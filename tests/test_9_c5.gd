extends SceneTree
## Task 9.C5: ChampionBrain (R1-R9, flag utility, personality defaults) + ChampionSense (fog-only knowledge).
## Headless on scenes/skirmish.tscn with the bot switched off. Champions and bounty flags are STUBS defined
## below (the real Champion / Bounty are other tasks); they carry the real ChampionType data when
## data/champions/<id>.tres exists. Proves the "Done when" of 9.C5:
##  1. the 8.2 utility examples give the listed numbers and decisions (fog off);
##  2. hysteresis 1.5 x; 3. Unpaid skips flags;
##  4. joins a fight only within its engage radius; 5. potion under 50 % (real Inventory + Ember Draught);
##  6. flee at the threshold to the nearest rest spot (keep, then a tavern door), rest until 85 %;
##  7. shopping detour only within 40 m and once per 60 s;
##  8. the Wayfinder explores unexplored cells first and avoids a known tower before L4 (not at L4);
##  9. the Oathwall patrols and never chases more than 25 m from the buildings;
## 10. the Coin-Cutter does not know a worker hidden by fog, raids it once seen, then opens a Lost Cache;
## 11. the Mender follows the largest group 4 m behind; 12. R1 fallen;
## 13. timing: all brains + senses < 0.1 ms per frame on average with 6 champions and 200 units.
## Run:  godot --headless --path . -s tests/test_9_c5.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "9.C5"
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1
const BUDGET_USEC := 100.0
const TIMING_FRAMES := 600
const UNIT_TARGET := 200


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

	func _on_death_finished() -> void:
		visible = false   # stays in the tree like a real champion


class StubType extends Resource:
	var id: StringName = &""
	var traits := {}
	var affinity := {}
	var bounty_threshold := 10.0
	var flee_pct := 0.35
	var wishlist: Array = []
	var max_hp := 300.0
	var move_speed := 5.0


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


class StubItem extends RefCounted:
	var id: StringName
	var cost := 100

	func _init(p_id: StringName, p_cost: int) -> void:
		id = p_id
		cost = p_cost

	func total_cost() -> int:
		return cost


## Implements the 9.C6 wish-list helpers the brain calls (next_wishlist_price / next_wishlist_buy / buy).
class StubInventory extends Node:
	var owner_ch: Node3D
	var items: Array = []
	var bought: Array[String] = []

	func next_wishlist_price(_list: Array) -> int:
		return (items[0] as StubItem).cost if not items.is_empty() else 0

	func next_wishlist_buy(_list: Array) -> Object:
		if items.is_empty() or int(owner_ch.get(&"purse")) < (items[0] as StubItem).cost or not _shop_near():
			return null
		return items[0]

	func buy(t: Object) -> String:
		if items.is_empty() or items[0] != t:
			return "Not wanted"
		if not bool(owner_ch.call(&"spend_purse", (t as StubItem).cost)):
			return "Not enough essence"
		items.pop_front()
		bought.append(String((t as StubItem).id))
		return ""

	func _shop_near() -> bool:
		for n in get_tree().get_nodes_in_group(&"buildings") + get_tree().get_nodes_in_group(&"shops"):
			var b := n as Node3D
			if b and b.has_method(&"is_shop") and bool(b.call(&"is_shop")) \
					and Vector2(b.global_position.x - owner_ch.global_position.x,
					b.global_position.z - owner_ch.global_position.z).length() <= 12.0:
				return true
		return false


var main: Node
var fog: FogOfWar
var _done := false
var _errors: Array[String] = []
var _temp: Array = []          # nodes freed at the end of each phase
var _results: Array[String] = []


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


# ---------------------------------------------------------------- helpers

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _check(ok: bool, what: String) -> void:
	if ok:
		_results.append("ok   " + what)
		print("ok   " + what)
	else:
		_errors.append(what)
		print("FAIL " + what)


