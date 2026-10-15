// fire_keep_runes.gdshader - the floating rune band around the Ember Heart (task A.7).
// Additive, two-sided: a faint band with two border lines and one glowing glyph per cell (UV.x runs
// around the band, UV.y across it). Glyphs are built from 3-5 strokes picked by a per-cell hash.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float energy = 3.0;
uniform float cells = 26.0;
uniform float boost = 1.0;
uniform float pulse_speed = 1.3;

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
	float h = hash11(id + 1.7);
	if (fract(h * 3.1) > 0.5) { d = min(d, seg(f, vec2(0.5, 0.88), vec2(0.18, 0.62))); }
	if (fract(h * 5.3) > 0.5) { d = min(d, seg(f, vec2(0.5, 0.88), vec2(0.82, 0.62))); }
	if (fract(h * 7.9) > 0.55) { d = min(d, seg(f, vec2(0.5, 0.45), vec2(0.18, 0.22))); }
	if (fract(h * 11.3) > 0.55) { d = min(d, seg(f, vec2(0.5, 0.45), vec2(0.82, 0.22))); }
	if (fract(h * 13.7) > 0.6) { d = min(d, seg(f, vec2(0.22, 0.5), vec2(0.78, 0.5))); }
	return d;
}

void fragment() {
	float x = UV.x * cells;
	float id = floor(x);
	vec2 f = vec2(fract(x), UV.y);
	float d = glyph(vec2(0.5 + (f.x - 0.5) * 1.25, 0.16 + f.y * 0.68), id);
	float g = 1.0 - smoothstep(0.045, 0.085, d);
	float border = 1.0 - smoothstep(0.03, 0.07, min(UV.y, 1.0 - UV.y));
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + id * 0.9);
	float v = g * pulse + border * 0.55 + 0.06;
	ALBEDO = glow_color * energy * boost * v;
}
