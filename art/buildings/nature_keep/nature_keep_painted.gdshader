// nature_keep_painted.gdshader - the Heartwood's hand-painted surfaces (task A2.5).
// Same base as art/shaders/painted.gdshader (art-keep.md 0.3): colour block, triplanar paint noise, height gradient
// (fake sky light + AO), dark contact band, toon ramp, soft rim, `damage` soot. Plus a painted pattern per material,
// drawn from the mesh UV that nature_keep_build.gd writes in METRES (u along the surface, v up / along):
//   pattern 0  plain (moss patches optional)
//   pattern 1  masonry: staggered blocks, dark joints, chiselled light tops; moss grows on the tops, in the
//              joints and in patches (`moss`); `damage` opens dark cracks
//   pattern 2  bark: long furrows along v (u = tiles around the limb), lighter plates; glowing sap flows up
//              the deepest furrows (`sap`), moss on the up-facing side; `damage` makes the sap bleed wider
//   pattern 3  foliage: world-space leaf cells (lit leaf faces, dark gaps), light warm tops, cool shade
//              underneath; `wither` turns patches autumn-brown (damage), `damage` dims
//   pattern 4  planks / wood: long boards (blocks along u), grain, worn light edges
// Instance uniforms (per MeshInstance3D): ao_bottom (world y of the part's bottom), ao_height.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.45, 0.42, 0.32);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.72, 0.88, 0.55);
uniform float rim_strength = 0.25;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform int pattern = 0;
uniform vec2 block_size = vec2(0.9, 0.45);
uniform float joint_width = 0.07;
uniform float block_tint = 0.18;
uniform float moss = 0.0;
uniform vec3 moss_color : source_color = vec3(0.25, 0.37, 0.12);
uniform float sap = 0.0;
uniform vec3 sap_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float sap_energy = 1.8;
uniform float sap_speed = 0.3;
uniform vec2 bark_scale = vec2(1.0, 0.16);
uniform float wither = 0.0;
uniform vec3 wither_color : source_color = vec3(0.56, 0.42, 0.17);
uniform vec3 top_tint = vec3(1.18, 1.14, 0.72);    // multipliers (linear, no colour hint)
uniform vec3 shade_tint = vec3(0.52, 0.62, 0.78);
uniform float leaf_scale = 1.7;
uniform float foliage_value = 0.74;  // foliage: the team colour is a light "cloth" colour, leaves sit darker
uniform float ao_floor = 0.35;       // how dark the baked occlusion (COLOR.r = 0) gets

instance uniform float ao_bottom = 0.0;
instance uniform float ao_height = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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

// x = joint mask, y = block id, z = height inside the block (0..1), w = across (0..1).
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

// Overlapping leaf scales on one plane (rows of discs, each row in front of the one below it, like shingles):
// x = 1 inside a scale, y = height inside it (-1 lower rim .. 1 top), z = distance from its centre (0..1), w = id.
vec4 leaf_scales(vec2 p) {
	float row = floor(p.y);
	for (int k = 0; k >= -1; k--) {
		float r = row + float(k);
		float off = mod(r, 2.0) * 0.5 + (hash12(vec2(r, 3.7)) - 0.5) * 0.3;
		float cx = floor(p.x - off) + off + 0.5;
		float cx2 = cx + (p.x > cx ? 1.0 : -1.0);
		float cy = r + 1.0 + (hash12(vec2(cx, r)) - 0.5) * 0.2;
		float cy2 = r + 1.0 + (hash12(vec2(cx2, r)) - 0.5) * 0.2;
		float rad = 0.74;
		float d1 = length(p - vec2(cx, cy)) / rad;
		float d2 = length(p - vec2(cx2, cy2)) / rad;
		if (d1 < 1.0 || d2 < 1.0) {
			bool first = d1 < d2;
			float d = first ? d1 : d2;
			vec2 c = first ? vec2(cx, cy) : vec2(cx2, cy2);
			return vec4(1.0, (p.y - c.y) / rad, d, hash12(c * 1.37));
		}
	}
	return vec4(0.0, 0.0, 1.0, 0.0);
}

