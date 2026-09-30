class_name ChampionWeaponKit
extends RefCounted
## Champion class weapons (skills-rework.md 3, 5, task 11.V1): the shared kit the four champion models hold once they
## take up a class. Static, built once per game, no nodes: `CharacterModel.set_weapon_class(class_id)` merges these
## meshes into the model's own pivot meshes (0 extra draw instances, 0 lights). Every champion uses the SAME meshes and
## the SAME 8 materials of `materials/` (shared, read-only; `weapon_team_cloth` is recoloured by set_team_color).
## Pieces (piece space: long weapons along +Y, origin = the fist / the strap point; the kit places them with
## `CharacterModel._weapon_grip(piece)` = `_weapon_slot(slot) * piece_hold(piece)`):
##   spear         2.3 m ash shaft, 0.36 m leaf blade, team tassel under the blade          slot hand_r
##   quiver        leather back quiver of 3 short javelins                                   slot back
##   javelin       one javelin in the left hand (hidden; shown by the Hobbling Javelin throw)   slot hand_l
##   sword         0.9 m arming sword, steel blade, brass guard and pommel                     slot hand_r
##   round_shield  r 0.4 oak board, iron rim and rivets, team-colour boss                      slot hand_l
##   greatsword    1.6 m blade 0.12 m wide, long grip, wide iron cross-guard                   slot hand_r
##   staff         1.8 m gnarled staff, 3 prongs around a floating crystal (glow (0.6, 0.75, 1.0) 1.5)  slot hand_r
## Class -> pieces: CLASS_PIECES. Attack style / windup per class: ATTACK_STYLE / ATTACK_WINDUP.
## Previews: tools/champion_weapons_preview.tscn (docs/art/screens/champion_weapons_*.png).

const DIR := "res://art/units/champions/weapons/"
const MAT_DIR := DIR + "materials/"
const DEG := PI / 180.0

const CLASS_IDS: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
## Class id -> the pieces a model holds (in this order; the first one is the main weapon, see piece_tip).
const CLASS_PIECES: Dictionary = {
	&"spear": [&"spear", &"quiver", &"javelin"],
	&"sword_shield": [&"sword", &"round_shield"],
	&"two_hand": [&"greatsword"],
	&"wizard": [&"staff"],
}
## Pieces merged only while a pose asks for them (CharacterModel.show_weapon_piece(piece, true)).
const HIDDEN_BY_DEFAULT: Array[StringName] = [&"javelin"]
const PIECE_SLOT: Dictionary = {
	&"spear": &"hand_r", &"quiver": &"back", &"javelin": &"hand_l", &"sword": &"hand_r", &"round_shield": &"hand_l",
	&"greatsword": &"hand_r", &"staff": &"hand_r",
}
const ATTACK_STYLE: Dictionary = {
	&"spear": &"spear_thrust", &"sword_shield": &"sword_slash", &"two_hand": &"great_cleave", &"wizard": &"staff_bolt",
}
## Ranged release (s) read by Unit (the Wizard bolt); melee styles strike at their own frame with windup 0.
const ATTACK_WINDUP: Dictionary = {&"spear": 0.0, &"sword_shield": 0.0, &"two_hand": 0.0, &"wizard": 0.12}
const CRYSTAL_COLOR := Color(0.6, 0.75, 1.0)

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}
## In-game read pass (2026-09-30): at RTS zoom 30 the class weapons were hair-thin lines. Every piece is built as
## authored, then widened across its length (piece x / z; the length along y and the grips are unchanged) and the
## round shield scaled as a whole, so each class keeps one clear weapon silhouette: spear, sword + shield, greatsword,
## staff.
const READ_WIDEN := {&"spear": 1.35, &"javelin": 1.25, &"sword": 1.35, &"greatsword": 1.3, &"staff": 1.35}
const READ_SHIELD := 1.15


# ================================================================ public (static)

static func has_class(class_id: StringName) -> bool:
	return CLASS_PIECES.has(class_id)


