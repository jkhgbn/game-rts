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
// Palette index, constant per triangle: flat, so branches on the pattern keep derivatives defined (shader lint B).
varying flat int v_pi;

#include "res://art/buildings/tavern/neutral_paint.gdshaderinc"

void vertex() {
	v_pi = clamp(int(UV.x + 0.5), 0, 23);
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
	int p_i = v_pi;
	vec3 p_base = palette ? pal_a[p_i].rgb : base_color;
	float p_spec = palette ? pal_a[p_i].w : spec_strength;
	vec3 p_moss = palette ? pal_b[p_i].rgb : moss_color;
	float p_mtop = palette ? pal_b[p_i].w : moss_top;
	vec3 p_patch = palette ? pal_c[p_i].rgb : patch_color;
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
	float vert = 1.0 - smoothstep(0.55, 0.85, abs(ln.y));

	if (p_pat == 1) {
		// Stone courses on walls: staggered blocks with their own value, thin mortar lines (faded when sub-pixel).
		float u = along(ln);
		float row = floor(v_lp.y / p_ch);
		float fy = fract(v_lp.y / p_ch);
		float cu = u / p_bl + row * 0.5 + hash2(vec2(row, 3.0)) * 0.35;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		albedo *= mix(1.0, 0.84 + cell * 0.3, vert);
		float d = min(min(fy, 1.0 - fy) * p_ch, min(fu, 1.0 - fu) * p_bl);
		float px = fwidth(v_lp.y) + fwidth(u);
		float mortar = (1.0 - smoothstep(0.018, 0.05, d)) * (1.0 - smoothstep(0.03, 0.09, px));
		albedo *= 1.0 - mortar * 0.42 * vert;
		albedo *= 1.0 + smoothstep(0.7, 0.95, ln.y) * 0.06;
	} else if (p_pat == 2) {
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
		c = mix(c, p_patch * (0.6 + cell * 0.2), step(0.982, cell));
		c = mix(c, vec3(0.04, 0.04, 0.05), step(cell, 0.03));
		c *= 1.0 - (1.0 - smoothstep(0.0, 0.22, fy)) * 0.42;
		c *= 1.0 + smoothstep(0.75, 1.0, fy) * 0.06;
		float px = fwidth(cz);
		c *= 1.0 - (1.0 - smoothstep(0.02, 0.06, min(fz, 1.0 - fz))) * 0.25 * (1.0 - smoothstep(0.05, 0.15, px));
		albedo = mix(albedo, c, slope);
	} else if (p_pat == 3) {
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
	} else if (p_pat == 4) {
		// Whitewash: dirty plaster with flaked patches (the dark daub shows) and grime running down.
		float fl = triplanar(v_wp * 2.1 + vec3(3.0), n, 0.5) * 0.7 + nb * 0.3;
		float flake = smoothstep(0.68, 0.71, fl);
		albedo = mix(albedo, p_patch * (0.85 + na * 0.25), flake * vert * 0.85);
		float grime = texture(noise_tex, vec2(along(ln) * 1.7, v_lp.y * 0.18)).r;
		albedo *= 1.0 - smoothstep(0.45, 0.8, grime) * 0.16 * vert;
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

	// G-B neutral paint layer (neutral_paint.gdshaderinc): kind by pattern, the rest by colour.
	int nk = p_pat == 1 ? NK_STONE : (p_pat == 2 ? NK_TILE : (p_pat == 3 ? NK_WOOD : (p_pat == 4 ? NK_PLASTER
		: np_kind_of(np_srgb(p_base), p_spec))));
	float bump_h;
	vec3 np_emit;
	albedo = np_albedo(albedo, nk, gb_detail, v_lp, ln, n, h, length(fwidth(v_wp)), v_wp, CAMERA_POSITION_WORLD,
		noise_tex, bump_h, np_emit);
	if (gb_detail > 1.5) {
		NORMAL = np_bump(NORMAL, VERTEX, bump_h);
	}
	v_np = vec3(p_spec, float(nk), gb_detail);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	EMISSION = rim * rim_color * rim_strength + np_emit;
	ROUGHNESS = 1.0;
	if (palette && pal_e[p_i].x > 0.0) {
		vec4 ge = pal_e[p_i];
		float gpulse = 0.75 + 0.25 * sin(TIME * ge.y + ge.z);
		ALBEDO = vec3(0.0);
		EMISSION = pal_a[p_i].rgb * (0.4 + ge.x * gpulse);
		v_spec = 0.0;
		v_np = vec3(0.0, -1.0, 0.0);
	}
}

void light() {
	np_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_np, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
