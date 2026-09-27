// env_glow.gdshader - glowing crystals, runes, lantern orbs, chest lock (art-keep.md 0.4 / 0.6: magic glows
// at energy 2.5-4 and pulses). One material per colour: crystal_glow_mat, ember_glow_mat, lantern_glow_mat.
// `sparkle` (crystals only, A.10): brief star-bright glints hop across the facets and a light band sweeps up.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 glow_color : source_color = vec3(0.45, 0.85, 1.0);
uniform vec3 core_color : source_color = vec3(0.85, 0.97, 1.0);
uniform float energy = 2.8;
uniform float pulse_speed = 1.6;
uniform float pulse_amount = 0.18;
uniform float sparkle = 0.0;

varying vec3 v_wp;
varying float v_ly;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_ly = VERTEX.y;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	// Faceted look: a light band on faces turned toward the sky.
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float facet = smoothstep(0.2, 0.7, wn.y) * 0.35;
	float pulse = 1.0 + sin(TIME * pulse_speed + v_wp.x * 0.7 + v_wp.z * 0.5 + v_ly * 2.5) * pulse_amount;
	vec3 c = mix(glow_color, core_color, clamp(fres + facet, 0.0, 1.0));
	vec3 e = c * energy * pulse;
	if (sparkle > 0.0) {
		// Glints: world-space cells (so they stay put while the prisms shrink), each flashing briefly.
		vec3 cell = floor(v_wp * 6.0 + wn * 0.5);
		float h = hash3(cell);
		float flash = pow(max(sin(TIME * (1.2 + h * 1.6) + h * 40.0), 0.0), 40.0) * step(0.62, h);
		// A soft band of light climbing the crystal every few seconds.
		float band = 1.0 - smoothstep(0.0, 0.12, abs(fract(TIME * 0.22 + v_wp.x * 0.05) * 3.2 - 0.6 - v_ly));
		e += core_color * (flash * 7.0 + band * 1.4) * sparkle;
	}
	ALBEDO = glow_color * 0.25;
	EMISSION = e;
	ROUGHNESS = 0.2;
	SPECULAR = 0.7;
}
