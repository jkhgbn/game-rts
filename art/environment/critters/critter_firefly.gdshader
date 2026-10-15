// critter_firefly.gdshader - cosmetic fireflies (task 12.V16): emissive camera-facing dots (one quad each), no light.
// Mesh: critter_meshes.gd firefly() (a unit quad, UV 0-1). INSTANCE_CUSTOM = (seed 0-1, -, drift radius m, -).
// Drift: slow sums of sines around the anchor (0.45-1.75 m up). Blink: a short bright pulse every 1.6-3.2 s over a
// faint ember, emission up to ~3.6 (crosses the bloom threshold: art-keep.md 0.4 "glowing points").
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

#include "res://art/environment/critters/critter_common.gdshaderinc"

uniform vec3 glow_color : source_color = vec3(0.86, 1.0, 0.38);
uniform float glow_energy = 3.2;
uniform float size = 0.24;
uniform float ember = 0.30;

varying float v_bright;

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(PARKED, 1.0)).xyz;
		v_bright = 0.0;
	} else {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		vec4 c = INSTANCE_CUSTOM;
		float seed = c.x;
		float r = c.z;
		float t = clock * (0.55 + seed * 0.3) + seed * 50.0;
		vec3 off = vec3(
			(sin(t * 0.37 + seed * 6.2) * 0.72 + sin(t * 0.93 + seed * 2.0) * 0.28) * r,
			1.1 + sin(t * 0.53 + seed * 4.0) * 0.5 + sin(t * 1.41) * 0.15,
			(sin(t * 0.41 + seed * 9.0) * 0.72 + sin(t * 0.87 + seed * 1.3) * 0.28) * r);
		vec3 centre = anchor + off;
		float per = 1.6 + seed * 1.6;
		float ph = fract(clock / per + seed * 3.7);
		float pulse = smoothstep(0.0, 0.06, ph) * (1.0 - smoothstep(0.22, 0.5, ph));
		v_bright = ember + pulse;
		vec3 vc = (VIEW_MATRIX * vec4(centre, 1.0)).xyz;
		float sz = size * s * (0.8 + 0.4 * pulse);
		VERTEX = vc + vec3((UV - 0.5) * 2.0 * sz, 0.0);
	}
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r2 = dot(q, q);
	float core = exp(-r2 * 9.0);
	float halo = exp(-r2 * 2.5) * 0.28;
	ALBEDO = glow_color * glow_energy * v_bright;
	ALPHA = clamp(core + halo, 0.0, 1.0) * step(r2, 1.0);
}
