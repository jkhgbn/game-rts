// fire_paint.gdshaderinc - G-B "painted PBR" layer for the Fire kingdom's buildings (docs/art/gb_fire_buildings.md).
// Shared by fire_painted_vc.gdshader (Hall, Hearth, Ember Spire, Bazaar, Dragon Roost, Ember Crucible) and the
// Fire Keep's fire_keep_painted.gdshader. Same idea as the units' G3b layer (art/units/kit/unit_paint.gdshaderinc),
// tuned for stone, bronze, timber and clay tiles seen from the RTS camera:
//   * light: a softer wrapped ramp (60 % smooth / 40 % the old 2-band paint, same energy at the terminator), a cool
//     fill on the turned-away side, a warm terminator, a light-side rim catch on the silhouette, per-surface speculars
//     (bronze = sharp + broad tinted Blinn, obsidian / water = glassy, tiles / lacquer = a soft sheen).
//   * albedo: tops catch the sky, undersides take a warm-brown crease, soot climbs the walls from the ground and
//     from vents, bronze gets a fake sky / horizon reflection and green patina in its crevices, an ember bounce
//     warms the foot of every wall (the scorched ground glows back), stone shows ashlar courses / flagstones, roofs
//     clay tile rows, timber grain and plank joints.
//   * fine detail (chisel marks, tile grain, wood fibres) also bends the normal (derivative bump) and fades out once a
//     pixel is wider than half its period (no shimmer at RTS zoom).
// Cost tier `gb_detail` (material uniform, written from GameSettings.effective_graphics_quality() by each model):
//   0 Low  = light ramp + the big patterns (blocks, tiles, planks: a few ALU, no extra texture sample)
//   1 Medium = + sky catch, crease, soot, patina, bronze reflection, ember bounce, joint seep glow
//   2 High / 3 Ultra = + fine detail and bump (only pixels closer than ~10 m pay for it)

uniform float gb_detail = 0.0;   // FireBuildingLook.apply / set_detail write the tier (shader lint A)
uniform vec3 fp_shade_tint : source_color = vec3(0.50, 0.56, 0.84);
uniform vec3 fp_crease_tint : source_color = vec3(0.70, 0.58, 0.52);
uniform vec3 fp_bounce_color : source_color = vec3(1.0, 0.42, 0.14);
uniform float fp_bounce = 0.11;
uniform float fp_light_rim = 0.30;
uniform float fp_soot = 1.0;

const int FK_STONE = 0;
const int FK_DARK = 1;      // dark basalt / obsidian (glossy when spec > 0)
const int FK_METAL = 2;     // bronze / iron
const int FK_TEAM = 3;      // team-colour clay tiles (slopes) / painted plaster (walls)
const int FK_WOOD = 4;
const int FK_LACQUER = 5;   // red lacquer / dyed trims
const int FK_GLASSY = 6;    // water, polished obsidian
const int FK_CLOTH = 8;     // canvas / awnings (painted spec 0.03-0.08 on a team or light part): no pattern, soft sheen

float fp_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// 1 while a pattern of `period` metres is wider than ~2 pixels, 0 once it would shimmer.
float fp_fade(float period, float px) {
	return 1.0 - smoothstep(period * 0.22, period * 0.55, px);
}

vec3 fp_hue(vec3 c) {
	return c / max(max(c.r, max(c.g, c.b)), 0.03);
}

// Surface kind from a part's colour (sRGB vertex colour), team flag and spec (fire_painted_vc).
int fp_kind_of(vec3 c, bool team, float spec) {
	float mx = max(c.r, max(c.g, c.b));
	if (spec >= 0.03 && spec < 0.08 && (team || mx > 0.5)) {
		return FK_CLOTH;
	}
	if (team) {
		return FK_TEAM;
	}
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	if (spec >= 0.3) {
		return mx < 0.26 ? FK_GLASSY : FK_METAL;
	}
	if (spec >= 0.15) {
		return FK_DARK;
	}
	if (c.r >= mx - 0.0001 && sat > 0.38) {
		float hue = (c.g - c.b) / max(mx - mn, 0.001) * 60.0;
		if (hue < 13.0 && sat > 0.6) {
			return FK_LACQUER;
		}
		if (hue < 48.0 && mx < 0.7) {
			return FK_WOOD;
		}
	}
	return mx < 0.17 ? FK_DARK : FK_STONE;
}

