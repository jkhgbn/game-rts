class_name UnitGuide
extends Control
## The Unit Guide screen (docs/design/unit-guide.md): every player-facing unit, helper and champion per kingdom with
## its numbers (read from the game data by UnitGuideData), abilities, pros / cons and Strong against / Weak against /
## Good with tags (data/ui/unit_guide.json). Filters: kingdom, tier, role, search; a compare view (A / B side by side).
## Opened from the main menu (MainMenu.show_unit_guide) and the pause menu (PauseMenu.show_unit_guide).
## Keys: Up / Down browse the list, Ctrl+F (or /) search, Enter in the search box jumps to the list, Esc closes.

signal closed

const LIST_W := 360.0
const ROW_H := 58.0
const PORTRAIT_ROW := 46.0
const PORTRAIT_BIG := 112.0
const PORTRAIT_COMPARE := 76.0
const TEXT := Color(0.93, 0.89, 0.82)
const MUTED := Color(0.72, 0.68, 0.62)
const PRO_COLOR := Color(0.55, 0.88, 0.45)
const CON_COLOR := Color(0.98, 0.5, 0.42)
const BETTER := Color(0.55, 0.92, 0.5)
const KINGDOM_FILTERS: Array[StringName] = [&"", &"fire", &"ice", &"nature", &"shadow", &"neutral"]
const TIER_FILTERS: Array[int] = [0, 1, 2, 3]
## Stat rows: [key, label, lower_is_better]. The single view shows them 3 per row; compare shows one per row.
const STAT_ROWS: Array = [
	["hp", "HP", false], ["damage", "Damage", false], ["dps", "DPS", false],
	["range", "Range", false], ["speed", "Speed", false], ["armor", "Armour", false],
	["sight", "Sight", false], ["cooldown", "Attack every", true], ["ehp", "Effective HP", false],
	["crystals", "Crystals", true], ["pop", "Pop", true], ["train_time", "Train time", true],
]
## The on-hit statuses the units have (data/units on_hit_status), one sentence each.
const ON_HIT_TEXT := {"chill": "Every hit: chill", "rooted": "Every hit: rooted"}
const HINT :="Up / Down: browse    Ctrl+F: search    Compare: pick a second unit    Esc: back"

var search_box: LineEdit
var kingdom_buttons: Array[Button] = []
var tier_buttons: Array[Button] = []
var role_select: OptionButton
var compare_button: Button
var swap_button: Button
var back_button: Button
var count_label: Label
var list_scroll: ScrollContainer
var list_box: VBoxContainer
var empty_label: Label
var detail_scroll: ScrollContainer
var detail_box: VBoxContainer
## id -> the list row Button.
var row_buttons: Dictionary = {}
## The stat value labels of the current view: "<id>:<stat key>" -> Label (tests read them).
var stat_labels: Dictionary = {}
## The framed content; scaled up on tall windows (_fit: x1 up to 1200 px high, then height / 1000, max x1.5).
var content_root: MarginContainer

var _kingdom: StringName = &""
var _tier := 0
var _role := ""
var _search := ""
var _selected: StringName = &""
var _compare := false
var _compare_a: StringName = &""
var _compare_b: StringName = &""
var _visible_ids: Array[StringName] = []
var _headers: Dictionary = {}   # kingdom -> header Label
var _row_subs: Dictionary = {}   # id -> the row's "T1 · Role · Class" Label
var _row_group := ButtonGroup.new()


## Live language switch: rebuild the text made in code (static labels / buttons switch by themselves).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and detail_box != null:
		_refresh_texts()
		_apply_filters()
		_show_detail()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if theme == null:
		theme = UIStyle.game_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	content_root = margin
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	resized.connect(_fit)
	_fit()
	var panel := UIStyle.panel(margin, 18.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_build_header(box)
	_build_filters(box)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	box.add_child(body)
	_build_list(body)
	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(detail_scroll)
	detail_box = VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail_box)
	var hint := UIStyle.panel_label(HINT, 13, MUTED)
	box.add_child(hint)
	_refresh_texts()
	_apply_filters()
	var ids := UnitGuideData.ids()
	if not ids.is_empty():
		select_unit(ids[0])


