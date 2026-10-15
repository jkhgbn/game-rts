class_name SettingsPanel
extends PanelContainer
## The settings window shared by the main menu and the pause menu (task 5.U1).
## Every change applies at once; Back saves user://settings.cfg and emits `closed`.

signal closed

var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var scale_slider: HSlider
var fullscreen_check: CheckButton
var edge_pan_check: CheckButton
## Controls (UX.1): item 0 = Classic, 1 = Hero WASD (GameSettings.CONTROLS_*).
var controls_option: OptionButton
## Wave Strike "Place on buy": Auto / Manual (ui-wave-strike.md 7.4).
var place_option: OptionButton
## The chosen scheme's keys in one line, with the letters of the player's keyboard.
var controls_hint: Label
## Map detail (ui-mapfill.md 11): item 0 = High, 1 = Low (faster). Applies from the next match.
var map_detail_option: OptionButton
var map_detail_hint: Label
## Upscaler: item i = GameSettings.UPSCALER_* (Off / FSR 1 / FSR 2), then the Render scale slider (50-100 %).
var upscaler_option: OptionButton
var render_scale_slider: HSlider
## Graphics quality (G1): item i = GameSettings.GFX_* (Low / Medium / High / Ultra); applies at once.
var graphics_option: OptionButton
## Playtest data (docs/design/health-and-playtests.md): OFF by default; records each match to a local file.
var playtest_check: CheckButton

const PLAYTEST_TEXT := "Help improve the game: record my playtest to a local file"
const PLAYTEST_HINT := ("Off by default. When on, each match saves a small timeline (times, resources, orders, "
		+ "frame rate) to a file on this computer only. No names or personal data, nothing is sent anywhere.")
## Language (localization.md): item i = Loc.LANGS[i] (English / Français (Québec)); switches live.
var language_option: OptionButton

const MAP_DETAIL_HINT := "Applies from the next match. Deer and rabbits stay on every setting."
const UPSCALER_TOOLTIP := ("Draws the 3D at a lower resolution, then upscales it: higher frame rate.\n"
		+ "FSR 1: fast, a bit soft. FSR 2: sharper, with its own anti-aliasing (best on a good GPU).\n"
		+ "Render scale: 67 % = Quality, 77 % = Ultra Quality. FSR 2 at 100 % = native with better anti-aliasing.")
const GRAPHICS_TOOLTIP := ("Lighting, shadows, anti-aliasing and model detail. Applies at once.\n"
		+ "Low: fastest. Medium: balanced. High: best look on a good GPU. Ultra: maximum, for a strong GPU.")
const MAP_DETAIL_TOOLTIP := ("High: full plants and flowers, birds, butterflies and frogs, animated water.\n"
		+ "Low: half the plants, no small animals, simpler water.")

var _refreshing := false
var _scale_dragging := false
## [slider, value label, printf format] per slider row: refresh() rewrites the value labels (a language switch
## changes "75 %" spacing but not the value, so value_changed never fires; review 2026-10-08 L3).
var _value_rows: Array = []
## Settings changed since the panel last saved (closing the game window saves them; review 2026-10-08 L5).
var _dirty := false


