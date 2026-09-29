extends MountModel
## Roan Courser (cavalry-mounts.md 6.1 / 10, task 13.V6): the neutral travel horse every champion can buy (120 purse
## essence at a tavern or the own Stables; ridden by the Wayfinder, Oathwall, Coin-Cutter and Mender in 13.V12).
## A plain, friendly working cob, 2.6 m nose to tail: stocky and round (withers 1.52 m, broad barrel and rump, short
## thick legs with feathered fetlocks), a thick crested neck carried low and relaxed, a broad kind head with big soft
## eyes, pricked ears and a white blaze. Red-roan coat (roan_courser_coat), solid chestnut head and legs
## (roan_courser_chestnut), dark chestnut mane falling to the right, full tail; two white hind socks with pale hooves.
## Travel kit = the read at 40 m: a cream bedroll strapped across the croup behind the cantle (roan_courser_wool,
## leather straps, dark wool bands), fat leather saddlebags on both flanks, a tin pot on the left bag, a coil of rope
## on the right of the pommel; plain brown saddle, iron stirrups, a simple bridle with brass rosettes, breast collar.
## Team colour = the saddle-cloth ONLY (fire_cloth + fire_cloth_dark hem and woven stripe, like the champions'
## kingdom_color): no kingdom emblem, no glow, no magic.
## Kept clearly apart from the Dusk Steed (13.V3, tall gaunt black horse, violet eye glow, smoke mane, caparison):
## short, round, warm-coloured, head low, gear on the back instead of a caparison, 0 glow points.
## Barding: none (spec 6.1, champions never buy it): set_barded(on) is accepted and remembered (is_barded) but
## changes nothing on the model.
## Motion: easy 4-beat walk, a rocking canter-gallop from 3.6 m/s, a "graze" fidget (head down, nibbles, lifts, a
## friendly head shake with a snort, tail swish), generic charge / toss / hit, death = the kit fall (rolls onto its
## side and lies there).
## Budget (section 10 mount): 8 authored meshes incl. the blob (7 sculpts + blob), 8 draw instances (Body, Head,
## 4 legs, Tail, blob), 0 lights, 0 particle systems.

const OWN := "res://art/units/mounts/roan_courser/materials/"
const KIT := "res://art/units/kit/materials/"
const WPN := "res://art/units/champions/weapons/materials/"
const BLOB_TINT := Color(0.06, 0.04, 0.03, 0.5)

## Body centre (= the Mount pivot) and the barrel of revolution along z: [z offset, lateral radius], vertical x SY.
const BC := Vector3(0, 1.06, -0.02)
const SY := 1.12
const BARREL_Z: Array[float] = [-0.78, -0.72, -0.58, -0.38, -0.12, 0.14, 0.38, 0.56, 0.68, 0.74]
const BARREL_R: Array[float] = [0.00, 0.20, 0.30, 0.335, 0.34, 0.345, 0.335, 0.30, 0.22, 0.00]
const CHEST_C := Vector3(0, 1.08, 0.44)
const CHEST_R := Vector3(0.31, 0.36, 0.30)
const WITHERS_C := Vector3(0, 1.32, 0.44)
const WITHERS_R := Vector3(0.20, 0.20, 0.24)
const CROUP_C := Vector3(0, 1.14, -0.54)
const CROUP_R := Vector3(0.355, 0.35, 0.36)
## Neck (Head pivot): tube points / radii from the chest to the poll; lateral squash NECK_FLAT.
const NECK_P: Array[Vector3] = [Vector3(0, 1.20, 0.40), Vector3(0, 1.42, 0.60), Vector3(0, 1.63, 0.78),
	Vector3(0, 1.81, 0.90), Vector3(0, 1.93, 0.97)]
const NECK_R: Array[float] = [0.27, 0.22, 0.18, 0.145, 0.12]
const NECK_FLAT := 0.74
## Skull: from SK_B (poll) toward SK_F (muzzle); lathe profile [s along the axis, radius], lateral squash SK_X.
const SK_B := Vector3(0, 1.93, 1.00)
const SK_F := Vector3(0, 1.50, 1.40)
const SK_S: Array[float] = [-0.03, 0.0, 0.06, 0.16, 0.28, 0.40, 0.48, 0.54, 0.58]
const SK_R: Array[float] = [0.0, 0.11, 0.14, 0.15, 0.125, 0.10, 0.10, 0.09, 0.0]
const SK_X := 0.82
## Bedroll across the croup (centre, radius, length).
const ROLL_C := Vector3(0, 1.60, -0.44)
const ROLL_R := 0.12
const ROLL_L := 0.80


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "roan_courser", face_spec())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	ensure_shadow_blob(0.6, BLOB_TINT)
	_shadow.scale = Vector3(1.7, 1.0, 3.2)
	_shadow.position = Vector3(0, 0.02, 0.05)


