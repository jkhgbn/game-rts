shader_type spatial;
// forge_evenmead river: a flat world-space ribbon at the water level (make_world.gd). Depth-aware colour (clear
// shallows over the stony bed, teal-green depths), refraction of the bed, sky reflection by Fresnel (peach horizon,
// blue zenith), the low sun's glitter path, flow streaks and ripples scrolling downstream, foam round the ford stones
// and a soft shore line. 0 lights (unshaded; the engine fog still applies).
//   UV.x = metres along the river (flow), UV.y = -1..1 across; COLOR.a = foam boost (ford riffle), COLOR.r = speed
render_mode blend_mix, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 deep_col : source_color = vec3(0.04, 0.16, 0.17);
uniform vec3 shallow_col : source_color = vec3(0.5, 0.62, 0.48);
uniform vec3 sky_hor : source_color = vec3(1.0, 0.8, 0.6);
uniform vec3 sky_top : source_color = vec3(0.34, 0.56, 0.88);
uniform vec3 sun_to = vec3(0.966, 0.259, 0.0);
uniform vec3 sun_col : source_color = vec3(1.0, 0.82, 0.55);
uniform float glint = 9.0;
uniform float flow_speed = 0.35;

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
float waves(vec2 q, float t) {
	return vnoise(q * vec2(0.9, 2.2) - vec2(t * 1.0, 0.0)) * 0.6 + vnoise(q * vec2(2.1, 3.7) + vec2(-t * 1.6, t * 0.2)) * 0.3
		+ vnoise(q * vec2(5.3, 6.1) - vec2(t * 2.4, 0.0)) * 0.03;
}

void vertex() {
	wp = VERTEX;
}

void fragment() {
	float t = TIME * flow_speed * (0.6 + COLOR.r);
	vec2 q = vec2(UV.x, UV.y * 4.0);
	float e = 0.05;
	float h0 = waves(q, t);
	float hx = waves(q + vec2(e, 0.0), t);
	float hz = waves(q + vec2(0.0, e), t);
	vec3 nw = normalize(vec3(-(hx - h0) / e * 0.022, 1.0, -(hz - h0) / e * 0.022));
	vec3 vdir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	// water thickness along the view ray (scene depth behind minus the surface depth)
	float dz = texture(depth_tex, SCREEN_UV).r;
	vec4 sv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dz, 1.0);
	float scene_d = -sv.z / sv.w;
	float thick = max(scene_d - (-VERTEX.z), 0.0);
	float dfac = 1.0 - exp(-thick * 0.75);
	vec2 off = nw.xz * 0.02 * clamp(thick, 0.0, 1.0);
	vec3 bed = texture(screen_tex, SCREEN_UV + off).rgb;
	vec3 body = mix(bed * shallow_col, deep_col, dfac);
	// reflection: sky gradient + a warm far-bank band near the horizon
	vec3 r = reflect(vdir, nw);
	float ry = clamp(r.y, 0.0, 1.0);
	vec3 refl = mix(sky_hor, sky_top, pow(ry, 0.55));
	refl = mix(refl * vec3(0.55, 0.62, 0.45), refl, smoothstep(0.02, 0.12, ry));
	float cosv = clamp(dot(-vdir, nw), 0.0, 1.0);
	float fres = 0.03 + 0.97 * pow(1.0 - cosv, 5.0);
	vec3 col = mix(body, refl, clamp(0.1 + fres * 1.2, 0.0, 0.92));
	// the sun's glitter path: a broad sheen + sparkling facets
	float sd = max(dot(r, normalize(sun_to)), 0.0);
	float sparkle = step(0.9, vnoise(wp.xz * 5.0 + vec2(t * 3.0, -t)) * vnoise(wp.xz * 11.0 - vec2(t * 2.0, 0.0)) * 1.9);
	col += sun_col * (pow(sd, 90.0) * 1.4 + pow(sd, 700.0) * glint + sparkle * pow(sd, 16.0) * glint * 0.6);
	// flow streaks
	float streak = smoothstep(0.62, 0.9, vnoise(vec2(UV.x * 0.35 - t * 1.4, UV.y * 9.0)));
	col += vec3(0.9, 0.85, 0.75) * streak * 0.05;
	// foam: a thin shore line + the ford riffle
	float shore = 1.0 - smoothstep(0.0, 0.1, thick);
	float foam_n = vnoise(wp.xz * 3.0 + vec2(t * 2.0, 0.0));
	float foam = clamp(shore * 0.35 + COLOR.a * smoothstep(0.35, 0.8, foam_n + COLOR.a * 0.3), 0.0, 1.0);
	col = mix(col, vec3(0.95, 0.93, 0.86), foam * 0.75);
	ALBEDO = col;
	ALPHA = smoothstep(0.0, 0.06, thick);
}
