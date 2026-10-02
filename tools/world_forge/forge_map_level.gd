extends Node3D
## World Forge map preview level: builds a flat, navmesh-baked stand-in of a MapLayout (ground, river / moat as
## obstacles with gaps at the crossings, keep footprints, blocks) and puts every spot in the groups the Map Lab reads
## (buildings / crystal_nodes / capture_points / neutral_camps / taverns / trade_posts / guilds / peddlers /
## lost_caches, the river's crossings(), `crown`). A generated subclass adds `const LAIR_SPOTS` (Map Lab reads lairs
## from the level script's constants). No positional constants here on purpose (the Map Lab checks them).

const KeepSpot := preload("res://tools/world_forge/forge_keep_spot.gd")
const RiverNode := preload("res://tools/world_forge/forge_river.gd")

const GROUPS := {"point": &"capture_points", "camp": &"neutral_camps", "tavern": &"taverns", "post": &"trade_posts",
	"guild": &"guilds", "peddler": &"peddlers", "cache": &"lost_caches"}

@export var layout: MapLayout

var match_started := false
var crown: Node3D
var hero: Node = null
var nav_region: NavigationRegion3D
var bake_seconds := 0.0
var forest_plan: Dictionary = {}
var _frames := 0
var _iter0 := -1


func _ready() -> void:
	if layout == null:
		push_error("forge_map_level: no layout")
		return
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Nav"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.agent_radius = 0.5
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.25
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nav_region.navigation_mesh = nm
	add_child(nav_region)
	NavigationServer3D.region_set_use_async_iterations(nav_region.get_rid(), false)
	_iter0 = NavigationServer3D.map_get_iteration_id(nav_region.get_navigation_map())
	MapInfo.setup(layout.size_x, layout.size_z, layout.id)
	_box(Vector3(0, -0.5, 0), Vector3(layout.size_x * 0.5 + 2.0, 0.5, layout.size_z * 0.5 + 2.0), 0.0, "Ground")
	_build_water()
	for b: Dictionary in layout.blocks:
		_box(b["center"] + Vector3(0, 1.5, 0), Vector3(b["half"].x, 1.5, b["half"].z), float(b.get("yaw", 0.0)), String(b["id"]))
	_build_forest()
	var spots_root := Node3D.new()
	spots_root.name = "Spots"
	add_child(spots_root)
	for s: Dictionary in layout.spots:
		var kind: String = s["kind"]
		var pos: Vector3 = s["pos"]
		match kind:
			"keep":
				var k: Node3D = KeepSpot.new()
				k.name = String(s["id"])
				k.set(&"team", int(s["team"]))
				k.position = pos
				spots_root.add_child(k)
				var fp: float = float((s.get("props", {}) as Dictionary).get("footprint", 6.0))
				_box(pos + Vector3(0, 1.5, 0), Vector3(fp * 0.5, 1.5, fp * 0.5), 0.0, "keep_body_%s" % s["id"])
			"node":
				_marker(spots_root, s, &"crystal_nodes")
			"crown":
				crown = _marker(spots_root, s, &"")
			_:
				if GROUPS.has(kind):
					_marker(spots_root, s, GROUPS[kind])
	if not layout.crossings.is_empty():
		var r: Node3D = RiverNode.new()
		r.name = "River"
		add_child(r)
		var list: Array[Dictionary] = []
		for c: Dictionary in layout.crossings:
			var d := c.duplicate()
			d["kind"] = StringName(String(c.get("kind", "ford")))
			d["id"] = StringName(String(c["id"]))
			list.append(d)
		r.call(&"setup", list)
	var t0 := Time.get_ticks_usec()
	if layout.navmeshes.is_empty():
		nav_region.bake_navigation_mesh(false)
	else:
		# the live map's own navmesh(es) (export-map): the preview's paths are the live paths
		for i in layout.navmeshes.size():
			var e: Dictionary = layout.navmeshes[i]
			var reg := nav_region
			if i > 0:
				reg = NavigationRegion3D.new()
				reg.name = "Nav%d" % i
				add_child(reg)
				NavigationServer3D.region_set_use_async_iterations(reg.get_rid(), false)
			reg.navigation_mesh = load(String(e["path"])) as NavigationMesh
			reg.transform = e.get("xf", Transform3D.IDENTITY)
	bake_seconds = float(Time.get_ticks_usec() - t0) / 1e6


