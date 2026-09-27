// roc_feather.gdshader - the Roc's painted plumage, beak and talons (task 12.V28). Painted style of the kit's
// unit_painted.gdshader (flat colour blocks, paint noise, toon ramp, rim, hit / level-up flash) + feather rows and a
// view-angle sheen (the Duskwing's violet, a faint steel glint on the Stormcrest).
// Noise is sampled in MODEL space (rest-pose vertices: the meshes are authored in model space), so the paint stays on
// the feathers while the bird flies (world-space noise would swim). Opaque, no screen / depth reads.
// Vertex COLOR (roc_mesh.gd):
//   r  feather-row pattern amount (scallops in UV metres: UV.x across, UV.y along the feathers)
//   g  blend base_color -> pale_color (belly, throat, crest, underwing, tail bands; beak tip on the horn material)
//   b  blend -> tip_color (primary fingertips, tail tip, trailing edge band, talons)
//   a  shaft line along a feather blade (UV.x 0..1 across the blade)
// Instance uniforms follow the kit slot map (kit/README.md, A.16): hit_flash 3, flash_color 4.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.21, 0.34, 0.59);
uniform vec3 pale_color : source_color = vec3(0.84, 0.88, 0.93);
uniform vec3 tip_color : source_color = vec3(0.07, 0.10, 0.20);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 1.4;
uniform float noise_scale_b = 0.3;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.06;
uniform vec3 rim_color : source_color = vec3(0.60, 0.78, 1.00);
uniform float rim_strength = 0.3;
// feather rows: each feather lighter in the middle, darker at its scalloped edge
uniform float row_len = 0.2;
uniform float col_w = 0.16;
uniform float edge_dark = 0.26;
uniform float mid_light = 0.08;
// view-angle sheen (albedo tint + a glint in emission)
uniform vec3 sheen_color : source_color = vec3(0.55, 0.78, 1.0);
uniform vec3 sheen_color_b : source_color = vec3(0.45, 0.65, 0.95);
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.2;
uniform float sheen_face : hint_range(0.0, 1.0) = 0.3;
uniform float sheen_glint = 0.12;
// top light: backs catch the sky, bellies stay in their own shade (model-space normal)
uniform float top_light = 0.14;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

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
	vec3 albedo = mix(base_color, pale_color, clamp(COLOR.g, 0.0, 1.0));
	albedo = mix(albedo, tip_color, clamp(COLOR.b, 0.0, 1.0));
	albedo *= (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.14);

	// feather rows (offset every other column), rounded tips pointing along +UV.y
	if (COLOR.r > 0.01) {
		float cx = UV.x / col_w;
		float ci = floor(cx);
		vec2 cell = vec2(fract(cx), fract(UV.y / row_len + 0.5 * mod(ci, 2.0)));
		float d = length((cell - vec2(0.5, 0.0)) * vec2(1.0, 0.85));
		float shade = mix(1.0 - edge_dark, 1.0 + mid_light, smoothstep(0.66, 0.3, d));
		albedo *= mix(1.0, shade, COLOR.r);
	}
	// shaft (rachis) line along a blade
	if (COLOR.a > 0.01) {
		float sh = exp(-pow((UV.x - 0.5) / 0.05, 2.0));
		albedo = mix(albedo, mix(albedo, pale_color, 0.35) * 1.1, sh * COLOR.a * 0.6);
	}
	albedo *= mix(1.0 - top_light, 1.0 + top_light * 0.5, smoothstep(-0.7, 0.7, n.y));

	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 sheen = mix(sheen_color, sheen_color_b, clamp(na * 1.4 - 0.2 + f * 0.5, 0.0, 1.0));
	float amount = sheen_strength * mix(sheen_face, 1.0, smoothstep(0.1, 0.8, f)) * (1.0 - 0.6 * clamp(COLOR.g, 0.0, 1.0));
	albedo = mix(albedo, sheen * (max(max(albedo.r, albedo.g), albedo.b) + 0.1), amount);

	vec3 emission = vec3(0.0);
	emission += pow(f, 3.0) * rim_color * rim_strength;
	emission += sheen * pow(f, 3.0) * sheen_glint * (1.0 - 0.6 * clamp(COLOR.g, 0.0, 1.0));

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
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 20.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
