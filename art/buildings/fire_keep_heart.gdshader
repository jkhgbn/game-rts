// fire_keep_heart.gdshader - the Ember Heart: a small churning sun cradled by the obsidian claws (task A.7).
// Unshaded; molten swirls scroll over the sphere, a hot rim, a slow heartbeat (pulse_speed).
// `boost` is raised by fire_keep.gd (selection, collapse overload).
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 glow_color : source_color = vec3(1.0, 0.50, 0.12);
uniform vec3 core_color : source_color = vec3(1.0, 0.90, 0.60);
uniform float energy = 3.6;
uniform float pulse_speed = 4.2;
uniform float boost = 1.0;
uniform float phase = 0.0;

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	vec3 p = normalize(v_local);
	float t = TIME;
	vec2 uv = vec2(atan(p.z, p.x) / 6.2831853, p.y * 0.5 + 0.5);
	float n1 = texture(noise_tex, vec2(uv.x * 2.0 + t * 0.06, uv.y * 1.0 + t * 0.05)).r;
	float n2 = texture(noise_tex, vec2(uv.x * 4.0 - t * 0.09, uv.y * 2.0 - t * 0.04)).r;
	float swirl = n1 * 0.6 + n2 * 0.4;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	// Heartbeat: a quick double thump every cycle.
	float beat = sin(TIME * pulse_speed + phase);
	float pulse = 0.82 + 0.18 * smoothstep(0.6, 1.0, beat) + 0.08 * sin(TIME * pulse_speed * 2.0 + phase);
	vec3 col = mix(glow_color * 0.7, core_color, smoothstep(0.38, 0.66, swirl));
	col = mix(col, glow_color * 1.2, fres * 0.8);
	ALBEDO = col * energy * pulse * boost;
}
