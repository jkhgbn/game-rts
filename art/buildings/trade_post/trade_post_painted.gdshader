// trade_post_painted.gdshader - the trading post's opaque parts (task 10.V10). Same look as art/shaders/painted.gdshader
// (art-keep.md 0.3: flat colour block, triplanar paint noise, height gradient + contact band, toon ramp, soft rim) and the
// tavern's moss, plus the patterns the waystation needs (all in MODEL space, so they stay put whatever the rotation):
//   pattern 1  stone courses (staggered blocks, per-block value, mortar lines that fade out when far)
//   pattern 3  clay barrel tiles (rounded columns down the slope, a dark lip per course, per-tile value)
//   pattern 4  striped canvas (stripes across local X, stripe_color every other band, soft sag shading)
//   pattern 5  planks (board joints across the longer horizontal axis, per-board value)
// Uniforms: base_color, stripe_color, noise_tex, noise_scale_a/b, spec_strength, rim_color, rim_strength, moss_color,
// moss_top, moss_foot (m), moss_cut, pattern, course_height, block_length, stripe_width, self_lit.
// Instance uniforms: ao_bottom, ao_height (as painted.gdshader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.46, 0.44, 0.39);
uniform vec3 stripe_color : source_color = vec3(0.80, 0.52, 0.16);
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
uniform float stripe_width = 0.42;
uniform float self_lit = 0.0;   // a little of the albedo added as emission (the sign emblem reads in shade / far)

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 5.0;

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
		albedo *= 1.0 + smoothstep(0.7, 0.95, ln.y) * 0.06;
	} else if (pattern == 3) {
		// Clay barrel tiles: columns run down the slope (across X on the front / back faces, across Z on the hips),
		// each course ends in a darker lip; the rounded tile catches light in its middle.
		float slope = smoothstep(0.3, 0.6, abs(ln.y));
		float u = abs(ln.x) > abs(ln.z) ? v_lp.z : v_lp.x;
		float col_w = 0.27;
		float row = floor(v_lp.y / course_height);
		float cu = u / col_w + mod(row, 2.0) * 0.5;
		float fu = fract(cu);
		float fy = fract(v_lp.y / course_height);
		float tile = hash2(vec2(floor(cu), row));
		float px = fwidth(u) / col_w;
		float round_k = 1.0 - smoothstep(0.25, 0.6, px);
		albedo *= mix(1.0, (0.80 + 0.30 * sin(fu * 3.14159)) * (0.9 + tile * 0.2), slope * round_k);
		albedo *= mix(1.0, 0.95, slope * (1.0 - round_k));
		albedo *= 1.0 - smoothstep(0.80, 0.97, fy) * 0.30 * slope;
		// A few weathered, paler tiles.
		albedo = mix(albedo, albedo * vec3(1.12, 1.08, 1.02), step(0.9, tile) * slope * 0.8);
	} else if (pattern == 4) {
		// Striped canvas: bands across local X, a darker fold every band edge, light sag in the middle of each band.
		float s = v_lp.x / stripe_width;
		float band = mod(floor(s), 2.0);
		albedo = mix(albedo, stripe_color * (1.0 + (na - 0.5) * 0.20), band);
		float fs = fract(s);
		albedo *= 0.92 + 0.12 * sin(fs * 3.14159);
	} else if (pattern == 5) {
		// Planks: board joints across the longer horizontal axis of the local position (vertical boards on walls,
		// long boards on floors / counters), each board a slightly different value.
		float u = abs(ln.x) > abs(ln.z) ? v_lp.z : v_lp.x;
		if (abs(ln.y) > 0.6) {
			u = v_lp.z;
		}
		float bw = 0.24;
		float fu = fract(u / bw);
		float board = hash2(vec2(floor(u / bw), 7.0));
		albedo *= 0.88 + board * 0.22;
		float px = fwidth(u) / bw;
		float joint = (1.0 - smoothstep(0.03, 0.09, min(fu, 1.0 - fu))) * (1.0 - smoothstep(0.15, 0.4, px));
		albedo *= 1.0 - joint * 0.4;
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
	EMISSION = rim * rim_color * rim_strength + albedo * self_lit;
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
