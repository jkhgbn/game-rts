extends SceneTree
## MU13 (docs/design/music.md 4 + 5): MusicDirector contexts. Main menu -> menu music; skirmish -> match (own kingdom
## first, the own theme); F9 (reload_current_scene) keeps the same track playing (no track_changed, its time goes on); the pool rule
## never repeats a track back-to-back over 30 picks and the match pool shows all 5 ids (4 themes + field); a pool of missing files falls back to music_match; mission_ended
## -> the sting (when its file exists), then theme_main (or music_menu) on the end screen; the ep8_choice screen ->
## chant (or its fallback). Override + boss: boss plays boss, match returns to the override; a briefing plays
## campaign, Begin returns to match; an in-mission film (CinematicPlayer) holds the music silent, then it resumes. Works with any subset of the music files present.
## Run: godot --headless --path . -s tests/test_mu13.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "mu13"
const TIMEOUT_FRAMES := 5000
const DIR := "res://assets/audio/music/"

var md: Node = null
var level: Node = null
var _level_id := 0
var frame := 0
var _phase := 0
var _phase_frame := 0
var _changes: Array[StringName] = []
var _track_before: StringName = &""
var _time_before := 0.0
var _sting_seen := false
var _briefing: Node = null
var _film: Node = null
var _bus_fail := ""


