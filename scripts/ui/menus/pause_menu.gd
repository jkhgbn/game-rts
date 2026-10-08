class_name PauseMenu
extends CanvasLayer
## In-game pause menu (task 5.U1): Resume, Settings, Unit Guide (UnitGuide, docs/design/unit-guide.md), Save, Load
## (SaveGame slots, docs/design/save-load.md), Restart, Surrender, Quit to menu. F12 = quicksave, Ctrl+F12 = quickload
## (menu open or not).
## Self-contained: add scenes/ui/pause_menu.tscn as a child of the level. Esc opens it only when
## no targeting / build ghost / build menu is active (those keep Esc = cancel); the tree pauses and
## this node keeps running (process_mode ALWAYS). Also applies the saved settings when the level starts.

signal opened
signal closed

var dim: ColorRect
var panel: PanelContainer
var settings_panel: SettingsPanel
var resume_button: Button
var settings_button: Button
var unit_guide_button: Button
var unit_guide: UnitGuide   ## Built on first open (show_unit_guide).
var save_button: Button
var load_button: Button
var slots_panel: PanelContainer   ## The Save / Load slot list (built on first open).
var slots_title: Label
var slots_status: Label
var slot_buttons: Array[Button] = []
var slots_mode := &"save"          ## &"save" or &"load"
var restart_button: Button
var surrender_button: Button
var quit_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	GameSettings.ensure_loaded(get_tree())
	MenuFlow.install_hooks(get_tree())

	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	dim.theme = UIStyle.game_theme()   # U7: Alegreya body text (null = engine default)

	panel = UIStyle.panel(center, 24.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := UIStyle.use_title_font(UIStyle.label("Paused", 40))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	resume_button = _button(box, "Resume")
	resume_button.pressed.connect(close)
	settings_button = _button(box, "Settings")
	settings_button.pressed.connect(show_settings)
	unit_guide_button = _button(box, "Unit Guide")
	unit_guide_button.tooltip_text = "Every unit: stats, abilities, pros and cons, counters."
	unit_guide_button.pressed.connect(show_unit_guide)
	save_button = _button(box, "Save")
	save_button.pressed.connect(show_slots.bind(&"save"))
	load_button = _button(box, "Load")
	load_button.pressed.connect(show_slots.bind(&"load"))
	restart_button = _button(box, "Restart")
	restart_button.pressed.connect(restart)
	surrender_button = _button(box, "Surrender")
	surrender_button.pressed.connect(surrender)
	quit_button = _button(box, "Quit to menu")
	quit_button.pressed.connect(quit_to_menu)

	settings_panel = SettingsPanel.new()
	center.add_child(settings_panel)
	settings_panel.visible = false
	settings_panel.closed.connect(func() -> void:
		panel.visible = true
		resume_button.grab_focus())

	visible = false


# ---------------------------------------------------------------- public

func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	visible = true
	panel.visible = true
	settings_panel.visible = false
	if unit_guide:
		unit_guide.visible = false
	var level := get_parent()
	surrender_button.disabled = level == null or not level.has_method(&"surrender") \
			or level.get(&"game_over") == true
	save_button.disabled = SaveGame.block_reason(level) != ""
	save_button.tooltip_text = Loc.sink(SaveGame.block_reason(level))
	if slots_panel:
		slots_panel.visible = false
	get_tree().paused = true
	resume_button.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	if settings_panel.visible:
		GameSettings.save_settings()
	if slots_panel:
		slots_panel.visible = false
	visible = false
	get_tree().paused = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func show_settings() -> void:
	panel.visible = false
	settings_panel.open()


## The Unit Guide over the paused game; Back / Esc returns to the pause panel.
func show_unit_guide() -> void:
	if unit_guide == null:
		unit_guide = UnitGuide.new()
		unit_guide.visible = false
		dim.add_child(unit_guide)
		unit_guide.closed.connect(func() -> void:
			panel.visible = true
			unit_guide_button.grab_focus())
	panel.visible = false
	unit_guide.open()


func restart() -> void:
	visible = false
	MenuFlow.restart(get_tree())


## The player gives up (skirmish.gd `surrender`): the defeat screen shows.
func surrender() -> void:
	var level := get_parent()
	close()
	if level != null and level.has_method(&"surrender"):
		level.call(&"surrender", Unit.Team.PLAYER)


func quit_to_menu() -> void:
	visible = false
	MenuFlow.quit_to_menu(get_tree())


## True when Esc would open the menu: nothing else paused the game and the selection has no
## pending order, placement ghost, open build menu or open Hall "+" page (Esc closes those first).
func can_open() -> bool:
	if get_tree().paused:
		return false
	var level := get_parent()
	var sel: Variant = level.get(&"selection") if level != null else null
	if sel is SelectionManager:
		var sm := sel as SelectionManager
		if sm.get_pending_order() != &"" or sm.build_menu_open or sm.upgrades_open():
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == QUICK_KEY:
		if key.ctrl_pressed:
			quickload()
		else:
			quicksave()
		get_viewport().set_input_as_handled()
		return
	if key.physical_keycode != KEY_ESCAPE:
		return
	if visible:
		if slots_panel and slots_panel.visible:
			_close_slots()
		elif settings_panel.visible:
			settings_panel.close()
		else:
			close()
		get_viewport().set_input_as_handled()
	elif can_open():
		open()
		get_viewport().set_input_as_handled()


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 48)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.5))
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

