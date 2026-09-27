// magpie_den_cloth.gdshader - every cloth of the Magpie Den (task 10.V8), merged into ONE mesh (one draw call).
// Mesh convention (built by magpie_den_model.gd): UV.x across the cloth (0-1), UV.y from the pinned edge (0) to the
// free edge (1); NORMAL = the cloth's face; COLOR.rgb = cloth colour (LINEAR), COLOR.a = kind:
//   a > 0.5  a stolen kingdom banner (tattered rag in its kingdom colour, dark hem, faded band, holes)
//   a < 0.5  the Magpies' own flag on the mast (black, white hoist band, a big white magpie feather with an
//            iridescent blue-green tip, ragged fly end)
// Waves along NORMAL in the vertex shader (the pinned edge stays put). Two-sided, lit like painted.gdshader.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec2 flag_size = vec2(1.2, 0.66);       // length (along UV.y), height (along UV.x) in metres
uniform float flag_amplitude = 0.11;
uniform float banner_amplitude = 0.045;
uniform float speed = 2.3;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.0;

varying float v_kind;
varying vec3 v_lp;

void vertex() {
	v_kind = COLOR.a;
	v_lp = VERTEX;
	float w = UV.y;
	float amp = mix(flag_amplitude, banner_amplitude, step(0.5, COLOR.a));
	float ph = dot(VERTEX, vec3(0.9, 0.35, 1.3));
	float wave = sin(TIME * speed + UV.y * 5.5 + ph) * amp * w
		+ sin(TIME * speed * 1.7 + UV.y * 9.0 + UV.x * 3.0 + ph * 0.7) * amp * 0.35 * w * w;
	VERTEX += NORMAL * wave;
}

float feather(vec2 p) {
	// p in metres on the flag (x = along the fly, y = up). Returns 1 inside the vane.
	vec2 c = vec2(flag_size.x * 0.54, flag_size.y * 0.5);
	float a = 0.42;
	vec2 d = p - c;
	vec2 q = vec2(d.x * cos(a) + d.y * sin(a), -d.x * sin(a) + d.y * cos(a));
	float e = q.x / 0.36;
	float hw = 0.115 * sqrt(max(0.0, 1.0 - e * e)) * (1.0 - 0.3 * e);
	float inside = step(abs(q.y), hw);
	// Barb notches on the edges.
	float notch = step(0.55 * hw, abs(q.y)) * step(fract(q.x * 8.0 + sign(q.y) * 0.3), 0.13);
	return inside * (1.0 - notch);
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float kind = v_kind;
	float nz = texture(noise_tex, vec2(u * 0.55 + kind * 0.37, 0.21 + v_lp.x * 0.05)).r;
	vec3 col;
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	if (kind > 0.5) {
		// Stolen banner: ragged free edge + a hole or two.
		float cut = 0.08 + nz * 0.26;
		if (v > 1.0 - cut) {
			discard;
		}
		float hole = texture(noise_tex, vec2(u * 0.9 + v_lp.z * 0.1, v * 0.8 + v_lp.x * 0.1)).r;
		if (hole > 0.72 && v > 0.3 && v < 0.85 && u > 0.12 && u < 0.88) {
			discard;
		}
		col = COLOR.rgb;
		col *= 0.9 + 0.1 * sin(u * 17.0 + v * 3.0);
		col = mix(col, col * 0.45, step(v, 0.09));
		col = mix(col, col * 1.35 + vec3(0.04), step(0.34, v) * step(v, 0.44));
		col = mix(col, col * 0.55, 1.0 - step(0.07, u) * step(u, 0.93));
		// Dirt and fading toward the free edge.
		col *= mix(1.0, 0.72, smoothstep(0.5, 1.0, v) * nz);
	} else {
		// The Magpies' flag.
		float cut = 0.04 + nz * 0.14 + 0.1 * (1.0 - abs(u - 0.5) * 2.0);
		if (v > 1.0 - cut) {
			discard;
		}
		vec2 p = vec2(v * flag_size.x, u * flag_size.y);
		col = vec3(0.035, 0.035, 0.045);
		col *= 0.85 + 0.15 * sin(v * 23.0 + u * 2.0);
		vec3 white = vec3(0.86, 0.86, 0.83);
		vec3 teal = mix(vec3(0.06, 0.42, 0.62), vec3(0.08, 0.72, 0.52), fres + 0.3 * sin(v * 6.0));
		col = mix(col, white, step(v, 0.11));
		col = mix(col, teal, step(0.11, v) * step(v, 0.145));
		float border = 1.0 - step(0.06, u) * step(u, 0.94);
		col = mix(col, teal * 0.8, border * step(0.145, v));
		float f = feather(p);
		vec2 c = vec2(flag_size.x * 0.54, flag_size.y * 0.5);
		vec2 d = p - c;
		float qx = d.x * cos(0.42) + d.y * sin(0.42);
		float qy = -d.x * sin(0.42) + d.y * cos(0.42);
		vec3 fc = mix(white, teal * 1.25, smoothstep(0.08, 0.16, qx));
		col = mix(col, fc, f);
		float spine = step(abs(qy), 0.011) * step(-0.46, qx) * step(qx, 0.33);
		col = mix(col, vec3(0.25, 0.25, 0.27), spine);
	}
	col *= mix(0.8, 1.04, smoothstep(0.0, 0.3, v));
	ALBEDO = col;
	EMISSION = rim_color * fres * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
