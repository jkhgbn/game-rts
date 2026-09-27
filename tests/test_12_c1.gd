extends SceneTree
## Task 12.C1 (docs/design/map-fill.md 2, 13, "Done when" 12.C1): RiverSystem and the Crown Hollow map changes.
## Part 1 loads the skirmish with map fill off (river, points, camps, beasts false): nothing of step 12, the step-4
## cache spots, the forest recorded. Part 2 loads it with map fill on (bot disabled; camps / Magpies paused so nothing
## fights the test units) and checks: is_water / is_ford / is_bridge / bank_of at the spec points and their mirrors,
## the navmesh has no polygon in deep water, a unit walking (-20, 0) -> (20, 0) never enters deep water and crosses the
## isle, the ford slow (x0.65, lost 0.3 m out, amphibious exempt, flag off), the push-out (< 0.3 s), step-10 constants,
## caches and crown drops, the forest (only corridor / clearing removals, additions = willows and Old Wood trees,
## everything mirrored), path-length fairness (< 1 %), shader params / EnvProps.set_river, services, fog, waystones.
## Run:  godot --headless --path . -s tests/test_12_c1.gd --fixed-fps 60 --quit-after 14000

const TASK_ID := "12.C1"
const TIMEOUT_FRAMES := 13500
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1
const FLAGS := ["river_enabled", "points_enabled", "camps_enabled", "beasts_enabled"]

var main: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _off_obstacles := {}


func _initialize() -> void:
	_run()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func _finish() -> bool:
	for n in _notes:
		print("  note: ", n)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	_done = true
	return true


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _load_scene(map_fill: bool) -> bool:
	main = load(SCENE).instantiate()
	for f in FLAGS:
		main.set(f, map_fill)
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking (map fill %s)" % map_fill)
		return false
	await _frames(3)
	return true


## Plain obstacles directly under the NavigationRegion3D (trees, rocks, pillars, willows; not the ground):
## "x,z" -> [pos, footprint reach, radius-or-size key].
func _obstacles() -> Dictionary:
	var out := {}
	for c in main.nav_region.get_children():
		var body := c as StaticBody3D
		if body == null or body.get_script() != null or body.get_child_count() == 0:
			continue
		var col := body.get_child(0) as CollisionShape3D
		if col == null:
			continue
		var extra := 0.0
		var key := ""
		if col.shape is BoxShape3D:
			var size: Vector3 = (col.shape as BoxShape3D).size
			if size.x > 50.0:
				continue   # the ground
			extra = size.x * 0.5
			key = "box %.3f" % size.x
		elif col.shape is CylinderShape3D:
			extra = (col.shape as CylinderShape3D).radius
			key = "cyl %.3f" % extra
		else:
			continue
		var p := body.global_position
		out["%.2f,%.2f" % [p.x, p.z]] = [p, extra, key]
	return out


# ---------------------------------------------------------------- the run

func _run() -> void:
	await _frames(1)
	if not await _load_scene(false):
		_finish()
		return
	_part_off()
	main.queue_free()
	await _frames(10)
	if not await _load_scene(true):
		_finish()
		return
	await _part_on()
	_finish()


## Map fill off: the step-11 map (no river, no landmarks, the old cache spots); the forest is remembered.
func _part_off() -> void:
	_check(root.get_tree().get_nodes_in_group("river").is_empty() and main.get("river") == null, "off: no RiverSystem")
	_check((main.get("landmarks") as Array).is_empty() and root.get_tree().get_nodes_in_group("landmarks").is_empty(),
			"off: no landmarks")
	for g in ["capture_points_service", "camp_manager", "epic_beasts", "critter_herds", "neutral_camps", "beasts"]:
		_check(root.get_tree().get_nodes_in_group(g).is_empty(), "off: nothing in group %s" % g)
	var spots := []
	for c in main.caches:
		spots.append(Vector3(c.global_position.x, 0, c.global_position.z))
	_check(spots.size() == 4 and spots.has(Vector3(0, 0, 30)) and spots.has(Vector3(0, 0, -30)),
			"off: caches at the step-4 spots (%s)" % [spots])
	var gm := _ground_mat()
	if gm:
		var rc: Variant = gm.get_shader_parameter(&"river_count")
		_check(rc == null or int(rc) == 0, "off: the ground has no river (%s)" % rc)
	_check(main.bank_of(Vector3(-30, 0, -24)) == P and main.bank_of(Vector3(30, 0, 24)) == E
			and main.bank_of(Vector3.ZERO) == -1, "off: bank_of fallback")
	_check(not String(main.end_screen_text()).contains("Points held"), "off: no map-fill end-screen line")
	_off_obstacles = _obstacles()
	var m1: Node = load("res://scripts/campaign/mission_01.gd").new()
	for f in FLAGS:
		_check(not bool(m1.get(f)), "mission 1: %s false" % f)
	m1.free()


