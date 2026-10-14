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
const REASON_NO_ROOM := MusterPad.REASON_NO_ROOM   ## the UI adds "L = auto-arrange" (wave-strike.md 15.2)

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
var bought_by_card: Dictionary = {}   ## StringName id -> copies bought (stats, WS2.C2)
var sold_by_card: Dictionary = {}     ## StringName id -> copies sold (stats, WS2.C2)
## The seat's Muster Pad (wave-strike.md 15, child node "MusterPad"): one copy per card owned, on its cells.
var pad: MusterPad
## Auto-place style of buys without a cell (&"line" / &"spearhead"; the WaveBot sets its own).
var place_style: StringName = &"line"
## Unit upgrades (wave-strike.md 16): the table, card id -> bought slots mask (1 = A, 2 = B), Armoury line -> level.
var upgrades: WaveUpgradeTable
var _upgrades: Dictionary = {}
var _armoury: Dictionary = {}
var _up_recent: Array[Dictionary] = []   ## [{key, t, price}] upgrade buys inside the cancel window
var upgrades_bought: Array[String] = []  ## "<card>:a" / "armoury:<line>:<level>" in buy order (stats, bot logs)


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
	if upgrades == null:
		upgrades = WaveUpgradeTable.load_default()
	if pad == null:
		pad = MusterPad.new()
		pad.setup(seat, table)
		add_child(pad)


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


## "" = can buy, else the reason ("Requires Stronghold" / "Requires Citadel", "Max 4 copies", "Supply full (36/36)",
## "No room on the pad" / a pad reason for `cell`, "Not enough crystals"). `cell` = the copy's pad anchor (NONE = auto).
func can_buy(id: StringName, cell := MusterPad.NONE) -> String:
	if not card_ids().has(id) or UnitType.find(String(id)) == null:
		return REASON_UNKNOWN
	if tier_of_card(id) > tier:
		return REASON_TIER if tier_of_card(id) <= 2 else "Requires %s" % tier_name(tier_of_card(id))
	var most := table.max_copies_of(id)
	if most > 0 and count(id) >= most:
		return "Max %d copies" % most
	if pop_used() + pop_of(id) > cap():
		return "Supply full (%d/%d)" % [pop_used(), cap()]
	if cell == MusterPad.NONE:
		if pad.auto_cell(id, place_style) == MusterPad.NONE:
			return REASON_NO_ROOM
	else:
		var pwhy := pad.can_place(id, cell)
		if pwhy != "":
			return pwhy
	if not bank.can_afford(unit_price(id)):
		return REASON_CRYSTALS
	return ""


## Buys one copy of `id` and puts it on the pad at `cell` (NONE = auto-place by `place_style`, 15.2).
func buy(id: StringName, cell := MusterPad.NONE) -> String:
	var why := can_buy(id, cell)
	if why != "":
		return why
	bank.spend(unit_price(id))
	pad.place(id, cell if cell != MusterPad.NONE else pad.auto_cell(id, place_style))
	_counts[id] = count(id) + 1
	_recent.append({"id": id, "t": _now()})
	bought_total += 1
	bought_by_card[id] = int(bought_by_card.get(id, 0)) + 1
	changed.emit()
	return ""


## Sells the copy on pad cell `cell` (refund rules as `sell`).
func sell_at(cell: Vector2i) -> String:
	var c := pad.copy_at(cell)
	if c.is_empty():
		return REASON_NONE
	return _sell(StringName(c["id"]), c["cell"])


## Sells one copy of `id` (its back-most one on the pad): 100 % back inside the cancel window, else rules.sell_refund
## (pop locked until the next horn).
func sell(id: StringName) -> String:
	if count(id) <= 0:
		return REASON_NONE
	return _sell(id, pad.back_most(id))


func _sell(id: StringName, cell: Vector2i) -> String:
	if count(id) <= 0:
		return REASON_NONE
	if cell != MusterPad.NONE:
		pad.remove_at(cell)
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
	sold_by_card[id] = int(sold_by_card.get(id, 0)) + 1
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
	_up_recent.clear()
	changed.emit()


# ---------------------------------------------------------------- upgrades (wave-strike.md 16)

