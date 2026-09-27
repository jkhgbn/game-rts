shader_type spatial;
// Camera-facing beast marks in the air (MapFillBeastVfx, task 12.V31). QuadMesh 1 x 1, size = node scale.x (metres).
//   0 slash    `count` curved claw strokes (Maul: 3, Hamstring: 1) drawn across the quad in `sweep` seconds from
//              the moment it appears (`age`), white-hot core, glow in `tint`, a dark cut line behind (`halo`) so it
//              reads on pale ground; `angle` tilts it (radians).
//   1 ripple   a ragged sound ring (Shrieking Dive, Rending Roar): grows with the node scale.
// Premultiplied alpha. Drawn over bodies (no depth test) and pulled toward the camera, like the champion flares.
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

instance uniform vec4 tint = vec4(2.0, 1.8, 1.6, 1.0);   // linear HDR, a = strength
instance uniform vec4 halo = vec4(0.12, 0.02, 0.02, 0.5);  // dark cut colour, a = opacity
instance uniform float pattern = 0.0;
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;
instance uniform float count = 3.0;
instance uniform float angle = -0.6;
instance uniform float sweep = 0.1;

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
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[3].z += 0.6;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;                                   // +y = up on screen
	float glow = 0.0;
	float core = 0.0;
	float cut = 0.0;
	if (int(pattern + 0.5) == 0) {
		float c = cos(angle);
		float s = sin(angle);
		vec2 q = vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
		int n = int(count + 0.5);
		float head = clamp(age / max(sweep, 0.01), 0.0, 1.0) * 1.2;   // how far the claws have raked (0..1.2)
		for (int k = 0; k < 3; k++) {
			if (k >= n) {
				break;
			}
			float lane = n == 1 ? 0.0 : (float(k) - 1.0) * 0.27;
			float x0 = -0.82 + abs(lane) * 0.25;
			float x1 = 0.82 - abs(lane) * 0.3;
			float t = (q.x - x0) / (x1 - x0);           // 0 start .. 1 end of the stroke
			if (t < 0.0 || t > 1.0) {
				continue;
			}
			float y = lane + 0.24 * (t - 0.5) * (t - 0.5) - 0.06 + (vnoise(vec2(t * 6.0, seed + float(k))) - 0.5) * 0.025;
			float w = (n == 1 ? 0.085 : 0.075) * pow(sin(3.14159 * t), 0.7);
			float dist = abs(q.y - y);
			float drawn = 1.0 - smoothstep(head - 0.12, head, t);
			float lead = exp(-pow((t - head + 0.06) / 0.1, 2.0)) * step(head, 1.1);   // bright rake tip
			core = max(core, (1.0 - smoothstep(w * 0.25, w * 0.6, dist)) * drawn);
			glow = max(glow, exp(-pow(dist / max(w, 0.004), 2.0) * 1.3) * drawn * (1.0 + lead * 1.5));
			cut = max(cut, (1.0 - smoothstep(w * 0.9, w * 1.9, dist)) * drawn);
		}
	} else {
		float r = length(p);
		if (r > 1.0) {
			discard;
		}
		float au = atan(p.y, p.x) / 6.2831853 + 0.5;
		float rr = r + (vnoise(vec2(au * 22.0, seed * 3.0)) - 0.5) * 0.06;
		float jag = 0.6 + 0.4 * vnoise(vec2(au * 40.0, seed + 2.0));
		glow = exp(-pow((rr - 0.84) / 0.045, 2.0)) * jag + exp(-pow((rr - 0.72) / 0.07, 2.0)) * 0.3;
		glow *= smoothstep(1.0, 0.94, r);
	}
	vec3 emit = (tint.rgb * glow + mix(tint.rgb, vec3(1.7, 1.6, 1.5), 0.7) * core * 1.3) * tint.a;
	float ha = halo.a * cut;
	ALBEDO = (emit + halo.rgb * ha) * fade;
	ALPHA = ha * fade;
}
