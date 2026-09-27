// ash_char.gdshader - charred wood of the Cinder Scars (task 12b.V4, docs/design/terrain.md 7.2 "ash" set).
// Burnt stumps, logs and snags: coal-black wood broken into the blocky "alligator" char checks, pale ash settled on
// every face that looks at the sky, and a few seams still smouldering orange where the fire ate deepest (broken ends,
// split hearts, the foot of a stump). EMISSION ONLY (no lights), MultiMesh friendly (no per-instance data), ONE
// material for the whole kind (ash_char_mat.tres).
// Vertex data baked by art/environment/biomes/ash/build_ash.gd (the nature_painted.gdshader layout):
//   COLOR.rgb  sRGB colour block, COLOR.a 0 at the mesh bottom -> 1 at its top (height gradient)
//   UV.x       heat 0 (cold char) .. 1 (glowing): smoulder in the char seams
//   UV.y       local height in metres (dark contact band near y = 0)
//   UV2.x      variant mask (0 = always drawn, else bit k = drawn in variant k; variant from the world-position hash,
//              the same hash1 as nature_painted.gdshader, so a preview / scatter can predict it)
//   UV2.y      kind: 0 charred wood (char checks), 1 charcoal chunk / ash heap (no checks), 2 ember heart (glows
//              through, not only in the seams)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float variant_count = 3.0;
uniform float check_size = 0.13;          // metres: size of one char block
uniform float seam_width = 0.07;          // share of a block that is dark seam
uniform vec3 ash_color : source_color = vec3(0.50, 0.48, 0.45);
uniform float ash_amount = 0.6;          // pale ash on the faces turned to the sky
uniform vec3 ember_color : source_color = vec3(1.0, 0.40, 0.08);
uniform vec3 ember_core : source_color = vec3(1.0, 0.74, 0.34);
// Hot seams just cross the bloom threshold (world_env hdr_threshold 1.1): a few orange glints per piece at 40 m.
uniform float ember_energy = 2.0;
uniform float breathe_speed = 0.9;
uniform float breathe_amount = 0.35;
uniform float shimmer = 0.75;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.16;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_col;
varying float v_grad;
varying float v_y;
varying float v_heat;
varying float v_phase;
varying flat float v_kind;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(vec2 p) {
	return vec2(hash1(p), hash1(p + vec2(19.19, 7.31)));
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float mask = UV2.x;
	if (mask > 0.5) {
		float variant = min(floor(hash1(origin.zx + vec2(3.1, 7.7)) * variant_count), variant_count - 1.0);
		if (mod(floor(mask / exp2(variant)), 2.0) < 0.5) {
			VERTEX = vec3(0.0, -3.0, 0.0);   // other variants' parts collapse to a point (never rasterised)
		}
	}
	float ih = hash1(origin.xz);
	v_col = pow(COLOR.rgb, vec3(2.2)) * (0.9 + ih * 0.2);
	v_grad = COLOR.a;
	v_y = UV.y;
	v_heat = UV.x;
	v_kind = UV2.y;
	v_phase = hash1(origin.xz + vec2(17.3, 5.9));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Cellular checks on the dominant projection: returns (distance to the nearest seam in cell units, cell value).
vec2 checks(vec3 p, vec3 n) {
	vec3 an = abs(n);
	vec2 q;
	if (an.y > max(an.x, an.z)) {
		q = p.xz;
	} else if (an.x > an.z) {
		q = vec2(p.z, p.y * 0.62);          // side faces: blocks a little taller than wide (the grain runs up)
	} else {
		q = vec2(p.x, p.y * 0.62);
	}
	q /= check_size;
	vec2 i = floor(q);
	vec2 f = fract(q);
	float f1 = 8.0;
	float f2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				id = i + g;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return vec2(f2 - f1, hash1(id * 1.37 + 4.1));
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	return texture(noise_tex, p.zy * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

void fragment() {
	vec3 n = normalize(v_wn);
	float na = triplanar(v_wp, n, 0.7);
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.3);
	float seam = 0.0;
	if (v_kind < 0.5) {
		vec2 c = checks(v_wp, n);
		seam = 1.0 - smoothstep(seam_width * 0.4, seam_width, c.x);
		// Each block a slightly different black (some grey-brown, some deep coal), the seams deeper still.
		albedo *= mix(0.78, 1.28, c.y) * mix(1.0, 0.32, seam);
	}
	// Pale ash dusting on the tops (never in the seams): what makes black wood read on the dark ash ground.
	float nlow = texture(noise_tex, v_wp.xz * 0.9 + vec2(3.7, 1.9)).r;
	float top = smoothstep(0.62, 0.72, n.y * 0.8 + (nlow - 0.5) * 0.8 + (na - 0.5) * 0.25 - 0.04);
	albedo = mix(albedo, ash_color * (0.85 + na * 0.3), top * ash_amount * (1.0 - seam * 0.8));
	albedo *= mix(0.66, 1.06, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.3, v_y + 0.04));
	// Smoulder: a slow breath per piece + a noise shimmer drifting over the hot seams.
	float sh = texture(noise_tex, v_wp.xz * 1.6 + vec2(v_wp.y * 0.8 + TIME * 0.06, -TIME * 0.045)).r;
	float breathe = 1.0 + sin(TIME * breathe_speed + v_phase * 6.2832) * breathe_amount;
	float heat = v_heat * mix(1.0, 0.35 + sh * 1.3, shimmer) * breathe;
	float glow_mask = v_kind > 1.5 ? (0.55 + 0.45 * smoothstep(0.35, 0.7, sh)) : seam;
	vec3 glow = mix(ember_color, ember_core, clamp(v_heat * v_heat * sh * 1.4, 0.0, 1.0));
	// Glowing parts sit on coal: darken the albedo where it burns so the emission carries it.
	albedo = mix(albedo, albedo * 0.3, clamp(glow_mask * v_heat * 1.5, 0.0, 1.0));
	ALBEDO = albedo;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = glow * glow_mask * heat * ember_energy + rim * rim_color * rim_strength * (albedo * 2.0 + vec3(0.02));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
