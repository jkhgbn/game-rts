class_name Inventory
extends Node
## A hero's items (docs/design/items.md): a child named "Inventory" of each wizard or champion; create it
## with `Inventory.ensure_for(owner)`.
## Per owner (champions.md 7 / 13): wizards 6 item slots + 2 artifact slots, champions 4 + 0.
## A champion is an owner in group "champions" or with a `purse` property; an owner may also set
## `slot_count` / `artifact_count` itself before the inventory is used (that wins over the detection).
## Slot indexes: 0..slot_count-1 = item slots (`slots`), 6-7 = artifact slots (`artifacts[0..1]`, see
## ARTIFACT_SLOT; they keep their index whatever slot_count is).
## Each entry is `null` or `{ "type": ItemType, "count": int, "cooldown_left": float }`.
## Item stats go through the Stats contract only: modifier `item:1`..`item:6`, `item:artifact_1/2`,
## re-applied on every change, with the items.md caps on the total from items.
## Purse owners (champions): `can_buy` / `buy` pay from the owner's purse (`purse`, `spend_purse(n)`,
## `add_purse(n)`) instead of the team bank, and 20 % of each price goes to the team's EssenceBank as a
## tithe (message `Tithe from <name>: N`, at most once per 10 s, summed). Champions never sell.

signal inventory_changed
signal item_used(slot: int, type: ItemType)
signal item_bought(type: ItemType)
signal item_sold(slot: int, type: ItemType, essence: int)
signal item_dropped(slot: int, type: ItemType, pickup: Node3D)
## A purse purchase credited `amount` essence to the team bank (every purchase, not throttled).
signal tithe_paid(amount: int)
## The throttled tithe line (`Tithe from Sable Quint: 40`), at most once per TITHE_MESSAGE_INTERVAL.
## Shown on the HUD too when the owner is on the local (PLAYER) team.
signal tithe_announced(text: String, amount: int)
## A campaign artifact's power was used (use_artifact_power; mission-e3-03.md D4): the mission applies the effect and
## drives its meter from this signal.
signal artifact_power_used(item_id: StringName)

const REASON_RECHARGING := "Recharging"
## Optional mission gate for artifact powers: `func(item_id: StringName) -> String` ("" = allowed, else the refusal,
## e.g. "The stone holds you"). Invalid = no gate.
var artifact_power_gate: Callable

const SLOT_COUNT := 6             ## Wizard item slots (the default).
const ARTIFACT_COUNT := 2         ## Wizard artifact slots (the default).
const CHAMPION_SLOT_COUNT := 4
const CHAMPION_ARTIFACT_COUNT := 0
const ARTIFACT_SLOT := 6          ## Slot index of artifact slot 1 (artifact slot 2 = 7).
const SHOP_RANGE := 12.0
const SELL_RATIO := 0.5
const TITHE_RATIO := 0.2          ## champions.md 7: 20 % of a purse purchase goes to the team bank.
const TITHE_MESSAGE_INTERVAL := 10.0
const WISHLIST_KEEP_ID := &"ember_draught"   ## After the wish list ends: keep 1 in stock.
const RECIPES_PATH := "res://scripts/items/recipes.gd"
const ACTIVES_PATH := "res://scripts/items/item_actives.gd"
## Caps on the total of each stat from items (items.md "Stats used by items"). Negative = a floor.
const STAT_CAPS := {
	&"hp_regen": 12.0, &"mana_regen": 6.0, &"attack_cooldown_pct": -0.35, &"move_speed": 2.5,
	&"armor": 150.0, &"spell_power": 60.0, &"cooldown_reduction": 40.0,   # spell_power cap: balance-1
}

## `slot_count` entries, `null` or `{type, count, cooldown_left}`.
var slots: Array = []
## `artifact_count` entries, same shape (artifacts only). Artifact slot 1 holds the Ember Crown.
var artifacts: Array = []
## The hero carrying this inventory (the parent): a wizard or a champion.
var wizard: Node3D
## Item slots of this owner (6 wizards, 4 champions). Setting it (before items are added) resizes
## `slots`; items in removed slots are lost.
var slot_count: int:
	get:
		return _slot_count
	set(value):
		_counts_explicit = true
		_set_counts(value, _artifact_count)
