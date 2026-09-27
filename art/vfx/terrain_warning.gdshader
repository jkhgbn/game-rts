shader_type spatial;
// Event warning ring (TerrainVfx, task 12b.V4, docs/design/terrain.md 6.2 / 7.3): drawn at both spots of a wildfire or a
// lightning strike 10 s before it hits. PlaneMesh 2 x 2 scaled to `radius` metres (node scale.x = radius): the outer
// rim IS the damage radius. ONE material for every ring, the look comes from instance uniforms.
//   rim            a bright line on the exact radius over a dark outline (reads on grass, sand and snow alike)
//   countdown arc  a segmented band inside the rim, one segment per second, lit from 12 o'clock (screen up = -Z)
//                  clockwise for the share of the warning `left`; the lit end is a hot head that retreats each second
//   field          a faint wash + a pulse contracting to the centre (faster in the last seconds, `urgency`)
//   motif          style 0 wildfire: flickering ember specks and warm heat blotches; style 1 storm: a target reticle
//                  (four ticks pointing in + a centre ring): "the bolt lands here". Shape, not only colour, tells them apart
// Premultiplied alpha: `tint` adds light, the outline / band darken a little so the ring reads on bright ground.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 0.9, 0.25, 1.0);   // linear HDR, a = strength
instance uniform float style = 0.0;      // 0 wildfire, 1 storm
instance uniform float fade = 1.0;
instance uniform float age = 0.0;        // seconds since it appeared (only its first second is sent: appear flash)
instance uniform float left = 1.0;       // share of the warning left, 1 -> 0 (the countdown arc)
instance uniform float ticks = 10.0;     // arc segments (one per second of warning)
instance uniform float urgency = 0.0;    // 0 -> 1 over the last 3 s: faster pulse, blink
instance uniform float radius = 4.5;     // metres (= node scale.x)
instance uniform float seed = 0.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float R = max(radius, 0.5);
	float d = (1.0 - r) * R;                        // metres in from the rim
	float rr = r * R;                               // metres from the centre
	float t = TIME + seed * 5.0;
	bool storm = style > 0.5;
	// Clock angle: 0 at screen-up (-Z), growing clockwise as seen by the RTS camera (+X = screen right).
	float a = fract(atan(p.x, -p.y) / 6.2831853 + 1.0);
	float blink = 1.0 + urgency * 0.5 * sin(t * mix(7.0, 18.0, urgency));
	float flash = 1.0 + 1.8 * exp(-age * 5.0);
	// 1. The rim on the exact radius + a dark outline under it.
	float rim = exp(-pow((d - 0.08) / 0.05, 2.0));
	float outline = exp(-pow((d - 0.1) / 0.2, 2.0));
	// 2. The countdown band.
	float b0 = 0.28;
	float b1 = b0 + clamp(R * 0.075, 0.2, 0.42);
	float band = smoothstep(b0 - 0.03, b0 + 0.02, d) * (1.0 - smoothstep(b1 - 0.02, b1 + 0.03, d));
	float rb = max(R - (b0 + b1) * 0.5, 0.3);       // band centre radius (m)
	float nt = max(ticks, 1.0);
	float seg = fract(a * nt);
	float gap = 0.1 * nt / (6.2831853 * rb);        // 0.1 m gaps between the segments
	float segm = smoothstep(0.0, gap, seg) * smoothstep(0.0, gap, 1.0 - seg);
	float lit = 1.0 - smoothstep(left - 0.003, left + 0.003, a);
	float head = exp(-pow((a - left) * 6.2831853 * rb / 0.35, 2.0)) * step(0.002, left);
	// 3. The field: faint wash + a pulse contracting to the centre.
	float fill = 0.012 + 0.03 * smoothstep(0.35, 1.0, r);
	float period = mix(1.0, 0.42, urgency);
	float ph = fract(t / period);
	float pulse = exp(-pow((r - (1.0 - ph)) * R / 0.2, 2.0)) * (1.0 - ph) * 0.3 * smoothstep(0.05, 0.25, r);
	float inner = smoothstep(b1, b1 + 0.1, d);     // the motif lives inside the band
	float motif = 0.0;
	vec3 dark;
	if (storm) {
		// Target reticle: four ticks on the axes pointing in, a small centre ring and dot.
		float ax = min(abs(p.x), abs(p.y)) * R;     // metres from the nearest axis
		float along = max(abs(p.x), abs(p.y)) * R;  // metres along it
		float tick_m = (1.0 - smoothstep(0.04, 0.08, ax)) * smoothstep(0.55, 0.65, along)
				* (1.0 - smoothstep(R - b1 - 0.25, R - b1 - 0.15, along));
		float centre = exp(-pow((rr - 0.42) / 0.05, 2.0)) + (1.0 - smoothstep(0.07, 0.12, rr));
		motif = tick_m * 1.1 + centre * 1.0;
		// A slow sweep of static round the field (pale crackle).
		float crackle = smoothstep(0.78, 0.95, vnoise(vec2(a * 40.0, rr * 3.0 + t * 2.0))) * 0.35 * (0.4 + urgency);
		motif += crackle;
		dark = vec3(0.012, 0.018, 0.035);
	} else {
		// Heat: warm blotches drifting outward + flickering ember specks.
		float n = vnoise(p * R * 0.8 + vec2(seed * 7.0, -t * 0.3));
		vec2 w = p * R * 2.4;
		vec2 c = floor(w);
		float h = hash(c + seed);
		vec2 f = fract(w) - 0.5 - (vec2(hash(c + 1.7), hash(c + 5.3)) - 0.5) * 0.5;
		float speck = step(0.9 - urgency * 0.05, h) * (1.0 - smoothstep(0.05, 0.13, length(f)))
				* (0.5 + 0.5 * sin(t * (3.0 + h * 5.0) + h * 30.0));
		motif = smoothstep(0.55, 0.85, n) * 0.05 * (0.6 + urgency * 0.8) + speck * 0.7;
		dark = vec3(0.03, 0.012, 0.004);
	}
	motif *= inner;
	float g = rim * 1.6 + band * segm * (lit * 1.2 + (1.0 - lit) * 0.04) + head * band * 1.3 + fill + pulse + motif;
	g *= blink * flash;
	float cover = outline * 0.5 + band * 0.32 + 0.06;
	float al = clamp(cover, 0.0, 1.0) * fade;
	ALBEDO = tint.rgb * tint.a * g * fade + dark * al;
	ALPHA = al;
}
