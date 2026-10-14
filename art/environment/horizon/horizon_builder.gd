extends SceneTree
## Task MAP.P3 (map polish, the horizon): bakes art/environment/horizon/horizon.tscn, the land the game camera sees
## beyond the Crown Hollow cliffs at zoom 40-55 and at the map edges, so the map sits in a world instead of ending
## at a flat painted wall:
##   - rolling forested uplands: a hill ground ring (15-110 m outside the 120 x 120 map) that rises from under the
##     map_dressing plateau, higher behind the tall north / west cliffs, low behind the south bank;
##   - a dense far canopy on it: ~3000 low-poly crowns (7-sided domes, 2-tier star conifers), clumped by kind
##     (fir stands, oak woods, a few autumn-gold and birch groves), bigger and sparser further out;
##   - a few silhouettes on the skyline: a broken watchtower (NE), a toppled shrine (NW), a broken aqueduct (W),
##     a standing-stone ring (W), a pond in a glade (E), granite crags (N, E, W, S);
##   - aerial perspective baked into the vertex colours: cooler, paler, less saturated with the distance (the
##     world_env depth fog, 55-190 m, adds the rest).
## Cheap: 8 merged meshes (one per compass sector, so frustum culling drops the ones behind the camera), ONE
## material (horizon_mat.tres, horizon.gdshader), no shadows cast, no lights, no colliders, no runtime materials.
## The camera never sees the sky (pitch 55, fov 50: the top ray is 30 deg below the horizon, the screen corners
## >= 20 deg even at 21:9), so the "backdrop band" is this far land + haze.
## Reads art/environment/meshes/map_plateau.res (12.V5) for the plateau height: re-run after the map edge changes.
## Run headless:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://art/environment/horizon/horizon_builder.gd
##       --quit-after 3000

const DIR := "res://art/environment/horizon/"
const MESH_DIR := "res://art/environment/horizon/meshes/"
const PLATEAU_MESH := "res://art/environment/meshes/map_plateau.res"
const NOISE_TEX := "res://art/shaders/paint_noise.tres"
const MAP_HALF := 60.0
const SECTOR_NAMES: Array[String] = ["North", "NorthEast", "East", "SouthEast", "South", "SouthWest", "West",
	"NorthWest"]
const GROUND_ROWS: Array[float] = [15.0, 18.5, 22.0, 25.5, 29.0, 32.5, 36.0, 40.0, 44.0, 48.5, 53.0, 58.0, 63.5,
	69.5, 76.0, 83.0, 91.0, 100.0, 110.0]
const CROWN_MAX_D := 78.0
const GRID_HALF := 180.0
const GRID_RES := 1.0
## 12.V5's river mouths (build_env.gd constants, read from the script with these fallbacks): the north stream runs
## out of the forest down a valley to the notch at x NOTCH_X; the south gorge is a hole in the plateau (found by
## the rasteriser). No crowns on the stream, no ground over the gorge.
const MOUTH_DEFAULTS := {"NOTCH_X": -15.1, "NOTCH_RECESS": 2.4, "STREAM_END": 20.0}
const DOME_FACET := 0.8    ## UV.x: how much the shader flat-shades a face (crowns read as painted facets like the
const CONE_FACET := 0.55   ## border trees; the ground stays smooth)

# Palette (sRGB, the shader linearises). Crowns follow build_env.gd's tree colours, darker with the distance.
const HAZE := Color(0.30, 0.40, 0.46)
const FLOOR := Color(0.09, 0.16, 0.11)
const FLOOR_L := Color(0.15, 0.24, 0.13)
const MEADOW := Color(0.34, 0.43, 0.19)
const MEADOW_DRY := Color(0.47, 0.45, 0.26)
const BANK := Color(0.45, 0.42, 0.30)
const WATER := Color(0.13, 0.33, 0.38)
const WATER_L := Color(0.22, 0.47, 0.50)
const ROCK := Color(0.44, 0.42, 0.40)
const ROCK_L := Color(0.55, 0.52, 0.47)
const ROCK_D := Color(0.30, 0.29, 0.30)
const ROCK_B := Color(0.39, 0.40, 0.45)
const MOSS := Color(0.26, 0.40, 0.17)
const RUIN := Color(0.44, 0.44, 0.41)
const RUIN_L := Color(0.52, 0.51, 0.47)
const RUIN_D := Color(0.33, 0.31, 0.30)
const IVY := Color(0.17, 0.33, 0.14)
const PINE := Color(0.12, 0.28, 0.16)
const PINE_L := Color(0.22, 0.42, 0.21)
const FIR := Color(0.09, 0.25, 0.23)
const FIR_L := Color(0.17, 0.39, 0.31)
const OAK_D := Color(0.15, 0.28, 0.11)
const OAK := Color(0.25, 0.41, 0.15)
const OAK_L := Color(0.42, 0.57, 0.21)
const BIRCH := Color(0.42, 0.55, 0.20)
const BIRCH_L := Color(0.63, 0.74, 0.30)
const GOLD_D := Color(0.55, 0.26, 0.09)
const GOLD := Color(0.78, 0.48, 0.14)
const GOLD_L := Color(0.93, 0.70, 0.26)


class Chunk:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var f := PackedFloat32Array()   # facet amount per vertex (UV.x)
	var idx := PackedInt32Array()
	var map: Dictionary = {}   # ground grid: global vertex id -> local index


var _chunks: Array[Chunk] = []
var _conv := 1.0
var _grid := PackedFloat32Array()   # plateau height grid (GRID_RES m cells over +-GRID_HALF), NAN = no plateau
var _gn := 0
var _noise := FastNoiseLite.new()
var _noise_kind := FastNoiseLite.new()
var _knolls: Array = []         # [Vector2 centre, radius, height]
var _pads: Array = []           # [Vector2 centre, radius, y]: flattened yards (tower, shrine, stone ring, pond hollow)
var _clearings: Array = []      # [Vector2 centre, radius, Color floor]
var _corridors: Array = []      # [Vector2 a, Vector2 b, half width]: no crowns (the aqueduct line)
var _counts: Dictionary = {}
var _pond_y := 0.0


func _init() -> void:
	_detect_winding()
	for i: int in 8:
		_chunks.append(Chunk.new())
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.seed = 71
	_noise.frequency = 0.021
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise_kind.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_kind.seed = 5
	_noise_kind.frequency = 0.035
	_noise_kind.fractal_type = FastNoiseLite.FRACTAL_NONE
	_load_plateau()
	_plan_sites()
	_build_ground()
	_build_landmarks()
	_build_crowns()
	_save_all()
	quit()


# --- helpers ------------------------------------------------------------------------------------------------------

func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _h(a: float, b: float, c: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453, 1.0)


## Sector 0-7 (N, NE, E, SE, S, SW, W, NW) of a world x/z point.
func _sector(p: Vector2) -> int:
	return posmod(int(round(atan2(p.x, -p.y) / (TAU / 8.0))), 8)


## Distance outside the map square and the outward direction: Vector3(d, nx, nz).
func _out(p: Vector2) -> Vector3:
	var q: Vector2 = p.clamp(Vector2(-MAP_HALF, -MAP_HALF), Vector2(MAP_HALF, MAP_HALF))
	var off: Vector2 = p - q
	var d: float = off.length()
	var n: Vector2 = off / d if d > 0.001 else Vector2(0.0, -1.0)
	return Vector3(d, n.x, n.y)


