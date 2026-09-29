extends MountModel
## Dusk Steed (cavalry-mounts.md 6.1 / 10, task 13.V3): the Shadow mount (Gloam Rider 13.V7, Malrik riding 13.V11).
## A normal-size riding horse (withers 1.68 m, ears 2.4 m, 2.9 m nose to tail), gaunt and tall: long thin legs with
## bony knees and hocks, a deep narrow chest, tucked flanks, sharp withers and hip bones, a long arched neck and a bony
## wedge head with hollow cheeks. Black coat (dusk_hide) with a violet rim sheen. Violet eye glow: slanted glowing slits
## trailing a short glow wisp = the glow point at 40 m (flares on the charge / snort). Smoky mane, forelock, tail and
## fetlock feathers made of static flame-like cones (dusk_smoke, pale dusk_wisp tips, strong violet rim).
## Tattered team caparison (shadow_cloth) over the back with ragged layered skirts (cloth + cloth_dark), a silver
## diamond sigil on each flank; black leather saddle, silver stirrups, bridle, silver bit, breast collar with a medallion.
## Barding (set_barded): tarnished silver (shadow_silver) chanfron with an iron crest ridge, a swept spike and a violet
## gem, cheek plates, a crinet of dark iron neck lames edged in silver, a silver peytral over the chest; iron rims
## and rivets. Vertices ~5.8k plain / ~7.3k barded.
## Kept apart from the Nightmare Knight's horse (13.V15): that one is HUGE with burning hooves; the Dusk Steed is a
## riding-size horse with plain iron-shod hooves and no fire or smoke particles.
## Motion: long-legged 4-beat walk, gallop from 3.8 m/s, a "dusk rear" fidget (half rear, pawing, head toss, snort
## flare), generic charge (neck stretched low, lunge, toss) and hit; death: stumbles, rolls onto its side, a violet
## dissolve flare that fades to a faint sheen (it stays lying there).
## No Neck pivot: the neck is part of the Head pivot (at the neck root), so the whole neck nods.
## Budget (section 10 mount): 10 authored meshes incl. the blob (7 sculpts + 2 barding sculpts + blob), 8 draw
## instances (Body, Head, 4 legs, Tail, blob), 0 lights, 0 particle systems.

const OWN := "res://art/units/mounts/dusk_steed/materials/"
const KIT := "res://art/units/kit/materials/"
const BLOB_TINT := Color(0.09, 0.04, 0.15, 0.5)
const DISSOLVE := Vector3(0.48, 0.16, 1.0)

## Body centre (= the Mount pivot) and the barrel of revolution along z: [z offset, lateral radius], vertical x SY.
const BC := Vector3(0, 1.22, -0.06)
const SY := 1.18
const BARREL_Z: Array[float] = [-0.80, -0.74, -0.60, -0.40, -0.15, 0.10, 0.35, 0.55, 0.68, 0.76]
const BARREL_R: Array[float] = [0.00, 0.17, 0.25, 0.265, 0.25, 0.275, 0.30, 0.28, 0.20, 0.00]
const CHEST_C := Vector3(0, 1.30, 0.44)
const CHEST_R := Vector3(0.265, 0.36, 0.28)
const CROUP_C := Vector3(0, 1.31, -0.56)
const CROUP_R := Vector3(0.28, 0.33, 0.30)
## Caparison: the back cloth is an elliptic shell around BC + CAPA_UP, radii CAPA_RX / CAPA_RY.
const CAPA_UP := 0.03
const CAPA_RX := 0.305
const CAPA_RY := 0.40
## Neck (Head pivot): tube points / radii from the chest to the poll.
const NECK_P: Array[Vector3] = [Vector3(0, 1.30, 0.50), Vector3(0, 1.56, 0.70), Vector3(0, 1.82, 0.88),
	Vector3(0, 2.04, 1.00), Vector3(0, 2.17, 1.05)]
const NECK_R: Array[float] = [0.30, 0.25, 0.19, 0.145, 0.115]
const NECK_FLAT := 0.62
## Skull: from SK_B (poll) to SK_F (muzzle); lathe profile [s along the axis, radius], lateral squash SK_X.
const SK_B := Vector3(0, 2.16, 1.04)
const SK_F := Vector3(0, 1.70, 1.48)
const SK_S: Array[float] = [-0.03, 0.0, 0.07, 0.18, 0.32, 0.46, 0.56, 0.62, 0.66]
const SK_R: Array[float] = [0.0, 0.10, 0.135, 0.13, 0.10, 0.083, 0.09, 0.075, 0.0]
const SK_X := 0.78

