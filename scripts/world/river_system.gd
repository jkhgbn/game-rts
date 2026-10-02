class_name RiverSystem
extends Node3D
## The river "Hollowmere" (docs/design/map-fill.md 2, contract section 13, task 12.C1): deep water that blocks
## pathing, walkable fords and bridges, the Crown Isle moat. One node per map in group "river"; find it with
## `RiverSystem.instance(tree)` (null = no river on this map).
## - `setup(polylines, half_width, moat, crossings)`: centre lines (world x/z, downstream order), the water half width,
##   the moat ring Vector4(centre x, centre z, centre-line radius, half width) (radius 0 = none) and the crossings
##   ({id, name, kind, center, width, length, dir}; kinds &"bridge_road" / &"bridge_lane" (rectangles: `length` along
##   `dir`, `width` across) and &"ford" / &"steps" (circles of radius width / 2)).
## - Deep water = the river channels (counted only outside the moat's centre line, like the ground cut) and the moat
##   band, minus the ford / steps circles and the bridge decks. It is carved out of the navmesh by one
##   NavigationObstacle3D per water piece (affect_navigation_mesh, not carve: the agent radius keeps units 0.5 m off
##   the edge), so add this node under the NavigationRegion3D and call setup() BEFORE the first bake. No collider:
##   clicks, spells, fog and projectiles work over the water as over the ground.
## - Draws the water surfaces, trench walls and ford films with WaterMeshes (art/environment/water/, load-guarded,
##   else plain colours) and places the bridge / ford / steps models (art/environment/bridges/, load-guarded, else a
##   plain deck on each bridge). The ground itself is cut by the ground shader: feed it `shader_params()` through
##   `EnvProps.set_river(mat, params)`.
## - 5 Hz pass over "units": a unit in deep water (knock-back, avoidance push) is moved to the nearest navmesh point;
##   a unit in a ford / steps circle gets the modifier `terrain:ford` {move_speed_pct: FORD_SLOW} (removed 0.3 m out;
##   group "amphibious" exempt) while `ford_modifier_enabled` (TerrainSystem, step 12b, turns it off and applies
##   `terrain:ford` itself).

const WATER_Y := -0.35
const FORD_SLOW := -0.35
const FORD_MODIFIER := &"terrain:ford"
const AMPHIBIOUS_GROUP := &"amphibious"
const KIND_BRIDGE_ROAD := &"bridge_road"
const KIND_BRIDGE_LANE := &"bridge_lane"
const KIND_FORD := &"ford"
const KIND_STEPS := &"steps"
const MASK_SIZE := 240            ## mask_image(): 240 x 240 pixels...
const MASK_CELL := 0.5            ## ...of 0.5 m, pixel (0, 0) at world (-60, -60).
const MAP_HALF := 60.0
const PASS_INTERVAL := 0.2        ## The unit pass: 5 Hz.
const FORD_HYSTERESIS := 0.3      ## A slowed unit keeps the ford modifier until this far outside the circle.
const CARVE_Y := -0.5
const CARVE_HEIGHT := 3.0
const CIRCLE_SIDES := 48
const MIN_PIECE_AREA := 0.05      ## Clipping slivers smaller than this (m2) are dropped.
const FOAM_SLOTS := 16
const SHADER_BOX_REACH := 10.5    ## shader_params() river_box margin beyond the half width (12.V2 BOX_REACH).
const GRID_CELL := 2.0           ## The unit pass skips units in cells this wide that are far from water and fords.
const GRID_HALF := 64.0
const PLAYER_TEAM := 0            ## Unit.Team.PLAYER
const ENEMY_TEAM := 1             ## Unit.Team.ENEMY

const WATER_MESHES_PATH := "res://art/environment/water/water_meshes.gd"
const WATER_MAT_PATH := "res://art/environment/water/water_mat.tres"
const FORD_MAT_PATH := "res://art/environment/water/water_ford_mat.tres"
const BED_MAT_PATH := "res://art/environment/water/riverbed_mat.tres"
const MODEL_PATHS := {
	&"bridge_road": "res://art/environment/bridges/road_bridge.tscn",
	&"bridge_lane": "res://art/environment/bridges/lane_bridge.tscn",
	&"ford": "res://art/environment/bridges/ford_stones.tscn",
	&"steps": "res://art/environment/bridges/crown_steps.tscn",
}
const PLAIN_WATER_COLOR := Color(0.12, 0.34, 0.36)
const PLAIN_DECK_COLOR := Color(0.45, 0.36, 0.26)
const _SIM := preload("res://scripts/core/sim_mode.gd")   # Bot Lab sim mode (no water meshes / models)

## True: fords slow units (`terrain:ford`). TerrainSystem (step 12b) sets it false and writes that modifier itself.
var ford_modifier_enabled := true
## A point on the PLAYER's bank: bank_of() returns PLAYER on its side of the river (Crown Hollow: the player start).
var player_bank_point := Vector3(-36.0, 0.0, 36.0)
## False: setup() builds only the geometry and the carve (no meshes / models; tools and tests).
var build_visuals := true