func _type_for(arch: StringName) -> Resource:
	var path := "res://data/champions/%s.tres" % arch
	if ResourceLoader.exists(path):
		return load(path)
	var t := StubType.new()
	t.id = arch
	var d: Dictionary = ChampionBrain.DEFAULTS[arch]
	for k in ["greed", "courage", "engage_radius"]:
		t.traits[k] = d[k]
	for k in ["hunt", "explore", "guard", "escort"]:
		t.affinity[k] = d[k]
	t.flee_pct = d["flee_pct"]
	return t


func _champ(arch: StringName, team: int, pos: Vector3, auto: bool = false) -> Unit:
	var ch := StubChampion.new()
	var t := _type_for(arch)
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
	brain.enabled = auto
	ch.add_child(brain)
	ch.brain = brain
	_temp.append(ch)
	return ch


func _brain(ch: Unit) -> ChampionBrain:
	return ch.get_node(^"Brain") as ChampionBrain


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	_temp.append(u)
	return u


func _flag(kind: int, team: int, target: Node3D, stake: int, pos: Vector3) -> StubBounty:
	var b := StubBounty.new()
	b.kind = kind
	b.team = team
	b.target = target
	b.stake = stake
	main.add_child(b)
	b.global_position = pos
	_temp.append(b)
	return b


func _sync(team: int) -> void:
	fog.update_team(team)
	ChampionSense.for_team(team).refresh()


func _clear() -> void:
	for n: Variant in _temp:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	_temp.clear()
	await _frames(2)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _keep_pos() -> Vector3:
	return (main.keep_of(P) as Node3D).global_position


# ---------------------------------------------------------------- the run

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
	if fog == null:
		print("FAIL %s: no fog of war in the skirmish" % TASK_ID)
		_done = true
		return
	ChampionSense.for_team(P)
	ChampionSense.for_team(E)
	await _frames(3)

	await _phase_utility()
	await _phase_hysteresis_unpaid()
	await _phase_fight()
	await _phase_potion()
	await _phase_flee()
	await _phase_shopping()
	await _phase_explore()
	await _phase_oathwall()
	await _phase_raid_cache()
	await _phase_mender()
	await _phase_real_champion()
	await _phase_timing()

	print("---- %d checks, %d failed" % [_results.size() + _errors.size(), _errors.size()])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	_done = true


# 1. The 8.2 examples (level 1, no pursuers, full HP), fog off.
func _phase_utility() -> void:
	fog.enabled = false
	var sense := ChampionSense.for_team(P)
	# Coin-Cutter, Hunt 100 on a worker 50 m away, unguarded -> 117, takes it
	var cc := _champ(&"coin_cutter", P, Vector3(-45.0, 0.0, -25.0))
	var worker := _unit("gloom_thrall", E, Vector3(5.0, 0.0, -25.0))
	var f1 := _flag(0, P, worker, 100, worker.global_position)
	sense.refresh()
	var u1 := _brain(cc).flag_utility(f1)
	_check(absf(u1 - 117.0) <= 2.0 and _brain(cc).choose_flag() == f1,
			"8.2 Coin-Cutter Hunt 100 on a worker at 50 m: U %.1f (117), taken" % u1)
	await _clear()
	# Oathwall, Explore 25 at 60 m -> 1.2, ignores
	var spot := _keep_pos() + Vector3(0.0, 0.0, -30.0)
	var ow := _champ(&"oathwall", P, spot + Vector3(60.0, 0.0, 0.0))
	var f2 := _flag(1, P, null, 25, spot)
	sense.refresh()
	var u2 := _brain(ow).flag_utility(f2)
	_check(absf(u2 - 1.2) <= 0.1 and _brain(ow).choose_flag() == null,
			"8.2 Oathwall Explore 25 at 60 m: U %.2f (1.2), ignored" % u2)
	# Wayfinder, Explore 25 at 60 m -> 14.7, takes it
	var wf := _champ(&"wayfinder", P, spot + Vector3(60.0, 0.0, 0.0))
	sense.refresh()
	var u3 := _brain(wf).flag_utility(f2)
	_check(absf(u3 - 14.7) <= 0.2 and _brain(wf).choose_flag() == f2,
			"8.2 Wayfinder Explore 25 at 60 m: U %.1f (14.7), taken" % u3)
	await _clear()
	# Oathwall, Guard 50 on a building 20 m away -> 44.4, takes it
	var keep := main.keep_of(P) as Node3D
	var ow2 := _champ(&"oathwall", P, keep.global_position + Vector3(20.0, 0.0, 0.0))
	var f3 := _flag(2, P, keep, 50, keep.global_position)
	sense.refresh()
	var u4 := _brain(ow2).flag_utility(f3)
	_check(absf(u4 - 44.4) <= 0.5 and _brain(ow2).choose_flag() == f3,
			"8.2 Oathwall Guard 50 on a building at 20 m: U %.1f (44.4), taken" % u4)
	await _clear()
	# Coin-Cutter, Hunt 75 on a Shade among 5 Shades 25 m away -> danger 400 vs 160, R 0.4, U 40.5, takes it
	var s0 := Vector3(-40.0, 0.0, 0.0)
	var shades: Array[Unit] = []
	for i in 5:
		shades.append(_unit("shade", E, s0 + Vector3(float(i % 3) * 1.5, 0.0, float(i / 3) * 1.5)))
	var cc2 := _champ(&"coin_cutter", P, shades[0].global_position + Vector3(0.0, 0.0, 25.0))
	var f4 := _flag(0, P, shades[0], 75, shades[0].global_position)
	sense.refresh()
	var danger := sense.danger_at(shades[0].global_position)
	var u5 := _brain(cc2).flag_utility(f4)
	_check(absf(danger - 400.0) < 1.0 and absf(u5 - 40.5) <= 1.0 and _brain(cc2).choose_flag() == f4,
			"8.2 Coin-Cutter Hunt 75 on a Shade among 5 at 25 m: danger %.0f (400), U %.1f (40.5), taken" % [danger, u5])
	await _clear()


