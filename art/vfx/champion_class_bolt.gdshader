shader_type spatial;
// Class-skill projectiles and streaks (ChampionVfx, task 11.V6). A QuadMesh 1 x 1 drawn as a billboard that only
// turns around its own Y axis (like champion_bolt): node basis Y = direction x length, X = width. Head at +Y.
//   style 0 javelin      Hobbling Javelin: ash shaft, steel leaf blade, a team-less teal tassel, a teal glow
//   style 1 arc bolt     Arc Bolt: a crackling blue-white bolt, a hot head and a jagged lightning core
//   style 2 dash streak  Lunge / Slipstep / the falling star: a tapered speed streak with running wind lines
//   style 3 thrust flash Skewer: a long spear-shaped piercing flash, hottest at the tip, flaring on `age`
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(0.6, 1.8, 1.5, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;

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
}

float hash(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

float vn(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	// Clamped: the interpolated UV can overshoot 1 by a hair, and pow() of a negative base is NaN (the glow then
	// spreads it into a white blob).
	float xs = clamp((v_uv.x - 0.5) * 2.0, -1.0, 1.0);   // -1..1 across
	float x = abs(xs);
	float y = clamp(v_uv.y, 0.0, 1.0);                     // 0 head, 1 tail
	vec3 emit = vec3(0.0);
	vec3 bodyc = vec3(0.0);
	float cover = 0.0;
	int st = int(style + 0.5);
	if (st == 0) {
		float hw = clamp(y / 0.1, 0.0, 1.0) * (1.0 - smoothstep(0.1, 0.22, y)) * 0.5;   // leaf blade
		float blade = step(y, 0.22) * (1.0 - smoothstep(hw - 0.06, hw, x));
		float shaft = step(0.2, y) * step(y, 0.97) * (1.0 - smoothstep(0.12, 0.18, x));
		float tassel = step(0.22, y) * step(y, 0.32) * (1.0 - smoothstep(0.26, 0.34, x)) * (1.0 - shaft * 0.5);
		float wrap = step(0.55, y) * step(y, 0.65) * shaft;
		float body = max(max(blade, shaft), tassel);
		bodyc = vec3(0.55, 0.40, 0.24) * (1.0 - wrap * 0.4) * (1.0 - x * 2.0);
		bodyc = mix(bodyc, vec3(1.25, 1.3, 1.3), blade);
		bodyc = mix(bodyc, tint.rgb * 0.55, tassel * (1.0 - blade));
		float glow = exp(-x * x * 8.0) * (1.0 - y) * 0.22 + exp(-(x * x * 14.0 + y * y * 60.0)) * 1.1;
		emit = tint.rgb * tint.a * glow;
		cover = body * 0.92;
	} else if (st == 1) {
		float t = TIME * 34.0 + seed * 11.0;
		float off = (vn(y * 9.0 - t) - 0.5) * 0.7 * smoothstep(0.08, 0.3, y);
		float off2 = (vn(y * 15.0 + t * 1.3 + 4.0) - 0.5) * 0.9 * smoothstep(0.1, 0.4, y);
		float start = smoothstep(0.12, 0.2, y);
		float bolt = exp(-pow((xs - off) * 7.0, 2.0)) * (1.0 - y * 0.8) * start;
		float fork = exp(-pow((xs - off2) * 11.0, 2.0)) * (1.0 - y) * 0.6 * step(0.5, vn(y * 3.0 + t * 0.5)) * start;
		float headb = exp(-(x * x * 7.0 + pow((y - 0.2) / 0.13, 2.0) * 2.0));
		float haze = exp(-x * x * 7.0) * pow(1.0 - y, 1.5) * 0.45 * smoothstep(0.02, 0.2, y);
		vec3 hot = mix(tint.rgb, vec3(1.6, 1.7, 2.0), 0.6);
		emit = tint.rgb * tint.a * (haze + fork) + hot * (bolt * 1.3 + headb * 2.0);
		cover = headb * 0.2;
		bodyc = vec3(0.02, 0.03, 0.08);
	} else if (st == 2) {
		float taper = pow(1.0 - y, 0.9) * smoothstep(0.0, 0.05, y);
		float w = max(taper, 0.02);
		float core = exp(-pow(x / (0.25 * w + 0.02), 2.0));
		float wide = exp(-pow(x / (0.5 * w + 0.02), 2.0)) * 0.4;
		float lines = 0.0;
		for (int i = 0; i < 3; i++) {
			float lx = (float(i) - 1.0) * 0.45 * w;
			float run = smoothstep(0.35, 0.9, vn(y * 7.0 - TIME * 9.0 + float(i) * 13.0 + seed * 7.0));
			lines += exp(-pow((xs - lx) / (0.07 * w + 0.01), 2.0)) * run * 0.7;
		}
		emit = tint.rgb * tint.a * (core * 1.4 + wide + lines) * taper
				+ vec3(1.3, 1.3, 1.25) * core * pow(1.0 - y, 3.0) * 0.8 * smoothstep(0.0, 0.05, y);
	} else {
		float flash = 0.6 + 1.6 * exp(-age * 7.0);
		float tipw = clamp(y / 0.14, 0.0, 1.0);                      // sharp tip
		float w = tipw * (1.0 - smoothstep(0.5, 1.0, y) * 0.6);
		float core = exp(-pow(x / (0.18 * w + 0.015), 2.0));
		float glow = exp(-pow(x / (0.8 * w + 0.03), 2.0)) * 0.45 * (1.0 - y * 0.7);
		float headb = exp(-(x * x * 4.0 + pow((y - 0.06) / 0.1, 2.0) * 2.0));
		float ripple = 0.8 + 0.2 * sin(y * 40.0 - TIME * 60.0);
		emit = tint.rgb * tint.a * (glow * ripple + core * 0.9) * flash + vec3(1.5, 1.5, 1.4) * (core * 0.6 + headb) * flash;
	}
	// Nothing may touch the quad's edges (no visible rectangle).
	emit *= (1.0 - smoothstep(0.8, 1.0, x)) * (1.0 - smoothstep(0.97, 1.0, y));
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + bodyc * a;
	ALPHA = a;
}
