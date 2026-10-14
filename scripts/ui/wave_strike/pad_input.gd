class_name MusterPadInput
extends Node
## Mouse and pad keys for the player's Muster Pad (docs/design/ui-wave-strike.md 7.3-7.5, task WS3.U2; rules
## wave-strike.md 15.2): hover (model ghost + tooltip), the manual place ghost (left-click places, Shift+click keeps
## it, right-click / Esc cancels), drag to move / swap, drag on empty cells = box select, drag a selected token = move
## the group, right-click a token = sell; P = pad camera (again = back), L = auto-arrange (Line) with a 5 s Ctrl+L undo.
## Reads clicks in _unhandled_input (the HUD keeps its clicks) before SelectionManager (a later node in the tree), and
## only takes the clicks that land on the own pad. The 2D parts (box rectangle, price badge, token tooltip) live on
## the `overlay` Control in the WS HUD.

signal placed(id: StringName, cell: Vector2i)
signal ghost_changed(id: StringName)

const DRAG_PX := 6.0
const UNDO_TIME := 5.0
const PAD_ZOOM := 37.0
const PAD_PITCH := 72.0   ## steeper than the game's 55: the plate sits in a forest clearing
const FLY_TIME := 0.35
const HELD_REFRESH := 0.5
const TIP_DELAY := 0.25

var hud: Node                  ## WaveStrikeHud
var level: Node
var roster: MusterRoster
var view: MusterPadView
var enemy_view: MusterPadView
var overlay: PadOverlay

var _ghost_id: StringName = &""
var _ghost_cell := MusterPad.NONE
var _press := false
var _press_pos := Vector2.ZERO
var _press_cell := MusterPad.NONE
var _press_token := -1
var _dragging := false
var _boxing := false
var _drag_cells: Array[Vector2i] = []
var _drag_anchor := MusterPad.NONE    ## the grabbed token's anchor
var _drag_target := MusterPad.NONE
var _mouse := Vector2.ZERO
var _undo: Variant = null             ## the pad cells before the last L ({id: [[c, r]...]})
var _undo_left := 0.0
var _saved_view: Array = []           ## camera [pos, yaw, zoom] before P
var _at_pad := false
var _pan_serial := 0
var _held_left := 0.0
var _hover_cell := MusterPad.NONE
var _hover_enemy := -1
var _tip_left := 0.0
var _cursor_forbidden := false


func setup(p_hud: Node, p_level: Node, p_roster: MusterRoster, p_view: MusterPadView, p_enemy: MusterPadView,
		p_overlay: PadOverlay) -> void:
	hud = p_hud
	level = p_level
	roster = p_roster
	view = p_view
	enemy_view = p_enemy
	overlay = p_overlay
	name = "MusterPadInput"


func _camera() -> Camera3D:
	return get_viewport().get_camera_3d() if is_inside_tree() else null


func _rig() -> RTSCamera:
	var r: Variant = level.get(&"camera_rig") if level else null
	return r as RTSCamera


## The own pad cell under screen point `p` (NONE off the pad).
func cell_under(p: Vector2, v: MusterPadView = null) -> Vector2i:
	var pv := v if v != null else view
	var cam := _camera()
	if cam == null or pv == null:
		return MusterPad.NONE
	var hit := pv.plate_hit(cam.project_ray_origin(p), cam.project_ray_normal(p))
	if not hit.is_finite():
		return MusterPad.NONE
	return pv.cell_at(hit)


## True when the mouse (last known position) is over the own pad.
func mouse_over_pad() -> bool:
	return cell_under(get_viewport().get_mouse_position()) != MusterPad.NONE


## Screen point of a cell's footprint centre (tests, the mini-pad).
func cell_screen(cell: Vector2i, size := 1, v: MusterPadView = null) -> Vector2:
	var pv := v if v != null else view
	var cam := _camera()
	return cam.unproject_position(pv.cell_pos(cell, size)) if cam else Vector2.ZERO


# ---------------------------------------------------------------- place ghost (15.2)

## True when a buy should show the ghost instead of auto-placing (setting Manual, or the cursor on the own pad).
func wants_ghost() -> bool:
	return GameSettings.ws_place_manual or mouse_over_pad()


func begin_place(id: StringName) -> void:
	_ghost_id = id
	_end_drag(true)
	_update_ghost(get_viewport().get_mouse_position())
	overlay.queue_redraw()
	ghost_changed.emit(id)


func placing() -> StringName:
	return _ghost_id


