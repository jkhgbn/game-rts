shader_type spatial;
// Light column for MapFillVfx (task 12.V25): the Wayshrine waking (`shrine_awaken`, a tall gold shaft seen across the
// map) and any other vertical beam. An open CylinderMesh (radius 1, height 1, no caps); node scale x / z = radius,
// y = height, origin at mid height. ONE material for every column, the look comes from instance uniforms.
// Additive: a soft volumetric body (brighter where the view crosses more of it), rising streaks and rune bands, a hot
// foot on the ground, a fade toward the top. `age` flashes it for its first second.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.4, 1.6, 0.5, 1.0);   // linear HDR colour, a = strength
instance uniform float fade = 1.0;
instance uniform float age = 0.0;      // seconds since the column appeared (only its first second is sent)
instance uniform float seed = 0.0;
instance uniform float bands = 1.0;    // 0 = plain shaft, 1 = rune bands climbing it
instance uniform float top_fade = 1.3; // higher = the top fades sooner

varying vec3 lp;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float h = clamp(lp.y + 0.5, 0.0, 1.0);                 // 0 foot, 1 top
	float au = atan(lp.z, lp.x) / 6.2831853 + 0.5;          // 0..1 around (seam-free: integer frequencies below)
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	// Soft body: the centre of the shaft (facing the camera) is denser than its silhouette edge.
	float body = 0.28 + 0.72 * pow(facing, 1.6);
	// Rising streaks: stretched noise scrolling up.
	float t = TIME + seed * 5.0;
	float s1 = vnoise(vec2(au * 14.0, h * 2.5 - t * 1.6));
	float s2 = vnoise(vec2(au * 31.0 + 7.0, h * 5.0 - t * 2.6));
	float streak = smoothstep(0.45, 0.95, s1) * 0.55 + smoothstep(0.6, 1.0, s2) * 0.35;
	// Rune bands: thin bright rings climbing the shaft, broken into dashes.
	float bph = fract(h * 5.0 - t * 0.9);
	float band = exp(-pow((bph - 0.5) * 9.0, 2.0)) * step(0.35, fract(au * 8.0 + floor(h * 5.0 - t * 0.9) * 0.37));
	float foot = exp(-h * 14.0) * 1.6;
	float vert = smoothstep(0.0, 0.03, h) * pow(1.0 - h, top_fade);
	float flash = 1.0 + 1.4 * exp(-age * 3.5);
	float g = (body * (0.55 + streak) + band * bands * 0.9 * facing) * vert * flash + foot * facing;
	vec3 col = tint.rgb * tint.a;
	// A whiter core where it is brightest.
	col = mix(col, vec3(length(col)) * vec3(1.0, 0.97, 0.9), clamp(g - 1.1, 0.0, 0.5));
	ALBEDO = col * g * fade;
	ALPHA = 1.0;
}
