class_name CinematicOverlay
extends CanvasLayer
## Letterbox bars, subtitles, skip prompt, paused view, full-screen fades and title card (cinematics.md 6,
## prologue 2.1 / 2.5). CanvasLayer 85: above the HUD / briefing (80), below the pause menu (90).
## Driven by CinematicPlayer; runs with PROCESS_MODE_ALWAYS so it works while the tree is paused.

const LAYER := 85
const BAR_IN_TIME := 0.4
const BAR_OUT_TIME := 0.3
const LINE_FADE := 0.15
const SKIP_PROMPT_TIME := 2.5
const HINT_TIME := 3.0
const CURSOR_HIDE_AFTER := 2.0
const SUB_WIDTH_FRAC := 0.7
const SUB_MIN_BAR := 80.0

var aspect := 2.39
var subtitles_enabled := true
## Recording / tools: bars and fades jump to their final value instead of animating.
var instant := false

var _bars_open := false
var _bar_k := 0.0              # 0 = no bars, 1 = full bars
var _top: ColorRect
var _bottom: ColorRect
var _fade: ColorRect
var _sub_strip: ColorRect
var _sub_box: VBoxContainer
var _speaker_label: Label
var _text_label: Label
var _line_left := 0.0          # seconds the current line stays (fade out at the end)
var _line_alpha := 0.0
var _line_on := false
var _skip_label: Label
var _skip_left := 0.0
var _hint_label: Label
var _hint_left := 0.0
var _dim: ColorRect
var _pause_label: Label
var _title_box: VBoxContainer
var _title_label: Label
var _sub_title_label: Label
var _title_left := 0.0
var _title_total := 0.0
var _still := 0.0
var _cursor_hidden := false


## Bar height (each) for a screen and an aspect: max((H - W / A) / 2, 0.03 x H) (cinematics.md 6.1). 0 aspect = 0.
static func bar_height(screen: Vector2, p_aspect: float) -> float:
	if p_aspect <= 0.0 or screen.y <= 0.0:
		return 0.0
	return roundf(maxf((screen.y - screen.x / p_aspect) * 0.5, 0.03 * screen.y))


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "CinematicOverlay"


func _ready() -> void:
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _build() -> void:
	_fade = _rect(Color(0, 0, 0, 0))
	_top = _rect(Color.BLACK)
	_bottom = _rect(Color.BLACK)
	_sub_strip = _rect(Color(0, 0, 0, 0.45))
	_sub_strip.visible = false
	_sub_box = VBoxContainer.new()
	_sub_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub_box.alignment = BoxContainer.ALIGNMENT_END
	_sub_box.add_theme_constant_override("separation", 2)
	add_child(_sub_box)
	_speaker_label = _label(20, HORIZONTAL_ALIGNMENT_CENTER, _sub_box)
	_text_label = _label(22, HORIZONTAL_ALIGNMENT_CENTER, _sub_box)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.max_lines_visible = 2
	_sub_box.modulate.a = 0.0
	_title_box = VBoxContainer.new()
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_title_box)
	_title_label = _label(56, HORIZONTAL_ALIGNMENT_CENTER, _title_box)
	_sub_title_label = _label(24, HORIZONTAL_ALIGNMENT_CENTER, _title_box)
	_title_box.visible = false
	_skip_label = _label(18, HORIZONTAL_ALIGNMENT_RIGHT)
	_skip_label.text = "Esc / Space: skip"
	_skip_label.visible = false
	_hint_label = _label(16, HORIZONTAL_ALIGNMENT_RIGHT)
	_hint_label.text = "P: pause · Enter: next line · Esc / Space: skip"
	_hint_label.visible = false
	_dim = _rect(Color(0, 0, 0, 0.3))
	_dim.visible = false
	_pause_label = _label(28, HORIZONTAL_ALIGNMENT_CENTER)
	_pause_label.text = "Paused · P: resume · Esc / Space: skip"
	_pause_label.visible = false


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _label(px: int, align: HorizontalAlignment, parent: Node = null) -> Label:
	var l := Label.new()
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	(parent if parent != null else self).add_child(l)
	return l


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1600, 900)


## Current bar height in px (animated).
func current_bar() -> float:
	return bar_height(_screen(), aspect) * _bar_k


func is_open() -> bool:
	return _bars_open


# ------------------------------------------------------------------ public API (cinematics.md 11)

func open(p_aspect: float) -> void:
	aspect = p_aspect
	_bars_open = true
	if instant:
		_bar_k = 1.0
	visible = true
	_layout()


func close() -> void:
	_bars_open = false
	if instant:
		_bar_k = 0.0
	end_line()
	_skip_left = 0.0
	_title_left = 0.0
	set_paused_view(false)
	set_fade(Color.BLACK, 0.0)
	if _cursor_hidden:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_cursor_hidden = false
	_layout()


func show_line(speaker: StringName, text: String, duration: float) -> void:
	if not subtitles_enabled:
		return
	_speaker_label.text = Speakers.name_of(speaker) if speaker != &"" else ""
	_speaker_label.add_theme_color_override("font_color", Speakers.color_of(speaker))
	_speaker_label.visible = speaker != &""
	_text_label.text = text
	_line_left = maxf(duration, 0.0)
	_line_on = true
	_layout()


func end_line() -> void:
	_line_on = false
	_line_left = 0.0
	if instant and _sub_box:
		_line_alpha = 0.0
		_sub_box.modulate.a = 0.0


