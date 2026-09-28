shader_type spatial;
// forge_citadel mist / cloud-bank / smoke cards: camera-facing soft puffs (collapsed quads like citadel_halo, UV2.x =
// radius m, UV2.y = drift speed), lumpy edge, slow breathing, soft against the scene depth (no hard line where a puff
// meets a cliff), faded out when the camera is inside it. Vertex colour = tint, alpha = density. 0 lights.
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear;

varying float ph;
varying float rad;
varying float near_fade;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ph = w.x * 0.37 + w.z * 0.61 + w.y * 0.23;
	vec4 c = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = -c.z;
	float s = UV2.x * (1.0 + 0.07 * sin(TIME * (0.25 + UV2.y) + ph));
	rad = s;
	vec2 k = UV * 2.0 - 1.0;
	float a = TIME * 0.03 * (UV2.y + 0.3) + ph;
	k = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * k;
	c.xy += k * s;
	near_fade = smoothstep(s * 0.25, s * 1.1, d) * smoothstep(245.0, 205.0, d);
	POSITION = PROJECTION_MATRIX * c;
}

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 k = UV * 2.0 - 1.0;
	float r = length(k);
	float lump = n2(k * 2.3 + ph) * 0.55 + n2(k * 5.1 - ph + TIME * 0.05) * 0.3;
	float a = smoothstep(1.0, 0.25, r + lump * 0.45 - 0.2);
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_d = -v.z / v.w;
	float soft = clamp((scene_d - (-VERTEX.z)) / max(rad * 0.35, 0.5), 0.0, 1.0);
	// a lit top, a cooler belly (vertex colour is the lit tone)
	vec3 col = mix(COLOR.rgb * vec3(0.84, 0.8, 0.92), COLOR.rgb, smoothstep(0.6, -0.4, k.y));
	ALBEDO = col;
	ALPHA = a * COLOR.a * soft * near_fade;
}
