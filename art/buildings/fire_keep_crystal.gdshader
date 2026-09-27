// fire_keep_crystal.gdshader - the orbiting ember crystals (task A.7). Unshaded but faceted: each flat
// face gets its own brightness from a fixed "light" direction, plus a white-hot fresnel edge, so the
// crystals read as cut gems instead of flat stickers. glow_color follows the team (set_team_color).
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 glow_color : source_color = vec3(1.0, 0.6, 0.18);
uniform float energy = 3.2;
uniform float pulse_speed = 3.0;
uniform int rune_bands = 0;
uniform float boost = 1.0;
uniform float phase = 0.0;

void fragment() {
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float facet = clamp(dot(wn, normalize(vec3(0.35, 0.85, 0.40))) * 0.5 + 0.5, 0.0, 1.0);
	facet = 0.35 + 0.65 * facet * facet;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed + phase);
	vec3 col = glow_color * facet * energy * pulse + mix(glow_color, vec3(1.0, 0.95, 0.8), 0.6) * fres * 1.6;
	ALBEDO = col * boost;
}
