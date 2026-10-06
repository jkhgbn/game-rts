class_name ChatLine
extends VBoxContainer
## HUD chat / command line (playtest 2026-09-27, JS): Enter opens it (not while a cinematic plays, a dialogue /
## briefing waits for Enter, or a text field has focus), typing + Enter runs the line, Esc closes it. While it is
## open no game hotkey fires (the line eats every key the text field leaves). Commands:
##   "dance 1" = dance_victory, "dance 2" = dance_surrender ("I give up"), "dance 3" = dance_random, on the selected
##   units (all the player's units when nothing is selected; UnitDances). Any order stops the dance.
## Anything else is echoed as a chat line. The last lines fade out after LOG_SECONDS.

signal command_run(text: String, result: String)

const MAX_LINES := 5
const LOG_SECONDS := 8.0
const WIDTH := 440.0

var selection: SelectionManager       ## Set by the HUD (setup); null = every player unit.
var input: LineEdit
var log_box: VBoxContainer
var _lines: Array[Label] = []
var _ages: PackedFloat32Array = PackedFloat32Array()
var _open := false


## Creates the chat line under the HUD's root control.
static func attach(parent: Control) -> ChatLine:
	var c := ChatLine.new()
	c.name = "ChatLine"
	parent.add_child(c)
	return c


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size = Vector2(WIDTH, 0)
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = -330.0
	offset_bottom = -250.0
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	log_box = VBoxContainer.new()
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_box.add_theme_constant_override("separation", 2)
	add_child(log_box)
	input = LineEdit.new()
	input.placeholder_text = "Type a command (dance 1 / 2 / 3) - Enter to send, Esc to close"
	input.custom_minimum_size = Vector2(WIDTH, 32)
	input.max_length = 120
	input.context_menu_enabled = false
	input.add_theme_font_size_override("font_size", 16)
	var sb := UIStyle.slate_style(6.0)
	input.add_theme_stylebox_override("normal", sb)
	input.add_theme_stylebox_override("focus", sb)
	input.visible = false
	input.text_submitted.connect(_on_submitted)
	input.focus_exited.connect(_on_focus_lost)
	add_child(input)
	set_process(false)


## True while the command line is open (typing).
func is_open() -> bool:
	return _open


## Opens the line and focuses it (no checks; the HUD calls try_open on Enter).
func open() -> void:
	_open = true
	input.text = ""
	input.visible = true
	input.grab_focus()
	if input.has_method(&"edit"):
		input.call(&"edit")


## Enter pressed in the game: opens the line unless a cinematic plays, a dialogue / briefing is waiting for Enter or a
## text field already has focus. Returns true when it opened.
func try_open() -> bool:
	if _open or not is_inside_tree():
		return false
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	if CinematicPlayer.is_any_playing(get_tree()):
		return false
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n is DialogueBox and (n as DialogueBox).is_showing():
			return false
		if n is BriefingScreen and (n as Control).is_visible_in_tree():
			return false
	open()
	return true


func close() -> void:
	if not _open:
		return
	_open = false
	input.visible = false
	if input.has_focus():
		input.release_focus()


## Runs one line (what Enter does): returns the reply shown in the log ("" = nothing to show).
func submit(text: String) -> String:
	var t := text.strip_edges()
	if t == "":
		return ""
	var result := run_command(t)
	add_line(result if result != "" else t)
	command_run.emit(t, result)
	return result


## The command behind a line: "dance N" (N = 1 victory, 2 "I give up", 3 random). Returns the reply, "" when the
## text is not a command (then it is just a chat line).
func run_command(text: String) -> String:
	var words := text.to_lower().trim_prefix("/").split(" ", false)
	if words.size() == 0 or words[0] != "dance":
		return ""
	if words.size() != 2 or not words[1].is_valid_int() or int(words[1]) < 1 or int(words[1]) > 3:
		return Loc.t("Usage: dance 1 (victory), dance 2 (I give up), dance 3 (random)")
	var clip: StringName = UnitDances.BY_NUMBER[int(words[1]) - 1]
	var units := target_units()
	var n := UnitDances.play_all(units, clip)
	if n == 0:
		return Loc.t("Nobody here can dance")
	var mood: String = [Loc.t("victory"), Loc.t("I give up"), Loc.t("random")][int(words[1]) - 1]
	return Loc.tn("{n} unit dancing ({mood})", "{n} units dancing ({mood})", n, {"mood": mood})


## The units a command acts on: the selected player units, else every living player unit.
func target_units() -> Array:
	var out: Array = []
	if selection != null and is_instance_valid(selection):
		for u in selection.selected:
			if is_instance_valid(u) and int(u.team) == Unit.Team.PLAYER:
				out.append(u)
	if not out.is_empty():
		return out
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u != null and u.is_alive() and int(u.team) == Unit.Team.PLAYER:
			out.append(u)
	return out


## Adds a line to the log (the oldest goes past MAX_LINES).
func add_line(text: String) -> void:
	var l := UIStyle.panel_label(text, 16)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	log_box.add_child(l)
	_lines.append(l)
	_ages.append(0.0)
	while _lines.size() > MAX_LINES:
		_lines[0].queue_free()
		_lines.remove_at(0)
		_ages.remove_at(0)
	set_process(true)


## The log's texts, oldest first (tests).
func log_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _lines:
		out.append(l.text)
	return out


func _process(delta: float) -> void:
	var i := 0
	while i < _lines.size():
		_ages[i] += delta
		var a: float = _ages[i]
		if a >= LOG_SECONDS and not _open:
			_lines[i].queue_free()
			_lines.remove_at(i)
			_ages.remove_at(i)
			continue
		_lines[i].modulate.a = 1.0 if _open else clampf((LOG_SECONDS - a) / 1.0, 0.0, 1.0)
		i += 1
	if _lines.is_empty():
		set_process(false)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## While open, every key the text field did not take stops here: no game hotkey fires.
func _shortcut_input(event: InputEvent) -> void:
	if _open and event is InputEventKey:
		get_viewport().set_input_as_handled()


func _on_submitted(text: String) -> void:
	submit(text)
	close()


func _on_focus_lost() -> void:
	# Clicked elsewhere: the line closes (the typed text is dropped).
	if _open:
		close.call_deferred()