// Staggered blocks on a plane. x = joint mask (faded out below a pixel), y = block id, z = height in the block 0..1,
// w = across 0..1.
vec4 fp_blocks(vec2 uv, vec2 size, float joint, float px) {
	float row = floor(uv.y / size.y);
	float shift = fp_hash(vec2(row, 7.0)) * 0.5 + 0.25;
	float cx = uv.x / size.x + row * shift;
	vec2 cell = vec2(floor(cx), row);
	vec2 f = vec2(fract(cx) * size.x, fract(uv.y / size.y) * size.y);
	float e = min(min(f.x, size.x - f.x), min(f.y, size.y - f.y));
	float aa = px * 0.75 + 0.0001;
	float j = 1.0 - smoothstep(joint * 0.5 - aa, joint * 0.5 + aa, e);
	float fade = clamp(joint / (aa * 2.5), 0.0, 1.0);
	return vec4(j * fade, fp_hash(cell), f.y / size.y, f.x / size.x);
}

// Plane coordinates in metres for a model-space point: walls -> (along the wall, up), tops -> (x, z).
// slope: 1 on sloped faces (roofs): v runs down the slope in metres.
vec2 fp_plane(vec3 lp, vec3 ln, out float flat_top) {
	vec3 a = abs(ln);
	flat_top = 0.0;
	if (a.y > 0.96) {
		flat_top = 1.0;
		return lp.xz;
	}
	vec2 hz = normalize(ln.xz + vec2(0.0001, 0.0));
	float along = dot(lp.xz, vec2(-hz.y, hz.x));
	float up = lp.y / max(length(ln.xz), 0.25);
	return vec2(along, up);
}

// Flat (per-facet) model-space normal: patterns follow the real faces even where the mesh normals are smoothed
// (CylinderMesh pyramids / shafts), so tile rows and courses do not swirl. ln = the interpolated one (sign).
vec3 fp_flat_normal(vec3 lp, vec3 ln) {
	vec3 f = cross(dFdx(lp), dFdy(lp));
	float l = length(f);
	if (l < 1e-12) {
		return ln;
	}
	f /= l;
	return dot(f, ln) < 0.0 ? -f : f;
}

