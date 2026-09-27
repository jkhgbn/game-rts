extends SceneTree
## Builds the Wayshrine (task 12.V18): bakes its meshes to art/buildings/capture/wayshrine/meshes/*.res and packs
## wayshrine.tscn (root script wayshrine.gd). The game only loads the results. Run it WINDOWED (a headless run may
## drop mesh data when saving) after any change to the geometry below:
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/buildings/capture/wayshrine/build_wayshrine.gd --quit-after 60
## Vertex conventions: see wayshrine_stone.gdshader (COLOR rgb + height gradient, UV.x moss, UV.y height above the
## ground, UV2.x rune mask), wayshrine_beam.gdshader (column UVs) and wayshrine_motes.gdshader (per-mote COLOR).
## Flat-shaded, indexed (SurfaceTool.index()), one surface per mesh, the shared .tres material set on the surface.

const DIR := "res://art/buildings/capture/wayshrine/"
const MESH_DIR := DIR + "meshes/"
const SCENE_PATH := DIR + "wayshrine.tscn"
const SCRIPT_PATH := DIR + "wayshrine.gd"
const STONE_MAT := DIR + "wayshrine_stone_mat.tres"
const COLUMN_MAT := DIR + "wayshrine_column_mat.tres"
const RING_MAT := DIR + "wayshrine_ring_mat.tres"
const HALO_MAT := DIR + "wayshrine_halo_mat.tres"
const BURST_MAT := DIR + "wayshrine_burst_mat.tres"
const MOTES_MAT := DIR + "wayshrine_motes_mat.tres"
## Shared soft contact shadow of the map's props (multiplied, order independent; A2.8).
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"

const FLOAT_Y := 1.6
const STONE_TOP := 1.42
const DAIS_IN := 0.97         # inner tier radius
const CHANNEL_OUT := 1.25     # dark rune channel between the tiers
const DAIS_OUT := 1.86        # outer flagstone ring
const RING_RADIUS := 1.11     # glowing rune circle (wayshrine_ring_mat.tres ring_radius)
const RING_DISC := 2.2
const BURST_RADIUS := 6.5
const MOTE_COUNT := 30

# Palette (sRGB): neutral weathered stone (saturation <= 0.2), dark slate for the rune stone so gold / team glow pops.
# The standing stone is the lightest value (the vertical reads first), the dais a step darker.
const C_STONE := Color(0.69, 0.67, 0.61)
const C_STONE_DARK := Color(0.47, 0.45, 0.42)
const C_DAIS := Color(0.50, 0.48, 0.44)
const C_DAIS_IN := Color(0.55, 0.53, 0.48)
const C_CHANNEL := Color(0.21, 0.19, 0.18)
const C_MARKER := Color(0.56, 0.55, 0.51)
const C_RUBBLE := Color(0.43, 0.41, 0.38)
const C_SLATE := Color(0.25, 0.26, 0.32)
const C_SLATE_LIGHT := Color(0.29, 0.30, 0.36)


class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()


## Flat-shaded builder. Every triangle faces along a hint direction; the current `col`, `moss`, `rune`, `lift` (added to
## UV.y) and height-gradient range `grad` are baked on the vertices added. `xf` transforms what is added.
class MB:
	var s := Surf.new()
	var col := Color.WHITE
	var moss := 0.0
	var rune := 0.0
	var lift := 0.0
	var grad := Vector2(0.0, 1.3)
	var face_var := 0.07
	var xf := Transform3D.IDENTITY

	func tri(a: Vector3, b: Vector3, c: Vector3, hint: Vector3) -> void:
		a = xf * a
		b = xf * b
		c = xf * c
		hint = xf.basis * hint
		var nn: Vector3 = (b - a).cross(c - a)
		if nn.length_squared() < 1e-14:
			return
		nn = nn.normalized()
		if nn.dot(hint) < 0.0:
			var t: Vector3 = b
			b = c
			c = t
			nn = -nn
		var cen: Vector3 = (a + b + c) / 3.0
		var h: float = fposmod(sin(cen.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)
		var fc: Color = col * (1.0 + (h - 0.5) * 2.0 * face_var)
		# Godot's front faces are clockwise: emit a, c, b.
		for p: Vector3 in [a, c, b]:
			s.v.append(p)
			s.n.append(nn)
			var ga: float = clampf((p.y - grad.x) / maxf(grad.y - grad.x, 0.01), 0.0, 1.0)
			s.c.append(Color(fc.r, fc.g, fc.b, ga))
			s.uv.append(Vector2(moss, p.y + lift))
			s.uv2.append(Vector2(rune, 0.0))

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3) -> void:
		tri(a, b, c, hint)
		tri(a, c, d, hint)

	func commit(mat: Material) -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in s.v.size():
			st.set_normal(s.n[i])
			st.set_color(s.c[i])
			st.set_uv(s.uv[i])
			st.set_uv2(s.uv2[i])
			st.add_vertex(s.v[i])
		st.index()
		st.set_material(mat)
		return st.commit()


