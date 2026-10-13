class_name UnitGrid
extends Node
## P1 (wave-strike.md 14.2): a uniform CELL m spatial hash of the "units" group, so auto-aggro scans
## (Unit._find_nearest_enemy) only look at the cells within their search radius instead of every unit.
## Opt-in per level: a level that wants it calls `UnitGrid.ensure(level)` (or adds a UnitGrid node); no grid in the
## tree = Unit keeps its old full scan.
## Binning is lazy: the first query of a physics frame re-bins every unit (counting sort into flat arrays), and so
## does a query after the "units" group's size changed or after `mark_dirty()` (a unit joined / was teleported).
## Units keep their group order (`units[i]`, i ascending inside each cell) so a query can break ties exactly like the
## old scan (the first unit in group order wins). Positions are read live by the query; the cells are only a filter,
## padded by SLACK for units that moved since this frame's binning. Known limit: a raw global_position write of more
## than SLACK m (not through Unit.set_down) is only seen at the next physics frame's re-bin.
## Skirmish / missions do not create one (measured 2026-10-13 with perf_test, 100 units: no gain).

const CELL := 8.0
## Metres a unit can move between the frame's binning and a query of the same frame (fast riders ~0.25 m/frame,
## displacements ~1 m/frame); teleports call mark_dirty().
const SLACK := 2.0
const GROUP := &"unit_grid"

static var _current: UnitGrid = null
static var _dirty := true

## Read only (Unit's scan walks them): units in "units" group order; cell c holds
## items[cell_start[c] .. cell_start[c + 1] - 1] (indices into `units`, ascending).
var units: Array = []
var cell_start := PackedInt32Array()
var items := PackedInt32Array()
## x / z of units[i] when binned (a cheap pre-filter; the query re-checks the live position).
var pos_x := PackedFloat32Array()
var pos_z := PackedFloat32Array()
## team of units[i] when binned (Unit.team's setter marks the grid dirty, so it is always current).
var teams := PackedInt32Array()
var cols := 1
var rows := 1
var origin_x := 0.0
var origin_z := 0.0

var _frame := -1
var _count := -1
var _cell_of := PackedInt32Array()
var _fill := PackedInt32Array()


## The grid of the running level, or null (no grid = full scans).
static func current() -> UnitGrid:
	if _current != null and not is_instance_valid(_current):
		_current = null
	return _current


## Adds a UnitGrid under `level` unless the level already has one. Returns the grid.
static func ensure(level: Node) -> UnitGrid:
	var g := current()
	if g != null and g.is_inside_tree() and g.get_parent() == level:
		return g
	g = UnitGrid.new()
	g.name = "UnitGrid"
	level.add_child(g)
	return g


## Forces a re-bin at the next query (a unit joined the group, or was moved more than SLACK inside a frame).
static func mark_dirty() -> void:
	_dirty = true


func _enter_tree() -> void:
	add_to_group(GROUP)
	_current = self
	_dirty = true


func _exit_tree() -> void:
	if _current == self:
		_current = null


## Re-bins when stale (new physics frame, group size changed or marked dirty). Unit's scan calls it first.
func prepare() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var f := Engine.get_physics_frames()
	var n := tree.get_node_count_in_group(&"units")
	if f == _frame and n == _count and not _dirty:
		return
	_frame = f
	_count = n
	_dirty = false
	_rebuild(tree)


## Cell column / row of a world x / z (clamped to the grid).
func col_of(x: float) -> int:
	return clampi(int(floorf((x - origin_x) / CELL)), 0, cols - 1)


func row_of(z: float) -> int:
	return clampi(int(floorf((z - origin_z) / CELL)), 0, rows - 1)


func _rebuild(tree: SceneTree) -> void:
	var hx := MapInfo.half_x()
	var hz := MapInfo.half_z()
	origin_x = -hx
	origin_z = -hz
	cols = maxi(1, int(ceilf(hx * 2.0 / CELL)))
	rows = maxi(1, int(ceilf(hz * 2.0 / CELL)))
	var ncells := cols * rows
	units.clear()
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u != null:
			units.append(u)
	var n := units.size()
	_cell_of.resize(n)
	pos_x.resize(n)
	pos_z.resize(n)
	teams.resize(n)
	cell_start.resize(ncells + 1)
	cell_start.fill(0)
	for i in n:
		var u := units[i] as Unit
		var p := u.global_position
		teams[i] = u.team
		pos_x[i] = p.x
		pos_z[i] = p.z
		var c := row_of(p.z) * cols + col_of(p.x)
		_cell_of[i] = c
		cell_start[c + 1] += 1
	for c in ncells:
		cell_start[c + 1] += cell_start[c]
	_fill.resize(ncells)
	for c in ncells:
		_fill[c] = cell_start[c]
	items.resize(n)
	for i in n:
		var c := _cell_of[i]
		items[_fill[c]] = i
		_fill[c] += 1
