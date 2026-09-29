class_name IdleWorkerButton
extends Button
## Idle-worker button (playtest 2026-09-27): over the minimap's top-right corner, shows how many own workers are idle.
## Click = next idle worker (F3), Ctrl+click = all idle workers (Ctrl+F3). Hidden while no worker is idle.
## Its key shows on it (2026-09-29): the command card's key badge "F3" bottom-right.

const SIZE := Vector2(48, 34)
const POLL := 0.25   ## Seconds between idle counts.

var selection: SelectionManager
var count_badge: Label
var key_badge: Label   ## "F3".
var _left := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	text = "Idle"
	add_theme_font_size_override("font_size", 12)
	UIStyle.style_button(self)
	CommandCard.keep_badge_room(self)
	key_badge = CommandCard.add_key_badge(self, "F3")
	tooltip_text = "Idle workers  [F3]\nClick / F3: next idle worker\nCtrl+click / Ctrl+F3: all idle workers"
	count_badge = Label.new()
	count_badge.add_theme_font_size_override("font_size", 12)
	count_badge.add_theme_color_override("font_color", Color.BLACK)
	var badge := StyleBoxFlat.new()
	badge.bg_color = UIStyle.GOLD
	badge.set_corner_radius_all(7)
	badge.content_margin_left = 4
	badge.content_margin_right = 4
	count_badge.add_theme_stylebox_override("normal", badge)
	count_badge.position = Vector2(SIZE.x - 14, -8)
	count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_badge)
	visible = false


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
