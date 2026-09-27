extends "res://art/icons/icon_painter.gd"
## Trade icons (task 10.V12, market-trade.md 9, ui-trade.md 15), painted at 256 px in the same look as icon_painter.gd
## (top-lit gradients, dark ink outline, soft glow; its helpers and palette are reused) and downsampled to 128 by
## res://art/icons/render_trade_icons.gd. Set kind / id / faction before adding it to a SubViewport.
## Kinds and ids:
##   orders     trade, route, wares                    (caravan / Bazaar command card, 56 px)
##   wares      iron_axles, masons_charter, tempered_steel, gambesons   (trade window rows, 40 px)
##   contracts  outriders, sweep                       (Lodge tab, 68 px)
##   posts      heron_ford, millstone_cross, lantern_wharf, saltgate    (route buttons 56, post panel 88): the gilded
##              emblem on the dark teal hanging board of the trading-post model (heron, millstone, lantern, gate)
##   ui         gold_coin, exchange_crystals, exchange_essence, crest_bazaar, crest_lodge   (16 / 12 / 10 px glyphs)
##   bg         portrait backgrounds: faction &"trade" (warm gold), &"magpie" (blue-green), &"tracker" (amber on
##              grey-green); any other faction = the kingdom backgrounds of icon_painter.gd
## Anything else falls back to icon_painter.gd.

const T_COIN := Color(1.0, 0.78, 0.25)          # ui-trade.md 16.1 GOLD_COIN
const T_COIN_RING := Color(0.55, 0.42, 0.10)     # 16.2 outer ring
const T_COIN_INNER := Color(0.85, 0.62, 0.18)    # 16.2 inner ring
const T_COIN_HI := Color(1.0, 0.93, 0.65)        # 16.2 highlight arc
const T_FIELD := Color(0.13, 0.24, 0.27)         # the trading-post sign board (trade_post_model.gd C_FIELD)
const T_SIGN_GOLD := Color(0.93, 0.71, 0.27)     # its gilding (C_GOLD)
const T_TIMBER := Color(0.31, 0.21, 0.13)
const T_IRON := Color(0.30, 0.30, 0.34)
const T_MAGPIE := Color(0.3, 1.0, 0.85)          # Magpie eye shine / iridescent trim
const T_AMBER := Color(1.0, 0.62, 0.22)          # tracker snare-bolt glow
const T_LODGE := Color(0.36, 0.46, 0.38)         # Greywater grey-green
const T_SAFFRON := Color(0.82, 0.52, 0.15)
const T_GO := Color(0.55, 0.95, 0.5)             # the move order's arrow green
const T_WAX := Color(0.80, 0.17, 0.12)
const T_PARCH := Color(0.93, 0.86, 0.68)
const T_QUILT := Color(0.80, 0.68, 0.48)


func _draw() -> void:
	match kind:
		&"orders":
			if not _trade_order():
				super()
		&"wares": _ware()
		&"contracts": _contract()
		&"posts": _post()
		&"ui": _ui()
		&"bg": _trade_bg()
		_: super()


# ---------------------------------------------------------------- helpers
func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _chamfer(a: Vector2, b: Vector2, k: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(a.x + k, a.y), Vector2(b.x - k, a.y), Vector2(b.x, a.y + k), Vector2(b.x, b.y - k),
		Vector2(b.x - k, b.y), Vector2(a.x + k, b.y), Vector2(a.x, b.y - k), Vector2(a.x, a.y + k)])


## Ellipse points rotated by `rot` around `c` (angles as in _ell).
func _ell_rot(c: Vector2, rx: float, ry: float, rot: float, n: int = 40, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var pts := _ell(Vector2.ZERO, rx, ry, n, a0, a1)
	for i in pts.size():
		pts[i] = c + pts[i].rotated(rot)
	return pts


## Gilded emblem shape for the post signs.
func _gild(pts: PackedVector2Array, ow: float = 5.0) -> void:
	_poly(pts, T_SIGN_GOLD.lightened(0.38), T_SIGN_GOLD.darkened(0.28), ow)


## A coin face-on (ui-trade.md 16.2): ink outline, the minted edge below, a top-lit face, the dark rim ring, the inner
## ring with a four-point star stamp, and the highlight arc from 200 to 290 degrees.
func _coin(c: Vector2, r: float, ow: float = 6.0, stamp: bool = true) -> void:
	var edge: Vector2 = c + Vector2(0, r * 0.13)
	if ow > 0.0:
		draw_circle(edge, r + ow * 0.5, INK)
		draw_circle(c, r + ow * 0.5, INK)
	draw_circle(edge, r, T_COIN_RING.darkened(0.15))
	_poly(_ell(c, r, r, 48), T_COIN.lightened(0.3), T_COIN.darkened(0.2), 0.0)
	draw_arc(c, r * 0.92, 0.0, TAU, 48, T_COIN_RING, maxf(1.5, r * 0.08), true)
	if stamp:
		draw_arc(c, r * 0.62, 0.0, TAU, 40, T_COIN_INNER, maxf(1.5, r * 0.06), true)
		_stamp_star(c, r * 0.44)
	draw_arc(c, r * 0.75, deg_to_rad(200.0), deg_to_rad(290.0), 16, T_COIN_HI, maxf(2.0, r * 0.1), true)


func _stamp_star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a: float = TAU * float(i) / 8.0 - PI * 0.5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.3))
	draw_colored_polygon(pts, T_COIN_INNER.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([c, pts[7], pts[0]]), Color(T_COIN_HI, 0.85))
	draw_colored_polygon(PackedVector2Array([c, pts[6], pts[7]]), Color(T_COIN_HI, 0.55))