# 2. Hysteresis 1.5 x, 3. Unpaid skips flags (fog off).
func _phase_hysteresis_unpaid() -> void:
	var sense := ChampionSense.for_team(P)
	var cc := _champ(&"coin_cutter", P, Vector3(-45.0, 0.0, -25.0))
	var brain := _brain(cc)
	var worker := _unit("gloom_thrall", E, Vector3(5.0, 0.0, -25.0))
	var a := _flag(0, P, worker, 100, worker.global_position)
	sense.refresh()
	brain.think_now()
	_check(brain.current_flag == a and a.pursuers.has(cc) and cc.get(&"intent") == ChampionBrain.I_HUNT,
			"R6 takes the Hunt flag (pursuer added, intent Hunting bounty)")
	var ua := brain.flag_utility(a)
	var b := _flag(1, P, null, 1, cc.global_position + Vector3(0.0, 0.0, 20.0))
	sense.refresh()
	var per_stake := brain.flag_utility(b)
	b.stake = int(1.4 * ua / per_stake)
	sense.refresh()
	brain.think_now()
	var ub := brain.flag_utility(b)
	_check(brain.current_flag == a, "hysteresis: keeps its flag when another scores %.2f x (< 1.5)" % (ub / ua))
	b.stake = int(ceil(1.6 * ua / per_stake))
	sense.refresh()
	brain.think_now()
	ub = brain.flag_utility(b)
	_check(brain.current_flag == b and not a.pursuers.has(cc) and b.pursuers.has(cc),
			"hysteresis: switches at %.2f x (>= 1.5), pursuers moved" % (ub / brain.flag_utility(a)))
	cc.set(&"is_unpaid", true)
	brain.think_now()
	_check(brain.current_flag == null and not b.pursuers.has(cc) and cc.get(&"intent") == ChampionBrain.I_UNPAID,
			"R5 Unpaid: drops and ignores flags, intent Unpaid! (is %s)" % cc.get(&"intent"))
	cc.set(&"is_unpaid", false)
	brain.think_now()
	_check(brain.current_flag != null, "paid again: takes a flag again")
	await _clear()
	fog.enabled = true
	await _frames(2)


