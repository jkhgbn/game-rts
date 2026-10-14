// Muster Pad token (ui-wave-strike.md 7.1): disc body, role rim, rank band, upgrade ticks; see MusterPadView.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always, blend_mix, shadows_disabled;
uniform vec4 body_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 warn : source_color = vec4(0.95, 0.35, 0.3, 1.0);
uniform float radius = 0.65;
uniform float rim_w = 0.12;
uniform float band_w = 0.1;
uniform float tick = 0.25;
uniform float height = 0.15;
varying vec3 lp;
varying vec4 cdata;
varying vec4 rcol;
void vertex() {
	lp = VERTEX;
	cdata = INSTANCE_CUSTOM;
	rcol = COLOR;
}
bool in_tick(vec2 p, vec2 dir) {
	float u = radius - dot(p, dir);
	float v = abs(dir.x * p.y - dir.y * p.x);
	float len = tick * 0.9;
	return u >= 0.0 && u <= len && v <= tick * 0.5 * (1.0 - u / len);
}
void fragment() {
	vec2 p = lp.xz;
	float r = length(p);
	bool top = lp.y > height - 0.002;
	bool rim = !top || r > radius - rim_w;
	vec3 role = pow(rcol.rgb, vec3(2.2));
	vec3 col = rim ? role : body_color.rgb;
	if (!top) col *= 0.7;
	float up = cdata.y;
	bool a_tick = mod(up, 2.0) > 0.5;
	bool b_tick = up > 1.5;
	if (top) {
		// rank band: gold arc on the rim, 60 deg per rank from the back (+Z), clockwise seen from above
		float ang = atan(-p.x, p.y);
		if (ang < 0.0) ang += 6.2831853;
		if (r > radius - band_w && ang < cdata.x * 1.0471976) col = gold.rgb;
		// upgrade ticks: A front-right, B front-left (front = -Z)
		if (a_tick && in_tick(p, normalize(vec2(1.0, -1.0)))) col = gold.rgb;
		if (b_tick && in_tick(p, normalize(vec2(-1.0, -1.0)))) col = gold.rgb;
	}
	if (rim) col = mix(col, vec3(1.0), clamp(cdata.z, 0.0, 1.0));
	float f = cdata.w;
	if (f > 0.0) col = mix(col, glow.rgb, rim ? f : f * 0.5);
	if (f < 0.0 && rim) col = mix(col, warn.rgb, -f);
	ALBEDO = col;
	ALPHA = rcol.a;
}
