extends Node2D
## Paints one 256 x 256 icon in code (painted look: top-lit gradients, dark ink outline, soft glow).
## Used by res://art/icons/render_icons.gd, which downsamples to 128 x 128. Set kind / id / faction / tier
## before adding it to a SubViewport. Kinds: spells, items, orders, units, buildings, bg (portrait background).

const C := Vector2(128, 128)
const INK := Color(0.06, 0.04, 0.05)
const FIRE_TEAM := Color(0.85, 0.30, 0.12)
const FIRE_GLOW := Color(1.0, 0.55, 0.15)
const SHADOW_TEAM := Color(0.42, 0.22, 0.60)
const SHADOW_GLOW := Color(0.70, 0.30, 1.0)
const NEUTRAL_GLOW := Color(0.55, 0.85, 0.50)
const ICE_TEAM := Color(0.45, 0.75, 0.95)
const ICE_DARK := Color(0.15, 0.35, 0.60)
const ICE_GLOW := Color(0.55, 0.85, 1.0)      # a touch deeper than the model glow (0.75, 0.92, 1) so it reads on dark
const ICE_PALE := Color(0.85, 0.95, 1.0)
const FROST_SILVER := Color(0.70, 0.78, 0.88)
const NATURE_TEAM := Color(0.35, 0.70, 0.25)
const NATURE_DARK := Color(0.15, 0.40, 0.15)
const NATURE_GLOW := Color(0.75, 1.0, 0.40)
const BARK := Color(0.40, 0.28, 0.16)
const BLOSSOM := Color(0.95, 0.60, 0.75)
const LEAF := Color(0.42, 0.76, 0.28)
const BRONZE := Color(0.62, 0.40, 0.16)
const SILVER := Color(0.55, 0.52, 0.66)
const STEEL := Color(0.66, 0.70, 0.76)
const GOLD := Color(1.0, 0.80, 0.30)
const CRYSTAL := Color(0.45, 0.85, 1.0)
const WOOD := Color(0.48, 0.30, 0.16)
const BONE := Color(0.90, 0.86, 0.74)
const STONE := Color(0.46, 0.45, 0.46)
const WARN := Color(0.95, 0.30, 0.25)
const TIER_COLORS: Array[Color] = [Color(0.85, 0.85, 0.85), Color(0.30, 0.75, 1.0), Color(1.0, 0.60, 0.20),
	Color(0.40, 0.90, 0.40), Color(1.0, 0.85, 0.30)]

var kind: StringName = &"items"
var id: StringName = &""
var faction: StringName = &"fire"
var tier: int = 0


func _draw() -> void:
	match kind:
		&"spells": _spell()
		&"items": _item()
		&"orders": _order()
		&"units": _unit()
		&"buildings": _building()
		&"bg": _portrait_bg()


# ---------------------------------------------------------------- helpers
func _xf(pos: Vector2, ang: float = 0.0, sc: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(pos, ang, sc)


func _rs() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _poly(pts: PackedVector2Array, top: Color, bottom: Color, ow: float = 6.0) -> void:
	if pts.size() < 3:
		return
	var miny: float = INF
	var maxy: float = -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 1.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, (p.y - miny) / span))
	if ow > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, INK, ow, true)
	draw_polygon(pts, cols)


func _shape(pts: PackedVector2Array, base: Color, ow: float = 6.0) -> void:
	_poly(pts, base.lightened(0.3), base.darkened(0.35), ow)


func _ell(c: Vector2, rx: float, ry: float, n: int = 40, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full: bool = is_equal_approx(a1 - a0, TAU)
	var count: int = n if full else n + 1
	for i in count:
		var a: float = a0 + (a1 - a0) * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _rect(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])


func _disc(c: Vector2, r: float, inner: Color, outer: Color, n: int = 40) -> void:
	for i in n:
		var a0: float = TAU * float(i) / float(n)
		var a1: float = TAU * float(i + 1) / float(n)
		draw_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]),
			PackedColorArray([inner, outer, outer]))


func _glow(c: Vector2, r: float, col: Color) -> void:
	_disc(c, r, col, Color(col, 0.0))


func _ball(c: Vector2, r: float, base: Color, ow: float = 6.0) -> void:
	if ow > 0.0:
		draw_circle(c, r + ow * 0.5, INK)
	_disc(c, r, base.lightened(0.15), base.darkened(0.35))
	_glow(c + Vector2(-r, -r) * 0.35, r * 0.45, Color(1, 1, 1, 0.45))


func _stroke(pts: PackedVector2Array, w: float, col: Color, ow: float = 6.0) -> void:
	if ow > 0.0:
		draw_polyline(pts, INK, w + ow, true)
	draw_polyline(pts, col, w, true)


func _sheen(c: Vector2, r: float, a0: float, a1: float, w: float = 5.0) -> void:
	draw_arc(c, r, a0, a1, 16, Color(1, 1, 1, 0.5), w, true)


func _bez(p0: Vector2, p1: Vector2, p2: Vector2, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t: float = float(i) / float(n)
		pts.append(p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t)
	return pts


## Outline of a stroke along `center` whose width goes from w0 to w1 (or a leaf profile if leaf = true).
func _tube(center: PackedVector2Array, w0: float, w1: float, leaf: bool = false) -> PackedVector2Array:
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	var n: int = center.size()
	for i in n:
		var d: Vector2 = (center[mini(i + 1, n - 1)] - center[maxi(i - 1, 0)]).normalized()
		var nor := Vector2(-d.y, d.x)
		var t: float = float(i) / float(n - 1)
		var w: float = lerpf(w0, w1, t) * 0.5
		if leaf:
			w = w0 * 0.5 * pow(sin(PI * t), 0.8)
		w = maxf(w, 0.8)
		l.append(center[i] + nor * w)
		r.append(center[i] - nor * w)
	r.reverse()
	l.append_array(r)
	return l


func _flame_pts(base: Vector2, w: float, h: float, sway: float = 0.12) -> PackedVector2Array:
	var n: int = 16
	var right := PackedVector2Array()
	var left := PackedVector2Array()
	for i in n + 1:
		var s: float = float(i) / float(n)
		var half: float
		if s < 0.35:
			half = w * 0.5 * sqrt(maxf(0.0, 1.0 - pow((0.35 - s) / 0.35, 2.0)))
		else:
			half = w * 0.5 * pow(1.0 - (s - 0.35) / 0.65, 1.2)
		var off: float = sin(s * PI * 1.6) * w * sway * s
		var y: float = base.y - s * h
		right.append(Vector2(base.x + off + half, y))
		left.append(Vector2(base.x + off - half, y))
	var pts := right
	for i in range(n - 1, 0, -1):
		pts.append(left[i])
	return pts


func _fire(base: Vector2, w: float, h: float, glow: bool = true) -> void:
	if glow:
		_glow(base + Vector2(0, -h * 0.4), maxf(w, h) * 0.7, Color(FIRE_GLOW, 0.5))
	_poly(_flame_pts(base, w, h), Color(1.0, 0.62, 0.15), Color(0.80, 0.18, 0.05), 6.0)
	_poly(_flame_pts(base + Vector2(0, -h * 0.03), w * 0.62, h * 0.66, 0.1), Color(1.0, 0.92, 0.45), Color(1.0, 0.6, 0.12), 0.0)
	_poly(_flame_pts(base + Vector2(0, -h * 0.05), w * 0.3, h * 0.35, 0.05), Color(1, 1, 0.92), Color(1.0, 0.9, 0.5), 0.0)


func _dark_fire(base: Vector2, w: float, h: float) -> void:
	_glow(base + Vector2(0, -h * 0.4), maxf(w, h) * 0.7, Color(SHADOW_GLOW, 0.5))
	_poly(_flame_pts(base, w, h), Color(0.75, 0.45, 1.0), Color(0.30, 0.08, 0.45), 6.0)
	_poly(_flame_pts(base + Vector2(0, -h * 0.03), w * 0.6, h * 0.62, 0.1), Color(0.95, 0.85, 1.0), Color(0.65, 0.35, 0.95), 0.0)


func _sparks(c: Vector2, r: float, n: int, col: Color, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in n:
		var a: float = rng.randf() * TAU
		var d: float = rng.randf_range(0.55, 1.0) * r
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * d
		var s: float = rng.randf_range(3.0, 6.5)
		_glow(p, s * 3.0, Color(col, 0.55))
		draw_circle(p, s * 0.6, col.lightened(0.6))


func _star4(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a: float = TAU * float(i) / 8.0 - PI * 0.5
		var rr: float = r if i % 2 == 0 else r * 0.22
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	_glow(c, r * 1.2, Color(col, 0.45))
	draw_colored_polygon(pts, col)


func _sword(hilt: Vector2, ang: float, length: float, w: float, top: Color, bottom: Color, guard: Color) -> void:
	_xf(hilt, ang)
	var gl: float = length * 0.22
	_shape(_rect(Vector2(-w * 0.2, 0), Vector2(w * 0.2, gl)), WOOD, 5.0)
	_ball(Vector2(0, gl + w * 0.2), w * 0.3, guard, 5.0)
	_poly(PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.5, -length * 0.8), Vector2(0, -length),
		Vector2(w * 0.5, -length * 0.8), Vector2(w * 0.5, 0)]), top, bottom, 6.0)
	draw_line(Vector2(0, -w * 0.4), Vector2(0, -length * 0.82), Color(0, 0, 0, 0.25), w * 0.16)
	draw_line(Vector2(-w * 0.26, -w * 0.4), Vector2(-w * 0.26, -length * 0.76), Color(1, 1, 1, 0.45), w * 0.1)
	_shape(PackedVector2Array([Vector2(-w * 1.5, -w * 0.12), Vector2(w * 1.5, -w * 0.12), Vector2(w * 1.25, w * 0.32),
		Vector2(-w * 1.25, w * 0.32)]), guard, 5.0)
	_rs()


func _pickaxe(c: Vector2, ang: float, head: Color) -> void:
	_xf(c, ang)
	_shape(_rect(Vector2(-8, -72), Vector2(8, 96)), WOOD, 5.0)
	_shape(_tube(_bez(Vector2(-92, -34), Vector2(0, -104), Vector2(92, -34), 18), 34.0, 0.0, true), head)
	_shape(_rect(Vector2(-14, -84), Vector2(14, -58)), BRONZE, 5.0)
	_rs()


func _crystal(c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -44) * s, c + Vector2(22, -16) * s, c + Vector2(18, 30) * s,
		c + Vector2(0, 42) * s, c + Vector2(-18, 30) * s, c + Vector2(-22, -16) * s])
	_glow(c, 56.0 * s, Color(col, 0.5))
	_poly(pts, col.lightened(0.5), col.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -44) * s, c + Vector2(22, -16) * s, c + Vector2(4, -10) * s]), Color(1, 1, 1, 0.5))


func _kite(c: Vector2, w: float, h: float) -> PackedVector2Array:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	return PackedVector2Array([c + Vector2(-hw, -hh + 10), c + Vector2(-hw + 10, -hh), c + Vector2(hw - 10, -hh),
		c + Vector2(hw, -hh + 10), c + Vector2(hw, hh * 0.05), c + Vector2(hw * 0.6, hh * 0.6), c + Vector2(0, hh),
		c + Vector2(-hw * 0.6, hh * 0.6), c + Vector2(-hw, hh * 0.05)])


func _boot(col: Color, cuff: Color) -> void:
	_shape(PackedVector2Array([Vector2(94, 40), Vector2(152, 40), Vector2(150, 146), Vector2(204, 170),
		Vector2(218, 196), Vector2(216, 214), Vector2(80, 214), Vector2(86, 150)]), col)
	_shape(_rect(Vector2(80, 204), Vector2(216, 220)), Color(0.18, 0.13, 0.10), 5.0)
	_shape(_rect(Vector2(88, 34), Vector2(158, 58)), cuff, 5.0)


func _hood(c: Vector2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -78), c + Vector2(34, -58), c + Vector2(50, -16), c + Vector2(56, 44),
		c + Vector2(70, 76), c + Vector2(42, 68), c + Vector2(22, 80), c + Vector2(0, 70), c + Vector2(-22, 80),
		c + Vector2(-42, 68), c + Vector2(-70, 76), c + Vector2(-56, 44), c + Vector2(-50, -16), c + Vector2(-34, -58)])
	_poly(pts, top, bottom)
	_poly(_ell(c + Vector2(0, -16), 28, 32), Color(0.01, 0.0, 0.03), Color(0.06, 0.02, 0.1), 0.0)
	for e in [Vector2(-11, -16), Vector2(11, -16)]:
		_glow(c + e, 16, Color(SHADOW_GLOW, 0.8))
		draw_colored_polygon(_ell(c + e, 6, 3.5, 12), Color(0.95, 0.85, 1.0))


