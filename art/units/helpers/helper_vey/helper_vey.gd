extends "res://art/units/helpers/helper_vey/helper_model.gd"
## Torren "Old" Vey, the Storm-Sword (Fire T3 helper; t3-helpers.md 1 / 4.2 / 10; story-episode-1.md 2 / U6).
## An old swordmaster, broad and weathered, read from the RTS camera by: a long BLACK BLADE held point-down in front
## of him (white-gold storm runes along the fuller, a storm stone in the pommel: the signature glow), a silver-white
## TOP-KNOT and swept mane (what pitch 55 sees first) and a long FORKED BEARD over the chest, bronze-ringed, gold-tipped
## (the hair hook, hair-redesign-plan rules 1-7). A charcoal storm coat with long split tails, a steel pauldron on the
## sword arm and a team-coloured mantle + fur collar on the other shoulder, a torn cape with a gold lightning glyph,
## an empty scabbard on the left hip. Face (FaceKit, faces pass 2026-09-28): stern storm-gold eyes under heavy white
## brows, crow's feet and a scar through the left eye; `set_expression(FaceKit.EXPRESSIONS)` (neutral / smile / fierce
## / worried / shout); vey_stormcall and vey_chain shout.
## Abilities (play_cast): vey_lunge (crouch, dash-thrust), vey_chain (off hand up, a bolt leaps from it),
## vey_stormcall (sword overhead with both hands, driven into the ground, blade blazing), vey_storm_sworn (passive tell:
## the blade crackles; also every 3rd strike). Helper hooks: play_arrival (rises out of the flash, sword dragging
## sparks), play_fall, play_revive, set_charge, play_gesture (base + `raise_sword`). 0 lights.

const HP := preload("res://art/units/helpers/helper_vey/helper_paint.gd")
const DIR := "res://art/units/helpers/helper_vey/"
const FACE_C := Vector3(0.0, 1.74, 0.03)
const FACE_R := 0.20
const SHOULDER_L := Vector3(-0.42, 1.44, 0.0)
const SHOULDER_R := Vector3(0.42, 1.44, 0.0)
const HAND_L := Vector3(-0.52, 1.00, 0.12)
const HAND_R := Vector3(0.50, 0.98, 0.20)
const BLADE_DIR := Vector3(0.06, -0.72, 0.69)   # grip -> tip at rest (point-down in front, just above the ground)
const BLADE_LEN := 1.10
const CAPE_TOP := Vector3(0.0, 1.52, -0.08)
const EXPR_MATS: Array[StringName] = [&"hair", &"white", &"gold", &"dark", &"line", &"scar", &"mouth"]

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}

