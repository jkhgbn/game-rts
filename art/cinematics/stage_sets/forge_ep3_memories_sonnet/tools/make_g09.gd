extends "res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/make_g04.gd"
## G09: the Hollow rubble at x 24. Stone actor (amber, pulsing) in a crater at local (0.3, -1.8).

const RUBBLE := Color(0.5, 0.47, 0.46)
const SOOT := Color(0.16, 0.14, 0.15)
const AMBER := Color(1.0, 0.6, 0.18)
const SPOS := Vector3(0.3, 0.0, -1.8)

var blocks: Array = []


func _block(x: float, z: float, s: float, sd: int, big := false) -> void:
	var y := gh(x, z)
	var yaw := h01(x, z, sd) * TAU
	var tilt := Vector3((h01(x, z, sd + 1) - 0.5) * 0.7, 0, (h01(x, z, sd + 2) - 0.5) * 0.7)
	var hs := Vector3(0.5 + h01(x, z, sd + 3) * 0.5, 0.35 + h01(x, z, sd + 4) * 0.4, 0.4 + h01(x, z, sd + 5) * 0.5) * s
	var col := RUBBLE.lerp(SOOT, h01(x, z, sd + 6) * 0.6)
	box(T(x, y + hs.y * 0.5, z, yaw, tilt), Vector3.ZERO, hs, col)
	if big:
		occl(Vector3(x, y + hs.y * 0.6, z), Vector3(hs.x, hs.y, hs.z) * 0.9)


func _pillar(x: float, z: float, h: float, yaw: float, lying: bool, sd: int) -> void:
	var y := gh(x, z)
	var col := Color(0.58, 0.55, 0.53)
	if lying:
		var xf := T(x, y + 0.4, z, yaw, Vector3(PI * 0.5 - 0.06, 0, 0))
		cyl(xf, Vector3.ZERO, 0.42, 0.4, h, 9, col, true)
		box(xf, Vector3(0, h * 0.5, 0.0), Vector3(0.5, 0.05, 0.5), col.darkened(0.2))
		occl(Vector3(x + sin(yaw) * h * 0.5, y + 0.4, z + cos(yaw) * h * 0.5), Vector3(0.5, 0.45, 0.5))
	else:
		var xf := T(x, y, z, yaw, Vector3(0.05, 0, -0.04))
		box(xf, Vector3(0, 0.2, 0), Vector3(0.6, 0.2, 0.6), col.darkened(0.15))
		cyl(xf, Vector3(0, 0.4, 0), 0.42, 0.38, h, 9, col, true)
		occl(Vector3(x, y + h * 0.5, z), Vector3(0.45, h * 0.5, 0.45))


func _beam(x: float, z: float, len: float, yaw: float, up: float) -> void:
	var xf := T(x, gh(x, z) + 0.18 + up * len * 0.5, z, yaw, Vector3(0, 0, up))
	box(xf, Vector3.ZERO, Vector3(0.12, 0.13, len * 0.5), Color(0.1, 0.08, 0.08))
	box(xf, Vector3(0, 0.02, len * 0.2), Vector3(0.125, 0.11, 0.06), Color(0.3, 0.12, 0.05), "pulse" if false else "lit")


func _shards(x: float, z: float, n: int, sd: int) -> void:
	for i in n:
		var a := TAU * i / n + h01(float(i), 1.0, sd)
		var d := 0.55 + h01(float(i), 2.0, sd) * 0.5
		var px := x + sin(a) * d
		var pz := z + cos(a) * d
		var xf := T(px, gh(px, pz) - 0.03, pz, a, Vector3(0.42 + h01(float(i), 3.0, sd) * 0.3, 0, 0))
		cyl(xf, Vector3.ZERO, 0.11, 0.0, 0.6 + h01(float(i), 4.0, sd) * 0.9, 4, Color(0.34, 0.3, 0.55), true)