## Artifact slots of this owner (2 wizards, 0 champions: they never carry artifacts or the Crown).
var artifact_count: int:
	get:
		return _artifact_count
	set(value):
		_counts_explicit = true
		_set_counts(_slot_count, value)

var _slot_count := SLOT_COUNT
var _artifact_count := ARTIFACT_COUNT
var _counts_explicit := false     # the owner set the counts: the champion detection leaves them alone
var _applied: Dictionary = {}     # StringName modifier id -> Dictionary stats last applied
var _passives: Dictionary = {}    # StringName slot source id -> StringName passive id attached
const ITEM_PASSIVES_PATH := "res://scripts/units/item_passives.gd"
var _ticking := false
var _tithe_pending := 0           # tithe not announced yet (summed while the message cools down)
var _tithe_cooling := false       # a tithe message went out less than TITHE_MESSAGE_INTERVAL ago


## The owner's Inventory, created (as the child "Inventory") if missing. Champions get 4 + 0 slots.
static func ensure_for(owner_wizard: Node) -> Inventory:
	if owner_wizard == null:
		return null
	var existing := owner_wizard.get_node_or_null(^"Inventory") as Inventory
	if existing:
		return existing
	var inv := Inventory.new()
	inv.name = "Inventory"
	inv.wizard = owner_wizard as Node3D
	inv._configure_for_owner()
	owner_wizard.add_child(inv)
	if &"inventory" in owner_wizard:
		owner_wizard.set(&"inventory", inv)
	return inv


func _init() -> void:
	slots.resize(SLOT_COUNT)
	artifacts.resize(ARTIFACT_COUNT)


func _ready() -> void:
	if wizard == null:
		wizard = get_parent() as Node3D
	_configure_for_owner()
	set_process(false)
	if wizard:
		EssenceBank.for_team(team())   # the bank starts its trickle as soon as a wizard exists


## Sets both counts at once (items 0-6, artifacts 0-2) and marks them as chosen by the owner.
func set_slot_counts(items: int, artifact_slots: int) -> void:
	_counts_explicit = true
	_set_counts(items, artifact_slots)


## True when the owner is a champion (group "champions" or a `purse` property).
func is_champion_owner() -> bool:
	return wizard != null and is_instance_valid(wizard) \
			and (wizard.is_in_group(&"champions") or wizard.get(&"purse") != null)


## True when purchases are paid from the owner's purse (the owner has a `purse` property).
func uses_purse() -> bool:
	return wizard != null and is_instance_valid(wizard) and wizard.get(&"purse") != null


## The money this inventory buys with: the owner's purse for champions, else the team's essence.
func funds() -> int:
	if uses_purse():
		return int(wizard.get(&"purse"))
	var b := bank()
	return b.essence if b else 0


## False for champions (they never sell; dismiss pays the team instead).
func can_sell() -> bool:
	return not is_champion_owner()


func _process(delta: float) -> void:
	var any := false
	for e: Variant in slots + artifacts:
		if e is Dictionary and float(e["cooldown_left"]) > 0.0:
			e["cooldown_left"] = maxf(0.0, float(e["cooldown_left"]) - delta)
			any = true
	if not any:
		set_process(false)


# ---------------------------------------------------------------- queries

func team() -> int:
	return int(wizard.get(&"team")) if wizard and wizard.get(&"team") != null else 0


func bank() -> EssenceBank:
	return EssenceBank.for_team(team())


## The entry at `slot` (0..slot_count-1 items, 6-7 artifacts), or null.
func get_entry(slot: int) -> Variant:
	if slot >= 0 and slot < slots.size():
		return slots[slot]
	if slot >= ARTIFACT_SLOT and slot < ARTIFACT_SLOT + artifacts.size():
		return artifacts[slot - ARTIFACT_SLOT]
	return null


