extends "res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/make_g03.gd"
## G04 / G06: the orrery hall at x 0 (centre world (0,-2)); four flame actors on an arc (red, blue, green, violet).

const HALL_R := 11.0
const WALL := Color(0.46, 0.44, 0.5)
const BRASS := Color(0.75, 0.55, 0.22)
const FLAME_POS := [Vector2(-4.2, -1.87), Vector2(-1.7, -4.27), Vector2(1.7, -4.27), Vector2(4.2, -1.87)]


func _pol(r: float, a: float, y: float) -> Vector3:
	return Vector3(sin(a) * r, y, cos(a) * r)


func _ring3d(c: Vector3, r: float, w: float, t: float, basis: Basis, segs: int, col: Color, gap0 := -1.0, gap1 := -1.0) -> void:
	for i in segs:
		var a := TAU * (i + 0.5) / segs
		if gap0 >= 0.0 and a > gap0 and a < gap1:
			continue
		var pos := c + basis * Vector3(sin(a) * r, 0, cos(a) * r)
		var ba := basis * Basis(Vector3.UP, a)
		box(Transform3D(ba, pos + off), Vector3.ZERO, Vector3(r * PI / segs * 1.05, t, w), col)


func _hall() -> void:
	var centre := Vector3(0, 4.0, 0) + off
	var segs := 24
	var win_step := 4
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var bcol := WALL.lerp(WALL.darkened(0.25), h01(float(i), 1.0, 8))
		if i % win_step == 1:
			# window bay: piers, sill, lintel, glowing pane, mullions
			var am := (a0 + a1) * 0.5
			var aw := (a1 - a0) * 0.27
			for pr in [[a0, am - aw], [am + aw, a1]]:
				qo("lit", _pol(HALL_R, pr[0], 0) + off, _pol(HALL_R, pr[1], 0) + off, _pol(HALL_R, pr[1], 9.6) + off, _pol(HALL_R, pr[0], 9.6) + off, bcol, centre)
			qo("lit", _pol(HALL_R, am - aw, 0) + off, _pol(HALL_R, am + aw, 0) + off, _pol(HALL_R, am + aw, 1.6) + off, _pol(HALL_R, am - aw, 1.6) + off, bcol, centre)
			qo("lit", _pol(HALL_R, am - aw, 7.4) + off, _pol(HALL_R, am + aw, 7.4) + off, _pol(HALL_R, am + aw, 9.6) + off, _pol(HALL_R, am - aw, 9.6) + off, bcol, centre)
			var pr2 := HALL_R + 0.5
			var pane := Color(0.45, 0.62, 1.0)
			qo("glow", _pol(pr2, am - aw, 1.6) + off, _pol(pr2, am + aw, 1.6) + off, _pol(pr2, am + aw, 7.4) + off, _pol(pr2, am - aw, 7.4) + off, pane * 0.32, centre)
			for f in [0.25, 0.5, 0.75]:
				var ma := lerpf(am - aw, am + aw, f)
				box(Transform3D(Basis(Vector3.UP, ma), _pol(HALL_R + 0.3, ma, 4.5) + off), Vector3.ZERO, Vector3(0.04, 2.9, 0.05), Color(0.12, 0.12, 0.16))
			box(Transform3D(Basis(Vector3.UP, am), _pol(HALL_R + 0.3, am, 4.6) + off), Vector3.ZERO, Vector3(aw * HALL_R * 0.98, 0.04, 0.05), Color(0.12, 0.12, 0.16))
			halo(_pol(HALL_R - 0.5, am, 4.5), 3.2, Color(0.3, 0.5, 1.0, 0.12), 0.0)
		else:
			qo("lit", _pol(HALL_R, a0, 0) + off, _pol(HALL_R, a1, 0) + off, _pol(HALL_R, a1, 9.6) + off, _pol(HALL_R, a0, 9.6) + off, bcol, centre)
	# wall base course and band
	for y in [0.0, 3.4, 9.0]:
		for i in segs:
			var am := TAU * (i + 0.5) / segs
			box(Transform3D(Basis(Vector3.UP, am), _pol(HALL_R - 0.12, am, y + 0.2) + off), Vector3.ZERO, Vector3(HALL_R * PI / segs * 1.02, 0.2 if y < 8.0 else 0.32, 0.14), WALL.darkened(0.3))
	# ceiling cone + ribs
	for i in 24:
		var a0 := TAU * i / 24
		var a1 := TAU * (i + 1) / 24
		qo("lit", _pol(HALL_R, a0, 9.6) + off, _pol(HALL_R, a1, 9.6) + off, _pol(0.4, a1, 14.0) + off, _pol(0.4, a0, 14.0) + off, Color(0.22, 0.2, 0.26), centre)
		if i % 2 == 0:
			var mid := (a0 + a1) * 0.5
			box(Transform3D(Basis(Vector3.UP, mid) * Basis(Vector3.RIGHT, -0.57), _pol(5.6, mid, 11.8) + off), Vector3.ZERO, Vector3(0.14, 0.18, 6.3), Color(0.12, 0.1, 0.12))
	# floor disc with tile variation and the brass inlay
	var rings := int(HALL_R / 0.45)
	for j in rings:
		for i in 48:
			var r0 := j * 0.45
			var r1 := r0 + 0.45
			var a0 := TAU * i / 48
			var a1 := TAU * (i + 1) / 48
			var tile := h01(floorf(r0 / 1.35), floorf((a0 + a1) * 0.5 * r0 / 1.35), 5)
			var fc := Color(0.24, 0.24, 0.31).lerp(Color(0.16, 0.16, 0.22), tile)
			qo("lit", _pol(r0, a0, 0.01) + off, _pol(r0, a1, 0.01) + off, _pol(r1, a1, 0.01) + off, _pol(r1, a0, 0.01) + off, fc, Vector3(0, 5, 0) + off)
	for rr in [2.2, 2.7, 6.6, 6.95]:
		for i in 64:
			var a0 := TAU * i / 64
			var a1 := TAU * (i + 1) / 64
			qo("lit", _pol(rr, a0, 0.03) + off, _pol(rr, a1, 0.03) + off, _pol(rr + 0.14, a1, 0.03) + off, _pol(rr + 0.14, a0, 0.03) + off, BRASS, Vector3(0, 5, 0) + off)
	for k in 12:
		var a := TAU * k / 12
		box(Transform3D(Basis(Vector3.UP, a), _pol(4.5, a, 0.02) + off), Vector3.ZERO, Vector3(0.05, 0.012, 2.1), BRASS.darkened(0.15))
	# central orrery on a plinth (dim brass, one ring broken)
	cyl(T(0, 0, 0), Vector3.ZERO, 0.9, 0.7, 0.6, 12, WALL.darkened(0.1))
	cyl(T(0, 0.6, 0), Vector3.ZERO, 0.28, 0.2, 0.9, 8, BRASS.darkened(0.2))
	blob(T(0, 1.75, 0), Vector3.ZERO, Vector3(0.3, 0.3, 0.3), Color(0.3, 0.32, 0.5), 4, 5, 8, 0.05, false)
	_ring3d(Vector3(0, 1.75, 0), 0.85, 0.05, 0.03, Basis.from_euler(Vector3(0.3, 0, 0.2)), 28, BRASS)
	_ring3d(Vector3(0, 1.75, 0), 1.2, 0.05, 0.03, Basis.from_euler(Vector3(-0.5, 0.7, 0.9)), 32, BRASS.darkened(0.1), 1.0, 2.2)
	_ring3d(Vector3(0, 1.75, 0), 1.55, 0.05, 0.03, Basis.from_euler(Vector3(1.1, 0.3, -0.4)), 36, BRASS.darkened(0.2))
	# braziers under each flame
	for fp: Vector2 in FLAME_POS:
		var xf := T(fp.x, 0, fp.y)
		cyl(xf, Vector3.ZERO, 0.34, 0.26, 0.16, 8, WALL.darkened(0.2))
		cyl(xf, Vector3(0, 0.16, 0), 0.09, 0.07, 0.62, 8, WALL.darkened(0.1))
		cyl(xf, Vector3(0, 0.78, 0), 0.24, 0.42, 0.2, 10, BRASS.darkened(0.25))
		cyl(xf, Vector3(0, 0.96, 0), 0.4, 0.4, 0.05, 10, Color(0.06, 0.05, 0.05), false)
		for k in 6:
			var a := TAU * k / 6.0 + 0.4
			box(Transform3D(Basis.from_euler(Vector3(0.3, a, 0.2)), Vector3(fp.x, 1.0, fp.y) + off + Vector3(sin(a) * 0.15, 0, cos(a) * 0.15)), Vector3.ZERO, Vector3(0.05, 0.03, 0.07), Color(0.07, 0.06, 0.06))


