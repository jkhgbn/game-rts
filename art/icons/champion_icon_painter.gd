extends "res://art/icons/icon_painter.gd"
## Champion icons (task A2.9), painted like icon_painter.gd (256 px, top-lit gradients, ink outline, soft glow) and
## downsampled to 128 by render_icons.gd. `faction` holds the champion id (wayfinder, oathwall, coin_cutter, mender):
## it picks the colour code (Wayfinder amber, Oathwall steel-blue, Coin-Cutter gold on burgundy, Mender green).
## Kinds: `abilities` (the 12 emblems of champions.md 4.3) and `bg` (the portrait background behind the rendered model).
## Step 11 (task 11.V7): `classes` (id = class id: spear, sword_shield, two_hand, wizard; one bold weapon silhouette that
## reads at 14 px) and `abilities` with `faction` = a class id (the 12 class skills of skills-rework.md 4.2), painted in
## the class colour code (Spear teal, Sword and Shield crimson, Two-Hand Sword forge orange, Wizard violet).
## Anything else falls back to icon_painter.gd.

const CHAMP_GLOW := {
	&"wayfinder": Color(1.0, 0.70, 0.30),
	&"oathwall": Color(0.48, 0.72, 1.0),
	&"coin_cutter": Color(1.0, 0.82, 0.32),
	&"mender": Color(0.45, 1.0, 0.58),
}
const CHAMP_INNER := {
	&"wayfinder": Color(0.16, 0.12, 0.07),
	&"oathwall": Color(0.09, 0.11, 0.15),
	&"coin_cutter": Color(0.22, 0.06, 0.09),
	&"mender": Color(0.07, 0.13, 0.10),
}
const AMBER := Color(1.0, 0.70, 0.30)
const AMBER_PALE := Color(1.0, 0.92, 0.70)
const ROPE := Color(0.80, 0.64, 0.40)
const MOSS := Color(0.35, 0.40, 0.28)
const LEATHER := Color(0.46, 0.30, 0.16)
const IRON := Color(0.50, 0.52, 0.57)
const OAK := Color(0.46, 0.31, 0.16)
const RUNE := Color(0.60, 0.85, 1.0)
const BURGUNDY := Color(0.55, 0.13, 0.17)
const BRASS := Color(0.74, 0.58, 0.26)
const CHARCOAL := Color(0.20, 0.19, 0.22)
const SMOKE := Color(0.56, 0.52, 0.58)
const MEND := Color(0.45, 1.0, 0.58)
const MEND_LIQ := Color(0.30, 0.85, 0.42)
const COPPER := Color(0.74, 0.46, 0.24)
const ROSE := Color(0.92, 0.30, 0.36)
const FOE := Color(0.90, 0.30, 0.22)
## Class colour codes (step 11): hues the four archetypes do not use (amber, steel-blue, gold / burgundy, green).
const CLASS_GLOW := {
	&"spear": Color(0.30, 0.92, 0.80),
	&"sword_shield": Color(1.0, 0.28, 0.36),
	&"two_hand": Color(1.0, 0.56, 0.12),
	&"wizard": Color(0.72, 0.52, 1.0),
}
const CLASS_INNER := {
	&"spear": Color(0.04, 0.12, 0.12),
	&"sword_shield": Color(0.15, 0.04, 0.07),
	&"two_hand": Color(0.15, 0.08, 0.035),
	&"wizard": Color(0.09, 0.06, 0.17),
}
const ASH := Color(0.80, 0.64, 0.42)
const BOLT := Color(0.6, 0.75, 1.0)   # the Wizard class bolt / staff crystal colour (skills-rework.md 3 and 5)
const HEAT := Color(1.0, 0.62, 0.20)


func _draw() -> void:
	if CLASS_GLOW.has(id) and kind == &"classes":
		faction = id
		_class_icon()
		return
	if CLASS_GLOW.has(faction) and kind == &"abilities":
		_class_skill()
		return
	if CHAMP_GLOW.has(faction):
		match kind:
			&"abilities":
				_ability()
				return
			&"bg", &"units":
				if faction == &"oathwall":
					# The pale iron helm needs a deeper backdrop to read at 56 / 32 px: navy + a deeper steel-blue halo.
					draw_rect(Rect2(0, 0, 256, 256), Color(0.045, 0.06, 0.10))
					_disc(C + Vector2(0, 10), 176, Color(0.28, 0.50, 0.90, 0.30), Color(0.28, 0.50, 0.90, 0.0), 48)
				else:
					_champ_bg(0.36)
				return
	super._draw()


func _cglow() -> Color:
	return CHAMP_GLOW.get(faction, CLASS_GLOW.get(faction, FIRE_GLOW))


## Flat inner colour + radial halo in the champion (or class) colour (spells use 0.5, portraits about 0.35).
func _champ_bg(alpha: float) -> void:
	draw_rect(Rect2(0, 0, 256, 256), CHAMP_INNER.get(faction, CLASS_INNER.get(faction, Color(0.14, 0.11, 0.11))))
	if faction == &"coin_cutter":
		_disc(C, 182, Color(0.62, 0.14, 0.18, alpha * 0.9), Color(0.62, 0.14, 0.18, 0.0), 48)
		_disc(C, 150, Color(_cglow(), alpha * 0.55), Color(_cglow(), 0.0), 48)
	else:
		_disc(C, 182, Color(_cglow(), alpha), Color(_cglow(), 0.0), 48)


# ---------------------------------------------------------------- helpers
## Point at distance `dist` along a polyline, and the unit direction there.
func _along(pts: PackedVector2Array, dist: float) -> Array:
	var acc: float = 0.0
	for i in range(1, pts.size()):
		var seg: Vector2 = pts[i] - pts[i - 1]
		var l: float = seg.length()
		if l <= 0.0:
			continue
		if acc + l >= dist:
			return [pts[i - 1] + seg * ((dist - acc) / l), seg / l]
		acc += l
	var last: Vector2 = pts[pts.size() - 1] - pts[pts.size() - 2]
	return [pts[pts.size() - 1], last.normalized()]


func _length(pts: PackedVector2Array) -> float:
	var l: float = 0.0
	for i in range(1, pts.size()):
		l += pts[i].distance_to(pts[i - 1])
	return l


## Twisted rope: inked stroke with diagonal twist marks.
func _rope(pts: PackedVector2Array, w: float, col: Color = ROPE) -> void:
	_stroke(pts, w, col, 6.0)
	var total: float = _length(pts)
	var s: float = 6.0
	while s < total - 4.0:
		var a: Array = _along(pts, s)
		var p: Vector2 = a[0]
		var d: Vector2 = a[1]
		var n := Vector2(-d.y, d.x)
		draw_line(p - n * w * 0.42 - d * w * 0.3, p + n * w * 0.42 + d * w * 0.3, col.darkened(0.45), maxf(2.0, w * 0.18), true)
		s += w * 1.05
	var hl := PackedVector2Array()
	for i in pts.size():
		var d2: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var n2 := Vector2(-d2.y, d2.x)
		if n2.dot(Vector2(-1, -1)) < 0.0:
			n2 = -n2
		hl.append(pts[i] + n2 * w * 0.22)
	draw_polyline(hl, Color(1, 1, 0.9, 0.35), maxf(1.5, w * 0.16), true)


func _coin(c: Vector2, r: float, squash: float = 1.0, ang: float = 0.0) -> void:
	_xf(c, ang)
	_poly(_ell(Vector2.ZERO, r, r * squash, 32), GOLD.lightened(0.35), GOLD.darkened(0.4), maxf(3.0, r * 0.2))
	var inner := _ell(Vector2.ZERO, r * 0.68, r * 0.68 * squash, 28)
	inner.append(inner[0])
	draw_polyline(inner, GOLD.darkened(0.45), maxf(2.0, r * 0.12), true)
	if squash > 0.9:
		draw_arc(Vector2.ZERO, r * 0.82, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.55), maxf(2.0, r * 0.12), true)
	_rs()


## Loot pouch: round bottom, ruffled neck, brass tie band. Centre = belly; about 116 x 130 at s = 1.
func _pouch(c: Vector2, s: float, col: Color, ang: float = 0.0) -> void:
	_xf(c, ang, Vector2(s, s))
	var body := PackedVector2Array([Vector2(-16, -40), Vector2(-40, -20), Vector2(-56, 8)])
	body.append_array(_ell(Vector2(0, 12), 58, 48, 18, PI, 0.0))
	body.append_array(PackedVector2Array([Vector2(40, -20), Vector2(16, -40)]))
	_shape(body, col)
	draw_arc(Vector2(0, 12), 44, PI * 1.08, PI * 1.38, 12, Color(1, 1, 1, 0.35), 7, true)
	draw_polyline(PackedVector2Array([Vector2(-8, -30), Vector2(-14, 10), Vector2(-4, 44)]), col.darkened(0.45), 3, true)
	draw_polyline(PackedVector2Array([Vector2(14, -28), Vector2(22, 8), Vector2(18, 40)]), col.darkened(0.45), 3, true)
	_shape(PackedVector2Array([Vector2(-16, -40), Vector2(-34, -66), Vector2(-12, -56), Vector2(0, -72), Vector2(12, -56),
		Vector2(34, -66), Vector2(16, -40)]), col.lightened(0.12), 5.0)
	_shape(_rect(Vector2(-22, -48), Vector2(22, -36)), BRASS, 4.0)
	_rs()


