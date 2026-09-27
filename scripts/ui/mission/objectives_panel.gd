class_name ObjectivesPanel
extends PanelContainer
## Mission objectives (top-left, replaces the skirmish objective text; task M7.U1, mission-01.md "Objectives").
## Slate panel at (16, 16) (ui-style.md 3.2 / 4): primary rows font 17 `title`, secondary rows font 15 `text`,
## a drawn marker per row (active = hollow box, done = green check, failed = red cross), counters and countdowns.
##
## Data: the mission node's `objectives()` returns an Array of Dictionaries (or a Dictionary id -> Dictionary):
##   id: StringName, text: String, primary: bool (or type: "primary" / "secondary"),
##   state: "hidden" / "active" / "done" / "failed" (missing = "active"),
##   optional progress: int + goal: int  -> " (1 / 3)" appended unless the text already has "(",
##   optional time_left: float seconds    -> " (1:23)" countdown (WARN colour under 10 s).
## Events.objective_changed(id, state) overrides the state and re-reads objectives(); the panel also polls
## objectives() 4 times a second for counters and countdowns. Without a mission node, rows come from events only.

const POLL_SECONDS := 0.25
const DONE_COLOR := Color(0.3, 0.9, 0.35)

var mission: Node   ## The node with objectives() (may be null: events only).

var _box: VBoxContainer
var _primary: VBoxContainer
var _secondary: VBoxContainer
var _secondary_header: Label
var _rows := {}      # id -> {row: HBoxContainer, label: Label, marker: Control, primary: bool}
var _states := {}    # id -> state from events (wins over the mission's own state)
var _poll := 0.0
var _skin := -1


func _ready() -> void:
	name = "ObjectivesPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(16, 16)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_primary = VBoxContainer.new()
	_primary.add_theme_constant_override("separation", 2)
	_primary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_primary)
	_secondary_header = UIStyle.display_label("Secondary", 12, UIStyle.token(&"text_muted"))
	_secondary_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_secondary_header)
	_secondary = VBoxContainer.new()
	_secondary.add_theme_constant_override("separation", 2)
	_secondary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_secondary)
	apply_skin()
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.connect(&"objective_changed", _on_objective_changed)
	refresh()


func setup(mission_node: Node) -> void:
	mission = mission_node
	refresh()


