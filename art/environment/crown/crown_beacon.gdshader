// crown_beacon.gdshader - the soft column of light above a claimable Ember Crown (task A2.3).
// Additive, unshaded, no depth write, no shadow. Mesh: an open cone-cylinder built by build_crown.gd with
// UV.x = angle (0-1 around) and UV.y = 0 at the bottom -> 1 at the top. Brightest where it faces the camera
// and near the crown, fading out upward, with faint bands climbing it. `intensity` / `tint` are per instance
// (crown_pedestal_art.gd drives them: off while sealed / worn, gold when claimable).
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform float band_speed = 0.3;
uniform float fade_power = 2.2;
instance uniform float intensity = 1.0;
instance uniform vec4 tint = vec4(1.0, 0.66, 0.26, 1.0);

void fragment() {
	// Guarded math: pow() of a value that interpolates a hair below 0 is NaN, and the glow pass spreads a NaN
	// pixel into a big white disc.
	float v = clamp(UV.y, 0.0, 1.0);
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float soft = pow(max(facing, 1e-4), 1.6);
	float top = pow(max(1.0 - v, 1e-4), fade_power) * (1.0 - smoothstep(0.9, 1.0, v));
	float bottom = smoothstep(0.0, 0.08, v);
	// In-game grade 2026-09-30 (row 48, 9 glow points): the bands were a spiral (+ UV.x), which broke the column
	// into ~7 separate bright spots over the bloom level (front + back faces add up). They are rings now, shallower,
	// and the column 20 % softer: one continuous shaft of light.
	float bands = 0.82 + 0.18 * sin((v * 4.0 - TIME * band_speed) * 6.2832);
	ALBEDO = tint.rgb * intensity * soft * top * bottom * bands * 0.8;
}
