shader_type spatial;
// Camera-facing flare (SpellVfx, task A.13): hand wind-ups, impact cores, the fireball head. QuadMesh 1 x 1,
// size = node scale. `turb` > 0 gives a boiling fire edge (fireball); `rays` adds a spinning star.
// Premultiplied alpha: `cover` > 0 draws a dark halo behind the glow (shadow magic stays readable on grass).
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 0.9, 0.2, 1.0);   // glow colour (HDR), a = strength
instance uniform vec4 halo = vec4(0.0);                  // dark halo colour, a = opacity
instance uniform float fade = 1.0;
instance uniform float rays = 0.0;
instance uniform float turb = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	// Pull toward the camera a bit so it sits in front of the caster's body.
	MODELVIEW_MATRIX[3].z += 0.4;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float t = TIME + seed * 7.0;
	float rr = r;
	if (turb > 0.0) {
		// Periodic in the angle (integer frequencies): no seam where atan wraps.
		float n = 0.5 + 0.28 * sin(ang * 3.0 + t * 5.0 - r * 6.0) + 0.22 * sin(ang * 7.0 - t * 7.0 + r * 9.0);
		rr = r * (1.0 + (n - 0.5) * 0.7 * turb);
	}
	float glow = pow(clamp(1.0 - rr, 0.0, 1.0), 2.2) * smoothstep(1.0, 0.8, r);   // never reaches the quad edge
	float hot = pow(clamp(1.0 - rr * 1.9, 0.0, 1.0), 2.0);
	float star = 0.0;
	if (rays > 0.0) {
		float k = abs(cos(ang * 2.0 + t * 1.3)) * 0.6 + abs(cos(ang * 3.0 - t * 0.9 + 1.0)) * 0.4;
		star = pow(k, 18.0) * clamp(1.0 - r, 0.0, 1.0) * rays;
	}
	vec3 c = tint.rgb * (glow + star) + mix(tint.rgb, vec3(1.5, 1.35, 1.1), 0.55) * hot * 1.1;
	float ha = halo.a * pow(clamp(1.0 - r, 0.0, 1.0), 1.4);
	c *= tint.a;
	ALBEDO = (c + halo.rgb * ha) * fade;
	ALPHA = ha * fade;
}
