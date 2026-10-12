extends SceneTree
## Bot review 2026-10-12, part B (docs/handoff/bot-review-2026-10-12.md): regression checks for the champion fixes.
##  B1 a Ruin Peddler that cannot sell the next wish is no shopping detour; it is when the next wish is sold there.
##  B2 a current flag whose utility dropped to 0 is dropped (no hysteresis).
##  B3 every tavern held -> no hire due (no reserve); the tavern nearest the wizard held, the other free -> the bot hires.
##  B4 explore goals stay inside MapInfo (a smaller map than the old 56 m constant).
##  B5 a Guard flag of another rule does not block the base-defence Guard flag B1.
## Run:  godot --headless --path . -s tests/test_botfix_champions.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "botfix_champions"
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1


class StubChampion extends Unit:
	var champion_type: Resource = null
	var display_name := "Stub"
	var variant := 0
	var purse := 0
	var intent: StringName = &"Idle"
	var intent_target: Node3D = null
	var is_unpaid := false
	var inventory: Node = null
	var brain: Node = null

	func _init() -> void:
		add_to_group(&"champions")

	func set_intent(id: StringName, target: Node3D = null) -> void:
		intent = id
		intent_target = target

	func power(_with_hp: bool = false) -> float:
		return 150.0 + 50.0 * float(level)

	func add_purse(n: int) -> void:
		purse += n

	func spend_purse(n: int) -> bool:
		if purse < n:
			return false
		purse -= n
		return true

	func xp_to_next() -> int:
		return 0

	func full_name() -> String:
		return display_name


class StubBounty extends Node3D:
	enum { HUNT, EXPLORE, GUARD, ESCORT }
	var team := 0
	var kind := 0
	var target: Node3D = null
	var stake := 0
	var pursuers: Array = []
	var valid := true

	func _ready() -> void:
		add_to_group(&"bounties")

	func add_pursuer(ch: Node3D) -> void:
		if not pursuers.has(ch):
			pursuers.append(ch)

	func remove_pursuer(ch: Node3D) -> void:
		pursuers.erase(ch)

	func is_valid() -> bool:
		return valid and (kind == EXPLORE or (target != null and is_instance_valid(target)
				and bool(target.call(&"is_alive"))))


var main: Node
var fog: FogOfWar
var _done := false
var _errors: Array[String] = []
var _oks := 0
var _temp: Array = []


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if ok:
		_oks += 1
		print("ok   " + what)
	else:
		_errors.append(what)
		print("FAIL " + what)


func _clear() -> void:
	for n: Variant in _temp:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	_temp.clear()
	await _frames(2)


func _stub(arch: StringName, team: int, pos: Vector3) -> Unit:
	var ch := StubChampion.new()
	var t: Resource = load("res://data/champions/%s.tres" % arch)
	ch.champion_type = t
	ch.display_name = "%s_%d" % [arch, team]
	ch.name = ch.display_name
	ch.team = team as Unit.Team
	for stat: String in ["max_hp", "move_speed", "attack_damage", "attack_cooldown", "attack_range", "aggro_range"]:
		var v: Variant = t.get(StringName(stat))
		if v != null:
			ch.set(StringName(stat), v)
	main.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	var brain := ChampionBrain.new()
	brain.name = "Brain"
	brain.enabled = false
	ch.add_child(brain)
	ch.brain = brain
	_temp.append(ch)
	return ch


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	_temp.append(u)
	return u


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _run() -> void:
	var waited := 0
	while not main.match_started:
		await process_frame
		waited += 1
		if waited > 6000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			_done = true
			return
	for child in main.get_children():
		if child is Commander:
			(child as Commander).enabled = false
	fog = main.get(&"fog") as FogOfWar
	if fog == null:
		fog = FogOfWar.find()
	ChampionSense.for_team(P)
	ChampionSense.for_team(E)
	await _frames(3)

	await _phase_b1()
	await _phase_b2()
	await _phase_b4()
	await _phase_b6()
	await _phase_b7()
	await _phase_b8()
	await _phase_b3_b5()

	print("---- %d checks, %d failed" % [_oks + _errors.size(), _errors.size()])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	_done = true


