shader_type spatial;
// Blizzard snow wall (MapFillWyrmVfx, task 13c.V9): an open cylinder (radius 1, height 1, origin at mid height, no
// caps) scaled to the storm (x / z = radius, y = height). Both faces drawn, so the far wall shows through the near
// one (a cheap volume). Premultiplied alpha: `cover` paints the blowing snow, `tint` adds a cold glow in the gusts.
// Slanted snow streaks race round the wall (`spin` = direction and speed), denser toward the foot (drifting snow),
// thinning to nothing at the top; the silhouette is denser than the face (more snow along the view), and the whole
// wall breathes with gusts. `fade` 0-1, `density` scales the snow.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(0.5, 0.75, 1.0, 1.0);    // linear HDR glow
instance uniform vec4 cover = vec4(0.85, 0.92, 1.0, 0.8);  // rgb linear, a = max opacity
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;
instance uniform float spin = 1.0;
instance uniform float density = 1.0;
// Soft where the wall meets the ground and bodies.
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 lp;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Periodic in x (period `px` cells) so the seam around the cylinder never shows.
float pnoise(vec2 p, float px) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float i0 = mod(i.x, px);
	float i1 = mod(i.x + 1.0, px);
	return mix(mix(hash(vec2(i0, i.y)), hash(vec2(i1, i.y)), f.x),
			mix(hash(vec2(i0, i.y + 1.0)), hash(vec2(i1, i.y + 1.0)), f.x), f.y);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float h = clamp(lp.y + 0.5, 0.0, 1.0);                // 0 foot, 1 top
	float au = atan(lp.z, lp.x) / TAU + 0.5;              // 0..1 around
	float t = TIME + seed * 3.0;
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float body = 0.35 + 0.65 * pow(1.0 - facing, 1.4);
	// Streaks: noise stretched along a slant, scrolling round the wall.
	float cells = 24.0;
	float u = au * cells + h * 5.0 * spin - t * 3.2 * spin;
	float s1 = pnoise(vec2(u, h * 26.0 + seed), cells);
	float u2 = au * cells * 2.0 + h * 9.0 * spin - t * 5.5 * spin;
	float s2 = pnoise(vec2(u2, h * 40.0 - seed * 2.0), cells * 2.0);
	float streaks = smoothstep(0.55, 0.85, s1) * 0.7 + smoothstep(0.62, 0.9, s2) * 0.5;
	// Big soft gust clouds.
	float g = pnoise(vec2(au * 6.0 - t * 0.9 * spin, h * 3.0 - t * 0.4), 6.0);
	float gust = smoothstep(0.25, 0.85, g);
	float vert = smoothstep(0.0, 0.06, h) * (1.0 - smoothstep(0.35, 1.0, h));
	float foot = 1.0 - smoothstep(0.0, 0.3, h);
	float a = (streaks * (0.55 + 0.45 * gust) + gust * 0.4 + foot * (0.5 + 0.7 * g)) * vert * body * density;
	// Soft cut against the ground and bodies.
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 wv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -wv.z / wv.w;
	float soft = clamp((scene_z + VERTEX.z) / 0.6, 0.0, 1.0);
	a = clamp(a * cover.a, 0.0, 1.0) * fade * soft;
	vec3 emit = tint.rgb * (streaks * 0.35 + gust * 0.15) * vert * fade * soft;
	ALBEDO = cover.rgb * a + emit;
	ALPHA = a;
}
