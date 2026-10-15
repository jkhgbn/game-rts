// champion_palette.gdshader - ONE painted material per champion (B8 material merge, champions.md 4.6: <= 5 materials).
// A copy of art/units/kit/unit_painted.gdshader (same toon ramp, paint noise, height AO, rim, hit / level-up flash, same
// instance uniform slots of kit/README.md A.16) where the flat colour block, the spec and the rim strength come from a
// small per-champion PALETTE picked per vertex instead of one base_color. ChampionPalette (champion_palette.gd) folds
// every unit_painted part of a champion into this material: it writes the palette index into UV.x (the kit merge keeps
// UV) and fills the palette arrays from the folded materials (their base_color / spec_strength / rim_strength), so the
// authored .tres files stay the source of the colours.
// Glow parts (the kit's unit_glow.gdshader) fold in too, as EMISSIVE entries: black albedo, emission = colour x (0.4 +
// energy x pulse x glow_boost), the same look as the unshaded unit_glow (glow_boost = the kit's instance uniform, slot 5:
// veterancy, casts, death; the model's own glow code drives it on its keep_separate glow parts).
//   pal_color[i]  vec4  linear rgb of entry i (w unused)
//   pal_extra[i]  vec4  x spec_strength, y rim_strength, z glow energy (0 = painted entry), w glow pulse speed (rad/s)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

const int PAL_MAX = 32;
uniform vec4 pal_color[32];
uniform vec4 pal_extra[32];
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float glow_boost : instance_index(5) = 1.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat int v_idx;
varying float v_spec;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_idx = clamp(int(UV.x + 0.5), 0, PAL_MAX - 1);
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
	vec3 base_color = pal_color[v_idx].rgb;
	vec4 extra = pal_extra[v_idx];
	v_spec = extra.x;
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 emission = rim * rim_color * extra.y;

	// A.17: the gold level-up flash tints the surface (as unit_painted).
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	if (extra.z > 0.0) {
		// Emissive entry (a folded unit_glow): unshaded look, pulse 0.75-1.0 like unit_glow.
		float pulse = 0.75 + 0.25 * sin(TIME * extra.w);
		albedo = vec3(0.0);
		emission = base_color * (0.4 + extra.z * pulse * glow_boost);
		v_spec = 0.0;
	}
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (v_spec > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * v_spec * LIGHT_COLOR * ATTENUATION / PI;
	}
}
