class_name WaveCardTable
extends Resource
## Wave Strike cards and prices (docs/design/wave-strike.md 4.4). Data: data/wave_strike/card_prices.tres.
## Card price = UnitType.cost x mode_mult[id] (default 1.0), rounded to 5. `mode_mult` is re-priced from the Unit Lab
## matrix (wave-strike.md 9.1) without touching data/units/*.tres. `price_override` (id -> crystals) wins when set.

const DEFAULT_PATH := "res://data/wave_strike/card_prices.tres"

## kingdom -> Array of unit ids, in buy-panel order (slot keys Z X C V ...).
@export var cards: Dictionary = {}
## unit id -> price multiplier (default 1.0).
@export var mode_mult: Dictionary = {}
## unit id -> fixed price (crystals); wins over cost x mode_mult.
@export var price_override: Dictionary = {}
## unit id -> supply (pop) of the card in Wave Strike (default UnitType.pop). Balance pass 2 (2026-10-06): the mode is
## supply-capped from ~11:00, so pop is the real price of a late card; never change data/units for the mode.
@export var pop_override: Dictionary = {}
## unit id -> most copies of the card one roster may own (absent / 0 = no limit). M2 (wave-strike.md 14.1): kingdom
## casters 4, support cards 6, T3 cards 3 (stacked autocasts on one clump, the casters' own scans).
@export var max_copies: Dictionary = {}
## unit id -> Muster Pad footprint 1 (1x1) / 2 (2x2) (wave-strike.md 15.1; default: UnitType.radius < 0.6 -> 1).
@export var footprint: Dictionary = {}

static var _cached: WaveCardTable = null
var _roles: Dictionary = {}   ## id -> role cache


static func load_default() -> WaveCardTable:
	if _cached != null:
		return _cached
	if ResourceLoader.exists(DEFAULT_PATH):
		_cached = load(DEFAULT_PATH) as WaveCardTable
	if _cached == null:
		_cached = WaveCardTable.new()
	return _cached


## Unit ids of `kingdom`'s cards (panel order).
func cards_of(kingdom: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in cards.get(kingdom, cards.get(String(kingdom), [])):
		out.append(StringName(id))
	return out


## Crystal price of card `id` (0 = unknown unit).
func price(id: StringName) -> int:
	if price_override.has(id) or price_override.has(String(id)):
		return int(price_override.get(id, price_override.get(String(id), 0)))
	var t := UnitType.find(String(id))
	if t == null:
		return 0
	var m := float(mode_mult.get(id, mode_mult.get(String(id), 1.0)))
	return int(roundf(t.cost * m / 5.0) * 5.0)


## Supply (pop) of card `id` in Wave Strike: pop_override, else UnitType.pop (0 = unknown unit).
func pop(id: StringName) -> int:
	if pop_override.has(id) or pop_override.has(String(id)):
		return int(pop_override.get(id, pop_override.get(String(id), 0)))
	var t := UnitType.find(String(id))
	return t.pop if t else 0


## Most copies of card `id` one roster may own (0 = no limit).
func max_copies_of(id: StringName) -> int:
	return int(max_copies.get(id, max_copies.get(String(id), 0)))


## Muster Pad footprint of card `id`: 1 = 1x1, 2 = 2x2 (wave-strike.md 15.1).
func footprint_of(id: StringName) -> int:
	if footprint.has(id) or footprint.has(String(id)):
		return clampi(int(footprint.get(id, footprint.get(String(id), 1))), 1, 2)
	var t := UnitType.find(String(id))
	return 2 if t != null and t.radius >= 0.6 else 1


## The card's role (ui-wave-strike.md 1.1 rule): &"caster" (CasterKit.CASTERS), &"support" (support_kind), &"rider"
## (Unit Guide role cavalry), &"heavy" (guide role siege or WS pop >= 3), else &"melee" (attack_range <= 3) / &"ranged".
func role_of(id: StringName) -> StringName:
	if _roles.has(id):
		return _roles[id]
	var t := UnitType.find(String(id))
	var guide := str(UnitGuideData.text_of(id).get("role", ""))
	var k := &"melee"
	if ResourceLoader.exists("res://scripts/units/caster_kit.gd") and CasterKit.CASTERS.has(id):
		k = &"caster"
	elif t != null and t.support_kind != &"":
		k = &"support"
	elif guide == "cavalry":
		k = &"rider"
	elif guide == "siege" or pop(id) >= 3:
		k = &"heavy"
	elif t != null and t.attack_range > 3.0:
		k = &"ranged"
	_roles[id] = k
	return k


## The card's role for its upgrades (wave-strike.md 16.2): as role_of, but Heavy = pop >= 3 and not T3 only (a siege
## card is Ranged, a big T3 card takes its rider / melee / ranged role).
func upgrade_role(id: StringName) -> StringName:
	var k := role_of(id)
	if k != &"heavy":
		return k
	var t := UnitType.find(String(id))
	if t != null and t.requires_tier < 3 and pop(id) >= 3:
		return &"heavy"
	return &"ranged" if t != null and t.attack_range > 3.0 else &"melee"
