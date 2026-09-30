extends IceModel
## Frostcrown Juggernaut rider (stables.md 2 slot V, the Ice tier-3 elite): a crowned knight in full steel-blue plate on
## the Frostcrown war-bear (frostcrown_bear.gd). Seated with the kit's set_seated (13.V1b); frostcrown_juggernaut.tscn
## pairs the two.
## Look: heavy STEEL-BLUE plate (ice_steel: the mid-tone mass, not white), big domed pauldrons with light rims and a cyan
## crystal each, a TEAM TABARD front and back (ice_cloth_dark + a light ice_cloth stripe) and a long TEAM CAPE falling
## back over the bear (the top-facing team colour); an open steel helm with cheek guards under THE FROSTCROWN: a light
## circlet with five cyan ice spikes (the only near-white is on their crystal edges = the crest rule). A stern
## weathered face with ice-grey eyes and a steel-grey braid (FaceKit face, eyes / lips / hair; ears under the helm).
## Left arm: a TALL TOWER SHIELD (steel back, team face, a light team cross, a cyan crystal boss) braced out on the
## flank and tilted to the sky. Right hand: a GREAT WAR-HAMMER (own node "Hammer" at the fist, turned by the wrist):
## steel head with a cyan ice block on the striking face, a back spike, a glowing frost band (the glow point) and a
## crystal top spike.
## Riding: hammer carried upright by the shoulder, shield braced; the kit's lean / bob.
## Attack (`great_swing`, 0.95 s, strike SW_HIT 0.16 s = event `release` + signal hammer_struck): the arm goes up and
## back, the hammer head drops behind the shoulders (wind-up), then comes over the top into a smash down the right
## front of the bear (lean into it, the shield swings out).
## Charge (play_charge_pose(), 0.85 s, impact 0.10 s): hunker behind the shield, the hammer raised, a jolt.
## Fidget (IceModel, standing still): hefts the hammer twice and looks round. Cast: the hammer raised high.
## Death: freezes over and SHATTERS (IceModel, 10 shards) while riding the bear's roll.
## Pivots: Root / Hips (the legs astride are part of the hips mesh: this rider never stands) / Chest (the head, helm
## and face are part of the chest: the face is drawn INSIDE the merged chest mesh, CreatureFaceRig host mode) / ArmL /
## ArmR, + Hammer (keep_separate). Budget with the bear: 12 draw instances, ~3000 vertices.
## Hooks (on top of the kit's / IceModel's): play_charge_pose(), get_hammer_head() -> Vector3 (world),
## authored_mesh_count() -> int; signal hammer_struck(at: Vector3).

signal hammer_struck(at: Vector3)

const OWN := "res://art/units/ice/frostcrown_juggernaut/materials/"
const BEAR := preload("res://art/units/ice/frostcrown_juggernaut/parts/frostcrown_bear.gd")

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.90
const SH_L := Vector3(-0.37, 1.43, 0.0)
const SH_R := Vector3(0.37, 1.43, 0.0)
const HAND_L := Vector3(-0.40, 0.92, 0.03)
const HAND_R := Vector3(0.40, 0.92, 0.03)
const HEAD_C := Vector3(0, 1.72, 0.04)
const HEAD_R := 0.145
const HAIR := Color(0.36, 0.38, 0.44)
const HAIR_TIP := Color(0.52, 0.56, 0.64)
## Tower shield centre (model, on the left forearm; its face looks along -X at rest).
const SHIELD_C := Vector3(-0.57, 1.00, 0.05)
const SHIELD: Array[Vector2] = [Vector2(-0.30, 0.44), Vector2(0.30, 0.44), Vector2(0.34, 0.36), Vector2(0.34, -0.18),
	Vector2(0.0, -0.56), Vector2(-0.34, -0.18), Vector2(-0.34, 0.36)]
## The hammer (node-local, origin = the fist): haft along +Y, head centre at HAMMER_HEAD, striking face toward +Z.
const HAMMER_LEN := 1.04
const HAMMER_HEAD := 0.90