var _cape: MeshInstance3D
var _crackle: MeshInstance3D
var _hand_bolt: MeshInstance3D
var _sparks: GPUParticles3D
var _crackle_xf: Array[Transform3D] = []
var _crackle_req: float = 0.0     # crackle wanted this frame (0-1), set by poses
var _hand_req: float = 0.0
var _cape_kick: float = 0.0
var _cape_w: float = 999.0
var _crk_w: int = -1
var _hand_w: int = -1
var _strike_n: int = 0
var _tell_t: float = 99.0         # passive tell (every 3rd strike) timer
var _fidget_next: float = 9.0
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
	var coat := mat(&"vey_coat")
	var coat_l := mat(&"vey_coat_light")
	var steel := mat(&"vey_steel")
	var skin := mat(&"vey_skin")
	var cloth := palette(&"fire_cloth")
	var bronze := palette(&"fire_bronze")
	var leather := palette(&"fire_leather")
	var fur := palette(&"fire_fur")

	# ---- Legs: charcoal breeches, brown riding boots with a bronze cuff and a steel knee guard.
	for pair: Array in [[leg_l, -1.0], [leg_r, 1.0]]:
		var leg: Node3D = pair[0]
		var sx: float = pair[1]
		var x := 0.14 * sx
		add_part(leg, cyl(0.085, 0.10, 0.58, 8), coat, Vector3(x, 0.58, 0))
		add_part(leg, cyl(0.10, 0.115, 0.32, 8), leather, Vector3(x, 0.16, 0))
		add_part(leg, sphere(0.10, 8, 4), leather, Vector3(x, 0.055, 0.09), Vector3.ZERO, Vector3(0.95, 0.55, 1.5))
		add_part(leg, torus(0.085, 0.13, 10), bronze, Vector3(x, 0.32, 0))
		add_part(leg, sphere(0.075, 8, 4), steel, Vector3(x, 0.50, 0.08), Vector3.ZERO, Vector3(1.0, 1.1, 0.7))

	# ---- Hips: coat skirt with a front slit, team hem band, long split tails behind, belt, sash knot, scabbard.
	add_part(hips, cyl(0.31, 0.44, 0.58, 10), coat, Vector3(0, 0.68, 0), Vector3(0, 18, 0))
	add_part(hips, box(Vector3(0.06, 0.52, 0.02)), palette(&"unit_eye_dark"), Vector3(0, 0.66, 0.385), Vector3(-12, 0, 0))
	add_part(hips, torus(0.41, 0.47, 12), cloth, Vector3(0, 0.42, 0))
	for k: int in 4:
		var a := (140.0 + 26.7 * float(k)) * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var h := 0.62 if k % 3 == 0 else 0.72
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -14.0 * DEG)
		add_part(hips, prism(Vector3(0.24, h, 0.04)), coat if k % 2 == 0 else coat_l,
			out * 0.43 + Vector3(0, 0.80 - h * 0.5, 0), b.get_euler() / DEG)
	add_part(hips, torus(0.29, 0.36, 12), leather, Vector3(0, 0.96, 0))
	add_part(hips, box(Vector3(0.13, 0.11, 0.05)), bronze, Vector3(0, 0.96, 0.34))
	add_part(hips, sphere(0.075, 8, 4), cloth, Vector3(-0.30, 0.95, 0.15))
	for tg: Array in [[-0.26, 0.22, 0.34, 8.0], [-0.33, 0.12, 0.28, -10.0]]:
		add_part(hips, prism(Vector3(0.09, tg[2], 0.03)), cloth, Vector3(tg[0], 0.94 - float(tg[2]) * 0.5, tg[1]),
			Vector3(-6, 0, tg[3]))
	var sc_top := Vector3(-0.36, 0.93, 0.02)
	var sc_dir := Vector3(-0.18, -0.70, -0.69).normalized()
	_segment(hips, cyl(0.036, 0.05, 0.92, 6), leather, sc_top, sc_dir, 0.92)
	_segment(hips, cyl(0.0, 0.05, 0.10, 6), bronze, sc_top + sc_dir * 0.92, sc_dir, 0.10)
	add_part(hips, torus(0.04, 0.07, 8), bronze, sc_top + sc_dir * 0.04, Basis(Quaternion(Vector3.UP, sc_dir)).get_euler() / DEG)

	# ---- Chest: broad torso, leather cuirass, baldric, steel pauldron (sword arm), team mantle + fur collar, cape.
	add_part(chest, cyl(0.34, 0.27, 0.58, 10), coat, Vector3(0, 1.21, 0))
	add_part(chest, sphere(0.29, 10, 5), leather, Vector3(0, 1.22, 0.10), Vector3.ZERO, Vector3(1.05, 1.05, 0.62))
	add_part(chest, box(Vector3(0.07, 0.78, 0.03)), leather, Vector3(0.02, 1.24, 0.29), Vector3(-8, 0, 38))
	add_part(chest, box(Vector3(0.09, 0.09, 0.04)), bronze, Vector3(0.14, 1.38, 0.29), Vector3(-8, 0, 38))
	add_part(chest, sphere(0.18, 10, 5), steel, Vector3(0.42, 1.50, 0.0), Vector3(0, 0, -18), Vector3(1.25, 0.66, 1.15))
	add_part(chest, sphere(0.17, 10, 5), steel, Vector3(0.47, 1.41, 0.0), Vector3(0, 0, -30), Vector3(1.1, 0.5, 1.05))
	add_part(chest, torus(0.16, 0.21, 12), bronze, Vector3(0.43, 1.47, 0.0), Vector3(0, 0, -18), Vector3(1.15, 1.0, 1.08))
	add_part(chest, cyl(0.0, 0.05, 0.14, 5), bronze, Vector3(0.47, 1.60, -0.02), Vector3(0, 0, -30))
	# storm brand on the pauldron: a white-gold bolt (the high glow point, read over crowds)
	add_part(chest, _zigzag(&"brand", Vector3.ZERO, Vector3(0.25, -0.15, 0.95).normalized(), 0.25, 3, 0.045), null,
		Vector3(0.36, 1.64, -0.10))
	add_part(chest, sphere(0.19, 10, 5), cloth, Vector3(-0.39, 1.48, -0.01), Vector3(0, 0, 16), Vector3(1.12, 0.55, 1.12))
	add_part(chest, cyl(0.19, 0.24, 0.16, 8), cloth, Vector3(-0.40, 1.37, -0.01), Vector3(0, 0, 16))
	add_part(chest, torus(0.21, 0.25, 8), bronze, Vector3(-0.41, 1.30, -0.01), Vector3(0, 0, 16))
	add_part(chest, torus(0.15, 0.28, 12), fur, Vector3(0, 1.52, -0.03), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))
	_cape = add_part(chest, _cape_mesh(), null, CAPE_TOP, Vector3(4, 0, 0), Vector3.ONE, true, "Cape")

	# ---- Head: neck, weathered face (painted features swapped per expression), hooked nose, ears, the silver mane.
	add_part(head, cyl(0.09, 0.105, 0.14, 8), skin, Vector3(0, 1.56, 0.0))
	add_part(head, sphere(FACE_R, 12, 6), skin, FACE_C)
	add_part(head, sphere(0.042, 8, 4), skin, Vector3(0, 1.725, 0.215), Vector3(-20, 0, 0), Vector3(0.8, 1.35, 1.15))
	add_part(head, sphere(0.03, 6, 3), skin, Vector3(0, 1.69, 0.24))
	for sx: float in [-1.0, 1.0]:
		add_part(head, sphere(0.045, 6, 3), skin, Vector3(0.195 * sx, 1.73, 0.0), Vector3.ZERO, Vector3(0.5, 1.0, 0.8))
	add_part(head, sphere(0.21, 10, 5), mat(&"vey_hair"), Vector3(0, 1.80, -0.035), Vector3.ZERO, Vector3(1.03, 0.86, 1.08))
	add_part(head, _hair_mesh(), null, Vector3.ZERO)
	add_part(head, torus(0.035, 0.068, 8), bronze, Vector3(0, 1.965, -0.10), Vector3(-30, 0, 0))
	for sx: float in [-1.0, 1.0]:
		add_part(head, torus(0.026, 0.05, 8), bronze, Vector3(0.078 * sx, 1.29, 0.395), Vector3(-4, 0, 0))
	_face = FaceKit.attach(self, head, "helper_vey", _face_style())
	_face.set_expression(_expr)

	# ---- Arms: coat sleeves; sword arm with a steel bracer and a leather glove, off arm a leather bracer.
	_arm(arm_l, SHOULDER_L, HAND_L, coat, leather, skin, 0.095)
	_arm(arm_r, SHOULDER_R, HAND_R, coat, steel, leather, 0.10)

	# ---- The black blade (in the right hand, point down in front): leather grip, bronze swept guard, pommel ring.
	var d := BLADE_DIR.normalized()
	var b := Basis(Quaternion(Vector3.UP, d))
	_segment(arm_r, cyl(0.032, 0.034, 0.26, 6), leather, HAND_R - d * 0.15, d, 0.26)
	add_part(arm_r, cyl(0.032, 0.032, 0.40, 6), bronze, HAND_R + d * 0.10, (b * Basis(Vector3.BACK, PI * 0.5)).get_euler() / DEG)
	for sx: float in [-1.0, 1.0]:
		add_part(arm_r, sphere(0.04, 6, 3), bronze, HAND_R + d * 0.10 + b * Vector3(0.20 * sx, 0.035, 0))
	add_part(arm_r, cyl(0.05, 0.06, 0.07, 8), bronze, HAND_R + d * 0.14, b.get_euler() / DEG)
	add_part(arm_r, torus(0.03, 0.065, 8), bronze, HAND_R - d * 0.21, (b * Basis(Vector3.RIGHT, PI * 0.5)).get_euler() / DEG)
	add_part(arm_r, _blade_mesh(), null, Vector3.ZERO)
	_glow_main = add_part(arm_r, _runes_mesh(), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "StormRunes")
	_glow_main.set_meta(&"own_glow", true)
	_crackle = add_part(arm_r, _zigzag(&"crackle", Vector3.ZERO, d, BLADE_LEN * 0.92, 8, 0.05), null,
		HAND_R + d * 0.16, Vector3.ZERO, Vector3.ONE, true, "Crackle")
	_crackle.visible = false
	var loc := _crackle.transform
	_crackle_xf = [loc, Transform3D(Basis(d, PI) * loc.basis, loc.origin)]
	var arm_dir := (HAND_L - SHOULDER_L).normalized()
	_hand_bolt = add_part(arm_l, _zigzag(&"hand_bolt", Vector3.ZERO, arm_dir, 1.3, 7, 0.07), null,
		HAND_L + arm_dir * 0.06, Vector3.ZERO, Vector3.ONE, true, "HandBolt")
	_hand_bolt.visible = false
	_sparks = HP.motes("vey_sparks", 6, 0.55, 0.10, 0.9, 0.07, false, Color(1.0, 1.0, 0.8, 1.0),
		Color(1.0, 0.8, 0.3, 0.0), Vector3(0, -1.0, 0))
	_sparks.name = "StormSparks"
	_sparks.position = HAND_R + d * 0.75 - model_origin(arm_r)
	arm_r.add_child(_sparks)
	var burst := HP.motes("vey_death", 16, 0.9, 0.35, 2.2, 0.12, true, Color(1.0, 1.0, 0.85, 1.0),
		Color(1.0, 0.75, 0.25, 0.0), Vector3(0, -2.0, 0))
	burst.name = "DeathSparks"
	burst.set_meta(&"death_fx", true)
	burst.position = Vector3(0.3, 0.6, 0.5)
	$Fx.add_child(burst)
	ensure_shadow_blob(0.6)


