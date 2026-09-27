class_name ItemActives
extends Node
## Item actives and consumables (docs/design/items.md, task 4.I2). One node per inventory, created on
## demand as a child named "ItemActives" (`ItemActives.for_inventory(inv)`).
##
## `ItemActives.use(inventory, slot, target) -> String` (static; `slot` = 0-based index into
## `inventory.slots`): `""` = used, else in this order `"Dead"`, `"Empty slot"`, `"Not an active"`,
## `"Unique"` (a stronger / earlier copy of the same active is carried), `"On cooldown"`,
## `"Invalid target"`. Cooldowns belong to the active's name (both potions share `potion`), so they
## follow the item through swaps and two Braces never run on separate cooldowns. They are mirrored into
## each slot entry's `cooldown_left` every frame for the UI. Passive effects are 4.G1 (gameplay).
## Gameplay hooks used when present: `add_shield(amount, duration)`, `heal(amount)`; simple fallbacks
## otherwise.

signal used(slot: int, type: Resource)
signal cooldown_started(group: StringName, seconds: float)
signal channel_started(seconds: float)
signal channel_ended(success: bool)

const NODE_NAME := "ItemActives"
const STRIDE_MOD := &"item_active:stride"
const CHANNEL_MOVE_TOLERANCE := 0.3
const CONSUMABLE_GROUPS: Array[StringName] = [&"potion", &"homeward_seal", &"owl_stone"]

## Effect table (numbers from items.md). `cooldown` is used when the ItemType's `active_cooldown` is 0.
const ACTIVES := {
	&"stride": {"target": "self", "cooldown": 40.0, "group": &"stride", "rank": 1,
			"speed": 2.5, "duration": 4.0},
	&"brace": {"target": "self", "cooldown": 60.0, "group": &"brace", "rank": 1,
			"shield": 120.0, "duration": 4.0},
	&"brace_ii": {"target": "self", "cooldown": 60.0, "group": &"brace", "rank": 2,
			"shield": 250.0, "duration": 5.0},
	&"blink": {"target": "point", "cooldown": 45.0, "group": &"blink", "rank": 1, "range": 10.0},
	&"rallying_cry": {"target": "self", "cooldown": 90.0, "group": &"rallying_cry", "rank": 1,
			"radius": 10.0, "heal": 60.0, "duration": 4.0},
	# Winterwall Aegis (kingdom-ice.md 6): the wizard is frozen 2.5 s and takes no damage.
	&"glacier_shell": {"target": "self", "cooldown": 75.0, "group": &"glacier_shell", "rank": 1,
			"duration": 2.5},
	# Heart of the Grove (kingdom-nature.md 5): every friendly unit within 8 m (the wizard, soldiers,
	# workers, summons) heals 100 over 5 s.
	&"overgrowth": {"target": "self", "cooldown": 80.0, "group": &"overgrowth", "rank": 1,
			"radius": 8.0, "heal": 100.0, "duration": 5.0},
	&"ember_draught": {"target": "self", "cooldown": 20.0, "group": &"potion", "consumable": true,
			"heal": 150.0, "duration": 8.0},
	&"dusk_vial": {"target": "self", "cooldown": 20.0, "group": &"potion", "consumable": true,
			"mana": 80.0, "duration": 8.0},
	&"homeward_seal": {"target": "self", "cooldown": 60.0, "group": &"homeward_seal",
			"consumable": true, "channel": 3.0},
	&"owl_stone": {"target": "point", "cooldown": 5.0, "group": &"owl_stone", "consumable": true,
			"range": 6.0, "wave": 5},
}
## Other spellings of active ids, and item ids whose ItemType has no `active_id`.
const ALIASES := {
	&"brace2": &"brace_ii", &"brace_2": &"brace_ii", &"brace_ii_": &"brace_ii",
	&"rally_cry": &"rallying_cry", &"homeward": &"homeward_seal", &"recall": &"homeward_seal",
	&"heal_potion": &"ember_draught", &"mana_potion": &"dusk_vial",
	&"ashen_greaves": &"stride", &"shadowstride": &"blink", &"bulwark_of_ruin": &"brace",
	&"ruinwarden_mantle": &"brace_ii", &"banner_of_embers": &"rallying_cry",
	&"winterwall_aegis": &"glacier_shell", &"heart_of_the_grove": &"overgrowth",
}
## Optional gameplay status that zeroes damage taken (`damage_taken` 0); applied when Unit knows it.
const SHELL_STATUS := &"glacier_shell"

