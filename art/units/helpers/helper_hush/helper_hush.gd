extends "res://art/units/helpers/helper_vey/helper_model.gd"
## Mother Hush, the Knife That Never Misses (Shadow T3 helper; t3-helpers.md 1 / 4.3 / 10; story-episode-1.md 19.V23).
## A tall, lean assassin read from the RTS camera by: the PORCELAIN-WHITE MOUTHLESS MASK inside a deep team-coloured
## hood (the brightest thing on her), two SICKLE KNIVES with glowing violet inner edges (the signature glow), and a
## long torn cloak that trails smoke. Hair (hair-redesign-plan rules 1-7, Shadow palette): ink-violet locks spill
## out of the hood over both shoulders onto the chest with big pale-lilac tips, a braid over the right shoulder
## ending in a silver ring and a lilac tassel, and a fringe swept across the mask's brow. Split leather coat open at
## the front (long legs, wrapped shins), a belt of throwing knives, a team tabard, a silver-spiked pauldron.
## Mask painted per expression (FaceKit, faces pass 2026-09-28; `set_expression(FaceKit.EXPRESSIONS)`): narrow dark eye
## slits with glowing violet irises, thin lilac brow strokes, lilac tear lines, a forehead sigil and small painted
## violet lips (the old mask had only a seam: lips were added so her face speaks too; hush_knives shouts).
## Abilities (play_cast): hush_blink (sinks into a crouch, then a double stab from behind), hush_smoke (a smoke
## pellet dashed at her feet), hush_knives (Night of Knives: she vanishes 1.5 s, then 6 strikes, reappears), hush_veil
## (passive tell) + set_status(&"veiled") thins the smoke. Helper hooks: play_arrival (rises out of her shadow, mask
## first, then the knives), play_fall (sinks into her shadow), play_revive, set_charge, play_gesture (+ draw_knives).
## 0 lights.

const HP := preload("res://art/units/helpers/helper_vey/helper_paint.gd")
const DIR := "res://art/units/helpers/helper_hush/"
const FACE_C := Vector3(0.0, 1.77, 0.085)
const FACE_R := 0.175
const FACE_SCL := Vector3(1.0, 1.22, 0.9)
const SHOULDER_L := Vector3(-0.36, 1.47, 0.0)
const SHOULDER_R := Vector3(0.36, 1.47, 0.0)
const HAND_L := Vector3(-0.46, 1.00, 0.16)
const HAND_R := Vector3(0.46, 1.00, 0.16)
const CAPE_TOP := Vector3(0.0, 1.56, -0.08)

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}

var _cape: MeshInstance3D
var _edge_l: GeometryInstance3D
var _smoke: GPUParticles3D
var _puff: GPUParticles3D
var _cape_kick: float = 0.0
var _cape_w: float = 999.0
var _vanish: float = 0.0          # 0-1 set by poses: 1 = gone (Night of Knives)
var _vanish_w: float = -1.0
var _smoke_w: float = -1.0
var _fidget_next: float = 8.0
var _fidget_alt: bool = false


