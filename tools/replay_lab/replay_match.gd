extends SceneTree
## Replay Lab runner (docs/plan/replay-lab.md). One skirmish on scenes/skirmish.tscn with a replay session
## (scripts/core/replay/replay_session.gd), then one line "REPLAY_RESULT {...}" and quit.
##   godot --headless --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 --quit-after 400000 -- <args>
## Always pass --fixed-fps 60 (every frame = 1/60 s of game time, also for _process gameplay).
## Modes (--mode=):
##   bots    bot vs bot from a seed, recorded: --seed=N --minutes=M --pair=fire:shadow --difficulty=normal --out=PATH
##   script  the player side gets a fixed list of orders through the real SelectionManager API (the recorder notes
##           them like a human's), the enemy is the normal bot: --seed=N --minutes=3 --out=PATH
##   play    replays a .replay and checks the state hashes: --file=PATH (headless verify). A file without an "end"
##           line (an F8 bug report cut mid-match) stops after its last recorded frame; the result says "partial".
##   watch   same as play in a window (run WITHOUT --headless): 1 / 2 / 3 / 4 = speed x1 / x2 / x4 / x8,
##           Space = pause, arrows / edge pan / mouse wheel / middle-drag = free camera, F = follow the next wizard
##           (then free), Home = reset rotation. The bar at the bottom is the timeline: one tick per checkpoint
##           (grey = not reached, green = same hash as the recording, red = diverged); click it to seek (forward =
##           fast-forward without drawing; backward = the replay restarts in a new window and fast-forwards).
##           --seek=F starts paused at frame F. Clicks and keys never reach the game (no new orders).
## Options: --sim=1 (record without art, as the Bot Lab; replays follow the header), --bake=thread (record like a real
## game: threaded navmesh bakes, landing frames recorded), --hash-every=300, --result=PATH (the result line as a file),
## --dump=F (every unit's rid / position at frame F, to find what drifts), --bug-report=F (press F8 at frame F).
## Test-script rules (CLAUDE.md): compiled before autoloads; game nodes are read untyped.

const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const HOOKS_PATH := "res://scripts/core/replay/replay_hooks.gd"
const SESSION_PATH := "res://scripts/core/replay/replay_session.gd"
const STATE_PATH := "res://scripts/core/replay/replay_state.gd"
const SIM_MODE_PATH := "res://scripts/core/sim_mode.gd"
## Level children that only draw or play sound (the Bot Lab's list).
const SIM_STRIP_NAMES: Array[String] = ["SpellVfx", "CombatVfx", "IceVfx", "NatureVfx", "ChampionVfx", "TradeVfx",
		"MapFillVfx", "TitanVfx", "UnitVfx", "GameAudio", "Horizon"]
const DIFFICULTIES := {"easy": 0, "normal": 1, "hard": 2}
const TICK := 60

