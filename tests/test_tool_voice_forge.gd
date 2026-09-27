extends SceneTree
## Voice Forge (tools/voice_forge/README.md): the manifest is valid, every mission line has a WAV that loads, and the
## VoicePlayer speaks a line when the DialogueBox shows it (Events.dialogue -> line_started) and stays silent for a
## line without a voice. Headless.
## Run:  godot --headless --path . -s tests/test_tool_voice_forge.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "tool_voice_forge"
const MANIFEST := "res://data/voice/manifest.json"
const PLAYER := "res://scripts/ui/voice_player.gd"

var frame := 0
var _box: Node
var _vp: Node
var _solo: Node
var _started: Array = []
var _solo_started: Array = []
var _fails: Array[String] = []


func _initialize() -> void:
	pass


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		_static_checks()
		if not _fails.is_empty():
			return _finish()
		_setup_players()
	elif frame == 4:
		var events := root.get_node_or_null("Events")
		if events == null:
			_fails.append("no Events autoload")
			return _finish()
		events.emit_signal(&"dialogue", &"narrator", "The Master is gone. His crown is not.")
		events.emit_signal(&"dialogue", &"vessa", "A line nobody ever recorded, for the silence test.")
	elif frame == 8:
		if _started.size() != 1 or String(_started[0][0]) != "narrator":
			_fails.append("DialogueBox voice: expected the narrator's L1 to start, got %s" % [_started])
		if not _vp.playing:
			_fails.append("VoicePlayer not playing after the line showed")
		if _solo_started.size() != 1:
			_fails.append("standalone VoicePlayer (Events.dialogue) played %d lines, expected 1" % _solo_started.size())
		_box.call(&"skip")   # next line has no voice: the voice stops, nothing else happens
	elif frame == 12:
		if _started.size() != 1:
			_fails.append("a line without a WAV played something: %s" % [_started])
		if _vp.playing:
			_fails.append("voice kept playing over a line without a voice")
		return _finish()
	return false


func _static_checks() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) if FileAccess.file_exists(MANIFEST) else null
	if not data is Dictionary or not (data as Dictionary).get("lines") is Dictionary:
		_fails.append("manifest missing or invalid: " + MANIFEST)
		return
	var lines: Dictionary = data["lines"]
	if lines.size() < 20:
		_fails.append("manifest has only %d lines" % lines.size())
	for key: String in lines:
		var e: Dictionary = lines[key]
		var spk := str(e.get("speaker", ""))
		var path := str(e.get("path", ""))
		if (spk + "\n" + str(e.get("text", ""))).sha256_text().substr(0, 16) != str(e.get("text_hash", "")):
			_fails.append("%s: text_hash does not match" % key)
		if float(e.get("duration", 0.0)) <= 0.2:
			_fails.append("%s: duration %s" % [key, e.get("duration")])
		if not ResourceLoader.exists(path) or not load(path) is AudioStream:
			_fails.append("%s: %s does not load (import?)" % [key, path])
		if _fails.size() > 6:
			return
	# Every mission line, read straight from the mission script, has a voice.
	var ms := load("res://scripts/campaign/mission_01.gd") as Script
	var dialogue: Array = ms.get_script_constant_map().get("DIALOGUE", []) if ms else []
	if dialogue.is_empty():
		_fails.append("mission_01 DIALOGUE not found")
	var vp_script := load(PLAYER) as Script
	if vp_script == null:
		_fails.append("VoicePlayer script missing")
		return
	var probe: Node = vp_script.new()
	root.add_child(probe)
	var missing := 0
	for l: Array in dialogue:
		if not probe.call(&"has_line", l[0], l[1]):
			missing += 1
			_fails.append("mission line without voice: %s: %s" % [l[0], l[1]])
	print("voice_forge test: manifest %d lines, mission_01 %d / %d voiced" % [lines.size(), dialogue.size() - missing, dialogue.size()])
	probe.queue_free()
	_python_selftest()


## voice_forge.py selftest (direction tags, speed-fit, manifest compatibility, auditions merge) in the Kokoro venv,
## which lives outside the repo: skipped (with a note) on a machine without it. No Kokoro model is loaded.
func _python_selftest() -> void:
	var home := OS.get_environment("FW_VOICE_HOME")
	if home == "":
		home = ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir().path_join("four-wizards-voice")
	var py := home.path_join("venv/Scripts/python.exe")
	if not FileAccess.file_exists(py):
		print("voice_forge test: python selftest skipped (no venv at %s)" % py)
		return
	var out: Array = []
	var code := OS.execute(py, [ProjectSettings.globalize_path("res://tools/voice_forge/voice_forge.py"), "selftest"], out, true)
	var text := "".join(PackedStringArray(out)).strip_edges()
	print("voice_forge test: " + text)
	if code != 0 or not text.contains("PASS voice_forge selftest"):
		_fails.append("python selftest: exit %d %s" % [code, text.substr(0, 300)])


func _setup_players() -> void:
	var box_script := load("res://scripts/ui/mission/dialogue_box.gd") as Script
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_box = box_script.new()
	layer.add_child(_box)
	_vp = (load(PLAYER) as Script).new()
	_box.add_child(_vp)
	_vp.connect(&"voice_started", func(s: StringName, t: String, _p: String) -> void: _started.append([s, t]))
	# Standalone (no DialogueBox parent): listens to Events.dialogue itself.
	_solo = (load(PLAYER) as Script).new()
	root.add_child(_solo)
	_solo.connect(&"voice_started", func(s: StringName, t: String, _p: String) -> void: _solo_started.append([s, t]))


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(PackedStringArray(_fails.slice(0, 6)))])
	return true
