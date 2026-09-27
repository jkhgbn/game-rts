class_name WatchtowerMesh
extends RefCounted
## Geometry of the watchtower capture point (task 12.V17, docs/design/map-fill.md 4.2 / 10). Built once in code and
## cached (every tower shares the same meshes); materials are the shared .tres next to this file, per-tower state goes
## through instance uniforms (WatchtowerModel).
##
## Model space: origin = footprint centre on the ground, FRONT = +Z (the default camera side). Footprint 4 x 4 m.
## Masses (art-keep.md 0.1): a round, battered stone shaft on a two-step octagonal plinth (dominant) whose top is broken
## (ragged courses low at the front, a deep breach on the front-left showing the dark inside and a rubble floor; intact
## at the back), a rebuilt timber crown turned 45 degrees (standing on posts and struts over the ragged front; plank
## parapet with lookout windows, corner posts, cloth drapes) under a steep shingle pyramid roof with an iron finial and a
## vane (~9.6 m). Secondary, asymmetric, front-right: a banner pole topped by an iron cresset (the brazier). Small:
## string course, arched doorway with an open door, arrow slits, ivy, rubble. The broken parts sit low enough to show
## under the crown from the RTS camera (pitch 55).
##
## One surface, one material (watchtower_mat.tres, watchtower_painted.gdshader). Per vertex:
##   COLOR.rgb  sRGB colour block (cloth: a grey shade multiplied onto the owner / neutral colour)
##   COLOR.a    moss amount 0-1
##   UV         surface coordinates in metres (u along the surface, v up / along a slope) for the painted patterns
##   UV2.x      kind (K_* below)
## Flames: WatchtowerMesh.flames() = the cresset's flame card + a soft halo, camera-facing in the shader (quad centre in
## VERTEX, corner offset in UV2). Ring: ring() = the capture progress annulus (UV.x = signed angle from the front / PI).
## Banner: banner(size) = a hanging cloth grid, origin at its top-left corner (the pole side), UV (0, 0) top-left.

const K_PLAIN := 0
const K_STONE := 1
const K_PLANK := 2
const K_SHINGLE := 3
const K_IRON := 4
const K_CLOTH := 5
const K_EMBER := 6
const K_VOID := 7

# --- Layout (metres, model space) ---
const PLINTH_A0 := 1.92        # bottom step apothem (octagon faces toward the axes and diagonals)
const PLINTH_A1 := 1.74
const PLINTH_Y0 := 0.32
const PLINTH_Y1 := 0.55
const SHAFT_R0 := 1.6          # radius at the plinth top (batter: narrows upward)
const SHAFT_R1 := 1.3          # radius at the top
const SHAFT_TOP := 5.95
const COLS := 18               # 20 degrees each
const ROWS := 12               # stone courses of 0.45 m (the shader's course_height)
const COURSE := 0.45
const WALL := 0.46
const ARC_SCALE := 1.4483      # u (m) per radian: 13 blocks of 0.7 m around, no seam
## The broken top: intact courses per column (12 = up to SHAFT_TOP, ragged). Low at the front (the crown stands on
## posts over the ragged masonry there), a deep breach on the front-left, intact at the back and right.
const TOP_ROWS: Array[int] = [12, 11, 9, 7, 7, 8, 5, 6, 8, 10, 11, 12, 12, 12, 12, 12, 12, 12]
const INNER_ROW := 5           # the dark inside (inner wall + rubble floor) from this course up
const DOOR_ANGLE := 78.0       # degrees, x = r cos, z = r sin (90 = +Z front)
const DOOR_HALF := 0.47
const DOOR_SPRING := 1.33      # height of the arch spring above the plinth top
const CROWN_YAW := PI * 0.25   # the timber crown and roof are turned 45 degrees (a corner toward the camera)
const DECK_HALF := 1.6
const DECK_Y0 := 6.15
const DECK_Y1 := 6.32
const PARAPET := 1.52          # wall plane distance from the centre (crown frame)
const SILL_Y := 6.66
const WALL_TOP := 6.98
const RAIL_TOP := 7.1
const PLATE_Y0 := 7.38
const PLATE_Y1 := 7.54
const EAVE_HALF := 1.9
const ROOF_T := 0.15
const APEX_Y := 8.86
const APEX_HALF := 0.18
const HEIGHT := 9.45           # vane / spike top
const POLE := Vector3(1.72, 0.0, 1.72)
const POLE_TOP := 7.9
const CROSSBAR_Y := 7.45
const CROSSBAR_LEN := 1.46
const CRESSET_Y := 7.9         # bowl bottom (on the pole top)
const EMBER_Y := 8.17
const FLAME_BASE := Vector3(1.72, 8.1, 1.72)

# --- Palette (sRGB, neutral: no kingdom colour on the building itself; the owner shows on cloth / fire) ---
const C_STONE := Color(0.47, 0.45, 0.41)
const C_STONE_D := Color(0.37, 0.36, 0.34)
const C_STONE_IN := Color(0.20, 0.19, 0.18)
const C_TIMBER := Color(0.33, 0.23, 0.15)
const C_WOOD := Color(0.54, 0.40, 0.25)
const C_WOOD_OLD := Color(0.43, 0.37, 0.30)
const C_ROOF := Color(0.42, 0.34, 0.27)     # old grey-brown shingles: the owner's colour pops against them
const C_ROOF_UNDER := Color(0.21, 0.14, 0.09)
const C_IRON := Color(0.21, 0.21, 0.23)
const C_VOID := Color(0.045, 0.04, 0.035)
const C_IVY := Color(0.22, 0.37, 0.13)
const C_IVY_D := Color(0.15, 0.28, 0.10)
const C_EMBER := Color(0.10, 0.08, 0.07)

static var _cache: Dictionary = {}


## The tower (stone, timber, roof, pole, cresset, drapes, rubble): one indexed surface.
static func structure() -> ArrayMesh:
	if not _cache.has(&"structure"):
		var g := Geo.new()
		_build_plinth(g)
		_build_shaft(g)
		_build_door(g)
		_build_slits(g)
		_build_crown(g)
		_build_roof(g)
		_build_pole(g)
		_build_ivy(g)
		_build_rubble(g)
		_cache[&"structure"] = g.commit()
	return _cache[&"structure"]


## The cresset's flame card (base on the embers) + a soft halo quad (COLOR.g = 1). Billboarded in the shader.
static func flames() -> ArrayMesh:
	if not _cache.has(&"flames"):
		var g := Geo.new()
		g.billboard(FLAME_BASE, Vector2(0.62, 0.98), 0.0, false, 0.31)
		g.billboard(FLAME_BASE + Vector3(0, 0.3, 0), Vector2(1.9, 1.9), 0.5, true, 0.0)
		var m: ArrayMesh = g.commit()
		m.custom_aabb = AABB(FLAME_BASE + Vector3(-1.2, -1.2, -1.2), Vector3(2.4, 2.8, 2.4))
		_cache[&"flames"] = m
	return _cache[&"flames"]