## The ghost's anchor cell under the cursor (NONE = off the pad / no ghost).
func ghost_cell() -> Vector2i:
	return _ghost_cell if _ghost_id != &"" else MusterPad.NONE


func cancel_place() -> void:
	if _ghost_id == &"":
		return
	_ghost_id = &""
	_ghost_cell = MusterPad.NONE
	view.hide_place_ghost()
	_set_forbidden(false)
	overlay.queue_redraw()
	ghost_changed.emit(&"")


## Pays and places the ghost's copy at `cell`; "" = ok (keeps the ghost when `keep`), else the reason.
func place_at(cell: Vector2i, keep := false) -> String:
	if _ghost_id == &"":
		return "No card"
	var id := _ghost_id
	var why := roster.can_buy(id, cell)
	if why == MusterPad.REASON_TAKEN or why == MusterPad.REASON_OFF:
		view.shake_quads()
		var blocker := roster.pad.copy_at(cell)
		if not blocker.is_empty():
			view.flash_cell(blocker["cell"])
		return why
	why = roster.buy(id, cell)
	if why != "":
		hud.call(&"refuse_card", id, why)
		return why
	placed.emit(id, cell)
	if keep:
		_update_ghost(get_viewport().get_mouse_position())
	else:
		cancel_place()
	return ""


func _update_ghost(p: Vector2) -> void:
	if _ghost_id == &"":
		return
	var size := roster.pad.footprint(_ghost_id)
	var c := cell_under(p)
	if c != MusterPad.NONE:   # the cursor is on the footprint's centre: anchor = its front-left cell
		var hit := view.plate_hit(_camera().project_ray_origin(p), _camera().project_ray_normal(p))
		c = _anchor_for(hit, size)
	_ghost_cell = c
	if c == MusterPad.NONE:
		view.hide_place_ghost()
		_set_forbidden(not _over_gui())
	else:
		view.show_place_ghost(_ghost_id, c, roster.pad.can_place(_ghost_id, c) == "")
		_set_forbidden(false)
	overlay.queue_redraw()


## The anchor cell that centres a `size` footprint on world point `hit`, clamped onto the pad.
func _anchor_for(hit: Vector3, size: int) -> Vector2i:
	if size <= 1:
		return view.cell_at(hit)
	var shift := (view.pad.right() * -0.5 + view.pad.forward * 0.5) * MusterPad.CELL
	var c := view.cell_at(hit + shift)
	if c == MusterPad.NONE:
		c = view.cell_at(hit)
	if c == MusterPad.NONE:
		return c
	return Vector2i(clampi(c.x, 0, MusterPad.COLS - size), clampi(c.y, 0, MusterPad.ROWS - size))


func _over_gui() -> bool:
	var vp := get_viewport()
	return vp != null and vp.gui_get_hovered_control() != null


func _set_forbidden(on: bool) -> void:
	if on == _cursor_forbidden:
		return
	_cursor_forbidden = on
	Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN if on else Input.CURSOR_ARROW)


# ---------------------------------------------------------------- mouse

func _unhandled_input(event: InputEvent) -> void:
	if view == null or bool(level.get(&"game_over")):
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_on_motion(mm.position)
		return
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	_mouse = mb.position
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if _on_left_press(mb.position, mb.shift_pressed):
				get_viewport().set_input_as_handled()
		elif _press:
			_on_left_release(mb.position, mb.shift_pressed)
			get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		if _on_right(mb.position):
			get_viewport().set_input_as_handled()


func _on_motion(p: Vector2) -> void:
	_mouse = p
	if _ghost_id != &"":
		_update_ghost(p)
		return
	if _press:
		if not _dragging and not _boxing and p.distance_to(_press_pos) > DRAG_PX:
			if _press_token >= 0:
				_start_drag()
			else:
				_boxing = true
		if _dragging:
			_update_drag(p)
		elif _boxing:
			overlay.box = Rect2(_press_pos, p - _press_pos).abs()
			overlay.queue_redraw()
		return
	_update_hover(p)


func _update_hover(p: Vector2) -> void:
	var c := cell_under(p)
	var i := view.token_at(c) if c != MusterPad.NONE else -1
	view.set_hover(i)
	var ei := -1
	if i < 0 and enemy_view != null:
		var ec := cell_under(p, enemy_view)
		ei = enemy_view.token_at(ec) if ec != MusterPad.NONE else -1
	var cell := view.tokens()[i]["cell"] as Vector2i if i >= 0 else MusterPad.NONE
	if cell != _hover_cell or ei != _hover_enemy:
		_hover_cell = cell
		_hover_enemy = ei
		_tip_left = TIP_DELAY
		overlay.tip_rows = []
		overlay.queue_redraw()
		set_process(true)
	if not overlay.tip_rows.is_empty():
		overlay.tip_at = p
		overlay.queue_redraw()


