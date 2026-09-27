shader_type spatial;
// Leap / swoop streak (MapFillBeastVfx, task 12.V31): a wind ribbon that trails a leaping Direwolf or a diving Roc.
// QuadMesh 1 x 1; the node basis Y = head - tail (length included), basis X length = the ribbon width; the quad turns
// around Y to face the camera (like combat_streak). Head (+Y) bright, tail fading, wispy wind lines scroll along it.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(1.2, 1.3, 1.5, 1.0);   // linear HDR, a = strength
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;
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
	float y = clamp(v_uv.y, 0.0, 1.0);           // 0 head, 1 tail
	float across = 1.0 - smoothstep(0.15, 1.0, x);
	float along = pow(1.0 - y, 1.3) * smoothstep(0.0, 0.06, y);
	// Wind lines: 3 thin strands across the width, broken up and scrolling toward the tail.
	float strands = pow(abs(sin((v_uv.x - 0.5) * 9.4 + seed * 3.0)), 6.0);
	float n = vnoise(vec2(y * v_len * 1.3 - TIME * 4.0 + seed * 7.0, v_uv.x * 5.0));
	float wisp = 0.45 + 0.55 * mix(n, strands, 0.5);
	float hot = (1.0 - smoothstep(0.0, 0.2, x)) * (1.0 - y) * 0.7;
	ALBEDO = tint.rgb * tint.a * (1.0 + hot);
	ALPHA = clamp(across * along * wisp * fade, 0.0, 1.0);
}
