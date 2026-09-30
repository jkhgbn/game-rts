extends "res://art/units/mounts/dusk_steed/dusk_steed.gd"
## Veil Steed: the Veilborn Dreadrider's horse (stables.md 2, Shadow V, the tier-3 elite, the army's anchor). The shared
## 13.V3 Dusk Steed (anatomy, gait, charge, fidget, violet dissolve death, glowing eyes, tattered team caparison) ALWAYS in
## its tarnished-silver barding, dressed as a dread knight's nightmare, all merged into the Dusk Steed's own pivots (0 extra
## draw instances; own type key = own caches):
##  - two long OBSIDIAN HORNS rising forward from the chanfron's brow (the mount's read from the RTS camera), an obsidian
##    ridge of short spikes down the crinet;
##  - the VEIL: a long team caparison hanging from under the skirts almost to the fetlocks on both flanks, its ragged hem
##    trailing back (a dark under-layer showing below), a silver rune-eye on each side;
##  - smoke at the hooves: a crown of dark smoke tongues (violet rim) round every fetlock, lagging back.
## Scene: parts/veil_steed.tscn (the Dusk Steed's pivots, a long heavy stride).

const VEIL_Z0 := -0.26
const VEIL_Z1 := 0.38
const VEIL_COLS := 8
const VEIL_TOP := 1.10
const VEIL_DROP := 0.62


func _build_mount() -> void:
	_barded = true   # the dread knight's horse always wears the tarnished-silver barding
	super()
	add_sculpt($Root/Mount, _veil_sculpt)
	add_sculpt($Root/Mount/Head, _horn_sculpt)
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _hoof_smoke(s, p))


static func _half_w(z: float) -> float:
	var zl := z - BC.z
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## One side's veil (sx -1 / +1): part 0 = the team cloth, 1 = the dark under-layer showing below its ragged hem. The hem
## trails back (lower rows further back): the veil streams even at rest.
static func _veil_mesh(sx: float, part: int) -> Mesh:
	var key := "veil_caparison_%s_%d_v1" % [sx, part]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = [[], [], []]
	var nh := Vector3(sx, -0.03, 0.0).normalized()
	var drop: float = VEIL_DROP if part == 0 else VEIL_DROP + 0.10
	var inset: float = 0.0 if part == 0 else -0.012
	for i: int in VEIL_COLS + 1:
		var z := lerpf(VEIL_Z0, VEIL_Z1, float(i) / float(VEIL_COLS))
		var x: float = (maxf(_half_w(z), 0.24) + 0.07 + inset) * sx
		var top := Vector3(x, VEIL_TOP, z)
		var tip: bool = i % 2 == (1 if part == 0 else 0)
		var rnd: float = fposmod(sin(float(i) * 4.71 + sx * 2.3 + float(part)) * 43758.5453, 1.0)
		(rows[0] as Array).append(top)
		(rows[1] as Array).append(top + Vector3(0.05 * sx, -drop * 0.6, -0.08))
		(rows[2] as Array).append(top + Vector3(0.07 * sx, -drop - (0.16 * (0.6 + 0.8 * rnd) if tip else 0.03 * rnd),
			-0.18 - (0.06 if tip else 0.0)))
	for r: int in 2:
		var ra: Array = rows[r]
		var rb: Array = rows[r + 1]
		for i: int in VEIL_COLS:
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


func _veil_sculpt(s: Dictionary) -> void:
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var obs := m("shadow_obsidian")
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, _veil_mesh(sx, 1), Transform3D.IDENTITY, cdark)
		sculpt_add(s, _veil_mesh(sx, 0), Transform3D.IDENTITY, cloth)
		# a silver rune-eye on the veil: a silver almond, an obsidian pupil
		var c := Vector3((maxf(_half_w(0.06), 0.24) + 0.105) * sx, VEIL_TOP - 0.22, 0.02)
		var fb := frame(c, Vector3(sx, 0, 0), Vector3.UP).basis
		sculpt_add(s, cyl(0.10, 0.10, 0.02, 8), Transform3D(fb * Basis.from_scale(Vector3(1.0, 1.0, 0.5)), c), sil)
		sculpt_add(s, cyl(0.035, 0.035, 0.026, 6), Transform3D(fb, c + Vector3(0.004 * sx, 0, 0)), obs)
	# an obsidian ridge of short spikes along the crest of the croup behind the saddle
	for k: int in 3:
		var z := -0.36 - 0.12 * float(k)
		var dz: float = (z - CROUP_C.z) / CROUP_R.z
		var y: float = CROUP_C.y + CROUP_R.y * sqrt(maxf(1.0 - dz * dz, 0.0)) - 0.02
		sculpt_add(s, cyl(0.0, 0.04, 0.16 - 0.03 * float(k), 4), Transform3D(frame(Vector3.ZERO, Vector3(0, 1.0, -0.5),
			Vector3.RIGHT).basis, Vector3(0, y + 0.06, z)), obs)


## Two long obsidian horns rising forward from the chanfron's brow, curving up and out.
func _horn_sculpt(s: Dictionary) -> void:
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	for sx: float in [-1.0, 1.0]:
		var b := SK_B + sd * 0.10 + up * 0.14 + Vector3(0.06 * sx, 0, 0)
		sculpt_add(s, tube_mesh("veil_horn_%s_v1" % sx, PackedVector3Array([b, b + up * 0.12 + sd * 0.05 + Vector3(0.04 * sx, 0, 0),
			b + up * 0.24 + sd * 0.16 + Vector3(0.07 * sx, 0, 0), b + up * 0.30 + sd * 0.32 + Vector3(0.06 * sx, 0, 0)]),
			PackedFloat32Array([0.04, 0.032, 0.02, 0.0]), 5), Transform3D.IDENTITY, obs)
		sculpt_add(s, cyl(0.045, 0.045, 0.025, 6, false), Transform3D(frame(Vector3.ZERO, up, sd).basis, b + up * 0.02), sil)


## Smoke round the fetlock: four dark smoke tongues (violet rim) leaning back, pale wisp tips.
func _hoof_smoke(s: Dictionary, p: Vector3) -> void:
	var smoke := m("dusk_smoke")
	var wisp := m("dusk_wisp")
	var front: bool = p.z > 0.0
	var c := Vector3(p.x, 0.10, p.z + (0.03 if front else -0.06))
	for k: int in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		var out := Vector3(sin(a), 0.0, cos(a))
		var dir := (Vector3.UP * 0.8 + out * 0.5 + Vector3(0, 0, -0.6)).normalized()
		_tongue(s, smoke if k % 2 == 0 else wisp, c + out * 0.06, dir, Vector3.RIGHT, 0.05, 0.18 if k % 2 == 0 else 0.14, 0.5)