## Left press on the own pad: true = taken (SelectionManager never sees it).
func _on_left_press(p: Vector2, shift: bool) -> bool:
	var c := cell_under(p)
	if _ghost_id != &"":
		if c == MusterPad.NONE:
			return false
		_update_ghost(p)
		place_at(_ghost_cell, shift)
		return true
	if c == MusterPad.NONE:
		return false
	_press = true
	_press_pos = p
	_press_cell = c
	_press_token = view.token_at(c)
	_dragging = false
	_boxing = false
	return true


func _on_left_release(p: Vector2, _shift: bool) -> void:
	_press = false
	if _dragging:
		_drop()
	elif _boxing:
		_boxing = false
		_box_select(overlay.box)
		overlay.box = Rect2()
		overlay.queue_redraw()
	elif _press_token >= 0:   # a click on a token selects it alone
		var sel: Array[Vector2i] = [view.tokens()[_press_token]["cell"]]
		view.set_selected(sel)
	else:
		clear_selection()
	_update_hover(p)


func _on_right(p: Vector2) -> bool:
	if _ghost_id != &"":
		cancel_place()
		return true
	if _dragging:
		_end_drag(true)
		return true
	var c := cell_under(p)
	if c == MusterPad.NONE:
		return false
	var i := view.token_at(c)
	if i < 0:
		return false
	sell_at(c)
	return true


## Sells the copy on `cell` (right-click): the card plays its Sold state, a +refund floats.
func sell_at(cell: Vector2i) -> String:
	var c := roster.pad.copy_at(cell)
	if c.is_empty():
		return MusterRoster.REASON_NONE
	var id: StringName = c["id"]
	var before := roster.bank.crystals()
	var why := roster.sell_at(cell)
	if why != "":
		hud.call(&"refuse_card", id, why)
		return why
	overlay.float_text("+%d" % (roster.bank.crystals() - before), UIStyle.CRYSTAL_TEXT, _mouse)
	var sel := view.selected()
	sel.erase(c["cell"])
	view.set_selected(sel)
	hud.call(&"after_pad_change")
	return ""


# ---------------------------------------------------------------- drag (move / swap / group)

func _start_drag() -> void:
	_dragging = true
	var t := view.tokens()[_press_token]
	_drag_anchor = t["cell"]
	var sel := view.selected()
	if sel.has(_drag_anchor) and sel.size() > 1:
		_drag_cells = sel.duplicate()
	else:
		_drag_cells = [_drag_anchor]
		var none: Array[Vector2i] = []
		view.set_selected(none)
	view.set_hover(-1)
	overlay.tip_rows = []
	_update_drag(_mouse)


## The grabbed token's target anchor for the cursor at `p` (the grab point keeps its offset in cells).
func _target_anchor(p: Vector2) -> Vector2i:
	var c := cell_under(p)
	if c == MusterPad.NONE:
		return MusterPad.NONE
	return _drag_anchor + (c - _press_cell)


func _update_drag(p: Vector2) -> void:
	var cam := _camera()
	var hit := view.plate_hit(cam.project_ray_origin(p), cam.project_ray_normal(p))
	var start := view.plate_hit(cam.project_ray_origin(_press_pos), cam.project_ray_normal(_press_pos))
	var off := Vector3.ZERO
	if hit.is_finite() and start.is_finite():
		off = Vector3(hit.x - start.x, 0.0, hit.z - start.z)
	view.set_drag(_drag_cells, off)
	_drag_target = _target_anchor(p)
	var rows: Array = []
	if _drag_target != MusterPad.NONE:
		var delta := _drag_target - _drag_anchor
		var state := _drop_state(delta)
		for cell in _drag_cells:
			var i := view.token_at(cell)
			var s := int(view.tokens()[i]["size"]) if i >= 0 else 1
			rows.append([cell + delta, s, state])
		if state == &"swap":
			view.flash_cell(_drag_target, false)
	if rows.is_empty():
		view.hide_quads()
	else:
		view.show_quads(rows)


