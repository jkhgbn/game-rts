shader_type spatial;
// Mage Archer ground marks (ChampionVfx + ChampionMageArcherVfx, task 13b.V8). PlaneMesh 2 x 2 scaled to the radius
// (scale.x = `radius` metres), turned by the node basis. ONE material for every mark, the look picked per instance
// (`pattern`). Premultiplied alpha: `glow` adds light in `tint`, `cover` darkens toward `dark` (the Shadow court's
// marks eat the light of the ground a little: they read on grass, dirt and snow alike). Widths are in metres.
//   0 eclipse   Eclipse Volley telegraph (r 4): a bright rim with a turning rune band, the disc darkened with a violet
//               corona licking in from the rim, a ring closing on the centre over `warn` s, the eclipse glyph (a black
//               sun ringed by light and rays) in the middle
//   1 call      the call ritual: rings drawn in by a sweep, a turning rune band, a crescent and three stars, the ground
//               opened dark in the middle with glowing cracks
//   2 revive    the revive circle: a bright ring, three crescents turning inside, a flash when the pillar lands
//   3 grave     Grave Mark at the target's feet: a thin ring, four chevrons pointing in, turning slowly, a dark pool
//   4 rift      Sable Shaft scar: the plane is scaled (half width, 1, half length), +Z = the far end. A charred line
//               with a violet crack burning along it at the shaft's speed (`age` x `speed`), cooling from white-hot
//   5 volley    Eclipse Volley aftermath: pocked, darkened ground with glowing arrow holes flickering out
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 0.25, 2.2, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;      // seconds since the mark appeared (only its first second is sent)
instance uniform float seed = 0.0;
instance uniform float radius = 1.0;   // current radius (or half width) in metres (= node scale.x)
instance uniform float length_m = 1.0; // rift: half length in metres
instance uniform float warn = 0.75;    // eclipse: telegraph length (s); rift: unused
instance uniform float speed = 64.0;   // rift: how fast the burn runs along the line (m/s)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// A small angular rune (q in metres, centred, ~0.26 m tall): a stem plus a slash, a hook or a dot, picked by `id`.
float rune(vec2 q, float id) {
	float h = hash(vec2(id, id * 1.7 + 3.1));
	float h2 = hash(vec2(id * 2.3 + 1.0, 7.7));
	float stem = (1.0 - smoothstep(0.018, 0.034, abs(q.x - (h2 - 0.5) * 0.06))) * (1.0 - smoothstep(0.1, 0.125, abs(q.y)));
	float sl = h > 0.5 ? 0.9 : -0.9;
	float slash = (1.0 - smoothstep(0.018, 0.034, abs(q.x - q.y * sl))) * (1.0 - smoothstep(0.07, 0.095, abs(q.y - 0.02)));
	float hook = (1.0 - smoothstep(0.018, 0.034, abs(q.y - 0.1))) * (1.0 - smoothstep(0.04, 0.065, abs(q.x - 0.035)));
	float dot_ = 1.0 - smoothstep(0.022, 0.04, length(q - vec2(h > 0.3 ? 0.075 : -0.075, -0.06)));
	return max(max(stem, slash * step(0.2, h2)), max(hook * step(h2, 0.55), dot_ * step(h, 0.7)));
}

