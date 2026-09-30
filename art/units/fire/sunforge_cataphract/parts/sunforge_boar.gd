extends "res://art/units/mounts/ember_boar/ember_boar.gd"
## Sunforge Boar: the Sunforge Cataphract's war boar (stables.md 2, Fire V, the tier-3 anchor). The shared 13.V2 Ember
## Boar (anatomy, gait, charge, fidget, death, eyes) clad as a cataphract mount, everything merged into its own pivots
## (0 extra draw instances; own type key = own caches):
##  - GILDED barding (materials/sunforge_gold, the deep sun-gold; bright unit_gold_trim for the rays): one big plate over
##    each shoulder with a dark leather rim and a team cloth skirt below it, a gilded chanfron down the skull with a ridge,
##    a gilded peytral; the fore knees in gilded cops;
##  - a standing SUN DISC crest on the brow between the ears (a gold disc, a team heart, a ring of short rays): the mount's
##    read from the RTS camera, the rider's halo echoes it;
##  - the team caparison of the Ember Boar plus a long quilted team trapper on both flanks (dark quilting band, flame-cut
##    hem, a gold roundel) and long team crupper drapes with a gold trim over both haunches (the rump flames stay free).
## The Ember Boar's own bronze barding stays available through set_barded (not used by the unit).
## Scene: parts/sunforge_boar.tscn (the Ember Boar's pivots, a heavier gait tuning).

const GOLD_MAT := "res://art/units/fire/sunforge_cataphract/materials/sunforge_gold.tres"
const SKIRT_Z0 := -0.24
const SKIRT_Z1 := 0.14
const SKIRT_COLS := 6
const SKIRT_DROP := 0.30
const SKIRT_A := 98.0


func _build_mount() -> void:
	super()
	var body: Node3D = $Root/Mount
	add_sculpt(body, _gold_body)
	add_sculpt($Root/Mount/Head, _gold_head)
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR]:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _gold_knee(s, p))


# ================================================================ body: gilded plates, trapper, crupper, peytral

## The team trapper under the caparison drape (see the Pyrehoof Boar): part 0 = team cloth, 1 = the dark quilting band,
## 2 = the flame-cut team hem.
static func _skirt_mesh(sx: float, part: int) -> Mesh:
	var key := "sunforge_trapper_%s_%d_v1" % [sx, part]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = [[], [], [], []]
	var nh := Vector3(sx, -0.05, 0.0).normalized()
	for i: int in SKIRT_COLS + 1:
		var z := lerpf(SKIRT_Z0, SKIRT_Z1, float(i) / float(SKIRT_COLS))
		var e := _bp(z, SKIRT_A * sx, 0.03)
		var top: Vector3 = e[0]
		var tip: bool = i % 2 == 1
		var rnd: float = fposmod(sin(float(i) * 5.17 + sx * 3.3) * 43758.5453, 1.0)
		(rows[0] as Array).append(top)
		(rows[1] as Array).append(top + Vector3(0.03 * sx, -SKIRT_DROP * 0.68, 0))
		(rows[2] as Array).append(top + Vector3(0.04 * sx, -SKIRT_DROP * 0.83, 0))
		(rows[3] as Array).append(top + Vector3(0.05 * sx, -SKIRT_DROP - (0.10 * (0.8 + 0.4 * rnd) if tip else 0.0),
			-0.04 if tip else 0.0))
	var pr: Array = [[0, 1], [1, 2], [2, 3]][part]
	var ra: Array = rows[pr[0]]
	var rb: Array = rows[pr[1]]
	for i: int in SKIRT_COLS:
		var j := i + 1
		var t := 0.016
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


