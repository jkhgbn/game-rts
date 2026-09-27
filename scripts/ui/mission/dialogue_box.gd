class_name DialogueBox
extends PanelContainer
## Mission dialogue box (task M7.U1, mission-01.md "Dialogue"): bottom-centre, 640 wide, its bottom edge at
## y 610 on a 1600 x 900 screen (just above the control group tabs at y 620). Heavy frame (ui-style.md 3.1).
## Listens to Events.dialogue(speaker, text); lines are queued and each shows LINE_SECONDS.
## Enter (physical, also keypad Enter) or a click on the box skips to the next line.
## The speaker name uses the speaker's colour (SPEAKER_COLORS; unknown speakers use the `title` token).

const LINE_SECONDS := 5.0
const WIDTH := 640.0
const BOTTOM_GAP := 290.0   ## Distance from the screen bottom to the box's bottom edge (900 - 610).
const FADE := 0.15
const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"pell": Color(0.85, 0.75, 0.5),
}

signal line_started(speaker: StringName, text: String)
signal queue_emptied

var _queue: Array = []        # [[speaker, text], ...] waiting
var _speaker := &""
var _time_left := 0.0
var _showing := false
var _name_label: Label
var _text_label: Label
var _hint: Label
var _timer_bar: Control
var _skin := -1
var _fade: Tween


func _ready() -> void:
	name = "DialogueBox"
	mouse_filter = Control.MOUSE_FILTER_STOP   # a click on the box skips the line
	custom_minimum_size = Vector2(WIDTH, 0)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = -BOTTOM_GAP
	offset_bottom = -BOTTOM_GAP
	UIStyle.add_drop_shadow(self)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	_name_label = UIStyle.display_label("", 15)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_name_label)
	_hint = UIStyle.panel_label("Enter / click: next", 11, UIStyle.token(&"text_muted"))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_hint)
	_text_label = UIStyle.panel_label("", 17)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(WIDTH - 28, 0)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_text_label)
	# Thin time bar along the bottom: how long this line stays.
	_timer_bar = Control.new()
	_timer_bar.custom_minimum_size = Vector2(0, 2)
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_bar.draw.connect(_draw_timer)
	box.add_child(_timer_bar)
	apply_skin()
	visible = false
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.connect(&"dialogue", say)


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	add_theme_stylebox_override("panel", UIStyle.frame_style(14.0))
	_text_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
	_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	if _showing:
		_name_label.add_theme_color_override("font_color", speaker_color(_speaker))


# --- Public ------------------------------------------------------------------------------------------

## Queues a line (Events.dialogue calls this). Shows at once when nothing is showing.
func say(speaker: StringName, text: String) -> void:
	_queue.append([speaker, text])
	if not _showing:
		_next()


## Ends the current line now and shows the next one (Enter / click).
func skip() -> void:
	if _showing:
		_next()


func is_showing() -> bool:
	return _showing


func current_speaker() -> StringName:
	return _speaker if _showing else &""


func current_text() -> String:
	return _text_label.text if _showing else ""


func queued_count() -> int:
	return _queue.size()


func name_color() -> Color:
	return _name_label.get_theme_color(&"font_color")


static func speaker_color(speaker: StringName) -> Color:
	return SPEAKER_COLORS.get(StringName(String(speaker).to_lower()), UIStyle.token(&"title"))


static func speaker_name(speaker: StringName) -> String:
	return String(speaker).replace("_", " ").capitalize()


# --- Internals ---------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()
	if not _showing:
		return
	_time_left -= delta
	_timer_bar.queue_redraw()
	if _time_left <= 0.0:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_showing = false
		_speaker = &""
		_fade_to(0.0)
		_fade.tween_callback(func() -> void:
			if not _showing:
				visible = false)
		queue_emptied.emit()
		return
	var line: Array = _queue.pop_front()
	_speaker = StringName(line[0])
	_showing = true
	_time_left = LINE_SECONDS
	_name_label.text = speaker_name(_speaker)
	_name_label.add_theme_color_override("font_color", speaker_color(_speaker))
	_text_label.text = str(line[1])
	visible = true
	_fade_to(1.0)
	reset_size()
	offset_top = -BOTTOM_GAP - size.y
	offset_bottom = -BOTTOM_GAP
	line_started.emit(_speaker, _text_label.text)


func _fade_to(alpha: float) -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, FADE)


func _draw_timer() -> void:
	var w := _timer_bar.size.x
	_timer_bar.draw_rect(Rect2(0, 0, w, 2), Color(0, 0, 0, 0.35))
	var f := clampf(_time_left / LINE_SECONDS, 0.0, 1.0) if _showing else 0.0
	_timer_bar.draw_rect(Rect2(0, 0, w * f, 2), Color(speaker_color(_speaker), 0.7))


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _showing:
		skip()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _showing:
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		skip()
		get_viewport().set_input_as_handled()
