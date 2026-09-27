class_name UnitDances
extends RefCounted
## Unit dances (ideas-inbox 2026-09-27): the glue between gameplay / UI and the models' `play_clip(&"dance_*")`
## (art/units/kit/character_model.gd "dances"). Match end: the winners play dance_victory, the losers
## dance_surrender (alive, not fighting). Chat command "dance 1 / 2 / 3" (scripts/ui/chat_line.gd) starts one on the
## selected units. Units whose model can't dance (beasts, mounts, flyers, buildings, placeholders) are skipped.
## An order (command_move / attack / attack_move / stop / hold) stops the dance (Unit calls the model's stop_clip).

const VICTORY := &"dance_victory"
const SURRENDER := &"dance_surrender"
const RANDOM := &"dance_random"
## "dance 1" / "dance 2" / "dance 3".
const BY_NUMBER: Array[StringName] = [VICTORY, SURRENDER, RANDOM]


## Plays `clip` on `unit` when it is alive and its model can dance. Returns true when it dances.
static func play(unit: Node, clip: StringName) -> bool:
	if unit == null or not is_instance_valid(unit) or not unit.has_method(&"model_call"):
		return false
	if unit.has_method(&"is_alive") and not bool(unit.call(&"is_alive")):
		return false
	if not bool(unit.call(&"model_has", &"play_clip")):
		return false
	return bool(unit.call(&"model_call", &"play_clip", [clip]))


## Stops the dance of `unit` (if any).
static func stop(unit: Node) -> void:
	if unit != null and is_instance_valid(unit) and unit.has_method(&"model_call"):
		unit.call(&"model_call", &"stop_clip")


## The clip `unit` dances (&"" = none).
static func current(unit: Node) -> StringName:
	if unit == null or not is_instance_valid(unit) or not unit.has_method(&"model_has") \
			or not bool(unit.call(&"model_has", &"current_clip")):
		return &""
	return StringName(unit.call(&"model_call", &"current_clip"))


## True while `unit` is fighting (an attack target that is still alive).
static func in_combat(unit: Node) -> bool:
	var t: Variant = unit.get(&"attack_target")
	if t is Node and is_instance_valid(t) and (t as Node).has_method(&"is_alive"):
		return bool((t as Node).call(&"is_alive"))
	return false


## Match end: `winner_team`'s units (alive, not fighting) play dance_victory, every other non-neutral team's units
## dance_surrender. Returns the number of dancers.
static func match_end(tree: SceneTree, winner_team: int) -> int:
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group(&"units"):
		var team: Variant = node.get(&"team")
		if team == null or int(team) == Unit.Team.NEUTRAL or in_combat(node):
			continue
		if play(node, VICTORY if int(team) == winner_team else SURRENDER):
			n += 1
	return n


## Starts `clip` on each unit of `units` (the selection). Returns the number of dancers.
static func play_all(units: Array, clip: StringName) -> int:
	var n := 0
	for u in units:
		if u is Node and play(u, clip):
			n += 1
	return n
