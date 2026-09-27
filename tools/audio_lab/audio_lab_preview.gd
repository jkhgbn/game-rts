extends Node3D
## Audio Lab preview (docs/plan/audio-lab.md): a windowed listening room. Plays each cue of a lab run over its
## context: "battle" (a staged fight: combat cues firing from 3D voices spread 4-14 m around the camera focus, the
## camera 30 m away like the RTS default zoom, GameAudio's pitch +-7 % and volumes), "ui" (menu / match music on the
## Music bus) or "map" (a soft generated wind bed). Fill docs/audio/lab/<name>/listening_sheet.md while listening.
## Run: godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/<name>/preview_cues.json
## Without cues= it lists every file under res://assets/audio (category from the lab rules).
## Keys: Right / Down next, Left / Up previous, Space replay, A auto-play all, B battle bed, M music, 1-3 bed
## intensity, Esc quit.

const Report := preload("res://tools/audio_lab/lab_report.gd")
const Code := preload("res://tools/audio_lab/lab_code.gd")
const BED_VOICES := 8
const AUTO_EVERY := 2.8
const INTENSITY_GAP := [0.9, 0.4, 0.15]   ## Average seconds between bed hits per voice-slot, per intensity.

var cues: Array = []          ## [{id, path, category, context, mode, volume_db, pitch, bus, level}]
var index := 0
var auto := false
var battle_on := false
var music_on := false
var wind_on := false
var intensity := 1
var played := 0               ## Read only (tests): cues played.
var bed_hits := 0             ## Read only (tests): battle bed hits.

var _streams := {}
var _bed: Array[AudioStreamPlayer3D] = []
var _bed_wait: Array[float] = []
var _bed_pool: Array = []     # unit-category cues
var _cue2d: AudioStreamPlayer
var _cue3d: AudioStreamPlayer3D
var _music: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _wind_pb: AudioStreamGeneratorPlayback
var _wind_last := 0.0
var _auto_left := 0.0
var _label: Label
var _help: Label


func _ready() -> void:
	_ensure_buses()
	_load_cues()
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 21.2, 21.2)
	add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.08, 0.09, 0.11)
	add_child(env)
	for i in BED_VOICES:
		var v := AudioStreamPlayer3D.new()
		v.bus = &"SFX"
		v.unit_size = 18.0
		v.max_distance = 75.0
		var ang := TAU * float(i) / BED_VOICES
		var rad := 4.0 + 10.0 * float(i % 3) / 2.0
		v.position = Vector3(cos(ang) * rad, 1.0, sin(ang) * rad)
		add_child(v)
		_bed.append(v)
		_bed_wait.append(randf())
	_cue2d = AudioStreamPlayer.new()
	_cue2d.bus = &"SFX"
	add_child(_cue2d)
	_cue3d = AudioStreamPlayer3D.new()
	_cue3d.bus = &"SFX"
	_cue3d.unit_size = 18.0
	_cue3d.max_distance = 75.0
	_cue3d.position = Vector3(2.0, 1.0, 3.0)
	add_child(_cue3d)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = -10.0
	add_child(_music)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.3
	_wind = AudioStreamPlayer.new()
	_wind.stream = gen
	_wind.bus = &"SFX"
	_wind.volume_db = -24.0
	add_child(_wind)
	var ui := CanvasLayer.new()
	add_child(ui)
	_label = Label.new()
	_label.position = Vector2(24, 24)
	_label.add_theme_font_size_override(&"font_size", 16)
	ui.add_child(_label)
	_help = Label.new()
	_help.position = Vector2(24, 4)
	_help.text = "Right/Left: cue  Space: replay  A: auto  B: battle bed  M: music  1-3: intensity  Esc: quit"
	ui.add_child(_help)
	select(0)


func _ensure_buses() -> void:
	for b: StringName in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")


func _load_cues() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.lstrip("-").begins_with("cues="):
			path = a.lstrip("-").substr(5)
	if path != "" and not path.begins_with("res://") and not path.contains(":"):
		path = "res://" + path
	if path != "" and FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(Code.read_text(path))
		if data is Dictionary:
			cues = (data as Dictionary).get("cues", [])
	if cues.is_empty():
		var files: Array[String] = []
		Code.list_files("res://assets/audio", ["wav", "ogg", "mp3"], files)
		files.sort()
		for f in files:
			var id := f.get_file().get_basename()
			var cat := Report.category_of(id, f, "auto")
			cues.append({"id": id, "path": f, "category": cat, "context": {"ui": "ui", "music": "ui",
				"ambience": "map"}.get(cat, "battle"), "mode": "3d" if cat in ["unit", "spell"] else "2d",
				"volume_db": 0.0, "pitch": 0.07 if cat in ["unit", "spell"] else 0.0, "bus": "Music" if cat == "music"
				else "SFX", "level": null})
	for c: Dictionary in cues:
		if c.get("category", "") == "unit":
			_bed_pool.append(c)


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


