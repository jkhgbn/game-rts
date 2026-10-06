class_name BuildGrid
extends Node
## The building grid (cells of 2 m, docs/design/buildings.md), reached as `main.build_grid`.
## snap() puts a footprint on the grid, check() says why a placement is refused ("" = ok),
## place() spends the crystals, creates the construction site and orders the workers.
## It also rebakes the navmesh (on a thread) whenever a building is placed or destroyed.
## Works for any team: the bot uses the same calls as the player.

signal building_placed(building: Building)

const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")

const CELL := 2.0
const MIN_CELL := -29          ## Buildable cells: -29..28 (the outer ring -30 / 29 is excluded).
const MAX_CELL := 28
const CRYSTAL_CLEARANCE := 4.0
const NAV_TOLERANCE := 0.3
const OBSTACLE_PROBE_RADIUS := 0.2   ## Agent radius 0.5 - NAV_TOLERANCE.
const PUSH_OUT := 1.0          ## Own units in the footprint are sent this far outside it.

const MSG_OUTSIDE := "Outside the map"
const MSG_NOT_WALKABLE := "Not on walkable ground"
const MSG_BLOCKED := "Blocked"
const MSG_CRYSTAL := "Too close to a crystal node"
const MSG_UNEXPLORED := "Unexplored"   ## Not checked yet: fog of war comes later.
const MSG_NO_CRYSTALS := "Not enough crystals"
const MSG_LIMIT := "Population limit reached"
const MSG_WALL_LIMIT := "Wall limit reached"   ## Ice Wall: max_count 16 (kingdom-ice.md section 5).
const MSG_UNKNOWN := "Can't build that"
## Bazaar (market-trade.md 4.1): BuildingType.requires_kind &"barracks" / max_keep_distance / max_count 1.
const MSG_NEEDS_HALL := "Needs a completed Hall"
const MSG_KEEP_DISTANCE := "Must be within 20 m of your keep"
const MSG_MARKET_LIMIT := "Only one Bazaar"
## Map fill (map-fill.md 2.4, contract 13): the river, its crossings and the monster camps. Read through the groups
## "river" (RiverSystem: distance_to_water, distance_to_crossing, crossings) and "camp_manager" (CampManager: camps).
const MSG_WATER := "Can't build on water"
const MSG_CROSSING := "Too close to a crossing"
const MSG_CAMP := "Too close to a monster camp"
const WATER_CLEARANCE := 1.0      ## No footprint cell within this of deep water, a ford or a bridge deck.
const CROSSING_CLEARANCE := 8.0   ## ... nor within this of a crossing centre ...
const CAMP_CLEARANCE := 8.0       ## ... nor of a camp spot.
const EDGE_SAMPLE_STEP := 0.5     ## Footprint outline sampling for the water distance.

## The region every building goes under (so it becomes a navmesh obstacle). Set by main.gd.
var nav_region: NavigationRegion3D
## New buildings get this as front_toward (their spawn / rally corner faces it). main: MID_CAMP.
var front_toward := Vector3.ZERO
var last_reason := ""          ## Why the last place() returned null ("" after a success).

var _rebake_pending := false


func _ready() -> void:
	if nav_region:
		nav_region.bake_finished.connect(_on_bake_finished)
	# Rebake when any building (placed here or added by the level) is destroyed.
	for node in get_tree().get_nodes_in_group("buildings"):
		_watch(node)
	get_tree().node_added.connect(_watch)


# ---------------------------------------------------------------- public

## The centre of a `footprint` (cells) snapped to the grid near `world_pos` (y = 0).
## 3 x 3 and 1 x 1 centres land on odd coordinates, 2 x 2 on even ones.
func snap(world_pos: Vector3, footprint: Vector2i) -> Vector3:
	var w := float(footprint.x)
	var d := float(footprint.y)
	var min_x := roundf((world_pos.x - w) / CELL) * CELL
	var min_z := roundf((world_pos.z - d) / CELL) * CELL
	return Vector3(min_x + w, 0.0, min_z + d)


## The cells (i, j) covered by `footprint` centred on `center` (snapped first).
func cells_of(center: Vector3, footprint: Vector2i) -> Array[Vector2i]:
	var c := snap(center, footprint)
	var i0 := roundi((c.x - footprint.x) / CELL)
	var j0 := roundi((c.z - footprint.y) / CELL)
	var out: Array[Vector2i] = []
	for i in footprint.x:
		for j in footprint.y:
			out.append(Vector2i(i0 + i, j0 + j))
	return out


