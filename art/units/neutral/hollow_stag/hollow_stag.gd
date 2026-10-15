extends CharacterModel
## Hollow Stag (map-fill.md 5.1 / 10, task 12.V23): the tier-3 camp creature of the two Stag Glades (one per glade,
## standing at the spot). A huge pale forest stag: 1.8 m at the withers, the head ~2.35 m, bare-branch antlers ~3.2 m
## high and ~2.5 m across; ~2.8 m nose to tail (selection radius 0.9, spec height 2.6). Read at 40 m by:
##  - the SIZE and the PALE ash-bone coat (dark birch-bark marks, a moss shawl over the withers, a moss beard);
##  - the ANTLERS: dark gnarled bare branches spreading wide like a winter tree, small GLOWING LEAVES at the twig tips
##    (glow point 1, a few glowing leaves drifting down from them);
##  - the HOLLOW CHEST: behind the shoulders both flanks are open (pale ribs across a dark cavity) and a GREEN HEART of
##    light beats inside it, held by root vines (glow point 2).
## Apart from the huntable red deer (critters/deer.tscn: slim, red-brown, pale-tipped upright antlers, no glow) by
## size (x1.5 height, x2 bulk), colour (pale vs brown), antler shape (wide dark branches vs upright tines) and glow.
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (heart + leaves).
## Motion (procedural, kit rules):
##  - idle: slow breathing, a slow regal look around, the heart beating (double thump); every ~fidget_every s at
##    close range an ANTLER SHAKE fidget (head up, shakes the antlers, sheds a few leaves, paws the ground);
##    `play_fidget()` starts one now;
##  - walk: a long-legged trot (diagonal pairs), the knees / hocks fold the hooves back in each swing (keep_separate
##    shins), the head held high;
##  - attack `antler_gore` (0.8 s, strike 0.12 s = the kit strike frame, damage stays instant): drops the antlers and
##    drives forward (lunge +0.34 m, fore hoof stamps), then hooks the head up and to the side;
##  - cast `antler_sweep` (1.4 s; any id plays it): crouches and swings the lowered antlers to its right, then SWEEPS
##    them across in a wide arc to the left (body turning with it), the heart and leaves flare and a burst of glowing
##    leaves is shed at 0.56 s, then a proud toss and a stamp; the ground ring is MapFillVfx's `antler_sweep` (12.V25);
##  - hit: the kit push + flash, the head jerks up, the antlers twist, the leaves flicker;
##  - death (1.0 s): a jolt (heart flares), the front knees buckle, it topples onto its left side with the legs stiff
##    (a last kick), the head comes to rest with the antlers up, the heart fades and the leaves fall (glows off at
##    0.55 s), then it sinks (the unit is freed at death_finished).
## Budget (map-fill.md 10 hero: <= 26 authored meshes, <= 16 draw instances, 0 lights; keep_separate <= 6): 12
## authored meshes (6 merged pivots: body, neck, 4 upper legs; keep_separate Skull (+antlers) and 4 Shins; the blob),
## 14 draw instances with the 2 emitters (Leaves loop, Shed one-shot). 5 painted + 2 glow materials (materials/).
## See tests/test_12_v23.gd.

const HM := preload("res://art/units/neutral/hollow_stag/hollow_stag_mesh.gd")
const GORE_LEN := 0.8
const GORE_HIT := 0.12
const SWEEP_LEN := 1.4
const SWEEP_SHED := 0.56
const FIDGET_LEN := 1.8
const FIDGET_SHED := 0.7
const DEATH_GLOW_OFF := 0.55
const TOPPLE := 72.0                          # deg: the death roll onto its left side
const DEATH_LEG_LIFT := 22.0                  # deg: the legs swing up level with the ground once it lies
const FRONT_Z := 0.68                         # fore / hind hoof z (the root pitches about them)
const HIND_Z := -0.74
const CROWN_CENTRE := Vector3(0.0, 0.85, -0.04)   # Crown space: between the two antler crowns (leaf sheds)
const LEG_PIVOTS: Array[String] = ["Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR"]

# Keyframe tracks [t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 ease-out,
# 2 ease-in). Degrees / metres. Neck x (Head pivot): + = head down. Crown x: + = nose down (antlers forward).
# Legs: + = hoof forward. Folds (shins): + = hoof folds back. Root pitch: + = nose down.
static var A_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.07, 30.0, 1, 0.12, 36.0, 0, 0.24, -14.0, 1, 0.5, -4.0, 0,
	0.8, 0.0, 0])
