class_name Recipes
extends RefCounted
## Recipe maths for mid / top items (docs/design/items.md "Tier colours and rules", task 4.I2).
## Static only. Works with the frozen Items API but reaches `ItemType`, `Inventory` and `EssenceBank`
## untyped, so it compiles whether or not those scripts exist yet.
##
## `plan(inventory, type)` answers "what happens if the wizard clicks Buy / Combine on this item now":
## which owned parts (slot indexes, 0-based into `inventory.slots`) are consumed, the essence price
## (recipe + the parts not carried, recursively) and the refusal reason in the items.md order
## `"Dead"`, `"No shop nearby"`, `"Not sold here"` (or `"Needs Warden Scale (neutral peddler)"` for a
## missing part sold elsewhere), `"Inventory full"`, `"Not enough essence"`.

const TIER_ORDER: Array[String] = ["component", "mid", "top", "consumable", "artifact"]
const SOLD_BASE_DEFAULT := 1
const SOLD_PEDDLER_DEFAULT := 2
const MAX_TREE_DEPTH := 3   # the item, its parts, their parts (items.md shop details)

static var _class_cache: Dictionary = {}


## Plan for buying / combining `type` from `inventory`. `shop` = the shop used (default: the
## inventory's `nearest_shop()` when it has one). Returns
## `{ok, reason, consume_slots: Array[int], essence_cost: int, missing: Array (types bought),
## is_combine: bool}`.
static func plan(inventory: Object, type: Object, shop: Object = null) -> Dictionary:
	var consume: Array[int] = []
	var out := {"ok": false, "reason": "", "consume_slots": consume, "essence_cost": 0,
			"missing": [], "is_combine": false}
	if type == null:
		out["reason"] = "Unknown item"
		return out
	var wizard := owner_of(inventory)
	# Cost and consumed parts are always filled in (the shop shows the live price even when refused).
	var parts: Array = _parts_of(type)
	var blocked: Object = null
	var has_shop_api := inventory != null and inventory.has_method(&"nearest_shop")
	if shop == null and has_shop_api:
		shop = inventory.call(&"nearest_shop") as Object
	if parts.is_empty():
		out["essence_cost"] = int(type.get("cost"))
	else:
		out["is_combine"] = true
		var owned := _owned_entries(inventory)
		var missing: Array = []
		var cost := int(type.get("cost"))
		for part: Variant in parts:
			cost += _take_or_buy(part as Object, owned, consume, missing, shop)
		out["essence_cost"] = cost
		out["missing"] = missing
		for part: Variant in missing:
			if not _shop_sells(shop, part as Object):
				blocked = part as Object
				break
	# Refusal reasons, in the items.md order.
	var reason := ""
	if wizard != null and wizard.has_method(&"is_alive") and not bool(wizard.call(&"is_alive")):
		reason = "Dead"
	elif has_shop_api and shop == null:
		reason = "No shop nearby"
	elif bool(type.get("is_artifact")) or bool(type.get("campaign_only")) or tier_name(type) == "artifact":
		reason = "Not sold here"
	elif parts.is_empty() and not _shop_sells(shop, type):
		reason = "Not sold here"
	elif blocked != null:
		reason = "Needs %s (%s)" % [display_name(blocked), _where_sold(blocked)]
	elif _free_slots(inventory) < _slots_needed(inventory, type, consume.size()):
		reason = "Inventory full"
	else:
		var essence := essence_of(team_of(inventory))
		if essence >= 0 and essence < int(out["essence_cost"]):
			reason = "Not enough essence"
	out["reason"] = reason
	out["ok"] = reason == ""
	return out


## Recipe tree for the shop's details view: `{id, name, abbrev, tier, cost, total_cost, owned: bool,
## slot: int, parts: Array[same]}`, 3 levels at most. With an `inventory`, parts the buyer carries
## (and that `plan` would consume) get `owned = true` and their slot index.
static func tree(type: Object, inventory: Object = null) -> Dictionary:
	var owned := _owned_entries(inventory)
	return _tree_node(type, 1, owned, false)


## Total value of an item: `total_cost()` when ItemType has it, else recipe + parts recursively.
static func total_cost(type: Object) -> int:
	if type == null:
		return 0
	if type.has_method(&"total_cost"):
		return int(type.call(&"total_cost"))
	var sum := int(type.get("cost"))
	for part: Variant in _parts_of(type):
		sum += total_cost(part as Object)
	return sum


