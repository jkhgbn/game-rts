shader_type spatial;
// Titan ground marks (TitanVfx, tasks 13.V14 / 13c.V2). PlaneMesh 2 x 2 scaled to `radius` metres (node scale.x),
// lying just above the ground. ONE material for every mark: the look is picked per instance (`pattern`), so a breath
// or a crash never creates a material. Procedural noise in WORLD space (same grain at every size), no textures.
// Premultiplied alpha: `cover` paints soot / rime / dirt, `glow` adds light. Line widths are in metres.
//   0 burning ground (r 2, 3 s): soot, ember veins, licking flames, a flickering fire line at `rim_at` (the damage edge)
//   1 hoarfrost      (r 2.5, 4 s): rime crust growing out with `front`, frost-fern crystal lines, twinkling glints,
//                    an icy line at `rim_at`
//   2 fire fan       (the breath hitting the ground): a 2 x `arc` sector (local +X = the breath), a fire front rolling
//                    out to `front`, flames streaming outward, soot left behind
//   3 rime fan       (the frost breath): the same sector, rime spreading behind a cold front, crystal lines, glints
//   4 crash crater   (fire): charred crater, a raised dirt lip, radial cracks glowing with `heat`
//   5 ice crater     (frost): a shattered ice sheet, bright radial cracks, a snow lip, glints
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float radius = 2.0;       // metres (= node scale.x)
instance uniform float heat = 1.0;         // 0-1: glow strength (the fire cools, the frost dulls)
instance uniform float front = 1.0;        // 0-1: how far the mark has spread
instance uniform float rim = 0.0;          // 0-1: strength of the damage-edge line
instance uniform float rim_at = 0.92;      // that line's radius, as a fraction of `radius`
instance uniform float arc = 0.5236;       // fan half-angle (radians)
instance uniform vec4 glow = vec4(2.2, 0.8, 0.12, 1.0);      // linear HDR
instance uniform vec4 cover = vec4(0.035, 0.025, 0.02, 0.8); // rgb linear, a = max opacity

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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

// Thin bright lines where the noise crosses 0.5 (crystal edges, ember veins).
float ridge_lines(vec2 p, float lo, float hi) {
	float r = 1.0 - abs(fbm(p) * 2.0 - 1.0);
	return smoothstep(lo, hi, r);
}

// A sparse grid of tiny stars that twinkle (ice glints). `w` in cells, `amount` = share of lit cells.
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

