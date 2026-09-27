// tavern_painted.gdshader - the tavern's opaque parts (task 9.V6). Same look as art/shaders/painted.gdshader
// (art-keep.md 0.3: flat colour block, triplanar paint noise, height gradient + contact band, toon ramp, soft rim)
// plus three things the neutral tavern needs:
//   moss       green growth on up-facing surfaces (ledges, roof) and creeping up from the ground
//   pattern 1  stone courses (staggered blocks, per-block value shift, mortar lines that fade out when far)
//   pattern 2  thatch (straw streaks down the slope + darker layer lips), ridge along local Z
// Patterns use MODEL space so they stay put whatever the tavern's rotation is.
// Uniforms: base_color, noise_tex, noise_scale_a/b, spec_strength, rim_color, rim_strength, moss_color, moss_top,
// moss_foot (m), moss_cut (noise threshold, higher = smaller patches), pattern, course_height, block_length.
// Instance uniforms: ao_bottom, ao_height (as painted.gdshader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.46, 0.44, 0.39);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform vec3 moss_color : source_color = vec3(0.30, 0.40, 0.17);
uniform float moss_top = 0.0;
uniform float moss_foot = 0.0;
uniform float moss_cut = 0.5;
uniform int pattern = 0;
uniform float course_height = 0.42;
uniform float block_length = 0.78;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 6.3;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_lp;
varying vec3 v_ln;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_lp = VERTEX;
	v_ln = NORMAL;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	return texture(noise_tex, p.zy * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 n = normalize(v_wn);
	vec3 ln = normalize(v_ln);
	float na = triplanar(v_wp, n, noise_scale_a);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

	if (pattern == 1) {
		// Stone courses on walls: staggered blocks with their own value, thin mortar lines (faded when sub-pixel).
		float vert = 1.0 - smoothstep(0.55, 0.85, abs(ln.y));
		vec2 t = normalize(vec2(-ln.z, ln.x) + vec2(0.0001, 0.0));
		float u = dot(v_lp.xz, t);
		float row = floor(v_lp.y / course_height);
		float fy = fract(v_lp.y / course_height);
		float cu = u / block_length + row * 0.5 + hash2(vec2(row, 3.0)) * 0.35;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		albedo *= mix(1.0, 0.86 + cell * 0.26, vert);
		float d = min(min(fy, 1.0 - fy) * course_height, min(fu, 1.0 - fu) * block_length);
		float px = fwidth(v_lp.y) + fwidth(u);
		float mortar = (1.0 - smoothstep(0.018, 0.045, d)) * (1.0 - smoothstep(0.03, 0.09, px));
		albedo *= 1.0 - mortar * 0.38 * vert;
		// Tops of blocks (ledges) catch a little more light.
		albedo *= 1.0 + smoothstep(0.7, 0.95, ln.y) * 0.06;
	} else if (pattern == 2) {
		// Thatch (ridge along local Z): straw streaks run down the slope, so they vary across Z; darker lip
		// every layer.
		float slope = smoothstep(0.3, 0.6, abs(ln.y));
		float s = texture(noise_tex, vec2(v_lp.z * 9.0, v_lp.y * 1.1)).r;
		float s2 = texture(noise_tex, vec2(v_lp.z * 3.0 + 3.1, v_lp.y * 0.35)).r;
		albedo *= (1.0 + (s - 0.5) * 0.5 * slope) * (1.0 + (s2 - 0.5) * 0.18);
		// Layers: each course of straw ends in a wavy darker lip, lighter just above it (the bundle ends).
		float wave = (texture(noise_tex, vec2(v_lp.z * 1.4, 0.37)).r - 0.5) * 0.22;
		float lay = fract((v_lp.y + wave) / 0.52);
		albedo *= mix(1.0, 1.0 - smoothstep(0.78, 1.0, lay) * 0.34 + smoothstep(0.0, 0.12, lay)
			* (1.0 - smoothstep(0.12, 0.3, lay)) * 0.1, slope);
	}

	// Moss: patches on up-facing surfaces and creeping up from the ground.
	float h = v_wp.y - ao_bottom;
	float up = smoothstep(0.45, 0.8, n.y);
	float patch_n = smoothstep(moss_cut - 0.08, moss_cut + 0.08, nb * 0.7 + na * 0.3);
	float foot = moss_foot > 0.0 ? (1.0 - smoothstep(0.0, moss_foot, h)) * smoothstep(0.35, 0.6, na) : 0.0;
	float m = clamp(moss_top * up * patch_n + foot, 0.0, 1.0);
	albedo = mix(albedo, moss_color * (0.8 + na * 0.45), m);

	// Height gradient (fake sky light + AO) and dark contact band.
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	EMISSION = rim * rim_color * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR
			* ATTENUATION / PI;
	}
}