## Flat annulus on the ground (y 0) from `r0` to `r1`; UV.x = signed angle from the front (+Z) / PI (-1..1, seam at
## the back), UV.y = 0 inner -> 1 outer.
static func ring(r0: float = 2.75, r1: float = 3.12, segs: int = 64) -> ArrayMesh:
	var key := StringName("ring_%.2f_%.2f_%d" % [r0, r1, segs])
	if not _cache.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in segs:
			var a0: float = -PI + TAU * float(i) / float(segs)
			var a1: float = -PI + TAU * float(i + 1) / float(segs)
			var p := [Vector3(sin(a0) * r0, 0, cos(a0) * r0), Vector3(sin(a1) * r0, 0, cos(a1) * r0),
				Vector3(sin(a1) * r1, 0, cos(a1) * r1), Vector3(sin(a0) * r1, 0, cos(a0) * r1)]
			var t := [Vector2(a0 / PI, 0), Vector2(a1 / PI, 0), Vector2(a1 / PI, 1), Vector2(a0 / PI, 1)]
			for k: int in [0, 2, 1, 0, 3, 2]:
				st.set_normal(Vector3.UP)
				st.set_uv(t[k])
				st.add_vertex(p[k])
		st.index()
		_cache[key] = st.commit()
	return _cache[key]


## A hanging cloth grid `size` (w, h) m: origin at the top-left corner, x to the right, y down to -h, facing +Z.
## UV (0, 0) = top-left, (1, 1) = bottom-right. `custom_aabb` leaves room for the wave.
static func banner(size: Vector2, cols: int = 6, rows: int = 12) -> ArrayMesh:
	var key := StringName("banner_%.2f_%.2f" % [size.x, size.y])
	if not _cache.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j: int in rows:
			for i: int in cols:
				var q: Array[Vector2] = [Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1), Vector2(i, j + 1)]
				for k: int in [0, 1, 2, 0, 2, 3]:
					var u := Vector2(q[k].x / float(cols), q[k].y / float(rows))
					st.set_normal(Vector3.BACK)
					st.set_uv(u)
					st.add_vertex(Vector3(u.x * size.x, -u.y * size.y, 0.0))
		st.index()
		var m: ArrayMesh = st.commit()
		m.custom_aabb = AABB(Vector3(-0.3, -size.y - 0.3, -0.5), Vector3(size.x + 0.6, size.y + 0.6, 1.0))
		_cache[key] = m
	return _cache[key]


# ------------------------------------------------------------------------------------------------ helpers

static func _ang(deg: float) -> float:
	return deg_to_rad(deg)


## Unit direction on the ground for an angle in radians (x = cos, z = sin: 90 degrees = +Z = front).
static func _dir(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, sin(a))


static func shaft_radius(y: float) -> float:
	return lerpf(SHAFT_R0, SHAFT_R1, clampf((y - PLINTH_Y1) / (SHAFT_TOP - PLINTH_Y1), 0.0, 1.0))


static func _row_y(j: int) -> float:
	return PLINTH_Y1 + float(j) * COURSE


## Jagged top of the stone shaft at column boundary k (under the crown's beams).
static func _top_y(k: int) -> float:
	var jag: Array[float] = [0.0, -0.08, -0.2, -0.05, 0.0, -0.12, -0.28, -0.1, -0.02, -0.18, -0.06, 0.0,
		-0.15, -0.3, -0.08, 0.0, -0.1, -0.22]
	return SHAFT_TOP + jag[posmod(k, COLS)]


static func _first_missing(c: int) -> int:
	return TOP_ROWS[posmod(c, COLS)]


## Height of the stone top at an angle (degrees).
static func top_at(deg: float) -> float:
	var c: int = int(floor(posmod(deg, 360.0) / (360.0 / float(COLS))))
	var m: int = _first_missing(c)
	return _top_y(c) if m >= ROWS else _row_y(m)


static func _moss(c: Color, m: float) -> Color:
	return Color(c.r, c.g, c.b, m)


# ------------------------------------------------------------------------------------------------ plinth / shaft

static func _build_plinth(g: Geo) -> void:
	# Two octagonal steps of dark stone (faces toward the axes and the diagonals), mossy at the foot.
	var off: float = PI / 8.0
	g.prism(Vector3.ZERO, 8, PLINTH_A0 / cos(off), PLINTH_A0 / cos(off), PLINTH_Y0, _moss(C_STONE_D, 0.5), K_STONE,
		false, true, false, off)
	g.prism(Vector3(0, PLINTH_Y0, 0), 8, PLINTH_A1 / cos(off), PLINTH_A1 / cos(off), PLINTH_Y1 - PLINTH_Y0,
		_moss(C_STONE_D.lightened(0.08), 0.35), K_STONE, false, true, false, off)
	# Worn nosing blocks on the front of the lower step (steps up to the door).
	var da: float = _ang(DOOR_ANGLE)
	var fwd: Vector3 = _dir(da)
	var side := Vector3(-fwd.z, 0, fwd.x)
	for s: float in [-0.52, 0.0, 0.52]:
		g.box(fwd * 1.88 + side * s + Vector3(0, 0.07, 0), Vector3(0.5, 0.14, 0.34), Basis(Vector3.UP, -da + PI * 0.5)
			* Basis(Vector3.UP, deg_to_rad(s * 7.0)), _moss(C_STONE_D, 0.5), K_STONE)


static func _shaft_point(k: int, y: float, dr: float = 0.0) -> Vector3:
	var a: float = TAU * float(k) / float(COLS)
	return _dir(a) * (shaft_radius(y) + dr) + Vector3(0, y, 0)


static func _shaft_normal(k: int) -> Vector3:
	var a: float = TAU * float(k) / float(COLS)
	var slope: float = (SHAFT_R0 - SHAFT_R1) / (SHAFT_TOP - PLINTH_Y1)
	return (_dir(a) + Vector3(0, slope, 0)).normalized()


