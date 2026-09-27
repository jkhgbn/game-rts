class_name HelperRoster
extends Node
## One per team (group "helper_rosters"): the team's tier-3 helper (docs/design/t3-helpers.md section 3).
## Called at the keep: the keep card lists `call_type()` ("Call Old Vey", 350 crystals + 200 essence, 60 s, pop 4,
## requires the Citadel) and, once the helper has fallen, `revive_type()` ("Revive Old Vey", 120 + 20 x level essence,
## 25 + 5 x level s). Both are runtime stub UnitTypes that go through the keep queue (TrainingBuilding hooks in T3Kit).
## One per team: "Already called" while queued, alive or fallen. The helper's pop (4) stays reserved from the queue on.
## Death never ends a match (the helper is not a building). Switch: T3Kit.ENABLED (+ T3Kit.enabled_here()).

signal helper_called(team: int, helper_id: StringName)
signal helper_ready(helper: Helper)
signal helper_fallen(helper: Helper)
signal helper_revived(helper: Helper)

const CALL_ID := &"call_helper"
const REVIVE_ID := &"revive_helper"
const REVIVE_BASE := 120
const REVIVE_PER_LEVEL := 20
const REVIVE_TIME_BASE := 25.0
const REVIVE_TIME_PER_LEVEL := 5.0
const REASON_ALREADY := "Already called"
const REASON_NOT_FALLEN := "Not fallen"
const REASON_NO_HOME := "No home"
const REASON_NO_ESSENCE := "Not enough essence"
const REASON_NO_HELPER := "No helper for this kingdom"

@export var team := 1
var helper: Helper = null
var kingdom: StringName = &""
## The team's Stormbottle Genie (T3Kit.hire_genie): &"none", &"hiring", &"alive", &"bottled" (dead: re-hire for essence).
var genie: Unit = null
var genie_state: StringName = &"none"

var _state: StringName = &"none"   # none / queued / alive / fallen / reviving
var _call_type: UnitType
var _revive_type: UnitType
var _pop_held := false


## The roster of `for_team` (created under the current scene on first use), or null without a scene.
static func for_team(for_team: int) -> HelperRoster:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"helper_rosters"):
		var r := n as HelperRoster
		if r and r.team == for_team and not r.is_queued_for_deletion():
			return r
	var scene := tree.current_scene
	if scene == null:
		return null
	var r := HelperRoster.new()
	r.team = for_team
	r.name = "HelperRoster%d" % for_team
	r.add_to_group(&"helper_rosters")
	scene.add_child(r)
	return r


## The wizard of `for_team` whose kingdom is `k` (else any wizard of the team), alive or dead.
static func wizard_of(tree: SceneTree, for_team: int, k: StringName = &"") -> Unit:
	if tree == null:
		return null
	var any: Unit = null
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for n in tree.get_nodes_in_group(group):
			var w := n as Unit
			if w == null or int(w.team) != for_team or w.is_in_group(&"champions"):
				continue
			if k == &"" or StringName(str(w.get(&"kingdom"))) == k:
				return w
			if any == null:
				any = w
	return any


func _ready() -> void:
	add_to_group(&"helper_rosters")


## The kingdom of the team (its wizard's, else the skirmish setting).
func team_kingdom() -> StringName:
	if kingdom != &"":
		return kingdom
	var w := wizard_of(get_tree(), team) if is_inside_tree() else null
	if w and w.get(&"kingdom") != null:
		return StringName(str(w.get(&"kingdom")))
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene and scene.has_method(&"kingdom_of"):
		return StringName(str(scene.call(&"kingdom_of", team)))
	return &"fire" if team == 0 else &"shadow"


func helper_type() -> HelperType:
	return HelperType.for_kingdom(team_kingdom())


## &"none", &"queued", &"alive", &"fallen" (a revive in the queue still reads &"fallen").
func state() -> StringName:
	if _state == &"reviving":
		return &"fallen"
	return _state


func level() -> int:
	if helper and is_instance_valid(helper):
		return helper.level
	var w := wizard_of(get_tree(), team, team_kingdom()) if is_inside_tree() else null
	return w.level if w else 1


func revive_cost() -> int:
	return REVIVE_BASE + REVIVE_PER_LEVEL * level()


func revive_time() -> float:
	return REVIVE_TIME_BASE + REVIVE_TIME_PER_LEVEL * float(level())


## "Call <name>" stub (cost / pop / time / tier from the HelperType), or null without a helper.
func call_type() -> UnitType:
	var ht := helper_type()
	if ht == null:
		return null
	if _call_type == null:
		_call_type = UnitType.new()
		_call_type.id = CALL_ID
		_call_type.faction = ht.kingdom
		_call_type.requires_tier = 3
		_call_type.commandable = false
		_call_type.display_name = "Call %s" % ht.display_name
		_call_type.cost = ht.call_crystals
		_call_type.pop = ht.pop
		_call_type.train_time = ht.call_time
	return _call_type


func revive_type() -> UnitType:
	var ht := helper_type()
	if ht == null:
		return null
	if _revive_type == null:
		_revive_type = UnitType.new()
		_revive_type.id = REVIVE_ID
		_revive_type.faction = ht.kingdom
		_revive_type.cost = 0
		_revive_type.pop = 0
		_revive_type.commandable = false
	_revive_type.display_name = "Revive %s" % ht.display_name
	if _state != &"reviving":
		_revive_type.train_time = revive_time()
	return _revive_type


## The stub the keep card shows now: call (none / queued) or revive (fallen), null while alive.
func card_type() -> UnitType:
	match _state:
		&"none", &"queued":
			return call_type()
		&"fallen", &"reviving":
			return revive_type()
	return null


