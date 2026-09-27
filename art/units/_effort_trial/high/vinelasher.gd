extends NatureWarModel
## Vinelasher, Nature T2 soldier (rush-balance.md 5.1 / 5.4; effort trial, level high). Height 1.8, melee reach 3.0.
## A lean bark warrior: long bark limbs, a light bark-tan chest plate, shoulders and mask (tops light), a team-leaf
## sash, pauldron, bracer and tabard, a russet leaf skirt (keeps the green off the main mass: green on grass), a crown
## of swept thorns. Silhouette hook: a 3 m thorn whip COILED around the right arm in three wide loops (the circle read), its tail curling up over the shoulder like a raised sting, the
## glowing tip bud (the ONE glow point, upper half) nodding by the head. Pink bud on the handle.
## Attack `whip_lash` (0.75 s): overhead wind-up, the coil vanishes and the full whip unrolls forward to 3 m, snaps
## down at 0.24 (the strike / release), a pink blossom opens on the handle, then the whip reels back into the coil.
## Cast (Snare Lash, 1.0 s): a low forward lash, the tip curls down around the target, a hard yank back.
## Parts: merged Hips / LegL / LegR / Chest / Head / ArmL / ArmR + keep_separate Coil (rest), Lash and Bloom (only
## during the attack / cast), VetTrim (L4) + blob. Glow: whip tip only.

const ATTACK_LEN := 0.75
const CAST_LEN := 1.0
const LASH_LEN := 2.5            # handle bottom -> tip (the handle adds 0.3 m: 3 m reach with the lunge)
const HANDLE_BOTTOM := Vector3(0.37, 0.56, 0.16)
const BLOSSOM := Color(0.95, 0.6, 0.75)

# whip_lash tracks: [t, value, ease] (NatureWarModel._kf). Arm x: - raises forward / overhead.
static var W_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, -165.0, 1, 0.24, -100.0, 2, 0.42, -88.0, 0, 0.75, 0.0, 0])
static var W_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -35.0, 1, 0.24, 30.0, 2, 0.75, 0.0, 0])
static var W_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, 28.0, 1, 0.24, -22.0, 2, 0.45, -10.0, 0, 0.75, 0.0, 0])
static var W_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, -10.0, 1, 0.24, 14.0, 2, 0.45, 6.0, 0, 0.75, 0.0, 0])
static var W_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.06, 1, 0.24, 0.18, 2, 0.45, 0.14, 0, 0.75, 0.0, 0])
static var W_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, 10.0, 1, 0.24, -28.0, 2, 0.50, -20.0, 0, 0.75, 0.0, 0])
static var W_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, -6.0, 1, 0.24, 18.0, 2, 0.50, 12.0, 0, 0.75, 0.0, 0])
# lash: length scale, flick (deg about the arm's x: - trails behind the swing, + snaps ahead / down), handle blossom
static var W_EXT := PackedFloat32Array([0.0, 0.15, 0, 0.06, 0.2, 0, 0.12, 0.35, 1, 0.22, 1.0, 1, 0.42, 1.0, 0,
	0.60, 0.2, 2, 0.68, 0.15, 0])
static var W_FLICK := PackedFloat32Array([0.0, -60.0, 0, 0.12, -70.0, 0, 0.20, -25.0, 1, 0.25, 14.0, 2, 0.32, -6.0, 1,
	0.42, 0.0, 0, 0.68, 20.0, 0])
static var W_BLOOM := PackedFloat32Array([0.0, 0.0, 0, 0.22, 0.0, 0, 0.30, 1.15, 1, 0.36, 1.0, 0, 0.56, 1.0, 0,
	0.74, 0.0, 2])
# Snare Lash cast tracks
static var S_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.15, -125.0, 1, 0.30, -98.0, 2, 0.50, -92.0, 0, 0.62, -30.0, 2,
	1.0, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.15, 24.0, 1, 0.30, -18.0, 2, 0.62, 20.0, 2, 1.0, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, 16.0, 2, 0.62, -12.0, 2, 1.0, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.12, 2, 0.50, 0.10, 0, 0.62, -0.16, 2, 1.0, 0.0, 0])
static var S_EXT := PackedFloat32Array([0.0, 0.15, 0, 0.15, 0.4, 1, 0.30, 1.0, 1, 0.50, 1.0, 0, 0.66, 0.25, 2,
	0.76, 0.15, 0])