## A cylinder / cone (axis +Y) standing on `base` along `dir`, total length `len_m`.
func _segment(pivot: Node3D, mesh: Mesh, m: Material, base: Vector3, dir: Vector3, len_m: float) -> void:
	add_part(pivot, mesh, m, base + dir * (len_m * 0.5), Basis(Quaternion(Vector3.UP, dir)).get_euler() / DEG)


## Sleeve capsule + bracer at the wrist + fist.
func _arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, sleeve: Material, bracer: Material, fist: Material, fr: float) -> void:
	var d := hand - shoulder
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() / DEG
	add_part(pivot, capsule(0.105, d.length() + 0.10), sleeve, shoulder + d * 0.5, e)
	add_part(pivot, cyl(0.10, 0.12, 0.24, 8), bracer, shoulder + d * 0.78, e)
	add_part(pivot, sphere(fr, 8, 4), fist, hand + d.normalized() * 0.03)


# ================================================================ cached meshes (once per type)

## The silver mane: 3 swept top locks into the top-knot, 2 side locks per side, the knot and its tail; the forked
## beard (2 long forks, chin lock, 2 side locks) and a drooping moustache. vey_hair body, gold tips (fire_sec_archer).
static func _hair_mesh() -> ArrayMesh:
	if _meshes.has(&"hair"):
		return _meshes[&"hair"]
	var body := HP.begin()
	var tip := HP.begin()
	var dark := HP.begin()
	for x: float in [-0.085, 0.0, 0.085]:
		HP.lock(body, null, [Vector3(x, 1.875, 0.155), Vector3(x * 1.25, 1.975, 0.07), Vector3(x * 0.8, 2.005, -0.05),
			Vector3(x * 0.25, 1.985, -0.11)], Vector3(x * 2.0, 1.0, 0.3).normalized(), 0.12, 0.05, 3)
	# top-knot plume: up out of the bronze ring, falling back
	HP.lock(body, tip, [Vector3(0, 2.00, -0.10), Vector3(0, 2.11, -0.10), Vector3(0, 2.10, -0.22), Vector3(0, 1.98, -0.29)],
		Vector3(0, 0.4, -1).normalized(), 0.11, 0.07, 4, 0.8)
	for sx: float in [-1.0, 1.0]:
		HP.lock(dark, null, [Vector3(0.165 * sx, 1.86, 0.10), Vector3(0.215 * sx, 1.82, 0.0), Vector3(0.215 * sx, 1.75, -0.11),
			Vector3(0.17 * sx, 1.66, -0.20)], Vector3(sx, 0.2, 0).normalized(), 0.11, 0.05, 3)
		# beard fork: from the jaw over the collar, down the chest; a small gold tip below the bronze ring
		HP.lock(body, tip, [Vector3(0.05 * sx, 1.62, 0.19), Vector3(0.09 * sx, 1.50, 0.39), Vector3(0.08 * sx, 1.34, 0.40),
			Vector3(0.05 * sx, 1.13, 0.37)], Vector3(0.25 * sx, 0.3, 1).normalized(), 0.15, 0.065, 5, 0.86, 12.0 * sx)
		# side beard: jaw -> chest, shorter, the dark underside
		HP.lock(dark, null, [Vector3(0.145 * sx, 1.67, 0.11), Vector3(0.19 * sx, 1.56, 0.27), Vector3(0.165 * sx, 1.46, 0.36),
			Vector3(0.13 * sx, 1.36, 0.38)], Vector3(0.6 * sx, 0.2, 1).normalized(), 0.12, 0.06, 4)
		# moustache: under the nose, out and drooping past the mouth (all white: gold points here read as fangs)
		HP.lock(body, null, [Vector3(0.015 * sx, 1.685, 0.228), Vector3(0.085 * sx, 1.683, 0.232), Vector3(0.14 * sx, 1.64, 0.205),
			Vector3(0.16 * sx, 1.56, 0.19)], Vector3(0.3 * sx, 0.2, 1).normalized(), 0.075, 0.04, 4, 1.0, -15.0 * sx)
	HP.lock(body, null, [Vector3(0, 1.605, 0.2), Vector3(0, 1.52, 0.38), Vector3(0, 1.41, 0.405), Vector3(0, 1.27, 0.39)],
		Vector3(0, 0.2, 1).normalized(), 0.12, 0.06, 4)
	var mesh := HP.finish(body, mat(&"vey_hair"), tip, palette(&"fire_sec_archer"))
	dark.generate_normals()
	dark.set_material(mat(&"vey_hair_dark"))
	dark.commit(mesh)
	_meshes[&"hair"] = mesh
	return mesh