func get_type(slot: int) -> ItemType:
	var e: Variant = get_entry(slot)
	return e["type"] as ItemType if e is Dictionary else null


## Seconds left on the item cooldown of `slot` (0 when ready or empty).
func cooldown_left(slot: int) -> float:
	var e: Variant = get_entry(slot)
	return float(e["cooldown_left"]) if e is Dictionary else 0.0


func free_slots() -> int:
	var n := 0
	for e: Variant in slots:
		if e == null:
			n += 1
	return n


## Slot index of the first carried item with this id (item slots, then artifacts), or -1.
func find_slot(item_id: StringName) -> int:
	for slot in _all_slot_indexes():
		var t := get_type(slot)
		if t and t.id == item_id:
			return slot
	return -1


## Item slot indexes then artifact slot indexes (0..slot_count-1, 6..6+artifact_count-1).
func _all_slot_indexes() -> Array[int]:
	var order: Array[int] = []
	for i in slots.size():
		order.append(i)
	for i in artifacts.size():
		order.append(ARTIFACT_SLOT + i)
	return order


func has_item(item_id: StringName) -> bool:
	return find_slot(item_id) >= 0


## Sum of the total cost of every carried item (x charges for consumables). Artifacts count 0.
func total_item_value() -> int:
	var total := 0
	for e: Variant in slots + artifacts:
		if e is Dictionary:
			total += (e["type"] as ItemType).total_cost() * int(e["count"])
	return total


func _is_alive() -> bool:
	return wizard != null and is_instance_valid(wizard) and (not wizard.has_method(&"is_alive")
			or bool(wizard.call(&"is_alive")))


# ---------------------------------------------------------------- add / remove

## Adds `count` of `type`: artifacts go to the first free artifact slot, consumables merge into
## existing stacks first, the rest into the first free item slots. False (nothing added) if it can't fit.
func add_item(type: ItemType, count: int = 1, cooldown_left: float = 0.0) -> bool:
	if type == null or count <= 0:
		return false
	if type.is_artifact:
		for i in artifacts.size():   # champions have none: they never take an artifact
			if artifacts[i] == null:
				artifacts[i] = _entry(type, 1, cooldown_left)
				_changed()
				return true
		return false
	var stack_max := maxi(1, type.stack_max)
	# Room check first so a refused add changes nothing.
	var room := 0
	for e: Variant in slots:
		if e == null:
			room += stack_max
		elif stack_max > 1 and (e["type"] as ItemType).id == type.id:
			room += stack_max - int(e["count"])
	if room < count:
		return false
	var left := count
	if stack_max > 1:
		for e: Variant in slots:
			if left > 0 and e is Dictionary and (e["type"] as ItemType).id == type.id:
				var put := mini(left, stack_max - int(e["count"]))
				e["count"] = int(e["count"]) + put
				left -= put
	for i in slots.size():
		if left <= 0:
			break
		if slots[i] == null:
			var put := mini(left, stack_max)
			slots[i] = _entry(type, put, cooldown_left)
			left -= put
	_changed()
	return true


## Empties `slot` (0-5, or 6-7 for artifacts) and returns what was there (null if empty).
func remove_item(slot: int) -> ItemType:
	var t := get_type(slot)
	if t == null:
		return null
	_set_entry(slot, null)
	_changed()
	return t


## Uses one charge of the consumable in `slot`; the last charge frees the slot. For ItemActives.
func consume_charge(slot: int) -> void:
	var e: Variant = get_entry(slot)
	if not e is Dictionary:
		return
	e["count"] = int(e["count"]) - 1
	if int(e["count"]) <= 0:
		_set_entry(slot, null)
	_changed()


## Starts the cooldown of `slot` (and of every item sharing its `cooldown_group`). For ItemActives.
func start_cooldown(slot: int, seconds: float) -> void:
	var t := get_type(slot)
	if t == null or seconds <= 0.0:
		return
	for e: Variant in slots + artifacts:
		if e is Dictionary:
			var other := e["type"] as ItemType
			if other.id == t.id \
					or (t.cooldown_group != &"" and other.cooldown_group == t.cooldown_group):
				e["cooldown_left"] = maxf(float(e["cooldown_left"]), seconds)
	set_process(true)


