// greywater_lodge_painted.gdshader - the Greywater Lodge's opaque parts (task 10.V9). Same look as
// art/shaders/painted.gdshader (art-keep.md 0.3: flat colour block, triplanar paint noise, height gradient + contact
// band, toon ramp, soft rim) plus the patterns a hunters' log hall needs:
//   moss       green growth on up-facing surfaces (roof, ledges) and creeping up from the ground
//   pattern 1  fieldstone courses (staggered blocks, per-block value shift, mortar lines that fade out when far)
//   pattern 2  wooden shingles (staggered tiles per row, dark lip under each row), rows follow the height
//   pattern 3  log grain (streaks along the log, darker bark cracks)
//   pattern 4  fur (tufty streaks, darker roots, lighter tips)
//   pattern 5  vertical boards (plank seams, per-board value)
// Patterns use MODEL space so they stay put whatever the Lodge's rotation is. The horizontal tangent of a face
// (perpendicular to its normal) orients the tiles, boards and grain, so walls along X and along Z both work.
// Uniforms: base_color, noise_tex, noise_scale_a/b, spec_strength, rim_color, rim_strength, moss_color, moss_top,
// moss_foot (m), moss_cut, pattern, course_height, block_length.
// Instance uniforms: ao_bottom, ao_height (as painted.gdshader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.46, 0.44, 0.40);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform vec3 moss_color : source_color = vec3(0.30, 0.40, 0.20);
uniform float moss_top = 0.0;
uniform float moss_foot = 0.0;
uniform float moss_cut = 0.5;
uniform int pattern = 0;
uniform float course_height = 0.36;
uniform float block_length = 0.6;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 4.2;

// PALETTE mode (BuildingPalette, art/buildings/building_palette.gd; B8 material merge 2026-09-30): when
// `palette` is on, every per-material value above comes per vertex from these arrays (index = UV.x; the patterns
// use model space, never UV), so ONE material draws all the painted parts of a building. Emissive entries
// (pal_e.x > 0) stand in for rune_glow.gdshader parts: black albedo, emission = colour x (0.4 + energy x pulse).
//   pal_a rgb base (linear), a spec · pal_b rgb moss, a moss_top · pal_c rgb patch, a moss_foot ·
//   pal_d x moss_cut, y pattern, z course_height, w block_length · pal_e x glow energy, y pulse speed, z phase
uniform bool palette = false;
uniform vec4 pal_a[24];
uniform vec4 pal_b[24];
uniform vec4 pal_c[24];
uniform vec4 pal_d[24];
uniform vec4 pal_e[24];

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_lp;
varying vec3 v_ln;

varying float v_spec;

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

// Horizontal coordinate along a face (perpendicular to its normal's horizontal part).
float along(vec3 lp, vec3 ln) {
	vec2 t = normalize(vec2(-ln.z, ln.x) + vec2(0.0001, 0.0));
	return dot(lp.xz, t);
}