## The pieces of a class (a copy; empty for &"" or an unknown id).
static func pieces_for(class_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for p: StringName in CLASS_PIECES.get(class_id, []):
		out.append(p)
	return out


static func slot_of(piece: StringName) -> StringName:
	return PIECE_SLOT.get(piece, &"hand_r")


static func attack_style_for(class_id: StringName) -> StringName:
	return ATTACK_STYLE.get(class_id, &"")


static func attack_windup_for(class_id: StringName) -> float:
	return float(ATTACK_WINDUP.get(class_id, 0.0))


static func is_hidden_by_default(piece: StringName) -> bool:
	return HIDDEN_BY_DEFAULT.has(piece)


## Shared weapon material by file name (e.g. &"weapon_steel"), loaded once.
static func material(name: StringName) -> Material:
	if not _mats.has(name):
		_mats[name] = load(MAT_DIR + String(name) + ".tres")
	return _mats[name]


## Every shared weapon material (for budget tests).
static func all_materials() -> Array[Material]:
	var out: Array[Material] = []
	for n: StringName in [&"weapon_ash", &"weapon_wood_dark", &"weapon_steel", &"weapon_iron", &"weapon_brass",
			&"weapon_leather", &"weapon_team_cloth", &"weapon_crystal_glow"]:
		out.append(material(n))
	return out


## Piece space -> slot frame at rest: how a generic champion holds the piece (see the header). Models tune the slot
## (the fist) with `_weapon_slot`, or the whole placement with `_weapon_grip`.
static func piece_hold(piece: StringName) -> Transform3D:
	match piece:
		&"spear":
			# Held mid-shaft (40 % from the butt), tip forward and 30 deg up, turned a little outward.
			return Transform3D(Basis(Vector3.UP, 6.0 * DEG) * Basis(Vector3.RIGHT, 60.0 * DEG), Vector3(0.02, 0.0, 0.0))
		&"quiver":
			# Slung across the back: the top leans toward the left shoulder and back.
			return Transform3D(Basis.from_euler(Vector3(-12.0, 0.0, 18.0) * DEG), Vector3.ZERO)
		&"javelin":
			# Left fist, pointing down-back at rest: forward-up once the arm is cocked over the shoulder (-160 deg).
			return Transform3D(Basis(Vector3.RIGHT, -128.0 * DEG), Vector3.ZERO)
		&"sword":
			# Point forward and 30 deg down, a touch outward; the edge in the swing plane.
			return Transform3D(Basis(Vector3.UP, 8.0 * DEG) * Basis(Vector3.RIGHT, 120.0 * DEG), Vector3.ZERO)
		&"round_shield":
			# On the left forearm, face turned 40 deg outward, top tipped back.
			return Transform3D(Basis.from_euler(Vector3(-8.0, -40.0, 0.0) * DEG), Vector3(-0.04, 0.06, 0.05))
		&"greatsword":
			# Up from the fist and leaning back on the shoulder (a tool held UP: its head moves forward when the arm
			# rotates positive, kit/README.md).
			var d := Vector3(0.10, 0.88, -0.46).normalized()
			var x := (Vector3.RIGHT - d * d.dot(Vector3.RIGHT)).normalized()
			return Transform3D(Basis(x, d, x.cross(d)), Vector3.ZERO)
		&"staff":
			# Upright, the head 7 deg forward and 6 deg outward.
			return Transform3D(Basis.from_euler(Vector3(7.0, 0.0, -6.0) * DEG), Vector3.ZERO)
	return Transform3D.IDENTITY


## The working end of a piece in piece space (spear / sword / greatsword tip, staff crystal, shield boss...).
static func piece_tip(piece: StringName) -> Vector3:
	match piece:
		&"spear":
			return Vector3(0, 1.80, 0)
		&"sword":
			return Vector3(0, 0.82, 0)
		&"greatsword":
			return Vector3(0, 1.78, 0)
		&"staff":
			return Vector3(0, 1.10, 0)
		&"round_shield":
			return Vector3(0, 0, 0.13)
		&"quiver":
			return Vector3(0, 0.62, 0)
		&"javelin":
			return Vector3(0, 0.58, 0)
	return Vector3.ZERO


## The piece's mesh (piece space, one surface per material), built once and shared by every champion.
static func piece_mesh(piece: StringName) -> ArrayMesh:
	if _meshes.has(piece):
		return _meshes[piece]
	var m: ArrayMesh
	match piece:
		&"spear":
			m = _spear_mesh()
		&"quiver":
			m = _quiver_mesh()
		&"javelin":
			m = _javelin_mesh()
		&"sword":
			m = _sword_mesh()
		&"round_shield":
			m = _shield_mesh()
		&"greatsword":
			m = _greatsword_mesh()
		&"staff":
			m = _staff_mesh()
		_:
			m = ArrayMesh.new()
	if READ_WIDEN.has(piece):
		m = _scaled(m, Vector3(READ_WIDEN[piece], 1.0, READ_WIDEN[piece]))
	elif piece == &"round_shield":
		m = _scaled(m, Vector3.ONE * READ_SHIELD)
	_meshes[piece] = m
	return m


## A copy of `m` scaled by `k` in piece space (normals corrected), same surfaces and materials.
static func _scaled(m: ArrayMesh, k: Vector3) -> ArrayMesh:
	var out := ArrayMesh.new()
	var nb := Basis.from_scale(k).inverse().transposed()
	for s: int in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i: int in v.size():
			v[i] = v[i] * k
		arr[Mesh.ARRAY_VERTEX] = v
		if arr[Mesh.ARRAY_NORMAL] != null:
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for j: int in n.size():
				n[j] = (nb * n[j]).normalized()
			arr[Mesh.ARRAY_NORMAL] = n
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(s, m.surface_get_material(s))
	return out


## Vertex count of a piece (budget tests).
static func piece_vertices(piece: StringName) -> int:
	var m := piece_mesh(piece)
	var n := 0
	for s: int in m.get_surface_count():
		n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


# ================================================================ geometry helpers

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## Appends primitive `m` (surface 0, smooth normals) transformed by xf.
static func _put(acc: Array, m: Mesh, xf: Transform3D) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for j: int in v.size():
		acc[0].append(xf * v[j])
		acc[1].append((nb * nr[j]).normalized())
		acc[2].append(Vector2.ZERO)
	if ix.is_empty():
		for j: int in v.size():
			acc[3].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[3].append(b0 + ix[j])


## One flat triangle whose front faces `hint` (Godot fronts are clockwise: normal = (c - a) x (b - a)).
static func _tri(acc: Array, a: Vector3, b: Vector3, c: Vector3, hint: Vector3) -> void:
	var n := (c - a).cross(b - a)
	if n.length_squared() < 1e-14:
		return
	if n.dot(hint) < 0.0:
		var t := b
		b = c
		c = t
		n = -n
	n = n.normalized()
	var i0: int = (acc[0] as PackedVector3Array).size()
	for p: Vector3 in [a, b, c]:
		acc[0].append(p)
		acc[1].append(n)
		acc[2].append(Vector2.ZERO)
	acc[3].append(i0)
	acc[3].append(i0 + 1)
	acc[3].append(i0 + 2)


## Primitives (own tiny cache: this script never depends on CharacterModel, which preloads it).
static func _cyl(top_r: float, bottom_r: float, h: float, seg: int = 8, caps: bool = true) -> Mesh:
	var key := "cyl%s_%s_%s_%d_%s" % [top_r, bottom_r, h, seg, caps]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top_r
		m.bottom_radius = bottom_r
		m.height = h
		m.radial_segments = seg
		m.rings = 1
		m.cap_top = caps and top_r > 0.0
		m.cap_bottom = caps and bottom_r > 0.0
		_meshes[key] = m
	return _meshes[key]


static func _sphere(r: float, radial: int = 10, rings: int = 5) -> Mesh:
	var key := "sph%s_%d_%d" % [r, radial, rings]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = radial
		m.rings = rings
		_meshes[key] = m
	return _meshes[key]


static func _box(size: Vector3) -> Mesh:
	var key := "box%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _meshes[key]


## Torus in the XZ plane (axis +Y).
static func _torus(inner: float, outer: float, rings: int = 16) -> Mesh:
	var key := "tor%s_%s_%d" % [inner, outer, rings]
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = rings
		m.ring_segments = 6
		_meshes[key] = m
	return _meshes[key]


static func _xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), at)


