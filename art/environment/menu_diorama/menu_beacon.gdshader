// menu_beacon.gdshader - the main menu's column of light above the Ember Crown (G-F review 2 item 13).
// Drop-in for crown_beacon.gdshader on the diorama's own Beacon / BeaconCore (same cone mesh, same per-instance
// `intensity` / `tint` that CrownPedestalArt drives). The game's beacon is additive and, front + back faces + the
// High core added over the sunset sky, read as a near-white bloomed column. Here it is alpha-blended: the pixel is a
// mix of what is behind and `core_color` / `rim_color`, so it can never get brighter than those colours (<= 0.9 per
// channel, under the menu environment's glow_hdr_threshold 1.1: no bloom, no white). Core = saturated amber where the
// cone faces the camera, rim = orange fading out toward the silhouette, the top fades out, faint rings climb it.
// The colours come from the uniforms; the pedestal's `tint` only scales the alpha (its .a, 1 by default).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform vec3 core_color : source_color = vec3(0.9, 0.56, 0.12);
uniform vec3 rim_color : source_color = vec3(0.86, 0.32, 0.06);
uniform float opacity = 0.55;          // alpha at full intensity, core, bottom of the column
uniform float max_alpha = 0.8;
uniform float full_intensity = 1.8;    // CrownPedestalArt's AWAKE beacon intensity = alpha 1x
uniform float core_power = 2.2;        // how narrow the amber core is (facing ^ core_power)
uniform float fade_power = 1.3;
uniform float band_speed = 0.3;
instance uniform float intensity = 1.0;
instance uniform vec4 tint = vec4(1.0, 0.66, 0.26, 1.0);

void fragment() {
	// Guarded math (crown_beacon.gdshader): pow() of a value a hair below 0 is NaN.
	float v = clamp(UV.y, 0.0, 1.0);
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float core = pow(max(facing, 1e-4), core_power);
	float edge = smoothstep(0.0, 0.45, facing);           // the rim fades out toward the silhouette
	float top = pow(max(1.0 - v, 1e-4), fade_power) * (1.0 - smoothstep(0.88, 1.0, v));
	float bottom = smoothstep(0.0, 0.1, v);
	float bands = 0.85 + 0.15 * sin((v * 4.0 - TIME * band_speed) * 6.2832);
	float level = clamp(intensity / max(full_intensity, 1e-3), 0.0, 1.0);
	ALBEDO = clamp(mix(rim_color, core_color, core), vec3(0.0), vec3(0.9));
	ALPHA = clamp(opacity * level * edge * (0.35 + 0.65 * core) * top * bottom * bands * tint.a, 0.0, max_alpha);
}
