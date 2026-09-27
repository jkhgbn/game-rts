extends SceneTree
## Task 7.I1: the 4 Ice items (kingdom-ice.md section 6) with their numbers, recipes, and Glacier Shell
## (Winterwall Aegis active) = 2.5 s of no damage and no action, then a 75 s cooldown.
## Parts that need other agents' Step 7 work (the `frozen` / `chill` statuses, the passive registry
## entries numbing_touch / frostbite / frost_ward) are checked only when present, else reported as SKIP.
## Run: godot --headless --path . -s tests/test_7_i1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "7.i1"
const SHELL_FRAMES := 150   # 2.5 s
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _fail := ""
var hero
var inv
var actives
var _hp_at_use := 0.0
var _frozen_checked := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		_setup()
	elif frame == 60 and _fail == "":
		_check_mid_shell()
	elif frame == 2 + SHELL_FRAMES + 10 and _fail == "":
		_check_after_shell()
		if _fail == "":
			print("PASS %s" % TASK_ID)
			return true
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	hero = main.hero
	inv = hero.inventory
	_expect(inv != null, "the hero has no inventory")
	if _fail != "":
		return
	# --- Data: tiers, costs, stats, shops (kingdom-ice.md 6)
	_check_item(&"frostglass_shard", ItemType.Tier.COMPONENT, 200, {&"armor": 10.0, &"max_mana": 20.0})
	_check_item(&"rimebound_bracers", ItemType.Tier.MID, 630, {&"armor": 25.0, &"max_hp": 60.0})
	_check_item(&"glacier_heart", ItemType.Tier.MID, 630,
			{&"spell_power": 15.0, &"max_mana": 50.0, &"armor": 10.0})
	_check_item(&"winterwall_aegis", ItemType.Tier.TOP, 1860, {&"armor": 40.0, &"max_hp": 200.0})
	if _fail != "":
		return
	_expect(ItemType.find(&"rimebound_bracers").passive_id == &"numbing_touch", "bracers passive id")
	_expect(ItemType.find(&"glacier_heart").passive_id == &"frostbite", "heart passive id")
	var aegis := ItemType.find(&"winterwall_aegis")
	_expect(aegis.passive_id == &"frost_ward" and is_equal_approx(aegis.active_cooldown, 75.0)
			and ItemActives.effect_key(aegis) == &"glacier_shell"
			and ItemActives.target_kind(aegis) == "self", "aegis passive / active data")
	# --- Recipes: owned parts consumed, the recipe cost paid
	for i in 6:
		inv.remove_item(i)
	inv.add_item(ItemType.find(&"frostglass_shard"))
	inv.add_item(ItemType.find(&"ironbark_plate"))
	var p: Dictionary = Recipes.plan(inv, ItemType.find(&"rimebound_bracers"))
	_expect(int(p["essence_cost"]) == 250 and (p["consume_slots"] as Array).size() == 2,
			"bracers from both parts should cost 250, got %s" % [p])
	p = Recipes.plan(inv, aegis)
	_expect(int(p["essence_cost"]) == 1860 - 380, "aegis with shard + plate should cost 1480, got %s" % [p])
	for i in 6:
		inv.remove_item(i)
	_check_passives()
	if _fail != "":
		return
	# --- Glacier Shell
	for i in 6:
		inv.remove_item(i)
	inv.add_item(aegis)
	var slot: int = inv.find_slot(&"winterwall_aegis")
	var reason: String = inv.use_item(slot, null)
	_expect(reason == "", "Glacier Shell refused: %s" % reason)
	actives = ItemActives.for_inventory(inv)
	_expect(is_equal_approx(actives.shell_time_left(), 2.5), "shell should last 2.5 s, got %.2f" % actives.shell_time_left())
	_hp_at_use = hero.hp
	hero.take_damage(100000.0, null)
	_expect(hero.is_alive() and is_equal_approx(hero.hp, _hp_at_use),
			"a huge hit during the shell changed HP %.1f -> %.1f" % [_hp_at_use, hero.hp])
	_expect(inv.use_item(slot, null) == "On cooldown", "second use should be on cooldown")
	if hero.has_method(&"can_act"):
		_expect(not hero.can_act() and not hero.can_move(), "the shelled wizard can still act / move")
		_expect(hero.status_time_left(&"frozen") >= 2.49,
				"frozen should last the full 2.5 s on the wizard, got %.2f" % hero.status_time_left(&"frozen"))
		_frozen_checked = true
	else:
		print("7.i1: SKIP frozen checks (Unit.can_act not there yet, 7.G1)")


func _check_mid_shell() -> void:
	var before: float = hero.hp
	hero.take_damage(100000.0, null)
	_expect(hero.is_alive() and is_equal_approx(hero.hp, before), "a hit at 1 s into the shell did damage")
	if _frozen_checked:
		_expect(not hero.can_act(), "the wizard thawed before 2.5 s")


func _check_after_shell() -> void:
	_expect(actives.shell_time_left() <= 0.0, "the shell is still running after 2.7 s")
	if _frozen_checked:
		_expect(hero.can_act(), "the wizard is still frozen after 2.7 s")
	var before: float = hero.hp
	hero.take_damage(20.0, null)
	_expect(hero.hp < before, "damage is still blocked after the shell")
	_expect(actives.cooldown_left(inv.find_slot(&"winterwall_aegis")) > 70.0, "the 75 s cooldown is not running")


# Numbing Touch / Frostbite / Frost Ward: only when the lead has added them to ItemPassives.
func _check_passives() -> void:
	if not ItemPassives.is_known(&"numbing_touch"):
		print("7.i1: SKIP passives (numbing_touch / frostbite / frost_ward not in ItemPassives yet)")
		return
	var enemy = null
	for u in hero.get_tree().get_nodes_in_group(&"units"):
		if u is Unit and u.is_alive() and hero.is_enemy_of(u) and not u.is_in_group(&"heroes"):
			enemy = u
			break
	if enemy == null or not Unit.STATUSES.has(&"chill"):
		print("7.i1: SKIP passive effects (no enemy unit or no chill status)")
		return
	inv.add_item(ItemType.find(&"rimebound_bracers"))
	hero.attack_landed.emit(enemy, 10.0)
	_expect(enemy.status_time_left(&"chill") > 1.4, "Numbing Touch did not chill the target")
	for i in 6:
		inv.remove_item(i)
	enemy.apply_status(&"chill", 0.01)
	inv.add_item(ItemType.find(&"glacier_heart"))
	hero.spell_hit.emit(enemy, 10.0, &"fireball")
	_expect(enemy.status_time_left(&"chill") > 1.4, "Frostbite did not chill the spell target")


func _check_item(id: StringName, tier: int, total: int, stats: Dictionary) -> void:
	var t := ItemType.find(id)
	if t == null:
		_fail = "missing data/items/%s.tres" % id
		return
	_expect(int(t.tier) == tier, "%s tier %d" % [id, t.tier])
	_expect(t.total_cost() == total, "%s total cost %d, expected %d" % [id, t.total_cost(), total])
	_expect(t.is_sold_at(ItemType.SOLD_BASE), "%s not sold at base shops" % id)
	_expect(t.stats.size() == stats.size(), "%s has %d stats, expected %d" % [id, t.stats.size(), stats.size()])
	for k: StringName in stats:
		_expect(is_equal_approx(float(t.stats.get(String(k), t.stats.get(k, -1.0))), float(stats[k])),
				"%s stat %s = %s" % [id, k, t.stats.get(String(k))])


func _expect(ok: bool, msg: String) -> void:
	if not ok and _fail == "":
		_fail = msg
