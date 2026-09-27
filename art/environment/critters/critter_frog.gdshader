// critter_frog.gdshader - cosmetic frogs on the banks (task 12.V16). Mesh: critter_meshes.gd frog() (sitting, faces
// +Z, ~0.3 m long). Vertex data: UV.x bone (0 body, 1 / 2 thigh L / R, 3 / 4 shin + foot L / R, 5 / 6 front leg L / R,
//   7 throat), UV.y rest height (m), UV2.x part (0 back, 1 belly, 2 eye, 3 leg, 4 spot), UV2.y side.
// Origin = the bank spot (y 0), basis yaw = the rest facing. INSTANCE_CUSTOM = (t0, mode, dx, dz), tau = clock - t0:
//   mode 0  sit: breathing throat, a small turn-hop in place every 7-11 s (offsets start at 0)
//   mode 1  jump into the water at origin + (dx, WATER_Y, dz): 0.12 s crouch while turning to face it, 0.55 s leap
//           (legs trailing), then it sinks below the surface (the CPU parks it after JUMP_END)
//   mode 2  come back: emerges at origin + (dx, WATER_Y, dz) (0.5 s), then hops onto the bank (0.5 s), facing land
// Palette per instance (INSTANCE_ID): green, olive-brown, teal.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

#include "res://art/environment/critters/critter_common.gdshaderinc"

const float WATER_Y = -0.35;
const float CROUCH = 0.12;
const float LEAP = 0.55;
// 3 palettes x 5 parts: back, belly, eye, leg, spot (sRGB).
const vec3 PAL[15] = {
	vec3(0.36, 0.66, 0.16), vec3(0.86, 0.86, 0.46), vec3(0.98, 0.76, 0.18), vec3(0.28, 0.54, 0.13), vec3(0.20, 0.40, 0.09),
	vec3(0.52, 0.46, 0.20), vec3(0.88, 0.80, 0.52), vec3(0.96, 0.62, 0.16), vec3(0.42, 0.36, 0.16), vec3(0.32, 0.26, 0.10),
	vec3(0.20, 0.58, 0.46), vec3(0.80, 0.90, 0.62), vec3(1.00, 0.82, 0.30), vec3(0.15, 0.46, 0.36), vec3(0.10, 0.34, 0.26)
};

varying vec3 v_col;
varying float v_grad;
varying flat int v_part;

float hop_yaw(float k, float id) {
	if (k < 0.5) {
		return 0.0;
	}
	return (hash1(vec2(k * 1.3, id + 2.9)) - 0.5) * 1.3;
}

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	v_part = int(UV2.x + 0.5);
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(PARKED, 1.0)).xyz;
		NORMAL = vec3(0.0, 1.0, 0.0);
		v_col = vec3(0.0);
		v_grad = 0.0;
	} else {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		float rest_yaw = basis_yaw(MODEL_MATRIX);
		float id = float(INSTANCE_ID);
		int pal = int(hid(id, 4.0) * 2.999);
		v_col = srgb(PAL[pal * 5 + v_part]);
		v_grad = clamp(UV.y / 0.12, 0.0, 1.0);
		vec4 c = INSTANCE_CUSTOM;
		float tau = max(clock - c.x, 0.0);
		float mode = c.y;
		vec2 d = c.zw;
		vec3 pos = anchor;
		float yaw = rest_yaw;
		float pitch = 0.0;
		float ext = 0.0;
		float sink = 0.0;
		float throat = 0.5 + 0.5 * sin(clock * 5.5 + id * 2.1);
		if (mode < 0.5) {
			float L = 7.0 + hid(id, 5.0) * 4.0;
			float k = floor(tau / L);
			float f = tau - k * L;
			float hp = smoothstep(0.0, 0.3, f);
			yaw = rest_yaw + mix(hop_yaw(k - 1.0, id), hop_yaw(k, id), hp);
			float arc = (k > 0.5 ? 1.0 : 0.0) * sin(clamp(f / 0.3, 0.0, 1.0) * PI);
			pos.y += arc * 0.09;
			ext = arc * 0.55;
			pitch = -arc * 0.25;
		} else if (mode < 1.5) {
			float jy = atan(d.x, d.y);
			if (tau < CROUCH) {
				float e = tau / CROUCH;
				yaw = mix_angle(rest_yaw, jy, smoothstep(0.0, 1.0, e));
				pitch = 0.18 * e;   // crouch, nose down
			} else {
				yaw = jy;
				float e = clamp((tau - CROUCH) / LEAP, 0.0, 1.0);
				float dist = length(d);
				pos += vec3(d.x * e, mix(0.0, WATER_Y, e) + 1.4 * e * (1.0 - e), d.y * e);
				float dy = WATER_Y + 1.4 * (1.0 - 2.0 * e);
				pitch = -atan(dy, max(dist, 0.05));
				ext = smoothstep(0.0, 0.15, e);
				sink = max(tau - CROUCH - LEAP, 0.0);
				pos.y -= min(sink * 1.2, 0.6);
			}
		} else {
			yaw = atan(-d.x, -d.y);
			if (tau < 0.5) {
				float e = smoothstep(0.0, 1.0, tau / 0.5);
				pos += vec3(d.x, WATER_Y - 0.26 * (1.0 - e), d.y);
				pitch = -0.35 * (1.0 - e);
			} else {
				float e = clamp((tau - 0.5) / 0.5, 0.0, 1.0);
				pos += vec3(d.x * (1.0 - e), mix(WATER_Y, 0.0, e) + 1.2 * e * (1.0 - e), d.y * (1.0 - e));
				ext = sin(e * PI);
				pitch = -atan(-WATER_Y + 1.2 * (1.0 - 2.0 * e), max(length(d), 0.05));
			}
		}

		int bone = int(UV.x + 0.5);
		float sd = UV2.y;
		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (bone == 1 || bone == 2 || bone == 3 || bone == 4) {
			vec3 hip = vec3(sd * 0.06, 0.06, -0.07);
			vec3 knee = vec3(sd * 0.115, 0.045, 0.015);
			if (bone >= 3) {
				p = rot_x(p - knee, -2.7 * ext) + knee;
				n = rot_x(n, -2.7 * ext);
			}
			p = rot_x(p - hip, 2.45 * ext) + hip;
			n = rot_x(n, 2.45 * ext);
		} else if (bone == 5 || bone == 6) {
			vec3 sh = vec3(sd * 0.055, 0.06, 0.06);
			p = rot_x(p - sh, -1.0 * ext) + sh;
			n = rot_x(n, -1.0 * ext);
		} else if (bone == 7) {
			p.y -= throat * 0.014;
			p.z += throat * 0.004;
		}
		vec3 B = vec3(0.0, 0.06, 0.0);
		p = rot_x(p - B, pitch) + B;
		n = rot_x(n, pitch);
		vec3 wp = pos + rot_y(p * s, yaw);
		vec3 wn = rot_y(n, yaw);
		VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
		NORMAL = normalize(mat3(VIEW_MATRIX) * wn);
	}
}

void fragment() {
	vec3 albedo = v_col * mix(0.70, 1.10, v_grad);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = rim * rim_color * rim_strength * (0.3 + albedo);
	if (v_part == 2) {
		emission += albedo * 0.5;   // wet, bright eyes
	} else {
		emission += rim * albedo * 0.5;   // wet skin sheen
	}
	ALBEDO = albedo;
	EMISSION = emission;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
