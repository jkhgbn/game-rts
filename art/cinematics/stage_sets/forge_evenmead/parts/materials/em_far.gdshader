shader_type spatial;
// forge_evenmead far mountain ring (make_world.gd _ring): the light and the aerial perspective are painted into the
// vertex colours (sRGB), so the engine fog stays off here (it bleached the ring to cream when looking toward the low
// sun); only a soft warm glow is added on the sun's side of the sky. 0 lights.
// COLOR.a = snow mask (make_world.gd paint_face). Sun-side pass (2026-09-28): when the view looks toward the sun the
// shaded rock faces go a little darker and the snow crests / sun-turned facets catch a warm rim light, so the range
// keeps a clear snow line against the bright sky instead of reading as pale lilac paper.
render_mode unshaded, fog_disabled, cull_back, shadows_disabled;

uniform vec3 sun_to = vec3(0.966, 0.259, 0.0);
uniform vec3 glow_col : source_color = vec3(1.0, 0.8, 0.6);
uniform float glow = 0.22;
uniform vec3 rim_col : source_color = vec3(1.0, 0.84, 0.6);
uniform float rim = 0.75;
uniform float back_dark = 0.45;

void fragment() {
	vec3 col = pow(COLOR.rgb, vec3(2.2));
	float snow = clamp(COLOR.a, 0.0, 1.0);
	vec3 vdir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 sd = normalize(sun_to);
	// how much this view looks toward the sun (horizontal): 0 = side / front lit
	float bk = smoothstep(0.2, 0.8, dot(normalize(vdir.xz + vec2(1e-4)), normalize(sd.xz)));
	// shaded rock faces darker against the sun (contrast with the snow and the bright sky)
	float shade = 1.0 - clamp(dot(nw, sd) * 2.0 + 0.5, 0.0, 1.0);
	col *= 1.0 - back_dark * bk * shade * (1.0 - snow * 0.1);
	// rim: facets turned toward the sun and grazing to the eye (crests, ridge edges), strongest on snow
	float graze = 1.0 - clamp(dot(nw, -vdir), 0.0, 1.0);
	float toward = smoothstep(-0.2, 0.3, dot(nw, sd));
	float r = toward * pow(graze, 1.3) * bk * (0.25 + 0.75 * snow);
	col = mix(col, pow(rim_col, vec3(2.2)) * 1.1, clamp(r * rim, 0.0, 0.85));
	float s = max(dot(vdir, sd), 0.0);
	col = mix(col, glow_col, pow(s, 3.0) * glow);
	ALBEDO = col;
}
