class_name PyrehoofLancerRider
extends FireModel
## Pyrehoof Lancer rider (stables.md 2, Fire C: the tier-2 line breaker, rank-3 "Pyrehoof Warlord"). Seated with the
## kit's CharacterModel.set_seated on the Pyrehoof Boar (parts/pyrehoof_boar.tscn); the scene pairing them is
## pyrehoof_lancer.tscn (PyrehoofLancerModel).
## Look (kept apart from the Blaze Rider: no horns, no round shield, no raised lance): a broad veteran in a burnished
## bronze cuirass with a gold sun and five rays on the breast, orange gambeson sleeves, bronze pauldrons with gold rims,
## a team cape over the cantle; a low bronze SALLET crowned by a wide TRANSVERSE team horsehair crest (side to side: the
## 40 m hook, a team bar over the head), an open face (FaceKit: stern amber eyes, round ears, a sculpted short auburn
## beard carrying the mouth); a tall team KITE SHIELD on the left arm (bronze rim, a gold sun with six rays
## over a dark flame); a heavy war lance (big bronze vamplate with a gold rim, bronze bands, a broad glowing flame head
## with two lugs) carried LOW and forward, a square team gonfalon laced under its head.
## Glow: the lance head only (own glow: flares at the strike / charge); the boar's mane is the other point.
## Riding: lance aimed in the model frame (seat pitch and lean compensated): REST_PITCH at a walk, GALLOP_PITCH at the
## gallop, couched level for the attack / the charge, raised for a cast salute; the shield arm guards, rises at the charge.
## Attack `lance_charge` (strike STRIKE_T 0.12 s, 0.72 s): cock back behind the shield with a twist, a driving thrust
## with the whole body (lean + twist + arm along the shaft), recover. play_charge() (0.85 s, hit CHARGE_HIT 0.10 s):
## couched, braced behind the raised shield, the head flares; charge_struck(at) at the hit frame (lance tip, world).
## Death: FireModel's burn while riding the boar's fall. Rank 3 (set_rank(3), Pyrehoof Warlord): node "RankCrest" shows
## (a gilded crown ring with seven rays round the sallet and a taller gold-tipped crest); the root also bards the boar.
## Hooks (on top of the kit's): play_charge(), get_lance_tip() (world), get_weapon_tip(), lance_pitch() (deg, negative
## = tip up), couch_amount(), is_charging(), set_rank(rank), authored_mesh_count(); signals charge_struck(at),
## lance_struck(at).
## Budget (rider, JS cap ~3000 vertices with the face): 7 draw instances at rest (Hips with the legs astride, Chest, Head,
## Face, ArmL with the shield, ArmR, Lance with its gonfalon); VetTrim / RankCrest hidden; no blob (the boar's shows);
## 1 one-shot particle system (the death embers); 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X).
const SH_L := Vector3(-0.32, 1.37, 0.0)
const SH_R := Vector3(0.32, 1.37, 0.0)
const ELBOW_R := Vector3(0.36, 1.09, -0.03)
const FIST_R := Vector3(0.36, 1.05, 0.24)
const ELBOW_L := Vector3(-0.36, 1.09, -0.02)
const FIST_L := Vector3(-0.35, 1.05, 0.23)
const SHIELD_C := Vector3(-0.49, 1.02, 0.12)
const HEAD_C := Vector3(0, 1.60, 0.06)
const HEAD_R := 0.135
## Lance (node-local at the fist, shaft along +Z): butt, head base, tip, the gonfalon's centre along the shaft.
const LANCE_BUTT := -0.62
const LANCE_HEAD := 2.52
const LANCE_TIP := 3.08
const GONF_Z := 2.12
## Lance pitch (deg above level, model frame) and yaw (deg, + = tip out to the right).
const REST_PITCH := 20.0
const GALLOP_PITCH := 11.0
const ATTACK_PITCH := -6.0
const CHARGE_PITCH := -2.0
const CAST_PITCH := 62.0
const REST_YAW := 9.0
const COUCH_YAW := -4.0
const ATTACK_LEN := 0.72
const STRIKE_T := 0.12
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10
const AUBURN := Color(0.50, 0.17, 0.07)

# Attack / charge tracks [t, v, ease, ...] (FireModel._kf format).
static var A_COUCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 1.0, 1, 0.42, 1.0, 0, 0.72, 0.0, 0])
static var A_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.14, 1, 0.13, 0.36, 2, 0.34, 0.18, 0, 0.72, 0.0, 0])
static var A_CHEST_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.05, 1, 0.13, 0.10, 2, 0.36, 0.05, 0, 0.72, 0.0, 0])
static var A_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.13, 16.0, 2, 0.36, 7.0, 0, 0.72, 0.0, 0])
static var A_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 16.0, 1, 0.13, -18.0, 2, 0.38, -6.0, 0, 0.72, 0.0, 0])
static var A_SHIELD := PackedFloat32Array([0.0, 0.0, 0, 0.07, -26.0, 1, 0.16, -8.0, 0, 0.72, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])
static var C_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.06, -0.10, 1, 0.11, 0.34, 2, 0.40, 0.14, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _lance: MeshInstance3D
var _embers: GPUParticles3D
var _rank_node: Node3D

