// rune_glow.gdshader - every emissive part (gems, orbs, coals, portcullis, rune rings). art-keep.md 5.3.
// Uniforms: glow_color, energy (2.0-4.0), pulse_speed (rad/s), rune_bands (0 = solid, N = dashes along UV.x),
// boost (1.0 idle; training pulse / selection / collapse raise it), phase (offset so copies don't pulse in sync).
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float energy = 3.0;
uniform float pulse_speed = 2.0;
uniform int rune_bands = 0;
uniform float boost = 1.0;
uniform float phase = 0.0;
#include "res://art/shaders/glow_cap.gdshaderinc"  // G-E 4: hue-keeping soft cap, no white discs

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + phase);
	float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0;
	ALBEDO = glow_cap(glow_color * 0.4 + glow_color * energy * pulse * band * boost, glow_cap_max);
}
