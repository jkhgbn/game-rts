extends SceneTree
## Task 4.I2: Recipes.plan (owned parts consumed, missing parts priced) and ItemActives
## (consumable heals over time and loses a charge, shared potion cooldown, Brace cooldown, Stride,
## Blink range, use reasons). Uses the real ItemType data when present, else fake types, and a fake
## inventory node (the frozen `slots` shape: `{type, count, cooldown_left}`).
## Run: godot --headless --path . -s tests/test_4_i2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.i2"
const TIMEOUT_FRAMES := 900
const WAIT_FRAMES := 510   # 8.5 s: the Ember Draught (8 s) is done, Stride (4 s) is over

class FakeType extends Resource:
	var id: StringName
	var display_name: String
	var tier: String = "component"
	var cost: int = 0
	var parts: Array = []
	var active_id: StringName = &""
	var active_cooldown: float = 0.0
	var stack_max: int = 1
	var sold_at: int = 1
	var is_artifact := false
	var campaign_only := false
	var icon_abbrev := ""

class FakeInventory extends Node:
	signal inventory_changed
	var slots: Array = [null, null, null, null, null, null]
	var artifacts: Array = [null, null]
	var wizard: Node

	func remove_item(slot: int) -> Resource:
		var e: Variant = slots[slot]
		slots[slot] = null
		inventory_changed.emit()
		return e["type"] if e is Dictionary else null

var main: Node
var frame := 0
var _wait := 0
var _fail := ""
var _types := {}
var inv: FakeInventory
var actives
var hero
var hp_after_potion := 0.0
var base_speed := 0.0


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
	elif frame == 1 + WAIT_FRAMES and _fail == "":
		_check_late()
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	if frame > 1 + WAIT_FRAMES:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	hero = main.hero
	inv = FakeInventory.new()
	inv.wizard = hero
	root.add_child(inv)
	var real := Recipes.find_type(&"blazing_edge") != null
	print("4.i2: using %s item types" % ("real" if real else "fake"))

	# --- Recipes
	_put(0, "ember_shard")
	_put(1, "whetted_fang")
	var p := Recipes.plan(inv, _t("blazing_edge"))
	_expect((p["consume_slots"] as Array) == [0, 1], "BE should consume slots 0 and 1, got %s" % [p["consume_slots"]])
	_expect(int(p["essence_cost"]) == 250, "BE with both parts should cost 250, got %d" % p["essence_cost"])
	_expect(p["reason"] in ["", "Not enough essence"], "BE refused: %s" % p["reason"])
	inv.slots[1] = null
	p = Recipes.plan(inv, _t("blazing_edge"))
	_expect(int(p["essence_cost"]) == 450 and (p["consume_slots"] as Array) == [0],
			"BE with Ember Shard only should cost 450 (250 + 200), got %s" % [p])
	inv.slots[0] = null
	p = Recipes.plan(inv, _t("blazing_edge"))
	_expect(int(p["essence_cost"]) == 650 and (p["consume_slots"] as Array).is_empty(),
			"BE with nothing should cost 650, got %s" % [p])
	_put(2, "blazing_edge")
	_put(4, "grave_pact")
	p = Recipes.plan(inv, _t("inferno_blade"))
	_expect(int(p["essence_cost"]) == 500 and (p["consume_slots"] as Array) == [2, 4],
			"Inferno Blade from BE + GP should cost 500, got %s" % [p])
	var tree := Recipes.tree(_t("inferno_blade"), inv)
	_expect((tree["parts"] as Array).size() == 2 and bool(tree["parts"][0]["owned"]),
			"tree should list 2 parts with Blazing Edge owned")
	for i in 6:
		inv.slots[i] = null

	# --- Actives: reasons
	_expect(ItemActives.use(inv, 0, null) == "Empty slot", "empty slot reason")
	actives = ItemActives.for_inventory(inv)
	_put(0, "ember_draught", 3)
	_put(1, "dusk_vial", 3)
	_put(2, "bulwark_of_ruin")
	_put(3, "ember_shard")
	_put(4, "ashen_greaves")
	_put(5, "shadowstride")
	_expect(ItemActives.use(inv, 3, null) == "Not an active", "component should be 'Not an active'")

	# Consumable: heals 150 over 8 s, loses a charge, shared potion cooldown.
	hero.take_damage(200.0, null)
	hp_after_potion = float(hero.hp)
	var r: String = ItemActives.use(inv, 0, null)
	_expect(r == "", "Ember Draught refused: %s" % r)
	_expect(int(inv.slots[0]["count"]) == 2, "Ember Draught should have 2 charges left")
	_expect(ItemActives.use(inv, 1, null) == "On cooldown", "Dusk Vial should share the potion cooldown")

	# Active: Brace goes on cooldown (60 s without CDR).
	r = ItemActives.use(inv, 2, null)
	_expect(r == "", "Brace refused: %s" % r)
	var cdr := float(hero.get_stat(&"cooldown_reduction"))
	_expect(absf(actives.cooldown_left(2) - 60.0 * (1.0 - cdr / 100.0)) < 0.1,
			"Brace cooldown should be 60, got %.2f" % actives.cooldown_left(2))
	_expect(ItemActives.use(inv, 2, null) == "On cooldown", "second Brace should be 'On cooldown'")

	# Stride: +2.5 move speed for 4 s.
	base_speed = float(hero.get_stat(&"move_speed"))
	_expect(ItemActives.use(inv, 4, null) == "", "Stride refused")
	_expect(absf(float(hero.get_stat(&"move_speed")) - base_speed - 2.5) < 0.01, "Stride should add 2.5 speed")

	# Blink: 10 m max, point target required.
	_expect(ItemActives.use(inv, 5, null) == "Invalid target", "Blink without a point: 'Invalid target'")
	var from: Vector3 = hero.global_position
	_expect(ItemActives.use(inv, 5, from + Vector3(30, 0, 0)) == "", "Blink refused")
	var moved := Vector2(hero.global_position.x - from.x, hero.global_position.z - from.z).length()
	_expect(moved > 3.0 and moved <= 10.05, "Blink should move up to 10 m, moved %.2f" % moved)

	# The real Inventory (4.I1), when it exists: recipe plan + a consumable through use_item.
	var real_inv = hero.get("inventory")
	if real_inv is Node and real_inv.has_method("add_item") and real_inv.has_method("use_item"):
		print("4.i2: also checking the real Inventory")
		real_inv.add_item(_t("ember_shard"))
		real_inv.add_item(_t("whetted_fang"))
		p = Recipes.plan(real_inv, _t("blazing_edge"))
		_expect((p["consume_slots"] as Array).size() == 2 and int(p["essence_cost"]) == 250,
				"real inventory: BE plan should consume 2 parts for 250, got %s" % [p])
		real_inv.add_item(_t("dusk_vial"))
		real_inv.add_item(_t("dusk_vial"))
		var vslot := -1
		for i in 6:
			var e: Variant = real_inv.slots[i]
			if e is Dictionary and String(e["type"].id) == "dusk_vial":
				vslot = i
		_expect(vslot >= 0 and int(real_inv.slots[vslot]["count"]) == 2, "real inventory: 2 Dusk Vials stacked")
		r = real_inv.use_item(vslot, null)
		_expect(r == "", "real inventory: Dusk Vial refused: %s" % r)
		_expect(int(real_inv.slots[vslot]["count"]) == 1, "real inventory: Dusk Vial should lose a charge")
		_expect(real_inv.use_item(vslot, null) == "On cooldown", "real inventory: potion cooldown")


