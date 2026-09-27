shader_type spatial;
// Frost Wyrm ground marks (MapFillWyrmVfx, task 13c.V9). PlaneMesh 2 x 2 scaled to `radius` metres (node scale.x),
// NOT turned (local +X = world +X, local +Z = world +Z: the arc angles below are atan(z, x) in world space).
// ONE material for every mark, the look is picked per instance (`pattern`). Premultiplied alpha: `cover` paints rime /
// snow / a dark halo, `glow` adds light (linear HDR). Procedural noise in world space, no textures. Widths in metres.
//   0 dive telegraph  (Glacial Dive, r 3, 1.0 s, both teams): a hard frost ring on the danger edge with 8 ice
//                     chevrons pointing in, a dark halo under it, a rime fill that CLOSES from the rim to the centre as
//                     the landing comes (`front` 0 -> 1 = the countdown), a pulse that quickens.
//   1 tail-lash arc   (r 3.5): a ragged band (0.35 .. 1 of the radius) swept from angle `a0` to `a1` as `front` goes
//                     0 -> 1: a white-hot leading edge, snow streaks trailing behind it, scraped rime left on the ground.
//   2 blizzard floor  (r 8): snow cover spreading out with `front`, spiral drift streaks turning with the wind, glints,
//                     a ragged bright line on the edge of the storm (the danger edge).
//   3 cold mist       (pre-spawn warning, r 9): a faint frost haze on water and banks, slow wisps turning, a few
//                     glints; `front` spreads it from the centre.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float radius = 3.0;       // metres (= node scale.x)
instance uniform float front = 1.0;        // 0-1 (see each pattern)
instance uniform float a0 = 0.0;           // arc start angle (radians, atan(z, x))
instance uniform float a1 = 3.0;           // arc end angle (may be < a0: the sweep then turns the other way)
instance uniform float spin = 1.0;         // swirl direction / speed (blizzard, mist)
instance uniform vec4 glow = vec4(1.2, 1.8, 2.4, 1.0);      // linear HDR
instance uniform vec4 cover = vec4(0.7, 0.82, 0.95, 0.7);   // rgb linear, a = max opacity

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + vec2(7.1, 1.3)) * 0.3 + vnoise(p * 4.07 - vec2(3.3, 5.9)) * 0.15;
}

float ridge_lines(vec2 p, float lo, float hi) {
	float r = 1.0 - abs(fbm(p) * 2.0 - 1.0);
	return smoothstep(lo, hi, r);
}

float glints(vec2 w, float amount, float t) {
	vec2 c = floor(w);
	vec2 f = fract(w) - 0.5;
	float h = hash(c + 3.7);
	vec2 o = vec2(hash(c + 1.3), hash(c + 9.1)) - 0.5;
	vec2 d = abs(f - o * 0.6);
	float star = max(1.0 - smoothstep(0.0, 0.07, length(d)),
			(1.0 - smoothstep(0.0, 0.02, min(d.x, d.y))) * (1.0 - smoothstep(0.0, 0.2, max(d.x, d.y))) * 0.6);
	float tw = pow(max(0.0, sin(t * (2.0 + h * 3.0) + h * 40.0)), 10.0);
	return step(1.0 - amount, h) * star * (0.25 + tw);
}