static func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL + CELL * 0.5, 0.0, cell.y * CELL + CELL * 0.5)


## "" if `team` may place `type` at `center` (snapped) now, else the message to show.
## Checks, in order: inside the map, not on another building / site, 4 m from crystal nodes,
## on walkable ground, no enemy unit inside, the map-fill rules (map_fill_reason: water, crossings,
## monster camps), the Bazaar rules (a completed Hall, then within 20 m of the own keep:
## BuildingType.requires_kind / max_keep_distance), crystals, the per-team limit
## (hearth: 2, Bazaar: 1; limit_message()).
## (Blocked and the crystal rule come before "walkable" because buildings and nodes are
## navmesh holes themselves: this way the player sees the real reason. For the same reason a
## footprint that is not walkable because it lies in or next to the carved river reports MSG_WATER.)
func check(type: BuildingType, center: Vector3, team: int) -> String:
	if type == null or not type.is_buildable():
		return MSG_UNKNOWN
	var c := snap(center, type.footprint)
	var cells := cells_of(c, type.footprint)
	# MT1: the buildable cells follow the running map (MapInfo; 120 m = -29..28, the outer ring excluded).
	var max_x := int(ceil(MapInfo.half_x() / CELL)) - 2
	var max_z := int(ceil(MapInfo.half_z() / CELL)) - 2
	for cell in cells:
		if cell.x < -max_x - 1 or cell.x > max_x or cell.y < -max_z - 1 or cell.y > max_z:
			return MSG_OUTSIDE
	var rect := _rect(c, type.footprint)
	if _overlaps_building(rect):
		return MSG_BLOCKED
	for cell in cells:
		var p := cell_center(cell)
		for node in get_tree().get_nodes_in_group("crystal_nodes"):
			var cn := node as Node3D
			if cn and Vector2(cn.global_position.x - p.x, cn.global_position.z - p.z).length() < CRYSTAL_CLEARANCE:
				return MSG_CRYSTAL
	if not _cells_walkable(cells):
		var river := _service(get_tree(), &"river") if is_inside_tree() else null
		return MSG_WATER if river and _touches_water(river, rect) else MSG_NOT_WALKABLE
	if _enemy_unit_inside(rect, team):
		return MSG_BLOCKED
	var map_reason := map_fill_reason(rect)
	if map_reason != "":
		return map_reason
	var needs := prerequisite_reason(type, team)
	if needs != "":
		return needs
	var far := keep_distance_reason(type, c, team)
	if far != "":
		return far
	var eco := Economy.for_team(team)
	if eco == null or not eco.can_afford(type.cost):
		return MSG_NO_CRYSTALS
	if at_limit(type, team):
		return limit_message(type)
	return ""


## The map-fill placement rules for a footprint `rect` (world x / z metres, e.g. a snapped footprint), "" = ok
## (map-fill.md 2.4): MSG_WATER when any part of it is within 1 m of deep water, a ford / Crown Steps circle or a
## bridge deck; MSG_CROSSING within 8 m of a crossing centre; MSG_CAMP within 8 m of a monster camp spot. Maps
## without a RiverSystem (group "river") or a CampManager (group "camp_manager") skip that part.
func map_fill_reason(rect: Rect2) -> String:
	if not is_inside_tree():
		return ""
	var tree := get_tree()
	var river := _service(tree, &"river")
	if river:
		if _touches_water(river, rect):
			return MSG_WATER
		if river.has_method(&"crossings"):
			var list: Variant = river.call(&"crossings")
			if list is Array:
				for c: Variant in list:
					if c is Dictionary and (c as Dictionary).get("center") is Vector3:
						var cp: Vector3 = (c as Dictionary)["center"]
						if _rect_distance(rect, Vector2(cp.x, cp.z)) < CROSSING_CLEARANCE:
							return MSG_CROSSING
	var camps := _service(tree, &"camp_manager")
	if camps and camps.has_method(&"camps"):
		var list: Variant = camps.call(&"camps")
		if list is Array:
			for camp: Variant in list:
				if not is_instance_valid(camp) or not camp is Node3D:
					continue
				var n := camp as Node3D
				var sp := n.global_position if n.is_inside_tree() else n.position
				if _rect_distance(rect, Vector2(sp.x, sp.z)) < CAMP_CLEARANCE:
					return MSG_CAMP
	# Mission no-build zones (mission-02.md: the frozen lake): nodes in group "no_build_zones" answer
	# `no_build_reason(rect: Rect2) -> String` ("" = fine).
	for zone in tree.get_nodes_in_group(&"no_build_zones"):
		if zone.has_method(&"no_build_reason"):
			var why := String(zone.call(&"no_build_reason", rect))
			if why != "":
				return why
	return ""


