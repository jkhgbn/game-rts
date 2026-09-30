extends Node
## Replay Lab (docs/plan/replay-lab.md): one replay session under a skirmish level, started by
## ReplayHooks.match_started (scripts/core/replay/replay_hooks.gd). Two modes:
## - "record": seeds the match's random systems from one match seed, numbers every entity (rid, in ready order),
##   logs the player's commands (ReplayHooks.note) with the physics frame, a state hash every `hash_every` frames and
##   the end hash to a JSON-lines `.replay` (user://replays/ by default). F8 = "Save bug report" (bug_report.gd).
## - "play": same seeding and numbering, applies the recorded commands at their frames, compares the state hash at
##   every checkpoint and at the end; `result()` says whether it matched and where it first diverged.
## Frames count physics frames since the match start (this node runs first in each physics frame, priority -1000).
## A command noted between physics frames f and f + 1 is applied in play at the start of frame f + 1.
## Nothing here is typed against gameplay classes: game nodes are read with get / call / has_method.

const _HOOKS := preload("res://scripts/core/replay/replay_hooks.gd")
const _STATE := preload("res://scripts/core/replay/replay_state.gd")
const BUG_REPORT_PATH := "res://scripts/core/replay/bug_report.gd"

const FORMAT_VERSION := 1
const REPLAY_DIR := "user://replays"
const MAX_KEPT := 20
const DEFAULT_HASH_EVERY := 300
## Groups whose members get a replay id (rid). Checked once, when the node is ready.
const ENTITY_GROUPS: Array[StringName] = [&"units", &"buildings", &"crystal_nodes", &"trade_posts", &"game_critters",
		&"item_pickups", &"bounties", &"capture_points", &"taverns", &"guilds", &"markets"]
## Service nodes whose `rng` is re-seeded from the match seed at the start (same list as the Bot Lab).
const SEEDED_SERVICES: Array[StringName] = [&"thieves_guild", &"camp_manager", &"epic_beasts", &"critter_herds"]
const RNG_FIELDS: Array[StringName] = [&"class_rng", &"_rng", &"rng"]

signal finished(result: Dictionary)

var level: Node = null
var mode := "record"
var match_seed := 0
var hash_every := DEFAULT_HASH_EVERY
var out_path := ""
var frame := 0

var _options := {}
var _file: FileAccess = null
var _lines: Array[String] = []        # everything written (kept for bug reports)
var _rids := {}                       # Node -> int
var _by_rid := {}                     # int -> Node
var _next_rid := 0
var _rng_counter := 0
var _applying := false                # play / script: our own command calls must not be noted again
var _last_move_input := Vector3.INF
var _last_selection := ""
var _stop_reason := ""
var _queued: Array = []               # script mode: [kind, args, selection rids] applied next frame
var _started := false
var _ended := false
# play
var _cmds := {}                       # frame -> Array of command dicts
var _checks := {}                     # frame -> {"h", "s"}
var _bakes := {}                      # frame -> count (deferred rebakes)
var _end := {}
var _header := {}
var _divergence := {}
var _checks_ok := 0
var _checks_total := 0
var _result := {}
var _bake_requests := 0


## Called by ReplayHooks before the node enters the tree. Options (all optional):
## mode "record" / "play" / "script", seed, out (path), hash_every, lines (play: the parsed file, Array of Dictionary).
func configure(p_level: Node, options: Dictionary) -> void:
	level = p_level
	_options = options
	mode = String(options.get("mode", "record"))
	hash_every = int(options.get("hash_every", DEFAULT_HASH_EVERY))
	out_path = String(options.get("out", ""))
	if mode == "play":
		_load_lines(options.get("lines", []))
		match_seed = int(_header.get("seed", 1))
	else:
		match_seed = int(options.get("seed", 0))
		if match_seed == 0:
			var r := RandomNumberGenerator.new()
			r.randomize()
			match_seed = r.randi_range(1, 2000000000)


func _enter_tree() -> void:
	process_physics_priority = -1000
	_HOOKS.session = self