var inventory: Node = null
var wizard: Node = null

var _cooldowns: Dictionary = {}        # group -> seconds left
var _cooldown_totals: Dictionary = {}  # group -> seconds at start
var _hots: Array[Dictionary] = []      # {unit, kind: "hp" / "mana", per_sec, left}
var _stride_left := 0.0
var _shield := {}                      # fallback shield: {amount, left, last_hp}
var _channel := {}                     # {left, total, entry, id, pos, hp}
var _shell_left := 0.0                 # Glacier Shell: seconds of "no damage" left


## The actives node of `inv` (created as its child on first use).
static func for_inventory(inv: Node) -> ItemActives:
	if inv == null:
		return null
	var existing := inv.get_node_or_null(NODE_NAME) as ItemActives
	if existing:
		return existing
	var node := ItemActives.new()
	node.name = NODE_NAME
	node.inventory = inv
	inv.add_child(node)
	return node


## Uses the active / consumable in `slot`. See the class doc for the reasons.
static func use(inv: Node, slot: int, target: Variant = null) -> String:
	var node := for_inventory(inv)
	if node == null:
		return "Empty slot"
	return node.use_slot(slot, target)


## `"none"`, `"self"` or `"point"`: how the UI targets this item (point = the spell targeting flow).
static func target_kind(type: Object) -> String:
	var key := effect_key(type)
	if key == &"":
		return "none"
	return String(ACTIVES[key]["target"])


## The effect key of an item (`&"brace"`, `&"ember_draught"`...), `&""` when it has no active.
static func effect_key(type: Object) -> StringName:
	if type == null:
		return &""
	for raw: Variant in [type.get("active_id"), type.get("id")]:
		if raw == null:
			continue
		var k := StringName(str(raw).to_lower().strip_edges().replace(" ", "_").replace("'", ""))
		if k == &"":
			continue
		if ACTIVES.has(k):
			return k
		if ALIASES.has(k):
			return ALIASES[k]
	return &""


## Tooltip data: `{target, cooldown, group, consumable}` plus the effect numbers; empty if no active.
static func active_info(type: Object) -> Dictionary:
	var key := effect_key(type)
	return (ACTIVES[key] as Dictionary).duplicate() if key != &"" else {}


# ---------------------------------------------------------------- by id (champions, champions.md 7)

## Uses the carried item `item_id` (an item id like `&"ember_draught"` / `&"ashen_greaves"`, or an
## active id like `&"stride"`) without knowing its slot. `""` = used, else `"Dead"`, `"Not carried"`,
## then the `use` reasons (`"Not an active"`, `"Unique"`, `"On cooldown"`, `"Invalid target"`).
## Goes through `Inventory.use_item` when the inventory has it, so `item_used` fires as for a click.
static func use_by_id(inv: Node, item_id: StringName, target: Variant = null) -> String:
	var owner := Recipes.owner_of(inv)
	if owner == null or (owner.has_method(&"is_alive") and not owner.call(&"is_alive")):
		return "Dead"
	var slot := slot_for(inv, item_id)
	if slot < 0:
		return "Not carried"
	if inv.has_method(&"use_item"):
		return str(inv.call(&"use_item", slot, target))
	return use(inv, slot, target)


## What `use_by_id` would answer now, without using anything (`""` = ready). Point targets are not
## checked. For brains: "an Ember Draught is ready" = `check_by_id(inv, &"ember_draught") == ""`.
static func check_by_id(inv: Node, item_id: StringName) -> String:
	var owner := Recipes.owner_of(inv)
	if owner == null or (owner.has_method(&"is_alive") and not owner.call(&"is_alive")):
		return "Dead"
	var slot := slot_for(inv, item_id)
	if slot < 0:
		return "Not carried"
	var node := for_inventory(inv)
	if node == null:
		return "Not carried"
	return node.check_slot(slot)


