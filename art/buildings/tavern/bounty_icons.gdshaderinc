// bounty_icons.gdshaderinc - the four bounty kind icons as signed distances (task 9.V6).
// icon_sd(kind, p): p in icon space (the icon fits in a circle of radius ~0.8), y up; < 0 = inside the icon.
//   0 Hunt    two crossed blades (guard, grip, pommel)
//   1 Explore an open eye (almond outline + iris with a highlight)
//   2 Guard   a heater shield with an inset groove
//   3 Escort  two interlocked rings
// Shared by bounty_coin.gdshader (engraved on both faces) and bounty_pennant.gdshader (painted on the cloth).

float bi_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

float bi_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

vec2 bi_rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float bi_sword(vec2 q) {
	// Blade tapering to a point at the top, crossguard, grip, pommel. Along +y.
	float taper = mix(0.085, 0.015, smoothstep(0.1, 0.72, q.y));
	float blade = bi_segment(q, vec2(0.0, -0.18), vec2(0.0, 0.72)) - taper;
	float guard = bi_box(q - vec2(0.0, -0.22), vec2(0.22, 0.05));
	float grip = bi_box(q - vec2(0.0, -0.4), vec2(0.045, 0.14));
	float pommel = length(q - vec2(0.0, -0.58)) - 0.075;
	return min(min(blade, guard), min(grip, pommel));
}

float bi_hunt(vec2 p) {
	return min(bi_sword(bi_rot(p, 0.72)), bi_sword(bi_rot(p, -0.72)));
}

float bi_explore(vec2 p) {
	// Almond = intersection of two circles, drawn as an outline; iris disc with a highlight hole.
	float lens = max(length(p - vec2(0.0, -0.52)) - 0.86, length(p - vec2(0.0, 0.52)) - 0.86);
	float outline = abs(lens) - 0.065;
	float iris = length(p) - 0.24;
	float glint = length(p - vec2(0.08, 0.09)) - 0.065;
	iris = max(iris, -glint);
	return min(outline, iris);
}

float bi_guard(vec2 p) {
	p -= vec2(0.0, 0.1);
	p *= 1.08;
	float top = bi_box(p - vec2(0.0, 0.26), vec2(0.46, 0.28));
	float bot = max(max(length(p - vec2(0.46, -0.02)) - 0.92, length(p - vec2(-0.46, -0.02)) - 0.92), p.y + 0.02);
	float shield = min(top, bot);
	float groove = abs(shield + 0.13) - 0.035;
	return max(shield, -groove);
}

float bi_escort(vec2 p) {
	float r1 = abs(length(p - vec2(-0.24, 0.0)) - 0.34) - 0.075;
	float r2 = abs(length(p - vec2(0.24, 0.0)) - 0.34) - 0.075;
	// Interlock: ring 2 passes over ring 1 at the top, under it at the bottom.
	float g2 = length(p - vec2(0.24, 0.0)) - 0.34;
	float g1 = length(p - vec2(-0.24, 0.0)) - 0.34;
	float cut1 = abs(g2) - 0.13;
	float cut2 = abs(g1) - 0.13;
	if (p.y > 0.0) {
		r1 = max(r1, -cut1);
	} else {
		r2 = max(r2, -cut2);
	}
	return min(r1, r2);
}

float icon_sd(int kind, vec2 p) {
	if (kind == 0) {
		return bi_hunt(p);
	} else if (kind == 1) {
		return bi_explore(p);
	} else if (kind == 2) {
		return bi_guard(p);
	}
	return bi_escort(p);
}

// Anti-aliased coverage of the icon (1 inside).
float icon_mask(int kind, vec2 p) {
	float d = icon_sd(kind, p);
	float aa = max(fwidth(d), 0.002);
	return 1.0 - smoothstep(-aa, aa, d);
}
