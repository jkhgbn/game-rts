shader_type spatial;
// forge_citadel cloud layers: big flat sheets (real geometry) with drifting world-space fbm holes: a thin cirrus deck
// high above, a mist deck over the cloud sea. Vertex colour = tint (alpha = density), UV.x = edge fade (0 at the rim,
// 1 inside), UV.y = streak stretch. Soft against the scene depth, faded when the camera is close to the sheet.
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return n2(p) * 0.5 + n2(p * 2.1 + 3.7) * 0.28 + n2(p * 4.3 - 1.3) * 0.14 + n2(p * 8.7) * 0.08; }

void fragment() {
	float stretch = 1.0 + UV.y * 3.0;
	vec2 p = vec2(wp.x / stretch, wp.z) * 0.018 + vec2(TIME * 0.004, TIME * 0.002);
	float f = fbm(p + wp.y * 0.01);
	float cov = smoothstep(0.42, 0.78, f);
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_d = -v.z / v.w;
	float soft = clamp((scene_d - (-VERTEX.z)) / 6.0, 0.0, 1.0);
	float cam_near = smoothstep(4.0, 30.0, abs(wp.y - CAMERA_POSITION_WORLD.y) + length(VERTEX) * 0.08);
	vec3 col = mix(COLOR.rgb * vec3(0.86, 0.82, 0.93), COLOR.rgb, smoothstep(0.45, 0.85, f));
	ALBEDO = col;
	// fade well before the cinematic camera's 250 m far plane (a plane cut by it shows a hard polygon edge)
	float far_fade = smoothstep(235.0, 150.0, length(VERTEX));
	ALPHA = cov * COLOR.a * smoothstep(0.0, 1.0, UV.x) * soft * cam_near * far_fade;
}