func _check_late() -> void:
	var gained: float = float(hero.hp) - hp_after_potion
	_expect(gained > 147.0 and gained < 153.0, "Ember Draught should heal 150 over 8 s, healed %.1f" % gained)
	_expect(absf(float(hero.get_stat(&"move_speed")) - base_speed) < 0.01, "Stride should end after 4 s")
	var cd: float = actives.cooldown_left(2)
	_expect(cd > 50.0 and cd < 52.0, "Brace cooldown should keep running (%.2f)" % cd)
	_expect(float(inv.slots[2]["cooldown_left"]) == cd, "slot cooldown_left should mirror the cooldown")
	_expect(ItemActives.use(inv, 0, null) == "On cooldown", "the potion cooldown (20 s) should still run at 8.5 s")


func _put(slot: int, id: String, count: int = 1) -> void:
	inv.slots[slot] = {"type": _t(id), "count": count, "cooldown_left": 0.0}


func _expect(cond: bool, msg: String) -> void:
	if not cond and _fail == "":
		_fail = msg


func _t(id: String) -> Object:
	if _types.has(id):
		return _types[id]
	var real := Recipes.find_type(StringName(id))
	if real != null:
		_types[id] = real
		return real
	var f := FakeType.new()
	f.id = StringName(id)
	f.display_name = id.capitalize()
	match id:
		"ember_shard", "whetted_fang":
			f.cost = 200
		"bone_charm", "warden_scale":
			f.cost = 250
			if id == "warden_scale":
				f.sold_at = 2
		"vital_root":
			f.cost = 220
			f.sold_at = 2
		"wisp_lantern":
			f.cost = 150
		"swiftsoles":
			f.cost = 250
		"ironbark_plate":
			f.cost = 180
		"blazing_edge":
			_mid(f, 250, ["ember_shard", "whetted_fang"])
		"grave_pact":
			_mid(f, 300, ["bone_charm", "ember_shard"])
		"nightveil_cloak":
			_mid(f, 250, ["ironbark_plate", "wisp_lantern"])
		"ashen_greaves":
			_mid(f, 200, ["swiftsoles", "wisp_lantern"])
			f.active_id = &"stride"
		"bulwark_of_ruin":
			_mid(f, 250, ["warden_scale", "vital_root"])
			f.active_id = &"brace"
		"inferno_blade":
			_mid(f, 500, ["blazing_edge", "grave_pact"])
			f.tier = "top"
		"shadowstride":
			_mid(f, 500, ["ashen_greaves", "nightveil_cloak"])
			f.tier = "top"
			f.active_id = &"blink"
		"ember_draught", "dusk_vial":
			f.tier = "consumable"
			f.cost = 120 if id == "ember_draught" else 100
			f.stack_max = 3
			f.sold_at = 3
	_types[id] = f
	return f


func _mid(f: FakeType, recipe: int, part_ids: Array) -> void:
	f.tier = "mid"
	f.cost = recipe
	f.sold_at = 0
	for pid: String in part_ids:
		f.parts.append(_t(pid))
