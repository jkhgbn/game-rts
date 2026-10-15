// ice_stables_painted.gdshader - the Frost Stables' one opaque material with the Ice paint layer (task G-B Ice,
// docs/art/gb_ice_buildings.md): art/buildings/stables/stables_painted.gdshader (same vertex data, uniforms, cracks,
// hot parts, holes) plus art/buildings/ice/ice_paint.gdshaderinc. Part class (UV2.x) -> Ice kind: team = glazed ice,
// stone = ice-stone (masonry, hoarfrost, snow on tops), metal = silver, plain = snow when pale, else plain (timber,
// wool, straw: the light layer and snow on tops only). FrostStablesModel._post_build swaps the body material to it.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.85, 0.30, 0.12);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float crack_strength = 0.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float crack_speed = 1.2;
uniform float crack_scale = 0.8;
uniform float hot_energy = 0.9;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

#include "res://art/buildings/ice/ice_paint.gdshaderinc"

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat float v_kind;
varying float v_spec;
varying float v_ik;
varying float v_glint;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_kind = UV2.x;
}

float triplanar(vec3 p, vec3 n, float scale, vec3 dx, vec3 dy) {   // explicit gradients: safe in branches
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = textureGrad(noise_tex, p.zy * scale, dx.zy * scale, dy.zy * scale).r;
	float y = textureGrad(noise_tex, p.xz * scale, dx.xz * scale, dy.xz * scale).r;
	float z = textureGrad(noise_tex, p.xy * scale, dx.xy * scale, dy.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	// Derivatives first, before any per-fragment branch (G-B Ice review: none inside divergent branches).
	vec3 dpx = dFdx(v_world_pos);
	vec3 dpy = dFdy(v_world_pos);
	float nfw = length(fwidth(normalize(v_world_normal)));
	vec3 n = normalize(v_world_normal);
	int kind = int(v_kind + 0.5);
	// Vertex colours are authored in sRGB (like the palette): convert to linear.
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	vec3 col = mix(vc * base_color, vc, step(0.5, COLOR.a));
	v_spec = 0.0;
	v_ik = float(IK_PLAIN);
	v_glint = 0.0;
	if (kind == 4) {
		v_ik = -1.0;   // holes stay unlit
		ALBEDO = vec3(0.0);
		EMISSION = col * 0.25;
		ROUGHNESS = 1.0;
	} else {
		float na = triplanar(v_world_pos, n, noise_scale_a, dpx, dpy);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b, dpx, dpy);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
		float h = v_world_pos.y - ao_bottom;
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
		vec3 emission = vec3(0.0);
		int ik = IK_PLAIN;
		if (COLOR.a < 0.5) {
			ik = IK_ICE;
		} else if (kind == 1) {
			ik = IK_STONE;
		} else if (kind == 2) {
			ik = IK_METAL;
		} else if (kind == 0 && ip_kind_of(COLOR.rgb, false, 0.0) == IK_SNOW) {
			ik = IK_SNOW;
		}
		vec3 view_ws = normalize(CAMERA_POSITION_WORLD - v_world_pos);
		v_glint = ip_surface(ik, col, v_world_pos, n, view_ws, dpx, dpy, nfw, na, nb, damage, albedo, emission);
		v_ik = float(ik);
		if (kind == 1 && crack_strength > 0.0) {
			float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0), dpx, dpy);
			float ridged = 1.0 - abs(rn * 2.0 - 1.0);
			float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
				* smoothstep(0.52 - damage * 0.35, 0.62, nb) * crack_strength;
			emission += crack_color * c * (1.6 + 0.8 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
			albedo = mix(albedo, crack_color * 0.3, c * 0.5);
		}
		if (kind == 3) {
			emission += col * hot_energy * (0.85 + 0.15 * sin(TIME * 3.1 + v_world_pos.x * 2.0 + v_world_pos.z));
		}
		albedo *= 1.0 - damage * 0.35;
		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		emission += rim * rim_color * rim_strength;
		ALBEDO = albedo;
		EMISSION = emission;
		ROUGHNESS = 1.0;
		v_spec = kind == 2 ? 1.0 : 0.0;
	}
}

void light() {
	if (v_ik >= 0.0) {
		ip_light(int(v_ik + 0.5), v_spec > 0.5 ? spec_strength : 0.0, v_glint, NORMAL, LIGHT, VIEW, LIGHT_COLOR,
			ATTENUATION, ALBEDO, DIFFUSE_LIGHT, SPECULAR_LIGHT);
	}
}