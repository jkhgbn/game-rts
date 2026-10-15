extends IceModel
## Snowdrift Rider rider (stables.md 2 slot Z, the Ice tier-1 armoured scout / raider): a sabre scout on the Snowdrift
## cat (snowdrift_cat.gd). Seated with the kit's set_seated (13.V1b); snowdrift_rider.tscn pairs the two.
## Look: STEEL-BLUE LAMELLAR (ice_steel with two light bands) under a TEAM TABARD (ice_cloth_dark, a light ice_cloth
## stripe) and a short TEAM CAPE over the cat's back, a shaggy dark fur collar, small steel pauldrons, dark leather
## breeches, steel greaves, fur-cuffed boots; a WINGED STEEL HELM (two swept-back pale steel wings tipped with cyan ice:
## the crest, the only near-white) with a nasal, an open face (FaceKit: sharp grey-blue eyes, lips) and a dark braid.
## Glow points: a frost gem on the helm brow and the sabre's glowing cyan edge.
## Right hand: the FROST SABRE (merged in the arm): a long curved steel blade with a glowing cyan edge,
## a steel guard; carried levelled forward, ready to cut.
## Rank 3 (Stables16 "Snowdrift Captain", set_rank_look(true)): the "RankCrest" = a tall team pennant on a pole behind
## the shoulders with a cyan crystal finial (a captain's standard) instead of the kit's placeholder ring.
## Attack (`mounted_slash`, 0.55 s, strike at SLASH_HIT 0.14 s = event `release` + signal sabre_struck): the torso coils
## and the sabre rises high behind the head (0.09 s), then a diagonal cut down the right front of the cat (the chest
## uncoils, a lean into it), a follow-through and the recovery.
## Charge (play_charge_pose(), 0.85 s, impact 0.10 s): a low crouch with the sabre thrust forward.
## Fidget (IceModel, standing still): twirls the sabre and looks round. Cast: the sabre raised high.
## Death: freezes over and SHATTERS (IceModel, 8 shards) while riding the cat's roll.
## Pivots: Root / Hips (legs astride in the hips mesh) / Chest (head + face drawn INSIDE the merged chest, CreatureFaceRig
## host mode) / ArmL / ArmR (the sabre merged). With the cat (tail pivot included): 12 draws.
## Hooks (on top of the kit's / IceModel's): play_charge_pose(), set_rank_look(on), get_sabre_tip() -> Vector3 (world),
## authored_mesh_count() -> int; signal sabre_struck(at: Vector3).

signal sabre_struck(at: Vector3)

const CAT := preload("res://art/units/ice/snowdrift_rider/parts/snowdrift_cat.gd")

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.86
const SH_L := Vector3(-0.31, 1.40, 0.0)
const SH_R := Vector3(0.31, 1.40, 0.0)
const HAND_L := Vector3(-0.32, 0.84, 0.02)
const HAND_R := Vector3(0.32, 0.84, 0.02)
const HEAD_C := Vector3(0, 1.66, 0.04)
const HEAD_R := 0.145
const HAIR := Color(0.16, 0.16, 0.22)
const HAIR_TIP := Color(0.30, 0.34, 0.46)
## The sabre, in the (hanging) right arm's frame: from the fist along SABRE_DIR (so it lies level forward when the
## arm is raised ~55 deg), curving back toward SABRE_BACK.
const SABRE_DIR := Vector3(0, -0.8, 0.6)
const SABRE_BACK := Vector3(0, 0.6, 0.8)
const SABRE_LEN := 0.86
## Riding rest pose of the arms (deg): the left hand on the reins, the sabre arm raised so the blade lies level forward.
const REST_L := Vector3(-34.0, 0.0, 10.0)
const REST_R := Vector3(-50.0, 0.0, 20.0)
const SLASH_HIT := 0.14
const SLASH_LEN := 0.55
const CH_HIT := 0.10
const CH_LEN := 0.85
static var T_ARM_X := PackedFloat32Array([0.0, -50.0, 0, 0.09, -168.0, 1, 0.14, -58.0, 2, 0.26, -18.0, 0, 0.55, -50.0, 0])
static var T_ARM_Z := PackedFloat32Array([0.0, 20.0, 0, 0.09, 38.0, 1, 0.14, -8.0, 2, 0.26, -22.0, 0, 0.55, 20.0, 0])
static var T_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.09, -24.0, 1, 0.14, 20.0, 2, 0.30, 8.0, 0, 0.55, 0.0, 0])
static var T_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.09, -8.0, 1, 0.14, 14.0, 2, 0.30, 5.0, 0, 0.55, 0.0, 0])
static var T_ARM_L := PackedFloat32Array([0.0, -34.0, 0, 0.09, -20.0, 1, 0.14, -52.0, 2, 0.30, -40.0, 0, 0.55, -34.0, 0])

