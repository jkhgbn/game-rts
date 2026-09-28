// heart_wave.gdshader - E34 Ep3: the heart-stone's shock shell (props/heart_pulse.tscn). A sphere drawn only at its
// silhouette (bright where seen edge-on), so it reads as a ring of amber light swelling out from any camera. Additive.
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float energy = 1.0;
uniform float width = 7.0;

void fragment() {
	float edge = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float k = pow(edge, width) * (1.0 - pow(edge, 40.0));
	ALBEDO = color.rgb * energy * k;
	ALPHA = clamp(k, 0.0, 1.0);
}
