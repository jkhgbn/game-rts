// fx_solid.gdshader - prologue spell props: opaque lit bodies with glowing veins (shadow tendrils, ice walls, vines,
// the bloom tree). Vertex COLOR = albedo (sRGB), COLOR.a = per-piece phase. Loops on TIME only (0 lights: the veins
// are emission, the sets' LightingRig lights the body).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 vein : source_color = vec4(0.7, 0.3, 1.0, 1.0);
uniform float energy = 2.0;
uniform vec2 tiling = vec2(3.0, 6.0);
uniform vec2 scroll = vec2(0.0, -0.5);
uniform float vein_w = 0.78;
uniform float sway = 0.0;
uniform float rough = 0.6;
uniform float spec = 0.4;
uniform float rim = 0.35;
uniform float tip_glow = 0.0;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnw(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, period);
	float x1 = mod(i.x + 1.0, period);
	return mix(mix(h21(vec2(x0, i.y)), h21(vec2(x1, i.y)), f.x), mix(h21(vec2(x0, i.y + 1.0)), h21(vec2(x1, i.y + 1.0)), f.x), f.y);
}

void vertex() {
	if (sway > 0.0) {
		float ph = COLOR.a * 6.2831;
		VERTEX.x += sin(TIME * 1.2 + ph + UV.y * 3.0) * sway * UV.y * UV.y;
		VERTEX.z += cos(TIME * 0.9 + ph * 1.3 + UV.y * 2.5) * sway * UV.y * UV.y;
	}
}

void fragment() {
	vec2 uv = UV * tiling + scroll * TIME;
	float n = vnw(uv, tiling.x);
	float v = smoothstep(vein_w, vein_w + 0.08, n) + smoothstep(vein_w + 0.1, vein_w, n) * 0.0;
	float p = 0.8 + 0.2 * sin(TIME * 2.3 + COLOR.a * 6.2831);
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * (0.85 + 0.3 * vnw(uv * 0.5 + 7.0, tiling.x * 0.5));
	ROUGHNESS = rough;
	SPECULAR = spec;
	RIM = rim;
	RIM_TINT = 0.6;
	EMISSION = vein.rgb * energy * p * (v + tip_glow * smoothstep(0.7, 1.0, UV.y));
}