## Riding rest pose of the arms (deg, pivot euler offsets): the shield braced out-left and tilted up, the hammer arm low.
const REST_L := Vector3(-28.0, 22.0, -40.0)
const REST_R := Vector3(-28.0, 0.0, 16.0)
## The hammer's angle in the chest frame at rest (deg about X: 0 = haft up, + = head toward the front).
const HAMMER_REST := 22.0
## Attack timeline (s): wind-up end, strike, end.
const SW_WIND := 0.11
const SW_HIT := 0.16
const SW_LEN := 0.95
## Charge (matches MountModel.play_charge: impact 0.10 s, length 0.85 s).
const CH_HIT := 0.10
const CH_LEN := 0.85

var _parts_n: int = 0
var _hammer: MeshInstance3D
var _charge_t: float = 99.0
# this frame's hammer angle / outward roll / yaw added by the poses (deg), consumed by _update_hammer
var _psi_add: float = 0.0
var _roll_add: float = 0.0
var _yaw_add: float = 0.0
var _hammer_q_w: Quaternion = Quaternion(0, 0, 0, 0)


# ================================================================ public hooks

## The rider's half of the cavalry charge (call with the mount's play_charge): hunker behind the shield, hammer raised.
func play_charge_pose() -> void:
	if _dead:
		return
	_charge_t = 0.0
	set_process(true)


## World position of the hammer head (the strike point for VFX).
func get_hammer_head() -> Vector3:
	if _hammer and _hammer.is_inside_tree():
		return _hammer.global_transform * Vector3(0, HAMMER_HEAD, 0.2)
	return global_position + Vector3.UP * 2.4


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	_sculpt($Root/Hips, "fjr_hips_v1", _hips_sculpt)
	_sculpt(chest, "fjr_chest_v1", _chest_sculpt)
	# Face (FaceKit spec, drawn inside the merged chest: host mode in _ice_ready).
	_face = CreatureFaceRig.attach(self, chest, "frostcrown_rider", face_style())
	_sculpt($Root/Chest/ArmL, "fjr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "fjr_arm_r_v1", _arm_r_sculpt)
	_parts_n += 1
	_hammer = add_part($Root/Chest/ArmR, _cached_sculpt("fjr_hammer_v1", _hammer_sculpt), null, HAND_R, Vector3.ZERO,
		Vector3.ONE, true, "Hammer")
	# Level 4: a gold ring on the helm brim (hidden below level 4).
	_parts_n += 1
	var trim := add_part(chest, cyl(0.19, 0.19, 0.04, 10, false), palette(&"unit_gold_trim"), Vector3(0, 1.80, 0.03),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# The shatter death: one burst of 10 crystal shards from the chest.
	_shatter = _shards(10, 0.9, 0.38, 1.6, 3.6, 180.0, Vector3.UP, 0.12)
	_shatter.name = "Shatter"
	_shatter.position = Vector3(0, 1.25, 0.05) - model_origin(chest)
	chest.add_child(_shatter)


## The knight's face: stern, ice-grey eyes, a steel-grey braid and two locks under the helm (cheap flat blades), no ears
## (the cheek guards cover them). Lean settings (no blush, bold RTS lines) for the vertex budget.
static func face_spec() -> Dictionary:
	var hc := HEAD_C
	return {"center": hc, "radius": HEAD_R, "head_mesh": sphere(HEAD_R, 8, 5), "head_scale": Vector3(0.95, 1.05, 0.95),
		"preset": &"stern", "detail": &"low", "skin": ICE_SKIN, "hair": HAIR, "eyes": Color(0.36, 0.60, 0.80),
		"ears": &"none", "x": NatureFaces.lean_x(1.05),
		"palette": {"lash": Color(0.10, 0.10, 0.14), "brow": HAIR.darkened(0.35), "lip": Color(0.72, 0.52, 0.54)},
		"hair_fn": func(acc: Dictionary) -> void:
			var back := Vector3(0, 0.3, -1.0).normalized()
			# the braid down the back: three overlapping blades
			NatureFaces.blade(acc, hc + Vector3(0, 0.02, -0.12), hc + Vector3(0, -0.14, -0.20), 0.05, 0.02, back, HAIR, HAIR_TIP)
			NatureFaces.blade(acc, hc + Vector3(0, -0.10, -0.18), hc + Vector3(0, -0.28, -0.24), 0.045, 0.02, back, HAIR, HAIR_TIP)
			NatureFaces.blade(acc, hc + Vector3(0, -0.24, -0.22), hc + Vector3(0, -0.42, -0.26), 0.035, 0.018, back, HAIR_TIP, HAIR)
			# two locks framing the face under the cheek guards
			for sx: float in [-1.0, 1.0]:
				NatureFaces.blade(acc, hc + Vector3(0.10 * sx, 0.07, 0.07), hc + Vector3(0.125 * sx, -0.08, 0.06), 0.028, 0.012,
					Vector3(sx, 0, 0.4).normalized(), HAIR, HAIR_TIP),
	}


## The style with coarser decal sampling (budget: the bold RTS face is what the game camera shows).
static func face_style() -> Dictionary:
	var st := FaceKit.style_from(face_spec())
	st["density"] = 5.0
	return st


func _ice_ready() -> void:
	if _face:
		(_face as CreatureFaceRig).set_host(_merged_nodes.get(P_CHEST))
		# the right face for the camera distance from the first frame (no neutral -> far pop when it spawns far away)
		_update_tier()
		_face.auto(self)
	_hammer_q_w = Quaternion(0, 0, 0, 0)
	_update_hammer()


## One authored part from a multi-material sculpt (MountModel's builders), skipped once the pivot's merge is cached.
func _sculpt(pivot: Node3D, key: String, build: Callable) -> void:
	_parts_n += 1
	if _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return
	var mesh := _cached_sculpt(key, build)
	if mesh:
		add_part(pivot, mesh, null, Vector3.ZERO)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	if name.begins_with("fj_"):
		return MountModel.material_at(OWN + name + ".tres")
	return ice(StringName(name))


## Rotation taking +Y onto `d` (robust for d straight down).
static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


## Cylinder / cone from a (radius ra) to b (radius rb).
static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6,
		caps: bool = true) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg, caps), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## Flat slab from a 2D outline (u -> local +Z, v -> local +Y), `thick` along local X, both faces + the rim walls.
