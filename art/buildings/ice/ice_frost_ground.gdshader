// Ice buildings' ground contact (task A2.4; the Rime Keep's ice_keep_ground.gdshader made generic): a dark contact
// band hugging the plinth (square or round), a HARD-EDGED frost rim about 1 m wide around it (in-game grade pass
// 2026-09-30: the old soft white patch filling the whole quad read as cotton wool at 30 m), blue-grey on its shadow
// side, with radial frost-fern lines and a few twinkling ice glints. Unshaded, alpha blended, no depth write, one flat
// quad (PlaneMesh of side `size`).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform float size = 10.0;            // quad side in metres (the mesh size)
uniform float plinth_half = 3.2;      // contact band starts at this distance (half-size of the plinth)
uniform float roundness = 0.0;        // 0 = square contact band, 1 = round (hex / octagonal plinths)
uniform float sectors = 14.0;         // frost fern count
uniform float seed = 0.0;             // varies the jagged edge and the ferns between building kinds
uniform float rim_width = 1.0;        // frost rim width beyond the plinth (m); clamped to the quad
uniform vec2 shadow_dir = vec2(0.7, -0.7);   // ground direction (x, z) the shadow side faces (away from the sun)
uniform vec3 frost_color : source_color = vec3(0.66, 0.74, 0.84);
uniform vec3 shade_color : source_color = vec3(0.34, 0.42, 0.55);    // blue-grey shadow side + outer lip
uniform vec3 stain_color : source_color = vec3(0.08, 0.11, 0.18);
uniform vec3 glow_color : source_color = vec3(0.75, 0.92, 1.00);
uniform float frost_alpha = 0.85;
uniform float scorch = 0.0;           // 0..1, destroyed: grey slush, darker
uniform float damage = 0.0;           // 0..1, fern lines glow brighter

float hash(float n) { return fract(sin(n * 12.9898 + seed * 7.13) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float a = atan(p.y, p.x);
	float half_size = size * 0.5;
	float sq = mix(max(abs(p.x), abs(p.y)), r, roundness);
	float d_out = mix(sq, r * 0.8, 0.25 * (1.0 - roundness));

	// Hard frost edge (8 cm soft) with a small jag.
	float jag = 0.1 * sin(a * 9.0 + 1.3 + seed) + 0.07 * sin(a * 17.0 + 4.1 - seed) + 0.04 * sin(a * 31.0 + 0.7);
	float reach = min(plinth_half + rim_width, half_size - 0.25) + jag;
	float frost = 1.0 - smoothstep(reach - 0.08, reach, d_out);
	float lip = smoothstep(reach - 0.3, reach - 0.1, d_out) * frost;
	float side = smoothstep(-0.2, 0.6, dot(normalize(p + vec2(0.0001)), normalize(shadow_dir)));

	// Dark contact band hugging the plinth.
	float contact = 1.0 - smoothstep(plinth_half - 0.05, plinth_half + 0.45, sq);

	// Frost ferns: radial lines with chevron side branches.
	float s = a / TAU * sectors + seed;
	float id = floor(s);
	float room = max(reach - plinth_half - 0.15, 0.25);
	float len = room * (0.5 + hash(id) * 0.45);
	float d = abs(fract(s) - 0.5) * (r * TAU / sectors);
	float start = plinth_half + 0.1;
	float in_len = step(start, sq) * (1.0 - smoothstep(start + len - 0.15, start + len, d_out));
	float spine = 1.0 - smoothstep(0.02, 0.045, d);
	float chev = 1.0 - smoothstep(0.018, 0.04, abs(d - abs(fract(r * 3.0 + hash(id)) - 0.5) * 0.5));
	float fern = max(spine, chev * step(d, 0.22)) * in_len;

	// Twinkling glints inside the frost.
	vec2 cell = floor(p * 2.5);
	float h = hash2(cell);
	float glint = step(0.95, h) * (1.0 - smoothstep(0.05, 0.1, length(fract(p * 2.5) - 0.5)))
		* (0.5 + 0.5 * sin(TIME * 2.3 + h * 40.0)) * frost * (1.0 - contact);

	vec3 col = mix(frost_color, shade_color, clamp(side * 0.65 + lip * 0.8, 0.0, 1.0));
	col = mix(col, stain_color, contact * 0.9);
	float alpha = max(frost * frost_alpha, contact * 0.7);
	col = mix(col, frost_color * 1.12, fern * 0.6 * (1.0 - contact * 0.5));
	col = mix(col, glow_color * (1.0 + damage * 0.5), fern * damage * 0.8);
	col += vec3(0.5, 0.75, 0.95) * glint * 0.35;
	alpha = max(alpha, max(fern * 0.75, glint) * frost);
	col = mix(col, vec3(0.20, 0.22, 0.26), scorch * 0.75);
	alpha = mix(alpha, max(alpha, frost * 0.8), scorch);
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
