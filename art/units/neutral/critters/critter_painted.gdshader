// critter_painted.gdshader - the game critters (task 12.V15: red deer, rabbit). ONE material per critter kind, one
// draw per critter, 0 lights. Painted look of art-keep.md 0.3 (flat colour blocks x triplanar paint noise, height
// gradient, contact band, toon ramp, soft rim) with the colour blocks baked PER VERTEX, plus a tiny vertex-shader
// rig so the whole animal is ONE mesh (no skeleton, no pivot nodes).
//
// Vertex data (built by critter_mesh_builder.gd):
//   COLOR.rgb   sRGB colour block of the fur / antler / hoof
//   UV.x        weight of the vertex's own bone (level 0): its angles are scaled by it (soft neck / tail joints)
//   UV.y        rest height in metres (height gradient + contact band follow the fur, even when the body rolls)
//   CUSTOM0     level-0 (own) bone: xyz = its rest pivot (model space), w = bone id (-1 = none)
//   CUSTOM1     level-1 (parent) bone, same layout
//   CUSTOM2     level-2 (grandparent) bone, same layout
// Bone ids: 0 body (never rotates here: the body's MeshInstance3D transform carries bounce / pitch / roll / the fall),
//   1 neck, 2 head, 3 ear L, 4 ear R, 5-8 upper legs FL FR BL BR, 9-12 lower legs FL FR BL BR, 13 tail.
// Forward kinematics with rest pivots: the deepest bone first, then its parents (p' = Rp (Rc (p - c) + c - pp) + pp).
//
// Legs are procedural (no per-frame CPU work per leg): angle = walk x (amp sin th) + run x (...) + fold x fold_pose,
//   th = TAU (phase + offset of the leg); the lower leg flexes during the swing (cos th < 0). Angles in rad, rotation
//   about +X: + = the hoof goes BACK (the model faces +Z).
// Instance uniforms (the CritterModel script writes them; slots 3 / 4 = the kit's names, the rest are free slots of
// kit/README.md "Instance uniform slots": this mesh has one material, so nothing else shares its buffer):
//   hit_flash (3), flash_color (4)          the kit's white hit flash
//   gait (8)       x phase (cycles), y walk weight, z run weight, w fold (0 standing .. 1 legs folded: dead / lying;
//                  negative = -tuck: the tuck_pose instead)
//   head_pose (9)  x neck pitch (+ nose down), y neck yaw (+ = toward +X, the animal's left), z head pitch,
//                  w tail pitch (+ = raised: a hanging tail swings back and up)
//   ear_pose (10)  x ear L pitch (+ laid back), y ear R pitch, z ear L roll (+ out), w ear R roll
//   dissolve (11)  0 solid .. 1 gone (painted-noise dissolve after the death fall)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 2.4;     // fine fur blotches (UV per metre)
uniform float noise_scale_b = 0.6;     // broad blotches
uniform float ao_height = 1.6;         // rest height of the top of the body (gradient 0.72 -> 1.08)
uniform float contact_height = 0.25;   // dark band over the hooves / feet (rest height)
uniform vec3 rim_color : source_color = vec3(0.62, 0.58, 0.50);
uniform float rim_strength = 0.22;
uniform vec3 dissolve_edge : source_color = vec3(0.30, 0.22, 0.14);
uniform bool flat_black = false;       // silhouette test renders only (tools/critter_preview.gd)
// Gait (per kind): phase offsets of FL FR BL BR, amplitudes (upper front, lower front, upper hind, lower hind).
uniform vec4 walk_offset = vec4(0.0, 0.5, 0.5, 0.0);
uniform vec4 walk_amp = vec4(0.40, 0.60, 0.36, 0.55);
uniform vec4 run_offset = vec4(0.45, 0.57, 0.0, 0.12);
uniform vec4 run_amp = vec4(0.75, 0.95, 0.70, 0.80);
uniform vec4 fold_pose = vec4(-0.2, 1.2, 0.6, -1.4);
uniform vec4 tuck_pose = vec4(0.0);    // negative gait.w: e.g. the rabbit's fore paws tucked while it sits up
// Neck pitch spread to the lower neck: the neck bone bends about its base, the head about the top (both from CPU).

instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform vec4 gait : instance_index(8) = vec4(0.0);
instance uniform vec4 head_pose : instance_index(9) = vec4(0.0);
instance uniform vec4 ear_pose : instance_index(10) = vec4(0.0);
instance uniform float dissolve : instance_index(11) = 0.0;

varying vec3 v_wp;
varying vec3 v_wn;
varying vec3 v_col;
varying float v_rest_y;
varying vec3 v_lp;
varying vec3 v_ln;

