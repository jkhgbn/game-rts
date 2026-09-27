shader_type spatial;
// Spell particles (SpellVfx, task A.13). One shared material for every emitter; each GPUParticles3D picks
// its look with instance uniforms. Premultiplied alpha: `additive` 1 = pure glow (adds light), 0 = normal
// mix (smoke, dark magic); in between keeps colours saturated on bright ground (glow + a bit of cover).
// `erosion` > 0 = noisy flame / smoke puff that burns away over its life (INSTANCE_CUSTOM.y = age 0-1).
// `axial` = 1: the quad stretches along the particle's Y axis (ParticleProcessMaterial align_y = velocity)
// and only turns around it to face the camera: streak sparks and shards. `tongue` = 1 turns that axial quad
// into a licking flame tongue (ground fires, fire columns).
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;   // seamless fbm (SpellVfx builds it)
instance uniform float additive = 1.0;
instance uniform float erosion = 0.0;
instance uniform float axial = 0.0;
instance uniform float core = 0.0;        // extra hot (yellower) centre (0-1)
instance uniform float tongue = 0.0;      // 1 = flame-tongue shape (use with axial and an upward velocity)

varying float v_age;
varying float v_seed;

void vertex() {
	v_age = INSTANCE_CUSTOM.y;
	v_seed = fract(float(INSTANCE_ID) * 0.6180339 + MODEL_MATRIX[3].x * 0.013);
	vec3 pos = MODEL_MATRIX[3].xyz;
	if (axial > 0.5) {
		vec3 ax = MODEL_MATRIX[1].xyz;
		vec3 to_cam = normalize(CAMERA_POSITION_WORLD - pos);
		vec3 side = cross(normalize(ax), to_cam);
		float sl = length(side);
		side = sl > 0.001 ? side / sl : vec3(1.0, 0.0, 0.0);
		side *= length(MODEL_MATRIX[0].xyz);
		vec3 nrm = normalize(cross(side, ax));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(side, 0.0), vec4(ax, 0.0), vec4(nrm, 0.0), vec4(pos, 1.0));
	} else {
		float a = INSTANCE_CUSTOM.x;
		mat4 w = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), vec4(pos, 1.0));
		w = w * mat4(vec4(cos(a), -sin(a), 0.0, 0.0), vec4(sin(a), cos(a), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		float s = length(MODEL_MATRIX[0].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * w * mat4(vec4(s, 0.0, 0.0, 0.0), vec4(0.0, s, 0.0, 0.0), vec4(0.0, 0.0, s, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float shape = clamp(1.0 - r, 0.0, 1.0);
	float yy = 1.0 - UV.y;                 // 0 bottom, 1 top of the quad
	if (tongue > 0.5) {
		// Flame tongue: round belly low down, narrowing tip that sways (the erosion noise breaks the outline).
		float sway = sin(yy * 5.0 + TIME * 9.0 + v_seed * 20.0) * 0.14 * yy;
		float wv = pow(sin(3.14159 * clamp(yy, 0.0, 1.0)), 0.7) * mix(1.0, 0.3, yy);
		float x = abs(p.x + sway);
		shape = clamp(1.0 - x / max(wv, 0.001), 0.0, 1.0);
		r = length(vec2(p.x, (yy - 0.3) * 1.6));
	}
	float a = tongue > 0.5 ? smoothstep(0.02, 0.3, shape) : shape * shape * (3.0 - 2.0 * shape);
	float edge = 0.0;
	if (erosion > 0.0) {
		vec2 q = UV * vec2(0.45, tongue > 0.5 ? 0.3 : 0.45) + vec2(v_seed * 7.0, v_seed * 3.0 - v_age * 0.25 - TIME * 0.2 * tongue);
		float n = clamp((texture(noise_tex, q).r - 0.5) * 1.7 + 0.5, 0.0, 1.0);
		float thr = mix(0.0, 0.85, v_age) * erosion;
		float body = shape * mix(1.0, 0.35 + n * 1.3, erosion);
		a = smoothstep(thr, thr + 0.22, body);
		edge = 1.0 - smoothstep(thr + 0.05, thr + 0.45, body);   // 1 at the burning edge, 0 inside
	}
	vec3 col = COLOR.rgb;
	// Burnt edges: deeper, redder rims give flame and smoke puffs a readable shape instead of a soft blob.
	col *= mix(vec3(1.0), vec3(0.55, 0.35, 0.3), edge * erosion);
	if (tongue > 0.5) {
		col *= mix(1.3, 0.75, yy);          // hotter at the root
	}
	if (core > 0.0) {
		float c = smoothstep(0.55, 0.0, r) * core * (1.0 - v_age);
		col = mix(col, col * vec3(1.25, 1.6, 2.2) + vec3(0.1, 0.08, 0.02), c);
	}
	float alpha = clamp(a * COLOR.a, 0.0, 1.0);
	ALBEDO = col * alpha;
	ALPHA = alpha * (1.0 - additive);
}
