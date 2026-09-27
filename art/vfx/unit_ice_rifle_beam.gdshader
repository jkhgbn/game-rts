shader_type spatial;
// Rune-rifle lines (UnitIceRifleVfx, task 13b.V7). QuadMesh 1 x 1: the node's Y axis (with its length) spans the line
// from A (-Y/2, the muzzle) to B (+Y/2, the target); the ribbon turns around that axis to face the camera, `width` in
// metres. ONE material, three looks picked per instance (`mode`):
//   0 frost tracer   the lit part is [tail, head] (0..1 along A->B): a white-hot head with a cold streak behind it,
//                    frost glints twinkling along the line.
//   1 aim line       Rime Lock sight line: thin, rune dashes flowing toward the target that close into a solid line as
//                    `charge` (0..1) rises; it flickers in the last fifth. [tail, head] grows it out of the muzzle.
//   2 shot / column  a thick bright beam with flowing frost (the Rime Lock shot, the freeze column).
// Premultiplied alpha: `edge` (a = cover) is a dark ice-blue rim so the thin lines read on snow and grass.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
		skip_vertex_transform;

instance uniform vec4 core = vec4(1.6, 2.6, 3.4, 1.0);     // hot centre (linear HDR), a = strength
instance uniform vec4 edge = vec4(0.06, 0.16, 0.34, 0.3);  // rim colour, a = cover opacity
instance uniform float width = 0.07;
instance uniform float fade = 1.0;
instance uniform float head = 1.0;
instance uniform float tail = 0.0;
instance uniform float mode = 0.0;
instance uniform float charge = 0.0;
instance uniform float seed = 0.0;

varying float v_len;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 ax = MODEL_MATRIX[1].xyz;
	vec3 mid = MODEL_MATRIX[3].xyz;
	vec3 at = mid + ax * VERTEX.y;
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - at);
	vec3 side = cross(normalize(ax), to_cam);
	float sl = length(side);
	side = sl > 0.001 ? side / sl : vec3(1.0, 0.0, 0.0);
	v_len = length(ax);
	VERTEX = (VIEW_MATRIX * vec4(at + side * VERTEX.x * width, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);         // 0 centre, 1 edge
	float s = 1.0 - UV.y;                     // 0 = A (muzzle), 1 = B (target)
	float L = max(v_len, 0.01);
	int m = int(mode + 0.5);
	float hot = 1.0 - smoothstep(0.0, 0.32, x);
	float body = 1.0 - smoothstep(0.35, 1.0, x);
	float lit = 0.0;
	float rim = 0.0;
	float ends = smoothstep(tail, tail + 0.4 / L, s) * (1.0 - smoothstep(head - 0.05 / L, head, s));
	if (m == 0) {
		float behind = max(head - s, 0.0) * L;          // metres behind the head
		float streak = exp(-behind / 4.5) * 0.85 + 0.3;
		float glint_cell = floor(s * L * 5.0);
		float g = step(0.86, hash(vec2(glint_cell, seed * 7.0)));
		float tw = 0.5 + 0.5 * sin(TIME * 30.0 + glint_cell * 2.3);
		float cell_x = abs(fract(s * L * 5.0) - 0.5) * 2.0;
		float glint = g * tw * (1.0 - smoothstep(0.0, 0.6, cell_x)) * (1.0 - smoothstep(0.0, 0.9, x)) * 0.9;
		float tip = exp(-behind * 3.0) * 1.3;
		lit = (hot * (streak + tip) + body * 0.35 * streak + glint) * ends;
		rim = body * ends * (0.4 + 0.6 * exp(-behind / 6.0));
	} else if (m == 1) {
		float flow = fract(s * L * 1.25 - TIME * 3.2 + seed);
		float dash = smoothstep(0.0, 0.08, flow) * (1.0 - smoothstep(0.45, 0.55, flow));
		float solid = smoothstep(0.35, 1.0, charge);
		float line = mix(0.45 + 0.9 * dash, 1.0 + 0.35 * dash, solid);
		float flick = 1.0 + 0.45 * sin(TIME * 47.0 + seed * 5.0) * step(0.8, charge);
		float strength = mix(0.45, 1.25, charge) * flick;
		float near_t = 0.35 + 0.65 * smoothstep(0.0, 1.0, s);   // brighter toward the target
		lit = (hot * line + body * 0.25) * strength * near_t * ends;
		rim = body * ends * (0.55 + 0.45 * charge);
	} else {
		float n = vnoise(vec2(UV.x * 3.0 + seed * 5.0, s * L * 1.3 - TIME * 9.0));
		float edge_x = 1.0 - 0.35 * n;
		float b2 = 1.0 - smoothstep(edge_x * 0.5, edge_x, x);
		lit = (hot * (1.3 + 0.4 * n) + b2 * 0.6) * ends;
		rim = b2 * ends;
	}
	float cover = clamp(edge.a * rim, 0.0, 1.0) * fade;
	ALBEDO = edge.rgb * cover + core.rgb * core.a * lit * fade;
	ALPHA = cover;
}