static func _build_shaft(g: Geo) -> void:
	var stone := _moss(C_STONE, 0.3)
	var inner := _moss(C_STONE_IN, 0.0)
	for c: int in COLS:
		var miss: int = _first_missing(c)
		var u0: float = TAU * float(c) / float(COLS) * ARC_SCALE
		var u1: float = TAU * float(c + 1) / float(COLS) * ARC_SCALE
		var n0: Vector3 = _shaft_normal(c)
		var n1: Vector3 = _shaft_normal(c + 1)
		# Outer wall, course by course (the top course follows the jagged break).
		for j: int in mini(miss, ROWS):
			var ya: float = _row_y(j)
			var yb0: float = _row_y(j + 1) if j + 1 < ROWS else _top_y(c)
			var yb1: float = _row_y(j + 1) if j + 1 < ROWS else _top_y(c + 1)
			var a := _shaft_point(c, ya)
			var b := _shaft_point(c + 1, ya)
			var cc := _shaft_point(c + 1, yb1)
			var d := _shaft_point(c, yb0)
			var t := [Vector2(u0, ya - PLINTH_Y1), Vector2(u1, ya - PLINTH_Y1), Vector2(u1, yb1 - PLINTH_Y1),
				Vector2(u0, yb0 - PLINTH_Y1)]
			g.quad_n([a, b, cc, d], [n0, n1, n1, n0], stone, t, K_STONE)
		# Inner wall (seen through the breach), facing the centre.
		for j: int in range(INNER_ROW, mini(miss, ROWS)):
			var ya2: float = _row_y(j)
			var yb20: float = _row_y(j + 1) if j + 1 < ROWS else _top_y(c)
			var yb21: float = _row_y(j + 1) if j + 1 < ROWS else _top_y(c + 1)
			var p := [_shaft_point(c, ya2, -WALL), _shaft_point(c + 1, ya2, -WALL), _shaft_point(c + 1, yb21, -WALL),
				_shaft_point(c, yb20, -WALL)]
			var t2 := [Vector2(u0, ya2), Vector2(u1, ya2), Vector2(u1, yb21), Vector2(u0, yb20)]
			g.quad_n(p, [-n0, -n1, -n1, -n0], inner, t2, K_STONE)
		# Wall top (the jagged rim, under the crown) where the column reaches the top.
		if miss >= ROWS:
			var p3 := [_shaft_point(c, _top_y(c)), _shaft_point(c + 1, _top_y(c + 1)), _shaft_point(c + 1, _top_y(c + 1), -WALL),
				_shaft_point(c, _top_y(c), -WALL)]
			g.quad(p3, Vector3.UP, _moss(C_STONE, 0.9), [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, WALL), Vector2(u0, WALL)],
				K_STONE)
		else:
			# Breach lip: the broken course top, between the outer and the inner face.
			var yl: float = _row_y(miss)
			var p4 := [_shaft_point(c, yl), _shaft_point(c + 1, yl), _shaft_point(c + 1, yl, -WALL), _shaft_point(c, yl, -WALL)]
			g.quad(p4, Vector3.UP, _moss(C_STONE, 1.0), [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, WALL), Vector2(u0, WALL)],
				K_STONE)
	# Breach sides: the cut wall between two columns that break at different courses.
	for k: int in COLS:
		var ma: int = _first_missing(k - 1)
		var mb: int = _first_missing(k)
		if ma == mb:
			continue
		var lo: int = mini(ma, mb)
		var hi: int = maxi(ma, mb)
		var y_lo: float = _row_y(lo)
		var y_hi: float = _top_y(k) if hi >= ROWS else _row_y(hi)
		var a: float = TAU * float(k) / float(COLS)
		var tangent := Vector3(-sin(a), 0, cos(a))
		var nrm: Vector3 = -tangent if ma < mb else tangent
		var p5 := [_shaft_point(k, y_lo), _shaft_point(k, y_hi), _shaft_point(k, y_hi, -WALL), _shaft_point(k, y_lo, -WALL)]
		g.quad(p5, nrm, _moss(C_STONE, 0.6), [Vector2(0, y_lo), Vector2(0, y_hi), Vector2(WALL, y_hi), Vector2(WALL, y_lo)],
			K_STONE)
	# The dark inside: a rubble floor at the lowest breach course (fallen upper floors).
	var yf: float = _row_y(INNER_ROW) + 0.02
	g.prism(Vector3(0, yf - 0.05, 0), COLS, shaft_radius(yf) - WALL + 0.02, shaft_radius(yf) - WALL + 0.02, 0.05,
		_moss(C_STONE_IN.darkened(0.2), 0.0), K_STONE, false, true, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12017
	for i: int in 6:
		var a2: float = _ang(rng.randf_range(100.0, 200.0))
		var r2: float = rng.randf_range(0.2, 0.75)
		var s2: float = rng.randf_range(0.22, 0.4)
		g.box(_dir(a2) * r2 + Vector3(0, yf + s2 * 0.3, 0), Vector3(s2, s2 * 0.7, s2 * 0.9),
			Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))),
			_moss(C_STONE_IN.lightened(0.1), 0.0), K_STONE)
	# Loose blocks along the breach lip (breaks the course grid).
	for blk: Array in [[31.0, 11, 0.34], [50.0, 9, 0.36], [66.0, 7, 0.38], [88.0, 7, 0.4], [112.0, 8, 0.36], [127.0, 5, 0.42], [136.0, 5, 0.34],
			[152.0, 6, 0.4], [169.0, 8, 0.38], [188.0, 10, 0.32], [205.0, 11, 0.3]]:
		var a3: float = _ang(float(blk[0]))
		var y3: float = _row_y(int(blk[1]))
		var s3: float = float(blk[2])
		g.box(_dir(a3) * (shaft_radius(y3) - WALL * 0.45) + Vector3(0, y3 + s3 * 0.3, 0), Vector3(s3 * 1.3, s3 * 0.7, WALL * 0.8),
			Basis(Vector3.UP, -a3 + PI * 0.5) * Basis(Vector3.BACK, rng.randf_range(-0.25, 0.25)), _moss(C_STONE, 0.9), K_STONE)
	# String course: a dark stone band round the shaft at course 4 (below every breach, broken by the door arch).
	var ys: float = _row_y(4)
	for c2: int in COLS:
		if c2 == 3 or c2 == 4:
			continue
		var ac: float = TAU * (float(c2) + 0.5) / float(COLS)
		var r3: float = shaft_radius(ys) + 0.05
		var len: float = 2.0 * r3 * sin(PI / float(COLS)) + 0.05
		g.box(_dir(ac) * r3 + Vector3(0, ys, 0), Vector3(len, 0.17, 0.2), Basis(Vector3.UP, -ac + PI * 0.5),
			_moss(C_STONE_D, 0.7), K_STONE)


# ------------------------------------------------------------------------------------------------ door / slits