## A coin lying flat (seen from above at an angle): face ellipse + milled edge band of height t.
func _coin_flat(c: Vector2, r: float, t: float, ow: float = 5.0) -> void:
	var sq: float = 0.42
	if ow > 0.0:
		draw_colored_polygon(_ell(c + Vector2(0, t), r + ow * 0.5, r * sq + ow * 0.5, 36), INK)
		draw_colored_polygon(_rect(c + Vector2(-r - ow * 0.5, 0), c + Vector2(r + ow * 0.5, t)), INK)
		draw_colored_polygon(_ell(c, r + ow * 0.5, r * sq + ow * 0.5, 36), INK)
	draw_colored_polygon(_ell(c + Vector2(0, t), r, r * sq, 36), T_COIN_RING)
	draw_colored_polygon(_rect(c + Vector2(-r, 0), c + Vector2(r, t)), T_COIN_RING.lightened(0.12))
	for k in 9:
		var x: float = -r * 0.85 + r * 1.7 * float(k) / 8.0
		var y0: float = c.y + r * sq * sqrt(maxf(0.0, 1.0 - (x / r) * (x / r)))
		draw_line(Vector2(c.x + x, y0), Vector2(c.x + x, y0 + t), T_COIN_RING.darkened(0.35), 2.0)
	_poly(_ell(c, r, r * sq, 36), T_COIN.lightened(0.32), T_COIN.darkened(0.12), 0.0)
	draw_polyline(_closed(_ell(c, r * 0.72, r * sq * 0.72, 32)), T_COIN_INNER, maxf(2.0, r * 0.07), true)
	draw_arc(c + Vector2(-r * 0.2, -r * sq * 0.25), r * 0.3, deg_to_rad(200.0), deg_to_rad(280.0), 8, Color(T_COIN_HI, 0.9), 2.5, true)


## Thick arrow along `path` (any curve), the head at its last point.
func _path_arrow(path: PackedVector2Array, w: float, head_w: float, head_len: float, col: Color, ow: float = 6.0) -> void:
	var end: Vector2 = path[path.size() - 1]
	var d: Vector2 = (end - path[path.size() - 2]).normalized()
	var n := Vector2(-d.y, d.x)
	var b: Vector2 = end - d * head_len
	var shaft := PackedVector2Array()
	for p in path:
		if p.distance_to(end) > head_len * 1.05:
			shaft.append(p)
	shaft.append(b + d * 2.0)
	var head := PackedVector2Array([b + n * head_w * 0.5, end, b - n * head_w * 0.5])
	var head_ink := PackedVector2Array([b - d * ow + n * (head_w * 0.5 + ow * 1.5), end + d * ow * 2.0,
		b - d * ow - n * (head_w * 0.5 + ow * 1.5)])
	draw_polyline(shaft, INK, w + ow * 2.0, true)
	draw_circle(shaft[0], (w + ow * 2.0) * 0.5, INK)
	draw_colored_polygon(head_ink, INK)
	draw_polyline(shaft, col.darkened(0.18), w, true)
	draw_circle(shaft[0], w * 0.5, col.darkened(0.18))
	var lit := PackedVector2Array()
	for i in shaft.size():
		var dd: Vector2 = (shaft[mini(i + 1, shaft.size() - 1)] - shaft[maxi(i - 1, 0)]).normalized()
		var nn := Vector2(-dd.y, dd.x)
		if nn.dot(Vector2(-0.5, -1.0)) < 0.0:
			nn = -nn
		lit.append(shaft[i] + nn * w * 0.18)
	draw_polyline(lit, col.lightened(0.35), w * 0.36, true)
	_poly(head, col.lightened(0.3), col.darkened(0.25), 0.0)


## Spoked cart wheel: tyre `tire`, wooden felloe and spokes, bronze hub, rivets on the tyre.
func _wheel(c: Vector2, r: float, spokes: int, tire: Color, rot: float = 0.0, ow: float = 6.0) -> void:
	var tw: float = r * 0.17
	var fw: float = r * 0.13
	var rin: float = r - tw - fw
	var sw: float = r * 0.11
	for i in spokes:
		var a: float = rot + TAU * float(i) / float(spokes)
		draw_line(c, c + Vector2(cos(a), sin(a)) * (rin + 2.0), INK, sw + ow)
	draw_arc(c, r - (tw + fw) * 0.5, 0.0, TAU, 64, INK, tw + fw + ow, true)
	for i in spokes:
		var a: float = rot + TAU * float(i) / float(spokes)
		var dir := Vector2(cos(a), sin(a))
		var shade: float = 0.5 + 0.5 * dir.dot(Vector2(-0.6, -0.8))
		draw_line(c + dir * r * 0.16, c + dir * (rin + 2.0), WOOD.darkened(0.25).lerp(WOOD.lightened(0.25), shade), sw)
	draw_arc(c, rin + fw * 0.5, 0.0, TAU, 64, WOOD.darkened(0.05), fw, true)
	draw_arc(c, rin + fw * 0.5, deg_to_rad(190.0), deg_to_rad(300.0), 24, WOOD.lightened(0.3), fw * 0.35, true)
	draw_arc(c, rin + ow * 0.25, 0.0, TAU, 64, Color(0, 0, 0, 0.35), 2.0, true)
	draw_arc(c, r - tw * 0.5, 0.0, TAU, 64, tire, tw, true)
	draw_arc(c, r - tw * 0.5, deg_to_rad(185.0), deg_to_rad(305.0), 24, tire.lightened(0.38), tw * 0.38, true)
	draw_arc(c, r - tw * 0.5, deg_to_rad(15.0), deg_to_rad(125.0), 24, tire.darkened(0.4), tw * 0.34, true)
	for i in 12:
		var a: float = rot + TAU * (float(i) + 0.5) / 12.0
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * (r - tw * 0.5)
		draw_circle(p, tw * 0.2 + 1.0, INK)
		draw_circle(p, tw * 0.2, tire.lightened(0.5))
	_ball(c, r * 0.19, BRONZE, 5.0)
	draw_circle(c, r * 0.06, INK)


