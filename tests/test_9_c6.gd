extends SceneTree
## Task 9.C6: champion inventories (4 slots, no artifacts), purse buying + 20 % tithe (message at most
## once per 10 s, summed), no selling, the wish-list helper (in order, combines consume their parts,
## 4 slots, keep 1 Ember Draught after the list), Ember Draught / Stride through ItemActives by id, and
## wizards unchanged (6 + 2, the bank pays, no tithe). Uses a stub champion (a Unit with a purse).
## Run: godot --headless --path . -s tests/test_9_c6.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "9.c6"
const TIMEOUT_FRAMES := 1200
const DRINK_FRAME := 5
const END_FRAME := 640

## Stands in for Champion (scripts/units/champion.gd, task 9.C1) with the frozen purse API.
class StubChampion extends Unit:
	signal purse_changed(amount: int)
	var purse: int = 0
	var display_name := "Sable Quint"
	var inventory: Inventory = null

	func _ready() -> void:
		super._ready()
		inventory = Inventory.ensure_for(self)   # like SpellCaster: created by the owner in _ready

	func add_purse(n: int) -> void:
		purse += n
		purse_changed.emit(purse)

	func spend_purse(n: int) -> bool:
		if n < 0 or n > purse:
			return false
		purse -= n
		purse_changed.emit(purse)
		return true

const WISHLISTS := {
	"wayfinder": ["swiftsoles", "ember_draught", "whetted_fang", "ember_shard", "blazing_edge",
			"wisp_lantern", "ashen_greaves"],
	"oathwall": ["ironbark_plate", "ember_draught", "wisp_lantern", "nightveil_cloak", "bone_charm",
			"ironbark_plate", "warlords_horn"],
	"coin_cutter": ["ember_shard", "whetted_fang", "blazing_edge", "ember_draught", "bone_charm",
			"ember_shard", "grave_pact"],
	"mender": ["wisp_lantern", "ember_draught", "duskglass", "cinder_ring", "emberwake_band",
			"ironbark_plate", "nightveil_cloak"],
}

var main: Node
var frame := 0
var _wait := 0
var _fail := ""
var _item_script: Script
var bank: Object
var champ: StubChampion
var cinv: Inventory
var hero: Node3D
var winv: Inventory
var _messages: Array = []      # [text, amount] from tithe_announced
var _tithe_total := 0          # every tithe_paid of the champion
var _hp_before_drink := 0.0
var _speed_before_stride := 0.0


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
		if _fail == "":
			_step_slots_and_purse()
	elif frame == 2:
		_step_tithe_throttle()
	elif frame == 3:
		_step_wizard_unchanged()
	elif frame == 4:
		_step_wishlists()
	elif frame == DRINK_FRAME:
		_step_actives()
	elif frame == DRINK_FRAME + 5:
		_check(is_equal_approx(champ.get_stat(&"move_speed"), _speed_before_stride + 2.5),
				"Stride did not add 2.5 speed (%.2f -> %.2f)" % [_speed_before_stride, champ.get_stat(&"move_speed")])
	elif frame == DRINK_FRAME + 250:   # 4.1 s
		_check(is_equal_approx(champ.get_stat(&"move_speed"), _speed_before_stride),
				"Stride still on after 4 s")
		var healed := champ.hp - _hp_before_drink
		_check(healed > 60.0 and healed < 90.0, "Ember Draught healed %.1f after 4 s (about 75)" % healed)
	elif frame == DRINK_FRAME + 500:   # 8.3 s; Ashen Greaves' own hp_regen (+2 / s) heals too
		var healed := champ.hp - _hp_before_drink - champ.get_stat(&"hp_regen") * 500.0 / 60.0
		_check(healed >= 149.0 and healed <= 151.0, "Ember Draught healed %.1f over 8 s (150)" % healed)
	elif frame == END_FRAME:
		# The throttled line: the 1st purchase at frame 1 was announced at once, the next two (frame 2)
		# were summed and announced 10 s after the first.
		# Every later tithe (frames 2 and 4) is in that one summed line.
		_check(_messages.size() == 2, "tithe messages: %s" % [_messages])
		if _messages.size() == 2:
			var rest := _tithe_total - 40
			_check(_messages[1][0] == "Tithe from Sable Quint: %d" % rest and int(_messages[1][1]) == rest,
					"summed tithe message: %s (expected %d)" % [_messages[1], rest])
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	if frame >= END_FRAME:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _check(cond: bool, what: String) -> void:
	if not cond and _fail == "":
		_fail = what


func _find(id: String) -> ItemType:
	return _item_script.call("find", StringName(id)) as ItemType


