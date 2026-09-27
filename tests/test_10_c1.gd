extends SceneTree
## Task 10.C1 (docs/design/market-trade.md 2, 4.3, 5.4, 12; "Done when" 10.C1): the trade map on Crown Hollow
## (posts, guild houses, corridors, clearings, landmarks explored at 0:00, posts open at 4:00), TradeNetwork
## (route length / value / points, ambush spots, remote nodes, holders, strength, ledger, losses), LootSack, the
## M1 / S3 / S4 slots, the end-screen line and `trade_enabled = false` (the step-9 map, nothing created).
## Part 1 loads the skirmish with trade off, part 2 with trade on (bot disabled in both).
## Other step-10 parts may be missing: GoldBank is stubbed when gold_bank.gd does not exist; the Thieves' /
## Hunters' guild services are paused so no Magpie band walks into the checks.
## Run:  godot --headless --path . -s tests/test_10_c1.gd --fixed-fps 60 --quit-after 14000

const TASK_ID := "10.C1"
const TIMEOUT_FRAMES := 13500
const SCENE := "res://scenes/skirmish.tscn"
const GOLD_BANK_PATH := "res://scripts/economy/gold_bank.gd"
const P := 0
const E := 1
const N := 2
const POSTS := {
	&"heron_ford": [Vector3(-53, 0, 1), Vector3(-49, 0, 1)],
	&"millstone_cross": [Vector3(-1, 0, 53), Vector3(-1, 0, 49)],
	&"lantern_wharf": [Vector3(53, 0, -1), Vector3(49, 0, -1)],
	&"saltgate": [Vector3(1, 0, -53), Vector3(1, 0, -49)],
}
const HOUSES := [
	[&"den", Vector3(-55, 0, -45), Vector3(-51, 0, -45)], [&"den", Vector3(55, 0, 45), Vector3(51, 0, 45)],
	[&"lodge", Vector3(-45, 0, -55), Vector3(-45, 0, -51)], [&"lodge", Vector3(45, 0, 55), Vector3(45, 0, 51)],
]
## From a Bazaar at (-45, 27) (player) / (45, -27) (enemy): post -> [L, V].
const ROUTES_P := {&"heron_ford": [26.3, 15], &"millstone_cross": [49.2, 28], &"saltgate": [122.0, 119],
		&"lantern_wharf": [144.9, 154]}
const ROUTES_E := {&"lantern_wharf": [26.3, 15], &"saltgate": [49.2, 28], &"millstone_cross": [122.0, 119],
		&"heron_ford": [144.9, 154]}
const SPOT := {
	&"A1": Vector3(-44, 0, 15), &"A2": Vector3(-15, 0, 44), &"A3": Vector3(-48, 0, -22), &"A4": Vector3(-22, 0, -48),
	&"A1m": Vector3(44, 0, -15), &"A2m": Vector3(15, 0, -44), &"A3m": Vector3(48, 0, 22), &"A4m": Vector3(22, 0, 48),
}
## Section 2.4: [team, post, spots from the post end back toward the base].
const AMBUSH_TABLE := [
	[P, &"heron_ford", [&"A1"]], [P, &"millstone_cross", [&"A2"]], [P, &"saltgate", [&"A4", &"A3", &"A1"]],
	[P, &"lantern_wharf", [&"A3m", &"A4m", &"A2"]], [E, &"lantern_wharf", [&"A1m"]], [E, &"saltgate", [&"A2m"]],
	[E, &"millstone_cross", [&"A4m", &"A3m", &"A1m"]], [E, &"heron_ford", [&"A3", &"A4", &"A2m"]],
]
const SEGMENTS := [
	[Vector3(-36, 0, 36), Vector3(-49, 0, 1)], [Vector3(-49, 0, 1), Vector3(-48, 0, -44)],
	[Vector3(-48, 0, -44), Vector3(-44, 0, -48)], [Vector3(-44, 0, -48), Vector3(1, 0, -49)],
	[Vector3(1, 0, -49), Vector3(36, 0, -36)], [Vector3(36, 0, -36), Vector3(49, 0, -1)],
	[Vector3(49, 0, -1), Vector3(48, 0, 44)], [Vector3(48, 0, 44), Vector3(44, 0, 48)],
	[Vector3(44, 0, 48), Vector3(-1, 0, 49)], [Vector3(-1, 0, 49), Vector3(-36, 0, 36)],
]