var _atk_k: float = 0.0          # couch weight of the attack this frame
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _pitch: float = REST_PITCH   # lance pitch of the last posed frame (deg)
var _lance_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _glow_w: float = -1.0
var _rank: int = 0


# ================================================================ public hooks

## The charge (the unit's charge hit): lance couched level, braced behind the raised shield, the head flares. 0.85 s;
## charge_struck(at) at CHARGE_HIT.
func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


## World position of the lance tip (VFX: charge streak, impact).
func get_lance_tip() -> Vector3:
	if _lance and _lance.is_inside_tree():
		return _lance.global_transform * Vector3(0, 0, LANCE_TIP)
	return global_position + Vector3(0, 1.8, 2.4)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


## Lance pitch of the last posed frame (deg, model frame; negative = tip up, like the Gloam Rider's).
func lance_pitch() -> float:
	return -_pitch


func couch_amount() -> float:
	return maxf(_atk_k, _charge_k)


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


## Stables16 rank-3 look (Pyrehoof Warlord): the gilded crest (node "RankCrest"). Idempotent.
func set_rank(rank: int) -> void:
	_rank = rank
	if _rank_node:
		_rank_node.visible = rank >= 3 and not _dead


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "pl_hips_v5", _hips_sculpt)
	_sculpt($Root/Chest, "pl_chest_v5", _chest_sculpt)
	_sculpt(head, "pl_head_v3", _head_sculpt)
	# Face: a stern, broad veteran under the open sallet: amber eyes under heavy auburn brows, round ears; the mouth sits on
	# the top of the sculpted auburn beard (mouth canvas, like the Blaze Rider's).
	_face = UnitFaces.attach_lean(self, head, "pyrehoof_lancer_rider", {"center": HEAD_C, "radius": HEAD_R,
		"head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.96, 1.04, 0.95), "preset": &"stern", "detail": &"low",
		"skin": FIRE_SKIN.darkened(0.03), "hair": AUBURN, "hair_tip": Color(0.78, 0.36, 0.12), "eyes": Color(0.82, 0.50, 0.12),
		"ears": &"round", "eye": {"c": Vector2(0.047, 0.008), "hw": 0.027, "top": 0.018, "ir": 0.013},
		"palette": {"brow": Color(0.34, 0.10, 0.04)},
		"mouth_canvas": FaceKit.canvas(Vector3(0, 1.515, 0.12), 0.10, sphere(0.108, 7, 3), Vector3(1.2, 0.82, 0.78),
			Vector3.INF, Basis(Vector3.RIGHT, deg_to_rad(20.0)), 0.002),
		"mouth": {"c": Vector2(0.0, 0.052), "hw": 0.029}}, false)
	_sculpt($Root/Chest/ArmL, "pl_arm_l_v4", _arm_l_sculpt)
	_sculpt(arm_r, "pl_arm_r_v3", _arm_r_sculpt)
	# Own (keep_separate) parts: the lance at the fist (with its gonfalon), the level-4 helm band, the rank crest.
	_lance = _sculpt(arm_r, "pl_lance_v3", _lance_sculpt, FIST_R, true, "Lance")
	_lance.set_meta(&"own_glow", true)
	_lance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var vet := add_part(head, cyl(0.2, 0.2, 0.04, 12, false), palette(&"unit_gold_trim"), Vector3(0, 1.70, -0.01),
		Vector3(-4, 0, 0), Vector3(1.0, 1.0, 1.1), true, "VetTrim")
	vet.set_meta(&"vet_trim", true)
	_parts_n += 1
	_rank_node = _sculpt(head, "pl_rank_v2", _rank_sculpt, Vector3.ZERO, true, "RankCrest")
	_rank_node.visible = false
	# The death burn: 10 embers from the body (FireModel restarts them when the body glows).
	_embers = CharacterModel.make_motes(Color(1.0, 0.42, 0.08), 10, 0.9, 0.34, 1.5, 0.15, false, true)
	_embers.name = "BurnEmbers"
	_embers.set_meta(&"burn_fx", true)
	_embers.set_meta(&"keep_separate", true)
	_embers.position = Vector3(0, 0.25, 0)
	$Root/Chest.add_child(_embers)