static func mat(n: StringName) -> Material:
	if not _mats.has(n):
		_mats[n] = load(DIR + String(n) + ".tres")
	return _mats[n]


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leather := mat(&"hush_leather")
	var wrap := mat(&"hush_wrap")
	var cloth := palette(&"shadow_cloth")
	var dark := palette(&"shadow_cloth_dark")
	var silver := palette(&"shadow_silver")
	var bone := palette(&"shadow_bone")

	# ---- Legs: long, slim, leather; wrapped shins (pale wraps: the legs read under the open coat), pointed boots.
	for pair: Array in [[leg_l, -1.0], [leg_r, 1.0]]:
		var leg: Node3D = pair[0]
		var sx: float = pair[1]
		var x := 0.11 * sx
		add_part(leg, cyl(0.072, 0.088, 0.60, 8), leather, Vector3(x, 0.63, 0))
		add_part(leg, cyl(0.078, 0.092, 0.36, 8), wrap, Vector3(x, 0.20, 0))
		add_part(leg, torus(0.08, 0.10, 8), leather, Vector3(x, 0.30, 0), Vector3(8.0 * sx, 0, 10.0))
		add_part(leg, sphere(0.085, 8, 4), leather, Vector3(x, 0.045, 0.09), Vector3.ZERO, Vector3(0.8, 0.52, 1.75))
		add_part(leg, sphere(0.055, 6, 3), silver, Vector3(x, 0.44, 0.07), Vector3.ZERO, Vector3(1.0, 1.2, 0.6))

	# ---- Hips: split coat (back + sides only, long torn panels), belt of throwing knives, team tabard.
	for k: int in 7:
		var a := (100.0 + 26.7 * float(k)) * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var h := 0.80 if k % 2 == 0 else 0.64
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -10.0 * DEG)
		add_part(hips, prism(Vector3(0.22, h, 0.035)), dark if k % 3 != 1 else leather,
			out * 0.29 + Vector3(0, 1.0 - h * 0.5, 0), b.get_euler() / DEG)
	add_part(hips, cyl(0.24, 0.28, 0.16, 8), leather, Vector3(0, 0.92, 0))
	add_part(hips, torus(0.22, 0.28, 10), silver, Vector3(0, 0.99, 0))
	add_part(hips, box(Vector3(0.08, 0.08, 0.04)), silver, Vector3(0, 0.99, 0.25), Vector3(0, 0, 45))
	add_part(hips, box(Vector3(0.15, 0.50, 0.03)), cloth, Vector3(0, 0.72, 0.27), Vector3(-9, 0, 0))
	add_part(hips, prism(Vector3(0.15, 0.10, 0.03)), cloth, Vector3(0, 0.43, 0.315), Vector3(-9, 0, 180))
	for k: int in 5:
		var a := (-70.0 + 13.0 * float(k)) * DEG
		var out := Vector3(sin(a), 0, cos(a))
		add_part(hips, prism(Vector3(0.035, 0.17, 0.012)), silver, out * 0.275 + Vector3(0, 0.90, 0),
			Vector3(0, a / DEG, 180))
		add_part(hips, sphere(0.02, 6, 3), bone, out * 0.28 + Vector3(0, 1.0, 0))

	# ---- Chest: slim leather torso, pale wrap sash across it, silver gorget, right pauldron with spikes, cloak.
	add_part(chest, cyl(0.27, 0.22, 0.56, 10), leather, Vector3(0, 1.26, 0))
	# pale bodice panel: the dark hair locks lie on it (hair value contrast, hair-redesign-plan rule 4)
	add_part(chest, sphere(0.24, 10, 5), wrap, Vector3(0, 1.31, 0.13), Vector3.ZERO, Vector3(0.86, 1.1, 0.6))
	for k: int in 4:
		add_part(chest, sphere(0.018, 6, 3), silver, Vector3(0, 1.16 + 0.075 * float(k), 0.272))
	add_part(chest, box(Vector3(0.08, 0.66, 0.03)), leather, Vector3(-0.02, 1.27, 0.27), Vector3(-6, 0, -32))
	add_part(chest, torus(0.12, 0.20, 10), silver, Vector3(0, 1.55, 0.0))
	add_part(chest, sphere(0.16, 10, 5), silver, Vector3(0.36, 1.53, 0.0), Vector3(0, 0, -20), Vector3(1.2, 0.6, 1.1))
	add_part(chest, sphere(0.15, 10, 5), leather, Vector3(0.40, 1.45, 0.0), Vector3(0, 0, -30), Vector3(1.05, 0.5, 1.0))
	for k: int in 3:
		var d := Vector3(0.45 + 0.2 * float(k), 1.0, -0.3 + 0.3 * float(k)).normalized()
		_segment(chest, cyl(0.0, 0.035, 0.16 - 0.03 * float(k), 5), bone, Vector3(0.34 + 0.05 * float(k), 1.58, -0.06 + 0.06 * float(k)), d, 0.16 - 0.03 * float(k))
	add_part(chest, sphere(0.15, 8, 4), dark, Vector3(-0.35, 1.51, -0.02), Vector3(0, 0, 16), Vector3(1.15, 0.7, 1.15))
	_cape = add_part(chest, _cape_mesh(), null, CAPE_TOP, Vector3(5, 0, 0), Vector3.ONE, true, "Cape")

	# ---- Head: the deep hood (team lip), the porcelain mask (painted), the hair spilling out of the hood.
	add_part(head, cyl(0.075, 0.09, 0.14, 8), leather, Vector3(0, 1.60, 0.0))
	add_part(head, sphere(FACE_R, 12, 6), mat(&"hush_mask"), FACE_C, Vector3.ZERO, FACE_SCL)
	add_part(head, sphere(0.25, 10, 5), dark, Vector3(0, 1.82, -0.07), Vector3.ZERO, Vector3(1.06, 1.12, 1.12))
	add_part(head, torus(0.19, 0.25, 12), cloth, Vector3(0, 1.81, 0.07), Vector3(74, 0, 0), Vector3(1.0, 1.0, 1.28))
	add_part(head, cyl(0.0, 0.13, 0.40, 6), dark, Vector3(0.0, 1.86, -0.30), Vector3(-62, 0, 0))
	add_part(head, sphere(0.17, 8, 4), palette(&"unit_eye_dark"), Vector3(0, 1.80, -0.04), Vector3.ZERO, Vector3(1.05, 1.2, 0.8))
	add_part(head, _hair_mesh(), null, Vector3.ZERO)
	add_part(head, torus(0.022, 0.045, 8), silver, Vector3(0.215, 1.08, 0.215), Vector3(-10, 0, 8))
	_face = FaceKit.attach(self, head, "helper_hush", _face_style())
	_face.set_expression(_expr)

	# ---- Arms: slim leather sleeves, pale forearm wraps, dark gloves; a sickle knife in each hand.
	for pair: Array in [[arm_l, SHOULDER_L, HAND_L], [arm_r, SHOULDER_R, HAND_R]]:
		var arm: Node3D = pair[0]
		var sh: Vector3 = pair[1]
		var hd: Vector3 = pair[2]
		var dd := hd - sh
		var e := Basis(Quaternion(Vector3.DOWN, dd.normalized())).get_euler() / DEG
		add_part(arm, capsule(0.08, dd.length() + 0.08), leather, sh + dd * 0.5, e)
		add_part(arm, cyl(0.075, 0.09, 0.24, 8), wrap, sh + dd * 0.76, e)
		add_part(arm, sphere(0.08, 8, 4), leather, hd + dd.normalized() * 0.02)
		add_part(arm, _knife_mesh(hd), null, Vector3.ZERO)
	_glow_main = add_part(arm_r, _edge_mesh(&"edge_r", HAND_R), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "EdgeR")
	_glow_main.set_meta(&"own_glow", true)
	_edge_l = add_part(arm_l, _edge_mesh(&"edge_l", HAND_L), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "EdgeL")
	_edge_l.set_meta(&"own_glow", true)

	# ---- Smoke: a thin trail from the cloak hem (looping), a pellet burst (Smoke Cloak / vanish), a death wisp.
	_smoke = HP.motes("hush_smoke", 7, 1.6, 0.30, 0.35, 0.34, false, Color(0.30, 0.22, 0.38, 0.55),
		Color(0.22, 0.16, 0.30, 0.0), Vector3(0, 0.25, 0), true)
	_smoke.name = "SmokeTrail"
	_smoke.position = Vector3(0, 0.25, -0.35)
	add_child(_smoke)
	_puff = HP.motes("hush_puff", 14, 1.0, 0.45, 1.4, 0.55, true, Color(0.34, 0.26, 0.44, 0.7),
		Color(0.2, 0.15, 0.28, 0.0), Vector3(0, 0.3, 0), true)
	_puff.name = "SmokePuff"
	_puff.position = Vector3(0, 0.35, 0)
	$Fx.add_child(_puff)
	var wisp := HP.motes("hush_death", 14, 1.1, 0.4, 1.0, 0.45, true, Color(0.36, 0.26, 0.48, 0.7),
		Color(0.2, 0.14, 0.28, 0.0), Vector3(0, 0.6, 0), true)
	wisp.name = "DeathWisp"
	wisp.set_meta(&"death_fx", true)
	wisp.position = Vector3(0, 0.6, 0)
	$Fx.add_child(wisp)
	ensure_shadow_blob(0.55, Color(0.06, 0.03, 0.08, 0.55))


