shader_type spatial;
// Class-skill shells (ChampionVfx, task 11.V6). SphereMesh radius 1, scaled per unit. Additive and mostly clear in
// the middle so the champion inside stays readable.
//   style 0 riposte shimmer  Riposte: a brass diamond lattice glinting over a fresnel shell, a sword-glint band that
//                            sweeps up it, a flash when raised
//   style 1 phase            Slipstep: a ghostly column of rising arcane scan lines (the fade / the reappear)
//   style 2 whirl band       Whirlwind: a flat band (scale y small) of blade arcs spinning round the champion
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.6, 0.8, 1.0);   // main colour (linear HDR)
instance uniform float style = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float au = atan(lp.z, lp.x) / 6.2831853 + 0.5;
	float h = lp.y * 0.5 + 0.5;   // 0 bottom, 1 top
	vec3 col = vec3(0.0);
	int st = int(style + 0.5);
	if (st == 0) {
		float flash = exp(-age * 5.0);
		vec2 g = vec2(au * 14.0, h * 7.0);
		vec2 d1 = abs(fract(vec2(g.x + g.y, g.x - g.y) * 0.5) - 0.5);
		float lattice = exp(-min(d1.x, d1.y) * 26.0);
		float cellid = fract(sin(dot(floor(vec2(g.x + g.y, g.x - g.y) * 0.5), vec2(12.9898, 78.233)) + seed) * 43758.5453);
		float twinkle = pow(0.5 + 0.5 * sin(TIME * 7.0 + cellid * 40.0), 12.0);
		float sweep = exp(-pow((h - fract(TIME * 0.9 + seed)) * 9.0, 2.0));
		float foot = exp(-h * 10.0) * 0.6;
		col = tint.rgb * (fres * 0.9 + lattice * (0.18 + fres * 0.5) + lattice * twinkle * 0.9 + sweep * (0.25 + fres) + foot);
		col += vec3(1.2, 1.15, 1.0) * flash * (0.3 + fres);
	} else if (st == 1) {
		float lines = pow(0.5 + 0.5 * sin(h * 60.0 - TIME * 22.0), 6.0);
		float flick = 0.75 + 0.25 * sin(TIME * 31.0 + au * 20.0);
		float vfade = smoothstep(0.0, 0.15, h) * (1.0 - smoothstep(0.7, 1.0, h));
		col = tint.rgb * (fres * 1.3 + lines * 0.5 * (0.3 + fres) + 0.12) * vfade * flick;
	} else {
		float band = exp(-lp.y * lp.y * 5.0);
		float s = fract(au * 3.0 + TIME * 2.6 + seed);
		float arc = smoothstep(0.0, 0.02, s) * pow(1.0 - s, 3.5);
		float edge = exp(-lp.y * lp.y * 60.0);
		float s2 = fract(au * 2.0 + TIME * 2.6 + seed + 0.17);
		float arc2 = smoothstep(0.0, 0.02, s2) * pow(1.0 - s2, 6.0) * exp(-pow(lp.y - 0.35, 2.0) * 30.0);
		col = tint.rgb * (arc * band * 0.9 + arc * edge * 1.6 + arc2 * 0.7) + vec3(1.2, 1.1, 1.0) * arc * edge * pow(1.0 - s, 6.0) * 0.8;
		col *= 0.55 + 0.45 * fres + 0.2;
	}
	ALBEDO = col * fade;
}