## Clears every item cooldown of consumables (respawn rule).
func reset_consumable_cooldowns() -> void:
	for e: Variant in slots:
		if e is Dictionary and (e["type"] as ItemType).is_consumable():
			e["cooldown_left"] = 0.0


## Swaps two item slots (0..slot_count-1). Works while dead. Artifact slots never swap with item slots.
func swap(a: int, b: int) -> void:
	if a == b or a < 0 or b < 0:
		return
	if a < slots.size() and b < slots.size():
		var tmp: Variant = slots[a]
		slots[a] = slots[b]
		slots[b] = tmp
	elif a >= ARTIFACT_SLOT and b >= ARTIFACT_SLOT and a < ARTIFACT_SLOT + artifacts.size() \
			and b < ARTIFACT_SLOT + artifacts.size():
		var tmp2: Variant = artifacts[a - ARTIFACT_SLOT]
		artifacts[a - ARTIFACT_SLOT] = artifacts[b - ARTIFACT_SLOT]
		artifacts[b - ARTIFACT_SLOT] = tmp2
	else:
		return
	_changed()


# ---------------------------------------------------------------- use

## Uses the active / consumable in `slot`. `""` = ok, else `"Dead"`, `"Empty slot"`, `"Not an active"`,
## `"On cooldown"`, `"Invalid target"` (the effect itself lives in ItemActives).
func use_item(slot: int, target: Variant = null) -> String:
	if not _is_alive():
		return "Dead"
	var e: Variant = get_entry(slot)
	if not e is Dictionary:
		return "Empty slot"
	var t := e["type"] as ItemType
	if not t.has_active():
		return "Not an active"
	if float(e["cooldown_left"]) > 0.0:
		return "On cooldown"
	if t.active_target == ItemType.Target.POINT and not target is Vector3 and not target is Node3D:
		return "Invalid target"
	var actives := _script(ACTIVES_PATH)
	if actives == null:
		return "Not an active"
	var result: Variant = null
	for method: StringName in [&"use", &"use_item", &"activate"]:
		if actives.has_method(method):
			result = actives.call(method, self, slot, target)
			break
	if result == null:
		return "Not an active"
	var reason := str(result)
	if reason == "":
		item_used.emit(slot, t)
	return reason


## Uses the power of the artifact in artifact slot `index` (0 = slot 1): "" = used (emits artifact_power_used, the
## artifact's `active_cooldown` starts), else "Dead", "Empty slot", the mission gate's refusal, or "Recharging".
## The effect itself belongs to the mission listening to the signal.
func use_artifact_power(index: int = 0) -> String:
	if not _is_alive():
		return "Dead"
	var slot := ARTIFACT_SLOT + index
	var t := get_type(slot)
	if t == null or index < 0 or index >= artifacts.size():
		return "Empty slot"
	if artifact_power_gate.is_valid():
		var gate := str(artifact_power_gate.call(t.id))
		if gate != "":
			return gate
	if cooldown_left(slot) > 0.0:
		return REASON_RECHARGING
	if t.active_cooldown > 0.0:
		start_cooldown(slot, t.active_cooldown)
	artifact_power_used.emit(t.id)
	return ""


# ---------------------------------------------------------------- shops

## The nearest shop within 12 m: a building of the wizard's team answering `is_shop()` (keep, barracks;
## before shops exist: completed drop-off buildings) or a neutral peddler (group `"shops"`). Else null.
func nearest_shop() -> Node:
	if wizard == null or not wizard.is_inside_tree():
		return null
	var best: Node = null
	var best_d := SHOP_RANGE
	var pos := wizard.global_position
	for node in _shop_candidates():
		var n3 := node as Node3D
		if n3 == null or not _is_shop(n3):
			continue
		var d := Vector2(n3.global_position.x - pos.x, n3.global_position.z - pos.z).length()
		if d <= best_d:
			best_d = d
			best = n3
	return best