## The rows between the title and Back scroll when the window is too short for them (1600x900: the panel ran 78 px
## off the bottom); `_fit` keeps the whole panel on screen with MARGIN px to spare.
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _pad: MarginContainer
var _fit_passes := 0
const SCROLLBAR_ROOM := 16
const MARGIN := 16.0
const MIN_ROWS_HEIGHT := 160.0


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.panel_style(24.0))
	custom_minimum_size = Vector2(520, 0)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	add_child(outer)

	var title := UIStyle.use_title_font(UIStyle.label("Settings", 34))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	outer.add_child(_scroll)
	_pad = MarginContainer.new()   # room for the scroll bar while the rows scroll
	_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad.add_theme_constant_override("margin_right", 0)
	_scroll.add_child(_pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad.add_child(box)
	_rows = box

	_language_row(box)
	master_slider = _slider_row(box, "Master volume", 0.0, 100.0, 1.0, "%d %%")
	music_slider = _slider_row(box, "Music volume", 0.0, 100.0, 1.0, "%d %%")
	sfx_slider = _slider_row(box, "Effects volume", 0.0, 100.0, 1.0, "%d %%")
	scale_slider = _slider_row(box, "UI scale", GameSettings.UI_SCALE_MIN * 100.0,
			GameSettings.UI_SCALE_MAX * 100.0, 5.0, "%d %%")
	fullscreen_check = _check_row(box, "Fullscreen")
	edge_pan_check = _check_row(box, "Scroll at screen edge")
	_controls_row(box)
	_place_row(box)
	_priority_row(box)
	_graphics_row(box)
	_map_detail_row(box)
	_upscaler_row(box)
	render_scale_slider = _slider_row(box, "Render scale", GameSettings.RENDER_SCALE_MIN * 100.0,
			GameSettings.RENDER_SCALE_MAX * 100.0, 1.0, "%d %%")
	render_scale_slider.tooltip_text = UPSCALER_TOOLTIP
	playtest_check = _check_row(box, PLAYTEST_TEXT)
	playtest_check.tooltip_text = PLAYTEST_HINT
	playtest_check.add_theme_font_size_override("font_size", 16)
	var playtest_hint := UIStyle.label(PLAYTEST_HINT, 14)
	playtest_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	playtest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(playtest_hint)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 20)
	UIStyle.style_button(back, UIStyle.PANEL_BORDER)
	back.pressed.connect(close)
	outer.add_child(back)
	_scroll.custom_minimum_size.y = box.get_combined_minimum_size().y
	box.minimum_size_changed.connect(_queue_fit)
	visibility_changed.connect(_queue_fit)
	get_viewport().size_changed.connect(_queue_fit)

	master_slider.value_changed.connect(func(v: float) -> void: _changed(&"master_volume", v / 100.0))
	music_slider.value_changed.connect(func(v: float) -> void: _changed(&"music_volume", v / 100.0))
	sfx_slider.value_changed.connect(func(v: float) -> void: _changed(&"sfx_volume", v / 100.0))
	# The scale applies when the drag ends (applying mid-drag moves the slider under the mouse).
	scale_slider.drag_started.connect(func() -> void: _scale_dragging = true)
	scale_slider.drag_ended.connect(func(_c: bool) -> void:
		_scale_dragging = false
		_changed(&"ui_scale", scale_slider.value / 100.0))
	scale_slider.value_changed.connect(func(v: float) -> void:
		if not _scale_dragging:
			_changed(&"ui_scale", v / 100.0))
	fullscreen_check.toggled.connect(func(on: bool) -> void: _changed(&"fullscreen", on))
	edge_pan_check.toggled.connect(func(on: bool) -> void: _changed(&"edge_pan", on))
	controls_option.item_selected.connect(func(i: int) -> void: _changed(&"control_scheme", i))
	place_option.item_selected.connect(func(i: int) -> void: _changed(&"ws_place_manual", i == 1))
	map_detail_option.item_selected.connect(func(i: int) -> void: _changed(&"map_detail", i))
	upscaler_option.item_selected.connect(func(i: int) -> void: _changed(&"upscaler", i))
	graphics_option.item_selected.connect(func(i: int) -> void: _changed(&"graphics_quality", i))
	render_scale_slider.value_changed.connect(func(v: float) -> void: _changed(&"render_scale", v / 100.0))
	playtest_check.toggled.connect(func(on: bool) -> void: _changed(&"playtest_data", on))
	refresh()


