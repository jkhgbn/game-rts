// old_wood_web.gdshader - the Old Wood's cobweb cards and the dead twigs that hold them (task 12.V10).
// ONE material (old_wood_web_mat.tres) for the whole cobweb mesh, so the scatter can draw it as one MultiMesh with
// any material rule. The web pattern is procedural (no texture): orb webs (spokes + a spiral) and sheet webs (a loose
// crossing mesh with a funnel), anti-aliased with fwidth so a far web fades to a faint haze instead of shimmering.
// Twigs are drawn fully opaque (alpha 1) in the same transparent pass; depth is written so they sort correctly.
// Vertex data (baked by build_old_wood.gd):
//   COLOR.rgb  sRGB colour (twig bark / web tint)   COLOR.a  0 at the mesh bottom -> 1 at its top
//   UV         web cards: card coordinates, (0, 0) = the web's hub, length 1 = the anchor rim; twigs: unused
//   UV2.x      variant mask (same rule and hash as nature_painted.gdshader)
//   UV2.y      kind: 0 twig, 1 orb web, 2 sheet web
// No lights, no shadows cast (transparent), no per-instance data.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, shadows_disabled;

uniform float variant_count = 3.0;
uniform vec3 web_color : source_color = vec3(0.86, 0.90, 0.95);
uniform float strand_width = 0.022;     // in card units (a 0.6 m web: ~9 mm strands, widened by the painted look)
uniform float strand_alpha = 0.42;
uniform float haze = 0.05;              // the milky film between strands (dust, dew)
uniform float sheet_haze = 0.13;
uniform float spokes = 9.0;
uniform float turns = 6.0;
uniform float dew_sparkle = 0.6;
uniform vec3 twig_rim : source_color = vec3(0.55, 0.65, 0.85);

varying vec3 v_wp;
varying vec3 v_col;
varying float v_grad;
varying flat float v_kind;
varying float v_ih;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float mask = UV2.x;
	if (mask > 0.5) {
		float ih4 = hash1(origin.zx + vec2(3.1, 7.7));
		float variant = min(floor(ih4 * variant_count), variant_count - 1.0);
		if (mod(floor(mask / exp2(variant)), 2.0) < 0.5) {
			VERTEX = vec3(0.0, -3.0, 0.0);
		}
	}
	v_ih = hash1(origin.xz);
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_grad = COLOR.a;
	v_kind = UV2.y;
}

// A strand at distance d (card units) from its centre line: coverage that keeps its average when far away.
float strand(float d, float fw) {
	float lw = max(strand_width, fw * 1.2);
	return (1.0 - smoothstep(lw * 0.5, lw, d)) * (strand_width / lw);
}

void fragment() {
	vec3 n = NORMAL;   // cull_disabled: Godot already turns back-face normals toward the viewer
	if (v_kind < 0.5) {
		// Dead twig: dark weathered wood, lighter tips, a faint cool rim.
		float rim = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 3.0);
		ALBEDO = v_col * mix(0.70, 1.06, v_grad);
		EMISSION = rim * twig_rim * 0.12 * ALBEDO * 2.0;
		ALPHA = 1.0;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else {
		vec2 uv = UV;
		float r = length(uv);
		float a = atan(uv.y, uv.x);
		float lines = 0.0;
		float film = haze;
		if (v_kind < 1.5) {
			// Orb web: `spokes` radial threads (slightly irregular per instance) + a spiral, a small open hub.
			float sa = a / 6.2831853 * spokes + v_ih * 3.0;
			float ds = abs(fract(sa) - 0.5) / spokes * 6.2831853 * r;
			float ls = strand(ds, fwidth(ds));
			float q = r * turns * (1.0 + sin(a * 3.0 + v_ih * 9.0) * 0.06) - a / 6.2831853 + v_ih;
			float dq = abs(fract(q) - 0.5) / turns;
			float lq = strand(dq, fwidth(dq)) * smoothstep(0.10, 0.18, r);
			lines = max(ls, lq);
		} else {
			// Sheet web: two loose crossing strand sets + a funnel hole near the hub, thicker milky film.
			vec2 p = uv * 5.0 + vec2(v_ih * 5.0);
			vec2 p2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 6.0;
			float d1 = abs(fract(p.x + sin(p.y * 1.3) * 0.25) - 0.5) / 5.0;
			float d2 = abs(fract(p2.y + sin(p2.x * 1.1) * 0.3) - 0.5) / 6.0;
			lines = max(strand(d1, fwidth(d1)), strand(d2, fwidth(d2))) * 0.6;
			film = sheet_haze * smoothstep(0.08, 0.35, r);
		}
		// Fade out toward the anchor rim (torn, thinning edges) and at the very hub.
		float edge = 1.0 - smoothstep(0.80, 1.0, r);
		float alpha = clamp(lines * strand_alpha + film, 0.0, 1.0) * edge;
		// Dew beads: sparse bright points on the strands.
		float cell = hash1(floor(uv * 26.0) + vec2(v_ih * 91.0, 7.0));
		float dew = step(0.93, cell) * lines * dew_sparkle;
		ALBEDO = web_color * v_col * mix(0.85, 1.05, v_grad);
		EMISSION = web_color * (0.06 + dew * 0.8);
		ALPHA = alpha;
		ROUGHNESS = 0.6;
		SPECULAR = 0.3;
	}
}

void light() {
	// Wrapped, soft: webs are thin and lit from both sides.
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	DIFFUSE_LIGHT += (0.45 + 0.55 * smoothstep(0.30, 0.70, d)) * ATTENUATION * LIGHT_COLOR / PI;
}
