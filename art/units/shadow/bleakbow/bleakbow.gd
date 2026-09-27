extends ShadowModel
## Bleakbow, Shadow bowman (docs/design/bowmen.md: bleeding barbed arrows). body_height 1.6 (UnitType), gaunt and upright.
## A lean grave-hunter (the Nightbolt wears a wide brim and shoots a caster, the Shade crouches with blades): a deep
## team cowl with a pale bone HALF-MASK (a fanged jaw), two bone HOOKS sweeping up and back from the cowl (the crest
## read), a violet team jerkin under a pale silver rib harness, an iron gorget, a long TATTERED dark coat split into three
## tails behind the legs, iron-shod boots. A quiver slung across the back (left hip to right shoulder) holds barbed
## arrows whose serrated heads over the right shoulder are the only glow point at rest (violet, high up).
## The silhouette hook: a black obsidian RECURVE bow (1.8 m, upright in the left fist) with barbs down the back of
## both limbs and bone hook tips.
## Attack `bow_draw` (0.6 s, release 0.15): the bow arm snaps up level, the body turns side-on, the right hand draws a
## barbed arrow (its head glows) to the mask, looses at 0.15 with a violet burst. play_cast (any id, 1.0 s): a slow
## held draw, the head charges, a bigger flare. Death: ShadowModel's violet dissolve.
## Hooks (plus every kit / Shadow hook): get_bow_tip_position() -> Vector3 (world; where the arrow leaves).
## Draws: merged pivots + Bow (2 surfaces) + BowString + StringDrawn + Arrow + ArrowHead (hidden at rest) + VetTrim
## (hidden) + blob. 0 lights.

const ATTACK_LEN := 0.6
const RELEASE := 0.15
const CAST_LEN := 1.0
const CAST_RELEASE := 0.65
const BOW_TILT := 6.0
const GRIP_L := Vector3(-0.34, 0.97, 0.11)
const HAND_R := Vector3(0.33, 0.92, 0.05)
const SH_L := Vector3(-0.25, 1.31, 0.0)
const SH_R := Vector3(0.25, 1.31, 0.0)
# bow space (origin = grip, +Y up the bow, -Z toward the archer)
const TIP_U := Vector3(0.0, 0.93, -0.12)
const TIP_D := Vector3(0.0, -0.88, -0.12)
const NOCK := Vector3(0.0, 0.0, -0.48)
const ARROW_HEAD := Vector3(0.0, 0.0, 0.34)
const VIOLET := Color(0.72, 0.34, 1.0)

# bow_draw tracks [t, value, ease]. Arm x: negative raises forward.
static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -86.0, 1, 0.36, -82.0, 0, 0.60, 0.0, 0])
static var A_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 28.0, 1, 0.36, 26.0, 0, 0.60, 0.0, 0])
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -78.0, 1, 0.15, -84.0, 0, 0.22, -64.0, 1, 0.60, 0.0, 0])
static var A_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.30, 1, 0.15, -0.44, 2, 0.22, -0.54, 1, 0.60, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.15, 0.0, 0, 0.20, -0.06, 1, 0.60, 0.0, 0])
static var A_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, 8.0, 1, 0.36, 8.0, 0, 0.60, 0.0, 0])
# Held draw: slow, the body hunches over the arrow, loose at 0.65.
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.25, -88.0, 1, 0.80, -84.0, 0, 1.0, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.25, 32.0, 1, 0.80, 28.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.25, -78.0, 1, 0.60, -88.0, 0, 0.72, -62.0, 1, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.25, -0.26, 1, 0.60, -0.50, 2, 0.72, -0.58, 1, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, 8.0, 0, 0.60, 12.0, 0, 0.72, -4.0, 1, 1.0, 0.0, 0])

