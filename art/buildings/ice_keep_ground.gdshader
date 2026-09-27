// Rime Keep ground contact (art-keep.md 0.5 + kingdom-ice.md 8): a dark contact band under the plinth,
// a jagged frost patch around it with radial frost-fern lines and a few twinkling ice glints.
// Unshaded, alpha blended, no depth write, one flat quad.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform float size = 11.0;            // quad side in metres (the mesh size)
uniform vec3 frost_color : source_color = vec3(0.85, 0.92, 1.00);
uniform vec3 stain_color : source_color = vec3(0.08, 0.11, 0.18);
uniform vec3 glow_color : source_color = vec3(0.75, 0.92, 1.00);
uniform float frost_alpha = 0.68;
uniform float scorch = 0.0;           // 0..1, destroyed: grey slush, darker and wider
uniform float damage = 0.0;           // 0..1, fern lines glow brighter
uniform float build = 1.0;            // 0..1, construction: the frost spreads with progress

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x);
	float half_size = size * 0.5;

	// Jagged frost edge that grows with construction.
	float jag = 0.45 * sin(a * 7.0 + 1.3) + 0.3 * sin(a * 13.0 + 4.1) + 0.2 * sin(a * 23.0 + 0.7);
	float reach = mix(3.6, half_size - 0.7, build) + jag * 0.55;
	float frost = 1.0 - smoothstep(reach - 0.9, reach, r);

	// Dark contact band hugging the square plinth.
	float sq = max(abs(p.x), abs(p.y));
	float contact = 1.0 - smoothstep(3.15, 4.0, sq);

	// Frost ferns: 14 radial lines with chevron side branches.
	float sectors = 14.0;
	float s = a / TAU * sectors;
	float id = floor(s);
	float len = (1.0 + hash(id) * 1.4) * build;
	float d = abs(fract(s) - 0.5) * (r * TAU / sectors);
	float in_len = step(3.3, r) * (1.0 - smoothstep(3.3 + len - 0.3, 3.3 + len, r));
	float spine = 1.0 - smoothstep(0.025, 0.06, d);
	float chev = 1.0 - smoothstep(0.02, 0.05, abs(d - abs(fract(r * 2.4 + hash(id)) - 0.5) * 0.7));
	float fern = max(spine, chev * step(d, 0.32)) * in_len;

	// Twinkling glints inside the frost.
	vec2 cell = floor(p * 2.5);
	float h = hash2(cell);
	float glint = step(0.93, h) * (1.0 - smoothstep(0.05, 0.11, length(fract(p * 2.5) - 0.5)))
		* (0.5 + 0.5 * sin(TIME * 2.3 + h * 40.0)) * frost * (1.0 - contact);

	vec3 col = mix(frost_color, stain_color, contact * 0.9);
	float alpha = max(frost * frost_alpha, contact * 0.7);
	col = mix(col, vec3(1.0), fern * 0.8 * (1.0 - contact * 0.5));
	col = mix(col, glow_color * (1.0 + damage * 1.2), fern * damage * 0.8);
	col += vec3(0.9, 0.95, 1.0) * glint * 0.6;
	alpha = max(alpha, max(fern * 0.75, glint) * frost);
	// Destroyed: dirty slush, darker, stays.
	col = mix(col, vec3(0.20, 0.22, 0.26), scorch * 0.75);
	alpha = mix(alpha, max(alpha, frost * 0.8), scorch);
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