## One authored part from a multi-material sculpt (MountModel's builders). Static parts are skipped once the pivot's
## merge is cached; keep_separate parts get their cached mesh every instance. `at` = the node's model position.
func _sculpt(pivot: Node3D, key: String, build: Callable, at: Vector3 = Vector3.ZERO, keep: bool = false,
		nm: String = "") -> MeshInstance3D:
	_parts_n += 1
	if not keep and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mesh := _cached_sculpt(key, build)
	if mesh == null:
		return null
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, nm)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	return palette(StringName(name))


## Rotation taking +Y onto `d`.
static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


## Cylinder / cone from a (radius ra) to b (radius rb).
static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 7) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## A ray / spike: a 3-sided cone from `base` along `dir`, length h, base radius r (a cheap sun ray).
static func _ray(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, h: float) -> void:
	MountModel.sculpt_add(s, cyl(0.0, r, h, 3), Transform3D(_to_dir(dir), base + dir.normalized() * h * 0.5), mat)


## Flame tongue along +Y (length 1, width ~0.8), the tip curling toward +Z; flattened (a sigil / plate cut-out).
static func _flame_mesh() -> Mesh:
	return MountModel.tube_mesh("pl_flame_v2", PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0, 0.36, -0.03),
		Vector3(0, 0.75, 0.12), Vector3(0, 1.0, 0.34)]), PackedFloat32Array([0.36, 0.36, 0.18, 0.0]), 6, true, 0.35)


## The kite shield: a slightly convex plate in the model YZ plane (face toward -X), height h (top edge gently arched,
## widest a quarter down, a point at the bottom), half width w, thickness th; centred on its origin. part 0 = the face
## (+ its back), 1 = the rim tube along the outline.
static func _kite_mesh(part: int, h: float, w: float, th: float, bulge: float) -> Mesh:
	var key := "pl_kite_%d_%s_%s_v2" % [part, h, w]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var rows := 7
	var cols := 4
	var grid: Array = []
	for i: int in rows + 1:
		var t := float(i) / float(rows)
		var hw: float = w * ((0.93 + 0.28 * t) if t < 0.25 else (1.0 - pow((t - 0.25) / 0.75, 1.35)))
		var y: float = h * 0.42 - h * t
		var row: Array[Vector3] = []
		for j: int in cols + 1:
			var u := lerpf(-1.0, 1.0, float(j) / float(cols))
			var x := -bulge * (1.0 - u * u) * (1.0 - 0.6 * t)
			row.append(Vector3(x, y + (0.03 * (1.0 - u * u) if i == 0 else 0.0), u * hw))
		grid.append(row)
	if part == 1:
		# the outline: the top edge left to right, down the right side to the point, back up the left side
		var outline := PackedVector3Array()
		for j: int in cols + 1:
			outline.append((grid[0] as Array)[j] + Vector3(-0.01, 0, 0))
		for i: int in range(1, rows + 1):
			outline.append((grid[i] as Array)[cols] + Vector3(-0.01, 0, 0))
		for i: int in range(rows - 1, 0, -1):
			outline.append((grid[i] as Array)[0] + Vector3(-0.01, 0, 0))
		outline.append(outline[0])
		var radii := PackedFloat32Array()
		for k: int in outline.size():
			radii.append(0.022)
		return _cached(key, MountModel.tube_mesh(key + "_t", outline, radii, 4, false))
	# smooth normals per grid vertex (the plate's convex curve): shared vertices, ~2 x 40
	var nrm: Array = []
	for i: int in rows + 1:
		var t := float(i) / float(rows)
		var row: Array[Vector3] = []
		for j: int in cols + 1:
			var u := lerpf(-1.0, 1.0, float(j) / float(cols))
			row.append(Vector3(-1.0, 0.0, 1.6 * bulge * u * (1.0 - 0.6 * t) / maxf(w, 0.05)).normalized())
		nrm.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var o := Vector3(th, 0, 0)
	var bx := Vector3(1, 0, 0)
	for i: int in rows:
		for j: int in cols:
			var a: Vector3 = (grid[i] as Array)[j]
			var b: Vector3 = (grid[i] as Array)[j + 1]
			var c: Vector3 = (grid[i + 1] as Array)[j + 1]
			var d: Vector3 = (grid[i + 1] as Array)[j]
			var na: Vector3 = (nrm[i] as Array)[j]
			var nb: Vector3 = (nrm[i] as Array)[j + 1]
			var nc: Vector3 = (nrm[i + 1] as Array)[j + 1]
			var nd: Vector3 = (nrm[i + 1] as Array)[j]
			_tri3(st, a, b, c, na, nb, nc)
			_tri3(st, a, c, d, na, nc, nd)
			_tri3(st, a + o, c + o, b + o, bx, bx, bx)
			_tri3(st, a + o, d + o, c + o, bx, bx, bx)
	st.index()
	return _cached(key, st.commit())