## A twisted rope along `pts`.
func _rope(pts: PackedVector2Array, w: float, col: Color, ow: float = 5.0) -> void:
	draw_polyline(pts, INK, w + ow * 2.0, true)
	draw_polyline(pts, col.darkened(0.12), w, true)
	var lit := PackedVector2Array()
	for p in pts:
		lit.append(p + Vector2(-0.4, -0.9) * w * 0.18)
	draw_polyline(lit, col.lightened(0.3), w * 0.3, true)
	var step: float = w * 0.9
	var acc: float = step * 0.5
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var seg: float = a.distance_to(b)
		if seg <= 0.001:
			continue
		var d: Vector2 = (b - a) / seg
		var n := Vector2(-d.y, d.x)
		while acc < seg:
			var p: Vector2 = a + d * acc
			draw_line(p - n * w * 0.45 - d * w * 0.22, p + n * w * 0.45 + d * w * 0.22, col.darkened(0.5), maxf(1.5, w * 0.16))
			acc += step
		acc -= seg


## A crossbow snare bolt from `tail` to `tip`: grey-green fletching, wooden shaft, glowing amber head.
func _bolt(tail: Vector2, tip: Vector2, w: float) -> void:
	var l: float = tail.distance_to(tip)
	var d: Vector2 = (tip - tail) / l
	var n := Vector2(-d.y, d.x)
	_glow(tip - d * l * 0.08, w * 3.4, Color(T_AMBER, 0.6))
	_stroke(PackedVector2Array([tail + d * l * 0.04, tip - d * l * 0.15]), w, WOOD.lightened(0.2), 5.0)
	for s in [-1.0, 1.0]:
		_shape(PackedVector2Array([tail + d * l * 0.30 + n * s * w * 0.4, tail + d * l * 0.10 + n * s * w * 1.9,
			tail + n * s * w * 1.6, tail + d * l * 0.05 + n * s * w * 0.4]), T_LODGE.lightened(0.25), 4.0)
	_poly(PackedVector2Array([tip, tip - d * l * 0.13 + n * w * 1.15, tip - d * l * 0.2, tip - d * l * 0.13 - n * w * 1.15]),
		T_AMBER.lightened(0.55), T_AMBER.darkened(0.15), 5.0)


## Heater shield outline, centre `c`.
func _heater(c: Vector2, w: float, h: float) -> PackedVector2Array:
	var hw: float = w * 0.5
	var top: float = c.y - h * 0.5
	var pts := PackedVector2Array([Vector2(c.x - hw, top), Vector2(c.x + hw, top)])
	pts.append_array(_bez(Vector2(c.x + hw, top + h * 0.36), Vector2(c.x + hw, top + h * 0.8), Vector2(c.x, top + h), 12))
	var left := _bez(Vector2(c.x, top + h), Vector2(c.x - hw, top + h * 0.8), Vector2(c.x - hw, top + h * 0.36), 12)
	pts.append_array(left.slice(1))
	return pts


## Balance scale: beam pivot `c`, size `s`, metal colour. Returns the two pan centres [left, right].
func _balance(c: Vector2, s: float, metal: Color, tilt: float = 0.0) -> Array:
	_shape(PackedVector2Array([c + Vector2(-44, 132) * s, c + Vector2(44, 132) * s, c + Vector2(28, 112) * s,
		c + Vector2(-28, 112) * s]), metal, 5.0)
	_shape(_rect(c + Vector2(-7, -2) * s, c + Vector2(7, 114) * s), metal, 5.0)
	var lft: Vector2 = c + Vector2(-88, 0).rotated(tilt) * s
	var rgt: Vector2 = c + Vector2(88, 0).rotated(tilt) * s
	var pans: Array = []
	for e: Vector2 in [lft, rgt]:
		var pc: Vector2 = e + Vector2(0, 66) * s
		for k in [-1.0, 1.0]:
			draw_line(e, pc + Vector2(k * 30, 0) * s, INK, 6.0 * s + 2.0)
			draw_line(e, pc + Vector2(k * 30, 0) * s, metal.lightened(0.25), 2.5 * s + 0.5)
		pans.append(pc)
	_stroke(PackedVector2Array([lft, rgt]), 11.0 * s, metal.lightened(0.1), 5.0)
	draw_line(lft + Vector2(4, -2) * s, rgt + Vector2(-4, -2) * s, Color(1, 1, 1, 0.4), 3.0 * s)
	for e: Vector2 in [lft, rgt]:
		_ball(e, 8.0 * s, metal, 4.0)
	_ball(c + Vector2(0, -16) * s, 12.0 * s, metal, 5.0)
	return pans


func _pan(pc: Vector2, s: float, metal: Color) -> void:
	_poly(_ell(pc, 36 * s, 16 * s, 24, 0.0, PI), metal.lightened(0.2), metal.darkened(0.35), 5.0)
	draw_line(pc + Vector2(-34, 0) * s, pc + Vector2(34, 0) * s, metal.lightened(0.45), 3.0 * s)


