extends SceneTree
## Task 4.I1: items, inventory, essence. Run:
## godot --headless --path . -s tests/test_4_i1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.i1"
const TIMEOUT_FRAMES := 2400

var main: Node
var frame := 0
var _wait := 0
var _fail := ""
var inv: Object
var bank: Object
var hero: Node3D
var _trickle_start := 0
var _item_script: Script
var _deaths := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		_setup()
	elif frame == 2:
		_step_shop()
	elif frame == 3:
		_trickle_start = int(bank.get("essence"))
	elif frame == 183:   # 3 s later at --fixed-fps 60
		var gained := int(bank.get("essence")) - _trickle_start
		if _deaths == 0 and (gained < 2 or gained > 4):
			_fail = "trickle gave %d in 3 s" % gained
		_step_kill_and_pickup()
	elif frame == 200:
		_step_pickup_check()
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	if frame >= 201:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _check(cond: bool, what: String) -> void:
	if not cond and _fail == "":
		_fail = what


func _find(id: String) -> Resource:
	return _item_script.call("find", StringName(id))


func _setup() -> void:
	_item_script = load("res://scripts/items/item_type.gd")
	root.get_node("Events").connect("unit_died", func(_u: Node) -> void: _deaths += 1)
	hero = main.hero
	var inv_script: Script = load("res://scripts/items/inventory.gd")
	inv = inv_script.call("ensure_for", hero)
	_check(inv != null and inv.get_parent() == hero, "ensure_for did not add the Inventory")
	_check(inv_script.call("ensure_for", hero) == inv, "ensure_for created a second Inventory")
	bank = load("res://scripts/items/essence_bank.gd").call("for_team", 0)
	# The HUD's top bar may create the bank a few seconds earlier (during the navmesh bake), so the
	# +1/s trickle can already have added a little: start = 150 plus at most ~15 s of trickle.
	_check(bank != null and int(bank.get("essence")) >= 150 and int(bank.get("essence")) <= 165,
			"essence does not start at 150 (+ early trickle)")
	# Every item of items.md exists with the right totals.
	var totals := {"ember_shard": 200, "vital_root": 220, "blazing_edge": 650, "nightveil_cloak": 580,
			"bulwark_of_ruin": 720, "inferno_blade": 1900, "shadowstride": 1680, "staff_of_cinders": 1950,
			"banner_of_embers": 1450, "gravemaw_idol": 1860, "ruinwarden_mantle": 1400,
			"phoenix_plume": 1590, "ember_draught": 120, "owl_stone": 75}
	for id: String in totals:
		var t := _find(id)
		_check(t != null and int(t.call("total_cost")) == int(totals[id]), "total_cost of %s" % id)
	var count: int = (_item_script.call("all_items") as Array).size()
	# 35 from items.md + 4 Ice (7.I1) + 4 Nature (8.I1) + the Stillwater Orb (M9.I1, campaign artifact)
	# + the Keystone Shard (e3m1, campaign artifact)
	_check(count == 45, "expected 45 items, found %d" % count)
	var crown := _find("ember_crown")
	_check(crown != null and bool(crown.get("is_artifact")), "ember_crown is not an artifact")


