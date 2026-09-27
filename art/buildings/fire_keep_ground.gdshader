// fire_keep_ground.gdshader - the Fire Keep's ground contact (art-keep.md 0.5, "scorch" variant, task A.7):
// a ragged dark scorch under the keep, a hot glow where the lava channel spills onto the ground, glowing
// lava cracks running out of the plinth, and a burnt rune circle whose glyphs smoulder and slowly turn.
// One unshaded, alpha-blended quad (13 x 13 m). `darkness` 0 -> 1 turns it into the wreck's burnt patch.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 scorch_color : source_color = vec4(0.05, 0.03, 0.02, 0.66);
uniform vec3 crack_color : source_color = vec3(1.0, 0.45, 0.10);
uniform float crack_energy = 2.2;
uniform float rune_energy = 1.3;
uniform float darkness = 0.0;
uniform float size_m = 13.0;

float hash11(float x) {
	return fract(sin(x * 91.713) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float glyph(vec2 f, float id) {
	float d = seg(f, vec2(0.5, 0.12), vec2(0.5, 0.88));
	float h = hash11(id + 3.3);
	if (fract(h * 3.1) > 0.5) { d = min(d, seg(f, vec2(0.5, 0.88), vec2(0.2, 0.6))); }
	if (fract(h * 5.3) > 0.5) { d = min(d, seg(f, vec2(0.5, 0.88), vec2(0.8, 0.6))); }
	if (fract(h * 7.9) > 0.55) { d = min(d, seg(f, vec2(0.5, 0.4), vec2(0.2, 0.2))); }
	if (fract(h * 11.3) > 0.55) { d = min(d, seg(f, vec2(0.5, 0.4), vec2(0.8, 0.2))); }
	if (fract(h * 13.7) > 0.6) { d = min(d, seg(f, vec2(0.25, 0.5), vec2(0.75, 0.5))); }
	return d;
}

void fragment() {
	vec2 p = UV - 0.5;
	vec2 pm = p * size_m;                       // metres from the keep centre
	float round_d = length(p) * 2.0;
	float square_d = max(abs(p.x), abs(p.y)) * 2.0;
	float d = mix(round_d, square_d, 0.55);
	float n = texture(noise_tex, UV * 1.4).r;
	float n2 = texture(noise_tex, UV * 2.6 + vec2(0.37, 0.71)).r;
	float edge = d + (n - 0.5) * 0.45;
	float a = scorch_color.a * (1.0 - smoothstep(0.55, 0.98, edge));
	a = mix(a, 0.9 * (1.0 - smoothstep(0.75, 1.0, edge)), darkness);
	vec3 col = mix(scorch_color.rgb, vec3(0.02), darkness);

	// Heat spill: warm light on the ground just outside the plinth (square distance 3.6 - 4.6 m).
	float sq_m = max(abs(pm.x), abs(pm.y));
	float heat = (1.0 - smoothstep(3.55, 4.7, sq_m)) * smoothstep(3.3, 3.6, sq_m) * (0.75 + 0.25 * n);
	heat *= 1.0 - darkness * 0.8;
	col = mix(col, vec3(0.55, 0.16, 0.03), heat * 0.8);
	a = max(a, heat * 0.75);

	// Lava cracks: thin ridged-noise lines, from the plinth edge out to the scorch edge.
	float ridged = 1.0 - abs(n2 * 2.0 - 1.0);
	float c = smoothstep(0.935, 0.985, ridged) * smoothstep(0.5, 0.6, d) * (1.0 - smoothstep(0.7, 0.92, edge));
	float pulse = 0.65 + 0.35 * sin(TIME * 1.4 - d * 8.0);
	c *= 1.0 - darkness * 0.6;
	col += crack_color * c * crack_energy * pulse;

	// Rune circle (radius 4.75 - 5.45 m): burnt band, two thin rings, one smouldering glyph per cell.
	float r = length(pm);
	float r0 = 4.75;
	float r1 = 5.45;
	float band = smoothstep(r0 - 0.08, r0, r) * (1.0 - smoothstep(r1, r1 + 0.08, r));
	float lines = (1.0 - smoothstep(0.03, 0.07, abs(r - r0))) + (1.0 - smoothstep(0.03, 0.07, abs(r - r1)));
	float ang = atan(pm.y, pm.x) / 6.2831853 + 0.5 + TIME * 0.004;
	float cells = 40.0;
	float gx = ang * cells;
	float id = mod(floor(gx), cells);
	vec2 f = vec2(fract(gx), clamp((r - r0) / (r1 - r0), 0.0, 1.0));
	float gd = glyph(vec2(0.5 + (f.x - 0.5) * 1.1, 0.12 + f.y * 0.76), id);
	float g = (1.0 - smoothstep(0.05, 0.1, gd)) * band;
	float smoulder = 0.55 + 0.45 * sin(TIME * 0.9 + id * 1.7);
	float rune = (g * smoulder + lines * 0.7) * (1.0 - darkness * 0.7);
	col = mix(col, vec3(0.03, 0.015, 0.01), band * 0.5);
	a = max(a, band * 0.35);
	col += crack_color * rune * rune_energy;

	ALBEDO = col;
	ALPHA = clamp(max(a, max(c, rune)), 0.0, 1.0);
}
