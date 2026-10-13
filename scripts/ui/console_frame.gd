class_name ConsoleFrame
extends PanelContainer
## The console (docs/design/ui-sc2-console.md 1, task SC2.U1): ONE framed panel across the bottom of the screen,
## y 684-900 at 1600 x 900 (216 tall, content margin 8), heavy frame with studs at the two top corners, drop shadow.
## The minimap, selection block, portrait window and command card are siblings drawn over it in their zones; this node
## only draws the frame, the three dividers (2 px groove + 1 px frame_light, a 6 x 6 diamond at each end) and, on a
## wide screen, the kingdom emblem at alpha 0.06 in the empty right part of the selection block.
## Zones (virtual px at 1600 x 900): the minimap and selection block keep their x from the left edge, the portrait
## window and the command card keep theirs from the right edge, so on an ultrawide screen only the selection block
## widens. `zone_rect(zone)` gives a zone in canvas coordinates (Wave Strike's Muster panel sits in &"muster").

const HEIGHT := 216.0
const MARGIN := 8.0
## Left-anchored zones (x from the left edge, y from the top of a 900 px screen).
const MINIMAP := Rect2(14, 692, 200, 200)
const SELECTION_LEFT := 244.0
## Right-anchored x: distances from the right edge (1600 - x).
const SELECTION_RIGHT := 468.0     ## The selection block ends at x 1132.
const PORTRAIT_LEFT := 456.0       ## Portrait window at x 1144 (136 x 136 at y 696).
const PORTRAIT_SIZE := 136.0
const STATUS_TOP := 840.0          ## Status slate 136 x 44 at (1144, 840).
const CARD_LEFT := 308.0           ## Command card grid at x 1292, y 704 (296 x 176).
const CARD_TOP := 704.0
const CARD_SIZE := Vector2(296, 176)
const INNER_TOP := 692.0
const INNER_BOTTOM := 892.0
## Dividers: x of the 2 px groove (the 1 px light line follows): left-anchored, then right-anchored (1600 - x).
const DIVIDERS_LEFT: Array[float] = [232.0]
const DIVIDERS_RIGHT: Array[float] = [464.0, 316.0]
## The selection block's base width (888 at 1600); wider screens show the emblem in the extra part.
const SELECTION_BASE_WIDTH := 888.0
const EMBLEM_ALPHA := 0.06

var _skin := -1
## Wave Strike (WS2.U1): the Muster panel fills the selection + portrait + card zones; only the minimap divider is drawn
## and no emblem (the panel draws its own dividers).
var muster_mode := false


func _ready() -> void:
	name = "ConsoleFrame"
	mouse_filter = Control.MOUSE_FILTER_STOP   # clicks on the console never reach the battlefield
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = 0.0
	offset_right = 0.0
	offset_top = -HEIGHT
	offset_bottom = 0.0
	custom_minimum_size = Vector2(0, HEIGHT)
	UIStyle.add_drop_shadow(self)
	apply_skin()


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	var st := UIStyle.frame_style(MARGIN, true)
	add_theme_stylebox_override("panel", st)
	queue_redraw()


func _process(_delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_muster_mode(on: bool) -> void:
	muster_mode = on
	queue_redraw()


## Screen width in the HUD's coordinates (the console spans it).
func width() -> float:
	return size.x if size.x > 0.0 else 1600.0


## Top of the console in canvas coordinates (684 at 1600 x 900).
func top() -> float:
	return global_position.y


## A zone in canvas coordinates: &"minimap", &"selection", &"portrait", &"status", &"card", or &"muster" (the selection
## block + portrait + card zones together, x 244 -> right edge - 12, y 692-892: Wave Strike's Muster panel).
func zone_rect(zone: StringName) -> Rect2:
	var w := width()
	var y0 := top()
	var dy := y0 - (900.0 - HEIGHT)   # 0 on a 900 px tall HUD
	match zone:
		&"minimap":
			return Rect2(MINIMAP.position + Vector2(0, dy), MINIMAP.size)
		&"selection":
			return Rect2(SELECTION_LEFT, INNER_TOP + dy, w - SELECTION_RIGHT - SELECTION_LEFT, INNER_BOTTOM - INNER_TOP)
		&"portrait":
			return Rect2(w - PORTRAIT_LEFT, 696.0 + dy, PORTRAIT_SIZE, PORTRAIT_SIZE)
		&"status":
			return Rect2(w - PORTRAIT_LEFT, STATUS_TOP + dy, PORTRAIT_SIZE, 44.0)
		&"card":
			return Rect2(Vector2(w - CARD_LEFT, CARD_TOP + dy), CARD_SIZE)
		&"muster":
			return Rect2(SELECTION_LEFT, INNER_TOP + dy, w - 12.0 - SELECTION_LEFT, INNER_BOTTOM - INNER_TOP)
	return Rect2()


## The divider x positions (groove left edge) in local coordinates, left to right.
func divider_xs() -> Array[float]:
	var out: Array[float] = []
	out.append_array(DIVIDERS_LEFT)
	if muster_mode:
		return out
	for d in DIVIDERS_RIGHT:
		out.append(width() - d)
	return out


## Drawn after the frame's style box (CanvasItem draws NOTIFICATION_DRAW first, then _draw).
func _draw() -> void:
	var groove := UIStyle.token(&"groove")
	var light := UIStyle.token(&"frame_light")
	var y0 := MARGIN
	var y1 := size.y - MARGIN
	for x in divider_xs():
		draw_rect(Rect2(x, y0, 2, y1 - y0), groove)
		draw_rect(Rect2(x + 2, y0, 1, y1 - y0), light)
		for y: float in [y0 + 3.0, y1 - 3.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(x + 1.5, y - 3), Vector2(x + 4.5, y),
					Vector2(x + 1.5, y + 3), Vector2(x - 1.5, y)]), light)
	# Ultrawide: the selection block's empty right part shows the kingdom emblem faintly.
	if muster_mode:
		return
	var sel := zone_rect(&"selection")
	var extra := sel.size.x - SELECTION_BASE_WIDTH
	if extra > 120.0:
		var c := Vector2(sel.position.x + SELECTION_BASE_WIDTH + extra * 0.5, size.y * 0.5)
		UIStyle.draw_emblem(self, UIStyle.get_kingdom(), c, minf(64.0, extra * 0.35),
				Color(UIStyle.token(&"title"), EMBLEM_ALPHA))