var _polylines: Array[PackedVector2Array] = []
var _half_width := 2.5
var _moat := Vector4.ZERO
var _crossings: Array[Dictionary] = []
var _pieces: Array[PackedVector2Array] = []   # the carve polygons (deep water pieces)
var _piece_boxes: Array[Rect2] = []
var _line_boxes: Array[Rect2] = []            # polyline AABBs grown by the half width
var _divider := PackedVector2Array()          # bank split polygon (bank_of)
var _player_inside := true
var _mask: Image
var _foam_rocks := PackedVector4Array()
var _ford_units := {}                         # instance id -> Unit slowed by this node
var _ford_on_last := true
var _pass_left := 0.0
var _obstacles: Array[NavigationObstacle3D] = []
var _visuals: Node3D
var _near := PackedByteArray()                # GRID_CELL cells: 1 = water or a ford within reach (unit pass)
var _grid_n := 0
var _grid_half := GRID_HALF                   # the near grid's half extent (MT1: the running map's size + a margin)
var _ford_centers := PackedVector2Array()     # fords and steps (unit pass)
var _ford_radii := PackedFloat32Array()


## The map's RiverSystem, or null (no river on this map).
static func instance(tree: SceneTree) -> RiverSystem:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(&"river"):
		var r := node as RiverSystem
		if r and not r.is_queued_for_deletion():
			return r
	return null


func _init() -> void:
	add_to_group(&"river")
	if _SIM.enabled:
		build_visuals = false   # Bot Lab sim: geometry and carve only (docs/plan/bot-lab.md)


func _ready() -> void:
	add_to_group(&"river")
	_pass_left = PASS_INTERVAL


# ---------------------------------------------------------------- setup

## Builds the river (replaces a previous setup). See the class comment for the shapes.
func setup(polylines: Array[PackedVector2Array], half_width: float, moat: Vector4, crossings: Array[Dictionary]) -> void:
	_polylines.clear()
	for line in polylines:
		if line.size() >= 2:
			_polylines.append(line.duplicate())
	_half_width = maxf(half_width, 0.1)
	_moat = moat
	_crossings.clear()
	for c in crossings:
		_crossings.append(_normalized_crossing(c))
	_mask = null
	_foam_rocks = PackedVector4Array()
	_line_boxes.clear()
	for line in _polylines:
		var box := Rect2(line[0], Vector2.ZERO)
		for p in line:
			box = box.expand(p)
		_line_boxes.append(box.grow(_half_width))
	_ford_centers = PackedVector2Array()
	_ford_radii = PackedFloat32Array()
	for c in _crossings:
		if _is_circle(c):
			_ford_centers.append(_xz(c["center"]))
			_ford_radii.append(float(c["radius"]))
	_build_pieces()
	_build_divider()
	_build_near_grid()
	_build_obstacles()
	if build_visuals:
		_build_visuals()


# ---------------------------------------------------------------- queries (contract)

## True in deep water (not walkable): a river channel or the moat band, not a ford / steps circle, not a bridge deck.
func is_water(pos: Vector3) -> bool:
	return _is_water_2d(Vector2(pos.x, pos.z))


