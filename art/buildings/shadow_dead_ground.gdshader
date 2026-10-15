// G-B Shadow buildings: the dead ground a Shadow building leaves round its plinth (ShadowDress, Medium and up).
// Ash-grey earth broken by a Voronoi crack network; the big cracks near the walls glow with a breathing soul-fire in
// the team glow colour; the edge is ragged (fbm) so the stain melts into the map's ground. Lit like the ground
// (shaded, alpha blended, no depth write). ONE material for every Shadow building: per-building values are instance
// uniforms (size, seed, build / damage / wreck state, glow colour).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled, specular_disabled;

instance uniform float half_size = 6.0;   // metres from the centre to the plane's edge
instance uniform float inner = 2.5;       // metres under the plinth: the veins glow from here outward
instance uniform float seed = 0.0;
instance uniform float build = 1.0;       // 0..1 construction: the dead ground spreads as the building rises
instance uniform float damage = 0.0;      // 0..1: wider, brighter cracks
instance uniform float scorch = 0.0;      // 1 = wreck: darker ash, the veins gutter out
instance uniform vec4 glow_color : source_color = vec4(0.70, 0.30, 1.0, 1.0);

uniform float vein_energy = 1.35;
uniform vec3 ash_a : source_color = vec3(0.07, 0.058, 0.08);
uniform vec3 ash_b : source_color = vec3(0.16, 0.14, 0.165);
uniform vec3 crack_col : source_color = vec3(0.025, 0.018, 0.035);

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 h22(vec2 p) {
	float n = h21(p);
	return vec2(n, h21(p + n * 17.0));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.1 + 3.7) * 0.3 + vnoise(p * 4.3 + 9.1) * 0.15;
}

// Approximate distance to the nearest Voronoi cell edge (F2 - F1, one 3 x 3 pass).
float vor_edge(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 r = g + h22(n + g) - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return sqrt(d2) - sqrt(d1);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * half_size;
	float r = length(p);
	vec2 q = p + vec2(seed * 7.31, seed * 3.17);
	float n = fbm(q * 0.45);
	// Ragged edge, spreading with the construction.
	float edge_r = half_size * (0.86 + 0.3 * (n - 0.5)) * mix(0.5, 1.0, build);
	float mask = 1.0 - smoothstep(edge_r * 0.7, edge_r, r);
	// Crack network: big plates (~1.2 m) and a finer craze between them.
	float e = vor_edge(q * 0.82);
	float crack = 1.0 - smoothstep(0.03, 0.085 + damage * 0.05, e);
	float fine = 1.0 - smoothstep(0.02, 0.06, vor_edge(q * 2.3 + 11.0));
	vec3 col = mix(ash_a, ash_b, n);
	col *= 1.0 - 0.3 * scorch;
	col = mix(col, crack_col, max(crack, fine * 0.4));
	// Soul-fire veins: the big cracks near the walls, breathing outward.
	float near = 1.0 - smoothstep(inner, inner + 2.4 + 1.6 * damage, r);
	float breath = 0.55 + 0.45 * sin(TIME * 1.4 - r * 0.9 + seed);
	float vein = crack * near * breath * (1.0 - scorch * 0.75) * build;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	EMISSION = glow_color.rgb * vein * vein_energy * (1.0 + damage);
	ALPHA = clamp(mask * mix(0.74, 0.92, max(crack * 0.8, scorch)), 0.0, 1.0);
}