func _shop_candidates() -> Array:
	var tree := get_tree()
	var out: Array = tree.get_nodes_in_group("buildings")
	for s in tree.get_nodes_in_group("shops"):
		if not out.has(s):
			out.append(s)
	return out


func _is_shop(node: Node) -> bool:
	if node.has_method(&"is_alive") and not bool(node.call(&"is_alive")):
		return false
	var shop_team: Variant = node.get(&"team")
	var neutral := node.is_in_group(&"shops") or node.is_in_group(&"peddlers")
	if not neutral and (shop_team == null or int(shop_team) != team()):
		return false
	if node.has_method(&"is_shop"):
		return bool(node.call(&"is_shop"))
	if neutral:
		return true
	# Fallback until the systems-coder adds is_shop(): completed keeps and barracks are drop-offs.
	return node.has_method(&"is_drop_off") and bool(node.call(&"is_drop_off"))


func _shop_bits(shop: Node) -> int:
	if shop == null:
		return 0
	var peddler := shop.is_in_group(&"peddlers") or (shop.has_method(&"is_peddler")
			and bool(shop.call(&"is_peddler"))) or (shop.get(&"team") != null and int(shop.get(&"team")) == 2)
	return ItemType.SOLD_PEDDLER if peddler else ItemType.SOLD_BASE


## What a Buy / Combine click on `type` would do now: `{ok, reason, consume_slots, essence_cost}`.
## Uses Recipes.plan when it exists (4.I2), else the plain price.
func buy_plan(type: ItemType) -> Dictionary:
	var recipes := _script(RECIPES_PATH)
	var plan: Dictionary
	if recipes and recipes.has_method(&"plan"):
		plan = recipes.call(&"plan", self, type, nearest_shop())
	else:
		plan = _plain_plan(type)
	var reason := str(plan.get("reason", ""))
	# Purse owners: Recipes checked the team bank; the purse decides instead (the last reason in order).
	if uses_purse() and (reason == "" or reason == "Not enough essence"):
		reason = "" if funds() >= int(plan.get("essence_cost", 0)) else "Not enough essence"
		plan["reason"] = reason
		plan["ok"] = reason == ""
	# Items waiting for a later wave are never sold (Recipes does not know `available`).
	if type and not type.available and reason in ["", "Inventory full", "Not enough essence"]:
		plan["reason"] = "Not sold here"
		plan["ok"] = false
	return plan


func _plain_plan(type: ItemType) -> Dictionary:
	var consume: Array[int] = []
	var out := {"ok": false, "reason": "", "consume_slots": consume,
			"essence_cost": type.total_cost() if type else 0}
	var shop := nearest_shop()
	var reason := ""
	if type == null:
		reason = "Unknown item"
	elif not _is_alive():
		reason = "Dead"
	elif shop == null:
		reason = "No shop nearby"
	elif not type.is_sold_at(_shop_bits(shop)):
		reason = "Not sold here"
	elif not _fits(type):
		reason = "Inventory full"
	elif funds() < int(out["essence_cost"]):
		reason = "Not enough essence"
	out["reason"] = reason
	out["ok"] = reason == ""
	return out


func _fits(type: ItemType) -> bool:
	if free_slots() > 0:
		return true
	if type.stack_max > 1:
		for e: Variant in slots:
			if e is Dictionary and (e["type"] as ItemType).id == type.id and int(e["count"]) < type.stack_max:
				return true
	return false


## `""` if the owner can buy `type` now, else (in order) `"Dead"`, `"No shop nearby"`,
## `"Not sold here"` (or `"Needs <part> (<where>)"`), `"Inventory full"`, `"Not enough essence"`
## (champions: not enough in the purse).
func can_buy(type: ItemType) -> String:
	return str(buy_plan(type).get("reason", ""))


