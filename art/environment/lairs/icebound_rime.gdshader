// icebound_rime.gdshader - hoarfrost on the river banks round the Icebound Barge (task 13c.V9). A PlaneMesh a few cm
// over the bank tops; it draws ONLY where a surface lies just under it (the banks), read from the depth buffer, so it
// never floats over the water or the ice sheet (both sit ~0.35 m lower) and needs no decal node. Unshaded, alpha
// blended, no depth write, local-space pattern (turns with the barge). `freeze` 0 -> 1 spreads it, back to 0 melts it.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

instance uniform float freeze = 1.0;
uniform float radius = 6.5;
uniform vec3 frost_color : source_color = vec3(0.86, 0.92, 0.98);
uniform float strength = 0.78;
uniform float hug = 0.32;            // metres (view depth) of gap that still draws
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec2 v_lp;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + vec2(7.1, 1.3)) * 0.3 + vnoise(p * 4.07 - vec2(3.3, 5.9)) * 0.15;
}

void vertex() {
	v_lp = VERTEX.xz;
}

void fragment() {
	vec2 p = v_lp;
	float r = length(p);
	vec2 dir = p / max(r, 0.001);
	float R = radius * clamp(freeze, 0.0, 1.0);
	float edge = R * (0.8 + 0.2 * vnoise(dir * 3.0 + 2.0));
	float inside = 1.0 - smoothstep(edge * 0.55, edge, r);
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 wv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -wv.z / wv.w;
	float gap = scene_z + VERTEX.z;       // how far behind the plane the visible surface is
	float on_ground = 1.0 - smoothstep(hug * 0.5, hug, gap);
	float n = fbm(p * 1.6);
	float fern = smoothstep(0.86, 0.97, 1.0 - abs(fbm(p * 3.4 + 5.0) * 2.0 - 1.0));
	float a = inside * on_ground * strength * clamp(0.45 + (n - 0.5) * 1.2 + fern * 0.5, 0.0, 1.0);
	ALBEDO = frost_color * (0.62 + 0.16 * n + 0.2 * fern);
	ALPHA = clamp(a, 0.0, 1.0);
}
