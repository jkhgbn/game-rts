extends Node
## Playtest Recorder (docs/design/health-and-playtests.md, part B). OFF by default: GameSettings "Playtest data"
## (Settings > "Help improve the game: record my playtest to a local file") sets ReplayHooks.playtest_enabled, and
## ReplayHooks.match_started then attaches one recorder under the level (skirmish + missions; another mode calls
## ReplayHooks.start_playtest(level, "wave_strike")). Nothing runs and nothing is written while the setting is off.
##
## Writes a compact JSON-lines timeline to user://playtests/<date>_<mode>[_n].jsonl, one object per line, key "k":
##   header  {v, game (commit), date (day only), mode, mission, map, map_size, kingdoms, controls, sample_every, retry}
##   s       state sample every `sample_every` s of game time: t, cr (crystals), inc (crystals gathered / min), wk
##           (workers), pop / cap, army {type id: supply}, tier, bld {type id: n}, cam [x, z], hero hp ratio (-1 dead),
##           units, the enemy's cr / inc / wk / army supply / tier (bot), keys / clicks since the last sample, frame
##           ms p50 / p95 / p99 / max over the window
##   ev      events: e = cmd (player command from ReplayHooks.note: c kind, p [x, z], id), death (team, type, p, hero,
##           kt killer team), built, tier, objective (id, state), mission_event (id), hero_fell, idle (dur s),
##           pause (dur s), hitch (ms, units, cam, t)
##   replay  {file} the Replay Lab recording of the same match, when one is being recorded (user://replays/...)
##   end     {outcome win / loss / left, reason, t, rage_quit, paused_s, idle_s, keys, clicks, hitches, ms p50/p95/p99}
## No personal data: no names, paths outside user://, OS user or hardware ids. The file is flushed at each sample.
## Cost (measured by tests/test_playtest_recorder.gd): one ring-buffer write per frame + a sample every 5 s.

const _HOOKS := preload("res://scripts/core/replay/replay_hooks.gd")
const FORMAT_VERSION := 1
const DIR := "user://playtests"
const HITCH_MS := 50.0
const IDLE_S := 15.0
const MAX_HITCH_EVENTS := 300
const MAX_CMD_EVENTS := 20000
const RING := 512
const RAGE_WINDOW_S := 60.0
const PLAYER := 0
const ENEMY := 1

## Matches recorded per mode in this game session (a retry = the same mode again: F9, "Try again").
static var _runs_by_mode := {}

var level: Node = null
var mode := ""
var out_path := ""
var sample_every := 5.0
var lines_written := 0

var _file: FileAccess = null
var _opts := {}
var _t_own := 0.0
var _next_sample := 0.0
var _last_us := 0
var _ring := PackedFloat32Array()
var _ring_n := 0
var _hist := PackedInt32Array()   # whole-match frame ms histogram, 1 ms buckets 0-199 (+ last = 200+)
var _hitches := 0
var _keys := 0
var _clicks := 0
var _keys_win := 0
var _clicks_win := 0
var _last_input_s := 0.0
var _idle_s := 0.0
var _paused_s := 0.0
var _pause_started := -1.0
var _cmds := 0
var _outcome := ""
var _reason := ""
var _last_hero_death := -1000.0
var _recent_deaths: Array[float] = []
var _replay_linked := false
var _prev_gathered := {PLAYER: 0, ENEMY: 0}
var _prev_sample_t := 0.0
var _ended := false
var _frames := 0


## Options: mode, out (path), sample_every (s).
func configure(p_level: Node, options: Dictionary) -> void:
	level = p_level
	_opts = options
	sample_every = maxf(0.25, float(options.get("sample_every", 5.0)))
	mode = String(options.get("mode", ""))
	out_path = String(options.get("out", ""))


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000


func _ready() -> void:
	if mode == "":
		mode = mode_of(level)
	_runs_by_mode[mode] = int(_runs_by_mode.get(mode, 0)) + 1
	_ring.resize(RING)
	_hist.resize(201)
	_last_us = Time.get_ticks_usec()
	_open()
	_write({"k": "header", "v": FORMAT_VERSION, "game": _game_version(), "date": Time.get_date_string_from_system(),
			"mode": mode, "mission": _str(level.get(&"mission_id")), "map": _map_id(), "map_size": _map_size(),
			"kingdoms": [_str(level.get(&"player_kingdom")), _str(level.get(&"enemy_kingdom"))],
			"controls": _controls(), "sample_every": sample_every, "retry": int(_runs_by_mode[mode]) - 1})
	_HOOKS.listener = self
	_connect_signals()
	_next_sample = 0.0