func _part_on() -> void:
	var river: Node = main.get("river")
	_check(river != null and river == RiverSystem.instance(root.get_tree()), "RiverSystem.instance() = skirmish.river")
	if river == null:
		return
	_check(river.get_parent() == main.nav_region, "the river is under the NavigationRegion3D")
	# Quiet map: no camp creature, beast, Magpie or tracker may fight the test units.
	for g in ["thieves_guild", "hunters_guild", "camp_manager", "epic_beasts"]:
		var svc: Node = root.get_tree().get_first_node_in_group(StringName(g))
		if svc:
			svc.process_mode = Node.PROCESS_MODE_DISABLED
	for n in root.get_tree().get_nodes_in_group("creatures") + root.get_tree().get_nodes_in_group("beasts"):
		n.remove_from_group("units")
		n.queue_free()
	await _frames(2)
	_query_checks(river)
	_constant_checks()
	_forest_checks(river)
	_mirror_checks(river)
	_navmesh_checks(river)
	_path_checks()
	_shader_checks(river)
	_service_checks()
	_waystone_checks(river)
	await _crown_drop_checks()
	await _walk_checks(river)
	await _ford_checks(river)
	await _push_checks(river)
	_perf_checks(river)


# ---------------------------------------------------------------- river queries

func _query_checks(river: Node) -> void:
	for p: Vector3 in [Vector3(-6.5, 0, -25.5), Vector3(-12.75, 0, 0)]:
		_check(river.is_water(p) and river.is_water(-p), "is_water at %s and its mirror" % p)
	for p: Vector3 in [Vector3(-8.5, 0, -34), Vector3(-9.02, 0, -9.02)]:
		_check(river.is_ford(p) and river.is_ford(-p) and not river.is_water(p), "is_ford at %s and its mirror" % p)
	for p: Vector3 in [Vector3(-12, 0, -48.7), Vector3(-9.02, 0, 9.02)]:
		_check(river.is_bridge(p) and river.is_bridge(-p) and not river.is_water(p), "is_bridge at %s and its mirror" % p)
	_check(river.bank_of(Vector3(-30, 0, -24)) == P, "bank_of(-30, -24) = PLAYER (%d)" % river.bank_of(Vector3(-30, 0, -24)))
	_check(river.bank_of(Vector3(30, 0, 24)) == E, "bank_of(30, 24) = ENEMY")
	_check(river.bank_of(Vector3.ZERO) == -1 and river.bank_of(Vector3(-6.5, 0, -25.5)) == -1, "bank_of isle / water = -1")
	_check(main.bank_of(Vector3(-30, 0, -24)) == P, "Skirmish.bank_of delegates to the river")
	# The west bank holds the player base, both west posts, the north-west corner, the west tavern and peddler.
	for p: Vector3 in [Vector3(-43, 0, 43), Vector3(-53, 0, 1), Vector3(-1, 0, 53), Vector3(-40, 0, -40),
			Vector3(-55, 0, -45), Vector3(-45, 0, -55), Vector3(-15, 0, -15), Vector3(-22, 0, -22), Vector3(-16, 0, 6)]:
		_check(river.bank_of(p) == P and river.bank_of(-p) == E, "bank_of %s = PLAYER, mirror ENEMY" % p)
	var land: Vector3 = river.nearest_land(Vector3(-6.5, 0, -25.5))
	_check(not river.is_water(land) and _flat(land, Vector3(-6.5, 0, -25.5)) < 2.7, "nearest_land out of the river (%s)" % land)
	_check(river.nearest_land(Vector3(-30, 0, 0)) == Vector3(-30, 0, 0), "nearest_land on land = the point")
	_check(is_equal_approx(river.distance_to_water(Vector3(-6.5, 0, -25.5)), 0.0), "distance_to_water in water = 0")
	var d: float = river.distance_to_water(Vector3(-6.5 - 4.0, 0, -25.5))
	_check(d > 1.0 and d < 2.0, "distance_to_water 4 m from the centre line ~1.5 (%.2f)" % d)
	var ids := []
	for c: Dictionary in river.crossings():
		ids.append(String(c["id"]))
	ids.sort()
	_check(ids == ["bridge_crown_e", "bridge_crown_w", "bridge_road_n", "bridge_road_s", "ford_n", "ford_s", "steps_nw",
			"steps_se"], "8 crossings (%s)" % [ids])
	_check(String(river.crossing(&"ford_n").get("name", "")) == "Reed Ford" and river.crossing(&"nope").is_empty(), "crossing(id)")
	_check(river.water_polygons().size() == 10, "10 water pieces (3 + 3 river, 4 moat arcs): %d" % river.water_polygons().size())
	var img: Image = river.mask_image()
	_check(img.get_width() == 240 and img.get_height() == 240, "mask 240 x 240")
	var px := func(x: float, z: float) -> Color: return img.get_pixel(int((x + 60.0) / 0.5), int((z + 60.0) / 0.5))
	_check(px.call(-6.5, -25.5).r > 0.9 and px.call(-8.5, -34).g > 0.9 and px.call(-12, -48.7).b > 0.9
			and px.call(-30, -24) == Color(0, 0, 0), "mask R water / G ford / B bridge")
	_check(RiverSystem.WATER_Y == -0.35 and RiverSystem.FORD_SLOW == -0.35 and river.ford_modifier_enabled
			and RiverSystem.FORD_MODIFIER == &"terrain:ford", "constants / flag")


