extends SceneTree
## Task 11.C3: step-11 champion prices and the campaign companion's class (docs/design/skills-rework.md 8, 9.2,
## 10 ChampionGuild / Campaign, "Done when" 11.C3).
## - Hire 225+75 / 275+100 / 325+125 crystals + essence (gold path: 225 / 275 / 325 gold + the same essence).
## - Revive 80 + 35 x level essence (L1 115, L4 220, L6 290; gold 2 per essence) after 15 + 5 x level s.
## - CampaignState: the companion entry gains "class" when the champion has one; a loaded class is re-applied
##   through `set_champion_class` (ChampionGuild.add_companion) at level 1; an old save without it loads unchanged
##   and the companion has no class (it draws at level 2).
## Champions are stubs (11.C1 may not have landed): StubChampion has the frozen class API (class_id,
## set_champion_class, class_chosen) and a stand-in draw at level 2. When the real Champion already has
## `set_champion_class`, a last section runs the companion checks with it (class kept at level 1, class skills
## locked, old save draws at level 2); otherwise it prints SKIP.
## Run:  godot --headless --path . -s tests/test_11_c3.gd --fixed-fps 60 --quit-after 7000

const TASK_ID := "11.C3"
const TIMEOUT_FRAMES := 6800
const SCENE := "res://scenes/skirmish.tscn"
const TEST_SAVE := "user://test_11_c3_campaign.json"
const CHAMPION_PATH := "res://scripts/units/champion.gd"
const CLASS_PATH := "res://scripts/units/champion_class.gd"
const P := 0
const E := 1


class StubType extends Resource:
	var id: StringName = &""
	var names := PackedStringArray()


class StubInventory extends RefCounted:
	var slots: Array = [null, null, null, null]

	func add_item(type: Resource, count: int = 1, _cooldown_left: float = 0.0) -> bool:
		for i in slots.size():
			if slots[i] == null:
				slots[i] = {"type": type, "count": count, "cooldown_left": 0.0}
				return true
		return false

	func total_item_value() -> int:
		return 0


## The guild's Champion contract + the step-11 class API (skills-rework.md 10).
class StubChampion extends Unit:
	signal class_chosen(champion: Node, class_id: StringName)
	var champion_type: Resource
	var variant := 0
	var display_name := ""
	var purse := 0
	var is_unpaid := false
	var inventory: Object
	var class_calls: Array = []
	var _class: StringName = &""

	func setup(type: Resource, v: int) -> void:
		champion_type = type
		variant = v
		inventory = StubInventory.new()
		var ut := UnitType.new()
		ut.pop = 2
		ut.id = StringName(type.get(&"id"))
		unit_type = ut

	func _ready() -> void:
		display_name = String(champion_type.get(&"id")).capitalize()
		unit_name = display_name
		add_to_group("champions")
		super()

	func class_id() -> StringName:
		return _class

	func set_champion_class(id: StringName) -> void:
		class_calls.append(StringName(id))
		_class = StringName(id)

	## Stand-in for 11.C1's draw: at level 2, only when no class yet.
	func stub_level_up_to(l: int) -> void:
		level = l
		if level >= 2 and _class == &"":
			_class = &"sword_shield"
			class_chosen.emit(self, _class)

	func add_purse(n: int) -> void:
		purse += n

	func spend_purse(n: int) -> bool:
		if n > purse:
			return false
		purse -= n
		return true

	func respawn(at: Vector3) -> void:
		_revive(at)

	func _on_death_finished() -> void:
		visible = false


class StubGoldBank extends Node:
	var team := 0
	var gold := 0

	func can_afford(n: int) -> bool:
		return gold >= n

	func spend(n: int) -> bool:
		if n < 0 or gold < n:
			return false
		gold -= n
		return true


var main: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _types := {}
var _revived: Array = []
var _hired_class: Array = []   # class_id() of each champion when champion_hired fires


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
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
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


func _stub_type(id: StringName) -> Resource:
	if not _types.has(id):
		var t := StubType.new()
		t.id = id
		t.names = PackedStringArray([String(id) + " A", String(id) + " B"])
		_types[id] = t
	return _types[id]


func _class_of(ch: Node) -> StringName:
	return StringName(ch.call(&"class_id")) if ch.has_method(&"class_id") else &""


func _use_stubs(g: ChampionGuild) -> void:
	g.champion_script = StubChampion
	g.type_lookup = _stub_type


# ---------------------------------------------------------------- the run

