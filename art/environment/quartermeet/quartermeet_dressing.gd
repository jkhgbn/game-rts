class_name QuartermeetDressing
extends Node3D
## G-F Quartermeet identity (docs/art/gf_quartermeet.md): Quartermeet's own dressing (Medium+ only; QuartermeetLook
## adds it), the HARVEST HIGHLAND props that make the map read apart from Ashwind Reach:
##   stook fields  small harvested plots in the open ground between the bases and the river: rows of straw stooks
##                 laid along the nearest road, broken drystone walls on two sides (a gap for the gate), round hay
##                 bales at the corners, stubble tufts; found in one quadrant and mirrored fourfold (the map's own
##                 symmetry), every piece checked again on its own side
##   moor rim      heather, gorse and lichen stones clumped along the last ~3 m of the map (noise: outcrops and bays),
##                 a hay bale now and then
##   crown isle    four granite standing stones with harvest garlands rising from the moat between the crossings
## One MultiMeshInstance3D per mesh kind (~8 draws). Draw-only: no collider, no navmesh effect, nothing on nav layers.
## Kept clear: keeps, nodes, building slots, points, camps, lairs, taverns, posts, caches, critter slots, roads,
## crossings, the planned forest trees / rocks / pillars, water; a building placed later hides the decor under its
## footprint (node_added). Map detail Low keeps half of every kind except the standing stones. Deterministic.

const NODE_NAME := &"QuartermeetDressing"
const B := "res://art/environment/biomes/"
const MESHES_SCRIPT := "res://art/environment/quartermeet/quartermeet_meshes.gd"
const HEATHER := B + "heath/heath_heather.res"
const GORSE := B + "heath/heath_gorse.res"
const LICHEN := B + "heath/heath_lichen_stones.res"
const HAY := B + "heath/heath_tall_grass.res"   ## stubble tufts (meadow_hay reads as a pumpkin from the game camera)   
## Built in code (quartermeet_meshes.gd), keyed like a path.
const STOOK := "quartermeet:stook"
const BALE := "quartermeet:bale"
const WALL := "quartermeet:wall"
const STONE := "quartermeet:standing_stone"
const CODE_KINDS := {STOOK: &"stook", BALE: &"bale", WALL: &"wall", STONE: &"standing_stone"}
const WATER_Y := -0.35
const SHADOW_KINDS: Array[String] = [STONE, WALL, BALE, LICHEN]
## Kinds never hidden by a building (in the moat).
const FIXED_KINDS: Array[String] = [STONE]
const LOW_DETAIL := 0.5
const RIM_REACH := 3.0          ## the deepest moor outcrop into the map (m)
const MAX_PLOTS := 3            ## stook fields per quadrant
const PLOT_SPACING := 20.0      ## metres between two field centres
const MIN_CLEAR := 4.5          ## a field centre this far from anything kept clear (the pieces are checked one by one)
const WALL_LEN := 2.4           ## one wall segment (quartermeet_meshes.gd)

var counts := {}                     ## kind -> instances placed (tests)
var plots: Array[Vector4] = []       ## (x, z, yaw, stooks) of every field laid (tests / the note)
var _level: Node
var _layout: Resource
var _river: Node
var _rng := RandomNumberGenerator.new()
var _thin_rng := RandomNumberGenerator.new()
var _keep := 1.0
var _lists := {}                     ## kind -> Array[Transform3D]
var _mmis := {}                      ## kind -> MultiMeshInstance3D
var _avoid: Array[Vector3] = []      ## (x, z, radius)
var _roads: Array[Vector4] = []      ## (a.x, a.z, b.x, b.z)
var _road_half := 3.3
var _hx := 60.0
var _hz := 60.0
var _obst := {}                      ## Vector2i cell (8 m) -> Array[Vector3] (x, z, radius): trees, rocks, pillars
const CELL := 8.0