static var A_NECK_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, 0.0, 0, 0.24, 12.0, 1, 0.5, 3.0, 0, 0.8, 0.0, 0])
static var A_CROWN := PackedFloat32Array([0.0, 0.0, 0, 0.07, 24.0, 1, 0.12, 28.0, 0, 0.24, -12.0, 1, 0.5, -2.0, 0,
	0.8, 0.0, 0])
static var A_CROWN_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, 0.0, 0, 0.24, -10.0, 1, 0.5, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.08, 1, 0.12, 0.34, 2, 0.3, 0.22, 1, 0.8, 0.0, 0])
static var A_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.05, 1, 0.12, -0.02, 0, 0.24, 0.03, 1, 0.5, 0.0, 0])
static var A_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 4.0, 1, 0.12, 6.0, 0, 0.24, -3.0, 1, 0.5, 0.0, 0])
static var A_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -4.0, 1, 0.12, 14.0, 2, 0.35, 4.0, 1, 0.8, 0.0, 0])
static var A_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, 6.0, 1, 0.12, -12.0, 1, 0.4, -3.0, 0, 0.8, 0.0, 0])
static var A_FOLD := PackedFloat32Array([0.0, 0.0, 0, 0.06, 34.0, 1, 0.12, 0.0, 2, 0.8, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.4, -24.0, 1, 0.72, 26.0, 0, 1.0, 6.0, 1, 1.4, 0.0, 0])
static var C_NECK_Y := PackedFloat32Array([0.0, 0.0, 0, 0.4, -38.0, 1, 0.72, 44.0, 0, 1.0, 8.0, 1, 1.4, 0.0, 0])
static var C_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.4, 30.0, 1, 0.72, 34.0, 0, 0.98, -18.0, 1, 1.4, 0.0, 0])
static var C_CROWN := PackedFloat32Array([0.0, 0.0, 0, 0.4, 20.0, 1, 0.72, 22.0, 0, 0.98, -14.0, 1, 1.4, 0.0, 0])
static var C_ROLL := PackedFloat32Array([0.0, 0.0, 0, 0.4, 16.0, 1, 0.72, -18.0, 0, 0.98, 0.0, 0, 1.4, 0.0, 0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.4, -0.14, 1, 0.72, -0.12, 0, 0.98, 0.05, 1, 1.4, 0.0, 0])
static var C_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.4, 5.0, 1, 0.72, 5.0, 0, 0.98, -6.0, 1, 1.4, 0.0, 0])
static var C_BRACE := PackedFloat32Array([0.0, 0.0, 0, 0.4, 7.0, 1, 0.72, 7.0, 0, 1.1, 0.0, 0])
static var C_STAMP := PackedFloat32Array([0.0, 0.0, 0, 0.8, 0.0, 0, 0.92, 1.0, 1, 1.04, 0.0, 2, 1.4, 0.0, 0])
static var C_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.4, 0.35, 1, 0.56, 1.0, 1, 1.0, 0.3, 0, 1.4, 0.0, 0])
static var D_JOLT := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.3, 0.0, 0])

## Idle antler-shake fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var fidget_every: float = 10.0

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _crown: Node3D
var _skull: MeshInstance3D
var _body_gi: GeometryInstance3D
var _leaves: GPUParticles3D
var _shed: GPUParticles3D
var _lowers: Array[Node3D] = []
var _lower_rest: Array[Vector3] = []
var _crown_rest: Vector3 = Vector3.ZERO
var _crown_req: Vector3 = Vector3.ZERO                        # deg, this frame's crown offsets from the poses
var _lower_req := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])    # deg, this frame's shin folds (FL, FR, BL, BR)
var _crown_w: Vector3 = Vector3(999.0, 0.0, 0.0)
var _lower_w := PackedFloat32Array([999.0, 999.0, 999.0, 999.0])
var _flare: float = 0.0          # 0..1 glow flare of the heart and leaves (sweep, gore, hit)
var _fade: float = 1.0           # death fade of the glows
var _heart_w: float = -1.0
var _leaf_w: float = -1.0
var _fidget_wait: float = 0.0
## B2 pass (2026-09-30): the 4 shins draw as ONE skinned mesh (one bone per Lower pivot, posed after the kit's pivot
## write each frame) instead of 4 keep_separate nodes; the Shin nodes stay (hidden) as the bone sources / test anchors.
var _shin_skel: Skeleton3D
var _shin_mi: MeshInstance3D
static var _shin_cache: Dictionary = {}   # "mesh" -> skinned ArrayMesh, "skin" -> Skin
var _cast_last: float = -1.0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D
var _fidget_last: float = -1.0
var _gores: int = 0
var _sweeps: int = 0
var _sheds: int = 0


