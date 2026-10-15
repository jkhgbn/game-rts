// wayshrine_beam.gdshader - the Wayshrine's light (task 12.V18): no real light, only additive unshaded surfaces
// (art-keep.md 0.4 / 0.6). One shader, four shared materials (the `kind` uniform), state in instance uniforms:
//   kind 0  Column   the light column of an awake shrine. Mesh: open cones, UV.x = angle 0-1, UV.y = 0 bottom -> 1 top,
//                    UV2.x = layer weight (the core beam rising from the rune stone's tip 1, the low ground sheath 0.3). Brightest facing the camera, fading upward, bands
//                    climbing it; `grow` (0-1) raises it from the ground when the shrine wakes.
//   kind 1  Ring     the rune circle inlaid in the dais + a soft pool of light. Mesh: a flat quad 2 x disc_radius wide,
//                    UV 0-1 (v along +Z). A glowing line at ring_radius with 8 rune diamonds, in fx_color x fx_energy;
//                    the capture arc (clockwise from -Z seen from above, cap_ratio of the circle) in cap_color.
//   kind 2  Halo     a camera-facing soft glow around the floating rune stone (billboarded here, quad in XY).
//   kind 3  Burst    the blessing: a ring of light racing out to burst_radius (the capture radius) while `burst` goes 0 -> 1.
// Instance uniforms: fx_color, fx_energy, cap_color, cap_ratio, grow, burst.
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform int kind = 0;
uniform float band_speed = 0.32;
uniform float fade_power = 1.35;
uniform float ring_radius = 1.11;
uniform float disc_radius = 2.2;
uniform float burst_radius = 6.5;

instance uniform vec4 fx_color = vec4(1.0, 0.72, 0.28, 1.0);
instance uniform float fx_energy = 0.0;
instance uniform vec4 cap_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float cap_ratio = 0.0;
instance uniform float grow = 1.0;
instance uniform float burst = 0.0;

void vertex() {
	if (kind == 2) {
		// Billboard (keeps the node's position, drops its rotation / scale).
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment() {
	vec3 c = vec3(0.0);
	if (kind == 0) {
		// Guarded math: pow() of a value a hair below 0 is NaN and the glow pass spreads it into a white disc.
		float v = clamp(UV.y, 0.0, 1.0);
		float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
		float soft = pow(max(facing, 1e-4), 1.4);
		float top = pow(max(1.0 - v, 1e-4), fade_power) * (1.0 - smoothstep(0.92, 1.0, v));
		float bottom = smoothstep(0.0, 0.07, v);
		float bands = 0.7 + 0.3 * sin((v * 5.0 - TIME * band_speed) * 6.2832 + UV.x * 12.566);
		float g = 1.0 - smoothstep(max(grow - 0.1, 0.0), grow + 0.001, v);
		c = fx_color.rgb * fx_energy * soft * top * bottom * bands * g * UV2.x;
	} else if (kind == 1) {
		vec2 p = (UV * 2.0 - 1.0) * disc_radius;
		float r = length(p);
		float ang = fract(atan(p.x, -p.y) / 6.2832 + 1.0);
		float line = exp(-pow((r - ring_radius) / 0.075, 2.0));
		// 8 rune diamonds sitting on the line (hollow: a bright outline and a dimmer heart).
		float seg = fract(ang * 8.0) - 0.5;
		vec2 q = vec2(seg * 6.2832 * ring_radius / 8.0, r - ring_radius);
		float dd = abs(q.x) * 0.8 + abs(q.y);
		float glyph = (1.0 - smoothstep(0.12, 0.15, dd)) * (0.55 + 0.45 * smoothstep(0.05, 0.09, dd));
		float shape = max(line, glyph);
		float pool = pow(max(1.0 - r / disc_radius, 0.0), 2.0) * 0.30;
		float arc = step(0.001, cap_ratio) * step(ang, cap_ratio);
		float head = step(0.001, cap_ratio) * exp(-abs(ang - cap_ratio) * 70.0) * max(line, glyph);
		float wob = 0.9 + 0.1 * sin(TIME * 1.4 + r * 4.0);
		float cap_dim = 1.0 - 0.75 * step(0.001, cap_ratio);   // the uncaptured part steps back while captured
		c = fx_color.rgb * fx_energy * (shape * 1.6 + pool) * wob * (1.0 - arc) * cap_dim;
		c += cap_color.rgb * (shape * 1.9 + pool * 0.6) * arc + cap_color.rgb * head * 3.0;
		c *= 1.0 - smoothstep(disc_radius * 0.9, disc_radius, r);
	} else if (kind == 2) {
		float r = length(UV * 2.0 - 1.0);
		float a = pow(max(1.0 - r, 0.0), 2.4);
		c = fx_color.rgb * fx_energy * a * (0.9 + 0.1 * sin(TIME * 2.3));
	} else {
		vec2 p = (UV * 2.0 - 1.0) * burst_radius;
		float r = length(p);
		float b = clamp(burst, 0.0, 1.0);
		float R = b * burst_radius * 0.95;
		float fade = pow(max(1.0 - b, 0.0), 1.3);
		float ring = exp(-pow((r - R) / (0.22 + b * 0.35), 2.0));
		float fill = (1.0 - smoothstep(0.0, max(R, 0.01), r)) * 0.2;
		float rays = 0.72 + 0.28 * sin(atan(p.x, p.y) * 12.0 + b * 5.0);
		c = fx_color.rgb * fx_energy * (ring * 2.4 * rays + fill) * fade * (1.0 - smoothstep(burst_radius * 0.9, burst_radius, r));
	}
	ALBEDO = c;
}
