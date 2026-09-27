// magpie_sheen.gdshader - the Magpie's iridescent feather-black (task 10.V6). A copy of the kit's unit_painted.gdshader
// (same painted noise, height gradient, toon ramp, rim, hit / level-up flash) whose colour slides from a near-black
// base to a blue -> green sheen with the view angle and a painted noise, like a magpie's tail and crest in the sun.
// Not emissive except a faint sheen rim (stays under the bloom threshold: the Magpie's one glow point is its eyes).
// Instance uniforms use the kit slot map (kit/README.md "Instance uniform slots", A.16): 1-4 as unit_painted.
//
// Extra uniforms:
//   sheen_a / sheen_b   vec3   the two sheen hues (blue / green); the view angle and the noise pick between them
//   sheen_strength      float  0 = plain base_color, 1 = full sheen at grazing angles
//   sheen_face          float  sheen amount seen head-on (the top-down RTS camera sees most parts at 30-60 deg)
//   sheen_glint         float  rim emission in the sheen colour
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.05, 0.05, 0.08);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform vec3 sheen_a : source_color = vec3(0.10, 0.26, 0.78);
uniform vec3 sheen_b : source_color = vec3(0.06, 0.62, 0.52);
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.85;
uniform float sheen_face : hint_range(0.0, 1.0) = 0.45;
uniform float sheen_glint = 0.35;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	float na = triplanar(v_world_pos, n, noise_scale_a * 4.0);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Hue: blue head-on, green at grazing angles, broken up by painted streaks (feather barbs).
	float hue = clamp(f * 1.25 + (na - 0.5) * 0.9 + 0.12 * sin(v_world_pos.y * 11.0 + v_world_pos.x * 6.0), 0.0, 1.0);
	vec3 sheen = mix(sheen_a, sheen_b, hue);
	float amount = sheen_strength * mix(sheen_face, 1.0, smoothstep(0.1, 0.8, f));
	vec3 albedo = mix(base_color, sheen, amount) * (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.12);

	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
	albedo *= 1.0 - damage * 0.35;

	vec3 emission = vec3(0.0);
	float rim = pow(f, 3.0);
	emission += rim * rim_color * rim_strength;
	emission += sheen * pow(f, 2.0) * sheen_glint;

	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
