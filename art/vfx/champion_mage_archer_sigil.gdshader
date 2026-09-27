shader_type spatial;
// The Grave Mark sigil (ChampionVfx + ChampionMageArcherVfx, task 13b.V8): a camera-facing glyph hung over the marked
// unit. QuadMesh 1 x 1, size = node scale. A broken rune ring turning slowly round the mark: a downward arrow (it
// points at the prey) struck through with a grave cross, its fletching at the top. Dark outline so it reads on any
// ground; drawn on top of bodies (no depth test) like the other champion badges; a flash when it lands (`age`).
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 0.25, 2.2, 1.0);   // glow colour (linear HDR)
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float tri(vec2 p, vec2 a, vec2 b, vec2 c) {
	// < 0 inside (approximate signed distance for a small triangle).
	vec2 e0 = b - a;
	vec2 e1 = c - b;
	vec2 e2 = a - c;
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	float d0 = s * (e0.x * (p.y - a.y) - e0.y * (p.x - a.x)) / length(e0);
	float d1 = s * (e1.x * (p.y - b.y) - e1.y * (p.x - b.x)) / length(e1);
	float d2 = s * (e2.x * (p.y - c.y) - e2.y * (p.x - c.x)) / length(e2);
	return -min(min(d0, d1), d2);
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);   // +y up
	float r = length(p);
	float ang = atan(p.y, p.x);
	float au = ang / 6.2831853 + 0.5;
	float t = TIME + seed * 5.0;
	// Distance field of the glyph (0 on the strokes).
	float dm = seg(p, vec2(0.0, 0.46), vec2(0.0, -0.2));                      // shaft
	dm = min(dm, seg(p, vec2(-0.25, 0.2), vec2(0.25, 0.2)));                  // grave cross bar
	dm = min(dm, seg(p, vec2(0.0, 0.46), vec2(-0.14, 0.6)));                  // fletching
	dm = min(dm, seg(p, vec2(0.0, 0.46), vec2(0.14, 0.6)));
	dm = min(dm, seg(p, vec2(0.0, 0.35), vec2(-0.14, 0.49)));
	dm = min(dm, seg(p, vec2(0.0, 0.35), vec2(0.14, 0.49)));
	float head = tri(p, vec2(0.0, -0.64), vec2(-0.25, -0.2), vec2(0.25, -0.2));   // the arrowhead points at the prey
	// The broken ring: 4 arcs with gaps turning slowly, and a dotted inner ring turning the other way.
	float s = fract(au * 4.0 + t * 0.08);
	float arcs = smoothstep(0.05, 0.1, s) * (1.0 - smoothstep(0.9, 0.95, s));
	float dr = abs(r - 0.8);
	float s2 = fract(au * 24.0 - t * 0.15);
	float dots = (1.0 - smoothstep(0.018, 0.035, length(vec2((s2 - 0.5) * 6.2831853 * 0.66 / 24.0, r - 0.66))));
	float w = 0.045;
	float stroke = 1.0 - smoothstep(w, w + 0.025, dm);
	float headf = 1.0 - smoothstep(0.0, 0.025, head);
	float ring = (1.0 - smoothstep(0.03, 0.055, dr)) * arcs;
	float shape = max(max(stroke, headf), max(ring, dots * 0.8));
	// Dark outline: the shape grown by ~0.07.
	float ol = max(max(1.0 - smoothstep(w + 0.06, w + 0.1, dm), 1.0 - smoothstep(0.05, 0.1, head)),
			(1.0 - smoothstep(0.08, 0.12, dr)) * arcs);
	float pulse = 0.82 + 0.18 * sin(t * 4.0);
	float flash = exp(-age * 5.0);
	float halo = pow(clamp(1.0 - r, 0.0, 1.0), 2.0) * 0.35;
	vec3 hot = vec3(1.45, 1.25, 1.7);
	vec3 emit = tint.rgb * (shape * (1.1 + flash * 1.5) * pulse + halo * pulse)
			+ hot * (stroke + headf) * (0.35 + flash * 0.8);
	float a = clamp(ol * 0.8, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + vec3(0.03, 0.01, 0.05) * a;
	ALPHA = a;
}
