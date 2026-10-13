class_name GoldBank
extends Node
## Gold, the trade currency of one team (docs/design/market-trade.md section 3, contract in section 12).
## One node per team in group `"gold_banks"`; get it with `GoldBank.for_team(team)`.
##
## **Trade on / off**: trade is on exactly when the banks exist. The Skirmish (task 10.C1) creates one bank per
## team with `GoldBank.create(parent, team)` when `trade_enabled` is true; missions (trade off) create none.
## `for_team` never creates a bank (unlike `EssenceBank.for_team`), so it returns **null when trade is off** and
## every caller must handle null (top bar hidden, no wares, no gold prices in the tavern...).
##
## Sources (3.1): start 0; `add(n, &"trade")` caravan deliveries, `&"loot"` loot sacks, `&"reward"` the Lodge
## bounty for Magpies. Nothing else pays gold. `earned(source)` totals every positive `add` (per source or all).
##
## Wares (3.2): four one-time upgrades bought at an own completed Bazaar (`buy_ware`). Unit wares are stat
## modifiers `ware:<id>` (Stats API) put on the team's living units at purchase and on every later unit by
## `apply_wares(unit)` (idempotent; `Unit._ready` calls it through the group, and the bank also catches new units
## itself one frame after they enter the tree). The Masons' Charter scales every own building's max HP by
## `building_hp_mult()` (Building reads it at creation; living buildings get `set_hp_mult` and heal the gain).
##
## Exchange (3.2): 100 gold -> 80 crystals or 40 essence (`exchange`), own completed Bazaar needed, no reverse.

## Gold changed (any add / spend / exchange). `gold` = the new amount.
signal changed(gold: int)
## A spend (or a ware / exchange paid in gold) was refused for lack of gold: the top bar flashes red.
signal spend_failed
## A ware was bought (the UI shows `Bought <name>`, the Bazaar plays `ware_bought`).
signal ware_bought(id: StringName)
## An exchange went through: `gold` spent, `received` crystals or essence (`to`). For the message
## `Exchanged 100 gold for 80 crystals`.
signal exchanged(gold: int, to: StringName, received: int)

const START_GOLD := 0
const GROUP := &"gold_banks"
const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL
## Gold sources (3.1). `add` accepts any StringName; these are the ones the game uses.
const SOURCE_TRADE := &"trade"
const SOURCE_LOOT := &"loot"
const SOURCE_REWARD := &"reward"
## BuildingType.kind of the Bazaar (task 10.C2).
const MARKET_KIND := &"market"
## Group of every Bazaar (Market.GROUP, task 10.C2).
const MARKETS_GROUP := &"markets"

## The four wares (3.2), in the trade window's order. `filter`: &"caravans", &"soldiers" or &"buildings".
## `stats`: the Stats API modifier `ware:<id>` put on the matching units. `hp_mult`: building max HP factor.
const WARES := {
	&"iron_axles": {"name": "Iron-shod Axles", "price": 150, "filter": &"caravans",
			"stats": {&"move_speed": 0.5, &"max_hp": 60.0}, "text": "Caravans +0.5 speed and +60 max HP"},
	&"masons_charter": {"name": "Masons' Charter", "price": 350, "filter": &"buildings",
			"stats": {}, "hp_mult": 1.15, "text": "Every building +15% max HP"},
	&"tempered_steel": {"name": "Tempered Steel", "price": 350, "filter": &"soldiers",
			"stats": {&"attack_damage_pct": 0.08}, "text": "Soldiers +8% attack damage"},
	&"gambesons": {"name": "Quilted Gambesons", "price": 350, "filter": &"soldiers",
			"stats": {&"armor": 10.0}, "text": "Soldiers +10 armor"},
}
const WARE_PREFIX := "ware:"
## Exchange rates per EXCHANGE_STEP gold (3.2). No reverse exchange.
const EXCHANGE := {&"crystals": 80, &"essence": 40}
const EXCHANGE_STEP := 100