var _parts_n: int = 0
var _crest: MeshInstance3D
var _charge_t: float = 99.0


# ================================================================ public hooks

func play_charge_pose() -> void:
	if _dead:
		return
	_charge_t = 0.0
	set_process(true)


## Rank-3 look (Stables16 "Snowdrift Captain"): the captain's standard behind the shoulders ("RankCrest").
func set_rank_look(on: bool) -> void:
	if _crest:
		_crest.visible = on


## World position of the sabre tip (the strike point).
func get_sabre_tip() -> Vector3:
	var arm := _piv[P_ARM_R] if _piv.size() > P_ARM_R else null
	if arm and arm.is_inside_tree():
		return arm.global_transform * (HAND_R - model_origin(arm) + SABRE_DIR * SABRE_LEN)
	return global_position + Vector3.UP * 1.8


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	_sculpt($Root/Hips, "sdr_hips_v1", _hips_sculpt)
	_sculpt(chest, "sdr_chest_v1", _chest_sculpt)
	_face = CreatureFaceRig.attach(self, chest, "snowdrift_scout", face_style())
	_sculpt($Root/Chest/ArmL, "sdr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "sdr_arm_r_v1", _arm_r_sculpt)
	# the rank-3 captain's standard (hidden until set_rank_look(true))
	_parts_n += 1
	_crest = add_part(chest, _cached_sculpt("sdr_crest_v1", _crest_sculpt), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE,
		true, "RankCrest")
	if _crest:
		_crest.visible = false
		_crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_parts_n += 1
	var trim := add_part(chest, cyl(0.17, 0.17, 0.035, 8, false), palette(&"unit_gold_trim"), Vector3(0, 1.77, 0.03),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	_shatter = _shards(8, 0.9, 0.3, 1.6, 3.4, 180.0, Vector3.UP, 0.10)
	_shatter.name = "Shatter"
	_shatter.position = Vector3(0, 1.18, 0.04) - model_origin(chest)
	chest.add_child(_shatter)


## A sharp-eyed scout: grey-blue eyes, a dark braid down the back and two short locks under the helm (cheap blades),
## no ears (the helm's cheek plates cover them).
static func face_spec() -> Dictionary:
	var hc := HEAD_C
	return {"center": hc, "radius": HEAD_R, "head_mesh": sphere(HEAD_R, 8, 5), "head_scale": Vector3(0.95, 1.05, 0.95),
		"preset": &"plain", "detail": &"low", "skin": ICE_SKIN, "hair": HAIR, "eyes": Color(0.42, 0.56, 0.72),
		"ears": &"none", "x": NatureFaces.lean_x(1.05),
		"palette": {"lash": Color(0.08, 0.08, 0.12), "brow": HAIR.darkened(0.1), "lip": Color(0.70, 0.50, 0.52)},
		"hair_fn": func(acc: Dictionary) -> void:
			var back := Vector3(0, 0.25, -1.0).normalized()
			NatureFaces.blade(acc, hc + Vector3(0, 0.0, -0.13), hc + Vector3(0.01, -0.17, -0.20), 0.045, 0.02, back, HAIR, HAIR_TIP)
			NatureFaces.blade(acc, hc + Vector3(0.01, -0.13, -0.18), hc + Vector3(0.02, -0.30, -0.22), 0.035, 0.016, back, HAIR_TIP, HAIR)
			for sx: float in [-1.0, 1.0]:
				NatureFaces.blade(acc, hc + Vector3(0.105 * sx, 0.06, 0.06), hc + Vector3(0.125 * sx, -0.07, 0.06), 0.03, 0.012,
					Vector3(sx, 0, 0.4).normalized(), HAIR, HAIR_TIP),
	}


static func face_style() -> Dictionary:
	var st := FaceKit.style_from(face_spec())
	st["density"] = 5.0
	return st


func _ice_ready() -> void:
	if _face:
		(_face as CreatureFaceRig).set_host(_merged_nodes.get(P_CHEST))
		_update_tier()
		_face.auto(self)


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
	return ice(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6,
		caps: bool = false) -> void:
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
			_emit(st, Vector3(h * sx, poly[tri[i]].y, poly[tri[i]].x), Vector3(h * sx, poly[tri[i + 1]].y, poly[tri[i + 1]].x),
				Vector3(h * sx, poly[tri[i + 2]].y, poly[tri[i + 2]].x), Vector3(sx, 0, 0))
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


## Keyframe track [t, v, ease, ...] from t = 0; ease of the segment arriving at a key: 0 smooth, 1 ease-out, 2 ease-in.
static func _kf(t: float, k: PackedFloat32Array) -> float:
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


# ---------------------------------------------------------------- body

## Lamellar skirt, the team tabard flap and the legs ASTRIDE the cat (authored in the saddle pose).
func _hips_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var leather := m("ice_leather")
	var fur := m("ice_fur")
	_put(s, cyl(0.215, 0.27, 0.22, 8, false), steel, Vector3(0, 0.83, 0))
	_put(s, cyl(0.225, 0.225, 0.06, 8, false), leather, Vector3(0, 0.93, 0))
	_put(s, soft_box(Vector3(0.26, 0.36, 0.03)), dark, Vector3(0, 0.80, 0.29), Vector3(-60, 0, 0))
	_put(s, soft_box(Vector3(0.07, 0.36, 0.034)), cloth, Vector3(0, 0.802, 0.292), Vector3(-60, 0, 0))
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.12 * sx, HIP_Y - 0.03, 0.0)
		var knee := Vector3(0.36 * sx, HIP_Y - 0.25, 0.17)
		var ankle := Vector3(0.43 * sx, HIP_Y - 0.57, 0.08)
		_seg(s, leather, hip, knee, 0.095, 0.075)
		_put(s, sphere(0.08, 5, 2), steel, knee + Vector3(0.0, 0.0, 0.02))
		_seg(s, steel, knee, ankle, 0.072, 0.06)
		_put(s, cyl(0.075, 0.085, 0.07, 6, false), fur, ankle + Vector3(0, 0.03, 0))
		_put(s, soft_box(Vector3(0.115, 0.10, 0.26)), leather, ankle + Vector3(0.0, -0.04, 0.06))


func _chest_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var fur := m("ice_fur")
	var skin := m("ice_skin")
	var frost := m("ice_frost_crystal")
	# lamellar coat (lathe, flattened) with two light lames
	var prof := PackedVector2Array([Vector2(0.19, 0.90), Vector2(0.23, 1.02), Vector2(0.27, 1.18), Vector2(0.275, 1.29),
		Vector2(0.24, 1.38), Vector2(0.13, 1.46), Vector2(0.0, 1.48)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("sdr_torso_v1", prof, 8), Transform3D(Basis.from_scale(Vector3(1.0, 1.0,
		0.82)), Vector3.ZERO), steel)
	for y: float in [1.06, 1.20]:
		MountModel.sculpt_add(s, cyl(0.262, 0.262, 0.025, 8, false), Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.84)),
			Vector3(0, y, 0)), metal)
	# team tabard front / back, light stripe; a short team cape over the cat's back (a light hem)
	_put(s, soft_box(Vector3(0.28, 0.42, 0.03)), dark, Vector3(0, 1.14, 0.235), Vector3(-6, 0, 0))
	_put(s, soft_box(Vector3(0.07, 0.42, 0.034)), cloth, Vector3(0, 1.14, 0.247), Vector3(-6, 0, 0))
	_put(s, soft_box(Vector3(0.52, 0.56, 0.03)), dark, Vector3(0, 1.16, -0.36), Vector3(40, 0, 0))
	_put(s, soft_box(Vector3(0.53, 0.06, 0.035)), cloth, Vector3(0, 0.95, -0.54), Vector3(40, 0, 0))
	# a shaggy dark fur collar, small steel pauldrons
	MountModel.sculpt_fringe(s, fur, MountModel.fringe_mesh("sdr_collar_v1", 0.14, 0.13, 0.30, 0.26, 0.14, 0.0, 360.0, 7,
		0.07, 0.025, 0.6), Vector3(0, 1.49, -0.01))
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.15, 6, 3), steel, Vector3(0.33 * sx, 1.40, 0.0), Vector3(0, 0, -16.0 * sx), Vector3(1.15, 0.72, 1.1))
	# neck + head (the face canvas)
	_put(s, cyl(0.065, 0.075, 0.12, 6, false), skin, Vector3(0, 1.53, 0.03))
	_put(s, sphere(HEAD_R, 8, 5), skin, HEAD_C, Vector3.ZERO, Vector3(0.95, 1.05, 0.95))
	# the winged helm: dome, nasal, cheek plates, two swept-back pale steel wings tipped with cyan ice
	var dome := PackedVector2Array([Vector2(0.168, 1.70), Vector2(0.172, 1.76), Vector2(0.158, 1.84), Vector2(0.11, 1.90),
		Vector2(0.04, 1.925), Vector2(0.0, 1.93)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("sdr_helm_v1", dome, 8, false), Transform3D(Basis.IDENTITY,
		Vector3(0, 0, 0.02)), steel)
	_put(s, soft_box(Vector3(0.035, 0.12, 0.03)), metal, Vector3(0, 1.69, 0.19), Vector3(-8, 0, 0))
	# a glowing frost gem on the helm brow (the high glow point)
	MountModel.sculpt_crystal(s, m("ice_glow_unit"), Vector3(0, 1.765, 0.17), Vector3(0, 0.55, 1.0), 0.032, 0.08, 0.55)
	for sx: float in [-1.0, 1.0]:
		_put(s, soft_box(Vector3(0.03, 0.13, 0.11)), steel, Vector3(0.155 * sx, 1.64, 0.05), Vector3(0, 14.0 * sx, 0))
		# a swept-back feathered wing: three feather points trailing behind the helm
		var wing := PackedVector2Array([Vector2(0.07, -0.02), Vector2(0.02, 0.07), Vector2(-0.10, 0.15), Vector2(-0.30, 0.19),
			Vector2(-0.22, 0.12), Vector2(-0.33, 0.10), Vector2(-0.22, 0.05), Vector2(-0.30, 0.00), Vector2(-0.12, -0.02)])
		MountModel.sculpt_add(s, _slab_mesh("sdr_wing_v2", wing, 0.025), Transform3D(Basis(Vector3.UP, deg_to_rad(34.0 * sx))
			* Basis(Vector3.BACK, deg_to_rad(-26.0 * sx)), Vector3(0.162 * sx, 1.79, 0.02)), metal)
		MountModel.sculpt_add(s, CAT.spike_mesh(3), Transform3D(_to_dir(Vector3(0.35 * sx, 0.35, -0.87)).scaled_local(
			Vector3(0.028, 0.12, 0.028)), Vector3(0.22 * sx, 1.92, -0.26)), frost)


func _arm_l_sculpt(s: Dictionary) -> void:
	var leather := m("ice_leather")
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var elbow := SH_L + Vector3(-0.01, -0.28, 0)
	_seg(s, dark, SH_L, elbow, 0.075, 0.066)
	_seg(s, steel, elbow, HAND_L + Vector3(0, 0.05, 0), 0.068, 0.058)
	_put(s, sphere(0.066, 5, 2), leather, HAND_L)


## The sabre arm and the FROST SABRE (merged): a curved steel blade with a glowing cyan edge, a steel guard, a
## leather grip and a pommel.
func _arm_r_sculpt(s: Dictionary) -> void:
	var leather := m("ice_leather")
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var elbow := SH_R + Vector3(0.01, -0.28, 0)
	_seg(s, dark, SH_R, elbow, 0.075, 0.066)
	_seg(s, steel, elbow, HAND_R + Vector3(0, 0.05, 0), 0.068, 0.058)
	_put(s, sphere(0.066, 5, 2), leather, HAND_R)
	# the blade outline in its own (L along SABRE_DIR, W along SABRE_BACK) frame, curving back toward the tip
	var d := SABRE_DIR.normalized()
	var bk := SABRE_BACK.normalized()
	var outline: Array[Vector2] = [Vector2(0.0, -0.030), Vector2(0.30, -0.040), Vector2(0.60, -0.036), Vector2(0.78, -0.016),
		Vector2(SABRE_LEN, 0.03), Vector2(0.76, 0.050), Vector2(0.50, 0.052), Vector2(0.20, 0.042), Vector2(0.0, 0.034)]
	var poly := PackedVector2Array()
	for q: Vector2 in outline:
		var w := q.y + 0.07 * pow(q.x / SABRE_LEN, 2.0)
		var p := d * q.x + bk * w
		poly.append(Vector2(p.z, p.y))
	MountModel.sculpt_add(s, _slab_mesh("sdr_blade_v1", poly, 0.022), Transform3D(Basis.IDENTITY, HAND_R), steel)
	# the glowing frost edge along the cutting side
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for i: int in 4:
		var l := 0.10 + 0.22 * float(i)
		var w := -0.036 + 0.07 * pow(l / SABRE_LEN, 2.0) - 0.004
		pts.append(HAND_R + d * l + bk * w)
		rad.append(0.019 if i < 3 else 0.0)
	MountModel.sculpt_add(s, MountModel.tube_mesh("sdr_edge_v1", pts, rad, 4), Transform3D.IDENTITY, m("ice_glow_unit"))
	# guard, grip, pommel
	MountModel.sculpt_add(s, soft_box(Vector3(0.20, 0.035, 0.045)), Transform3D(_to_dir(d), HAND_R + d * 0.02), metal)
	_seg(s, leather, HAND_R - d * 0.02, HAND_R - d * 0.13, 0.024, 0.022, 5)
	MountModel.sculpt_add(s, sphere(0.032, 5, 2), Transform3D(Basis.IDENTITY, HAND_R - d * 0.15), metal)


## The captain's standard (keep_separate "RankCrest", model space): a pole behind the right shoulder, a long team
## pennant streaming back (ice_cloth, a light / dark split) and a cyan crystal finial.
func _crest_sculpt(s: Dictionary) -> void:
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var frost := m("ice_frost_crystal")
	var base := Vector3(0.16, 1.02, -0.24)
	var top := Vector3(0.18, 2.34, -0.34)
	_seg(s, m("ice_wood"), base, top, 0.02, 0.018, 5)
	MountModel.sculpt_crystal(s, frost, top, (top - base).normalized(), 0.04, 0.18, 0.55)
	var pen := PackedVector2Array([Vector2(0.0, 0.0), Vector2(-0.62, -0.10), Vector2(0.0, -0.30)])
	MountModel.sculpt_add(s, _slab_mesh("sdr_pennant_v1", pen, 0.015), Transform3D(Basis.IDENTITY, top - Vector3(0, 0.04, 0)),
		cloth)
	var pen2 := PackedVector2Array([Vector2(0.0, -0.30), Vector2(-0.62, -0.10), Vector2(-0.40, -0.34)])
	MountModel.sculpt_add(s, _slab_mesh("sdr_pennant2_v1", pen2, 0.015), Transform3D(Basis.IDENTITY, top - Vector3(0, 0.04, 0)),
		dark)


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"mounted_slash":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3((_kf(t, T_ARM_X) - REST_R.x) * DEG, 0, (_kf(t, T_ARM_Z) - REST_R.z) * DEG))
	rot(P_ARM_L, Vector3((_kf(t, T_ARM_L) - REST_L.x) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, T_LEAN) * DEG, _kf(t, T_YAW) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, 0.08 * _kf(t, T_LEAN) / 14.0))
	if prev < SLASH_HIT and t >= SLASH_HIT:
		_on_action_event(&"release")
	return t < SLASH_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		sabre_struck.emit(get_sabre_tip())


