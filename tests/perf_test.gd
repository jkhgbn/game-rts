extends SceneTree
## Performance check: many units cross the map at once (pathfinding + avoidance load).
## Run:  godot --headless --path . -s tests/perf_test.gd --fixed-fps 60 --quit-after 3000
## Optional:  -- units=200  to change the army size (default 100).
## Prints one PERF line. Compare it with the baseline in docs/plan/waves.md.
## Headless = no rendering, so this measures game logic only (CPU), not graphics.
## Uses the wall clock: the Performance TIME_* monitors are not reliable in headless runs.

const RUN_FRAMES := 1500          # 25 s of game time at 60 fps
const BUDGET_MS_PER_100 := 8.0    # logic budget per frame for 100 units (a frame is 16.6 ms)

var main: Node
var unit_count := 100
var units: Array = []
var start_positions: Array = []
var frame := 0
var _wait := 0
var _start_usec := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("units="):
			unit_count = int(arg.substr(6))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL: navigation never finished baking")
			return true
		return false
	frame += 1
	if frame == 5:
		_setup_army()
	elif frame == 10:
		_start_usec = Time.get_ticks_usec()
	elif frame >= RUN_FRAMES:
		_report()
		return true
	return false


func _setup_army() -> void:
	# Remove every existing unit so nobody fights; this test is about movement only.
	for u in root.get_tree().get_nodes_in_group("units"):
		if u != main.hero:
			u.remove_from_group("units")
			u.queue_free()
	var cols := int(ceil(sqrt(float(unit_count))))
	for i in unit_count:
		var u: Unit = main.make_unit("Flame Guard")
		u.team = Unit.Team.PLAYER
		main.add_child(u)
		var offset := Vector3((i % cols - cols * 0.5) * 1.1, 0.0, (floori(float(i) / cols) - cols * 0.5) * 1.1)
		u.global_position = main.PLAYER_START + Vector3(6.0, 0.0, -6.0) + offset
		u.command_stop()
		units.append(u)
		start_positions.append(u.global_position)
	main.selection.select_units(units)
	main.selection.formation_move(main.ARTIFACT_POS + Vector3(-14.0, 0.0, 14.0))


func _report() -> void:
	var target: Vector3 = main.ARTIFACT_POS + Vector3(-14.0, 0.0, 14.0)
	var arrived := 0
	var stuck := 0
	for i in units.size():
		var u: Unit = units[i]
		if not is_instance_valid(u):
			continue
		if u.global_position.distance_to(target) < 15.0:
			arrived += 1
		elif u.global_position.distance_to(start_positions[i]) < 5.0:
			stuck += 1
	var ms_per_frame := (Time.get_ticks_usec() - _start_usec) / 1000.0 / float(RUN_FRAMES - 10)
	var budget := BUDGET_MS_PER_100 * unit_count / 100.0
	print("PERF units=%d ms_per_frame=%.2f budget=%.1f arrived=%d stuck=%d" % [
			unit_count, ms_per_frame, budget, arrived, stuck])
	print("PERF %s" % ("OK" if ms_per_frame <= budget and stuck == 0 else "OVER BUDGET"))