func _arch(x: float, z: float, yaw: float) -> void:
	var xf := T(x, gh(x, z), z, yaw, Vector3(0, 0, 0.06))
	var c := Color(0.5, 0.47, 0.47)
	box(xf, Vector3(-1.4, 1.8, 0), Vector3(0.5, 1.8, 0.5), c)
	box(xf, Vector3(1.4, 1.1, 0), Vector3(0.5, 1.1, 0.5), c.darkened(0.1))
	for i in 7:
		var a := PI * (i + 0.5) / 9.0 + 0.15
		var p := Vector3(-cos(a) * 1.4, 3.4 + sin(a) * 1.15, 0)
		box(xf, p, Vector3(0.28, 0.2, 0.5), c.lerp(SOOT, h01(float(i), 1.0, 3) * 0.4))
	occl(Vector3(x - 1.4, 1.8, z), Vector3(0.5, 1.8, 0.5))


func _g09() -> void:
	off = Vector3(24, 0, 0)
	seedv = 9
	grime = 0.7
	amb_top = Color(0.3, 0.26, 0.36)
	amb_bot = Color(0.16, 0.13, 0.19)
	moon_dir = Vector3(-0.4, 0.4, -0.82).normalized()
	moon_col = Color(0.5, 0.6, 0.95)
	fill_dir = Vector3(0.3, 0.5, 0.8).normalized()
	fill_col = Color(0.08, 0.08, 0.14)
	mounds = [[SPOS.x, SPOS.z, 2.2, -0.42, 1], [-3.0, -4.0, 2.0, 0.5, 0], [4.5, -3.0, 1.6, 0.4, 0], [-1.5, 1.4, 1.2, 0.22, 0]]
	# occluders first
	_pillar(-2.6, -0.4, 3.4, 0.6, true, 1)
	_pillar(3.4, -5.2, 2.6, 0.2, false, 2)
	_pillar(-4.4, -6.0, 4.4, 0.0, false, 3)
	_pillar(4.2, 0.6, 1.8, -0.5, true, 4)
	occl(Vector3(-3.0, 0.8, -4.0), Vector3(1.6, 0.8, 1.4))
	occl(Vector3(4.5, 0.6, -3.0), Vector3(1.4, 0.6, 1.2))
	occl(Vector3(-1.5, 0.4, 1.4), Vector3(1.0, 0.4, 0.8))
	occl(Vector3(-2.0, 1.8, -8.8), Vector3(4.0, 1.8, 0.4))
	add_light(SPOS + Vector3(0, 0.55, 0.3), AMBER, 3.6, 8.5)
	add_light(SPOS + Vector3(0, 1.4, 0.0), Color(1.0, 0.5, 0.15), 1.2, 12.0, false)
	prep()
	var gcol := func(x: float, z: float) -> Color:
		var c := Color(0.30, 0.27, 0.25).lerp(Color(0.2, 0.18, 0.18), h01(x * 0.35, z * 0.35, 3))
		var d := Vector2(x - SPOS.x, z - SPOS.z).length()
		return c.lerp(Color(0.1, 0.07, 0.07), clampf(1.0 - d / 3.2, 0.0, 1.0) * 0.7)
	ground(-17.0, -17.0, 17.0, 9.0, 0.42, gcol, Color(0.03, 0.03, 0.06))
	blades(-8.0, -8.0, 8.0, 4.0, 500, Color(0.25, 0.28, 0.2), 6, 0.2)
	_pillar(-2.6, -0.4, 3.4, 0.6, true, 1)
	_pillar(3.4, -5.2, 2.6, 0.2, false, 2)
	_pillar(-4.4, -6.0, 4.4, 0.0, false, 3)
	_pillar(4.2, 0.6, 1.8, -0.5, true, 4)
	# rubble mounds of blocks
	for i in 60:
		var a := h01(float(i), 1.0, 21) * TAU
		var d := 2.6 + h01(float(i), 2.0, 21) * 7.5
		var px := SPOS.x + sin(a) * d * 1.3
		var pz := SPOS.z + cos(a) * d * 0.9
		if pz > 3.0:
			continue
		_block(px, pz, 0.5 + h01(float(i), 3.0, 21) * 0.5, 30 + i, d < 5.0)
	for i in 14:
		_block(-3.0 + (h01(float(i), 1.0, 5) - 0.5) * 2.4, -4.0 + (h01(float(i), 2.0, 5) - 0.5) * 2.0, 0.8, 70 + i)
		_block(4.5 + (h01(float(i), 1.0, 6) - 0.5) * 2.0, -3.0 + (h01(float(i), 2.0, 6) - 0.5) * 1.8, 0.7, 90 + i)
	_beam(-1.8, 2.2, 3.4, 0.35, 0.0)
	_beam(2.4, -0.4, 2.6, -0.7, 0.25)
	_beam(-5.0, -3.4, 3.8, 1.2, 0.5)
	_arch(-1.5, -9.0, 0.1)
	_shards(SPOS.x, SPOS.z, 9, 4)
	# broken tower stump in the back
	var tx := 7.5
	var tz := -10.0
	for i in 3:
		cyl(T(tx, gh(tx, tz) + i * 2.0, tz, i * 0.4), Vector3.ZERO, 2.4 - i * 0.05, 2.35 - i * 0.05, 2.0, 12, RUBBLE.darkened(0.2 * i * 0.3), false)
	for k in 6:
		var a := TAU * k / 6.0
		box(T(tx + sin(a) * 2.1, 6.0, tz + cos(a) * 2.1, a), Vector3(0, 0.4 + h01(float(k), 1.0, 7), 0), Vector3(0.7, 0.4 + h01(float(k), 1.0, 7), 0.4), RUBBLE.darkened(0.3))
	# story props: toy horse, cracked bell, candle stub
	var tp := T(-0.9, gh(-0.9, 2.4) + 0.02, 2.4, 0.7, Vector3(0.0, 0, 0.5))
	box(tp, Vector3(0, 0.12, 0), Vector3(0.15, 0.06, 0.05), Color(0.5, 0.35, 0.2))
	box(tp, Vector3(0.12, 0.2, 0), Vector3(0.04, 0.09, 0.04), Color(0.5, 0.35, 0.2))
	for lx in [-0.1, 0.1]:
		box(tp, Vector3(lx, 0.03, 0.03), Vector3(0.015, 0.06, 0.015), Color(0.4, 0.28, 0.16))
	var bx := T(3.0, gh(3.0, 0.4) + 0.3, 0.4, 0.4, Vector3(1.2, 0, 0.2))
	cyl(bx, Vector3.ZERO, 0.38, 0.18, 0.55, 10, Color(0.42, 0.3, 0.16), true)
	cyl(T(1.4, gh(1.4, 0.2), 0.2), Vector3.ZERO, 0.035, 0.03, 0.08, 8, Color(0.85, 0.8, 0.68))
	cyl(T(1.4, gh(1.4, 0.2) + 0.08, 0.2), Vector3.ZERO, 0.02, 0.0, 0.05, 5, Color(1.0, 0.6, 0.2), true, "glow")
	halo(Vector3(1.4, 0.16, 0.2), 0.4, Color(1.0, 0.55, 0.2, 0.5), 0.0)
	# glowing cracks radiating from the stone (pulse)
	for k in 9:
		var a := TAU * k / 9.0 + h01(float(k), 1.0, 15) * 0.5
		var len := 1.6 + h01(float(k), 2.0, 15) * 2.2
		var px := SPOS.x
		var pz := SPOS.z
		var dirv := Vector2(sin(a), cos(a))
		for s in 4:
			var seg := len / 4.0
			var ang := a + (h01(float(k), float(s), 16) - 0.5) * 0.9
			var cx := px + sin(ang) * seg * 0.5
			var cz := pz + cos(ang) * seg * 0.5
			var y := gh(cx, cz) + 0.045
			var w := 0.06 * (1.0 - s * 0.2)
			var pv := Vector3(cx, y, cz) + off
			var bs := Basis(Vector3.UP, ang)
			var hx := bs * Vector3(w, 0, 0)
			var hz := bs * Vector3(0, 0, seg * 0.55)
			var cc := AMBER * (1.0 - s * 0.18)
			_emit(_st("pulse"), pv - hx - hz, pv + hx - hz, pv + hx + hz, cc, cc, cc, Vector3.UP)
			_emit(_st("pulse"), pv - hx - hz, pv + hx + hz, pv - hx + hz, cc, cc, cc, Vector3.UP)
			px += sin(ang) * seg
			pz += cos(ang) * seg
		dirv = dirv
	# smoke and embers
	for i in 10:
		var sx := -6.0 + h01(float(i), 1.0, 40) * 12.0
		var sz := -8.0 + h01(float(i), 2.0, 40) * 6.0
		for k in 4:
			mist(Vector3(sx + k * 0.4, 1.0 + k * 1.4, sz), 1.6 + k * 0.7, Color(0.16, 0.14, 0.2, 0.22), 0.25)
	for i in 12:
		mist(Vector3(-9.0 + i * 1.6, 0.5 + h01(float(i), 1.0, 41) * 0.5, -7.0 + h01(float(i), 2.0, 41) * 9.0), 3.0, Color(0.24, 0.2, 0.26, 0.2), 0.2)
	for i in 22:
		halo(Vector3(SPOS.x + (h01(float(i), 1.0, 42) - 0.5) * 8.0, 0.4 + h01(float(i), 2.0, 42) * 4.5, SPOS.z + (h01(float(i), 3.0, 42) - 0.5) * 7.0), 0.07, Color(1.0, 0.6, 0.25, 0.7), 1.0)