func _setup() -> void:
	_item_script = load("res://scripts/items/item_type.gd")
	hero = main.hero
	bank = load("res://scripts/items/essence_bank.gd").call("for_team", 0)
	bank.set("trickle_enabled", false)
	champ = StubChampion.new()
	champ.team = Unit.Team.PLAYER
	champ.unit_name = "Coin-Cutter"
	champ.max_hp = 1000.0
	champ.add_to_group(&"champions")
	main.add_child(champ)
	champ.global_position = (main.keep as Node3D).global_position + Vector3(6, 0, 0)
	cinv = champ.inventory
	_check(cinv != null and cinv.get_parent() == champ, "the champion has no Inventory")
	if cinv:
		cinv.tithe_announced.connect(func(text: String, amount: int) -> void: _messages.append([text, amount]))
		cinv.tithe_paid.connect(func(amount: int) -> void: _tithe_total += amount)


func _step_slots_and_purse() -> void:
	# 4 item slots, 0 artifact slots; never the Crown.
	_check(cinv.slot_count == 4 and cinv.slots.size() == 4, "champion slots: %d" % cinv.slots.size())
	_check(cinv.artifact_count == 0 and cinv.artifacts.is_empty(), "champion artifact slots")
	_check(cinv.is_champion_owner() and cinv.uses_purse() and not cinv.can_sell(), "champion detection")
	_check(not cinv.add_item(_find("ember_crown")), "a champion took the Ember Crown")
	_check(cinv.find_slot(&"ember_crown") < 0 and cinv.artifacts.is_empty(), "crown stored somewhere")
	# Counts chosen by the owner before _ready win over the detection.
	var inv2 := Inventory.new()
	inv2.slot_count = 5
	inv2.artifact_count = 1
	_check(inv2.slots.size() == 5 and inv2.artifacts.size() == 1, "set counts before _ready")
	inv2.free()
	# Buying Ember Shard from a 300 purse: 100 left, +40 to the team bank (which pays nothing).
	var shard := _find("ember_shard")
	bank.set("essence", 0)
	champ.purse = 300
	_check(cinv.can_buy(shard) == "", "champion can_buy shard: %s" % cinv.can_buy(shard))
	var dmg0 := champ.get_stat(&"attack_damage")
	var r := cinv.buy(shard)
	_check(r == "", "champion buy shard: %s" % r)
	_check(champ.purse == 100, "purse after the shard: %d (100)" % champ.purse)
	_check(int(bank.get("essence")) == 40, "bank after the tithe: %d (40)" % int(bank.get("essence")))
	_check(is_equal_approx(champ.get_stat(&"attack_damage"), dmg0 + 12.0), "shard stat on the champion")
	_check(champ.has_modifier(&"item:1"), "item:1 modifier on the champion")
	_check(_messages.size() == 1 and _messages[0][0] == "Tithe from Sable Quint: 40",
			"first tithe message: %s" % [_messages])
	# The purse decides, not the bank.
	bank.set("essence", 5000)
	_check(cinv.can_buy(_find("bone_charm")) == "Not enough essence",
			"100 purse bought a 250 item: %s" % cinv.can_buy(_find("bone_charm")))
	# No selling.
	_check(cinv.sell(0) == 0 and cinv.find_slot(&"ember_shard") == 0, "a champion sold an item")
	_check(int(bank.get("essence")) == 5000, "bank changed on a refused sale")
	# 4 slots: 3 more fit, a 5th does not.
	champ.add_purse(5000)
	for id: String in ["ironbark_plate", "wisp_lantern", "cinder_ring"]:
		cinv.add_item(_find(id))
	_check(cinv.can_buy(_find("gloom_ink")) == "Inventory full",
			"5th item: %s" % cinv.can_buy(_find("gloom_ink")))
	for i in 4:
		cinv.remove_item(i)
	_check(not champ.has_modifier(&"item:1") and is_equal_approx(champ.get_stat(&"attack_damage"), dmg0),
			"modifiers not removed")
	champ.purse = 0


func _step_tithe_throttle() -> void:
	# Two purchases inside the 10 s window: the bank gets both tithes at once, one summed line later.
	bank.set("essence", 0)
	champ.purse = 320
	_check(cinv.buy(_find("whetted_fang")) == "", "buy fang")
	_check(cinv.buy(_find("ember_draught")) == "", "buy draught")
	_check(champ.purse == 0, "purse after fang + draught: %d" % champ.purse)
	_check(int(bank.get("essence")) == 64, "tithes 40 + 24: %d" % int(bank.get("essence")))
	_check(_messages.size() == 1, "a second tithe line inside 10 s")
	for i in 4:
		cinv.remove_item(i)


func _step_wizard_unchanged() -> void:
	winv = Inventory.ensure_for(hero)
	_check(winv.slot_count == 6 and winv.slots.size() == 6, "wizard slots: %d" % winv.slots.size())
	_check(winv.artifact_count == 2 and winv.artifacts.size() == 2, "wizard artifact slots")
	_check(not winv.is_champion_owner() and not winv.uses_purse() and winv.can_sell(), "wizard is a champion")
	for i in 6:
		winv.remove_item(i)
	var tithes := [0]
	winv.tithe_paid.connect(func(n: int) -> void: tithes[0] += n)
	hero.global_position = (main.keep as Node3D).global_position + Vector3(-6, 0, 0)
	bank.set("essence", 500)
	var r := winv.buy(_find("ember_shard"))
	_check(r == "" and int(bank.get("essence")) == 300, "wizard buy: '%s', bank %d (300)" % [r, bank.get("essence")])
	_check(tithes[0] == 0, "the wizard paid a tithe")
	var slot := winv.find_slot(&"ember_shard")
	_check(slot >= 0 and winv.sell(slot) == 100 and int(bank.get("essence")) == 400, "wizard sell")