var args := {}
var mode := "bots"
var main: Node = null
var hooks: Script = null
var session: Node = null
var minutes := 3.0
var seed_value := 1
var lines: Array = []
var header := {}
var _t0 := 0
var _done := false
var _script_steps: Array = []   # [match seconds, Callable]
var _speed := 1
var _overlay: Label = null
var _last_print := -1
# play / watch: what the file holds
var _has_end := false
var _last_f := 0                 # last frame the file mentions (hash / cmd / bake / end)
var _end_f := 0                  # "end" frame, else _last_f
var _checks_rec := {}            # frame -> recorded hash
var _hash_every := 300
# watch mode
var _state: Script = null
var _marks := {}                 # frame -> true (same hash) / false (diverged)
var _first_bad := -1
var _first_bad_diff := ""
var _seek_target := -1
var _follow: Node3D = null
var _timeline: Control = null


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	# Determinism: Godot's multi-threaded RVO avoidance updates each agent's velocity inside the same parallel pass that
	# reads its neighbours' (a race: two runs drift ~0.001 m on crowded workers from frame 600). A navigation map reads
	# this setting when it is created, and the world's map is created lazily, after this point: this process gets a
	# single-threaded (deterministic) avoidance map while real games keep the multi-threaded default.
	ProjectSettings.set_setting(&"navigation/avoidance/thread_model/avoidance_use_multiple_threads", false)
	_parse_args()
	Engine.physics_ticks_per_second = TICK
	hooks = load(HOOKS_PATH) as Script
	hooks.set(&"auto_record", false)
	var options := {"hash_every": int(args.get("hash-every", "300"))}
	var setup := {}
	if mode == "play" or mode == "watch":
		var session_script := load(SESSION_PATH) as Script
		lines = session_script.call(&"read_file", String(args.get("file", "")))
		for d: Dictionary in lines:
			var k := String(d.get("k", ""))
			if k == "header" and header.is_empty():
				header = d
			elif k == "hash":
				_checks_rec[int(d["f"])] = String(d.get("h", ""))
			elif k == "end":
				_has_end = true
				_end_f = int(d.get("f", 0))
			if d.has("f"):
				_last_f = maxi(_last_f, int(d["f"]))
		if not _has_end:
			_end_f = _last_f
		_hash_every = maxi(1, int(header.get("hash_every", 300)))
		if header.is_empty():
			_fail("no header in %s" % args.get("file", ""))
			return
		setup = header.get("setup", {})
		options["mode"] = "play"
		options["lines"] = lines
		options["hash_every"] = int(header.get("hash_every", 300))
		hooks.set(&"bake_mode", 1 if String(header.get("bake", "sync")) == "sync" else 2)
	else:
		options["mode"] = "record"
		options["kind"] = mode
		options["seed"] = seed_value
		options["out"] = String(args.get("out", "user://replays/lab_%s_%d.replay" % [mode, seed_value]))
		# deterministic: navmesh bakes on the main thread; --bake=thread records like a real game (for checks)
		hooks.set(&"bake_mode", 0 if String(args.get("bake", "sync")) == "thread" else 1)
		var pair := String(args.get("pair", "fire:shadow")).split(":")
		setup = {"player_kingdom": pair[0], "enemy_kingdom": pair[1] if pair.size() > 1 else "shadow",
				"time_limit_s": 0.0, "bots": {"1": {"name": "ShadowBot", "difficulty": _difficulty()}}}
		if mode == "bots":
			setup["bots"]["0"] = {"name": "LabBot0", "difficulty": _difficulty()}
	hooks.set(&"pending_options", options)
	# Sim mode (scripts/core/sim_mode.gd, as the Bot Lab): no art / VFX / audio, gameplay unchanged. Recorded in the
	# header, so a replay runs the same way.
	var sim: bool = bool(setup.get("sim", false)) if mode == "play" or mode == "watch" else String(args.get("sim", "0")) == "1"
	if mode == "watch":
		sim = false
	if ResourceLoader.exists(SIM_MODE_PATH):
		(load(SIM_MODE_PATH) as Script).set(&"enabled", sim)
	main = (load(SCENE) as PackedScene).instantiate()
	if sim:
		for child in main.get_children():
			if SIM_STRIP_NAMES.has(String(child.name)):
				main.remove_child(child)
				child.free()
	_apply_setup(setup)
	root.add_child(main)
	current_scene = main
	print("REPLAY start mode %s seed %s file %s" % [mode, str(header.get("seed", seed_value)), args.get("file", args.get("out", ""))])
	if mode == "watch":
		_setup_watch()


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		if eq < 0:
			args[s] = "1"
		else:
			args[s.substr(0, eq)] = s.substr(eq + 1)
	mode = String(args.get("mode", "bots"))
	minutes = String(args.get("minutes", "3")).to_float()
	seed_value = String(args.get("seed", "1")).to_int()


func _difficulty() -> int:
	return int(DIFFICULTIES.get(String(args.get("difficulty", "normal")), 1))


## Kingdoms, toggles and bots, before the level enters the tree (as the menu does).
func _apply_setup(setup: Dictionary) -> void:
	for key: String in ["player_kingdom", "enemy_kingdom"]:
		if setup.has(key) and StringName(key) in main:
			main.set(StringName(key), StringName(String(setup[key])))
	for key: String in ["tavern_enabled", "trade_enabled", "river_enabled", "points_enabled", "camps_enabled",
			"beasts_enabled", "time_limit_s"]:
		if setup.has(key) and StringName(key) in main:
			main.set(StringName(key), setup[key])
	var commander_script := load(COMMANDER_PATH) as Script
	var bots := {}
	for child in main.get_children():
		if child.get_script() == commander_script:
			bots[int(child.get(&"team"))] = child
	var wanted: Dictionary = setup.get("bots", {})
	for team_text: String in wanted:
		var team := int(team_text)
		var b: Node = bots.get(team)
		if b == null:
			b = commander_script.new()
			b.name = String(wanted[team_text].get("name", "LabBot%d" % team))
			b.set(&"team", team)
			main.add_child(b)
		b.set(&"difficulty", int(wanted[team_text].get("difficulty", 1)))
	# A side without a bot in the setup plays nothing (the player side of a human / script replay).
	for team: int in bots:
		if not wanted.has(str(team)) and team == 0:
			main.remove_child(bots[team])
			bots[team].free()


