// watchtower_ground.gdshader - the watchtower's ground contact (task 12.V17, art-keep.md 0.5), shared
// (watchtower_contact_mat.tres). A flat plane just above the ground, MULTIPLIED onto it (order independent, like
// nature_contact.gdshader): a dark soft contact round the plinth and a ragged ring of trodden, earthy ground, both with
// painted-noise edges (world space, so every tower differs). UV 0..1 over the plane, the centre = the tower.
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 contact_color : source_color = vec3(0.40, 0.42, 0.36);
uniform vec3 dirt_color : source_color = vec3(0.88, 0.74, 0.56);
uniform float plinth_r = 0.45;   // plinth edge in plane-radius units (1.92 m / 4.3 m)

varying vec3 v_wp;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float nz = texture(noise_tex, v_wp.xz * 0.3).r;
	float nz2 = texture(noise_tex, v_wp.xz * 0.85 + vec2(3.1, 7.3)).r;
	float rr = r + (nz - 0.5) * 0.22;
	float contact = 1.0 - smoothstep(plinth_r - 0.02, plinth_r + 0.22, rr);
	float dirt = (1.0 - smoothstep(plinth_r + 0.1, 0.95, rr + (nz2 - 0.5) * 0.25)) * smoothstep(0.32, 0.5, nz2 + 0.18);
	vec3 col = mix(vec3(1.0), dirt_color, clamp(dirt, 0.0, 1.0) * 0.85);
	col = mix(col, contact_color, contact * 0.85);
	ALBEDO = col;
}
