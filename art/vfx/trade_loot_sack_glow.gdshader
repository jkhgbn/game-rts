shader_type spatial;
// Gold ground glow under a loot sack (task 10.V11, art/vfx/trade_loot_sack.tscn). PlaneMesh 2 x 2 (radius 1 in
// UV space, scaled by the node). A soft warm pool, a thin rim ring that breathes, and 6 small glints turning slowly
// around the rim: a drop of treasure reads from the RTS camera at 40 m without a real light.
// Per instance (the model script): `fade` 0-1 (appear / vanish), `blink` 0-1 (warning flash in the last seconds).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.32, 1.0);
uniform float energy = 1.25;
instance uniform float fade = 1.0;
instance uniform float blink = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float breathe = 0.85 + 0.15 * sin(TIME * 2.2);
	float pool = pow(1.0 - r, 2.2) * 0.55;
	float rim = exp(-pow((r - 0.78) * 16.0, 2.0)) * 0.5 * breathe;
	float a = atan(p.y, p.x) + TIME * 0.35;
	float cell = fract(a / 6.2831853 * 6.0) - 0.5;
	vec2 q = vec2(cell * 6.2831853 * 0.78 / 6.0, r - 0.78);
	float dots = (1.0 - smoothstep(0.02, 0.06, length(q))) * (0.6 + 0.4 * sin(TIME * 5.0 + a * 3.0));
	float g = (pool + rim + dots * 0.9) * (1.0 + blink * 1.6) * fade;
	vec3 col = pow(tint.rgb, vec3(2.2)) * energy;
	ALBEDO = col * g;
}
