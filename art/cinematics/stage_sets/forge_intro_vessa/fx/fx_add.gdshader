// fx_add.gdshader - prologue vignette spell props (forge_intro_*): additive glowing sheets (fire pillars, arrow streaks,
// frost cracks, bloom rings). Unshaded + additive: no lights needed (0-lights rule), looping on TIME only, so a
// fixed-fps record is deterministic. UV.x wraps around a tube (period = tiling.x), UV.y runs along it (0 -> 1).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 col_a : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform vec4 col_b : source_color = vec4(1.0, 0.85, 0.45, 1.0);
uniform float energy = 2.0;
uniform vec2 scroll = vec2(0.0, -0.6);
uniform vec2 tiling = vec2(4.0, 3.0);
uniform float twist = 0.0;
uniform float sharp = 1.5;
uniform float fres = 1.0;
uniform float fade_lo = 0.12;
uniform float fade_hi = 0.25;
uniform float base = 0.15;
uniform float sway = 0.0;
uniform float pulse = 0.0;
uniform float dash = 0.0;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnw(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, period);
	float x1 = mod(i.x + 1.0, period);
	float a = h21(vec2(x0, i.y));
	float b = h21(vec2(x1, i.y));
	float c = h21(vec2(x0, i.y + 1.0));
	float d = h21(vec2(x1, i.y + 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	if (sway > 0.0) {
		float ph = COLOR.a * 6.2831;
		VERTEX.x += sin(TIME * 1.3 + VERTEX.y * 0.35 + ph) * sway * UV.y;
		VERTEX.z += cos(TIME * 1.1 + VERTEX.y * 0.3 + ph) * sway * UV.y;
	}
}

void fragment() {
	vec2 uv = UV * tiling + scroll * TIME + vec2(twist * UV.y, 0.0);
	float n = vnw(uv, tiling.x) * 0.62 + vnw(uv * 2.0 + vec2(0.0, 3.1), tiling.x * 2.0) * 0.38;
	float m = base + (1.0 - base) * pow(n, sharp);
	if (dash > 0.0) {
		float d = fract(UV.y * dash + scroll.y * TIME);
		m *= smoothstep(0.0, 0.08, d) * smoothstep(0.55, 0.2, d);
	}
	float edge = smoothstep(0.0, max(fade_lo, 0.0001), UV.y) * smoothstep(1.0, 1.0 - max(fade_hi, 0.0001), UV.y);
	float fr = fres > 0.0 ? pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), fres) : 1.0;
	float p = 1.0 + pulse * sin(TIME * 2.7 + COLOR.a * 6.2831);
	vec3 c = mix(col_a.rgb, col_b.rgb, clamp(n * 1.3 - 0.15, 0.0, 1.0)) * COLOR.rgb;
	float k = clamp(m * edge * fr, 0.0, 1.0);
	ALBEDO = c * energy * p;
	ALPHA = k;
}
