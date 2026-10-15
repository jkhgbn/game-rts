// rune_glow_vc.gdshader - rune_glow.gdshader (every emissive part: gems, orbs, coals, portcullis, rune rings; art-keep.md
// 5.3) for ONE glow material per building (B8 budget). PaintedVC.convert_glow merges a building's glow materials
// into one surface per mesh; each source material is a CHANNEL (UV2.x of its vertices) whose uniforms live in the
// arrays below, copied from the sources every frame by PaintedVC.sync_glow (the building code keeps driving its own
// glow materials: boosts, pulses, team colour). The formula is rune_glow's, per channel. Colours are LINEAR.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_colors[8];
uniform float energies[8];
uniform float pulse_speeds[8];
uniform int bands[8];
uniform float boosts[8];
uniform float phases[8];
#include "res://art/shaders/glow_cap.gdshaderinc"  // G-E 4: hue-keeping soft cap, no white discs

varying flat int v_ch;

void vertex() {
	v_ch = int(floor(UV2.x + 0.5));
}

void fragment() {
	int c = clamp(v_ch, 0, 7);
	vec3 glow_color = glow_colors[c];
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speeds[c] + phases[c]);
	float band = bands[c] > 0 ? step(0.45, fract(UV.x * float(bands[c]))) : 1.0;
	ALBEDO = glow_cap(glow_color * 0.4 + glow_color * energies[c] * pulse * band * boosts[c], glow_cap_max);
}