static func m(name: String) -> Material:
	if name.begins_with("roan_courser"):
		return material_at(OWN + name + ".tres")
	if name.begins_with("weapon_"):
		return material_at(WPN + name + ".tres")
	return material_at(KIT + name + ".tres")


## Unit sphere placed with a basis (ellipsoids along any frame).
static func _ell(s: Dictionary, mat: Material, at: Vector3, b: Basis, r: Vector3, seg: int = 10, rings: int = 5) -> void:
	sculpt_add(s, sphere(1.0, seg, rings), Transform3D(Basis(b.x * r.x, b.y * r.y, b.z * r.z), at), mat)


# ================================================================ body (barrel, chest, croup, tack, travel kit)

func _body_sculpt(s: Dictionary) -> void:
	var coat := m("roan_courser_coat")
	var wool := m("roan_courser_wool")
	var mane := m("fire_fur")
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var saddle := m("fire_leather")
	var leather := m("weapon_leather")
	var brass := m("weapon_brass")
	var iron := m("weapon_iron")
	var rope := m("weapon_ash")
	# ---- mass: a round barrel, deep chest, withers, a broad rump with two haunches
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	var barrel := lathe_mesh("roan_barrel_v1", prof, 12)
	sculpt_add(s, barrel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1, 1, SY)), BC), coat)
	sculpt_put(s, sphere(1.0, 10, 5), coat, CHEST_C, Vector3.ZERO, CHEST_R)
	sculpt_put(s, sphere(1.0, 8, 4), coat, WITHERS_C, Vector3.ZERO, WITHERS_R)
	sculpt_put(s, sphere(1.0, 10, 5), coat, CROUP_C, Vector3.ZERO, CROUP_R)
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, sphere(1.0, 8, 4), coat, Vector3(0.14 * sx, 1.12, -0.62), Vector3.ZERO, Vector3(0.24, 0.32, 0.30))
		# shoulder muscle over the fore leg
		sculpt_put(s, sphere(1.0, 6, 3), coat, Vector3(0.17 * sx, 1.08, 0.46), Vector3(-18, 0, 0), Vector3(0.14, 0.30, 0.20))
	# ---- team saddle-cloth: a big square blanket under the saddle, dark hem + a woven stripe (both team-darkened)
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, shell_mesh("roan_cloth_v2", 0.36, 0.40, -122.0, 122.0, -0.44, 0.26, 0.03, 12, 2, 1.0, 0.02), at, cloth)
	for sx: float in [-1.0, 1.0]:
		var h0: float = 114.0 * sx
		var h1: float = 123.5 * sx
		sculpt_add(s, shell_mesh("roan_hem2_%s" % sx, 0.368, 0.408, minf(h0, h1), maxf(h0, h1), -0.45, 0.27, 0.035, 1, 2,
			1.0, 0.02), at, cdark)
		var t0: float = 100.0 * sx
		var t1: float = 104.0 * sx
		sculpt_add(s, shell_mesh("roan_stripe2_%s" % sx, 0.366, 0.406, minf(t0, t1), maxf(t0, t1), -0.44, 0.26, 0.034, 1, 2,
			1.0, 0.02), at, cdark)
	sculpt_add(s, shell_mesh("roan_hem_back_v2", 0.368, 0.408, -123.5, 123.5, -0.45, -0.40, 0.035, 6, 1), at, cdark)
	sculpt_add(s, shell_mesh("roan_hem_front_v2", 0.368, 0.408, -123.5, 123.5, 0.22, 0.27, 0.035, 6, 1), at, cdark)
	# ---- saddle: plain brown seat, cushion, cantle, pommel, skirts, girth, stirrups
	sculpt_add(s, shell_mesh("roan_saddle_v2", 0.378, 0.422, -54.0, 54.0, -0.30, 0.10, 0.045, 8, 2, 1.0, 0.0), at, saddle)
	sculpt_put(s, sphere(0.2, 8, 3), leather, Vector3(0, 1.49, -0.11), Vector3.ZERO, Vector3(0.9, 0.2, 1.0))
	sculpt_add(s, shell_mesh("roan_cantle_v1", 0.19, 0.12, -80.0, 80.0, -0.035, 0.035, 0.06, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-15.0)), Vector3(0, 1.47, -0.30)), saddle)
	sculpt_add(s, shell_mesh("roan_pommel_v1", 0.16, 0.10, -75.0, 75.0, -0.03, 0.03, 0.06, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(15.0)), Vector3(0, 1.48, 0.11)), saddle)
	sculpt_put(s, cyl(0.035, 0.05, 0.08, 8), brass, Vector3(0, 1.60, 0.12), Vector3(12, 0, 0))
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, box(Vector3(0.03, 0.15, 0.24)), saddle, Vector3(0.315 * sx, 1.33, -0.10), Vector3(0, 0, 38.0 * sx))
		sculpt_put(s, box(Vector3(0.03, 0.40, 0.055)), leather, Vector3(0.375 * sx, 1.08, -0.04), Vector3(0, 0, 6.0 * sx))
		sculpt_put(s, torus(0.035, 0.075, 6), iron, Vector3(0.395 * sx, 0.86, -0.04), Vector3(0, 0, 90))
		sculpt_put(s, box(Vector3(0.05, 0.03, 0.12)), iron, Vector3(0.395 * sx, 0.80, -0.04))
	sculpt_add(s, shell_mesh("roan_girth_v1", 0.352, 0.394, -180.0, 180.0, 0.10, 0.19, 0.025, 12, 1), at, leather)
	# breast collar across the chest with a brass medallion
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, tube_mesh("roan_collar_%s" % sx, PackedVector3Array([Vector3(0.31 * sx, 1.30, 0.20),
			Vector3(0.30 * sx, 1.14, 0.46), Vector3(0.24 * sx, 1.06, 0.66), Vector3(0.0, 1.00, 0.765)]),
			PackedFloat32Array([0.022, 0.024, 0.024, 0.024]), 5, false), Transform3D.IDENTITY, leather)
	sculpt_add(s, cyl(0.055, 0.055, 0.02, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.00, 0.78)), brass)
	# ---- bedroll across the croup behind the cantle: cream wool, two dark bands, two leather straps with buckles
	var rb := Basis(Vector3.BACK, PI * 0.5)       # cylinder axis Y -> model X
	sculpt_add(s, cyl(ROLL_R, ROLL_R, ROLL_L, 10), Transform3D(rb, ROLL_C), wool)
	sculpt_add(s, cyl(ROLL_R * 0.55, ROLL_R * 0.55, ROLL_L + 0.01, 8), Transform3D(rb, ROLL_C), mane)
	for bx: float in [-0.31, 0.31]:
		sculpt_add(s, cyl(ROLL_R + 0.004, ROLL_R + 0.004, 0.05, 10, false), Transform3D(rb, ROLL_C + Vector3(bx, 0, 0)), mane)
	for bx: float in [-0.17, 0.17]:
		sculpt_add(s, cyl(ROLL_R + 0.016, ROLL_R + 0.016, 0.045, 8, false), Transform3D(rb, ROLL_C + Vector3(bx, 0, 0)), saddle)
		sculpt_put(s, box(Vector3(0.05, 0.035, 0.03)), brass, ROLL_C + Vector3(bx, ROLL_R + 0.012, 0.03))
	# ---- saddlebags on both flanks (rounded bottoms, dark flaps, straps, brass buckles)
	for sx: float in [-1.0, 1.0]:
		var bc := Vector3(0.425 * sx, 1.24, -0.50)
		var bb := Basis.from_euler(Vector3(0, 0, deg_to_rad(12.0 * sx)))
		sculpt_add(s, box(Vector3(0.13, 0.30, 0.34)), Transform3D(bb, bc), leather)
		sculpt_add(s, cyl(0.065, 0.065, 0.34, 8), Transform3D(bb * Basis(Vector3.RIGHT, PI * 0.5), bc + bb.y * -0.15), leather)
		sculpt_add(s, box(Vector3(0.145, 0.15, 0.355)), Transform3D(bb, bc + bb.y * 0.10 + bb.x * 0.004 * sx), saddle)
		sculpt_add(s, box(Vector3(0.15, 0.22, 0.05)), Transform3D(bb, bc + bb.y * -0.01), saddle)
		sculpt_add(s, box(Vector3(0.158, 0.05, 0.075)), Transform3D(bb, bc + bb.y * 0.02), brass)
	# asymmetric travel details: a tin pot on the left bag, a coil of rope right of the pommel
	sculpt_put(s, cyl(0.085, 0.07, 0.13, 6), iron, Vector3(-0.47, 1.14, -0.72), Vector3(0, 0, 10))
	sculpt_put(s, torus(0.045, 0.115, 6), rope, Vector3(0.40, 1.26, 0.14), Vector3(0, 0, 90 - 30))


