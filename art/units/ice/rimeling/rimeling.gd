extends IceModel
## Rimeling, Ice T1 rush unit (new-units-12.md 6, rush-balance.md 5.4; tiers wave, medium). Height 1.05, radius 0.4.
## A squat frost goblin: a big head with a long nose, bat ears and two pale tusks in a team hood whose floppy tip
## falls to the left, a pale fur mantle, a pot belly in team cloth over a dark fur kilt, two ICICLE SHIVS held low
## (the right one longer), 3 icicle trophies at the left hip and a frozen crystal hump on the back (asymmetry).
## One glow point: the eye slit. Frost-breath puffs every ~2.6 s.
## Attack `dual_slash` (kit): the two shivs slash one after the other. play_cast(&"frostbite") 0.6 s: both shivs
## raised overhead, crossed, stabbed down, a breath puff. Fidget: scrapes the shivs together. Death: freezes, shatters.

const CAST_LEN := 0.6
const FIST_L := Vector3(-0.31, 0.47, 0.10)
const FIST_R := Vector3(0.31, 0.47, 0.10)
const SH_L := Vector3(-0.25, 0.72, 0.0)
const SH_R := Vector3(0.25, 0.72, 0.0)

var _puffed: bool = false


func _build_parts() -> void:
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := ice(&"ice_cloth")
	var cdark := ice(&"ice_cloth_dark")
	var skin := ice(&"ice_skin")
	var leather := ice(&"ice_leather")
	var fur := ice(&"ice_fur")
	var pale := ice(&"ice_fur_pale")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	# ---- Legs: short bowed fur legs, pale fur cuffs, big leather feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _path("rml_leg_%s" % sx, PackedVector3Array([Vector3(0.11 * sx, 0.42, 0), Vector3(0.14 * sx, 0.24, 0.04),
			Vector3(0.12 * sx, 0.08, 0.0)]), PackedFloat32Array([0.08, 0.068, 0.058]), 8), fur, Vector3.ZERO)
		add_part(leg, cyl(0.085, 0.078, 0.06, 8), pale, Vector3(0.125 * sx, 0.15, 0.01))
		add_part(leg, sphere(0.08, 8, 4), leather, Vector3(0.125 * sx, 0.05, 0.07), Vector3.ZERO, Vector3(1.0, 0.6, 1.55))
	# ---- Chest: pot belly (team), dark fur kilt, leather belt + pouch, pale fur mantle, icicle trophies at the left
	# hip, frozen crystal hump on the back.
	add_part(chest, sphere(0.24, 10, 6), cloth, Vector3(0, 0.61, 0.03), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	add_part(chest, cyl(0.21, 0.26, 0.15, 10, false), fur, Vector3(0, 0.45, 0.0))
	add_part(chest, cyl(0.235, 0.235, 0.055, 10), leather, Vector3(0, 0.52, 0.02))
	add_part(chest, box(Vector3(0.11, 0.12, 0.08)), leather, Vector3(0.20, 0.46, 0.14), Vector3(0, -30, 0))
	add_part(chest, cyl(0.12, 0.27, 0.13, 10), pale, Vector3(0, 0.77, -0.01))
	add_part(chest, box(Vector3(0.14, 0.26, 0.04)), cdark, Vector3(0, 0.60, 0.25), Vector3(-10, 0, 0))
	# value breaks on the belly: a leather baldric strap, an iron buckle, a dark fur patch on the right flank
	add_part(chest, box(Vector3(0.06, 0.50, 0.04)), leather, Vector3(0.02, 0.64, 0.225), Vector3(-12, 0, -38))
	add_part(chest, box(Vector3(0.07, 0.06, 0.03)), ice(&"ice_steel"), Vector3(0, 0.52, 0.26))
	add_part(chest, sphere(0.10, 8, 4), fur, Vector3(0.17, 0.60, 0.12), Vector3.ZERO, Vector3(0.6, 1.0, 0.8))
	for i: int in 3:
		add_crystal(chest, Vector3(-0.19 - 0.035 * i, 0.50, 0.10 - 0.05 * i), Vector3(0.1 * (i - 1), -1.0, 0.1), 0.028,
			0.13 + 0.03 * i, frost, 0.6)
	add_crystal(chest, Vector3(0.07, 0.70, -0.20), Vector3(0.25, 1.0, -0.9), 0.055, 0.22, frost, 0.5)
	add_crystal(chest, Vector3(-0.06, 0.66, -0.22), Vector3(-0.3, 0.7, -1.0), 0.045, 0.17, frost, 0.5)
	add_crystal(chest, Vector3(0.0, 0.58, -0.24), Vector3(0.05, 0.4, -1.0), 0.04, 0.13, frost, 0.5)
	# ---- Head: big goblin head, long nose, bat ears, tusks, team hood with a floppy tip (left), fur rim, eye slit.
	add_part(head, sphere(0.19, 10, 6), skin, Vector3(0, 0.90, 0.05), Vector3.ZERO, Vector3(1.15, 0.95, 1.0))
	add_part(head, cyl(0.0, 0.05, 0.17, 6), skin, Vector3(0, 0.87, 0.28), Vector3(80, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(head, cyl(0.0, 0.065, 0.28, 6), skin, Vector3(0.26 * s, 0.95, -0.02), Vector3(-10, 0, -72.0 * s),
			Vector3(1.0, 1.0, 0.45))
		add_part(head, cyl(0.0, 0.022, 0.07, 5), pale, Vector3(0.055 * s, 0.82, 0.19), Vector3(-15, 0, 10.0 * s))
	add_part(head, sphere(0.235, 10, 6), cloth, Vector3(0, 0.96, -0.08), Vector3.ZERO, Vector3(1.05, 1.0, 1.05))
	var tip_rot := Vector3(-55, 0, 24)
	var tip_c := Vector3(-0.07, 1.12, -0.24)
	add_part(head, cyl(0.0, 0.125, 0.34, 7), cloth, tip_c, tip_rot)
	add_part(head, sphere(0.055, 7, 4), pale, tip_c + Basis.from_euler(tip_rot * DEG) * Vector3(0, 0.17, 0))
	add_part(head, torus(0.13, 0.195, 12), pale, Vector3(0, 0.93, 0.13), Vector3(78, 0, 0))
	add_part(head, box(Vector3(0.19, 0.045, 0.04)), glow, Vector3(0, 0.935, 0.225))
	var trim := add_part(head, torus(0.17, 0.21, 12), palette(&"unit_gold_trim"), Vector3(0, 1.07, -0.06),
		Vector3(-8, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: dark fur sleeves, pale fur shoulder tufts, leather mitts, the two icicle shivs (held low, forward).
	add_limb(arm_l, SH_L, FIST_L, 0.058, fur, 0.07, leather)
	add_limb(arm_r, SH_R, FIST_R, 0.058, fur, 0.07, leather)
	add_part(arm_l, sphere(0.085, 8, 4), pale, SH_L + Vector3(-0.02, 0.01, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(arm_r, sphere(0.085, 8, 4), pale, SH_R + Vector3(0.02, 0.01, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(arm_l, cyl(0.05, 0.05, 0.07, 6), leather, FIST_L + Vector3(0, -0.02, 0.06), Vector3(70, 0, 0))
	add_part(arm_r, cyl(0.05, 0.05, 0.07, 6), leather, FIST_R + Vector3(0, -0.02, 0.06), Vector3(70, 0, 0))
	add_crystal(arm_l, FIST_L + Vector3(0, -0.03, 0.08), Vector3(0.05, -0.35, 1.0), 0.042, 0.34, frost, 0.5)
	add_crystal(arm_r, FIST_R + Vector3(0, -0.03, 0.08), Vector3(-0.05, -0.30, 1.0), 0.048, 0.44, frost, 0.5)
	# ---- Fx: breath, hit chips, shatter, cool blob.
	add_breath(Vector3(0, 0.86, 0.33), 0.16)
	add_hit_chips(Vector3(0, 0.65, 0.1), 5)
	add_shatter(Vector3(0, 0.55, 0), 10, 0.25, 0.08)
	ensure_shadow_blob(0.36, BLOB_TINT)


## Tapered tube through `pts` (model space), cached by key.
static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var len_total := d.length() + 0.02
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))
	st.index()
	return _cached(key, st.commit())


# ================================================================ motion

## Frostbite: both shivs raised overhead and crossed, then stabbed down in front with a breath puff.
func _pose_cast(_spell: StringName, t: float) -> float:
	var a := _k3(t, 0.0, 0.22, 0.32, CAST_LEN, -150.0, -40.0)
	rot(P_ARM_L, Vector3(a * DEG, 0, _k3(t, 0.0, 0.22, 0.32, CAST_LEN, -18.0, -10.0) * DEG))
	rot(P_ARM_R, Vector3(a * DEG, 0, _k3(t, 0.0, 0.22, 0.32, CAST_LEN, 18.0, 10.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.22, 0.32, CAST_LEN, -12.0, 20.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.2, 0.32, CAST_LEN, 0.08, -0.05), _k3(t, 0.2, 0.32, 0.35, CAST_LEN, 0.15, 0.15)))
	if t >= 0.3 and not _puffed:
		_puffed = true
		puff_breath()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_puffed = false


func _ice_process(_dt: float) -> void:
	# Goblin scurry: a forward hunch and a wider arm pump on the walk.
	if _walk_w > 0.0 and not _dead:
		rot(P_CHEST, Vector3(10.0 * DEG * _walk_w, 0, 0))
		rot(P_ARM_L, Vector3(-10.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))
		rot(P_ARM_R, Vector3(14.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))


## Fidget: scrapes the two shivs together in front of the belly, grinning up.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.25, 0.9, 1.2, 1.0, 1.0)
	var s: float = sin(t * 18.0) * k
	rot(P_ARM_L, Vector3((-45.0 + 8.0 * s) * DEG * k, 0, -22.0 * DEG * k))
	rot(P_ARM_R, Vector3((-45.0 - 8.0 * s) * DEG * k, 0, 22.0 * DEG * k))
	rot(P_HEAD, Vector3(-10.0 * DEG * k, 0, 0))
	return 1.2
