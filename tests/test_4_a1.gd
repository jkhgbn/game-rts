extends SceneTree
## Task 4.A1: the bot buys and uses items (items.md "The bot"). On scenes/skirmish.tscn, normal bot:
## 1. Malrik at his anchor (9.9 m from the Dusk Keep) gets 2 000 essence -> one purchase per tick, the
##    NORMAL list in order: Ember Shard, Bone Charm, Grave Pact, Ember Draught (Grave Pact consumes the parts).
## 2. Malrik at 40 % HP with a Draught -> he drinks it (Draught count drops, AIItems.used has it).
## 3. Strength: Malrik's AIMemory strength = 170 + 30 x level + total_item_value / 5.
## 4. Malrik 20 m from every shop with essence -> he buys nothing there (walks back to the keep instead).
## Uses the real Inventory when the wizard has one; otherwise a small stand-in (same API) is added as a
## child "Inventory", so the bot logic is proven either way (the log says which one ran).
## Run:  godot --headless --path . -s tests/test_4_a1.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "4.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const MEMORY := preload("res://scripts/ai/ai_memory.gd")
const ITEMS := preload("res://scripts/ai/ai_items.gd")
const BANK := "res://scripts/items/essence_bank.gd"
const SHADOW := 1
const TIMEOUT_FRAMES := 5400
const WANT := ["ember_shard", "bone_charm", "grave_pact", "ember_draught"]

var main: Node
var bot: Node
var malrik: Wizard
var inv: Object
var fake := false
var frame := 0
var _wait := 0
var _step := 0
var _step_at := 0.0
var _errors: Array[String] = []
var _hp_set := 0.0
var _draughts_before := 0