func _exit_tree() -> void:
	if not _ended and _started:
		_finish("left")
	if _HOOKS.session == self:
		_HOOKS.session = null


func _ready() -> void:
	seed(hash([match_seed, "global"]))
	_seed_services()
	# Entities that exist at the match start, in group order (deterministic when the game is).
	for g in ENTITY_GROUPS:
		for n in get_tree().get_nodes_in_group(g):
			_assign_rid(n)
	get_tree().node_added.connect(_on_node_added)
	var region: Variant = level.get(&"nav_region") if level else null
	if region is NavigationRegion3D:
		(region as NavigationRegion3D).bake_finished.connect(_on_bake_finished)
		_sync_nav_map(region as NavigationRegion3D)
	# Selection changes are commands too: some gameplay reads the selection (TrainingBuilding._process drops a dead
	# gather rally only while selected).
	var sm: Variant = level.get(&"selection") if level else null
	if mode == "record" and sm is Object and (sm as Object).has_signal(&"selection_changed"):
		(sm as Object).connect(&"selection_changed", _on_selection_changed.bind(sm))
	if mode == "record":
		_add_bug_key()
	if mode == "record" or mode == "script":
		_open_out()
		_write({"k": "header", "v": FORMAT_VERSION, "game": game_version(), "date": Time.get_datetime_string_from_system(),
				"mode": String(_options.get("kind", "player")), "seed": match_seed, "tick": Engine.physics_ticks_per_second,
				"hash_every": hash_every, "bake": ["thread", "sync", "deferred"][clampi(_HOOKS.bake_mode, 0, 2)],
				"pre_frames": Engine.get_physics_frames() - _HOOKS.level_ready_frame if _HOOKS.level_ready_frame >= 0 else -1,
				"setup": setup_of(level)})
	_started = true


## The match setup a replay needs to rebuild the same skirmish (applied by the lab before the level enters the tree).
static func setup_of(lvl: Node) -> Dictionary:
	var s := {}
	for key: StringName in [&"player_kingdom", &"enemy_kingdom", &"tavern_enabled", &"trade_enabled", &"river_enabled",
			&"points_enabled", &"camps_enabled", &"beasts_enabled", &"time_limit_s"]:
		if lvl != null and key in lvl:
			var v: Variant = lvl.get(key)
			s[String(key)] = String(v) if v is StringName else v
	var bots := {}
	if lvl != null:
		for n in lvl.get_children():
			if n.has_method(&"tick_usec_average") or (&"difficulty" in n and &"team" in n and n.get_script() != null
					and String((n.get_script() as Script).resource_path).ends_with("commander.gd")):
				var b := {"name": String(n.name), "difficulty": int(n.get(&"difficulty"))}
				if &"style" in n:
					b["style"] = String(n.get(&"style"))
				bots[str(int(n.get(&"team")))] = b
	s["bots"] = bots
	var gs: Variant = _game_settings()
	if gs != null:
		s["map_detail"] = String(gs.get(&"map_detail"))
		s["control_scheme"] = int(gs.get(&"control_scheme"))
	var sim: Script = load("res://scripts/core/sim_mode.gd") as Script \
			if ResourceLoader.exists("res://scripts/core/sim_mode.gd") else null
	s["sim"] = bool(sim.get(&"enabled")) if sim != null else false
	return s


static func _game_settings() -> Variant:
	var path := "res://scripts/ui/menus/game_settings.gd"
	return load(path) if ResourceLoader.exists(path) else null


## The commit hash from .git (read only, never runs git), else "date:<today>".
static func game_version() -> String:
	var git := ProjectSettings.globalize_path("res://.git/")
	var head := FileAccess.get_file_as_string(git + "HEAD").strip_edges()
	if head.begins_with("ref: "):
		var ref := head.substr(5)
		var h := FileAccess.get_file_as_string(git + ref).strip_edges()
		if h == "":
			for line in FileAccess.get_file_as_string(git + "packed-refs").split("\n"):
				if line.ends_with(" " + ref):
					h = line.get_slice(" ", 0)
		if h != "":
			return h.substr(0, 12)
	elif head.length() >= 12:
		return head.substr(0, 12)
	return "date:" + Time.get_date_string_from_system()


