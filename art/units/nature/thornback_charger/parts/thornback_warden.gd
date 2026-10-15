extends NatureWarModel
## Thornback Charger rider (stables.md 2 slot C, the Nature tier-2 line breaker; rank 3 "Thornback Warden"): a heavy
## thorn lancer on the Thornback elk (thornback_elk.gd). Seated with the kit's set_seated (13.V1b);
## thornback_charger.tscn pairs the two.
## Look: a burly rider in BARK LAMELLAR (nature_bark with dark bands), a TEAM TABARD with a dark team stripe (the value
## step inside the team colour) and a short team cape over the elk's back, a PALE MOSS MANTLE over the shoulders and a
## bark half-helm crested with two short PALE ANTLER TINES (the pale cap), bark pauldrons with thorns, dark leggings
## and boots. Face (FaceKit): amber eyes, lips, a chestnut beard and sideburns (blades), pointed leaf ears.
## Left arm: a tall WICKER KITE SHIELD (pale straw with a bark rim, a team leaf emblem, a thorn boss).
## Right hand: the THORN LANCE (own node "Lance" at the fist, turned by the wrist): a 2.3 m bark shaft wrapped with a
## vine, a big thorn head, a glowing green seed at the socket (the glow point) and a TEAM PENNANT under the head.
## Carried angled forward (ready); lowered level at the gallop.
## Rank 3 (Stables16 "Thornback Warden", set_rank_look(true)): the "RankCrest" = a tall warden's standard behind the
## shoulders: a leaf-shaped team banner with a straw hem and a glowing blossom finial.
## Attack (`lance_thrust`, 0.6 s, strike THRUST_HIT 0.14 s = event `release` + signal lance_struck): the lance drops
## level and draws back (0.07 s), then drives forward with the whole body behind it (the chest uncoils, a lean in),
## holds and rises back to the carry.
## Charge (play_charge_pose(), 0.85 s, impact 0.10 s): a low crouch behind the shield, the lance couched level.
## Fidget (standing still): lifts the lance and looks round. Cast: the lance raised high.
## Death: "return to the grove" (the life flash, a burst of straw-gold leaves) riding the elk's roll.
## Pivots: Root / Hips (legs astride in the hips mesh) / Chest (head, helm and face INSIDE the merged chest,
## CreatureFaceRig host mode) / ArmL (the shield merged) / ArmR, + Lance (keep_separate). With the elk: 12 draws.
## Hooks (on top of the kit's): play_charge_pose(), set_rank_look(on), get_lance_tip() -> Vector3 (world),
## authored_mesh_count() -> int; signal lance_struck(at: Vector3).

signal lance_struck(at: Vector3)

const ELK := preload("res://art/units/nature/thornback_charger/parts/thornback_elk.gd")
const DRAPE := preload("res://art/units/nature/nature_drape.gd")   # G-E fixes D: draped cloth panels
const ANTLER := "res://art/units/mounts/grove_stag/materials/grove_stag_antler.tres"

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.90
const SH_L := Vector3(-0.34, 1.43, 0.0)
const SH_R := Vector3(0.34, 1.43, 0.0)
const HAND_L := Vector3(-0.36, 0.90, 0.02)
const HAND_R := Vector3(0.36, 0.90, 0.02)
const HEAD_C := Vector3(0, 1.72, 0.05)
const HEAD_R := 0.15
const SHIELD_C := Vector3(-0.52, 1.00, 0.04)
const SHIELD: Array[Vector2] = [Vector2(-0.24, 0.40), Vector2(0.24, 0.40), Vector2(0.28, 0.30), Vector2(0.26, -0.08),
	Vector2(0.0, -0.46), Vector2(-0.26, -0.08), Vector2(-0.28, 0.30)]