func _segment(pivot: Node3D, mesh: Mesh, m: Material, base: Vector3, dir: Vector3, len_m: float) -> void:
	add_part(pivot, mesh, m, base + dir * (len_m * 0.5), Basis(Quaternion(Vector3.UP, dir)).get_euler() / DEG)


# ================================================================ cached meshes (once per type)

## The sickle's centre line (model space) for a hand: the blade rises up-forward from the fist and curls down.
static func _sickle_pts(hand: Vector3) -> PackedVector3Array:
	return PackedVector3Array([hand + Vector3(0, 0.02, 0.11), hand + Vector3(0, 0.15, 0.19), hand + Vector3(0, 0.22, 0.33),
		hand + Vector3(0, 0.18, 0.47), hand + Vector3(0, 0.07, 0.55), hand + Vector3(0, -0.06, 0.53)])


## Knife (merged into the arm): dark sickle blade, silver collar, leather handle through the fist, silver pommel.
static func _knife_mesh(hand: Vector3) -> ArrayMesh:
	var key := StringName("knife_%s" % signf(hand.x))
	if _meshes.has(key):
		return _meshes[key]
	var st := HP.begin()
	HP.sweep(st, _sickle_pts(hand), PackedVector2Array([Vector2(0.022, 0.009), Vector2(0.036, 0.011),
		Vector2(0.042, 0.011), Vector2(0.036, 0.010), Vector2(0.024, 0.008), Vector2(0.003, 0.003)]), Vector3.UP)
	st.generate_normals()
	st.set_material(mat(&"hush_blade"))
	var am := st.commit()
	var st2 := SurfaceTool.new()
	st2.append_from(cyl(0.024, 0.024, 0.22, 6), 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hand + Vector3(0, 0, 0.0)))
	st2.set_material(mat(&"hush_leather"))
	st2.commit(am)
	var st3 := SurfaceTool.new()
	st3.append_from(torus(0.03, 0.05, 8), 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hand + Vector3(0, 0, -0.105)))
	st3.append_from(torus(0.02, 0.042, 8), 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), hand + Vector3(0, 0.01, 0.10)))
	st3.set_material(palette(&"shadow_silver"))
	st3.commit(am)
	_meshes[key] = am
	return am


