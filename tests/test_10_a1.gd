extends SceneTree
## Task 10.A1: the ThiefBand brain (market-trade.md 5.3). A small flat world (no main scene); ThievesGuild,
## TradeNetwork, Caravan and LootSack are stand-ins written in this file, so the test only depends on the band:
## - static rules: spot validity (18 m units, 20 m towers, 25 m keep), escort strength (soldiers, trackers 150,
##   towers / keep covering the point 150 / 250, workers and caravans 0);
## - spot choice (first valid spot of the route), lurk 90 s, the one move to the next spot, 90 s, home;
## - no strike on an escort above 70 x size, strike at or below it;
## - snatch 1.5 s, max 60 each (119 -> 60 + 59), broken by 20 damage; a lone caravan dies within 15 s;
## - worker strike: carrying worker first, stops at 2 kills (loot = carried crystals) or at 15 s; never a
##   home-node worker; flee with shroud 2 s to the nearer Den; leave_map at the door (no `died`);
## - a sack within 15 m is taken, one at 20 m is not; a dead Magpie drops its loot as a sack;
## - fights back against a weaker attacker, flees from a stronger one; half the band dead -> flee;
## - perf: 3 bands next to 200 units and 12 caravans cost < 0.05 ms per frame on average.
## Run:  godot --headless --path . -s tests/test_10_a1.gd --fixed-fps 60 --quit-after 40000

const TASK_ID := "10.A1"
const P := 0
const E := 1
const N := 2
const DOOR_NEAR := Vector3(0.0, 0.0, -40.0)
const DOOR_FAR := Vector3(0.0, 0.0, 140.0)
const KEEP_POS := Vector3(-80.0, 0.0, 80.0)
const SACK_PATH := "user://test_10_a1_sack.gd"

const DEN_SRC := "extends Node3D\nvar door := Vector3.ZERO\nfunc door_point() -> Vector3:\n\treturn door\n"
const GUILD_SRC := "extends Node\nvar den_nodes: Array = []\nfunc dens() -> Array:\n\treturn den_nodes\n"
const NET_SRC := "extends Node\nsignal workers_raided(team: int, node: Node)\nvar spots: Array = []\nvar raids: Array = []\n" \
		+ "func ambush_spots(_team: int, _post: Node) -> Array:\n\treturn spots\n" \
		+ "func worker_spot(node: Node3D) -> Vector3:\n\treturn node.global_position + Vector3(12.0, 0.0, 0.0)\n" \
		+ "func record_workers_raided(team: int, node: Node) -> void:\n\traids.append([team, node])\n"
const BUILDING_SRC := "extends Node3D\nvar team := 0\nvar building_type: BuildingType\n" \
		+ "func is_alive() -> bool:\n\treturn true\nfunc is_constructed() -> bool:\n\treturn true\n" \
		+ "func target_radius() -> float:\n\treturn 3.0\n"
const CARAVAN_SRC := "extends Unit\nsignal robbed(caravan: Node, amount: int, thief: Node3D)\nvar cargo := 0\n" \
		+ "func _ready() -> void:\n\tsuper()\n\tadd_to_group(&\"caravans\")\n" \
		+ "func is_loaded() -> bool:\n\treturn cargo > 0\n" \
		+ "func steal(amount: int, thief: Node3D) -> int:\n\tvar got := mini(amount, cargo)\n\tcargo -= got\n" \
		+ "\trobbed.emit(self, got, thief)\n\treturn got\n"
const SACK_SRC := "extends Node3D\nvar amount := 0\nfunc _ready() -> void:\n\tadd_to_group(&\"loot_sacks\")\n" \
		+ "static func spawn(parent: Node, pos: Vector3, gold: int) -> Node3D:\n" \
		+ "\tvar s = load(\"" + SACK_PATH + "\").new()\n\ts.amount = gold\n\tparent.add_child(s)\n" \
		+ "\ts.global_position = pos\n\treturn s\n" \
		+ "func take(_by: Node3D) -> int:\n\tvar a := amount\n\tamount = 0\n\tqueue_free()\n\treturn a\n"