// Albedo pass. kind: FK_*; detail: gb_detail; lp / ln: model-space point / normal (patterns stay on the part);
// n: world normal; h: height above the building's foot; hrel: h / building height; na / nb: paint noise already
// sampled; px: world size of one pixel; dmg: damage 0..1. Writes the bump height and the emission it adds.
vec3 fp_albedo(vec3 albedo, int kind, float detail, vec3 lp, vec3 ln, vec3 n, float h, float hrel, float na,
		float nb, float px, vec3 world_pos, vec3 cam_pos, sampler2D ntex, float dmg, vec3 glow_col,
		out float bump_h, out vec3 emit) {
	bump_h = 0.0;
	emit = vec3(0.0);
	bool fine = detail > 1.5;
	float flat_top;
	vec2 uv = fp_plane(lp, ln, flat_top);
	float slope = (1.0 - flat_top) * smoothstep(0.22, 0.4, ln.y);
	float side = 1.0 - abs(n.y);

	// --- Big patterns (every tier: a few ALU, no texture sample). The keep draws its own (FP_NO_PATTERNS).
#ifndef FP_NO_PATTERNS
	{
		if (kind == FK_STONE || kind == FK_DARK) {
			vec2 bsize = flat_top > 0.5 ? vec2(0.92, 0.66) : (kind == FK_DARK ? vec2(0.95, 0.48) : vec2(0.78, 0.40));
			vec4 b = fp_blocks(uv, bsize, kind == FK_DARK ? 0.05 : 0.06, px);
			float f = fp_fade(bsize.y, px);
			albedo *= 1.0 + (b.y - 0.5) * 0.20 * f;
			// Each block catches the light on its top edge and sinks a little at its foot (hand-cut bevel).
			albedo *= mix(1.0, mix(0.90, 1.07, smoothstep(0.0, 1.0, b.z)), f * (1.0 - flat_top));
			albedo = mix(albedo, albedo * 0.48, b.x * f);
			// Ember seep: deep joints near the foot glow faintly (Medium+), more as the building burns.
			if (detail > 0.5 && kind == FK_DARK) {
				float seep = b.x * f * smoothstep(0.58 - dmg * 0.3, 0.74 - dmg * 0.2, nb) * (1.0 - smoothstep(0.4, 1.6, h));
				emit += glow_col * seep * (0.35 + 0.15 * sin(TIME * 1.6 + b.y * 6.28)) * (1.0 + dmg * 2.0);
			}
		} else if (kind == FK_TEAM && slope > 0.5) {
			// Clay tile rows down the slope: each tile's lower lip catches the light, its top hides under the row above.
			vec4 b = fp_blocks(uv, vec2(0.42, 0.30), 0.035, px);
			float f = fp_fade(0.30, px);
			albedo *= 1.0 + (b.y - 0.5) * 0.24 * f;
			albedo *= mix(1.0, mix(1.10, 0.78, b.z), f);
			albedo = mix(albedo, albedo * 0.55, b.x * f);
			// A few kiln-dark tiles.
			albedo = mix(albedo, albedo * 0.62, step(0.9, b.y) * f);
		} else if (kind == FK_WOOD) {
			// Planks (0.24 m) with dark seams, grain along the length.
			float f = fp_fade(0.24, px);
			float seam = 1.0 - smoothstep(0.0, max(px * 1.5, 0.012), abs(fract(uv.y / 0.24) - 0.5) * 0.24 - 0.105);
			float grain = sin(uv.x * 9.0 + na * 9.0 + uv.y * 3.0) * 0.5 + 0.5;
			albedo *= 1.0 + (grain - 0.5) * 0.16 * f;
			albedo = mix(albedo, albedo * 0.55, seam * f * (1.0 - flat_top));
		}
	}
#endif

	if (detail < 0.5) {
		return albedo;
	}
	// --- Medium: value read and weathering.
	albedo *= 1.0 + 0.13 * smoothstep(0.35, 0.95, n.y);
	albedo *= mix(vec3(1.0), fp_crease_tint, smoothstep(0.1, -0.8, n.y) * 0.35);
	if (kind != FK_TEAM && kind != FK_GLASSY && kind != FK_CLOTH) {
		// Soot climbing from the ground and streaking down from ledges; stronger on damaged buildings.
		float streak = texture(ntex, vec2(uv.x * 0.5, uv.y * 0.12) + vec2(0.31, 0.17)).r;
		float s = smoothstep(0.52, 0.80, streak) * side * (0.14 + 0.18 * (1.0 - smoothstep(0.0, 1.8, h)));
		s += (1.0 - smoothstep(0.0, 0.9, h)) * 0.16;
		albedo *= 1.0 - clamp(s * fp_soot * (1.0 + dmg), 0.0, 0.55);
	}
	if (kind == FK_METAL) {
		// Bronze: darker diffuse, a fake environment reflection, green patina in the crevices / undersides, bright
		// worn upper edges.
		albedo *= 0.82;
		float pat = smoothstep(0.58, 0.82, 1.0 - na) * (0.35 + 0.65 * smoothstep(0.2, -0.6, n.y)) * 0.55;
		albedo = mix(albedo, vec3(0.20, 0.36, 0.30) * 0.75, pat);
		vec3 v = normalize(cam_pos - world_pos);
		vec3 r = reflect(-v, n);
		vec3 env = mix(vec3(0.17, 0.12, 0.08), vec3(0.55, 0.64, 0.80), smoothstep(-0.15, 0.35, r.y));
		env += vec3(1.0, 0.86, 0.66) * exp(-abs(r.y - 0.05) * 10.0) * 0.6;
		emit += env * fp_hue(albedo) * albedo * 0.5 * (1.0 - pat);
	} else if (kind == FK_TEAM) {
		// Ash settles on the upper tiles, the eaves stay saturated.
		float lum = dot(albedo, vec3(0.299, 0.587, 0.114));
		albedo = mix(albedo, vec3(lum) * 0.9, smoothstep(0.62, 0.86, nb) * 0.25 * slope);
	} else if (kind == FK_WOOD) {
		// Charred ends near the ground and the forge.
		albedo *= 1.0 - (1.0 - smoothstep(0.0, 1.2, h)) * 0.25;
	}
	// Ember bounce: the scorched, glowing ground lights the foot of every wall (fades out by ~1.6 m).
	float foot = (1.0 - smoothstep(0.0, 1.6, h)) * smoothstep(-0.2, 0.6, side);
	emit += fp_bounce_color * albedo * foot * fp_bounce * (0.9 + 0.1 * sin(TIME * 2.2 + lp.x));

	// --- High: fine detail + bump (only near pixels). Two mipmapped samples taken in the uniform branch (no
	// aliasing, defined derivatives); each kind fades its pattern out by pixel size.
	if (fine) {
		float fa = texture(ntex, uv * 0.42 + vec2(0.37, 0.71)).r;
		float fs = texture(ntex, vec2(uv.x * 0.3, uv.y * 3.2) + vec2(0.13, 0.59)).r;
		if (kind == FK_STONE || kind == FK_DARK) {
			float f = fp_fade(0.3, px);
			if (f > 0.001) {
				float c = fa;
				albedo *= 1.0 + (c - 0.5) * 0.22 * f;
				bump_h = (c - 0.5) * 0.004 * f;
			}
		} else if (kind == FK_METAL) {
			float f = fp_fade(0.15, px);
			if (f > 0.001) {
				float s = fs;
				albedo *= 1.0 + (s - 0.5) * 0.14 * f;
				bump_h = (s - 0.5) * 0.0012 * f;
			}
		} else if (kind == FK_WOOD) {
			float f = fp_fade(0.03, px);
			if (f > 0.001) {
				float g = sin(uv.x * 70.0 + na * 12.0) * 0.5 + 0.5;
				albedo *= 1.0 + (g - 0.5) * 0.12 * f;
				bump_h = (g - 0.5) * 0.0015 * f;
			}
		} else if (kind == FK_TEAM) {
			float f = fp_fade(0.3, px);
			if (f > 0.001) {
				float g = fa;
				albedo *= 1.0 + (g - 0.5) * 0.16 * f;
				bump_h = (g - 0.5) * 0.002 * f;
			}
		}
	}
	return albedo;
}

