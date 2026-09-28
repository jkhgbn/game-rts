extends "res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/make_core.gd"
## G03: the graveyard at x -24. Boy, candle (local 0.55, 1.7), the family tombstones.

const STONE := Color(0.62, 0.64, 0.68)
const BARK := Color(0.22, 0.17, 0.15)
const CANDLE_POS := Vector3(0.55, 0.0, 1.7)
const BOY_POS := Vector3(-0.9, 0.0, -1.2)

var stones: Array = []


func _add_stone(kind: int, x: float, z: float, s: float, yaw: float, lean: Vector3, eng := false) -> void:
	stones.append([kind, x, z, s, yaw, lean, eng])
	occl(Vector3(x, 0.5 * s, z), Vector3(0.3 * s, 0.5 * s, 0.14 * s))


func _build_stone(d: Array) -> void:
	var kind: int = d[0]
	var s: float = d[3]
	var xf := T(d[1], gh(d[1], d[2]) - 0.03, d[2], d[4], d[5])
	var tone := STONE.lerp(Color(0.5, 0.56, 0.5), h01(d[1], d[2], 4) * 0.6)
	match kind:
		0:  # arched
			box(xf, Vector3(0, 0.42 * s, 0), Vector3(0.28, 0.42, 0.07) * s, tone)
			cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.84 * s, 0)), Vector3(0, -0.07 * s, 0), 0.28 * s, 0.28 * s, 0.14 * s, 10, tone)
		1:  # cross
			box(xf, Vector3(0, 0.5 * s, 0), Vector3(0.09, 0.5, 0.07) * s, tone)
			box(xf, Vector3(0, 0.78 * s, 0), Vector3(0.28, 0.08, 0.07) * s, tone)
			box(xf, Vector3(0, 0.05 * s, 0), Vector3(0.28, 0.05, 0.16) * s, tone.darkened(0.15))
		2:  # low slab
			box(xf, Vector3(0, 0.16 * s, 0), Vector3(0.34, 0.16, 0.06) * s, tone)
			box(xf, Vector3(0, 0.03 * s, 0), Vector3(0.4, 0.03, 0.14) * s, tone.darkened(0.2))
		3:  # obelisk
			box(xf, Vector3(0, 0.08 * s, 0), Vector3(0.3, 0.08, 0.3) * s, tone.darkened(0.15))
			cyl(xf * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO), Vector3(0, 0.16 * s, 0), 0.2 * s, 0.11 * s, 1.0 * s, 4, tone)
		_:  # wooden marker
			box(xf, Vector3(0, 0.35 * s, 0), Vector3(0.04, 0.35, 0.03) * s, Color(0.4, 0.3, 0.22))
			box(xf, Vector3(0, 0.5 * s, 0), Vector3(0.16, 0.035, 0.03) * s, Color(0.4, 0.3, 0.22))
	if d[6]:
		var ink := tone.darkened(0.6)
		var zf := 0.074 * s
		for i in 3:
			box(xf, Vector3(0, (0.56 - 0.09 * i) * s, zf), Vector3(0.14 - 0.03 * i, 0.012, 0.004) * s, ink)
		box(xf, Vector3(0, 0.7 * s, zf), Vector3(0.012, 0.05, 0.004) * s, ink)
		box(xf, Vector3(0, 0.71 * s, zf), Vector3(0.04, 0.012, 0.004) * s, ink)


func _flowers(x: float, z: float, cols: Array, sd: int) -> void:
	for i in 6:
		var px := x + (h01(float(i), 1.0, sd) - 0.5) * 0.3
		var pz := z + (h01(float(i), 2.0, sd) - 0.5) * 0.2
		var c: Color = cols[i % cols.size()]
		box(T(px, gh(px, pz), pz), Vector3(0, 0.06, 0), Vector3(0.006, 0.06, 0.006), Color(0.2, 0.4, 0.2))
		blob(T(px, gh(px, pz) + 0.11, pz), Vector3.ZERO, Vector3(0.05, 0.035, 0.05), c, sd + i, 3, 5, 0.2, false)


func _dead_tree(x: float, z: float, h: float, lean: float, sd: int) -> void:
	var p := Vector3(x, gh(x, z), z)
	var d := Vector3(lean, 1.0, lean * 0.4).normalized()
	var r := 0.3
	for i in 5:
		var sl := h * 0.14
		var rr := r * 0.82
		d = (d + Vector3(h01(float(i), 1.0, sd) - 0.5, 0.15, h01(float(i), 2.0, sd) - 0.5) * 0.25).normalized()
		cyl(Transform3D(_by(d), p + off), Vector3.ZERO, r, rr, sl, 6, BARK, false)
		p += d * sl
		r = rr
		if i >= 1:
			for k in 2:
				var a := h01(float(i), float(k), sd + 5) * TAU
				limb(p, Vector3(cos(a), 0.55 + 0.5 * h01(float(k), float(i), sd), sin(a)).normalized(), h * (0.32 - 0.03 * i), r * 0.55, r * 0.12, BARK, sd + i * 17 + k, 0)
	limb(p, d, h * 0.25, r, r * 0.15, BARK, sd + 99, 0)
	occl(Vector3(x, h * 0.4, z), Vector3(0.3, h * 0.4, 0.3))


