shader_type spatial;
// The thrown shield of Shield Throw (ChampionVfx, task 11.V6). CylinderMesh radius 1, height 0.12, scaled to the
// shield; it flies flat and spins (`spin` turns / s, in the shader: the node only moves). Oak boards, an iron rim with
// rivets, an iron boss glowing in `tint`, a bright rim glint that sweeps round as it spins. Painted, unshaded, with
// its own fake light (top face lit, edge darker) so it reads from the RTS camera.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.6, 0.8, 1.0);   // boss / glint glow (linear HDR)
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float spin = 3.0;
instance uniform float seed = 0.0;

varying vec3 lp;
varying vec3 ln;

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}

void fragment() {
	float ang = -(TIME * spin + seed) * 6.2831853;
	mat2 rot = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
	vec2 q = rot * lp.xz;
	float r = length(lp.xz);
	vec3 col;
	vec3 emit = vec3(0.0);
	if (abs(ln.y) < 0.5) {
		// The edge: dark iron band.
		col = vec3(0.16, 0.16, 0.18);
	} else {
		float board = fract(q.x * 2.4 + 0.5);
		float seam = 1.0 - smoothstep(0.0, 0.06, min(board, 1.0 - board));
		float grain = 0.85 + 0.15 * sin(q.y * 30.0 + floor(q.x * 2.4) * 7.0);
		col = vec3(0.50, 0.34, 0.19) * grain * (1.0 - seam * 0.45);
		float rim = smoothstep(0.8, 0.84, r);
		col = mix(col, vec3(0.38, 0.38, 0.42), rim);
		float n = 10.0;
		float a = atan(q.y, q.x) / 6.2831853 * n;
		vec2 rv = vec2((fract(a) - 0.5) * 6.2831853 * 0.9 / n, r - 0.9);
		float rivet = 1.0 - smoothstep(0.03, 0.05, length(rv));
		col = mix(col, vec3(0.75, 0.72, 0.65), rivet);
		float boss = 1.0 - smoothstep(0.22, 0.26, r);
		float bhl = 1.0 - smoothstep(0.0, 0.12, length(q - vec2(-0.06, -0.06)));
		col = mix(col, vec3(0.30, 0.30, 0.33) + bhl * 0.4, boss);
		emit += tint.rgb * boss * 0.55;
		// A glint that sweeps round the rim as the shield turns (the light stays put, the shield spins).
		float la = atan(lp.z, lp.x);
		float glint = pow(max(cos(la - 0.8), 0.0), 18.0) * rim;
		emit += tint.rgb * glint * 1.4 + vec3(1.2) * glint * 0.4;
		col *= ln.y > 0.0 ? 1.05 : 0.6;
	}
	float flash = exp(-age * 6.0);
	ALBEDO = (col + emit + tint.rgb * flash * 0.4) * fade;
	ALPHA = clamp(fade * 1.5, 0.0, 1.0);
}