var _bow: Node3D
var _bstring: GeometryInstance3D
var _string_drawn: GeometryInstance3D
var _barrow: GeometryInstance3D
var _head_glow: GeometryInstance3D
var _burst: GPUParticles3D
var _drawn_on: bool = false
var _cast_loosed: bool = false
var _flare: float = 0.0
var _charge: float = 0.0
var _head_written: float = -1.0
var _bow_x_written: float = 999.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := palette(&"shadow_cloth")
	var cdark := palette(&"shadow_cloth_dark")
	var leather := palette(&"shadow_leather")
	var iron := palette(&"shadow_iron")
	var bone := palette(&"shadow_bone")
	var obsidian := palette(&"shadow_obsidian")
	var skin := palette(&"shadow_skin")
	var glow := palette(&"shadow_glow_mid")
	# ---- Legs: thin wrapped legs, iron-shod pointed boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var x: float = 0.10 * sx
		add_part(leg, _path("bb_leg", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 0.50, 0.03),
			Vector3(0, 0.12, 0.0)]), PackedFloat32Array([0.085, 0.065, 0.055]), 7), leather, Vector3(x, 0, 0))
		add_part(leg, _path("bb_boot", PackedVector3Array([Vector3(0, 0.26, -0.01), Vector3(0, 0.06, -0.01),
			Vector3(0, 0.05, 0.12), Vector3(0, 0.04, 0.22)]), PackedFloat32Array([0.07, 0.07, 0.055, 0.0]), 6),
			iron, Vector3(x, 0, 0))
		add_part(leg, cyl(0.08, 0.075, 0.05, 7), leather, Vector3(x, 0.27, 0.0))
	# ---- Hips: belt with a bone buckle, three tattered coat tails hanging behind to the calves.
	add_part(hips, cyl(0.19, 0.25, 0.26, 8, false), cdark, Vector3(0, 0.76, 0))
	add_part(hips, cyl(0.20, 0.20, 0.06, 8), leather, Vector3(0, 0.88, 0))
	add_part(hips, sphere(0.045, 6, 3), bone, Vector3(0, 0.88, 0.2))
	add_part(hips, _tails_mesh(), cdark, Vector3.ZERO)
	# ---- Chest: violet team jerkin (tapered), iron gorget, bone rib harness, the slung quiver + glowing barbs.
	add_part(chest, _path("bb_torso", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 1.02, 0.01),
		Vector3(0, 1.20, 0.02), Vector3(0, 1.33, 0.0), Vector3(0, 1.40, 0.0)]),
		PackedFloat32Array([0.18, 0.19, 0.22, 0.22, 0.13]), 8), cloth, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.8))
	add_part(chest, cyl(0.12, 0.25, 0.14, 8), iron, Vector3(0, 1.34, 0))
	add_part(chest, _ribs_mesh(), palette(&"shadow_silver"), Vector3.ZERO)
	var qa := Vector3(0.45, 0.89, 0.0)
	var qc := Vector3(0.02, 1.08, -0.24)
	add_part(chest, cyl(0.07, 0.06, 0.60, 6), leather, qc, _euler_up(qa))
	add_part(chest, cyl(0.08, 0.08, 0.05, 6), iron, qc + qa * 0.27, _euler_up(qa))
	add_part(chest, box(Vector3(0.05, 0.62, 0.03)), leather, Vector3(0.0, 1.12, 0.20), Vector3(-8, 0, 36))
	var qtop := qc + qa * 0.30
	add_part(chest, _quiver_shafts_mesh(qtop, qa), leather, Vector3.ZERO)
	add_part(chest, _barbs_mesh(qtop, qa), glow, Vector3.ZERO)
	# ---- Head: dark face in a deep team cowl, a pale bone half-mask with fangs, two bone hooks sweeping up-back.
	add_part(head, sphere(0.115, 8, 5), skin, Vector3(0, 1.53, 0.06))
	add_part(head, sphere(0.17, 10, 5), cloth, Vector3(0, 1.56, -0.03), Vector3(-8, 0, 0), Vector3(1.0, 1.12, 1.12))
	add_part(head, torus(0.10, 0.14, 10), cdark, Vector3(0, 1.55, 0.11), Vector3(80, 0, 0), Vector3(1.0, 1.0, 1.2))
	add_part(head, _path("bb_mask", PackedVector3Array([Vector3(0, 1.52, 0.13), Vector3(0, 1.46, 0.16),
		Vector3(0, 1.40, 0.13)]), PackedFloat32Array([0.085, 0.075, 0.045]), 7), bone, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.7))
	add_part(head, _fangs_mesh(), bone, Vector3.ZERO)
	for ex: float in [-0.042, 0.042]:
		add_part(head, box(Vector3(0.045, 0.028, 0.04)), palette(&"unit_eye_dark"), Vector3(ex, 1.555, 0.165))
	add_part(head, _hooks_mesh(), bone, Vector3.ZERO)
	var trim := add_part(head, torus(0.15, 0.19, 12), palette(&"unit_gold_trim"), Vector3(0, 1.66, -0.03),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: dark sleeves, leather gloves, a bone-plated bracer on the bow arm, iron spaulder on the draw arm.
	_limb(arm_l, SH_L, GRIP_L, 0.065, cdark, 0.07, leather)
	var dl := (GRIP_L - SH_L).normalized()
	add_part(arm_l, cyl(0.08, 0.075, 0.16, 6), bone, SH_L.lerp(GRIP_L, 0.72), _euler_up(dl))
	_limb(arm_r, SH_R, HAND_R, 0.065, cdark, 0.07, leather)
	add_part(arm_r, sphere(0.10, 8, 4), iron, SH_R + Vector3(0.03, 0.02, 0.0), Vector3(0, 0, -20), Vector3(1.1, 0.7, 1.0))
	add_part(arm_l, sphere(0.09, 8, 4), cloth, SH_L + Vector3(-0.02, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	# ---- The bow (keep_separate container under the bow arm, counter-rotated to stay upright on the draw).
	_bow = Node3D.new()
	_bow.name = "Bow"
	_bow.set_meta(&"keep_separate", true)
	_bow.position = GRIP_L - model_origin(arm_l)
	_bow.rotation_degrees = Vector3(BOW_TILT, 0, 0)
	arm_l.add_child(_bow)
	var body := MeshInstance3D.new()
	body.name = "BowBody"
	body.mesh = _bow_mesh(obsidian, bone)
	body.set_meta(&"keep_separate", true)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_bow.add_child(body)
	_bstring = _bow_part(_string_mesh(), bone, "BowString")
	_string_drawn = _bow_part(_drawn_mesh(), bone, "StringDrawn")
	_barrow = _bow_part(_arrow_mesh(), leather, "Arrow")
	_head_glow = _bow_part(_head_mesh(), glow, "ArrowHead")
	_head_glow.set_meta(&"own_glow", true)
	_string_drawn.visible = false
	_barrow.visible = false
	_head_glow.visible = false
	# ---- Fx: release burst off the bow front, dissolve death motes, the violet pool blob.
	_burst = make_motes(VIOLET, 10, 0.4, 0.08, 2.8, 0.09, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = Vector3(0, 0.02, 0.36)
	_bow.add_child(_burst)
	var dm := make_motes(VIOLET, 12, 1.1, 0.25, 1.3, 0.12, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.7, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.42, Color(0.1, 0.03, 0.16, 0.55))


func _bow_part(mesh: Mesh, mat: Material, part_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	_bow.add_child(mi)
	return mi


func _limb(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float, end_mat: Material) -> void:
	var d := b - a
	add_part(pivot, cyl(r * 0.85, r, d.length(), 7), mat, a + d * 0.5, _euler_up(d.normalized()))
	add_part(pivot, sphere(end_r, 7, 4), end_mat, b)


static func _euler_up(dir: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, dir.normalized())).get_euler() / DEG


# ================================================================ hooks

## World position where the arrow leaves the bow.
func get_bow_tip_position() -> Vector3:
	if _bow == null:
		return global_position + Vector3(0, 1.3, 0.4)
	return _bow.global_transform * Vector3(0, 0, 0.36)


# ================================================================ meshes (cached)

static func _path_into(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int,
		xf: Transform3D = Transform3D.IDENTITY) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			xf * Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_path_into(st, pts, radii, seg)
	st.index()
	return _cached(key, st.commit())


## Three ragged coat tails behind the legs (flattened tapering strips, the middle one longest).
static func _tails_mesh() -> Mesh:
	const KEY := "bb_tails"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var xs: Array[float] = [-0.13, 0.0, 0.13]
	var ends: Array[float] = [0.34, 0.22, 0.38]
	for i: int in 3:
		var x: float = xs[i]
		var pts := PackedVector3Array([Vector3(x, 0.86, -0.17), Vector3(x * 1.2, 0.62, -0.25),
			Vector3(x * 1.35, ends[i], -0.30 - 0.02 * i)])
		_path_into(st, pts, PackedFloat32Array([0.085, 0.075, 0.0]), 5,
			Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, 1.0)), Vector3.ZERO))
	st.index()
	var m := st.commit()
	# flatten the strips toward the body (a cloth read, not rods)
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for j: int in v.size():
		var z: float = v[j].z
		var zc: float = -0.17 - (0.86 - v[j].y) * 0.22
		v[j].z = zc + (z - zc) * 0.35
	arr[Mesh.ARRAY_VERTEX] = v
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _cached(KEY, out)


## Bone rib harness on the jerkin: a sternum bar and 3 curved rib pairs.
static func _ribs_mesh() -> Mesh:
	const KEY := "bb_ribs"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([Vector3(0, 1.30, 0.19), Vector3(0, 1.00, 0.19)]), PackedFloat32Array([0.025, 0.02]), 5)
	for k: int in 2:
		var y: float = 1.22 - 0.11 * k
		for s: float in [-1.0, 1.0]:
			_path_into(st, PackedVector3Array([Vector3(0.01 * s, y, 0.19), Vector3(0.10 * s, y - 0.02, 0.17),
				Vector3(0.17 * s, y - 0.06, 0.10)]), PackedFloat32Array([0.026, 0.022, 0.0]), 4)
	st.index()
	return _cached(KEY, st.commit())


