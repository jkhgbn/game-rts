extends SceneTree
## Bug fix (bot-vs-bot balance games): ThiefBand._start_strike handed a freed (depleted) crystal node to
## TradeNetwork.record_workers_raided -> SCRIPT ERROR. A freed target node must never reach the network, and a worker
## band whose node ran dry must not start a strike.
## Run: godot --headless --path . -s tests/test_thief_freed_node.gd --quit-after 600

const TASK_ID := "thief_freed_node"

const NET_SRC := """extends Node
var calls: Array = []
func record_workers_raided(team: int, node: Node) -> void:
	calls.append([team, node])
"""

var _fails: Array[String] = []
var _frame := 0


func _initialize() -> void:
	pass


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_run()
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _run() -> void:
	var net_script := GDScript.new()
	net_script.source_code = NET_SRC
	net_script.reload()
	var net := Node.new()
	net.set_script(net_script)
	net.add_to_group(&"trade_network")
	root.add_child(net)

	var node := Node3D.new()
	root.add_child(node)
	var band := ThiefBand.new()
	root.add_child(band)   # setup() never called: the band does not think on its own
	band.target = {"kind": &"workers", "team": 0, "node": node}
	band._kind = &"workers"
	band._team = 0
	_check(band._target_node() == node, "a live target node is returned")
	_check(not band._target_node_gone(), "a live node is not gone")

	node.free()
	_check(band._target_node() == null, "a freed node reads as null")
	_check(band._target_node_gone(), "a freed node is gone")
	_check(band._pick_worker(true) == null, "no worker victim once the node is freed")
	_check(not band._node_pos().is_finite() or band._node_pos() == band.spot, "node_pos falls back to the spot")

	var victim := Node3D.new()
	root.add_child(victim)
	band._start_strike(victim)   # used to pass the freed node on (SCRIPT ERROR)
	var calls: Array = net.get(&"calls")
	_check(calls.size() == 1, "the raid is still recorded once (got %d)" % calls.size())
	if calls.size() == 1:
		_check(calls[0][1] == null, "the network gets null, never a freed node")

	# An entry without a node is not "gone" (road bands).
	band.target = {"kind": &"road", "team": 0}
	_check(not band._target_node_gone(), "an entry without a node is not gone")
	band.queue_free()
	victim.queue_free()
	net.queue_free()
