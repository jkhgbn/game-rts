// menu_sky.gdshader - the dusk sky behind the main menu diorama (task A2.10).
// Painted, not photographic: five soft colour bands (deep indigo zenith -> violet -> rose -> amber -> a bright
// gold line on the horizon), a wide warm sun halo, a few long painted cloud streaks lit from below by the
// setting sun, and faint stars near the zenith. Static (no TIME) so Godot bakes its radiance once: free at
// runtime. It is also the ambient light source of the diorama (cool from above, warm from the horizon).
shader_type sky;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 zenith_color : source_color = vec3(0.07, 0.07, 0.20);
uniform vec3 high_color : source_color = vec3(0.20, 0.13, 0.34);
uniform vec3 mid_color : source_color = vec3(0.62, 0.27, 0.36);
uniform vec3 low_color : source_color = vec3(0.98, 0.50, 0.24);
uniform vec3 horizon_color : source_color = vec3(1.00, 0.78, 0.42);
uniform vec3 ground_horizon_color : source_color = vec3(0.30, 0.17, 0.15);
uniform vec3 ground_color : source_color = vec3(0.05, 0.04, 0.07);
uniform float band_scale : hint_range(0.1, 2.0) = 0.62;   // elevation (sin) where the zenith colour is reached
uniform float paint_steps : hint_range(0.0, 16.0) = 7.0;
uniform float paint_steps_mix : hint_range(0.0, 1.0) = 0.4;
uniform vec3 sun_tint : source_color = vec3(1.0, 0.62, 0.30);
uniform float sun_halo : hint_range(0.0, 4.0) = 1.1;
uniform float sun_halo_power : hint_range(1.0, 64.0) = 5.0;
uniform float sun_disc : hint_range(0.0, 16.0) = 5.0;
uniform vec3 cloud_dark : source_color = vec3(0.24, 0.12, 0.22);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.56, 0.32);
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.55;
uniform float star_amount : hint_range(0.0, 1.0) = 0.7;
uniform float energy = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 bands(float t) {
	// t: 0 horizon -> 1 zenith.
	if (paint_steps > 0.0) {
		t = mix(t, floor(t * paint_steps + 0.5) / paint_steps, paint_steps_mix);
	}
	vec3 c = mix(horizon_color, low_color, smoothstep(0.0, 0.10, t));
	c = mix(c, mid_color, smoothstep(0.08, 0.34, t));
	c = mix(c, high_color, smoothstep(0.30, 0.62, t));
	c = mix(c, zenith_color, smoothstep(0.58, 1.0, t));
	return c;
}

void sky() {
	float y = EYEDIR.y;
	vec3 col;
	if (y >= 0.0) {
		float t = clamp(y / band_scale, 0.0, 1.0);
		t = pow(t, 0.8);
		col = bands(t);
		float s = 0.0;
		vec3 sun_d = vec3(0.0, 1.0, 0.0);
		if (LIGHT0_ENABLED) {
			sun_d = LIGHT0_DIRECTION;
			s = max(dot(EYEDIR, sun_d), 0.0);
			// Wide halo, stronger along the horizon (the sun sits low).
			float halo = pow(s, sun_halo_power) * sun_halo + pow(s, 24.0) * sun_halo * 0.8;
			halo *= 1.0 - smoothstep(0.05, 0.6, y) * 0.4;
			col += sun_tint * halo;
			col += sun_tint * smoothstep(0.9990, 0.9995, s) * sun_disc;
		}
		// Painted cloud streaks: long horizontal strokes in a band above the horizon.
		if (cloud_amount > 0.0) {
			// Azimuth in turns; whole numbers of repeats of the seamless noise around the sky = no seam. Lod 0
			// because the azimuth derivative jumps at the wrap (a mip seam line otherwise).
			float u = atan(EYEDIR.x, EYEDIR.z) / 6.2831853;
			vec2 p1 = vec2(u * 3.0 + 0.13, y * 6.5 + 0.4);
			vec2 p2 = vec2(u * 8.0 + 0.71, y * 19.5 + 0.2);
			float n = textureLod(noise_tex, p1, 0.0).r;
			float n2 = textureLod(noise_tex, p2, 0.0).r;
			float band = smoothstep(0.03, 0.10, y) * (1.0 - smoothstep(0.22, 0.42, y));
			float c = smoothstep(0.52, 0.60, n * 0.75 + n2 * 0.25 + (band - 1.0) * 0.5) * band * cloud_amount;
			// Lit from below: the lower edge of each stroke glows, the top stays dusky.
			float under = smoothstep(0.45, 0.75, textureLod(noise_tex, p1 + vec2(0.0, 0.03), 0.0).r);
			vec3 cc = mix(cloud_lit, cloud_dark, clamp(under * 1.2, 0.0, 1.0));
			cc += sun_tint * pow(s, 3.0) * 0.8 * (1.0 - under);
			col = mix(col, cc, c * 0.85);
		}
		// Faint stars near the zenith.
		if (star_amount > 0.0) {
			vec2 sp = EYEDIR.xz / max(y + 0.35, 0.05) * 90.0;
			vec2 id = floor(sp);
			float h = hash(id);
			vec2 q = fract(sp) - 0.5 - (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.6;
			float star = step(0.985, h) * (1.0 - smoothstep(0.02, 0.09, length(q)));
			col += vec3(0.9, 0.85, 1.0) * star * smoothstep(0.35, 0.75, y) * star_amount * (0.5 + hash(id + 1.3));
		}
	} else {
		float t = clamp(-y / 0.18, 0.0, 1.0);
		t = smoothstep(0.0, 1.0, t);
		col = mix(ground_horizon_color, ground_color, t);
	}
	COLOR = col * energy;
}