# ---------------------------------------------------------------- public

## Shows the guide and puts the keyboard focus on the selected row.
func open() -> void:
	visible = true
	_focus_selected_row()


func close() -> void:
	visible = false
	closed.emit()


## &"" = all, &"fire" / &"ice" / &"nature" / &"shadow" / &"neutral".
func set_kingdom_filter(k: StringName) -> void:
	_kingdom = k if KINGDOM_FILTERS.has(k) else &""
	for i in kingdom_buttons.size():
		kingdom_buttons[i].set_pressed_no_signal(KINGDOM_FILTERS[i] == _kingdom)
	_apply_filters()


## 0 = all tiers, else 1-3.
func set_tier_filter(t: int) -> void:
	_tier = t if TIER_FILTERS.has(t) else 0
	for i in tier_buttons.size():
		tier_buttons[i].set_pressed_no_signal(TIER_FILTERS[i] == _tier)
	_apply_filters()


## "" = all, else a UnitGuideData.ROLES id.
func set_role_filter(role: String) -> void:
	_role = role if UnitGuideData.ROLES.has(role) else ""
	role_select.select(UnitGuideData.ROLES.find(_role) + 1)
	_apply_filters()


func set_search(text: String) -> void:
	_search = text
	if search_box.text != text:
		search_box.text = text
	_apply_filters()


## The unit ids the list shows now (filters applied), in list order.
func visible_ids() -> Array[StringName]:
	return _visible_ids.duplicate()


func selected_id() -> StringName:
	return _selected


## Shows `id` (in compare mode: it becomes unit B).
func select_unit(id: StringName) -> void:
	if UnitGuideData.entry(id).is_empty():
		return
	if _compare:
		_compare_b = id
	else:
		_selected = id
	var b: Button = row_buttons.get(id)
	if b:
		b.button_pressed = true   # the ButtonGroup unpresses the old row (only pressed selects)
		if b.is_inside_tree():
			list_scroll.ensure_control_visible.call_deferred(b)
	_show_detail()


## Compare on: unit A = the current unit, unit B = the next listed one (pick another in the list).
func set_compare(on: bool) -> void:
	_compare = on
	compare_button.set_pressed_no_signal(on)
	swap_button.visible = on
	if on:
		_compare_a = _selected
		if _compare_b == &"" or _compare_b == _compare_a:
			_compare_b = _next_visible(_compare_a)
	else:
		_selected = _compare_a if _compare_a != &"" else _selected
	_show_detail()


func is_comparing() -> bool:
	return _compare


## Sets both compared units and turns compare on.
func set_compare_pair(a: StringName, b: StringName) -> void:
	_selected = a
	_compare_a = a
	_compare_b = b
	_compare = true
	var row: Button = row_buttons.get(b)
	if row:
		row.button_pressed = true
	compare_button.set_pressed_no_signal(true)
	swap_button.visible = true
	_show_detail()


func compare_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if _compare:
		out.append(_compare_a)
		out.append(_compare_b)
	return out


func swap_compare() -> void:
	if _compare:
		var t := _compare_a
		_compare_a = _compare_b
		_compare_b = t
		_selected = _compare_a
		_show_detail()


## The text shown for `stat` of `id` (the same formatting the screen uses).
static func stat_text(e: Dictionary, stat: String) -> String:
	var s: Dictionary = e["stats"]
	var v := float(s.get(stat, 0.0))
	match stat:
		"hp", "ehp", "crystals", "pop", "armor":
			return str(int(round(v)))
		"damage":
			return _trim(v, 1)
		"dps":
			return Loc.num(v, 1)
		"range", "sight":
			return "%s m" % _trim(v, 1)
		"speed":
			return "%s m/s" % _trim(v, 1)
		"cooldown", "train_time":
			return "%s s" % _trim(v, 2)
	return _trim(v, 1)


