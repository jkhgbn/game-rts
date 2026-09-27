class_name CampaignItems
extends RefCounted
## Items carried between campaign missions (docs/design/items.md "Campaign"). Save format (JSON):
##   { "version": 1,
##     "slots": [ {"id": "ember_shard", "count": 1}, null, ... ]   # 6 entries, potion counts kept
##     "artifacts_owned": ["ember_crown", ...],                    # every artifact owned
##     "artifacts_equipped": ["ember_crown", ""],                  # the 2 equipped ("" = empty)
##     "essence": 750 }                                            # already halved and capped
## Ground items, shop stock and cooldowns are not saved. `inventory` is the real Inventory
## (wizard.inventory) or a Dictionary with the same `slots` / `artifacts` keys (tests, tools).
## Slot entries are null or {type, count, cooldown_left}; `type` is an ItemType, or an id.

const VERSION := 1
const SLOT_COUNT := 6
const ARTIFACT_SLOTS := 2
const ESSENCE_CARRY := 0.5
const ESSENCE_CAP := 1500
const SAVE_PATH := "user://campaign_items.json"


## Essence kept for the next mission: 50 %, rounded down, capped at 1 500.
static func carried_essence(essence: int) -> int:
	return mini(floori(maxf(essence, 0) * ESSENCE_CARRY), ESSENCE_CAP)


## The save dictionary at the end of a mission. `owned_artifacts` adds artifacts owned but not
## equipped (the equipped ones are always counted as owned).
static func snapshot(inventory: Variant, essence: int, owned_artifacts: Array = []) -> Dictionary:
	var slots: Array = []
	var src_slots: Array = _array_of(inventory, "slots")
	for i in SLOT_COUNT:
		var e: Variant = src_slots[i] if i < src_slots.size() else null
		var id := _entry_id(e)
		var count := int((e as Dictionary).get("count", 1)) if e is Dictionary else 1
		slots.append(null if id == &"" else {"id": String(id), "count": maxi(1, count)})
	var equipped: Array = []
	var src_art: Array = _array_of(inventory, "artifacts")
	for i in ARTIFACT_SLOTS:
		equipped.append(String(_entry_id(src_art[i] if i < src_art.size() else null)))
	var owned: Array = []
	for a in owned_artifacts + equipped:
		var id := String(_type_id(a))
		if id != "" and not owned.has(id):
			owned.append(id)
	return {"version": VERSION, "slots": slots, "artifacts_owned": owned, "artifacts_equipped": equipped,
			"essence": carried_essence(essence)}


## Fills `inventory` from a snapshot at the start of the next mission and returns the essence to
## give the team (the caller adds it to the EssenceBank). A Dictionary inventory gets its `slots` /
## `artifacts` written in place (ids as StringName); a real Inventory gets add_item() calls (so its
## modifiers apply) with the potion counts.
static func restore(data: Dictionary, inventory: Variant) -> int:
	var slots: Array = data.get("slots", [])
	var equipped: Array = data.get("artifacts_equipped", [])
	if inventory is Dictionary:
		var inv := inventory as Dictionary
		var out_slots: Array = []
		for i in SLOT_COUNT:
			var e: Variant = slots[i] if i < slots.size() else null
			out_slots.append(null if e == null else {"type": StringName(e["id"]), "count": int(e.get("count", 1)),
					"cooldown_left": 0.0})
		var out_art: Array = []
		for i in ARTIFACT_SLOTS:
			var id := String(equipped[i]) if i < equipped.size() else ""
			out_art.append(null if id == "" else {"type": StringName(id), "count": 1, "cooldown_left": 0.0})
		inv["slots"] = out_slots
		inv["artifacts"] = out_art
	elif inventory is Object and (inventory as Object).has_method(&"add_item"):
		var inv_obj := inventory as Object
		for e in slots:
			if e == null:
				continue
			var type := ItemDrops.item_type(StringName(e["id"]))
			if type:
				inv_obj.call(&"add_item", type, int(e.get("count", 1)))
		for id in equipped:
			var art := ItemDrops.item_type(StringName(id)) if String(id) != "" else null
			if art:
				inv_obj.call(&"add_item", art)
	return int(data.get("essence", 0))


static func save_file(data: Dictionary, path: String = SAVE_PATH) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "\t"))
	return OK


## The saved snapshot, or {} when there is none (or it is unreadable).
static func load_file(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary and int((parsed as Dictionary).get("version", 0)) == VERSION else {}


# ---------------------------------------------------------------- helpers

static func _array_of(inventory: Variant, key: String) -> Array:
	if inventory is Dictionary:
		return (inventory as Dictionary).get(key, [])
	if inventory is Object and key in inventory:
		var v: Variant = (inventory as Object).get(key)
		return v if v is Array else []
	return []


## The item id of a slot entry ({type, count...}) or &"" for an empty slot.
static func _entry_id(e: Variant) -> StringName:
	if e is Dictionary:
		return _type_id((e as Dictionary).get("type"))
	return _type_id(e)


## ItemType (its `id`), StringName or String -> StringName; anything else -> &"".
static func _type_id(t: Variant) -> StringName:
	if t is String or t is StringName:
		return StringName(t)
	if t is Object and &"id" in t:
		return StringName((t as Object).get(&"id"))
	return &""
