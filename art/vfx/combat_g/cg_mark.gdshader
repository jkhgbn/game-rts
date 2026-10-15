shader_type spatial;
// G-D combat feedback (CombatFxG): ground marks left by a fight, ONE MultiMesh draw call: where a unit died
// (Fire scorch with cooling embers, Ice frost star, Nature leaf litter, Shadow stain, neutral dust) and the rubble
// stain of a collapsed building. Procedural (no textures), flat on the ground, lit by the scene so night maps stay dark.
// Instance layout (12 floats): origin = centre (ground + lift), basis.x = (radius m, rotation rad, kind),
//   basis.y = (fade-in s, lifetime s, fade-out fraction of the life), basis.z unused.
//   INSTANCE_CUSTOM = (start time, seed, glow 0-1, 0); COLOR = tint rgb, a = opacity (the script writes 0 to hide a
//   mark the fog covers).
// kind: 0 scorch, 1 frost, 2 leaves, 3 shadow, 4 rubble, 5 dust.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

uniform float now = 0.0;

varying vec2 v_p;
varying vec4 v_col;
varying flat int v_kind;
varying float v_seed;
varying float v_glow;
varying float v_k;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 rrk = MODEL_MATRIX[0].xyz;
	vec3 flo = MODEL_MATRIX[1].xyz;
	vec3 c = MODEL_MATRIX[3].xyz;
	float t = now - INSTANCE_CUSTOM.x;
	float life = max(flo.y, 0.001);
	float k = clamp(t / life, 0.0, 1.0);
	float a = rrk.y;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (VERTEX.xy * 2.0 * rrk.x);
	vec3 world = c + vec3(q.x, 0.0, q.y);
	if (t < 0.0 || t >= life) {
		world = c;
	}
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	v_p = UV * 2.0 - 1.0;
	float fin = clamp(t / max(flo.x, 0.01), 0.0, 1.0);
	float fout = 1.0 - smoothstep(1.0 - clamp(flo.z, 0.05, 1.0), 1.0, k);
	v_col = vec4(COLOR.rgb, COLOR.a * fin * fout);
	v_kind = int(rrk.z + 0.5);
	v_seed = INSTANCE_CUSTOM.y;
	v_glow = INSTANCE_CUSTOM.z * (1.0 - smoothstep(0.0, 0.25, k));
	v_k = k;
}

void fragment() {
	vec2 p = v_p;
	float r = length(p);
	vec2 sp = p * 3.0 + vec2(v_seed * 17.0, v_seed * 31.0);
	float n = vnoise(sp) * 0.6 + vnoise(sp * 2.7) * 0.4;
	float blot = 1.0 - smoothstep(0.45 + 0.35 * n, 0.95, r);
	vec3 col = v_col.rgb;
	float a = blot;
	vec3 emit = vec3(0.0);
	if (v_kind == 0) {
		// Scorch: dark centre, brown rim, embers that cool.
		col = mix(col * 0.35, col, smoothstep(0.1, 0.8, r + n * 0.3));
		float sparks = step(0.82, vnoise(p * 9.0 + v_seed * 5.0)) * (1.0 - r);
		emit = vec3(1.6, 0.55, 0.12) * sparks * v_glow * 2.0;
	} else if (v_kind == 1) {
		// Frost: a 6-point star of rime with a pale fill.
		float th = atan(p.y, p.x) + v_seed * 6.2831;
		float star = pow(abs(cos(th * 3.0)), 6.0);
		float arms = 1.0 - smoothstep(0.2 + 0.55 * star, 0.3 + 0.6 * star, r);
		a = max(blot * 0.45, arms * 0.85) * (0.75 + 0.25 * n);
		col = mix(col, vec3(0.95, 0.98, 1.0), arms * 0.7);
		emit = col * 0.12 + vec3(0.25, 0.55, 0.9) * arms * v_glow * 0.5;
	} else if (v_kind == 2) {
		// Leaf litter: scattered leaf flecks (a cell grid, one oval leaf per lucky cell) on a faint green blot.
		vec2 g = p * 4.0 + v_seed * 9.0;
		vec2 cell = floor(g);
		vec2 f = fract(g) - 0.5;
		float h = hash(cell);
		float ang = h * 6.2831;
		vec2 lf = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * f;
		float leaf = (1.0 - smoothstep(0.18, 0.24, length(lf * vec2(1.0, 2.1)))) * step(0.35, h) * step(r, 0.95);
		a = max(blot * 0.3, leaf);
		col = mix(col * 0.6, col * (0.8 + 0.5 * h), leaf);
	} else if (v_kind == 3) {
		// Shadow stain: an ink smudge with a faint violet glow that fades first.
		a = blot * (0.75 + 0.25 * n);
		col = col * (0.5 + 0.5 * n);
		emit = vec3(0.5, 0.15, 0.9) * (1.0 - smoothstep(0.2, 0.9, r)) * v_glow * 0.4;
	} else if (v_kind == 4) {
		// Rubble stain: broken dirt with darker stones.
		float stones = step(0.68, vnoise(p * 7.0 + v_seed * 3.0));
		a = blot * (0.7 + 0.3 * n);
		col = mix(col * (0.75 + 0.35 * n), col * 0.45, stones);
	} else {
		a = blot * 0.7 * (0.6 + 0.4 * n);
	}
	ALBEDO = col;
	EMISSION = emit;
	ROUGHNESS = v_kind == 1 ? 0.6 : 0.95;
	ALPHA = clamp(a * v_col.a, 0.0, 1.0);
}