## Aerial perspective: cooler, paler, a little less saturated with the distance outside the map.
func _haze(col: Color, d: float) -> Color:
	var t: float = smoothstep(18.0, 90.0, d)
	var l: float = col.get_luminance()
	var c: Color = col.lerp(Color(l, l, l), t * 0.3)
	c = c.lerp(HAZE, t * 0.45)
	return Color(c.r, c.g, c.b, col.a)


func _ca(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)


## Appends triangle (a, b, c) of chunk ch, front face along `out`.
func _tri(ch: Chunk, a: int, b: int, c: int, out: Vector3) -> void:
	var fn: Vector3 = (ch.v[b] - ch.v[a]).cross(ch.v[c] - ch.v[a])
	var s: float = 1.0 if fn.dot(out) >= 0.0 else -1.0
	if s != _conv:
		ch.idx.append_array([a, c, b])
	else:
		ch.idx.append_array([a, b, c])


## Flat-shaded triangles (every face its own 3 vertices) for the faceted rocks / ruins. `hints[t]` is the outward
## direction of triangle t, or ZERO = away from `centre`. Faces turned to the sky take `top` (alpha = amount);
## alpha of the vertex colour = height gradient between y0 and y1 (fake AO).
func _flat(ch: Chunk, verts: PackedVector3Array, tris: PackedInt32Array, centre: Vector3, col: Color, top: Color,
		y0: float, y1: float, seed: float, hints: PackedVector3Array = PackedVector3Array(), ivy: float = 0.0) -> void:
	for t: int in range(0, tris.size(), 3):
		var a: Vector3 = verts[tris[t]]
		var b: Vector3 = verts[tris[t + 1]]
		var c: Vector3 = verts[tris[t + 2]]
		var fn: Vector3 = (b - a).cross(c - a)
		if fn.length_squared() < 1e-10:
			continue
		fn = fn.normalized()
		var mid: Vector3 = (a + b + c) / 3.0
		var hint: Vector3 = hints[t / 3] if hints.size() > t / 3 and hints[t / 3] != Vector3.ZERO else mid - centre
		if fn.dot(hint) < 0.0:
			fn = -fn
		var hv: float = _h(mid.x * 0.37 + seed, mid.y * 0.51, mid.z * 0.29)
		var fc: Color = col * (0.9 + hv * 0.2)
		if top.a > 0.0 and fn.y > 0.55:
			fc = fc.lerp(Color(top.r, top.g, top.b), top.a * smoothstep(0.55, 0.9, fn.y))
		elif ivy > 0.0 and fn.y < 0.4 and hv < ivy:
			fc = fc.lerp(IVY, 0.75)
		var d: float = _out(Vector2(mid.x, mid.z)).x
		fc = _haze(fc, d)
		var base: int = ch.v.size()
		for p: Vector3 in [a, b, c]:
			ch.v.append(p)
			ch.n.append(fn)
			ch.c.append(_ca(fc, lerpf(0.45, 1.0, clampf((p.y - y0) / maxf(y1 - y0, 0.01), 0.0, 1.0))))
			ch.f.append(1.0)
		_tri(ch, base, base + 1, base + 2, fn)


## A box (any transform) as flat faces.
func _box(p: Vector3, size: Vector3, basis: Basis, col: Color, top: Color, seed: float, ivy: float = 0.0) -> void:
	var ch: Chunk = _chunks[_sector(Vector2(p.x, p.z))]
	var v := PackedVector3Array()
	for i: int in 8:
		var s := Vector3(1.0 if (i & 1) != 0 else -1.0, 1.0 if (i & 2) != 0 else -1.0, 1.0 if (i & 4) != 0 else -1.0)
		v.append(p + basis * (s * size * 0.5))
	var tris := PackedInt32Array([0, 1, 3, 0, 3, 2, 4, 5, 7, 4, 7, 6, 0, 1, 5, 0, 5, 4, 2, 3, 7, 2, 7, 6,
		0, 2, 6, 0, 6, 4, 1, 3, 7, 1, 7, 5])
	var ys: Array[float] = []
	for q: Vector3 in v:
		ys.append(q.y)
	_flat(ch, v, tris, p, col, top, ys.min(), ys.max(), seed, PackedVector3Array(), ivy)


## A jagged prism: `segs` sides, radius r0 at the bottom -> r1 at the top, height h, top rim heights jittered by
## `jag`; `sunk` > 0 gives a sunken broken top (ruins), else a flat-ish cap. Tilted by `basis`.
func _prism(bottom: Vector3, segs: int, r0: float, r1: float, h: float, jag: float, sunk: float, basis: Basis,
		col: Color, top: Color, seed: float, ivy: float = 0.0, cap_col: Color = Color(0, 0, 0, 0)) -> void:
	var ch: Chunk = _chunks[_sector(Vector2(bottom.x, bottom.z))]
	var v := PackedVector3Array()
	var rot: float = _h(seed, 1.0, 2.0) * TAU
	for k: int in segs:
		var a: float = rot + k * TAU / segs
		var jr: float = 0.85 + 0.3 * _h(seed, k, 3.0)
		v.append(bottom + basis * Vector3(cos(a) * r0 * jr, 0.0, sin(a) * r0 * jr))
	for k: int in segs:
		var a: float = rot + k * TAU / segs + (_h(seed, k, 4.0) - 0.5) * 0.3
		var jr: float = 0.8 + 0.4 * _h(seed, k, 5.0)
		var y: float = h - jag * _h(seed, k, 6.0)
		v.append(bottom + basis * Vector3(cos(a) * r1 * jr, y, sin(a) * r1 * jr))
	v.append(bottom + basis * Vector3(0.0, h - jag * 0.5 - sunk, 0.0))
	var tris := PackedInt32Array()
	var hints := PackedVector3Array()
	var centre: Vector3 = bottom + basis * Vector3(0.0, h * 0.4, 0.0)
	var up: Vector3 = basis * Vector3.UP
	for k: int in segs:
		var k1: int = (k + 1) % segs
		tris.append_array([k, k1, segs + k, k1, segs + k1, segs + k])
		hints.append(Vector3.ZERO)
		hints.append(Vector3.ZERO)
	var side_tris: int = tris.size()
	for k: int in segs:
		var k1: int = (k + 1) % segs
		tris.append_array([segs + k, segs + k1, segs * 2])
		hints.append(up)
	var ys: Array[float] = []
	for q: Vector3 in v:
		ys.append(q.y)
	_flat(ch, v, tris.slice(0, side_tris), centre, col, top, ys.min(), ys.max(), seed, hints.slice(0, side_tris / 3),
		ivy)
	var cc: Color = cap_col if cap_col.a > 0.0 else col
	_flat(ch, v, tris.slice(side_tris), centre, cc, top, ys.min(), ys.max(), seed + 7.0,
		hints.slice(side_tris / 3))


# --- the plateau (12.V5's map_plateau.res) and the hill terrain ---------------------------------------------------