## Slot (0-based into `inventory.slots`) of the carried item `item_id` (item id first, else the first
## slot whose active is `item_id`, preferring the copy that is not shadowed by a stronger one); -1.
static func slot_for(inv: Node, item_id: StringName) -> int:
	if inv == null:
		return -1
	var slots: Variant = inv.get("slots")
	if not slots is Array:
		return -1
	for i in (slots as Array).size():
		if Recipes.id_of(Recipes.type_in((slots as Array)[i])) == item_id:
			return i
	var key: StringName = ALIASES.get(item_id, item_id)
	if not ACTIVES.has(key):
		return -1
	var first := -1
	var node := inv.get_node_or_null(NODE_NAME) as ItemActives
	for i in (slots as Array).size():
		if effect_key(Recipes.type_in((slots as Array)[i])) != key:
			continue
		if node == null or not node._is_shadowed(i, key):
			return i
		if first < 0:
			first = i
	return first


## Champion shortcut: drink an Ember Draught (heals 150 over 8 s, shared 20 s potion cooldown).
static func drink_potion(inv: Node) -> String:
	return use_by_id(inv, &"ember_draught")


## Champion shortcut: Stride from Ashen Greaves (+2.5 move speed for 4 s, cooldown 40 x CDR).
static func use_stride(inv: Node) -> String:
	return use_by_id(inv, &"stride")


## Instance dry run of `use_slot` (no effect, no target check). `""` = it would fire.
func check_slot(slot: int) -> String:
	if wizard == null:
		wizard = Recipes.owner_of(inventory)
	if wizard == null or (wizard.has_method(&"is_alive") and not wizard.call(&"is_alive")):
		return "Dead"
	var type := Recipes.type_in(_entry(slot))
	if type == null:
		return "Empty slot"
	var key := effect_key(type)
	if key == &"":
		return "Not an active"
	var data: Dictionary = ACTIVES[key]
	if not data.get("consumable", false) and _is_shadowed(slot, key):
		return "Unique"
	if float(_cooldowns.get(data["group"], 0.0)) > 0.0 or not _channel.is_empty():
		return "On cooldown"
	if key == &"owl_stone":
		return "Not available yet"
	return ""


func _ready() -> void:
	if inventory == null:
		inventory = get_parent()
	wizard = Recipes.owner_of(inventory)
	if wizard and wizard.has_signal(&"respawned"):
		wizard.connect(&"respawned", _on_wizard_respawned)


## Instance form of `use`.
func use_slot(slot: int, target: Variant = null) -> String:
	if wizard == null:
		wizard = Recipes.owner_of(inventory)
	if wizard == null or (wizard.has_method(&"is_alive") and not wizard.call(&"is_alive")):
		return "Dead"
	var entry: Variant = _entry(slot)
	var type := Recipes.type_in(entry)
	if type == null:
		return "Empty slot"
	var key := effect_key(type)
	if key == &"":
		return "Not an active"
	var data: Dictionary = ACTIVES[key]
	if not data.get("consumable", false) and _is_shadowed(slot, key):
		return "Unique"
	var group: StringName = data["group"]
	if float(_cooldowns.get(group, 0.0)) > 0.0:
		return "On cooldown"
	if not _channel.is_empty():
		return "On cooldown"   # a Homeward Seal is channelling
	var point := Vector3.INF
	if data["target"] == "point":
		point = _point_of(target)
		if point == Vector3.INF:
			return "Invalid target"
		if key == &"owl_stone":
			if _flat(point - _wizard_pos()).length() > float(data["range"]) + 0.01:
				return "Invalid target"
			return "Not available yet"   # Owl Stone needs fog of war (wave 5)
	match key:
		&"stride":
			_start_stride(float(data["speed"]), float(data["duration"]))
		&"brace", &"brace_ii":
			_add_shield(float(data["shield"]), float(data["duration"]))
		&"blink":
			_blink(point, float(data["range"]))
		&"rallying_cry":
			_rallying_cry(float(data["radius"]), float(data["heal"]), float(data["duration"]))
		&"glacier_shell":
			_glacier_shell(float(data["duration"]))
		&"overgrowth":
			_overgrowth(float(data["radius"]), float(data["heal"]), float(data["duration"]))
		&"ember_draught":
			_add_hot(wizard, "hp", float(data["heal"]), float(data["duration"]))
		&"dusk_vial":
			_add_hot(wizard, "mana", float(data["mana"]), float(data["duration"]))
		&"homeward_seal":
			if _home_point() == Vector3.INF:
				return "Invalid target"
			_start_channel(entry, type, float(data["channel"]))
			used.emit(slot, type as Resource)
			return ""   # the charge and the cooldown are taken when the channel ends
	_start_cooldown(group, _cooldown_for(type, data), slot)
	if data.get("consumable", false):
		_consume_charge(slot)
	used.emit(slot, type as Resource)
	return ""


