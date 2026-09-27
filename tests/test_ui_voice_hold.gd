extends SceneTree
## Voice hold (DialogueBox + VoicePlayer): a voiced line stays up for its voice length + 0.4 s (not cut at LINE_SECONDS
## by the queued next line), the next voiced line waits in the queue (no overlap), and a line without a voice keeps
## exactly LINE_SECONDS. Headless.
## Run:  godot --headless --path . -s tests/test_ui_voice_hold.gd --fixed-fps 60 --quit-after 1400

const TASK_ID := "ui_voice_hold"
const PLAYER := "res://scripts/ui/voice_player.gd"
# Two of the longest mission voice lines (manifest durations 5.589 s / 5.57 s, both > LINE_SECONDS).
const L1 := [&"vessa", "An Ember Crown, in a place called Emberfall. I'm not saying it was left for me. I'm not NOT saying it."]
const L2 := [&"pell", "Free at last! Buy something, would you? Shadow soldiers are terrible customers. They never pay, they just loom."]
const L3 := [&"narrator", "A line nobody ever recorded, for the hold test."]

var frame := 0
var _box: DialogueBox
var _vp: Node
var _starts: Array = []     # [[speaker, frame], ...]
var _empty_frame := -1
var _fails: Array[String] = []


func _initialize() -> void:
	pass


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		if not ResourceLoader.exists(PLAYER):
			_fails.append("no " + PLAYER)
			return _finish()
		_box = DialogueBox.new()
		root.add_child(_box)
		_vp = (load(PLAYER) as Script).new()
		_box.add_child(_vp)
		_box.line_started.connect(func(s: StringName, _t: String) -> void: _starts.append([s, frame]))
		_box.queue_emptied.connect(func() -> void: _empty_frame = frame)
		if not (_vp.call(&"has_line", L1[0], L1[1]) and _vp.call(&"has_line", L2[0], L2[1])):
			_fails.append("test lines missing from the voice manifest")
			return _finish()
	elif frame == 4:
		var events := root.get_node_or_null("Events")
		if events == null:
			_fails.append("no Events autoload")
			return _finish()
		events.emit_signal(&"dialogue", L1[0], L1[1])
		events.emit_signal(&"dialogue", L2[0], L2[1])
	elif frame == 4 + 330:   # 5.5 s: past LINE_SECONDS, the voice (5.589 s) is still going
		if _box.current_speaker() != L1[0]:
			_fails.append("first voiced line cut at 5.5 s: showing '%s'" % _box.current_speaker())
		if _box.queued_count() != 1:
			_fails.append("second line should still wait in the queue, queued=%d" % _box.queued_count())
		if _starts.size() != 1:
			_fails.append("second voice started while the first played: %s" % [_starts])
	elif frame == 4 + 380:   # 6.33 s: first line done (5.589 + 0.4 = 5.99 s), second voiced line showing
		if _box.current_speaker() != L2[0]:
			_fails.append("second line not showing at 6.3 s: '%s'" % _box.current_speaker())
		if _starts.size() == 2:
			var held: float = (int(_starts[1][1]) - int(_starts[0][1])) / 60.0
			var want := float(_vp.call(&"line_duration", L1[0], L1[1])) + DialogueBox.VOICE_TAIL
			if held < want - 0.05 or held > want + 0.1:
				_fails.append("first line held %.2f s, expected %.2f s" % [held, want])
			print("  first voiced line held %.2f s (voice %.2f s)" % [held, want - DialogueBox.VOICE_TAIL])
		else:
			_fails.append("expected 2 line starts, got %s" % [_starts])
	elif frame == 800:   # both voiced lines over; now a line without voice
		if _box.is_showing():
			_fails.append("box still showing at frame 800")
		_empty_frame = -1
		_box.say(L3[0], L3[1])
	elif frame == 800 + 330:
		if _empty_frame < 0:
			_fails.append("unvoiced line still up after 5.5 s")
		else:
			var held: float = (_empty_frame - 800) / 60.0
			if absf(held - DialogueBox.LINE_SECONDS) > 0.05:
				_fails.append("unvoiced line held %.2f s, expected %.1f s" % [held, DialogueBox.LINE_SECONDS])
			print("  unvoiced line held %.2f s" % held)
		return _finish()
	return false


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS " + TASK_ID)
	else:
		for f in _fails:
			print("FAIL " + TASK_ID + ": " + f)
	quit(0 if _fails.is_empty() else 1)
	return true