## A stat row's label in the current language ("HP" = "PV").
static func stat_name(label: String) -> String:
	match label:
		"HP":
			return Loc.t("HP")
		"DPS":
			return Loc.t("DPS")
	return Loc.t(label)


static func _trim(v: float, decimals: int) -> String:
	var t := ("%." + str(decimals) + "f") % v
	if t.contains("."):
		t = t.rstrip("0").trim_suffix(".")
	return t.replace(".", ",") if Loc.is_french() else t


# ---------------------------------------------------------------- building

## 1440 px high (3440 x 1440) -> x1.44: the same layout, readable text.
func ui_scale() -> float:
	var h := size.y
	return 1.0 if h < 1200.0 else minf(h / 1000.0, 1.5)


func _fit() -> void:
	if content_root == null:
		return
	var s := ui_scale()
	content_root.position = Vector2.ZERO
	content_root.scale = Vector2(s, s)
	content_root.size = size / s



func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var title := UIStyle.use_title_font(UIStyle.label("Unit Guide", 34))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	row.add_child(title)
	count_label = UIStyle.panel_label("", 15, MUTED)
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	search_box = LineEdit.new()
	search_box.placeholder_text = "Search a unit, role or counter (Ctrl+F)"
	search_box.custom_minimum_size = Vector2(380, 42)
	search_box.clear_button_enabled = true
	search_box.add_theme_font_size_override("font_size", 17)
	search_box.tooltip_text = "Type a name, role, kingdom, building or tag (\"archers\", \"chill\", \"stables\")."
	search_box.text_changed.connect(func(t: String) -> void:
		_search = t
		_apply_filters())
	search_box.text_submitted.connect(func(_t: String) -> void: _focus_first_row())
	row.add_child(search_box)
	back_button = _button(row, "Back", 140)
	back_button.tooltip_text = "Close the guide (Esc)."
	back_button.pressed.connect(close)


