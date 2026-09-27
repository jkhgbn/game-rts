// icebound_crust.gdshader - the Icebound Barge's ice and snow (task 13c.V9): icicles, the ice sheath on the mast,
// snow caps, pressure-ridge ice plates, the frost glaze on the hull. ONE material, opaque, painted toon ramp
// (art-keep 0.3), no textures. Mesh data baked by build_icebound_barge.gd:
//   COLOR.rgb   sRGB colour block
//   UV.x        kind: 0 ice (glassy: fresnel glow, cold spec), 1 snow (matte, blue shade), 2 frost glaze (ragged edge)
//   UV.y        frost glaze: 0 at its top edge -> 1 at its ragged lower edge (dissolves first)
//   CUSTOM0     xyz = the piece's root (it grows out of it), w = its delay (0 first .. 1 last)
// instance uniform `freeze` 0 -> 1: the pieces grow out of their roots one after the other (the barge freezing over);
// back to 0 they shrink into them (the thaw). At 0 everything collapses to its root (nothing drawn).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

instance uniform float freeze = 1.0;
uniform vec3 glow_color : source_color = vec3(0.62, 0.86, 1.0);
uniform float glow_strength = 0.55;
uniform vec3 shade_color : source_color = vec3(0.55, 0.66, 0.86);   // snow in shadow turns blue
uniform vec3 rim_color : source_color = vec3(0.7, 0.85, 1.0);
uniform float rim_strength = 0.3;

varying vec3 v_col;
varying vec3 v_wp;
varying flat float v_kind;
varying float v_rag;
varying float v_g;

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
	float delay = CUSTOM0.w;
	float g = clamp((freeze - delay * 0.55) / 0.45, 0.0, 1.0);
	g = g * g * (3.0 - 2.0 * g);
	VERTEX = mix(CUSTOM0.xyz, VERTEX, g);
	v_g = g;
	v_col = pow(COLOR.rgb, vec3(2.2));   // sRGB block -> linear
	v_kind = UV.x;
	v_rag = UV.y;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (v_g <= 0.001) {
		discard;
	}
	int kind = int(v_kind + 0.5);
	float n = vnoise(v_wp.xz * 2.3 + v_wp.y * 1.7) * 0.6 + vnoise(v_wp.xz * 6.1 - v_wp.y * 3.0) * 0.4;
	if (kind == 2) {
		// Frost glaze: a ragged lower edge that creeps down as it freezes.
		if (v_rag > (0.25 + 0.75 * v_g) * (0.55 + 0.6 * n)) {
			discard;
		}
	}
	vec3 c = v_col;
	c *= 0.9 + 0.2 * n;
	ALBEDO = c;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	if (kind == 0) {
		EMISSION = glow_color * glow_strength * (fres * 1.1 + 0.12);
		ROUGHNESS = 0.25;
		SPECULAR = 0.7;
	} else if (kind == 1) {
		EMISSION = rim_color * fres * rim_strength * 0.6 * c;
		ROUGHNESS = 1.0;
		SPECULAR = 0.2;
	} else {
		EMISSION = glow_color * glow_strength * 0.35 * fres + rim_color * fres * rim_strength * c;
		ROUGHNESS = 0.6;
		SPECULAR = 0.4;
	}
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	int kind = int(v_kind + 0.5);
	vec3 lit = LIGHT_COLOR * ATTENUATION / PI;
	if (kind == 1) {
		// Snow: shadowed faces go cold blue instead of dark.
		DIFFUSE_LIGHT += mix(shade_color * 0.55, vec3(1.0), ramp) * lit;
	} else {
		DIFFUSE_LIGHT += ramp * lit;
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 28.0) * 0.45 * LIGHT_COLOR * ATTENUATION;
	}
}
