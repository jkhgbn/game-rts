// wyrm_scale.gdshader - Frost Wyrm scales, claws and teeth (task 13c.V8). Painted like the Frost Dragon's
// frost_scale.gdshader (flat colour blocks, paint noise, toon ramp, rim, overlapping scales, belly plates, rime crust),
// but SKINNING-SAFE: the serpent body bends with a Skeleton3D, so every noise / frost lookup uses the REST pose baked
// in CUSTOM0.xyz (model position) and CUSTOM1.xyz (model normal) instead of VERTEX / NORMAL (which move with the
// bones): the paint never swims over the body while it writhes.
// The wyrm's own marks: dark chevron BANDS across the back every band_len metres (the long body reads as a banded
// serpent at 40 m) and a dotted row of glowing frost SPOTS along each flank (UV2.x = 1 where allowed: the body only).
// Vertex COLOR:
//   r  rime amount of the part (0 = never frosts: claws, teeth; 1 = full crust)
//   g  colour blend base_color -> belly_color (belly plates / pale claw tips)
//   b  1 = a lofted part: UV.x = angle around (0 = the top), UV.y = metres along -> flank seam, plates, scales, bands
//   a  explicit glow (the lip line): emits glow_color x a
// UV2: x = spot mask, y = band mask.
// Instance uniforms (kit slot map, kit/README.md A.16): hit_flash 3, flash_color 4, glow_boost 5 (the breath / roar
// flare raises it, death puts it out).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.44, 0.66, 0.84);
uniform vec3 belly_color : source_color = vec3(0.90, 0.95, 0.99);
uniform vec3 band_color : source_color = vec3(0.20, 0.33, 0.52);
uniform float band_len = 0.95;
uniform float band_width = 0.34;
uniform float band_chevron = 0.22;
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 1.1;
uniform float noise_scale_b = 0.25;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec3 rim_color : source_color = vec3(0.70, 0.88, 1.0);
uniform float rim_strength = 0.35;
uniform vec3 rime_color : source_color = vec3(0.92, 0.97, 1.0);
uniform float rime_glow = 0.06;
uniform float crack_amount = 1.0;
uniform float crack_scale = 0.55;
uniform float frost_top = 0.35;
uniform vec3 glow_color : source_color = vec3(0.55, 0.92, 1.0);
uniform float glow_energy = 2.4;
uniform vec3 groove_color : source_color = vec3(0.50, 0.66, 0.80);
uniform float plate_len = 0.26;
uniform float scale_cols = 24.0;
uniform float scale_len = 0.18;
uniform float flank_width = 0.05;
uniform vec3 spot_color : source_color = vec3(0.60, 0.95, 1.0);
uniform float spot_energy = 2.2;
uniform float spot_len = 0.72;
uniform float spot_size = 0.075;
uniform float spot_ca = -0.02;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

varying vec3 v_rest;
varying vec3 v_restn;
varying vec2 v_mask;

void vertex() {
	v_rest = CUSTOM0.xyz;
	v_restn = CUSTOM1.xyz;
	v_mask = UV2;
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
	vec3 n = length(v_restn) > 0.01 ? normalize(v_restn) : vec3(0.0, 1.0, 0.0);
	float na = triplanar(v_rest, n, noise_scale_a);
	float nb = triplanar(v_rest + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	float belly = clamp(COLOR.g, 0.0, 1.0);
	vec3 albedo = mix(base_color, belly_color, belly);
	albedo *= (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.14);

	float rime = 0.0;
	float heat = clamp(glow_boost, 0.0, 3.0);
	vec3 emission = vec3(0.0);
	if (COLOR.b > 0.5) {
		float ca = cos(TAU * UV.x);
		float sa = sin(TAU * UV.x);
		// overlapping scales on the back and flanks (rows along the body, every other column offset)
		float cx = UV.x * scale_cols;
		float col_i = floor(cx);
		vec2 cell = vec2(fract(cx), fract(UV.y / scale_len + 0.5 * mod(col_i, 2.0)));
		float d = length((cell - vec2(0.5, 0.05)) * vec2(1.0, 0.8));
		float scale_shade = mix(0.80, 1.07, smoothstep(0.62, 0.25, d));
		albedo *= mix(scale_shade, 1.0, belly);
		// chevron bands over the back (pointing forward), noise-broken edges, fading out down the flanks
		float bp = fract(UV.y / band_len + abs(sa) * band_chevron + (na - 0.5) * 0.12);
		float band = 1.0 - smoothstep(band_width * 0.5 - 0.06, band_width * 0.5 + 0.06, abs(bp - 0.5));
		band *= smoothstep(-0.30, 0.05, ca) * clamp(v_mask.y, 0.0, 1.0);
		albedo = mix(albedo, band_color, band * 0.85);
		// belly plates: a groove every plate_len, frost caught in it
		float pl = fract(UV.y / plate_len);
		float groove = 1.0 - smoothstep(0.02, 0.07, min(pl, 1.0 - pl));
		float on_belly = smoothstep(-0.30, -0.55, ca);
		albedo = mix(albedo, groove_color, 0.5 * groove * on_belly);
		// the rime seam along each flank, where the back meets the pale belly (broken by the noise)
		float flank = exp(-pow((ca + 0.26) / flank_width, 2.0)) * smoothstep(0.25, 0.45, na + 0.15);
		rime = max(flank * 0.9, groove * on_belly * 0.25) * COLOR.r;
		// dotted frost spots along each flank (bioluminescent: they glow)
		float sp_along = (fract(UV.y / spot_len) - 0.5) * spot_len;
		float sp = length(vec2(sp_along, (ca - spot_ca) * 0.42));
		float spot = (1.0 - smoothstep(spot_size * 0.6, spot_size, sp)) * clamp(v_mask.x, 0.0, 1.0);
		albedo = mix(albedo, spot_color, spot * 0.7);
		emission += spot_color * spot_energy * spot * (0.85 + 0.15 * sin(TIME * 1.7 + UV.y * 0.9)) * heat;
		// frost dusting on the top of the back
		rime = max(rime, smoothstep(0.80, 0.97, ca) * smoothstep(0.52, 0.68, na) * frost_top * COLOR.r);
	} else {
		rime = smoothstep(0.75, 0.95, n.y) * smoothstep(0.52, 0.68, na) * frost_top * COLOR.r;
	}
	// rime crust patches (ridged noise inside patches of the broad noise)
	float rn = triplanar(v_rest + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
	float ridged = 1.0 - abs(rn * 2.0 - 1.0);
	float crack = smoothstep(0.92, 0.975, ridged) * smoothstep(0.46, 0.60, nb) * crack_amount * COLOR.r;
	rime = max(rime, crack);
	albedo = mix(albedo, rime_color, clamp(rime, 0.0, 1.0) * 0.88);

	float flow = 0.8 + 0.2 * sin(TIME * 1.3 + v_rest.z * 2.1 + v_rest.y * 1.3);
	emission += glow_color * glow_energy * COLOR.a * flow * heat;
	albedo = mix(albedo, glow_color * 0.6, COLOR.a * clamp(heat, 0.0, 1.0) * 0.6);
	emission += rime_color * rime_glow * rime * min(heat, 1.0);

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	// the kit's gold level-up flash tints the surface (pale parts would add up to white otherwise)
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
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 18.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
