class_name MusterButton
extends Button
## Coffer / next tier button of the Muster panel (docs/design/ui-wave-strike.md 1.3): 160 x 40, button frame 3.3, two
## text lines (font 13 / 11) left after a 20 x 14 key badge at (4, 4); `primary` = the trim_glow look (6.4);
## `progress` >= 0 draws a 4 px GOLD line along the bottom edge (a rising tier). Tooltip rows like MusterCard.

const SIZE := Vector2(160, 40)

var line1: Label
var line2: Label
var key := ""
var progress := -1.0
var dim := false
var tip_rows: Array = []
var _primary := false
var _skin := -1


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	line1 = _line(Vector2(28, 3), 13, &"text")
	line2 = _line(Vector2(28, 20), 11, &"text_muted")


func _line(pos: Vector2, fs: int, col: StringName) -> Label:
	var l := UIStyle.panel_label("", fs, UIStyle.token(col))
	l.set_meta(&"tok", col)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = Vector2(SIZE.x - pos.x - 4, fs + 4)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(l)
	return l


## `t2_short`: shown instead of `t2` when `t2` does not fit even at font 10 (the tooltip keeps the long text).
func set_content(p_key: String, t1: String, t2: String, primary: bool, p_dim: bool, p_progress: float, rows: Array,
		t2_short := "") -> void:
	if _skin != UIStyle.skin_version or primary != _primary:
		_skin = UIStyle.skin_version
		_primary = primary
		UIStyle.style_button(self)
		if primary:
			add_theme_stylebox_override("normal", UIStyle.primary_button_frame())
		for l: Label in [line1, line2]:
			l.add_theme_color_override("font_color", UIStyle.token(StringName(l.get_meta(&"tok"))))
	key = p_key
	var x := 28.0 if key != "" else 8.0
	line1.position.x = x
	line2.position.x = x
	line1.size.x = SIZE.x - x - 4.0
	line2.size.x = SIZE.x - x - 4.0
	line1.text = t1
	_fit_line2(t2, t2_short)
	line2.visible = t2 != ""
	if t2 == "":
		line1.position.y = 11.0
	else:
		line1.position.y = 3.0
	dim = p_dim
	disabled = dim   # 1.3: disabled while the reason stands (keys still answer with the reason)
	modulate.a = 0.45 if dim else 1.0
	progress = p_progress
	tip_rows = rows
	var plain: PackedStringArray = []
	for r: Array in rows:
		plain.append(String(r[0]))
	tooltip_text = "\n".join(plain)
	queue_redraw()


func _fit_line2(t2: String, t2_short: String) -> void:
	var font := line2.get_theme_font(&"font")
	var avail := line2.size.x - 4.0
	var fs := 11
	var text := t2
	if font != null and font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x > avail:
		if t2_short != "":
			text = t2_short
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x > avail:
			fs = 10
	UIStyle.set_font_size_if_changed(line2, &"font_size", fs)
	line2.text = text


func _draw() -> void:
	if key != "":
		var font := get_theme_default_font()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.75)
		sb.border_color = UIStyle.token(&"frame_dark")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		var r := Rect2(4, 4, 20, 14)
		draw_style_box(sb, r)
		draw_string(font, Vector2(4, 15), key, HORIZONTAL_ALIGNMENT_CENTER, 20, 11, UIStyle.GOLD)
	if progress >= 0.0:
		draw_rect(Rect2(3, SIZE.y - 7, SIZE.x - 6, 4), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(3, SIZE.y - 7, (SIZE.x - 6) * clampf(progress, 0.0, 1.0), 4), UIStyle.GOLD)


func _make_custom_tooltip(_for_text: String) -> Object:
	return MusterCard.tip_panel(tip_rows)