## &"free" (the move fits), &"swap" (one token onto another of the same size) or &"blocked".
func _drop_state(delta: Vector2i) -> StringName:
	var pad := roster.pad
	if delta == Vector2i.ZERO:
		return &"free"
	if _drag_cells.size() == 1:
		var to := _drag_anchor + delta
		var other := pad.copy_at(to)
		var mine := pad.copy_at(_drag_anchor)
		if not other.is_empty() and other["cell"] != mine["cell"]:
			if other["cell"] == to and int(other["size"]) == int(mine["size"]):
				return &"swap"
		var i := view.token_at(_drag_anchor)
		var s := int(view.tokens()[i]["size"]) if i >= 0 else 1
		var ignore: Array = []
		ignore.append(_index_of(_drag_anchor))
		return &"free" if pad.in_bounds(to, s) and _fits(StringName(mine["id"]), to, ignore) else &"blocked"
	for cell in _drag_cells:
		var c := pad.copy_at(cell)
		if c.is_empty():
			return &"blocked"
		if not pad.in_bounds(cell + delta, int(c["size"])):
			return &"blocked"
		for dx in int(c["size"]):
			for dy in int(c["size"]):
				var o := pad.copy_at(cell + delta + Vector2i(dx, dy))
				if not o.is_empty() and not _drag_cells.has(o["cell"] as Vector2i):
					return &"blocked"
	return &"free"


func _index_of(anchor: Vector2i) -> int:
	var cs := roster.pad.copies()
	for i in cs.size():
		if cs[i]["cell"] == anchor:
			return i
	return -1


func _fits(id: StringName, to: Vector2i, ignore: Array) -> bool:
	return roster.pad.can_place(id, to, ignore) == ""


func _drop() -> void:
	_dragging = false
	var why := "No target"  # LOC_IGNORE
	var delta := _drag_target - _drag_anchor if _drag_target != MusterPad.NONE else Vector2i.ZERO
	if _drag_target != MusterPad.NONE and delta != Vector2i.ZERO:
		var state := _drop_state(delta)
		if _drag_cells.size() == 1:
			why = roster.pad.swap(_drag_anchor, _drag_target) if state == &"swap" else roster.pad.move(_drag_anchor, _drag_target)
		else:
			why = roster.pad.move_group(_drag_cells, delta)
	var refused := why != ""
	if delta == Vector2i.ZERO and _drag_target != MusterPad.NONE:
		refused = false
	view.end_drag(refused)
	if not refused and _drag_cells.size() > 1:
		var moved: Array[Vector2i] = []
		for c in _drag_cells:
			moved.append(c + delta)
		view.set_selected(moved)
	_drag_cells.clear()
	_drag_target = MusterPad.NONE
	hud.call(&"after_pad_change")


func _end_drag(refused: bool) -> void:
	if not _dragging:
		_press = false
		return
	_dragging = false
	_press = false
	view.end_drag(refused)
	_drag_cells.clear()


## Moves the copy at `from` to `to` (or swaps onto a same-size copy anchored at `to`), as a drag would.
func drag_cell(from: Vector2i, to: Vector2i) -> String:
	var a := roster.pad.copy_at(from)
	var b := roster.pad.copy_at(to)
	if a.is_empty():
		return MusterPad.REASON_EMPTY
	if not b.is_empty() and b["cell"] == to and int(b["size"]) == int(a["size"]) and b["cell"] != a["cell"]:
		return roster.pad.swap(a["cell"], to)
	return roster.pad.move(a["cell"], to)


func _box_select(r: Rect2) -> void:
	var sel: Array[Vector2i] = []
	for t in view.tokens():
		var sp := cell_screen(t["cell"], int(t["size"]))
		if r.has_point(sp):
			sel.append(t["cell"])
	view.set_selected(sel)


func clear_selection() -> void:
	var none: Array[Vector2i] = []
	view.set_selected(none)


## Esc: the ghost, then a drag, then the selection. True when something was cancelled.
func cancel() -> bool:
	if _ghost_id != &"":
		cancel_place()
		return true
	if _dragging:
		_end_drag(true)
		return true
	if not view.selected().is_empty():
		clear_selection()
		return true
	return false


# ---------------------------------------------------------------- L / Ctrl+L, P

## L: re-places every own copy in the Line formation (5 s undo).
func arrange() -> void:
	_undo = roster.pad.save_cells()
	_undo_left = UNDO_TIME
	roster.pad.auto_arrange(&"line")
	clear_selection()
	set_process(true)
	hud.call(&"say", Loc.t("Arranged  ·  %s = undo (%d s)") % [_ctrl_label(KEY_L), int(UNDO_TIME)], UIStyle.token(&"text"))