## A hexagonal ice crystal seen from the side, from `base` to `tip`; the half facing the top-left light is brighter.
func _ice_shard(base: Vector2, tip: Vector2, w: float, col: Color = ICE_TEAM, ow: float = 5.0) -> void:
	var d: Vector2 = tip - base
	var l: float = d.length()
	d = d / l
	var n := Vector2(-d.y, d.x)
	var hw: float = w * 0.5
	var pts := PackedVector2Array([base - d * l * 0.04, base + n * hw * 0.8 + d * l * 0.06, base + n * hw + d * l * 0.62,
		tip, base - n * hw + d * l * 0.62, base - n * hw * 0.8 + d * l * 0.06])
	_poly(pts, col.lightened(0.55), col.darkened(0.3), ow)
	var lit: Vector2 = n if n.dot(Vector2(-1, -1)) > 0.0 else -n
	draw_colored_polygon(PackedVector2Array([base + d * l * 0.02, base + lit * hw * 0.8 + d * l * 0.06,
		base + lit * hw + d * l * 0.62, tip]), Color(1, 1, 1, 0.3))
	draw_line(base + d * l * 0.08, tip - d * l * 0.08, Color(1, 1, 1, 0.6), maxf(2.0, w * 0.07))


## Six-armed snowflake with two pairs of branches per arm and round ink caps.
func _snowflake(c: Vector2, r: float, col: Color, w: float, ow: float = 5.0, rot: float = -PI * 0.5) -> void:
	var segs: Array[PackedVector2Array] = []
	for i in 6:
		var a: float = rot + TAU * float(i) / 6.0
		var dir := Vector2(cos(a), sin(a))
		segs.append(PackedVector2Array([c, c + dir * r]))
		for t in [0.48, 0.76]:
			var p: Vector2 = c + dir * r * t
			var bl: float = r * (0.34 if t < 0.6 else 0.2)
			for s in [-1.0, 1.0]:
				segs.append(PackedVector2Array([p, p + dir.rotated(s * PI / 3.0) * bl]))
	if ow > 0.0:
		for sg in segs:
			draw_polyline(sg, INK, w + ow, true)
			draw_circle(sg[1], (w + ow) * 0.5, INK)
	for sg in segs:
		draw_polyline(sg, col, w, true)
		draw_circle(sg[1], w * 0.5, col)
	draw_circle(c, w * 1.2, col.lightened(0.5))


func _leaf(base: Vector2, tip: Vector2, w: float, col: Color = LEAF, bend: float = 0.2, ow: float = 5.0) -> void:
	var d: Vector2 = tip - base
	var mid: Vector2 = base + d * 0.5 + Vector2(-d.y, d.x) * bend
	var cpts := _bez(base, mid, tip, 14)
	_shape(_tube(cpts, w, 0.0, true), col, ow)
	draw_polyline(cpts.slice(1, 12), col.darkened(0.4), maxf(2.0, w * 0.07), true)


## Curved thorn from `base` (wide) to `tip` (sharp).
func _thorn(base: Vector2, tip: Vector2, w: float, bend: float = 0.15) -> void:
	var d: Vector2 = tip - base
	var mid: Vector2 = base + d * 0.5 + Vector2(-d.y, d.x) * bend
	var cpts := _bez(base, mid, tip, 14)
	_poly(_tube(cpts, w, 0.0), Color(0.72, 0.92, 0.42), Color(0.26, 0.30, 0.10), 6.0)
	var nor := Vector2(-d.y, d.x).normalized()
	var lit: Vector2 = nor if nor.dot(Vector2(-1, -1)) > 0.0 else -nor
	var hl := PackedVector2Array()
	for i in range(1, 11):
		var t: float = float(i) / 14.0
		hl.append(cpts[i] + lit * w * 0.22 * (1.0 - t))
	draw_polyline(hl, Color(1, 1, 0.85, 0.4), maxf(2.0, w * 0.1), true)


func _flower(c: Vector2, r: float, n: int, col: Color, core: Color, rot: float = 0.0) -> void:
	for i in n:
		var a: float = rot + TAU * float(i) / float(n)
		_xf(c + Vector2(cos(a), sin(a)) * r * 0.55, a)
		_poly(_ell(Vector2.ZERO, r * 0.56, r * 0.36, 20), col.lightened(0.35), col.darkened(0.25), 5.0)
		_rs()
	for i in n:
		var a: float = rot + TAU * (float(i) + 0.5) / float(n)
		_xf(c + Vector2(cos(a), sin(a)) * r * 0.3, a)
		_poly(_ell(Vector2.ZERO, r * 0.34, r * 0.22, 16), col.lightened(0.6), col.lightened(0.15), 3.0)
		_rs()
	_glow(c, r * 0.7, Color(core, 0.8))
	_ball(c, r * 0.22, core, 4.0)


