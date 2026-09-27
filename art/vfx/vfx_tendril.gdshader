shader_type spatial;
// Curved draining tendril (SpellVfx, task A.13, Soul Siphon): a ribbon along the quadratic curve p0 -> p1 -> p2
// in world space (the node sits at the origin with a custom AABB), turned to face the camera, wriggling, with
// bright pulses flowing from p0 (the victim) to p2 (the sink). QuadMesh 1 x 1 subdivided along Y.
// Premultiplied alpha: dark ragged body that covers + violet glowing core that adds light.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
		skip_vertex_transform;

instance uniform vec3 p0 = vec3(0.0);
instance uniform vec3 p1 = vec3(0.0, 1.0, 0.0);
instance uniform vec3 p2 = vec3(0.0, 0.0, 1.0);
instance uniform vec4 core = vec4(1.6, 0.6, 2.6, 1.0);
instance uniform vec4 body_color = vec4(0.08, 0.0, 0.14, 0.75);
instance uniform float width = 0.28;
instance uniform float fade = 1.0;
instance uniform float pulse = 0.0;       // 0-1 extra glow (heal tick)
instance uniform float seed = 0.0;
instance uniform float grow = 1.0;        // 0-1: how far from p0 the tendril reaches (spawn animation)

varying float v_t;

void vertex() {
	float t = clamp(0.5 - VERTEX.y, 0.0, 1.0) * grow;
	v_t = t;
	float u = 1.0 - t;
	vec3 pos = u * u * p0 + 2.0 * u * t * p1 + t * t * p2;
	vec3 tan = normalize(2.0 * u * (p1 - p0) + 2.0 * t * (p2 - p1) + vec3(0.0001));
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - pos);
	vec3 side = cross(tan, to_cam);
	float sl = length(side);
	side = sl > 0.001 ? side / sl : vec3(1.0, 0.0, 0.0);
	vec3 up2 = normalize(cross(side, tan));
	float env = sin(3.14159 * t);
	float ph = seed * 6.28;
	pos += (side * sin(t * 9.0 - TIME * 5.0 + ph) * 0.22 + up2 * cos(t * 7.0 - TIME * 4.0 + ph * 1.3) * 0.16) * env;
	float w = width * mix(1.0, 0.45, t) * (0.85 + 0.15 * sin(TIME * 9.0 + t * 20.0 + ph));
	VERTEX = (VIEW_MATRIX * vec4(pos + side * VERTEX.x * w, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);
	float t = v_t;
	float ph = seed * 6.28;
	float beads = pow(0.5 + 0.5 * sin(t * 22.0 - TIME * 14.0 + ph), 6.0);
	float body = 1.0 - smoothstep(0.65, 1.0, x);
	float hot = 1.0 - smoothstep(0.0, 0.5, x);
	float ends = smoothstep(0.0, 0.08, t) * smoothstep(1.0, 0.9, t / max(grow, 0.001));
	float k = ends * fade;
	float cover = body_color.a * body * k;
	vec3 glow = core.rgb * core.a * hot * (0.35 + beads * 1.4 + pulse * 1.2) * k;
	ALBEDO = body_color.rgb * cover + glow;
	ALPHA = cover;
}
