class_name MapInfo
extends RefCounted
## The playable map's size (docs/design/map-production.md 2.8, tool task MT1). One per running level: the level sets it
## at the start of its `_ready` (main.gd `_map_size()`: Crown Hollow / mission 1 = 120 x 120, a LayoutLevel = its
## layout's `W x D`), before the fog, the BuildGrid, the river, the minimap and the camera read it. Static state, so
## systems reach it without a level reference; a level that never calls `setup` reads the 120 m default.
## Coordinates: metres, the map is centred on (0, 0): x in [-half_x, half_x], z in [-half_z, half_z].

const DEFAULT_SIZE := 120.0

static var size_x := DEFAULT_SIZE   ## Map width (x) in metres.
static var size_z := DEFAULT_SIZE   ## Map depth (z) in metres.
static var map_id := &""            ## The layout id when the level came from a MapLayout, else "".


## Sets the running map's size (call before anything that reads it: fog, BuildGrid, river, minimap, camera).
static func setup(width: float, depth: float, id: StringName = &"") -> void:
	size_x = maxf(width, 8.0)
	size_z = maxf(depth, 8.0)
	map_id = id


## Back to the 120 m default (tests that build a level by hand).
static func reset() -> void:
	setup(DEFAULT_SIZE, DEFAULT_SIZE)


static func half_x() -> float:
	return size_x * 0.5


static func half_z() -> float:
	return size_z * 0.5


## The larger half extent (square things: the minimap view, camera framing).
static func half_max() -> float:
	return maxf(size_x, size_z) * 0.5


## The larger edge (the minimap letterboxes a non-square map inside this square).
static func size_max() -> float:
	return maxf(size_x, size_z)


## The map rectangle on the ground: Rect2(x, z, width, depth).
static func bounds() -> Rect2:
	return Rect2(-size_x * 0.5, -size_z * 0.5, size_x, size_z)


## True when `pos` lies inside the map, `margin` metres in from the edge.
static func contains(pos: Vector3, margin: float = 0.0) -> bool:
	return absf(pos.x) <= size_x * 0.5 - margin and absf(pos.z) <= size_z * 0.5 - margin


## `pos` clamped into the map, `margin` metres in from the edge (y kept).
static func clamp_point(pos: Vector3, margin: float = 0.0) -> Vector3:
	var hx := maxf(0.0, size_x * 0.5 - margin)
	var hz := maxf(0.0, size_z * 0.5 - margin)
	return Vector3(clampf(pos.x, -hx, hx), pos.y, clampf(pos.z, -hz, hz))
