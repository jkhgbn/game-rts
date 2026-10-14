class_name PortraitWindow
extends Control
## The console's portrait window (docs/design/ui-sc2-console.md 4.3, task SC2.U1): the HUD's one Portrait (3D model of
## the selected thing, 136 x 136 at (1144, 696) at 1600 x 900) and, under it, the status slate 136 x 44 at (1144, 840):
## the team / kingdom line (`Fire · yours`, `Shadow · enemy`, `Neutral`) + `Pop 2` (font 12, muted).
## Click = centre the camera on the shown thing; double-click a unit = select every own unit of its type on screen.
## Anchored bottom-right (x from the right edge), so it stays next to the command card on any screen width.

const SLATE_GAP := 8.0
const SLATE_HEIGHT := 44.0

var portrait: Portrait
var selection: SelectionManager
var team_label: Label
var pop_label: Label
var _slate: PanelContainer
var _team_key := ""
## UR.U2 (ui-sc2-console.md 7.5): up to 5 research pips, 8 x 8 GOLD diamonds at (6 + 11 i, 4) over the portrait.
var research_pips: Control
var _pip_count := 0


## `p_portrait` = the selection panel's Portrait (moved in here).
func setup_portrait(p_portrait: Portrait) -> void:
	portrait = p_portrait
	if portrait.get_parent() != null:
		portrait.get_parent().remove_child(portrait)
	add_child(portrait)
	move_child(portrait, 0)
	if research_pips != null:
		move_child(research_pips, -1)
	portrait.position = Vector2.ZERO
	portrait.size = Vector2(ConsoleFrame.PORTRAIT_SIZE, ConsoleFrame.PORTRAIT_SIZE)


func _ready() -> void:
	name = "PortraitWindow"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var w := ConsoleFrame.PORTRAIT_SIZE
	var h := w + SLATE_GAP + SLATE_HEIGHT
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -ConsoleFrame.PORTRAIT_LEFT
	offset_right = offset_left + w
	offset_top = -(900.0 - 696.0)
	offset_bottom = offset_top + h
	_slate = PanelContainer.new()
	_slate.name = "StatusSlate"
	_slate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slate.position = Vector2(0, w + SLATE_GAP)
	_slate.size = Vector2(w, SLATE_HEIGHT)
	_slate.custom_minimum_size = Vector2(w, SLATE_HEIGHT)
	_slate.add_theme_stylebox_override("panel", UIStyle.slate_style(4.0))
	add_child(_slate)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slate.add_child(box)
	team_label = UIStyle.panel_label("", 12)
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	team_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # built with Loc.t
	box.add_child(team_label)
	pop_label = UIStyle.panel_label("", 12)
	pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(pop_label)
	research_pips = Control.new()
	research_pips.name = "ResearchPips"
	research_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	research_pips.position = Vector2(6, 4)
	research_pips.size = Vector2(11.0 * ResearchMarks.PIP_MAX, 10)
	research_pips.draw.connect(_draw_pips)
	add_child(research_pips)
	apply_skin()


func _draw_pips() -> void:
	for i in _pip_count:
		ResearchMarks.draw_pip(research_pips, Vector2(4.0 + 11.0 * i, 4.0))


## Number of research pips shown (tests).
func pip_count() -> int:
	return _pip_count if research_pips != null and research_pips.visible else 0


func apply_skin() -> void:
	if _slate:
		_slate.add_theme_stylebox_override("panel", UIStyle.slate_style(4.0))
		pop_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		_team_key = ""


func _process(_delta: float) -> void:
	_refresh_slate()
	_refresh_pips()


func _refresh_pips() -> void:
	if research_pips == null:
		return
	var t: Node = portrait.target if portrait != null and is_instance_valid(portrait.target) else null
	var n := mini(ResearchMarks.count(t), ResearchMarks.PIP_MAX) if t is Unit else 0
	if n != _pip_count:
		_pip_count = n
		research_pips.queue_redraw()


## The status slate lines for `node` (["", ""] when nothing is shown): team / kingdom, then the pop.
static func slate_lines(node: Node, own_team: int) -> Array[String]:
	var out: Array[String] = ["", ""]
	if node == null or not is_instance_valid(node):
		return out
	var team: Variant = node.get("team")
	var kingdom := kingdom_word(node)
	if team == null:
		return out
	if int(team) == Unit.Team.NEUTRAL:
		out[0] = Loc.t("Neutral")
	elif int(team) == own_team:
		out[0] = Loc.t("{kingdom} · yours", {"kingdom": Loc.t(kingdom)}) if kingdom != "" else Loc.t("Yours")
	else:
		out[0] = Loc.t("{kingdom} · enemy", {"kingdom": Loc.t(kingdom)}) if kingdom != "" else Loc.t("Enemy")
	var type: Variant = node.get("unit_type")
	if type is Object and type.get("pop") != null and int(type.get("pop")) > 0:
		out[1] = Loc.t("Pop %d") % int(type.get("pop"))
	return out


## "Fire" / "Shadow" / "Ice" / "Nature" from the node's unit / building type faction ("" when it has none).
static func kingdom_word(node: Node) -> String:
	for key: StringName in [&"unit_type", &"building_type"]:
		var t: Variant = node.get(key)
		if t is Object and t.get("faction") != null:
			var f := String(t.get("faction"))
			if f in ["fire", "shadow", "ice", "nature"]:
				return f.capitalize()
	if node is Wizard:
		return String(GameHUD.kingdom_of(node)).capitalize()
	return ""


func _refresh_slate() -> void:
	if portrait == null or team_label == null:
		return
	var own := 0
	if selection != null and selection.hero != null and is_instance_valid(selection.hero):
		own = int(selection.hero.team)
	var target: Node = portrait.target if is_instance_valid(portrait.target) else null   # freed: nothing to show
	var lines := slate_lines(target, own)
	var key := "%s|%s|%s" % [lines[0], lines[1], Loc.language]
	if key == _team_key:
		return
	_team_key = key
	team_label.text = lines[0]
	pop_label.text = lines[1]
	pop_label.visible = lines[1] != ""
	var team: Variant = target.get("team") if target != null else null
	var col := UIStyle.token(&"text")
	if team != null and int(team) != own:
		col = Color(0.85, 0.30, 0.30) if int(team) != Unit.Team.NEUTRAL else UIStyle.token(&"text_muted")
	team_label.add_theme_color_override("font_color", col)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mb.double_click:
		select_type_on_screen()
	else:
		centre_on_target()


## Centres the camera on the portrait's target (a click on the portrait).
func centre_on_target() -> void:
	var t: Node = portrait.target if portrait != null and is_instance_valid(portrait.target) else null
	if t == null or not is_instance_valid(t) or not (t is Node3D) or selection == null:
		return
	selection.centre_camera_on([t])


## Double-click: every own commandable unit of the portrait unit's type that is on screen.
func select_type_on_screen() -> void:
	var u := portrait.target as Unit if portrait != null and is_instance_valid(portrait.target) else null
	if u == null or not is_instance_valid(u) or selection == null or selection.camera == null \
			or u.team != Unit.Team.PLAYER:
		return
	var cam := selection.camera
	var screen := get_viewport_rect()
	var same: Array = []
	for node in get_tree().get_nodes_in_group(&"units"):
		var other := node as Unit
		if other != null and other.team == Unit.Team.PLAYER and other.is_alive() and other.unit_name == u.unit_name \
				and SelectionManager.is_commandable_unit(other) and not cam.is_position_behind(other.global_position) \
				and screen.has_point(cam.unproject_position(other.global_position)):
			same.append(other)
	if not same.is_empty():
		selection.select_units(same)
