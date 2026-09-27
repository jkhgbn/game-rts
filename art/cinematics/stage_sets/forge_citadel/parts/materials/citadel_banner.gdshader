shader_type spatial;
// forge_citadel banner cloth: colour from vertex colour, UV.x = distance from the pole / top edge (0 = fixed), waves in
// the cloth normal direction (baked in UV2 as a 2D hint is not needed: we sway along world z and x a little).
render_mode cull_disabled;

uniform float amp = 0.35;
uniform float freq = 2.2;

void vertex() {
	float w = UV.x;
	float ph = VERTEX.x * 0.9 + VERTEX.z * 0.7 + VERTEX.y * 0.4;
	float s = sin(TIME * freq + ph + w * 4.0) * amp * w;
	VERTEX += NORMAL * s;
}

void fragment() {
	float fold = 0.82 + 0.18 * sin(UV.x * 18.0 + TIME * 2.0);
	ALBEDO = COLOR.rgb * fold;
	ROUGHNESS = 0.85;
}