func _run() -> void:
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking")
		_finish()
		return
	await _frames(10)
	var gp: ChampionGuild = ChampionGuild.for_team(P)
	_check(gp != null, "a player ChampionGuild")
	if gp == null:
		_finish()
		return
	_use_stubs(gp)
	gp.champion_revived.connect(func(ch: Node) -> void: _revived.append([total, ch]))
	gp.champion_hired.connect(func(ch: Node) -> void: _hired_class.append(_class_of(ch)))
	for n in root.get_tree().get_nodes_in_group("gold_banks"):
		n.remove_from_group("gold_banks")
	var gb := StubGoldBank.new()
	gb.team = P
	gb.add_to_group("gold_banks")
	main.add_child(gb)
	for team in [P, E]:
		Economy.for_team(team).crystals = 5000
		var bank := EssenceBank.for_team(team)
		bank.trickle_enabled = false
		bank.essence = 5000
	main.set("_match_time", 119.8)
	await _frames(30)
	_check(gp.is_open(), "taverns open after 2:00")

	_constants()
	await _hires(gp, gb)
	await _revive(gp, gb)
	await _companion_with_class(gp)
	await _old_save(gp)
	_clean_values()
	await _real_champion(gp)
	_finish()


## The numbers of skills-rework.md 9.2 in the guild's constants.
func _constants() -> void:
	var want := [[225, 75], [275, 100], [325, 125]]
	for i in 3:
		var c: Dictionary = ChampionGuild.HIRE_COSTS[i]
		_check(int(c["crystals"]) == want[i][0] and int(c["essence"]) == want[i][1], "HIRE_COSTS[%d] = %s" % [i, c])
	_check(ChampionGuild.REVIVE_BASE_COST == 80 and ChampionGuild.REVIVE_COST_PER_LEVEL == 35, "revive 80 + 35 x level")
	_check(ChampionGuild.REVIVE_BASE_TIME == 15.0 and ChampionGuild.REVIVE_TIME_PER_LEVEL == 5.0, "revive time unchanged")


## Three hires at the new prices (1st and 3rd with crystals, 2nd with gold: 275 gold + 100 essence).
func _hires(gp: ChampionGuild, gb: StubGoldBank) -> void:
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	gb.gold = 1000
	var g1 := gp.hire_cost(&"oathwall", true)
	_check(int(g1["gold"]) == 225 and int(g1["crystals"]) == 0 and int(g1["essence"]) == 75, "1st gold price %s" % g1)
	var rows := [[&"oathwall", false, 225, 75], [&"mender", true, 275, 100], [&"coin_cutter", false, 325, 125]]
	for row in rows:
		var c0 := eco.crystals
		var e0 := bank.essence
		var g0 := gb.gold
		var cost := gp.hire_cost(row[0], row[1])
		var r := gp.hire(row[0], row[1])
		_check(r == "", "hire %s (got '%s')" % [row[0], r])
		if row[1]:
			_check(int(cost["gold"]) == row[2] and gb.gold == g0 - row[2] and eco.crystals == c0 and bank.essence == e0 - row[3],
					"%s paid %d gold + %d essence (%s)" % [row[0], row[2], row[3], cost])
		else:
			_check(int(cost["crystals"]) == row[2] and int(cost["essence"]) == row[3], "hire_cost %s = %s" % [row[0], cost])
			_check(eco.crystals == c0 - row[2] and bank.essence == e0 - row[3] and gb.gold == g0,
					"%s paid %d crystals + %d essence" % [row[0], row[2], row[3]])
	_check(int(gp.hire_cost(&"wayfinder", true)["gold"]) == 325, "full roster: 3rd gold price 325")
	await _until(func() -> bool: return gp.champions.size() == 3, 260)
	_check(gp.champions.size() == 3, "3 champions out")
	var i := 0
	for ch: Node3D in gp.champions:
		ch.global_position = Vector3(-44 + i * 2.0, 0, 20)
		ch.call("command_stop")
		i += 1
	_check(_hired_class == [&"", &"", &""], "a hired champion has no class (%s)" % str(_hired_class))


