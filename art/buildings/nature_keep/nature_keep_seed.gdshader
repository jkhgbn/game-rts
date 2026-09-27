// nature_keep_seed.gdshader - the Heartwood's living seed-hearts (task A2.5): the heart knot in the trunk and the
// seed at the centre of the Crown Bloom. Unshaded glow (art-keep.md 5.3 energies): a hot pale core where the
// surface faces the camera, the kingdom glow around it, slow sap swirls crawling over it, a heartbeat pulse
// (a double beat every `beat_period` s). `boost` = training pulse / selection / collapse.
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform vec3 core_color : source_color = vec3(1.0, 1.0, 0.82);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float energy = 3.2;
uniform float beat_period = 2.5;
uniform float boost = 1.0;

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float t = fract(TIME / beat_period);
	float beat = exp(-pow((t - 0.08) * 22.0, 2.0)) + 0.6 * exp(-pow((t - 0.2) * 22.0, 2.0));
	float pulse = 0.78 + 0.22 * beat;
	vec3 d = normalize(v_local + vec3(0.0001));
	vec2 suv = vec2(atan(d.z, d.x) / 6.2831853 * 2.0 + TIME * 0.03, d.y * 0.6 - TIME * 0.06);
	float swirl = texture(noise_tex, suv).r;
	float veins = smoothstep(0.62, 0.7, swirl) * (1.0 - smoothstep(0.7, 0.8, swirl));
	vec3 deep = mix(glow_color * glow_color, glow_color, 0.45);
	vec3 col = mix(deep, core_color, smoothstep(0.55, 1.0, facing));
	col = mix(col, glow_color * 0.55, veins * 0.6);
	ALBEDO = col * (0.35 + energy * pulse * boost * (0.85 + 0.3 * swirl));
}
