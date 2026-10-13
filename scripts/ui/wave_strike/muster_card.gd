class_name MusterCard
extends Button
## One card of the Wave Strike Muster panel (docs/design/ui-wave-strike.md 1.1 / 1.2, task WS2.U1): 72 x 118, drawn in
## `_draw` (frame with the kingdom rim, art slot, key badge, role tag, price / pop / copies, rank pips) plus one Label for
## the 2-line name (autowrap, shrinks to font 10, then ellipsis). The panel feeds it with `set_data(d)` every refresh
## and triggers the small animations (buy pulse, rank-up pop, sell, refusal shake, tier-open flash).
## Mouse: left = buy, Ctrl+left = rank up, Alt+left / right = sell -> signal `action(slot, kind)`.

signal action(slot: int, kind: StringName)   ## kind: &"buy" / &"rank" / &"sell"

const SIZE := Vector2(72, 118)
const ART := Rect2(4, 4, 64, 64)
const BADGE := Rect2(2, 2, 20, 14)
const ROLE := Rect2(38, 56, 32, 12)
const BUY_TIME := 0.35
const RANK_TIME := 0.5
const SHAKE_TIME := 0.3
const FLOAT_TIME := 0.6
const OPEN_TIME := 0.4
const HOVER_FADE := 0.08
const LOCK_FADE := 0.3

var slot := 0
## Data from the panel: id, name, abbrev, icon, key, role, price, pop, count, max, rank, why, locked, empty,
## crystals_short, supply_short, maxed, tip (Array of [text, color, size]), role_tip.
var data: Dictionary = {}
var name_label: Label

var _buy_t := 0.0
var _sell_t := 0.0
var _rank_t := 0.0
var _shake_t := 0.0
var _open_t := 0.0
var _float_t := 0.0
var _float_text := ""
var _float_color := Color.WHITE
var _hover := 0.0
var _lock := 0.0          ## lock glyph alpha (fades out when the tier opens)
var _right_down := false
var _shown_name := ""
var _frames: Dictionary = {}
var _skin := -1
static var _art_bg: Dictionary = {}   ## skin_version -> GradientTexture2D


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	name_label = Label.new()
	name_label.name = "Name"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.position = Vector2(2, 64)
	name_label.size = Vector2(68, 29)
	name_label.custom_minimum_size = Vector2(68, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_constant_override("line_spacing", -3)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(name_label)
	gui_input.connect(_on_gui_input)
	mouse_exited.connect(func() -> void: _right_down = false)


## New data from the panel (cheap when nothing changed: the name is re-fitted only when it changes).
func set_data(d: Dictionary) -> void:
	data = d
	var nm := String(d.get("name", ""))
	if nm != _shown_name or _skin != UIStyle.skin_version:
		_shown_name = nm
		_fit_name(nm)
	if _skin != UIStyle.skin_version:
		_skin = UIStyle.skin_version
		_frames.clear()
	name_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
	var target_lock := 1.0 if bool(d.get("locked", false)) else 0.0
	if target_lock > _lock and _open_t <= 0.0:
		_lock = target_lock
	# Locked / empty cards are disabled buttons (WCAG-inactive look; clicks still reach gui_input -> the refusal).
	disabled = bool(d.get("locked", false)) or bool(d.get("empty", false))
	if bool(d.get("empty", false)):
		modulate.a = 1.0
	elif bool(d.get("locked", false)):
		modulate.a = 0.45
	elif String(d.get("why", "")) != "" and not bool(d.get("maxed", false)):
		modulate.a = 0.7
	else:
		modulate.a = 1.0
	tooltip_text = _plain_tip()
	queue_redraw()


## Name: 2 lines at font 11; font 10 when 11 would need 3 lines; then ellipsis.
func _fit_name(nm: String) -> void:
	name_label.text = nm
	name_label.max_lines_visible = -1
	name_label.add_theme_font_size_override("font_size", 11)
	if name_label.get_line_count() > 2:
		name_label.add_theme_font_size_override("font_size", 10)
	name_label.max_lines_visible = 2


func play_buy() -> void:
	_buy_t = BUY_TIME
	_start_float("+1", UIStyle.token(&"text"))


func play_sell() -> void:
	_sell_t = BUY_TIME
	_start_float("-1", UIStyle.WARN)


func play_rank() -> void:
	_rank_t = RANK_TIME


func play_refuse() -> void:
	_shake_t = SHAKE_TIME


func play_open() -> void:
	_open_t = OPEN_TIME


func _start_float(text: String, col: Color) -> void:
	_float_t = FLOAT_TIME
	_float_text = text
	_float_color = col


## True while any of the small animations runs (tests).
func is_animating() -> bool:
	return _buy_t > 0.0 or _sell_t > 0.0 or _rank_t > 0.0 or _shake_t > 0.0 or _open_t > 0.0 or _float_t > 0.0


func _process(delta: float) -> void:
	var busy := is_animating()
	_buy_t = maxf(0.0, _buy_t - delta)
	_sell_t = maxf(0.0, _sell_t - delta)
	_rank_t = maxf(0.0, _rank_t - delta)
	_shake_t = maxf(0.0, _shake_t - delta)
	_float_t = maxf(0.0, _float_t - delta)
	if _open_t > 0.0:
		_open_t = maxf(0.0, _open_t - delta)
	var want_lock := 1.0 if bool(data.get("locked", false)) else 0.0
	var lock_moving := not is_equal_approx(_lock, want_lock)
	if lock_moving:
		_lock = move_toward(_lock, want_lock, delta / LOCK_FADE)
	var hv := 1.0 if is_hovered() and not bool(data.get("empty", false)) else 0.0
	var hover_moving := not is_equal_approx(_hover, hv)
	if hover_moving:
		_hover = move_toward(_hover, hv, delta / HOVER_FADE)
	if busy or lock_moving or hover_moving or is_pressed() or _right_down:
		queue_redraw()


func _on_gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null:
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		_right_down = mb.pressed
		queue_redraw()
		if mb.pressed:
			action.emit(slot, &"sell")
			accept_event()
	elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		if mb.ctrl_pressed:
			action.emit(slot, &"rank")
		elif mb.alt_pressed:
			action.emit(slot, &"sell")
		else:
			action.emit(slot, &"buy")
		queue_redraw()


# ---------------------------------------------------------------- drawing

func _frame(state: StringName, rim: Color) -> StyleBox:
	var key := "%s_%s" % [state, rim.to_html()]
	if not _frames.has(key):
		_frames[key] = UIStyle.button_frame(state, rim)
	return _frames[key]


static func _art_gradient() -> Texture2D:
	if _art_bg.has(UIStyle.skin_version):
		return _art_bg[UIStyle.skin_version]
	_art_bg.clear()
	var g := Gradient.new()
	var glow := UIStyle.token(&"trim_glow")
	var inner := UIStyle.token(&"panel_inner")
	g.colors = PackedColorArray([inner.lerp(glow, 0.30), inner])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.0, 0.95)
	tex.width = 64
	tex.height = 64
	_art_bg[UIStyle.skin_version] = tex
	return tex


