class_name GroveStablesModel
extends StablesModel
## Visual model of Ysolde's Stables, the Grove Stables (docs/design/stables.md; cavalry-mounts.md 13.V24), in the
## Grove Hall / Heartwood language but with NO green-on-green (under_90.md: Nature melts into the meadow): the main
## masses are bark, straw and pale moss. A mossy stone foundation with pale lichen, wattle walls (woven straw-tan
## withies) in a frame of living bark posts, living branch arches over the barn (the Hall's bark arches, their feet
## rooting into the plinth), a thick STRAW THATCH roof whose ridge is dressed with a runner of TEAM leaves and a
## team cloth (the top-facing team area), the loft tower as a hollow living trunk with root flares under a thatch
## cone crowned with a pale-sage leaf crown and a hanging glowing seed-lantern (the high glow point, drifting pollen),
## a woven wattle fence on rough branch posts, a seed-lantern at the gate, a log pile and a rune stone.
## The mount is the Stagrunners' GROVE STAG (warm brown, pale branching antlers with blossoms) with a team saddle
## cloth; another looks out of the middle stall. Warm windows.
## Layout, hooks, states, budgets: StablesModel (stables_model.gd).

const MOSS := Color(0.64, 0.66, 0.48)
const SAGE := Color(0.60, 0.64, 0.42)
const OLIVE := Color(0.66, 0.56, 0.30)
const STAG := Color(0.48, 0.32, 0.20)
const STAG_DK := Color(0.26, 0.17, 0.11)
const ANTLER := Color(0.88, 0.80, 0.62)
const BLOSSOM := Color(0.96, 0.66, 0.74)


func _setup_palette() -> void:
	kingdom_color = Color(0.35, 0.70, 0.25)
	glow_color = Color(0.75, 1.00, 0.40)
	stone_color = Color(0.50, 0.47, 0.37)
	dark_color = Color(0.26, 0.24, 0.17)
	metal_color = Color(0.40, 0.28, 0.16)
	stripe_color = Color(0.15, 0.40, 0.15)
	glyph_color = Color(0.75, 1.00, 0.40)
	glyph_shape = 1
	smoke_color = Color(0.24, 0.22, 0.17)
	dust_color = Color(0.40, 0.36, 0.26)
	decal_color = Color(0.05, 0.05, 0.02)
	light_color = Color(0.75, 1.00, 0.45)
	light_energy = 1.0
	danger_ramp_hot = Color(1.0, 0.85, 0.5)
	danger_ramp_mid = Color(1.0, 0.5, 0.15)
	danger_ramp_end = Color(0.35, 0.12, 0.04)
	c_found = Color(0.28, 0.25, 0.19)
	c_stone = Color(0.54, 0.51, 0.41)
	c_wall = Color(0.52, 0.42, 0.27)
	c_beam = Color(0.32, 0.21, 0.12)
	c_wood = Color(0.55, 0.40, 0.24)
	c_trim = Color(0.46, 0.33, 0.19)
	c_straw = Color(0.88, 0.75, 0.43)
	c_straw_dk = Color(0.64, 0.51, 0.27)
	c_earth = Color(0.42, 0.33, 0.21)
	c_water = Color(0.20, 0.30, 0.28)
	c_leather = Color(0.34, 0.20, 0.11)
	c_roof_core = Color(0.44, 0.36, 0.22)
	roof_tile = Color(0.81, 0.75, 0.58)
	window_color = Color(1.0, 0.72, 0.36)
	glow_energy = 3.2
	roof_rise = 1.9
	tower_rise = 1.55
	tile_courses = 4
	seed_base = 7501


## Pale moss / lichen on the foundation.
func _k_found_extra(it: Array, rng: RandomNumberGenerator) -> void:
	for k: int in 3:
		var p := Vector3(rng.randf_range(-2.9, 2.7), PT + 0.02, rng.randf_range(0.3, 2.9))
		it.append(_i(_sp(8, 3), p, MOSS.lerp(SAGE, rng.randf()), Vector3(0, rng.randf() * 180.0, 0),
			Vector3(rng.randf_range(0.5, 0.9), 0.14, rng.randf_range(0.35, 0.6))))


