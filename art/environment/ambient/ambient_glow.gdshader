// ambient_glow.gdshader - G-D ambient motes (docs/art/gd_ambient.md): additive camera-facing specks drawn by one
// GPUParticles3D that follows the camera (AmbientLife "Motes"): pollen and sunlit dust glints by day, fireflies at
// night. COLOR = the particle colour (process material colour x its alpha ramp = the life fade).
// blink 0 = steady (a slow twinkle), 1 = firefly pulses (each particle its own rhythm, dark most of the time).
// Fades with the fog of war (ambient_common.gdshaderinc) and close to the camera (no big blobs in the lens).
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://art/environment/ambient/ambient_common.gdshaderinc"

uniform float glow = 1.0;
uniform float blink = 0.0;
uniform float twinkle = 0.35;
uniform float near_fade = 6.0;

varying float v_a;

void vertex() {
	vec3 w = MODEL_MATRIX[3].xyz;
	MODELVIEW_MATRIX = amb_billboard(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX);
	float h = amb_pid(INSTANCE_ID, 1.0);
	float tw = 1.0 - twinkle * (0.5 + 0.5 * sin(TIME * (2.0 + 3.0 * h) + h * 40.0));
	// Firefly: a short bright pulse every 2.5-4.5 s.
	float cyc = fract(TIME / (2.5 + 2.0 * h) + h);
	float pulse = smoothstep(0.0, 0.08, cyc) * (1.0 - smoothstep(0.18, 0.42, cyc));
	float b = mix(tw, 0.14 + pulse, blink);
	float d = length(CAMERA_POSITION_WORLD - w);
	v_a = COLOR.a * b * fog_seen(w) * smoothstep(near_fade * 0.4, near_fade, d);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r2 = dot(q, q);
	float core = exp(-r2 * 9.0);
	float halo = exp(-r2 * 2.6) * 0.35;
	float a = (core + halo) * v_a;
	ALBEDO = COLOR.rgb * glow * a;
	ALPHA = 1.0;
}