// Radial cracks: `k` lanes around the circle, each wandering with the noise and ending at its own length.
float cracks(vec2 p, vec2 w, float r, float R, float k, float reach) {
	vec2 dir = p / max(r, 0.0001);
	float ang = atan(p.y, p.x);
	float wander = vnoise(dir * 3.0 + seed * 2.0) * 0.6 + (vnoise(w * 1.3) - 0.5) * 0.45;
	float lane_f = ang / TAU * k + wander + seed;
	float lane = abs(fract(lane_f) - 0.5);
	float id = floor(lane_f + 0.5);
	float len = reach * (0.55 + 0.5 * hash(vec2(id, seed)));
	float wf = 0.075 * k / (TAU * max(r * R, 0.25));
	float line = 1.0 - smoothstep(wf * 0.35, wf, 0.5 - lane);
	return line * smoothstep(0.06, 0.16, r) * (1.0 - smoothstep(len * 0.8, len, r));
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
	float edge_n = vnoise(dir * 2.6 + seed * 7.0) * 0.6 + vnoise(dir * 6.5 - seed * 3.0) * 0.4;
	float t = TIME + seed * 5.0;
	int pat = int(pattern + 0.5);
	float a = 0.0;
	vec3 col = cover.rgb;
	vec3 emit = vec3(0.0);
	if (pat == 0) {
		// ---- burning ground
		float reach = rim_at * (0.86 + 0.14 * edge_n) * mix(0.4, 1.0, front);
		float inside = 1.0 - smoothstep(reach - 0.2, reach, r);
		float n = fbm(w * 0.9);
		float n2 = fbm(w * 2.4 + 5.0);
		a = inside * cover.a * clamp(0.72 + (n - 0.5) * 0.9 + (n2 - 0.5) * 0.4, 0.35, 1.0);
		col = mix(cover.rgb, cover.rgb * 3.0 + vec3(0.03, 0.012, 0.0), clamp(n2 * 1.3 - 0.4, 0.0, 1.0));
		float veins = ridge_lines(w * 1.25 + 11.0, 0.86, 0.97) * inside;
		float flick = 0.72 + 0.28 * sin(t * 7.0 + n * 18.0);
		float f = fbm(vec2(w.x * 1.7, w.y * 1.7 - t * 0.9)) * 0.6 + fbm(vec2(w.x * 3.3 + 0.5, w.y * 3.3 - t * 1.7)) * 0.4;
		float fl = smoothstep(0.5, 0.72, f) * inside;
		float core = pow(clamp(1.0 - r / max(reach, 0.1), 0.0, 1.0), 1.4);
		emit += glow.rgb * (veins * 1.5 * flick + fl * (0.6 + 0.7 * core) + core * 0.3) * heat;
		emit += vec3(1.7, 1.25, 0.55) * smoothstep(0.66, 0.8, f) * inside * heat * 0.7;
		// The fire line on the damage edge (a flickering, broken ring of flame).
		float wob = rim_at + 0.012 * sin(atan(p.y, p.x) * 9.0 + t * 3.0);
		float band = exp(-pow((r - wob) * R / 0.075, 2.0));
		float band_n = 0.45 + 0.55 * smoothstep(0.3, 0.7, vnoise(dir * 5.0 + vec2(t * 1.4, t * 0.6)));
		emit += glow.rgb * 1.9 * band * band_n * rim;
		emit += vec3(1.5, 1.1, 0.5) * band * band * band_n * rim * 0.6;
		a = max(a, band * rim * 0.55 * cover.a);
	} else if (pat == 1) {
		// ---- hoarfrost
		float reach = rim_at * (0.88 + 0.12 * edge_n) * max(front, 0.001);
		float inside = 1.0 - smoothstep(reach - 0.22, reach, r);
		float n = fbm(w * 1.1);
		float n2 = fbm(w * 3.0 + 2.0);
		a = inside * cover.a * clamp(0.55 + (n - 0.5) * 1.1 + (n2 - 0.5) * 0.5, 0.2, 1.0);
		col = cover.rgb * (0.82 + 0.32 * n2);
		float lines = (ridge_lines(w * 1.6 + 4.0, 0.9, 0.985) + ridge_lines(w * 3.4 - 9.0, 0.92, 0.99) * 0.6) * inside;
		float gl = glints(w * 3.2, 0.24, t) * inside;
		float breath = 0.85 + 0.15 * sin(t * 1.6);
		emit += glow.rgb * (lines * 0.85 + gl * 2.6) * heat;
		emit += glow.rgb * 0.16 * inside * heat * breath;
		float wob = rim_at * max(front, 0.001);
		float band = exp(-pow((r - wob) * R / 0.085, 2.0));
		emit += glow.rgb * 1.25 * band * rim * (0.75 + 0.25 * sin(t * 2.2 + atan(p.y, p.x) * 5.0));
		a = max(a, band * rim * 0.6 * cover.a);
	} else if (pat == 2 || pat == 3) {
		// ---- breath fans (fire / rime); local +X = the breath direction
		bool fr_fire = pat == 2;
		float ang = atan(p.y, p.x);
		float half_a = arc * (0.86 + 0.22 * vnoise(vec2(r * R * 0.8, seed * 3.0)));
		float side = 1.0 - smoothstep(half_a - 0.14, half_a, abs(ang));
		float start = smoothstep(0.1, 0.24, r);
		float fr = front * (0.9 + 0.12 * vnoise(vec2(ang * 3.0 + seed, t * 0.8)));
		float reached = 1.0 - smoothstep(fr - 0.06, fr, r);
		float inside = side * start * reached;
		float n = fbm(w * 1.0);
		float n2 = fbm(w * 2.7 + 3.0);
		// The rolling front: bright while it travels, gone once it reached the end of the cone.
		float lead = exp(-pow((r - fr) * R / 0.45, 2.0)) * side * start * step(0.02, front)
				* (1.0 - 0.85 * smoothstep(0.8, 1.0, front));
		if (fr_fire) {
			a = inside * cover.a * clamp(0.55 + (n - 0.5) * 1.0, 0.25, 1.0) * mix(0.55, 1.0, smoothstep(0.2, 0.7, r));
			col = mix(cover.rgb, cover.rgb * 2.6, clamp(n2 * 1.3 - 0.4, 0.0, 1.0));
			// flames streaming outward
			float f = fbm(vec2(ang * 4.0 + seed, r * R * 0.9 - t * 5.0)) * 0.6
					+ fbm(vec2(ang * 8.0 - seed, r * R * 1.9 - t * 8.0)) * 0.4;
			float fl = smoothstep(0.42, 0.7, f) * inside;
			float veins = ridge_lines(w * 1.3 + 2.0, 0.86, 0.97) * inside;
			emit += glow.rgb * (fl * 0.9 + lead * 1.1 + veins * 0.7) * heat;
			emit += vec3(1.2, 0.85, 0.35) * (smoothstep(0.64, 0.8, f) * inside + lead * lead * 0.4) * heat;
			a = max(a, lead * 0.35 * heat * cover.a);
		} else {
			a = inside * cover.a * clamp(0.5 + (n - 0.5) * 1.1 + (n2 - 0.5) * 0.4, 0.2, 1.0);
			col = cover.rgb * (0.82 + 0.32 * n2);
			float lines = ridge_lines(w * 1.7 + 6.0, 0.9, 0.985) * inside;
			float gl = glints(w * 3.2, 0.22, t) * inside;
			float mist = fbm(vec2(ang * 3.0 - seed, r * R * 0.7 - t * 2.2));
			emit += glow.rgb * (lines * 0.9 + gl * 2.6 + lead * 1.1 + smoothstep(0.5, 0.8, mist) * inside * 0.35) * heat;
			a = max(a, lead * 0.5 * cover.a * heat);
		}
	} else {
		// ---- crash craters (4 fire, 5 ice)
		bool ice = pat == 5;
		float reach = max(front, 0.001) * (0.78 + 0.14 * edge_n);
		float inside = 1.0 - smoothstep(reach - 0.22, reach, r);
		float n = fbm(w * 1.2);
		float n2 = fbm(w * 3.1 - 4.0);
		float lip = exp(-pow((r - reach * 0.86) * R / 0.4, 2.0));
		float bowl = 1.0 - smoothstep(0.0, reach * 0.9, r);
		float cr = cracks(p, w, r, R, ice ? 11.0 : 9.0, min(1.0, reach * 1.18));
		if (!ice) {
			a = clamp(inside * cover.a * (0.55 + 0.35 * bowl + (n - 0.5) * 0.5) + lip * 0.5 * cover.a, 0.0, 1.0);
			vec3 dirt = vec3(0.13, 0.085, 0.05);
			col = mix(cover.rgb * (0.8 + 0.5 * n2), dirt * (0.8 + 0.4 * n2), lip);
			float veins = ridge_lines(w * 1.4 + 8.0, 0.88, 0.97) * inside * bowl;
			emit += glow.rgb * (cr * 1.7 + veins * 0.9) * heat;
			emit += glow.rgb * 1.1 * pow(bowl, 2.0) * heat * heat;
			a = max(a, cr * 0.8 * cover.a);
			col = mix(col, vec3(0.02, 0.012, 0.008), cr * 0.8);
		} else {
			a = clamp(inside * cover.a * (0.6 + 0.3 * bowl + (n - 0.5) * 0.6) + lip * 0.35, 0.0, 1.0);
			vec3 snow = vec3(0.86, 0.92, 0.98);
			col = mix(cover.rgb * (0.78 + 0.35 * n2), snow, lip);
			float lines = ridge_lines(w * 2.2 + 3.0, 0.9, 0.985) * inside;
			float gl = glints(w * 3.0, 0.3, t) * inside;
			emit += glow.rgb * (cr * 1.4 + lines * 0.6 + gl * 2.2 + bowl * 0.25) * heat;
			a = max(a, cr * 0.5);
		}
	}
	a = clamp(a, 0.0, 1.0) * fade;
	ALBEDO = col * a + emit * fade;
	ALPHA = a;
}
