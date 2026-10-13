extends SceneTree
## Test for 1.U5 (selection panel + keep selection): panel placement, hero column always visible
## (name click selects the wizard), nothing / one unit / many units views, icon click = select
## that unit, left click selects the keep alone, keep view with queue slots, slot-1 progress,
## click a slot = cancel, rally by right click (ground and crystal node).
## Run:  godot --headless --path . -s tests/test_1_u5.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.u5"
const TIMEOUT_FRAMES := 400

var main: Node
var sel: Node
var panel: Node
var eco: Node
var keep: Node
var frame := 0
var _wait := 0
var _error := ""
var _done := false
var _army: Array = []
var _crystals_before := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _step() -> void:
	match frame:
		5:
			sel = main.selection
			panel = main.hud.selection_panel
			eco = main.get("economy")
			keep = main.get("keep")
			if panel == null:
				_error = "GameHUD has no selection_panel"
				return
			if keep == null or eco == null:
				_error = "main.keep / main.economy missing (systems-coder's 1.S1 / 1.S2)"
				return
			for u in root.get_tree().get_nodes_in_group("units"):
				if u.team == 0 and not u.is_in_group("heroes") and not u.has_method("command_gather"):
					_army.append(u)
			var rect: Rect2 = panel.get_global_rect()
			var screen: Vector2 = root.get_visible_rect().size
			# SC2.U1 (ui-sc2-console.md 1): the console's selection block, x 244, y 692-892 at 1600 x 900.
			var expected := Vector2(244, screen.y - 208)
			if rect.position.distance_to(expected) > 1.5 or absf(rect.size.y - 200.0) > 1.5:
				_error = "selection panel at %s, expected %s, 200 tall" % [rect, expected]
				return
			sel.select_units([])
		7:
			if panel.current_view() != "nothing" or panel.nothing_view.text != "Nothing selected":
				_error = "empty selection shows view '%s'" % panel.current_view()
				return
			if not panel.hero_name.visible or not panel.hero_hp_text.text.begins_with("HP  "):
				_error = "hero column not visible with nothing selected"
				return
			if not panel.hero_mana_text.text.begins_with("Mana  "):
				_error = "hero column has no mana text"
				return
			panel.hero_name.pressed.emit()
			if sel.selected.size() != 1 or sel.selected[0] != main.hero:
				_error = "clicking the hero name did not select the wizard"
				return
		9:
			if panel.current_view() != "single" or panel.single_name.text != main.hero.unit_name \
					or not panel.single_mana.visible:
				_error = "wizard selected: view '%s', name '%s'" % [panel.current_view(), panel.single_name.text]
				return
			sel.select_units([_army[0]])
		11:
			if panel.single_mana.visible or not panel.single_stats.text.begins_with("Damage "):
				_error = "single unit view: mana shown or stats '%s'" % panel.single_stats.text
				return
			if not panel.single_stats.text.contains(" · Range ") or not panel.single_hp_text.text.begins_with("HP "):
				_error = "single unit stats line '%s'" % panel.single_stats.text
				return
			sel.select_units(_army)
		13:
			if panel.current_view() != "multi":
				_error = "%d units selected shows view '%s'" % [_army.size(), panel.current_view()]
				return
			if panel.multi_header.text != "%d selected" % _army.size():   # SC2.U4: the types are the type tabs
				_error = "multi header '%s'" % panel.multi_header.text
				return
			var shown := 0
			for b in panel.icons:
				if b.visible:
					shown += 1
			if shown != _army.size():
				_error = "%d icons shown for %d units" % [shown, _army.size()]
				return
			panel.icons[2].pressed.emit()
			if sel.selected.size() != 1 or sel.selected[0] != _army[2]:
				_error = "icon click did not select only that unit"
				return
			# Left click on the keep selects it alone (HUD hidden: the headless window is 64 px).
			main.hud.visible = false
			main.camera_rig.focus_on(keep.global_position)
		15:
			var p: Vector2 = main.camera_rig.camera.unproject_position(keep.global_position + Vector3.UP * 3.0)
			_click(p, MOUSE_BUTTON_LEFT)
			if sel.selected_building != keep or not sel.selected.is_empty() or not keep.selected:
				_error = "left click on the keep did not select it alone (building=%s, units=%d)" % [
						sel.selected_building, sel.selected.size()]
				return
			# Box drag over the screen: the keep never joins a unit box selection.
			_drag(Vector2(0, 0), root.get_visible_rect().size)
			if sel.selected_building != null and not sel.selected.is_empty():
				_error = "box selection mixed units and the keep"
				return
			sel.select_building(keep)
			if not keep.selected:
				_error = "select_building did not call set_selected(true)"
				return
			sel.select_units([_army[0]])
			if keep.selected or sel.selected_building != null:
				_error = "selecting units did not deselect the keep"
				return
			sel.select_building(keep)
			_crystals_before = eco.crystals
			# The keep trains only workers (wave 2): queue two Cinder Hands.
			keep.queue_unit(_type("cinder_hand"))
			keep.queue_unit(_type("cinder_hand"))
		40:
			main.hud.visible = true
			if panel.current_view() != "keep" or panel.keep_name.text != "Keep":
				_error = "keep selected shows view '%s'" % panel.current_view()
				return
			# Filled slots show the unit's icon (or its name when it has none); empty slots show nothing.
			var qb: Array[Button] = panel.queue_buttons
			if (qb[0].icon == null and qb[0].text != "Cinder Hand") or (qb[1].icon == null and qb[1].text != "Cinder Hand") \
					or qb[2].text != "" or qb[2].icon != null:
				_error = "queue slots show %s / %s / %s" % [panel.queue_buttons[0].text,
						panel.queue_buttons[1].text, panel.queue_buttons[2].text]
				return
			if panel.queue_progress.value <= 0.0:
				_error = "slot 1 progress bar is empty after 25 frames"
				return
			if not panel.keep_hp_text.text.begins_with("HP  2500"):
				_error = "keep HP text '%s'" % panel.keep_hp_text.text
				return
			panel.queue_buttons[1].pressed.emit()      # cancel the second worker
			if keep.queue.size() != 1 or eco.crystals != _crystals_before - 50:
				_error = "slot 2 click did not cancel with refund (queue %d, crystals %d, expected %d)" % [
						keep.queue.size(), eco.crystals, _crystals_before - 50]
				return
			panel.queue_buttons[3].pressed.emit()      # empty slot: nothing happens
			if keep.queue.size() != 1:
				_error = "clicking an empty slot changed the queue"
				return
			if panel.rally_label.text != "Rally: set":
				_error = "rally label '%s', expected 'Rally: set'" % panel.rally_label.text
				return
			# Right click a crystal node with the keep selected = gather rally.
			main.hud.visible = false
			var node: Node3D = main.crystal_nodes.get(&"node_home_a")
			main.camera_rig.focus_on(node.global_position)
		42:
			var node: Node3D = main.crystal_nodes.get(&"node_home_a")
			var p: Vector2 = main.camera_rig.camera.unproject_position(node.global_position + Vector3.UP * 0.6)
			_click(p, MOUSE_BUTTON_RIGHT)
			if not keep.rally_is_node():
				_error = "right click on a crystal node did not set a gather rally"
				return
		44:
			if panel.rally_label.text != "Rally: gather node":
				_error = "rally label '%s', expected 'Rally: gather node'" % panel.rally_label.text
				return
			# Right click the ground = rally point there.
			var ground: Vector3 = main.camera_rig.position + Vector3(0, 0, 0)
			var target := Vector3(ground.x + 6.0, 0.0, ground.z + 6.0)
			var p: Vector2 = main.camera_rig.camera.unproject_position(target)
			_click(p, MOUSE_BUTTON_RIGHT)
			if keep.rally_is_node():
				_error = "right click on the ground kept the gather rally"
				return
			var rp: Vector3 = keep.rally_point()
			if Vector2(rp.x, rp.z).distance_to(Vector2(target.x, target.z)) > 0.5:
				_error = "rally point at %s, expected %s" % [rp, target]
				return
		46:
			main.hud.visible = true
			if panel.rally_label.text != "Rally: set":
				_error = "rally label '%s' after a ground rally" % panel.rally_label.text
				return
			# Hero column when the wizard dies: bars at 0, name greyed.
			main.hero.take_damage(99999.0)
		48:
			if panel.hero_hp.value != 0.0 or not panel.hero_name.disabled:
				_error = "dead wizard: HP bar %s, name disabled %s" % [panel.hero_hp.value, panel.hero_name.disabled]
				return
			_done = true


func _type(id: String) -> Resource:
	for t in keep.trainable_types():
		if str(t.id) == id:
			return t
	return null


func _click(pos: Vector2, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)


func _drag(from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = from
	down.pressed = true
	root.push_input(down)
	var move := InputEventMouseMotion.new()
	move.position = to
	root.push_input(move)
	var up := down.duplicate() as InputEventMouseButton
	up.position = to
	up.pressed = false
	root.push_input(up)