## Shows the current GameSettings values.
func refresh() -> void:
	_refreshing = true
	master_slider.value = GameSettings.master_volume * 100.0
	music_slider.value = GameSettings.music_volume * 100.0
	sfx_slider.value = GameSettings.sfx_volume * 100.0
	scale_slider.value = GameSettings.ui_scale * 100.0
	fullscreen_check.button_pressed = GameSettings.fullscreen
	edge_pan_check.button_pressed = GameSettings.edge_pan
	controls_option.select(GameSettings.control_scheme)
	controls_hint.text = controls_hint_text(GameSettings.control_scheme)
	controls_option.tooltip_text = controls_tooltip_text()
	place_option.select(1 if GameSettings.ws_place_manual else 0)
	language_option.select(maxi(Loc.LANGS.find(Loc.language), 0))
	map_detail_option.select(1 if GameSettings.map_detail == GameSettings.MAP_DETAIL_LOW else 0)
	upscaler_option.select(GameSettings.upscaler)
	graphics_option.select(clampi(GameSettings.graphics_quality, GameSettings.GFX_LOW, GameSettings.GFX_ULTRA))
	render_scale_slider.value = GameSettings.render_scale * 100.0
	render_scale_slider.editable = GameSettings.upscaler != GameSettings.UPSCALER_OFF
	playtest_check.button_pressed = GameSettings.playtest_data
	rebuild_priority_list()
	for r: Array in _value_rows:
		(r[1] as Label).text = _value_text(String(r[2]), (r[0] as HSlider).value)
	_refreshing = false


## One line per scheme (keyboard labels): Classic "Right click moves your wizard · Q + click: attack-move · Arrows:
## camera" on AZERTY; Hero WASD "Z Q S D: walk your wizard · X + click: attack-move".
static func controls_hint_text(scheme: int) -> String:
	if scheme == GameSettings.CONTROLS_HERO_WASD:
		return Loc.t("%s: walk your wizard (camera follows)  ·  %s + click: attack-move") % [
				KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]), KeyLabels.of(KEY_X)]
	if scheme == GameSettings.CONTROLS_RTS_WASD:
		return Loc.t("Right click moves your wizard  ·  %s + click: attack-move  ·  %s / arrows: camera (Shift: faster)") % [
				KeyLabels.of(KEY_X), KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D])]
	return Loc.t("Right click moves your wizard  ·  %s + click: attack-move  ·  Arrows: camera") % KeyLabels.of(KEY_A)


## The Controls list tooltip (the three schemes, keyboard letters).
static func controls_tooltip_text() -> String:
	var wasd := KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D])
	return Loc.t("Classic: like most strategy games, right click moves your wizard and %s + click "
			+ "attack-moves.\nHero WASD: %s walk your wizard, %s + click attack-moves.\nRTS camera (WASD): right click "
			+ "moves your wizard, %s move the camera (Shift = faster), %s + click attack-moves.") % [KeyLabels.of(KEY_A),
			wasd, KeyLabels.of(KEY_X), wasd, KeyLabels.of(KEY_X)]


## Live language switch: the text built in code is rebuilt (auto-translated labels redraw by themselves).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and language_option != null and is_inside_tree():
		refresh()
	# The game window closed while the panel is open (Back never pressed): keep the changes.
	elif what == NOTIFICATION_WM_CLOSE_REQUEST and _dirty:
		GameSettings.save_settings()
		_dirty = false


## "Language" + English / Français (Québec) (each name in its own language, never translated).
func _language_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Language", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	language_option = OptionButton.new()
	language_option.add_theme_font_size_override("font_size", 18)
	language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_option.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in Loc.LANG_NAMES.size():
		language_option.add_item(Loc.LANG_NAMES[i], i)
	language_option.get_popup().auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	language_option.tooltip_text = "Game language (voices stay in English; subtitles follow the language)."
	language_option.item_selected.connect(func(i: int) -> void:
		if not _refreshing:
			GameSettings.set_language(Loc.LANGS[clampi(i, 0, Loc.LANGS.size() - 1)]))
	row.add_child(language_option)


func open() -> void:
	refresh()
	visible = true
	_queue_fit()


func _queue_fit() -> void:
	_fit_passes = 0
	_fit.call_deferred()


