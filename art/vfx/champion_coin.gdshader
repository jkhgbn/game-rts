shader_type spatial;
// Spinning gold coin (ChampionVfx, task 9.V5): Marked for Coin's mark above the target and the flipped coin.
// CylinderMesh radius 1 (flat), scaled. The vertex stage stands the disc up and spins it around the world-up axis
// (TIME * spin + phase: no script work per frame); the fragment fakes a polished metal look (fixed key light in
// view space, specular) with a raised rim, a groove and the Coin-Cutter's diamond mark. HDR `energy` makes it glow.
render_mode unshaded, blend_mix, depth_draw_always, cull_back, shadows_disabled, fog_disabled;

uniform vec3 gold : source_color = vec3(1.0, 0.85, 0.3);
uniform vec3 deep : source_color = vec3(0.70, 0.55, 0.25);
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float spin = 4.0;      // radians / second
instance uniform float phase = 0.0;
instance uniform float energy = 1.5;

varying vec3 lp;
varying vec3 ln;

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
	float a = TIME * spin + phase;
	// Stand up: rotate 90 degrees around X (faces +-Y -> +-Z), then spin around Y.
	vec3 v = vec3(VERTEX.x, -VERTEX.z, VERTEX.y);
	vec3 n = vec3(NORMAL.x, -NORMAL.z, NORMAL.y);
	mat2 rot = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
	v.xz = rot * v.xz;
	n.xz = rot * n.xz;
	VERTEX = v;
	NORMAL = n;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 l = normalize(vec3(0.35, 0.8, 0.5));
	float dif = 0.5 + 0.6 * max(dot(n, l), 0.0);
	vec3 h = normalize(l + VIEW);
	float spec = pow(max(dot(n, h), 0.0), 30.0);
	float rim_light = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 3.0);
	vec3 base;
	if (abs(ln.y) > 0.5) {
		float r = length(lp.xz);
		float rim = smoothstep(0.8, 0.85, r) * (1.0 - smoothstep(0.93, 0.98, r));
		float groove = smoothstep(0.7, 0.73, r) * (1.0 - smoothstep(0.76, 0.79, r));
		float dm = abs(lp.x) + abs(lp.z) * 1.35;
		float diamond = 1.0 - smoothstep(0.42, 0.47, dm);
		float cut = 1.0 - smoothstep(0.17, 0.21, dm);
		base = mix(gold, deep, groove * 0.85);
		base = mix(base, gold * 1.3, rim * 0.6 + (diamond - cut) * 0.55);
		base = mix(base, deep * 0.8, cut * 0.7);
	} else {
		float reed = step(0.5, fract(atan(lp.z, lp.x) * 9.549));
		base = deep * (0.75 + 0.3 * reed);
	}
	ALBEDO = (base * dif * energy + vec3(1.0, 0.95, 0.8) * (spec * 1.6 + rim_light * 0.4)) * fade;
	ALPHA = fade;
}
