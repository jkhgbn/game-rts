extends SceneTree
## Task 12.A3: BeastBrain (docs/design/map-fill.md 5.5, contract section 13, "Done when" 12.A3), in a small world
## with a navmesh. EpicBeasts (12.C11) and CreatureAbilities (12.C4) are built in parallel: beasts are plain Units
## with a hand-made UnitType (neutral_leash = false, aggro 0, stats of 5.5), abilities are StubAbilities (a child
## "CreatureAbilities" with ready(id) / cast(id, target) that records the calls).
## - Patrol: visits its 4 points (short pauses in the test), patrol speed; ignores workers, caravans, buildings and
##   neutrals standing next to it.
## - Targets: combatants only (soldiers, wizards, champions, trackers) within aggro and inside the leash; answers
##   an attacker inside the leash (out of aggro); a worker is answered only while it hits.
## - Leash / reset: 8 s without a valid target -> return to the centre -> patrol; beyond the leash -> return;
##   regen 3 % / s after 5 s without damage, full after 10 s.
## - Abilities: Gore Charge 6-14 m, Pounce prefers ranged 5-10 m, Gale Swoop / Shrieking Dive on the crowd,
##   Maul in reach, Rending Roar at <= 50 %, Enrage < 30 %, Updraft once at 40 % (flies to the nest), escape
##   without a CreatureAbilities node.
## - Death: a brain that is not the beast's child frees itself. Perf: 8 beasts + 160 soldiers < 0.03 ms / frame.
## Run:  godot --headless --path . -s tests/test_12_a3.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "12.A3"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL

## id -> [max_hp, damage, cooldown, range, fight speed, radius]
const BEASTS := {
	&"ironhide_tusker": [1800.0, 34.0, 1.5, 1.8, 5.5, 1.0],
	&"old_scarback": [2160.0, 34.0, 1.5, 1.8, 5.5, 1.0],
	&"stormcrest_roc": [1500.0, 24.0, 1.2, 3.0, 6.5, 0.9],
	&"duskwing_roc": [1500.0, 24.0, 1.2, 3.0, 6.5, 0.9],
	&"greymane_direwolf": [1300.0, 26.0, 1.0, 1.6, 7.0, 0.8],
	&"moonpelt_direwolf": [1300.0, 26.0, 1.0, 1.6, 7.5, 0.8],
	&"grizzlemaw": [2600.0, 42.0, 1.8, 2.0, 5.0, 1.1],
	&"elder_grizzlemaw": [3000.0, 42.0, 1.8, 2.0, 5.0, 1.1],
}


## CreatureAbilities stand-in (12.C4 builds the real one).
class StubAbilities extends Node:
	var calls: Array = []          # [id, target]
	var cooldowns := {}            # id -> seconds (default 10)
	var next_ready := {}           # id -> clock
	var refuse := {}               # id -> reason
	var clock := 0.0

	func _physics_process(delta: float) -> void:
		clock += delta

	func ready(id: StringName) -> bool:
		return clock >= float(next_ready.get(id, 0.0))

	func cast(id: StringName, target: Variant) -> String:
		if refuse.has(id):
			return str(refuse[id])
		calls.append([id, target])
		next_ready[id] = clock + float(cooldowns.get(id, 10.0))
		return ""

	func count(id: StringName) -> int:
		var n := 0
		for c: Array in calls:
			if c[0] == id:
				n += 1
		return n

	func last(id: StringName) -> Variant:
		for i in range(calls.size() - 1, -1, -1):
			if calls[i][0] == id:
				return calls[i][1]
		return null


## A building (never a beast target).
class StubBuilding extends Node3D:
	var team := 0

	func _init() -> void:
		add_to_group(&"buildings")

	func is_alive() -> bool:
		return true

	func take_damage(_amount: float, _attacker: Node3D = null) -> void:
		pass

	func target_radius() -> float:
		return 1.5


