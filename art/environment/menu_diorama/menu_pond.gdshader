// menu_pond.gdshader - a still dusk pond in the menu diorama's foreground (G-D menu).
// Painted, not physical: the reflection is the sunset sky's own bands looked up along the reflected view ray (no
// reflection probe, no SSR, no screen read), broken by slow ripples, with a gold sun glint, the far treeline
// mirrored as a dark band and a wet shore. PlaneMesh, UV 0-1 over the plane; the pond is an irregular blob in it.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 deep_color : source_color = vec3(0.05, 0.05, 0.09);
uniform vec3 horizon_color : source_color = vec3(1.00, 0.72, 0.40);
uniform vec3 low_color : source_color = vec3(0.92, 0.45, 0.26);
uniform vec3 mid_color : source_color = vec3(0.50, 0.22, 0.34);
uniform vec3 high_color : source_color = vec3(0.16, 0.11, 0.28);
uniform vec3 shore_color : source_color = vec3(0.13, 0.10, 0.08);
uniform vec3 sun_dir = vec3(-1.0, 0.36, 0.0);   // toward the sun (world)
uniform vec3 sun_tint : source_color = vec3(1.0, 0.66, 0.32);
uniform float ripple = 0.05;
uniform float brightness = 1.0;
// The dark far forest mirrored along the far shore.
uniform vec3 treeline_color : source_color = vec3(0.16, 0.12, 0.18);
// Half the pond's long size (m), set by the diorama.
uniform float pond_radius = 5.0;
// The crown's beacon mirrored in the water.
uniform vec3 crown_pos = vec3(0.0, 0.0, 0.0);
uniform vec3 beacon_color : source_color = vec3(1.0, 0.78, 0.4);
uniform float beacon_strength = 1.4;

varying vec3 v_wp;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 sky(float y) {
	float t = pow(clamp(y / 0.62, 0.0, 1.0), 0.8);
	vec3 c = mix(horizon_color, low_color, smoothstep(0.0, 0.10, t));
	c = mix(c, mid_color, smoothstep(0.08, 0.34, t));
	return mix(c, high_color, smoothstep(0.30, 0.62, t));
}

void fragment() {
	// Irregular outline: the radius wobbles with the noise around the blob.
	vec2 q = UV * 2.0 - 1.0;
	float ang = atan(q.y, q.x);
	float edge = 0.8 + 0.07 * sin(ang * 3.0 + 1.0) + 0.04 * sin(ang * 5.0 + 2.3) + 0.025 * sin(ang * 9.0 + 0.4);
	float r = length(q) / edge;
	float water = 1.0 - smoothstep(0.86, 0.93, r);
	float shore = 1.0 - smoothstep(0.93, 1.0 + 0.1 * texture(noise_tex, v_wp.xz * 0.21).r, r);

	// Ripples: two slow scrolling noise layers tilt the normal a little.
	vec2 p = v_wp.xz;
	float n1 = texture(noise_tex, p * 0.09 + vec2(TIME * 0.006, TIME * 0.004)).r;
	float n2 = texture(noise_tex, p * 0.23 - vec2(TIME * 0.009, -TIME * 0.005)).r;
	float n3 = texture(noise_tex, p * 0.23 + vec2(0.37, 0.11) - vec2(TIME * 0.009, -TIME * 0.005)).r;
	vec3 nw = normalize(vec3((n2 - 0.5) * ripple * 2.0 + (n1 - 0.5) * ripple, 1.0,
			(n3 - 0.5) * ripple * 2.0 + (n1 - 0.5) * ripple));

	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 view = normalize(v_wp - cam);
	vec3 rf = reflect(view, nw);
	// Painted, not physical: how far across the pond this point lies from the viewer (0 near shore, 1 far shore)
	// picks the mirrored sky: the near water holds the rose sky, the far water the gold horizon, and a ragged dark
	// band of mirrored forest lines the far shore. The ripples bend it a little.
	vec2 fw = normalize(view.xz);
	float across = dot(v_wp.xz - NODE_POSITION_WORLD.xz, fw) / max(pond_radius, 0.1) * 0.5 + 0.5;
	across = clamp(across + (rf.y - (-view.y)) * 2.0, 0.0, 1.0);
	vec3 refl = sky(mix(0.26, 0.0, across));
	float tl = 0.84 - 0.1 * textureLod(noise_tex, vec2(v_wp.x * 0.05 + v_wp.z * 0.05, 0.7), 0.0).r;
	refl = mix(refl, treeline_color, smoothstep(tl, tl + 0.03, across) * 0.9);
	// Horizontal shimmer lines (wind on the water), brighter on the gold.
	float lines = sin(across * 70.0 + (n2 - 0.5) * 9.0 + TIME * 0.6);
	refl *= 1.0 + 0.12 * smoothstep(0.6, 1.0, lines);
	// The crown beacon's column mirrored: a gold streak below the crown on screen.
	vec2 to_c = crown_pos.xz - v_wp.xz;
	float hit = max(dot(normalize(to_c), normalize(rf.xz)), 0.0);
	float streak = pow(hit, 900.0) * (0.55 + 0.45 * n1);
	refl += beacon_color * streak * beacon_strength * (1.0 - smoothstep(0.75, 0.95, across));
	vec3 sd = normalize(sun_dir);
	float s = max(dot(rf, sd), 0.0);
	refl += sun_tint * (pow(s, 40.0) * 1.6 + pow(s, 6.0) * 0.25);
	// Fresnel (painted): the near water is dark and deep, the far water a mirror.
	float f = clamp(mix(0.3, 0.95, smoothstep(0.0, 0.8, across)) + 0.2 * pow(1.0 - clamp(-view.y, 0.0, 1.0), 3.0), 0.0, 1.0);
	vec3 col = mix(deep_color, refl, f) * brightness;
	// Shore: wet dark mud ring, fading into the grass.
	col = mix(shore_color, col, water);
	ALBEDO = col;
	ALPHA = clamp(max(water, shore * 0.75), 0.0, 1.0);
}