# ================================================================ public (tests, preview, camp idle)

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Antler-gore strikes played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _gores


## Antler sweeps that reached their shed frame, for tests.
func sweep_count() -> int:
	return _sweeps


## Leaf bursts shed so far (sweep, fidget, death), for tests.
func shed_count() -> int:
	return _sheds


## Current glow flare (0 rest .. 1 full sweep flare).
func glow_flare() -> float:
	return _flare


## The glow_boost last written to the heart / the leaves (0 once dead).
func heart_glow() -> float:
	return _heart_w


func leaf_glow() -> float:
	return _leaf_w


## Starts the idle antler shake now (it also plays by itself every ~fidget_every s close to the camera).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_last = -1.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, at: Vector3 = Vector3.ZERO, keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	_authored = 0
	_lowers.clear()
	_lower_rest.clear()
	_part($Root/Mount, HM.body_mesh())
	_part($Root/Mount/Head, HM.neck_mesh())
	_crown = $Root/Mount/Head/Crown
	_crown_rest = _crown.position
	_skull = _part(_crown, HM.skull_mesh(), HM.SKULL_ORIGIN, true, "Skull")
	_skull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_skull.set_meta(&"own_glow", true)
	_face = CreatureFaceRig.attach(self, _skull, "hollow_stag", face_spec())
	for k: int in 4:
		var leg: Node3D = get_node(LEG_PIVOTS[k])
		var front: bool = k < 2
		var sx: float = -1.0 if k % 2 == 0 else 1.0
		_part(leg, HM.upper_leg_mesh(front, sx))
		var low: Node3D = leg.get_node("Lower")
		_part(low, HM.lower_leg_mesh(front, sx), model_origin(low), true, "Shin")
		_lowers.append(low)
		_lower_rest.append(low.position)
	_leaves = $Root/Mount/Head/Crown/Leaves
	_shed = $Fx/Shed
	ensure_shadow_blob(0.9, Color(0.03, 0.05, 0.03, 0.5))
	_shadow.scale = Vector3(1.45, 1.0, 3.0)
	_shadow.position = Vector3(0.0, 0.02, -0.02)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none: add the body, neck, legs, skull,
	# shins.
	for i: int in [P_MOUNT, P_MOUNT_HEAD, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
		if m and i == P_MOUNT_HEAD:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for n: Node3D in [_skull] + _lowers:
		for g: Node in ([n] if n is GeometryInstance3D else n.get_children()):
			if g is GeometryInstance3D and not _flash_hit_targets.has(g):
				_flash_hit_targets.append(g)
	# The heart (in the merged body) and the leaves (the skull) glow on their own: beat, flares, the death fade.
	_body_gi = _merged_nodes.get(P_MOUNT)
	if _body_gi:
		_glow_nodes.erase(_body_gi)
	_glow_nodes.erase(_skull)
	if _face:
		_face.set_host(_skull)
	_fidget_wait = _next_fidget() * 0.6
	_build_shin_skin()
	_write_parts(true)
	_write_glow(true)
	_sync_shins()
	# G-D signature (High+): forest motes drifting round the leafy antler crown.
	var crown: Node3D = $Root/Mount/Head/Crown
	_sig = CreatureSignature.attach(self, crown, Vector3(0.0, 0.35, -0.1), &"pollen", 1.2)


## One skinned mesh for the 4 shins (see _shin_skel): vertices in MODEL space at the rest pose (so a static read of
## the mesh sees the shins where they stand), bind k = the inverse of Lower k's rest transform, bone k = Lower k.
func _build_shin_skin() -> void:
	var shins: Array[MeshInstance3D] = []
	for low: Node3D in _lowers:
		var sh := low.get_node_or_null(^"Shin") as MeshInstance3D
		if sh == null:
			return
		shins.append(sh)
	var rest: Array[Transform3D] = []
	for low2: Node3D in _lowers:
		rest.append(_model_xf(low2))
	if not _shin_cache.has("mesh"):
		var by_mat: Dictionary = {}
		var order: Array = []
		for k: int in shins.size():
			var xf: Transform3D = rest[k] * shins[k].transform
			var nb := xf.basis.inverse().transposed()
			var mesh := shins[k].mesh
			for s: int in mesh.get_surface_count():
				var mat: Material = mesh.surface_get_material(s)
				if not by_mat.has(mat):
					by_mat[mat] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array(),
						PackedInt32Array(), PackedFloat32Array()]
					order.append(mat)
				var acc: Array = by_mat[mat]
				var arr := mesh.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var base: int = (acc[0] as PackedVector3Array).size()
				for j: int in v.size():
					acc[0].append(xf * v[j])
					acc[1].append((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
					acc[2].append(uv[j] if j < uv.size() else Vector2.ZERO)
					acc[4].append_array(PackedInt32Array([k, 0, 0, 0]))
					acc[5].append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
				if ix.is_empty():
					for j: int in v.size():
						acc[3].append(base + j)
				else:
					for j: int in ix.size():
						acc[3].append(base + ix[j])
		var am := ArrayMesh.new()
		for mat: Material in order:
			var acc2: Array = by_mat[mat]
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = acc2[0]
			arrays[Mesh.ARRAY_NORMAL] = acc2[1]
			arrays[Mesh.ARRAY_TEX_UV] = acc2[2]
			arrays[Mesh.ARRAY_INDEX] = acc2[3]
			arrays[Mesh.ARRAY_BONES] = acc2[4]
			arrays[Mesh.ARRAY_WEIGHTS] = acc2[5]
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			am.surface_set_material(am.get_surface_count() - 1, mat)
		var skin := Skin.new()
		for k2: int in shins.size():
			skin.add_named_bind("Shin%d" % k2, rest[k2].affine_inverse())
		_shin_cache["mesh"] = am
		_shin_cache["skin"] = skin
	_shin_skel = Skeleton3D.new()
	_shin_skel.name = "ShinSkeleton"
	for k3: int in shins.size():
		_shin_skel.add_bone("Shin%d" % k3)
	add_child(_shin_skel)
	_shin_mi = MeshInstance3D.new()
	_shin_mi.name = "Shins"
	_shin_mi.mesh = _shin_cache["mesh"]
	_shin_mi.skin = _shin_cache["skin"]
	_shin_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shin_mi.custom_aabb = AABB(Vector3(-2.0, -0.5, -2.5), Vector3(4.0, 3.5, 5.0))
	_shin_skel.add_child(_shin_mi)
	_shin_mi.skeleton = NodePath("..")
	_shin_mi.set_instance_shader_parameter(&"ao_height", body_height)
	var glows := false
	for s2: int in _shin_mi.mesh.get_surface_count():
		if instance_uniforms_of(_shin_mi.mesh.surface_get_material(s2)).has("glow_boost"):
			glows = true
	for sh2: MeshInstance3D in shins:
		sh2.visible = false
		_flash_hit_targets.erase(sh2)
		_flash_all_targets.erase(sh2)
		_glow_nodes.erase(sh2)
	_flash_hit_targets.append(_shin_mi)
	_flash_all_targets.append(_shin_mi)
	if glows:
		_glow_nodes.append(_shin_mi)


## A node's transform in this model's space (the chain of local transforms up to the model root).
func _model_xf(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c and c != self:
		t = (c as Node3D).transform * t
		c = c.get_parent()
	return t


## Bone k = Lower pivot k in the skeleton's space (after the kit wrote the pivots this frame).
func _sync_shins() -> void:
	if _shin_skel == null or not is_inside_tree():
		return
	for k: int in _lowers.size():
		var t: Transform3D = _model_xf(_lowers[k])   # the skeleton sits at the model origin
		_shin_skel.set_bone_pose_position(k, t.origin)
		_shin_skel.set_bone_pose_rotation(k, t.basis.get_rotation_quaternion())
		_shin_skel.set_bone_pose_scale(k, t.basis.get_scale())


func _process(delta: float) -> void:
	super._process(delta)
	_sync_shins()


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _action == &"attack":
		_gores += 1
		_flare = maxf(_flare, 0.45)
	elif ev == &"cast_start":
		_cast_last = -1.0


func _on_revive() -> void:
	if _face:
		_face.reset()
	_crown_req = Vector3.ZERO
	_lower_req.fill(0.0)
	_flare = 0.0
	_fade = 1.0
	if _leaves:
		set_fx_emitting(_leaves, _tier < 2)
	_write_parts(true)
	_write_glow(true)


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# A slow regal look around, the head lifting a little now and then.
	var y: float = 10.0 * sin(ph * 0.37 + 0.8 + _phase_off)
	var x: float = -1.5 + 2.5 * sin(ph * 0.53 + _phase_off * 2.0)
	return Vector3(x, y, 0.0) * DEG


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.008 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	pos(P_ROOT, Vector3(0, 0.008 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w)


## Long-legged trot: diagonal pairs (FL + BR, FR + BL); each shin folds its hoof back through the swing; the head held
## high with a small counter-bob.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	var a: float = 26.0 * w
	_stride(P_LEG_FL, ph, a, 62.0 * w)
	_stride(P_LEG_BR, ph, a * 0.85, 50.0 * w)
	_stride(P_LEG_FR, ph + PI, a, 62.0 * w)
	_stride(P_LEG_BL, ph + PI, a * 0.85, 50.0 * w)
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(1.2 * DEG * sin(2.0 * ph) * w, 0, 1.5 * DEG * sin(ph) * w))
	if _action == &"":
		rot(P_MOUNT_HEAD, Vector3((-5.0 + 2.5 * sin(2.0 * ph + 0.6)) * DEG * w, 0, 0))


## One leg of the stride: `amp` deg swing (hoof forward at sin > 0), the shin folds while the hoof travels forward.
func _stride(i: int, ph: float, amp: float, fold: float) -> void:
	rot(i, Vector3(-amp * sin(ph) * DEG, 0, 0))
	_lower_req[i - P_LEG_FL] += fold * maxf(0.0, cos(ph))


func _leg(i: int, fwd: float, fold: float = 0.0, spread: float = 0.0) -> void:
	var sx: float = -1.0 if (i - P_LEG_FL) % 2 == 0 else 1.0
	rot(i, Vector3(-fwd * DEG, 0, sx * spread * DEG))
	_lower_req[i - P_LEG_FL] += fold


## Pitches the body about the hooves that stay planted (+ nose down about the fore hooves, - rears about the hind).
func _pitch_root(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var zp: float = FRONT_Z if th > 0.0 else HIND_Z
	pos(P_ROOT, Vector3(0, zp * sin(th), 0))


# ================================================================ attack / cast / fidget

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"antler_gore":
		return super._pose_attack(prev, t)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, A_NECK), _trk(t, A_NECK_Y), 0) * DEG)
	_crown_req += Vector3(_trk(t, A_CROWN), 0.0, _trk(t, A_CROWN_Z))
	pos(P_ROOT, Vector3(0, _trk(t, A_ROOT_Y), _trk(t, A_ROOT_Z)))
	_pitch_root(_trk(t, A_PITCH))
	var f: float = _trk(t, A_LEG_F)
	var b: float = _trk(t, A_LEG_B)
	_leg(P_LEG_FL, f, _trk(t, A_FOLD))
	_leg(P_LEG_FR, f * 0.5)
	_leg(P_LEG_BL, b)
	_leg(P_LEG_BR, b * 0.85)
	if prev < GORE_HIT and t >= GORE_HIT:
		_on_action_event(&"release")
	return t < GORE_LEN


## Any cast id plays the Antler Sweep: crouch and swing the lowered antlers to the right, sweep them across to the left
## (the body turning with them, heart and leaves flaring, a leaf burst at SWEEP_SHED), a proud toss and a stamp.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ROOT, Vector3(0, _trk(t, C_YAW) * DEG, 0))
	pos(P_ROOT, Vector3(0, _trk(t, C_ROOT_Y), 0))
	_pitch_root(_trk(t, C_PITCH))
	rot(P_MOUNT_HEAD, Vector3(_trk(t, C_NECK), _trk(t, C_NECK_Y), 0) * DEG)
	_crown_req += Vector3(_trk(t, C_CROWN), 0.0, _trk(t, C_ROLL))
	var brace: float = _trk(t, C_BRACE)
	var stamp: float = _trk(t, C_STAMP)
	_leg(P_LEG_FL, -3.0 * brace / 7.0, 0.0, brace)
	_leg(P_LEG_FR, 16.0 * stamp, 70.0 * stamp, brace)
	_leg(P_LEG_BL, 4.0 * brace / 7.0, 8.0 * brace / 7.0, brace * 0.5)
	_leg(P_LEG_BR, 4.0 * brace / 7.0, 8.0 * brace / 7.0, brace * 0.5)
	_flare = maxf(_flare, _trk(t, C_FLARE))
	if _cast_last < SWEEP_SHED and t >= SWEEP_SHED:
		_sweeps += 1
		_shed_burst(1.0)
	_cast_last = t
	return SWEEP_LEN


## The antler shake (1.8 s): head up, three shakes of the antlers (a few leaves shed), then the fore hoof paws twice.
func _pose_fidget(t: float) -> void:
	var up: float = sin(PI * clampf(t / FIDGET_LEN, 0.0, 1.0))
	var sh: float = sin(PI * clampf((t - 0.35) / 0.8, 0.0, 1.0))
	rot(P_MOUNT_HEAD, Vector3(-9.0 * up, 11.0 * sin(t * 11.0) * sh, 0) * DEG)
	_crown_req += Vector3(-4.0 * up, 0.0, 12.0 * sin(t * 11.0 + 0.7) * sh)
	var paw: float = 0.0
	for c: float in [1.2, 1.5]:
		paw = maxf(paw, sin(PI * clampf((t - c + 0.13) / 0.26, 0.0, 1.0)))
	_leg(P_LEG_FL, 14.0 * paw, 68.0 * paw)
	_flare = maxf(_flare, 0.3 * sh)
	if _fidget_last < FIDGET_SHED and t >= FIDGET_SHED:
		_shed_burst(0.3)
	_fidget_last = t


## Restarts the Shed emitter at the antler crowns' current place (world particles fall from there).
func _shed_burst(ratio: float) -> void:
	if _shed == null or _crown == null or not is_inside_tree():
		return
	_sheds += 1
	_shed.position = to_local(_crown.global_transform * CROWN_CENTRE)
	_shed.amount_ratio = ratio
	_shed.restart()


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	if prev <= 0.0 and _leaves:
		set_fx_emitting(_leaves, false)
	var jolt: float = _trk(t, D_JOLT)
	var kneel: float = smoothstep(0.08, 0.40, t)
	var top: float = _ease_in(clampf((t - 0.32) / 0.38, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.8) / 0.2, 0.0, 1.0))
	# The front knees buckle (the body pitches forward and drops), then it topples onto its left side.
	rot(P_ROOT, Vector3(9.0 * kneel * (1.0 - top) * DEG, 0, TOPPLE * top * DEG))
	pos(P_ROOT, Vector3(0.62 * top, lerpf(-0.42 * kneel, -0.05, top) - 0.5 * sink, 0.08 * kneel * (1.0 - top)))
	var kick: float = 0.0
	if t > 0.7:
		kick = sin((t - 0.7) * 30.0) * exp(-(t - 0.7) * 6.0)
	# Legs: the fronts fold at the knees while kneeling, then all stretch out stiff, swung up level with the ground
	# (a +z roll lifts every hoof toward the sky side); a last kick of the hind legs.
	for i: int in [P_LEG_FL, P_LEG_FR]:
		_leg(i, 10.0 * kneel * (1.0 - top) + 18.0 * top, 95.0 * kneel * (1.0 - top) + 8.0 * top)
	_leg(P_LEG_BL, -8.0 * kneel * (1.0 - top) - 16.0 * top - 12.0 * kick, 20.0 * kneel * (1.0 - top) + 6.0 * top)
	_leg(P_LEG_BR, -8.0 * kneel * (1.0 - top) - 20.0 * top + 10.0 * kick, 20.0 * kneel * (1.0 - top) + 10.0 * top)
	for i: int in [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		rot(i, Vector3(0, 0, (DEATH_LEG_LIFT + (6.0 if (i - P_LEG_FL) % 2 == 1 else 0.0)) * top * DEG))
	# Head: jerks up, then droops to the ground; the crown counter-rolls so the antlers come to rest pointing up.
	rot(P_MOUNT_HEAD, Vector3((-16.0 * jolt + 12.0 * top) * DEG, 0, 16.0 * top * DEG))
	_crown_req += Vector3(10.0 * top - 8.0 * jolt, 0.0, -(TOPPLE + 16.0) * 0.8 * top)
	_flare = maxf(_flare, jolt)
	_fade = 1.0 - smoothstep(0.25, DEATH_GLOW_OFF, t)
	if prev < DEATH_GLOW_OFF and t >= DEATH_GLOW_OFF:
		_glows_dead()
		_shed_burst(0.8)
	if _shadow:
		_shadow.transparency = clampf((t - 0.6) / 0.4, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		_write_parts(false)
		_write_glow(true)
		death_finished.emit()
		set_process(false)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		if _action == &"fidget":
			if _speed >= 0.3 or _action_t >= FIDGET_LEN:
				_action = &""
			else:
				_pose_fidget(_action_t)
		elif fidget_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_fidget_wait -= dt
			if _fidget_wait <= 0.0:
				_fidget_wait = _next_fidget()
				play_fidget()
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-10.0 * k, 6.0 * k, 0) * DEG)
			_crown_req.z += 9.0 * k
			_flare = maxf(_flare, 0.35 * k)
	_write_parts(false)
	_write_glow(false)
	_flare = move_toward(_flare, 0.0, dt * 1.5)
	_crown_req = Vector3.ZERO
	_lower_req.fill(0.0)


