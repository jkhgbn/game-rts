class_name VoicePlayer
extends AudioStreamPlayer
## Voice Forge hookup (tools/voice_forge/README.md, owner: the Voice Forge agent; ui-coder owns the folder).
## Plays the Kokoro WAV of a dialogue line when one exists in `data/voice/manifest.json`; otherwise does nothing.
## Added as a child of the DialogueBox by MissionHud (one load-guarded line): it follows the box's `line_started`
## signal, so the voice starts when the subtitle shows (queued lines wait their turn) and a new line / skip cuts the
## previous voice. Without a DialogueBox parent it listens to `Events.dialogue(speaker, text)` directly.
## No manifest / no matching WAV = no connection / no sound, never an error. Bus "Voice" if it exists, else "SFX",
## else "Master"; ducks nothing.

signal voice_started(speaker: StringName, text: String, path: String)

const MANIFEST_PATH := "res://data/voice/manifest.json"
const VOLUME_DB := -2.0

var enabled := true            ## False = stay silent (e.g. a future "voices off" setting).
var last_path := ""            ## Read only: the WAV of the last line played ("" = none yet).
var current_duration := 0.0    ## Read only: voice length (s) of the line now shown, 0 = it has no voice (DialogueBox hold).
var _by_line: Dictionary = {}  # "speaker\ntext" -> {path, duration}


func _ready() -> void:
	name = "VoicePlayer"
	volume_db = VOLUME_DB
	_load_manifest()
	if _by_line.is_empty():
		return
	var p := get_parent()
	if p and p.has_signal(&"line_started"):
		p.connect(&"line_started", _on_line)
		if p.has_signal(&"queue_emptied"):
			p.connect(&"queue_emptied", _on_queue_emptied)   # U5-5: skipping the last line cuts its voice
	else:
		var events := get_node_or_null(^"/root/Events")
		if events and events.has_signal(&"dialogue"):
			events.connect(&"dialogue", _on_line)


# --- Public ------------------------------------------------------------------------------------------

## Plays the line's voice. Returns false (and stays silent) when there is none.
func play_line(speaker: StringName, text: String) -> bool:
	var e: Dictionary = _by_line.get(_key(speaker, text), {})
	if not enabled or e.is_empty():
		return false
	var path := str(e.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return false
	var s := load(path) as AudioStream
	if s == null:
		return false
	stop()
	stream = s
	bus = _pick_bus()
	play()
	last_path = path
	current_duration = float(e.get("duration", 0.0))
	if current_duration <= 0.0:
		current_duration = s.get_length()
	voice_started.emit(speaker, text, path)
	return true


func has_line(speaker: StringName, text: String) -> bool:
	return _by_line.has(_key(speaker, text))


## Length in seconds of the line's voice (0 = no voice). The DialogueBox can hold a line this long.
func line_duration(speaker: StringName, text: String) -> float:
	return float((_by_line.get(_key(speaker, text), {}) as Dictionary).get("duration", 0.0))


func line_count() -> int:
	return _by_line.size()


static func norm_text(text: String) -> String:
	var parts := text.replace("|", " ").replace("\n", " ").split(" ", false)
	return " ".join(parts).strip_edges()


# --- Internals ---------------------------------------------------------------------------------------

func _on_line(speaker: StringName, text: String) -> void:
	current_duration = 0.0
	if not play_line(speaker, text) and playing:
		stop()   # the subtitle moved on to a line without a voice


func _on_queue_emptied() -> void:
	current_duration = 0.0
	if playing:
		stop()


func _key(speaker: StringName, text: String) -> String:
	return String(speaker).to_lower() + "\n" + norm_text(text)


func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not data is Dictionary or not (data as Dictionary).get("lines") is Dictionary:
		return
	var lines: Dictionary = data["lines"]
	for id: String in lines:
		var e: Variant = lines[id]
		if not e is Dictionary:
			continue
		var entry := {"path": str(e.get("path", "")), "duration": float(e.get("duration", 0.0))}
		var text := norm_text(str(e.get("text", "")))
		_by_line[str(e.get("speaker", "")).to_lower() + "\n" + text] = entry
		var sources: Variant = e.get("sources", [])
		if sources is Array:
			for src: Variant in sources:
				if src is Dictionary and (src as Dictionary).has("speaker_id"):
					_by_line[str(src["speaker_id"]).to_lower() + "\n" + text] = entry


static func _pick_bus() -> StringName:
	for b: StringName in [&"Voice", &"SFX"]:
		if AudioServer.get_bus_index(b) != -1:
			return b
	return &"Master"