func _exit_tree() -> void:
	if not _ended:
		_finish("left", "exit" if not get_tree() or not get_tree().paused else "menu")
	if _HOOKS.listener == self:
		_HOOKS.listener = null


## "mission_<id>" / "wave_strike" / "skirmish" / the level's name.
static func mode_of(lvl: Node) -> String:
	if lvl == null:
		return "unknown"
	var mid: Variant = lvl.get(&"mission_id")
	if mid != null and String(mid) != "":
		return "mission_" + String(mid)
	if lvl.has_method(&"bastion_ratio") or lvl.get(&"lane_spawner") != null:
		return "wave_strike"
	if lvl.has_method(&"match_time"):
		return "skirmish"
	return String(lvl.name).to_snake_case()


# --- per frame ----------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var ms := (now - _last_us) / 1000.0
	_last_us = now
	if _ended:
		return
	if get_tree().paused:
		if _pause_started < 0.0:
			_pause_started = _wall_s()
		return
	if _pause_started >= 0.0:
		var d := _wall_s() - _pause_started
		_paused_s += d
		if d >= 1.0:
			ev({"e": "pause", "dur": snappedf(d, 0.1)})
		_pause_started = -1.0
		_last_input_s = _wall_s()
	_t_own += delta
	_frames += 1
	if _frames <= 2:   # the first frames carry the level load / attach time
		return
	_ring[_ring_n % RING] = ms
	_ring_n += 1
	_hist[mini(int(ms), 200)] += 1
	if ms > HITCH_MS:
		_hitch(ms)
	if game_time() >= _next_sample:
		_next_sample = game_time() + sample_every
		sample()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		_keys += 1
		_keys_win += 1
	elif event is InputEventMouseButton:
		if not event.pressed or event.button_index > MOUSE_BUTTON_MIDDLE:
			return
		_clicks += 1
		_clicks_win += 1
	else:
		return
	var w := _wall_s()
	if not get_tree().paused and w - _last_input_s >= IDLE_S and _last_input_s > 0.0:
		var d := w - _last_input_s
		_idle_s += d
		ev({"e": "idle", "dur": snappedf(d, 0.1)})
	_last_input_s = w


func _wall_s() -> float:
	return Time.get_ticks_msec() / 1000.0


## Match / mission time (held time excluded in missions), else the recorder's own unpaused time.
func game_time() -> float:
	if level != null and is_instance_valid(level):
		if level.has_method(&"mission_time"):
			return float(level.call(&"mission_time"))
		if level.has_method(&"match_time"):
			return float(level.call(&"match_time"))
		var t: Variant = level.get(&"time")
		if t is float:
			return t
	return _t_own


# --- events -------------------------------------------------------------------------------------------------------

func ev(d: Dictionary) -> void:
	if _ended:
		return
	d["k"] = "ev"
	if not d.has("t"):
		d["t"] = snappedf(game_time(), 0.1)
	_write(d)


## ReplayHooks.note forwards every player command here.
func on_command(kind: StringName, args: Array) -> void:
	if kind == &"move_input" or kind == &"select" or _cmds >= MAX_CMD_EVENTS:
		return
	_cmds += 1
	var d := {"e": "cmd", "c": String(kind)}
	for a in args:
		if a is Vector3 and not d.has("p"):
			d["p"] = _xz(a)
		elif a is Node3D and not d.has("p") and is_instance_valid(a):
			d["p"] = _xz((a as Node3D).global_position)
		elif a is Resource and not d.has("id"):
			var rid: Variant = (a as Resource).get(&"id")
			if rid != null:
				d["id"] = String(rid)
		elif (a is StringName or a is String) and not d.has("id"):
			d["id"] = String(a)
	ev(d)


func _connect_signals() -> void:
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.connect(&"unit_died", _on_unit_died)
		events.connect(&"building_completed", func(b: Node) -> void:
			if b is Node3D and int(b.get(&"team")) == PLAYER:
				ev({"e": "built", "id": _type_id(b), "p": _xz((b as Node3D).global_position)}))
		events.connect(&"objective_changed", func(id: StringName, state: StringName) -> void:
			ev({"e": "objective", "id": String(id), "state": String(state)}))
		events.connect(&"mission_ended", func(victory: bool) -> void:
			_set_outcome("win" if victory else "loss", "mission"))
	if level.has_signal(&"match_ended"):
		level.connect(&"match_ended", func(winner: int) -> void:
			_set_outcome("win" if winner == PLAYER else "loss", "match"))
	if level.has_signal(&"event_fired"):
		level.connect(&"event_fired", func(id: StringName) -> void: ev({"e": "mission_event", "id": String(id)}))
	for ts in get_tree().get_nodes_in_group(&"tier_systems"):
		if ts.has_signal(&"tier_changed"):
			ts.connect(&"tier_changed", func(team: int, tier: int) -> void:
				ev({"e": "tier", "team": team, "tier": tier}))


