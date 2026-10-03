extends SceneTree
## A map of 150 m or more end to end (code review of the map tools, docs/reviews/review-map-tools.md "Test quality"):
## Quartermeet (176 x 176, fourfold, played 1v1 by LayoutLevel) with a normal bot on each side, sim mode, the 30:00
## limit. Before the match: spacing (tools/world_forge/forge_spacing.gd) and the R1 `rules` bands (gen grid
## pre-filter) pass; after the bake: MapInfo / fog / BuildGrid sized for 176 m and both keeps on the map. PASS when the
## match reaches an end (a kill, a concede or the score at 30:00) with 0 script errors (Godot Logger).
## Slow (tools/ci/slow_tests.txt): several minutes. `-- --map=thornwater` runs another adopted map.
## Prints "PASS map_big_e2e" or "FAIL map_big_e2e: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_map_big_e2e.gd --fixed-fps 60 --quit-after 120000

const TASK_ID := "map_big_e2e"
const SCENE := "res://scenes/layout_level.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const Gen := preload("res://tools/world_forge/forge_gen.gd")
const Spacing := preload("res://tools/world_forge/forge_spacing.gd")
const SIM := preload("res://scripts/core/sim_mode.gd")
const LIMIT_SECONDS := 1800.0
const TIMEOUT_FRAMES := 115000
const BAND_FAIL := 0.10


class ErrCounter:
	extends Logger
	var mutex := Mutex.new()
	var lines: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type != 2:   # ERROR_TYPE_SCRIPT ("SCRIPT ERROR")
			return
		mutex.lock()
		lines.append("%s:%d %s %s" % [file, line, function, rationale if rationale != "" else code])
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


var main: Node
var map_id := "quartermeet"
var lay: MapLayout
var errs := ErrCounter.new()
var fails: Array[String] = []
var notes: Array[String] = []
var frame := 0
var _wait := 0
var _checked := false


func _initialize() -> void:
	OS.add_logger(errs)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			map_id = a.trim_prefix("--map=")
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	lay = LayoutLevel.load_layout("res://data/maps/%s_layout.tres" % map_id)
	if lay == null:
		fails.append("no layout %s" % map_id)
		_done(0.0)
		return
	if maxf(lay.size_x, lay.size_z) < 150.0 and map_id == "quartermeet":
		fails.append("%s is %.0f m (< 150)" % [map_id, maxf(lay.size_x, lay.size_z)])
	# spacing + R1 bands (grid pre-filter) before the match
	var close := Spacing.findings(lay)
	if not close.is_empty():
		fails.append("spacing: %s" % ", ".join(Spacing.lines(close)))
	var g := Gen.new(map_id, String(lay.rules.get("archetype", "river_split")), int(lay.rules.get("players", 2)),
		String(lay.rules.get("tempo", "standard")), lay.biome)
	var sc := g.score_layout(lay)
	var miss: Dictionary = sc.get("miss", {})
	for k: String in miss:
		if is_inf(float(miss[k])) or float(miss[k]) > BAND_FAIL:
			fails.append("R1 %s %.0f %% outside its band" % [k, 100.0 * float(miss[k])])
	notes.append("%s %.0f x %.0f m: spacing ok %s, R1 grid %s" % [map_id, lay.size_x, lay.size_z, str(close.is_empty()),
		JSON.stringify(sc.get("measures", {}))])
	SIM.enabled = true
	main = (load(SCENE) as PackedScene).instantiate()
	main.set(&"layout", lay)
	main.set(&"time_limit_s", LIMIT_SECONDS)
	var have := [false, false]
	for c: Node in main.get_children():
		if c.get_script() == COMMANDER:
			have[int(c.get(&"team"))] = true
	for team: int in [0, 1]:
		if not have[team]:
			var b: Node = COMMANDER.new()
			b.name = "TestBot%d" % team
			b.set(&"team", team)
			main.add_child(b)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main == null or not is_instance_valid(main):
		return true
	if not bool(main.get(&"match_started")):
		_wait += 1
		if _wait > 9000:
			fails.append("the level never started (navmesh bake)")
			return _done(0.0)
		return false
	frame += 1
	var t: float = float(main.call(&"match_time"))
	if not _checked:
		_checked = true
		_size_checks()
	if bool(main.get(&"game_over")):
		return _done(t)
	if frame % 18000 == 0:
		print("[%d:%02d] %d units, %d buildings, %d script errors" % [int(t) / 60, int(t) % 60,
			get_nodes_in_group(&"units").size(), get_nodes_in_group(&"buildings").size(), errs.lines.size()])
	if frame > TIMEOUT_FRAMES:
		fails.append("no end after %d frames (%.0f s of game)" % [frame, t])
		return _done(t)
	return false


## MapInfo, the fog grid, the BuildGrid and the keeps follow the layout's size.
func _size_checks() -> void:
	if not is_equal_approx(MapInfo.size_x, lay.size_x) or not is_equal_approx(MapInfo.size_z, lay.size_z):
		fails.append("MapInfo %s x %s" % [MapInfo.size_x, MapInfo.size_z])
	var fog: Variant = main.get(&"fog")
	if fog is Node and int((fog as Node).get(&"grid_w")) < int(lay.size_x / 2.0):
		fails.append("fog grid %s cells wide for %.0f m" % [(fog as Node).get(&"grid_w"), lay.size_x])
	for team: int in [0, 1]:
		var k: Variant = main.call(&"keep_of", team)
		if k == null or not MapInfo.contains((k as Node3D).global_position, 2.0):
			fails.append("team %d keep missing or off the map" % team)
	var bg: Variant = main.get(&"build_grid")
	if bg is Node and bg.has_method(&"check"):
		var kt: Variant = (main.call(&"keep_of", 0) as Node).get(&"building_type") if main.call(&"keep_of", 0) != null else null
		if kt != null and String(bg.call(&"check", kt, Vector3(lay.size_x * 0.5 + 6.0, 0, 0), 0)) == "":
			fails.append("BuildGrid accepts a keep off the map edge")


func _done(t: float) -> bool:
	var winner := int(main.get(&"winner_team")) if main != null and is_instance_valid(main) else -1
	var on_score: bool = main != null and is_instance_valid(main) and main.get(&"ended_on_score") == true
	if main != null and is_instance_valid(main):
		notes.append("end at %d:%02d, winner team %d%s" % [int(t) / 60, int(t) % 60, winner, " (on score)" if on_score else ""])
		if not bool(main.get(&"game_over")) and fails.is_empty():
			fails.append("the match did not end")
	errs.mutex.lock()
	var el := errs.lines.duplicate()
	errs.mutex.unlock()
	if not el.is_empty():
		fails.append("%d script errors, first: %s" % [el.size(), el[0]])
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)
	return true