## Selects cue i and sets its context (battle bed / music / wind).
func select(i: int) -> void:
	if cues.is_empty():
		_label.text = "No cues."
		return
	index = posmod(i, cues.size())
	var c: Dictionary = cues[index]
	var ctx := str(c.get("context", "battle"))
	battle_on = ctx == "battle"
	wind_on = ctx == "map"
	music_on = ctx == "ui" and str(c.get("category", "")) != "music"
	_apply_music()
	_apply_wind()
	_refresh()


func play_current() -> void:
	if cues.is_empty():
		return
	var c: Dictionary = cues[index]
	var s := _stream(str(c["path"]))
	if s == null:
		return
	var is3d := str(c.get("mode", "2d")) == "3d"
	var vol := float(c["volume_db"]) if c.get("volume_db") != null else 0.0
	var pitch := float(c["pitch"]) if c.get("pitch") != null else 0.0
	if str(c.get("category", "")) == "music":
		_music.stream = s
		_music.volume_db = vol
		_music.play()
	elif is3d:
		_cue3d.stop()
		_cue3d.stream = s
		_cue3d.bus = StringName(str(c.get("bus", "SFX")))
		_cue3d.volume_db = vol
		_cue3d.pitch_scale = randf_range(1.0 - pitch, 1.0 + pitch) if pitch > 0.0 else 1.0
		_cue3d.play()
	else:
		_cue2d.stop()
		_cue2d.stream = s
		_cue2d.bus = StringName(str(c.get("bus", "SFX")))
		_cue2d.volume_db = vol
		_cue2d.play()
	played += 1


func _apply_music() -> void:
	if not music_on:
		if _music.playing and (_music.stream == null or not str(_music.stream.resource_path).contains("music")):
			_music.stop()
		elif _music.playing:
			_music.stop()
		return
	for c: Dictionary in cues:
		if str(c.get("category", "")) == "music":
			var s := _stream(str(c["path"]))
			if s and (_music.stream != s or not _music.playing):
				_music.stream = s
				_music.volume_db = float(c.get("volume_db", -10.0)) if c.get("volume_db") != null else -10.0
				_music.play()
			return


func _apply_wind() -> void:
	if wind_on and not _wind.playing:
		_wind.play()
		_wind_pb = _wind.get_stream_playback() as AudioStreamGeneratorPlayback
	elif not wind_on and _wind.playing:
		_wind.stop()
		_wind_pb = null


func _process(delta: float) -> void:
	if battle_on and not _bed_pool.is_empty():
		for i in _bed.size():
			_bed_wait[i] -= delta
			if _bed_wait[i] > 0.0:
				continue
			_bed_wait[i] = randf_range(0.3, 1.7) * float(INTENSITY_GAP[intensity - 1]) * _bed.size() / 4.0
			var c: Dictionary = _bed_pool[randi() % _bed_pool.size()]
			var s := _stream(str(c["path"]))
			if s == null:
				continue
			var v := _bed[i]
			v.stream = s
			v.volume_db = float(c["volume_db"]) if c.get("volume_db") != null else 0.0
			v.pitch_scale = randf_range(0.93, 1.07)
			v.play()
			bed_hits += 1
	if _wind_pb:
		var n := _wind_pb.get_frames_available()
		for k in n:
			_wind_last = clampf(_wind_last + randf_range(-0.02, 0.02), -0.5, 0.5) * 0.998
			_wind_pb.push_frame(Vector2(_wind_last, _wind_last))
	if auto:
		_auto_left -= delta
		if _auto_left <= 0.0:
			_auto_left = AUTO_EVERY
			select(index + 1)
			play_current()


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.physical_keycode:
		KEY_RIGHT, KEY_DOWN:
			select(index + 1)
			play_current()
		KEY_LEFT, KEY_UP:
			select(index - 1)
			play_current()
		KEY_SPACE:
			play_current()
		KEY_A:
			auto = not auto
			_auto_left = 0.0
		KEY_B:
			battle_on = not battle_on
		KEY_M:
			music_on = not music_on
			_apply_music()
		KEY_1, KEY_2, KEY_3:
			intensity = k.physical_keycode - KEY_0
		KEY_ESCAPE:
			get_tree().quit()
	_refresh()


func _refresh() -> void:
	if _label == null or cues.is_empty():
		return
	var lines: PackedStringArray = []
	var c: Dictionary = cues[index]
	lines.append("Cue %d / %d: %s  [%s, %s context, %s]  in game %s LUFS" % [index + 1, cues.size(), c["id"],
		c.get("category", "?"), c.get("context", "?"), c.get("mode", "2d"), Report.f1(c.get("level"))])
	lines.append("Battle bed %s (intensity %d)  Music %s  Wind %s  Auto %s" % ["ON" if battle_on else "off", intensity,
		"ON" if music_on else "off", "ON" if wind_on else "off", "ON" if auto else "off"])
	lines.append("")
	var first := maxi(index - 8, 0)
	for i in range(first, mini(first + 22, cues.size())):
		lines.append("%s %s  (%s)" % [">" if i == index else " ", cues[i]["id"], cues[i].get("category", "?")])
	_label.text = "\n".join(lines)
