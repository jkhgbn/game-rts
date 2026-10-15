// ambient_birds.gdshader - G-D high flocks (docs/art/gd_ambient.md): small flocks circling / crossing 10-17 m up,
// one MultiMesh for every bird (AmbientLife "Birds"), mesh = the critter bird (critter_meshes.gd bird(): UV.x bone
// 1 inner wing / 2 outer wing, UV2.x part, UV2.y side). All motion is computed here from `clock` (AmbientLife's
// clock, set every frame: a paused game freezes them); the CPU rewrites a flock's instances only when its plan
// changes (drift, re-entry, scatter). The instance transform is NOT a transform (custom_aabb covers the map):
//   origin            A = the flock's path start (x, base altitude, z)
//   basis x column    (radius, phase0, angular speed): the flock circles round its moving centre
//   basis y column    (seed, scale, climb): scale 0 = parked; climb = extra height in the middle of a transit
//   basis z column    (side offset, back offset, palette 0 swallows / 1 doves / 2 kites) of the bird in the flock
//   INSTANCE_CUSTOM   (Bx, Bz, t0, dur): the centre moves from A to B with a smoothstep over [t0, t0 + dur]
// Keep flock_centre() in sync with AmbientLife.flock_centre().
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform, specular_disabled;

uniform float clock = 0.0;
uniform vec3 rim_color : source_color = vec3(0.80, 0.84, 0.95);
uniform float rim_strength = 0.35;

// 3 palettes x (back, belly, wing tip) in sRGB: slate swallows, pale doves, brown kites.
const vec3 PAL[9] = {
	vec3(0.26, 0.29, 0.40), vec3(0.88, 0.82, 0.72), vec3(0.14, 0.15, 0.20),
	vec3(0.76, 0.76, 0.78), vec3(0.95, 0.93, 0.88), vec3(0.40, 0.40, 0.45),
	vec3(0.50, 0.36, 0.24), vec3(0.80, 0.66, 0.48), vec3(0.22, 0.16, 0.12)
};

varying vec3 v_col;

vec3 rot_x(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

vec3 rot_y(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

vec3 rot_z(vec3 p, float a) {
	float s = sin(a);
	float c = cos(a);
	return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

vec2 flock_centre(vec2 a, vec4 b, float t) {
	float u = clamp((t - b.z) / max(b.w, 0.01), 0.0, 1.0);
	return mix(a, b.xy, u * u * (3.0 - 2.0 * u));
}

vec3 flock_pos(vec3 a, vec3 circ, float climb, vec4 b, float t) {
	vec2 c = flock_centre(a.xz, b, t);
	float ang = circ.y + circ.z * t;
	float u = clamp((t - b.z) / max(b.w, 0.01), 0.0, 1.0);
	return vec3(c.x + circ.x * cos(ang), a.y + climb * sin(u * PI), c.y + circ.x * sin(ang));
}

void vertex() {
	vec3 a = MODEL_MATRIX[3].xyz;
	vec3 circ = MODEL_MATRIX[0].xyz;
	vec3 bird = MODEL_MATRIX[1].xyz;
	vec3 off = MODEL_MATRIX[2].xyz;
	vec4 b = INSTANCE_CUSTOM;
	float s = bird.y;
	if (s < 0.0001) {
		VERTEX = (VIEW_MATRIX * vec4(0.0, -300.0, 0.0, 1.0)).xyz;
		NORMAL = vec3(0.0, 1.0, 0.0);
		v_col = vec3(0.0);
	} else {
		float seed = bird.x;
		float t = clock;
		vec3 f0 = flock_pos(a, circ, bird.z, b, t - 0.15);
		vec3 f1 = flock_pos(a, circ, bird.z, b, t + 0.15);
		vec3 vel = (f1 - f0) / 0.3;
		float speed = length(vel.xz);
		vec2 dir = speed > 0.01 ? vel.xz / speed : vec2(0.0, 1.0);
		float yaw = atan(dir.x, dir.y);
		// Formation offset turns with the heading; each bird weaves a little on its own.
		vec3 o = rot_y(vec3(off.x, 0.0, -off.y), yaw);
		o += vec3(sin(t * 0.7 + seed * 9.0), 0.5 * sin(t * 1.1 + seed * 5.0), cos(t * 0.6 + seed * 7.0)) * 0.55;
		vec3 pos = flock_pos(a, circ, bird.z, b, t) + o;
		// Bank into the turn (angular speed sign), harder when the flock turns tightly.
		float turn = circ.z * circ.x / max(speed, 0.5);
		float roll = clamp(-turn * 0.9, -0.6, 0.6);
		float pitch = clamp(-vel.y * 0.08, -0.3, 0.3);
		// Flap-flap-glide; a fast flock (scatter, transit) beats all the time.
		float glide = smoothstep(0.3, 0.75, sin(t * 0.8 + seed * 11.0)) * (1.0 - smoothstep(7.0, 10.0, speed));
		float flap = mix(1.0, 0.08, glide);
		float ph = t * (14.0 + 4.0 * seed) + seed * 30.0;
		float th1 = flap * (0.15 + 0.7 * sin(ph)) + 0.08;
		float th2 = flap * 0.45 * sin(ph - 0.9);
		int bone = int(UV.x + 0.5);
		int part = int(UV2.x + 0.5);
		float sd = UV2.y;
		int pal = clamp(int(off.z + 0.5), 0, 2);
		vec3 col = PAL[pal * 3];
		if (part == 1) {
			col = PAL[pal * 3 + 1];
		} else if (part == 3) {
			col = PAL[pal * 3 + 2];
		}
		v_col = pow(col, vec3(2.2));
		vec3 p = VERTEX;
		vec3 n = NORMAL;
		if (bone == 1 || bone == 2) {
			vec3 S = vec3(sd * 0.04, 0.105, 0.0);
			vec3 EL = vec3(sd * 0.18, 0.105, 0.0);
			if (bone == 2) {
				p = rot_z(p - EL, sd * th2) + EL;
				n = rot_z(n, sd * th2);
			}
			p = rot_z(p - S, sd * th1) + S;
			n = rot_z(n, sd * th1);
		}
		vec3 B = vec3(0.0, 0.08, 0.0);
		p = rot_z(rot_x(p - B, pitch), roll) + B;
		n = rot_z(rot_x(n, pitch), roll);
		vec3 wp = pos + rot_y(p * s, yaw);
		VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
		NORMAL = normalize(mat3(VIEW_MATRIX) * rot_y(n, yaw));
	}
}

void fragment() {
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = v_col;
	EMISSION = rim * rim_color * rim_strength * (0.2 + v_col);
	ROUGHNESS = 1.0;
}
