// fire_heat_haze.gdshader - heat shimmer over the Fire buildings' chimneys and forges (G-B, High / Ultra only:
// FireBuildingLook.add_heat_haze makes no quad at Low / Medium). A camera-facing quad (pivot at its bottom) that
// bends the screen behind it with two scrolling noise layers; it fades at its edges and towards the top. No depth
// write, no shadow.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
instance uniform float strength = 1.0;   // per quad (one shared material for every haze)
uniform float speed = 0.9;

void vertex() {
	// Cylindrical billboard (stays upright, turns to the camera).
	vec3 cam_r = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 sx = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), 1.0);
	vec3 world = MODEL_MATRIX[3].xyz + cam_r * VERTEX.x * sx.x + vec3(0.0, VERTEX.y * sx.y, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

float wave(vec2 p) {
	return sin(p.x * 7.0 + sin(p.y * 3.1)) * sin(p.y * 5.3 + p.x * 1.7);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float edge = smoothstep(0.0, 0.3, uv.x) * smoothstep(1.0, 0.7, uv.x);
	float vert = smoothstep(1.0, 0.75, uv.y) * smoothstep(0.0, 0.85, uv.y);   // UV.y 0 = top of the quad
	float mask = edge * vert;
	vec2 w = vec2(wave(uv * vec2(2.0, 3.0) + vec2(0.0, t * 1.7)), wave(uv * vec2(3.0, 2.0) + vec2(t * 0.6, t * 2.3)));
	vec2 off = w * 0.006 * strength * mask;
	vec3 c = textureLod(screen_tex, SCREEN_UV + off, 0.0).rgb;
	ALBEDO = c;   // pure refraction: no added light (the Art Lab must not count it as a glow point)
	ALPHA = mask;
}