var world: Node3D
var errors: Array[String] = []
var notes: Array[String] = []
var finished := false
var spawned: Array = []
var stages := 0


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240.0, 1.0, 240.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(240.0, 240.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	_test_is_combatant()
	await _test_patrol_and_ignore()
	await _clear()
	await _test_targets()
	await _clear()
	await _test_leash_and_reset()
	await _clear()
	await _test_charge_pounce_swoop()
	await _clear()
	await _test_grizzlemaw()
	await _clear()
	await _test_updraft()
	await _clear()
	await _test_death()
	await _clear()
	await _test_real_abilities()
	await _clear()
	await _test_perf()
	await _clear()
	_eq(stages, 10, "every stage ran to its end")
	for n in notes:
		print("NOTE %s: %s" % [TASK_ID, n])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- is_combatant

func _test_is_combatant() -> void:
	var s := _soldier(P, Vector3(50, 0, 50))
	var wiz := _soldier(E, Vector3(51, 0, 50))
	wiz.add_to_group(&"heroes")
	var champ := _soldier(P, Vector3(52, 0, 50))
	champ.add_to_group(&"champions")
	var tracker := _soldier(E, Vector3(53, 0, 50))
	tracker.add_to_group(&"trackers")
	var worker := _worker(P, Vector3(54, 0, 50))
	var caravan := _caravan(P, Vector3(55, 0, 50))
	var creature := _soldier(N, Vector3(56, 0, 50))
	var b := _building(P, Vector3(58, 0, 50))
	_check(BeastBrain.is_combatant(s), "a soldier is a combatant")
	_check(BeastBrain.is_combatant(wiz), "a wizard is a combatant")
	_check(BeastBrain.is_combatant(champ), "a champion is a combatant")
	_check(BeastBrain.is_combatant(tracker), "a tracker is a combatant")
	_check(not BeastBrain.is_combatant(worker), "a worker is not a combatant")
	_check(not BeastBrain.is_combatant(caravan), "a caravan is not a combatant")
	_check(not BeastBrain.is_combatant(creature), "a neutral creature is not a combatant")
	_check(not BeastBrain.is_combatant(b), "a building is not a combatant")
	_check(not BeastBrain.is_combatant(null), "null is not a combatant")
	stages += 1


# ---------------------------------------------------------------- patrol

func _test_patrol_and_ignore() -> void:
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4), Vector3(-4, 0, 0), Vector3(0, 0, 4), Vector3(4, 0, 0)])
	var pair := _beast(&"ironhide_tusker", Vector3.ZERO, lair, true)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	brain.pause_min = 1.0
	brain.pause_max = 1.5
	var worker := _worker(P, Vector3(2.5, 0, 2.5))
	var caravan := _caravan(E, Vector3(-2.5, 0, 2.5))
	var b := _building(P, Vector3(3, 0, -3))
	var creature := _soldier(N, Vector3(-2.5, 0, -2.5))
	var ignored := [worker, caravan, b, creature]
	var seen := [false, false, false, false]
	var speed_ok := false
	var speed_seen := 0.0
	var bad_target := false
	for f in 60 * 45:
		await physics_frame
		for i in 4:
			if _flat(beast.global_position, lair["patrol"][i]) <= 1.6:
				seen[i] = true
		if brain.state == &"patrol" and beast.get_stat(&"move_speed") > 0.0:
			speed_seen = beast.move_speed
			if absf(beast.move_speed - 3.5) < 0.05:
				speed_ok = true
		if ignored.has(beast.attack_target) or ignored.has(brain.target):
			bad_target = true
		if seen.count(true) == 4 and f > 60 * 3:
			await _wait_s(0.6)   # the brain counts the last point at its next think
			break
	_eq(seen, [true, true, true, true], "the tusker visited its 4 patrol points")
	_check(brain.patrol_visits >= 4, "patrol_visits counts the points (%d)" % brain.patrol_visits)
	_check(speed_ok, "patrol speed 3.5 (seen %.2f)" % speed_seen)
	_check(beast.has_modifier(&"beast:patrol"), "the beast:patrol modifier is on while patrolling")
	_eq(brain.state, &"patrol", "state stays patrol next to a worker, a caravan, a building and a neutral")
	_check(not bad_target, "never targets a worker, a caravan, a building or a neutral")
	# A soldier walking into aggro starts a fight, at fight speed.
	var s := _soldier(P, beast.global_position + Vector3(6, 0, 0))
	await _wait_s(1.0)
	_eq(brain.state, &"fight", "a soldier 6 m away starts a fight")
	_check(brain.target == s, "the soldier is the target")
	_check(beast.attack_target == s, "the beast attacks the soldier")
	_check(not beast.has_modifier(&"beast:patrol"), "fight speed in a fight")
	stages += 1