func _constant_checks() -> void:
	var S: GDScript = load("res://scripts/world/skirmish.gd")
	var c: Dictionary = S.get_script_constant_map()
	var want_roads := {&"hub": Vector3(-36, 0, 36), &"w_door": Vector3(-49, 0, 1), &"nw1": Vector3(-48, 0, -44),
		&"nw2": Vector3(-44, 0, -48), &"s_door": Vector3(-1, 0, 49), &"hub_e": Vector3(36, 0, -36),
		&"e_door": Vector3(49, 0, -1), &"se1": Vector3(48, 0, 44), &"se2": Vector3(44, 0, 48), &"n_door": Vector3(1, 0, -49)}
	_check(c["ROAD_NODES"] == want_roads, "ROAD_NODES unchanged")
	_check((c["ROAD_SEGMENTS"] as Array).size() == 10, "ROAD_SEGMENTS unchanged")
	_check(c["TAVERN_SPOTS"] == [Vector3(-15, 0, -15), Vector3(15, 0, 15)] and c["PEDDLER_SPOTS"] == [Vector3(-22, 0, -22),
			Vector3(22, 0, 22)], "taverns / peddlers unchanged")
	_check(c["MARKET_SLOT"] == Vector3(-45, 0, 27) and c["TOWER_SLOTS"] == {&"natural": Vector3(-19, 0, 1),
			&"rich": Vector3(-37, 0, -45)}, "M1 / S3 / S4 unchanged")
	_check((c["AMBUSH_SPOTS"] as Dictionary)[&"A1"] == Vector3(-44, 0, 15) and (c["WORKER_SPOTS"] as Dictionary)[&"W1"]
			== Vector3(-8, 0, 16), "ambush / worker spots unchanged")
	_check((c["POST_SPOTS"] as Array).size() == 4 and (c["DEN_SPOTS"] as Array)[0]["center"] == Vector3(-55, 0, -45)
			and (c["LODGE_SPOTS"] as Array)[0]["center"] == Vector3(-45, 0, -55), "posts / guild houses unchanged")
	_check(c["FIRE_NODES"][&"node_fire_rich"] == Vector3(-40, 0, -40) and c["HOUSE_SLOT"] == Vector3(-50, 0, 46),
			"nodes / house slot unchanged")
	var spots := []
	for cache in main.caches:
		spots.append(Vector3(cache.global_position.x, 0, cache.global_position.z))
	_check(spots.has(Vector3(-6, 0, 27)) and spots.has(Vector3(6, 0, -27)) and spots.has(Vector3(-30, 0, 0))
			and spots.has(Vector3(30, 0, 0)), "caches at (-6, 27) / (6, -27) with the river (%s)" % [spots])
	_check(c["CAMP_DROP_SPOTS"] == [Vector3(2, 0, 2), Vector3(-2, 0, -2)] and c["CAMP_DROP_ITEMS"][0] == &"warden_scale",
			"crown drops: Warden Scale (2, 2), Ember Draught (-2, -2)")
	# Spec tables: mirrored pairs.
	for key in ["POINT_SPOTS", "CAMP_SPOTS"]:
		var list: Array = c[key]
		_check(list.size() == 8, "%s has 8 spots" % key)
		for s: Dictionary in list:
			var twin := false
			for t: Dictionary in list:
				twin = twin or ((t["pos"] as Vector3) == -(s["pos"] as Vector3) and t["kind"] == s["kind"])
			_check(twin, "%s %s has its mirror" % [key, s["id"]])
	var lairs: Array = c["LAIR_SPOTS"]
	_check(lairs.size() == 8, "8 lairs")
	for s: Dictionary in lairs:
		var twin := false
		for t: Dictionary in lairs:
			twin = twin or ((t["center"] as Vector3) == -(s["center"] as Vector3) and t["kind"] == s["kind"])
		_check(twin, "lair %s has its mirror" % s["id"])
	var homes: Array = c["RABBIT_HOMES"]
	_check(homes.size() == 12, "12 rabbit homes")
	for h: Vector3 in homes:
		_check(homes.has(-h), "rabbit home %s mirrored" % h)
	var herds: Array = c["DEER_HERDS"]
	_check(herds.size() == 2 and (herds[0]["spots"] as Array).size() == 6, "2 deer herds of 6 graze spots")
	for k in 6:
		_check((herds[1]["spots"][k] as Vector3) == -(herds[0]["spots"][k] as Vector3), "deer graze spot %d mirrored" % k)


# ---------------------------------------------------------------- forest / obstacles

