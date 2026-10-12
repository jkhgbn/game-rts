shader_type spatial;
// Hit flash (CombatVfx, task A.12): a camera-facing 4-point star + round hot core, drawn from ONE MultiMesh
// for every live flash (one draw call). The script writes an instance once when the flash starts; the shader
// animates it from `now` (one uniform set per frame), so live flashes cost no per-frame instance updates.
// Instance transform scale = full size in metres, COLOR = kingdom colour (alpha = strength),
// INSTANCE_CUSTOM = (rotation radians, ray strength 0-1, start time, duration) in CombatVfx._clock seconds.
// No depth test: a flash half inside a body would be cut in two; it only lives ~0.15-0.35 s.
// Ice readability pass (2026-10-12): INSTANCE_CUSTOM.y >= 2 marks a COOL flash (Ice): ray strength = y - 2, no
// white-hot core (the core is the kingdom colour instead) and a softer glow, so a hit on a pale Ice unit stays
// cyan and under the bloom instead of turning into a white smear.
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

uniform float now = 0.0;

varying vec2 v_uv;
varying float v_rays;
varying float v_alpha;
varying float v_cool;

void vertex() {
	float k = (now - INSTANCE_CUSTOM.z) / max(INSTANCE_CUSTOM.w, 0.001);
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float size = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	// Pops to full size in the first 15 %, then shrinks to 55 % while it fades (stays bright, then drops).
	size *= (0.6 + 0.4 * min(1.0, k * 6.5)) * (1.0 - 0.45 * k);
	if (k < 0.0 || k >= 1.0) {
		size = 0.0;   // not started / finished: collapse to nothing
	}
	float a = INSTANCE_CUSTOM.x + k * 0.6;
	vec2 p = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	VERTEX = center + vec3(p * size, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_uv = UV;
	v_cool = step(1.5, INSTANCE_CUSTOM.y);
	v_rays = INSTANCE_CUSTOM.y - v_cool * 2.0;
	v_alpha = 1.0 - clamp(k, 0.0, 1.0) * clamp(k, 0.0, 1.0);
}

void fragment() {
	vec2 p = (v_uv - 0.5) * 2.0;
	float r = length(p);
	float core = exp(-r * r * 18.0);
	float glow = exp(-r * r * 4.0) * 0.35;
	float rays = (max(0.0, 1.0 - abs(p.x) * 9.0) * max(0.0, 1.0 - abs(p.y))
			+ max(0.0, 1.0 - abs(p.y) * 9.0) * max(0.0, 1.0 - abs(p.x)));
	float shape = (core + glow) * (1.0 - v_cool * 0.45) + rays * 0.9 * v_rays;
	// Kingdom-coloured rays; white-hot centre, except a cool (Ice) flash: its centre is only a bit more cyan.
	ALBEDO = COLOR.rgb + mix(vec3(core * 0.9), COLOR.rgb * core * 0.15, v_cool);
	ALPHA = clamp(COLOR.a * v_alpha * shape, 0.0, 1.0);
}
