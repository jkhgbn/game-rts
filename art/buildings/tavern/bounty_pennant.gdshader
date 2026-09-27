// bounty_pennant.gdshader - the team-colour pennant of a bounty flag (task 9.V6).
// Mesh: a vertical PlaneMesh (orientation Z), UV.y = 0 at the top (fixed) edge. Waves in the vertex shader.
// Look: team cloth with darker side borders, a gold hem at the top, a swallow-tail cut, and the kind icon in gold
// with a dark outline (reads on any team colour) inside a thin gold ring. Two-sided, the icon is never mirrored.
// Instance uniforms (per flag): kind (0 Hunt, 1 Explore, 2 Guard, 3 Escort), team_color (sRGB), phase, highlight.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

#include "res://art/buildings/tavern/bounty_icons.gdshaderinc"

uniform vec3 trim_color : source_color = vec3(0.96, 0.76, 0.32);
uniform vec3 outline_color : source_color = vec3(0.10, 0.07, 0.05);
uniform vec2 size = vec2(0.56, 0.74);
uniform float icon_radius = 0.19;
uniform float icon_y = 0.46;
uniform float amplitude = 0.05;
uniform float speed = 2.4;

instance uniform float kind = 0.0;
instance uniform vec4 team_color = vec4(0.85, 0.30, 0.12, 1.0);
instance uniform float phase = 0.0;
instance uniform float highlight = 0.0;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	float w = UV.y;
	VERTEX.z += sin(TIME * speed + UV.y * 5.0 + UV.x * 1.6 + phase) * amplitude * w;
	VERTEX.x += sin(TIME * speed * 0.41 + UV.y * 2.0 + phase) * amplitude * 0.35 * w;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float notch = 0.2 * (1.0 - abs(u - 0.5) * 2.0);
	if (v > 1.0 - notch) {
		discard;
	}
	vec3 team = srgb_to_linear(team_color.rgb);
	vec3 dark = team * 0.5;
	vec3 gold = trim_color;
	vec3 col = team;
	// Soft vertical folds.
	col *= 0.93 + 0.07 * sin(u * 19.0 + v * 2.0);
	// Side borders, gold hem at the top, a dark band along the swallow-tail.
	float border = 1.0 - step(0.075, u) * step(u, 0.925);
	col = mix(col, dark, border);
	col = mix(col, dark, step(1.0 - notch - 0.075, v));
	col = mix(col, gold, step(v, 0.1));
	col = mix(col, dark, step(0.1, v) * step(v, 0.13));
	// Icon: gold with a dark outline, inside a thin gold ring.
	vec2 pm = vec2((u - 0.5) * size.x, (icon_y - v) * size.y) / icon_radius;
	if (!FRONT_FACING) {
		pm.x = -pm.x;
	}
	int k = int(kind + 0.5);
	float d = icon_sd(k, pm);
	float aa = max(fwidth(d), 0.002);
	float ring_d = abs(length(pm) - 1.02) - 0.045;
	float ring = 1.0 - smoothstep(-aa, aa, ring_d);
	float outline = 1.0 - smoothstep(0.1 - aa, 0.1 + aa, min(d, ring_d));
	float icon = 1.0 - smoothstep(-aa, aa, d);
	col = mix(col, outline_color, outline);
	col = mix(col, gold, max(icon, ring));
	// Fold shadow near the fixed top edge.
	col *= mix(0.82, 1.04, smoothstep(0.0, 0.3, v));
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = col;
	EMISSION = gold * max(icon, ring) * 0.35 + team * rim * (0.15 + highlight * 0.8) + team * highlight * 0.25;
	ROUGHNESS = 1.0;
}

void light() {
	float d = abs(dot(NORMAL, LIGHT)) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