func _forest_checks(river: Node) -> void:
	var on := _obstacles()
	var clearings: Array = main.get("_mapfill_clearings")
	var removed := 0
	for k in _off_obstacles:
		if on.has(k):
			continue
		removed += 1
		var p: Vector3 = _off_obstacles[k][0]
		var extra: float = _off_obstacles[k][1]
		var why: bool = river.distance_to_water(p) < 1.2 + extra + 0.01 or river.distance_to_crossing(p) < 2.0 + extra + 0.01
		for c in clearings:
			why = why or _flat(p, c[0]) < float(c[1]) + extra + 0.01
		_check(why, "obstacle at %s removed although outside every river corridor / map-fill clearing" % p)
	var added := 0
	var clusters := [[Vector3(-30, 0, -56), 4.0], [Vector3(-57, 0, -32), 3.5]]
	for k in on:
		var p: Vector3 = on[k][0]
		var extra: float = on[k][1]
		_check(river.distance_to_water(p) >= 1.2 + extra - 0.01, "tree / rock at %s within 1.2 m of deep water" % p)
		if String(on[k][2]) != "cyl 0.700":   # the crown's ruin pillars (placed as before, 2 m from the Crown Steps)
			_check(river.distance_to_crossing(p) >= 2.0 + extra - 0.01, "tree / rock at %s within 2 m of a crossing" % p)
		if _off_obstacles.has(k):
			continue
		added += 1
		var ok := String(on[k][2]).begins_with("cyl") and extra < 0.6
		var old_wood := false
		for cl in clusters:
			old_wood = old_wood or _flat(p, cl[0]) <= float(cl[1]) + 0.01 or _flat(p, -(cl[0] as Vector3)) <= float(cl[1]) + 0.01
		var willow: bool = river.distance_to_water(p) <= 4.05
		_check(ok and (old_wood or willow), "new obstacle at %s is neither a willow nor an Old Wood tree" % p)
	_check(added >= 16 and added % 2 == 0, "willows + Old Wood trees added in mirrored pairs (%d)" % added)
	_notes.append("forest: %d obstacles off, %d on, %d removed, %d added (willows + Old Wood)" % [_off_obstacles.size(),
			on.size(), removed, added])
	var ep: Node = main.get("env_props")
	var wmm: MultiMeshInstance3D = ep.get_node_or_null("TreeWillow") if ep else null
	if wmm and wmm.multimesh:
		var nw := wmm.multimesh.instance_count
		_check(nw >= 6 and nw % 2 == 0, "willows drawn in mirrored pairs (%d)" % nw)
		_notes.append("willows: %d" % nw)
	# Landmarks: 5 kinds x 2, colliders <= 1.8 m under the NavigationRegion3D.
	var lms: Array = main.get("landmarks")
	_check(lms.size() == 10, "10 landmarks (%d)" % lms.size())
	for lm: Node3D in lms:
		_check(lm.get_parent() == main.nav_region, "landmark %s under the NavigationRegion3D" % lm.name)
		for cs in lm.find_children("*", "CollisionShape3D", true, false):
			var top := _shape_top(cs as CollisionShape3D)
			_check(top <= 1.85, "landmark %s collider top %.2f m (<= 1.8)" % [lm.name, top])


func _shape_top(cs: CollisionShape3D) -> float:
	var h := 0.0
	if cs.shape is CylinderShape3D:
		h = (cs.shape as CylinderShape3D).height * 0.5
	elif cs.shape is BoxShape3D:
		h = (cs.shape as BoxShape3D).size.y * 0.5
	elif cs.shape is CapsuleShape3D:
		h = (cs.shape as CapsuleShape3D).height * 0.5
	return cs.global_position.y + h


## Every plain obstacle and every landmark collider has its point-mirror twin (same shape); the water is mirrored.
func _mirror_checks(river: Node) -> void:
	var on := _obstacles()
	var missing := 0
	for k in on:
		var p: Vector3 = on[k][0]
		var twin := "%.2f,%.2f" % [-p.x, -p.z]
		if not on.has(twin) or on[twin][2] != on[k][2]:
			twin = ""
			for k2 in on:   # rounding at the 2nd decimal
				if _flat(on[k2][0], -p) < 0.02 and on[k2][2] == on[k][2]:
					twin = k2
		if twin == "":
			missing += 1
			if missing <= 5:
				_check(false, "obstacle %s at %s has no mirror twin" % [on[k][2], p])
	_check(missing == 0, "%d obstacles without a mirror twin" % missing)
	var shapes := []
	for lm: Node3D in main.get("landmarks"):
		for cs in lm.find_children("*", "CollisionShape3D", true, false):
			shapes.append(cs.global_position)
	for s: Vector3 in shapes:
		var twin := false
		for t: Vector3 in shapes:
			twin = twin or Vector2(s.x + t.x, s.z + t.z).length() < 0.02
		_check(twin, "landmark collider at %s has no mirror" % s)
	var bad := 0
	for i in 600:
		var p := Vector3(-60.0 + fmod(i * 7.31, 120.0), 0, -60.0 + fmod(i * 13.77, 120.0))
		if river.is_water(p) != river.is_water(-p) or river.is_ford(p) != river.is_ford(-p) \
				or river.is_bridge(p) != river.is_bridge(-p):
			bad += 1
		var b: int = river.bank_of(p)
		var bm: int = river.bank_of(-p)
		if (b == -1) != (bm == -1) or (b != -1 and b == bm):
			bad += 1
	_check(bad == 0, "river queries not point-symmetric at %d samples" % bad)


# ---------------------------------------------------------------- navmesh

