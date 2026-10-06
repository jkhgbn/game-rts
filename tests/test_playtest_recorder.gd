extends SceneTree
## Playtest Recorder test (docs/design/health-and-playtests.md, part B):
##  1. the setting is OFF by default: a skirmish starts with no recorder and no command listener (no overhead);
##  2. a short scripted game is recorded (commands through ReplayHooks.note, a death, key presses, samples every 0.5 s);
##  3. the file's schema is valid (header / samples / events / end);
##  4. overhead when on: the per-frame work + the 5-s sample amortised must stay < 0.1 ms per frame;
##  5. the analyzer turns the recording into a report with every section and the two heatmap PNGs.
## Run:  godot --headless --path . -s tests/test_playtest_recorder.gd --fixed-fps 60 --quit-after 9000
## Prints "PASS playtest_recorder" (+ "PLAYTEST OVERHEAD ..." line) or "FAIL playtest_recorder: <reasons>".

const TASK_ID := "playtest_recorder"
const SCENE := "res://scenes/skirmish.tscn"
const OUT := "user://playtest_test/rec.jsonl"
const REPORT_DIR := "user://playtest_test/report"
const Hooks := preload("res://scripts/core/replay/replay_hooks.gd")
const Analyzer := preload("res://tools/playtest/playtest_analyzer.gd")
const LIMIT_MS := 0.1

var main: Node
var _errors: Array[String] = []


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await process_frame
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _run() -> void:
	await _frames(1)
	GameSettings.use_test_file()
	GameSettings.load_settings()
	_check(not GameSettings.playtest_data and not Hooks.playtest_enabled, "Playtest data must be OFF by default")
	for f in ["rec.jsonl"]:
		if FileAccess.file_exists("user://playtest_test/" + f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://playtest_test/" + f))
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	if not await _until(func() -> bool: return main.hero != null and bool(main.get(&"match_started")), 6000):
		_finish("the skirmish never started")
		return
	await _frames(30)
	# 1. Off: nothing attached, nobody listens to the commands.
	_check(main.get_node_or_null("PlaytestRecorder") == null, "a recorder exists while the setting is off")
	_check(Hooks.listener == null, "ReplayHooks.listener set while off")
	# 2. On: the same hook the setting uses (ReplayHooks.start_playtest), short sample interval for the test.
	var rec: Node = Hooks.start_playtest(main, "", {"out": OUT, "sample_every": 0.5})
	_check(rec != null, "start_playtest returned null")
	if rec == null:
		_finish("")
		return
	await _frames(5)
	_check(Hooks.listener == rec, "the recorder does not listen to commands")
	var keep: Node = null
	for b in get_nodes_in_group("buildings"):
		if int(b.get("team")) == 0 and b.has_method("trainable_types"):
			keep = b
			break
	if keep:
		var types: Array = keep.call("trainable_types")
		if not types.is_empty():
			Hooks.note(&"train", [types[0]])
	Hooks.note(&"formation_move", [Vector3(10, 0, -12)])
	Hooks.note(&"move_input", [Vector3.RIGHT])   # ignored (too frequent)
	for k in [KEY_Q, KEY_W]:
		var e := InputEventKey.new()
		e.physical_keycode = k
		e.keycode = k
		e.pressed = true
		Input.parse_input_event(e)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(5, 5)
	Input.parse_input_event(click)
	await _frames(120)
	# A death: one of the player's workers.
	for u in get_nodes_in_group("units"):
		if int(u.get("team")) == 0 and u.has_method("command_gather") and u.is_alive():
			u.take_damage(100000.0, null)
			break
	await _frames(240)
	# 4. Overhead (measured in place, on this live match): per-frame work, then the sample.
	var n := 3000
	var t0 := Time.get_ticks_usec()
	for i in n:
		rec.call("_process", 1.0 / 60.0)
	var per_frame_us := float(Time.get_ticks_usec() - t0) / n
	var ns := 40
	t0 = Time.get_ticks_usec()
	for i in ns:
		rec.call("sample")
	var sample_us := float(Time.get_ticks_usec() - t0) / ns
	var amortised_ms := (per_frame_us + sample_us / (5.0 * 60.0)) / 1000.0
	print("PLAYTEST OVERHEAD: %.4f ms per frame (frame work %.2f us, one sample %.1f us every 5 s = 300 frames)" % [
			amortised_ms, per_frame_us, sample_us])
	_check(amortised_ms < LIMIT_MS, "overhead %.4f ms per frame >= %.2f" % [amortised_ms, LIMIT_MS])
	# End: leaving the match (the recorder leaves the tree with the level).
	rec.queue_free()
	await _frames(3)
	_check(Hooks.listener == null, "listener still set after the recorder left")
	# 3. Schema.
	var r := Analyzer.load_recording(ProjectSettings.globalize_path(OUT))
	var errs := Analyzer.validate(r)
	_check(errs.is_empty(), "schema: %s" % "; ".join(errs))
	_check((r["samples"] as Array).size() >= 6, "only %d samples" % (r["samples"] as Array).size())
	var kinds := {}
	for e in r["events"]:
		kinds[String(e["e"]) + ("/" + String(e["c"]) if e.has("c") else "")] = true
	_check(kinds.has("cmd/formation_move"), "no formation_move command event")
	_check(not kinds.has("cmd/move_input"), "move_input must not be logged")
	if keep:
		_check(kinds.has("cmd/train"), "no train command event")
	_check(kinds.has("death"), "no death event")
	_check(String(r["header"].get("mode", "")) == "skirmish", "mode '%s' != skirmish" % r["header"].get("mode", ""))
	_check(int(r["end"].get("keys", 0)) >= 2 and int(r["end"].get("clicks", 0)) >= 1, "keys %s clicks %s" % [r["end"].get("keys"), r["end"].get("clicks")])
	_check(String(r["end"].get("outcome", "")) == "left", "outcome '%s' != left" % r["end"].get("outcome", ""))
	var s0: Dictionary = r["samples"][-1]
	_check(int(s0.get("wk", 0)) > 0 and s0.has("e_wk") and s0.has("cr") and (s0.get("cam", []) as Array).size() == 2,
			"sample content %s" % JSON.stringify(s0).left(200))
	var txt := FileAccess.get_file_as_string(OUT)
	var home := OS.get_environment("USERNAME")
	_check(home == "" or not txt.contains(home), "the recording contains the OS user name")
	# 5. Analyzer.
	var out := ProjectSettings.globalize_path(REPORT_DIR)
	var rep := Analyzer.report([ProjectSettings.globalize_path(OUT)], out, "pt_test")
	for sec in Analyzer.SECTIONS:
		_check(String(rep["md"]).contains(sec), "report misses '%s'" % sec)
	for f in ["pt_test_fights.png", "pt_test_deaths.png"]:
		_check(FileAccess.file_exists(out.path_join(f)), "no %s" % f)
	_finish("")


func _finish(extra: String) -> void:
	if extra != "":
		_errors.append(extra)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit(0 if _errors.is_empty() else 1)