func _step_shop() -> void:
	var keep: Node3D = main.keep
	var e0 := int(bank.get("essence"))
	# Out of range: 40 m from every shop.
	hero.global_position = keep.global_position + Vector3(0, 0, 40)
	var shard := _find("ember_shard")
	_check(inv.call("can_buy", shard) == "No shop nearby", "out of range: %s" % inv.call("can_buy", shard))
	# Near the keep.
	hero.global_position = keep.global_position + Vector3(6, 0, 0)
	_check(inv.call("nearest_shop") == keep, "the keep is not a shop at 6 m")
	_check(inv.call("can_buy", _find("vital_root")) == "Not sold here", "vital_root sold at the keep")
	_check(inv.call("can_buy", _find("owl_stone")) == "Not sold here", "owl_stone is sold (wave 5)")
	# 150 at the start < 200: not enough essence.
	_check(inv.call("can_buy", shard) == "Not enough essence", "150 essence bought a 200 item")
	bank.set("essence", e0 + 200)
	var dmg0: float = hero.call("get_stat", &"attack_damage")
	var r: String = inv.call("buy", shard)
	_check(r == "", "buy ember_shard: %s" % r)
	_check(int(bank.get("essence")) == e0, "essence did not drop by 200")
	_check(is_equal_approx(hero.call("get_stat", &"attack_damage"), dmg0 + 12.0), "attack_damage +12 missing")
	_check(bool(hero.call("has_modifier", &"item:1")), "modifier item:1 missing")
	# Not enough essence.
	bank.set("essence", 100)
	_check(inv.call("can_buy", _find("whetted_fang")) == "Not enough essence", "not enough essence")
	# Sell 50 %.
	var gained: int = inv.call("sell", 0)
	_check(gained == 100 and int(bank.get("essence")) == 200, "sell gave %d" % gained)
	_check(inv.call("sell", 0) == 0, "sold an empty slot")
	_check(is_equal_approx(hero.call("get_stat", &"attack_damage"), dmg0), "stat not back after sell")
	_check(not bool(hero.call("has_modifier", &"item:1")), "item:1 still on after sell")
	# Full: 6 components, then a 7th.
	bank.set("essence", 5000)
	for i in 6:
		_check(inv.call("buy", _find("ironbark_plate")) == "", "buy plate %d" % i)
	_check(inv.call("can_buy", shard) == "Inventory full", "7th: %s" % inv.call("can_buy", shard))
	# Caps: 6 plates = 90 armor (no cap hit); 5 Cinder Rings = 40 CDR, a 6th adds nothing.
	_check(is_equal_approx(hero.call("get_stat", &"armor"), 90.0), "armor from 6 plates")
	for i in 6:
		inv.call("remove_item", i)
	_check(is_equal_approx(hero.call("get_stat", &"armor"), 0.0), "armor not removed")
	for i in 6:
		inv.call("add_item", _find("cinder_ring"))
	_check(is_equal_approx(hero.call("get_stat", &"cooldown_reduction"), 40.0),
			"CDR cap: %s" % hero.call("get_stat", &"cooldown_reduction"))
	for i in 6:
		inv.call("remove_item", i)
	# Consumables stack.
	inv.call("buy", _find("ember_draught"))
	inv.call("buy", _find("ember_draught"))
	var e: Variant = inv.get("slots")[0]
	_check(e is Dictionary and int(e["count"]) == 2 and inv.get("slots")[1] == null, "draughts did not stack")
	_check(int(inv.call("sell_value", 0)) == 120, "2 draughts sell for %d" % inv.call("sell_value", 0))
	inv.call("remove_item", 0)
	# The Crown goes to artifact slot 1.
	var hp0: float = hero.call("get_stat", &"max_hp")
	_check(bool(inv.call("add_item", _find("ember_crown"))), "crown not added")
	_check(inv.get("artifacts")[0] != null, "crown not in artifact slot 1")
	_check(is_equal_approx(hero.call("get_stat", &"max_hp"), hp0 + 100.0), "crown +100 HP")
	_check(bool(hero.call("has_modifier", &"item:artifact_1")), "item:artifact_1 missing")
	_check(int(inv.call("sell", 6)) == 0 and inv.get("artifacts")[0] != null, "crown was sold")
	# Swap.
	inv.call("add_item", _find("wisp_lantern"))
	inv.call("swap", 0, 3)
	_check(inv.get("slots")[0] == null and inv.get("slots")[3] != null, "swap failed")
	_check(bool(hero.call("has_modifier", &"item:4")) and not bool(hero.call("has_modifier", &"item:1")),
			"swap did not move the modifier")
	inv.call("remove_item", 3)
	# Combine (Recipes.plan when 4.I2 exists): carried parts are consumed, only the recipe is paid.
	if ResourceLoader.exists("res://scripts/items/recipes.gd"):
		inv.call("add_item", _find("ember_shard"))
		inv.call("add_item", _find("whetted_fang"))
		bank.set("essence", 300)
		var rb: String = inv.call("buy", _find("blazing_edge"))
		_check(rb == "" and int(bank.get("essence")) == 50, "combine: '%s', essence %d" % [rb, bank.get("essence")])
		_check(int(inv.call("free_slots")) == 5 and inv.call("find_slot", &"blazing_edge") >= 0, "combine slots")
		for i in 6:
			inv.call("remove_item", i)
	bank.set("essence", 150)


func _step_kill_and_pickup() -> void:
	# Kill income: an enemy shade killed by the hero pays 60 % of its XP value (40 -> 24) to the team
	# (balance-1 2d).
	var shade: Node = null
	for u in root.get_tree().get_nodes_in_group("units"):
		if int(u.get("team")) == 1 and String(u.get("unit_name")) == "Shade":
			shade = u
			break
	_check(shade != null, "no enemy shade to kill")
	if shade:
		var before := int(bank.get("essence"))
		var xp: int = load("res://scripts/units/wizard.gd").call("xp_value_of", shade)
		var value := roundi(xp * 0.6)
		shade.call("take_damage", 99999.0, hero)
		_check(int(bank.get("essence")) - before == value and value > 0,
				"kill income %d (expected %d)" % [int(bank.get("essence")) - before, value])
	# Drop then pick up: the dropper ignores it until she leaves, then takes it on walking back.
	inv.call("add_item", _find("warden_scale"))
	var pickup: Node3D = inv.call("drop", 0)
	_check(pickup != null and pickup.is_in_group("item_pickups"), "drop made no pickup")
	_check(inv.get("slots")[0] == null, "drop kept the item")
	if pickup:
		hero.global_position = pickup.global_position + Vector3(10, 0, 0)


func _step_pickup_check() -> void:
	var pickups := root.get_tree().get_nodes_in_group("item_pickups")
	_check(pickups.size() == 1, "pickups: %d" % pickups.size())
	if pickups.size() == 1:
		var p: Node3D = pickups[0]
		hero.global_position = p.global_position + Vector3(0.5, 0, 0)
		_check(bool(p.call("pick_up", hero)), "pick_up failed")
		_check(inv.call("find_slot", &"warden_scale") >= 0, "warden_scale not picked up")
