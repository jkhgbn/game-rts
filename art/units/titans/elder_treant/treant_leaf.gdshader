// treant_leaf.gdshader - Elder Treant leaves, moss beard, blossoms and the team garland (task 13.V18). Painted
// style of unit_painted.gdshader; the colour block comes from the vertex COLOR (one material for every soft part):
//   rgb  albedo (leaf greens, moss greys, blossom pinks)
//   a    0 = leaf / moss, 0.5 = blossom (pale glancing edges + a faint glow of its own colour),
//        1 = team leaf (albedo = team_tint x COLOR.r)
// Leaf masses get painted lobes (noise cells), lighter tops / darker undersides, a yellow-green backlit rim and a
// small breeze (vertex), all in MODEL rest space. Instance uniforms: treant.gdshaderinc.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/units/titans/elder_treant/treant.gdshaderinc"

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float sway = 0.03;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.08;
uniform vec3 rim_color : source_color = vec3(0.78, 0.95, 0.45);
uniform float rim_strength = 0.2;
uniform vec3 heal_color : source_color = vec3(0.55, 1.00, 0.35);
uniform vec3 petal_edge : source_color = vec3(1.00, 0.93, 0.96);

varying vec3 v_obj;
varying vec3 v_objn;
varying vec3 v_world;

void vertex() {
	v_obj = VERTEX;
	v_objn = NORMAL;
	vec3 p = treant_morph(VERTEX, CUSTOM0);
	vec3 o = v_obj;
	p += vec3(sin(TIME * 1.4 + o.x * 2.1 + o.z * 1.3), 0.5 * sin(TIME * 1.9 + o.y * 2.7),
		cos(TIME * 1.2 + o.y * 1.7 + o.x * 0.9)) * sway * step(COLOR.a, 0.75);
	VERTEX = p;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(v_objn);
	float na = treant_triplanar(noise_tex, v_obj, n, 1.6);
	float nb = treant_triplanar(noise_tex, v_obj + vec3(7.1, 3.3, 1.9), n, 0.35);
	float blossom = 1.0 - abs(COLOR.a - 0.5) * 2.0;
	blossom = step(0.5, blossom);
	float team = step(0.75, COLOR.a);
	vec3 base = mix(treant_linear(COLOR.rgb), treant_linear(team_tint) * COLOR.r, team);
	vec3 albedo = base * (1.0 + (na - 0.5) * 0.26) * (1.0 + (nb - 0.5) * 0.14);
	// painted leaf lobes (not on petals)
	float lob = treant_triplanar(noise_tex, v_obj + vec3(2.2, 0.0, 4.4), n, 3.4);
	albedo *= mix(1.0, 0.82 + 0.34 * smoothstep(0.32, 0.68, lob), 1.0 - blossom);
	// light tops, dark undersides
	albedo *= mix(0.62, 1.12, smoothstep(-0.55, 0.85, n.y));

	vec3 emission = vec3(0.0);
	if (blossom > 0.5) {
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		albedo = mix(albedo, petal_edge, pow(1.0 - facing, 2.0) * 0.35);
		emission += base * 0.16;
	}

	float h = v_world.y - ao_bottom;
	albedo *= mix(0.78, 1.06, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.3, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength * (1.0 - blossom * 0.5);
	emission += (rim * 0.7 + pow(rim, 0.6) * 0.08) * heal_color * heal_glow * (0.75 + 0.25 * sin(TIME * 2.2)) * min(glow_boost, 1.0);

	vec3 tint = treant_flash_tint();
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.30, 0.40, d) * 0.55 + smoothstep(0.56, 0.66, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 14.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
