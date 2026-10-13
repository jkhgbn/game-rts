class_name HeroTile
extends Control
## The hero tile (docs/design/ui-sc2-console.md 3.1, task SC2.U3): 240 x 100 at (8, 548) at 1600 x 900, bottom-left above
## the quick row. Slate background with the kingdom's trim_glow aura; the player's wizard always: portrait 48 (her icon)
## + level medallion + `F1` badge, name, HP / mana / XP bars, the spell-points chip, then the inventory's 6 item slots and
## 2 artifact slots (InventoryBar, placed over the tile). The SelectionPanel builds the parts (its `hero_*` fields) and
## the HUD adds the tile to its root. Click = select the wizard; double-click = centre the camera on her (Space too).

signal select_requested
signal centre_requested

const SIZE := Vector2(240, 100)
const POS := Vector2(8, 548)
## Rects inside the tile (3.1).
const PORTRAIT := Rect2(4, 4, 48, 48)
const NAME_POS := Vector2(58, -6)   ## Text at y ~0-20 ((58, 4) in 3.1): the flat button is 30 tall for its Cinzel line
const NAME_WIDTH := 140.0
const HP_RECT := Rect2(58, 24, 140, 12)
const MANA_RECT := Rect2(58, 38, 140, 12)
const XP_RECT := Rect2(58, 52, 140, 6)
const POINTS_RECT := Rect2(162, 50, 36, 14)
const MEDALLION := Rect2(38, 38, 20, 20)
const F1_BADGE := Rect2(32, 2, 20, 12)

var face: TextureRect          ## The wizard's icon (art/icons/units/<id>.png).
## Extra drawing over the background (the SelectionPanel's level-up ring), called from _draw.
var draw_extra: Callable
var face_letters: Label        ## Her initials when there is no icon.
var _face_frame: Panel
var _wizard_key := ""


func _ready() -> void:
	name = "HeroTile"
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = POS.x
	offset_right = POS.x + SIZE.x
	offset_top = -(900.0 - POS.y)
	offset_bottom = offset_top + SIZE.y
	_face_frame = Panel.new()
	_face_frame.name = "Face"
	_face_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face_frame.position = PORTRAIT.position
	_face_frame.size = PORTRAIT.size
	add_child(_face_frame)
	face = TextureRect.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.position = Vector2(2, 2)
	face.size = PORTRAIT.size - Vector2(4, 4)
	_face_frame.add_child(face)
	face_letters = UIStyle.display_label("", 18)
	face_letters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face_letters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face_letters.position = Vector2.ZERO
	face_letters.size = PORTRAIT.size
	_face_frame.add_child(face_letters)
	var f1 := Label.new()
	f1.name = "F1Badge"
	f1.text = "F1"
	f1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f1.add_theme_font_size_override("font_size", 9)
	f1.add_theme_color_override("font_color", CommandCard.KEY_COLOR)
	f1.add_theme_stylebox_override("normal", ItemTooltip.HudSkin.badge_style())
	f1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f1.position = F1_BADGE.position
	f1.size = F1_BADGE.size
	f1.custom_minimum_size = F1_BADGE.size
	add_child(f1)
	apply_skin()


func apply_skin() -> void:
	if _face_frame:
		_face_frame.add_theme_stylebox_override("panel", UIStyle.button_frame(&"normal"))
		face_letters.add_theme_color_override("font_color", UIStyle.token(&"title"))
	queue_redraw()


func _draw() -> void:
	draw_style_box(UIStyle.slate_style(0.0), Rect2(Vector2.ZERO, size))
	if draw_extra.is_valid():
		draw_extra.call()


## Shows `wizard`'s icon (or initials), greyed while `alive` is false.
func set_wizard(wizard: Node, alive: bool) -> void:
	var key := ""
	if wizard != null and is_instance_valid(wizard):
		var t: Variant = wizard.get("unit_type")
		key = String(t.get("id")) if t is Object and t.get("id") != null else ""
		if key == "" or ItemTooltip.HudSkin.icon("units", key) == null:
			key = GameHUD.wizard_short_name(wizard).to_lower()
	if key != _wizard_key:
		_wizard_key = key
		var tex: Texture2D = ItemTooltip.HudSkin.icon("units", key) if key != "" else null
		face.texture = tex
		face_letters.text = "" if tex != null else UIStyle.abbrev(GameHUD.wizard_short_name(wizard))
	_face_frame.modulate = Color.WHITE if alive else Color(0.5, 0.5, 0.5)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mb.double_click:
		centre_requested.emit()
	else:
		select_requested.emit()
