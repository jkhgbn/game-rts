// crown_rune.gdshader - glowing runes, ember coals, seal chains / rings and crown jewels (task A2.3).
// Unshaded emissive (magic = glow + motion, art-keep.md 0.6): energy waves run toward `focus` (local
// space, the crown above the altar), so the whole altar looks like it feeds the crown.
// The uniform names glow_color / core_color / energy are a contract: EmberCrown tints the pedestal's
// "Runes" node red while it is sealed by duplicating this material and setting those three.
// `intensity` is per instance (the pedestal art dims the runes when the crown is gone, flashes the seal).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec3 glow_color : source_color = vec3(1.0, 0.52, 0.12);
uniform vec3 core_color : source_color = vec3(1.0, 0.88, 0.55);
uniform float energy = 3.2;
uniform vec3 focus = vec3(0.0, 1.8, 0.0);
uniform float flow_speed = 2.2;
uniform float flow_scale = 3.2;
uniform float pulse_amount = 0.14;
instance uniform float intensity = 1.0;

varying vec3 v_lp;

void vertex() {
	v_lp = VERTEX;
}

void fragment() {
	float d = distance(v_lp, focus);
	// Bright bands travelling toward the focus point.
	float wave = pow(0.5 + 0.5 * sin(d * flow_scale + TIME * flow_speed), 6.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 c = mix(glow_color, core_color, clamp(0.25 + fres * 0.45 + wave * 0.55, 0.0, 1.0));
	float pulse = 1.0 + sin(TIME * 1.7 + d * 0.9) * pulse_amount;
	ALBEDO = c * energy * intensity * pulse * (0.8 + wave * 0.55);
}