static func _build_door(g: Geo) -> void:
	var da: float = _ang(DOOR_ANGLE)
	var span: float = asin(DOOR_HALF / SHAFT_R0)
	var y0: float = PLINTH_Y1
	var steps: int = 8
	# Dark doorway following the wall curve, arched top (a flat plate would sink into the round wall).
	for i: int in steps:
		var f0: float = float(i) / float(steps)
		var f1: float = float(i + 1) / float(steps)
		var a0: float = da - span + 2.0 * span * f0
		var a1: float = da - span + 2.0 * span * f1
		var x0: float = (f0 - 0.5) * 2.0 * DOOR_HALF
		var x1: float = (f1 - 0.5) * 2.0 * DOOR_HALF
		var h0: float = y0 + DOOR_SPRING + sqrt(maxf(DOOR_HALF * DOOR_HALF - x0 * x0, 0.0))
		var h1: float = y0 + DOOR_SPRING + sqrt(maxf(DOOR_HALF * DOOR_HALF - x1 * x1, 0.0))
		var p := [_dir(a0) * (shaft_radius(y0) + 0.012) + Vector3(0, y0, 0), _dir(a1) * (shaft_radius(y0) + 0.012) + Vector3(0, y0, 0),
			_dir(a1) * (shaft_radius(h1) + 0.012) + Vector3(0, h1, 0), _dir(a0) * (shaft_radius(h0) + 0.012) + Vector3(0, h0, 0)]
		var mid: float = (a0 + a1) * 0.5
		g.quad(p, _dir(mid), _moss(C_VOID, 0.0), [Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, h1), Vector2(x0, h0)], K_VOID)
	# Jambs and voussoirs (dark dressed stone, proud of the wall).
	var fwd: Vector3 = _dir(da)
	var side := Vector3(-fwd.z, 0, fwd.x)
	var face := Basis(Vector3.UP, -da + PI * 0.5)
	var rw: float = shaft_radius(y0 + 0.7) + 0.02
	for s: float in [-1.0, 1.0]:
		g.box(fwd * rw + side * s * (DOOR_HALF + 0.12) + Vector3(0, y0 + DOOR_SPRING * 0.5, 0), Vector3(0.26, DOOR_SPRING, 0.24), face,
			_moss(C_STONE_D, 0.5), K_STONE)
	for i2: int in 7:
		var t: float = PI * (float(i2) + 0.5) / 7.0
		var ax: float = cos(t) * (DOOR_HALF + 0.12)
		var ay: float = sin(t) * (DOOR_HALF + 0.12)
		var rr: float = shaft_radius(y0 + DOOR_SPRING + ay) + 0.02
		g.box(fwd * rr + side * ax + Vector3(0, y0 + DOOR_SPRING + ay, 0), Vector3(0.24, 0.3, 0.24),
			face * Basis(Vector3.BACK, t - PI * 0.5), _moss(C_STONE_D, 0.6), K_STONE)
	# The door: planks with iron straps, swung open outward on its right hinge.
	var hinge: Vector3 = fwd * (SHAFT_R0 + 0.05) - side * DOOR_HALF + Vector3(0, y0, 0)
	var db: Basis = face * Basis(Vector3.UP, deg_to_rad(-52.0))
	var dx: Vector3 = db * Vector3(1, 0, 0)
	g.box(hinge + dx * 0.44 + Vector3(0, 0.84, 0), Vector3(0.86, 1.62, 0.08), db, _moss(C_WOOD_OLD, 0.3), K_PLANK)
	for y2: float in [0.35, 1.3]:
		g.box(hinge + dx * 0.44 + Vector3(0, y2, 0) + db * Vector3(0, 0, 0.05), Vector3(0.8, 0.09, 0.03), db, _moss(C_IRON, 0.0), K_IRON)


static func _build_slits(g: Geo) -> void:
	for s: Array in [[18.0, 3.75], [40.0, 1.6], [232.0, 2.3], [262.0, 4.9], [300.0, 3.6], [340.0, 1.55], [352.0, 5.15]]:
		var a: float = _ang(float(s[0]))
		var y: float = float(s[1])
		var face := Basis(Vector3.UP, -a + PI * 0.5)
		var r: float = shaft_radius(y)
		g.box(_dir(a) * (r + 0.01) + Vector3(0, y, 0), Vector3(0.24, 0.82, 0.04), face, _moss(C_VOID, 0.0), K_VOID)
		g.box(_dir(a) * (r + 0.03) + Vector3(0, y + 0.47, 0), Vector3(0.5, 0.14, 0.14), face, _moss(C_STONE_D, 0.6), K_STONE)
		g.box(_dir(a) * (r + 0.03) + Vector3(0, y - 0.46, 0), Vector3(0.44, 0.1, 0.14), face, _moss(C_STONE_D, 0.6), K_STONE)


# ------------------------------------------------------------------------------------------------ crown