## Heart outline, centre `c` (the heart is about 136 wide and 168 tall at s = 1).
func _heart_pts(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array([c + Vector2(0, 86) * s])
	for p in _ell(Vector2(-38, -40), 42, 42, 14, PI * 0.75, PI * 1.87):
		pts.append(c + p * s)
	for p in _ell(Vector2(38, -40), 42, 42, 14, PI * 1.13, PI * 2.25):
		pts.append(c + p * s)
	return pts


## A walking young tree (the Sapling summon): root feet, bark body, leaf-ball head with glowing eyes.
func _sapling(foot: Vector2, s: float) -> void:
	var bark: Color = BARK.lightened(0.12)
	for k in [-1.0, 0.0, 1.0]:
		_shape(_tube(_bez(foot + Vector2(0, -16) * s, foot + Vector2(k * 14, -4) * s, foot + Vector2(k * 28, 6) * s, 8), 13 * s, 3 * s), bark, 4.0)
	_shape(_tube(_bez(foot + Vector2(-4, -64) * s, foot + Vector2(-26, -66) * s, foot + Vector2(-40, -90) * s, 8), 10 * s, 3 * s), bark, 4.0)
	_shape(_tube(_bez(foot + Vector2(4, -58) * s, foot + Vector2(28, -60) * s, foot + Vector2(40, -80) * s, 8), 10 * s, 3 * s), bark, 4.0)
	_shape(_tube(PackedVector2Array([foot + Vector2(0, -8) * s, foot + Vector2(-3, -52) * s, foot + Vector2(2, -96) * s]), 24 * s, 15 * s), bark, 5.0)
	var h: Vector2 = foot + Vector2(0, -122) * s
	var lobes: Array = [[Vector2(-24, 8), 26.0], [Vector2(24, 8), 26.0], [Vector2(-12, -18), 26.0], [Vector2(14, -20), 24.0], [Vector2(0, 4), 30.0]]
	for lb in lobes:
		draw_circle(h + lb[0] * s, (lb[1] + 3.0) * s, INK)
	for lb in lobes:
		_disc(h + lb[0] * s, lb[1] * s, LEAF.lightened(0.25), LEAF.darkened(0.35))
	_glow(h + Vector2(-14, -22) * s, 16 * s, Color(1, 1, 0.9, 0.35))
	for e in [Vector2(-10, 12), Vector2(10, 12)]:
		draw_colored_polygon(_ell(h + e * s, 7 * s, 5 * s, 12), Color(0.06, 0.08, 0.03))
		_glow(h + e * s, 10 * s, Color(NATURE_GLOW, 0.9))
		draw_circle(h + e * s, 2.6 * s, Color(0.95, 1.0, 0.8))


func _bg(glow: Color, alpha: float) -> void:
	var inner := Color(0.14, 0.11, 0.11)
	match faction:
		&"shadow": inner = Color(0.13, 0.11, 0.18)
		&"neutral": inner = Color(0.12, 0.13, 0.11)
		&"ice": inner = Color(0.10, 0.12, 0.17)
		&"nature": inner = Color(0.10, 0.13, 0.09)
	draw_rect(Rect2(0, 0, 256, 256), inner)
	_disc(C, 182, Color(glow, alpha), Color(glow, 0.0), 48)


func _faction_glow() -> Color:
	match faction:
		&"shadow": return SHADOW_GLOW
		&"neutral": return NEUTRAL_GLOW
		&"ice": return ICE_GLOW
		&"nature": return NATURE_GLOW
	return FIRE_GLOW


func _team() -> Color:
	match faction:
		&"shadow": return SHADOW_TEAM
		&"ice": return ICE_TEAM
		&"nature": return NATURE_TEAM
		&"neutral": return STONE
	return FIRE_TEAM


func _portrait_bg() -> void:
	# Ice models are pale and Nature models green: a deeper, less bright halo keeps them readable at 32 px.
	match faction:
		&"ice": _bg(Color(0.25, 0.48, 0.90), 0.34)
		&"nature": _bg(Color(0.50, 0.66, 0.30), 0.28)
		_: _bg(_faction_glow(), 0.35)


# ---------------------------------------------------------------- spells
func _spell() -> void:
	match id:
		&"fireball":
			_bg(FIRE_GLOW, 0.5)
			_xf(Vector2(150, 152), -PI * 0.25)
			_fire(Vector2(0, 40), 112, 210)
			_rs()
			_glow(Vector2(150, 152), 96, Color(1.0, 0.6, 0.2, 0.7))
			draw_circle(Vector2(150, 152), 54, INK)
			_disc(Vector2(150, 152), 50, Color(1, 0.98, 0.8), Color(1.0, 0.45, 0.08))
			_sparks(Vector2(150, 152), 90, 6, FIRE_GLOW, 11)
		&"ember_step":
			_bg(FIRE_GLOW, 0.5)
			_poly(_ell(Vector2(74, 200), 54, 20), Color(0.22, 0.08, 0.03), Color(0.1, 0.03, 0.02), 5.0)
			var ring := _ell(Vector2(74, 200), 46, 15)
			ring.append(ring[0])
			draw_polyline(ring, FIRE_GLOW, 5, true)
			_fire(Vector2(62, 204), 24, 40, false)
			_fire(Vector2(90, 206), 18, 30, false)
			_fire(Vector2(186, 150), 72, 124)
			var path := _bez(Vector2(84, 168), Vector2(100, 96), Vector2(150, 84), 20)
			for t in [0.2, 0.5, 0.8]:
				var i: int = int(t * 20.0)
				var p: Vector2 = path[i]
				var d: Vector2 = (path[mini(i + 1, 20)] - path[maxi(i - 1, 0)]).normalized()
				var nor := Vector2(-d.y, d.x)
				_stroke(PackedVector2Array([p - d * 12 + nor * 16, p + d * 8, p - d * 12 - nor * 16]), 10, GOLD)
		&"kindle":
			_bg(FIRE_GLOW, 0.5)
			var ring := _ell(Vector2(128, 200), 100, 30)
			ring.append(ring[0])
			draw_polyline(ring, INK, 14, true)
			draw_polyline(ring, FIRE_GLOW.lightened(0.3), 7, true)
			_fire(Vector2(58, 204), 44, 86)
			_fire(Vector2(198, 204), 44, 86)
			_fire(Vector2(128, 210), 84, 172)
			_sparks(Vector2(128, 120), 110, 7, FIRE_GLOW, 5)
		&"shadow_lance":
			_bg(SHADOW_GLOW, 0.5)
			_xf(C, PI * 0.25, Vector2(0.45, 1.0))
			_glow(Vector2.ZERO, 128, Color(SHADOW_GLOW, 0.75))
			_xf(C, PI * 0.25)
			_poly(PackedVector2Array([Vector2(0, -120), Vector2(24, -60), Vector2(10, -70), Vector2(10, 96), Vector2(0, 118),
				Vector2(-10, 96), Vector2(-10, -70), Vector2(-24, -60)]), Color(0.97, 0.88, 1.0), Color(0.45, 0.15, 0.7))
			draw_line(Vector2(0, -100), Vector2(0, 100), Color(1, 0.95, 1, 0.9), 3)
			for k in 3:
				var y: float = 40.0 + k * 26.0
				draw_polyline(PackedVector2Array([Vector2(-12, y), Vector2(-26, y + 16), Vector2(-16, y + 34)]), Color(SHADOW_GLOW.lightened(0.4), 0.8), 4, true)
				draw_polyline(PackedVector2Array([Vector2(12, y), Vector2(26, y + 16), Vector2(16, y + 34)]), Color(SHADOW_GLOW.lightened(0.4), 0.8), 4, true)
			_rs()
			_sparks(C, 110, 5, SHADOW_GLOW, 7)
		&"soul_siphon":
			_bg(SHADOW_GLOW, 0.5)
			_poly(_ell(Vector2(128, 190), 104, 38), Color(0.22, 0.07, 0.35), Color(0.1, 0.03, 0.16), 6.0)
			_xf(Vector2(128, 190), 0.0, Vector2(1.0, 0.36))
			for k in 3:
				var a0: float = k * 2.1
				draw_arc(Vector2.ZERO, 88.0 - k * 26.0, a0, a0 + PI * 1.2, 24, Color(SHADOW_GLOW, 0.9), 9, true)
			_rs()
			for w in [[Vector2(70, 176), 0.45, 70.0], [Vector2(186, 176), -0.45, 70.0], [Vector2(128, 170), 0.0, 120.0]]:
				_xf(w[0], w[1])
				_glow(Vector2(0, -w[2] * 0.4), w[2] * 0.6, Color(SHADOW_GLOW, 0.5))
				_poly(_flame_pts(Vector2.ZERO, w[2] * 0.42, w[2]), Color(0.97, 0.9, 1.0), Color(0.55, 0.22, 0.85))
				_rs()
			_ball(Vector2(128, 44), 14, Color(0.9, 0.3, 0.55), 4.0)
			_glow(Vector2(128, 44), 34, Color(1.0, 0.4, 0.6, 0.5))
		&"umbral_shroud":
			_bg(SHADOW_GLOW, 0.5)
			_disc(Vector2(128, 132), 104, Color(0.2, 0.05, 0.35, 0.0), Color(0.55, 0.25, 0.85, 0.55))
			_hood(Vector2(128, 136), Color(0.42, 0.26, 0.6), Color(0.08, 0.04, 0.14))
			draw_arc(Vector2(128, 132), 104, 0, TAU, 64, Color(SHADOW_GLOW.lightened(0.3), 0.9), 4, true)
			_sheen(Vector2(128, 132), 90, PI * 1.1, PI * 1.45, 7)
		&"rime_bolt":
			_bg(ICE_GLOW, 0.5)
			var tail := Vector2(22, 234)
			var head := Vector2(124, 132)
			var dd: Vector2 = (head - tail).normalized()
			var nn := Vector2(-dd.y, dd.x)
			_poly(_tube(PackedVector2Array([tail, tail.lerp(head, 0.5), head]), 4, 62), Color(ICE_PALE, 0.8), Color(ICE_GLOW, 0.05), 0.0)
			for k in [-1.0, 0.0, 1.0]:
				var a0: Vector2 = tail + nn * k * 20.0 + dd * (26.0 + absf(k) * 30.0)
				var a1: Vector2 = head + nn * k * 18.0
				draw_polyline(PackedVector2Array([a0, a1]), Color(1, 1, 1, 0.85), 7.0 - absf(k) * 2.0, true)
			for fr in [[Vector2(58, 170), 0.6], [Vector2(92, 214), 0.45], [Vector2(40, 200), 0.35]]:
				var fp: Vector2 = fr[0]
				_ice_shard(fp, fp + dd * 26.0 * float(fr[1]) * 1.6, 12.0 * float(fr[1]) + 4.0, ICE_TEAM, 3.0)
			_glow(Vector2(170, 86), 96, Color(ICE_GLOW, 0.6))
			_ice_shard(Vector2(104, 152), Vector2(226, 30), 58, ICE_TEAM, 6.0)
			_star4(Vector2(222, 34), 24, Color.WHITE)
			_sparks(Vector2(140, 120), 96, 6, ICE_GLOW, 41)
		&"flash_freeze":
			_bg(ICE_GLOW, 0.5)
			var gc := Vector2(128, 190)
			_poly(_ell(gc, 110, 38), Color(0.62, 0.85, 1.0), Color(0.18, 0.38, 0.62), 6.0)
			var ring := _ell(gc, 92, 30)
			ring.append(ring[0])
			draw_polyline(ring, Color(1, 1, 1, 0.85), 5, true)
			var angles: Array[float] = []
			for i in 10:
				angles.append(TAU * float(i) / 10.0 + 0.2)
			angles.sort_custom(func(a: float, b: float) -> bool: return sin(a) < sin(b))
			var drew_flake := false
			for a in angles:
				if not drew_flake and sin(a) > -0.2:
					drew_flake = true
					_glow(Vector2(128, 104), 92, Color(ICE_PALE, 0.7))
					_snowflake(Vector2(128, 104), 66, Color(0.92, 0.98, 1.0), 9.0, 6.0, -PI * 0.5)
				var p: Vector2 = gc + Vector2(cos(a) * 94.0, sin(a) * 30.0)
				var front: float = (sin(a) + 1.0) * 0.5
				var tip: Vector2 = p + Vector2(cos(a) * 30.0, -58.0 - front * 20.0)
				_ice_shard(p + Vector2(0, 6), tip, 22.0 + front * 12.0, ICE_TEAM.darkened(0.25 * (1.0 - front)), 5.0)
			_sparks(Vector2(128, 120), 116, 6, ICE_GLOW, 43)
		&"rime_aegis":
			_bg(ICE_GLOW, 0.5)
			var gc := Vector2(128, 206)
			_poly(_ell(gc, 104, 28), Color(0.40, 0.62, 0.85), Color(0.12, 0.25, 0.42), 5.0)
			var dome := _ell(gc, 114, 150, 32, PI, TAU)
			_poly(dome, Color(ICE_PALE, 0.45), Color(ICE_TEAM, 0.14), 0.0)
			for k in [0.42, 0.78]:
				var mer := _ell(gc, 114.0 * k, 150, 20, PI, TAU)
				draw_polyline(mer, Color(ICE_PALE, 0.4), 3, true)
			var lat := _ell(gc + Vector2(0, -84), 92, 20, 24, 0.0, PI)
			draw_polyline(lat, Color(ICE_PALE, 0.4), 3, true)
			draw_polyline(dome, INK, 13, true)
			draw_polyline(dome, Color(0.85, 0.96, 1.0), 6, true)
			var sc := Vector2(128, 140)
			draw_circle(sc, 60, INK)
			_disc(sc, 56, Color(0.80, 0.94, 1.0, 0.95), Color(0.30, 0.58, 0.88, 0.95))
			draw_arc(sc, 50, 0, TAU, 40, FROST_SILVER.darkened(0.1), 10, true)
			draw_arc(sc, 50, PI * 1.05, PI * 1.55, 16, Color(1, 1, 1, 0.8), 4, true)
			_snowflake(sc, 30, Color(1, 1, 1), 6.0, 4.0)
			_sheen(gc, 86, PI * 1.12, PI * 1.38, 8)
			_sparks(Vector2(128, 110), 110, 5, ICE_GLOW, 47)
		&"thornburst":
			_bg(NATURE_GLOW, 0.5)
			var gc := Vector2(128, 196)
			_poly(_ell(gc, 108, 36), Color(0.36, 0.30, 0.16), Color(0.14, 0.11, 0.06), 6.0)
			for seg in [[Vector2(60, 196), Vector2(84, 186), Vector2(96, 200)], [Vector2(150, 206), Vector2(174, 192), Vector2(198, 198)],
					[Vector2(118, 214), Vector2(128, 222)]]:
				draw_polyline(PackedVector2Array(seg), Color(NATURE_GLOW, 0.5), 9, true)
				draw_polyline(PackedVector2Array(seg), Color(0.9, 1.0, 0.7), 3, true)
			_thorn(Vector2(76, 190), Vector2(46, 100), 30, 0.12)
			_thorn(Vector2(182, 190), Vector2(216, 96), 30, -0.12)
			_thorn(Vector2(128, 198), Vector2(120, 26), 50, 0.1)
			_thorn(Vector2(98, 212), Vector2(72, 138), 32, 0.15)
			_thorn(Vector2(162, 214), Vector2(194, 146), 32, -0.15)
			var rng := RandomNumberGenerator.new()
			rng.seed = 51
			for i in 6:
				var p := Vector2(rng.randf_range(40, 216), rng.randf_range(60, 150))
				var r: float = rng.randf_range(4, 8)
				var a0: float = rng.randf() * TAU
				_poly(_ell(p, r, r * 0.8, 6, a0, a0 + TAU), Color(0.45, 0.36, 0.2), Color(0.2, 0.15, 0.08), 3.0)
			_sparks(Vector2(128, 120), 110, 5, NATURE_GLOW, 53)
		&"wild_bloom":
			_bg(NATURE_GLOW, 0.5)
			var ring := _ell(Vector2(128, 204), 104, 30)
			ring.append(ring[0])
			draw_polyline(ring, INK, 14, true)
			draw_polyline(ring, NATURE_GLOW, 7, true)
			_leaf(Vector2(128, 176), Vector2(46, 196), 40, LEAF, 0.15)
			_leaf(Vector2(128, 176), Vector2(212, 190), 40, LEAF, -0.15)
			_shape(_tube(PackedVector2Array([Vector2(128, 200), Vector2(126, 150), Vector2(128, 120)]), 12, 10), NATURE_DARK.lightened(0.2), 4.0)
			_flower(Vector2(128, 110), 84, 6, BLOSSOM, Color(1.0, 0.9, 0.4), -PI * 0.5)
			var rng := RandomNumberGenerator.new()
			rng.seed = 57
			for i in 5:
				var p := Vector2(rng.randf_range(34, 222), rng.randf_range(30, 170))
				if p.distance_to(Vector2(128, 110)) < 90.0:
					p = Vector2(128, 110) + (p - Vector2(128, 110)).normalized() * 96.0
				_xf(p, rng.randf() * TAU)
				_poly(_ell(Vector2.ZERO, 9, 5, 12), BLOSSOM.lightened(0.4), BLOSSOM.darkened(0.1), 3.0)
				_rs()
			for p in [Vector2(40, 72), Vector2(218, 64), Vector2(214, 150)]:
				_glow(p, 24, Color(NATURE_GLOW, 0.6))
				var plus: Array[PackedVector2Array] = Geometry2D.merge_polygons(_rect(p + Vector2(-13, -4), p + Vector2(13, 4)),
					_rect(p + Vector2(-4, -13), p + Vector2(4, 13)))
				if plus.size() > 0:
					_poly(plus[0], Color(0.92, 1.0, 0.75), Color(0.6, 0.95, 0.35), 4.0)
		&"call_the_thicket":
			_bg(NATURE_GLOW, 0.5)
			var gc := Vector2(128, 206)
			_poly(_ell(gc, 108, 32), Color(0.28, 0.40, 0.16), Color(0.10, 0.16, 0.06), 5.0)
			var ring := _ell(gc, 90, 24)
			ring.append(ring[0])
			draw_polyline(ring, Color(NATURE_GLOW, 0.9), 5, true)
			_glow(gc + Vector2(0, -10), 90, Color(NATURE_GLOW, 0.35))
			_sapling(Vector2(58, 196), 0.66)
			_sapling(Vector2(198, 196), 0.66)
			_sapling(Vector2(128, 218), 1.12)
			_sparks(Vector2(128, 120), 116, 6, NATURE_GLOW, 59)
		_:
			_bg(_faction_glow(), 0.5)
			_star4(C, 70, Color.WHITE)


# ---------------------------------------------------------------- items
func _item() -> void:
	var tc: Color = TIER_COLORS[clampi(tier, 0, 4)]
	_glow(C, 124, Color(tc, 0.16 if tier == 0 else 0.26))
	match id:
		&"ember_shard":
			_glow(C, 100, Color(FIRE_GLOW, 0.5))
			_poly(PackedVector2Array([Vector2(128, 22), Vector2(170, 80), Vector2(160, 196), Vector2(128, 234), Vector2(96, 196), Vector2(86, 80)]),
				Color(1.0, 0.85, 0.45), Color(0.8, 0.22, 0.05))
			draw_colored_polygon(PackedVector2Array([Vector2(128, 22), Vector2(86, 80), Vector2(96, 196), Vector2(128, 234), Vector2(116, 120)]), Color(0.3, 0.02, 0.0, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(128, 22), Vector2(170, 80), Vector2(140, 96)]), Color(1, 1, 1, 0.45))
			_glow(Vector2(132, 132), 42, Color(1, 0.95, 0.7, 0.6))
			_sparks(C, 112, 6, FIRE_GLOW, 3)
		&"whetted_fang":
			var left := _bez(Vector2(62, 52), Vector2(116, 150), Vector2(92, 234), 20)
			var right := _bez(Vector2(146, 52), Vector2(212, 124), Vector2(92, 234), 20)
			right.reverse()
			for i in range(1, right.size()):
				left.append(right[i])
			_poly(left, BONE.lightened(0.25), BONE.darkened(0.25))
			draw_polyline(_bez(Vector2(132, 70), Vector2(176, 130), Vector2(110, 206), 12), Color(1, 1, 1, 0.55), 5, true)
			_shape(_rect(Vector2(52, 30), Vector2(156, 58)), BRONZE, 5.0)
			_star4(Vector2(176, 116), 26, Color.WHITE)
		&"ironbark_plate":
			_shape(PackedVector2Array([Vector2(56, 64), Vector2(98, 46), Vector2(128, 62), Vector2(158, 46), Vector2(200, 64),
				Vector2(204, 124), Vector2(184, 196), Vector2(128, 228), Vector2(72, 196), Vector2(52, 124)]), Color(0.52, 0.37, 0.22))
			for i in 4:
				var x: float = 84.0 + i * 30.0
				draw_polyline(PackedVector2Array([Vector2(x, 72), Vector2(x + 6, 120), Vector2(x - 4, 170), Vector2(x + 2, 204)]), Color(0.2, 0.11, 0.05, 0.6), 4, true)
			_stroke(PackedVector2Array([Vector2(56, 64), Vector2(98, 46), Vector2(128, 62), Vector2(158, 46), Vector2(200, 64)]), 10, STEEL)
			_stroke(PackedVector2Array([Vector2(128, 66), Vector2(128, 222)]), 8, STEEL)
			for pt in [Vector2(80, 96), Vector2(176, 96), Vector2(90, 178), Vector2(166, 178)]:
				_ball(pt, 9, STEEL, 4.0)
		&"wisp_lantern":
			_glow(Vector2(128, 140), 118, Color(0.7, 1.0, 0.8, 0.45))
			draw_arc(Vector2(128, 66), 26, PI, TAU, 20, INK, 14, true)
			draw_arc(Vector2(128, 66), 26, PI, TAU, 20, BRONZE.lightened(0.2), 7, true)
			_poly(_rect(Vector2(102, 92), Vector2(154, 188)), Color(0.85, 1, 0.9), Color(0.3, 0.7, 0.55))
			_glow(Vector2(128, 142), 44, Color(1, 1, 0.9, 0.85))
			_poly(_flame_pts(Vector2(128, 172), 30, 64), Color(1, 1, 1), Color(0.55, 1.0, 0.8), 0.0)
			for x in [104.0, 152.0]:
				_stroke(PackedVector2Array([Vector2(x, 92), Vector2(x, 188)]), 6, BRONZE, 4.0)
			_shape(PackedVector2Array([Vector2(88, 68), Vector2(168, 68), Vector2(156, 94), Vector2(100, 94)]), BRONZE)
			_shape(PackedVector2Array([Vector2(96, 186), Vector2(160, 186), Vector2(174, 212), Vector2(82, 212)]), BRONZE)
		&"duskglass":
			_xf(Vector2(160, 160), -PI * 0.25)
			_shape(_rect(Vector2(-12, 0), Vector2(12, 86)), WOOD)
			_shape(_rect(Vector2(-17, -6), Vector2(17, 16)), BRONZE, 5.0)
			_rs()
			draw_circle(Vector2(110, 110), 72, INK)
			_disc(Vector2(110, 110), 68, SILVER.lightened(0.4), SILVER.darkened(0.2))
			_disc(Vector2(110, 110), 52, Color(0.85, 0.65, 1.0), Color(0.3, 0.1, 0.5))
			_glow(Vector2(110, 110), 40, Color(SHADOW_GLOW, 0.6))
			_sheen(Vector2(110, 110), 40, PI * 1.05, PI * 1.45, 7)
		&"mana_thread":
			_glow(Vector2(128, 128), 110, Color(0.4, 0.6, 1.0, 0.45))
			_shape(_rect(Vector2(94, 68), Vector2(162, 192)), Color(0.28, 0.45, 1.0))
			for i in 7:
				var y: float = 80.0 + i * 16.0
				draw_line(Vector2(97, y), Vector2(159, y + 6), Color(0.7, 0.88, 1.0, 0.6), 3)
			_shape(_rect(Vector2(70, 50), Vector2(186, 72)), WOOD, 5.0)
			_shape(_rect(Vector2(70, 188), Vector2(186, 210)), WOOD, 5.0)
			var th := PackedVector2Array()
			for i in 17:
				var t: float = float(i) / 16.0
				th.append(Vector2(160, 150).lerp(Vector2(230, 236), t) + Vector2(1, -1).normalized() * sin(t * TAU * 1.5) * 12.0)
			draw_polyline(th, Color(0.45, 0.6, 1.0, 0.45), 14, true)
			draw_polyline(th, Color(0.85, 0.93, 1.0), 4, true)
		&"swiftsoles":
			for i in 3:
				draw_line(Vector2(20, 150 + i * 22), Vector2(70 - i * 10, 150 + i * 22), Color(1, 1, 1, 0.5), 5)
			_shape(PackedVector2Array([Vector2(100, 72), Vector2(28, 44), Vector2(46, 72), Vector2(20, 88), Vector2(50, 102),
				Vector2(32, 120), Vector2(100, 118)]), Color(0.96, 0.95, 0.9))
			_boot(Color(0.62, 0.40, 0.2), Color(0.85, 0.65, 0.35))
			for i in 3:
				draw_line(Vector2(104, 80 + i * 20), Vector2(140, 88 + i * 20), Color(0.95, 0.85, 0.6), 4)
		&"bone_charm":
			_stroke(PackedVector2Array([Vector2(92, 110), Vector2(104, 44), Vector2(128, 30), Vector2(152, 44), Vector2(164, 110)]), 4, Color(0.5, 0.35, 0.25), 4.0)
			_xf(Vector2(128, 142), -PI / 5.0)
			var ends := [Vector2(-70, -18), Vector2(-70, 18), Vector2(70, -18), Vector2(70, 18)]
			for e in ends:
				draw_circle(e, 27, INK)
			draw_rect(Rect2(-72, -19, 144, 38), INK)
			for e in ends:
				_disc(e, 23, BONE.lightened(0.2), BONE.darkened(0.2))
			draw_rect(Rect2(-72, -15, 144, 30), BONE)
			draw_rect(Rect2(-72, 3, 144, 12), Color(0.6, 0.5, 0.38, 0.45))
			draw_line(Vector2(-60, -8), Vector2(60, -8), Color(1, 1, 1, 0.5), 4)
			_rs()
			_ball(Vector2(128, 30), 13, SHADOW_TEAM, 4.0)
		&"cinder_ring":
			draw_arc(Vector2(128, 150), 62, 0, TAU, 48, INK, 32, true)
			draw_arc(Vector2(128, 150), 62, 0, TAU, 48, GOLD.darkened(0.2), 22, true)
			draw_arc(Vector2(128, 150), 62, PI * 1.0, PI * 1.4, 16, Color(1, 1, 0.8, 0.6), 6, true)
			_shape(PackedVector2Array([Vector2(96, 96), Vector2(160, 96), Vector2(148, 72), Vector2(108, 72)]), GOLD)
			_glow(Vector2(128, 66), 60, Color(FIRE_GLOW, 0.6))
			_poly(_ell(Vector2(128, 66), 30, 30, 6, -PI * 0.5, TAU - PI * 0.5), Color(1.0, 0.8, 0.4), Color(0.85, 0.2, 0.05))
			_star4(Vector2(118, 56), 12, Color.WHITE)
			_sparks(Vector2(128, 66), 70, 4, FIRE_GLOW, 9)
		&"gloom_ink":
			_xf(Vector2(134, 96), PI * 0.25)
			var q := PackedVector2Array([Vector2(0, 0), Vector2(-16, -40), Vector2(-12, -92), Vector2(0, -128), Vector2(15, -82), Vector2(13, -36)])
			_poly(q, Color(0.95, 0.9, 1.0), Color(0.55, 0.45, 0.72))
			draw_line(Vector2(0, 0), Vector2(0, -120), Color(0.3, 0.2, 0.4), 3)
			_rs()
			_glow(Vector2(128, 170), 80, Color(SHADOW_GLOW, 0.4))
			_shape(_rect(Vector2(108, 80), Vector2(148, 112)), Color(0.3, 0.26, 0.36))
			_shape(_rect(Vector2(102, 62), Vector2(154, 84)), WOOD, 5.0)
			_poly(PackedVector2Array([Vector2(82, 110), Vector2(174, 110), Vector2(188, 150), Vector2(178, 212), Vector2(78, 212), Vector2(68, 150)]),
				Color(0.45, 0.2, 0.7), Color(0.1, 0.03, 0.18))
			draw_line(Vector2(84, 132), Vector2(172, 132), Color(0.85, 0.6, 1.0, 0.8), 4)
			draw_line(Vector2(84, 150), Vector2(90, 196), Color(1, 1, 1, 0.4), 6)
		&"warden_scale":
			var pts := _ell(Vector2(128, 104), 76, 64, 20, PI, TAU)
			pts.append(Vector2(196, 142))
			pts.append(Vector2(128, 234))
			pts.append(Vector2(60, 142))
			_shape(pts, Color(0.36, 0.54, 0.42))
			for k in 3:
				draw_arc(Vector2(128, 106.0 + k * 34.0), 58.0 - k * 14.0, PI * 1.1, PI * 1.9, 16, Color(0.75, 0.95, 0.8, 0.55), 5, true)
			draw_line(Vector2(128, 50), Vector2(128, 220), Color(0.1, 0.2, 0.12, 0.5), 5)
			_sheen(Vector2(128, 104), 64, PI * 1.1, PI * 1.35, 6)
		&"vital_root":
			_glow(Vector2(128, 120), 100, Color(0.5, 1.0, 0.4, 0.35))
			_shape(_tube(_bez(Vector2(126, 70), Vector2(96, 150), Vector2(134, 234), 16), 40, 6), Color(0.5, 0.33, 0.2))
			_shape(_tube(_bez(Vector2(112, 146), Vector2(80, 170), Vector2(52, 218), 10), 18, 4), Color(0.5, 0.33, 0.2), 5.0)
			_shape(_tube(_bez(Vector2(118, 176), Vector2(160, 190), Vector2(200, 224), 10), 16, 4), Color(0.5, 0.33, 0.2), 5.0)
			_shape(_tube(_bez(Vector2(126, 74), Vector2(84, 40), Vector2(46, 56), 12), 40, 0, true), Color(0.4, 0.78, 0.3))
			_shape(_tube(_bez(Vector2(128, 74), Vector2(170, 30), Vector2(212, 48), 12), 44, 0, true), Color(0.45, 0.82, 0.3))
			_ball(Vector2(128, 112), 16, Color(0.75, 1.0, 0.45), 4.0)
			_glow(Vector2(128, 112), 36, Color(0.8, 1.0, 0.5, 0.6))
		&"blazing_edge":
			_xf(Vector2(92, 184), PI * 0.25)
			for k in 4:
				_fire(Vector2(0, -40.0 - k * 34.0), 34, 60, k == 0)
			_rs()
			_sword(Vector2(92, 184), PI * 0.25, 164, 30, Color(1.0, 0.9, 0.65), Color(0.9, 0.45, 0.2), BRONZE)
			_sparks(Vector2(150, 110), 80, 5, FIRE_GLOW, 21)
		&"nightveil_cloak":
			_poly(PackedVector2Array([Vector2(96, 44), Vector2(160, 44), Vector2(178, 82), Vector2(204, 212), Vector2(172, 202), Vector2(150, 220),
				Vector2(128, 206), Vector2(106, 220), Vector2(84, 202), Vector2(52, 212), Vector2(78, 82)]), Color(0.38, 0.24, 0.56), Color(0.08, 0.04, 0.15))
			for x in [104.0, 128.0, 152.0]:
				draw_line(Vector2(x, 70), Vector2(x + (x - 128.0) * 0.5, 200), Color(0, 0, 0, 0.35), 5)
			var rng := RandomNumberGenerator.new()
			rng.seed = 4
			for i in 9:
				draw_circle(Vector2(rng.randf_range(84, 172), rng.randf_range(80, 196)), rng.randf_range(1.5, 3.2), Color(0.95, 0.9, 1.0, 0.9))
			_ball(Vector2(128, 56), 16, SILVER, 5.0)
			_glow(Vector2(128, 56), 14, Color(SHADOW_GLOW, 0.9))
		&"pyre_staff":
			_xf(Vector2(128, 140), 0.3)
			_shape(_rect(Vector2(-9, -52), Vector2(9, 112)), WOOD, 6.0)
			_shape(PackedVector2Array([Vector2(-26, -64), Vector2(26, -64), Vector2(12, -40), Vector2(-12, -40)]), BRONZE, 5.0)
			_fire(Vector2(0, -58), 64, 110)
			_rs()
		&"ashen_greaves":
			_boot(Color(0.46, 0.44, 0.44), STEEL)
			_shape(_ell(Vector2(122, 70), 30, 20), STEEL, 5.0)
			for y in [104.0, 136.0]:
				draw_line(Vector2(90, y), Vector2(150, y), INK, 5)
			for seg in [[Vector2(100, 160), Vector2(124, 180), Vector2(118, 204)], [Vector2(160, 170), Vector2(176, 190)], [Vector2(134, 90), Vector2(126, 120)]]:
				draw_polyline(PackedVector2Array(seg), Color(FIRE_GLOW, 0.5), 9, true)
				draw_polyline(PackedVector2Array(seg), Color(1.0, 0.85, 0.5), 3, true)
			_sparks(Vector2(120, 60), 60, 5, FIRE_GLOW, 13)
		&"grave_pact":
			_sword(Vector2(76, 200), PI * 0.25, 170, 22, STEEL.lightened(0.2), STEEL.darkened(0.3), SILVER)
			_skull(Vector2(128, 124), 1.0, Color(0.9, 0.3, 0.45))
		&"warlords_horn":
			var cpts := _bez(Vector2(206, 84), Vector2(84, 20), Vector2(56, 200), 20)
			_shape(_tube(cpts, 62, 8), BONE)
			for t in [4, 9, 14]:
				var p: Vector2 = cpts[t]
				var d: Vector2 = (cpts[t + 1] - cpts[t - 1]).normalized()
				var nor := Vector2(-d.y, d.x)
				var hw: float = lerpf(62.0, 8.0, float(t) / 20.0) * 0.55
				_shape(PackedVector2Array([p + nor * hw - d * 6, p + nor * hw + d * 6, p - nor * hw + d * 6, p - nor * hw - d * 6]), BRONZE, 4.0)
			_poly(_ell(Vector2(204, 84), 12, 30), Color(0.15, 0.08, 0.05), Color(0.05, 0.02, 0.02), 5.0)
		&"siphon_idol":
			_glow(Vector2(128, 120), 110, Color(SHADOW_GLOW, 0.45))
			_shape(PackedVector2Array([Vector2(94, 124), Vector2(162, 124), Vector2(178, 216), Vector2(78, 216)]), Color(0.32, 0.26, 0.4))
			_ball(Vector2(128, 90), 42, Color(0.36, 0.3, 0.46))
			for e in [Vector2(112, 84), Vector2(144, 84)]:
				_glow(e, 16, Color(SHADOW_GLOW, 0.9))
				draw_colored_polygon(_ell(e, 8, 4, 12), Color(0.95, 0.85, 1.0))
			draw_colored_polygon(_ell(Vector2(128, 110), 12, 9, 16), Color(0.04, 0.0, 0.08))
			for k in 6:
				var a: float = -PI * 0.9 + k * 0.32
				var p := Vector2(128, 110) + Vector2(cos(a), sin(a)) * (96.0 - k * 12.0)
				_glow(p, 14, Color(SHADOW_GLOW, 0.7))
				draw_circle(p, 4, Color(0.95, 0.85, 1.0))
			draw_line(Vector2(100, 150), Vector2(156, 150), Color(0.7, 0.4, 1.0, 0.6), 4)
		&"emberwake_band":
			_xf(C, 0.0, Vector2(1.0, 0.55))
			draw_arc(Vector2.ZERO, 76, PI, TAU, 32, INK, 46, true)
			draw_arc(Vector2.ZERO, 76, PI, TAU, 32, BRONZE.darkened(0.45), 36, true)
			draw_arc(Vector2.ZERO, 76, 0, PI, 32, INK, 46, true)
			draw_arc(Vector2.ZERO, 76, 0, PI, 32, BRONZE.lightened(0.1), 36, true)
			_rs()
			for k in 5:
				var a: float = PI * (0.15 + k * 0.175)
				var p := C + Vector2(cos(a) * 76.0, sin(a) * 76.0 * 0.55)
				_glow(p, 16, Color(FIRE_GLOW, 0.8))
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -8), p + Vector2(6, 0), p + Vector2(0, 8), p + Vector2(-6, 0)]), Color(1.0, 0.9, 0.5))
			_fire(Vector2(128, 96), 44, 70)
		&"bulwark_of_ruin":
			var s := PackedVector2Array([Vector2(66, 38), Vector2(190, 38), Vector2(200, 58), Vector2(200, 168), Vector2(128, 232), Vector2(56, 168), Vector2(56, 58)])
			_shape(s, Color(0.44, 0.44, 0.47))
			var rim := s.duplicate()
			rim.append(s[0])
			draw_polyline(rim, SILVER.lightened(0.2), 6, true)
			for seg in [[Vector2(80, 60), Vector2(100, 96), Vector2(88, 128)], [Vector2(176, 150), Vector2(156, 176), Vector2(162, 200)]]:
				draw_polyline(PackedVector2Array(seg), Color(0.1, 0.08, 0.12), 5, true)
			_glow(Vector2(128, 120), 44, Color(SHADOW_GLOW, 0.7))
			draw_arc(Vector2(128, 120), 28, 0, TAU, 32, Color(0.9, 0.75, 1.0), 5, true)
			draw_line(Vector2(128, 96), Vector2(128, 144), Color(0.9, 0.75, 1.0), 5)
		&"inferno_blade":
			_glow(Vector2(128, 110), 120, Color(1.0, 0.35, 0.1, 0.55))
			_fire(Vector2(92, 190), 70, 150, false)
			_fire(Vector2(164, 190), 70, 150, false)
			_fire(Vector2(128, 160), 96, 150, false)
			_sword(Vector2(128, 196), 0.0, 176, 42, Color(1.0, 0.7, 0.3), Color(0.5, 0.06, 0.02), GOLD)
			_sparks(Vector2(128, 110), 110, 7, FIRE_GLOW, 17)
		&"shadowstride":
			for i in 3:
				var y: float = 120.0 + i * 30.0
				_poly(_tube(PackedVector2Array([Vector2(90, y), Vector2(50, y - 8), Vector2(14, y - 4)]), 18, 2), Color(SHADOW_GLOW.lightened(0.3), 0.9), Color(SHADOW_GLOW, 0.4), 0.0)
			_shape(PackedVector2Array([Vector2(100, 70), Vector2(20, 30), Vector2(40, 64), Vector2(8, 82), Vector2(44, 98),
				Vector2(24, 120), Vector2(100, 116)]), Color(0.3, 0.16, 0.45))
			_boot(Color(0.28, 0.2, 0.38), SILVER)
			_glow(Vector2(120, 46), 20, Color(SHADOW_GLOW, 0.9))
		&"staff_of_cinders":
			_xf(Vector2(128, 142), -0.25)
			_shape(_rect(Vector2(-9, -34), Vector2(9, 114)), Color(0.28, 0.18, 0.12), 6.0)
			for y in [0.0, 50.0]:
				_shape(_rect(Vector2(-12, y), Vector2(12, y + 10)), GOLD, 4.0)
			_glow(Vector2(0, -78), 70, Color(FIRE_GLOW, 0.6))
			draw_arc(Vector2(0, -78), 44, PI * 0.6, PI * 2.4, 32, INK, 20, true)
			draw_arc(Vector2(0, -78), 44, PI * 0.6, PI * 2.4, 32, GOLD.darkened(0.1), 12, true)
			draw_circle(Vector2(0, -78), 27, INK)
			_disc(Vector2(0, -78), 24, Color(1, 0.98, 0.8), Color(1.0, 0.4, 0.05))
			_fire(Vector2(0, -96), 30, 56, false)
			_rs()
			_sparks(Vector2(110, 60), 70, 6, FIRE_GLOW, 23)
		&"banner_of_embers":
			_shape(_rect(Vector2(62, 34), Vector2(76, 236)), WOOD, 6.0)
			_shape(PackedVector2Array([Vector2(69, 8), Vector2(80, 34), Vector2(58, 34)]), GOLD, 5.0)
			_poly(PackedVector2Array([Vector2(76, 46), Vector2(206, 46), Vector2(200, 204), Vector2(140, 174), Vector2(80, 204)]),
				FIRE_TEAM.lightened(0.2), Color(0.55, 0.08, 0.05))
			_shape(_rect(Vector2(70, 38), Vector2(212, 52)), GOLD, 5.0)
			_fire(Vector2(142, 150), 58, 92)
		&"gravemaw_idol":
			_glow(Vector2(128, 130), 120, Color(SHADOW_GLOW, 0.5))
			_shape(PackedVector2Array([Vector2(70, 34), Vector2(96, 60), Vector2(160, 60), Vector2(186, 34), Vector2(190, 120),
				Vector2(176, 226), Vector2(80, 226), Vector2(66, 120)]), Color(0.3, 0.25, 0.38))
			_poly(_ell(Vector2(128, 162), 46, 46), Color(0.02, 0.0, 0.04), Color(0.2, 0.05, 0.3), 5.0)
			for k in 5:
				var x: float = 92.0 + k * 18.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 124 + absf(k - 2.0) * 4.0), Vector2(x + 7, 124 + absf(k - 2.0) * 4.0), Vector2(x, 144)]), BONE)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 200 - absf(k - 2.0) * 4.0), Vector2(x + 7, 200 - absf(k - 2.0) * 4.0), Vector2(x, 182)]), BONE)
			for e in [[Vector2(100, 90), 0.35], [Vector2(156, 90), -0.35]]:
				_xf(e[0], e[1])
				_glow(Vector2.ZERO, 22, Color(SHADOW_GLOW, 0.9))
				draw_colored_polygon(_ell(Vector2.ZERO, 16, 5, 12), Color(0.95, 0.85, 1.0))
				_rs()
		&"ruinwarden_mantle":
			_poly(PackedVector2Array([Vector2(40, 124), Vector2(64, 82), Vector2(100, 62), Vector2(156, 62), Vector2(192, 82), Vector2(216, 124),
				Vector2(200, 176), Vector2(170, 154), Vector2(150, 196), Vector2(128, 172), Vector2(106, 196), Vector2(86, 154), Vector2(56, 176)]),
				Color(0.40, 0.32, 0.52), Color(0.12, 0.08, 0.18))
			for p in [Vector2(74, 98), Vector2(182, 98)]:
				_shape(_ell(p, 42, 28), STONE.lightened(0.1))
				draw_arc(p, 42, PI * 1.05, PI * 1.95, 16, BRONZE.lightened(0.2), 7, true)
				draw_arc(p + Vector2(0, 8), 26, PI * 1.15, PI * 1.85, 12, Color(0.55, 0.85, 0.45, 0.8), 5, true)
			_shape(_ell(Vector2(128, 70), 34, 16), SILVER)
			_glow(Vector2(128, 70), 14, Color(SHADOW_GLOW, 0.9))
		&"phoenix_plume":
			var cp := _bez(Vector2(70, 226), Vector2(90, 100), Vector2(196, 40), 24)
			_glow(Vector2(140, 110), 110, Color(FIRE_GLOW, 0.45))
			_poly(_tube(cp, 76, 0, true), Color(1.0, 0.8, 0.3), Color(0.8, 0.12, 0.08))
			for t in [6, 10, 14, 18]:
				var p: Vector2 = cp[t]
				draw_line(p, p + Vector2(-26, 8), INK, 4)
			draw_polyline(cp, GOLD.lightened(0.3), 5, true)
			_xf(Vector2(196, 44), PI * 0.3)
			_fire(Vector2(0, 12), 34, 56)
			_rs()
		&"oath_of_embers":
			_glow(C, 110, Color(FIRE_GLOW, 0.4))
			_shape(PackedVector2Array([Vector2(66, 50), Vector2(190, 50), Vector2(184, 128), Vector2(194, 206), Vector2(70, 206), Vector2(60, 128)]), Color(0.92, 0.82, 0.6))
			_shape(_rect(Vector2(52, 36), Vector2(204, 58)), WOOD, 5.0)
			_shape(_rect(Vector2(56, 198), Vector2(208, 220)), WOOD, 5.0)
			for i in 4:
				draw_line(Vector2(84, 80 + i * 22), Vector2(172 - (i % 2) * 20, 80 + i * 22), Color(0.4, 0.25, 0.15, 0.7), 5)
			_fire(Vector2(148, 196), 44, 70)
			_ball(Vector2(148, 176), 20, FIRE_TEAM, 5.0)
		&"ember_draught":
			_potion_round(Color(1.0, 0.35, 0.12), FIRE_GLOW)
		&"dusk_vial":
			_glow(Vector2(128, 150), 90, Color(0.4, 0.5, 1.0, 0.5))
			var body := PackedVector2Array([Vector2(98, 84), Vector2(158, 84), Vector2(158, 196)])
			body.append_array(_ell(Vector2(128, 196), 30, 28, 12, 0.0, PI))
			body.append(Vector2(98, 196))
			_poly(body, Color(0.55, 0.6, 0.72, 0.9), Color(0.25, 0.28, 0.36, 0.9))
			var liq := PackedVector2Array([Vector2(102, 124), Vector2(154, 124), Vector2(154, 196)])
			liq.append_array(_ell(Vector2(128, 196), 26, 24, 12, 0.0, PI))
			liq.append(Vector2(102, 196))
			_poly(liq, Color(0.55, 0.6, 1.0), Color(0.3, 0.12, 0.7), 0.0)
			draw_line(Vector2(108, 96), Vector2(108, 200), Color(1, 1, 1, 0.45), 5)
			_shape(_rect(Vector2(106, 60), Vector2(150, 86)), SILVER, 5.0)
			_shape(_rect(Vector2(100, 40), Vector2(156, 62)), SILVER.darkened(0.2), 5.0)
			_sparks(Vector2(128, 160), 50, 3, Color(0.7, 0.8, 1.0), 31)
		&"homeward_seal":
			_shape(_tube(PackedVector2Array([Vector2(104, 170), Vector2(92, 206), Vector2(84, 238)]), 26, 22), GOLD, 5.0)
			_shape(_tube(PackedVector2Array([Vector2(152, 170), Vector2(164, 206), Vector2(172, 238)]), 26, 22), GOLD, 5.0)
			var blob := PackedVector2Array()
			for i in 48:
				var a: float = TAU * float(i) / 48.0
				blob.append(Vector2(128, 120) + Vector2(cos(a), sin(a)) * (82.0 + sin(a * 9.0) * 5.0))
			_shape(blob, Color(0.72, 0.14, 0.1))
			draw_arc(Vector2(128, 120), 58, 0, TAU, 48, Color(0.35, 0.04, 0.03, 0.8), 6, true)
			var keep := PackedVector2Array([Vector2(98, 150), Vector2(98, 96), Vector2(108, 96), Vector2(108, 106), Vector2(118, 106),
				Vector2(118, 84), Vector2(138, 84), Vector2(138, 106), Vector2(148, 106), Vector2(148, 96), Vector2(158, 96), Vector2(158, 150)])
			_poly(keep, Color(1.0, 0.55, 0.45), Color(0.85, 0.3, 0.22), 4.0)
			draw_colored_polygon(_ell(Vector2(128, 140), 9, 12, 12, PI, TAU) + PackedVector2Array([Vector2(137, 150), Vector2(119, 150)]), Color(0.35, 0.05, 0.03))
		&"owl_stone":
			_glow(Vector2(128, 136), 100, Color(1.0, 0.8, 0.3, 0.35))
			_shape(_ell(Vector2(128, 140), 88, 76), Color(0.52, 0.55, 0.6))
			_shape(PackedVector2Array([Vector2(66, 78), Vector2(84, 40), Vector2(100, 72)]), Color(0.52, 0.55, 0.6), 5.0)
			_shape(PackedVector2Array([Vector2(156, 72), Vector2(172, 40), Vector2(190, 78)]), Color(0.52, 0.55, 0.6), 5.0)
			var eye := _ell(Vector2(128, 132), 58, 30, 20, PI, TAU)
			eye.append_array(_ell(Vector2(128, 132), 58, 30, 20, 0.0, PI).slice(1, 20))
			_poly(eye, Color(1.0, 0.9, 0.45), Color(0.9, 0.55, 0.1))
			_glow(Vector2(128, 132), 50, Color(1.0, 0.85, 0.3, 0.5))
			draw_circle(Vector2(128, 132), 20, INK)
			draw_circle(Vector2(120, 124), 6, Color(1, 1, 1, 0.9))
		&"ember_crown":
			_glow(Vector2(128, 130), 120, Color(1.0, 0.7, 0.2, 0.5))
			var tips := [Vector2(52, 92), Vector2(100, 62), Vector2(156, 62), Vector2(204, 92), Vector2(128, 44)]
			for t in tips:
				_fire(t + Vector2(0, 10), 22, 38, false)
			_shape(PackedVector2Array([Vector2(52, 196), Vector2(52, 92), Vector2(82, 140), Vector2(100, 62), Vector2(116, 128), Vector2(128, 44),
				Vector2(140, 128), Vector2(156, 62), Vector2(174, 140), Vector2(204, 92), Vector2(204, 196)]), GOLD)
			_shape(_rect(Vector2(48, 168), Vector2(208, 204)), GOLD.darkened(0.1), 5.0)
			for x in [84.0, 128.0, 172.0]:
				_glow(Vector2(x, 186), 18, Color(FIRE_GLOW, 0.8))
				_ball(Vector2(x, 186), 10, FIRE_TEAM, 3.0)
		&"masters_signet":
			draw_arc(Vector2(128, 168), 54, 0, TAU, 48, INK, 30, true)
			draw_arc(Vector2(128, 168), 54, 0, TAU, 48, GOLD.darkened(0.15), 20, true)
			draw_circle(Vector2(128, 96), 62, INK)
			_disc(Vector2(128, 96), 58, GOLD.lightened(0.2), GOLD.darkened(0.3))
			_disc(Vector2(128, 96), 44, Color(0.2, 0.16, 0.18), Color(0.1, 0.08, 0.1))
			var arms := [[Vector2(0, -1), FIRE_GLOW], [Vector2(1, 0), Color(0.7, 0.92, 1.0)], [Vector2(0, 1), Color(0.75, 1.0, 0.4)], [Vector2(-1, 0), SHADOW_GLOW]]
			for a in arms:
				var d: Vector2 = a[0]
				var nor := Vector2(-d.y, d.x)
				var c0 := Vector2(128, 96)
				_glow(c0 + d * 22.0, 18, Color(a[1], 0.7))
				draw_colored_polygon(PackedVector2Array([c0 + nor * 8.0, c0 + d * 38.0, c0 - nor * 8.0]), a[1])
			draw_circle(Vector2(128, 96), 6, Color(1, 1, 0.9))
		&"frostglass_shard":
			_glow(C, 104, Color(ICE_GLOW, 0.5))
			_ice_shard(Vector2(84, 214), Vector2(46, 128), 30, ICE_TEAM.darkened(0.15), 5.0)
			_ice_shard(Vector2(176, 218), Vector2(212, 142), 26, ICE_TEAM.darkened(0.15), 5.0)
			var pts := PackedVector2Array([Vector2(128, 20), Vector2(170, 78), Vector2(162, 194), Vector2(128, 236), Vector2(94, 194), Vector2(86, 78)])
			_poly(pts, Color(0.92, 0.98, 1.0), Color(0.22, 0.48, 0.85))
			draw_colored_polygon(PackedVector2Array([Vector2(128, 20), Vector2(170, 78), Vector2(162, 194), Vector2(128, 236), Vector2(140, 120)]), Color(0.02, 0.12, 0.32, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(128, 20), Vector2(86, 78), Vector2(116, 92)]), Color(1, 1, 1, 0.55))
			draw_line(Vector2(128, 30), Vector2(128, 226), Color(1, 1, 1, 0.35), 3)
			_glow(Vector2(126, 134), 40, Color(1, 1, 1, 0.55))
			_star4(Vector2(106, 70), 20, Color.WHITE)
			_sparks(C, 112, 5, ICE_GLOW, 61)
		&"rimebound_bracers":
			# A vambrace lying diagonally: narrow wrist bottom-left, wide open elbow top-right, ice spikes on its spine.
			_glow(C, 110, Color(ICE_GLOW, 0.35))
			_xf(Vector2(124, 134), -PI * 0.25)
			for sx in [-44.0, 0.0, 44.0]:
				var ex: float = 38.0 + (sx + 60.0) * 0.1
				_ice_shard(Vector2(sx, -ex + 8.0), Vector2(sx + 14.0, -ex - 44.0 - (sx + 44.0) * 0.12), 26)
			var body := PackedVector2Array()
			body.append_array(_ell(Vector2(-84, 0), 12, 32, 12, PI * 0.5, PI * 1.5))
			body.append_array(_ell(Vector2(84, 0), 16, 48, 16, -PI * 0.5, PI * 0.5))
			_poly(body, Color(0.62, 0.74, 0.90), Color(0.20, 0.30, 0.48))
			_poly(_ell(Vector2(84, 0), 16, 48, 24), Color(0.05, 0.08, 0.14), Color(0.16, 0.22, 0.34), 5.0)
			var rim := _ell(Vector2(84, 0), 16, 48, 16, -PI * 0.5, PI * 0.5)
			draw_polyline(rim, FROST_SILVER.lightened(0.2), 6, true)
			for bx in [-44.0, 34.0]:
				var hh: float = 32.0 + (bx + 84.0) / 168.0 * 16.0
				var strap := _rect(Vector2(bx - 9, -hh - 3), Vector2(bx + 9, hh + 3))
				_shape(strap, Color(0.42, 0.28, 0.18), 4.0)
				_shape(_rect(Vector2(bx - 7, 10), Vector2(bx + 7, 26)), FROST_SILVER, 3.0)
			draw_line(Vector2(-80, -24), Vector2(78, -38), Color(1, 1, 1, 0.45), 5)
			_glow(Vector2(-5, 0), 32, Color(ICE_GLOW, 0.9))
			_poly(PackedVector2Array([Vector2(-5, -20), Vector2(11, 0), Vector2(-5, 20), Vector2(-21, 0)]), Color(0.95, 1, 1), ICE_TEAM, 4.0)
			_rs()
			_sparks(C, 110, 4, ICE_GLOW, 63)
		&"glacier_heart":
			_glow(C, 118, Color(ICE_GLOW, 0.5))
			var hc := Vector2(128, 136)
			var hp := _heart_pts(hc, 1.0)
			_poly(hp, Color(0.88, 0.97, 1.0), Color(0.20, 0.45, 0.82))
			var fc: Vector2 = hc + Vector2(-8, -14)
			var facet_on := true
			for i in range(0, hp.size() - 1, 3):
				var j: int = mini(i + 3, hp.size() - 1)
				facet_on = not facet_on
				if facet_on:
					var tri := PackedVector2Array([fc])
					for k in range(i, j + 1):
						tri.append(hp[k])
					draw_colored_polygon(tri, Color(1, 1, 1, 0.16))
			draw_colored_polygon(PackedVector2Array([fc, hp[hp.size() - 1], hp[0]]), Color(0.02, 0.12, 0.3, 0.3))
			_glow(fc, 54, Color(1, 1, 1, 0.75))
			_snowflake(fc, 22, Color(1, 1, 1), 4.0, 0.0)
			_sheen(hc + Vector2(-38, -40), 28, PI * 1.05, PI * 1.5, 6)
			_sparks(C, 112, 5, ICE_GLOW, 67)
		&"winterwall_aegis":
			_glow(C, 122, Color(ICE_GLOW, 0.45))
			for sp in [[Vector2(86, 50), Vector2(64, 10), 24.0], [Vector2(170, 50), Vector2(192, 10), 24.0], [Vector2(128, 44), Vector2(128, 4), 30.0]]:
				_ice_shard(sp[0], sp[1], sp[2])
			var sh := _kite(Vector2(128, 136), 172, 206)
			_poly(sh, Color(0.80, 0.94, 1.0), Color(0.22, 0.46, 0.80))
			var rim := sh.duplicate()
			rim.append(sh[0])
			draw_polyline(rim, FROST_SILVER.lightened(0.1), 9, true)
			var inner := _kite(Vector2(128, 136), 140, 172)
			inner.append(inner[0])
			draw_polyline(inner, Color(1, 1, 1, 0.35), 3, true)
			draw_colored_polygon(PackedVector2Array([Vector2(58, 50), Vector2(128, 40), Vector2(128, 238), Vector2(80, 196), Vector2(46, 144)]), Color(1, 1, 1, 0.12))
			_glow(Vector2(128, 126), 60, Color(1, 1, 1, 0.5))
			_snowflake(Vector2(128, 126), 52, Color(0.95, 0.99, 1.0), 8.0, 5.0)
			for seg in [[Vector2(66, 150), Vector2(84, 170), Vector2(80, 196)], [Vector2(190, 92), Vector2(174, 108)]]:
				draw_polyline(PackedVector2Array(seg), Color(1, 1, 1, 0.6), 3, true)
		&"verdant_seed":
			_glow(C, 104, Color(NATURE_GLOW, 0.45))
			var pod := PackedVector2Array()
			pod.append_array(_bez(Vector2(128, 70), Vector2(186, 100), Vector2(186, 160), 12))
			pod.append_array(_ell(Vector2(128, 160), 58, 64, 16, 0.0, PI).slice(1))
			pod.append_array(_bez(Vector2(70, 160), Vector2(70, 100), Vector2(128, 70), 12).slice(1, 12))
			_shape(pod, Color(0.62, 0.44, 0.24))
			for k in [-1.0, 1.0]:
				draw_polyline(_bez(Vector2(128, 78), Vector2(128 + k * 44, 140), Vector2(128 + k * 18, 218), 12), Color(0.25, 0.15, 0.06, 0.55), 4, true)
			var crack := PackedVector2Array([Vector2(122, 96), Vector2(132, 128), Vector2(120, 156), Vector2(130, 190)])
			draw_polyline(crack, Color(NATURE_GLOW, 0.5), 14, true)
			draw_polyline(crack, Color(0.9, 1.0, 0.7), 5, true)
			_glow(Vector2(126, 142), 40, Color(NATURE_GLOW, 0.6))
			_sheen(Vector2(128, 150), 48, PI * 1.05, PI * 1.35, 6)
			_shape(_tube(_bez(Vector2(128, 78), Vector2(122, 50), Vector2(140, 26), 10), 10, 6), NATURE_DARK.lightened(0.25), 4.0)
			_leaf(Vector2(134, 42), Vector2(74, 22), 34, LEAF, 0.2)
			_leaf(Vector2(138, 36), Vector2(200, 30), 30, LEAF.lightened(0.1), -0.25)
		&"thornweave_vest":
			var vest := PackedVector2Array([Vector2(82, 36), Vector2(106, 40), Vector2(128, 104), Vector2(150, 40), Vector2(174, 36),
				Vector2(184, 72), Vector2(204, 108), Vector2(196, 212), Vector2(128, 228), Vector2(60, 212), Vector2(52, 108), Vector2(72, 72)])
			for t in [[Vector2(52, 108), Vector2(24, 96)], [Vector2(204, 108), Vector2(232, 96)], [Vector2(60, 212), Vector2(38, 232)],
					[Vector2(196, 212), Vector2(218, 232)], [Vector2(96, 222), Vector2(88, 246)], [Vector2(160, 222), Vector2(168, 246)],
					[Vector2(56, 160), Vector2(28, 164)], [Vector2(200, 160), Vector2(228, 164)]]:
				_thorn(t[0], t[1], 16, 0.0)
			_shape(vest, NATURE_TEAM.darkened(0.2))
			for k in 9:
				var o: float = -120.0 + k * 30.0
				for dir in [1.0, -1.0]:
					var line := PackedVector2Array([Vector2(128 + o, 30), Vector2(128 + o + dir * 200.0, 230)])
					for part in Geometry2D.intersect_polyline_with_polygon(line, vest):
						draw_polyline(part, Color(0.55, 0.40, 0.22, 0.75), 5, true)
			var rimv := vest.duplicate()
			rimv.append(vest[0])
			draw_polyline(rimv, Color(0.55, 0.40, 0.22), 6, true)
			_leaf(Vector2(128, 118), Vector2(98, 146), 26, LEAF, 0.2)
			_leaf(Vector2(128, 118), Vector2(158, 146), 26, LEAF, -0.2)
			_glow(Vector2(128, 116), 22, Color(NATURE_GLOW, 0.9))
			_ball(Vector2(128, 116), 9, NATURE_GLOW, 4.0)
			draw_line(Vector2(76, 90), Vector2(70, 196), Color(1, 1, 1, 0.3), 6)
		&"bloomcaller_staff":
			_glow(Vector2(150, 76), 100, Color(BLOSSOM, 0.3))
			_xf(Vector2(128, 152), 0.28)
			_shape(_rect(Vector2(-9, -48), Vector2(9, 114)), BARK.lightened(0.1), 6.0)
			var vine := PackedVector2Array()
			for i in 21:
				var y: float = -40.0 + i * 7.0
				vine.append(Vector2(sin(i * 0.9) * 11.0, y))
			draw_polyline(vine, NATURE_DARK.lightened(0.3), 4, true)
			_leaf(Vector2(-4, -50), Vector2(-66, -64), 30, LEAF, 0.2)
			_leaf(Vector2(4, -50), Vector2(64, -70), 30, LEAF, -0.2)
			_leaf(Vector2(-4, -56), Vector2(-40, -112), 26, LEAF.lightened(0.1), 0.15)
			_leaf(Vector2(4, -56), Vector2(44, -116), 26, LEAF.lightened(0.1), -0.15)
			_rs()
			# _flower sets its own transforms: place it in canvas space at the staff head.
			_flower(Vector2(128, 152) + Vector2(0, -86).rotated(0.28), 46, 6, BLOSSOM, NATURE_GLOW, -PI * 0.5 + 0.28)
			_sparks(Vector2(150, 76), 90, 5, NATURE_GLOW, 71)
		&"heart_of_the_grove":
			_glow(C, 122, Color(NATURE_GLOW, 0.5))
			for r in [[Vector2(110, 206), Vector2(84, 236), Vector2(46, 232)], [Vector2(128, 214), Vector2(126, 236), Vector2(138, 250)],
					[Vector2(146, 206), Vector2(172, 236), Vector2(210, 232)]]:
				_shape(_tube(_bez(r[0], r[1], r[2], 10), 18, 4), BARK.lightened(0.1), 5.0)
			var hc := Vector2(128, 132)
			var hp := _heart_pts(hc, 0.92)
			_shape(hp, Color(0.58, 0.40, 0.22))
			for k in 3:
				draw_arc(hc + Vector2(0, 10), 40.0 + k * 16.0, PI * 0.15, PI * 0.85, 18, Color(0.26, 0.16, 0.07, 0.55), 4, true)
			_poly(_ell(hc + Vector2(0, 4), 30, 36), Color(0.05, 0.08, 0.02), Color(0.14, 0.2, 0.05), 5.0)
			_glow(hc + Vector2(0, 4), 50, Color(NATURE_GLOW, 0.9))
			_ball(hc + Vector2(0, 4), 18, NATURE_GLOW, 0.0)
			_shape(_tube(_bez(Vector2(128, 84), Vector2(124, 60), Vector2(132, 40), 8), 9, 5), NATURE_DARK.lightened(0.25), 4.0)
			_leaf(Vector2(130, 46), Vector2(92, 22), 28, LEAF, 0.2)
			_leaf(Vector2(130, 44), Vector2(170, 18), 28, LEAF.lightened(0.1), -0.2)
			_flower(Vector2(176, 78), 30, 5, BLOSSOM, Color(1.0, 0.9, 0.4), -PI * 0.5)
			_sheen(hc + Vector2(-35, -37), 26, PI * 1.05, PI * 1.5, 6)
		&"stillwater_orb":
			var oc := Vector2(128, 116)
			_glow(oc, 116, Color(0.45, 0.85, 1.0, 0.5))
			_shape(PackedVector2Array([Vector2(86, 192), Vector2(170, 192), Vector2(188, 232), Vector2(68, 232)]), GOLD.darkened(0.1), 6.0)
			for side in [-1.0, 1.0]:
				_shape(_tube(_bez(Vector2(128 + side * 34, 196), Vector2(128 + side * 96, 170), Vector2(128 + side * 74, 104), 12), 20, 5), GOLD, 5.0)
				_ice_shard(Vector2(128 + side * 44, 208), Vector2(128 + side * 62, 176), 14)
			draw_circle(oc, 76, INK)
			_disc(oc, 72, Color(0.75, 0.93, 1.0), Color(0.25, 0.55, 0.85))
			var water := Geometry2D.intersect_polygons(_ell(oc, 68, 68, 48), _rect(Vector2(40, oc.y + 4), Vector2(220, 200)))
			if water.size() > 0:
				_poly(water[0], Color(0.12, 0.55, 0.72), Color(0.03, 0.14, 0.32), 0.0)
			for k in 3:
				var rp := _ell(oc + Vector2(0, 26), 54.0 - k * 16.0, 13.0 - k * 4.0, 32)
				rp.append(rp[0])
				draw_polyline(rp, Color(0.8, 0.97, 1.0, 0.75 - k * 0.15), 3, true)
			draw_line(oc + Vector2(-66, 4), oc + Vector2(66, 4), Color(0.9, 1.0, 1.0, 0.8), 3)
			_glow(oc + Vector2(0, 26), 30, Color(0.85, 1.0, 1.0, 0.5))
			_sheen(oc, 56, PI * 1.08, PI * 1.45, 9)
			_star4(oc + Vector2(34, -36), 14, Color.WHITE)
			for side in [-1.0, 1.0]:
				_ball(Vector2(128 + side * 72, 100), 9, GOLD, 4.0)
		_:
			_star4(C, 60, Color.WHITE)