## Revive 80 + 35 x level: L1 115, L4 220, L6 290 (gold x2); a level-4 revive takes 35 s.
func _revive(gp: ChampionGuild, gb: StubGoldBank) -> void:
	var bank := EssenceBank.for_team(P)
	var ch: Unit = gp.champion_of(&"oathwall")
	for lv in [[1, 115], [2, 150], [3, 185], [4, 220], [5, 255], [6, 290]]:
		ch.level = lv[0]
		_check(gp.revive_cost(ch) == lv[1] and gp.revive_cost(ch, true) == 2 * lv[1],
				"L%d revive = %d essence / %d gold (%d / %d)" % [lv[0], lv[1], 2 * lv[1], gp.revive_cost(ch), gp.revive_cost(ch, true)])
	ch.level = 4
	ch.take_damage(99999.0, null)
	await _frames(5)
	_check(gp.is_fallen(ch), "fallen")
	bank.essence = 219
	_check(gp.can_revive(ch) == "Not enough essence", "219 essence: Not enough essence (got '%s')" % gp.can_revive(ch))
	gb.gold = 439
	_check(gp.can_revive(ch, true) == "Not enough gold", "439 gold: Not enough gold (got '%s')" % gp.can_revive(ch, true))
	bank.essence = 220
	_check(absf(gp.revive_duration(ch) - 35.0) < 0.01, "L4 revive takes 35 s")
	var r := gp.revive(ch)
	var start := total
	_check(r == "" and bank.essence == 0 and gb.gold == 439, "L4 revive paid 220 essence ('%s', %d)" % [r, bank.essence])
	await _frames(2080)
	_check(not ch.is_alive(), "still fallen before 35 s")
	await _until(func() -> bool: return ch.is_alive(), 40)
	_check(ch.is_alive(), "back after 35 s")
	if not _revived.is_empty():
		_check(absi(int(_revived[0][0]) - start - 2100) <= 3, "revive took 35 s (%d frames)" % (int(_revived[0][0]) - start))
	ch.global_position = Vector3(-44, 0, 22)
	ch.call("command_stop")
	bank.essence = 5000


## A companion with a class: saved with "class", reloaded, restored at level 1 with set_champion_class.
func _companion_with_class(gp: ChampionGuild) -> void:
	var cc: Node = gp.champion_of(&"coin_cutter")
	var ow: Node = gp.champion_of(&"oathwall")
	cc.call(&"set_champion_class", &"two_hand")
	cc.set("level", 3)
	cc.set("purse", 200)
	# No class yet: no key (the entry stays the step-9 shape).
	var plain := CampaignState.companion_snapshot(ow)
	_check(not plain.has("class") and plain.size() == 4, "no class: no \"class\" key (%s)" % plain)
	_check(CampaignState.companion_class_of(ow) == "" and CampaignState.companion_class_of(cc) == "two_hand",
			"companion_class_of")
	var cs := CampaignState.open(TEST_SAVE)
	cs.reset()
	_check(cs.choose_companion(cc) == OK, "companion saved")
	_check(str(cs.companion.get("class", "")) == "two_hand", "snapshot has class two_hand (%s)" % cs.companion)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))
	_check(raw is Dictionary and int(raw.get("version", 0)) == 1 and str((raw["companion"] as Dictionary).get("class", "")) == "two_hand",
			"file: version 1, companion.class two_hand")
	var cs2 := CampaignState.open(TEST_SAVE)
	_check(str(cs2.companion.get("class", "")) == "two_hand" and str(cs2.companion.get("id", "")) == "coin_cutter"
			and int(cs2.companion.get("purse", -1)) == 100, "round-trip keeps the class (%s)" % cs2.companion)
	_check(cs2.to_dict()["companion"] == cs2.companion, "to_dict writes the class back")
	for ch in gp.champions.duplicate():
		gp.dismiss(ch)
	await _frames(70)
	_check(gp.roster_size() == 0, "roster empty before the next mission")
	_hired_class.clear()
	var comp: Node = cs2.apply_companion(main)
	_check(comp != null, "companion spawned")
	if comp:
		_check(StringName(comp.call(&"class_id")) == &"two_hand", "companion keeps its class (%s)" % comp.call(&"class_id"))
		_check(comp.get("class_calls") == [&"two_hand"], "set_champion_class called once (%s)" % str(comp.get("class_calls")))
		_check(int(comp.get("level")) == 1, "companion back at level 1")
		_check(_hired_class == [&"two_hand"], "class set before champion_hired (%s)" % str(_hired_class))
		# The stand-in draw sees a class and does not draw again at level 2.
		var chosen := []
		comp.connect(&"class_chosen", func(_c: Node, id: StringName) -> void: chosen.append(id))
		comp.call(&"stub_level_up_to", 2)
		_check(chosen.is_empty() and StringName(comp.call(&"class_id")) == &"two_hand", "no second draw at level 2")
		gp.dismiss(comp)
		await _frames(70)
	cs2.reset()