class StubMarket extends Node3D:
	var team := 0


## Enough of GoldBank for the sacks and the end screen (used only while gold_bank.gd does not exist).
class StubBank extends Node:
	var team := 0
	var gold := 0
	var by_source := {}

	func add(n: int, source: StringName = &"") -> void:
		gold += n
		by_source[source] = int(by_source.get(source, 0)) + n


var main: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _off_obstacles := {}      # "x,z" -> [Vector3 pos, float extra]
var _opened := 0
var _held_events: Array = []
var _delivered := 0
var _picked: Array = []


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


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(a.x, a.z), Vector2(b.x, b.z))
	return q.distance_to(Vector2(p.x, p.z))


func _road_dist(p: Vector3) -> float:
	var best := INF
	for s in SEGMENTS:
		best = minf(best, _seg_dist(p, s[0], s[1]))
	return best


func _load_scene(trade: bool) -> bool:
	main = load(SCENE).instantiate()
	main.set(&"trade_enabled", trade)
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking (trade %s)" % trade)
		return false
	await _frames(5)
	return true


## Trees and rocks: the plain StaticBody3D obstacles under the NavigationRegion3D (not the ground, not
## pillars). Returns "x,z" -> [pos, footprint reach from the centre].
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
		if col.shape is BoxShape3D:
			var size: Vector3 = (col.shape as BoxShape3D).size
			if size.x > 50.0:
				continue   # the ground
			extra = size.x * 0.5
		elif col.shape is CylinderShape3D:
			var r: float = (col.shape as CylinderShape3D).radius
			if r >= 0.69:
				continue   # a ruin pillar
			extra = r
		else:
			continue
		var p := body.global_position
		out["%.2f,%.2f" % [p.x, p.z]] = [p, extra]
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


## trade_enabled = false: nothing of step 10 exists; remembers the forest for part 2.
func _part_off() -> void:
	_check(root.get_tree().get_nodes_in_group("trade_posts").is_empty(), "trade off: no trading posts")
	_check(root.get_tree().get_nodes_in_group("guilds").is_empty(), "trade off: no guild houses")
	_check(root.get_tree().get_nodes_in_group("gold_banks").is_empty(), "trade off: no GoldBank")
	_check(root.get_tree().get_nodes_in_group("trade_network").is_empty() and main.get("trade_network") == null,
			"trade off: no TradeNetwork")
	_check(root.get_tree().get_nodes_in_group("thieves_guild").is_empty()
			and root.get_tree().get_nodes_in_group("hunters_guild").is_empty(), "trade off: no guild services")
	_check(root.get_tree().get_nodes_in_group("taverns").size() == 2, "trade off: step-9 taverns still there")
	_check(not String(main.end_screen_text()).contains("Gold earned"), "trade off: no gold line on the end screen")
	_check(not main.stats_of(P).has("gold_earned"), "trade off: no gold stats")
	_off_obstacles = _obstacles()
	var m1: Node = load("res://scripts/campaign/mission_01.gd").new()
	_check(not bool(m1.get("trade_enabled")), "mission 1 has no trade (trade_enabled false)")
	m1.free()


