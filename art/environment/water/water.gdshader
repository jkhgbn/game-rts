// water.gdshader - painted river / moat water for Crown Hollow (task 12.V1, map-fill.md sections 2 and 10).
// Opaque, flat (lily-pad-safe: no vertex motion), no screen / depth texture reads, no real lights.
//
// Mesh convention (WaterMeshes in water_meshes.gd builds it; RiverSystem 12.C1 may build its own the same way):
//   UV.x   metres ALONG the flow (increases downstream); the noise scrolls along it at flow_speed m/s
//   UV.y   0 on one bank -> 1 on the other bank (darker in the middle, foam at 0 and 1)
//   channel_width = the metres UV.y spans on a piece with COLOR.g = 1 (the 5 m river)
//   COLOR.r  bank weight (optional): 1 = a real bank (light shallows + foam), 0 = an open edge where the water goes
//            on (the river mouths on the moat's outer rim: deep colour, no foam)
//   COLOR.g  piece width / channel_width (optional; 0.7 on the 3.5 m moat). No colours = white = 1, 1.
// Layers: posterised teal-green depth bands (dark mid-channel), long flow strokes, wobbly light ripple lines
// drifting with the flow, a sun glint band (few sparkles, hidden by the sun's shadow map), a sky tint at grazing
// angles, broken foam at both banks with drifting foam clumps, foam collars + V wakes around foam_rocks (piers,
// stones, the barge), and with `shallow` the ford film: light water over painted stones and sand, a caustic web,
// faster ripples, rapids foam along the ford rim. The ford film is a second material (water_ford_mat.tres,
// shallow = 1), so no material is ever made at runtime.
// `detail` 0 = Map detail Low (no ripple lines, glints, foam clumps or wakes; simpler stones).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
// Palette (painted teal-green; middle darker).
uniform vec3 deep_color : source_color = vec3(0.04, 0.18, 0.19);
uniform vec3 water_color : source_color = vec3(0.09, 0.32, 0.29);
uniform vec3 bank_color : source_color = vec3(0.22, 0.46, 0.36);
uniform vec3 sky_color : source_color = vec3(0.52, 0.70, 0.78);
uniform vec3 foam_color : source_color = vec3(0.86, 0.93, 0.87);
uniform vec3 glint_color : source_color = vec3(1.0, 0.95, 0.80);
// Ford film (shallow).
uniform vec3 film_color : source_color = vec3(0.22, 0.50, 0.45);
uniform vec3 stone_color : source_color = vec3(0.52, 0.49, 0.42);
uniform vec3 sand_color : source_color = vec3(0.60, 0.51, 0.33);
// Behaviour.
uniform float flow_speed = 0.55;                          // metres per second along UV.x
uniform float foam_amount : hint_range(0.0, 2.0) = 1.0;   // 0 = no foam, 1 = default, 2 = rapids
uniform float shallow : hint_range(0.0, 1.0) = 0.0;       // 0 = deep channel, 1 = ford film
uniform float channel_width = 5.0;                        // metres spanned by UV.y 0..1 (COLOR.g = 1)
uniform float ripple_strength = 1.0;
uniform float glint_strength = 1.0;
uniform float glint_center = 0.36;                        // UV.y of the sun glint band
uniform float glint_width = 0.12;
uniform float detail = 1.0;                               // 1 = high, 0 = Map detail Low
// World-space foam sources (x, z, radius, 0): bridge piers, stones, the drowned barge. Only the first
// foam_rock_count are used; set them once on the shared material (RiverSystem / 12.C8).
uniform vec4 foam_rocks[16];
uniform int foam_rock_count = 0;
// Ford circles (cx, cz, r, 0), same data as the ground shader's `fords`: rapids foam along the rim of the film.
uniform vec4 fords[4];
uniform int ford_count = 0;
// Direction TO the sun on the ground plane (sun yaw 40, pitch -52), for the lit side of submerged stones.
uniform vec2 sun_dir = vec2(0.57, 0.82);

