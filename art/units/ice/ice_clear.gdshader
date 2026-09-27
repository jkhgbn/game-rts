// ice_clear.gdshader - translucent ice (Rimeshield round shield, lantern glass): the crystal look of
// ice_crystal.gdshaderinc with an alpha that is low where the surface faces the camera and solid at the rim
// (you see the body through the shield, the edge stays crisp). Drawn after the opaque pass (render_priority 1).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled;

#include "res://art/units/ice/ice_crystal.gdshaderinc"

uniform float alpha_center = 0.40;
uniform float alpha_edge = 0.95;

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
	ROUGHNESS = 0.2;
	ALPHA = clamp(mix(alpha_center, alpha_edge, fres) + hit_flash * 0.5, 0.0, 1.0);
}

void light() {
	ice_light(NORMAL, LIGHT, VIEW, ATTENUATION, LIGHT_COLOR, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
