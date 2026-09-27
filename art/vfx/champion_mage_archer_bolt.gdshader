shader_type spatial;
// Mage Archer projectiles and beams (ChampionVfx + ChampionMageArcherVfx, task 13b.V8). A QuadMesh 1 x 1 drawn as a
// billboard that only turns around its own Y axis (like champion_bolt): node basis Y = direction x length, X = width.
// Head at +Y. Premultiplied alpha: `cover` draws the sable (black) parts, the rest is light.
//   style 0 arcane arrow  her shot: a white-violet arrowhead, a thin shaft of light, two swept vanes of glow, a tail
//   style 1 sable shaft   the Sable Shaft head: a black barbed arrowhead rimmed in violet fire, a smoking black shaft
//                         wrapped in violet flame licks
//   style 2 pierce beam   the line the shaft tore (the full 16 m): white-hot when it opens (`age`), then a black core
//                         between two violet rims with runes running along it; tapered at both ends
//   style 3 dart          Grave Mark's thrown mark / small needles: a hot head on a violet needle
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 0.25, 2.2, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;
varying float v_len;

void vertex() {
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 to_cam = normalize(-center);
	vec3 side = cross(axis, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	float len = max(al, width);
	VERTEX = center + along * VERTEX.y * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
	v_len = len;
}

float hash(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i.x + i.y * 57.0);
	float b = hash(i.x + 1.0 + i.y * 57.0);
	float c = hash(i.x + (i.y + 1.0) * 57.0);
	float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// Clamped: the interpolated UV can overshoot 1 by a hair, and pow() of a negative base is NaN.
	float xs = clamp((v_uv.x - 0.5) * 2.0, -1.0, 1.0);   // -1..1 across
	float x = abs(xs);
	float y = clamp(v_uv.y, 0.0, 1.0);                     // 0 head, 1 tail
	vec3 hot = vec3(1.45, 1.25, 1.7);
	vec3 emit = vec3(0.0);
	vec3 bodyc = vec3(0.0);
	float cover = 0.0;
	int st = int(style + 0.5);
	if (st == 0) {
		float hw = clamp(y / 0.16, 0.0, 1.0) * 0.46 * (1.0 - smoothstep(0.13, 0.17, y));     // arrowhead
		float head = step(y, 0.17) * (1.0 - smoothstep(hw - 0.07, hw, x));
		float barb = step(0.12, y) * step(y, 0.2) * (1.0 - smoothstep(0.04, 0.09, abs(x - 0.34 + (y - 0.12) * 2.0)));
		float shaft = step(0.14, y) * (1.0 - smoothstep(0.05, 0.1, x)) * (1.0 - smoothstep(0.62, 0.78, y));
		float vt = clamp((y - 0.56) / 0.2, 0.0, 1.0);
		float vane = step(0.56, y) * step(y, 0.8) * exp(-pow((x - 0.1 - vt * 0.3) / 0.07, 2.0)) * (1.0 - vt * 0.5);
		float tail = exp(-x * x * 26.0) * smoothstep(0.55, 0.75, y) * pow(clamp(1.0 - (y - 0.7) / 0.3, 0.0, 1.0), 2.0);
		float haze = exp(-x * x * 5.0) * (1.0 - y) * 0.3;
		float flick = 0.85 + 0.15 * sin(TIME * 40.0 + seed * 9.0);
		emit = tint.rgb * tint.a * (haze + vane * 0.9 + tail * 0.8 + barb * 0.8) * flick
				+ hot * (head * 1.6 + shaft * 1.0);
	} else if (st == 1) {
		float hw = clamp(y / 0.2, 0.0, 1.0) * 0.52 * (1.0 - smoothstep(0.16, 0.2, y));
		float headm = step(y, 0.2) * (1.0 - smoothstep(hw - 0.05, hw, x));
		float edge = step(y, 0.21) * exp(-pow((x - hw) / 0.055, 2.0)) * smoothstep(0.0, 0.03, y);
		float tipb = exp(-(x * x * 30.0 + y * y * 400.0));
		float shaft = step(0.17, y) * (1.0 - smoothstep(0.08, 0.13, x)) * (1.0 - smoothstep(0.6, 0.85, y));
		float t = TIME * 11.0 + seed * 7.0;
		float lick = smoothstep(0.45, 0.95, vn(vec2(xs * 4.0 + seed, y * 9.0 - t)))
				* exp(-pow(x / 0.45, 2.0)) * smoothstep(0.15, 0.3, y) * (1.0 - y);
		float smoke = exp(-x * x * 5.0) * smoothstep(0.4, 0.7, y) * (1.0 - y) * (0.6 + 0.4 * vn(vec2(xs * 3.0, y * 5.0 - t * 0.5)));
		float haze = exp(-x * x * 3.5) * (1.0 - y * 0.8) * 0.25;
		cover = max(headm * 0.97, shaft * 0.9) + smoke * 0.45;
		bodyc = vec3(0.03, 0.01, 0.05);
		emit = tint.rgb * tint.a * (edge * 2.2 + lick * 1.3 + haze) + hot * (edge * 0.15 + tipb * 1.2);
	} else if (st == 2) {
		float L = max(v_len, 0.5);
		float m = y * L;                                   // metres from the head (the far end)
		float ends = smoothstep(0.0, 0.8, m) * smoothstep(0.0, 1.2, L - m);
		float flash = exp(-age * 5.5);
		float core = 1.0 - smoothstep(0.12, 0.22, x);
		float rims = exp(-pow((x - 0.3) / 0.09, 2.0)) * (0.8 + 0.2 * sin(m * 3.0 - TIME * 20.0));
		float outer = exp(-pow(x / 0.75, 2.0)) * 0.35;
		float runs = step(0.62, fract(m / 0.55 + TIME * 7.0 + seed)) * exp(-pow((x - 0.3) / 0.12, 2.0));
		float crackle = smoothstep(0.7, 0.95, vn(vec2(m * 2.2 - TIME * 16.0, xs * 3.0 + seed))) * exp(-x * x * 8.0);
		cover = core * 0.85 * (1.0 - flash) * ends;
		bodyc = vec3(0.02, 0.005, 0.04);
		emit = (tint.rgb * tint.a * (rims * 1.3 + outer + runs * 0.9 + crackle * 0.8 + flash * 1.4 * (1.0 - x))
				+ hot * flash * core * 1.6) * ends;
	} else {
		float needle = exp(-x * x * 70.0) * pow(1.0 - y, 1.3);
		float headb = exp(-(x * x * 18.0 + y * y * 70.0));
		float haze = exp(-x * x * 8.0) * (1.0 - y) * 0.35;
		emit = tint.rgb * tint.a * (needle * 1.2 + haze) + hot * headb * 1.5;
	}
	// Nothing may touch the quad's edges (no visible rectangle).
	emit *= (1.0 - smoothstep(0.82, 1.0, x)) * (1.0 - smoothstep(0.97, 1.0, y));
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + bodyc * a;
	ALPHA = a;
}