## Buys (or combines) `type`: pays (team essence, or the owner's purse + 20 % tithe to the team bank),
## consumes the carried parts, adds the item. `""` = ok.
func buy(type: ItemType) -> String:
	var plan := buy_plan(type)
	var reason := str(plan.get("reason", ""))
	if reason != "":
		return reason
	var cost := int(plan.get("essence_cost", type.total_cost()))
	var consume: Array = plan.get("consume_slots", [])
	# Remove the consumed parts first (they free the slot the result needs), put them back on failure.
	var removed := {}
	for s: Variant in consume:
		removed[int(s)] = get_entry(int(s))
		_set_entry(int(s), null)
	if not _pay(cost):
		for s: int in removed:
			_set_entry(s, removed[s])
		return "Not enough essence"
	if not add_item(type):
		for s: int in removed:
			_set_entry(s, removed[s])
		_refund(cost)
		_changed()
		return "Inventory full"
	if uses_purse():
		_pay_tithe(cost)
	item_bought.emit(type)
	return ""


## The tithe a purse purchase of `cost` sends to the team bank (20 %, rounded).
static func tithe_for(cost: int) -> int:
	return maxi(0, roundi(float(cost) * TITHE_RATIO))


## Sells `slot` at a shop in range for 50 % of its total cost (per charge, rounded down) and returns the
## essence gained; 0 if refused (champion owner, dead, no shop, empty, artifact or campaign reward).
func sell(slot: int) -> int:
	var e: Variant = get_entry(slot)
	if not can_sell() or not e is Dictionary or not _is_alive() or nearest_shop() == null:
		return 0
	var t := e["type"] as ItemType
	if t.is_artifact or t.campaign_only or slot >= ARTIFACT_SLOT:
		return 0
	var value := sell_value(slot)
	_set_entry(slot, null)
	_changed()
	bank().add(value)
	item_sold.emit(slot, t, value)
	return value


## What sell(slot) would pay (0 for artifacts / campaign rewards / an empty slot).
func sell_value(slot: int) -> int:
	var e: Variant = get_entry(slot)
	if not e is Dictionary:
		return 0
	var t := e["type"] as ItemType
	if t.is_artifact or t.campaign_only:
		return 0
	return floori(t.total_cost() * SELL_RATIO) * int(e["count"])


## Drops `slot` on the ground at the wizard's feet (an ItemPickup keeping the full stack). Artifacts are
## never dropped by hand. Returns the pickup, or null.
func drop(slot: int) -> ItemPickup:
	var e: Variant = get_entry(slot)
	if not e is Dictionary or slot >= ARTIFACT_SLOT or wizard == null or not wizard.is_inside_tree():
		return null
	var t := e["type"] as ItemType
	if t.is_artifact:
		return null
	_set_entry(slot, null)
	_changed()
	var pickup := ItemPickup.spawn(t, wizard.global_position, int(e["count"]))
	if pickup:
		pickup.ignore_until_left(wizard)
	item_dropped.emit(slot, t, pickup)
	return pickup


# ---------------------------------------------------------------- champion wish list (champions.md 4.4)

## The next wish-list entry this inventory still needs, whether or not it can be bought now. The list is
## bought in order; an entry counts as done while its item is carried, alone or inside a carried
## combine (Blazing Edge covers its Ember Shard and Whetted Fang), each carried copy covering one entry.
## A consumable that was used up is wanted again when its entry is reached. After the list: an Ember
## Draught when none is carried (keep 1), else null. Entries are item ids (String / StringName) or
## ItemTypes; unknown ids are skipped.
func next_wishlist_entry(list: Array) -> ItemType:
	var pool := _owned_pool()
	for raw: Variant in list:
		var t := _as_item_type(raw)
		if t == null:
			continue
		var n := int(pool.get(t.id, 0))
		if n > 0:
			pool[t.id] = n - 1
			continue
		return t
	if find_slot(WISHLIST_KEEP_ID) < 0:
		return ItemType.find(WISHLIST_KEEP_ID)
	return null


## The next wish-list entry when it can be bought right now (`can_buy == ""`: alive, a shop in range,
## room in the 4 slots after its parts are consumed, enough in the purse), else null. In order: an
## entry that cannot be bought blocks the ones after it. Buy it with `buy(type)` (combines consume
## their carried parts through Recipes).
func next_wishlist_buy(list: Array) -> ItemType:
	var t := next_wishlist_entry(list)
	if t == null or can_buy(t) != "":
		return null
	return t


