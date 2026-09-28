shader_type spatial;
// forge_evenmead ground skin: the painted meadow laid exactly on the World Forge terrain grid (same vertices, same
// diagonals; make_world.gd), pulled 0.12 % toward the camera so it always wins the depth test over the plain terrain
// under it. The mesh sits at the origin (VERTEX = world position).
//   COLOR.rgb  painted base colour (sRGB): lush / golden swathes, river banks, mud line, worn tracks, fields
//   UV.x       flower amount 0..1 (speckle density), UV.y flower palette 0..1 (daisy, buttercup, poppy, cornflower, clover)
//   UV2.x      grass amount (brush strokes + sun sheen; 0 on mud, tracks, ploughed earth), UV2.y furrow direction (rad / TAU)
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap;

uniform vec3 sun_to = vec3(0.966, 0.259, 0.0);
uniform vec3 sheen_color : source_color = vec3(1.0, 0.86, 0.5);
uniform float sheen = 0.22;

varying vec3 wp;
varying float vd;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash1(i), hash1(i + vec2(1.0, 0.0)), f.x), mix(hash1(i + vec2(0.0, 1.0)), hash1(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	return vnoise(p) * 0.5 + vnoise(p * 2.03 + 5.1) * 0.27 + vnoise(p * 4.1 - 2.3) * 0.15 + vnoise(p * 8.3 + 1.7) * 0.08;
}

vec3 flower_col(float pal, float h) {
	// palette strip: daisy white, buttercup yellow, poppy red, cornflower blue, clover pink (h picks a neighbour)
	float k = clamp(pal * 4.0 + (h - 0.5) * 0.9, 0.0, 4.0);
	if (k < 0.5) return vec3(0.98, 0.97, 0.9);
	if (k < 1.5) return vec3(1.0, 0.83, 0.12);
	if (k < 2.5) return vec3(0.9, 0.16, 0.08);
	if (k < 3.5) return vec3(0.32, 0.46, 0.95);
	return vec3(0.93, 0.55, 0.72);
}

void vertex() {
	wp = VERTEX;
	vec4 c = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vd = -c.z;
	c.xyz *= 0.9988;
	POSITION = PROJECTION_MATRIX * c;
}

void fragment() {
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	float grass = UV2.x;
	// painterly value breakup: soft blotches + short brush strokes along the slope
	float blot = fbm(wp.xz * 0.11);
	float fine = vnoise(vec2(wp.x * 1.3 + wp.z * 0.4, wp.z * 3.1 - wp.x * 0.2));
	vec3 col = base * (0.84 + 0.3 * blot) * mix(1.0, 0.9 + 0.2 * fine, grass);
	// ploughed / mown fields: furrows
	float fa = UV2.y * 6.2831;
	float fur = sin(dot(wp.xz, vec2(cos(fa), sin(fa))) * 3.2);
	col *= mix(1.0, 0.86 + 0.14 * fur, (1.0 - grass) * step(0.001, UV2.y));
	// flower speckle close by, a colour wash far away (no shimmer)
	float fl = UV.x;
	if (fl > 0.01) {
		vec2 cell = floor(wp.xz * 5.0);
		float h = hash1(cell);
		float h2 = hash1(cell + 17.3);
		vec2 f = fract(wp.xz * 5.0) - 0.5 - (vec2(h, h2) - 0.5) * 0.5;
		float dot_ = smoothstep(0.24, 0.12, length(f)) * step(h2, fl * 0.55);
		vec3 fc = pow(flower_col(UV.y, h), vec3(2.2));
		float near = smoothstep(55.0, 18.0, vd) * smoothstep(3.0, 9.0, vd);
		col = mix(col, fc, dot_ * near * 0.9);
		// far away: a warm wash only (the palette's blues / pinks, interpolated across the skin, turned the shaded
		// hillsides into grey-blue puddles from the crane shots)
		col = mix(col, pow(vec3(0.96, 0.86, 0.5), vec3(2.2)), fl * 0.12 * (1.0 - near));
	}
	ALBEDO = col;
	ROUGHNESS = 0.94;
	SPECULAR = 0.18;
	// sun sheen on the grass when looking toward the low sun (dew, blade tips)
	vec3 vdir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	float toward = pow(max(dot(vdir, normalize(sun_to)), 0.0), 3.0);
	EMISSION = pow(sheen_color, vec3(2.2)) * sheen * toward * grass * (0.6 + 0.4 * fine) * 0.35;
}
