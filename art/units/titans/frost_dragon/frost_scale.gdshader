// frost_scale.gdshader - Frost Dragon scales / bone horns / claws (task 13c.V1). The Cinder Dragon's dragon_scale.gdshader
// (painted flat colour blocks, paint noise, toon ramp, rim, overlapping scales, belly plates) with a RIME CRUST where
// the Cinder has lava: the flank seam, the belly-plate grooves and the crack patches are frozen white crust (albedo,
// not light), plus a light frost dusting on the upward faces. Only the explicit glow (COLOR.a: lip line) emits.
// Noise is sampled in MODEL space (rest-pose vertices: the meshes are authored in model space), so the paint and the
// rime stay on the body while it flies.
// Vertex COLOR (same layout as dragon_scale, so the Cinder Dragon's leg meshes can be reused with this material):
//   r  rime amount of the part (0 = never frosts: claws, teeth; 1 = full crust)
//   g  colour blend base_color -> belly_color (belly plates / horn tips)
//   b  1 = a lofted part: UV.x = angle around (0 = the top), UV.y = metres along -> flank seam, plates, scales
//   a  explicit glow (the lip line): emits glow_color x a
// Instance uniforms follow the kit slot map (kit/README.md, A.16): hit_flash 3, flash_color 4, glow_boost 5
// (glow_boost scales the cold glow: the breath flare raises it, death puts it out).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.36, 0.54, 0.76);
uniform vec3 belly_color : source_color = vec3(0.84, 0.90, 0.96);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 1.1;
uniform float noise_scale_b = 0.25;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec3 rim_color : source_color = vec3(0.70, 0.88, 1.0);
uniform float rim_strength = 0.35;
uniform vec3 rime_color : source_color = vec3(0.90, 0.96, 1.0);
uniform float rime_glow = 0.06;
uniform float crack_amount = 1.0;
uniform float crack_scale = 0.55;
uniform float frost_top = 0.35;
uniform vec3 glow_color : source_color = vec3(0.55, 0.90, 1.0);
uniform float glow_energy = 2.4;
uniform vec3 groove_color : source_color = vec3(0.30, 0.44, 0.62);
uniform float plate_len = 0.24;
uniform float scale_cols = 26.0;
uniform float scale_len = 0.17;
uniform float flank_width = 0.05;

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

	float rime = 0.0;
	if (COLOR.b > 0.5) {
		float ca = cos(TAU * UV.x);
		// overlapping scales on the back and flanks (rows along the body, every other column offset)
		float cx = UV.x * scale_cols;
		float col_i = floor(cx);
		vec2 cell = vec2(fract(cx), fract(UV.y / scale_len + 0.5 * mod(col_i, 2.0)));
		float d = length((cell - vec2(0.5, 0.05)) * vec2(1.0, 0.8));
		float scale_shade = mix(0.78, 1.07, smoothstep(0.62, 0.25, d));
		albedo *= mix(scale_shade, 1.0, belly);
		// belly plates: a cold blue groove every plate_len, frost caught in it
		float pl = fract(UV.y / plate_len);
		float groove = 1.0 - smoothstep(0.02, 0.07, min(pl, 1.0 - pl));
		float on_belly = smoothstep(-0.30, -0.55, ca);
		albedo = mix(albedo, groove_color, 0.55 * groove * on_belly);
		// the rime seam along each flank, where the blue back meets the pale belly (broken by the noise)
		float flank = exp(-pow((ca + 0.26) / flank_width, 2.0)) * smoothstep(0.25, 0.45, na + 0.15);
		rime = max(flank * 0.9, groove * on_belly * 0.25) * COLOR.r;
	}
	// rime crust patches (ridged noise inside patches of the broad noise): wider and softer than the Cinder's cracks
	float rn = triplanar(v_obj + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
	float ridged = 1.0 - abs(rn * 2.0 - 1.0);
	float crack = smoothstep(0.92, 0.975, ridged) * smoothstep(0.46, 0.60, nb) * crack_amount * COLOR.r;
	// a light frost dusting on the faces that point straight up (rest pose), speckled by the fine noise
	float dust = smoothstep(0.75, 0.95, n.y) * smoothstep(0.52, 0.68, na) * frost_top * COLOR.r;
	rime = max(max(rime, crack), dust);
	albedo = mix(albedo, rime_color, clamp(rime, 0.0, 1.0) * 0.88);

	float heat = clamp(glow_boost, 0.0, 3.0);
	float flow = 0.8 + 0.2 * sin(TIME * 1.3 + v_obj.z * 2.1 + v_obj.y * 1.3);
	vec3 emission = glow_color * glow_energy * COLOR.a * flow * heat;
	albedo = mix(albedo, glow_color * 0.6, COLOR.a * clamp(heat, 0.0, 1.0) * 0.6);
	emission += rime_color * rime_glow * rime * min(heat, 1.0);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	// the kit's gold level-up flash tints the surface (pale parts would add up to white otherwise)
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
