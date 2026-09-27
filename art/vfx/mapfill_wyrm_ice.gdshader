shader_type spatial;
// Ice crown (MapFillWyrmVfx, task 13c.V9): the ring of jagged ice spikes that bursts out of the ground where the
// Glacial Dive lands. Opaque, lit with the painted toon ramp (art-keep 0.3), flat facets baked in the mesh (COLOR.a =
// 0 at a spike's foot -> 1 at its tip). Looks from instance uniforms: `glow` (inner cold light, strongest at the tips
// and along the silhouette), `melt` 0 -> 1 dissolves it in ragged pieces from the tips down (the shatter), `frost`
// whitens the facets. No alpha blending (no sorting against water or bodies).
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled;

instance uniform vec4 glow = vec4(0.5, 1.0, 1.6, 1.0);   // linear HDR
instance uniform float melt = 0.0;
instance uniform float seed = 0.0;
instance uniform float frost = 0.0;
uniform vec3 ice_deep : source_color = vec3(0.30, 0.55, 0.78);
uniform vec3 ice_pale : source_color = vec3(0.80, 0.93, 1.0);

varying vec3 v_wp;
varying float v_tip;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tip = COLOR.a;
}

void fragment() {
	// Dissolve from the tips down, in ragged chunks.
	float n = vnoise(v_wp.xz * 3.1 + v_wp.y * 2.3 + seed) * 0.6 + vnoise(v_wp.xy * 7.0 - seed) * 0.4;
	if (n * 0.55 + (1.0 - v_tip) * 0.45 < melt * 1.02) {
		discard;
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(ice_deep, ice_pale, clamp(v_tip * 0.7 + up * 0.35 + (n - 0.5) * 0.3, 0.0, 1.0));
	base = mix(base, vec3(0.95, 0.98, 1.0), frost * 0.5);
	ALBEDO = base * mix(0.75, 1.05, v_tip);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float edge = smoothstep(melt * 1.02, melt * 1.02 + 0.06, n * 0.55 + (1.0 - v_tip) * 0.45);
	EMISSION = glow.rgb * (fres * 0.9 + pow(v_tip, 3.0) * 0.6 + (1.0 - edge) * 2.0 * step(0.01, melt));
	ROUGHNESS = 0.3;
	SPECULAR = 0.6;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * 0.4 * LIGHT_COLOR * ATTENUATION;
}
