extends SceneTree
## Avoidance perf guards (perf-research-2026-10-12 P1 / P2 / P12).
## Run:  godot --headless --path . -s tests/test_perf_avoidance.gd --fixed-fps 60 --quit-after 3000
## Checks:
## 1. P2: avoidance runs single-threaded (replay determinism, docs/plan/replay-lab.md).
## 2. P1: every unit's NavigationAgent3D uses unit.gd's AVOID_* constants (written explicitly on purpose).
## 3. P12 lab hooks: the Perf Lab's --physsplit wrapper finds Unit._on_velocity_computed on the agent's
##    velocity_computed signal, and a wrapped unit still walks (the handler fires every physics frame it moves).
## 4. The --noavoid variant: an agent without avoidance never emits velocity_computed (units would stand still), so
##    the lab feeds each handler its agent's velocity from the SceneTree's _physics_process; fed units must walk.
## Prints "PASS perf_avoidance" or "FAIL perf_avoidance: <reason>".
## Test-script rules (CLAUDE.md): no autoload names; game classes reached through the scene.

const TASK_ID := "perf_avoidance"
const WALK_FRAMES := 180          # 3 s of game time
const MIN_WALK_M := 3.0           # a walking Flame Guard covers far more than this in 3 s

var main: Node
var frame := 0
var _wait := 0
var _wrapped: Array[Node] = []
var _plain: Array[Node] = []
var _start: Array[Vector3] = []
var _calls := 0
var _fail := ""


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 5:
		_setup()
		if _fail != "":
			print("FAIL %s: %s" % [TASK_ID, _fail])
			return true
	if frame == 5 + WALK_FRAMES:
		_check_walk()
		print("FAIL %s: %s" % [TASK_ID, _fail] if _fail != "" else "PASS %s" % TASK_ID)
		return true
	return false


func _setup() -> void:
	if bool(ProjectSettings.get_setting("navigation/avoidance/thread_model/avoidance_use_multiple_threads", true)):
		_fail = "avoidance_use_multiple_threads is on (P2: replays need single-threaded avoidance)"
		return
	var consts: Dictionary = (load("res://scripts/units/unit.gd") as Script).get_script_constant_map()
	for k: String in ["AVOID_NEIGHBOR_DISTANCE", "AVOID_MAX_NEIGHBORS", "AVOID_TIME_HORIZON"]:
		if not consts.has(k):
			_fail = "unit.gd lost the constant %s" % k
			return
	for u: Node in get_nodes_in_group(&"units"):
		if u != main.hero:
			u.remove_from_group(&"units")
			u.queue_free()
	for i in 6:
		var u: Node3D = main.make_unit("Flame Guard")
		u.set(&"team", 0)
		main.add_child(u)
		u.global_position = main.PLAYER_START + Vector3(6.0 + 3.0 * float(i), 0.0, -6.0)
		var ag: Variant = u.get(&"_agent")
		if not ag is NavigationAgent3D:
			_fail = "unit has no NavigationAgent3D in _agent (the Perf Lab variants read it)"
			return
		var a := ag as NavigationAgent3D
		if not is_equal_approx(a.neighbor_distance, float(consts["AVOID_NEIGHBOR_DISTANCE"])) \
				or a.max_neighbors != int(consts["AVOID_MAX_NEIGHBORS"]) \
				or not is_equal_approx(a.time_horizon_agents, float(consts["AVOID_TIME_HORIZON"])):
			_fail = "agent avoidance values differ from unit.gd's AVOID_* constants"
			return
		var orig := Callable(u, &"_on_velocity_computed")
		if not a.velocity_computed.is_connected(orig):
			_fail = "velocity_computed is not connected to Unit._on_velocity_computed (Perf Lab --physsplit)"
			return
		if i < 3:   # the lab's wrapper, as in perf_lab.gd _wrap_velocity_handler
			a.velocity_computed.disconnect(orig)
			a.velocity_computed.connect(_timed.bind(u))
			_wrapped.append(u)
		else:       # the --noavoid variant
			a.avoidance_enabled = false
			_plain.append(u)
		u.call(&"command_move", u.global_position + Vector3(0.0, 0.0, 12.0))
		_start.append(u.global_position)


## As perf_lab.gd's _physics_process for --noavoid.
func _physics_process(_delta: float) -> bool:
	for u: Node in _plain:
		if is_instance_valid(u) and u.is_physics_processing():
			u.call(&"_on_velocity_computed", (u.get(&"_agent") as NavigationAgent3D).velocity)
	return false


func _timed(v: Vector3, u: Node) -> void:
	u.call(&"_on_velocity_computed", v)
	_calls += 1


func _check_walk() -> void:
	var all: Array[Node] = []
	all.append_array(_wrapped)
	all.append_array(_plain)
	for i in all.size():
		var u := all[i] as Node3D
		if not is_instance_valid(u):
			_fail = "a test unit died"
			return
		var moved := Vector2(u.global_position.x - _start[i].x, u.global_position.z - _start[i].z).length()
		if moved < MIN_WALK_M:
			_fail = "%s unit %d walked only %.2f m" % ["wrapped" if i < _wrapped.size() else "no-avoidance", i, moved]
			return
	if _calls < WALK_FRAMES:   # 3 wrapped walkers, about one call each per physics frame
		_fail = "the wrapped handler fired only %d times" % _calls