## CPU copies of one kind's instance transforms (tests: the headless renderer keeps no MultiMesh data).
func instance_transforms(kind: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for xf: Variant in _lists.get(kind, []):
		out.append(xf as Transform3D)
	return out


func _ready() -> void:
	_level = get_parent()
	if _level and _level.has_method(&"map_layout"):
		_layout = _level.call(&"map_layout") as Resource
	_river = _level.get(&"river") as Node if _level and &"river" in _level else null
	build()
	if is_inside_tree():
		get_tree().node_added.connect(_on_node_added)


## Builds (or rebuilds) every MultiMesh. Returns the instances placed.
func build() -> int:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_lists.clear()
	_mmis.clear()
	counts.clear()
	plots.clear()
	_hx = MapInfo.half_x()
	_hz = MapInfo.half_z()
	_rng.seed = hash("quartermeet_dressing")
	_thin_rng.seed = _rng.seed + 1
	_keep = LOW_DETAIL if MapDressingArt.map_detail() == &"low" else 1.0
	_read_avoid()
	_read_obstacles()
	_fields()
	_moor_rim()
	_crown_isle()
	_clear_existing_buildings()
	var total := 0
	for kind: String in _lists:
		var list: Array = _lists[kind]
		if list.is_empty():
			continue
		var mesh := _mesh_for(kind)
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i: int in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = kind.get_file().get_basename().to_pascal_case() if kind.begins_with("res://") \
			else kind.trim_prefix("quartermeet:").to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if not kind in SHADOW_KINDS:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mmis[kind] = mmi
		counts[kind] = list.size()
		total += list.size()
	return total


func _mesh_for(kind: String) -> Mesh:
	if CODE_KINDS.has(kind):
		if not ResourceLoader.exists(MESHES_SCRIPT):
			return null
		return (load(MESHES_SCRIPT) as Script).call(CODE_KINDS[kind]) as Mesh
	if not ResourceLoader.exists(kind):
		return null
	return load(kind) as Mesh


# ---------------------------------------------------------------- what to keep clear

const SPOT_RADII := {"keep": 9.5, "node": 3.5, "start": 3.0, "point": 4.5, "camp": 6.0, "lair": 6.0, "tavern": 6.5,
	"peddler": 4.5, "post": 5.0, "cache": 2.5, "guild": 5.5, "crown": 6.0}
const SLOT_RADII := {"house": 4.5, "market": 5.5, "natural_hall": 6.5, "rich_hall": 6.5, "tower_natural": 4.0,
	"tower_rich": 4.0, "graze": 3.5, "rabbit": 3.5, "bot_rally": 3.0, "bot_anchor": 3.0}


func _read_avoid() -> void:
	_avoid.clear()
	_roads.clear()
	if _layout == null:
		return
	var spots: Array = _layout.get(&"spots")
	for s: Dictionary in spots:
		var p: Vector3 = s.get("pos", Vector3.ZERO)
		var kind := String(s.get("kind", ""))
		var r := float(SPOT_RADII.get(kind, 0.0))
		if kind == "keep":
			r = float((s.get("props", {}) as Dictionary).get("footprint", 6.0)) + 3.5
		elif kind == "slot":
			r = float(SLOT_RADII.get(String(s.get("sub", "")), 3.0))
		if r > 0.0:
			_avoid.append(Vector3(p.x, p.z, r))
	var props: Array = _layout.get(&"props") if &"props" in _layout else []
	for pr: Dictionary in props:
		var pv: Variant = pr.get("pos", pr.get("at", null))
		if pv is Vector3:
			_avoid.append(Vector3((pv as Vector3).x, (pv as Vector3).z, 4.0))
		elif pv is Vector2:
			_avoid.append(Vector3((pv as Vector2).x, (pv as Vector2).y, 4.0))
	var roads: Array = _layout.get(&"roads")
	for rd: Dictionary in roads:
		var poly: PackedVector3Array = rd.get("poly", PackedVector3Array())
		_road_half = float(rd.get("width", 5.0)) * 0.5 + 0.8
		for i: int in poly.size() - 1:
			_roads.append(Vector4(poly[i].x, poly[i].z, poly[i + 1].x, poly[i + 1].z))


## The planned forest (trees, rocks, ruin pillars) in 8 m buckets.
func _read_obstacles() -> void:
	_obst.clear()
	var plan: Variant = _level.get(&"forest_plan") if _level and &"forest_plan" in _level else null
	if not (plan is Dictionary):
		return
	for key: String in ["trees", "rocks", "pillars"]:
		for t: Dictionary in (plan as Dictionary).get(key, []):
			var p: Vector3 = t.get("pos", Vector3.ZERO)
			var r := 2.4 if key == "trees" else (1.8 * float(t.get("s", 1.0)) if key == "rocks" else 1.6)
			var c := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
			if not _obst.has(c):
				_obst[c] = []
			(_obst[c] as Array).append(Vector3(p.x, p.z, r))


## Distance from `p` to the nearest planned tree / rock / pillar edge (capped at 2 cells).
func _obst_clear(p: Vector2) -> float:
	var best := CELL * 2.0
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	for dx: int in range(-2, 3):
		for dz: int in range(-2, 3):
			for o: Vector3 in _obst.get(c + Vector2i(dx, dz), []):
				best = minf(best, Vector2(p.x - o.x, p.y - o.y).length() - o.z)
	return best


func _road_dist(p: Vector2) -> float:
	var best := INF
	for s: Vector4 in _roads:
		var q := Geometry2D.get_closest_point_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w))
		best = minf(best, q.distance_to(p) - _road_half)
	return best


