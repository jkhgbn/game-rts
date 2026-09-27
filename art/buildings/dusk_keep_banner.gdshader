// Dusk Keep banner cloth (art-keep.md 5.2, Dusk column). UV.y 0 = top (fixed edge).
shader_type spatial;
render_mode cull_disabled;

uniform vec3 cloth_color : source_color = vec3(0.25, 0.12, 0.38);
uniform vec3 stripe_color : source_color = vec3(0.55, 0.52, 0.66);
uniform vec3 glyph_color : source_color = vec3(0.70, 0.30, 1.00);
uniform float amplitude = 0.10;
uniform float speed = 1.8;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
instance uniform float phase = 0.0;

void vertex() {
	float w = UV.y;
	VERTEX.z += sin(TIME * speed + UV.y * 6.0 + phase) * amplitude * w;
	VERTEX.x += sin(TIME * speed * 0.37 + UV.y * 2.0) * amplitude * 0.4 * w;
}

void fragment() {
	if (UV.y > 0.88 && abs(UV.x - 0.5) < 0.12) {
		discard;
	}
	vec3 col = cloth_color;
	if ((UV.y > 0.52 && UV.y < 0.62) || UV.y > 0.92) {
		col = stripe_color;
	}
	float glyph = step(abs(UV.x - 0.5) + abs(UV.y - 0.32) * 0.5, 0.14);
	col = mix(col, glyph_color, glyph);
	ALBEDO = col * mix(0.8, 1.05, 1.0 - UV.y);
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = glyph_color * glyph * 0.6 + rim * rim_color * rim_strength;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
