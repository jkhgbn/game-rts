// Dusk Keep fallback of the shared painted shader (art-keep.md 0.3). Same uniform names as
// art/shaders/painted.gdshader so the materials can switch to it without changes.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.20, 0.17, 0.26);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float spec_strength = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float crack_strength = 0.0;
uniform vec3 crack_color : source_color = vec3(0.70, 0.30, 1.00);
uniform float crack_speed = 0.7;
uniform float damage = 0.0;
instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 1.0;

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float tri(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	p /= scale;
	return texture(noise_tex, p.zy).r * w.x + texture(noise_tex, p.xz).r * w.y + texture(noise_tex, p.xy).r * w.z;
}

void fragment() {
	vec3 albedo = base_color;
	albedo *= 1.0 + (tri(w_pos, w_nrm, 6.0) - 0.5) * 0.20;
	albedo *= 1.0 + (tri(w_pos, w_nrm, 20.0) - 0.5) * 0.12;
	float rel = w_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, rel / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, rel));
	albedo *= 1.0 - damage * 0.35;
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	float ridged = 1.0 - abs(tri(w_pos + vec3(3.1, 0.0, 1.7), w_nrm, 9.0) * 2.0 - 1.0);
	float c = smoothstep(0.88 - damage * 0.10, 0.95, ridged) * crack_strength;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = crack_color * c * (2.0 + 1.0 * sin(TIME * crack_speed + w_pos.y * 1.7)) + rim * rim_color * rim_strength;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
}
