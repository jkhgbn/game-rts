class_name ScorePanel
extends VBoxContainer
## Step 16a: the end screen's Score tab (GameHUD.show_score): a per-category table for both teams (Military,
## Economy, Map control, Growth, Total) and a small score-over-time line graph drawn in code from
## ScoreKeeper.history() (one point every 30 s). Skinned with UIStyle tokens; team lines in the kingdom colours.
## Reused later by the 2v2 end table (ui-2v2.md).

const KEEPER_SCRIPT := preload("res://scripts/world/score_keeper.gd")
const GRAPH_SIZE := Vector2(520, 150)
const ROWS: Array[StringName] = [&"military", &"economy", &"map", &"growth"]
const ROW_NAMES := {&"military": "Military", &"economy": "Economy", &"map": "Map control", &"growth": "Growth"}

var table: GridContainer
var graph: Control
## What was last shown (tests read it): {"teams": [a, b], "names": [...], "rows": {cat: [a, b]}, "total": [a, b]}.
var shown := {}

var _series: Array = []        # [Array of Vector2 (t, total)] per team
var _colors: Array[Color] = []


func _init() -> void:
	name = "ScorePanel"
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	table = GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 28)
	table.add_theme_constant_override("v_separation", 4)
	table.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(table)
	graph = Control.new()
	graph.name = "ScoreGraph"
	graph.custom_minimum_size = GRAPH_SIZE
	graph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph.draw.connect(_draw_graph)
	add_child(graph)


## Fills the table and the graph. `keeper` = a ScoreKeeper (or anything with breakdown / history); `teams` = [the
## local team, the other]; `names` = their column titles; `colors` = their line colours.
func show_score(keeper: Object, teams: Array, names: Array, colors: Array) -> void:
	for c in table.get_children():
		table.remove_child(c)
		c.queue_free()
	_series.clear()
	_colors.clear()
	shown = {"teams": teams.duplicate(), "names": names.duplicate(), "rows": {}, "total": []}
	_cell("", false, HORIZONTAL_ALIGNMENT_LEFT)
	for i in teams.size():
		_cell(str(names[i]), true, HORIZONTAL_ALIGNMENT_RIGHT, colors[i] as Color)
	var bds: Array[Dictionary] = []
	for t in teams:
		bds.append(keeper.call(&"breakdown", int(t)) as Dictionary)
	for cat in ROWS:
		_cell(ROW_NAMES[cat], false, HORIZONTAL_ALIGNMENT_LEFT)
		var row: Array[int] = []
		for b in bds:
			var v := int(b.get(String(cat), 0))
			row.append(v)
			_cell(KEEPER_SCRIPT.fmt(v), false, HORIZONTAL_ALIGNMENT_RIGHT)
		shown["rows"][String(cat)] = row
	_cell("Total", true, HORIZONTAL_ALIGNMENT_LEFT)
	for i in bds.size():
		var v := int(bds[i].get("total", 0))
		(shown["total"] as Array).append(v)
		_cell(KEEPER_SCRIPT.fmt(v), true, HORIZONTAL_ALIGNMENT_RIGHT, colors[i] as Color)
	for i in teams.size():
		var pts: Array = []
		for p in keeper.call(&"history", int(teams[i])) as Array:
			pts.append(Vector2(float((p as Dictionary)["t"]), float((p as Dictionary)["total"])))
		_series.append(pts)
		_colors.append(colors[i] as Color)
	graph.queue_redraw()


func _cell(text: String, strong: bool, align: HorizontalAlignment, color := Color(0, 0, 0, 0)) -> void:
	var l: Label
	if strong:
		l = UIStyle.number_label(text, 18, color if color.a > 0.0 else UIStyle.token(&"title"))
	else:
		l = UIStyle.panel_label(text, 17, UIStyle.token(&"text"))
	l.horizontal_alignment = align
	l.custom_minimum_size = Vector2(150 if align == HORIZONTAL_ALIGNMENT_LEFT else 130, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.add_child(l)


func _draw_graph() -> void:
	var r := Rect2(Vector2(44, 6), GRAPH_SIZE - Vector2(52, 28))
	graph.draw_rect(r, UIStyle.token(&"groove"), true)
	graph.draw_rect(r, UIStyle.token(&"frame_dark"), false, 1.0)
	var t_max := 1.0
	var s_max := 1.0
	for pts: Array in _series:
		for p: Vector2 in pts:
			t_max = maxf(t_max, p.x)
			s_max = maxf(s_max, p.y)
	var font := ThemeDB.fallback_font
	var muted := UIStyle.token(&"text_muted")
	# Horizontal guides at 1/2 and the top, with their values; time labels at both ends.
	for f: float in [0.5, 1.0]:
		var y := r.end.y - r.size.y * f
		graph.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(muted, 0.25), 1.0)
		graph.draw_string(font, Vector2(0, y + 5), _short(s_max * f), HORIZONTAL_ALIGNMENT_RIGHT, 40, 12, muted)
	graph.draw_string(font, Vector2(r.position.x, r.end.y + 16), "0:00", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, muted)
	graph.draw_string(font, Vector2(r.end.x - 60, r.end.y + 16), "%d:%02d" % [int(t_max) / 60, int(t_max) % 60],
			HORIZONTAL_ALIGNMENT_RIGHT, 60, 12, muted)
	for i in _series.size():
		var line := PackedVector2Array()
		for p: Vector2 in _series[i]:
			line.append(Vector2(r.position.x + r.size.x * p.x / t_max, r.end.y - r.size.y * p.y / s_max))
		if line.size() >= 2:
			graph.draw_polyline(line, _colors[i], 2.0, true)
		elif line.size() == 1:
			graph.draw_circle(line[0], 2.5, _colors[i])


static func _short(v: float) -> String:
	if v >= 1000.0:
		return "%.1fk" % (v / 1000.0)
	return str(roundi(v))