# ---------------------------------------------------------------- targets

func _test_targets() -> void:
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4), Vector3(4, 0, 0)])
	# A champion and a tracker are picked like soldiers (think_now: no automatic ticks).
	var pair := _beast(&"greymane_direwolf", Vector3.ZERO, lair, false)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	brain.enabled = false
	var worker := _worker(E, Vector3(1.5, 0, 0))
	var champ := _soldier(E, Vector3(7, 0, 0))
	champ.add_to_group(&"champions")
	await _think(brain)
	_eq(brain.state, &"fight", "a champion within aggro 9 starts a fight")
	_check(brain.target == champ, "the champion is picked, not the worker next to the beast")
	_kill(champ)
	var tracker := _soldier(P, Vector3(0, 0, 8))
	tracker.add_to_group(&"trackers")
	await _wait(2)
	await _think(brain)
	_check(brain.target == tracker, "a tracker is picked after the champion dies")
	_kill(tracker)
	await _wait(2)
	await _think(brain)
	_check(brain.target == null, "no target left (the worker is ignored)")
	# The worker hits the beast: answered while it hits, dropped 3 s after its last hit.
	beast.take_damage(1.0, worker)
	brain.think_now()   # same frame: no blow lands on the worker, so it never hits back for real
	_check(brain.target == worker, "a worker that hits the beast inside the leash is answered")
	beast.command_stop()   # (the brain is off) the beast stands still, the worker walks off
	worker.command_move(Vector3(0, 0, 6))
	await _wait_s(3.6)
	await _think(brain)
	_check(brain.target != worker, "the worker is dropped 3 s after its last hit")
	# Out of aggro but inside the leash (14 m): an attacker is answered.
	var far := _soldier(P, Vector3(12, 0, 0))
	await _think(brain)
	_check(brain.target != far, "a soldier 12 m away (out of aggro 9) is not picked")
	beast.take_damage(1.0, far)
	await _think(brain)
	_check(brain.target == far, "an attacker 12 m away inside the leash is answered")
	# Outside the leash: an attacker is not answered.
	var outside := _soldier(P, Vector3(-18, 0, 0))
	_kill(far)
	await _wait(2)
	beast.take_damage(1.0, outside)
	await _think(brain)
	_check(brain.target != outside, "an attacker 18 m from the centre (leash 14) is not answered")
	# Hidden from auto-target (Smoke Pouch): not picked.
	var hidden := _soldier(P, Vector3(0, 0, -5))
	hidden.hide_from_auto_target(5.0)
	await _think(brain)
	_check(brain.target != hidden, "a unit hidden from auto-target is not picked")
	stages += 1


# ---------------------------------------------------------------- leash / reset

