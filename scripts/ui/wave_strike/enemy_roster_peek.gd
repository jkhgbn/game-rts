class_name EnemyRosterPeek
extends Panel
## Enemy roster peek (docs/design/ui-wave-strike.md 4): slate panel 300 x 236, anchored bottom-right above the console,
## fades in over 0.1 s. Title `Enemy roster · Shadow (Citadel)` in the enemy kingdom colour, 10 mini cards 48 x 56 in the
## 5 / 3 / 2 grouping (count badge, 4 px pips, locked groups at alpha 0.35), footer with field / supply / last wave.
## Never clickable except the X stud. Shown by key I (toggle) or while the enemy Bastion bar is hovered.

const SIZE := Vector2(300, 236)
const MINI := Vector2(48, 56)
const FADE := 0.1
const REFRESH := 0.5

var roster: MusterRoster
var level: Node
var director: WaveDirector
var pinned := false
var hovered := false
var title: Label
var footer: Label
var close_button: Button
var _cards: Control
var _rows: Array[Dictionary] = []
var _refresh_left := 0.0
var _kingdom: StringName = &"shadow"


func setup(p_level: Node, p_roster: MusterRoster, p_director: WaveDirector) -> void:
	level = p_level
	roster = p_roster
	director = p_director
	_kingdom = roster.kingdom if roster else &"shadow"


func _ready() -> void:
	name = "EnemyRosterPeek"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_right = -16.0
	offset_left = -16.0 - SIZE.x
	offset_bottom = -254.0
	offset_top = -254.0 - SIZE.y
	add_theme_stylebox_override("panel", UIStyle.slate_style(8.0, UIStyle.token(&"frame_metal")))
	var bg := get_theme_stylebox("panel") as StyleBoxFlat
	if bg:
		bg.bg_color.a = 0.9
	title = UIStyle.use_title_font(UIStyle.panel_label("", 15, UIStyle.kingdom_color(_kingdom)))
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.position = Vector2(10, 6)
	title.size = Vector2(SIZE.x - 40, 20)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	close_button = Button.new()
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.position = Vector2(SIZE.x - 24, 6)
	close_button.size = Vector2(18, 18)
	close_button.custom_minimum_size = Vector2(18, 18)
	close_button.add_theme_font_size_override("font_size", 13)
	UIStyle.style_button(close_button)
	close_button.pressed.connect(func() -> void:
		pinned = false
		hovered = false)
	add_child(close_button)
	_cards = Control.new()
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.position = Vector2.ZERO
	_cards.size = SIZE
	_cards.draw.connect(_draw_cards)
	add_child(_cards)
	footer = UIStyle.panel_label("", 12, UIStyle.token(&"text_muted"))
	footer.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	footer.position = Vector2(10, 158)
	footer.size = Vector2(SIZE.x - 20, 70)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	visible = false
	modulate.a = 0.0
	_update_tooltips()


func _update_tooltips() -> void:
	close_button.tooltip_text = Loc.t("Close (%s)") % KeyLabels.of(KEY_I)


func toggle() -> void:
	pinned = not pinned


func wants_visible() -> bool:
	return pinned or hovered


func _process(delta: float) -> void:
	var want := wants_visible()
	if want and not visible:
		visible = true
		_refresh_left = 0.0
	if want:
		modulate.a = minf(1.0, modulate.a + delta / FADE)
	else:
		modulate.a = maxf(0.0, modulate.a - delta / FADE)
		if modulate.a <= 0.0:
			visible = false
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH
		refresh()


## Reads the enemy roster live (full vision, Q6).
func refresh() -> void:
	if roster == null or level == null:
		return
	_update_tooltips()
	title.text = Loc.t("Enemy roster · %s (%s)") % [Loc.t(String(_kingdom).capitalize()), Loc.t(roster.tier_name())]
	_rows.clear()
	var ids := roster.card_ids()
	for i in 10:
		if i >= ids.size():
			_rows.append({"empty": true})
			continue
		var id := ids[i]
		var t := UnitType.find(String(id))
		_rows.append({"id": id, "icon": UnitGuideData.icon_of(id),
				"abbrev": UIStyle.abbrev(Loc.t(t.display_name) if t else String(id)),
				"count": roster.count(id), "rank": roster.rank(id), "locked": roster.tier_of_card(id) > roster.tier})
	var team := roster.team
	var cap := int(director.rules.field_cap) if director and director.rules else 0
	var last := int(director.last_wave_size[roster.seat]) if director and roster.seat < director.last_wave_size.size() else 0
	footer.text = Loc.t("On the field %d / %d · Supply %d / %d · Last wave %d") % [
		int(level.call(&"field_count", team)) if level.has_method(&"field_count") else 0, cap,
		roster.pop_used(), roster.cap(), last]
	_cards.queue_redraw()


## Mini card rect for slot i (rows at y 30 and y 90; T2 + T3 on row 2 with a divider).
static func mini_rect(i: int) -> Rect2:
	if i < 5:
		return Rect2(Vector2(10 + i * 54, 30), MINI)
	var x := 10.0 + (i - 5) * 54.0
	if i >= 8:
		x += 14.0
	return Rect2(Vector2(x, 90), MINI)


func _draw_cards() -> void:
	var font := get_theme_default_font()
	var kc := UIStyle.kingdom_color(_kingdom)
	for i in _rows.size():
		var d: Dictionary = _rows[i]
		var r := mini_rect(i)
		var a := 0.35 if bool(d.get("locked", false)) else 1.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UIStyle.token(&"panel_inner"), a)
		sb.border_color = Color(kc, 0.8 * a) if not bool(d.get("empty", false)) else Color(UIStyle.token(&"frame_dark"), 0.5)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		_cards.draw_style_box(sb, r)
		if bool(d.get("empty", false)):
			continue
		var icon: Texture2D = d.get("icon", null)
		var ir := Rect2(r.position + Vector2(4, 2), Vector2(40, 40))
		if icon != null:
			_cards.draw_texture_rect(icon, ir, false, Color(1, 1, 1, a))
		else:
			var ab := String(d.get("abbrev", "?"))
			var tf := UIStyle.title_font()
			var w := tf.get_string_size(ab, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			_cards.draw_string(tf, ir.get_center() + Vector2(-w * 0.5, 6), ab, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
					Color(UIStyle.token(&"title"), a))
		var n := str(int(d.get("count", 0)))
		var nw := font.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0
		var br := Rect2(r.end - Vector2(nw + 2, 15), Vector2(nw, 13))
		_cards.draw_rect(br, Color(0, 0, 0, 0.75 * a))
		_cards.draw_string(font, Vector2(br.position.x, br.position.y + 10.5), n, HORIZONTAL_ALIGNMENT_CENTER, nw, 11,
				Color(UIStyle.token(&"text"), a))
		var rk := int(d.get("rank", 1))
		for j in 2:
			var c := r.position + Vector2(6 + 6 * j, r.size.y - 7)
			var col := UIStyle.GOLD if rk >= j + 2 else Color(0.3, 0.3, 0.3)
			_cards.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(2, 0), c + Vector2(0, 2),
					c + Vector2(-2, 0)]), Color(col, a))
	# divider between T2 and T3 on row 2
	var dx := 175.0
	_cards.draw_rect(Rect2(dx, 92, 2, 52), UIStyle.token(&"groove"))
	_cards.draw_rect(Rect2(dx + 2, 92, 1, 52), UIStyle.token(&"frame_light"))
