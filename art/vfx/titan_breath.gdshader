shader_type spatial;
// Dragon breath jet (TitanVfx, tasks 13.V14 / 13c.V2): the stream of fire / rime from the mouth to the ground.
// Mesh = the cone TitanVfx builds once (apex at the origin, axis +Z, length 1, end radius 1; UV.x around, UV.y along
// from the mouth), stretched by the node basis (x / y = end radius in metres, z = length to the ground).
// ONE material for every jet: the look is picked per instance. Premultiplied alpha: the `*_color` glows add light,
// `cover` paints a body (dark smoke at the fire's far end, white snow billows for the rime breath) so the stream
// reads over grass, sand and snow. Soft at the silhouette (view facing), noise flowing out of the mouth, the stream
// shoots out of the mouth (`grow` 0 -> 1) and breaks off it at the end (`tail` 0 -> 1).
//   pattern 0 = fire (hot white-yellow core -> orange -> deep red, licking tongues)
//   pattern 1 = frost (billowing snow-white body, cold cyan glow, glittering ice)
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 hot_color = vec4(3.2, 2.6, 1.3, 1.0);    // linear HDR
instance uniform vec4 mid_color = vec4(2.6, 0.9, 0.16, 1.0);
instance uniform vec4 edge_color = vec4(1.2, 0.16, 0.02, 1.0);
instance uniform vec4 cover = vec4(0.05, 0.04, 0.035, 0.5);    // rgb linear, a = max opacity
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float grow = 1.0;
instance uniform float tail = 0.0;
instance uniform float seed = 0.0;
instance uniform float density = 1.0;
// Soft where the stream meets the ground and bodies (no hard cut line).
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
			mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

void fragment() {
	float a = UV.x * TAU;
	float v = clamp(UV.y, 0.0, 1.0);
	bool frost = pattern > 0.5;
	// Seamless around the cone: the noise is sampled on a circle (cos, sin), flowing along the axis.
	float speed = frost ? 3.0 : 6.5;
	float t = TIME * speed + seed * 13.0;
	vec3 q = vec3(cos(a) * 2.3, sin(a) * 2.3, v * (frost ? 3.6 : 6.0) - t);
	float n = noise3(q) * 0.55 + noise3(q * 2.13 + vec3(3.1, 1.7, 0.0)) * 0.3
			+ noise3(q * 4.37 - vec3(1.7, 0.0, 2.9)) * 0.15;
	// Soft silhouette (a volume, not a solid cone); seen along its axis it keeps a floor so it never vanishes.
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float soft = mix(0.1, 1.0, smoothstep(0.2, 0.9, facing));
	soft *= soft;
	float head = 1.0 - smoothstep(grow - 0.1, grow + 0.001, v);
	float cut = smoothstep(tail - 0.001, tail + 0.14, v);
	float mouth = smoothstep(0.0, 0.07, v);
	float far_end = 1.0 - smoothstep(0.55, 1.0, v) * 0.85;
	float scene_depth = texture(depth_tex, SCREEN_UV).r;
	vec4 sp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	float touch = clamp((VERTEX.z - sp.z / sp.w) / 0.9, 0.0, 1.0);
	float body = head * cut * mouth * far_end * soft * fade * touch;
	// Slow streaks along the flow (the stream is made of strands, not a smooth sheet).
	float streak = noise3(vec3(cos(a) * 3.2, sin(a) * 3.2, v * 1.4 - t * 0.55 + seed));
	vec3 emit;
	float alpha;
	if (!frost) {
		// Hot at the mouth, cooling toward the ground; the noise tears it into tongues.
		float heat = clamp(1.08 - v * 1.1 + (n - 0.5) * 0.7, 0.0, 1.0);
		float d = smoothstep(0.42, 0.8, n * 0.72 + streak * 0.36 + (1.0 - v) * 0.12) * body * density;
		vec3 c = mix(edge_color.rgb, mid_color.rgb, smoothstep(0.12, 0.5, heat));
		c = mix(c, hot_color.rgb, smoothstep(0.62, 0.95, heat));
		emit = c * d;
		// Sooty smoke curling off the far end (only where the flame is thin).
		alpha = cover.a * smoothstep(0.5, 1.0, v) * smoothstep(0.35, 0.6, n) * (1.0 - smoothstep(0.62, 0.9, n))
				* head * cut * soft * fade * touch;
		emit += cover.rgb * alpha;
	} else {
		// Billowing snow body (opaque-ish), a cold inner glow, glittering ice specks riding the stream.
		float billow = smoothstep(0.36, 0.72, n * 0.75 + streak * 0.3 + 0.06 * (1.0 - v)) * body * density;
		alpha = clamp(cover.a * billow, 0.0, 1.0);
		float shade = 0.82 + 0.3 * smoothstep(0.4, 0.8, n);
		float inner = smoothstep(0.5, 0.85, n) * (1.0 - v * 0.6);
		vec3 c = mix(edge_color.rgb, mid_color.rgb, inner);
		float spark_n = noise3(q * 9.0 + vec3(0.0, 0.0, t * 0.5));
		float spark = smoothstep(0.86, 0.97, spark_n) * billow;
		emit = cover.rgb * shade * alpha + c * billow * 0.55 + hot_color.rgb * spark;
	}
	ALBEDO = emit;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
