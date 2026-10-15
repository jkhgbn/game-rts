// hp_bar.gdshader - the in-world HP bar of a unit (graphics week G-D, scripts/units/fx/unit_fx.gd). Billboard quad
// (QuadMesh, UV x = along the bar, UV y = 0 top -> 1 bottom), drawn on top (depth_test_disabled, as before).
// ONE shared material per fill colour / frame style / tier (UnitFx.bar_material), never one per unit; the unit's values
// are instance uniforms, written by Unit._update_hp_bar only when they change (no per-frame GDScript per unit).
// Instance uniform slots (the bar is its own MeshInstance3D, so they never meet the model kit's slots):
//   0 fill        HP / total (total = max(max_hp, hp + shield))
//   1 shield_end  (HP + shield) / total: the shield segment after the HP
//   2 trail_from  the fill before the last hit (the white "recent damage" trail starts there)
//   3 trail_t0    UnitFx.now() at that hit; the trail holds TRAIL_HOLD s then drains to the fill in TRAIL_DRAIN s
//   4 tick_step   100 HP as a fraction of the bar (0 = no ticks; only max_hp >= 400, drawn at gfx_tier 2+)
//   5 bar_size    the quad's size in metres (rounded ends, frame widths)
// Material uniforms: frame_color / frame_size (m) / inner_size (m) keep the champion gold frame (Unit._hp_bar_frame_style),
// ramp_k 1 = own units go green -> yellow -> red with the fill, fx_now = UnitFx clock (UnitFx.Clock, only while a trail runs).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform vec4 fill_color : source_color = vec4(0.2, 0.9, 0.25, 1.0);
uniform vec4 back_color : source_color = vec4(0.05, 0.05, 0.06, 0.85);
uniform vec4 frame_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 frame_size = vec2(0.022, 0.022);
uniform vec2 inner_size = vec2(0.0, 0.0);
uniform float ramp_k = 0.0;
uniform int gfx_tier = 0;
uniform float fx_now = 0.0;
uniform float trail_hold = 0.3;
uniform float trail_drain = 0.5;

instance uniform float fill : instance_index(0) = 1.0;
instance uniform float shield_end : instance_index(1) = 0.0;
instance uniform float trail_from : instance_index(2) = 0.0;
instance uniform float trail_t0 : instance_index(3) = -100.0;
instance uniform float tick_step : instance_index(4) = 0.0;
instance uniform vec2 bar_size : instance_index(5) = vec2(1.0, 0.16);

void vertex() {
	// Always face the camera (billboard).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * bar_size;
	float fw = max(fwidth(p.x), 0.0005);   // one pixel in metres (derivatives at the top: shader lint rule B)
	vec2 hs = bar_size * 0.5;
	float rad = hs.y * 0.7;
	float d = sd_round_box(p, hs, rad);
	float shape = 1.0 - smoothstep(-fw, fw * 0.5, d);
	float vy = UV.y;
	// Inner area (inside the frame and the optional black line).
	float f_in = frame_size.y + inner_size.y;
	vec2 ihs = max(hs - vec2(f_in), vec2(0.001));
	float t = clamp((p.x + ihs.x) / (2.0 * ihs.x), 0.0, 1.0);
	float ft = fw / (2.0 * ihs.x);
	float k_frame = smoothstep(-frame_size.y - fw, -frame_size.y + fw * 0.5, d);
	float k_inner = smoothstep(-f_in - fw, -f_in + fw * 0.5, d);

	// Recent-damage trail: the bar the unit had before the hit, holding then draining to the fill.
	float age = fx_now - trail_t0;
	age = age < -1.0 ? 99.0 : max(age, 0.0);
	float dk = clamp((age - trail_hold) / trail_drain, 0.0, 1.0);
	dk = dk * dk * (3.0 - 2.0 * dk);
	float trail = mix(max(trail_from, fill), fill, dk);

	// Fill colour: own units ramp green -> yellow -> red with the fill; other teams keep their colour.
	vec3 red = vec3(0.92, 0.18, 0.12);
	vec3 yellow = vec3(0.98, 0.80, 0.16);
	vec3 ramp = fill < 0.5 ? mix(red, yellow, smoothstep(0.1, 0.5, fill)) : mix(yellow, fill_color.rgb, smoothstep(0.5, 0.85, fill));
	vec3 fc = mix(fill_color.rgb, ramp, ramp_k);
	float shade = mix(1.28, 0.70, vy);
	float gloss = (1.0 - smoothstep(0.08, 0.42, vy)) * 0.22;
	fc = fc * shade + vec3(gloss);

	float in_fill = 1.0 - smoothstep(fill - ft, fill + ft, t);
	float in_shield = (1.0 - smoothstep(shield_end - ft, shield_end + ft, t)) * (1.0 - in_fill);
	float in_trail = (1.0 - smoothstep(trail - ft, trail + ft, t)) * (1.0 - in_fill) * (1.0 - in_shield);
	vec3 back = back_color.rgb * mix(0.7, 1.3, vy);
	vec3 c = back;
	float a = back_color.a;
	c = mix(c, vec3(1.0, 0.95, 0.86) * mix(1.05, 0.8, vy), in_trail);
	c = mix(c, vec3(0.86, 0.93, 1.0) * mix(1.12, 0.78, vy), in_shield);
	c = mix(c, fc, in_fill);
	a = mix(a, 1.0, max(in_fill, max(in_shield, in_trail)));

	if (gfx_tier >= 2 && tick_step > 0.0) {
		// Segment ticks every 100 HP (big units), on the upper part of the bar.
		float s = t / tick_step;
		float dist = abs(fract(s + 0.5) - 0.5) * tick_step * 2.0 * ihs.x;
		float tick = (1.0 - smoothstep(0.006, 0.006 + fw, dist)) * (1.0 - smoothstep(0.62, 0.7, vy));
		tick *= step(tick_step * 0.5, t) * step(t, 1.0 - tick_step * 0.5);
		c *= 1.0 - tick * 0.5;
	}

	// Black line inside the frame (champions), then the frame with a bevel (lit top, dark bottom).
	c = mix(c, vec3(0.0), k_inner * (1.0 - k_frame));
	a = mix(a, 1.0, k_inner);
	vec3 fr = frame_color.rgb * mix(1.45, 0.6, vy) + frame_color.rgb * (1.0 - smoothstep(0.0, 0.25, vy)) * 0.35;
	c = mix(c, fr, k_frame);
	a = mix(a, frame_color.a, k_frame);
	ALBEDO = c;
	ALPHA = a * shape;
}