## Two fangs from the mask's jaw.
static func _fangs_mesh() -> Mesh:
	const KEY := "bb_fangs"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		st.append_from(cyl(0.0, 0.018, 0.07, 4), 0, Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0.035 * s, 1.40, 0.17)))
	st.index()
	return _cached(KEY, st.commit())


## Two bone hooks from the cowl's temples, sweeping up and back, curling at the tips (the crest read).
static func _hooks_mesh() -> Mesh:
	const KEY := "bb_hooks"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		_path_into(st, PackedVector3Array([Vector3(0.11 * s, 1.63, 0.02), Vector3(0.16 * s, 1.76, -0.06),
			Vector3(0.19 * s, 1.83, -0.20), Vector3(0.17 * s, 1.83, -0.32), Vector3(0.14 * s, 1.76, -0.36)]),
			PackedFloat32Array([0.045, 0.036, 0.026, 0.016, 0.0]), 5)
	st.index()
	return _cached(KEY, st.commit())


static func _quiver_shafts_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "bb_qshafts"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.025), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.18, 0.24, 0.21]
	for i: int in 3:
		var a: Vector3 = top + offs[i]
		_path_into(st, PackedVector3Array([a - qa * 0.05, a + qa * lens[i]]), PackedFloat32Array([0.014, 0.014]), 4)
	st.index()
	return _cached(KEY, st.commit())