var _dissolve_v: float = -1.0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "dusk_steed", face_spec())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	# Barding: tarnished silver merged into barded variants of Body (peytral) and Head (chanfron + crinet).
	add_barding_sculpt(body, _body_barding)
	add_barding_sculpt(head, _head_barding)
	ensure_shadow_blob(0.5, BLOB_TINT)
	_shadow.scale = Vector3(1.45, 1.0, 3.3)
	_shadow.position = Vector3(0, 0.02, 0.12)


## Own materials (dusk_*) or the Shadow kit palette.
static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("dusk") else KIT) + name + ".tres")


## Unit cone (tip +Y) as a flame / smoke tongue: wide end at `base`, pointing along `dir`, radius r, length h,
## flattened to `flat` across `side` (so it reads broad from the side).
static func _tongue(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, side: Vector3, r: float, h: float,
		flat: float = 0.5) -> void:
	var f := frame(base, dir, side)
	sculpt_add(s, cyl(0.0, 1.0, 1.0, 5), Transform3D(Basis(f.basis.x * r, f.basis.y * h, f.basis.z * r * flat),
		base + f.basis.y * h * 0.5), mat)


## A tube between two points (straps, reins, bones).
static func _rod(s: Dictionary, mat: Material, key: String, a: Vector3, b: Vector3, ra: float, rb: float,
		seg: int = 6) -> void:
	sculpt_add(s, tube_mesh(key, PackedVector3Array([Vector3.ZERO, b - a]), PackedFloat32Array([ra, rb]), seg),
		Transform3D(Basis.IDENTITY, a), mat)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var hd := m("dusk_hide")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var leather := m("shadow_leather")
	var silver := m("shadow_silver")
	var iron := m("shadow_iron")
	# ---- mass: a deep narrow barrel, chest, sharp withers, a bony croup with jutting hip bones, shoulder blades
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	var barrel := lathe_mesh("dusk_barrel_v1", prof, 12)
	sculpt_add(s, barrel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1, 1, SY)), BC), hd)
	sculpt_put(s, sphere(0.36, 10, 6), hd, CHEST_C, Vector3.ZERO, CHEST_R / 0.36)
	sculpt_put(s, sphere(0.36, 10, 6), hd, CROUP_C, Vector3.ZERO, CROUP_R / 0.36)
	sculpt_put(s, sphere(0.2, 8, 4), hd, Vector3(0, 1.58, 0.29), Vector3(-8, 0, 0), Vector3(0.45, 0.5, 1.2))
	for sx: float in [-1.0, 1.0]:
		# hip bones and the point of the buttock (gaunt), scapula ridge, point of the shoulder
		sculpt_put(s, sphere(0.08, 8, 4), hd, Vector3(0.2 * sx, 1.54, -0.45), Vector3(0, 0, 0), Vector3(0.8, 0.6, 1.4))
		sculpt_put(s, sphere(0.2, 8, 4), hd, Vector3(0.175 * sx, 1.38, 0.42), Vector3(-28, 0, -6.0 * sx),
			Vector3(0.36, 1.0, 0.42))
	# ---- tattered caparison: the back cloth, dark hems front and back, ragged layered skirts on both flanks
	var at := Transform3D(Basis.IDENTITY, BC + Vector3(0, CAPA_UP, 0))
	sculpt_add(s, shell_mesh("dusk_capa_v2", CAPA_RX, CAPA_RY, -104.0, 104.0, -0.50, 0.18, 0.025, 12, 2, 1.0, 0.03),
		at, cloth)
	sculpt_add(s, shell_mesh("dusk_capa_back_v2", CAPA_RX + 0.008, CAPA_RY + 0.008, -106.0, 106.0, -0.53, -0.47, 0.03,
		12, 1), at, cdark)
	sculpt_add(s, shell_mesh("dusk_capa_front_v2", CAPA_RX + 0.008, CAPA_RY + 0.008, -106.0, 106.0, 0.14, 0.2, 0.03,
		12, 1), at, cdark)
	var skirt_y: float = BC.y + CAPA_UP + CAPA_RY * cos(deg_to_rad(104.0))
	var skirt_c := Vector3(0, skirt_y, BC.z - 0.16)
	for sx: float in [-1.0, 1.0]:
		var a0: float = 25.0 if sx > 0.0 else -155.0
		var a1: float = 155.0 if sx > 0.0 else -25.0
		# the long dark under-layer shows its rags below the team cloth
		sculpt_fringe(s, cdark, fringe_mesh("dusk_skirt_in_v2_%s" % sx, 0.29, 0.35, 0.32, 0.38, 0.15, a0, a1, 7, 0.15,
			0.02, 0.95), skirt_c + Vector3(0, -0.005, 0))
		sculpt_fringe(s, cloth, fringe_mesh("dusk_skirt_out_v2_%s" % sx, 0.298, 0.36, 0.33, 0.39, 0.1, a0, a1, 9, 0.1,
			0.022, 0.9), skirt_c)
		# a ragged crupper drape over each side of the rump (the tail stays free between them)
		var c0: float = 128.0 if sx > 0.0 else -172.0
		var c1: float = 172.0 if sx > 0.0 else -128.0
		sculpt_fringe(s, cloth, fringe_mesh("dusk_crupper_%s" % sx, 0.232, 0.248, 0.3, 0.32, 0.14, c0, c1, 3, 0.16, 0.02,
			0.9), CROUP_C + Vector3(0, 0.2, 0))
		# the Shadow diamond sigil: a dark diamond, a tarnished-silver diamond, a team-cloth heart
		var a := deg_to_rad(84.0 * sx)
		var nn := Vector3(sin(a) / CAPA_RX, cos(a) / CAPA_RY, 0.0).normalized()
		var ep := BC + Vector3(0, CAPA_UP, 0) + Vector3(CAPA_RX * sin(a), CAPA_RY * cos(a), -0.16) + nn * 0.014
		var eb := frame(ep, Vector3.UP, nn).basis
		var dia := eb * Basis(Vector3.BACK, PI * 0.25)
		sculpt_add(s, box(Vector3(0.21, 0.21, 0.02)), Transform3D(dia, ep), cdark)
		sculpt_add(s, box(Vector3(0.13, 0.13, 0.02)), Transform3D(dia, ep + nn * 0.008), silver)
		sculpt_add(s, box(Vector3(0.06, 0.06, 0.02)), Transform3D(dia, ep + nn * 0.016), cloth)
	# ---- saddle: seat, cantle, pommel, fenders, girth, stirrups
	sculpt_put(s, sphere(0.2, 10, 4), leather, Vector3(0, 1.665, 0.0), Vector3(-3, 0, 0), Vector3(0.95, 0.22, 1.2))
	sculpt_add(s, shell_mesh("dusk_cantle_v1", 0.16, 0.10, -84.0, 84.0, -0.03, 0.03, 0.05, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-18.0)), Vector3(0, 1.66, -0.2)), leather)
	sculpt_put(s, cyl(0.03, 0.05, 0.12, 8), iron, Vector3(0, 1.73, 0.2), Vector3(12, 0, 0))
	sculpt_put(s, sphere(0.045, 8, 4), silver, Vector3(0, 1.8, 0.215))
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, box(Vector3(0.03, 0.22, 0.30)), leather, Vector3(0.29 * sx, 1.53, 0.0), Vector3(0, 0, -22.0 * sx))
		sculpt_put(s, box(Vector3(0.025, 0.40, 0.045)), leather, Vector3(0.33 * sx, 1.24, 0.05), Vector3(0, 0, -5.0 * sx))
		sculpt_put(s, torus(0.028, 0.058, 10), silver, Vector3(0.345 * sx, 1.0, 0.05), Vector3(90, 0, 0))
		sculpt_put(s, box(Vector3(0.04, 0.025, 0.1)), silver, Vector3(0.345 * sx, 0.94, 0.05))
	sculpt_add(s, shell_mesh("dusk_girth_v2", 0.29, 0.345, -180.0, 180.0, 0.1, 0.17, 0.02, 10, 1), Transform3D(Basis.IDENTITY,
		BC), leather)
	# ---- breast collar with a silver medallion
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	sculpt_add(s, shell_mesh("dusk_collar_v1", 0.268, 0.29, -78.0, 78.0, -0.035, 0.035, 0.02, 10, 1),
		Transform3D(cb, Vector3(0, 1.2, 0.44)), leather)
	sculpt_put(s, cyl(0.06, 0.06, 0.03, 10), silver, Vector3(0, 1.2, 0.735), Vector3(90, 0, 0))
	sculpt_put(s, sphere(0.03, 6, 3), iron, Vector3(0, 1.2, 0.755))


