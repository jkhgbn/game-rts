shader_type spatial;
// Shockwave / cast ring on the ground (SpellVfx, task A.13). PlaneMesh 2 x 2 scaled to the radius; one shared
// material, the look comes from instance uniforms. Premultiplied alpha: the glowing band adds light, the
// `fill` colour covers the ground (a dark fill reads as a shadow pool).
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.0, 0.5, 0.1, 1.0);   // band colour (HDR allowed), a = strength
instance uniform vec4 fill = vec4(0.0);                  // inner cover colour, a = opacity
instance uniform float width = 0.12;                     // band width, fraction of the radius
instance uniform float fade = 1.0;
instance uniform float glow = 0.35;                      // soft glow trailing inside the band
instance uniform float seed = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float ang = atan(p.y, p.x);
	// Periodic in the angle (integer frequencies): no seam where atan wraps.
	float n = 0.5 + 0.3 * sin(ang * 5.0 + seed * 11.0 + TIME * 2.0) + 0.2 * sin(ang * 11.0 - seed * 7.0 - TIME * 3.0);
	float w = width * (0.7 + 0.6 * n);
	float band = smoothstep(1.0 - w, 1.0 - w * 0.3, r) * (1.0 - smoothstep(0.96, 1.0, r));
	float inner = smoothstep(1.0 - w - glow, 1.0 - w, r) * (1.0 - band) * step(r, 1.0 - w * 0.3);
	float fa = fill.a * smoothstep(1.0, 0.85, r) * fade;
	vec3 add = tint.rgb * (band + inner * 0.35) * tint.a * fade;
	ALBEDO = fill.rgb * fa + add;
	ALPHA = fa;
}
