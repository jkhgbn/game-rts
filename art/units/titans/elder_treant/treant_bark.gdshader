// treant_bark.gdshader - Elder Treant bark (task 13.V18). Painted style of unit_painted.gdshader (flat colour blocks,
// paint noise, height gradient, toon ramp, rim, kit flash) + old oak bark, moss and glowing sap veins.
// Bark furrows run along each limb: the meshes carry UV.x = around (integer tiles, no seam), UV.y = metres along.
// Noise is sampled in MODEL rest space (the meshes are authored in model space) so nothing swims when it walks.
// Vertex COLOR:
//   r  moss allowance (grows on up-facing surfaces, broken by noise)
//   g  darkening toward dark_color (eye sockets, mouth, knot hollows, broken ends)
//   b  sap veins allowance (thin glowing lines in some furrows; brighter and pulsing with heal_glow)
//   a  bark furrow strength
// Instance uniforms: treant.gdshaderinc (glow_boost scales the sap; 0 when dead).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/units/titans/elder_treant/treant.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.29, 0.20, 0.13);
uniform vec3 plate_color : source_color = vec3(0.42, 0.31, 0.20);
uniform vec3 dark_color : source_color = vec3(0.09, 0.06, 0.04);
uniform vec3 moss_color : source_color = vec3(0.30, 0.44, 0.13);
uniform vec3 moss_light : source_color = vec3(0.52, 0.64, 0.22);
uniform vec3 sap_color : source_color = vec3(0.72, 1.00, 0.38);
uniform float sap_energy = 1.5;
uniform vec3 heal_color : source_color = vec3(0.55, 1.00, 0.35);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float furrow_stretch = 0.55;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.05;
uniform vec3 rim_color : source_color = vec3(0.60, 0.70, 0.55);
uniform float rim_strength = 0.22;

varying vec3 v_obj;
varying vec3 v_objn;
varying vec3 v_world;

void vertex() {
	v_obj = VERTEX;
	v_objn = NORMAL;
	VERTEX = treant_morph(VERTEX, CUSTOM0);
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(v_objn);
	float na = treant_triplanar(noise_tex, v_obj, n, 1.3);
	float nb = treant_triplanar(noise_tex, v_obj + vec3(17.3, 5.1, 9.7), n, 0.3);

	// bark: long furrows along the limb, lighter plates between them
	float f = texture(noise_tex, vec2(UV.x, UV.y * furrow_stretch)).r;
	float f2 = texture(noise_tex, vec2(UV.x * 2.0 + 0.37, UV.y * 1.1 + 0.11)).r;
	float ridged = 1.0 - abs(f * 2.0 - 1.0);
	float furrow = smoothstep(0.70, 0.93, ridged) * COLOR.a;
	vec3 albedo = mix(base_color, plate_color, smoothstep(0.38, 0.72, f2) * 0.75 * COLOR.a);
	albedo *= (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.14);
	albedo = mix(albedo, dark_color, furrow * 0.78);
	albedo = mix(albedo, dark_color, clamp(COLOR.g, 0.0, 1.0));

	// moss on what faces up
	// broad painted patches (low-frequency noise), thickest on top, thinning down the sides
	float up = smoothstep(0.15, 0.85, n.y);
	float mn = treant_triplanar(noise_tex, v_obj + vec3(5.3, 1.1, 2.9), n, 0.75);
	float mn2 = treant_triplanar(noise_tex, v_obj + vec3(1.7, 8.2, 3.3), n, 2.6);
	float moss = COLOR.r * (0.15 + 1.0 * up) + (mn - 0.5) * 1.3 + (mn2 - 0.5) * 0.25 - 0.45;
	moss = smoothstep(0.0, 0.12, moss) * step(0.001, COLOR.r) * (1.0 - COLOR.g);
	albedo = mix(albedo, mix(moss_color, moss_light, clamp(up * 0.6 + (na - 0.5), 0.0, 1.0)), moss);

	// sap veins in some furrows (bright + pulsing up the limb while it heals; a faint even glow far away)
	float mask = smoothstep(0.58, 0.70, texture(noise_tex, vec2(UV.x * 0.5 + 0.31, UV.y * 0.2 + 0.57)).r);
	float vein = smoothstep(0.90, 0.985, ridged) * mask * COLOR.b * (1.0 - moss);
	float flow = 0.5 + 0.5 * sin(UV.y * 4.0 - TIME * (1.4 + 2.2 * heal_glow));
	float near = 1.0 - smoothstep(22.0, 34.0, length(VERTEX));
	float live = clamp(glow_boost, 0.0, 3.0);
	vec3 emission = sap_color * sap_energy * live
		* (vein * (0.10 + 0.14 * flow + heal_glow * 1.6 * flow) * near + mask * COLOR.b * 0.05 * heal_glow * (1.0 - near));
	albedo = mix(albedo, sap_color * 0.42, vein * 0.55 * min(live, 1.0));

	// height gradient (fake sky light + AO) and the contact band (world height above the unit's ground)
	float h = v_world.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;
	emission += (rim * 0.85 + pow(rim, 0.6) * 0.12) * heal_color * heal_glow * (0.75 + 0.25 * sin(TIME * 2.2)) * min(live, 1.0);

	vec3 tint = treant_flash_tint();
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 18.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