## The black blade (arm-local = model space; merged into ArmR): a lens section, slight swell, a long point.
static func _blade_mesh() -> ArrayMesh:
	if _meshes.has(&"blade"):
		return _meshes[&"blade"]
	var d := BLADE_DIR.normalized()
	var st := HP.begin()
	var pts := PackedVector3Array()
	var half := PackedVector2Array()
	for i: int in 7:
		var u := float(i) / 6.0
		pts.append(HAND_R + d * (0.16 + BLADE_LEN * u))
		var w := 0.068 if u < 0.7 else lerpf(0.068, 0.004, (u - 0.7) / 0.3)
		half.append(Vector2(w, 0.016 if u < 0.95 else 0.004))
	HP.sweep(st, pts, half, Vector3.RIGHT)
	st.generate_normals()
	st.set_material(mat(&"vey_blade"))
	var mesh := st.commit()
	_meshes[&"blade"] = mesh
	return mesh


## Storm runes: the glowing fuller along the blade's upper face, 4 rune diamonds on it, the pommel storm stone.
static func _runes_mesh() -> ArrayMesh:
	if _meshes.has(&"runes"):
		return _meshes[&"runes"]
	var d := BLADE_DIR.normalized()
	var th := d.cross(Vector3.RIGHT).normalized()
	if th.y < 0.0:
		th = -th
	var st := HP.begin()
	var pts := PackedVector3Array()
	var half := PackedVector2Array()
	for i: int in 5:
		var u := float(i) / 4.0
		pts.append(HAND_R + d * (0.22 + 0.78 * u) + th * 0.015)
		half.append(Vector2(0.032 * (1.0 - 0.45 * u), 0.008))
	HP.sweep(st, pts, half, Vector3.RIGHT)
	for k: int in 4:
		var c := HAND_R + d * (0.30 + 0.2 * float(k)) + th * 0.02
		var dia := PackedVector3Array([c - d * 0.035, c, c + d * 0.035])
		HP.sweep(st, dia, PackedVector2Array([Vector2(0.004, 0.004), Vector2(0.045, 0.008), Vector2(0.004, 0.004)]), Vector3.RIGHT)
	st.generate_normals()
	st.append_from(sphere(0.058, 8, 4), 0, Transform3D(Basis.IDENTITY, HAND_R - d * 0.21))
	st.append_from(sphere(0.07, 8, 4), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.8, 1.0)), HAND_R + d * 0.10 + th * 0.05))
	st.set_material(mat(&"vey_storm"))
	var mesh := st.commit()
	_meshes[&"runes"] = mesh
	return mesh