func _initialize() -> void:
	# bare tree (no GameAudio, no GameSettings yet): ensure() must put every player on an existing Music bus
	var had_bus := AudioServer.get_bus_index(&"Music") != -1
	var d: Node = load("res://scripts/audio/music_director.gd").call(&"ensure", self)
	var buses: Array = d.call(&"player_buses")
	var idx := AudioServer.get_bus_index(&"Music")
	for b: StringName in buses:
		if b != &"Music" or idx == -1 or AudioServer.get_bus_index(b) != idx:
			_bus_fail = "player bus %s (Music bus index %d, existed before: %s)" % [b, idx, had_bus]
	if _bus_fail == "":
		AudioServer.set_bus_mute(idx, true)   # the Music bus level reaches them: muting it mutes their bus
		for b: StringName in buses:
			if not AudioServer.is_bus_mute(AudioServer.get_bus_index(b)):
				_bus_fail = "muting Music does not reach bus %s" % b
		AudioServer.set_bus_mute(idx, false)
	if _bus_fail == "":
		print("  buses: %d music players on Music (bus existed before ensure: %s)" % [buses.size(), had_bus])
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	frame += 1
	if _bus_fail != "":
		return _fail(_bus_fail)
	if frame > TIMEOUT_FRAMES:
		return _fail("timed out in phase %d" % _phase)
	if md == null:
		md = root.get_node_or_null(^"MusicDirector")
		if md != null:
			md.connect(&"track_changed", func(id: StringName) -> void: _changes.append(id))
		elif frame > 30:
			return _fail("no /root/MusicDirector after the main menu opened")
		return false
	var t := frame - _phase_frame
	match _phase:
		0:   # main menu
			if t < 20:
				return false
			var want := &"theme_main" if _has(&"theme_main") else &"music_menu"
			if md.call(&"music_context") != &"menu" or md.call(&"current_track") != want:
				return _fail("menu: context %s track %s, expected menu / %s" % [md.call(&"music_context"),
						md.call(&"current_track"), want])
			print("  menu: %s" % want)
			var sk: Node = load("res://scenes/skirmish.tscn").instantiate()
			var bot: Node = sk.get_node_or_null("ShadowBot")
			if bot:
				bot.set("enabled", false)
			var old := current_scene
			root.add_child(sk)
			current_scene = sk
			old.queue_free()
			level = sk
			_next()
		1:   # skirmish: match, own kingdom first
			if level.get(&"hero") == null or t < 60:
				return t > 4000 and _fail("skirmish never ready")
			var own := StringName(str(level.get(&"player_kingdom")))
			var want := own if _has(own) else &"music_match"
			if md.call(&"music_context") != &"match" or md.call(&"current_track") != want:
				return _fail("match: context %s track %s, expected match / %s" % [md.call(&"music_context"),
						md.call(&"current_track"), want])
			_track_before = want
			_time_before = float(md.call(&"track_time"))
			_changes.clear()
			_level_id = level.get_instance_id()
			print("  match: %s (t %.1f s)" % [want, _time_before])
			reload_current_scene()   # F9
			_next()
		2:   # after F9: same track, not restarted
			var cur := current_scene
			if cur == null or cur.get_instance_id() == _level_id or cur.get(&"hero") == null or t < 60:
				return t > 4000 and _fail("reloaded skirmish never ready")
			level = cur
			if md.call(&"current_track") != _track_before or not _changes.is_empty():
				return _fail("F9 changed the track: %s -> %s (changes %s)" % [_track_before,
						md.call(&"current_track"), _changes])
			var now := float(md.call(&"track_time"))
			if now <= _time_before:
				return _fail("F9 restarted the track (time %.2f -> %.2f)" % [_time_before, now])
			print("  F9 kept %s (t %.1f -> %.1f s)" % [_track_before, _time_before, now])
			if not _check_picks():
				return true
			# missing files -> the old loop
			var missing: Array[StringName] = [&"zz_missing_a", &"zz_missing_b"]
			md.call(&"set_track_pool", missing)
			var fb := &"music_match" if _has(&"music_match") else &""
			if md.call(&"current_track") != fb:
				return _fail("missing pool: track %s, expected %s" % [md.call(&"current_track"), fb])
			print("  missing files -> %s" % fb)
			var empty: Array[StringName] = []
			md.call(&"set_track_pool", empty)
			_next()
		3:   # MissionConfig.music_tracks override + boss: boss plays boss, match goes back to the override
			var own_only: Array[StringName] = [_track_before]
			md.call(&"set_track_pool", own_only)
			md.call(&"set_music_context", &"boss")
			var boss := &"boss" if _has(&"boss") else &"music_match"
			if md.call(&"current_track") != boss:
				return _fail("boss with an override: track %s, expected %s" % [md.call(&"current_track"), boss])
			md.call(&"set_music_context", &"match")
			if md.call(&"music_context") != &"match" or md.call(&"current_track") != _track_before:
				return _fail("boss -> match: %s / %s, expected the override %s" % [md.call(&"music_context"),
						md.call(&"current_track"), _track_before])
			print("  override + boss: %s, back to %s" % [boss, _track_before])
			var empty: Array[StringName] = []
			md.call(&"set_track_pool", empty)
			_briefing = load("res://scripts/ui/mission/briefing_screen.gd").new()
			level.add_child(_briefing)
			_briefing.call(&"open", {"title": "Test", "paragraphs": ["A test briefing."]}, null)
			_next()
		4:   # briefing = campaign, Begin = match
			if t == 10:
				var camp := &"campaign_map" if _has(&"campaign_map") else &"music_menu"
				if md.call(&"music_context") != &"campaign" or md.call(&"current_track") != camp:
					return _fail("briefing: %s / %s, expected campaign / %s" % [md.call(&"music_context"),
							md.call(&"current_track"), camp])
				print("  briefing: %s" % camp)
				_briefing.call(&"begin")
			elif t == 20:
				if md.call(&"music_context") != &"match" or md.call(&"current_track") != _track_before:
					return _fail("after Begin: %s / %s, expected match / %s" % [md.call(&"music_context"),
							md.call(&"current_track"), _track_before])
				print("  Begin -> match %s" % _track_before)
				_film = load("res://scripts/cinematics/cinematic_player.gd").call(&"instance", self)
				# a bare 6 s film (one static shot, no actors): only CinematicPlayer.is_any_playing matters here
				var film: Resource = load("res://scripts/cinematics/cinematic_script.gd").new()
				var shot: Resource = load("res://scripts/cinematics/cinematic_shot.gd").new()
				shot.set(&"id", &"mu13_shot")
				shot.set(&"duration", 6.0)
				film.set(&"id", &"mu13_film")
				(film.get(&"shots") as Array).append(shot)
				var why := str(_film.call(&"play", film, level))
				if why != "":
					return _fail("film refused: %s" % why)
				_next()
		5:   # an in-mission film: the music holds silent (paused), then resumes where it was
			if t == 90:
				if not bool(md.call(&"is_film_hold")) or md.call(&"current_track") != _track_before:
					return _fail("film: hold %s, track %s" % [md.call(&"is_film_hold"), md.call(&"current_track")])
				_time_before = float(md.call(&"track_time"))
			elif t == 150:
				if absf(float(md.call(&"track_time")) - _time_before) > 0.01:
					return _fail("film: the track went on (%.2f -> %.2f s)" % [_time_before, md.call(&"track_time")])
				print("  film: silent, track held at %.1f s" % _time_before)
				_film.call(&"stop")
			elif t == 200:
				if bool(md.call(&"is_film_hold")) or md.call(&"current_track") != _track_before 						or float(md.call(&"track_time")) <= _time_before:
					return _fail("after the film: hold %s, track %s t %.2f" % [md.call(&"is_film_hold"),
							md.call(&"current_track"), md.call(&"track_time")])
				print("  film over: %s resumed" % _track_before)
				root.get_node(^"Events").emit_signal(&"mission_ended", true)
				_next()
		6:   # match end: fade, sting, 3 s silence, theme_main at -6 dB
			if md.call(&"music_context") != &"end":
				return _fail("mission_ended: context %s, expected end" % md.call(&"music_context"))
			if bool(md.call(&"is_sting_playing")):
				_sting_seen = true
			var end_id := &"theme_main" if _has(&"theme_main") else &"music_menu"
			if md.call(&"current_track") == end_id:
				if _has(&"sting_victory") and not _sting_seen:
					return _fail("end track came without the sting")
				print("  end: sting %s, then %s" % ["played" if _sting_seen else "missing (skipped)", end_id])
				_next()
			elif t > 60 * 20:
				return _fail("end track never came (track %s)" % md.call(&"current_track"))
		7:   # the ep8 choice screen -> chant
			var screen := Node.new()
			screen.scene_file_path = "res://missions/ep8_choice.tscn"
			md.call(&"apply_scene", screen)
			screen.free()
			var want := &"chant" if _has(&"chant") else &"music_menu"
			if md.call(&"music_context") != &"chant" or md.call(&"current_track") != want:
				return _fail("ep8_choice: context %s track %s" % [md.call(&"music_context"), md.call(&"current_track")])
			print("  ep8_choice -> %s" % want)
			print("PASS %s" % TASK_ID)
			return true
	return false