# B1: a real Coin-Cutter (first wish Ember Shard, base only) next to a Ruin Peddler.
func _phase_b1() -> void:
	var peddlers: Array = main.get(&"peddlers")
	if peddlers.is_empty():
		_check(false, "B1: the skirmish has Ruin Peddlers")
		return
	var ped := peddlers[0] as Node3D
	var ch := ChampionType.find(&"coin_cutter").create_champion(0)
	ch.team = P as Unit.Team
	main.add_child(ch)
	_temp.append(ch)
	var to_center := (Vector3.ZERO - ped.global_position)
	to_center.y = 0.0
	ch.global_position = ped.global_position + (to_center.normalized() if to_center.length() > 0.1 else Vector3.RIGHT) * 6.0
	ch.command_stop()
	var brain := ch.get_node_or_null(^"Brain") as ChampionBrain
	if brain == null:
		_check(false, "B1: the champion has a Brain")
		return
	brain.enabled = false
	ch.add_purse(2000)
	ChampionSense.for_team(P).refresh()
	brain.think_now()
	var to_peddler: bool = brain.plan == ChampionBrain.Plan.SHOP and brain.plan_node() == ped
	_check(not to_peddler, "B1: no detour to a peddler that cannot sell the next wish (plan %d, node %s)"
			% [brain.plan, str(brain.plan_node())])
	# Ember Shard + Whetted Fang carried: the next wish is Blazing Edge, sold at peddlers too.
	ch.inventory.add_item(ItemType.find(&"ember_shard"))
	ch.inventory.add_item(ItemType.find(&"whetted_fang"))
	brain.last_detour_at = -INF
	brain.plan = ChampionBrain.Plan.NONE
	ChampionSense.for_team(P).refresh()
	var keep_d := _flat(ch.global_position, (main.keep_of(P) as Node3D).global_position)
	brain.think_now()
	var node: Variant = brain.plan_node()
	# standing 6 m from it, the detour buys at once (Blazing Edge combines the two parts) and ends
	var bought: bool = brain.purchases.has("blazing_edge") or (brain.plan == ChampionBrain.Plan.SHOP and node == ped)
	_check(bought, "B1: shops at the peddler once it sells the next wish (bought %s, plan %d, keep %.0f m)"
			% [str(brain.purchases), brain.plan, keep_d])
	await _clear()


# B2: a Hunt flag whose utility drops to 0 is dropped.
func _phase_b2() -> void:
	fog.enabled = false
	var sense := ChampionSense.for_team(P)
	var cc := _stub(&"coin_cutter", P, Vector3(-45.0, 0.0, -25.0))
	var brain := cc.get_node(^"Brain") as ChampionBrain
	var worker := _unit("gloom_thrall", E, Vector3(5.0, 0.0, -25.0))
	var a := StubBounty.new()
	a.kind = 0
	a.team = P
	a.target = worker
	a.stake = 100
	main.add_child(a)
	a.global_position = worker.global_position
	_temp.append(a)
	sense.refresh()
	brain.think_now()
	_check(brain.current_flag == a, "B2: takes the Hunt flag first")
	a.stake = 0   # utility 0
	sense.refresh()
	_check(brain.flag_utility(a) <= 0.0 and brain.choose_flag() == null,
			"B2: choose_flag drops a current flag worth 0 (utility %.2f)" % brain.flag_utility(a))
	brain.think_now()
	_check(brain.current_flag == null and not a.pursuers.has(cc), "B2: the brain left the flag")
	await _clear()
	fog.enabled = true
	await _frames(2)


# B4: on an 80 m map the explore goals stay inside it (the old 56 m constant allowed |x| up to 56).
func _phase_b4() -> void:
	var old_x := MapInfo.size_x
	var old_z := MapInfo.size_z
	var old_id := MapInfo.map_id
	MapInfo.setup(80.0, 80.0, old_id, main)
	var w := _stub(&"wayfinder", P, Vector3(20.0, 0.0, 0.0))
	var brain := w.get_node(^"Brain") as ChampionBrain
	_sync_p()
	var outside := 0
	var found := 0
	for i in 40:
		var g := brain.explore_goal()
		if g == Vector3.INF:
			continue
		found += 1
		if not MapInfo.contains(g, 4.0):
			outside += 1
			print("  off-map goal %s" % str(g))
	_check(found > 0 and outside == 0, "B4: %d explore goals on an 80 m map, %d outside it" % [found, outside])
	MapInfo.setup(old_x, old_z, old_id, main)
	await _clear()


func _sync_p() -> void:
	fog.update_team(P)
	ChampionSense.for_team(P).refresh()


func _neutral(type_id: String, pos: Vector3) -> Unit:
	return _unit(type_id, int(Unit.Team.NEUTRAL), pos)   # command_stop: idle, no target