const REASON_UPGRADES_OFF := "Upgrades off"
const REASON_BOUGHT := "Already bought"
const REASON_MAX_LEVEL := "Max level"


## Card `id`'s upgrade in `slot` (WaveUpgradeTable.SLOT_A / SLOT_B): {id, name, desc, mods, type_*, release} or {}.
func upgrade_info(id: StringName, slot: int) -> Dictionary:
	return upgrades.upgrade(table, id, slot)


func has_upgrade(id: StringName, slot: int) -> bool:
	return slot >= 0 and slot <= 1 and (int(_upgrades.get(id, 0)) & (1 << slot)) != 0


## The bought upgrades of card `id` (entries as upgrade_info, A first). WS4.C2 applies them at spawn.
func upgrades_of(id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in 2:
		if has_upgrade(id, slot):
			out.append(upgrade_info(id, slot))
	return out


## Crystal price of card `id`'s upgrade `slot` (-1 = none).
func upgrade_price(id: StringName, slot: int) -> int:
	return upgrades.price(table, id, slot)


## "" = card `id`'s upgrade `slot` can be bought, else the reason ("Upgrades off", "Unknown card", "Already bought",
## "Requires Stronghold" / "Requires Citadel", "Not enough crystals"). Owning a copy is not needed.
func can_buy_upgrade(id: StringName, slot: int) -> String:
	if not rules.upgrades_enabled:
		return REASON_UPGRADES_OFF
	if not card_ids().has(id) or upgrade_info(id, slot).is_empty():
		return REASON_UNKNOWN
	if has_upgrade(id, slot):
		return REASON_BOUGHT
	var need := upgrades.gate_tier(id, slot)
	if tier < need:
		return "Requires %s" % tier_name(need)
	if not bank.can_afford(upgrade_price(id, slot)):
		return REASON_CRYSTALS
	return ""


## Buys card `id`'s upgrade `slot` (a one-time tech: every copy spawned from the next horn has it).
func buy_upgrade(id: StringName, slot: int) -> String:
	var why := can_buy_upgrade(id, slot)
	if why != "":
		return why
	var price := upgrade_price(id, slot)
	bank.spend(price)
	_upgrades[id] = int(_upgrades.get(id, 0)) | (1 << slot)
	var key := "%s:%s" % [id, WaveUpgradeTable.SLOT_KEYS[slot]]
	_up_recent.append({"key": key, "t": _now(), "price": price})
	upgrades_bought.append(key)
	changed.emit()
	return ""


## Takes back card `id`'s upgrade `slot` with a 100 % refund, only within `cancel_window` s of its buy (16.3).
func cancel_upgrade(id: StringName, slot: int) -> String:
	if not has_upgrade(id, slot):
		return "Not bought"
	var price := _take_recent("%s:%s" % [id, WaveUpgradeTable.SLOT_KEYS[slot]])
	if price < 0:
		return "Too late to cancel"
	_upgrades[id] = int(_upgrades.get(id, 0)) & ~(1 << slot)
	if int(_upgrades[id]) == 0:
		_upgrades.erase(id)
	bank.refund(price)
	changed.emit()
	return ""


## The price of a recent upgrade buy `key` inside the cancel window, removed from the list (-1 = none).
func _take_recent(key: String) -> int:
	var now := _now()
	for i in range(_up_recent.size() - 1, -1, -1):
		if String(_up_recent[i]["key"]) == key and now - float(_up_recent[i]["t"]) <= rules.cancel_window:
			var p := int(_up_recent[i]["price"])
			_up_recent.remove_at(i)
			return p
	return -1


## Armoury line `line`'s level (0 = none bought).
func armoury_level(line: StringName) -> int:
	return int(_armoury.get(line, 0))


## Price of the next level of `line` (-1 = maxed / unknown).
func armoury_price(line: StringName) -> int:
	return upgrades.armoury_price(line, armoury_level(line))


## "" = the next level of `line` can be bought, else the reason ("Upgrades off", "Unknown upgrade", "Max level",
## "Requires Stronghold" / "Requires Citadel", "Not enough crystals").
func can_armoury_buy(line: StringName) -> String:
	if not rules.upgrades_enabled:
		return REASON_UPGRADES_OFF
	if upgrades.armoury_max(line) <= 0:
		return "Unknown upgrade"
	var lv := armoury_level(line)
	if lv >= upgrades.armoury_max(line):
		return REASON_MAX_LEVEL
	var need := upgrades.armoury_tier(line, lv)
	if tier < need:
		return "Requires %s" % tier_name(need)
	if not bank.can_afford(armoury_price(line)):
		return REASON_CRYSTALS
	return ""


## Buys the next Armoury level of `line` (&"weapons" / &"armour" / &"arcana"): seat-wide from the next horn.
func armoury_buy(line: StringName) -> String:
	var why := can_armoury_buy(line)
	if why != "":
		return why
	var price := armoury_price(line)
	bank.spend(price)
	_armoury[line] = armoury_level(line) + 1
	var key := "armoury:%s:%d" % [line, armoury_level(line)]
	_up_recent.append({"key": key, "t": _now(), "price": price})
	upgrades_bought.append(key)
	changed.emit()
	return ""


## Takes back the last Armoury level of `line` (100 %, within `cancel_window` s of its buy).
func armoury_cancel(line: StringName) -> String:
	var lv := armoury_level(line)
	if lv <= 0:
		return "Not bought"
	var price := _take_recent("armoury:%s:%d" % [line, lv])
	if price < 0:
		return "Too late to cancel"
	_armoury[line] = lv - 1
	if lv - 1 <= 0:
		_armoury.erase(line)
	bank.refund(price)
	changed.emit()
	return ""


## The seat's Armoury stats for a unit of card `id` ({stat: total}; Arcana only on casters / support cards).
func armoury_mods(id: StringName) -> Dictionary:
	var out := {}
	for line: StringName in upgrades.armoury_order:
		var lv := armoury_level(line)
		if lv <= 0:
			continue
		var l := upgrades.armoury_line(line)
		if String(l.get("only", "")) == "caster_support" and not table.role_of(id) in [&"caster", &"support"]:
			continue
		var mods: Dictionary = l.get("mods", {})
		for s: Variant in mods:
			out[String(s)] = float(out.get(String(s), 0.0)) + float(mods[s]) * lv
	return out


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
			"bought_total": bought_total, "bought_by_card": bought_by_card.duplicate(),
			"sold_by_card": sold_by_card.duplicate(), "cells": pad.save_cells(), "place_style": String(place_style),
			"upgrades": _upgrades.duplicate(), "armoury": _armoury.duplicate(), "up_recent": _up_recent.duplicate(true),
			"upgrades_bought": upgrades_bought.duplicate()}