## The barbed heads of the quiver arrows (one glow mesh): a long point + two swept-back barbs each.
static func _barbs_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "bb_qbarbs"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.025), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.18, 0.24, 0.21]
	var b := Basis(Quaternion(Vector3.UP, qa))
	for i: int in 3:
		var c: Vector3 = top + offs[i] + qa * lens[i]
		_barb_into(st, Transform3D(b * Basis(Vector3.UP, 1.1 * i), c), 1.3)
	st.index()
	return _cached(KEY, st.commit())


## One barbed head along +Y at `xf` (point + 2 back-swept barbs).
static func _barb_into(st: SurfaceTool, xf: Transform3D, s: float) -> void:
	st.append_from(cyl(0.0, 0.035 * s, 0.13 * s, 4), 0, xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.065 * s, 0)))
	for side: float in [-1.0, 1.0]:
		var bb := Basis(Vector3.BACK, side * deg_to_rad(150.0))
		st.append_from(cyl(0.0, 0.016 * s, 0.08 * s, 3), 0, xf * Transform3D(bb, Vector3(0.03 * side * s, 0.01 * s, 0)))


## Two surfaces: obsidian recurve limbs with barbs down the back (0), bone hook tips + a bone grip (1).
static func _bow_mesh(obsidian: Material, bone: Material) -> Mesh:
	const KEY := "bb_bow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [1.0, -1.0]:
		var L: float = 0.93 if s > 0.0 else 0.88
		var pts := PackedVector3Array([Vector3(0, 0.0, 0.03), Vector3(0, 0.25 * L * s, 0.05),
			Vector3(0, 0.52 * L * s, 0.0), Vector3(0, 0.76 * L * s, -0.10), Vector3(0, 0.92 * L * s, -0.18),
			Vector3(0, 1.0 * L * s, -0.12)])
		_path_into(st, pts, PackedFloat32Array([0.055, 0.05, 0.042, 0.034, 0.026, 0.02]), 5)
		# 3 obsidian barbs down the back (+Z) of each limb, raked toward the tip (one value with the limb: calm at 25 m)
		for k: int in 3:
			var u: float = 0.28 + 0.2 * k
			var p := Vector3(0, u * L * s, 0.06 - 0.12 * (u - 0.25) * (u - 0.25) * 4.0)
			var d := Vector3(0, 0.6 * s, 1.0).normalized()
			st.append_from(cyl(0.0, 0.032, 0.14, 5), 0, Transform3D(Basis(Quaternion(Vector3.UP, d)), p + d * 0.05))
	st.index()
	var m: ArrayMesh = st.commit()
	m.surface_set_material(0, obsidian)
	var st2 := SurfaceTool.new()
	st2.append_from(cyl(0.065, 0.065, 0.22, 6), 0, Transform3D.IDENTITY)
	for s: float in [1.0, -1.0]:
		var L: float = 0.93 if s > 0.0 else 0.88
		var tip := Vector3(0, 1.0 * L * s, -0.12)
		_path_into(st2, PackedVector3Array([tip, tip + Vector3(0, 0.07 * s, 0.05), tip + Vector3(0, 0.05 * s, 0.13)]),
			PackedFloat32Array([0.03, 0.022, 0.0]), 4)
	st2.index()
	st2.commit(m)
	m.surface_set_material(1, bone)
	return _cached(KEY, m)


