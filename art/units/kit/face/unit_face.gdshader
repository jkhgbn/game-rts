// unit_face.gdshader - painted FACE decals (face rework 2026-09-28, art/units/kit/face/face_kit.gd). A unit_painted copy
// whose colour comes from the vertex COLOR (sRGB authored, converted here) instead of base_color, so a whole face
// (eye whites, irises, pupils, highlights, lids, brows, blush gradients, lips, teeth, tongue) is ONE surface = one draw
// call. COLOR.a = 1 - glow: a vertex with alpha < 1 also emits its colour (glowing irises / mouths / gems), scaled by
// `glow_energy` and the kit's glow_boost instance uniform. Same kit instance-uniform slots (kit/README.md A.16):
// ao_bottom 1, ao_height 2, hit_flash 3, flash_color 4, glow_boost 5 -> the kit drives flash + glow on the Face node.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float noise_amount = 0.5;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
uniform float glow_energy = 2.2;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec4 v_col;

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) / vec3(1.055), vec3(2.4)), c / vec3(12.92), step(c, vec3(0.04045)));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_col = vec4(to_linear(COLOR.rgb), COLOR.a);
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(noise_tex, p.zy * scale).r;
	float y = texture(noise_tex, p.xz * scale).r;
	float z = texture(noise_tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	float glow = 1.0 - v_col.a;
	vec3 base = v_col.rgb;
	vec3 albedo = base * (1.0 + (na - 0.5) * 0.20 * noise_amount) * (1.0 + (nb - 0.5) * 0.12 * noise_amount);
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	vec3 emission = base * glow * glow_energy * glow_boost;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint * (1.0 - glow * 0.5);
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