## The glowing violet inner edge of a sickle (keep_separate, own_glow).
static func _edge_mesh(key: StringName, hand: Vector3) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var pts := _sickle_pts(hand)
	var c := hand + Vector3(0, 0.06, 0.33)
	var inner := PackedVector3Array()
	var half := PackedVector2Array()
	var w := [0.02, 0.034, 0.040, 0.034, 0.022, 0.003]
	for i: int in range(1, pts.size()):
		var p := pts[i]
		inner.append(p + (c - p).normalized() * float(w[i]) * 0.75)
		half.append(Vector2(0.016, 0.016) * (1.0 if i < pts.size() - 1 else 0.3))
	var st := HP.begin()
	HP.sweep(st, inner, half, Vector3.UP)
	st.generate_normals()
	# the soul-gem set on the knife collar, over the fist (the glow point that survives 40 m)
	st.append_from(sphere(0.05, 8, 4), 0, Transform3D(Basis.IDENTITY, hand + Vector3(0, 0.075, 0.07)))
	st.set_material(mat(&"hush_edge"))
	var am := st.commit()
	_meshes[key] = am
	return am


## Hair out of the hood: 2 long chest locks per side (ink violet, big lilac tips), a braid over the right shoulder
## (6 alternating lobes, silver ring, lilac tassel), a fringe swept across the mask's brow.
static func _hair_mesh() -> ArrayMesh:
	if _meshes.has(&"hair"):
		return _meshes[&"hair"]
	var body := HP.begin()
	var tip := HP.begin()
	for sx: float in [-1.0, 1.0]:
		if sx < 0.0:
			HP.lock(body, tip, [Vector3(0.12 * sx, 1.84, 0.12), Vector3(0.21 * sx, 1.66, 0.21), Vector3(0.18 * sx, 1.44, 0.29),
				Vector3(0.13 * sx, 1.18, 0.30)], Vector3(0.35 * sx, 0.2, 1).normalized(), 0.16, 0.05, 5, 0.62, 14.0 * sx)
		HP.lock(body, tip, [Vector3(0.15 * sx, 1.80, 0.05), Vector3(0.25 * sx, 1.63, 0.07), Vector3(0.27 * sx, 1.46, 0.12),
			Vector3(0.24 * sx, 1.30, 0.17)], Vector3(0.8 * sx, 0.2, 0.6).normalized(), 0.15, 0.05, 4, 0.66, 20.0 * sx)
		HP.lock(body, tip, [Vector3(0.10 * sx, 1.70, 0.14), Vector3(0.15 * sx, 1.60, 0.23), Vector3(0.13 * sx, 1.50, 0.285),
			Vector3(0.09 * sx, 1.42, 0.30)], Vector3(0.3 * sx, 0.1, 1).normalized(), 0.11, 0.045, 4, 0.7, -10.0 * sx)
	# braid over the right shoulder: lobes alternating either side of the path
	var path := [Vector3(0.15, 1.78, 0.04), Vector3(0.23, 1.56, 0.12), Vector3(0.235, 1.34, 0.20), Vector3(0.215, 1.10, 0.22)]
	for k: int in 6:
		var u0 := float(k) / 6.0
		var u1 := float(k + 1) / 6.0 + 0.03
		var a := HP.bez3(path, u0)
		var b := HP.bez3(path, minf(u1, 1.0))
		var s := 0.022 * (1.0 if k % 2 == 0 else -1.0)
		HP.lock(body, null, [a, a.lerp(b, 0.33) + Vector3(s, 0, 0.01), a.lerp(b, 0.66) + Vector3(s, 0, 0.01), b],
			Vector3(0.2, 0.1, 1).normalized(), 0.085 - 0.006 * float(k), 0.06, 4)
	HP.lock(tip, null, [Vector3(0.215, 1.08, 0.215), Vector3(0.22, 1.00, 0.225), Vector3(0.21, 0.93, 0.22), Vector3(0.20, 0.86, 0.21)],
		Vector3(0.2, 0.1, 1).normalized(), 0.07, 0.04, 4)
	# two locks framing the mask, from under the hood lip down beside the cheeks
	for sx: float in [-1.0, 1.0]:
		HP.lock(body, tip, [Vector3(0.12 * sx, 1.93, 0.13), Vector3(0.175 * sx, 1.84, 0.185), Vector3(0.18 * sx, 1.72, 0.185),
			Vector3(0.15 * sx, 1.62, 0.17)], Vector3(0.6 * sx, 0.1, 1).normalized(), 0.085, 0.04, 4, 0.72, 8.0 * sx)
	var mesh := HP.finish(body, mat(&"hush_hair"), tip, mat(&"hush_hair_tip"))
	_meshes[&"hair"] = mesh
	return mesh


