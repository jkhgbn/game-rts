extends SceneTree
## Replay Lab runner (docs/plan/replay-lab.md). One skirmish on scenes/skirmish.tscn with a replay session
## (scripts/core/replay/replay_session.gd), then one line "REPLAY_RESULT {...}" and quit.
##   godot --headless --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 --quit-after 400000 -- <args>
## Always pass --fixed-fps 60 (every frame = 1/60 s of game time, also for _process gameplay).
## Modes (--mode=):
##   bots    bot vs bot from a seed, recorded: --seed=N --minutes=M --pair=fire:shadow --difficulty=normal --out=PATH
##   script  the player side gets a fixed list of orders through the real SelectionManager API (the recorder notes
##           them like a human's), the enemy is the normal bot: --seed=N --minutes=3 --out=PATH
##   play    replays a .replay and checks the state hashes: --file=PATH (headless verify)
##   watch   same as play in a window (run WITHOUT --headless): 1 / 2 / 3 / 4 = speed x1 / x2 / x4 / x8,
##           Space = pause, arrows / edge pan = free camera (mouse clicks never reach the game)
## Options: --sim=1 (record without art, as the Bot Lab; replays follow the header), --bake=thread (record like a real
## game: threaded navmesh bakes, landing frames recorded), --hash-every=300, --result=PATH (the result line as a file),
## --dump=F (every unit's rid / position at frame F, to find what drifts), --bug-report=F (press F8 at frame F).
## Test-script rules (CLAUDE.md): compiled before autoloads; game nodes are read untyped.

const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const HOOKS_PATH := "res://scripts/core/replay/replay_hooks.gd"
const SESSION_PATH := "res://scripts/core/replay/replay_session.gd"
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


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
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
			if String(d.get("k", "")) == "header":
				header = d
				break
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
	if _overlay:
		_overlay.text = "REPLAY  x%d%s   %s   frame %d   [1-4 speed, Space pause]" % [_speed,
				"  PAUSED" if paused else "", _clock(t), int(session.get(&"frame"))]
	return _done


func _on_finished(result: Dictionary) -> void:
	_done = true
	result["mode"] = mode
	result["real_s"] = snappedf((Time.get_ticks_msec() - _t0) / 1000.0, 0.1)
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
	var layer := CanvasLayer.new()
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(layer)
	var blocker := Control.new()   # mouse clicks never reach the HUD or the 3D world (no new orders)
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(blocker)
	var keys := WatchKeys.new()
	keys.runner = self
	keys.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(keys)
	_overlay = Label.new()
	_overlay.position = Vector2(16, 8)
	_overlay.add_theme_font_size_override(&"font_size", 20)
	layer.add_child(_overlay)
	Engine.max_fps = TICK
	await process_frame
	var sm: Variant = main.get(&"selection")
	if sm is Node:
		(sm as Node).set_process_unhandled_input(false)
		(sm as Node).set_process_input(false)
	var rig: Variant = main.get(&"camera_rig")
	if rig is Node:
		(rig as Node).process_mode = Node.PROCESS_MODE_ALWAYS


## Watch-mode keys (a SceneTree gets no input events itself).
class WatchKeys extends Node:
	var runner: Object = null

	func _input(event: InputEvent) -> void:
		if runner != null:
			runner.call(&"input_event_watch", event)


func input_event_watch(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	match code:
		KEY_1, KEY_2, KEY_3, KEY_4:
			_speed = [1, 2, 4, 8][code - KEY_1]
			Engine.max_fps = TICK * _speed   # --fixed-fps: one 1/60 s game frame per drawn frame
		KEY_SPACE:
			paused = not paused


func _physics_process(_delta: float) -> bool:
	return _done and mode != "watch"


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
