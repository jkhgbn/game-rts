class_name WaveUpgradeTable
extends Resource
## Wave Strike unit upgrades (docs/design/wave-strike.md 16). Data: data/wave_strike/card_upgrades.tres when it exists,
## else the defaults below (= the 16.1 / 16.2 rows; a .tres saved from `WaveUpgradeTable.new()` holds the same data).
## Card upgrades: two per card, A from the card's tier, B from the next tier (T3 B = Citadel); price = card price x
## price_mult[slot] rounded to 5, at least price_min[slot]. Each card's pair comes from its role template
## (WaveCardTable.upgrade_role), a ranged card that already has an on-hit status gets `on_hit_b` (Lingering) as B, and
## `overrides` (card id -> {"a": {...}, "b": {...}}) win (the T3 signature Bs).
## An upgrade entry: {id, name, desc, mods: {stat: v} (modifier "ws_up:<id>" at spawn), type_add / type_mult / type_set:
## {field: v} (the seat's lane copy of the UnitType), release: [{status, duration} | {shield, duration}]}.
## Armoury (16.1): line -> {name, desc, prices: [...], tiers: [...], mods: {stat: v per level}, only: "" | "caster_support"}.

const DEFAULT_PATH := "res://data/wave_strike/card_upgrades.tres"
const SLOT_A := 0
const SLOT_B := 1
const SLOT_KEYS: Array[String] = ["a", "b"]

@export var price_mult: Array[float] = [1.5, 2.5]
@export var price_min: Array[int] = [100, 150]
## role (&"melee", &"ranged", &"rider", &"heavy", &"support", &"caster") -> [upgrade A, upgrade B].
@export var templates: Dictionary = {
	"melee": [
		{"id": "shield_drill", "name": "Shield Drill", "desc": "+3 armour", "mods": {"armor": 3.0}},
		{"id": "war_cry", "name": "War Cry", "desc": "Haste for 4 s when the wave meets the enemy",
				"release": [{"status": "haste", "duration": 4.0}]}],
	"ranged": [
		{"id": "long_draw", "name": "Long Draw", "desc": "+1.5 range",
				"type_add": {"attack_range": 1.5, "aggro_range": 1.5}},
		{"id": "spotter_marks", "name": "Spotter Marks", "desc": "Hits mark the target for 3 s (+15 % damage taken)",
				"type_set": {"on_hit_status": "marked", "on_hit_duration": 3.0}}],
	"rider": [
		{"id": "barding", "name": "Barding", "desc": "+20 % max HP", "mods": {"max_hp_pct": 0.2}},
		{"id": "flank_gallop", "name": "Flank Gallop", "desc": "Haste for 6 s when the wave meets the enemy",
				"release": [{"status": "haste", "duration": 6.0}]}],
	"heavy": [
		{"id": "plate", "name": "Plate", "desc": "+4 armour", "mods": {"armor": 4.0}},
		{"id": "brace", "name": "Brace", "desc": "Braced for 6 s when the wave meets the enemy (damage taken x0.7)",
				"release": [{"status": "braced", "duration": 6.0}]}],
	"support": [
		{"id": "deep_wells", "name": "Deep Wells", "desc": "Support effect x1.4", "type_mult": {"support_amount": 1.4}},
		{"id": "quick_hands", "name": "Quick Hands", "desc": "Support every 25 % sooner",
				"type_mult": {"support_interval": 0.75}}],
	"caster": [
		{"id": "mana_font", "name": "Mana Font", "desc": "+40 % max mana, +50 % mana regen",
				"mods": {"max_mana_pct": 0.4, "mana_regen_pct": 0.5}},
		{"id": "focus", "name": "Focus", "desc": "+25 spell power, +20 % cooldown reduction",
				"mods": {"spell_power": 25.0, "cooldown_reduction": 0.2}}],
}
## Upgrade B of a ranged card that already has an on_hit_status (Lingering instead of Spotter Marks).
@export var on_hit_b: Dictionary = {"id": "lingering", "name": "Lingering", "desc": "On-hit effects last 50 % longer",
		"type_mult": {"on_hit_duration": 1.5}}
