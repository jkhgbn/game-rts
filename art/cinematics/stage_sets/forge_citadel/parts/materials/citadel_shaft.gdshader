shader_type spatial;
// forge_citadel light shafts / rainbow: additive vertex colour, fades with UV.y (0 = source, 1 = far end) and at the
// sides (UV.x 0..1), a slow dust shimmer. Fake light: no Light3D.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float strength = 0.55;

void fragment() {
	float side = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	float along = (1.0 - UV.y * 0.75) * smoothstep(0.0, 0.08, UV.y);
	float dust = 0.85 + 0.15 * sin(UV.y * 40.0 - TIME * 0.8 + UV.x * 9.0);
	ALBEDO = COLOR.rgb * strength * side * along * dust * COLOR.a;
}