func _build_filters(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	row.add_child(_filter_title("Kingdom"))
	var kg := ButtonGroup.new()
	kg.allow_unpress = false
	for k in KINGDOM_FILTERS:
		var b := _toggle(row, "All" if k == &"" else String(UnitGuideData.KINGDOM_NAMES[String(k)]), kg, 86)
		if k != &"":
			b.add_theme_color_override("font_color", UnitGuideData.kingdom_color(k).lightened(0.2))
		var kk := k
		b.pressed.connect(func() -> void: set_kingdom_filter(kk))
		kingdom_buttons.append(b)
	kingdom_buttons[0].set_pressed_no_signal(true)
	row.add_child(_gap())
	row.add_child(_filter_title("Tier"))
	var tg := ButtonGroup.new()
	tg.allow_unpress = false
	for t in TIER_FILTERS:
		var b := _toggle(row, "All" if t == 0 else "T%d" % t, tg, 58)
		b.tooltip_text = "Every tier." if t == 0 else ["", "Tier 1: Keep", "Tier 2: Stronghold", "Tier 3: Citadel"][t]
		var tt := t
		b.pressed.connect(func() -> void: set_tier_filter(tt))
		tier_buttons.append(b)
	tier_buttons[0].set_pressed_no_signal(true)
	row.add_child(_gap())
	row.add_child(_filter_title("Role"))
	role_select = OptionButton.new()
	role_select.custom_minimum_size = Vector2(150, 40)
	role_select.add_theme_font_size_override("font_size", 16)
	role_select.tooltip_text = "Show one role only."
	role_select.add_item("All roles")
	for r in UnitGuideData.ROLES:
		role_select.add_item(UnitGuideData.ROLE_NAMES[r])
	role_select.item_selected.connect(func(i: int) -> void:
		_role = "" if i <= 0 else UnitGuideData.ROLES[i - 1]
		_apply_filters())
	row.add_child(role_select)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	swap_button = _button(row, "Swap A / B", 130)
	swap_button.tooltip_text = "Swap the two compared units."
	swap_button.pressed.connect(swap_compare)
	swap_button.visible = false
	compare_button = _button(row, "Compare", 140)
	compare_button.toggle_mode = true
	compare_button.tooltip_text = "Side by side: the current unit is A; pick unit B in the list."
	compare_button.toggled.connect(set_compare)


func _build_list(parent: Control) -> void:
	list_scroll = ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(LIST_W, 0)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(list_scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 4)
	list_scroll.add_child(list_box)
	var last_k: StringName = &"-"
	for e in UnitGuideData.entries():
		var k: StringName = e["kingdom"]
		if k != last_k:
			var h := UIStyle.display_label("", 16, UnitGuideData.kingdom_color(k))
			h.custom_minimum_size = Vector2(0, 28)
			h.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			list_box.add_child(h)
			_headers[k] = h
			last_k = k
		list_box.add_child(_row(e))
	empty_label = UIStyle.panel_label("No unit matches these filters.", 15, MUTED)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.custom_minimum_size = Vector2(LIST_W - 24, 0)
	list_box.add_child(empty_label)


func _row(e: Dictionary) -> Button:
	var id: StringName = e["id"]
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = _row_group
	b.custom_minimum_size = Vector2(LIST_W - 16, ROW_H)
	b.focus_mode = Control.FOCUS_ALL
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	b.add_theme_stylebox_override("hover_pressed", UIStyle.button_style(UIStyle.GOLD, Color(0.3, 0.22, 0.12, 0.95)))
	b.add_theme_stylebox_override("pressed", UIStyle.button_style(UIStyle.GOLD, Color(0.26, 0.19, 0.11, 0.95)))
	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 6
	hb.offset_right = -6
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hb)
	var p := portrait(e, PORTRAIT_ROW)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(p)
	var col := VBoxContainer.new()
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(col)
	var nm := UIStyle.display_label(String(e["name"]), 17, TEXT)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var sub := UIStyle.panel_label("", 13, MUTED)
	_row_subs[id] = sub
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.clip_text = true
	sub.custom_minimum_size = Vector2(LIST_W - 100, 0)
	col.add_child(sub)
	b.pressed.connect(func() -> void: select_unit(id))
	b.focus_entered.connect(func() -> void:
		if (_compare and _compare_b != id) or (not _compare and _selected != id):
			select_unit(id))
	row_buttons[id] = b
	return b


## The unit's portrait: its icon (art/icons/units/<id>.png) in a kingdom-coloured frame, else its abbreviation.
static func portrait(e: Dictionary, size: float) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size, size)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.11)
	sb.border_color = UnitGuideData.kingdom_color(e["kingdom"])
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	frame.add_theme_stylebox_override("panel", sb)
	var tex := UnitGuideData.icon_of(e["id"])
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tr)
	else:
		var l := UIStyle.display_label(UIStyle.abbrev(String(e["name"])), int(size * 0.38),
				UnitGuideData.kingdom_color(e["kingdom"]))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(l)
	return frame


## The text built in code outside the detail view: kingdom tooltips, list headers, row sub-lines and tooltips.
func _refresh_texts() -> void:
	for i in kingdom_buttons.size():
		var k := KINGDOM_FILTERS[i]
		if k == &"":
			kingdom_buttons[i].tooltip_text = "Every kingdom."
		elif k == UnitGuideData.NEUTRAL:
			kingdom_buttons[i].tooltip_text = Loc.t("Only Neutral units. (champions, the Genie, caravans, trackers)")
		else:
			kingdom_buttons[i].tooltip_text = Loc.t("Only {kingdom} units.", {"kingdom": UnitGuideData.kingdom_label(k)})
	for k: StringName in _headers:
		(_headers[k] as Label).text = UnitGuideData.kingdom_label(k).to_upper()
	for id: StringName in _row_subs:
		var e := UnitGuideData.entry(id)
		var cls := String(e["class"])
		(_row_subs[id] as Label).text = "T%d · %s · %s" % [e["tier"], UnitGuideData.role_label(String(e["role"])),
				Loc.t(cls) if cls != "" else ""]
		(row_buttons[id] as Button).tooltip_text = "%s\n%s" % [e["name"], Loc.sink(String(e["summary"]))]


