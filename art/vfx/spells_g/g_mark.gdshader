shader_type spatial;
// G-B spell VFX (art/vfx/spells_g/spell_fx_g.gd): small ground marks that fade (on a flat 2 x 2 m plane, scaled to
// the radius). See-through by design: the darkest mark keeps <= 0.62 alpha so units and buildings stay readable.
//   kind 0  scorch: charcoal splat, a ring of soot and glowing ember cracks that cool with `heat`
//   kind 1  frost:  pale steel-blue rime with fern rays and glints
//   kind 2  void:   a violet-black burn with a thin rune ring
//   kind 3  earth:  torn dark soil with pale root lines (Nature)
render_mode unshaded, cull_back, depth_draw_never, blend_mix, fog_disabled, shadows_disabled;

instance uniform float kind = 0.0;
instance uniform float fade = 1.0;
instance uniform float heat = 1.0;
instance uniform float seed = 0.0;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * n2(p);
		p = p * 2.07 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 c = (UV - 0.5) * 2.0;
	float d = length(c);
	float ang = atan(c.y, c.x);
	vec2 sp = c * 3.0 + vec2(seed * 7.1, seed * 3.3);
	float n = fbm(sp);
	float edge = 1.0 - smoothstep(0.55, 1.0, d + (n - 0.5) * 0.55);
	vec3 col = vec3(0.0);
	float a = 0.0;
	int k = int(kind + 0.5);
	if (k == 0) {
		float soot = edge * (0.45 + 0.35 * n);
		float ridge = 1.0 - smoothstep(0.0, 0.07, abs(fbm(sp * 1.6 + 4.0) - 0.5));
		float crack = ridge * edge * smoothstep(0.95, 0.2, d) * clamp(heat, 0.0, 1.0);
		col = mix(vec3(0.035, 0.028, 0.024), vec3(4.0, 1.1, 0.18), crack);
		a = max(soot * 0.62, crack * 0.95);
	} else if (k == 1) {
		float rays = pow(abs(sin(ang * 7.0 + n * 5.0 + seed)), 14.0) * (1.0 - d);
		float fern = 1.0 - smoothstep(0.0, 0.06, abs(fbm(sp * 2.2) - 0.5));
		float glint = step(0.985, h2(floor(sp * 9.0))) * edge;
		float body = edge * (0.25 + 0.25 * n);
		col = mix(vec3(0.42, 0.62, 0.80), vec3(0.85, 0.95, 1.05), clamp(rays + fern * 0.6, 0.0, 1.0));
		col += vec3(1.2, 1.5, 1.8) * glint;
		a = clamp(body + (rays + fern * 0.5) * edge * 0.45 + glint, 0.0, 0.62);
	} else if (k == 2) {
		float burn = edge * (0.5 + 0.3 * n);
		float ring = 1.0 - smoothstep(0.0, 0.035, abs(d - 0.78 - 0.015 * sin(ang * 11.0 + seed) - (n - 0.5) * 0.05));
		float rune = step(0.55, fract(ang * 3.8197 + seed)) * ring;
		col = mix(vec3(0.03, 0.0, 0.05), vec3(1.0, 0.32, 2.0) * (0.4 + 0.6 * heat), clamp(ring * 0.6 + rune, 0.0, 1.0));
		a = clamp(burn * 0.42 + ring * 0.5 * heat, 0.0, 0.62);
	} else {
		float soil = edge * (0.42 + 0.3 * n);
		float root = 1.0 - smoothstep(0.0, 0.05, abs(fbm(vec2(ang * 2.0, d * 3.0) + seed) - 0.5));
		col = mix(vec3(0.09, 0.065, 0.04), vec3(0.62, 0.78, 0.30) * (0.6 + 0.8 * heat), root * edge * 0.8);
		a = clamp(soil * 0.6 + root * edge * 0.3, 0.0, 0.62);
	}
	ALBEDO = col;
	ALPHA = clamp(a * fade, 0.0, 1.0);
}
