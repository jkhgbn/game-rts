shader_type spatial;
// Nature ground patch (PlaneMesh 2 x 2 scaled to the radius): a ragged patch of torn soil with jagged radial root
// cracks that glow lime. Thornburst = dark scar, Call the Thicket / sprout = mossy mound, wither = dry brown leaf
// litter (glow_energy 0). `glow` animates the crack light (1 -> 0) while `fade` fades the whole patch.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 soil_color : source_color = vec3(0.17, 0.11, 0.06);
uniform vec3 moss_color : source_color = vec3(0.30, 0.46, 0.12);
uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float glow_energy = 1.6;
uniform float moss_amount = 0.25;
uniform float cracks = 7.0;
uniform float opacity = 0.85;
uniform float rim_glow = 0.0;          // thin glowing ring at the edge (Call the Thicket circle)
// Rim ring colour (NatureVfx sets pale gold on the Call the Thicket circle so it reads on meadow). The default is the
// glow colour, so other users look as before.
uniform vec3 rim_color : source_color = vec3(0.75, 1.00, 0.40);
instance uniform float fade = 1.0;
instance uniform float glow = 1.0;
instance uniform float seed = 0.0;

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

// Jagged radial cracks: n rays with a random angle, length and a wobble along r. a in [0, TAU).
float crack_set(float a, float r, float n, float s, float r0, float reach, float width) {
	float sector = 6.2831853 / n;
	float k = floor(a / sector + 0.5);
	float kk = mod(k, n);
	float base = k * sector + (hash(vec2(kk, s)) - 0.5) * sector * 0.6;
	float wob = (vnoise(vec2(r * 7.0, kk * 3.7 + s)) - 0.5) * 0.45 + (vnoise(vec2(r * 19.0, kk * 1.3 + s)) - 0.5) * 0.14;
	float d = abs(a - base - wob) * r;
	float len = reach * (0.55 + 0.45 * hash(vec2(kk + 7.0, s)));
	float t = clamp((r - r0) / max(len - r0, 0.01), 0.0, 1.0);
	float w = mix(width, width * 0.2, t);
	return (1.0 - smoothstep(w * 0.4, w, d)) * step(r0, r) * step(r, len);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float a = atan(p.y, p.x) + 3.14159265;
	vec2 dir = p / max(r, 0.001);
	float edge_n = vnoise(dir * 2.2 + seed * 7.0) * 0.6 + vnoise(dir * 6.0 - seed * 3.0) * 0.4;
	float reach = 0.7 + 0.28 * edge_n;
	float body = 1.0 - smoothstep(reach - 0.12, reach, r);
	vec2 pr = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p;   // rotated octave: hides the value-noise grid
	float mottle = vnoise(p * 4.0 + seed * 11.0) * 0.55 + vnoise(pr * 9.0 - seed) * 0.3 + vnoise(p * 17.0 + seed) * 0.15;
	float moss = smoothstep(0.62 - moss_amount * 0.6, 0.78 - moss_amount * 0.5, mottle) * step(0.01, moss_amount);
	vec3 col = mix(soil_color * (0.7 + 0.6 * mottle), moss_color * (0.75 + 0.5 * mottle), moss);
	// Darker churned ring near the edge (soil thrown up), lighter dry centre.
	col *= 0.85 + 0.3 * smoothstep(reach, reach * 0.5, r) - 0.25 * smoothstep(reach * 0.7, reach * 0.95, r) * step(r, reach);
	float c = crack_set(a, r, cracks, seed, 0.04, reach * 0.98, 0.07);
	c = max(c, crack_set(a, r, cracks * 2.0 - 1.0, seed + 5.3, 0.3 * reach, reach * 0.9, 0.04) * 0.8);
	vec3 crack_col = mix(soil_color * 0.25, glow_color * glow_energy, glow);
	col = mix(col, crack_col, c);
	float ring = rim_glow * (1.0 - smoothstep(0.0, 0.045, abs(r - 0.93))) * glow;
	col = mix(col, rim_color * min(glow_energy, 1.1), clamp(ring, 0.0, 1.0));
	float a_out = body * opacity + c * 0.5 * glow + ring;
	ALBEDO = col;
	ALPHA = clamp(a_out, 0.0, 1.0) * fade;
}
