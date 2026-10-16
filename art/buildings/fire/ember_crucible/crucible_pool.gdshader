// crucible_pool.gdshader - the Ember Crucible annex's fake light pool (task 13c.V7): a soft warm radial glow disc on the
// annex floor instead of a real light (art-keep.md 0.4: 0 real lights). Radial falloff from the UV centre, a soft
// flicker, scaled per instance by glow_boost (0 = cold, 1 = lit, > 1 = forge flare).
// G-F round 3 item 6 (docs/art/gf_r3_fire_keep.md): alpha-blended, colour at value ~0.5 and alpha <= 0.6, so the floor
// warms instead of an additive square burning toward white.
// glow_boost sits on slot 5 like the kit's unit_glow.gdshader (kit/README.md "Instance uniform slots"), so the annex
// drives every glow of its own with one parameter name.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec3 pool_color : source_color = vec3(1.0, 0.48, 0.16);
uniform float strength = 0.4;
uniform float value = 0.21;   // linear scale on pool_color: ~0.5 sRGB value
uniform float max_alpha = 0.6;
uniform float flicker_speed = 6.3;

instance uniform float glow_boost : instance_index(5) = 1.0;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float a = 1.0 - smoothstep(0.0, 1.0, length(d));
	a *= a;
	float flicker = 0.86 + 0.14 * sin(TIME * flicker_speed) * sin(TIME * flicker_speed * 0.47 + 1.3);
	ALBEDO = pool_color * value;
	ALPHA = clamp(a * strength * flicker * glow_boost, 0.0, max_alpha);
}
