// crown_gold.gdshader - painted gold for the Ember Crown and its altar trims (task A2.3).
// Colour blocks come from vertex colours (mesh_kit.gd conventions: COLOR.rgb sRGB, COLOR.a height 0-1),
// shading follows art-keep.md 0.3 (toon ramp, painted noise, rim) plus the "trim metal" specular:
// a hard-edged toon highlight so gold reads as metal from the RTS camera without real reflections.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 spec_color : source_color = vec3(1.0, 0.88, 0.62);
uniform float spec_strength = 1.1;
uniform float spec_power = 26.0;
uniform vec3 rim_color : source_color = vec3(1.0, 0.78, 0.42);
uniform float rim_strength = 0.35;
uniform float self_glow = 0.06;   // gold never goes muddy in shadow

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_col;
varying float v_grad;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_grad = COLOR.a;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	return texture(noise_tex, p.zy * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

void fragment() {
	vec3 n = normalize(v_wn);
	float na = triplanar(v_wp, n, 1.3);
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.18);
	albedo *= mix(0.82, 1.10, v_grad);
	// Brushed bands: faces turned to the sky are brighter (painted "lit top" of metal).
	albedo *= 1.0 + max(n.y, 0.0) * 0.15;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	ROUGHNESS = 0.4;
	EMISSION = albedo * self_glow + rim * rim_color * rim_strength;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	vec3 hv = normalize(LIGHT + VIEW);
	float s = pow(max(dot(NORMAL, hv), 0.0), spec_power);
	s = smoothstep(0.25, 0.45, s);
	SPECULAR_LIGHT += s * spec_strength * spec_color * LIGHT_COLOR * ATTENUATION;
}
