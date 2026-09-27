// banner.gdshader - waving team cloth with a stripe, a glyph and a swallow-tail. art-keep.md 5.2.
// Uniforms: cloth_color, stripe_color, glyph_color, glyph_energy, glyph_shape (0 flame, 1 diamond),
// amplitude (m), speed, rim_color, rim_strength; instance uniform phase (desync the banners).
// Mesh: a vertical PlaneMesh (orientation Z) with UV.y = 0 at the top (fixed) edge.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 cloth_color : source_color = vec3(0.85, 0.30, 0.12);
uniform vec3 stripe_color : source_color = vec3(0.55, 0.08, 0.05);
uniform vec3 glyph_color : source_color = vec3(1.0, 0.75, 0.30);
uniform float glyph_energy = 0.6;
uniform int glyph_shape = 0;
uniform float amplitude = 0.14;
uniform float speed = 2.6;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
instance uniform float phase = 0.0;

void vertex() {
	float w = UV.y;
	VERTEX.z += sin(TIME * speed + UV.y * 6.0 + phase) * amplitude * w;
	VERTEX.x += sin(TIME * speed * 0.37 + UV.y * 2.0 + phase) * amplitude * 0.4 * w;
}

void fragment() {
	if (UV.y > 0.88 && abs(UV.x - 0.5) < 0.12 * (UV.y - 0.88) / 0.12 + 0.0001) {
		discard;
	}
	vec3 col = cloth_color;
	bool stripe = (UV.y > 0.52 && UV.y < 0.62) || UV.y > 0.80;
	if (stripe) {
		col = stripe_color;
	}
	float glyph = 0.0;
	if (glyph_shape == 0) {
		glyph = (UV.y > 0.18 && UV.y < 0.46 && abs(UV.x - 0.5) < (UV.y - 0.18) * 0.9) ? 1.0 : 0.0;
	} else {
		glyph = (abs(UV.x - 0.5) + abs(UV.y - 0.32) * 0.5 < 0.14) ? 1.0 : 0.0;
	}
	col = mix(col, glyph_color, glyph);
	// Darker near the fixed top edge (fold shadow), lighter lower down.
	col *= mix(0.8, 1.05, smoothstep(0.0, 0.3, UV.y));
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = glyph_color * glyph * glyph_energy + rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