func _navmesh_checks(river: Node) -> void:
	var nm: NavigationMesh = main.nav_region.navigation_mesh
	var verts := nm.get_vertices()
	var in_water := 0
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		var c := Vector3.ZERO
		for k in poly.size():
			var v := verts[poly[k]]
			var w := verts[poly[(k + 1) % poly.size()]]
			c += v
			if river.is_water(v) or river.is_water((v + w) * 0.5):
				in_water += 1
		c /= float(poly.size())
		if river.is_water(c):
			in_water += 1
	_check(nm.get_polygon_count() > 50, "navmesh baked (%d polygons)" % nm.get_polygon_count())
	_check(in_water == 0, "%d navmesh vertices / edges / centres in deep water" % in_water)
	# Every deep-water mask cell is off the navmesh (the closest navmesh point is away from it).
	var map: RID = main.nav_region.get_navigation_map()
	var img: Image = river.mask_image()
	var on_mesh := 0
	var n := 0
	for j in range(0, 240, 2):
		for i in range(0, 240, 2):
			if img.get_pixel(i, j).r < 0.5:
				continue
			var p := Vector3(-60.0 + 0.5 * (i + 0.5), 0, -60.0 + 0.5 * (j + 0.5))
			n += 1
			var q := NavigationServer3D.map_get_closest_point(map, p)
			if _flat(p, q) < 0.2:
				on_mesh += 1
	_check(n > 200 and on_mesh == 0, "deep water on the navmesh at %d of %d cells" % [on_mesh, n])
	# Crossings stay walkable: the navmesh reaches every crossing centre.
	for c: Dictionary in river.crossings():
		var q := NavigationServer3D.map_get_closest_point(map, c["center"])
		_check(_flat(q, c["center"]) < 0.3, "crossing %s on the navmesh (%.2f m)" % [c["id"], _flat(q, c["center"])])


func _path_length(map: RID, a: Vector3, b: Vector3) -> float:
	var path := NavigationServer3D.map_get_path(map, a, b, true)
	var l := 0.0
	for k in range(1, path.size()):
		l += path[k - 1].distance_to(path[k])
	if path.is_empty() or _flat(path[path.size() - 1], b) > 1.0:
		return -1.0
	return l


## The nearest ground-level navmesh point to `p` (not an island on top of a building), searching rings around it.
func _ground_snap(map: RID, p: Vector3) -> Vector3:
	var q := NavigationServer3D.map_get_closest_point(map, p)
	if q.y < 0.8:
		return q
	for step in range(2, 20):
		var r := 0.5 * step
		for a in 16:
			var c := p + Vector3(cos(TAU * a / 16.0) * r, 0, sin(TAU * a / 16.0) * r)
			var s := NavigationServer3D.map_get_closest_point(map, c)
			if s.y < 0.8 and _flat(s, c) < 0.3:
				return s
	return q


