// ice_crystal.gdshader - opaque faceted ice for the Ice army (armour, glacier plates, rods, clubs). See the include.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/units/ice/ice_crystal.gdshaderinc"

void fragment() {
	vec3 n = ice_normal(NORMAL, VERTEX, VIEW);
	vec3 em;
	float fres;
	// A.17: the gold level-up flash (low blue, mid green: hit white, Ice freeze blue, Fire ember are untouched) also tints
	// the surface, so pale and blue parts turn gold instead of adding up to white.
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = ice_shade(n, VIEW, VERTEX, INV_VIEW_MATRIX, TIME, em, fres) * tint;
	NORMAL = n;
	EMISSION = em * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 0.25;
}

void light() {
	ice_light(NORMAL, LIGHT, VIEW, ATTENUATION, LIGHT_COLOR, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