## True inside a ford or Crown Steps circle (the whole circle, banks included).
func is_ford(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	for c in _crossings:
		if _is_circle(c) and _in_crossing(c, p):
			return true
	return false


## True on a bridge deck rectangle (road or lane bridge).
func is_bridge(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	for c in _crossings:
		if not _is_circle(c) and _in_crossing(c, p):
			return true
	return false


## Metres from `pos` to the nearest deep water (0 in deep water; INF without water). `max_distance`: only water
## closer than this is measured (INF beyond it: a cheap "is there water within x m" test).
func distance_to_water(pos: Vector3, max_distance: float = INF) -> float:
	var p := Vector2(pos.x, pos.z)
	if _is_water_2d(p):
		return 0.0
	var best := max_distance
	for i in _pieces.size():
		if _rect_distance(_piece_boxes[i], p) >= best:
			continue
		best = minf(best, _polygon_edge_distance(_pieces[i], p))
	return best if best < max_distance else INF


## Metres from `pos` to the nearest crossing shape (0 inside a ford / steps circle or on a bridge deck; INF when
## there is none).
func distance_to_crossing(pos: Vector3) -> float:
	var p := Vector2(pos.x, pos.z)
	var best := INF
	for c in _crossings:
		best = minf(best, _crossing_distance(c, p))
	return best


## PLAYER (0) or ENEMY (1): the bank `pos` is on; -1 in deep water and on the isle (inside the moat's centre line).
func bank_of(pos: Vector3) -> int:
	var p := Vector2(pos.x, pos.z)
	if _is_water_2d(p):
		return -1
	if _moat.z > 0.0 and p.distance_to(Vector2(_moat.x, _moat.y)) < _moat.z:
		return -1
	if _divider.size() < 3:
		return PLAYER_TEAM if (p.x < 0.0) == (player_bank_point.x < 0.0) else ENEMY_TEAM
	var inside := Geometry2D.is_point_in_polygon(p, _divider)
	return PLAYER_TEAM if inside == _player_inside else ENEMY_TEAM


## Every crossing (copies): {id, name, kind, center, width, length, dir} (+ `radius` for fords / steps).
func crossings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _crossings:
		out.append(c.duplicate())
	return out


## The crossing with this id (a copy), or {}.
func crossing(id: StringName) -> Dictionary:
	for c in _crossings:
		if c["id"] == id:
			return c.duplicate()
	return {}


## `pos` itself on land; in deep water the nearest point just outside it (on a bank, a ford or a bridge).
func nearest_land(pos: Vector3) -> Vector3:
	var p := Vector2(pos.x, pos.z)
	if not _is_water_2d(p):
		return pos
	var best := p
	var best_d := INF
	for i in _pieces.size():
		var poly := _pieces[i]
		if not _piece_boxes[i].grow(0.01).has_point(p) or not Geometry2D.is_point_in_polygon(p, poly):
			continue
		for k in poly.size():
			var q := Geometry2D.get_closest_point_to_segment(p, poly[k], poly[(k + 1) % poly.size()])
			var d := p.distance_to(q)
			if d >= best_d:
				continue
			var out := (q - p).normalized() if d > 0.0001 else Vector2.RIGHT
			var land := q + out * 0.05
			if not _is_water_2d(land):
				best_d = d
				best = land
	if best_d == INF:   # not inside a carve piece (a sliver): a straight step out of the channel
		for step in range(1, 40):
			for a in 16:
				var q := p + Vector2.from_angle(TAU * float(a) / 16.0) * 0.25 * float(step)
				if not _is_water_2d(q):
					return Vector3(q.x, pos.y, q.y)
	return Vector3(best.x, pos.y, best.y)


## The deep-water pieces (the carve polygons, world x/z).
func water_polygons() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly in _pieces:
		out.append(poly.duplicate())
	return out


## 240 x 240 RGB8, 0.5 m per pixel, pixel (i, j) = world (-60 + 0.5 (i + 0.5), -60 + 0.5 (j + 0.5)): R 255 = deep
## water, G 255 = ford / steps circle, B 255 = bridge deck. Built once, cached (callers must not change it).
func mask_image() -> Image:
	if _mask:
		return _mask
	# MT1: the mask covers the running map (MapInfo): 240 x 240 on a 120 m map, (W / 0.5) x (D / 0.5) on a W x D one.
	var mw := maxi(2, int(ceil(MapInfo.size_x / MASK_CELL)))
	var mh := maxi(2, int(ceil(MapInfo.size_z / MASK_CELL)))
	var ox := float(mw) * MASK_CELL * 0.5
	var oz := float(mh) * MASK_CELL * 0.5
	var data := PackedByteArray()
	data.resize(mw * mh * 3)
	data.fill(0)
	var boxes: Array[Rect2] = []
	boxes.append_array(_piece_boxes)
	for c in _crossings:
		var r := _crossing_reach(c)
		var cp := _xz(c["center"])
		boxes.append(Rect2(cp - Vector2(r, r), Vector2(r, r) * 2.0))
	var done := {}
	for box in boxes:
		var i0 := clampi(int(floor((box.position.x + ox) / MASK_CELL)), 0, mw - 1)
		var i1 := clampi(int(ceil((box.end.x + ox) / MASK_CELL)), 0, mw - 1)
		var j0 := clampi(int(floor((box.position.y + oz) / MASK_CELL)), 0, mh - 1)
		var j1 := clampi(int(ceil((box.end.y + oz) / MASK_CELL)), 0, mh - 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var idx := j * mw + i
				if done.has(idx):
					continue
				done[idx] = true
				var p := Vector2(-ox + MASK_CELL * (float(i) + 0.5), -oz + MASK_CELL * (float(j) + 0.5))
				var at := Vector3(p.x, 0.0, p.y)
				if _is_water_2d(p):
					data[idx * 3] = 255
				if is_ford(at):
					data[idx * 3 + 1] = 255
				if is_bridge(at):
					data[idx * 3 + 2] = 255
	_mask = Image.create_from_data(mw, mh, false, Image.FORMAT_RGB8, data)
	return _mask


## The ground shader's river uniforms (12.V2; keys = uniform names, the same dictionary as GroundParams.river()):
## river_segs (PackedVector4Array, 16 slots), river_count, river_half_width, river_box (perf box: the segments grown
## by the half width + 10.5 m), moat, fords (PackedVector4Array, 4 slots of (x, z, r, 0)), ford_count.
func shader_params() -> Dictionary:
	var segs := PackedVector4Array()
	for line in _polylines:
		for i in line.size() - 1:
			segs.append(Vector4(line[i].x, line[i].y, line[i + 1].x, line[i + 1].y))
	var count := mini(segs.size(), 16)
	segs.resize(16)
	var box := Vector4.ZERO
	if count > 0:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for i in count:
			for q: Vector2 in [Vector2(segs[i].x, segs[i].y), Vector2(segs[i].z, segs[i].w)]:
				lo = lo.min(q)
				hi = hi.max(q)
		var m := _half_width + SHADER_BOX_REACH
		box = Vector4(lo.x - m, lo.y - m, hi.x + m, hi.y + m)
	var fords := PackedVector4Array()
	for c in _crossings:
		if _is_circle(c) and fords.size() < 4:
			var cp := _xz(c["center"])
			fords.append(Vector4(cp.x, cp.y, float(c["radius"]), 0.0))
	var n := fords.size()
	fords.resize(4)
	return {
		&"river_segs": segs,
		&"river_count": count,
		&"river_half_width": _half_width,
		&"river_box": box,
		&"moat": _moat,
		&"fords": fords,
		&"ford_count": n,
	}


## Adds foam circles (x, z, radius, 0) for the water materials (bridge piers, the Drowned Barge...); at most 16 in
## total, later ones dropped.
func add_foam_rocks(rocks: PackedVector4Array) -> void:
	for r in rocks:
		if _foam_rocks.size() < FOAM_SLOTS:
			_foam_rocks.append(r)
	_apply_water_material_data()


## The polylines, half width and moat of setup() (read only).
func polylines() -> Array[PackedVector2Array]:
	return _polylines.duplicate()


func half_width() -> float:
	return _half_width


func moat() -> Vector4:
	return _moat


# ---------------------------------------------------------------- the unit pass (5 Hz)

func _physics_process(delta: float) -> void:
	_pass_left -= delta
	if _pass_left > 0.0:
		return
	_pass_left = PASS_INTERVAL
	unit_pass()


## One pass over "units" (push-out and ford slow). Runs by itself at 5 Hz; public for tests.
func unit_pass() -> void:
	if not is_inside_tree():
		return
	var slow_on := ford_modifier_enabled
	if not slow_on and _ford_on_last:
		_release_ford_units()
	_ford_on_last = slow_on
	var map_rid := RID()
	var tracking := not _ford_units.is_empty()
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null:
			continue
		var gp := u.global_position
		var ci := int((gp.x + _grid_half) / GRID_CELL)
		var cj := int((gp.z + _grid_half) / GRID_CELL)
		var near := ci >= 0 and cj >= 0 and ci < _grid_n and cj < _grid_n and _near[cj * _grid_n + ci] != 0
		if not near and not tracking:
			continue   # far from any water and ford: the common case, nothing to do
		var id := u.get_instance_id()
		var tracked := _ford_units.has(id)
		if not near and not tracked:
			continue
		if not u.is_alive():
			if tracked:
				u.remove_modifier(FORD_MODIFIER)
				_ford_units.erase(id)
			continue
		var p := Vector2(gp.x, gp.z)
		if near and _is_water_2d(p):
			if not map_rid.is_valid():
				map_rid = _nav_map()
			_push_out(u, gp, map_rid)
			gp = u.global_position
			p = Vector2(gp.x, gp.z)
		if not slow_on:
			continue
		var inside := false
		if not u.is_in_group(AMPHIBIOUS_GROUP):
			var extra := FORD_HYSTERESIS if tracked else 0.0
			for k in _ford_centers.size():
				if p.distance_to(_ford_centers[k]) < _ford_radii[k] + extra:
					inside = true
					break
		if inside and not tracked:
			u.add_modifier(FORD_MODIFIER, {"move_speed_pct": FORD_SLOW})
			_ford_units[id] = u
		elif tracked and not inside:
			u.remove_modifier(FORD_MODIFIER)
			_ford_units.erase(id)
	for id: int in _ford_units.keys():
		if not is_instance_valid(_ford_units[id]):
			_ford_units.erase(id)


func _release_ford_units() -> void:
	for id: int in _ford_units.keys():
		var u: Variant = _ford_units[id]
		if is_instance_valid(u):
			(u as Unit).remove_modifier(FORD_MODIFIER)
	_ford_units.clear()


func _push_out(u: Unit, gp: Vector3, map_rid: RID) -> void:
	var q := Vector3.INF
	if map_rid.is_valid() and NavigationServer3D.map_get_iteration_id(map_rid) > 0:
		q = NavigationServer3D.map_get_closest_point(map_rid, gp)
		if _is_water_2d(Vector2(q.x, q.z)) or Vector2(q.x - gp.x, q.z - gp.z).length() > 8.0:
			q = Vector3.INF
	if q == Vector3.INF:
		q = nearest_land(gp)
	u.global_position = Vector3(q.x, gp.y, q.z)
	u.reset_physics_interpolation()


func _nav_map() -> RID:
	var region := get_parent() as NavigationRegion3D
	if region:
		return region.get_navigation_map()
	return get_world_3d().navigation_map if get_world_3d() else RID()


# ---------------------------------------------------------------- geometry

func _is_water_2d(p: Vector2) -> bool:
	if not _in_channel(p):
		return false
	for c in _crossings:
		if _in_crossing(c, p):
			return false
	return true


## In a river channel (outside the moat's centre line) or in the moat band; crossings not subtracted.
func _in_channel(p: Vector2) -> bool:
	var outside_moat := true
	if _moat.z > 0.0:
		var r := p.distance_to(Vector2(_moat.x, _moat.y))
		if absf(r - _moat.z) < _moat.w:
			return true
		outside_moat = r > _moat.z
	if not outside_moat:
		return false
	for i in _polylines.size():
		if not _line_boxes[i].has_point(p):
			continue
		var line := _polylines[i]
		for k in line.size() - 1:
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[k], line[k + 1])) < _half_width:
				return true
	return false


func _normalized_crossing(src: Dictionary) -> Dictionary:
	var c := src.duplicate()
	c["id"] = StringName(str(src.get("id", "")))
	c["name"] = str(src.get("name", String(c["id"])))
	c["kind"] = StringName(str(src.get("kind", KIND_FORD)))
	var center: Variant = src.get("center", Vector3.ZERO)
	if center is Vector2:
		center = Vector3((center as Vector2).x, 0.0, (center as Vector2).y)
	c["center"] = Vector3((center as Vector3).x, 0.0, (center as Vector3).z)
	c["width"] = float(src.get("width", 6.0))
	c["length"] = float(src.get("length", c["width"]))
	var dir: Variant = src.get("dir", Vector3.FORWARD)
	if dir is Vector2:
		dir = Vector3((dir as Vector2).x, 0.0, (dir as Vector2).y)
	var d := Vector3((dir as Vector3).x, 0.0, (dir as Vector3).z)
	c["dir"] = d.normalized() if d.length_squared() > 1e-6 else Vector3.FORWARD
	if _is_circle(c):
		c["radius"] = float(c["width"]) * 0.5
	return c


static func _is_circle(c: Dictionary) -> bool:
	return c["kind"] == KIND_FORD or c["kind"] == KIND_STEPS


static func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _in_crossing(c: Dictionary, p: Vector2) -> bool:
	var d := p - _xz(c["center"])
	if _is_circle(c):
		return d.length() < float(c["radius"])
	var along := _xz(c["dir"])
	var across := Vector2(-along.y, along.x)
	return absf(d.dot(along)) <= float(c["length"]) * 0.5 and absf(d.dot(across)) <= float(c["width"]) * 0.5


func _crossing_distance(c: Dictionary, p: Vector2) -> float:
	var d := p - _xz(c["center"])
	if _is_circle(c):
		return maxf(0.0, d.length() - float(c["radius"]))
	var along := _xz(c["dir"])
	var across := Vector2(-along.y, along.x)
	var dx := maxf(0.0, absf(d.dot(along)) - float(c["length"]) * 0.5)
	var dy := maxf(0.0, absf(d.dot(across)) - float(c["width"]) * 0.5)
	return Vector2(dx, dy).length()


## Half the largest extent of a crossing (its reach from the centre).
func _crossing_reach(c: Dictionary) -> float:
	if _is_circle(c):
		return float(c["radius"])
	return Vector2(float(c["length"]), float(c["width"])).length() * 0.5


func _crossing_polygon(c: Dictionary) -> PackedVector2Array:
	var cp := _xz(c["center"])
	if _is_circle(c):
		return _circle_polygon(cp, float(c["radius"]) + 0.01, CIRCLE_SIDES)
	var along := _xz(c["dir"]) * float(c["length"]) * 0.5
	var across := Vector2(-_xz(c["dir"]).y, _xz(c["dir"]).x) * float(c["width"]) * 0.5
	return PackedVector2Array([cp - along - across, cp + along - across, cp + along + across, cp - along + across])


static func _circle_polygon(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in sides:
		out.append(center + Vector2.from_angle(TAU * float(i) / float(sides)) * radius)
	return out


## Annular sector between angles a0 and a1 (radians, a1 > a0) of the moat band.
func _sector_polygon(a0: float, a1: float) -> PackedVector2Array:
	var c := Vector2(_moat.x, _moat.y)
	var n := maxi(2, int(ceil((a1 - a0) / deg_to_rad(2.5))))
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / float(n))
		outer.append(c + Vector2.from_angle(a) * (_moat.z + _moat.w))
		inner.append(c + Vector2.from_angle(a) * (_moat.z - _moat.w))
	inner.reverse()
	outer.append_array(inner)
	return outer


static func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		s += a.x * b.y - b.x * a.y
	return absf(s) * 0.5


## `polys` minus `cutter`; holes (a result polygon inside another one) are dropped.
static func _subtract(polys: Array[PackedVector2Array], cutter: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly in polys:
		var parts: Array[PackedVector2Array] = Geometry2D.clip_polygons(poly, cutter)
		for k in parts.size():
			var hole := false
			for m in parts.size():
				if m != k and Geometry2D.is_point_in_polygon(parts[k][0], parts[m]):
					hole = true
					break
			if not hole:
				out.append(parts[k])
	return out


func _build_pieces() -> void:
	var raw: Array[PackedVector2Array] = []
	var mc := Vector2(_moat.x, _moat.y)
	var disk := _circle_polygon(mc, _moat.z, 128) if _moat.z > 0.0 else PackedVector2Array()
	for line in _polylines:
		var strips: Array[PackedVector2Array] = Geometry2D.offset_polyline(line, _half_width,
				Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		if disk.is_empty():
			raw.append_array(strips)
		else:
			raw.append_array(_subtract(strips, disk))
	if _moat.z > 0.0 and _moat.w > 0.0:
		# Sectors between the crossings that sit on the moat (each sector then loses its two half crossings).
		var angles: Array[float] = []
		for c in _crossings:
			var cp := _xz(c["center"])
			if absf(cp.distance_to(mc) - _moat.z) < _moat.w + 1.0:
				angles.append(fposmod((cp - mc).angle(), TAU))
		if angles.size() < 2:
			angles = [0.0, PI * 0.5, PI, PI * 1.5]
		angles.sort()
		for i in angles.size():
			var a0 := angles[i]
			var a1 := angles[(i + 1) % angles.size()]
			if a1 <= a0:
				a1 += TAU
			if a1 - a0 > PI:   # keep every sector a simple, clearly convex-ish shape
				var mid := (a0 + a1) * 0.5
				raw.append(_sector_polygon(a0, mid))
				raw.append(_sector_polygon(mid, a1))
			else:
				raw.append(_sector_polygon(a0, a1))
	for c in _crossings:
		raw = _subtract(raw, _crossing_polygon(c))
	_pieces.clear()
	_piece_boxes.clear()
	for poly in raw:
		if poly.size() < 3 or _area(poly) < MIN_PIECE_AREA:
			continue
		_pieces.append(poly)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		_piece_boxes.append(box)


## The bank split: the river line (polylines joined along the moat) extended far past both ends and closed on one
## side. bank_of() compares a point's side with `player_bank_point`'s.
func _build_divider() -> void:
	_divider = PackedVector2Array()
	var path := PackedVector2Array()
	var mc := Vector2(_moat.x, _moat.y)
	for i in _polylines.size():
		var line := _polylines[i]
		if i > 0 and _moat.z > 0.0 and path.size() > 0:
			var a0 := (path[path.size() - 1] - mc).angle()
			var a1 := (line[0] - mc).angle()
			while a1 >= a0:
				a1 -= TAU
			var n := maxi(2, int(ceil((a0 - a1) / deg_to_rad(5.0))))
			for k in range(1, n):
				path.append(mc + Vector2.from_angle(lerpf(a0, a1, float(k) / float(n))) * _moat.z)
		path.append_array(line)
	if path.size() < 2:
		return
	var d0 := (path[1] - path[0]).normalized()
	var dn := (path[path.size() - 1] - path[path.size() - 2]).normalized()
	var e0 := path[0] - d0 * 1000.0
	var en := path[path.size() - 1] + dn * 1000.0
	var poly := PackedVector2Array([e0])
	poly.append_array(path)
	poly.append(en)
	poly.append(en + Vector2(-dn.y, dn.x) * 3000.0)
	poly.append(e0 + Vector2(-d0.y, d0.x) * 3000.0)
	_divider = poly
	_player_inside = Geometry2D.is_point_in_polygon(Vector2(player_bank_point.x, player_bank_point.z), _divider)


## Flags the GRID_CELL cells a unit can stand in while in deep water or (hysteresis included) a ford circle.
func _build_near_grid() -> void:
	_grid_half = maxf(GRID_HALF, ceil(MapInfo.half_max() / GRID_CELL) * GRID_CELL + 4.0)   # MT1: bigger maps
	_grid_n = int(_grid_half * 2.0 / GRID_CELL)
	_near = PackedByteArray()
	_near.resize(_grid_n * _grid_n)
	_near.fill(0)
	var margin := GRID_CELL * 0.75 + FORD_HYSTERESIS + 0.2   # > half the cell diagonal (1.41) + hysteresis
	var mc := Vector2(_moat.x, _moat.y)
	for j in _grid_n:
		for i in _grid_n:
			var c := Vector2(-_grid_half + GRID_CELL * (float(i) + 0.5), -_grid_half + GRID_CELL * (float(j) + 0.5))
			var hit := false
			if _moat.z > 0.0 and absf(c.distance_to(mc) - _moat.z) < _moat.w + margin:
				hit = true
			for k in _ford_centers.size():
				if not hit and c.distance_to(_ford_centers[k]) < _ford_radii[k] + margin:
					hit = true
			for n in _polylines.size():
				if hit or not _line_boxes[n].grow(margin).has_point(c):
					continue
				var line := _polylines[n]
				for k in line.size() - 1:
					if c.distance_to(Geometry2D.get_closest_point_to_segment(c, line[k], line[k + 1])) < _half_width + margin:
						hit = true
						break
			if hit:
				_near[j * _grid_n + i] = 1


func _build_obstacles() -> void:
	for o in _obstacles:
		if is_instance_valid(o):
			o.queue_free()
	_obstacles.clear()
	for i in _pieces.size():
		var obstacle := NavigationObstacle3D.new()
		obstacle.name = "WaterCarve%d" % i
		obstacle.radius = 0.0
		obstacle.height = CARVE_HEIGHT
		obstacle.avoidance_enabled = false
		obstacle.affect_navigation_mesh = true
		obstacle.carve_navigation_mesh = false
		var verts := PackedVector3Array()
		for q in _pieces[i]:
			verts.append(Vector3(q.x, 0.0, q.y))
		obstacle.vertices = verts
		obstacle.position = Vector3(0.0, CARVE_Y, 0.0)
		add_child(obstacle)
		_obstacles.append(obstacle)


func _rect_distance(box: Rect2, p: Vector2) -> float:
	var dx := maxf(0.0, maxf(box.position.x - p.x, p.x - box.end.x))
	var dy := maxf(0.0, maxf(box.position.y - p.y, p.y - box.end.y))
	return Vector2(dx, dy).length()


static func _polygon_edge_distance(poly: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for k in poly.size():
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, poly[k], poly[(k + 1) % poly.size()])))
	return best


# ---------------------------------------------------------------- visuals

func _build_visuals() -> void:
	if _visuals and is_instance_valid(_visuals):
		_visuals.queue_free()
	_visuals = Node3D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	if ResourceLoader.exists(WATER_MESHES_PATH) and ResourceLoader.exists(WATER_MAT_PATH) \
			and ResourceLoader.exists(FORD_MAT_PATH) and ResourceLoader.exists(BED_MAT_PATH):
		_build_art_water(load(WATER_MESHES_PATH) as GDScript)
	else:
		_build_plain_water()
	_place_models()
	_apply_water_material_data()


## Water surfaces, ford films and trench walls with WaterMeshes (the 12.V1 conventions, water_test_strip.gd).
func _build_art_water(wm: GDScript) -> void:
	var mc := Vector2(_moat.x, _moat.y)
	var has_moat := _moat.z > 0.0 and _moat.w > 0.0
	var mr := _moat.z
	var mw := _moat.w
	var hw := _half_width
	var lines := _polylines
	# Where each river meets the moat: rivers ending there flow in, rivers starting there flow out.
	var in_angle := INF
	var out_angle := INF
	var in_length := 0.0
	for line in lines:
		if not has_moat:
			break
		if absf(line[line.size() - 1].distance_to(mc) - mr) < 0.5 and in_angle == INF:
			in_angle = rad_to_deg(fposmod((line[line.size() - 1] - mc).angle(), TAU))
			in_length = _path_length(line)
		elif absf(line[0].distance_to(mc) - mr) < 0.5 and out_angle == INF:
			out_angle = rad_to_deg(fposmod((line[0] - mc).angle(), TAU))
	var in_moat := func(p: Vector2) -> float:
		return 0.0 if has_moat and p.distance_to(mc) < mr + mw + 0.3 else 1.0
	var in_river := func(p: Vector2) -> float:
		if p.distance_to(mc) <= mr:
			return 1.0
		for l: PackedVector2Array in lines:
			if float(wm.call(&"distance_to_path", l, p)) < hw + 0.35:
				return 0.0
		return 1.0
	# Moat paths (UV.x continues the inflow river's flow).
	var moat_paths: Array[PackedVector2Array] = []
	var moat_len := 0.0
	if has_moat:
		if in_angle != INF and out_angle != INF:
			var out_w := out_angle
			while out_w >= in_angle:
				out_w -= 360.0
			var out_e := out_angle
			while out_e <= in_angle:
				out_e += 360.0
			var w_path: PackedVector2Array = wm.call(&"arc_path", mc, mr, in_angle, out_w, 0.6)
			var e_path: PackedVector2Array = wm.call(&"arc_path", mc, mr, in_angle, out_e, 0.6)
			moat_paths.append(w_path)
			moat_paths.append(e_path)
			var radial_w := PackedVector2Array([w_path[0] - mc, w_path[w_path.size() - 1] - mc])
			var radial_e := PackedVector2Array([e_path[0] - mc, e_path[e_path.size() - 1] - mc])
			_add_mesh("MoatWaterW", wm.call(&"channel_surface", w_path, mw, WATER_Y, in_length, 0.6, in_river, true, radial_w))
			_add_mesh("MoatWaterE", wm.call(&"channel_surface", e_path, mw, WATER_Y, in_length, 0.6, in_river, false, radial_e))
			moat_len = _path_length(w_path)
		else:
			var ring: PackedVector2Array = wm.call(&"arc_path", mc, mr, 0.0, 360.0, 0.6)
			moat_paths.append(ring)
			_add_mesh("MoatWater", wm.call(&"channel_surface", ring, mw, WATER_Y, 0.0, 0.6, in_river))
		var ring_walls: PackedVector2Array = wm.call(&"arc_path", mc, mr, 0.0, 360.0, 0.6)
		var skip_moat := func(p: Vector2) -> bool:
			if p.distance_to(mc) <= mr:
				return false
			for l: PackedVector2Array in lines:
				if float(wm.call(&"distance_to_path", l, p)) < hw - 0.05:
					return true
			return false
		_add_mesh("MoatWalls", wm.call(&"channel_walls", ring_walls, mw, skip_moat, -0.6, 0.8, 99))
	# Rivers: 4 mm under the moat where they overlap (the ring wins); no bank foam across a mouth.
	var skip_river := func(p: Vector2) -> bool: return has_moat and p.distance_to(mc) < mr + mw - 0.05
	var river_s0: Array[float] = []
	for i in lines.size():
		var line := lines[i]
		var s0 := 0.0
		if has_moat and absf(line[0].distance_to(mc) - mr) < 0.5:
			s0 = in_length + moat_len
		river_s0.append(s0)
		_add_mesh("RiverWater%d" % i, wm.call(&"channel_surface", line, hw, WATER_Y - 0.004, s0, 1.0, in_moat))
		_add_mesh("RiverWalls%d" % i, wm.call(&"channel_walls", line, hw, skip_river, -0.6, 0.8, i + 1))
	# Ford films and their end walls, on the channel each circle sits on.
	for c in _crossings:
		if not _is_circle(c):
			continue
		var cp := _xz(c["center"])
		var r := float(c["radius"])
		var on_moat := has_moat and absf(cp.distance_to(mc) - mr) < mw + 0.5
		var path := PackedVector2Array()
		var width := hw
		var s0 := 0.0
		if on_moat:
			width = mw
			s0 = in_length
			var best := INF
			for mp in moat_paths:
				var d := float(wm.call(&"distance_to_path", mp, cp))
				if d < best:
					best = d
					path = mp
		else:
			var best := INF
			for i in lines.size():
				var d := float(wm.call(&"distance_to_path", lines[i], cp))
				if d < best:
					best = d
					path = lines[i]
					s0 = river_s0[i]
		if path.size() < 2:
			continue
		var tag := String(c["id"]).to_pascal_case()
		_add_mesh("Film" + tag, wm.call(&"ford_film", path, width, cp, r, 0.02, s0))
		_add_mesh("Ends" + tag, wm.call(&"ford_end_walls", path, width, cp, r, -0.6))


## No art: flat plain-colour water over every channel (crossings included: the ground covers the fords).
func _build_plain_water() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLAIN_WATER_COLOR
	mat.roughness = 0.3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var polys: Array[PackedVector2Array] = []
	for line in _polylines:
		polys.append_array(Geometry2D.offset_polyline(line, _half_width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND))
	if _moat.z > 0.0 and _moat.w > 0.0:
		for i in 4:
			polys.append(_sector_polygon(PI * 0.5 * float(i), PI * 0.5 * float(i + 1)))
	for poly in polys:
		var tris := Geometry2D.triangulate_polygon(poly)
		for k in range(0, tris.size() - 2, 3):
			var v := [poly[tris[k]], poly[tris[k + 1]], poly[tris[k + 2]]]
			var a := Vector3(v[0].x, WATER_Y, v[0].y)
			var b := Vector3(v[1].x, WATER_Y, v[1].y)
			var c := Vector3(v[2].x, WATER_Y, v[2].y)
			if (b - a).cross(c - a).y > 0.0:
				var t := b
				b = c
				c = t
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)
		_add_mesh("PlainWater", mesh)