varying vec3 v_wp;
varying float v_glint;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float nz(vec2 p) {
	return texture(noise_tex, p).r;
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float poster(float x, float n) {
	float f = x * n;
	float i = floor(f);
	float fr = f - i;
	float w = clamp(fwidth(f), 0.001, 0.5);
	return (i + smoothstep(0.5 - w, 0.5 + w, fr)) / n;
}

float disc(float d, float r, float aa) {
	return 1.0 - smoothstep(r - aa, r + aa, d);
}

// Anti-aliased iso-lines of `v` every 1/levels, `w` metres wide (px = metres per pixel).
float contour(float v, float levels, float w, float px) {
	float k = v * levels;
	float f = min(fract(k), 1.0 - fract(k));
	float dm = f * px / max(fwidth(k), 1e-5);   // metres to the nearest line
	return 1.0 - smoothstep(w - px * 0.7, w + px * 0.7, dm);
}

// Sparse short sparkles in flow space q (metres): cells of `cell`, one tiny dash in a fraction `prob` of them,
// each twinkling on its own phase. Returns the mask.
float sparkles(vec2 q, vec2 cell, float prob, float hl, float hw, float aa) {
	vec2 g = q / cell;
	vec2 id = floor(g);
	vec2 h = hash2(id);
	if (h.x > prob) {
		return 0.0;
	}
	vec2 o = (hash2(id + 5.17) - 0.5) * 0.5;
	vec2 f = (fract(g) - 0.5 - o) * cell;
	// A thin diamond along the flow crossed by a shorter one: a painted four-point twinkle.
	float e = min(abs(f.x) / hl + abs(f.y) / hw, abs(f.x) / (hw * 1.6) + abs(f.y) / (hl * 0.55));
	float m = 1.0 - smoothstep(1.0 - aa / hw, 1.0 + aa / hw, e);
	float ph = sin(TIME * (2.2 + h.y * 2.0) + h.y * 6.2832) * 0.5 + 0.5;
	return m * smoothstep(0.35, 0.9, ph);
}

// Painted river stones for the ford bed (world metres). x = stone mask, y = lit side (-1..1), z = id.
vec3 stones(vec2 p, float aa, bool simple) {
	float cell = 0.62;
	vec2 g = p / cell;
	vec2 id = floor(g);
	if (simple) {
		vec2 h = hash2(id);
		vec2 f = (fract(g) - 0.5 - (hash2(id + 1.7) - 0.5) * 0.35) * cell;
		float r = cell * (0.22 + h.y * 0.16);
		float m = disc(length(f * vec2(1.0, 1.2)), r, aa) * step(0.45, h.x);
		return vec3(m, dot(normalize(f + 0.0001), sun_dir) * m, h.x);
	}
	// The two nearest jittered feature points: rounded stones with sand gaps between them.
	float d1 = 9.0;
	float d2 = 9.0;
	vec2 best = vec2(0.0);
	vec2 bid = id;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = id + vec2(float(x), float(y));
			vec2 fp = (c + 0.5 + (hash2(c) - 0.5) * 0.75) * cell;
			vec2 v = p - fp;
			float d = length(v * vec2(1.0, 1.15));
			if (d < d1) {
				d2 = d1;
				d1 = d;
				best = v;
				bid = c;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	float h = hash2(bid + 3.3).x;
	float gap = 0.05 + h * 0.07;
	float m = smoothstep(gap - aa, gap + aa, (d2 - d1) * 0.5) * step(0.4, h);   // stones scattered on sand
	float lit = dot(normalize(best + 0.0001), sun_dir) * smoothstep(0.03, 0.22, d1);
	return vec3(m, lit * m, h);
}

void fragment() {
	vec2 wp = v_wp.xz;
	float px = max(length(fwidth(wp)), 0.0005);     // metres per pixel
	float aa = px * 0.8;
	bool hi = detail > 0.5;
	float sh = clamp(shallow, 0.0, 1.0);
	float bankw = clamp(COLOR.r, 0.0, 1.0);
	float t = clamp(UV.y, 0.0, 1.0);
	float s = UV.x;
	float cw = channel_width * max(COLOR.g, 0.05);   // COLOR.g = this piece's width / channel_width
	float across = (t - 0.5) * cw;                   // metres from the centre line
	float edge_m = (0.5 - abs(t - 0.5)) * cw;        // metres to the nearest bank
	float side = step(0.5, t) * 7.31;                // decorrelates the two banks
	float tm = TIME * flow_speed * mix(1.0, 1.7, sh);
	float fade_near = 1.0 - smoothstep(0.06, 0.15, px);   // fine detail vanishes when zoomed far out

	// Flow-space noise (moves with the water).
	vec2 f1 = vec2(s - tm, across);
	vec2 f2 = vec2(s - tm * 0.62, across * 1.3 + 3.7);
	float n_big = nz(f1 * vec2(0.032, 0.085));
	float n_str = nz(f2 * vec2(0.045, 0.40) + vec2(0.31, 0.12));
	float n_fine = nz(f1 * vec2(0.20, 0.28) + vec2(5.1, 2.7));

	// Depth bands: light shallows at the banks, dark mid-channel, wobbling posterised edges like the ground.
	// An open edge (COLOR.r 0) stays deep all the way out.
	float mid = 1.0 - abs(t - 0.5) * 2.0;
	mid = mix(1.0 - (1.0 - mid) * 0.25, mid, bankw);
	float depth = clamp(mid * 1.05 + (n_big - 0.5) * 0.38 + (n_fine - 0.5) * 0.08, 0.0, 1.0);
	float band = poster(depth, 3.0) * 0.62 + depth * 0.38;
	vec3 col = mix(bank_color, water_color, smoothstep(0.0, 0.42, band));
	col = mix(col, deep_color, smoothstep(0.45, 1.0, band));
	// Long painted strokes along the flow.
	col *= 0.88 + poster(n_str, 4.0) * 0.22;
	col *= 0.95 + n_fine * 0.10;

	// Ford film: light water over painted stones and sand, a caustic web, seen through a small wobble.
	if (sh > 0.001) {
		vec2 wob = (vec2(n_fine, n_str) - 0.5) * 0.10;
		vec3 st = stones(wp + wob, aa, !hi);
		float sand_n = nz(wp * 0.35 + vec2(2.1, 7.7));
		vec3 bed = sand_color * (0.82 + sand_n * 0.3);
		vec3 sc = stone_color * (0.70 + st.z * 0.45) * mix(vec3(1.0), vec3(1.08, 1.0, 0.86), step(0.62, st.z));
		sc = mix(sc, sc * vec3(0.78, 0.95, 0.72), step(st.z, 0.3) * 0.6);          // a few mossy stones
		sc *= 1.0 + st.y * 0.28;
		bed = mix(bed * (1.0 - 0.3 * smoothstep(0.0, 0.3, st.x)), sc, st.x);      // dark wet rim around stones
		vec3 film = mix(bed * vec3(0.78, 0.92, 0.84), film_color, 0.6) * 0.86;
		// Deeper, greener water toward the middle of the channel; wet dark earth at the banks (meets the ground's
		// wet bank band of 12.V2 instead of a hard edge).
		film = mix(film, film * vec3(0.72, 0.9, 0.92), smoothstep(0.3, 1.0, mid) * 0.6);
		float wet = (1.0 - smoothstep(0.05, 0.5, edge_m + (n_fine - 0.5) * 0.2)) * bankw;
		film = mix(film, sand_color * vec3(0.46, 0.42, 0.34), wet * 0.85);
		float caustic = contour(nz(f1 * vec2(0.22, 0.26) + vec2(1.3, 4.4)), 3.0, 0.025, px);
		film *= 1.0 + caustic * 0.16 * fade_near;
		film *= 0.94 + poster(n_str, 3.0) * 0.10;
		col = mix(col, film, sh);
	}

	// Sky reflection at grazing angles (top of the screen at high zoom), a soft light band under the glints.
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col = mix(col, sky_color * 0.85, fres * 0.28);
	float gb = 1.0 - smoothstep(glint_width * 0.4, glint_width, abs(t - glint_center + (n_big - 0.5) * 0.10));
	col = mix(col, sky_color, gb * 0.08 * (1.0 - sh) * glint_strength);

	// Ripple lines: wobbly light iso-lines of two noises drifting at different speeds, broken into pieces.
	if (hi && ripple_strength > 0.0) {
		float r1 = nz(vec2(s - tm * 1.1, across) * vec2(0.13, 0.30) + vec2(0.7, 3.3));
		float r2 = nz(vec2(s - tm * 0.75, across * 1.1) * vec2(0.09, 0.22) + vec2(4.2, 1.1));
		float rv = r1 * 0.6 + r2 * 0.4;
		float lines = contour(rv, mix(4.0, 4.5, sh), mix(0.022, 0.016, sh), px);
		float brk = smoothstep(0.42, 0.58, nz(vec2(s - tm * 0.9, across) * vec2(0.3, 0.5) + vec2(2.9, 0.4)));
		float far_soft = 1.0 - smoothstep(0.03, 0.09, px) * 0.6;   // quieter at high zoom (no shimmer)
		float rip = lines * brk * far_soft * ripple_strength * (0.35 + 0.65 * smoothstep(0.05, 0.5, mid + sh))
				* (1.0 - smoothstep(0.1, 0.2, px));
		col = mix(col, col * 1.38 + vec3(0.04, 0.06, 0.05), rip * 0.8);
	}

	// Sun glint band: a few small twinkling sparkles along the band, lit only in sunlight (light()).
	float glint = 0.0;
	if (hi && glint_strength > 0.0) {
		vec2 gq = vec2(s - tm * 1.2, across);
		float g1 = sparkles(gq + vec2(3.1, 0.0), vec2(0.7, 0.26), 0.22, 0.12, 0.03, aa);
		float g2 = sparkles(gq + vec2(0.0, 0.37), vec2(0.9, 0.34), 0.14, 0.09, 0.024, aa);
		glint = max(g1, g2) * smoothstep(0.1, 0.7, gb) * (1.0 - sh) * glint_strength * bankw;
	}

	// Bank foam: a crisp lip of changing width, a lighter band of churned water beyond it, drifting clumps.
	float fn = nz(vec2(s - tm * 0.35 + side * 3.0, side) * vec2(0.22, 1.0));
	float fn2 = nz(vec2(s - tm * 0.6 + side, 0.37 + side) * vec2(0.55, 1.0));
	float fw = (0.06 + fn * 0.22 + fn2 * 0.08) * mix(1.0, 0.45, sh) * foam_amount;
	float lip = 1.0 - smoothstep(fw - aa, fw + aa, edge_m);
	lip *= mix(1.0, smoothstep(0.35, 0.5, fn2), sh);    // the ford's lip is broken (wet sand shows between)
	float churn = (1.0 - smoothstep(fw, fw + 0.5 * foam_amount, edge_m)) * step(0.01, foam_amount);
	col = mix(col, col * 1.2 + vec3(0.03, 0.05, 0.04), churn * 0.5 * bankw * (1.0 - sh));
	float foam = lip;
	if (hi) {
		// A few foam clumps drifting just off the bank.
		float cl = nz(vec2(s - tm * 0.95, edge_m * 1.4 + side) * vec2(0.8, 1.1) + vec2(0.2, 5.3));
		float near_bank = (1.0 - smoothstep(fw + 0.05, fw + 0.45 * foam_amount, edge_m)) * step(fw, edge_m);
		foam = max(foam, smoothstep(0.73, 0.75, cl) * near_bank * 0.85 * (1.0 - sh));
	}
	foam *= bankw * step(0.01, foam_amount);

	// Foam collars and V wakes around piers / stones (world space).
	if (foam_rock_count > 0) {
		// Flow direction in world space = gradient of UV.x (screen derivatives, flat triangles).
		vec2 dsx = dFdx(wp);
		vec2 dsy = dFdy(wp);
		float ux = dFdx(s);
		float uy = dFdy(s);
		float det = dsx.x * dsy.y - dsx.y * dsy.x;
		vec2 fd = abs(det) > 1e-9 ? vec2(ux * dsy.y - dsx.y * uy, dsx.x * uy - ux * dsy.x) / det : vec2(1.0, 0.0);
		fd = normalize(fd + vec2(1e-6, 0.0));
		vec2 fnrm = vec2(-fd.y, fd.x);
		for (int i = 0; i < 16; i++) {
			if (i >= foam_rock_count) {
				break;
			}
			vec4 r = foam_rocks[i];
			vec2 v = wp - r.xy;
			float len = 1.6 + r.z * 3.0;
			float reach = r.z + len;
			if (dot(v, v) > reach * reach) {
				continue;
			}
			float d = length(v) - r.z;
			float a = dot(v, fd);
			float b = abs(dot(v, fnrm));
			float wn = nz(vec2(a - tm * 0.9, b) * vec2(0.45, 0.9) + vec2(float(i) * 0.37, 0.5));
			// Collar: thicker upstream (the water piles against the stone), broken by noise.
			float wn2 = nz(v * 1.7 + vec2(tm * 0.25, float(i) * 0.53));   // finer, for ragged edges
			float cw0 = (0.04 + wn * 0.10 + (wn2 - 0.5) * 0.12 + (1.0 - smoothstep(-r.z, 0.0, a)) * 0.08) * foam_amount;
			float collar = 1.0 - smoothstep(cw0 - aa, cw0 + aa, d);
			float ring2 = disc(abs(d - 0.28 * foam_amount - (wn - 0.5) * 0.12), 0.025 + px * 0.2, aa)
					* smoothstep(0.52, 0.62, wn) * 0.7 * fade_near;
			col = mix(col, col * 1.2 + vec3(0.03, 0.05, 0.04), (1.0 - smoothstep(0.0, 0.5 * foam_amount, d)) * 0.5);
			float fr = max(collar, ring2);
			if (hi) {
				// Two short broken foam lines spreading downstream from the sides, churned water right behind.
				len *= 0.6;
				float spread = r.z * 0.8 + max(a, 0.0) * 0.28 + (wn2 - 0.5) * 0.14;
				float along = step(0.0, a) * (1.0 - smoothstep(len * 0.25, len, a));
				float brk = smoothstep(0.42, 0.58, nz(vec2(a * 1.4 - tm * 1.1, b * 0.3 + float(i)) * 0.9));
				float vlines = disc(abs(b - spread), (0.04 - a * 0.008) * (0.6 + wn2 * 0.8), aa) * along * brk;
				float trail = step(0.0, a) * (1.0 - smoothstep(r.z * 0.5, r.z * 0.95, b))
						* (1.0 - smoothstep(0.0, r.z * 1.6 + 0.4, a)) * smoothstep(0.5, 0.6, wn);
				fr = max(fr, max(vlines * 0.85, trail * 0.8));
			}
			foam = max(foam, fr * step(0.01, foam_amount));
		}
	}

	// Ford rim: broken rapids foam where the film drops into the deep channel.
	if (sh > 0.001 && ford_count > 0) {
		for (int i = 0; i < 4; i++) {
			if (i >= ford_count) {
				break;
			}
			vec4 fo = fords[i];
			float d = length(wp - fo.xy);
			if (fo.z <= 0.0 || d > fo.z + 0.5) {
				continue;
			}
			float ang = atan(wp.y - fo.y, wp.x - fo.x);
			float rn = nz(vec2(ang * fo.z * 0.35 - tm * 0.5, 0.71 + float(i)) * vec2(0.6, 1.0));
			float inner = fo.z - d;
			// Blobby foam piled along the drop-off: a 2D noise in (around the rim, distance in), biased to the rim.
			float blob = nz(vec2(ang * fo.z * 0.55 - tm * 0.4, inner * 1.3 + rn * 0.8) * vec2(0.8, 0.9) + vec2(float(i) * 0.31, 0.0));
			float bias = (1.0 - smoothstep(0.0, 0.45 * foam_amount, inner)) * 0.32 + (rn - 0.5) * 0.08;
			float rim = smoothstep(0.66 - aa * 2.0, 0.68 + aa * 2.0, blob + bias) * (1.0 - smoothstep(0.5, 0.9, inner));
			// The film deepens toward the drop-off, so the ford reads as a sandbar, not a slab.
			col = mix(col, water_color * 1.1, (1.0 - smoothstep(0.0, 1.6, inner)) * 0.7 * sh
					* smoothstep(0.2, 0.9, edge_m));
			foam = max(foam, rim * sh * step(0.01, foam_amount));
		}
	}

	foam = clamp(foam, 0.0, 1.0);
	col = mix(col, foam_color * (0.9 + fn * 0.12), foam);
	v_glint = glint * (1.0 - foam);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	// Painted sparkles: only in sunlight (the shadow map hides them under bridges and trees).
	SPECULAR_LIGHT += v_glint * glint_color * ATTENUATION * LIGHT_COLOR * 0.6;
}
