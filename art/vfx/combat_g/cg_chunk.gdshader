shader_type spatial;
// G-D combat feedback (CombatFxG, docs/art/gd_combat_feedback.md): every solid bit of a fight in ONE MultiMesh draw
// call: steel / bone / stone chips, wood splinters, ice shards, leaves that settle, building debris and rubble.
// The script writes an instance ONCE when it spawns; the shader flies it from `now` (one uniform per frame):
// drag-damped ballistic flight, tumble that settles, rest on the ground, then shrink + sink away at the end.
// Instance layout (a non-orthogonal "transform" used as 12 floats):
//   origin = start point, basis.x = start velocity (m/s), basis.y = (size m, gravity m/s2, drag 1/s),
//   basis.z = (ground y, lifetime s, spin rad/s)
//   INSTANCE_CUSTOM = (start time, stretch (>1 long splinter / shard, <1 flat flake), seed, glow 0-1)
//   COLOR = albedo rgb, a = gloss (0 matte stone / wood, 1 wet ice).
render_mode cull_disabled, skip_vertex_transform, shadows_disabled;

uniform float now = 0.0;

varying vec3 v_col;
varying float v_gloss;
varying float v_glow;

vec3 rodrigues(vec3 v, vec3 axis, float a) {
	float c = cos(a);
	float s = sin(a);
	return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0 - c);
}

void vertex() {
	vec3 vel = MODEL_MATRIX[0].xyz;
	vec3 sgd = MODEL_MATRIX[1].xyz;
	vec3 gls = MODEL_MATRIX[2].xyz;
	vec3 p0 = MODEL_MATRIX[3].xyz;
	float t = now - INSTANCE_CUSTOM.x;
	float life = max(gls.y, 0.001);
	float k = t / life;
	float drag = max(sgd.z, 0.01);
	float e = (1.0 - exp(-drag * max(t, 0.0))) / drag;
	vec3 pos = p0 + vel * e;
	pos.y -= 0.5 * sgd.y * t * t;
	float size = sgd.x * (1.0 - smoothstep(0.78, 1.0, k));
	float rest = gls.x + size * 0.3;
	pos.y = max(pos.y, rest) - smoothstep(0.82, 1.0, k) * size * 0.6;
	float seed = INSTANCE_CUSTOM.z;
	vec3 axis = normalize(vec3(sin(seed * 12.9898) + 0.01, cos(seed * 78.233), sin(seed * 37.719 + 1.3)));
	// Tumbles while it flies, settles once drag has eaten the throw (e saturates).
	float ang = seed * 6.2831 + gls.z * e;
	float stretch = max(INSTANCE_CUSTOM.y, 0.05);
	vec3 local = VERTEX * vec3(1.0, stretch, 1.0) * size;
	vec3 world = pos + rodrigues(local, axis, ang);
	vec3 n = rodrigues(normalize(NORMAL / vec3(1.0, stretch, 1.0)), axis, ang);
	if (t < 0.0 || t >= life) {
		world = p0;   // not started / finished: collapse to a point (no pixels)
	}
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = normalize(mat3(VIEW_MATRIX) * n);
	v_col = COLOR.rgb;
	v_gloss = COLOR.a;
	// Glow (embers on Fire debris, a cold sheen on ice) cools over the first 60 % of the life.
	v_glow = INSTANCE_CUSTOM.w * (1.0 - smoothstep(0.0, 0.6, k));
}

void fragment() {
	ALBEDO = v_col;
	ROUGHNESS = mix(0.95, 0.12, v_gloss);
	SPECULAR = mix(0.3, 0.8, v_gloss);
	METALLIC = 0.0;
	EMISSION = v_col * v_glow * 2.2 + vec3(1.0, 0.35, 0.05) * v_glow * step(v_col.b, v_col.r) * 1.5;
}
