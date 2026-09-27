extends SceneTree
## Task 1.G2: attack-move and hold (unit side).
## - An attack-moving group stops for an enemy on its way, kills it, then resumes and arrives.
## - A held unit never moves: it ignores an enemy outside attack range, then kills one that
##   comes into range, without taking a step.
## Run:  godot --headless --path . -s tests/test_1_g2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.G2"
const TIMEOUT_FRAMES := 2400

const GROUP_START := Vector3(-26.0, 0.0, 26.0)   # on the road from the base to the mid camp
const GROUP_GOAL := Vector3(-10.0, 0.0, 10.0)
const BLOCKER_POS := Vector3(-18.0, 0.0, 18.0)

var main: Node
var frame := 0
var _wait := 0

var group: Array = []
var blocker: Unit
var engaged := false
var goal_reached := false

var holder: Unit
var holder_start := Vector3.ZERO
var bait: Unit
var bait_sent := false
var max_hold_drift := 0.0
var errors: Array[String] = []


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
		_clear_units()
	elif frame == 2:
		_setup()
	elif frame > 2:
		_watch()
		if not errors.is_empty():
			print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
			return true
		if _check_done():
			print("attack-move: engaged=%s arrived=%s  hold: drift=%.3f m" % [engaged, goal_reached, max_hold_drift])
			print("PASS %s" % TASK_ID)
			return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (engaged=%s blocker_dead=%s arrived=%s bait_dead=%s drift=%.3f)" % [
				TASK_ID, engaged, not is_instance_valid(blocker) or not blocker.is_alive(), goal_reached,
				not is_instance_valid(bait) or not bait.is_alive(), max_hold_drift])
		return true
	return false


func _clear_units() -> void:
	for u in get_nodes_in_group("units"):
		if u != main.hero:
			u.remove_from_group("units")
			u.queue_free()


func _spawn(type_id: String, team: Unit.Team, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _setup() -> void:
	# Attack-move: 3 guards walk through a Shade standing on the road.
	for i in 3:
		var u := _spawn("flame_guard", Unit.Team.PLAYER, GROUP_START + Vector3(i * 1.2 - 1.2, 0.0, 0.0))
		group.append(u)
	blocker = _spawn("shade", Unit.Team.ENEMY, BLOCKER_POS)
	blocker.aggro_range = 0.0   # waits for them, so the attack-movers must pick the fight
	for u in group:
		u.command_attack_move(GROUP_GOAL)

	# Hold: a guard at the mid camp, a passive Shade 5 m away (inside aggro, outside attack range).
	holder = _spawn("flame_guard", Unit.Team.PLAYER, main.MID_CAMP)
	holder_start = holder.global_position
	holder.command_hold()
	bait = _spawn("shade", Unit.Team.ENEMY, main.MID_CAMP + Vector3(5.0, 0.0, 0.0))
	bait.aggro_range = 0.0


func _watch() -> void:
	for u in group:
		if is_instance_valid(u) and is_instance_valid(blocker) and u.attack_target == blocker:
			engaged = true
			if not u.is_attack_moving():
				errors.append("attack-move flag lost while fighting")
	if is_instance_valid(holder) and holder.is_alive():
		var p: Vector3 = holder.global_position
		max_hold_drift = max(max_hold_drift, Vector2(p.x - holder_start.x, p.z - holder_start.z).length())
		if not holder.is_holding():
			errors.append("hold flag lost")
		if frame < 200 and holder.attack_target != null:
			errors.append("held unit targeted an enemy out of attack range")
	# After 3 s of the bait standing out of range, the bait attacks the held guard.
	if frame == 200 and is_instance_valid(bait):
		bait.command_attack(holder)
		bait_sent = true
	if max_hold_drift > 0.3:
		errors.append("held unit moved %.2f m" % max_hold_drift)
	if engaged and (not is_instance_valid(blocker) or not blocker.is_alive()):
		var arrived := 0
		for u in group:
			if is_instance_valid(u) and u.global_position.distance_to(GROUP_GOAL) < 3.0:
				arrived += 1
		if arrived == group.size():
			goal_reached = true


func _check_done() -> bool:
	var bait_dead: bool = not is_instance_valid(bait) or not bait.is_alive()
	return goal_reached and bait_sent and bait_dead and is_instance_valid(holder) and holder.is_alive()
