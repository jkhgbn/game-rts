extends RefCounted
## G-F review 3 item 10 (docs/art/gf_thornwater_bridges.md): Thornwater's crown lane bridges as fen-timber trestles
## instead of the mossy stone bridge (whose deck read as a flat green "carpet" under the Thornwater moss). Built in code
## once per run (static cache), never saved: the shared lane_bridge.res is only read. Reach it with load():
##     var tb: GDScript = load("res://art/environment/bridges/timber_bridge_meshes.gd")
##     tb.lane_bridge(src)     # src = lane_bridge.res; a NEW ArrayMesh in the same local frame (LaneBridgeArt)
## CrownIsleVariant (thornwater) swaps it onto each crown lane bridge's "Mesh" node and puts lane_bridge.res back
## when it leaves the tree.
##
## Same draw cost as the stone bridge (3 surfaces, every tier): 0 the timber (shared env_painted_mat.tres, the road
## bridge's timber material: COLOR.rgb sRGB block, COLOR.a height gradient, UV = (sway 0, height for the contact band)),
## 1 the source's gold bands, 2 its ember coals (same arrays, same shared materials). The four iron braziers (bowls and
## coal lumps) are copied from the source's stone surface, so they sit on timber corner posts exactly where they were.
## Local frame = LaneBridgeArt (metres, +Z away from the isle at (0, 0, -12.75), X along the moat; water r 11.0-14.5 at
## y -0.35, trench bed y -1.0). Draw-only: no collider (the navmesh carve is unchanged).
## Look: weathered grey-brown plank deck laid across the lane with dark gaps (stringers and water show through), a low
## kerb log, post-and-rail sides (two rails, one bay's mid rail broken), three pile bents in the moat with a slimy band
## at the waterline and a black-brown wet foot, cross braces, fender piles where the moat foams (LaneBridgeArt
## WATER_STONES), timber sheet-pile bank revetments and half-buried sill logs at both ends.

const ENV_MAT := "res://art/environment/env_painted_mat.tres"
const MOAT_R := 12.75
const WATER_IN := 11.0
const WATER_OUT := 14.5
const BED_Y := -1.05
const DECK_TOP := 0.03          ## plank tops 0.03-0.042 (units stand at y 0)
const PLANK_TH := 0.07
const DECK_HL := 3.3
const POST_X := 4.62            ## LaneBridgeArt corner posts (the braziers stand on them)
const POST_Z := 3.1
const BRAZIER_Y := 1.125        ## the braziers' foot (stone post cap top in build_lane_bridge.gd)
const RAIL_X := 4.15
const BENTS: Array[float] = [11.55, 12.75, 13.95]
const PILE_X: Array[float] = [-4.15, -2.0, 0.0, 2.0, 4.15]
const STRINGER_X: Array[float] = [-3.55, -1.9, 0.0, 1.9, 3.55]
const SPLIT_X: Array[float] = [-1.9, 0.0, 1.9]
const WET_TOP := -0.40           ## below: black-brown wet foot
const SLIME_TOP := -0.19         ## -0.40 .. -0.19: green-brown slime band at the waterline
const UV_DECK := 0.6             ## UV.y = y + this (no contact darkening on the deck)

## Thornwater fen timber (sRGB): weathered grey-brown, a step lighter than the marsh grass (~0.30) so the path reads.
const PLANK := Color(0.43, 0.37, 0.28)
const PLANK_SILVER := Color(0.50, 0.47, 0.40)
const PLANK_DAMP := Color(0.33, 0.28, 0.21)
const END_GRAIN := Color(0.27, 0.22, 0.16)
const BEAM := Color(0.25, 0.20, 0.145)
const POST := Color(0.35, 0.29, 0.21)
const POST_TOP := Color(0.42, 0.37, 0.29)
const RAIL := Color(0.39, 0.33, 0.245)
const SLIME := Color(0.19, 0.21, 0.12)
const WET := Color(0.12, 0.11, 0.085)
const STONE := Color(0.36, 0.35, 0.31)
const MOSS := Color(0.20, 0.26, 0.13)