## Section-3 refusals in order (the tier gate itself is the keep's "Requires Citadel", checked before this).
func can_call() -> String:
	if helper_type() == null:
		return REASON_NO_HELPER
	if _state != &"none":
		return REASON_ALREADY
	var ht := helper_type()
	var eco := Economy.for_team(team)
	if eco and not eco.has_pop_for(ht.pop):
		return TrainingBuilding.REASON_POP_CAP
	if eco and not eco.can_afford(ht.call_crystals):
		return TrainingBuilding.REASON_NO_CRYSTALS
	if not _essence_ok(ht.call_essence):
		return REASON_NO_ESSENCE
	return ""


## Queues the call at the team's keep. "" = queued.
func call_helper() -> String:
	var keep := _home_keep()
	if keep == null:
		return REASON_NO_HOME
	return keep.queue_unit(call_type())


func can_revive() -> String:
	if _state != &"fallen":
		return REASON_NOT_FALLEN
	if _home_keep() == null:
		return REASON_NO_HOME
	if not _essence_ok(revive_cost()):
		return REASON_NO_ESSENCE
	return ""


func revive() -> String:
	var keep := _home_keep()
	if keep == null:
		return REASON_NO_HOME
	return keep.queue_unit(revive_type())


# ---------------------------------------------------------------- keep queue hooks (T3Kit -> TrainingBuilding)

## Extra refusal for a stub at the keep ("" = fine; crystals / pop / queue are the keep's own checks).
func gate_reason(type: UnitType) -> String:
	if type.id == CALL_ID:
		if _state != &"none":
			return REASON_ALREADY
		if not _essence_ok(helper_type().call_essence):
			return REASON_NO_ESSENCE
	elif type.id == REVIVE_ID:
		if _state != &"fallen":
			return REASON_NOT_FALLEN
		if not _essence_ok(revive_cost()):
			return REASON_NO_ESSENCE
	return ""


func on_queued(type: UnitType) -> void:
	var bank := EssenceBank.for_team(team)
	if type.id == CALL_ID:
		if bank:
			bank.spend(helper_type().call_essence)
		_state = &"queued"
		helper_called.emit(team, helper_type().id)
		_announce(&"calling")
	elif type.id == REVIVE_ID:
		if bank:
			bank.spend(revive_cost())
		_revive_type.train_time = revive_time()
		_state = &"reviving"


func on_cancelled(type: UnitType) -> void:
	var bank := EssenceBank.for_team(team)
	if type.id == CALL_ID and _state == &"queued":
		if bank:
			bank.add(helper_type().call_essence)
		_state = &"none"
	elif type.id == REVIVE_ID and _state == &"reviving":
		if bank:
			bank.add(revive_cost())
		_state = &"fallen"


## The keep finished a stub: spawn or revive at `at`.
func on_trained(type: UnitType, at: Vector3) -> void:
	if type.id == CALL_ID:
		spawn_helper(at)
	elif type.id == REVIVE_ID and helper and is_instance_valid(helper):
		helper.respawn(at)
		_state = &"alive"
		helper_revived.emit(helper)
		_announce(&"revived")


## Creates the team's helper at `at` (the call's end; tests may call it directly). Returns it.
func spawn_helper(at: Vector3) -> Helper:
	var ht := helper_type()
	if ht == null or not is_inside_tree():
		return null
	var w := wizard_of(get_tree(), team, ht.kingdom)
	var h := Helper.new()
	h.apply_helper_type(ht, w.level if w else 1)
	h.team = team as Unit.Team
	var parent := get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(h)
	h.global_position = at
	h.command_stop()
	if w:
		h.bond_to(w)
	h.died.connect(_on_helper_died)
	helper = h
	_state = &"alive"
	if not _pop_held:
		var eco := Economy.for_team(team)
		if eco:
			eco.reserve_pop(ht.pop)   # the helper's 4 pop, kept while alive and while fallen
		_pop_held = true
	if h.model_has(&"play_arrival"):
		h.model_call(&"play_arrival")
	helper_ready.emit(h)
	_announce(&"ready")
	print("T3: team %d %s takes the field (level %d)" % [team, ht.display_name, h.level])
	return h


## The Genie walked out (T3Kit._genie_arrives): at 0 HP it returns to its bottle (re-hire for essence).
func set_genie(u: Unit) -> void:
	genie = u
	genie_state = &"alive"
	u.died.connect(func(_d: Unit) -> void:
		genie = null
		genie_state = &"bottled")


func _on_helper_died(_u: Unit) -> void:
	_state = &"fallen"
	helper_fallen.emit(helper)
	_announce(&"fallen")


func _home_keep() -> Keep:
	if not is_inside_tree():
		return null
	var scene := get_tree().current_scene
	if scene and scene.has_method(&"keep_of"):
		var k: Variant = scene.call(&"keep_of", team)
		if k is Keep:
			return k
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k and int(k.team) == team and k.is_alive():
			return k
	return null


func _essence_ok(n: int) -> bool:
	var bank := EssenceBank.for_team(team)
	return bank == null or bank.can_afford(n)


# Player-side messages (section 3 "Warnings"), through the HUD when there is one.
func _announce(what: StringName) -> void:
	if not is_inside_tree():
		return
	var ht := helper_type()
	var name_ := ht.display_name if ht else "The helper"
	var own := team == 0
	var text := ""
	match what:
		&"calling":
			text = ("%s answers the call" % name_) if own else ("The enemy calls %s!" % name_)
		&"ready":
			text = "%s takes the field!" % name_
		&"fallen":
			text = "%s has fallen" % name_
		&"revived":
			text = "%s returns" % name_
	var scene := get_tree().current_scene
	var hud: Variant = scene.get(&"hud") if scene else null
	if hud is Object and is_instance_valid(hud) and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, 3.0)