## The direction of the road segment nearest `p` (ZERO when none within `reach`).
func _road_dir(p: Vector2, reach: float) -> Vector2:
	var best := reach
	var dir := Vector2.ZERO
	for s: Vector4 in _roads:
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := q.distance_to(p)
		if d < best and a.distance_to(b) > 0.5:
			best = d
			dir = (b - a).normalized()
	return dir


func _on_road(p: Vector2, pad: float = 0.0) -> bool:
	return _road_dist(p) < pad


func _blocked(p: Vector2, pad: float = 0.0) -> bool:
	for a: Vector3 in _avoid:
		if Vector2(p.x - a.x, p.y - a.y).length() < a.z + pad:
			return true
	return _on_road(p, pad)


## How much room `p` has: the smallest gap to anything kept clear (spots, roads, forest, water, crossings, edge).
func _clearance(p: Vector2) -> float:
	var c := minf(_road_dist(p), _obst_clear(p))
	for a: Vector3 in _avoid:
		c = minf(c, Vector2(p.x - a.x, p.y - a.y).length() - a.z)
	c = minf(c, _water_dist(p, 20.0) - 3.0)
	c = minf(c, minf(_hx - absf(p.x), _hz - absf(p.y)) - 6.0)
	if _river and _river.has_method(&"distance_to_crossing"):
		c = minf(c, float(_river.call(&"distance_to_crossing", Vector3(p.x, 0.0, p.y))) - 6.0)
	return c


func _crossing_near(p: Vector2, dist: float) -> bool:
	if _river == null or not _river.has_method(&"distance_to_crossing"):
		return false
	return float(_river.call(&"distance_to_crossing", Vector3(p.x, 0.0, p.y))) < dist


func _is_water(p: Vector2) -> bool:
	return _river != null and _river.has_method(&"is_water") and bool(_river.call(&"is_water", Vector3(p.x, 0.0, p.y)))


func _water_dist(p: Vector2, cap: float) -> float:
	if _river == null or not _river.has_method(&"distance_to_water"):
		return cap
	return float(_river.call(&"distance_to_water", Vector3(p.x, 0.0, p.y), cap))


