shader_type spatial;
// forge_citadel pools: deep vertex colour, glossy, slow ripples + sun glints that twinkle (unshaded sparkle pushed into
// the HDR glow). 0 lights.
render_mode blend_mix, cull_back;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 p = wp.xz * 2.2;
	float rip = sin(p.x * 1.3 + TIME * 1.7) * sin(p.y * 1.1 - TIME * 1.3);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(rip * 0.12, 0.0, rip * 0.1, 0.0)).xyz);
	vec2 cell = floor(p * 1.6);
	float g = h2(cell + floor(TIME * 1.5 + h2(cell) * 7.0));
	float glint = smoothstep(0.93, 1.0, g) * (0.5 + 0.5 * sin(TIME * 9.0 + h2(cell) * 40.0));
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.08;
	METALLIC = 0.2;
	SPECULAR = 0.8;
	EMISSION = vec3(1.0, 0.92, 0.78) * glint * 2.2;
}
