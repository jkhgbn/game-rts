shader_type spatial;
// The Mossback's Canopy pulse on the ground (UnitNatureT3Vfx, task 13b.V9, tier3-extras.md 7.2): PlaneMesh 2 x 2 scaled
// to the aura radius (6 m). One pulse every 4 s: a soft lime wave rolls out from the shell (WAVE_T s to the rim), a
// dappled leaf-shade floor (the canopy's shadow, sun specks through it) swells behind it, and when the wave reaches
// the rim a RING OF LEAVES sprouts along it and flashes, then everything fades (the family's `fade`).
// Pooled: one shared material, the look comes from instance uniforms (`age` = seconds since the pulse started).
// Premultiplied alpha: the shade darkens the ground, the wave / leaves add light.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.3, 2.4, 0.45, 1.0);    // glow colour (linear HDR), a = strength
instance uniform vec4 shade = vec4(0.02, 0.06, 0.02, 0.22); // leaf-shade colour, a = opacity
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;
instance uniform float radius = 6.0;                        // metres (= node scale.x)

const float WAVE_T = 0.7;

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

// A pointed leaf (lens of two circles) of half-length hl and half-width hw, along local x; 1 inside, soft edge.
float leaf(vec2 q, float hl, float hw) {
	float off = (hl * hl - hw * hw) / (2.0 * hw);
	float rad = off + hw;
	float d = max(length(q - vec2(0.0, off)), length(q + vec2(0.0, off)));
	return 1.0 - smoothstep(rad - 0.03, rad, d);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float R = max(radius, 0.5);
	float au = atan(p.y, p.x) / 6.2831853 + 0.5;
	float d = (1.0 - r) * R;                              // metres in from the rim
	float k = clamp(age / WAVE_T, 0.0, 1.0);
	float wr = 1.0 - pow(1.0 - k, 2.2);                     // wave front (fraction of R), ease-out
	float after = max(age - WAVE_T, 0.0);
	// Wave: a soft bright band at the front, a faint wash behind it.
	float band = exp(-pow((r - wr) * R, 2.0) * 4.0) * (1.0 - 0.55 * k) * step(age, WAVE_T + 0.25)
			* (1.0 - smoothstep(WAVE_T, WAVE_T + 0.25, age));
	float wash = (1.0 - smoothstep(wr - 0.25, wr + 0.02, r)) * 0.018 * (1.0 - smoothstep(0.0, 0.6, after));
	// Leaf shade: dapple (two drifting noise octaves), only where the wave has passed.
	vec2 wp = p * R;
	float dn = vnoise(wp * 0.55 + seed * 3.0 + vec2(TIME * 0.12, -TIME * 0.08)) * 0.65
			+ vnoise(wp * 1.4 - seed + vec2(-TIME * 0.2, TIME * 0.15)) * 0.35;
	float dapple = smoothstep(0.38, 0.62, dn);
	float inside = (1.0 - smoothstep(wr - 0.1, wr + 0.03, r)) * (1.0 - smoothstep(0.9, 1.0, r));
	float cover = shade.a * inside * (0.45 + 0.55 * dapple);
	float specks = smoothstep(0.8, 0.92, dn) * inside * 0.05;   // sun specks through the leaves
	// Ring of leaves along the rim: each cell a leaf turned along the rim (+- a random tilt), alternately in / out.
	float n = max(12.0, floor(6.2831853 * R / 0.85));
	float ci = floor(au * n);
	float cf = fract(au * n) - 0.5;
	float hsh = hash(vec2(ci, seed));
	float rr = 0.93 - 0.035 * step(0.5, fract(ci * 0.5));
	vec2 q = vec2(cf * 6.2831853 * R / n, (r - rr) * R);
	float ang = (hsh - 0.5) * 1.2 + 0.35;
	q = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * q;
	float grow = smoothstep(WAVE_T - 0.25, WAVE_T + 0.1, age + hsh * 0.08);
	float lf = leaf(q, 0.3 * (0.8 + 0.4 * hsh) * grow + 0.001, 0.1 * grow + 0.001);
	float rib = (1.0 - smoothstep(0.0, 0.018, abs(q.y))) * step(abs(q.x), 0.24);
	float flash = exp(-after * 3.5) * step(WAVE_T, age);
	float leaves = lf * (0.35 + 1.0 * flash) * (1.0 - rib * 0.45);
	float rim = exp(-d * d * 30.0) * (0.12 + 0.35 * flash) * grow;
	float glow = band * 0.6 + wash + specks + leaves + rim;
	vec3 emit = tint.rgb * tint.a * glow;
	vec3 leaf_dark = vec3(0.03, 0.08, 0.02);
	float a = clamp(cover + lf * 0.35, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + mix(shade.rgb, leaf_dark, clamp(lf, 0.0, 1.0)) * a;
	ALPHA = a;
}
