// glow_pool.gdshader - a soft additive pool of light on the ground (no real light, task A2.3).
// Used under the Ember Crown altar and under every crystal node. PlaneMesh, UV 0-1 over the plane.
// Per instance: `intensity` and `tint` (the crown changes colour with its state, crystal nodes dim as they
// deplete). A slow wobble keeps it alive.
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform vec3 color : source_color = vec3(0.35, 0.8, 1.0);
uniform float strength = 0.5;
uniform float inner = 0.0;        // radius (0-1) where the pool is brightest (a ring when > 0)
uniform float falloff = 2.0;
instance uniform float intensity = 1.0;
instance uniform vec4 tint = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = 1.0 - smoothstep(inner, 1.0, r);
	a = pow(a, falloff);
	a *= smoothstep(0.0, max(inner, 0.001), r) * step(0.001, inner) + (1.0 - step(0.001, inner));
	float wob = 0.9 + 0.1 * sin(TIME * 1.3 + r * 5.0);
	ALBEDO = color * tint.rgb * a * strength * intensity * wob;
}