## True when a small prop can stand at `p` (`pad` = its own radius).
func _free(p: Vector2, pad: float) -> bool:
	if absf(p.x) > _hx - 2.0 or absf(p.y) > _hz - 2.0:
		return false
	if _blocked(p, pad) or _obst_clear(p) < pad or _is_water(p) or _water_dist(p, 4.0) < 2.5:
		return false
	return not _crossing_near(p, 5.0)


func _add(kind: String, p: Vector3, s: float, yaw: float = -1.0) -> void:
	if _keep < 1.0 and kind != STONE and _thin_rng.randf() > _keep:
		return
	if yaw < 0.0:
		yaw = _rng.randf() * TAU
	if not _lists.has(kind):
		_lists[kind] = []
	(_lists[kind] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p))


static func _h(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


## Smooth 1D value noise (period ~`cell` metres), 0..1.
static func _noise1(t: float, cell: float, seed: float) -> float:
	var x := t / cell
	var i := floorf(x)
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_h(i, seed), _h(i + 1.0, seed), f)


## The yaw that turns a mesh's local +X along `d` (x, z).
static func _yaw_along(d: Vector2) -> float:
	return atan2(-d.y, d.x)


# ---------------------------------------------------------------- stook fields

## Finds up to MAX_PLOTS open spots in the x < 0, z > 0 quadrant (the most room first, PLOT_SPACING apart) and lays
## a field at each, mirrored into the other three quadrants.
func _fields() -> void:
	if _layout == null:
		return
	var cands: Array = []
	var x := -_hx + 12.0
	while x < -8.0:
		var z := 8.0
		while z < _hz - 12.0:
			var p := Vector2(x, z)
			var clear := _clearance(p)
			if clear >= MIN_CLEAR:
				cands.append([clear + _h(x, z) * 1.5, p, clear])
			z += 4.0
		x += 4.0
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var chosen: Array[Vector2] = []
	for c: Array in cands:
		if chosen.size() >= MAX_PLOTS:
			break
		var p: Vector2 = c[1]
		var ok := true
		for q: Vector2 in chosen:
			if q.distance_to(p) < PLOT_SPACING:
				ok = false
		if not ok:
			continue
		chosen.append(p)
		var dir := _road_dir(p, 40.0)
		if dir == Vector2.ZERO:
			dir = Vector2.from_angle(_h(p.x, p.y) * PI)
		var size := clampf(float(c[2]) * 2.0, 11.0, 18.0)
		for sx: float in [1.0, -1.0]:
			for sz: float in [1.0, -1.0]:
				_lay_field(Vector2(p.x * sx, p.y * sz), Vector2(dir.x * sx, dir.y * sz), size)