func _part_on() -> void:
	for path in ["thieves_guild", "hunters_guild"]:
		var svc: Node = root.get_tree().get_first_node_in_group(StringName(path))
		if svc:
			_check(svc.get_parent() == main, "%s is a child of the level" % path)
			var src: Variant = svc.get(&"match_time_source")
			_check(src is Callable and (src as Callable).is_valid(), "%s got match_time_source" % path)
			svc.process_mode = Node.PROCESS_MODE_DISABLED   # no bands / contracts during the checks
		else:
			_notes.append("%s script missing: service not created (load guard)" % path)
	var net: TradeNetwork = TradeNetwork.instance(root.get_tree())
	_check(net != null and net == main.get("trade_network"), "one TradeNetwork, reachable with instance()")
	if net == null:
		return
	net.posts_opened.connect(func() -> void: _opened += 1)
	net.post_held_changed.connect(func(post: Node, team: int) -> void: _held_events.append([post, team]))
	net.delivered.connect(func(_t: int, _c: Node, _a: int, _p: Node) -> void: _delivered += 1)
	var fade_sack := LootSack.spawn(main, Vector3(10, 0, -40), 5)
	var fade_frame := total
	_check(fade_sack != null and fade_sack.is_in_group("loot_sacks"), "LootSack.spawn")
	_check(LootSack.spawn(main, Vector3(10, 0, -40), 0) == null, "no sack below 1 gold")

	_forest_checks()
	_post_checks(net)
	_house_checks()
	_bank_checks()
	_route_checks(net)
	_slot_checks()
	await _open_checks(net)
	await _held_checks(net)
	_ledger_checks(net)
	await _sack_checks(net)
	_loss_checks(net)
	_ground_checks()
	# The sack left alone fades at 45 s.
	await _until(func() -> bool: return total - fade_frame >= 44 * 60, 3000)
	_check(is_instance_valid(fade_sack) and fade_sack.is_available(), "sack still there at 44 s")
	await _frames(90)
	_check(not is_instance_valid(fade_sack) or not fade_sack.is_available(), "sack faded at 45 s")
	_check(not is_instance_valid(fade_sack) or not fade_sack.is_in_group("loot_sacks"), "faded sack left the group")
	# 10 s mining samples (the start workers mine home node a for ~48 s by now).
	net.refresh()
	var node_a: Node3D = main.node_of(P, "a")
	_check(node_a != null and net.workers_at(P, node_a).size() >= 1, "workers_at: the start workers mine home node a")
	_check(node_a != null and net.mined_recently(node_a, 1.0e6) > 0, "mined_recently: samples of home node a (%d)"
			% (net.mined_recently(node_a, 1.0e6) if node_a else -1))
	_check(node_a != null and net.mined_recently(node_a, 0.0) == 0, "mined_recently: empty window")


## No new obstacle; the removed ones are all in a corridor or a post / house clearing; none left in a corridor.
func _forest_checks() -> void:
	var on := _obstacles()
	var added := 0
	for k in on:
		if not _off_obstacles.has(k):
			added += 1
	_check(added == 0, "trade on adds no tree / rock (%d new)" % added)
	var removed := 0
	for k in _off_obstacles:
		if on.has(k):
			continue
		removed += 1
		var p: Vector3 = _off_obstacles[k][0]
		var extra: float = _off_obstacles[k][1]
		var why := _road_dist(p) < 2.5 + extra
		for id in POSTS:
			why = why or _flat(p, POSTS[id][0]) < 5.0
		for h in HOUSES:
			why = why or _flat(p, h[1]) < 6.0
		_check(why, "obstacle at %s removed although outside every corridor / clearing" % p)
	for k in on:
		var p: Vector3 = on[k][0]
		_check(_road_dist(p) >= 2.5, "tree / rock at %s within 2.5 m of a road (%.2f)" % [p, _road_dist(p)])
	_notes.append("forest: %d obstacles, %d removed for roads / posts / houses" % [_off_obstacles.size(), removed])


func _post_checks(net: TradeNetwork) -> void:
	var posts := root.get_tree().get_nodes_in_group("trade_posts")
	_check(posts.size() == 4 and net.posts().size() == 4, "4 trading posts (%d)" % posts.size())
	var map: RID = main.nav_region.get_navigation_map()
	var tower := BuildingType.find("fire_tower")
	for id in POSTS:
		var post: TradePost = net.post_by_id(id)
		_check(post != null, "post %s" % id)
		if post == null:
			continue
		var center: Vector3 = POSTS[id][0]
		var door: Vector3 = POSTS[id][1]
		_check(_flat(post.global_position, center) < 0.01, "%s at %s" % [id, center])
		_check(_flat(post.door_point(), door) < 0.05, "%s door %s (got %s)" % [id, door, post.door_point()])
		_check(post.team == N and not post.is_in_group("units") and not post.is_in_group("buildings"),
				"%s neutral, never a target" % id)
		post.take_damage(99999.0, null)
		_check(post.is_alive() and post.is_invulnerable() and not post.is_targetable(), "%s invulnerable" % id)
		_check((post.collision_layer & 3) == 3 and post.get_parent() == main.nav_region, "%s layers 1 + 2, under the nav region" % id)
		_check(post.footprint_rect().size == Vector2(6, 6), "%s 6 x 6 footprint" % id)
		_check(not post.is_open() and post.holder_team() == -1, "%s closed and free at 0:00" % id)
		for off in [Vector3.ZERO, Vector3(-2, 0, -2), Vector3(2, 0, 2), Vector3(-2, 0, 2), Vector3(2, 0, -2)]:
			var reason: String = main.build_grid.check(tower, center + off, P)
			_check(reason == BuildGrid.MSG_NOT_WALKABLE or reason == BuildGrid.MSG_BLOCKED,
					"build grid refuses a tower at %s (got '%s')" % [center + off, reason])
		for c in main.nav_region.get_children():
			if c is StaticBody3D and c != post and c.get_script() == null and _flat(c.global_position, center) < 5.0:
				_check(false, "post clearing: obstacle at %.1f m from %s" % [_flat(c.global_position, center), id])
		_nav_around(map, center, door, String(id))
		for team in [P, E]:
			_check(main.fog.is_explored(team, center) and main.fog.is_explored(team, door),
					"%s explored for team %d at 0:00" % [id, team])
	var segs := net.road_segments()
	_check(segs.size() == 10, "10 road segments (%d)" % segs.size())
	var lengths := []
	for s in segs:
		lengths.append(roundi(_flat(s[0], s[1]) * 10.0))
	_check(lengths.count(373) == 4 and lengths.count(450) == 4 and lengths.count(57) == 2, "segment lengths x10 %s" % [lengths])


