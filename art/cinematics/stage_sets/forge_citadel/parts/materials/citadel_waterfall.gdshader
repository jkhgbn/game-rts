shader_type spatial;
// forge_citadel waterfall sheet: streaks scroll down (UV.y grows downward), foamy edges, soft alpha. No textures.
render_mode blend_mix, cull_disabled, depth_draw_opaque, unshaded;

uniform vec3 deep = vec3(0.34, 0.52, 0.66);
uniform vec3 foam = vec3(0.92, 0.96, 1.0);
uniform float speed = 0.55;

float h1(float n) { return fract(sin(n) * 43758.5453); }
float n1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f); return mix(h1(i), h1(i + 1.0), f); }

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float col = floor(u * 38.0);
	float sp = speed * (0.8 + 0.5 * h1(col * 7.1));
	float s = n1(v * 5.0 - TIME * sp * 6.0 + h1(col) * 20.0);
	float s2 = n1(u * 60.0 + v * 2.0 - TIME * 3.0);
	float streak = smoothstep(0.35, 0.9, s * 0.7 + s2 * 0.4);
	float edge = smoothstep(0.0, 0.12, u) * smoothstep(1.0, 0.88, u);
	float bottom = smoothstep(0.75, 1.0, v);
	vec3 c = mix(deep, foam, clamp(streak * 0.8 + bottom * 0.7 + 0.15, 0.0, 1.0));
	// glints: sparse sparkles riding down with the water, pushed over the glow threshold
	float gc = h1(col * 3.3 + floor(v * 26.0 - TIME * sp * 9.0) * 17.1);
	float glint = smoothstep(0.955, 1.0, gc) * edge * (0.6 + 0.4 * sin(TIME * 11.0 + col));
	ALBEDO = c * COLOR.rgb * 1.2 + vec3(1.0, 0.95, 0.85) * glint * 2.4;
	ALPHA = clamp((0.55 + 0.4 * streak) * edge + bottom * 0.2, 0.0, 0.95) * COLOR.a;
}
