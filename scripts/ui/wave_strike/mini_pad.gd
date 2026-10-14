class_name WsMiniPad
extends Control
## The 2D mini-pad of the Muster panel (docs/design/ui-wave-strike.md 7.6): a slate 114 x 86 with the 16 x 12 cells of
## the own pad at 7 px (front edge on top, 1 px GOLD), tokens as rounded squares in the role colour (5 x 5 for 1x1,
## 12 x 12 for 2x2), hatched when moved after the horn, dimmed when held, 2 px gold corners per upgrade. Hover a token
## = its tooltip (7.5); click a cell = the camera centres on it behind the pad (P-like). No placing in 2D.

const SIZE := Vector2(114, 86)
const CELL := 7.0

var view: MusterPadView
var input: MusterPadInput
var _flash := 0.0
var _hover := Vector2i(-1, -1)


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "
	set_process(false)


func setup(p_view: MusterPadView, p_input: MusterPadInput) -> void:
	view = p_view
	input = p_input
	view.rebuilt.connect(queue_redraw)
	name = "MiniPad"


## The border flashes WARN for 0.3 s (`No room on the pad`).
func flash() -> void:
	_flash = 0.3
	set_process(true)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if _flash <= 0.0:
		set_process(false)


func cell_at(p: Vector2) -> Vector2i:
	var c := Vector2i(floori((p.x - 1.0) / CELL), floori((p.y - 1.0) / CELL))
	return c if MusterPad.in_bounds(c) else MusterPad.NONE


func _gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and input != null:
		var c := cell_at(mb.position)
		if c != MusterPad.NONE:
			input.focus_cell(c)
			accept_event()
	var mm := ev as InputEventMouseMotion
	if mm != null:
		var c := cell_at(mm.position)
		if c != _hover:
			_hover = c
			queue_redraw()


func _get_tooltip(at: Vector2) -> String:
	if view == null:
		return ""
	var c := cell_at(at)
	if c == MusterPad.NONE:
		return Loc.t("Your Muster Pad: click a cell to look at it")
	var i := view.token_at(c)
	if i < 0:
		return Loc.t("Cell (%d, %d)") % [c.x, c.y]
	var lines: PackedStringArray = []
	for r: Array in MusterPadInput.token_tip(view, i):
		lines.append(String(r[0]))
	return "\n".join(lines)


func _make_custom_tooltip(for_text: String) -> Object:
	if view == null or for_text == "":
		return null
	var i := view.token_at(_hover)
	if i >= 0:
		return MusterCard.tip_panel(MusterPadInput.token_tip(view, i))
	return MusterCard.tip_panel([[for_text, UIStyle.token(&"text"), 13]])


func _draw() -> void:
	var sb := UIStyle.slate_style(0.0, UIStyle.token(&"frame_metal"))
	draw_style_box(sb, Rect2(Vector2.ZERO, SIZE))
	var light := Color(UIStyle.token(&"frame_light"), 0.18)
	for c in MusterPad.COLS + 1:
		var x := 1.0 + c * CELL
		draw_line(Vector2(x, 1), Vector2(x, 1 + MusterPad.ROWS * CELL), Color(light, 0.30) if c % 4 == 0 else light, 1.0)
	for r in MusterPad.ROWS + 1:
		var y := 1.0 + r * CELL
		draw_line(Vector2(1, y), Vector2(1 + MusterPad.COLS * CELL, y), light, 1.0)
	draw_line(Vector2(1, 1), Vector2(1 + MusterPad.COLS * CELL, 1), UIStyle.GOLD, 1.0)
	if view == null:
		return
	for t in view.tokens():
		var cell: Vector2i = t["cell"]
		var s := int(t["size"])
		var side := 5.0 if s == 1 else 12.0
		var origin := Vector2(1 + cell.x * CELL, 1 + cell.y * CELL)
		var r := Rect2(origin + Vector2.ONE * (s * CELL - side) * 0.5, Vector2(side, side))
		var col: Color = MusterPadView.ROLE_COLORS.get(t["role"], MusterPadView.ROLE_COLORS[&"melee"])
		if bool(t.get("held", false)):
			col.a = 0.45
		var box := StyleBoxFlat.new()
		box.bg_color = col
		box.set_corner_radius_all(1 if s == 1 else 2)
		draw_style_box(box, r)
		if bool(t.get("moved", false)):
			var k := 0.0
			while k < r.size.x * 2.0:
				var a := r.position + Vector2(k, 0)
				var b := a + Vector2(-r.size.y, r.size.y)
				var seg := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]),
						PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end,
						r.position + Vector2(0, r.size.y)]))
				for pl: PackedVector2Array in seg:
					draw_polyline(pl, Color(0, 0, 0, 0.55), 1.0)
				k += 3.0
		var up := int(t.get("up", 0))
		if up & 1:
			draw_rect(Rect2(Vector2(r.end.x - 2, r.position.y), Vector2(2, 2)), UIStyle.GOLD)
		if up & 2:
			draw_rect(Rect2(r.position, Vector2(2, 2)), UIStyle.GOLD)
	if _hover != MusterPad.NONE:
		draw_rect(Rect2(Vector2(1 + _hover.x * CELL, 1 + _hover.y * CELL), Vector2(CELL, CELL)),
				Color(UIStyle.token(&"trim_glow"), 0.6), false, 1.0)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(UIStyle.WARN, _flash / 0.3), false, 2.0)


## A 108 x 24 pad button (button frame 3.3, font 12, key badge 20 x 14) or the 50 x 24 compact one.
class SmallButton extends Button:
	var key := ""
	var label := ""
	var tip_rows: Array = []
	var _skin := -1

	func _init(w := 108.0) -> void:
		custom_minimum_size = Vector2(w, 24)
		size = custom_minimum_size
		focus_mode = Control.FOCUS_NONE
		for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func set_content(p_key: String, p_label: String, rows: Array, dim := false) -> void:
		key = p_key
		label = p_label
		tip_rows = rows
		disabled = dim
		modulate.a = 0.45 if dim else 1.0
		var plain: PackedStringArray = []
		for r: Array in rows:
			plain.append(String(r[0]))
		tooltip_text = "\n".join(plain)
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
			queue_redraw()

	func _draw() -> void:
		var state := &"pressed" if is_pressed() else (&"hover" if is_hovered() and not disabled else &"normal")
		var rim := UIStyle.token(&"frame_light") if state == &"hover" else UIStyle.token(&"frame_metal")
		draw_style_box(UIStyle.button_frame(state, rim), Rect2(Vector2.ZERO, size))
		var font := get_theme_default_font()
		var x := 6.0
		if key != "":
			var kw := maxf(20.0, font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0.75)
			sb.border_color = UIStyle.token(&"frame_dark")
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(2)
			draw_style_box(sb, Rect2(4, 5, kw, 14))
			draw_string(font, Vector2(4, 16), key, HORIZONTAL_ALIGNMENT_CENTER, kw, 11, UIStyle.GOLD)
			x = 8.0 + kw
		var avail := size.x - x - 4.0
		var fs := 12
		if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > avail:
			fs = 11 if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= avail else 10
		draw_string(font, Vector2(x, 16), label, HORIZONTAL_ALIGNMENT_LEFT, avail, fs, UIStyle.token(&"text"))

	func _make_custom_tooltip(_for_text: String) -> Object:
		return MusterCard.tip_panel(tip_rows)
