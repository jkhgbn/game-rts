// Flock impostor (art/cinematics/flocks/README.md): one baked mesh per flyer kind (the real model's meshes merged at
// the rest pose, colours from its materials), drawn by one MultiMesh per kind and LOD. The wing beat is done here:
// vertices carry their part in UV2.x (0 body, 1 wing L, 2 hand L, 3 wing R, 4 hand R, 5 tail) and turn about the
// model's own hinge axes (FlyerModel.wing_axis / hand_axis) with the same curve as flyer_model.gd _pose_flight.
// Per instance (INSTANCE_CUSTOM): x = flap phase 0..1 (0 = wings up), y = flap weight (0 = glide), z = slow phase
// (radians: soar sway, tail / serpent wave), w = packed tint (r5 g5 b5 as an integer + strength as the fraction).
// Everything is a pure function of the instance data the flock writes: no TIME, so seek / record are exact.
// COLOR.a < 0.5 marks an emissive vertex (eyes, lava, glow parts): COLOR.rgb is then the glow colour.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec3 wl_pos;
uniform vec3 wl_axis = vec3(0.0, 0.0, -1.0);
uniform vec3 wl2_pos;
uniform vec3 wl2_axis = vec3(0.0, 0.0, -1.0);
uniform vec3 wr_pos;
uniform vec3 wr_axis = vec3(0.0, 0.0, -1.0);
uniform vec3 wr2_pos;
uniform vec3 wr2_axis = vec3(0.0, 0.0, -1.0);
uniform float flap_amp = 40.0;
uniform float flap_mid = 6.0;
uniform float hand_amp = 24.0;
uniform float tail_start = 1.0;
uniform float tail_sway = 0.1;
uniform float serpent = 0.0;
uniform float wave_k = 0.55;
uniform float wave_amp = 0.6;
uniform float emit_energy = 2.4;
uniform float rim_amount = 0.35;
uniform float roughness_v = 0.72;

varying vec4 v_tint;

mat3 axis_rot(vec3 axis, float a) {
	vec3 u = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	float t = 1.0 - c;
	return mat3(
		vec3(t * u.x * u.x + c, t * u.x * u.y + s * u.z, t * u.x * u.z - s * u.y),
		vec3(t * u.x * u.y - s * u.z, t * u.y * u.y + c, t * u.y * u.z + s * u.x),
		vec3(t * u.x * u.z + s * u.y, t * u.y * u.z - s * u.x, t * u.z * u.z + c));
}

void vertex() {
	vec4 cd = INSTANCE_CUSTOM;
	float p = cd.x;
	float aw = cd.y;
	float slow = cd.z;
	float gw = 1.0 - aw;
	float psi = p < 0.45 ? 0.5 * p / 0.45 : 0.5 + 0.5 * (p - 0.45) / 0.55;
	float c = cos(TAU * psi);
	float soar = sin(slow);
	float raise = radians((flap_mid + flap_amp * c) * aw + gw * (2.0 + 3.0 * soar));
	float hand = radians((-hand_amp * sin(TAU * psi - 0.9) - 6.0) * aw + gw * (5.0 + 2.0 * soar));
	float sweep = radians(4.0 * sin(TAU * psi + 0.4) * aw);
	float flick = radians(3.0 * sin(TAU * psi + 1.2) * aw);
	int part = int(UV2.x + 0.5);
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 yax = vec3(0.0, 1.0, 0.0);
	if (part == 2) {
		mat3 h = axis_rot(wl2_axis, hand) * axis_rot(yax, flick);
		v = wl2_pos + h * (v - wl2_pos);
		n = h * n;
	} else if (part == 4) {
		mat3 h = axis_rot(wr2_axis, -hand) * axis_rot(yax, -flick);
		v = wr2_pos + h * (v - wr2_pos);
		n = h * n;
	}
	if (part == 1 || part == 2) {
		mat3 a = axis_rot(wl_axis, raise) * axis_rot(yax, sweep);
		v = wl_pos + a * (v - wl_pos);
		n = a * n;
	} else if (part == 3 || part == 4) {
		mat3 a = axis_rot(wr_axis, -raise) * axis_rot(yax, -sweep);
		v = wr_pos + a * (v - wr_pos);
		n = a * n;
	}
	if (part == 5) {
		float behind = max(0.0, -v.z - tail_start);
		v.x += tail_sway * behind * sin(slow * 1.37 - behind * 0.9);
	}
	if (serpent > 0.5) {
		float along = max(0.0, -v.z + 0.6);
		float k = clamp(along * 0.35, 0.0, 1.0);
		v.x += wave_amp * k * sin(slow * 2.2 - along * wave_k);
		v.y += 0.3 * wave_amp * k * sin(slow * 1.1 - along * wave_k * 0.5);
	}
	VERTEX = v;
	NORMAL = normalize(n);
	float w = cd.w;
	float strength = fract(w);
	float code = floor(w + 0.0001);
	float r = floor(code / 1024.0);
	float g = floor(mod(code, 1024.0) / 32.0);
	float b = mod(code, 32.0);
	v_tint = vec4(r / 31.0, g / 31.0, b / 31.0, strength);
}

void fragment() {
	vec3 base = COLOR.rgb;
	float lum = dot(base, vec3(0.3, 0.59, 0.11));
	vec3 tinted = mix(base, clamp(v_tint.rgb * (0.3 + 1.7 * lum), 0.0, 1.0), v_tint.a);
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	if (COLOR.a < 0.5) {
		ALBEDO = tinted * 0.25;
		EMISSION = mix(base, v_tint.rgb, v_tint.a * 0.6) * emit_energy;
	} else {
		ALBEDO = tinted;
	}
	ROUGHNESS = roughness_v;
	SPECULAR = 0.3;
	RIM = rim_amount;
	RIM_TINT = 0.5;
}