# ================================================================ head (neck, skull, mane)

func _head_sculpt(s: Dictionary) -> void:
	var hd := m("dusk_hide")
	var smoke := m("dusk_smoke")
	var wisp := m("dusk_wisp")
	var dark := m("unit_eye_dark")
	var hoof := m("shadow_obsidian")
	var glow := m("shadow_glow_hero")
	var leather := m("shadow_leather")
	var silver := m("shadow_silver")
	# ---- neck: a long arched column, narrow from the side
	var np := PackedVector3Array()
	var nr := PackedFloat32Array()
	for i: int in NECK_P.size():
		np.append(NECK_P[i])
		nr.append(NECK_R[i])
	sculpt_add(s, tube_mesh("dusk_neck_v1", np, nr, 10, false, NECK_FLAT), Transform3D.IDENTITY, hd)
	# throat latch / crest bulge
	sculpt_put(s, sphere(0.14, 8, 4), hd, Vector3(0, 1.96, 0.9), Vector3(-40, 0, 0), Vector3(0.72, 0.9, 1.25))
	# ---- skull: a long bony wedge, big round jowls, hollow cheeks with sharp cheekbones
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	sculpt_add(s, lathe_mesh("dusk_skull_v1", prof, 10), Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z),
		SK_B), hd)
	sculpt_add(s, sphere(0.13, 10, 5), Transform3D(Basis(sf.basis.x * 0.74, sf.basis.y * 1.1, sf.basis.z * 1.0),
		SK_B + sd * 0.13 - up * 0.075), hd)
	sculpt_add(s, sphere(0.09, 8, 4), Transform3D(Basis(sf.basis.x * 0.86, sf.basis.y * 1.0, sf.basis.z * 0.9),
		SK_B + sd * 0.58 - up * 0.035), hd)
	for sx: float in [-1.0, 1.0]:
		var side := Vector3(sx, 0, 0)
		# nostrils (flared, dark), cheekbone ridge, eye socket, glowing slanted eye + a short glow wisp, heavy brow
		sculpt_put(s, sphere(0.032, 6, 3), dark, SK_B + sd * 0.63 + up * 0.035 + side * 0.052, Vector3.ZERO,
			Vector3(0.8, 1.0, 1.3))
		sculpt_add(s, sphere(0.05, 6, 3), Transform3D(Basis(sf.basis.x * 0.7, sf.basis.y * 2.6, sf.basis.z * 0.8),
			SK_B + sd * 0.27 - up * 0.02 + side * 0.078), hd)
		var eye := SK_B + sd * 0.15 + up * 0.055 + side * 0.093
		var ef := frame(eye, up, sd).basis
		var eb := Basis(up, 0.38 * sx) * ef * Basis(Vector3.RIGHT, 0.25)
		# (the eye socket, the glow slit and the brow bump: the CreatureFaceRig eyes, faces pass 2026-09-28)
		var wd := (-sd * 0.85 + up * 0.35 + side * 0.25).normalized()
		_tongue(s, glow, eye + side * 0.02 - sd * 0.04, wd, side, 0.022, 0.17, 0.5)
		# ears: tall, sharp, laid slightly back
		var ear := SK_B + up * 0.09 + side * 0.058 - sd * 0.01
		var ed := Vector3(0.28 * sx, 1.0, -0.3).normalized()
		var eaf := frame(ear, ed, Vector3(0, 0, 1))
		sculpt_add(s, cyl(0.0, 1.0, 1.0, 5), Transform3D(Basis(eaf.basis.x * 0.05, eaf.basis.y * 0.24, eaf.basis.z * 0.028),
			ear + ed * 0.12), hd)
		# bridle: cheek straps, silver bit rings, reins lying along the neck
		var ring := SK_B + sd * 0.54 - up * 0.035 + side * 0.078
		sculpt_put(s, torus(0.018, 0.04, 8), silver, ring, Vector3(0, 0, 90))
		_rod(s, leather, "dusk_cheek_%s" % sx, SK_B + sd * 0.02 + up * 0.08 + side * 0.075, ring - sd * 0.05 + up * 0.02,
			0.013, 0.013, 4)
		var rein_mid := Vector3(0.12 * sx, 1.74, 0.96)
		var rein_end := Vector3(0.16 * sx, 1.56, 0.62)
		sculpt_add(s, tube_mesh("dusk_rein_%s" % sx, PackedVector3Array([ring, rein_mid, rein_end]),
			PackedFloat32Array([0.012, 0.012, 0.012]), 4), Transform3D.IDENTITY, leather)
	# noseband + brow band (leather rings around the skull axis)
	var ring_b := Basis(sf.basis.z, sf.basis.x, sf.basis.y)   # torus axis (y) along the skull axis
	sculpt_add(s, torus(0.078, 0.1, 12), Transform3D(ring_b.scaled_local(Vector3(1.0, 0.25, 0.8)), SK_B + sd * 0.44), leather)
	sculpt_add(s, torus(0.125, 0.145, 12), Transform3D(ring_b.scaled_local(Vector3(1.0, 0.25, 0.8)), SK_B + sd * 0.06), leather)
	# ---- smoky mane: flame-like cones streaming up and back along the crest (dark smoke, pale wisp tips)
	for i: int in NECK_P.size() - 1:
		var t := (NECK_P[i + 1] - NECK_P[i]).normalized()
		var nu := Vector3(0, t.z, -t.y).normalized()
		for k: int in 3:
			var u: float = float(k) / 3.0
			var idx: int = i * 3 + k
			var p := NECK_P[i].lerp(NECK_P[i + 1], u)
			var r := lerpf(NECK_R[i], NECK_R[i + 1], u)
			var crest := p + nu * r * 0.86
			var sx: float = -1.0 if idx % 2 == 0 else 1.0
			# smoke streams back off the crest (lying low near the withers, lifting toward the poll)
			var dir := (nu * (0.45 + 0.12 * float(i)) + Vector3(0, 0.0, -1.0) + Vector3(0.3 * sx, 0, 0)).normalized()
			var ln: float = [0.26, 0.3, 0.34, 0.4, 0.44, 0.46, 0.46, 0.44, 0.4, 0.36, 0.34, 0.3][idx]
			_tongue(s, smoke, crest - nu * 0.03, dir, Vector3.RIGHT, 0.1, ln, 0.45)
			if idx % 2 == 1 or idx == 0:
				var wd := (dir + Vector3(0, 0.45, -0.2) - Vector3(0.35 * sx, 0, 0)).normalized()
				_tongue(s, wisp, crest + dir * ln * 0.3, wd, Vector3.RIGHT, 0.05, ln * 0.7, 0.45)
	# forelock falling over the brow, and a smoke plume between the ears
	for sx: float in [-1.0, 1.0]:
		_tongue(s, smoke, SK_B + up * 0.11 + Vector3(0.02 * sx, 0, 0), (sd * 0.9 + up * 0.45 + Vector3(0.15 * sx, 0, 0)).normalized(),
			Vector3.RIGHT, 0.055, 0.22, 0.5)
	_tongue(s, wisp, SK_B + up * 0.1 - sd * 0.02, (up * 0.8 - sd * 0.5).normalized(), Vector3.RIGHT, 0.05, 0.26, 0.45)
	_tongue(s, smoke, SK_B + up * 0.06 - sd * 0.06, (up * 0.6 - sd * 0.8).normalized(), Vector3.RIGHT, 0.07, 0.3, 0.5)
	# teeth-dark lip line under the muzzle
	sculpt_put(s, box(Vector3(0.1, 0.012, 0.09)), hoof, SK_B + sd * 0.6 - up * 0.1, Vector3(-44, 0, 0))