## What the next wish-list entry would cost now (recipe + the parts not carried), 0 when nothing is
## wanted. For the "purse >= next price" shopping check.
func next_wishlist_price(list: Array) -> int:
	var t := next_wishlist_entry(list)
	return int(buy_plan(t).get("essence_cost", 0)) if t else 0


## Item id -> copies carried, counting every part inside carried combines (recursively).
func _owned_pool() -> Dictionary:
	var pool := {}
	for e: Variant in slots:
		if e is Dictionary:
			_pool_add(pool, e["type"] as ItemType, maxi(1, int(e["count"])), 0)
	return pool


func _pool_add(pool: Dictionary, t: ItemType, n: int, depth: int) -> void:
	if t == null or depth > 4:
		return
	pool[t.id] = int(pool.get(t.id, 0)) + n
	for part in t.parts:
		_pool_add(pool, part, n, depth + 1)


static func _as_item_type(raw: Variant) -> ItemType:
	if raw is ItemType:
		return raw as ItemType
	if raw is String or raw is StringName:
		return ItemType.find(StringName(raw))
	return null


# ---------------------------------------------------------------- stat modifiers

static func modifier_id(slot: int) -> StringName:
	if slot >= ARTIFACT_SLOT:
		return StringName("item:artifact_%d" % (slot - ARTIFACT_SLOT + 1))
	return StringName("item:%d" % (slot + 1))


## Re-applies every `item:<slot>` modifier on the wizard (only the ones that changed). Caps: the total
## of a capped stat from items never passes STAT_CAPS (later slots get what is left).
func apply_modifiers() -> void:
	if wizard == null or not wizard.has_method(&"add_modifier"):
		return
	var totals := {}
	var order := _all_slot_indexes()
	for slot in order:
		var t := get_type(slot)
		var stats := {}
		if t:
			for key: Variant in t.stats:
				var k := StringName(str(key))
				var v := float(t.stats[key])
				if STAT_CAPS.has(k):
					var cap := float(STAT_CAPS[k])
					var so_far := float(totals.get(k, 0.0))
					v = maxf(v, cap - so_far) if cap < 0.0 else minf(v, cap - so_far)
					totals[k] = so_far + v
				if v != 0.0:
					stats[k] = v
		var id := modifier_id(slot)
		var last: Variant = _applied.get(id)
		if stats.is_empty():
			if last != null:
				wizard.call(&"remove_modifier", id)
				_applied.erase(id)
		elif last == null or last != stats:
			wizard.call(&"add_modifier", id, stats)
			_applied[id] = stats
	_apply_passives(order)


## Attaches each item's passive (on-hit burn, lifesteal, auras...) through the gameplay ItemPassives
## registry, one source per slot, and detaches the ones whose item left.
func _apply_passives(order: Array[int]) -> void:
	if not ResourceLoader.exists(ITEM_PASSIVES_PATH):
		return
	var passives: Script = load(ITEM_PASSIVES_PATH)
	for slot in order:
		var t := get_type(slot)
		var id := modifier_id(slot)
		var want := StringName(str(t.get(&"passive_id"))) if t and t.get(&"passive_id") else &""
		var had: StringName = _passives.get(id, &"")
		if want == had:
			continue
		if had != &"":
			passives.call(&"detach_source", wizard, id)
			_passives.erase(id)
		if want != &"":
			passives.call(&"attach", wizard, want, id)
			_passives[id] = want


# ---------------------------------------------------------------- private

func _entry(type: ItemType, count: int, cooldown_left: float) -> Dictionary:
	if cooldown_left > 0.0:
		set_process(true)
	return {"type": type, "count": count, "cooldown_left": cooldown_left}