## `"component"`, `"mid"`, `"top"`, `"consumable"` or `"artifact"` whatever the tier is stored as.
static func tier_name(type: Object) -> String:
	if type == null:
		return ""
	var t: Variant = type.get("tier")
	if t is String or t is StringName:
		return String(t).to_lower()
	if t is int:
		var script := type.get_script() as Script
		if script:
			var tiers: Variant = script.get_script_constant_map().get("Tier")
			if tiers is Dictionary:
				for key: Variant in tiers:
					if int(tiers[key]) == int(t):
						return String(key).to_lower()
		if int(t) >= 0 and int(t) < TIER_ORDER.size():
			return TIER_ORDER[int(t)]
	if bool(type.get("is_artifact")):
		return "artifact"
	return "component"


static func id_of(type: Object) -> StringName:
	if type == null:
		return &""
	return StringName(str(type.get("id")))


static func display_name(type: Object) -> String:
	if type == null:
		return ""
	var n: Variant = type.get("display_name")
	return str(n) if n != null and str(n) != "" else String(id_of(type)).capitalize()


## The ItemType in a slot entry (`{type, count, cooldown_left}`, or a bare type), else null.
static func type_in(entry: Variant) -> Object:
	if entry is Dictionary:
		return (entry as Dictionary).get("type") as Object
	if entry is Object:
		return entry as Object
	return null


## The wizard that carries `inventory` (its `wizard` property, else its parent).
static func owner_of(inventory: Object) -> Node:
	if inventory == null:
		return null
	var w: Variant = inventory.get("wizard")
	if is_instance_valid(w) and w is Node:
		return w as Node
	if inventory is Node:
		return (inventory as Node).get_parent()
	return null


static func team_of(inventory: Object) -> int:
	var w := owner_of(inventory)
	if w != null and w.get("team") != null:
		return int(w.get("team"))
	return 0


## The team's essence: `EssenceBank.for_team(team).essence`, else `Economy.essence`; -1 if unknown.
static func essence_of(team: int) -> int:
	for cls: String in ["EssenceBank", "Economy"]:
		var script := global_script(cls)
		if script == null or not script.has_method(&"for_team"):
			continue
		var bank: Variant = script.call(&"for_team", team)
		if is_instance_valid(bank) and bank is Object and (bank as Object).get("essence") != null:
			return int((bank as Object).get("essence"))
	return -1


## `ItemType.find(id)` when it exists, else `data/items/<id>.tres`, else null.
static func find_type(id: StringName) -> Object:
	var script := global_script("ItemType")
	if script != null and script.has_method(&"find"):
		var found: Variant = script.call(&"find", id)
		if found is Object:
			return found as Object
	var path := "res://data/items/%s.tres" % id
	if ResourceLoader.exists(path):
		return load(path)
	return null


## A global class script by name (null if the class does not exist yet). Cached once found.
static func global_script(cls: String) -> Script:
	if _class_cache.has(cls):
		return _class_cache[cls] as Script
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if String(entry.get("class", "")) == cls:
			var script := load(String(entry["path"])) as Script
			if script:
				_class_cache[cls] = script
			return script
	return null


# ---------------------------------------------------------------- private

static func _parts_of(type: Object) -> Array:
	if type == null:
		return []
	var p: Variant = type.get("parts")
	return p if p is Array else []


## Owned item-slot entries: `[{slot, id, used}]` (artifact slots never count).
static func _owned_entries(inventory: Object) -> Array:
	var owned: Array = []
	if inventory == null:
		return owned
	var slots: Variant = inventory.get("slots")
	if not slots is Array:
		return owned
	for i in (slots as Array).size():
		var t := type_in((slots as Array)[i])
		if t != null:
			owned.append({"slot": i, "id": id_of(t), "used": false})
	return owned


## Consumes an owned copy of `part` (cost 0), else recurses into its parts (recipe + missing parts),
## else buys it (its price). Fills `consume` and `missing`.
static func _take_or_buy(part: Object, owned: Array, consume: Array[int], missing: Array,
		shop: Object) -> int:
	var slot := _claim(owned, id_of(part))
	if slot >= 0:
		consume.append(slot)
		return 0
	var sub := _parts_of(part)
	if sub.is_empty():
		missing.append(part)
		return int(part.get("cost"))
	var cost := int(part.get("cost"))
	for p: Variant in sub:
		cost += _take_or_buy(p as Object, owned, consume, missing, shop)
	return cost


