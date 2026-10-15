// nature_paint.gdshaderinc - G-B Nature: the painted layer shared by every Nature building's shaders
// (nature_keep_painted.gdshader = the Heartwood, nature_vc.gdshader = Hall / Hollow / Spire / Bazaar merged material,
// nature_keep_leaf.gdshader + nature_cards_vc.gdshader = the leaf / blossom cards). docs/art/gb_nature_buildings.md.
//
// `gfx_detail` (material uniform, default 0; set from GameSettings.effective_graphics_quality() by NatureKit.make_materials
// and the Heartwood's _ready):
//   0  Low     the pre-G-B light and look (only the cheaper wither / foliage albedo fixes), no wind
//   1  Medium  + wind in the canopies (bodies and cards move together), soft wrapped light, cool fill, warm terminator,
//              leaf translucency, sky catch on tops, cool crease under overhangs, sun rim, moss velvet
//   2  High+   + close-up relief (bark furrows, masonry joints, leaf scales bend the normal; only pixels < ~16 m)
uniform int gfx_detail = 0;   // Low unless a script sets it (stage sets / cinematics using these shaders stay cheap)
uniform float wind_strength = 1.0;

// Shared wind field (world space): the same displacement for a canopy body and the cards on it, so they move as one.
// `h` = height above the building's origin (the trunk and walls below ~3 m do not move).
vec3 nv_wind(vec3 wp, float h, float t) {
	float k = clamp((h - 2.5) / 12.0, 0.0, 1.3);
	k *= k;
	float ph = dot(wp.xz, vec2(0.23, 0.17));
	float gust = 0.6 + 0.4 * sin(t * 0.31 + wp.x * 0.07 + wp.z * 0.05);
	vec3 d = vec3(sin(t * 1.05 + ph) + 0.35 * sin(t * 2.4 + ph * 1.9),
		0.18 * sin(t * 1.6 + ph * 2.3),
		0.55 * cos(t * 0.83 + ph * 1.3) + 0.25 * sin(t * 2.1 + ph * 0.7));
	return d * k * gust * 0.085 * wind_strength;
}

// Model-space offset for a vertex at model-space `vtx` (rotation-only model matrices: the building's gate yaw).
vec3 nv_wind_local(mat4 model, vec3 vtx, float t) {
	vec3 wp = (model * vec4(vtx, 1.0)).xyz;
	vec3 d = nv_wind(wp, wp.y - model[3].y, t);
	return (vec4(d, 0.0) * model).xyz;
}

// Derivative bump: bends the view-space normal by the screen-space gradient of the height `h`.
vec3 nv_bump(vec3 nrm, vec3 vtx, float h) {
	vec3 dpdx = dFdx(vtx);
	vec3 dpdy = dFdy(vtx);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpdy, nrm);
	vec3 r2 = cross(nrm, dpdx);
	float det = dot(dpdx, r1);
	if (abs(det) < 1e-14) {
		return nrm;
	}
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * nrm - grad);
}

// Normalised hue (max channel = 1).
vec3 nv_hue(vec3 c) {
	return c / max(max(c.r, max(c.g, c.b)), 0.001);
}

// Medium+: value structure on the albedo (world normal n, kind 0 plain / stone / wood, 1 bark, 2 foliage, 3 moss).
vec3 nv_albedo(vec3 albedo, vec3 n, int kind, float na) {
	if (gfx_detail < 1) {
		return albedo;
	}
	// Tops catch the sky, undersides take a cool crease (overhangs, eaves, the canopy's belly).
	float top = smoothstep(0.35, 0.95, n.y);
	float under = smoothstep(0.1, -0.8, n.y);
	albedo *= 1.0 + top * (kind == 2 ? 0.0 : 0.08);   // foliage keeps its value (it shares the meadow's hue)
	albedo = mix(albedo, albedo * vec3(0.78, 0.86, 1.0), under * 0.35);
	if (kind == 2) {
		// Dappled value: sunlit crowns, blue-green hollows inside the clumps.
		float dap = smoothstep(0.3, 0.75, na);
		// (Sunny = lighter, not yellower: the meadow is yellow-green, the foliage must stay apart from it, Art Lab R3.)
		albedo = mix(albedo * vec3(0.84, 0.95, 1.0), albedo, dap * (0.4 + 0.6 * top));
		albedo *= 0.93;   // the soft light lifts the shade side: keep the canopy's mean value off the meadow
	}
	return albedo;
}

// Light pass. kind: 0 plain / stone / wood, 1 bark, 2 foliage, 3 moss (velvet), 4 card (thin leaf).
// spec = the old Phong strength; moss_k = moss coverage of the pixel (0..1).
void nv_light(vec3 nrm, vec3 l, vec3 v, vec3 light_col, float atten, vec3 albedo, float spec, int kind,
		float moss_k, inout vec3 diffuse, inout vec3 specular) {
	float ndl = dot(nrm, l);
	float x = ndl * 0.5 + 0.5;
	float band = smoothstep(0.32, 0.42, x) * 0.55 + smoothstep(0.58, 0.68, x) * 0.45;
	vec3 lc = light_col * atten / PI;
	if (gfx_detail < 1) {
		if (kind == 4) {
			band = max(band, 0.28);
		}
		diffuse += band * lc;
		if (spec > 0.0) {
			specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec * lc;
		}
		return;
	}
	float soft = smoothstep(0.2, 0.78, x);
	float ramp = mix(band, soft, 0.55);
	if (kind == 2 || kind == 4) {
		ramp = max(ramp, kind == 4 ? 0.3 : 0.08);   // light passes through thin leaves: never pitch dark
	}
	vec3 hue = nv_hue(albedo);
	vec3 fill = vec3(0.62, 0.74, 1.0) * 0.14 * (1.0 - ramp) * smoothstep(0.05, 0.4, x);
	float term = smoothstep(0.3, 0.48, x) * (1.0 - smoothstep(0.48, 0.7, x));
	float sss = (kind == 2 || kind == 4) ? 0.26 : (kind == 3 || moss_k > 0.5 ? 0.24 : 0.12);
	diffuse += lc * (ramp + fill + term * sss * hue);
	float ndv = clamp(dot(nrm, v), 0.0, 1.0);
	float lit = smoothstep(0.0, 0.3, ndl);
	if (kind == 2 || kind == 4) {
		// Translucency: the sun behind a leaf lights it from inside in its own (yellower) colour.
		float back = pow(clamp(dot(v, -l), 0.0, 1.0), 3.0) * (0.55 - 0.45 * clamp(ndl, 0.0, 1.0));
		diffuse += lc * back * (hue * vec3(1.0, 1.0, 0.8)) * 0.4;
	}
	float velvet = kind == 3 ? 1.0 : moss_k;
	if (velvet > 0.01) {
		diffuse += lc * pow(1.0 - ndv, 3.0) * lit * 0.32 * velvet * (hue * 0.6 + 0.4);
	}
	if (spec > 0.0) {
		specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec * lc;
	}
	if (kind == 1) {
		// Bark: a soft waxy sheen on the plates.
		vec3 hv = normalize(l + v);
		specular += lc * pow(max(dot(nrm, hv), 0.0), 18.0) * 0.05 * lit;
	}
	// Sun rim along the lit silhouette (reads at RTS zoom).
	specular += lc * pow(1.0 - ndv, 4.0) * smoothstep(0.0, 0.5, ndl) * 0.26 * mix(vec3(1.0), hue, 0.45);
}