func _gold_body(s: Dictionary) -> void:
	var gold := material_at(GOLD_MAT)
	var leather := m("fire_leather")
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var at := Transform3D(Basis.IDENTITY, BC)
	for sx: float in [-1.0, 1.0]:
		# one big gilded plate over the shoulder with a dark leather rim along its lower edge (the haunch wears the team crupper)
		for pl: Array in [[0.18, 0.66, 56.0, 108.0, 0.075, "sh"]]:
			var z0: float = pl[0]
			var z1: float = pl[1]
			var a0: float = pl[2]
			var a1: float = pl[3]
			var off: float = pl[4]
			var l0: float = z0 - BC.z
			var l1: float = z1 - BC.z
			var rx0: float = _barrel_r(l0) * LX + off
			var ry0: float = _barrel_r(l0) * SY + off
			var tap: float = (_barrel_r(l1) * LX + off) / maxf(rx0, 0.05)
			var key := "sunforge_%s_%s_v1" % [pl[5], sx]
			sculpt_add(s, shell_mesh(key, rx0, ry0, minf(a0 * sx, a1 * sx), maxf(a0 * sx, a1 * sx), l0, l1, 0.03, 5, 2, tap,
				0.04), at, gold)
			var e0: float = (a1 - 4.0) * sx
			var e1: float = (a1 + 2.0) * sx
			sculpt_add(s, shell_mesh(key + "_rim", rx0 + 0.012, ry0 + 0.012, minf(e0, e1), maxf(e0, e1), l0 - 0.005, l1 + 0.005,
				0.045, 1, 1, tap, 0.0), at, leather)
			# a team cloth skirt hanging below the plate
			var k0: float = (a1 - 2.0) * sx
			var k1: float = (a1 + 26.0) * sx
			sculpt_add(s, shell_mesh(key + "_skirt", rx0 - 0.01, ry0 - 0.01, minf(k0, k1), maxf(k0, k1), l0 + 0.02, l1 - 0.02, 0.02, 4,
				1, tap, 0.0), at, cloth)
		# the trapper and its gold roundel
		sculpt_add(s, _skirt_mesh(sx, 0), Transform3D.IDENTITY, cloth)
		sculpt_add(s, _skirt_mesh(sx, 1), Transform3D.IDENTITY, cdark)
		sculpt_add(s, _skirt_mesh(sx, 2), Transform3D.IDENTITY, cloth)
		var rc := _bp(-0.05, SKIRT_A * sx, 0.03)
		var c: Vector3 = (rc[0] as Vector3) + Vector3(0.028 * sx, -0.11, 0)
		var n := Vector3(sx, -0.05, 0).normalized()
		sculpt_add(s, cyl(0.075, 0.075, 0.022, 10), Transform3D(frame(c, n, Vector3.UP).basis, c), m("unit_gold_trim"))
		# the crupper drape over the haunch (a band round the rump's vertical axis; the spine flames stay free)
		var c0: float = 45.0 if sx > 0.0 else -160.0
		var c1: float = 160.0 if sx > 0.0 else -45.0
		sculpt_fringe(s, cloth, fringe_mesh("sunforge_crupper_%s_v2" % sx, 0.345, 0.385, 0.43, 0.47, 0.26, c0, c1, 5, 0.12,
			0.02, 0.8), Vector3(0, 1.03, RUMP_C.z))
		sculpt_fringe(s, m("unit_gold_trim"), fringe_mesh("sunforge_crupper_trim_%s_v1" % sx, 0.35, 0.39, 0.355, 0.395, 0.03, c0,
			c1, 5, 0.0, 0.024, 0.0), Vector3(0, 1.035, RUMP_C.z))
	# gilded peytral with a dark rim
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	sculpt_add(s, shell_mesh("sunforge_peytral_v1", 0.40, 0.38, -68.0, 68.0, 0.0, 0.26, 0.03, 6, 1, 1.04, 0.0),
		Transform3D(cb, Vector3(0, 0.49, 0.58)), gold)
	sculpt_add(s, shell_mesh("sunforge_peytral_rim_v1", 0.412, 0.392, -70.0, 70.0, 0.24, 0.29, 0.035, 6, 1),
		Transform3D(cb, Vector3(0, 0.49, 0.58)), leather)


## Gilded chanfron with a ridge, and the standing sun-disc crest on the brow (a gold disc facing forward, a team heart,
## eight short rays).
func _gold_head(s: Dictionary) -> void:
	var gold := material_at(GOLD_MAT)
	var bright := m("unit_gold_trim")
	var cloth := m("fire_cloth")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	sculpt_add(s, shell_mesh("sunforge_chanfron_v1", 0.332, 0.38, -46.0, 46.0, 0.12, 0.64, 0.028, 5, 2, 0.58, 0.02),
		Transform3D(hb, SK_B), gold)
	var rp := PackedVector3Array([SK_B + sd * 0.14 + up * 0.39, SK_B + sd * 0.40 + up * 0.315, SK_B + sd * 0.62 + up * 0.25])
	sculpt_add(s, tube_mesh("sunforge_ridge_v1", rp, PackedFloat32Array([0.03, 0.024, 0.016]), 5, true, 0.6),
		Transform3D.IDENTITY, gold)
	# the sun crest: a post from the brow, the disc facing forward (+Z) a little tilted back, the team heart, rays
	var sc := SK_B + up * 0.50 + sd * 0.02 + Vector3(0, 0.02, 0)
	sculpt_add(s, cyl(0.03, 0.04, 0.16, 6), Transform3D(Basis.IDENTITY, SK_B + up * 0.38 + sd * 0.03), gold)
	var db := Basis(Vector3.RIGHT, deg_to_rad(80.0))   # cylinder axis (+Y) -> forward, tilted back 10 deg
	sculpt_add(s, cyl(0.12, 0.12, 0.035, 12), Transform3D(db, sc), gold)
	sculpt_add(s, cyl(0.065, 0.065, 0.04, 8), Transform3D(db, sc + db.y * 0.006), cloth)
	for k: int in 8:
		var a := TAU * float(k) / 8.0
		var d := db * Vector3(cos(a), 0, sin(a))
		sculpt_add(s, prism(Vector3(0.06, 0.10, 0.025)), Transform3D(frame(Vector3.ZERO, d, db.y).basis, sc + d * 0.16), bright)


func _gold_knee(s: Dictionary, p: Vector3) -> void:
	var gold := material_at(GOLD_MAT)
	sculpt_put(s, sphere(0.12, 8, 4), gold, Vector3(p.x, 0.40, p.z + 0.11), Vector3(-10, 0, 0), Vector3(1.1, 1.3, 0.55))
