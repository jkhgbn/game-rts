shader_type spatial;
// Epic-beast ground marks (MapFillBeastVfx, task 12.V31). PlaneMesh 2 x 2 scaled per node: scale.x = half LENGTH
// (along local +X = the beast's travel direction), scale.z = half WIDTH, both in metres (read here from the model
// matrix, so a stretching mark needs no parameter update). ONE material for every mark, the look is picked per
// instance (`pattern`). Premultiplied alpha: `glow` adds light in `tint`, `cover` darkens (gouges, churned earth) so
// the marks read on grass, dirt and stone alike.
//   0 furrow   Gore Charge path: churned earth band, two tusk gouges, clods (tint = the earth colour, no glow)
//   1 claws    Pounce landing: two paws of three raking claw gouges converging ahead, glowing edges + a binding ring
//   2 shriek   Shrieking Dive: sound-wave rings racing outward, jagged, a violet wash and scream spikes
//   3 cracks   Rending Roar: radial ground cracks with hot edges, churned centre
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(1.0, 0.8, 0.5, 1.0);   // linear HDR, a = strength
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;    // seconds since the mark appeared (sent during its first second)
instance uniform float seed = 0.0;

varying vec2 v_half;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec2 rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void vertex() {
	v_half = vec2(max(length(MODEL_MATRIX[0].xyz), 0.05), max(length(MODEL_MATRIX[2].xyz), 0.05));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec2 m = p * v_half;                     // metres from the centre (x = along travel)
	float glow = 0.0;
	float cover = 0.0;
	vec3 dark = vec3(0.045, 0.032, 0.02);
	int pat = int(pattern + 0.5);
	if (pat == 0) {
		// Furrow: tail at local -X, the charging beast at +X.
		float L = v_half.x * 2.0;
		float W = v_half.y;
		float x = m.x + v_half.x;                // metres from the tail
		float y = m.y;
		float n1 = vnoise(vec2(x * 1.7, seed * 3.1));
		float edge = abs(p.y) + (n1 - 0.5) * 0.42;
		float ends = smoothstep(0.0, min(1.3, L * 0.4), x) * smoothstep(0.0, 0.35, L - x);
		float body = (1.0 - smoothstep(0.52, 0.95, edge)) * ends;
		float mott = vnoise(m * 2.6 + seed * 5.0);
		float gouge = 0.0;
		for (int i = 0; i < 2; i++) {
			float s = i == 0 ? -0.34 : 0.34;
			float wob = (vnoise(vec2(x * 0.9 + float(i) * 7.3, seed)) - 0.5) * 0.2;
			float gw = 0.09 + 0.04 * vnoise(vec2(x * 3.0, float(i) * 3.0 + seed));
			gouge = max(gouge, 1.0 - smoothstep(gw * 0.45, gw, abs(y - s * W - wob)));
		}
		gouge *= smoothstep(0.0, 0.7, x) * smoothstep(0.0, 0.2, L - x);
		// Clods thrown onto the band.
		vec2 cp = vec2(x, y) * 2.6;
		vec2 cell = floor(cp);
		vec2 off = vec2(hash(cell + 3.1 + seed), hash(cell + 7.7 + seed)) - 0.5;
		float clod = (1.0 - smoothstep(0.1, 0.2, length(fract(cp) - 0.5 - off * 0.45)))
				* step(0.62, hash(cell + seed * 1.3)) * (1.0 - smoothstep(0.7, 1.15, edge)) * ends;
		// A lighter lip of pushed-up earth along both edges.
		float lip = exp(-pow((edge - 0.72) * 7.0, 2.0)) * ends;
		cover = body * (0.34 + 0.2 * mott) + gouge * 0.42 + clod * 0.45 + lip * 0.22;
		vec3 earth = tint.rgb * (0.85 + 0.35 * mott);
		dark = mix(earth, earth * 0.4, max(gouge, clod));
		dark = mix(dark, tint.rgb * 1.7, lip * 0.6 * (1.0 - gouge));
	} else if (pat == 1) {
		// Claws: the leap came along +X; two paws rake in toward the victim at the front.
		float h = v_half.x;
		float gouge = 0.0;
		float rim = 0.0;
		for (int s = 0; s < 2; s++) {
			float side = s == 0 ? -1.0 : 1.0;
			vec2 q = rot(m - vec2(-0.05 * h, side * 0.34 * h), side * 0.30);
			for (int k = 0; k < 3; k++) {
				float lane = (float(k) - 1.0) * 0.17 * h;
				float len = 1.05 * h * (k == 1 ? 1.0 : 0.86);
				float t = (q.x + len * 0.5) / len;             // 0 where the claws dig in, 1 the tip
				float curve = (t - 0.5) * (t - 0.5) * 0.3 * h * side;
				float w = 0.075 * h * (1.0 - t * 0.75) * smoothstep(0.0, 0.08, t);
				float inside = step(0.0, t) * step(t, 1.0);
				float dist = abs(q.y - lane - curve);
				gouge = max(gouge, (1.0 - smoothstep(w * 0.5, w, dist)) * inside);
				rim = max(rim, exp(-pow((dist - w) / (0.035 * h + 0.02), 2.0)) * inside * (1.0 - t * 0.5));
			}
		}
		float r = length(m);
		float au = atan(m.y, m.x) / 6.2831853 + 0.5;
		float bind = exp(-pow((r - 0.62 * h) / 0.07, 2.0)) * step(0.38, fract(au * 10.0 + seed));
		float hot = exp(-age * 3.2);
		glow = rim * (0.14 + 1.3 * hot) + gouge * 0.7 * exp(-age * 5.0) + bind * 0.9 * exp(-age * 2.4);
		cover = gouge * 0.88 + rim * 0.1;
		dark = vec3(0.05, 0.036, 0.024);
	} else if (pat == 2) {
		// Shriek: three wave fronts leave the centre each 0.26 s; ragged, brightest young.
		float R = v_half.x;
		float r = length(p);
		if (r > 1.0) {
			discard;
		}
		float au = atan(p.y, p.x) / 6.2831853 + 0.5;
		float d = (1.0 - r) * R;
		for (int i = 0; i < 3; i++) {
			float ph = fract(age * 1.3 + float(i) / 3.0);
			float jag = 0.55 + 0.45 * vnoise(vec2(au * 34.0, float(i) * 5.0 + seed));
			float rr = ph + (vnoise(vec2(au * 12.0, seed + float(i))) - 0.5) * 0.06;
			glow += exp(-pow((r - rr) * R / 0.11, 2.0)) * (1.0 - ph) * smoothstep(0.0, 0.12, ph) * jag * 1.5;
		}
		float rim = exp(-d * d * 22.0) * 0.8;
		float wash = (0.03 + 0.06 * vnoise(p * R * 1.1 + seed)) * (1.0 - smoothstep(0.3, 1.0, r));
		float spike = pow(abs(sin(au * 3.14159 * 9.0 + seed * 2.0)), 14.0)
				* smoothstep(0.12, 0.35, r) * (1.0 - smoothstep(0.6, 0.95, r)) * 0.7;
		glow += rim + wash + spike;
		cover = rim * 0.12 + wash * 0.6;
		dark = vec3(0.05, 0.02, 0.08);
	} else {
		// Cracks: ~16 jagged radial cracks of random reach, hot edges cooling over ~1 s.
		float R = v_half.x;
		float r = length(p);
		if (r > 1.0) {
			discard;
		}
		float au = atan(p.y, p.x) / 6.2831853 + 0.5;
		float n = 16.0;
		float a2 = au * n + (vnoise(vec2(r * R * 0.9, seed)) - 0.5) * 0.9 + (vnoise(vec2(r * R * 3.1, seed + 4.0)) - 0.5) * 0.25;
		float cell = floor(a2);
		float lane = abs(fract(a2) - 0.5) * 6.2831853 * max(r, 0.05) * R / n;   // metres from the crack line
		float reach = 0.42 + 0.58 * hash(vec2(cell, seed));
		float along = smoothstep(0.07, 0.18, r) * (1.0 - smoothstep(reach - 0.12, reach, r));
		float w = 0.05 + 0.07 * (1.0 - r / max(reach, 0.1));
		float crack = (1.0 - smoothstep(w * 0.4, w, lane)) * along;
		float edge = exp(-pow(lane / (w * 2.0), 2.0)) * along;
		float centre = (1.0 - smoothstep(0.06, 0.22, r)) * (0.6 + 0.4 * vnoise(p * R * 2.0 + seed));
		glow = edge * (0.22 + 1.5 * exp(-age * 2.6)) + centre * 0.4 * exp(-age * 3.0);
		cover = crack * 0.78 + centre * 0.35;
	}
	vec3 emit = tint.rgb * tint.a * glow;
	if (pat == 0) {
		emit = vec3(0.0);
	}
	float a = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = emit * fade + dark * a;
	ALPHA = a;
}
