// fire_stables_painted.gdshader - the Ember Stables' one opaque material on the G-B Fire paint layer (G-B leftovers,
// docs/art/gb_leftovers.md). Same vertex-data contract and uniforms as art/buildings/stables/stables_painted.gdshader
// (the shared Stables shader, untouched), so EmberStablesModel only swaps the shader at _post_build:
//   COLOR.rgb  flat colour of the part (team parts: a multiplier on the team colour)
//   COLOR.a    0 = team part (base_color x COLOR.rgb), 1 = plain part
//   UV2.x      part class: 0 plain, 1 stone (glowing cracks), 2 metal, 3 hot (self-lit), 4 hole (unlit dark)
// The look is the Fire buildings' (art/buildings/fire/fire_paint.gdshaderinc, like fire_painted_vc.gdshader): the
// surface kind comes from the part colour (ashlar stone, dark basalt, timber planks, clay tiles on the team roofs,
// lacquer), class 2 is bronze / iron; wrapped light, sky catch, soot, ember bounce, patina; fine detail + bump at
// High / Ultra. Hot parts (embers in the boar's crest, hot iron) and holes keep the shared look.
// gb_detail: written once at _ready from GameSettings.effective_graphics_quality() (FireBuildingLook.detail()).
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

#include "res://art/buildings/fire/fire_paint.gdshaderinc"

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat float v_kind;
varying vec3 v_lp;
varying vec3 v_ln;
varying vec3 v_m;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_kind = UV2.x;
	v_lp = VERTEX;
	v_ln = NORMAL;
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
	vec3 n = normalize(v_world_normal);
	int cls = int(v_kind + 0.5);
	bool team = COLOR.a < 0.5;
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	vec3 col = team ? vc * base_color : vc;
	v_m = vec3(0.0, 0.0, gb_detail);
	// Derivatives outside the per-class branches (shader lint B): the pixel size here, the bump after the if / else.
	float px = length(fwidth(v_world_pos));
	vec3 flat_n = fp_flat_normal(v_lp, normalize(v_ln));
	float bump_h = 0.0;
	if (cls == 4) {
		ALBEDO = vec3(0.0);
		EMISSION = col * 0.25;
		ROUGHNESS = 1.0;
	} else {
		float na = triplanar(v_world_pos, n, noise_scale_a);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
		float h = v_world_pos.y - ao_bottom;
		float hrel = h / max(ao_height, 0.01);
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, hrel));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
		vec3 emission = vec3(0.0);
		// G-B Fire layer: class 2 = bronze / iron, the rest by colour (timber, stone, basalt, tiles on team slopes).
		float spec = cls == 2 ? spec_strength : 0.0;
		int kind = cls == 2 ? FK_METAL : fp_kind_of(COLOR.rgb, team, spec);
		if (cls != 3) {
			vec3 fp_emit;
			albedo = fp_albedo(albedo, kind, gb_detail, v_lp, flat_n, n, h, hrel, na, nb, px, v_world_pos,
				CAMERA_POSITION_WORLD, noise_tex, damage, crack_color, bump_h, fp_emit);
			emission += fp_emit;
		}
		if (cls == 1 && crack_strength > 0.0) {
			float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
			float ridged = 1.0 - abs(rn * 2.0 - 1.0);
			float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
				* smoothstep(0.52 - damage * 0.35, 0.62, nb) * crack_strength;
			emission += crack_color * c * (1.6 + 0.8 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
			albedo = mix(albedo, crack_color * 0.3, c * 0.5);
		}
		if (cls == 3) {
			emission += col * hot_energy * (0.85 + 0.15 * sin(TIME * 3.1 + v_world_pos.x * 2.0 + v_world_pos.z));
		}
		// Damage: soot blotches (the Fire layer's), not a flat darkening.
		float soot = smoothstep(0.35, 0.7, nb * 0.6 + na * 0.4);
		albedo *= 1.0 - damage * mix(0.22, 0.55, soot);
		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		emission += rim * rim_color * rim_strength;
		ALBEDO = albedo;
		EMISSION = emission;
		ROUGHNESS = 1.0;
		v_m = vec3(spec, float(kind), gb_detail);
	}
	if (gb_detail > 1.5) {   // uniform branch: the derivatives stay defined
		NORMAL = fp_bump(NORMAL, VERTEX, bump_h);
	}
}

void light() {
	vec3 dl = DIFFUSE_LIGHT;
	vec3 sl = SPECULAR_LIGHT;
	fp_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_m, dl, sl);
	DIFFUSE_LIGHT = dl;
	SPECULAR_LIGHT = sl;
}