## Ctrl+L within 5 s of L: the previous cells back. "" = done, else the reason.
func undo_arrange() -> String:
	if _undo == null or _undo_left <= 0.0:
		return "Nothing to undo"
	roster.pad.load_cells(_undo, roster.cards(), &"line")
	_undo = null
	_undo_left = 0.0
	hud.call(&"say", Loc.t("Undone"), UIStyle.token(&"text"))
	return ""


func undo_left() -> float:
	return _undo_left if _undo != null else 0.0


static func _ctrl_label(code: int) -> String:
	return "Ctrl+%s" % KeyLabels.of(code)


## P: the camera flies behind the pad (0.35 s); P again = back to where it was.
func toggle_pad_camera() -> void:
	var rig := _rig()
	if rig == null:
		return
	if _at_pad and rig.pan_serial == _pan_serial and not _saved_view.is_empty():
		rig.fly_to(_saved_view[0], _saved_view[1], _saved_view[2], FLY_TIME, float(_saved_view[3]))
		_at_pad = false
		return
	_saved_view = rig.view_state()
	var pose := view.camera_pose()
	rig.fly_to(pose[0], pose[1], PAD_ZOOM, FLY_TIME, PAD_PITCH)
	_at_pad = true
	_pan_serial = rig.pan_serial


## Centres the camera on pad cell `cell` behind the pad (the mini-pad click).
func focus_cell(cell: Vector2i) -> void:
	var rig := _rig()
	if rig == null:
		return
	if not _at_pad:
		_saved_view = rig.view_state()
	var pose := view.camera_pose()
	var p := view.cell_pos(cell, 1)
	rig.fly_to(Vector3(p.x, 0.0, p.z) + view.pad.forward * 0.5, pose[1], PAD_ZOOM, FLY_TIME, PAD_PITCH)
	_at_pad = true
	_pan_serial = rig.pan_serial


## A pan away from the pad view: the saved yaw / zoom / pitch ease back (the position stays the player's).
func _check_pan() -> void:
	if not _at_pad:
		return
	var rig := _rig()
	if rig == null or rig.pan_serial == _pan_serial or _saved_view.is_empty():
		return
	_at_pad = false
	rig.fly_to(rig.position, _saved_view[1], _saved_view[2], FLY_TIME, float(_saved_view[3]))


func at_pad() -> bool:
	var rig := _rig()
	return _at_pad and rig != null and rig.pan_serial == _pan_serial


# ---------------------------------------------------------------- tooltips (7.5), held markers

func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_check_pan()
	if _undo_left > 0.0:
		_undo_left = maxf(0.0, _undo_left - delta)
		if _undo_left <= 0.0:
			_undo = null
	_held_left -= delta
	if _held_left <= 0.0:
		_held_left = HELD_REFRESH
		_refresh_held()
	if _tip_left > 0.0:
		_tip_left -= delta
		if _tip_left <= 0.0:
			_show_tip()


func _refresh_held() -> void:
	if level == null or not level.has_method(&"field_count"):
		return
	var cap := int(roster.rules.field_cap) if roster.rules else 200
	for v: MusterPadView in [view, enemy_view]:
		if v == null:
			continue
		var room := maxi(0, cap - int(level.call(&"field_count", v.roster.team)))
		v.set_held(maxi(0, v.token_count() - room))


func _show_tip() -> void:
	if _hover_cell != MusterPad.NONE:
		overlay.tip_rows = token_tip(view, view.token_at(_hover_cell))
	elif _hover_enemy >= 0 and enemy_view != null:
		overlay.tip_rows = token_tip(enemy_view, _hover_enemy)
	else:
		overlay.tip_rows = []
	overlay.tip_at = _mouse
	overlay.queue_redraw()


