shader_type spatial;
// forge_evenmead heart-stone (E34.V1 stand-in in the set): Obren's cracked amber stone. Faceted dark amber with a
// warm inner light and bright hairline cracks that breathe (a slow heartbeat: two pulses, a rest). COLOR = facet tint.
// 0 lights: the glow is emission (+ the halo card beside it in the same part).
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 amber : source_color = vec3(0.95, 0.55, 0.12);
uniform vec3 core : source_color = vec3(1.0, 0.78, 0.35);
uniform float beat_rate = 0.75;

varying vec3 lp;

float hash1(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash1(i), hash1(i + vec3(1, 0, 0)), f.x), mix(hash1(i + vec3(0, 1, 0)), hash1(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash1(i + vec3(0, 0, 1)), hash1(i + vec3(1, 0, 1)), f.x), mix(hash1(i + vec3(0, 1, 1)), hash1(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float t = fract(TIME * beat_rate);
	float beat = exp(-pow((t - 0.1) * 14.0, 2.0)) + 0.7 * exp(-pow((t - 0.3) * 14.0, 2.0));
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	float n = vn(lp * 60.0);
	float crack = 1.0 - smoothstep(0.0, 0.06, abs(vn(lp * 34.0 + 3.1) - 0.5));
	crack *= smoothstep(0.3, 0.6, vn(lp * 20.0));
	ALBEDO = base * (0.7 + 0.3 * n);
	ROUGHNESS = 0.28;
	SPECULAR = 0.6;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	EMISSION = amber * (0.9 + 0.9 * beat) * (0.55 + 0.45 * fres) + core * crack * (2.5 + 5.0 * beat);
}
