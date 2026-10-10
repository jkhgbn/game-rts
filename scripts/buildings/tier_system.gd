class_name TierSystem
extends Node
## Keep tiers (docs/design/tiers.md): T1 Keep -> T2 "Stronghold" -> T3 "Citadel", per team.
## One node per game (the skirmish creates it, group "tier_systems"); missions have none unless they turn
## `tiers_enabled` on (mission 1: Stronghold only, max_tier / bots_upgrade, tiers.md 6).
## UI helpers (2026-09-30, the way up made obvious): status(team), unlocks(team, tier), unlock_text, announce_text.
## A team's tier = the highest tier of its living keeps (Keep.tier; the upgrade itself lives in Keep).
## UnitType.requires_tier / BuildingType.requires_tier gate training and building (gate_reason).
## Bots: bot_try_upgrade (commander rule 5) starts the upgrades on a per-difficulty timeline.

signal tier_changed(team: int, tier: int)

## THE switch: false = no tiers (everything counts as T3, nothing is gated, no keep upgrade button).
const ENABLED := true
const MSG_T2 := "Requires Stronghold"
const MSG_T3 := "Requires Citadel"
const NAMES: Array[String] = ["Keep", "Stronghold", "Citadel"]
## Upgrade to tier N (tiers.md 2): price, time, earliest match time the upgrade may START, needs a completed Hall.
const UPGRADES := {
	2: {"crystals": 200, "time": 60.0, "from": 210.0, "needs_hall": true},
	3: {"crystals": 300, "time": 90.0, "from": 345.0, "needs_hall": true},
}
## Keep effect per tier (index = tier - 1): max HP factor of the type's base, flat attack damage bonus.
const HP_MULT: Array[float] = [1.0, 1.2, 1.4]
const DAMAGE_BONUS: Array[float] = [0.0, 4.0, 8.0]
const MSG_NEEDS_HALL := "Needs a completed Hall"

## Bot timeline (tiers.md 4): match time (s) the bot starts saving for / starts the Stronghold and the Citadel,
## by Commander.Difficulty (0 easy, 1 normal, 2 hard). Normal: T2 done ~5:00, T3 done ~8:30.
const BOT_START := {0: [420.0, 720.0], 1: [240.0, 400.0], 2: [210.0, 345.0]}
## Seconds of saving (rule 5 paused) before the bot gives up for now and trains soldiers again.
const BOT_SAVE_WINDOW := 45.0
const BOT_RETRY := 20.0

const MSG_NOT_HERE := "Not in this mission"

## Match clock (the skirmish passes match_time); unset = physics time since the node entered the tree.
var match_time_source: Callable
## False = the "Available at m:ss" rule is skipped (tests, labs).
var time_gates := true
## Campaign knobs (tiers.md 6, 2026-09-30): the highest tier any keep may reach here (a mission caps it: the keep card
## then shows no button past it) and whether the bots upgrade their keeps (missions: false, the scripted enemy keeps its
## numbers).
var max_tier := 3
var bots_upgrade := true
## Pace factor on the tier timeline (PaceSwitch.tier_time_x: Blitz < 1): the earliest start ("from"), the upgrade
## time and the bot timeline (BOT_START) are multiplied by it. 1.0 = tiers.md values.
var pace_time_x := 1.0

var _tiers: Dictionary = {}          # team (int) -> cached tier (int)
var _forced: Dictionary = {}         # team -> tier set by set_tier() for a team without a keep
var _start_frame := 0
var _bot_hold: Dictionary = {}       # team -> match time until which the bot stops saving (gave up)
var _bot_saving: Dictionary = {}     # team -> match time the current saving started


func _enter_tree() -> void:
	add_to_group(&"tier_systems")
	_start_frame = Engine.get_physics_frames()


# ---------------------------------------------------------------- static API

## The team's keep tier (1-3). No TierSystem in the game (missions, old tests) or switch off: 3 (no gating).
static func tier_of(team: int) -> int:
	if not ENABLED:
		return 3
	var ts := instance()
	if ts == null:
		return 3
	return ts.get_tier(team)


## The TierSystem of the running game, or null (missions, switch off).
static func instance() -> TierSystem:
	if not ENABLED:
		return null
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"tier_systems") as TierSystem


## "" if `team` has tier `needed`, else "Requires Stronghold" / "Requires Citadel".
static func gate_reason(needed: int, team: int) -> String:
	if needed <= 1 or tier_of(team) >= needed:
		return ""
	return MSG_T2 if needed == 2 else MSG_T3


static func tier_name(tier: int) -> String:
	return NAMES[clampi(tier, 1, 3) - 1]


## Keep.upgrade calls it for the text of the completion message.
static func announce(team: int, tier: int) -> void:
	if team != Unit.Team.PLAYER:
		return
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = tree.current_scene if tree else null
	if scene == null:
		return
	var hud: Variant = scene.get(&"hud")
	if is_instance_valid(hud) and hud is Object and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", announce_text(team, tier), ANNOUNCE_SECONDS)


const ANNOUNCE_SECONDS := 7.0