func _test_leash_and_reset() -> void:
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4), Vector3(4, 0, 0), Vector3(0, 0, 4), Vector3(-4, 0, 0)])
	var pair := _beast(&"ironhide_tusker", Vector3.ZERO, lair, true)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	brain.pause_min = 1.0
	brain.pause_max = 1.5
	var s := _soldier(P, Vector3(3, 0, 0))
	await _wait_s(1.0)
	_eq(brain.state, &"fight", "fighting the soldier")
	beast.take_damage(900.0 / 0.8333, null)   # armor 20: ~900 damage -> about half HP
	var half := beast.hp
	# The soldier leaves the leash: no valid target; 8 s later the beast walks home (it stands at the centre, so
	# return -> patrol may happen in one think).
	s.global_position = Vector3(40, 0, 0)
	s.command_stop()
	var t0 := _now()
	var left_at := -1.0
	var hp_home := 0.0
	for f in 60 * 12:
		await physics_frame
		if brain.state != &"fight":
			left_at = _now() - t0
			hp_home = beast.hp
			break
	_check(left_at >= 7.4 and left_at <= 9.0, "leaves the fight ~8 s after losing its target (%.2f s)" % left_at)
	var back := false
	for f in 60 * 10:
		await physics_frame
		if brain.state == &"patrol":
			back = true
			break
	_check(back, "patrols again once home")
	_check(_flat(beast.global_position, Vector3.ZERO) <= 4.5, "home at the lair")
	# Reset heal: none while fighting, +3 % / s after 5 s undamaged, full after 10 s.
	_check(hp_home < half + 0.02 * beast.max_hp, "no regen during the fight (%.0f -> %.0f)" % [half, hp_home])
	await _wait_s(maxf(0.0, 9.2 - beast.seconds_since_damage()))
	_check(beast.hp > half + 0.02 * beast.max_hp and beast.hp < beast.max_hp,
			"regenerates 3 %% / s after 5 s undamaged (%.0f -> %.0f)" % [half, beast.hp])
	await _wait_s(maxf(0.0, 10.7 - beast.seconds_since_damage()))
	_check(is_equal_approx(beast.hp, beast.max_hp), "full HP 10 s after the last damage (%.0f / %.0f)" % [beast.hp, beast.max_hp])
	# Beyond the leash: the beast walks back at once.
	var s2 := _soldier(P, beast.global_position + Vector3(2, 0, 0))
	await _wait_s(1.0)
	_eq(brain.state, &"fight", "fighting again")
	beast.global_position = Vector3(18, 0, 0)
	await _wait_s(0.6)
	_eq(brain.state, &"return", "beyond the leash (18 m > 14 + 1): return")
	_check(not beast.has_modifier(&"beast:patrol"), "returns at fight speed")
	_check(brain.target == null, "no target while returning")
	# While returning it ignores attackers.
	beast.take_damage(1.0, s2)
	await _wait_s(0.6)
	_eq(brain.state, &"return", "an attacker does not stop the return")
	stages += 1


# ---------------------------------------------------------------- charge / pounce / swoop

func _test_charge_pounce_swoop() -> void:
	# Tusker: Gore Charge on a combatant 6-14 m away (the target at 2 m is too close).
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4)])
	var pair := _beast(&"ironhide_tusker", Vector3.ZERO, lair, false)
	var brain: BeastBrain = pair[1]
	var ab: StubAbilities = pair[2]
	brain.enabled = false
	var near := _soldier(P, Vector3(2, 0, 0))
	var mid := _soldier(P, Vector3(-10, 0, 0))
	var too_far := _soldier(P, Vector3(0, 0, 13.5))   # inside the leash but 13.5 m: also in the band
	await _think(brain)
	_eq(ab.count(&"gore_charge"), 1, "Gore Charge cast once")
	_check(ab.last(&"gore_charge") == mid, "Gore Charge on the nearest combatant 6-14 m away")
	_check(brain.target == mid, "the charged unit becomes the target")
	await _think(brain)
	_eq(ab.count(&"gore_charge"), 1, "Gore Charge waits for its cooldown (ready false)")
	_check(too_far != null, "")
	await _clear()
	# Direwolf: Pounce prefers a ranged unit 5-10 m away.
	lair = _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4)])
	pair = _beast(&"greymane_direwolf", Vector3.ZERO, lair, false)
	brain = pair[1]
	ab = pair[2]
	brain.enabled = false
	var first := _soldier(E, Vector3(1.5, 0, 0))
	var melee := _soldier(E, Vector3(6, 0, 0))
	var archer := _soldier(E, Vector3(0, 0, -8))
	archer.attack_range = 6.0
	await _think(brain)
	_check(brain.state == &"fight" and first != null, "the direwolf fights")
	_eq(ab.count(&"pounce"), 1, "Pounce cast")
	_check(ab.last(&"pounce") == archer, "Pounce on the ranged unit 8 m away (not the melee one at 6 m)")
	_check(melee != null, "")
	await _clear()
	# Roc A: Gale Swoop on the crowd; Roc B: Shrieking Dive.
	for id: StringName in [&"stormcrest_roc", &"duskwing_roc"]:
		lair = _lair(Vector3.ZERO, 5.0, [Vector3(0, 0, -4)])
		pair = _beast(id, Vector3.ZERO, lair, false)
		brain = pair[1]
		ab = pair[2]
		brain.enabled = false
		var lone := _soldier(P, Vector3(4, 0, 0))
		var c1 := _soldier(P, Vector3(-9, 0, 0))
		var c2 := _soldier(P, Vector3(-9.5, 0, 1.0))
		var c3 := _soldier(P, Vector3(-9, 0, -1.2))
		await _think(brain)
		var want := &"shrieking_dive" if id == &"duskwing_roc" else &"gale_swoop"
		var other := &"gale_swoop" if id == &"duskwing_roc" else &"shrieking_dive"
		_eq(ab.count(want), 1, "%s casts %s" % [id, want])
		_eq(ab.count(other), 0, "%s never casts %s" % [id, other])
		var hit: Variant = ab.last(want)
		_check(hit == c1 or hit == c2 or hit == c3, "%s leaps onto the crowd, not the lone unit" % id)
		_check(lone != null, "")
		await _clear()
	stages += 1


