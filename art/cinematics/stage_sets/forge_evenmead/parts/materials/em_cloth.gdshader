shader_type spatial;
// forge_evenmead cloth: banners, standards, pennants and tent flags (world-space meshes, VERTEX = world position).
//   COLOR.rgb sRGB field colour, UV.x = distance from the fixed edge 0..1 (0 = on the pole / crossbar: no motion),
//   UV.y = 0..1 across the cloth, UV2.x = per-flag phase, UV2.y = kingdom emblem (0 none, 0.125 shadow crescent,
//   0.375 ice diamond, 0.625 nature leaf, 0.875 fire flame): drawn per pixel with a trim border and a swallowtail
//   (crisp at any distance, no texture). Waves travel from the fixed edge to the free one; thin cloth glows when the
//   low sun is behind it.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert_wrap;

uniform vec2 wind_dir = vec2(-0.86, -0.5);
uniform float amp = 0.2;
uniform float freq = 2.4;
uniform float translucency = 0.45;

const vec3 MARK[4] = vec3[4](vec3(0.68, 0.52, 0.92), vec3(0.97, 0.98, 1.0), vec3(0.96, 0.80, 0.32), vec3(1.0, 0.76, 0.24));

varying float v_fold;

void vertex() {
	float w = UV.x;
	float ph = UV2.x * 6.2831;
	float wave = sin(TIME * freq - w * 7.0 + ph + UV.y * 1.3);
	float wave2 = sin(TIME * freq * 1.7 - w * 11.0 + ph * 1.3);
	vec3 side = normalize(NORMAL);
	VERTEX += side * (wave * 0.75 + wave2 * 0.25) * amp * w;
	VERTEX.xz += normalize(wind_dir) * amp * 0.35 * w * (0.6 + 0.4 * wave);
	v_fold = wave * 0.5 + 0.5;
}

float emblem(int k, vec2 p) {
	// p: (u - 0.5, (v - 0.42) * 0.62); returns coverage 0..1 (anti-aliased by the pixel footprint)
	float aa = max(fwidth(p.x), fwidth(p.y)) * 1.2 + 0.002;
	if (k == 0) {
		float a = 0.25 - length(p);
		float b = length(p - vec2(0.1, -0.05)) - 0.2;
		return smoothstep(-aa, aa, min(a, b));
	} else if (k == 1) {
		float q = abs(p.x) + abs(p.y) * 1.3;
		float ring = min(0.26 - q, q - 0.13);
		float bar = min(0.022 - abs(p.x), 0.19 - abs(p.y));
		return smoothstep(-aa, aa, max(ring, bar));
	} else if (k == 2) {
		vec2 r = vec2(p.x * 0.8 + p.y * 0.6, -p.x * 0.6 + p.y * 0.8);
		float e = 1.0 - sqrt(r.x * r.x / 0.02 + r.y * r.y / 0.075);
		float vein = abs(r.x) - 0.01;
		return smoothstep(-aa * 6.0, aa * 6.0, e) * smoothstep(-aa, aa, vein);
	}
	float y = p.y + 0.14;
	float w = 0.19 * sqrt(clamp(y / 0.3, 0.0, 1.0)) * (1.0 - clamp((y - 0.2) / 0.13, 0.0, 1.0));
	float d = w - abs(p.x + 0.035 * sin(y * 22.0));
	return smoothstep(-aa, aa, d) * step(0.0, y);
}

void fragment() {
	vec3 col = pow(COLOR.rgb, vec3(2.2));
	if (UV2.y > 0.01) {
		int k = int(UV2.y * 4.0);
		float u = UV.y;
		float v = UV.x;
		if (v > 0.86 && abs(u - 0.5) < (v - 0.86) * 2.6) {
			discard;
		}
		vec3 mark = pow(MARK[k], vec3(2.2));
		float aa = fwidth(u) + fwidth(v);
		float border = 1.0 - smoothstep(0.0, aa, min(min(u - 0.07, 0.93 - u), v - 0.05));
		float em = emblem(k, vec2(u - 0.5, (v - 0.42) * 0.62));
		col = mix(col, mark, max(em, border * 0.85));
	}
	float fold = 0.8 + 0.2 * v_fold;
	ALBEDO = col * fold;
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	BACKLIGHT = col * translucency;
}