# ================================================================ legs + tail

## A long thin leg rooted at the pivot p (model space): muscled top, bony knee (front) / hock (hind), thin cannon,
## fetlock with smoky feathers, pastern, iron-shod hoof with a silver shoe.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var hd := m("dusk_hide")
	var smoke := m("dusk_smoke")
	var hoof := m("shadow_obsidian")
	var silver := m("shadow_silver")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	var o := Vector3(x, 0, z)
	var fet: Vector3
	var hoof_p: Vector3
	if front:
		sculpt_add(s, tube_mesh("dusk_fore_v1", PackedVector3Array([Vector3(0, 1.16, 0.0), Vector3(0, 0.88, 0.03),
			Vector3(0, 0.58, 0.02)]), PackedFloat32Array([0.13, 0.09, 0.058]), 8, false), Transform3D(Basis.IDENTITY, o), hd)
		sculpt_put(s, sphere(0.058, 8, 4), hd, o + Vector3(0, 0.56, 0.026), Vector3.ZERO, Vector3(0.95, 1.3, 1.0))
		sculpt_add(s, tube_mesh("dusk_fcannon_v1", PackedVector3Array([Vector3(0, 0.56, 0.02), Vector3(0, 0.2, 0.0)]),
			PackedFloat32Array([0.05, 0.043]), 6, false), Transform3D(Basis.IDENTITY, o), hd)
		fet = o + Vector3(0, 0.18, -0.005)
		hoof_p = o + Vector3(0, 0.052, 0.05)
	else:
		sculpt_put(s, sphere(0.2, 8, 5), hd, o + Vector3(-0.02 * signf(x), 1.0, 0.03), Vector3(10, 0, 0), Vector3(0.55, 1.2, 0.85))
		sculpt_add(s, tube_mesh("dusk_gaskin_v1", PackedVector3Array([Vector3(0, 1.0, 0.0), Vector3(0, 0.78, -0.07),
			Vector3(0, 0.56, -0.12)]), PackedFloat32Array([0.11, 0.075, 0.056]), 8, false), Transform3D(Basis.IDENTITY, o), hd)
		sculpt_put(s, sphere(0.05, 8, 4), hd, o + Vector3(0, 0.575, -0.14), Vector3.ZERO, Vector3(0.9, 1.1, 1.4))
		sculpt_add(s, tube_mesh("dusk_hcannon_v1", PackedVector3Array([Vector3(0, 0.56, -0.12), Vector3(0, 0.2, -0.09)]),
			PackedFloat32Array([0.05, 0.043]), 6, false), Transform3D(Basis.IDENTITY, o), hd)
		fet = o + Vector3(0, 0.18, -0.095)
		hoof_p = o + Vector3(0, 0.052, -0.045)
	sculpt_put(s, sphere(0.05, 8, 4), hd, fet, Vector3.ZERO, Vector3(1.0, 1.1, 1.15))
	_rod(s, hd, "dusk_pastern_%s" % front, fet, hoof_p + Vector3(0, 0.04, 0.0), 0.044, 0.05, 6)
	sculpt_put(s, cyl(0.056, 0.074, 0.09, 8), hoof, hoof_p, Vector3(4, 0, 0))
	sculpt_put(s, cyl(0.077, 0.077, 0.018, 8), silver, hoof_p + Vector3(0, -0.036, 0.004))
	# smoky fetlock feathers trailing behind the joint
	for k: int in 3:
		var dx: float = (float(k) - 1.0) * 0.03
		_tongue(s, smoke, fet + Vector3(dx, 0.03, -0.03), Vector3(dx * 3.0, -0.75, -0.65).normalized(), Vector3.RIGHT,
			0.035, 0.15 - absf(dx), 0.5)


