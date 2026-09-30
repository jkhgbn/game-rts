shader_type spatial;
// Bramblesage ground marks (CasterNatureVfx, task CU.V6 Nature part). PlaneMesh 2 x 2 (UV 0-1); the node's scale is the
// mark's half size in metres (`size` = the same numbers). ONE material, the look per instance (`pattern`):
//   0 furrow       torn earth along local +Z (UV.y 0 = where the victim stood, 1 = where the drag has got to): a dark
//                  soil trench with ragged lips and a few clods, `draw` 0-1 draws it in.
//   1 haze pool    the Pollen Haze footprint (r = size.x): a soft straw-yellow veil with drifting pollen specks and a
//                  thin rim so the 3.5 m area reads at 40 m (both teams see it).
//   2 root coil    the rooted look at a unit's feet (r = size.x): bark roots curling in around the feet, lime tips.
//   3 mote halo    `hazed`: a ring of glowing pollen motes (r = size.x) turning around a unit's head (laid flat).
// Premultiplied alpha: `tint` glow adds light, the cover (soil / bark / olive) darkens so it reads on meadow and sand.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.2, 1.6, 0.4, 1.0);
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float draw = 1.0;
instance uniform vec2 size = vec2(1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 m = (UV - 0.5) * 2.0 * size;
	float glow = 0.0;
	float cover = 0.0;
	vec3 cov_col = vec3(0.14, 0.09, 0.04);
	if (pattern < 0.5) {
		float along = UV.y * size.y * 2.0;
		float total = size.y * 2.0;
		float shown = step(along, draw * total);
		float w = size.x * (0.55 + 0.35 * vnoise(vec2(along * 3.0, seed * 4.0)));
		float d = abs(m.x + (vnoise(vec2(along * 1.3, seed)) - 0.5) * 0.12);
		float trench = 1.0 - smoothstep(w * 0.45, w * 0.7, d);
		float lip = (1.0 - smoothstep(0.02, 0.08, abs(d - w * 0.8))) * 0.8;
		float clods = step(0.8, vnoise(m * 9.0 + seed * 5.0)) * (1.0 - smoothstep(w * 0.7, w * 1.3, d));
		float ends = smoothstep(0.0, 0.25, along) * (1.0 - smoothstep(total - 0.3, total, along) * 0.5);
		cover = (trench * 0.75 + lip * 0.35 + clods * 0.5) * shown * ends;
		cov_col = mix(vec3(0.16, 0.10, 0.05), vec3(0.34, 0.24, 0.13), lip + clods * 0.6);
		glow = 0.0;
	} else if (pattern < 1.5) {
		float r = length(m) / size.x;
		float veil = (1.0 - smoothstep(0.55, 1.0, r));
		float swirl = vnoise(vec2(atan(m.y, m.x) * 2.0 + TIME * 0.25, r * 3.0 - TIME * 0.2) + seed);
		float specks = step(0.86, vnoise(m * 7.0 + vec2(TIME * 0.3, -TIME * 0.2) + seed * 3.0));
		float rim = 1.0 - smoothstep(0.012, 0.035, abs(r - 0.97));
		glow = veil * (0.18 + 0.2 * swirl) + specks * veil * 0.6 + rim * 0.9;
		cover = veil * 0.22 + rim * 0.25;
		cov_col = vec3(0.24, 0.22, 0.06);
	} else if (pattern < 2.5) {
		float r = length(m) / size.x;
		float a = atan(m.y, m.x);
		float k = 7.0;
		// roots spiral in: a = a0 + twist * (1 - r)
		float ang = a + (1.0 - r) * 2.2 + seed;
		float root = abs(fract(ang / 6.28318 * k) - 0.5) / k * 6.28318 * r * size.x;
		float wdt = 0.035 + 0.05 * (1.0 - r);
		float line = (1.0 - smoothstep(wdt, wdt + 0.03, root)) * step(0.22, r) * (1.0 - smoothstep(0.85, 1.0, r));
		float tipm = line * smoothstep(0.7, 0.9, r);
		cover = line * 0.9 + (1.0 - smoothstep(0.25, 1.0, r)) * 0.15;
		cov_col = mix(vec3(0.20, 0.13, 0.06), vec3(0.34, 0.24, 0.12), 0.5 + 0.5 * sin(root * 60.0));
		glow = tipm * 0.8;
	} else {
		float r = length(m) / size.x;
		float a = atan(m.y, m.x) + TIME * 1.6 + seed;
		float n = 7.0;
		float cell = fract(a / 6.28318 * n);
		vec2 q = vec2((cell - 0.5) * 6.28318 * size.x / n, (r - 1.0) * size.x);
		float dotm = 1.0 - smoothstep(0.035, 0.07, length(q));
		float band = (1.0 - smoothstep(0.0, 0.05, abs(r - 1.0) * size.x)) * 0.25;
		glow = dotm * 1.6 + band;
		cover = dotm * 0.2;
		cov_col = vec3(0.2, 0.2, 0.05);
	}
	float f = fade;
	ALBEDO = cov_col * cover * f + tint.rgb * tint.a * glow * f;
	ALPHA = clamp(cover * f, 0.0, 1.0);
}