# ---------------------------------------------------------------- grizzlemaw

func _test_grizzlemaw() -> void:
	var lair := _lair(Vector3.ZERO, 5.0, [Vector3(0, 0, -4)])
	var pair := _beast(&"grizzlemaw", Vector3.ZERO, lair, false)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	var ab: StubAbilities = pair[2]
	brain.enabled = false
	var s := _soldier(P, Vector3(2.5, 0, 0))
	await _think(brain)
	_eq(ab.count(&"maul"), 1, "Maul on the target in reach")
	_check(ab.last(&"maul") == s, "Maul hits the target")
	_eq(ab.count(&"rending_roar"), 0, "no roar above 50 % HP")
	beast.hp = beast.max_hp * 0.45
	await _think(brain)
	_eq(ab.count(&"rending_roar"), 1, "Rending Roar at 45 % HP with an enemy within 6 m")
	await _think(brain)
	_eq(ab.count(&"rending_roar"), 1, "the roar waits 30 s (ready false)")
	_eq(ab.count(&"enrage"), 0, "no enrage above 30 %")
	beast.hp = beast.max_hp * 0.25
	await _think(brain)
	_eq(ab.count(&"enrage"), 1, "enrage below 30 %")
	await _think(brain)
	_eq(ab.count(&"enrage"), 1, "enrage once")
	stages += 1


# ---------------------------------------------------------------- updraft

func _test_updraft() -> void:
	var nest := Vector3(8, 0, 0)
	var lair := _lair(Vector3.ZERO, 5.0, [Vector3(0, 0, -4), Vector3(4, 0, 0)])
	lair["nest"] = nest
	var pair := _beast(&"stormcrest_roc", Vector3(-3, 0, 0), lair, true)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	var ab: StubAbilities = pair[2]
	var s := _soldier(P, Vector3(-5, 0, 0))
	s.max_hp = 1.0e6
	s.hp = s.max_hp
	await _wait_s(1.0)
	_eq(brain.state, &"fight", "the roc fights")
	beast.hp = beast.max_hp * 0.35
	await _wait_s(0.6)
	_eq(brain.state, &"escape", "Updraft escape at 35 % HP")
	_eq(ab.count(&"updraft"), 1, "Updraft cast")
	var tgt: Variant = ab.last(&"updraft")
	_check(tgt is Vector3 and _flat(tgt, nest) < 0.5, "Updraft's target is the nest position")
	_check(brain.escaped, "escaped flag set")
	var arrived := false
	for f in 60 * 11:
		await physics_frame
		if brain.state != &"escape":
			arrived = true
			break
	_check(arrived, "the escape ends")
	_check(_flat(beast.global_position, nest) <= 3.0, "the roc is at its nest (%.1f m)" % _flat(beast.global_position, nest))
	beast.hp = beast.max_hp * 0.2
	await _wait_s(1.0)
	_check(brain.state != &"escape", "no second escape")
	_eq(ab.count(&"updraft"), 1, "Updraft once per life")
	await _clear()
	# Without a CreatureAbilities node the roc still flies home.
	lair = _lair(Vector3.ZERO, 5.0, [Vector3(0, 0, -4)])
	lair["nest"] = nest
	pair = _beast(&"stormcrest_roc", Vector3(-2, 0, 0), lair, true, false)
	beast = pair[0]
	brain = pair[1]
	beast.hp = beast.max_hp * 0.3
	await _wait_s(0.6)
	_eq(brain.state, &"escape", "escape without CreatureAbilities")
	stages += 1


