// banner.gdshader - waving team cloth with a stripe, a glyph and a swallow-tail. art-keep.md 5.2.
// Uniforms: cloth_color, stripe_color, glyph_color, glyph_energy, glyph_shape (0 flame, 1 diamond),
// amplitude (m), speed, rim_color, rim_strength; instance uniform phase (desync the banners).
// Mesh: a vertical PlaneMesh (orientation Z) with UV.y = 0 at the top (fixed) edge.
// G3b (docs/art/g3b_materials.md): unit_cloth (0 = the buildings' banners, unchanged; 1 = unit capes / pennons, set in
// their materials): gusts + a secondary flutter, fold normals, a woven thread tint, softer wrapped light and a velvet
// sheen. No new instance uniform here: `phase` must stay this shader's only one (implicit slot 0, kit/README A.16).
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
uniform float unit_cloth : hint_range(0.0, 1.0) = 0.0;
instance uniform float phase = 0.0;

void vertex() {
	float w = UV.y;
	float gust = 1.0 + unit_cloth * 0.35 * sin(TIME * 0.7 + phase * 1.3) * sin(TIME * 0.23 + phase);
	float a1 = TIME * speed + UV.y * 6.0 + phase;
	VERTEX.z += sin(a1) * amplitude * w * gust;
	VERTEX.x += sin(TIME * speed * 0.37 + UV.y * 2.0 + phase) * amplitude * 0.4 * w;
	if (unit_cloth > 0.0) {
		// Flutter on the free edge, and fold normals from the main wave's slope.
		float a2 = TIME * speed * 2.7 + UV.y * 13.0 + UV.x * 5.0 + phase * 2.0;
		VERTEX.z += sin(a2) * amplitude * 0.16 * w * w * unit_cloth;
		float slope = cos(a1) * 6.0 * amplitude * w * gust + cos(a2) * 13.0 * amplitude * 0.16 * w * w;
		NORMAL = normalize(NORMAL + vec3(0.0, slope * 0.8 * unit_cloth, 0.0));
	}
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
	if (unit_cloth > 0.0) {
		// Woven threads (fade before they shimmer) and dye pooling toward the hem.
		vec2 th = UV * vec2(70.0, 110.0);
		float px = max(fwidth(th.x), fwidth(th.y));
		float weave = sin(th.x * 6.2831853) * sin(th.y * 6.2831853) * (1.0 - smoothstep(0.25, 0.5, px));
		col *= 1.0 + weave * 0.06 * unit_cloth;
		col = mix(col, pow(col, vec3(1.3)), smoothstep(0.55, 1.0, UV.y) * 0.4 * unit_cloth);
	}
	ALBEDO = col;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = glyph_color * glyph * glyph_energy + rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	ramp = mix(ramp, smoothstep(0.22, 0.75, d), 0.6 * unit_cloth);
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (unit_cloth > 0.0) {
		float ndv = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
		DIFFUSE_LIGHT += pow(1.0 - ndv, 3.0) * smoothstep(0.5, 0.7, d) * 0.3 * unit_cloth * ATTENUATION * LIGHT_COLOR / PI;
	}
}
