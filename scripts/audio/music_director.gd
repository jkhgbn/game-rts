class_name MusicDirector
extends Node
## The game's music (docs/design/music.md 4 + 5, tasks MU13 / MU14). One node, a child of /root made by `ensure(tree)`,
## so it survives scene changes (F9 restart keeps the track playing). GameAudio, the main menu, the pause menu and
## the scene watcher below call it; it never edits gameplay code.
## Contexts (`set_music_context`): menu (theme_main), campaign (campaign_map), chant (ep8 screens), match (pool: the 4
## kingdom themes + field, own kingdom x2, the others x1; first track = own), wave_strike (wave_strike x2, the 4 themes
## + field x1, first = wave_strike), boss (boss), none. A new random seed per context start (`pool_seed` for tests).
## Pool tracks play once, then a 8-20 s gap (skipped when combat intensity >= 0.3: 2 s cross-fade), never the same
## track twice in a row; after 4:00 calm a match picks `tavern` (once per 10 min). Match end (`play_sting`, also on
## Events.mission_ended): fade 1 s, sting, 3 s silence, then theme_main at -6 dB.
## Combat intensity (fed by GameAudio every 0.5 s): rise 1.5 s, hold 8 s, fall over 12 s; the kingdom's drive stem
## (`<id>_drive.wav`, started on the same frame as the track) is off below 0.15, on from 0.3, -18 dB at 0.3 -> 0 dB at 0.75.
## Files: MUSIC_DIR <id>.wav (stereo 22 050 Hz), loaded by path at runtime; any missing file falls back to the old
## music_match / music_menu loops (missing too = silence), never an error.

signal track_changed(id: StringName)

const MUSIC_DIR := "res://assets/audio/music/"
const MUSIC_DB := -10.0                 ## Same level as the old GameAudio music player.
const CONTEXT_XFADE := 3.0
const TRACK_XFADE := 2.0
const TRACK_TAIL := 0.25                ## Fade at a pool track's end before its gap (no click when it wraps).
const GAP_MIN := 8.0
const GAP_MAX := 20.0
const GAP_SKIP_INTENSITY := 0.3
const END_FADE := 1.0
const END_SILENCE := 3.0
const END_DB := -6.0                    ## theme_main on the end screen.
const PAUSE_DB := -6.0                  ## Pause menu: the level's music, quieter (no switch).
const CTX_DB_RATE := 6.0                ## dB per second when the context volume changes (end screen -> menu).
const TAVERN_CALM_S := 240.0
const TAVERN_CALM_BELOW := 0.1
const TAVERN_EVERY_S := 600.0
const RISE_S := 1.5
const HOLD_S := 8.0
const FALL_S := 12.0
const FEED_TIMEOUT := 2.0               ## No intensity feed for this long (menus) = 0.
const DRIVE_ON := 0.3
const DRIVE_OFF := 0.15
const DRIVE_LOW_DB := -18.0
const DRIVE_FULL_AT := 0.75
const DRIVE_SLEW_DB := 60.0             ## dB per second.
const SILENT_DB := -80.0
const FALLBACK_MATCH := &"music_match"
const FALLBACK_MENU := &"music_menu"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHANT_SCREENS: Array[StringName] = [&"ep8_choice", &"ep8_credits"]
const LOOP_CONTEXTS := {&"menu": &"theme_main", &"campaign": &"campaign_map", &"chant": &"chant", &"boss": &"boss"}
## The 4 kingdom themes (every match / Wave Strike pool holds all of them, JS 2026-10-14).
const KINGDOM_THEMES: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]
const CINE_SCRIPT := "res://scripts/cinematics/cinematic_player.gd"
const CINE_POLL := 0.25                 ## How often an in-mission film (CinematicPlayer.is_any_playing) is checked.
const FILM_FADE_OUT := 1.0
const FILM_FADE_IN := 2.0
const POOL_CONTEXTS: Array[StringName] = [&"match", &"wave_strike"]
const MATCH_FALLBACK_CONTEXTS: Array[StringName] = [&"match", &"wave_strike", &"boss"]


