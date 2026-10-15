// nature_keep_ground.gdshader - the Heartwood's ground contact (art-keep.md 0.5 "moss" variant, task A2.5):
// a dark contact shadow under the chamfered plinth, a lumpy moss carpet crossed by dark surface roots, fallen
// blossom petals and twinkling spore dots, and a fairy ring of small glowing caps (r 5.2) that breathe slowly.
// One unshaded, alpha-blended quad (`size` metres). `build` 0..1 grows the moss with construction, `scorch`
// 0..1 withers it to the wreck's brown patch, `damage` makes the spores flicker.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float size = 13.0;
uniform vec3 moss_color : source_color = vec3(0.17, 0.30, 0.09);
uniform vec3 moss_light : source_color = vec3(0.30, 0.44, 0.13);
uniform vec3 stain_color : source_color = vec3(0.05, 0.05, 0.02);
uniform vec3 root_color : source_color = vec3(0.19, 0.12, 0.06);
uniform vec3 petal_color : source_color = vec3(0.95, 0.66, 0.78);
uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform vec3 wither_color : source_color = vec3(0.30, 0.21, 0.10);
uniform float moss_alpha = 0.78;
uniform float ring_energy = 1.6;
uniform float scorch = 0.0;
uniform float damage = 0.0;
uniform float build = 1.0;
uniform float tier = 1.0;      // G-B: keep tier 1..3 (rune circles)
uniform float upgrade = 0.0;   // G-B: upgrade progress 0..1 (0 = not upgrading)

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x);
	float half_size = size * 0.5;
	float n1 = texture(noise_tex, UV * 1.3).r;
	float n2 = texture(noise_tex, UV * 3.1 + vec2(0.37, 0.71)).r;

	// Dark contact shadow hugging the chamfered plinth (half 3.3, chamfer 1.0).
	vec2 ap = abs(p);
	float plinth_d = max(max(ap.x, ap.y) / 3.3, (ap.x + ap.y) / 5.6);
	float contact = 1.0 - smoothstep(0.96, 1.28, plinth_d + (n2 - 0.5) * 0.08);

	// Lumpy moss carpet that spreads with construction.
	float jag = 0.45 * sin(a * 5.0 + 0.8) + 0.3 * sin(a * 11.0 + 2.9) + 0.2 * sin(a * 19.0 + 4.4);
	float reach = mix(3.6, half_size - 0.6, build) + jag * 0.5 + (n1 - 0.5) * 1.2;
	float moss = 1.0 - smoothstep(reach - 1.3, reach, r);
	moss *= mix(0.7, 1.0, smoothstep(0.3, 0.6, n1));
	vec3 col = mix(moss_color, moss_light, smoothstep(0.35, 0.75, n2));
	float alpha = moss * moss_alpha;

	// Surface roots: 9 wavy dark lines crawling out of the plinth, thinning outward.
	float sectors = 9.0;
	float s = (a + 0.3 * sin(r * 1.4 + 0.5) + 0.15 * sin(r * 3.1)) / 6.2831853 * sectors;
	float id = floor(s);
	float len = (1.0 + hash1(id) * 1.6) * build;
	float t = clamp((r - 3.2) / max(len, 0.01), 0.0, 1.0);
	float d = abs(fract(s) - 0.5) * (r * 6.2831853 / sectors);
	float width = mix(0.2, 0.03, t);
	float root = (1.0 - smoothstep(width * 0.55, width, d)) * step(3.2, r) * (1.0 - step(1.0, t));
	col = mix(col, root_color, root * 0.9);
	alpha = max(alpha, root * 0.85);

	// Fallen blossom petals: small tilted ovals, thicker near the tree.
	vec2 pc = p * 2.6;
	vec2 cell = floor(pc);
	float h = hash2(cell);
	vec2 f = fract(pc) - 0.5 - (vec2(hash2(cell + 1.7), hash2(cell + 4.3)) - 0.5) * 0.5;
	float ang = h * 6.2831853;
	vec2 q = vec2(cos(ang) * f.x - sin(ang) * f.y, sin(ang) * f.x + cos(ang) * f.y);
	float petal = 1.0 - smoothstep(0.9, 1.1, length(q / vec2(0.16, 0.09)));
	float density = mix(0.9, 0.975, smoothstep(3.5, 6.0, r));
	petal *= step(density, h) * moss * (1.0 - contact) * build;
	col = mix(col, petal_color * (0.85 + 0.3 * hash2(cell + 9.1)), petal);
	alpha = max(alpha, petal * 0.95);

	// Spore dots (tiny, twinkling).
	vec2 sc = floor(p * 2.2);
	float hs = hash2(sc + 31.0);
	float spore = step(0.955, hs) * (1.0 - smoothstep(0.03, 0.08, length(fract(p * 2.2) - 0.5)))
		* (0.55 + 0.45 * sin(TIME * (1.4 + damage * 5.0) + hs * 40.0)) * moss * (1.0 - contact);
	col = mix(col, glow_color * 1.5, spore * (1.0 - scorch));
	alpha = max(alpha, spore);

	// Fairy ring: 30 small glowing caps on a ring r 5.2 over a band of darker lush moss.
	float rr = 5.2 + 0.12 * sin(a * 3.0 + 1.0);
	float band = 1.0 - smoothstep(0.0, 0.55, abs(r - rr));
	col = mix(col, moss_color * 0.6, band * 0.5 * build);
	alpha = max(alpha, band * 0.55 * build);
	float caps = 30.0;
	float ca = (a / 6.2831853 + 0.5) * caps;
	float cid = floor(ca);
	float jitter = (hash1(cid + 5.0) - 0.5) * 0.35;
	float cang = (cid + 0.5 + jitter * 0.5) / caps * 6.2831853 - 3.14159265;
	vec2 cap_c = vec2(cos(cang), sin(cang)) * (rr + jitter);
	float cap_r = 0.09 + 0.07 * hash1(cid + 11.0);
	float cd = length(p - cap_c);
	float cap = (1.0 - smoothstep(cap_r * 0.7, cap_r, cd)) * build;
	float breathe = 0.6 + 0.4 * sin(TIME * 1.1 + cid * 0.9);
	vec3 cap_col = mix(glow_color * glow_color, glow_color, 0.5);
	col = mix(col, cap_col * (0.8 + ring_energy * breathe * (1.0 - scorch * 0.8)), cap);
	alpha = max(alpha, cap);

	// G-B tiers: Stronghold (tier 2) draws a glowing rune circle (r 4.45) with 8 leaf glyphs; Citadel (tier 3) a
	// second circle and glowing veins out to the fairy ring. While upgrading, a light sweeps the circle (progress).
	if (tier > 1.5 || upgrade > 0.0) {
		float lw = 0.045;
		float ring1 = 1.0 - smoothstep(lw, lw + 0.04, abs(r - 4.45));
		float g8 = (a / 6.2831853 + 0.5) * 8.0;
		vec2 gc = vec2(cos((floor(g8) + 0.5) / 8.0 * 6.2831853 - 3.14159265),
			sin((floor(g8) + 0.5) / 8.0 * 6.2831853 - 3.14159265)) * 4.45;
		vec2 gd = p - gc;
		float glyph = 1.0 - smoothstep(0.16, 0.2, length(gd * vec2(1.0, 1.0)));
		glyph = max(glyph * (1.0 - smoothstep(0.05, 0.09, abs(length(gd) - 0.13))), (1.0 - smoothstep(0.035, 0.06, length(gd))));
		float rune = max(ring1, glyph);
		if (tier > 2.5) {
			float ring2 = 1.0 - smoothstep(0.03, 0.07, abs(r - 4.75));
			float veins = 1.0 - smoothstep(0.03, 0.07, abs(fract(g8 + 0.5) - 0.5) * r * 6.2831853 / 8.0);
			veins *= step(4.75, r) * (1.0 - smoothstep(5.0, 5.15, r));
			rune = max(rune, max(ring2, veins));
		}
		float on = tier > 1.5 ? 1.0 : 0.0;
		float sweep = 0.0;
		if (upgrade > 0.0) {
			float u = a / 6.2831853 + 0.5;   // 0..1 around
			sweep = step(u, upgrade) * (0.55 + 0.45 * sin(TIME * 4.0 - u * 18.0));
		}
		float k = max(on, sweep) * rune * build * (1.0 - scorch);
		float br = 0.75 + 0.25 * sin(TIME * 0.9 + r);
		col = mix(col, glow_color * (1.1 + ring_energy * 0.6 * br), k);
		alpha = max(alpha, k);
	}

	// Contact shadow last (darkest under the plinth).
	col = mix(col, stain_color, contact * 0.92);
	alpha = max(alpha, contact * 0.8);

	// Destroyed: the moss withers brown and the patch darkens.
	col = mix(col, wither_color * (0.75 + 0.5 * n2), scorch * 0.85 * (1.0 - contact) * (1.0 - cap * 0.5));
	alpha = mix(alpha, max(alpha, moss * 0.85), scorch);
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