## A hunting horn from the mouthpiece to the bell, bone with bronze bands.
func _horn(mouth: Vector2, bend: Vector2, bell: Vector2, w0: float, w1: float) -> void:
	var cpts := _bez(mouth, bend, bell, 18)
	_poly(_tube(cpts, w0, w1), BONE.lightened(0.12), BONE.darkened(0.38), 6.0)
	for t in [0.3, 0.62]:
		var i: int = int(t * 18.0)
		var d: Vector2 = (cpts[i + 1] - cpts[i - 1]).normalized()
		var nn := Vector2(-d.y, d.x)
		var hw: float = lerpf(w0, w1, t) * 0.5 + 2.0
		_stroke(PackedVector2Array([cpts[i] - nn * hw, cpts[i] + nn * hw]), 7.0, BRONZE.lightened(0.15), 4.0)
	var de: Vector2 = (cpts[18] - cpts[17]).normalized()
	var ne := Vector2(-de.y, de.x)
	var rot: float = ne.angle() - PI * 0.5  # the opening's long axis along the bell's width
	_poly(_ell_rot(cpts[18], w1 * 0.2, w1 * 0.56, rot, 24), BRONZE.lightened(0.3), BRONZE.darkened(0.3), 5.0)
	draw_colored_polygon(_ell_rot(cpts[18], w1 * 0.11, w1 * 0.42, rot, 20), Color(0.12, 0.08, 0.05))
	_ball(mouth, w0 * 0.55, BRONZE, 4.0)


# ---------------------------------------------------------------- backgrounds
func _trade_bg() -> void:
	match faction:
		&"trade": _bg_col(Color(0.15, 0.11, 0.08), Color(1.0, 0.72, 0.28), 0.36)
		&"magpie": _bg_col(Color(0.08, 0.10, 0.13), Color(0.25, 0.85, 0.78), 0.30)
		&"tracker": _bg_col(Color(0.10, 0.12, 0.10), Color(0.95, 0.62, 0.25), 0.30)
		_: _portrait_bg()


func _bg_col(inner: Color, glow: Color, alpha: float) -> void:
	draw_rect(Rect2(0, 0, 256, 256), inner)
	_disc(C, 182, Color(glow, alpha), Color(glow, 0.0), 48)


# ---------------------------------------------------------------- orders
func _trade_order() -> bool:
	match id:
		&"trade":
			# The trade loop: a gold coin inside two arrows chasing each other (out to the post, back home).
			_glow(C, 96, Color(T_COIN, 0.3))
			_coin(C + Vector2(0, -6), 58)
			_path_arrow(_ell(C, 98, 98, 22, deg_to_rad(196.0), deg_to_rad(334.0)), 18, 52, 40, T_GO)
			_path_arrow(_ell(C, 98, 98, 22, deg_to_rad(16.0), deg_to_rad(154.0)), 18, 52, 40, T_GO)
		&"route":
			# A dotted road to a gold ring, and a fingerpost whose boards are the posts' teal and gold.
			var ring := _ell(Vector2(188, 214), 52, 18)
			draw_polyline(_closed(ring), INK, 13, true)
			draw_polyline(_closed(ring), T_COIN, 6, true)
			var road := _bez(Vector2(26, 236), Vector2(96, 150), Vector2(176, 206), 24)
			for i in range(0, road.size() - 2, 3):
				var a: Vector2 = road[i]
				var b: Vector2 = road[i + 1].lerp(road[i + 2], 0.4)
				draw_line(a, b, INK, 17)
			for i in range(0, road.size() - 2, 3):
				var a: Vector2 = road[i]
				var b: Vector2 = road[i + 1].lerp(road[i + 2], 0.4)
				draw_line(a, b, T_COIN.lightened(0.1), 8)
			_shape(_rect(Vector2(82, 24), Vector2(98, 238)), WOOD)
			_shape(PackedVector2Array([Vector2(78, 26), Vector2(90, 10), Vector2(102, 26)]), WOOD.darkened(0.1), 4.0)
			var b1 := PackedVector2Array([Vector2(98, 40), Vector2(194, 40), Vector2(226, 68), Vector2(194, 96), Vector2(98, 96)])
			_poly(b1, T_FIELD.lightened(0.3), T_FIELD.darkened(0.2))
			draw_polyline(_closed(PackedVector2Array([Vector2(106, 48), Vector2(190, 48), Vector2(212, 68), Vector2(190, 88),
				Vector2(106, 88)])), T_SIGN_GOLD, 4, true)
			var b2 := PackedVector2Array([Vector2(82, 110), Vector2(40, 110), Vector2(14, 134), Vector2(40, 158), Vector2(82, 158)])
			_poly(b2, T_FIELD.lightened(0.3), T_FIELD.darkened(0.2))
			draw_polyline(_closed(PackedVector2Array([Vector2(76, 117), Vector2(43, 117), Vector2(25, 134), Vector2(43, 151),
				Vector2(76, 151)])), T_SIGN_GOLD, 4, true)
		&"wares":
			# The Bazaar's goods: an open crate (a wine flask, a bolt of saffron cloth) with a coin price tag.
			_shape(PackedVector2Array([Vector2(56, 108), Vector2(200, 108), Vector2(214, 62), Vector2(76, 52)]), WOOD.darkened(0.2))
			draw_line(Vector2(84, 64), Vector2(206, 72), Color(0, 0, 0, 0.3), 3)
			_shape(_rect(Vector2(76, 50), Vector2(104, 76)), Color(0.62, 0.48, 0.30), 4.0)
			_poly(PackedVector2Array([Vector2(66, 128), Vector2(66, 96), Vector2(80, 76), Vector2(100, 76), Vector2(114, 96),
				Vector2(114, 128)]), Color(0.45, 0.75, 0.50), Color(0.10, 0.32, 0.20))
			draw_line(Vector2(74, 98), Vector2(74, 122), Color(1, 1, 1, 0.5), 5)
			_xf(Vector2(152, 94), -0.32)
			_shape(_rect(Vector2(-48, -20), Vector2(40, 20)), T_SAFFRON)
			draw_line(Vector2(-44, -4), Vector2(36, -4), Color(0.6, 0.12, 0.08), 6)
			_poly(_ell(Vector2(40, 0), 10, 20, 20), T_SAFFRON.lightened(0.35), T_SAFFRON.darkened(0.1), 4.0)
			draw_arc(Vector2(40, 0), 5, 0.0, TAU, 12, T_SAFFRON.darkened(0.4), 2.0, true)
			_rs()
			_shape(_rect(Vector2(40, 112), Vector2(216, 228)), WOOD)
			for y in [150.0, 190.0]:
				draw_line(Vector2(44, y), Vector2(212, y), Color(0.12, 0.07, 0.04, 0.8), 4)
				draw_line(Vector2(44, y + 3), Vector2(212, y + 3), Color(1, 0.9, 0.7, 0.25), 2)
			_shape(_rect(Vector2(34, 106), Vector2(222, 122)), WOOD.darkened(0.15), 5.0)
			for cx in [40.0, 216.0]:
				_shape(_rect(Vector2(cx - 8, 122), Vector2(cx + 8, 228)), T_IRON, 4.0)
				draw_circle(Vector2(cx, 140), 3.0, Color(0.8, 0.8, 0.8))
				draw_circle(Vector2(cx, 210), 3.0, Color(0.8, 0.8, 0.8))
			draw_line(Vector2(204, 116), Vector2(214, 150), INK, 6)
			draw_line(Vector2(204, 116), Vector2(214, 150), Color(0.85, 0.8, 0.65), 3)
			_coin(Vector2(212, 178), 30, 5.0, false)
		_:
			return false
	return true