## Position-free building prerequisite for the build menu (the button's reason) and check():
## first the keep tier (`type.requires_tier`: "Requires Stronghold" / "Requires Citadel", tiers.md), then
## MSG_NEEDS_HALL while `type.requires_kind` is set and `team` has no completed, living building of
## that kind (a Hall under construction does not count), else "".
static func prerequisite_reason(type: BuildingType, team: int) -> String:
	if type == null:
		return ""
	var tier_gate := TierSystem.gate_reason(type.requires_tier, team)   # tiers.md: Stronghold / Citadel
	if tier_gate != "":
		return tier_gate
	if type.requires_kind == &"":
		return ""
	for b in Building.for_team(team):
		if b.building_type and b.building_type.kind == type.requires_kind and b.is_constructed():
			return ""
	if type.requires_kind == &"barracks":
		return MSG_NEEDS_HALL
	return "Needs a completed %s" % String(type.requires_kind).capitalize()


## MSG_KEEP_DISTANCE if `type.max_keep_distance` > 0 and `center` (not snapped) is farther than that
## (flat, centre to centre) from every living keep of `team` (or the team has no keep), else "".
static func keep_distance_reason(type: BuildingType, center: Vector3, team: int) -> String:
	if type == null or type.max_keep_distance <= 0.0:
		return ""
	var limit2 := type.max_keep_distance * type.max_keep_distance + 0.0001
	for b in Building.for_team(team):
		if b is Keep:
			var d := Vector2(b.global_position.x - center.x, b.global_position.z - center.z)
			if d.length_squared() <= limit2:
				return ""
	if is_equal_approx(type.max_keep_distance, 20.0):
		return MSG_KEEP_DISTANCE
	return "Must be within %d m of your keep" % roundi(type.max_keep_distance)


## True when `team` already has `type.max_count` buildings of that type (finished or under construction).
static func at_limit(type: BuildingType, team: int) -> bool:
	return type != null and type.max_count > 0 and Building.count_of(type.id, team) >= type.max_count


## The message when at_limit(): "Only one Bazaar", "Wall limit reached", else "Population limit reached".
static func limit_message(type: BuildingType) -> String:
	if type != null and type.kind == &"market":
		return MSG_MARKET_LIMIT
	if type != null and type.kind == &"wall":
		return MSG_WALL_LIMIT
	return MSG_LIMIT


## Places a construction site of `type` for `team` at `center` (snapped): spends the crystals,
## pushes own units out of the footprint, rebakes the navmesh and gives every worker in `workers`
## command_build(site). Returns the site, or null (the reason is in last_reason).
func place(type: BuildingType, center: Vector3, team: int, workers: Array) -> Building:
	last_reason = check(type, center, team)
	if last_reason != "":
		if last_reason == MSG_NO_CRYSTALS and Economy.for_team(team):
			Economy.for_team(team).spend(type.cost)   # fails on purpose: spend_failed (top bar flash)
		return null
	var c := snap(center, type.footprint)
	Economy.for_team(team).spend(type.cost)
	var site := create_building(type)
	site.team = team as Unit.Team
	site.make_site()
	_add_to_world(site, c)
	_push_units_out(_rect(c, type.footprint), team, workers)
	request_rebake()
	for w in workers:
		if w != null and is_instance_valid(w) and w.has_method(&"command_build"):
			w.call(&"command_build", site)
	building_placed.emit(site)
	return site


