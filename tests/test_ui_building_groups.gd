extends SceneTree
## Playtest request 2026-09-27 ("all building on the same hotkey and tab to each one"): a control group holds several
## buildings (2 Halls + the keep); N recalls them all; Tab / Shift+Tab cycle the active building (selection panel chip
## highlight + keep view name, card slots); Z trains at the active one, or at the least busy selected building of
## the same type. Units-only groups behave as before; Tab does nothing with one building.
## Run:  godot --headless --path . -s tests/test_ui_building_groups.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "ui_building_groups"
const TIMEOUT_FRAMES := 5000

var main: Node
var frame := 0
var step := 0
var _wait := 0
var _h1: Node3D
var _h2: Node3D
var _keep: Node3D


func _initialize() -> void:
	main = MenuFlow.start_skirmish(self, 0, &"shadow", &"fire")


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	var sel: SelectionManager = main.get("selection") if main != null else null
	match step:
		0:
			_wait += 1
			if main == null or main.get("hero") == null or main.get("keep") == null or _wait < 30:
				return _wait > 3000 and _finish("skirmish never started")
			var eco: Economy = Economy.for_team(0)
			if eco:
				eco.add(5000)
				eco.pop_cap = 200
			_keep = main.get("keep")
			var bt: Resource = load("res://data/buildings/fire_barracks.tres")
			_h1 = _make_hall(bt, Vector3(14, 0, 0))
			_h2 = _make_hall(bt, Vector3(0, 0, 14))
			if not bool(_h1.call(&"is_constructed")) or not bool(_h2.call(&"is_constructed")):
				return _finish("test Halls not completed")
			_wait = 0
			step = 1
		1:
			_wait += 1
			if _wait < 5:
				return false
			# Ctrl+3 on 2 Halls + the keep, then drop the selection and press 3.
			sel.select_buildings([_h2, _keep, _h1])
			_key(KEY_3, false, true)
			if sel.get_control_group(3).size() != 3:
				return _finish("Ctrl+3 stored %d members, expected 3" % sel.get_control_group(3).size())
			sel.select_units([])
			if not sel.selected_buildings.is_empty() or sel.selected_building != null:
				return _finish("select_units([]) kept buildings selected")
			_key(KEY_3)
			if sel.selected_buildings.size() != 3:
				return _finish("3 recalled %d buildings, expected 3" % sel.selected_buildings.size())
			if sel.selected_building != _keep:
				return _finish("the keep is not the first active building (%s)" % sel.selected_building)
			if not sel.selected.is_empty():
				return _finish("recalling a building group selected units")
			if sel.active_control_group() != 3:
				return _finish("group 3 not shown as the active group (%d)" % sel.active_control_group())
			_wait = 0
			step = 2
		2:
			_wait += 1
			if _wait < 3:
				return false
			var r := _check_active(_keep, 0)
			if r != "":
				return _finish("after recall: " + r)
			_key(KEY_TAB)
			var first_hall := _h1 if _h1.get_instance_id() < _h2.get_instance_id() else _h2
			if sel.selected_building != first_hall:
				return _finish("Tab did not make the first Hall active (%s)" % sel.selected_building)
			_wait = 0
			step = 3
		3:
			_wait += 1
			if _wait < 3:
				return false
			var a := sel.selected_building
			var other := _h2 if a == _h1 else _h1
			var r := _check_active(a, 1)
			if r != "":
				return _finish("after Tab: " + r)
			var types: Array = sel.trainable_types()
			if types.is_empty() or types != a.call("trainable_types"):
				return _finish("card types are not the active Hall's")
			# Z at the active Hall (both idle: the active one wins), Z again: the other (least busy) Hall.
			_key(KEY_Z)
			if (a.get("queue") as Array).size() != 1 or (other.get("queue") as Array).size() != 0:
				return _finish("Z did not queue at the active Hall (%d / %d)" % [(a.get("queue") as Array).size(),
						(other.get("queue") as Array).size()])
			if (_keep.get("queue") as Array).size() != 0:
				return _finish("Z queued at the keep")
			_key(KEY_Z)
			if (other.get("queue") as Array).size() != 1:
				return _finish("second Z did not go to the least busy Hall")
			print("  Z x2: active %s queue %d, other %s queue %d" % [a.name, (a.get("queue") as Array).size(),
					other.name, (other.get("queue") as Array).size()])
			# Shift+Tab back to the keep, Tab Tab to the second Hall, Tab wraps to the keep.
			_key(KEY_TAB, true)
			if sel.selected_building != _keep:
				return _finish("Shift+Tab did not go back to the keep")
			_key(KEY_TAB)
			_key(KEY_TAB)
			if sel.selected_building != other:
				return _finish("Tab Tab did not reach the second Hall")
			_key(KEY_TAB)
			if sel.selected_building != _keep:
				return _finish("Tab did not wrap to the keep")
			# Z at the keep trains the keep's unit there.
			_key(KEY_Z)
			if (_keep.get("queue") as Array).size() != 1:
				return _finish("Z with the keep active did not queue at the keep")
			_wait = 0
			step = 4
		4:
			# Units-only group: unchanged. Tab with one building: nothing.
			var hero: Unit = main.get("hero")
			sel.select_units([hero])
			_key(KEY_4, false, true)
			sel.select_building(_h1)
			_key(KEY_TAB)
			if sel.selected_building != _h1 or sel.selected_buildings.size() != 1:
				return _finish("Tab changed a single-building selection")
			_key(KEY_4)
			if sel.selected.size() != 1 or sel.selected[0] != hero or sel.selected_building != null \
					or not sel.selected_buildings.is_empty():
				return _finish("units group 4 did not recall exactly the wizard")
			# Shift+click style toggle through the API: a group mixing units and buildings recalls its units.
			sel.select_units([hero])
			_key(KEY_5, false, true)
			sel.select_building(_h1)
			_key(KEY_5, true)   # Shift+5 adds the Hall
			sel.select_units([])
			_key(KEY_5)
			if sel.selected.size() != 1 or sel.selected_building != null:
				return _finish("mixed group did not recall its units only")
			# A dead Hall leaves the building selection; the active one moves on.
			sel.select_buildings([_keep, _h1, _h2], _h2)
			_h2.call("take_damage", 99999.0)
			_wait = 0
			step = 5
		5:
			_wait += 1
			if _wait < 5:
				return false
			if sel.selected_buildings.has(_h2) or sel.selected_buildings.size() != 2:
				return _finish("the destroyed Hall stayed selected (%d)" % sel.selected_buildings.size())
			if sel.selected_building == null or not sel.selected_buildings.has(sel.selected_building):
				return _finish("no active building after the active Hall fell")
			return _finish("")
	return false