## Long torn cloak (team shadow_cloth_dark, shadow_cloth band, silver crescent-eye sigil); deep tattered hem.
static func _cape_mesh() -> ArrayMesh:
	if _meshes.has(&"cape"):
		return _meshes[&"cape"]
	var cols := 12
	var rows := 10
	var h := 1.42
	var arc := 70.0 * DEG
	var body := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var band := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var grid: Array[Vector3] = []
	var gn: Array[Vector3] = []
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		var r := 0.26 + 0.18 * smoothstep(0.0, 0.22, v) + 0.10 * v
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var a := lerpf(-arc, arc, u)
			var torn := 1.0 - 0.26 * absf(sin(3.5 * PI * u + 0.3)) * smoothstep(0.45, 1.0, v)
			grid.append(Vector3(sin(a) * r, -h * v * torn, -cos(a) * r))
			gn.append(Vector3(sin(a), 0.3 - 0.25 * v, -cos(a)).normalized())
	for j: int in rows:
		var target: Array = band if j == 1 else body
		for i: int in cols:
			var q := j * (cols + 1) + i
			_quad(target, grid, gn, [q, q + 1, q + cols + 2, q + cols + 1])
	var glyph := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var cn := Vector3(0, 0.1, -1).normalized()
	# a closed eye: an almond outline (upper + lower lid bands) with three lashes below
	var eye := HP.almond(Vector2(0.0, 0.30), 0.13, 0.05, 0.035, 0.0)
	var cc := _cape_point(Vector2(0.0, 0.30), h)
	for k: int in eye.size():
		var p0 := eye[k]
		var p1 := eye[(k + 1) % eye.size()]
		var i0 := p0.lerp(Vector2(0.0, 0.30), 0.35)
		var i1 := p1.lerp(Vector2(0.0, 0.30), 0.35)
		_tri(glyph, _cape_point(p0, h), _cape_point(p1, h), _cape_point(i1, h), cn)
		_tri(glyph, _cape_point(p0, h), _cape_point(i1, h), _cape_point(i0, h), cn)
	_tri(glyph, cc + Vector3(-0.02, 0.02, 0), cc + Vector3(0.02, 0.02, 0), cc + Vector3(0, -0.02, 0), cn)
	for k: int in 3:
		var x := (float(k) - 1.0) * 0.06
		_tri(glyph, _cape_point(Vector2(x - 0.012, 0.345), h), _cape_point(Vector2(x + 0.012, 0.345), h),
			_cape_point(Vector2(x * 1.4, 0.41), h), cn)
	var am := ArrayMesh.new()
	for sf: Array in [[body, &"shadow_cloth_dark"], [band, &"shadow_cloth"], [glyph, &"shadow_silver"]]:
		var dd: Array = sf[0]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dd[0]
		arrays[Mesh.ARRAY_NORMAL] = dd[1]
		arrays[Mesh.ARRAY_INDEX] = dd[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, palette(sf[1]))
	_meshes[&"cape"] = am
	return am


static func _cape_point(sv: Vector2, h: float) -> Vector3:
	var v := sv.y
	var r := 0.26 + 0.18 * smoothstep(0.0, 0.22, v) + 0.10 * v + 0.015
	var a := sv.x / r
	return Vector3(sin(a) * r, -h * v, -cos(a) * r)


static func _quad(dd: Array, grid: Array[Vector3], gn: Array[Vector3], q: Array) -> void:
	var ids := PackedInt32Array()
	for k: int in 4:
		var g: int = q[k]
		if not dd[3].has(g):
			dd[3][g] = (dd[0] as PackedVector3Array).size()
			dd[0].append(grid[g])
			dd[1].append(gn[g])
			dd[0].append(grid[g])
			dd[1].append(-gn[g])
		ids.append(dd[3][g])
	dd[2].append_array(PackedInt32Array([ids[0], ids[3], ids[1], ids[1], ids[3], ids[2]]))
	dd[2].append_array(PackedInt32Array([ids[0] + 1, ids[1] + 1, ids[3] + 1, ids[1] + 1, ids[2] + 1, ids[3] + 1]))


