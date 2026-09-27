// critter_common.gdshaderinc - shared by the cosmetic critter shaders (task 12.V16, map-fill.md 3.3 / 9).
// Every kind is ONE MultiMesh drawn with its own shader. The CPU (critter_system.gd) only writes an instance when its
// state changes (take-off, landing, a frog's jump...): all motion between those keyframes is computed here from
// `clock` (CritterSystem's own clock, set on the material every frame, so start times in INSTANCE_CUSTOM.x use the
// same time base and a paused game freezes the critters).
// Instance transform: origin = the anchor (world), basis = yaw about +Y x uniform scale; a ZERO basis = parked
// (hidden, every vertex collapses to one point: nothing is rasterised).
// All shaders use skip_vertex_transform: positions are built in world space, then written in view space.

uniform float clock = 0.0;
uniform vec3 rim_color : source_color = vec3(0.62, 0.66, 0.78);
uniform float rim_strength = 0.30;

const vec3 PARKED = vec3(0.0, -200.0, 0.0);

// Sine-free hash (same as nature_painted.gdshader).
float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// A per-instance random number in [0, 1) for a salt.
float hid(float id, float salt) {
	return hash1(vec2(id * 1.618 + salt * 7.13, salt * 3.71 + id * 0.37));
}

// Rotations (radians). rot_x: + = nose (+Z) down. rot_y: yaw, forward (+Z) -> (sin a, 0, cos a). rot_z: + = the +X side
// goes up.
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

// Yaw of the instance basis (its +Z column) and its uniform scale.
float basis_yaw(mat4 m) {
	return atan(m[2].x, m[2].z);
}

float basis_scale(mat4 m) {
	return length(m[0].xyz);
}

// Angle lerp along the short way round.
float mix_angle(float a, float b, float t) {
	float d = mod(b - a + PI, TAU) - PI;
	return a + d * t;
}

vec3 srgb(vec3 c) {
	return pow(c, vec3(2.2));
}
