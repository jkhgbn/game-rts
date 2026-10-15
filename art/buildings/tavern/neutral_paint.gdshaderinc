// neutral_paint.gdshaderinc - G-B "painted PBR" layer for the neutral and shared buildings (docs/art/gb_neutral_buildings.md):
// taverns, trading posts, watchtower / essence well / wayshrine, Magpie Den, Greywater Lodge and the Stables' shared
// shader. Same idea as the units' G3b layer (art/units/kit/unit_paint.gdshaderinc), tuned for the materials of an old
// roadside world seen from the RTS camera: weathered stone, timber, thatch, plaster, iron, canvas, shingles, hides.
//   * light (every tier): a softer wrapped ramp (60 % smooth / 40 % the old 2-band paint, same energy at the
//     terminator), a cool fill on the turned-away side, a warm terminator, a light-side rim catch along the sunlit
//     silhouette, per-surface speculars (iron = sharp + broad tinted Blinn, wood / tiles = soft sheen, canvas / straw /
//     fur = velvet grazing sheen, stone = a faint broad sheen).
//   * albedo (Medium+): tops catch the sky, undersides take a tinted crease AO, rain streaks run down walls, earth
//     splashes up the foot of every wall, iron gets a small fake sky / horizon reflection.
//   * fine detail (High / Ultra): chisel pits on stone, wood fibres, straw strands, trowel marks on plaster, canvas weave,
//     fur strands; they also bend the shading normal (derivative bump) and fade out once a pixel is wider than half
//     their period (no shimmer at RTS zoom; an RTS-zoom pixel never pays for them).
// Cost tier `gb_detail` (material uniform, written by NeutralBuildingLook from GameSettings.effective_graphics_quality()):
//   0 Low = light pass only (a few ALU over the old toon ramp, no texture sample), 1 Medium = + albedo layer (one extra
//   noise sample for the streaks), 2 High / 3 Ultra = + fine detail and bump. Default 2 (a tool preview looks right).
// The including shader declares `noise_tex`, computes its albedo as before, then:
//   albedo = np_albedo(albedo, kind, gb_detail, lp, ln, n, h, px, world_pos, CAMERA_POSITION_WORLD, noise_tex, bh, em);
//   if (gb_detail > 1.5) { NORMAL = np_bump(NORMAL, VERTEX, bh); }   (uniform branch: derivatives stay defined)
//   v_np = vec3(spec, float(kind), gb_detail);  and in light(): np_light(NORMAL, LIGHT, VIEW, ..., v_np, ...).

uniform float gb_detail = 0.0;   // NeutralBuildingLook.set_detail writes the tier (shader lint A)
uniform vec3 np_shade_tint : source_color = vec3(0.52, 0.58, 0.86);
uniform vec3 np_crease_tint : source_color = vec3(0.66, 0.60, 0.64);
uniform float np_light_rim : hint_range(0.0, 1.0) = 0.22;
uniform float np_streaks : hint_range(0.0, 2.0) = 1.0;

const int NK_PLAIN = 0;
const int NK_STONE = 1;
const int NK_WOOD = 2;
const int NK_STRAW = 3;     // thatch, hay, rope
const int NK_PLASTER = 4;   // plaster, whitewash, daub
const int NK_METAL = 5;     // iron, bronze, gold leaf
const int NK_CLOTH = 6;     // canvas, banners, awnings
const int NK_TILE = 7;      // shingles, clay tiles
const int NK_FUR = 8;       // hides, pelts

varying vec3 v_np;   // x spec, y kind (-1 = self-lit, no light), z detail (fragment -> light)

float np_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// 1 while a pattern of `period` metres is wider than ~2 pixels, 0 once it would shimmer.
float np_fade(float period, float px) {
	return 1.0 - smoothstep(period * 0.22, period * 0.55, px);
}

