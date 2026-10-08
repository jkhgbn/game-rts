extends SceneTree
## Mid-mission save / load sweep (docs/design/save-load.md): every campaign mission scene is played ~10-60 s (hero kept
## alive), saved at the first moment MissionBase allows it, rebuilt from the save and played 5 s more. Checks: the
## restorer finishes, objectives keep their states, each team keeps about its living units, the match is not over.
## A mission that never allows a save in the window is reported "blocked" (not a failure); a mission marked
## save_supported = false is reported "unsupported". Slow (every mission bakes twice): tools/ci/slow_tests.txt.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_save_load_missions.gd --fixed-fps 60 --quit-after 200000
## Options after '--': only=<substring> (one mission). Prints "PASS save_load_missions" or "FAIL ...".

const TASK_ID := "save_load_missions"
const SAVE_FROM := 600     ## frames after the match starts before the first save try
const SAVE_UNTIL := 3600
const AFTER_LOAD := 300

var missions: Array[String] = []
var index := -1
var level: Node
var step := ""
var frames := 0
var data: Dictionary = {}
var expect: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var fails: Array[String] = []
var report: Array[String] = []


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for f in DirAccess.get_files_at("res://missions"):
		if f.begins_with("mission_") and f.ends_with(".tscn") and not f.begins_with("mission_e4_") \
				and (only == "" or f.contains(only)):
			missions.append("res://missions/" + f)
	missions.sort()
	_next()


func _next() -> void:
	index += 1
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if index >= missions.size():
		return
	level = (load(missions[index]) as PackedScene).instantiate()
	level.set(&"show_briefing", false)
	level.set(&"save_campaign_on_victory", false)
	level.set(&"cinematics_enabled", false)
	level.set(&"mission_difficulty", 1)
	root.add_child(level)
	current_scene = level
	step = "start"
	frames = 0


func _process(_delta: float) -> bool:
	if index >= missions.size():
		print("\n".join(report))
		if fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	frames += 1
	var name := missions[index].get_file().get_basename()
	var hero: Variant = level.get(&"hero") if level else null
	if hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(hero as Unit).heal(1.0e6)
	match step:
		"start":
			if hero != null and bool(level.get(&"match_started")):
				_goto("play")
			elif frames > 6000:
				_result(name, "FAIL never started")
		"play":
			if frames >= SAVE_FROM and frames % 30 == 0:
				var why := SaveGame.block_reason(level)
				if why == "":
					data = SaveGame.capture(level)
					expect = _state()
					_reload()
					_goto("wait")
				elif why == MissionBase.SAVE_REASON_UNSUPPORTED:
					_result(name, "unsupported")
				elif frames >= SAVE_UNTIL:
					_result(name, "blocked (%s)" % why)
		"wait":
			if restorer_done:
				if not restorer_ok:
					_result(name, "FAIL the restorer failed")
				else:
					_goto("after")
			elif frames > 6000:
				_result(name, "FAIL the load never finished")
		"after":
			if frames >= AFTER_LOAD:
				_result(name, _compare())
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _result(name: String, what: String) -> void:
	report.append("  %s: %s" % [name, what])
	print("  %s: %s" % [name, what])
	if what.begins_with("FAIL"):
		fails.append("%s %s" % [name, what])
	_next()


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data)
	level.set(&"save_campaign_on_victory", false)
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


func _state() -> Dictionary:
	var objs := {}
	for o: Dictionary in (level as MissionBase).objectives():
		objs[String(o["id"])] = String(o["state"])
	var teams := {}
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive():
			teams[int(u.team)] = int(teams.get(int(u.team), 0)) + 1
	return {"objs": objs, "teams": teams, "time": (level as MissionBase).mission_time()}


func _compare() -> String:
	var got := _state()
	var bad: Array[String] = []
	if bool(level.get(&"game_over")):
		bad.append("game over after the load")
	for id: String in expect["objs"]:
		var was := String(expect["objs"][id])
		var now := String((got["objs"] as Dictionary).get(id, "?"))
		if was != now and not (was == "active" and now in ["done", "failed"]):
			bad.append("objective %s %s -> %s" % [id, was, now])
	for t: int in expect["teams"]:
		var was := int(expect["teams"][t])
		var now := int((got["teams"] as Dictionary).get(t, 0))
		if absi(now - was) > maxi(3, was / 5):
			bad.append("team %d units %d -> %d" % [t, was, now])
	if bad.is_empty():
		return "ok (saved at %.0f s)" % float(expect["time"])
	return "FAIL " + ", ".join(bad)