## Brazier triangles copied from the source: above this height, near a corner post, iron / coal dark.
const BRAZIER_PICK_R := 0.5
const BRAZIER_MAX_VALUE := 0.45

static var _cache: Dictionary = {}


static func clear_cache() -> void:
	_cache.clear()


## The timber version of the crown lane bridge `src` (lane_bridge.res). Cached per source mesh; null for a null source.
static func lane_bridge(src: Mesh) -> ArrayMesh:
	if src == null:
		return null
	var key := "lane:%d" % src.get_instance_id()
	if _cache.has(key):
		return _cache[key]
	var b := Builder.new()
	b.build_lane()
	if src.get_surface_count() > 0:
		b.copy_braziers(src.surface_get_arrays(0))
	var out := ArrayMesh.new()
	b.commit(out, load(ENV_MAT) as Material)
	for s: int in range(1, src.get_surface_count()):   # gold bands, ember coals: shared arrays and materials
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), src.surface_get_arrays(s))
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(s))
		out.surface_set_name(out.get_surface_count() - 1, src.surface_get_name(s))
	_cache[key] = out
	return out


## A point at tangential offset x, radius r from the isle centre, height y (the moat curvature, as the stone bridge).
static func on_moat(x: float, r: float, y: float) -> Vector3:
	return Vector3(x, y, sqrt(maxf(r * r - x * x, 0.0)) - MOAT_R)