# ================================================================ head (neck, skull, mane, bridle)

## Skull radius at s along the skull axis (linear in the profile).
static func _sk_r(sv: float) -> float:
	for i: int in range(1, SK_S.size()):
		if sv < SK_S[i]:
			return lerpf(SK_R[i - 1], SK_R[i], (sv - SK_S[i - 1]) / (SK_S[i] - SK_S[i - 1]))
	return 0.0


## [point, radius, crest normal] on the neck axis at t (0 chest .. 1 poll).
static func _neck_at(t: float) -> Array:
	var f: float = clampf(t, 0.0, 1.0) * float(NECK_P.size() - 1)
	var i: int = mini(int(f), NECK_P.size() - 2)
	var u: float = f - float(i)
	var p: Vector3 = NECK_P[i].lerp(NECK_P[i + 1], u)
	var r: float = lerpf(NECK_R[i], NECK_R[i + 1], u)
	var tg: Vector3 = (NECK_P[i + 1] - NECK_P[i]).normalized()
	return [p, r, Vector3(0, tg.z, -tg.y)]


func _head_sculpt(s: Dictionary) -> void:
	var coat := m("roan_courser_coat")
	var head := m("roan_courser_chestnut")
	var mane := m("fire_fur")
	var dark := m("fire_hair")
	var white := m("shadow_bone")
	var eye := m("unit_eye_dark")
	var leather := m("weapon_leather")
	var brass := m("weapon_brass")
	var iron := m("weapon_iron")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)          # perpendicular to the skull axis: the face front
	var sf := frame(SK_B, sd, up)
	var lat := sf.basis.x
	# ---- neck: a thick crested cob neck, deep and narrow
	var np := PackedVector3Array()
	var nr := PackedFloat32Array()
	for i: int in NECK_P.size():
		np.append(NECK_P[i])
		nr.append(NECK_R[i])
	sculpt_add(s, tube_mesh("roan_neck_v1", np, nr, 10, false, NECK_FLAT), Transform3D.IDENTITY, coat)
	var c0: Array = _neck_at(0.45)
	_ell(s, coat, (c0[0] as Vector3) + (c0[2] as Vector3) * 0.07, frame(Vector3.ZERO, NECK_P[3] - NECK_P[1],
		Vector3.UP).basis, Vector3(0.12, 0.36, 0.14), 8, 4)
	# ---- skull (broad, short, kind), jowl, muzzle, nostrils
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	var skull := lathe_mesh("roan_skull_v1", prof, 10)
	sculpt_add(s, skull, Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z), SK_B), head)
	_ell(s, head, SK_B + sd * 0.15 - up * 0.08, sf.basis, Vector3(0.11, 0.15, 0.12), 8, 4)
	var muz := SK_B + sd * 0.49 - up * 0.02
	_ell(s, head, muz, sf.basis, Vector3(0.10, 0.12, 0.115), 8, 4)
	_ell(s, dark, SK_B + sd * 0.55 - up * 0.06, sf.basis, Vector3(0.085, 0.07, 0.07), 6, 3)
	for sx: float in [-1.0, 1.0]:
		_ell(s, dark, SK_B + sd * 0.55 + up * 0.04 + lat * 0.05 * sx, sf.basis, Vector3(0.026, 0.032, 0.03), 6, 3)
	# ---- white blaze: star, stripe, snip
	var bz: Array = [[0.10, 0.065, 0.075], [0.28, 0.036, 0.14], [0.46, 0.055, 0.065]]
	for b: Array in bz:
		var sv: float = b[0]
		var rr: float = _sk_r(sv) if sv < 0.44 else 0.10
		_ell(s, white, SK_B + sd * sv + up * (rr * 0.93), sf.basis, Vector3(b[1], b[2], 0.024), 6, 3)
	# ---- big soft eyes with a brow and a catch-light, pricked ears with dark tips
	for sx: float in [-1.0, 1.0]:
		var er: float = _sk_r(0.15) * SK_X
		var ep := SK_B + sd * 0.15 + up * 0.04 + lat * (er * 0.9) * sx
		# (the eye, its catch-light and the brow: the CreatureFaceRig eyes, faces pass 2026-09-28)
		var ear := SK_B + Vector3(0.07 * sx, 0.07, 0.01)
		var ed := Vector3(0.24 * sx, 1.0, 0.26).normalized()
		sculpt_add(s, cyl(0.0, 0.052, 0.18, 6), Transform3D(Basis(Quaternion(Vector3.UP, ed)).scaled_local(Vector3(1.0, 1.0,
			0.6)), ear + ed * 0.08), head)
		sculpt_add(s, cyl(0.0, 0.024, 0.06, 6), Transform3D(Basis(Quaternion(Vector3.UP, ed)).scaled_local(Vector3(1.0, 1.0,
			0.6)), ear + ed * 0.155), mane)
	# ---- mane: a crest ridge and thick locks falling to the right (a few short ones on the left), forelock
	var cp := PackedVector3Array()
	var cr := PackedFloat32Array()
	for i: int in 6:
		var n: Array = _neck_at(0.12 + 0.88 * float(i) / 5.0)
		cp.append((n[0] as Vector3) + (n[2] as Vector3) * (float(n[1]) * 0.86))
		cr.append(0.055 - 0.015 * float(i) / 5.0)
	sculpt_add(s, tube_mesh("roan_crest_v1", cp, cr, 6, true, 0.8), Transform3D.IDENTITY, mane)
	for i: int in 8:
		var t: float = 0.14 + 0.86 * float(i) / 7.0
		var n: Array = _neck_at(t)
		var root := (n[0] as Vector3) + (n[2] as Vector3) * (float(n[1]) * 0.84)
		var left: bool = i == 2 or i == 5
		var sx: float = -1.0 if left else 1.0
		var out := Vector3(sx, 0.35, 0.0).normalized()
		var dir := Vector3(0.55 * sx, -1.0, -0.12).normalized()
		sculpt_lock(s, mane, root + Vector3(0.03 * sx, 0, 0), dir, out, 0.20,
			(0.20 if left else lerpf(0.40, 0.30, t)), 0.07)
	for k: int in 3:
		var fx: float = (float(k) - 1.0) * 0.05
		sculpt_lock(s, mane, SK_B + Vector3(fx, 0.10, 0.02), (sd + up * 0.35 + Vector3(fx * 1.5, 0, 0)).normalized(), up,
			0.10, 0.20 - absf(fx), 0.045)
	# ---- bridle: headpiece, noseband, cheek straps, brass rosettes, iron bit rings, reins lying on the neck
	var hb := Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z)
	sculpt_add(s, torus(0.108, 0.132, 6), Transform3D(hb, SK_B + sd * 0.36), leather)
	sculpt_add(s, torus(0.125, 0.15, 6), Transform3D(hb * Basis(Vector3.RIGHT, 0.35), SK_B + sd * 0.03 - up * 0.01), leather)
	for sx: float in [-1.0, 1.0]:
		var cs := SK_B + sd * 0.19 + lat * (0.118 * sx) - up * 0.02
		sculpt_add(s, box(Vector3(0.02, 0.34, 0.035)), Transform3D(sf.basis, cs), leather)
		sculpt_put(s, sphere(0.03, 6, 3), brass, SK_B + sd * 0.05 + up * 0.07 + lat * (0.118 * sx))
		var ring := SK_B + sd * 0.50 - up * 0.05 + lat * (0.10 * sx)
		sculpt_add(s, torus(0.018, 0.034, 6), Transform3D(Basis(Vector3.BACK, PI * 0.5), ring), iron)
		sculpt_add(s, tube_mesh("roan_rein_%s" % sx, PackedVector3Array([ring, Vector3(0.14 * sx, 1.47, 1.10),
			Vector3(0.165 * sx, 1.47, 0.80), Vector3(0.15 * sx, 1.49, 0.52), Vector3(0.10 * sx, 1.52, 0.38)]),
			PackedFloat32Array([0.013, 0.013, 0.013, 0.013, 0.013]), 4, false), Transform3D.IDENTITY, leather)