static func _build_crown(g: Geo) -> void:
	var crown := Transform3D(Basis(Vector3.UP, CROWN_YAW), Vector3.ZERO)
	g.xf = crown
	var timber := _moss(C_TIMBER, 0.25)
	var wood := _moss(C_WOOD, 0.15)
	var span: float = DECK_HALF * 2.0 + 0.44
	# Wall plates (let into the broken top) and joists (on them): their ends show under the deck edge.
	for x: float in [-1.05, 1.05]:
		g.box(Vector3(x, SHAFT_TOP - 0.1, 0), Vector3(0.26, 0.24, span), Basis.IDENTITY, timber, K_PLAIN)
	for z: float in [-1.25, -0.55, 0.55, 1.25]:
		g.box(Vector3(0, DECK_Y0 - 0.1, z), Vector3(span, 0.2, 0.2), Basis.IDENTITY, timber, K_PLAIN)
	# Deck.
	g.box(Vector3(0, (DECK_Y0 + DECK_Y1) * 0.5, 0), Vector3(DECK_HALF * 2.0, DECK_Y1 - DECK_Y0, DECK_HALF * 2.0), Basis.IDENTITY,
		wood, K_PLANK)
	# Parapet: vertical boards with two lookout windows per side, a hand rail on top.
	var t: float = 0.1
	var pin: float = PARAPET - 0.14   # inner end of a side (the corner posts stand at +-PARAPET)
	for side: int in 4:
		var sb := Basis(Vector3.UP, PI * 0.5 * float(side))
		var solid: Array = [[-pin, -0.84], [-0.3, 0.3], [0.84, pin]]
		var gaps: Array = [[-0.84, -0.3], [0.3, 0.84]]
		for s: Array in solid:
			var w: float = float(s[1]) - float(s[0])
			var cx: float = (float(s[0]) + float(s[1])) * 0.5
			g.box(sb * Vector3(cx, (DECK_Y1 + WALL_TOP) * 0.5, PARAPET), Vector3(w, WALL_TOP - DECK_Y1, t), sb, wood, K_PLANK)
		for s2: Array in gaps:
			var w2: float = float(s2[1]) - float(s2[0])
			var cx2: float = (float(s2[0]) + float(s2[1])) * 0.5
			g.box(sb * Vector3(cx2, (DECK_Y1 + SILL_Y) * 0.5, PARAPET), Vector3(w2, SILL_Y - DECK_Y1, t), sb, wood, K_PLANK)
			g.box(sb * Vector3(cx2, SILL_Y + 0.03, PARAPET + 0.02), Vector3(w2 + 0.06, 0.07, 0.18), sb, timber, K_PLAIN)
		g.box(sb * Vector3(0, WALL_TOP + 0.06, PARAPET), Vector3(PARAPET * 2.0, 0.12, 0.16), sb, timber, K_PLAIN)
		# Mid post (above the rail) and the top plate.
		g.box(sb * Vector3(0, (RAIL_TOP + PLATE_Y0) * 0.5, PARAPET), Vector3(0.2, PLATE_Y0 - RAIL_TOP, 0.2), sb, timber, K_PLAIN)
		g.box(sb * Vector3(0, (PLATE_Y0 + PLATE_Y1) * 0.5, PARAPET), Vector3(PARAPET * 2.0 + 0.44, PLATE_Y1 - PLATE_Y0, 0.22), sb,
			timber, K_PLAIN)
		# Diagonal braces in the lookout opening (corner post -> plate).
		for sx: float in [-1.0, 1.0]:
			g.beam(sb * Vector3(sx * (PARAPET - 0.1), RAIL_TOP, PARAPET), sb * Vector3(sx * (PARAPET - 0.45), PLATE_Y0, PARAPET), 0.1,
				0.1, timber, K_PLAIN)
		_drape(g, sb, side)
	for cx3: float in [-1.0, 1.0]:
		for cz3: float in [-1.0, 1.0]:
			g.box(Vector3(cx3 * PARAPET, (DECK_Y1 + PLATE_Y1) * 0.5, cz3 * PARAPET), Vector3(0.27, PLATE_Y1 - DECK_Y1, 0.27),
				Basis.IDENTITY, timber, K_PLAIN)
	g.xf = Transform3D.IDENTITY
	# Struts under the deck corners (the corners point along the world axes), each on a stone corbel below the
	# broken top; the left one stands just past the breach.
	for a_deg: float in [0.0, 90.0, 190.0, 270.0]:
		var a: float = _ang(a_deg)
		var corner: float = _ang(roundf(a_deg / 90.0) * 90.0)
		var ys: float = minf(4.85, top_at(a_deg) - 0.4)
		g.beam(_dir(a) * (shaft_radius(ys) - 0.05) + Vector3(0, ys, 0), _dir(corner) * 2.02 + Vector3(0, DECK_Y0 - 0.14, 0), 0.2, 0.2,
			timber, K_PLAIN)
		g.box(_dir(a) * (shaft_radius(ys) + 0.06) + Vector3(0, ys - 0.07, 0), Vector3(0.3, 0.16, 0.3), Basis(Vector3.UP, -a),
			_moss(C_STONE_D, 0.6), K_STONE)
	# Rebuilt: two posts standing on the breach lip hold the deck edge over the gap, a lintel pegged across it.
	for pp: Array in [[128.0, 5], [151.0, 6]]:
		var a2: float = _ang(float(pp[0]))
		var y2: float = _row_y(int(pp[1]))
		var r2: float = shaft_radius(y2) - WALL * 0.5
		g.beam(_dir(a2) * r2 + Vector3(0, y2, 0), _dir(a2 + 0.04) * (r2 + 0.22) + Vector3(0, DECK_Y0 - 0.2, 0), 0.2, 0.2, timber,
			K_PLAIN, 0.02)
		g.box(_dir(a2) * r2 + Vector3(0, y2 + 0.05, 0), Vector3(0.34, 0.1, 0.34), Basis(Vector3.UP, -a2), _moss(C_WOOD_OLD, 0.3),
			K_PLANK)
	# Posts standing on the ragged front top up to the deck, with braces: the crown sits on timber there.
	var posts: Array[float] = [64.0, 86.0, 108.0]
	for i: int in posts.size():
		var pa: float = _ang(posts[i])
		var py: float = top_at(posts[i])
		var pr: float = shaft_radius(py) - WALL * 0.5
		g.beam(_dir(pa) * pr + Vector3(0, py, 0), _dir(pa) * pr + Vector3(0, DECK_Y0, 0), 0.22, 0.22, timber, K_PLAIN)
		g.box(_dir(pa) * pr + Vector3(0, py + 0.05, 0), Vector3(0.36, 0.1, 0.36), Basis(Vector3.UP, -pa), _moss(C_WOOD_OLD, 0.3),
			K_PLANK)
		if i + 1 < posts.size():
			var pb: float = _ang(posts[i + 1])
			var qy: float = top_at(posts[i + 1])
			var qr: float = shaft_radius(qy) - WALL * 0.5
			g.beam(_dir(pa) * (pr + 0.06) + Vector3(0, py + 0.1, 0), _dir(pb) * (qr + 0.06) + Vector3(0, DECK_Y0 - 0.25, 0), 0.12, 0.12,
				timber, K_PLAIN)
	var ly: float = 4.3
	var la: Vector3 = _dir(_ang(102.0)) * (shaft_radius(ly) + 0.06) + Vector3(0, ly, 0)
	var lb: Vector3 = _dir(_ang(184.0)) * (shaft_radius(ly) + 0.06) + Vector3(0, ly, 0)
	g.beam(la, lb, 0.22, 0.24, timber, K_PLAIN, 0.12)


## Cloth drape over the rail of one parapet side (crown frame basis `sb`): a hem and three ragged strips hanging below
## the deck. Owner colour (or neutral grey) in the shader; COLOR.rgb is the shade.
static func _drape(g: Geo, sb: Basis, side: int) -> void:
	var z: float = PARAPET + 0.1
	var hem := Color(0.62, 0.62, 0.62, 0.0)
	g.box(sb * Vector3(0, RAIL_TOP + 0.015, PARAPET), Vector3(0.84, 0.05, 0.24), sb, hem, K_CLOTH)
	g.box(sb * Vector3(0, RAIL_TOP - 0.08, z - 0.01), Vector3(0.84, 0.16, 0.04), sb, hem, K_CLOTH)
	var lengths: Array = [[1.35, 1.62, 1.25], [1.52, 1.3, 1.46], [1.28, 1.64, 1.38], [1.5, 1.4, 1.6]][side]
	var shades: Array[float] = [0.9, 1.0, 0.84]
	for i: int in 3:
		var x0: float = -0.4 + float(i) * 0.27
		var x1: float = x0 + 0.25
		var top: float = RAIL_TOP - 0.16
		var bot: float = RAIL_TOP - float(lengths[i])
		var tip: float = bot - 0.16
		var sh: float = shades[i]
		var col := Color(sh, sh, sh, 0.0)
		var zz: float = z + 0.012 * float(i % 2)
		# Pentagon strip (pointed / slanted bottom), both faces.
		var pts := [Vector3(x0, top, zz), Vector3(x1, top, zz), Vector3(x1, bot + (0.08 if i == 1 else 0.0), zz),
			Vector3((x0 + x1) * 0.5 + (0.05 if i == 2 else -0.03), tip, zz), Vector3(x0, bot, zz)]
		for face: int in 2:
			var nn: Vector3 = sb * (Vector3.BACK if face == 0 else Vector3.FORWARD)
			var wp: Array = []
			for p: Vector3 in pts:
				wp.append(sb * p)
			var t := [Vector2(x0, top), Vector2(x1, top), Vector2(x1, bot), Vector2((x0 + x1) * 0.5, tip), Vector2(x0, bot)]
			g.tri(wp[0], wp[1], wp[2], nn, col, t[0], t[1], t[2], K_CLOTH)
			g.tri(wp[0], wp[2], wp[3], nn, col, t[0], t[2], t[3], K_CLOTH)
			g.tri(wp[0], wp[3], wp[4], nn, col, t[0], t[3], t[4], K_CLOTH)