static func _slab_mesh(key: String, poly: PackedVector2Array, thick: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := thick * 0.5
	var tri := Geometry2D.triangulate_polygon(poly)
	for i: int in range(0, tri.size(), 3):
		for sx: float in [-1.0, 1.0]:
			var nn := Vector3(sx, 0, 0)
			_emit(st, Vector3(h * sx, poly[tri[i]].y, poly[tri[i]].x), Vector3(h * sx, poly[tri[i + 1]].y, poly[tri[i + 1]].x),
				Vector3(h * sx, poly[tri[i + 2]].y, poly[tri[i + 2]].x), nn)
	var area := 0.0
	for i: int in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	var ccw: float = 1.0 if area > 0.0 else -1.0
	for i: int in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := (q - p).normalized()
		var o := Vector2(e.y, -e.x) * ccw
		var nn := Vector3(0, o.y, o.x)
		_emit(st, Vector3(-h, p.y, p.x), Vector3(h, p.y, p.x), Vector3(h, q.y, q.x), nn)
		_emit(st, Vector3(-h, p.y, p.x), Vector3(h, q.y, q.x), Vector3(-h, q.y, q.x), nn)
	st.index()
	return _cached(key, st.commit())


## One flat-shaded triangle, front face (Godot: clockwise) toward `n`.
static func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(n) > 0.0:
		var t := b
		b = c
		c = t
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


# ---------------------------------------------------------------- body

## Waist, belt, the team tabard flaps (front between the thighs, back over the bear) and the legs ASTRIDE (authored in
## the saddle pose: thighs out and forward round the bear's barrel, greaves down its flanks, sabatons forward).
func _hips_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var leather := m("ice_leather")
	_put(s, cyl(0.26, 0.26, 0.07, 8, false), leather, Vector3(0, 0.955, 0))
	# tabard: front flap forward over the pommel, back flap down over the bear's back (team, a light stripe)
	_put(s, box(Vector3(0.30, 0.40, 0.03)), dark, Vector3(0, 0.78, 0.30), Vector3(-62, 0, 0))
	_put(s, box(Vector3(0.08, 0.40, 0.034)), cloth, Vector3(0, 0.782, 0.302), Vector3(-62, 0, 0))
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.14 * sx, HIP_Y - 0.02, 0.0)
		var knee := Vector3(0.52 * sx, HIP_Y - 0.26, 0.14)
		var ankle := Vector3(0.66 * sx, HIP_Y - 0.62, 0.08)
		_seg(s, steel, hip, knee, 0.115, 0.095, 6, false)
		_put(s, sphere(0.10, 5, 2), metal, knee + Vector3(0.01 * sx, 0.0, 0.02))
		_seg(s, steel, knee, ankle, 0.085, 0.072, 6, false)
		_put(s, box(Vector3(0.13, 0.11, 0.28)), leather, ankle + Vector3(0.0, -0.05, 0.07))