## One smooth triangle with its front face (Godot: clockwise) toward the given normals.
static func _tri3(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(na + nb + nc) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


# ---------------------------------------------------------------- body

## Hips + both legs astride (no leg pivots: the seated legs never swing, so they merge into Hips = 1 draw): gambeson
## skirt, belt with a gold buckle, the team surcoat's back skirt over the cantle, dark trousers, bronze knee cops and greaves,
## leather boots in the boar's stirrups.
func _hips_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	var sec := m("fire_sec_rider")
	# G-C leftovers: padded bell skirt with a rolled hem, bevelled pointed surcoat skirt, legs as smooth tubes with domed
	# knee cops, greaves with a calf swell and a ridge, rounded boots (were 6-sided cans and cylinders)
	RiderShapes.lathe(s, sec, PackedVector2Array([Vector2(0.265, 0.71), Vector2(0.276, 0.725), Vector2(0.265, 0.75),
		Vector2(0.248, 0.83), Vector2(0.225, 0.93)]), 12)
	RiderShapes.band(s, leather, 0.228, 0.07, 0.016, 12, Transform3D(Basis.IDENTITY, Vector3(0, 0.935, 0)))
	# the surcoat skirt hanging over the cantle, a dark hem (a front one would sit inside the boar's hump)
	RiderShapes.box_plate(s, cloth, Vector3(0.35, 0.42, 0.026), Vector3(0, 0.735, -0.25), Vector3(16, 0, 0), Vector3.ONE,
		0.9, 0.16)
	RiderShapes.box_plate(s, cdark, Vector3(0.31, 0.07, 0.03), Vector3(0, 0.565, -0.30), Vector3(16, 0, 0), Vector3.ONE,
		0.55, 0.55)
	for sx: float in [-1.0, 1.0]:

		# the leg astride: thigh out and forward over the barrel, shin hanging down to the stirrup, boot forward
		var hip := Vector3(0.13 * sx, 0.83, 0.02)
		var knee := Vector3(0.41 * sx, 0.62, 0.24)
		var ankle := Vector3(0.50 * sx, 0.40, 0.12)
		RiderShapes.tube(s, cdark, PackedVector3Array([hip, hip.lerp(knee, 0.45), knee]),
			PackedFloat32Array([0.105, 0.11, 0.082]), 9)
		RiderShapes.lathe(s, bronze, PackedVector2Array([Vector2(0.09, 0.0), Vector2(0.086, 0.035), Vector2(0.06, 0.066),
			Vector2(0.0, 0.08)]), 10, MountModel.frame(knee + Vector3(0.01 * sx, 0.01, -0.005), Vector3(0.1 * sx, 0.1, 1.0),
			Vector3.UP), 1.0, 1.15)
		var an := ankle + Vector3(0, -0.04, 0)
		RiderShapes.tube(s, bronze, PackedVector3Array([knee, knee.lerp(an, 0.3), an]),
			PackedFloat32Array([0.078, 0.084, 0.068]), 9)
		var fr := Vector3(0.0, 0.25, 1.0).normalized()
		RiderShapes.tube(s, bronze, PackedVector3Array([knee.lerp(an, 0.12) + fr * 0.072, knee.lerp(an, 0.5) + fr * 0.078,
			an + fr * 0.058]), PackedFloat32Array([0.02, 0.018, 0.01]), 5)
		var fd := Vector3(0.05 * sx, 0.03, 1.0).normalized()
		var fc := ankle + Vector3(0.01 * sx, -0.05, 0.10)
		RiderShapes.boot(s, leather, fc - fd * 0.12, fc + fd * 0.15, 0.072)
		RiderShapes.band(s, leather, 0.07, 0.06, 0.014, 9, MountModel.frame(an + Vector3(0, 0.02, 0), knee - an, Vector3.BACK))


func _chest_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var sec := m("fire_sec_rider")
	var bronze := m("fire_bronze")
	var gold := m("unit_gold_trim")
	# gambeson torso, then the burnished bronze cuirass (broad, flattened front-back)
	var prof := PackedVector2Array([Vector2(0.20, 0.90), Vector2(0.23, 1.0), Vector2(0.265, 1.14), Vector2(0.278, 1.26),
		Vector2(0.255, 1.36), Vector2(0.15, 1.45), Vector2(0.0, 1.47)])
	RiderShapes.lathe(s, sec, prof, 12, Transform3D.IDENTITY, 1.0, 0.82)
	# G-C leftovers: the cuirass turned on 16 sides with a rolled waist lip, a faceted centre ridge
	var cu := PackedVector2Array([Vector2(0.252, 0.985), Vector2(0.258, 1.0), Vector2(0.285, 1.14), Vector2(0.298, 1.26),
		Vector2(0.28, 1.35), Vector2(0.21, 1.425)])
	RiderShapes.lathe(s, bronze, cu, 16, Transform3D.IDENTITY, 1.0, 0.86, false)
	RiderShapes.tube(s, bronze, PackedVector3Array([Vector3(0, 1.02, 0.222), Vector3(0, 1.14, 0.247), Vector3(0, 1.26, 0.258),
		Vector3(0, 1.35, 0.242)]), PackedFloat32Array([0.012, 0.016, 0.016, 0.01]), 4)
	# the sun on the breast: a gold disc, a dark heart and five gold rays fanning up and out
	_put(s, cyl(0.072, 0.072, 0.022, 8), gold, Vector3(0, 1.20, 0.262), Vector3(84, 0, 0))
	_put(s, box(Vector3(0.05, 0.05, 0.03)), cdark, Vector3(0, 1.20, 0.272), Vector3(-6, 0, 45))
	for k: int in 3:
		var a := deg_to_rad(-50.0 + 50.0 * float(k))
		_put(s, prism(Vector3(0.05, 0.10, 0.02)), gold, Vector3(0, 1.20, 0.258) + Vector3(sin(a), cos(a), 0) * 0.125,
			Vector3(-6, 0, -rad_to_deg(a)))
	# short team tabard below the sun, a dark hem
	RiderShapes.box_plate(s, cloth, Vector3(0.30, 0.15, 0.026), Vector3(0, 1.05, 0.25), Vector3(-5, 0, 0), Vector3.ONE,
		0.9, 0.2)
	RiderShapes.box_plate(s, cdark, Vector3(0.27, 0.05, 0.03), Vector3(0, 0.985, 0.255), Vector3(-5, 0, 0), Vector3.ONE,
		0.5, 0.6)
	# bronze gorget: two rolled lames
	RiderShapes.lame(s, bronze, 0.168, 0.14, 1.40, 1.45, 0.0, TAU, 12, 0.014)
	RiderShapes.lame(s, bronze, 0.142, 0.118, 1.445, 1.50, 0.0, TAU, 12, 0.012)
	# bronze pauldrons with a gold rim (bronze: the Blaze Rider's are team): a smooth dome over two rolled lames
	for sx: float in [-1.0, 1.0]:
		var pf := MountModel.frame(Vector3(0.345 * sx, 1.41, -0.01), Vector3(0.55 * sx, 1.0, 0.0), Vector3.BACK)
		RiderShapes.lathe(s, bronze, PackedVector2Array([Vector2(0.17, -0.07), Vector2(0.178, -0.01), Vector2(0.145, 0.045),
			Vector2(0.075, 0.075), Vector2(0.0, 0.082)]), 14, pf)
		RiderShapes.band(s, gold, 0.172, 0.035, 0.012, 14, Transform3D(pf.basis, pf * Vector3(0, -0.05, 0)))
		for k: int in 2:
			var rk: float = 0.168 - 0.02 * float(k)
			RiderShapes.lame(s, bronze, rk + 0.012, rk, 0.0, 0.055, 0.0, TAU, 12, 0.013,
				Transform3D(pf.basis, pf * Vector3(0.012 * sx * float(k + 1), -0.13 - 0.06 * float(k), 0.0)))
	# a team cape from the shoulders, falling back over the cantle
	_put(s, cape(0.62, 0.58), m("fire_cape"), Vector3(0, 1.11, -0.34), Vector3(30, 0, 0))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("fire_skin")
	var hair := m("fire_hair")
	var bronze := m("fire_bronze")
	var gold := m("unit_gold_trim")
	var cloth := m("fire_cloth")
	_put(s, cyl(0.075, 0.085, 0.12, 10), skin, Vector3(0, 1.50, 0.02))
	# the face sphere (the FaceKit canvas) and the short auburn beard (the mouth canvas) with a jutting point
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.96, 1.04, 0.95))
	_put(s, sphere(0.108, 7, 3), hair, Vector3(0, 1.515, 0.12), Vector3(20, 0, 0), Vector3(1.2, 0.82, 0.78))
	MountModel.sculpt_add(s, cyl(0.0, 0.055, 0.12, 5), Transform3D(_to_dir(Vector3(0, -1.0, 0.5)).scaled_local(
		Vector3(1.0, 1.0, 0.6)), Vector3(0, 1.44, 0.18)), hair)
	# the low sallet: a bronze dome from the brow, a gold brow band, a flared tail over the nape (open face and sides)
	var hp := PackedVector2Array([Vector2(0.172, 1.675), Vector2(0.182, 1.735), Vector2(0.165, 1.80), Vector2(0.115, 1.848),
		Vector2(0.0, 1.868)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("pl_sallet_v3", hp, 10),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.12)), Vector3(0, 0, -0.01)), bronze)
	_put(s, cyl(0.186, 0.186, 0.04, 10, false), gold, Vector3(0, 1.682, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.12))
	var tb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	MountModel.sculpt_add(s, MountModel.shell_mesh("pl_sallet_tail_v3", 0.22, 0.235, 120.0, 240.0, 1.50, 1.70, 0.02, 5, 1,
		0.85, 0.0), Transform3D(tb, Vector3(0, 0, -0.01)), bronze)
	# the TRANSVERSE crest: a bronze holder arched side to side over the dome, a fan of team horsehair along it (tallest
	# in the middle, sweeping out and up at the ends)
	var arc := PackedVector3Array()
	var radii := PackedFloat32Array()
	for k: int in 5:
		var u := lerpf(-1.0, 1.0, float(k) / 4.0)
		arc.append(Vector3(u * 0.15, 1.862 - 0.075 * u * u, -0.02))
		radii.append(0.03)
	MountModel.sculpt_add(s, MountModel.tube_mesh("pl_crest_holder_v2", arc, radii, 5), Transform3D.IDENTITY, bronze)
	for k: int in 6:
		var u := lerpf(-1.0, 1.0, float(k) / 5.0)
		var root := Vector3(u * 0.16, 1.875 - 0.08 * u * u, -0.02)
		var dir := Vector3(u * 0.55, 1.0, -0.12).normalized()
		MountModel.sculpt_lock(s, cloth, root, dir, Vector3(0, 0, -1), 0.105, 0.24 + 0.06 * (1.0 - absf(u)), 0.055)


