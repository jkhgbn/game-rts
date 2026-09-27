extends SceneTree
## Task 10.C12: ChampionGuild gold payment (docs/design/market-trade.md 3.2, section 12 ChampionGuild bullet).
## - hire_cost(id, true) = {crystals 0, essence n-th, gold n-th crystals}; hire(id, true) spends gold + essence,
##   never crystals; "Not enough gold" sits where "Not enough crystals" does in the refusal order.
## - revive_cost(ch, true) = 2 x the essence price (step 11: L1 230, L2 300, L6 580); revive(ch, true) spends gold only.
## - Without a GoldBank (trade off) every gold payment is refused; defaults stay the crystal / essence behaviour.
## Prices are the step-11 ones (skills-rework.md 9.2): hire 225+75 / 275+100 / 325+125, revive 80 + 35 x level.
## GoldBank (10.C11) may not exist yet: StubGoldBank below joins the group "gold_banks" (the guild's lookup).
## Champions are stubs, like test_9_c3.
## Run:  godot --headless --path . -s tests/test_10_c12.gd --fixed-fps 60 --quit-after 7000

const TASK_ID := "10.C12"
const TIMEOUT_FRAMES := 6800
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1


class StubType extends Resource:
	var id: StringName = &""
	var names := PackedStringArray()


class StubChampion extends Unit:
	var champion_type: Resource
	var variant := 0
	var display_name := ""
	var purse := 0
	var is_unpaid := false

	func setup(type: Resource, v: int) -> void:
		champion_type = type
		variant = v
		var ut := UnitType.new()
		ut.pop = 2
		ut.id = StringName(type.get(&"id"))
		unit_type = ut

	func _ready() -> void:
		display_name = String(champion_type.get(&"id")).capitalize()
		unit_name = display_name
		add_to_group("champions")
		super()

	func respawn(at: Vector3) -> void:
		_revive(at)

	func _on_death_finished() -> void:
		visible = false


## The frozen GoldBank API the guild uses (team, can_afford, spend) + the test's bookkeeping.
class StubGoldBank extends Node:
	var team := 0
	var gold := 0
	var spends: Array[int] = []

	func can_afford(n: int) -> bool:
		return gold >= n

	func spend(n: int) -> bool:
		if n < 0 or gold < n:
			return false
		gold -= n
		spends.append(n)
		return true

	func add(n: int, _source: StringName = &"") -> void:
		gold = maxi(0, gold + n)


var main: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _types := {}


func _initialize() -> void:
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func _finish() -> bool:
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


func _stub_type(id: StringName) -> Resource:
	if not _types.has(id):
		var t := StubType.new()
		t.id = id
		t.names = PackedStringArray([String(id) + " A", String(id) + " B"])
		_types[id] = t
	return _types[id]


func _run() -> void:
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking")
		_finish()
		return
	await _frames(10)
	var gp: ChampionGuild = ChampionGuild.for_team(P)
	var ge: ChampionGuild = ChampionGuild.for_team(E)
	_check(gp != null and ge != null, "one ChampionGuild per team")
	if gp == null or ge == null:
		_finish()
		return
	for g: ChampionGuild in [gp, ge]:
		g.champion_script = StubChampion
		g.type_lookup = _stub_type
	# Any real GoldBank (once 10.C11 / the level glue land) leaves the group: the stubs are the only banks.
	for n in root.get_tree().get_nodes_in_group("gold_banks"):
		n.remove_from_group("gold_banks")
	for team in [P, E]:
		Economy.for_team(team).crystals = 5000
		var bank := EssenceBank.for_team(team)
		bank.trickle_enabled = false
		bank.essence = 5000
	main.set("_match_time", 119.8)
	await _frames(30)
	_check(gp.is_open(), "taverns open after 2:00")

	await _costs(gp)
	await _no_gold_bank(gp)
	var gb := _add_gold_bank(P, 0)
	_add_gold_bank(E, 99999)   # another team's bank never pays for the player
	await _hire_refusals(gp, gb)
	await _hires(gp, gb)
	await _revives(gp, gb)
	_finish()


func _add_gold_bank(team: int, gold: int) -> StubGoldBank:
	var gb := StubGoldBank.new()
	gb.team = team
	gb.gold = gold
	gb.name = "StubGoldBank%d" % team
	gb.add_to_group("gold_banks")
	main.add_child(gb)
	return gb


