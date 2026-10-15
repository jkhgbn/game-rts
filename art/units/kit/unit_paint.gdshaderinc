// unit_paint.gdshaderinc - the G3b "painted PBR" layer shared by every kit unit shader (unit_painted.gdshader,
// champions/champion_palette.gdshader). docs/art/g3b_materials.md.
//
// What it adds over the old flat toon ramp (all procedural, no texture besides the paint noise already bound):
//   * light: a softer wrapped ramp (60 % smooth / 40 % the old 2-band paint), a cool hue-shifted fill on the shadow side,
//     a warm saturated terminator (dye / skin scatter), a crisp light-side rim, per-surface specular:
//     metal = sharp + broad tinted Blinn, leather / skin / wood = soft sheen, cloth / fur = velvet sheen.
//   * albedo: tops catch the sky, undersides take a tinted crease AO, cloth folds where the dye pools (team colour reads
//     dyed, not painted on), metal brushing, leather grain, wood grain, fur strands, bone pits; metal gets a small fake
//     sky / horizon / ground reflection.
//   * fine detail (weave, grain, brushing, strands) also bends the shading normal (derivative bump), fades out once a
//     pixel is wider than half its period (no shimmer at RTS zoom), and only runs at kit_detail >= 1.5.
// Cost tiers (instance uniform kit_detail, slot 12, written by CharacterModel from GameSettings.effective_graphics_quality):
//   0 = Low (new light ramp only, the rest skipped), 1 = Medium (+ folds, sky catch, crease tint, metal reflection),
//   2 = High / Ultra (+ fine detail and bump). Default 2 so a model the kit does not drive still looks right.
//
// Uniforms (per material; every default lifts an untouched palette material):
//   surface_kind    int    -1 auto (spec_strength >= 0.15 -> metal, else plain), 0 plain, 1 cloth, 2 metal, 3 leather,
//                          4 skin, 5 wood, 6 fur / hair / hide, 7 bone / horn / stone
//   detail_strength float  scales every procedural pattern (0 = off)
//   sheen_strength  float  scales the per-kind sheen / soft specular
//   shade_tint      vec3   colour of the shadow-side fill
//   crease_tint     vec3   multiplier colour of undersides / creases
//   env_strength    float  metal fake reflection
//   light_rim       float  light-side rim (outline catch light)

uniform int surface_kind = -1;
uniform float detail_strength : hint_range(0.0, 2.0) = 1.0;
uniform float sheen_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec3 shade_tint : source_color = vec3(0.52, 0.58, 0.86);
uniform vec3 crease_tint : source_color = vec3(0.62, 0.56, 0.70);
uniform float env_strength : hint_range(0.0, 2.0) = 1.0;
uniform float light_rim : hint_range(0.0, 1.0) = 0.32;

const int UK_PLAIN = 0;
const int UK_CLOTH = 1;
const int UK_METAL = 2;
const int UK_LEATHER = 3;
const int UK_SKIN = 4;
const int UK_WOOD = 5;
const int UK_FUR = 6;
const int UK_BONE = 7;

int up_kind(float spec) {
	if (surface_kind >= 0) {
		return surface_kind;
	}
	return spec >= 0.15 ? UK_METAL : UK_PLAIN;
}

// 1 while a pattern of `period` metres is still wider than ~2 pixels, 0 once it would shimmer.
float up_fade(float period, float px) {
	return 1.0 - smoothstep(period * 0.22, period * 0.55, px);
}

// The normalised hue of a colour (max channel = 1): tints speculars and the terminator without changing energy much.
vec3 up_hue(vec3 c) {
	return c / max(max(c.r, max(c.g, c.b)), 0.03);
}

// 2D coordinates of the local position on the plane facing the local normal (cheap "triplanar pick").
vec2 up_plane(vec3 lp, vec3 ln) {
	vec3 a = abs(ln);
	if (a.x > a.y && a.x > a.z) {
		return lp.zy;
	}
	if (a.z > a.y) {
		return lp.xy;
	}
	return lp.xz;
}