## Navmesh path length from each keep's drop-off to mirrored targets differs by < 1 % (2.5). Measured as the
## geodesic on the baked navmesh (its ground polygons rasterised on the symmetric 0.5 m grid, AStarGrid2D octile:
## optimal, so only the navmesh itself can make the two sides differ). Godot's own corridor paths are noted too:
## their polygon-corridor choice is not optimal and differs between mirror runs even without the river (up to ~10 %).
func _path_checks() -> void:
	var map: RID = main.nav_region.get_navigation_map()
	# Own natural, both rich nodes, both tavern doors, the 4 post doors, then crossings, points and camps.
	var targets: Array[Vector3] = [Vector3(-16, 0, 6), Vector3(-40, 0, -40), Vector3(40, 0, 40), Vector3(-11.5, 0, -11.5),
		Vector3(11.5, 0, 11.5), Vector3(-49, 0, 1), Vector3(-1, 0, 49), Vector3(49, 0, -1), Vector3(1, 0, -49)]
	var S: Dictionary = (load("res://scripts/world/skirmish.gd") as GDScript).get_script_constant_map()
	for c: Dictionary in S["CROSSINGS"]:
		targets.append(c["center"])
	for s: Dictionary in S["POINT_SPOTS"] + S["CAMP_SPOTS"]:
		targets.append(s["pos"])
	# The walkable grid: ground-level navmesh polygons rasterised at the 0.5 m cell centres (mirror cell = 239 - i).
	var n := 240
	var walk := PackedByteArray()
	walk.resize(n * n)
	walk.fill(0)
	var nm: NavigationMesh = main.nav_region.navigation_mesh
	var verts := nm.get_vertices()
	var ground_y := 1.0e9
	for v in verts:
		ground_y = minf(ground_y, v.y)
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		var p2 := PackedVector2Array()
		var high := false
		for k in poly.size():
			var v := verts[poly[k]]
			high = high or v.y > ground_y + 0.6
			p2.append(Vector2(v.x, v.z))
		if high:
			continue   # tops of buildings / props
		var box := Rect2(p2[0], Vector2.ZERO)
		for q in p2:
			box = box.expand(q)
		for cj in range(maxi(0, int((box.position.y + 60.0) / 0.5)), mini(n, int((box.end.y + 60.0) / 0.5) + 1)):
			for ci in range(maxi(0, int((box.position.x + 60.0) / 0.5)), mini(n, int((box.end.x + 60.0) / 0.5) + 1)):
				if Geometry2D.is_point_in_polygon(Vector2(-60.0 + 0.5 * (ci + 0.5), -60.0 + 0.5 * (cj + 0.5)), p2):
					walk[cj * n + ci] = 1
	var asym := 0
	for idx in n * n:
		if walk[idx] != walk[n * n - 1 - idx]:
			asym += 1
	_notes.append("walkable grid: %d of %d cells differ from their mirror" % [asym, n * n])
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, n, n)
	grid.cell_size = Vector2(1, 1)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for idx in n * n:
		if walk[idx] == 0:
			grid.set_point_solid(Vector2i(idx % n, idx / n), true)
	var cell_of := func(p: Vector3) -> Vector2i:   # the nearest walkable cell (square rings)
		var c0 := Vector2i(clampi(int((p.x + 60.0) / 0.5), 0, n - 1), clampi(int((p.z + 60.0) / 0.5), 0, n - 1))
		for r in 30:
			for dj in range(-r, r + 1):
				for di in range(-r, r + 1):
					if maxi(absi(di), absi(dj)) != r:
						continue
					var c := c0 + Vector2i(di, dj)
					if c.x >= 0 and c.y >= 0 and c.x < n and c.y < n and walk[c.y * n + c.x] != 0:
						return c
		return c0
	var geo := func(a: Vector2i, b: Vector2i) -> float:
		var ids := grid.get_id_path(a, b)
		if ids.is_empty():
			return -1.0
		var l := 0.0
		for k in range(1, ids.size()):
			l += 1.4142136 if ids[k].x != ids[k - 1].x and ids[k].y != ids[k - 1].y else 1.0
		return l * 0.5
	var from_p: Vector2i = cell_of.call(main.keep_of(P).spawn_point())
	var from_e := Vector2i(n - 1 - from_p.x, n - 1 - from_p.y)
	_check(walk[from_e.y * n + from_e.x] != 0, "the enemy keep's drop-off cell mirrors the player's")
	var worst := 0.0
	var worst_at := Vector3.ZERO
	var godot_worst := 0.0
	var sample: float = geo.call(from_p, cell_of.call(Vector3(40, 0, 40)))
	_check(sample > 70.0 and sample < 200.0,"geodesic keep -> the other rich node is sane (%.1f m)" % sample)
	_notes.append("geodesic player keep -> enemy-side rich node: %.1f m" % sample)
	var from_gp := _ground_snap(map, main.keep_of(P).spawn_point())
	for t in targets:
		var tp: Vector2i = cell_of.call(t)
		var te := Vector2i(n - 1 - tp.x, n - 1 - tp.y)
		var lp: float = geo.call(from_p, tp)
		var le: float = geo.call(from_e, te)
		if lp < 0.0 or le < 0.0:
			_check(false, "no navmesh path from a keep to %s (%.1f / %.1f)" % [t, lp, le])
			continue
		var diff := absf(lp - le) / maxf(lp, le)
		if diff > worst:
			worst = diff
			worst_at = t
		_check(diff < 0.01, "navmesh path lengths to %s differ %.2f %% (%.1f vs %.1f)" % [t, diff * 100.0, lp, le])
		var tg := _ground_snap(map, t)
		var gp := _path_length(map, from_gp, tg)
		var ge := _path_length(map, -from_gp, -tg)
		if gp > 0.0 and ge > 0.0:
			godot_worst = maxf(godot_worst, absf(gp - ge) / maxf(gp, ge))
	_notes.append("path fairness (navmesh geodesic): %d mirrored targets, worst %.2f %% at %s" % [targets.size(),
			worst * 100.0, worst_at])
	_notes.append("Godot corridor paths (not optimal, informative only): worst %.2f %%" % (godot_worst * 100.0))


# ---------------------------------------------------------------- shader, services, fog, waystones

func _ground_mat() -> ShaderMaterial:
	for c in main.nav_region.get_children():
		if c is StaticBody3D and c.get_script() == null:
			for m in c.get_children():
				if m is MeshInstance3D and m.mesh is PlaneMesh and m.material_override is ShaderMaterial:
					return m.material_override
	return null


func _shader_checks(river: Node) -> void:
	var sp: Dictionary = river.shader_params()
	_check(int(sp[&"river_count"]) == 10 and (sp[&"river_segs"] as PackedVector4Array).size() == 16
			and (sp[&"fords"] as PackedVector4Array).size() == 4 and int(sp[&"ford_count"]) == 4
			and sp[&"moat"] == Vector4(0, 0, 12.75, 1.75) and is_equal_approx(float(sp[&"river_half_width"]), 2.5),
			"shader_params: 10 segments, 4 fords, moat, half width")
	var gp_path := "res://art/environment/ground_params.gd"
	if ResourceLoader.exists(gp_path):
		var gp: GDScript = load(gp_path)
		var want: Dictionary = gp.call(&"river", river.polylines(), 2.5, Vector4(0, 0, 12.75, 1.75),
				[Vector4(-8.5, -34, 3.5, 0), Vector4(8.5, 34, 3.5, 0), Vector4(-9.02, -9.02, 3, 0), Vector4(9.02, 9.02, 3, 0)])
		for k in want:
			_check(sp.has(k) and str(sp[k]) == str(want[k]), "shader_params[%s] = GroundParams.river() (%s vs %s)"
					% [k, sp.get(k), want[k]])
	var plain := ShaderMaterial.new()
	plain.shader = Shader.new()
	plain.shader.code = "shader_type spatial;\nvoid fragment() { ALBEDO = vec3(1.0); }\n"
	_check(not EnvProps.set_river(plain, sp), "set_river is a no-op without river uniforms")
	_check(plain.get_shader_parameter(&"river_count") == null, "set_river changed nothing on a plain shader")
	var gm := _ground_mat()
	if gm and gm.shader and gm.shader.code.contains("river_segs"):
		_check(int(gm.get_shader_parameter(&"river_count")) == 10, "the skirmish ground cuts the river (river_count 10)")
		if gm.shader.code.contains("biome_amount"):
			_check(float(gm.get_shader_parameter(&"biome_amount")) == 1.0, "the skirmish ground has the biome tints on")
	else:
		_notes.append("ground shader without river uniforms: set_river skipped")


