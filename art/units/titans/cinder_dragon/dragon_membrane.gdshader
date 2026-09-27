// dragon_membrane.gdshader - Cinder Dragon wing membranes (task 13.V13). Painted toon style, double sided (one
// surface, cull disabled, the back face flips its normal), tinted per unit by the kingdom colour.
// Vertex COLOR:
//   r  distance from the nearest bone across the panel (0 at a finger, 1 mid-panel): darker leathery folds at the bones
//   g  0 at the wrist / wing root -> 1 at the trailing edge
//   b  1 on the scalloped trailing edge band (scorched, smouldering rim)
// UV = (across the panel, from the wrist) in metres: veins.
// Instance uniforms (kit slot map, kit/README.md): hit_flash 3, flash_color 4, glow_boost 5 (the smouldering rim),
// membrane_tint 7 (NEW slot, this shader only: set_team_color writes it; never merged with another unit's shader).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale = 0.7;
uniform vec3 bone_shade : source_color = vec3(0.16, 0.06, 0.05);
uniform float tint_bright = 0.66;
uniform float tint_dark = 0.22;
uniform vec3 scorch_color : source_color = vec3(0.07, 0.035, 0.03);
uniform vec3 ember_color : source_color = vec3(1.0, 0.42, 0.08);
uniform float ember_energy = 2.2;
uniform float vein_scale = 1.8;
uniform float back_light = 0.35;
uniform vec3 rim_color : source_color = vec3(1.0, 0.55, 0.25);
uniform float rim_strength = 0.25;

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;
instance uniform vec3 membrane_tint : instance_index(7) = vec3(0.85, 0.30, 0.12);

varying vec3 v_obj;

void vertex() {
	v_obj = VERTEX;
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float nz = texture(noise_tex, v_obj.xz * noise_scale).r;
	float mid = clamp(COLOR.r, 0.0, 1.0);
	float edge = clamp(COLOR.g, 0.0, 1.0);
	vec3 tint = pow(max(membrane_tint, vec3(0.0)), vec3(1.35));
	// bright in the middle of each panel, dark leathery folds at the bones and toward the root
	vec3 albedo = tint * mix(tint_dark, tint_bright, smoothstep(0.0, 0.8, mid) * (0.75 + 0.25 * edge));
	albedo = mix(bone_shade * (0.6 + 0.8 * tint), albedo, smoothstep(0.02, 0.22, mid));
	// veins: thin wavy lines radiating from the wrist
	float vein = sin(UV.x * vein_scale * TAU + sin(UV.y * 2.3) * 1.6);
	albedo *= 1.0 - 0.16 * smoothstep(0.86, 0.98, vein) * (1.0 - edge * 0.5);
	albedo *= 0.9 + 0.2 * nz;
	// scorched, smouldering trailing edge
	float rim_band = clamp(COLOR.b, 0.0, 1.0);
	albedo = mix(albedo, scorch_color, smoothstep(0.35, 0.9, rim_band) * 0.85);
	float heat = clamp(glow_boost, 0.0, 3.0);
	float flick = 0.7 + 0.3 * sin(TIME * 2.3 + v_obj.x * 3.1 + v_obj.z * 2.7);
	vec3 emission = ember_color * ember_energy * smoothstep(0.75, 1.0, rim_band) * flick * heat * (0.6 + 0.4 * nz);
	// light through the skin when seen from below / against the sun (a warm glow of the tint)
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