# ---------------------------------------------------------------- death

func _test_death() -> void:
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4)])
	var pair := _beast(&"ironhide_tusker", Vector3.ZERO, lair, true)
	var beast: Unit = pair[0]
	var brain: BeastBrain = pair[1]
	_check(brain.is_in_group(&"beast_brains"), "brains are in group beast_brains")
	_kill(beast)
	await _wait(3)
	_check(not is_instance_valid(brain), "a brain beside its beast frees itself when the beast dies")
	# A brain that is the beast's child just stops.
	var b2 := _beast_unit(&"ironhide_tusker", Vector3(20, 0, 20), true)
	var child := BeastBrain.new()
	b2.add_child(child)
	child.setup(b2, _lair(Vector3(20, 0, 20), 4.0, [Vector3(20, 0, 16)]))
	_kill(b2)
	await _wait(3)
	_check(not is_instance_valid(b2) or is_instance_valid(child), "a child brain stays with its beast")
	stages += 1


# ---------------------------------------------------------------- real CreatureAbilities (12.C4), when present

func _test_real_abilities() -> void:
	const AB_PATH := "res://scripts/units/creature_abilities.gd"
	if not ResourceLoader.exists(AB_PATH) or not ResourceLoader.exists("res://data/units/ironhide_tusker.tres") \
			or not ResourceLoader.exists("res://data/units/stormcrest_roc.tres"):
		notes.append("real CreatureAbilities / beast .tres missing: integration stage skipped")
		stages += 1
		return
	var ab_script: Script = load(AB_PATH)
	# Tusker: autocast off, patrol pace through set_patrolling, the brain's Gore Charge really dashes.
	var lair := _lair(Vector3.ZERO, 4.0, [Vector3(0, 0, -4), Vector3(4, 0, 0)])
	var beast := _real_beast("res://data/units/ironhide_tusker.tres", Vector3.ZERO, ab_script)
	var brain := BeastBrain.new()
	world.add_child(brain)
	brain.setup(beast, lair)
	spawned.append(brain)
	var ab: Node = beast.get_node("CreatureAbilities")
	_check(ab.get(&"autocast_enabled") == false, "the brain turns CreatureAbilities' autocast off")
	await _wait_s(1.0)
	_check(beast.has_modifier(&"beast:patrol"), "patrol pace with the real CreatureAbilities")
	var near := _soldier(P, beast.global_position + Vector3(2, 0, 0))
	near.max_hp = 1.0e6
	near.hp = near.max_hp
	var far := _soldier(P, beast.global_position + Vector3(-9, 0, 0))
	far.max_hp = 1.0e6
	far.hp = far.max_hp
	var charged := false
	var moved := 0.0
	var start := beast.global_position
	for f in 60 * 5:
		await physics_frame
		moved = maxf(moved, _flat(start, beast.global_position))
		if int(brain.casts.get(&"gore_charge", 0)) > 0:
			charged = true
	_check(charged, "the brain casts the real Gore Charge (log: %s)" % " / ".join(brain.log_lines.slice(-4)))
	_check(float(ab.call(&"cooldown_left", &"gore_charge")) > 0.0, "Gore Charge on cooldown after the cast")
	_check(moved >= 4.0, "the charge moved the tusker (%.1f m)" % moved)
	_eq(brain.state, &"fight", "still fighting after the charge")
	await _clear()
	# Roc: the real Updraft (shroud, heal) and the flight to the nest, once.
	var nest := Vector3(8, 0, 0)
	lair = _lair(Vector3.ZERO, 5.0, [Vector3(0, 0, -4)])
	lair["nest"] = nest
	beast = _real_beast("res://data/units/stormcrest_roc.tres", Vector3(-3, 0, 0), ab_script)
	brain = BeastBrain.new()
	world.add_child(brain)
	brain.setup(beast, lair)
	spawned.append(brain)
	ab = beast.get_node("CreatureAbilities")
	var s := _soldier(P, Vector3(-5, 0, 0))
	s.max_hp = 1.0e6
	s.hp = s.max_hp
	await _wait_s(1.0)
	beast.hp = beast.max_hp * 0.35
	await _wait_s(0.6)
	_eq(brain.state, &"escape", "real Updraft: escape")
	_check(bool(ab.call(&"updraft_used")), "real Updraft used")
	_check(beast.has_status(&"shroud"), "shroud during the escape")
	for f in 60 * 11:
		await physics_frame
		if brain.state != &"escape":
			break
	_check(_flat(beast.global_position, nest) <= 3.0, "the roc reached its nest (%.1f m)" % _flat(beast.global_position, nest))
	stages += 1