## A path from the door to the far side goes around the body; the door is on the navmesh.
func _nav_around(map: RID, center: Vector3, door: Vector3, what: String) -> void:
	var back := center + (center - door)
	var path := NavigationServer3D.map_get_path(map, door, back, true)
	var length := 0.0
	for k in range(1, path.size()):
		length += path[k - 1].distance_to(path[k])
	_check(path.size() >= 2 and _flat(path[path.size() - 1], back) < 1.0 and length > door.distance_to(back) + 1.5,
			"%s: path door -> back goes around (%.1f m, straight %.1f)" % [what, length, door.distance_to(back)])
	var qd := NavigationServer3D.map_get_closest_point(map, door)
	_check(_flat(qd, door) < 0.6, "%s: door on the navmesh (%.2f m)" % [what, _flat(qd, door)])


func _house_checks() -> void:
	var houses := root.get_tree().get_nodes_in_group("guilds")
	_check(houses.size() == 4, "4 guild houses (%d)" % houses.size())
	var map: RID = main.nav_region.get_navigation_map()
	for h in HOUSES:
		var found: GuildHouse = null
		for n in houses:
			if n is GuildHouse and _flat(n.global_position, h[1]) < 0.01:
				found = n
		_check(found != null, "a guild house at %s" % h[1])
		if found == null:
			continue
		_check(found.kind == h[0], "%s kind %s" % [h[1], h[0]])
		_check(_flat(found.door_point(), h[2]) < 0.05, "%s door %s (got %s)" % [h[1], h[2], found.door_point()])
		_check(found.team == N and found.is_alive() and not found.is_targetable() and not found.is_in_group("units")
				and not found.is_in_group("buildings") and (found.collision_layer & 3) == 3, "%s neutral, invulnerable, clickable" % h[1])
		_check(not found.is_open(), "%s closed at 0:00" % h[1])
		for c in main.nav_region.get_children():
			if c is StaticBody3D and c != found and c.get_script() == null and _flat(c.global_position, h[1]) < 6.0:
				_check(false, "house clearing: obstacle at %.1f m from %s" % [_flat(c.global_position, h[1]), h[1]])
		var reason: String = main.build_grid.check(BuildingType.find("fire_tower"), h[1], P)
		_check(reason == BuildGrid.MSG_NOT_WALKABLE or reason == BuildGrid.MSG_BLOCKED, "build grid refuses %s ('%s')" % [h[1], reason])
		_nav_around(map, h[1], h[2], "house %s" % h[1])
		for team in [P, E]:
			_check(main.fog.is_explored(team, h[1]) and main.fog.is_explored(team, h[2]), "house %s explored for %d" % [h[1], team])


func _bank_checks() -> void:
	var banks := root.get_tree().get_nodes_in_group("gold_banks")
	if ResourceLoader.exists(GOLD_BANK_PATH):
		var teams := []
		for b in banks:
			teams.append(int(b.get(&"team")))
		teams.sort()
		_check(teams == [P, E], "one GoldBank per team (%s)" % [teams])
		_check(main.gold_bank_of(P) != null and main.gold_bank_of(E) != null, "gold_bank_of")
	else:
		_check(banks.is_empty(), "no GoldBank while gold_bank.gd is missing")
		_notes.append("gold_bank.gd missing: GoldBank stubbed for the sack checks")
		for team in [P, E]:
			var stub := StubBank.new()
			stub.team = team
			stub.add_to_group("gold_banks")
			main.add_child(stub)