func _tail_sculpt(s: Dictionary) -> void:
	var hd := m("dusk_hide")
	var smoke := m("dusk_smoke")
	var wisp := m("dusk_wisp")
	var tp := PackedVector3Array([Vector3(0, 1.5, -0.8), Vector3(0, 1.45, -0.93), Vector3(0, 1.32, -1.01)])
	sculpt_add(s, tube_mesh("dusk_dock_v1", tp, PackedFloat32Array([0.065, 0.055, 0.042]), 6), Transform3D.IDENTITY, hd)
	# a plume of smoke tongues pouring down and back from the dock, pale wisps on the outside
	var tongues: Array = [[0.0, Vector3(0.0, 0.25, -1.0), 0.09, 0.42], [0.35, Vector3(0.1, -0.35, -1.0), 0.095, 0.6],
		[0.5, Vector3(-0.12, -0.55, -0.9), 0.09, 0.66], [0.7, Vector3(0.05, -0.85, -0.6), 0.09, 0.74],
		[0.85, Vector3(-0.08, -1.0, -0.35), 0.085, 0.7], [1.0, Vector3(0.1, -1.0, -0.2), 0.08, 0.62],
		[1.0, Vector3(-0.1, -1.0, -0.45), 0.075, 0.55]]
	for tg: Array in tongues:
		var u: float = tg[0]
		var base: Vector3 = tp[0].lerp(tp[1], u * 2.0) if u < 0.5 else tp[1].lerp(tp[2], (u - 0.5) * 2.0)
		_tongue(s, smoke, base, (tg[1] as Vector3).normalized(), Vector3.RIGHT, tg[2], tg[3], 0.5)
	var wisps: Array = [[0.3, Vector3(0.25, -0.2, -1.0), 0.05, 0.42], [0.6, Vector3(-0.25, -0.6, -0.8), 0.05, 0.48],
		[0.9, Vector3(0.2, -1.0, -0.5), 0.045, 0.5], [0.1, Vector3(0.0, 0.6, -0.8), 0.05, 0.3]]
	for w: Array in wisps:
		var u: float = w[0]
		var base: Vector3 = tp[0].lerp(tp[1], u * 2.0) if u < 0.5 else tp[1].lerp(tp[2], (u - 0.5) * 2.0)
		_tongue(s, wisp, base + Vector3(0, 0, -0.03), (w[1] as Vector3).normalized(), Vector3.RIGHT, w[2], w[3], 0.45)