## Seconds before the item in `slot` can be used again (0 = ready or no active).
func cooldown_left(slot: int) -> float:
	var key := effect_key(Recipes.type_in(_entry(slot)))
	if key == &"":
		return 0.0
	return float(_cooldowns.get(ACTIVES[key]["group"], 0.0))


## Length of the running cooldown of `slot` (for the UI overlay ratio), 0 when none.
func cooldown_total(slot: int) -> float:
	var key := effect_key(Recipes.type_in(_entry(slot)))
	if key == &"" or cooldown_left(slot) <= 0.0:
		return 0.0
	return float(_cooldown_totals.get(ACTIVES[key]["group"], 0.0))


## Charges left in `slot` (1 for non-stacking items, 0 when empty).
func charges(slot: int) -> int:
	var entry: Variant = _entry(slot)
	if Recipes.type_in(entry) == null:
		return 0
	return int((entry as Dictionary).get("count", 1)) if entry is Dictionary else 1


func is_channeling() -> bool:
	return not _channel.is_empty()


## 0-1 progress of the Homeward Seal channel (0 when none).
func channel_progress() -> float:
	if _channel.is_empty():
		return 0.0
	return 1.0 - float(_channel["left"]) / float(_channel["total"])


## Stops a channel; the seal is kept and no cooldown starts.
func cancel_channel() -> void:
	if _channel.is_empty():
		return
	_channel = {}
	channel_ended.emit(false)


## Remaining fallback shield (0 when the gameplay `add_shield` hook handles shields).
func fallback_shield() -> float:
	return float(_shield.get("amount", 0.0))


func _process(delta: float) -> void:
	for group: StringName in _cooldowns.keys():
		var left := float(_cooldowns[group]) - delta
		if left <= 0.0:
			_cooldowns.erase(group)
		else:
			_cooldowns[group] = left
	_tick_hots(delta)
	if _stride_left > 0.0:
		_stride_left -= delta
		if _stride_left <= 0.0 and is_instance_valid(wizard) and wizard.has_method(&"remove_modifier"):
			wizard.call(&"remove_modifier", STRIDE_MOD)
	_tick_shield(delta)
	if _shell_left > 0.0:
		_shell_left -= delta
	_tick_channel(delta)
	_mirror_cooldowns()


# ---------------------------------------------------------------- effects

func _start_stride(speed: float, duration: float) -> void:
	if wizard.has_method(&"add_modifier"):
		wizard.call(&"add_modifier", STRIDE_MOD, {&"move_speed": speed})
		_stride_left = duration


func _add_shield(amount: float, duration: float) -> void:
	if wizard.has_method(&"add_shield"):
		wizard.call(&"add_shield", amount, duration)
		return
	# Fallback: damage taken while the shield lasts is healed back, up to `amount`.
	_shield = {"amount": amount, "left": duration, "last_hp": float(wizard.get("hp"))}


