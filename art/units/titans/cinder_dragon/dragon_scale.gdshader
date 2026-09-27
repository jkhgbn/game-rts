// dragon_scale.gdshader - Cinder Dragon scales / horns (task 13.V13). Painted style of unit_painted.gdshader (flat colour
// blocks, paint noise, toon ramp, rim) + scales and glowing lava seams.
// Noise is sampled in MODEL space (the rest-pose vertex position: the meshes are authored in model space), so the
// paint and the cracks stay on the body while it flies (world-space noise would swim).
// Vertex COLOR:
//   r  lava amount of the part (0 = never glows: horns, claws; 1 = full seams)
//   g  colour blend base_color -> belly_color (belly plates / horn tips)
//   b  1 = a lofted part: UV.x = angle around (0 = the top), UV.y = metres along -> flank seam, belly plate grooves,
//      overlapping scales (0 = plain part)
//   a  explicit glow (nostrils, lip line): emits lava_color x a
// Instance uniforms follow the kit slot map (kit/README.md, A.16): hit_flash 3, flash_color 4, glow_boost 5
// (glow_boost scales every lava seam: the breath flare raises it, death cools it to 0).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.10, 0.065, 0.06);
uniform vec3 belly_color : source_color = vec3(0.48, 0.10, 0.06);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 1.1;
uniform float noise_scale_b = 0.25;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.18;
uniform vec3 rim_color : source_color = vec3(0.95, 0.42, 0.18);
uniform float rim_strength = 0.35;
uniform vec3 lava_color : source_color = vec3(1.0, 0.40, 0.07);
uniform vec3 lava_hot : source_color = vec3(1.0, 0.78, 0.35);
uniform float lava_energy = 2.6;
uniform float crack_amount = 1.0;
uniform float crack_scale = 0.55;
uniform float plate_len = 0.24;
uniform float scale_cols = 26.0;
uniform float scale_len = 0.17;
uniform float flank_width = 0.045;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

varying vec3 v_obj;
varying vec3 v_objn;

void vertex() {
	v_obj = VERTEX;
	v_objn = NORMAL;
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
	vec3 n = normalize(v_objn);
	float na = triplanar(v_obj, n, noise_scale_a);
	float nb = triplanar(v_obj + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	float belly = clamp(COLOR.g, 0.0, 1.0);
	vec3 albedo = mix(base_color, belly_color, belly);
	albedo *= (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.14);

	float lava = 0.0;
	if (COLOR.b > 0.5) {
		float ca = cos(TAU * UV.x);
		// overlapping scales on the back and flanks (rows along the body, every other column offset)
		float cx = UV.x * scale_cols;
		float col_i = floor(cx);
		vec2 cell = vec2(fract(cx), fract(UV.y / scale_len + 0.5 * mod(col_i, 2.0)));
		float d = length((cell - vec2(0.5, 0.05)) * vec2(1.0, 0.8));
		float scale_shade = mix(0.80, 1.06, smoothstep(0.62, 0.25, d));
		albedo *= mix(scale_shade, 1.0, belly);
		// belly plates: a dark groove every plate_len, glowing
		float pl = fract(UV.y / plate_len);
		float groove = 1.0 - smoothstep(0.02, 0.065, min(pl, 1.0 - pl));
		float on_belly = smoothstep(-0.30, -0.55, ca);
		albedo *= 1.0 - 0.35 * groove * on_belly;
		// the seam along each flank, where the black back meets the red belly
		float flank = exp(-pow((ca + 0.26) / flank_width, 2.0));
		lava = max(flank * 0.85, groove * on_belly * 0.32) * COLOR.r;
	}
	// lava cracks (ridged noise) inside patches of the broad noise
	float rn = triplanar(v_obj + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
	float ridged = 1.0 - abs(rn * 2.0 - 1.0);
	float crack = smoothstep(0.93, 0.985, ridged) * smoothstep(0.48, 0.60, nb) * crack_amount * COLOR.r;
	lava = max(lava, crack);
	lava = max(lava, COLOR.a);

	float heat = clamp(glow_boost, 0.0, 3.0);
	float flow = 0.78 + 0.22 * sin(TIME * 1.7 + v_obj.z * 2.1 + v_obj.y * 1.3);
	vec3 lc = mix(lava_color, lava_hot, clamp((heat - 1.0) * 0.6 + lava * 0.15, 0.0, 1.0));
	vec3 emission = lc * lava_energy * lava * flow * heat;
	// cooled (dead): the seams go dark ash, lit: a hot tint on the albedo
	albedo = mix(albedo, mix(vec3(0.06, 0.05, 0.05), lava_color * 0.35, clamp(heat, 0.0, 1.0)), lava * 0.7);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength * (0.5 + 0.5 * clamp(heat, 0.0, 1.0));

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
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 18.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
