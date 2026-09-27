// critter_dragonfly.gdshader - cosmetic dragonflies over the water (task 12.V16). Mesh: critter_meshes.gd dragonfly()
// (faces +Z, ~0.42 m long, wingspan ~0.5 m). The CPU writes an instance once: origin = a point on the water surface,
// basis yaw = the local river direction. INSTANCE_CUSTOM = (seed 0-1, palette 0-1, along amplitude m, across
// amplitude m). Motion: hover (tiny jitter) at a point, then a quick dart to the next point along the river, every
// 2.4-4 s; the body turns to the next dart before it goes. Wings: a fast 4-wing shimmer.
// Vertex data: UV.x bone (0 body, 1 forewing, 2 hindwing), UV.y span fraction on wings / rest height on the body,
//   UV2.x part (0 thorax, 1 abdomen, 2 abdomen ring, 3 eye, 4 wing), UV2.y side.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

#include "res://art/environment/critters/critter_common.gdshaderinc"

// 2 palettes x (thorax, abdomen, ring, eye) sRGB: blue-teal hawker, red darter.
const vec3 PAL[8] = {
	vec3(0.10, 0.46, 0.44), vec3(0.14, 0.52, 0.90), vec3(0.04, 0.08, 0.14), vec3(0.20, 0.85, 0.75),
	vec3(0.55, 0.22, 0.10), vec3(0.92, 0.26, 0.12), vec3(0.20, 0.06, 0.04), vec3(0.85, 0.35, 0.20)
};
uniform vec3 wing_color : source_color = vec3(0.82, 0.92, 0.98);

varying vec3 v_col;
varying float v_span;
varying flat int v_part;

vec2 dart_pt(float k, float id, vec2 amp) {
	return vec2((hash1(vec2(k, id + 0.3)) - 0.5) * 2.0 * amp.y, (hash1(vec2(id + 0.7, k)) - 0.5) * 2.0 * amp.x);
}

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	v_part = int(UV2.x + 0.5);
	v_span = UV.y;
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(PARKED, 1.0)).xyz;
		NORMAL = vec3(0.0, 1.0, 0.0);
		v_col = vec3(0.0);
	} else {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		float river_yaw = basis_yaw(MODEL_MATRIX);
		float id = float(INSTANCE_ID);
		vec4 c = INSTANCE_CUSTOM;
		float seed = c.x;
		int pal = clamp(int(c.y + 0.5), 0, 1);
		v_col = v_part < 4 ? srgb(PAL[pal * 4 + min(v_part, 3)]) : srgb(wing_color);
		vec2 amp = c.zw;
		float t = clock + seed * 71.0;
		float P = 2.4 + seed * 1.6;
		float k = floor(t / P);
		float f = t / P - k;
		vec2 p0 = dart_pt(k - 1.0, id, amp);
		vec2 p1 = dart_pt(k, id, amp);
		vec2 p2 = dart_pt(k + 1.0, id, amp);
		float m = smoothstep(0.64, 1.0, f);
		vec2 lp = mix(p1, p2, m);
		lp += vec2(sin(clock * 9.0 + seed * 3.0), sin(clock * 7.3 + seed * 5.0)) * 0.035 * (1.0 - m);
		float h1 = 0.42 + 0.22 * hash1(vec2(k, id + 9.1));
		float h2 = 0.42 + 0.22 * hash1(vec2(k + 1.0, id + 9.1));
		float y = mix(h1, h2, m) + sin(clock * 5.1 + seed * 7.0) * 0.03;
		vec2 hd = normalize(mix(p1 - p0, p2 - p1, smoothstep(0.0, 0.2, f)) + vec2(0.0001, 0.0));
		float yaw = river_yaw + atan(hd.x, hd.y);
		float pitch = 0.3 * m * (1.0 - m) * 4.0 - 0.06;
		vec3 pos = anchor + rot_y(vec3(lp.x, y, lp.y), river_yaw);

		int bone = int(UV.x + 0.5);
		float sd = UV2.y;
		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (bone > 0) {
			float w = sd * (0.10 + 0.34 * sin(clock * 92.0 + (bone == 2 ? 1.7 : 0.0) + seed * 9.0));
			vec3 root = vec3(sd * 0.012, 0.02, 0.0);
			p = rot_z(p - root, w) + root;
			n = rot_z(n, w);
		}
		// A slight droop of the long abdomen.
		if (v_part == 1 || v_part == 2) {
			p.y -= max(-p.z - 0.04, 0.0) * 0.12;
		}
		p = rot_x(p, pitch);
		n = rot_x(n, pitch);
		vec3 wp = pos + rot_y(p * s, yaw);
		vec3 wn = rot_y(n, yaw);
		VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
		NORMAL = normalize(mat3(VIEW_MATRIX) * wn);
	}
}

void fragment() {
	vec3 col = v_col;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = rim * rim_color * rim_strength * (0.3 + col);
	if (v_part == 4) {
		// Glassy wings: pale, a darker leading edge and a small dark tip mark, faintly bright.
		col *= mix(1.0, 0.55, smoothstep(0.86, 0.94, v_span));
		emission += col * 0.45;
	} else if (v_part == 3) {
		emission += col * 0.6;   // bright compound eyes (below the bloom threshold: no glow point)
	} else {
		emission += col * 0.12 + rim * col * 0.8;   // metallic sheen
	}
	ALBEDO = col;
	EMISSION = emission;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