## Rasterises the plateau mesh (the open ring with the river mouths: the north stream's valley and the south gorge
## hole) into a 1 m height grid; cells no triangle covers stay NAN (the gorge hole, and the map itself).
func _load_plateau() -> void:
	var mesh := load(PLATEAU_MESH) as ArrayMesh
	var arr: Array = mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	_gn = int(GRID_HALF * 2.0 / GRID_RES) + 1
	_grid.resize(_gn * _gn)
	_grid.fill(NAN)
	for t: int in range(0, idx.size(), 3):
		var a: Vector3 = v[idx[t]]
		var b: Vector3 = v[idx[t + 1]]
		var c: Vector3 = v[idx[t + 2]]
		var x0: int = maxi(int(floor((minf(a.x, minf(b.x, c.x)) + GRID_HALF) / GRID_RES)), 0)
		var x1: int = mini(int(ceil((maxf(a.x, maxf(b.x, c.x)) + GRID_HALF) / GRID_RES)), _gn - 1)
		var z0: int = maxi(int(floor((minf(a.z, minf(b.z, c.z)) + GRID_HALF) / GRID_RES)), 0)
		var z1: int = mini(int(ceil((maxf(a.z, maxf(b.z, c.z)) + GRID_HALF) / GRID_RES)), _gn - 1)
		var e0 := Vector2(b.x - a.x, b.z - a.z)
		var e1 := Vector2(c.x - a.x, c.z - a.z)
		var den: float = e0.x * e1.y - e1.x * e0.y
		if absf(den) < 1e-8:
			continue
		for gz: int in range(z0, z1 + 1):
			for gx: int in range(x0, x1 + 1):
				var p := Vector2(gx * GRID_RES - GRID_HALF - a.x, gz * GRID_RES - GRID_HALF - a.z)
				var s: float = (p.x * e1.y - e1.x * p.y) / den
				var u: float = (e0.x * p.y - p.x * e0.y) / den
				if s >= -0.002 and u >= -0.002 and s + u <= 1.002:
					_grid[gz * _gn + gx] = a.y + (b.y - a.y) * s + (c.y - a.y) * u
	var holes: int = 0
	for gz: int in _gn:
		for gx: int in _gn:
			var q := Vector2(gx * GRID_RES - GRID_HALF, gz * GRID_RES - GRID_HALF)
			var d: float = _out(q).x
			if d > 4.0 and d < 30.0 and is_nan(_grid[gz * _gn + gx]):
				holes += 1
	print("plateau: %d tris rasterised, %d hole cells near the edge, north y %.2f" % [idx.size() / 3, holes,
		_plateau_y(Vector2(0.0, -80.0))])


func _cell(gx: int, gz: int) -> float:
	if gx < 0 or gz < 0 or gx >= _gn or gz >= _gn:
		return NAN
	return _grid[gz * _gn + gx]


## True where the plateau is cut open (the south gorge) within 30 m of the map.
func _is_hole(p: Vector2) -> bool:
	var d: float = _out(p).x
	if d < 3.5 or d > 30.0:
		return false
	return is_nan(_cell(roundi((p.x + GRID_HALF) / GRID_RES), roundi((p.y + GRID_HALF) / GRID_RES)))


## Plateau height at p (bilinear); next to a hole, the nearest covered cells.
func _plateau_y(p: Vector2) -> float:
	var fx: float = (p.x + GRID_HALF) / GRID_RES
	var fz: float = (p.y + GRID_HALF) / GRID_RES
	var gx: int = int(floor(fx))
	var gz: int = int(floor(fz))
	var tx: float = fx - gx
	var tz: float = fz - gz
	var c00: float = _cell(gx, gz)
	var c10: float = _cell(gx + 1, gz)
	var c01: float = _cell(gx, gz + 1)
	var c11: float = _cell(gx + 1, gz + 1)
	if not (is_nan(c00) or is_nan(c10) or is_nan(c01) or is_nan(c11)):
		return lerpf(lerpf(c00, c10, tx), lerpf(c01, c11, tx), tz)
	for r: int in range(1, 12):
		var sum: float = 0.0
		var cnt: int = 0
		for dz: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var c: float = _cell(gx + dx, gz + dz)
				if not is_nan(c):
					sum += c
					cnt += 1
		if cnt > 0:
			return sum / cnt
	return 0.0


## Hill amplitude by facing: uplands behind the tall north / west cliffs, lowlands behind the low south bank.
func _amp(n: Vector2) -> float:
	var w: float = maxf(-n.y, 0.0) * 1.0 + maxf(n.y, 0.0) * 0.4 + maxf(-n.x, 0.0) * 0.9 + maxf(n.x, 0.0) * 0.7
	return w / (absf(n.x) + absf(n.y))


## Height of the far land: the plateau (embedded 0.45 m under it near the band so it never z-fights), then
## rolling hills, the landmark knolls and the flattened yards.
func _ground_y(p: Vector2) -> float:
	var o: Vector3 = _out(p)
	var d: float = o.x
	var n := Vector2(o.y, o.z)
	var amp: float = _amp(n)
	var start: float = lerpf(24.0, 34.0, maxf(n.y, 0.0))
	var ramp: float = smoothstep(start, start + 30.0, d)
	var nv: float = _noise.get_noise_2dv(p) * 0.5 + 0.5
	var b: float = amp * (ramp * (1.0 + 5.5 * nv * nv) + smoothstep(50.0, 110.0, d) * 4.0)
	for k: Array in _knolls:
		var dist: float = p.distance_to(k[0])
		b += float(k[2]) * (1.0 - smoothstep(float(k[1]) * 0.3, float(k[1]), dist)) * smoothstep(22.0, 30.0, d)
	var y: float = _plateau_y(p) + b - 0.45 * (1.0 - smoothstep(26.0, 40.0, d))
	for pad: Array in _pads:
		var dist2: float = p.distance_to(pad[0])
		y = lerpf(y, float(pad[2]), (1.0 - smoothstep(float(pad[1]) * 0.5, float(pad[1]), dist2)) * smoothstep(23.0, 28.0, d))
	return y


## True when a crown at p (radius r) would stand in a clearing, a yard or on the aqueduct line.
func _cleared(p: Vector2, r: float) -> bool:
	for off: Vector2 in [Vector2.ZERO, Vector2(r, 0.0), Vector2(-r, 0.0), Vector2(0.0, r), Vector2(0.0, -r)]:
		if _is_hole(p + off):
			return true
	for c: Array in _clearings:
		var wob: float = (_noise_kind.get_noise_2dv(p * 3.0)) * 1.5
		if p.distance_to(c[0]) < float(c[1]) * 0.9 + r * 0.3 + wob:
			return true
	for cor: Array in _corridors:
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, cor[0], cor[1])
		if p.distance_to(q) < float(cor[2]) + r * 0.4:
			return true
	return false


# --- sites ---------------------------------------------------------------------------------------------------------