## Sizes the scrolling rows so the panel fits the window: as tall as the rows need, shorter (scrolling) when the panel
## would cross the window's top or bottom edge. A few deferred passes, as the holder re-centres the panel each time.
func _fit() -> void:
	if _scroll == null or not is_inside_tree() or not is_visible_in_tree():
		return
	var need := _rows.get_combined_minimum_size().y
	var vp := get_viewport_rect().size.y
	var r := get_global_rect()
	var cur := _scroll.custom_minimum_size.y
	var over := maxf(r.end.y - (vp - MARGIN), MARGIN - r.position.y)
	var target := cur
	if over > 0.5:
		target = cur - over
	elif cur < need:
		target = cur + minf(-over, need - cur)
	target = clampf(minf(target, need), minf(MIN_ROWS_HEIGHT, need), need)
	var room := SCROLLBAR_ROOM if target < need - 0.5 else 0
	if _pad.get_theme_constant(&"margin_right") != room:
		_pad.add_theme_constant_override("margin_right", room)
	if absf(target - cur) > 0.5:
		_scroll.custom_minimum_size.y = target
		_fit_passes += 1
		if _fit_passes < 8:
			_fit.call_deferred()


## Saves and hides.
func close() -> void:
	GameSettings.save_settings()
	_dirty = false
	visible = false
	closed.emit()


## U5-6: leaving the tree with unsaved changes (Ctrl+F12 / quit while the panel is open) still writes them.
func _exit_tree() -> void:
	if _dirty:
		GameSettings.save_settings()
		_dirty = false


func _changed(key: StringName, value: Variant) -> void:
	if _refreshing:
		return
	_dirty = true
	match key:
		&"master_volume":
			GameSettings.master_volume = value
		&"music_volume":
			GameSettings.music_volume = value
		&"sfx_volume":
			GameSettings.sfx_volume = value
		&"ui_scale":
			GameSettings.ui_scale = clampf(value, GameSettings.UI_SCALE_MIN, GameSettings.UI_SCALE_MAX)
		&"fullscreen":
			GameSettings.fullscreen = value
		&"edge_pan":
			GameSettings.edge_pan = value
		&"control_scheme":
			GameSettings.control_scheme = clampi(int(value), GameSettings.CONTROLS_CLASSIC,
					GameSettings.CONTROLS_RTS_WASD)
			controls_hint.text = controls_hint_text(GameSettings.control_scheme)
		&"map_detail":
			# Only the saved value changes (Back saves it); the current match keeps its detail.
			GameSettings.map_detail = GameSettings.MAP_DETAIL_LOW if int(value) == 1 else GameSettings.MAP_DETAIL_HIGH
		&"upscaler":
			GameSettings.upscaler = clampi(int(value), GameSettings.UPSCALER_OFF, GameSettings.UPSCALER_FSR2)
			render_scale_slider.editable = GameSettings.upscaler != GameSettings.UPSCALER_OFF
		&"graphics_quality":
			GameSettings.graphics_quality = clampi(int(value), GameSettings.GFX_LOW, GameSettings.GFX_ULTRA)
		&"render_scale":
			GameSettings.render_scale = clampf(value, GameSettings.RENDER_SCALE_MIN, GameSettings.RENDER_SCALE_MAX)
		&"playtest_data":
			GameSettings.set_playtest_data(bool(value), false)   # Back saves the file
		&"ws_place_manual":
			GameSettings.set_ws_place_manual(bool(value), false)   # Back saves the file
	apply_changed(key)


## Applies only what `key` touches (review 2026-10-08 L4: a full GameSettings.apply walked the whole scene tree and
## reconfigured the viewport on every slider step). Returns the part applied ("" = nothing to apply now).
func apply_changed(key: StringName) -> String:
	var tree := get_tree()
	match key:
		&"master_volume", &"music_volume", &"sfx_volume":
			GameSettings.apply_audio()
			return "audio"
		&"ui_scale", &"fullscreen":
			GameSettings.apply_window(tree)
			return "window"
		&"edge_pan":
			GameSettings.apply_edge_pan(tree.root if tree else null)
			return "edge_pan"
		&"upscaler", &"render_scale":
			if tree and tree.root:
				var o := GameSettings.render_overrides()
				GameSettings.apply_render(tree.root, int(o.get("upscaler", GameSettings.upscaler)),
						float(o.get("render_scale", GameSettings.render_scale)))
			return "render"
		&"graphics_quality":
			# The player's pick applies as chosen (a --gfx override or a quiet run only sets the start tier).
			GameSettings.apply_graphics(tree, GameSettings.graphics_quality)
			return "graphics"
	return ""


