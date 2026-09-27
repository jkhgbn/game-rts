// fire_keep_lava.gdshader - flowing lava for the Fire Keep's channel, lava falls and pools (task A.7).
// UV is in metres (fire_keep_build.gd): x across the flow, y along it (the lava flows toward +y).
// Unshaded, emissive: a bright core, hot orange body and dark crust plates that drift with the flow.
//   agitation 0-1: damaged keep, faster and brighter        cool 0-1: destroyed keep, the crust takes over
//   boost: selection (fire_keep.gd glow boost)
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 core_color : source_color = vec3(1.0, 0.86, 0.45);
uniform vec3 hot_color : source_color = vec3(1.0, 0.42, 0.08);
uniform vec3 crust_color : source_color = vec3(0.16, 0.05, 0.03);
uniform float energy = 2.4;
uniform float flow_speed = 0.45;
uniform float agitation = 0.0;
uniform float cool = 0.0;
uniform float boost = 1.0;

void fragment() {
	float speed = flow_speed * (1.0 + agitation * 1.5) * (1.0 - cool * 0.9);
	float t = TIME * speed;
	vec2 uv = UV;
	float n1 = texture(noise_tex, vec2(uv.x * 0.30 + 0.13, uv.y * 0.16 - t * 0.16)).r;
	float n2 = texture(noise_tex, vec2(uv.x * 0.75 + 0.47, uv.y * 0.42 - t * 0.42)).r;
	float n = n1 * 0.62 + n2 * 0.38;
	float crust = smoothstep(0.55 - cool * 0.45 - agitation * 0.05, 0.66 - cool * 0.40, n);
	float core = 1.0 - smoothstep(0.30, 0.46, n);
	vec3 hot = mix(hot_color, core_color, core);
	float pulse = 0.9 + 0.1 * sin(TIME * 2.3 + uv.y * 1.3);
	float e = energy * (1.0 + agitation * 0.45) * (1.0 - cool * 0.8) * boost * pulse;
	// Thin glowing rims around the crust plates.
	float rim = smoothstep(0.50, 0.55, n) * (1.0 - smoothstep(0.55, 0.63, n)) * (1.0 - cool);
	vec3 col = mix(hot * e, crust_color * (1.0 - cool * 0.5), crust) + hot_color * rim * e * 0.6;
	ALBEDO = col;
}
