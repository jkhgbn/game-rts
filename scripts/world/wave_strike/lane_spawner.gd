class_name LaneSpawner
extends Node
## One player's spawn pad (docs/design/wave-strike.md 7.3): takes a horn's unit list and spawns it one unit every
## rules.spawn_stagger s on a grid in front of the gate (8 across the lane, rows behind), each unit with a lateral
## offset that it keeps along the lane (LaneMarch). The level makes the unit (WaveStrikeLevel.spawn_lane_unit).

const COLS := 8
const COL_GAP := 2.0
const ROW_GAP := 1.8

var seat := 0
var team: int = Unit.Team.PLAYER
var gate := Vector3.ZERO
var forward := Vector3.RIGHT        ## the walking direction at the gate
var level: Node                     ## WaveStrikeLevel
var stagger := 0.15
var lateral_max := 8.0
var spawned_total := 0

var _queue: Array[StringName] = []
var _slot := 0
var _left := 0.0


func setup(p_seat: int, p_team: int, p_gate: Vector3, p_forward: Vector3, p_level: Node, rules: WaveStrikeRules) -> void:
	seat = p_seat
	team = p_team
	gate = p_gate
	forward = p_forward.normalized()
	level = p_level
	stagger = rules.spawn_stagger
	lateral_max = rules.lane_lateral
	name = "LaneSpawner%d" % seat


## Queues one horn's units (melee first: MusterRoster.spawn_list order).
func queue_wave(ids: Array[StringName]) -> void:
	_queue.append_array(ids)
	_slot = 0


func pending() -> int:
	return _queue.size()


## Advances the spawn clock (called by the director with its own delta).
func tick(delta: float) -> void:
	if _queue.is_empty():
		return
	_left -= delta
	while _left <= 0.0 and not _queue.is_empty():
		_left += stagger
		var id: StringName = _queue.pop_front()
		_spawn_one(id)
	if _queue.is_empty():
		_left = 0.0


func _spawn_one(id: StringName) -> void:
	var col := _slot % COLS
	var row := _slot / COLS
	_slot += 1
	var side := Vector3(-forward.z, 0.0, forward.x)
	var frac := (float(col) + 0.5) / float(COLS) * 2.0 - 1.0   # -1..1 across
	var lat := frac * lateral_max
	var pos := gate + side * (frac * COLS * COL_GAP * 0.5) - forward * (row * ROW_GAP)
	if level and level.has_method(&"spawn_lane_unit"):
		var u: Variant = level.call(&"spawn_lane_unit", seat, id, pos, lat)
		if u != null:
			spawned_total += 1