## The rank-3 crest (node "RankCrest" on Head, node-local = model space): a gilded crown ring with seven rays round the
## brim, a gold holder and taller team horsehair with gold tips over the crest.
func _rank_sculpt(s: Dictionary) -> void:
	var gold := m("unit_gold_trim")
	var cloth := m("fire_cloth")
	_put(s, cyl(0.195, 0.195, 0.045, 12, false), gold, Vector3(0, 1.72, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.12))
	for k: int in 7:
		var a := deg_to_rad(-90.0 + 30.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a) * 1.12)
		_ray(s, gold, Vector3(0, 1.73, -0.01) + d * 0.19, Vector3(d.x * 0.3, 1.0, d.z * 0.3), 0.025, 0.10)
	for k: int in 5:
		var u := lerpf(-1.0, 1.0, float(k) / 4.0)
		var root := Vector3(u * 0.12, 1.90 - 0.05 * u * u, -0.03)
		var dir := Vector3(u * 0.5, 1.0, -0.2).normalized()
		MountModel.sculpt_lock(s, cloth, root, dir, Vector3(0, 0, -1), 0.085, 0.36, 0.05)
		_put(s, sphere(0.03, 6, 3), gold, root + dir * 0.34)


func _arm_l_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, -1.0)
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var bronze := m("fire_bronze")
	var gold := m("unit_gold_trim")
	var leather := m("fire_leather")
	# the tall team kite shield on the forearm, face outward (-X): the face, a bronze rim, a gold sun with four rays over a
	# dark flame; a leather strap on the inside
	var h := 0.96
	var w := 0.27
	var at := Transform3D(Basis.IDENTITY, SHIELD_C)
	MountModel.sculpt_add(s, _kite_mesh(0, h, w, 0.035, 0.06), at, cloth)
	MountModel.sculpt_add(s, _kite_mesh(1, h, w, 0.035, 0.06), at, bronze)
	var sun := SHIELD_C + Vector3(-0.072, 0.10, 0.0)
	var sb := Basis(Vector3.BACK, PI * 0.5)   # cylinder axis along X
	MountModel.sculpt_add(s, cyl(0.075, 0.075, 0.025, 8), Transform3D(sb, sun), gold)
	MountModel.sculpt_add(s, cyl(0.13, 0.13, 0.022, 10, false), Transform3D(sb, sun + Vector3(0.012, 0, 0)), gold)
	MountModel.sculpt_add(s, _flame_mesh(), Transform3D(Basis(Vector3(0.012, 0, 0), Vector3(0, 0.30, 0), Vector3(0, 0, 0.22)),
		SHIELD_C + Vector3(-0.056, -0.34, 0.0)), cdark)
	RiderShapes.box_plate(s, leather, Vector3(0.24, 0.05, 0.03), SHIELD_C + Vector3(0.06, 0.02, 0.0), Vector3(0, 90, 0))


