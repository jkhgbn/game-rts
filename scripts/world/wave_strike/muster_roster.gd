class_name MusterRoster
extends Node
## One Wave Strike player's persistent cards (docs/design/wave-strike.md 4.4, 7.3; M1: no ranks, no lane toggle).
## Every card spawns one unit at each horn. Buys join the next horn; a sell within `cancel_window` s of a buy refunds
## 100 %, later 50 % and its pop stays locked until the next horn. Supply cap per tier (Keep / Stronghold).
## Group "rosters"; find one with `MusterRoster.for_seat(tree, seat)`.

signal changed

const REASON_UNKNOWN := "Unknown card"
const REASON_TIER := "Requires Stronghold"
const REASON_CRYSTALS := "Not enough crystals"
const REASON_NONE := "No card to sell"

var seat := 0
var team: int = Unit.Team.PLAYER
var kingdom: StringName = &"fire"
var rules: WaveStrikeRules
var table: WaveCardTable
var bank: WaveBank
var director: Node                 ## WaveDirector (clock, horn index); untyped to keep the load order free
var tier := 1
var upgrade_left := 0.0            ## > 0 while the Stronghold is rising
var _upgrade_to := 0
var _counts: Dictionary = {}       ## StringName id -> int
var _ranks: Dictionary = {}        ## StringName id -> 2 / 3 (absent = rank 1)
var _locked_pop := 0               ## sold cards' pop, freed at the next horn
var _recent: Array[Dictionary] = []   ## [{id, t}] buys inside the cancel window
var bought_total := 0              ## cards bought (stats)


func setup(p_seat: int, p_team: int, p_kingdom: StringName, p_rules: WaveStrikeRules, p_table: WaveCardTable,
		p_bank: WaveBank, p_director: Node) -> void:
	seat = p_seat
	team = p_team
	kingdom = p_kingdom
	rules = p_rules
	table = p_table
	bank = p_bank
	director = p_director
	name = "MusterRoster%d" % seat
	add_to_group(&"rosters")


static func for_seat(tree: SceneTree, p_seat: int) -> MusterRoster:
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"rosters"):
		if n is MusterRoster and (n as MusterRoster).seat == p_seat:
			return n
	return null


func _now() -> float:
	return float(director.get(&"time")) if director != null else 0.0


func _horn_index() -> int:
	return int(director.get(&"horn_index")) if director != null else 0


# ---------------------------------------------------------------- cards

func card_ids() -> Array[StringName]:
	return table.cards_of(kingdom)


func price_of(id: StringName) -> int:
	return table.price(id)


## The card's Wave Strike supply (WaveCardTable.pop: pop_override, else UnitType.pop).
func pop_of(id: StringName) -> int:
	return table.pop(id)


func tier_of_card(id: StringName) -> int:
	var t := UnitType.find(String(id))
	return t.requires_tier if t else 1


## The line's rank (1 Recruit, 2 Drilled, 3 Elite): every copy of the card spawns at it.
func rank(id: StringName) -> int:
	return int(_ranks.get(id, 1))


## What one more copy costs: the card price plus the line's ranks (wave-strike.md 4.4).
func unit_price(id: StringName) -> int:
	var p := float(price_of(id))
	var m := 1.0
	for r in range(2, rank(id) + 1):
		m += rules.rank_pct[r - 2]
	return int(roundf(p * m / 5.0) * 5.0)


## Price to raise the whole line one rank (per copy owned, at least one).
func rank_up_price(id: StringName) -> int:
	var r := rank(id)
	if r >= 3:
		return -1
	return int(roundf(price_of(id) * rules.rank_pct[r - 1] * maxi(count(id), 1) / 5.0) * 5.0)


## "" = the line can rank up, else the reason.
func can_rank_up(id: StringName) -> String:
	if not card_ids().has(id):
		return REASON_UNKNOWN
	var r := rank(id)
	if r >= 3:
		return "Max rank"
	if count(id) <= 0:
		return "Buy the card first"
	if tier < r + 1:
		return "Requires %s" % tier_name(r + 1)
	if not bank.can_afford(rank_up_price(id)):
		return REASON_CRYSTALS
	return ""


func rank_up(id: StringName) -> String:
	var why := can_rank_up(id)
	if why != "":
		return why
	bank.spend(rank_up_price(id))
	_ranks[id] = rank(id) + 1
	changed.emit()
	return ""


func count(id: StringName) -> int:
	return int(_counts.get(id, 0))


## id -> count (a copy).
func cards() -> Dictionary:
	return _counts.duplicate()


func card_total() -> int:
	var n := 0
	for id in _counts:
		n += int(_counts[id])
	return n


func pop_used() -> int:
	var p := _locked_pop
	for id in _counts:
		p += int(_counts[id]) * pop_of(id)
	return p


