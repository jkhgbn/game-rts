shader_type spatial;
// Rime Aegis / Rime Seer shield: a HOLLOW ice-rim hemisphere around one unit (SphereMesh hemisphere radius 1,
// scaled). In-game grade pass (2026-09-30): alpha-blended (it was additive and near-white and hid Torvald and his
// targets), steel / cyan tint, colour kept at or under the bloom threshold (energy <= 1.5, brightest band ~1.1),
// and the face of the dome toward the camera is clear: only the silhouette rim, a thin base band, faint facet
// lines and one thin sweeping band show, so the unit inside keeps its colours and its face.
// 2026-10-12: rim alpha 0.6 -> 0.5, base band 0.5 -> 0.3, cap 0.75 -> 0.65 (grouped domes still hid the feet).
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 dome_color : source_color = vec3(0.30, 0.80, 1.00);   // saturated cyan (rim, band, base)
uniform vec3 steel_color : source_color = vec3(0.22, 0.40, 0.58);  // steel-blue facet lines
uniform float energy = 1.1;     // <= 1.5: stays under the bloom
uniform float rim_alpha = 0.5;
instance uniform float fade = 1.0;
instance uniform float phase = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Hollow: nothing where the dome faces the camera, a crisp rim where it turns away.
	float rim = smoothstep(0.45, 0.12, nv);
	float ang = atan(lp.z, lp.x) / 6.2831853 + 0.5;
	vec2 cell = vec2(ang * 14.0 + floor(lp.y * 5.0) * 0.5, lp.y * 5.0);
	vec2 f = abs(fract(cell) - 0.5);
	float facet = smoothstep(0.46, 0.5, max(f.x, f.y));
	float sweep = 1.0 - smoothstep(0.0, 0.04, abs(fract(lp.y * 0.9 - TIME * 0.55 + phase) - 0.5));
	float base = smoothstep(0.07, 0.0, lp.y);
	vec3 col = mix(steel_color, dome_color, clamp(rim + sweep + base, 0.0, 1.0));
	ALBEDO = col * energy;
	ALPHA = clamp(rim * rim_alpha + facet * (0.06 + rim * 0.2) + sweep * (0.08 + rim * 0.2) + base * 0.3,
			0.0, 0.65) * fade;
}