// A crescent (lit edge + faint body) of radius `a` at `c`, bitten by a disc shifted by `bite` (units of p).
vec2 crescent(vec2 p, vec2 c, float a, vec2 bite, float R) {
	float d1 = length(p - c) - a;
	float d2 = length(p - c - bite) - a * 0.86;
	float body = (1.0 - smoothstep(-0.01, 0.01, d1)) * smoothstep(-0.01, 0.01, d2);
	float edge = exp(-pow(d1 * R * 22.0, 2.0)) * smoothstep(-0.02, 0.02, d2)
			+ exp(-pow(d2 * R * 22.0, 2.0)) * (1.0 - smoothstep(-0.01, 0.01, d1)) * 0.6;
	return vec2(body, edge);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	int pat = int(pattern + 0.5);
	float r = length(p);
	if (pat != 4 && r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	float ang = atan(p.y, p.x);
	float au = ang / 6.2831853 + 0.5;
	float d = (1.0 - r) * R;   // metres in from the rim
	float rm = r * R;          // metres from the centre
	float glow = 0.0;
	float cover = 0.0;
	vec3 dark = vec3(0.025, 0.01, 0.045);
	vec3 hotc = vec3(0.0);     // extra white-hot light (not tinted)
	if (pat == 0) {
		float k = clamp(age / max(warn, 0.05), 0.0, 1.0);
		float snap = exp(-age * 6.0);
		float rim = exp(-d * d * 60.0);
		float rim2 = exp(-pow((d - 0.62) * 14.0, 2.0)) * 0.55;
		float n = max(12.0, floor(6.2831853 * (R - 0.35) / 0.42));
		float ca = au * n + TIME * 0.12 * (R / 4.0) + seed;
		float cell = fract(ca) - 0.5;
		vec2 q = vec2(cell * 6.2831853 * (R - 0.35) / n, d - 0.33);
		float runes = rune(q, floor(ca) + floor(seed * 7.0)) * step(abs(d - 0.33), 0.2);
		// The eclipse: the disc darkens as the volley comes; a violet corona licks in from the rim.
		float lick = vnoise(vec2(au * 40.0, d * 1.4 - TIME * 2.2 + seed)) * 0.65
				+ vnoise(vec2(au * 97.0 + 5.0, d * 3.1 - TIME * 3.3 + seed)) * 0.35;
		float corona = pow(lick, 2.2) * exp(-(d - 0.62) * 1.4) * step(0.62, d) * (0.55 + 0.9 * k);
		float inside = smoothstep(0.55, 0.9, d);
		cover = inside * (0.18 + 0.3 * k) + rim * 0.2;
		// The closing ring: from the rim to the centre over `warn` s.
		float rc = (1.0 - k) * (R - 0.62);
		float close = exp(-pow(rm - rc, 2.0) * 16.0) * step(age, warn + 0.05) * (0.6 + 1.2 * k);
		// Centre glyph: a black sun (r 0.55 m) ringed by light, turning rays that grow as the volley comes.
		float sun = 1.0 - smoothstep(0.5, 0.56, rm);
		float ring_c = exp(-pow((rm - 0.6) * 16.0, 2.0));
		float ray = pow(abs(cos(ang * 4.0 + TIME * 0.8)), 24.0) * exp(-(rm - 0.6) * 2.2) * step(0.58, rm)
				* step(rm, 0.6 + 0.5 + 0.9 * k);
		cover = max(cover, sun * 0.8);
		glow = rim * (1.4 + snap * 2.0) + rim2 + runes * (0.9 + 0.5 * k) + corona + close
				+ ring_c * (0.7 + 1.2 * k) + ray * (0.4 + 1.0 * k) + snap * (1.0 - r) * 0.5;
		hotc = vec3(1.0, 0.9, 1.1) * (ring_c * 0.4 * k + rim * snap * 0.6);
	} else if (pat == 1) {
		float draw = clamp(age / 0.55, 0.0, 1.0);                     // the rings are drawn in by a sweep
		float sweep = smoothstep(au - 0.03, au, draw * 1.03);
		float rim = exp(-d * d * 120.0);
		float ring2 = exp(-pow((d - 0.5) * 22.0, 2.0));
		float n = max(10.0, floor(6.2831853 * (R - 0.27) / 0.4));
		float ca = au * n - TIME * 0.1 + seed;
		vec2 q = vec2((fract(ca) - 0.5) * 6.2831853 * (R - 0.27) / n, d - 0.26);
		float runes = rune(q, floor(ca)) * step(abs(d - 0.26), 0.18);
		// Inner circle: ticks, then the crescent-and-stars sigil.
		float inner = exp(-pow((rm - R * 0.55) * 20.0, 2.0)) * 0.8;
		float tick = step(0.8, fract(au * 24.0 + TIME * 0.05)) * exp(-pow((rm - R * 0.55 - 0.1) * 18.0, 2.0));
		vec2 cr = crescent(p, vec2(0.0, 0.02), 0.34, vec2(0.11, -0.07), R);
		float stars = 0.0;
		for (int i = 0; i < 3; i++) {
			float a = 2.2 + float(i) * 0.55;
			vec2 sp = vec2(cos(a), sin(a)) * 0.2 + vec2(0.05, 0.0);
			vec2 sq = abs(p - sp) * R;
			stars += exp(-sq.x * sq.y * 900.0) * exp(-length(sq) * 9.0) * 1.4;
		}
		// The opened ground: dark, broken by glowing cracks radiating from the centre.
		float mott = vnoise(p * R * 2.4 + seed);
		float hole = 1.0 - smoothstep(0.22, 0.45 + (mott - 0.5) * 0.15, r);
		float crack = pow(abs(cos(ang * 3.5 + (vnoise(vec2(rm * 3.0, seed)) - 0.5) * 1.6)), 90.0)
				* smoothstep(0.08, 0.2, r) * (1.0 - smoothstep(0.35, 0.6, r));
		cover = hole * (0.55 + 0.25 * mott) * smoothstep(0.0, 0.4, age + 0.1) + rim * 0.2;
		glow = (rim * 1.8 + ring2 * 0.9 + runes * 1.1 + inner + tick * 0.7) * sweep
				+ (cr.y * 1.6 + cr.x * 0.25 + stars) * smoothstep(0.2, 0.6, age)
				+ crack * 1.2 + exp(-rm * 1.5) * 0.25 + exp(-age * 4.0) * (1.0 - r) * 0.8;
		hotc = vec3(1.0, 0.9, 1.1) * cr.y * 0.3;
	} else if (pat == 2) {
		float flash = exp(-age * 3.5);
		float rim = exp(-d * d * 90.0);
		float n = 3.0;
		float ca = au * n + TIME * 0.35 + seed;
		float cid = fract(ca) - 0.5;
		// Three crescents on a ring at 60 % of the radius.
		vec2 c = vec2(cos(ang - cid * 6.2831853 / n), sin(ang - cid * 6.2831853 / n)) * 0.6;
		vec2 cr = crescent(p, c, 0.17, normalize(c) * 0.06, R);
		float inner = exp(-pow((rm - R * 0.35) * 18.0, 2.0)) * 0.6;
		float fill = (1.0 - r) * (0.25 + flash * 1.2);
		glow = rim * (1.6 + flash * 2.0) + cr.y * 1.5 + cr.x * 0.3 + inner + fill;
		cover = rim * 0.15 + (1.0 - smoothstep(0.3, 1.0, r)) * 0.25;
		hotc = vec3(1.0, 0.95, 1.1) * flash * (1.0 - r) * 0.9;
	} else if (pat == 3) {
		float pulse = 0.8 + 0.2 * sin(TIME * 3.0 + seed);
		float rim = exp(-d * d * 260.0);
		float cell = fract(au * 4.0 - TIME * 0.08 + seed) - 0.5;
		vec2 q = vec2(cell * 6.2831853 * R / 4.0, d);
		// A chevron (a "v" pointing at the centre) just inside the rim.
		float chev = (1.0 - smoothstep(0.02, 0.045, abs(q.y - 0.09 - abs(q.x) * 0.9))) * step(abs(q.x), 0.16);
		float pool = (1.0 - smoothstep(0.2, 0.95, r));
		glow = rim * 1.2 * pulse + chev * 1.3 * pulse + pool * 0.08;
		cover = pool * 0.32 + rim * 0.1;
	} else if (pat == 4) {
		if (abs(p.x) > 1.0 || abs(p.y) > 1.0) {
			discard;
		}
		float t = (p.y + 1.0) * 0.5;                   // 0 the bow end, 1 the far end
		float L = max(length_m, 0.1);
		float along = t * L * 2.0;                     // metres from the bow end
		float burned = age * speed;                    // metres the shaft has passed
		float lit = smoothstep(0.0, 0.6, burned - along);
		float fresh = exp(-max(burned - along, 0.0) / (speed * 0.35));   // white-hot just behind the head
		float taper = sqrt(clamp((1.0 - t) / 0.06, 0.0, 1.0) * clamp(t / 0.04, 0.0, 1.0));
		float xm = abs(p.x) * R;                        // metres across
		float wob = (vnoise(vec2(along * 1.3, seed)) - 0.5) * 0.18 + (vnoise(vec2(along * 4.1, seed + 3.0)) - 0.5) * 0.06;
		float crack = exp(-pow((p.x * R - wob) / 0.035, 2.0)) * taper;
		float halo = exp(-pow(xm / (R * 0.45), 2.0)) * taper;
		float embers = step(0.86, hash(floor(vec2(p.x * R * 8.0, along * 5.0)) + seed))
				* (0.5 + 0.5 * sin(TIME * 9.0 + hash(floor(vec2(along * 5.0, seed))) * 40.0)) * halo;
		float char_ = (1.0 - smoothstep(R * 0.4, R, xm)) * taper * (0.75 + 0.25 * vnoise(vec2(p.x * 6.0, along * 0.9) + seed));
		// Mostly a charred scar (it must not read as a second beam from above): a thin dim crack, embers, and a short
		// burn right behind the passing head.
		glow = (crack * (0.35 + 1.1 * fresh) + halo * (0.05 + 0.35 * fresh) + embers * 0.7) * lit;
		cover = char_ * 0.6 * lit;
		hotc = vec3(1.2, 1.0, 1.3) * crack * fresh * lit * 0.25;
	} else {
		float mott = vnoise(p * R * 1.1 + seed * 4.0);
		float scorch = 1.0 - smoothstep(0.6, 1.0, r + (mott - 0.5) * 0.3);
		vec2 g = p * R / 0.62;
		vec2 id = floor(g);
		vec2 f = fract(g) - 0.5;
		float hsh = hash(id + seed);
		vec2 jit = vec2(hash(id + 1.3 + seed), hash(id + 7.1 + seed)) - 0.5;
		float hole_d = length(f - jit * 0.5);
		float has = step(0.4, hsh) * scorch;
		float hole = (1.0 - smoothstep(0.08, 0.16, hole_d)) * has;
		float ember = exp(-hole_d * hole_d * 90.0) * has * (0.55 + 0.45 * sin(TIME * 6.0 + hsh * 30.0));
		cover = scorch * (0.22 + 0.2 * mott) + hole * 0.45;
		glow = ember * 1.4 + scorch * 0.05;
	}
	vec3 emit = tint.rgb * tint.a * glow + hotc;
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * a;
	ALPHA = a;
}