## One playing track: the main player and its drive stem, started together.
class Slot:
	extends RefCounted
	var main: AudioStreamPlayer
	var drive: AudioStreamPlayer
	var id: StringName = &""
	var fade := 0.0
	var fade_to := 0.0
	var fade_rate := 1.0
	var length := 0.0
	var time := 0.0
	var loops := true
	var ctx_db := 0.0     # context level (END_DB on the end screen), moves toward _ctx_db_to while current


var pool_seed := -1     ## >= 0: the pool order seed of the next context start (tests / replays); -1 = random.

static var _inst: MusicDirector = null

var _slots: Array[Slot] = []
var _cur := 0
var _sting: AudioStreamPlayer
var _context: StringName = &""
var _kingdom: StringName = &""
var _enemy: StringName = &""
var _override: Array[StringName] = []
var _pending := false               # a context was asked before the node entered the tree
var _phase: StringName = &"idle"    # idle, play, gap, end_fade, sting, end_silence
var _phase_left := 0.0
var _sting_id: StringName = &""
var _last_pick: StringName = &""
var _rng := RandomNumberGenerator.new()
var _streams: Dictionary = {}       # id -> AudioStream (looped copy)
var _ctx_db_to := 0.0
var _duck_db := 0.0
var _raw := 0.0
var _raw_age := 999.0
var _intensity := 0.0
var _hold_left := 0.0
var _drive_on := false
var _drive_db := SILENT_DB
var _clock := 0.0
var _calm := 0.0
var _last_tavern_at := -1.0e9
var _match_kingdom: StringName = &""   # the last match / wave_strike kingdoms (boss / briefing hand back to them)
var _match_enemy: StringName = &""
var _briefing_id := 0                  # BriefingScreen holding the campaign music (0 = none)
var _cine_script: GDScript = null      # scripts/cinematics/cinematic_player.gd, load-guarded
var _cine_checked := false
var _cine_left := 0.0
var _film_on := false                  # an in-mission film (CinematicPlayer) plays: the music is held silent
var _film_fade := 1.0                  # 0-1, multiplies every track's level


## The director (made on first use, a child of /root named "MusicDirector"). Calls made before it enters the tree
## (it is added deferred) are applied in its _ready.
static func ensure(tree: SceneTree) -> MusicDirector:
	if is_instance_valid(_inst) and not _inst.is_queued_for_deletion():
		return _inst
	if tree == null:
		return null
	var found := tree.root.get_node_or_null(^"MusicDirector") as MusicDirector
	if found != null:
		_inst = found
		return _inst
	_inst = MusicDirector.new()
	_inst.name = "MusicDirector"
	tree.root.add_child.call_deferred(_inst)
	return _inst


## Every music player (main + drive of both slots, the sting) back on the Music bus.
func _assign_buses() -> void:
	for s in _slots:
		s.main.bus = &"Music"
		s.drive.bus = &"Music"
	_sting.bus = &"Music"


## The buses of every music player (tests: all &"Music").
func player_buses() -> Array[StringName]:
	var out: Array[StringName] = []
	for s in _slots:
		out.append(s.main.bus)
		out.append(s.drive.bus)
	out.append(_sting.bus)
	return out


## True when `<id>.wav` exists under MUSIC_DIR.
static func has_track(id: StringName) -> bool:
	return id != &"" and ResourceLoader.exists(MUSIC_DIR + String(id) + ".wav")


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The Music bus must exist before a player is told to use it: a missing bus reads back as Master (and plays
	# there, so the Music slider would do nothing). GameSettings makes the buses; _ready sets them again.
	GameSettings.ensure_buses()
	_rng.randomize()
	for i in 2:
		var s := Slot.new()
		var main := AudioStreamPlayer.new()
		main.bus = &"Music"
		var drive := AudioStreamPlayer.new()
		drive.bus = &"Music"
		s.main = main
		s.drive = drive
		add_child(main)
		add_child(drive)
		_slots.append(s)
	_sting = AudioStreamPlayer.new()
	_sting.bus = &"Music"
	add_child(_sting)


func _ready() -> void:
	GameSettings.ensure_buses()
	_assign_buses()
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"mission_ended"):
		events.connect(&"mission_ended", _on_mission_ended)
	get_tree().node_added.connect(_on_node_added)
	if _pending:
		_pending = false
		_start_context(CONTEXT_XFADE)