var world: Node3D
var guild: Node
var net: Node
var sack_script: Script
var caravan_script: GDScript
var building_script: GDScript
var magpie_type: UnitType
var caravan_type: UnitType
var keep_stub: Node3D
var errors: Array[String] = []
var finished := false
var spawned: Array = []
var stages := 0
var events: Array = []       # [time, name, args]
var died_thieves: Array = []


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
	# Stand-ins
	var f := FileAccess.open(SACK_PATH, FileAccess.WRITE)
	f.store_string(SACK_SRC)
	f.close()
	sack_script = load(SACK_PATH) as Script
	caravan_script = _script(CARAVAN_SRC)
	building_script = _script(BUILDING_SRC)
	guild = Node.new()
	guild.set_script(_script(GUILD_SRC))
	world.add_child(guild)
	for door in [DOOR_NEAR, DOOR_FAR]:
		var den := Node3D.new()
		den.set_script(_script(DEN_SRC))
		den.set(&"door", door)
		den.position = door   # the world sits at the origin (not in the tree yet during _initialize)
		world.add_child(den)
		(guild.get(&"den_nodes") as Array).append(den)
	net = Node.new()
	net.set_script(_script(NET_SRC))
	net.add_to_group(&"trade_network")
	world.add_child(net)
	keep_stub = _building(&"fire_keep", P, KEEP_POS)
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
	magpie_type.kill_xp = 25
	magpie_type.set(&"neutral_leash", false)
	caravan_type = UnitType.new()
	caravan_type.id = &"caravan"
	caravan_type.display_name = "Caravan"
	caravan_type.max_hp = 220.0
	caravan_type.armor = 10.0
	caravan_type.attack_damage = 0.0
	caravan_type.aggro_range = 0.0
	caravan_type.move_speed = 4.0
	caravan_type.radius = 0.8
	caravan_type.body_height = 1.9
	caravan_type.set(&"is_caravan", true)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	await _test_static_rules()
	await _clear()
	await _test_escort_and_caravan_strike()
	await _clear()
	await _test_snatch_break_and_sack_drop()
	await _clear()
	await _test_fight_or_flee()
	await _clear()
	await _test_worker_strike()
	await _clear()
	await _test_worker_time_cap()
	await _clear()
	await _test_home_workers()
	await _clear()
	await _test_sacks()
	await _clear()
	await _test_lurk_cycle()
	await _clear()
	await _test_perf()
	await _clear()
	_eq(stages, 10, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- stages

func _test_static_rules() -> void:
	var tree := world.get_tree()
	var at := Vector3(40.0, 0.0, -60.0)
	_check(ThiefBand.spot_is_valid(tree, P, at), "empty spot is valid")
	var s := _soldier(&"shade", P, at + Vector3(17.0, 0.0, 0.0), true)
	await _wait(2)
	_check(not ThiefBand.spot_is_valid(tree, P, at), "a soldier at 17 m makes the spot invalid")
	s.global_position = at + Vector3(19.0, 0.0, 0.0)
	_check(ThiefBand.spot_is_valid(tree, P, at), "a soldier at 19 m does not")
	s.global_position = at + Vector3(5.0, 0.0, 0.0)
	_check(ThiefBand.spot_is_valid(tree, E, at), "the other team's soldiers don't matter")
	s.global_position = at + Vector3(19.0, 0.0, 0.0)
	var w := _worker(P, at + Vector3(3.0, 0.0, 0.0), 0)
	var cv := _caravan(P, at + Vector3(-3.0, 0.0, 0.0), 50)
	await _wait(2)
	_check(ThiefBand.spot_is_valid(tree, P, at), "workers and caravans never block a spot")
	var tower := _building(&"fire_tower", P, at + Vector3(0.0, 0.0, 19.5))
	_check(not ThiefBand.spot_is_valid(tree, P, at), "a tower at 19.5 m makes the spot invalid")
	tower.global_position = at + Vector3(0.0, 0.0, 20.5)
	_check(ThiefBand.spot_is_valid(tree, P, at), "a tower at 20.5 m does not")
	_check(not ThiefBand.spot_is_valid(tree, P, KEEP_POS + Vector3(24.0, 0.0, 0.0)), "keep at 24 m: invalid")
	_check(ThiefBand.spot_is_valid(tree, P, KEEP_POS + Vector3(26.0, 0.0, 0.0)), "keep at 26 m: valid")
	# Escort strength (5.3)
	var shade_str := AIMemory.strength_of(s)
	_near(ThiefBand.unit_strength(s), 80.0, "a Shade counts its cost (80)")
	_near(ThiefBand.unit_strength(w), 0.0, "a worker counts 0")
	_near(ThiefBand.unit_strength(cv), 0.0, "a caravan counts 0")
	var victim_at := at + Vector3(0.0, 0.0, 40.0)
	_near(ThiefBand.escort_strength(tree, P, victim_at), 0.0, "no escort far from everything")
	s.global_position = victim_at + Vector3(6.0, 0.0, 0.0)
	var s2 := _soldier(&"shade", P, victim_at + Vector3(0.0, 0.0, 9.0), true)
	_soldier(&"shade", P, victim_at + Vector3(0.0, 0.0, 11.0), true)   # outside 10 m
	var tr := _soldier(&"shade", P, victim_at + Vector3(-5.0, 0.0, 0.0), true)
	tr.add_to_group(&"trackers")
	await _wait(2)
	_near(ThiefBand.unit_strength(tr), 150.0, "a tracker counts 150")
	_near(ThiefBand.escort_strength(tree, P, victim_at), shade_str * 2.0 + 150.0, "escort = 2 Shades + tracker")
	var cover := _building(&"fire_tower", P, victim_at + Vector3(0.0, 0.0, -8.0))
	_near(ThiefBand.escort_strength(tree, P, victim_at), shade_str * 2.0 + 300.0, "a tower covering it adds 150")
	cover.global_position = victim_at + Vector3(0.0, 0.0, -14.0)
	_near(ThiefBand.escort_strength(tree, P, victim_at), shade_str * 2.0 + 150.0, "a tower out of range adds 0")
	_near(ThiefBand.escort_strength(tree, P, KEEP_POS + Vector3(12.0, 0.0, 0.0)), 250.0, "the keep covering it adds 250")
	var mg := _magpie(at + Vector3(0.0, 0.0, -10.0))
	await _wait(1)
	_near(ThiefBand.unit_strength(mg), 80.0, "a Magpie counts 80")
	s2.queue_free()
	stages += 1


# A band of 2 lurks; a loaded caravan with 2 Shades beside it (160 > 140) is left alone; with 1 Shade (80) it is
# struck: snatch 60 then 59 (1.5 s each), the lone caravan dies within 15 s of the first hit, the band flees in
# smoke to the nearer Den and leaves the map there (loot fenced, no sack, no `died`).
func _test_escort_and_caravan_strike() -> void:
	var at := Vector3(0.0, 0.0, 10.0)
	var band := _band([_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"road", "team": P, "post": net, "spot": at})
	var mags: Array = band.thieves.duplicate()
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "band reaches lurking")
	var cv := _caravan(P, at + Vector3(8.0, 0.0, 0.0), 119)
	var g1 := _soldier(&"shade", P, at + Vector3(9.0, 0.0, 2.0), true)
	var g2 := _soldier(&"shade", P, at + Vector3(9.0, 0.0, -2.0), true)
	var first_hit := [-1.0]
	cv.damage_taken.connect(func(_a: float, _b: Node3D) -> void:
		if first_hit[0] < 0.0:
			first_hit[0] = _now())
	await _seconds(3.0)
	_eq(band.state, &"lurking", "no strike on an escort of 160 > 70 x 2")
	_eq(int(cv.get(&"cargo")), 119, "cargo untouched while escorted")
	g2.queue_free()
	_check(await _wait_until(func() -> bool: return band.state == &"striking", 90), "strike with an escort of 80 <= 140")
	_check(_event_count(&"strike_started") == 1, "strike_started emitted once")
	_check(await _wait_until(func() -> bool: return int(cv.get(&"cargo")) == 0, 600), "the cargo is snatched")
	var snatches := _events(&"snatched")
	var starts := _events(&"snatch_started")
	_eq(snatches.size(), 2, "two snatches for 119 gold")
	if snatches.size() == 2 and starts.size() >= 2:
		_eq(int(snatches[0][2][2]), 60, "first snatch takes 60")
		_eq(int(snatches[1][2][2]), 59, "second snatch takes 59")
		_near(float(snatches[0][0]) - float(starts[0][0]), 1.5, "snatch channel lasts 1.5 s", 0.05)
		_near(float(snatches[1][0]) - float(starts[1][0]), 1.5, "second channel lasts 1.5 s", 0.05)
		_check(snatches[0][2][0] != snatches[1][2][0], "a second Magpie makes the second snatch")
	_eq(band.loot_total(), 119, "the band carries 119")
	for m in mags:
		_check(int((m as Node).get_meta(&"loot", 0)) <= 60, "max 60 loot per Magpie")
	_check(await _wait_until(func() -> bool: return not cv.is_alive(), 1200), "the robbed caravan is finished off")
	var kill_time := _now() - float(first_hit[0])
	_check(first_hit[0] >= 0.0 and kill_time <= 15.0, "a lone caravan dies within 15 s of the first hit (%.1f s)" % kill_time)
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 60), "the band flees after the strike")
	for m in mags:
		if is_instance_valid(m):
			_check((m as Unit).has_status(&"shroud"), "fleeing Magpies get shroud")
			_near((m as Unit).status_time_left(&"shroud"), 2.0, "shroud lasts 2 s", 0.6)
	var fin := [false]
	band.finished.connect(func(_b: Node) -> void: fin[0] = true)
	var last_pos := {}
	for m in mags:
		(m as Node).tree_exiting.connect(func() -> void: last_pos[m] = (m as Node3D).global_position)
	_check(await _wait_until(func() -> bool: return fin[0], 1800), "the band finishes at the Den")
	await _seconds(1.5)   # leave_map fades for 1 s before freeing
	for m in mags:
		_check(last_pos.has(m) and _flat(last_pos[m], DOOR_NEAR) <= 4.0, "a Magpie leaves the map at the nearer Den door")
	_eq(died_thieves.size(), 0, "leaving the map is not dying")
	_eq(world.get_tree().get_nodes_in_group(&"loot_sacks").size(), 0, "fenced loot drops no sack")
	g1.queue_free()
	stages += 1


