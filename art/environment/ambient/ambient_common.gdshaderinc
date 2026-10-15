// ambient_common.gdshaderinc - shared by the G-D ambient life shaders (docs/art/gd_ambient.md).
// Fog of war: ambient life is neutral scenery, but see-through particles draw AFTER the fog overlay
// (FogOfWar's box, render_priority -100), so they read the same explored / visible textures here and fade out
// where the local player sees nothing (black) and dim in grey fog. AmbientLife copies the textures and the map half
// size from the overlay material; fog_on 0 (no fog, F11 off) = full strength. Opaque meshes (birds, butterflies,
// leaves) need nothing: the overlay darkens them from the depth buffer like any other mesh.

uniform sampler2D fog_vis : filter_linear, repeat_disable, hint_default_white;
uniform sampler2D fog_exp : filter_linear, repeat_disable, hint_default_white;
uniform vec2 fog_half = vec2(60.0, 60.0);
uniform float fog_on = 0.0;

// 1 = seen now, ~0.45 = explored grey, 0 = never explored (or off the map).
float fog_seen(vec3 w) {
	if (fog_on < 0.5) {
		return 1.0;
	}
	vec2 uv = (w.xz + fog_half) / (2.0 * fog_half);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	float e = textureLod(fog_exp, uv, 0.0).r;
	float v = textureLod(fog_vis, uv, 0.0).r;
	return e * mix(0.45, 1.0, v);
}

// Sine-free hash (same family as critter_common.gdshaderinc).
float amb_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The particle's own random number (stable for one particle life: its index plus the life it is in).
float amb_pid(int id, float salt) {
	return amb_hash(vec2(float(id) * 1.618 + salt * 7.13, salt * 3.71 + float(id) * 0.37));
}

// Billboard model-view for a particle (the StandardMaterial "particles" billboard): faces the camera, keeps the
// particle's scale.
mat4 amb_billboard(mat4 model, mat4 view, mat4 inv_view) {
	mat4 mv = view * mat4(inv_view[0], inv_view[1], inv_view[2], model[3]);
	return mv * mat4(vec4(length(model[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(model[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(model[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