# ---------------------------------------------------------------- wares (market-trade.md 3.2)
func _ware() -> void:
	match id:
		&"iron_axles":
			# Iron-shod Axles (caravans faster): an iron-tyred cart wheel with speed streaks.
			for s in [[Vector2(12, 84), 46.0], [Vector2(4, 130), 50.0], [Vector2(14, 176), 42.0]]:
				var p: Vector2 = s[0]
				_stroke(PackedVector2Array([p, p + Vector2(float(s[1]), 0)]), 10, Color(0.92, 0.9, 0.84), 5.0)
			_wheel(Vector2(150, 130), 96, 8, T_IRON, 0.2)
		&"masons_charter":
			# Masons' Charter (+15 % building HP): a sealed charter over a block of dressed stone.
			var stone := Color(0.64, 0.61, 0.56)
			var rows: Array = [[120.0, 168.0, [18.0, 56.0, 128.0, 200.0, 238.0]], [172.0, 226.0, [18.0, 92.0, 166.0, 238.0]]]
			var k: int = 0
			for row: Array in rows:
				var xs: Array = row[2]
				for i in xs.size() - 1:
					k += 1
					var col: Color = stone.darkened(0.08 * float(k % 3))
					_shape(_rect(Vector2(float(xs[i]) + 2.0, float(row[0])), Vector2(float(xs[i + 1]) - 2.0, float(row[1]))), col, 5.0)
					draw_line(Vector2(float(xs[i]) + 6.0, float(row[0]) + 4.0), Vector2(float(xs[i + 1]) - 6.0, float(row[0]) + 4.0),
						Color(1, 1, 1, 0.35), 3)
			_xf(Vector2(112, 76), -0.12)
			_shape(_rect(Vector2(-70, -46), Vector2(70, 44)), T_PARCH)
			for ly in [-24.0, -10.0, 4.0, 18.0]:
				draw_line(Vector2(-52, ly), Vector2(40 if ly < 10.0 else 10.0, ly), Color(0.25, 0.18, 0.12, 0.55), 4)
			_shape(_rect(Vector2(-78, -58), Vector2(78, -40)), T_PARCH.darkened(0.12), 5.0)
			_shape(_rect(Vector2(-78, 38), Vector2(78, 54)), T_PARCH.darkened(0.12), 5.0)
			_rs()
			for t in [[Vector2(162, 132), Vector2(146, 190)], [Vector2(178, 132), Vector2(196, 186)]]:
				var a: Vector2 = t[0]
				var b: Vector2 = t[1]
				_shape(PackedVector2Array([a + Vector2(-9, 0), a + Vector2(9, 0), b + Vector2(9, 0), b + Vector2(0, -10), b + Vector2(-9, 0)]),
					T_WAX.darkened(0.1), 4.0)
			draw_circle(Vector2(170, 118), 38, INK)
			_poly(_ell(Vector2(170, 118), 35, 35, 36), T_WAX.lightened(0.25), T_WAX.darkened(0.3), 0.0)
			draw_arc(Vector2(170, 118), 24, 0.0, TAU, 32, T_WAX.darkened(0.35), 4, true)
			_stroke(PackedVector2Array([Vector2(158, 104), Vector2(158, 132), Vector2(184, 132)]), 7, T_COIN, 3.0)
			_sheen(Vector2(170, 118), 28, deg_to_rad(200.0), deg_to_rad(260.0), 4.0)
		&"tempered_steel":
			# Tempered Steel (+8 % soldier damage): a blade glowing from the forge, laid on an anvil, sparks.
			var anvil := PackedVector2Array([Vector2(18, 126), Vector2(70, 116), Vector2(222, 116), Vector2(222, 148),
				Vector2(186, 148), Vector2(170, 188), Vector2(206, 198), Vector2(214, 230), Vector2(74, 230), Vector2(82, 198),
				Vector2(118, 188), Vector2(102, 148), Vector2(70, 148)])
			_poly(anvil, Color(0.50, 0.52, 0.58), Color(0.14, 0.14, 0.18))
			draw_line(Vector2(74, 121), Vector2(218, 121), Color(1, 1, 1, 0.4), 4)
			_glow(Vector2(132, 96), 86, Color(1.0, 0.5, 0.12, 0.55))
			var tail := Vector2(28, 104)
			var tip := Vector2(238, 70)
			var d: Vector2 = (tip - tail).normalized()
			var n := Vector2(-d.y, d.x)
			var l: float = tail.distance_to(tip)
			var pts := PackedVector2Array([tail + n * 5.0, tail + d * l * 0.18 + n * 5.0, tail + d * l * 0.2 + n * 14.0,
				tail + d * l * 0.86 + n * 14.0, tip, tail + d * l * 0.86 - n * 12.0, tail + d * l * 0.2 - n * 12.0,
				tail + d * l * 0.18 - n * 5.0, tail - n * 5.0])
			var cols := PackedColorArray()
			for p in pts:
				var t: float = (p - tail).dot(d) / l
				var hot: float = clampf(1.0 - absf(t - 0.55) / 0.4, 0.0, 1.0)
				var steel: Color = STEEL.lerp(Color(0.45, 0.47, 0.52), 0.3 if (p - tail).dot(n) < 0.0 else 0.0)
				cols.append(steel.lerp(Color(1.0, 0.72, 0.28), hot).lerp(Color(1.0, 0.95, 0.7), hot * hot * 0.6))
			draw_polyline(_closed(pts), INK, 6, true)
			draw_polygon(pts, cols)
			draw_line(tail + d * l * 0.24 + n * 3.0, tail + d * l * 0.84 + n * 3.0, Color(1, 1, 0.9, 0.55), 3)
			_sparks(Vector2(150, 74), 62, 7, Color(1.0, 0.72, 0.25), 11)
		&"gambesons":
			# Quilted Gambesons (soldiers take 9 % less): a padded, diamond-quilted jacket with bronze toggles.
			var body := PackedVector2Array([Vector2(96, 32), Vector2(160, 32), Vector2(208, 52), Vector2(242, 142), Vector2(208, 156),
				Vector2(190, 110), Vector2(190, 228), Vector2(66, 228), Vector2(66, 110), Vector2(48, 156), Vector2(14, 142),
				Vector2(48, 52)])
			_poly(body, T_QUILT.lightened(0.22), T_QUILT.darkened(0.3))
			for off in range(-256, 512, 28):
				for line in [PackedVector2Array([Vector2(off, 0), Vector2(off + 256, 256)]),
						PackedVector2Array([Vector2(off, 256), Vector2(off + 256, 0)])]:
					for seg: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, body):
						draw_polyline(seg, T_QUILT.darkened(0.42), 3, true)
						var hl := seg.duplicate()
						for i in hl.size():
							hl[i] += Vector2(0, 2.5)
						draw_polyline(hl, Color(1, 0.95, 0.85, 0.35), 1.5, true)
			draw_colored_polygon(PackedVector2Array([Vector2(100, 34), Vector2(128, 76), Vector2(156, 34)]), Color(0.22, 0.14, 0.08))
			_stroke(PackedVector2Array([Vector2(96, 32), Vector2(128, 80), Vector2(160, 32)]), 10, T_QUILT.lightened(0.1), 5.0)
			_shape(_rect(Vector2(66, 208), Vector2(190, 228)), T_QUILT.darkened(0.12), 5.0)
			_stroke(PackedVector2Array([Vector2(14, 142), Vector2(48, 156)]), 10, T_QUILT.darkened(0.12), 5.0)
			_stroke(PackedVector2Array([Vector2(208, 156), Vector2(242, 142)]), 10, T_QUILT.darkened(0.12), 5.0)
			draw_line(Vector2(128, 80), Vector2(128, 208), Color(0.18, 0.11, 0.06), 5)
			for y in [102.0, 132.0, 162.0, 190.0]:
				_shape(_rect(Vector2(118, y - 5), Vector2(138, y + 5)), BRONZE.lightened(0.2), 3.0)
		_:
			_coin(C, 70)