func _skull(c: Vector2, s: float, eye: Color) -> void:
	_shape(PackedVector2Array([c + Vector2(-28, 20) * s, c + Vector2(28, 20) * s, c + Vector2(26, 66) * s, c + Vector2(-26, 66) * s]), BONE, 6.0)
	_ball(c, 58.0 * s, BONE)
	draw_rect(Rect2(c + Vector2(-26, 22) * s, Vector2(52, 20) * s), BONE.darkened(0.1))
	for e in [Vector2(-22, 4), Vector2(22, 4)]:
		draw_colored_polygon(_ell(c + e * s, 17.0 * s, 15.0 * s, 16), Color(0.08, 0.02, 0.06))
		_glow(c + e * s, 14.0 * s, Color(eye, 0.9))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, 20) * s, c + Vector2(8, 34) * s, c + Vector2(-8, 34) * s]), Color(0.1, 0.04, 0.05))
	for k in 4:
		draw_line(c + Vector2(-18.0 + k * 12.0, 48) * s, c + Vector2(-18.0 + k * 12.0, 64) * s, Color(0.2, 0.15, 0.12), 3)


func _potion_round(liquid: Color, glow: Color) -> void:
	var c := Vector2(128, 154)
	_glow(c, 104, Color(glow, 0.5))
	_shape(_rect(Vector2(110, 60), Vector2(146, 104)), Color(0.55, 0.6, 0.7), 6.0)
	draw_circle(c, 67, INK)
	_disc(c, 64, Color(0.45, 0.5, 0.6), Color(0.2, 0.22, 0.28))
	var circle := _ell(c, 58, 58, 40)
	var cut := Geometry2D.intersect_polygons(circle, _rect(Vector2(40, 136), Vector2(220, 230)))
	if cut.size() > 0:
		_poly(cut[0], liquid.lightened(0.3), liquid.darkened(0.4), 0.0)
	draw_line(Vector2(76, 136), Vector2(180, 136), liquid.lightened(0.5), 4)
	for b in [Vector2(110, 176), Vector2(146, 160), Vector2(132, 196)]:
		draw_circle(b, 5, Color(1, 1, 0.9, 0.7))
	_sheen(c, 48, PI * 1.05, PI * 1.45, 8)
	_shape(_rect(Vector2(104, 42), Vector2(152, 66)), WOOD, 5.0)