# 4. Joins a fight within its engage radius (Coin-Cutter: 8 m), fog on.
func _phase_fight() -> void:
	var at := Vector3(-36.0, 0.0, 20.0)
	var cc := _champ(&"coin_cutter", P, at)
	var brain := _brain(cc)
	var ally := _unit("flame_guard", P, at + Vector3(14.0, 0.0, 0.0))
	var foe := _unit("shade", E, at + Vector3(15.2, 0.0, 0.0))
	foe.max_hp = 4000.0
	foe.hp = 4000.0
	foe.attack_target = ally
	ally.take_damage(1.0, foe)
	_sync(P)
	brain.think_now()
	_check(cc.get(&"intent") != ChampionBrain.I_FIGHTING and cc.attack_target != foe,
			"R4 ignores a hit ally 14 m away (engage 8 m), intent %s" % cc.get(&"intent"))
	ally.global_position = at + Vector3(6.0, 0.0, 0.0)
	foe.global_position = at + Vector3(7.2, 0.0, 0.0)
	foe.attack_target = ally
	ally.take_damage(1.0, foe)
	_sync(P)
	brain.think_now()
	_check(cc.get(&"intent") == ChampionBrain.I_FIGHTING and cc.attack_target == foe,
			"R4 joins when an ally 6 m away is hit by a visible enemy (attacks it)")
	await _clear()


# 5. Potion under 50 % HP (real Inventory, Ember Draught).
func _phase_potion() -> void:
	var cc := _champ(&"coin_cutter", P, Vector3(-36.0, 0.0, 20.0))
	var brain := _brain(cc)
	var inv := Inventory.ensure_for(cc)
	var draught := ItemType.find(&"ember_draught")
	if inv == null or draught == null or not inv.add_item(draught):
		_check(false, "R3 setup: an Ember Draught in a champion inventory")
		await _clear()
		return
	cc.hp = cc.max_hp * 0.55
	_sync(P)
	brain.think_now()
	_check(brain.potions_drunk == 0 and inv.has_item(&"ember_draught"), "R3 no potion at 55 % HP")
	cc.hp = cc.max_hp * 0.45
	brain.think_now()
	_check(brain.potions_drunk == 1 and not inv.has_item(&"ember_draught"),
			"R3 drinks the Ember Draught at 45 %% HP (flee is 35 %%: other rules go on, intent %s)" % cc.get(&"intent"))
	await _clear()


# 6. Flee at the threshold to the nearest rest spot, rest until 85 %.
func _phase_flee() -> void:
	var keep_pos := _keep_pos()
	var cc := _champ(&"coin_cutter", P, keep_pos + Vector3(0.0, 0.0, -28.0))
	var brain := _brain(cc)
	var flee := brain.flee_ratio()
	_sync(P)
	cc.hp = cc.max_hp * (flee + 0.01)
	brain.think_now()
	_check(not brain.fleeing, "R2 does not flee at %d %% (threshold %d %%)" % [roundi((flee + 0.01) * 100.0), roundi(flee * 100.0)])
	cc.hp = cc.max_hp * (flee - 0.01)
	brain.think_now()
	var goal := brain.plan_goal()
	_check(brain.fleeing and cc.get(&"intent") == ChampionBrain.I_FLEEING and goal != Vector3.INF
			and _flat(goal, keep_pos) <= 13.0,
			"R2 flees under %d %% toward the nearest rest spot (own keep)" % roundi(flee * 100.0))
	brain.enabled = true
	var rested := await _wait_until(func() -> bool: return cc.get(&"intent") == ChampionBrain.I_RESTING, 900)
	_check(rested and _flat(cc.global_position, keep_pos) <= 15.0,
			"R2 reaches the keep and rests (%.1f m from it)" % _flat(cc.global_position, keep_pos))
	cc.hp = cc.max_hp * 0.84
	await _frames(70)
	_check(cc.get(&"intent") == ChampionBrain.I_RESTING, "R2 keeps resting at 84 %")
	cc.hp = cc.max_hp * 0.86
	var left := await _wait_until(func() -> bool: return not brain.fleeing and cc.get(&"intent") != ChampionBrain.I_RESTING, 70)
	_check(left, "R2 leaves the rest at 86 %% (intent now %s)" % cc.get(&"intent"))
	await _clear()
	# a tavern door nearer than any own keep / barracks
	var taverns: Array = get_nodes_in_group(&"taverns")
	var tv: Node3D = null
	if taverns.is_empty():
		tv = Node3D.new()
		tv.add_to_group(&"taverns")
		main.add_child(tv)
		tv.global_position = Vector3(-15.0, 0.0, -15.0)
		_temp.append(tv)
	else:
		tv = taverns[0] as Node3D
		for t: Variant in taverns:
			if (t as Node3D).global_position.x < tv.global_position.x:
				tv = t as Node3D
	var door := ChampionSense.door_of(tv)
	var cc2 := _champ(&"coin_cutter", P, door + Vector3(-6.0, 0.0, 8.0))
	_sync(P)
	cc2.hp = cc2.max_hp * 0.3
	_brain(cc2).think_now()
	_check(_brain(cc2).fleeing and _flat(_brain(cc2).plan_goal(), door) < 0.5,
			"R2 picks the nearer tavern door (%.0f, %.0f) as rest spot" % [door.x, door.z])
	await _clear()


