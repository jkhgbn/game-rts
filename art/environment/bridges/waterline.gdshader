// waterline.gdshader - G2b wet stone at the waterline of the crossings (bridge piers, cutwaters, ford stones,
// Crown Steps). A material_overlay (drawn over the body with its own material untouched): multiplies the stone
// under it, so it works on any body shader.
//   - a dark wet band from the water up to ~0.3 m (ragged top edge, drips), tinted a little teal
//   - a thin pale tide line just above the water
//   - (Medium+) light bouncing off the moving water: soft bright ripple bands crawling on the stone above it
// Everything above `water_y + 0.45` is left as it is (multiplied by 1; discarded to save blending).
// `water_y` is an instance uniform: RiverSystem.WATER_Y (-0.35) for bridges and steps, -0.15 for the ford stones
// (CrossingArt.FORD_WET_Y: the film is at 0.02, but only the stones' feet should look wet).
// CrossingArt / LaneBridgeArt set it and hand the node to WaterQuality (tier 0 = no overlay).
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 wet_tint : source_color = vec3(0.55, 0.62, 0.62);
uniform float band_height = 0.28;
uniform int quality = 2;
instance uniform float water_y = -0.35;

varying vec3 v_wp;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float h = v_wp.y - water_y;
	if (h > band_height + 0.2 || h < -0.6) {
		discard;
	}
	float n = texture(noise_tex, v_wp.xz * 0.9 + vec2(v_wp.y * 0.4, 0.0)).r;
	float n2 = texture(noise_tex, vec2(v_wp.x + v_wp.z, v_wp.y * 0.2) * 2.3).r;
	// Ragged top of the wet band, with a few drips running down below it.
	float top = band_height * (0.65 + n * 0.6) + smoothstep(0.62, 0.8, n2) * 0.12;
	float wet = 1.0 - smoothstep(top - 0.03, top + 0.03, h);
	vec3 m = mix(vec3(1.0), wet_tint, wet);
	// Tide line: a thin pale stain 3-6 cm over the water.
	float px = max(fwidth(v_wp.y), 0.001);
	float tide = 1.0 - smoothstep(0.012, 0.012 + px * 1.5, abs(h - 0.045 - (n - 0.5) * 0.03));
	m = mix(m, vec3(1.25, 1.28, 1.2), tide * step(0.35, n2));
	// Light bounced off the water: bright soft bands crawling up and along the stone just above the surface.
	if (quality >= 1) {
		float t = TIME * 0.6;
		float r = texture(noise_tex, vec2(v_wp.x * 0.7 + v_wp.z * 0.7 + t * 0.3, h * 2.5 - t)).r;
		float band = smoothstep(0.55, 0.7, r) * (1.0 - smoothstep(0.05, 0.4, h)) * step(0.0, h);
		m *= 1.0 + band * 0.45;
	}
	ALBEDO = m;
}
