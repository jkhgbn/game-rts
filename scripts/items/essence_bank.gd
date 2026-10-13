class_name EssenceBank
extends Node
## Essence, the item currency of one team (docs/design/items.md "Essence"). One node per team in group
## `"essence_banks"`; get it with `EssenceBank.for_team(team)` (created under the current scene if missing).
## Income: start 150, +1 per second, and KILL_ESSENCE_RATIO (60 %, balance-1) of the victim's XP value (levels.md),
## rounded, on every kill credited to
## the team, wherever the wizard is. Kills by neutral units (wardens) pay nobody.

signal changed
## A spend() was refused (the HUD flashes the essence counter red).
signal spend_failed

const START_ESSENCE := 150
const TRICKLE_PER_SECOND := 1.0
## Share of the victim's XP value paid as essence on a kill (docs/design/balance-1.md 2d).
const KILL_ESSENCE_RATIO := 0.6
const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL

@export var team: int = 0
@export var essence: int = START_ESSENCE
## Set false to stop the +1/s trickle (scripted missions, tests).
@export var trickle_enabled := true
## Set false so kills pay nothing (MissionBase no-economy / hidden-economy phases, mission-e3-02.md phase 1).
@export var kill_income_enabled := true

var _trickle_acc := 0.0

static var _waiting: Dictionary = {}   # team -> [EssenceBank, parent]: made by for_team, add_child still deferred


## The bank of `for_team_id`, created under the current scene the first time.
static func for_team(for_team_id: int) -> EssenceBank:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("essence_banks"):
		var bank := node as EssenceBank
		if bank and bank.team == for_team_id and not bank.is_queued_for_deletion():
			return bank
	# A bank made a moment ago and still waiting for its deferred add_child is not in the group yet (groups
	# register only in the tree): reuse it, never make a second one (code review R5-7).
	# Only while its parent is still alive: a parent freed before the deferred add_child (F9, scene change)
	# leaves an orphan that must not reach the next match.
	var row: Array = _waiting.get(for_team_id, [])
	if row.size() == 2 and is_instance_valid(row[0]) and is_instance_valid(row[1]):
		var waiting := row[0] as Node
		var waiting_parent := row[1] as Node
		if not waiting.is_inside_tree() and not waiting.is_queued_for_deletion() \
				and not waiting_parent.is_queued_for_deletion() and waiting_parent.is_inside_tree():
			return waiting as EssenceBank
	if row.size() == 2 and is_instance_valid(row[0]) and not (row[0] as Node).is_inside_tree():
		(row[0] as Node).queue_free()   # the orphan
	_waiting.erase(for_team_id)
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	var created := EssenceBank.new()
	created.team = for_team_id
	created.name = "EssenceBank%d" % for_team_id
	created.add_to_group("essence_banks")
	if parent.is_inside_tree() and not parent.is_node_ready():
		_waiting[for_team_id] = [created, parent]
		parent.add_child.call_deferred(created)
	else:
		parent.add_child(created)
	return created


func _enter_tree() -> void:
	var row: Array = _waiting.get(team, [])
	if not row.is_empty() and is_same(row[0], self):
		_waiting.erase(team)


func _ready() -> void:
	add_to_group("essence_banks")
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died"):
		events.connect(&"unit_died", _on_unit_died)
	get_tree().node_added.connect(_on_node_added)
	for b in get_tree().get_nodes_in_group("buildings"):
		_watch_building(b)


func _process(delta: float) -> void:
	if not trickle_enabled:
		return
	_trickle_acc += delta * TRICKLE_PER_SECOND
	if _trickle_acc >= 1.0:
		var whole := floori(_trickle_acc)
		_trickle_acc -= whole
		add(whole)


func can_afford(amount: int) -> bool:
	return essence >= amount


func add(amount: int) -> void:
	if amount == 0:
		return
	essence = maxi(0, essence + amount)
	changed.emit()


## Spends `amount` if the team has it (true), else emits spend_failed (false).
func spend(amount: int) -> bool:
	if amount < 0:
		return false
	if essence < amount:
		spend_failed.emit()
		return false
	essence -= amount
	changed.emit()
	return true


# ---------------------------------------------------------------- kill income

func _on_unit_died(victim: Node) -> void:
	_credit(victim)


func _on_node_added(node: Node) -> void:
	if node is Building:
		_watch_building(node)


func _watch_building(node: Node) -> void:
	if node is Building and not node.is_connected(&"destroyed", _on_building_destroyed):
		node.connect(&"destroyed", _on_building_destroyed)


func _on_building_destroyed(building: Node) -> void:
	# A cancelled construction site also emits destroyed: only a building beaten to 0 HP pays.
	if building is Node3D and float(building.get(&"hp")) <= 0.0:
		_credit(building)


func _credit(victim: Node) -> void:
	if victim == null or not is_instance_valid(victim) or not kill_income_enabled:
		return
	var killer_team := killer_team_of(victim)
	if killer_team != team or team == NEUTRAL_TEAM:
		return
	var victim_team: Variant = victim.get(&"team")
	if victim_team == null or int(victim_team) == team:
		return
	add(kill_essence(Wizard.xp_value_of(victim)))


## Essence for a kill worth xp_value XP: 60 %, rounded to the nearest integer (a Shade, 40 XP, gives 24).
static func kill_essence(xp_value: int) -> int:
	return roundi(float(xp_value) * KILL_ESSENCE_RATIO)


## The team that dealt the killing blow on `victim`, or -1 when unknown.
static func killer_team_of(victim: Node) -> int:
	if victim == null or not is_instance_valid(victim):
		return -1
	for prop: StringName in [&"killer_team", &"last_attacker_team"]:
		var t: Variant = victim.get(prop)
		if t is int:
			return t
	for prop: StringName in [&"killer", &"last_attacker"]:
		var a: Variant = victim.get(prop)
		if typeof(a) == TYPE_OBJECT and is_instance_valid(a):
			var t: Variant = (a as Object).get(&"team")
			if t != null:
				return int(t)
	if victim.has_meta(&"last_attacker_team"):
		return int(victim.get_meta(&"last_attacker_team"))
	return -1