static func _build_roof(g: Geo) -> void:
	g.xf = Transform3D(Basis(Vector3.UP, CROWN_YAW), Vector3.ZERO)
	var e: float = EAVE_HALF
	var a: float = APEX_HALF
	var ye: float = PLATE_Y1
	var ya: float = APEX_Y
	var roof := _moss(C_ROOF, 0.3)
	var under := _moss(C_ROOF_UNDER, 0.0)
	var slope_len: float = Vector2(e - a, ya - ye - ROOF_T).length()
	for side: int in 4:
		var sb := Basis(Vector3.UP, PI * 0.5 * float(side))
		var p := [sb * Vector3(-e, ye + ROOF_T, e), sb * Vector3(e, ye + ROOF_T, e), sb * Vector3(a, ya, a), sb * Vector3(-a, ya, a)]
		var nrm: Vector3 = (p[1] - p[0]).cross(p[3] - p[0]).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		g.quad(p, nrm, roof, [Vector2(-e, 0), Vector2(e, 0), Vector2(a, slope_len), Vector2(-a, slope_len)], K_SHINGLE)
		var q := [sb * Vector3(-e, ye, e), sb * Vector3(e, ye, e), sb * Vector3(a, ya - ROOF_T, a), sb * Vector3(-a, ya - ROOF_T, a)]
		g.quad(q, -nrm, under, [Vector2(-e, 0), Vector2(e, 0), Vector2(a, 1), Vector2(-a, 1)], K_PLANK)
		# Eave edge board.
		var r := [sb * Vector3(-e, ye, e), sb * Vector3(e, ye, e), sb * Vector3(e, ye + ROOF_T, e), sb * Vector3(-e, ye + ROOF_T, e)]
		g.quad(r, sb * Vector3.BACK, _moss(C_TIMBER, 0.0), [Vector2(-e, 0), Vector2(e, 0), Vector2(e, ROOF_T), Vector2(-e, ROOF_T)],
			K_PLAIN)
		# Hip roll along the corner.
		g.beam(sb * Vector3(e + 0.02, ye + ROOF_T + 0.03, e + 0.02), sb * Vector3(a, ya + 0.04, a), 0.15, 0.13, _moss(C_TIMBER, 0.3),
			K_PLAIN, 0.06)
	# Iron cap, finial spike with a knob and a small vane.
	g.box(Vector3(0, ya + 0.06, 0), Vector3(a * 2.0 + 0.16, 0.16, a * 2.0 + 0.16), Basis.IDENTITY, _moss(C_IRON, 0.0), K_IRON)
	g.xf = Transform3D.IDENTITY
	g.prism(Vector3(0, ya + 0.14, 0), 6, 0.07, 0.015, HEIGHT - ya - 0.14, _moss(C_IRON, 0.0), K_IRON, true, false, false)
	g.blob(Vector3(0, ya + 0.42, 0), Vector3(0.1, 0.1, 0.1), 8, 4, _moss(C_IRON, 0.0), K_IRON)
	var vy: float = ya + 0.62
	var vb := Basis(Vector3.UP, deg_to_rad(28.0))
	g.box(Vector3(0, vy, 0) + vb * Vector3(0.05, 0, 0), Vector3(0.62, 0.05, 0.035), vb, _moss(C_IRON, 0.0), K_IRON)
	g.box(Vector3(0, vy + 0.07, 0) + vb * Vector3(-0.2, 0, 0), Vector3(0.22, 0.2, 0.03), vb, _moss(C_IRON, 0.0), K_IRON)
	g.box(Vector3(0, vy, 0) + vb * Vector3(0.38, 0, 0), Vector3(0.14, 0.14, 0.035), vb * Basis(Vector3.BACK, PI * 0.25),
		_moss(C_IRON, 0.0), K_IRON)


# ------------------------------------------------------------------------------------------------ banner pole + cresset

static func _build_pole(g: Geo) -> void:
	var p: Vector3 = POLE
	var timber := _moss(C_TIMBER, 0.1)
	var iron := _moss(C_IRON, 0.0)
	# Stone socket with wedges.
	g.prism(p, 8, 0.34, 0.28, 0.42, _moss(C_STONE_D, 0.9), K_STONE, false, true, false, 0.2)
	for k: int in 3:
		var a: float = TAU * float(k) / 3.0 + 0.5
		g.box(p + _dir(a) * 0.3 + Vector3(0, 0.12, 0), Vector3(0.26, 0.24, 0.2), Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, 0.35),
			_moss(C_STONE_D, 0.8), K_STONE)
	# The pole (tapered), iron bands, a cleat.
	g.prism(p + Vector3(0, 0.3, 0), 8, 0.16, 0.115, POLE_TOP - 0.3, timber, K_PLAIN, true, false, false)
	for y: float in [1.1, 3.6, 6.1]:
		g.prism(p + Vector3(0, y, 0), 8, 0.18 - y * 0.006, 0.18 - y * 0.006, 0.09, iron, K_IRON, true, true, true)
	g.box(p + Vector3(0.17, 1.4, 0), Vector3(0.09, 0.32, 0.07), Basis.IDENTITY, iron, K_IRON)
	# Crossbar to the right (+X) the owner banner hangs from, an iron brace and an end knob.
	g.rod(p + Vector3(0.0, CROSSBAR_Y, 0), p + Vector3(CROSSBAR_LEN, CROSSBAR_Y, 0), 0.06, 6, timber, K_PLAIN)
	g.blob(p + Vector3(CROSSBAR_LEN + 0.05, CROSSBAR_Y, 0), Vector3(0.1, 0.1, 0.1), 6, 4, iron, K_IRON)
	g.rod(p + Vector3(0.08, CROSSBAR_Y - 0.6, 0), p + Vector3(0.7, CROSSBAR_Y - 0.04, 0), 0.03, 5, iron, K_IRON)
	# Cresset: an open iron fire basket on the pole top (bowl, rim, four claws), glowing embers inside.
	var c: Vector3 = p + Vector3(0, CRESSET_Y, 0)
	g.prism(c, 8, 0.15, 0.36, 0.3, iron, K_IRON, true, false, true, 0.3)
	g.prism(c + Vector3(0, -0.1, 0), 8, 0.1, 0.13, 0.1, iron, K_IRON, true, false, true, 0.3)
	for k2: int in 8:
		var a2: float = TAU * (float(k2) + 0.5) / 8.0 + 0.3
		var r: float = 0.37
		g.box(c + _dir(a2) * r + Vector3(0, 0.3, 0), Vector3(2.0 * r * sin(PI / 8.0) + 0.04, 0.06, 0.07),
			Basis(Vector3.UP, -a2 + PI * 0.5), iron, K_IRON)
	for k3: int in 4:
		var a3: float = TAU * float(k3) / 4.0 + 0.3 + PI / 8.0
		g.beam(c + _dir(a3) * 0.34 + Vector3(0, 0.26, 0), c + _dir(a3) * 0.46 + Vector3(0, 0.58, 0), 0.06, 0.06, iron, K_IRON)
	var ember := _moss(C_EMBER, 0.0)
	g.prism(p + Vector3(0, EMBER_Y - 0.04, 0), 8, 0.31, 0.31, 0.04, ember, K_EMBER, false, true, false, 0.3)
	for e: Array in [[0.0, 0.0, 0.13], [0.15, 1.2, 0.1], [0.14, 3.0, 0.11], [0.16, 4.6, 0.09]]:
		var ea: float = float(e[1])
		g.blob(p + _dir(ea) * float(e[0]) + Vector3(0, EMBER_Y + 0.02, 0), Vector3(float(e[2]), float(e[2]) * 0.7, float(e[2])), 6, 3,
			ember, K_EMBER)


