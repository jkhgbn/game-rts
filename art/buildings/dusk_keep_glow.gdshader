// Dusk Keep glow parts (art-keep.md 5.3). Per-part values are instance uniforms so every glow part
// of the keep shares ONE material.
shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled;

uniform vec3 glow_color : source_color = vec3(0.70, 0.30, 1.00);
uniform float boost_mult = 1.0;
instance uniform float energy = 3.0;
instance uniform float pulse_speed = 2.0;
instance uniform int rune_bands = 0;
instance uniform float boost = 1.0;
instance uniform float phase = 0.0;
#include "res://art/shaders/glow_cap.gdshaderinc"  // G-E 4: hue-keeping soft cap, no white discs

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + phase);
	float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0;
	ALBEDO = glow_cap(glow_color * (0.4 + energy * pulse * band * boost * boost_mult), glow_cap_max);
}
