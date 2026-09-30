shader_type spatial;
// Rime Bulwark wall (CasterIceVfx, task CU.V5 Ice part; caster-units.md 5.2 / 10.5): a jagged slab of rune-ice,
// 4.0 x 2.2 x 0.9 m (the mesh is built at that size, origin at the ground centre, long axis local X). ONE material; the
// state is per instance: `rise` (0-1) grows it out of the ground (clip + a hot rim at the growing top), `melt` (0-1)
// slumps it (the top sinks and bulges, it turns clear and drips), `fade` (0-1) shatters / dissolves it (a ragged cut
// with bright edges), `age` (s) flashes it as it rises. Look: Ice clarity pass (2026-09-30): deep steel-blue body,
// cyan facet edges and fresnel, a band of carved runes glowing inside (emission <= 1.4, under the bloom except the
// rune strokes); never near-white. Lit (the sun shapes the facets), flat facets from screen derivatives.
render_mode blend_mix, depth_draw_always, cull_back, shadows_disabled, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.10, 0.24, 0.44);
uniform vec3 body_color : source_color = vec3(0.24, 0.47, 0.72);
uniform vec3 edge_color : source_color = vec3(0.42, 0.84, 1.00);
uniform vec3 rune_color : source_color = vec3(0.30, 0.86, 1.00);
uniform float rune_energy = 2.2;
uniform float height = 2.2;
uniform float half_length = 2.0;
uniform float body_alpha = 0.84;
instance uniform float rise = 1.0;
instance uniform float melt = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 9.0;
instance uniform float seed = 0.0;

varying vec3 lp;
varying float h01;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Distance to a segment.
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// One carved rune (q in metres, ~0.5 m tall): a stem, two rising branches, a foot bar (the Rimecarver's mark).
float rune(vec2 q) {
	float d = seg(q, vec2(0.0, -0.22), vec2(0.0, 0.22));
	d = min(d, seg(q, vec2(0.0, 0.02), vec2(-0.12, 0.16)));
	d = min(d, seg(q, vec2(0.0, 0.02), vec2(0.12, 0.16)));
	d = min(d, seg(q, vec2(-0.1, -0.22), vec2(0.1, -0.22)));
	return d;
}

void vertex() {
	lp = VERTEX;
	float hy = clamp(VERTEX.y / height, 0.0, 1.0);
	// Melt: the top sinks toward the ground, the sides bulge out, a sag in the middle of the length.
	float m = melt;
	VERTEX.y *= 1.0 - m * (0.55 + 0.25 * hy);
	VERTEX.xz *= 1.0 + m * 0.18 * (1.0 - hy);
	VERTEX.y -= m * 0.25 * (1.0 - abs(VERTEX.x) / half_length) * hy;
	h01 = hy;
}

void fragment() {
	float top = height * rise;
	float n = vnoise(lp.xz * 3.1 + vec2(seed * 7.0, lp.y * 2.3));
	if (lp.y > top + (n - 0.5) * 0.12) {
		discard;
	}
	// Shatter / dissolve: a ragged noisy cut.
	float cut = fade * 1.2 - 0.1;
	float dn = vnoise(lp.xy * 5.0 + seed * 3.0) * 0.6 + vnoise(lp.zy * 9.0 - seed) * 0.4;
	if (dn > cut) {
		discard;
	}
	float cut_edge = 1.0 - smoothstep(0.0, 0.06, cut - dn);
	// Flat facet normal from screen derivatives (the crystal look).
	vec3 fn = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(fn, VIEW) < 0.0) {
		fn = -fn;
	}
	NORMAL = fn;
	float fres = pow(1.0 - clamp(dot(fn, VIEW), 0.0, 1.0), 2.0);
	float hy = clamp(lp.y / height, 0.0, 1.0);
	vec3 col = mix(deep_color, body_color, smoothstep(0.0, 0.9, hy) * (0.7 + 0.3 * n));
	col = mix(col, edge_color, fres * 0.55);
	ALBEDO = col * (1.0 - melt * 0.25);
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
	// Inner runes: a row of carved marks at mid-height on both long faces (object space x / y).
	float cell = 1.05;
	float cx = (fract(lp.x / cell + 0.5 + seed * 0.37) - 0.5) * cell;
	float rd = rune(vec2(cx, lp.y - 1.0));
	float stroke = 1.0 - smoothstep(0.018, 0.042, rd);
	float halo = (1.0 - smoothstep(0.03, 0.16, rd)) * 0.25;
	float inner = step(abs(lp.x), half_length - 0.35) * (1.0 - melt);
	// Growth rim: the top edge glows while rising, and the whole wall flashes once at full height.
	float rim = (1.0 - smoothstep(0.0, 0.14, top - lp.y)) * step(rise, 0.995);
	float flash = exp(-max(age - 0.3, 0.0) * 6.0) * step(0.0, age) * 0.6;
	EMISSION = rune_color * rune_energy * (stroke + halo) * inner * (0.75 + 0.25 * sin(TIME * 2.0 + seed * 6.0))
		+ edge_color * (rim * 1.4 + cut_edge * 1.6 + flash * fres * 1.2 + fres * 0.12);
	ALPHA = clamp(body_alpha * (1.0 - melt * 0.45) + fres * 0.12 + cut_edge * 0.3, 0.0, 1.0);
}
