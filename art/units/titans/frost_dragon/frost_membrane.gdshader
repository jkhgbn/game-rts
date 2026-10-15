// frost_membrane.gdshader - Frost Dragon wing membranes (task 13c.V1). The Cinder Dragon's dragon_membrane.gdshader
// (painted toon, one double-sided surface, kingdom-colour tint, dark folds at the bones, veins) turned to ice: a
// frosted, translucent-looking skin (bright mid-panels, strong light through it from below, pale frost veins), rime
// feathering in from the scalloped trailing edge (broken by noise) and a faint cold shimmer on the very rim.
// Vertex COLOR (same layout as the Cinder's membranes):
//   r  distance from the nearest bone across the panel (0 at a finger, 1 mid-panel)
//   g  0 at the wrist / wing root -> 1 at the trailing edge
//   b  1 on the scalloped trailing edge band (frosted rim)
// UV = (across the panel, from the wrist) in metres: veins.
// Instance uniforms (kit slot map): hit_flash 3, flash_color 4, glow_boost 5 (the rim shimmer), membrane_tint 7
// (set_team_color writes it; the slot of dragon_membrane.gdshader, never merged with another unit's shader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale = 0.7;
uniform vec3 bone_shade : source_color = vec3(0.10, 0.17, 0.30);
// The Ice kingdom colours are pale: the tint is deepened (pow tint_gamma) so the wings read BLUE, not white.
uniform float tint_gamma = 2.8;
uniform float tint_bright = 0.56;
uniform float tint_dark = 0.22;
uniform vec3 frost_color : source_color = vec3(0.86, 0.94, 1.0);
uniform float frost_amount = 0.62;
uniform float frost_patches = 0.12;
uniform vec3 shimmer_color : source_color = vec3(0.60, 0.90, 1.0);
uniform float shimmer_energy = 0.5;
uniform float vein_scale = 1.8;
uniform float back_light = 0.4;
uniform vec3 rim_color : source_color = vec3(0.70, 0.88, 1.0);
uniform float rim_strength = 0.2;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;
instance uniform vec3 membrane_tint : instance_index(7) = vec3(0.55, 0.80, 0.95);

varying vec3 v_obj;

void vertex() {
	v_obj = VERTEX;
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float nz = texture(noise_tex, v_obj.xz * noise_scale).r;
	float nz2 = texture(noise_tex, v_obj.xz * noise_scale * 2.3 + vec2(5.1, 2.7)).r;
	float mid = clamp(COLOR.r, 0.0, 1.0);
	float edge = clamp(COLOR.g, 0.0, 1.0);
	// G-C: deepen the hue (pow) but give it back the kingdom colour's own brightness (its max channel), so a pale Ice
	// blue still reads BLUE while red / violet / green teams stay vivid instead of sinking to near black (Art Lab R6:
	// the team colour barely showed on the wings).
	vec3 mt = max(membrane_tint, vec3(0.0));
	vec3 deep = pow(mt, vec3(tint_gamma));
	float mt_max = max(mt.r, max(mt.g, mt.b));
	float deep_max = max(deep.r, max(deep.g, deep.b));
	vec3 tint = deep / max(deep_max, 0.001) * mt_max * 0.82;
	// bright, thin-looking mid-panels, darker folds at the bones and toward the root
	vec3 albedo = tint * mix(tint_dark, tint_bright, smoothstep(0.0, 0.8, mid) * (0.75 + 0.25 * edge));
	albedo = mix(bone_shade * (0.6 + 0.8 * tint), albedo, smoothstep(0.02, 0.22, mid));
	// pale frost veins radiating from the wrist
	float vein = sin(UV.x * vein_scale * TAU + sin(UV.y * 2.3) * 1.6);
	albedo = mix(albedo, frost_color, 0.16 * smoothstep(0.86, 0.98, vein) * (0.4 + 0.6 * edge));
	albedo *= 0.9 + 0.2 * nz;
	// rime feathering in from the trailing edge (noise-broken), plus a few frost patches out on the panels
	float rim_band = clamp(COLOR.b, 0.0, 1.0);
	float frost = smoothstep(0.72, 1.0, rim_band + (nz2 - 0.5) * 0.4);
	frost = max(frost, smoothstep(0.70, 0.84, nz2) * edge * frost_patches);
	albedo = mix(albedo, frost_color, clamp(frost, 0.0, 1.0) * frost_amount);
	float heat = clamp(glow_boost, 0.0, 3.0);
	float flick = 0.7 + 0.3 * sin(TIME * 1.3 + v_obj.x * 2.0 + v_obj.z * 1.7);
	vec3 emission = shimmer_color * shimmer_energy * smoothstep(0.8, 1.0, rim_band) * flick * min(heat, 1.5)
		* (0.6 + 0.4 * nz);
	// light through the skin when seen from below / against the sun (the frosted-glass look)
	emission += tint * back_light * (1.0 - float(FRONT_FACING)) * smoothstep(0.1, 0.7, mid);
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;
	ALBEDO = albedo;
	EMISSION = emission + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += (0.18 + 0.82 * ramp) * ATTENUATION * LIGHT_COLOR / PI;
}