## The bridge / ford / steps models (12.V3 / 12.V4), load-guarded; a plain deck on bridges without a model.
func _place_models() -> void:
	var mc3 := Vector3(_moat.x, 0.0, _moat.y)
	var lane_rocks := PackedVector4Array()
	for c in _crossings:
		var kind: StringName = c["kind"]
		var path: String = MODEL_PATHS.get(kind, "")
		var model: Node3D = null
		if path != "" and ResourceLoader.exists(path):
			var scene := load(path) as PackedScene
			model = scene.instantiate() as Node3D if scene else null
		if model:
			model.name = "Model" + String(c["id"]).to_pascal_case()
			_visuals.add_child(model)
			if model.has_method(&"place_on_moat"):
				model.call(&"place_on_moat", c["center"], mc3)
				var rocks: Variant = model.call(&"foam_rocks", c["center"], mc3) if model.has_method(&"foam_rocks") else null
				if rocks is PackedVector4Array:
					for k in mini(2, (rocks as PackedVector4Array).size()):   # the two cutwaters
						lane_rocks.append((rocks as PackedVector4Array)[k])
			elif model.has_method(&"place_crossing"):
				model.call(&"place_crossing", c["center"], c["dir"], mc3)
			else:
				model.position = c["center"]
		elif not _is_circle(c):
			_add_plain_deck(c)
	if not lane_rocks.is_empty():
		add_foam_rocks(lane_rocks)


