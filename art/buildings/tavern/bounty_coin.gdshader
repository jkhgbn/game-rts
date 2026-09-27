// bounty_coin.gdshader - the spinning gold coin on top of a bounty flag (task 9.V6).
// Mesh: a disc whose faces look along mesh-local +-Z (radius `radius`), built by bounty_flag.gd.
// The spin (about local Y) and the bob run here, so a flag costs no CPU per frame.
// Faces: gold with a raised rim, a thin groove and the kind icon engraved dark (the same on both faces, never
// mirrored); the edge band is the owner's team colour (like the minimap coin's border); a glint sweeps across.
// Instance uniforms (per flag): kind (0 Hunt, 1 Explore, 2 Guard, 3 Escort), team_color (sRGB), phase, highlight.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/buildings/tavern/bounty_icons.gdshaderinc"

uniform vec3 gold_color : source_color = vec3(0.96, 0.74, 0.30);
uniform vec3 engrave_color : source_color = vec3(0.30, 0.17, 0.05);
uniform float radius = 0.35;
uniform float half_thickness = 0.04;
uniform float spin_speed = 1.05;
uniform float bob = 0.035;
uniform float glow = 0.22;

instance uniform float kind = 0.0;
instance uniform vec4 team_color = vec4(0.85, 0.30, 0.12, 1.0);
instance uniform float phase = 0.0;
instance uniform float highlight = 0.0;

varying vec3 v_lp;
varying vec3 v_ln;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	v_lp = VERTEX;
	v_ln = NORMAL;
	float a = TIME * spin_speed + phase;
	float c = cos(a);
	float s = sin(a);
	VERTEX.xz = vec2(c * VERTEX.x + s * VERTEX.z, -s * VERTEX.x + c * VERTEX.z);
	NORMAL.xz = vec2(c * NORMAL.x + s * NORMAL.z, -s * NORMAL.x + c * NORMAL.z);
	VERTEX.y += sin(TIME * 1.4 + phase * 1.7) * bob;
}

void fragment() {
	vec3 ln = normalize(v_ln);
	float face = step(0.5, abs(ln.z));
	vec2 p = v_lp.xy / radius;
	if (ln.z < 0.0) {
		p.x = -p.x;
	}
	float r = length(p);
	vec3 gold = gold_color;
	// Raised rim (brighter), a dark groove inside it, a softly domed field.
	float rim = smoothstep(0.80, 0.84, r);
	float groove = 1.0 - smoothstep(0.012, 0.03, abs(r - 0.77));
	vec3 col = gold * mix(0.9 - r * 0.08, 1.14, rim);
	col = mix(col, engrave_color * 1.6, groove * 0.7);
	float ic = icon_mask(int(kind + 0.5), p * 1.12);
	col = mix(col, engrave_color, ic);
	// Edge band: team colour with thin gold lips.
	vec3 team = srgb_to_linear(team_color.rgb);
	float lip = smoothstep(0.55, 0.8, abs(v_lp.z) / half_thickness);
	vec3 edge = mix(team, gold, lip);
	col = mix(edge, col, face);
	// Glint sweeping across the faces every few seconds.
	float sweep = fract(TIME * 0.33 + phase * 0.13) * 4.0 - 1.5;
	float g = (1.0 - smoothstep(0.0, 0.1, abs((p.x + p.y) * 0.707 - sweep))) * face * (1.0 - ic) * step(r, 1.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col;
	EMISSION = col * glow * (1.0 - ic) + gold * g * 2.6 + gold * fres * (0.25 + highlight * 1.2)
		+ gold * highlight * 0.35;
	ROUGHNESS = 0.45;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 18.0) * 0.6 * LIGHT_COLOR * ATTENUATION / PI;
}
