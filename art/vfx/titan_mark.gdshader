shader_type spatial;
// Ground marks of the non-dragon titans (TitanGroundVfx, task 13.V19). PlaneMesh 2 x 2 scaled to `radius` metres
// (node scale.x; the skid is scaled `radius` along local X and `width` across), lying just above the ground. ONE
// material for every mark: the look is picked per instance (`pattern`), so no effect ever creates a material.
// Procedural noise, no textures. Premultiplied alpha: `cover` paints rime / soil / scorch, `glow` adds light.
// Line widths are in metres (same look on a 1 m and an 8 m mark).
//   0 frost aura    (War Mammoth, r 5, follows it): a thin icy line at the rim, crystal teeth pointing in (they turn
//                   slowly), a rime fringe with frost ferns and glints, a chill ripple running inward every 2 s.
//                   LOCAL noise (the ring moves with the mammoth: world noise would crawl through it).
//   1 grove pulse   (Elder Treant, r 8, every 4 s): a band of leaves and green light racing out to `front`, root veins
//                   lighting up behind it, a soft wash; the r 8 line lingers when it arrives.
//   2 trample stomp (War Mammoth foot, r 1.5): packed dirt, a snowy frost lip, radial ice cracks glowing, glints.
//   3 root bed      (Elder Treant, r 3.4): torn churned soil, radial root furrows with a green sap line, moss specks,
//                   a raised dirt lip. `front` = how far the roots have spread, `heat` = the sap glow.
//   4 skid          (Knight knockback, local +X = the push; `radius` = half the length, `width` = half the width):
//                   three ploughed furrows from the start to `front`, a heap of dirt at the head.
//   5 sprout        (Sapling, r 1.3): a small burst mound, cracks, a green ring and slowly turning leaf marks.
//   6 frost splat   (howdah bolt hit, r 0.9): a rime star with glints.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float radius = 2.0;       // metres (= node scale.x)
instance uniform float width = 0.5;        // skid: half width in metres (= node scale.z)
instance uniform float heat = 1.0;         // 0-1: glow strength
instance uniform float front = 1.0;        // 0-1: how far the mark has spread
instance uniform vec4 glow = vec4(0.6, 1.2, 2.0, 1.0);        // linear HDR
instance uniform vec4 cover = vec4(0.1, 0.12, 0.16, 0.6);     // rgb linear, a = max opacity

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

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

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + vec2(7.1, 1.3)) * 0.3 + vnoise(p * 4.07 - vec2(3.3, 5.9)) * 0.15;
}

// Thin bright lines where the noise crosses 0.5 (crystal edges, veins).
float ridge_lines(vec2 p, float lo, float hi) {
	float r = 1.0 - abs(fbm(p) * 2.0 - 1.0);
	return smoothstep(lo, hi, r);
}

// A sparse grid of tiny twinkling stars (ice glints). `w` in cells, `amount` = share of lit cells.
float glints(vec2 w, float amount, float t) {
	vec2 c = floor(w);
	vec2 f = fract(w) - 0.5;
	float h = hash(c + 3.7);
	vec2 o = vec2(hash(c + 1.3), hash(c + 9.1)) - 0.5;
	vec2 d = abs(f - o * 0.6);
	float star = max(1.0 - smoothstep(0.0, 0.07, length(d)),
			(1.0 - smoothstep(0.0, 0.02, min(d.x, d.y))) * (1.0 - smoothstep(0.0, 0.2, max(d.x, d.y))) * 0.6);
	float tw = pow(max(0.0, sin(t * (2.0 + h * 3.0) + h * 40.0)), 10.0);
	return step(1.0 - amount, h) * star * (0.25 + tw);
}

