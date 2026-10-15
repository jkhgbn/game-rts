// essence_well_painted.gdshader - every opaque part of the Essence well (task 12.V19): the stone rim, footing, apron
// flagstones and rubble, the broken timber winch, the roof slabs, iron bands, rope, bucket and the carved rim runes.
// ONE shared material (essence_well_painted_mat.tres); each well's state lives in instance uniforms, so no material is
// ever created at runtime. Same painted look as the map's stone props and the Wayshrine (art-keep.md 0.3): vertex-colour
// blocks, triplanar paint noise, moss caps on the faces turned to the sky, height gradient + dark contact band, toon ramp,
// soft rim. Meshes come from build_essence_well.gd, which bakes per vertex:
//   COLOR.rgb  sRGB colour block of the part (the shaft's inner faces are baked darker and stained violet)
//   COLOR.a    0 at the part's bottom -> 1 at its top (height gradient: fake sky light + AO)
//   UV.x       moss amount (0 = bare)
//   UV.y       height in metres above the ground (dark contact band)
//   UV2.x      kind: 0 stone, 1 wood, 2 iron, 3 rope, 4 rune inlay, 5 shingles
//   UV2.y      rune inlay: angle around the well as a fraction 0-1, clockwise seen from above, starting at -Z (the capture
//              fill sweeps along it); wood / shingles: a coordinate across the grain (the streaks run along the grain)
// Instance uniforms (driven by essence_well.gd): rune_color, rune_energy (~0.45 neutral dim violet, ~2.3 owned),
// cap_color + cap_ratio (the rune ring fills clockwise in the capturer's colour with a bright head), flare (income pulse /
// capture flash), select_k (selection rim).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 moss_color : source_color = vec3(0.34, 0.47, 0.13);
uniform vec3 moss_dark : source_color = vec3(0.16, 0.29, 0.07);
uniform vec3 groove_color : source_color = vec3(0.075, 0.065, 0.095);
uniform float stone_top_light = 0.30;
uniform float iron_spec = 0.40;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.12;
uniform vec3 select_rim : source_color = vec3(1.0, 0.84, 0.48);

instance uniform vec4 rune_color = vec4(0.52, 0.36, 0.80, 1.0);
instance uniform float rune_energy = 0.45;
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
varying flat float v_kind;
varying float v_aux;
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
	v_kind = UV2.x;
	v_aux = UV2.y;
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
	float spec = 0.0;
	vec3 glow = vec3(0.0);
	float kind = v_kind;
	if (kind < 0.5) {
		// Stone: big soft moss caps on the faces turned to the sky, lit tops.
		float nlow = texture(noise_tex, v_wp.xz * 0.3 + vec2(5.3, 2.1)).r;
		float moss = smoothstep(0.60, 0.68, (n.y - 0.55) * 1.4 + (nlow - 0.5) * 1.0 + (na - 0.5) * 0.12) * v_moss;
		albedo *= 1.0 + max(n.y, 0.0) * stone_top_light;
		albedo = mix(albedo, mix(moss_dark, moss_color, smoothstep(0.3, 0.7, na)), moss);
	} else if (kind < 1.5 || (kind > 4.5 && kind < 5.5)) {
		// Old timber / shingles: painted streaks along the grain (constant along it, varying across it).
		float s1 = texture(noise_tex, vec2(v_aux * 1.9, 0.31 + kind * 0.13)).r;
		float s2 = texture(noise_tex, vec2(v_aux * 6.3, 0.77)).r;
		albedo *= mix(0.80, 1.12, s1) * mix(0.93, 1.05, s2);
		albedo *= 1.0 + max(n.y, 0.0) * 0.12;
		// Weathered grey on the faces turned to the sky, a little moss at the foot of the posts.
		float grey = smoothstep(0.55, 0.9, n.y) * 0.35;
		albedo = mix(albedo, vec3(dot(albedo, vec3(0.33))) * 1.08, grey);
		float foot = (1.0 - smoothstep(0.0, 0.5, v_y)) * smoothstep(0.4, 0.62, na) * v_moss;
		albedo = mix(albedo, moss_dark * (0.9 + na * 0.3), foot);
	} else if (kind < 2.5) {
		// Iron: a cool sheen and a warm rust bloom from below.
		float rust = smoothstep(0.55, 0.75, na) * 0.5;
		albedo = mix(albedo, vec3(0.20, 0.10, 0.05), rust);
		spec = iron_spec * (1.0 - rust);
	} else if (kind < 3.5) {
		// Rope: twisted strands (diagonal bands).
		float tw = sin((v_wp.x + v_wp.y + v_wp.z) * 42.0) * 0.5 + 0.5;
		albedo *= 0.88 + tw * 0.2;
	} else {
		// Rune inlay: a dark groove lit by the well's state; the capture fill sweeps the ring clockwise from -Z.
		float a = v_aux;
		float capturing = step(0.001, cap_ratio);
		float filled = capturing * (1.0 - smoothstep(cap_ratio - 0.004, cap_ratio + 0.004, a));
		float head = capturing * exp(-abs(a - cap_ratio) * 45.0);
		float lit = smoothstep(0.9, 2.2, rune_energy);        // the travelling shimmer only on an owned (lit) well
		float wave = pow(0.5 + 0.5 * sin(a * 6.2832 * 3.0 - TIME * 1.6), 5.0) * lit;
		float breathe = 0.86 + 0.14 * sin(TIME * 1.3 + a * 6.2832);
		vec3 state_glow = rune_color.rgb * rune_energy * breathe * (1.0 + wave * 0.5);
		vec3 cap_glow = cap_color.rgb * max(rune_energy, 2.4) * (1.0 + head * 1.8);
		glow = mix(state_glow, cap_glow, filled) * (1.0 + flare * 1.4);
		albedo = groove_color;
	}
	// Height gradient (0.72 -> 1.08) and the dark contact band.
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, v_y));

	// G-B neutral paint layer (neutral_paint.gdshaderinc). The rune inlay keeps its own look.
	int ki = int(kind + 0.5);
	int nk = ki == 0 ? NK_STONE : (ki == 1 ? NK_WOOD : (ki == 2 ? NK_METAL : (ki == 3 ? NK_STRAW
		: (ki == 5 ? NK_TILE : NK_PLAIN))));
	float bump_h = 0.0;
	float np_px = length(fwidth(v_wp));   // derivatives outside the per-kind branch
	vec3 np_emit = vec3(0.0);
	if (ki != 4) {
		albedo = np_albedo(albedo, nk, gb_detail, v_lp, normalize(v_ln), n, v_y, np_px, v_wp,
			CAMERA_POSITION_WORLD, noise_tex, bump_h, np_emit);
	}
	if (gb_detail > 1.5) {
		NORMAL = np_bump(NORMAL, VERTEX, bump_h);
	}
	v_np = vec3(spec, float(nk), gb_detail);

	float ndv = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(ndv, 3.0);
	// Selected: a warmer, wider rim (pow 2) so it reads from the RTS camera.
	vec3 rim_c = mix(rim * rim_color * rim_strength * albedo * 2.0, pow(ndv, 2.0) * select_rim * 0.75, select_k);
	ALBEDO = albedo;
	EMISSION = glow + rim_c + np_emit;
	// No environment reflections (SPECULAR 0); the iron sheen is done in light(), its strength passed through ROUGHNESS.
	ROUGHNESS = 1.0 - spec;
	SPECULAR = 0.0;
}

void light() {
	np_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_np, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