## hire_cost with and without gold, for the 1st price; defaults unchanged.
func _costs(gp: ChampionGuild) -> void:
	var c := gp.hire_cost(&"wayfinder")
	_check(int(c["crystals"]) == 225 and int(c["essence"]) == 75 and int(c.get("gold", -1)) == 0,
			"default hire_cost = 225 crystals + 75 essence, 0 gold (%s)" % c)
	var g := gp.hire_cost(&"wayfinder", true)
	_check(int(g["crystals"]) == 0 and int(g["essence"]) == 75 and int(g["gold"]) == 225,
			"gold hire_cost = 225 gold + 75 essence, 0 crystals (%s)" % g)
	var n := gp.next_hire_cost()
	_check(int(n["crystals"]) == 225 and int(n["essence"]) == 75, "next_hire_cost unchanged (%s)" % n)
	_check(ChampionGuild.R_GOLD == "Not enough gold", "R_GOLD text")


## Trade off (no GoldBank): gold payments are refused, the crystal payment still works.
func _no_gold_bank(gp: ChampionGuild) -> void:
	_check(gp.gold_bank_of_team() == null, "no gold bank yet")
	_check(gp.can_hire(&"wayfinder", true) == "Not enough gold", "no bank: Not enough gold (got '%s')" % gp.can_hire(&"wayfinder", true))
	var c0: int = Economy.for_team(P).crystals
	_check(gp.hire(&"wayfinder", true) == "Not enough gold" and Economy.for_team(P).crystals == c0 and gp.roster_size() == 0,
			"no bank: gold hire refused, nothing paid")
	_check(gp.can_hire(&"wayfinder") == "", "no bank: the crystal hire is still fine (got '%s')" % gp.can_hire(&"wayfinder"))


## Refusal order with gold: ... Population, Not enough gold (in place of crystals), Not enough essence, held.
func _hire_refusals(gp: ChampionGuild, gb: StubGoldBank) -> void:
	_check(gp.gold_bank_of_team() == gb, "the guild finds its own team's bank")
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	var fill: int = eco.pop_cap - eco.pop_used - 1
	if fill > 0:
		eco.reserve_pop(fill)
	eco.crystals = 0
	bank.essence = 0
	gb.gold = 0
	_check(gp.can_hire(&"oathwall", true) == "Population cap reached", "gold: Population first (got '%s')" % gp.can_hire(&"oathwall", true))
	if fill > 0:
		eco.release_pop(fill)
	_check(gp.can_hire(&"oathwall", true) == "Not enough gold", "gold: Not enough gold (got '%s')" % gp.can_hire(&"oathwall", true))
	_check(gp.can_hire(&"oathwall") == "Not enough crystals", "crystals: Not enough crystals (got '%s')" % gp.can_hire(&"oathwall"))
	gb.gold = 224
	_check(gp.can_hire(&"oathwall", true) == "Not enough gold", "224 gold is not enough")
	gb.gold = 225
	_check(gp.can_hire(&"oathwall", true) == "Not enough essence", "gold ok, 0 crystals: Not enough essence (got '%s')" % gp.can_hire(&"oathwall", true))
	_check(gp.can_hire(&"oathwall") == "Not enough crystals", "the crystal path ignores gold")
	bank.essence = 75
	_check(gp.can_hire(&"oathwall", true) == "", "225 gold + 75 essence, 0 crystals: hire ok (got '%s')" % gp.can_hire(&"oathwall", true))
	# A refused hire pays nothing.
	bank.essence = 74
	_check(gp.hire(&"oathwall", true) == "Not enough essence" and gb.gold == 225 and gb.spends.is_empty(),
			"refused gold hire pays nothing")