## Grammar v2 `forest` / `grove` / `willows` / `prop` (MT2 / MT3): the same placements as LayoutLevel (MapForest), as
## colliders only (trees r 0.45 s, rocks 1.6 x 1.2 x 1.3 s, pillars r 0.7), so the Map Lab judges the dressed map.
func _build_forest() -> void:
	for p: Dictionary in layout.props:
		var root: Node3D = null
		var path := String(p.get("scene", ""))
		if path != "" and ResourceLoader.exists(path):
			var ps := load(path) as PackedScene
			root = ps.instantiate() as Node3D if ps else null
		if root == null:
			root = Node3D.new()
			for col: Vector3 in p.get("colliders", []):
				var body := StaticBody3D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var cs := CollisionShape3D.new()
				var cy := CylinderShape3D.new()
				cy.radius = col.z
				cy.height = 1.8
				cs.shape = cy
				cs.position = Vector3(col.x, 0.9, col.y)
				body.add_child(cs)
				root.add_child(body)
		root.name = "Prop_%s" % String(p["id"]).validate_node_name()
		nav_region.add_child(root)
		root.position = p["pos"]
		root.rotation.y = float(p.get("yaw", 0.0))
	if layout.forest.is_empty():
		return
	var river: RiverSystem = null
	if not layout.river.is_empty() or not layout.moat.is_empty():
		river = RiverSystem.new()   # off-tree: only its distance queries (no carve, no visuals)
		river.build_visuals = false
		river.setup(LayoutLevel.river_lines(layout), LayoutLevel.river_half_width(layout), LayoutLevel.moat_of(layout),
				LayoutLevel.crossings_of(layout))
	forest_plan = MapForest.plan(layout, river)
	if river:
		river.free()
	for t: Dictionary in forest_plan["trees"]:
		var cy := CylinderShape3D.new()
		cy.radius = 0.45 * float(t["s"])
		cy.height = 2.0
		_shape(cy, Transform3D(Basis(), (t["pos"] as Vector3) + Vector3(0, 1.0, 0)), "tree")
	for r: Dictionary in forest_plan["rocks"]:
		var bx := BoxShape3D.new()
		bx.size = Vector3(1.6, 1.2, 1.3) * float(r["s"])
		_shape(bx, Transform3D(Basis(Vector3.UP, float(r["rot"])), (r["pos"] as Vector3) + Vector3(0, 0.5 * float(r["s"]), 0)), "rock")
	for pl: Dictionary in forest_plan["pillars"]:
		var cy2 := CylinderShape3D.new()
		cy2.radius = 0.7
		cy2.height = float(pl["h"])
		_shape(cy2, Transform3D(Basis(), (pl["pos"] as Vector3) + Vector3(0, float(pl["h"]) * 0.5, 0)), "pillar")


func _shape(shape: Shape3D, xf: Transform3D, nm: String) -> void:
	var body := StaticBody3D.new()
	body.name = nm
	body.collision_layer = 1
	body.collision_mask = 0
	body.transform = xf
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	nav_region.add_child(body)