## A jagged lightning zigzag (local: from the origin along `dir`), vey_storm; cached per key.
static func _zigzag(key: StringName, from: Vector3, dir: Vector3, length: float, n: int, amp: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var pts := PackedVector3Array()
	var half := PackedVector2Array()
	for i: int in n + 1:
		var u := float(i) / float(n)
		var off := Vector3.ZERO
		if i > 0 and i < n:
			var s := 1.0 if i % 2 == 0 else -1.0
			off = side * s * amp * (0.6 + 0.4 * sin(float(i) * 2.3)) + up * amp * 0.6 * sin(float(i) * 1.7)
		pts.append(from + dir * length * u + off)
		half.append(Vector2(0.016, 0.016) * (1.0 - 0.6 * u))
	var st := HP.begin()
	HP.sweep(st, pts, half, side)
	st.generate_normals()
	st.set_material(mat(&"vey_storm"))
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Torn storm cape (team fire_cloth_dark, fire_cloth band, gold lightning glyph); a cone section hanging from the
## shoulders (hinge CAPE_TOP), jagged hem. Double-sided, cached.
static func _cape_mesh() -> ArrayMesh:
	if _meshes.has(&"cape"):
		return _meshes[&"cape"]
	var cols := 10
	var rows := 9
	var h := 1.12
	var arc := 62.0 * DEG
	var body := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var band := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var grid: Array[Vector3] = []
	var gn: Array[Vector3] = []
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		var r := 0.30 + 0.22 * smoothstep(0.0, 0.25, v) + 0.06 * v
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var a := lerpf(-arc, arc, u)
			var torn := 1.0 - 0.17 * absf(sin(2.5 * PI * u + 0.4)) * smoothstep(0.55, 1.0, v)
			grid.append(Vector3(sin(a) * r, -h * v * torn, -cos(a) * r))
			gn.append(Vector3(sin(a), 0.3 - 0.25 * v, -cos(a)).normalized())
	for j: int in rows:
		var target: Array = band if j == 7 else body
		for i: int in cols:
			var q := j * (cols + 1) + i
			_quad(target, grid, gn, [q, q + 1, q + cols + 2, q + cols + 1])
	var glyph := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var cn := Vector3(0, 0.1, -1).normalized()
	var polys: Array = [
		[Vector2(0.03, 0.14), Vector2(0.12, 0.14), Vector2(0.03, 0.36), Vector2(-0.06, 0.36)],
		[Vector2(-0.06, 0.33), Vector2(0.10, 0.33), Vector2(0.10, 0.39), Vector2(-0.06, 0.39)],
		[Vector2(0.01, 0.39), Vector2(0.10, 0.39), Vector2(-0.07, 0.66)]]
	for poly: Array in polys:
		var p0 := _cape_point(poly[0], h)
		for k: int in range(1, poly.size() - 1):
			_tri(glyph, p0, _cape_point(poly[k], h), _cape_point(poly[k + 1], h), cn)
	var am := ArrayMesh.new()
	for sf: Array in [[body, &"fire_cloth_dark"], [band, &"fire_cloth"], [glyph, &"fire_sec_archer"]]:
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
	var r := 0.30 + 0.22 * smoothstep(0.0, 0.25, v) + 0.06 * v + 0.015
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


# ================================================================ face / expressions

## FaceKit face (faces pass 2026-09-28; was a HelperPaint face with 3 expressions): stern storm-gold irises with a
## faint glow under heavy white brows, crow's feet, the fold under the eye, two forehead lines, the scar from the brow
## through the left eye (-X) to the cheek, the mouth under the moustache (the mane / beard are the hair mesh). One Face
## node, every FaceKit expression + the bold far face.
func _shout_ids() -> Array[StringName]:
	return [&"vey_stormcall", &"vey_chain"]


static func _face_style() -> Dictionary:
	if _meshes.has("_face_style"):
		return _meshes["_face_style"]
	var skin := Color(0.82, 0.62, 0.48)
	var line := skin.darkened(0.36)
	var scar := Color(0.66, 0.36, 0.30)
	var white := Color(0.90, 0.90, 0.93)
	var st := FaceKit.style_from({"center": FACE_C, "radius": FACE_R, "head_mesh": sphere(FACE_R, 12, 6), "preset": &"stern",
		"skin": skin, "hair": white, "eyes": Color(0.95, 0.74, 0.20), "ears": &"none",
		"eye": {"c": Vector2(0.066, 0.022), "hw": 0.028, "top": 0.018, "bot": 0.012, "ir": 0.0105},
		"brow": {"inner": Vector2(0.026, 0.050), "mid": Vector2(0.068, 0.068), "outer": Vector2(0.114, 0.058),
			"w": Vector3(0.011, 0.013, 0.007)},
		"mouth": {"c": Vector2(0.0, -0.100), "hw": 0.036, "lip": 0.0028},
		"palette": {"iris_glow": 0.3, "brow": white, "lash": Color(0.22, 0.16, 0.12), "lip": Color(0.70, 0.44, 0.38),
			"lip_line": Color(0.34, 0.16, 0.10)}})
	var cv: Dictionary = st["canvas"]
	st["extra"] = func(acc: Dictionary, id: StringName) -> void:
		var cf := 1.4 if id == &"smile" else 1.0
		for sx: float in [1.0, -1.0]:
			for k: int in 2:
				var a := Vector2(0.098, 0.028 - 0.016 * float(k))
				FaceKit.strip(acc, cv, FaceKit.mirror(PackedVector2Array([a, a + Vector2(0.022, 0.006 - 0.012 * float(k)) * cf]), sx), Vector3(0.0014, 0.0014, 0.0008), line, 0.003)
			FaceKit.strip(acc, cv, FaceKit.mirror(FaceKit.bez(Vector2(0.046, 0.004), Vector2(0.066, -0.004), Vector2(0.090, 0.006)), sx), Vector3(0.0008, 0.0014, 0.0008), line, 0.003)
		for k: int in 2:
			var y := 0.100 + 0.022 * float(k)
			FaceKit.strip(acc, cv, FaceKit.bez(Vector2(-0.07, y), Vector2(0.0, y + (0.010 if id == &"smile" else 0.004)), Vector2(0.07, y)), Vector3(0.0012, 0.0020, 0.0012), line, 0.003)
		# the scar: brow -> cheek through the left eye (-X), over the eye
		FaceKit.strip(acc, cv, PackedVector2Array([Vector2(-0.050, 0.075), Vector2(-0.066, 0.030), Vector2(-0.080, -0.012), Vector2(-0.090, -0.050)]), Vector3(0.0024, 0.0042, 0.002), scar, 0.0062)
	_meshes["_face_style"] = st
	return st


# ================================================================ abilities (t3-helpers.md 4.2) + helper poses

func _pose_ability(spell: StringName, t: float) -> float:
	match spell:
		&"vey_lunge":
			# Crouch and cock the blade back, then a long dash-thrust (the tip leads), hold, recover.
			var c := _k3(t, 0.0, 0.14, 0.18, 0.26, 1.0, 0.0)
			var th := _k3(t, 0.16, 0.28, 0.48, 0.80, 1.0, 1.0)
			pos(P_ROOT, Vector3(0, -0.14 * c - 0.06 * th, -0.10 * c + 0.75 * th))
			rot(P_ROOT, Vector3(14.0 * DEG * th, 0, 0))
			rot(P_CHEST, Vector3((10.0 * c + 12.0 * th) * DEG, (25.0 * c - 10.0 * th) * DEG, 0))
			rot(P_ARM_R, Vector3((30.0 * c - 40.0 * th) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.08 * th, -0.10 * c + 0.28 * th))
			rot(P_ARM_L, Vector3((25.0 * c + 40.0 * th) * DEG, 0, -35.0 * DEG * th))
			rot(P_LEG_L, Vector3((-10.0 * c + 30.0 * th) * DEG, 0, 0))
			rot(P_LEG_R, Vector3((10.0 * c - 45.0 * th) * DEG, 0, 0))
			_crackle_req = maxf(_crackle_req, th)
			_boost = maxf(_boost, 2.5 * maxf(c, th))
			_cape_kick = 30.0 * th
			return 0.8
		&"vey_chain":
			# Off hand up and forward, fingers splayed: a bolt leaps from it; the blade held back, crackling.
			var k := _k3(t, 0.0, 0.18, 0.62, 0.90, 1.0, 1.0)
			var f := _k3(t, 0.20, 0.24, 0.62, 0.66, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-125.0 * DEG * k, 0, -12.0 * DEG * k))
			rot(P_ARM_R, Vector3(28.0 * DEG * k, 0, 10.0 * DEG * k))
			rot(P_CHEST, Vector3(-8.0 * DEG * k, 22.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(-12.0 * DEG * k, 8.0 * DEG * k, 0))
			pos(P_ROOT, Vector3(0, 0.03 * f, 0))
			_hand_req = f
			_crackle_req = maxf(_crackle_req, f * 0.7)
			_boost = maxf(_boost, 2.0 * k)
			_cape_kick = 14.0 * k
			return 0.9
		&"vey_stormcall":
			# Both hands lift the blade overhead (the sky answers), then drive it into the ground on one knee.
			var up := _k3(t, 0.0, 0.40, 0.95, 1.05, 1.0, 0.0)
			var dn := _k3(t, 0.95, 1.08, 1.45, 1.75, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-165.0 * up + 40.0 * dn) * DEG, 0, 8.0 * DEG * up))
			rot(P_ARM_L, Vector3((-150.0 * up - 30.0 * dn) * DEG, 0, 22.0 * DEG * up + 15.0 * DEG * dn))
			pos(P_ARM_L, Vector3(0.18 * up, 0.10 * up, 0))
			rot(P_HEAD, Vector3((-24.0 * up + 16.0 * dn) * DEG, 0, 0))
			rot(P_CHEST, Vector3((-10.0 * up + 22.0 * dn) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0.08 * up - 0.30 * dn, 0.10 * dn))
			rot(P_LEG_R, Vector3(-60.0 * DEG * dn, 0, 0))
			rot(P_LEG_L, Vector3(40.0 * DEG * dn, 0, 0))
			_crackle_req = maxf(_crackle_req, maxf(up * 0.8, dn))
			_boost = maxf(_boost, 3.5 * maxf(up, dn))
			_cape_kick = 20.0 * up + 30.0 * dn
			return 1.75
		&"vey_storm_sworn":
			var k := _k3(t, 0.0, 0.06, 0.25, 0.45, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-18.0 * DEG * k, 0, 0))
			_crackle_req = maxf(_crackle_req, k)
			_boost = maxf(_boost, 2.5 * k)
			return 0.45
		&"arrival":
			# Stands up out of the flash, sword dragging sparks (the blade stays low, then a flourish to the shoulder).
			var r := _pose_rise(t, ARRIVAL_LEN, 0.55)
			var fl := _k3(t, 0.9, 1.1, 1.3, 1.5, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-60.0 * DEG * fl, 0, 0))
			_crackle_req = maxf(_crackle_req, 1.0 - smoothstep(0.0, 0.9, t))
			_cape_kick = 25.0 * (1.0 - smoothstep(0.0, 0.8, t))
			return r
		&"revive":
			var r2 := _pose_rise(t, REVIVE_LEN, 0.45)
			_crackle_req = maxf(_crackle_req, 0.5 * (1.0 - smoothstep(0.0, 0.6, t)))
			return r2
		&"_fidget_beard":
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.45, 1.7, 2.1, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-62.0 * DEG * k, 0, 38.0 * DEG * k))
			pos(P_ARM_L, Vector3(0.14 * k, 0.12 * k, 0.10 * k))
			rot(P_HEAD, Vector3(-8.0 * DEG * k, 10.0 * DEG * k, 0))
			pos(P_ARM_L, Vector3(0, -0.04 * sin(t * 5.0) * k, 0))
			return 2.1
		&"_fidget_blade":
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.5, 1.5, 2.0, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-62.0 * DEG * k, 0, -18.0 * DEG * k))
			rot(P_HEAD, Vector3(10.0 * DEG * k, -14.0 * DEG * k, 0))
			rot(P_CHEST, Vector3(0, -10.0 * DEG * k, 0))
			_crackle_req = maxf(_crackle_req, _k3(t, 0.9, 1.0, 1.1, 1.2, 1.0, 1.0))
			return 2.0
	return -1.0


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_strike_n += 1
		if _strike_n % 3 == 0:
			_tell_t = 0.0   # Storm-Sworn: every 3rd strike chains (t3-helpers.md 4.2)