func _step_wishlists() -> void:
	bank.set("essence", 0)
	for arch: String in WISHLISTS:
		var list: Array = WISHLISTS[arch]
		for i in 4:
			cinv.remove_item(i)
		champ.purse = 0
		var first := cinv.next_wishlist_entry(list)
		_check(first != null and String(first.id) == list[0], "%s: first entry %s" % [arch, first])
		_check(cinv.next_wishlist_buy(list) == null, "%s: buyable with an empty purse" % arch)
		_check(cinv.next_wishlist_price(list) == first.total_cost(), "%s: first price" % arch)
		# Plenty of money: buy in order until the helper says stop. The helper's price is what buy() takes.
		champ.purse = 10000
		var bought: Array = []
		var tithes := 0
		var bank0 := int(bank.get("essence"))
		for step in 12:
			var t := cinv.next_wishlist_buy(list)
			if t == null:
				break
			var price := cinv.next_wishlist_price(list)
			var before := champ.purse
			var r := cinv.buy(t)
			_check(r == "", "%s: buy %s: %s" % [arch, t.id, r])
			_check(before - champ.purse == price, "%s: %s cost %d, helper said %d" % [arch, t.id,
					before - champ.purse, price])
			tithes += Inventory.tithe_for(before - champ.purse)
			bought.append(String(t.id))
			_check(cinv.slots.size() == 4, "%s: slots" % arch)
		_check(bought == list, "%s bought %s" % [arch, bought])
		_check(int(bank.get("essence")) - bank0 == tithes and tithes > 0, "%s: tithes %d, bank +%d" % [arch,
				tithes, int(bank.get("essence")) - bank0])
		_check(cinv.next_wishlist_entry(list) == null, "%s: wants more after the list with a draught" % arch)
		_check(cinv.find_slot(&"ember_draught") >= 0, "%s: no draught kept" % arch)
		# After the list: the draught is used up -> keep 1 in stock.
		var ds := cinv.find_slot(&"ember_draught")
		cinv.remove_item(ds)
		var again := cinv.next_wishlist_entry(list)
		_check(again != null and again.id == &"ember_draught", "%s: no draught restock" % arch)
	# A combine whose part is carried costs only the recipe (Blazing Edge after Shard + Fang = 250).
	for i in 4:
		cinv.remove_item(i)
	var cc: Array = WISHLISTS["coin_cutter"]
	cinv.add_item(_find("ember_shard"))
	cinv.add_item(_find("whetted_fang"))
	champ.purse = 250
	var t2 := cinv.next_wishlist_buy(cc)
	_check(t2 != null and t2.id == &"blazing_edge" and cinv.next_wishlist_price(cc) == 250,
			"blazing edge from carried parts: %s" % [t2])
	_check(cinv.buy(t2) == "" and champ.purse == 0 and cinv.free_slots() == 3, "combine consumed its parts")
	for i in 4:
		cinv.remove_item(i)


func _step_actives() -> void:
	var actives: Script = load("res://scripts/items/item_actives.gd")
	# Far from every shop and away from the keep's healing.
	champ.global_position = (main.keep as Node3D).global_position + Vector3(0, 0, 40)
	_check(actives.call("use_by_id", cinv, &"ember_draught") == "Not carried", "drank a missing draught")
	_check(actives.call("use_stride", cinv) == "Not carried", "strode without greaves")
	cinv.add_item(_find("ember_draught"), 2)
	cinv.add_item(_find("ashen_greaves"))
	champ.take_damage(500.0, null)
	_hp_before_drink = champ.hp
	_check(actives.call("check_by_id", cinv, &"ember_draught") == "", "draught not ready: %s" %
			actives.call("check_by_id", cinv, &"ember_draught"))
	var r: String = actives.call("drink_potion", cinv)
	_check(r == "", "drink_potion: %s" % r)
	var ds := cinv.find_slot(&"ember_draught")
	_check(ds >= 0 and int(cinv.slots[ds]["count"]) == 1, "the draught charge was not used")
	_check(actives.call("drink_potion", cinv) == "On cooldown", "second draught not on cooldown")
	_check(actives.call("check_by_id", cinv, &"ember_draught") == "On cooldown", "check_by_id cooldown")
	_speed_before_stride = champ.get_stat(&"move_speed")
	_check(actives.call("check_by_id", cinv, &"stride") == "", "stride not ready")
	r = actives.call("use_by_id", cinv, &"ashen_greaves")
	_check(r == "", "Stride by item id: %s" % r)
	_check(actives.call("use_stride", cinv) == "On cooldown", "Stride not on cooldown")