## Cylinder from a to b (radius ra at a, rb at b).
static func _seg(acc: Array, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6, caps: bool = false) -> void:
	var d := b - a
	var l := d.length()
	if l < 1e-5:
		return
	var dn := d / l
	var bs: Basis
	if dn.y < -0.9999:
		bs = Basis(Vector3.RIGHT, PI)
	else:
		bs = Basis(Quaternion(Vector3.UP, dn))
	bs = bs.scaled_local(Vector3(1.0, l, 1.0))
	_put(acc, _cyl(rb, ra, 1.0, seg, caps), Transform3D(bs, (a + b) * 0.5))


## Flat-shaded blade along +Y from y0: prof = [[t 0..1, half width, half thickness], ...] (last = the point).
## Diamond section (edges and ridges); the width lies along X (width_on_x) or Z.
static func _blade(acc: Array, y0: float, length: float, prof: Array, width_on_x: bool) -> void:
	var w_ax := Vector3.RIGHT if width_on_x else Vector3.BACK
	var t_ax := Vector3.BACK if width_on_x else Vector3.RIGHT
	var rings: Array = []
	for p: Array in prof:
		var c := Vector3(0.0, y0 + float(p[0]) * length, 0.0)
		var w: float = p[1]
		var th: float = p[2]
		rings.append([c + w_ax * w, c + t_ax * th, c - w_ax * w, c - t_ax * th])
	for k: int in rings.size() - 1:
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		var mid := Vector3(0.0, ((ra[0] as Vector3).y + (rb[0] as Vector3).y) * 0.5, 0.0)
		for j: int in 4:
			var j2 := (j + 1) % 4
			var p0: Vector3 = ra[j]
			var p1: Vector3 = ra[j2]
			var p2: Vector3 = rb[j2]
			var p3: Vector3 = rb[j]
			var hint := (p0 + p1 + p2 + p3) * 0.25 - mid
			_tri(acc, p0, p1, p2, hint)
			_tri(acc, p0, p2, p3, hint)
	var r0: Array = rings[0]
	_tri(acc, r0[0], r0[1], r0[2], Vector3.DOWN)
	_tri(acc, r0[0], r0[2], r0[3], Vector3.DOWN)


