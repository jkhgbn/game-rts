// mender_painted.gdshader - the Mender's ONE painted material (task 9.V4, champions.md 4.6: <= 5 materials).
// A copy of art/units/kit/unit_painted.gdshader (same toon ramp, paint noise, height AO, rim, hit / level-up flash,
// same instance uniform slots of kit/README.md A.16) where the colour block comes from a small PALETTE picked per
// vertex instead of one base_color, so one material paints linen, wicker, herb cloth, skin, leather, copper...
// The meshes are baked by mender.gd with  UV.x = palette index  and  UV.y = surface mode  (the kit merge keeps UV):
//   mode 0 cloth (matte) · 1 wicker weave (object-space rows + stakes) · 2 metal (spec 0.4, patina)
//   mode 3 hair (vertical strands) · 4 wood (grain) · 5 skin (soft rim, no noise darkening)
// Palette = sRGB colours of champions.md 4.6 (linen, wicker, herb green) + the neutral extras; index table in mender.gd.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float weave_scale = 21.0;      // wicker rows per metre (object space)
uniform float weave_depth = 0.34;      // darkness of the gaps between strands

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

// sRGB palette (mender.gd PAL_* constants use the same indices).
const vec3 PAL[20] = vec3[20](
	vec3(0.80, 0.76, 0.62),   // 0  linen (apron, blouse, kerchief)
	vec3(0.55, 0.40, 0.20),   // 1  wicker
	vec3(0.30, 0.50, 0.30),   // 2  herb green cloth (dress)
	vec3(0.90, 0.70, 0.55),   // 3  skin
	vec3(0.30, 0.19, 0.11),   // 4  leather (boots, straps, pouch)
	vec3(0.74, 0.44, 0.22),   // 5  copper (the kettle)
	vec3(0.42, 0.28, 0.15),   // 6  wood (staff, pennant pole)
	vec3(0.52, 0.25, 0.12),   // 7  chestnut-red hair (both siblings)
	vec3(0.10, 0.08, 0.08),   // 8  eye bar
	vec3(0.68, 0.54, 0.35),   // 9  cork
	vec3(0.34, 0.23, 0.11),   // 10 dark wicker (rims, bands, basket inside)
	vec3(0.17, 0.29, 0.18),   // 11 dark herb (hem, stockings)
	vec3(0.46, 0.66, 0.30),   // 12 fresh herb leaves
	vec3(0.21, 0.20, 0.21),   // 13 iron (chain, bail)
	vec3(0.93, 0.58, 0.48),   // 14 blush (nose, cheeks)
	vec3(0.60, 0.31, 0.20),   // 15 rust (bedroll)
	vec3(0.66, 0.60, 0.47),   // 16 linen shadow (pocket, cuffs)
	vec3(0.82, 0.64, 0.30),   // 17 brass (finials, buckles)
	vec3(0.62, 0.62, 0.58),   // 18 grey (beard streak, pestle)
	vec3(0.25, 0.17, 0.10)    // 19 dark leather (soles)
);

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local;
varying float v_spec;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local = VERTEX;
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
	int pi = clamp(int(UV.x + 0.5), 0, 19);
	int mode = int(UV.y + 0.5);
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = srgb_to_linear(PAL[pi]);
	float spec = 0.0;
	float rim_k = 1.0;
	if (mode == 5) {
		// skin: gentle paint noise only, warm and soft
		albedo *= (1.0 + (na - 0.5) * 0.10) * (1.0 + (nb - 0.5) * 0.06);
		rim_k = 0.7;
	} else {
		albedo *= (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	}
	if (mode == 1) {
		// Wicker: horizontal strands (rows) with dark gaps, staggered over / under the vertical stakes.
		vec3 p = v_local * weave_scale;
		float row = floor(p.y);
		float fy = fract(p.y);
		float u = (p.x - p.z) * 0.75 + row * 0.5;
		float fu = fract(u);
		float strand = smoothstep(0.0, 0.24, fy) * smoothstep(1.0, 0.76, fy);
		float over = smoothstep(0.0, 0.2, fu) * smoothstep(1.0, 0.8, fu);
		float lit = strand * (0.6 + 0.4 * over);
		albedo *= mix(1.0 - weave_depth, 1.0 + weave_depth * 0.35, lit);
	} else if (mode == 2) {
		spec = 0.4;
		albedo *= 0.88 + 0.24 * na;   // hammered patina
	} else if (mode == 3 || mode == 4) {
		// Strands / grain: noise stretched along the part's local y.
		float s = texture(noise_tex, vec2((v_local.x + v_local.z) * (mode == 3 ? 9.0 : 5.0), v_local.y * 0.8)).r;
		albedo *= (mode == 3 ? 0.80 : 0.84) + (mode == 3 ? 0.40 : 0.32) * s;
		spec = mode == 3 ? 0.08 : 0.0;
	}
	v_spec = spec;

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = rim * rim_color * rim_strength * rim_k;

	// Same gold level-up tint as unit_painted (A.17).
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
	if (v_spec > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * v_spec * LIGHT_COLOR * ATTENUATION / PI;
	}
}