## The completion message: "The Keep is now a Stronghold. New: Pyre Adept, Cinder Arbalest (Ember Hall) ·
## Kilnwarden (Keep)". Without a list (nothing new here): the first sentence only.
static func announce_text(team: int, tier: int) -> String:
	var text := "The Keep is now a %s" % tier_name(tier)
	var list := unlock_text(team, tier)
	if list != "":
		text += ". New: " + list
	return text


## What reaching `tier` opens for `team`, grouped by building, in card order: [{name, where, building, type, index}]
## (`where` = the building's display name, `index` = the slot in its trainable_types(), -1 for a Hall the team has not
## built yet). Own training buildings first (a mission's Hall lists only its mission units); with no own Hall, the
## kingdom's Hall type. The helper call reads "Old Vey (helper)".
static func unlocks(team: int, tier: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tier < 2:
		return out
	var seen := {}
	var has_hall := false
	var faction: StringName = &""
	for n in tree.get_nodes_in_group(&"buildings"):
		var b := n as TrainingBuilding
		if b == null or int(b.team) != team or not b.is_alive() or b.building_type == null:
			continue
		if b is Keep:
			faction = b.building_type.faction
		if b.building_type.kind == &"barracks":
			has_hall = true
		var types := b.trainable_types()
		for i in types.size():
			var t: UnitType = types[i]
			if t == null or t.requires_tier != tier or t.id == Keep.TIER_STUB_ID:
				continue
			var key := "%s|%s" % [t.id, b.building_type.id]
			if seen.has(key):
				continue
			seen[key] = true
			out.append({"name": _unlock_name(t), "where": b.building_type.display_name, "building": b, "type": t,
					"index": i})
	if not has_hall and faction != &"":
		for bid in BuildingType.ALL_IDS:
			var ht := BuildingType.find(String(bid))
			if ht == null or ht.faction != faction or ht.kind != &"barracks":
				continue
			var list: Array[UnitType] = []
			list.append_array(ht.trains)
			var bow := BowmanKit.hall_bowman(ht)
			if bow:
				list.append(bow)
			list.append_array(NewUnits12.hall_units(ht))
			for t in list:
				if t != null and t.requires_tier == tier:
					out.append({"name": _unlock_name(t), "where": ht.display_name, "building": null, "type": t, "index": -1})
			break
	# Hall units first, then the keep's (the order a player meets them).
	var halls := out.filter(func(d: Dictionary) -> bool: return not (d["building"] is Keep))
	var keeps := out.filter(func(d: Dictionary) -> bool: return d["building"] is Keep)
	var sorted: Array[Dictionary] = []
	sorted.assign(halls + keeps)
	return sorted


static func _unlock_name(t: UnitType) -> String:
	if t.display_name.begins_with("Call "):
		return "%s (helper)" % t.display_name.trim_prefix("Call ")
	return t.display_name


## "Pyre Adept, Cinder Arbalest (Ember Hall) · Kilnwarden (Keep)", "" when nothing opens.
static func unlock_text(team: int, tier: int) -> String:
	var groups: Array[String] = []
	var by_where := {}
	var order: Array[String] = []
	for d in unlocks(team, tier):
		var w := String(d["where"])
		if not by_where.has(w):
			by_where[w] = []
			order.append(w)
		if not (by_where[w] as Array).has(d["name"]):
			(by_where[w] as Array).append(d["name"])
	for w in order:
		groups.append("%s (%s)" % [", ".join(by_where[w]), w])
	return " · ".join(groups)


## Bots (commander rule 5): starts the next keep upgrade once the difficulty's time has come. Returns true while the
## bot is SAVING for it (rule 5 then trains nothing this tick) or when it just started it.
static func bot_try_upgrade(team: int, keep: Keep, eco: Economy, difficulty: int) -> bool:
	var ts := instance()
	if ts == null or not ts.bots_upgrade or keep == null or not is_instance_valid(keep) or eco == null \
			or not keep.is_alive():
		return false
	return ts._bot_step(team, keep, eco, difficulty)


# ---------------------------------------------------------------- instance

func get_tier(team: int) -> int:
	if not _tiers.has(team):
		refresh(team)
	return int(_tiers.get(team, 1))


## Recomputes the team's tier from its living keeps (Keep calls it on tier change / destruction).
func refresh(team: int) -> void:
	var best := 0
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k and int(k.team) == team and k.is_alive():
			best = maxi(best, k.tier)
	if best == 0:
		best = int(_forced.get(team, 1))
	var old := int(_tiers.get(team, 0))
	_tiers[team] = best
	if old != 0 and old != best:
		tier_changed.emit(team, best)


## Tests / cheats / campaign: puts every living keep of `team` at `tier` now (no cost, no time).
func set_tier(team: int, tier: int) -> void:
	tier = clampi(tier, 1, 3)
	_forced[team] = tier
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k and int(k.team) == team and k.is_alive():
			k.set_tier_now(tier)
	refresh(team)


## Campaign start state (mission-e2-01.md, mission-04.md): every living keep of `team` starts at `tier` quietly
## (Keep.set_start_tier: no announcement, no timer); a team without a keep reads `tier` too. Mid-mission is fine.
func set_start_tier(team: int, tier: int) -> void:
	tier = clampi(tier, 1, 3)
	_forced[team] = tier
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k and int(k.team) == team and k.is_alive():
			k.set_start_tier(tier)
	refresh(team)


## Seconds of match time.
func now() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	return float(Engine.get_physics_frames() - _start_frame) / float(maxi(1, Engine.physics_ticks_per_second))


## The team-level needs of the upgrade to `to_tier` ("" = ok): the match time and a completed own Hall.
func upgrade_reason(team: int, to_tier: int) -> String:
	if not UPGRADES.has(to_tier):
		return "Already a Citadel"
	if to_tier > max_tier:
		return MSG_NOT_HERE
	var u: Dictionary = UPGRADES[to_tier]
	if time_gates and now() < start_time(to_tier):
		return "Available at %s" % clock(start_time(to_tier))
	if bool(u["needs_hall"]) and not _has_hall(team):
		return MSG_NEEDS_HALL
	return ""


## Earliest match time (s) the upgrade to `to_tier` may start (UPGRADES "from").
func start_time(to_tier: int) -> float:
	return float((UPGRADES.get(to_tier, {}) as Dictionary).get("from", 0.0)) * pace_time_x


## Seconds the upgrade to `to_tier` takes here (UPGRADES "time" x the game's pace_time_x; Keep reads this).
static func upgrade_seconds(to_tier: int) -> float:
	var ts := instance()
	return float((UPGRADES.get(to_tier, {}) as Dictionary).get("time", 0.0)) * (ts.pace_time_x if ts else 1.0)


## "3:30".
static func clock(seconds: float) -> String:
	var s := maxi(0, roundi(seconds))
	return "%d:%02d" % [s / 60, s % 60]


## The highest tier `team` may still reach here (max_tier; 3 without a TierSystem).
static func cap() -> int:
	var ts := instance()
	return ts.max_tier if ts else 3


## The team's keep the tier button lives on: the upgrading one, else the highest tier living finished keep (null if none).
static func keep_of(team: int) -> Keep:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var best: Keep = null
	for n in tree.get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k == null or int(k.team) != team or not k.is_alive() or not k.is_constructed():
			continue
		if k.is_upgrading():
			return k
		if best == null or k.tier > best.tier:
			best = k
	return best


## The UI's view of the team's next keep upgrade (hint, tier chip, card): {tier, next (0 = none here), name (next tier's),
## upgrading (bool), progress (0-1), left (s), reason ("" = can start now; crystals are NOT counted), crystals, time,
## from (s), short_crystals (bool), keep}. Empty without a TierSystem or a keep.
static func status(team: int) -> Dictionary:
	var ts := instance()
	var k := keep_of(team)
	if ts == null or k == null:
		return {}
	var out := {"tier": k.tier, "next": 0, "name": "", "upgrading": k.is_upgrading(), "progress": k.upgrade_progress(),
			"left": k.upgrade_time_left(), "reason": "", "crystals": 0, "time": 0.0, "from": 0.0,
			"short_crystals": false, "keep": k}
	var nxt := k.tier + 1
	if k.is_upgrading():
		out["next"] = nxt
		out["name"] = tier_name(nxt)
		return out
	if nxt > 3 or nxt > ts.max_tier:
		return out
	out["next"] = nxt
	out["name"] = tier_name(nxt)
	out["crystals"] = k.upgrade_cost()
	out["time"] = k.upgrade_time()
	out["from"] = ts.start_time(nxt)
	out["reason"] = ts.upgrade_reason(team, nxt)
	var eco := Economy.for_team(team)
	out["short_crystals"] = eco == null or not eco.can_afford(k.upgrade_cost())
	return out


func _has_hall(team: int) -> bool:
	for b in Building.for_team(team):
		if b.building_type and b.building_type.kind == &"barracks" and b.is_constructed():
			return true
	return false


func _bot_step(team: int, keep: Keep, eco: Economy, difficulty: int) -> bool:
	if keep.is_upgrading() or keep.tier >= mini(3, max_tier):
		return false
	var t := now()
	var times: Array = BOT_START.get(clampi(difficulty, 0, 2), BOT_START[1])
	if t < float(times[keep.tier - 1]) * pace_time_x or t < float(_bot_hold.get(team, 0.0)):
		return false
	var reason := keep.can_upgrade()
	if reason == "":
		keep.upgrade()
		_bot_saving.erase(team)
		return true
	if reason != TrainingBuilding.REASON_NO_CRYSTALS:
		return false
	# Short of crystals: save (no soldiers) for up to BOT_SAVE_WINDOW s, then fight on and retry later.
	var since := float(_bot_saving.get(team, t))
	_bot_saving[team] = since
	if t - since > BOT_SAVE_WINDOW:
		_bot_saving.erase(team)
		_bot_hold[team] = t + BOT_RETRY
		return false
	return true
