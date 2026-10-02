extends SceneTree
## MT2 perf gate (docs/design/map-production.md 4.3 "Performance"): the perf_test.gd load (100 Flame Guards cross the
## map: pathfinding + avoidance) on Crown Hollow as scenes/skirmish.tscn, then on a LayoutLevel (default: Crown Hollow
## rebuilt from crown_hollow_level.map; `map=<_layout.tres or .map>` for any map). PASS when the LayoutLevel stays in
## live Crown Hollow's frame time (scenes/skirmish.tscn, same load, same run) within 15 % + 0.5 ms with no stuck unit
## (perf_test.gd's 8 ms / 100 units is a main.tscn budget: printed as a note).
## Bots off; the crowd starts 8 m from the player's start toward the map centre and walks to 19.8 m short of the
## centre (perf_test.gd's goal on Crown Hollow).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt2_perf.gd --fixed-fps 60 --quit-after 12000 [-- map=...]
## Prints "PASS mt2_perf" or "FAIL mt2_perf: <reasons>".

const TASK_ID := "mt2_perf"
const MapLab := preload("res://tools/map_lab/map_lab.gd")
const RUN_FRAMES := 1500
const UNITS := 100
const BUDGET_MS_PER_100 := 8.0

var map_path := "res://data/maps/crown_hollow_level.map"
var runs: Array = []      ## [scene, layout or null]
var results: Array = []   ## [{label, ms, arrived, stuck}]
var level: Node
var frame := 0
var wait := 0
var units: Array = []
var starts: Array = []
var target := Vector3.ZERO
var t_start := 0
var gap := 0
var fails: Array[String] = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("map="):
			map_path = a.substr(4)
	var lay: Resource = LayoutLevel.load_layout(map_path)
	if lay == null:
		print("FAIL %s: no layout %s" % [TASK_ID, map_path])
		quit(1)
		return
	runs.append(["res://scenes/skirmish.tscn", null])   # the reference: live Crown Hollow, same load, same machine
	runs.append(["res://scenes/layout_level.tscn", lay])
	_next()


func _next() -> void:
	var r: Array = runs.pop_front()
	level = (load(r[0]) as PackedScene).instantiate()
	if r[1] != null:
		level.set(&"layout", r[1])
	MapLab._disable_bots(level)
	root.add_child(level)
	frame = 0
	wait = 0
	units.clear()
	starts.clear()


func _process(_delta: float) -> bool:
	if level == null:
		gap += 1
		if gap > 5:
			gap = 0
			_next()
		return false
	MapLab._disable_bots(level)
	if level.get(&"hero") == null:
		wait += 1
		if wait > 6000:
			fails.append("level never started")
			return _done()
		return false
	frame += 1
	if frame == 5:
		_setup()
	elif frame == 10:
		t_start = Time.get_ticks_usec()
	elif frame >= RUN_FRAMES:
		_measure()
		level.queue_free()
		level = null
		if runs.is_empty():
			return _done()
	return false


func _setup() -> void:
	for u in get_nodes_in_group("units"):
		if u != level.get(&"hero"):
			u.remove_from_group("units")
			u.queue_free()
	var start: Vector3 = level.call(&"start_position", 0)
	var toward := (-start).normalized()
	target = -toward * 19.8   # perf_test.gd's goal: 19.8 m short of the centre on the player's side
	var cols := int(ceil(sqrt(float(UNITS))))
	var side := Vector3(toward.z, 0.0, -toward.x)
	for i in UNITS:
		var u: Unit = level.call(&"make_unit", "Flame Guard")
		u.team = Unit.Team.PLAYER
		level.add_child(u)
		var off := side * (float(i % cols) - cols * 0.5) * 1.1 + toward * (8.0 + float(i / cols) * 1.1)
		u.global_position = start + off
		u.command_stop()
		units.append(u)
		starts.append(u.global_position)
	var sel: Node = level.get(&"selection")
	sel.call(&"select_units", units)
	sel.call(&"formation_move", target)


func _measure() -> void:
	var ms := (Time.get_ticks_usec() - t_start) / 1000.0 / float(RUN_FRAMES - 10)
	var arrived := 0
	var stuck := 0
	for i in units.size():
		var u: Unit = units[i]
		if not is_instance_valid(u):
			continue
		if u.global_position.distance_to(target) < 18.0:
			arrived += 1
		elif u.global_position.distance_to(starts[i]) < 5.0:
			stuck += 1
	var label := String((level.get_script() as Script).resource_path.get_file())
	results.append({"label": label, "ms": ms, "arrived": arrived, "stuck": stuck})
	print("  %s: %.2f ms/frame, %d arrived, %d stuck (MapInfo %.0f x %.0f)" % [label, ms, arrived, stuck, MapInfo.size_x, MapInfo.size_z])


func _done() -> bool:
	if not results.is_empty():
		var lay: Dictionary = results[results.size() - 1]
		var budget := BUDGET_MS_PER_100 * UNITS / 100.0
		if float(lay["ms"]) > budget:
			print("  note: %.2f ms/frame is over perf_test.gd's %.1f ms main.tscn budget (the full skirmish costs more; the gate is the live reference)" % [lay["ms"], budget])
		if int(lay["stuck"]) > 0:
			fails.append("%d units stuck on the LayoutLevel" % lay["stuck"])
		if results.size() == 2:
			var live: Dictionary = results[0]
			if float(lay["ms"]) > float(live["ms"]) * 1.15 + 0.5:
				fails.append("LayoutLevel %.2f ms vs live %.2f ms (> +15 %%)" % [lay["ms"], live["ms"]])
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)
	return true
