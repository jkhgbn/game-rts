// frost_ice.gdshader - Frost Dragon ice horns, ice spines, the ice-shard tail tip, the chin / cheek shards (task 13c.V1).
// The Ice army's faceted crystal (art/units/ice/ice_crystal.gdshaderinc: flat facets, deep core, fresnel edge, glints)
// plus a cold inner glow per vertex and the flyer's glow_boost (the breath flare brightens it, death puts it out).
// Vertex COLOR:
//   r  inner glow amount (0 = a plain ice horn, 1 = a glowing spine / the tail shard)
//   g  0 at the base -> 1 at the tip (pale, whiter tips; the glow is strongest at the base, inside the body)
// Instance uniforms: the include's ao_bottom 1, ao_height 2, hit_flash 3, flash_color 4 (kit map) + glow_boost 5.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/units/ice/ice_crystal.gdshaderinc"

uniform vec3 glow_color : source_color = vec3(0.55, 0.90, 1.0);
uniform float glow_energy = 1.6;
uniform float tip_white = 0.45;

instance uniform float glow_boost : instance_index(5) = 1.0;

void fragment() {
	vec3 n = ice_normal(NORMAL, VERTEX, VIEW);
	vec3 em;
	float fres;
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	vec3 col = ice_shade(n, VIEW, VERTEX, INV_VIEW_MATRIX, TIME, em, fres);
	float along = clamp(COLOR.g, 0.0, 1.0);
	col = mix(col, edge_color, along * along * tip_white);
	float heat = clamp(glow_boost, 0.0, 3.0);
	float g = clamp(COLOR.r, 0.0, 1.0);
	float pulse = 0.82 + 0.18 * sin(TIME * 1.6 + v_world_pos.x * 1.3 + v_world_pos.z * 0.9);
	vec3 glow = glow_color * glow_energy * g * mix(1.0, 0.45, along) * pulse * heat;
	// a dead dragon's ice goes dull (the cold light inside it dies with it)
	em *= mix(0.35, 1.0, clamp(heat, 0.0, 1.0));
	col = mix(col, glow_color * 0.8, g * 0.35 * clamp(heat, 0.0, 1.0));
	ALBEDO = col * tint;
	NORMAL = n;
	EMISSION = (em + glow) * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 0.25;
}

void light() {
	ice_light(NORMAL, LIGHT, VIEW, ATTENUATION, LIGHT_COLOR, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