mat3 euler(vec3 a) {
	// R = Ry(yaw) * Rx(pitch) * Rz(roll)
	float sx = sin(a.x); float cx = cos(a.x);
	float sy = sin(a.y); float cy = cos(a.y);
	float sz = sin(a.z); float cz = cos(a.z);
	mat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, sx), vec3(0.0, -sx, cx));
	mat3 ry = mat3(vec3(cy, 0.0, -sy), vec3(0.0, 1.0, 0.0), vec3(sy, 0.0, cy));
	mat3 rz = mat3(vec3(cz, sz, 0.0), vec3(-sz, cz, 0.0), vec3(0.0, 0.0, 1.0));
	return ry * rx * rz;
}

float pick(vec4 v, int i) {
	return i == 0 ? v.x : (i == 1 ? v.y : (i == 2 ? v.z : v.w));
}

vec3 bone_angles(int id) {
	if (id == 1) {
		return vec3(head_pose.x, head_pose.y, 0.0);
	} else if (id == 2) {
		return vec3(head_pose.z, 0.0, 0.0);
	} else if (id == 3) {
		return vec3(-ear_pose.x, 0.0, -ear_pose.z);   // ear L sits on +X: out = -roll
	} else if (id == 4) {
		return vec3(-ear_pose.y, 0.0, ear_pose.w);
	} else if (id == 13) {
		return vec3(head_pose.w, 0.0, 0.0);
	} else if (id >= 5 && id <= 12) {
		bool lower = id >= 9;
		int leg = lower ? id - 9 : id - 5;
		bool front = leg < 2;
		float tw = TAU * (gait.x + pick(walk_offset, leg));
		float tr = TAU * (gait.x + pick(run_offset, leg));
		int k = (front ? 0 : 2) + (lower ? 1 : 0);
		float a;
		if (lower) {
			a = gait.y * pick(walk_amp, k) * max(0.0, -cos(tw)) + gait.z * pick(run_amp, k) * max(0.0, -cos(tr - 0.6));
		} else {
			a = gait.y * pick(walk_amp, k) * sin(tw) + gait.z * pick(run_amp, k) * sin(tr);
		}
		a += gait.w >= 0.0 ? gait.w * pick(fold_pose, k) : -gait.w * pick(tuck_pose, k);
		return vec3(a, 0.0, 0.0);
	}
	return vec3(0.0);
}

void apply_bone(vec4 b, float w, inout vec3 p, inout vec3 n) {
	int id = int(round(b.w));
	if (id <= 0) {
		return;
	}
	mat3 r = euler(bone_angles(id) * w);
	p = r * (p - b.xyz) + b.xyz;
	n = r * n;
}

void vertex() {
	vec3 p = VERTEX;
	vec3 n = NORMAL;
	v_lp = VERTEX;
	v_ln = NORMAL;
	apply_bone(CUSTOM0, UV.x, p, n);
	apply_bone(CUSTOM1, 1.0, p, n);
	apply_bone(CUSTOM2, 1.0, p, n);
	VERTEX = p;
	NORMAL = normalize(n);
	v_wp = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_col = pow(COLOR.rgb, vec3(2.2));
	v_rest_y = UV.y;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	return texture(noise_tex, p.zy * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

void fragment() {
	// Paint noise in MODEL (rest) space: the pattern sticks to the fur while the animal runs and falls.
	vec3 ln = normalize(v_ln);
	float na = triplanar(v_lp, ln, noise_scale_a);
	float nb = triplanar(v_lp + vec3(17.3, 5.1, 9.7), ln, noise_scale_b);
	float edge = 0.0;
	if (dissolve > 0.0) {
		float d = triplanar(v_lp + vec3(3.1, 0.0, 7.7), ln, 3.1) * 0.7 + nb * 0.3 - dissolve * 1.05;
		if (d < 0.0) {
			discard;
		}
		edge = 1.0 - smoothstep(0.0, 0.05, d);
	}
	vec3 albedo = v_col * (1.0 + (na - 0.5) * 0.22) * (1.0 + (nb - 0.5) * 0.12);
	// Height gradient (fake sky light + AO) and dark contact band, on the rest height.
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, v_rest_y / max(ao_height, 0.01)));
	albedo *= mix(0.62, 1.0, smoothstep(0.0, contact_height, v_rest_y));
	albedo = mix(albedo, dissolve_edge * 0.25, edge);
	vec3 emission = vec3(0.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength * (0.4 + albedo * 1.5);
	ALBEDO = flat_black ? vec3(0.0) : albedo;
	EMISSION = flat_black ? vec3(0.0) : emission + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