func _process(delta: float) -> void:
	_clock += delta
	if _briefing_id != 0 and not _briefing_active():
		release_briefing()
	_cine_left -= delta
	if _cine_left <= 0.0:
		_cine_left = CINE_POLL
		_set_film(_film_playing())
	_film_fade = move_toward(_film_fade, 0.0 if _film_on else 1.0, delta / (FILM_FADE_OUT if _film_on else FILM_FADE_IN))
	var held := _film_on and _film_fade <= 0.0
	for s in _slots:
		if s.id != &"":
			s.main.stream_paused = held
			s.drive.stream_paused = held
	_update_intensity(delta)
	if not held:
		for s in _slots:
			if s.id != &"":
				s.time += delta
		_update_phase(delta)
	_update_volumes(delta)


# ---------------------------------------------------------------- public API

## Switches the music context (see the header). `kingdom` / `enemy_kingdom` pick the match pool (empty on `match` =
## the last match's kingdoms, so a boss can hand back). The same context + kingdoms = nothing happens (F9 keeps the
## track). Entering a non-match context clears a `set_track_pool` override.
func set_music_context(context: StringName, kingdom := &"", enemy_kingdom := &"") -> void:
	if context == &"match" and kingdom == &"":
		kingdom = _match_kingdom
		enemy_kingdom = _match_enemy
	if context == _context and kingdom == _kingdom and enemy_kingdom == _enemy:
		return
	if context == &"menu" or context == &"none":
		_override.clear()   # out of the level; boss / campaign (briefing) / chant keep it for the way back
	if context in POOL_CONTEXTS and kingdom != &"":
		_match_kingdom = kingdom
		_match_enemy = enemy_kingdom
	_context = context
	_kingdom = kingdom
	_enemy = enemy_kingdom
	_duck_db = 0.0
	if pool_seed >= 0:
		_rng.seed = pool_seed
	else:
		_rng.randomize()
	if not is_inside_tree():
		_pending = true
		return
	_start_context(CONTEXT_XFADE)


## The context running now (&"" before the first call; &"end" during / after a match-end sting).
func music_context() -> StringName:
	return _context


## The raw combat intensity 0-1 (GameAudio, every 0.5 s); the director smooths it (rise / hold / fall).
func set_combat_intensity(v: float) -> void:
	_raw = clampf(v, 0.0, 1.0)
	_raw_age = 0.0


## The smoothed combat intensity 0-1.
func combat_intensity() -> float:
	return _intensity


## The drive stem's level relative to the track, in dB (SILENT_DB = off; 0 = full).
func drive_db() -> float:
	return _drive_db


## Match end: the current track fades out over 1 s, `id` (sting_victory / sting_defeat) plays once, 3 s of silence,
## then theme_main at -6 dB. A missing sting file = the same without the sting.
func play_sting(id: StringName) -> void:
	_context = &"end"
	_kingdom = &""
	_enemy = &""
	_override.clear()
	_sting_id = id
	for s in _slots:
		if s.id != &"":
			_fade_slot(s, 0.0, END_FADE)
	_phase = &"end_fade"
	_phase_left = END_FADE


## Overrides the current pool (MissionConfig.music_tracks, a mission's boss / special pool). Empty = back to the
## context's own pool. Ids whose file is missing are skipped; none left = the fallback loop.
func set_track_pool(ids: Array[StringName]) -> void:
	_override = ids.duplicate()
	if not is_inside_tree() or not (_context in POOL_CONTEXTS):
		return   # boss / menus ignore it; `match` picks it up again
	var avail := _available_pool()
	var cur := current_track()
	if cur == &"" or not avail.has(cur):
		_start_context(TRACK_XFADE)
	else:
		_slots[_cur].loops = _distinct(avail).size() <= 1


