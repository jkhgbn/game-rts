// muster_plate.gdshader - G-F review 2 item 10 (docs/art/gf_r2_autumn.md): the Wave Strike Muster Pad plate as worn
// flagstones instead of a flat unlit grey quad. Drop-in for the plate mesh of scripts/ui/wave_strike/pad_view.gd
// (`_build_plate`: vertex colours STONE top / STONE_RIM rim / darker sides): the vertex colour keeps its role as a value
// multiplier (top 1.0, rim ~0.75, sides darker) and the stone pattern comes from the world position, one flag per
// 1.5 m pad cell (MusterPad.CELL) so the drawn cell grid sits on the joints. Lit (it takes the sun, the shadows and the
// autumn fog like the ground). No texture, no derivative, no extra pass: the same cost at every tier.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform vec3 flag_light : source_color = vec3(0.47, 0.42, 0.35);   // sun-bleached sandstone
uniform vec3 flag_dark : source_color = vec3(0.33, 0.29, 0.24);
uniform vec3 joint_color : source_color = vec3(0.16, 0.13, 0.10);  // trodden earth in the joints
uniform vec3 moss_color : source_color = vec3(0.27, 0.30, 0.15);
uniform float cell = 1.5;                  // flag size (m): MusterPad.CELL
uniform float joint = 0.07;                // joint half width (share of a flag)
uniform float moss_amount = 0.35;
uniform float stone_ref = 0.28;            // the view's STONE vertex value: COLOR / stone_ref = the value multiplier

varying vec3 v_wp;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), u.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_wp.xz / cell;
	vec2 id = floor(p);
	vec2 f = fract(p);
	// Per flag: a value step, a slight warm / cool shift and a few split flags (a crack across the cell).
	float r = h21(id);
	vec3 c = mix(flag_dark, flag_light, 0.25 + 0.6 * r);
	c *= 0.94 + 0.12 * h21(id + 7.3);
	float n = vnoise(v_wp.xz * 2.3);
	c *= 0.9 + 0.2 * n;
	// Joints: worn, uneven edges (noise on the joint width).
	float jw = joint * (0.7 + 0.8 * vnoise(v_wp.xz * 4.1 + 3.0));
	vec2 e = min(f, 1.0 - f);
	float jm = 1.0 - smoothstep(jw, jw + 0.03, min(e.x, e.y));
	if (r > 0.78) {   // a split flag: one crack across it (r is constant per flag, no derivative here)
		float crack = abs(f.y - (0.35 + 0.3 * h21(id + 1.9)) - (f.x - 0.5) * 0.4);
		jm = max(jm, 1.0 - smoothstep(0.012, 0.03, crack));
	}
	// Moss creeping out of the joints, more on the outer flags.
	float moss = smoothstep(0.55, 0.85, vnoise(v_wp.xz * 0.9 + 11.0)) * moss_amount * (1.0 - smoothstep(0.0, 0.18, min(e.x, e.y)));
	c = mix(c, moss_color, moss);
	c = mix(c, joint_color, jm * 0.85);
	// The view's vertex colour as a value multiplier (rim strip and sides darker), never a hue.
	float vm = clamp(dot(COLOR.rgb, vec3(0.333)) / stone_ref, 0.3, 1.3);
	ALBEDO = c * vm;
	ROUGHNESS = 0.92;
}