func _check_picks() -> bool:
	# JS 2026-10-14: match pool = the 4 kingdom themes + field (own x2), first = own; Wave Strike adds wave_strike x2.
	var pools: Array = [
		[&"fire", &"fire", &"ice", &"nature", &"shadow", &"field"],
		[&"wave_strike", &"wave_strike", &"fire", &"ice", &"nature", &"shadow", &"field"],
	]
	for p: Array in pools:
		var pool: Array[StringName] = []
		pool.assign(p)
		if not _no_repeat(md.call(&"simulate_picks", 30, pool, 7), str(p)):
			return false
	# the running match's own pool (fire vs shadow): no repeat, all 5 ids over 30 picks (fixed seeds)
	var empty: Array[StringName] = []
	for seed in [1, 2, 3]:
		var picks: Array = md.call(&"simulate_picks", 30, empty, seed)
		if not _no_repeat(picks, "match pool seed %d" % seed):
			return false
		for id: StringName in [&"fire", &"ice", &"nature", &"shadow", &"field"]:
			if not picks.has(id):
				return not _fail("match pool seed %d: %s never picked in 30 (%s)" % [seed, id, picks])
	print("  match pool: all 5 ids over 30 picks, no back-to-back repeat")
	return true


func _no_repeat(picks: Array, what: String) -> bool:
	if picks.size() != 30:
		return not _fail("simulate_picks gave %d picks" % picks.size())
	for i in range(1, picks.size()):
		if picks[i] == picks[i - 1]:
			return not _fail("%s repeated %s back-to-back at pick %d" % [what, picks[i], i])
	print("  30 picks %s: no repeat (%s ...)" % [what, picks.slice(0, 6)])
	return true


func _has(id: StringName) -> bool:
	return ResourceLoader.exists(DIR + String(id) + ".wav")


func _next() -> void:
	_phase += 1
	_phase_frame = frame


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	return true
