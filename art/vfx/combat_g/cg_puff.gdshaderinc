// G-D combat feedback (CombatFxG): soft camera-facing puffs (dust, smoke, frost steam, shadow wisps, spores) in ONE
// MultiMesh draw call per blend (cg_puff_mix / cg_puff_add). Written once at spawn, animated from `now`.
// Instance layout (12 floats): origin = start point, basis.x = start velocity,
//   basis.y = (start size m, gravity m/s2 (negative = rises), drag 1/s), basis.z = (ground y, lifetime s, growth)
//   INSTANCE_CUSTOM = (start time, seed, fade-in fraction, top light 0-1); COLOR = rgb, a = peak opacity.
// Shape: a lumpy disc (3 + 5 lobes from the seed), lighter on top, soft edge; it grows (size x (0.55 + growth x
// sqrt(k))), turns slowly and fades in fast / out slowly.

uniform float now = 0.0;

varying vec2 v_uv;
varying vec4 v_col;
varying float v_seed;
varying float v_top;

void vertex() {
	vec3 vel = MODEL_MATRIX[0].xyz;
	vec3 sgd = MODEL_MATRIX[1].xyz;
	vec3 glg = MODEL_MATRIX[2].xyz;
	vec3 p0 = MODEL_MATRIX[3].xyz;
	float t = now - INSTANCE_CUSTOM.x;
	float life = max(glg.y, 0.001);
	float k = clamp(t / life, 0.0, 1.0);
	float drag = max(sgd.z, 0.01);
	vec3 pos = p0 + vel * (1.0 - exp(-drag * max(t, 0.0))) / drag;
	pos.y -= 0.5 * sgd.y * t * t;
	float size = sgd.x * (0.55 + glg.z * sqrt(k));
	pos.y = max(pos.y, glg.x + size * 0.3);
	vec3 c = (VIEW_MATRIX * vec4(pos, 1.0)).xyz;
	float a = INSTANCE_CUSTOM.y * 6.2831 + k * (INSTANCE_CUSTOM.y - 0.5) * 1.6;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vec3 p = c + vec3(q * size, 0.0);
	if (t < 0.0 || t >= life) {
		p = c;
	}
	VERTEX = p;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_uv = UV;
	float fin = smoothstep(0.0, max(INSTANCE_CUSTOM.z, 0.01), k);
	v_col = vec4(COLOR.rgb, COLOR.a * fin * pow(1.0 - k, 1.3));
	v_seed = INSTANCE_CUSTOM.y;
	v_top = INSTANCE_CUSTOM.w;
}

float puff_shape(vec2 uv, float seed) {
	vec2 p = (uv - 0.5) * 2.0;
	float r = length(p);
	float th = atan(p.y, p.x);
	float edge = 0.78 + 0.1 * sin(th * 3.0 + seed * 19.0) + 0.06 * sin(th * 5.0 + seed * 41.0);
	float body = 1.0 - smoothstep(edge * 0.3, edge, r);
	// Two inner lumps so a big dust cloud is not a flat disc.
	vec2 l1 = vec2(cos(seed * 23.0), sin(seed * 23.0)) * 0.32;
	vec2 l2 = vec2(cos(seed * 57.0 + 2.0), sin(seed * 57.0 + 2.0)) * 0.36;
	float lumps = exp(-dot(p - l1, p - l1) * 7.0) + exp(-dot(p - l2, p - l2) * 9.0);
	return clamp(body * (0.7 + 0.3 * lumps), 0.0, 1.0);
}
