extends SceneTree
## Seat probe (map gate G5 diagnostics): loads a LayoutLevel, waits for the navmesh, then prints per seat the bot's
## points (node roles, halls, slots, rally / anchor, every Commander ROWS slot through bot_point) and the navmesh path
## lengths the economy and the attacks use, next to the other seat's value seen through the symmetry (rot180: -p).
## Any line marked "!!" differs by more than 0.5 m (positions) or 2 % + 0.5 m (path lengths).
## Run: tools\godot_run.ps1 --headless --path . -s res://tools/map_lab/seat_probe.gd '--' map=res://data/maps/thornwater_layout.tres

const COMMANDER := preload("res://scripts/ai/commander.gd")

var level: Node = null
var wait := 0
var lines: Array[String] = []
var flags := 0


func _initialize() -> void:
	var map_path := "res://data/maps/thornwater_layout.tres"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("map="):
			map_path = a.substr(4)
	var lay: Resource = LayoutLevel.load_layout(map_path)
	if lay == null:
		print("SEAT PROBE: no layout %s" % map_path)
		quit(2)
		return
	level = (load("res://scenes/layout_level.tscn") as PackedScene).instantiate()
	level.set(&"layout", lay)
	if OS.get_cmdline_user_args().has("swap=1"):
		level.set(&"swap_sides", true)   # the PLAYER on the side-1 seat (LayoutLevel.swap_sides)
	_disable(level)
	root.add_child(level)


func _disable(n: Node) -> void:
	for c: Node in n.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.contains("/ai/") and &"enabled" in c:
			c.set(&"enabled", false)


func _process(_d: float) -> bool:
	_disable(level)
	if level.get(&"hero") == null:
		wait += 1
		if wait > 6000:
			print("SEAT PROBE: level never started")
			quit(1)
		return false
	wait += 1
	if wait < 30:
		return false
	_probe()
	print("\n".join(lines))
	print("SEAT PROBE %s: %d asymmetries" % [String(level.get(&"layout").get(&"id")), flags])
	quit(0)
	return true


func _mirror(p: Vector3) -> Vector3:
	var sym := String(level.get(&"layout").get(&"symmetry"))
	if sym == "rot180":
		return Vector3(-p.x, p.y, -p.z)
	return p


func _pos(label: String, a: Vector3, b: Vector3) -> void:
	if a == Vector3.INF or b == Vector3.INF:
		lines.append("  %-26s P %s  E %s" % [label, _xz(a), _xz(b)])
		return
	var d := Vector2(_mirror(a).x - b.x, _mirror(a).z - b.z).length()
	var ba := int(level.call(&"bank_of", a))
	var bb := int(level.call(&"bank_of", b))
	var mark := " !!" if d > 0.5 or (ba == 0) != (bb == 1) else ""
	if mark != "":
		flags += 1
	lines.append("  %-26s P %s  E %s  sym err %.2f m  bank %d / %d%s" % [label, _xz(a), _xz(b), d, ba, bb, mark])


func _xz(p: Vector3) -> String:
	return "inf" if p == Vector3.INF else "(%.1f, %.1f)" % [p.x, p.z]


func _path_len(a: Vector3, b: Vector3) -> float:
	if a == Vector3.INF or b == Vector3.INF:
		return -1.0
	var nav: RID = (level as Node3D).get_world_3d().navigation_map
	var pa := NavigationServer3D.map_get_closest_point(nav, a)
	var pb := NavigationServer3D.map_get_closest_point(nav, b)
	var path := NavigationServer3D.map_get_path(nav, pa, pb, true)
	if path.is_empty():
		return -1.0
	var l := 0.0
	for i in range(1, path.size()):
		l += Vector2(path[i].x - path[i - 1].x, path[i].z - path[i - 1].z).length()
	var gap := Vector2(path[path.size() - 1].x - pb.x, path[path.size() - 1].z - pb.z).length()
	return l + (gap * 100.0 if gap > 1.0 else 0.0)   # unreachable ends show as a huge length


func _len(label: String, pa: float, pe: float) -> void:
	var mark := ""
	if pa < 0.0 or pe < 0.0 or absf(pa - pe) > 0.5 + 0.02 * maxf(pa, pe):
		mark = " !!"
		flags += 1
	lines.append("  %-26s P %7.1f  E %7.1f  diff %+6.1f%s" % [label, pa, pe, pe - pa, mark])