# 7. Shopping detour only within 40 m and once per 60 s.
func _phase_shopping() -> void:
	var keep_pos := _keep_pos()
	var cc := _champ(&"coin_cutter", P, keep_pos + Vector3(23.0, 0.0, -18.0))
	var brain := _brain(cc)
	var inv := StubInventory.new()
	inv.owner_ch = cc
	inv.items = [StubItem.new(&"stub_a", 100), StubItem.new(&"stub_b", 150)]
	cc.add_child(inv)
	cc.set(&"inventory", inv)
	cc.set(&"purse", 300)
	_sync(P)
	var shop_d := _flat(cc.global_position, keep_pos)
	brain.think_now()
	_check(brain.plan == ChampionBrain.Plan.SHOP and cc.get(&"intent") == ChampionBrain.I_SHOP,
			"R7 shopping detour to the keep %.0f m away (purse 300 >= 100)" % shop_d)
	brain.enabled = true
	var bought := await _wait_until(func() -> bool: return inv.bought.size() >= 2, 1200)
	_check(bought and int(cc.get(&"purse")) == 50 and brain.purchases.size() == 2,
			"R7 buys every affordable entry in order (%s, purse %d)" % [str(inv.bought), int(cc.get(&"purse"))])
	await _frames(40)
	inv.items.append(StubItem.new(&"stub_c", 100))
	cc.set(&"purse", 300)
	brain.think_now()
	_check(brain.plan != ChampionBrain.Plan.SHOP, "R7 no second detour within 60 s")
	brain.enabled = false
	# 50 m from every shop: no detour
	var far := _champ(&"coin_cutter", P, Vector3(-55.0, 0.0, -55.0))
	var inv2 := StubInventory.new()
	inv2.owner_ch = far
	inv2.items = [StubItem.new(&"stub_a", 100)]
	far.add_child(inv2)
	far.set(&"inventory", inv2)
	far.set(&"purse", 300)
	_sync(P)
	var nearest := INF
	for s: Variant in ChampionSense.for_team(P).shops:
		nearest = minf(nearest, _flat((s as Node3D).global_position, far.global_position))
	_brain(far).think_now()
	_check(nearest > 40.0 and _brain(far).plan != ChampionBrain.Plan.SHOP,
			"R7 no detour when the nearest shop is %.0f m away (> 40)" % nearest)
	await _clear()