## Landmark positions. Where the game camera (pitch 55) sees the far land: past the north cliffs only ~20 m at zoom 55
## (the band forest); past the east / west cliffs 10-60 m, seen from the side; at the corners the top of the screen
## reaches 40-60 m out. Past the south bank, z 60-81 is at the bottom of the screen right under the camera (seen big,
## close), z > 81 only when the camera is turned round: so landmarks sit east / west / north corners, 25-45 m out.
const TOWER := Vector2(86.0, -76.0)       # NE: broken watchtower on a knoll
const SHRINE := Vector2(-84.0, -80.0)     # NW: toppled shrine columns on a knoll
const AQ_A := Vector2(-82.0, -24.0)       # W: aqueduct, from near the cliff out west
const AQ_B := Vector2(-124.0, -31.0)
const STONES := Vector2(-90.0, 40.0)      # W: standing-stone ring in a meadow
const POND := Vector2(93.0, -32.0)        # E: pond in a glade
const CRAGS: Array[Vector2] = [Vector2(24.0, -86.0), Vector2(104.0, 58.0), Vector2(-100.0, -58.0), Vector2(-34.0, 100.0),
	Vector2(-30.0, -92.0), Vector2(42.0, 104.0)]


func _plan_sites() -> void:
	_knolls.append([TOWER, 16.0, 4.0])
	_knolls.append([SHRINE, 15.0, 3.0])
	_knolls.append([STONES, 16.0, 1.5])
	for i: int in CRAGS.size():
		_knolls.append([CRAGS[i], 11.0, 2.5 + _h(i, 2.0, 9.0) * 1.5])
	# Yards: flat, at the height the hills give their centre.
	_pads.append([TOWER, 8.0, _ground_y(TOWER) + 0.3])
	_pads.append([SHRINE, 8.0, _ground_y(SHRINE)])
	_pads.append([STONES, 12.0, _ground_y(STONES)])
	# A flat terrace just above the map_dressing plateau (a hollow would sink under the plateau and vanish).
	_pond_y = maxf(_ground_y(POND), _plateau_y(POND) + 0.6)
	_pads.append([POND, 11.0, _pond_y])
	_clearings.append([TOWER, 8.0, MEADOW_DRY])
	_clearings.append([SHRINE, 7.5, MEADOW])
	_clearings.append([STONES, 11.5, MEADOW])
	_clearings.append([POND, 9.5, BANK])
	# Glades: break the carpet (and let the hill ground show its shape).
	_clearings.append([Vector2(94.0, 18.0), 5.5, MEADOW])
	_clearings.append([Vector2(-104.0, 76.0), 6.5, MEADOW])
	_clearings.append([Vector2(100.0, -58.0), 6.0, MEADOW])
	_clearings.append([Vector2(10.0, 100.0), 7.0, MEADOW])
	_clearings.append([Vector2(-58.0, -100.0), 6.0, MEADOW_DRY])
	_corridors.append([AQ_A, AQ_B, 3.4])
	# The north stream (12.V5): keep its valley open from the notch back to where it leaves the forest.
	var consts: Dictionary = MOUTH_DEFAULTS.duplicate()
	var env_script := load("res://art/environment/build_env.gd") as GDScript
	if env_script:
		var cm: Dictionary = env_script.get_script_constant_map()
		for k: String in consts:
			if cm.has(k):
				consts[k] = float(cm[k])
	var sx: float = consts["NOTCH_X"]
	var s_end: float = -MAP_HALF - float(consts["NOTCH_RECESS"]) - float(consts["STREAM_END"]) + 1.5
	_corridors.append([Vector2(sx, -MAP_HALF), Vector2(sx, s_end), 2.9])
	print("stream corridor x %.2f to z %.1f" % [sx, s_end])


# --- ground ring ---------------------------------------------------------------------------------------------------

## Perimeter samples of the map square, N -> E -> S -> W with quarter-circle fans at the corners: [base, normal].
func _perimeter(step: float, arc_steps: int) -> Array:
	var out: Array = []
	var h: float = MAP_HALF
	var sides: Array = [
		[Vector2(-h, -h), Vector2(1, 0), Vector2(0, -1)],
		[Vector2(h, -h), Vector2(0, 1), Vector2(1, 0)],
		[Vector2(h, h), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(-h, h), Vector2(0, -1), Vector2(-1, 0)],
	]
	for k: int in 4:
		var start: Vector2 = sides[k][0]
		var t: Vector2 = sides[k][1]
		var nrm: Vector2 = sides[k][2]
		var cnt: int = int(round(2.0 * h / step))
		for i: int in cnt:
			out.append([start + t * (i * 2.0 * h / cnt), nrm])
		var corner: Vector2 = start + t * 2.0 * h
		var nrm2: Vector2 = sides[(k + 1) % 4][2]
		for j: int in arc_steps:
			var a: float = float(j) / arc_steps * PI * 0.5
			out.append([corner, (nrm * cos(a) + nrm2 * sin(a)).normalized()])
	return out


func _floor_color(p: Vector2, d: float, nrm: Vector3) -> Color:
	var nv: float = _noise_kind.get_noise_2dv(p * 2.3) * 0.5 + 0.5
	var col: Color = FLOOR.lerp(FLOOR_L, nv * 0.6)
	var a: float = 0.55
	for c: Array in _clearings:
		var dist: float = p.distance_to(c[0])
		var t: float = 1.0 - smoothstep(float(c[1]) * 0.75, float(c[1]) * 1.2, dist + (nv - 0.5) * 3.0)
		if t > 0.0:
			# Glades a notch darker with the distance, like the canopy (bright bare patches pull the eye).
			var cc: Color = (c[2] as Color).lerp(MEADOW, 0.35 * nv) * lerpf(0.92, 0.72, smoothstep(15.0, 60.0, d))
			col = col.lerp(cc, t)
			a = lerpf(a, 1.0, t)
	# Bare rock on the steep knoll flanks and round the crags.
	var steep: float = smoothstep(0.86, 0.7, nrm.y)
	if steep > 0.0:
		col = col.lerp(ROCK.lerp(ROCK_D, nv), steep * 0.8)
		a = lerpf(a, 0.85, steep)
	return _haze(_ca(col, a), d)


