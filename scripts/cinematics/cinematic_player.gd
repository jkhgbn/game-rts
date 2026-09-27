class_name CinematicPlayer
extends Node
## Plays a CinematicScript (docs/design/cinematics.md 2-6, 11; prologue-movie-plan.md 2.2-2.5; tools-wave.md 2).
## API + frozen resource fields: scripts/cinematics/README.md.
##
## Determinism: one clock `_t += delta` in `_process` (frozen while paused). Camera, fades, shake and every timed
## action (move / face / despawn / title) are pure functions of `_t` and the action's start state, so `seek(t)` then
## one frame gives the same frame as playing to it, and `--fixed-fps` runs repeat exactly. Creates 0 lights.

signal started(id: StringName)
signal shot_started(index: int, shot_id: StringName)
signal line_shown(line: CinematicLine)
signal line_started(speaker: StringName, text: String)
signal action_fired(action: CinematicAction)
signal finished(id: StringName, skipped: bool)

const GROUP := &"cinematic_player"
const OVERLAY_SCRIPT := "res://scripts/ui/cinematic/cinematic_overlay.gd"
const CAMPAIGN_STATE_SCRIPT := "res://scripts/campaign/campaign_state.gd"
const SKIP_WINDOW := 2.5
const FOLLOW_SMOOTH := 6.0
const EPS := 0.000001
## Timed kinds: their duration comes from `_action_duration`.
const COSMETIC_KINDS: Array[StringName] = [&"vfx", &"sfx", &"anim", &"clip", &"shake"]
## Voice lines (Voice Forge WAVs peak at -1 dBFS; room for the music bed, like cine's preview and VoicePlayer).
const VOICE_DB := -2.0

## Options (set before `play`).
var recording := false
var one_press_skip := false
var use_overlay := true
var emit_events := true
var perf_probe := false
## DOF far blur only when the graphics setting allows it (High).
var dof_allowed := false
## Print "[cine]" start / finish lines (Error Lab reads the log).
var log_enabled := true

var _script: CinematicScript = null
var _context: Node = null
var _playing := false
var _paused := false
var _t := 0.0
var _total := 0.0
var _shots: Array[CinematicShot] = []       # active shots (branch filter applied)
var _shot_src: Array[int] = []              # active index -> index in script.shots
var _starts: Array[float] = []
var _shot_i := -1                           # active index
var _events: Array[Dictionary] = []         # {t, shot, action, order}
var _next_event := 0
var _running: Array[Dictionary] = []
var _lines: Array[Dictionary] = []          # {start, end, line}
var _line_i := -1
var _line_ended := -1
var _fade_events: Array[Dictionary] = []    # {t, color, alpha, time}
var _trauma: Array[Vector2] = []            # (t0, amount)
var _noise_f: Array[float] = []
var _noise_p: Array[float] = []
var _actors: Dictionary = {}                # tag -> Node3D (registered)
var _actor_cache: Dictionary = {}           # tag -> Node3D (resolved for this play)
var _warned: Dictionary = {}
var _snapshot: Dictionary = {}              # Node -> {xform, visible}
var _posed: Dictionary = {}                 # Node3D -> true: moved / teleported / turned by this play (kept over begin_shot)
var _spawned: Array[Node] = []
var _changed_modes: Dictionary = {}         # Node -> old process_mode
var _hud_restore: Array[Dictionary] = []
var _prev_paused := false
var _prev_cam: Camera3D = null
var _game_xform := Transform3D.IDENTITY
var _cam: Camera3D
var _overlay: CanvasLayer = null
var _input_node: CinematicInput
var _music: AudioStreamPlayer
var _music_started_at := -1.0
var _skip_armed := 0.0
var _seen_cache := -1
var _active_set: StringName = &""
var _initial_set: StringName = &""
var _set_for_shot: Array[StringName] = []
var _resolved: Dictionary = {}              # active index -> camera params
var _follow_pos := Vector3.ZERO
var _follow_valid := false
var _seeking := false
var _cam_look := Vector3.ZERO
var _fade_color := Color.BLACK
var _fade_alpha := 0.0
var _fired: Dictionary = {}                 # kind -> count (tools / tests)
var _perf: Dictionary = {}
var _perf_last := 0
var _current_title := ""
var _timed_vfx: Array[Dictionary] = []      # {node, t0, life}: scene vfx with set_cine_age (posed by the clock)
var _firing_t := 0.0


# ------------------------------------------------------------------ static helpers

static func instance(tree: SceneTree) -> CinematicPlayer:
	for n in tree.get_nodes_in_group(GROUP):
		if n is CinematicPlayer and is_instance_valid(n):
			return n as CinematicPlayer
	var p := CinematicPlayer.new()
	tree.root.add_child(p)
	return p


static func is_any_playing(tree: SceneTree) -> bool:
	for n in tree.get_nodes_in_group(GROUP):
		if n is CinematicPlayer and (n as CinematicPlayer).is_playing():
			return true
	return false


func _init() -> void:
	name = "CinematicPlayer"
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	_cam = Camera3D.new()
	_cam.name = "CinematicCamera"
	_cam.near = 0.1
	_cam.far = 250.0
	_cam.attributes = CameraAttributesPractical.new()
	add_child(_cam)
	_input_node = CinematicInput.new()
	_input_node.player = self
	add_child(_input_node)
	_music = AudioStreamPlayer.new()
	_music.name = "CinematicMusic"
	add_child(_music)


# ------------------------------------------------------------------ public API

func play(script: CinematicScript, context: Node = null) -> String:
	if _playing:
		return "Already playing"
	if script == null:
		return "No script"
	if script.kind == CinematicScript.Kind.VIDEO:
		return "VIDEO scripts go to VideoCinematic"
	if script.world_mode == CinematicScript.WorldMode.HOLD:
		return "HOLD mode is not supported yet (tools wave: STAGE and PAUSE only)"
	_script = script
	_context = context
	_build_timeline()
	if _shots.is_empty():
		_script = null
		return "Empty script"
	CinematicInput.ensure_actions()
	_reset_state()
	_playing = true
	_paused = false
	_capture_snapshot()
	var vp := get_viewport()
	_prev_cam = vp.get_camera_3d() if vp else null
	if _prev_cam != null:
		_game_xform = _prev_cam.global_transform
	_cam.make_current()
	_enter_world_mode()
	_set_hud(false)
	if use_overlay:
		_ensure_overlay()
		_overlay.set(&"subtitles_enabled", not recording)
		_overlay.call(&"open", script.letterbox_aspect)
	if script.music_cue != &"":
		_start_music(String(script.music_cue), script.music_volume_db, 0.0, true)
	if log_enabled:
		print("[cine] play %s (%d shots, %.2f s, mode %d)" % [script.id, _shots.size(), _total, script.world_mode])
	started.emit(script.id)
	_emit_event(&"cinematic_started", [script.id])
	_advance_to(0.0)
	_apply_frame(0.0, true)
	return ""


## Jump to the start of the shot `shot_index` (index in `script.shots`; dropped branch shots go to the next one).
func play_from(shot_index: int) -> void:
	if not _playing:
		return
	for i in _shots.size():
		if _shot_src[i] >= shot_index:
			seek(_starts[i])
			return
	seek(_total)


