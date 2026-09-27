// unit_glow.gdshader - CHARACTER copy of art/shaders/rune_glow.gdshader (art-units.md 2.4) + instance uniform glow_boost
// (per unit: veterancy, haste, casts, death). Material-wide boost stays 1.0 on character materials.
// Uniforms: glow_color, energy (2.0-4.0), pulse_speed (rad/s), rune_bands (0 = solid, N = dashes along UV.x),
// boost (1.0 idle; training pulse / selection / collapse raise it), phase (offset so copies don't pulse in sync).
// glow_boost sits on slot 5 of the kit slot map (kit/README.md, task A.16) so it never shares a slot with ao_bottom.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float energy = 3.0;
uniform float pulse_speed = 2.0;
uniform int rune_bands = 0;
uniform float boost = 1.0;
uniform float phase = 0.0;
instance uniform float glow_boost : instance_index(5) = 1.0;

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + phase);
	float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0;
	ALBEDO = glow_color * 0.4 + glow_color * energy * pulse * band * boost * glow_boost;
}