func _service_checks() -> void:
	var tree := root.get_tree()
	var rows := [["res://scripts/world/capture_points.gd", "capture_points", "capture_points_service"],
		["res://scripts/world/camp_manager.gd", "camp_manager", "camp_manager"],
		["res://scripts/world/epic_beasts.gd", "epic_beasts", "epic_beasts"],
		["res://scripts/world/critter_herds.gd", "critter_herds", "critter_herds"]]
	for r in rows:
		var script: GDScript = load(r[0]) if ResourceLoader.exists(r[0]) else null
		if script == null or not script.can_instantiate():
			_notes.append("%s missing or not compiling: not created (load guard)" % r[0])
			_check(main.get(r[1]) == null, "%s: nothing created without a working script" % r[1])
			continue
		var svc: Node = main.get(r[1])
		_check(svc != null and is_instance_valid(svc) and svc.get_parent() == main, "%s created as a child of the level" % r[1])
	var cp: Node = main.get("capture_points")
	if cp and is_instance_valid(cp):
		var pts := tree.get_nodes_in_group("capture_points")
		_check(pts.size() == 8, "8 capture points (%d)" % pts.size())
		for p: Node3D in pts:
			_check(main.nav_region.is_ancestor_of(p), "point %s under the NavigationRegion3D (cuts the navmesh)" % p.name)
			for team in [P, E]:
				_check(main.fog.is_explored(team, p.global_position), "point %s explored for team %d at 0:00" % [p.name, team])
		_check(String(main.end_screen_text()).contains("Points held at the end"), "end-screen map-fill line")
	for lm: Node3D in main.get("landmarks"):
		for team in [P, E]:
			_check(main.fog.is_explored(team, lm.global_position), "landmark %s explored for team %d" % [lm.name, team])


func _waystone_checks(river: Node) -> void:
	var found := false
	for c in main.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi == null or not String(mmi.name).to_lower().contains("waystone") or mmi.multimesh == null:
			continue
		found = true
		for i in mmi.multimesh.instance_count:
			var p := mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin
			for id in [&"bridge_road_n", &"bridge_road_s"]:
				var bc: Vector3 = river.crossing(id)["center"]
				_check(_flat(p, bc) >= 7.0, "waystone at %s within 7 m of %s" % [p, id])
	if not found:
		_notes.append("no waystone row (art missing)")


# ---------------------------------------------------------------- crown drops, walking, fords, push-out

func _crown_drop_checks() -> void:
	for w in main.wardens.duplicate():
		w.take_damage(1.0e6, main.hero)
	await _frames(3)
	_check(main.wardens_killed == 4, "4 wardens killed")
	if not (ResourceLoader.exists(ItemDrops.PICKUP_PATH) and ResourceLoader.exists("res://data/items/warden_scale.tres")):
		_notes.append("items not there: crown drops not spawned")
		return
	for spot: Vector3 in [Vector3(2, 0, 2), Vector3(-2, 0, -2)]:
		var near := 0
		for n in root.get_tree().get_nodes_in_group("item_pickups"):
			if n is Node3D and _flat((n as Node3D).global_position, spot) < 0.8:
				near += 1
		_check(near == 1, "one crown drop at %s (%d)" % [spot, near])


func _soldier(at: Vector3, team: int = P) -> Unit:
	var u: Unit = main.make_unit("flame_guard")
	u.team = team
	main.add_child(u)
	u.global_position = at
	u.command_hold()
	return u


func _walk_checks(river: Node) -> void:
	var map: RID = main.nav_region.get_navigation_map()
	var path := NavigationServer3D.map_get_path(map, Vector3(-20, 0, 0), Vector3(20, 0, 0), true)
	var wet := 0
	for k in range(1, path.size()):
		for s in 20:
			if river.is_water(path[k - 1].lerp(path[k], s / 20.0)):
				wet += 1
	_check(path.size() >= 2 and wet == 0, "the path (-20, 0) -> (20, 0) stays out of deep water (%d wet samples)" % wet)
	var u := _soldier(Vector3(-20, 0, 0))
	u.command_move(Vector3(20, 0, 0))
	var min_r := INF
	var wet_frames := 0
	for i in 1800:
		await process_frame
		if not is_instance_valid(u):
			break
		var p := u.global_position
		min_r = minf(min_r, Vector2(p.x, p.z).length())
		if river.is_water(p):
			wet_frames += 1
		if _flat(p, Vector3(20, 0, 0)) < 1.5:
			break
	_check(is_instance_valid(u) and _flat(u.global_position, Vector3(20, 0, 0)) < 1.5,
			"the walker reached (20, 0) (at %s)" % (u.global_position if is_instance_valid(u) else Vector3.INF))
	_check(wet_frames == 0, "the walker was in deep water for %d frames" % wet_frames)
	_check(min_r < 11.0, "the walker crossed the isle (min r %.1f)" % min_r)
	if is_instance_valid(u):
		u.remove_from_group("units")
		u.queue_free()