## Door-sized oak shield with iron rim, bands, rivets and the steel-blue rune boss. Corners tl, tr, br, bl.
func _tower_shield(q: PackedVector2Array, glow: float = 1.0) -> void:
	var tl: Vector2 = q[0]
	var tr: Vector2 = q[1]
	var br: Vector2 = q[2]
	var bl: Vector2 = q[3]
	_poly(q, OAK.lightened(0.32), OAK.darkened(0.35), 7.0)
	for k in [1, 2, 3, 4]:
		var t: float = float(k) / 5.0
		draw_line(tl.lerp(tr, t), bl.lerp(br, t), Color(0.16, 0.09, 0.04, 0.7), 4, true)
	for t in [0.2, 0.8]:
		var a: Vector2 = tl.lerp(bl, t)
		var b: Vector2 = tr.lerp(br, t)
		_stroke(PackedVector2Array([a, b]), 11, IRON, 4.0)
		draw_line(a + Vector2(0, -3), b + Vector2(0, -3), Color(1, 1, 1, 0.35), 3, true)
		for u in [0.12, 0.5, 0.88]:
			draw_circle(a.lerp(b, u), 4.5, INK)
			draw_circle(a.lerp(b, u) + Vector2(-1, -1), 2.6, IRON.lightened(0.5))
	var rim := q.duplicate()
	rim.append(q[0])
	draw_polyline(rim, INK, 16, true)
	draw_polyline(rim, IRON.lightened(0.1), 9, true)
	draw_polyline(PackedVector2Array([bl, tl, tr]), Color(1, 1, 1, 0.35), 3, true)
	var c: Vector2 = (tl + tr + br + bl) * 0.25
	var r: float = tl.distance_to(tr) * 0.2
	_glow(c, r * 2.2, Color(RUNE, 0.6 * glow))
	_ball(c, r, IRON, 5.0)
	_poly(PackedVector2Array([c + Vector2(0, -r * 0.62), c + Vector2(r * 0.4, 0), c + Vector2(0, r * 0.62), c + Vector2(-r * 0.4, 0)]),
		Color(0.95, 1.0, 1.0), RUNE, 0.0)


func _plus(p: Vector2, s: float, top: Color, bottom: Color, ow: float = 4.0) -> void:
	var plus: Array[PackedVector2Array] = Geometry2D.merge_polygons(_rect(p + Vector2(-s, -s * 0.34), p + Vector2(s, s * 0.34)),
		_rect(p + Vector2(-s * 0.34, -s), p + Vector2(s * 0.34, s)))
	if plus.size() > 0:
		_poly(plus[0], top, bottom, ow)


## Arrowhead pointing from `from` to `to` (tip at `to`).
func _dart(from: Vector2, to: Vector2, w: float, col: Color) -> void:
	var d: Vector2 = (to - from).normalized()
	var n := Vector2(-d.y, d.x)
	var l: float = from.distance_to(to)
	_poly(PackedVector2Array([to, from + n * w * 0.5, from + d * l * 0.3, from - n * w * 0.5]), col.lightened(0.3), col.darkened(0.3), 5.0)


func _ground(c: Vector2, rx: float, ry: float, col: Color) -> void:
	_poly(_ell(c, rx, ry), col.lightened(0.1), col.darkened(0.45), 6.0)


# ---------------------------------------------------------------- abilities
func _ability() -> void:
	_champ_bg(0.5)
	match id:
		&"flare_arrow": _flare_arrow()
		&"snare_line": _snare_line()
		&"trailblaze": _trailblaze()
		&"oath_of_iron": _oath_of_iron()
		&"shield_bash": _shield_bash()
		&"bulwark_stand": _bulwark_stand()
		&"cutpurse": _cutpurse()
		&"smoke_pouch": _smoke_pouch()
		&"marked_for_coin": _marked_for_coin()
		&"mending_draught": _mending_draught()
		&"soothing_circle": _soothing_circle()
		&"lifeline": _lifeline()
		_: _star4(C, 70, _cglow())


## Arrow shot up-right, its head bursting into a flare that lights a dashed circle (the revealed area).
func _flare_arrow() -> void:
	var fc := Vector2(172, 82)
	var tail := Vector2(34, 226)
	var d: Vector2 = (fc - tail).normalized()
	var n := Vector2(-d.y, d.x)
	# light trail
	_poly(_tube(PackedVector2Array([tail, tail.lerp(fc, 0.55), fc]), 2, 46), Color(AMBER_PALE, 0.75), Color(AMBER, 0.0), 0.0)
	# revealed circle, dashed
	for k in 12:
		var a0: float = TAU * float(k) / 12.0
		draw_arc(fc, 70, a0, a0 + TAU / 24.0, 6, Color(AMBER_PALE, 0.85), 5, true)
	# shaft + fletching
	var shaft_end: Vector2 = fc - d * 26.0
	_stroke(PackedVector2Array([tail + d * 8.0, shaft_end]), 9, WOOD.lightened(0.3), 6.0)
	for s in [-1.0, 1.0]:
		_poly(PackedVector2Array([tail + d * 12.0, tail + d * 56.0, tail + d * 44.0 + n * s * 22.0, tail + d * 2.0 + n * s * 24.0]),
			Color(0.95, 0.55, 0.30), Color(0.62, 0.24, 0.12), 5.0)
	# flare burst
	_glow(fc, 96, Color(AMBER, 0.75))
	for k in 10:
		var a: float = TAU * float(k) / 10.0 + 0.2
		var dir := Vector2(cos(a), sin(a))
		var ray: float = 62.0 if k % 2 == 0 else 40.0
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([fc + side * 7.0, fc + dir * ray, fc - side * 7.0]), Color(AMBER_PALE, 0.8))
	_dart(fc - d * 30.0, fc + d * 6.0, 30, STEEL)
	draw_circle(fc, 24, Color(1, 0.98, 0.85))
	_glow(fc, 40, Color(1, 1, 0.9, 0.9))
	_star4(fc, 34, Color.WHITE)
	_sparks(Vector2(150, 110), 100, 5, AMBER, 81)


## A hunter's snare: iron stake in the ground, rope running to a tightening noose.
func _snare_line() -> void:
	_ground(Vector2(128, 216), 112, 30, Color(0.36, 0.27, 0.16))
	# pull marks: the noose closing
	var lc := Vector2(150, 104)
	for a in [PI * 1.05, PI * 1.5, PI * 1.95, PI * 0.25]:
		var dir := Vector2(cos(a), sin(a))
		_stroke(PackedVector2Array([lc + dir * 96.0, lc + dir * 80.0]), 6, AMBER_PALE, 4.0)
	# stake
	_poly(PackedVector2Array([Vector2(48, 132), Vector2(66, 132), Vector2(64, 214), Vector2(57, 232), Vector2(50, 214)]),
		IRON.lightened(0.3), IRON.darkened(0.35), 6.0)
	_shape(_rect(Vector2(42, 124), Vector2(72, 138)), IRON.darkened(0.1), 5.0)
	draw_arc(Vector2(57, 116), 11, 0, TAU, 20, INK, 11, true)
	draw_arc(Vector2(57, 116), 11, 0, TAU, 20, IRON.lightened(0.35), 5, true)
	# rope from the stake ring to the knot
	_rope(_bez(Vector2(62, 124), Vector2(96, 204), Vector2(150, 178), 18), 13)
	# noose loop
	var loop := PackedVector2Array()
	for i in 29:
		var a: float = PI * 0.5 + 0.34 + (TAU - 0.68) * float(i) / 28.0
		loop.append(lc + Vector2(cos(a) * 56.0, sin(a) * 66.0))
	_rope(loop, 14)
	# slip knot (wrapped coils)
	_xf(Vector2(150, 176), 0.0)
	_shape(_rect(Vector2(-15, -14), Vector2(15, 14)), ROPE.darkened(0.08), 5.0)
	for k in 3:
		var y: float = -9.0 + k * 9.0
		draw_line(Vector2(-14, y - 3), Vector2(14, y + 3), ROPE.darkened(0.5), 3, true)
	_rs()
	_rope(PackedVector2Array([Vector2(150, 190), Vector2(154, 206), Vector2(166, 214)]), 10)
	_glow(lc, 40, Color(AMBER, 0.35))
	_sparks(lc, 70, 4, AMBER, 83)


