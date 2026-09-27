// treant_glow.gdshader - Elder Treant glow parts (task 13.V18): the green eyes and the seed pods. Same formula as the
// kit's unit_glow.gdshader (unshaded, glow_color x energy x pulse x glow_boost, bloom carries it at 40 m) with the colour
// from the vertex COLOR (rgb) and a per-part pulse phase (a); a hot core where the surface faces the camera; the
// root-morph growth of treant.gdshaderinc (the pods only exist in the rooted form). glow_boost: the model drives it
// (veterancy x haste, the volley flare, 0 = dead: the glow goes out).
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://art/units/titans/elder_treant/treant.gdshaderinc"

uniform float energy = 2.8;
uniform float pulse_speed = 2.2;

void vertex() {
	VERTEX = treant_morph(VERTEX, CUSTOM0);
}

void fragment() {
	float pulse = 0.78 + 0.22 * sin(TIME * pulse_speed + COLOR.a * 6.2831853);
	float core = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5);
	float b = glow_boost * (1.0 + heal_glow * 0.3);
	vec3 c = treant_linear(COLOR.rgb);
	ALBEDO = c * 0.16 + c * energy * pulse * b * (0.6 + 0.6 * core);
}
