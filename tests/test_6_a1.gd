extends SceneTree
## Task 6.A1: the bot sees through its fog of war like a player (scenes/skirmish.tscn, normal Shadow bot).
## - A Flame Guard 14 m from a Shadow Shade (inside the old 16 m rule, outside the Shade's 10 m sight):
##   the fog cell is not VISIBLE for Shadow and the bot's memory does not hold it for 4 s;
## - the Guard moved 6 m from the Shade (in sight): it enters memory within 3 s;
## - the scout (interval set to 12 s) walks to points that were unexplored for Shadow when chosen, the
##   first one becomes explored, and it picks a second point.
## Run:  godot --headless --path . -s tests/test_6_a1.gd --fixed-fps 60 --quit-after 14000

const TASK_ID := "6.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const TIMEOUT_FRAMES := 13000
const FIRE := 0
const SHADOW := 1
const SHADE_POS := Vector3(10.0, 0.0, -45.0)
const HIDDEN_OFFSET := Vector3(-14.0, 0.0, 0.0)
const SEEN_OFFSET := Vector3(-6.0, 0.0, 0.0)
const HIDDEN_TIME := 4.0
const LEARN_TIME := 3.0

var main: Node
var bot: Node
var fog: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _t := 0.0

var _shade: Unit
var _guard: Unit
var _phase := 0            # 0 hidden, 1 moved into sight, 2 done
var _phase_at := 0.0
var _learned_at := -1.0
var _goals_checked := 0
var _first_goal := Vector3.INF
var _first_explored_at := -1.0


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == SHADOW:
			bot = child
	if bot == null:
		bot = COMMANDER.new()
		bot.team = SHADOW
		main.add_child(bot)
	bot.debug_log = true


func _process(_delta: float) -> bool:
	if bot.ai != null and frame == 0:
		bot.ai.scout_interval = 12.0   # read by the bot's first think, after the navmesh bake
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_t = main.match_time()
	if frame == 1:
		fog = main.get(&"fog")
		if fog == null or not fog.enabled:
			print("FAIL %s: no fog of war in the skirmish" % TASK_ID)
			return true
		_spawn()
	_check_hidden()
	_check_scout()
	if _phase == 2 and _goals_checked >= 2 and _first_explored_at >= 0.0:
		return _finish()
	if frame > TIMEOUT_FRAMES or main.game_over:
		return _finish()
	return false


func _spawn() -> void:
	_shade = main.make_unit("shade")
	_shade.team = SHADOW
	main.add_child(_shade)
	_shade.global_position = SHADE_POS
	_shade.command_stop()
	_guard = main.make_unit("flame_guard")
	_guard.team = FIRE
	main.add_child(_guard)
	_guard.global_position = SHADE_POS + HIDDEN_OFFSET
	_guard.command_stop()
	_phase_at = _t


func _in_memory(u: Unit) -> bool:
	return bot.memory.units.has(u.get_instance_id())


func _check_hidden() -> void:
	if _phase == 2:
		return
	_shade.global_position = SHADE_POS   # pinned: the bot would walk it to the rally
	if _phase == 0:
		_guard.global_position = SHADE_POS + HIDDEN_OFFSET
		if _in_memory(_guard):
			_errors.append("the bot knew the hidden Guard at %.1f s (fog visible %s)" % [_t,
					str(fog.is_visible(SHADOW, _guard.global_position))])
			_phase = 2
			return
		if _t - _phase_at >= HIDDEN_TIME:
			if fog.is_visible(SHADOW, _guard.global_position):
				_errors.append("the Guard's cell is VISIBLE for Shadow at 14 m from a Shade")
			print("hidden Guard (14 m, old rule would see it) not in memory for %.1f s" % HIDDEN_TIME)
			_guard.global_position = SHADE_POS + SEEN_OFFSET
			_guard.command_stop()
			_phase = 1
			_phase_at = _t
		return
	_guard.global_position = SHADE_POS + SEEN_OFFSET
	if _in_memory(_guard):
		_learned_at = _t - _phase_at
		print("Guard learned %.1f s after coming into sight (seen_strength %.0f)" % [_learned_at, bot.seen_strength])
		_end_hidden()
	elif _t - _phase_at > LEARN_TIME:
		_errors.append("the Guard in sight never entered memory")
		_end_hidden()


func _end_hidden() -> void:
	_phase = 2
	_shade.take_damage(1.0e6, null)
	_guard.take_damage(1.0e6, null)


func _check_scout() -> void:
	var goals: Array = bot.scout_goals
	while _goals_checked < goals.size():
		var g: Vector3 = goals[_goals_checked]
		# checked the frame it was chosen: it must still be unexplored for Shadow
		print("scout goal %d: (%d, %d) at %.1f s" % [_goals_checked + 1, roundi(g.x), roundi(g.z), _t])
		if fog.is_explored(SHADOW, g):
			_errors.append("scout goal %s was already explored" % str(g))
		if _goals_checked == 0:
			_first_goal = g
		_goals_checked += 1
	if _first_goal != Vector3.INF and _first_explored_at < 0.0 and fog.is_explored(SHADOW, _first_goal):
		_first_explored_at = _t
		print("first scout goal explored at %.1f s" % _t)


func _finish() -> bool:
	if _phase != 2:
		_errors.append("hidden / seen check never finished")
	if _goals_checked == 0:
		_errors.append("the bot never scouted")
	elif _first_explored_at < 0.0:
		_errors.append("the first scout goal never became explored")
	elif _goals_checked < 2:
		_errors.append("the scout never picked a second unexplored point")
	for line in bot.log_lines:
		if line.contains("SCOUT"):
			print(line)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