func _make_hall(bt: Resource, offset: Vector3) -> Node3D:
	var h: Node3D = BuildGrid.create_building(bt)
	h.set(&"team", 0)
	h.position = (main.get("keep") as Node3D).global_position + offset
	main.add_child(h)
	return h


## Selection manager + panel show `b` as the active building; the panel chip `chip` is highlighted.
func _check_active(b: Node3D, chip: int) -> String:
	var sel: SelectionManager = main.get("selection")
	var panel: SelectionPanel = main.get("hud").selection_panel
	panel.refresh()
	if sel.selected_building != b:
		return "active is %s, not %s" % [sel.selected_building, b]
	if panel.current_view() != "keep":
		return "panel view %s" % panel.current_view()
	var type: Variant = b.get("building_type")
	if panel.keep_name.text != str(type.get("display_name")):
		return "panel shows '%s', not the active building" % panel.keep_name.text
	var shown := panel.building_strip_buildings()
	if shown.size() != 3:
		return "building strip shows %d chips" % shown.size()
	if panel.active_building_chip() != chip or shown[chip] != b:
		return "highlighted chip %d, expected %d" % [panel.active_building_chip(), chip]
	print("  active %s (chip %d), strip %s" % [panel.keep_name.text, chip,
			", ".join(shown.map(func(n): return str(n.name)))])
	return ""


func _key(code: Key, shift := false, ctrl := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.shift_pressed = shift
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _finish(reason: String) -> bool:
	paused = false
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