# ------------------------------------------------------------------------------------------------ ivy / rubble

static func _build_ivy(g: Geo) -> void:
	# Ivy mats hugging the old stone on the right / back and around the breach (breaks the column outline a little).
	var spots: Array = [[345.0, 0.9, 0.5], [352.0, 1.6, 0.45], [5.0, 2.3, 0.38], [330.0, 1.35, 0.42], [318.0, 0.8, 0.46],
		[205.0, 4.4, 0.36], [212.0, 3.9, 0.4], [197.0, 4.7, 0.3], [262.0, 0.95, 0.44], [255.0, 1.55, 0.36], [22.0, 5.2, 0.34],
		[36.0, 4.75, 0.3]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4417
	for s: Array in spots:
		var a: float = _ang(float(s[0]))
		var y: float = float(s[1])
		var r: float = float(s[2])
		# A clump = three overlapping leafy lumps (a single flat blob reads as a green disc face-on).
		for k: int in 3:
			var col: Color = C_IVY if rng.randf() < 0.6 else C_IVY_D
			var da: float = a + rng.randf_range(-0.16, 0.16) * float(k)
			var dy: float = y + rng.randf_range(-0.3, 0.3) * float(k)
			var rk: float = r * rng.randf_range(0.55, 0.85)
			g.blob(_dir(da) * (shaft_radius(dy) + rk * 0.25) + Vector3(0, dy, 0), Vector3(rk * 1.1, rk * 1.2, rk * 0.75), 5, 3,
				_moss(col, 0.0), K_PLAIN, Basis(Vector3.UP, -da + PI * 0.5))


static func _build_rubble(g: Geo) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91733
	# Under the breach (left), on the steps and the ground; never in the capture ring band (2.7-3.2 m).
	var spots: Array = []
	for i: int in 9:
		spots.append([rng.randf_range(104.0, 180.0), rng.randf_range(1.75, 2.55), rng.randf_range(0.28, 0.62)])
	for i2: int in 3:
		spots.append([rng.randf_range(120.0, 185.0), rng.randf_range(3.35, 3.9), rng.randf_range(0.3, 0.5)])
	for i3: int in 5:
		spots.append([rng.randf_range(235.0, 330.0), rng.randf_range(1.95, 2.5), rng.randf_range(0.25, 0.45)])
	for s: Array in spots:
		var a: float = _ang(float(s[0]))
		var r: float = float(s[1])
		var sz: float = float(s[2])
		var y: float = 0.0
		if r < PLINTH_A1 + 0.1:
			y = PLINTH_Y1
		elif r < PLINTH_A0 + 0.1:
			y = PLINTH_Y0
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.35, 0.35)))
		var size := Vector3(sz * rng.randf_range(1.0, 1.5), sz * rng.randf_range(0.6, 0.9), sz)
		g.box(_dir(a) * r + Vector3(0, y + size.y * 0.3, 0), size, b, _moss(C_STONE.darkened(rng.randf_range(0.0, 0.18)), 0.9),
			K_STONE)
	# A fallen, split plank and a broken beam end under the breach.
	g.box(_dir(_ang(150.0)) * 2.35 + Vector3(0, 0.12, 0), Vector3(1.3, 0.06, 0.26), Basis(Vector3.UP, 0.7) * Basis(Vector3.BACK, 0.18),
		_moss(C_WOOD_OLD, 0.4), K_PLANK)
	g.beam(_dir(_ang(168.0)) * 1.95 + Vector3(0, PLINTH_Y0 + 0.1, 0), _dir(_ang(178.0)) * 2.62 + Vector3(0, 0.1, 0), 0.2, 0.2,
		_moss(C_TIMBER, 0.5), K_PLAIN)


# ================================================================================================ Geo

