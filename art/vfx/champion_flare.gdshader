shader_type spatial;
// Camera-facing glow for champion abilities (ChampionVfx, task 9.V5): impact stars (Shield Bash, Cutpurse), cast
// flashes, the lingering Flare Arrow light-ball (no real light: `pulse` makes it flicker like a burning flare).
// QuadMesh 1 x 1, size = node scale. `rays` adds a slowly turning star with `spikes` points.
// Premultiplied alpha: `halo` draws a dark disc behind the glow (keeps pale glows readable on bright ground).
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.5, 0.6, 1.0);   // glow colour (linear HDR), a = strength
instance uniform vec4 halo = vec4(0.0);                  // dark halo colour, a = opacity
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float rays = 0.0;
instance uniform float spikes = 4.0;
instance uniform float pulse = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	// Pull toward the camera a bit so it sits in front of the body it hits.
	MODELVIEW_MATRIX[3].z += 0.3;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float t = TIME + seed * 7.0;
	float flick = 1.0 + pulse * (0.16 * sin(t * 9.0) + 0.09 * sin(t * 23.0 + 1.3) + 0.05 * sin(t * 41.0));
	float rr = r / flick;
	float glow = pow(clamp(1.0 - rr, 0.0, 1.0), 2.4) * smoothstep(1.0, 0.8, r);
	float hot = pow(clamp(1.0 - rr * 2.1, 0.0, 1.0), 2.0);
	float star = 0.0;
	if (rays > 0.0) {
		float a1 = ang * spikes * 0.5 + t * 0.7;
		float k = pow(abs(cos(a1)), 36.0);
		float k2 = pow(abs(cos(a1 + 1.5707963 / max(spikes * 0.5, 1.0))), 60.0) * 0.45;
		star = (k + k2) * pow(clamp(1.0 - r, 0.0, 1.0), 1.3) * rays;
	}
	vec3 c = tint.rgb * (glow + star) + mix(tint.rgb, vec3(1.5, 1.4, 1.2), 0.6) * hot * 1.2;
	c *= tint.a;
	float ha = halo.a * pow(clamp(1.0 - r, 0.0, 1.0), 1.5);
	ALBEDO = (c + halo.rgb * ha) * fade;
	ALPHA = ha * fade;
}