# Snatch broken by 20 damage (restarts later); a dying Magpie drops its loot; half the band dead -> flee.
func _test_snatch_break_and_sack_drop() -> void:
	var at := Vector3(30.0, 0.0, 10.0)
	var band := _band([_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"road", "team": P, "post": net, "spot": at})
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "band reaches lurking")
	var cv := _caravan(P, at + Vector3(6.0, 0.0, 0.0), 119)
	_check(await _wait_until(func() -> bool: return _event_count(&"snatch_started") >= 1, 600), "a snatch starts")
	var first_start := float(_events(&"snatch_started")[0][0])
	var snatcher: Unit = _events(&"snatch_started")[0][2][0]
	await _seconds(0.5)
	snatcher.take_damage(20.0, null)
	await _seconds(1.2)
	_eq(_event_count(&"snatched"), 0, "20 damage breaks the snatch")
	_check(await _wait_until(func() -> bool: return _event_count(&"snatched") >= 1, 600), "a new snatch succeeds")
	_check(_event_count(&"snatch_started") >= 2, "the snatch restarts")
	_check(float(_events(&"snatched")[0][0]) - first_start > 1.9, "the broken channel did not pay")
	var robber: Unit = _events(&"snatched")[0][2][0]
	var loot := int(robber.get_meta(&"loot", 0))
	_eq(loot, 60, "the robber carries 60")
	var pos := robber.global_position
	robber.take_damage(10000.0, null)
	await _wait(1)
	var sacks := world.get_tree().get_nodes_in_group(&"loot_sacks")
	_eq(sacks.size(), 1, "a dead Magpie drops a loot sack")
	if sacks.size() == 1:
		_eq(int(sacks[0].get(&"amount")), 60, "the sack holds its loot")
		_check(_flat((sacks[0] as Node3D).global_position, pos) < 0.5, "the sack lies where it died")
		(sacks[0] as Node).queue_free()
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 60), "half the band dead -> flee")
	cv.queue_free()
	stages += 1


