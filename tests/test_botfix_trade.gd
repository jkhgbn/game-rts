extends SceneTree
## Bot fixes 2026-10-12 (docs/handoff/bot-review-2026-10-12.md, D1 / D3 / D4), regression checks:
## - D4: a fleeing Magpie band goes to the guild's nearest_den_door (navmesh), not the straight-line nearest Den.
## - D3: a flee that can't reach its door ends after ~90 s: every thief leaves the map (no `died`, loot 0).
## - D3: a calm-flee sack run that can't reach its sack is dropped after ~10 s; the thief walks home.
## - D1 (scenes/skirmish.tscn): the default route "Held by the enemy" counts as unsafe -> the other free near post;
##   back to the default by itself when it is free again.
## Parts 1-3 run in a small flat world (stand-in guild / network / sacks, like test_10_a1).
## Run:  godot --headless --path . -s tests/test_botfix_trade.gd --fixed-fps 60 --quit-after 40000

const TASK_ID := "botfix_trade"
const P := 0
const E := 1
const N := 2
const DOOR_NEAR := Vector3(0.0, 0.0, -40.0)
const DOOR_FAR := Vector3(0.0, 0.0, 140.0)
const SACK_PATH := "user://test_botfix_trade_sack.gd"

const DEN_SRC := "extends Node3D\nvar door := Vector3.ZERO\nfunc door_point() -> Vector3:\n\treturn door\n"
const GUILD_SRC := "extends Node\nvar den_nodes: Array = []\nvar pref := Vector3.INF\n" \
		+ "func dens() -> Array:\n\treturn den_nodes\n" \
		+ "func nearest_den_door(_pos: Vector3) -> Vector3:\n\treturn pref\n"
const NET_SRC := "extends Node\nvar spots: Array = []\n" \
		+ "func ambush_spots(_team: int, _post: Node) -> Array:\n\treturn spots\n" \
		+ "func worker_spot(node: Node3D) -> Vector3:\n\treturn node.global_position\n"
const SACK_SRC := "extends Node3D\nvar amount := 0\nfunc _ready() -> void:\n\tadd_to_group(&\"loot_sacks\")\n" \
		+ "static func spawn(parent: Node, pos: Vector3, gold: int) -> Node3D:\n" \
		+ "\tvar s = load(\"" + SACK_PATH + "\").new()\n\ts.amount = gold\n\tparent.add_child(s)\n" \
		+ "\ts.global_position = pos\n\treturn s\n" \
		+ "func take(_by: Node3D) -> int:\n\tvar a := amount\n\tamount = 0\n\tqueue_free()\n\treturn a\n"

var world: Node3D
var net: Node
var sack_script: Script
var magpie_type: UnitType
var errors: Array[String] = []
var finished := false
var spawned: Array = []
var died_thieves: Array = []
var stages := 0


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	var f := FileAccess.open(SACK_PATH, FileAccess.WRITE)
	f.store_string(SACK_SRC)
	f.close()
	sack_script = load(SACK_PATH) as Script
	net = Node.new()
	net.set_script(_script(NET_SRC))
	net.add_to_group(&"trade_network")
	world.add_child(net)
	magpie_type = UnitType.new()
	magpie_type.id = &"magpie"
	magpie_type.display_name = "Magpie"
	magpie_type.faction = &"neutral"
	magpie_type.max_hp = 140.0
	magpie_type.attack_damage = 9.0
	magpie_type.attack_range = 1.5
	magpie_type.attack_cooldown = 1.0
	magpie_type.move_speed = 5.2
	magpie_type.aggro_range = 0.0
	magpie_type.radius = 0.4
	magpie_type.body_height = 1.6
	magpie_type.set(&"neutral_leash", false)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	await _test_d4_navmesh_door()
	await _clear()
	await _test_d3_flee_cap()
	await _clear()
	await _test_d3_sack_cap()
	await _clear()
	world.queue_free()
	await _wait(3)
	await _test_d1_held_route()
	_eq(stages, 4, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- D4

func _test_d4_navmesh_door() -> void:
	var guild := _guild([DOOR_NEAR, DOOR_FAR], DOOR_FAR)
	var at := Vector3(-40.0, 0.0, 10.0)
	var band := _band(guild, [_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))], at)
	var mags: Array = band.thieves.duplicate()
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "D4: band reaches lurking")
	(mags[0] as Unit).take_damage(100000.0, null)
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 120), "D4: half the band dead -> flee")
	var m := mags[1] as Unit
	var d0 := _flat(m.global_position, DOOR_FAR)
	var n0 := _flat(m.global_position, DOOR_NEAR)
	await _seconds(4.0)
	_check(_flat(m.global_position, DOOR_FAR) < d0 - 10.0,
			"D4: the band walks to the guild's nearest_den_door (far door %.1f -> %.1f m, near door %.1f -> %.1f m)" % [
			d0, _flat(m.global_position, DOOR_FAR), n0, _flat(m.global_position, DOOR_NEAR)])
	stages += 1


