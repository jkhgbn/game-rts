extends RefCounted
## Replay Lab hooks (docs/plan/replay-lab.md). The ONLY replay file game code touches, so keep it tiny and stable:
## game code reaches it through a preload (never a class name, so a stale class cache can't break a script):
##   const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")   ...   _REPLAY.note(&"stop", [], self)
## Every function is a cheap no-op while no replay session runs. The session itself
## (scripts/core/replay/replay_session.gd) is loaded by path, so a broken session script never breaks the game.

const SESSION_PATH := "res://scripts/core/replay/replay_session.gd"

## Navmesh rebake modes (BuildGrid.request_rebake asks `rebake_mode()`).
const BAKE_THREAD := 0     ## the game's default: bake on a thread (lands after a wall-clock-dependent delay)
const BAKE_SYNC := 1       ## deterministic runs: bake on the main thread, at once
const BAKE_DEFERRED := 2   ## replaying a thread-baked recording: the session bakes at the recorded landing frames

## The running ReplaySession (a Node under the level), or null.
static var session: Object = null
## When true, every skirmish records itself (user://replays/, last 20 kept) and F8 saves a bug report. OFF by default
## (lead 2026-09-26: the replay code stays inert unless a recording / replay is active); the Replay Lab runner drives
## its own sessions through `pending_options`. To be switched on by a settings toggle (docs/plan/replay-lab.md).
static var auto_record := false
## Set by the lab before the level is instanced; read by `rebake_mode()`.
static var bake_mode := BAKE_THREAD
## Set by the lab: the session to start at match start is a player (replay) instead of a recorder. Dictionary
## {"mode": "play" / "record", ...options}; empty = auto (record when auto_record).
static var pending_options := {}
## Playtest Recorder (docs/design/health-and-playtests.md): set by GameSettings from the "Playtest data" setting (OFF by
## default). When true, `match_started` also attaches scripts/core/playtest/playtest_recorder.gd to the level.
const PLAYTEST_PATH := "res://scripts/core/playtest/playtest_recorder.gd"
static var playtest_enabled := false
## The running playtest recorder (or null): it hears every player command `note` sees (the same command stream the
## Replay Lab records, so nothing is noted twice in game code).
static var listener: Object = null


## A player command at the UI / command level (SelectionManager, WizardControl...). `kind` names the command
## (docs/plan/replay-lab.md "Commands"), `args` its world-level arguments (Vector3, nodes, resources, ints...),
## `selection` the SelectionManager (its selection is saved with the command).
static func note(kind: StringName, args: Array = [], selection: Object = null) -> void:
	if session != null and is_instance_valid(session):
		session.call(&"note", kind, args, selection)
	if listener != null:
		if is_instance_valid(listener):
			listener.call(&"on_command", kind, args)
		else:
			listener = null


## BuildGrid: how to rebake the navmesh now (BAKE_*). While a session defers bakes it also counts the request.
static func rebake_mode() -> int:
	if session != null and is_instance_valid(session) and bake_mode == BAKE_DEFERRED:
		session.call(&"bake_requested")
	return bake_mode


## Physics frame at which the level asked for its first navmesh (main.gd); the session records the wait until the
## match start (`pre_frames` in the header: 0 when the first bake ran on the main thread).
static var level_ready_frame := -1


static func level_ready() -> void:
	level_ready_frame = Engine.get_physics_frames()


## Skirmish._start_match: starts the replay session (recorder or player) as a child of the level.
static func match_started(level: Node) -> void:
	if level == null:
		return
	if playtest_enabled and pending_options.is_empty():
		start_playtest(level)
	if pending_options.is_empty() and not auto_record:
		return
	if not ResourceLoader.exists(SESSION_PATH):
		return
	var script := load(SESSION_PATH) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Replay: %s can't be instantiated, no replay" % SESSION_PATH)
		return
	var s := script.new() as Node
	if s == null:
		return
	s.name = "ReplaySession"
	s.call(&"configure", level, pending_options.duplicate(true))
	level.add_child(s)


## Attaches a Playtest Recorder to `level` (skirmish / missions through match_started; another mode such as Wave Strike
## calls this itself when `playtest_enabled`). `mode` = "" (worked out from the level). Returns the recorder or null.
static func start_playtest(level: Node, mode := "", options := {}) -> Node:
	if level == null or not ResourceLoader.exists(PLAYTEST_PATH):
		return null
	var script := load(PLAYTEST_PATH) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Playtest: %s can't be instantiated, no recording" % PLAYTEST_PATH)
		return null
	var r := script.new() as Node
	r.name = "PlaytestRecorder"
	var o: Dictionary = options.duplicate()
	if mode != "":
		o["mode"] = mode
	r.call(&"configure", level, o)
	level.add_child(r)
	return r
