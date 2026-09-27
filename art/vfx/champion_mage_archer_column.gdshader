shader_type spatial;
// Mage Archer light columns (ChampionVfx + ChampionMageArcherVfx, task 13b.V8). An open CylinderMesh (radius 1, height
// 1, no caps) scaled per effect: (radius, height, radius). Additive; the middle stays clear (fresnel) so she reads
// inside it.
//   style 0 call column   the call ritual: a column rising from the circle, violet streaks and rune rings climbing it,
//                         brightest at the foot, fading out at the top
//   style 1 revive pillar the revive: a pillar of light driven down from the sky (revealed top-down in 0.3 s by `age`),
//                         a white-hot leading edge, then it glows and thins out
//   style 2 flare ring    a short wide band flashing out (the call's peak): a bright belt fading up and down
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.1, 0.25, 2.2, 1.0);   // glow colour (linear HDR), a = strength
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec3 lp;

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

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	float au = atan(lp.z, lp.x) / 6.2831853 + 0.5;
	float h = clamp(lp.y + 0.5, 0.0, 1.0);   // 0 foot, 1 top
	vec3 hot = vec3(1.4, 1.2, 1.7);
	vec3 col = vec3(0.0);
	int st = int(style + 0.5);
	if (st == 0) {
		float streak = smoothstep(0.55, 0.95, vnoise(vec2(au * 28.0, h * 2.5 - TIME * 1.6 + seed)));
		float streak2 = smoothstep(0.7, 1.0, vnoise(vec2(au * 60.0 + 3.0, h * 5.0 - TIME * 3.2 + seed)));
		float band_y = fract(h * 3.0 - TIME * 0.55 + seed);
		float band = exp(-pow(band_y - 0.5, 2.0) * 500.0) * step(0.35, fract(au * 20.0 + h * 2.0));
		float vfade = smoothstep(0.0, 0.04, h) * pow(1.0 - h, 1.5);
		float foot = exp(-h * 12.0);
		// Mostly a fresnel shell with climbing streaks: the middle stays see-through so she reads rising inside it.
		col = tint.rgb * ((fres * 1.0 + (streak * 0.55 + streak2 * 0.45 + band * 0.7) * (0.25 + fres) + 0.03) * vfade
				+ foot * fres * 0.9) + hot * foot * fres * 0.25;
	} else if (st == 1) {
		float reveal = 1.0 - clamp(age / 0.3, 0.0, 1.0);        // the pillar comes down from the top
		float on = smoothstep(reveal - 0.02, reveal + 0.01, h);
		float edge = exp(-pow((h - reveal) * 26.0, 2.0)) * step(0.001, reveal);
		float glow = exp(-max(age - 0.3, 0.0) * 3.0);
		float streak = smoothstep(0.5, 0.95, vnoise(vec2(au * 22.0, h * 4.0 + TIME * 5.0 + seed)));
		float core = pow(1.0 - fres, 6.0);                      // a thin hot line down the pillar's middle
		float vfade = smoothstep(0.0, 0.03, h) * (1.0 - smoothstep(0.75, 1.0, h));
		col = (tint.rgb * (fres * 1.2 + streak * 0.4 * (0.3 + fres) + core * 0.16 * glow) + hot * core * glow * 0.08)
				* on * vfade + hot * edge * 1.6;
	} else {
		float belt = exp(-pow((h - 0.5) * 4.0, 2.0));
		float rays = 0.7 + 0.3 * vnoise(vec2(au * 40.0, TIME * 3.0 + seed));
		col = (tint.rgb * (fres * 1.1 + 0.12) + hot * fres * 0.15) * belt * rays;
	}
	ALBEDO = col * fade;
}