## The lance (node-local, origin = the fist): along +Y from LANCE_BUTT to LANCE_TIP.
const LANCE_BUTT := -0.70
const LANCE_TIP := 1.62
const REST_L := Vector3(-28.0, 20.0, -36.0)
const REST_R := Vector3(-24.0, 0.0, 14.0)
## The lance's rest angle in the chest frame (deg about X: 0 = up, + = tip toward the front).
const LANCE_REST := 55.0
const THRUST_HIT := 0.14
const THRUST_LEN := 0.6
const CH_HIT := 0.10
const CH_LEN := 0.85
static var T_ARM_X := PackedFloat32Array([0.0, -24.0, 0, 0.07, -8.0, 1, 0.14, -78.0, 2, 0.30, -60.0, 0, 0.6, -24.0, 0])
static var T_ARM_Z := PackedFloat32Array([0.0, 14.0, 0, 0.07, 24.0, 1, 0.14, 8.0, 2, 0.6, 14.0, 0])
static var T_PSI := PackedFloat32Array([0.0, 55.0, 0, 0.07, 86.0, 1, 0.14, 90.0, 0, 0.30, 88.0, 0, 0.6, 55.0, 0])
static var T_DYAW := PackedFloat32Array([0.0, 0.0, 0, 0.07, 4.0, 1, 0.14, -8.0, 2, 0.6, 0.0, 0])
static var T_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.07, -16.0, 1, 0.14, 14.0, 2, 0.30, 6.0, 0, 0.6, 0.0, 0])
static var T_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -6.0, 1, 0.14, 16.0, 2, 0.30, 8.0, 0, 0.6, 0.0, 0])

var _parts_n: int = 0
var _lance: MeshInstance3D
var _crest: MeshInstance3D
var _lance_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _lance_glow_w: float = -1.0
var _psi_add: float = 0.0
var _dyaw_add: float = 0.0
var _charge_t: float = 99.0


# ================================================================ public hooks

func play_charge_pose() -> void:
	if _dead:
		return
	_charge_t = 0.0
	set_process(true)


## Rank-3 look (Stables16 "Thornback Warden"): the warden's standard behind the shoulders ("RankCrest").
func set_rank_look(on: bool) -> void:
	if _crest:
		_crest.visible = on