## One field centred on `c`, its rows along `u` (unit), `length` metres long and ~0.6 x as wide.
func _lay_field(c: Vector2, u: Vector2, length: float) -> void:
	var v := Vector2(-u.y, u.x)
	var width := length * 0.62
	var seed := _h(c.x, c.y)
	var stooks := 0
	# Stook rows (a stook every ~1.9 m, rows ~2.2 m apart, a little jitter: hand-set, not a grid).
	var rows := maxi(2, int(width / 2.2))
	var per := maxi(3, int(length / 1.9))
	for r: int in rows:
		var off_v := (r - (rows - 1) * 0.5) * 2.2
		for k: int in per:
			var off_u := (k - (per - 1) * 0.5) * 1.9 + (0.5 if r % 2 == 1 else 0.0)
			var p := c + u * off_u + v * off_v + Vector2(_rng.randf_range(-0.35, 0.35), _rng.randf_range(-0.35, 0.35))
			if _rng.randf() < 0.12 or not _free(p, 0.6):
				continue
			_add(STOOK, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.85, 1.12))
			stooks += 1
	# Stubble tufts between the rows.
	for k: int in int(length * width / 9.0):
		var p := c + u * _rng.randf_range(-length * 0.5, length * 0.5) + v * _rng.randf_range(-width * 0.5, width * 0.5)
		if _free(p, 0.4):
			_add(HAY, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.7, 1.0))
	# Drystone walls: the long side away from the road and one short end, each with a gate gap; segments slightly
	# out of line (a hand-built wall), a few left out (fallen).
	var sides: Array = [[v * (width * 0.5 + 1.4), u, length + 2.0], [u * ((length * 0.5 + 1.4) * (1.0 if seed > 0.5
		else -1.0)), v, width + 2.8]]
	for sd: Array in sides:
		var base: Vector2 = c + (sd[0] as Vector2)
		var along: Vector2 = sd[1]
		var span: float = sd[2]
		var n := int(span / WALL_LEN)
		var gate := _rng.randi_range(1, maxi(1, n - 2))
		for k: int in n:
			if k == gate or _rng.randf() < 0.08:
				continue
			var t := (k - (n - 1) * 0.5) * WALL_LEN
			var p := base + along * t
			var a := along.rotated(_rng.randf_range(-0.06, 0.06))
			if not (_free(p, 0.6) and _free(p + a * 1.1, 0.4) and _free(p - a * 1.1, 0.4)):
				continue
			_add(WALL, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.95, 1.05),
				fposmod(_yaw_along(a) + (PI if _rng.randf() < 0.5 else 0.0), TAU))
	# Round bales at two or three corners (inside the walls).
	var corners: Array[Vector2] = [u * length * 0.5 + v * width * 0.5, -u * length * 0.5 + v * width * 0.5,
		u * length * 0.5 - v * width * 0.5, -u * length * 0.5 - v * width * 0.5]
	var nb := 2 + int(seed * 2.0)
	for k: int in nb:
		var p := c + corners[(k + int(seed * 4.0)) % 4] * 0.82
		if _free(p, 1.2):
			_add(BALE, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.9, 1.08))
	plots.append(Vector4(c.x, c.y, _yaw_along(u), stooks))


# ---------------------------------------------------------------- moor rim

## Walks the 4 edges: noise gives each stretch an outcrop depth (heather, gorse, lichen stones this far into the map)
## or a bay (open stubble); a hay bale sits out on the moor now and then.
func _moor_rim() -> void:
	for edge: int in 4:
		var horizontal := edge < 2
		var sgn := -1.0 if edge % 2 == 0 else 1.0
		var half_along := _hx if horizontal else _hz
		var half_across := _hz if horizontal else _hx
		var t := -half_along + 1.0
		while t < half_along - 1.0:
			var out := _noise1(t, 12.0, 21.0 + edge * 5.0)
			var reach := lerpf(-0.6, RIM_REACH, out)
			if reach > 0.4:
				for _rep: int in 2:
					var inset := _rng.randf_range(0.25, reach)
					var p := _edge_pos(horizontal, sgn, t + _rng.randf_range(-1.0, 1.0), half_across - inset)
					if _blocked(p, 0.3) or _is_water(p) or _water_dist(p, 3.0) <= 2.0:
						continue
					var k := _rng.randf()
					if k < 0.5:
						_add(HEATHER, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.8, 1.2))
					elif k < 0.75:
						_add(GORSE, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.7, 1.05))
					elif k < 0.95:
						_add(LICHEN, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.8, 1.2))
			elif out < 0.2 and _rng.randf() < 0.12:
				var p := _edge_pos(horizontal, sgn, t, half_across - _rng.randf_range(2.0, 3.5))
				if _free(p, 1.4):
					_add(BALE, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.9, 1.05))
			t += _rng.randf_range(2.0, 3.0)


func _edge_pos(horizontal: bool, sgn: float, along: float, across: float) -> Vector2:
	return Vector2(along, sgn * across) if horizontal else Vector2(sgn * across, along)


# ---------------------------------------------------------------- crown isle