# ================================================================ barding (tarnished silver)

func _body_barding(s: Dictionary) -> void:
	var plate := m("shadow_silver")
	var iron := m("shadow_iron")
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	var at := Transform3D(cb, Vector3(0, 1.0, 0.44))
	# peytral: a curved chest plate from the breast collar down to the elbows, an iron rim, rivets
	sculpt_add(s, shell_mesh("dusk_peytral_v1", 0.285, 0.305, -80.0, 80.0, 0.0, 0.3, 0.025, 10, 2, 1.06, 0.04), at, plate)
	sculpt_add(s, shell_mesh("dusk_peytral_rim_v1", 0.298, 0.318, -82.0, 82.0, 0.27, 0.32, 0.03, 10, 1), at, iron)
	sculpt_add(s, shell_mesh("dusk_peytral_low_v1", 0.29, 0.31, -80.0, 80.0, -0.02, 0.02, 0.03, 10, 1), at, iron)
	for k: int in 5:
		var a := deg_to_rad(-60.0 + 30.0 * float(k))
		sculpt_put(s, sphere(0.022, 6, 3), iron, Vector3(0.3 * sin(a), 1.16, 0.44 + 0.325 * cos(a)))
	sculpt_put(s, cyl(0.0, 0.05, 0.12, 6), plate, Vector3(0, 1.1, 0.77), Vector3(90, 0, 0))


