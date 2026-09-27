shader_type spatial;
// Shield shells for champion abilities (ChampionVfx, task 9.V5). SphereMesh radius 1 (hemisphere for style 0,
// full sphere for style 1), scaled per unit / radius. Additive, fresnel-lit, mostly clear in the middle so units
// inside stay readable.
//   style 0: Bulwark Stand planted shield dome: steel-blue boards (horizontal seams), iron straps, a band that
//            sweeps up the dome, a bright foot ring, a flash when it slams down.
//   style 1: Lifeline bubble: green <-> gold swirling film, strong rim, one soft highlight, a pop-in flash.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(0.6, 0.85, 1.0, 1.0);    // main colour (linear HDR)
instance uniform vec4 tint2 = vec4(1.0, 0.85, 0.3, 1.0);   // second colour (bubble film)
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	float au = atan(lp.z, lp.x) / 6.2831853 + 0.5;
	vec3 col;
	float a;
	if (style < 0.5) {
		float h = clamp(lp.y, 0.0, 1.0);
		float seam_d = abs(fract(h * 5.0 + 0.5) - 0.5);
		float seam = 1.0 - smoothstep(0.02, 0.07, seam_d);
		float strap_d = abs(fract(au * 8.0 + 0.5) - 0.5) * (1.0 - h * 0.6);
		float strap = (1.0 - smoothstep(0.018, 0.04, strap_d)) * step(h, 0.92);
		float rivet = (1.0 - smoothstep(0.02, 0.045, length(vec2(strap_d * 2.2, abs(fract(h * 5.0) - 0.5) * 0.35))))
				* step(h, 0.9);
		float sweep = 1.0 - smoothstep(0.0, 0.1, abs(fract(h * 0.8 - TIME * 0.45 + seed) - 0.5));
		float foot = smoothstep(0.14, 0.0, h);
		float slam = exp(-age * 5.0);
		col = tint.rgb;
		a = 0.03 + fres * 0.55 + seam * 0.1 + strap * 0.16 + rivet * 0.35 + sweep * 0.1 + foot * 0.45 + slam * 0.35;
	} else {
		float sw = 0.5 + 0.5 * sin(lp.y * 5.0 + au * 6.2831853 * 2.0 + TIME * 1.8 + seed * 6.0);
		col = mix(tint.rgb, tint2.rgb, smoothstep(0.2, 0.8, sw));
		float spec = pow(clamp(dot(NORMAL, normalize(vec3(-0.45, 0.6, 0.65))), 0.0, 1.0), 30.0);
		float shimmer = 0.5 + 0.5 * sin(TIME * 5.0 + lp.y * 9.0 - au * 12.0);
		float pop = exp(-age * 6.0);
		col += vec3(1.2, 1.2, 1.0) * spec;
		a = 0.05 + fres * 0.85 + spec * 0.7 + sw * fres * 0.25 + shimmer * 0.04 + pop * 0.4;
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0) * fade;
}