func _rim_and_state() -> Array:
	var kc := UIStyle.kingdom_color(StringName(data.get("kingdom", UIStyle.get_kingdom())))
	if bool(data.get("empty", false)):
		var fd := UIStyle.token(&"frame_dark")
		return [&"normal", Color(fd, 0.5)]
	var state := &"normal"
	var rim := kc
	if bool(data.get("locked", false)):
		rim = UIStyle.token(&"frame_dark")
	elif bool(data.get("maxed", false)):
		rim = UIStyle.GOLD
	elif String(data.get("why", "")) != "":
		rim = Color(kc, 0.5)
	if is_pressed() or _right_down:
		state = &"pressed"
		rim = UIStyle.token(&"frame_dark")
		if _right_down or Input.is_key_pressed(KEY_ALT):
			rim = UIStyle.WARN
		elif Input.is_key_pressed(KEY_CTRL):
			rim = UIStyle.GOLD
	elif _hover > 0.5:
		state = &"hover"
		rim = UIStyle.token(&"frame_light")
	# Animation rims (the newest wins)
	if _open_t > 0.0:
		rim = rim.lerp(UIStyle.token(&"trim_glow"), _open_t / OPEN_TIME)
	if _buy_t > 0.0:
		rim = rim.lerp(UIStyle.token(&"trim_glow"), _buy_t / BUY_TIME)
	if _sell_t > 0.0:
		rim = rim.lerp(UIStyle.WARN, _sell_t / BUY_TIME)
	if _rank_t > 0.0:
		rim = rim.lerp(UIStyle.GOLD, clampf(_rank_t / RANK_TIME * 1.5, 0.0, 1.0))
	return [state, rim]