## The valid centre nearest to `near` (check() == "", or only short of crystals), scanning outward
## ring by ring (2 m cells) up to `max_rings`; Vector3.INF if none.
## For the bot: `place(type, find_spot(type, p, team), team, workers)`.
func find_spot(type: BuildingType, near: Vector3, team: int, max_rings: int = 12) -> Vector3:
	if type == null:
		return Vector3.INF
	for r in max_rings + 1:
		for i in range(-r, r + 1):
			for j in range(-r, r + 1):
				if maxi(absi(i), absi(j)) != r:
					continue
				var p := snap(near + Vector3(i * CELL, 0.0, j * CELL), type.footprint)
				var reason := check(type, p, team)
				if reason == "" or reason == MSG_NO_CRYSTALS:
					return p
	return Vector3.INF


## A finished building (no cost, no rules checked): for level setup (bases, tests).
## Call request_rebake() afterwards if the navmesh was already baked.
func spawn_complete(type: BuildingType, center: Vector3, team: int) -> Building:
	var b := create_building(type)
	b.team = team as Unit.Team
	_add_to_world(b, snap(center, type.footprint))
	return b


## The right node for a type: Keep, TrainingBuilding (barracks), Tower, Market (Bazaar) or a plain Building.
static func create_building(type: BuildingType) -> Building:
	var b: Building
	match type.kind:
		&"keep":
			b = Keep.new()
		&"barracks":
			b = TrainingBuilding.new()
		&"tower":
			b = Tower.new()
		&"market":
			b = Market.new()
		&"stables":   # docs/design/stables.md (Stables16)
			b = StablesBuilding.new()
		&"forge":   # docs/design/unit-upgrades.md (ForgeKit)
			b = ForgeBuilding.new()
		_:
			b = Building.new()
	b.building_type = type
	b.name = String(type.id).to_pascal_case()
	return b


## Rebakes the navmesh on a thread; if a bake is running, another one follows it.
func request_rebake() -> void:
	if nav_region == null:
		return
	if nav_region.is_baking():
		_rebake_pending = true
		return
	_rebake_pending = false
	# Replay Lab (docs/plan/replay-lab.md): deterministic runs bake on the main thread (BAKE_SYNC) or let the replay
	# bake at the recorded frames (BAKE_DEFERRED); the game bakes on a thread (BAKE_THREAD, the default).
	var bake_mode := _REPLAY.rebake_mode()
	if bake_mode == _REPLAY.BAKE_DEFERRED:
		return
	nav_region.bake_navigation_mesh(bake_mode != _REPLAY.BAKE_SYNC)


func is_rebaking() -> bool:
	return _rebake_pending or (nav_region != null and nav_region.is_baking())


# ---------------------------------------------------------------- helpers

func _add_to_world(b: Building, center: Vector3) -> void:
	b.position = center
	b.front_toward = front_toward
	if nav_region:
		nav_region.add_child(b, true)
	else:
		get_parent().add_child(b, true)


func _rect(center: Vector3, footprint: Vector2i) -> Rect2:
	var size := Vector2(footprint.x * CELL, footprint.y * CELL)
	return Rect2(Vector2(center.x, center.z) - size * 0.5, size)


func _overlaps_building(rect: Rect2) -> bool:
	var inner := rect.grow(-0.01)
	for node in get_tree().get_nodes_in_group("buildings"):
		var b := node as Building
		if b and b.is_alive() and b.footprint_rect().intersects(inner):
			return true
	return false


## Every cell centre must be on the navmesh (closest point within 0.3 m) and free of obstacles.
## The obstacle check (a thin physics cylinder on layer 1, above the ground) is needed because the
## navmesh closest-point query also "finds" the walkable roof of a rock, pillar or keep right above
## the cell centre, so it alone would let a building be placed on a rock.
func _cells_walkable(cells: Array[Vector2i]) -> bool:
	if nav_region == null:
		return true
	var map := nav_region.get_navigation_map()
	var nav_ready := map.is_valid() and NavigationServer3D.map_get_iteration_id(map) > 0
	var space := nav_region.get_world_3d().direct_space_state if nav_region.is_inside_tree() else null
	var query := PhysicsShapeQueryParameters3D.new()
	var probe := CylinderShape3D.new()
	probe.radius = OBSTACLE_PROBE_RADIUS
	probe.height = 2.0
	query.shape = probe
	query.collision_mask = 1
	for cell in cells:
		var p := cell_center(cell)
		# The navmesh is synced to the map a couple of frames after a bake: skip it until then.
		if nav_ready and NavigationServer3D.map_get_closest_point_owner(map, p).is_valid():
			var q := NavigationServer3D.map_get_closest_point(map, p)
			if Vector2(q.x - p.x, q.z - p.z).length() > NAV_TOLERANCE:
				return false
		if space:
			query.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 1.15)
			if not space.intersect_shape(query, 1).is_empty():
				return false
	return true