func _add_plain_deck(c: Dictionary) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(float(c["width"]), 0.12, float(c["length"]))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLAIN_DECK_COLOR
	mat.roughness = 0.9
	box.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Deck" + String(c["id"]).to_pascal_case()
	mi.mesh = box
	var z: Vector3 = c["dir"]
	mi.transform = Transform3D(Basis(Vector3.UP.cross(z), Vector3.UP, z), c["center"] + Vector3(0.0, -0.03, 0.0))
	_visuals.add_child(mi)


func _add_mesh(node_name: String, mesh: Variant) -> MeshInstance3D:
	if not mesh is Mesh:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_visuals.add_child(mi)
	return mi


## The shared data both water materials read (12.V1): the ford circles and the foam rocks.
func _apply_water_material_data() -> void:
	if not build_visuals:
		return
	var fords := PackedVector4Array()
	for c in _crossings:
		if _is_circle(c) and fords.size() < 4:
			var cp := _xz(c["center"])
			fords.append(Vector4(cp.x, cp.y, float(c["radius"]), 0.0))
	var n_fords := fords.size()
	fords.resize(4)
	var rocks := _foam_rocks.duplicate()
	var n_rocks := rocks.size()
	rocks.resize(FOAM_SLOTS)
	var detail := 0.0 if _map_detail() == &"low" else 1.0
	for path in [WATER_MAT_PATH, FORD_MAT_PATH]:
		if not ResourceLoader.exists(path):
			continue
		var mat := load(path) as ShaderMaterial
		if mat == null:
			continue
		mat.set_shader_parameter(&"fords", fords)
		mat.set_shader_parameter(&"ford_count", n_fords)
		mat.set_shader_parameter(&"foam_rocks", rocks)
		mat.set_shader_parameter(&"foam_rock_count", n_rocks)
		mat.set_shader_parameter(&"detail", detail)


## Settings "Map detail" (`GameSettings.map_detail`, &"high" / &"low"; high while the setting does not exist yet).
static func _map_detail() -> StringName:
	const SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
	if not ResourceLoader.exists(SETTINGS_PATH):
		return &"high"
	var s: Script = load(SETTINGS_PATH)
	if s == null:
		return &"high"
	for m: Dictionary in s.get_script_method_list():
		if String(m.get("name", "")) == "ensure_read":
			s.call(&"ensure_read")
			break
	var v: Variant = s.get(&"map_detail")
	return StringName(str(v)) if v != null else &"high"


static func _path_length(path: PackedVector2Array) -> float:
	var l := 0.0
	for i in path.size() - 1:
		l += path[i].distance_to(path[i + 1])
	return l