static func _tri(dd: Array, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var base: int = (dd[0] as PackedVector3Array).size()
	for p: Vector3 in [a, b, c]:
		dd[0].append(p)
		dd[1].append(n)
	for p: Vector3 in [a, b, c]:
		dd[0].append(p)
		dd[1].append(-n)
	dd[2].append_array(PackedInt32Array([base, base + 2, base + 1, base + 3, base + 4, base + 5]))


# ================================================================ mask / expressions

func _shout_ids() -> Array[StringName]:
	return [&"hush_knives"]


## The painted porcelain mask (FaceKit style on the oval mask sphere): dark slit eyes with glowing violet irises, lilac
## brow strokes, small violet painted lips, no blush; tear lines down both cheeks and the forehead sigil (extra).
static func _face_style() -> Dictionary:
	if _meshes.has("_face_style"):
		return _meshes["_face_style"]
	var lilac := Color(0.74, 0.56, 0.95)
	var violet := Color(0.42, 0.20, 0.58)
	var st := FaceKit.style_from({"center": FACE_C, "radius": FACE_R, "head_mesh": sphere(FACE_R, 12, 6),
		"head_scale": FACE_SCL, "preset": &"hollow", "skin": Color(0.95, 0.94, 0.97), "hair": lilac,
		"eyes": Color(0.80, 0.42, 1.0), "ears": &"none",
		"eye": {"c": Vector2(0.062, 0.032), "hw": 0.040, "top": 0.013, "bot": 0.009, "tilt": 0.008, "ir": 0.0095, "lash": 1.3,
			"flick": 0.012},
		"brow": {"inner": Vector2(0.024, 0.062), "mid": Vector2(0.060, 0.074), "outer": Vector2(0.098, 0.066),
			"w": Vector3(0.0022, 0.0026, 0.0010)},
		"mouth": {"c": Vector2(0.0, -0.076), "hw": 0.026, "lip": 0.0030},
		"palette": {"sclera": Color(0.10, 0.06, 0.14), "iris_glow": 0.7, "pupil": Color(0.20, 0.04, 0.30), "lash": Color(0.08, 0.05, 0.10),
			"brow": lilac, "lip": Color(0.62, 0.44, 0.74), "lip_line": Color(0.32, 0.12, 0.42), "mouth_in": Color(0.14, 0.04, 0.20),
			"highlight": Color(0.92, 0.84, 1.0)},
		"x": {&"neutral": {"mouth": {"curve": 0.25, "w": 0.9}}}})
	var cv: Dictionary = st["canvas"]
	st["extra"] = func(acc: Dictionary, _id: StringName) -> void:
		var eye := Vector2(0.062, 0.032)
		for sx: float in [1.0, -1.0]:
			# tear line: from under the eye down the cheek, a drop at the end
			FaceKit.strip(acc, cv, FaceKit.mirror(FaceKit.bez(eye + Vector2(0.004, -0.016), eye + Vector2(0.010, -0.05), eye + Vector2(0.002, -0.088)), sx), Vector3(0.0018, 0.0026, 0.0010), lilac, 0.003)
			FaceKit.fill(acc, cv, FaceKit.mirror(FaceKit.ellipse(eye + Vector2(0.002, -0.096), Vector2(0.006, 0.009), 0.0, 8), sx), lilac, 0.003)
		# forehead sigil: a small diamond over a crescent
		FaceKit.fill(acc, cv, PackedVector2Array([Vector2(0.0, 0.118), Vector2(0.012, 0.098), Vector2(0.0, 0.078), Vector2(-0.012, 0.098)]), violet, 0.003)
		FaceKit.strip(acc, cv, FaceKit.bez(Vector2(-0.03, 0.084), Vector2(0.0, 0.066), Vector2(0.03, 0.084)), Vector3(0.0012, 0.003, 0.0012), violet, 0.003)
	_meshes["_face_style"] = st
	return st


# ================================================================ abilities (t3-helpers.md 4.3) + helper poses

func _pose_ability(spell: StringName, t: float) -> float:
	match spell:
		&"hush_blink":
			# 0.5 s: she folds into a crouch, cloak wrapped (the violet ring is on the target); then she is behind it:
			# a double stab down into its back.
			var c := _k3(t, 0.0, 0.25, 0.45, 0.52, 1.0, 0.0)
			var s := _k3(t, 0.50, 0.58, 0.72, 0.95, 1.0, 1.0)
			pos(P_ROOT, Vector3(0, -0.22 * c + 0.06 * s, 0.25 * s))
			rot(P_CHEST, Vector3((25.0 * c + 20.0 * s) * DEG, 0, 0))
			rot(P_ARM_L, Vector3((30.0 * c - 115.0 * s) * DEG, 0, 22.0 * DEG * c))
			rot(P_ARM_R, Vector3((30.0 * c - 115.0 * s) * DEG, 0, -22.0 * DEG * c))
			rot(P_HEAD, Vector3(10.0 * DEG * c, 0, 0))
			rot(P_LEG_L, Vector3((-40.0 * c - 20.0 * s) * DEG, 0, 0))
			rot(P_LEG_R, Vector3((30.0 * c + 25.0 * s) * DEG, 0, 0))
			_vanish = maxf(_vanish, _k3(t, 0.38, 0.47, 0.50, 0.56, 1.0, 0.0))
			_cape_kick = 30.0 * s - 10.0 * c
			_boost = maxf(_boost, 2.5 * s + 1.0 * c)
			if t < 0.5:
				_puff_once(0)
			return 0.95
		&"hush_smoke":
			var k := _k3(t, 0.0, 0.12, 0.20, 0.70, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-70.0 * _k3(t, 0.0, 0.08, 0.08, 0.14, 1.0, 0.0) + 25.0 * k) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, -0.12 * k, 0))
			rot(P_CHEST, Vector3(16.0 * DEG * k, 0, 0))
			rot(P_ARM_L, Vector3(-40.0 * DEG * k, 0, 30.0 * DEG * k))
			_cape_kick = 35.0 * k
			if t >= 0.12:
				_puff_once(1)
			return 0.7
		&"hush_knives":
			# Night of Knives: gone for 1.5 s, then six strikes 0.25 s apart (alternating knives), back at the last.
			if t < 1.5:
				var sink := _k3(t, 0.0, 0.25, 1.3, 1.5, 1.0, 0.0)
				pos(P_ROOT, Vector3(0, -0.2 * sink, 0))
				rot(P_ROOT, Vector3(0, TAU * smoothstep(0.0, 0.3, t), 0))
				_vanish = maxf(_vanish, _k3(t, 0.2, 0.3, 1.4, 1.5, 1.0, 0.0))
				if t < 0.3:
					_puff_once(2)
			else:
				var u := t - 1.5
				var i := mini(int(u / 0.25), 5)
				var lt := u - 0.25 * float(i)
				var w := _k3(lt, 0.0, 0.05, 0.10, 0.24, 1.0, 1.0)
				var arm := P_ARM_R if i % 2 == 0 else P_ARM_L
				rot(arm, Vector3((60.0 - 150.0 * w) * DEG, 0, 0))
				rot(P_CHEST, Vector3(10.0 * DEG, (24.0 if i % 2 == 0 else -24.0) * DEG * w, 0))
				pos(P_ROOT, Vector3(0, -0.06, 0.18 * w))
				_boost = maxf(_boost, 3.0 * w)
				_cape_kick = 25.0 * w
			return 3.0
		&"hush_veil":
			var k := _k3(t, 0.0, 0.2, 0.5, 0.8, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, 40.0 * DEG * k))
			rot(P_HEAD, Vector3(8.0 * DEG * k, 0, 10.0 * DEG * k))
			_cape_kick = -10.0 * k
			return 0.8
		&"arrival":
			# Out of her shadow: the mask surfaces first (the body rises through the ground), arms crossed, then the
			# knives flick out to the sides.
			var up := smoothstep(0.1, 1.0, t)
			pos(P_ROOT, Vector3(0, -1.9 * (1.0 - up), 0))
			var cross := 1.0 - smoothstep(1.0, 1.2, t)
			rot(P_ARM_L, Vector3(-60.0 * DEG * cross, 0, 40.0 * DEG * cross))
			rot(P_ARM_R, Vector3(-60.0 * DEG * cross, 0, -40.0 * DEG * cross))
			var fl := _k3(t, 1.1, 1.25, 1.35, 1.5, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-20.0 * DEG * fl, 0, -45.0 * DEG * fl))
			rot(P_ARM_R, Vector3(-20.0 * DEG * fl, 0, 45.0 * DEG * fl))
			rot(P_HEAD, Vector3(-10.0 * DEG * fl, 0, 12.0 * DEG * fl))
			_boost = maxf(_boost, 3.0 * fl)
			if t < 0.2:
				_puff_once(3)
			return ARRIVAL_LEN
		&"_fidget_spin":
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.3, 1.3, 1.6, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-55.0 + 25.0 * sin(t * 14.0)) * DEG * k, 0, 0))
			rot(P_HEAD, Vector3(6.0 * DEG * k, 0, 0))
			_boost = maxf(_boost, 0.8 * k)
			return 1.6
		&"_fidget_tilt":
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.5, 1.4, 1.9, 1.0, 1.0)
			rot(P_HEAD, Vector3(0, 12.0 * DEG * k, 24.0 * DEG * k))
			return 1.9
	if spell == &"gesture" and _gest == &"draw_knives":
		var k := _k3(t, 0.0, 0.2, 0.5, 0.8, 1.0, 1.0)
		var x := _k3(t, 0.0, 0.15, 0.15, 0.3, 1.0, 0.0)
		rot(P_ARM_L, Vector3(-50.0 * DEG * x - 15.0 * DEG * k, 0, 35.0 * DEG * x - 40.0 * DEG * k))
		rot(P_ARM_R, Vector3(-50.0 * DEG * x - 15.0 * DEG * k, 0, -35.0 * DEG * x + 40.0 * DEG * k))
		_boost = maxf(_boost, 2.0 * k)
		return 0.8
	return -1.0


