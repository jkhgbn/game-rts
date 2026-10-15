// nature_ground.gdshader - ground contact of the Nature halls, hollows and spires (task A2.6), the Heartwood's moss
// patch (art/buildings/nature_keep_ground.gdshader, read-only) with the plinth shape and the dressing sizes as
// parameters so every footprint gets the same language: a dark contact shadow hugging the plinth, a lumpy moss
// carpet crossed by dark surface roots, fallen blossom petals, twinkling spore dots and a fairy ring of small
// glowing caps that breathe. One unshaded, alpha-blended quad (`size` metres, centred on the building).
// `build` 0..1 grows the moss with construction, `scorch` 0..1 withers it (wreck), `damage` makes the spores flicker.
// Plinth shape: `roundness` 0 = square with 45-degree chamfers (`plinth_half`, `chamfer_sum` = the |x| + |z| limit),
// 1 = a circle of radius `plinth_half`.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float size = 10.0;
uniform float plinth_half = 3.2;
uniform float chamfer_sum = 5.4;
uniform float roundness = 0.0;
uniform float reach_min = 3.4;
uniform float root_start = 3.1;
uniform float root_len = 1.4;
uniform float root_count = 9.0;
uniform float root_width = 0.18;
uniform float ring_radius = 4.3;
uniform float ring_caps = 24.0;
uniform float cap_size = 1.0;
uniform float petal_scale = 2.6;
uniform float seed = 0.0;
uniform vec3 moss_color : source_color = vec3(0.17, 0.30, 0.09);
uniform vec3 moss_light : source_color = vec3(0.30, 0.44, 0.13);
uniform vec3 stain_color : source_color = vec3(0.05, 0.05, 0.02);
uniform vec3 root_color : source_color = vec3(0.19, 0.12, 0.06);
uniform vec3 petal_color : source_color = vec3(0.95, 0.66, 0.78);
uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform vec3 wither_color : source_color = vec3(0.30, 0.21, 0.10);
uniform float moss_alpha = 0.78;
uniform float ring_energy = 0.8;
uniform float scorch = 0.0;
uniform float damage = 0.0;
uniform float build = 1.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x) + seed;
	float half_size = size * 0.5;
	vec2 nuv = UV * size / 10.0 + vec2(seed * 0.13, seed * 0.07);
	float n1 = texture(noise_tex, nuv * 1.3).r;
	float n2 = texture(noise_tex, nuv * 3.1 + vec2(0.37, 0.71)).r;

	// Dark contact shadow hugging the plinth.
	vec2 ap = abs(p);
	float sq = max(max(ap.x, ap.y) / plinth_half, (ap.x + ap.y) / chamfer_sum);
	float plinth_d = mix(sq, r / plinth_half, roundness);
	float contact = (1.0 - smoothstep(0.96, 1.3, plinth_d + (n2 - 0.5) * 0.08)) * mix(0.4, 1.0, build);

	// Lumpy moss carpet that spreads with construction.
	float jag = 0.45 * sin(a * 5.0 + 0.8) + 0.3 * sin(a * 11.0 + 2.9) + 0.2 * sin(a * 19.0 + 4.4);
	float reach = mix(reach_min, half_size - 0.5, build) + jag * 0.4 + (n1 - 0.5) * 1.0;
	float moss = 1.0 - smoothstep(reach - 1.1, reach, r);
	moss *= mix(0.7, 1.0, smoothstep(0.3, 0.6, n1));
	vec3 col = mix(moss_color, moss_light, smoothstep(0.35, 0.75, n2));
	float alpha = moss * moss_alpha;

	// Surface roots: wavy dark lines crawling out of the plinth, thinning outward.
	float s = (a + 0.3 * sin(r * 1.4 + 0.5) + 0.15 * sin(r * 3.1)) / 6.2831853 * root_count;
	float id = floor(s);
	float len = (root_len * (0.6 + hash1(id + seed) * 0.9)) * build;
	float t = clamp((r - root_start) / max(len, 0.01), 0.0, 1.0);
	float d = abs(fract(s) - 0.5) * (r * 6.2831853 / root_count);
	float width = mix(root_width, 0.025, t);
	float root = (1.0 - smoothstep(width * 0.55, width, d)) * step(root_start, r) * (1.0 - step(1.0, t));
	col = mix(col, root_color, root * 0.9);
	alpha = max(alpha, root * 0.85);

	// Fallen blossom petals: small tilted ovals, thicker near the building.
	vec2 pc = p * petal_scale;
	vec2 cell = floor(pc);
	float h = hash2(cell + seed);
	vec2 f = fract(pc) - 0.5 - (vec2(hash2(cell + 1.7), hash2(cell + 4.3)) - 0.5) * 0.5;
	float ang = h * 6.2831853;
	vec2 q = vec2(cos(ang) * f.x - sin(ang) * f.y, sin(ang) * f.x + cos(ang) * f.y);
	float petal = 1.0 - smoothstep(0.9, 1.1, length(q / vec2(0.16, 0.09)));
	float density = mix(0.9, 0.975, smoothstep(plinth_half + 0.3, ring_radius + 0.8, r));
	petal *= step(density, h) * moss * (1.0 - contact) * build;
	col = mix(col, petal_color * (0.85 + 0.3 * hash2(cell + 9.1)), petal);
	alpha = max(alpha, petal * 0.95);

	// Spore dots (tiny, twinkling).
	vec2 sc = floor(p * 2.2);
	float hs = hash2(sc + 31.0 + seed);
	float spore = step(0.955, hs) * (1.0 - smoothstep(0.03, 0.08, length(fract(p * 2.2) - 0.5)))
		* (0.55 + 0.45 * sin(TIME * (1.4 + damage * 5.0) + hs * 40.0)) * moss * (1.0 - contact);
	col = mix(col, glow_color * 0.9, spore * (1.0 - scorch));   // G-F r2 item 7: was x1.5 (over the bloom)
	alpha = max(alpha, spore);

	// Fairy ring of small glowing caps over a band of darker lush moss.
	float rr = ring_radius + 0.1 * sin(a * 3.0 + 1.0);
	float band = 1.0 - smoothstep(0.0, 0.45, abs(r - rr));
	col = mix(col, moss_color * 0.6, band * 0.5 * build);
	alpha = max(alpha, band * 0.5 * build);
	float ca = (a / 6.2831853 + 0.5) * ring_caps;
	float cid = floor(ca);
	float jitter = (hash1(cid + 5.0 + seed) - 0.5) * 0.35;
	float cang = (cid + 0.5 + jitter * 0.5) / ring_caps * 6.2831853 - 3.14159265 - seed;
	vec2 cap_c = vec2(cos(cang), sin(cang)) * (rr + jitter);
	float cap_r = (0.08 + 0.06 * hash1(cid + 11.0)) * cap_size;
	float cd = length(p - cap_c);
	float gap = step(0.22, hash1(cid + 17.0 + seed)); // a few caps missing: a ring that grew, not a stamp
	float cap = (1.0 - smoothstep(cap_r * 0.7, cap_r, cd)) * build * gap;
	float breathe = 0.6 + 0.4 * sin(TIME * 1.1 + cid * 0.9);
	vec3 cap_col = mix(glow_color * glow_color, glow_color, 0.5);
	// G-F r2 item 7: the caps reached x1.6 the glow (unshaded) and bloomed into pale ovals; now under the bloom.
	col = mix(col, cap_col * min(0.5 + 0.35 * breathe * clamp(ring_energy / 0.8, 0.0, 1.0), 0.85) * (1.0 - scorch * 0.8), cap);
	alpha = max(alpha, cap);

	// Contact shadow last (darkest under the plinth).
	col = mix(col, stain_color, contact * 0.92);
	alpha = max(alpha, contact * 0.8);

	// Destroyed: the moss withers brown and the patch darkens.
	col = mix(col, wither_color * (0.75 + 0.5 * n2), scorch * 0.85 * (1.0 - contact) * (1.0 - cap * 0.5));
	alpha = mix(alpha, max(alpha, moss * 0.85), scorch);
	// Soft outer edge of the quad (never a hard square).
	alpha *= 1.0 - smoothstep(half_size - 0.6, half_size, max(abs(p.x), abs(p.y)));
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
