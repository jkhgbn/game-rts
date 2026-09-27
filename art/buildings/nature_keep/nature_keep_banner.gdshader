// nature_keep_banner.gdshader - the Heartwood's banners (task A2.5). Same look rules as art/shaders/banner.gdshader
// (art-keep.md 5.2) for MERGED banner meshes: the cloth waves along its own NORMAL, the per-banner phase comes from
// UV2.x, UV is 0..1 per banner (y = 0 at the fixed top edge). Leaf-shaped: the lower quarter narrows to a point;
// bark trim, a cloth-shadow band, a leaf midrib and the Heartwood emblem (a round crown on a trunk with roots,
// the seed-heart glowing in the middle).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 cloth_color : source_color = vec3(0.35, 0.70, 0.25);
uniform vec3 stripe_color : source_color = vec3(0.15, 0.40, 0.15);
uniform vec3 trim_color : source_color = vec3(0.58, 0.44, 0.25);
uniform vec3 glyph_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float glyph_energy = 0.9;
uniform float amplitude = 0.09;
uniform float speed = 1.7;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	float w = UV.y;
	float ph = UV2.x;
	float wave = sin(TIME * speed + UV.y * 4.5 + ph) * amplitude * w
		+ sin(TIME * speed * 1.6 + UV.x * 3.0 + ph * 2.0) * amplitude * 0.3 * w;
	VERTEX += NORMAL * wave;
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	float x = UV.x - 0.5;
	float y = UV.y;
	// Leaf point: from 72 % down the cloth narrows to the tip.
	float half_w = 0.5;
	if (y > 0.72) {
		float k = (y - 0.72) / 0.28;
		half_w = 0.5 * sqrt(max(1.0 - k * k, 0.0));
	}
	if (abs(x) > half_w) {
		discard;
	}
	float edge_d = half_w - abs(x);
	vec3 col = cloth_color;
	// Cloth-shadow band and the midrib running into the point.
	if (y > 0.60 && y < 0.66) {
		col = stripe_color;
	}
	float rib = (1.0 - smoothstep(0.012, 0.025, abs(x))) * smoothstep(0.62, 0.7, y);
	col = mix(col, stripe_color, rib);
	for (int i = 0; i < 3; i++) {
		float yy = 0.72 + float(i) * 0.075;
		float vein = 1.0 - smoothstep(0.01, 0.022, abs(y - yy - abs(x) * 0.55));
		col = mix(col, stripe_color, vein * step(0.03, abs(x)) * step(abs(x), half_w - 0.04) * 0.8);
	}
	// Bark trim along the sides, the top hem and the point.
	if (edge_d < 0.055 || y < 0.05) {
		col = trim_color * (0.85 + 0.15 * sin(y * 60.0));
	}
	// Emblem: round crown ring, trunk, two roots, glowing seed in the crown.
	vec2 p = vec2(x * 1.0, y - 0.3);
	float ring = abs(length(p) - 0.17);
	float g = 1.0 - smoothstep(0.022, 0.034, ring);
	float trunk = seg(vec2(x, y), vec2(0.0, 0.47), vec2(0.0, 0.57));
	trunk = min(trunk, seg(vec2(x, y), vec2(0.0, 0.55), vec2(-0.12, 0.6)));
	trunk = min(trunk, seg(vec2(x, y), vec2(0.0, 0.55), vec2(0.12, 0.6)));
	trunk = min(trunk, seg(vec2(x, y), vec2(0.0, 0.47), vec2(0.0, 0.34)));
	trunk = min(trunk, seg(vec2(x, y), vec2(0.0, 0.38), vec2(-0.08, 0.28)));
	trunk = min(trunk, seg(vec2(x, y), vec2(0.0, 0.38), vec2(0.08, 0.28)));
	g = max(g, 1.0 - smoothstep(0.018, 0.03, trunk));
	float seed = 1.0 - smoothstep(0.035, 0.05, length(p - vec2(0.0, -0.03)));
	vec3 glyph = mix(glyph_color * 0.85, vec3(1.0, 1.0, 0.8), seed);
	float gm = max(g, seed);
	col = mix(col, glyph, gm);
	// Fold shading: darker near the fixed top edge, soft vertical folds; soot when damaged.
	col *= mix(0.78, 1.05, smoothstep(0.0, 0.3, y));
	col *= 0.93 + 0.07 * sin(UV.x * 18.0);
	col *= 1.0 - damage * 0.3;
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = glyph * gm * glyph_energy * (1.0 + seed * 1.5) + rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