var _frame: int = 0
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	var meshes: Dictionary = {
		"stone": _build_stone(),
		"rune_stone": _build_rune_stone(),
		"shards": _build_shards(),
		"column": _build_column(),
		"motes": _build_motes(),
		"ring": _flat_quad(RING_DISC, load(RING_MAT) as Material, false),
		"burst": _flat_quad(BURST_RADIUS, load(BURST_MAT) as Material, false),
		"halo": _flat_quad(1.25, load(HALO_MAT) as Material, true),
		"contact": _build_contact(),
	}
	var saved: Dictionary = {}
	for key: String in meshes:
		var path: String = MESH_DIR + key + ".res"
		var mesh: ArrayMesh = meshes[key]
		var err: int = ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
		var tris: int = mesh.surface_get_array_index_len(0) / 3
		print("baked %s tris=%d aabb=%s err=%d" % [path, tris, mesh.get_aabb(), err])
		saved[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	_pack_scene(saved)
	return true


# ============================================================ geometry helpers

## Signed area of a 2D polygon (positive = counter-clockwise).
static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i: int in p.size():
		var q: Vector2 = p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5


static func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if _area(p) >= 0.0:
		return p
	var r := PackedVector2Array()
	for i: int in range(p.size() - 1, -1, -1):
		r.append(p[i])
	return r


## Miter inset of a counter-clockwise polygon by `d` (convex or mildly concave).
static func _inset(p: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = p.size()
	for i: int in n:
		var p0: Vector2 = p[(i - 1 + n) % n]
		var p1: Vector2 = p[i]
		var p2: Vector2 = p[(i + 1) % n]
		var e0: Vector2 = (p1 - p0).normalized()
		var e1: Vector2 = (p2 - p1).normalized()
		var n0 := Vector2(-e0.y, e0.x)
		var n1 := Vector2(-e1.y, e1.x)
		var bis: Vector2 = n0 + n1
		bis = n0 if bis.length() < 1e-4 else bis.normalized()
		out.append(p1 + bis * (d / maxf(bis.dot(n0), 0.4)))
	return out


static func _centroid(p: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q: Vector2 in p:
		c += q
	return c / float(p.size())


## A flat slab: convex polygon (x, z) from y0 up to a (tilted) top at `ytop`, with a bevelled top edge.
func _slab(mb: MB, poly: PackedVector2Array, y0: float, ytop: float, tilt: Vector2, bev: float) -> void:
	poly = _ccw(poly)
	var cen: Vector2 = _centroid(poly)
	var inner: PackedVector2Array = _inset(poly, bev)
	var n: int = poly.size()
	var r0: Array[Vector3] = []
	var r1: Array[Vector3] = []
	var r2: Array[Vector3] = []
	for i: int in n:
		var p: Vector2 = poly[i]
		var q: Vector2 = inner[i]
		var yt: float = ytop + tilt.x * (p.x - cen.x) + tilt.y * (p.y - cen.y)
		var yq: float = ytop + tilt.x * (q.x - cen.x) + tilt.y * (q.y - cen.y)
		r0.append(Vector3(p.x, y0, p.y))
		r1.append(Vector3(p.x, yt - bev, p.y))
		r2.append(Vector3(q.x, yq, q.y))
	var mid := Vector3(cen.x, (y0 + ytop) * 0.5, cen.y)
	for i: int in n:
		var j: int = (i + 1) % n
		var fc: Vector3 = (r0[i] + r0[j] + r1[i] + r1[j]) * 0.25
		mb.quad(r0[i], r0[j], r1[j], r1[i], fc - mid)
		var bc: Vector3 = (r1[i] + r1[j] + r2[i] + r2[j]) * 0.25
		mb.quad(r1[i], r1[j], r2[j], r2[i], bc - mid)
	var top := Vector3(cen.x, ytop, cen.y)
	for i: int in n:
		mb.tri(top, r2[i], r2[(i + 1) % n], Vector3.UP)


## A rough standing stone / lump: an irregular `sides`-gon from radius r0 at y0 to r1 at h (leaning along `lean`), with
## a slanted top. Local space (use mb.xf to place / tip it over).
func _menhir(mb: MB, r0: float, r1: float, y0: float, h: float, lean: Vector2, slant: float, sides: int, seed: int) -> void:
	_rng.seed = seed
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	var ph: float = _rng.randf() * TAU
	var sd := Vector2.from_angle(_rng.randf() * TAU)
	for i: int in sides:
		var a: float = ph + TAU * (float(i) + _rng.randf_range(-0.18, 0.18)) / float(sides)
		var d := Vector2.from_angle(a)
		var j0: float = _rng.randf_range(0.82, 1.12)
		var j1: float = _rng.randf_range(0.78, 1.15)
		bot.append(Vector3(d.x * r0 * j0, y0, d.y * r0 * j0))
		var tp := Vector2(d.x * r1 * j1, d.y * r1 * j1) + lean * h
		top.append(Vector3(tp.x, h + slant * d.dot(sd) * r1 + _rng.randf_range(-0.02, 0.02), tp.y))
	var mid := Vector3(lean.x * h * 0.5, (y0 + h) * 0.5, lean.y * h * 0.5)
	for i: int in sides:
		var j: int = (i + 1) % sides
		var fc: Vector3 = (bot[i] + bot[j] + top[i] + top[j]) * 0.25
		mb.quad(bot[i], bot[j], top[j], top[i], fc - mid)
	var tc := Vector3.ZERO
	for p: Vector3 in top:
		tc += p
	tc /= float(sides)
	tc.y += 0.015
	for i: int in sides:
		mb.tri(tc, top[i], top[(i + 1) % sides], Vector3.UP)


# ============================================================ stone (dais + standing stone + markers), one surface

func _build_stone() -> ArrayMesh:
	var mb := MB.new()
	_build_dais(mb)
	_build_standing_stone(mb)
	_build_markers(mb)
	return mb.commit(load(STONE_MAT) as Material)


func _build_dais(mb: MB) -> void:
	mb.grad = Vector2(-0.35, 0.55)
	mb.lift = 0.26
	mb.rune = 0.0
	# Inner tier: seven wedge flagstones around the standing stone (a rose), top ~0.12.
	_rng.seed = 1812
	mb.col = C_DAIS_IN
	mb.moss = 0.3
	var wedges: int = 7
	for i: int in wedges:
		var a0: float = TAU * float(i) / float(wedges) + 0.03 + 0.2
		var a1: float = TAU * float(i + 1) / float(wedges) - 0.03 + 0.2
		var poly := PackedVector2Array([Vector2.from_angle((a0 + a1) * 0.5) * 0.06])
		for k: int in 4:
			var a: float = lerpf(a0, a1, float(k) / 3.0)
			poly.append(Vector2.from_angle(a) * (DAIS_IN - _rng.randf_range(0.0, 0.03)))
		var tilt := Vector2(_rng.randf_range(-0.018, 0.018), _rng.randf_range(-0.018, 0.018))
		_slab(mb, poly, -0.03, 0.12 + _rng.randf_range(-0.012, 0.01), tilt, 0.03)
	# Dark rune channel (the glowing circle sits over it).
	mb.col = C_CHANNEL
	mb.moss = 0.0
	mb.face_var = 0.03
	var segs: int = 36
	for i: int in segs:
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var p0 := Vector2.from_angle(a0)
		var p1 := Vector2.from_angle(a1)
		var ri: float = DAIS_IN - 0.02
		var ro: float = CHANNEL_OUT + 0.02
		mb.quad(Vector3(p0.x * ri, 0.03, p0.y * ri), Vector3(p1.x * ri, 0.03, p1.y * ri),
			Vector3(p1.x * ro, 0.03, p1.y * ro), Vector3(p0.x * ro, 0.03, p0.y * ro), Vector3.UP)
	mb.face_var = 0.07
	# Outer ring: irregular flagstones, two missing (broken gaps with rubble), one heaved up.
	_rng.seed = 2231
	mb.col = C_DAIS
	mb.moss = 0.45
	var a: float = 0.35
	var idx: int = 0
	while a < TAU + 0.3:
		var w: float = _rng.randf_range(0.46, 0.7)
		var a0: float = a + 0.035
		var a1: float = minf(a + w, TAU + 0.35) - 0.035
		a += w
		idx += 1
		if a1 - a0 < 0.18 or idx == 3 or idx == 4 or idx == 9:
			continue   # broken gaps (front-right, back-left)
		var ro: float = DAIS_OUT + _rng.randf_range(-0.07, 0.05)
		var ri: float = CHANNEL_OUT + 0.02
		var poly := PackedVector2Array([Vector2.from_angle(a0) * ri, Vector2.from_angle(a0) * ro,
			Vector2.from_angle((a0 + a1) * 0.5) * (ro + 0.02), Vector2.from_angle(a1) * ro, Vector2.from_angle(a1) * ri])
		var tilt := Vector2(_rng.randf_range(-0.02, 0.02), _rng.randf_range(-0.02, 0.02))
		var ytop: float = 0.085 + _rng.randf_range(-0.012, 0.012)
		if idx == 6:
			# Heaved slab: lifted on its outer edge by a root.
			var out := Vector2.from_angle((a0 + a1) * 0.5)
			tilt = out * 0.16
			ytop = 0.13
		_slab(mb, poly, -0.03, ytop, tilt, 0.025)
	# Rubble in the gaps and around the rim.
	mb.col = C_RUBBLE
	mb.moss = 0.8
	var rubble: Array = [[1.58, 0.62, 0.17], [1.82, 1.0, 0.12], [1.55, 4.3, 0.16], [1.85, 4.62, 0.11], [2.15, 2.3, 0.13],
		[2.2, 5.6, 0.12], [2.05, 3.2, 0.1]]
	for i: int in rubble.size():
		var r: Array = rubble[i]
		var p := Vector2.from_angle(float(r[1])) * float(r[0])
		mb.xf = Transform3D(Basis(Vector3.UP, float(i) * 1.7), Vector3(p.x, 0.0, p.y))
		var s: float = float(r[2])
		_menhir(mb, s * 1.1, s * 0.75, -0.04, s * 0.9, Vector2.ZERO, 0.4, 5, 400 + i)
	mb.xf = Transform3D.IDENTITY


## The front profile of the standing stone (x, y): tapering sides, two uneven horns cradling a notch.
static func _stone_profile() -> PackedVector2Array:
	return _ccw(PackedVector2Array([
		Vector2(-0.49, 0.0), Vector2(0.52, 0.0), Vector2(0.49, 0.4), Vector2(0.45, 0.9), Vector2(0.41, 1.16),
		Vector2(0.36, 1.3), Vector2(0.25, 1.28), Vector2(0.13, 1.17), Vector2(-0.01, 1.11), Vector2(-0.14, 1.17),
		Vector2(-0.24, 1.31), Vector2(-0.31, STONE_TOP), Vector2(-0.39, 1.36), Vector2(-0.44, 1.08),
		Vector2(-0.48, 0.55),
	]))


## Half depth of the standing stone at height y (tapers toward the top).
static func _half_depth(y: float) -> float:
	return lerpf(0.29, 0.2, clampf(y / STONE_TOP, 0.0, 1.0))


func _build_standing_stone(mb: MB) -> void:
	mb.grad = Vector2(0.0, STONE_TOP)
	mb.lift = 0.0
	mb.col = C_STONE
	mb.moss = 0.55
	mb.rune = 0.0
	var bev: float = 0.055
	var prof: PackedVector2Array = _stone_profile()
	var inner: PackedVector2Array = _inset(prof, bev)
	var n: int = prof.size()
	for side: float in [1.0, -1.0]:
		# Bevel band: outer profile (z = H - bev) -> inner profile on the face (z = H).
		for i: int in n:
			var j: int = (i + 1) % n
			var a := Vector3(prof[i].x, prof[i].y, side * (_half_depth(prof[i].y) - bev))
			var b := Vector3(prof[j].x, prof[j].y, side * (_half_depth(prof[j].y) - bev))
			var c := Vector3(inner[j].x, inner[j].y, side * _half_depth(inner[j].y))
			var d := Vector3(inner[i].x, inner[i].y, side * _half_depth(inner[i].y))
			var e: Vector2 = prof[j] - prof[i]
			var out := Vector2(e.y, -e.x).normalized()
			mb.quad(a, b, c, d, Vector3(out.x, out.y, side * 1.2))
		# Face: the inner profile, triangulated (the notch makes it concave).
		var tris: PackedInt32Array = Geometry2D.triangulate_polygon(inner)
		for t: int in range(0, tris.size(), 3):
			var pts: Array[Vector3] = []
			for k: int in 3:
				var q: Vector2 = inner[tris[t + k]]
				pts.append(Vector3(q.x, q.y, side * _half_depth(q.y)))
			mb.tri(pts[0], pts[1], pts[2], Vector3(0.0, 0.1, side))
	# Side walls around the profile.
	for i: int in n:
		var j: int = (i + 1) % n
		var e: Vector2 = prof[j] - prof[i]
		var out := Vector2(e.y, -e.x).normalized()
		var hi: float = _half_depth(prof[i].y) - bev
		var hj: float = _half_depth(prof[j].y) - bev
		mb.quad(Vector3(prof[i].x, prof[i].y, hi), Vector3(prof[j].x, prof[j].y, hj),
			Vector3(prof[j].x, prof[j].y, -hj), Vector3(prof[i].x, prof[i].y, -hi), Vector3(out.x, out.y, 0.0))
	# The Wayfarer's mark carved on both faces (reads the same from behind: mirrored in x).
	mb.rune = 1.0
	mb.col = C_STONE_DARK
	for side2: float in [1.0, -1.0]:
		for s: Array in _glyph_strokes():
			_stroke(mb, s[0], s[1], float(s[2]), side2)
	mb.rune = 0.0


## The Wayfarer's mark: a road climbing between two chevrons to a sun ring, on a base line. [from, to, width] (x, y).
static func _glyph_strokes() -> Array:
	var s: Array = []
	s.append([Vector2(-0.28, 0.26), Vector2(0.32, 0.26), 0.07])      # base line
	s.append([Vector2(0.02, 0.29), Vector2(0.02, 0.8), 0.07])        # the road
	s.append([Vector2(-0.22, 0.47), Vector2(0.02, 0.645), 0.065])    # lower chevron
	s.append([Vector2(0.02, 0.645), Vector2(0.26, 0.47), 0.065])
	s.append([Vector2(-0.17, 0.645), Vector2(0.02, 0.8), 0.06])      # upper chevron
	s.append([Vector2(0.02, 0.8), Vector2(0.21, 0.645), 0.06])
	var c := Vector2(0.02, 0.93)
	var r: float = 0.085
	for k: int in 8:
		var a0: float = TAU * float(k) / 8.0
		var a1: float = TAU * float(k + 1) / 8.0
		s.append([c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r, 0.045])
	# Side ticks (milestones).
	for y: float in [0.4, 0.58, 0.76]:
		s.append([Vector2(-0.39, y), Vector2(-0.32, y), 0.05])
		s.append([Vector2(0.33, y), Vector2(0.4, y), 0.05])
	return s


## A carved stroke on the front (side 1) or back (side -1) face of the standing stone: a thin inlay box standing 1.5 cm
## proud of the face, all faces rune-masked.
func _stroke(mb: MB, p: Vector2, q: Vector2, w: float, side: float) -> void:
	if side < 0.0:
		p.x = -p.x
		q.x = -q.x
	var b: float = (_half_depth(1.0) - _half_depth(0.0))   # dH/dy
	var nf := Vector3(0.0, -b, 1.0).normalized() * Vector3(1.0, 1.0, side)
	var e: Vector2 = q - p
	var len: float = e.length()
	var d: Vector2 = e / maxf(len, 1e-4)
	p -= d * w * 0.3
	q += d * w * 0.3
	var perp := Vector2(-d.y, d.x) * w * 0.5
	var corners: Array[Vector2] = [p - perp, q - perp, q + perp, p + perp]
	var lo: Array[Vector3] = []
	var hi: Array[Vector3] = []
	for c: Vector2 in corners:
		var base := Vector3(c.x, c.y, side * _half_depth(c.y))
		lo.append(base - nf * 0.01)
		hi.append(base + nf * 0.015)
	mb.quad(hi[0], hi[1], hi[2], hi[3], nf)
	var mid: Vector3 = (lo[0] + lo[2]) * 0.5
	for i: int in 4:
		var j: int = (i + 1) % 4
		var fc: Vector3 = (hi[i] + hi[j]) * 0.5
		mb.quad(lo[i], lo[j], hi[j], hi[i], fc - mid)


func _build_markers(mb: MB) -> void:
	mb.grad = Vector2(-0.15, 0.85)
	mb.lift = 0.0
	mb.col = C_MARKER
	mb.moss = 1.0
	# Upright (back-left), leaning (right), toppled and broken (front-left).
	mb.xf = Transform3D(Basis(Vector3.UP, 0.4), Vector3(-2.05, 0.0, -1.75))
	_menhir(mb, 0.26, 0.17, -0.05, 1.12, Vector2(-0.04, 0.02), 0.35, 6, 71)
	mb.xf = Transform3D(Basis(Vector3.UP, -0.9), Vector3(2.2, 0.0, -1.05))
	_menhir(mb, 0.21, 0.13, -0.05, 0.64, Vector2(0.36, -0.12), 0.3, 6, 72)
	mb.xf = Transform3D(Basis(Vector3.UP, 0.7) * Basis(Vector3.BACK, deg_to_rad(84.0)), Vector3(-1.9, 0.16, 1.7))
	_menhir(mb, 0.18, 0.15, -0.32, 0.32, Vector2.ZERO, 0.5, 6, 73)
	mb.xf = Transform3D(Basis(Vector3.UP, 1.9) * Basis(Vector3.BACK, deg_to_rad(80.0)), Vector3(-1.25, 0.13, 2.2))
	_menhir(mb, 0.15, 0.11, -0.05, 0.28, Vector2.ZERO, 0.6, 6, 74)
	mb.xf = Transform3D.IDENTITY


# ============================================================ floating rune stone (origin = its centre)

func _build_rune_stone() -> ArrayMesh:
	var mb := MB.new()
	mb.grad = Vector2(-0.55, 0.45)
	mb.lift = FLOAT_Y
	mb.moss = 0.0
	var sides: int = 6
	var tip_t := Vector3(0.025, 0.6, -0.02)
	var tip_b := Vector3(-0.02, -0.44, 0.015)
	var ru: Array[Vector3] = []
	var bt: Array[Vector3] = []
	var bb: Array[Vector3] = []
	var rl: Array[Vector3] = []
	for i: int in sides:
		var d := Vector2.from_angle(TAU * float(i) / float(sides) + 0.26)
		ru.append(Vector3(d.x * 0.285, 0.1, d.y * 0.285))
		bt.append(Vector3(d.x * 0.34, 0.1, d.y * 0.34))
		bb.append(Vector3(d.x * 0.34, -0.1, d.y * 0.34))
		rl.append(Vector3(d.x * 0.27, -0.1, d.y * 0.27))
	for i: int in sides:
		var j: int = (i + 1) % sides
		var mid_u: Vector3 = (ru[i] + ru[j]) * 0.5
		var mid_l: Vector3 = (rl[i] + rl[j]) * 0.5
		# Upper / lower facets.
		mb.col = C_SLATE_LIGHT if i % 2 == 0 else C_SLATE
		mb.rune = 0.0
		mb.tri(tip_t, ru[i], ru[j], (tip_t + ru[i] + ru[j]) / 3.0)
		mb.col = C_SLATE
		mb.tri(tip_b, rl[j], rl[i], (tip_b + rl[i] + rl[j]) / 3.0)
		# Belt ledges.
		mb.quad(ru[i], ru[j], bt[j], bt[i], Vector3.UP + mid_u * 0.2)
		mb.quad(bb[i], bb[j], rl[j], rl[i], Vector3.DOWN + mid_l * 0.2)
		# Belt: a band of rune panels.
		mb.rune = 1.0
		mb.quad(bt[i], bt[j], bb[j], bb[i], (bt[i] + bt[j]) * 0.5)
		# Upper facets: a glowing triangle inlay on every other one, a slit on the others.
		var fc: Vector3 = (tip_t + ru[i] + ru[j]) / 3.0
		var fn: Vector3 = (ru[i] - tip_t).cross(ru[j] - tip_t).normalized()
		if fn.dot(fc) < 0.0:
			fn = -fn
		if i % 2 == 0:
			var sc: float = 0.5
			mb.tri(fc + (tip_t - fc) * sc + fn * 0.01, fc + (ru[i] - fc) * sc + fn * 0.01, fc + (ru[j] - fc) * sc + fn * 0.01, fn)
		else:
			var top_p: Vector3 = fc + (tip_t - fc) * 0.62 + fn * 0.01
			var bot_p: Vector3 = mid_u + (fc - mid_u) * 0.2 + fn * 0.01
			var sv: Vector3 = (ru[j] - ru[i]).normalized() * 0.03
			mb.quad(bot_p - sv, bot_p + sv, top_p + sv * 0.3, top_p - sv * 0.3, fn)
		# Lower facets: a slit down the middle of every other one.
		if i % 2 == 1:
			var fc2: Vector3 = (tip_b + rl[i] + rl[j]) / 3.0
			var fn2: Vector3 = (rl[j] - tip_b).cross(rl[i] - tip_b).normalized()
			if fn2.dot(fc2) < 0.0:
				fn2 = -fn2
			var top_mid: Vector3 = mid_l + (fc2 - mid_l) * 0.15 + fn2 * 0.01
			var bot: Vector3 = fc2 + (tip_b - fc2) * 0.45 + fn2 * 0.01
			var side_v: Vector3 = (rl[j] - rl[i]).normalized() * 0.028
			mb.quad(top_mid - side_v, top_mid + side_v, bot + side_v * 0.3, bot - side_v * 0.3, fn2)
	# Dark stone ribs between the belt panels.
	mb.rune = 0.0
	mb.col = C_SLATE
	for i: int in sides:
		var d: Vector3 = Vector3(bt[i].x, 0.0, bt[i].z).normalized()
		var t := Vector3(-d.z, 0.0, d.x) * 0.026
		var o: Vector3 = d * 0.355
		var y0: float = -0.11
		var y1: float = 0.125
		var p0 := Vector3(o.x, y0, o.z)
		var p1 := Vector3(o.x, y1, o.z)
		var i0: Vector3 = p0 - d * 0.03
		var i1: Vector3 = p1 - d * 0.03
		mb.quad(p0 - t, p0 + t, p1 + t, p1 - t, d)
		mb.quad(i0 - t, p0 - t, p1 - t, i1 - t, -t)
		mb.quad(p0 + t, i0 + t, i1 + t, p1 + t, t)
		mb.quad(p1 - t, p1 + t, i1 + t, i1 - t, Vector3.UP)
	return mb.commit(load(STONE_MAT) as Material)


func _build_shards() -> ArrayMesh:
	var mb := MB.new()
	mb.grad = Vector2(-0.6, 0.6)
	mb.lift = FLOAT_Y
	mb.col = C_SLATE_LIGHT
	var spots: Array = [[0.0, 0.1, 1.0], [2.15, -0.08, 0.8], [4.2, 0.03, 0.9]]
	for i: int in spots.size():
		var sp: Array = spots[i]
		var c := Vector3(cos(float(sp[0])) * 0.64, float(sp[1]), sin(float(sp[0])) * 0.64)
		var s: float = float(sp[2]) * 1.3
		var bs := Basis(Vector3.UP, float(i) * 1.3) * Basis(Vector3.RIGHT, 0.4 + float(i) * 0.3)
		var top: Vector3 = c + bs * Vector3(0, 0.09 * s, 0)
		var bot: Vector3 = c + bs * Vector3(0, -0.08 * s, 0)
		var ring: Array[Vector3] = []
		for k: int in 4:
			var d := Vector2.from_angle(TAU * float(k) / 4.0)
			ring.append(c + bs * Vector3(d.x * 0.055 * s, 0.0, d.y * 0.04 * s))
		for k: int in 4:
			var kk: int = (k + 1) % 4
			mb.rune = 1.0 if k == 0 else 0.0
			mb.tri(top, ring[k], ring[kk], (top + ring[k] + ring[kk]) / 3.0 - c)
			mb.rune = 0.0
			mb.tri(bot, ring[kk], ring[k], (bot + ring[k] + ring[kk]) / 3.0 - c)
	return mb.commit(load(STONE_MAT) as Material)


# ============================================================ effects

## The light column: a beam flaring out of the rune stone's tip (y 2.05 r 0.1 -> y 12 r 0.8; seen from the high camera a
## column through the rune stone would wash it out) and a low wide sheath over the dais (r 1.15 -> 0.9, 3.4 m).
func _build_column() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layers: Array = [[0.1, 0.8, 2.05, 12.0, 1.0], [1.15, 0.9, 0.14, 3.4, 0.3]]
	var segs: int = 20
	var rows: int = 4
	for L: Array in layers:
		for i: int in segs + 1:
			for k: int in rows + 1:
				var u: float = float(i) / float(segs)
				var v: float = float(k) / float(rows)
				var r: float = lerpf(float(L[0]), float(L[1]), v)
				var d := Vector2.from_angle(u * TAU)
				st.set_normal(Vector3(d.x, 0.0, d.y))
				st.set_uv(Vector2(u, v))
				st.set_uv2(Vector2(float(L[4]), 0.0))
				st.add_vertex(Vector3(d.x * r, lerpf(float(L[2]), float(L[3]), v), d.y * r))
	# Indices per layer (vertices were added layer after layer).
	var per_layer: int = (segs + 1) * (rows + 1)
	for li: int in layers.size():
		var off: int = li * per_layer
		for i: int in segs:
			for k: int in rows:
				var a: int = off + i * (rows + 1) + k
				var b: int = off + (i + 1) * (rows + 1) + k
				st.add_index(a)
				st.add_index(b)
				st.add_index(a + 1)
				st.add_index(a + 1)
				st.add_index(b)
				st.add_index(b + 1)
	st.set_material(load(COLUMN_MAT) as Material)
	return st.commit()


## Motes: MOTE_COUNT quads at the origin, animated by wayshrine_motes.gdshader.
func _build_motes() -> ArrayMesh:
	_rng.seed = 9031
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for m: int in MOTE_COUNT:
		var c := Color(float(m) / float(MOTE_COUNT) + _rng.randf() * 0.02, _rng.randf_range(0.25, 0.9), _rng.randf(),
			_rng.randf())
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			st.set_color(c)
			st.set_uv(corner)
			st.set_normal(Vector3.BACK)
			st.add_vertex(Vector3(corner.x - 0.5, corner.y - 0.5, 0.0) * 0.001)
		var o: int = m * 4
		for ix: int in [0, 1, 2, 0, 2, 3]:
			st.add_index(o + ix)
	st.set_material(load(MOTES_MAT) as Material)
	var am: ArrayMesh = st.commit()
	am.custom_aabb = AABB(Vector3(-1.2, 0.0, -1.2), Vector3(2.4, 7.6, 2.4))
	return am


## A flat quad `half` metres from its centre: on the ground (normal up, UV v along +Z), or in XY (billboards).
func _flat_quad(half: float, mat: Material, vertical: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for p: Vector2 in pts:
		st.set_uv(Vector2(p.x * 0.5 + 0.5, p.y * 0.5 + 0.5))
		if vertical:
			st.set_normal(Vector3.BACK)
			st.add_vertex(Vector3(p.x * half, -p.y * half, 0.0))
		else:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(p.x * half, 0.0, p.y * half))
	for ix: int in [0, 1, 2, 0, 2, 3]:
		st.add_index(ix)
	st.set_material(mat)
	var am: ArrayMesh = st.commit()
	if vertical:
		am.custom_aabb = AABB(Vector3(-half, -half, -half), Vector3(half, half, half) * 2.0)
	return am


## The soft contact shadow under the dais (nature_contact_mat: UV.x 0 at the centre -> 1 at the rim).
func _build_contact() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 32
	var r: float = 2.8
	st.set_uv(Vector2(0.0, 0.0))
	st.set_uv2(Vector2.ZERO)
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(0.0, 0.02, 0.0))
	for i: int in segs:
		var d := Vector2.from_angle(TAU * float(i) / float(segs))
		st.set_uv(Vector2(1.0, 0.0))
		st.set_uv2(Vector2.ZERO)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(d.x * r, 0.02, d.y * r))
	for i: int in segs:
		var a: int = 1 + i
		var b: int = 1 + (i + 1) % segs
		# Clockwise seen from above (Godot's front face): centre, angle i, angle i + 1 (angles run from +X toward +Z).
		st.add_index(0)
		st.add_index(a)
		st.add_index(b)
	st.set_material(load(CONTACT_MAT) as Material)
	return st.commit()


# ============================================================ scene

func _mi(parent: Node, owner_node: Node, nm: String, mesh: Mesh, shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = owner_node
	return mi


func _pack_scene(m: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Wayshrine"
	root.set_script(load(SCRIPT_PATH))
	_mi(root, root, "Stone", m["stone"], true)
	_mi(root, root, "Contact", m["contact"], false)
	var ring: MeshInstance3D = _mi(root, root, "Ring", m["ring"], false)
	ring.position = Vector3(0.0, 0.17, 0.0)
	ring.visible = false
	var burst: MeshInstance3D = _mi(root, root, "Burst", m["burst"], false)
	burst.position = Vector3(0.0, 0.1, 0.0)
	burst.visible = false
	var column: MeshInstance3D = _mi(root, root, "Column", m["column"], false)
	column.visible = false
	var motes: MeshInstance3D = _mi(root, root, "Motes", m["motes"], false)
	motes.visible = false
	var fl := Node3D.new()
	fl.name = "Float"
	fl.position = Vector3(0.0, FLOAT_Y, 0.0)
	root.add_child(fl)
	fl.owner = root
	_mi(fl, root, "RuneStone", m["rune_stone"], true)
	var halo: MeshInstance3D = _mi(fl, root, "Halo", m["halo"], false)
	halo.visible = false
	var orbit := Node3D.new()
	orbit.name = "Orbit"
	fl.add_child(orbit)
	orbit.owner = root
	_mi(orbit, root, "Shards", m["shards"], false)
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	var err2: int = ResourceSaver.save(ps, SCENE_PATH)
	print("packed %s err=%d save=%d" % [SCENE_PATH, err, err2])
	root.free()