## The track playing now (&"" in a gap, the sting or silence).
func current_track() -> StringName:
	if _phase != &"play":
		return &""
	return _slots[_cur].id


## Seconds the current track has played (0 when nothing plays).
func track_time() -> float:
	return _slots[_cur].time if current_track() != &"" else 0.0


## A mission briefing (BriefingScreen) opened: campaign music (music.md 4) until `release_briefing` or until `screen`
## leaves the tree; then the level's match music starts.
func hold_for_briefing(screen: Node) -> void:
	_briefing_id = screen.get_instance_id() if screen != null else 0
	set_music_context(&"campaign")


## The briefing is over (Begin): the current level's match music.
func release_briefing() -> void:
	if _briefing_id == 0:
		return
	_briefing_id = 0
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and &"hero" in scene:
		_context = &""   # restart the match pool even if the kingdoms did not change
		apply_scene(scene)


## True while an in-mission film holds the music silent.
func is_film_hold() -> bool:
	return _film_on


## True while a match-end sting plays.
func is_sting_playing() -> bool:
	return _phase == &"sting" and _sting.playing


## The pause menu: the level's music -6 dB while `on` (no switch).
func set_pause_duck(on: bool) -> void:
	_duck_db = PAUSE_DB if on else 0.0


## Reads a scene and sets its context: the main menu -> menu, a CampaignState story screen -> campaign (ep8_choice /
## ep8_credits -> chant), a film stage (signal cinematic_done) -> none (films carry their own bed), Wave Strike ->
## wave_strike, a level (has `hero`) -> match with its kingdoms (and its MissionConfig.music_tracks, when set).
## Other scenes keep the music as it is.
func apply_scene(scene: Node) -> void:
	if scene == null or scene == self:
		return
	_duck_db = 0.0   # a new scene is never under the pause menu
	var path := scene.scene_file_path
	if path == MAIN_MENU_SCENE:
		set_music_context(&"menu")
		return
	for id: StringName in CampaignState.STORY_SCREENS:
		if String(CampaignState.STORY_SCREENS[id]) == path and path != "":
			set_music_context(&"chant" if CHANT_SCREENS.has(id) else &"campaign")
			return
	if scene.has_signal(&"cinematic_done"):
		set_music_context(&"none")
		return
	if not (&"hero" in scene):
		return
	if _briefing_active():
		return   # the briefing holds the campaign music; Begin hands back to this level's match
	var own := _kingdom_prop(scene, &"player_kingdom", &"fire")
	var enemy := _kingdom_prop(scene, &"enemy_kingdom", &"shadow")
	if scene.has_method(&"lane_for") and scene.has_method(&"bastion_ratio"):
		set_music_context(&"wave_strike", own, enemy)
		return
	var tracks := _config_tracks(scene)
	var same := _context == &"match" and own == _kingdom and enemy == _enemy and tracks == _override
	if same:
		return
	_override = tracks
	_context = &""   # force the restart with the new pool
	set_music_context(&"match", own, enemy)


## Runs the pool rule `n` times without playing anything (tests / debug): `pool` empty = the current context's
## weighted pool (files not checked). Uses a copy of the director's random state, or `seed` when >= 0.
func simulate_picks(n: int, pool: Array[StringName] = [], seed := -1) -> Array[StringName]:
	var p: Array[StringName] = pool if not pool.is_empty() else _weighted_pool()
	var r := RandomNumberGenerator.new()
	if seed >= 0:
		r.seed = seed
	else:
		r.seed = _rng.seed
		r.state = _rng.state
	var out: Array[StringName] = []
	var last := _last_pick
	for i in n:
		last = _pick_from(p, last, r)
		out.append(last)
	return out