# B6: idle camp creatures closer than the enemy that hit an own unit are never the fight target; a creature that
# attacks an own unit still is; hit by an unseen attacker with only idle creatures near -> no fight.
func _phase_b6() -> void:
	fog.enabled = false
	var sense := ChampionSense.for_team(P)
	var at := Vector3(-36.0, 0.0, 20.0)
	var ch := _stub(&"wayfinder", P, at)
	ch.level = 6
	var brain := ch.get_node(^"Brain") as ChampionBrain
	var own := _unit("flame_guard", P, at + Vector3(4.0, 0.0, 0.0))
	var soldier := _unit("shade", E, at + Vector3(6.5, 0.0, 0.0))
	var c1 := _neutral("gloomcap_sprout", at + Vector3(-1.5, 0.0, 1.0))
	var c2 := _neutral("gloomcap_sprout", at + Vector3(-1.5, 0.0, -1.0))
	soldier.set_auto_target(own)
	own.take_damage(1.0, soldier)
	sense.refresh()
	brain.think_now()
	_check(ch.attack_target == soldier, "B6: fights the soldier hitting an ally, not the closer idle creatures (target %s)"
			% str(ch.attack_target))
	await _clear()
	# a creature that attacks an own unit is still a target
	var ch2 := _stub(&"wayfinder", P, at)
	ch2.level = 6
	var brain2 := ch2.get_node(^"Brain") as ChampionBrain
	var own2 := _unit("flame_guard", P, at + Vector3(4.0, 0.0, 0.0))
	var c3 := _neutral("gloomcap_sprout", at + Vector3(6.0, 0.0, 0.0))
	c3.set_auto_target(own2)
	own2.take_damage(1.0, c3)
	sense.refresh()
	brain2.think_now()
	_check(ch2.attack_target == c3, "B6: a creature attacking an own unit is still fought (target %s)" % str(ch2.attack_target))
	await _clear()
	# hit by an unseen attacker: the nearest-enemy fallback skips idle creatures
	var ch3 := _stub(&"wayfinder", P, at)
	ch3.level = 6
	var brain3 := ch3.get_node(^"Brain") as ChampionBrain
	var c4 := _neutral("gloomcap_sprout", at + Vector3(2.0, 0.0, 0.0))
	ch3.take_damage(1.0, null)
	sense.refresh()
	brain3.think_now()
	_check(ch3.attack_target != c4 and brain3._fight_target == null,
			"B6: an unseen hit does not pull the idle creature nearby (target %s)" % str(ch3.attack_target))
	await _clear()
	fog.enabled = true
	await _frames(2)


# B7: a back-line Mender whose only ally is 40 m away fights from range instead of walking to it.
func _phase_b7() -> void:
	fog.enabled = false
	var sense := ChampionSense.for_team(P)
	var at := Vector3(-36.0, 0.0, 20.0)
	var m := _stub(&"mender", P, at)
	m.level = 6
	m.max_hp = 5000.0
	m.hp = 5000.0
	var brain := m.get_node(^"Brain") as ChampionBrain
	var ally := _unit("flame_guard", P, at + Vector3(0.0, 0.0, -40.0))
	ally.set(&"aggro_range", 0.0)
	var soldier := _unit("shade", E, at + Vector3(4.0, 0.0, 0.0))
	soldier.add_modifier(&"test_b7", {"attack_damage_pct": -1.0})
	soldier.set_auto_target(m)
	_check(brain.is_back_line(), "B7: the Mender stub is back line (range %.1f)" % m.attack_range)
	var min_ally_d := INF
	for i in 20:   # ~5 s, a brain tick every 15 frames
		m.take_damage(0.1, soldier)
		sense.refresh()
		brain.think_now()
		await _frames(15)
		min_ally_d = minf(min_ally_d, _flat(m.global_position, ally.global_position))
	_check(min_ally_d > 30.0, "B7: never walks toward the ally 40 m away (closest %.1f m)" % min_ally_d)
	_check(brain._fight_target == soldier and m.attack_target == soldier,
			"B7: ends attacking its fight target (target %s, fight %s)" % [str(m.attack_target), str(brain._fight_target)])
	await _clear()
	fog.enabled = true
	await _frames(2)


# B8: a TRUCE_ALL unit is no enemy for the sense; a unit sharing a truce with the champion is never picked nor attacked.
func _phase_b8() -> void:
	fog.enabled = false
	var sense := ChampionSense.for_team(P)
	var at := Vector3(-36.0, 0.0, 20.0)
	var ch := _stub(&"wayfinder", P, at)
	var brain := ch.get_node(^"Brain") as ChampionBrain
	var peace := _unit("shade", E, at + Vector3(4.0, 0.0, 0.0))
	Unit.set_truce_id(peace, Unit.TRUCE_ALL)
	sense.refresh()
	var listed := false
	for e: Dictionary in sense.enemies:
		if e["node"] == peace:
			listed = true
	_check(not listed, "B8: a TRUCE_ALL unit is not in sense.enemies")
	Unit.set_truce_id(peace, &"")
	peace.queue_free()
	await _frames(2)
	var pact := _unit("shade", E, at + Vector3(3.0, 0.0, 2.0))
	Unit.set_truce_id(pact, &"b8_pact")
	Unit.set_truce_id(ch, &"b8_pact")
	sense.refresh()
	brain.think_now()   # binds the brain to its sense
	var entry: Dictionary = {}
	for e: Dictionary in sense.enemies:
		if e["node"] == pact:
			entry = e
	var picked: Variant = brain._pick_fight_target([entry] if not entry.is_empty() else [], at)
	_check(not entry.is_empty() and picked == null and ch.attack_target != pact,
			"B8: a unit in truce with the champion is seen but never picked (got %s)" % str(picked))
	ch.command_stop()
	brain._order_attack(pact)
	_check(ch.attack_target != pact, "B8: _order_attack sends no command_attack to a truce unit")
	Unit.set_truce_id(pact, &"")
	Unit.set_truce_id(ch, &"")
	await _clear()
	fog.enabled = true
	await _frames(2)


