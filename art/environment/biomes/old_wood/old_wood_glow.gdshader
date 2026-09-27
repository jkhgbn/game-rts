// old_wood_glow.gdshader - the Old Wood's blue-cap glow mushrooms (task 12.V10, map-fill.md 3.1 / 9 / 10).
// ONE material (old_wood_glow_mat.tres) for the whole mushroom mesh: painted stems / caps / mossy knobs like
// nature_painted.gdshader, plus emission only (no light nodes, map-fill.md 9 "Emissive decor"). MultiMesh friendly:
// no per-instance data, no scripts, no texture reads in vertex().
// Vertex data (baked by build_old_wood.gd):
//   COLOR.rgb  sRGB colour block      COLOR.a  0 at the mesh bottom -> 1 at its top (fake sky light + AO)
//   UV.x       glow weight 0 (moss, wood, lower stem) .. 1 (spots, gills, cap rim)
//   UV.y       local height in metres (dark contact band near y = 0)
//   UV2.x      variant mask, the same rule and hash as nature_painted.gdshader (3 shapes in one MultiMesh)
// Per instance (world-position hash): the glow hue (cyan <-> violet-blue) and a slow breathing phase.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float variant_count = 3.0;
uniform vec3 glow_color : source_color = vec3(0.24, 0.66, 1.0);
uniform vec3 glow_alt : source_color = vec3(0.40, 0.46, 1.0);     // a few instances lean violet-blue
uniform vec3 glow_core : source_color = vec3(0.72, 0.95, 1.0);    // hot centre of spots / gills
// map-fill.md 10: emissive 1.5-2.0 (below the magic-rune 2.5-4.0 of art-keep.md 0.4: decor, not magic).
uniform float energy = 1.8;
uniform float pulse_amount = 0.12;
uniform float pulse_speed = 0.8;
uniform float stem_tint = 0.10;                                    // cool bounce of the glow on the stems
uniform vec3 rim_color : source_color = vec3(0.55, 0.75, 1.0);
uniform float rim_strength = 0.18;

varying vec3 v_wp;
varying vec3 v_col;
varying float v_grad;
varying float v_y;
varying float v_glow;
varying float v_ih;
varying float v_ih2;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float mask = UV2.x;
	if (mask > 0.5) {
		float ih4 = hash1(origin.zx + vec2(3.1, 7.7));
		float variant = min(floor(ih4 * variant_count), variant_count - 1.0);
		if (mod(floor(mask / exp2(variant)), 2.0) < 0.5) {
			VERTEX = vec3(0.0, -3.0, 0.0);
		}
	}
	v_ih = hash1(origin.xz);
	v_ih2 = hash1(origin.xz + vec2(17.3, 5.9));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_col = pow(COLOR.rgb, vec3(2.2)) * (0.92 + v_ih * 0.16);
	v_grad = COLOR.a;
	v_y = UV.y;
	v_glow = UV.x;
}

void fragment() {
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float na = texture(noise_tex, v_wp.xz * 0.9 + v_wp.y * 0.4).r;
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.22);
	albedo *= mix(0.66, 1.06, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.50, 1.0, smoothstep(0.0, 0.30, v_y + 0.04));
	float g = v_glow;
	// Hue per instance: mostly cyan-blue, one in four leans violet-blue.
	vec3 hue = mix(glow_color, glow_alt, step(0.75, v_ih2));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	// Slow breathing, out of phase between instances (and a little along each cap).
	float pulse = 1.0 + sin(TIME * pulse_speed + v_ih * 6.2831 + v_wp.y * 3.0) * pulse_amount;
	vec3 e = mix(hue, glow_core, clamp(smoothstep(0.7, 1.0, g) * 0.7 + fres * 0.15, 0.0, 1.0)) * g;
	// Painted brush breakup of the glow (caps are not flat neon).
	e *= 0.82 + na * 0.36;
	// Stems / moss catch a faint blue bounce under the caps.
	albedo = mix(albedo, albedo + hue * 0.08, stem_tint * smoothstep(0.05, 0.4, g) * 4.0);
	ALBEDO = albedo;
	EMISSION = e * energy * pulse + fres * fres * rim_color * rim_strength * albedo;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