func _build_ground() -> void:
	var cols: Array = _perimeter(3.0, 12)
	var m: int = cols.size()
	var nr: int = GROUND_ROWS.size()
	var pos := PackedVector3Array()
	pos.resize(m * nr)
	for i: int in m:
		var base: Vector2 = cols[i][0]
		var n: Vector2 = cols[i][1]
		var t := Vector2(-n.y, n.x)
		for r: int in nr:
			var jt: float = (_h(i, r, 1.0) - 0.5) * 1.2 if r > 0 else 0.0
			var jd: float = (_h(i, r, 2.0) - 0.5) * 1.4 if r > 0 and r < nr - 1 else 0.0
			var p: Vector2 = base + n * (GROUND_ROWS[r] + jd) + t * jt
			pos[i * nr + r] = Vector3(p.x, _ground_y(p), p.y)
	# Smooth normals (face-area weighted, the faces all point up).
	var nrm := PackedVector3Array()
	nrm.resize(m * nr)
	for i: int in m:
		var j: int = (i + 1) % m
		for r: int in nr - 1:
			var q: Array[int] = [i * nr + r, j * nr + r, i * nr + r + 1, j * nr + r + 1]
			for tri: Array in [[q[0], q[1], q[2]], [q[1], q[3], q[2]]]:
				var fn: Vector3 = (pos[tri[1]] - pos[tri[0]]).cross(pos[tri[2]] - pos[tri[0]])
				if fn.y < 0.0:
					fn = -fn
				for vi: int in tri:
					nrm[vi] += fn
	var cols_c := PackedColorArray()
	cols_c.resize(m * nr)
	for vi: int in m * nr:
		nrm[vi] = nrm[vi].normalized() if nrm[vi].length_squared() > 0.0 else Vector3.UP
		var p2 := Vector2(pos[vi].x, pos[vi].z)
		cols_c[vi] = _floor_color(p2, _out(p2).x, nrm[vi])
	var tris: int = 0
	for i: int in m:
		var j: int = (i + 1) % m
		for r: int in nr - 1:
			var q: Array[int] = [i * nr + r, j * nr + r, i * nr + r + 1, j * nr + r + 1]
			var mid: Vector3 = (pos[q[0]] + pos[q[3]]) * 0.5
			# No ground over the gorge hole (it would lid the river's way out).
			var over_hole: bool = false
			for s: Vector3 in [pos[q[0]], pos[q[1]], pos[q[2]], pos[q[3]], mid, (pos[q[0]] + pos[q[1]]) * 0.5,
					(pos[q[2]] + pos[q[3]]) * 0.5, (pos[q[0]] + pos[q[2]]) * 0.5, (pos[q[1]] + pos[q[3]]) * 0.5]:
				if _is_hole(Vector2(s.x, s.z)):
					over_hole = true
					break
			if over_hole:
				continue
			var ch: Chunk = _chunks[_sector(Vector2(mid.x, mid.z))]
			var li: Array[int] = []
			for vi: int in q:
				if not ch.map.has(vi):
					ch.map[vi] = ch.v.size()
					ch.v.append(pos[vi])
					ch.n.append(nrm[vi])
					ch.c.append(cols_c[vi])
					ch.f.append(0.0)
				li.append(ch.map[vi])
			_tri(ch, li[0], li[1], li[2], Vector3.UP)
			_tri(ch, li[1], li[3], li[2], Vector3.UP)
			tris += 2
	_counts["ground tris"] = tris


# --- canopy --------------------------------------------------------------------------------------------------------

## Point on the map square offset by d (rounded corners), at arc length t: [position, outward normal].
func _offset_point(t: float, d: float) -> Array:
	var h: float = MAP_HALF
	var arc: float = PI * 0.5 * d
	var seg: float = 2.0 * h + arc
	t = fposmod(t, 4.0 * seg)
	var k: int = mini(int(t / seg), 3)
	var u: float = t - k * seg
	var starts: Array[Vector2] = [Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]
	var dirs: Array[Vector2] = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	var nrms: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	var base: Vector2
	var n: Vector2
	if u < 2.0 * h:
		base = starts[k] + dirs[k] * u
		n = nrms[k]
	else:
		var a: float = (u - 2.0 * h) / maxf(arc, 0.001) * PI * 0.5
		base = starts[k] + dirs[k] * 2.0 * h
		n = (nrms[k] * cos(a) + nrms[(k + 1) % 4] * sin(a)).normalized()
	return [base + n * d, n]


func _build_crowns() -> void:
	var d: float = 15.0
	var row: int = 0
	var domes: int = 0
	var cones: int = 0
	while d < CROWN_MAX_D:
		var sp: float = 3.2 + maxf(d - 20.0, 0.0) * 0.026
		var length: float = 4.0 * 2.0 * MAP_HALF + TAU * d
		var cnt: int = int(length / sp)
		for i: int in cnt:
			var t: float = (i + 0.5 * (row % 2)) * length / cnt + (_h(row, i, 1.0) - 0.5) * sp * 0.8
			var dd: float = d + (_h(row, i, 2.0) - 0.5) * sp * 0.7
			if dd < 14.5:
				continue
			# Thin inner rows: map_dressing's border forest stands there (dense to 13 m, thinning to 24 m).
			var keep: float = clampf((dd - 11.0) / 8.0, 0.35, 1.0)
			if _h(row, i, 3.0) > keep:
				continue
			var p: Vector2 = _offset_point(t, dd)[0]
			if _cleared(p, sp * 0.5):
				continue
			if _add_crown(p, dd, _h(row, i, 4.0), _h(row, i, 5.0), _h(row, i, 6.0)):
				domes += 1
			else:
				cones += 1
		d += sp * 0.86
		row += 1
	_counts["domes"] = domes
	_counts["conifers"] = cones


## One crown; returns true for a dome, false for a conifer.
func _add_crown(p: Vector2, d: float, h1: float, h2: float, h3: float) -> bool:
	var ch: Chunk = _chunks[_sector(p)]
	var gy: float = _ground_y(p)
	var o: Vector3 = _out(p)
	# Kind: clumped by a low-frequency noise. Uplands (north / west) are mostly firs, lowlands mostly oaks.
	var nk: float = _noise_kind.get_noise_2dv(p)
	var upland: float = maxf(-o.z, 0.0) * 0.6 + maxf(-o.y, 0.0) * 0.5
	var conifer_p: float = clampf(0.42 + upland * 0.3 - nk * 0.55, 0.08, 0.92)
	# Roughly the border trees' size, a little bigger far out (fewer, cheaper crowns); darker with the distance
	# so the far forest reads as deep shade behind the lit band and the play space stays the brightest thing.
	var scale: float = (0.95 + smoothstep(15.0, 75.0, d) * 0.25) * (0.85 + h2 * 0.3)
	var shade: float = lerpf(0.8, 0.6, smoothstep(15.0, 60.0, d)) * (0.9 + h3 * 0.2)
	if h1 < conifer_p:
		var fir: bool = _noise_kind.get_noise_2dv(p * 1.7 + Vector2(40.0, 11.0)) > 0.0
		var c0: Color = FIR if fir else PINE
		var c1: Color = FIR_L if fir else PINE_L
		_conifer(ch, Vector3(p.x, gy + 0.5 * scale, p.y), 1.45 * scale, (5.0 + h3 * 2.4) * scale,
			_haze(c0 * 0.6 * shade, d), _haze(c0 * shade, d), _haze(c1 * shade, d), h1 * 91.0 + h2)
		return false
	# Far oaks drift a little bluer (under the warm sun a plain oak green turns olive in the shade band).
	var cool: float = smoothstep(20.0, 60.0, d) * 0.35
	var lo: Color = OAK_D.lerp(PINE, cool)
	var mi: Color = OAK.lerp(PINE_L, cool)
	var hi: Color = OAK.lerp(OAK_L, 0.55).lerp(PINE_L, cool)
	var gold: float = _noise_kind.get_noise_2dv(p * 0.8 + Vector2(-77.0, 23.0))
	if gold > 0.7 and h2 > 0.8:
		lo = GOLD_D * 0.8
		mi = GOLD.lerp(OAK, 0.35) * 0.82
		hi = GOLD.lerp(GOLD_L, 0.3).lerp(OAK, 0.2) * 0.85
	elif gold < -0.55 and h2 > 0.5:
		mi = BIRCH
		hi = BIRCH.lerp(BIRCH_L, 0.6)
	var r: float = 1.9 * scale * (0.9 + h3 * 0.25)
	var c := Vector3(p.x, gy + (2.2 + h2 * 1.0) * scale, p.y)
	_dome(ch, c, r, r * (1.0 + h1 * 0.3), _haze(lo * shade, d), _haze(mi * shade, d), _haze(hi * shade, d),
		h1 * 57.0 + h2 * 3.0)
	# Some crowns are lumpy: a smaller second puff on one shoulder.
	if h3 > 0.62:
		var a: float = h2 * TAU
		var r2: float = r * 0.62
		_dome(ch, c + Vector3(cos(a) * r * 0.75, r * 0.35, sin(a) * r * 0.75), r2, r2 * 1.1, _haze(lo * shade, d),
			_haze(mi * shade, d), _haze(hi * shade * 1.04, d), h3 * 31.0 + h1)
	return true