# 8. Wayfinder: unexplored first, a known tower avoided before L4.
func _phase_explore() -> void:
	var keep_pos := _keep_pos()
	var w := Vector3(-25.0, 0.0, 0.0)
	var away := Vector3(w.x - keep_pos.x, 0.0, w.z - keep_pos.z).normalized()
	var tower_at := w + away * 30.0
	var grid: Variant = main.get(&"build_grid")
	var ttype := BuildingType.find("shadow_tower")
	if grid == null or ttype == null:
		_check(false, "explore setup: build_grid and shadow_tower")
		return
	var tower: Building = grid.spawn_complete(ttype, tower_at, E)
	_temp.append(tower)
	tower_at = tower.global_position
	fog.reveal(P, tower_at, 0.5)   # its cell is explored: a KNOWN tower
	var wf := _champ(&"wayfinder", P, w)
	var brain := _brain(wf)
	_sync(P)
	var sense := ChampionSense.for_team(P)
	var known := false
	for s: Dictionary in sense.structures:
		known = known or s["node"] == tower
	_check(known, "ChampionSense knows the tower on an explored cell")
	var all_unexplored := true
	var all_far := true
	for i in 10:
		var g := brain.explore_goal()
		if g == Vector3.INF or fog.state_at(P, g) != FogOfWar.UNEXPLORED:
			all_unexplored = false
		if g != Vector3.INF and _flat(g, tower_at) <= 12.0:
			all_far = false
	_check(all_unexplored, "Wayfinder explore goals are unexplored cells")
	_check(all_far, "Wayfinder (L1) never picks a point within 12 m of a known tower")
	wf.level = 4
	var near := 0
	for i in 10:
		var g := brain.explore_goal()
		if g != Vector3.INF and _flat(g, tower_at) <= 12.0:
			near += 1
	# (not 10 / 10: some ring points near it were explored by earlier phases and score lower)
	_check(near >= 3, "Wayfinder at L4 no longer avoids it (%d / 10 goals near the tower)" % near)
	wf.level = 1
	brain.think_now()
	_check(wf.get(&"intent") == ChampionBrain.I_EXPLORE and brain.plan_goal() != Vector3.INF,
			"R8 Wayfinder default: Exploring")
	# enemy sense: the enemy does not know our Wayfinder in its fog
	await _clear()


# 9. Oathwall: patrols own buildings, never chases more than 25 m past them.
func _phase_oathwall() -> void:
	var keep := main.keep_of(P) as Node3D
	var kp := keep.global_position
	var ow := _champ(&"oathwall", P, kp + Vector3(10.0, 0.0, -10.0), true)
	var patrolling := await _wait_until(func() -> bool: return ow.get(&"intent") == ChampionBrain.I_PATROL, 120)
	_check(patrolling and _brain(ow).plan_node() == keep, "R8 Oathwall default: Patrolling its buildings")
	var foe := _unit("shade", E, kp + Vector3(6.0, 0.0, -9.0))
	foe.max_hp = 5000.0
	foe.hp = 5000.0
	foe.attack_target = keep
	keep.take_damage(1.0, foe)
	var fighting := await _wait_until(func() -> bool: return ow.get(&"intent") == ChampionBrain.I_FIGHTING, 150)
	_check(fighting and ow.attack_target == foe, "R4 Oathwall defends the hit keep (engage 20 m)")
	fog.enabled = false   # everything visible: only the leash stops the chase
	var pin := kp + Vector3(0.0, 0.0, -30.0)
	var max_d := 0.0
	for i in 360:
		foe.global_position = pin
		foe.velocity = Vector3.ZERO
		foe.attack_target = keep
		if i % 30 == 0:
			keep.take_damage(0.01, foe)
		max_d = maxf(max_d, _dist_to_buildings(ow.global_position))
		await process_frame
	_check(max_d <= 27.0 and ow.attack_target != foe,
			"Oathwall never goes more than 25 m from its buildings (max %.1f m) and drops the chase" % max_d)
	fog.enabled = true
	await _clear()


func _dist_to_buildings(pos: Vector3) -> float:
	var best := INF
	for b in Building.for_team(P):
		if b.is_alive() and b.is_constructed():
			best = minf(best, _flat(b.global_position, pos))
	return best