## A trail running into the distance with glowing blaze chevrons: haste for everyone on it.
func _trailblaze() -> void:
	var road := PackedVector2Array([Vector2(106, 52), Vector2(150, 52), Vector2(230, 246), Vector2(26, 246)])
	_glow(Vector2(128, 50), 70, Color(AMBER_PALE, 0.7))
	_poly(road, Color(0.62, 0.48, 0.28), Color(0.34, 0.24, 0.12), 6.0)
	for s in [-1.0, 1.0]:
		var e0: Vector2 = Vector2(128 + s * 22, 52)
		var e1: Vector2 = Vector2(128 + s * 102, 246)
		draw_line(e0.lerp(e1, 0.05), e0.lerp(e1, 0.98), Color(0.22, 0.14, 0.06, 0.6), 4, true)
	# chevrons, big near, small far
	for k in 3:
		var y: float = 212.0 - k * 58.0
		var sc: float = 1.0 - k * 0.24
		var w: float = 76.0 * sc
		var h: float = 34.0 * sc
		var col := AMBER.lerp(AMBER_PALE, float(k) / 2.0)
		_glow(Vector2(128, y - h * 0.4), w * 0.9, Color(AMBER, 0.45))
		var chev := PackedVector2Array([Vector2(128 - w, y + h * 0.3), Vector2(128, y - h), Vector2(128 + w, y + h * 0.3),
			Vector2(128 + w * 0.62, y + h * 0.3 + h * 0.5), Vector2(128, y - h * 0.34), Vector2(128 - w * 0.62, y + h * 0.3 + h * 0.5)])
		_poly(chev, col.lightened(0.35), col.darkened(0.2), 5.0)
	# wind streaks
	for st in [[Vector2(18, 150), Vector2(56, 104)], [Vector2(32, 200), Vector2(62, 162)], [Vector2(238, 150), Vector2(200, 104)],
			[Vector2(224, 200), Vector2(194, 162)]]:
		draw_line(st[0], st[1], Color(1, 1, 1, 0.55), 5, true)
	_star4(Vector2(128, 44), 22, Color.WHITE)


## The flat iron helm with its glowing visor; enemies' arrows point in at it (taunt), a ring of iron around.
func _oath_of_iron() -> void:
	var c := Vector2(128, 132)
	draw_arc(c, 108, 0, TAU, 64, INK, 13, true)
	draw_arc(c, 108, 0, TAU, 64, Color(RUNE, 0.85), 6, true)
	for a in [PI * 1.25, PI * 1.75, PI * 0.75, PI * 0.25]:
		var dir := Vector2(cos(a), sin(a))
		_dart(c + dir * 126.0, c + dir * 92.0, 34, FOE)
	var helm := PackedVector2Array([Vector2(80, 70), Vector2(94, 48), Vector2(162, 48), Vector2(176, 70), Vector2(184, 172),
		Vector2(162, 206), Vector2(94, 206), Vector2(72, 172)])
	_poly(helm, IRON.lightened(0.38), IRON.darkened(0.42), 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(128, 48), Vector2(162, 48), Vector2(176, 70), Vector2(184, 172),
		Vector2(162, 206), Vector2(128, 206)]), Color(0, 0, 0.05, 0.22))
	_stroke(PackedVector2Array([Vector2(80, 76), Vector2(176, 76)]), 9, IRON.lightened(0.15), 4.0)
	draw_line(Vector2(128, 50), Vector2(128, 108), Color(1, 1, 1, 0.4), 5, true)
	# visor
	_poly(_rect(Vector2(82, 108), Vector2(174, 128)), Color(0.03, 0.04, 0.07), Color(0.08, 0.1, 0.14), 5.0)
	_glow(Vector2(128, 118), 60, Color(RUNE, 0.7))
	draw_line(Vector2(90, 118), Vector2(166, 118), Color(0.9, 0.97, 1.0), 5, true)
	for x in [110.0, 146.0]:
		for y in [150.0, 168.0, 186.0]:
			draw_circle(Vector2(x, y), 4, Color(0.08, 0.08, 0.1))
	for p in [Vector2(90, 90), Vector2(166, 90), Vector2(86, 176), Vector2(170, 176)]:
		_ball(p, 5, IRON.lightened(0.2), 3.0)
	draw_polyline(PackedVector2Array([Vector2(78, 168), Vector2(82, 76), Vector2(96, 54)]), Color(1, 1, 1, 0.3), 4, true)


## The door shield thrust forward into a burst; dazed stars over the hit.
func _shield_bash() -> void:
	for k in 4:
		var y: float = 70.0 + k * 36.0
		draw_line(Vector2(10, y), Vector2(46 - (k % 2) * 14, y), Color(1, 1, 1, 0.5), 6, true)
	# impact burst
	var ic := Vector2(196, 128)
	_glow(ic, 84, Color(RUNE, 0.7))
	var burst := PackedVector2Array()
	for i in 16:
		var a: float = TAU * float(i) / 16.0
		var r: float = 58.0 if i % 2 == 0 else 26.0
		burst.append(ic + Vector2(cos(a), sin(a)) * r)
	_poly(burst, Color(1, 1, 1), Color(0.7, 0.88, 1.0), 5.0)
	_tower_shield(PackedVector2Array([Vector2(58, 40), Vector2(166, 58), Vector2(166, 204), Vector2(58, 222)]))
	for sp in [Vector2(204, 40), Vector2(234, 66), Vector2(176, 30)]:
		_star4(sp, 16, Color(1.0, 0.95, 0.6))


## The shield planted in cracked ground, a wall of steel-blue light spreading behind it (braced).
func _bulwark_stand() -> void:
	var gc := Vector2(128, 208)
	_ground(gc, 112, 32, Color(0.34, 0.33, 0.36))
	var dome := _ell(gc, 116, 168, 32, PI, TAU)
	_poly(dome, Color(RUNE, 0.42), Color(RUNE, 0.12), 0.0)
	draw_polyline(dome, INK, 12, true)
	draw_polyline(dome, Color(0.82, 0.93, 1.0), 6, true)
	for k in [0.5]:
		draw_polyline(_ell(gc, 116.0 * k, 168, 20, PI, TAU), Color(RUNE, 0.4), 3, true)
	draw_polyline(_ell(gc + Vector2(0, -92), 96, 22, 24, 0.0, PI), Color(RUNE, 0.4), 3, true)
	# cracks
	for cr in [[Vector2(96, 212), Vector2(62, 206), Vector2(38, 214)], [Vector2(160, 214), Vector2(196, 204), Vector2(218, 212)],
			[Vector2(118, 222), Vector2(106, 234)], [Vector2(142, 222), Vector2(156, 236)]]:
		draw_polyline(PackedVector2Array(cr), Color(0.05, 0.05, 0.08), 6, true)
		draw_polyline(PackedVector2Array(cr), Color(RUNE, 0.8), 2.5, true)
	_tower_shield(PackedVector2Array([Vector2(78, 50), Vector2(178, 50), Vector2(178, 216), Vector2(78, 216)]), 1.3)
	# dirt kicked up at its foot
	for p in [Vector2(70, 214), Vector2(186, 214), Vector2(98, 226), Vector2(160, 226)]:
		_poly(_ell(p, 9, 6, 8), Color(0.45, 0.42, 0.44), Color(0.2, 0.2, 0.22), 3.0)


## A curved knife cuts the purse strings: coins tumble out.
func _cutpurse() -> void:
	_pouch(Vector2(100, 154), 1.05, BURGUNDY, -0.25)
	# slash arc across the neck
	var slash := _bez(Vector2(30, 60), Vector2(92, 120), Vector2(220, 92), 20)
	draw_polyline(slash, Color(1, 0.95, 0.8, 0.35), 18, true)
	draw_polyline(slash, Color(1, 1, 1, 0.95), 6, true)
	# cut string end, falling away
	_stroke(PackedVector2Array([Vector2(70, 84), Vector2(56, 90), Vector2(46, 104)]), 5, ROPE, 4.0)
	# knife: charcoal grip, brass guard, curved blade pointing down-left along the cut
	var blade := _bez(Vector2(196, 78), Vector2(176, 116), Vector2(132, 124), 16)
	_poly(_tube(blade, 26, 0.0), Color(0.92, 0.94, 0.98), STEEL.darkened(0.3), 6.0)
	draw_polyline(_bez(Vector2(192, 82), Vector2(174, 110), Vector2(140, 118), 12), Color(1, 1, 1, 0.7), 3, true)
	_stroke(PackedVector2Array([Vector2(184, 70), Vector2(210, 88)]), 10, BRASS, 5.0)
	_stroke(PackedVector2Array([Vector2(200, 72), Vector2(230, 30)]), 14, CHARCOAL.lightened(0.15), 6.0)
	_ball(Vector2(232, 26), 8, BRASS, 4.0)
	# spilled coins
	_coin(Vector2(166, 190), 20, 1.0)
	_coin(Vector2(206, 170), 16, 0.45, 0.6)
	_coin(Vector2(196, 222), 18, 1.0)
	_coin(Vector2(146, 230), 14, 0.5, -0.3)
	_sparks(Vector2(186, 196), 50, 4, GOLD, 91)