# A weaker attacker (1 Shade, 80 <= 160) is fought; a stronger force (3 Shadow Knights) makes the band flee.
func _test_fight_or_flee() -> void:
	var at := Vector3(-40.0, 0.0, 10.0)
	var band := _band([_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"road", "team": P, "post": net, "spot": at})
	var mags: Array = band.thieves.duplicate()
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "band reaches lurking")
	var shade := _soldier(&"shade", P, at + Vector3(6.0, 0.0, 0.0), false)
	shade.aggro_range = 0.0
	shade.command_attack(mags[0])
	_check(await _wait_until(func() -> bool:
		return (mags[0] as Unit).attack_target == shade and (mags[1] as Unit).attack_target == shade, 240),
			"both Magpies fight back against a weaker attacker")
	_eq(band.state, &"lurking", "fighting a weaker attacker keeps the band at its spot")
	_check(await _wait_until(func() -> bool: return not shade.is_alive(), 1200), "the band kills the Shade")
	_eq(band.state, &"lurking", "still lurking after the fight")
	var knights: Array = []
	for i in 3:
		var k := _soldier(&"shadow_knight", P, at + Vector3(7.0, 0.0, -2.0 + 2.0 * i), false)
		k.aggro_range = 0.0
		k.command_attack(mags[i % 2])
		knights.append(k)
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 400), "a stronger force makes the band flee")
	for m in mags:
		if is_instance_valid(m) and (m as Unit).is_alive():
			_check((m as Unit).has_status(&"shroud"), "shroud on the fleeing Magpies")
	for k in knights:
		(k as Node).queue_free()
	stages += 1


