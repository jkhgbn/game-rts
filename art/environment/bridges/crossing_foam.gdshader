// crossing_foam.gdshader - painted white water around the river crossings (task 12.V4): the rapids where a ford's
// film spills into the deep trench, the foam lines at the ford sill, the bow waves and wakes of the road-bridge piers
// and the foam at the foot of the Crown Steps. ONE material (crossing_foam_mat.tres) for every crossing mesh.
// Transparent, unshaded, no depth / screen reads, no vertex motion, no lights. Meshes are baked by
// build_crossings.gd:
//   UV      metres (x along the band, y across it), so the noise keeps its size on every band
//   COLOR.a envelope 0..1: how much foam there is (dense at the lip, breaking up and fading outward and at the ends)
//   UV2.x   sheet: 0 = foam floating on the water (see-through between the blobs), 1 = a falling water curtain
//           (the cascade off the ford lip: teal water with white streaks)
//   UV2.y   flow: +1 = the foam drifts toward +UV.y, -1 = toward -UV.y, 2 = along +UV.x
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 foam_color : source_color = vec3(0.86, 0.94, 0.90);
uniform vec3 foam_shade : source_color = vec3(0.60, 0.76, 0.74);
uniform vec3 sheet_color : source_color = vec3(0.16, 0.42, 0.38);
uniform float flow_speed = 0.45;       // metres per second
uniform float foam_amount = 1.0;       // global multiplier (Map detail Low may lower it)
uniform float streak = 2.6;            // how much the blobs stretch along the flow

varying float v_sheet;
varying float v_flow;

void vertex() {
	v_sheet = UV2.x;
	v_flow = UV2.y;
}

void fragment() {
	vec2 dir = abs(v_flow) > 1.5 ? vec2(1.0, 0.0) : vec2(0.0, v_flow >= 0.0 ? 1.0 : -1.0);
	vec2 perp = vec2(-dir.y, dir.x);
	float a = dot(UV, dir);
	float c = dot(UV, perp);
	float speed = flow_speed * (1.0 + v_sheet * 1.4);
	float t = TIME * speed;
	// Two stretched noise layers drifting downstream at different speeds: painted foam clumps with crisp edges.
	float n1 = texture(noise_tex, vec2(c * 0.42, (a - t) * 0.42 / streak)).r;
	float n2 = texture(noise_tex, vec2(c * 0.95 + 0.37, (a - t * 1.55) * 0.95 / streak + 0.21)).r;
	float n = n1 * 0.62 + n2 * 0.38;
	float e = clamp(COLOR.a, 0.0, 1.0) * foam_amount;
	float thr = mix(0.74, 0.38, clamp(e, 0.0, 1.0));
	float foam = smoothstep(thr, thr + 0.05, n);
	// A second, thinner rim inside each clump: reads as painted foam, not as a blur.
	float core = smoothstep(thr + 0.09, thr + 0.13, n);
	vec3 fc = mix(foam_shade, foam_color, core * 0.8 + 0.2);
	float fade = smoothstep(0.0, 0.2, e);
	float alpha_foam = foam * fade * 0.92;
	// Water curtain: teal with streaks, lighter where it breaks.
	float streaks = smoothstep(0.42, 0.62, texture(noise_tex, vec2(c * 1.6, (a - t * 1.9) * 0.18)).r);
	vec3 sheet = mix(sheet_color, foam_color * 0.92, max(streaks * 0.7, foam));
	float alpha_sheet = (0.78 + foam * 0.2) * fade;
	ALBEDO = mix(fc, sheet, v_sheet);
	ALPHA = mix(alpha_foam, alpha_sheet, v_sheet);
}