func _chest_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var skin := m("ice_skin")
	var frost := m("ice_frost_crystal")
	# breastplate (lathe, flattened front-back)
	var prof := PackedVector2Array([Vector2(0.21, 0.93), Vector2(0.26, 1.05), Vector2(0.315, 1.24), Vector2(0.30, 1.38),
		Vector2(0.20, 1.50), Vector2(0.08, 1.56), Vector2(0.0, 1.565)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("fjr_torso_v2", prof, 8), Transform3D(Basis.from_scale(Vector3(1.0, 1.0,
		0.84)), Vector3.ZERO), steel)
	# team tabard over the chest, front and back, light stripe
	_put(s, box(Vector3(0.34, 0.44, 0.03)), dark, Vector3(0, 1.17, 0.255), Vector3(-7, 0, 0))
	# the long team cape from the shoulders, falling back over the bear (a light hem)
	# (two panels: from the shoulders down the back, then lying back over the bear's rump)
	_put(s, box(Vector3(0.62, 0.42, 0.035)), dark, Vector3(0, 1.32, -0.31), Vector3(30, 0, 0))
	_put(s, box(Vector3(0.70, 0.58, 0.035)), dark, Vector3(0, 1.05, -0.68), Vector3(68, 0, 0))
	_put(s, box(Vector3(0.72, 0.07, 0.045)), cloth, Vector3(0, 0.95, -0.95), Vector3(68, 0, 0))
	# gorget
	_put(s, cyl(0.13, 0.19, 0.10, 8, false), steel, Vector3(0, 1.555, 0.0))
	# domed pauldrons, light rims, a cyan crystal each
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.19, 7, 3), steel, Vector3(0.42 * sx, 1.45, 0.0), Vector3.ZERO, Vector3(1.25, 0.8, 1.2))
		MountModel.sculpt_crystal(s, frost, Vector3(0.48 * sx, 1.53, -0.02), Vector3(0.6 * sx, 1.0, -0.2), 0.045, 0.20, 0.45)
	# neck + head (the face canvas)
	_put(s, sphere(HEAD_R, 8, 5), skin, HEAD_C, Vector3.ZERO, Vector3(0.95, 1.05, 0.95))
	# open helm: dome, light brim, cheek guards
	var dome := PackedVector2Array([Vector2(0.172, 1.775), Vector2(0.178, 1.83), Vector2(0.166, 1.90), Vector2(0.126, 1.955),
		Vector2(0.055, 1.985), Vector2(0.0, 1.99)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("fjr_helm_v2", dome, 8, false), Transform3D(Basis.IDENTITY,
		Vector3(0, 0, 0.025)), steel)
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.035, 0.15, 0.12)), steel, Vector3(0.158 * sx, 1.69, 0.06), Vector3(0, 12.0 * sx, 0))
	# THE FROSTCROWN: a light circlet with five cyan ice spikes (tallest at the front)
	_put(s, cyl(0.172, 0.182, 0.07, 9, false), metal, Vector3(0, 1.84, 0.025))
	var spikes: Array = [[0.0, 0.25], [55.0, 0.16], [-55.0, 0.16], [130.0, 0.12], [-130.0, 0.12]]
	for sp: Array in spikes:
		var a := deg_to_rad(float(sp[0]))
		var h: float = sp[1]
		var out := Vector3(sin(a), 0, cos(a))
		var dir := (Vector3.UP + out * 0.22).normalized()
		var base := Vector3(0, 1.88, 0.025) + out * 0.17
		MountModel.sculpt_add(s, BEAR.spike_mesh(3), Transform3D(_to_dir(dir).scaled_local(Vector3(0.042, h, 0.042)), base - dir * 0.02),
			frost)


