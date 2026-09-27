// ruins_ember.gdshader - ember moss of the Crown Isle ruins (task 12.V12, map-fill.md 3.1 biome 3 / section 10).
// Dark, scorched moss that soaked up the crown's embers: faint orange smoulder on the frond tips and in the heart of
// each patch. EMISSION ONLY (no lights), MultiMesh friendly (no per-instance data), one material for the whole kind.
// Vertex data baked by art/environment/biomes/ruins/build_ruins.gd (same layout as nature_painted.gdshader):
//   COLOR.rgb  sRGB colour block, COLOR.a 0 at the mesh bottom -> 1 at its top (height gradient)
//   UV.x       ember heat 0 (plain moss / stone) .. 1 (glowing tip)
//   UV.y       local height in metres (dark contact band near y = 0)
//   UV2.x      variant mask (0 = always drawn, else bit k = drawn in variant k; variant from the world-position hash,
//              the same hash1 as nature_painted.gdshader, so a preview / scatter can predict it)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float variant_count = 3.0;
uniform vec3 ember_color : source_color = vec3(1.0, 0.42, 0.08);
uniform vec3 ember_core : source_color = vec3(1.0, 0.76, 0.38);
// Faint: the hottest specks just cross the bloom threshold (world_env hdr_threshold 1.1), the rest stays a warm tint.
uniform float ember_energy = 1.5;
uniform float breathe_speed = 0.8;      // slow smoulder, every patch on its own phase
uniform float breathe_amount = 0.35;
uniform float shimmer = 0.7;            // noise drifting over the embers (0 = steady)
uniform float body_warmth = 0.03;       // warm under-glow on the moss itself (reads in shade)
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.10;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_col;
varying float v_grad;
varying float v_y;
varying float v_heat;
varying float v_phase;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
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
	v_phase = hash1(origin.xz + vec2(17.3, 5.9));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	float na = triplanar(v_wp, n, 0.6);
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.26);
	albedo *= mix(0.62, 1.06, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.22, v_y + 0.03));
	// Smoulder: a slow breath per patch + a noise shimmer drifting across the embers.
	float sh = texture(noise_tex, v_wp.xz * 1.4 + vec2(TIME * 0.05, -TIME * 0.035)).r;
	float breathe = 1.0 + sin(TIME * breathe_speed + v_phase * 6.2832) * breathe_amount;
	float g = v_heat;
	float heat = g * mix(1.0, 0.45 + sh * 1.1, shimmer) * breathe;
	vec3 glow = mix(ember_color, ember_core, clamp(g * g * sh * 1.3, 0.0, 1.0));
	// Glowing parts sit on a dark coal base (the emission carries them), the moss around them is warmed a little.
	albedo = mix(albedo, albedo * 0.35, smoothstep(0.3, 0.9, g));
	ALBEDO = albedo;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = glow * heat * ember_energy + albedo * ember_color * body_warmth * breathe
		+ rim * rim_color * rim_strength * albedo * 2.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
