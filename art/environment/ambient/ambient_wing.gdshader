// ambient_wing.gdshader - G-D ambient flutterers (docs/art/gd_ambient.md), opaque meshes drawn by camera-following
// GPUParticles3D of AmbientLife (the fog overlay darkens them from the depth buffer like any mesh):
//   look 0 butterflies by day / moths at night: the critter butterfly mesh (critter_meshes.gd: UV.x bone 0 body,
//          1 fore wing, 2 hind wing; UV2.y side -1 / +1), wings beat about the body axis (+Z), flap-flap-glide.
//   look 1 leaves: a small folded leaf (AmbientLife._leaf_mesh: UV over the leaf, UV2.x 1 on the tip) tumbling
//          and swinging as it falls.
// Colour per particle from the palette uniforms (`night` turns butterflies into dusty pale moths; leaf_a / leaf_b /
// leaf_c are the season's leaf colours). The particle's scale ramp shrinks it in / out (opaque: no alpha fade).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert_wrap, specular_disabled;

#include "res://art/environment/ambient/ambient_common.gdshaderinc"

uniform int look = 0;
uniform float night = 0.0;
uniform vec3 leaf_a : source_color = vec3(0.42, 0.58, 0.20);
uniform vec3 leaf_b : source_color = vec3(0.70, 0.66, 0.24);
uniform vec3 leaf_c : source_color = vec3(0.30, 0.46, 0.16);
uniform float flap_rate = 13.0;

// Butterfly palettes (sRGB): wing, wing edge.
const vec3 WING[5] = {
	vec3(0.98, 0.55, 0.12), vec3(0.96, 0.94, 0.86), vec3(0.30, 0.55, 0.98), vec3(0.98, 0.84, 0.22),
	vec3(0.86, 0.36, 0.62)
};
const vec3 EDGE[5] = {
	vec3(0.16, 0.10, 0.06), vec3(0.55, 0.62, 0.30), vec3(0.08, 0.10, 0.25), vec3(0.45, 0.28, 0.06),
	vec3(0.30, 0.10, 0.28)
};

varying vec3 v_col;
varying float v_edge;

vec3 rot_z(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

vec3 rot_x(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

vec3 rot_y(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

void vertex() {
	float h = amb_pid(INSTANCE_ID, 3.0);
	if (look == 0) {
		float side = UV2.y;
		float bone = UV.x;
		// Flap-flap-glide: wings beat fast, then hold open for a moment.
		float t = TIME * (flap_rate * (0.85 + 0.3 * h)) + h * 40.0;
		float glide = smoothstep(0.55, 0.8, sin(TIME * 0.9 + h * 17.0));
		float beat = mix(0.5 + 0.5 * sin(t), 0.25, glide);
		float ang = side * mix(-0.25, 1.25, beat);
		if (bone > 1.5) {
			ang *= 0.85;   // hind wings lag a little
		}
		if (abs(side) > 0.5) {
			VERTEX = rot_z(VERTEX, ang);
			NORMAL = rot_z(NORMAL, ang);
		}
		// A small bob of the whole body with each beat.
		VERTEX.y += 0.03 * sin(t);
		int k = int(h * 4.999);
		vec3 day = WING[k];
		vec3 moth = mix(vec3(0.86, 0.82, 0.72), vec3(0.62, 0.58, 0.50), h);
		v_col = mix(day, moth, night);
		v_edge = mix(0.0, 1.0, step(0.5, abs(side)));
		if (bone < 0.5) {
			v_col = vec3(0.12, 0.10, 0.09);
			v_edge = 0.0;
		}
		vec3 ec = mix(EDGE[k], vec3(0.42, 0.38, 0.32), night);
		// Edge colour mixed in by the vertex distance from the body (outer rim of the wing fans).
		float rim = smoothstep(0.12, 0.22, length(VERTEX.xz));
		v_col = mix(v_col, ec, rim * v_edge * 0.75);
	} else {
		// Tumble + swing: spin about a tilted axis, rock side to side.
		float t = TIME * (1.6 + 1.8 * h) + h * 31.0;
		VERTEX = rot_x(rot_z(VERTEX, sin(t * 0.7) * 1.1), t);
		VERTEX = rot_y(VERTEX, h * 6.283);
		NORMAL = rot_y(rot_x(rot_z(NORMAL, sin(t * 0.7) * 1.1), t), h * 6.283);
		float k = amb_pid(INSTANCE_ID, 5.0);
		v_col = k < 0.45 ? leaf_a : (k < 0.8 ? leaf_b : leaf_c);
		v_col *= 0.85 + 0.3 * amb_pid(INSTANCE_ID, 6.0);
		v_edge = UV2.x;
	}
}

void fragment() {
	vec3 c = v_col;
	if (look == 1) {
		// Leaf outline: a pointed oval over UV, a darker midrib.
		vec2 q = UV * 2.0 - 1.0;
		float w = (1.0 - q.y * q.y) * (0.75 - 0.25 * q.y);
		if (abs(q.x) > w) {
			discard;
		}
		c *= 0.8 + 0.2 * smoothstep(0.0, 0.08, abs(q.x));
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	BACKLIGHT = c * 0.35;
}
