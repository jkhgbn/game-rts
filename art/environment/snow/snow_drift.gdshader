shader_type spatial;
// G-E fixes B (docs/art/ge_fixes_b.md): wind-packed snow for drifts, snowbanks, rock caps and the frozen lake's shore lip
// (FrozenLook, art/environment/snow/frozen_look.gd). Value ~0.8 (not paper white), cool blue on the faces turned away
// from the sky and low on the mound, faint wind ripples, rare glints (sparkle: 0 at Low, set per tier by FrozenLook).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 snow_lit : source_color = vec3(0.62, 0.64, 0.68);
uniform vec3 snow_cool : source_color = vec3(0.44, 0.50, 0.62);
uniform float ripple = 0.5;
uniform float sparkle = 0.0;

varying vec3 v_wp;
varying vec3 v_wn;
varying float v_h;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_h = COLOR.r;   // 0 at the foot of the mound, 1 at the crest (FrozenLook writes it; 1 when the mesh has none)
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

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = v_wp.xz;
	float px = length(fwidth(p));
	float up = clamp(v_wn.y, 0.0, 1.0);
	// Cool where the snow faces away from the open sky and at the foot of the mound (painted ambient occlusion).
	float cool = (1.0 - smoothstep(0.25, 0.85, up)) * 0.55 + (1.0 - smoothstep(0.0, 0.45, v_h)) * 0.35;
	float big = vnoise(p * 0.35);
	vec3 col = mix(snow_lit, snow_cool, clamp(cool + (big - 0.5) * 0.18, 0.0, 1.0));
	// Wind ripples: faint bands, faded once a pixel is wider than them.
	float rb = sin(dot(p, vec2(2.6, 1.7)) + vnoise(p * 0.9) * 5.0);
	col *= 1.0 - ripple * 0.05 * smoothstep(0.3, 1.0, rb) * (1.0 - smoothstep(0.05, 0.14, px));
	ALBEDO = col;
	ROUGHNESS = 0.82;
	SPECULAR = 0.35;
	vec2 sg = p * 5.0;
	vec2 sid = floor(sg);
	float phase = hash(sid) * 40.0 + TIME * 1.6 + dot(CAMERA_POSITION_WORLD.xz, vec2(0.9, 0.6)) * 0.6;
	float spark = step(0.965, hash(sid + vec2(37.0, 11.0))) * pow(max(sin(phase), 0.0), 10.0);
	float sd = length(fract(sg) - 0.5);
	spark *= (1.0 - smoothstep(0.04, 0.16, sd)) * (1.0 - smoothstep(0.05, 0.12, px)) * up;
	EMISSION = vec3(0.85, 0.92, 1.0) * spark * sparkle;
}