func _route_checks(net: TradeNetwork) -> void:
	var mp := StubMarket.new()
	mp.team = P
	main.add_child(mp)
	mp.global_position = Vector3(-45, 0, 27)
	var me := StubMarket.new()
	me.team = E
	main.add_child(me)
	me.global_position = Vector3(45, 0, -27)
	for pair in [[mp, ROUTES_P], [me, ROUTES_E]]:
		var m: StubMarket = pair[0]
		var table: Dictionary = pair[1]
		for id in table:
			var post := net.post_by_id(id)
			var l := net.route_length(m, post)
			var v := net.route_value(m, post)
			_check(absf(l - float(table[id][0])) <= 0.2 and v == int(table[id][1]),
					"team %d -> %s: L %.2f V %d (want %.1f / %d)" % [m.team, id, l, v, table[id][0], table[id][1]])
	var rn: Dictionary = net.road_nodes()
	var want_points := [
		[mp, &"heron_ford", [&"w_door"]], [mp, &"millstone_cross", [&"s_door"]],
		[mp, &"saltgate", [&"w_door", &"nw1", &"nw2", &"n_door"]], [mp, &"lantern_wharf", [&"s_door", &"se2", &"se1", &"e_door"]],
		[me, &"heron_ford", [&"n_door", &"nw2", &"nw1", &"w_door"]], [me, &"lantern_wharf", [&"e_door"]],
	]
	for row in want_points:
		var pts := net.route_points(row[0], net.post_by_id(row[1]))
		var ok: bool = pts.size() == (row[2] as Array).size()
		if ok:
			for i in pts.size():
				ok = ok and _flat(pts[i], rn[row[2][i]]) < 0.01
		_check(ok, "route_points team %d -> %s follow the ring %s (got %s)" % [row[0].team, row[1], row[2], pts])
	for row in AMBUSH_TABLE:
		var got := net.ambush_spots(row[0], net.post_by_id(row[1]))
		var ok: bool = got.size() == (row[2] as Array).size()
		if ok:
			for i in got.size():
				ok = ok and _flat(got[i], SPOT[row[2][i]]) < 0.01
		_check(ok, "ambush_spots team %d %s = %s (got %s)" % [row[0], row[1], row[2], got])
	for id in POSTS:
		var post := net.post_by_id(id)
		var far_p: bool = id == &"lantern_wharf" or id == &"saltgate"
		_check(net.is_far(P, post) == far_p and net.is_far(E, post) == not far_p, "is_far %s" % id)
	_check(net.route_reason(mp, net.post_by_id(&"heron_ford")) == TradeNetwork.MSG_CLOSED,
			"route_reason before 4:00 (got '%s')" % net.route_reason(mp, net.post_by_id(&"heron_ford")))
	_check(net.route_reason(mp, mp) == TradeNetwork.MSG_NOT_POST, "route_reason: not a post")
	_check(TradeNetwork.value_for_length(10.0) == 11 and TradeNetwork.value_for_length(200.0) == 154, "value formula + cap")
	var short := StubMarket.new()
	main.add_child(short)
	short.global_position = Vector3(-52, 0, 8)
	var saved: float = main.get("_match_time")
	main.set("_match_time", 250.0)
	_check(net.route_reason(short, net.post_by_id(&"heron_ford")) == TradeNetwork.MSG_TOO_SHORT, "Route too short under 20 m")
	main.set("_match_time", saved)
	short.queue_free()
	# Remote nodes: the natural and both rich nodes for each team; never home nodes.
	for team in [P, E]:
		var ids := []
		for n in net.remote_nodes(team):
			ids.append(String(n.node_id))
		ids.sort()
		var own := "fire" if team == P else "shadow"
		var want := ["node_%s_mid" % own, "node_fire_rich", "node_shadow_rich"]
		want.sort()
		_check(ids == want, "remote_nodes(%d) = %s (got %s)" % [team, want, ids])
	_check(_flat(net.worker_spot(main.node_of(P, "mid")), Vector3(-8, 0, 16)) < 0.01, "W1 serves the player's natural")
	_check(_flat(net.worker_spot(main.node_of(P, "rich")), Vector3(-50, 0, -30)) < 0.01, "W2 serves the player-side rich node")
	_check(_flat(net.worker_spot(main.node_of(E, "mid")), Vector3(8, 0, -16)) < 0.01, "W1m serves the enemy natural")
	_check(net.worker_spot(main.node_of(P, "a")) == Vector3.INF, "no W spot for a home node")
	mp.set_meta(&"keep", true)