// Derivative bump (Mikkelsen 2010) on the view-space normal.
vec3 fp_bump(vec3 nrm, vec3 vtx, float h) {
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

// Light pass. m: x spec_strength, y kind, z detail. Detail 0 keeps the old two-band paint shape but softened.
void fp_light(vec3 nrm, vec3 l, vec3 v, vec3 light_col, float atten, vec3 albedo, vec3 m,
		inout vec3 diffuse, inout vec3 specular) {
	if (m.z < -0.5) {   // legacy (comparison shots): the old painted.gdshader light, line for line
		float d = dot(nrm, l) * 0.5 + 0.5;
		float r = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
		diffuse += r * atten * light_col / PI;
		if (m.x > 0.0) {
			specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * m.x * light_col * atten / PI;
		}
		return;
	}
	float ndl = dot(nrm, l);
	float x = ndl * 0.5 + 0.5;
	float band = smoothstep(0.32, 0.42, x) * 0.55 + smoothstep(0.58, 0.68, x) * 0.45;
	float soft = smoothstep(0.22, 0.75, x);
	float ramp = mix(band, soft, 0.6);
	vec3 lc = light_col * atten / PI;
	int kind = int(m.y + 0.5);
	vec3 hue = fp_hue(albedo);
	vec3 fill = fp_shade_tint * 0.15 * (1.0 - ramp) * smoothstep(0.05, 0.40, x);
	float term = smoothstep(0.30, 0.48, x) * (1.0 - smoothstep(0.48, 0.70, x));
	diffuse += lc * (ramp + fill + term * 0.12 * hue);
	float ndv = clamp(dot(nrm, v), 0.0, 1.0);
	float lit = smoothstep(0.0, 0.3, ndl);
	vec3 hv = normalize(l + v);
	float ndh = max(dot(nrm, hv), 0.0);
	float spec = m.x;
	if (kind == FK_METAL) {
		vec3 tint = mix(vec3(1.0), hue, 0.6);
		float s = pow(ndh, 80.0) * 1.3 + pow(ndh, 10.0) * 0.22;
		specular += lc * tint * s * max(spec, 0.3) * 2.2 * lit;
	} else if (kind == FK_GLASSY) {
		specular += lc * pow(ndh, 120.0) * 2.0 * max(spec, 0.3) * lit;
	} else if (kind == FK_TEAM || kind == FK_LACQUER || kind == FK_CLOTH) {
		specular += lc * hue * pow(ndh, 18.0) * 0.10 * lit;
	} else if (spec > 0.0) {
		specular += lc * pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec;
	}
	// Light-side rim: a crisp catch along the lit silhouette (reads the building's outline against the ground).
	if (m.z > 0.5) {
		float rim = pow(1.0 - ndv, 4.0) * smoothstep(-0.1, 0.4, ndl);
		specular += lc * rim * fp_light_rim * mix(vec3(1.0), hue, 0.4);
	}
}
