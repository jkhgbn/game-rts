class_name Economy
extends Node
## Crystals and population of one team. One Economy node per team, in group "economies".
## Find one with Economy.for_team(team). Numbers: docs/design/economy.md.
##
## Population: pop_used = pop of living units (counted automatically when a Unit of this team
## with a UnitType enters the scene tree, freed when it dies or leaves the tree) + pop reserved
## by training queues (reserve_pop / release_pop, used by TrainingBuilding).
## pop_cap = the pop bonus of the team's finished buildings (keep +20, hearth / hovel +10), max
## `max_pop_cap` (40; Nature 50: kingdom-nature.md section 1, set by set_kingdom, which the team's
## pop buildings call when they complete).
## It may drop under pop_used when a building is destroyed; training then waits for units to die.

signal changed
signal spend_failed

const START_CRYSTALS := 250
const MAX_POP_CAP := 40   ## The default hard cap. Read `max_pop_cap` for this team's cap.
## Hard pop cap per kingdom when it differs from MAX_POP_CAP.
const KINGDOM_POP_CAPS := {&"nature": 50}

@export var team: Unit.Team = Unit.Team.PLAYER
@export var crystals: int = START_CRYSTALS
@export var pop_cap: int = 0   ## Read only (set by buildings through add_pop_bonus).

var max_pop_cap: int = MAX_POP_CAP   ## Read only: this team's hard cap (set_kingdom).
var kingdom: StringName = &""        ## Read only: &"" until set_kingdom.

var pop_used: int = 0   ## Read only: living units + queued units.
var gathered_total: int = 0   ## Read only: crystals delivered by workers since the start (end-screen stat).

var _pop_bonus: int = 0
var _living_pop: int = 0
var _queued_pop: int = 0
var _unit_pop: Dictionary = {}   # Unit -> pop it counts for


## The Economy of `team`, or null if there is none in the scene.
static func for_team(for_team_id: int) -> Economy:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("economies"):
		var eco := node as Economy
		if eco and eco.team == for_team_id and not eco.is_queued_for_deletion():
			return eco
	return null


func _ready() -> void:
	add_to_group("economies")
	# Count units that are already in the scene, then every unit added later.
	for node in get_tree().get_nodes_in_group("units"):
		_on_node_added(node)
	get_tree().node_added.connect(_on_node_added)


func can_afford(cost: int) -> bool:
	return crystals >= cost


## Takes `cost` crystals. Returns false (and emits spend_failed) if there are not enough.
func spend(cost: int) -> bool:
	if cost > crystals:
		spend_failed.emit()
		return false
	crystals -= cost
	changed.emit()
	return true


func add(amount: int) -> void:
	if amount == 0:
		return
	crystals += amount
	changed.emit()


## Crystals delivered by a worker: add() + counted in gathered_total (refunds use add() only).
func add_gathered(amount: int) -> void:
	gathered_total += maxi(amount, 0)
	add(amount)


## Buildings call this when they are finished (+bonus) and destroyed (-bonus).
func add_pop_bonus(amount: int) -> void:
	_pop_bonus += amount
	pop_cap = clampi(_pop_bonus, 0, max_pop_cap)
	changed.emit()


## The hard pop cap of a kingdom (&"nature" 50, the others MAX_POP_CAP = 40).
static func pop_cap_limit_for(faction: StringName) -> int:
	return int(KINGDOM_POP_CAPS.get(faction, MAX_POP_CAP))


## Sets the team's kingdom, and with it max_pop_cap (buildings call it; the skirmish may too).
func set_kingdom(faction: StringName) -> void:
	if faction == kingdom:
		return
	kingdom = faction
	max_pop_cap = pop_cap_limit_for(faction)
	pop_cap = clampi(_pop_bonus, 0, max_pop_cap)
	changed.emit()


## True if `pop` more population fits under the cap.
func has_pop_for(pop: int) -> bool:
	return pop_used + pop <= pop_cap


## Reserves population for a queued unit (training queues call it; the unit's own pop is
## counted when it spawns, so release the reservation right before spawning it).
func reserve_pop(pop: int) -> void:
	_queued_pop += pop
	_update_pop()


func release_pop(pop: int) -> void:
	_queued_pop = maxi(0, _queued_pop - pop)
	_update_pop()


func _update_pop() -> void:
	pop_used = _living_pop + _queued_pop
	changed.emit()


func _on_node_added(node: Node) -> void:
	var unit := node as Unit
	if unit == null or unit.team != team or unit.unit_type == null or _unit_pop.has(unit):
		return
	if not unit.is_alive():
		return
	_unit_pop[unit] = unit.unit_type.pop
	_living_pop += unit.unit_type.pop
	if not unit.died.is_connected(_release_unit):
		unit.died.connect(_release_unit)
	unit.tree_exiting.connect(_release_unit.bind(unit), CONNECT_ONE_SHOT)
	_update_pop()


func _release_unit(unit: Unit) -> void:
	if not _unit_pop.has(unit):
		return
	_living_pop -= int(_unit_pop[unit])
	_unit_pop.erase(unit)
	_update_pop()