## Flat bipyramid (crystal): `sides` around, radius r, half heights up / down, turned `yaw` deg.
static func _crystal(acc: Array, c: Vector3, r: float, up: float, down: float, sides: int, yaw: float) -> void:
	var top := c + Vector3(0, up, 0)
	var bot := c - Vector3(0, down, 0)
	for k: int in sides:
		var a0 := (yaw + 360.0 * float(k) / float(sides)) * DEG
		var a1 := (yaw + 360.0 * float(k + 1) / float(sides)) * DEG
		var p0 := c + Vector3(sin(a0) * r, 0, cos(a0) * r)
		var p1 := c + Vector3(sin(a1) * r, 0, cos(a1) * r)
		var out := (p0 + p1) * 0.5 - c
		_tri(acc, top, p0, p1, out + Vector3(0, 0.3 * r, 0))
		_tri(acc, bot, p0, p1, out - Vector3(0, 0.3 * r, 0))


## One ArrayMesh from [acc, material] pairs (empty accs skipped).
static func _commit(surfaces: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for s: Array in surfaces:
		var acc: Array = s[0]
		if (acc[0] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[2]
		arrays[Mesh.ARRAY_INDEX] = acc[3]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, s[1])
	return am


# ================================================================ pieces
# Chunky on purpose (the "3 heads tall" painted style, read at 40 m): lengths follow skills-rework.md 5, shafts and
# blades are thicker / wider than real ones. Blades show their flat to the front (width along X) at rest.

## Spear: ash shaft (butt -0.92 .. socket 1.38), leather grip wrap at the fist, iron butt cap and socket, a leaf blade
## with a raised midrib, a team-colour tassel (collar + 6 strands hanging back under the blade).
static func _spear_mesh() -> ArrayMesh:
	var ash := _bucket()
	var iron := _bucket()
	var steel := _bucket()
	var lea := _bucket()
	var team := _bucket()
	_seg(ash, Vector3(0, -0.92, 0), Vector3(0, 1.38, 0), 0.036, 0.031, 7)
	_seg(lea, Vector3(0, -0.13, 0), Vector3(0, 0.13, 0), 0.043, 0.043, 7, true)
	for y: float in [-0.15, 0.15]:
		_put(lea, _torus(0.036, 0.052, 8), _xf(Vector3(0, y, 0)))
	_seg(iron, Vector3(0, -1.0, 0), Vector3(0, -0.90, 0), 0.018, 0.042, 7, true)
	_seg(iron, Vector3(0, 1.31, 0), Vector3(0, 1.46, 0), 0.043, 0.024, 7, true)
	_put(iron, _torus(0.034, 0.052, 8), _xf(Vector3(0, 1.32, 0)))
	_blade(steel, 1.44, 0.36, [[0.0, 0.02, 0.018], [0.14, 0.064, 0.019], [0.42, 0.078, 0.02], [0.78, 0.044, 0.015],
		[1.0, 0.0, 0.0]], true)
	# Tassel: hangs down and back along the shaft (piece space: -Y streams back, +Z droops toward the ground at rest).
	_put(team, _sphere(0.05, 8, 4), _xf(Vector3(0, 1.28, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0)))
	var hang := Vector3(0.0, -0.75, 0.43).normalized()
	for k: int in 6:
		var a := TAU * float(k) / 6.0 + 0.3
		var root := Vector3(cos(a) * 0.034, 1.27, sin(a) * 0.034)
		var tip := root + hang * (0.24 + 0.05 * float(k % 2)) + Vector3(cos(a) * 0.05, 0.0, sin(a) * 0.05)
		_seg(team, root, tip, 0.021, 0.007, 4, true)
	return _commit([[ash, material(&"weapon_ash")], [lea, material(&"weapon_leather")], [iron, material(&"weapon_iron")],
		[steel, material(&"weapon_steel")], [team, material(&"weapon_team_cloth")]])


## Back quiver (origin = its centre, axis +Y): leather tube with an iron rim, bands and foot; 3 short javelins
## sticking out, steel heads up.
static func _quiver_mesh() -> ArrayMesh:
	var lea := _bucket()
	var iron := _bucket()
	var ash := _bucket()
	var steel := _bucket()
	var dark := _bucket()
	_put(lea, _cyl(0.092, 0.08, 0.56, 9), _xf(Vector3.ZERO))
	_put(iron, _torus(0.082, 0.106, 12), _xf(Vector3(0, 0.28, 0)))
	_put(iron, _cyl(0.082, 0.072, 0.05, 9), _xf(Vector3(0, -0.295, 0)))
	for y: float in [0.10, -0.14]:
		_put(dark, _torus(0.082, 0.1, 12), _xf(Vector3(0, y, 0)))
	var jav: Array = [[Vector3(0.034, 0, 0.022), 0.60, Vector3(6, 0, -5)], [Vector3(-0.036, 0, 0.014), 0.68, Vector3(4, 0, 6)],
		[Vector3(0.002, 0, -0.038), 0.55, Vector3(-6, 0, 1)]]
	for j: Array in jav:
		var b := Basis.from_euler((j[2] as Vector3) * DEG)
		var base: Vector3 = j[0]
		var top: float = j[1]
		var p0 := base + b * Vector3(0, -0.20, 0)
		var p1 := base + b * Vector3(0, top, 0)
		_seg(ash, p0, p1, 0.019, 0.017, 5, true)
		var head := _bucket()
		_blade(head, 0.0, 0.15, [[0.0, 0.015, 0.012], [0.3, 0.034, 0.013], [1.0, 0.0, 0.0]], true)
		var hx := Transform3D(b, p1)
		var arr_v: PackedVector3Array = head[0]
		var arr_n: PackedVector3Array = head[1]
		var b0: int = (steel[0] as PackedVector3Array).size()
		for k: int in arr_v.size():
			steel[0].append(hx * arr_v[k])
			steel[1].append((b * arr_n[k]).normalized())
			steel[2].append(Vector2.ZERO)
		for k: int in (head[3] as PackedInt32Array).size():
			steel[3].append(b0 + int(head[3][k]))
	return _commit([[lea, material(&"weapon_leather")], [iron, material(&"weapon_iron")], [dark, material(&"weapon_wood_dark")],
		[ash, material(&"weapon_ash")], [steel, material(&"weapon_steel")]])


## A single javelin for the left hand (origin = the fist): ash shaft, leather wrap, steel leaf head.
static func _javelin_mesh() -> ArrayMesh:
	var ash := _bucket()
	var lea := _bucket()
	var steel := _bucket()
	_seg(ash, Vector3(0, -0.42, 0), Vector3(0, 0.46, 0), 0.02, 0.018, 5, true)
	_seg(lea, Vector3(0, -0.08, 0), Vector3(0, 0.08, 0), 0.027, 0.027, 6, true)
	_blade(steel, 0.45, 0.15, [[0.0, 0.016, 0.013], [0.3, 0.036, 0.013], [1.0, 0.0, 0.0]], true)
	return _commit([[ash, material(&"weapon_ash")], [lea, material(&"weapon_leather")], [steel, material(&"weapon_steel")]])


## Arming sword (origin = the fist): leather grip, brass pommel and cross-guard with knobs, a 0.72 m steel blade
## (width along X: its flat faces the front and the camera above).
static func _sword_mesh() -> ArrayMesh:
	var lea := _bucket()
	var brass := _bucket()
	var steel := _bucket()
	var iron := _bucket()
	_seg(lea, Vector3(0, -0.08, 0), Vector3(0, 0.08, 0), 0.03, 0.03, 6, true)
	_put(brass, _sphere(0.048, 8, 4), _xf(Vector3(0, -0.11, 0), Vector3.ZERO, Vector3(1.0, 0.85, 1.0)))
	_put(brass, _box(Vector3(0.30, 0.046, 0.056)), _xf(Vector3(0, 0.1, 0)))
	for x: float in [-0.155, 0.155]:
		_put(brass, _sphere(0.034, 6, 3), _xf(Vector3(x, 0.1, 0)))
	_blade(steel, 0.12, 0.72, [[0.0, 0.044, 0.015], [0.10, 0.043, 0.015], [0.80, 0.033, 0.012], [1.0, 0.0, 0.0]], true)
	# a dark fuller down both flats
	_put(iron, _box(Vector3(0.018, 0.46, 0.032)), _xf(Vector3(0, 0.40, 0)))
	return _commit([[lea, material(&"weapon_leather")], [brass, material(&"weapon_brass")], [steel, material(&"weapon_steel")],
		[iron, material(&"weapon_iron")]])


## Round shield (origin = the fist behind it, face +Z): oak board r 0.4, 4 plank seams, iron rim and 6 rivets, an iron
## ring round the team-colour boss, a leather grip on the back.
static func _shield_mesh() -> ArrayMesh:
	var oak := _bucket()
	var iron := _bucket()
	var team := _bucket()
	var lea := _bucket()
	var zc := 0.075
	_put(oak, _cyl(0.40, 0.40, 0.04, 22), _xf(Vector3(0, 0, zc), Vector3(90, 0, 0)))
	var front := zc + 0.02
	for x: float in [-0.20, -0.067, 0.067, 0.20]:
		var chord := 2.0 * sqrt(0.40 * 0.40 - x * x) - 0.05
		_put(iron, _box(Vector3(0.012, chord, 0.006)), _xf(Vector3(x, 0, front + 0.002)))
	_put(iron, _torus(0.372, 0.43, 24), _xf(Vector3(0, 0, zc), Vector3(90, 0, 0)))
	for k: int in 6:
		var a := TAU * float(k) / 6.0 + PI / 6.0
		_put(iron, _sphere(0.024, 6, 3), _xf(Vector3(cos(a) * 0.32, sin(a) * 0.32, front + 0.004)))
	_put(iron, _torus(0.11, 0.15, 14), _xf(Vector3(0, 0, front + 0.004), Vector3(90, 0, 0)))
	_put(team, _sphere(0.12, 10, 5), _xf(Vector3(0, 0, front + 0.01), Vector3.ZERO, Vector3(1.0, 1.0, 0.6)))
	_put(lea, _box(Vector3(0.06, 0.18, 0.035)), _xf(Vector3(0, 0, zc - 0.035)))
	return _commit([[oak, material(&"weapon_wood_dark")], [iron, material(&"weapon_iron")], [team, material(&"weapon_team_cloth")],
		[lea, material(&"weapon_leather")]])


## Greatsword (origin = the fist, near the guard): 0.42 m leather grip with a brass band, iron pommel, wide iron
## cross-guard with knobbed quillons and a brass langet, a 1.6 m x 0.13 m blade with a dark fuller (width along X).
static func _greatsword_mesh() -> ArrayMesh:
	var lea := _bucket()
	var iron := _bucket()
	var brass := _bucket()
	var steel := _bucket()
	_seg(lea, Vector3(0, -0.30, 0), Vector3(0, 0.12, 0), 0.034, 0.034, 7, true)
	_put(brass, _cyl(0.04, 0.04, 0.03, 8), _xf(Vector3(0, -0.09, 0)))
	_put(iron, _sphere(0.064, 8, 4), _xf(Vector3(0, -0.35, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0)))
	_put(brass, _cyl(0.0, 0.034, 0.05, 6), _xf(Vector3(0, -0.42, 0), Vector3(180, 0, 0)))
	_put(iron, _box(Vector3(0.52, 0.064, 0.07)), _xf(Vector3(0, 0.15, 0)))
	for x: float in [-0.27, 0.27]:
		_put(iron, _sphere(0.045, 6, 3), _xf(Vector3(x, 0.13, 0)))
	_put(brass, _box(Vector3(0.15, 0.09, 0.05)), _xf(Vector3(0, 0.2, 0)))
	_blade(steel, 0.18, 1.60, [[0.0, 0.066, 0.022], [0.10, 0.066, 0.022], [0.13, 0.06, 0.02], [0.88, 0.052, 0.017],
		[1.0, 0.0, 0.0]], true)
	_put(iron, _box(Vector3(0.024, 1.0, 0.046)), _xf(Vector3(0, 0.88, 0)))
	return _commit([[lea, material(&"weapon_leather")], [iron, material(&"weapon_iron")], [brass, material(&"weapon_brass")],
		[steel, material(&"weapon_steel")]])


## Wizard staff (origin = the fist): gnarled dark shaft with knots, iron foot, leather wrap, brass bands, a bulb and 3
## curling prongs around a FLOATING glowing crystal (a gap between prongs and crystal).
static func _staff_mesh() -> ArrayMesh:
	var wood := _bucket()
	var iron := _bucket()
	var lea := _bucket()
	var brass := _bucket()
	var glow := _bucket()
	var pts: Array[Vector3] = [Vector3(0, -0.80, 0), Vector3(0.018, -0.45, -0.01), Vector3(-0.016, -0.10, 0.009),
		Vector3(0.013, 0.25, 0.016), Vector3(-0.017, 0.58, -0.008), Vector3(0.0, 0.84, 0.0)]
	var radii: Array[float] = [0.036, 0.040, 0.041, 0.041, 0.040, 0.046]
	for k: int in pts.size() - 1:
		_seg(wood, pts[k], pts[k + 1], radii[k], radii[k + 1], 6)
	for k: int in range(1, pts.size() - 1):
		var off := Vector3(0.012 * float(k % 2 * 2 - 1), 0.0, 0.01)
		_put(wood, _sphere(radii[k] + 0.011, 6, 3), _xf(pts[k] + off, Vector3.ZERO, Vector3(1.0, 1.4, 1.0)))
	_seg(iron, Vector3(0, -0.86, 0), Vector3(0, -0.78, 0), 0.024, 0.042, 6, true)
	_seg(lea, Vector3(0, -0.12, 0), Vector3(0, 0.13, 0), 0.049, 0.049, 6, true)
	for y: float in [0.56, 0.80]:
		_put(brass, _cyl(0.05, 0.05, 0.03, 7), _xf(Vector3(0, y, 0)))
	_put(wood, _sphere(0.064, 7, 4), _xf(Vector3(0, 0.88, 0)))
	for k: int in 3:
		var a := TAU * float(k) / 3.0 + 0.4
		var d := Vector3(cos(a), 0.0, sin(a))
		var chain: Array[Vector3] = [Vector3(0, 0.9, 0) + d * 0.04, Vector3(0, 0.98, 0) + d * 0.1,
			Vector3(0, 1.1, 0) + d * 0.122, Vector3(0, 1.21, 0) + d * 0.092, Vector3(0, 1.27, 0) + d * 0.048]
		var pr: Array[float] = [0.024, 0.021, 0.017, 0.013, 0.008]
		for j: int in chain.size() - 1:
			_seg(wood, chain[j], chain[j + 1], pr[j], pr[j + 1], 5)
			_put(wood, _sphere(pr[j + 1] + 0.001, 5, 3), _xf(chain[j + 1]))
	_crystal(glow, Vector3(0, 1.10, 0), 0.075, 0.15, 0.11, 6, 15.0)
	return _commit([[wood, material(&"weapon_wood_dark")], [iron, material(&"weapon_iron")], [lea, material(&"weapon_leather")],
		[brass, material(&"weapon_brass")], [glow, material(&"weapon_crystal_glow")]])