func _props() -> void:
	# lectern with an open book, papers, a toppled stool, a telescope, bookshelves
	var lx := -7.0
	var lz := 3.4
	var la := atan2(-lx, -lz)
	var lt := T(lx, 0, lz, la)
	box(lt, Vector3(0, 0.55, 0), Vector3(0.28, 0.55, 0.22), Color(0.3, 0.2, 0.14))
	box(lt, Vector3(0, 1.12, -0.05), Vector3(0.4, 0.03, 0.3), Color(0.3, 0.2, 0.14), "lit")
	box(T(lx, 1.15, lz, la, Vector3(-0.4, 0, 0)), Vector3(0, 0.1, 0.02), Vector3(0.3, 0.015, 0.2), Color(0.85, 0.8, 0.65))
	for i in 9:
		var a := h01(float(i), 1.0, 4) * TAU
		var px := lx + 1.0 + (h01(float(i), 2.0, 4) - 0.2) * 3.0
		var pz := lz - 0.2 + (h01(float(i), 3.0, 4) - 0.5) * 2.4
		box(T(px, 0.02, pz, a), Vector3.ZERO, Vector3(0.14, 0.006, 0.1), Color(0.75, 0.7, 0.56))
	box(T(-5.3, 0.15, 4.8, 0.5, Vector3(0, 0, 1.5)), Vector3(0, 0.2, 0), Vector3(0.18, 0.2, 0.18), Color(0.3, 0.2, 0.14))
	var tx := T(7.4, 0, 2.6, -0.8)
	cyl(tx, Vector3(0, 0.6, 0), 0.5, 0.12, 0.0, 3, BRASS.darkened(0.3), false)
	cyl(T(7.4, 1.35, 2.6, -0.8, Vector3(0.9, 0, 0)), Vector3.ZERO, 0.16, 0.12, 2.6, 10, BRASS.darkened(0.15), true)
	for k in 3:
		var a := TAU * k / 3.0
		box(Transform3D(Basis(Vector3.UP, a) * Basis.from_euler(Vector3(0, 0, 0.0)), Vector3(7.4, 0.6, 2.6) + off + Vector3(sin(a) * 0.3, 0, cos(a) * 0.3)), Vector3.ZERO, Vector3(0.025, 0.65, 0.025), Color(0.25, 0.18, 0.13))
	for i: int in [0, 2, 5]:
		var a := TAU * (i * 4 + 3.0) / 24.0 - 0.02
		var xf := Transform3D(Basis(Vector3.UP, a), _pol(HALL_R - 0.5, a, 0) + off)
		box(xf, Vector3(0, 1.8, 0), Vector3(0.9, 1.8, 0.28), Color(0.26, 0.18, 0.13))
		for r in 5:
			var x := -0.8
			while x < 0.75:
				var w := 0.05 + 0.05 * h01(x, float(r), i)
				var bh := 0.28 + 0.1 * h01(float(r), x, i + 5)
				var bc := Color(0.4, 0.15, 0.15).lerp(Color(0.15, 0.25, 0.4), h01(x, float(r), i + 9))
				box(xf, Vector3(x + w, 0.35 + r * 0.66 + bh * 0.5, 0.06), Vector3(w * 0.9, bh * 0.5, 0.2), bc.darkened(0.15))
				x += w * 2.1