const MSG_NO_BAZAAR := "No Bazaar"
const MSG_OWNED := "Already owned"
const MSG_NO_GOLD := "Not enough gold"
const MSG_UNKNOWN_WARE := "Unknown ware"
const MSG_UNKNOWN_RESOURCE := "Unknown resource"
const MSG_STEP := "Exchange in steps of 100 gold"
const MSG_NO_TARGET := "Cannot exchange now"

@export var team: int = 0
## Read only outside this script (use add / spend).
@export var gold: int = START_GOLD

## Wares bought, in purchase order. Read only.
var owned_wares: Array[StringName] = []

var _earned_total := 0
var _earned: Dictionary = {}          # StringName source -> int
var _has_unit_wares := false          # an owned ware puts a modifier on units
var _pending: Array = []              # units added to the tree, waiting for apply_wares at the frame end
var _flush_queued := false


## The bank of `for_team_id`, or null when there is none (trade off). Never creates one.
static func for_team(for_team_id: int) -> GoldBank:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GROUP):
		var bank := node as GoldBank
		if bank and bank.team == for_team_id and not bank.is_queued_for_deletion():
			return bank
	return null


## True when at least one bank exists (trade is on in this match).
static func trade_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and tree.get_first_node_in_group(GROUP) != null


## Creates the bank of `for_team_id` under `parent` (the Skirmish does it when trade is on), or returns the
## existing one. Findable by for_team at once, even while `parent` is still setting up.
static func create(parent: Node, for_team_id: int) -> GoldBank:
	var existing := for_team(for_team_id)
	if existing:
		return existing
	var bank := GoldBank.new()
	bank.team = for_team_id
	bank.name = "GoldBank%d" % for_team_id
	bank.add_to_group(GROUP)   # before add_child, so a second call finds it at once
	if parent.is_inside_tree() and not parent.is_node_ready():
		parent.add_child.call_deferred(bank)
	else:
		parent.add_child(bank)
	return bank


func _ready() -> void:
	add_to_group(GROUP)
	set_process(false)
	get_tree().node_added.connect(_on_node_added)


# ---------------------------------------------------------------- gold

func can_afford(amount: int) -> bool:
	return amount <= gold


## Adds `amount` gold. A positive amount counts in `earned()` (total and per `source`: &"trade", &"loot",
## &"reward"). A negative amount removes gold (never below 0) and is not counted.
func add(amount: int, source: StringName = &"") -> void:
	if amount == 0:
		return
	if amount > 0:
		_earned_total += amount
		if source != &"":
			_earned[source] = int(_earned.get(source, 0)) + amount
	gold = maxi(0, gold + amount)
	changed.emit(gold)