# ================================================================ legs + tail

## A short thick leg rooted at the pivot p (model space): forearm / gaskin in the roan coat, chestnut knee / hock and
## cannon, feathered fetlock over the hoof. Hind legs: white socks, white feathers, pale hooves.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var coat := m("roan_courser_coat")
	var pts := m("roan_courser_chestnut")
	var mane := m("fire_fur")
	var white := m("shadow_bone")
	var at := Transform3D(Basis.IDENTITY, Vector3(p.x, 0, p.z))
	var feather := fringe_mesh("roan_feather_v1", 0.068, 0.072, 0.105, 0.115, 0.10, 0.0, 360.0, 7, 0.05, 0.02, 0.5)
	var hoof := lathe_mesh("roan_hoof_v1", PackedVector2Array([Vector2(0.10, 0.0), Vector2(0.094, 0.05),
		Vector2(0.072, 0.115)]), 8)
	if p.z > 0.0:
		sculpt_add(s, tube_mesh("roan_fore_upper_v1", PackedVector3Array([Vector3(0, 1.00, 0.0), Vector3(0, 0.80, 0.02),
			Vector3(0, 0.56, 0.02)]), PackedFloat32Array([0.14, 0.115, 0.08]), 8, false), at, coat)
		sculpt_put(s, sphere(0.085, 6, 3), pts, Vector3(p.x, 0.53, p.z + 0.03), Vector3.ZERO, Vector3(1.0, 1.15, 0.95))
		sculpt_add(s, tube_mesh("roan_fore_cannon_v1", PackedVector3Array([Vector3(0, 0.54, 0.02), Vector3(0, 0.36, 0.02),
			Vector3(0, 0.21, 0.02)]), PackedFloat32Array([0.068, 0.06, 0.066]), 8, false), at, pts)
		sculpt_put(s, sphere(0.072, 6, 3), pts, Vector3(p.x, 0.18, p.z))
		sculpt_add(s, tube_mesh("roan_fore_pastern_v1", PackedVector3Array([Vector3(0, 0.19, 0.0), Vector3(0, 0.10, 0.035)]),
			PackedFloat32Array([0.058, 0.066]), 8, false), at, pts)
		sculpt_fringe(s, mane, feather, Vector3(p.x, 0.27, p.z + 0.02))
		sculpt_add(s, hoof, Transform3D(Basis.IDENTITY, Vector3(p.x, 0.0, p.z + 0.045)), m("fire_leather"))
	else:
		sculpt_add(s, tube_mesh("roan_hind_upper_v1", PackedVector3Array([Vector3(0, 1.02, 0.0), Vector3(0, 0.84, -0.05),
			Vector3(0, 0.64, -0.10)]), PackedFloat32Array([0.17, 0.135, 0.085]), 8, false), at, coat)
		sculpt_put(s, sphere(0.08, 6, 3), pts, Vector3(p.x, 0.60, p.z - 0.115), Vector3.ZERO, Vector3(0.9, 1.2, 1.1))
		sculpt_add(s, tube_mesh("roan_hind_cannon_v1", PackedVector3Array([Vector3(0, 0.60, -0.10), Vector3(0, 0.40, -0.075),
			Vector3(0, 0.22, -0.055)]), PackedFloat32Array([0.07, 0.062, 0.066]), 8, false), at, pts)
		sculpt_add(s, tube_mesh("roan_sock_v1", PackedVector3Array([Vector3(0, 0.40, -0.075), Vector3(0, 0.30, -0.064),
			Vector3(0, 0.21, -0.055)]), PackedFloat32Array([0.067, 0.067, 0.072]), 8, false), at, white)
		sculpt_put(s, sphere(0.074, 6, 3), white, Vector3(p.x, 0.18, p.z - 0.055))
		sculpt_add(s, tube_mesh("roan_hind_pastern_v1", PackedVector3Array([Vector3(0, 0.19, -0.055), Vector3(0, 0.10, -0.02)]),
			PackedFloat32Array([0.058, 0.066]), 8, false), at, white)
		sculpt_fringe(s, white, feather, Vector3(p.x, 0.27, p.z - 0.035))
		sculpt_add(s, hoof, Transform3D(Basis.IDENTITY, Vector3(p.x, 0.0, p.z - 0.01)), m("weapon_ash"))