func _process(_delta: float) -> bool:
	if _done:
		return true
	if main == null or not is_instance_valid(main):
		return true
	if session == null:
		var s: Variant = hooks.get(&"session")
		if s is Node and is_instance_valid(s):
			session = s
			session.finished.connect(_on_finished)
			if mode == "script":
				_build_script()
				physics_frame.connect(_run_script)
		elif Time.get_ticks_msec() - _t0 > 600000:
			_fail("the match never started")
		return false
	var t := float(main.call(&"match_time"))
	var dump_at := int(args.get("dump", "-1"))   # --dump=F: every unit's rid / type / position at frame F (debugging)
	if dump_at >= 0 and int(session.get(&"frame")) >= dump_at and not args.has("_dumped"):
		args["_dumped"] = "1"
		_dump_units()
	var bug_at := int(args.get("bug-report", "-1"))   # --bug-report=F: F8 at frame F (checks the zip)
	if bug_at >= 0 and int(session.get(&"frame")) >= bug_at and not args.has("_bug"):
		args["_bug"] = str(session.call(&"save_bug_report"))
		print("REPLAY bug report: %s" % args["_bug"])
	if int(t) % 30 == 0 and int(t) != _last_print:
		_last_print = int(t)
		print("REPLAY %s  frame %d  (%.1f s real)" % [_clock(t), int(session.get(&"frame")), (Time.get_ticks_msec() - _t0) / 1000.0])
	if (mode == "bots" or mode == "script") and t >= minutes * 60.0:
		session.call(&"stop", "time")
	# A file cut mid-match (F8 bug report: no "end" line): stop once its last recorded frame is done (else the replay
	# would run on with nothing to check until --quit-after).
	if (mode == "play" or mode == "watch") and not _has_end and int(session.get(&"frame")) > _last_f:
		session.call(&"stop", "end_of_file")
	if mode == "watch":
		_watch_tick(t)
	return _done


func _on_finished(result: Dictionary) -> void:
	_done = true
	result["mode"] = mode
	result["real_s"] = snappedf((Time.get_ticks_msec() - _t0) / 1000.0, 0.1)
	if mode == "play" or mode == "watch":
		# A file without an "end" line can't match an end hash: judge it on its checkpoints ("partial").
		result["partial"] = not _has_end
		result["partial_ok"] = not _has_end and int(result.get("checks", 0)) > 0 \
				and int(result.get("checks_ok", 0)) == int(result.get("checks", 0)) and (result.get("divergence", {}) as Dictionary).is_empty()
		result["file_checks"] = _checks_rec.size()
		result["file_end_frame"] = _end_f
	if mode == "bots" or mode == "script":
		result["abs_path"] = ProjectSettings.globalize_path(String(result.get("path", "")))
	_emit_result(result)
	if mode != "watch":
		quit(0)


func _fail(msg: String) -> void:
	_done = true
	_emit_result({"ok": false, "error": msg, "mode": mode})
	quit(1)


## Printed as "REPLAY_RESULT {...}" and, with --result=PATH, written there (tests/test_replay_lab.gd polls it).
func _emit_result(result: Dictionary) -> void:
	var line := JSON.stringify(result)
	print("REPLAY_RESULT " + line)
	var path := String(args.get("result", ""))
	if path != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_line(line)
			f.close()


# ---------------------------------------------------------------- script mode: orders through the real UI API