## Accumulates triangles (flat or smooth normals, sRGB vertex colour + moss in alpha, metre UVs, kind in UV2.x) under
## a current transform `xf`, then commits one indexed surface.
class Geo:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var xf := Transform3D.IDENTITY

	func _vert(p: Vector3, nn: Vector3, col: Color, t: Vector2, kind: int, extra: float = 0.0) -> void:
		v.append(xf * p)
		n.append((xf.basis * nn).normalized())
		c.append(col)
		uv.append(t)
		uv2.append(Vector2(float(kind), extra))

	## Triangle with per-vertex normals; the winding is fixed to Godot's front face (clockwise seen from the front).
	func tri_n(a: Vector3, b: Vector3, cc: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color, ta: Vector2,
			tb: Vector2, tc: Vector2, kind: int) -> void:
		var fn: Vector3 = (b - a).cross(cc - a)
		if fn.dot(na + nb + nc) > 0.0:
			_vert(a, na, col, ta, kind)
			_vert(cc, nc, col, tc, kind)
			_vert(b, nb, col, tb, kind)
		else:
			_vert(a, na, col, ta, kind)
			_vert(b, nb, col, tb, kind)
			_vert(cc, nc, col, tc, kind)

	func tri(a: Vector3, b: Vector3, cc: Vector3, nn: Vector3, col: Color, ta: Vector2, tb: Vector2, tc: Vector2,
			kind: int) -> void:
		tri_n(a, b, cc, nn, nn, nn, col, ta, tb, tc, kind)

	## Quad p[0..3] (in order around the edge), flat normal `nn`.
	func quad(p: Array, nn: Vector3, col: Color, t: Array, kind: int) -> void:
		tri(p[0], p[1], p[2], nn, col, t[0], t[1], t[2], kind)
		tri(p[0], p[2], p[3], nn, col, t[0], t[2], t[3], kind)

	## Quad with per-corner normals (smooth surfaces).
	func quad_n(p: Array, nrm: Array, col: Color, t: Array, kind: int) -> void:
		tri_n(p[0], p[1], p[2], nrm[0], nrm[1], nrm[2], col, t[0], t[1], t[2], kind)
		tri_n(p[0], p[2], p[3], nrm[0], nrm[2], nrm[3], col, t[0], t[2], t[3], kind)

	## Box of `size` centred at `center`, rotated by `b`. UVs in metres on each face (offset by the centre so boxes
	## don't repeat the same pattern).
	func box(center: Vector3, size: Vector3, b: Basis, col: Color, kind: int) -> void:
		var h: Vector3 = size * 0.5
		var o := Vector2(center.x + center.z, center.y)
		for axis: int in 3:
			for sgn: float in [-1.0, 1.0]:
				var nl := Vector3.ZERO
				nl[axis] = sgn
				var ua: int = (axis + 1) % 3
				var va: int = (axis + 2) % 3
				if axis == 0:
					ua = 2
					va = 1
				elif axis == 2:
					ua = 0
					va = 1
				var corners: Array = []
				var uvs: Array = []
				for k: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					var p := Vector3.ZERO
					p[axis] = sgn * h[axis]
					p[ua] = k.x * h[ua]
					p[va] = k.y * h[va]
					corners.append(center + b * p)
					uvs.append(Vector2(p[ua], p[va]) + o)
				quad(corners, b * nl, col, uvs, kind)

	## A beam (box) from `a` to `b`, `w` wide and `h` thick, `extra` longer at both ends.
	func beam(a: Vector3, b: Vector3, w: float, h: float, col: Color, kind: int, extra: float = 0.0) -> void:
		var d: Vector3 = (b - a)
		var len: float = d.length()
		d = d / maxf(len, 0.0001)
		var side: Vector3 = d.cross(Vector3.UP)
		if side.length() < 0.01:
			side = d.cross(Vector3.RIGHT)
		side = side.normalized()
		var up: Vector3 = side.cross(d).normalized()
		box((a + b) * 0.5, Vector3(len + extra * 2.0, h, w), Basis(d, up, side), col, kind)

	## An n-sided prism / cylinder from `base` up `h` (radii r0 at the bottom, r1 at the top), optional caps.
	## `rot` turns the first vertex; `smooth` = radial normals (else flat faces). Side UV: u = arc (m), v = height.
	func prism(base: Vector3, segs: int, r0: float, r1: float, h: float, col: Color, kind: int, smooth: bool,
			cap_top: bool, cap_bot: bool, rot: float = 0.0, b: Basis = Basis.IDENTITY) -> void:
		var slope: float = (r0 - r1) / maxf(h, 0.0001)
		var rm: float = (r0 + r1) * 0.5
		for i: int in segs:
			var a0: float = rot + TAU * float(i) / float(segs)
			var a1: float = rot + TAU * float(i + 1) / float(segs)
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var p := [base + b * (d0 * r0), base + b * (d1 * r0), base + b * (d1 * r1 + Vector3(0, h, 0)),
				base + b * (d0 * r1 + Vector3(0, h, 0))]
			var t := [Vector2(a0 * rm, base.y), Vector2(a1 * rm, base.y), Vector2(a1 * rm, base.y + h), Vector2(a0 * rm, base.y + h)]
			if smooth:
				var n0: Vector3 = b * (d0 + Vector3(0, slope, 0)).normalized()
				var n1: Vector3 = b * (d1 + Vector3(0, slope, 0)).normalized()
				quad_n(p, [n0, n1, n1, n0], col, t, kind)
			else:
				var dm: Vector3 = (d0 + d1).normalized()
				quad(p, b * (dm + Vector3(0, slope, 0)).normalized(), col, t, kind)
			if cap_top and r1 > 0.0:
				var ct: Vector3 = base + b * Vector3(0, h, 0)
				tri(ct, p[2], p[3], b * Vector3.UP, col, Vector2(base.x, base.z), Vector2(p[2].x, p[2].z), Vector2(p[3].x, p[3].z), kind)
			if cap_bot and r0 > 0.0:
				tri(base, p[0], p[1], b * Vector3.DOWN, col, Vector2(base.x, base.z), Vector2(p[0].x, p[0].z), Vector2(p[1].x, p[1].z), kind)

	## A round rod from `a` to `b`.
	func rod(a: Vector3, b: Vector3, r: float, segs: int, col: Color, kind: int) -> void:
		var d: Vector3 = b - a
		var bs := Basis(Quaternion(Vector3.UP, d.normalized()))
		prism(a, segs, r, r, d.length(), col, kind, true, true, true, 0.0, bs)

	## A low-poly ellipsoid (smooth normals) with radii `r`, optionally turned by `b`.
	func blob(center: Vector3, r: Vector3, segs: int, rings: int, col: Color, kind: int, b: Basis = Basis.IDENTITY) -> void:
		var pts: Array = []
		var nrm: Array = []
		for j: int in rings + 1:
			var phi: float = PI * float(j) / float(rings)
			var row_p: Array = []
			var row_n: Array = []
			for i: int in segs + 1:
				var th: float = TAU * float(i) / float(segs)
				var s := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
				row_p.append(center + b * (s * r))
				row_n.append(b * Vector3(s.x / r.x, s.y / r.y, s.z / r.z).normalized())
			pts.append(row_p)
			nrm.append(row_n)
		for j2: int in rings:
			for i2: int in segs:
				var p := [pts[j2][i2], pts[j2][i2 + 1], pts[j2 + 1][i2 + 1], pts[j2 + 1][i2]]
				var nn := [nrm[j2][i2], nrm[j2][i2 + 1], nrm[j2 + 1][i2 + 1], nrm[j2 + 1][i2]]
				var t := [Vector2(i2 * 0.2, j2 * 0.2), Vector2((i2 + 1) * 0.2, j2 * 0.2), Vector2((i2 + 1) * 0.2, (j2 + 1) * 0.2),
					Vector2(i2 * 0.2, (j2 + 1) * 0.2)]
				if j2 == 0:
					tri_n(p[0], p[2], p[3], nn[0], nn[2], nn[3], col, t[0], t[2], t[3], kind)
				elif j2 == rings - 1:
					tri_n(p[0], p[1], p[2], nn[0], nn[1], nn[2], col, t[0], t[1], t[2], kind)
				else:
					quad_n(p, nn, col, t, kind)

	## A camera-facing quad for the flame shader: every vertex sits at `center`; UV2 = corner offset (m) from it,
	## UV = 0..1 (y up), COLOR.r = phase, COLOR.g = 1 for a halo. `base_off` = how far below `center` the quad starts
	## (a flame's base sits on the embers).
	func billboard(center: Vector3, size: Vector2, phase: float, halo: bool, base_off: float) -> void:
		var col := Color(phase, 1.0 if halo else 0.0, 0.0, 1.0)
		var y0: float = -base_off if not halo else -size.y * 0.5
		var corners: Array[Vector2] = [Vector2(-size.x * 0.5, y0), Vector2(size.x * 0.5, y0), Vector2(size.x * 0.5, y0 + size.y),
			Vector2(-size.x * 0.5, y0 + size.y)]
		var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			v.append(center)
			n.append(Vector3.BACK)
			c.append(col)
			uv.append(uvs[k])
			uv2.append(corners[k])

	func commit() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in v.size():
			st.set_color(c[i])
			st.set_normal(n[i])
			st.set_uv(uv[i])
			st.set_uv2(uv2[i])
			st.add_vertex(v[i])
		st.index()
		return st.commit()