func _draw() -> void:
	var rs := _rim_and_state()
	var state: StringName = rs[0]
	var rim: Color = rs[1]
	if _hover > 0.0 and _hover < 1.0 and state == &"normal":
		draw_rect(Rect2(Vector2(-1, -1), SIZE + Vector2(2, 2)), Color(UIStyle.token(&"trim_glow"), 0.6 * _hover), false, 1.0)
	draw_style_box(_frame(state, rim), Rect2(Vector2.ZERO, SIZE))
	var empty := bool(data.get("empty", false))
	if empty:
		draw_rect(Rect2(Vector2(4, 4), SIZE - Vector2(8, 8)), Color(0, 0, 0, 0.2))
		return
	var font := get_theme_default_font()
	var off := Vector2(1, 1) if state == &"pressed" else Vector2.ZERO
	_draw_art(off)
	_draw_badge(font)
	_draw_role(font)
	_draw_numbers()
	_draw_pips()
	if _float_t > 0.0:
		var k := 1.0 - _float_t / FLOAT_TIME
		var fy := 52.0 - 16.0 * k
		draw_string_outline(font, Vector2(46, fy), _float_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 1.0 - k))
		draw_string(font, Vector2(46, fy), _float_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(_float_color, 1.0 - k))


func _draw_art(off: Vector2) -> void:
	draw_texture_rect(_art_gradient(), ART, false)
	var sc := 1.0
	var since := BUY_TIME - _buy_t
	if _buy_t > 0.0 and since < 0.2:
		sc = 1.0 + 0.10 * sin(since / 0.2 * PI)
	var tint := Color.WHITE
	if bool(data.get("locked", false)):
		tint = Color(0.35, 0.35, 0.35)
	elif String(data.get("why", "")) != "" and not bool(data.get("maxed", false)):
		tint = Color(0.55, 0.55, 0.55)
	if state_lightened():
		tint = tint.lightened(0.12)
	if _sell_t > 0.0:
		tint.a = 1.0 - 0.4 * sin((1.0 - _sell_t / BUY_TIME) * PI)
	var r := Rect2(ART.position + off + ART.size * (1.0 - sc) * 0.5, ART.size * sc)
	var icon: Texture2D = data.get("icon", null)
	if icon != null:
		draw_texture_rect(icon, r, false, tint)
	else:
		var ab := String(data.get("abbrev", "?"))
		var tf := UIStyle.title_font()
		var fs := int(22 * sc)
		var w := tf.get_string_size(ab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(r.get_center().x - w * 0.5, r.get_center().y + fs * 0.35)
		draw_string(tf, pos, ab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIStyle.token(&"title") * tint)
	if _lock > 0.0:
		_draw_lock(ART.get_center() + off, Color(UIStyle.token(&"text_muted"), _lock))


func state_lightened() -> bool:
	return _hover > 0.5 and not is_pressed()


## 14 x 16 padlock glyph centred on `c`.
func _draw_lock(c: Vector2, col: Color) -> void:
	var body := Rect2(c + Vector2(-7, -2), Vector2(14, 10))
	draw_rect(Rect2(body.position - Vector2(1, 1), body.size + Vector2(2, 2)), Color(0, 0, 0, col.a * 0.6))
	draw_rect(body, col)
	draw_arc(c + Vector2(0, -3), 4.5, PI, TAU, 10, col, 2.0)
	draw_line(c + Vector2(-4.5, -3), c + Vector2(-4.5, -2), col, 2.0)
	draw_line(c + Vector2(4.5, -3), c + Vector2(4.5, -2), col, 2.0)
	draw_rect(Rect2(c + Vector2(-1, 1), Vector2(2, 4)), Color(0, 0, 0, col.a))


func _draw_badge(font: Font) -> void:
	var key := String(data.get("key", ""))
	if key == "":
		return
	var w := maxf(BADGE.size.x, font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0)
	var r := Rect2(BADGE.position, Vector2(w, BADGE.size.y))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.75)
	sb.border_color = UIStyle.token(&"frame_dark")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	draw_style_box(sb, r)
	draw_string(font, Vector2(r.position.x, r.position.y + 11), key, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, UIStyle.GOLD)


