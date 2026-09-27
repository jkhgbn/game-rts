// mender_glow.gdshader - the Mender's glow material (task 9.V4): the censer core and the potion jars.
// A copy of art/units/kit/unit_glow.gdshader (instance uniform glow_boost on kit slot 5, A.16) whose colour comes
// per vertex from a tiny palette: UV.x = colour index, UV.y = pulse phase (so the jars never pulse in sync).
//   0 censer / draught green (0.5, 1.0, 0.6) (champions.md 4.6) · 1 honey amber · 2 rose tonic · 3 pale blue salve
// A soft fresnel brightening makes the jars read as lit glass rather than flat stickers.
shader_type spatial;
render_mode unshaded, cull_back;

uniform float energy = 1.5;
uniform float pulse_speed = 2.2;
uniform float boost = 1.0;
instance uniform float glow_boost : instance_index(5) = 1.0;

const vec3 GLOW[4] = vec3[4](
	vec3(0.50, 1.00, 0.60),
	vec3(1.00, 0.76, 0.34),
	vec3(1.00, 0.55, 0.62),
	vec3(0.55, 0.85, 1.00)
);

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	vec3 c = srgb_to_linear(GLOW[clamp(int(UV.x + 0.5), 0, 3)]);
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + UV.y * 2.1);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = c * (0.4 + 0.2 * rim) + c * energy * pulse * boost * glow_boost * (0.8 + 0.4 * rim);
}