## Stand-in with the frozen Inventory API subset the bot uses (only when the real one is missing).
class FakeInventory extends Node:
	var slots: Array = [null, null, null, null, null, null]
	var essence := 0
	var wizard: Node

	func _find(id: String) -> Resource:
		var p := "res://data/items/%s.tres" % id
		return load(p) if ResourceLoader.exists(p) else null

	func _parts(t: Object) -> Array:
		var p: Variant = t.get(&"parts")
		return p if p is Array else []

	func _slot_with(id: String, skip: Array) -> int:
		for i in slots.size():
			if slots[i] != null and not skip.has(i) and str(slots[i]["type"].get(&"id")) == id:
				return i
		return -1

	## Parts carried are consumed; missing ones are paid (one level is enough for the list's order).
	func _price(t: Object, used: Array) -> int:
		var cost := int(t.get(&"cost"))
		for part: Variant in _parts(t):
			var s := _slot_with(str((part as Object).get(&"id")), used)
			if s >= 0:
				used.append(s)
			else:
				cost += _price(part as Object, used)
		return cost

	func can_buy(t: Object) -> String:
		if not bool(wizard.call(&"is_alive")):
			return "Dead"
		var near := false
		for b in wizard.get_tree().get_nodes_in_group("buildings"):
			if int(b.get(&"team")) == int(wizard.get(&"team")) and (b is Keep or (b.building_type \
					and b.building_type.kind == &"barracks")) and Vector2(b.global_position.x - wizard.global_position.x,
					b.global_position.z - wizard.global_position.z).length() <= 12.0:
				near = true
		if not near:
			return "No shop nearby"
		var used: Array = []
		var cost := _price(t, used)
		if slots.count(null) + used.size() < 1 and _slot_with(str(t.get(&"id")), []) < 0:
			return "Inventory full"
		if essence < cost:
			return "Not enough essence"
		return ""

	func buy(t: Object) -> String:
		var r := can_buy(t)
		if r != "":
			return r
		var used: Array = []
		essence -= _price(t, used)
		for s: int in used:
			slots[s] = null
		var stack := _slot_with(str(t.get(&"id")), [])
		if stack >= 0 and int(t.get(&"stack_max")) > 1:
			slots[stack]["count"] += 1
		else:
			slots[slots.find(null)] = {"type": t, "count": 1, "cooldown_left": 0.0}
		return ""

	func use_item(slot: int, _target: Variant) -> String:
		if slot < 0 or slot >= slots.size() or slots[slot] == null:
			return "Empty slot"
		var e: Dictionary = slots[slot]
		if str(e["type"].get(&"id")) != "ember_draught":
			return "Not an active"
		wizard.call(&"heal", 150.0)
		e["count"] -= 1
		if e["count"] <= 0:
			slots[slot] = null
		return ""

	func total_item_value() -> int:
		var v := 0
		for e: Variant in slots:
			if e != null:
				v += int((e as Dictionary)["type"].call(&"total_cost")) * int((e as Dictionary)["count"])
		return v


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == SHADOW:
			bot = child
	if bot == null:
		bot = COMMANDER.new()
		bot.team = SHADOW
		main.add_child(bot)
	bot.debug_log = true


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out at step %d" % _step)
		return _finish()
	var t: float = main.match_time()
	match _step:
		0:
			if bot.items == null:
				return false   # the bot's first tick creates it
			malrik = main.wizard_of(SHADOW)
			if int(bot.difficulty) != 1:
				_errors.append("bot is not normal")
			if not ResourceLoader.exists("res://data/items/ember_shard.tres"):
				_errors.append("data/items missing: nothing to test")
				return _finish()
			inv = ITEMS.inventory_of(malrik)
			if inv == null and ResourceLoader.exists("res://scripts/items/inventory.gd"):
				var s: Variant = load("res://scripts/items/inventory.gd")
				if ITEMS._script_has(s, "ensure_for"):
					inv = (s as Object).call(&"ensure_for", malrik)
			if inv == null:
				fake = true
				var f := FakeInventory.new()
				f.name = "Inventory"
				f.wizard = malrik
				malrik.add_child(f)
				inv = f
			print("inventory: %s" % ("STAND-IN (real Inventory missing)" if fake else "real"))
			_set_essence(2000)
			var keep: Node3D = main.keep_of(SHADOW)
			print("Malrik %.1f m from the keep" % _flat(malrik.global_position, keep.global_position))
			_next(t)
		1:
			if bot.items.bought.size() < WANT.size() and t - _step_at < 12.0:
				return false
			var got: Array = bot.items.bought.slice(0, WANT.size())
			print("bought %s (essence left %d), slots %s" % [str(bot.items.bought), _essence(), _slot_ids()])
			if str(got) != str(WANT):
				_errors.append("bought %s (want %s first)" % [str(got), str(WANT)])
			if _slot_ids().has("ember_shard") or _slot_ids().has("bone_charm"):
				_errors.append("Grave Pact did not consume its parts: %s" % str(_slot_ids()))
			var level: int = malrik.level
			var want_str := 170.0 + 30.0 * level + float(inv.call(&"total_item_value")) / 5.0
			var got_str: float = MEMORY.strength_of(malrik)
			print("strength %.1f (want %.1f, items %d)" % [got_str, want_str, int(inv.call(&"total_item_value"))])
			if absf(got_str - want_str) > 0.5 or float(inv.call(&"total_item_value")) <= 0.0:
				_errors.append("strength %.1f (want %.1f with items)" % [got_str, want_str])
			# Stop shopping (no essence) and hurt him to 40 %.
			_set_essence(0)
			_draughts_before = bot.items.count_of(inv, "ember_draught")
			malrik.hp = malrik.max_hp * 0.4
			_hp_set = malrik.hp
			_next(t)
		2:
			if not bot.items.used.has("ember_draught") and t - _step_at < 4.0:
				return false
			var after: int = bot.items.count_of(inv, "ember_draught")
			print("used %s, Draughts %d -> %d, HP %.0f -> %.0f" % [str(bot.items.used), _draughts_before, after,
					_hp_set, malrik.hp])
			if _draughts_before < 1:
				_errors.append("no Draught carried before the drink")
			elif not bot.items.used.has("ember_draught") or after != _draughts_before - 1:
				_errors.append("no Draught drunk at 40 %% HP within 4 s (used %s)" % str(bot.items.used))
			# Far from every shop with essence: no purchase there.
			malrik.hp = malrik.max_hp
			malrik.global_position = Vector3(10.0, 0.0, -10.0)
			malrik.command_stop()
			_draughts_before = bot.items.bought.size()
			_set_essence(2000)
			_next(t)
		3:
			if t - _step_at < 1.5:
				return false
			var d: float = _flat(malrik.global_position, main.keep_of(SHADOW).global_position)
			print("far away: %.1f m from the keep, purchases %d -> %d" % [d, _draughts_before, bot.items.bought.size()])
			if d > 12.5 and bot.items.bought.size() != _draughts_before:
				_errors.append("bought %s while %.1f m from the keep" % [str(bot.items.bought.back()), d])
			_next(t)
		4:
			var d0: float = _flat(malrik.global_position, main.keep_of(SHADOW).global_position)
			if d0 > 11.0 and t - _step_at < 15.0:
				return false
			var d: float = _flat(malrik.global_position, main.keep_of(SHADOW).global_position)
			print("after walking back: %.1f m from the keep, purchases %d" % [d, bot.items.bought.size()])
			if d > 12.5:
				_errors.append("Malrik did not walk back to the shop (%.1f m)" % d)
			return _finish()
	return false


func _set_essence(n: int) -> void:
	if fake:
		(inv as FakeInventory).essence = n
	if ResourceLoader.exists(BANK):
		var bank: Object = load(BANK).call(&"for_team", SHADOW)
		bank.set(&"essence", n)


func _essence() -> int:
	if fake:
		return (inv as FakeInventory).essence
	return int(load(BANK).call(&"for_team", SHADOW).get(&"essence"))


func _slot_ids() -> Array:
	var out: Array = []
	for e: Variant in inv.get(&"slots"):
		out.append(ITEMS.type_id(ITEMS.slot_type(e)))
	return out


func _next(t: float) -> void:
	_step += 1
	_step_at = t


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