func _filter_title(text: String) -> Label:
	var l := UIStyle.display_label(text, 15, UIStyle.GOLD)
	l.custom_minimum_size = Vector2(0, 40)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _gap() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(14, 0)
	return c


func _button(parent: Control, text: String, w: float) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 42)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_pressed_color", UIStyle.GOLD)
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	parent.add_child(b)
	return b


func _toggle(parent: Control, text: String, group: ButtonGroup, w: float) -> Button:
	var b := _button(parent, text, w)
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(w, 40)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("hover_pressed", UIStyle.button_style(UIStyle.GOLD, Color(0.3, 0.22, 0.12, 0.95)))
	b.add_theme_stylebox_override("pressed", UIStyle.button_style(UIStyle.GOLD, Color(0.26, 0.19, 0.11, 0.95)))
	return b


# ---------------------------------------------------------------- filtering

func _apply_filters() -> void:
	_visible_ids.clear()
	for e in UnitGuideData.filter(_kingdom, _tier, _role, _search):
		_visible_ids.append(e["id"])
	var shown_k := {}
	for id: StringName in row_buttons:
		var on := _visible_ids.has(id)
		(row_buttons[id] as Button).visible = on
		if on:
			shown_k[UnitGuideData.entry(id)["kingdom"]] = true
	for k: StringName in _headers:
		(_headers[k] as Label).visible = shown_k.has(k) and _kingdom == &""
	empty_label.visible = _visible_ids.is_empty()
	empty_label.text = Loc.t("No unit matches these filters.") + (("\n" + Loc.t("Titans are not in the game yet."))
			if _role == "titan" else "")
	count_label.text = Loc.t("{shown} of {total} units", {"shown": _visible_ids.size(),
			"total": UnitGuideData.entries().size()})
	_link_focus()
	if not _visible_ids.is_empty():
		var cur := _compare_b if _compare else _selected
		if not _visible_ids.has(cur):
			select_unit(_visible_ids[0])


## Search box Down -> first row; the last row's Down stays put.
func _link_focus() -> void:
	if _visible_ids.is_empty():
		return
	var first: Button = row_buttons[_visible_ids[0]]
	search_box.focus_neighbor_bottom = search_box.get_path_to(first)
	first.focus_neighbor_top = first.get_path_to(search_box)


func _next_visible(id: StringName) -> StringName:
	var i := _visible_ids.find(id)
	if _visible_ids.size() > 1:
		return _visible_ids[(i + 1) % _visible_ids.size()]
	var all := UnitGuideData.ids()
	return all[(all.find(id) + 1) % all.size()] if not all.is_empty() else &""


func _focus_first_row() -> void:
	if not _visible_ids.is_empty():
		(row_buttons[_visible_ids[0]] as Button).grab_focus()


func _focus_selected_row() -> void:
	var b: Button = row_buttons.get(_compare_b if _compare else _selected)
	if b and b.visible and b.is_inside_tree():
		b.grab_focus()
	elif search_box.is_inside_tree():
		search_box.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif (key.physical_keycode == KEY_F and key.ctrl_pressed) or (key.keycode == KEY_SLASH and not search_box.has_focus()):
		search_box.grab_focus()
		search_box.select_all()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- detail views

func _show_detail() -> void:
	for c in detail_box.get_children():
		detail_box.remove_child(c)
		c.queue_free()
	stat_labels.clear()
	if _compare:
		_build_compare(UnitGuideData.entry(_compare_a), UnitGuideData.entry(_compare_b))
	else:
		_build_single(UnitGuideData.entry(_selected))
	detail_scroll.scroll_vertical = 0


