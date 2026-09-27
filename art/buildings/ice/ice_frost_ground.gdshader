// Ice buildings' ground contact (task A2.4; the Rime Keep's ice_keep_ground.gdshader made generic): a dark contact
// band hugging the plinth (square or round), a jagged frost patch around it with radial frost-fern lines and a few
// twinkling ice glints. Unshaded, alpha blended, no depth write, one flat quad (PlaneMesh of side `size`).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform float size = 10.0;            // quad side in metres (the mesh size)
uniform float plinth_half = 3.2;      // contact band starts at this distance (half-size of the plinth)
uniform float roundness = 0.0;        // 0 = square contact band, 1 = round (hex / octagonal plinths)
uniform float sectors = 14.0;         // frost fern count
uniform float seed = 0.0;             // varies the jagged edge and the ferns between building kinds
uniform vec3 frost_color : source_color = vec3(0.85, 0.92, 1.00);
uniform vec3 stain_color : source_color = vec3(0.08, 0.11, 0.18);
uniform vec3 glow_color : source_color = vec3(0.75, 0.92, 1.00);
uniform float frost_alpha = 0.62;
uniform float scorch = 0.0;           // 0..1, destroyed: grey slush, darker
uniform float damage = 0.0;           // 0..1, fern lines glow brighter

float hash(float n) { return fract(sin(n * 12.9898 + seed * 7.13) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x);
	float half_size = size * 0.5;

	// Jagged frost edge.
	float jag = 0.45 * sin(a * 7.0 + 1.3 + seed) + 0.3 * sin(a * 13.0 + 4.1 - seed) + 0.2 * sin(a * 23.0 + 0.7);
	float reach = half_size - 0.55 + jag * 0.4;
	float frost = 1.0 - smoothstep(reach - 0.8, reach, r);

	// Dark contact band hugging the plinth.
	float sq = mix(max(abs(p.x), abs(p.y)), r, roundness);
	float contact = 1.0 - smoothstep(plinth_half - 0.05, plinth_half + 0.7, sq);

	// Frost ferns: radial lines with chevron side branches.
	float s = a / TAU * sectors + seed;
	float id = floor(s);
	float room = max(reach - plinth_half - 0.2, 0.3);
	float len = room * (0.45 + hash(id) * 0.55);
	float d = abs(fract(s) - 0.5) * (r * TAU / sectors);
	float start = plinth_half + 0.1;
	float in_len = step(start, sq) * (1.0 - smoothstep(start + len - 0.25, start + len, r));
	float spine = 1.0 - smoothstep(0.022, 0.055, d);
	float chev = 1.0 - smoothstep(0.02, 0.045, abs(d - abs(fract(r * 2.6 + hash(id)) - 0.5) * 0.6));
	float fern = max(spine, chev * step(d, 0.28)) * in_len;

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
	col = mix(col, vec3(0.20, 0.22, 0.26), scorch * 0.75);
	alpha = mix(alpha, max(alpha, frost * 0.8), scorch);
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
