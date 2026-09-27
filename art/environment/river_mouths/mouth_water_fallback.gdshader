// mouth_water_fallback.gdshader - plain painted teal water for the river mouths (task 12.V5), used only when the
// 12.V1 water material (res://art/environment/water/water_mat.tres) is missing. Same mesh convention as water.gdshader
// (UV.x metres along the flow, UV.y 0..1 across). Opaque, no screen / depth reads, no lights.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 deep_color : source_color = vec3(0.05, 0.20, 0.21);
uniform vec3 bank_color : source_color = vec3(0.20, 0.45, 0.38);
uniform float flow_speed = 0.55;

void fragment() {
	float t = clamp(UV.y, 0.0, 1.0);
	float mid = 1.0 - abs(t - 0.5) * 2.0;
	float n = texture(noise_tex, vec2((UV.x - TIME * flow_speed) * 0.05, t * 1.2)).r;
	ALBEDO = mix(bank_color, deep_color, smoothstep(0.1, 0.8, mid + (n - 0.5) * 0.3));
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
