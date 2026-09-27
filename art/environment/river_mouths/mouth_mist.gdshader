// mouth_mist.gdshader - mist cards of the river mouths (task 12.V5): soft spray rising from the plunge pool under the
// north falls and from the rapid steps of the south gorge. Every card of the mesh is a camera-facing billboard that
// slowly rises, swells and fades on its own phase, so all the mist is ONE draw call. Transparent, unshaded, no depth
// / screen reads (no proximity fade), no lights. Mesh baked by build_env.gd (river mouths section):
//   VERTEX  card centre + (corner.x, -corner.y) * size / 2 in the local XY plane (keeps the mesh AABB honest)
//   UV      0..1 across the card (corner = UV * 2 - 1)
//   UV2.x   card size in metres, UV2.y phase 0..1
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, skip_vertex_transform;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 mist_color : source_color = vec3(0.84, 0.92, 0.93);
uniform float opacity = 0.42;
uniform float cycle = 7.0;          // seconds for one rise-and-fade of a card
uniform float rise = 1.3;           // metres a card rises over its cycle

varying vec2 v_corner;
varying float v_life;
varying float v_phase;

void vertex() {
	vec2 corner = UV * 2.0 - 1.0;
	float size = UV2.x;
	float ph = UV2.y;
	vec3 centre = VERTEX - vec3(corner.x, -corner.y, 0.0) * size * 0.5;
	float life = fract(TIME / cycle + ph);
	centre.y += life * rise;
	float s = size * (0.75 + life * 0.5);
	vec4 c = MODELVIEW_MATRIX * vec4(centre, 1.0);
	c.xy += vec2(corner.x, -corner.y) * s * 0.5;
	VERTEX = c.xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_corner = corner;
	v_life = life;
	v_phase = ph;
}

void fragment() {
	float r = length(v_corner);
	float soft = 1.0 - smoothstep(0.25, 1.0, r);
	// Billowy edge: a noise that drifts inside the card.
	float n = texture(noise_tex, v_corner * 0.35 + vec2(v_phase * 3.7, v_phase * 1.3 - TIME * 0.04)).r;
	float puff = smoothstep(0.30, 0.70, n * 0.8 + soft * 0.45);
	float fade = sin(v_life * PI);
	ALBEDO = mist_color * (0.92 + n * 0.1);
	ALPHA = soft * puff * fade * opacity;
}