const QUICK_KEY := KEY_F12   ## F12 quicksave, Ctrl+F12 quickload (physical key).


## F12: saves the running match in the quicksave slot; the HUD says done or why not.
func quicksave() -> String:
	var why := SaveGame.save_to_slot(get_parent(), SaveGame.QUICK)
	_tell(why if why != "" else SaveGame.MSG_SAVED)
	return why


## Ctrl+F12: loads the quicksave (the current match is replaced).
func quickload() -> String:
	var why := SaveGame.load_slot(get_tree(), SaveGame.QUICK)
	if why != "":
		_tell(why)
	else:
		visible = false
	return why


## The slot list over the pause panel: `mode` &"save" (click = write) or &"load" (click = load that match).
func show_slots(mode: StringName) -> void:
	slots_mode = mode
	if slots_panel == null:
		_build_slots()
	panel.visible = false
	slots_panel.visible = true
	slots_title.text = Loc.t("Save game") if mode == &"save" else Loc.t("Load game")
	slots_status.text = ""
	_refresh_slots()
	slot_buttons[0].grab_focus()


func _build_slots() -> void:
	var center := panel.get_parent() as Control
	slots_panel = UIStyle.panel(center, 24.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	slots_panel.add_child(box)
	slots_title = UIStyle.use_title_font(UIStyle.label("Save game", 32))
	slots_title.add_theme_color_override("font_color", UIStyle.GOLD)
	slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(slots_title)
	for slot in SaveGame.SLOTS:
		var b := _button(box, "")
		b.custom_minimum_size = Vector2(560, 48)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_slot_pressed.bind(slot))
		slot_buttons.append(b)
	slots_status = UIStyle.label("", 18)
	slots_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(slots_status)
	var back := _button(box, "Back")
	back.pressed.connect(_close_slots)


func _refresh_slots() -> void:
	var saving := slots_mode == &"save"
	var save_block := SaveGame.block_reason(get_parent()) if saving else ""
	for i in SaveGame.SLOTS.size():
		var slot := SaveGame.SLOTS[i]
		var info := SaveGame.slot_info(slot)
		var slot_name := Loc.t("Quicksave") if slot == SaveGame.QUICK else Loc.t("Slot {n}", {"n": i + 1})
		var b := slot_buttons[i]
		if not bool(info["exists"]):
			b.text = Loc.t("{slot}: empty", {"slot": slot_name})
		elif String(info["error"]) != "":
			b.text = Loc.t("{slot}: {reason}", {"slot": slot_name, "reason": Loc.sink(String(info["error"]))})
		else:
			b.text = Loc.t("{slot}: {title}  ·  {time}  ·  {date}", {"slot": slot_name,
					"title": Loc.sink(String(info["title"])), "time": SaveGame.clock(float(info["time"])),
					"date": String(info["date"]).replace("T", " ").left(16)})
		b.disabled = (save_block != "") if saving else (not bool(info["exists"]) or String(info["error"]) != "")
	if save_block != "":
		slots_status.text = Loc.sink(save_block)


func _on_slot_pressed(slot: StringName) -> void:
	if slots_mode == &"save":
		var why := SaveGame.save_to_slot(get_parent(), slot)
		_refresh_slots()
		slots_status.text = Loc.sink(why if why != "" else SaveGame.MSG_SAVED)
	else:
		var why := SaveGame.load_slot(get_tree(), slot)
		if why != "":
			slots_status.text = Loc.sink(why)
		else:
			visible = false


func _close_slots() -> void:
	slots_panel.visible = false
	panel.visible = true
	(save_button if slots_mode == &"save" else load_button).grab_focus()


func _tell(text: String) -> void:
	var hud: Variant = get_parent().get(&"hud") if get_parent() else null
	if hud is Object and is_instance_valid(hud) and hud.has_method(&"show_message"):
		hud.call(&"show_message", text, 3.0)
	if slots_status and slots_panel and slots_panel.visible:
		slots_status.text = Loc.sink(text)


## SaveGame's messages and titles (logic text in scripts/core, outside the string extractor's areas), listed here so
## they are ui_menus keys with a French entry; Loc.sink shows them. tests/test_save_load.gd checks this list.
const SAVE_TEXTS: Array[String] = [
	"Nothing to save here", "The match has not started yet", "The match is over", "Can't save during a film",
	"Still loading", "Could not write the save file", "No save in this slot", "This save file is damaged",
	"This save is from another version of the game", "The saved map is missing", "Game saved", "Game loaded",
	"Skirmish", "Mission 1",
]
