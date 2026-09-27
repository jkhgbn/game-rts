// greywater_lodge_pennant.gdshader - the Lodge's flags (task 10.V9). Two-sided cloth on a vertical PlaneMesh
// (orientation Z) whose UV.x = 0 edge is tied to the pole; the free end waves (more toward the tip).
//   shape 0  the guild pennant: long grey-green swallow-tail, dark hoist band and hems, a bone-white arrow emblem
//   shape 1  the contract flag: amber square flag with a dark hunting horn (raised by play_contract)
// Uniforms: shape, size (metres, for the emblem aspect), cloth_color, stripe_color, emblem_color, emblem_energy,
// amplitude, speed, rim_color, rim_strength; instance uniform phase.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform int shape = 0;
uniform vec2 size = vec2(1.3, 0.56);
uniform vec3 cloth_color : source_color = vec3(0.36, 0.52, 0.40);
uniform vec3 stripe_color : source_color = vec3(0.17, 0.26, 0.20);
uniform vec3 emblem_color : source_color = vec3(0.90, 0.85, 0.72);
uniform float emblem_energy = 0.25;
uniform float amplitude = 0.13;
uniform float speed = 3.2;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;
instance uniform float phase = 0.0;

void vertex() {
	float w = UV.x;
	VERTEX.z += sin(TIME * speed - UV.x * 5.5 + phase) * amplitude * w;
	VERTEX.y += sin(TIME * speed * 0.53 - UV.x * 3.0 + phase) * amplitude * 0.25 * w;
}

float seg_d(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	vec2 p = vec2(u * size.x, v * size.y);
	vec3 col = cloth_color;
	float emblem = 0.0;
	if (shape == 0) {
		// Tapering swallow-tail.
		float half_h = 0.5 * (1.0 - 0.42 * u);
		if (abs(v - 0.5) > half_h) {
			discard;
		}
		if (u > 0.8 && abs(v - 0.5) < (u - 0.8) / 0.2 * 0.3) {
			discard;
		}
		col *= 0.93 + 0.07 * sin(u * 23.0 + v * 3.0);
		float hem = step(half_h - 0.07, abs(v - 0.5));
		col = mix(col, stripe_color, max(hem, step(u, 0.1)));
		// Arrow emblem pointing to the tip: shaft, head, fletching.
		vec2 c = vec2(0.0, 0.5 * size.y);
		float d = seg_d(p, vec2(0.22 * size.x, c.y), vec2(0.58 * size.x, c.y)) - 0.028;
		vec2 tip = vec2(0.66 * size.x, c.y);
		vec2 q = p - tip;
		float head = max(-q.x - 0.13, abs(q.y) * 1.35 + q.x);
		d = min(d, head);
		for (int i = 0; i < 2; i++) {
			float x0 = (0.22 + 0.06 * float(i)) * size.x;
			d = min(d, seg_d(vec2(p.x, abs(p.y - c.y)), vec2(x0, 0.0), vec2(x0 - 0.07, 0.085)) - 0.022);
		}
		float aa = max(fwidth(d), 0.002);
		emblem = 1.0 - smoothstep(-aa, aa, d);
	} else {
		// Square contract flag with a dark border and a hunting horn.
		col *= 0.93 + 0.07 * sin(u * 17.0 + v * 2.0);
		float border = 1.0 - step(0.08, u) * step(u, 0.93) * step(0.1, v) * step(v, 0.9);
		col = mix(col, stripe_color, border);
		// UV.y grows downward: the horn is the lower half of a crescent (thick at the bottom, thin at the tips),
		// a flared bell on the left tip, the mouthpiece on the right.
		vec2 c = vec2(0.52 * size.x, 0.4 * size.y);
		float r = 0.2 * size.y + 0.08;
		float outer = length(p - c) - r;
		float inner = length(p - (c + vec2(0.0, -0.09))) - (r - 0.02);
		float crescent = max(outer, -inner);
		crescent = max(crescent, (c.y - p.y) - 0.02);
		vec2 bell_c = c + vec2(-r + 0.02, -0.02);
		float bell = max(length(p - bell_c) - 0.085, p.y - bell_c.y - 0.01);
		float mouth = length(p - (c + vec2(r - 0.01, -0.03))) - 0.035;
		float d = min(min(crescent, bell), mouth);
		float aa = max(fwidth(d), 0.002);
		emblem = 1.0 - smoothstep(-aa, aa, d);
	}
	col = mix(col, emblem_color, emblem);
	col *= mix(0.84, 1.04, smoothstep(0.0, 0.25, u));
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = col;
	EMISSION = emblem_color * emblem * emblem_energy + rim_color * rim * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
