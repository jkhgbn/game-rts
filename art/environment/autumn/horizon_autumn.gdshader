// horizon_autumn.gdshader - task 20.V0: the GOLDEN AUTUMN variant of horizon/horizon.gdshader (same baked meshes,
// same cost + one noise sample). The baked vertex colours are green; the marked "AUTUMN 20.V0" block remaps the green
// ones (canopy, hill grass) to russet / amber / gold canopy blocks and ochre hills, keeping their value and the baked
// aerial-perspective cooling. When horizon.gdshader changes, re-copy it and re-apply the block.
// Material: autumn/horizon_autumn_mat.tres.
// --- original header ---
// horizon.gdshader - MAP.P3, the land beyond the cliffs (art/environment/horizon/horizon.tscn).
// One cheap shared material for every far mesh (forest canopy, rolling hill ground, crags, far ruins, pond): the
// painted look of env_painted.gdshader (vertex colour blocks, the 2-step toon ramp of art-keep.md 0.3) at a
// fraction of its cost: one planar noise sample, no triplanar, no sway, no per-instance math.
// Meshes are baked by art/environment/horizon/horizon_builder.gd:
//   COLOR.rgb  sRGB colour, already darkened / cooled with the distance from the map (aerial perspective)
//   COLOR.a    fake AO: 0 = deep shadow (crown bottoms, forest floor between trees), 1 = open top
//   UV.x       facet amount: 1 = flat-shaded faces from screen derivatives (crowns read as painted facets like the
//              border trees without duplicating vertices), 0 = the smooth vertex normal (hill ground)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale = 0.4;       // painted value variation, one sample per fragment (~2.5 m strokes)
uniform float noise_amount = 0.3;
uniform float ao_floor = 0.58;         // albedo multiplier where COLOR.a = 0
uniform float top_light = 0.08;        // faces turned to the sky get a touch lighter (painted sky light)
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.06;     // faint cool rim on the silhouettes, weaker than the map props
// AUTUMN 20.V0
uniform vec3 far_russet : source_color = vec3(0.55, 0.22, 0.10);
uniform vec3 far_amber : source_color = vec3(0.70, 0.42, 0.14);
uniform vec3 far_gold : source_color = vec3(0.76, 0.60, 0.22);
uniform vec3 far_evergreen : source_color = vec3(0.20, 0.27, 0.17);
uniform float evergreen_share = 0.22;  // share of canopy blocks that stay evergreen
uniform float autumn_value = 0.075;    // linear luminance that maps to the tone itself
uniform float autumn_mix = 0.88;       // 1 = full remap; below keeps a little of the baked (cool, distant) hue

varying vec3 v_col;
varying vec3 v_wp;
varying float v_facet;

float h_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// AUTUMN 20.V0 (begin): green vertex colours -> autumn tones, picked per ~9 m cell (one crown clump), value kept.
	float green = smoothstep(0.0, 0.25, (c.g - max(c.r, c.b)) / max(c.g, 0.001));
	float lum = dot(c, vec3(0.30, 0.59, 0.11));
	float pick = h_hash(floor(v_wp.xz / 9.0) + vec2(3.7, -1.3));
	vec3 tone = far_gold;
	if (pick < evergreen_share) {
		tone = far_evergreen;
	} else if (pick < evergreen_share + (1.0 - evergreen_share) / 3.0) {
		tone = far_russet;
	} else if (pick < evergreen_share + (1.0 - evergreen_share) * 2.0 / 3.0) {
		tone = far_amber;
	}
	vec3 autumn = tone * clamp(lum / autumn_value, 0.3, 1.6);
	c = mix(c, autumn, green * autumn_mix);
	// AUTUMN 20.V0 (end)
	v_col = c * mix(ao_floor, 1.0, COLOR.a);
	v_facet = UV.x;
}

void fragment() {
	vec3 n = NORMAL;
	if (v_facet > 0.0) {
		vec3 fn = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		fn *= sign(dot(fn, n) + 1e-4);
		n = normalize(mix(n, fn, v_facet));
		NORMAL = n;
	}
	float up = (INV_VIEW_MATRIX * vec4(n, 0.0)).y;
	float na = texture(noise_tex, (v_wp.xz + v_wp.y * 0.6) * noise_scale * 0.1).r;
	float nb = texture(noise_tex, (v_wp.xz - v_wp.y * 0.8) * noise_scale).r;
	vec3 albedo = v_col * (1.0 + (na - 0.5) * noise_amount * 0.6) * (1.0 + (nb - 0.5) * noise_amount);
	albedo *= 1.0 + max(up, 0.0) * top_light;
	float rim = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	EMISSION = rim * rim_color * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
