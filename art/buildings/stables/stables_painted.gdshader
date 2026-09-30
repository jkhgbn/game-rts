// stables_painted.gdshader - the Stables' one opaque material (art-keep.md 0.3 painted look, one material per building).
// The hand-painted shading of art/shaders/painted.gdshader (triplanar paint noise, height gradient + contact band,
// toon ramp, soft rim, damage soot, glowing cracks), but the colour blocks come from the VERTEX COLOUR, so a whole
// building (stone, timber, trims, straw, the mount) is one material and one surface per merged tier (B8 / B2 budgets).
//   COLOR.rgb  flat colour of the part (for team parts: a multiplier on the team colour, 1 = the plain team colour)
//   COLOR.a    0 = team part (base_color x COLOR.rgb), 1 = plain part
//   UV2.x      part class: 0 plain, 1 stone (glowing cracks when crack_strength > 0), 2 metal (specular),
//              3 hot (self-lit a little under the bloom level: embers in a mane, hot iron), 4 hole (unlit dark)
// Uniforms: base_color = the TEAM colour (FireHallModel.set_team_color writes it), the rest as painted.gdshader.
// Instance uniforms ao_bottom / ao_height: the height gradient of each merged tier (FireHallModel._merged sets them).
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

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat float v_kind;
varying float v_spec;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_kind = UV2.x;
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
	int kind = int(v_kind + 0.5);
	// Vertex colours are authored in sRGB (like the palette): convert to linear.
	vec3 vc = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	vec3 col = mix(vc * base_color, vc, step(0.5, COLOR.a));
	v_spec = 0.0;
	if (kind == 4) {
		ALBEDO = vec3(0.0);
		EMISSION = col * 0.25;
		ROUGHNESS = 1.0;
	} else {
		float na = triplanar(v_world_pos, n, noise_scale_a);
		float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
		vec3 albedo = col * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
		float h = v_world_pos.y - ao_bottom;
		albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
		vec3 emission = vec3(0.0);
		if (kind == 1 && crack_strength > 0.0) {
			float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
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
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (v_spec > 0.5) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