## Writes the Crown / shin transforms (skipped when they barely changed).
func _write_parts(force: bool) -> void:
	if _crown and (force or (_crown_req - _crown_w).length() > 0.25):
		_crown_w = _crown_req
		_crown.transform = Transform3D(Basis.from_euler(_crown_req * DEG), _crown_rest)
	for k: int in _lowers.size():
		var v: float = _lower_req[k]
		if force or absf(v - _lower_w[k]) > 0.3:
			_lower_w[k] = v
			_lowers[k].transform = Transform3D(Basis(Vector3.RIGHT, v * DEG), _lower_rest[k])


## Heart: a slow double heartbeat + the flares; leaves: steady + the flares; both x glow_level (0 once dead) x the
## death fade. Written only when they change enough.
func _write_glow(force: bool) -> void:
	var g: float = glow_level() * _fade
	var x: float = fmod(_t + _phase_off, 1.5)
	var beat: float = exp(-pow((x - 0.15) / 0.07, 2.0)) + 0.6 * exp(-pow((x - 0.38) / 0.07, 2.0))
	var heart: float = g * (0.8 + 0.45 * beat + 1.2 * _flare)
	var leaf: float = g * (1.0 + 0.9 * _flare)
	if _body_gi and (force or absf(heart - _heart_w) > 0.03 or (heart == 0.0 and _heart_w != 0.0)):
		_heart_w = heart
		_body_gi.set_instance_shader_parameter(&"glow_boost", heart)
	if _skull and (force or absf(leaf - _leaf_w) > 0.03 or (leaf == 0.0 and _leaf_w != 0.0)):
		_leaf_w = leaf
		_skull.set_instance_shader_parameter(&"glow_boost", leaf)


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