func _cypress(x: float, z: float, h: float, sd: int) -> void:
	var col := Color(0.1, 0.24, 0.17).lerp(Color(0.16, 0.3, 0.2), h01(x, z, sd))
	var y := gh(x, z)
	var r := 0.5 + h * 0.07
	for i in 4:
		var k := float(i) / 4.0
		cyl(T(x, y + h * k * 0.72, z, h01(float(i), x, sd) * 3.0), Vector3.ZERO, r * (1.0 - k * 0.55), r * (0.45 - k * 0.4) + 0.04, h * 0.42, 7, col, true)


func _mausoleum(x: float, z: float) -> void:
	var y := gh(x, z)
	var c := Color(0.5, 0.52, 0.56)
	var xf := T(x, y, z)
	box(xf, Vector3(0, 0.25, 1.4), Vector3(1.9, 0.25, 0.8), c.darkened(0.15))
	box(xf, Vector3(0, 0.6, 1.0), Vector3(1.7, 0.1, 0.5), c.darkened(0.1))
	box(xf, Vector3(0, 1.6, 0), Vector3(1.5, 1.4, 1.5), c)
	box(xf, Vector3(0, 3.1, 0), Vector3(1.75, 0.16, 1.7), c.darkened(0.1))
	cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 3.26, 1.7)), Vector3.ZERO, 1.2, 0.0, 3.4, 3, c.darkened(0.05), true)
	box(xf, Vector3(0, 1.0, 1.51), Vector3(0.55, 1.0, 0.06), Color(0.02, 0.03, 0.04))
	box(xf, Vector3(0, 1.0, 1.53), Vector3(0.38, 0.85, 0.01), Color(0.25, 0.75, 0.85), "glow")
	for sx in [-1.0, 1.0]:
		cyl(xf, Vector3(sx * 0.95, 0.6, 1.55), 0.13, 0.11, 2.4, 8, c.lightened(0.05))
	occl(Vector3(x, 1.6, z), Vector3(1.6, 1.6, 1.6))


func _fence(x0: float, x1: float, z: float, gate0: float, gate1: float) -> void:
	var n := int((x1 - x0) / 0.55)
	for i in n + 1:
		var x := x0 + i * 0.55
		if x > gate0 and x < gate1:
			continue
		var y := gh(x, z)
		var xf := T(x + (h01(float(i), 1.0, 8) - 0.5) * 0.04, y, z, 0.0, Vector3(0, 0, (h01(float(i), 2.0, 8) - 0.5) * 0.12))
		box(xf, Vector3(0, 0.45, 0), Vector3(0.018, 0.45, 0.018), Color(0.09, 0.09, 0.11))
		cyl(xf, Vector3(0, 0.9, 0), 0.03, 0.0, 0.14, 4, Color(0.12, 0.12, 0.14))
	for yy in [0.3, 0.72]:
		box(T(0, 0, z), Vector3((x0 + x1) * 0.5 - (gate0 + gate1) * 0.0, yy, 0), Vector3((x1 - x0) * 0.5, 0.014, 0.014), Color(0.08, 0.08, 0.1))