// Albedo pass. lp / ln: model-space position / normal of the pivot mesh (moves with the limb: no swimming);
// n: world normal; na / nb: the paint noise already sampled; px: world size of one pixel. Returns the new albedo,
// writes the bump height (0 = none) and the emission the metal reflection adds. The fine layers branch per pixel on
// their fade (0 beyond ~8 m: an RTS-zoom pixel never pays for them) and sample with textureLod (no implicit derivative
// inside the branch).
vec3 up_albedo(vec3 albedo, int kind, float detail, vec3 lp, vec3 ln, vec3 n, float na, float nb, float px,
		vec3 world_pos, vec3 cam_pos, sampler2D ntex, out float bump_h, out vec3 env_emit) {
	bump_h = 0.0;
	env_emit = vec3(0.0);
	if (detail < 0.5) {
		return albedo;
	}
	float ds = detail_strength;
	// Tops catch the sky (separates helmets / shoulders / hoods from the RTS camera), undersides take a tinted AO.
	albedo *= 1.0 + 0.15 * ds * smoothstep(0.35, 0.95, n.y);
	float under = smoothstep(0.15, -0.75, n.y) * 0.32 * ds;
	albedo *= mix(vec3(1.0), crease_tint, under);
	float side = 1.0 - abs(n.y);
	bool fine = detail > 1.5;
	if (kind == UK_CLOTH) {
		// Folds: soft vertical valleys around the pivot, broken by the paint noise. Dye pools in the valleys (darker
		// and more saturated), the ridges wear a touch paler: the team colour reads woven-in.
		float fold = sin(atan(lp.x, lp.z) * 9.0 + lp.y * 2.4 + na * 4.0) * 0.5 + 0.5;
		float valley = (1.0 - fold) * side * 0.55 * ds;
		albedo = mix(albedo, pow(albedo, vec3(1.45)) * 0.92, valley);
		float lum = dot(albedo, vec3(0.299, 0.587, 0.114));
		albedo = mix(albedo, vec3(lum) * 1.1 + albedo * 0.25, fold * side * 0.10 * ds);
		float f = fine ? up_fade(0.018, px) * ds : 0.0;
		if (f > 0.001) {
			// Twill-like threads, broken up by the paint noise so no regular grid shows.
			vec2 uv = up_plane(lp, ln) * (6.2831853 / 0.018);
			float w = sin(uv.x + uv.y * 0.5) * sin(uv.y - uv.x * 0.3) * (0.4 + 0.6 * na);
			albedo *= 1.0 + w * 0.035 * f;
			bump_h = w * 0.0005 * f;
		}
	} else if (kind == UK_METAL) {
		// Darker diffuse (metal reads by its reflection), brushed streaks along the limb, a small fake environment.
		albedo *= 0.86;
		vec3 v = normalize(cam_pos - world_pos);
		vec3 r = reflect(-v, n);
		vec3 env = mix(vec3(0.16, 0.13, 0.10), vec3(0.58, 0.68, 0.86), smoothstep(-0.15, 0.35, r.y));
		env += vec3(1.0, 0.92, 0.78) * exp(-abs(r.y - 0.06) * 12.0) * 0.55;
		env_emit = env * up_hue(albedo) * albedo * 0.9 * env_strength * ds;
		float f = fine ? up_fade(0.025, px) * ds : 0.0;
		if (f > 0.001) {
			float s = textureLod(ntex, vec2(dot(lp.xz, vec2(23.0, 19.0)), lp.y * 0.9), 0.0).r;
			albedo *= 1.0 + (s - 0.5) * 0.14 * f;
			bump_h = (s - 0.5) * 0.0012 * f;
		}
	} else if (kind == UK_LEATHER) {
		// Scuffed lighter patches, fine pebble grain.
		albedo = mix(albedo, albedo * 1.28, smoothstep(0.62, 0.82, na) * 0.35 * ds);
		float f = fine ? up_fade(0.05, px) * ds : 0.0;
		if (f > 0.001) {
			float g = textureLod(ntex, up_plane(lp, ln) * 9.0, 0.0).r;
			albedo *= 1.0 + (g - 0.5) * 0.24 * f;
			bump_h = (g - 0.5) * 0.0025 * f;
		}
	} else if (kind == UK_WOOD) {
		float grain = sin((lp.x + lp.z) * 38.0 + na * 7.0 + lp.y * 1.5);
		float f = up_fade(0.16, px) * ds;
		albedo *= 1.0 + grain * 0.10 * f;
		bump_h = grain * 0.0015 * f * (fine ? 1.0 : 0.0);
	} else if (kind == UK_FUR) {
		// Strands: noise stretched along the limb, tips lighter.
		albedo *= 1.0 + 0.08 * ds * smoothstep(0.55, 0.8, nb);
		float f = fine ? up_fade(0.03, px) * ds : 0.0;
		if (f > 0.001) {
			float t = textureLod(ntex, vec2(dot(lp.xz, vec2(14.0, 11.0)), lp.y * 1.4), 0.0).r;
			albedo *= 1.0 + (t - 0.5) * 0.32 * f;
			bump_h = (t - 0.5) * 0.002 * f;
		}
	} else if (kind == UK_BONE) {
		float f = fine ? up_fade(0.06, px) * ds : 0.0;
		if (f > 0.001) {
			float p = textureLod(ntex, up_plane(lp, ln) * 5.0 + vec2(0.37, 0.71), 0.0).r;
			float pit = smoothstep(0.68, 0.85, p);
			albedo *= 1.0 - pit * 0.16 * f;
			bump_h = -pit * 0.002 * f;
		}
	} else if (kind == UK_SKIN) {
		// A little warm blood in the side planes (cheeks, hands), no texture.
		albedo = mix(albedo, albedo * vec3(1.06, 0.95, 0.92), side * 0.35 * ds);
	}
	return albedo;
}