func _arm_r_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, 1.0)


## Upper arm (gambeson orange; the shoulder sits under the pauldron), a bronze elbow cop, bronze vambrace, leather
## gauntlet.
func _arm_sculpt(s: Dictionary, sx: float) -> void:
	var sec := m("fire_sec_rider")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var sh: Vector3 = SH_L if sx < 0.0 else SH_R
	var el: Vector3 = ELBOW_L if sx < 0.0 else ELBOW_R
	var fi: Vector3 = FIST_L if sx < 0.0 else FIST_R
	# G-C leftovers: a padded sleeve with a bicep swell, a cupped elbow cop, a flared vambrace, a cuffed gauntlet
	var s0 := sh + Vector3(0, 0.02, 0)
	var d := (fi - el).normalized()
	RiderShapes.tube(s, sec, PackedVector3Array([s0, s0.lerp(el, 0.45), el]), PackedFloat32Array([0.088, 0.093, 0.072]), 9)
	RiderShapes.lathe(s, bronze, PackedVector2Array([Vector2(0.078, 0.0), Vector2(0.074, 0.03), Vector2(0.048, 0.06),
		Vector2(0.0, 0.07)]), 9, MountModel.frame(el - d * 0.01, (el - s0).normalized() - d, Vector3(sx, 0, 0)))
	var w0 := fi - d * 0.04
	RiderShapes.tube(s, bronze, PackedVector3Array([el, el.lerp(w0, 0.3), w0, w0 + d * 0.006]),
		PackedFloat32Array([0.074, 0.079, 0.084, 0.06]), 9)
	RiderShapes.band(s, m("unit_gold_trim"), 0.08, 0.025, 0.01, 10, MountModel.frame(w0 - d * 0.015, d, Vector3.UP))
	_put(s, sphere(0.08, 9, 4), leather, fi, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The war lance (keep_separate "Lance", node-local at the fist, shaft along +Z): bronze butt, leather grip, a big bronze
## vamplate with a gold rim, the ash shaft with a bronze band, the square team gonfalon laced under the head by two gold
## rings, a collar, two bronze lugs and the broad glowing flame head.
func _lance_sculpt(s: Dictionary) -> void:
	var wood := m("fire_wood")
	var bronze := m("fire_bronze")
	var gold := m("unit_gold_trim")
	var leather := m("fire_leather")
	var glow := m("fire_glow")
	var z := Basis(Vector3.RIGHT, PI * 0.5)   # +Y -> +Z
	MountModel.sculpt_add(s, MountModel.tube_mesh("pl_shaft_v3", PackedVector3Array([Vector3(0, 0, LANCE_BUTT),
		Vector3(0, 0, 0.9), Vector3(0, 0, LANCE_HEAD)]), PackedFloat32Array([0.046, 0.048, 0.036]), 6), Transform3D.IDENTITY,
		wood)
	_put(s, sphere(0.06, 6, 3), bronze, Vector3(0, 0, LANCE_BUTT), Vector3.ZERO, Vector3(1.0, 1.0, 1.4))
	MountModel.sculpt_add(s, cyl(0.06, 0.06, 0.24, 6), Transform3D(z, Vector3(0, 0, -0.02)), leather)
	MountModel.sculpt_add(s, cyl(0.058, 0.20, 0.30, 8), Transform3D(z, Vector3(0, 0, 0.26)), bronze)
	MountModel.sculpt_add(s, cyl(0.205, 0.205, 0.035, 8, false), Transform3D(z, Vector3(0, 0, 0.40)), gold)
	MountModel.sculpt_add(s, cyl(0.054, 0.054, 0.05, 6), Transform3D(z, Vector3(0, 0, 1.25)), bronze)
	var gb := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
	MountModel.sculpt_add(s, cape(0.42, 0.44), Transform3D(gb, Vector3(0, -0.24, GONF_Z)), m("fire_pennon"))
	for rz: float in [GONF_Z - 0.2, GONF_Z + 0.2]:
		MountModel.sculpt_add(s, cyl(0.05, 0.05, 0.035, 6, false), Transform3D(z, Vector3(0, 0, rz)), gold)
	MountModel.sculpt_add(s, cyl(0.072, 0.056, 0.13, 6), Transform3D(z, Vector3(0, 0, LANCE_HEAD - 0.02)), bronze)
	MountModel.sculpt_add(s, prism(Vector3(0.05, 0.14, 0.26)), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0)),
		Vector3(0, 0, LANCE_HEAD - 0.05)), bronze)
	MountModel.sculpt_add(s, MountModel.tube_mesh("pl_lance_head_v3", PackedVector3Array([Vector3(0, 0, LANCE_HEAD + 0.02),
		Vector3(0, 0, LANCE_HEAD + 0.17), Vector3(0, 0, LANCE_HEAD + 0.38), Vector3(0, 0, LANCE_TIP)]),
		PackedFloat32Array([0.07, 0.15, 0.09, 0.0]), 7, true, 0.34), Transform3D.IDENTITY, glow)