func _build_single(e: Dictionary) -> void:
	if e.is_empty():
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	detail_box.add_child(top)
	top.add_child(portrait(e, PORTRAIT_BIG))
	var head := VBoxContainer.new()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_constant_override("separation", 3)
	top.add_child(head)
	_head_lines(head, e, 30)
	_section(detail_box, "Stats")
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	detail_box.add_child(grid)
	for row: Array in STAT_ROWS:
		var lab := UIStyle.panel_label(stat_name(String(row[1])), 15, MUTED)
		lab.custom_minimum_size = Vector2(110, 0)
		grid.add_child(lab)
		var val := UIStyle.number_label(stat_text(e, row[0]), 18, TEXT)
		val.custom_minimum_size = Vector2(110, 0)
		grid.add_child(val)
		stat_labels["%s:%s" % [e["id"], row[0]]] = val
	var extra := _extras(e)
	if extra != "":
		detail_box.add_child(UIStyle.panel_label(extra, 15, TEXT))
	if not (e["abilities"] as Array).is_empty():
		_section(detail_box, "Abilities")
		for a: Dictionary in e["abilities"]:
			detail_box.add_child(_ability_row(a))
	var pc := HBoxContainer.new()
	pc.add_theme_constant_override("separation", 28)
	detail_box.add_child(pc)
	pc.add_child(_list_column("Pros", e["pros"], PRO_COLOR, "+"))
	pc.add_child(_list_column("Cons", e["cons"], CON_COLOR, "-"))
	_tags(detail_box, e)


func _head_lines(head: Control, e: Dictionary, name_size: int) -> void:
	var nm := UIStyle.display_label(String(e["name"]), name_size, UIStyle.GOLD)
	head.add_child(nm)
	var args := {"kingdom": UnitGuideData.kingdom_label(e["kingdom"]), "tier": e["tier"],
			"role": UnitGuideData.role_label(String(e["role"])), "class": Loc.t(String(e["class"]))}
	var role_line := Loc.t("{kingdom}  ·  Tier {tier}  ·  {role}  ·  {class}", args) if e["class"] != "" \
			else Loc.t("{kingdom}  ·  Tier {tier}  ·  {role}", args)
	var rl := UIStyle.panel_label(role_line, 16, UnitGuideData.kingdom_color(e["kingdom"]).lerp(TEXT, 0.35))
	head.add_child(rl)
	var key := String(e.get("card_key", ""))
	var bld := UnitGuideData.building_label(String(e["building"]))
	var where := Loc.t("From: {building}   [{key}]", {"building": bld, "key": key}) if key != "" \
			else Loc.t("From: {building}", {"building": bld})
	head.add_child(UIStyle.panel_label(where, 15, TEXT))
	head.add_child(UIStyle.panel_label(UnitGuideData.cost_text(e), 15, UIStyle.CRYSTAL_TEXT))
	var sm := UIStyle.panel_label(Loc.sink(String(e["summary"])), 15, MUTED)
	sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sm.custom_minimum_size = Vector2(260, 0)
	head.add_child(sm)


## "Regenerates 1 %/s out of combat · Hits chill" (only what the unit has).
static func _extras(e: Dictionary) -> String:
	var s: Dictionary = e["stats"]
	var parts: Array[String] = []
	if float(s.get("regen", 0.0)) > 0.0:
		parts.append(Loc.t("Regenerates {n} % HP/s out of combat", {"n": _trim(float(s["regen"]), 1)}))
	var on_hit := String(s.get("on_hit", ""))
	if on_hit != "":
		parts.append(Loc.t(ON_HIT_TEXT[on_hit]) if ON_HIT_TEXT.has(on_hit) else Loc.t("Every hit: {status}", {"status": on_hit}))
	if float(s["range"]) > 3.0:
		parts.append(Loc.t("Ranged attack"))
	return "   ·   ".join(parts)


func _section(parent: Control, text: String) -> void:
	var l := UIStyle.display_label(text, 19, UIStyle.GOLD)
	parent.add_child(l)