# Workers at a remote node: the carrying one first, 2 kills, its 10 crystals become loot, then flee.
func _test_worker_strike() -> void:
	var node_pos := Vector3(40.0, 0.0, -20.0)
	var node := Node3D.new()
	world.add_child(node)
	node.global_position = node_pos
	spawned.append(node)
	var w1 := _worker(P, node_pos + Vector3(3.0, 0.0, 0.0), 0)
	var w2 := _worker(P, node_pos + Vector3(-3.0, 0.0, 0.0), 10)
	var w3 := _worker(P, node_pos + Vector3(0.0, 0.0, 4.0), 0)
	var spot := node_pos + Vector3(12.0, 0.0, 0.0)
	var band := _band([_magpie(spot + Vector3(0.0, 0.0, 1.0)), _magpie(spot + Vector3(0.0, 0.0, -1.0))],
			{"kind": &"workers", "team": P, "node": node, "spot": spot})
	_check(await _wait_until(func() -> bool: return band.state == &"striking", 600), "worker strike starts")
	var started := _events(&"strike_started")
	_check(started.size() == 1 and started[0][2][1] == w2, "the worker carrying crystals is struck first")
	_eq((net.get(&"raids") as Array).size(), 1, "TradeNetwork.record_workers_raided called once")
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 1200), "flee after the worker strike")
	_eq(band.worker_kills, 2, "stops at 2 worker kills")
	var alive := 0
	for w in [w1, w2, w3]:
		if is_instance_valid(w) and (w as Unit).is_alive():
			alive += 1
	_eq(alive, 1, "the third worker lives")
	_eq(band.loot_total(), 10, "the carried crystals become loot (as gold)")
	stages += 1


func _test_worker_time_cap() -> void:
	var node_pos := Vector3(-40.0, 0.0, -20.0)
	var node := Node3D.new()
	world.add_child(node)
	node.global_position = node_pos
	spawned.append(node)
	var tank := _worker(P, node_pos + Vector3(2.0, 0.0, 0.0), 0)
	tank.set_base_stat(&"max_hp", 5000.0)
	tank.heal(5000.0)
	var spot := node_pos + Vector3(12.0, 0.0, 0.0)
	var band := _band([_magpie(spot + Vector3(0.0, 0.0, 1.0)), _magpie(spot + Vector3(0.0, 0.0, -1.0))],
			{"kind": &"workers", "team": P, "node": node, "spot": spot})
	_check(await _wait_until(func() -> bool: return band.state == &"striking", 600), "worker strike starts")
	var t0 := _now()
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 1500), "the worker strike ends")
	_near(_now() - t0, 15.0, "a worker strike lasts at most 15 s", 0.6)
	_eq(band.worker_kills, 0, "no kill on a tanky worker")
	stages += 1


