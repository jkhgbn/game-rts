// critter_bird.gdshader - cosmetic bird flocks (task 12.V16): 3 flocks x 6 (instance i belongs to flock i / 6:
// 0 = crows, 1 = finches, 2 = bluewings). Mesh: critter_meshes.gd bird() (faces +Z, ~0.5 m long, wingspan ~0.7 m).
// Vertex data: UV.x bone (0 body, 1 inner wing, 2 outer wing, 3 head, 4 tail), UV.y rest height (m),
//   UV2.x part (0 back, 1 belly, 2 wing, 3 wing tip, 4 beak, 5 tail, 6 head), UV2.y side (-1 left, +1 right, 0 centre).
// INSTANCE_CUSTOM = (t0, mode, a, b), `tau` = clock - t0:
//   mode 0          on the ground at the origin (basis yaw): hops to a new little spot every 2-4 s, pecks, flicks the
//                   tail (offsets start at 0, so a switch to mode 0 never jumps)
//   mode 1 + H      take-off + circling at height H around the origin (the circle centre): a = start angle
//                   (atan2(z, x) from the centre), |b| = radius, sign(b) = direction. The bird starts exactly at
//                   centre + |b| (cos a, sin a), accelerates over ACCEL_TIME, climbs over RISE_TIME
//   mode 100 + y0   glide down to the origin (the landing spot) from origin + (a, y0, b); lands with a flare
// CritterSystem mirrors FLY_SPEED / ACCEL_TIME / RISE_TIME / the bob and the glide duration (bird position for fog
// and hand-offs): keep them in sync (BIRD_* constants there).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

#include "res://art/environment/critters/critter_common.gdshaderinc"

const float FLY_SPEED = 6.5;
const float ACCEL_TIME = 0.8;
const float RISE_TIME = 2.4;

// 3 flocks x 7 parts: back, belly, wing, wing tip, beak, tail, head (sRGB).
const vec3 PAL[21] = {
	// crows: blue-black, a lighter slate breast, pale bill
	vec3(0.13, 0.13, 0.19), vec3(0.24, 0.24, 0.30), vec3(0.10, 0.11, 0.17), vec3(0.05, 0.05, 0.08),
	vec3(0.45, 0.42, 0.36), vec3(0.08, 0.08, 0.12), vec3(0.14, 0.14, 0.21),
	// finches: warm brown back, orange breast, dark tips, yellow bill, black cap
	vec3(0.52, 0.34, 0.20), vec3(0.98, 0.52, 0.18), vec3(0.40, 0.27, 0.16), vec3(0.14, 0.11, 0.09),
	vec3(0.95, 0.78, 0.32), vec3(0.28, 0.20, 0.13), vec3(0.16, 0.13, 0.12),
	// bluewings: cobalt back and wings, cream belly, blue head
	vec3(0.22, 0.42, 0.78), vec3(0.95, 0.90, 0.74), vec3(0.16, 0.32, 0.72), vec3(0.07, 0.10, 0.22),
	vec3(0.22, 0.20, 0.18), vec3(0.12, 0.20, 0.40), vec3(0.26, 0.48, 0.86)
};

varying vec3 v_col;
varying float v_grad;

vec2 hop_off(float k, float id) {
	if (k < 0.5) {
		return vec2(0.0);
	}
	return (vec2(hash1(vec2(k, id * 1.3 + 0.7)), hash1(vec2(id * 0.9 + 2.1, k))) - 0.5) * 0.8;
}

