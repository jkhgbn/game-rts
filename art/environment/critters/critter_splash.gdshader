// critter_splash.gdshader - water splashes (task 12.V16): the optional leaping fish and the frogs' dives. A small pool
// of instances; the CPU writes one per event. Mesh: critter_meshes.gd splash(): parts in UV2.x (1 ring A, 2 ring B,
// 3 droplets A, 4 droplets B, 5 fish), UV.x = droplet index (0-5), UV.y = rest height (fish gradient).
// Origin = a point on the water surface (y = WATER_Y), basis yaw = the leap direction.
// INSTANCE_CUSTOM = (t0, mode, -, -): nothing shows before t0; mode 1 = fish: it leaves the water at z -0.55 (ring A +
// droplets A), arcs 0.5 m up and dives at z +0.55 (ring B + droplets B at 0.85 s); mode 0 = a plain splash at the
// origin (ring B + droplets B). Everything is gone after ~2 s (the CPU parks the instance at t0 + LIFETIME).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://art/environment/critters/critter_common.gdshaderinc"

uniform vec3 foam_color : source_color = vec3(0.88, 0.96, 1.0);
uniform vec3 fish_back : source_color = vec3(0.24, 0.36, 0.30);
uniform vec3 fish_belly : source_color = vec3(0.86, 0.88, 0.80);
const float FISH_TIME = 0.85;

varying float v_alpha;
varying float v_fish;
varying float v_grad;
varying float v_ring;

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	int part = int(UV2.x + 0.5);
	v_fish = part == 5 ? 1.0 : 0.0;
	v_grad = part == 5 ? clamp((UV.y + 0.05) / 0.10, 0.0, 1.0) : UV.y;   // fish: height; rings: 0 inner .. 1 outer
	v_ring = (part == 1 || part == 2) ? 1.0 : 0.0;
	v_alpha = 0.0;
	vec3 wp = PARKED;
	vec3 wn = vec3(0.0, 1.0, 0.0);
	vec3 drop_view = vec3(0.0);
	bool is_drop = false;
	vec4 c = INSTANCE_CUSTOM;
	float tau = clock - c.x;
	bool fish = c.y > 0.5;
	if (s >= 0.0001 && tau >= 0.0 && tau < 2.2) {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		float yaw = basis_yaw(MODEL_MATRIX);
		float id = float(INSTANCE_ID);
		bool is_a = part == 1 || part == 3;
		// Event A: the fish leaves the water (fish mode only). Event B: the dive (fish) or the plain splash.
		vec3 centre = fish ? vec3(0.0, 0.0, is_a ? -0.55 : 0.55) : vec3(0.0);
		float start = (fish && !is_a) ? FISH_TIME : 0.0;
		float age = tau - start;
		bool on = age >= 0.0 && (fish || !is_a) && part != 5;
		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (part == 5) {
			if (fish && tau < FISH_TIME + 0.1) {
				float u = clamp(tau / FISH_TIME, 0.0, 1.0);
				vec3 bp = vec3(0.0, -0.22 + 0.72 * sin(u * PI), mix(-0.55, 0.55, u));
				float pitch = -atan(0.72 * PI * cos(u * PI), 1.1);
				float wig = sin(clock * 30.0) * 0.35 * (1.0 - smoothstep(-0.16, -0.02, p.z));
				float roll = sin(u * PI * 2.0) * 0.4;
				p = rot_z(rot_y(p, wig), roll);
				n = rot_z(rot_y(n, wig), roll);
				p = rot_x(p, pitch) + bp;
				n = rot_x(n, pitch);
				v_alpha = 1.0;
				wp = anchor + rot_y(p * s, yaw);
				wn = rot_y(n, yaw);
			}
		} else if (on) {
			if (part <= 2) {
				// Ripple rings: grow fast then slow, fade out.
				float R = 0.10 + 1.05 * (1.0 - exp(-age * 2.3));
				p.xz *= R;
				v_alpha = smoothstep(0.0, 0.06, age) * (1.0 - smoothstep(0.2, 1.4, age)) * 0.7;
				wp = anchor + rot_y((p + centre) * s, yaw) + vec3(0.0, 0.015, 0.0);
			} else {
				// Droplets: a small crown thrown up and falling back.
				float i = UV.x;
				float a = i / 6.0 * TAU + hid(id + floor(c.x), i) * 0.8;
				float sp = 0.7 + hid(id, i + 3.0) * 0.5;
				vec3 dp = vec3(cos(a) * sp * age, 2.3 * age - 4.9 * age * age, sin(a) * sp * age);
				float sc = (1.0 - smoothstep(0.2, 0.55, age)) * (0.8 + hid(id, i) * 0.5);
				if (dp.y > -0.02 && sc > 0.0) {
					v_alpha = 0.95;
					// Camera-facing droplet: the centre in world space, the diamond offset in view space.
					vec3 dc = anchor + rot_y((centre + dp) * s, yaw);
					drop_view = (VIEW_MATRIX * vec4(dc, 1.0)).xyz + vec3(p.x, p.y, 0.0) * sc * 1.6;
					is_drop = true;
				}
			}
		}
	}
	if (v_alpha <= 0.0) {
		wp = PARKED;
	}
	if (is_drop) {
		VERTEX = drop_view;
		NORMAL = vec3(0.0, 0.0, 1.0);
	} else {
		VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
		NORMAL = normalize(mat3(VIEW_MATRIX) * wn);
	}
}

void fragment() {
	vec3 col;
	if (v_fish > 0.5) {
		col = mix(srgb(fish_belly), srgb(fish_back), v_grad);
		ALPHA = 1.0;
		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		EMISSION = rim * vec3(0.8, 0.9, 1.0) * 0.6;   // wet flash
	} else {
		col = srgb(foam_color);
		// Rings: soft inner edge, a brighter crest near the outer edge; droplets: solid.
		float band = v_ring > 0.5 ? smoothstep(0.0, 0.75, v_grad) * (1.0 - smoothstep(0.82, 1.0, v_grad)) : 1.0;
		ALPHA = v_alpha * band;
		EMISSION = col * 0.35;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