func load_state(d: Dictionary) -> void:
	tier = int(d.get("tier", tier))
	upgrade_left = float(d.get("upgrade_left", 0.0))
	_upgrade_to = int(d.get("upgrade_to", 0))
	_counts = (d.get("counts", {}) as Dictionary).duplicate()
	_ranks = (d.get("ranks", {}) as Dictionary).duplicate()
	_locked_pop = int(d.get("locked_pop", 0))
	_recent.assign((d.get("recent", []) as Array).duplicate(true))
	bought_total = int(d.get("bought_total", 0))
	bought_by_card = _id_counts(d.get("bought_by_card", {}))
	sold_by_card = _id_counts(d.get("sold_by_card", {}))
	place_style = StringName(str(d.get("place_style", place_style)))
	_upgrades = _id_counts(d.get("upgrades", {}))
	_armoury = _id_counts(d.get("armoury", {}))
	_up_recent.assign((d.get("up_recent", []) as Array).duplicate(true))
	upgrades_bought.assign(d.get("upgrades_bought", []) as Array)
	# an older save without cells: the pad is auto-arranged in Line (wave-strike.md 15.5)
	pad.load_cells(d.get("cells", {}), _counts, place_style if d.has("cells") else &"line")
	changed.emit()


## A saved id -> count map with StringName keys (a JSON round trip gives String keys).
static func _id_counts(v: Variant) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for k: Variant in v:
			out[StringName(str(k))] = int(v[k])
	return out
