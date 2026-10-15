// ice_paint.gdshaderinc - G-B "painted PBR" layer for the Ice kingdom's buildings (docs/art/gb_ice_buildings.md).
// Shared by ice_painted_vc.gdshader (Frost Hall, Snow Lodge, Rime Spire, Ice Wall: the B8 one-material merge) and
// ice_painted.gdshader (the Rime Keep's per-part materials). Same idea as the units' G3b layer
// (art/units/kit/unit_paint.gdshaderinc), tuned for crystal ice, ice-stone, snow and silver seen from the RTS camera:
//   * ICE (team crystals, glazed roof tiles) and FROST (pale glazed blocks): a deep body with a fake interior (the noise
//     sampled again behind the surface along the view ray: cloudy depth and bright inner fracture planes, a cheap
//     stand-in for refraction), a sky reflection at grazing angles, crisp facet edges, a sharp twin specular, light
//     that wraps through the ice and glows when the sun is behind it; damage = white fracture lines that spread.
//   * SNOW: a very soft wrapped ramp with a blue shadow side (snow scatters), view-dependent glints close up.
//   * STONE: snow caught on every upward face (broken by the paint noise), ashlar courses with frost in the joints
//     (opt-in: ip_masonry), hoarfrost creeping up from the ground, a cold fill on the turned-away side.
//   * METAL (silver-blue trims): a fake sky / horizon reflection, a sharp tinted highlight, frost on its tops.
//   * every kind: a light-side rim catch on the silhouette.
// Cost tier `gb_detail` (material uniform, written from GameSettings.effective_graphics_quality() by IceShapes):
//   0 Low    = the light ramp, sky fresnel on ice, snow on stone tops (a few ALU, no extra texture sample)
//   1 Medium = + ice interior (one parallax layer), facet edges, masonry, hoarfrost, metal reflection, frost on ice tops
//   2 High / 3 Ultra = + a second interior layer (fracture planes), snow / frost glints (only on pixels < ~6 cm)
// Include it AFTER the shader's own uniforms (it reads noise_tex).

uniform float gb_detail = 2.0;
uniform vec3 ip_shade_tint : source_color = vec3(0.46, 0.60, 0.95);
uniform vec3 ip_sky : source_color = vec3(0.80, 0.90, 1.00);
uniform vec3 ip_snow_color : source_color = vec3(0.74, 0.80, 0.89);
uniform float ip_snow = 1.0;          // snow caught on upward stone / metal faces (0 = none)
uniform float ip_masonry = 1.0;       // ashlar courses on vertical stone faces (0 = the parts are already blocks)
uniform float ip_ice_glow = 1.0;      // strength of the ice interior's glow
uniform float ip_light_rim = 0.26;
uniform float ip_ground_y = 0.0;      // world y of the ground (hoarfrost creeps up from it)

const int IK_STONE = 0;
const int IK_DARK = 1;
const int IK_METAL = 2;
const int IK_ICE = 3;      // team crystal / glazed team tiles
const int IK_SNOW = 4;
const int IK_FROST = 5;    // pale glazed ice blocks (not team)
const int IK_PLAIN = 6;    // team cloth (matte team parts), warm goods (pelts, crates, wood): light layer + snow on tops

float ip_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 ip_hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// 1 while a pattern of `period` metres is wider than ~2 pixels, 0 once it would shimmer.
float ip_fade(float period, float px) {
	return 1.0 - smoothstep(period * 0.22, period * 0.55, px);
}

vec3 ip_hue(vec3 c) {
	return c / max(max(c.r, max(c.g, c.b)), 0.03);
}

