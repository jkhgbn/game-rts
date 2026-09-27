shader_type spatial;
// Straight energy ribbon (SpellVfx, task A.13): the Shadow Lance streak and its piercing flash, the Ember Step
// dash streak. QuadMesh 1 x 1; the node's Y axis (with its length) is the beam, from -Y/2 (tail) to +Y/2 (head);
// the ribbon turns around that axis to face the camera. Premultiplied alpha: a hot core that adds light,
// an `edge` colour that can be dark (covers the ground) for shadow magic.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
		skip_vertex_transform;

instance uniform vec4 core = vec4(2.5, 1.4, 3.0, 1.0);    // centre colour (HDR), a = strength
instance uniform vec4 body_color = vec4(0.25, 0.05, 0.4, 0.7);  // rim colour, a = cover opacity
instance uniform float width = 0.4;                       // metres
instance uniform float fade = 1.0;
instance uniform float tail = 0.8;                        // 0 = even, 1 = fully faded at the tail
instance uniform float flow = 3.0;                        // noise scroll speed toward the head
instance uniform float wobble = 0.3;                      // ragged edges (0 = clean)
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
	float x = abs(UV.x * 2.0 - 1.0);              // 0 centre, 1 edge
	float along = 1.0 - UV.y;                      // 0 tail, 1 head
	float n = vnoise(vec2(UV.x * 3.0 + seed * 5.0, UV.y * v_len * 1.6 + TIME * flow));
	float edge_x = 1.0 - wobble * n * 0.6;
	float body = 1.0 - smoothstep(edge_x * 0.55, edge_x, x);
	float hot = 1.0 - smoothstep(0.0, 0.35 + 0.1 * n, x);
	float len_fade = mix(1.0, smoothstep(0.0, 1.0, along), tail);
	float tip = smoothstep(1.0, 0.94, along);      // soft head tip
	float k = len_fade * tip * fade;
	float cover = body_color.a * body * k;
	vec3 glow = core.rgb * core.a * hot * (0.75 + 0.5 * n) * k;
	ALBEDO = body_color.rgb * cover + glow;
	ALPHA = cover;
}