# ---------------------------------------------------------------- D3

# The only Den door lies off the ground (unreachable): the band gives up after 90 s and every thief leaves.
func _test_d3_flee_cap() -> void:
	var door := Vector3(0.0, 0.0, 300.0)
	var guild := _guild([door], Vector3.INF)   # INF: the band falls back to the straight-line nearest door
	var at := Vector3(0.0, 0.0, 150.0)
	var band := _band(guild, [_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))], at)
	var mags: Array = band.thieves.duplicate()
	var fin := [false]
	band.finished.connect(func(_b: Node) -> void: fin[0] = true)
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "D3: band reaches lurking")
	var m := mags[1] as Unit
	m.set_meta(&"loot", 40)
	(mags[0] as Unit).take_damage(100000.0, null)
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 120), "D3: half the band dead -> flee")
	died_thieves.clear()
	var t0 := _now()
	await _seconds(80.0)
	_check(not fin[0] and band.state == &"fleeing", "D3: still fleeing at 80 s (state %s)" % band.state)
	_check(await _wait_until(func() -> bool: return fin[0], 15 * 60), "D3: the band ends within ~95 s of a blocked flee")
	var took := _now() - t0
	_check(took >= 89.0 and took <= 92.0, "D3: flee capped at ~90 s (took %.1f s)" % took)
	_check(not is_instance_valid(m) or not m.is_alive(), "D3: the stuck thief left the map")
	_check(died_thieves.is_empty(), "D3: leaving the map is not a death")
	if is_instance_valid(m):
		_eq(int(m.get_meta(&"loot", -1)), 0, "D3: the loot is fenced (0)")
	stages += 1


# Calm flee (no spot, 3 retries) with a sack lying off the ground edge: the run is dropped after ~10 s.
func _test_d3_sack_cap() -> void:
	var door := Vector3(-150.0, 0.0, 180.0)
	var guild := _guild([door], door)
	var at := Vector3(0.0, 0.0, 192.0)
	var band := _band(guild, [_magpie(at)], Vector3.INF)
	var m := band.thieves[0] as Unit
	var fin := [false]
	band.finished.connect(func(_b: Node) -> void: fin[0] = true)
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 70 * 60), "D3 sack: no spot -> calm flee")
	var sack: Node3D = sack_script.call(&"spawn", world, Vector3(m.global_position.x, 0.0, 206.0), 30)
	spawned.append(sack)
	await _seconds(3.0)
	_check(_flat(m.global_position, sack.global_position) < 10.0, "D3 sack: the thief runs for the sack first")
	_check(await _wait_until(func() -> bool: return _flat(m.global_position, sack.global_position) > 12.0, 20 * 60),
			"D3 sack: the thief gives the unreachable sack up and walks home")
	_check(is_instance_valid(sack) and int(sack.get(&"amount")) == 30, "D3 sack: the sack is still there")
	_check(await _wait_until(func() -> bool: return fin[0], 60 * 60), "D3 sack: the band gets home")
	stages += 1


# ---------------------------------------------------------------- D1