// Signed angle from a to b in (-PI, PI].
float adiff(float a, float b) {
	return mod(b - a + PI, TAU) - PI;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	vec2 w = v_world + vec2(seed * 3.7, seed * 1.9);
	vec2 dir = p / max(r, 0.0001);
	float ang = atan(p.y, p.x);
	float t = TIME + seed * 5.0;
	int pat = int(pattern + 0.5);
	float a = 0.0;
	vec3 col = cover.rgb;
	vec3 emit = vec3(0.0);
	float d = (1.0 - r) * R;   // metres in from the rim
	if (pat == 0) {
		// ---- Glacial Dive telegraph
		float k = clamp(front, 0.0, 1.0);
		float pulse = 0.5 + 0.5 * sin(t * mix(7.0, 22.0, k * k));
		// The edge ring (0.14 m wide) with a dark halo on both sides so it reads on snow and on grass.
		float band = exp(-pow((d - 0.12) / 0.09, 2.0));
		float halo = exp(-pow((d - 0.12) / 0.32, 2.0));
		// Ice chevrons pointing in (8, slowly turning), their tips reaching further in as the landing nears.
		float lanes = 8.0;
		float au = fract((ang + t * 0.35) / TAU * lanes) - 0.5;
		float reach = mix(0.35, 0.8, k);
		float chev_d = abs(au) * 2.0 * 0.55 + d;
		float chev = (1.0 - smoothstep(reach - 0.06, reach, chev_d)) * smoothstep(0.05, 0.18, d);
		float chev_edge = exp(-pow((chev_d - reach + 0.03) / 0.045, 2.0)) * step(d, reach);
		// The closing fill: rime from the rim inward to the countdown radius.
		float fill_r = 1.0 - k;
		float edge_n = vnoise(dir * 3.0 + seed * 3.0) * 0.06;
		float filled = smoothstep(fill_r - 0.02 + edge_n, fill_r + 0.06 + edge_n, r);
		float n = fbm(w * 1.4);
		float lines = ridge_lines(w * 2.1 + 5.0, 0.9, 0.985);
		float front_line = exp(-pow((r - fill_r - edge_n) * R / 0.07, 2.0)) * step(0.01, k) * step(r, 0.97);
		a = cover.a * (halo * 0.55 + filled * (0.28 + 0.2 * n) + chev * 0.45);
		col = mix(vec3(0.02, 0.035, 0.07), cover.rgb, clamp(filled * 0.8 + chev * 0.6 - halo * 0.3, 0.0, 1.0));
		emit += glow.rgb * (band * (1.6 + 1.0 * pulse) + chev_edge * 1.3 + chev * 0.35 + front_line * 1.4);
		emit += glow.rgb * (filled * (lines * 0.6 + 0.12) + glints(w * 3.0, 0.2, t) * filled * 1.6);
		a = max(a, band * 0.8);
	} else if (pat == 1) {
		// ---- Tail Lash arc (a0 -> a1 NOT wrapped: the sweep may exceed 180 deg)
		float span = a1 - a0;
		float s = span < 0.0 ? -1.0 : 1.0;
		float rel = mod((ang - a0) * s, TAU);          // angle travelled from the start (radians, sweep direction)
		float total = abs(span);
		float head = total * clamp(front, 0.0, 1.0);   // the leading edge
		float r_in = 0.58 + 0.08 * vnoise(dir * 3.0 + seed);
		float ring = smoothstep(r_in, r_in + 0.12, r) * (1.0 - smoothstep(0.9, 1.0, r + 0.06 * vnoise(dir * 5.0 + seed)));
		float swept = 1.0 - smoothstep(head - 0.02, head + 0.04, rel);
		float behind = clamp((head - rel) / max(total, 0.1), 0.0, 1.0);
		// White-hot leading edge (the tail's path), snow streaks trailing, scraped rime left behind.
		float gap = rel - head;
		float lead = exp(-pow(gap * r * R / 0.45, 2.0)) * ring * step(0.02, front) * step(rel, total + 0.3);
		float streak = fbm(vec2(r * R * 4.0 + seed, rel * 1.2 - t * 1.5));
		float streaks = smoothstep(0.5, 0.75, streak) * ring * swept * (1.0 - behind * 0.7);
		float n = fbm(w * 1.8);
		float body = (1.0 - behind) * (1.0 - behind);
		a = cover.a * ring * swept * clamp(0.28 + (n - 0.5) * 0.5 + streaks * 0.8, 0.0, 1.0) * (0.35 + 0.65 * body);
		col = cover.rgb * (0.85 + 0.3 * n);
		emit += glow.rgb * (lead * 2.6 + streaks * 1.1 * body + glints(w * 3.4, 0.2, t) * ring * swept * 0.6);
		a = max(a, lead * 0.6 * cover.a);
	} else if (pat == 2) {
		// ---- Blizzard floor
		float k = clamp(front, 0.0, 1.0);
		float edge_n = vnoise(dir * 4.0 + vec2(t * 0.3, seed)) * 0.06;
		float reach = k * (0.93 + edge_n);
		float inside = 1.0 - smoothstep(reach - 0.12, reach, r);
		// Spiral drift streaks turning with the wind (seam-free: noise on the turned direction).
		float sw = spin * (log(max(r, 0.02)) * 2.4 - t * 1.4);
		vec2 d2 = vec2(dir.x * cos(sw) - dir.y * sin(sw), dir.x * sin(sw) + dir.y * cos(sw));
		float drift = smoothstep(0.52, 0.85, mix(fbm(w * 0.7), fbm(d2 * 3.2 + vec2(r * R * 0.25, seed)),
				smoothstep(0.03, 0.2, r)));
		float n = fbm(w * 0.9);
		float outer = smoothstep(0.35, 0.95, r);
		a = inside * cover.a * clamp(0.12 + (n - 0.5) * 0.5 + drift * 0.55 + 0.45 * outer * n, 0.0, 1.0);
		col = cover.rgb * (0.86 + 0.25 * n + 0.1 * drift);
		float rim_n = vnoise(dir * 9.0 + vec2(t * 1.2, seed));
		float rim = exp(-pow((r - reach + 0.02 * rim_n) * R / 0.35, 2.0)) * step(0.02, k);
		emit += glow.rgb * (drift * 0.25 * inside + glints(w * 2.6, 0.18, t) * inside * 1.2 + rim * (0.3 + 0.7 * rim_n) * 0.9);
		a = max(a, rim * (0.3 + 0.4 * rim_n) * cover.a);
	} else {
		// ---- Cold mist (pre-spawn)
		float k = clamp(front, 0.0, 1.0);
		float reach = k * (0.9 + 0.1 * vnoise(dir * 3.0 + seed));
		float inside = 1.0 - smoothstep(reach * 0.45, reach, r);
		float sw = spin * (r * 1.6 - t * 0.12);
		vec2 d2 = vec2(dir.x * cos(sw) - dir.y * sin(sw), dir.x * sin(sw) + dir.y * cos(sw));
		float wisp = fbm(d2 * 2.2 + vec2(r * R * 0.2, seed));
		float wisp2 = fbm(w * 0.35 + vec2(t * 0.08, -t * 0.05));
		wisp = mix(wisp2, wisp, smoothstep(0.03, 0.2, r));   // no pinch at the centre
		float m = smoothstep(0.35, 0.8, wisp * 0.6 + wisp2 * 0.5);
		a = inside * cover.a * (0.2 + 0.8 * m);
		col = cover.rgb * (0.9 + 0.15 * wisp2);
		emit += glow.rgb * (glints(w * 1.6, 0.12, t * 0.6) * inside * k * 1.2 + m * inside * 0.1);
	}	a = clamp(a, 0.0, 1.0) * fade;
	ALBEDO = col * a + emit * fade;
	ALPHA = a;
}