func _ability_row(a: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var badge := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.border_color = Color(UIStyle.GOLD, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	badge.add_theme_stylebox_override("panel", sb)
	badge.custom_minimum_size = Vector2(92, 0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var kl := UIStyle.panel_label(UnitGuideData.key_label(String(a["key"])), 13, UIStyle.GOLD)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(kl)
	row.add_child(badge)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", 15)
	t.add_theme_font_size_override("bold_font_size", 15)
	t.add_theme_color_override("default_color", TEXT)
	t.text = "[b]%s[/b]  %s" % [UnitGuideData.ability_name(a).replace("[", "("),
			UnitGuideData.ability_text(a).replace("[", "(")]
	row.add_child(t)
	return row


func _list_column(title: String, lines: Array, color: Color, mark: String) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	col.add_child(UIStyle.display_label(title, 19, color))
	for s: String in lines:
		var l := UIStyle.panel_label("%s  %s" % [mark, Loc.sink(s)], 15, TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(200, 0)
		col.add_child(l)
	return col


func _tags(parent: Control, e: Dictionary) -> void:
	for spec: Array in [["Strong against", "strong", PRO_COLOR], ["Weak against", "weak", CON_COLOR],
			["Good with", "good_with", UIStyle.GOLD]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)
		var l := UIStyle.panel_label(String(spec[0]), 15, MUTED)
		l.custom_minimum_size = Vector2(124, 30)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(l)
		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		row.add_child(flow)
		for tag: String in e[spec[1]]:
			flow.add_child(_chip(tag, spec[2]))


func _chip(text: String, color: Color) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.14)
	sb.border_color = Color(color, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UIStyle.panel_label(text, 14, TEXT))
	return p


func _build_compare(a: Dictionary, b: Dictionary) -> void:
	if a.is_empty() or b.is_empty():
		detail_box.add_child(UIStyle.panel_label("Pick two units to compare.", 16, MUTED))
		return
	var heads := HBoxContainer.new()
	heads.add_theme_constant_override("separation", 24)
	detail_box.add_child(heads)
	for pair: Array in [["A", a], ["B", b]]:
		var e: Dictionary = pair[1]
		var col := HBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 12)
		heads.add_child(col)
		var tag := UIStyle.display_label(String(pair[0]), 28, UIStyle.GOLD)
		tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		col.add_child(tag)
		col.add_child(portrait(e, PORTRAIT_COMPARE))
		var head := VBoxContainer.new()
		head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_theme_constant_override("separation", 2)
		col.add_child(head)
		_head_lines(head, e, 24)
	_section(detail_box, "Stats  (green = better)")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 5)
	detail_box.add_child(grid)
	for row: Array in STAT_ROWS:
		var va := float(a["stats"][row[0]])
		var vb := float(b["stats"][row[0]])
		var low: bool = row[2]
		var a_better := (va < vb) if low else (va > vb)
		var b_better := (vb < va) if low else (vb > va)
		var la := UIStyle.number_label(stat_text(a, row[0]), 18, BETTER if a_better else TEXT)
		la.custom_minimum_size = Vector2(140, 0)
		la.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(la)
		var name_l := UIStyle.panel_label(stat_name(String(row[1])), 15, MUTED)
		name_l.custom_minimum_size = Vector2(130, 0)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(name_l)
		var lb := UIStyle.number_label(stat_text(b, row[0]), 18, BETTER if b_better else TEXT)
		lb.custom_minimum_size = Vector2(140, 0)
		grid.add_child(lb)
		stat_labels["%s:%s" % [a["id"], row[0]]] = la
		stat_labels["%s:%s" % [b["id"], row[0]]] = lb
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	detail_box.add_child(cols)
	for e: Dictionary in [a, b]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		col.add_child(UIStyle.display_label(String(e["name"]), 20, UIStyle.GOLD))
		col.add_child(_list_column("Pros", e["pros"], PRO_COLOR, "+"))
		col.add_child(_list_column("Cons", e["cons"], CON_COLOR, "-"))
		_tags(col, e)
