// barrow_shroud.gdshader - the Barrow Giant's tattered burial shroud (task 13c.V3). A copy of art/shaders/banner.gdshader
// (same wave, same light ramp, same `phase` instance uniform on slot 0 so it merges with the body like every cape) with a
// ragged, moth-eaten cloth instead of the stripe / glyph / swallow-tail: a torn bottom edge, a few holes, grime near the
// hem. Team colour: the kit recolours materials whose name ends in "_cape" through `cloth_color` / `stripe_color`.
// Mesh: a vertical PlaneMesh (orientation Z) with UV.y = 0 at the top (fixed) edge (CharacterModel.cape()).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 cloth_color : source_color = vec3(0.42, 0.22, 0.60);
uniform vec3 stripe_color : source_color = vec3(0.18, 0.08, 0.28);
uniform float amplitude = 0.05;
uniform float speed = 1.6;
uniform float tatter = 0.22;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
instance uniform float phase : instance_index(0) = 0.0;

float hash1(float x) {
	return fract(sin(x * 12.9898 + 4.1) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(27.1, 61.7))) * 43758.5453);
}

void vertex() {
	float w = UV.y;
	VERTEX.z += sin(TIME * speed + UV.y * 5.0 + UV.x * 2.0 + phase) * amplitude * w;
	VERTEX.x += sin(TIME * speed * 0.41 + UV.y * 2.0 + phase) * amplitude * 0.35 * w;
}

void fragment() {
	// Torn bottom edge: 9 strips of random length, each cut to a point.
	float cols = 9.0;
	float cell = floor(UV.x * cols);
	float fx = fract(UV.x * cols) - 0.5;
	float edge = 1.0 - tatter * (0.25 + 0.75 * hash1(cell)) - abs(fx) * tatter * 0.6;
	if (UV.y > edge) {
		discard;
	}
	// A few moth holes in the lower two thirds.
	vec2 g = UV * vec2(5.0, 8.0);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	if (UV.y > 0.3 && hash2(id) > 0.82 && length(f * vec2(1.0, 1.4)) < 0.22 + 0.1 * hash2(id + 3.1)) {
		discard;
	}
	// Grime: the cloth darkens toward the torn hem and near the fixed top fold.
	float grime = smoothstep(0.45, 1.0, UV.y / max(edge, 0.01)) * 0.7 + 0.25 * hash2(id * 1.7);
	vec3 col = mix(cloth_color, stripe_color, clamp(grime, 0.0, 1.0));
	col *= mix(0.72, 1.04, smoothstep(0.0, 0.3, UV.y));
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
