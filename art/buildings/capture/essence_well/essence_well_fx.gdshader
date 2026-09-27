// essence_well_fx.gdshader - the additive effects of the Essence well (task 12.V19), all in ONE mesh and ONE shared
// material (essence_well_fx_mat.tres), so a well's effects cost a single draw call:
//   mode 0  mist cards: two soft cards turning around Y toward the camera (built in the local XY plane), wisps of violet
//           essence mist rising 2-3 m from the pool. Cheap and visible at every zoom (the particles add detail up close).
//   mode 1  ground glow: a soft light pool around the well in the rune colour (faint violet when neutral, the owner's
//           colour when owned); while captured, an arc of the capturer's colour fills clockwise from -Z like the runes.
//   mode 2  pulse ring (play_pulse, each income tick): a violet ring racing out from the rim to ~4.6 m. Collapsed to a
//           point while no pulse plays (pulse < 0), so it costs nothing.
// Baked by build_essence_well.gd: UV2.x = mode; mist: UV = (0-1 across, 0 bottom -> 1 top), UV2.y = card seed;
// ground glow / ring: UV = local xz in metres.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 mist_color : source_color = vec3(0.62, 0.34, 1.0);
uniform float mist_strength = 0.95;
uniform vec3 pulse_color : source_color = vec3(0.78, 0.46, 1.0);

instance uniform vec4 rune_color = vec4(0.52, 0.36, 0.80, 1.0);
instance uniform float rune_energy = 0.45;
instance uniform vec4 cap_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float cap_ratio = 0.0;
instance uniform float pulse = -1.0;
instance uniform float flare = 0.0;

varying vec2 v_uv;
varying flat float v_mode;
varying flat float v_seed;

void vertex() {
	v_uv = UV;
	v_mode = UV2.x;
	v_seed = UV2.y;
	if (UV2.x < 0.5) {
		// Turn the card around the model's Y axis to face the camera.
		vec3 cam_m = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
		vec2 to_cam = cam_m.xz;
		to_cam = length(to_cam) > 0.001 ? normalize(to_cam) : vec2(0.0, 1.0);
		vec3 fwd = vec3(to_cam.x, 0.0, to_cam.y);
		vec3 right = vec3(to_cam.y, 0.0, -to_cam.x);
		float h = UV.y;
		vec3 p = vec3(0.0, VERTEX.y, 0.0) + right * VERTEX.x + fwd * VERTEX.z;
		// A lazy sway, stronger toward the top.
		p.x += sin(TIME * 0.55 + v_seed * 6.0 + VERTEX.y * 1.1) * 0.12 * h;
		p.z += cos(TIME * 0.47 + v_seed * 4.0 + VERTEX.y * 0.9) * 0.10 * h;
		VERTEX = p;
	} else if (UV2.x > 1.5 && pulse < 0.0) {
		VERTEX = vec3(0.0, -4.0, 0.0);
	}
}

void fragment() {
	vec3 col = vec3(0.0);
	float a = 0.0;
	if (v_mode < 0.5) {
		float u = v_uv.x;
		float h = v_uv.y;
		float edge = pow(sin(u * 3.14159), 1.6);
		float n1 = texture(noise_tex, vec2(u * 0.7 + v_seed * 3.7, h * 0.8 - TIME * 0.13)).r;
		float n2 = texture(noise_tex, vec2(u * 1.6 - v_seed * 2.1, h * 1.7 - TIME * 0.26) + vec2(3.1, 1.7)).r;
		float wisps = smoothstep(0.30, 0.80, n1 * 0.58 + n2 * 0.52);
		float fade = smoothstep(0.0, 0.14, h) * (1.0 - smoothstep(0.30, 1.0, h));
		a = wisps * edge * fade * mist_strength * (1.0 + flare * 1.5);
		col = mist_color * (1.0 + (1.0 - h) * 0.6);
	} else if (v_mode < 1.5) {
		vec2 p = v_uv;
		float r = length(p);
		float ang = fract(atan(p.x, -p.y) / 6.28319 + 1.0);
		float pool = smoothstep(1.25, 1.75, r) * (1.0 - smoothstep(1.9, 3.2, r));
		float k = clamp(rune_energy * 0.1, 0.0, 0.26);
		col = rune_color.rgb;
		a = pool * k;
		float capturing = step(0.001, cap_ratio);
		float filled = capturing * (1.0 - smoothstep(cap_ratio - 0.004, cap_ratio + 0.004, ang));
		float head = capturing * exp(-abs(ang - cap_ratio) * 30.0);
		// The filled arc in the capturer's colour with a bright head, the rest of the circle a faint track of it.
		float cap_pool = smoothstep(1.2, 1.6, r) * (1.0 - smoothstep(2.2, 3.3, r));
		float cap_a = cap_pool * ((0.34 + head * 0.5) * filled + 0.07 * (1.0 - filled)) * capturing;
		col = mix(col, cap_color.rgb, clamp(cap_a / max(a + cap_a, 0.0001), 0.0, 1.0));
		a = max(a, cap_a) * (1.0 + flare * 0.8);
	} else {
		vec2 p = v_uv;
		float r = length(p);
		float t = clamp(pulse, 0.0, 1.0);
		float rr = mix(1.4, 4.6, 1.0 - pow(1.0 - t, 2.2));
		float ring = exp(-pow((r - rr) / 0.2, 2.0));
		float wake = smoothstep(rr - 1.4, rr, r) * step(r, rr) * 0.25;   // a faint trail inside the ring
		a = (ring + wake) * pow(1.0 - t, 1.3) * smoothstep(1.2, 1.5, r);
		col = pulse_color * 2.2;
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