// Triplanar paint noise with explicit gradients (dx / dy = dFdx / dFdy of the world position, taken at the top of
// fragment() before any branch): safe inside per-fragment branches (no implicit derivatives).
float ip_tri(vec3 p, vec3 n, float scale, vec3 dx, vec3 dy) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = textureGrad(noise_tex, p.zy * scale, dx.zy * scale, dy.zy * scale).r;
	float y = textureGrad(noise_tex, p.xz * scale, dx.xz * scale, dy.xz * scale).r;
	float z = textureGrad(noise_tex, p.xy * scale, dx.xy * scale, dy.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

// Surface kind of a vertex-coloured part (sRGB colour, team flag, spec strength): the Ice palette's blocks.
int ip_kind_of(vec3 c, bool team, float spec) {
	if (team) {
		return spec >= 0.3 ? IK_ICE : IK_PLAIN;   // the Ice team parts are glazed (spec 0.45-0.5); awnings are matte
	}
	if (spec >= 0.33) {
		return IK_METAL;
	}
	if (spec >= 0.25) {
		return IK_FROST;
	}
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	if (mx > 0.6 && sat < 0.27 && spec < 0.2) {
		return IK_SNOW;
	}
	if (c.r > c.b + 0.04) {
		return IK_PLAIN;   // warm goods: never masonry / hoarfrost
	}
	if (mx < 0.42) {
		return IK_DARK;
	}
	return IK_STONE;
}

// The face's dominant-axis plane coordinates (for 2D patterns on flat-shaded blocks).
vec2 ip_plane(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y >= a.x && a.y >= a.z) {
		return p.xz;
	}
	return a.x > a.z ? p.zy : p.xy;
}

