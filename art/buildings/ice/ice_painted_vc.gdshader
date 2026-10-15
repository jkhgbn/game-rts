// ice_painted_vc.gdshader - the Ice buildings' B8 one-material shader (task G-B Ice, docs/art/gb_ice_buildings.md):
// art/shaders/painted_vc.gdshader (same vertex data, same uniforms, same cracks / rim / damage / holes) plus the Ice
// paint layer (ice_paint.gdshaderinc: crystal ice with a fake interior, snow, frost-rimmed ice-stone, silver).
// IceShapes.ice_vc() swaps a building's team material to it right after PaintedVC.convert(); everything that drives
// the material (team colour, selection rim, damage, crack energy) keeps working. The surface kind comes from the
// vertex data: team parts = ice, spec >= 0.33 = silver, spec >= 0.25 = frosted ice, pale low-saturation = snow.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.45, 0.75, 0.95);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float crack_strength = 1.0;
uniform vec3 crack_color : source_color = vec3(0.75, 0.92, 1.0);
uniform float crack_speed = 1.2;
uniform float crack_scale = 0.8;
uniform float crack_energy = 1.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

#include "res://art/buildings/ice/ice_paint.gdshaderinc"

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_spec_in;
varying float v_crack;
varying vec2 v_crack_ss;
varying float v_spec;
varying float v_kind;
varying float v_glint;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_crack = UV2.x;
	v_crack_ss = CUSTOM0.xy;
	v_spec_in = UV2.y;
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
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	bool team = COLOR.a < 0.5;
	vec3 col = mix(base_color * vc, vc, step(0.5, COLOR.a));
	v_spec = 0.0;
	v_kind = 0.0;
	v_glint = 0.0;
	if (v_crack < -0.5) {
		ALBEDO = vec3(0.0);
		EMISSION = col;
		ROUGHNESS = 1.0;
	} else {
		vec3 n = normalize(v_world_normal);
		float na = triplanar(v_world_pos, n, noise_scale_a, dpx, dpy);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b, dpx, dpy);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

		float h = v_world_pos.y - ao_bottom;
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

		vec3 emission = vec3(0.0);
		// The Ice layer (kind from the vertex data: the sRGB colour, the team flag, the spec strength).
		int kind = ip_kind_of(COLOR.rgb, team, v_spec_in);
		vec3 view_ws = normalize(CAMERA_POSITION_WORLD - v_world_pos);
		v_glint = ip_surface(kind, col, v_world_pos, n, view_ws, dpx, dpy, nfw, na, nb, damage, albedo, emission);
		v_kind = float(kind);

		float cs = v_crack * crack_strength;
		if (cs > 0.0) {
			float cscale = v_crack_ss.x > 0.0 ? v_crack_ss.x : crack_scale;
			float cspeed = v_crack_ss.x > 0.0 ? v_crack_ss.y : crack_speed;
			float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (cscale * 8.0), dpx, dpy);
			float ridged = 1.0 - abs(rn * 2.0 - 1.0);
			float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
				* smoothstep(0.52 - damage * 0.35, 0.62, nb) * cs;
			emission += crack_color * c * (2.0 + 1.0 * sin(TIME * cspeed + v_world_pos.y * 1.7)) * crack_energy;
			albedo = mix(albedo, crack_color * 0.3, c * 0.5);
		}
		albedo *= 1.0 - damage * 0.35;

		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		emission += rim * rim_color * rim_strength;

		ALBEDO = albedo;
		EMISSION = emission;
		ROUGHNESS = 1.0;
		v_spec = v_spec_in;
	}
}

void light() {
	if (v_crack >= -0.5) {   // holes stay unlit
		ip_light(int(v_kind + 0.5), v_spec, v_glint, NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO,
			DIFFUSE_LIGHT, SPECULAR_LIGHT);
	}
}
