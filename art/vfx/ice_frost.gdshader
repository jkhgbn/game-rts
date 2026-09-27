shader_type spatial;
// Frost patch on the ground (PlaneMesh 2 x 2 scaled to the radius): a crystalline star with feathery
// veins and an optional glowing rim. Chill = small pale patch at the feet, Flash Freeze = the big circle.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 frost_color : source_color = vec3(0.84, 0.94, 1.00);
uniform vec3 glow_color : source_color = vec3(0.55, 0.86, 1.00);
uniform float glow_energy = 1.8;
uniform float spikes = 9.0;
uniform float opacity = 0.6;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float rim = 0.0;       // 0 = soft patch, 1 = bright rim ring (Flash Freeze)

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float n1 = 0.5 + 0.5 * sin(ang * spikes + seed * 6.0);
	float n2 = 0.5 + 0.5 * sin(ang * (spikes * 2.0 + 1.0) + seed * 13.0);
	float reach = mix(0.9, 1.0, rim) * (0.62 + 0.38 * pow(n1, 3.0) * (0.6 + 0.4 * n2));
	reach = max(reach, 0.55 + rim * 0.35);
	float body = 1.0 - smoothstep(reach - 0.22, reach, r);
	float veins = pow(abs(sin(ang * spikes * 1.5 + seed * 3.0 + r * 3.0)), 18.0) * smoothstep(1.0, 0.15, r);
	float branch = pow(abs(sin(ang * spikes * 4.0 - r * 9.0 + seed)), 30.0) * smoothstep(0.95, 0.3, r);
	float ring = rim * (1.0 - smoothstep(0.0, 0.07, abs(r - 0.94)));
	float glow = clamp(veins + branch * 0.6, 0.0, 1.0);
	ALBEDO = mix(frost_color, glow_color * glow_energy, clamp(glow * 0.7 + ring, 0.0, 1.0));
	ALPHA = clamp(body * opacity + glow * 0.45 * body + ring, 0.0, 1.0) * fade * step(r, 1.0);
}