func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-100.0 * DEG * k, 0, 10.0 * DEG * k))
	return 0.75


## Fidget (standing still): twirls the sabre (the forearm rolls it round) and looks round.
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.2, 1.1, 1.4, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-18.0 * DEG * env * sin(t * TAU * 1.8), 70.0 * DEG * env * sin(t * TAU * 1.8), 0))
	rot(P_CHEST, Vector3(0, 18.0 * DEG * sin(t * TAU / 1.4) * env, 0))
	return 1.4


func _ice_process(dt: float) -> void:
	if _charge_t < CH_LEN:
		_charge_t += dt
	if _dead:
		_charge_t = 99.0


## Riding: the kit's seat pose (lean, bob), then the own arms (rest pose + the action offsets written before); the
## charge crouch with the sabre thrust forward.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 7.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var rl := REST_L + Vector3(bounce, 0, 0)
	var rr := REST_R + Vector3(-bounce * 0.6 - 10.0 * gallop * moving, 0, 0)
	if _charge_t < CH_LEN and not _dead:
		var t := _charge_t
		var env := _k3(t, 0.0, 0.07, 0.40, CH_LEN, 1.0, 1.0)
		var jolt := _k3(t, CH_HIT - 0.02, CH_HIT + 0.03, CH_HIT + 0.05, 0.32, 1.0, 1.0)
		rr += Vector3(-35.0 * env, 0, -12.0 * env)
		rl += Vector3(-10.0 * env, 0, 0)
		rot(P_CHEST, Vector3((18.0 * env - 8.0 * jolt) * DEG * w, 0, 0))
	_off_rot[P_ARM_L] = sal + rl * DEG * w
	_off_rot[P_ARM_R] = sar + rr * DEG * w


func _ice_revive() -> void:
	_charge_t = 99.0
