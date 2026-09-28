shader_type spatial;
// forge_evenmead river: a flat world-space ribbon at the water level (make_world.gd). Painted, clear and blue-green:
// the stony bed shows through the clear shallows along the banks, the channel deepens to a rich teal, the dark wooded
// banks mirror along both edges, the golden sky mirrors at grazing angles (Fresnel), fine ripple lines run downstream,
// the low sun lays a glitter path when the camera looks into it, and a thin foam line hugs the banks and the ford stones.
// 0 lights (unshaded; the engine fog still applies).
//   UV.x = metres along the river (flow), UV.y = -1..1 across; COLOR.a = foam boost (ford riffle), COLOR.r = speed
render_mode blend_mix, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 deep_col : source_color = vec3(0.07, 0.30, 0.38);
uniform vec3 mid_col : source_color = vec3(0.16, 0.46, 0.46);
uniform vec3 shallow_tint : source_color = vec3(0.62, 0.84, 0.72);
uniform vec3 bank_refl : source_color = vec3(0.12, 0.22, 0.12);
uniform vec3 sky_hor : source_color = vec3(1.0, 0.84, 0.66);
uniform vec3 sky_top : source_color = vec3(0.36, 0.58, 0.9);
uniform vec3 sun_to = vec3(0.966, 0.259, 0.0);
uniform vec3 sun_col : source_color = vec3(1.0, 0.84, 0.58);
uniform float glint = 3.0;
uniform float flow_speed = 0.35;
uniform float half_width = 10.5;

varying vec3 wp;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash1(i), hash1(i + vec2(1.0, 0.0)), f.x), mix(hash1(i + vec2(0.0, 1.0)), hash1(i + vec2(1.0, 1.0)), f.x), f.y);
}
// fine ripples, stretched across the flow (q in metres: x along, y across)
float ripples(vec2 q, float t) {
	return vnoise(q * vec2(0.8, 2.6) - vec2(t * 1.2, 0.0)) * 0.55 + vnoise(q * vec2(1.9, 5.5) + vec2(-t * 1.9, t * 0.3)) * 0.3
		+ vnoise(q * vec2(4.2, 9.0) - vec2(t * 2.6, 0.0)) * 0.15;
}

void vertex() {
	wp = VERTEX;
}

void fragment() {
	float t = TIME * flow_speed * (0.6 + COLOR.r);
	vec2 q = vec2(UV.x, UV.y * half_width);
	float e = 0.04;
	float h0 = ripples(q, t);
	float hx = ripples(q + vec2(e, 0.0), t);
	float hz = ripples(q + vec2(0.0, e), t);
	vec3 nw = normalize(vec3(-(hx - h0) / e * 0.035, 1.0, -(hz - h0) / e * 0.035));
	vec3 vdir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	// water thickness along the view ray (scene depth behind minus the surface depth)
	float dz = texture(depth_tex, SCREEN_UV).r;
	vec4 sv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dz, 1.0);
	float scene_d = -sv.z / sv.w;
	float thick = max(scene_d - (-VERTEX.z), 0.0);
	// body: the bed through clear shallows -> green-teal -> deep teal in the channel
	vec2 off = nw.xz * 0.015 * clamp(thick, 0.0, 1.0);
	vec3 bed = texture(screen_tex, SCREEN_UV + off).rgb;
	float k_mid = 1.0 - exp(-thick * 0.9);
	float k_deep = smoothstep(1.6, 6.0, thick);
	vec3 body = mix(bed * shallow_tint, mid_col, k_mid * 0.9);
	body = mix(body, deep_col, k_deep);
	// a soft painted band of light down the middle of the channel (depth reads, no flat slab)
	float across = abs(UV.y);
	body *= 0.92 + 0.16 * smoothstep(0.9, 0.2, across) * (0.7 + 0.3 * vnoise(vec2(UV.x * 0.08, UV.y * 2.0)));
	// reflection: the golden sky (Fresnel) and the dark wooded banks along both edges
	vec3 r = reflect(vdir, nw);
	float ry = clamp(r.y, 0.0, 1.0);
	vec3 refl = mix(sky_hor, sky_top, smoothstep(0.02, 0.6, ry));
	float cosv = clamp(dot(-vdir, nw), 0.0, 1.0);
	float fres = 0.04 + 0.96 * pow(1.0 - cosv, 4.0);
	vec3 col = mix(body, refl, clamp(0.06 + fres, 0.0, 0.85));
	float bank = smoothstep(0.55, 0.95, across) * (0.35 + 0.65 * (1.0 - cosv));
	bank *= 0.75 + 0.25 * vnoise(vec2(UV.x * 0.5, UV.y * 3.0));
	col = mix(col, bank_refl, bank * 0.55);
	// the sun's glitter path (only when looking toward the low sun): a soft sheen + a few sparkles
	float sd = max(dot(r, normalize(sun_to)), 0.0);
	float sparkle = step(0.93, vnoise(wp.xz * 4.0 + vec2(t * 3.0, -t)) * vnoise(wp.xz * 9.0 - vec2(t * 2.0, 0.0)) * 1.9);
	col += sun_col * (pow(sd, 40.0) * 0.5 + pow(sd, 400.0) * glint + sparkle * pow(sd, 24.0) * glint * 0.35);
	// ripple lines: thin bright crests drifting downstream (painted water)
	// (long and thin, running with the current, broken into dashes)
	float wv = sin(UV.y * half_width * 2.4 + vnoise(vec2(UV.x * 0.12, UV.y * 2.0)) * 5.0 + vnoise(vec2(UV.x * 0.5, UV.y * 5.0)) * 1.2);
	float lines = smoothstep(0.965, 0.995, wv) * smoothstep(0.55, 0.8, vnoise(vec2(UV.x * 0.3 - t * 2.0, UV.y * half_width * 0.9)));
	col = mix(col, mix(vec3(0.9, 0.96, 0.94), sky_hor, 0.4), lines * 0.22 * (1.0 - across * 0.5));
	// foam: a thin line on the banks and round stones + the ford riffle
	float shore = (1.0 - smoothstep(0.0, 0.22, thick)) * smoothstep(0.3, 0.7, vnoise(wp.xz * 1.3 + vec2(t, 0.0)));
	float foam_n = vnoise(wp.xz * 3.0 + vec2(t * 2.0, 0.0));
	float foam = clamp(shore * (0.45 + 0.4 * foam_n) + COLOR.a * smoothstep(0.35, 0.8, foam_n + COLOR.a * 0.3), 0.0, 1.0);
	col = mix(col, vec3(0.96, 0.95, 0.9), foam * 0.7);
	ALBEDO = col;
	ALPHA = smoothstep(0.0, 0.05, thick);
}
