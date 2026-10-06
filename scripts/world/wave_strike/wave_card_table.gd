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

static var _cached: WaveCardTable = null


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
