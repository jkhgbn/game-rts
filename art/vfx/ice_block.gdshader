shader_type spatial;
// `frozen` look (kingdom-ice.md 2.1): a translucent ice block around the unit. Used on a unit BoxMesh
// (size 1) scaled to (radius x 2.2, height x 1.1, radius x 2.2). Cyan edges, facet fresnel, a few
// frozen cracks and a frosted top. One shared material; per-unit `fade` and `seed` are instance uniforms.
// In-game grade pass (2026-09-30): the block was near-white and glowed over the bloom, hiding the frozen unit.
// Now a steel / cyan tint, a clear body (the unit shows through), emission <= 1.5 on the edges only.
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled, specular_schlick_ggx;

uniform vec4 ice_color : source_color = vec4(0.30, 0.58, 0.78, 0.16);
uniform float emission_energy = 0.12;
uniform vec3 edge_color : source_color = vec3(0.35, 0.82, 1.00);
uniform float edge_energy = 1.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float crack(vec3 p, vec3 n, float o) {
	float d = abs(fract(dot(p, n) + o) - 0.5);
	return 1.0 - smoothstep(0.0, 0.018, d);
}

void fragment() {
	vec3 a = abs(lp) * 2.0;                       // 0 at the centre, 1 on a face
	vec3 s = smoothstep(vec3(0.88), vec3(0.985), a);
	float edge = max(max(s.x * s.y, s.y * s.z), s.x * s.z);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float cracks = crack(lp, normalize(vec3(1.3, 2.1, -0.7)) * 1.6, seed)
			* (0.5 + 0.5 * sin(lp.x * 9.0 + lp.z * 7.0 + seed * 11.0));
	cracks = max(cracks, crack(lp, normalize(vec3(-0.9, 0.6, 1.8)) * 1.3, seed * 1.7) * 0.7);
	float top = smoothstep(0.96, 1.0, lp.y * 2.0);
	float frost = top * (0.7 + 0.3 * sin(lp.x * 9.0 + lp.z * 6.0 + seed * 5.0));
	float shine = smoothstep(0.2, 0.0, abs(lp.x + lp.y * 0.6 - lp.z * 0.3 - 0.1)) * 0.25;
	ALBEDO = ice_color.rgb;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	EMISSION = ice_color.rgb * emission_energy
			+ edge_color * edge_energy * (edge * 0.9 + fres * 0.25 + cracks * 0.4 + frost * 0.35 + shine);
	ALPHA = clamp(ice_color.a + edge * 0.45 + fres * 0.18 + cracks * 0.22 + frost * 0.3 + shine * 0.3, 0.0, 0.8) * fade;
}
