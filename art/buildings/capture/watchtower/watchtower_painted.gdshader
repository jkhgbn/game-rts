// watchtower_painted.gdshader - the watchtower's one opaque surface (task 12.V17), shared by every tower through
// watchtower_mat.tres. Same look as art/shaders/painted.gdshader (art-keep.md 0.3: flat colour blocks, triplanar paint
// noise, height gradient + contact band, toon ramp, soft rim) driven by vertex data (WatchtowerMesh):
//   COLOR.rgb sRGB colour block (cloth: a grey shade), COLOR.a moss, UV metres on the surface, UV2.x kind:
//   0 plain, 1 stone courses, 2 planks, 3 shingles, 4 iron (specular), 5 cloth (owner / neutral colour),
//   6 embers (glow_color x glow_energy; char-black when cold), 7 void (dark openings).
// Per tower (instance uniforms, no per-tower material): owner_color / owner_k (cloth), glow_color / glow_energy (the
// cresset: embers + a fake light on everything near it, no real light), select_k (selection rim), flash (capture flash).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float ao_height = 9.4;
uniform float course_height = 0.45;
uniform float block_length = 0.7;
uniform vec3 moss_color : source_color = vec3(0.31, 0.41, 0.17);
uniform vec3 moss_dark : source_color = vec3(0.17, 0.27, 0.09);
uniform vec3 neutral_cloth : source_color = vec3(0.42, 0.41, 0.38);
uniform vec3 char_color : source_color = vec3(0.07, 0.06, 0.055);
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.22;
uniform vec3 select_color : source_color = vec3(1.0, 0.8, 0.4);
uniform vec3 beacon_pos = vec3(1.72, 8.22, 1.72);   // the cresset, model space
uniform float beacon_reach = 4.2;
uniform float beacon_light = 0.55;
// In-game grade 2026-09-30 (row 67, 0 glow points on a neutral tower): an unclaimed tower's cresset is not stone
// cold any more but SMOULDERS: the crack peaks of the char-black embers glow dull red-orange (sparse points over the
// bloom level, no fake light), fading out as the owner's fire takes over (glow_energy 0 -> 1).
uniform vec3 smoulder_color : source_color = vec3(1.0, 0.32, 0.08);
uniform float smoulder = 2.2;

instance uniform vec3 owner_color : source_color = vec3(0.55, 0.54, 0.50);
instance uniform float owner_k = 0.0;
instance uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
instance uniform float glow_energy = 0.0;
instance uniform float select_k = 0.0;
instance uniform float flash = 0.0;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_lp;
varying vec3 v_ln;
varying vec3 v_col;
varying float v_moss;
varying vec2 v_uv;
varying flat float v_kind;

