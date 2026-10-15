shader_type spatial;
// G-B spell VFX (art/vfx/spells_g/spell_fx_g.gd), High / Ultra only: screen-space distortion.
//   mode 0  shockwave: a flat ground disc; a refracting ring races from the centre to the rim as `life` goes 0 -> 1
//   mode 1  heat haze: a camera-facing quad; the picture behind it wobbles upward (rising heat / cold shimmer)
//   mode 2  implosion: like 0 but the ring closes from the rim to the centre and pulls inward
// The picture is read from the screen texture (the opaque pass), written back offset: no extra light, nothing hidden.
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, fog_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;

instance uniform float life = 0.0;
instance uniform float strength = 0.03;
instance uniform float mode = 0.0;
instance uniform float seed = 0.0;
instance uniform vec4 tint = vec4(0.0);

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	if (mode > 0.5 && mode < 1.5) {
		// camera-facing quad that keeps the node's scale
		vec3 sx = vec3(length(MODEL_MATRIX[0].xyz));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				vec4(INV_VIEW_MATRIX[0].xyz * sx.x, 0.0),
				vec4(INV_VIEW_MATRIX[1].xyz * length(MODEL_MATRIX[1].xyz), 0.0),
				vec4(INV_VIEW_MATRIX[2].xyz * length(MODEL_MATRIX[2].xyz), 0.0),
				MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec2 off = vec2(0.0);
	float mask = 0.0;
	float l = clamp(life, 0.0, 1.0);
	if (mode < 0.5 || mode > 1.5) {
		vec2 c = UV - 0.5;
		float d = length(c) * 2.0;
		float r = mode > 1.5 ? 1.0 - l : l;
		float w = 0.10 + 0.14 * l;
		float ring = 1.0 - smoothstep(0.0, w, abs(d - r));
		ring *= (1.0 - l) * (1.0 - smoothstep(0.92, 1.0, d));
		vec2 dir = d > 0.0001 ? c / (d * 0.5) : vec2(0.0);
		dir = vec2(dir.x, dir.y);
		float wob = 0.75 + 0.5 * n2(c * 9.0 + seed);
		off = dir * ring * strength * wob * (mode > 1.5 ? -1.0 : 1.0);
		mask = ring;
	} else {
		vec2 c = UV - vec2(0.5);
		float side = 1.0 - smoothstep(0.18, 0.5, abs(c.x));
		float vert = smoothstep(0.0, 0.35, UV.y) * (1.0 - smoothstep(0.85, 1.0, UV.y));
		float env = sin(3.14159 * l);
		mask = side * vert * env;
		vec2 flow = vec2(seed, TIME * 1.9);
		float nx = n2(UV * vec2(5.0, 3.5) + flow);
		float ny = n2(UV * vec2(5.0, 3.5) + flow + vec2(7.3, 2.1));
		off = (vec2(nx, ny) - 0.5) * 2.0 * strength * mask;
	}
	vec3 sc = textureLod(screen_tex, SCREEN_UV + off, 0.0).rgb;
	ALBEDO = sc + tint.rgb * mask;
	ALPHA = clamp(mask * 3.0, 0.0, 1.0);
}