func cap() -> int:
	return rules.cap_at(tier)


## "" = can buy, else the reason ("Requires Stronghold", "Supply full (24/24)", "Not enough crystals").
func can_buy(id: StringName) -> String:
	if not card_ids().has(id) or UnitType.find(String(id)) == null:
		return REASON_UNKNOWN
	if tier_of_card(id) > tier:
		return REASON_TIER
	if pop_used() + pop_of(id) > cap():
		return "Supply full (%d/%d)" % [pop_used(), cap()]
	if not bank.can_afford(unit_price(id)):
		return REASON_CRYSTALS
	return ""


func buy(id: StringName) -> String:
	var why := can_buy(id)
	if why != "":
		return why
	bank.spend(unit_price(id))
	_counts[id] = count(id) + 1
	_recent.append({"id": id, "t": _now()})
	bought_total += 1
	changed.emit()
	return ""


## Sells one copy of `id`: 100 % back inside the cancel window, else rules.sell_refund (pop locked until the next horn).
func sell(id: StringName) -> String:
	if count(id) <= 0:
		return REASON_NONE
	var price := unit_price(id)
	var refund := int(roundf(price * rules.sell_refund))
	var now := _now()
	for i in range(_recent.size() - 1, -1, -1):
		if StringName(_recent[i]["id"]) == id and now - float(_recent[i]["t"]) <= rules.cancel_window:
			refund = price
			_recent.remove_at(i)
			break
	if refund < price:
		_locked_pop += pop_of(id)
	_counts[id] = count(id) - 1
	if int(_counts[id]) <= 0:
		_counts.erase(id)
	bank.refund(refund)
	changed.emit()
	return ""


## The units of the next horn, in spawn order: melee, then ranged, then casters (by card order inside a group).
func spawn_list() -> Array[StringName]:
	var groups: Array[Array] = [[], [], []]
	for id in card_ids():
		var t := UnitType.find(String(id))
		if t == null:
			continue
		var g := 0
		if t.attack_range > 3.0:
			g = 1
		if ResourceLoader.exists("res://scripts/units/caster_kit.gd") and CasterKit.CASTERS.has(id):
			g = 2
		for i in count(id):
			groups[g].append(id)
	var out: Array[StringName] = []
	for g in groups:
		for id in g:
			out.append(id)
	return out


## The director calls it at each horn (sold pop is free again, the cancel window closes).
func on_horn() -> void:
	_locked_pop = 0
	_recent.clear()
	changed.emit()


# ---------------------------------------------------------------- tiers (the War Hall)

func next_tier_price() -> int:
	return rules.stronghold_price if tier == 1 else rules.citadel_price


## "" = the next tier can start, else the reason.
func can_upgrade() -> String:
	if tier >= rules.max_tier:
		return "Max tier"
	if upgrade_left > 0.0:
		return "Upgrade in progress"
	var from_horn := rules.stronghold_from_horn if tier == 1 else rules.citadel_from_horn
	if _horn_index() < from_horn:
		return "From horn %d" % from_horn
	if not bank.can_afford(next_tier_price()):
		return REASON_CRYSTALS
	return ""


func upgrade() -> String:
	var why := can_upgrade()
	if why != "":
		return why
	bank.spend(next_tier_price())
	_upgrade_to = tier + 1
	upgrade_left = rules.stronghold_time if tier == 1 else rules.citadel_time
	changed.emit()
	return ""


func tier_name(t: int = -1) -> String:
	return ["Keep", "Stronghold", "Citadel"][clampi(t if t > 0 else tier, 1, 3) - 1]


## Advances the tier timer (the director calls it with its own clock, so a held / paused game holds it too).
func tick(delta: float) -> void:
	if upgrade_left <= 0.0:
		return
	upgrade_left -= delta
	if upgrade_left <= 0.0:
		upgrade_left = 0.0
		tier = _upgrade_to
		_upgrade_to = 0
		changed.emit()


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

func save_state() -> Dictionary:
	return {"tier": tier, "upgrade_left": upgrade_left, "upgrade_to": _upgrade_to, "counts": _counts.duplicate(),
			"ranks": _ranks.duplicate(), "locked_pop": _locked_pop, "recent": _recent.duplicate(true),
			"bought_total": bought_total}


func load_state(d: Dictionary) -> void:
	tier = int(d.get("tier", tier))
	upgrade_left = float(d.get("upgrade_left", 0.0))
	_upgrade_to = int(d.get("upgrade_to", 0))
	_counts = (d.get("counts", {}) as Dictionary).duplicate()
	_ranks = (d.get("ranks", {}) as Dictionary).duplicate()
	_locked_pop = int(d.get("locked_pop", 0))
	_recent.assign((d.get("recent", []) as Array).duplicate(true))
	bought_total = int(d.get("bought_total", 0))
	changed.emit()