# ---------------------------------------------------------------- orders
func _order() -> void:
	match id:
		&"move":
			var ring := _ell(Vector2(160, 204), 62, 22)
			ring.append(ring[0])
			draw_polyline(ring, INK, 14, true)
			draw_polyline(ring, GOLD, 7, true)
			_arrow(Vector2(56, 48), Vector2(158, 194), 30, 76, 62, Color(0.55, 0.95, 0.5))
		&"stop":
			var oct := _ell(C, 96, 96, 8, PI / 8.0, PI / 8.0 + TAU)
			_shape(oct, WARN)
			var inner := _ell(C, 82, 82, 8, PI / 8.0, PI / 8.0 + TAU)
			inner.append(inner[0])
			draw_polyline(inner, Color(1, 0.9, 0.85, 0.8), 4, true)
			_shape(_rect(Vector2(76, 110), Vector2(180, 146)), Color(0.98, 0.96, 0.92), 5.0)
		&"hold":
			_shape(_kite(Vector2(128, 124), 150, 196), STEEL)
			_shape(_rect(Vector2(116, 40), Vector2(140, 206)), GOLD, 4.0)
			_shape(_rect(Vector2(58, 92), Vector2(198, 116)), GOLD, 4.0)
		&"attack":
			_sword(Vector2(88, 180), PI * 0.25, 168, 32, STEEL.lightened(0.3), STEEL.darkened(0.3), BRONZE)
		&"attack_move":
			_sword(Vector2(76, 170), PI * 0.25, 150, 30, STEEL.lightened(0.3), STEEL.darkened(0.3), BRONZE)
			_arrow(Vector2(112, 206), Vector2(236, 206), 20, 52, 40, GOLD)
		&"gather":
			_pickaxe(Vector2(116, 118), -PI * 0.2, STEEL)
			_crystal(Vector2(190, 196), 0.95, CRYSTAL)
		&"build":
			_xf(Vector2(128, 132), PI * 0.22)
			_shape(_rect(Vector2(-10, -40), Vector2(10, 110)), WOOD)
			_shape(_rect(Vector2(-58, -84), Vector2(58, -36)), STEEL)
			_shape(_rect(Vector2(-66, -90), Vector2(-50, -30)), STEEL.darkened(0.15), 5.0)
			draw_line(Vector2(-50, -76), Vector2(50, -76), Color(1, 1, 1, 0.45), 5)
			_rs()
		&"rally":
			var ring := _ell(Vector2(96, 214), 54, 18)
			ring.append(ring[0])
			draw_polyline(ring, INK, 12, true)
			draw_polyline(ring, GOLD, 6, true)
			_shape(_rect(Vector2(88, 28), Vector2(102, 216)), WOOD)
			_poly(PackedVector2Array([Vector2(102, 36), Vector2(150, 50), Vector2(210, 38), Vector2(190, 76), Vector2(214, 116),
				Vector2(154, 110), Vector2(102, 120)]), GOLD.lightened(0.2), GOLD.darkened(0.35))
		&"cancel":
			for a in [PI * 0.25, -PI * 0.25]:
				_xf(C, a)
				_shape(_rect(Vector2(-20, -92), Vector2(20, 92)), WARN)
				_rs()
			_xf(C, PI * 0.25)
			_poly(_rect(Vector2(-16, -88), Vector2(16, 88)), WARN.lightened(0.3), WARN.darkened(0.3), 0.0)
			_rs()
		&"back":
			_stroke(PackedVector2Array([Vector2(160, 44), Vector2(80, 128), Vector2(160, 212)]), 34, GOLD, 10.0)
		_:
			_star4(C, 60, GOLD)