func _blink(point: Vector3, reach: float) -> void:
	var w := wizard as Node3D
	var origin := w.global_position
	var offset := _flat(point - origin)
	if offset.length() > reach:
		offset = offset.normalized() * reach
	var dest := origin + offset
	var map := w.get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) > 0:
		var on_mesh := NavigationServer3D.map_get_closest_point(map, dest)
		if _flat(on_mesh - origin).length() <= reach + 0.01:
			dest = on_mesh
		else:
			dest = origin + _flat(on_mesh - origin).normalized() * reach
			dest.y = on_mesh.y
	w.global_position = dest
	if w.has_method(&"command_stop"):
		w.call(&"command_stop")


func _rallying_cry(radius: float, amount: float, duration: float) -> void:
	var w := wizard as Node3D
	var team: Variant = w.get("team")
	for node: Node in w.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u == w or u.is_in_group(&"heroes") or u.get("team") != team:
			continue
		if u.has_method(&"is_worker") and u.call(&"is_worker"):
			continue
		if u.has_method(&"is_alive") and not u.call(&"is_alive"):
			continue
		if _flat(u.global_position - w.global_position).length() <= radius:
			_add_hot(u, "hp", amount, duration)


## Overgrowth: every living friendly unit (wizard included) whose centre is within `radius` heals
## `amount` over `duration`. Buildings are not units and are skipped.
func _overgrowth(radius: float, amount: float, duration: float) -> void:
	var w := wizard as Node3D
	var team: Variant = w.get("team")
	for node: Node in w.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u.get("team") != team or not u.has_method(&"heal"):
			continue
		if u.has_method(&"is_alive") and not u.call(&"is_alive"):
			continue
		if _flat(u.global_position - w.global_position).length() <= radius:
			_add_hot(u, "hp", amount, duration)


## Glacier Shell: `frozen` for `duration` (no move / attack / cast, orders resume) and no damage taken.
## Wizards get half of a `frozen` duration (kingdom-ice.md 2.1), so the freeze is topped up to the full
## shell. No damage: the gameplay status `glacier_shell` when Unit has it, else every hit taken during
## the shell is healed back from `damage_taken`, which Unit emits before its death check.
func _glacier_shell(duration: float) -> void:
	_shell_left = duration
	if wizard.has_signal(&"damage_taken") and not wizard.is_connected(&"damage_taken", _on_shell_damage):
		wizard.connect(&"damage_taken", _on_shell_damage)
	if not wizard.has_method(&"apply_status"):
		return
	if wizard is Unit and Unit.STATUSES.has(SHELL_STATUS):
		wizard.call(&"apply_status", SHELL_STATUS, duration)
	wizard.call(&"apply_status", &"frozen", duration)
	if wizard.has_method(&"status_time_left"):
		var got := float(wizard.call(&"status_time_left", &"frozen"))
		if got > 0.0 and got < duration - 0.01:
			wizard.call(&"apply_status", &"frozen", duration * duration / got)


## Seconds of Glacier Shell left (0 = none).
func shell_time_left() -> float:
	return maxf(0.0, _shell_left)


func _on_shell_damage(amount: float, _attacker: Node3D) -> void:
	if _shell_left > 0.0 and amount > 0.0 and is_instance_valid(wizard) and wizard.has_method(&"heal"):
		wizard.call(&"heal", amount)


func _add_hot(unit: Node, kind: String, amount: float, duration: float) -> void:
	_hots.append({"unit": unit, "kind": kind, "per_sec": amount / duration, "left": duration})


func _tick_hots(delta: float) -> void:
	for i in range(_hots.size() - 1, -1, -1):
		var h: Dictionary = _hots[i]
		var unit: Node = h["unit"]
		var dt := minf(delta, float(h["left"]))
		h["left"] = float(h["left"]) - delta
		var alive: bool = is_instance_valid(unit) \
				and (not unit.has_method(&"is_alive") or bool(unit.call(&"is_alive")))
		if alive:
			var amount := float(h["per_sec"]) * dt
			if h["kind"] == "hp":
				unit.call(&"heal", amount)
			elif unit.get("mana") != null:
				var cap: Variant = unit.get("max_mana")
				var m := float(unit.get("mana")) + amount
				unit.set("mana", minf(m, float(cap)) if cap != null else m)
		if not alive or float(h["left"]) <= 0.0:
			_hots.remove_at(i)


