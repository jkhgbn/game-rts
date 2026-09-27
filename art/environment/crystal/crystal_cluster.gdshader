// crystal_cluster.gdshader - the mana crystals of a crystal node, all in ONE mesh + ONE material (task A2.3).
// Mesh from art/environment/crystal/build_crystal.gd:
//   CUSTOM0.xyz  base point of the crystal this vertex belongs to, CUSTOM0.w its depletion threshold
//                (< -0.5 = a stump that never shrinks, 0 = the big crystal that stays to the end)
//   COLOR.r      tone (1 = bright crystal, lower = dull stump), COLOR.g per-face random, COLOR.b hue variant,
//   COLOR.a      height along the crystal (0 base -> 1 tip)
// Per instance: `fill` (crystals left / crystals at start). Each crystal shrinks toward its base as `fill`
// drops past its threshold (smallest first), the glow dims with `fill`. Shadows shrink too (same vertex code).
// Painted gem look: dark saturated base -> bright body -> near-white tips, facets of different values, a toon
// light ramp with a hard specular glint, fresnel rim and a little star glint hopping across the facets.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 deep_color : source_color = vec3(0.05, 0.17, 0.55);
uniform vec3 body_color : source_color = vec3(0.18, 0.60, 1.0);
uniform vec3 tip_color : source_color = vec3(0.78, 0.98, 1.0);
uniform float glow_energy = 0.75;
uniform float tip_energy = 1.9;
uniform float rim_energy = 0.9;
uniform float spec_strength = 1.6;
uniform float sparkle = 1.0;
instance uniform float fill = 1.0;

varying float v_t;
varying float v_tone;
varying float v_face;
varying float v_hue;
varying vec3 v_wp;

void vertex() {
	vec3 base = CUSTOM0.xyz;
	float thr = CUSTOM0.w;
	float t0 = max(thr, 0.0);
	float s = clamp((fill - t0) / max(1.0 - t0, 0.001), 0.0, 1.0);
	float k = thr <= 0.0 ? mix(0.35, 1.0, s) : smoothstep(0.0, 0.15, s) * mix(0.3, 1.0, s);
	k = thr < -0.5 ? 1.0 : k;
	VERTEX = base + (VERTEX - base) * k;
	v_t = COLOR.a;
	v_tone = COLOR.r;
	v_face = COLOR.g;
	v_hue = COLOR.b;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	vec3 c = mix(deep_color, body_color, smoothstep(0.0, 0.62, v_t));
	c = mix(c, tip_color, smoothstep(0.72, 1.0, v_t) * 0.85);
	c *= mix(vec3(0.82, 1.04, 1.02), vec3(1.06, 0.9, 1.06), v_hue);   // teal <-> lilac variety
	c *= 0.78 + v_face * 0.44;                                        // cut facets
	float dim = mix(0.45, 1.0, fill) * v_tone;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	vec3 e = c * glow_energy * mix(0.5, 1.0, v_t);
	e += tip_color * smoothstep(0.8, 1.0, v_t) * tip_energy;
	e += body_color * fres * rim_energy;
	if (sparkle > 0.0) {
		vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		vec3 cell = floor(v_wp * 5.0 + wn * 0.5);
		float h = hash3(cell);
		float flash = pow(max(sin(TIME * (1.1 + h * 1.5) + h * 40.0), 0.0), 36.0) * step(0.7, h);
		float band = 1.0 - smoothstep(0.0, 0.1, abs(fract(TIME * 0.2 + v_wp.x * 0.05 + v_wp.z * 0.03) * 2.6 - 0.4 - v_t));
		e += tip_color * (flash * 5.0 + band * 0.9) * sparkle;
	}
	ALBEDO = c * 0.55;
	ROUGHNESS = 0.25;
	EMISSION = e * dim;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.3, 0.45, d) * 0.6 + smoothstep(0.6, 0.72, d) * 0.4;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	vec3 hv = normalize(LIGHT + VIEW);
	float s = pow(max(dot(NORMAL, hv), 0.0), 48.0);
	SPECULAR_LIGHT += smoothstep(0.3, 0.5, s) * spec_strength * LIGHT_COLOR * ATTENUATION;
}
