shader_type spatial;
// forge_citadel painted darkness (S13 ruin): unshaded vertex colour with vertex alpha, laid over floors / walls to
// deepen the shadows around the candle without any light. Soft against the scene depth.
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
