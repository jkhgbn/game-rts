shader_type spatial;
// forge_evenmead birds: small dark swallows wheeling over the valley. Each bird is 4 triangles whose vertices all sit
// on the bird's circle centre (VERTEX); COLOR.rgb - 0.5 carries the vertex's offset in the bird frame (x = span, y = up,
// z = forward). The bird flies round the centre (UV2.x = radius m, UV.y = angular speed rad/s, signed, UV.x = phase)
// and beats its wings (UV2.y = flap phase). Unshaded silhouettes; fog applies.
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.16, 0.13, 0.12);

void vertex() {
	vec3 lo = COLOR.rgb - vec3(0.5);
	float a = UV.x + TIME * UV.y;
	float rad = UV2.x;
	vec3 pos = VERTEX + vec3(cos(a), 0.0, sin(a)) * rad + vec3(0.0, sin(TIME * 0.37 + UV.x * 3.0) * 1.5, 0.0);
	vec3 fwd = normalize(vec3(-sin(a), 0.0, cos(a)) * sign(UV.y));
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(fwd, up));
	float flap = sin(TIME * 11.0 + UV2.y * 6.2831);
	float ly = lo.y + abs(lo.x) * flap * 0.55;
	// bank into the turn
	float bank = 0.35 * sign(UV.y);
	vec3 rb = normalize(right * cos(bank) + up * sin(bank));
	vec3 ub = normalize(cross(rb, fwd));
	VERTEX = pos + rb * lo.x + ub * ly + fwd * lo.z;
	NORMAL = up;
}

void fragment() {
	ALBEDO = tint;
}
