extends SceneTree
## Mid-mission save / load sweep (docs/design/save-load.md): every campaign mission scene is played ~10-60 s (hero kept
## alive), saved at the first moment MissionBase allows it, rebuilt from the save and played 5 s more. Checks: the
## restorer finishes, objectives keep their states, each team keeps about its living units, the match is not over.
## A mission that never allows a save in the window is reported "blocked" (not a failure); a mission marked
## save_supported = false is reported "unsupported". Slow (every mission bakes twice): tools/ci/slow_tests.txt.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_save_load_missions.gd --fixed-fps 60 --quit-after 200000
## Options after '--': only=<substring> (one mission). Prints "PASS save_load_missions" or "FAIL ...".
## Review 2026-10-10 regressions (set up right before the save, checked after the load): Warden Gates / pylons keep
## their broken state (#2, one gate broken; E8m1 Nature: a raised bridge gate, broken, comes back once and broken);
## mid-mission hooks and guards are made again (#3: E7m1 Seraphine's died hook after the knives, E7m3 Brannet's guard,
## E8m1 Ice refugees' died hook, E8m3 the King's guard and damage gate).

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
	_prepared = false
	_gates_expect.clear()


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
				if why == "" and not _prepared:
					_prepared = true
					_prepare(name)
					why = SaveGame.block_reason(level)
				if why == "":
					_record()
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


# ---------------------------------------------------------------- review 2026-10-10 regressions

var _gates_expect := {}   ## gate id -> alive at the save
var _prepared := false


## Sets up the state the load must keep. Timers the setup adds that cannot be saved (lambdas) are dropped.
func _prepare(name: String) -> void:
	var m := level as MissionBase
	var timers: Array = m.get(&"_timers")
	var before := timers.size()
	if name == "mission_e7_01":
		m.fire_once(&"E11")
		m.call(&"_laurel_end")
		MissionHarness.kill(m.get(&"knives") as Array)   # Seraphine must live through the reload
	if name == "mission_e8_01_ice" and m.has_method(&"_spawn_column") and (m.get(&"refugees") as Array).is_empty():
		m.call(&"_spawn_column")
	if name == "mission_e8_01_nature":
		var g: Variant = m.call(&"_restore_missing_gate", &"north")
		if g == null:
			fails.append("%s: could not raise the north bridge gate" % name)
	if m.has_method(&"warden_gates"):
		var gates: Dictionary = m.call(&"warden_gates")
		var ids := gates.keys()
		ids.sort()
		for i in ids.size():
			var g := gates[ids[i]] as WardenGate
			if i == 0 or ids[i] == &"north":
				g.open()
				g.take_damage(1.0e7, null)
	for i in range(timers.size() - 1, before - 1, -1):
		var c := timers[i][1] as Callable
		if not (c.is_standard() and c.get_object() == m):
			timers.remove_at(i)


## The gates' alive states at the save.
func _record() -> void:
	_gates_expect.clear()
	if level.has_method(&"warden_gates"):
		var gates: Dictionary = level.call(&"warden_gates")
		for id: StringName in gates:
			_gates_expect[String(id)] = (gates[id] as WardenGate).is_alive()


func _verify(name: String) -> Array[String]:
	var bad: Array[String] = []
	var m := level as MissionBase
	if not _gates_expect.is_empty():
		var gates: Dictionary = m.call(&"warden_gates")
		for id: String in _gates_expect:
			var g: WardenGate = gates.get(StringName(id))
			if g == null:
				bad.append("gate %s missing" % id)
			elif g.is_alive() and not bool(_gates_expect[id]):
				bad.append("gate %s broken at the save stands again" % id)
		var n := 0
		for x in get_nodes_in_group(&"warden_gates"):
			if (x as WardenGate).gate_id == &"north" and m.is_ancestor_of(x):
				n += 1
		if name == "mission_e8_01_nature" and (n != 1 or not (m.get(&"bridge_gates") as Dictionary).has(&"north")):
			bad.append("north bridge gate: %d after the load, listed %s" % [n, (m.get(&"bridge_gates") as Dictionary).has(&"north")])
	match name:
		"mission_e7_01":
			var sr: Unit = m.get(&"seraphine")
			if sr == null or not sr.died.is_connected(Callable(m, &"_on_seraphine_died")):
				bad.append("Seraphine's died hook lost")
		"mission_e7_03":
			var b: Unit = m.get(&"brannet")
			if b == null or not b.death_guard.is_valid():
				bad.append("Brannet's guard lost")
		"mission_e8_01_ice":
			var refs: Array = m.call(&"alive_refugees")
			if refs.is_empty():
				bad.append("no refugees after the load")
			for r: Variant in refs:
				if not (r as Unit).died.is_connected(Callable(m, &"_on_refugee_died")):
					bad.append("a refugee's died hook lost")
					break
		"mission_e8_03":
			var k: Unit = m.get(&"king")
			if k == null or not k.death_guard.is_valid() or not k.damage_taken.is_connected(Callable(m, &"_on_king_hit")):
				bad.append("the King's guard / damage gate lost")
	return bad


func _compare() -> String:
	var got := _state()
	var bad: Array[String] = []
	bad.append_array(_verify(missions[index].get_file().get_basename()))
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
