shader_type spatial;
// Rime Aegis / Rime Seer shield: a shimmering hemisphere of ice facets around one unit (SphereMesh
// hemisphere radius 1, scaled). Fresnel rim + faint facet lines + a bright band that sweeps upward.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 dome_color : source_color = vec3(0.55, 0.86, 1.00);
uniform float energy = 1.5;
instance uniform float fade = 1.0;
instance uniform float phase = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float ang = atan(lp.z, lp.x) / 6.2831853 + 0.5;
	vec2 cell = vec2(ang * 14.0 + floor(lp.y * 5.0) * 0.5, lp.y * 5.0);
	vec2 f = abs(fract(cell) - 0.5);
	float facet = smoothstep(0.42, 0.5, max(f.x, f.y));
	float sweep = 1.0 - smoothstep(0.0, 0.12, abs(fract(lp.y * 0.9 - TIME * 0.55 + phase) - 0.5));
	float base = smoothstep(0.12, 0.0, lp.y);
	ALBEDO = dome_color * energy;
	ALPHA = clamp(0.06 + fres * 0.75 + facet * (0.12 + sweep * 0.35) + sweep * 0.12 + base * 0.4, 0.0, 1.0) * fade;
}
