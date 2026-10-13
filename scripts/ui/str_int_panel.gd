class_name StrIntPanel
extends CanvasLayer
## STR / INT path UI (docs/design/level-boons.md "STR / INT path"), minimal. Created by StrIntPath (load-guarded)
## for the human's wizard in a skirmish only:
## 1. at 0:00 a centred 2-button panel "Choose your path" (Strength / Intellect); the game is paused until a
##    button is pressed (the choice is mandatory and locked for the match);
## 2. then a small ability button (right edge) "J  Vigor" / "J  Snow Shield" with the active time or cooldown;
##    click it or press J (physical keycode, AZERTY-safe) to use the ability.
## Only public StrIntPath calls are used.

const ABILITY_KEY := KEY_J
const BUTTON_SIZE := Vector2(190, 40)
const BUTTON_OFFSET := Vector2(-202, -140)   ## from the right-centre of the screen

var path_node: Node = null
var _choice: Control = null
var _ability: Button = null
var _paused_by_me := false


func open_for(p: Node) -> void:
	path_node = p
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_choice()
	var tree := get_tree()
	if tree and not tree.paused:
		tree.paused = true
		_paused_by_me = true


## Called by StrIntPath.choose(): close the choice, resume, show the ability button.
func on_path_chosen() -> void:
	if _choice:
		_choice.queue_free()
		_choice = null
	if _paused_by_me and get_tree():
		get_tree().paused = false
	_paused_by_me = false
	_build_ability_button()


func _build_choice() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_choice = dim
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -310
	box.offset_right = 310
	box.offset_top = -130
	box.offset_bottom = 130
	box.add_theme_constant_override(&"separation", 14)
	dim.add_child(box)
	var title := Label.new()
	title.text = "Choose your path (locked for the match)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var dur := int(StrIntPath.ABILITY_DURATION)
	var cd := int(StrIntPath.ABILITY_COOLDOWN)
	row.add_child(_path_button(&"str", Loc.t("STRENGTH\n\n+15 %% attack damage\n+20 %% max HP\n\nVigor (J): regenerate %d %% max HP\nover %d s, cooldown %d s") % [
			roundi(StrIntPath.VIGOR_REGEN_PCT * 100.0 * dur), dur, cd], Color(0.75, 0.25, 0.08)))
	row.add_child(_path_button(&"int", Loc.t("INTELLECT\n\n+15 spell power (+15 %% spell damage)\n+25 %% max mana\n\nSnow Shield (J): shield %d %% max HP\nfor %d s, cooldown %d s") % [
			roundi(StrIntPath.SNOW_SHIELD_HP_PCT * 100.0), dur, cd], Color(0.2, 0.5, 0.8)))


func _path_button(p: StringName, text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(290, 200)
	b.add_theme_font_size_override(&"font_size", 15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color.darkened(0.45)
	sb.border_color = color.lightened(0.3)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override(&"normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = color.darkened(0.2)
	b.add_theme_stylebox_override(&"hover", hover)
	b.add_theme_stylebox_override(&"pressed", hover)
	b.pressed.connect(func() -> void:
		if path_node and is_instance_valid(path_node):
			path_node.call(&"choose", p))
	return b


func _build_ability_button() -> void:
	if _ability or path_node == null:
		return
	_ability = Button.new()
	_ability.focus_mode = Control.FOCUS_NONE
	_ability.add_theme_font_size_override(&"font_size", 15)
	_ability.pressed.connect(_use)
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ctrl)
	ctrl.add_child(_ability)
	_ability.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_ability.offset_left = BUTTON_OFFSET.x
	_ability.offset_right = BUTTON_OFFSET.x + BUTTON_SIZE.x
	_ability.offset_top = BUTTON_OFFSET.y
	_ability.offset_bottom = BUTTON_OFFSET.y + BUTTON_SIZE.y
	process_mode = Node.PROCESS_MODE_INHERIT


func _use() -> String:
	if path_node == null or not is_instance_valid(path_node):
		return ""
	var reason := str(path_node.call(&"activate"))
	if reason != "":
		_tell(reason)   # U4-7: the refusal ("On cooldown", "Dead"...) is shown, not dropped
	return reason


func _tell(text: String) -> void:
	var tree := get_tree()
	var level := tree.current_scene if tree else null
	var hud: Variant = level.get(&"hud") if level else null
	if hud is Object and is_instance_valid(hud) and (hud as Object).has_method(&"show_message"):
		hud.call(&"show_message", text)   # the HUD translates logic text (Loc.sink)


func _process(_delta: float) -> void:
	if _ability == null or path_node == null or not is_instance_valid(path_node):
		return
	var key := KeyLabels.of(ABILITY_KEY)   # U4-7: the label of the physical key on the player's layout
	var name_text := Loc.sink(str(path_node.call(&"ability_name")))   # U4-7: "Vigor" / "Snow Shield" translated
	if path_node.call(&"is_active"):
		_ability.text = Loc.t("%s  %s  ACTIVE %d s") % [key, name_text, ceili(float(path_node.call(&"time_left")))]
		_ability.modulate = Color(1.3, 1.2, 0.8)
	elif float(path_node.call(&"cooldown_left")) > 0.0:
		_ability.text = Loc.t("%s  %s  %d s") % [key, name_text, ceili(float(path_node.call(&"cooldown_left")))]
		_ability.modulate = Color(0.6, 0.6, 0.6)
	else:
		_ability.text = Loc.t("%s  %s  ready") % [key, name_text]
		_ability.modulate = Color(1, 1, 1)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
		return
	if k.physical_keycode == ABILITY_KEY and _ability != null:
		_use()
		get_viewport().set_input_as_handled()