## Keyframe track [t, v, ease, ...] (see the constants). A few float ops per call.
static func _trk(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size()
	if t >= k[n - 3]:
		return k[n - 2]
	if t <= 0.0:
		return k[1]
	var i: int = 3
	while t >= k[i]:
		i += 3
	var t0: float = k[i - 3]
	var u: float = (t - t0) / (k[i] - t0)
	var e: float = k[i + 2]
	if e == 1.0:
		u = u * (2.0 - u)
	elif e == 2.0:
		u = u * u
	else:
		u = u * u * (3.0 - 2.0 * u)
	return k[i - 2] + (k[i + 1] - k[i - 2]) * u


## The eyes (faces pass 2026-09-28): in the hollow dark sockets, a pale spirit glint (a glowing leaf-green iris on a
## near-black eye) under a pale bark-grey brow ridge that carries the expression. Drawn inside the Skull mesh
## (CreatureFaceRig host mode: no extra draw instance; the skull's glow drive lights the irises too).
static func face_spec() -> Dictionary:
	var out := Vector3(0.80, 0.18, 0.58).normalized()
	return CreatureFaceRig.side_eye_spec(Vector3(0.115, 2.16, 1.24) + out * 0.028, out, 0.032, Color(0.82, 0.80, 0.72),
		Color(0.60, 1.0, 0.40), 0.9, {"palette": {"sclera": Color(0.05, 0.05, 0.04), "brow": Color(0.30, 0.24, 0.18),
		"lash": Color(0.10, 0.08, 0.06)}, "eye": {"pupil": 0.35}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