func _arm_l_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var leather := m("ice_leather")
	var frost := m("ice_frost_crystal")
	var elbow := Vector3(-0.39, 1.16, 0.0)
	_seg(s, steel, SH_L, elbow, 0.09, 0.08, 6, false)
	_seg(s, steel, elbow, HAND_L + Vector3(0, 0.05, 0), 0.085, 0.072, 6, false)
	_put(s, sphere(0.08, 6, 2), leather, HAND_L)
	# the tower shield (face -X): steel back, team face, a light team cross, a cyan crystal boss
	var poly := PackedVector2Array()
	var face := PackedVector2Array()
	for p: Vector2 in SHIELD:
		poly.append(p)
		face.append(p * 0.86 + Vector2(0, -0.02))
	MountModel.sculpt_add(s, _slab_mesh("fjr_shield_v1", poly, 0.05), Transform3D(Basis.IDENTITY, SHIELD_C), steel)
	MountModel.sculpt_add(s, _slab_mesh("fjr_shield_face_v1", face, 0.02), Transform3D(Basis.IDENTITY,
		SHIELD_C + Vector3(-0.03, 0, 0)), dark)
	_put(s, box(Vector3(0.022, 0.70, 0.08)), cloth, SHIELD_C + Vector3(-0.045, -0.06, 0))
	_put(s, box(Vector3(0.022, 0.08, 0.44)), cloth, SHIELD_C + Vector3(-0.045, 0.16, 0))
	MountModel.sculpt_crystal(s, frost, SHIELD_C + Vector3(-0.05, 0.16, 0), Vector3(-1, 0, 0), 0.08, 0.17, 0.55)


func _arm_r_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var leather := m("ice_leather")
	var elbow := Vector3(0.39, 1.16, 0.0)
	_seg(s, steel, SH_R, elbow, 0.09, 0.08, 6, false)
	_seg(s, steel, elbow, HAND_R + Vector3(0, 0.05, 0), 0.085, 0.072, 6, false)
	_put(s, sphere(0.08, 6, 2), leather, HAND_R)


## The great war-hammer (keep_separate "Hammer", node-local: the fist at the origin, haft along +Y, striking face +Z).
func _hammer_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var frost := m("ice_frost_crystal")
	var h := Vector3(0, HAMMER_HEAD, 0.02)
	_seg(s, m("ice_wood"), Vector3(0, -0.20, 0), Vector3(0, HAMMER_LEN, 0), 0.036, 0.034, 6, false)
	MountModel.sculpt_add(s, cyl(0.0, 0.055, 0.10, 4), Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.25, 0)), metal)
	_put(s, box(Vector3(0.25, 0.29, 0.44)), steel, h)
	# the ice block on the striking face, the back spike, the glowing frost band, the top spike
	_put(s, box(Vector3(0.21, 0.24, 0.08)), frost, h + Vector3(0, 0, 0.25))
	MountModel.sculpt_add(s, cyl(0.0, 0.08, 0.28, 4), Transform3D(_to_dir(Vector3(0, 0, -1)), h + Vector3(0, 0, -0.35)), steel)
	_put(s, box(Vector3(0.255, 0.05, 0.36)), m("ice_glow_unit"), h + Vector3(0, 0.125, -0.02))
	MountModel.sculpt_crystal(s, frost, h + Vector3(0, 0.14, 0.0), Vector3.UP, 0.055, 0.20, 0.55)


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"great_swing":
		return super._pose_attack(prev, t)
	var sc := swing_scale * DEG
	rot(P_ARM_R, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -140.0, -26.0) * sc, 0,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 6.0, 16.0) * DEG))
	_psi_add += _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -176.0, 86.0)
	_yaw_add += _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 8.0, 40.0)
	rot(P_ARM_L, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 14.0, -20.0) * DEG, 0,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 10.0, -18.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -14.0, 20.0) * DEG,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 26.0, -18.0) * DEG, _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 4.0, -12.0) * DEG))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 0.05, -0.08), _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -0.05, 0.14)))
	if prev < SW_HIT and t >= SW_HIT:
		_on_action_event(&"release")
	return t < SW_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		hammer_struck.emit(get_hammer_head())


