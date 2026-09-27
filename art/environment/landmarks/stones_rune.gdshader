// stones_rune.gdshader - the faint carved runes of the Standing Stones (task 12.V14, map-fill.md 3.2 / 10).
// A thin emissive surface of standing_stones.res (surface 2), baked by build_landmarks_b.gd:
//   COLOR.rgb  rune colour (sRGB)
//   COLOR.a    per-stone phase 0-1 (each stone breathes on its own beat)
//   UV.y       local height in metres (the glow climbs the stone in a slow wave)
// FAINT on purpose (art-keep.md 0.4: 2-4 glow points at 40 m belong to buildings / points, not decor): the base
// energy stays under the bloom threshold (1.2) and only the crest of the slow wave crosses it, so a rune softly
// flares now and then instead of the ring reading as a glow point. No light, no texture, no alpha.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Art Lab R5 pass: resting energy 0.5 -> 0.2 and flare 0.85 -> 0.5 (at 0.5 every stone's runes read as a separate
// glow point at 40 m: 7 points, landmark rule 0-3); the albedo inlay (ember) goes up so the carving still reads.
uniform float energy = 0.2;          // resting glow (under the bloom threshold)
uniform float flare = 0.5;           // extra energy at the crest of the wave
uniform float wave_speed = 0.45;     // cycles per second
uniform float wave_scale = 0.55;     // cycles per metre up the stone
uniform float ember = 0.26;         // ALBEDO share: the carving reads as a faint inlay in daylight

varying vec3 v_col;
varying float v_phase;
varying float v_y;

void vertex() {
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_phase = COLOR.a;
	v_y = UV.y;
}

void fragment() {
	float w = fract(TIME * wave_speed * 0.25 + v_phase - v_y * wave_scale * 0.25);
	// A soft crest travelling up: 0 most of the time, 1 at the crest.
	float crest = smoothstep(0.0, 0.35, w) * (1.0 - smoothstep(0.35, 0.75, w));
	float breathe = 0.85 + 0.15 * sin(TIME * 1.3 + v_phase * 6.2831);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 core = mix(v_col, vec3(1.0), 0.35 * crest + 0.2 * fres);
	ALBEDO = v_col * ember;
	EMISSION = core * (energy * breathe + flare * crest);
	ROUGHNESS = 0.6;
	SPECULAR = 0.2;
}