func _build_script() -> void:
	var sm: Object = main.get(&"selection")
	var hero: Node3D = main.get(&"hero")
	var keep: Node3D = main.call(&"keep_of", 0)
	var kp := keep.global_position
	_script_steps = [
		[1.0, func() -> void:
			sm.call(&"select_building", keep)
			var types: Array = sm.call(&"trainable_types")
			if not types.is_empty():
				sm.call(&"train", types[0])],
		[3.0, func() -> void:
			sm.call(&"select_units", [hero])
			sm.call(&"formation_move", hero.global_position + Vector3(6.0, 0.0, 6.0))],
		[20.0, func() -> void:
			var workers := _own_workers()
			if workers.size() >= 2:
				sm.call(&"select_units", workers.slice(0, 2))
				var node: Variant = main.call(&"node_of", 0, "b")
				if node != null:
					sm.call(&"gather", node)],
		[40.0, func() -> void:
			sm.call(&"select_units", [hero])
			sm.call(&"attack_move", hero.global_position.lerp(Vector3.ZERO, 0.4))],
		[60.0, func() -> void:
			var workers := _own_workers()
			if workers.is_empty():
				return
			sm.call(&"select_units", [workers[-1]])
			var types: Array = sm.call(&"buildable_types")
			if types.is_empty():
				return
			sm.call(&"begin_placement", types[0])
			sm.call(&"place_building_at", kp + (Vector3.ZERO - kp).normalized() * 12.0 + Vector3(6.0, 0.0, 0.0))],
		[90.0, func() -> void:
			sm.call(&"select_units", [hero])
			sm.call(&"stop")],
		[120.0, func() -> void:
			sm.call(&"select_building", keep)
			sm.call(&"order_at", kp + Vector3(4.0, 0.0, -4.0))],
		[150.0, func() -> void:
			sm.call(&"select_army")
			sm.call(&"formation_move", kp + (Vector3.ZERO - kp).normalized() * 8.0)],
	]


## physics_frame is emitted before any node's _physics_process, where real input lands between frames: the recorder
## notes the order with the frames already done, the replay gives it at the same point.
func _run_script() -> void:
	if _script_steps.is_empty() or main == null or not is_instance_valid(main):
		return
	var t := float(main.call(&"match_time"))
	while not _script_steps.is_empty() and t >= float(_script_steps[0][0]):
		var step: Array = _script_steps.pop_front()
		(step[1] as Callable).call()


func _dump_units() -> void:
	var rows: Array[String] = []
	for u in get_nodes_in_group(&"units"):
		var ut: Variant = u.get(&"unit_type")
		var p: Vector3 = (u as Node3D).global_position
		rows.append("DUMP f%d rid %d team %d %s pos (%.5f, %.5f, %.5f) hp %.2f" % [int(session.get(&"frame")),
				int(session.call(&"rid_of", u)), int(u.get(&"team")), String(ut.get(&"id")) if ut != null else u.name,
				p.x, p.y, p.z, float(u.get(&"hp"))])
	rows.sort()
	for r in rows:
		print(r)


func _own_workers() -> Array:
	var out := []
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == 0 and u.has_method(&"command_gather") and bool(u.call(&"is_alive")):
			out.append(u)
	return out


# ---------------------------------------------------------------- watch mode

func _setup_watch() -> void:
	_state = load(STATE_PATH) as Script
	var layer := CanvasLayer.new()
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(layer)
	var blocker := WatchBlocker.new()   # clicks never reach the HUD or the 3D world; wheel / middle drag reach the camera
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(blocker)
	var keys := WatchKeys.new()
	keys.runner = self
	keys.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(keys)
	_overlay = Label.new()
	_overlay.position = Vector2(16, 8)
	_overlay.add_theme_font_size_override(&"font_size", 18)
	_overlay.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_overlay.add_theme_constant_override(&"outline_size", 6)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	var bar := WatchTimeline.new()
	bar.runner = self
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 16.0
	bar.offset_right = -16.0
	bar.offset_top = -40.0
	bar.offset_bottom = -12.0
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bar)
	_timeline = bar
	Engine.max_fps = TICK
	physics_frame.connect(_watch_check)
	var seek := int(args.get("seek", "-1"))
	if seek > 0:
		_start_seek(seek)
	await process_frame
	var sm: Variant = main.get(&"selection")
	if sm is Node:
		(sm as Node).set_process_unhandled_input(false)
		(sm as Node).set_process_input(false)
	var rig: Variant = main.get(&"camera_rig")
	if rig is Node:
		(rig as Node).process_mode = Node.PROCESS_MODE_ALWAYS


