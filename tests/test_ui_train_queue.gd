extends SceneTree
## Playtest fix 2026-09-27 ("unit in ui not visible what i train"): with the keep or a completed Hall selected,
## the selection panel shows the training queue: one slot per queued unit (icon, or the unit's name as text),
## the progress bar under slot 1, the queue count, all on screen and not hidden by another panel; clicking a
## slot still cancels it. Skirmish Fire vs Shadow, checked at 1600 x 900 and 1920 x 1080.
## Run:  godot --headless --path . -s tests/test_ui_train_queue.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "ui_train_queue"
const TIMEOUT_FRAMES := 5000

var main: Node
var frame := 0
var step := 0
var _wait := 0
var _hall: Node3D


func _initialize() -> void:
	main = MenuFlow.start_skirmish(self, 0, &"shadow", &"fire")


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	match step:
		0:
			_wait += 1
			if main == null or main.get("hero") == null or main.get("keep") == null or _wait < 30:
				return _wait > 3000 and _finish("skirmish never started")
			var eco: Economy = Economy.for_team(0)
			if eco:
				eco.add(5000)
				eco.pop_cap = 200
			var keep: Node3D = main.get("keep")
			var sel: SelectionManager = main.get("selection")
			_set_screen(Vector2i(1600, 900))
			sel.select_building(keep)
			var types: Array = keep.call("trainable_types")
			if types.is_empty():
				return _finish("the keep trains nothing")
			for i in 3:
				var r := str(keep.call("queue_unit", types[0]))
				if r != "":
					return _finish("keep refused to queue: %s" % r)
			_wait = 0
			step = 1
		1:
			_wait += 1
			if _wait < 20:
				return false
			var r := _check_panel(main.get("keep"), 3, Vector2i(1600, 900))
			if r != "":
				return _finish("keep: " + r)
			# Click slot 3 cancels it.
			var panel: SelectionPanel = main.get("hud").selection_panel
			panel.queue_buttons[2].pressed.emit()
			var q: Array = main.get("keep").get("queue")
			if q.size() != 2:
				return _finish("clicking queue slot 3 did not cancel it (queue %d)" % q.size())
			# A completed Hall.
			var bt: Resource = load("res://data/buildings/fire_barracks.tres")
			_hall = BuildGrid.create_building(bt)
			_hall.set(&"team", 0)
			var kp: Vector3 = (main.get("keep") as Node3D).global_position
			_hall.position = kp + Vector3(14, 0, 0)
			main.add_child(_hall)
			if not bool(_hall.call(&"is_constructed")):
				return _finish("the test Hall is not completed")
			main.get("selection").select_building(_hall)
			var types: Array = _hall.call("trainable_types")
			if types.is_empty():
				return _finish("the Hall trains nothing")
			for i in 2:
				var rr := str(_hall.call("queue_unit", types[0]))
				if rr != "":
					return _finish("Hall refused to queue: %s" % rr)
			_wait = 0
			step = 2
		2:
			_wait += 1
			if _wait < 20:
				return false
			var r := _check_panel(_hall, 2, Vector2i(1600, 900))
			if r != "":
				return _finish("hall: " + r)
			_set_screen(Vector2i(1920, 1080))
			_wait = 0
			step = 3
		3:
			_wait += 1
			if _wait < 10:
				return false
			var r := _check_panel(_hall, 2, Vector2i(1920, 1080))
			if r != "":
				return _finish("hall at 1920x1080: " + r)
			return _finish("")
	return false


## The headless window is stuck at 64 x 64: lay the HUD's full-screen roots out at `screen` by hand.
var _screen_roots: Array[Control] = []


func _set_screen(screen: Vector2i) -> void:
	if _screen_roots.is_empty():
		for n in root.find_children("*", "Control", true, false):
			var c := n as Control
			if c.get_parent() is Control or not c.is_visible_in_tree() or c.get_window() != root:
				continue
			if c.anchor_right == 1.0 and c.anchor_bottom == 1.0 and c.anchor_left == 0.0 and c.anchor_top == 0.0:
				c.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
				_screen_roots.append(c)
	for c in _screen_roots:
		c.position = Vector2.ZERO
		c.size = Vector2(screen)