func _probe() -> void:
	var lv := level
	var P := 0
	var E := 1
	lines.append("== positions (player seat, enemy seat, error of the enemy's vs the player's seen through the symmetry)")
	_pos("keep", lv.base_center(P), lv.base_center(E))
	_pos("start", lv.start_position(P), lv.start_position(E))
	var roles: Dictionary = lv.get(&"_node_role")
	for role: String in ["a", "b", "mid", "rich", "third"]:
		_pos("node %s (%s / %s)" % [role, (roles.get(P, {}) as Dictionary).get(role, "-"), (roles.get(E, {}) as Dictionary).get(role, "-")],
				lv.call(&"_node_spot_pos", P, role), lv.call(&"_node_spot_pos", E, role))
	_pos("natural hall", lv.natural_hall_spot(P), lv.natural_hall_spot(E))
	_pos("rich hall", lv.rich_hall_spot(P), lv.rich_hall_spot(E))
	_pos("market", lv.market_slot(P), lv.market_slot(E))
	_pos("tower natural", lv.tower_slot(P, &"natural"), lv.tower_slot(E, &"natural"))
	_pos("tower rich", lv.tower_slot(P, &"rich"), lv.tower_slot(E, &"rich"))
	for key: StringName in [&"rally", &"anchor", &"hub", &"crown"]:
		_pos("mark " + String(key), lv.bot_mark(P, key), lv.bot_mark(E, key))
	for row: Dictionary in COMMANDER.ROWS:
		var p: Vector3 = row["pos"]
		if p != Vector3.INF:
			_pos("row %s %s" % [row["id"], row["kind"]], lv.bot_point(P, p), lv.bot_point(E, p))
	var sp: Array = lv.bot_scout_path(P)
	var se: Array = lv.bot_scout_path(E)
	for i in mini(sp.size(), se.size()):
		_pos("scout %d" % i, sp[i], se[i])
	lines.append("== navmesh path lengths (m)")
	var kp: Vector3 = lv.start_position(P)   # the keep itself is off the navmesh: its front door (the start)
	var ke: Vector3 = lv.start_position(E)
	for role: String in ["a", "b", "mid", "rich", "third"]:
		_len("keep -> node " + role, _path_len(kp, lv.call(&"_node_spot_pos", P, role)),
				_path_len(ke, lv.call(&"_node_spot_pos", E, role)))
	for role: String in ["mid", "rich", "third"]:
		_len("hall -> node %s (nat)" % role, _path_len(lv.natural_hall_spot(P), lv.call(&"_node_spot_pos", P, role)),
				_path_len(lv.natural_hall_spot(E), lv.call(&"_node_spot_pos", E, role)))
	_len("rich hall -> node rich", _path_len(lv.rich_hall_spot(P), lv.call(&"_node_spot_pos", P, &"rich")),
			_path_len(lv.rich_hall_spot(E), lv.call(&"_node_spot_pos", E, &"rich")))
	_len("keep -> natural hall", _path_len(kp, lv.natural_hall_spot(P)), _path_len(ke, lv.natural_hall_spot(E)))
	_len("keep -> rich hall", _path_len(kp, lv.rich_hall_spot(P)), _path_len(ke, lv.rich_hall_spot(E)))
	_len("keep -> crown", _path_len(kp, lv.bot_mark(P, &"crown")), _path_len(ke, lv.bot_mark(E, &"crown")))
	_len("keep -> enemy keep", _path_len(kp, ke), _path_len(ke, kp))
	_len("rally -> enemy keep", _path_len(lv.bot_mark(P, &"rally"), ke), _path_len(lv.bot_mark(E, &"rally"), kp))
	_len("rally -> enemy natural", _path_len(lv.bot_mark(P, &"rally"), lv.natural_hall_spot(E)),
			_path_len(lv.bot_mark(E, &"rally"), lv.natural_hall_spot(P)))
	_len("rally -> enemy rich hall", _path_len(lv.bot_mark(P, &"rally"), lv.rich_hall_spot(E)),
			_path_len(lv.bot_mark(E, &"rally"), lv.rich_hall_spot(P)))
	_len("keep -> enemy node mid", _path_len(kp, lv.call(&"_node_spot_pos", E, "mid")),
			_path_len(ke, lv.call(&"_node_spot_pos", P, "mid")))
	_len("keep -> enemy node rich", _path_len(kp, lv.call(&"_node_spot_pos", E, "rich")),
			_path_len(ke, lv.call(&"_node_spot_pos", P, "rich")))
	for t: int in [P, E]:
		var nav: RID = (level as Node3D).get_world_3d().navigation_map
		var a: Vector3 = lv.start_position(t)
		var b: Vector3 = lv.call(&"_node_spot_pos", t, "a")
		var pb := NavigationServer3D.map_get_closest_point(nav, b)
		var path := NavigationServer3D.map_get_path(nav, NavigationServer3D.map_get_closest_point(nav, a), pb, true)
		var pts: Array[String] = []
		for q in path:
			pts.append(_xz(_mirror(q) if t == E else q))
		lines.append("  node a path team %d (seat-0 frame): end %s -> %s" % [t, _xz(_mirror(pb) if t == E else pb), " ".join(pts)])
	# what stands around each seat's home node a (the navmesh path of seat 0 detours there): every Node3D within 7 m
	for t: int in [P, E]:
		var c: Vector3 = lv.call(&"_node_spot_pos", t, "a")
		var found: Array[String] = []
		for n: Node in level.find_children("*", "Node3D", true, false):
			var p := (n as Node3D).global_position
			if Vector2(p.x - c.x, p.z - c.z).length() < 7.0 and not (n is MeshInstance3D):
				var q := _mirror(p) if t == E else p
				found.append("%s<%s>%s" % [n.name, n.get_class(), _xz(q)])
		found.sort()
		lines.append("  near node a team %d (seat-0 frame): %s" % [t, ", ".join(found)])
	# every neutral spot of the layout (camps, points, lairs, caches, taverns, posts): the nearer of the two seats
	lines.append("== neutral spots: keep path length per seat for each spot and its symmetric twin")
	var lay: MapLayout = lv.get(&"layout")
	for kind: String in ["camp", "point", "lair", "cache", "tavern", "peddler", "post", "guild", "crown"]:
		for s: Dictionary in lay.spots_of(kind):
			if String(s.get("image", "identity")) != "identity":
				continue
			var p: Vector3 = s["pos"]
			_len("%s %s" % [kind, s["id"]], _path_len(kp, p), _path_len(ke, _mirror(p)))
