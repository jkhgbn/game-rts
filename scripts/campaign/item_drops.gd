class_name ItemDrops
extends RefCounted
## Glue between the map (caches, the warden camp, the crown) and the items system of scripts/items/
## (docs/design/items.md). Every call is guarded: while an items script is missing, nothing is
## given or spawned and a warning is logged.

const ITEM_TYPE_DIR := "res://data/items/"
const PICKUP_PATH := "res://scripts/items/item_pickup.gd"
const INVENTORY_PATH := "res://scripts/items/inventory.gd"

## Lost Cache loot table (one roll): cumulative chances.
const LOOT_ESSENCE := 0.40
const LOOT_DRAUGHT := 0.60
const LOOT_COMPONENT := 0.75
const LOOT_VIAL := 0.90        ## The last 10 %: Warden Scale.
const CACHE_ESSENCE := 80
const CACHE_ESSENCE_STEP := 20   ## Per 5 match minutes.
const CACHE_ESSENCE_CAP := 120


## One Lost Cache roll: {"essence": n} or {"item": id}.
static func roll_cache_loot(rng: RandomNumberGenerator, match_seconds: float) -> Dictionary:
	var r := rng.randf()
	if r < LOOT_ESSENCE:
		return {"essence": cache_essence(match_seconds)}
	if r < LOOT_DRAUGHT:
		return {"item": &"ember_draught"}
	if r < LOOT_COMPONENT:
		return {"item": ShopStock.BASE_COMPONENTS[rng.randi_range(0, ShopStock.BASE_COMPONENTS.size() - 1)]}
	if r < LOOT_VIAL:
		return {"item": &"dusk_vial"}
	return {"item": &"warden_scale"}


## 80 essence + 20 per full 5 match minutes, capped at 120.
static func cache_essence(match_seconds: float) -> int:
	var fives := int(match_seconds / 60.0) / 5
	return mini(CACHE_ESSENCE + CACHE_ESSENCE_STEP * fives, CACHE_ESSENCE_CAP)


## The ItemType resource data/items/<id>.tres, or null.
static func item_type(id: StringName) -> Resource:
	var path := ITEM_TYPE_DIR + String(id) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null


## Adds `amount` essence to `team` (EssenceBank). False if the bank does not exist yet.
static func give_essence(team: int, amount: int) -> bool:
	var bank := Keep.essence_bank_for(team)
	if bank == null:
		push_warning("ItemDrops: no EssenceBank yet, %d essence for team %d lost" % [amount, team])
		return false
	bank.call(&"add", amount)
	return true


## Puts item `id` into `wizard`'s inventory; when that fails (full, no inventory) it lies on the
## ground at `ground_pos`. Returns "inventory", "ground" or "" (nothing given: no items system).
static func give_item(wizard: Node, id: StringName, ground_pos: Vector3, parent: Node) -> String:
	var type := item_type(id)
	if type == null:
		push_warning("ItemDrops: no item type '%s' yet, nothing given" % id)
		return ""
	var inv := inventory_of(wizard)
	if inv and inv.has_method(&"add_item") and bool(inv.call(&"add_item", type)):
		return "inventory"
	return "ground" if spawn_pickup(parent, id, ground_pos) != null else ""


## An ItemPickup of item `id` on the ground at `pos` (child of `parent`), or null (logged) while
## scripts/items/item_pickup.gd or the item type is missing. Tries, in order: the static
## `ItemPickup.spawn(type, pos, amount, parent)`, then `new()` + `setup(type)` or an `item_type` / `type`
## property.
static func spawn_pickup(parent: Node, id: StringName, pos: Vector3) -> Node:
	var type := item_type(id)
	if type == null or parent == null or not ResourceLoader.exists(PICKUP_PATH):
		push_warning("ItemDrops: can't drop '%s' (no ItemPickup or item type yet)" % id)
		return null
	var script := load(PICKUP_PATH) as Script
	if script == null:
		return null
	if Keep.script_has(script, &"spawn"):
		var spawned := script.call(&"spawn", type, pos, 1, parent) as Node3D
		# The pickup snaps to the navmesh; if that query failed (it can return the origin), keep the
		# spot we asked for (the drop spots are open ground).
		if spawned and Vector2(spawned.global_position.x - pos.x, spawned.global_position.z - pos.z).length() > 1.5:
			spawned.global_position = Vector3(pos.x, 0.0, pos.z)
		return spawned
	var node := script.new() as Node
	if node == null:
		return null
	if node.has_method(&"setup"):
		node.call(&"setup", type)
	elif &"item_type" in node:
		node.set(&"item_type", type)
	elif &"type" in node:
		node.set(&"type", type)
	parent.add_child(node)
	if node is Node3D:
		(node as Node3D).global_position = pos
	return node


## `wizard.inventory` (or its child "Inventory") if it exists, else null.
static func inventory_of(wizard: Node) -> Object:
	if wizard == null or not is_instance_valid(wizard):
		return null
	if &"inventory" in wizard and wizard.get(&"inventory") != null:
		return wizard.get(&"inventory") as Object
	return wizard.get_node_or_null(^"Inventory")


## Calls Inventory.ensure_for(wizard) if scripts/items/inventory.gd exists (glue for main / skirmish).
static func ensure_inventory(wizard: Node) -> void:
	if wizard == null or not ResourceLoader.exists(INVENTORY_PATH):
		return
	var script := load(INVENTORY_PATH) as Script
	if script and Keep.script_has(script, &"ensure_for"):
		script.call(&"ensure_for", wizard)
