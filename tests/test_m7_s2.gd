extends SceneTree
## M7.S2 scripted headless run of mission 1: free Pell, light the 3 braziers (guards removed, Vessa kept
## alive), claim the crown, hold -> Events.mission_ended(true). Also checks E4 / E5 / E6 / E7 effects and waves.
## Run: godot --headless --path . -s tests/test_m7_s2.gd --fixed-fps 60 --quit-after 14000

const TASK_ID := "m7_s2"
const TIMEOUT_FRAMES := 12000

var main: Node
var frame := 0
var _wait := 0
var _events: Array[String] = []
var _victory := -1          # -1 none, 0 defeat, 1 victory
var _errors: Array[String] = []
var _step := 0
var _t0 := 0
var _plan: Array = []       # [brazier id, guard group to clear]


func _initialize() -> void:
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.objective_changed.connect(func(id: StringName, state: StringName) -> void:
			_events.append("%s=%s" % [id, state]))
		ev.mission_ended.connect(func(victory: bool) -> void: _victory = 1 if victory else 0)
	main = load("res://missions/mission_01.tscn").instantiate()
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
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
	var hero: Node3D = main.hero
	if hero.is_alive():
		hero.heal(1.0e6)
	var done := _run(hero)
	if _victory == 0:
		_errors.append("defeat")
		done = true
	if done or frame > TIMEOUT_FRAMES:
		if not done:
			_errors.append("timed out at step %d" % _step)
		print("m7_s2 game time %.0f s, waves %s, lit %d, victory=%s" % [main.match_time(), main.waves_fired,
				main.lit_count, _victory == 1])
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _kill(units: Array) -> void:
	for u in units:
		if is_instance_valid(u) and u.is_alive():
			u.take_damage(1.0e7, null)


func _put(hero: Node3D, at: Vector3) -> void:
	hero.global_position = at
	hero.command_stop()


func _run(hero: Node3D) -> bool:
	match _step:
		0:
			hero.death_guard = func(_a: Variant) -> bool:
				hero.hp = hero.max_hp
				return true
			_kill(main.guard_groups[&"G2"])
			_put(hero, main.pell.global_position + Vector3(0.0, 0.0, 3.0))
			_t0 = frame
			_step = 1
		1:
			if frame - _t0 >= 90:
				_check(main.objective_state("sec_peddler") == "done" and main.pell.is_shop(), "Pell freed (E4)")
				_plan = [[&"hearthward", &"G1"], [&"westwatch", &"G3"], [&"southgate", &"G4"]]
				_step = 2
		2:
			if _plan.is_empty():
				_step = 4
				return false
			var row: Array = _plan[0]
			_kill(main.guard_groups[row[1]])
			if row[0] == &"westwatch":
				main.westwatch_spire.take_damage(1.0e7, null)
			_put(hero, main.brazier(row[0]).global_position + Vector3(1.5, 0.0, 1.5))
			_t0 = frame
			_step = 3
		3:
			var b: Node = main.brazier(_plan[0][0])
			if b.lit:
				_plan.pop_front()
				_step = 2
			elif frame - _t0 > 400:
				_check(false, "brazier %s never lit" % b.brazier_id)
				return true
		4:
			_check(main.riders_unlocked and main.waves_fired.has(&"W2") and main.waves_fired.has(&"W3"),
					"E5 / W2 / W3 fired")
			_check(main.seal_broken and main.crown.can_be_claimed(), "seal broken (E6)")
			_check(_events.has("obj_crown=active") and _events.has("obj_braziers=done"), "obj_crown active")
			_kill(main.guard_groups[&"G5"])
			_put(hero, Vector3(0.5, 0.0, 0.5))
			_t0 = frame
			_step = 5
		5:
			if main.crown.is_worn():
				_check(_events.has("obj_hold=active") and main.waves_fired.has(&"final"), "E7: hold + final wave")
				_t0 = frame
				_step = 6
			elif frame - _t0 > 300:
				_check(false, "crown never claimed")
				return true
		6:
			if _victory == 1:
				_check(_events.has("obj_hold=done"), "obj_hold done")
				return true
	return false