# ---------------------------------------------------------------- contracts (market-trade.md 6)
func _contract() -> void:
	match id:
		&"outriders":
			# Outriders: two trackers ride with the caravans: crossed snare bolts over a cart wheel.
			_wheel(Vector2(128, 132), 86, 8, WOOD.darkened(0.3), 0.39)
			_bolt(Vector2(44, 222), Vector2(214, 42), 11)
			_bolt(Vector2(212, 222), Vector2(42, 42), 11)
		&"sweep":
			# Sweep: trackers comb the roads for thieves: a magpie tail feather caught in a snare noose.
			var q := Vector2(80, 214)
			var t := Vector2(190, 34)
			var d: Vector2 = (t - q).normalized()
			var nrm := Vector2(-d.y, d.x)
			var rot: float = d.angle() + PI * 0.5
			var noose_c := Vector2(132, 124) + d * 8.0
			var back := _ell_rot(noose_c, 58, 30, rot, 20, PI, TAU)
			_rope(back, 12, Color(0.82, 0.68, 0.46))
			var mid: Vector2 = q.lerp(t, 0.55) + nrm * 12.0
			var cpts := _bez(q + d * 26.0, mid, t, 16)
			var outer := _tube(cpts, 78, 0, true)
			_poly(outer, T_MAGPIE.lightened(0.2), Color(0.12, 0.40, 0.62), 6.0)
			var inner := _tube(_bez(q + d * 30.0, mid, t - d * 8.0, 16), 60, 0, true)
			_poly(inner, Color(0.20, 0.20, 0.26), Color(0.03, 0.03, 0.05), 0.0)
			var cut_c: Vector2 = q + d * 88.0
			var half := PackedVector2Array([cut_c + nrm * 90.0, cut_c - nrm * 90.0, cut_c - nrm * 90.0 - d * 120.0,
				cut_c + nrm * 90.0 - d * 120.0])
			for wpoly: PackedVector2Array in Geometry2D.intersect_polygons(inner, half):
				_poly(wpoly, Color(0.98, 0.97, 0.94), Color(0.72, 0.74, 0.78), 0.0)
			draw_polyline(cpts, BONE, 4, true)
			_stroke(PackedVector2Array([q, q + d * 30.0]), 7, BONE, 4.0)
			var front := _ell_rot(noose_c, 58, 30, rot, 20, 0.0, PI)
			_rope(front, 12, Color(0.82, 0.68, 0.46))
			var knot: Vector2 = front[front.size() - 1]
			var tail_pts := _bez(knot, knot + Vector2(40, 10), Vector2(236, 214), 14)
			_rope(tail_pts, 11, Color(0.82, 0.68, 0.46))
			_ball(knot, 11, Color(0.82, 0.68, 0.46), 5.0)
			_glow(t + Vector2(8, -2), 26, Color(T_MAGPIE, 0.4))
		_:
			_bolt(Vector2(40, 216), Vector2(216, 40), 12)