func _g03() -> void:
	off = Vector3(-24, 0, 0)
	seedv = 3
	grime = 1.0
	amb_top = Color(0.26, 0.32, 0.5)
	amb_bot = Color(0.13, 0.15, 0.24)
	moon_dir = Vector3(-0.35, 0.42, -0.83).normalized()
	moon_col = Color(0.5, 0.65, 1.0)
	fill_dir = Vector3(0.4, 0.5, 0.8).normalized()
	fill_col = Color(0.1, 0.12, 0.2)
	mounds = [[-2.4, -1.6, 1.1, 0.16, 0], [0.4, -1.9, 1.3, 0.2, 0], [2.6, -1.5, 0.9, 0.12, 0], [4.6, 0.6, 1.0, 0.22, 0]]
	stones = []
	_add_stone(0, -2.5, -2.7, 1.0, 0.1, Vector3(0.02, 0, 0.04), true)
	_add_stone(1, 0.3, -3.1, 1.35, -0.06, Vector3(0, 0, -0.03), true)
	_add_stone(0, 2.7, -2.6, 0.62, -0.12, Vector3(-0.03, 0, 0.06), true)
	_add_stone(4, 4.6, -0.3, 1.0, 0.4, Vector3(0.05, 0, -0.18))
	# rows behind
	var idx := 0
	for row in 3:
		var z := -5.2 - row * 2.3
		for i in 9:
			var x := -10.5 + i * 2.5 + (h01(float(i), float(row), 21) - 0.5) * 1.2 + row * 0.6
			if h01(float(i), float(row), 33) < 0.2:
				continue
			var kind := int(h01(float(i), float(row), 44) * 4.0)
			_add_stone(kind, x, z, 0.85 + h01(float(i), float(row), 55) * 0.6, (h01(float(i), float(row), 66) - 0.5) * 0.6, Vector3((h01(float(i), 1.0, row) - 0.5) * 0.14, 0, (h01(float(i), 2.0, row) - 0.5) * 0.25))
			idx += 1
	_add_stone(2, -4.6, 0.4, 1.0, 0.3, Vector3(0, 0, 0.1))
	_add_stone(0, -6.2, -1.8, 0.9, 0.5, Vector3(0.05, 0, -0.12))
	_add_stone(2, 6.6, -3.0, 1.0, -0.4, Vector3(0, 0, -0.1))
	# tree / building occluders are registered by their builders (before ground: mark them first)
	occl(Vector3(-6.0, 3.0, -4.0), Vector3(0.3, 3.0, 0.3))
	occl(Vector3(BOY_POS.x, 0.72, BOY_POS.z), Vector3(0.3, 0.72, 0.28))
	occl(Vector3(3.8, 1.6, -9.5), Vector3(1.6, 1.6, 1.6))
	add_light(CANDLE_POS + Vector3(0, 0.3, 0), Color(1.0, 0.6, 0.26), 2.6, 5.5)
	add_light(Vector3(-5.5, 1.2, 2.0), Color(0.3, 0.55, 0.9), 0.35, 8.0, false)
	prep()
	var gcol := func(x: float, z: float) -> Color:
		var c := Color(0.30, 0.42, 0.30).lerp(Color(0.22, 0.32, 0.26), h01(x * 0.3, z * 0.3, 2))
		if h01(x * 0.9, z * 0.9, 7) > 0.8:
			c = c.lerp(Color(0.36, 0.3, 0.22), 0.5)
		for m: Array in mounds:
			var d := Vector2(x - m[0], z - m[1]).length()
			c = c.lerp(Color(0.34, 0.25, 0.19), clampf(1.0 - d / (m[2] * 1.2), 0.0, 1.0) * 0.8)
		var pth := clampf(1.0 - absf(x - (0.5 - z * 0.06) + 1.0) / 1.3, 0.0, 1.0) * smoothstep(-2.5, 1.0, z)
		return c.lerp(Color(0.42, 0.42, 0.4), pth * 0.55)
	ground(-17.0, -17.0, 17.0, 9.0, 0.42, gcol, Color(0.03, 0.04, 0.08))
	blades(-9.0, -9.0, 9.0, 4.0, 1800, Color(0.2, 0.34, 0.22), 5, 0.3)
	blades(-2.0, 0.8, 3.0, 3.6, 450, Color(0.22, 0.36, 0.24), 6, 0.36)
	for d: Array in stones:
		_build_stone(d)
	# mounds: dirt piles + shovel + flowers
	blob(T(-2.4, gh(-2.4, -1.6), -1.6), Vector3(0, -0.05, 0), Vector3(0.6, 0.22, 1.0), Color(0.3, 0.22, 0.17), 3, 4, 8, 0.2)
	blob(T(0.4, gh(0.4, -1.9), -1.9), Vector3(0, -0.05, 0), Vector3(0.7, 0.26, 1.15), Color(0.3, 0.22, 0.17), 5, 4, 8, 0.2)
	_flowers(0.3, -2.5, [Color(0.75, 0.2, 0.2), Color(0.8, 0.75, 0.3)], 40)
	_flowers(-2.3, -2.2, [Color(0.6, 0.6, 0.85), Color(0.85, 0.85, 0.9)], 50)
	_flowers(2.6, -2.1, [Color(0.85, 0.5, 0.6)], 60)
	# shovel in the fresh pile
	var sx := T(4.6, gh(4.6, 0.6), 0.6, 0.6, Vector3(0.25, 0, -0.2))
	box(sx, Vector3(0, 0.55, 0), Vector3(0.015, 0.55, 0.015), Color(0.36, 0.26, 0.18))
	box(sx, Vector3(0, 1.12, 0), Vector3(0.05, 0.015, 0.015), Color(0.36, 0.26, 0.18))
	box(sx, Vector3(0, 0.05, 0), Vector3(0.1, 0.13, 0.012), Color(0.4, 0.42, 0.46))
	# the candle's tile and an open book at the boy's feet
	box(T(CANDLE_POS.x, gh(0.55, 1.7), CANDLE_POS.z, 0.3), Vector3(0, 0.02, 0), Vector3(0.28, 0.02, 0.22), Color(0.5, 0.5, 0.52))
	box(T(-1.35, gh(-1.35, -0.4), -0.4, 0.5), Vector3(0, 0.02, 0), Vector3(0.22, 0.02, 0.16), Color(0.7, 0.66, 0.55))
	# trees and buildings
	_dead_tree(-6.0, -4.0, 6.6, 0.15, 12)
	_dead_tree(7.5, -6.5, 5.4, -0.2, 31)
	_mausoleum(3.8, -9.5)
	_fence(-12.0, -3.0, -6.6, -8.0, -6.6)
	for i in 15:
		var x := -16.0 + i * 2.4 + (h01(float(i), 1.0, 77) - 0.5) * 1.4
		_cypress(x, -12.0 - h01(float(i), 2.0, 78) * 2.5, 6.0 + h01(float(i), 3.0, 79) * 3.5, 80 + i)
	_cypress(-9.5, -2.4, 5.0, 91)
	_cypress(9.2, -1.6, 4.4, 92)
	# moon and sky glints
	var mc := Vector3(-8.0, 11.0, -33.0)
	box(T(mc.x, mc.y, mc.z), Vector3.ZERO, Vector3(2.0, 2.0, 0.05), Color(0.85, 0.92, 1.0), "glow")
	halo(mc, 9.0, Color(0.35, 0.5, 0.9, 0.55), 0.0)
	halo(mc, 2.6, Color(0.7, 0.8, 1.0, 0.6), 0.0)
	# ground mist layers
	for i in 16:
		var mx := -12.0 + i * 1.6 + h01(float(i), 3.0, 90) * 1.5
		var mz := -10.0 + h01(float(i), 4.0, 91) * 13.0
		mist(Vector3(mx, 0.35 + h01(float(i), 5.0, 92) * 0.5, mz), 3.0 + h01(float(i), 6.0, 93) * 2.0, Color(0.30, 0.38, 0.6, 0.26), 0.2 + h01(float(i), 7.0, 94) * 0.3)
	# wisps
	for i in 7:
		halo(Vector3(-6.0 + h01(float(i), 1.0, 95) * 13.0, 0.6 + h01(float(i), 2.0, 96) * 2.2, -8.0 + h01(float(i), 3.0, 97) * 9.0), 0.16, Color(0.4, 0.8, 0.9, 0.5), 1.0)