# ================================================================ per frame

func _helper_process(_dt: float) -> void:
	if _cape == null:
		return
	var full := _walk_w > 0.0 or _action != &"" or _dead or _hit_t < HIT_LEN or _level_t < LEVEL_LEN
	if full and not _dead:
		_body_extras()
	elif _dead:
		_death_extras()
	if _tell_t < 0.45:
		_tell_t += _dt
		_crackle_req = maxf(_crackle_req, 1.0)
		_boost = maxf(_boost, 2.0)
	# idle fidgets, close camera only
	if _action == &"" and not _dead and _speed < 0.3 and _tier == 0 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		if _t >= _fidget_next:
			_fidget_alt = not _fidget_alt
			_fidget_next = _t + 8.0 + fmod(_phase_off * 6.1 + _t, 5.0)
			play_cast(&"_fidget_beard" if _fidget_alt else &"_fidget_blade")
	elif _action != &"" or _speed >= 0.3:
		_fidget_next = maxf(_fidget_next, _t + 4.0)
	# ambient crackle: a flick along the blade every ~3 s (close camera), stronger with the charge
	var amb := fmod(_t * 0.37 + _phase_off, 1.0) < 0.035 + 0.05 * _charge
	var crk := -1
	if not _dead and (_crackle_req > 0.3 or (amb and _tier == 0) or _charge > 0.6):
		crk = int(_t * 14.0) % 2
	if crk != _crk_w:
		_crk_w = crk
		_crackle.visible = crk >= 0
		if crk >= 0:
			_crackle.transform = _crackle_xf[crk]
	var hb := -1
	if not _dead and _hand_req > 0.3:
		hb = int(_t * 18.0) % 2
	if hb != _hand_w:
		_hand_w = hb
		_hand_bolt.visible = hb >= 0
		if hb >= 0:
			_hand_bolt.scale = Vector3(1.0 if hb == 0 else -1.0, 1.0, 1.0)
	_boost = maxf(_boost, 0.6 * _crackle_req)
	# cape billows with the walk, kicked by the poses
	var ck := 4.0 + (8.0 + 3.0 * absf(sin(TAU * _walk_p))) * _walk_w + _cape_kick
	if _dead:
		ck = 4.0 - 18.0 * clampf(_death_t / 0.5, 0.0, 1.0)
	ck += 1.5 * sin(_t * 1.9 + _phase_off) + 1.0 * sin(_t * 3.3)
	if absf(ck - _cape_w) > 0.05:
		_cape_w = ck
		_cape.rotation.x = ck * DEG
	_crackle_req = 0.0
	_hand_req = 0.0
	_cape_kick = 0.0


