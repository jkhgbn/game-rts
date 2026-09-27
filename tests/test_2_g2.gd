extends SceneTree
## Task 2.G2: Wizard.set_move_input(dir), direct control of Vessa.
## - A pending order (fireball out of range = walk + cast) is dropped as soon as input starts.
## - While the input is held she walks that way at ~4.6 m/s and ignores a nearby enemy.
## - Released: she stands still, then auto-aggro picks a nearby enemy again.
## Run:  godot --headless --path . -s tests/test_2_g2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "2.G2"
const TIMEOUT_FRAMES := 600
const START_INPUT := 10
const MEASURE_FROM := 40
const MEASURE_TO := 100
const RELEASE := 130
const STILL_FROM := 160
const STILL_TO := 220
const EXPECTED_SPEED := 4.6

var main: Node
var frame := 0
var _wait := 0

var hero   # untyped: Wizard references Events at runtime only, but keep tests loose
var dir := Vector3(1.0, 0.0, -1.0).normalized()   # along the road toward the ruins
var side_shade: Unit
var bait: Unit
var pos_a := Vector3.ZERO
var speed := 0.0
var dir_dot := 0.0
var still_a := Vector3.ZERO
var drift := 0.0
var aggro_ok := false
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
	hero = main.hero
	_step()
	if not errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
		return true
	if aggro_ok:
		print("speed %.2f m/s (dot %.3f), drift after release %.3f m, auto-aggro resumed" % [speed, dir_dot, drift])
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (speed %.2f, drift %.3f, aggro %s)" % [TASK_ID, speed, drift, aggro_ok])
		return true
	return false


func _spawn(type_id: String, team: Unit.Team, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _step() -> void:
	if frame == 1:
		for u in get_nodes_in_group("units"):
			if u != hero:
				u.remove_from_group("units")
				u.queue_free()
		return
	if frame == 2:
		# Fireball far out of range: she walks toward it with a pending cast.
		var reason: String = hero.command_fireball(main.ARTIFACT_POS)
		if reason != "":
			errors.append("command_fireball refused: %s" % reason)
		return
	if frame < START_INPUT:
		return

	if frame == START_INPUT:
		if not bool(hero.get(&"_has_pending_cast")):
			errors.append("setup: no pending cast before the input")
		# A passive enemy 6 m to the side, inside aggro range (9): she must ignore it while walking.
		var side := Vector3(1.0, 0.0, 1.0).normalized()
		side_shade = _spawn("shade", Unit.Team.ENEMY, hero.global_position + dir * 3.0 + side * 6.0)
		side_shade.aggro_range = 0.0

	if frame >= START_INPUT and frame < RELEASE:
		hero.set_move_input(dir)   # the UI calls it every frame while a key is held
		if frame == START_INPUT:
			if bool(hero.get(&"_has_pending_cast")):
				errors.append("pending cast not dropped")
			if hero.get_move_input() != dir:
				errors.append("get_move_input() returned %s" % hero.get_move_input())
		if hero.attack_target != null:
			errors.append("she targeted %s while walking" % hero.attack_target)
		if frame == 60:
			hero.command_move(main.ARTIFACT_POS + Vector3(0.0, 0.0, 30.0))   # ignored: the keys win
		if frame == MEASURE_FROM:
			pos_a = hero.global_position
		elif frame == MEASURE_TO:
			var moved: Vector3 = hero.global_position - pos_a
			moved.y = 0.0
			speed = moved.length() / (float(MEASURE_TO - MEASURE_FROM) / 60.0)
			dir_dot = moved.normalized().dot(dir)
			if absf(speed - EXPECTED_SPEED) > 0.3:
				errors.append("walked at %.2f m/s, expected %.1f" % [speed, EXPECTED_SPEED])
			if dir_dot < 0.97:
				errors.append("walked off direction (dot %.3f)" % dir_dot)
		return

	if frame == RELEASE:
		hero.set_move_input(Vector3.ZERO)
		if hero.get_move_input() != Vector3.ZERO:
			errors.append("get_move_input() not ZERO after release")
		if is_instance_valid(side_shade):
			side_shade.queue_free()   # far behind now anyway; keep the stillness check clean
			side_shade.remove_from_group("units")
		return
	if frame == STILL_FROM:
		still_a = hero.global_position
	if frame > STILL_FROM and frame <= STILL_TO:
		var p: Vector3 = hero.global_position
		drift = maxf(drift, Vector2(p.x - still_a.x, p.z - still_a.z).length())
		if drift > 0.1:
			errors.append("she kept moving after release (%.2f m)" % drift)
		if bool(hero.get(&"_has_pending_cast")):
			errors.append("pending cast came back")
	if frame == STILL_TO:
		bait = _spawn("shade", Unit.Team.ENEMY, hero.global_position + dir * 6.0)
		bait.aggro_range = 0.0
	if frame > STILL_TO and is_instance_valid(bait) and hero.attack_target == bait:
		aggro_ok = true
	if frame > STILL_TO + 60 and not aggro_ok:
		errors.append("auto-aggro did not resume after release")