# ---------------------------------------------------------------- trading-post signs (market-trade.md 2.2)
func _post() -> void:
	_shape(_rect(Vector2(4, 22), Vector2(252, 44)), T_TIMBER.lightened(0.25), 5.0)
	draw_line(Vector2(8, 27), Vector2(248, 27), Color(1, 0.9, 0.7, 0.3), 3)
	_shape(_rect(Vector2(232, 16), Vector2(252, 50)), T_IRON, 4.0)
	for x in [72.0, 184.0]:
		draw_line(Vector2(x, 38), Vector2(x, 74), INK, 10)
		draw_line(Vector2(x, 38), Vector2(x, 74), T_IRON.lightened(0.35), 4)
		draw_arc(Vector2(x, 40), 7, 0.0, TAU, 12, INK, 7, true)
		draw_arc(Vector2(x, 40), 7, 0.0, TAU, 12, T_IRON.lightened(0.45), 3, true)
	var board := _chamfer(Vector2(24, 66), Vector2(232, 238), 16)
	_poly(board, T_FIELD.lightened(0.2), T_FIELD.darkened(0.3), 6.0)
	for gy in [100.0, 150.0, 200.0]:
		draw_line(Vector2(34, gy), Vector2(222, gy + 4), Color(0, 0, 0, 0.18), 2)
	draw_polyline(_closed(_chamfer(Vector2(35, 77), Vector2(221, 227), 11)), T_SIGN_GOLD.darkened(0.1), 4, true)
	match id:
		&"heron_ford": _heron()
		&"millstone_cross": _millstone()
		&"lantern_wharf": _lantern()
		&"saltgate": _gate()
		_: _star4(Vector2(128, 152), 50, T_SIGN_GOLD)


func _heron() -> void:
	for wy in [206.0, 218.0]:
		var wave := PackedVector2Array()
		for i in 25:
			var x: float = 64.0 + float(i) * 5.5
			wave.append(Vector2(x, wy + sin(float(i) * 0.9 + wy) * 3.0))
		_stroke(wave, 4, T_SIGN_GOLD.darkened(0.05), 3.0)
	_stroke(PackedVector2Array([Vector2(114, 164), Vector2(110, 210)]), 5, T_SIGN_GOLD, 3.0)
	_stroke(PackedVector2Array([Vector2(126, 164), Vector2(140, 188), Vector2(128, 208)]), 5, T_SIGN_GOLD, 3.0)
	_gild(PackedVector2Array([Vector2(98, 148), Vector2(58, 178), Vector2(100, 166)]))
	_gild(_ell_rot(Vector2(118, 150), 38, 20, -0.28, 32))
	draw_polyline(_bez(Vector2(94, 150), Vector2(116, 138), Vector2(142, 146), 10), T_SIGN_GOLD.darkened(0.45), 3, true)
	_gild(_tube(_bez(Vector2(138, 142), Vector2(114, 102), Vector2(156, 86), 14), 17, 11))
	_gild(_ell(Vector2(160, 82), 12, 10, 20))
	_gild(PackedVector2Array([Vector2(166, 76), Vector2(206, 88), Vector2(166, 90)]), 4.0)
	_stroke(PackedVector2Array([Vector2(152, 76), Vector2(126, 66)]), 3, T_SIGN_GOLD, 3.0)
	draw_circle(Vector2(163, 80), 2.5, T_FIELD.darkened(0.4))


