shader_type spatial;
// Flat spell circles on the ground (scorch, Soul Siphon, Kindle wave, impact rings).
// Draw on a PlaneMesh of size 2r x 2r. UV centre = circle centre.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 fill_color : source_color = vec4(0.15, 0.05, 0.02, 0.7);
uniform vec4 ring_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float ring_energy = 3.0;
uniform float ring_width = 0.07;
// Rotating segmented inner ring (Soul Siphon). Alpha 0 = off.
uniform vec4 inner_color : source_color = vec4(0.0);
uniform float inner_radius = 0.72;
uniform float spin_speed = 0.15;
uniform float segments = 9.0;
// Glowing embers in the fill (scorch). 0 = off.
uniform float ember_strength = 0.0;
uniform vec4 ember_color : source_color = vec4(1.0, 0.4, 0.05, 1.0);
uniform float fade = 1.0;

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
	vec3 col = fill_color.rgb;
	float a = fill_color.a * smoothstep(1.0, 0.8, r);
	if (ember_strength > 0.0) {
		float n = vnoise(p * 3.0 + vec2(TIME * 0.25, -TIME * 0.2)) * 0.65 + vnoise(p * 6.5 - TIME * 0.4) * 0.35;
		float e = smoothstep(0.55, 0.8, n) * ember_strength * (0.65 + 0.35 * sin(TIME * 3.0 + r * 9.0));
		col = mix(col, ember_color.rgb * 3.0, e);
		a = max(a, e);
	}
	if (inner_color.a > 0.0) {
		float band = 1.0 - smoothstep(0.03, 0.06, abs(r - inner_radius));
		float seg = smoothstep(0.3, 0.4, fract((ang / 6.2831853) * segments + TIME * spin_speed));
		float spokes = (1.0 - smoothstep(0.015, 0.035, abs(fract((ang / 6.2831853) * 3.0 - TIME * spin_speed * 0.5) - 0.5) * r))
				* step(0.25, r) * step(r, inner_radius);
		float ib = max(band * seg, spokes * 0.6) * inner_color.a;
		col = mix(col, inner_color.rgb, ib);
		a = max(a, ib);
	}
	float edge = smoothstep(1.0 - ring_width, 1.0 - ring_width * 0.35, r) * (1.0 - smoothstep(0.975, 1.0, r));
	float pulse = 0.85 + 0.15 * sin(TIME * 4.0 + ang * 3.0);
	col = mix(col, ring_color.rgb * ring_energy * pulse, edge);
	a = max(a, edge * ring_color.a);
	ALBEDO = col;
	ALPHA = clamp(a * fade, 0.0, 1.0);
}