static var S_FLICK := PackedFloat32Array([0.0, -60.0, 0, 0.15, -50.0, 0, 0.28, 4.0, 2, 0.36, 14.0, 1, 0.50, 14.0, 0,
	0.62, -40.0, 2, 0.76, -20.0, 0])
static var S_BLOOM := PackedFloat32Array([0.0, 0.0, 0, 0.55, 0.0, 0, 0.66, 1.15, 1, 0.72, 1.0, 0, 0.86, 1.0, 0,
	1.0, 0.0, 2])

var _coil: MeshInstance3D
var _lash: MeshInstance3D
var _bloom: MeshInstance3D
var _petals: GPUParticles3D
var _lash_pos: Vector3
var _lash_on: bool = false
var _bloom_v: float = 0.0
var _snare_prev: float = 0.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var russet := nature(&"nature_hair")
	var bark := nature(&"nature_bark")
	var dark := nature(&"nature_bark_dark")
	var bark_tan := nature(&"nature_skin")
	var thorn := nature(&"nature_thorn")
	var bloom := nature(&"nature_blossom")
	# ---- Legs: long lean bark legs, knee knot, long root feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _leg_mesh(), dark, Vector3(0.13 * sx, 0, 0))
		add_part(leg, sphere(0.065, 8, 4), bark, Vector3(0.13 * sx, 0.53, 0.075))
		add_part(leg, sphere(0.08, 8, 4), dark, Vector3(0.13 * sx, 0.05, 0.05), Vector3.ZERO, Vector3(0.9, 0.6, 1.6))
	# ---- Hips: a skirt of hanging team-dark leaves under a bark belt.
	add_part(hips, leaf_ring_mesh(7, 0.13, Vector3(0.16, 0.035, 0.32), -68.0, 12.0), russet, Vector3(0, 0.97, 0))
	# ---- Chest: lean bark torso, light bark-tan chest / back plates and shoulders, team sash, left team pauldron, tabard.
	add_part(chest, sphere(0.2, 10, 5), bark, Vector3(0, 1.22, 0), Vector3.ZERO, Vector3(1.05, 1.45, 0.78))
	add_part(chest, torus(0.11, 0.16, 10), dark, Vector3(0, 0.99, 0), Vector3.ZERO, Vector3(1.0, 1.3, 0.85))
	add_part(chest, sphere(0.15, 10, 5), bark_tan, Vector3(0, 1.31, 0.07), Vector3(-10, 0, 0), Vector3(1.25, 0.9, 0.55))
	add_part(chest, sphere(0.15, 10, 5), bark_tan, Vector3(0, 1.33, -0.07), Vector3(12, 0, 0), Vector3(1.2, 0.85, 0.5))
	add_part(chest, cyl(0.05, 0.065, 0.14, 6), bark, Vector3(0, 1.50, 0.01))
	for s: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.1, 8, 4), bark_tan, Vector3(0.25 * s, 1.41, 0), Vector3.ZERO, Vector3(1.15, 0.8, 1.05))
	add_part(chest, box(Vector3(0.09, 0.64, 0.36)), cloth, Vector3(0.0, 1.22, 0.0), Vector3(0, 0, -38))
	add_part(chest, _pauldron_mesh(), cloth, Vector3.ZERO)
	add_leaf(chest, Vector3(0, 0.86, 0.15), Vector3(0.22, 0.05, 0.36), cdark, Vector3(70, 0, 0))
	add_leaf(chest, Vector3(0, 0.86, -0.13), Vector3(0.26, 0.05, 0.40), russet, Vector3(110, 0, 0))
	# ---- Head: bark-tan mask, dark eye slit under a heavy brow, bark jaw, swept thorn crown, team leaf hood.
	add_part(head, sphere(0.13, 10, 5), bark_tan, Vector3(0, 1.66, 0.03), Vector3.ZERO, Vector3(0.85, 1.15, 0.95))
	add_part(head, sphere(0.09, 8, 4), bark, Vector3(0, 1.57, 0.07), Vector3.ZERO, Vector3(0.95, 0.8, 0.9))
	for s: float in [-1.0, 1.0]:
		add_part(head, box(Vector3(0.055, 0.026, 0.04)), palette(&"unit_eye_dark"), Vector3(0.036 * s, 1.665, 0.135),
			Vector3(0, 18.0 * s, -14.0 * s))
	add_part(head, box(Vector3(0.2, 0.045, 0.08)), bark, Vector3(0, 1.70, 0.115), Vector3(-12, 0, 0))
	add_part(head, _crown_mesh(), thorn, Vector3.ZERO)
	add_part(head, leaf_ring_mesh(6, 0.07, Vector3(0.12, 0.03, 0.17), 35.0, 15.0), bloom, Vector3(0, 1.765, 0.01))
	var trim := add_part(head, torus(0.10, 0.135, 10), palette(&"unit_gold_trim"), Vector3(0, 1.76, 0.03), Vector3.ZERO,
		Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Arms: lean bark arms, dark fists, team bracer on the left; the whip handle + pink bud in the right fist.
	add_part(arm_l, _arm_mesh(-1.0), bark, Vector3.ZERO)
	add_part(arm_l, sphere(0.06, 8, 4), dark, Vector3(-0.35, 0.82, 0.07))
	add_part(arm_l, cyl(0.07, 0.08, 0.18, 7), cloth, Vector3(-0.345, 0.95, 0.01), Vector3(-20, 0, 0))
	add_part(arm_r, _arm_mesh(1.0), bark, Vector3.ZERO)
	add_part(arm_r, sphere(0.065, 8, 4), dark, Vector3(0.35, 0.82, 0.08))
	add_part(arm_r, cyl(0.035, 0.042, 0.30, 6), dark, Vector3(0.36, 0.70, 0.12), Vector3(-16, 0, 0))
	add_part(arm_r, sphere(0.05, 8, 4), bloom, HANDLE_BOTTOM + Vector3(0, 0.01, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
	# ---- The whip: coiled (rest) / unrolled lash / handle blossom. Multi-surface meshes carry their own materials.
	_coil = add_part(arm_r, _coil_mesh(), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Coil")
	_lash = add_part(arm_r, _lash_mesh(), null, HANDLE_BOTTOM, Vector3.ZERO, Vector3.ONE, true, "Lash")
	_lash_pos = _lash.position
	_lash.visible = false
	_bloom = add_part(arm_r, _bloom_mesh(), bloom, HANDLE_BOTTOM, Vector3.ZERO, Vector3.ONE, true, "Bloom")
	_bloom.visible = false
	_petals = make_petals(BLOSSOM, 8, 0.7, 0.1, 1.2, 0.1, true)
	_petals.name = "HandlePetals"
	_petals.set_meta(&"keep_separate", true)
	_petals.position = HANDLE_BOTTOM - model_origin(arm_r)
	arm_r.add_child(_petals)
	# ---- Fx
	add_hit_burst(Vector3(0, 1.2, 0.05), Color(0.55, 0.42, 0.24), 7)
	add_death_bloom(Vector3(0, 1.0, 0.1), 0.3, 8, 10, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.42)


# ================================================================ meshes (cached per type, model space unless said)

## Hip -> knee (a little forward) -> ankle, one tapered bark limb; local to x = 0.
static func _leg_mesh() -> Mesh:
	return tapered_path_mesh("vinelasher_leg", PackedVector3Array([Vector3(0, 0.97, 0), Vector3(0, 0.53, 0.06),
		Vector3(0, 0.09, -0.01)]), PackedFloat32Array([0.085, 0.062, 0.05]))


## Shoulder -> elbow (out and back) -> wrist (forward), side +1 right / -1 left (no negative scale).
static func _arm_mesh(side: float) -> Mesh:
	return tapered_path_mesh("vinelasher_arm_%s" % side, PackedVector3Array([Vector3(0.29 * side, 1.39, 0.0),
		Vector3(0.34 * side, 1.10, -0.04), Vector3(0.35 * side, 0.85, 0.06)]), PackedFloat32Array([0.07, 0.057, 0.05]))


## Three team leaves fanned over the LEFT shoulder (the asymmetric counterweight of the coiled right arm).
static func _pauldron_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	xs.append(leaf_xform(Vector3(-0.22, 1.47, 0.02), Vector3(-1, 0, 0.35), Vector3(0.24, 0.06, 0.36), -30.0))
	xs.append(leaf_xform(Vector3(-0.22, 1.46, -0.03), Vector3(-1, 0, -0.45), Vector3(0.22, 0.06, 0.32), -22.0))
	xs.append(leaf_xform(Vector3(-0.20, 1.50, 0.0), Vector3(-1, 0, 0.0), Vector3(0.20, 0.06, 0.30), -8.0))
	return cluster_mesh("vinelasher_pauldron", leaf_mesh(), xs)


## Crown of 3 swept-back thorns + 2 short ear thorns (one mesh, model space).
static func _crown_mesh() -> Mesh:
	const KEY := "vinelasher_crown"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var cone := cyl(0.0, 1.0, 1.0, 6)
	var defs: Array = [   # base, dir, length, radius
		[Vector3(0, 1.77, 0.05), Vector3(0, 0.62, -0.78), 0.30, 0.05],
		[Vector3(-0.07, 1.75, 0.03), Vector3(-0.30, 0.55, -0.78), 0.24, 0.042],
		[Vector3(0.07, 1.75, 0.03), Vector3(0.30, 0.55, -0.78), 0.24, 0.042],
		[Vector3(-0.10, 1.66, 0.0), Vector3(-0.90, 0.30, -0.30), 0.16, 0.035],
		[Vector3(0.10, 1.66, 0.0), Vector3(0.90, 0.30, -0.30), 0.16, 0.035],
	]
	for d: Array in defs:
		var dir := (d[1] as Vector3).normalized()
		var h: float = d[2]
		var r: float = d[3]
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(r, h, r))
		st.append_from(cone, 0, Transform3D(b, (d[0] as Vector3) + dir * h * 0.45))
	return _cached(KEY, _indexed(st))


## The whip at rest (model space): from the handle bottom three wide loops climb the right forearm and upper arm,
## then the tail rises over the shoulder and curls forward; thorn spikes on the loops; the glowing tip bud by the head.
## Two surfaces: nature_thorn (whip + spikes: a light line, reads on the darker heath too) and nature_glow (tip).
static func _coil_mesh() -> Mesh:
	const KEY := "vinelasher_coil"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var a := Vector3(0.35, 0.70, 0.12)
	var b := Vector3(0.30, 1.34, -0.01)
	var ax := (b - a).normalized()
	var u := Vector3(0, 0, 1).cross(ax).normalized()
	var v := ax.cross(u)
	var pts := PackedVector3Array([HANDLE_BOTTOM])
	var radii := PackedFloat32Array([0.045])
	var spikes: Array[Transform3D] = []
	const N := 30
	const TURNS := 3.0
	for i: int in N + 1:
		var s := float(i) / float(N)
		var th := PI + s * TURNS * TAU
		var r: float = lerpf(0.13, 0.17, s)
		var out := u * cos(th) + v * sin(th)
		var p := a.lerp(b, s) + out * r
		pts.append(p)
		radii.append(0.045)
		if i % 6 == 2:
			var sd := (out + ax * 0.25).normalized()
			spikes.append(Transform3D(Basis(Quaternion(Vector3.UP, sd)).scaled_local(Vector3(0.03, 0.12, 0.03)),
				p + sd * 0.08))
	# tail over the shoulder, curling forward (the raised sting)
	var last := pts[pts.size() - 1]
	var tail: Array[Vector3] = [last + Vector3(-0.03, 0.12, -0.05), Vector3(0.22, 1.60, -0.14),
		Vector3(0.19, 1.74, -0.10), Vector3(0.21, 1.82, 0.0), Vector3(0.24, 1.82, 0.08)]
	var tr: Array[float] = [0.042, 0.038, 0.034, 0.030, 0.026]
	for i: int in tail.size():
		pts.append(tail[i])
		radii.append(tr[i])
	var vw := PackedVector3Array()
	var nw := PackedVector3Array()
	var iw := PackedInt32Array()
	_sweep(vw, nw, iw, pts, radii, 6)
	var cone := cyl(0.0, 1.0, 1.0, 5)
	for xf: Transform3D in spikes:
		_put(vw, nw, iw, cone, xf)
	var vg := PackedVector3Array()
	var ng := PackedVector3Array()
	var ig := PackedInt32Array()
	var tip_dir := (tail[4] - tail[3]).normalized()
	_put(vg, ng, ig, sphere(1.0, 8, 4), Transform3D(Basis(Quaternion(Vector3.UP, tip_dir)).scaled_local(
		Vector3(0.075, 0.1, 0.075)), tail[4] + tip_dir * 0.05))
	return _commit(KEY, [[vw, nw, iw, nature(&"nature_thorn")], [vg, ng, ig, nature(&"nature_glow")]])


## The unrolled whip in the handle's frame: LASH_LEN along local -Y (the arm's direction), a gentle wave in local Z
## (up when the arm points forward), the last 15 % curling toward -Z (the crack snapping down), thorn spikes on
## alternate sides, the glowing tip bud at the end. Two surfaces like the coil.
static func _lash_mesh() -> Mesh:
	const KEY := "vinelasher_lash"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	const N := 16
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var spikes: Array[Transform3D] = []
	for i: int in N + 1:
		var s := float(i) / float(N)
		var z: float = 0.10 * sin(PI * s * 1.5)
		if s > 0.85:
			z -= 0.25 * (s - 0.85) / 0.15
		pts.append(Vector3(0, -LASH_LEN * s, z))
		radii.append(lerpf(0.06, 0.034, s))
		if i % 2 == 1 and i < N:
			var side: float = 1.0 if ((i >> 1) & 1) == 0 else -1.0
			var sd := Vector3(side, 0.35, 0.35).normalized()
			spikes.append(Transform3D(Basis(Quaternion(Vector3.UP, sd)).scaled_local(Vector3(0.02, 0.09, 0.02)),
				pts[i] + sd * 0.05))
	var vw := PackedVector3Array()
	var nw := PackedVector3Array()
	var iw := PackedInt32Array()
	_sweep(vw, nw, iw, pts, radii, 6)
	var cone := cyl(0.0, 1.0, 1.0, 5)
	for xf: Transform3D in spikes:
		_put(vw, nw, iw, cone, xf)
	var vg := PackedVector3Array()
	var ng := PackedVector3Array()
	var ig := PackedInt32Array()
	var tip_dir := (pts[N] - pts[N - 1]).normalized()
	_put(vg, ng, ig, sphere(1.0, 8, 4), Transform3D(Basis(Quaternion(Vector3.UP, tip_dir)).scaled_local(
		Vector3(0.08, 0.11, 0.08)), pts[N] + tip_dir * 0.05))
	return _commit(KEY, [[vw, nw, iw, nature(&"nature_thorn")], [vg, ng, ig, nature(&"nature_glow")]])


## Six pink petals opening around the handle's end (local frame at the handle bottom, a cup facing down the whip).
static func _bloom_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	for i: int in 6:
		var ang := TAU * float(i) / 6.0
		var out := Vector3(sin(ang), 0, cos(ang))
		var xf := leaf_xform(out * 0.03, out, Vector3(0.13, 0.03, 0.2), -35.0)
		xs.append(xf)
	return cluster_mesh("vinelasher_bloom", leaf_mesh(), xs)


## Appends a smooth swept tube (seg sides, parallel-transport frames, no caps) through pts / radii.
static func _sweep(v: PackedVector3Array, n: PackedVector3Array, ix: PackedInt32Array, pts: PackedVector3Array,
		radii: PackedFloat32Array, seg: int) -> void:
	var cnt := pts.size()
	var t0 := (pts[1] - pts[0]).normalized()
	var ref := Vector3.UP if absf(t0.y) < 0.9 else Vector3.RIGHT
	var nrm := t0.cross(ref).normalized()
	var base := v.size()
	for i: int in cnt:
		var t := (pts[mini(i + 1, cnt - 1)] - pts[maxi(i - 1, 0)]).normalized()
		nrm = (nrm - t * nrm.dot(t)).normalized()
		var bn := t.cross(nrm)
		for k: int in seg:
			var ang := TAU * float(k) / float(seg)
			var dir := nrm * cos(ang) + bn * sin(ang)
			v.append(pts[i] + dir * radii[i])
			n.append(dir)
	for i: int in cnt - 1:
		for k: int in seg:
			var a0: int = base + i * seg + k
			var a1: int = base + i * seg + (k + 1) % seg
			ix.append_array(PackedInt32Array([a0, a0 + seg, a1, a1, a0 + seg, a1 + seg]))


## Appends surface 0 of a primitive mesh, transformed (no negative scale).
static func _put(v: PackedVector3Array, n: PackedVector3Array, ix: PackedInt32Array, mesh: Mesh, xf: Transform3D) -> void:
	var arr := mesh.surface_get_arrays(0)
	var mv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var mn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var nb := xf.basis.inverse().transposed()
	var b0 := v.size()
	for j: int in mv.size():
		v.append(xf * mv[j])
		n.append((nb * mn[j]).normalized())
	if arr[Mesh.ARRAY_INDEX] == null:
		for j: int in mv.size():
			ix.append(b0 + j)
	else:
		for j: int in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array):
			ix.append(b0 + j)


## One ArrayMesh with a surface per [verts, normals, indices, material] entry (materials on the mesh, shared).
static func _commit(key: String, surfs: Array) -> Mesh:
	var am := ArrayMesh.new()
	for s: Array in surfs:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_INDEX] = s[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, s[3])
	return _cached(key, am)


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"whip_lash":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, W_ARM_R) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, W_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, W_CHEST_X) * DEG, _kf(t, W_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, W_ROOT_Z)))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_kf(t, W_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, W_LEG_R) * DEG, 0, 0))
	if prev < 0.24 and t >= 0.24:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Snare Lash: a low forward lash, the tip wraps down around the target, then a hard yank back.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(_kf(t, S_ARM_R) * DEG, 0, -12.0 * DEG * _k3(t, 0.0, 0.2, 0.5, 0.8, 1.0, 1.0)))
	rot(P_ARM_L, Vector3(-30.0 * DEG * _k3(t, 0.0, 0.2, 0.55, 0.9, 1.0, 1.0), 0, 0))
	rot(P_CHEST, Vector3(_kf(t, S_CHEST_X) * DEG, _kf(t, S_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, -0.06 * _k3(t, 0.1, 0.3, 0.5, 0.7, 1.0, 1.0), _kf(t, S_ROOT_Z)))
	if _snare_prev < 0.62 and t >= 0.62:
		_restart_petals()
	_snare_prev = t
	return CAST_LEN


## Stalking walk: a slight forward lean, the whip arm held tight (small swing), head steady.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	rot(P_ROOT, Vector3(5.0 * DEG * w, 0, 0))
	rot(P_ARM_R, Vector3(-8.0 * DEG * sin(TAU * _walk_p) * w - 6.0 * DEG * w, 0, 0))


## Fidget: lifts the coiled arm, flexes it and looks the coil over, head cocked.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.35, 1.1, 1.6, 1.0, 1.0)
	var flex: float = 0.0
	if t > 0.35 and t < 1.1:
		flex = sin((t - 0.35) * TAU * 1.33)
	rot(P_ARM_R, Vector3(-55.0 * DEG * up, 18.0 * DEG * flex * up, 0))
	rot(P_CHEST, Vector3(0, 10.0 * DEG * up, 0))
	rot(P_HEAD, Vector3(10.0 * DEG * up, 25.0 * DEG * up, 8.0 * DEG * up))
	return 1.6


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_snare_prev = 0.0
	elif ev == &"release":
		_restart_petals()


func _restart_petals() -> void:
	if _petals and _tier <= 1:
		_petals.restart()


func _war_process(_dt: float) -> void:
	var on := false
	var ext: float = 0.15
	var flick: float = 0.0
	var bloom: float = 0.0
	if not _dead:
		var t := _action_t
		if _action == &"attack" and attack_style == &"whip_lash":
			on = t >= 0.04 and t < 0.68
			ext = _kf(t, W_EXT)
			flick = _kf(t, W_FLICK)
			bloom = _kf(t, W_BLOOM)
		elif _action == &"cast":
			on = t >= 0.05 and t < 0.76
			ext = _kf(t, S_EXT)
			flick = _kf(t, S_FLICK)
			bloom = _kf(t, S_BLOOM)
	_set_whip(on, ext, flick, bloom)


func _war_revive() -> void:
	_set_whip(false, 0.15, 0.0, 0.0)


## Coil at rest, lash while it is out (no allocation: transforms and visibility only).
func _set_whip(on: bool, ext: float, flick_deg: float, bloom: float) -> void:
	if on:
		_lash.transform = Transform3D(Basis(Vector3.RIGHT, flick_deg * DEG).scaled_local(Vector3(1.0, ext, 1.0)),
			_lash_pos)
	if on != _lash_on:
		_lash_on = on
		_lash.visible = on
		_coil.visible = not on
	if bloom != _bloom_v:
		_bloom_v = bloom
		_bloom.visible = bloom > 0.01
		if _bloom.visible:
			_bloom.scale = Vector3.ONE * bloom