func _candle() -> void:
	seedv = 9
	amb_top = Color(0.6, 0.55, 0.5)
	amb_bot = Color(0.3, 0.28, 0.25)
	moon_col = Color(0.1, 0.12, 0.2)
	fill_col = Color(0.1, 0.08, 0.06)
	add_light(Vector3(0, 0.3, 0), Color(1.0, 0.6, 0.26), 1.6, 1.2, false)
	prep()
	var wax := Color(0.9, 0.85, 0.7)
	cyl(T(0, 0.02, 0), Vector3.ZERO, 0.11, 0.09, 0.03, 10, Color(0.35, 0.33, 0.3))
	cyl(T(0, 0.05, 0), Vector3.ZERO, 0.048, 0.044, 0.2, 9, wax)
	blob(T(0.03, 0.2, 0.02), Vector3.ZERO, Vector3(0.03, 0.05, 0.03), wax, 2, 3, 5, 0.1, false)
	box(T(0, 0.255, 0), Vector3.ZERO, Vector3(0.004, 0.02, 0.004), Color(0.05, 0.04, 0.04))
	# flame: nested cones, white-hot core
	cyl(T(0, 0.27, 0), Vector3.ZERO, 0.03, 0.0, 0.11, 6, Color(1.0, 0.55, 0.15), true, "glow")
	cyl(T(0, 0.275, 0), Vector3.ZERO, 0.015, 0.0, 0.07, 6, Color(1.0, 0.92, 0.6), true, "glow")
	halo(Vector3(0, 0.33, 0), 0.7, Color(1.0, 0.55, 0.2, 0.7), 0.0)
	halo(Vector3(0, 0.33, 0), 0.16, Color(1.0, 0.8, 0.5, 0.8), 1.0)
	pool(Vector3(0, 0.03, 0), 3.0, Color(1.0, 0.52, 0.18, 0.5))