## A war-cry salute for any cast: the hammer raised high overhead.
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-130.0 * DEG * k, 0, 14.0 * DEG * k))
	_psi_add += 10.0 * k
	rot(P_CHEST, Vector3(-6.0 * DEG * k, 0, 0))
	return 0.75


## Fidget (standing still): hefts the hammer twice, a look round (the whole upper body turns: no head pivot).
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.25, 1.25, 1.6, 1.0, 1.0)
	var heft: float = absf(sin(clampf((t - 0.2) / 1.0, 0.0, 1.0) * TAU))
	rot(P_ARM_R, Vector3((-16.0 * env - 16.0 * heft * env) * DEG, 0, 0))
	_psi_add += 14.0 * heft * env
	rot(P_CHEST, Vector3(-4.0 * DEG * env, 14.0 * DEG * sin(t * TAU / 1.6) * env, 0))
	return 1.6


func _ice_process(dt: float) -> void:
	if _charge_t < CH_LEN:
		_charge_t += dt
	if _dead:
		_charge_t = 99.0
	if not _rd_on:
		_update_hammer()


## Riding: the kit's seat pose (lean, bob), then the own arms (the kit's reins replaced): the rest pose always on, the
## action offsets written before kept on top; the charge hunker; then the hammer's wrist.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 7.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var rl := REST_L + Vector3(bounce * 0.6, 0, 0)
	var rr := REST_R + Vector3(-bounce, 0, 0)
	var psi: float = HAMMER_REST + (bounce * 0.8 - 12.0 * gallop * moving)
	rl += Vector3(-6.0, 6.0, 4.0) * gallop * moving
	if _charge_t < CH_LEN and not _dead:
		var t := _charge_t
		var env := _k3(t, 0.0, 0.07, 0.40, CH_LEN, 1.0, 1.0)
		var jolt := _k3(t, CH_HIT - 0.02, CH_HIT + 0.03, CH_HIT + 0.05, 0.32, 1.0, 1.0)
		rl += Vector3(-34.0 * env - 14.0 * jolt, 34.0 * env, 18.0 * env)
		rr += Vector3(-70.0 * env, 0, 26.0 * env)
		psi += -40.0 * env
		_roll_add += 12.0 * env
		rot(P_CHEST, Vector3((16.0 * env - 9.0 * jolt) * DEG * w, 0, 0))
	_off_rot[P_ARM_L] = sal + rl * DEG * w
	_off_rot[P_ARM_R] = sar + rr * DEG * w
	_psi_add += (psi - HAMMER_REST) * w
	_update_hammer()


## The wrist: turns the Hammer node so its haft points at angle HAMMER_REST + _psi_add (chest frame, about X) rolled
## outward by _roll_add and yawed by _yaw_add, whatever the arm does. Consumes this frame's additions.
func _update_hammer() -> void:
	var psi: float = HAMMER_REST + _psi_add
	var roll: float = _roll_add
	var yaw: float = _yaw_add
	_psi_add = 0.0
	_roll_add = 0.0
	_yaw_add = 0.0
	if _dead:
		psi = HAMMER_REST
		roll = 0.0
		yaw = 0.0
	if _hammer == null:
		return
	var want := Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.BACK, -roll * DEG) * Basis(Vector3.RIGHT, psi * DEG)
	var arm := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]) if _piv[P_ARM_R] else Basis.IDENTITY
	var q := (arm.inverse() * want).get_rotation_quaternion()
	if not q.is_equal_approx(_hammer_q_w):
		_hammer_q_w = q
		_hammer.quaternion = q


func _ice_revive() -> void:
	_charge_t = 99.0
	_psi_add = 0.0
	_roll_add = 0.0
	_yaw_add = 0.0
	_hammer_q_w = Quaternion(0, 0, 0, 0)
	_update_hammer()