## Wattle walls: straw-tan woven withies (alternating tilted bands) over a mossy stone course.
func _k_walls(it: Array, rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var cx: float = (BX0 + BX1) * 0.5
	var cz: float = (BZ0 + BZ1) * 0.5
	var lx: float = BX1 - BX0
	var lz: float = BZ1 - BZ0
	it.append(_i(box, Vector3(cx, PT + lower_h * 0.5, cz), c_stone, Vector3.ZERO, Vector3(lx, lower_h, lz), K_STONE))
	var up0: float = PT + lower_h
	it.append(_i(box, Vector3(cx, (up0 + EAVE) * 0.5, cz), c_wall, Vector3.ZERO, Vector3(lx - 0.08, EAVE - up0, lz - 0.08)))
	for k: int in 4:
		var y: float = up0 + 0.2 + (EAVE - up0 - 0.4) * k / 3.0
		var col: Color = c_wall.darkened(0.12) if k % 2 == 0 else c_wall.lightened(0.06)
		it.append(_i(box, Vector3(cx, y, BZ1 + 0.02), col, Vector3(0, 0, 2.0 if k % 2 == 0 else -2.0), Vector3(lx - 0.3, 0.14, 0.04)))
	for k: int in 4:
		var p := Vector3(rng.randf_range(BX0 + 0.3, BX1 - 0.3), PT + rng.randf_range(0.1, lower_h - 0.1), BZ1 + 0.05)
		it.append(_i(_sp(8, 3), p, MOSS, Vector3(90, 0, rng.randf() * 90.0), Vector3(0.5, 0.22, 0.3)))


## Living bark arches over the barn (feet rooting into the plinth), the ridge runner of team leaves + cloth, a
## few leaf knots.
func _k_roof_extra(it: Array, cz: float, hd: float, x0: float, x1: float) -> void:
	var a: float = atan2(roof_rise, hd)
	var slope_l: float = sqrt(hd * hd + roof_rise * roof_rise)
	# Team cloth runner draped over the ridge (upper course of both slopes) + a dark hem.
	for s: float in [-1.0, 1.0]:
		var e := Vector3((x0 + x1) * 0.5, EAVE, cz + s * hd)
		var u := Vector3(0.0, sin(a), -s * cos(a))
		var nrm := Vector3(0.0, cos(a), s * sin(a))
		var p: Vector3 = e + u * (slope_l * 0.8) + nrm * 0.26
		it.append(_ix(_bx(), Transform3D(Basis(Vector3.RIGHT, s * a).scaled_local(Vector3(x1 - x0 - 0.6, 0.06, slope_l * 0.42)), p), T(1.0)))
		var hem: Vector3 = e + u * (slope_l * 0.58) + nrm * 0.25
		it.append(_ix(_bx(), Transform3D(Basis(Vector3.RIGHT, s * a).scaled_local(Vector3(x1 - x0 - 0.6, 0.07, 0.1)), hem), T(0.55)))
	# Leaf knots on the ridge (team leaves).
	for k: int in 3:
		var x: float = x0 + 0.5 + (x1 - x0 - 1.0) * k / 2.0
		if absf(x - 1.05) < 0.55:
			continue
		it.append(_i(_sp(8, 4), Vector3(x, EAVE + roof_rise + 0.35, cz), T(0.9), Vector3(0, 30 * k, 0), Vector3(0.55, 0.32, 0.45)))
	# Two living arches across the barn (bark), rooting into the foundation.
	for x: float in [BX0 + 0.35, BX1 - 0.35]:
		var pts: Array[Vector3] = []
		for k: int in 5:
			var t: float = float(k) / 4.0
			var ang: float = PI * t
			pts.append(Vector3(x, EAVE - 0.2 + sin(ang) * (roof_rise + 0.7), cz - cos(ang) * (hd + 0.1)))
		pts[0] = Vector3(pts[0].x, 0.02, pts[0].z - 0.15)
		pts[4] = Vector3(pts[4].x, 0.02, pts[4].z + 0.15)
		for k: int in 4:
			it.append(_rod(pts[k], pts[k + 1], 0.13, 0.12, 6, c_beam))


## A carved wooden stag-head vane.
func _k_vane(it: Array, p: Vector3) -> void:
	it.append(_i(_bx(), p, c_wood, Vector3(0, 30, 0), Vector3(0.05, 0.22, 0.42)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(_cy(0.0, 0.03, 0.3, 4), p + Vector3(0, 0.22, 0) + Basis(Vector3.UP, deg_to_rad(30.0)) * Vector3(0, 0, s * 0.08), ANTLER,
			Vector3(s * 25.0, 30, 0)))


## The tower as a living trunk: bark cylinder with vertical ridges, root flares over the plinth, sap-lit knot holes.
func _k_tower_skin(it: Array, h: float) -> void:
	var box: BoxMesh = _bx()
	it.append(_i(_cy(TR - 0.12, TR + 0.12, h, TSEG), Vector3(0, h * 0.5, 0), c_beam.lightened(0.12), Vector3(0, 18, 0)))
	it.append(_i(_cy(TR + 0.02, TR + 0.02, 0.18, TSEG), Vector3(0, 2.0, 0), c_wall, Vector3(0, 18, 0)))
	for k: int in 5:
		var ang: float = TAU * (k + 0.3) / 5.0
		var d := Vector3(cos(ang), 0, sin(ang))
		it.append(_ix(box, Transform3D(Basis(Vector3.UP, -ang).scaled_local(Vector3(0.14, h - 0.4, 0.16)),
			d * (TR - 0.02) + Vector3(0, h * 0.5, 0)), c_beam))
	for k: int in 5:
		var ang2: float = TAU * (k + 0.1) / 5.0
		var d2 := Vector3(cos(ang2), 0, sin(ang2))
		it.append(_rod(d2 * (TR - 0.05) + Vector3(0, 0.9, 0), d2 * (TR + 0.55) + Vector3(0, -0.75, 0), 0.2, 0.08, 6, c_beam))
	it.append(_i(_sp(8, 4), Vector3(TR * 0.7, 2.6, TR * 0.6), MOSS, Vector3(0, 40, 90), Vector3(0.6, 0.2, 0.4)))


## Pale-sage leaf crown on the thatch cone, a hanging seed-lantern (glow), drifting pollen.
func _k_tower_top(it: Array, tower: Node3D, h: float) -> void:
	var apex: float = h + tower_rise + 0.45
	var c := Vector3(0, apex + 0.1, 0)
	it.append(_i(_cy(0.08, 0.12, 0.7, 6), c + Vector3(0, 0.15, 0), c_beam))
	var blobs: Array = [[Vector3(0, 0.62, 0), Vector3(0.95, 0.55, 0.9), SAGE], [Vector3(0.35, 0.45, 0.2), Vector3(0.6, 0.4, 0.55), OLIVE],
		[Vector3(0.05, 0.9, -0.05), Vector3(0.5, 0.35, 0.45), T(0.95)]]
	for b: Array in blobs:
		it.append(_i(_sp(8, 4), c + (b[0] as Vector3), b[2], Vector3(0, 25, 0), b[1]))
	it.append(_i(_sp(6, 3), c + Vector3(0.1, 1.12, 0.05), BLOSSOM, Vector3.ZERO, Vector3(0.24, 0.12, 0.24)))
	# Seed-lantern hanging from a branch over the dormer side.
	var br := c + Vector3(0.0, 0.35, -0.3)
	var tip: Vector3 = br + Vector3(0.0, -0.1, -0.85)
	it.append(_rod(br, tip, 0.06, 0.035, 5, c_beam))
	it.append(_i(_bx(), tip + Vector3(0, -0.2, 0), c_beam, Vector3.ZERO, Vector3(0.03, 0.4, 0.03)))
	it.append(_i(_cyc(0.08, 0.16, 0.12, 6), tip + Vector3(0, -0.42, 0), c_beam))
	it.append(_i(_sp(8, 4), tip + Vector3(0, -0.62, 0), Color.WHITE, Vector3.ZERO, Vector3(0.26, 0.36, 0.26), K_PLAIN, mat_glow))
	var pol := _pm(Vector3(0, -0.2, 0), 90.0, 0.1, 0.3, Vector3(0.12, -0.05, 0.0), 0.06, 0.03,
		_ramp(Color(0.95, 1.0, 0.6, 0.7), Color(0.8, 1.0, 0.5, 0.0), false))
	pol.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pol.emission_sphere_radius = 0.8
	_idle_fx.append(_particles("Pollen", tower, c + Vector3(0, 0.6, 0), 8, 3.0, pol, _add_quad, false))


## Log pile, a rune stone with a pale leaf rune (no glow), mushrooms.
func _k_yard_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	var lp := Vector3(-2.35, 0.0, -2.35)
	for k: int in 3:
		var row: int = 0 if k < 2 else 1
		var z: float = -0.12 + 0.24 * k if row == 0 else 0.0
		it.append(_i(_cyc(0.12, 0.12, 0.9, 7), lp + Vector3(0, 0.12 + 0.22 * row, z), c_beam.lightened(0.1), Vector3(0, 0, 90)))
	var rs := Vector3(-1.45, 0.0, -2.45)
	it.append(_i(_cyc(0.16, 0.26, 1.1, 5), rs + Vector3(0, 0.5, 0), c_stone.lightened(0.1), Vector3(8, 20, -6), Vector3.ONE, K_STONE))
	it.append(_i(_bx(), rs + Vector3(0.05, 0.62, -0.2), MOSS, Vector3(8, 20, -6), Vector3(0.16, 0.34, 0.04)))


func _k_lantern_cage() -> Color:
	return c_beam


## Rough branch post, slightly crooked, with a knot.
func _k_post(it: Array, p: Vector3) -> void:
	var lean: float = sin(p.x * 3.1 + p.z * 1.7) * 5.0
	it.append(_i(_cy(0.08, 0.11, 1.15, 6), p + Vector3(0, 0.56, 0), c_beam, Vector3(lean, 0, -lean * 0.6)))
	it.append(_i(_cyc(0.0, 0.12, 0.12, 5), p + Vector3(0, 1.18, 0), MOSS))


## Woven wattle rails: two twisted withies.
func _k_rail(it: Array, a: Vector3, b: Vector3) -> void:
	it.append(_ix(_bx(), _seg(a + Vector3(0, 0.03, 0), b - Vector3(0, 0.03, 0), 0.1, 0.12), c_wall.darkened(0.1)))


# --- The Grove Stag -----------------------------------------------------------------------------------------------

func _k_mount_prof() -> Dictionary:
	return {"len": 1.8, "height": 1.45, "girth": 0.52, "coat": STAG, "dark": STAG_DK, "hoof": Color(0.12, 0.08, 0.06),
		"leg_r": 0.06, "neck_h": 0.6, "neck_f": 0.22, "neck_r": 0.38}


func _k_mount_extra(body: Array, tail: Array, bh: float, L: float, G: float) -> void:
	# Pale belly and rump patch, a ruff of pale fur on the chest.
	body.append(_i(_sp(8, 4), Vector3(0, bh + 0.02, L * 0.42), ANTLER.lerp(STAG, 0.3), Vector3.ZERO, Vector3(G * 0.7, G * 0.62, 0.2)))
	body.append(_i(_sp(8, 4), Vector3(0, bh + 0.05, -L * 0.42), ANTLER.lerp(STAG, 0.35), Vector3(-20, 0, 0), Vector3(G * 0.8, G * 0.8, 0.3)))
	tail.append(_i(_cyc(0.02, 0.07, 0.2, 5), Vector3(0, -0.05, 0.06), ANTLER.lerp(STAG, 0.2), Vector3(-40, 0, 0)))


## Stag head: a slim head, big pale branching antlers with blossoms, ears.
func _k_head(it: Array, xf: Transform3D) -> void:
	var parts: Array = []
	parts.append(_i(_sp(10, 5), Vector3(0, 0.02, -0.08), STAG, Vector3(-20, 0, 0), Vector3(0.26, 0.3, 0.36)))
	parts.append(_i(_cyc(0.07, 0.12, 0.42, 8), Vector3(0, -0.08, -0.34), STAG, Vector3(-65, 0, 0)))
	parts.append(_i(_cyc(0.07, 0.07, 0.05, 8), Vector3(0, -0.16, -0.54), STAG_DK, Vector3(-65, 0, 0)))
	for s: float in [-1.0, 1.0]:
		parts.append(_i(_pr(), Vector3(s * 0.17, 0.16, 0.0), STAG_DK, Vector3(0, 0, s * -60.0), Vector3(0.1, 0.2, 0.05)))
		var base := Vector3(s * 0.08, 0.16, -0.04)
		var mid: Vector3 = base + Vector3(s * 0.3, 0.42, 0.06)
		var top: Vector3 = mid + Vector3(s * 0.1, 0.36, -0.1)
		parts.append(_rod(base, mid, 0.04, 0.03, 5, ANTLER))
		parts.append(_rod(mid, top, 0.03, 0.015, 5, ANTLER))
		parts.append(_rod(mid, mid + Vector3(s * 0.26, 0.12, 0.1), 0.025, 0.012, 4, ANTLER))
		parts.append(_i(_sp(6, 3), mid + Vector3(0, 0.04, 0), BLOSSOM, Vector3.ZERO, Vector3(0.14, 0.09, 0.14)))
	for p: Array in parts:
		p[1] = xf * (p[1] as Transform3D)
		it.append(p)
