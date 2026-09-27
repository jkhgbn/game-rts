shader_type spatial;
// The Wayfarer's Blessing rune floating over each blessed unit (MapFillVfx `blessing`, task 12.V25). ONE MultiMesh of
// 1 x 1 quads (<= 80 instances, one draw call); each instance faces the camera, its scale = the rune size in metres.
// The glyph echoes the Wayshrine's carved mark: a stem on a short base, two uneven horns cradling a floating dot,
// inside a thin dashed ring. Gold glow with a dark outline so it reads on grass, stone and water alike.
// Per instance: COLOR.rgb = glow colour (linear HDR), COLOR.a = fade; INSTANCE_CUSTOM.x = age (s, pops in),
// INSTANCE_CUSTOM.y = seed (phase of the shimmer).
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled,
		fog_disabled;

varying vec4 v_tint;
varying float v_age;
varying float v_seed;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	float pop = 1.0 + 0.45 * exp(-INSTANCE_CUSTOM.x * 7.0) * sin(min(INSTANCE_CUSTOM.x * 18.0, 3.14159));
	s *= pop;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	v_tint = COLOR;
	v_age = INSTANCE_CUSTOM.x;
	v_seed = INSTANCE_CUSTOM.y;
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);   // y up
	float r = length(p);
	// Glyph strokes (distance in quad units).
	float d = seg(p, vec2(0.0, -0.62), vec2(0.0, 0.02));
	d = min(d, seg(p, vec2(-0.26, -0.62), vec2(0.26, -0.62)));
	d = min(d, seg(p, vec2(0.0, -0.08), vec2(-0.40, 0.30)));
	d = min(d, seg(p, vec2(-0.40, 0.30), vec2(-0.34, 0.62)));
	d = min(d, seg(p, vec2(0.0, -0.08), vec2(0.36, 0.22)));
	d = min(d, seg(p, vec2(0.36, 0.22), vec2(0.44, 0.50)));
	d = min(d, length(p - vec2(0.0, 0.40)) - 0.05);
	float w = 0.075;
	float g = d - w;
	float core = 1.0 - smoothstep(-0.02, 0.02, g);
	float halo = exp(-max(g, 0.0) * 9.0) * 0.55;
	// Thin dashed ring, slowly turning.
	float au = atan(p.y, p.x) / 6.2831853 + 0.5;
	float dash = step(0.3, fract(au * 10.0 + TIME * 0.12 + v_seed));
	float ring = (1.0 - smoothstep(0.0, 0.035, abs(r - 0.86))) * dash * 0.7;
	float shimmer = 0.85 + 0.15 * sin(TIME * 3.0 + v_seed * 6.2831853);
	float flash = 1.0 + 1.2 * exp(-v_age * 5.0);
	vec3 hot = mix(v_tint.rgb, vec3(max(v_tint.r, max(v_tint.g, v_tint.b))), 0.45);
	vec3 glow = (v_tint.rgb * (halo + ring) + hot * core * 1.3) * shimmer * flash;
	// Dark outline under the strokes and the ring (premultiplied: darkens whatever is behind).
	float cover = (1.0 - smoothstep(0.0, 0.08, g)) * 0.7 + (1.0 - smoothstep(0.02, 0.07, abs(r - 0.86))) * dash * 0.35;
	cover *= smoothstep(1.0, 0.95, r);
	float fade = clamp(v_tint.a, 0.0, 1.0);
	ALBEDO = glow * fade;
	ALPHA = clamp(cover, 0.0, 1.0) * fade;
}