// Distance to the nearest Voronoi cell edge (F2 - F1, 2D, cells of 1).
float ip_voronoi_edge(vec2 x) {
	vec2 cell = floor(x);
	vec2 f = fract(x);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = ip_hash2(cell + g);
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

// The fragment layer. col = the part's linear base colour (already x the paint noise and height gradient),
// wp / n = world position / normal, v = world direction to the camera, na / nb = the shader's two paint noises,
// dmg = the damage uniform. Changes albedo / emission; returns the glint mask for the light pass (0..1).
// dpx / dpy = dFdx / dFdy of the world position, nfw = length(fwidth(world normal)): all taken by the caller at the
// top of fragment(), before any per-fragment branch (derivatives are undefined inside divergent branches).
float ip_surface(int kind, vec3 col, vec3 wp, vec3 n, vec3 v, vec3 dpx, vec3 dpy, float nfw, float na, float nb, float dmg,
		inout vec3 albedo, inout vec3 emission) {
	float detail = gb_detail;
	float px = length(abs(dpx) + abs(dpy));   // = length(fwidth(wp))
	float ndv = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 3.0);
	float glint = 0.0;
	vec3 snow_lin = ip_snow_color * ip_snow_color;   // sRGB-ish -> linear (cheap)
	if (kind == IK_ICE || kind == IK_FROST) {
		bool team = kind == IK_ICE;
		vec3 hue = ip_hue(col);
		// Deep body: the ice is darker inside, the sky shows on its grazing faces (a glossy, wet read at any zoom).
		albedo *= team ? 0.80 : 0.90;
		albedo = mix(albedo, ip_sky * (team ? 0.62 : 0.72), fres * (team ? 0.12 : 0.2));
		emission += col * (team ? 0.035 : 0.02) * ip_ice_glow;   // light trapped in the ice (Low too: one MAD)
		if (detail >= 0.5) {
			// Fake interior: the noise again 0.45 m behind the surface along the view ray (parallax), cloudy depth.
			vec3 pin = wp - v * 0.45;
			float cloud = ip_tri(pin, n, 1.7, dpx, dpy);
			float depth_k = mix(0.55, 1.0, ndv);
			float inner = smoothstep(0.38, 0.78, cloud) * 0.11;
			if (detail >= 1.5) {
				// Second layer deeper in: thin bright fracture planes (ridged noise).
				float rn = ip_tri(wp - v * 0.9 + vec3(5.3, 1.7, 2.9), n, 0.55, dpx, dpy);
				float ridge = 1.0 - abs(rn * 2.0 - 1.0);
				inner += smoothstep(0.86, 0.97, ridge) * 0.24;
			}
			emission += col * hue * inner * 1.5 * depth_k * ip_ice_glow * (team ? 1.0 : 0.6);
			// Crisp facet edges (the normal jumps between flat facets): a thin pale line, faded with distance.
			float edge = clamp(nfw * 2.2 - 0.15, 0.0, 1.0) * (1.0 - smoothstep(0.03, 0.09, px));
			emission += ip_sky * edge * 0.16;
			// Frost dusting on the faces that look up.
			float up = smoothstep(0.62, 0.92, n.y) * smoothstep(0.42, 0.62, nb + (na - 0.5) * 0.5);
			albedo = mix(albedo, snow_lin, up * (team ? 0.0 : 0.35));
			emission += ip_sky * fres * 0.05;   // the fake sky reflection, a touch on top of the albedo mix
		}
		// Damage: white fracture lines spread through the ice (more and wider as the HP drops), crazed ice around them.
		if (dmg > 0.02) {
			float e = ip_voronoi_edge(ip_plane(wp, n) * 1.7 + vec2(nb * 1.3, na * 0.9));
			float w = 0.025 + 0.06 * dmg;
			float reach = smoothstep(0.75 - dmg * 0.9, 0.85 - dmg * 0.9, 1.0 - nb);
			float crack = (1.0 - smoothstep(w * 0.5, w, e)) * reach;
			float craze = (1.0 - smoothstep(w, w * 4.0, e)) * reach;
			albedo = mix(albedo, vec3(0.80, 0.88, 0.95), craze * 0.18 + crack * 0.4);
			emission += vec3(0.62, 0.84, 1.0) * crack * (0.25 + 0.35 * dmg);
		}
	} else if (kind == IK_SNOW) {
		// Glints: a few cells catch the sun close up (light pass), never at RTS distance (they would shimmer).
		if (detail >= 1.5) {
			vec2 q = ip_plane(wp, n) * 16.0;
			float h = ip_hash(floor(q));
			float dot_k = 1.0 - smoothstep(0.12, 0.3, length(fract(q) - 0.5));
			glint = step(0.93, h) * dot_k * (1.0 - smoothstep(0.03, 0.06, px));
		}
		// Wind-packed pockets: a cold blue in the hollows of the broad noise, the crests stay white.
		albedo *= mix(0.93, 1.0, na);
		albedo = mix(albedo, albedo * vec3(0.74, 0.84, 1.0), smoothstep(0.35, 0.7, nb) * 0.45);
	} else {
		bool metal = kind == IK_METAL;
		// Snow caught on every upward face (any tier: a smoothstep on the noise the shader already sampled).
		float up = smoothstep(0.72, 0.92, n.y);
		// A soft, mostly even dusting (density varies with the fine noise; the broad noise only thins it a little), so a
		// big flat top never reads as camouflage blotches. Dark plinths keep more of their edge read.
		float drift = 0.6 + 0.4 * smoothstep(0.3, 0.7, na) - 0.2 * smoothstep(0.55, 0.75, nb);
		float snow = up * drift * ip_snow * (metal ? 0.6 : (kind == IK_DARK ? 0.5 : 0.75));
		bool plain = kind == IK_PLAIN;
		if (detail >= 0.5 && !plain) {
			if (!metal && ip_masonry > 0.5 && abs(n.y) < 0.55) {
				// Ashlar courses (0.55 m) with staggered joints; the joints hold frost.
				vec2 pl = ip_plane(wp, n);
				float cy = wp.y / 0.55;
				float row = floor(cy);
				float cx = pl.x / 1.1 + (mod(row, 2.0) * 0.5) + ip_hash(vec2(row, 3.0)) * 0.3;
				float jy = abs(fract(cy) - 0.5) * 0.55;
				float jx = abs(fract(cx) - 0.5) * 1.1;
				float joint = 1.0 - smoothstep(0.018, 0.04, min(0.275 - jy, 0.55 - jx));
				joint *= ip_fade(0.55, px);
				float blk = ip_hash(vec2(row, floor(cx)));
				albedo *= 1.0 + (blk - 0.5) * 0.12 * ip_fade(0.55, px);
				albedo = mix(albedo, albedo * 0.52, joint * 0.75);
			}
			// Hoarfrost creeping up from the ground (pale, broken), and a cold sheen in crevices of the paint noise.
			float hy = wp.y - ip_ground_y;
			float hoar = (1.0 - smoothstep(0.15, 1.3 + nb * 0.8, hy)) * smoothstep(0.35, 0.7, na);
			albedo = mix(albedo, snow_lin * 0.9, hoar * (metal ? 0.25 : 0.4));
			if (metal) {
				// Silver: darker body + a small fake sky / horizon / ground reflection (emission).
				vec3 r = reflect(-v, n);
				vec3 env = mix(vec3(0.20, 0.23, 0.27), ip_sky, smoothstep(-0.25, 0.35, r.y));
				albedo *= 0.78;
				emission += env * col * 0.22;
			}
			if (detail >= 1.5) {
				vec2 q = ip_plane(wp, n) * 14.0;
				float h = ip_hash(floor(q) + 7.0);
				float dot_k = 1.0 - smoothstep(0.12, 0.3, length(fract(q) - 0.5));
				glint = step(0.95, h) * dot_k * max(snow, hoar) * (1.0 - smoothstep(0.03, 0.06, px));
			}
		}
		albedo = mix(albedo, snow_lin, snow);
	}
	return glint;
}

