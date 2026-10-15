// fire_painted_vc.gdshader - the Fire buildings' painted_vc (art/shaders/painted_vc.gdshader: same vertex-data
// contract, same uniforms, same crack / damage / rim / hole behaviour) with the G-B Fire paint layer on top
// (art/buildings/fire/fire_paint.gdshaderinc, docs/art/gb_fire_buildings.md). Fire models switch their PaintedVC
// body material to this shader right after PaintedVC.convert (FireBuildingLook.apply), so nothing else changes:
//   COLOR.rgb  part base_color (sRGB); COLOR.a 0 = team part, 1 = plain
//   UV2.x      crack strength (< -0.5 = hole: unlit dark)
//   UV2.y      spec strength
//   CUSTOM0.xy crack scale / speed (0 = uniforms)
// The surface kind (stone, basalt, bronze, team tiles, timber, lacquer, glassy) is read from the part colour / spec.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.85, 0.30, 0.12);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float crack_strength = 1.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float crack_speed = 1.2;
uniform float crack_scale = 0.8;
uniform float crack_energy = 1.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

#include "res://art/buildings/fire/fire_paint.gdshaderinc"

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_lp;
varying vec3 v_ln;
varying float v_spec_in;
varying float v_crack;
varying vec2 v_crack_ss;
varying vec3 v_m;
// Hole flag (UV2.x < -0.5), constant per part: flat, so the lit branch keeps derivatives defined (shader lint B).
varying flat int v_hole;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_lp = VERTEX;
	v_ln = NORMAL;
	v_crack = UV2.x;
	v_hole = UV2.x < -0.5 ? 1 : 0;
	v_crack_ss = CUSTOM0.xy;
	v_spec_in = UV2.y;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(noise_tex, p.zy * scale).r;
	float y = texture(noise_tex, p.xz * scale).r;
	float z = texture(noise_tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	bool team = COLOR.a < 0.5;
	vec3 col = team ? base_color * vc : vc;
	v_m = vec3(0.0);
	if (v_hole == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = col;
		ROUGHNESS = 1.0;
	} else {
		vec3 n = normalize(v_world_normal);
		float na = triplanar(v_world_pos, n, noise_scale_a);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

		float h = v_world_pos.y - ao_bottom;
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

		// G-B Fire layer (kind from the part colour; the vertex colour is sRGB like the palette).
		int kind = fp_kind_of(COLOR.rgb, team, v_spec_in);
		float px = length(fwidth(v_world_pos));
		float bump_h;
		vec3 fp_emit;
		albedo = fp_albedo(albedo, kind, gb_detail, v_lp, fp_flat_normal(v_lp, normalize(v_ln)), n, h, h / max(ao_height, 0.01), na, nb, px,
			v_world_pos, CAMERA_POSITION_WORLD, noise_tex, damage, crack_color, bump_h, fp_emit);
		vec3 emission = fp_emit * crack_energy;
		if (gb_detail > 1.5) {   // uniform branch: the derivatives stay defined
			NORMAL = fp_bump(NORMAL, VERTEX, bump_h);
		}

		float cs = v_crack * crack_strength;
		if (cs > 0.0) {
			float cscale = v_crack_ss.x > 0.0 ? v_crack_ss.x : crack_scale;
			float cspeed = v_crack_ss.x > 0.0 ? v_crack_ss.y : crack_speed;
			float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (cscale * 8.0));
			float ridged = 1.0 - abs(rn * 2.0 - 1.0);
			float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
				* smoothstep(0.52 - damage * 0.35, 0.62, nb) * cs;
			emission += crack_color * c * (2.0 + 1.0 * sin(TIME * cspeed + v_world_pos.y * 1.7)) * crack_energy;
			albedo = mix(albedo, crack_color * 0.3, c * 0.5);
		}
		// Damage: soot blotches (not a flat darkening) and a warm scorch near the cracks.
		float soot = smoothstep(0.35, 0.7, nb * 0.6 + na * 0.4);
		albedo *= 1.0 - damage * mix(0.22, 0.55, soot);

		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		emission += rim * rim_color * rim_strength;

		ALBEDO = albedo;
		EMISSION = emission;
		ROUGHNESS = 1.0;
		v_m = vec3(v_spec_in, float(kind), gb_detail);
	}
}

void light() {
	vec3 dl = DIFFUSE_LIGHT;
	vec3 sl = SPECULAR_LIGHT;
	fp_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_m, dl, sl);
	DIFFUSE_LIGHT = dl;
	SPECULAR_LIGHT = sl;
}