func _tick_shield(delta: float) -> void:
	if _shield.is_empty() or not is_instance_valid(wizard):
		return
	var hp := float(wizard.get("hp"))
	var lost := float(_shield["last_hp"]) - hp
	if lost > 0.0 and wizard.call(&"is_alive"):
		var absorb := minf(lost, float(_shield["amount"]))
		wizard.call(&"heal", absorb)
		_shield["amount"] = float(_shield["amount"]) - absorb
	_shield["last_hp"] = float(wizard.get("hp"))
	_shield["left"] = float(_shield["left"]) - delta
	if float(_shield["left"]) <= 0.0 or float(_shield["amount"]) <= 0.0:
		_shield = {}


func _start_channel(entry: Variant, type: Object, seconds: float) -> void:
	if wizard.has_method(&"command_stop"):
		wizard.call(&"command_stop")
	_channel = {"left": seconds, "total": seconds, "entry": entry, "id": Recipes.id_of(type),
			"pos": _wizard_pos(), "hp": float(wizard.get("hp"))}
	channel_started.emit(seconds)


func _tick_channel(delta: float) -> void:
	if _channel.is_empty():
		return
	if not is_instance_valid(wizard) or not wizard.call(&"is_alive"):
		cancel_channel()
		return
	var hp := float(wizard.get("hp"))
	var moved := _flat(_wizard_pos() - (_channel["pos"] as Vector3)).length() > CHANNEL_MOVE_TOLERANCE
	var steering := wizard.has_method(&"get_move_input") \
			and (wizard.call(&"get_move_input") as Vector3) != Vector3.ZERO
	if hp < float(_channel["hp"]) - 0.001 or moved or steering:
		cancel_channel()
		return
	_channel["hp"] = hp
	_channel["left"] = float(_channel["left"]) - delta
	if float(_channel["left"]) > 0.0:
		return
	var home := _home_point()
	var slot := _slot_of(_channel["entry"], _channel["id"])
	_channel = {}
	if home == Vector3.INF:
		channel_ended.emit(false)
		return
	(wizard as Node3D).global_position = home
	if wizard.has_method(&"command_stop"):
		wizard.call(&"command_stop")
	var type := Recipes.type_in(_entry(slot))
	_start_cooldown(&"homeward_seal", _cooldown_for(type, ACTIVES[&"homeward_seal"]), slot)
	if slot >= 0:
		_consume_charge(slot)
	channel_ended.emit(true)


# ---------------------------------------------------------------- helpers

func _entry(slot: int) -> Variant:
	if inventory == null:
		return null
	var slots: Variant = inventory.get("slots")
	if not slots is Array or slot < 0 or slot >= (slots as Array).size():
		return null
	return (slots as Array)[slot]


## Where the entry of a channel is now (it may have been swapped), else a slot with the same id.
func _slot_of(entry: Variant, id: StringName) -> int:
	var slots: Variant = inventory.get("slots") if inventory else null
	if not slots is Array:
		return -1
	for i in (slots as Array).size():
		if is_same((slots as Array)[i], entry) and entry != null:
			return i
	for i in (slots as Array).size():
		if Recipes.id_of(Recipes.type_in((slots as Array)[i])) == id:
			return i
	return -1


## True when another slot carries the same active with a higher rank, or the same rank earlier.
func _is_shadowed(slot: int, key: StringName) -> bool:
	var slots: Variant = inventory.get("slots")
	if not slots is Array:
		return false
	var group: StringName = ACTIVES[key]["group"]
	var rank := int(ACTIVES[key].get("rank", 1))
	for i in (slots as Array).size():
		if i == slot:
			continue
		var other := effect_key(Recipes.type_in((slots as Array)[i]))
		if other == &"" or ACTIVES[other]["group"] != group:
			continue
		var r := int(ACTIVES[other].get("rank", 1))
		if r > rank or (r == rank and i < slot):
			return true
	return false