# Workers at a home node (within 30 m of their keep) are never struck, and neither is a worker standing within
# 30 m of its keep next to a remote node.
func _test_home_workers() -> void:
	var home := Node3D.new()
	world.add_child(home)
	home.global_position = KEEP_POS + Vector3(10.0, 0.0, 0.0)
	spawned.append(home)
	var hw1 := _worker(P, home.global_position + Vector3(0.0, 0.0, 3.0), 10)
	var hw2 := _worker(P, home.global_position + Vector3(0.0, 0.0, -3.0), 0)
	var spot_h := home.global_position + Vector3(0.0, 0.0, 12.0)
	var band_h := _band([_magpie(spot_h + Vector3(1.0, 0.0, 0.0)), _magpie(spot_h + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"workers", "team": P, "node": home, "spot": spot_h})
	_check(await _wait_until(func() -> bool: return band_h.state == &"lurking", 600), "home band lurks")
	await _seconds(4.0)
	_eq(band_h.state, &"lurking", "no strike at a home node")
	_check(hw1.hp == hw1.max_hp and hw2.hp == hw2.max_hp, "home workers untouched")
	for m in band_h.thieves.duplicate():
		(m as Node).queue_free()
	await _wait(3)
	var remote := Node3D.new()
	world.add_child(remote)
	remote.global_position = KEEP_POS + Vector3(40.0, 0.0, 0.0)
	spawned.append(remote)
	var near_keep := _worker(P, remote.global_position + Vector3(-12.0, 0.0, 0.0), 10)   # 28 m from the keep
	var far_one := _worker(P, remote.global_position + Vector3(10.0, 0.0, 0.0), 0)       # 50 m
	var spot_r := remote.global_position + Vector3(0.0, 0.0, 12.0)
	events.clear()
	var band_r := _band([_magpie(spot_r + Vector3(1.0, 0.0, 0.0)), _magpie(spot_r + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"workers", "team": P, "node": remote, "spot": spot_r})
	_check(await _wait_until(func() -> bool: return band_r.state == &"striking", 600), "remote band strikes")
	var started := _events(&"strike_started")
	_check(started.size() == 1 and started[0][2][1] == far_one, "the worker near its keep is skipped")
	_check(await _wait_until(func() -> bool: return band_r.state == &"fleeing", 1200), "remote strike ends")
	_eq(band_r.worker_kills, 1, "only the remote worker is killed")
	_check(near_keep.is_alive() and near_keep.hp == near_keep.max_hp, "the worker within 30 m of its keep is untouched")
	stages += 1


func _test_sacks() -> void:
	var at := Vector3(60.0, 0.0, 60.0)
	var band := _band([_magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(-1.0, 0.0, 0.0))],
			{"kind": &"road", "team": P, "post": net, "spot": at})
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "band reaches lurking")
	var near_sack: Node3D = sack_script.call(&"spawn", world, at + Vector3(10.0, 0.0, 4.0), 30)
	var far_sack: Node3D = sack_script.call(&"spawn", world, at + Vector3(-20.0, 0.0, 0.0), 25)
	spawned.append(far_sack)
	var near_ref: WeakRef = weakref(near_sack)
	_check(await _wait_until(func() -> bool: return near_ref.get_ref() == null, 600), "a sack within 15 m is taken")
	_eq(band.loot_total(), 30, "its gold becomes loot")
	await _seconds(3.0)
	_check(is_instance_valid(far_sack), "a sack 20 m away is left")
	_check(await _wait_until(func() -> bool:
		for m in band.thieves:
			if _flat((m as Node3D).global_position, at) > 3.5:
				return false
		return true, 600), "the runner walks back to the cluster")
	_eq(band.state, &"lurking", "still lurking after the sack")
	stages += 1


# Spot choice (first valid spot of the route), 90 s lurk, one move to the next valid spot, 90 s, home.
func _test_lurk_cycle() -> void:
	var s0 := Vector3(40.0, 0.0, 0.0)
	var s1 := Vector3(40.0, 0.0, 20.0)
	var s2 := Vector3(40.0, 0.0, 40.0)
	net.set(&"spots", [s0, s1, s2])
	var guard := _soldier(&"shade", P, s0 + Vector3(5.0, 0.0, 0.0), true)
	var band := _band([_magpie(s1 + Vector3(-4.0, 0.0, 0.0)), _magpie(s1 + Vector3(-4.0, 0.0, 2.0))],
			{"kind": &"road", "team": P, "post": net})
	var fin := [false]
	band.finished.connect(func(_b: Node) -> void: fin[0] = true)
	await _wait_until(func() -> bool: return band.spot.is_finite(), 120)
	_check(band.spot.distance_to(s1) < 0.01, "the first valid spot of the route is chosen (%s)" % str(band.spot))
	guard.queue_free()
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "band reaches lurking")
	var t0 := _now()
	_check(await _wait_until(func() -> bool: return band.spot.distance_to(s2) < 0.01, 6000), "moves on to the next spot")
	_near(_now() - t0, 90.0, "lurks 90 s at the first spot", 0.6)
	_check(await _wait_until(func() -> bool: return band.state == &"lurking", 600), "lurks at the second spot")
	var t1 := _now()
	_check(await _wait_until(func() -> bool: return band.state == &"fleeing", 6000), "goes home after the second lurk")
	_near(_now() - t1, 90.0, "lurks 90 s at the second spot", 0.6)
	_check(await _wait_until(func() -> bool: return fin[0], 3000), "the band finishes at the Den")
	net.set(&"spots", [])
	stages += 1