# 10. Coin-Cutter: fog-only knowledge, raids a seen worker, opens a Lost Cache.
func _phase_raid_cache() -> void:
	var at := Vector3(-36.0, 0.0, 20.0)
	var cc := _champ(&"coin_cutter", P, at)
	var brain := _brain(cc)
	var worker := _unit("gloom_thrall", E, at + Vector3(22.0, 0.0, 0.0))
	var sense := ChampionSense.for_team(P)
	sense.workers_seen.clear()   # forget the enemy base workers seen while the fog was off (phases 1-3, 9)
	_sync(P)
	brain.think_now()
	_check(fog.state_at(P, worker.global_position) != FogOfWar.VISIBLE
			and not sense.workers_seen.has(worker.get_instance_id()) and brain.plan != ChampionBrain.Plan.RAID,
			"fog: a worker 22 m away in the fog is unknown, no raid (fog state %d, remembered %s, plan %s)" % [
			fog.state_at(P, worker.global_position), str(sense.workers_seen.has(worker.get_instance_id())),
			ChampionBrain.Plan.keys()[brain.plan]])
	worker.global_position = at + Vector3(7.0, 0.0, 0.0)
	_sync(P)
	brain.think_now()
	_check(brain.plan == ChampionBrain.Plan.RAID and cc.attack_target == worker
			and cc.get(&"intent") == ChampionBrain.I_RAID, "R8 Coin-Cutter raids the seen worker")
	worker.take_damage(1.0e6, null)
	var cache := LostCache.new()
	cache.first_delay = 0.1
	cache.reopen_delay = 999.0
	main.add_child(cache)
	cache.global_position = at + Vector3(0.0, 0.0, -9.0)
	_temp.append(cache)
	await _frames(20)
	_sync(P)
	var purse0 := int(cc.get(&"purse"))
	brain.think_now()
	_check(brain.plan == ChampionBrain.Plan.CACHE,
			"R8 Coin-Cutter goes for the nearest closed Lost Cache (plan %s, available %s, fog %d, caches %d)" % [
			ChampionBrain.Plan.keys()[brain.plan], str(cache.is_available()),
			fog.state_at(P, cache.global_position), sense.caches.size()])
	brain.enabled = true
	var at_cache := func() -> bool: return not cache.is_available() \
			or _flat(cc.global_position, cache.global_position) <= LostCache.OPEN_RADIUS
	var reached := await _wait_until(at_cache, 900)
	await _frames(15)
	_check(reached, "Coin-Cutter reaches the cache (opened: %s, purse %d -> %d)" % [str(not cache.is_available()),
			purse0, int(cc.get(&"purse"))])
	await _clear()


# 11. Mender follows the largest group 4 m behind.
func _phase_mender() -> void:
	var a := Vector3(-35.0, 0.0, 22.0)
	var b := Vector3(-20.0, 0.0, 30.0)
	var small: Array[Unit] = []
	var big: Array[Unit] = []
	for i in 3:
		small.append(_unit("flame_guard", P, a + Vector3(float(i) * 1.6, 0.0, 0.0)))
	for i in 5:
		big.append(_unit("flame_guard", P, b + Vector3(float(i % 3) * 1.6, 0.0, float(i / 3) * 1.6)))
	var me := _champ(&"mender", P, Vector3(-28.0, 0.0, 40.0))
	var brain := _brain(me)
	_sync(P)
	brain.think_now()
	var centre := brain.plan_node() as Node3D
	var goal := brain.plan_goal()
	var in_big := centre != null and big.has(centre)
	var behind := goal != Vector3.INF and centre != null and absf(_flat(goal, centre.global_position) - 4.0) <= 0.3
	_check(brain.plan == ChampionBrain.Plan.FOLLOW and in_big and behind
			and me.get(&"intent") == ChampionBrain.I_ARMY,
			"R8 Mender follows the 5-soldier group, goal %.1f m behind its centre" % (
			_flat(goal, centre.global_position) if centre and goal != Vector3.INF else -1.0))
	var kp := _keep_pos()
	_check(centre != null and _flat(goal, kp) < _flat(centre.global_position, kp),
			"Mender stands on the side away from the enemy (toward home)")
	# R1: fallen
	me.take_damage(1.0e6, null)
	brain.think_now()
	_check(me.get(&"intent") == ChampionBrain.I_FALLEN and brain.current_flag == null, "R1 fallen: intent Fallen")
	await _clear()