func _slot_checks() -> void:
	_check(main.market_slot(P) == Vector3(-45, 0, 27) and main.market_slot(E) == Vector3(45, 0, -27), "M1 slots")
	_check(main.tower_slot(P, &"S3") == Vector3(-19, 0, 1) and main.tower_slot(E, &"natural") == Vector3(19, 0, -1), "S3 slots")
	_check(main.tower_slot(P, &"rich") == Vector3(-37, 0, -45) and main.tower_slot(E, &"S4") == Vector3(37, 0, 45), "S4 slots")
	_check(main.tower_slot(P, &"nope") == Vector3.INF, "unknown tower slot")
	for team in [P, E]:
		Economy.for_team(team).crystals = 5000
	var hall := BuildingType.find("fire_barracks")
	var tower := BuildingType.find("fire_tower")
	for row in [[hall, main.market_slot(P), P], [tower, main.tower_slot(P, &"S3"), P], [tower, main.tower_slot(P, &"S4"), P]]:
		var at: Vector3 = main.build_grid.snap(row[1], (row[0] as BuildingType).footprint)
		var reason: String = main.build_grid.check(row[0], at, row[2])
		_check(reason == "" or reason == BuildGrid.MSG_UNEXPLORED, "slot %s is buildable (got '%s')" % [row[1], reason])


func _open_checks(net: TradeNetwork) -> void:
	main.set("_match_time", 200.0)   # taverns open first (their message)
	await _frames(20)
	main.set("_match_time", 239.8)
	await _frames(30)
	_check(_opened == 1, "posts_opened once at 4:00 (%d)" % _opened)
	for p in net.posts():
		_check(p.is_open(), "%s open after 4:00" % p.post_id)
	var msg: String = (main.hud.get("_message") as Label).text
	_check(msg.contains("The trading posts open their gates") and msg.contains("Build a Bazaar (B then B with a worker) to send caravans"),
			"open message + hint (got '%s')" % msg)
	await _frames(30)
	_check(_opened == 1, "posts opened only once")
	for h in root.get_tree().get_nodes_in_group("guilds"):
		_check(not h.is_open(), "guild houses still closed at 4:00")
	main.set("_match_time", 299.9)
	await _frames(20)
	for h in root.get_tree().get_nodes_in_group("guilds"):
		_check(h.is_open(), "guild house open at 5:00")


func _held_checks(net: TradeNetwork) -> void:
	var heron: TradePost = net.post_by_id(&"heron_ford")
	var door := heron.door_point()
	var mp: StubMarket = null
	for c in main.get_children():
		if c is StubMarket and c.team == P and c.has_meta(&"keep"):
			mp = c
	net.refresh()
	_check(net.route_reason(mp, heron) == "", "route open to Heron Ford after 4:00 (got '%s')" % net.route_reason(mp, heron))
	var foes: Array = []
	for off in [Vector3(2, 0, 3), Vector3(2, 0, -3)]:
		var u: Unit = main.make_unit("flame_guard")
		u.team = E
		main.add_child(u)
		u.global_position = door + off
		u.command_hold()
		foes.append(u)
	net.refresh()
	_check(heron.holder_team() == E and heron.is_held_by_enemy_of(P) and not heron.is_held_by_enemy_of(E),
			"2 enemy soldiers within 12 m: held by the enemy (holder %d)" % heron.holder_team())
	_check(_held_events.size() >= 1 and _held_events[-1][0] == heron and _held_events[-1][1] == E, "post_held_changed(heron, ENEMY)")
	_check(net.route_reason(mp, heron) == TradeNetwork.MSG_HELD, "route_reason Held by the enemy (got '%s')" % net.route_reason(mp, heron))
	var s := net.strength_near(E, door, 12.0)
	_check(s >= 100.0, "strength_near counts the 2 soldiers (%.0f)" % s)
	_check(net.strength_near(P, door, 12.0) == 0.0, "no player strength at the door")
	_check(not net.spot_valid(E, door) and net.spot_valid(P, door), "spot_valid: 18 m rule")
	var near_keep: Vector3 = main.base_center(E) + Vector3(15.6, 0, 15.6)   # 22 m from the enemy keep, no fighter within 18 m
	_check(not net.spot_valid(E, near_keep), "spot_valid: 25 m keep rule")
	var guard: Unit = main.make_unit("flame_guard")
	guard.team = P
	main.add_child(guard)
	guard.global_position = door + Vector3(-1, 0, 6)
	guard.command_hold()
	net.refresh()
	_check(heron.holder_team() == -1 and not heron.is_held_by_enemy_of(P), "contested: not held (holder %d)" % heron.holder_team())
	for u in foes + [guard]:
		u.remove_from_group("units")
		u.queue_free()
	await _frames(2)
	net.refresh()
	_check(heron.holder_team() == -1, "free again")


