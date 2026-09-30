extends "res://art/units/mounts/dusk_steed/dusk_steed.gd"
## Barrow Steed: the Barrow Knight's horse (stables.md 2, Shadow C, the tier-2 line breaker; rank-3 "Barrow Dreadlord").
## The shared 13.V3 Dusk Steed (anatomy, gait, charge, fidget, violet dissolve death, glowing eyes, tattered team
## caparison) ALWAYS in its tarnished-silver barding (chanfron, crinet, peytral), dressed as a grave-knight's mount, all
## merged into the Dusk Steed's own pivots (0 extra draw instances; own type key = own caches):
##  - a BONE SKULL MASK over the chanfron's brow with dark eye holes burning violet (the mount's glow point: the barding
##    covers the steed's own eyes) and two short bone horns sweeping back (the mount's read from the RTS camera);
##  - a long tattered team SHROUD hanging below the caparison skirts on both flanks down to the hocks (team cloth, a dark
##    band, a ragged hem) with a bone crescent moon on each side;
##  - a rattle of three small bone charms on cords from the saddle's cantle.
## Scene: parts/barrow_steed.tscn (the Dusk Steed's pivots, a heavier gait).

## Shroud: model z range, columns, its top (tucked under the caparison skirts), its drop.
const SHROUD_Z0 := -0.24
const SHROUD_Z1 := 0.36
const SHROUD_COLS := 8
const SHROUD_TOP := 1.10
const SHROUD_DROP := 0.40


func _build_mount() -> void:
	_barded = true   # the grave-knight's horse always wears the tarnished-silver barding
	super()
	add_sculpt($Root/Mount, _shroud_sculpt)
	add_sculpt($Root/Mount/Head, _skull_sculpt)


## Lateral half width of the barrel at model z (the Dusk Steed's profile).
static func _half_w(z: float) -> float:
	var zl := z - BC.z
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## One side's shroud (sx -1 / +1): part 0 = the team cloth, 1 = the dark band, 2 = the ragged team hem.
static func _shroud_mesh(sx: float, part: int) -> Mesh:
	var key := "barrow_shroud_%s_%d_v1" % [sx, part]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = [[], [], [], []]
	var nh := Vector3(sx, -0.04, 0.0).normalized()
	for i: int in SHROUD_COLS + 1:
		var z := lerpf(SHROUD_Z0, SHROUD_Z1, float(i) / float(SHROUD_COLS))
		var x: float = (maxf(_half_w(z), 0.24) + 0.06) * sx
		var top := Vector3(x, SHROUD_TOP, z)
		var tip: bool = i % 2 == 1
		var rnd: float = fposmod(sin(float(i) * 9.13 + sx * 1.7) * 43758.5453, 1.0)
		(rows[0] as Array).append(top)
		(rows[1] as Array).append(top + Vector3(0.03 * sx, -SHROUD_DROP * 0.70, 0))
		(rows[2] as Array).append(top + Vector3(0.035 * sx, -SHROUD_DROP * 0.80, 0))
		(rows[3] as Array).append(top + Vector3(0.045 * sx, -SHROUD_DROP - (0.13 * (0.6 + 0.8 * rnd) if tip else 0.02 * rnd),
			-0.05 if tip else 0.0))
	var pr: Array = [[0, 1], [1, 2], [2, 3]][part]
	var ra: Array = rows[pr[0]]
	var rb: Array = rows[pr[1]]
	for i: int in SHROUD_COLS:
		var j := i + 1
		var t := 0.014
		var a0: Vector3 = ra[i]
		var a1: Vector3 = ra[j]
		var b0: Vector3 = rb[i]
		var b1: Vector3 = rb[j]
		_emit(st, a0, a1, b1, nh, nh, nh)
		_emit(st, a0, b1, b0, nh, nh, nh)
		_emit(st, a0 - nh * t, b1 - nh * t, a1 - nh * t, -nh, -nh, -nh)
		_emit(st, a0 - nh * t, b0 - nh * t, b1 - nh * t, -nh, -nh, -nh)
	st.index()
	return _cached(key, st.commit())


func _shroud_sculpt(s: Dictionary) -> void:
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var bone := m("shadow_bone")
	var leather := m("shadow_leather")
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, _shroud_mesh(sx, 0), Transform3D.IDENTITY, cloth)
		sculpt_add(s, _shroud_mesh(sx, 1), Transform3D.IDENTITY, cdark)
		sculpt_add(s, _shroud_mesh(sx, 2), Transform3D.IDENTITY, cloth)
		# the bone crescent moon on the shroud: a bone disc bitten by a dark one
		var c := Vector3((maxf(_half_w(-0.02), 0.24) + 0.10) * sx, SHROUD_TOP - 0.17, -0.02)
		var fb := frame(c, Vector3(sx, 0, 0), Vector3.UP).basis
		sculpt_add(s, cyl(0.085, 0.085, 0.02, 10), Transform3D(fb, c), bone)
		sculpt_add(s, cyl(0.07, 0.07, 0.022, 8), Transform3D(fb, c + Vector3(0.004 * sx, 0.035, 0.03)), cdark)
		# bone charms on cords hanging from the cantle
		for k: int in 2:
			var cp := Vector3(0.12 * sx, 1.60 - 0.02 * float(k), -0.24 - 0.05 * float(k))
			sculpt_add(s, cyl(0.006, 0.006, 0.20, 3), Transform3D(Basis.IDENTITY, cp + Vector3(0, -0.10, 0)), leather)
			sculpt_put(s, sphere(0.035, 6, 3), bone, cp + Vector3(0, -0.22, 0), Vector3.ZERO, Vector3(0.8, 1.2, 0.8))


## The bone skull mask over the barding's chanfron: a flattened bone skull, dark eye holes, a jaw ridge, two short horns
## sweeping back past the ears.
func _skull_sculpt(s: Dictionary) -> void:
	var bone := m("shadow_bone")
	var dark := m("unit_eye_dark")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	var c := SK_B + sd * 0.26 + up * 0.155
	sculpt_add(s, sphere(0.11, 8, 4), Transform3D(Basis(sf.basis.x * 0.95, sf.basis.y * 1.45, sf.basis.z * 0.45), c), bone)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, sphere(0.03, 6, 3), Transform3D(Basis(sf.basis.x, sf.basis.y * 1.2, sf.basis.z * 0.5),
			c + sd * -0.03 + up * 0.035 + Vector3(0.045 * sx, 0, 0)), dark)
		# a violet ember burning in each eye hole (the mount's glow point: the barding hides the steed's own eyes)
		sculpt_add(s, sphere(0.03, 6, 3), Transform3D(Basis.IDENTITY, c + sd * -0.03 + up * 0.055 + Vector3(0.045 * sx, 0, 0)),
			m("shadow_glow_hero"))
		var hr := c + sd * -0.10 + up * 0.03 + Vector3(0.07 * sx, 0, 0)
		sculpt_add(s, tube_mesh("barrow_horn_%s_v1" % sx, PackedVector3Array([hr, hr + Vector3(0.08 * sx, 0.06, -0.08),
			hr + Vector3(0.10 * sx, 0.14, -0.20)]), PackedFloat32Array([0.035, 0.022, 0.0]), 5), Transform3D.IDENTITY, bone)
	sculpt_add(s, cyl(0.012, 0.012, 0.13, 4), Transform3D(frame(Vector3.ZERO, sd, up).basis, c + sd * 0.12 + up * 0.01), dark)