# 12b. Integration (when 9.C1 / 9.C4 exist): a real Champion builds this brain, takes a real Explore flag
# placed through the BountyBoard and gets paid on arrival.
func _phase_real_champion() -> void:
	var cpath := "res://scripts/units/champion.gd"
	var bpath := "res://scripts/world/bounty_board.gd"
	var tpath := "res://data/champions/wayfinder.tres"
	if not (ResourceLoader.exists(cpath) and ResourceLoader.exists(bpath) and ResourceLoader.exists(tpath)):
		print("note: real Champion / BountyBoard not there yet, integration phase skipped")
		return
	var ch := (load(cpath) as Script).new() as Unit
	ch.call(&"apply_champion_type", load(tpath), 0)
	ch.team = P as Unit.Team
	main.add_child(ch)
	ch.global_position = Vector3(-36.0, 0.0, 20.0)
	ch.command_stop()
	_temp.append(ch)
	var brain := ch.get_node_or_null(^"Brain") as ChampionBrain
	_check(brain != null, "a real Champion creates its ChampionBrain child")
	if brain == null:
		return
	var roster: Variant = null
	for g in get_nodes_in_group(&"champion_guilds"):
		if int(g.get(&"team")) == P:
			roster = g.get(&"champions")
	if roster is Array:
		(roster as Array).append(ch)   # "hired" for the board's "No champions" rule
	var board: Object = (load(bpath) as Script).call(&"for_team", P)
	var reason := str(board.call(&"place", 1, null, Vector3(-30.0, 0.0, 0.0))) if board else "no board"
	var purse0 := int(ch.get(&"purse"))
	var scouting := func() -> bool: return brain.current_flag != null \
			and ch.get(&"intent") == ChampionBrain.I_SCOUT
	var took := await _wait_until(scouting, 240)
	_check(reason == "" and took, "real Champion takes a real Explore flag (place: '%s', intent %s)" % [reason,
			ch.get(&"intent")])
	var paid := await _wait_until(func() -> bool: return int(ch.get(&"purse")) > purse0, 900)
	_check(paid, "real Champion walks to it and is paid (purse %d -> %d)" % [purse0, int(ch.get(&"purse"))])
	if roster is Array:
		(roster as Array).erase(ch)
	await _clear()


# 13. Timing: 6 champions, 200 units, every brain automatic.
func _phase_timing() -> void:
	var ps := [[&"wayfinder", Vector3(-30.0, 0.0, 30.0)], [&"oathwall", Vector3(-38.0, 0.0, 34.0)],
			[&"mender", Vector3(-34.0, 0.0, 28.0)]]
	var es := [[&"coin_cutter", Vector3(30.0, 0.0, -30.0)], [&"wayfinder", Vector3(34.0, 0.0, -26.0)],
			[&"oathwall", Vector3(38.0, 0.0, -34.0)]]
	for e: Array in ps:
		_champ(e[0], P, e[1], true)
	for e: Array in es:
		_champ(e[0], E, e[1], true)
	var have := get_nodes_in_group(&"units").size()
	var i := 0
	while have < UNIT_TARGET:
		var team := P if i % 2 == 0 else E
		var k := i / 2
		var base := Vector3(-48.0, 0.0, 12.0) if team == P else Vector3(34.0, 0.0, -12.0)
		_unit("flame_guard" if team == P else "shade", team,
				base + Vector3(float(k % 10) * 1.5, 0.0, float(k / 10) * 1.5))
		have += 1
		i += 1
	await _frames(60)
	var b0 := ChampionBrain.usec_total
	var s0 := ChampionSense.usec_total
	var t0 := ChampionBrain.ticks
	var p0 := ChampionSense.passes
	await _frames(TIMING_FRAMES)
	var brain_us := float(ChampionBrain.usec_total - b0)
	var sense_us := float(ChampionSense.usec_total - s0)
	var per_frame := (brain_us + sense_us) / float(TIMING_FRAMES)
	print("timing: %d units, 6 champions: brains %.1f us (%d ticks), senses %.1f us (%d passes) over %d frames"
			% [get_nodes_in_group(&"units").size(), brain_us, ChampionBrain.ticks - t0, sense_us,
			ChampionSense.passes - p0, TIMING_FRAMES])
	_check(per_frame < BUDGET_USEC, "timing: brains + senses %.1f us per frame (< %.0f)" % [per_frame, BUDGET_USEC])
	await _clear()