## A painted round crown: 7-sided, two rings + apex, smooth normals (the toon ramp paints a lit and a shaded half).
func _dome(ch: Chunk, c: Vector3, r: float, h: float, lo: Color, mi: Color, hi: Color, seed: float) -> void:
	var segs: int = 7
	var b0: int = ch.v.size()
	var rot: float = _h(seed, 0.0, 1.0) * TAU
	for k: int in segs:
		var a: float = rot + k * TAU / segs
		var dir := Vector3(cos(a), 0.0, sin(a))
		ch.v.append(c + dir * r * (0.88 + 0.24 * _h(seed, k, 2.0)) + Vector3(0.0, -0.15 * r * _h(seed, k, 3.0), 0.0))
		ch.n.append((dir - Vector3.UP * 0.2).normalized())
		ch.c.append(_ca(lo, 0.35))
		ch.f.append(DOME_FACET)
	for k: int in segs:
		var a: float = rot + (k + 0.5) * TAU / segs
		var dir := Vector3(cos(a), 0.0, sin(a))
		ch.v.append(c + dir * r * (0.72 + 0.16 * _h(seed, k, 4.0)) + Vector3(0.0, h * (0.5 + 0.12 * _h(seed, k, 5.0)), 0.0))
		ch.n.append((dir * 0.72 + Vector3.UP * 0.7).normalized())
		ch.c.append(_ca(mi, 0.85))
		ch.f.append(DOME_FACET)
	var apex: Vector3 = c + Vector3((_h(seed, 6.0, 1.0) - 0.5) * r * 0.3, h, (_h(seed, 7.0, 1.0) - 0.5) * r * 0.3)
	ch.v.append(apex)
	ch.n.append(Vector3.UP)
	ch.c.append(_ca(hi, 1.0))
	ch.f.append(DOME_FACET)
	var mid: Vector3 = c + Vector3(0.0, h * 0.3, 0.0)
	for k: int in segs:
		var k1: int = (k + 1) % segs
		var a0: int = b0 + k
		var a1: int = b0 + k1
		var r0: int = b0 + segs + k
		var r1: int = b0 + segs + k1
		_tri(ch, a0, a1, r0, (ch.v[a0] + ch.v[a1] + ch.v[r0]) / 3.0 - mid)
		_tri(ch, r0, a1, r1, (ch.v[r0] + ch.v[a1] + ch.v[r1]) / 3.0 - mid)
		_tri(ch, r0, r1, b0 + segs * 2, (ch.v[r0] + ch.v[r1] + apex) / 3.0 - mid)


## A far conifer: two star tiers (5 drooping points each), smooth-ish normals, 20 triangles.
func _conifer(ch: Chunk, base: Vector3, r: float, h: float, lo: Color, mi: Color, hi: Color, seed: float) -> void:
	var rot: float = _h(seed, 0.0, 1.0) * TAU
	for tier: int in 2:
		var y0: float = 0.0 if tier == 0 else h * 0.4
		var th: float = h * (0.62 if tier == 0 else 0.6)
		var rr: float = r * (1.0 if tier == 0 else 0.64)
		var b0: int = ch.v.size()
		for k: int in 10:
			var a: float = rot + tier * 0.6 + k * TAU / 10.0
			var outer: bool = k % 2 == 0
			var rk: float = rr * (1.0 if outer else 0.58) * (0.9 + 0.2 * _h(seed, k, tier + 2.0))
			var dir := Vector3(cos(a), 0.0, sin(a))
			var droop: float = -th * 0.14 if outer else th * 0.05
			ch.v.append(base + dir * rk + Vector3(0.0, y0 + droop, 0.0))
			ch.n.append((dir * th + Vector3.UP * rr * 1.1).normalized())
			ch.c.append(_ca(lo if tier == 0 else mi, 0.3 if tier == 0 else 0.7))
			ch.f.append(CONE_FACET)
		var apex: Vector3 = base + Vector3(0.0, y0 + th, 0.0)
		ch.v.append(apex)
		ch.n.append(Vector3.UP)
		ch.c.append(_ca(mi if tier == 0 else hi, 0.8 if tier == 0 else 1.0))
		ch.f.append(CONE_FACET)
		var mid: Vector3 = base + Vector3(0.0, y0 + th * 0.25, 0.0)
		for k: int in 10:
			var k1: int = (k + 1) % 10
			_tri(ch, b0 + k, b0 + k1, b0 + 10, (ch.v[b0 + k] + ch.v[b0 + k1] + apex) / 3.0 - mid)


# --- landmarks -----------------------------------------------------------------------------------------------------

func _gy3(p: Vector2, dy: float = 0.0) -> Vector3:
	return Vector3(p.x, _ground_y(p) + dy, p.y)


func _build_landmarks() -> void:
	_tower()
	_shrine()
	_aqueduct()
	_stone_ring()
	_pond()
	for i: int in CRAGS.size():
		_crag(CRAGS[i], 40.0 + i * 13.0)


## NE: a broken round watchtower in a curtain-wall ring, leaning a little, ivy on the stones.
func _tower() -> void:
	var c: Vector3 = _gy3(TOWER, -0.6)
	var lean := Basis(Vector3(1, 0, 0.4).normalized(), 0.05)
	_prism(c, 8, 3.0, 2.5, 12.5, 3.0, 1.4, lean, RUIN, MOSS * Color(1, 1, 1, 0.6), 11.0, 0.25, RUIN_D)
	_prism(c + lean * Vector3(0.0, 7.6, 0.0), 8, 3.2, 3.2, 0.7, 0.0, 0.0, lean, RUIN_L, Color(0, 0, 0, 0), 12.0)
	_prism(c, 8, 3.8, 3.3, 1.6, 0.3, 0.0, Basis(), RUIN_D, MOSS * Color(1, 1, 1, 0.5), 13.0)
	# Curtain wall stubs.
	for k: int in 6:
		if k == 2:
			continue
		var a: float = k * TAU / 6.0 + 0.4
		var p: Vector2 = TOWER + Vector2(cos(a), sin(a)) * 7.0
		var hh: float = 1.6 + _h(k, 1.0, 14.0) * 2.8
		var b := Basis(Vector3.UP, -a + PI * 0.5)
		_box(_gy3(p, hh * 0.5 - 0.5), Vector3(5.2, hh, 1.1), b, RUIN, MOSS * Color(1, 1, 1, 0.7), 20.0 + k, 0.3)
	# Rubble.
	for k: int in 7:
		var a: float = _h(k, 2.0, 15.0) * TAU
		var p: Vector2 = TOWER + Vector2(cos(a), sin(a)) * (3.8 + _h(k, 3.0, 15.0) * 4.0)
		var s: float = 0.7 + _h(k, 4.0, 15.0) * 0.7
		_box(_gy3(p, s * 0.2), Vector3(s * 1.3, s, s), Basis.from_euler(Vector3(0.3, a, 0.2)), RUIN_D, MOSS * Color(1, 1, 1, 0.5),
			30.0 + k)