var _puffed: int = -1
func _puff_once(id: int) -> void:
	if _puffed == id or _puff == null:
		return
	_puffed = id
	_puff.restart()


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start" or ev == &"attack_start":
		_puffed = -1


func _on_veil(on: bool) -> void:
	_smoke_w = -1.0
	if on and _action == &"":
		play_cast(&"hush_veil")


# ================================================================ per frame

func _helper_process(_dt: float) -> void:
	if _cape == null:
		return
	var full := _walk_w > 0.0 or _action != &"" or _dead or _hit_t < HIT_LEN or _level_t < LEVEL_LEN
	if full and not _dead:
		_body_extras()
	elif _dead:
		_death_extras()
	if _action == &"" and not _dead and _speed < 0.3 and _tier == 0 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		if _t >= _fidget_next:
			_fidget_alt = not _fidget_alt
			_fidget_next = _t + 7.0 + fmod(_phase_off * 5.3 + _t, 5.0)
			play_cast(&"_fidget_spin" if _fidget_alt else &"_fidget_tilt")
	elif _action != &"" or _speed >= 0.3:
		_fidget_next = maxf(_fidget_next, _t + 4.0)
	# left knife edge follows the right one (the base writes _glow_main)
	if _edge_l and _glow_main:
		_edge_l.set_instance_shader_parameter(&"glow_boost", _glow_main_w)
	# Night of Knives / blink: the whole body shrinks into the smoke (root scale, never 0)
	var v := clampf(_vanish, 0.0, 0.98)
	if absf(v - _vanish_w) > 0.005:
		_vanish_w = v
	if v > 0.0:
		_root_scale *= Vector3(1.0 - v, 1.0 - v, 1.0 - v)
	# smoke trail: thinner while veiled, gone when dead
	var sm := 0.0 if _dead else (0.35 if _veiled else 1.0)
	if absf(sm - _smoke_w) > 0.01:
		_smoke_w = sm
		_smoke.emitting = sm > 0.0
		_smoke.amount_ratio = maxf(sm, 0.01)
	var ck := 5.0 + (10.0 + 4.0 * absf(sin(TAU * _walk_p))) * _walk_w + _cape_kick
	if _dead:
		ck = 5.0 + 25.0 * clampf(_death_t / 0.6, 0.0, 1.0)
	ck += 2.0 * sin(_t * 1.7 + _phase_off) + 1.2 * sin(_t * 3.1)
	if absf(ck - _cape_w) > 0.05:
		_cape_w = ck
		_cape.rotation.x = ck * DEG
	_cape_kick = 0.0
	_vanish = 0.0


