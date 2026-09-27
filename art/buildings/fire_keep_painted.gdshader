// fire_keep_painted.gdshader - the Fire Keep's hand-painted surfaces (task A.7, merged in the Art Lab budget pass).
// Same height gradient, toon ramp and rim as art/shaders/painted.gdshader (art-keep.md 0.3), so fire_keep.gd
// drives it the same way (rim_color / rim_strength / damage). ONE material paints the whole Fire palette: the
// five surface kinds are slots of the uniform arrays below, picked per vertex by UV2.y (fire_keep_build.gd
// writes it; `slot_override` >= 0 forces a slot for meshes without UV2, e.g. the rubble BoxMesh MultiMeshes).
//   slot 0 S stone      pattern 1  masonry: staggered blocks, dark joints, lava glowing through in patches
//   slot 1 O obsidian   pattern 3  glossy black with glowing lava veins
//   slot 2 D dark stone pattern 1  masonry, no lava
//   slot 3 M bronze     pattern 4  metal: riveted plates, bright worn top edges
//   slot 4 T team roof  pattern 2  roof tiles (base colour = team colour, set_team_color)
// The mesh UV is in METRES (u along the surface, v up / up the slope).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

const int SLOTS = 5;

uniform vec3 base_colors[5] : source_color;
uniform float spec_strengths[5];
uniform float crack_strengths[5];
uniform int patterns[5];
uniform vec2 block_sizes[5];
uniform float joint_widths[5];
uniform float block_tints[5];

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform vec3 crack_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float crack_speed = 1.2;
uniform float crack_scale = 0.8;
uniform float damage : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;
instance uniform int slot_override = -1;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat int v_slot;
varying float v_spec;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_slot = clamp(slot_override >= 0 ? slot_override : int(UV2.y + 0.5), 0, SLOTS - 1);
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(noise_tex, p.zy * scale).r;
	float y = texture(noise_tex, p.xz * scale).r;
	float z = texture(noise_tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// x = joint mask (1 inside a joint, faded out when the joint gets thinner than a pixel),
// y = the block's random id, z = height inside the block (0 bottom .. 1 top), w = across (0..1).
vec4 blocks(vec2 uv, vec2 size, float joint) {
	float row = floor(uv.y / size.y);
	float shift = hash12(vec2(row, 7.0)) * 0.5 + 0.25;
	float cx = uv.x / size.x + row * shift;
	vec2 cell = vec2(floor(cx), row);
	vec2 f = vec2(fract(cx) * size.x, fract(uv.y / size.y) * size.y);
	float e = min(min(f.x, size.x - f.x), min(f.y, size.y - f.y));
	float aa = fwidth(uv.y) * 1.2 + 0.0001;
	float j = 1.0 - smoothstep(joint * 0.5 - aa, joint * 0.5 + aa, e);
	float fade = clamp(joint / (aa * 2.5), 0.0, 1.0);
	return vec4(j * fade, hash12(cell), f.y / size.y, f.x / size.x);
}

void fragment() {
	int s = v_slot;
	vec3 base_color = base_colors[s];
	float crack_strength = crack_strengths[s];
	int pattern = patterns[s];
	vec2 block_size = block_sizes[s];
	float joint_width = joint_widths[s];
	float block_tint = block_tints[s];

	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));

	vec3 emission = vec3(0.0);
	if (pattern == 1) {
		vec4 b = blocks(UV, block_size, joint_width);
		albedo *= 1.0 + (b.y - 0.5) * block_tint;
		albedo *= mix(0.86, 1.10, b.z);
		albedo = mix(albedo, albedo * 0.40, b.x);
		// Lava behind the wall: the joints glow in patches; damage spreads the patches.
		float patch = smoothstep(0.57 - damage * 0.34, 0.69 - damage * 0.24, nb);
		float lava = b.x * patch * crack_strength;
		emission += crack_color * lava * (1.4 + 0.7 * sin(TIME * crack_speed + v_world_pos.y * 1.3 + b.y * 6.0));
		albedo = mix(albedo, crack_color * 0.3, lava * 0.6);
	} else if (pattern == 2) {
		vec4 b = blocks(UV, block_size, joint_width);
		albedo *= 1.0 + (b.y - 0.5) * block_tint;
		// Each row's lower end catches the light, its top sits in the shadow of the row above.
		albedo *= mix(1.12, 0.80, b.z);
		albedo = mix(albedo, albedo * 0.5, b.x);
	} else if (pattern == 3) {
		float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
		float ridged = 1.0 - abs(rn * 2.0 - 1.0);
		float c = smoothstep(0.94 - damage * 0.06, 0.985, ridged)
			* smoothstep(0.46 - damage * 0.35, 0.58, nb) * crack_strength;
		emission += crack_color * c * (2.2 + 1.0 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
		albedo = mix(albedo, crack_color * 0.3, c * 0.5);
		// Glassy facets: a cool sheen on the faces that look up.
		albedo += vec3(0.05, 0.05, 0.08) * smoothstep(0.3, 0.9, n.y);
	} else if (pattern == 4) {
		vec4 b = blocks(UV, block_size, joint_width);
		albedo *= 1.0 + (b.y - 0.5) * block_tint * 0.6;
		albedo = mix(albedo, albedo * 0.55, b.x);
		// Worn, polished top rim of every plate.
		albedo *= 1.0 + smoothstep(0.78, 1.0, b.z) * 0.35;
	} else if (crack_strength > 0.0) {
		float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
		float ridged = 1.0 - abs(rn * 2.0 - 1.0);
		float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
			* smoothstep(0.52 - damage * 0.35, 0.62, nb) * crack_strength;
		emission += crack_color * c * (2.0 + 1.0 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
		albedo = mix(albedo, crack_color * 0.3, c * 0.5);
	}
	albedo *= 1.0 - damage * 0.35;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	v_spec = spec_strengths[s];
	ALBEDO = albedo;
	EMISSION = emission;
	ROUGHNESS = 1.0;
	SPECULAR = v_spec;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	if (v_spec > 0.0) {
		SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 24.0) * v_spec * LIGHT_COLOR * ATTENUATION / PI;
	}
}
