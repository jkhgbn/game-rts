class_name PauseMenu
extends CanvasLayer
## In-game pause menu (task 5.U1): Resume, Settings, Restart, Surrender, Quit to menu.
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
	var level := get_parent()
	surrender_button.disabled = level == null or not level.has_method(&"surrender") \
			or level.get(&"game_over") == true
	get_tree().paused = true
	resume_button.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	if settings_panel.visible:
		GameSettings.save_settings()
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
## pending order, placement ghost or open build menu (Esc cancels those first).
func can_open() -> bool:
	if get_tree().paused:
		return false
	var level := get_parent()
	var sel: Variant = level.get(&"selection") if level != null else null
	if sel is SelectionManager:
		var sm := sel as SelectionManager
		if sm.get_pending_order() != &"" or sm.build_menu_open:
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_ESCAPE:
		return
	if visible:
		if settings_panel.visible:
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
