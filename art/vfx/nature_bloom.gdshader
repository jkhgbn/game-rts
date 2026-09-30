shader_type spatial;
// Wild Bloom circle (PlaneMesh 2 x 2 scaled to the radius): a pale-gold rim, a slowly turning ring of sage leaves
// with cream-gold petals between them, a blossom rosette in the middle and soft healing waves rolling outward.
// `grow` 0 -> 1 unfurls it from the centre, `fade` fades it at the end of the heal.
// In-game grade pass (2026-09-30): it was lime green on green meadow (dE ~5); the rim, the dotted ring and the petal
// ring are pale gold / cream now, the fill a warm straw tint, and the brightest colour ~1.1 x (under the bloom).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 leaf_color : source_color = vec3(0.56, 0.66, 0.30);    // sage, lighter than the grass
uniform vec3 glow_color : source_color = vec3(0.80, 1.00, 0.45);    // healing waves, rosette heart
uniform vec3 gold_color : source_color = vec3(1.00, 0.85, 0.50);    // rim, dotted ring, petal ring
uniform vec3 fill_color : source_color = vec3(0.95, 0.85, 0.55);    // warm straw fill
uniform vec3 petal_color : source_color = vec3(1.00, 0.76, 0.82);
uniform float glow_energy = 1.1;
uniform float fill_alpha = 0.12;
instance uniform float fade = 1.0;
instance uniform float grow = 1.0;
instance uniform float seed = 0.0;

float leaf_shape(vec2 q) {
	// q.x along the leaf (0..1), q.y across: a pointed leaf blade.
	float w = 0.5 * sin(clamp(q.x, 0.0, 1.0) * 3.14159) * (1.0 - 0.35 * q.x);
	return (1.0 - smoothstep(w * 0.8, w, abs(q.y))) * step(0.0, q.x) * step(q.x, 1.0);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0 || r > grow + 0.02) {
		discard;
	}
	float ang = atan(p.y, p.x) + TIME * 0.12 + seed;
	vec3 col = fill_color;
	float a = fill_alpha * smoothstep(1.0, 0.6, r);
	// Healing waves rolling outward.
	float wave = pow(0.5 + 0.5 * sin(r * 16.0 - TIME * 4.0), 6.0) * smoothstep(0.15, 0.4, r) * smoothstep(1.0, 0.75, r);
	col = mix(col, gold_color * glow_energy, wave * 0.6);
	a += wave * 0.12;
	// Ring of 12 sage leaves at r 0.62..0.9 pointing outward, a cream-gold petal between each pair.
	float seg = 6.2831853 / 12.0;
	float la = mod(ang + seg * 0.5, seg) - seg * 0.5;
	vec2 lq = vec2((r - 0.60) / 0.30, la * r / 0.12);
	float leaf = leaf_shape(vec2(lq.x, lq.y * 0.9));
	float rib = leaf * (1.0 - smoothstep(0.0, 0.08, abs(lq.y)));
	col = mix(col, leaf_color, leaf * 0.9);
	col = mix(col, gold_color * 0.95, rib);
	a = max(a, leaf * 0.55 + rib * 0.3);
	float pa2 = mod(ang, seg) - seg * 0.5;
	vec2 pq = vec2((r - 0.70) / 0.22, pa2 * r / 0.09);
	float gpetal = leaf_shape(vec2(pq.x, pq.y * 0.8)) * (1.0 - leaf);
	col = mix(col, gold_color * glow_energy, gpetal * 0.95);
	a = max(a, gpetal * 0.8);
	// Blossom rosette: 6 petals r < 0.3 and a glowing heart.
	float pa = mod(ang * 1.0 - TIME * 0.3 + 0.26, 6.2831853 / 6.0) - 3.14159 / 6.0;
	float petal_r = 0.30 * (0.55 + 0.45 * cos(pa * 3.0));
	float petal = 1.0 - smoothstep(petal_r - 0.04, petal_r, r);
	col = mix(col, petal_color * 1.1, petal * 0.85);
	float heart = 1.0 - smoothstep(0.03, 0.08, r);
	col = mix(col, gold_color * glow_energy, heart);
	a = max(a, petal * 0.6 + heart);
	// Rim: a wide pale-gold main ring plus a dotted inner ring.
	float rim = 1.0 - smoothstep(0.0, 0.045, abs(r - 0.955));
	float dots = (1.0 - smoothstep(0.0, 0.02, abs(r - 0.54))) * step(0.5, fract(ang * 36.0 / 6.2831853));
	float pulse = 0.9 + 0.1 * sin(TIME * 3.0);
	col = mix(col, gold_color * glow_energy * pulse, clamp(rim + dots * 0.8, 0.0, 1.0));
	a = max(a, rim * 0.95 + dots * 0.7);
	// Bright unfurling front while growing.
	float front = (1.0 - smoothstep(0.0, 0.06, abs(r - grow))) * step(grow, 0.99);
	col = mix(col, gold_color * glow_energy, front);
	a = max(a, front);
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0) * fade;
}