float moss_mask(vec3 n, float na, float nb, float joint) {
	float up = smoothstep(0.45, 0.9, n.y);
	float on_top = up * smoothstep(0.38, 0.6, na + 0.1);
	float patches = smoothstep(0.68, 0.78, nb) * smoothstep(0.45, 0.6, na) * (1.0 - up * 0.5);
	float in_joints = joint * smoothstep(0.55, 0.7, nb);
	return clamp(on_top + patches * 0.8 + in_joints * 0.8, 0.0, 1.0);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	vec3 emission = vec3(0.0);
	float dist = length(VERTEX);
	float far = smoothstep(28.0, 55.0, dist);
	float joint = 0.0;

	if (pattern == 1) {
		vec4 b = blocks(UV, block_size, joint_width);
		joint = b.x;
		albedo *= 1.0 + (b.y - 0.5) * block_tint;
		albedo *= mix(0.84, 1.10, b.z);
		albedo = mix(albedo, albedo * 0.40, b.x);
		// Cracks opened by damage: dark ridged lines through the blocks.
		float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 0.16);
		float ridged = 1.0 - abs(rn * 2.0 - 1.0);
		float c = smoothstep(0.965 - damage * 0.05, 0.99, ridged) * smoothstep(0.35, 0.5, damage + nb * 0.4);
		albedo = mix(albedo, albedo * 0.25, c);
	} else if (pattern == 2) {
		vec2 buv = UV * bark_scale;
		float f = texture(noise_tex, buv).r;
		float ridged = 1.0 - abs(f * 2.0 - 1.0);
		float furrow = smoothstep(0.74, 0.95, ridged);
		albedo *= 1.0 + (f - 0.5) * 0.45;
		albedo *= 1.0 - 0.55 * furrow;
		joint = furrow;
		if (sap > 0.0) {
			float mask = smoothstep(0.56 - damage * 0.2, 0.68 - damage * 0.15,
				texture(noise_tex, buv * vec2(0.5, 0.45) + vec2(0.31, 0.57)).r);
			float core = smoothstep(0.925 - far * 0.05 - damage * 0.03, 0.985, ridged) * mask;
			float flow = 0.5 + 0.5 * sin(UV.y * 2.2 - TIME * sap_speed * 6.2831853 + UV.x * 9.0);
			float e = sap * sap_energy * (1.0 + damage * 0.6) * (1.0 - far * 0.35);
			emission += sap_color * e * core * (0.35 + 0.65 * flow);
			albedo = mix(albedo, sap_color * 0.4, core * sap * 0.6);
		}
	} else if (pattern == 3) {
		vec3 w = pow(abs(n), vec3(6.0));
		w /= (w.x + w.y + w.z + 0.0001);
		vec3 p = v_world_pos * leaf_scale;
		vec4 sx = leaf_scales(p.zy);
		vec4 sy = leaf_scales(p.xz + vec2(0.37, 0.71));
		vec4 sz = leaf_scales(p.xy + vec2(0.53, 0.19));
		vec4 s = sx * w.x + sy * w.y + sz * w.z;
		albedo *= foliage_value;
		// Each leaf scale: its lower rim catches the light, its top sits in the shadow of the scale above,
		// a soft darker line along its edge; each has its own tint. Fades toward flat colour with distance.
		float fade = 1.0 - far * 0.7;
		float lit = smoothstep(-0.1, -0.85, s.y) * (1.0 - smoothstep(0.82, 1.0, s.z));
		float shadowed = smoothstep(-0.35, 0.25, s.y);
		float rim_line = smoothstep(0.84, 0.98, s.z) * smoothstep(0.2, -0.6, s.y);
		albedo *= 1.0 + (lit * 0.26 - shadowed * 0.2 - rim_line * 0.22) * fade;
		albedo *= 1.0 + (s.w - 0.5) * 0.18 * fade;
		albedo *= mix(0.7, 1.0, s.x);
		// Leaf clusters: broad darker patches (painted depth inside the clump).
		float cluster = smoothstep(0.42, 0.62, nb);
		albedo *= mix(0.78, 1.06, cluster);
		// Strong volume: warm light on the tops, deep cool shade underneath (the canopy reads as clumps).
		float up = n.y;
		albedo *= mix(shade_tint * 0.55, vec3(1.0), smoothstep(-0.8, 0.45, up));
		albedo = mix(albedo, albedo * top_tint, smoothstep(0.35, 0.95, up) * (0.45 + 0.55 * na));
		float wm = smoothstep(1.0 - wither - 0.08, 1.0 - wither + 0.08, nb * 0.7 + s.w * 0.3 + 0.15);
		albedo = mix(albedo, wither_color * (0.75 + 0.5 * na) * mix(0.8, 1.1, lit), wm * step(0.001, wither));
	} else if (pattern == 4) {
		vec4 b = blocks(UV, block_size, joint_width);
		joint = b.x;
		albedo *= 1.0 + (b.y - 0.5) * block_tint;
		float grain = texture(noise_tex, vec2(UV.x * 0.35, UV.y * 4.0 + b.y * 7.0)).r;
		albedo *= 0.88 + grain * 0.24;
		albedo *= 1.0 + smoothstep(0.8, 1.0, b.z) * 0.25;
		albedo = mix(albedo, albedo * 0.45, b.x);
	}

	// Baked occlusion (vertex colour r; white on meshes that bake none): dark crevices between canopy clumps.
	albedo *= mix(ao_floor, 1.0, COLOR.r);

	// Moss (before the AO so it sits in the contact shade).
	if (moss > 0.0) {
		float m = moss_mask(n, na, nb, joint * (pattern == 2 ? 0.0 : 1.0)) * moss;
		albedo = mix(albedo, moss_color * (0.8 + 0.4 * na), m);
	}

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
	albedo *= 1.0 - damage * 0.3;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength;

	ALBEDO = albedo;
	EMISSION = emission;
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
