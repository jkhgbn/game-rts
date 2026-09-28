// em_army_glow.gdshader (copy of forge_intro_vessa/fx/army_glow) - forge_evenmead baked hosts (parts/army_*.res): every glowing part of every unit in one
// surface. Vertex COLOR = the unit_glow glow_color (sRGB). Unshaded, gentle per-unit pulse (COLOR.a = phase).
shader_type spatial;
render_mode unshaded, cull_back;

uniform float energy = 1.5;

void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	float p = 0.8 + 0.2 * sin(TIME * 2.0 + COLOR.a * 6.2831);
	ALBEDO = c * 0.4 + c * energy * p;
}