## Gives back `amount` gold paid earlier (a cancelled contract, a refund): never counted in `earned()`. <= 0 = no-op.
func refund(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	changed.emit(gold)


## Spends `amount` if the team has it (true), else emits spend_failed (false).
func spend(amount: int) -> bool:
	if amount < 0:
		return false
	if gold < amount:
		spend_failed.emit()
		return false
	if amount == 0:
		return true
	gold -= amount
	changed.emit(gold)
	return true


## Gold earned since the start: all sources (`source` = &"") or one source (&"trade", &"loot", &"reward").
func earned(source: StringName = &"") -> int:
	if source == &"":
		return _earned_total
	return int(_earned.get(source, 0))


# ---------------------------------------------------------------- Bazaar

## True when the team has a living, completed Bazaar: a node of group "markets" (every Market, sites too;
## same rule as `Market.of_team`), or any Building whose BuildingType.kind is &"market".
func has_bazaar() -> bool:
	for node in get_tree().get_nodes_in_group(MARKETS_GROUP):
		var b := node as Building
		if b and int(b.team) == team and b.is_alive() and b.is_constructed():
			return true
	for b in Building.for_team(team):
		if b.building_type != null and b.building_type.kind == MARKET_KIND and b.is_constructed():
			return true
	return false


# ---------------------------------------------------------------- wares

## Display name of a ware (`Masons' Charter`), "" if unknown.
static func ware_name(id: StringName) -> String:
	return String(WARES[id]["name"]) if WARES.has(id) else ""


## Gold price of a ware, 0 if unknown.
static func ware_price(id: StringName) -> int:
	return int(WARES[id]["price"]) if WARES.has(id) else 0


## The effect line for the trade window (`Soldiers +8% attack damage`), "" if unknown.
static func ware_text(id: StringName) -> String:
	return String(WARES[id]["text"]) if WARES.has(id) else ""


## The Stats API modifier id of a unit ware: `ware:<id>`.
static func ware_modifier_id(id: StringName) -> StringName:
	return StringName(WARE_PREFIX + String(id))


func owns_ware(id: StringName) -> bool:
	return owned_wares.has(id)


## "" if the ware can be bought now, else the reason, in this order: "No Bazaar", "Already owned",
## "Not enough gold" ("Unknown ware" for a bad id).
func can_buy_ware(id: StringName) -> String:
	if not WARES.has(id):
		return MSG_UNKNOWN_WARE
	if not has_bazaar():
		return MSG_NO_BAZAAR
	if owned_wares.has(id):
		return MSG_OWNED
	if gold < ware_price(id):
		return MSG_NO_GOLD
	return ""


## Buys a ware: pays, applies it to the living units / buildings, emits ware_bought. "" = ok, else the reason
## of can_buy_ware ("Not enough gold" also emits spend_failed).
func buy_ware(id: StringName) -> String:
	var reason := can_buy_ware(id)
	if reason == MSG_NO_GOLD:
		spend_failed.emit()
	if reason != "":
		return reason
	if not spend(ware_price(id)):
		return MSG_NO_GOLD
	owned_wares.append(id)
	var ware: Dictionary = WARES[id]
	if not (ware["stats"] as Dictionary).is_empty():
		_has_unit_wares = true
		for node in get_tree().get_nodes_in_group(&"units"):
			apply_wares(node)
	if ware.has("hp_mult"):
		apply_building_hp_mult()
	ware_bought.emit(id)
	return ""


## Puts every owned unit ware that fits `unit` on it (modifier `ware:<id>`). Idempotent: a modifier already
## there is left alone. Only this team's living units; soldiers / caravans as in 3.2. `Unit._ready` calls it.
func apply_wares(unit: Node) -> void:
	if not _has_unit_wares or unit == null or not is_instance_valid(unit):
		return
	var u := unit as Unit
	if u == null or int(u.team) != team or not u.is_alive():
		return
	for id: StringName in owned_wares:
		var ware: Dictionary = WARES[id]
		var stats: Dictionary = ware["stats"]
		if stats.is_empty() or not unit_matches(StringName(ware["filter"]), u):
			continue
		var mod_id := ware_modifier_id(id)
		if not u.has_modifier(mod_id):
			u.add_modifier(mod_id, stats)


## Building max HP factor for this team: 1.15 with the Masons' Charter, else 1.0.
func building_hp_mult() -> float:
	var mult := 1.0
	for id: StringName in owned_wares:
		mult *= float((WARES[id] as Dictionary).get("hp_mult", 1.0))
	return mult


## Sends building_hp_mult() to every living building of the team (Building.set_hp_mult heals the gain).
## buy_ware calls it; new buildings read the factor themselves when they are created.
func apply_building_hp_mult() -> void:
	var mult := building_hp_mult()
	for node in get_tree().get_nodes_in_group(&"buildings"):
		if is_instance_valid(node) and int(node.get(&"team")) == team and node.has_method(&"set_hp_mult"):
			node.call(&"set_hp_mult", mult)


## Does a ware filter (&"soldiers", &"caravans") cover `u`? (&"buildings" never matches a unit.)
static func unit_matches(filter: StringName, u: Unit) -> bool:
	match filter:
		&"caravans":
			return is_caravan_unit(u)
		&"soldiers":
			return is_soldier_unit(u)
	return false


## A trade caravan (Caravan class / group "caravans", or UnitType.is_caravan / id "caravan").
static func is_caravan_unit(u: Unit) -> bool:
	if u.is_in_group(&"caravans") or u.has_method(&"command_trade"):
		return true
	var t := u.unit_type
	if t == null:
		return false
	var flag: Variant = t.get(&"is_caravan")
	if flag is bool and flag:
		return true
	return t.id == &"caravan"


## A hired Greywater Tracker (group "trackers" or UnitType id "greywater_tracker").
static func is_tracker_unit(u: Unit) -> bool:
	return u.is_in_group(&"trackers") or (u.unit_type != null and u.unit_type.id == &"greywater_tracker")


## "Soldiers" of 3.2: every unit except workers, caravans, wizards, champions and trackers.
static func is_soldier_unit(u: Unit) -> bool:
	# Champions join "champions" in Champion._init (no class reference: keeps this file independent of champion.gd).
	if u.is_worker() or u is Wizard or u.is_in_group(&"heroes") or u.is_in_group(&"champions"):
		return false
	return not is_caravan_unit(u) and not is_tracker_unit(u)


func _on_node_added(node: Node) -> void:
	# Safety net for units whose _ready does not call apply_wares: apply at the end of the frame, once the
	# spawner has set the team and the unit its groups.
	if not _has_unit_wares or not (node is Unit):
		return
	_pending.append(node)
	if not _flush_queued:
		_flush_queued = true
		_flush_pending.call_deferred()


func _flush_pending() -> void:
	_flush_queued = false
	var batch := _pending
	_pending = []
	for node: Variant in batch:
		if is_instance_valid(node) and (node as Node).is_inside_tree():
			apply_wares(node)


# ---------------------------------------------------------------- exchange

## "" if `amount` gold (floored to steps of 100) can be exchanged into `to` (&"crystals" / &"essence") now,
## else the reason: "No Bazaar", "Not enough gold".
func can_exchange(amount: int, to: StringName) -> String:
	if not EXCHANGE.has(to):
		return MSG_UNKNOWN_RESOURCE
	var cost := (amount / EXCHANGE_STEP) * EXCHANGE_STEP
	if cost <= 0:
		return MSG_STEP
	if not has_bazaar():
		return MSG_NO_BAZAAR
	if gold < cost:
		return MSG_NO_GOLD
	return ""


## Exchanges `amount` gold (steps of 100: 100, or 500 with Shift) into crystals (80 per 100) or essence
## (40 per 100). "" = ok, else the reason of can_exchange ("Not enough gold" also emits spend_failed).
func exchange(amount: int, to: StringName) -> String:
	var reason := can_exchange(amount, to)
	if reason == MSG_NO_GOLD:
		spend_failed.emit()
	if reason != "":
		return reason
	var steps := amount / EXCHANGE_STEP
	var cost := steps * EXCHANGE_STEP
	var received := steps * int(EXCHANGE[to])
	if to == &"crystals":
		var eco := Economy.for_team(team)
		if eco == null:
			return MSG_NO_TARGET
		if not spend(cost):
			return MSG_NO_GOLD
		eco.add(received)
	else:
		var bank := EssenceBank.for_team(team)
		if bank == null:
			return MSG_NO_TARGET
		if not spend(cost):
			return MSG_NO_GOLD
		bank.add(received)
	exchanged.emit(cost, to, received)
	return ""


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## Load: owns `ids` again without paying (the saved gold already paid them); unit wares and the HP factor re-apply.
func restore_wares(ids: Array) -> void:
	for v: Variant in ids:
		var id := StringName(str(v))
		if not WARES.has(id) or owned_wares.has(id):
			continue
		owned_wares.append(id)
		var ware: Dictionary = WARES[id]
		if not (ware["stats"] as Dictionary).is_empty():
			_has_unit_wares = true
		if ware.has("hp_mult"):
			apply_building_hp_mult()
	if _has_unit_wares and is_inside_tree():
		for node in get_tree().get_nodes_in_group(&"units"):
			apply_wares(node)
	changed.emit(gold)