func _real_beast(tres: String, pos: Vector3, ab_script: Script) -> Unit:
	var u := Unit.new()
	u.apply_type(load(tres) as UnitType)
	u.team = N
	u.add_to_group(&"beasts")
	var ab: Node = ab_script.new()
	ab.name = "CreatureAbilities"
	u.add_child(ab)
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	ab.call(&"setup", u, [] as Array[StringName])
	spawned.append(u)
	return u


# ---------------------------------------------------------------- perf

func _test_perf() -> void:
	var ids: Array = BEASTS.keys()
	var brains: Array = []
	for i in 8:
		var c := Vector3(-60 + 40 * (i % 4), 0, -30 + 60 * (i / 4))
		var lair := _lair(c, 4.0, [c + Vector3(0, 0, -4), c + Vector3(-4, 0, 0), c + Vector3(0, 0, 4), c + Vector3(4, 0, 0)])
		var pair := _beast(ids[i], c, lair, true)
		(pair[1] as BeastBrain).pause_min = 2.0
		(pair[1] as BeastBrain).pause_max = 4.0
		brains.append(pair[1])
		for k in 20:
			var a := TAU * float(k) / 20.0
			var r := 6.0 + float(k % 5) * 4.0
			var s := _soldier(P if k % 2 == 0 else E, c + Vector3(cos(a) * r, 0, sin(a) * r))
			s.max_hp = 1.0e6
			s.hp = s.max_hp
	await _wait(30)
	var usec0 := BeastBrain.think_usec_total
	var count0 := BeastBrain.think_count
	var scan0 := BeastBrain.scan_usec_total
	var frames := 600
	var max_per_frame := 0
	for f in frames:
		var before := BeastBrain.think_count
		await physics_frame
		max_per_frame = maxi(max_per_frame, BeastBrain.think_count - before)
	var usec := BeastBrain.think_usec_total - usec0
	var thinks := BeastBrain.think_count - count0
	var per_frame_ms := float(usec) / float(frames) / 1000.0
	notes.append("perf: 8 brains + 160 soldiers: %.4f ms / frame, %d thinks in %d frames (%.1f us each), max %d per frame" \
			% [per_frame_ms, thinks, frames, float(usec) / maxf(1.0, float(thinks)), max_per_frame])
	var in_leash := 0
	for b: BeastBrain in brains:
		in_leash += b.combatants_in_leash().size()
	notes.append("perf: scans %.1f us per think; %d combatants inside the 8 leashes" % [
			float(BeastBrain.scan_usec_total - scan0) / maxf(1.0, float(thinks)), in_leash])
	_check(per_frame_ms < 0.03, "8 brains cost < 0.03 ms / frame (%.4f)" % per_frame_ms)
	_check(thinks >= 8 * 2 * 9 and thinks <= 8 * 2 * 11, "each brain thinks every 0.5 s (%d thinks in 10 s)" % thinks)
	_check(max_per_frame <= 1, "brains are staggered (max %d per frame)" % max_per_frame)
	var fighting := 0
	for b: BeastBrain in brains:
		if b.state == &"fight":
			fighting += 1
	notes.append("perf: %d of 8 beasts fighting at the end" % fighting)
	stages += 1


# ---------------------------------------------------------------- helpers