func _check_panel(building: Node3D, count: int, screen: Vector2i) -> String:
	var hud: GameHUD = main.get("hud")
	var panel: SelectionPanel = hud.selection_panel
	var sel: SelectionManager = main.get("selection")
	if sel.selected_building != building:
		return "building not selected"
	if panel.current_view() != "keep":
		return "panel view is %s, not keep" % panel.current_view()
	var q: Array = building.get("queue")
	print("[%dx%d] %s queue=%d progress=%.2f panel rect=%s" % [screen.x, screen.y, building.name, q.size(),
			float(building.call("train_progress")), panel.get_global_rect()])
	print("  root=%s panel parent=%s" % [root.size, (panel.get_parent() as Control).get_global_rect() if panel.get_parent() is Control else "n/a"])
	if q.size() != count:
		return "queue has %d, expected %d" % [q.size(), count]
	var vp := Rect2(Vector2.ZERO, Vector2(screen))
	for i in count:
		var b: Button = panel.queue_buttons[i]
		var rect := b.get_global_rect()
		var name_text := str(q[i].get("display_name"))
		print("  slot %d: text='%s' icon=%s visible=%s rect=%s tooltip='%s'" % [i, b.text, b.icon != null,
				b.is_visible_in_tree(), rect, b.tooltip_text.get_slice("\n", 0)])
		if not b.is_visible_in_tree():
			return "queue slot %d is hidden" % (i + 1)
		if b.icon == null and b.text.strip_edges() == "":
			return "queue slot %d shows nothing" % (i + 1)
		if b.icon == null and not b.text.contains(name_text.get_slice(" ", 0)):
			return "queue slot %d has no icon and not the unit's name (%s)" % [i + 1, b.text]
		if not vp.encloses(rect):
			return "queue slot %d off screen (%s)" % [i + 1, rect]
		var cover := _covering(rect.get_center(), panel)
		if cover != "":
			return "queue slot %d covered by %s" % [i + 1, cover]
	var bar: ProgressBar = panel.queue_progress
	print("  progress bar visible=%s value=%.2f rect=%s" % [bar.is_visible_in_tree(), bar.value, bar.get_global_rect()])
	if not bar.is_visible_in_tree() or bar.get_global_rect().size.y < 3.0 or not vp.encloses(bar.get_global_rect()):
		return "progress bar not visible"
	var cnt: Label = panel.get("queue_count") as Label
	if cnt == null or not cnt.is_visible_in_tree() or not cnt.text.contains(str(count)):
		return "no visible queue count (%s)" % (cnt.text if cnt else "missing")
	print("  count: '%s' rect=%s" % [cnt.text.replace("\n", " | "), cnt.get_global_rect()])
	if not vp.encloses(cnt.get_global_rect()) or _covering(cnt.get_global_rect().get_center(), panel) != "":
		return "queue count off screen or covered"
	if not cnt.text.contains(str(q[0].get("display_name"))):
		return "queue count does not name the unit in training (%s)" % cnt.text
	# The name fallback when a unit has no icon: the slot shows the full name.
	var fake := UnitType.new()
	fake.id = &"no_icon_test_unit"
	fake.display_name = "Test Walker"
	var qq: Array = building.get("queue")
	var saved: Variant = qq[count - 1]
	qq[count - 1] = fake
	panel.refresh()
	var fb: Button = panel.queue_buttons[count - 1]
	var ok := fb.icon == null and fb.text == "Test Walker"
	qq[count - 1] = saved
	panel.refresh()
	if not ok:
		return "slot without an icon does not fall back to the name (text '%s', icon %s)" % [fb.text, fb.icon != null]
	return ""


## A visible Control drawn above `point` that is not part of the selection panel (another panel on top).
func _covering(point: Vector2, panel: Control) -> String:
	var panel_layer := _layer_of(panel)
	var found := ""
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c == panel or panel.is_ancestor_of(c) or c.is_ancestor_of(panel) or not c.is_visible_in_tree() \
				or c.get_window() != root:   # popups / tooltips are their own (hidden) windows
			continue
		if c.mouse_filter == Control.MOUSE_FILTER_IGNORE and not (c is Panel or c is PanelContainer):
			continue
		if not c.get_global_rect().has_point(point):
			continue
		var layer := _layer_of(c)
		var above := layer > panel_layer or (layer == panel_layer and _after(c, panel))
		if above:
			found += "%s (%s) " % [c.get_path(), c.get_class()]
	return found


func _layer_of(n: Node) -> int:
	var p := n
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


## True when `a` is drawn after `b` (later in tree order, same canvas layer).
func _after(a: Node, b: Node) -> bool:
	var common := a
	while common != null and not common.is_ancestor_of(b):
		common = common.get_parent()
	if common == null:
		return false
	var ca := a
	while ca.get_parent() != common:
		ca = ca.get_parent()
	var cb := b
	while cb.get_parent() != common:
		cb = cb.get_parent()
	return ca.get_index() > cb.get_index()


func _finish(reason: String) -> bool:
	paused = false
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
