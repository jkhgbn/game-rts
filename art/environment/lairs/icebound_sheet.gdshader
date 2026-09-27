// icebound_sheet.gdshader - the ice sheet on the river round the Icebound Barge (task 13c.V9). A flat PlaneMesh
// (node scale 1) lying just over the water (RiverSystem.WATER_Y -0.35 + 0.05); the banks cut it where they rise
// above it. Opaque (the painted water is opaque too, so nothing sorts), painted toon ramp, no textures. The pattern
// is in the mesh's LOCAL space (the barge's frame), so the mirrored barge gets the same ice turned with it.
// Inside `radius`: pale sea ice with snow drifts streaked along the flow (local +Z), darker clear "black ice"
// windows, cracks radiating from the hull and a web of fine ones, glints. Toward the edge the sheet breaks into
// floes (Voronoi cells, dark water in the gaps, a bright broken rim on each floe).
// instance uniform `freeze` 0 -> 1 grows the ice out from the barge (and shrinks it back for the thaw).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

instance uniform float freeze = 1.0;
uniform float radius = 5.0;
uniform vec3 ice_color : source_color = vec3(0.56, 0.72, 0.84);
uniform vec3 snow_color : source_color = vec3(0.93, 0.96, 1.0);
uniform vec3 clear_color : source_color = vec3(0.22, 0.38, 0.5);
uniform vec3 crack_color : source_color = vec3(0.16, 0.3, 0.42);
uniform vec3 glow_color : source_color = vec3(0.62, 0.88, 1.0);
uniform float glint_strength = 1.6;

varying vec2 v_lp;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(17.3, 5.1)));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + vec2(7.1, 1.3)) * 0.3 + vnoise(p * 4.07 - vec2(3.3, 5.9)) * 0.15;
}

// Voronoi: x = distance to the nearest cell centre, y = distance to the border, zw = the cell id.
vec4 voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = i + g;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec4(d1, (d2 - d1) * 0.5, id);
}

float glints(vec2 w, float amount, float t) {
	vec2 c = floor(w);
	vec2 f = fract(w) - 0.5;
	float h = hash(c + 3.7);
	vec2 o = vec2(hash(c + 1.3), hash(c + 9.1)) - 0.5;
	vec2 d = abs(f - o * 0.6);
	float star = max(1.0 - smoothstep(0.0, 0.07, length(d)),
			(1.0 - smoothstep(0.0, 0.02, min(d.x, d.y))) * (1.0 - smoothstep(0.0, 0.2, max(d.x, d.y))) * 0.6);
	float tw = pow(max(0.0, sin(t * (1.5 + h * 2.0) + h * 40.0)), 10.0);
	return step(1.0 - amount, h) * star * (0.2 + tw);
}

void vertex() {
	v_lp = VERTEX.xz;
}

void fragment() {
	vec2 p = v_lp;
	float r = length(p);
	vec2 dir = p / max(r, 0.001);
	float ang = atan(p.y, p.x);
	float R = radius * clamp(freeze, 0.0, 1.0);
	// The sheet's reach: stretched along the flow (+Z), a wobbly edge.
	vec2 q = vec2(p.x * 1.18, p.y * 0.92);
	float rq = length(q);
	float edge = R * (0.86 + 0.14 * vnoise(dir * 2.5 + 3.0) + 0.08 * vnoise(dir * 7.0));
	// Floes in the outer band: each cell stays only while its own threshold is inside the edge.
	vec4 vc = voronoi(p * 0.95 + vec2(11.0, 3.0));
	float cell_r = length((vc.zw + 0.5 - vec2(11.0, 3.0)) / 0.95);
	float keep = step(cell_r + (hash(vc.zw) - 0.5) * 1.4, edge);
	float inner = step(rq, edge * 0.7);
	if (inner < 0.5 && (keep < 0.5 || vc.y < 0.05 || rq > edge + 0.9)) {
		discard;
	}
	// Base: ice, snow drifts along the flow, clear windows.
	float drift = fbm(vec2(p.x * 1.1, p.y * 0.35) + 4.0);
	float snow = smoothstep(0.52, 0.74, drift);
	float clear = smoothstep(0.62, 0.8, fbm(p * 0.55 + 9.0)) * (1.0 - snow);
	vec3 c = ice_color * (0.9 + 0.2 * fbm(p * 2.2));
	c = mix(c, clear_color, clear * 0.75);
	c = mix(c, snow_color, snow * 0.85);
	// Thinner, bluer ice toward the edge (older, thicker and whiter at the hull).
	c = mix(c, clear_color * 1.3, smoothstep(0.45, 1.0, rq / max(edge, 0.1)) * 0.35 * (1.0 - snow));
	// Cracks: radiating from the hull + a fine web.
	float lane = ang / TAU * 14.0 + vnoise(dir * 3.0) * 0.8 + (vnoise(p * 0.9) - 0.5) * 0.6;
	float lw = abs(fract(lane) - 0.5) * TAU / 14.0 * r;   // metres from the crack line
	float rad = 1.0 - smoothstep(0.02, 0.06, lw);
	rad *= smoothstep(1.2, 2.0, r) * (1.0 - snow * 0.8);
	vec4 web = voronoi(p * 2.6);
	float web_mask = smoothstep(0.42, 0.68, fbm(p * 0.45 + 2.0));   // the fine web only in patches
	float fine = (1.0 - smoothstep(0.0, 0.025, web.y)) * (1.0 - snow) * 0.55 * web_mask;
	float cr = max(rad, fine);
	c = mix(c, crack_color, cr * 0.8);
	// Floe rims: bright broken edges, a darker wet ring under them.
	float rim = (1.0 - inner) * (1.0 - smoothstep(0.05, 0.14, vc.y));
	c = mix(c, snow_color * 1.05, rim * 0.9);
	ALBEDO = c;
	float t = TIME;
	EMISSION = glow_color * (glints(p * 3.3, 0.14, t) * glint_strength * (1.0 - snow * 0.5) + cr * 0.12
			+ clear * 0.08);
	ROUGHNESS = mix(0.3, 0.9, snow);
	SPECULAR = mix(0.6, 0.2, snow);
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.44, d) * 0.55 + smoothstep(0.58, 0.70, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	SPECULAR_LIGHT += pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 40.0) * 0.35 * LIGHT_COLOR * ATTENUATION;
}