func _slider_row(parent: Control, text: String, min_v: float, max_v: float, step: float,
		fmt: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label(text, 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := UIStyle.label(_value_text(fmt, min_v), 18)
	value_label.custom_minimum_size = Vector2(70, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void: value_label.text = _value_text(fmt, v))
	_value_rows.append([slider, value_label, fmt])
	return slider


## "75 %" (French: a no-break space before %, glossary).
static func _value_text(fmt: String, v: float) -> String:
	var s := fmt % int(round(v))
	return s.replace(" %", " %") if Loc.is_french() else s


## "Controls" + the scheme list, then the hint line under it.
func _controls_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Controls", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	controls_option = OptionButton.new()
	controls_option.add_theme_font_size_override("font_size", 18)
	controls_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_option.add_item("Classic (right click moves)", GameSettings.CONTROLS_CLASSIC)
	controls_option.add_item("Hero WASD (keys walk the wizard)", GameSettings.CONTROLS_HERO_WASD)
	controls_option.add_item("RTS camera (WASD)", GameSettings.CONTROLS_RTS_WASD)
	controls_option.tooltip_text = controls_tooltip_text()
	row.add_child(controls_option)
	controls_hint = UIStyle.label("", 14)
	controls_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(controls_hint)


## Wave Strike "Place on buy" + Auto / Manual (ui-wave-strike.md 7.4; the mini-pad toggle mirrors it).
func _place_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Place on buy", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.tooltip_text = "Wave Strike"
	row.add_child(name_label)
	place_option = OptionButton.new()
	place_option.add_theme_font_size_override("font_size", 18)
	place_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	place_option.add_item("Auto", 0)
	place_option.add_item("Manual", 1)
	place_option.tooltip_text = "Auto: new copies fill the Line formation, drag to fix · Manual: every buy shows a ghost on the pad"
	row.add_child(place_option)


## Controls > "Unit priority" (playtest 2026-09-27): the Tab order of unit types in a mixed selection (the first one is
## active first). A kingdom picker, Show / Hide, Reset, then one row per type with + (up) / − (down). Saved in
## settings.cfg (GameSettings.unit_priority) when changed.
var priority_kingdom: OptionButton
var priority_list: VBoxContainer
var priority_toggle: Button
const PRIORITY_KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]


func _priority_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Unit priority", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.tooltip_text = "Tab order of unit types in a selection; the first one is active first."
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(name_label)
	priority_kingdom = OptionButton.new()
	priority_kingdom.add_theme_font_size_override("font_size", 18)
	priority_kingdom.tooltip_text = "The kingdom whose unit order is shown."
	priority_kingdom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in PRIORITY_KINGDOMS:
		priority_kingdom.add_item(String(k).capitalize())
	priority_kingdom.item_selected.connect(func(_i: int) -> void: rebuild_priority_list())
	row.add_child(priority_kingdom)
	priority_toggle = _small_button(row, "Show", "Show / hide the list (Tab cycles unit types in this order)")
	priority_toggle.pressed.connect(func() -> void:
		priority_list.visible = not priority_list.visible
		priority_toggle.text = "Hide" if priority_list.visible else "Show")
	var reset := _small_button(row, "Reset", "Default order: wizard, dearest soldiers first, workers last")
	reset.pressed.connect(func() -> void:
		GameSettings.reset_unit_priority()
		rebuild_priority_list())
	priority_list = VBoxContainer.new()
	priority_list.add_theme_constant_override("separation", 2)
	priority_list.visible = false
	parent.add_child(priority_list)
	rebuild_priority_list()


func _small_button(parent: Control, text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(34, 30)
	b.add_theme_font_size_override("font_size", 16)
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	parent.add_child(b)
	return b


## The kingdom's unit type keys in priority order: the saved order first, then the default (wizard, dearest soldiers,
## workers last), as SelectionManager.unit_type_rank sorts them.
static func priority_order(kingdom: StringName) -> Array[StringName]:
	var types: Array[UnitType] = []
	for f in DirAccess.get_files_at(UnitType.DIR):
		var file := f.trim_suffix(".remap")
		if not file.ends_with(".tres"):
			continue
		var t := UnitType.find(file.get_basename())
		if t != null and t.faction == kingdom and not t.is_caravan:
			types.append(t)
	types.sort_custom(func(a: UnitType, b: UnitType) -> bool:
		if a.is_worker != b.is_worker:
			return b.is_worker
		return a.cost > b.cost if a.cost != b.cost else String(a.id) < String(b.id))
	var base: Array[StringName] = [&"wizard"]
	for t in types:
		base.append(t.id)
	var saved := GameSettings.unit_priority()
	var out: Array[StringName] = []
	for k in saved:
		if base.has(k):
			out.append(k)
	for k in base:
		if not out.has(k):
			out.append(k)
	return out


## + (`step` -1) / − (+1) on a row: moves it and saves (entries of other kingdoms keep their place after it).
func move_priority(key: StringName, step: int) -> void:
	var kingdom := PRIORITY_KINGDOMS[maxi(priority_kingdom.selected, 0)]
	var shown := priority_order(kingdom)
	var moved := GameSettings.move_unit_priority(shown, key, step, false)
	for k in GameSettings.unit_priority():
		if not moved.has(k):
			moved.append(k)
	GameSettings.set_unit_priority(moved)
	rebuild_priority_list()


func rebuild_priority_list() -> void:
	if priority_list == null:
		return
	for c in priority_list.get_children():
		priority_list.remove_child(c)
		c.queue_free()
	var kingdom := PRIORITY_KINGDOMS[maxi(priority_kingdom.selected, 0)]
	var order := priority_order(kingdom)
	for i in order.size():
		var key := order[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		priority_list.add_child(row)
		var t := UnitType.find(String(key))
		var label := UIStyle.label("%d. %s" % [i + 1, Loc.t("Wizard") if key == &"wizard" else (t.display_name if t else String(key))], 15)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var up := _small_button(row, "+", "Higher priority")
		up.disabled = i == 0
		up.pressed.connect(move_priority.bind(key, -1))
		var down := _small_button(row, "−", "Lower priority")
		down.disabled = i == order.size() - 1
		down.pressed.connect(move_priority.bind(key, 1))


## "Map detail" + High / Low (faster), then its hint line (font 14, text_muted).
func _map_detail_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Map detail", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	map_detail_option = OptionButton.new()
	map_detail_option.add_theme_font_size_override("font_size", 18)
	map_detail_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_detail_option.add_item("High", 0)
	map_detail_option.add_item("Low (faster)", 1)
	map_detail_option.tooltip_text = MAP_DETAIL_TOOLTIP
	row.add_child(map_detail_option)
	map_detail_hint = UIStyle.label(MAP_DETAIL_HINT, 14)
	map_detail_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	map_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(map_detail_hint)


## "Graphics quality" + Low / Medium / High / Ultra, one tooltip line per tier (applies at once).
func _graphics_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Graphics quality", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	graphics_option = OptionButton.new()
	graphics_option.add_theme_font_size_override("font_size", 18)
	graphics_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in GameSettings.GFX_NAMES.size():
		graphics_option.add_item(GameSettings.GFX_NAMES[i], i)
		graphics_option.set_item_tooltip(i, GameSettings.GFX_TOOLTIPS[i])
	graphics_option.tooltip_text = GRAPHICS_TOOLTIP
	row.add_child(graphics_option)


## "Upscaler" + Off / FSR 1 / FSR 2 (applies at once, in the menu and mid-match).
func _upscaler_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var name_label := UIStyle.label("Upscaler", 18)
	name_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_label)
	upscaler_option = OptionButton.new()
	upscaler_option.add_theme_font_size_override("font_size", 18)
	upscaler_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in GameSettings.UPSCALER_NAMES.size():
		upscaler_option.add_item(GameSettings.UPSCALER_NAMES[i], i)
	upscaler_option.tooltip_text = UPSCALER_TOOLTIP
	row.add_child(upscaler_option)


func _check_row(parent: Control, text: String) -> CheckButton:
	var check := CheckButton.new()
	check.text = text
	check.add_theme_font_size_override("font_size", 18)
	parent.add_child(check)
	return check