// Derivative bump (Mikkelsen 2010): bends the view-space normal by the screen-space gradient of the height `h`.
vec3 up_bump(vec3 nrm, vec3 vtx, float h) {
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

// The light pass shared by the kit shaders. m: x spec_strength, y kind, z detail tier.
void up_light(vec3 nrm, vec3 l, vec3 v, vec3 light_col, float atten, vec3 albedo, vec3 m,
		inout vec3 diffuse, inout vec3 specular) {
	float ndl = dot(nrm, l);
	float x = ndl * 0.5 + 0.5;
	float band = smoothstep(0.32, 0.42, x) * 0.55 + smoothstep(0.58, 0.68, x) * 0.45;
	float soft = smoothstep(0.22, 0.75, x);
	float ramp = mix(band, soft, 0.6);
	vec3 lc = light_col * atten / PI;
	int kind = int(m.y + 0.5);
	vec3 hue = up_hue(albedo);
	// Cool fill on the turned-away side (only where the light could reach: cast shadows stay the ambient's).
	vec3 fill = shade_tint * 0.16 * (1.0 - ramp) * smoothstep(0.05, 0.40, x);
	// Warm saturated terminator: cloth / fur / skin scatter, the rest a touch.
	float term = smoothstep(0.30, 0.48, x) * (1.0 - smoothstep(0.48, 0.70, x));
	float sss = kind == UK_SKIN ? 0.50 : ((kind == UK_CLOTH || kind == UK_FUR) ? 0.28 : 0.12);
	diffuse += lc * (ramp + fill + term * sss * hue);
	float ndv = clamp(dot(nrm, v), 0.0, 1.0);
	float lit = smoothstep(0.0, 0.3, ndl);
	vec3 h = normalize(l + v);
	float ndh = max(dot(nrm, h), 0.0);
	float spec = m.x;
	if (kind == UK_METAL) {
		vec3 tint = mix(vec3(1.0), hue, 0.55);
		float s = pow(ndh, 90.0) * 1.4 + pow(ndh, 12.0) * 0.22;
		specular += lc * tint * s * max(spec, 0.2) * 2.2 * lit * sheen_strength;
	} else {
		if (spec > 0.0) {
			specular += pow(max(dot(reflect(-l, nrm), v), 0.0), 24.0) * spec * lc;
		}
		float soft_s = kind == UK_LEATHER ? 0.11 : (kind == UK_SKIN ? 0.06 : (kind == UK_WOOD || kind == UK_BONE ? 0.05 : 0.0));
		if (soft_s > 0.0) {
			float p = kind == UK_LEATHER ? 28.0 : 16.0;
			specular += lc * pow(ndh, p) * soft_s * lit * sheen_strength;
		}
		if (kind == UK_CLOTH || kind == UK_FUR) {
			// Velvet sheen: grazing angles light up in the cloth's own colour (into diffuse: x albedo).
			diffuse += lc * pow(1.0 - ndv, 3.0) * lit * 0.35 * sheen_strength * (hue * 0.6 + 0.4);
		}
	}
	// Light-side rim: a crisp catch light along the silhouette facing the sun (reads at RTS zoom).
	specular += lc * pow(1.0 - ndv, 4.0) * smoothstep(0.0, 0.5, ndl) * light_rim * mix(vec3(1.0), hue, 0.4);
}
