shader_type spatial;
// Camera-facing status icons over units (ChampionVfx, task 9.V5). QuadMesh 1 x 1, size = node scale.
//   icon 0: taunt badge (Oath of Iron): a dark shield with a steel-blue rim and a bright "!".
//   icon 1: daze star (Shield Bash): a turning five-point star with a hot core and a dark outline.
// Drawn on top of bodies (no depth test) like the heal "+", with a dark outline so it reads on any ground.
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.2, 1.7, 2.0, 1.0);   // glow colour (linear HDR)
instance uniform float icon = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);   // y up
	vec3 emit = vec3(0.0);
	float cover = 0.0;
	vec3 dark = vec3(0.0);
	if (icon < 0.5) {
		// Heater shield: straight sides down to y = 0, then curving to a point at y = -0.92; gently arched top.
		float halfw = p.y > 0.0 ? 0.66 : 0.66 * sqrt(clamp((p.y + 0.92) / 0.92, 0.0, 1.0));
		float top = 0.66 + 0.12 * (1.0 - p.x * p.x);
		float sd = max(abs(p.x) - halfw, p.y - top);   // < 0 inside (approximate distance)
		float inside = 1.0 - smoothstep(-0.02, 0.02, sd);
		float rim = inside * smoothstep(-0.2, -0.12, sd);
		float outline = (1.0 - smoothstep(0.0, 0.12, sd)) * (1.0 - inside);
		float barw = mix(0.07, 0.13, clamp((p.y + 0.02) / 0.6, 0.0, 1.0));
		float bar = (1.0 - smoothstep(barw - 0.035, barw, abs(p.x))) * smoothstep(-0.06, -0.02, p.y)
				* (1.0 - smoothstep(0.56, 0.6, p.y));
		float dotm = 1.0 - smoothstep(0.08, 0.12, length(p - vec2(0.0, -0.3)));
		float mark = max(bar, dotm) * inside;
		float beat = 0.8 + 0.2 * sin(TIME * 9.0 + seed);
		emit = tint.rgb * rim * beat + mix(tint.rgb, vec3(1.6, 1.6, 1.5), 0.55) * mark * 1.3;
		cover = inside * 0.82 + outline * 0.55;
		dark = vec3(0.03, 0.04, 0.06);
		cover *= 1.0 - mark;
	} else {
		float r = length(p);
		float a = atan(p.y, p.x) + TIME * 3.5 + seed;
		float f = pow(0.5 + 0.5 * cos(5.0 * a), 1.5);
		float rs = mix(0.42, 0.94, f);
		float inside = 1.0 - smoothstep(rs - 0.08, rs, r);
		float outline = (1.0 - smoothstep(rs, rs + 0.18, r)) * (1.0 - inside);
		float core = 1.0 - smoothstep(0.0, 0.45, r);
		emit = tint.rgb * inside * (0.85 + 0.5 * core) + vec3(1.3, 1.2, 1.0) * core * inside * 0.6;
		cover = outline * 0.5;
		dark = vec3(0.1, 0.06, 0.01);
	}
	float al = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * al;
	ALPHA = al;
}
