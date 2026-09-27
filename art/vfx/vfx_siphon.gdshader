shader_type spatial;
// Soul Siphon circle (SpellVfx, task A.13): a dark pool with a vortex whose spiral arms turn inward toward a
// black eye, a sharp violet rim with rune ticks turning the other way, and a slow breathing glow.
// PlaneMesh 2 x 2 scaled to the radius. Premultiplied alpha: the dark pool covers, the violet parts glow.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float pulse = 0.0;     // 0-1 flash on a drain tick
uniform vec3 glow_color : source_color = vec3(0.62, 0.2, 1.0);
uniform vec3 dark_color : source_color = vec3(0.05, 0.0, 0.09);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float ang = atan(p.y, p.x);
	float t = TIME + seed * 13.0;
	// Pool: dark, denser toward the eye, soft toward the rim.
	float n = vnoise(p * 4.0 + vec2(t * 0.3, -t * 0.2));
	float pool = (0.55 + 0.35 * smoothstep(0.9, 0.1, r)) * smoothstep(1.0, 0.9, r);
	// Spiral arms (log spiral), turning inward.
	float spiral = sin(ang * 3.0 + log(max(r, 0.02)) * 5.5 + t * 2.4);
	float arms = smoothstep(0.55, 0.95, spiral) * smoothstep(0.08, 0.35, r) * smoothstep(0.95, 0.6, r);
	arms *= 0.6 + 0.4 * n;
	// Eye: black hole with a thin glowing lip.
	float eye = 1.0 - smoothstep(0.08, 0.16, r);
	float lip = smoothstep(0.1, 0.16, r) * (1.0 - smoothstep(0.16, 0.24, r));
	// Rim + rune ticks spinning the other way.
	float rim = smoothstep(0.9, 0.955, r) * (1.0 - smoothstep(0.975, 1.0, r));
	float ticks = step(0.5, fract(ang / 6.2831853 * 18.0 - t * 0.12)) * smoothstep(0.8, 0.84, r) * (1.0 - smoothstep(0.87, 0.9, r));
	float breathe = 0.8 + 0.2 * sin(t * 2.5);
	float cover = clamp(pool + eye * 0.4, 0.0, 0.92) * fade;
	vec3 glow = glow_color * (arms * 1.3 + lip * 2.2 + rim * 2.0 * breathe + ticks * 1.1) * (1.0 + pulse * 1.2);
	ALBEDO = dark_color * cover + glow * fade;
	ALPHA = cover;
}
