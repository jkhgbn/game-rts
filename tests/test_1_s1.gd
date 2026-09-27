extends SceneTree
## Task 1.S1: crystal nodes, workers gathering, node depletion (docs/design/economy.md).
## Run:  godot --headless --path . -s tests/test_1_s1.gd --fixed-fps 60 --quit-after 6000
## Checks: the 4 nodes (positions, amounts); the 3 starting workers are Workers already gathering;
## 3 workers on one node bring about 210 crystals in 60 s; a worker carries crystals between the
## node and the keep; a node reaching 0 disappears and its worker moves to a node within 30 m.

const TASK_ID := "1.S1"
const TIMEOUT_FRAMES := 5000
const MEASURE_FRAMES := 3600          # 60 s of game time
const INCOME_MIN := 180   # spec: "about 210"; the spec's positions give ~240 (7.3 s per trip)
const INCOME_MAX := 270

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _workers: Array = []
var _start_crystals := 0
var _carry_seen := false
var _depletion_started := false
var _node_b: Node
var _node_a: Node


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		_setup()
		if not _errors.is_empty():
			return _finish()
	for w in _workers:
		if is_instance_valid(w) and w.carried > 0:
			_carry_seen = true
	if frame == MEASURE_FRAMES:
		var income: int = main.economy.crystals - _start_crystals
		print("Income in 60 s with 3 workers on one node: %d (node_home_a left: %d)" % [
				income, _node_a.crystals_left])
		if income < INCOME_MIN or income > INCOME_MAX:
			_errors.append("income %d not in %d..%d" % [income, INCOME_MIN, INCOME_MAX])
		if _node_a.crystals_left != 600 - income - _carried_total():
			_errors.append("node_home_a left %d does not match income %d + carried %d" % [
					_node_a.crystals_left, income, _carried_total()])
		if not _carry_seen:
			_errors.append("no worker ever carried crystals")
		# Depletion: node_home_b has 5 left; worker 0 mines it out, then moves to node_home_a.
		_node_b.crystals_left = 5
		_workers[0].command_gather(_node_b)
		_depletion_started = true
	if _depletion_started and frame > MEASURE_FRAMES:
		var gone := not is_instance_valid(_node_b)
		var w = _workers[0]
		if gone and w.gather_node == _node_a and w.is_gathering():
			if get_nodes_in_group("crystal_nodes").size() != 3:
				_errors.append("crystal_nodes group has %d nodes after depletion" % get_nodes_in_group("crystal_nodes").size())
			return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (node_home_b gone: %s, worker 0 node: %s)" % [
				not is_instance_valid(_node_b), _workers[0].gather_node])
		return _finish()
	return false


func _setup() -> void:
	var expected := {
		&"node_home_a": [main.PLAYER_START + Vector3(-10, 0, -2), 600],
		&"node_home_b": [main.PLAYER_START + Vector3(2, 0, 10), 600],
		&"node_mid": [main.MID_CAMP + Vector3(4, 0, 4), 900],
		&"node_ruins": [main.ARTIFACT_POS + Vector3(6, 0, -7), 900],
	}
	var nodes := get_nodes_in_group("crystal_nodes")
	if nodes.size() != 4:
		_errors.append("%d crystal nodes, want 4" % nodes.size())
	for node in nodes:
		var cn := node as CrystalNode
		if cn == null or not expected.has(cn.node_id):
			_errors.append("unexpected node %s" % node.name)
			continue
		var e: Array = expected[cn.node_id]
		if cn.global_position.distance_to(e[0]) > 0.01 or cn.crystals_left != e[1]:
			_errors.append("%s at %s with %d" % [cn.node_id, cn.global_position, cn.crystals_left])
	_node_a = main.crystal_nodes[&"node_home_a"]
	_node_b = main.crystal_nodes[&"node_home_b"]

	for node in get_nodes_in_group("units"):
		if node is Unit and node.team == Unit.Team.PLAYER and node.is_worker():
			_workers.append(node)
	if _workers.size() != 3:
		_errors.append("%d player workers, want 3" % _workers.size())
		return
	for w in _workers:
		if not (w is Worker) or not w.has_method("command_gather"):
			_errors.append("%s is not a Worker" % w.unit_name)
			return
		if not w.is_gathering():
			_errors.append("a starting worker is not gathering")
	# All 3 on one node for the income check.
	for w in _workers:
		w.command_gather(_node_a)
	_start_crystals = main.economy.crystals
	if _start_crystals != 250:
		_errors.append("start crystals %d, want 250" % _start_crystals)


func _carried_total() -> int:
	var total := 0
	for w in _workers:
		total += w.carried
	return total


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true
