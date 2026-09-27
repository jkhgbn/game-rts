shader_type spatial;
// Champion class-skill ground marks (ChampionVfx, task 11.V6). PlaneMesh 2 x 2 scaled to the radius (scale.x =
// `radius` metres), turned by the node basis. ONE material for every mark: the look is picked per instance (`pattern`).
// Premultiplied alpha: `glow` adds light in `tint`, `cover` darkens (cracks, dust, scorch). Widths are in metres.
//   0 crack          Crushing Blow: radial cracks with glowing seams and a crater, flashing on impact
//   1 whirl          Whirlwind: sword arcs racing round a r 3 band
//   2 star target    Starfall: dashed warning rim + a ring closing on the centre over 1 s (`age`)
//   3 class ring     class_chosen: bright rim, a turning rune band, a flash
//   4 thrust line    Skewer / Lunge scuff: the plane is scaled (half width, 1, half length); +Z = the tip.
//                    `radius` = half width, `length_m` = half length
//   5 crescent       Cleave: a horizontal blade swoosh sweeping 240 degrees round +Z in 0.14 s
//   6 sigil          Slipstep: a small arcane circle with turning runes
//   7 hobble         Hobbling Javelin: a scuffed dusty ring at the feet with a dim glint
//   8 star burn      Starfall aftermath: scorched ground with glowing star cracks
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(0.6, 1.8, 1.5, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;      // seconds since the mark appeared (only its first second is sent)
instance uniform float seed = 0.0;
instance uniform float radius = 1.0;   // current radius (or half width) in metres (= node scale.x)
instance uniform float length_m = 1.0; // thrust line: half length in metres

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

// Radial cracks: `n` rays with jittered paths, each of its own length. Returns (body 0-1, glow seam).
vec2 cracks(vec2 p, float r, float au, float R, float n, float len_min, float w0, float s) {
	float a = au * n + s;
	float id = floor(a);
	float jit = (vnoise(vec2(r * R * 2.6, id * 3.7 + s)) - 0.5) * 0.55;
	float cell = fract(a + jit * (0.3 + r)) - 0.5;
	float w = abs(cell) * 6.2831853 * r * R / n;              // metres off the ray
	float len = len_min + (1.0 - len_min) * hash(vec2(id, s));
	float width = w0 * (1.0 - r / max(len, 0.01)) + 0.012;
	float on = (1.0 - smoothstep(width * 0.55, width, w)) * step(r, len) * smoothstep(0.08, 0.2, r);
	float seam = exp(-w * w / (width * width) * 7.0) * step(r, len) * (1.0 - r / max(len, 0.01))
			* smoothstep(0.08, 0.2, r);
	return vec2(on, seam);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	int pat = int(pattern + 0.5);
	float r = length(p);
	if (pat != 4 && r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	float au = atan(p.y, p.x) / 6.2831853 + 0.5;
	float d = (1.0 - r) * R;   // metres in from the rim
	float glow = 0.0;
	float cover = 0.0;
	vec3 dark = vec3(0.0);
	if (pat == 0) {
		float flash = exp(-age * 3.2);
		vec2 c1 = cracks(p, r, au, R, 7.0, 0.6, 0.26, seed);
		vec2 c2 = cracks(p, r, au, R, 13.0, 0.3, 0.12, seed + 5.3);
		float body = max(c1.x, c2.x * 0.8);
		float crater = 1.0 - smoothstep(0.16, 0.26, r);
		float lip = exp(-pow((r - 0.24) * R * 7.0, 2.0));
		float mott = vnoise(p * R * 2.2 + seed * 3.0);
		float scorch = (1.0 - smoothstep(0.25, 0.75, r)) * 0.3;
		cover = max(max(body * 0.95, crater * (0.6 + 0.2 * mott)), scorch) + lip * 0.15;
		dark = vec3(0.06, 0.045, 0.035) * (0.8 + 0.4 * mott);
		// Seams: thin hot lines inside the dark cracks, cooling from white-hot to the tint.
		glow = (c1.y * 1.0 + c2.y * 0.5) * (0.3 + 1.8 * flash) + crater * flash * 0.8 + lip * (0.15 + 0.6 * flash);
		glow += exp(-d * d * 18.0) * flash * 0.4;   // dust ring flash at the edge
	} else if (pat == 1) {
		float band = exp(-pow(d - 0.45, 2.0) * 7.0);
		float s = fract(au * 3.0 - TIME * 2.4 + seed);
		float arc = smoothstep(0.0, 0.025, s) * pow(1.0 - s, 3.0);
		float s2 = fract(au * 5.0 - TIME * 3.1 + seed * 1.7);
		float arc2 = smoothstep(0.0, 0.03, s2) * pow(1.0 - s2, 5.0) * exp(-pow(d - 1.1, 2.0) * 6.0);
		float rim = exp(-d * d * 50.0);
		float wash = exp(-d * 0.9) * 0.08;
		glow = band * arc * 2.2 + arc2 * 0.9 + rim * (0.5 + arc * 1.2) + wash;
		cover = band * arc * 0.12;
	} else if (pat == 2) {
		float k = clamp(age / 1.0, 0.0, 1.0);
		float rc = 1.0 - k;
		float dash = step(0.35, fract(au * floor(6.2831853 * R / 0.7) - TIME * 0.25));
		float rim = exp(-d * d * 45.0) * (0.55 + 0.45 * dash);
		float close = exp(-pow((r - rc) * R, 2.0) * 22.0) * (0.6 + 0.9 * k);
		float fill = (0.06 + 0.22 * k * k) * smoothstep(1.0, 0.2, r) * (0.8 + 0.2 * sin(TIME * 18.0));
		// A four-point star glyph in the centre, growing brighter as the star falls.
		vec2 q = abs(p) * R;
		float star = exp(-q.x * q.y * 40.0) * exp(-length(q) * 1.6) * (0.3 + 1.2 * k);
		glow = rim * 1.3 + close * 1.4 + fill + star;
		cover = rim * 0.25 + fill * 0.6;
		dark = vec3(0.03, 0.04, 0.09);
	} else if (pat == 3) {
		float flash = exp(-age * 4.0);
		float rim = exp(-d * d * 60.0);
		float inner = exp(-pow((d - 0.3) * 9.0, 2.0)) * 0.6;
		float n = max(8.0, floor(6.2831853 * R / 0.35));
		float cell = fract(au * n + TIME * 0.12 + seed) - 0.5;
		float tick = (1.0 - smoothstep(0.12, 0.22, abs(cell))) * exp(-pow((d - 0.15) * 22.0, 2.0));
		float fill = exp(-d * 2.2) * 0.22 + (1.0 - r) * flash * 0.3;
		glow = rim * (1.6 + flash * 1.5) + inner + tick * 1.1 + fill;
		cover = rim * 0.15;
	} else if (pat == 4) {
		float t = (p.y + 1.0) * 0.5;                   // 0 caster end, 1 the tip
		float L = max(length_m, 0.1);
		float taper = clamp((1.0 - t) / 0.18, 0.0, 1.0) * clamp(t / 0.06, 0.0, 1.0);
		taper = sqrt(taper);
		float xm = abs(p.x) * R;                        // metres across
		float half_w = R * 0.85 * taper + 0.001;
		float flash = exp(-age * 4.5);
		float core = exp(-xm * xm / (0.012 + half_w * half_w * 0.04));
		float wide = exp(-xm * xm / (half_w * half_w * 0.35)) * taper;
		float streaks = smoothstep(0.55, 0.9, vnoise(vec2(p.x * 9.0, p.y * L * 0.6 - age * 14.0 + seed)));
		float scuff = (1.0 - smoothstep(half_w * 0.5, half_w, xm)) * taper;
		glow = core * taper * (0.5 + 2.4 * flash) + wide * (0.25 + streaks * 0.8) * (0.4 + flash);
		cover = scuff * 0.3 * (0.7 + 0.3 * vnoise(p * vec2(4.0, L * 2.0) + seed));
		dark = vec3(0.06, 0.05, 0.04);
		if (abs(p.x) > 1.0 || abs(p.y) > 1.0) {
			discard;
		}
	} else if (pat == 5) {
		// Blade swoosh round +Z (p.y = local z): phi 0 at +Z, the head sweeps -120 -> +120 degrees.
		float phi = degrees(atan(p.x, p.y));
		float head = mix(-120.0, 125.0, clamp(age / 0.14, 0.0, 1.0));
		float behind = head - phi;
		float trail = step(0.0, behind) * pow(clamp(1.0 - behind / 240.0, 0.0, 1.0), 1.6) * step(abs(phi), 122.0);
		float edge = exp(-d * d * 30.0);
		float body = smoothstep(0.42, 0.75, r) * (0.3 + 0.7 * r * r);
		float lines = 0.7 + 0.3 * sin(r * R * 18.0 + phi * 0.05);
		float tip = exp(-pow(behind / 12.0, 2.0)) * smoothstep(0.5, 0.9, r);
		glow = trail * (edge * 2.2 + body * 0.9 * lines) + tip * 1.4;
		cover = trail * body * 0.1;
	} else if (pat == 6) {
		float flash = exp(-age * 5.0);
		float rim = exp(-d * d * 90.0);
		float r2 = exp(-pow((r - 0.68) * R * 11.0, 2.0)) * 0.7;
		float n = 6.0;
		float cell = fract(au * n - TIME * 0.35 + seed) - 0.5;
		vec2 q = vec2(cell * 6.2831853 * 0.84 * R / n, (r - 0.84) * R);
		float rune = (1.0 - smoothstep(0.03, 0.06, abs(q.y))) * (1.0 - smoothstep(0.05, 0.1, abs(q.x)))
				+ (1.0 - smoothstep(0.035, 0.07, length(q - vec2(0.13, 0.0)))) * 0.8;
		// A six-point star drawn with three lines through the centre, inside the inner ring.
		float ang = atan(p.y, p.x) + TIME * 0.5;
		float spoke = pow(abs(cos(ang * 3.0)), 60.0) * step(r, 0.68) * 0.5;
		glow = rim * 1.5 + r2 + rune * 1.2 + spoke + (1.0 - r) * flash * 0.6;
		cover = rim * 0.12;
	} else if (pat == 7) {
		vec2 dir = p / max(r, 0.001);
		float n = vnoise(dir * 3.0 + seed * 5.0) * 0.6 + vnoise(dir * 7.0 - seed) * 0.4;
		// A trampled dust ring with drag scuffs, broken in 5 places, and a thin teal glint just outside it.
		float ring = exp(-pow((r - 0.7 - (n - 0.5) * 0.12) * R * 4.5, 2.0));
		float scuff = smoothstep(0.3, 0.8, vnoise(vec2(au * 40.0, r * R * 3.0 + seed)));
		float gap = smoothstep(0.12, 0.22, fract(au * 5.0 + seed));
		cover = ring * (0.25 + 0.3 * scuff) * gap;
		dark = vec3(0.36, 0.30, 0.22) * (0.8 + 0.4 * scuff);
		float glint = exp(-pow((r - 0.9) * R * 14.0, 2.0)) * gap;
		glow = glint * 0.55 * (0.75 + 0.25 * sin(TIME * 4.0 + au * 30.0)) + ring * gap * 0.08;
	} else {
		float mott = vnoise(p * R * 1.3 + seed * 4.0);
		vec2 c1 = cracks(p, r, au, R, 8.0, 0.5, 0.12, seed + 2.0);
		float scorch = (1.0 - smoothstep(0.55, 1.0, r + (mott - 0.5) * 0.3));
		cover = scorch * (0.5 + 0.25 * mott);
		dark = vec3(0.03, 0.03, 0.06) * (0.8 + 0.5 * mott);
		float twinkle = step(0.93, hash(floor(p * R * 3.0) + seed)) * (0.5 + 0.5 * sin(TIME * 7.0 + hash(floor(p * R * 3.0)) * 30.0));
		glow = c1.y * 1.1 + twinkle * scorch * 0.9 + exp(-r * 5.0) * 0.6;
	}
	vec3 emit = tint.rgb * tint.a * glow;
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * a;
	ALPHA = a;
}
