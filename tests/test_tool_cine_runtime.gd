extends SceneTree
## Tools wave, tool 1 (Cinematic Runtime) acceptance demo (docs/plan/tools-wave.md section 2).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_tool_cine_runtime.gd --fixed-fps 60 --quit-after 4000
## A synthetic 4-shot script built in code (STATIC, DOLLY, ORBIT from markers, RAIL) with 3 lines, a fade, a clip and
## a vfx plays headless: finishes at frame N +- 1; two runs give identical camera transforms at 10 sample times;
## seek(t) + 1 frame == playing; skip lock / two presses / one press when seen; pause adds 0; Enter ends a line;
## PAUSE mode restores process modes; recording path; bars 115 / 43 / 32; 0 lights; HOLD refused.
## Never names the Events autoload (tests compile before autoloads exist).

const TASK_ID := "tool_cine_runtime"
const FPS := 60.0

var _fails: Array[String] = []
var _notes: Array[String] = []
var _stage: CinematicStage
var _player: CinematicPlayer
var _finished_log: Array = []
var _shots_log: Array = []
var _lines_log: Array = []
var _events_finished := 0
var _model_script: GDScript
var _mover_script: GDScript
var _set_script: GDScript


func _initialize() -> void:
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# ------------------------------------------------------------------ fixtures

func _make_scripts() -> void:
	_model_script = GDScript.new()
	_model_script.source_code = """extends Node3D
var clips: Array = []
var gestures: Array = []
var moving := 0.0
func play_clip(id: StringName) -> bool:
	clips.append(id)
	return true
func play_gesture(id) -> void:
	gestures.append(id)
func set_moving(s: float) -> void:
	moving = s
func play_cast(_id: StringName) -> void:
	pass
"""
	_model_script.reload()
	_mover_script = GDScript.new()
	_mover_script.source_code = """extends Node3D
func _process(delta: float) -> void:
	position.x += delta
"""
	_mover_script.reload()
	_set_script = GDScript.new()
	_set_script.source_code = """extends Node3D
@export var set_id: StringName = &""
var begun: Array = []
func begin_shot(id: StringName) -> void:
	begun.append(id)
func end_shot(_id: StringName) -> void:
	pass
func puppet(_tag: StringName) -> Node3D:
	return null
"""
	_set_script.reload()


func _make_stage() -> CinematicStage:
	if _stage != null and is_instance_valid(_stage):
		_stage.free()
	var st := CinematicStage.new()
	st.name = "DemoStage"
	st.autoplay = false
	st.render_scale = false
	var set_root := Node3D.new()
	set_root.name = "DemoSet"
	set_root.set_script(_set_script)
	set_root.set(&"set_id", &"demo")
	set_root.add_to_group(&"cinematic_sets")
	st.add_child(set_root)
	var shots := Node3D.new()
	shots.name = "Shots"
	set_root.add_child(shots)
	_marker(shots, "s3_from", Vector3(5, 3, 0))
	_marker(shots, "s3_to", Vector3(0, 3, 5)).set_meta(&"fov", 35.0)
	_marker(shots, "s3_pivot", Vector3(0, 0, 0))
	var rail := Path3D.new()
	rail.name = "s4_rail"
	var c := Curve3D.new()
	c.add_point(Vector3(-6, 2, 6))
	c.add_point(Vector3(0, 3, 8))
	c.add_point(Vector3(6, 2, 6))
	rail.curve = c
	shots.add_child(rail)
	var proxy := CastProxy.new()
	proxy.name = "Vessa"
	st.add_child(proxy)
	var model := Node3D.new()
	model.set_script(_model_script)
	model.name = "Model"
	proxy.setup(model, &"fire")
	var malrik := Node3D.new()
	malrik.name = "Malrik"
	malrik.position = Vector3(3, 0, -3)
	st.add_child(malrik)
	root.add_child(st)
	_stage = st
	return st