func _process(_delta: float) -> void:
	# two frames after the bake the navigation map has synced (an iteration after this level's own: a job run after
	# another one in the same process sees the earlier level's iterations first)
	_frames += 1
	var map := nav_region.get_navigation_map()
	var it := NavigationServer3D.map_get_iteration_id(map)
	# ...and a probe path between two spots answers (an async map iteration started before this level's region was
	# added can land first: its queries see no navmesh at all)
	if match_started or _frames < 3:
		return
	if _probe_ok(map) and (it > _iter0 or _frames > 30):
		match_started = true
	elif _frames % 60 == 0 and nav_region.navigation_mesh != null:
		# a map iteration that ran while the region was still empty can stick (sequential jobs in one process):
		# hand the baked navmesh to the server again so the map rebuilds with it
		NavigationServer3D.region_set_navigation_mesh(nav_region.get_rid(), nav_region.navigation_mesh)
	if _frames > 1800:
		match_started = true   # tick_map's N0 / the Map Lab report what is wrong


## True when the map's current iteration answers queries with this level's region (its closest point to the ground
## centre belongs to our NavigationRegion3D).
func _probe_ok(map: RID) -> bool:
	var p := Vector3(0.0, 0.5, 0.0)
	for s: Dictionary in layout.spots:
		if not String(s["kind"]) in ["keep", "slot", "start"]:
			p = (s["pos"] as Vector3) + Vector3(0, 0.5, 0)
			break
	return NavigationServer3D.map_get_closest_point_owner(map, p) == nav_region.get_rid()


func _marker(parent: Node3D, s: Dictionary, group: StringName) -> Node3D:
	var n := Node3D.new()
	n.name = String(s["id"])
	n.position = s["pos"]
	n.set_meta(&"kind", s["kind"])
	n.set_meta(&"sub", s.get("sub", ""))
	parent.add_child(n)
	if group != &"":
		n.add_to_group(group)
	return n


func _box(center: Vector3, half: Vector3, yaw_deg: float, nm: String) -> void:
	var body := StaticBody3D.new()
	body.name = nm
	body.collision_layer = 1
	body.collision_mask = 0
	body.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), center)
	var sh := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = half * 2.0
	sh.shape = bs
	body.add_child(sh)
	nav_region.add_child(body)


## River arms and moat as obstacle boxes, cut open at the crossings.
func _build_water() -> void:
	for arm: Dictionary in layout.river:
		var poly: PackedVector3Array = arm["poly"]
		var hw: float = arm["half_width"]
		for i in range(poly.size() - 1):
			var a := poly[i]
			var b := poly[i + 1]
			var length := Vector2(b.x - a.x, b.z - a.z).length()
			var n := maxi(1, int(ceil(length / 1.0)))
			var dir := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
			var yaw := rad_to_deg(atan2(-dir.z, dir.x))
			for s in n:
				var c := a.lerp(b, (s + 0.5) / n)
				if _near_crossing(c, 0.0):
					continue
				_box(Vector3(c.x, 1.0, c.z), Vector3(length / n * 0.5 + 0.05, 1.0, hw), yaw, "water")
	if not layout.moat.is_empty():
		var center: Vector3 = layout.moat["center"]
		var r: float = layout.moat["radius"]
		var hw2: float = layout.moat["half_width"]
		var segs := 96
		for k in segs:
			var a := TAU * (k + 0.5) / segs
			var c := center + Vector3(cos(a) * r, 0, sin(a) * r)
			if _near_crossing(c, 0.0):
				continue
			var yaw := rad_to_deg(-a) - 90.0
			_box(Vector3(c.x, 1.0, c.z), Vector3(TAU * r / segs * 0.5 + 0.05, 1.0, hw2), yaw, "moat")


func _near_crossing(p: Vector3, margin: float) -> bool:
	for c: Dictionary in layout.crossings:
		var cc: Vector3 = c["center"]
		var kind := String(c.get("kind", "ford"))
		var gap: float = float(c.get("width", 6.0)) * 0.5 if kind.begins_with("bridge") else float(c.get("radius", float(c.get("width", 6.0)) * 0.5))
		if Vector2(p.x - cc.x, p.z - cc.z).length() < gap + margin:
			return true
	return false
