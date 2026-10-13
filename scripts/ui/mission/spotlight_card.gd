class_name SpotlightCard
extends PanelContainer
## The mission's unit spotlight card (mission-framework.md 7, unit-spotlights.md 3): portrait, name, the card line,
## the Unit Guide's "Strong against" tags and the key hint, under the objectives panel. Stays FULL_SECONDS (a replay:
## a one-line card for SHORT_SECONDS) or until clicked; a click opens the Unit Guide on that unit (pause menu).
## Never holds the world. Built by MissionHud.show_spotlight(data) with data {id, card, key_hint, short}.

const FULL_SECONDS := 12.0
const SHORT_SECONDS := 4.0
const WIDTH := 360.0
const PORTRAIT := 56.0
const MAX_TAGS := 4
const MUTED := Color(0.72, 0.68, 0.62)
const PRO_COLOR := Color(0.55, 0.88, 0.45)

var unit_id: StringName = &""
var short := false
var time_left := 0.0
var card_label: Label   ## Read only (tests): the card line as shown.

var _fading := false


## Fills the card from `data` ({id, card, key_hint, short}).
func setup(data: Dictionary) -> void:
	name = "SpotlightCard"
	unit_id = StringName(data.get("id", &""))
	short = bool(data.get("short", false))
	time_left = SHORT_SECONDS if short else FULL_SECONDS
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Open the Unit Guide on this unit"
	var sb := UIStyle.slate_style(10.0, UIStyle.GOLD)
	sb.set_border_width_all(2)
	add_theme_stylebox_override("panel", sb)
	var e := UnitGuideData.entry(unit_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	if not e.is_empty() and not short:
		var pic := UnitGuide.portrait(e, PORTRAIT)
		pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN   # a square at the top, not a strip the card's height
		row.add_child(pic)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var head := UIStyle.display_label("Spotlight", 12, UIStyle.GOLD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var line := Loc.sink(String(data.get("card", "")))
	card_label = UIStyle.panel_label(line, 15 if not short else 14)
	card_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_label.custom_minimum_size = Vector2(WIDTH - (PORTRAIT + 40.0 if not short else 30.0), 0)
	card_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(card_label)
	if short:
		return
	var tags: Array = e.get("strong", []) if not e.is_empty() else []
	if not tags.is_empty():
		var t := HFlowContainer.new()
		t.add_theme_constant_override("h_separation", 6)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(t)
		var lead := UIStyle.panel_label("Strong against", 12, MUTED)
		lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(lead)
		for i in mini(tags.size(), MAX_TAGS):
			var chip := UIStyle.panel_label(String(tags[i]), 12, PRO_COLOR)
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(chip)
	var hint := String(data.get("key_hint", ""))
	if hint != "":
		var k := UIStyle.panel_label(Loc.sink(hint), 12, UIStyle.GOLD)
		k.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(k)


func _process(delta: float) -> void:
	if _fading:
		return
	time_left -= delta
	if time_left <= 0.0:
		dismiss()


## Fades out and frees the card.
func dismiss() -> void:
	if _fading:
		return
	_fading = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		open_guide()


## Opens the pause menu's Unit Guide on this unit (the pause menu pauses the game), then closes the card.
func open_guide() -> void:
	var tree := get_tree()
	var menu: PauseMenu = null
	if tree and tree.current_scene:
		for n in tree.current_scene.find_children("*", "CanvasLayer", true, false):
			if n is PauseMenu:
				menu = n as PauseMenu
				break
	if menu:
		menu.open()
		menu.show_unit_guide()
		if menu.unit_guide:
			menu.unit_guide.show_unit(unit_id)   # U5-4: compare off, filters cleared
	dismiss()
