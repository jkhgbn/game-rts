// fire_keep_banner.gdshader - the Fire Keep's banners (task A.7). Same look rules as
// art/shaders/banner.gdshader (art-keep.md 5.2) but for MERGED banner meshes: the cloth waves along its
// own NORMAL, the per-banner phase comes from UV2.x, UV is 0..1 per banner (y = 0 at the fixed top edge).
// Adds a bronze border, a proper flame emblem and a swallow-tail.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 cloth_color : source_color = vec3(0.85, 0.30, 0.12);
uniform vec3 stripe_color : source_color = vec3(0.55, 0.08, 0.05);
uniform vec3 trim_color : source_color = vec3(0.80, 0.55, 0.22);
uniform vec3 glyph_color : source_color = vec3(1.0, 0.75, 0.30);
uniform float glyph_energy = 0.9;
uniform float amplitude = 0.12;
uniform float speed = 2.4;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;

void vertex() {
	float w = UV.y;
	float ph = UV2.x;
	float wave = sin(TIME * speed + UV.y * 5.0 + ph) * amplitude * w
		+ sin(TIME * speed * 1.7 + UV.x * 3.0 + ph * 2.0) * amplitude * 0.3 * w;
	VERTEX += NORMAL * wave;
}

float flame(vec2 uv, float t) {
	// uv: x -1..1 across, y -1 (tip) .. 1 (base)
	float y = uv.y;
	float x = uv.x + 0.10 * sin(y * 5.0 + t * 3.0) * (1.0 - y) * 0.5;
	float body = length(vec2(x, (y - 0.42) * 1.05)) - 0.52;
	float taper = 0.55 * clamp((y + 1.0) / 1.42, 0.0, 1.0);
	float cone = abs(x) - taper;
	float d = y < 0.42 ? max(cone, -y - 1.0) : body;
	return d;
}

void fragment() {
	if (UV.y > 0.86 && abs(UV.x - 0.5) < (UV.y - 0.86) / 0.14 * 0.24) {
		discard;
	}
	vec3 col = cloth_color;
	float edge = abs(UV.x - 0.5);
	if ((UV.y > 0.64 && UV.y < 0.70) || (UV.y > 0.78 && UV.y < 0.81)) {
		col = stripe_color;
	}
	if (edge > 0.43 || UV.y < 0.05) {
		col = trim_color;
	}
	// Flame emblem centred at (0.5, 0.36).
	vec2 q = vec2((UV.x - 0.5) / 0.26, (UV.y - 0.36) / 0.22);
	float outer = 1.0 - step(0.0, flame(q, TIME));
	float inner = 1.0 - step(0.0, flame(q * vec2(1.7, 1.45) + vec2(0.0, -0.35), TIME + 0.7));
	vec3 glyph = mix(glyph_color * 0.85, vec3(1.0, 0.92, 0.6), inner);
	float g = max(outer, inner);
	col = mix(col, glyph, g);
	// Fold shading: darker near the fixed top edge, soft vertical folds.
	col *= mix(0.78, 1.05, smoothstep(0.0, 0.3, UV.y));
	col *= 0.93 + 0.07 * sin(UV.x * 18.0);
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = glyph * g * glyph_energy + rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