# ---------------------------------------------------------------- context / pool

func _start_context(xfade: float) -> void:
	_phase_left = 0.0
	_sting.stop()
	if _context == &"none" or _context == &"":
		for s in _slots:
			if s.id != &"":
				_fade_slot(s, 0.0, xfade)
		_phase = &"idle"
		return
	var avail := _available_pool()
	if avail.is_empty():
		for s in _slots:
			if s.id != &"":
				_fade_slot(s, 0.0, xfade)
		_phase = &"idle"
		return
	var first := _first_track(avail)
	var target_db := 0.0
	_last_pick = &""
	var cur := _slots[_cur]
	if cur.id == first and cur.main.playing and cur.fade_to > 0.0:
		# same track (end screen -> menu, boss pool = current): keep it, only its level moves
		_ctx_db_to = target_db
		cur.loops = _distinct(avail).size() <= 1
		_last_pick = first
		_phase = &"play"
		return
	_ctx_db_to = target_db
	_start_track(first, xfade, _distinct(avail).size() <= 1)


func _first_track(avail: Array[StringName]) -> StringName:
	var want: StringName = &""
	if _override.is_empty() or not (_context in POOL_CONTEXTS):
		if _context == &"match":
			want = _own()
		elif _context == &"wave_strike":
			want = &"wave_strike"
	if want != &"" and avail.has(want):
		return want
	return _pick_from(avail, &"", _rng)


## The context's pool with weights (own x2...), before the file check.
func _weighted_pool() -> Array[StringName]:
	if not _override.is_empty() and _context in POOL_CONTEXTS:
		return _override.duplicate()   # MissionConfig.music_tracks: match / wave_strike only (boss stays boss)
	var out: Array[StringName] = []
	if _context == &"match":
		var own := _own()
		out = [own]   # own kingdom x2, every other track x1 (JS 2026-10-14)
		for id in KINGDOM_THEMES:
			out.append(id)
		out.append(&"field")
	elif _context == &"wave_strike":
		out = [&"wave_strike", &"wave_strike"]
		for id in KINGDOM_THEMES:
			out.append(id)
		out.append(&"field")
	elif LOOP_CONTEXTS.has(_context):
		out = [LOOP_CONTEXTS[_context]]
	return out


## The weighted pool, files present only; nothing present = the old loop (music_match / music_menu) if it exists.
func _available_pool() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _weighted_pool():
		if has_track(id):
			out.append(id)
	if out.is_empty():
		var fb := FALLBACK_MATCH if _context in MATCH_FALLBACK_CONTEXTS else FALLBACK_MENU
		if has_track(fb):
			out.append(fb)
	return out


func _own() -> StringName:
	return _kingdom if _kingdom != &"" else &"fire"