## Jump to any time: restore the start snapshot, apply the end states of every earlier action in timeline order,
## start in-flight ones at their progress (cosmetic kinds are not replayed; `call` only if `on_skip`).
func seek(t: float) -> void:
	if not _playing:
		return
	t = clampf(t, 0.0, _total)
	_restore_snapshot(t)
	_t = t
	_seeking = true
	_advance_to(t)
	_seeking = false
	_sync_line(t, true)
	_follow_valid = false
	_apply_frame(0.0, true)


func skip() -> void:
	if not _playing:
		return
	_seeking = true   # end states only, no cosmetic replays
	for r: Dictionary in _running:
		_end_state(r["action"], r)
	_running.clear()
	while _next_event < _events.size():
		var e: Dictionary = _events[_next_event]
		_next_event += 1
		_end_state(e["action"], {})
	_seeking = false
	_finish(true)


## Ends at once without applying end states (tools abort).
func stop() -> void:
	if _playing:
		_finish(true)


## Skip key: locked before `skip_locked_until`, one press when seen / one_press_skip, else two presses in 2.5 s.
func press_skip() -> void:
	if not _playing or recording or _script == null or not _script.skippable:
		return
	if _t < _script.skip_locked_until:
		return
	if one_press_skip or _is_seen():
		skip()
		return
	if _skip_armed > 0.0:
		skip()
		return
	_skip_armed = SKIP_WINDOW
	if _overlay:
		_overlay.call(&"show_skip_prompt")


func set_paused(on: bool) -> void:
	if not _playing:
		return
	_paused = on
	_music.stream_paused = on
	if _overlay:
		_overlay.call(&"set_paused_view", on)


func is_paused() -> bool:
	return _paused


func is_playing() -> bool:
	return _playing


func current_id() -> StringName:
	return _script.id if _script != null else &""


func current_script() -> CinematicScript:
	return _script


func elapsed() -> float:
	return _t


func total_duration() -> float:
	return _total


## Index of the current shot in `script.shots` (-1 when not playing).
func shot_index() -> int:
	return _shot_src[_shot_i] if _playing and _shot_i >= 0 else -1


## Start time of the shot `shot_index` (index in `script.shots`), -1 if dropped / unknown.
func shot_start(shot_index: int) -> float:
	for i in _shots.size():
		if _shot_src[i] == shot_index:
			return _starts[i]
	return -1.0


## Enter: ends the current subtitle at once (never skips a shot).
func end_line() -> void:
	if not _playing:
		return
	if _line_i >= 0:
		_line_ended = _line_i
	if _overlay:
		_overlay.call(&"end_line")


func register_actor(tag: StringName, node: Node3D) -> void:
	_actors[tag] = node
	_actor_cache.erase(tag)


func actor(tag: StringName) -> Node3D:
	if tag == &"":
		return null
	if _actors.has(tag) and is_instance_valid(_actors[tag]):
		return _actors[tag]
	if _actor_cache.has(tag) and is_instance_valid(_actor_cache[tag]):
		return _actor_cache[tag]
	var n: Node3D = null
	if _context != null and is_instance_valid(_context) and _context.has_method(&"cinematic_actor"):
		n = _context.call(&"cinematic_actor", tag) as Node3D
	if n != null:
		_actor_cache[tag] = n
	elif not _warned.has(tag):
		_warned[tag] = true
		push_warning("[cine] unknown actor \"%s\" in %s" % [tag, current_id()])
	return n


func camera() -> Camera3D:
	return _cam


func overlay() -> CanvasLayer:
	return _overlay


## Probe for tools (headless-safe): see README section 2.
func debug_state() -> Dictionary:
	var line := {}
	if _playing and _line_i >= 0 and _line_i != _line_ended:
		var l: CinematicLine = _lines[_line_i]["line"]
		line = {"speaker": l.speaker, "text": l.text}
	var vis: Array[StringName] = []
	var tags: Array = _actors.keys()
	for k in _actor_cache.keys():
		if not tags.has(k):
			tags.append(k)
	tags.sort()
	for tag: StringName in tags:
		var n := actor(tag)
		if n != null and n.is_inside_tree() and n.is_visible_in_tree():
			vis.append(tag)
	var xf := _cam.global_transform if _cam.is_inside_tree() else _cam.transform
	return {
		"id": current_id(),
		"playing": _playing,
		"paused": _paused,
		"t": _t,
		"total": _total,
		"shot_index": shot_index(),
		"shot_id": _shots[_shot_i].id if _playing and _shot_i >= 0 else &"",
		"camera": {"pos": xf.origin, "look": _cam_look, "basis": xf.basis, "fov": _cam.fov, "xform": xf},
		"active_set": _active_set,
		"visible_actors": vis,
		"line": line,
		"fade_alpha": _fade_alpha,
		"fade_color": _fade_color,
		"skip_prompt": _skip_armed > 0.0,
		"skip_armed": _skip_armed > 0.0,
		"recording": recording,
		"fired": _fired.duplicate(),
		"title": _current_title,
	}


## Perf Lab hook: {shot_id: {frames, avg_ms, max_ms}} of real frame time per shot (needs `perf_probe`).
func perf_samples() -> Dictionary:
	var out := {}
	for k in _perf.keys():
		var p: Dictionary = _perf[k]
		var n := maxi(int(p["frames"]), 1)
		out[k] = {"frames": p["frames"], "avg_ms": float(p["sum"]) / n, "max_ms": p["max"]}
	return out


# ------------------------------------------------------------------ timeline build

func _build_timeline() -> void:
	_shots.clear()
	_shot_src.clear()
	_starts.clear()
	_events.clear()
	_lines.clear()
	_fade_events.clear()
	_trauma.clear()
	_resolved.clear()
	_set_for_shot.clear()
	var t := 0.0
	var order := 0
	var cue_set := _current_set_of_context()
	for i in _script.shots.size():
		var s: CinematicShot = _script.shots[i]
		if s == null or not _branch_ok(s.branch_flag):
			continue
		var ai := _shots.size()
		_shots.append(s)
		_shot_src.append(i)
		_starts.append(t)
		var dur := maxf(s.duration, 0.0)
		if s.shake > 0.0:
			_trauma.append(Vector2(t, s.shake))
		if s.stage_set != &"":
			cue_set = s.stage_set
		var acts: Array[CinematicAction] = []
		acts.append_array(s.actions)
		acts.append_array(set_cues(_find_set(cue_set), s))
		for a: CinematicAction in acts:
			if a == null:
				continue
			var te := t + clampf(a.at, 0.0, dur)
			_events.append({"t": te, "shot": ai, "action": a, "order": order})
			order += 1
			if a.kind == &"fade":
				_fade_events.append({"t": te, "color": _param_color(a.params, &"color", Color.BLACK),
						"alpha": float(a.params.get("alpha", 1.0)), "time": maxf(float(a.params.get("time", 0.5)), 0.0)})
			elif a.kind == &"shake":
				_trauma.append(Vector2(te, float(a.params.get("amount", 0.5))))
		for l: CinematicLine in s.lines:
			if l == null:
				continue
			var ls := t + clampf(l.at, 0.0, dur)
			var le := ls + l.effective_duration() if _script.lines_over_cuts else minf(ls + l.effective_duration(), t + dur)
			if le > ls:
				_lines.append({"start": ls, "end": le, "line": l})
		t += dur
	_total = t
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["t"] < b["t"] or (a["t"] == b["t"] and a["order"] < b["order"]))
	_lines.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["start"] < b["start"])
	if _script.lines_over_cuts:
		# cine rule: a line runs on over cuts until the next line starts (and the cinematic ends)
		for li in _lines.size():
			var nxt: float = _lines[li + 1]["start"] if li + 1 < _lines.size() else _total
			_lines[li]["end"] = minf(float(_lines[li]["end"]), minf(nxt, _total))
	var rng := RandomNumberGenerator.new()
	rng.seed = _script.shake_seed
	_noise_f.clear()
	_noise_p.clear()
	for k in 6:
		_noise_f.append(rng.randf_range(9.0, 17.0))
		_noise_p.append(rng.randf_range(0.0, TAU))


