// painted_sky.gdshader - stylised sky for the RTS maps (task A.11, docs/art/lighting.md).
// A soft 3-band gradient (zenith -> horizon glow -> ground), a painted sun halo and a few
// posterised steps so it reads "hand painted", not photographic. The RTS camera (pitch 55) almost
// never sees the upper sky: what matters is (1) the lower hemisphere, seen past the map edges, and
// (2) the ambient light the sky gives (Environment ambient source = Sky): the zenith colour lights
// every up-facing surface, the horizon colours the sides, the ground colour the undersides.
// Static (no TIME), so Godot bakes its radiance once: free at runtime.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.30, 0.47, 0.76);
uniform vec3 horizon_color : source_color = vec3(0.86, 0.78, 0.62);
uniform vec3 ground_horizon_color : source_color = vec3(0.36, 0.33, 0.25);
uniform vec3 ground_color : source_color = vec3(0.12, 0.12, 0.09);
uniform float horizon_height : hint_range(0.02, 1.0) = 0.35;   // how far up the horizon glow reaches
uniform float ground_fade : hint_range(0.02, 1.0) = 0.22;      // how fast the ground darkens below the horizon
uniform float paint_steps : hint_range(0.0, 16.0) = 6.0;       // 0 = smooth; else posterise the gradient
uniform float paint_steps_mix : hint_range(0.0, 1.0) = 0.35;
uniform vec3 sun_tint : source_color = vec3(1.0, 0.82, 0.55);
uniform float sun_halo : hint_range(0.0, 2.0) = 0.45;           // wide warm halo around the sun
uniform float sun_disc : hint_range(0.0, 8.0) = 2.5;           // small bright disc
uniform float energy = 1.0;

void sky() {
	float y = EYEDIR.y;
	vec3 col;
	if (y >= 0.0) {
		float t = clamp(y / horizon_height, 0.0, 1.0);
		t = smoothstep(0.0, 1.0, pow(t, 0.7));
		if (paint_steps > 0.0) {
			t = mix(t, floor(t * paint_steps + 0.5) / paint_steps, paint_steps_mix);
		}
		col = mix(horizon_color, zenith_color, t);
		if (LIGHT0_ENABLED) {
			float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
			col += sun_tint * (pow(s, 6.0) * sun_halo + smoothstep(0.9985, 0.9992, s) * sun_disc);
		}
	} else {
		float t = clamp(-y / ground_fade, 0.0, 1.0);
		t = smoothstep(0.0, 1.0, t);
		col = mix(ground_horizon_color, ground_color, t);
	}
	COLOR = col * energy;
}