#include "res://art/buildings/tavern/neutral_paint.gdshaderinc"

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_lp = VERTEX;
	v_ln = NORMAL;
	v_kind = UV2.x;
	// Cloth keeps its raw shade (multiplied onto a colour that is already linear); the rest is sRGB -> linear.
	v_col = (UV2.x > 4.5 && UV2.x < 5.5) ? COLOR.rgb : pow(COLOR.rgb, vec3(2.2));
	v_moss = COLOR.a;
	v_uv = UV;
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
	float na = triplanar(v_wp, n, 0.5);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, 0.12);
	int kind = int(v_kind + 0.5);
	vec3 base = v_col;
	if (kind == 5) {
		base = mix(neutral_cloth, owner_color, owner_k) * v_col.r;
	}
	vec3 albedo = base * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	vec3 emit = vec3(0.0);
	float rough = 1.0;
	float moss_ok = 1.0;

	if (kind == 1) {
		// Stone courses: staggered blocks with their own value, thin mortar lines (faded when sub-pixel).
		float row = floor(v_uv.y / course_height);
		float fy = fract(v_uv.y / course_height);
		float cu = v_uv.x / block_length + row * 0.5 + hash2(vec2(row, 3.0)) * 0.35;
		float fu = fract(cu);
		float cell = hash2(vec2(floor(cu), row));
		albedo *= 0.86 + cell * 0.26;
		float d = min(min(fy, 1.0 - fy) * course_height, min(fu, 1.0 - fu) * block_length);
		float px = fwidth(v_uv.y) + fwidth(v_uv.x);
		float mortar = (1.0 - smoothstep(0.018, 0.045, d)) * (1.0 - smoothstep(0.03, 0.09, px));
		albedo *= 1.0 - mortar * 0.4;
		albedo *= 1.0 + smoothstep(0.72, 0.95, fy) * 0.06;   // lit top edge of each course
		// A few darker, weathered blocks.
		albedo *= 1.0 - step(0.9, cell) * 0.12;
	} else if (kind == 2) {
		// Planks: joints across u every 0.25 m, per-board value, grain along v.
		float bw = 0.25;
		float fu = fract(v_uv.x / bw);
		float board = hash2(vec2(floor(v_uv.x / bw), 7.0));
		albedo *= 0.86 + board * 0.24;
		float px = fwidth(v_uv.x) / bw;
		float joint = (1.0 - smoothstep(0.04, 0.1, min(fu, 1.0 - fu))) * (1.0 - smoothstep(0.15, 0.4, px));
		albedo *= 1.0 - joint * 0.45;
		albedo *= 0.94 + 0.12 * texture(noise_tex, vec2(v_uv.x * 2.0, v_uv.y * 0.25)).r;
	} else if (kind == 3) {
		// Wooden shingles: staggered rows up the slope, a dark butt line at the bottom of each row, per-shingle value.
		float rh = 0.24;
		float tw = 0.3;
		float row = floor(v_uv.y / rh);
		float fy = fract(v_uv.y / rh);
		float cu = v_uv.x / tw + mod(row, 2.0) * 0.5;
		float fu = fract(cu);
		float tile = hash2(vec2(floor(cu), row));
		albedo *= 0.82 + tile * 0.32;
		albedo *= mix(0.62, 1.0, smoothstep(0.0, 0.22, fy));
		float px = fwidth(v_uv.x) / tw;
		float gap = (1.0 - smoothstep(0.03, 0.08, min(fu, 1.0 - fu))) * (1.0 - smoothstep(0.2, 0.5, px));
		albedo *= 1.0 - gap * 0.35;
		albedo = mix(albedo, albedo * vec3(1.1, 1.08, 1.04), step(0.92, tile) * 0.8);   // a few pale, sun-bleached ones
	} else if (kind == 4) {
		rough = 0.45;
		moss_ok = 0.0;
	} else if (kind == 5) {
		// Cloth: vertical weave streaks and a darker ragged hem at the bottom of each strip.
		albedo *= 0.92 + 0.1 * sin(v_uv.x * 40.0 + na * 3.0);
		moss_ok = 0.0;
	} else if (kind == 6) {
		// Embers: char-black when cold; glowing, crackling in the owner's glow colour when lit.
		float crack = smoothstep(0.35, 0.75, na + 0.25 * sin(TIME * 3.1 + v_lp.x * 9.0 + v_lp.z * 7.0));
		albedo = char_color * (0.8 + na * 0.4);
		emit += glow_color * glow_energy * (0.45 + 0.75 * crack);
		emit += smoulder_color * smoulder * (1.0 - clamp(glow_energy, 0.0, 1.0)) * crack * crack;
		moss_ok = 0.0;
	} else if (kind == 7) {
		albedo = base;
		moss_ok = 0.0;
	}

	// Moss: patches on up-facing surfaces and creeping up from the ground (amount per vertex).
	if (moss_ok > 0.5 && v_moss > 0.0) {
		float up = smoothstep(0.35, 0.8, n.y);
		float patch_n = smoothstep(0.5, 0.62, nb * 0.7 + na * 0.3);
		float foot = (1.0 - smoothstep(0.0, 0.8, v_lp.y)) * smoothstep(0.35, 0.6, na);
		float m = clamp(v_moss * (up * patch_n * 1.2 + foot + patch_n * 0.2), 0.0, 1.0);
		albedo = mix(albedo, mix(moss_dark, moss_color, smoothstep(0.3, 0.7, na)), m);
	}

	// Height gradient (fake sky light + AO) and dark contact band (art-keep.md 0.3).
	if (kind != 7) {
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, v_lp.y / ao_height));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, v_lp.y));
	}

	// The cresset lights what is near it (emission only, no real light): facing parts take the owner's glow colour.
	if (glow_energy > 0.0) {
		vec3 d = beacon_pos - v_lp;
		float dist = length(d);
		float lam = clamp(dot(normalize(v_ln), d / max(dist, 0.001)), 0.0, 1.0) * 0.8 + 0.2;
		float fall = 1.0 - smoothstep(0.0, beacon_reach, dist);
		emit += albedo * glow_color * glow_energy * beacon_light * fall * fall * lam;
	}

	// G-B neutral paint layer (neutral_paint.gdshaderinc). Embers / openings keep their own look.
	int nk = kind == 1 ? NK_STONE : (kind == 2 ? NK_WOOD : (kind == 3 ? NK_TILE : (kind == 4 ? NK_METAL
		: (kind == 5 ? NK_CLOTH : (kind == 0 ? np_kind_of(np_srgb(v_col), 0.0) : NK_PLAIN)))));
	float bump_h = 0.0;
	float np_px = length(fwidth(v_wp));   // derivatives outside the per-kind branch
	if (kind < 6) {
		vec3 np_emit;
		albedo = np_albedo(albedo, nk, gb_detail, v_lp, normalize(v_ln), n, v_lp.y, np_px, v_wp,
			CAMERA_POSITION_WORLD, noise_tex, bump_h, np_emit);
		emit += np_emit;
	}
	if (gb_detail > 1.5) {
		NORMAL = np_bump(NORMAL, VERTEX, bump_h);
	}
	v_np = vec3(kind == 4 ? 0.4 : 0.0, float(nk), gb_detail);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emit += rim * mix(rim_color * rim_strength, select_color * 0.85, select_k);
	emit += owner_color * flash * (0.18 + rim * 0.9);
	if (kind == 5) {
		emit += albedo * 0.07;
	}
	ALBEDO = albedo;
	EMISSION = emit;
	ROUGHNESS = rough;
}

void light() {
	np_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_np, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