## A pouch bursting into a cloud of smoke; the Coin-Cutter's gold eye bar in it.
func _smoke_pouch() -> void:
	var lobes: Array = [[Vector2(70, 132), 44.0], [Vector2(186, 128), 46.0], [Vector2(102, 84), 48.0], [Vector2(158, 78), 46.0],
		[Vector2(128, 128), 62.0], [Vector2(84, 176), 34.0], [Vector2(176, 176), 36.0], [Vector2(128, 44), 30.0]]
	for lb in lobes:
		draw_circle(lb[0], lb[1] + 4.0, INK)
	for lb in lobes:
		_disc(lb[0], lb[1], SMOKE.lightened(0.3), SMOKE.darkened(0.3))
	for lb in lobes:
		_glow(lb[0] + Vector2(-lb[1], -lb[1]) * 0.3, lb[1] * 0.5, Color(1, 1, 1, 0.28))
	# the hidden face: gold eye bar
	_poly(_ell(Vector2(128, 116), 50, 20, 24), Color(0.06, 0.04, 0.06), Color(0.14, 0.08, 0.12), 0.0)
	for e in [Vector2(108, 116), Vector2(148, 116)]:
		_glow(e, 20, Color(GOLD, 0.9))
		draw_colored_polygon(_ell(e, 11, 4, 12), Color(1.0, 0.95, 0.7))
	_pouch(Vector2(128, 206), 0.62, BURGUNDY, 0.0)
	for w in [[Vector2(106, 176), Vector2(90, 164)], [Vector2(150, 176), Vector2(168, 164)]]:
		draw_line(w[0], w[1], Color(1, 1, 1, 0.5), 5, true)


## A big gold coin stamped with a burgundy crosshair, locked inside target brackets.
func _marked_for_coin() -> void:
	var c := Vector2(128, 128)
	_glow(c, 110, Color(GOLD, 0.45))
	# flip arcs
	draw_arc(c, 94, PI * 0.95, PI * 1.35, 16, Color(1, 1, 1, 0.55), 5, true)
	draw_arc(c, 94, PI * 1.95, PI * 2.35, 16, Color(1, 1, 1, 0.55), 5, true)
	_coin(c, 74, 1.0)
	# crosshair stamped on the face
	var mark := Color(0.45, 0.07, 0.12)
	draw_arc(c, 32, 0, TAU, 36, mark, 8, true)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * 16.0, c + dir * 52.0, mark, 8, true)
	draw_circle(c, 7, mark)
	# target brackets
	for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var corner: Vector2 = c + q * 104.0
		_stroke(PackedVector2Array([corner - Vector2(0, q.y * 34.0), corner, corner - Vector2(q.x * 34.0, 0)]), 11, Color(0.85, 0.18, 0.22), 5.0)


## The Mender's green draught: round flask, a leaf on the cork, a plus rising from it.
func _mending_draught() -> void:
	_potion_round(MEND_LIQ, MEND)
	_leaf(Vector2(140, 48), Vector2(186, 26), 26, Color(0.46, 0.70, 0.30), -0.2)
	_glow(Vector2(196, 78), 44, Color(MEND, 0.7))
	_plus(Vector2(196, 78), 28, Color(0.95, 1.0, 0.95), MEND.darkened(0.1))
	_glow(Vector2(128, 176), 40, Color(0.8, 1.0, 0.85, 0.35))
	_sparks(Vector2(128, 150), 100, 4, MEND, 101)


## The censer-kettle swinging above a glowing ring; soothing mist and pluses rise inside it.
func _soothing_circle() -> void:
	var gc := Vector2(128, 200)
	_ground(gc, 110, 36, Color(0.22, 0.34, 0.24))
	var ring := _ell(gc, 94, 28)
	ring.append(ring[0])
	draw_polyline(ring, INK, 14, true)
	draw_polyline(ring, MEND, 7, true)
	# mist column
	_poly(PackedVector2Array([Vector2(104, 96), Vector2(152, 96), Vector2(214, 196), Vector2(42, 196)]), Color(MEND, 0.05), Color(MEND, 0.45), 0.0)
	for w in [[Vector2(80, 190), Vector2(64, 150), Vector2(88, 120)], [Vector2(176, 190), Vector2(196, 150), Vector2(168, 120)]]:
		draw_polyline(_bez(w[0], w[1], w[2], 12), Color(0.85, 1.0, 0.9, 0.6), 6, true)
	_plus(Vector2(128, 166), 24, Color(0.95, 1.0, 0.95), MEND.darkened(0.1))
	_plus(Vector2(76, 128), 14, Color(0.95, 1.0, 0.95), MEND.darkened(0.1), 3.0)
	_plus(Vector2(184, 122), 14, Color(0.95, 1.0, 0.95), MEND.darkened(0.1), 3.0)
	# chain + kettle
	for k in 3:
		var y: float = 4.0 + k * 13.0
		draw_arc(Vector2(128, y + 6), 6, 0, TAU, 12, INK, 6, true)
		draw_arc(Vector2(128, y + 6), 6, 0, TAU, 12, IRON.lightened(0.3), 3, true)
	var kc := Vector2(128, 72)
	_shape(PackedVector2Array([kc + Vector2(30, 0), kc + Vector2(64, -18), kc + Vector2(70, -14), kc + Vector2(40, 12)]), COPPER, 5.0)
	draw_circle(kc, 38, INK)
	_disc(kc, 35, COPPER.lightened(0.35), COPPER.darkened(0.4))
	_shape(_rect(kc + Vector2(-26, -40), kc + Vector2(26, -30)), COPPER.darkened(0.15), 4.0)
	_glow(kc + Vector2(0, 8), 30, Color(MEND, 0.9))
	_poly(_ell(kc + Vector2(0, 8), 16, 7, 16), Color(0.9, 1.0, 0.9), MEND, 0.0)
	_sheen(kc, 26, PI * 1.05, PI * 1.45, 6)


## A heart held in a protective green bubble, a heartbeat line running through it.
func _lifeline() -> void:
	var c := Vector2(128, 128)
	_glow(c, 118, Color(MEND, 0.45))
	_disc(c, 98, Color(MEND, 0.05), Color(MEND, 0.4))
	var hp := _heart_pts(c + Vector2(0, 2), 0.62)
	_poly(hp, ROSE.lightened(0.3), ROSE.darkened(0.35), 6.0)
	_sheen(c + Vector2(-24, -24), 16, PI * 1.05, PI * 1.5, 5)
	var pulse := PackedVector2Array([Vector2(8, 138), Vector2(70, 138), Vector2(88, 116), Vector2(104, 170), Vector2(128, 72),
		Vector2(148, 158), Vector2(162, 128), Vector2(182, 138), Vector2(248, 138)])
	draw_polyline(pulse, INK, 16, true)
	draw_polyline(pulse, Color(MEND, 0.6), 14, true)
	draw_polyline(pulse, Color(0.92, 1.0, 0.94), 6, true)
	draw_arc(c, 98, 0, TAU, 64, INK, 11, true)
	draw_arc(c, 98, 0, TAU, 64, Color(0.75, 1.0, 0.8), 5, true)
	_sheen(c, 84, PI * 1.1, PI * 1.42, 8)


# ================================================================ step 11 (task 11.V7): classes and class skills
# ---------------------------------------------------------------- class weapons (shared by the class icons and skills)
## The side of a direction's normal that faces the top-left light.
func _lit_side(d: Vector2) -> Vector2:
	var n := Vector2(-d.y, d.x)
	return n if n.dot(Vector2(-1, -1)) > 0.0 else -n