static func _claim(owned: Array, id: StringName) -> int:
	for e: Dictionary in owned:
		if not e["used"] and e["id"] == id:
			e["used"] = true
			return int(e["slot"])
	return -1


static func _tree_node(type: Object, depth: int, owned: Array, match_owned: bool) -> Dictionary:
	var node := {"id": id_of(type), "name": display_name(type), "tier": tier_name(type),
			"abbrev": str(type.get("icon_abbrev")) if type and type.get("icon_abbrev") != null else "",
			"cost": int(type.get("cost")) if type else 0, "total_cost": total_cost(type),
			"owned": false, "slot": -1, "parts": []}
	if type == null:
		return node
	if match_owned:
		var slot := _claim(owned, id_of(type))
		if slot >= 0:
			node["owned"] = true
			node["slot"] = slot
	var children: Array = []
	if depth < MAX_TREE_DEPTH:
		for p: Variant in _parts_of(type):
			# Below an owned part nothing is needed, so its own parts are never marked owned.
			children.append(_tree_node(p as Object, depth + 1, owned, not node["owned"]))
	node["parts"] = children
	return node


static func _free_slots(inventory: Object) -> int:
	if inventory == null:
		return 0
	var slots: Variant = inventory.get("slots")
	if not slots is Array:
		return 0
	var free := 0
	for e: Variant in slots:
		if type_in(e) == null:
			free += 1
	return free


## Slots the purchase needs: 1 - parts consumed, or 0 when a consumable merges into a stack.
static func _slots_needed(inventory: Object, type: Object, consumed: int) -> int:
	if consumed == 0 and _parts_of(type).is_empty():
		var stack_max := int(type.get("stack_max")) if type.get("stack_max") != null else 1
		var slots: Variant = inventory.get("slots") if inventory else null
		if stack_max > 1 and slots is Array:
			for e: Variant in slots:
				if e is Dictionary and id_of(type_in(e)) == id_of(type) \
						and int((e as Dictionary).get("count", 1)) < stack_max:
					return 0
	return 1 - consumed


static func _is_peddler(shop: Object) -> bool:
	if shop == null:
		return false
	if shop.has_method(&"is_peddler"):
		return bool(shop.call(&"is_peddler"))
	if shop is Node and (shop as Node).is_in_group(&"peddlers"):
		return true
	return shop.get("team") != null and int(shop.get("team")) == Unit.Team.NEUTRAL


## Bits `[base, peddler]` of `ItemType.sold_at` (read from the ItemType constants when present).
static func _sold_bits(type: Object) -> Array[int]:
	var bits: Array[int] = [SOLD_BASE_DEFAULT, SOLD_PEDDLER_DEFAULT]
	var script := type.get_script() as Script if type else null
	if script == null:
		return bits
	var consts := script.get_script_constant_map()
	for key: Variant in consts:
		var k := String(key).to_upper()
		var v: Variant = consts[key]
		if v is int and k.contains("SOLD"):
			if k.contains("BASE"):
				bits[0] = int(v)
			elif k.contains("PEDDLER"):
				bits[1] = int(v)
		elif v is Dictionary and (v as Dictionary).has("BASE") and (v as Dictionary).has("PEDDLER"):
			var b := int(v["BASE"])
			var p := int(v["PEDDLER"])
			if b == 0 or p == 0 or b == p:   # a plain enum: the values are bit indexes
				b = 1 << b
				p = 1 << p
			bits[0] = b
			bits[1] = p
	return bits


static func _shop_sells(shop: Object, type: Object) -> bool:
	if shop == null or type == null:
		return true   # no shop information: the Inventory's own checks decide
	if shop.has_method(&"sells"):
		return bool(shop.call(&"sells", type))
	var sold: Variant = type.get("sold_at")
	if sold == null:
		return true
	var bits := _sold_bits(type)
	return (int(sold) & (bits[1] if _is_peddler(shop) else bits[0])) != 0


static func _where_sold(type: Object) -> String:
	var sold: Variant = type.get("sold_at")
	if sold == null:
		return "another shop"
	var bits := _sold_bits(type)
	if (int(sold) & bits[1]) != 0 and (int(sold) & bits[0]) == 0:
		return "neutral peddler"
	if (int(sold) & bits[0]) != 0:
		return "base shop"
	return "not sold"