func get_lance_tip() -> Vector3:
	if _lance and _lance.is_inside_tree():
		return _lance.global_transform * Vector3(0, LANCE_TIP, 0)
	return global_position + Vector3.UP * 2.0


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	_sculpt($Root/Hips, "tbr_hips_v1", _hips_sculpt)
	_sculpt(chest, "tbr_chest_v1", _chest_sculpt)
	_face = CreatureFaceRig.attach(self, chest, "thornback_warden", face_style())
	_sculpt($Root/Chest/ArmL, "tbr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "tbr_arm_r_v1", _arm_r_sculpt)
	_parts_n += 1
	_lance = add_part($Root/Chest/ArmR, _cached_sculpt("tbr_lance_v1", _lance_sculpt), null, HAND_R, Vector3.ZERO,
		Vector3.ONE, true, "Lance")
	if _lance:
		_lance.set_meta(&"own_glow", true)
	_parts_n += 1
	_crest = add_part(chest, _cached_sculpt("tbr_crest_v1", _crest_sculpt), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE,
		true, "RankCrest")
	if _crest:
		_crest.visible = false
		_crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_parts_n += 1
	var trim := add_part(chest, cyl(0.19, 0.19, 0.035, 9, false), palette(&"unit_gold_trim"), Vector3(0, 1.80, 0.04),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	var lv := make_petals(Color(0.72, 0.62, 0.34), 12, 1.0, 0.45, 1.5, 0.16, true)
	lv.name = "DeathLeaves"
	lv.set_meta(&"death_fx", true)
	lv.position = Vector3(0, 1.20, 0.0)
	$Fx.add_child(lv)


## Amber eyes, a chestnut beard and sideburns, pointed leaf ears out under the helm, a short fringe (cheap blades).
static func face_spec() -> Dictionary:
	var hc := HEAD_C
	var r := HEAD_R
	return {"center": hc, "radius": r, "head_mesh": sphere(r, 8, 5), "head_scale": Vector3(0.96, 1.04, 0.96),
		"preset": &"stern", "detail": &"low", "skin": NatureFaces.SKIN, "hair": NatureFaces.CHESTNUT,
		"hair_tip": NatureFaces.CHESTNUT_TIP, "eyes": NatureFaces.EYE_AMBER,
		"x": NatureFaces.lean_x(1.05), "palette": NatureFaces.pal(NatureFaces.CHESTNUT),
		"hair_fn": func(acc: Dictionary) -> void:
			for sx: float in [-1.0, 1.0]:
				NatureFaces.ear_leaf(acc, hc, r, sx, NatureFaces.SKIN, 0.55, 0.30, 0.25)
				# the beard: blades from the jaw line down onto the chest, and the sideburns
				NatureFaces.blade(acc, hc + Vector3(0.10 * sx, -0.05, 0.08), hc + Vector3(0.09 * sx, -0.20, 0.12), 0.035, 0.015,
					Vector3(sx, 0.0, 0.6).normalized(), NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP)
				NatureFaces.blade(acc, hc + Vector3(0.05 * sx, -0.10, 0.12), hc + Vector3(0.04 * sx, -0.27, 0.15), 0.035, 0.015,
					Vector3(0.4 * sx, -0.1, 1.0).normalized(), NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP)
			NatureFaces.blade(acc, hc + Vector3(0.0, -0.12, 0.13), hc + Vector3(0.0, -0.31, 0.16), 0.04, 0.016,
				Vector3(0.0, -0.1, 1.0).normalized(), NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP)
			NatureFaces.fringe(acc, hc, r, 2, NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP, 0.5, 0.5, 0.26),
	}


static func face_style() -> Dictionary:
	var st := FaceKit.style_from(face_spec())
	st["density"] = 5.0
	return st


func _war_ready() -> void:
	if _face:
		(_face as CreatureFaceRig).set_host(_merged_nodes.get(P_CHEST))
		_update_tier()
		_face.auto(self)
	_lance_q_w = Quaternion(0, 0, 0, 0)
	_update_lance()


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
	if name == "antler":
		return MountModel.material_at(ANTLER)
	return nature(StringName(name))


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


static func _leaf(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, nrm: Vector3, size: Vector3) -> void:
	var z := dir.normalized()
	var y := nrm - z * nrm.dot(z)
	if y.length_squared() < 1e-6:
		y = Vector3.UP - z * z.y
	y = y.normalized()
	var x := y.cross(z)
	MountModel.sculpt_add(s, leaf_mesh(), Transform3D(Basis(x * size.x, y * size.y, z * size.z), base + z * size.z * 0.5), mat)


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


# ---------------------------------------------------------------- body

## Bark tassets, the team tabard flap, the legs ASTRIDE the elk (saddle pose): dark leggings, bark greaves, boots.
func _hips_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var leg := m("nature_leaf_dark")
	_put(s, cyl(0.24, 0.29, 0.22, 8, false), bark, Vector3(0, 0.87, 0))
	_put(s, cyl(0.25, 0.25, 0.07, 8, false), dark, Vector3(0, 0.96, 0))
	# G-E fixes D: the tabard flap is a draped panel (wrap, two folds, a leaf-point hem), the stripe follows it
	_put(s, DRAPE.panel("tbr_flap_v1", 0.30, 0.25, 0.36, 0.035, 0.0, 2.0, 0.018, 0.07, 0.015, 0.02),
		cloth, Vector3(0, 0.80, 0.31), Vector3(-60, 0, 0))
	_put(s, DRAPE.panel("tbr_flap_stripe_v1", 0.30, 0.25, 0.36, 0.035, 0.0, 2.0, 0.018, 0.07, 0.015, 0.02,
		Rect2(-0.3, 0.0, 0.6, 1.0), 0.006, 1), cdark, Vector3(0, 0.80, 0.31), Vector3(-60, 0, 0))
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.13 * sx, HIP_Y - 0.03, 0.0)
		var knee := Vector3(0.50 * sx, HIP_Y - 0.25, 0.16)
		var ankle := Vector3(0.60 * sx, HIP_Y - 0.60, 0.08)
		_seg(s, leg, hip, knee, 0.11, 0.09)
		_put(s, sphere(0.09, 5, 2), bark, knee + Vector3(0.0, 0.0, 0.03))
		_seg(s, bark, knee, ankle, 0.085, 0.072)
		_put(s, box(Vector3(0.13, 0.11, 0.28)), dark, ankle + Vector3(0.0, -0.05, 0.07))


func _chest_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var moss := m("nature_moss")
	var skin := m("nature_skin")
	var thorn := m("nature_thorn")
	var ant := m("antler")
	# bark lamellar torso (lathe, flattened), two dark bands
	var prof := PackedVector2Array([Vector2(0.23, 0.93), Vector2(0.27, 1.04), Vector2(0.32, 1.20), Vector2(0.325, 1.31),
		Vector2(0.29, 1.41), Vector2(0.17, 1.50), Vector2(0.0, 1.53)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("tbr_torso_v1", prof, 8), Transform3D(Basis.from_scale(Vector3(1.0, 1.0,
		0.82)), Vector3.ZERO), bark)
	for y: float in [1.08, 1.24]:
		MountModel.sculpt_add(s, cyl(0.31, 0.31, 0.03, 8, false), Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.84)),
			Vector3(0, y, 0)), dark)
	# team tabard front (a dark team stripe: the value step), a short team cape over the elk's back
	# G-E fixes D: draped panels instead of boxes (the tabard wraps the chest, the cape flares over the elk's back with
	# three folds and a scalloped hem; each stripe follows its panel)
	_put(s, DRAPE.panel("tbr_tabard_v1", 0.32, 0.30, 0.40, 0.05, 0.0, 2.0, 0.015, 0.06, 0.0, 0.02),
		cloth, Vector3(0, 1.17, 0.255), Vector3(-6, 0, 0))
	_put(s, DRAPE.panel("tbr_tabard_stripe_v1", 0.32, 0.30, 0.40, 0.05, 0.0, 2.0, 0.015, 0.06, 0.0, 0.02,
		Rect2(-0.3, 0.0, 0.6, 1.0), 0.006, 1), cdark, Vector3(0, 1.17, 0.255), Vector3(-6, 0, 0))
	_put(s, DRAPE.panel("tbr_cape_v3", 0.44, 0.64, 0.50, -0.12, -0.03, 3.0, 0.06, 0.05, 0.05, 0.02),
		cloth, Vector3(0, 1.20, -0.35), Vector3(38, 0, 0))
	_put(s, DRAPE.panel("tbr_cape_stripe_v3", 0.44, 0.64, 0.50, -0.12, -0.03, 3.0, 0.06, 0.05, 0.05, 0.02,
		Rect2(-0.24, 0.0, 0.48, 1.0), -0.028, -1), cdark, Vector3(0, 1.20, -0.35), Vector3(38, 0, 0))
	# the pale moss mantle over the shoulders (the pale shoulder read), bark pauldrons with two thorns each
	MountModel.sculpt_fringe(s, moss, MountModel.fringe_mesh("tbr_mantle_v1", 0.20, 0.18, 0.40, 0.34, 0.16, 0.0, 360.0, 9,
		0.08, 0.025, 0.6), Vector3(0, 1.53, -0.01))
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.17, 6, 3), bark, Vector3(0.38 * sx, 1.44, 0.0), Vector3(0, 0, -16.0 * sx), Vector3(1.2, 0.72, 1.12))
		for k: int in 2:
			var z: float = 0.06 - 0.12 * float(k)
			MountModel.sculpt_add(s, ELK.spike_mesh(4), Transform3D(_to_dir(Vector3(0.7 * sx, 1.0, z)).scaled_local(Vector3(0.03,
				0.13, 0.03)), Vector3(0.44 * sx, 1.51, z)), thorn)
	# neck + head (the face canvas)
	_put(s, cyl(0.07, 0.085, 0.12, 6, false), skin, Vector3(0, 1.59, 0.03))
	_put(s, sphere(HEAD_R, 8, 5), skin, HEAD_C, Vector3.ZERO, Vector3(0.96, 1.04, 0.96))
	# the bark half-helm crested with two short pale antler tines
	var dome := PackedVector2Array([Vector2(0.172, 1.77), Vector2(0.176, 1.82), Vector2(0.16, 1.89), Vector2(0.11, 1.94),
		Vector2(0.0, 1.96)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("tbr_helm_v1", dome, 8, true), Transform3D(Basis.IDENTITY,
		Vector3(0, 0, 0.02)), dark)
	for sx: float in [-1.0, 1.0]:
		MountModel.sculpt_add(s, MountModel.tube_mesh("tbr_tine_%s_v1" % sx, PackedVector3Array([Vector3(0.10 * sx, 1.90, 0.06),
			Vector3(0.14 * sx, 2.02, 0.10), Vector3(0.15 * sx, 2.10, 0.18)]), PackedFloat32Array([0.035, 0.026, 0.0]), 5, true),
			Transform3D.IDENTITY, ant)


## The shield arm and the WICKER KITE SHIELD (face -X): pale straw with a bark rim, a team leaf emblem, a thorn boss.
func _arm_l_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var skin := m("nature_skin")
	var straw := m("nature_straw")
	var cloth := m("nature_cloth")
	var thorn := m("nature_thorn")
	var elbow := SH_L + Vector3(-0.01, -0.27, 0)
	_seg(s, dark, SH_L, elbow, 0.09, 0.08)
	_seg(s, bark, elbow, HAND_L + Vector3(0, 0.05, 0), 0.08, 0.07)
	_put(s, sphere(0.075, 5, 2), skin, HAND_L)
	var poly := PackedVector2Array()
	var face := PackedVector2Array()
	for p: Vector2 in SHIELD:
		poly.append(p)
		face.append(p * 0.88 + Vector2(0, -0.01))
	MountModel.sculpt_add(s, _slab_mesh("tbr_shield_v1", poly, 0.05), Transform3D(Basis.IDENTITY, SHIELD_C), dark)
	MountModel.sculpt_add(s, _slab_mesh("tbr_shield_face_v1", face, 0.02), Transform3D(Basis.IDENTITY,
		SHIELD_C + Vector3(-0.03, 0, 0)), straw)
	_leaf(s, cloth, SHIELD_C + Vector3(-0.045, -0.20, 0.0), Vector3(0, 1.0, 0.0), Vector3(-1, 0, 0), Vector3(0.24, 0.02, 0.46))
	MountModel.sculpt_add(s, ELK.spike_mesh(4), Transform3D(_to_dir(Vector3(-1, 0, 0)).scaled_local(Vector3(0.05, 0.12, 0.05)),
		SHIELD_C + Vector3(-0.05, 0.10, 0.0)), thorn)


func _arm_r_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var skin := m("nature_skin")
	var elbow := SH_R + Vector3(0.01, -0.27, 0)
	_seg(s, dark, SH_R, elbow, 0.09, 0.08)
	_seg(s, bark, elbow, HAND_R + Vector3(0, 0.05, 0), 0.08, 0.07)
	_put(s, sphere(0.075, 5, 2), skin, HAND_R)


## The thorn lance (keep_separate "Lance", node-local: the fist at the origin, along +Y): a bark shaft with a vine wrap,
## a big thorn head, a glowing seed at the socket and a team pennant under the head.
func _lance_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var thorn := m("nature_thorn")
	var cloth := m("nature_cloth")
	var vine := m("nature_leaf_dark")
	_seg(s, bark, Vector3(0, LANCE_BUTT, 0), Vector3(0, LANCE_TIP - 0.30, 0), 0.04, 0.03, 6)
	for k: int in 2:
		_put(s, cyl(0.044, 0.044, 0.035, 6, false), vine, Vector3(0, 0.30 + 0.55 * float(k), 0), Vector3(0, 0, 12.0 * float(k % 2 * 2 - 1)))
	_put(s, cyl(0.05, 0.05, 0.14, 6, false), dark, Vector3.ZERO)
	MountModel.sculpt_add(s, ELK.spike_mesh(4), Transform3D(Basis.from_scale(Vector3(0.075, 0.36, 0.06)),
		Vector3(0, LANCE_TIP - 0.36, 0)), thorn)
	_put(s, sphere(0.05, 6, 3), m("nature_glow"), Vector3(0, LANCE_TIP - 0.38, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
	var pen := PackedVector2Array([Vector2(0.0, 0.0), Vector2(-0.42, -0.08), Vector2(-0.30, -0.14), Vector2(-0.44, -0.22),
		Vector2(0.0, -0.24)])
	MountModel.sculpt_add(s, _slab_mesh("tbr_pennant_v1", pen, 0.015), Transform3D(Basis.IDENTITY,
		Vector3(0.0, LANCE_TIP - 0.46, -0.03)), cloth)


## The warden's standard (keep_separate "RankCrest", model space): a pole behind the right shoulder, a leaf-shaped team
## banner with a straw hem, a glowing blossom finial.
func _crest_sculpt(s: Dictionary) -> void:
	var cloth := m("nature_cloth")
	var straw := m("nature_straw")
	var base := Vector3(0.18, 1.08, -0.26)
	var top := Vector3(0.20, 2.46, -0.36)
	_seg(s, m("nature_bark"), base, top, 0.024, 0.02, 5)
	_put(s, sphere(0.06, 6, 3), m("nature_blossom"), top + Vector3(0, 0.05, 0))
	_put(s, sphere(0.03, 5, 2), m("nature_glow"), top + Vector3(0, 0.08, 0.03))
	_leaf(s, cloth, top - Vector3(0, 0.08, 0.02), Vector3(0, -0.35, -1.0), Vector3(1, 0, 0), Vector3(0.34, 0.02, 0.62))
	_leaf(s, straw, top - Vector3(0, 0.07, 0.03), Vector3(0, -0.35, -1.0), Vector3(1, 0, 0), Vector3(0.12, 0.024, 0.66))


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"lance_thrust":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3((_kf(t, T_ARM_X) - REST_R.x) * DEG, 0, (_kf(t, T_ARM_Z) - REST_R.z) * DEG))
	_psi_add += _kf(t, T_PSI) - LANCE_REST
	_dyaw_add += _kf(t, T_DYAW)
	rot(P_CHEST, Vector3(_kf(t, T_LEAN) * DEG, _kf(t, T_YAW) * DEG, 0))
	rot(P_ARM_L, Vector3(_kf(t, T_LEAN) * 0.8 * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, 0.10 * _kf(t, T_LEAN) / 16.0))
	if prev < THRUST_HIT and t >= THRUST_HIT:
		_on_action_event(&"release")
	return t < THRUST_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		lance_struck.emit(get_lance_tip())


func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-110.0 * DEG * k, 0, 8.0 * DEG * k))
	_psi_add += -18.0 * k
	return 0.75


