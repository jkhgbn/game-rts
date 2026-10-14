class_name ArmouryButton
extends Button
## One Armoury line button of the Muster panel (docs/design/ui-wave-strike.md 8.2, task WS4.U1): 108 x 40, button
## frame 3.3, key badge 20 x 14 at (4, 4) (R / Y / O), a 24 px glyph drawn in code (crossed blades / kite shield / rune
## circle), `Weapons II` + level pips (diamonds), the next price (crystal diamond + number, WARN when short; `Max` in
## GOLD at the top level). Gated = dim + a lock over the price; max = GOLD rim, disabled. Bought flash: trim_glow rim
## 0.4 s, the new pip pops. The compact form (50 x 40) shows the glyph and pips only (text in the tooltip).

const SIZE := Vector2(108, 40)
const COMPACT := Vector2(50, 40)
const FLASH_TIME := 0.4
const POP_TIME := 0.5

var line: StringName = &"weapons"
var key := ""
var title := ""
var level := 0
var max_level := 3
var price := -1
var short := false
var gated := false
var compact := false
var tip_rows: Array = []
var _flash := 0.0
var _pop := 0.0
var _frames: Dictionary = {}
var _skin := -1


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	set_process(false)


func set_compact(on: bool) -> void:
	compact = on
	custom_minimum_size = COMPACT if on else SIZE
	size = custom_minimum_size
	queue_redraw()


## New state from the panel.
func set_state(p_key: String, p_title: String, p_level: int, p_max: int, p_price: int, p_short: bool, p_gated: bool,
		rows: Array) -> void:
	if p_level > level and level >= 0 and title != "":
		play_bought()
	key = p_key
	title = p_title
	level = p_level
	max_level = p_max
	price = p_price
	short = p_short
	gated = p_gated
	tip_rows = rows
	var maxed := level >= max_level
	disabled = maxed
	modulate.a = 0.45 if gated and not maxed else 1.0
	var plain: PackedStringArray = []
	for r: Array in rows:
		plain.append(String(r[0]))
	tooltip_text = "\n".join(plain)
	queue_redraw()


func play_bought() -> void:
	_flash = FLASH_TIME
	_pop = POP_TIME
	set_process(true)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_pop = maxf(0.0, _pop - delta)
	queue_redraw()
	if _flash <= 0.0 and _pop <= 0.0 and not is_hovered():
		set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()


func _frame(state: StringName, rim: Color) -> StyleBox:
	if _skin != UIStyle.skin_version:
		_skin = UIStyle.skin_version
		_frames.clear()
	var k := "%s_%s" % [state, rim.to_html()]
	if not _frames.has(k):
		_frames[k] = UIStyle.button_frame(state, rim)
	return _frames[k]


func _draw() -> void:
	var maxed := level >= max_level
	var state := &"normal"
	var rim := UIStyle.GOLD if maxed else UIStyle.token(&"frame_metal")
	if is_pressed():
		state = &"pressed"
		rim = UIStyle.token(&"frame_dark")
	elif is_hovered() and not maxed:
		state = &"hover"
		rim = UIStyle.token(&"frame_light")
	if _flash > 0.0:
		rim = rim.lerp(UIStyle.token(&"trim_glow"), _flash / FLASH_TIME)
	draw_style_box(_frame(state, rim), Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var nf := UIStyle.number_font()
	var off := Vector2(1, 1) if state == &"pressed" else Vector2.ZERO
	if key != "" and not maxed:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.75)
		sb.border_color = UIStyle.token(&"frame_dark")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		draw_style_box(sb, Rect2(4, 4, 20, 14))
		draw_string(font, Vector2(4, 15), key, HORIZONTAL_ALIGNMENT_CENTER, 20, 11, UIStyle.GOLD)
	var gx := 6.0 if not compact else 13.0
	_draw_glyph(Vector2(gx + 12, 10 + 13 + (2.0 if not compact else 0.0)) + off, UIStyle.token(&"text"))
	# level pips: diamonds, filled GOLD per level
	var px := 34.0 if not compact else 25.0 - (max_level - 1) * 4.0
	var py := 23.0 if not compact else 35.0
	for j in max_level:
		var c := Vector2(px + 8 * j + 3, py + 3) + off
		var half := 3.0
		if j == level - 1 and _pop > 0.0:
			half *= 1.0 + 0.6 * sin((1.0 - _pop / POP_TIME) * PI)
		var col := UIStyle.GOLD if j < level else Color(0.3, 0.3, 0.3)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -half), c + Vector2(half, 0), c + Vector2(0, half),
				c + Vector2(-half, 0)]), col)
	if compact:
		return
	var t := title
	var fs := 13
	if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > size.x - 38.0:
		fs = 11
	draw_string(font, Vector2(34, 17) + off, t, HORIZONTAL_ALIGNMENT_LEFT, size.x - 38.0, fs, UIStyle.token(&"text"))
	if maxed:
		var mt := Loc.t("Max")
		var w := font.get_string_size(mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(102 - w, 34) + off, mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UIStyle.GOLD)
		return
	if price < 0:
		return
	var ps := str(price)
	var w := nf.get_string_size(ps, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var x := 102.0 - w
	if gated:
		_draw_lock(Vector2(x - 8, 29) + off)
	else:
		var c := Vector2(x - 7, 30) + off
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4),
				c + Vector2(-4, 0)]), UIStyle.CRYSTAL)
	draw_string(nf, Vector2(x, 34) + off, ps, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			UIStyle.WARN if short else UIStyle.CRYSTAL_TEXT)


## 10 x 12 lock glyph centred on `c`.
func _draw_lock(c: Vector2) -> void:
	var col := UIStyle.WARN
	draw_rect(Rect2(c + Vector2(-5, -1), Vector2(10, 7)), col)
	draw_arc(c + Vector2(0, -1), 3.2, PI, TAU, 8, col, 1.6)


## The line's glyph (24 px) centred on `c`: crossed blades / kite shield / rune circle.
func _draw_glyph(c: Vector2, col: Color) -> void:
	match line:
		&"weapons":
			for s: float in [-1.0, 1.0]:
				var a := c + Vector2(-9 * s, 9)
				var b := c + Vector2(8 * s, -9)
				draw_line(a, b, col, 2.4)
				var n := (b - a).normalized()
				var p := Vector2(-n.y, n.x)
				var guard := a + n * 5.0
				draw_line(guard - p * 3.5, guard + p * 3.5, col, 2.0)
		&"armour":
			var pts := PackedVector2Array([c + Vector2(-9, -10), c + Vector2(9, -10), c + Vector2(9, -1),
					c + Vector2(0, 11), c + Vector2(-9, -1)])
			draw_colored_polygon(pts, Color(col, 0.25))
			pts.append(pts[0])
			draw_polyline(pts, col, 2.0)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 7), col, 1.5)
		_:
			draw_arc(c, 10.0, 0.0, TAU, 28, col, 1.8)
			draw_arc(c, 6.0, 0.0, TAU, 20, Color(col, 0.6), 1.2)
			for k in 3:
				var ang := -PI * 0.5 + TAU * k / 3.0
				draw_line(c + Vector2(cos(ang), sin(ang)) * 6.0, c + Vector2(cos(ang), sin(ang)) * 10.0, col, 1.6)


func _make_custom_tooltip(_for_text: String) -> Object:
	return MusterCard.tip_panel(tip_rows)