## card id -> {"a": upgrade, "b": upgrade} (either key optional). The T3 signature Bs (16.2).
@export var overrides: Dictionary = {
	"sunforge_cataphract": {"b": {"id": "sunforged_charge", "name": "Sunforged Charge",
			"desc": "Haste and braced for 6 s when the wave meets the enemy",
			"release": [{"status": "haste", "duration": 6.0}, {"status": "braced", "duration": 6.0}]}},
	"frostcrown_juggernaut": {"b": {"id": "rime_mantle", "name": "Rime Mantle", "desc": "Hits chill the target for 2 s",
			"type_set": {"on_hit_status": "chill", "on_hit_duration": 2.0}}},
	"shardguard": {"b": {"id": "shard_ward", "name": "Shard Ward",
			"desc": "A 150 shield for 10 s when the wave meets the enemy", "release": [{"shield": 150.0, "duration": 10.0}]}},
	"briar_roc": {"b": {"id": "thorned_pinions", "name": "Thorned Pinions", "desc": "+30 % max HP",
			"mods": {"max_hp_pct": 0.3}}},
	"glade_outrider": {"b": {"id": "far_sight", "name": "Far Sight", "desc": "+2 range",
			"type_add": {"attack_range": 2.0, "aggro_range": 2.0}}},
	"nightblood_reaver": {"b": {"id": "blood_feast", "name": "Blood Feast", "desc": "+6 HP regeneration",
			"mods": {"hp_regen": 6.0}}},
	"veilborn_dreadrider": {"b": {"id": "veil_ride", "name": "Veil Ride",
			"desc": "Shroud for 5 s when the wave meets the enemy (+2 speed, damage taken x0.5)",
			"release": [{"status": "shroud", "duration": 5.0}]}},
}
## line id -> Armoury line (see the header). 16.1.
@export var armoury: Dictionary = {
	"weapons": {"name": "Weapons", "desc": "+6 % damage per level", "prices": [200, 350, 500], "tiers": [1, 2, 3],
			"mods": {"attack_damage_pct": 0.06}, "only": ""},
	"armour": {"name": "Armour", "desc": "+1 armour per level", "prices": [200, 350, 500], "tiers": [1, 2, 3],
			"mods": {"armor": 1.0}, "only": ""},
	"arcana": {"name": "Arcana", "desc": "Casters and support cards: +15 spell power, +20 % mana regen per level",
			"prices": [250, 450], "tiers": [2, 3], "mods": {"spell_power": 15.0, "mana_regen_pct": 0.2},
			"only": "caster_support"},
}
## Armoury lines in panel order (keys R / Y / O).
@export var armoury_order: Array[StringName] = [&"weapons", &"armour", &"arcana"]

static var _cached: WaveUpgradeTable = null


static func load_default() -> WaveUpgradeTable:
	if _cached != null:
		return _cached
	if ResourceLoader.exists(DEFAULT_PATH):
		_cached = load(DEFAULT_PATH) as WaveUpgradeTable
	if _cached == null:
		_cached = WaveUpgradeTable.new()
	return _cached


## Card `id`'s upgrade in `slot` (SLOT_A / SLOT_B) ({} = none). `cards` gives the role and the price base.
func upgrade(cards: WaveCardTable, id: StringName, slot: int) -> Dictionary:
	if slot < 0 or slot > 1:
		return {}
	var o: Variant = overrides.get(id, overrides.get(String(id), null))
	if o is Dictionary and (o as Dictionary).has(SLOT_KEYS[slot]):
		return o[SLOT_KEYS[slot]]
	var role := cards.upgrade_role(id) if cards != null else &"melee"
	if slot == SLOT_B and role == &"ranged" and not on_hit_b.is_empty():
		var t := UnitType.find(String(id))
		if t != null and t.on_hit_status != &"":
			return on_hit_b
	var pair: Variant = templates.get(role, templates.get(String(role), []))
	if pair is Array and (pair as Array).size() > slot:
		return pair[slot]
	return {}


## Crystal price of card `id`'s upgrade in `slot` (-1 = no such upgrade).
func price(cards: WaveCardTable, id: StringName, slot: int) -> int:
	if upgrade(cards, id, slot).is_empty():
		return -1
	var p := roundf(cards.price(id) * price_mult[slot] / 5.0) * 5.0
	return maxi(int(p), price_min[slot])


## The tier (1-3) the upgrade needs: A = the card's own tier, B = the next one (T3 B = Citadel).
func gate_tier(id: StringName, slot: int) -> int:
	var t := UnitType.find(String(id))
	var card_tier := t.requires_tier if t != null else 1
	return mini(card_tier + (1 if slot == SLOT_B else 0), 3)


func armoury_line(line: StringName) -> Dictionary:
	return armoury.get(line, armoury.get(String(line), {}))


## Levels in Armoury line `line` (0 = unknown line).
func armoury_max(line: StringName) -> int:
	return (armoury_line(line).get("prices", []) as Array).size()


## Price of the next level after `level` (-1 = maxed / unknown).
func armoury_price(line: StringName, level: int) -> int:
	var prices: Array = armoury_line(line).get("prices", [])
	return int(prices[level]) if level >= 0 and level < prices.size() else -1


## Tier the next level after `level` needs.
func armoury_tier(line: StringName, level: int) -> int:
	var tiers: Array = armoury_line(line).get("tiers", [])
	return int(tiers[level]) if level >= 0 and level < tiers.size() else 3