func _arrow(from: Vector2, to: Vector2, shaft: float, head_w: float, head_len: float, col: Color) -> void:
	var d: Vector2 = (to - from).normalized()
	var n := Vector2(-d.y, d.x)
	var b: Vector2 = to - d * head_len
	_shape(PackedVector2Array([from + n * shaft * 0.5, b + n * shaft * 0.5, b + n * head_w * 0.5, to, b - n * head_w * 0.5,
		b - n * shaft * 0.5, from - n * shaft * 0.5]), col)


# ---------------------------------------------------------------- units (emblems until models exist)
func _unit() -> void:
	_portrait_bg()
	var team: Color = _team()
	match id:
		&"flame_guard":
			_shape(_kite(Vector2(128, 130), 150, 196), team)
			var rim := _kite(Vector2(128, 130), 150, 196)
			rim.append(rim[0])
			draw_polyline(rim, BRONZE.lightened(0.2), 8, true)
			_fire(Vector2(128, 186), 70, 120)
		&"ember_archer":
			draw_arc(Vector2(150, 128), 96, PI * 0.62, PI * 1.38, 32, INK, 22, true)
			draw_arc(Vector2(150, 128), 96, PI * 0.62, PI * 1.38, 32, WOOD.lightened(0.15), 13, true)
			var top := Vector2(150, 128) + Vector2(cos(PI * 0.62), sin(PI * 0.62)) * 96.0
			var bot := Vector2(150, 128) + Vector2(cos(PI * 1.38), sin(PI * 1.38)) * 96.0
			draw_line(top, bot, Color(0.95, 0.9, 0.8), 3)
			_arrow(Vector2(40, 212), Vector2(206, 46), 10, 30, 34, STEEL)
			_xf(Vector2(206, 46), PI * 0.25)
			_fire(Vector2(0, 30), 36, 70)
			_rs()
		&"ash_hurler":
			_xf(Vector2(140, 148), -PI * 0.25)
			_fire(Vector2(0, 40), 110, 180)
			_rs()
			var rock := PackedVector2Array()
			var rng := RandomNumberGenerator.new()
			rng.seed = 2
			for i in 11:
				var a: float = TAU * float(i) / 11.0
				rock.append(Vector2(140, 148) + Vector2(cos(a), sin(a)) * rng.randf_range(46, 58))
			_shape(rock, Color(0.3, 0.27, 0.26))
			for seg in [[Vector2(116, 130), Vector2(136, 148), Vector2(130, 172)], [Vector2(150, 126), Vector2(166, 150)]]:
				draw_polyline(PackedVector2Array(seg), Color(1.0, 0.6, 0.2), 5, true)
		&"blaze_rider":
			_fire(Vector2(128, 206), 150, 190)
			draw_arc(Vector2(128, 134), 62, PI * 0.5 + 0.7, PI * 2.5 - 0.7, 36, INK, 42, true)
			draw_arc(Vector2(128, 134), 62, PI * 0.5 + 0.7, PI * 2.5 - 0.7, 36, STEEL, 30, true)
			for k in 6:
				var a: float = PI * 0.5 + 1.0 + k * (PI * 2.0 - 2.0) / 5.0
				draw_circle(Vector2(128, 134) + Vector2(cos(a), sin(a)) * 62.0, 4, INK)
		&"cinder_hand", &"gloom_thrall":
			_pickaxe(Vector2(112, 124), -PI * 0.2, STEEL)
			_crystal(Vector2(186, 192), 0.95, CRYSTAL)
		&"grave_hound":
			_glow(Vector2(128, 140), 100, Color(SHADOW_GLOW, 0.4))
			_shape(PackedVector2Array([Vector2(82, 190), Vector2(94, 146), Vector2(128, 130), Vector2(162, 146), Vector2(174, 190), Vector2(128, 206)]), team.lightened(0.2))
			for t in [[Vector2(70, 118), -0.5], [Vector2(104, 82), -0.15], [Vector2(152, 82), 0.15], [Vector2(186, 118), 0.5]]:
				_xf(t[0], t[1])
				_shape(_ell(Vector2.ZERO, 17, 24), team.lightened(0.2))
				_shape(PackedVector2Array([Vector2(-7, -20), Vector2(0, -44), Vector2(7, -20)]), BONE, 4.0)
				_rs()
		&"nightbolt":
			_glow(C, 110, Color(SHADOW_GLOW, 0.7))
			_poly(PackedVector2Array([Vector2(150, 20), Vector2(80, 136), Vector2(124, 136), Vector2(98, 236), Vector2(182, 104),
				Vector2(136, 104), Vector2(170, 20)]), Color(0.97, 0.9, 1.0), Color(0.55, 0.25, 0.9))
		&"shade":
			_glow(C, 104, Color(SHADOW_GLOW, 0.45))
			_hood(Vector2(128, 132), Color(0.5, 0.36, 0.7, 0.95), Color(0.15, 0.08, 0.25, 0.4))
		&"shadow_knight":
			_poly(_tube(_bez(Vector2(128, 60), Vector2(150, 18), Vector2(206, 30), 12), 30, 6), SHADOW_GLOW.lightened(0.2), SHADOW_TEAM)
			var helm := PackedVector2Array([Vector2(74, 90), Vector2(96, 56), Vector2(128, 46), Vector2(160, 56), Vector2(182, 90),
				Vector2(186, 186), Vector2(160, 212), Vector2(96, 212), Vector2(70, 186)])
			_shape(helm, SILVER.lightened(0.1))
			_shape(_rect(Vector2(78, 118), Vector2(178, 138)), Color(0.05, 0.02, 0.08), 0.0)
			_glow(Vector2(128, 128), 40, Color(SHADOW_GLOW, 0.8))
			draw_line(Vector2(84, 128), Vector2(172, 128), Color(0.9, 0.75, 1.0), 4)
			draw_line(Vector2(128, 140), Vector2(128, 206), Color(0.2, 0.18, 0.25), 6)
			for x in [100.0, 156.0]:
				for y in [160.0, 180.0]:
					draw_circle(Vector2(x, y), 4, Color(0.1, 0.08, 0.14))
		&"ruin_warden":
			_shape(PackedVector2Array([Vector2(58, 70), Vector2(198, 62), Vector2(208, 200), Vector2(150, 222), Vector2(64, 214), Vector2(48, 140)]), STONE)
			_poly(PackedVector2Array([Vector2(56, 74), Vector2(92, 58), Vector2(140, 66), Vector2(198, 60), Vector2(200, 92), Vector2(160, 84),
				Vector2(120, 96), Vector2(84, 86), Vector2(56, 98)]), Color(0.5, 0.8, 0.35), Color(0.25, 0.5, 0.2), 0.0)
			for e in [Vector2(98, 134), Vector2(160, 130)]:
				_glow(e, 26, Color(NEUTRAL_GLOW, 0.9))
				draw_colored_polygon(_ell(e, 14, 8, 12), Color(0.85, 1.0, 0.7))
			draw_polyline(PackedVector2Array([Vector2(126, 100), Vector2(118, 150), Vector2(134, 180), Vector2(124, 214)]), Color(0.15, 0.14, 0.15), 5, true)
			_shape(_rect(Vector2(90, 176), Vector2(170, 192)), Color(0.2, 0.2, 0.22), 0.0)
		_:
			_star4(C, 60, _faction_glow())


# ---------------------------------------------------------------- buildings (fallback when no model renders)
func _building() -> void:
	_portrait_bg()
	var team: Color = _team()
	var stone := Color(0.30, 0.26, 0.24)
	match faction:
		&"shadow": stone = Color(0.20, 0.17, 0.26)
		&"ice": stone = Color(0.30, 0.38, 0.48)
		&"nature": stone = Color(0.30, 0.27, 0.18)
	_shape(_rect(Vector2(70, 100), Vector2(186, 220)), stone.lightened(0.3))
	_shape(PackedVector2Array([Vector2(52, 104), Vector2(128, 36), Vector2(204, 104)]), team)
	_glow(Vector2(128, 170), 30, Color(_faction_glow(), 0.8))
	_shape(_rect(Vector2(112, 160), Vector2(144, 220)), Color(0.1, 0.07, 0.06), 4.0)