// Radial lanes (cracks, root furrows): `k` lanes around the circle, wandering with the noise, each ending at its own
// length (fraction of the radius, up to `reach`). `wm` = the lane width in metres. Returns 0-1 across the lane.
float lanes(vec2 p, vec2 w, float r, float R, float k, float reach, float wm) {
	vec2 dir = p / max(r, 0.0001);
	float ang = atan(p.y, p.x);
	float wander = vnoise(dir * 3.0 + seed * 2.0) * 0.6 + (vnoise(w * 1.3) - 0.5) * 0.45;
	float lane_f = ang / TAU * k + wander + seed;
	float lane = abs(fract(lane_f) - 0.5);
	float id = floor(lane_f + 0.5);
	float len = reach * (0.55 + 0.5 * hash(vec2(id, seed)));
	float wf = wm * k / (TAU * max(r * R, 0.25));
	float line = 1.0 - smoothstep(wf * 0.35, wf, 0.5 - lane);
	return line * smoothstep(0.05, 0.14, r) * (1.0 - smoothstep(len * 0.8, len, r));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	int pat = int(pattern + 0.5);
	if (pat != 4 && r > 1.0) {
		discard;
	}
	float R = max(radius, 0.05);
	vec2 w = v_world + vec2(seed * 3.7, seed * 1.9);
	vec2 dir = p / max(r, 0.0001);
	float edge_n = vnoise(dir * 2.6 + seed * 7.0) * 0.6 + vnoise(dir * 6.5 - seed * 3.0) * 0.4;
	float t = TIME + seed * 5.0;
	float ang = atan(p.y, p.x);
	float a = 0.0;
	vec3 col = cover.rgb;
	vec3 emit = vec3(0.0);
	if (pat == 0) {
		// ---- frost aura (local space)
		vec2 pm = p * R;
		float d = (1.0 - r) * R;                                 // metres in from the rim
		float n = fbm(pm * 1.2 + seed * 4.0);
		float n2 = fbm(pm * 3.1 - seed * 2.0);
		// Everything lives in the outer ~1.3 m (small linear values still show on dark grass: cut them hard).
		float outer = 1.0 - smoothstep(0.5, 1.3, d);
		float band = exp(-pow((d - 0.1) / 0.06, 2.0));
		float halo = exp(-pow((d - 0.1) / 0.3, 2.0));
		float fringe = exp(-d / 0.3) * (0.5 + 0.8 * n) * outer;
		float ferns = ridge_lines(pm * 1.7 + seed * 3.0, 0.9, 0.985) * exp(-d / 0.35) * outer;
		// Crystal teeth: slim triangles from the rim inward, turning slowly around the ring.
		float nt = floor(TAU * R / 0.62);
		float af = (ang + TIME * 0.06) / TAU * nt;
		float id = floor(af);
		float xm = (fract(af) - 0.5) * TAU * R / nt;               // metres along the rim from the tooth axis
		float len = 0.24 + 0.34 * hash(vec2(id, seed));
		float k = clamp((d - 0.05) / len, 0.0, 1.0);
		float half_w = 0.11 * (1.0 - k);
		float tooth = (1.0 - smoothstep(half_w * 0.55, half_w + 0.004, abs(xm))) * step(d, len + 0.05) * step(0.02, d);
		float facet = xm > 0.0 ? 1.0 : 0.6;
		float tw = 0.55 + 0.45 * sin(TIME * 1.6 + id * 2.3);
		// The chill ripple (the 0.5 s re-chill, shown as a slow breath inward every 2 s).
		float ph = fract(TIME * 0.5 + seed);
		float rip = exp(-pow((d - ph * 1.8) / 0.22, 2.0)) * (1.0 - ph) * (1.0 - smoothstep(1.2, 1.8, d));
		float wash = 0.012 + 0.03 * smoothstep(0.6, 1.0, r);
		a = (fringe * 0.4 + tooth * 0.75 + band * 0.35 + wash) * cover.a;
		col = mix(cover.rgb, vec3(0.85, 0.93, 1.0), tooth * facet * 0.8 + band * 0.4);
		emit = glow.rgb * (band * 1.35 + halo * 0.2 + tooth * facet * 0.55 * tw + ferns * 0.35 + rip * 0.12
				+ glints(pm * 2.3, 0.22, t) * exp(-d / 0.35) * 2.2 * outer);
		a *= heat;
		emit *= heat;
	} else if (pat == 1) {
		// ---- grove pulse
		float fr = max(front, 0.001);
		float dm = (r - fr) * R;                                   // metres from the band (negative = inside)
		float band = exp(-pow(dm / 0.3, 2.0));
		// Behind the band only (hard cut: small linear values still show on dark grass).
		float behind = r < fr ? 1.0 - smoothstep(0.0, 1.6, -dm) : 0.0;
		float trail = r < fr ? exp(dm / 0.7) * behind : 0.0;
		float nl = max(8.0, floor(TAU * fr * R / 0.85));
		float cell = fract(ang / TAU * nl + seed + fr * 0.6) - 0.5;
		vec2 q = vec2(cell * TAU * fr * R / nl, dm + 0.05);
		float leaf = 1.0 - smoothstep(0.7, 1.0, length(q / vec2(0.36, 0.13)));
		float vein = (1.0 - smoothstep(0.0, 0.018, abs(q.y))) * step(abs(q.x), 0.3) * leaf;
		float veins = ridge_lines(w * 1.4 + seed, 0.94, 0.99) * behind;
		float rimk = smoothstep(0.82, 1.0, fr);
		float rimline = exp(-pow((1.0 - r) * R / 0.09, 2.0)) * rimk;
		float mott = fbm(w * 0.9 + 3.0);
		a = (band * 0.22 + leaf * 0.55 + trail * 0.08 * (0.6 + 0.8 * mott)) * cover.a;
		col = mix(cover.rgb, cover.rgb * 2.6, leaf * (1.0 - vein));
		emit = glow.rgb * (band * 1.15 + leaf * (0.8 - vein * 0.5) + trail * 0.12 * (0.5 + mott) + veins * 0.6
				+ rimline * 0.9);
		a *= heat;
		emit *= heat;
	} else if (pat == 2) {
		// ---- trample stomp
		float reach = max(front, 0.001) * (0.8 + 0.18 * edge_n);
		float inside = 1.0 - smoothstep(reach - 0.2, reach, r);
		float n = fbm(w * 1.6);
		float n2 = fbm(w * 3.6 + 1.0);
		float bowl = 1.0 - smoothstep(0.0, reach * 0.75, r);
		float lip = exp(-pow((r - reach * 0.86) * R / 0.17, 2.0)) * (0.6 + 0.6 * n2);
		float cr = lanes(p, w, r, R, 7.0, min(1.0, reach * 1.3), 0.06);
		a = inside * cover.a * clamp(0.3 + 0.4 * bowl + (n - 0.5) * 0.6, 0.0, 1.0) + lip * 0.55;
		vec3 snow = vec3(0.78, 0.86, 0.95);
		col = mix(cover.rgb * (0.8 + 0.4 * n2), snow, clamp(lip * 1.2, 0.0, 1.0));
		col = mix(col, vec3(0.03, 0.05, 0.09), cr * 0.7);
		emit = glow.rgb * (cr * 1.5 + glints(w * 3.6, 0.28, t) * (inside + lip) * 1.6 + bowl * 0.12) * heat;
		a = max(a, cr * 0.6 * cover.a);
	} else if (pat == 3) {
		// ---- root bed
		float reach = max(front, 0.001) * (0.8 + 0.18 * edge_n);
		float inside = 1.0 - smoothstep(reach - 0.25, reach, r);
		float n = fbm(w * 1.1);
		float n2 = fbm(w * 2.8 + 4.0);
		float churn = clamp(0.45 + (n - 0.5) * 1.4, 0.0, 1.0);
		float clumps = smoothstep(0.5, 0.72, n2);
		float fur = lanes(p, w, r, R, 10.0, min(1.0, reach * 1.08), 0.2);
		float sap = lanes(p, w, r, R, 10.0, min(1.0, reach * 1.08), 0.05);
		float lip = exp(-pow((r - reach * 0.9) * R / 0.3, 2.0)) * (0.5 + 0.7 * n2) * step(0.02, front);
		vec2 mc = floor(w * 3.0);
		float moss = step(0.9, hash(mc + seed)) * (1.0 - smoothstep(0.12, 0.32, length(fract(w * 3.0) - 0.5))) * inside;
		a = inside * cover.a * (0.4 + 0.45 * churn) + lip * 0.5 * cover.a;
		col = mix(cover.rgb * (0.75 + 0.35 * churn), cover.rgb * 2.2, clumps * 0.6 + lip * 0.7);
		col = mix(col, cover.rgb * 0.35, fur);
		col = mix(col, vec3(0.08, 0.2, 0.05), moss);
		a = max(a, fur * 0.9 * cover.a);
		emit = glow.rgb * (sap * 1.3 + moss * 0.25 + fur * 0.12) * heat;
	} else if (pat == 4) {
		// ---- skid (UV x: 0 = start, 1 = end of the plane; the skid reaches `front` of it)
		float L = 2.0 * R;
		float xm = (p.x + 1.0) * R;                                  // metres from the start
		float ym = p.y * max(width, 0.05);                          // metres across
		float W = max(width, 0.05);
		float headx = max(front, 0.001) * L;
		float edge = W * (0.5 + 0.5 * smoothstep(0.0, max(headx, 0.3), xm)) * (0.85 + 0.3 * vnoise(vec2(xm * 2.3, seed * 5.0)));
		float inside = (1.0 - smoothstep(edge * 0.75, edge, abs(ym))) * smoothstep(-0.02, 0.2, xm)
				* (1.0 - smoothstep(headx - 0.12, headx + 0.04, xm));
		float n = fbm(w * 1.8);
		float fur = 0.5 + 0.5 * cos(ym / W * PI * 3.0 + (vnoise(vec2(xm * 1.3, seed)) - 0.5) * 1.6);
		float groove = smoothstep(0.55, 0.95, fur);
		float pile = exp(-pow((xm - headx) / 0.24, 2.0)) * (1.0 - smoothstep(edge * 0.6, edge * 1.15, abs(ym)));
		float side = exp(-pow((abs(ym) - edge * 0.9) / 0.07, 2.0)) * inside * 0.6;
		a = inside * cover.a * clamp(0.35 + 0.45 * groove + (n - 0.5) * 0.5, 0.0, 1.0) + (pile * 0.6 + side * 0.4) * cover.a;
		col = mix(cover.rgb * (0.8 + 0.4 * n), cover.rgb * 0.22, groove);
		col = mix(col, cover.rgb * 1.5, clamp(pile + side, 0.0, 1.0));
		emit = glow.rgb * groove * inside * heat * 0.3;
	} else if (pat == 5) {
		// ---- sapling sprout
		float reach = max(front, 0.001) * (0.82 + 0.16 * edge_n);
		float inside = 1.0 - smoothstep(reach - 0.14, reach, r);
		float n = fbm(w * 2.2);
		float mound = 1.0 - smoothstep(0.0, reach * 0.55, r);
		float lip = exp(-pow((r - reach * 0.62) * R / 0.12, 2.0));
		float cr = lanes(p, w, r, R, 6.0, min(1.0, reach), 0.05);
		float ring = exp(-pow((r - reach * 0.93) * R / 0.07, 2.0));
		float nl = 5.0;
		float cell = fract((ang + TIME * 0.35) / TAU * nl + seed) - 0.5;
		vec2 q = vec2(cell * TAU * 0.62 * R / nl, (r - 0.78) * R);
		float leaf = (1.0 - smoothstep(0.75, 1.0, length(q / vec2(0.2, 0.08)))) * step(0.3, front);
		a = inside * cover.a * clamp(0.45 + 0.35 * mound + (n - 0.5) * 0.6, 0.0, 1.0) + lip * 0.35 * cover.a;
		col = mix(cover.rgb * (0.8 + 0.4 * n), cover.rgb * 2.2, lip);
		col = mix(col, cover.rgb * 0.4, cr);
		a = max(a, leaf * 0.6);
		col = mix(col, vec3(0.12, 0.3, 0.08), leaf);
		emit = glow.rgb * (ring * 1.2 + leaf * 0.8 + cr * 0.5 + mound * 0.2) * heat;
	} else {
		// ---- frost splat
		float spikes = pow(abs(cos(ang * 3.5 + seed * 3.0)), 5.0) * (0.6 + 0.4 * hash(vec2(floor(ang * 1.1 + 3.5), seed)));
		float rr = max(front, 0.001) * (0.45 + 0.5 * spikes) * (0.85 + 0.2 * edge_n);
		float inside = 1.0 - smoothstep(rr - 0.1, rr, r);
		float n = fbm(w * 3.0);
		a = inside * cover.a * clamp(0.5 + (n - 0.5) * 0.8, 0.0, 1.0);
		col = cover.rgb * (0.85 + 0.3 * n);
		emit = glow.rgb * (ridge_lines(w * 3.4 + seed, 0.88, 0.98) * 0.8 + glints(w * 5.0, 0.35, t) * 2.2
				+ (1.0 - r) * 0.35) * inside * heat;
	}
	a = clamp(a, 0.0, 1.0) * fade;
	ALBEDO = col * a + emit * fade;
	ALPHA = a;
}
