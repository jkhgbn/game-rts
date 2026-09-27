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

varying vec3 v_col;
varying vec3 v_wp;
varying float v_facet;

void vertex() {
	v_col = pow(COLOR.rgb, vec3(2.2)) * mix(ao_floor, 1.0, COLOR.a);
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