func _tail_sculpt(s: Dictionary) -> void:
	var mane := m("fire_fur")
	var coat := m("roan_courser_coat")
	var tp := PackedVector3Array([Vector3(0, 1.40, -0.84), Vector3(0, 1.36, -0.95), Vector3(0, 1.24, -1.01)])
	sculpt_add(s, tube_mesh("roan_dock_v1", tp, PackedFloat32Array([0.075, 0.065, 0.05]), 6), Transform3D.IDENTITY, coat)
	sculpt_put(s, sphere(0.09, 8, 4), mane, Vector3(0, 1.37, -0.96), Vector3(-30, 0, 0), Vector3(1.0, 1.2, 1.0))
	for i: int in 7:
		var a := deg_to_rad(lerpf(-75.0, 75.0, float(i) / 6.0))
		var out := Vector3(sin(a), 0.0, -cos(a)).normalized()
		var f: float = 0.2 + 0.6 * float(i % 3) / 2.0
		var base := tp[1].lerp(tp[2], f) + out * 0.035
		var ln: float = 0.80 - absf(float(i) - 3.0) * 0.04
		sculpt_lock(s, mane, base, Vector3(out.x * 0.12, -1.0, -0.14).normalized(), out, 0.17, ln, 0.07)


# ================================================================ motion (on top of MountModel)

