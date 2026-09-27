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
## The chosen scheme's keys in one line, with the letters of the player's keyboard.
var controls_hint: Label
## Map detail (ui-mapfill.md 11): item 0 = High, 1 = Low (faster). Applies from the next match.
var map_detail_option: OptionButton
var map_detail_hint: Label
## Upscaler: item i = GameSettings.UPSCALER_* (Off / FSR 1 / FSR 2), then the Render scale slider (50-100 %).
var upscaler_option: OptionButton
var render_scale_slider: HSlider

const MAP_DETAIL_HINT := "Applies from the next match. Deer and rabbits stay on every setting."
const UPSCALER_TOOLTIP := ("Draws the 3D at a lower resolution, then upscales it: higher frame rate.\n"
		+ "FSR 1: fast, a bit soft. FSR 2: sharper, with its own anti-aliasing (best on a good GPU).\n"
		+ "Render scale: 67 % = Quality, 77 % = Ultra Quality. FSR 2 at 100 % = native with better anti-aliasing.")
const MAP_DETAIL_TOOLTIP := ("High: full plants and flowers, birds, butterflies and frogs, animated water.\n"
		+ "Low: half the plants, no small animals, simpler water.")

var _refreshing := false
var _scale_dragging := false


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.panel_style(24.0))
	custom_minimum_size = Vector2(520, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := UIStyle.label("Settings", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	master_slider = _slider_row(box, "Master volume", 0.0, 100.0, 1.0, "%d %%")
	music_slider = _slider_row(box, "Music volume", 0.0, 100.0, 1.0, "%d %%")
	sfx_slider = _slider_row(box, "Effects volume", 0.0, 100.0, 1.0, "%d %%")
	scale_slider = _slider_row(box, "UI scale", GameSettings.UI_SCALE_MIN * 100.0,
			GameSettings.UI_SCALE_MAX * 100.0, 5.0, "%d %%")
	fullscreen_check = _check_row(box, "Fullscreen")
	edge_pan_check = _check_row(box, "Scroll at screen edge")
	_controls_row(box)
	_map_detail_row(box)
	_upscaler_row(box)
	render_scale_slider = _slider_row(box, "Render scale", GameSettings.RENDER_SCALE_MIN * 100.0,
			GameSettings.RENDER_SCALE_MAX * 100.0, 1.0, "%d %%")
	render_scale_slider.tooltip_text = UPSCALER_TOOLTIP

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 20)
	UIStyle.style_button(back, UIStyle.PANEL_BORDER)
	back.pressed.connect(close)
	box.add_child(back)

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
	map_detail_option.item_selected.connect(func(i: int) -> void: _changed(&"map_detail", i))
	upscaler_option.item_selected.connect(func(i: int) -> void: _changed(&"upscaler", i))
	render_scale_slider.value_changed.connect(func(v: float) -> void: _changed(&"render_scale", v / 100.0))
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
	map_detail_option.select(1 if GameSettings.map_detail == GameSettings.MAP_DETAIL_LOW else 0)
	upscaler_option.select(GameSettings.upscaler)
	render_scale_slider.value = GameSettings.render_scale * 100.0
	render_scale_slider.editable = GameSettings.upscaler != GameSettings.UPSCALER_OFF
	_refreshing = false


## One line per scheme (keyboard labels): Classic "Right click moves your wizard · Q + click: attack-move · Arrows:
## camera" on AZERTY; Hero WASD "Z Q S D: walk your wizard · X + click: attack-move".
static func controls_hint_text(scheme: int) -> String:
	if scheme == GameSettings.CONTROLS_HERO_WASD:
		return "%s: walk your wizard (camera follows)  ·  %s + click: attack-move" % [
				KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]), KeyLabels.of(KEY_X)]
	return "Right click moves your wizard  ·  %s + click: attack-move  ·  Arrows: camera" % KeyLabels.of(KEY_A)


func open() -> void:
	refresh()
	visible = true


## Saves and hides.
func close() -> void:
	GameSettings.save_settings()
	visible = false
	closed.emit()


func _changed(key: StringName, value: Variant) -> void:
	if _refreshing:
		return
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
					GameSettings.CONTROLS_HERO_WASD)
			controls_hint.text = controls_hint_text(GameSettings.control_scheme)
		&"map_detail":
			# Only the saved value changes (Back saves it); the current match keeps its detail.
			GameSettings.map_detail = GameSettings.MAP_DETAIL_LOW if int(value) == 1 else GameSettings.MAP_DETAIL_HIGH
		&"upscaler":
			GameSettings.upscaler = clampi(int(value), GameSettings.UPSCALER_OFF, GameSettings.UPSCALER_FSR2)
			render_scale_slider.editable = GameSettings.upscaler != GameSettings.UPSCALER_OFF
		&"render_scale":
			GameSettings.render_scale = clampf(value, GameSettings.RENDER_SCALE_MIN, GameSettings.RENDER_SCALE_MAX)
	GameSettings.apply(get_tree())


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
	var value_label := UIStyle.label(fmt % int(round(min_v)), 18)
	value_label.custom_minimum_size = Vector2(70, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void: value_label.text = fmt % int(round(v)))
	return slider


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
	controls_option.tooltip_text = ("Classic: like most strategy games, right click moves your wizard and %s + click "
			+ "attack-moves.\nHero WASD: %s walk your wizard, %s + click attack-moves.") % [KeyLabels.of(KEY_A),
			KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]), KeyLabels.of(KEY_X)]
	row.add_child(controls_option)
	controls_hint = UIStyle.label("", 14)
	controls_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(controls_hint)


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
