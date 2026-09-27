shader_type spatial;
// The Glade Outrider's parting-shot arrow in flight (UnitNatureT3Vfx, task 13b.V9). ONE 1 x 1 QuadMesh per arrow (pooled),
// drawn as a billboard that only turns around its own Y axis (like combat_streak): the instance basis Y = head - tail
// (length included), X = the width. From the head (+Y, UV.y 0) to the tail (UV.y 1): a glowing lime SEED HEAD (the
// read at 40 m), a dark ash shaft, two green leaf-fletching vanes, then a soft lime trail with drifting leaf glints.
// `arrow_frac` = the share of the quad that is the arrow itself (the trail grows behind it as it flies).
// Premultiplied alpha: the wood covers the ground, the glow adds light (HDR `tint` crosses the bloom threshold).
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(1.3, 2.4, 0.45, 1.0);   // seed head + trail glow (linear HDR), a = strength
instance uniform float fade = 1.0;
instance uniform float arrow_frac = 0.35;
instance uniform float seed = 0.0;

uniform vec3 shaft_color : source_color = vec3(0.36, 0.26, 0.16);
uniform vec3 fletch_color : source_color = vec3(0.30, 0.62, 0.20);

varying vec2 v_uv;
varying float v_len;

void vertex() {
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 to_cam = normalize(-center);
	vec3 side = cross(axis, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	float len = max(al, width);
	VERTEX = center + along * VERTEX.y * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
	v_len = len;
}

void fragment() {
	float x = abs(v_uv.x - 0.5) * 2.0;           // 0 centre line, 1 edge
	float y = clamp(v_uv.y, 0.0, 1.0);           // 0 head (+Y), 1 tail
	float L = clamp(arrow_frac, 0.05, 1.0);
	float ya = y / L;                            // 0 head .. 1 nock (arrow part)
	// Seed head: a pointed leaf-shaped glow (widest at 40 % of its length).
	float hk = clamp(ya / 0.2, 0.0, 1.0);
	float hw = sin(pow(hk, 0.7) * 3.14159) * 0.95;
	float head = step(ya, 0.2) * (1.0 - smoothstep(hw - 0.18, hw + 0.02, x));
	// Shaft: thin dark wood.
	float shaft = (1.0 - smoothstep(0.15, 0.24, x)) * step(0.15, ya) * step(ya, 1.0);
	// Fletching: two leaf vanes near the nock, swept back.
	float ft = clamp((ya - 0.7) / 0.28, 0.0, 1.0);
	float vane_w = sin(ft * 3.14159) * 0.9;
	float vane = step(0.7, ya) * step(ya, 0.98) * (1.0 - smoothstep(vane_w - 0.12, vane_w, x)) * step(0.1, x);
	float body_a = max(max(shaft * 0.95, vane * 0.9), head * 0.2);
	vec3 body = mix(shaft_color * (0.8 + 0.4 * (1.0 - x)), fletch_color, vane);
	// Trail: a soft lime streak starting at the fletching, tapering and fading to the tail, with leaf glints.
	float tr0 = L * 0.7;
	float ty = clamp((y - tr0) / max(1.0 - tr0, 0.001), 0.0, 1.0);
	float trail = smoothstep(0.0, 0.1, ty) * exp(-x * x * (12.0 + ty * 18.0)) * pow(1.0 - ty, 2.0);
	float gl = fract(y * v_len * 1.6 - TIME * 3.0 + seed);
	float glint = exp(-pow((gl - 0.5) * 7.0, 2.0)) * exp(-x * x * 18.0) * (1.0 - ty) * step(tr0, y);
	float halo = exp(-x * x * 3.0) * (1.0 - smoothstep(0.0, 0.35, ya)) * 0.45;   // bloom seed around the head
	float glow = head * 1.6 + halo + trail * 0.5 + glint * 0.45;
	vec3 emit = tint.rgb * tint.a * glow;
	ALBEDO = (body * body_a + emit) * fade;
	ALPHA = body_a * fade;
}
