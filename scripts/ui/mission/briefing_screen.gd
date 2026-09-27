class_name BriefingScreen
extends CanvasLayer
## Mission briefing (task M7.U1, mission-01.md E1): shown before the mission starts and pauses the game.
## Full-screen dim + a centred heavy-frame panel 760 wide (margin 24, like the end screen): title, the story
## paragraphs, "Primary objectives" with a bullet list, and a "Begin" button (Enter / Space / click).
## Begin unpauses, emits `begun` and frees the screen.
##
## Data: the mission node's `briefing() -> Dictionary`:
##   title: String, paragraphs: Array[String] (or text: String, paragraphs split on blank lines),
##   objectives: Array[String] (or primary_objectives). Missing objectives = the primary rows of objectives().

signal begun

const WIDTH := 760.0

var begin_button: Button
var title_label: Label
var paragraph_labels: Array[Label] = []
var objective_labels: Array[Label] = []


func _init() -> void:
	name = "BriefingScreen"
	layer = 80   # above the HUD and the mission HUD, below the pause menu (90)
	process_mode = Node.PROCESS_MODE_ALWAYS


## Builds the screen from a briefing dictionary (and the mission, for its objectives) and pauses the game.
func open(data: Dictionary, mission: Node = null) -> void:
	_build(data, _objective_texts(data, mission))
	get_tree().paused = true
	begin_button.grab_focus.call_deferred()


func begin() -> void:
	if begin_button.disabled:
		return
	begin_button.disabled = true
	get_tree().paused = false
	begun.emit()
	queue_free()


static func paragraphs_of(data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = data.get("paragraphs", null)
	if raw is Array:
		for p: Variant in raw:
			out.append(str(p))
	elif data.has("text"):
		for p in str(data.text).split("\n\n", false):
			out.append(p.strip_edges())
	return out


func _objective_texts(data: Dictionary, mission: Node) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = data.get("objectives", data.get("primary_objectives", null))
	if raw is Array:
		for o: Variant in raw:
			out.append(str(o.get("text", "")) if o is Dictionary else str(o))
		return out
	if mission and is_instance_valid(mission) and mission.has_method(&"objectives"):
		var list: Variant = mission.call(&"objectives")
		if list is Dictionary:
			list = (list as Dictionary).values()
		if list is Array:
			for d: Variant in list:
				if d is Dictionary and bool(d.get("primary", str(d.get("type", "primary")) != "secondary")) \
						and str(d.get("state", "active")) != "hidden":
					out.append(str(d.get("text", d.get("id", ""))))
	return out


func _build(data: Dictionary, objectives: Array[String]) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing reaches the battlefield while the briefing is up
	root.theme = UIStyle.hud_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.frame_style(24.0))
	panel.custom_minimum_size = Vector2(WIDTH, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	UIStyle.add_drop_shadow(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var kicker := UIStyle.display_label(str(data.get("subtitle", "Mission briefing")), 13, UIStyle.token(&"text_muted"))
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	title_label = UIStyle.display_label(str(data.get("title", "Mission")), 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	box.add_child(_rule())

	for p in paragraphs_of(data):
		var l := UIStyle.panel_label(p, 16)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(WIDTH - 48, 0)
		box.add_child(l)
		paragraph_labels.append(l)

	if not objectives.is_empty():
		var head := UIStyle.display_label("Primary objectives", 15)
		box.add_child(head)
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		box.add_child(list)
		for o in objectives:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var mark := Control.new()
			mark.custom_minimum_size = Vector2(14, 14)
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			mark.draw.connect(func() -> void:
				mark.draw_rect(Rect2(1, 1, 12, 12), Color(0, 0, 0, 0.5))
				mark.draw_rect(Rect2(1, 1, 12, 12), UIStyle.token(&"frame_light"), false, 1.0)
				mark.draw_rect(Rect2(5, 5, 4, 4), UIStyle.token(&"trim_glow")))
			row.add_child(mark)
			var l := UIStyle.panel_label(o, 16, UIStyle.token(&"title"))
			row.add_child(l)
			list.add_child(row)
			objective_labels.append(l)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	box.add_child(spacer)
	begin_button = Button.new()
	begin_button.text = "Begin"
	begin_button.custom_minimum_size = Vector2(200, 46)
	begin_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	begin_button.add_theme_font_override("font", UIStyle.display_font())
	begin_button.add_theme_font_size_override("font_size", 18)
	UIStyle.style_button(begin_button)
	begin_button.add_theme_stylebox_override("normal", UIStyle.primary_button_frame())
	begin_button.pressed.connect(begin)
	box.add_child(begin_button)
	var hint := UIStyle.panel_label("Enter: begin", 11, UIStyle.token(&"text_muted"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


func _rule() -> Control:
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(400, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(func() -> void:
		rule.draw_rect(Rect2(0, 0, 400, 1), UIStyle.token(&"groove"))
		rule.draw_rect(Rect2(0, 1, 400, 1), UIStyle.token(&"frame_light")))
	return rule


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or begin_button == null:
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		begin()
		get_viewport().set_input_as_handled()