## NW: a toppled shrine: a ring of column stubs round a plinth, one column fallen down the slope.
func _shrine() -> void:
	var c: Vector3 = _gy3(SHRINE, -0.2)
	_box(c + Vector3(0.0, 0.3, 0.0), Vector3(8.0, 1.0, 8.0), Basis(Vector3.UP, 0.3), RUIN_D, MOSS * Color(1, 1, 1, 0.6), 50.0)
	for k: int in 6:
		var a: float = k * TAU / 6.0 + 0.3
		var p: Vector2 = SHRINE + Vector2(cos(a), sin(a)) * 3.0
		var hh: float = 2.0 + _h(k, 1.0, 51.0) * 5.5
		if k == 4:
			continue
		_prism(_gy3(p, 0.6), 6, 0.62, 0.55, hh, 0.9, 0.0, Basis(), RUIN_L, MOSS * Color(1, 1, 1, 0.5), 52.0 + k, 0.2)
	var fall := Basis(Vector3(0, 0, 1), PI * 0.5 - 0.12) * Basis(Vector3.UP, 0.0)
	var fp: Vector2 = SHRINE + Vector2(5.5, 3.0)
	_prism(_gy3(fp, 0.4), 6, 0.6, 0.6, 5.5, 0.4, 0.0, Basis(Vector3.UP, 0.7) * fall, RUIN_L, MOSS * Color(1, 1, 1, 0.6), 60.0)


## W: a broken aqueduct striding out of the forest, arches over a cleared line, two spans fallen.
func _aqueduct() -> void:
	var dir: Vector2 = (AQ_B - AQ_A).normalized()
	var across := Vector2(-dir.y, dir.x)
	var span: float = 7.0
	var count: int = int(AQ_A.distance_to(AQ_B) / span)
	var pier_w: float = 1.8
	var r: float = (span - pier_w) * 0.5
	var yaw: float = atan2(-dir.y, dir.x)
	var b := Basis(Vector3.UP, yaw)
	var broken: Array[int] = [2, 5]
	# The channel steps up with the hills: each span's deck sits ~9 m over its higher pier foot.
	var decks: Array[float] = []
	for k: int in count:
		decks.append(maxf(_ground_y(AQ_A + dir * k * span), _ground_y(AQ_A + dir * (k + 1) * span)) + 4.6 + r + 0.9)
	for k: int in count + 1:
		var p: Vector2 = AQ_A + dir * k * span
		var gy: float = _ground_y(p) - 1.0
		var deck_k: float = maxf(decks[k - 1] if k > 0 else -INF, decks[k] if k < count else -INF)
		var ph: float = deck_k - gy
		if k == 3 or k == 6:
			ph *= 0.45 + _h(k, 1.0, 70.0) * 0.2   # snapped piers
		_box(Vector3(p.x, gy + ph * 0.5, p.y), Vector3(pier_w, ph, 2.2), b, RUIN, MOSS * Color(1, 1, 1, 0.6), 70.0 + k, 0.25)
		if k == count or broken.has(k):
			continue
		# Arch + spandrel + deck between pier k and k + 1.
		var deck: float = decks[k]
		var c2: Vector2 = p + dir * span * 0.5
		_arch(Vector3(c2.x, deck - 0.9 - r, c2.y), dir, across, r, deck, 2.2, 80.0 + k)
		_box(Vector3(c2.x, deck + 0.3, c2.y), Vector3(span + 0.4, 0.6, 2.4), b, RUIN, MOSS * Color(1, 1, 1, 0.55), 90.0 + k)
		_box(Vector3(c2.x, deck + 0.62, c2.y), Vector3(span + 0.4, 0.06, 0.8), b, WATER, Color(0, 0, 0, 0), 95.0 + k)
	# Fallen blocks under the broken spans.
	for k: int in broken:
		for j: int in 3:
			var p: Vector2 = AQ_A + dir * (k + 0.5) * span + across * (_h(k, j, 71.0) - 0.5) * 4.0 + dir * (j - 1.0) * 1.8
			var s: float = 1.0 + _h(k, j, 72.0) * 0.8
			_box(_gy3(p, s * 0.25), Vector3(s * 1.6, s, s * 1.1), Basis.from_euler(Vector3(0.25, _h(k, j, 73.0) * TAU, 0.3)),
				RUIN_D, MOSS * Color(1, 1, 1, 0.5), 100.0 + k * 3 + j)


## One arch: the semicircular soffit and the two spandrel faces up to the deck.
func _arch(c: Vector3, dir: Vector2, across: Vector2, r: float, deck: float, width: float, seed: float) -> void:
	var ch: Chunk = _chunks[_sector(Vector2(c.x, c.z))]
	var d3 := Vector3(dir.x, 0.0, dir.y)
	var a3 := Vector3(across.x, 0.0, across.y) * width * 0.5
	var segs: int = 6
	var v := PackedVector3Array()
	for side: int in 2:
		var off: Vector3 = a3 if side == 0 else -a3
		for k: int in segs + 1:
			var th: float = PI - PI * k / segs
			v.append(c + off + d3 * cos(th) * r + Vector3(0.0, sin(th) * r, 0.0))
		for k: int in segs + 1:
			var th2: float = PI - PI * k / segs
			v.append(c + off + d3 * cos(th2) * r + Vector3(0.0, deck - c.y, 0.0))
	var n1: int = segs + 1
	var tris := PackedInt32Array()
	var hints := PackedVector3Array()
	for side: int in 2:
		var o: int = side * n1 * 2
		var out: Vector3 = a3 if side == 0 else -a3
		for k: int in segs:
			tris.append_array([o + k, o + k + 1, o + n1 + k, o + k + 1, o + n1 + k + 1, o + n1 + k])
			hints.append(out)
			hints.append(out)
	for k: int in segs:
		var f0: int = k
		var f1: int = k + 1
		var b0: int = n1 * 2 + k
		var b1: int = n1 * 2 + k + 1
		tris.append_array([f0, f1, b0, f1, b1, b0])
		var th3: float = PI - PI * (k + 0.5) / segs
		var inward: Vector3 = -(d3 * cos(th3) + Vector3(0.0, sin(th3), 0.0))
		hints.append(inward)
		hints.append(inward)
	_flat(ch, v, tris, c, RUIN, Color(0, 0, 0, 0), c.y - 6.0, deck, seed, hints, 0.2)