## Text of the line on screen ("" = none).
func current_line_text() -> String:
	return _text_label.text if _line_on else ""


func show_skip_prompt() -> void:
	_skip_left = SKIP_PROMPT_TIME
	_skip_label.visible = true


func hide_skip_prompt() -> void:
	_skip_left = 0.0
	_skip_label.visible = false


func is_skip_prompt_shown() -> bool:
	return _skip_left > 0.0


func set_paused_view(on: bool) -> void:
	if _dim == null:
		return
	_dim.visible = on
	_pause_label.visible = on


func is_paused_view() -> bool:
	return _dim != null and _dim.visible


## Full-screen fade colour / alpha (the player computes it per frame from the timeline).
func set_fade(c: Color, a: float) -> void:
	if _fade:
		_fade.color = Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))


func fade_alpha() -> float:
	return _fade.color.a if _fade else 0.0


func show_title(text: String, sub: String = "", time: float = 3.0) -> void:
	_title_label.text = text
	_sub_title_label.text = sub
	_sub_title_label.visible = sub != ""
	_title_total = maxf(time, 0.1)
	_title_left = _title_total
	_title_box.visible = true
	_layout()


func hide_title() -> void:
	_title_left = 0.0
	_title_box.visible = false


func is_title_shown() -> bool:
	return _title_box != null and _title_box.visible


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	var target := 1.0 if _bars_open else 0.0
	if _bar_k != target:
		var step := delta / (BAR_IN_TIME if _bars_open else BAR_OUT_TIME)
		_bar_k = move_toward(_bar_k, target, step)
		_layout()
	if _line_on:
		_line_alpha = minf(1.0, _line_alpha + delta / LINE_FADE)
		_line_left -= delta
		if _line_left <= 0.0:
			_line_on = false
	else:
		_line_alpha = maxf(0.0, _line_alpha - delta / LINE_FADE)
	_sub_box.modulate.a = _line_alpha
	_sub_strip.visible = _line_alpha > 0.0 and bar_height(_screen(), aspect) * _bar_k < SUB_MIN_BAR
	if _skip_left > 0.0:
		_skip_left -= delta
		if _skip_left <= 0.0:
			_skip_label.visible = false
	if _hint_left > 0.0:
		_hint_left -= delta
		_hint_label.visible = _hint_left > 0.0
	if _title_left > 0.0:
		_title_left -= delta
		var a := clampf(minf(_title_total - _title_left, _title_left) / 0.5, 0.0, 1.0)
		_title_box.modulate.a = a
		if _title_left <= 0.0:
			_title_box.visible = false
	if _bars_open and DisplayServer.get_name() != "headless":
		_still += delta
		if _still > CURSOR_HIDE_AFTER and not _cursor_hidden:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_cursor_hidden = true


func _input(event: InputEvent) -> void:
	if not _bars_open:
		return
	if event is InputEventMouseMotion:
		_still = 0.0
		_hint_left = HINT_TIME
		_hint_label.visible = true
		if _cursor_hidden:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_cursor_hidden = false
	elif event is InputEventMouseButton:
		get_viewport().set_input_as_handled()   # clicks do nothing during a cinematic


func _layout() -> void:
	if _top == null:
		return
	var s := _screen()
	var bar := bar_height(s, aspect) * _bar_k
	_top.position = Vector2.ZERO
	_top.size = Vector2(s.x, bar)
	_bottom.position = Vector2(0, s.y - bar)
	_bottom.size = Vector2(s.x, bar)
	_top.visible = bar > 0.0
	_bottom.visible = bar > 0.0
	_fade.position = Vector2.ZERO
	_fade.size = s
	_dim.position = Vector2.ZERO
	_dim.size = s
	var ks := s.y / 900.0
	_text_label.add_theme_font_size_override("font_size", int(round(22.0 * ks)))
	_speaker_label.add_theme_font_size_override("font_size", int(round(19.0 * ks)))
	var w := s.x * SUB_WIDTH_FRAC
	var sub_h := 3.4 * 22.0 * ks + 6.0
	var y := s.y - sub_h - 8.0 * ks
	if bar < SUB_MIN_BAR:
		y = s.y - bar - sub_h - 10.0 * ks
	_sub_box.position = Vector2((s.x - w) * 0.5, y)
	_sub_box.size = Vector2(w, sub_h)
	_sub_strip.position = Vector2((s.x - w) * 0.5 - 12.0, y - 4.0)
	_sub_strip.size = Vector2(w + 24.0, sub_h + 8.0)
	_title_box.position = Vector2(0, s.y * 0.35)
	_title_box.size = Vector2(s.x, s.y * 0.3)
	var margin := 24.0 * ks
	_skip_label.position = Vector2(s.x * 0.5, s.y - maxf(bar, 30.0 * ks) * 0.5 - 12.0 * ks)
	_skip_label.size = Vector2(s.x * 0.5 - margin, 24.0 * ks)
	_hint_label.position = Vector2(s.x * 0.3, maxf(bar, 30.0 * ks) * 0.5 - 10.0 * ks)
	_hint_label.size = Vector2(s.x * 0.7 - margin, 24.0 * ks)
	_pause_label.position = Vector2(0, s.y * 0.5 - 20.0 * ks)
	_pause_label.size = Vector2(s.x, 40.0 * ks)
