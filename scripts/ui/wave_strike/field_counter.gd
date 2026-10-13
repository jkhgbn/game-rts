class_name WsFieldCounter
extends Control
## The Wave Strike field counter (docs/design/ui-wave-strike.md 3): 160 x 54 slate box, `On the field` / `187 / 200`
## (orange from 90 %, WARN at the cap) and, when the valve held units back at the last horn, `12 held at home` in WARN
## with a pause glyph; the border pulses WARN for 3 s after such a horn.

const SIZE := Vector2(160, 54)
const PULSE_TIME := 3.0
const NEAR := Color(1.0, 0.75, 0.3)

var title: Label
var count_label: Label
var held_label: Label
var held := 0
var _pulse := 0.0
var _clock := 0.0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	title = _label(Vector2(8, 0), 12)
	count_label = _label(Vector2(8, 16), 16)
	count_label.add_theme_font_override("font", UIStyle.number_font())
	count_label.add_theme_constant_override("outline_size", 0)
	held_label = _label(Vector2(22, 38), 11)
	held_label.add_theme_color_override("font_color", UIStyle.WARN)


func _label(pos: Vector2, fs: int) -> Label:
	var l := UIStyle.panel_label("", fs)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = Vector2(SIZE.x - pos.x - 4, fs + 5)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(l)
	return l


func set_counts(on_field: int, cap: int, p_held: int) -> void:
	title.text = Loc.t("On the field")
	title.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	count_label.text = "%d / %d" % [on_field, cap] if cap > 0 else str(on_field)
	var col := UIStyle.token(&"text")
	if cap > 0 and on_field >= cap:
		col = UIStyle.WARN
	elif cap > 0 and on_field >= int(ceil(cap * 0.9)):
		col = NEAR
	count_label.add_theme_color_override("font_color", col)
	if p_held > held:
		_pulse = PULSE_TIME   # the valve just held units back (they are counted while the horn's units spawn)
	held = p_held
	held_label.visible = held > 0
	held_label.text = Loc.tn("{n} held at home", "{n} held at home", held)
	tooltip_text = Loc.tn("Lane cap reached: {n} unit of this horn waits at the Bastion and marches with the next horn",
			"Lane cap reached: {n} units of this horn wait at the Bastion and march with the next horn", held) if held > 0 else ""
	queue_redraw()


func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta)
		_clock += delta
		queue_redraw()


func _draw() -> void:
	var border := UIStyle.token(&"frame_metal")
	if _pulse > 0.0:
		border = Color(UIStyle.WARN, 0.65 + 0.25 * sin(_clock * TAU * 1.5))
	var st := UIStyle.slate_style(0.0, border)
	draw_style_box(st, Rect2(Vector2.ZERO, SIZE))
	if held > 0:
		# pause glyph 10 px before the held line
		var y := 41.0
		draw_rect(Rect2(9, y, 3, 10), UIStyle.WARN)
		draw_rect(Rect2(15, y, 3, 10), UIStyle.WARN)


func _make_custom_tooltip(for_text: String) -> Object:
	return MusterCard.tip_panel([[for_text, UIStyle.token(&"text"), 13]]) if for_text != "" else null