func _test_d1_held_route() -> void:
	var main: Node = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var ok := await _wait_until(func() -> bool: return bool(main.get(&"match_started")), 6000)
	_check(ok, "D1: skirmish ready")
	if not ok:
		return
	for c in main.get_children():   # the bots stay out of it: only this test's AITrade picks routes
		if c.get_script() == preload("res://scripts/ai/commander.gd"):
			c.process_mode = Node.PROCESS_MODE_DISABLED
	var net2 := TradeNetwork.instance(self)
	_check(net2 != null, "D1: a TradeNetwork")
	if net2 == null:
		return
	net2.match_time_source = func() -> float: return 300.0
	var keep: Node3D = null
	for b in get_nodes_in_group(&"buildings"):
		if b is Keep and int((b as Keep).team) == E:
			keep = b as Node3D
	var m := Market.new()
	m.building_type = BuildingType.find("shadow_market")
	m.team = E as Unit.Team
	main.add_child(m)
	m.global_position = keep.global_position + (Vector3.ZERO - keep.global_position).normalized() * 14.0
	await _wait(3)
	_check(Market.of_team(E) == m, "D1: the test Bazaar is the team's Bazaar")
	var def := m.default_route()
	var other: Node3D = null
	for p in net2.posts():
		if p != def and not m.is_far_post(p) and net2.route_reason(m, p) == "":
			other = p
	_check(def != null and other != null, "D1: a default and another free near post")
	if def == null or other == null:
		return
	m.set_route(def)
	var foe := Unit.new()
	foe.apply_type(load("res://data/units/flame_guard.tres") as UnitType)
	foe.team = P as Unit.Team
	main.add_child(foe)
	foe.global_position = (def as TradePost).door_point()
	foe.aggro_range = 0.0
	foe.command_stop()
	await _wait(2)
	net2.refresh()
	_eq(net2.route_reason(m, def), TradeNetwork.MSG_HELD, "D1: one enemy at the door holds the default post")
	var a := AITrade.new(E, P, AIProfile.normal())
	_check(a.active(), "D1: AITrade active")
	var mem := AIMemory.new()
	var cu: Array[Unit] = []
	var bu: Array[Building] = []
	a.sense(300.0, null, 1000.0, 0.0, cu, bu)
	a.tick(300.0, mem, 1000.0, 0.0, cu)
	_check(m.route_post == other, "D1: a held default -> the other near post (route %s)" % AITrade.post_name(m.route_post))
	foe.queue_free()
	await _wait(2)
	net2.refresh()
	_eq(net2.route_reason(m, def), "", "D1: the default is free again")
	a.sense(331.0, null, 1000.0, 0.0, cu, bu)
	a.tick(331.0, mem, 1000.0, 0.0, cu)
	_check(m.route_post == def, "D1: back on the default once it is free (route %s)" % AITrade.post_name(m.route_post))
	stages += 1


# ---------------------------------------------------------------- helpers

func _guild(doors: Array, pref: Vector3) -> Node:
	var g := Node.new()
	g.set_script(_script(GUILD_SRC))
	world.add_child(g)
	g.set(&"pref", pref)
	spawned.append(g)
	for door: Vector3 in doors:
		var den := Node3D.new()
		den.set_script(_script(DEN_SRC))
		den.set(&"door", door)
		world.add_child(den)
		den.global_position = door
		(g.get(&"den_nodes") as Array).append(den)
		spawned.append(den)
	return g


func _band(guild: Node, thieves: Array, at: Vector3) -> ThiefBand:
	var b := ThiefBand.new()
	b.loot_sack_script = sack_script
	var t := {"kind": &"road", "team": P, "post": net}
	if at.is_finite():
		t["spot"] = at
	b.setup(guild, thieves, t)
	world.add_child(b)
	spawned.append(b)
	return b


func _magpie(pos: Vector3) -> Unit:
	var u := Unit.new()
	u.apply_type(magpie_type)
	u.team = N as Unit.Team
	u.add_to_group(&"magpies")
	u.set_meta(&"loot", 0)
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	u.died.connect(func(x: Unit) -> void: died_thieves.append(x))
	spawned.append(u)
	return u


func _now() -> float:
	return float(Engine.get_physics_frames()) / 60.0


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _seconds(s: float) -> void:
	await _wait(int(round(s * 60.0)))


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await physics_frame
	return bool(cond.call())


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			(n as Node).queue_free()
	spawned.clear()
	for s in world.get_tree().get_nodes_in_group(&"loot_sacks"):
		s.queue_free()
	died_thieves.clear()
	await _wait(3)


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _check(cond: bool, msg: String) -> void:
	if not cond:
		errors.append(msg)
		print("  x %s" % msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	_check(got == want, "%s (got %s, want %s)" % [msg, str(got), str(want)])
