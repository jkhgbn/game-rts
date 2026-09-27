// fx_veil.gdshader - prologue spell props: alpha-blended dark / misty sheets with glowing streaks (shadow vortex, dark
// pools, frost mist). Unshaded, loops on TIME only. UV.x wraps (period tiling.x), UV.y runs along the sheet.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 dark : source_color = vec4(0.05, 0.02, 0.09, 1.0);
uniform vec4 glow : source_color = vec4(0.65, 0.3, 1.0, 1.0);
uniform float energy = 2.5;
uniform vec2 scroll = vec2(0.15, -0.2);
uniform vec2 tiling = vec2(6.0, 3.0);
uniform float twist = 2.0;
uniform float streak = 0.72;
uniform float opacity = 0.85;
uniform float fade_lo = 0.15;
uniform float fade_hi = 0.25;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnw(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, period);
	float x1 = mod(i.x + 1.0, period);
	return mix(mix(h21(vec2(x0, i.y)), h21(vec2(x1, i.y)), f.x), mix(h21(vec2(x0, i.y + 1.0)), h21(vec2(x1, i.y + 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV * tiling + scroll * TIME + vec2(twist * UV.y, 0.0);
	float n = vnw(uv, tiling.x) * 0.6 + vnw(uv * 2.0 + vec2(1.7, 0.0), tiling.x * 2.0) * 0.4;
	float s = smoothstep(streak, streak + 0.12, n);
	float edge = smoothstep(0.0, max(fade_lo, 0.0001), UV.y) * smoothstep(1.0, 1.0 - max(fade_hi, 0.0001), UV.y);
	ALBEDO = mix(dark.rgb * (0.6 + 0.8 * n), glow.rgb * energy, s) * COLOR.rgb;
	ALPHA = clamp(opacity * edge * (0.55 + 0.45 * n) + s * edge * 0.5, 0.0, 1.0) * COLOR.a;
}
