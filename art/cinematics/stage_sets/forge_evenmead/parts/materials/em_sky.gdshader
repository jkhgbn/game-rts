// forge_evenmead golden-hour sky (preset_golden, make_light.gd): a clear blue top over a peach horizon, the low sun in
// the east with a warm glow, a pink-lavender counter-glow in the west, and painted fair-weather clouds: soft cumulus
// banks low round the horizon (sun-lit gold edges, lavender bellies), a few high cirrus streaks catching the light.
// Clouds live on a flat dome (uv = EYEDIR.xz / EYEDIR.y), so they shrink and crowd toward the horizon like real ones.
// Static (no TIME): Godot bakes the radiance once.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.19, 0.39, 0.78);
uniform vec3 mid_color : source_color = vec3(0.45, 0.62, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.98, 0.83, 0.66);
uniform vec3 sun_glow_color : source_color = vec3(1.0, 0.74, 0.46);
uniform vec3 anti_glow_color : source_color = vec3(0.88, 0.72, 0.78);
uniform vec3 ground_horizon_color : source_color = vec3(0.86, 0.76, 0.62);
uniform vec3 ground_color : source_color = vec3(0.36, 0.40, 0.30);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.93, 0.82);
uniform vec3 cloud_gold : source_color = vec3(1.0, 0.8, 0.52);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.62, 0.78);
uniform float cloud_cover = 0.5;
uniform float energy = 1.0;

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
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 5; k++) {
		s += vnoise(p) * a;
		p = p * 2.03 + vec2(1.7, -3.1);
		a *= 0.5;
	}
	return s;
}
// cumulus density on the cloud plane (0..1)
float cumulus(vec2 q) {
	float base = fbm(q * 0.55);
	float detail = fbm(q * 1.9 + 7.0);
	float d = base * 0.75 + detail * 0.35;
	return smoothstep(0.62 - cloud_cover * 0.18, 0.8 - cloud_cover * 0.12, d);
}

void sky() {
	vec3 e = EYEDIR;
	float y = e.y;
	vec3 sun = LIGHT0_ENABLED ? LIGHT0_DIRECTION : normalize(vec3(0.966, 0.259, 0.0));
	vec2 sun_h = normalize(sun.xz + vec2(1e-4));
	float face = dot(normalize(e.xz + vec2(1e-4)), sun_h);   // +1 toward the sun, -1 away
	float s = max(dot(e, sun), 0.0);
	vec3 col;
	if (y >= -0.02) {
		float yy = max(y, 0.0);
		// the gradient: peach horizon -> soft blue -> deep top
		float t1 = smoothstep(0.0, 0.32, pow(yy, 0.85));
		float t2 = smoothstep(0.18, 0.95, yy);
		vec3 hor = horizon_color;
		hor = mix(hor, anti_glow_color, smoothstep(0.1, -0.9, face) * 0.55);
		col = mix(hor, mid_color, t1);
		col = mix(col, zenith_color, t2);
		// the low sun: a wide warm glow on its side of the sky, a hot halo and the disc
		col = mix(col, sun_glow_color, pow(s, 4.0) * 0.55 * (1.0 - t2));
		col += sun_glow_color * pow(s, 32.0) * 0.5;
		col += vec3(1.0, 0.92, 0.75) * smoothstep(0.9986, 0.9993, s) * 3.0;
		// clouds on the dome
		float hy = max(yy, 0.035);
		vec2 q = e.xz / (hy + 0.06) * 1.2;
		// a band of cumulus low round the horizon, thinning overhead
		float band = smoothstep(0.02, 0.07, yy) * (1.0 - smoothstep(0.26, 0.55, yy));
		float d = cumulus(q + vec2(3.0, 11.0)) * band;
		// light: density toward the sun is lower on the lit rim
		vec2 toward = sun_h * 0.22;
		float d_sun = cumulus(q + vec2(3.0, 11.0) + toward) * band;
		float lit = clamp(0.55 + (d - d_sun) * 1.8, 0.0, 1.0);
		lit = mix(lit, 1.0, 0.25 * (1.0 - d));
		vec3 cc = mix(cloud_shade, cloud_lit, lit);
		cc = mix(cc, cloud_gold, lit * (0.35 + 0.5 * pow(max(face, 0.0), 2.0)));
		// silver lining round the clouds near the sun
		cc += sun_glow_color * pow(s, 6.0) * (1.0 - d) * 0.9;
		// far clouds melt into the horizon haze
		float haze = 1.0 - smoothstep(0.02, 0.16, yy);
		cc = mix(cc, hor, haze * 0.65);
		col = mix(col, cc, clamp(d * 1.1, 0.0, 0.96));
		// high cirrus: long thin streaks catching the light
		vec2 qc = e.xz / (hy + 0.12) * vec2(0.9, 3.2);
		float ci = smoothstep(0.58, 0.82, fbm(qc * 0.6 + vec2(-4.0, 2.0))) * smoothstep(0.08, 0.3, yy) * (1.0 - smoothstep(0.75, 1.0, yy));
		ci *= 0.6 + 0.4 * vnoise(qc * 4.0);
		col = mix(col, mix(vec3(1.0, 0.9, 0.84), cloud_gold, pow(max(face, 0.0), 1.5)), ci * 0.45 * (1.0 - d));
		// below the horizon line (seen past the land's edge): the warm haze
		col = mix(col, ground_horizon_color, smoothstep(0.0, -0.02, y));
	} else {
		float t = smoothstep(0.0, 0.3, -y);
		col = mix(ground_horizon_color, ground_color, t);
	}
	COLOR = col * energy;
}
