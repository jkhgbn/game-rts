class_name IdleWorkerButton
extends Button
## Idle-worker button (playtest 2026-09-27; console quick row ui-sc2-console.md 3.3, SC2.U3): 36 x 36 at (8, 648) at
## 1600 x 900, left of the Army button. A worker glyph (pick), the idle count on a gold badge (top-right, font 10) and
## its key "F3" bottom-right (the command card's key badge). Click = next idle worker (F3), Ctrl+click = all idle
## workers (Ctrl+F3). Hidden while no worker is idle.

const SIZE := Vector2(36, 36)
const POS := Vector2(8, 648)
const POLL := 0.25   ## Seconds between idle counts.

var selection: SelectionManager
var count_badge: Label
var key_badge: Label   ## "F3".
var _left := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	text = ""
	UIStyle.style_button(self)
	place_bottom_left(self, POS, SIZE)
	var glyph := Control.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.draw.connect(func() -> void: draw_pick(glyph, Vector2(5, 5), 20.0, UIStyle.token(&"text")))
	add_child(glyph)
	key_badge = CommandCard.add_key_badge(self, "F3")
	tooltip_text = "Idle workers  [F3]\nClick / F3: next idle worker\nCtrl+click / Ctrl+F3: all idle workers"
	count_badge = count_label(self)
	visible = false


## Anchors `b` bottom-left with its top-left at `pos` on a 1600 x 900 screen.
static func place_bottom_left(b: Control, pos: Vector2, sz: Vector2) -> void:
	b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	b.grow_vertical = Control.GROW_DIRECTION_BEGIN
	b.offset_left = pos.x
	b.offset_right = pos.x + sz.x
	b.offset_top = -(900.0 - pos.y)
	b.offset_bottom = b.offset_top + sz.y


## The gold count badge (font 10, black) in the top-right corner of a quick-row button.
static func count_label(b: Control) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color.BLACK)
	var badge := StyleBoxFlat.new()
	badge.bg_color = UIStyle.GOLD
	badge.set_corner_radius_all(6)
	badge.content_margin_left = 3
	badge.content_margin_right = 3
	l.add_theme_stylebox_override("normal", badge)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.offset_right = -1.0
	l.offset_left = -1.0
	l.offset_top = 1.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	return l


## A worker's pick (handle + head) in a box of `s` px at `o`.
static func draw_pick(ci: CanvasItem, o: Vector2, s: float, col: Color) -> void:
	var k := s / 20.0
	ci.draw_line(o + Vector2(4, 18) * k, o + Vector2(14, 6) * k, col, 2.5 * k, true)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(6, 2) * k, o + Vector2(12, 3) * k, o + Vector2(18, 8) * k,
			o + Vector2(19, 13) * k, o + Vector2(15, 8) * k, o + Vector2(9, 5) * k]), col)


func setup(sel: SelectionManager) -> void:
	selection = sel
	refresh()


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = POLL
		refresh()


## Recounts the idle workers: the badge shows the count; hidden at 0.
func refresh() -> void:
	var n := 0
	if selection != null and is_instance_valid(selection) and selection.is_inside_tree():
		n = selection.idle_workers().size()
	count_badge.text = str(n)
	visible = n > 0


## The button's action: `all` (Ctrl+click) selects every idle worker, else the next one.
func activate(all: bool) -> void:
	if selection == null:
		return
	if all:
		selection.select_all_idle_workers()
	else:
		selection.select_idle_worker()
	refresh()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		activate(mb.ctrl_pressed)
		accept_event()
