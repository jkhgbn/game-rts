// frozen_ice.gdshader - clear block ice for the frozen prisoners of mission 2 (G-F review 2 item 11,
// docs/art/gf_m02.md). Built by FrozenBlockArt (art/environment/snow/frozen_block_art.gd) on faceted meshes whose
// COLOR.rgb is an edge code (min component = 0 on a real facet edge, internal triangle diagonals coded out) and
// COLOR.a a per-facet tone. Look: deep blue-green ice that darkens with thickness, a frosted rim on every facet edge,
// rime on the base and on upward faces, cracks (one on the surface + one parallax layer inside, gfx_detail >= 1),
// a soft fresnel. Lit, transparent (no depth write): what is inside (a soldier) shows through, muted.
// Value pass (Ice whites ~0.75-0.8): frost_color is the brightest albedo; no emission unless `glow` > 0.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 ice_deep : source_color = vec3(0.16, 0.34, 0.46);
uniform vec3 ice_face : source_color = vec3(0.42, 0.62, 0.74);
uniform vec3 frost_color : source_color = vec3(0.76, 0.81, 0.87);
uniform float y_min = 0.0;           // object-space y of the block base
uniform float block_height = 2.0;    // metres from y_min to the top
uniform float clarity = 0.52;        // base opacity of clear ice seen face-on
uniform float frost_base = 0.38;     // rime height on the base, as a fraction of block_height
uniform float glow = 0.0;            // faint inner light (0 = none)
uniform float gfx_detail = 0.0;      // 0 Low (no cracks), 1 Medium+ (FrozenLook.tier)

varying vec3 v_local;
varying vec3 v_wp;

uint hash_u(uvec3 q) {
	q = q * uvec3(1597334673u, 3812015801u, 2798796415u);
	uint n = (q.x ^ q.y ^ q.z) * 1597334673u;
	return n ^ (n >> 16u);
}

float hash3(vec3 c) {
	return float(hash_u(uvec3(ivec3(c) + ivec3(4096)))) / 4294967295.0;
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

// A thin wavy crack sheet: the 0.5 level set of 2-octave noise.
float crack(vec3 p) {
	float n = vnoise(p) * 0.65 + vnoise(p * 2.3 + 7.1) * 0.35;
	return 1.0 - smoothstep(0.0, 0.045, abs(n - 0.5));
}

void vertex() {
	v_local = VERTEX;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n_w = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v_w = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 2.2);
	vec3 seed = MODEL_MATRIX[3].xyz * 0.37;
	float h = clamp((v_local.y - y_min) / max(block_height, 0.01), 0.0, 1.0);
	float large = vnoise(v_wp * 1.3 + seed);

	// Frosted rim on the facet edges (edge code in COLOR.rgb), constant width on screen + in metres.
	float e = min(min(COLOR.r, COLOR.g), COLOR.b);
	float fw = fwidth(e);
	float edge = 1.0 - smoothstep(fw * 0.8, fw * 2.6 + 0.06, e);
	edge *= 0.6 + 0.4 * large;
	// Frosted patches on the faces (hoar-frost bloom), broken by the noise.
	float hoar = 0.0;
	if (gfx_detail > 0.5) {
		hoar = smoothstep(0.58, 0.8, vnoise(v_wp * 2.4 + seed + 5.0) * 0.6 + large * 0.4) * 0.7;
	}
	// Rime: thick on the base (broken top line), dusting on faces that look up.
	float base = 1.0 - smoothstep(frost_base * 0.55, frost_base, h + (large - 0.5) * 0.22);
	float top = smoothstep(0.62, 0.92, n_w.y) * (0.45 + 0.4 * large);
	float frost = max(max(edge * 0.85, base * 0.92), max(top, hoar));

	// Clear ice: deeper colour where the view crosses more ice (face-on), paler towards grazing angles.
	vec3 col = mix(ice_deep, ice_face, clamp(fres * 0.9 + (COLOR.a - 0.5) * 0.35 + h * 0.15, 0.0, 1.0));
	float alpha = clarity + fres * 0.36 + (COLOR.a - 0.5) * 0.1 + (1.0 - h) * 0.08;

	if (gfx_detail > 0.5) {
		// Surface crack + an inner crack layer seen through the surface (parallax along the view).
		float c_out = crack(v_wp * 1.1 + seed);
		float c_in = crack((v_wp - v_w * 0.32) * 0.9 + seed + 3.3) * (1.0 - fres);
		col = mix(col, frost_color * 0.92, c_out * 0.7);
		col = mix(col, mix(ice_face, frost_color, 0.5), c_in * 0.45);
		alpha += c_out * 0.25 + c_in * 0.18;
		// Trapped milky veils inside the block.
		float veil = smoothstep(0.55, 0.85, vnoise((v_wp - v_w * 0.5) * 0.7 + seed + 11.0));
		col = mix(col, ice_face * 1.05, veil * 0.25);
		alpha += veil * 0.08;
	}
	col = mix(col, frost_color * (0.9 + 0.1 * large), frost);
	alpha = mix(alpha, 0.94, frost);

	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 0.95);
	ROUGHNESS = mix(0.07, 0.78, frost);
	SPECULAR = 0.55;
	METALLIC = 0.0;
	RIM = 0.25 * (1.0 - frost);
	RIM_TINT = 0.6;
	EMISSION = ice_face * glow * (1.0 - fres) * (1.0 - frost);
}
