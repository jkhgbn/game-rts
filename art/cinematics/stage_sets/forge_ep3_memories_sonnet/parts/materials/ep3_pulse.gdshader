shader_type spatial;
// forge_ep3_memories_sonnet: the amber stone's pulsing veins (unshaded HDR vertex colour). 0 lights.
render_mode unshaded, cull_back;
uniform float energy = 2.2;
void fragment() {
	float f = 0.62 + 0.38 * sin(TIME * 3.1);
	ALBEDO = COLOR.rgb * energy * f;
}