class Builder:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var conv := 1.0
	var uv_off := 0.6

	func _init() -> void:
		var arr: Array = BoxMesh.new().get_mesh_arrays()
		var bv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var bi: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var fn: Vector3 = (bv[bi[1]] - bv[bi[0]]).cross(bv[bi[2]] - bv[bi[0]])
		conv = 1.0 if fn.dot(bn[bi[0]]) >= 0.0 else -1.0

	# ------------------------------------------------------------ primitives

	## One flat triangle whose front faces along `hint`.
	func tri(a: Vector3, b: Vector3, cc: Vector3, col: Color, hint: Vector3, nn_in: Vector3 = Vector3.ZERO,
			k_in: float = -1.0) -> void:
		var fn: Vector3 = (b - a).cross(cc - a)
		if fn.length_squared() < 1e-12:
			return
		var sg: float = 1.0 if fn.dot(hint) >= 0.0 else -1.0
		var nn: Vector3 = fn.normalized() * sg if nn_in == Vector3.ZERO else nn_in
		if sg != conv:
			var t: Vector3 = b
			b = cc
			cc = t
		var k: float = k_in if k_in >= 0.0 else 1.0 + (TimberHash.h(((a + b + cc) / 3.0).snappedf(0.01)) - 0.5) * 0.08
		for p: Vector3 in [a, b, cc]:
			v.append(p)
			n.append(nn)
			c.append(Color(col.r * k, col.g * k, col.b * k, 1.0))
			uv.append(Vector2(0.0, p.y + uv_off))

	func quad(a: Vector3, b: Vector3, cc: Vector3, d: Vector3, col: Color, hint: Vector3) -> void:
		var qn: Vector3 = (cc - a).cross(d - b)
		if qn.length_squared() < 1e-12:
			qn = (b - a).cross(cc - a)
		if qn.length_squared() < 1e-12:
			return
		qn = qn.normalized()
		if qn.dot(hint) < 0.0:
			qn = -qn
		var k: float = 1.0 + (TimberHash.h(((a + b + cc + d) * 0.25).snappedf(0.01)) - 0.5) * 0.08
		tri(a, b, cc, col, hint, qn, k)
		tri(a, cc, d, col, hint, qn, k)

	## A box from 4 bottom + 4 top corners (same order around); `top_col` on the top face, `side_col` on the sides.
	func block(bot: Array, top: Array, top_col: Color, side_col: Color, bottom: bool = false) -> void:
		var centre := Vector3.ZERO
		for p: Vector3 in bot + top:
			centre += p
		centre /= 8.0
		for i: int in 4:
			var j: int = (i + 1) % 4
			var a: Vector3 = bot[i]
			var b: Vector3 = bot[j]
			var cc: Vector3 = top[j]
			var d: Vector3 = top[i]
			quad(a, b, cc, d, side_col, (a + b + cc + d) * 0.25 - centre)
		quad(top[0], top[1], top[2], top[3], top_col, (top[0] + top[1] + top[2] + top[3]) * 0.25 - centre)
		if bottom:
			quad(bot[0], bot[1], bot[2], bot[3], side_col.darkened(0.3), (bot[0] + bot[1] + bot[2] + bot[3]) * 0.25 - centre)

	## An oriented box (centre, basis, half extents).
	func box(centre: Vector3, basis: Basis, half: Vector3, top_col: Color, side_col: Color, bottom: bool = false) -> void:
		var bot: Array = []
		var top: Array = []
		for l: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			bot.append(centre + basis * Vector3(l.x * half.x, -half.y, l.y * half.z))
			top.append(centre + basis * Vector3(l.x * half.x, half.y, l.y * half.z))
		block(bot, top, top_col, side_col, bottom)

	## A squared beam from a to b (width w across, height h), its "up" as close to world up as the direction allows.
	func beam(a: Vector3, b: Vector3, w: float, h: float, col: Color) -> void:
		var d: Vector3 = b - a
		if d.length_squared() < 1e-6:
			return
		var fwd: Vector3 = d.normalized()
		var side: Vector3 = Vector3.UP.cross(fwd)
		if side.length_squared() < 1e-4:
			side = Vector3.RIGHT
		side = side.normalized()
		var up: Vector3 = fwd.cross(side).normalized()
		box((a + b) * 0.5, Basis(side, up, fwd), Vector3(w * 0.5, h * 0.5, d.length() * 0.5), col.lightened(0.05), col, true)

	## A round post (n-sided prism) from a to b, radius r; `cap` = a fan on the top end.
	func cyl(a: Vector3, b: Vector3, r: float, sides: int, col: Color, cap: bool = false, cap_col: Color = Color.BLACK) -> void:
		var d: Vector3 = b - a
		if d.length_squared() < 1e-6:
			return
		var fwd: Vector3 = d.normalized()
		var s1: Vector3 = Vector3.UP.cross(fwd)
		if s1.length_squared() < 1e-4:
			s1 = Vector3.RIGHT
		s1 = s1.normalized()
		var s2: Vector3 = fwd.cross(s1).normalized()
		for i: int in sides:
			var a0: float = i * TAU / sides
			var a1: float = (i + 1) * TAU / sides
			var o0: Vector3 = (s1 * cos(a0) + s2 * sin(a0)) * r
			var o1: Vector3 = (s1 * cos(a1) + s2 * sin(a1)) * r
			quad(a + o0, a + o1, b + o1, b + o0, col, (o0 + o1) * 0.5)
		if cap:
			for i: int in sides:
				var a0: float = i * TAU / sides
				var a1: float = (i + 1) * TAU / sides
				tri(b, b + (s1 * cos(a0) + s2 * sin(a0)) * r * 0.9, b + (s1 * cos(a1) + s2 * sin(a1)) * r * 0.9,
						cap_col, fwd)

	## A vertical pile from y0 to y1 at (x, z) with the waterline bands (wet foot, slime, timber), leaning by `lean`
	## (top offset, metres).
	func pile(xz: Vector2, r: float, y0: float, y1: float, col: Color, lean: Vector2, cap: bool) -> void:
		var cuts: Array[float] = [y0]
		for y: float in [WET_TOP, SLIME_TOP]:
			if y > y0 + 0.02 and y < y1 - 0.02:
				cuts.append(y)
		cuts.append(y1)
		for i: int in cuts.size() - 1:
			var ya: float = cuts[i]
			var yb: float = cuts[i + 1]
			var ta: float = (ya - y0) / maxf(y1 - y0, 0.01)
			var tb: float = (yb - y0) / maxf(y1 - y0, 0.01)
			var pa := Vector3(xz.x + lean.x * ta, ya, xz.y + lean.y * ta)
			var pb := Vector3(xz.x + lean.x * tb, yb, xz.y + lean.y * tb)
			var mid: float = (ya + yb) * 0.5
			var band: Color = WET if mid < WET_TOP else (SLIME if mid < SLIME_TOP else col)
			cyl(pa, pb, r, 6, band, cap and i == cuts.size() - 2, POST_TOP)

	# ------------------------------------------------------------ the bridge

	func build_lane() -> void:
		_deck()
		_bents()
		_rails()
		_corner_posts()
		_banks()

	## Planks laid across the lane (along X) with dark gaps; a few split over a stringer; ragged ends; damper near
	## the banks. Under them the stringers, the outer fascia beams and a kerb log on each side.
	func _deck() -> void:
		uv_off = UV_DECK
		var z: float = -DECK_HL
		var i: int = 0
		while z < DECK_HL - 0.15:
			var hh: float = TimberHash.h(Vector3(i, 3.0, 1.0))
			var z1: float = minf(z + 0.29 + hh * 0.07, DECK_HL)
			var col: Color = PLANK.lerp(PLANK_SILVER, TimberHash.h(Vector3(i, 4.0, 2.0)) * 0.65)
			if TimberHash.h(Vector3(i, 5.0, 3.0)) < 0.22:
				col = col.lerp(PLANK_DAMP, 0.7)
			col = col.lerp(PLANK_DAMP, smoothstep(2.3, 3.3, absf((z + z1) * 0.5)) * 0.45)
			var xl: float = -(3.98 + TimberHash.h(Vector3(i, 6.0, 4.0)) * 0.12)
			var xr: float = 3.98 + TimberHash.h(Vector3(i, 7.0, 5.0)) * 0.12
			if TimberHash.h(Vector3(i, 8.0, 6.0)) < 0.3:
				var xs: float = SPLIT_X[int(TimberHash.h(Vector3(i, 9.0, 7.0)) * 2.99)]
				_plank(xl, xs - 0.02, z, z1, col, i * 2)
				_plank(xs + 0.02, xr, z, z1, col.lerp(PLANK_SILVER, 0.25).darkened(0.04), i * 2 + 1)
			else:
				_plank(xl, xr, z, z1, col, i * 2)
			z = z1 + 0.045 + hh * 0.015
			i += 1
		# Stringers along the lane under the planks (they show through the gaps).
		for sx: float in STRINGER_X:
			box(Vector3(sx, -0.145, 0.0), Basis.IDENTITY, Vector3(0.08, 0.105, DECK_HL + 0.12), BEAM, BEAM.darkened(0.1))
		# Fascia beams outside the plank ends, kerb logs on the deck along both sides.
		for sgn: float in [-1.0, 1.0]:
			box(Vector3(sgn * 4.16, -0.15, 0.0), Basis.IDENTITY, Vector3(0.06, 0.15, DECK_HL + 0.05), BEAM, BEAM)
			cyl(Vector3(sgn * 3.84, 0.1, -DECK_HL + 0.05), Vector3(sgn * 3.84, 0.1, DECK_HL - 0.05), 0.075, 6,
					POST.lerp(PLANK_DAMP, 0.3))

	## One plank: x0..x1 across, z0..z1 along the lane; the top in three lengthwise strips (grain), the ends darker.
	func _plank(x0: float, x1: float, z0: float, z1: float, col: Color, seed: int) -> void:
		var h0: float = TimberHash.h(Vector3(seed, 11.0, 1.0))
		var h1: float = TimberHash.h(Vector3(seed, 12.0, 2.0))
		var yl: float = DECK_TOP + h0 * 0.012
		var yr: float = DECK_TOP + h1 * 0.012
		var yaw: float = (TimberHash.h(Vector3(seed, 13.0, 3.0)) - 0.5) * 0.02
		var zc: float = (z0 + z1) * 0.5
		var rot := Basis(Vector3.UP, yaw)
		var cen := Vector3((x0 + x1) * 0.5, 0.0, zc)
		var p := func(x: float, y: float, zz: float) -> Vector3:
			return cen + rot * (Vector3(x, y, zz) - cen)
		var bot: Array = [p.call(x0, yl - PLANK_TH, z0), p.call(x1, yr - PLANK_TH, z0), p.call(x1, yr - PLANK_TH, z1),
				p.call(x0, yl - PLANK_TH, z1)]
		var top: Array = [p.call(x0, yl, z0), p.call(x1, yr, z0), p.call(x1, yr, z1), p.call(x0, yl, z1)]
		var centre := Vector3.ZERO
		for q: Vector3 in bot + top:
			centre += q
		centre /= 8.0
		for k: int in 4:
			var j: int = (k + 1) % 4
			var a: Vector3 = bot[k]
			var b: Vector3 = bot[j]
			var side_col: Color = END_GRAIN if k == 1 or k == 3 else col.darkened(0.22)
			quad(a, b, top[j], top[k], side_col, (a + b + top[j] + top[k]) * 0.25 - centre)
		var tones: Array[float] = [0.96, 1.04, 0.99]
		for s: int in 3:
			var za: float = lerpf(z0, z1, s / 3.0)
			var zb: float = lerpf(z0, z1, (s + 1) / 3.0)
			quad(p.call(x0, yl, za), p.call(x1, yr, za), p.call(x1, yr, zb), p.call(x0, yl, zb),
					col * tones[(s + seed) % 3], Vector3.UP)

	## Three pile bents across the moat (crosshead beam along the moat arc + 5 piles; the outer two run up as the rail
	## posts), cross braces on the outer faces between the bents, fender piles where the moat foams.
	func _bents() -> void:
		uv_off = UV_DECK
		for bi: int in BENTS.size():
			var r: float = BENTS[bi]
			var xs: Array[float] = [-4.4, -2.2, 0.0, 2.2, 4.4]
			for k: int in xs.size() - 1:
				beam(TimberHash.at(xs[k], r, -0.335), TimberHash.at(xs[k + 1], r, -0.335), 0.2, 0.15, BEAM)
			for x: float in PILE_X:
				var p: Vector3 = TimberHash.at(x, r, 0.0)
				var hh: float = TimberHash.h(Vector3(x, r, 21.0))
				var lean := Vector2((hh - 0.5) * 0.06, (TimberHash.h(Vector3(x, r, 22.0)) - 0.5) * 0.06)
				if absf(x) > 4.0:
					pile(Vector2(p.x, p.z), 0.14, BED_Y, 0.98 + hh * 0.06, POST, lean, true)
				else:
					pile(Vector2(p.x, p.z), 0.12, BED_Y, -0.4, BEAM, lean * 0.5, false)
		for sgn: float in [-1.0, 1.0]:
			var x: float = sgn * 4.24
			for bi: int in BENTS.size() - 1:
				var a: Vector3 = TimberHash.at(x, BENTS[bi], 0.0)
				var b: Vector3 = TimberHash.at(x, BENTS[bi + 1], 0.0)
				beam(Vector3(a.x, -0.3, a.z), Vector3(b.x, -0.88, b.z), 0.07, 0.1, SLIME)
				beam(Vector3(a.x, -0.88, a.z), Vector3(b.x, -0.3, b.z), 0.07, 0.1, SLIME.darkened(0.15))
			# Fender cluster (3 lashed piles) where LaneBridgeArt's cutwater foam rings are (x +-4.75, moat centre).
			var f: Vector3 = TimberHash.at(sgn * 4.68, MOAT_R, 0.0)
			for k: int in 3:
				var ang: float = k * TAU / 3.0 + sgn
				var off := Vector2(cos(ang), sin(ang)) * 0.12
				var top: float = 0.18 + TimberHash.h(Vector3(k, sgn, 31.0)) * 0.3
				pile(Vector2(f.x, f.z) + off, 0.1, BED_Y, top, POST.darkened(0.1), off * 0.4, true)
			cyl(Vector3(f.x, -0.05, f.z), Vector3(f.x, 0.03, f.z), 0.25, 6, BEAM.darkened(0.2))   # the lashing
		# A loose plank half sunk where the stone bridge's fallen coping stone was (its foam ring stays).
		box(Vector3(4.9, -0.37, 0.42), Basis.from_euler(Vector3(0.18, 0.6, -0.12)), Vector3(0.6, 0.035, 0.15),
				PLANK_DAMP, PLANK_DAMP.darkened(0.2))

	## Post-and-rail sides: the outer piles, one deck post on the outer bank, the corner posts at both ends; a top
	## rail and a mid rail, the +X mid rail broken in its middle bay (one end hangs down).
	func _rails() -> void:
		uv_off = UV_DECK
		for sgn: float in [-1.0, 1.0]:
			var pts: Array[Vector3] = [Vector3(sgn * POST_X, 0.0, -POST_Z)]
			for r: float in BENTS:
				pts.append(TimberHash.at(sgn * RAIL_X, r, 0.0))
			var extra := Vector3(sgn * RAIL_X, 0.0, 1.85)
			pts.append(extra)
			pts.append(Vector3(sgn * POST_X, 0.0, POST_Z))
			box(Vector3(extra.x, 0.33, extra.z), Basis(Vector3.UP, 0.04 * sgn), Vector3(0.075, 0.66, 0.075), POST_TOP, POST)
			for k: int in pts.size() - 1:
				var a: Vector3 = pts[k]
				var b: Vector3 = pts[k + 1]
				var ya: float = 0.94 + TimberHash.h(Vector3(k, sgn, 41.0)) * 0.04
				var yb: float = 0.94 + TimberHash.h(Vector3(k + 1, sgn, 41.0)) * 0.04
				beam(Vector3(a.x, ya, a.z), Vector3(b.x, yb, b.z), 0.1, 0.09, RAIL)
				if sgn > 0.0 and k == 2:
					var m: Vector3 = a.lerp(b, 0.45)
					beam(Vector3(a.x, 0.52, a.z), Vector3(m.x, 0.5, m.z), 0.07, 0.07, RAIL.darkened(0.08))
					beam(Vector3(b.x, 0.52, b.z), b.lerp(a, 0.4) + Vector3(0.12, 0.1, 0.0), 0.07, 0.07, RAIL.darkened(0.08))
				else:
					beam(Vector3(a.x, 0.52, a.z), Vector3(b.x, 0.52, b.z), 0.07, 0.07, RAIL.darkened(0.08))

	## The four corner posts under the braziers (square, stout, a dark plate on top), with stones at their feet.
	func _corner_posts() -> void:
		uv_off = 0.0   # on the banks: the dark contact band at the ground
		for sgn: float in [-1.0, 1.0]:
			for zs: float in [-1.0, 1.0]:
				var cp := Vector3(sgn * POST_X, 0.0, zs * POST_Z)
				var yaw := Basis(Vector3.UP, 0.05 * sgn * zs)
				var post_top: float = BRAZIER_Y - 0.06
				box(cp + Vector3(0.0, (post_top - 0.08) * 0.5, 0.0), yaw, Vector3(0.17, (post_top + 0.08) * 0.5, 0.17),
						POST_TOP, POST.darkened(0.06))
				box(cp + Vector3(0.0, post_top + 0.03, 0.0), yaw, Vector3(0.25, 0.03, 0.25), BEAM, BEAM.darkened(0.1))
				for k: int in 2:
					var hh: float = TimberHash.h(Vector3(sgn, zs, 51.0 + k))
					var off := Vector3((0.3 + hh * 0.12) * sgn, 0.03, (k * 0.5 - 0.25) * zs + 0.2 * zs)
					box(cp + off, Basis(Vector3.UP, hh * 3.0), Vector3(0.13 + hh * 0.06, 0.07, 0.1 + hh * 0.05),
							STONE.lightened(0.05), STONE)
				# A tuft of moss at the post foot (the isle-side posts: wetter).
				if zs < 0.0:
					box(cp + Vector3(-0.2 * sgn, 0.015, 0.22), Basis(Vector3.UP, 0.4), Vector3(0.16, 0.02, 0.12), MOSS, MOSS.darkened(0.2))

	## Both ends: a half-buried sill log across the lane; the banks beside the bridge lined with timber sheet piles
	## (wet foot, slime band) and a waling beam, where the stone bridge had its block revetments.
	func _banks() -> void:
		uv_off = 0.0
		for zs: float in [-1.0, 1.0]:
			cyl(Vector3(-4.45, -0.04, zs * (DECK_HL + 0.12)), Vector3(4.45, -0.04, zs * (DECK_HL + 0.12)), 0.12, 6,
					BEAM.lerp(PLANK_DAMP, 0.4))
		uv_off = UV_DECK
		for sgn: float in [-1.0, 1.0]:
			for bank: int in 2:
				var inner: bool = bank == 0
				var r_edge: float = WATER_IN if inner else WATER_OUT
				var to_water: float = 1.0 if inner else -1.0
				var x_end: float = 4.3 + (1.75 if inner else 2.1)
				var x: float = 4.3
				var k: int = 0
				var first := Vector3.ZERO
				var last := Vector3.ZERO
				while x < x_end:
					var hh: float = TimberHash.h(Vector3(sgn, bank, 61.0 + k))
					var p: Vector3 = TimberHash.at(sgn * x, r_edge + to_water * 0.05, 0.0)
					var radial := Vector3(p.x, 0.0, p.z + MOAT_R).normalized()
					var b := Basis(Vector3.UP.cross(radial).normalized(), Vector3.UP, radial)
					var top: float = 0.02 + hh * 0.09 - (0.12 if k == 4 else 0.0)
					for band: Array in [[-0.85, WET_TOP, WET], [WET_TOP, SLIME_TOP, SLIME], [SLIME_TOP, top, POST]]:
						var y0: float = band[0]
						var y1: float = band[1]
						box(p + Vector3(0.0, (y0 + y1) * 0.5, 0.0), b, Vector3(0.095, (y1 - y0) * 0.5, 0.045),
								POST_TOP, band[2])
					if k == 0:
						first = p
					last = p
					x += 0.2 + hh * 0.03
					k += 1
				var push := Vector3(first.x, 0.0, first.z + MOAT_R).normalized() * to_water * 0.09
				beam(first + push + Vector3(0.0, -0.1, 0.0), last + push + Vector3(0.0, -0.1, 0.0), 0.08, 0.12, BEAM)

	# ------------------------------------------------------------ the braziers, commit

	## Copies the source's iron brazier bowls and coal lumps (stone surface triangles above the corner posts, dark).
	func copy_braziers(arr: Array) -> void:
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] is PackedVector3Array \
				else PackedVector3Array()
		var sc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] is PackedColorArray else PackedColorArray()
		var idx := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] is PackedInt32Array:
			idx = arr[Mesh.ARRAY_INDEX]
		else:
			for i: int in sv.size():
				idx.append(i)
		for t: int in range(0, idx.size() - 2, 3):
			var ok := true
			var cen := Vector3.ZERO
			for k: int in 3:
				var i: int = idx[t + k]
				var p: Vector3 = sv[i]
				cen += p
				if p.y < BRAZIER_Y - 0.01:
					ok = false
				if i < sc.size():
					var col: Color = sc[i]
					if maxf(col.r, maxf(col.g, col.b)) > BRAZIER_MAX_VALUE:
						ok = false
			if not ok:
				continue
			cen /= 3.0
			var near := false
			for sgn: float in [-1.0, 1.0]:
				for zs: float in [-1.0, 1.0]:
					if Vector2(cen.x - sgn * POST_X, cen.z - zs * POST_Z).length() < BRAZIER_PICK_R:
						near = true
			if not near:
				continue
			for k: int in 3:
				var i: int = idx[t + k]
				v.append(sv[i])
				n.append(sn[i] if i < sn.size() else Vector3.UP)
				var col: Color = sc[i] if i < sc.size() else Color(0.2, 0.2, 0.2)
				c.append(Color(col.r, col.g, col.b, 1.0))
				uv.append(Vector2(0.0, sv[i].y + 1.0))
			brazier_tris += 1

	var brazier_tris := 0

	func commit(mesh: ArrayMesh, mat: Material) -> void:
		for i: int in c.size():
			var cc: Color = c[i]
			cc.a = clampf((v[i].y + 1.0) / 1.6, 0.0, 1.0)
			c[i] = cc
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(0, mat)
		mesh.surface_set_name(0, "timber")


## Small static helpers the Builder reaches without the outer script's name.
class TimberHash:
	static func h(p: Vector3) -> float:
		return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)

	static func at(x: float, r: float, y: float) -> Vector3:
		return Vector3(x, y, sqrt(maxf(r * r - x * x, 0.0)) - MOAT_R)