## Token tooltip rows [text, colour, size] (7.5): own = name · rank, cell / spawn row, upgrades, drag / sell; enemy =
## name + x copies.
static func token_tip(v: MusterPadView, i: int) -> Array:
	if v == null or i < 0 or i >= v.tokens().size():
		return []
	var t := v.tokens()[i]
	var id: StringName = t["id"]
	var r := v.roster
	var ut := UnitType.find(String(id))
	var nm := Loc.t(ut.display_name) if ut else String(id)
	if not v.own:
		return [["%s  ·  x%d" % [nm, r.count(id)], UIStyle.token(&"title"), 15]]
	var rank_names: Array[String] = [Loc.t("Recruit"), Loc.t("Drilled"), Loc.t("Elite")]
	var rows: Array = [["%s  ·  %s" % [nm, rank_names[clampi(r.rank(id), 1, 3) - 1]], UIStyle.token(&"title"), 15]]
	var cell: Vector2i = t["cell"]
	var size := int(t["size"])
	var mid := cell.x + size * 0.5 - MusterPad.COLS * 0.5
	var side := Loc.t("centre") if absf(mid) < 0.01 else (Loc.t("left of centre") if mid < 0.0 else Loc.t("right of centre"))
	rows.append([Loc.t("Cell (%d, %d) · spawns row %d, %s") % [cell.x, cell.y, cell.y, side], UIStyle.token(&"text_muted"), 13])
	var ups: PackedStringArray = []
	for slot in 2:
		if r.has_upgrade(id, slot):
			ups.append(Loc.sink(String(r.upgrade_info(id, slot).get("name", ""))))
	if not ups.is_empty():
		rows.append([", ".join(ups), UIStyle.GOLD, 13])
	if bool(t.get("held", false)):
		rows.append([Loc.t("Stays home this horn (lane cap)"), UIStyle.WARN, 13])
	elif bool(t.get("moved", false)):
		rows.append([Loc.t("Moves after the horn count next horn"), UIStyle.token(&"text_muted"), 13])
	var refund := int(roundf(r.unit_price(id) * r.rules.sell_refund))
	rows.append([Loc.t("Drag = move · right-click = sell for %d") % refund, UIStyle.token(&"text_muted"), 13])
	return rows


## The 2D layer of the pad: box-select rectangle, the ghost's price badge, the token tooltip, floating refunds.
class PadOverlay extends Control:
	var input: MusterPadInput
	var box := Rect2()
	var tip_rows: Array = []
	var tip_at := Vector2.ZERO
	var _tip: Control
	var _tip_key := ""
	var _floats: Array[Dictionary] = []

	func _init() -> void:
		name = "PadOverlay"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		set_process(false)

	func float_text(text: String, col: Color, at: Vector2) -> void:
		_floats.append({"text": text, "col": col, "at": at, "t": 0.0})
		set_process(true)

	func _process(delta: float) -> void:
		for i in range(_floats.size() - 1, -1, -1):
			_floats[i]["t"] = float(_floats[i]["t"]) + delta
			if float(_floats[i]["t"]) >= 0.8:
				_floats.remove_at(i)
		if _floats.is_empty():
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		if box.size.length() > 1.0:
			draw_rect(box, Color(UIStyle.GOLD, 0.12))
			draw_rect(box, UIStyle.GOLD, false, 1.0)
		var font := get_theme_default_font()
		if input != null and input.ghost_cell() != MusterPad.NONE:
			var id := input.placing()
			var price := input.roster.unit_price(id)
			var txt := str(price)
			if Input.is_key_pressed(KEY_SHIFT):
				txt += "  ·  " + Loc.t("again")
			var mp := get_local_mouse_position() + Vector2(8, 4)
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 22.0
			draw_rect(Rect2(mp, Vector2(w, 18)), Color(0, 0, 0, 0.75))
			var c := mp + Vector2(8, 9)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4),
					c + Vector2(-4, 0)]), UIStyle.CRYSTAL)
			var col := UIStyle.CRYSTAL_TEXT if input.roster.bank.can_afford(price) else UIStyle.WARN
			draw_string(font, mp + Vector2(16, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		for f in _floats:
			var k := float(f["t"]) / 0.8
			var p: Vector2 = f["at"] + Vector2(10, -6 - 28.0 * k)
			draw_string_outline(font, p, String(f["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 1.0 - k))
			draw_string(font, p, String(f["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(f["col"], 1.0 - k))
		_sync_tip()

	func _sync_tip() -> void:
		var key := str(tip_rows)
		if key != _tip_key:
			_tip_key = key
			if _tip != null:
				_tip.queue_free()
				_tip = null
			if not tip_rows.is_empty():
				_tip = MusterCard.tip_panel(tip_rows)
				_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
				for c in _tip.find_children("*", "Control", true, false):
					(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(_tip)
		if _tip != null:
			var sz := _tip.get_combined_minimum_size()
			var p := tip_at + Vector2(24.0, -sz.y - 8.0)   # above-right: the hovered token's model ghost stays visible
			p.x = clampf(p.x, 4.0, size.x - sz.x - 4.0)
			p.y = clampf(p.y, 4.0, size.y - sz.y - 4.0)
			_tip.position = p
			_tip.size = sz
