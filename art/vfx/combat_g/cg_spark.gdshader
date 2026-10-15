shader_type spatial;
// G-D combat feedback (CombatFxG): every spark / ember / glint streak of a fight in ONE MultiMesh draw call.
// A streak is a camera-facing ribbon from where the spark was `trail` seconds ago to where it is now, so fast
// sparks read as streaks and slow embers as dots. Written once at spawn, flown here from `now`.
// Instance layout (12 floats): origin = start point, basis.x = start velocity,
//   basis.y = (width m, gravity m/s2 (negative = rises), drag 1/s), basis.z = (trail s, lifetime s, ground y)
//   INSTANCE_CUSTOM = (start time, seed, flicker 0-1, 0); COLOR = HDR colour (alpha = strength).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

uniform float now = 0.0;

varying vec2 v_uv;
varying vec4 v_col;

vec3 fly(vec3 p0, vec3 vel, vec3 wgd, float t, float ground) {
	float drag = max(wgd.z, 0.01);
	vec3 p = p0 + vel * (1.0 - exp(-drag * t)) / drag;
	p.y -= 0.5 * wgd.y * t * t;
	p.y = max(p.y, ground + 0.03);
	return p;
}

void vertex() {
	vec3 vel = MODEL_MATRIX[0].xyz;
	vec3 wgd = MODEL_MATRIX[1].xyz;
	vec3 tlg = MODEL_MATRIX[2].xyz;
	vec3 p0 = MODEL_MATRIX[3].xyz;
	float t = now - INSTANCE_CUSTOM.x;
	float life = max(tlg.y, 0.001);
	float k = clamp(t / life, 0.0, 1.0);
	vec3 head = (VIEW_MATRIX * vec4(fly(p0, vel, wgd, max(t, 0.0), tlg.z), 1.0)).xyz;
	vec3 tail = (VIEW_MATRIX * vec4(fly(p0, vel, wgd, max(t - tlg.x, 0.0), tlg.z), 1.0)).xyz;
	vec3 along = head - tail;
	if (dot(along, along) < 0.0004) {
		along = vec3(0.0, 0.02, 0.0);
		tail = head - along;
	}
	vec3 side = normalize(cross(along, head)) * wgd.x * (1.0 - 0.5 * k);
	vec3 p = mix(tail, head, VERTEX.y + 0.5) + side * VERTEX.x * 2.0;
	if (t < 0.0 || t >= life) {
		p = head;
	}
	VERTEX = p;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_uv = UV;
	float flick = 1.0 - INSTANCE_CUSTOM.z * 0.5 * (1.0 + sin(now * 37.0 + INSTANCE_CUSTOM.y * 40.0));
	v_col = vec4(COLOR.rgb, COLOR.a * pow(1.0 - k, 1.4) * flick);
}

void fragment() {
	float across = 1.0 - abs(v_uv.x - 0.5) * 2.0;
	float head = mix(0.35, 1.0, 1.0 - v_uv.y);   // UV.y = 0 at the head (top of the quad)
	float a = clamp(across * across * head, 0.0, 1.0);
	ALBEDO = v_col.rgb * (0.7 + 0.6 * across * head);
	ALPHA = clamp(a * v_col.a, 0.0, 1.0);
}