func _ledger_checks(net: TradeNetwork) -> void:
	var heron := net.post_by_id(&"heron_ford")
	var wharf := net.post_by_id(&"lantern_wharf")
	main.set("_match_time", 400.0)
	net.record_delivery(P, 100, heron, null)
	main.set("_match_time", 550.0)
	net.record_delivery(P, 20, heron, null)
	net.record_delivery(E, 7, wharf, null)
	main.set("_match_time", 575.0)
	_check(net.trade_income(P) == 120 and net.trade_income(E) == 7, "trade_income at 575 s = 120 (%d)" % net.trade_income(P))
	main.set("_match_time", 581.0)
	_check(net.trade_income(P) == 20, "trade_income sums the last 180 s only (%d)" % net.trade_income(P))
	_check(net.trade_income(P, 600.0) == 120, "trade_income(600 s)")
	_check(net.trips(P, heron) == 1 and net.trips(P, heron, 600.0) == 2 and net.trips(P, wharf) == 0, "trips per post and window")
	_check(net.route_income(P, heron) == 20 and net.route_income(E, wharf) == 7, "route_income")
	_check(net.traded_total(P) == 120 and _delivered == 3, "traded_total / delivered signal")


func _sack_checks(net: TradeNetwork) -> void:
	var bank: Node = null
	for b in root.get_tree().get_nodes_in_group("gold_banks"):
		if int(b.get(&"team")) == P:
			bank = b
	var gold0 := int(bank.get(&"gold")) if bank else 0
	var at := Vector3(-26, 0, 30)
	var sack := LootSack.spawn(main, at, 60)
	sack.picked.connect(func(s: LootSack, team: int, amount: int) -> void: _picked.append([s, team, amount]))
	var u: Unit = main.make_unit("flame_guard")
	u.team = P
	main.add_child(u)
	u.global_position = at + Vector3(2.1, 0, 0)
	u.command_hold()
	await _frames(40)
	_check(sack.is_available() and sack.amount == 60 and int(bank.get(&"gold")) == gold0,
			"not picked up at 2.1 m (unit at %.2f m)" % _flat(u.global_position, at))
	u.global_position = at + Vector3(1.9, 0, 0)
	u.command_hold()
	await _frames(40)
	_check(not is_instance_valid(sack) or not sack.is_available(), "picked up at 1.9 m")
	_check(int(bank.get(&"gold")) == gold0 + 60, "the sack adds 60 gold to the team (%d -> %d)" % [gold0, int(bank.get(&"gold"))])
	_check(_picked.size() == 1 and _picked[0][1] == P and _picked[0][2] == 60, "picked(sack, PLAYER, 60)")
	_check(net.loot_total(P) == 60, "network loot_total")
	u.remove_from_group("units")
	u.queue_free()
	# A Magpie takes at most 60 into its loot; the rest stays in the sack.
	var at2 := Vector3(-20, 0, -45)
	var sack2 := LootSack.spawn(main, at2, 80)
	var m: Unit = main.make_unit("flame_guard")
	m.team = N
	m.add_to_group("magpies")
	main.add_child(m)
	m.global_position = at2 + Vector3(0.5, 0, 0)
	m.command_hold()
	await _frames(30)
	_check(int(m.get_meta(&"loot", 0)) == 60 and is_instance_valid(sack2) and sack2.amount == 20 and sack2.is_available(),
			"a Magpie carries 60, 20 stay (loot %d, sack %d)" % [int(m.get_meta(&"loot", 0)), sack2.amount if is_instance_valid(sack2) else -1])
	_check(sack2.take(m) == 0, "a full Magpie takes nothing")
	# A neutral non-Magpie never takes it.
	m.remove_from_group("magpies")
	m.set_meta(&"loot", 0)
	await _frames(20)
	_check(is_instance_valid(sack2) and sack2.amount == 20, "a neutral non-Magpie leaves the sack")
	m.remove_from_group("units")
	m.queue_free()
	sack2.expire()


