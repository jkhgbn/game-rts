shader_type spatial;
// Rune-rifle ground marks (UnitIceRifleVfx, task 13b.V7). PlaneMesh 2 x 2 scaled to the radius (scale.x = `radius`
// metres). ONE material; the look is picked per instance (`pattern`). Line widths are in metres.
//   0 brace circle   Two thin rings with six frost runes between them and a faint six-spoke star inside. `draw`
//                    (0..1) sweeps it in around the circle (the 1.0 s kneel) with a bright leading edge; when it closes
//                    it flashes (`age` s since the start); afterwards it idles dimly, the rune band turning slowly.
//   1 lock reticle   Rime Lock target mark: a dashed ring whose dashes close up as `draw` (= the charge) rises, three
//                    chevrons pointing in, turning; it pulses faster near the shot.
// Premultiplied alpha: `tint` glow adds light, a dark ice-blue cover under the lines keeps them readable on snow.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 2.0, 2.8, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;
instance uniform float radius = 1.0;
instance uniform float draw = 1.0;

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// One of three small frost runes, q in metres (x along the circle, y outward), about 0.2 m tall.
float rune(vec2 q, float kind) {
	float d;
	if (kind < 1.0) {        // a spear: stem, head chevron, crossbar
		d = seg(q, vec2(0.0, -0.09), vec2(0.0, 0.09));
		d = min(d, seg(q, vec2(-0.05, 0.04), vec2(0.0, 0.09)));
		d = min(d, seg(q, vec2(0.05, 0.04), vec2(0.0, 0.09)));
		d = min(d, seg(q, vec2(-0.04, -0.04), vec2(0.04, -0.04)));
	} else if (kind < 2.0) { // a diamond with a dot
		d = seg(q, vec2(0.0, -0.09), vec2(0.06, 0.0));
		d = min(d, seg(q, vec2(0.06, 0.0), vec2(0.0, 0.09)));
		d = min(d, seg(q, vec2(0.0, 0.09), vec2(-0.06, 0.0)));
		d = min(d, seg(q, vec2(-0.06, 0.0), vec2(0.0, -0.09)));
		d = min(d, length(q) - 0.012);
	} else {                 // a fork (flake arm)
		d = seg(q, vec2(0.0, -0.09), vec2(0.0, 0.02));
		d = min(d, seg(q, vec2(0.0, 0.02), vec2(-0.055, 0.09)));
		d = min(d, seg(q, vec2(0.0, 0.02), vec2(0.055, 0.09)));
		d = min(d, seg(q, vec2(-0.035, -0.05), vec2(0.035, -0.05)));
	}
	return d;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	float ang = atan(p.y, p.x);
	float au = ang / 6.2831853 + 0.5;
	float d = (1.0 - r) * R;                         // metres in from the rim
	float glow = 0.0;
	float cover = 0.0;
	int pat = int(pattern + 0.5);
	if (pat == 0) {
		float band_w = 0.34;
		float outer = exp(-pow(d / 0.028, 2.0));
		float inner = exp(-pow((d - band_w) / 0.022, 2.0));
		// 24 ticks outside... just inside the outer ring
		float tick_c = fract(au * 24.0 + seed) - 0.5;
		float ticks = (1.0 - smoothstep(0.08, 0.16, abs(tick_c))) * (1.0 - smoothstep(0.0, 0.06, abs(d - 0.06)));
		// six runes, turning slowly
		float turn = TIME * 0.035 + seed;
		float cell = au * 6.0 + turn;
		float ci = floor(cell);
		float cf = fract(cell) - 0.5;
		float circ = 6.2831853 * (R - band_w * 0.5) / 6.0;
		vec2 q = vec2(cf * circ, band_w * 0.5 - d);
		float rd = rune(q, mod(ci + floor(seed * 3.0), 3.0));
		float runes = 1.0 - smoothstep(0.008, 0.022, rd);
		float runes_glow = exp(-max(rd, 0.0) * 40.0) * 0.4;
		// dots between the runes
		vec2 qd = vec2((fract(cell + 0.5) - 0.5) * circ, band_w * 0.5 - d);
		float dots = 1.0 - smoothstep(0.018, 0.03, length(qd));
		// faint six-spoke star inside
		float spoke_a = abs(fract(ang / 1.0471976 + 0.5) - 0.5) * 1.0471976;
		float spoke = (1.0 - smoothstep(0.0, 0.02, sin(spoke_a) * r * R)) * smoothstep(0.1, 0.4, r)
				* step(band_w + 0.06, d) * 0.28;
		// reveal sweep
		float sweep = fract(au - seed * 0.13);
		float drawn = step(sweep, draw);
		float front = draw < 1.0 ? exp(-pow((sweep - draw) * 22.0, 2.0)) * smoothstep(-0.02, 0.4, d) * (1.0 - smoothstep(0.4, 0.6, d)) : 0.0;
		float flash = draw >= 1.0 ? exp(-max(age - 1.0, 0.0) * 4.0) : 0.0;
		float lines = outer + inner * 0.8 + ticks * 0.6 + runes + dots * 0.7;
		glow = (lines * (0.55 + 0.9 * flash) + runes_glow + spoke * (0.6 + flash)) * drawn + front * 2.2;
		glow += flash * 0.12 * smoothstep(band_w + 0.1, 0.0, d) * drawn;
		cover = (min(lines, 1.0) * 0.45 + spoke * 0.3) * drawn;
	} else {
		float spin = TIME * 1.4 + seed;
		float ring = exp(-pow((d - 0.06) / 0.035, 2.0));
		float gap = mix(0.5, 0.0, clamp(draw, 0.0, 1.0));
		float dash = step(gap, fract(au * 8.0 - spin * 0.25));
		// three chevrons pointing in, just inside the ring
		float cc = fract(au * 3.0 + spin * 0.16) - 0.5;
		vec2 q = vec2(cc * 6.2831853 * R / 3.0, d - 0.2);
		float ch = min(seg(q, vec2(-0.12, 0.1), vec2(0.0, -0.02)), seg(q, vec2(0.12, 0.1), vec2(0.0, -0.02)));
		float chev = 1.0 - smoothstep(0.015, 0.035, ch);
		float rate = mix(3.0, 14.0, draw);
		float pulse = 0.75 + 0.25 * sin(TIME * rate + seed * 3.0);
		float wash = exp(-d * 1.8) * 0.0 + smoothstep(0.35, 1.0, r) * 0.08 * draw;
		glow = (ring * dash * 1.2 + chev * 1.3 + wash) * pulse * (0.6 + 0.8 * draw);
		cover = (ring * dash + chev) * 0.5;
	}
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = tint.rgb * tint.a * glow * fade + vec3(0.02, 0.05, 0.10) * a;
	ALPHA = a;
}