func _ford_checks(river: Node) -> void:
	var ford := Vector3(-8.5, 0, -34)
	var u := _soldier(Vector3(-30, 0, 10))
	await _frames(2)
	var base: float = u.get_stat(&"move_speed")
	u.global_position = ford + Vector3(0.5, 0, 0)
	river.unit_pass()
	var slowed: float = u.get_stat(&"move_speed")
	_check(u.has_modifier(RiverSystem.FORD_MODIFIER) and absf(slowed / base - 0.65) < 0.005,
			"in a ford: move_speed x0.65 (%.2f -> %.2f)" % [base, slowed])
	u.global_position = ford + Vector3(3.5 + 0.2, 0, 0)
	river.unit_pass()
	_check(u.has_modifier(RiverSystem.FORD_MODIFIER), "0.2 m out of the ford: still slowed (hysteresis 0.3)")
	u.global_position = ford + Vector3(3.5 + 0.4, 0, 0)
	river.unit_pass()
	_check(not u.has_modifier(RiverSystem.FORD_MODIFIER) and is_equal_approx(u.get_stat(&"move_speed"), base),
			"0.4 m out of the ford: normal speed")
	u.global_position = Vector3(-9.02, 0, -9.02)   # the Crown Steps are a ford too
	river.unit_pass()
	_check(u.has_modifier(RiverSystem.FORD_MODIFIER), "Crown Steps slow too")
	river.ford_modifier_enabled = false
	river.unit_pass()
	_check(not u.has_modifier(RiverSystem.FORD_MODIFIER), "ford_modifier_enabled false: the modifier is removed")
	river.unit_pass()
	_check(not u.has_modifier(RiverSystem.FORD_MODIFIER), "ford_modifier_enabled false: never applied")
	river.ford_modifier_enabled = true
	var amph := _soldier(ford + Vector3(-0.5, 0, 0))
	amph.add_to_group("amphibious")
	await _frames(1)
	river.unit_pass()
	_check(not amph.has_modifier(RiverSystem.FORD_MODIFIER), "amphibious units are not slowed")
	# The pass alone (5 Hz) slows a unit that walks in.
	u.global_position = ford
	await _frames(15)
	_check(u.has_modifier(RiverSystem.FORD_MODIFIER), "the 5 Hz pass slows a unit in the ford")
	for x in [u, amph]:
		x.remove_from_group("units")
		x.queue_free()


func _push_checks(river: Node) -> void:
	var map: RID = main.nav_region.get_navigation_map()
	for spot: Vector3 in [Vector3(-6.5, 0, -25.5), Vector3(-12.75, 0, 0), Vector3(6.5, 0, 25.5)]:
		var u := _soldier(Vector3(-30, 0, 10))
		await _frames(2)
		u.global_position = spot
		u.command_hold()
		await _frames(18)   # 0.3 s
		var p := u.global_position
		_check(not river.is_water(p), "a unit teleported to %s is back on land within 0.3 s (at %s)" % [spot, p])
		_check(_flat(NavigationServer3D.map_get_closest_point(map, p), p) < 0.3, "...on the navmesh (%s)" % p)
		u.remove_from_group("units")
		u.queue_free()


func _perf_checks(river: Node) -> void:
	var extra: Array[Unit] = []
	for i in 180:
		var p := Vector3(-50.0 + float(i % 20) * 5.0, 0, -45.0 + floorf(i / 20.0) * 10.0)
		if river.is_water(p):
			p = river.nearest_land(p)
		var u: Unit = main.make_unit("flame_guard")
		u.team = P
		main.add_child(u)
		u.global_position = p
		extra.append(u)
	var n := root.get_tree().get_nodes_in_group("units").size()
	var t0 := Time.get_ticks_usec()
	for k in 20:
		river.unit_pass()
	var per_pass := (Time.get_ticks_usec() - t0) / 1000.0 / 20.0
	_notes.append("unit pass: %.3f ms for %d units (%.4f ms / frame at 5 Hz)" % [per_pass, n, per_pass / 12.0])
	_check(per_pass / 12.0 < 0.05, "the 5 Hz pass costs < 0.05 ms / frame on average (%.4f)" % (per_pass / 12.0))
	var t1 := Time.get_ticks_usec()
	for k in 200:
		river.distance_to_water(Vector3(-20.0 + k * 0.1, 0, 30.0))
	_notes.append("distance_to_water: %.3f ms per call" % ((Time.get_ticks_usec() - t1) / 1000.0 / 200.0))
	for u in extra:
		u.remove_from_group("units")
		u.queue_free()
