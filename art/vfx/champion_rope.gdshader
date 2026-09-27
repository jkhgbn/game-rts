shader_type spatial;
// Lines between a champion and its target (ChampionVfx, task 9.V5). A QuadMesh 1 x 1 drawn as a billboard that only
// turns around its own Y axis: basis Y = (tip - caster end), X = width. Tip (the target end) at +Y.
//   style 0: Snare Line: a braided leather rope with an amber glint; it whips (`wave`, metres, decays to 0 as the
//            line snaps taut) with both ends pinned.
//   style 1: Lifeline: a thin green-gold light thread with beads of light running from the Mender to the ally.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.4, 0.6, 1.0);   // glow colour (linear HDR)
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float wave = 0.0;
instance uniform float length_m = 4.0;
instance uniform float width_m = 0.6;

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
	VERTEX = center + along * VERTEX.y * al + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
}

void fragment() {
	float y = v_uv.y;                          // 0 tip (target), 1 caster end
	float s = (1.0 - y) * length_m;            // metres from the caster
	float xm = (v_uv.x - 0.5) * width_m;       // metres across
	float off = wave * sin(s * 2.3 - age * 26.0) * sin(3.14159 * y);
	float d = abs(xm - off);
	vec3 emit;
	vec3 body = vec3(0.0);
	float cover = 0.0;
	if (style < 0.5) {
		float th = 0.055;
		float across = clamp((xm - off) / th, -1.0, 1.0);
		float on = 1.0 - smoothstep(th * 0.7, th, d);
		float strand = fract(s * 8.0 + across * 0.6);
		float lit = smoothstep(0.05, 0.3, strand) * (1.0 - smoothstep(0.6, 0.9, strand));
		body = vec3(0.40, 0.26, 0.14) * (0.6 + 0.55 * lit) * (1.0 - across * across * 0.4);
		cover = on * 0.95;
		float tipg = 1.0 + 1.6 * exp(-(length_m - s) * 1.5);
		float glow = (exp(-d * d * 160.0) * 0.55 + exp(-d * d * 1500.0) * 0.4) * tipg * (0.6 + 0.8 * exp(-age * 4.0));
		emit = tint.rgb * tint.a * glow * (1.0 - on * 0.5);
	} else {
		float core = exp(-d * d / (0.03 * 0.03));
		float halo = exp(-d * d * 50.0) * 0.45;
		float beads = pow(0.5 + 0.5 * sin(s * 5.0 - TIME * 20.0), 8.0) * exp(-d * d * 180.0);
		emit = tint.rgb * tint.a * (core * 1.5 + halo + beads * 1.4);
	}
	float a = cover * fade;
	ALBEDO = emit * fade + body * a;
	ALPHA = a;
}