void fragment() {
	int p_i = clamp(int(UV.x + 0.5), 0, 23);
	vec3 p_base = palette ? pal_a[p_i].rgb : base_color;
	float p_spec = palette ? pal_a[p_i].w : spec_strength;
	vec3 p_moss = palette ? pal_b[p_i].rgb : moss_color;
	float p_mtop = palette ? pal_b[p_i].w : moss_top;
	float p_mfoot = palette ? pal_c[p_i].w : moss_foot;
	float p_mcut = palette ? pal_d[p_i].x : moss_cut;
	int p_pat = palette ? int(pal_d[p_i].y + 0.5) : pattern;
	float p_ch = palette ? pal_d[p_i].z : course_height;
	float p_bl = palette ? pal_d[p_i].w : block_length;
	v_spec = p_spec;
	vec3 n = normalize(v_wn);
	vec3 ln = normalize(v_ln);
	float na = triplanar(v_wp, n, noise_scale_a);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = p_base * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	float u = along(v_lp, ln);

	if (p_pat == 1) {
		// Fieldstone courses: staggered blocks with their own value, thin mortar lines (faded when sub-pixel).
		float vert = 1.0 - smoothstep(0.55, 0.85, abs(ln.y));
		float row = floor(v_lp.y / p_ch);
		float fy = fract(v_lp.y / p_ch);
		float cu = u / p_bl + row * 0.5 + hash2(vec2(row, 3.0)) * 0.35;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		albedo *= mix(1.0, 0.84 + cell * 0.30, vert);
		float d = min(min(fy, 1.0 - fy) * p_ch, min(fu, 1.0 - fu) * p_bl);
		float px = fwidth(v_lp.y) + fwidth(u);
		float mortar = (1.0 - smoothstep(0.02, 0.05, d)) * (1.0 - smoothstep(0.03, 0.09, px));
		albedo *= 1.0 - mortar * 0.42 * vert;
		albedo *= 1.0 + smoothstep(0.7, 0.95, ln.y) * 0.06;
	} else if (p_pat == 2) {
		// Shingles on the slopes: rows by height, staggered tiles, each tile its own value, a dark lip at the lower
		// edge of every row and a lighter band just above it.
		float slope = smoothstep(0.3, 0.6, abs(ln.y));
		float wave = (texture(noise_tex, vec2(u * 0.9, 0.61)).r - 0.5) * 0.04;
		float rowf = (v_lp.y + wave) / p_ch;
		float row = floor(rowf);
		float fy = fract(rowf);
		float cu = u / p_bl + row * 0.5;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		float tile = 0.86 + cell * 0.26;
		float lip = 1.0 - (1.0 - smoothstep(0.0, 0.16, fy)) * 0.36;
		float px = fwidth(u) * 2.0;
		float seam = (1.0 - smoothstep(0.02, 0.05, min(fu, 1.0 - fu) * p_bl)) * (1.0 - smoothstep(0.03, 0.1, px));
		float shade = tile * lip * (1.0 - seam * 0.25) * (1.0 + smoothstep(0.55, 0.95, fy) * 0.07);
		albedo *= mix(1.0, shade, slope);
	} else if (p_pat == 3) {
		// Log grain: long streaks along the log, a few dark bark cracks.
		float s = texture(noise_tex, vec2(u * 0.35, v_lp.y * 4.5 + dot(v_lp.xz, ln.xz) * 4.5)).r;
		float s2 = texture(noise_tex, vec2(u * 0.12 + 7.0, v_lp.y * 1.3)).r;
		albedo *= (1.0 + (s - 0.5) * 0.36) * (1.0 + (s2 - 0.5) * 0.16);
		float crack = smoothstep(0.70, 0.78, s) * (1.0 - smoothstep(0.03, 0.09, fwidth(u) + fwidth(v_lp.y)));
		albedo *= 1.0 - crack * 0.3;
	} else if (p_pat == 4) {
		// Fur: tufts streaking down, darker at the roots, light tips.
		float s = texture(noise_tex, vec2(u * 6.0, v_lp.y * 1.6)).r;
		float s2 = texture(noise_tex, vec2(u * 2.2 + 3.7, v_lp.y * 0.7)).r;
		albedo *= (0.78 + s * 0.42) * (0.9 + s2 * 0.2);
	} else if (p_pat == 5) {
		// Vertical boards: seams every board, each board its own value, faint grain.
		float bw = p_bl;
		float cu = u / bw;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), 11.0));
		float px = fwidth(u);
		float seam = (1.0 - smoothstep(0.015, 0.04, min(fu, 1.0 - fu) * bw)) * (1.0 - smoothstep(0.03, 0.09, px));
		float g = texture(noise_tex, vec2(u * 3.0, v_lp.y * 0.4)).r;
		albedo *= (0.88 + cell * 0.22) * (1.0 - seam * 0.45) * (1.0 + (g - 0.5) * 0.14);
	}

	// Moss: patches on up-facing surfaces and creeping up from the ground.
	float h = v_wp.y - ao_bottom;
	float up = smoothstep(0.45, 0.8, n.y);
	float patch_n = smoothstep(p_mcut - 0.08, p_mcut + 0.08, nb * 0.7 + na * 0.3);
	float foot = p_mfoot > 0.0 ? (1.0 - smoothstep(0.0, p_mfoot, h)) * smoothstep(0.35, 0.6, na) : 0.0;
	float m = clamp(p_mtop * up * patch_n + foot, 0.0, 1.0);
	albedo = mix(albedo, p_moss * (0.8 + na * 0.45), m);

	// Height gradient (fake sky light + AO) and dark contact band.
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	EMISSION = rim * rim_color * rim_strength;
	ROUGHNESS = 1.0;
	if (palette && pal_e[p_i].x > 0.0) {
		vec4 ge = pal_e[p_i];
		float gpulse = 0.75 + 0.25 * sin(TIME * ge.y + ge.z);
		ALBEDO = vec3(0.0);
		EMISSION = pal_a[p_i].rgb * (0.4 + ge.x * gpulse);
		v_spec = 0.0;
	}
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (v_spec > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * v_spec * LIGHT_COLOR
			* ATTENUATION / PI;
	}
}