## Four standing stones in the moat, at the angles furthest from every crossing (a river arm's mouth only needs
## ~16 deg); a stone in a tight gap is smaller. The same picking as Thornwater's spires.
func _crown_isle() -> void:
	if _river == null or not _river.has_method(&"moat"):
		return
	var moat: Vector4 = _river.call(&"moat")
	if moat.z <= 0.0:
		return
	var centre := Vector2(moat.x, moat.y)
	var crossings: Array[float] = []
	var mouths: Array[float] = []
	for cr: Dictionary in _river.call(&"crossings"):
		var cv: Variant = cr.get("center", Vector3.ZERO)
		var c := Vector2((cv as Vector3).x, (cv as Vector3).z) if cv is Vector3 else (cv as Vector2)
		if c.distance_to(centre) < moat.z + 6.0:
			crossings.append((c - centre).angle())
	for line: Variant in _river.call(&"polylines"):
		var pl := line as PackedVector2Array
		for p: Vector2 in [pl[0], pl[pl.size() - 1]]:
			if p.distance_to(centre) < moat.z + 3.0:
				mouths.append((p - centre).angle())
	var chosen: Array[float] = []
	var clears: Array[float] = []
	for pick: int in 4:
		var best := -1.0
		var best_a := 0.0
		for k: int in 144:
			var a := k * TAU / 144.0
			var mouth_ok := true
			for m: float in mouths:
				if absf(angle_difference(a, m)) < deg_to_rad(16.0):
					mouth_ok = false
			if not mouth_ok:
				continue
			var clear := PI
			for bk: float in crossings:
				clear = minf(clear, absf(angle_difference(a, bk)))
			for ch: float in chosen:
				clear = minf(clear, absf(angle_difference(a, ch)) * 0.5)
			if clear > best:
				best = clear
				best_a = a
		if best < deg_to_rad(24.0):
			break
		chosen.append(best_a)
		clears.append(best)
	for k: int in chosen.size():
		var a := chosen[k]
		var p := centre + Vector2(cos(a), sin(a)) * moat.z
		var room := clampf(remap(clears[k], deg_to_rad(30.0), deg_to_rad(44.0), 0.0, 1.0), 0.0, 1.0)
		# The stone leans (mesh +X) toward the isle.
		_add(STONE, Vector3(p.x, WATER_Y, p.y), lerpf(0.85, 1.12, room) + _h(p.x, p.y) * 0.1,
			fposmod(_yaw_along(-Vector2(cos(a), sin(a))), TAU))


# ---------------------------------------------------------------- buildings placed on the decor

func _clear_existing_buildings() -> void:
	if not is_inside_tree():
		return
	for b: Node in get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D and (_level == null or _level.is_ancestor_of(b)):
			clear_area((b as Node3D).global_position, _radius_of(b), false)


func _radius_of(b: Node) -> float:
	return float(b.call(&"target_radius")) + 0.6 if b.has_method(&"target_radius") else 3.0


func _on_node_added(n: Node) -> void:
	if n is Node3D and n.is_in_group(&"buildings") and _level and _level.is_ancestor_of(n):
		_clear_for.call_deferred(n)


func _clear_for(n: Node) -> void:
	if is_instance_valid(n) and n.is_inside_tree():
		clear_area((n as Node3D).global_position, _radius_of(n), true)


## Hides (zero scale) every decor instance within `r` of `pos` (walls: within r + 1.2, their half length);
## `live` = also update the MultiMeshes.
func clear_area(pos: Vector3, r: float, live: bool = true) -> int:
	var hidden := 0
	for kind: String in _lists:
		if kind in FIXED_KINDS:
			continue
		var rr := r + (1.2 if kind == WALL else 0.0)
		var list: Array = _lists[kind]
		for i: int in list.size():
			var xf: Transform3D = list[i]
			if xf.basis.get_scale().x < 0.001:
				continue
			if Vector2(xf.origin.x - pos.x, xf.origin.z - pos.z).length() < rr:
				xf.basis = Basis().scaled(Vector3.ZERO)
				list[i] = xf
				hidden += 1
				if live and _mmis.has(kind):
					((_mmis[kind] as MultiMeshInstance3D).multimesh).set_instance_transform(i, xf)
	return hidden
