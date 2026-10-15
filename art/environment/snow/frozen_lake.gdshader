shader_type spatial;
// G-E fixes B (docs/art/ge_fixes_b.md): the frozen lake's ice (FrozenLook, Glasswater Mere's IceDisc in mission 2).
// Clear blue-green ice over a dark depth (a parallax layer of weed / depth streaks that slides with the view), a pale
// network of frozen fractures over big plates plus fine dark hairlines, trapped bubbles, wind-blown snow dust in
// streaks, a lighter frosted rim near the shore. Centred on the node (lake_radius from NODE_POSITION_WORLD).
// Opaque, one pass; no derivative inside a branch (shader lint B).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float lake_radius = 22.0;
uniform float old_ice = 7.0;
uniform vec3 deep_color : source_color = vec3(0.07, 0.20, 0.29);
uniform vec3 ice_color : source_color = vec3(0.30, 0.52, 0.62);
uniform vec3 rim_color : source_color = vec3(0.60, 0.72, 0.80);
uniform vec3 frost_color : source_color = vec3(0.72, 0.79, 0.87);
uniform vec3 fracture_color : source_color = vec3(0.78, 0.88, 0.94);
uniform vec2 wind = vec2(0.82, 0.57);
uniform float depth_m = 0.9;          // how deep the parallax layer sits (metres)

varying vec3 v_wp;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Integer hash of the cell (exact on every GPU: the sine hash gave seams between value-noise cells).
uint ihash(uvec2 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * 1664525u;
	v.y += v.x * 1664525u;
	v = v ^ (v >> 16u);
	v.x += v.y * 1664525u;
	v.y += v.x * 1664525u;
	v = v ^ (v >> 16u);
	return v.x ^ v.y;
}

float hash(vec2 p) {
	return float(ihash(uvec2(ivec2(floor(p)) + 65536))) / 4294967295.0;
}

vec2 hash2(vec2 p) {
	uint h = ihash(uvec2(ivec2(floor(p)) + 65536));
	return vec2(float(h & 65535u), float(h >> 16u)) / 65535.0;
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 7.1) * 0.3 + vnoise(p * 4.01 + 3.3) * 0.15;
}

// Distance to the nearest Voronoi cell edge (F2 - F1 style, the classic border distance).
float voronoi_edge(vec2 p) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	vec2 mr = vec2(0.0);
	float md = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 b = vec2(float(x), float(y));
			vec2 r = b + hash2(g + b) - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
			}
		}
	}
	md = 8.0;
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			vec2 b = vec2(float(x), float(y));
			vec2 r = b + hash2(g + b) - f;
			if (dot(mr - r, mr - r) > 0.00001) {
				md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
			}
		}
	}
	return md;
}

void fragment() {
	vec2 c = NODE_POSITION_WORLD.xz;
	vec2 p = v_wp.xz - c;
	float r = length(p);
	float rn = r / lake_radius;
	float px = length(fwidth(v_wp.xz));
	// Parallax: the depth layer seen through the ice, offset along the view ray.
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec2 pd = p - vw.xz / max(abs(vw.y), 0.3) * depth_m;
	float depth_n = fbm(pd * 0.22);
	float weed = smoothstep(0.55, 0.75, fbm(pd * 0.6 + 4.0)) * 0.6;
	// Deeper (darker) toward the middle, shallow and paler near the shore.
	float shallow = smoothstep(0.55, 1.0, rn);
	vec3 col = mix(deep_color, ice_color, clamp(shallow * 0.8 + depth_n * 0.45 - 0.1, 0.0, 1.0));
	col = mix(col, deep_color * 0.6, weed * (1.0 - shallow));
	// Plates and fractures: big plates (~4 m) with pale fracture planes, fine dark hairlines (~1.3 m cells).
	vec2 wob = vec2(fbm(p * 0.3), fbm(p * 0.3 + 9.0)) - 0.5;
	float e1 = voronoi_edge((p + wob * 3.0) / 6.0) * 6.0;
	float e2 = voronoi_edge((p + wob * 0.8) / 1.35 + 11.0) * 1.35;
	float aa = px * 0.8 + 0.01;
	float fracture = (1.0 - smoothstep(0.025, 0.045 + aa, e1)) * smoothstep(0.3, 0.6, vnoise(p * 0.25 + 3.0)) * (0.6 + 0.4 * vnoise(p * 0.8));
	float halo = (1.0 - smoothstep(0.0, 0.6, e1)) * 0.2 * smoothstep(0.3, 0.6, vnoise(p * 0.25 + 3.0));
	float hair = (1.0 - smoothstep(0.012, 0.02 + aa, e2)) * smoothstep(0.35, 0.6, vnoise(p * 0.5 + 2.0));
	hair *= 1.0 - smoothstep(0.04, 0.1, px);
	col = mix(col, fracture_color, halo * 0.35);
	col = mix(col, fracture_color, fracture * 0.6);
	col = mix(col, deep_color * 0.7, hair * 0.5);
	// Trapped bubbles: tiny pale dots in clusters (fade at range).
	vec2 bg = p * 3.0;
	vec2 bid = floor(bg);
	float bub = step(0.93, hash(bid)) * step(0.5, vnoise(p * 0.4 + 5.0));
	bub *= 1.0 - smoothstep(0.08, 0.18, length(fract(bg) - 0.5 - (hash2(bid) - 0.5) * 0.5));
	bub *= 1.0 - smoothstep(0.04, 0.1, px);
	col = mix(col, fracture_color, bub * 0.6);
	// Wind-blown snow dust: streaks along the wind, more toward the shore.
	vec2 wd = normalize(wind);
	vec2 wq = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float dust = smoothstep(0.58, 0.82, fbm(vec2(wq.x * 0.09, wq.y * 0.2)) + shallow * 0.15);
	col = mix(col, frost_color, dust * 0.35);
	// Frosted rim: the last ~2.5 m before the shore, noisy edge, then a thin snow-dusted band at the very edge.
	float rim_e = lake_radius - r + (fbm(p * 0.5) - 0.5) * 1.6;
	float rim = 1.0 - smoothstep(0.4, 2.6, rim_e);
	col = mix(col, rim_color, rim * 0.75);
	col = mix(col, frost_color, (1.0 - smoothstep(0.0, 0.6, rim_e)) * 0.85);
	// Old Ice (r <= old_ice): a faint thicker-ice ring, the oldest plates.
	float oring = 1.0 - smoothstep(0.0, 0.35 + aa, abs(r - old_ice) + (vnoise(p * 1.3) - 0.5) * 0.25);
	col = mix(col, fracture_color, oring * 0.35);
	ALBEDO = col;
	float frost = max(max(dust, rim), fracture);
	ROUGHNESS = mix(0.12, 0.7, frost);
	SPECULAR = 0.6;
}
