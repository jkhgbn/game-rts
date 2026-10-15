// glow_cap.gdshaderinc - G-E fix 4 (docs/art/ge_review.md item 4, docs/art/ge_fixes_a.md): building glow parts
// (orbs, crowns, braziers, doors) burned to pure white discs: their unshaded colour went to 3-4x, far above the bloom
// threshold (glow_hdr_threshold 1.2, world_env.tres), and ACES flattens every channel to white. glow_cap() squeezes
// the brightest channel softly toward `glow_cap_max` (no hard edge: idle parts below the knee are untouched, pulses /
// selection / training flashes still read, they just saturate) and deepens the hue as it squeezes, so the core keeps
// its colour and shape and the bloom halo is tinted, not white. Same cost at every tier (a few ALU ops).
// Spell / combat VFX never include it: they stay free to burn hot.

uniform float glow_cap_max : hint_range(0.5, 8.0) = 1.5;

vec3 glow_cap(vec3 c, float cap) {
	float m = max(max(c.r, c.g), max(c.b, 0.0001));
	// Pale glow colours (Ice cyan-white, Nature lime, team colours lightened) white out first: their cap is lower
	// (down to 0.72 x for a grey-white) and their hue is deepened harder.
	float sat = 1.0 - min(min(c.r, c.g), c.b) / m;
	cap *= mix(0.72, 1.0, clamp(sat * 1.6, 0.0, 1.0));
	float knee = cap * 0.6;
	float room = cap - knee;
	float over = max(m - knee, 0.0);
	float squeeze = over / (over + room);          // 0 below the knee -> 1 far above
	float m2 = min(m, knee) + room * squeeze;      // asymptote at `cap`
	vec3 hue = pow(clamp(c / m, 0.0, 1.0), vec3(1.0 + (0.9 + 1.4 * (1.0 - sat)) * squeeze));
	return hue * m2;
}