func _lair(center: Vector3, radius: float, patrol: Array) -> Dictionary:
	var pts := PackedVector3Array()
	for p: Vector3 in patrol:
		pts.append(p)
	return {"id": &"test_lair", "name": "Test Lair", "center": center, "radius": radius, "patrol": pts,
			"first_spawn": 0.0, "respawn": 600.0}


func _beast_unit(id: StringName, pos: Vector3, with_abilities: bool) -> Unit:
	var st: Array = BEASTS[id]
	var t := UnitType.new()
	t.id = id
	t.display_name = String(id).capitalize()
	t.faction = &"neutral"
	t.max_hp = st[0]
	t.attack_damage = st[1]
	t.attack_cooldown = st[2]
	t.attack_range = st[3]
	t.move_speed = st[4]
	t.radius = st[5]
	t.body_height = 2.0
	t.armor = 20.0 if String(id).contains("tusker") or id == &"old_scarback" else 5.0
	t.aggro_range = 0.0
	t.neutral_leash = false
	var u := Unit.new()
	u.apply_type(t)
	u.team = N
	u.add_to_group(&"beasts")
	if with_abilities:
		var ab := StubAbilities.new()
		ab.name = "CreatureAbilities"
		ab.cooldowns = {&"gore_charge": 12.0, &"gale_swoop": 10.0, &"shrieking_dive": 10.0, &"pounce": 9.0,
				&"maul": 9.0, &"rending_roar": 30.0, &"updraft": 1.0e9, &"enrage": 1.0e9}
		u.add_child(ab)
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


## [beast, brain, abilities or null]; the brain is a child of the world (like a child of EpicBeasts).
func _beast(id: StringName, pos: Vector3, lair: Dictionary, auto: bool, with_abilities: bool = true) -> Array:
	var u := _beast_unit(id, pos, with_abilities)
	var brain := BeastBrain.new()
	brain.enabled = auto
	world.add_child(brain)
	brain.setup(u, lair)
	spawned.append(brain)
	return [u, brain, u.get_node_or_null("CreatureAbilities")]


func _soldier(team: int, pos: Vector3) -> Unit:
	var s := Unit.new()
	s.team = team
	s.max_hp = 5000.0
	s.attack_damage = 5.0
	s.attack_range = 1.6
	s.aggro_range = 0.0
	world.add_child(s)
	s.global_position = pos
	s.command_stop()
	spawned.append(s)
	return s


func _worker(team: int, pos: Vector3) -> Unit:
	var t := UnitType.new()
	t.id = &"test_worker"
	t.is_worker = true
	t.max_hp = 5000.0
	t.attack_damage = 5.0
	t.aggro_range = 0.0
	var w := Unit.new()
	w.apply_type(t)
	w.team = team
	world.add_child(w)
	w.global_position = pos
	w.command_stop()
	spawned.append(w)
	return w


func _caravan(team: int, pos: Vector3) -> Unit:
	var t := UnitType.new()
	t.id = &"test_caravan"
	t.is_caravan = true
	t.max_hp = 5000.0
	t.attack_damage = 0.0
	t.aggro_range = 0.0
	var c := Unit.new()
	c.apply_type(t)
	c.team = team
	c.add_to_group(&"caravans")
	world.add_child(c)
	c.global_position = pos
	c.command_stop()
	spawned.append(c)
	return c


func _building(team: int, pos: Vector3) -> Node3D:
	var b := StubBuilding.new()
	b.team = team
	world.add_child(b)
	b.global_position = pos
	spawned.append(b)
	return b


func _kill(u: Variant) -> void:
	if u != null and is_instance_valid(u) and (u as Unit).is_alive():
		(u as Unit).take_damage(1.0e9, null)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _now() -> float:
	return float(Engine.get_physics_frames()) / 60.0


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n) and n is BeastBrain:
			(n as BeastBrain).enabled = false
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile:
			n.queue_free()
	await _wait(3)


## Two physics frames (the leash area sees new / moved units), then one think.
func _think(brain: BeastBrain) -> void:
	await physics_frame
	await physics_frame
	brain.think_now()


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _wait_s(seconds: float) -> void:
	for i in int(ceil(seconds * 60.0)):
		await physics_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	if got != want:
		errors.append("%s (got %s, want %s)" % [what, str(got), str(want)])