func _g04() -> void:
	off = Vector3(0, 0, -2)
	seedv = 4
	grime = 0.4
	amb_top = Color(0.22, 0.24, 0.36)
	amb_bot = Color(0.12, 0.12, 0.2)
	moon_col = Color(0.0, 0.0, 0.0)
	fill_col = Color(0.03, 0.03, 0.06)
	cell = 0.5
	for k in 6:
		var a := TAU * (k * 4 + 1.5) / 24.0
		add_light(_pol(HALL_R * 0.72, a, 4.2), Color(0.32, 0.5, 1.0), 1.5, 9.0, false)
	add_light(Vector3(0, 6.0, 0), Color(0.25, 0.28, 0.5), 0.6, 12.0, false)
	prep()
	_hall()
	_props()
	for i in 12:
		mist(Vector3(-8.0 + h01(float(i), 1.0, 12) * 16.0, 0.4 + h01(float(i), 2.0, 12) * 0.5, -6.0 + h01(float(i), 3.0, 12) * 14.0), 3.0, Color(0.32, 0.38, 0.6, 0.12), 0.2)
	for i in 14:
		halo(Vector3(-7.0 + h01(float(i), 4.0, 12) * 14.0, 0.5 + h01(float(i), 5.0, 12) * 5.0, -7.0 + h01(float(i), 6.0, 12) * 12.0), 0.09, Color(0.6, 0.75, 1.0, 0.4), 1.0)
	cell = 0.32


