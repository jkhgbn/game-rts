extends SceneTree
## Task 10.C6 (market-trade.md 4.2 / 5.1 / 6.1 / 12, "Done when" 10.C6): UnitType trade fields, the caravan /
## magpie / greywater_tracker .tres, Unit.is_commandable() from the type, roaming neutrals (no leash pull),
## Unit.leave_map() (no died / XP / essence / kill credit, pop freed, left_map, 1 s fade), the GoldBank ware
## call in Unit._ready (stubbed bank), victim XP 20 / 25 / 40 / Bazaar 80, caravans never fight.
## Run:  godot --headless --path . -s tests/test_10_c6.gd --fixed-fps 60 --quit-after 3000
## A small world (floor + flat navmesh, no UI, no main scene) so other step-10 agents' files do not matter.

const TASK_ID := "10.C6"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL

# id: [cost, pop, train, hp, armor, damage, range, cooldown, speed, aggro, sight, radius, height, kill_xp,
#      faction, is_caravan, commandable, neutral_leash, model_path]
const TABLE := {
	&"caravan": [75, 1, 20.0, 220.0, 10.0, 0.0, -1.0, -1.0, 4.0, 0.0, 8.0, 0.8, 1.9, 20,
			&"", true, true, true, "res://art/units/caravan/caravan.tscn"],
	&"magpie": [0, 0, -1.0, 140.0, 0.0, 9.0, 1.5, 1.0, 5.2, 0.0, 10.0, 0.4, 1.6, 25,
			&"neutral", false, true, false, "res://art/units/neutral/magpie/magpie.tscn"],
	&"greywater_tracker": [0, 0, -1.0, 240.0, 5.0, 12.0, 7.0, 1.2, 5.4, 0.0, 12.0, 0.45, 1.8, 40,
			&"", false, false, true, "res://art/units/neutral/tracker/tracker.tscn"],
}

## Stub GoldBank (the real one is task 10.C11): puts Tempered Steel on every unit it is asked about.
const BANK_SRC := "extends Node\nvar team := 0\nvar calls: Array = []\n" \
		+ "func apply_wares(unit: Node) -> void:\n\tcalls.append(unit)\n" \
		+ "\tif not unit.has_modifier(&\"ware:tempered_steel\"):\n" \
		+ "\t\tunit.add_modifier(&\"ware:tempered_steel\", {&\"attack_damage_pct\": 0.08})\n"
## Stub champion: records every kill credit (Unit.award_soldier_kill_xp tells group "champions").
const CREDIT_SRC := "extends Node3D\nvar team := 0\nvar credits: Array = []\n" \
		+ "func credit_kill(victim: Node, killer: Node, value: int) -> void:\n\tcredits.append([victim, value])\n"