## Offsets on top of the kit's walk / attack / hit / level-up poses.
func _body_extras() -> void:
	if _walk_w > 0.0:
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_CHEST, Vector3(6.0 * DEG * _walk_w, -4.0 * DEG * sw, 0))
		rot(P_HEAD, Vector3(-5.0 * DEG * _walk_w, 2.0 * DEG * sw, 0))
		rot(P_ARM_R, Vector3(-10.0 * DEG * _walk_w, 0, 0))
	if _action == &"attack":
		# sword_slash (kit): a bigger shoulder turn, the off hand thrown back, the cape kicks; a flare at the strike.
		var a := _k3(_action_t, 0.0, 0.07, 0.14, 0.5, 1.0, 1.0)
		rot(P_ARM_L, Vector3(24.0 * DEG * a, 0, -34.0 * DEG * a))
		rot(P_HEAD, Vector3(0, -10.0 * DEG * a, 0))
		_cape_kick = maxf(_cape_kick, 16.0 * a)
		_boost = maxf(_boost, 1.2 * _k3(_action_t, 0.08, 0.12, 0.2, 0.35, 1.0, 1.0))
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-10.0 * DEG * k, 0, -5.0 * DEG * k))
	if _level_t < LEVEL_LEN:
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		rot(P_ARM_R, Vector3(-100.0 * DEG * sin(PI * u), 0, 0))
		_crackle_req = 1.0
		_boost = maxf(_boost, 3.0 * sin(PI * u))


## Fallen: he drops to one knee and leans on the blade before the kit's fall.
func _death_extras() -> void:
	var g := _k3(_death_t, 0.0, 0.2, 0.3, 0.55, 1.0, 1.0)
	rot(P_HEAD, Vector3(18.0 * DEG * g, 0, 0))
	rot(P_ARM_L, Vector3(-40.0 * DEG * g, 0, 10.0 * DEG * g))


func _on_revive() -> void:
	super._on_revive()
	_cape_w = 999.0
	_crk_w = -1
	_hand_w = -1
	if _crackle:
		_crackle.visible = false
	if _hand_bolt:
		_hand_bolt.visible = false