func _distinct(pool: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in pool:
		if not out.has(id):
			out.append(id)
	return out


## A weighted pick from `pool`, never `last` when another track is there.
func _pick_from(pool: Array[StringName], last: StringName, r: RandomNumberGenerator) -> StringName:
	if pool.is_empty():
		return &""
	var cands: Array[StringName] = []
	for id in pool:
		if id != last:
			cands.append(id)
	if cands.is_empty():
		cands = pool
	return cands[r.randi() % cands.size()]


## The next pool track: tavern after 4:00 calm (match, once per 10 min), else the weighted pick.
func _pick_next() -> StringName:
	if _context == &"match" and _override.is_empty() and _calm >= TAVERN_CALM_S \
			and _clock - _last_tavern_at >= TAVERN_EVERY_S and has_track(&"tavern") and _last_pick != &"tavern":
		_last_tavern_at = _clock
		_calm = 0.0
		return &"tavern"
	return _pick_from(_available_pool(), _last_pick, _rng)


# ---------------------------------------------------------------- playback

func _stream(id: StringName) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	if not has_track(id):
		return null
	var s := load(MUSIC_DIR + String(id) + ".wav") as AudioStream
	if s is AudioStreamWAV:
		var wav := (s as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
		s = wav
	_streams[id] = s
	return s


func _start_track(id: StringName, xfade: float, loops: bool) -> void:
	var stream := _stream(id)
	if stream == null:
		_phase = &"idle"
		return
	var old := _slots[_cur]
	if old.id != &"":
		_fade_slot(old, 0.0, xfade)
	_cur = 1 - _cur
	var s := _slots[_cur]
	_stop_slot(s)
	s.id = id
	s.loops = loops
	s.time = 0.0
	s.length = stream.get_length()
	s.main.stream = stream
	var drive_id := StringName(String(id) + "_drive")
	var drive := _stream(drive_id) if not String(id).begins_with("music_") else null
	s.drive.stream = drive
	s.ctx_db = _ctx_db_to
	s.fade = 0.0 if xfade > 0.0 else 1.0
	_fade_slot(s, 1.0, xfade)
	_apply_slot_volume(s)
	s.main.play()
	if drive != null:
		s.drive.play()   # same frame as the track: they loop in sync from bar 1
	_last_pick = id
	_phase = &"play"
	track_changed.emit(id)


func _fade_slot(s: Slot, to: float, seconds: float) -> void:
	s.fade_to = to
	if seconds <= 0.0:
		s.fade = to
		s.fade_rate = 1000.0
	else:
		s.fade_rate = 1.0 / seconds
	if to <= 0.0 and seconds <= 0.0:
		_stop_slot(s)


func _stop_slot(s: Slot) -> void:
	s.main.stop()
	s.drive.stop()
	s.id = &""
	s.fade = 0.0
	s.fade_to = 0.0
	s.time = 0.0


func _update_phase(delta: float) -> void:
	match _phase:
		&"play":
			var s := _slots[_cur]
			if s.loops or s.id == &"" or s.length <= 0.0 or s.fade_to <= 0.0:
				return
			if _intensity >= GAP_SKIP_INTENSITY and s.time >= s.length - TRACK_XFADE:
				var nxt := _pick_next()
				if nxt != &"":
					_start_track(nxt, TRACK_XFADE, false)
			elif s.time >= s.length - TRACK_TAIL:
				_fade_slot(s, 0.0, TRACK_TAIL)
				_phase = &"gap"
				_phase_left = _rng.randf_range(GAP_MIN, GAP_MAX)
		&"gap":
			_phase_left -= delta
			if _phase_left <= 0.0 or _intensity >= GAP_SKIP_INTENSITY:
				var nxt := _pick_next()
				if nxt != &"":
					_start_track(nxt, 0.0, false)
				else:
					_phase = &"idle"
		&"end_fade":
			_phase_left -= delta
			if _phase_left <= 0.0:
				for s in _slots:
					_stop_slot(s)
				var st := _stream_once(_sting_id)
				if st != null:
					_sting.stream = st
					_sting.volume_db = MUSIC_DB
					_sting.play()
					_phase = &"sting"
					_phase_left = st.get_length()
				else:
					_phase = &"end_silence"
					_phase_left = END_SILENCE
		&"sting":
			_phase_left -= delta
			if _phase_left <= 0.0:
				_phase = &"end_silence"
				_phase_left = END_SILENCE
		&"end_silence":
			_phase_left -= delta
			if _phase_left <= 0.0:
				var end_id := &"theme_main" if has_track(&"theme_main") else FALLBACK_MENU
				_ctx_db_to = END_DB
				if has_track(end_id):
					_start_track(end_id, TRACK_XFADE, true)
				else:
					_phase = &"idle"


## A sting: no loop.
func _stream_once(id: StringName) -> AudioStream:
	if not has_track(id):
		return null
	return load(MUSIC_DIR + String(id) + ".wav") as AudioStream


func _update_volumes(delta: float) -> void:
	var want := SILENT_DB
	if _drive_on:
		var t := clampf((_intensity - DRIVE_ON) / (DRIVE_FULL_AT - DRIVE_ON), 0.0, 1.0)
		want = lerpf(DRIVE_LOW_DB, 0.0, t)
	_drive_db = move_toward(_drive_db, want, DRIVE_SLEW_DB * delta)
	for s in _slots:
		if s.id == &"":
			continue
		s.fade = move_toward(s.fade, s.fade_to, s.fade_rate * delta)
		if s == _slots[_cur]:
			s.ctx_db = move_toward(s.ctx_db, _ctx_db_to, CTX_DB_RATE * delta)
		if s.fade <= 0.0 and s.fade_to <= 0.0:
			_stop_slot(s)
			continue
		_apply_slot_volume(s)


func _apply_slot_volume(s: Slot) -> void:
	var db := MUSIC_DB + s.ctx_db + _duck_db + linear_to_db(maxf(s.fade * _film_fade, 0.0001))
	s.main.volume_db = db
	s.drive.volume_db = SILENT_DB if _drive_db <= SILENT_DB + 1.0 else db + _drive_db


func _update_intensity(delta: float) -> void:
	_raw_age += delta
	var raw := _raw if _raw_age <= FEED_TIMEOUT else 0.0
	if raw > _intensity:
		_intensity = minf(raw, _intensity + delta / RISE_S)
		_hold_left = HOLD_S
	elif raw >= _intensity - 0.001:
		_hold_left = HOLD_S
	elif _hold_left > 0.0:
		_hold_left -= delta
	else:
		_intensity = maxf(raw, _intensity - delta / FALL_S)
	if _intensity >= DRIVE_ON:
		_drive_on = true
	elif _intensity < DRIVE_OFF:
		_drive_on = false
	if _context == &"match" and _intensity < TAVERN_CALM_BELOW:
		_calm += delta
	else:
		_calm = 0.0


# ---------------------------------------------------------------- hooks

func _on_mission_ended(victory: bool) -> void:
	if _context == &"end":
		return
	play_sting(&"sting_victory" if victory else &"sting_defeat")


## A new scene under /root (change_scene, F9 reload, MenuFlow.set_scene): read it once it is ready.
func _on_node_added(node: Node) -> void:
	if node == self or not is_inside_tree() or node.get_parent() != get_tree().root:
		return
	_check_scene.call_deferred(node)


func _check_scene(node: Node) -> void:
	if is_instance_valid(node) and node.is_inside_tree() and node == get_tree().current_scene:
		apply_scene(node)


static func _kingdom_prop(scene: Node, prop: StringName, fallback: StringName) -> StringName:
	if prop in scene:
		var v: Variant = scene.get(prop)
		if v != null and StringName(str(v)) != &"":
			return StringName(str(v))
	return fallback


## MissionConfig.music_tracks of a mission (its `config` resource), empty when unset.
static func _config_tracks(scene: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	var cfg: Variant = scene.get(&"config") if &"config" in scene else null
	if cfg is Resource and &"music_tracks" in (cfg as Resource):
		var v: Variant = (cfg as Resource).get(&"music_tracks")
		if v is Array:
			for id: Variant in v:
				out.append(StringName(str(id)))
	return out


func _briefing_active() -> bool:
	if _briefing_id == 0:
		return false
	var n := instance_from_id(_briefing_id) as Node
	return n != null and n.is_inside_tree() and not n.is_queued_for_deletion()


## CinematicPlayer.is_any_playing(tree), load-guarded (no cinematics script = never).
func _film_playing() -> bool:
	if not _cine_checked:
		_cine_checked = true
		if ResourceLoader.exists(CINE_SCRIPT):
			_cine_script = load(CINE_SCRIPT) as GDScript
	if _cine_script == null or not is_inside_tree():
		return false
	return bool(_cine_script.call(&"is_any_playing", get_tree()))


func _set_film(on: bool) -> void:
	if on == _film_on:
		return
	_film_on = on
	if not on:
		for s in _slots:
			s.main.stream_paused = false
			s.drive.stream_paused = false
