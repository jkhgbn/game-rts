// memory_grade_mix.gdshader - E34 Ep3 (props/memory_grade.tscn, pass 1 of 2): a full-screen quad (POSITION written in
// clip space, so it covers the frame from any camera) that pulls a set without a memory grade (W02: forge_watch_keep)
// toward mood_ep3_memory.tres: desaturated, shadows lifted to violet, highlights toward warm paper. Mixed at `amount`
// over the frame: glows drawn after the screen copy keep (1 - amount) of their strength.
shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.78;
uniform float saturation = 0.32;
uniform vec3 shadow_col : source_color = vec3(0.13, 0.1, 0.2);
uniform vec3 high_col : source_color = vec3(1.0, 0.9, 0.76);

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.5, 1.0);
}

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 d = mix(vec3(l), c, saturation);
	// split tone: violet in the shadows, warm in the highlights (luminance-weighted)
	vec3 tone = mix(shadow_col, high_col, smoothstep(0.02, 0.7, l));
	d = mix(d, d * tone * 1.6 + shadow_col * 0.25, 0.55);
	ALBEDO = d;
	ALPHA = amount;
}