func _head_barding(s: Dictionary) -> void:
	var plate := m("shadow_silver")
	var iron := m("shadow_iron")
	var gem := m("shadow_glow_mid")
	var sd := (SK_F - SK_B).normalized()
	var sf := frame(SK_B, sd, Vector3.UP)
	var up := Vector3(0, sd.z, -sd.y)
	# chanfron: shell z along the skull axis, shell y = up (the eyes stay free at the sides)
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	var at := Transform3D(hb, SK_B)
	sculpt_add(s, shell_mesh("dusk_chanfron_v1", 0.125, 0.158, -52.0, 52.0, 0.03, 0.52, 0.022, 6, 3, 0.66, 0.02), at, plate)
	sculpt_add(s, shell_mesh("dusk_chanfron_rim_v1", 0.106, 0.128, -55.0, 55.0, 0.5, 0.54, 0.028, 6, 1), at, iron)
	sculpt_add(s, tube_mesh("dusk_chanfron_ridge_v1", PackedVector3Array([SK_B + sd * 0.05 + up * 0.165, SK_B + sd * 0.28 +
		up * 0.14, SK_B + sd * 0.5 + up * 0.105]), PackedFloat32Array([0.022, 0.02, 0.014]), 5), Transform3D.IDENTITY, iron)
	for sx: float in [-1.0, 1.0]:
		var side := Vector3(sx, 0, 0)
		sculpt_add(s, shell_mesh("dusk_cheek_plate_%s" % sx, 0.118, 0.15, minf(68.0 * sx, 112.0 * sx),
			maxf(68.0 * sx, 112.0 * sx), 0.22, 0.42, 0.02, 3, 1, 0.84), at, plate)
		sculpt_put(s, sphere(0.02, 6, 3), iron, SK_B + sd * 0.25 + side * 0.105 - up * 0.02)
	# a swept-back spike between the ears and a violet gem on the brow
	var sp := (up * 0.75 - sd * 0.65).normalized()
	sculpt_add(s, cyl(0.0, 1.0, 1.0, 6), Transform3D(frame(Vector3.ZERO, sp, Vector3.RIGHT).basis.scaled_local(Vector3(0.04,
		0.2, 0.03)), SK_B + sd * 0.06 + up * 0.15 + sp * 0.1), plate)
	sculpt_put(s, sphere(0.034, 8, 4), gem, SK_B + sd * 0.22 + up * 0.17, Vector3.ZERO, Vector3(1.0, 1.0, 1.3))
	# crinet: dark iron lames down both sides of the neck, each edged in silver (the crest stays free for the mane;
	# the silver face stays the one bright read of the barding)
	for i: int in 3:
		var t := (NECK_P[i + 1] - NECK_P[i]).normalized()
		var nu := Vector3(0, t.z, -t.y).normalized()
		var lb := Basis(nu.cross(t), nu, t)
		var ln: float = (NECK_P[i + 1] - NECK_P[i]).length()
		var r0: float = NECK_R[i] + 0.022
		var r1: float = NECK_R[i + 1] + 0.022
		for sx: float in [-1.0, 1.0]:
			var a0: float = 28.0 * sx
			var a1: float = 104.0 * sx
			var key := "dusk_crinet_%d_%s" % [i, sx]
			sculpt_add(s, shell_mesh(key, r0 * NECK_FLAT + 0.01, r0, minf(a0, a1), maxf(a0, a1), -0.02, ln * 1.02, 0.02, 4, 1,
				r1 / r0, 0.03), Transform3D(lb, NECK_P[i]), iron)
			sculpt_add(s, shell_mesh(key + "_rim", r0 * NECK_FLAT + 0.016, r0 + 0.006, minf(a0, a1), maxf(a0, a1), -0.025, 0.0,
				0.024, 4, 1), Transform3D(lb, NECK_P[i]), plate)


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_dissolve_v = -1.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))


