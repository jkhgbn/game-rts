shader_type spatial;
// Rimecarver ground marks (CasterIceVfx, task CU.V5 Ice part). PlaneMesh 2 x 2 (UV 0-1); the node's scale is the
// mark's half size in metres (`size` = the same numbers, for line widths). ONE material, the look per instance:
//   0 frost crack   a jagged glowing crack line along local +Z (from UV.y 0 = the caster end to 1 = the wall) with
//                   short branches, drawn in by `draw` (0-1) with a bright leading tip; a dark ice-blue cover under
//                   it so it reads on grass and snow alike.
//   1 scrying ring  the Scrying Rune's vision circle (r = size.x): a thin ring with 12 rune dashes, a fainter inner
//                   ring, turning slowly; `draw` sweeps it in.
//   2 rime footprint the frosted strip under a Bulwark (size = its half length / width): a steel-blue rime patch with
//                   frost spikes and a darker rim (never white).
// Premultiplied alpha: `tint` glow adds light, the cover darkens.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(0.5, 1.6, 2.6, 1.0);
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;
instance uniform float draw = 1.0;
instance uniform vec2 size = vec2(1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 uv = UV;
	vec2 m = (uv - 0.5) * 2.0 * size;          // metres from the centre (x across, y along)
	float glow = 0.0;
	float cover = 0.0;
	if (pattern < 0.5) {
		// Frost crack: the path wanders across x as it runs along y; branches split off every ~0.6 m.
		float along = uv.y * size.y * 2.0;         // metres from the start
		float total = size.y * 2.0;
		float head = draw * total;
		float wob = (vnoise(vec2(along * 2.2, seed * 5.0)) - 0.5) * 0.22 + (vnoise(vec2(along * 7.0, seed)) - 0.5) * 0.06;
		float d = abs(m.x - wob);
		float br = 1e3;
		float cellw = 0.6;
		float ci = floor(along / cellw);
		float cf = along - ci * cellw;
		float side = hash(vec2(ci, seed)) > 0.5 ? 1.0 : -1.0;
		br = seg(vec2(m.x - wob, cf), vec2(0.0, 0.05), vec2(side * (0.12 + 0.12 * hash(vec2(ci, seed + 1.0))), 0.38));
		float shown = step(along, head);
		float line = (1.0 - smoothstep(0.012, 0.035, d)) + (1.0 - smoothstep(0.008, 0.025, br)) * 0.7;
		float tip = exp(-abs(along - head) * 6.0) * step(along, head + 0.05);
		float taper = smoothstep(0.0, 0.3, along) * (1.0 - smoothstep(total - 0.4, total, along) * 0.3);
		glow = clamp(line, 0.0, 1.0) * shown * taper * (0.8 + 1.5 * tip);
		cover = (1.0 - smoothstep(0.03, 0.16, min(d, br))) * shown * 0.55 * taper;
		// soft rime spread either side of the crack, fading with distance
		cover += (1.0 - smoothstep(0.05, size.x, abs(m.x - wob))) * shown * 0.12 * taper;
	} else if (pattern < 1.5) {
		// Scrying ring: r = size.x metres.
		float r = length(m);
		float R = size.x;
		float ang = atan(m.y, m.x) + TIME * 0.08 + seed;
		float band = abs(r - R * 0.985);
		float ring = 1.0 - smoothstep(0.03, 0.07, band);
		float inner = (1.0 - smoothstep(0.02, 0.05, abs(r - R * 0.93))) * 0.45;
		float k = 12.0;
		float a = fract(ang / 6.28318 * k);
		float dash = (1.0 - smoothstep(0.02, 0.06, abs(a - 0.5) * (6.28318 * R / k) - 0.18)) * (1.0 - smoothstep(0.05, 0.14, abs(r - R * 0.958)));
		float swept = step(fract((atan(m.y, m.x) + 3.14159) / 6.28318 + 0.25), draw);
		glow = (ring + inner + dash * 0.9) * swept;
		cover = (1.0 - smoothstep(0.0, 0.22, abs(r - R * 0.96))) * 0.35 * swept;
	} else {
		// Rime footprint (rectangle, soft ends): steel-blue frost + spikes, a darker rim.
		vec2 q = abs(m) / size;
		float edge = max(q.x, q.y);
		float body = 1.0 - smoothstep(0.75, 1.0, edge);
		float spikes = 0.0;
		float ang = atan(m.y, m.x);
		float n = vnoise(m * 4.0 + seed * 3.0);
		spikes = step(0.72, n) * body;
		glow = spikes * 0.35 + (1.0 - smoothstep(0.0, 0.06, abs(edge - 0.86))) * 0.25;
		cover = body * (0.40 + 0.15 * n);
	}
	float k = fade;
	vec3 cov_col = vec3(0.05, 0.12, 0.22);
	ALBEDO = cov_col * cover * k + tint.rgb * tint.a * glow * k;
	ALPHA = clamp(cover * k, 0.0, 1.0);
}