func _process(delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()
	_poll -= delta
	if _poll <= 0.0:
		_poll = POLL_SECONDS
		refresh()


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	add_theme_stylebox_override("panel", UIStyle.slate_style())
	_secondary_header.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for id: StringName in _rows:
		_restyle(id, row_state(id))


# --- Public (tests, mission scripts) -----------------------------------------------------------------

## The row text as shown ("" if there is no such row or it is hidden).
func row_text(id: StringName) -> String:
	if not _rows.has(id) or not (_rows[id].row as Control).visible:
		return ""
	return (_rows[id].label as Label).text


## &"active", &"done", &"failed" or &"" (no row / hidden).
func row_state(id: StringName) -> StringName:
	if not _rows.has(id):
		return &""
	return _rows[id].get("state", &"")


func is_primary(id: StringName) -> bool:
	return _rows.has(id) and bool(_rows[id].primary)


## Re-reads the mission's objectives() (cheap: labels change only when their text changes).
func refresh() -> void:
	var list := _read_objectives()
	var seen := {}
	for d: Dictionary in list:
		var id := StringName(str(d.get("id", "")))
		if id == &"":
			continue
		seen[id] = true
		var state := StringName(str(_states.get(id, d.get("state", "active"))))
		_show_row(id, _format_text(d), _is_primary_dict(d), state, float(d.get("time_left", -1.0)))
	# Rows known only from events (no mission node, or an id the mission does not list).
	for id: StringName in _states:
		if not seen.has(id):
			var text := String(id).trim_prefix("obj_").trim_prefix("sec_").replace("_", " ").capitalize()
			if _rows.has(id):
				text = (_rows[id].label as Label).text
			_show_row(id, text, not String(id).begins_with("sec_"), _states[id], -1.0)
	_secondary_header.visible = false
	for c in _secondary.get_children():
		if (c as Control).visible:
			_secondary_header.visible = true
			break
	visible = _visible_rows() > 0
	reset_size()


# --- Internals ---------------------------------------------------------------------------------------

func _on_objective_changed(id: StringName, state: StringName) -> void:
	var before := row_state(id)
	_states[id] = state
	refresh()
	if before != state and _rows.has(id) and (state == &"done" or state == &"failed"):
		var row: Control = _rows[id].row
		var t := create_tween()
		row.modulate = Color(1.6, 1.5, 1.2) if state == &"done" else Color(1.6, 0.8, 0.8)
		t.tween_property(row, "modulate", Color.WHITE, 0.6)


func _read_objectives() -> Array:
	var out: Array = []
	if mission == null or not is_instance_valid(mission) or not mission.has_method(&"objectives"):
		return out
	var raw: Variant = mission.call(&"objectives")
	if raw is Array:
		for d: Variant in raw:
			if d is Dictionary:
				out.append(d)
	elif raw is Dictionary:
		for key: Variant in raw:
			var d: Variant = raw[key]
			if d is Dictionary:
				var copy: Dictionary = (d as Dictionary).duplicate()
				if not copy.has("id"):
					copy["id"] = key
				out.append(copy)
	return out


static func _is_primary_dict(d: Dictionary) -> bool:
	if d.has("primary"):
		return bool(d.primary)
	return str(d.get("type", "primary")).to_lower() != "secondary"


static func _format_text(d: Dictionary) -> String:
	var text := str(d.get("text", d.get("id", "")))
	if d.has("goal") and int(d.goal) > 0 and not text.contains("("):
		text += " (%d / %d)" % [int(d.get("progress", 0)), int(d.goal)]
	var left := float(d.get("time_left", -1.0))
	if left >= 0.0:
		var s := int(ceil(left))
		var clock := "%d:%02d" % [floori(s / 60.0), s % 60]
		var open := text.rfind("(")
		if open >= 0 and text.ends_with(")") and text.substr(open).contains(":"):
			text = text.substr(0, open) + "(" + clock + ")"   # "Survive ... (2:00)" counts down in place
		else:
			text += " (" + clock + ")"
	return text


func _show_row(id: StringName, text: String, primary: bool, state: StringName, time_left: float) -> void:
	if not _rows.has(id):
		_make_row(id, primary)
	var r: Dictionary = _rows[id]
	var row: HBoxContainer = r.row
	var hidden := state == &"hidden" or state == &"inactive" or state == &""
	row.visible = not hidden
	var label: Label = r.label
	if label.text != text:
		label.text = text
	var urgent := time_left >= 0.0 and time_left < 10.0 and state == &"active"
	if r.get("state", &"") != state or bool(r.get("urgent", false)) != urgent:
		r.state = state
		r.urgent = urgent
		_restyle(id, state)


func _make_row(id: StringName, primary: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marker := Control.new()
	marker.custom_minimum_size = Vector2(14, 14)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.draw.connect(_draw_marker.bind(marker, id))
	row.add_child(marker)
	var label := UIStyle.label("", 17 if primary else 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	(_primary if primary else _secondary).add_child(row)
	_rows[id] = {row = row, label = label, marker = marker, primary = primary, state = &"", urgent = false}


func _restyle(id: StringName, state: StringName) -> void:
	var r: Dictionary = _rows[id]
	var label: Label = r.label
	var c := UIStyle.token(&"title") if bool(r.primary) else UIStyle.token(&"text")
	match state:
		&"done":
			c = UIStyle.token(&"text_muted")
		&"failed":
			c = UIStyle.DEFEAT
		_:
			if bool(r.get("urgent", false)):
				c = UIStyle.WARN
	label.add_theme_color_override("font_color", c)
	(r.marker as Control).queue_redraw()


func _draw_marker(m: Control, id: StringName) -> void:
	var state := row_state(id)
	var rect := Rect2(1, 1, 12, 12)
	match state:
		&"done":
			m.draw_rect(rect, Color(0, 0, 0, 0.5))
			m.draw_rect(rect, DONE_COLOR, false, 1.0)
			m.draw_polyline(PackedVector2Array([Vector2(3.5, 7), Vector2(6, 10), Vector2(11, 3.5)]), DONE_COLOR, 2.0)
		&"failed":
			m.draw_rect(rect, Color(0, 0, 0, 0.5))
			m.draw_rect(rect, UIStyle.DEFEAT, false, 1.0)
			m.draw_line(Vector2(4, 4), Vector2(10, 10), UIStyle.DEFEAT, 2.0)
			m.draw_line(Vector2(10, 4), Vector2(4, 10), UIStyle.DEFEAT, 2.0)
		_:
			m.draw_rect(rect, Color(0, 0, 0, 0.5))
			m.draw_rect(rect, UIStyle.token(&"frame_light"), false, 1.0)
			if is_primary(id):
				m.draw_rect(Rect2(5, 5, 4, 4), UIStyle.token(&"trim_glow"))


func _visible_rows() -> int:
	var n := 0
	for id: StringName in _rows:
		if (_rows[id].row as Control).visible:
			n += 1
	return n