## The dusk rear: a half rear with the fore hooves pawing the air, the head tossed up and shaken, then a snort (the
## eyes flare) as it comes down.
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.4, 0.85, 1.25, 1.0, 1.0)
	rot(P_MOUNT, Vector3(-7.5 * DEG * env, 0, 0))
	pos(P_ROOT, Vector3(0, 0.06 * env, -0.04 * env))
	var paw: float = sin(maxf(t - 0.3, 0.0) * TAU * 2.4)
	rot(P_LEG_FL, Vector3((-34.0 + 12.0 * paw) * DEG * env, 0, 0))
	rot(P_LEG_FR, Vector3((-26.0 - 12.0 * paw) * DEG * env, 0, 0))
	rot(P_LEG_BL, Vector3(-7.0 * DEG * env, 0, 0))
	rot(P_LEG_BR, Vector3(-7.0 * DEG * env, 0, 0))
	var toss := _k3(t, 0.1, 0.45, 1.0, 1.5, 1.0, 0.6)
	rot(P_MOUNT_HEAD, Vector3(-12.0 * DEG * toss, 10.0 * DEG * sin(t * TAU * 1.8) * toss, 0))
	xrot(X_TAIL, Vector3(-14.0 * DEG * env, 18.0 * DEG * sin(t * TAU * 1.5) * env, 0))
	if _fidget_prev < 1.2 and t >= 1.2:
		_flare = maxf(_flare, 0.7)
		_on_mount_event(&"fidget_snort")
	return 1.7


## Death: a violet dissolve flare as it goes down (the Shadow idiom), fading to a faint violet sheen on the body.
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		return
	var t := _death_t
	var v: float = 0.22 * smoothstep(0.1, 0.45, t) * (1.0 - 0.7 * smoothstep(0.55, 1.0, t))
	v = snappedf(v, 0.02)
	if v == _dissolve_v:
		return
	_dissolve_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", DISSOLVE)


func _mount_revive() -> void:
	if _face:
		_face.reset()
	_dissolve_v = -1.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)


## The eyes (faces pass 2026-09-28): slanted glowing violet eyes (the old glow slits: the irises glow) under a heavy
## brow ridge that carries the expression; the glow wisps stay. Drawn inside the merged head (CreatureFaceRig host).
static func face_spec() -> Dictionary:
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var eye := SK_B + sd * 0.15 + up * 0.055 + Vector3(0.093, 0, 0)
	return CreatureFaceRig.side_eye_spec(eye, Vector3(0.92, 0.12, 0.36), 0.040, Color(0.125, 0.105, 0.155),
		Color(0.78, 0.40, 1.0), 0.9, {"eye": {"tilt": 0.012, "top": 0.022}, "palette": {"brow": Color(0.30, 0.24, 0.40)}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