## SW: a ring of standing stones in a meadow, two fallen, a flat altar stone in the middle.
func _stone_ring() -> void:
	for k: int in 9:
		var a: float = k * TAU / 9.0 + 0.2
		var p: Vector2 = STONES + Vector2(cos(a), sin(a)) * 7.0
		var hh: float = 3.4 + _h(k, 1.0, 110.0) * 1.8
		var b := Basis(Vector3.UP, -a) * Basis(Vector3(1, 0, 0), (_h(k, 2.0, 110.0) - 0.5) * 0.25)
		if k == 3 or k == 7:
			b = Basis(Vector3.UP, -a + 0.8) * Basis(Vector3(1, 0, 0), PI * 0.5 - 0.1)
			_box(_gy3(p, 0.3), Vector3(1.3, hh, 0.8), b, ROCK_B, MOSS * Color(1, 1, 1, 0.8), 111.0 + k)
			continue
		_box(_gy3(p, hh * 0.5 - 0.4), Vector3(0.8, hh, 1.3), b, ROCK_B.lerp(ROCK_D, 0.3 + _h(k, 3.0, 110.0) * 0.3),
			MOSS * Color(1, 1, 1, 0.7), 111.0 + k)
	_box(_gy3(STONES, 0.2), Vector3(3.0, 0.8, 1.8), Basis(Vector3.UP, 0.5), ROCK_L, MOSS * Color(1, 1, 1, 0.4), 120.0)


## E: a pond in a glade: a flat water disc with a paler rim, in a hollow.
func _pond() -> void:
	var y: float = _pond_y + 0.1
	var ch: Chunk = _chunks[_sector(POND)]
	var segs: int = 14
	for ring: int in 2:
		var r: float = 5.4 if ring == 0 else 4.2
		var col: Color = _haze(WATER if ring == 0 else WATER_L.lerp(WATER, 0.45), 32.0)
		var b0: int = ch.v.size()
		var cy: float = y + ring * 0.06
		ch.v.append(Vector3(POND.x, cy, POND.y))
		ch.n.append(Vector3.UP)
		ch.c.append(_ca(col, 1.0))
		ch.f.append(0.0)
		for k: int in segs:
			var a: float = k * TAU / segs
			var rk: float = r * (0.85 + 0.3 * _h(k, ring, 160.0))
			ch.v.append(Vector3(POND.x + cos(a) * rk * 1.15, cy, POND.y + sin(a) * rk))
			ch.n.append(Vector3.UP)
			ch.c.append(_ca(col, 1.0))
			ch.f.append(0.0)
		for k: int in segs:
			_tri(ch, b0, b0 + 1 + k, b0 + 1 + (k + 1) % segs, Vector3.UP)
	# Reeds / rocks on the bank.
	for k: int in 5:
		var a: float = _h(k, 1.0, 161.0) * TAU
		var p: Vector2 = POND + Vector2(cos(a) * 7.0, sin(a) * 6.0)
		var s: float = 0.6 + _h(k, 2.0, 161.0) * 0.8
		_box(_gy3(p, s * 0.2), Vector3(s * 1.4, s, s), Basis.from_euler(Vector3(0.2, a, 0.3)), ROCK, MOSS * Color(1, 1, 1, 0.6),
			162.0 + k)


## A granite crag: 3-5 tilted, jagged spires rising through the canopy, plus boulders.
func _crag(at: Vector2, seed: float) -> void:
	var n: int = 3 + int(_h(seed, 1.0, 0.0) * 2.99)
	var o: Vector3 = _out(at)
	var lean_dir := Vector3(o.y, 0.0, o.z)
	for k: int in n:
		var a: float = _h(seed, k, 1.0) * TAU
		var p: Vector2 = at + Vector2(cos(a), sin(a)) * (k * 2.4) * (0.6 + _h(seed, k, 2.0) * 0.5)
		var hh: float = (11.0 - k * 1.8) * (0.8 + _h(seed, k, 3.0) * 0.4)
		var r0: float = 2.6 - k * 0.3
		var tilt := Basis(lean_dir.cross(Vector3.UP).normalized(), -(0.08 + _h(seed, k, 4.0) * 0.14))
		var col: Color = [ROCK, ROCK_B, ROCK_L, ROCK.lerp(ROCK_B, 0.5)][k % 4]
		_prism(_gy3(p, -1.5), 6, r0, r0 * 0.35, hh, hh * 0.18, 0.0, tilt, col, MOSS * Color(1, 1, 1, 0.8), seed + k)
	for k: int in 4:
		var a2: float = _h(seed, k, 6.0) * TAU
		var p2: Vector2 = at + Vector2(cos(a2), sin(a2)) * (4.5 + _h(seed, k, 7.0) * 3.0)
		var s: float = 0.9 + _h(seed, k, 8.0) * 1.0
		_box(_gy3(p2, s * 0.2), Vector3(s * 1.5, s, s * 1.2), Basis.from_euler(Vector3(0.3, a2, 0.25)), ROCK_D.lerp(ROCK, 0.5),
			MOSS * Color(1, 1, 1, 0.7), seed + 20.0 + k)


# --- output --------------------------------------------------------------------------------------------------------

func _save_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	var mat := ShaderMaterial.new()
	mat.shader = load(DIR + "horizon.gdshader") as Shader
	mat.set_shader_parameter("noise_tex", load(NOISE_TEX))
	_save(mat, DIR + "horizon_mat.tres")
	mat = load(DIR + "horizon_mat.tres") as ShaderMaterial
	var root := Node3D.new()
	root.name = "Horizon"
	root.set_script(load(DIR + "horizon_fit.gd"))
	var total: int = 0
	for i: int in 8:
		var ch: Chunk = _chunks[i]
		if ch.idx.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = ch.v
		arrays[Mesh.ARRAY_NORMAL] = ch.n
		arrays[Mesh.ARRAY_COLOR] = ch.c
		var uv := PackedVector2Array()
		uv.resize(ch.v.size())
		for k: int in ch.v.size():
			uv[k] = Vector2(ch.f[k], 0.0)
		arrays[Mesh.ARRAY_TEX_UV] = uv
		# HorizonFit anchors: the ring follows the running map's size (horizon_fit.gd).
		arrays[Mesh.ARRAY_TEX_UV2] = HorizonFit.anchors(ch.v, ch.idx)
		arrays[Mesh.ARRAY_INDEX] = ch.idx
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, mat)
		var path: String = MESH_DIR + "horizon_%s.res" % SECTOR_NAMES[i].to_snake_case()
		_save(mesh, path)
		var mi := MeshInstance3D.new()
		mi.name = SECTOR_NAMES[i]
		mi.mesh = load(path) as Mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		# The farthest a gameplay camera gets from a sector is ~230 m; the range only drops them for far views
		# (menus, cinematics). Frustum culling of the 8 sectors does the real work.
		mi.visibility_range_end = 300.0
		root.add_child(mi)
		mi.owner = root
		total += ch.idx.size() / 3
		print("sector %s: %d verts, %d tris" % [SECTOR_NAMES[i], ch.v.size(), ch.idx.size() / 3])
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, DIR + "horizon.tscn")
	root.free()
	print("counts %s" % str(_counts))
	print("HORIZON BUILT: %d tris in %d sectors" % [total, _chunks.filter(func(c: Chunk) -> bool: return not c.idx.is_empty()).size()])


func _save(res: Resource, path: String) -> void:
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])
