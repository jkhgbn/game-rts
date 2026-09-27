class_name TierSystem
extends Node
## Keep tiers (docs/design/tiers.md): T1 Keep -> T2 "Stronghold" -> T3 "Citadel", per team.
## One node per game (the skirmish creates it, group "tier_systems"); missions have none.
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

## Match clock (the skirmish passes match_time); unset = physics time since the node entered the tree.
var match_time_source: Callable
## False = the "Available at m:ss" rule is skipped (tests, labs).
var time_gates := true

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
		var text := "The Keep is now a %s" % tier_name(tier)
		if tier == 3:
			text += ": tier-3 units and your helper are open"
		(hud as Object).call(&"show_message", text, 4.0)


## Bots (commander rule 5): starts the next keep upgrade once the difficulty's time has come. Returns true while the
## bot is SAVING for it (rule 5 then trains nothing this tick) or when it just started it.
static func bot_try_upgrade(team: int, keep: Keep, eco: Economy, difficulty: int) -> bool:
	var ts := instance()
	if ts == null or keep == null or not is_instance_valid(keep) or eco == null or not keep.is_alive():
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


## Seconds of match time.
func now() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	return float(Engine.get_physics_frames() - _start_frame) / float(maxi(1, Engine.physics_ticks_per_second))


## The team-level needs of the upgrade to `to_tier` ("" = ok): the match time and a completed own Hall.
func upgrade_reason(team: int, to_tier: int) -> String:
	if not UPGRADES.has(to_tier):
		return "Already a Citadel"
	var u: Dictionary = UPGRADES[to_tier]
	if time_gates and now() < float(u["from"]):
		var s := roundi(float(u["from"]))
		return "Available at %d:%02d" % [s / 60, s % 60]
	if bool(u["needs_hall"]) and not _has_hall(team):
		return MSG_NEEDS_HALL
	return ""


func _has_hall(team: int) -> bool:
	for b in Building.for_team(team):
		if b.building_type and b.building_type.kind == &"barracks" and b.is_constructed():
			return true
	return false


func _bot_step(team: int, keep: Keep, eco: Economy, difficulty: int) -> bool:
	if keep.is_upgrading() or keep.tier >= 3:
		return false
	var t := now()
	var times: Array = BOT_START.get(clampi(difficulty, 0, 2), BOT_START[1])
	if t < float(times[keep.tier - 1]) or t < float(_bot_hold.get(team, 0.0)):
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