func _reset_state() -> void:
	_t = 0.0
	_shot_i = -1
	_next_event = 0
	_running.clear()
	_line_i = -1
	_line_ended = -1
	_actor_cache.clear()
	_warned.clear()
	_snapshot.clear()
	_posed.clear()
	_spawned.clear()
	_timed_vfx.clear()
	_changed_modes.clear()
	_hud_restore.clear()
	_skip_armed = 0.0
	_seen_cache = -1
	_follow_valid = false
	_fade_alpha = 0.0
	_fired.clear()
	_perf.clear()
	_perf_last = 0
	_current_title = ""
	_music_started_at = -1.0
	_initial_set = _current_set_of_context()
	_active_set = _initial_set
	var cur := _initial_set
	for s: CinematicShot in _shots:
		if s.stage_set != &"":
			cur = s.stage_set
		_set_for_shot.append(cur)


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	if not _playing:
		return
	if _skip_armed > 0.0:
		_skip_armed = maxf(_skip_armed - delta, 0.0)
	if _paused:
		return
	if perf_probe:
		_perf_sample()
	_t += delta
	_advance_to(_t)
	_update_timed_vfx()
	_sync_line(_t, false)
	_apply_frame(delta, false)
	if _t >= _total - EPS:
		_finish(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _playing and not recording \
			and DisplayServer.get_name() != "headless":
		set_paused(true)


## Crosses shot starts and action times up to `t` in time order (shots first on ties).
func _advance_to(t: float) -> void:
	var target_shot := _shot_at(t)
	while true:
		var ns := _shot_i + 1
		var next_shot_t := _starts[ns] if ns < _shots.size() and ns <= target_shot else INF
		var next_ev_t: float = _events[_next_event]["t"] if _next_event < _events.size() else INF
		if next_ev_t > t + EPS:
			next_ev_t = INF
		if next_shot_t == INF and next_ev_t == INF:
			break
		if next_shot_t <= next_ev_t:
			_enter_shot(ns, _seeking and ns < target_shot)
		else:
			var e: Dictionary = _events[_next_event]
			_next_event += 1
			_fire(e, t)
	_update_running(t)


func _shot_at(t: float) -> int:
	var idx := 0
	for i in _shots.size():
		if _starts[i] <= t + EPS:
			idx = i
	return idx


func _enter_shot(i: int, passing: bool) -> void:
	var prev := _shot_i
	_shot_i = i
	var s := _shots[i]
	if prev >= 0:
		_set_call(_set_for_shot[prev], &"end_shot", [_shots[prev].id])
	if _set_for_shot[i] != _active_set:
		_switch_set(_set_for_shot[i])
	_follow_valid = false
	if passing:
		return
	# A set's begin_shot may reset its puppets to their start pose (World Forge sets do). Actors this cinematic has
	# already moved / turned keep their pose (the timeline's end states carry over cuts, in play and after a seek).
	var keep := {}
	for n in _posed.keys():
		if is_instance_valid(n) and (n as Node3D).is_inside_tree():
			keep[n] = (n as Node3D).global_transform
	_set_call(_set_for_shot[i], &"begin_shot", [s.id])
	for n2: Node3D in keep:
		if n2.global_transform != keep[n2]:
			n2.global_transform = keep[n2]
			n2.reset_physics_interpolation()
	shot_started.emit(_shot_src[i], s.id)


func _apply_frame(delta: float, snap: bool) -> void:
	if _shot_i < 0:
		return
	var st := _camera_state(_t, delta, snap)
	_cam.global_transform = st["xform"]
	_cam.fov = st["fov"]
	_cam_look = st["look"]
	var s := _shots[_shot_i]
	var attr := _cam.attributes as CameraAttributesPractical
	if attr:
		attr.dof_blur_far_enabled = dof_allowed and s.dof_far > 0.0
		if s.dof_far > 0.0:
			attr.dof_blur_far_distance = s.dof_far
	_compute_fade(_t)
	if _overlay:
		_overlay.call(&"set_fade", _fade_color, _fade_alpha)


# ------------------------------------------------------------------ camera

func _camera_state(t: float, delta: float, snap: bool) -> Dictionary:
	var i := _shot_i
	var s := _shots[i]
	var dur := maxf(s.duration, EPS)
	var lt := clampf(t - _starts[i], 0.0, dur)
	var r := _resolve(i)
	var trans := s.trans_type
	if s.camera_mode == CinematicShot.CameraMode.CRANE and trans == Tween.TRANS_SINE:
		trans = Tween.TRANS_CUBIC
	var k := float(Tween.interpolate_value(0.0, 1.0, lt, dur, trans, s.ease_type)) if s.duration > 0.0 else 1.0
	var look_default: Vector3 = (r["look_from"] as Vector3).lerp(r["look_to"], k)
	var pos := Vector3.ZERO
	var look := look_default
	match s.camera_mode:
		CinematicShot.CameraMode.STATIC:
			pos = r["from"]
			look = r["look_from"]
		CinematicShot.CameraMode.DOLLY, CinematicShot.CameraMode.CRANE:
			pos = (r["from"] as Vector3).lerp(r["to"], k)
		CinematicShot.CameraMode.ORBIT:
			var pv: Vector3 = r["pivot"]
			var pa: Node3D = actor(s.pivot_actor) if s.pivot_actor != &"" else null
			if pa != null:
				pv = pa.global_position
			var a := deg_to_rad(lerpf(r["a0"], r["a1"], k))
			var rad := lerpf(r["r0"], r["r1"], k)
			pos = pv + Vector3(cos(a) * rad, lerpf(r["h0"], r["h1"], k), sin(a) * rad)
			look = pv + s.look_offset
		CinematicShot.CameraMode.RAIL:
			var path := r.get("rail") as Path3D
			if path != null and is_instance_valid(path) and path.curve != null and path.curve.get_baked_length() > 0.0:
				pos = path.global_transform * path.curve.sample_baked(k * path.curve.get_baked_length())
			else:
				pos = (r["from"] as Vector3).lerp(r["to"], k)
		CinematicShot.CameraMode.FOLLOW:
			var fa := actor(s.follow_actor)
			if fa != null:
				var want := fa.global_transform * s.follow_offset
				if snap or not _follow_valid:
					_follow_pos = want
					_follow_valid = true
				else:
					_follow_pos = _follow_pos.lerp(want, clampf(FOLLOW_SMOOTH * delta, 0.0, 1.0))
				pos = _follow_pos
				look = fa.global_position + s.look_offset
			else:
				pos = r["from"]
	if s.look_actor != &"":
		var la := actor(s.look_actor)
		if la != null:
			look = la.global_position + s.look_offset
	var xf := _look_xform(pos, look, s.roll_deg)
	# shake (pure function of t)
	var tr := _trauma_at(t)
	if tr > 0.0:
		var q := tr * tr
		xf.origin += Vector3(_noise(t, 0), _noise(t, 1), _noise(t, 2)) * 0.25 * q
		xf.basis = xf.basis * Basis.from_euler(Vector3(_noise(t, 3) * 0.03, _noise(t, 4) * 0.03, _noise(t, 5) * 0.04) * q)
	# blends with the game camera
	if s.transition_in == CinematicShot.Transition.BLEND_FROM_GAME and s.transition_time > 0.0 and lt < s.transition_time:
		var bk := float(Tween.interpolate_value(0.0, 1.0, lt, s.transition_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
		xf = _game_xform.interpolate_with(xf, bk)
	if s.blend_to_game and s.transition_time > 0.0 and lt > dur - s.transition_time:
		var gx := _prev_cam.global_transform if _prev_cam != null and is_instance_valid(_prev_cam) and _prev_cam.is_inside_tree() else _game_xform
		var gk := (lt - (dur - s.transition_time)) / s.transition_time
		xf = xf.interpolate_with(gx, clampf(gk, 0.0, 1.0))
	return {"xform": xf, "fov": lerpf(r["fov_from"], r["fov_to"], k), "look": look}


static func _look_xform(pos: Vector3, look: Vector3, roll_deg: float) -> Transform3D:
	var dir := look - pos
	var xf := Transform3D(Basis.IDENTITY, pos)
	if dir.length_squared() > 0.000001:
		var up := Vector3.UP
		if absf(dir.normalized().dot(up)) > 0.999:
			up = Vector3.FORWARD
		xf = xf.looking_at(look, up)
	if roll_deg != 0.0:
		xf.basis = xf.basis * Basis(Vector3(0, 0, 1), deg_to_rad(roll_deg))
	return xf


func _trauma_at(t: float) -> float:
	var sum := 0.0
	for v: Vector2 in _trauma:
		if v.x <= t + EPS:
			sum += maxf(0.0, v.y - (t - v.x))
	return clampf(sum, 0.0, 1.0)


func _noise(t: float, i: int) -> float:
	return sin(t * _noise_f[i] + _noise_p[i]) * 0.6 + sin(t * _noise_f[i] * 2.3 + _noise_p[i] * 1.7) * 0.4


## Camera params of an active shot, markers / marks.json applied (cached).
func _resolve(i: int) -> Dictionary:
	if _resolved.has(i):
		return _resolved[i]
	var s := _shots[i]
	var r := {"from": s.from_pos, "to": s.to_pos, "look_from": s.look_from, "look_to": s.look_to,
			"fov_from": s.fov_from, "fov_to": s.fov_to, "pivot": s.pivot, "r0": s.orbit_radius, "r1": s.orbit_radius,
			"h0": s.orbit_height, "h1": s.orbit_height, "a0": s.orbit_from_deg, "a1": s.orbit_to_deg, "rail": null}
	if s.rail != NodePath(""):
		r["rail"] = _node_at(s.rail) as Path3D
	if s.marker_prefix != &"":
		var m := {}
		if _context != null and is_instance_valid(_context) and _context.has_method(&"markers_for"):
			m = _context.call(&"markers_for", s.marker_prefix, _set_for_shot[i])
		else:
			m = read_markers(_find_set(_set_for_shot[i]), s.marker_prefix)
		for key in ["from", "to", "look_from", "look_to", "fov_from", "fov_to", "rail"]:
			if m.has(key) and m[key] != null:
				r[key] = m[key]
		if m.has("pivot"):
			var pv: Vector3 = m["pivot"]
			r["pivot"] = pv
			var f: Vector3 = r["from"]
			var g: Vector3 = r["to"]
			r["r0"] = Vector2(f.x - pv.x, f.z - pv.z).length()
			r["r1"] = Vector2(g.x - pv.x, g.z - pv.z).length()
			r["h0"] = f.y - pv.y
			r["h1"] = g.y - pv.y
			r["a0"] = rad_to_deg(atan2(f.z - pv.z, f.x - pv.x))
			r["a1"] = rad_to_deg(atan2(g.z - pv.z, g.x - pv.x))
	_resolved[i] = r
	return r


## Reads the set contract markers (`Shots/<prefix>_from` ...) or `<set folder>/marks.json`. Keys: from, to,
## look_from, look_to, fov_from, fov_to, pivot, rail (Path3D). Missing keys are absent.
static func read_markers(set_root: Node, prefix: StringName) -> Dictionary:
	var out := {}
	if set_root == null:
		return out
	var shots := set_root.get_node_or_null(^"Shots")
	var base := shots if shots != null else set_root
	var p := String(prefix)
	var f := base.get_node_or_null(NodePath(p + "_from")) as Node3D
	if f != null:
		out["from"] = f.global_position
		out["to"] = f.global_position
		if f.has_meta(&"fov"):
			out["fov_from"] = float(f.get_meta(&"fov"))
			out["fov_to"] = out["fov_from"]
		var to := base.get_node_or_null(NodePath(p + "_to")) as Node3D
		if to != null:
			out["to"] = to.global_position
			if to.has_meta(&"fov"):
				out["fov_to"] = float(to.get_meta(&"fov"))
		var lf := base.get_node_or_null(NodePath(p + "_look_from")) as Node3D
		if lf != null:
			out["look_from"] = lf.global_position
			out["look_to"] = lf.global_position
		var lt := base.get_node_or_null(NodePath(p + "_look_to")) as Node3D
		if lt != null:
			out["look_to"] = lt.global_position
		var pv := base.get_node_or_null(NodePath(p + "_pivot")) as Node3D
		if pv != null:
			out["pivot"] = pv.global_position
		var rail := base.get_node_or_null(NodePath(p + "_rail")) as Path3D
		if rail != null:
			out["rail"] = rail
		return out
	var rail2 := base.get_node_or_null(NodePath(p + "_rail")) as Path3D
	if rail2 != null:
		out["rail"] = rail2
	var scene_path := set_root.scene_file_path
	if scene_path == "":
		return out
	var json_path := scene_path.get_base_dir().path_join("marks.json")
	if not FileAccess.file_exists(json_path):
		return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not data is Dictionary or not (data as Dictionary).has(p):
		return out
	var d: Dictionary = data[p]
	var xf := (set_root as Node3D).global_transform if set_root is Node3D and set_root.is_inside_tree() else Transform3D.IDENTITY
	for key in ["from", "to", "look_from", "look_to", "pivot"]:
		if d.has(key) and d[key] is Array and (d[key] as Array).size() >= 3:
			var a: Array = d[key]
			out[key] = xf * Vector3(float(a[0]), float(a[1]), float(a[2]))
	for key in ["fov_from", "fov_to"]:
		if d.has(key):
			out[key] = float(d[key])
	if out.has("from") and not out.has("to"):
		out["to"] = out["from"]
	if out.has("look_from") and not out.has("look_to"):
		out["look_to"] = out["look_from"]
	return out


# ------------------------------------------------------------------ fades

func _compute_fade(t: float) -> void:
	# shot transitions
	var ta := 0.0
	var tc := Color.BLACK
	for i in _shots.size():
		var s := _shots[i]
		if s.transition_in != CinematicShot.Transition.FADE_BLACK and s.transition_in != CinematicShot.Transition.FADE_WHITE:
			continue
		var half := maxf(s.transition_time * 0.5, EPS)
		var d := t - _starts[i]
		var a := 0.0
		if i == 0:
			a = 1.0 - clampf(d / half, 0.0, 1.0) if d >= 0.0 else 1.0
		else:
			a = 1.0 - clampf(absf(d) / half, 0.0, 1.0)
		if a > ta:
			ta = a
			tc = Color.WHITE if s.transition_in == CinematicShot.Transition.FADE_WHITE else Color.BLACK
	# fade actions (piecewise: each goes from the previous value to its alpha over its time)
	var fa := 0.0
	var fc := Color.BLACK
	for e: Dictionary in _fade_events:
		var te: float = e["t"]
		if te > t + EPS:
			break
		fc = e["color"]
		var time: float = e["time"]
		if time <= 0.0 or t >= te + time:
			fa = e["alpha"]
		else:
			fa = lerpf(fa, e["alpha"], (t - te) / time)
	if fa >= ta:
		_fade_alpha = fa
		_fade_color = fc
	else:
		_fade_alpha = ta
		_fade_color = tc


# ------------------------------------------------------------------ lines

func _sync_line(t: float, force_show: bool) -> void:
	var idx := -1
	for i in _lines.size():
		var L: Dictionary = _lines[i]
		if float(L["start"]) <= t + EPS and t < float(L["end"]) - EPS:
			idx = i
	if idx == _line_i:
		return
	_line_i = idx
	if idx < 0:
		if _overlay:
			_overlay.call(&"end_line")
		return
	var L2: Dictionary = _lines[idx]
	var line: CinematicLine = L2["line"]
	if _overlay:
		var who := &"" if _script.voice_over.has(line.speaker) else line.speaker
		_overlay.call(&"show_line", who, line.text, float(L2["end"]) - t)
	if force_show:
		return
	if line.voice != "" and ResourceLoader.exists(line.voice):
		_play_sfx(line.voice, VOICE_DB)
	line_shown.emit(line)
	line_started.emit(line.speaker, line.text)


# ------------------------------------------------------------------ actions

func _fire(e: Dictionary, now: float) -> void:
	var a: CinematicAction = e["action"]
	var te: float = e["t"]
	_firing_t = te
	if _seeking and COSMETIC_KINDS.has(a.kind):
		return
	var n: Node3D = actor(a.actor) if a.actor != &"" else null
	if n != null and a.kind in [&"move", &"teleport", &"face"]:
		_posed[n] = true
	var r := {"action": a, "t": te, "node": n}
	match a.kind:
		&"move":
			if n == null:
				return
			var path: Path3D = _node_at(a.params["path"]) as Path3D if a.params.has("path") else null
			r["from"] = n.global_position
			r["path"] = path
			var speed := maxf(float(a.params.get("speed", 2.0)), 0.01)
			var dist := n.global_position.distance_to(a.target)
			if path != null and path.curve != null:
				dist = path.curve.get_baked_length()
			r["dur"] = dist / speed
			_mark_animate(n, a)
			if not _seeking:
				_hook(n, &"set_moving", [speed])
		&"face":
			if n == null:
				return
			r["yaw0"] = n.global_rotation.y
			r["yaw1"] = _face_yaw(n, a)
			r["dur"] = maxf(float(a.params.get("time", 0.3)), 0.0)
		&"despawn":
			r["dur"] = maxf(float(a.params.get("fade", 0.5)), 0.0)
		&"title":
			r["dur"] = maxf(float(a.params.get("time", 3.0)), 0.0)
			var remain: float = r["dur"] - (now - te)
			if remain > 0.0 and _overlay:
				_overlay.call(&"show_title", String(a.params.get("text", "")), String(a.params.get("sub", "")), remain)
				_current_title = String(a.params.get("text", ""))
		&"music":
			_start_music(String(a.params.get("path", a.params.get("cue", ""))), float(a.params.get("volume_db", 0.0)),
					now - te)
			_count(a)
			if not _seeking:
				action_fired.emit(a)
			return
		&"call":
			if _seeking and not a.on_skip:
				return
			_do_call(a)
			_count(a)
			if not _seeking:
				action_fired.emit(a)
			return
		&"vfx":
			_do_vfx(a, n)
		&"sfx":
			_play_sfx(String(a.params.get("path", "")), float(a.params.get("volume_db", 0.0)))
		&"anim":
			if n != null:
				_mark_animate(n, a)
				var hook := StringName(a.params.get("hook", ""))
				if hook != &"":
					_hook(n, hook, [a.params["arg"]] if a.params.has("arg") else [])
		&"clip":
			if n != null:
				_mark_animate(n, a)
				_hook(n, &"play_clip", [StringName(a.params.get("id", ""))])
		&"shake", &"fade":
			pass   # pure functions of t (_trauma_at / _compute_fade)
		_:
			_end_state(a, r)   # instant kinds: teleport, spawn, dormant, visible, set_shot
	_count(a)
	if not _seeking:
		action_fired.emit(a)
	if r.has("dur") and float(r["dur"]) > 0.0 and now < te + float(r["dur"]):
		_running.append(r)
	elif r.has("dur"):
		_end_state(a, r)


func _update_running(t: float) -> void:
	for i in range(_running.size() - 1, -1, -1):
		var r: Dictionary = _running[i]
		var a: CinematicAction = r["action"]
		var dur: float = r["dur"]
		var k := clampf((t - float(r["t"])) / dur, 0.0, 1.0)
		if k >= 1.0:
			_running.remove_at(i)
			_end_state(a, r)
			continue
		var n := r["node"] as Node3D
		match a.kind:
			&"move":
				if n != null and is_instance_valid(n):
					var from: Vector3 = r["from"]
					var pos := from.lerp(a.target, k)
					var path := r.get("path") as Path3D
					if path != null and is_instance_valid(path) and path.curve != null:
						pos = path.global_transform * path.curve.sample_baked(k * path.curve.get_baked_length())
					var dir := a.target - from
					n.global_position = pos
					if Vector2(dir.x, dir.z).length() > 0.01:
						_set_yaw(n, atan2(dir.x, dir.z))
			&"face":
				if n != null and is_instance_valid(n):
					_set_yaw(n, lerp_angle(float(r["yaw0"]), float(r["yaw1"]), k))


## End state of an action (skip, seek, normal end). `r` may carry start state (move `from`).
func _end_state(a: CinematicAction, r: Dictionary) -> void:
	var n: Node3D = null
	if r.has("node"):
		n = r["node"]
	elif a.actor != &"":
		n = actor(a.actor)
	if n != null and not is_instance_valid(n):
		n = null
	match a.kind:
		&"move":
			if n == null:
				return
			var from: Vector3 = r.get("from", n.global_position)
			n.global_position = a.target
			var dir := a.target - from
			if Vector2(dir.x, dir.z).length() > 0.01:
				_set_yaw(n, atan2(dir.x, dir.z))
			_hook(n, &"set_moving", [0.0])
			n.reset_physics_interpolation()
		&"teleport":
			if n == null:
				return
			n.global_position = a.target
			if a.params.has("yaw_deg"):
				_set_yaw(n, deg_to_rad(float(a.params["yaw_deg"])))
			n.reset_physics_interpolation()
		&"face":
			if n != null:
				_set_yaw(n, float(r["yaw1"]) if r.has("yaw1") else _face_yaw(n, a))
		&"spawn":
			_do_spawn(a)
		&"despawn":
			if n != null:
				n.visible = false
		&"dormant":
			var on := bool(a.params.get("on", true))
			if _context != null and is_instance_valid(_context) and _context.has_method(&"cinematic_dormant"):
				_context.call(&"cinematic_dormant", n, on)
			elif n != null and n.has_method(&"set_dormant"):
				n.call(&"set_dormant", on)
		&"visible":
			var target: Node = n
			if a.params.has("node"):
				target = _node_at(a.params["node"])
			if target != null and "visible" in target:
				_remember(target)
				target.set(&"visible", bool(a.params.get("on", true)))
		&"call":
			if r.is_empty() and a.on_skip:
				_do_call(a)   # skip: never fired yet
		&"title":
			if _overlay:
				_overlay.call(&"hide_title")
			_current_title = ""
		&"set_shot":
			_switch_set(StringName(a.params.get("set", "")))
		_:
			pass   # vfx / sfx / anim / clip / shake / fade / music: nothing (music stops at the end)


func _face_yaw(n: Node3D, a: CinematicAction) -> float:
	if a.params.has("yaw_deg"):
		return deg_to_rad(float(a.params["yaw_deg"]))
	var other: Node3D = actor(StringName(a.params["look_actor"])) if a.params.has("look_actor") else null
	var to := other.global_position if other != null else a.target
	var d := to - n.global_position
	if Vector2(d.x, d.z).length() < 0.001:
		return n.global_rotation.y
	return atan2(d.x, d.z)


static func _set_yaw(n: Node3D, yaw: float) -> void:
	var sc := n.global_basis.get_scale()
	n.global_basis = Basis(Vector3.UP, yaw).scaled_local(sc)


func _hook(n: Node, method: StringName, args: Array) -> bool:
	if n == null:
		return false
	if n.has_method(method):
		n.callv(method, args)
		return true
	var m: Variant = n.call(&"get_model") if n.has_method(&"get_model") else n.get_node_or_null(^"Model")
	if m is Node and (m as Node).has_method(method):
		(m as Node).callv(method, args)
		return true
	return false


func _do_call(a: CinematicAction) -> void:
	var method := StringName(a.params.get("method", ""))
	if method == &"" or _context == null or not is_instance_valid(_context):
		return
	if not _context.has_method(method):
		push_warning("[cine] call: context has no method \"%s\"" % method)
		return
	var args: Array = a.params.get("args", [])
	_context.callv(method, args)


func _do_vfx(a: CinematicAction, n: Node3D) -> void:
	var vid := StringName(a.params.get("vfx_id", ""))
	if vid != &"":
		var hubs := get_tree().get_nodes_in_group(&"composer_vfx")
		if not hubs.is_empty() and hubs[0].has_method(&"play"):
			hubs[0].call(&"play", vid, a.target, n)
			return
		if n != null and n.has_method(&"cast"):
			n.call(&"cast", vid, a.target, float(a.params.get("travel_time", 0.6)))
			return
		push_warning("[cine] vfx \"%s\": no composer hub and no CastProxy actor" % vid)
		return
	var scene_path := String(a.params.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return
	var inst := ps.instantiate()
	var parent := _spawn_parent()
	var life := float(a.params.get("life", 3.0))
	if inst is Node3D:
		# placed before it enters the tree (cine fx read their position / scale in _ready), like cine's preview
		var n3 := inst as Node3D
		n3.position = (parent as Node3D).to_local(a.target) if parent is Node3D and (parent as Node3D).is_inside_tree() else a.target
		if a.params.has("yaw"):
			n3.rotation.y = deg_to_rad(float(a.params["yaw"]))
		if a.params.has("scale"):
			n3.scale = Vector3.ONE * float(a.params["scale"])
		if a.params.has("to") and n3.has_method(&"set_cine_target"):
			n3.call(&"set_cine_target", a.params["to"])
	parent.add_child(inst)
	if _script.world_mode == CinematicScript.WorldMode.PAUSE:
		inst.process_mode = Node.PROCESS_MODE_ALWAYS
	if inst.has_method(&"set_cine_age"):
		# time-driven effect (art/cinematics/fx): posed from the cinematic clock every frame, freed after `life`
		_timed_vfx.append({"node": inst, "t0": _t0_of(a), "life": life})
		inst.call(&"set_cine_age", _t - _t0_of(a))
		return
	get_tree().create_timer(life, true).timeout.connect(func() -> void:
		if is_instance_valid(inst):
			inst.queue_free())


## Start time on the cinematic clock of the action being fired (set by `_fire`).
func _t0_of(_a: CinematicAction) -> float:
	return _firing_t


func _update_timed_vfx() -> void:
	for i in range(_timed_vfx.size() - 1, -1, -1):
		var v: Dictionary = _timed_vfx[i]
		var n: Node = v["node"]
		if not is_instance_valid(n):
			_timed_vfx.remove_at(i)
			continue
		var age := _t - float(v["t0"])
		if age > float(v["life"]):
			n.queue_free()
			_timed_vfx.remove_at(i)
		else:
			n.call(&"set_cine_age", age)


func _clear_timed_vfx() -> void:
	for v: Dictionary in _timed_vfx:
		if is_instance_valid(v["node"]):
			(v["node"] as Node).queue_free()
	_timed_vfx.clear()


func _do_spawn(a: CinematicAction) -> void:
	var tag := StringName(a.params.get("tag", a.actor))
	var node: Node3D = null
	if _context != null and is_instance_valid(_context) and _context.has_method(&"cinematic_spawn"):
		node = _context.call(&"cinematic_spawn", tag, a.params) as Node3D
	else:
		var sp := String(a.params.get("scene", ""))
		if sp != "" and ResourceLoader.exists(sp):
			var ps := load(sp) as PackedScene
			if ps != null:
				node = ps.instantiate() as Node3D
				if node != null:
					_spawn_parent().add_child(node)
	if node == null:
		push_warning("[cine] spawn \"%s\": nothing to spawn" % tag)
		return
	node.global_position = a.target
	if a.params.has("yaw_deg"):
		_set_yaw(node, deg_to_rad(float(a.params["yaw_deg"])))
	_spawned.append(node)
	if tag != &"":
		register_actor(tag, node)


func _spawn_parent() -> Node:
	if _context != null and is_instance_valid(_context) and _context.is_inside_tree():
		return _context
	return self


func _mark_animate(n: Node, a: CinematicAction) -> void:
	if _script.world_mode != CinematicScript.WorldMode.PAUSE or not bool(a.params.get("animate", false)):
		return
	if not _changed_modes.has(n):
		_changed_modes[n] = n.process_mode
		n.process_mode = Node.PROCESS_MODE_ALWAYS


func _count(a: CinematicAction) -> void:
	_fired[a.kind] = int(_fired.get(a.kind, 0)) + 1


func _param_color(p: Dictionary, key: StringName, def: Color) -> Color:
	var v: Variant = p.get(String(key), p.get(key, def))
	if v is Color:
		return v
	if v is String:
		return Color.from_string(v, def)
	return def


func _node_at(path: Variant) -> Node:
	var np := NodePath(str(path)) if not path is NodePath else path as NodePath
	if np.is_empty():
		return null
	if np.is_absolute():
		return get_node_or_null(np)
	if _context != null and is_instance_valid(_context) and _context.is_inside_tree():
		return _context.get_node_or_null(np)
	return null


# ------------------------------------------------------------------ audio

func _bus(names: Array) -> StringName:
	for b: String in names:
		if AudioServer.get_bus_index(b) >= 0:
			return StringName(b)
	return &"Master"


func _start_music(path: String, volume_db: float, from: float, loop: bool = false) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var st := load(path) as AudioStream
	if st == null:
		return
	var length := st.get_length()
	if loop and st is AudioStreamWAV and length > 0.0 and length < _total:
		# a bed shorter than the cinematic loops (cine's preview does the same); a copy, the cached one is untouched
		var w := (st as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(length * w.mix_rate)
		st = w
		from = fmod(maxf(from, 0.0), length)
	_music.stream = st
	_music.volume_db = volume_db
	_music.bus = _bus(["Cinematic", "Music"])
	if DisplayServer.get_name() != "headless":
		_music.play(maxf(from, 0.0))
	_music_started_at = _t


func _play_sfx(path: String, volume_db: float) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var st := load(path) as AudioStream
	if st == null or DisplayServer.get_name() == "headless":
		return
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = volume_db
	p.bus = _bus(["SFX", "Cinematic"])
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ------------------------------------------------------------------ snapshot / seek

func _capture_snapshot() -> void:
	var tags := {}
	for s: CinematicShot in _shots:
		for tag: StringName in [s.look_actor, s.pivot_actor, s.follow_actor]:
			if tag != &"":
				tags[tag] = true
		for a: CinematicAction in s.actions:
			if a != null and a.actor != &"" and a.kind != &"spawn":
				tags[a.actor] = true
	for s: CinematicShot in _shots:
		for a: CinematicAction in s.actions:
			if a != null and a.kind == &"spawn":
				tags.erase(StringName(a.params.get("tag", a.actor)))
	for tag: StringName in tags.keys():
		var n := actor(tag)
		if n != null:
			_remember(n)
	for s: CinematicShot in _shots:
		for a: CinematicAction in s.actions:
			if a != null and a.kind == &"visible" and a.params.has("node"):
				var vn := _node_at(a.params["node"])
				if vn != null:
					_remember(vn)


func _remember(n: Node) -> void:
	if _snapshot.has(n):
		return
	var d := {"visible": n.get(&"visible")}
	if n is Node3D and (n as Node3D).is_inside_tree():
		d["xform"] = (n as Node3D).global_transform
	_snapshot[n] = d


func _restore_snapshot(t: float) -> void:
	for n: Node in _spawned:
		if is_instance_valid(n):
			for tag in _actors.keys():
				if _actors[tag] == n:
					_actors.erase(tag)
			n.queue_free()
			if n.get_parent():
				n.get_parent().remove_child(n)
	_spawned.clear()
	_posed.clear()
	_clear_timed_vfx()
	for n in _snapshot.keys():
		if not is_instance_valid(n):
			continue
		var d: Dictionary = _snapshot[n]
		if d.has("xform") and (n as Node3D).is_inside_tree():
			(n as Node3D).global_transform = d["xform"]
			(n as Node3D).reset_physics_interpolation()
		if d["visible"] != null:
			n.set(&"visible", d["visible"])
	_running.clear()
	_next_event = 0
	_shot_i = -1
	_line_i = -1
	_line_ended = -1
	_current_title = ""
	if _overlay:
		_overlay.call(&"end_line")
		_overlay.call(&"hide_title")
	_music.stop()
	if _script.music_cue != &"":
		_start_music(String(_script.music_cue), _script.music_volume_db, t, true)
	if _active_set != _initial_set:
		_switch_set(_initial_set)


# ------------------------------------------------------------------ sets

func _current_set_of_context() -> StringName:
	if _context != null and is_instance_valid(_context) and _context.has_method(&"active_set_id"):
		return StringName(_context.call(&"active_set_id"))
	return &""


func _find_set(id: StringName) -> Node:
	if id == &"":
		return null
	if _context != null and is_instance_valid(_context) and _context.has_method(&"find_set"):
		return _context.call(&"find_set", id)
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group(&"cinematic_sets"):
		if StringName(str(n.get(&"set_id"))) == id:
			return n
	return null


func _switch_set(id: StringName) -> void:
	_active_set = id
	if id == &"":
		return
	if _context != null and is_instance_valid(_context) and _context.has_method(&"set_active_set"):
		_context.call(&"set_active_set", id)
		return
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"cinematic_sets"):
		var on := StringName(str(n.get(&"set_id"))) == id
		if n.has_method(&"set_active"):
			n.call(&"set_active", on)
		elif n is Node3D:
			(n as Node3D).visible = on


## Set cue API: a set may define `cine_cues(shot_id: StringName) -> Array` of cue Dictionaries so it can fire its own
## spell VFX / sfx / anims during its shots (today's .cine-only cues). A cue = `{at, kind, actor, target, params}` like
## a CinematicAction (kind default `vfx`; only the cosmetic kinds vfx / sfx / anim / clip / shake), `target` / `to` in
## the set root's local space; shortcut keys `scene`, `vfx_id`, `life`, `scale`, `yaw`, `to`, `hook`, `arg`, `path`,
## `volume_db`, `amount`, `travel_time` go to params. A shot that already carries baked set cues (params `from_set`,
## written by `cine build`) is not merged again. Returns [] when the set has no cues.
static func set_cues(set_node: Node, shot: CinematicShot) -> Array[CinematicAction]:
	var out: Array[CinematicAction] = []
	if set_node == null or shot == null or not set_node.has_method(&"cine_cues"):
		return out
	for a0: CinematicAction in shot.actions:
		if a0 != null and bool(a0.params.get("from_set", false)):
			return out
	var cues: Variant = set_node.call(&"cine_cues", shot.id)
	if not cues is Array:
		return out
	var xf := (set_node as Node3D).global_transform if set_node is Node3D and (set_node as Node3D).is_inside_tree() else Transform3D.IDENTITY
	for c: Variant in cues:
		var a := cue_action(c, xf)
		if a != null:
			out.append(a)
	return out


## One set cue Dictionary -> CinematicAction (null when not a cosmetic cue). `xf` = the set root's transform.
static func cue_action(c: Variant, xf: Transform3D = Transform3D.IDENTITY) -> CinematicAction:
	if not c is Dictionary:
		return null
	var d: Dictionary = c
	var kind := StringName(str(d.get("kind", "vfx")))
	if not COSMETIC_KINDS.has(kind):
		return null
	var params: Dictionary = (d.get("params", {}) as Dictionary).duplicate() if d.get("params") is Dictionary else {}
	for k: String in ["scene", "vfx_id", "life", "scale", "yaw", "hook", "arg", "path", "volume_db", "amount", "travel_time"]:
		if d.has(k):
			params[k] = d[k]
	if d.get("to") is Vector3:
		params["to"] = xf * (d["to"] as Vector3)
	params["from_set"] = true
	var target: Vector3 = d["target"] if d.get("target") is Vector3 else Vector3.ZERO
	return CinematicAction.make(float(d.get("at", 0.0)), kind, StringName(str(d.get("actor", ""))), xf * target, params)


## Fires one cue now (a set's own script may call it mid-shot, e.g. from begin_shot or a timer): cosmetic only, not
## part of the timeline (seek / stills do not see it; prefer `cine_cues` for anything the camera must frame).
func fire_cue(cue: Dictionary, set_node: Node3D = null) -> void:
	if not _playing:
		return
	var a := cue_action(cue, set_node.global_transform if set_node != null and set_node.is_inside_tree() else Transform3D.IDENTITY)
	if a != null:
		_fire({"t": _t, "shot": _shot_i, "action": a, "order": -1}, _t)


func _set_call(id: StringName, method: StringName, args: Array) -> void:
	var s := _find_set(id)
	if s != null and s.has_method(method):
		s.callv(method, args)


# ------------------------------------------------------------------ world mode, HUD, end

func _enter_world_mode() -> void:
	if _script.world_mode == CinematicScript.WorldMode.PAUSE:
		_prev_paused = get_tree().paused
		get_tree().paused = true


func _leave_world_mode() -> void:
	for n in _changed_modes.keys():
		if is_instance_valid(n):
			(n as Node).process_mode = _changed_modes[n]
	_changed_modes.clear()
	if _script.world_mode == CinematicScript.WorldMode.PAUSE:
		get_tree().paused = _prev_paused


func _set_hud(on: bool) -> void:
	if not is_inside_tree():
		return
	if not on:
		_hud_restore.clear()
		var scene := get_tree().current_scene
		if scene != null:
			for key: StringName in [&"hud", &"mission_hud"]:
				var h: Variant = scene.get(key)
				if h is Node and is_instance_valid(h):
					if (h as Node).has_method(&"set_cinematic_mode"):
						(h as Node).call(&"set_cinematic_mode", true)
						_hud_restore.append({"node": h, "method": true})
					elif "visible" in h:
						_hud_restore.append({"node": h, "visible": (h as Node).get(&"visible")})
						(h as Node).set(&"visible", false)
		for w in get_tree().get_nodes_in_group(&"heroes"):
			if w.has_method(&"set_move_input"):
				w.call(&"set_move_input", Vector3.ZERO)
	else:
		for d: Dictionary in _hud_restore:
			var h: Variant = d["node"]
			if not is_instance_valid(h):
				continue
			if d.has("method"):
				(h as Node).call(&"set_cinematic_mode", false)
			else:
				(h as Node).set(&"visible", d["visible"])
		_hud_restore.clear()


func _finish(skipped: bool) -> void:
	if not _playing:
		return
	var id := _script.id
	_music.stop()
	_clear_timed_vfx()
	_leave_world_mode()
	if _overlay:
		_overlay.call(&"close")
	_skip_armed = 0.0
	if _prev_cam != null and is_instance_valid(_prev_cam) and _prev_cam.is_inside_tree():
		_prev_cam.make_current()
		if _script.world_mode != CinematicScript.WorldMode.STAGE:
			_focus_game_camera()
	else:
		_cam.clear_current(false)
	_set_hud(true)
	_playing = false
	_paused = false
	if log_enabled:
		print("[cine] finished %s skipped=%s t=%.3f" % [id, skipped, _t])
	finished.emit(id, skipped)
	_emit_event(&"cinematic_finished", [id, skipped])


func _focus_game_camera() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var rig: Variant = scene.get(&"camera_rig")
	if not (rig is Node and (rig as Node).has_method(&"focus_on")):
		return
	var at := _script.return_focus
	if not at.is_finite():
		var hero: Variant = scene.get(&"hero")
		if hero is Node3D and is_instance_valid(hero):
			at = (hero as Node3D).global_position
		else:
			return
	(rig as Node).call(&"focus_on", at)


func _emit_event(sig: StringName, args: Array) -> void:
	if not emit_events or not is_inside_tree():
		return
	var ev := get_node_or_null(^"/root/Events")
	if ev != null and ev.has_signal(sig):
		ev.callv(&"emit_signal", [sig] + args)


func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	var sc := load(OVERLAY_SCRIPT) as GDScript
	if sc == null:
		return
	_overlay = sc.new() as CanvasLayer
	add_child(_overlay)


func _is_seen() -> bool:
	if _seen_cache >= 0:
		return _seen_cache == 1
	_seen_cache = 0
	if _context != null and is_instance_valid(_context) and _context.has_method(&"cinematic_seen"):
		_seen_cache = 1 if bool(_context.call(&"cinematic_seen", _script.id)) else 0
		return _seen_cache == 1
	var st: Object = _campaign_state()
	if st != null and st.has_method(&"is_seen"):
		_seen_cache = 1 if bool(st.call(&"is_seen", _script.id)) else 0
	return _seen_cache == 1


func _branch_ok(flag: String) -> bool:
	if flag == "":
		return true
	var neg := flag.begins_with("!")
	var name_ := flag.substr(1) if neg else flag
	var value := false
	if _context != null and is_instance_valid(_context) and _context.has_method(&"cinematic_flag"):
		value = bool(_context.call(&"cinematic_flag", name_))
	else:
		var st: Object = _campaign_state()
		if st != null and st.has_method(&"flag"):
			value = bool(st.call(&"flag", name_))
	return value != neg


func _campaign_state() -> Object:
	if not ResourceLoader.exists(CAMPAIGN_STATE_SCRIPT):
		return null
	var sc: Variant = load(CAMPAIGN_STATE_SCRIPT)
	if sc == null:
		return null
	for m: Dictionary in (sc as Script).get_script_method_list():
		if m["name"] == "open":
			return (sc as Object).call(&"open") as Object
	return null


func _perf_sample() -> void:
	var now := Time.get_ticks_usec()
	if _perf_last > 0 and _shot_i >= 0:
		var ms := float(now - _perf_last) / 1000.0
		var key := String(_shots[_shot_i].id) if _shots[_shot_i].id != &"" else str(_shot_src[_shot_i])
		var p: Dictionary = _perf.get(key, {"frames": 0, "sum": 0.0, "max": 0.0})
		p["frames"] = int(p["frames"]) + 1
		p["sum"] = float(p["sum"]) + ms
		p["max"] = maxf(float(p["max"]), ms)
		_perf[key] = p
	_perf_last = now