func _on_unit_died(u: Node) -> void:
	if not (u is Node3D) or not is_instance_valid(u):
		return
	var team := int(u.get(&"team"))
	var hero := u.is_in_group(&"heroes")
	var d := {"e": "death", "team": team, "type": _type_id(u), "p": _xz((u as Node3D).global_position)}
	var k: Variant = u.get(&"killer")
	if k is Node and is_instance_valid(k) and k.get(&"team") != null:
		d["kt"] = int(k.get(&"team"))
	if hero:
		d["hero"] = true
	ev(d)
	if team == PLAYER:
		var t := game_time()
		_recent_deaths.append(t)
		if hero:
			_last_hero_death = t
			ev({"e": "hero_fell", "p": d["p"]})


func _hitch(ms: float) -> void:
	_hitches += 1
	if _hitches > MAX_HITCH_EVENTS:
		return
	ev({"e": "hitch", "ms": snappedf(ms, 0.1), "units": get_tree().get_node_count_in_group(&"units"), "cam": _cam()})


func _set_outcome(outcome: String, reason: String) -> void:
	if _outcome != "":
		return
	_outcome = outcome
	_reason = reason
	sample()
	_finish(outcome, reason)


# --- samples ------------------------------------------------------------------------------------------------------

func sample() -> void:
	if _ended or level == null or not is_instance_valid(level):
		return
	if not _replay_linked:
		_link_replay()
	var t := game_time()
	var dt := maxf(t - _prev_sample_t, 0.001)
	var s := {"k": "s", "t": snappedf(t, 0.1)}
	var army := {}
	var wk := [0, 0]
	var esup := 0
	var units := 0
	var hero_hp := -1.0
	for u in get_tree().get_nodes_in_group(&"units"):
		units += 1
		var team: Variant = u.get(&"team")
		if team == null or not u.has_method(&"is_alive") or not u.call(&"is_alive"):
			continue
		var ti := int(team)
		if ti != PLAYER and ti != ENEMY:
			continue
		var ut: Variant = u.get(&"unit_type")
		if u.has_method(&"command_gather"):
			wk[ti] += 1
			continue
		if u.is_in_group(&"heroes"):
			if ti == PLAYER and hero_hp < 0.0:
				var mhp := float(u.get(&"max_hp")) if u.get(&"max_hp") != null else 0.0
				hero_hp = snappedf(float(u.get(&"hp")) / mhp, 0.01) if mhp > 0.0 and u.get(&"hp") != null else 1.0
			continue
		var pop := int(ut.get(&"pop")) if ut is Resource and ut.get(&"pop") != null else 1
		if ti == PLAYER:
			var id := String(ut.get(&"id")) if ut is Resource else "other"
			army[id] = int(army.get(id, 0)) + pop
		else:
			esup += pop
	var bld := {}
	for b in get_tree().get_nodes_in_group(&"buildings"):
		if b.get(&"team") != null and int(b.get(&"team")) == PLAYER:
			var id := _type_id(b)
			bld[id] = int(bld.get(id, 0)) + 1
	for team in [PLAYER, ENEMY]:
		var eco := _economy(team)
		var pre := "" if team == PLAYER else "e_"
		if eco != null:
			s[pre + "cr"] = int(eco.get(&"crystals"))
			var g := int(eco.get(&"gathered_total")) if eco.get(&"gathered_total") != null else 0
			s[pre + "inc"] = roundi((g - int(_prev_gathered[team])) * 60.0 / dt) if t > 0.0 else 0
			_prev_gathered[team] = g
			if team == PLAYER:
				s["pop"] = int(eco.get(&"pop_used"))
				s["cap"] = int(eco.get(&"pop_cap"))
		s[pre + "wk"] = wk[team]
		s[pre + "tier"] = _tier(team)
	s["army"] = army
	s["e_army"] = esup
	s["bld"] = bld
	s["cam"] = _cam()
	s["hero"] = hero_hp
	s["units"] = units
	s["keys"] = _keys_win
	s["clicks"] = _clicks_win
	_keys_win = 0
	_clicks_win = 0
	var n := mini(_ring_n, RING)
	if n > 0:
		var w := _ring.slice(0, n)
		w.sort()
		s["ms"] = [snappedf(w[n / 2], 0.1), snappedf(w[mini(n - 1, int(n * 0.95))], 0.1),
				snappedf(w[mini(n - 1, int(n * 0.99))], 0.1), snappedf(w[n - 1], 0.1)]
	_ring_n = 0
	_prev_sample_t = t
	while not _recent_deaths.is_empty() and t - _recent_deaths[0] > 30.0:
		_recent_deaths.pop_front()
	_write(s)
	if _file:
		_file.flush()