var world: Node3D
var errors: Array[String] = []
var finished := false
var stages := 0
var spawned: Array = []


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	_test_data()
	_test_commandable_and_xp()
	await _clear()
	await _test_roaming_neutral()
	await _clear()
	await _test_leave_map()
	await _clear()
	await _test_wares()
	await _clear()
	await _test_caravan_never_fights()
	await _clear()
	# A script error aborts a stage silently: every stage counts itself at its very end.
	_eq(stages, 6, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- data

func _test_data() -> void:
	var defaults := UnitType.new()
	_eq(defaults.is_caravan, false, "UnitType.is_caravan defaults to false")
	_eq(defaults.commandable, true, "UnitType.commandable defaults to true")
	_eq(defaults.neutral_leash, true, "UnitType.neutral_leash defaults to true")
	for id: StringName in TABLE:
		var row: Array = TABLE[id]
		var t := UnitType.find(String(id))
		if t == null:
			_check(false, "data/units/%s.tres loads" % id)
			continue
		_eq(t.id, id, "%s id" % id)
		_eq(t.cost, row[0], "%s cost" % id)
		_eq(t.pop, row[1], "%s pop" % id)
		if float(row[2]) >= 0.0:
			_near(t.train_time, row[2], "%s train time" % id)
		_near(t.max_hp, row[3], "%s max_hp" % id)
		_near(t.armor, row[4], "%s armor" % id)
		_near(t.attack_damage, row[5], "%s damage" % id)
		if float(row[6]) >= 0.0:
			_near(t.attack_range, row[6], "%s range" % id)
		if float(row[7]) >= 0.0:
			_near(t.attack_cooldown, row[7], "%s cooldown" % id)
		_near(t.move_speed, row[8], "%s speed" % id)
		_near(t.aggro_range, row[9], "%s aggro" % id)
		_near(t.sight_radius, row[10], "%s sight" % id)
		_near(t.radius, row[11], "%s radius" % id)
		_near(t.body_height, row[12], "%s height" % id)
		_eq(t.kill_xp, row[13], "%s kill_xp" % id)
		_eq(t.faction, row[14], "%s faction" % id)
		_eq(t.is_caravan, row[15], "%s is_caravan" % id)
		_eq(t.commandable, row[16], "%s commandable" % id)
		_eq(t.neutral_leash, row[17], "%s neutral_leash" % id)
		_eq(t.model_path, row[18], "%s model path (section 12)" % id)
		_eq(t.is_worker, false, "%s is not a worker" % id)
	var tracker := UnitType.find("greywater_tracker")
	if tracker:
		_eq(tracker.on_hit_status, &"rooted", "tracker snare arrow roots")
		_near(tracker.on_hit_duration, 0.5, "tracker root 0.5 s")
	stages += 1


# ---------------------------------------------------------------- commandable, veterancy, victim XP

func _test_commandable_and_xp() -> void:
	var caravan := _spawn("caravan", P, Vector3(-60.0, 0.0, -60.0))
	var magpie := _spawn("magpie", N, Vector3(-55.0, 0.0, -60.0))
	var tracker := _spawn("greywater_tracker", P, Vector3(-50.0, 0.0, -60.0))
	var guard := _spawn("flame_guard", P, Vector3(-45.0, 0.0, -60.0))
	_eq(tracker.is_commandable(), false, "a tracker is not commandable")
	# SelectionManager through load(): other step-10 agents edit files it depends on while this runs.
	var sel_script := load("res://scripts/ui/selection_manager.gd") as GDScript
	if sel_script and sel_script.can_instantiate():
		_eq(sel_script.call(&"is_commandable_unit", tracker), false, "selection-for-orders refuses a tracker")
		_eq(sel_script.call(&"is_commandable_unit", caravan), true, "selection-for-orders takes a caravan")
	else:
		print("  (selection_manager.gd does not compile right now: checked is_commandable() only)")
	_eq(caravan.is_commandable(), true, "a caravan is commandable")
	_eq(guard.is_commandable(), true, "a soldier stays commandable")
	var bare := Unit.new()
	_eq(bare.is_commandable(), true, "a unit without a type (wizard) stays commandable")
	bare.free()
	var champ := Champion.new()
	_eq(champ.is_commandable(), false, "a champion stays not commandable")
	champ.free()
	_eq(caravan.can_gain_veterancy(), false, "caravans never level")
	_eq(tracker.can_gain_veterancy(), false, "trackers never level")
	_eq(magpie.can_gain_veterancy(), false, "Magpies never level")
	_eq(guard.can_gain_veterancy(), true, "soldiers still level")
	_eq(Unit.kill_xp_value(caravan), 20, "victim XP caravan")
	_eq(Unit.kill_xp_value(magpie), 25, "victim XP Magpie")
	_eq(Unit.kill_xp_value(tracker), 40, "victim XP tracker")
	for market_id: StringName in [&"fire_market", &"shadow_market", &"ice_market", &"nature_market"]:
		var bazaar := Node3D.new()   # a Bazaar stand-in (Market is task 10.C2)
		var bt := BuildingType.new()
		bt.id = market_id
		bazaar.set_script(_script("extends Node3D\nvar team := 1\nvar building_type: Resource\n"))
		bazaar.set(&"building_type", bt)
		_eq(Unit.kill_xp_value(bazaar), 80, "victim XP %s" % market_id)
		bazaar.free()
	_near(FogOfWar.sight_of(caravan), 8.0, "fog sight caravan")
	_near(FogOfWar.sight_of(magpie), 10.0, "fog sight Magpie")
	_near(FogOfWar.sight_of(tracker), 12.0, "fog sight tracker")
	_eq(magpie.has_neutral_leash(), false, "a Magpie has no neutral leash")
	_eq(guard.has_neutral_leash(), false, "a PLAYER unit has no neutral leash")
	stages += 1


# ---------------------------------------------------------------- roaming neutrals

func _test_roaming_neutral() -> void:
	# A Magpie ordered to attack a soldier 40 m away walks there and fights; a Ruin Warden (leashed) drops the
	# same order at once.
	var target := _spawn("flame_guard", P, Vector3(0.0, 0.0, 10.0))
	target.command_hold()   # stays put (still hits back in range)
	var hits_from := {}
	target.damage_taken.connect(func(_a: float, by: Node3D) -> void:
		if by != null:
			hits_from[by] = true)
	var magpie := _spawn("magpie", N, Vector3(-40.0, 0.0, 10.0))
	var warden_target := _spawn("flame_guard", P, Vector3(0.0, 0.0, -30.0))
	warden_target.command_hold()
	var warden := _spawn("ruin_warden", N, Vector3(-40.0, 0.0, -30.0))
	magpie.command_attack(target)
	warden.command_attack(warden_target)
	await _wait(10)
	_eq(magpie.attack_target, target, "the Magpie keeps an order 40 m from home")
	_eq(warden.attack_target, null, "a leashed Ruin Warden drops a target 40 m away (control)")
	var hit := false
	for i in 900:   # up to 15 s
		await physics_frame
		if hits_from.has(magpie):
			hit = true
			break
	_check(hit, "the Magpie reached the soldier 40 m away and hit it")
	await _wait(120)   # 2 s more: no pull home
	if is_instance_valid(magpie) and magpie.is_alive():
		var from_target := _flat(magpie.global_position, target.global_position)
		_check(from_target < 5.0, "the Magpie fights at the soldier (%.1f m away)" % from_target)
		_check(_flat(magpie.global_position, Vector3(-40.0, 0.0, 10.0)) > 30.0, "the Magpie is not pulled home")
	# An idle roaming Magpie moved 40 m stays there (no walk home).
	var idle := _spawn("magpie", N, Vector3(-40.0, 0.0, 40.0))
	idle.command_move(Vector3(0.0, 0.0, 40.0))
	for i in 720:
		await physics_frame
		if _flat(idle.global_position, Vector3(0.0, 0.0, 40.0)) < 1.5:
			break
	await _wait(120)
	_check(_flat(idle.global_position, Vector3(0.0, 0.0, 40.0)) < 2.0,
			"a Magpie moved 40 m stays there (%.1f m off)" % _flat(idle.global_position, Vector3(0.0, 0.0, 40.0)))
	stages += 1


# ---------------------------------------------------------------- leave_map

func _test_leave_map() -> void:
	var eco := Economy.new()
	eco.team = P
	world.add_child(eco)
	var credit := Node3D.new()
	credit.set_script(_script(CREDIT_SRC))
	credit.add_to_group(&"champions")
	world.add_child(credit)
	spawned.append(eco)
	spawned.append(credit)
	var events := root.get_node_or_null(^"Events")
	var event_deaths: Array = []
	var on_event := func(u: Node) -> void: event_deaths.append(u)
	if events:
		events.connect(&"unit_died", on_event)
	var leaver := _spawn("flame_guard", P, Vector3(20.0, 0.0, 20.0))
	var control := _spawn("flame_guard", P, Vector3(24.0, 0.0, 20.0))
	var shade := _spawn("shade", E, Vector3(22.0, 0.0, 30.0))
	shade.command_hold()
	await _wait(2)
	_eq(eco.pop_used, 2, "two soldiers use 2 pop")
	var died_flags: Array = []
	leaver.died.connect(func(u: Unit) -> void: died_flags.append(u))
	var left: Array = []
	leaver.left_map.connect(func(u: Unit) -> void: left.append(u))
	leaver.take_damage(10.0, shade)
	leaver.apply_status(&"haste", 5.0)
	leaver.leave_map()
	_eq(left, [leaver], "leave_map emits left_map(unit)")
	_eq(leaver.is_alive(), false, "a leaving unit is no longer alive")
	_eq(leaver.has_left_map(), true, "has_left_map()")
	_eq(leaver.is_in_group(&"units"), false, "a leaving unit leaves group units")
	_eq(leaver.active_statuses().size(), 0, "statuses end on leave_map")
	leaver.leave_map()   # twice: nothing more
	_eq(left.size(), 1, "left_map fires once")
	await _wait(30)   # 0.5 s: fading, still in the tree
	_check(is_instance_valid(leaver), "the unit is still fading at 0.5 s")
	if is_instance_valid(leaver):
		var fade := _max_transparency(leaver)
		_check(fade > 0.2 and fade < 0.9, "half-faded at 0.5 s (transparency %.2f)" % fade)
	await _wait(40)   # 1.17 s
	_check(not is_instance_valid(leaver), "the unit is freed after the 1 s fade")
	_eq(died_flags.size(), 0, "leave_map never emits died")
	_eq(event_deaths.size(), 0, "leave_map never emits Events.unit_died (no essence)")
	_eq(shade.xp, 0, "leave_map gives no XP")
	_eq((credit.get(&"credits") as Array).size(), 0, "leave_map gives no kill credit / loot")
	_eq(eco.pop_used, 1, "leave_map frees the pop")
	# Control: a real kill pays.
	control.take_damage(10000.0, shade)
	await _wait(2)
	_eq(shade.xp, 45, "control: a real kill gives the Shade 45 XP")
	_eq((credit.get(&"credits") as Array).size(), 1, "control: a real kill is credited")
	if events:
		_check(event_deaths.size() == 1, "control: Events.unit_died fires on a real kill")
		events.disconnect(&"unit_died", on_event)
	stages += 1


# ---------------------------------------------------------------- wares in _ready

func _test_wares() -> void:
	var bank := Node.new()
	bank.set_script(_script(BANK_SRC))
	bank.set(&"team", P)
	bank.add_to_group(&"gold_banks")
	world.add_child(bank)
	spawned.append(bank)
	var soldier := _spawn("flame_guard", P, Vector3(-20.0, 0.0, 60.0))
	_check(soldier.has_modifier(&"ware:tempered_steel"), "a soldier spawned after Tempered Steel has the ware")
	_near(soldier.get_stat(&"attack_damage"), 12.0 * 1.08, "Tempered Steel +8 % damage")
	_near(soldier.hp, soldier.max_hp, "spawned at full HP")
	_eq((bank.get(&"calls") as Array).count(soldier), 1, "apply_wares called once from _ready")
	var foe := _spawn("shade", E, Vector3(-10.0, 0.0, 60.0))
	_eq(foe.has_modifier(&"ware:tempered_steel"), false, "another team's bank is not used")
	var magpie := _spawn("magpie", N, Vector3(0.0, 0.0, 60.0))
	_eq((bank.get(&"calls") as Array).has(magpie), false, "neutral units never ask a bank")
	stages += 1


# ---------------------------------------------------------------- caravans never fight

func _test_caravan_never_fights() -> void:
	var caravan := _spawn("caravan", P, Vector3(40.0, 0.0, -40.0))
	var shade := _spawn("shade", E, Vector3(41.5, 0.0, -40.0))
	shade.command_attack(caravan)
	caravan.command_attack(shade)
	_eq(caravan.attack_target, null, "a caravan ignores attack orders")
	await _wait(90)
	_eq(caravan.attack_target, null, "a caravan never fights back")
	_check(_flat(caravan.global_position, Vector3(40.0, 0.0, -40.0)) < 1.0, "a caravan does not chase")
	caravan.take_damage(10000.0, shade)
	await _wait(2)
	_eq(shade.xp, 20, "killing a caravan gives 20 XP")
	stages += 1


# ---------------------------------------------------------------- helpers

func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team
	u.position = pos
	world.add_child(u)
	u.command_stop()
	spawned.append(u)
	return u


func _max_transparency(node: Node) -> float:
	var best := 0.0
	for c in node.get_children():
		if c is GeometryInstance3D and (c as GeometryInstance3D).visible:
			best = maxf(best, (c as GeometryInstance3D).transparency)
		best = maxf(best, _max_transparency(c))
	return best


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile:
			n.queue_free()
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


func _near(got: float, want: float, msg: String) -> void:
	_check(absf(got - want) < 0.01, "%s (got %.3f, want %.3f)" % [msg, got, want])