func _draw_role(font: Font) -> void:
	var role := String(data.get("role", ""))
	if role == "":
		return
	var tw := font.get_string_size(role, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 4.0
	var w := maxf(ROLE.size.x, tw)
	var r := Rect2(Vector2(ROLE.end.x - w, ROLE.position.y), Vector2(w, ROLE.size.y))
	draw_rect(r, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2(r.position.x, r.position.y + 9.5), role, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9,
			UIStyle.token(&"text_muted"))


## The rect of the role tag (tooltips: hovering it shows the short role line).
func role_rect() -> Rect2:
	var font := get_theme_default_font()
	var w := maxf(ROLE.size.x, font.get_string_size(String(data.get("role", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 4.0)
	return Rect2(Vector2(ROLE.end.x - w, ROLE.position.y), Vector2(w, ROLE.size.y))


func _draw_numbers() -> void:
	var nf := UIStyle.number_font()
	var shake := 0.0
	if _shake_t > 0.0:
		shake = sin((SHAKE_TIME - _shake_t) * 60.0) * 3.0 * (_shake_t / SHAKE_TIME)
	# Price: crystal diamond + number (WARN when short of crystals)
	var price_col := UIStyle.WARN if bool(data.get("crystals_short", false)) else UIStyle.CRYSTAL_TEXT
	var p := Vector2(3 + shake, 93)
	_diamond(p + Vector2(4, 5), 4.0, UIStyle.CRYSTAL)
	draw_string(nf, p + Vector2(10, 10), str(int(data.get("price", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, price_col)
	# Pop: shield glyph + number (WARN when it would pass the cap)
	var pop_col := UIStyle.WARN if bool(data.get("supply_short", false)) else UIStyle.token(&"text")
	var q := Vector2(44 + (shake if bool(data.get("supply_short", false)) else 0.0), 93)
	_shield(q + Vector2(4, 5), UIStyle.token(&"text_muted"))
	draw_string(nf, q + Vector2(10, 10), str(int(data.get("pop", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, pop_col)
	# Copies: "x3" or "3 / 4" (gold at the max), popping after a buy / sell
	var most := int(data.get("max", 0))
	var n := int(data.get("count", 0))
	var text := ("%d / %d" % [n, most]) if most > 0 else ("x%d" % n)
	var col := UIStyle.GOLD if most > 0 and n >= most else UIStyle.token(&"text")
	var s := 1.0
	var t := maxf(_buy_t, _sell_t)
	if t > 0.0:
		s = lerpf(1.0, 1.4, t / BUY_TIME)
	var base := Vector2(5, 113)
	draw_set_transform(base, 0.0, Vector2(s, s))
	draw_string(nf, Vector2(0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pips() -> void:
	var r := int(data.get("rank", 1))
	for j in 2:
		var filled := r >= j + 2
		var c := Vector2(57 + 8 * j, 110)
		var half := 3.0
		if filled and j == r - 2 and _rank_t > 0.0:
			half *= 1.0 + 0.6 * sin((1.0 - _rank_t / RANK_TIME) * PI)
		_diamond(c, half, UIStyle.GOLD if filled else Color(0.3, 0.3, 0.3))


func _diamond(c: Vector2, half: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -half), c + Vector2(half, 0), c + Vector2(0, half),
			c + Vector2(-half, 0)]), col)


func _shield(c: Vector2, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -5), c + Vector2(4, -5), c + Vector2(4, 0),
			c + Vector2(0, 5), c + Vector2(-4, 0)]), col)


# ---------------------------------------------------------------- tooltips

func _plain_tip() -> String:
	var lines: PackedStringArray = []
	for row: Array in data.get("tip", []):
		lines.append(String(row[0]))
	return "\n".join(lines)


func _get_tooltip(at_position: Vector2) -> String:
	var rt := String(data.get("role_tip", ""))
	if rt != "" and role_rect().grow(1.0).has_point(at_position):
		return rt
	return tooltip_text


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text == "":
		return null
	if for_text == String(data.get("role_tip", "")) and for_text != tooltip_text:
		return MusterCard.tip_panel([[for_text, UIStyle.token(&"text"), 13]])
	return MusterCard.tip_panel(data.get("tip", []))


## Section-8 tooltip from rows [text, colour, font size] (row 0 = the title: display font, key badge parsed from
## "[K]", an optional right part after a tab). Max width 320.
static func tip_panel(rows: Array) -> Control:
	if rows.is_empty():
		return null
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIStyle.tooltip_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	p.add_child(box)
	for i in rows.size():
		var row: Array = rows[i]
		var text := String(row[0])
		var col: Color = row[1]
		var fs := int(row[2])
		if i == 0 and rows.size() > 1:
			box.add_child(_title_row(text, col, fs))
			continue
		var l := UIStyle.panel_label(text, fs, col)
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var font := l.get_theme_default_font()
		if font != null and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 304.0:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = 304
		box.add_child(l)
	return p


static func _title_row(line: String, col: Color, fs: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var parts := line.split("\t")
	var main := parts[0]
	var key := ""
	var open := main.rfind("[")
	if open > 0 and main.ends_with("]"):
		key = main.substr(open + 1, main.length() - open - 2)
		main = main.substr(0, open).strip_edges()
	var t := UIStyle.display_label(main, fs, col)
	t.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(t)
	if key != "":
		var badge := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = UIStyle.GOLD
		st.set_corner_radius_all(2)
		st.content_margin_left = 3
		st.content_margin_right = 3
		badge.add_theme_stylebox_override("panel", st)
		var kl := UIStyle.panel_label(key, 11, Color.BLACK)
		kl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		badge.add_child(kl)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(badge)
	if parts.size() > 1:
		var r := UIStyle.panel_label(parts[1], 12, UIStyle.token(&"text_muted"))
		r.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	return row
