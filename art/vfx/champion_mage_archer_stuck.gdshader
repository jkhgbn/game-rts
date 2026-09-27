shader_type spatial;
// Eclipse Volley's arrows stuck in the ground (ChampionVfx + ChampionMageArcherVfx, task 13b.V8). One pre-built mesh of
// 16 arrows (two crossed quads each, UV.y 0 = 0.1 m under the ground -> 1 = the nock, COLOR.r = a per-arrow random)
// spread over the r 4 volley circle; each wave shows one copy turned by a random yaw. Black shafts, glowing violet
// fletching and a violet glow where each one bit the ground. As `fade` drops they sink into the ground and go dark.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 0.25, 2.2, 1.0);   // glow colour (linear HDR)
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying float v_rand;

void vertex() {
	v_rand = COLOR.r;
	VERTEX.y -= (1.0 - fade) * 0.95;          // sink
	VERTEX.y += max(0.0, 0.05 - age) * 5.0;   // the last 0.25 m of the fall
}

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float shaft = (1.0 - smoothstep(0.12, 0.2, x)) * step(y, 0.86);
	float vt = clamp((y - 0.66) / 0.3, 0.0, 1.0);
	float hw = 0.25 + vt * 0.65;
	float vane = step(0.66, y) * step(y, 0.97) * (1.0 - smoothstep(hw - 0.12, hw, x));
	float nock = exp(-pow((y - 0.97) * 40.0, 2.0)) * (1.0 - smoothstep(0.2, 0.4, x));
	float bite = exp(-pow((y - 0.105) * 26.0, 2.0)) * (1.0 - smoothstep(0.3, 0.9, x));
	float flick = 0.7 + 0.3 * sin(TIME * (5.0 + v_rand * 4.0) + v_rand * 30.0 + seed);
	float flash = exp(-age * 5.0);
	float cover = max(shaft * 0.95, vane * 0.55) * step(0.105, y);
	vec3 emit = tint.rgb * (vane * 0.9 * flick + nock * 1.2 + bite * (1.4 + flash * 2.0) + shaft * 0.08)
			+ vec3(1.4, 1.2, 1.6) * (bite + vane * 0.3) * flash;
	emit *= smoothstep(0.0, 0.3, fade);
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + vec3(0.035, 0.025, 0.05) * a;
	ALPHA = a;
}
