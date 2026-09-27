// torvald_frost.gdshader - Torvald's hero variant of art/units/kit/unit_painted.gdshader (task A.3).
// Same colour blocks, paint noise, height gradient, toon ramp, rim, hit / level-up flash and instance uniforms as
// unit_painted (so the kit's hit flash, gold flash and ao_height work unchanged), plus four painted frost looks:
//   frost_top   snow dusting on up-facing surfaces (fur collar, shoulders, hat of the crown), broken by noise
//   frost_hem   rime creeping up from the ground (robe hem), with a faint cold shimmer
//   fur         vertical painted fur streaks around the pivot axis (mantle, cuffs)
//   crystal     ice crystal: deep core where the face looks at you, glowing cold edges (below the bloom threshold)
// Frost / fur noise is sampled in MESH space (the merged pivot mesh), so it never swims when Torvald walks.
// Uniforms of unit_painted: base_color, noise_tex, noise_scale_a / _b, spec_strength, rim_color, rim_strength.
// Instance uniforms: ao_bottom, ao_height, hit_flash, flash_color (set by the kit).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.45, 0.75, 0.95);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;

uniform vec3 frost_color : source_color = vec3(0.90, 0.95, 1.00);
uniform float frost_top : hint_range(0.0, 1.0) = 0.0;
uniform float frost_scale = 2.2;
uniform float frost_hem : hint_range(0.0, 1.0) = 0.0;
uniform float frost_hem_height = 0.45;
uniform float fur : hint_range(0.0, 1.0) = 0.0;
uniform float fur_density = 9.0;
uniform float crystal : hint_range(0.0, 1.0) = 0.0;
uniform vec3 crystal_deep : source_color = vec3(0.22, 0.46, 0.78);
uniform vec3 crystal_glow : source_color = vec3(0.75, 0.92, 1.00);
uniform float crystal_energy = 0.9;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 2.1;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
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
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	vec3 emission = vec3(0.0);

	// Painted fur streaks: noise wrapped around the pivot's vertical axis, stretched along y.
	if (fur > 0.0) {
		float ang = atan(v_local_pos.z, v_local_pos.x) / 6.2831853;
		float s = texture(noise_tex, vec2(ang * fur_density, v_local_pos.y * 0.9)).r;
		float s2 = texture(noise_tex, vec2(ang * fur_density * 2.3 + 0.37, v_local_pos.y * 1.7)).r;
		albedo *= 1.0 + ((s * 0.6 + s2 * 0.4) - 0.5) * 0.55 * fur;
	}

	// Ice crystal: saturated deep core facing the viewer, pale glowing edges.
	if (crystal > 0.0) {
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float edge = pow(1.0 - facing, 1.6);
		albedo = mix(albedo, mix(crystal_deep, base_color * 1.05, edge), crystal);
		emission += crystal_glow * (edge * 0.8 + 0.15) * crystal_energy * crystal;
	}

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	// Frost (painted after the AO so it stays bright, like light snow in the shade).
	float nf = triplanar(v_local_pos * frost_scale, normalize(v_local_normal), 1.0);
	if (frost_top > 0.0) {
		float up = smoothstep(0.15, 0.75, n.y);
		float breakup = smoothstep(0.40, 0.58, nf + (n.y - 0.5) * 0.35);
		albedo = mix(albedo, frost_color * mix(0.86, 1.0, nf), up * breakup * frost_top);
	}
	if (frost_hem > 0.0) {
		float hf = 1.0 - smoothstep(0.0, frost_hem_height, h + (nf - 0.5) * 0.30);
		hf *= frost_hem;
		albedo = mix(albedo, frost_color * 0.92, hf);
		emission += crystal_glow * hf * 0.10;
	}

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	// A.17: the gold level-up flash (low blue, mid green: hit white, Ice freeze blue, Fire ember are untouched) also tints
	// the surface, so pale and blue parts turn gold instead of adding up to white.
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (spec_strength > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * spec_strength * LIGHT_COLOR * ATTENUATION / PI;
	}
}