# B3 + B5 through a real AIChampions of the ENEMY.
func _phase_b3_b5() -> void:
	var prof := AIProfile.hard()
	prof.champion_earliest = 0.0
	prof.champion_max = 3
	prof.bounty_max_flags = 3
	prof.bounty_budget_pct = 1.0
	prof.bounty_guard_only = true
	var ca := AIChampions.new(E, P, prof)
	var taverns: Array = Tavern.all()
	if taverns.size() < 2:
		_check(false, "B3: the skirmish has 2 taverns")
		return
	for t: Variant in taverns:
		(t as Tavern).open_time = 0.0
	var wiz := main.wizard_of(E) as Node3D
	var ref: Vector3 = wiz.global_position if wiz else (main.keep_of(E) as Node3D).global_position
	taverns.sort_custom(func(x: Variant, y: Variant) -> bool:
		return _flat((x as Tavern).door_point(), ref) < _flat((y as Tavern).door_point(), ref))
	var near_t := taverns[0] as Tavern
	var far_t := taverns[1] as Tavern
	var holders: Array[Unit] = []
	for t: Tavern in [near_t, far_t]:
		holders.append(_unit("flame_guard", P, t.door_point() + Vector3(1.0, 0.0, 0.0)))
	await _frames(30)
	var reserve := ca.plan(1000.0)
	_check(reserve == 0 and ca.hire_due == &"" and ca.pop_reserve() == 0 and ca.essence_hold() == 0,
			"B3: both taverns held -> no hire due, no reserve (crystals %d, due '%s', pop %d)"
			% [reserve, ca.hire_due, ca.pop_reserve()])
	holders[1].queue_free()
	await _frames(30)
	reserve = ca.plan(1010.0)
	_check(reserve > 0 and ca.hire_due != &"", "B3: one tavern free -> hire due again (crystals %d)" % reserve)
	_check(ca.chosen_tavern(main) == far_t, "B3: chosen_tavern = the free one, not the held nearer one")
	var eco := Economy.for_team(E)
	var bank := EssenceBank.for_team(E)
	eco.crystals = 5000
	bank.essence = 5000
	var own: Array[Building] = []
	ca.tick(1010.0, main, null, fog, 0, 0, own, false, Vector3.INF, false)
	_check(ca.hires.size() == 1, "B3: hires although the tavern nearer the wizard is held (hires %d)" % ca.hires.size())
	# B5: wait for the champion, then a Guard flag of another rule must not block B1.
	var g := ChampionGuild.for_team(E)
	var alive := false
	for i in 600:
		for c: Variant in g.champions:
			if c != null and is_instance_valid(c) and (c as Unit).is_alive():
				alive = true
		if alive:
			break
		await process_frame
	_check(alive, "B5: the hired champion walked out")
	var keep := main.keep_of(E) as Building
	var grid: Variant = main.get(&"build_grid")
	var away := (Vector3.ZERO - keep.global_position)
	away.y = 0.0
	var hovel := (grid as BuildGrid).spawn_complete(BuildingType.find("shadow_hovel"),
			keep.global_position + away.normalized() * 16.0, E)
	_temp.append(hovel)
	await _frames(3)
	var board := BountyBoard.for_team(E)
	bank.essence = 5000
	var other := board.place(Bounty.GUARD, hovel, hovel.global_position, 50)
	_check(other == "", "B5: another rule's Guard flag on the hovel placed ('%s')" % other)
	own = [keep, hovel]
	ca.tick(1011.0, main, null, fog, 0, 0, own, true, keep.global_position + Vector3(2.0, 0.0, 0.0), false)
	_check(board.bounty_on(keep) != null and board.bounty_on(keep).kind == Bounty.GUARD,
			"B5: B1 places its Guard flag on the intruded keep although a Guard flag is up elsewhere")
	var flags_before := ca.flags.size()
	ca.tick(1012.0, main, null, fog, 0, 0, own, true, keep.global_position + Vector3(2.0, 0.0, 0.0), false)
	_check(ca.flags.size() == flags_before, "B5: B1's own flag still blocks a second B1 flag")
	await _clear()
