extends SceneTree
## Task 1.S2: the keep trains units (docs/design/economy.md): selectable keep, queue of 5 with
## reserve-on-queue, full refund on cancel, slot 1 progress, spawn at the drop-off corner,
## walk to the rally point, gather rally on a crystal node, flag only while selected.
## Run:  godot --headless --path . -s tests/test_1_s2.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "1.S2"
const TIMEOUT_FRAMES := 3300

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var keep: Keep
var eco: Economy
var _known: Dictionary = {}          # units that existed before training
var _new_worker: Unit = null
var _new_guard: Unit = null
var _ground_rally := Vector3.ZERO
var _queue_signals := 0


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
	elif frame == 60:
		_cancel_slot_one()
	if frame > 1:
		_watch_spawns()
	if _new_guard and _flat(_new_guard.global_position, _ground_rally) < 2.0:
		_final_checks()
		return _finish()
	if not _errors.is_empty():
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (worker spawned: %s, guard spawned: %s)" % [_new_worker != null, _new_guard != null])
		return _finish()
	return false


func _setup() -> void:
	keep = main.keep
	eco = main.economy
	if keep == null or not keep.is_in_group("buildings") or (keep.collision_layer & 3) != 3:
		_errors.append("keep missing, not in 'buildings' or not on layers 1+2")
		return
	if keep.team != Unit.Team.PLAYER or keep.max_hp != 2500.0 or keep.hp != 2500.0 or not keep.is_alive():
		_errors.append("keep team/hp")
	var ids: Array[String] = []
	for t in keep.trainable_types():
		ids.append(String(t.id))
	if ids != ["cinder_hand"]:   # wave 2: the keep trains only workers
		_errors.append("trainable types %s" % [ids])
	# Selection ring + flag only while selected.
	var flag: Node3D = keep.get("_flag")
	if flag.visible:
		_errors.append("flag visible while not selected")
	keep.set_selected(true)
	if not keep.selected or not flag.visible:
		_errors.append("set_selected(true) did not show the flag")
	if _flat(flag.global_position, keep.global_position + Vector3(6, 0, -6)) > 0.01:
		_errors.append("default rally flag at %s" % flag.global_position)
	keep.set_selected(false)
	if flag.visible:
		_errors.append("flag still visible after deselect")

	# Freeze the income: stop the starting workers.
	for u in get_nodes_in_group("units"):
		if u.has_method("command_gather"):
			u.command_stop()
		_known[u] = true
	eco.crystals = 1000
	keep.queue_changed.connect(func() -> void: _queue_signals += 1)

	var hand := UnitType.find("cinder_hand")
	for i in 5:
		var r := keep.queue_unit(hand)
		if r != "":
			_errors.append("queue %d refused: %s" % [i, r])
	var sixth := keep.queue_unit(hand)
	if sixth != "Queue is full" or keep.can_queue(hand) != "Queue is full":
		_errors.append("6th queue gave '%s'" % sixth)
	_expect(750, 17, 5, "after queueing 5")
	keep.cancel(4)
	keep.cancel(3)
	keep.cancel(2)
	_expect(900, 14, 2, "after cancelling 3")
	if _queue_signals != 8:
		_errors.append("queue_changed fired %d times, want 8" % _queue_signals)


func _cancel_slot_one() -> void:
	var p := keep.train_progress()
	var want := 59.0 / 60.0 / 12.0
	if absf(p - want) > 0.02:
		_errors.append("progress %.3f after ~1 s, want %.3f" % [p, want])
	keep.cancel(0)   # slot 1: loses its progress
	if keep.train_progress() != 0.0:
		_errors.append("progress not reset after cancelling slot 1")
	_expect(950, 13, 1, "after cancelling slot 1")
	# Gather rally on node_home_b for the worker, then a 2nd worker that follows a ground rally
	# (wave 2: the keep trains only workers; it used to be a Flame Guard).
	keep.set_rally_node(main.crystal_nodes[&"node_home_b"])
	if not keep.rally_is_node():
		_errors.append("rally_is_node() false after set_rally_node")
	var r := keep.queue_unit(UnitType.find("cinder_hand"))
	if r != "":
		_errors.append("2nd worker refused: %s" % r)
	_expect(900, 14, 2, "after queueing a 2nd worker")


func _watch_spawns() -> void:
	for u in get_nodes_in_group("units"):
		if _known.has(u):
			continue
		_known[u] = true
		if _flat(u.global_position, keep.spawn_point()) > 1.0:
			_errors.append("%s spawned at %s, not at the spawn point" % [u.unit_name, u.global_position])
		if _flat(keep.spawn_point(), keep.global_position + Vector3(3.5, 0, -3.5)) > 0.01:
			_errors.append("spawn point is not keep + (3.5, -3.5)")
		if u.unit_name == "Cinder Hand" and _new_worker == null:
			_new_worker = u
			if not u.has_method("command_gather") or u.gather_node != main.crystal_nodes[&"node_home_b"]:
				_errors.append("trained worker did not follow the gather rally")
			_ground_rally = keep.global_position + Vector3(10.0, 0.0, -12.0)
			keep.set_rally_point(_ground_rally)
			if keep.rally_is_node():
				_errors.append("rally_is_node() true after set_rally_point")
		elif u.unit_name == "Cinder Hand":   # the 2nd worker walks to the ground rally
			_new_guard = u
			if keep.queue.size() != 0:
				_errors.append("queue not empty after the last spawn")
		else:
			_errors.append("unexpected unit %s" % u.unit_name)


func _final_checks() -> void:
	if _new_worker == null:
		_errors.append("worker never spawned")
	# The trained worker has been mining meanwhile, so crystals may be above 900.
	if eco.crystals < 900 or (eco.crystals - 900) % 10 != 0 or eco.pop_used != 14 or keep.queue.size() != 0:
		_errors.append("at the end: crystals %d pop %d queue %d, want 900+ 14 0" % [
				eco.crystals, eco.pop_used, keep.queue.size()])


func _expect(crystals: int, pop: int, queued: int, when: String) -> void:
	if eco.crystals != crystals or eco.pop_used != pop or keep.queue.size() != queued:
		_errors.append("%s: crystals %d pop %d queue %d, want %d %d %d" % [
				when, eco.crystals, eco.pop_used, keep.queue.size(), crystals, pop, queued])


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true
