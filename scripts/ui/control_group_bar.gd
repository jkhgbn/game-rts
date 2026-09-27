class_name ControlGroupBar
extends HBoxContainer
## Control group tabs (StarCraft II style), just above the selection panel: one tab per non-empty
## group in key order 1-9, 0. Each tab shows the key (gold, top-left), the member count and the
## abbreviation of the most common unit (or building). The tab of the group that is exactly the
## current selection is gold. Left click = select the group, double click = centre the camera.

const TAB_SIZE := Vector2(64, 36)
const GAP := 4
const LEFT := 272.0                   # same left edge as the selection panel
const BOTTOM := 16.0 + 224.0 + 4.0    # 4 px above the selection panel (16 px margin + 224 px panel)
const REFRESH_INTERVAL := 0.25
const NORMAL_BORDER := Color(0.45, 0.4, 0.35, 0.9)

var selection: SelectionManager
var tabs: Array[Button] = []          # index = group - 1 (group 10 = key 0 is last)
var key_labels: Array[Label] = []

var _active := -1
var _refresh_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the tabs take clicks
	add_theme_constant_override("separation", GAP)
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = LEFT
	offset_right = LEFT
	offset_top = -BOTTOM - TAB_SIZE.y
	offset_bottom = -BOTTOM
	for i in SelectionManager.GROUP_COUNT:
		var group := i + 1
		var b := Button.new()
		b.custom_minimum_size = TAB_SIZE
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 14)
		UIStyle.style_button(b)
		b.visible = false
		b.pressed.connect(_on_tab_pressed.bind(group))
		# Chamfered top corners + the gold active line (drawn over the frame).
		var deco := Control.new()
		deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deco.set_anchors_preset(Control.PRESET_FULL_RECT)
		deco.draw.connect(_draw_tab_deco.bind(deco, group))
		b.add_child(deco)
		# Key digit on a 12 x 12 badge, top-left.
		var badge := ColorRect.new()
		badge.color = Color(0, 0, 0, 0.75)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.position = Vector2(4, 4)
		badge.size = Vector2(12, 12)
		b.add_child(badge)
		var key := UIStyle.panel_label(SelectionManager.group_label(group), 11, UIStyle.GOLD)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key.position = Vector2(4, 4)
		key.size = Vector2(12, 12)
		key.custom_minimum_size = Vector2(12, 12)
		b.add_child(key)
		add_child(b)
		tabs.append(b)
		key_labels.append(key)


func setup(p_selection: SelectionManager) -> void:
	selection = p_selection
	if not selection.groups_changed.is_connected(refresh):
		selection.groups_changed.connect(refresh)
	if not selection.selection_changed.is_connected(refresh):
		selection.selection_changed.connect(refresh)
	refresh()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_INTERVAL
		refresh()


## Rebuilds the tabs from the selection manager's groups.
func refresh() -> void:
	if selection == null:
		return
	var active := selection.active_control_group()
	for i in tabs.size():
		var group := i + 1
		var b := tabs[i]
		var members := selection.get_control_group(group)
		b.visible = not members.is_empty()
		if members.is_empty():
			continue
		var summary := _summary(members)
		b.text = "  %d %s" % [members.size(), UIStyle.abbrev(summary[0][0])]
		var parts: Array[String] = []
		for entry in summary:
			parts.append("%d %s" % [entry[1], entry[0]])
		b.tooltip_text = "Group %s: %s\nClick: select  ·  Double-click: centre camera" % [
				SelectionManager.group_label(group), ", ".join(parts)]
	if active != _active:
		if _active > 0:
			UIStyle.style_button(tabs[_active - 1])
			tabs[_active - 1].propagate_call(&"queue_redraw")
		if active > 0:
			UIStyle.style_button(tabs[active - 1], UIStyle.GOLD)
			tabs[active - 1].propagate_call(&"queue_redraw")
		_active = active


## Re-applies the kingdom skin (GameHUD.setup calls it after UIStyle.set_kingdom).
func apply_skin() -> void:
	for i in tabs.size():
		UIStyle.style_button(tabs[i], UIStyle.GOLD if i + 1 == _active else UIStyle.PANEL_BORDER)
		tabs[i].propagate_call(&"queue_redraw")


## The two top corners cut 6 px (dark wedges over the frame) and, on the active tab, a 2 px gold line
## along the bottom edge.
func _draw_tab_deco(c: Control, group: int) -> void:
	var w := c.size.x
	var h := c.size.y
	var dark := Color(0, 0, 0, 0.85)
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(6, 0), Vector2(0, 6)]), dark)
	c.draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, 6), Vector2(w - 6, 0)]), dark)
	var rim := UIStyle.GOLD if group == _active else UIStyle.token(&"frame_light")
	c.draw_line(Vector2(0, 6), Vector2(6, 0), rim, 1.0, true)
	c.draw_line(Vector2(w - 6, 0), Vector2(w, 6), rim, 1.0, true)
	if group == _active:
		c.draw_rect(Rect2(2, h - 2, w - 4, 2), UIStyle.GOLD)


## The shown groups, in tab order (for tests).
func visible_groups() -> Array[int]:
	var out: Array[int] = []
	for i in tabs.size():
		if tabs[i].visible:
			out.append(i + 1)
	return out


## The highlighted group (the one that is exactly the selection), or 0 (for tests).
func highlighted_group() -> int:
	return maxi(_active, 0)


func tab_for_group(group: int) -> Button:
	return tabs[group - 1] if group >= 1 and group <= tabs.size() else null


## [[name, count], ...] sorted by count (most common first; ties keep group order).
func _summary(members: Array) -> Array:
	var counts := {}
	var order: Array[String] = []
	for m in members:
		var member_name := _member_name(m)
		if not counts.has(member_name):
			order.append(member_name)
		counts[member_name] = int(counts.get(member_name, 0)) + 1
	var out: Array = []
	for member_name in order:
		out.append([member_name, counts[member_name]])
	# Stable: equal counts keep the order they first appear in.
	var sorted: Array = []
	for entry in out:
		var at := sorted.size()
		for j in sorted.size():
			if int(entry[1]) > int(sorted[j][1]):
				at = j
				break
		sorted.insert(at, entry)
	return sorted


func _member_name(m: Object) -> String:
	if m is Unit:
		return (m as Unit).unit_name
	var type: Variant = m.get("building_type")
	if type is Object:
		return str(type.get("display_name"))
	return "Building"


## Left click selects; two clicks within 0.4 s centre the camera (the selection manager's double tap).
func _on_tab_pressed(group: int) -> void:
	if selection:
		selection.recall_control_group(group)
