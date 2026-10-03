extends SceneTree
# error_lab: quit-after=125000
## MT10 (docs/design/map-production.md 4.2, NM.A1), slow part: two normal bots play Thornwater (a generated 1v1
## LayoutLevel, sim mode, the 30:00 score limit) to the end, reading the layout:
## - every Hall (X1 natural, X2 rich), the Bazaar (M1) and the raid Spires (S3 / S4) a bot places stand at the layout's
##   slot of its seat (within SLOT_TOL m: the slot itself, a 4 m shift or a short ring search when a unit stands on it);
##   both bots expand to their natural (X1);
## - the scouts walk the layout's loop (a chosen scout goal is one of `scout_loop()`'s points);
## - the match reaches an end (a kill, a concede or the score at 30:00) with 0 script errors.
## The fast checks (rows on the slots, the loop, rally, Crown Hollow unchanged) are tests/test_mt10_bot_slots.gd.
## Slow (tools/ci/slow_tests.txt). `-- --map=<id>` runs another layout (default thornwater).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt10_layout_bots.gd --fixed-fps 60 --quit-after 120000
## Prints "PASS mt10_layout_bots" or "FAIL mt10_layout_bots: <reasons>".

const TASK_ID := "mt10_layout_bots"
const SCENE := "res://scenes/layout_level.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const SIM := preload("res://scripts/core/sim_mode.gd")
const LIMIT_SECONDS := 1800.0
const TIMEOUT_FRAMES := 115000
const SLOT_TOL := 8.5
const ROWS: Array[StringName] = [&"X1", &"X2", &"M1", &"S3", &"S4"]


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
var map_id := "thornwater"
var lay: MapLayout
var bots: Array = [null, null]
var errs := ErrCounter.new()
var fails: Array[String] = []
var notes: Array[String] = []
var placed := [{}, {}]        ## team -> {row id: Vector3 where the bot placed it}
var planned := [{}, {}]       ## team -> {row id: the layout slot}
var loops := [[], []]
var frame := 0
var _wait := 0


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
	SIM.enabled = true
	main = (load(SCENE) as PackedScene).instantiate()
	main.set(&"layout", lay)
	main.set(&"time_limit_s", LIMIT_SECONDS)
	for c: Node in main.get_children():
		if c.get_script() == COMMANDER:
			bots[int(c.get(&"team"))] = c
	for team: int in [0, 1]:
		if bots[team] == null:
			var b: Node = COMMANDER.new()
			b.name = "TestBot%d" % team
			b.set(&"team", team)
			main.add_child(b)
			bots[team] = b
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
	if frame % 60 == 0:
		_watch()
	if bool(main.get(&"game_over")):
		_watch()
		return _done(t)
	if frame % 18000 == 0:
		print("[%d:%02d] %d units, %d buildings, placed %s / %s, %d script errors" % [int(t) / 60, int(t) % 60,
			get_nodes_in_group(&"units").size(), get_nodes_in_group(&"buildings").size(), str(placed[0].keys()),
			str(placed[1].keys()), errs.lines.size()])
	if frame > TIMEOUT_FRAMES:
		fails.append("no end after %d frames (%.0f s of game)" % [frame, t])
		return _done(t)
	return false


## Records the slot buildings each bot placed and its planned slots / scout loop (after its first tick).
func _watch() -> void:
	for team: int in [0, 1]:
		var b: Node = bots[team]
		if b == null or not is_instance_valid(b) or b.get(&"_ready_done") != true:
			continue
		if loops[team].is_empty():
			loops[team] = b.call(&"scout_loop")
			for row in ROWS:
				planned[team][row] = b.call(&"planned_spot", row)
		var sb: Dictionary = b.get(&"_slot_building")
		for row in ROWS:
			if placed[team].has(row) or not sb.has(row):
				continue
			var site: Variant = sb[row]
			if site != null and is_instance_valid(site):
				placed[team][row] = (site as Node3D).global_position


func _done(t: float) -> bool:
	var winner := int(main.get(&"winner_team")) if main != null and is_instance_valid(main) else -1
	var on_score: bool = main != null and is_instance_valid(main) and main.get(&"ended_on_score") == true
	if main != null and is_instance_valid(main):
		notes.append("%s: end at %d:%02d, winner team %d%s" % [map_id, int(t) / 60, int(t) % 60, winner, " (on score)" if on_score else ""])
		if not bool(main.get(&"game_over")) and fails.is_empty():
			fails.append("the match did not end")
		for team: int in [0, 1]:
			if not placed[team].has(&"X1"):
				fails.append("team %d never expanded to its natural (X1)" % team)
			for row: StringName in placed[team]:
				var want: Vector3 = planned[team].get(row, Vector3.INF)
				var got: Vector3 = placed[team][row]
				var d := Vector2(got.x - want.x, got.z - want.z).length() if want != Vector3.INF else INF
				notes.append("team %d %s placed at (%.1f, %.1f), layout slot (%.1f, %.1f): %.1f m" % [team, row, got.x, got.z,
					want.x, want.z, d])
				if d > SLOT_TOL:
					fails.append("team %d %s placed %.1f m from its layout slot" % [team, row, d])
			var b: Node = bots[team]
			if b != null and is_instance_valid(b):
				var goals: Array = b.get(&"scout_goals")
				var on_loop := false
				for g: Vector3 in goals:
					for p: Vector3 in loops[team]:
						if Vector2(g.x - p.x, g.z - p.z).length() < 0.5:
							on_loop = true
				notes.append("team %d scout goals %d, on the layout loop: %s" % [team, goals.size(), str(on_loop)])
				if not goals.is_empty() and not on_loop:
					fails.append("team %d scouted none of its layout loop points" % team)
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
