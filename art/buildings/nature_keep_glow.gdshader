// Heartwood glow parts with per-instance values (art-keep.md 5.3): the seed-lantern pods and the construction
// outline. Instance uniforms so the three lanterns share one material but pulse out of step.
// The colour is pushed toward its own saturated core (glow^2) so the green survives the tonemapper at high
// energy instead of blooming to white; a soft fresnel keeps a brighter heart where the pod faces the camera.
shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled;

uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float boost_mult = 1.0;
instance uniform float energy = 3.0;
instance uniform float pulse_speed = 2.0;
instance uniform int rune_bands = 0;
instance uniform float boost = 1.0;
instance uniform float phase = 0.0;

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + phase);
	float band = rune_bands > 0 ? step(0.45, fract(UV.x * float(rune_bands))) : 1.0;
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	vec3 deep = mix(glow_color * glow_color, glow_color, 0.45);
	vec3 col = mix(deep, glow_color, smoothstep(0.5, 1.0, facing));
	ALBEDO = col * (0.4 + energy * pulse * band * boost * boost_mult * mix(0.7, 1.15, facing));
}