func _marker(parent: Node, n: String, at: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = n
	m.position = at
	parent.add_child(m)
	return m


func _demo_script() -> CinematicScript:
	var s := CinematicScript.new()
	s.id = &"tool_runtime_demo"
	s.title = "Runtime demo"
	var s1 := CinematicShot.make(&"s1", 1.5, CinematicShot.CameraMode.STATIC)
	s1.from_pos = Vector3(0, 2, 8)
	s1.look_from = Vector3(0, 1, 0)
	s1.transition_in = CinematicShot.Transition.FADE_BLACK
	s1.transition_time = 0.6
	s1.add_line(0.2, &"narrator", "The ember wakes.")
	var s2 := CinematicShot.make(&"s2", 1.5, CinematicShot.CameraMode.DOLLY)
	s2.from_pos = Vector3(-4, 2, 6)
	s2.to_pos = Vector3(4, 2, 6)
	s2.look_actor = &"vessa"
	s2.add_line(0.1, &"vessa", "Not tonight.")
	s2.add_action(0.0, &"move", &"vessa", Vector3(2, 0, 0), {"speed": 2.0})
	s2.add_action(0.3, &"clip", &"vessa", Vector3.ZERO, {"id": &"bow"})
	var s3 := CinematicShot.make(&"s3", 2.0, CinematicShot.CameraMode.ORBIT)
	s3.stage_set = &"demo"
	s3.marker_prefix = &"s3"
	s3.add_line(0.5, &"malrik", "Then when?")
	s3.add_action(0.5, &"vfx", &"vessa", Vector3(0, 0, -5), {"vfx_id": &"fireball"})
	s3.add_action(0.2, &"face", &"malrik", Vector3.ZERO, {"look_actor": &"vessa"})
	var s4 := CinematicShot.make(&"s4", 1.5, CinematicShot.CameraMode.RAIL)
	s4.marker_prefix = &"s4"
	s4.look_from = Vector3(0, 1, 0)
	s4.look_to = Vector3(2, 1, 0)
	s4.fov_from = 40.0
	s4.fov_to = 50.0
	s4.shake = 0.4
	s4.add_action(1.0, &"fade", &"", Vector3.ZERO, {"color": Color.BLACK, "alpha": 1.0, "time": 0.5})
	s.shots = [s1, s2, s3, s4]
	return s


func _connect_player() -> void:
	_player = CinematicPlayer.instance(self)
	if not _player.finished.is_connected(_on_finished):
		_player.finished.connect(_on_finished)
		_player.shot_started.connect(func(i: int, id: StringName) -> void: _shots_log.append([i, id]))
		_player.line_shown.connect(func(l: CinematicLine) -> void: _lines_log.append(l.text))
	_player.recording = false
	_player.one_press_skip = false
	_player.log_enabled = false


func _on_finished(id: StringName, skipped: bool) -> void:
	_finished_log.append([id, skipped])


func _count_lights(n: Node) -> int:
	var c := 1 if n is Light3D else 0
	for ch in n.get_children():
		c += _count_lights(ch)
	return c


func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	root.push_input(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	root.push_input(up)


# ------------------------------------------------------------------ the run

func _run() -> void:
	await _frames(2)
	_make_scripts()
	var ev_node := root.get_node_or_null(^"Events")
	if ev_node != null and ev_node.has_signal(&"cinematic_finished"):
		ev_node.connect(&"cinematic_finished", func(_id: StringName, _s: bool) -> void: _events_finished += 1)
	else:
		_notes.append("Events autoload not present: Events signals not checked")
	var lights0 := _count_lights(root)
	_connect_player()

	# 1. bars
	_expect(CinematicOverlay.bar_height(Vector2(1600, 900), 2.39) == 115.0, "bar 1600x900 = %s" % CinematicOverlay.bar_height(Vector2(1600, 900), 2.39))
	_expect(CinematicOverlay.bar_height(Vector2(3440, 1440), 2.39) == 43.0, "bar 3440x1440 = %s" % CinematicOverlay.bar_height(Vector2(3440, 1440), 2.39))
	_expect(CinematicOverlay.bar_height(Vector2(2560, 1080), 2.39) == 32.0, "bar 2560x1080 = %s" % CinematicOverlay.bar_height(Vector2(2560, 1080), 2.39))

	# 2. HOLD / VIDEO refused
	var hold := _demo_script()
	hold.world_mode = CinematicScript.WorldMode.HOLD
	_expect(_player.play(hold).begins_with("HOLD"), "HOLD mode refused")
	_expect(not _player.is_playing(), "not playing after a refusal")

	# 3. full play twice (determinism + frame count)
	var run_a := await _full_run()
	var run_b := await _full_run()
	var expect_frames := int(round(_demo_script().total_duration() * FPS))
	_expect(absi(int(run_a["frames"]) - expect_frames) <= 1, "run A finished at frame %d, expected %d +- 1" % [run_a["frames"], expect_frames])
	_expect(absi(int(run_b["frames"]) - expect_frames) <= 1, "run B finished at frame %d" % run_b["frames"])
	var samples_a: Array = run_a["samples"]
	var samples_b: Array = run_b["samples"]
	var sample_frames: Array[int] = []
	for k in 10:
		sample_frames.append(int(3 + k * (expect_frames - 8) / 9.0))
	var same := 0
	for f: int in sample_frames:
		if f < samples_a.size() and f < samples_b.size():
			var xa: Transform3D = samples_a[f][1]
			var xb: Transform3D = samples_b[f][1]
			if xa.is_equal_approx(xb) and absf(float(samples_a[f][0]) - float(samples_b[f][0])) < 0.000001:
				same += 1
	_expect(same == 10, "identical camera transforms at 10 sample times: %d / 10" % same)
	_expect(_shots_log.size() == 8 and _shots_log[3] == [3, &"s4"], "4 shot_started per run in order: %s" % [_shots_log])
	_expect(_lines_log.size() == 6 and _lines_log[2] == "Then when?", "3 lines per run in order: %s" % [_lines_log])
	var fired: Dictionary = run_a["fired"]
	_expect(int(fired.get(&"clip", 0)) == 1 and int(fired.get(&"vfx", 0)) == 1 and int(fired.get(&"fade", 0)) == 1,
			"clip / vfx / fade fired once: %s" % [fired])
	_expect(run_a["clips"] == [&"bow"], "clip reached the model: %s" % [run_a["clips"]])
	_expect(float(run_a["fade_end"]) > 0.99, "fade action ends black: %.3f" % run_a["fade_end"])
	_expect(float(run_a["fade_start"]) > 0.9, "FADE_BLACK shot 1 starts black: %.3f" % run_a["fade_start"])
	_expect(float(run_a["orbit_r"]) > 4.99 and float(run_a["orbit_r"]) < 5.01, "ORBIT radius from markers: %.3f" % run_a["orbit_r"])
	_expect(run_a["set"] == &"demo", "active set during s3: %s" % run_a["set"])
	_expect(bool(run_a["vessa_at_target"]), "move end state: vessa at (2, 0, 0)")
	_expect((run_a["vessa_fwd"] as Vector3).dot(Vector3.RIGHT) > 0.99, "move faces the walk direction on +Z (game convention): fwd %s" % run_a["vessa_fwd"])
	_expect(float(run_a["malrik_dot"]) > 0.99, "face look_actor turns +Z toward the target: dot %.3f" % run_a["malrik_dot"])
	_expect(_finished_log.size() == 2 and _finished_log[0] == [&"tool_runtime_demo", false], "finished(false) twice: %s" % [_finished_log])

	# 4. seek(t) + 1 frame == playing
	await _seek_check(samples_a, [30, 120, 200, 260, 330, 380])

	# 5. skip lock / two presses / one press when seen / not skippable
	await _skip_checks()

	# 6. pause adds 0, Enter ends a line
	await _pause_advance_checks()

	# 7. PAUSE world mode restores process modes
	await _pause_mode_check()

	# 8. recording path
	await _recording_check()

	# 8b. set cue API + puppets keep their cinematic pose over a set's begin_shot reset (play and seek)
	await _set_cue_checks()

	# 9. lights, events
	_expect(_count_lights(root) == lights0 and lights0 == 0, "0 lights created (%d before, %d after)" % [lights0, _count_lights(root)])
	if ev_node != null and ev_node.has_signal(&"cinematic_finished"):
		_expect(_events_finished == _finished_log.size(), "Events.cinematic_finished per finish: %d vs %d" % [_events_finished, _finished_log.size()])

	for n in _notes:
		print("  note: ", n)
	if _fails.is_empty():
		print("PASS %s (frames %d / %d, 10/10 samples, %d seeks, %d finishes)" % [TASK_ID, run_a["frames"], expect_frames, 6, _finished_log.size()])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _set_cue_checks() -> void:
	_make_stage()
	var cue_script := GDScript.new()
	cue_script.source_code = """extends Node3D
@export var set_id: StringName = &""
var start := {}
func _ready() -> void:
	for p in get_node(^"Puppets").get_children():
		start[p.name.to_lower()] = p.transform
func begin_shot(_id: StringName) -> void:
	for p in get_node(^"Puppets").get_children():
		p.transform = start[p.name.to_lower()]
func puppet(tag: StringName) -> Node3D:
	return get_node_or_null(NodePath("Puppets/" + String(tag).capitalize())) as Node3D
func cine_cues(shot_id: StringName) -> Array:
	if shot_id == &"cb":
		return [{"at": 0.2, "kind": "vfx", "vfx_id": &"fireball", "actor": &"vessa", "target": Vector3(0, 0, -2)},
			{"at": 0.1, "kind": "move", "actor": &"grunt", "target": Vector3(9, 0, 9)}]
	return []
"""
	cue_script.reload()
	var set_root := Node3D.new()
	set_root.name = "CueSet"
	set_root.set_script(cue_script)
	set_root.set(&"set_id", &"cueset")
	set_root.add_to_group(&"cinematic_sets")
	var puppets := Node3D.new()
	puppets.name = "Puppets"
	set_root.add_child(puppets)
	var grunt := Node3D.new()
	grunt.name = "Grunt"
	puppets.add_child(grunt)
	_stage.add_child(set_root)
	await _frames(1)
	var s := CinematicScript.new()
	s.id = &"set_cue_demo"
	var ca := CinematicShot.make(&"ca", 1.0, CinematicShot.CameraMode.STATIC)
	ca.stage_set = &"cueset"
	ca.add_action(0.0, &"move", &"grunt", Vector3(3, 0, 0), {"speed": 10.0})
	var cb := CinematicShot.make(&"cb", 1.0, CinematicShot.CameraMode.STATIC)
	s.shots = [ca, cb]
	var cues := CinematicPlayer.set_cues(set_root, cb)
	_expect(cues.size() == 1 and cues[0].kind == &"vfx" and bool(cues[0].params.get("from_set", false)),
			"set_cues: 1 cosmetic cue kept (move refused), from_set: %d" % cues.size())
	_expect(_player.play(s, _stage) == "", "set cue demo plays")
	var guard := 0
	while _player.is_playing() and guard < 400:
		await process_frame
		guard += 1
	var fired: Dictionary = _player.debug_state().get("fired", {})
	_expect(grunt.position.distance_to(Vector3(3, 0, 0)) < 0.01, "grunt kept its moved pose over begin_shot(cb): %s" % grunt.position)
	_expect(int(fired.get(&"vfx", 0)) == 1, "the set's vfx cue fired once: %s" % [fired])
	# seek into cb: the move of ca is replayed and survives cb's begin_shot reset
	_expect(_player.play(s, _stage) == "", "set cue demo plays again")
	_player.seek(1.5)
	_expect(grunt.position.distance_to(Vector3(3, 0, 0)) < 0.01, "seek(1.5): grunt at its moved pose: %s" % grunt.position)
	_player.stop()
	await _frames(1)
	_stage.remove_child(set_root)
	set_root.free()


func _full_run() -> Dictionary:
	_make_stage()
	await _frames(1)
	var vessa := _stage.get_node(^"Vessa") as Node3D
	var model := vessa.get_node(^"Model")
	var n_before := _finished_log.size()
	var err := _player.play(_demo_script(), _stage)
	_expect(err == "", "play() = '%s'" % err)
	var out := {"samples": [], "frames": 0, "fade_start": _player.debug_state()["fade_alpha"], "orbit_r": 0.0, "set": &""}
	var frames := 0
	while _finished_log.size() == n_before and frames < 1000:
		await process_frame
		frames += 1
		var ds := _player.debug_state()
		(out["samples"] as Array).append([_player.elapsed(), ds["camera"]["xform"]])
		if ds["shot_id"] == &"s3" and float(out["orbit_r"]) == 0.0:
			var p: Vector3 = ds["camera"]["pos"]
			out["orbit_r"] = Vector2(p.x, p.z).length()   # shake adds a few cm: first s3 frame has trauma 0.4 -> small
			out["set"] = ds["active_set"]
		out["fade_end"] = ds["fade_alpha"]
		out["fired"] = ds["fired"]
	out["frames"] = frames
	out["clips"] = model.get(&"clips")
	out["vessa_at_target"] = vessa.global_position.distance_to(Vector3(2, 0, 0)) < 0.01
	# facing (game convention, Unit._face: models face +Z): vessa walked +X -> her +Z axis points +X;
	# malrik faced vessa -> his +Z axis points at her
	out["vessa_fwd"] = vessa.global_basis.z.normalized()
	var malrik := _stage.get_node(^"Malrik") as Node3D
	var to_v := vessa.global_position - malrik.global_position
	to_v.y = 0.0
	out["malrik_dot"] = malrik.global_basis.z.normalized().dot(to_v.normalized())
	return out


func _seek_check(samples: Array, frames: Array) -> void:
	_make_stage()
	await _frames(1)
	var err := _player.play(_demo_script(), _stage)
	_expect(err == "", "seek play() = '%s'" % err)
	var ok := 0
	for f: int in frames:
		if f < 1 or f >= samples.size():
			continue
		var t_prev: float = samples[f - 1][0]
		_player.seek(t_prev)
		await process_frame
		var t_now := _player.elapsed()
		var want: Transform3D = samples[f][1]
		var got: Transform3D = _player.debug_state()["camera"]["xform"]
		var d := got.origin.distance_to(want.origin) + (got.basis.x - want.basis.x).length() + (got.basis.z - want.basis.z).length()
		if absf(t_now - float(samples[f][0])) < 0.0001 and d < 0.001:
			ok += 1
		else:
			_fails.append("seek frame %d: t %.5f vs %.5f, diff %.5f" % [f, t_now, samples[f][0], d])
	_expect(ok == frames.size(), "seek + 1 frame == play: %d / %d" % [ok, frames.size()])
	# seek applies end states: after seeking into s3, vessa is at the move target
	_player.seek(3.2)
	var vessa := _stage.get_node(^"Vessa") as Node3D
	_expect(vessa.global_position.distance_to(Vector3(2, 0, 0)) < 0.01, "seek applied the move end state")
	_player.seek(1.6)
	await process_frame
	var mid := vessa.global_position
	_expect(mid.distance_to(Vector3(2, 0, 0)) > 0.5, "seek back restored the start snapshot (in-flight move): %s" % mid)
	_player.stop()
	await process_frame


func _short_script(id: StringName, length: float) -> CinematicScript:
	var s := CinematicScript.new()
	s.id = id
	var sh := CinematicShot.make(&"a", length, CinematicShot.CameraMode.STATIC)
	sh.add_line(0.1, &"vessa", "A line long enough to stay a while on screen.", 2.0)
	sh.add_action(0.0, &"call", &"", Vector3.ZERO, {"method": "noop_missing"})
	s.shots = [sh]
	return s


func _skip_checks() -> void:
	_make_stage()
	await _frames(1)
	# lock: skip_locked_until 1.0
	var s := _short_script(&"skip_lock", 4.0)
	s.shots[0].actions.clear()
	s.skip_locked_until = 1.0
	var n0 := _finished_log.size()
	_player.play(s, _stage)
	await _frames(20)
	_press(&"cinematic_skip")
	_press(&"cinematic_skip")
	await _frames(2)
	_expect(_player.is_playing() and not _player.debug_state()["skip_prompt"], "skip ignored before skip_locked_until")
	await _frames(50)   # t > 1.0
	_press(&"cinematic_skip")
	await _frames(2)
	_expect(_player.is_playing() and _player.debug_state()["skip_prompt"], "first press after the lock shows the prompt")
	_press(&"cinematic_skip")
	await _frames(1)
	_expect(not _player.is_playing() and _finished_log.size() == n0 + 1 and _finished_log[-1][1] == true,
			"second press skips (finished(true))")
	# seen before: one press
	var s2 := _short_script(&"skip_seen", 4.0)
	s2.shots[0].actions.clear()
	_player.one_press_skip = true
	_player.play(s2, _stage)
	await _frames(10)
	_press(&"cinematic_skip")
	await _frames(1)
	_expect(not _player.is_playing() and _finished_log[-1] == [&"skip_seen", true], "one press when seen")
	_player.one_press_skip = false
	# not skippable
	var s3 := _short_script(&"skip_never", 0.5)
	s3.shots[0].actions.clear()
	s3.skippable = false
	var n1 := _finished_log.size()
	_player.play(s3, _stage)
	await _frames(5)
	_press(&"cinematic_skip")
	_press(&"cinematic_skip")
	await _frames(2)
	_expect(_player.is_playing(), "skippable=false ignores skip")
	await _frames(40)
	_expect(_finished_log.size() == n1 + 1 and _finished_log[-1] == [&"skip_never", false], "unskippable plays to the end")
	# skip applies end states (move at target; call with on_skip runs once)
	var s4 := _demo_script()
	s4.id = &"skip_end_states"
	_make_stage()
	await _frames(1)
	_player.one_press_skip = true
	_player.play(s4, _stage)
	await _frames(5)
	_press(&"cinematic_skip")
	await _frames(1)
	_player.one_press_skip = false
	var vessa := _stage.get_node(^"Vessa") as Node3D
	_expect(vessa.global_position.distance_to(Vector3(2, 0, 0)) < 0.1, "skip: move actor at its target")
	_expect(int(_player.debug_state()["fired"].get(&"vfx", 0)) == 0, "skip: vfx not played")


func _pause_advance_checks() -> void:
	_make_stage()
	await _frames(1)
	var s := _short_script(&"pause_test", 3.0)
	s.shots[0].actions.clear()
	_player.play(s, _stage)
	await _frames(20)
	_expect(not (_player.debug_state()["line"] as Dictionary).is_empty(), "line on screen at 0.33 s")
	_press(&"cinematic_advance")
	await _frames(1)
	_expect((_player.debug_state()["line"] as Dictionary).is_empty() and _player.is_playing() and _player.shot_index() == 0,
			"Enter ends the line, not the shot")
	_press(&"cinematic_pause")
	await _frames(1)
	var t0 := _player.elapsed()
	await _frames(60)
	_expect(_player.is_paused() and absf(_player.elapsed() - t0) < 0.000001, "60 paused frames add 0 (%.4f -> %.4f)" % [t0, _player.elapsed()])
	_press(&"cinematic_pause")
	await _frames(5)
	_expect(not _player.is_paused() and _player.elapsed() > t0, "P resumes")
	_player.stop()
	await _frames(1)


func _pause_mode_check() -> void:
	_make_stage()
	var guard := Node3D.new()
	guard.name = "Guard"
	guard.set_script(_model_script)
	_stage.add_child(guard)
	var walker := Node3D.new()
	walker.name = "Walker"
	walker.set_script(_mover_script)
	_stage.add_child(walker)
	await _frames(2)
	var s := CinematicScript.new()
	s.id = &"pause_mode"
	s.world_mode = CinematicScript.WorldMode.PAUSE
	var sh := CinematicShot.make(&"p1", 1.0, CinematicShot.CameraMode.STATIC)
	sh.add_action(0.1, &"anim", &"guard", Vector3.ZERO, {"hook": "play_gesture", "arg": &"wave", "animate": true})
	s.shots = [sh]
	var mode0 := guard.process_mode
	var n0 := _finished_log.size()
	_player.play(s, _stage)
	await _frames(15)
	var wx := walker.position.x
	await _frames(20)
	_expect(paused, "PAUSE mode: tree paused during")
	_expect(absf(walker.position.x - wx) < 0.000001, "PAUSE mode: a non-actor did not move")
	_expect(guard.process_mode == Node.PROCESS_MODE_ALWAYS, "PAUSE mode: animated actor set to ALWAYS")
	_expect(guard.get(&"gestures") == [&"wave"], "anim hook ran: %s" % [guard.get(&"gestures")])
	await _frames(40)
	_expect(_finished_log.size() == n0 + 1, "PAUSE-mode cinematic finished")
	_expect(not paused, "PAUSE mode: tree unpaused after")
	_expect(guard.process_mode == mode0, "PAUSE mode: process_mode restored (%d -> %d)" % [mode0, guard.process_mode])


func _recording_check() -> void:
	if _stage != null and is_instance_valid(_stage):
		_stage.free()
	var st := CinematicStage.new()
	st.name = "RecStage"
	st.render_scale = false
	st.force_recording = true
	st.quit_when_done = false
	var s := _short_script(&"rec_test", 1.0)
	s.shots[0].actions.clear()
	s.shots[0].add_action(0.0, &"title", &"", Vector3.ZERO, {"text": "Four Wizards", "sub": "Test", "time": 0.8})
	st.autoplay_script = s
	var done := [false, 0]
	st.recording_done.connect(func() -> void: done[0] = true)
	var n0 := _finished_log.size()
	root.add_child(st)
	_stage = st
	await _frames(5)
	_expect(st.is_black() and not _player.is_playing(), "recording: 0.5 s black head")
	var frames := 5
	var saw_title := false
	var saw_hidden_sub := false
	while not done[0] and frames < 400:
		await process_frame
		frames += 1
		if _player.is_playing():
			_expect(_player.recording, "recording flag set on the player")
			var ov := _player.overlay()
			if ov != null and ov.call(&"is_title_shown"):
				saw_title = true
			if ov != null and not (_player.debug_state()["line"] as Dictionary).is_empty() and ov.call(&"current_line_text") == "":
				saw_hidden_sub = true
			if frames == 40:
				_press(&"cinematic_skip")
				_press(&"cinematic_skip")
	_expect(done[0], "recording_done emitted")
	_expect(frames >= 115 and frames <= 130, "recording length ~ 0.5 + 1.0 + 0.5 s: %d frames" % frames)
	_expect(saw_title, "recording: title card shown")
	_expect(saw_hidden_sub, "recording: subtitles off")
	_expect(_finished_log.size() == n0 + 1 and _finished_log[-1] == [&"rec_test", false], "recording: skip ignored, finished(false)")
	_player.recording = false