func _stone_actor() -> void:
	seedv = 11
	amb_top = Color(0.3, 0.26, 0.3)
	amb_bot = Color(0.15, 0.12, 0.14)
	moon_col = Color(0.3, 0.35, 0.55)
	fill_col = Color(0.05, 0.05, 0.08)
	add_light(Vector3(0, 0.5, 1.0), AMBER, 1.6, 4.0, false)
	prep()
	var rock := Color(0.32, 0.28, 0.3)
	var xf := T(0, -0.05, 0, 0.3, Vector3(0.06, 0, -0.08))
	cyl(xf, Vector3.ZERO, 0.42, 0.26, 1.0, 5, rock, true)
	cyl(xf, Vector3(0.05, 1.0, 0), 0.25, 0.05, 0.25, 5, rock.lightened(0.1), true)
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		var top := Vector3(sin(a) * 0.3, 0.98, cos(a) * 0.3)
		var bot := Vector3(sin(a) * 0.4, 0.1, cos(a) * 0.4)
		var w := Basis(Vector3.UP, a) * Vector3(0.025, 0, 0)
		var pn := Vector3(sin(a), 0, cos(a)) * 0.02
		_emit(_st("pulse"), bot - w + pn, bot + w + pn, top + w + pn, AMBER, AMBER, AMBER * 1.3, Vector3.UP)
		_emit(_st("pulse"), bot - w + pn, top + w + pn, top - w + pn, AMBER, AMBER * 1.3, AMBER * 1.3, Vector3.UP)
	halo(Vector3(0, 0.75, 0), 2.6, Color(1.0, 0.55, 0.15, 0.55), 0.0, "hpulse")
	halo(Vector3(0, 0.75, 0), 0.7, Color(1.0, 0.8, 0.4, 0.7), 0.0, "hpulse")
	pool(Vector3(0, 0.06, 0), 4.2, Color(1.0, 0.5, 0.14, 0.6), "hpulse")
	pool(Vector3(0, 0.06, 0), 1.4, Color(1.0, 0.6, 0.2, 0.5), "hpulse")