## Fidget (standing still): lifts the lance, plants it again and looks round.
func _pose_fidget(t: float) -> float:
	var lift := _k3(t, 0.0, 0.3, 0.7, 1.0, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-30.0 * DEG * lift, 0, 0))
	_psi_add += -10.0 * lift
	var look := _k3(t, 0.8, 1.0, 1.6, 1.9, 1.0, 1.0)
	rot(P_CHEST, Vector3(0, 18.0 * DEG * sin((t - 0.8) * TAU / 1.1) * look, 0))
	return 1.9


func _war_process(dt: float) -> void:
	if _charge_t < CH_LEN:
		_charge_t += dt
	if _dead:
		_charge_t = 99.0
	if not _rd_on:
		_update_lance()


## Riding: the kit's seat pose (lean, bob), then the own arms (rest + the action offsets), the lance lowered level at
## the gallop and in the charge crouch, then the wrist.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 7.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var rl := REST_L + Vector3(bounce * 0.6, 0, 0)
	var rr := REST_R + Vector3(-bounce * 0.6 - 16.0 * gallop * moving, 0, 0)
	var psi: float = LANCE_REST + (bounce * 0.6 + 32.0 * gallop * moving)
	if _charge_t < CH_LEN and not _dead:
		var t := _charge_t
		var env := _k3(t, 0.0, 0.07, 0.40, CH_LEN, 1.0, 1.0)
		var jolt := _k3(t, CH_HIT - 0.02, CH_HIT + 0.03, CH_HIT + 0.05, 0.32, 1.0, 1.0)
		rl += Vector3(-30.0 * env - 12.0 * jolt, 30.0 * env, 16.0 * env)
		rr += Vector3(-40.0 * env, 0, -6.0 * env)
		psi = lerpf(psi, 88.0, env)
		rot(P_CHEST, Vector3((18.0 * env - 8.0 * jolt) * DEG * w, 0, 0))
	_off_rot[P_ARM_L] = sal + rl * DEG * w
	_off_rot[P_ARM_R] = sar + rr * DEG * w
	_psi_add += (psi - LANCE_REST) * w
	_update_lance()


func _update_lance() -> void:
	var psi: float = LANCE_REST + _psi_add
	var yaw: float = _dyaw_add
	_psi_add = 0.0
	_dyaw_add = 0.0
	if _dead:
		psi = LANCE_REST
		yaw = 0.0
	if _lance == null:
		return
	var want := Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.RIGHT, psi * DEG)
	var arm := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]) if _piv[P_ARM_R] else Basis.IDENTITY
	var q := (arm.inverse() * want).get_rotation_quaternion()
	if not q.is_equal_approx(_lance_q_w):
		_lance_q_w = q
		_lance.quaternion = q
	var gl: float = snappedf(glow_level() * (1.0 + 0.8 * float(_action == &"attack" or _charge_t < CH_LEN)), 0.05)
	if gl != _lance_glow_w:
		_lance_glow_w = gl
		_lance.set_instance_shader_parameter(&"glow_boost", gl)


func _war_revive() -> void:
	_charge_t = 99.0
	_psi_add = 0.0
	_dyaw_add = 0.0
	_lance_q_w = Quaternion(0, 0, 0, 0)
	_lance_glow_w = -1.0
	_update_lance()