func _loss_checks(net: TradeNetwork) -> void:
	var caravan: Unit = main.make_unit("flame_guard")
	caravan.team = P
	caravan.add_to_group("caravans")
	main.add_child(caravan)
	caravan.global_position = Vector3(-30, 0, 20)
	caravan.take_damage(99999.0, null)
	_check(net.caravans_lost(P) == 1 and net.caravans_lost(E) == 0, "caravans_lost (%d)" % net.caravans_lost(P))
	var magpie: Unit = main.make_unit("flame_guard")
	magpie.team = N
	magpie.add_to_group("magpies")
	main.add_child(magpie)
	magpie.global_position = Vector3(-28, 0, 26)
	var worker: Unit = Worker.make_unit(UnitType.find("cinder_hand"))
	worker.team = P
	main.add_child(worker)
	worker.global_position = Vector3(-28, 0, 24)
	worker.take_damage(99999.0, magpie)
	_check(net.workers_lost_to_magpies(P) == 1, "workers_lost_to_magpies (%d)" % net.workers_lost_to_magpies(P))
	var killer: Unit = main.make_unit("flame_guard")
	killer.team = P
	main.add_child(killer)
	killer.global_position = Vector3(-27, 0, 27)
	magpie.take_damage(99999.0, killer)
	_check(net.magpies_slain(P) == 1 and net.magpies_slain(E) == 0, "magpies_slain credits the killer's team")
	var line: String = main.end_screen_text()
	_check(line.contains("Gold earned ") and line.contains("Caravans lost 1") and line.contains("Workers lost to Magpies 1")
			and line.contains("Magpies slain 1") and line.ends_with("F9: play again"), "end-screen line (got '%s')" % line)
	var st: Dictionary = main.stats_of(P)
	_check(st.has("gold_earned") and st.has("gold_trade") and int(st["caravans_lost"]) == 1, "stats_of has the trade stats")
	killer.remove_from_group("units")
	killer.queue_free()


func _ground_checks() -> void:
	var plain := ShaderMaterial.new()
	plain.shader = Shader.new()
	plain.shader.code = "shader_type spatial;\nvoid fragment() { ALBEDO = vec3(1.0); }\n"
	_check(not EnvProps.set_roads(plain, main.road_param()), "set_roads is a no-op without road uniforms")
	_check(main.road_param().size() == 10, "road_param has the 10 segments")
	var roads := ShaderMaterial.new()
	roads.shader = Shader.new()
	roads.shader.code = "shader_type spatial;\nuniform vec4 road_segs[16];\nuniform int road_count = 0;\nuniform float road_width = 1.0;\nvoid fragment() { ALBEDO = vec3(road_segs[0].x * 0.0 + float(road_count) * 0.0 + road_width * 0.0); }\n"
	_check(EnvProps.set_roads(roads, main.road_param()), "set_roads with road uniforms")
	_check(int(roads.get_shader_parameter(&"road_count")) == 10 and is_equal_approx(float(roads.get_shader_parameter(&"road_width")), 3.0),
			"road_count 10, width 3")
	var segs: Variant = roads.get_shader_parameter(&"road_segs")
	_check(segs is PackedVector4Array and (segs as PackedVector4Array).size() == 16
			and (segs as PackedVector4Array)[0] == Vector4(-36, 36, -49, 1), "road_segs padded to 16 (%s)" % [segs])
	var ground_has := false
	for c in main.nav_region.get_children():
		if c is StaticBody3D and c.get_script() == null:
			for m in c.get_children():
				if m is MeshInstance3D and m.material_override is ShaderMaterial:
					var mat := m.material_override as ShaderMaterial
					for u: Dictionary in mat.shader.get_shader_uniform_list():
						if String(u["name"]) == "road_segs":
							ground_has = true
							_check(int(mat.get_shader_parameter(&"road_count")) == 10, "the ground paints 10 roads")
			break
	if not ground_has:
		_notes.append("ground shader has no road uniforms yet (10.V10): roads not painted")