## Leaf-shaped spear blade from `base` to `tip` (widest ~40 % up), steel with a mid-rib and a lit edge.
func _leaf_blade(base: Vector2, tip: Vector2, w: float, root_w: float, ow: float) -> void:
	var d: Vector2 = (tip - base).normalized()
	var n := Vector2(-d.y, d.x)
	var l: float = base.distance_to(tip)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 17:
		var t: float = float(i) / 16.0
		var half: float = maxf(root_w * 0.5 * (1.0 - t), w * 0.5 * pow(sin(PI * pow(t, 0.75)), 0.9))
		half = maxf(half, 0.8)
		left.append(base + d * l * t + n * half)
		right.append(base + d * l * t - n * half)
	right.reverse()
	left.append_array(right)
	_poly(left, Color(0.93, 0.96, 1.0), STEEL.darkened(0.3), ow)
	draw_line(base + d * l * 0.06, base + d * l * 0.9, Color(0.1, 0.12, 0.18, 0.35), maxf(2.0, w * 0.08), true)
	var side: Vector2 = _lit_side(d)
	draw_line(base + d * l * 0.2 + side * w * 0.17, base + d * l * 0.72 + side * w * 0.1, Color(1, 1, 1, 0.75), maxf(2.0, w * 0.07), true)


## Spear from `butt` to `tip`: ash shaft, iron butt cap, brass socket, leaf blade and a class-colour tassel.
func _spear(butt: Vector2, tip: Vector2, shaft_w: float, blade_len: float, blade_w: float, ow: float = 6.0, tassel: bool = true) -> void:
	var d: Vector2 = (tip - butt).normalized()
	var base: Vector2 = tip - d * blade_len
	_stroke(PackedVector2Array([butt, base + d * 4.0]), shaft_w, ASH, ow)
	var side: Vector2 = _lit_side(d)
	draw_line(butt + d * shaft_w * 1.2 + side * shaft_w * 0.2, base - d * shaft_w + side * shaft_w * 0.2, Color(1, 1, 0.9, 0.45), maxf(2.0, shaft_w * 0.2), true)
	draw_line(butt + d * shaft_w * 1.2 - side * shaft_w * 0.22, base - d * shaft_w - side * shaft_w * 0.22, Color(0.25, 0.15, 0.05, 0.35), maxf(2.0, shaft_w * 0.18), true)
	_stroke(PackedVector2Array([butt - d * shaft_w * 0.1, butt + d * shaft_w * 0.9]), shaft_w * 1.12, IRON, ow)
	if tassel:
		var tc: Color = _cglow()
		var knot: Vector2 = base - d * shaft_w * 0.8
		for k in [-1.0, 0.0, 1.0]:
			var end: Vector2 = knot + Vector2(k * shaft_w * 0.7 - d.x * shaft_w * 0.6, shaft_w * 2.5)
			_poly(_tube(_bez(knot, knot + Vector2(k * shaft_w * 0.35, shaft_w * 1.1), end, 8), shaft_w * 0.85, shaft_w * 0.3),
				tc.lightened(0.3), tc.darkened(0.3), ow * 0.8)
		_ball(knot, shaft_w * 0.55, tc, ow * 0.8)
	_stroke(PackedVector2Array([base - d * shaft_w * 0.45, base + d * shaft_w * 0.45]), shaft_w * 1.3, BRASS, ow)
	_leaf_blade(base + d * shaft_w * 0.3, tip, blade_w, shaft_w * 0.9, ow)


## Straight sword, guard at `hilt`, blade toward local -y turned by `ang` (clockwise). `grip` = grip length; the
## greatsword is the same call with a long grip and a wide guard. `gem` (alpha > 0) sets a stone in the guard.
func _blade_sword(hilt: Vector2, ang: float, length: float, w: float, guard_w: float, grip: float, ow: float,
		guard_col: Color = BRASS, gem: Color = Color(0, 0, 0, 0)) -> void:
	_xf(hilt, ang)
	_poly(_rect(Vector2(-w * 0.2, 0), Vector2(w * 0.2, grip)), LEATHER.lightened(0.25), LEATHER.darkened(0.4), ow)
	var y: float = w * 0.3
	while y < grip - w * 0.1:
		draw_line(Vector2(-w * 0.18, y), Vector2(w * 0.18, y + w * 0.14), Color(0, 0, 0, 0.35), maxf(1.5, w * 0.06), true)
		y += w * 0.34
	_ball(Vector2(0, grip + w * 0.24), w * 0.34, guard_col, ow * 0.8)
	var blade := PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.5, -length * 0.84), Vector2(0, -length),
		Vector2(w * 0.5, -length * 0.84), Vector2(w * 0.5, 0)])
	_poly(blade, Color(0.94, 0.96, 1.0), STEEL.darkened(0.3), ow)
	draw_line(Vector2(0, -w * 0.5), Vector2(0, -length * 0.8), Color(0.1, 0.12, 0.18, 0.3), w * 0.16, true)
	draw_line(Vector2(-w * 0.3, -w * 0.5), Vector2(-w * 0.3, -length * 0.8), Color(1, 1, 1, 0.6), maxf(2.0, w * 0.09), true)
	_poly(PackedVector2Array([Vector2(-guard_w * 0.5, -w * 0.18), Vector2(guard_w * 0.5, -w * 0.18), Vector2(guard_w * 0.44, w * 0.3),
		Vector2(-guard_w * 0.44, w * 0.3)]), guard_col.lightened(0.3), guard_col.darkened(0.35), ow)
	if gem.a > 0.0:
		_glow(Vector2(0, w * 0.06), w * 0.6, Color(gem, 0.8))
		_ball(Vector2(0, w * 0.06), w * 0.2, gem, ow * 0.6)
	_rs()


## Round shield (Sword and Shield class): crimson-painted face, iron rim with rivets, brass boss. `squash` < 1 tilts it.
func _round_shield(c: Vector2, r: float, ow: float, squash: float = 1.0, ang: float = 0.0) -> void:
	var face: Color = Color(CLASS_GLOW[&"sword_shield"]).darkened(0.28)
	_xf(c, ang, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, r + ow * 0.5, INK)
	_disc(Vector2.ZERO, r, face.lightened(0.18), face.darkened(0.45), 48)
	draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 40, Color(1, 0.86, 0.62, 0.4), maxf(2.0, r * 0.05), true)
	draw_arc(Vector2.ZERO, r * 0.92, 0, TAU, 56, INK, r * 0.2, true)
	draw_arc(Vector2.ZERO, r * 0.92, 0, TAU, 56, IRON.lightened(0.12), r * 0.13, true)
	for k in 8:
		var a: float = TAU * float(k) / 8.0 + PI / 8.0
		draw_circle(Vector2(cos(a), sin(a)) * r * 0.92, maxf(2.0, r * 0.045), INK)
	_ball(Vector2.ZERO, r * 0.27, BRASS, ow * 0.7)
	draw_arc(Vector2.ZERO, r * 0.8, PI * 1.08, PI * 1.42, 16, Color(1, 1, 1, 0.45), maxf(2.0, r * 0.06), true)
	_rs()


## Gnarled staff from `butt` to `head`; two curled prongs at the head cradle the floating crystal (drawn by the caller).
func _staff(butt: Vector2, head: Vector2, w: float, ow: float, wood: Color = WOOD) -> void:
	var d: Vector2 = (head - butt).normalized()
	var n := Vector2(-d.y, d.x)
	var shaft: PackedVector2Array = _bez(butt, butt.lerp(head, 0.5) + n * w * 0.6, head, 16)
	for s in [-1.0, 1.0]:
		var p1: Vector2 = head + d * w * 1.0 + n * s * w * 1.5
		var p2: Vector2 = head + d * w * 2.4 + n * s * w * 0.55
		_poly(_tube(_bez(head - d * w * 0.4, p1, p2, 10), w * 0.72, w * 0.22), wood.lightened(0.4), wood.darkened(0.25), ow)
	_poly(_tube(shaft, w * 0.82, w), wood.lightened(0.45), wood.darkened(0.2), ow)
	var total: float = _length(shaft)
	for t in [0.28, 0.6]:
		var a: Array = _along(shaft, total * t)
		_poly(_ell(a[0], w * 0.64, w * 0.64, 14), wood.lightened(0.3), wood.darkened(0.35), ow * 0.6)
	var side: Vector2 = _lit_side(d)
	draw_line(butt + d * w + side * w * 0.2, head - d * w + side * w * 0.2, Color(1, 0.95, 0.85, 0.35), maxf(2.0, w * 0.16), true)