func _millstone() -> void:
	var c := Vector2(128, 150)
	draw_circle(c + Vector2(0, 9), 64, INK)
	draw_circle(c, 64, INK)
	draw_circle(c + Vector2(0, 9), 61, T_SIGN_GOLD.darkened(0.45))
	_gild(_ell(c, 61, 61, 48), 0.0)
	draw_arc(c, 54, 0.0, TAU, 48, T_SIGN_GOLD.darkened(0.35), 4, true)
	for i in 10:
		var a: float = TAU * float(i) / 10.0
		draw_line(c + Vector2(cos(a), sin(a)) * 20.0, c + Vector2(cos(a + 0.42), sin(a + 0.42)) * 50.0, T_SIGN_GOLD.darkened(0.4), 4)
	draw_circle(c, 15, INK)
	draw_circle(c, 11, T_FIELD.darkened(0.45))
	draw_arc(c, 40, deg_to_rad(200.0), deg_to_rad(280.0), 12, Color(1, 0.97, 0.8, 0.7), 4, true)


func _lantern() -> void:
	var c := Vector2(128, 150)
	_glow(c + Vector2(0, -6), 84, Color(1.0, 0.8, 0.4, 0.55))
	draw_arc(Vector2(128, 88), 9, PI, TAU, 12, INK, 9, true)
	draw_arc(Vector2(128, 88), 9, PI, TAU, 12, T_SIGN_GOLD, 4, true)
	_gild(PackedVector2Array([Vector2(98, 112), Vector2(158, 112), Vector2(144, 90), Vector2(112, 90)]))
	_poly(_rect(Vector2(102, 112), Vector2(154, 186)), Color(1.0, 0.95, 0.72), Color(1.0, 0.68, 0.28), 6.0)
	_fire(Vector2(128, 176), 22, 46, false)
	for x in [102.0, 128.0, 154.0]:
		_stroke(PackedVector2Array([Vector2(x, 112), Vector2(x, 186)]), 5, T_SIGN_GOLD, 3.0)
	_gild(PackedVector2Array([Vector2(94, 186), Vector2(162, 186), Vector2(150, 206), Vector2(106, 206)]))


func _gate() -> void:
	for x0 in [60.0, 158.0]:
		_gild(_rect(Vector2(x0, 104), Vector2(x0 + 38, 214)))
		for m in 3:
			_gild(_rect(Vector2(x0 - 2 + float(m) * 15.0, 90), Vector2(x0 + 8 + float(m) * 15.0, 106)), 4.0)
		draw_line(Vector2(x0 + 19, 128), Vector2(x0 + 19, 150), T_FIELD.darkened(0.3), 5)
	_gild(_rect(Vector2(96, 128), Vector2(160, 214)))
	for m in 3:
		_gild(_rect(Vector2(98 + float(m) * 22.0, 116), Vector2(114 + float(m) * 22.0, 130)), 4.0)
	var arch := PackedVector2Array([Vector2(110, 214), Vector2(110, 164)])
	arch.append_array(_ell(Vector2(128, 164), 18, 18, 12, PI, TAU))
	arch.append(Vector2(146, 214))
	_poly(arch, T_FIELD.darkened(0.2), T_FIELD.darkened(0.55), 4.0)
	for x in [117.0, 128.0, 139.0]:
		draw_line(Vector2(x, 150 if x == 128.0 else 154), Vector2(x, 212), T_SIGN_GOLD, 3)
	for y in [176.0, 196.0]:
		draw_line(Vector2(112, y), Vector2(144, y), T_SIGN_GOLD, 3)


# ---------------------------------------------------------------- UI glyphs (ui-trade.md 15 / 16.2)
func _ui() -> void:
	match id:
		&"gold_coin":
			_coin(Vector2(128, 118), 104, 7.0)
		&"exchange_crystals":
			_crystal(Vector2(190, 84), 1.2, CRYSTAL)
			_path_arrow(_bez(Vector2(70, 114), Vector2(84, 40), Vector2(152, 56), 18), 16, 44, 34, T_GO)
			_coin(Vector2(80, 176), 58)
		&"exchange_essence":
			_dark_fire(Vector2(190, 138), 76, 118)
			_path_arrow(_bez(Vector2(70, 114), Vector2(84, 40), Vector2(152, 56), 18), 16, 44, 34, T_GO)
			_coin(Vector2(80, 176), 58)
		&"crest_bazaar":
			var sh := _heater(Vector2(128, 128), 200, 232)
			_poly(sh, T_FIELD.lightened(0.25), T_FIELD.darkened(0.3), 7.0)
			draw_polyline(_closed(_heater(Vector2(128, 126), 176, 206)), T_SIGN_GOLD, 5, true)
			var pans: Array = _balance(Vector2(128, 70), 0.78, T_SIGN_GOLD, -0.12)
			_coin_flat(pans[0] + Vector2(0, -8), 20, 6, 4.0)
			_coin_flat(pans[0] + Vector2(0, -16), 20, 6, 4.0)
			_pan(pans[0], 0.78, T_SIGN_GOLD)
			_shape(_rect(pans[1] + Vector2(-16, -26), pans[1] + Vector2(16, 2)), WOOD, 4.0)
			_pan(pans[1], 0.78, T_SIGN_GOLD)
		&"crest_lodge":
			var sh := _heater(Vector2(128, 128), 200, 232)
			_poly(sh, T_LODGE.lightened(0.15), T_LODGE.darkened(0.45), 7.0)
			draw_polyline(_closed(_heater(Vector2(128, 126), 176, 206)), BRONZE.lightened(0.2), 5, true)
			_horn(Vector2(70, 84), Vector2(84, 186), Vector2(196, 112), 10, 50)
			_glow(Vector2(128, 206), 20, Color(T_AMBER, 0.6))
			draw_circle(Vector2(128, 206), 6, T_AMBER.lightened(0.4))
		_:
			_coin(C, 90)
