class_name ArmyButton
extends Button
## The Army button of the console's quick row (docs/design/ui-sc2-console.md 3.3, SC2.U3): 36 x 36 at (48, 648) at
## 1600 x 900, right of the idle-worker button. A sword glyph, the army count on a gold badge (top-right, font 10) and
## its key "F2" bottom-right. Click = select the whole army (F2; a second click within the double-tap time centres
## on it), Shift+click = add the army to the selection (Shift+F2). Hidden while the player has no army unit.

const SIZE := Vector2(36, 36)
const POS := Vector2(48, 648)
const POLL := 0.25

var selection: SelectionManager
var count_badge: Label
var key_badge: Label   ## "F2".
var _left := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_NONE
	text = ""
	UIStyle.style_button(self)
	IdleWorkerButton.place_bottom_left(self, POS, SIZE)
	var glyph := Control.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.draw.connect(func() -> void: draw_sword(glyph, Vector2(5, 5), 20.0, UIStyle.token(&"text")))
	add_child(glyph)
	key_badge = CommandCard.add_key_badge(self, "F2")
	tooltip_text = "Army  [F2]\nClick / F2: select every soldier (twice: centre on them)\nShift+click / Shift+F2: add them to the selection"
	count_badge = IdleWorkerButton.count_label(self)
	visible = false


## A sword (blade, guard, grip) pointing up-right in a box of `s` px at `o`.
static func draw_sword(ci: CanvasItem, o: Vector2, s: float, col: Color) -> void:
	var k := s / 20.0
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(18, 1) * k, o + Vector2(19, 2) * k,
			o + Vector2(8, 13) * k, o + Vector2(6, 11) * k]), col)
	ci.draw_line(o + Vector2(3, 10) * k, o + Vector2(10, 17) * k, col, 2.0 * k, true)
	ci.draw_line(o + Vector2(6, 14) * k, o + Vector2(2, 18) * k, col, 2.5 * k, true)


func setup(sel: SelectionManager) -> void:
	selection = sel
	refresh()


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = POLL
		refresh()


## Recounts the army: the badge shows the count; hidden at 0.
func refresh() -> void:
	var n := 0
	if selection != null and is_instance_valid(selection) and selection.is_inside_tree():
		n = selection.army_units().size()
	count_badge.text = str(n)
	visible = n > 0


## The button's action: `add` (Shift+click) adds the army to the selection, else selects it (F2).
func activate(add: bool) -> void:
	if selection == null:
		return
	if add:
		selection.add_army()
	else:
		selection.select_army()
	refresh()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		activate(mb.shift_pressed)
		accept_event()