## The graze: the neck drops to crop the grass, two nibbles, the head comes back up with a friendly shake and a
## snort, tail swishing at the flies.
func _pose_fidget(t: float) -> float:
	var down := _k3(t, 0.0, 0.7, 2.0, 2.6, 1.0, 1.0)
	var nib: float = sin((t - 0.8) * TAU * 2.2) * smoothstep(0.7, 0.9, t) * (1.0 - smoothstep(1.8, 2.0, t))
	var shake := _k3(t, 2.45, 2.6, 2.95, 3.2, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3((56.0 * down + 5.0 * nib * down) * DEG, (6.0 * sin(t * 1.7) * down +
		12.0 * sin((t - 2.45) * TAU * 3.2) * shake) * DEG, 10.0 * DEG * sin((t - 2.45) * TAU * 3.2) * shake))
	rot(P_MOUNT, Vector3(3.5 * DEG * down, 0, 0))
	pos(P_ROOT, Vector3(0, -0.02 * down, 0))
	for k: int in 2:
		rot(LEGS[k], Vector3(-3.5 * DEG * down, 0, 0))
		rot(LEGS[k + 2], Vector3(-3.5 * DEG * down, 0, 0))
	xrot(X_TAIL, Vector3(6.0 * DEG, 22.0 * DEG * sin(t * TAU * 1.3), 0))
	if _fidget_prev < 2.55 and t >= 2.55:
		_on_mount_event(&"fidget_snort")
	return 3.2


# ================================================================ eyes (faces pass 2026-09-28)

## Eyes + expression (CreatureFaceRig).
var _face: CreatureFaceRig


## Big soft dark horse eyes with a catch-light and a chestnut brow ridge that carries the expression. Drawn inside the
## merged head (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var eye := SK_B + sd * 0.15 + up * 0.04 + Vector3(_sk_r(0.15) * SK_X * 0.9, 0, 0)
	return CreatureFaceRig.side_eye_spec(eye, Vector3(0.90, 0.10, 0.42), 0.040, Color(0.45, 0.23, 0.13),
		Color(0.26, 0.14, 0.07), 0.0, {"eye": {"top": 0.034, "bot": 0.026, "ir": 0.028},
		"palette": {"sclera": Color(0.10, 0.06, 0.04), "brow": Color(0.22, 0.10, 0.05), "lash": Color(0.07, 0.04, 0.02)}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


func _mount_ready() -> void:
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))


func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)


func _mount_revive() -> void:
	if _face:
		_face.reset()