# ---------------------------------------------------------------- seeding and ids

func _seed_services() -> void:
	for group in SEEDED_SERVICES:
		for n in get_tree().get_nodes_in_group(group):
			var r: Variant = n.get(&"rng")
			if r is RandomNumberGenerator:
				(r as RandomNumberGenerator).seed = hash([match_seed, String(group)])
	if level:
		for n in level.get_children():   # Lost Caches
			if &"rng" in n and n.get(&"rng") is RandomNumberGenerator and n.has_signal(&"opened"):
				(n.get(&"rng") as RandomNumberGenerator).seed = hash([match_seed, String(n.name)])


func _on_node_added(node: Node) -> void:
	if node.get_script() == null:
		return
	# By name: some game scripts have a method called `ready`, so `node.ready` is not always the signal.
	var cb := _on_node_ready.bind(node)
	if not node.is_connected(&"ready", cb):
		node.connect(&"ready", cb, CONNECT_ONE_SHOT)


## After the node's own _ready (champions / brains randomize theirs there): seed its RNGs, give it a rid.
func _on_node_ready(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for key in RNG_FIELDS:
		if key in node:
			var r: Variant = node.get(key)
			if r is RandomNumberGenerator:
				_rng_counter += 1
				(r as RandomNumberGenerator).seed = hash([match_seed, _rng_counter, String(key)])
	_assign_rid(node)


func _assign_rid(node: Node) -> void:
	if _rids.has(node):
		return
	for g in ENTITY_GROUPS:
		if node.is_in_group(g):
			_rids[node] = _next_rid
			_by_rid[_next_rid] = node
			_next_rid += 1
			return


func rid_of(node: Object) -> int:
	return int(_rids.get(node, -1)) if node != null and is_instance_valid(node) else -1


func node_of_rid(rid: int) -> Node:
	var n: Variant = _by_rid.get(rid)
	return n if n != null and is_instance_valid(n) else null


## Map changes (a rebake) reach path queries on the next map sync, not after an async iteration of unknown length.
## Only in deterministic runs (BAKE_SYNC: the first navmesh was baked on the main thread): switching async iterations
## off after a threaded first bake left the map without paths (units never moved) in the first tests.
func _sync_nav_map(region: NavigationRegion3D) -> void:
	if not region.is_inside_tree() or _HOOKS.bake_mode != _HOOKS.BAKE_SYNC:
		return
	var map := region.get_world_3d().navigation_map if region.get_world_3d() else RID()
	if map.is_valid() and NavigationServer3D.has_method(&"map_set_use_async_iterations"):
		NavigationServer3D.call(&"map_set_use_async_iterations", map, false)
	# Regions update asynchronously too (Godot 4.5+): a new navmesh would reach the map after a wall-clock delay.
	if NavigationServer3D.has_method(&"region_set_use_async_iterations") and level:
		for r in level.find_children("*", "NavigationRegion3D", true, false):
			NavigationServer3D.call(&"region_set_use_async_iterations", (r as NavigationRegion3D).get_rid(), false)


# ---------------------------------------------------------------- frames

## Runs first in every physics frame. `frame` = physics frames fully done, so at this point the state is the one
## after `frame` frames: end check, checkpoint, then the commands noted after that frame, then the count moves on.
func _physics_process(_delta: float) -> void:
	if _ended or level == null or not is_instance_valid(level):
		return
	if mode == "play" and not _end.is_empty() and frame >= int(_end.get("f", 0)):
		_finish("end_frame")
		return
	if bool(level.get(&"game_over")):
		_finish("game_over")
		return
	if _stop_reason != "":
		_finish(_stop_reason)
		return
	if frame > 0 and frame % hash_every == 0:
		_checkpoint()
	if mode == "play":
		for c: Dictionary in _cmds.get(frame, []):
			_apply(c)
		for i in int(_bakes.get(frame, 0)):
			_deferred_bake()
	elif mode == "script" and not _queued.is_empty():
		var q := _queued.duplicate()
		_queued.clear()
		for item: Array in q:
			var cmd := {"k": "cmd", "f": frame, "c": String(item[0]), "a": encode(item[1]), "sel": item[2], "b": item[3],
					"fl": -1}
			_write(cmd)
			_apply(cmd)
	frame += 1


func _checkpoint() -> void:
	var t := float(level.call(&"match_time")) if level.has_method(&"match_time") else 0.0
	var s := _STATE.summary(get_tree(), frame, t)
	var h := _STATE.hash_of(s)
	if mode == "play":
		var rec: Variant = _checks.get(frame)
		if rec is Dictionary:
			_checks_total += 1
			if String(rec["h"]) == h:
				_checks_ok += 1
			elif _divergence.is_empty():
				_divergence = {"f": frame, "t": s["t"], "diff": _STATE.diff(rec.get("s", {}), s)}
				print("REPLAY diverged at frame %d (%s): %s" % [frame, _clock(float(s["t"])), "; ".join(_divergence["diff"])])
	else:
		_write({"k": "hash", "f": frame, "h": h, "s": s})
		if _file:
			_file.flush()


func _finish(reason: String) -> void:
	if _ended:
		return
	_ended = true
	var t := float(level.call(&"match_time")) if level and is_instance_valid(level) and level.has_method(&"match_time") else 0.0
	var s := _STATE.summary(get_tree(), frame, t) if is_inside_tree() else {}
	var h := _STATE.hash_of(s) if not s.is_empty() else ""
	if mode == "play":
		var end_ok := not _end.is_empty() and String(_end.get("h", "")) == h and int(_end.get("f", -1)) == frame
		if not end_ok and _divergence.is_empty() and not _end.is_empty():
			_divergence = {"f": frame, "t": s.get("t", 0.0), "diff": _STATE.diff(_end.get("s", {}), s)}
		_result = {"ok": end_ok and _divergence.is_empty(), "end_match": end_ok, "frame": frame,
				"recorded_end_frame": int(_end.get("f", -1)), "checks": _checks_total, "checks_ok": _checks_ok,
				"hash": h, "recorded_hash": String(_end.get("h", "")), "reason": reason, "divergence": _divergence}
	else:
		var winner := int(level.get(&"winner_team")) if level and is_instance_valid(level) and level.get(&"winner_team") != null else -1
		_write({"k": "end", "f": frame, "h": h, "s": s, "reason": reason, "winner": winner})
		if _file:
			_file.close()
			_file = null
		_result = {"ok": true, "frame": frame, "hash": h, "path": out_path, "reason": reason}
		_prune()
	finished.emit(_result)


## play: the verdict (empty until the end). record: the file written.
func result() -> Dictionary:
	return _result


## Ends the session at the start of the next physics frame (the same point in the loop where a replay ends, so
## `_process` gameplay of this frame is counted on both sides).
func stop(reason: String = "stopped") -> void:
	if _stop_reason == "":
		_stop_reason = reason


# ---------------------------------------------------------------- recording

## ReplayHooks.note: a player command from the UI.
func note(kind: StringName, args: Array, selection: Object) -> void:
	if mode != "record" or _applying or _ended or not _started:
		return
	if kind == &"move_input":
		var d: Vector3 = args[0] if args.size() > 0 and args[0] is Vector3 else Vector3.ZERO
		if d.is_equal_approx(_last_move_input):
			return
		_last_move_input = d
	var cmd := {"k": "cmd", "f": frame, "c": String(kind), "a": encode(args), "sel": [], "b": -1, "fl": -1}
	if selection != null and is_instance_valid(selection):
		var sel: Variant = selection.get(&"selected")
		if sel is Array:
			for u in sel:
				var r := rid_of(u)
				if r >= 0:
					(cmd["sel"] as Array).append(r)
		cmd["b"] = rid_of(selection.get(&"selected_building"))
		cmd["fl"] = rid_of(selection.get(&"selected_bounty"))
	if kind == &"select":
		var key := JSON.stringify([cmd["sel"], cmd["b"], cmd["fl"]])
		if key == _last_selection:
			return
		_last_selection = key
	_write(cmd)


func _on_selection_changed(sm: Object) -> void:
	note(&"select", [], sm)


## Script mode (tests, the lab): issue a command as if the player gave it; applied and logged at the start of the
## next physics frame (exactly where a replay applies it). `sel` = the units to select, `building` the building.
func issue(kind: StringName, args: Array = [], sel: Array = [], building: Node = null) -> void:
	var rids := []
	for u in sel:
		var r := rid_of(u)
		if r >= 0:
			rids.append(r)
	_queued.append([kind, args, rids, rid_of(building)])


func _on_bake_finished() -> void:
	if (mode == "record" or mode == "script") and _started and _HOOKS.bake_mode == _HOOKS.BAKE_THREAD:
		_write({"k": "bake", "f": frame})


func _open_out() -> void:
	if out_path == "":
		DirAccess.make_dir_recursive_absolute(REPLAY_DIR)
		var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		out_path = "%s/replay_%s_%d.replay" % [REPLAY_DIR, stamp, match_seed % 10000]
	else:
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	_file = FileAccess.open(out_path, FileAccess.WRITE)
	if _file == null:
		push_warning("Replay: can't write %s" % out_path)


func _write(d: Dictionary) -> void:
	var line := JSON.stringify(d, "", false, true)
	_lines.append(line)
	if _file:
		_file.store_line(line)


## The replay so far (bug reports), as text.
func text() -> String:
	return "\n".join(PackedStringArray(_lines)) + "\n"


func _prune() -> void:
	if not out_path.begins_with(REPLAY_DIR):
		return
	var files := Array(DirAccess.get_files_at(REPLAY_DIR)).filter(func(f: String) -> bool: return f.ends_with(".replay"))
	files.sort()
	while files.size() > MAX_KEPT:
		DirAccess.remove_absolute(REPLAY_DIR + "/" + String(files.pop_front()))


## F8 also works while the game is paused (the session itself pauses with the game, so its frames stop).
class BugKey extends Node:
	var session: Node = null

	func _input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key == null or not key.pressed or key.echo or session == null:
			return
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if code == KEY_F8:
			session.call(&"save_bug_report")


func _add_bug_key() -> void:
	var k := BugKey.new()
	k.name = "BugReportKey"
	k.session = self
	k.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(k)


## F8: the replay so far + the last log lines + settings + a screenshot, zipped under user://bug_reports/.
func save_bug_report() -> String:
	if not ResourceLoader.exists(BUG_REPORT_PATH):
		return ""
	var br := load(BUG_REPORT_PATH) as GDScript
	if br == null:
		return ""
	var path := str(br.call(&"save", get_tree(), self))
	var hud: Variant = level.get(&"hud") if level else null
	if hud is Object and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", "Bug report saved: %s" % ProjectSettings.globalize_path(path) if path != "" \
				else "Bug report failed", 5.0)
	return path


# ---------------------------------------------------------------- playing

func _load_lines(lines: Array) -> void:
	for d: Variant in lines:
		if not d is Dictionary:
			continue
		match String(d.get("k", "")):
			"header":
				_header = d
			"cmd":
				var f := int(d["f"])
				if not _cmds.has(f):
					_cmds[f] = []
				(_cmds[f] as Array).append(d)
			"hash":
				_checks[int(d["f"])] = {"h": d["h"], "s": d.get("s", {})}
			"bake":
				_bakes[int(d["f"])] = int(_bakes.get(int(d["f"]), 0)) + 1
			"end":
				_end = d


## Reads a .replay file into dictionaries (one per line).
static func read_file(path: String) -> Array:
	var out := []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var d: Variant = JSON.parse_string(line)
		if d is Dictionary:
			out.append(d)
	return out


func bake_requested() -> void:
	_bake_requests += 1


func _deferred_bake() -> void:
	var region: Variant = level.get(&"nav_region")
	if region is NavigationRegion3D:
		(region as NavigationRegion3D).bake_navigation_mesh(false)


func _apply(cmd: Dictionary) -> void:
	var sm: Variant = level.get(&"selection")
	var args: Array = decode(cmd.get("a", []))
	_applying = true
	if sm is Object and is_instance_valid(sm):
		_restore_selection(sm, cmd)
	var ok := _execute(StringName(String(cmd.get("c", ""))), args, sm)
	_applying = false
	if not ok:
		push_warning("Replay: frame %d, command %s could not be applied" % [int(cmd.get("f", 0)), cmd.get("c", "")])


func _restore_selection(sm: Object, cmd: Dictionary) -> void:
	var fl := node_of_rid(int(cmd.get("fl", -1)))
	var b := node_of_rid(int(cmd.get("b", -1)))
	if fl != null and sm.has_method(&"select_flag"):
		sm.call(&"select_flag", fl)
		return
	if b != null:
		sm.call(&"select_building", b)
		return
	var units := []
	for r in cmd.get("sel", []):
		var n := node_of_rid(int(r))
		if n != null:
			units.append(n)
	sm.call(&"select_units", units)


## One command, the same way the UI gives it (docs/plan/replay-lab.md "Commands"). False = unknown / impossible.
func _execute(kind: StringName, a: Array, sm: Variant) -> bool:
	var hero: Variant = level.get(&"hero")
	match kind:
		&"select":   # the selection itself was restored by _apply
			return true
		&"formation_move", &"attack_move", &"hold", &"stop", &"gather", &"attack_building", &"build_site", \
				&"trade_with", &"hunt_critter", &"set_market_route", &"pick_up_item", &"train", \
				&"raise_selected_bounty", &"remove_selected_bounty":
			if not sm is Object or not (sm as Object).has_method(kind):
				return false
			(sm as Object).callv(kind, a)
			return true
		&"attack_unit":   # SelectionManager._issue_order / _confirm_attack_move on an enemy or neutral unit
			var target: Variant = a[0] if a.size() > 0 else null
			if target == null or not sm is Object:
				return false
			for u in (sm as Object).call(&"orderable_units"):
				if u.is_in_group(&"caravans") or (u.get(&"unit_type") != null and &"is_caravan" in u.get(&"unit_type")
						and bool(u.get(&"unit_type").get(&"is_caravan"))):
					u.call(&"command_move", (target as Node3D).global_position)
				else:
					u.call(&"command_attack", target)
			return true
		&"place":   # [BuildingType, snapped center]
			var grid: Variant = level.get(&"build_grid")
			if grid == null or a.size() < 2 or not sm is Object:
				return false
			grid.call(&"place", a[0], a[1], 0, (sm as Object).call(&"selected_workers"))
			return true
		&"cancel_site":
			var site: Variant = a[0] if a.size() > 0 else null
			if site is Object and (site as Object).has_method(&"cancel_construction"):
				site.call(&"cancel_construction")
				if sm is Object:
					(sm as Object).call(&"select_units", [])
				return true
			return false
		&"rally":   # [point, crystal node or null]
			var b: Variant = sm.get(&"selected_building") if sm is Object else null
			if b == null:
				return false
			if a.size() > 1 and a[1] != null and b.has_method(&"set_rally_node"):
				b.call(&"set_rally_node", a[1])
			elif b.has_method(&"set_rally_point"):
				b.call(&"set_rally_point", a[0])
			return true
		&"cast":   # [spell id, target]
			if hero == null or not is_instance_valid(hero) or not hero.call(&"is_alive"):
				return false
			if hero.has_method(&"command_cast"):
				hero.call(&"command_cast", a[0], a[1] if a.size() > 1 else null)
			else:
				hero.call(&"command_fireball", a[1])
			return true
		&"caster_cast":   # [spell id, target]: the selected casters' smart-cast (caster-units.md 3.2)
			if not sm is Object or not (sm as Object).has_method(&"cast_caster_at") or a.size() < 2:
				return false
			(sm as Object).call(&"cast_caster_at", a[0], a[1])
			return true
		&"caster_autocast":   # [spell id, on] for the selected casters of that spell
			if not sm is Object or not (sm as Object).has_method(&"selected_casters") or a.size() < 2:
				return false
			for u in (sm as Object).call(&"selected_casters", &""):
				var ab: Variant = (u as Node).get_node_or_null(^"CasterAbility")
				if ab != null and ab.has_method(&"set_autocast"):
					ab.call(&"set_autocast", a[0], a[1])
			return true
		&"learn":
			if hero == null or not is_instance_valid(hero) or not hero.has_method(&"learn_spell"):
				return false
			hero.call(&"learn_spell", a[0])
			return true
		&"use_item":   # [slot, target]
			if hero == null or not is_instance_valid(hero):
				return false
			var inv: Variant = hero.get(&"inventory")
			if inv == null or not inv.has_method(&"use_item"):
				return false
			inv.call(&"use_item", a[0], a[1] if a.size() > 1 else null)
			return true
		&"hero_move":
			if hero == null or not is_instance_valid(hero):
				return false
			hero.call(&"command_move", a[0])
			return true
		&"move_input":
			if hero == null or not is_instance_valid(hero) or not hero.has_method(&"set_move_input"):
				return false
			hero.call(&"set_move_input", a[0])
			return true
		&"call":   # generic: [node, method, args...] (tavern, trade, shop windows)
			if a.size() < 2 or not a[0] is Object or not is_instance_valid(a[0]):
				return false
			(a[0] as Object).callv(StringName(str(a[1])), a.slice(2))
			return true
	return false


# ---------------------------------------------------------------- argument encoding

func encode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_FLOAT, TYPE_STRING:
			return v
		TYPE_INT:
			return {"i": v}
		TYPE_STRING_NAME:
			return {"sn": String(v)}
		TYPE_VECTOR3:
			return {"v3": [v.x, v.y, v.z]}
		TYPE_VECTOR2:
			return {"v2": [v.x, v.y]}
		TYPE_ARRAY:
			var out := []
			for x: Variant in v:
				out.append(encode(x))
			return out
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in v:
				d[str(k)] = encode(v[k])
			return {"d": d}
		TYPE_OBJECT:
			if v == null or not is_instance_valid(v):
				return null
			if v is Resource and (v as Resource).resource_path != "":
				return {"res": (v as Resource).resource_path}
			if v is Node:
				var r := rid_of(v)
				if r >= 0:
					var p := (v as Node3D).global_position if v is Node3D and (v as Node).is_inside_tree() else Vector3.ZERO
					return {"rid": r, "at": [snappedf(p.x, 0.01), snappedf(p.z, 0.01)]}
				if level and (v as Node).is_inside_tree() and level.is_ancestor_of(v):
					return {"np": String(level.get_path_to(v))}
			push_warning("Replay: can't encode %s" % str(v))
			return null
	return v


func decode(v: Variant) -> Variant:
	if v is Array:
		var out := []
		for x: Variant in v:
			out.append(decode(x))
		return out
	if not v is Dictionary:
		return v
	var d: Dictionary = v
	if d.has("i"):
		return int(d["i"])
	if d.has("sn"):
		return StringName(String(d["sn"]))
	if d.has("v3"):
		return Vector3(float(d["v3"][0]), float(d["v3"][1]), float(d["v3"][2]))
	if d.has("v2"):
		return Vector2(float(d["v2"][0]), float(d["v2"][1]))
	if d.has("res"):
		return load(String(d["res"]))
	if d.has("rid"):
		return node_of_rid(int(d["rid"]))
	if d.has("np"):
		return level.get_node_or_null(NodePath(String(d["np"]))) if level else null
	if d.has("d"):
		var out := {}
		for k: Variant in d["d"]:
			out[k] = decode(d["d"][k])
		return out
	return v


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
