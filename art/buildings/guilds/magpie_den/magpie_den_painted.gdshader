// magpie_den_painted.gdshader - the Magpie Den's opaque parts (task 10.V8). Same look as art/shaders/painted.gdshader
// (art-keep.md 0.3: flat colour block, triplanar paint noise, height gradient + contact band, toon ramp, soft rim)
// plus the patterns a ramshackle thieves' house in a ruin needs:
//   moss       green growth on up-facing surfaces and creeping up from the ground (ruin stone)
//   pattern 1  stone courses (staggered blocks, per-block value shift, mortar lines that fade out when far)
//   pattern 2  shingles (rows along the slope, staggered tiles, dark lips, a few patched / missing tiles)
//   pattern 3  planks (vertical boards with dark seams, per-board value, board ends)
//   pattern 4  whitewash (dirty plaster: flaked patches show the dark daub under it, grime streaks)
// Patterns use MODEL space so they stay put whatever the house's rotation is.
// Uniforms: base_color, noise_tex, spec_strength, rim_color, rim_strength, moss_color, moss_top, moss_foot, moss_cut,
// pattern, course_height, block_length, patch_color. Instance uniforms: ao_bottom, ao_height (as painted.gdshader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.42, 0.42, 0.40);
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
uniform vec3 patch_color : source_color = vec3(0.45, 0.35, 0.24);

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 7.0;

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

// Horizontal coordinate along a wall face (model space), so vertical patterns follow each face.
float along(vec3 ln) {
	vec2 t = normalize(vec2(-ln.z, ln.x) + vec2(0.0001, 0.0));
	return dot(v_lp.xz, t);
}

void fragment() {
	vec3 n = normalize(v_wn);
	vec3 ln = normalize(v_ln);
	float na = triplanar(v_wp, n, noise_scale_a);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	float vert = 1.0 - smoothstep(0.55, 0.85, abs(ln.y));

	if (pattern == 1) {
		// Stone courses on walls: staggered blocks with their own value, thin mortar lines (faded when sub-pixel).
		float u = along(ln);
		float row = floor(v_lp.y / course_height);
		float fy = fract(v_lp.y / course_height);
		float cu = u / block_length + row * 0.5 + hash2(vec2(row, 3.0)) * 0.35;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		albedo *= mix(1.0, 0.84 + cell * 0.3, vert);
		float d = min(min(fy, 1.0 - fy) * course_height, min(fu, 1.0 - fu) * block_length);
		float px = fwidth(v_lp.y) + fwidth(u);
		float mortar = (1.0 - smoothstep(0.018, 0.05, d)) * (1.0 - smoothstep(0.03, 0.09, px));
		albedo *= 1.0 - mortar * 0.42 * vert;
		albedo *= 1.0 + smoothstep(0.7, 0.95, ln.y) * 0.06;
	} else if (pattern == 2) {
		// Shingles (ridge along local X): rows by height, tiles along X, staggered; each row's lower edge is a dark
		// lip (the tile above overlaps it). A few tiles are patched with raw wood, a few are missing (dark holes).
		float slope = smoothstep(0.25, 0.55, abs(ln.y));
		float wave = (texture(noise_tex, vec2(v_lp.x * 0.9, 0.61)).r - 0.5) * 0.06;
		float ry = (v_lp.y + wave) / 0.21;
		float row = floor(ry);
		float fy = fract(ry);
		float cz = v_lp.x / 0.38 + row * 0.5 + hash2(vec2(row, 7.0)) * 0.3;
		float fz = fract(cz);
		float cell = hash2(vec2(floor(cz), row) + sign(v_lp.z) * 13.0);
		float tile = 0.86 + cell * 0.26;
		vec3 c = albedo * tile;
		c = mix(c, patch_color * (0.6 + cell * 0.2), step(0.982, cell));
		c = mix(c, vec3(0.04, 0.04, 0.05), step(cell, 0.03));
		c *= 1.0 - (1.0 - smoothstep(0.0, 0.22, fy)) * 0.42;
		c *= 1.0 + smoothstep(0.75, 1.0, fy) * 0.06;
		float px = fwidth(cz);
		c *= 1.0 - (1.0 - smoothstep(0.02, 0.06, min(fz, 1.0 - fz))) * 0.25 * (1.0 - smoothstep(0.05, 0.15, px));
		albedo = mix(albedo, c, slope);
	} else if (pattern == 3) {
		// Planks: vertical boards (horizontal on up-facing tops), dark seams, per-board value, staggered board ends.
		float u = mix(v_lp.x + v_lp.z * 0.37, along(ln), vert);
		float cu = u / 0.27;
		float board = floor(cu);
		float fu = fract(cu);
		float bh = hash2(vec2(board, 1.0 + step(0.5, vert)));
		float fv = fract((v_lp.y + bh * 1.3) / 1.15);
		float piece = hash2(vec2(board, floor((v_lp.y + bh * 1.3) / 1.15)));
		albedo *= 0.8 + piece * 0.34;
		float grain = texture(noise_tex, vec2(u * 3.0, v_lp.y * 0.25)).r;
		albedo *= 1.0 + (grain - 0.5) * 0.25;
		float px = fwidth(cu);
		float seam = (1.0 - smoothstep(0.04, 0.1, min(fu, 1.0 - fu))) * (1.0 - smoothstep(0.08, 0.25, px));
		float end = (1.0 - smoothstep(0.0, 0.025, min(fv, 1.0 - fv))) * vert * (1.0 - smoothstep(0.08, 0.25, px));
		albedo *= 1.0 - max(seam, end) * 0.45;
	} else if (pattern == 4) {
		// Whitewash: dirty plaster with flaked patches (the dark daub shows) and grime running down.
		float fl = triplanar(v_wp * 2.1 + vec3(3.0), n, 0.5) * 0.7 + nb * 0.3;
		float flake = smoothstep(0.68, 0.71, fl);
		albedo = mix(albedo, patch_color * (0.85 + na * 0.25), flake * vert * 0.85);
		float grime = texture(noise_tex, vec2(along(ln) * 1.7, v_lp.y * 0.18)).r;
		albedo *= 1.0 - smoothstep(0.45, 0.8, grime) * 0.16 * vert;
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
