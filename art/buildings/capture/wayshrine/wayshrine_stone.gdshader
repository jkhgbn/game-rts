// wayshrine_stone.gdshader - every stone part of the Wayshrine (task 12.V18): the dais, the carved standing stone, the
// marker stones, the floating rune stone and its shards. ONE shared material (wayshrine_stone_mat.tres); the state of
// each shrine lives in instance uniforms, so no material is ever created at runtime.
// Same painted look as the map's stone props (nature_painted.gdshader stone path / art-keep.md 0.3): vertex-colour blocks,
// triplanar paint noise, moss caps on the faces turned to the sky, height gradient + dark contact band, toon ramp, soft rim.
// Meshes come from build_wayshrine.gd, which bakes per vertex:
//   COLOR.rgb  sRGB colour block of the part (+ a small per-face value jitter)
//   COLOR.a    0 at the part's bottom -> 1 at its top (height gradient: fake sky light + AO)
//   UV.x       moss amount (0 = bare)
//   UV.y       height in metres ABOVE THE GROUND at rest (the floating rune stone bakes its 1.6 m lift in): contact band +
//              the capture fill, which climbs every carved rune of the shrine from the dais to the rune stone
//   UV2.x      rune mask: 1 = carved groove / inlay (dark stone when dormant, glows in `rune_color` when lit)
// Instance uniforms (driven by wayshrine.gd): rune_color, rune_energy (0.1 dormant, ~1.5 owned, ~3 awake), cap_color +
// cap_ratio (the runes below 0.2 + ratio x 1.8 m burn in the capturer's colour, with a bright leading edge), flare
// (blessing flash), select_k (selection rim).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 moss_color : source_color = vec3(0.34, 0.47, 0.13);
uniform vec3 moss_dark : source_color = vec3(0.16, 0.29, 0.07);
uniform vec3 groove_color : source_color = vec3(0.075, 0.07, 0.085);
uniform float stone_top_light = 0.30;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.12;
uniform vec3 select_rim : source_color = vec3(1.0, 0.84, 0.48);
uniform float fill_base = 0.2;     // capture fill height at ratio 0 (m)
uniform float fill_span = 1.8;     // + ratio x span (m): ratio 1 reaches over the rune stone (~1.95 m)

instance uniform vec4 rune_color = vec4(0.46, 0.54, 0.70, 1.0);
instance uniform float rune_energy = 0.1;
instance uniform vec4 cap_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float cap_ratio = 0.0;
instance uniform float flare = 0.0;
instance uniform float select_k = 0.0;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_col;
varying float v_grad;
varying float v_y;
varying float v_moss;
varying float v_rune;
varying vec3 v_lp;
varying vec3 v_ln;

#include "res://art/buildings/tavern/neutral_paint.gdshaderinc"

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_grad = COLOR.a;
	v_y = UV.y;
	v_moss = UV.x;
	v_rune = UV2.x;
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

void fragment() {
	vec3 n = normalize(v_wn);
	float na = triplanar(v_wp, n, 0.5);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, 0.12);
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	// Moss / lichen: big soft caps on the faces turned to the sky (never a fine camouflage pattern).
	float nlow = texture(noise_tex, v_wp.xz * 0.3 + vec2(5.3, 2.1)).r;
	float moss = smoothstep(0.60, 0.68, (n.y - 0.55) * 1.4 + (nlow - 0.5) * 1.0 + (na - 0.5) * 0.12) * v_moss;
	albedo *= 1.0 + max(n.y, 0.0) * stone_top_light;
	albedo = mix(albedo, mix(moss_dark, moss_color, smoothstep(0.3, 0.7, na)), moss);
	// Height gradient (0.72 -> 1.08) and the dark contact band.
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, v_y));

	// Carved runes: a dark groove, lit by the shrine's state; the capture fill climbs them in the capturer's colour.
	float fill_h = fill_base + cap_ratio * fill_span;
	float capturing = step(0.001, cap_ratio);
	float filled = capturing * (1.0 - smoothstep(fill_h - 0.03, fill_h, v_y));
	float edge = capturing * exp(-abs(v_y - fill_h) * 16.0);
	float lit = smoothstep(1.0, 2.5, rune_energy);                 // only a lit shrine gets the climbing waves
	float wave = pow(0.5 + 0.5 * sin(v_y * 7.0 - TIME * 2.6), 6.0) * lit;
	float pulse = 0.88 + 0.12 * sin(TIME * 1.9 + v_y * 2.0);
	vec3 state_glow = rune_color.rgb * rune_energy * pulse * (1.0 + wave * 0.45);
	vec3 cap_glow = cap_color.rgb * max(rune_energy, 2.6) * (1.0 + edge * 1.6);
	vec3 glow = mix(state_glow, cap_glow, filled) * (1.0 + flare * 1.6);
	albedo = mix(albedo, groove_color, v_rune);

	// G-B neutral paint layer (neutral_paint.gdshaderinc): weathered stone; the rune light spills a little onto the
	// stone around the grooves (Medium+), so a lit / owned shrine glows in its colour from the RTS camera.
	float bump_h;
	vec3 np_emit;
	albedo = np_albedo(albedo, NK_STONE, gb_detail * (1.0 - v_rune), v_lp, normalize(v_ln), n, v_y,
		length(fwidth(v_wp)), v_wp, CAMERA_POSITION_WORLD, noise_tex, bump_h, np_emit);
	if (gb_detail > 1.5) {
		NORMAL = np_bump(NORMAL, VERTEX, bump_h);
	}
	v_np = vec3(0.0, float(NK_STONE), gb_detail);
	vec3 spill = gb_detail > 0.5 ? albedo * glow * 0.05 * (1.0 - v_rune) : vec3(0.0);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 rim_c = mix(rim_color * rim_strength * albedo * 2.0, select_rim * 0.85, select_k);
	ALBEDO = albedo;
	EMISSION = glow * v_rune + rim * rim_c + spill;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	np_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_np, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