func _body_extras() -> void:
	if _walk_w > 0.0:
		# prowl: a low forward lean, head level and forward, the knives held out
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_CHEST, Vector3(12.0 * DEG * _walk_w, -5.0 * DEG * sw, 0))
		rot(P_HEAD, Vector3(-10.0 * DEG * _walk_w, 3.0 * DEG * sw, 0))
		rot(P_ARM_L, Vector3(-14.0 * DEG * _walk_w, 0, -10.0 * DEG * _walk_w))
		rot(P_ARM_R, Vector3(-14.0 * DEG * _walk_w, 0, 10.0 * DEG * _walk_w))
		pos(P_ROOT, Vector3(0, -0.05 * _walk_w, 0))
	if _action == &"attack":
		var a := _k3(_action_t, 0.0, 0.10, 0.22, 0.45, 1.0, 1.0)
		rot(P_HEAD, Vector3(-6.0 * DEG * a, 0, 0))
		pos(P_ROOT, Vector3(0, -0.06 * a, 0))
		_cape_kick = maxf(_cape_kick, 22.0 * a)
		_boost = maxf(_boost, 1.5 * _k3(_action_t, 0.06, 0.12, 0.22, 0.35, 1.0, 1.0))
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-12.0 * DEG * k, 0, 8.0 * DEG * k))
	if _level_t < LEVEL_LEN:
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		rot(P_ROOT, Vector3(0, TAU * smoothstep(0.0, 1.0, u), 0))
		_cape_kick = 30.0 * sin(PI * u)
		_boost = maxf(_boost, 3.0 * sin(PI * u))


## Fallen (sink): the knives drop to her sides, the head bows, she sinks into her shadow and smoke.
func _death_extras() -> void:
	var g := _k3(_death_t, 0.0, 0.2, 0.3, 0.6, 1.0, 1.0)
	rot(P_HEAD, Vector3(22.0 * DEG * g, 0, 0))
	rot(P_ARM_L, Vector3(20.0 * DEG * g, 0, -20.0 * DEG * g))
	rot(P_ARM_R, Vector3(20.0 * DEG * g, 0, 20.0 * DEG * g))


func _on_revive() -> void:
	super._on_revive()
	_cape_w = 999.0
	_vanish_w = -1.0
	_smoke_w = -1.0
	_puffed = -1
