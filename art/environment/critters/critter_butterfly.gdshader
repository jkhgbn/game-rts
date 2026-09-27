// critter_butterfly.gdshader - cosmetic butterflies (task 12.V16). Mesh: critter_meshes.gd butterfly() (faces +Z,
// wingspan ~0.44 m). Fully shader-driven: the CPU writes an instance once (anchor = the flower patch spot).
// Vertex data: UV.x bone (0 body, 1 forewing, 2 hindwing), UV.y wing edge (0 at the root .. 1 on the rim),
//   UV2.x part (0 body, 1 forewing, 2 hindwing), UV2.y side (-1 / +1).
// INSTANCE_CUSTOM = (seed 0-1, palette 0-3, loop radius m, cruise height m).
// Motion: an erratic Lissajous loop around the anchor (within the radius, < 3 m), bobbing with every wing beat; every
// 8-13 s it settles for ~2.4 s low on the flowers, wings held up and slowly opening / closing.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

#include "res://art/environment/critters/critter_common.gdshaderinc"

// 4 palettes x (base, dark border, spot) sRGB: orange, sky blue, lemon, rose-white.
const vec3 WING[12] = {
	vec3(0.98, 0.50, 0.08), vec3(0.10, 0.05, 0.03), vec3(1.00, 0.96, 0.86),
	vec3(0.30, 0.64, 1.00), vec3(0.04, 0.08, 0.22), vec3(0.92, 0.97, 1.00),
	vec3(1.00, 0.90, 0.22), vec3(0.24, 0.16, 0.04), vec3(1.00, 0.55, 0.12),
	vec3(1.00, 0.88, 0.94), vec3(0.58, 0.22, 0.46), vec3(0.95, 0.40, 0.62)
};
const float REST_TIME = 2.4;

varying vec3 v_lp;
varying float v_edge;
varying flat int v_pal;
varying flat int v_part;

void vertex() {
	float s = basis_scale(MODEL_MATRIX);
	v_lp = VERTEX;
	v_edge = UV.y;
	v_part = int(UV2.x + 0.5);
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(PARKED, 1.0)).xyz;
		NORMAL = vec3(0.0, 1.0, 0.0);
		v_pal = 0;
	} else {
		vec3 anchor = MODEL_MATRIX[3].xyz;
		vec4 c = INSTANCE_CUSTOM;
		float seed = c.x;
		v_pal = clamp(int(c.y + 0.5), 0, 3);
		float t = clock + seed * 97.0;
		float P = 8.0 + seed * 5.0;
		float cyc = floor(t / P);
		float ft = t - cyc * P;
		float fly_t = cyc * (P - REST_TIME) + min(ft, P - REST_TIME);
		float rest = smoothstep(P - REST_TIME, P - REST_TIME + 0.5, ft) * (1.0 - smoothstep(P - 0.45, P, ft));
		float u = fly_t * 0.55;
		float a1 = seed * 11.0;
		float a2 = seed * 23.0;
		vec2 xz = c.z * vec2(sin(u * 0.83 + a1), sin(u * 0.61 + a2) * 0.8 + sin(u * 1.7 + a1) * 0.2);
		vec2 dxz = c.z * vec2(0.83 * cos(u * 0.83 + a1), 0.61 * 0.8 * cos(u * 0.61 + a2) + 1.7 * 0.2 * cos(u * 1.7 + a1));
		float beat = clock * (36.0 + seed * 10.0) + seed * 40.0;
		float fl = 0.5 + 0.5 * sin(beat);
		float y_fly = c.w + 0.30 * sin(u * 2.9 + seed * 5.0) + 0.12 * sin(u * 7.3) + 0.05 * fl;
		float y = mix(y_fly, 0.32 + 0.06 * seed, rest);
		vec3 pos = anchor + vec3(xz.x, y, xz.y);
		float yaw = atan(dxz.x, dxz.y) + rest * (seed - 0.5) * 1.2;
		float wing = mix(0.12 + 1.3 * fl, 1.15 + 0.3 * sin(clock * 1.7 + seed * 8.0), rest);
		float pitch = mix(-0.35 - 0.1 * fl, -0.12, rest);
		int bone = int(UV.x + 0.5);
		float sd = UV2.y;
		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (bone > 0) {
			float w = bone == 2 ? wing * 0.9 - 0.05 : wing;
			p = rot_z(p, sd * w);
			n = rot_z(n, sd * w);
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
	vec3 col;
	if (v_part == 0) {
		col = srgb(vec3(0.10, 0.08, 0.07));
	} else {
		vec3 base = srgb(WING[v_pal * 3]);
		vec3 dark = srgb(WING[v_pal * 3 + 1]);
		vec3 spot = srgb(WING[v_pal * 3 + 2]);
		col = base * mix(0.72, 1.08, smoothstep(0.0, 0.55, v_edge));
		float border = smoothstep(0.74, 0.82, v_edge);
		col = mix(col, dark, border);
		// A row of pale dots in the border, and a dark cell mark on the forewing.
		float ang = atan(v_lp.z, abs(v_lp.x));
		float dots = step(0.55, sin(ang * 24.0)) * step(0.87, v_edge) * step(v_edge, 0.97);
		col = mix(col, spot, dots * border);
		if (v_part == 1) {
			float cell = 1.0 - smoothstep(0.018, 0.026, length(v_lp.xz - vec2(sign(v_lp.x) * 0.12, 0.085)));
			col = mix(col, dark, cell * 0.85);
		}
		if (!FRONT_FACING) {
			col *= 0.78;   // paler, duller underside
		}
	}
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col;
	EMISSION = col * 0.12 + rim * rim_color * rim_strength * 0.5;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;   // thin wings: lit from either side
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