func _cooldown_for(type: Object, data: Dictionary) -> float:
	var base := float(data["cooldown"])
	if type != null and type.get("active_cooldown") != null and float(type.get("active_cooldown")) > 0.0:
		base = float(type.get("active_cooldown"))
	if data.get("consumable", false):
		return base   # consumables ignore cooldown reduction
	var cdr := 0.0
	if wizard.has_method(&"get_stat"):
		cdr = clampf(float(wizard.call(&"get_stat", &"cooldown_reduction")), 0.0, 40.0)
	return base * (1.0 - cdr / 100.0)


## Starts the cooldown of `group`; the Inventory's own per-slot timer too when it has one.
func _start_cooldown(group: StringName, seconds: float, slot: int) -> void:
	if seconds <= 0.0:
		return
	_cooldowns[group] = seconds
	_cooldown_totals[group] = seconds
	if slot >= 0 and inventory.has_method(&"start_cooldown"):
		inventory.call(&"start_cooldown", slot, seconds)
	cooldown_started.emit(group, seconds)


func _consume_charge(slot: int) -> void:
	if inventory.has_method(&"consume_charge"):
		inventory.call(&"consume_charge", slot)
		return
	var entry: Variant = _entry(slot)
	var count := int((entry as Dictionary).get("count", 1)) - 1 if entry is Dictionary else 0
	if count <= 0:
		if inventory.has_method(&"remove_item"):
			inventory.call(&"remove_item", slot)
		else:
			(inventory.get("slots") as Array)[slot] = null
			_notify_changed()
	else:
		(entry as Dictionary)["count"] = count
		_notify_changed()


func _notify_changed() -> void:
	for s: Dictionary in inventory.get_signal_list():
		if s["name"] == "inventory_changed" and (s["args"] as Array).is_empty():
			inventory.emit_signal(&"inventory_changed")
			return


## Keeps `cooldown_left` of active items up to date in inventories without their own timers.
func _mirror_cooldowns() -> void:
	if not is_instance_valid(inventory) or inventory.has_method(&"start_cooldown"):
		return
	var slots: Variant = inventory.get("slots")
	if not slots is Array:
		return
	for i in (slots as Array).size():
		var e: Variant = (slots as Array)[i]
		if e is Dictionary and effect_key(Recipes.type_in(e)) != &"":
			(e as Dictionary)["cooldown_left"] = cooldown_left(i)


## The own keep's spawn point, else the oldest barracks'; Vector3.INF when there is none.
func _home_point() -> Vector3:
	var tree := get_tree()
	var scene := tree.current_scene
	var team := int(wizard.get("team"))
	if scene and scene.has_method(&"respawn_point"):
		return scene.call(&"respawn_point", team) as Vector3
	var fallback := Vector3.INF
	for node: Node in tree.get_nodes_in_group(&"buildings"):
		if node.get("team") == null or int(node.get("team")) != team or not node.has_method(&"spawn_point"):
			continue
		if node.has_method(&"is_alive") and not node.call(&"is_alive"):
			continue
		if node is Keep:
			return node.call(&"spawn_point") as Vector3
		if fallback == Vector3.INF:
			fallback = node.call(&"spawn_point") as Vector3
	return fallback


func _point_of(target: Variant) -> Vector3:
	if target is Vector3:
		return target as Vector3
	if is_instance_valid(target) and target is Node3D:
		return (target as Node3D).global_position
	return Vector3.INF


func _wizard_pos() -> Vector3:
	return (wizard as Node3D).global_position if wizard is Node3D else Vector3.ZERO


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _on_wizard_respawned(_w: Variant) -> void:
	for group: StringName in CONSUMABLE_GROUPS:
		_cooldowns.erase(group)
	_channel = {}
	_hots.clear()
	_shell_left = 0.0
