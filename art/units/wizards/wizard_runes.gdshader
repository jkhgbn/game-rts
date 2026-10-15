// wizard_runes.gdshader - G3a hero rune bands (art/units/wizards, docs/art/g3a_wizards.md).
// A strip of procedural glyphs (no texture): UV.x runs along the band (one glyph per 1/cells), UV.y across it.
// Each glyph is 3-6 strokes picked by a hash from 8 candidates (spine, chevrons, arms, a ring, a cross bar), drawn as
// anti-aliased distance strokes on a dark inlay with two thin border lines. The glyphs breathe (per-glyph phase) and
// a brighter wave runs along the band. glow_boost (instance uniform, kit slot 5 like unit_glow) is driven by the kit:
// veterancy / haste raise it, death fades it to 0; the wizard script adds cast flares on top through `flare`.
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.10, 0.05, 0.03);
uniform vec3 rune_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float cells = 12.0;          // glyphs along the whole band (UV.x 0..1)
uniform float aspect = 1.0;          // glyph cell width / height in metres (keeps the strokes round)
uniform float energy = 2.4;          // emission of a lit stroke at pulse 1
uniform float pulse_speed = 1.7;     // rad/s of the per-glyph breathing
uniform float wave_speed = 0.22;     // travelling wave, band lengths per second
uniform float stroke = 0.075;        // stroke half-width (cell units)
uniform float border = 0.13;         // border lines position from each edge (fraction of UV.y)
uniform float border_energy = 0.55;
uniform float seed = 0.0;
uniform float metallic_v : hint_range(0.0, 1.0) = 0.35;
uniform float roughness_v : hint_range(0.0, 1.0) = 0.5;
instance uniform float glow_boost : instance_index(5) = 1.0;
instance uniform float flare : instance_index(13) = 0.0;   // kit slot table (art/units/kit/README.md)

float h1(float n) {
	return fract(sin(n * 91.3458 + seed * 7.13) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

// Distance to the glyph `id` at p (cell space: x 0..aspect, y 0..1).
float glyph(vec2 p, float id) {
	float cx = 0.5 * aspect;
	float w = 0.30;                     // glyph half-width in glyph-height units (aspect only adds spacing)
	float d = seg(p, vec2(cx, 0.12), vec2(cx, 0.88));                       // spine, always on
	if (h1(id + 1.0) > 0.45) d = min(d, seg(p, vec2(cx, 0.88), vec2(cx + w, 0.64)));
	if (h1(id + 2.0) > 0.45) d = min(d, seg(p, vec2(cx, 0.88), vec2(cx - w, 0.64)));
	if (h1(id + 3.0) > 0.50) d = min(d, seg(p, vec2(cx, 0.52), vec2(cx + w, 0.30)));
	if (h1(id + 4.0) > 0.50) d = min(d, seg(p, vec2(cx, 0.52), vec2(cx - w, 0.30)));
	if (h1(id + 5.0) > 0.70) d = min(d, seg(p, vec2(cx - w, 0.50), vec2(cx + w, 0.50)));
	if (h1(id + 6.0) > 0.60) d = min(d, seg(p, vec2(cx, 0.12), vec2(cx + w * 0.8, 0.26)));
	if (h1(id + 7.0) > 0.72) d = min(d, abs(length(p - vec2(cx, 0.70)) - 0.13));
	return d;
}

void fragment() {
	float u = UV.x * cells;
	float id = floor(u);
	float y = clamp((UV.y - border) / max(1.0 - 2.0 * border, 0.01), -0.2, 1.2);
	vec2 p = vec2(fract(u) * aspect, y);
	float d = glyph(p, id);
	float aa = max(fwidth(d), 0.0015);
	float ink = 1.0 - smoothstep(stroke - aa, stroke + aa, d);
	ink *= step(0.0, y) * step(y, 1.0);
	float bd = min(abs(UV.y - border * 0.5), abs(UV.y - (1.0 - border * 0.5)));
	float baa = max(fwidth(UV.y), 0.001);
	float line = 1.0 - smoothstep(0.02 - baa, 0.02 + baa, bd);
	float breathe = 0.62 + 0.38 * sin(TIME * pulse_speed + h1(id + 9.0) * 6.2832);
	float wave = pow(1.0 - fract(UV.x - TIME * wave_speed), 5.0);
	float lit = ink * (breathe + 1.4 * wave) + line * border_energy * (0.8 + 0.6 * wave);
	float g = glow_boost * (1.0 + flare);
	ALBEDO = mix(base_color, rune_color * 0.55, clamp(ink + line * 0.6, 0.0, 1.0));
	METALLIC = metallic_v;
	ROUGHNESS = roughness_v;
	EMISSION = rune_color * energy * lit * g;
}