## The Wizard's floating crystal: a tall six-sided gem in the bolt colour with a strong glow.
func _float_crystal(c: Vector2, h: float, ang: float, ow: float) -> void:
	_glow(c, h * 1.8, Color(BOLT, 0.8))
	_xf(c, ang)
	var gem := PackedVector2Array([Vector2(0, -h), Vector2(h * 0.44, -h * 0.22), Vector2(h * 0.3, h * 0.5), Vector2(0, h * 0.8),
		Vector2(-h * 0.3, h * 0.5), Vector2(-h * 0.44, -h * 0.22)])
	_poly(gem, Color(0.96, 0.98, 1.0), BOLT.darkened(0.2), ow)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -h), Vector2(-h * 0.44, -h * 0.22), Vector2(0, -h * 0.05)]), Color(1, 1, 1, 0.6))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -h * 0.05), Vector2(h * 0.3, h * 0.5), Vector2(0, h * 0.8)]), Color(0.2, 0.3, 0.7, 0.3))
	_rs()


## An enemy token: a hunched dark shade with glowing red eyes and a red under-rim. `r` = body radius.
func _foe(c: Vector2, r: float) -> void:
	var body := PackedVector2Array([c + Vector2(0, -r * 1.3), c + Vector2(r * 0.42, -r * 0.9)])
	body.append_array(_ell(c, r, r * 1.02, 18, -PI * 0.3, PI * 1.3))
	body.append(c + Vector2(-r * 0.42, -r * 0.9))
	_poly(body, Color(0.40, 0.34, 0.42), Color(0.13, 0.10, 0.15), maxf(4.0, r * 0.2))
	draw_arc(c, r * 1.0, PI * 0.15, PI * 0.85, 14, Color(FOE, 0.85), maxf(2.5, r * 0.14), true)
	for e in [Vector2(-0.36, -0.22), Vector2(0.36, -0.22)]:
		var p: Vector2 = c + e * r
		_glow(p, r * 0.42, Color(FOE, 0.9))
		draw_colored_polygon(_ell(p, r * 0.17, r * 0.1, 10), Color(1.0, 0.85, 0.7))


func _burst(c: Vector2, r_out: float, r_in: float, n: int, core: Color, rim: Color, ow: float = 5.0, rot: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a: float = rot + TAU * float(i) / float(n * 2)
		pts.append(c + Vector2(cos(a), sin(a)) * (r_out if i % 2 == 0 else r_in))
	_poly(pts, core, rim, ow)


func _star5(c: Vector2, r: float, rot: float = -PI * 0.5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = rot + TAU * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.46))
	return pts


func _dashed(pts: PackedVector2Array, dash: float, gap: float, col: Color, w: float) -> void:
	var total: float = _length(pts)
	var s: float = 0.0
	while s < total:
		var a: Array = _along(pts, s)
		var b: Array = _along(pts, minf(s + dash, total))
		draw_line(a[0], b[0], col, w, true)
		s += dash + gap