func _test_perf() -> void:
	# 200 passive units (both teams, spread), 12 loaded caravans on a line, 3 bands of 3 lurking among them.
	for i in 200:
		var u := _soldier(&"shade", P if i % 2 == 0 else E, Vector3(-90.0 + float(i % 20) * 9.0, 0.0,
				-90.0 + float(i / 20) * 9.0 + (0.0 if i % 2 == 0 else 4.0)), true)
		u.attack_damage = 0.0
	for i in 12:
		_caravan(P if i % 2 == 0 else E, Vector3(-60.0 + float(i) * 10.0, 0.0, 100.0), 50)
	var bands: Array = []
	for b in 3:
		var at := Vector3(-60.0 + 60.0 * b, 0.0, 130.0)
		bands.append(_band([_magpie(at), _magpie(at + Vector3(1.0, 0.0, 0.0)), _magpie(at + Vector3(0.0, 0.0, 1.0))],
				{"kind": &"road", "team": E, "post": net, "spot": at}))
	await _seconds(3.0)
	var usec0 := ThiefBand.think_usec_total
	var count0 := ThiefBand.think_count
	var frames := 600
	await _wait(frames)
	var per_frame := float(ThiefBand.think_usec_total - usec0) / float(frames) / 1000.0
	var thinks := ThiefBand.think_count - count0
	var per_think := float(ThiefBand.think_usec_total - usec0) / maxf(1.0, float(thinks)) / 1000.0
	print("  perf: 3 bands, %d thinks in %d frames, %.4f ms per frame, %.4f ms per think" % [thinks, frames, per_frame, per_think])
	_check(thinks >= 55 and thinks <= 65, "3 bands think 2x per second (%d)" % thinks)
	_check(per_frame < 0.05, "3 bands cost < 0.05 ms per frame (%.4f)" % per_frame)
	if per_frame < 0.05:
		print("PERF OK")
	stages += 1


# ---------------------------------------------------------------- helpers

func _band(thieves: Array, target: Dictionary) -> ThiefBand:
	var b := ThiefBand.new()
	b.loot_sack_script = sack_script
	b.setup(guild, thieves, target)
	world.add_child(b)
	events.clear()
	b.strike_started.connect(func(band: Node, v: Node3D) -> void: events.append([_now(), &"strike_started", [band, v]]))
	b.snatch_started.connect(func(t: Node3D, c: Node3D) -> void: events.append([_now(), &"snatch_started", [t, c]]))
	b.snatched.connect(func(t: Node3D, c: Node3D, n: int) -> void: events.append([_now(), &"snatched", [t, c, n]]))
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


func _soldier(id: StringName, team: int, pos: Vector3, passive: bool) -> Unit:
	var u := UnitType.find(String(id)).create_unit()
	u.team = team as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	if passive:
		u.aggro_range = 0.0
		u.attack_damage = 0.0
	spawned.append(u)
	return u


func _worker(team: int, pos: Vector3, carried: int) -> Unit:
	var u := Worker.make_unit(UnitType.find("cinder_hand"))
	u.team = team as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	u.set(&"carried", carried)
	spawned.append(u)
	return u


func _caravan(team: int, pos: Vector3, cargo: int) -> Unit:
	var u := caravan_script.new() as Unit
	u.apply_type(caravan_type)
	u.team = team as Unit.Team
	u.set(&"cargo", cargo)
	world.add_child(u)
	u.global_position = pos
	u.command_hold()
	spawned.append(u)
	return u


func _building(type_id: StringName, team: int, pos: Vector3) -> Node3D:
	var b := Node3D.new()
	b.set_script(building_script)
	b.set(&"team", team)
	b.set(&"building_type", BuildingType.find(String(type_id)))
	b.add_to_group(&"buildings")
	b.position = pos   # the world sits at the origin
	world.add_child(b)
	if type_id != &"fire_keep":
		spawned.append(b)
	return b


func _events(name: StringName) -> Array:
	return events.filter(func(e: Array) -> bool: return e[1] == name)


func _event_count(name: StringName) -> int:
	return _events(name).size()


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
	events.clear()
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


func _near(got: float, want: float, msg: String, tol: float = 0.01) -> void:
	_check(absf(got - want) <= tol, "%s (got %.3f, want %.3f)" % [msg, got, want])
