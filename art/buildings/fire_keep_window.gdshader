// fire_keep_window.gdshader - the Fire Keep's lit openings (forge windows, arrow slits, lava vents).
// UV is 0..1 inside each opening (x across, y up, written by fire_keep_build.gd): hot at the bottom where
// the fire is, dimmer at the top, a dark soot rim along the sides and top, a flicker that differs per
// opening. `boost` = selection (fire_keep.gd glow boost).
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_color : source_color = vec3(1.0, 0.45, 0.10);
uniform vec3 hot_color : source_color = vec3(1.0, 0.85, 0.45);
uniform float energy = 2.3;
uniform float boost = 1.0;
uniform float pulse_speed = 2.0;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = UV;
	float edge = min(min(w.x, 1.0 - w.x), 1.0 - w.y);
	float rim = smoothstep(0.0, 0.14, edge);
	float grad = mix(1.15, 0.45, smoothstep(0.0, 1.0, w.y));
	float ph = v_world.x * 1.7 + v_world.z * 2.3 + v_world.y * 0.9;
	float flick = 0.86 + 0.14 * sin(TIME * pulse_speed * 3.1 + ph) * sin(TIME * 1.7 + ph * 0.5);
	vec3 col = mix(glow_color, hot_color, clamp(1.0 - w.y * 1.4, 0.0, 1.0)) * energy * grad * flick * boost;
	ALBEDO = mix(vec3(0.05, 0.015, 0.0), col, rim);
}
