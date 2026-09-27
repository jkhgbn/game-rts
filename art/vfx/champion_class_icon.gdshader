shader_type spatial;
// Camera-facing class badges over champions and units (ChampionVfx, task 11.V6). QuadMesh 1 x 1, size = node scale.
// A dark round medallion with a glowing rim in `tint` and a glyph (the ui-champions.md 15.1 class glyphs):
//   icon 0 spear (shaft + leaf blade)     1 sword and shield     2 two-hand sword     3 wizard staff + crystal
//   icon 4 armor break (Crushing Blow): a cracked shield, the crack glowing in `tint`
// Drawn on top of bodies (no depth test) like the step-9 icons, with a dark outline so it reads on any ground.
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.6, 0.8, 1.0);   // glow colour (linear HDR)
instance uniform float icon = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float tri(vec2 p, vec2 a, vec2 b, vec2 c) {
	// < 0 inside (approximate signed distance for a small triangle).
	vec2 e0 = b - a;
	vec2 e1 = c - b;
	vec2 e2 = a - c;
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	float d0 = s * (e0.x * (p.y - a.y) - e0.y * (p.x - a.x)) / length(e0);
	float d1 = s * (e1.x * (p.y - b.y) - e1.y * (p.x - b.x)) / length(e1);
	float d2 = s * (e2.x * (p.y - c.y) - e2.y * (p.x - c.x)) / length(e2);
	return -min(min(d0, d1), d2);
}

float line_m(float d, float w) {
	return 1.0 - smoothstep(w * 0.7, w, d);
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);   // y up
	float r = length(p);
	float flash = exp(-age * 5.0);
	int k = int(icon + 0.5);
	vec3 emit = vec3(0.0);
	float cover = 0.0;
	vec3 dark = vec3(0.02, 0.025, 0.035);
	float glyph = 0.0;
	float glyph_fill = 0.0;
	if (k < 4) {
		float disc = 1.0 - smoothstep(0.8, 0.84, r);
		float rim = exp(-pow((r - 0.78) * 18.0, 2.0));
		float outline = (1.0 - smoothstep(0.84, 0.98, r)) * (1.0 - disc);
		vec2 q = p / 0.62;   // glyph box: r = 1 (the 15.1 unit r = 0.375 s -> scale up to fill the medallion)
		if (k == 0) {
			glyph = line_m(seg(q, vec2(-0.8, -0.8), vec2(0.55, 0.55)), 0.11);
			glyph_fill = 1.0 - smoothstep(-0.02, 0.03, tri(q, vec2(0.95, 0.95), vec2(0.3, 0.65), vec2(0.65, 0.3)));
			glyph = max(glyph, line_m(seg(q, vec2(0.25, 0.62), vec2(0.62, 0.25)), 0.09));   // tassel bar
		} else if (k == 1) {
			// Shield: straight sides from y 0.55 down to 0.05, then tapering to a point at y -0.6.
			float hw = q.y > 0.05 ? 0.5 : 0.5 * clamp((q.y + 0.6) / 0.65, 0.0, 1.0);
			float sd = max(max(abs(q.x) - hw, q.y - 0.55), -0.6 - q.y);
			glyph_fill = (1.0 - smoothstep(-0.02, 0.02, sd)) * 0.45;
			glyph = line_m(abs(sd), 0.07);                                                   // shield outline
			glyph = max(glyph, line_m(seg(q, vec2(-0.75, -0.75), vec2(0.75, 0.75)), 0.1));   // sword
			glyph = max(glyph, line_m(seg(q, vec2(-0.55, -0.25), vec2(-0.25, -0.55)), 0.09)); // cross-guard
		} else if (k == 2) {
			glyph = line_m(seg(q, vec2(0.0, -0.5), vec2(0.0, 0.95)), 0.14);                 // blade
			glyph = max(glyph, line_m(seg(q, vec2(-0.55, -0.35), vec2(0.55, -0.35)), 0.1)); // cross-guard
			glyph = max(glyph, line_m(seg(q, vec2(0.0, -0.35), vec2(0.0, -0.85)), 0.09));   // grip
			glyph = max(glyph, 1.0 - smoothstep(0.13, 0.18, length(q - vec2(0.0, -0.92))));  // pommel
		} else {
			glyph = line_m(seg(q, vec2(-0.3, -0.95), vec2(0.3, 0.45)), 0.1);
			vec2 c = q - vec2(0.42, 0.68);
			float dia = abs(c.x) + abs(c.y);
			glyph_fill = 1.0 - smoothstep(0.3, 0.36, dia);
			emit += vec3(0.8, 1.0, 1.6) * exp(-dot(c, c) * 8.0) * 0.6;
		}
		glyph = clamp(glyph, 0.0, 1.0) * disc;
		glyph_fill = clamp(glyph_fill, 0.0, 1.0) * disc;
		float beat = 0.85 + 0.15 * sin(TIME * 6.0 + seed);
		vec3 hot = mix(tint.rgb, vec3(1.6, 1.55, 1.45), 0.55);
		emit += tint.rgb * rim * 1.3 * beat + hot * max(glyph, glyph_fill) * (1.1 + flash) + tint.rgb * disc * flash * 0.5;
		cover = disc * 0.8 + outline * 0.55;
		cover *= 1.0 - max(glyph, glyph_fill) * 0.9;
	} else {
		// Cracked heater shield (the step-9 taunt badge outline), a jagged crack glowing through it.
		float halfw = p.y > 0.0 ? 0.62 : 0.62 * sqrt(clamp((p.y + 0.9) / 0.9, 0.0, 1.0));
		float top = 0.62 + 0.1 * (1.0 - p.x * p.x);
		float sd = max(abs(p.x) - halfw, p.y - top);
		float inside = 1.0 - smoothstep(-0.02, 0.02, sd);
		float rim = inside * smoothstep(-0.18, -0.1, sd);
		float outline = (1.0 - smoothstep(0.0, 0.12, sd)) * (1.0 - inside);
		float cx = 0.08 * sin(p.y * 11.0 + 1.3) + 0.05 * sin(p.y * 23.0) - p.y * 0.08;
		float crack = (1.0 - smoothstep(0.03, 0.07, abs(p.x - cx))) * inside;
		float branch = line_m(seg(p, vec2(0.02, 0.1), vec2(0.38, -0.12)), 0.05) * inside;
		float split = sign(p.x - cx) * 0.03;   // the halves drift apart a little
		float beat = 0.7 + 0.3 * sin(TIME * 8.0 + seed);
		emit = vec3(0.7, 0.72, 0.8) * rim * 0.8 + tint.rgb * (crack + branch) * (1.4 + flash) * beat;
		cover = inside * 0.85 + outline * 0.55;
		cover *= 1.0 - max(crack, branch) * 0.8;
		dark = vec3(0.07, 0.07, 0.09) + vec3(split);
	}
	float al = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * al;
	ALPHA = al;
}