func _finish(outcome: String, reason: String) -> void:
	if _ended:
		return
	var t := game_time()
	var rage := outcome == "left" and (t - _last_hero_death <= RAGE_WINDOW_S or _recent_deaths.size() >= 5)
	_write({"k": "end", "outcome": outcome, "reason": reason, "t": snappedf(t, 0.1), "rage_quit": rage,
			"paused_s": snappedf(_paused_s, 0.1), "idle_s": snappedf(_idle_s, 0.1), "keys": _keys, "clicks": _clicks,
			"hitches": _hitches, "cmds": _cmds, "ms": [_hist_pct(0.5), _hist_pct(0.95), _hist_pct(0.99)]})
	_ended = true
	if _file:
		_file.close()
		_file = null
	if _HOOKS.listener == self:
		_HOOKS.listener = null


func _hist_pct(q: float) -> int:
	var total := 0
	for c in _hist:
		total += c
	if total == 0:
		return 0
	var want := int(ceil(total * q))
	var acc := 0
	for i in _hist.size():
		acc += _hist[i]
		if acc >= want:
			return i
	return 200


# --- helpers ------------------------------------------------------------------------------------------------------

func _open() -> void:
	if out_path == "":
		DirAccess.make_dir_recursive_absolute(DIR)
		var base := "%s/%s_%s" % [DIR, Time.get_date_string_from_system(), mode]
		out_path = base + ".jsonl"
		var i := 2
		while FileAccess.file_exists(out_path):
			out_path = "%s_%d.jsonl" % [base, i]
			i += 1
	else:
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	_file = FileAccess.open(out_path, FileAccess.WRITE)
	if _file == null:
		push_warning("Playtest: can't write %s" % out_path)
	else:
		print("Playtest recorder: recording to %s" % out_path)


func _write(d: Dictionary) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify(d, "", false))
	lines_written += 1


func _link_replay() -> void:
	_replay_linked = true
	var s: Object = _HOOKS.session
	if s != null and is_instance_valid(s) and String(s.get(&"mode")) == "record":
		var p := String(s.get(&"out_path"))
		if p.begins_with("user://"):
			_write({"k": "replay", "file": p, "seed": int(s.get(&"match_seed"))})


func _economy(team: int) -> Object:
	for e in get_tree().get_nodes_in_group(&"economies"):
		if int(e.get(&"team")) == team:
			return e
	return null


func _tier(team: int) -> int:
	for ts in get_tree().get_nodes_in_group(&"tier_systems"):
		if ts.has_method(&"tier_of"):
			return int(ts.call(&"tier_of", team))
	return 0


func _cam() -> Array:
	var rig: Variant = level.get(&"camera_rig") if level != null and is_instance_valid(level) else null
	if rig is Node3D and is_instance_valid(rig):
		return _xz((rig as Node3D).global_position)
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	return _xz(cam.global_position) if cam else [0, 0]


static func _xz(p: Vector3) -> Array:
	return [snappedf(p.x, 0.1), snappedf(p.z, 0.1)]


static func _type_id(n: Object) -> String:
	for f in [&"unit_type", &"building_type"]:
		var t: Variant = n.get(f)
		if t is Resource and t.get(&"id") != null:
			return String(t.get(&"id"))
	if n.is_in_group(&"heroes"):
		return "wizard"
	return String((n as Node).name).to_snake_case() if n is Node else "?"


static func _str(v: Variant) -> String:
	return "" if v == null else String(v)


func _map_id() -> String:
	var lay: Variant = level.get(&"layout")
	if lay is Resource and lay.get(&"id") != null:
		return String(lay.get(&"id"))
	return String(MapInfo.map_id)


func _map_size() -> Array:
	return [MapInfo.size_x, MapInfo.size_z]


func _controls() -> String:
	var gs := _gs_script()
	if gs == null:
		return ""
	var ids: Variant = gs.get(&"CONTROL_SCHEME_IDS")
	var c: Variant = gs.get(&"control_scheme")
	return String(ids[int(c)]) if ids is Array and c != null and int(c) < (ids as Array).size() else ""


static func _gs_script() -> Script:
	const P := "res://scripts/ui/menus/game_settings.gd"
	return load(P) as Script if ResourceLoader.exists(P) else null


static func _game_version() -> String:
	var s := load("res://scripts/core/replay/replay_session.gd")
	return String(s.call(&"game_version")) if s != null else ""