## Two gold hires (225 / 275 gold + essence, crystals untouched) and one crystal hire (gold untouched).
func _hires(gp: ChampionGuild, gb: StubGoldBank) -> void:
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	eco.crystals = 1000
	bank.essence = 1000
	gb.gold = 1000
	var rows := [[&"oathwall", true, 225, 75], [&"mender", true, 275, 100], [&"coin_cutter", false, 325, 125]]
	for row in rows:
		var c0 := eco.crystals
		var e0 := bank.essence
		var g0 := gb.gold
		var p0 := eco.pop_used
		var cost := gp.hire_cost(row[0], row[1])
		var r := gp.hire(row[0], row[1])
		_check(r == "", "hire %s gold=%s (got '%s')" % [row[0], row[1], r])
		if row[1]:
			_check(int(cost["gold"]) == row[2] and int(cost["crystals"]) == 0, "%s gold price %s" % [row[0], cost])
			_check(gb.gold == g0 - row[2] and eco.crystals == c0 and bank.essence == e0 - row[3],
					"%s paid %d gold + %d essence, no crystals (gold %d, crystals %d, essence %d)"
					% [row[0], row[2], row[3], gb.gold, eco.crystals, bank.essence])
		else:
			_check(int(cost["crystals"]) == row[2] and int(cost["gold"]) == 0, "%s crystal price %s" % [row[0], cost])
			_check(eco.crystals == c0 - row[2] and bank.essence == e0 - row[3] and gb.gold == g0,
					"%s paid %d crystals + %d essence, no gold" % [row[0], row[2], row[3]])
		_check(eco.pop_used == p0 + 2, "%s takes pop 2 (%d -> %d)" % [row[0], p0, eco.pop_used])
	_check(gp.can_hire(&"wayfinder", true) == "Max 3 champions", "Max 3 still first with gold")
	await _until(func() -> bool: return gp.champions.size() == 3, 260)
	_check(gp.champions.size() == 3, "3 champions out after 3 s")
	var i := 0
	for ch: Node3D in gp.champions:
		ch.global_position = Vector3(-44 + i * 2.0, 0, 20)
		if ch.has_method("command_stop"):
			ch.call("command_stop")
		i += 1


## Revive in gold: 2 gold per essence, refusals, only gold spent; the default revive still spends essence.
func _revives(gp: ChampionGuild, gb: StubGoldBank) -> void:
	var bank := EssenceBank.for_team(P)
	var ch: Unit = gp.champion_of(&"oathwall")
	var other: Unit = gp.champion_of(&"mender")
	if ch == null or other == null:
		_check(false, "hired champions missing")
		return
	for lv in [[1, 115, 230], [4, 220, 440], [6, 290, 580], [2, 150, 300]]:
		ch.level = lv[0]
		_check(gp.revive_cost(ch) == lv[1] and gp.revive_cost(ch, true) == lv[2],
				"L%d revive = %d essence / %d gold (%d / %d)" % [lv[0], lv[1], lv[2], gp.revive_cost(ch), gp.revive_cost(ch, true)])
	_check(gp.can_revive(ch, true) == "Not fallen", "gold: Not fallen first")
	ch.take_damage(99999.0, null)
	other.take_damage(99999.0, null)
	await _frames(5)
	_check(gp.is_fallen(ch) and gp.is_fallen(other), "both fallen")
	gb.gold = 299
	bank.essence = 0
	_check(gp.can_revive(ch, true) == "Not enough gold", "299 gold: Not enough gold (got '%s')" % gp.can_revive(ch, true))
	_check(gp.can_revive(ch) == "Not enough essence", "default: Not enough essence")
	gb.gold = 300
	_check(gp.can_revive(ch, true) == "", "300 gold, 0 essence: revive ok (got '%s')" % gp.can_revive(ch, true))
	var r := gp.revive(ch, true)
	_check(r == "" and gb.gold == 0 and bank.essence == 0, "gold revive paid 300 gold, no essence ('%s', gold %d, essence %d)" % [r, gb.gold, bank.essence])
	_check(gp.is_reviving(ch) and absf(gp.revive_time_left(ch) - 25.0) < 0.1, "reviving, 25 s")
	_check(gp.can_revive(ch, true) == "Already reviving", "gold: Already reviving")
	# Default revive of the Mender (L1): 115 essence, gold untouched.
	gb.gold = 500
	bank.essence = 1000
	_check(gp.revive(other) == "" and bank.essence == 885 and gb.gold == 500, "default revive spends 115 essence only")
	# Trade off: a gold revive is refused.
	var third: Unit = gp.champion_of(&"coin_cutter")
	third.take_damage(99999.0, null)
	await _frames(5)
	gb.remove_from_group("gold_banks")
	_check(gp.can_revive(third, true) == "Not enough gold" and gp.revive(third, true) == "Not enough gold" and gb.gold == 500,
			"no bank: gold revive refused, nothing paid")
	gb.add_to_group("gold_banks")
	# The gold revive brings the champion back like an essence one.
	await _until(func() -> bool: return ch.is_alive(), 1560)
	_check(ch.is_alive(), "gold-revived champion back after 25 s")
