// crown_stone.gdshader - the Ember Crown altar's stone at High+ (G-D, docs/art/gd_props.md).
// CrownPedestalArt puts crown_stone_mat.tres on surface 0 of the "Stone" node when the graphics tier is High or
// Ultra (Low / Medium keep env_painted_mat.tres, the look before G-D). Same vertex conventions as env_painted:
//   COLOR.rgb  sRGB colour block, COLOR.a 0 bottom -> 1 top, UV.y local height in metres.
// Look: dressed stone courses (joint lines by height and around the altar), sun-bleached warm tops, cool sides,
// and the crown lighting its own altar: faces turned to the crown take its glow, the joints glow faintly.
// Per instance (CrownPedestalArt, every frame): `glow_tint` (the glow pool colour: red sealed, gold awake) and
// `glow_i` (its intensity).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 focus = vec3(0.0, 1.8, 0.0);        // the crown, local space
uniform float course_h = 0.34;                    // stone course height (m)
uniform float blocks_around = 10.0;               // blocks per ring
uniform float joint_dark = 0.6;
uniform float uplight = 1.2;
uniform float joint_glow = 1.8;
uniform vec3 top_warm : source_color = vec3(1.10, 1.04, 0.92);
uniform vec3 side_cool : source_color = vec3(0.90, 0.94, 1.04);
instance uniform vec4 glow_tint : source_color = vec4(1.0, 0.62, 0.22, 1.0);
instance uniform float glow_i = 1.0;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_lp;
varying vec3 v_ln;
varying vec3 v_col;
varying float v_grad;
varying float v_y;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_lp = VERTEX;
	v_ln = NORMAL;
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_grad = COLOR.a;
	v_y = UV.y;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	return texture(noise_tex, p.zy * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

void fragment() {
	// Joint coordinates and their anti-alias widths first (derivatives only at the top level).
	float cy = v_lp.y / course_h;
	float ang = atan(v_lp.z, v_lp.x) / 6.2832 * blocks_around + floor(cy) * 0.5;
	float fy = fwidth(cy);
	float fa = fwidth(ang);
	vec3 n = normalize(v_wn);
	float na = triplanar(v_wp, n, 0.7);
	float nb = triplanar(v_wp + vec3(17.3, 5.1, 9.7), n, 0.16);
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.24) * (1.0 + (nb - 0.5) * 0.16);
	albedo *= mix(0.72, 1.10, smoothstep(0.0, 1.0, v_grad));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, v_y + 0.05));
	// Warm sun-bleached tops, cool sides.
	float up = smoothstep(0.4, 0.9, n.y);
	albedo *= mix(side_cool, top_warm * 1.28, up);
	// Courses: horizontal joints on the sides, vertical joints staggered every other course.
	float side = 1.0 - up;
	float jy = 1.0 - smoothstep(0.0, fy * 1.5 + 0.045, 0.5 - abs(fract(cy) - 0.5));
	float ja = 1.0 - smoothstep(0.0, fa * 1.5 + 0.04, 0.5 - abs(fract(ang) - 0.5));
	float joint = max(jy, ja) * side * (1.0 - smoothstep(1.0, 2.0, max(fy, fa) * 4.0));
	albedo *= 1.0 - joint * joint_dark;
	// The crown lights its altar: faces turned to it take its glow (falls off over ~3 m), the joints glow.
	vec3 to_f = focus - v_lp;
	float dist = length(to_f);
	float face = max(dot(normalize(v_ln), to_f / max(dist, 0.001)), 0.0);
	float fall = 1.0 / (1.0 + dist * dist * 0.35);
	vec3 glow = glow_tint.rgb * glow_i;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = albedo * glow * face * fall * uplight * 2.0 + glow * joint * fall * joint_glow * (0.7 + 0.3 * nb)
		+ rim * vec3(0.55, 0.65, 0.85) * 0.12 * albedo;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.25, 0.45, d) * 0.55 + smoothstep(0.55, 0.75, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