vec3 np_srgb(vec3 linear_c) {
	return pow(max(linear_c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 np_hue(vec3 c) {
	return c / max(max(c.r, max(c.g, c.b)), 0.03);
}

// Plane coordinates in metres: walls -> (along the wall, up), tops -> (x, z).
vec2 np_plane(vec3 lp, vec3 ln) {
	vec3 a = abs(ln);
	if (a.y > 0.8) {
		return lp.xz;
	}
	vec2 hz = normalize(ln.xz + vec2(0.0001, 0.0));
	return vec2(dot(lp.xz, vec2(-hz.y, hz.x)), lp.y);
}

// Surface kind from a part's SRGB colour (a linear colour: pass np_srgb(c)) and spec, for shaders whose parts carry no
// kind of their own. Iron by spec; browns = wood; light warm yellows = straw; pale low-saturation = plaster; the rest
// stone.
int np_kind_of(vec3 c, float spec) {
	if (spec >= 0.2) {
		return NK_METAL;
	}
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	bool warm = c.r >= c.g && c.g >= c.b;
	if (warm && sat > 0.38 && mx > 0.05) {
		float hue = (c.g - c.b) / max(mx - mn, 0.001);   // 0 red .. 1 yellow
		if (hue > 0.55 && mx > 0.42) {
			return NK_STRAW;
		}
		return NK_WOOD;
	}
	if (sat < 0.3 && mx > 0.55) {
		return NK_PLASTER;
	}
	return NK_STONE;
}

// Albedo pass. lp / ln: model-space point / normal (patterns stay on the building); n: world normal; h: height above
// the building's foot (m); px: world size of one pixel. Writes the bump height and the emission the iron reflection adds.
vec3 np_albedo(vec3 albedo, int kind, float detail, vec3 lp, vec3 ln, vec3 n, float h, float px, vec3 world_pos,
		vec3 cam_pos, sampler2D ntex, out float bump_h, out vec3 emit) {
	bump_h = 0.0;
	emit = vec3(0.0);
	if (detail < 0.5) {
		return albedo;
	}
	float side = 1.0 - abs(n.y);
	vec2 uv = np_plane(lp, ln);
	// Tops catch the sky (roofs, ledges, barrel lids read from the RTS camera); undersides take a tinted crease AO.
	albedo *= 1.0 + 0.06 * smoothstep(0.35, 0.95, n.y);
	albedo *= mix(vec3(1.0), np_crease_tint, smoothstep(0.15, -0.75, n.y) * 0.32);
	// Earth splashed up the foot of every wall (warm, uneven), not on iron / canvas.
	if (kind != NK_METAL && kind != NK_CLOTH) {
		float foot = (1.0 - smoothstep(0.05, 0.75, h)) * side;
		albedo = mix(albedo, albedo * vec3(0.80, 0.70, 0.56), foot * 0.42);
	}
	// Rain streaks down walls: noise stretched vertically, darker and a touch cooler (stone, plaster, wood, tiles).
	if ((kind == NK_STONE || kind == NK_PLASTER || kind == NK_WOOD || kind == NK_PLAIN) && side > 0.5) {
		float s = textureLod(ntex, vec2(uv.x * 1.7, uv.y * 0.09 + 0.31), 0.0).r;
		float streak = smoothstep(0.55, 0.85, s) * smoothstep(0.5, 0.9, side) * np_streaks;
		albedo *= mix(vec3(1.0), vec3(0.80, 0.82, 0.86), streak * (kind == NK_PLASTER ? 0.55 : 0.35));
	}
	bool fine = detail > 1.5;
	if (kind == NK_METAL) {
		// Darker diffuse (iron reads by its reflection) + a small fake sky / horizon / ground environment.
		albedo *= 0.86;
		vec3 v = normalize(cam_pos - world_pos);
		vec3 r = reflect(-v, n);
		vec3 env = mix(vec3(0.15, 0.12, 0.10), vec3(0.56, 0.66, 0.84), smoothstep(-0.15, 0.35, r.y));
		env += vec3(1.0, 0.92, 0.78) * exp(-abs(r.y - 0.06) * 12.0) * 0.5;
		emit = env * np_hue(albedo) * albedo * 0.8;
		float f = fine ? np_fade(0.03, px) : 0.0;
		if (f > 0.001) {
			float s = textureLod(ntex, uv * vec2(3.0, 18.0), 0.0).r;
			albedo *= 1.0 + (s - 0.5) * 0.16 * f;
			bump_h = (s - 0.5) * 0.0012 * f;
		}
	} else if (kind == NK_STONE) {
		// Lichen-warm / cool weathering at the scale of a few blocks, then chisel pits close up.
		float w = textureLod(ntex, uv * 0.21 + vec2(0.13, 0.57), 0.0).r;
		albedo *= mix(vec3(0.95, 0.97, 1.03), vec3(1.05, 1.01, 0.94), w);
		float f = fine ? np_fade(0.07, px) : 0.0;
		if (f > 0.001) {
			float p = textureLod(ntex, uv * 4.3 + vec2(0.71, 0.29), 0.0).r;
			float pit = smoothstep(0.62, 0.82, p);
			albedo *= 1.0 - pit * 0.14 * f + (p - 0.5) * 0.08 * f;
			bump_h = (p - 0.5) * 0.004 * f - pit * 0.002 * f;
		}
	} else if (kind == NK_WOOD) {
		// Grain along the member (vertical on posts / boards, along the wall on beams: both via the plane coords),
		// weathered grey on sky-facing tops.
		albedo = mix(albedo, vec3(dot(albedo, vec3(0.33))) * 1.08, smoothstep(0.6, 0.95, n.y) * 0.22);
		float g = sin((uv.x + uv.y) * 31.0 + textureLod(ntex, uv * 0.6, 0.0).r * 9.0);
		float f = np_fade(0.2, px);
		albedo *= 1.0 + g * 0.07 * f;
		float ff = fine ? np_fade(0.04, px) : 0.0;
		if (ff > 0.001) {
			float fib = textureLod(ntex, vec2(uv.x * 2.0, uv.y * 24.0) + vec2(uv.y * 0.5, 0.0), 0.0).r;
			albedo *= 1.0 + (fib - 0.5) * 0.18 * ff;
			bump_h = (fib - 0.5) * 0.002 * ff + g * 0.0008 * f;
		}
	} else if (kind == NK_STRAW) {
		// Sun-bleached tops, damp darker under the eaves; strands down the slope close up.
		albedo *= mix(0.84, 1.0, smoothstep(0.2, 0.9, n.y));
		float ff = fine ? np_fade(0.035, px) : 0.0;
		if (ff > 0.001) {
			float st = textureLod(ntex, vec2(uv.x * 22.0, uv.y * 1.6), 0.0).r;
			albedo *= 1.0 + (st - 0.5) * 0.30 * ff;
			bump_h = (st - 0.5) * 0.003 * ff;
		}
	} else if (kind == NK_PLASTER) {
		// Soft blotches of damp and fresh lime, trowel marks close up.
		float b = textureLod(ntex, uv * 0.45 + vec2(0.4, 0.1), 0.0).r;
		albedo *= 0.94 + b * 0.10;
		float ff = fine ? np_fade(0.12, px) : 0.0;
		if (ff > 0.001) {
			float t = textureLod(ntex, uv * vec2(2.6, 1.3) + vec2(0.2, 0.8), 0.0).r;
			albedo *= 1.0 + (t - 0.5) * 0.08 * ff;
			bump_h = (t - 0.5) * 0.003 * ff;
		}
	} else if (kind == NK_CLOTH) {
		// Dye pools in soft vertical folds (darker, more saturated), ridges paler; weave close up.
		float fold = sin(uv.x * 5.5 + textureLod(ntex, uv * 0.5, 0.0).r * 4.0) * 0.5 + 0.5;
		albedo = mix(albedo, pow(albedo, vec3(1.4)) * 0.92, (1.0 - fold) * side * 0.4);
		float ff = fine ? np_fade(0.02, px) : 0.0;
		if (ff > 0.001) {
			vec2 wv = uv * (6.2831853 / 0.02);
			float w = sin(wv.x + wv.y * 0.5) * sin(wv.y - wv.x * 0.3);
			albedo *= 1.0 + w * 0.04 * ff;
			bump_h = w * 0.0005 * ff;
		}
	} else if (kind == NK_TILE) {
		float ff = fine ? np_fade(0.05, px) : 0.0;
		if (ff > 0.001) {
			float gr = textureLod(ntex, uv * 6.0 + vec2(0.33, 0.66), 0.0).r;
			albedo *= 1.0 + (gr - 0.5) * 0.14 * ff;
			bump_h = (gr - 0.5) * 0.002 * ff;
		}
	} else if (kind == NK_FUR) {
		float ff = fine ? np_fade(0.03, px) : 0.0;
		if (ff > 0.001) {
			float t = textureLod(ntex, vec2(uv.x * 14.0, uv.y * 1.4), 0.0).r;
			albedo *= 1.0 + (t - 0.5) * 0.32 * ff;
			bump_h = (t - 0.5) * 0.002 * ff;
		}
	}
	return albedo;
}

// Derivative bump (Mikkelsen 2010): bends the view-space normal by the screen-space gradient of the height `h`.
vec3 np_bump(vec3 nrm, vec3 vtx, float h) {
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

// The light pass. m: x spec strength, y kind, z detail tier (v_np).
void np_light(vec3 nrm, vec3 l, vec3 v, vec3 light_col, float atten, vec3 albedo, vec3 m,
		inout vec3 diffuse, inout vec3 specular) {
	if (m.y < -0.5) {
		return;   // self-lit part (glow entries): no light at all, as before
	}
	float ndl = dot(nrm, l);
	float x = ndl * 0.5 + 0.5;
	float band = smoothstep(0.32, 0.42, x) * 0.55 + smoothstep(0.58, 0.68, x) * 0.45;
	float soft = smoothstep(0.22, 0.75, x);
	float ramp = mix(band, soft, 0.6);
	vec3 lc = light_col * atten / PI;
	int kind = int(m.y + 0.5);
	vec3 hue = np_hue(albedo);
	// Cool fill on the turned-away side (only where the light could reach: cast shadows stay the ambient's).
	vec3 fill = np_shade_tint * 0.12 * (1.0 - ramp) * smoothstep(0.05, 0.40, x);
	// Warm saturated terminator (canvas / straw / fur scatter most).
	float term = smoothstep(0.30, 0.48, x) * (1.0 - smoothstep(0.48, 0.70, x));
	float sss = (kind == NK_CLOTH || kind == NK_FUR) ? 0.28 : (kind == NK_STRAW ? 0.2 : 0.1);
	diffuse += lc * (ramp + fill + term * sss * hue);
	float ndv = clamp(dot(nrm, v), 0.0, 1.0);
	float lit = smoothstep(0.0, 0.3, ndl);
	vec3 hv = normalize(l + v);
	float ndh = max(dot(nrm, hv), 0.0);
	float spec = m.x;
	if (kind == NK_METAL) {
		vec3 tint = mix(vec3(1.0), hue, 0.55);
		float s = pow(ndh, 80.0) * 1.3 + pow(ndh, 12.0) * 0.2;
		specular += lc * tint * s * max(spec, 0.2) * 2.0 * lit;
	} else {
		if (spec > 0.0) {
			specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec * lc;
		}
		float soft_s = (kind == NK_WOOD || kind == NK_TILE) ? 0.05 : (kind == NK_STONE ? 0.025 : 0.0);
		if (soft_s > 0.0) {
			specular += lc * pow(ndh, kind == NK_STONE ? 8.0 : 16.0) * soft_s * lit;
		}
		if (kind == NK_CLOTH || kind == NK_FUR || kind == NK_STRAW) {
			// Velvet sheen: grazing angles light up in the material's own colour.
			diffuse += lc * pow(1.0 - ndv, 3.0) * lit * (kind == NK_STRAW ? 0.12 : 0.32) * (hue * 0.6 + 0.4);
		}
	}
	// Light-side rim: a crisp catch light along the silhouette facing the sun (reads at RTS zoom).
	specular += lc * pow(1.0 - ndv, 4.0) * smoothstep(0.0, 0.5, ndl) * np_light_rim * mix(vec3(1.0), hue, 0.4);
}
