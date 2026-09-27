// waterfall.gdshader - the Hollowmere falls pouring out of the north cliffs (task 12.V5, map-fill.md 3.2 `lm_mouths`).
// Painted water curtain: dark teal glassy water at the lip, long white streaks that speed up as they fall, white water
// at the bottom, ragged sides that break into strands. Opaque (alpha-tested edges), lit with the painted toon ramp,
// no screen / depth reads, no vertex motion. ONE material (waterfall_mat.tres) for the main fall and the side
// trickle. Meshes are baked by art/environment/build_env.gd (river mouths section):
//   UV.x    metres across the sheet (0 = centre line)
//   UV.y    metres down the sheet from the lip (arc length)
//   UV2.x   the sheet's full length in metres (for the white water at the bottom)
//   COLOR.a 0 at the side edges -> 1 inside (the edges fray into strands)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 water_dark : source_color = vec3(0.07, 0.27, 0.27);
uniform vec3 water_light : source_color = vec3(0.26, 0.55, 0.51);
uniform vec3 lip_color : source_color = vec3(0.55, 0.78, 0.76);
uniform vec3 foam_color : source_color = vec3(0.90, 0.96, 0.94);
uniform vec3 foam_shade : source_color = vec3(0.66, 0.82, 0.80);
uniform float fall_speed = 2.4;          // metres per second at the lip (the streaks accelerate below)
uniform float streak_amount = 1.0;
uniform float self_light = 0.10;         // a touch of emission so the curtain never goes muddy in shade

varying float v_len;
varying float v_edge;

void vertex() {
	v_len = max(UV2.x, 0.5);
	v_edge = COLOR.a;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float vn = clamp(v / v_len, 0.0, 1.0);
	float t = TIME * fall_speed;
	// The water accelerates: stretch the fall coordinate so the streaks run faster lower down.
	float fall = v + vn * vn * 3.0;
	float n1 = texture(noise_tex, vec2(u * 0.50, (fall - t) * 0.070)).r;
	float n2 = texture(noise_tex, vec2(u * 1.30 + 0.41, (fall - t * 1.30) * 0.150 + 0.30)).r;
	float n3 = texture(noise_tex, vec2(u * 3.20 + 0.13, (fall - t * 1.65) * 0.300 + 0.70)).r;

	// Body: dark glassy teal with broad lighter sheets.
	vec3 col = mix(water_dark, water_light, smoothstep(0.30, 0.75, n1));
	// Streaks: posterised vertical strokes, more and whiter as the water falls.
	float sn = n2 * 0.65 + n3 * 0.35;
	float s_lo = 0.58 - vn * 0.16;
	float streak = smoothstep(s_lo, s_lo + 0.05, sn);
	float streak_core = smoothstep(s_lo + 0.09, s_lo + 0.13, sn);
	col = mix(col, mix(foam_shade, foam_color, streak_core), streak * (0.55 + 0.40 * vn) * streak_amount);
	// Glassy lip: a smooth light band where the water bends over the edge.
	float lip = 1.0 - smoothstep(0.08, 0.60, v + (n2 - 0.5) * 0.3);
	col = mix(col, lip_color, lip * 0.60);
	// White water at the bottom, broken upward by noise.
	float bottom = smoothstep(0.66, 0.96, vn + (n1 - 0.5) * 0.30);
	col = mix(col, foam_color, bottom);

	// Ragged sides: the edges thin out into strands; a few gaps open in the thin water near the bottom.
	float edge = v_edge * 1.4 - (1.0 - n2) * 0.55 - vn * 0.08;
	if (edge < 0.16) {
		discard;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	EMISSION = col * self_light;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