# ================================================================ motion

func _after_ready() -> void:
	super()
	if _embers and not _burn_fx.has(_embers):
		_burn_fx.append(_embers)
	_write_glow()


## `lance_charge`: cock back, couch, thrust (strike STRIKE_T), recover. Arms and the lance are posed in _pose_seated.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"lance_charge":
		return super._pose_attack(prev, t)
	_atk_k = _kf(t, A_COUCH)
	rot(P_CHEST, Vector3(_kf(t, A_LEAN) * DEG, _kf(t, A_TWIST) * DEG, 0))
	pos(P_CHEST, Vector3(0, 0, _kf(t, A_CHEST_Z)))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, A_ARM_Z)))
	rot(P_ARM_L, Vector3(_kf(t, A_SHIELD) * DEG, 0, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
		_flare = maxf(_flare, 0.7)
		lance_struck.emit(get_lance_tip())
	if t >= ATTACK_LEN:
		_atk_k = 0.0
	return t < ATTACK_LEN


## A lance salute for any cast: the lance raised high, the shield out.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-30.0 * DEG * _cast_k, 0, 0))
	rot(P_ARM_L, Vector3(-20.0 * DEG * _cast_k, 0, 12.0 * DEG * _cast_k))
	return 0.75


func _extra_process(dt: float) -> void:
	super(dt)
	if _action != &"attack":
		_atk_k = 0.0
	if _action != &"cast":
		_cast_k = 0.0
	if _charge_t < CHARGE_LEN:
		var prev := _charge_t
		_charge_t += dt
		_charge_k = _kf(_charge_t, C_K) if not _dead else 0.0
		if prev < CHARGE_HIT and _charge_t >= CHARGE_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
		if _charge_t >= CHARGE_LEN:
			_charge_k = 0.0
	else:
		_charge_k = 0.0
		_flare = maxf(0.0, _flare - dt / 0.5)
	if _dead and _rank_node and _rank_node.visible and _death_t > 0.5:
		_rank_node.visible = false
	_write_glow()


## Riding: the kit's seat pose, then the lance arm, the shield arm, the charge brace and the lance aim.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var ck := _charge_k
	var gm: float = gallop * moving
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 4.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	# arms (replace the kit's reins): lance fist at the hip, the shield arm guarding across; the charge raises the shield
	_off_rot[P_ARM_R] = sar + Vector3((4.0 + bounce * 0.5 - 4.0 * ck) * DEG, 0, -3.0 * DEG) * w
	_off_rot[P_ARM_L] = sal + Vector3((-10.0 + bounce - 30.0 * ck) * DEG, 0, (4.0 + 8.0 * ck) * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(12.0 * DEG * ck * w, -6.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-12.0 * DEG * ck * w, 5.0 * DEG * ck * w, 0))
		pos(P_ARM_R, Vector3(0, 0, _kf(_charge_t, C_ARM_Z) * w))
	# the lance: aimed in the model frame (seat pitch + lean compensated), bobbing a little with the gait
	var p: float = lerpf(REST_PITCH, GALLOP_PITCH, gm) + lerpf(1.2 * sin(2.0 * TAU * gait), 3.0 * sin(TAU * (gait - 0.3)),
		gallop) * moving
	var yaw: float = REST_YAW
	var couch: float = maxf(ck, _atk_k)
	if couch > 0.0:
		p = lerpf(p, CHARGE_PITCH if ck >= _atk_k else ATTACK_PITCH, couch)
		yaw = lerpf(yaw, COUCH_YAW, couch)
	if _cast_k > 0.0:
		p = lerpf(p, CAST_PITCH, _cast_k)
	if not _dead:
		_pitch = p
		_aim_lance(p, yaw)


## Turns the lance (child of ArmR) so its shaft points along pitch / yaw (deg) in the model frame.
func _aim_lance(pitch_deg: float, yaw_deg: float) -> void:
	if _lance == null:
		return
	var pr := pitch_deg * DEG
	var yr := yaw_deg * DEG
	var d := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	var up := Vector3.UP - d * d.y
	if up.length_squared() < 1e-4:
		up = Vector3.BACK
	up = up.normalized()
	var want := Basis(up.cross(d), up, d)
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	var ba := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R])
	var q := ((rb * bc * ba).inverse() * want).orthonormalized().get_rotation_quaternion()
	if not q.is_equal_approx(_lance_q_w):
		_lance_q_w = q
		_lance.quaternion = q


## The lance head's own glow: the kit's glow level, flared by the charge / strike.
func _write_glow() -> void:
	if _lance == null:
		return
	var g: float = snappedf(glow_level() * (1.0 + 1.6 * _flare + 0.6 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_lance.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super()
	_atk_k = 0.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_pitch = REST_PITCH
	_lance_q_w = Quaternion(0, 0, 0, 0)
	_glow_w = -1.0
	set_rank(_rank)
	_write_glow()
