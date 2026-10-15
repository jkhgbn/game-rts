// painted_vc.gdshader - painted.gdshader (art-keep.md 0.3 / 5.1) with the colour blocks in the VERTEX data, so every
// painted part of a building (stone, dark stone, trims, team roof, holes) draws with ONE material (B8 budget) and a
// merged tier with ONE surface. The shading is painted.gdshader's, line for line; only where the per-part values
// come from differs. Baked by PaintedVC (art/buildings/painted_vc.gd) from the building's painted materials:
//   COLOR.rgb  the part's base_color (sRGB, like the palette); team parts: a multiplier on the team colour
//   COLOR.a    0 = team part (base_color uniform x COLOR.rgb), 1 = plain part
//   UV2.x      crack strength of the part (painted crack_strength; x the crack_strength uniform, 1 by default);
//              < -0.5 = hole (unlit dark: the old unshaded "hole" StandardMaterial3D, colour COLOR.rgb)
//   UV2.y      spec strength of the part (painted spec_strength)
//   CUSTOM0.xy crack scale / crack speed of the part (0 = the uniforms below)
// Uniforms: base_color = the TEAM colour (set_team_color writes it); the rest as painted.gdshader (rim, damage, crack
// colour / speed / scale are shared by the whole building, as they already were in every painted material of one).
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
uniform float crack_energy = 1.0;   // emission of the cracks (1 = painted.gdshader's; < 1 keeps them under the bloom)
uniform float damage : hint_range(0.0, 1.0) = 0.0;
// G-E value pass (docs/art/ge_value_pass.md): a per-kingdom grade of the team parts (saturation / value of the team
// colour, hue kept) and of the plain parts (saturation). 1 = unchanged (every kingdom but Shadow; ShadowDress.grade).
uniform float team_sat : hint_range(0.0, 1.5) = 1.0;
uniform float team_val : hint_range(0.0, 1.5) = 1.0;
uniform float body_sat : hint_range(0.0, 1.5) = 1.0;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_spec_in;
varying float v_crack;
varying vec2 v_crack_ss;
varying float v_spec;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_crack = UV2.x;
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
	// Vertex colours are authored in sRGB (like the palette and base_color): to linear.
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	vec3 tcol = base_color;
	vec3 body = vc;
	if (team_sat != 1.0 || team_val != 1.0 || body_sat != 1.0) {
		// graded in a perceptual (gamma 2) space: hue kept
		vec3 tg = sqrt(max(tcol, vec3(0.0)));
		tcol = mix(vec3(dot(tg, vec3(0.2126, 0.7152, 0.0722))), tg, team_sat) * team_val;
		tcol *= tcol;
		vec3 bg = sqrt(max(body, vec3(0.0)));
		body = mix(vec3(dot(bg, vec3(0.2126, 0.7152, 0.0722))), bg, body_sat);
		body *= body;
	}
	vec3 col = mix(tcol * vc, body, step(0.5, COLOR.a));
	v_spec = 0.0;
	if (v_crack < -0.5) {
		// Hole (roof breach, doorway dark): unlit, like the unshaded hole material it replaces.
		ALBEDO = vec3(0.0);
		EMISSION = col;
		ROUGHNESS = 1.0;
	} else {
		vec3 n = normalize(v_world_normal);
		float na = triplanar(v_world_pos, n, noise_scale_a);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

		// Height gradient (fake sky light + AO) and dark contact band.
		float h = v_world_pos.y - ao_bottom;
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

		// Glowing cracks / veins (ridged noise), only on parts that had them.
		vec3 emission = vec3(0.0);
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
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (v_spec > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * v_spec * LIGHT_COLOR * ATTENUATION / PI;
	}
}
