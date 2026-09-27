shader_type spatial;
// Champion ability ground marks (ChampionVfx, task 9.V5). PlaneMesh 2 x 2 scaled to the radius (scale.x = `radius`
// metres). ONE material for every mark: the look is picked per instance (`pattern`), so a cast never creates a
// material. Premultiplied alpha: `glow` adds light in `tint`, `cover` darkens (soot, rope) so marks read on grass,
// dirt and stone alike. Line widths are in metres (they stay thin on a 6 m ring and on a 1 m ring).
//   0 shockwave ring    (Oath of Iron, Bulwark plant, impacts)     1 golden wind ring (Trailblaze)
//   2 heal circle       (Soothing Circle: leaf ring + 1 pulse / s)  3 rope coils (Snare Line root)
//   4 flare light pool  (Flare Arrow: dashed rim = vision radius)   5 soot (Smoke Pouch; `tint` = soot colour)
//   6 ward rim + rivets (Bulwark footprint, Oath armour, Marked for Coin)
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.5, 0.6, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;      // seconds since the mark appeared (only its first second is sent: snap flash)
instance uniform float seed = 0.0;
instance uniform float radius = 1.0;   // current radius in metres (= node scale.x)

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

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	float au = atan(p.y, p.x) / 6.2831853 + 0.5;   // 0..1 around the circle
	float d = (1.0 - r) * R;                        // metres in from the rim
	float glow = 0.0;
	float cover = 0.0;
	vec3 dark = vec3(0.0);
	int pat = int(pattern + 0.5);
	if (pat == 0) {
		// Shockwave: a hot band at the rim, a soft wash trailing inside it, radial scuff streaks.
		float band = exp(-d * d * 30.0);
		float wash = exp(-d * 1.4) * 0.16 * smoothstep(0.0, 0.3, d);
		float n = vnoise(vec2(au * 46.0, seed * 13.0));
		float streak = smoothstep(0.6, 0.92, n) * exp(-d * 1.2) * 0.35;
		glow = band * 1.4 + wash + streak;
		cover = band * 0.12;
	} else if (pat == 1) {
		// Golden wind: comet-shaped arcs racing around a 1 m band, a thin bright rim ahead of them.
		float band = exp(-d * d * 1.6);
		float s = fract(au * 7.0 + d * 0.35 - TIME * 1.1 + seed);
		float arc = smoothstep(0.0, 0.04, s) * pow(1.0 - s, 2.6);
		float s2 = fract(au * 11.0 - d * 0.5 - TIME * 1.6 + seed * 2.0);
		float arc2 = smoothstep(0.0, 0.05, s2) * pow(1.0 - s2, 4.0) * exp(-pow(d - 0.9, 2.0) * 4.0);
		float rim = exp(-d * d * 60.0);
		glow = band * arc * 1.9 + arc2 * 1.1 + rim * 0.9 + band * 0.12;
	} else if (pat == 2) {
		// Heal circle: mottled soft fill, glowing rim, a slow ring of leaf marks, a pulse every second (the ticks).
		float rim = exp(-d * d * 26.0);
		float mottle = vnoise(p * R * 0.8 + seed * 5.0) * 0.6 + vnoise(p * R * 2.1 - seed) * 0.4;
		float fill = (0.07 + 0.12 * smoothstep(0.2, 1.0, r)) * (0.6 + 0.8 * mottle);
		float n = 10.0;
		float rr = 0.78;
		float cell = fract(au * n - TIME * 0.04 + seed) - 0.5;
		vec2 q = vec2(cell * 6.2831853 * rr * R / n, (r - rr) * R);
		float leaf = 1.0 - smoothstep(0.75, 1.0, length(q / vec2(0.34, 0.12)));
		float vein = (1.0 - smoothstep(0.0, 0.02, abs(q.y))) * step(abs(q.x), 0.3);
		float pr = fract(TIME + seed);
		float pulse = exp(-pow((r - pr) * R, 2.0) * 5.0) * (1.0 - pr) * 0.75;
		glow = rim * 1.5 + fill + leaf * (0.75 - vein * 0.4) + pulse;
		cover = leaf * 0.1;
		dark = vec3(0.02, 0.08, 0.03);
	} else if (pat == 3) {
		// Snare root: two twisted leather rope coils with an amber glint (flashes when the loop snaps shut).
		float snap = exp(-age * 7.0);
		for (int i = 0; i < 2; i++) {
			float rr = i == 0 ? 0.62 : 0.86;
			float th = 0.075;
			float dr = ((r - rr) * R) / th;             // -1..1 across the rope
			float on = 1.0 - smoothstep(0.7, 1.0, abs(dr));
			float strands = 6.2831853 * rr * R / 0.1;
			float tw = fract(au * strands + dr * 0.55 + float(i) * 0.37);
			float lit = smoothstep(0.05, 0.3, tw) * (1.0 - smoothstep(0.6, 0.9, tw));
			vec3 rope = vec3(0.40, 0.26, 0.14) * (0.55 + 0.55 * lit) * (1.0 - dr * dr * 0.45);
			dark = mix(dark, rope, on);
			cover = max(cover, on * 0.95);
			glow += exp(-dr * dr * 0.35) * (0.22 + 1.4 * snap) * (1.0 - on * 0.6);
		}
		// Four glowing knots where the coils cross.
		float kc = fract(au * 4.0 + seed) - 0.5;
		vec2 kq = vec2(kc * 6.2831853 * 0.74 * R / 4.0, (r - 0.74) * R);
		glow += (1.0 - smoothstep(0.08, 0.14, length(kq))) * 0.8;
	} else if (pat == 4) {
		// Flare light pool: warm falloff from the centre, flickering, dashed rim at the vision radius.
		float flick = 0.88 + 0.08 * sin(TIME * 11.0 + seed * 6.0) + 0.04 * sin(TIME * 27.0 + seed);
		float pool = pow(1.0 - r, 1.8) * 0.6;
		float dash = step(0.42, fract(au * floor(6.2831853 * R / 0.9) - TIME * 0.08));
		float rim = exp(-d * d * 30.0) * dash * 0.55;
		glow = (pool + rim) * flick;
	} else if (pat == 5) {
		// Soot: dark ragged smudge that churns slowly; tint = the soot colour (no glow).
		vec2 dir = p / max(r, 0.001);
		float edge_n = vnoise(dir * 2.5 + seed * 7.0) * 0.6 + vnoise(dir * 6.0 - seed * 3.0) * 0.4;
		float reach = 0.7 + 0.28 * edge_n;
		float body = 1.0 - smoothstep(reach - 0.3, reach, r);
		float mott = vnoise(p * R * 1.4 + seed * 3.0 + vec2(TIME * 0.25, -TIME * 0.18));
		cover = body * (0.4 + 0.35 * mott);
		dark = tint.rgb * (0.8 + 0.4 * mott);
	} else {
		// Ward: a bright rim, a second line 0.35 m inside, rivets between the two, a faint tinted floor.
		float rim = exp(-d * d * 70.0);
		float inner = exp(-pow((d - 0.36) * 11.0, 2.0)) * 0.5;
		float n = max(6.0, floor(6.2831853 * R / 0.8));
		float cell = fract(au * n) - 0.5;
		vec2 q = vec2(cell * 6.2831853 * R / n, d - 0.18);
		float rivet = 1.0 - smoothstep(0.045, 0.075, length(q));
		float fill = 0.06 + 0.06 * smoothstep(0.3, 1.0, r);
		glow = rim * 1.6 + inner + rivet * 1.1 + fill;
		cover = rim * 0.15;
	}
	vec3 emit = tint.rgb * tint.a * glow;
	if (pat == 5) {
		emit = vec3(0.0);
	}
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * a;
	ALPHA = a;
}
