// mouth_foam.gdshader - white water of the river mouths (task 12.V5): the plunge pool under the north falls, the lip
// where the stream tips over, the riffles of the stream, the rapid steps and rock wakes of the south gorge.
// ONE material (mouth_foam_mat.tres). Transparent, lit with the painted toon ramp (foam in a wall's shadow stays
// shaded), no depth / screen reads, no vertex motion, no lights. Meshes are baked by build_env.gd (river mouths):
//   UV.x    metres along the flow (increasing downstream), UV.y metres across from the band's centre line
//   COLOR.a envelope 0..1 (how much foam), COLOR.r 0..1 across the band (0.5 = centre; the sides fade out)
//   UV2.x   drift speed multiplier, UV2.y 1 = boil (the foam also rolls sideways, plunge pools), 0 = plain drift
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 foam_color : source_color = vec3(0.90, 0.96, 0.93);
uniform vec3 foam_shade : source_color = vec3(0.62, 0.80, 0.78);
uniform vec3 churn_color : source_color = vec3(0.36, 0.63, 0.58);
uniform float flow_speed = 0.9;         // metres per second (x UV2.x)
uniform float foam_amount = 1.0;        // global multiplier (Map detail Low may lower it)
uniform float streak = 2.2;             // how much the blobs stretch along the flow

varying float v_speed;
varying float v_boil;

void vertex() {
	v_speed = UV2.x;
	v_boil = UV2.y;
}

void fragment() {
	float a = UV.x;
	float c = UV.y;
	float t = TIME * flow_speed * v_speed;
	float roll = v_boil * sin(TIME * 0.8 + a * 0.9) * 0.45;
	// Two stretched noise layers drifting downstream at different speeds: painted clumps with crisp edges.
	float n1 = texture(noise_tex, vec2(c * 0.45 + roll, (a - t) * 0.45 / streak)).r;
	float n2 = texture(noise_tex, vec2(c * 1.05 + 0.37 - roll * 0.6, (a - t * 1.5) * 1.0 / streak + 0.21)).r;
	float n = n1 * 0.6 + n2 * 0.4;
	float side = 1.0 - smoothstep(0.28, 0.5, abs(COLOR.r - 0.5));
	float e = clamp(COLOR.a * side * foam_amount, 0.0, 1.0);
	float thr = mix(0.76, 0.30, e);
	float foam = smoothstep(thr, thr + 0.045, n);
	// A thinner rim inside each clump: reads as painted foam, not as a blur.
	float core = smoothstep(thr + 0.08, thr + 0.12, n);
	vec3 fc = mix(foam_shade, foam_color, core * 0.8 + 0.2);
	// Churned water between the clumps: lighter, milky teal.
	float churn = smoothstep(0.04, 0.4, e) * (0.30 + 0.30 * n2);
	ALBEDO = mix(churn_color, fc, foam);
	ALPHA = max(foam * 0.95, churn * 0.6) * smoothstep(0.0, 0.1, e);
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