func _flame(col: Color) -> void:
	var y := 1.02
	var hot := col.lerp(Color(1, 1, 1), 0.55)
	cyl(T(0, y, 0), Vector3.ZERO, 0.3, 0.0, 1.05, 7, col * 0.9, true, "glow")
	cyl(T(0.02, y, 0), Vector3.ZERO, 0.2, 0.0, 0.8, 7, col.lerp(hot, 0.4), true, "glow")
	cyl(T(0, y, 0), Vector3.ZERO, 0.11, 0.0, 0.5, 6, hot, true, "glow")
	for i in 4:
		var a := TAU * i / 4.0
		cyl(T(sin(a) * 0.2, y + 0.04, cos(a) * 0.2, 0, Vector3(cos(a) * 0.35, 0, -sin(a) * 0.35)), Vector3.ZERO, 0.09, 0.0, 0.5 + 0.1 * i, 5, col, true, "glow")
	halo(Vector3(0, y + 0.55, 0), 1.7, Color(col.r, col.g, col.b, 0.5), 0.0)
	halo(Vector3(0, y + 0.55, 0), 0.5, Color(hot.r, hot.g, hot.b, 0.8), 0.0)
	halo(Vector3(0, y + 2.4, 0), 1.3, Color(col.r, col.g, col.b, 0.14), 0.0)
	for i in 5:
		halo(Vector3((h01(float(i), 1.0, 3) - 0.5) * 0.7, y + 1.0 + i * 0.35, (h01(float(i), 2.0, 3) - 0.5) * 0.7), 0.1, Color(hot.r, hot.g, hot.b, 0.9), 1.0)
	pool(Vector3(0, 0.05, 0), 4.6, Color(col.r, col.g, col.b, 0.55))
	pool(Vector3(0, 0.05, 0), 1.7, Color(col.r, col.g, col.b, 0.5))
	pool(Vector3(0, 0.98, 0), 0.5, Color(hot.r, hot.g, hot.b, 0.6))
