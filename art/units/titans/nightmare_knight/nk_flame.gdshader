// nk_flame.gdshader - Nightmare Knight (task 13.V15): violet flame tongues (helmet crest, burning hooves) and smoke
// tongues (mane, forelock, tail). Unshaded, flickering: the tongues sway and lick in the vertex shader (0 CPU).
// Mesh contract: UV.y = 0 at the tongue's root (fixed), 1 at its tip; UV.x = a per-tongue seed (0-1).
// Colour runs core -> mid (at 45 % of the height) -> tip. Smoke = a dark core with glowing violet tips.
// Instance uniform glow_boost on slot 5 (kit slot map, kit/README.md "Instance uniform slots"): the kit drives it
// (0 when dead = the fire gutters to its dim base colour, flares on the charge).
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 core_color : source_color = vec3(1.0, 0.85, 1.0);
uniform vec3 mid_color : source_color = vec3(0.72, 0.32, 1.0);
uniform vec3 tip_color : source_color = vec3(0.32, 0.10, 0.62);
// Brightness multiplier of the glowing part (x glow_boost) and the unlit floor (always there, even dead).
uniform float energy = 2.6;
uniform float base_mix = 0.3;
uniform float flicker_speed = 8.0;
// Tip sway amplitude (m), growing with the square of the height.
uniform float sway = 0.05;
instance uniform float glow_boost : instance_index(5) = 1.0;

void vertex() {
	float h = UV.y;
	float s = UV.x * 6.2831 + dot(VERTEX, vec3(2.3, 0.7, 1.9));
	float t = TIME * flicker_speed;
	float k = sway * h * h;
	VERTEX.x += k * (sin(t + s) + 0.45 * sin(t * 1.73 + s * 2.1));
	VERTEX.z += k * cos(t * 1.31 + s * 1.4);
	VERTEX.y += k * 0.5 * sin(t * 2.2 + s * 3.0);
}

void fragment() {
	float h = UV.y;
	vec3 c = h < 0.45 ? mix(core_color, mid_color, h / 0.45) : mix(mid_color, tip_color, (h - 0.45) / 0.55);
	float fl = 0.82 + 0.18 * sin(TIME * flicker_speed * 1.9 + UV.x * 23.0 + h * 5.0);
	ALBEDO = c * (base_mix + energy * fl * glow_boost);
}
