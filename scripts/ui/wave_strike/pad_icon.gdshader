// Muster Pad token icon (ui-wave-strike.md 7.1): the unit icon masked to a disc; see MusterPadView.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always, blend_mix, shadows_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
instance uniform float alpha = 1.0;
instance uniform float tint = 1.0;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	if (r > 1.0) discard;
	vec4 c = texture(tex, UV);
	float edge = smoothstep(0.8, 1.0, r);
	ALBEDO = mix(c.rgb * tint, vec3(0.0), edge * 0.55);
	ALPHA = alpha * (1.0 - smoothstep(0.95, 1.0, r));
}
