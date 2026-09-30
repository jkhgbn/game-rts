shader_type spatial;
// Snagroot vine (CasterNatureVfx, task CU.V6 Nature part; caster-units.md 5.3 / 10.5): a thorned briar vine along the
// quadratic curve p0 (the Bramblesage's crook hook) -> p1 -> p2 (the victim) in WORLD space (the node sits at the
// origin; a big custom AABB), a ribbon turned to face the camera. QuadMesh 1 x 1 subdivided along Y.
// `grow` 0-1 = how far from p0 the vine reaches (the shot, the retract); `taut` 0-1 straightens its whip wave; `pulse`
// flashes the sap core (the yank). Bark-brown body with thorn notches along both edges, leaf pairs every ~0.7 m, a
// lime sap core that glows (under the bloom except while pulsing). Premultiplied alpha.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled,
		skip_vertex_transform;

instance uniform vec3 p0 = vec3(0.0);
instance uniform vec3 p1 = vec3(0.0, 1.0, 0.0);
instance uniform vec3 p2 = vec3(0.0, 0.0, 1.0);
instance uniform float width = 0.16;
instance uniform float fade = 1.0;
instance uniform float grow = 1.0;
instance uniform float taut = 0.0;
instance uniform float pulse = 0.0;
instance uniform float seed = 0.0;
instance uniform float length_m = 5.0;

uniform vec3 bark : source_color = vec3(0.26, 0.30, 0.10);
uniform vec3 bark_light : source_color = vec3(0.46, 0.52, 0.20);
uniform vec3 leaf : source_color = vec3(0.70, 0.78, 0.30);
uniform vec3 sap : source_color = vec3(0.75, 1.00, 0.40);

varying float v_t;
varying float v_side;

void vertex() {
	float t = clamp(0.5 - VERTEX.y, 0.0, 1.0) * grow;
	v_t = t;
	v_side = VERTEX.x * 2.0;
	float u = 1.0 - t;
	vec3 pos = u * u * p0 + 2.0 * u * t * p1 + t * t * p2;
	vec3 tan = normalize(2.0 * u * (p1 - p0) + 2.0 * t * (p2 - p1) + vec3(0.0001));
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - pos);
	vec3 side = cross(tan, to_cam);
	float sl = length(side);
	side = sl > 0.001 ? side / sl : vec3(1.0, 0.0, 0.0);
	vec3 up2 = normalize(cross(side, tan));
	// Whip wave travelling to the tip, gone once the vine is taut.
	float env = sin(3.14159 * t) * (1.0 - taut);
	float ph = seed * 6.28;
	pos += (side * sin(t * 11.0 - TIME * 16.0 + ph) * 0.18 + up2 * cos(t * 8.0 - TIME * 12.0 + ph) * 0.12) * env;
	float w = width * mix(1.0, 0.55, t);
	VERTEX = (VIEW_MATRIX * vec4(pos + side * VERTEX.x * w * 2.0, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float x = abs(v_side);                       // 0 centre, 1 edge
	float t = v_t;
	float s = t * length_m;                      // metres along the vine
	// thorn notches: small hooked triangles along both edges every 0.18 m, alternating sides
	float cell = fract(s / 0.18 + seed);
	float side_sel = step(0.0, v_side) == mod(floor(s / 0.18), 2.0) ? 1.0 : 0.0;
	float thorn = side_sel * step(0.62, x) * (1.0 - smoothstep(0.0, 0.5, cell)) * step(x, 1.0 - cell * 0.5 + 0.1);
	// body: a tapering stem with bark ridges
	float body = 1.0 - smoothstep(0.55, 0.66, x);
	float ridge = 0.5 + 0.5 * sin(s * 40.0 + x * 3.0);
	// leaf pairs: an oval blade either side every 0.7 m
	float lc = fract(s / 0.7 + 0.3 + seed);
	vec2 lq = vec2((lc - 0.5) * 0.7 / 0.16, (x - 0.82) / 0.2);
	float leafm = (1.0 - smoothstep(0.8, 1.0, length(lq))) * step(0.2, t);
	float ends = smoothstep(0.0, 0.03, t) * (1.0 - smoothstep(0.985, 1.0, t / max(grow, 0.001)));
	float k = fade * ends;
	vec3 col = mix(bark, bark_light, ridge * 0.5) * body;
	float cover = max(body, max(thorn, leafm));
	col = mix(col, bark * 0.8, thorn * (1.0 - body));
	col = mix(col, leaf * (0.8 + 0.2 * ridge), leafm * (1.0 - body));
	float core = (1.0 - smoothstep(0.0, 0.2, x)) * body;
	float beads = pow(0.5 + 0.5 * sin(s * 6.0 - TIME * 10.0 + seed * 3.0), 4.0);
	vec3 glow = sap * core * (0.25 + 0.55 * beads + 2.2 * pulse);
	ALBEDO = (col * cover + glow) * k;
	ALPHA = cover * k;
}