static func _string_mesh() -> Mesh:
	const KEY := "bb_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, TIP_D]), PackedFloat32Array([0.015, 0.015]), 4)
	st.index()
	return _cached(KEY, st.commit())


static func _drawn_mesh() -> Mesh:
	const KEY := "bb_string_drawn"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, NOCK, TIP_D]), PackedFloat32Array([0.015, 0.017, 0.015]), 4)
	st.index()
	return _cached(KEY, st.commit())


static func _arrow_mesh() -> Mesh:
	const KEY := "bb_arrow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([NOCK, ARROW_HEAD]), PackedFloat32Array([0.016, 0.016]), 4)
	st.index()
	return _cached(KEY, st.commit())


## The nocked arrow's barbed head (glow), pointing +Z at the arrow tip.
static func _head_mesh() -> Mesh:
	const KEY := "bb_arrow_head"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_barb_into(st, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), ARROW_HEAD), 1.2)
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

static func _bb_kf(t: float, k: PackedFloat32Array) -> float:
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


func _bb_drawn(on: bool) -> void:
	if on == _drawn_on or _bstring == null:
		return
	_drawn_on = on
	_bstring.visible = not on
	_string_drawn.visible = on
	_barrow.visible = on
	_head_glow.visible = on


func _set_bow_x(arm_deg: float) -> void:
	var x: float = BOW_TILT - arm_deg
	if absf(x - _bow_x_written) < 0.01 or _bow == null:
		return
	_bow_x_written = x
	_bow.rotation.x = x * DEG


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bow_draw":
		return super._pose_attack(prev, t)
	var al := _bb_kf(t, A_ARM_L)
	var yaw := _bb_kf(t, A_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(0, yaw * DEG, 0))
	rot(P_HEAD, Vector3(_bb_kf(t, A_HEAD_X) * DEG, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_bb_kf(t, A_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _bb_kf(t, A_ARM_RZ)))
	pos(P_ROOT, Vector3(0, 0, _bb_kf(t, A_ROOT_Z)))
	var st: float = yaw / 28.0
	rot(P_LEG_L, Vector3(-16.0 * DEG * st, 0, -6.0 * DEG * st))
	rot(P_LEG_R, Vector3(12.0 * DEG * st, 0, 6.0 * DEG * st))
	rot(P_ROOT, Vector3(-5.0 * DEG * st, 0, 0))
	_set_bow_x(al)
	_bb_drawn(t > 0.04 and t < RELEASE)
	_charge = clampf(t / RELEASE, 0.0, 1.0) if t < RELEASE else 0.0
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	var al := _bb_kf(t, C_ARM_L)
	var yaw := _bb_kf(t, C_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(_bb_kf(t, C_CHEST_X) * DEG, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_bb_kf(t, C_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _bb_kf(t, C_ARM_RZ)))
	_set_bow_x(al)
	_bb_drawn(t > 0.12 and t < CAST_RELEASE)
	_charge = clampf((t - 0.2) / (CAST_RELEASE - 0.2), 0.0, 1.0) * 1.6 if t < CAST_RELEASE else 0.0
	if t >= CAST_RELEASE and not _cast_loosed:
		_cast_loosed = true
		_loose(1.6)
	return CAST_LEN


func _loose(amount: float) -> void:
	_flare = amount
	_charge = 0.0
	_bb_drawn(false)
	if _burst and _tier < 2:
		_burst.restart()


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"release":
		_loose(1.0)
	elif ev == &"cast_start":
		_cast_loosed = false
	elif ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_bb_drawn(false)
		_charge = 0.0
		_set_bow_x(0.0)


## Stalking walk: leaning in a little, the long bow kept calm (the kit swings the bow arm -18 deg: net -5).
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3(13.0 * DEG * s * w, 0, 0))
	rot(P_CHEST, Vector3(6.0 * DEG * w, 0, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(-5.0 * DEG * w, 0, 0))


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _dead:
		if _drawn_on:
			_bb_drawn(false)
		return
	if _action == &"":
		if _drawn_on:
			_bb_drawn(false)
		_set_bow_x(0.0)
		_charge = 0.0
	_flare = maxf(0.0, _flare - dt / 0.35)
	if _head_glow and _drawn_on:
		var b: float = snappedf(glow_level() * (1.2 + 1.4 * _charge), 0.05)
		if b != _head_written:
			_head_written = b
			_head_glow.set_instance_shader_parameter(&"glow_boost", b)


func _on_revive() -> void:
	super._on_revive()
	_flare = 0.0
	_charge = 0.0
	_head_written = -1.0
	_drawn_on = true
	_bb_drawn(false)
	_set_bow_x(0.0)
