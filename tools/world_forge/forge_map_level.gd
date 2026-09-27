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
var _frames := 0


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
	var half := layout.size * 0.5
	_box(Vector3(0, -0.5, 0), Vector3(half + 2.0, 0.5, half + 2.0), 0.0, "Ground")
	_build_water()
	for b: Dictionary in layout.blocks:
		_box(b["center"] + Vector3(0, 1.5, 0), Vector3(b["half"].x, 1.5, b["half"].z), float(b.get("yaw", 0.0)), String(b["id"]))
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
	nav_region.bake_navigation_mesh(false)
	bake_seconds = float(Time.get_ticks_usec() - t0) / 1e6


func _process(_delta: float) -> void:
	# two frames after the bake the navigation map has synced
	_frames += 1
	if not match_started and _frames >= 3 and NavigationServer3D.map_get_iteration_id(nav_region.get_navigation_map()) > 0:
		match_started = true


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
