class_name ItemType
extends Resource
## One item (docs/design/items.md): a component, a mid / top recipe item, a consumable or an artifact.
## One `.tres` per item in `data/items/<id>.tres`. Stats are Stats-contract modifier keys
## (`"attack_damage": 12`, `"attack_cooldown_pct": -0.10`); the Inventory applies them as `item:<slot>`.

enum Tier { COMPONENT, MID, TOP, CONSUMABLE, ARTIFACT }
enum Target { NONE, SELF, POINT }

## `sold_at` bits.
const SOLD_BASE := 1      ## The team's completed keep / barracks.
const SOLD_PEDDLER := 2   ## Ruin Peddlers (neutral shops).

const DATA_DIR := "res://data/items/"
const TIER_COLORS: Array[Color] = [
	Color(0.85, 0.85, 0.85), Color(0.30, 0.75, 1.00), Color(1.00, 0.60, 0.20),
	Color(0.40, 0.90, 0.40), Color(1.00, 0.85, 0.30)]
const EMPTY_COLOR := Color(0.3, 0.3, 0.3)

@export var id: StringName
@export var display_name := ""
@export var tier: Tier = Tier.COMPONENT
## Components / consumables: the price. Mid / top: the recipe cost only (see total_cost()).
@export var cost := 0
## Recipe parts (mid / top). Empty for components, consumables, artifacts.
@export var parts: Array[ItemType] = []
## Stats-contract modifier keys -> values.
@export var stats: Dictionary = {}
## The main passive (`&"searing_strikes"`, `&"feed"`...), empty if none. All passives with their
## numbers are in `passives`.
@export var passive_id: StringName
## Every passive / aura of the item: id -> parameters (numbers from items.md), for 4.G1 / 4.I2.
@export var passives: Dictionary = {}
## Active id (`&"brace"`, `&"stride"`, `&"ember_draught"`...), empty if none. ItemActives runs it.
@export var active_id: StringName
@export var active_cooldown := 0.0
@export var active_target: Target = Target.NONE
## Active parameters (shield amount, duration, range...), numbers from items.md.
@export var active_params: Dictionary = {}
## Items with the same non-empty group share their cooldown (Ember Draught + Dusk Vial: `&"potion"`).
@export var cooldown_group: StringName
@export var stack_max := 1
@export_flags("Base", "Peddler") var sold_at := 0
@export var is_artifact := false
@export var campaign_only := false
## False while an item waits for a later wave (Owl Stone needs fog of war): never sold, never listed.
@export var available := true
@export var icon_abbrev := ""
## Passive / active description lines (the UI adds the name, key, stats and sell lines).
@export_multiline var tooltip := ""

static var _cache: Dictionary = {}     # StringName id -> ItemType
static var _all_loaded := false


## Recipe cost + the total cost of every part (components and consumables: `cost`).
func total_cost() -> int:
	var total := cost
	for part in parts:
		if part:
			total += part.total_cost()
	return total


func tier_color() -> Color:
	return TIER_COLORS[clampi(int(tier), 0, TIER_COLORS.size() - 1)]


func is_consumable() -> bool:
	return tier == Tier.CONSUMABLE


func has_active() -> bool:
	return active_id != &""


func is_sold_at(shop_bits: int) -> bool:
	return available and not campaign_only and not is_artifact and (sold_at & shop_bits) != 0


## The item with this id (`data/items/<id>.tres`), or null.
static func find(item_id: StringName) -> ItemType:
	var key := StringName(item_id)
	if _cache.has(key):
		return _cache[key]
	var path := DATA_DIR + String(key) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var type := load(path) as ItemType
	if type:
		_cache[key] = type
	return type


## Every item in `data/items/`, sorted by tier then total cost then id (shop order).
static func all_items() -> Array[ItemType]:
	if not _all_loaded:
		_all_loaded = true
		var dir := DirAccess.open(DATA_DIR)
		if dir:
			for file in dir.get_files():
				var f := file.trim_suffix(".remap")
				if f.ends_with(".tres"):
					find(StringName(f.get_basename()))
	var out: Array[ItemType] = []
	for type: ItemType in _cache.values():
		out.append(type)
	out.sort_custom(func(a: ItemType, b: ItemType) -> bool:
		if a.tier != b.tier:
			return a.tier < b.tier
		if a.total_cost() != b.total_cost():
			return a.total_cost() < b.total_cost()
		return String(a.id) < String(b.id))
	return out


## Items of one tier, shop order.
static func of_tier(t: Tier) -> Array[ItemType]:
	var out: Array[ItemType] = []
	for type in all_items():
		if type.tier == t:
			out.append(type)
	return out
