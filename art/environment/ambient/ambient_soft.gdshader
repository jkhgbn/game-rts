// ambient_soft.gdshader - G-D ambient see-through particles (docs/art/gd_ambient.md), blended (not added), one
// material per look, each drawn by one camera-following GPUParticles3D of AmbientLife:
//   look 0 snow   camera-facing soft flakes (QuadMesh)
//   look 1 dust   camera-facing soft puffs blown along roads / heath in wind gusts, growing over their life
//   look 2 mist   flat soft patches lying over meadows / water at night (PlaneMesh), slow noise inside
//   look 3 ripple flat rings spreading on the water (PlaneMesh at the water line)
// COLOR = the particle colour (alpha ramp = life fade); INSTANCE_CUSTOM.y = the particle's life fraction.
// Fog of war (ambient_common.gdshaderinc): nothing in black fog, dimmed in grey. Close to the camera they fade.
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://art/environment/ambient/ambient_common.gdshaderinc"

uniform int look = 0;
uniform float strength = 1.0;
uniform float near_fade = 6.0;
// Light of the scene (AmbientLife sets it from the lighting rig: dim at night).
uniform vec3 light_tint : source_color = vec3(1.0);

varying float v_a;
varying float v_life;
varying float v_seed;

void vertex() {
	vec3 w = MODEL_MATRIX[3].xyz;
	if (look <= 1) {
		MODELVIEW_MATRIX = amb_billboard(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX);
	}
	v_life = INSTANCE_CUSTOM.y;
	v_seed = amb_pid(INSTANCE_ID, 2.0);
	float d = length(CAMERA_POSITION_WORLD - w);
	v_a = COLOR.a * strength * fog_seen(w) * smoothstep(near_fade * 0.35, near_fade, d);
}

// Cheap value noise for the mist / dust insides.
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = amb_hash(i);
	float b = amb_hash(i + vec2(1.0, 0.0));
	float c = amb_hash(i + vec2(0.0, 1.0));
	float e = amb_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, e, f.x), f.y);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float a = 0.0;
	vec3 col = COLOR.rgb;
	if (look == 0) {
		a = exp(-r * r * 5.0);
		col = mix(col, vec3(1.0), 0.3);
	} else if (look == 1) {
		vec2 nq = q * 1.6 + vec2(v_seed * 17.0, TIME * 0.15);
		float n = vnoise(nq) * 0.65 + vnoise(nq * 2.3) * 0.35;
		a = smoothstep(1.0, 0.15, r) * (0.45 + 0.75 * n);
	} else if (look == 2) {
		vec2 nq = q * 1.3 + vec2(v_seed * 11.0 + TIME * 0.03, TIME * 0.02);
		float n = vnoise(nq) * 0.6 + vnoise(nq * 2.7 + 3.0) * 0.4;
		a = smoothstep(1.0, 0.2, r) * smoothstep(0.25, 0.75, n);
	} else {
		// Ring radius grows with the life; two rings, the second smaller and later.
		float rr = 0.15 + 0.8 * v_life;
		float ring = exp(-pow((r - rr) * 14.0, 2.0));
		float rr2 = 0.1 + 0.6 * clamp(v_life - 0.15, 0.0, 1.0);
		ring += 0.55 * exp(-pow((r - rr2) * 16.0, 2.0)) * step(0.15, v_life);
		a = ring * (1.0 - v_life) * step(r, 1.0);
	}
	ALBEDO = col * light_tint;
	ALPHA = clamp(a * v_a, 0.0, 1.0);
}
