shader_type spatial;
// forge_evenmead (copied from forge_citadel) glow cards (0 lights): every card is 2 triangles collapsed on its centre (baked into the set's one
// scatter mesh), expanded here to a camera-facing quad. UV = corner 0..1, UV2.x = radius (m), UV2.y = mode:
// 0 soft halo (lanterns, windows, fires), 1 star glint (gold gleam, water sparkle), 2 flat card (real geometry: a
// pool of light on a floor). Additive, no fog (it would add fog colour), fades very near and near the far plane.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float energy = 1.0;

varying float kind;
varying float ph;
varying float fade;

void vertex() {
	kind = UV2.y;
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ph = w.x * 1.31 + w.z * 0.73 + w.y * 0.51;
	vec4 c = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = -c.z;
	if (kind < 1.5) {
		// keep a minimum angular size so far lamps still read as sparks
		float s = max(UV2.x, d * 0.0035);
		vec2 k = UV * 2.0 - 1.0;
		c.xy += k * s;
		c.z += min(s * 0.9, d * 0.5);  // pull toward the camera: do not clip into the wall it sits on
	}
	fade = smoothstep(245.0, 170.0, d) * smoothstep(0.3, 2.5, d);
	// evenmead: pollen and seed fluff (tiny cards) only read close to the camera
	if (UV2.x < 0.08) {
		fade *= smoothstep(26.0, 9.0, d);
	}
	POSITION = PROJECTION_MATRIX * c;
}

void fragment() {
	vec2 k = UV * 2.0 - 1.0;
	float r = length(k);
	float soft = pow(max(1.0 - r, 0.0), 2.2);
	float core = pow(max(1.0 - r * 2.6, 0.0), 2.0);
	float a;
	if (kind > 0.5 && kind < 1.5) {
		float sx = max(0.0, 1.0 - abs(k.y) * 14.0) * pow(max(0.0, 1.0 - abs(k.x)), 2.0);
		float sy = max(0.0, 1.0 - abs(k.x) * 14.0) * pow(max(0.0, 1.0 - abs(k.y)), 2.0);
		float tw = 0.35 + 0.65 * pow(0.5 + 0.5 * sin(TIME * 1.9 + ph * 3.1), 3.0);
		a = ((sx + sy) * 1.1 + core * 1.4 + soft * 0.25) * tw;
	} else if (kind > 1.5) {
		a = soft * 0.9;
	} else {
		a = (soft * 0.75 + core * 0.6) * (1.0 + 0.1 * sin(TIME * 5.3 + ph));
	}
	ALBEDO = COLOR.rgb * energy * a * fade * COLOR.a;
}
