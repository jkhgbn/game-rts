shader_type spatial;
// forge_evenmead far mountain ring (make_world.gd _ring): the light and the aerial perspective are painted into the
// vertex colours (sRGB), so the engine fog stays off here (it bleached the ring to cream when looking toward the low
// sun); only a soft warm glow is added on the sun's side of the sky. 0 lights.
render_mode unshaded, fog_disabled, cull_back, shadows_disabled;

uniform vec3 sun_to = vec3(0.966, 0.259, 0.0);
uniform vec3 glow_col : source_color = vec3(1.0, 0.8, 0.6);
uniform float glow = 0.22;

void fragment() {
	vec3 col = pow(COLOR.rgb, vec3(2.2));
	vec3 vdir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	float s = max(dot(vdir, normalize(sun_to)), 0.0);
	col = mix(col, glow_col, pow(s, 3.0) * glow);
	ALBEDO = col;
}