## Polygon filled with a colour ramp from `a_col` (at point `a`) to `b_col` (at point `b`).
func _ramp(pts: PackedVector2Array, a: Vector2, b: Vector2, a_col: Color, b_col: Color) -> void:
	var ab: Vector2 = b - a
	var l2: float = maxf(ab.length_squared(), 1.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(a_col.lerp(b_col, clampf((p - a).dot(ab) / l2, 0.0, 1.0)))
	draw_polygon(pts, cols)


## Hooded robed figure (Slipstep), centre `c`, about 124 x 176 at s = 1.
func _robed(c: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in [Vector2(0, -92), Vector2(20, -72), Vector2(32, -44), Vector2(40, -18), Vector2(50, 40), Vector2(62, 84),
			Vector2(22, 76), Vector2(0, 84), Vector2(-22, 76), Vector2(-62, 84), Vector2(-50, 40), Vector2(-40, -18),
			Vector2(-32, -44), Vector2(-20, -72)]:
		pts.append(c + p)
	return pts


# ---------------------------------------------------------------- class icons (128 px, shown at 14 px in a 16 badge)
## One bold weapon silhouette per class, thick ink (12 px at 256 = ~0.7 px at 14), over the class colour halo.
func _class_icon() -> void:
	_champ_bg(0.7)
	match id:
		&"spear":
			_spear(Vector2(40, 222), Vector2(230, 26), 32, 112, 84, 12.0)
		&"sword_shield":
			_round_shield(Vector2(102, 146), 86, 12.0)
			_blade_sword(Vector2(98, 164), PI * 0.25, 184, 42, 112, 40, 12.0)
		&"two_hand":
			_blade_sword(Vector2(128, 168), 0.0, 158, 64, 172, 46, 12.0, IRON.darkened(0.1), HEAT)
		&"wizard":
			# Leans the other way from the spear (bottom-right to top-left) and ends in a big glowing crystal, so
			# the two diagonal glyphs stay apart at 14 px.
			_staff(Vector2(192, 250), Vector2(124, 116), 34, 12.0, ASH.darkened(0.12))
			_glow(Vector2(96, 66), 118, Color(BOLT, 0.55))
			_float_crystal(Vector2(96, 66), 64, -0.46, 12.0)


# ---------------------------------------------------------------- class skills (skills-rework.md 4.2)
func _class_skill() -> void:
	_champ_bg(0.5)
	match id:
		&"lunge": _lunge()
		&"hobbling_javelin": _hobbling_javelin()
		&"skewer": _skewer()
		&"riposte": _riposte()
		&"second_wind": _second_wind()
		&"shield_throw": _shield_throw()
		&"cleave": _cleave()
		&"crushing_blow": _crushing_blow()
		&"whirlwind": _whirlwind()
		&"arc_bolt": _arc_bolt()
		&"slipstep": _slipstep()
		&"starfall": _starfall()
		_: _star4(C, 70, _cglow())


## A low dash-thrust: the spear darts up-right out of a teal speed wedge into a burst; dazed stars over the hit.
func _lunge() -> void:
	var tc: Color = _cglow()
	var butt := Vector2(14, 214)
	var tip := Vector2(204, 100)
	var d: Vector2 = (tip - butt).normalized()
	var n := Vector2(-d.y, d.x)
	var wedge := PackedVector2Array([butt - d * 20.0 + n * 58.0, tip - d * 70.0 + n * 12.0, tip - d * 70.0 - n * 12.0, butt - d * 20.0 - n * 58.0])
	_ramp(wedge, butt - d * 20.0, tip - d * 70.0, Color(tc, 0.0), Color(tc, 0.7))
	for k in [-2.0, -1.0, 1.0, 2.0]:
		var o: Vector2 = n * k * 26.0
		draw_line(butt + o - d * (10.0 - absf(k) * 14.0), butt + o + d * (70.0 - absf(k) * 16.0), Color(1, 1, 1, 0.55), 5, true)
	var hit: Vector2 = tip + d * 10.0
	_glow(hit, 70, Color(tc, 0.75))
	_burst(hit, 44, 18, 8, Color(1, 1, 1), tc.lightened(0.4), 5.0, 0.2)
	_spear(butt, tip, 14, 62, 36, 6.0)
	for sp in [[Vector2(206, 38), 16.0], [Vector2(240, 66), 12.0], [Vector2(172, 30), 11.0]]:
		_star4(sp[0], sp[1], Color(1.0, 0.95, 0.6))


## A javelin arcs down and pins a boot at the heel: dust kicked up, the foot slowed (down chevrons).
func _hobbling_javelin() -> void:
	var tc: Color = _cglow()
	_ground(Vector2(160, 230), 96, 20, Color(0.30, 0.25, 0.19))
	var jd := Vector2(0.62, 0.78).normalized()
	var jtip := Vector2(160, 188)
	var jbutt: Vector2 = jtip - jd * 150.0
	_dashed(_bez(Vector2(4, 214), jbutt - jd * 90.0, jbutt, 20), 12, 10, Color(1, 1, 1, 0.6), 5)
	var boot := PackedVector2Array([Vector2(154, 104), Vector2(204, 104), Vector2(202, 180), Vector2(240, 198), Vector2(250, 220),
		Vector2(144, 222), Vector2(148, 176)])
	_shape(boot, Color(0.44, 0.29, 0.17), 6.0)
	_shape(_rect(Vector2(146, 96), Vector2(212, 118)), Color(0.32, 0.21, 0.12), 5.0)
	_shape(_rect(Vector2(140, 216), Vector2(252, 230)), Color(0.16, 0.12, 0.09), 4.0)
	draw_line(Vector2(162, 126), Vector2(160, 170), Color(1, 1, 1, 0.25), 5, true)
	for k in 3:
		var ly: float = 132.0 + k * 18.0
		draw_line(Vector2(180, ly), Vector2(198, ly + 8), ROPE.lightened(0.2), 4, true)
		draw_line(Vector2(198, ly), Vector2(180, ly + 8), ROPE.lightened(0.2), 4, true)
	for p in [Vector2(132, 222), Vector2(116, 208), Vector2(142, 204), Vector2(206, 232)]:
		_poly(_ell(p, 15, 10, 12), Color(0.66, 0.58, 0.48), Color(0.36, 0.30, 0.24), 3.0)
	_glow(jtip, 40, Color(1, 0.9, 0.7, 0.7))
	_spear(jbutt, jtip, 10, 40, 22, 5.0)
	for k in 2:
		var cy: float = 42.0 + k * 30.0
		var chev := PackedVector2Array([Vector2(196, cy), Vector2(222, cy + 18), Vector2(248, cy), Vector2(248, cy + 12),
			Vector2(222, cy + 30), Vector2(196, cy + 12)])
		_poly(chev, tc.lightened(0.45), tc.darkened(0.1), 4.0)


## A long two-hand thrust through three foes standing in a line; a flash runs along the spear.
func _skewer() -> void:
	var tc: Color = _cglow()
	var y: float = 152.0
	var foes: Array = [[Vector2(78, 128), 36.0], [Vector2(144, 132), 32.0], [Vector2(204, 136), 28.0]]
	for f in foes:
		_foe(f[0], f[1])
	draw_line(Vector2(0, y), Vector2(256, y), Color(tc, 0.35), 30, true)
	draw_line(Vector2(0, y), Vector2(256, y), Color(1, 1, 1, 0.5), 10, true)
	_spear(Vector2(6, y + 4), Vector2(252, y - 2), 13, 50, 32, 6.0, false)
	for f in foes:
		var p: Vector2 = f[0]
		_burst(Vector2(p.x - f[1] * 0.7, y + 1), f[1] * 0.5, f[1] * 0.22, 6, Color(1, 1, 1), tc.lightened(0.3), 3.0, 0.3)
	for k in [-1.0, 1.0]:
		draw_line(Vector2(8, y + k * 34.0), Vector2(52, y + k * 30.0), Color(1, 1, 1, 0.5), 5, true)


## Shield up, sword cocked behind: a foe's blade glances off the rim in sparks and the hit comes back (return arrow).
func _riposte() -> void:
	var tc: Color = _cglow()
	_blade_sword(Vector2(176, 112), -0.62, 118, 22, 64, 30, 6.0)
	var foe_blade := PackedVector2Array([Vector2(260, 150), Vector2(182, 140), Vector2(170, 150), Vector2(182, 160), Vector2(260, 172)])
	_poly(foe_blade, Color(0.62, 0.56, 0.62), Color(0.26, 0.20, 0.26), 5.0)
	draw_line(Vector2(250, 152), Vector2(186, 143), Color(FOE, 0.9), 4, true)
	_round_shield(Vector2(100, 150), 74, 6.0)
	var hit := Vector2(172, 150)
	_glow(hit, 60, Color(1, 0.9, 0.6, 0.85))
	_burst(hit, 34, 14, 7, Color(1, 1, 0.92), Color(1.0, 0.8, 0.4), 4.0)
	var ret: PackedVector2Array = _bez(Vector2(176, 178), Vector2(192, 236), Vector2(232, 210), 16)
	_stroke(ret, 12, tc.lightened(0.35), 5.0)
	_dart(Vector2(222, 218), Vector2(252, 196), 32, tc.lightened(0.2))
	_sparks(hit, 50, 4, Color(1.0, 0.85, 0.5), 111)


## Sword planted point-down, a deep breath: warm wisps rise around it and a heart lifts above.
func _second_wind() -> void:
	var tc: Color = _cglow()
	_ground(Vector2(128, 220), 104, 24, Color(0.30, 0.24, 0.22))
	for w in [[Vector2(70, 216), Vector2(22, 140), Vector2(80, 58)], [Vector2(188, 216), Vector2(240, 148), Vector2(176, 66)],
			[Vector2(104, 226), Vector2(60, 160), Vector2(110, 100)], [Vector2(154, 226), Vector2(198, 170), Vector2(150, 110)]]:
		var pts: PackedVector2Array = _bez(w[2], w[1], w[0], 18)
		_poly(_tube(pts, 3, 20), Color(1, 0.95, 0.9, 0.85), Color(tc, 0.3), 0.0)
	for cr in [[Vector2(120, 222), Vector2(96, 230)], [Vector2(136, 222), Vector2(162, 232)]]:
		draw_line(cr[0], cr[1], Color(0.06, 0.05, 0.05), 5, true)
	_blade_sword(Vector2(128, 78), PI, 142, 28, 84, 36, 6.0)
	_glow(Vector2(200, 60), 50, Color(1, 0.6, 0.6, 0.6))
	_poly(_heart_pts(Vector2(200, 66), 0.3), ROSE.lightened(0.35), ROSE.darkened(0.3), 5.0)
	_sparks(Vector2(128, 120), 96, 5, Color(1, 0.85, 0.75), 113)


## The round shield spins out and bounces between three foes (big, smaller, smallest hit).
func _shield_throw() -> void:
	var tc: Color = _cglow()
	var hits: Array = [[Vector2(196, 66), 22.0], [Vector2(222, 176), 18.0], [Vector2(142, 222), 14.0]]
	var path := PackedVector2Array([Vector2(90, 132)])
	for h in hits:
		path.append(h[0])
	_dashed(path, 14, 10, Color(1, 1, 1, 0.7), 5)
	var sizes: Array = [34.0, 26.0, 18.0]
	for i in hits.size():
		var p: Vector2 = hits[i][0]
		_foe(p, hits[i][1])
		_glow(p, sizes[i] * 1.6, Color(1, 0.85, 0.6, 0.7))
		_burst(p + Vector2(-4, -6), sizes[i], sizes[i] * 0.42, 7, Color(1, 1, 0.92), Color(1.0, 0.75, 0.4), 4.0)
	for k in 3:
		draw_arc(Vector2(90, 132), 88 + k * 14, PI * 0.62, PI * 1.02, 14, Color(1, 1, 1, 0.5 - k * 0.12), 5, true)
	_round_shield(Vector2(90, 132), 70, 6.0, 0.6, -0.5)
	_glow(Vector2(90, 132), 30, Color(tc, 0.35))


## A wide horizontal sweep: the greatsword above, its crescent trail cutting through three foes below.
func _cleave() -> void:
	var tc: Color = _cglow()
	var foes: Array = [[Vector2(52, 196), 24.0], [Vector2(128, 206), 27.0], [Vector2(204, 196), 24.0]]
	for f in foes:
		_foe(f[0], f[1])
	var arc: PackedVector2Array = _ell(Vector2(128, 310), 130, 172, 28, PI * 1.22, PI * 1.78)
	_poly(_tube(arc, 58, 0.0, true), Color(1, 0.97, 0.88, 0.9), Color(tc, 0.55), 0.0)
	draw_polyline(_ell(Vector2(128, 312), 124, 168, 28, PI * 1.25, PI * 1.75), Color(1, 1, 1, 0.9), 4, true)
	for f in foes:
		var p: Vector2 = f[0]
		_burst(p + Vector2(0, -26), 20, 8, 6, Color(1, 1, 1), tc.lightened(0.3), 3.0, 0.4)
	_blade_sword(Vector2(74, 66), PI * 0.5, 170, 30, 92, 48, 6.0, IRON.darkened(0.1), HEAT)


## A two-hand chop splits a steel breastplate: the crack glows, shards fly (armor broken).
func _crushing_blow() -> void:
	var tc: Color = _cglow()
	var crack := [Vector2(128, 150), Vector2(118, 176), Vector2(136, 200), Vector2(122, 238)]
	var left := PackedVector2Array([Vector2(58, 146), Vector2(98, 132)])
	left.append_array(PackedVector2Array(crack))
	left.append_array(PackedVector2Array([Vector2(70, 238), Vector2(52, 188)]))
	var right := PackedVector2Array([Vector2(158, 132), Vector2(198, 146), Vector2(204, 188), Vector2(186, 238)])
	var back: Array = crack.duplicate()
	back.reverse()
	right.append_array(PackedVector2Array(back))
	_glow(Vector2(128, 190), 70, Color(tc, 0.7))
	_xf(Vector2(-10, 4), -0.06)
	_poly(left, STEEL.lightened(0.3), STEEL.darkened(0.45), 6.0)
	draw_polyline(PackedVector2Array([Vector2(66, 150), Vector2(60, 188), Vector2(74, 232)]), Color(1, 1, 1, 0.4), 4, true)
	for p in [Vector2(76, 160), Vector2(80, 220)]:
		_ball(p, 5, IRON.lightened(0.2), 3.0)
	_rs()
	_xf(Vector2(10, 4), 0.06)
	_poly(right, STEEL.lightened(0.2), STEEL.darkened(0.5), 6.0)
	for p in [Vector2(180, 160), Vector2(176, 220)]:
		_ball(p, 5, IRON.lightened(0.2), 3.0)
	_rs()
	var cr := PackedVector2Array(crack)
	draw_polyline(cr, Color(tc, 0.6), 16, true)
	draw_polyline(cr, Color(1, 0.95, 0.7), 5, true)
	_blade_sword(Vector2(128, 24), PI, 118, 40, 118, 36, 6.0, IRON.darkened(0.1), HEAT)
	_glow(Vector2(128, 148), 64, Color(1, 0.85, 0.5, 0.9))
	_burst(Vector2(128, 148), 42, 16, 8, Color(1, 1, 0.9), HEAT, 4.0, 0.2)
	for sh in [[Vector2(40, 116), 0.4], [Vector2(214, 110), -0.5], [Vector2(26, 170), 0.9], [Vector2(232, 164), -1.1]]:
		_xf(sh[0], sh[1])
		_poly(PackedVector2Array([Vector2(-12, -8), Vector2(12, -4), Vector2(2, 12)]), STEEL.lightened(0.3), STEEL.darkened(0.3), 4.0)
		_rs()
	for st in [[Vector2(60, 120), Vector2(84, 132)], [Vector2(196, 120), Vector2(172, 132)]]:
		draw_line(st[0], st[1], Color(1, 1, 1, 0.55), 4, true)


## Top-down spin: the greatsword sweeps a ring, three blurred crescents trail it, the r 3 m ring dashed around.
func _whirlwind() -> void:
	var tc: Color = _cglow()
	var c := Vector2(128, 132)
	for k in 18:
		var a0: float = TAU * float(k) / 18.0
		draw_arc(c, 114, a0, a0 + TAU / 36.0, 6, Color(tc.lightened(0.4), 0.85), 5, true)
	for k in 3:
		var a0: float = -0.8 - 2.2 - TAU * float(k) / 3.0
		var pts: PackedVector2Array = _ell(c, 88, 88, 20, a0, a0 + 2.0)
		_poly(_tube(pts, 2, 34), Color(1, 0.96, 0.85, 0.85), Color(tc, 0.45), 0.0)
	# the blade points at screen angle -0.8 rad (up-right) and spins clockwise: ghosts trail at smaller angles
	var blade_dir := Vector2(cos(-0.8), sin(-0.8))
	var rot: float = atan2(blade_dir.x, -blade_dir.y)
	for g in [[rot - 1.1, 0.16], [rot - 0.55, 0.3]]:
		_xf(c, g[0])
		draw_colored_polygon(PackedVector2Array([Vector2(-15, -24), Vector2(-15, -114), Vector2(0, -130), Vector2(15, -114),
			Vector2(15, -24)]), Color(1, 1, 1, g[1]))
		_rs()
	_blade_sword(c + blade_dir * 22.0, rot, 110, 30, 86, 30, 6.0, IRON.darkened(0.1), HEAT)
	for sp in [Vector2(40, 88), Vector2(222, 186)]:
		_burst(sp, 18, 7, 6, Color(1, 1, 0.92), HEAT, 3.0)


## The staff's crystal looses a crackling bolt up-right: a zigzag trail and a bright orb head.
func _arc_bolt() -> void:
	var start := Vector2(46, 214)
	var orb := Vector2(178, 80)
	var d: Vector2 = (orb - start).normalized()
	var n := Vector2(-d.y, d.x)
	_ramp(_tube(PackedVector2Array([start, orb]), 10, 70), start, orb, Color(BOLT, 0.0), Color(BOLT, 0.55))
	for pass_i in 2:
		var zig := PackedVector2Array()
		for i in 9:
			var t: float = float(i) / 8.0
			var off: float = 0.0 if (i == 0 or i == 8) else (16.0 if (i + pass_i) % 2 == 0 else -16.0) * (1.0 - pass_i * 0.4)
			zig.append(start.lerp(orb, t) + n * off)
		draw_polyline(zig, Color(BOLT, 0.45), 20 - pass_i * 8, true)
		draw_polyline(zig, Color(0.92, 0.96, 1.0), 6 - pass_i * 2, true)
	_staff(Vector2(-6, 272), Vector2(22, 238), 16, 5.0)
	_float_crystal(start, 24, 0.7, 5.0)
	_glow(orb, 92, Color(BOLT, 0.85))
	for k in 6:
		var a: float = TAU * float(k) / 6.0 + 0.4
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		draw_polyline(PackedVector2Array([orb + dir * 30.0, orb + dir * 44.0 + side * 8.0, orb + dir * 58.0 - side * 4.0]), Color(0.9, 0.95, 1.0, 0.9), 4, true)
	draw_circle(orb, 36 + 3, INK)
	_disc(orb, 36, Color(1, 1, 1), BOLT)
	_star4(orb, 30, Color.WHITE)


## Blink: a fading ghost (clawed at by a foe) on the left, the wizard reappearing bright on the right.
func _slipstep() -> void:
	var tc: Color = _cglow()
	var ghost: PackedVector2Array = _robed(Vector2(74, 150))
	draw_colored_polygon(ghost, Color(tc, 0.22))
	var gl := ghost.duplicate()
	gl.append(ghost[0])
	_dashed(gl, 10, 8, Color(0.9, 0.85, 1.0, 0.6), 4)
	for k in 7:
		var p := Vector2(24 + (k % 3) * 18, 90 + k * 18)
		draw_rect(Rect2(p, Vector2(8, 8)), Color(0.85, 0.8, 1.0, 0.35 - k * 0.03))
	for k in 3:
		var o := Vector2(k * 16.0, k * 10.0)
		draw_polyline(_bez(Vector2(34, 104) + o, Vector2(64, 130) + o, Vector2(72, 170) + o, 10), Color(FOE, 0.85), 5, true)
	var arc: PackedVector2Array = _bez(Vector2(96, 62), Vector2(132, 6), Vector2(170, 52), 16)
	_stroke(arc, 10, Color(0.95, 0.92, 1.0), 5.0)
	_dart(Vector2(160, 36), Vector2(176, 66), 28, Color(0.95, 0.92, 1.0))
	var sc := Vector2(180, 156)
	_glow(sc, 100, Color(BOLT, 0.7))
	var solid: PackedVector2Array = _robed(sc)
	_poly(solid, tc.lightened(0.2), tc.darkened(0.5), 6.0)
	draw_polyline(PackedVector2Array([sc + Vector2(-26, -40), sc + Vector2(-40, 36), sc + Vector2(-50, 76)]), Color(1, 1, 1, 0.3), 4, true)
	draw_colored_polygon(_ell(sc + Vector2(0, -44), 17, 14, 14), Color(0.05, 0.03, 0.08))
	for e in [Vector2(-7, -44), Vector2(7, -44)]:
		_glow(sc + e, 9, Color(BOLT, 0.95))
		draw_circle(sc + e, 2.6, Color(0.95, 0.98, 1.0))
	for sp in [Vector2(226, 96), Vector2(234, 196), Vector2(136, 206)]:
		_star4(sp, 12, Color(0.92, 0.95, 1.0))


## A falling star streaks down onto a target ring on the ground (shown to both teams).
func _starfall() -> void:
	var tc: Color = _cglow()
	var rc := Vector2(116, 208)
	draw_colored_polygon(_ell(rc, 100, 30, 36), Color(tc, 0.22))
	for k in 16:
		var a0: float = TAU * float(k) / 16.0
		draw_polyline(_ell(rc, 100, 30, 4, a0, a0 + TAU / 32.0), Color(0.95, 0.9, 1.0, 0.9), 5, true)
	var inner_ring: PackedVector2Array = _ell(rc, 56, 17, 30)
	inner_ring.append(inner_ring[0])
	draw_polyline(inner_ring, Color(tc.lightened(0.3), 0.6), 3, true)
	var sc := Vector2(146, 110)
	var tail := PackedVector2Array([Vector2(262, -20), sc])
	_ramp(_tube(tail, 6, 76), Vector2(262, -20), sc, Color(tc, 0.0), Color(BOLT, 0.85))
	_ramp(_tube(tail, 2, 30), Vector2(262, -20), sc, Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.8))
	_dashed(PackedVector2Array([sc + Vector2(-8, 40), rc + Vector2(0, -6)]), 8, 8, Color(1, 1, 1, 0.45), 4)
	_glow(sc, 84, Color(BOLT, 0.8))
	_poly(_star5(sc, 46, -PI * 0.5 + 0.2), Color(1, 1, 0.96), Color(0.72, 0.82, 1.0), 6.0)
	draw_colored_polygon(_star5(sc + Vector2(-3, -3), 20, -PI * 0.5 + 0.2), Color(1, 1, 1, 0.7))
	_sparks(rc + Vector2(0, -20), 90, 5, BOLT, 127)