## The first living node of `group` (a step-12 service reached without its class), or null.
static func _service(tree: SceneTree, group: StringName) -> Node:
	for node in tree.get_nodes_in_group(group):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			return node
	return null


## True when some point of `rect` is within WATER_CLEARANCE of deep water or of a crossing shape (ford circle,
## bridge deck). A cheap test from the centre first; only footprints near the river sample their outline
## (every 0.25 m: deep water and crossings are far bigger than a footprint, so they always cut the outline).
func _touches_water(river: Node, rect: Rect2) -> bool:
	var has_water := river.has_method(&"distance_to_water")
	var has_cross := river.has_method(&"distance_to_crossing")
	if not has_water and not has_cross:
		return false
	var c := rect.get_center()
	var reach := rect.size.length() * 0.5 + WATER_CLEARANCE
	var c3 := Vector3(c.x, 0.0, c.y)
	var near_water := has_water and float(river.call(&"distance_to_water", c3, reach)) < reach
	var near_cross := has_cross and float(river.call(&"distance_to_crossing", c3)) < reach
	if not near_water and not near_cross:
		return false
	var pts: Array[Vector2] = [c]
	var step := EDGE_SAMPLE_STEP * 0.5
	var nx := maxi(1, ceili(rect.size.x / step))
	var nz := maxi(1, ceili(rect.size.y / step))
	for i in nx + 1:
		var x := rect.position.x + rect.size.x * float(i) / float(nx)
		pts.append(Vector2(x, rect.position.y))
		pts.append(Vector2(x, rect.end.y))
	for j in range(1, nz):
		var z := rect.position.y + rect.size.y * float(j) / float(nz)
		pts.append(Vector2(rect.position.x, z))
		pts.append(Vector2(rect.end.x, z))
	for p in pts:
		var p3 := Vector3(p.x, 0.0, p.y)
		if near_water and float(river.call(&"distance_to_water", p3, WATER_CLEARANCE)) < WATER_CLEARANCE:
			return true
		if near_cross and float(river.call(&"distance_to_crossing", p3)) < WATER_CLEARANCE:
			return true
	return false


## Flat distance from `p` to the rectangle (0 inside).
static func _rect_distance(rect: Rect2, p: Vector2) -> float:
	var dx := maxf(0.0, maxf(rect.position.x - p.x, p.x - rect.end.x))
	var dz := maxf(0.0, maxf(rect.position.y - p.y, p.y - rect.end.y))
	return Vector2(dx, dz).length()


func _enemy_unit_inside(rect: Rect2, team: int) -> bool:
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or int(u.team) == team or not u.is_alive():
			continue
		if rect.grow(u.radius).has_point(Vector2(u.global_position.x, u.global_position.z)):
			return true
	return false


## Own units standing in the footprint walk to the nearest point 1 m outside it (the builders
## get their own order right after).
func _push_units_out(rect: Rect2, team: int, workers: Array) -> void:
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or int(u.team) != team or not u.is_alive() or workers.has(u):
			continue
		var p := Vector2(u.global_position.x, u.global_position.z)
		if not rect.grow(u.radius).has_point(p):
			continue
		var to_edges := [p.x - rect.position.x, rect.end.x - p.x, p.y - rect.position.y, rect.end.y - p.y]
		var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		var best := 0
		for i in 4:
			if to_edges[i] < to_edges[best]:
				best = i
		var out: Vector2 = p + dirs[best] * (float(to_edges[best]) + PUSH_OUT + u.radius)
		u.command_move(Vector3(out.x, 0.0, out.y))


func _watch(node: Node) -> void:
	var b := node as Building
	if b and not b.destroyed.is_connected(_on_building_destroyed):
		b.destroyed.connect(_on_building_destroyed)


func _on_building_destroyed(_b: Building) -> void:
	request_rebake()


func _on_bake_finished() -> void:
	if _rebake_pending:
		# Wait a frame: the region may still report "baking" inside its own signal.
		call_deferred(&"request_rebake")