float hop_yaw(float k, float id) {
	if (k < 0.5) {
		return 0.0;
	}
	return (hash1(vec2(k * 1.7, id + 5.3)) - 0.5) * 2.6;
}

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(PARKED, 1.0)).xyz;
		NORMAL = vec3(0.0, 1.0, 0.0);
		v_col = vec3(0.0);
		v_grad = 0.0;
	} else {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		float rest_yaw = basis_yaw(MODEL_MATRIX);
		float id = float(INSTANCE_ID);
		int flock = min(INSTANCE_ID / 6, 2);
		int bone = int(UV.x + 0.5);
		int part = int(UV2.x + 0.5);
		float sd = UV2.y;
		v_col = srgb(PAL[flock * 7 + part]);
		v_grad = clamp((UV.y - 0.04) / 0.10, 0.0, 1.0);

		vec4 c = INSTANCE_CUSTOM;
		float tau = max(clock - c.x, 0.0);
		float mode = c.y;
		float flap_rate = flock == 0 ? 27.0 : 36.0;   // crows beat slower
		float ph = clock * flap_rate + hid(id, 1.0) * TAU;
		vec3 pos;
		float yaw;
		float pitch = 0.0;
		float roll = 0.0;
		float fold = 1.0;
		float flap = 0.0;
		float head = 0.0;
		float tail = 0.0;
		if (mode < 0.5) {
			// On the ground: a hop to a new little spot at the start of each cycle, two pecks, a tail flick.
			float L = 2.0 + hid(id, 2.0) * 1.8;
			float k = floor(tau / L);
			float f = tau - k * L;
			float hp = smoothstep(0.0, 0.2, f);
			vec2 o = mix(hop_off(k - 1.0, id), hop_off(k, id), hp);
			yaw = rest_yaw + mix(hop_yaw(k - 1.0, id), hop_yaw(k, id), hp);
			float hy = (k > 0.5 ? 1.0 : 0.0) * sin(clamp(f / 0.2, 0.0, 1.0) * PI) * 0.07;
			pos = anchor + vec3(o.x, hy, o.y);
			float pk = clamp((f - 0.45) / 0.9, 0.0, 1.0);
			head = pow(max(sin(pk * 4.0 * PI), 0.0), 0.7) * 0.95;
			pitch = head * 0.30;
			tail = max(sin(f * 9.0), 0.0) * (1.0 - step(0.35, f)) * 0.5 + head * 0.25;
		} else if (mode < 99.5) {
			// Take-off, then circling.
			float H = mode - 1.0;
			float r = max(abs(c.w), 0.5);
			float dir = c.w < 0.0 ? -1.0 : 1.0;
			float dist = tau < ACCEL_TIME ? FLY_SPEED * tau * tau / (2.0 * ACCEL_TIME) : FLY_SPEED * (tau - ACCEL_TIME * 0.5);
			float ang = c.z + dir * dist / r;
			float rise = smoothstep(0.0, 1.0, tau / RISE_TIME);
			float bob = sin(clock * 1.3 + id * 1.7) * 0.35 * rise;
			pos = anchor + vec3(cos(ang) * r, H * rise + bob, sin(ang) * r);
			vec2 tng = dir * vec2(-sin(ang), cos(ang));
			yaw = atan(tng.x, tng.y);
			roll = dir * 0.42 * rise;
			pitch = -0.6 * (1.0 - rise) * smoothstep(0.0, 0.25, tau);
			fold = 1.0 - smoothstep(0.0, 0.22, tau);
			float glide = smoothstep(0.25, 0.7, sin(clock * 0.9 + id * 2.3)) * rise;
			flap = mix(1.0, 0.1, glide);
		} else {
			// Glide down to the landing spot, flare, fold.
			float y0 = mode - 100.0;
			vec2 d = c.zw;
			float T = clamp(2.0 * length(d) / FLY_SPEED, 1.6, 5.0);
			float e = clamp(tau / T, 0.0, 1.0);
			float ex = e * (2.0 - e);
			pos = anchor + vec3(d.x * (1.0 - ex), y0 * (1.0 - e) * (1.0 - e), d.y * (1.0 - ex));
			yaw = length(d) > 0.001 ? atan(-d.x, -d.y) : rest_yaw;
			float flare = smoothstep(0.72, 0.92, e) * (1.0 - smoothstep(0.96, 1.0, e));
			pitch = -0.75 * flare + 0.12 * (1.0 - e);
			fold = smoothstep(0.95, 1.0, e);
			flap = mix(0.12, 1.0, flare);
		}
		float th1 = flap * (0.22 + 0.85 * sin(ph)) + 0.10;
		float th2 = flap * 0.5 * sin(ph - 0.9);

		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (bone == 1 || bone == 2) {
			vec3 S = vec3(sd * 0.04, 0.105, 0.0);
			vec3 EL = vec3(sd * 0.18, 0.105, 0.0);
			vec3 sp = p;
			vec3 sn = n;
			if (bone == 2) {
				sp = rot_z(sp - EL, sd * th2) + EL;
				sn = rot_z(sn, sd * th2);
			}
			sp = rot_z(sp - S, sd * th1) + S;
			sn = rot_z(sn, sd * th1);
			// Folded: the span laid back along the flank, tips crossing over the tail.
			vec3 v = p - S;
			float ax = abs(v.x);
			vec3 fp = S + vec3(sd * (0.012 + ax * 0.10), v.y + 0.006 - ax * 0.07, v.z * 0.45 - ax * 0.66);
			p = mix(sp, fp, fold);
			n = normalize(mix(sn, vec3(sd * 0.7, 0.7, 0.0), fold));
		} else if (bone == 3) {
			vec3 N = vec3(0.0, 0.10, 0.09);
			p = rot_x(p - N, head) + N;
			n = rot_x(n, head);
		} else if (bone == 4) {
			vec3 Tp = vec3(0.0, 0.085, -0.11);
			p = rot_x(p - Tp, -tail) + Tp;
			n = rot_x(n, -tail);
		}
		vec3 B = vec3(0.0, 0.08, 0.0);
		p = rot_z(rot_x(p - B, pitch), roll) + B;
		n = rot_z(rot_x(n, pitch), roll);
		vec3 wp = pos + rot_y(p * s, yaw);
		vec3 wn = rot_y(n, yaw);
		VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
		NORMAL = normalize(mat3(VIEW_MATRIX) * wn);
	}
}

void fragment() {
	vec3 albedo = v_col * mix(0.72, 1.12, v_grad);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	EMISSION = rim * rim_color * rim_strength * (0.25 + albedo);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
