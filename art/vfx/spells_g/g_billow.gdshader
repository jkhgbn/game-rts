shader_type spatial;
// G-B spell VFX (art/vfx/spells_g/spell_fx_g.gd): a boiling, noise-displaced sphere for explosions, implosions,
// steam / dust puffs and the fireball's flying head. Colours are linear HDR from the palette; `life` 0 -> 1 cools
// the colour from hot core to smoke and dissolves the shell through its noise (holes open first where it is thin).
// `implode` > 0.5 flips the motion (the noise flows inward, the rim stays bright). Unshaded, no depth write, no shadow.
render_mode unshaded, cull_back, depth_draw_never, blend_mix, fog_disabled, shadows_disabled;

instance uniform float life = 0.0;
instance uniform float seed = 0.0;
instance uniform float opacity = 1.0;
instance uniform float turb = 0.35;
instance uniform float implode = 0.0;
instance uniform vec4 c_hot = vec4(5.0, 2.6, 0.9, 1.0);
instance uniform vec4 c_mid = vec4(2.4, 0.62, 0.08, 1.0);
instance uniform vec4 c_smoke = vec4(0.07, 0.05, 0.045, 0.8);

varying vec3 v_dir;
varying float v_n;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x),
			mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x),
			mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	vec3 n = normalize(VERTEX);
	float flow = implode > 0.5 ? 1.0 : -1.0;
	float t = TIME * 1.4 + seed * 3.7;
	float d = fbm(n * 2.3 + vec3(seed, t * flow, seed * 0.5));
	v_n = d;
	v_dir = n;
	VERTEX = n * 0.5 * (1.0 + (d - 0.5) * 2.0 * turb);
	// a rising plume: the top swells and lifts a little as it cools
	VERTEX.y += max(VERTEX.y, 0.0) * life * 0.55 * (1.0 - implode);
}

void fragment() {
	float t = TIME * (implode > 0.5 ? -1.6 : 1.8);
	// domain-warped noise: licking tongues instead of a lumpy rock
	vec3 q = v_dir * 2.6 + vec3(seed * 1.3, -t * 0.6, seed);
	vec3 warp = vec3(fbm(q), fbm(q + vec3(5.2, 1.3, 2.8)), fbm(q + vec3(1.7, 9.2, 4.1)));
	float n = fbm(v_dir * 3.4 + warp * 1.6 + vec3(0.0, -t, 0.0));
	n = clamp((n - 0.5) * 1.8 + 0.5, 0.0, 1.0);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - facing, 2.0);
	float l = clamp(life, 0.0, 1.0);
	vec3 col;
	float a;
	if (implode > 0.5) {
		// a dark vortex: smoky body, a bright rim that thins as it closes
		float body = smoothstep(0.25, 0.75, n);
		col = mix(c_smoke.rgb, c_mid.rgb, body * 0.8);
		col += c_hot.rgb * fres * (0.6 + 0.8 * n) * (1.0 - l * 0.6);
		a = mix(c_smoke.a, 1.0, fres) * smoothstep(0.05, 0.4, n + fres);
	} else {
		// heat: hot tongues where the noise is high, cooling to smoke with life; the middle stays hottest
		float heat = smoothstep(0.3, 0.9, n + 0.26 - l * 0.95 + (facing - 0.5) * 0.35);
		col = mix(c_smoke.rgb, c_mid.rgb, smoothstep(0.0, 0.45, heat));
		col = mix(col, c_hot.rgb, smoothstep(0.55, 1.0, heat));
		a = mix(c_smoke.a, 1.0, smoothstep(0.05, 0.4, heat));
		// dissolve: the shell breaks up through its noise as life runs out
		a *= smoothstep(l * 1.05 - 0.22, l * 1.05 + 0.05, n * 0.85 + facing * 0.3);
	}
	a *= smoothstep(0.0, 0.5, facing + 0.08);   // soft volumetric silhouette, never a hard ball
	ALBEDO = col;
	ALPHA = clamp(a * opacity, 0.0, 1.0);
}