## Per frame (watch): seek end, camera follow, overlay text, timeline redraw.
func _watch_tick(t: float) -> void:
	var f := int(session.get(&"frame"))
	if _seek_target >= 0 and (f >= _seek_target or _done):
		_seek_target = -1
		RenderingServer.render_loop_enabled = true
		Engine.max_fps = TICK * _speed
		paused = true
	if _follow != null:
		if is_instance_valid(_follow) and _follow.is_inside_tree():
			var rig: Variant = main.get(&"camera_rig")
			if rig is Object and (rig as Object).has_method(&"focus_on"):
				(rig as Object).call(&"focus_on", _follow.global_position)
		else:
			_follow = null
	if _overlay:
		var checked := 0
		var good := 0
		for k: int in _marks:
			checked += 1
			if _marks[k]:
				good += 1
		var state := "PAUSED" if paused else ("SEEKING to %s" % _clock(_seek_target / float(TICK)) if _seek_target >= 0 else "x%d" % _speed)
		var lines_txt: Array[String] = [
			"REPLAY  %s   %s / %s   frame %d / %d%s" % [state, _clock(t), _clock(_end_f / float(TICK)), f, _end_f,
					"   ENDED" if _done else ""],
			"checkpoints %d / %d same%s%s" % [good, checked, ("   first divergence %s: %s" % [_clock(_first_bad / float(TICK)),
					_first_bad_diff]) if _first_bad >= 0 else "", ("   (sim recording watched with art: small drift is expected)"
					if bool(header.get("setup", {}).get("sim", false)) and _first_bad >= 0 else "")],
			"follow: %s   [1-4 speed  Space pause  F follow  wheel zoom  click the bar to seek]" % [
					String(_follow.name) if _follow != null else "free camera"],
		]
		_overlay.text = "\n".join(lines_txt)
	if _timeline:
		_timeline.queue_redraw()


## physics_frame comes before every node's _physics_process, so the state here is the one the session hashes at the
## top of this frame: compare it with the recording's checkpoint (the session keeps its own verdict private).
func _watch_check() -> void:
	if session == null or not is_instance_valid(session) or _state == null:
		return
	var f := int(session.get(&"frame"))
	if f <= 0 or f % _hash_every != 0 or _marks.has(f) or not _checks_rec.has(f):
		return
	var t := float(main.call(&"match_time")) if main.has_method(&"match_time") else 0.0
	var s: Dictionary = _state.call(&"summary", self, f, t)
	var same := String(_state.call(&"hash_of", s)) == String(_checks_rec[f])
	_marks[f] = same
	if not same and _first_bad < 0:
		_first_bad = f
		for d: Dictionary in lines:
			if String(d.get("k", "")) == "hash" and int(d.get("f", -1)) == f:
				var diff: Array = _state.call(&"diff", d.get("s", {}), s)
				_first_bad_diff = "; ".join(PackedStringArray(diff)).left(160)
				break
		print("REPLAY watch: checkpoint %d (%s) differs from the recording (red on the timeline)" % [f, _clock(t)])


## Timeline data for WatchTimeline.
func timeline_info() -> Dictionary:
	return {"end": maxi(1, _end_f), "frame": int(session.get(&"frame")) if session != null and is_instance_valid(session) else 0,
			"checks": _checks_rec.keys(), "marks": _marks, "seek": _seek_target, "first_bad": _first_bad}


## Seek to a frame: forward = run without drawing until there, then pause; backward = restart this replay in a new
## process with --seek (a replay can only be re-simulated from the start) and close this one.
func seek_to(target: int) -> void:
	target = clampi(target, 0, _end_f)
	var f := int(session.get(&"frame")) if session != null and is_instance_valid(session) else 0
	if target > f and not _done:
		_start_seek(target)
		return
	var engine_args := PackedStringArray(OS.get_cmdline_args())
	var user_args := PackedStringArray()
	for a: String in OS.get_cmdline_user_args():
		if not a.begins_with("--seek="):
			user_args.append(a)
	user_args.append("--seek=%d" % target)
	engine_args.append("--")
	engine_args.append_array(user_args)
	var pid := OS.create_process(OS.get_executable_path(), engine_args)
	if pid > 0:
		print("REPLAY seek back to frame %d: restarted as pid %d" % [target, pid])
		quit(0)