func _set_entry(slot: int, value: Variant) -> void:
	if slot >= 0 and slot < slots.size():
		slots[slot] = value
	elif slot >= ARTIFACT_SLOT and slot < ARTIFACT_SLOT + artifacts.size():
		artifacts[slot - ARTIFACT_SLOT] = value


## Champions get 4 + 0 slots unless the owner already chose the counts.
func _configure_for_owner() -> void:
	if _counts_explicit or not is_champion_owner():
		return
	_set_counts(CHAMPION_SLOT_COUNT, CHAMPION_ARTIFACT_COUNT)


## Resizes the slot arrays. Items in slots that disappear are removed (with their modifiers) first.
func _set_counts(items: int, artifact_slots: int) -> void:
	items = clampi(items, 0, ARTIFACT_SLOT)
	artifact_slots = clampi(artifact_slots, 0, ARTIFACT_COUNT)
	if items == slots.size() and artifact_slots == artifacts.size():
		_slot_count = items
		_artifact_count = artifact_slots
		return
	var lost := false
	for i in range(items, slots.size()):
		lost = lost or slots[i] != null
		slots[i] = null
	for i in range(artifact_slots, artifacts.size()):
		lost = lost or artifacts[i] != null
		artifacts[i] = null
	if lost:
		apply_modifiers()   # still over the old indexes: removes the modifiers of the lost items
	slots.resize(items)
	artifacts.resize(artifact_slots)
	_slot_count = items
	_artifact_count = artifact_slots
	inventory_changed.emit()


## Takes `cost` from the purse (purse owners) or the team bank. False if it is not there.
func _pay(cost: int) -> bool:
	if cost <= 0:
		return true
	if uses_purse():
		if wizard.has_method(&"spend_purse"):
			return bool(wizard.call(&"spend_purse", cost))
		if int(wizard.get(&"purse")) < cost:
			return false
		wizard.set(&"purse", int(wizard.get(&"purse")) - cost)
		return true
	var b := bank()
	return b != null and b.spend(cost)


func _refund(cost: int) -> void:
	if cost <= 0:
		return
	if uses_purse():
		if wizard.has_method(&"add_purse"):
			wizard.call(&"add_purse", cost)
		else:
			wizard.set(&"purse", int(wizard.get(&"purse")) + cost)
	elif bank():
		bank().add(cost)


## Credits the 20 % tithe of a purse purchase to the team bank and queues the message line.
func _pay_tithe(cost: int) -> void:
	var tithe := tithe_for(cost)
	if tithe <= 0:
		return
	var b := bank()
	if b:
		b.add(tithe)
	tithe_paid.emit(tithe)
	_tithe_pending += tithe
	if not _tithe_cooling:
		_announce_tithe()


## Sends the summed tithe line, then holds further lines for TITHE_MESSAGE_INTERVAL (game time).
func _announce_tithe() -> void:
	if _tithe_pending <= 0:
		_tithe_cooling = false
		return
	var amount := _tithe_pending
	_tithe_pending = 0
	var text := "Tithe from %s: %d" % [_owner_name(), amount]
	tithe_announced.emit(text, amount)
	_show_on_hud(text)
	if is_inside_tree():
		_tithe_cooling = true
		get_tree().create_timer(TITHE_MESSAGE_INTERVAL, false).timeout.connect(_announce_tithe)


func _owner_name() -> String:
	if wizard == null or not is_instance_valid(wizard):
		return "?"
	for prop: StringName in [&"display_name", &"unit_name"]:
		var v: Variant = wizard.get(prop)
		if v != null and str(v) != "":
			return str(v)
	return String(wizard.name)


## The line goes to the HUD (`current_scene.hud.show_message`) only for the local player's team.
func _show_on_hud(text: String) -> void:
	if team() != Unit.Team.PLAYER or not is_inside_tree():
		return
	var scene := get_tree().current_scene
	var hud: Variant = scene.get(&"hud") if scene else null
	if is_instance_valid(hud) and hud is Object and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, 3.0)


func _changed() -> void:
	apply_modifiers()
	inventory_changed.emit()


static func _script(path: String) -> Script:
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as Script
	return s if s and s.can_instantiate() else null
