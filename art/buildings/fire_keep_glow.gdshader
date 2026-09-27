// fire_keep_glow.gdshader - EVERY glowing / unlit part of the Fire Keep in one material (Art Lab budget pass:
// art-keep.md 9 allows <= 8 materials). Each part keeps its own look; the kind comes from UV2.y (written by
// fire_keep_build.gd per surface) or from the `kind_override` instance uniform (meshes without UV2).
//   0 coal       brazier coals (rune_glow look, energy 2.4, pulse 2.0)
//   1 gate       portcullis and emblem gem (energy 2.2, pulse 1.0; `gate_boost` = training pulse)
//   2 window     forge windows, arrow slits, lava vents, chimney mouth; UV 0..1 inside the opening,
//                UV2.x = energy scale (the small slits are dimmed below the bloom threshold)
//   3 heart      the Ember Heart (churning sun on a sphere; `heart_pulse_speed`, `core_boost`)
//   4 crystal    the orbiting ember crystals (faceted, team glow, `core_boost`)
//   5 lava       channel, falls, pools (UV in metres, flows toward +v; `lava_agitation`, `lava_cool`)
//   6 void       the dark doorway (unlit near-black)
//   7 outline    the construction outline bars (team glow, `outline_energy`)
// `boost` = selection (1.0 idle, 1.4 selected).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float boost = 1.0;
uniform float gate_boost = 1.0;
uniform float core_boost = 1.0;
uniform vec3 team_glow : source_color = vec3(1.0, 0.6, 0.18);
uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
// Windows.
uniform vec3 window_color : source_color = vec3(1.0, 0.45, 0.10);
uniform vec3 window_hot : source_color = vec3(1.0, 0.85, 0.45);
uniform float window_energy = 2.3;
// Heart.
uniform vec3 heart_color : source_color = vec3(1.0, 0.50, 0.12);
uniform vec3 heart_core : source_color = vec3(1.0, 0.90, 0.60);
uniform float heart_energy = 3.6;
uniform float heart_pulse_speed = 4.2;
// Lava.
uniform vec3 lava_core : source_color = vec3(1.0, 0.86, 0.45);
uniform vec3 lava_hot : source_color = vec3(1.0, 0.42, 0.08);
uniform vec3 lava_crust : source_color = vec3(0.16, 0.05, 0.03);
uniform float lava_energy = 2.4;
uniform float lava_flow_speed = 0.45;
uniform float lava_agitation = 0.0;
uniform float lava_cool = 0.0;
// Doorway and construction outline.
uniform vec3 void_color : source_color = vec3(0.035, 0.015, 0.01);
uniform float outline_energy = 2.0;

instance uniform int kind_override = -1;

varying vec3 v_local;
varying vec3 v_world;
varying flat int v_kind;
varying float v_scale;

void vertex() {
	v_local = VERTEX;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_kind = kind_override >= 0 ? kind_override : int(UV2.y + 0.5);
	v_scale = UV2.x;
}

vec3 rune_glow(vec3 gc, float energy, float pulse_speed, float b) {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);
	return gc * 0.4 + gc * energy * pulse * b;
}

void fragment() {
	int k = v_kind;
	vec3 col = vec3(0.0);
	if (k == 0) {
		col = rune_glow(glow_color, 2.4, 2.0, boost);
	} else if (k == 1) {
		col = rune_glow(glow_color, 2.2, 1.0, boost * gate_boost);
	} else if (k == 2) {
		vec2 w = UV;
		float edge = min(min(w.x, 1.0 - w.x), 1.0 - w.y);
		float rim = smoothstep(0.0, 0.14, edge);
		float grad = mix(1.15, 0.45, smoothstep(0.0, 1.0, w.y));
		float ph = v_world.x * 1.7 + v_world.z * 2.3 + v_world.y * 0.9;
		float flick = 0.86 + 0.14 * sin(TIME * 2.0 * 3.1 + ph) * sin(TIME * 1.7 + ph * 0.5);
		vec3 c = mix(window_color, window_hot, clamp(1.0 - w.y * 1.4, 0.0, 1.0)) * window_energy * v_scale
			* grad * flick * boost;
		col = mix(vec3(0.05, 0.015, 0.0), c, rim);
	} else if (k == 3) {
		vec3 p = normalize(v_local);
		float t = TIME;
		vec2 uv = vec2(atan(p.z, p.x) / 6.2831853, p.y * 0.5 + 0.5);
		float n1 = texture(noise_tex, vec2(uv.x * 2.0 + t * 0.06, uv.y * 1.0 + t * 0.05)).r;
		float n2 = texture(noise_tex, vec2(uv.x * 4.0 - t * 0.09, uv.y * 2.0 - t * 0.04)).r;
		float swirl = n1 * 0.6 + n2 * 0.4;
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
		// Heartbeat: a quick double thump every cycle.
		float beat = sin(TIME * heart_pulse_speed);
		float pulse = 0.82 + 0.18 * smoothstep(0.6, 1.0, beat) + 0.08 * sin(TIME * heart_pulse_speed * 2.0);
		vec3 c = mix(heart_color * 0.7, heart_core, smoothstep(0.38, 0.66, swirl));
		c = mix(c, heart_color * 1.2, fres * 0.8);
		col = c * heart_energy * pulse * boost * core_boost;
	} else if (k == 4) {
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float facet = clamp(dot(wn, normalize(vec3(0.35, 0.85, 0.40))) * 0.5 + 0.5, 0.0, 1.0);
		facet = 0.35 + 0.65 * facet * facet;
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
		float pulse = 0.8 + 0.2 * sin(TIME * 3.0);
		col = (team_glow * facet * 3.2 * pulse + mix(team_glow, vec3(1.0, 0.95, 0.8), 0.6) * fres * 1.6)
			* boost * core_boost;
	} else if (k == 5) {
		float speed = lava_flow_speed * (1.0 + lava_agitation * 1.5) * (1.0 - lava_cool * 0.9);
		float t = TIME * speed;
		vec2 uv = UV;
		float n1 = texture(noise_tex, vec2(uv.x * 0.30 + 0.13, uv.y * 0.16 - t * 0.16)).r;
		float n2 = texture(noise_tex, vec2(uv.x * 0.75 + 0.47, uv.y * 0.42 - t * 0.42)).r;
		float n = n1 * 0.62 + n2 * 0.38;
		float crust = smoothstep(0.55 - lava_cool * 0.45 - lava_agitation * 0.05, 0.66 - lava_cool * 0.40, n);
		float core = 1.0 - smoothstep(0.30, 0.46, n);
		vec3 hot = mix(lava_hot, lava_core, core);
		float pulse = 0.9 + 0.1 * sin(TIME * 2.3 + uv.y * 1.3);
		float e = lava_energy * (1.0 + lava_agitation * 0.45) * (1.0 - lava_cool * 0.8) * boost * pulse;
		// Thin glowing rims around the crust plates.
		float rim = smoothstep(0.50, 0.55, n) * (1.0 - smoothstep(0.55, 0.63, n)) * (1.0 - lava_cool);
		col = mix(hot * e, lava_crust * (1.0 - lava_cool * 0.5), crust) + lava_hot * rim * e * 0.6;
	} else if (k == 6) {
		col = void_color;
	} else {
		col = rune_glow(team_glow, outline_energy, 6.2831853, 1.0);
	}
	ALBEDO = col;
}
