extends SceneTree
## Fix batch F5 (code review V1-1..V1-4, docs/handoff/code-review-2026-10-12.md).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_f5_cinematics.gd --fixed-fps 60 --quit-after 3000
## - V1-2: a film watched to the end applies the end state of a move still running (actor at its target).
## - V1-3: voice players started by a film are tracked, paused with it and stopped when it ends.
## - V1-4: the overlay's subtitle timer is frozen while paused; the line is re-sent on resume.
## - V1-1: the film stops when its level (context) leaves the tree; the level's own callbacks are dropped.
## Never names the Events autoload (tests compile before autoloads exist).

const TASK_ID := "f5_cinematics"
const VOICE := "res://assets/audio/forge/music/ep3_opening.wav"

var _fails: Array[String] = []
var _player: CinematicPlayer
var _ctx_script: GDScript


func _initialize() -> void:
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _make_context() -> Node3D:
	var ctx := Node3D.new()
	ctx.set_script(_ctx_script)
	ctx.name = "F5Level"
	var hero := Node3D.new()
	hero.name = "Hero"
	ctx.add_child(hero)
	root.add_child(ctx)
	return ctx


func _run() -> void:
	await process_frame
	_ctx_script = GDScript.new()
	_ctx_script.source_code = """extends Node3D
var finished_calls := 0
func on_finished(_id: StringName, _skipped: bool) -> void:
	finished_calls += 1
"""
	_ctx_script.reload()
	_player = CinematicPlayer.instance(self)
	_player.log_enabled = false
	_player.emit_events = false
	_player.audio_in_headless = true
	await _test_end_state()
	await _test_pause_and_context_exit()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## V1-2: a 1 s film whose move needs 10 s: the end state still puts the actor at its target.
func _test_end_state() -> void:
	var ctx := _make_context()
	var hero := ctx.get_node("Hero") as Node3D
	_player.register_actor(&"hero", hero)
	var s := CinematicScript.new()
	s.id = &"f5_end_state"
	var shot := CinematicShot.make(&"a", 1.0)
	shot.actions.append(CinematicAction.make(0.2, &"move", &"hero", Vector3(10, 0, 0), {"speed": 1.0}))
	s.shots.append(shot)
	var done := [false]
	_player.finished.connect(func(_id: StringName, skipped: bool) -> void: done[0] = not skipped, CONNECT_ONE_SHOT)
	_expect(_player.play(s, ctx) == "", "end-state film plays")
	for i in 180:
		await process_frame
		if not _player.is_playing():
			break
	_expect(done[0], "end-state film finished (not skipped)")
	_expect(hero.global_position.distance_to(Vector3(10, 0, 0)) < 0.01,
			"V1-2 running move gets its end state on a normal finish (at %s)" % hero.global_position)
	ctx.queue_free()
	await process_frame


## V1-3 / V1-4 / V1-1 on one long voiced film.
func _test_pause_and_context_exit() -> void:
	var ctx := _make_context()
	_player.register_actor(&"hero", ctx.get_node("Hero") as Node3D)
	var s := CinematicScript.new()
	s.id = &"f5_long"
	var shot := CinematicShot.make(&"a", 20.0)
	var line := CinematicLine.make(0.1, &"vessa", "A line long enough to stay on screen.", 10.0)
	line.voice = VOICE
	shot.lines.append(line)
	s.shots.append(shot)
	var ours := [0]
	_player.finished.connect(Callable(ctx, "on_finished"))
	var outside := func(_id: StringName, _skipped: bool) -> void: ours[0] += 1
	_player.finished.connect(outside)
	_expect(_player.play(s, ctx) == "", "long film plays")
	await _frames(20)
	var voices := _player.audio_players()
	_expect(voices.size() == 1, "V1-3 voice player tracked (%d)" % voices.size())
	var ov := _player.overlay()
	_expect(ov != null and float(ov.call(&"line_time_left")) > 0.0, "subtitle on screen")
	# pause
	_player.set_paused(true)
	var left0 := float(ov.call(&"line_time_left")) if ov else 0.0
	await _frames(60)
	var left1 := float(ov.call(&"line_time_left")) if ov else -1.0
	_expect(absf(left1 - left0) < 0.001, "V1-4 subtitle timer frozen while paused (%.3f -> %.3f)" % [left0, left1])
	for p: AudioStreamPlayer in voices:
		_expect(is_instance_valid(p) and p.stream_paused, "V1-3 voice paused with the film")
	_player.set_paused(false)
	var expect_left := 10.0 - (_player.elapsed() - 0.1)
	_expect(absf(float(ov.call(&"line_time_left")) - expect_left) < 0.05 if ov else false,
			"V1-4 line re-sent on resume with the time it has left")
	for p: AudioStreamPlayer in voices:
		_expect(is_instance_valid(p) and not p.stream_paused, "V1-3 voice resumes with the film")
	await _frames(10)
	# the level leaves the tree (quickload / restart / menu)
	root.remove_child(ctx)
	_expect(not _player.is_playing(), "V1-1 film stopped when its level left the tree")
	_expect(not CinematicPlayer.is_any_playing(self), "V1-1 no film playing after the level left")
	_expect(_player.audio_players().is_empty(), "V1-3 voice players stopped with the film")
	_expect(int(ctx.get(&"finished_calls")) == 0, "V1-1 the leaving level's finished callback is dropped")
	_expect(ours[0] == 1, "V1-1 other listeners still hear finished (%d)" % ours[0])
	if _player.finished.is_connected(outside):
		_player.finished.disconnect(outside)
	await _frames(2)
	for p: AudioStreamPlayer in voices:
		_expect(not is_instance_valid(p), "V1-3 voice player freed")
	# the player is reusable afterwards
	var ctx2 := _make_context()
	var s2 := CinematicScript.new()
	s2.id = &"f5_again"
	s2.shots.append(CinematicShot.make(&"a", 0.3))
	_expect(_player.play(s2, ctx2) == "", "player plays again after a context exit")
	await _frames(40)
	_expect(not _player.is_playing(), "second film finished")
	ctx.free()
	ctx2.queue_free()
	await process_frame
	await _test_pause_mode_exit()


## Lead review: a PAUSE film whose level leaves must not touch tree.paused (the scene changer unpaused already).
func _test_pause_mode_exit() -> void:
	var ctx := _make_context()
	var s := CinematicScript.new()
	s.id = &"f5_pause"
	s.world_mode = CinematicScript.WorldMode.PAUSE
	s.shots.append(CinematicShot.make(&"a", 10.0))
	paused = true   # paused before the film: a normal end would restore true
	_expect(_player.play(s, ctx) == "", "pause film plays")
	await _frames(5)
	paused = false   # SaveGame.launch / MenuFlow unpause, then set_scene removes the old level
	root.remove_child(ctx)
	_expect(not _player.is_playing(), "pause film stopped when its level left")
	_expect(not paused, "level-leaving path leaves tree.paused alone (new level not paused)")
	paused = false
	ctx.free()
	await process_frame