// The light pass. kind / spec / glint come from the fragment (varyings).
void ip_light(int kind, float spec, float glint, vec3 nrm, vec3 l, vec3 v, vec3 light_col, float atten, vec3 albedo,
		inout vec3 diffuse, inout vec3 specular) {
	float ndl = dot(nrm, l);
	float x = ndl * 0.5 + 0.5;
	float band = smoothstep(0.32, 0.42, x) * 0.55 + smoothstep(0.58, 0.68, x) * 0.45;
	float soft = smoothstep(0.22, 0.75, x);
	bool icy = kind == IK_ICE || kind == IK_FROST;
	float wrap_k = kind == IK_SNOW ? 0.7 : (icy ? 0.55 : 0.35);
	float ramp = mix(band, soft, wrap_k);
	vec3 lc = light_col * atten / PI;
	vec3 hue = ip_hue(albedo);
	// Cool fill on the turned-away side (snow scatters blue), only where the light could reach.
	float fill_k = kind == IK_SNOW ? 0.30 : 0.16;
	vec3 fill = ip_shade_tint * fill_k * (1.0 - ramp) * smoothstep(0.05, 0.40, x);
	diffuse += lc * (ramp + fill);
	float ndv = clamp(dot(nrm, v), 0.0, 1.0);
	float lit = smoothstep(0.0, 0.3, ndl);
	vec3 h = normalize(l + v);
	float ndh = max(dot(nrm, h), 0.0);
	if (icy) {
		// Light through the ice: the shadow side keeps a tinted glow, and a crystal between the eye and the sun lights up.
		float back = pow(clamp(dot(v, -l), 0.0, 1.0), 4.0);
		diffuse += lc * hue * ((1.0 - ramp) * 0.16 + back * 0.45);
		float s = pow(ndh, 140.0) * 1.2 + pow(ndh, 18.0) * 0.12;   // sharp, but under the bloom (Art Lab R5)
		specular += lc * s * max(spec, 0.3) * 1.6 * lit;
	} else if (kind == IK_METAL) {
		vec3 tint = mix(vec3(1.0), hue, 0.45);
		float s = pow(ndh, 90.0) * 1.3 + pow(ndh, 12.0) * 0.2;
		specular += lc * tint * s * max(spec, 0.2) * 2.0 * lit;
	} else {
		if (spec > 0.0) {
			specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec * lc;
		}
	}
	if (glint > 0.0) {
		// Sparkles: a tight lobe so each glint winks as the camera or the sun moves.
		specular += lc * glint * pow(ndh, 24.0) * 2.4 * lit;
	}
	// Light-side rim: a crisp catch light along the silhouette facing the sun.
	specular += lc * pow(1.0 - ndv, 4.0) * smoothstep(0.0, 0.5, ndl) * ip_light_rim * mix(vec3(1.0), hue, 0.4);
}
