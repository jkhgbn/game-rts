shader_type spatial;
// forge_citadel fake glow: vertex colour pushed over the HDR glow threshold (lanterns, windows, braziers). 0 lights.
render_mode unshaded, cull_back;

uniform float energy = 2.6;
uniform float flicker = 0.12;

varying float phase;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	phase = floor(w.x * 0.7) * 1.7 + floor(w.z * 0.7) * 2.3;
}

void fragment() {
	float f = 1.0 + flicker * sin(TIME * 6.0 + phase);
	ALBEDO = COLOR.rgb * energy * f;
}
