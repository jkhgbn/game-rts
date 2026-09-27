shader_type spatial;
// Burnt ground (SpellVfx, task A.13): the Fireball scorch decal, Ember Step's burning ground and Kindle's fire
// wave. PlaneMesh 2 x 2 scaled to the radius, lying just above the ground; one shared material, per-instance look.
// Premultiplied alpha: charred soot covers the grass, glowing ember veins and flames add light.
//   burn  = soot opacity, heat = ember veins glow (cools to 0), flames = licking flame tongues on the patch,
//   rim   = glowing zone edge (a damage area must read), front = Kindle: radius (0-1) of a travelling fire
//   ring (< 0 = off); inside it the ground smoulders with `heat`.
// noise_tex = seamless fbm (soot, flames), cell_tex = seamless cellular distance2-distance (veins = dark lines).
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D cell_tex : filter_linear_mipmap, repeat_enable;
instance uniform float burn = 0.8;
instance uniform float heat = 1.0;
instance uniform float flames = 0.0;
instance uniform float rim = 0.0;
instance uniform float front = -1.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform vec4 glow_color = vec4(1.0, 0.3, 0.04, 1.0);

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(vec2(i, 0.0)), hash(vec2(i + 1.0, 0.0)), f);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	vec2 uv = v_world * 0.085 + vec2(seed * 0.37, seed * 0.19);   // world scale: same cell size at any radius
	float ang = atan(p.y, p.x);
	float a01 = ang / 6.2831853 + 0.5;
	// Ragged outline (angle noise, wraps cleanly): the patch edge wobbles between ~0.72 and 1.0 of the radius.
	float e1 = mix(vnoise1(a01 * 9.0 + seed * 5.0), vnoise1((a01 - 1.0) * 9.0 + seed * 5.0), smoothstep(0.85, 1.0, a01));
	float e2 = mix(vnoise1(a01 * 23.0 + seed * 3.0), vnoise1((a01 - 1.0) * 23.0 + seed * 3.0), smoothstep(0.95, 1.0, a01));
	float edge_n = e1 * 0.65 + e2 * 0.35;
	float outline = 0.72 + 0.26 * edge_n;
	if (rim > 0.0) {
		outline = 0.9 + 0.08 * edge_n;
	}
	float inside = 1.0 - smoothstep(outline - 0.25, outline, r);
	float n = texture(noise_tex, uv).r;
	float n2 = texture(noise_tex, uv * 2.7 + 0.31).r;
	float soot = inside * burn * clamp(0.85 + (n - 0.5) * 1.0 + (n2 - 0.5) * 0.4, 0.45, 1.0);
	vec3 soot_col = mix(vec3(0.035, 0.025, 0.02), vec3(0.12, 0.07, 0.04), clamp(n2 * 1.4 - 0.2, 0.0, 1.0));
	// Ember veins: the cellular edges, thicker and hotter toward the centre.
	float cell = texture(cell_tex, uv * 1.3).r;
	float vein_w = mix(0.035, 0.1, clamp(1.0 - r, 0.0, 1.0));
	float veins = (1.0 - smoothstep(0.0, vein_w, cell)) * inside * smoothstep(0.3, 0.6, n + 0.2);
	float flick = 0.75 + 0.25 * sin(TIME * 6.0 + n * 20.0);
	vec3 add = glow_color.rgb * 1.8 * veins * heat * flick;
	// Hot glow under the blast centre while it is fresh.
	add += glow_color.rgb * 1.2 * pow(clamp(1.0 - r * 1.5, 0.0, 1.0), 2.0) * heat * heat;
	if (flames > 0.0) {
		float f = texture(noise_tex, vec2(uv.x * 1.6, uv.y * 1.6 - TIME * 0.35)).r;
		float g = texture(noise_tex, vec2(uv.x * 3.1 + 0.5, uv.y * 3.1 - TIME * 0.7)).r;
		float fl = smoothstep(0.55, 0.75, f * 0.6 + g * 0.5) * inside;
		add += mix(glow_color.rgb * 1.3, vec3(1.5, 0.55, 0.1), smoothstep(0.7, 0.85, f * 0.6 + g * 0.5)) * fl * flames * flick;
	}
	if (rim > 0.0) {
		float band = smoothstep(outline - 0.07, outline - 0.02, r) * (1.0 - smoothstep(outline, outline + 0.02, r));
		float pulse = 0.8 + 0.2 * sin(TIME * 5.0 + ang * 4.0);
		add += glow_color.rgb * 1.9 * band * rim * pulse;
		soot = max(soot, band * rim * 0.6);
	}
	if (front >= 0.0) {
		float fr = front * (0.93 + 0.1 * texture(noise_tex, vec2(a01 * 2.0, TIME * 0.3 + seed)).r);
		float lead = smoothstep(fr - 0.14, fr - 0.01, r) * (1.0 - smoothstep(fr, fr + 0.03, r));
		float behind = step(r, fr);
		float ff = texture(noise_tex, vec2(a01 * 3.0, r * 1.5 - TIME * 0.6)).r;
		vec3 lead_col = mix(glow_color.rgb * 1.5, vec3(1.4, 0.42, 0.05), lead) * lead * (0.6 + 0.8 * ff);
		soot *= behind;
		add = add * behind + lead_col;
	}
	float a = clamp(soot, 0.0, 1.0) * fade;
	ALBEDO = soot_col * a + add * fade;
	ALPHA = a;
}