func _start_seek(target: int) -> void:
	_seek_target = target
	paused = false
	Engine.max_fps = 0
	RenderingServer.render_loop_enabled = false   # no drawing while fast-forwarding (much faster)


## F: follow the next wizard (player side first), then back to the free camera.
func _cycle_follow() -> void:
	var heroes: Array[Node3D] = []
	for h in get_nodes_in_group(&"heroes"):
		if h is Node3D and h.has_method(&"is_alive") and bool(h.call(&"is_alive")):
			heroes.append(h as Node3D)
	heroes.sort_custom(func(a: Node3D, b: Node3D) -> bool: return int(a.get(&"team")) < int(b.get(&"team")))
	if heroes.is_empty():
		_follow = null
		return
	var i := heroes.find(_follow)
	_follow = heroes[i + 1] if i + 1 < heroes.size() else (null if i >= 0 else heroes[0])


## Watch-mode keys (a SceneTree gets no input events itself). Every key is eaten here (a watch never gives an
## order: no hotkey, spell or window key reaches the HUD / wizard control), except Home (camera rotation reset).
## Arrows still pan: the camera polls Input.is_key_pressed.
class WatchKeys extends Node:
	var runner: Object = null

	func _input(event: InputEvent) -> void:
		if runner == null or not (event is InputEventKey):
			return
		var key := event as InputEventKey
		if key.keycode == KEY_HOME or key.physical_keycode == KEY_HOME:
			return
		runner.call(&"input_event_watch", event)
		get_viewport().set_input_as_handled()


## Full-screen input filter: mouse buttons stop here (no selection / order / HUD click), the wheel and the middle button
## (zoom / rotate) go on to the camera's _unhandled_input.
class WatchBlocker extends Control:
	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and not [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_MIDDLE].has(mb.button_index):
			accept_event()


## The timeline bar: checkpoints (grey / green / red), the playhead, the seek target; a click seeks.
class WatchTimeline extends Control:
	var runner: Object = null

	func _draw() -> void:
		if runner == null:
			return
		var info: Dictionary = runner.call(&"timeline_info")
		var end := float(info["end"])
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.55))
		draw_rect(Rect2(0.0, 0.0, w * clampf(float(info["frame"]) / end, 0.0, 1.0), h), Color(0.35, 0.45, 0.6, 0.45))
		var marks: Dictionary = info["marks"]
		for f: int in info["checks"]:
			var x := w * float(f) / end
			var c := Color(0.6, 0.6, 0.6, 0.8)
			if marks.has(f):
				c = Color(0.3, 0.85, 0.35) if marks[f] else Color(0.95, 0.25, 0.2)
			draw_line(Vector2(x, h * 0.25), Vector2(x, h * 0.75), c, 2.0)
		if int(info["first_bad"]) >= 0:
			var xb := w * float(info["first_bad"]) / end
			draw_line(Vector2(xb, 0.0), Vector2(xb, h), Color(0.95, 0.25, 0.2), 3.0)
		if int(info["seek"]) >= 0:
			var xs := w * float(info["seek"]) / end
			draw_line(Vector2(xs, 0.0), Vector2(xs, h), Color(1.0, 0.85, 0.2), 2.0)
		var xp := w * clampf(float(info["frame"]) / end, 0.0, 1.0)
		draw_line(Vector2(xp, -4.0), Vector2(xp, h + 4.0), Color.WHITE, 2.0)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and runner != null and size.x > 0.0:
			var info: Dictionary = runner.call(&"timeline_info")
			runner.call(&"seek_to", roundi(clampf(mb.position.x / size.x, 0.0, 1.0) * float(info["end"])))
			accept_event()


func input_event_watch(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	match code:
		KEY_1, KEY_2, KEY_3, KEY_4:
			_speed = [1, 2, 4, 8][code - KEY_1]
			if _seek_target < 0:
				Engine.max_fps = TICK * _speed   # --fixed-fps: one 1/60 s game frame per drawn frame
		KEY_SPACE:
			if _seek_target < 0:
				paused = not paused
		KEY_F:
			_cycle_follow()


func _physics_process(_delta: float) -> bool:
	return _done and mode != "watch"


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
