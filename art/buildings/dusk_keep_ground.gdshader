// Dusk Keep ground contact (art-keep.md 0.5, 3.V2b): dark void stain + glowing radial cracks +
// a slowly turning rune circle, on one flat quad. Unshaded, alpha blended, no depth write.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform float size = 11.0;            // quad side in metres (the mesh size)
uniform vec3 stain_color : source_color = vec3(0.04, 0.02, 0.06);
uniform vec3 edge_color : source_color = vec3(0.15, 0.06, 0.25);
uniform vec3 glow_color : source_color = vec3(0.70, 0.30, 1.00);
uniform float glow_energy = 2.2;      // crack / rune emission (above the bloom threshold)
uniform float scorch = 0.0;           // 0..1, destroyed: darker, wider stain
uniform float damage = 0.0;           // 0..1, cracks widen and burn brighter
uniform float build = 1.0;            // 0..1, construction: cracks / runes grow with progress

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x);
	float half_size = size * 0.5;

	// Soft stain: dark at the plinth, purple-black mist stain further out, fades at the edge.
	float stain = smoothstep(half_size, 2.8, r);
	vec3 col = mix(edge_color, stain_color, smoothstep(4.6, 3.0, r));
	float alpha = stain * mix(0.72, 0.92, scorch);

	// Radial void cracks: 11 sectors, each with a jagged line of random length.
	float sectors = 11.0;
	float s = a / TAU * sectors;
	float id = floor(s);
	float len = 0.9 + hash(id) * 1.9 + damage * 0.8 + scorch * 0.6;
	float wob = sin(r * 3.1 + id * 7.0) * 0.12 + sin(r * 7.3 + id) * 0.05;
	float d = abs(fract(s) - 0.5 - wob) * (r * TAU / sectors); // metres from the crack line
	float width = mix(0.07, 0.02, clamp((r - 3.0) / len, 0.0, 1.0)) * (1.0 + damage);
	float crack = (1.0 - smoothstep(width, width + 0.05, d))
		* step(3.0, r) * (1.0 - smoothstep(3.0 + len * build - 0.4, 3.0 + len * build, r));

	// Rune circle at r 4.35: a thin ring + 16 dashes that turn slowly.
	float ring = 1.0 - smoothstep(0.03, 0.07, abs(r - 4.35));
	float dash_band = 1.0 - smoothstep(0.10, 0.16, abs(r - 4.6));
	float dash = step(0.55, fract((a + TIME * 0.12) / TAU * 16.0)) * dash_band;
	float runes = (ring * 0.7 + dash) * step(0.999, build) ;

	float pulse = 0.8 + 0.2 * sin(TIME * 1.6 - r * 1.5);
	float glow = max(crack * pulse, runes * 0.55) * (1.0 - scorch * 0.6);
	col = mix(col, glow_color * glow_energy * (1.0 + damage * 0.6), clamp(glow, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(max(alpha, glow), 0.0, 1.0);
}