## An old (step-9) save without "class": loads unchanged, the companion has no class and draws at level 2.
func _old_save(gp: ChampionGuild) -> void:
	var old := {"version": 1, "unlocked": ["m01", "m02"], "completed": ["m01"], "flags": {}, "items": {},
			"companion": {"id": "wayfinder", "variant": 1, "items": [{"id": "ember_shard", "count": 1}, null, null, null],
			"purse": 150}}
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	var cs := CampaignState.open(TEST_SAVE)
	_check(cs.has_companion() and not cs.companion.has("class"), "old save: companion without class (%s)" % cs.companion)
	_check(str(cs.companion["id"]) == "wayfinder" and int(cs.companion["variant"]) == 1 and int(cs.companion["purse"]) == 150,
			"old save: id / variant / purse unchanged")
	_check(cs.completed.has(&"m01") and cs.unlocked.has(&"m02"), "old save: progress unchanged")
	_check(cs.to_dict()["companion"] == old["companion"], "old save: written back exactly as it was (%s)" % cs.to_dict()["companion"])
	_hired_class.clear()
	var comp: Node = cs.apply_companion(main)
	_check(comp != null, "old-save companion spawned")
	if comp:
		_check(StringName(comp.call(&"class_id")) == &"" and (comp.get("class_calls") as Array).is_empty(),
				"old-save companion has no class, set_champion_class never called")
		var chosen := []
		comp.connect(&"class_chosen", func(_c: Node, id: StringName) -> void: chosen.append(id))
		comp.call(&"stub_level_up_to", 2)
		_check(chosen.size() == 1, "old-save companion draws at level 2")
		gp.dismiss(comp)
		await _frames(70)
	cs.reset()


## Bad "class" values in a save file are dropped on load (the rest of the entry stays).
func _clean_values() -> void:
	for bad: Variant in ["", "   ", 5, null, [], {}, "wizard"]:
		var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
		f.store_string(JSON.stringify({"version": 1, "companion": {"id": "mender", "variant": 0, "items": [], "purse": 10,
				"class": bad}}))
		f.close()
		var c := CampaignState.open(TEST_SAVE).companion
		if bad is String and bad == "wizard":
			_check(str(c.get("class", "")) == "wizard", "class wizard kept (%s)" % c)
		else:
			_check(not c.has("class") and str(c.get("id", "")) == "mender", "class %s dropped (%s)" % [str(bad), c])


## With the real Champion (once 11.C1 has landed): class kept at level 1, class skills locked, old save draws at 2.
func _real_champion(gp: ChampionGuild) -> void:
	var script := load(CHAMPION_PATH) as Script
	var has_api := false
	if script:
		for m in script.get_script_method_list():
			if str(m["name"]) == "set_champion_class":
				has_api = true
	if not has_api:
		print("  SKIP real-champion checks: Champion.set_champion_class not there yet (11.C1)")
		return
	gp.champion_script = null
	gp.type_lookup = Callable()
	var at: Vector3 = main.hero.global_position + Vector3(2, 0, 2)
	var comp: Node = gp.add_companion({"id": "wayfinder", "variant": 0, "items": [], "purse": 20, "class": "spear"}, at)
	_check(comp != null, "real: companion spawned")
	if comp == null:
		_use_stubs(gp)
		return
	await _frames(5)
	_check(StringName(comp.call(&"class_id")) == &"spear" and int(comp.get("level")) == 1, "real: spear at level 1")
	var abilities: Variant = comp.get("abilities")
	var cls_script: Script = load(CLASS_PATH) as Script if ResourceLoader.exists(CLASS_PATH) else null
	var cls: Variant = cls_script.call(&"find", &"spear") if cls_script else null
	if abilities is Object and (abilities as Object).has_method(&"is_unlocked") and cls is Object:
		for id: Variant in (cls as Object).get(&"ability_ids"):
			_check(not bool((abilities as Object).call(&"is_unlocked", StringName(id))), "real: class skill %s locked at level 1" % id)
	gp.dismiss(comp)
	await _frames(70)
	var old: Node = gp.add_companion({"id": "mender", "variant": 0, "items": [], "purse": 0}, at)
	_check(old != null and StringName(old.call(&"class_id")) == &"", "real: old-save companion has no class")
	if old:
		old.call(&"add_xp", 190)
		_check(int(old.get("level")) == 2 and StringName(old.call(&"class_id")) != &"", "real: old-save companion draws at level 2")
		gp.dismiss(old)
		await _frames(70)
	_use_stubs(gp)
