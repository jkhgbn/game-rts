// crucible_glow.gdshader - the Ember Crucible's glows (molten metal, coals, the white-hot pour / mould / blade): the kit's
// unit_glow.gdshader (same uniforms, glow_boost on instance slot 5) through the buildings' hue-keeping glow cap
// (G-F round 2, docs/art/gf_r2_buildings_fs.md; gf_review2 item 4: the molten bowl burned to a white disc at energy 3.2,
// as the keep orb did before the G-E cap). The pour and forge flares still read: they saturate toward the cap instead
// of going white. Same cost at every tier (a few ALU ops).
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float energy = 3.0;
uniform float pulse_speed = 2.0;
uniform int rune_bands = 0;
uniform float boost = 1.0;
uniform float phase = 0.0;
instance uniform float glow_boost : instance_index(5) = 1.0;
#include "res://art/shaders/glow_cap.gdshaderinc"  // G-E 4: hue-keeping soft cap, no white discs

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + phase);
	float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0;
	ALBEDO = glow_cap(glow_color * 0.4 + glow_color * energy * pulse * band * boost * glow_boost, glow_cap_max);
}
