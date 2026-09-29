extends SceneTree
## Test for the StarCraft II control groups (playtest fix):
## Ctrl+N set, Shift+N add, Alt+N steal, Shift+Alt+N steal and add, key 0 = group 10,
## buildings in groups, dead units leave groups; the group bar above the selection panel
## (one tab per non-empty group, number + count + most common unit, active tab highlighted,
## click = select, double click = centre camera); F2 = army (wizard included), F3 = next idle worker
## (cycles, centres the camera); X = attack-move, C = stop, A and S unused; help text and card letters.
## Keys are sent as physical keycodes with AZERTY printed keycodes where they differ.
## Run:  godot --headless --path . -s tests/test_fix_groups.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "fix_groups"
const TIMEOUT_FRAMES := 400

var main: Node
var sel: Node
var bar: Node
var frame := 0
var _wait := 0
var _error := ""
var _done := false
var _guards: Array = []
var _archers: Array = []
var _workers: Array = []
var _first_idle: Node = null


func _initialize() -> void:
	# UX.1: this test covers the Hero WASD control scheme (W A S D walk, X = attack-move); test_ux_1 covers Classic.
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
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
		1:
			root.size = Vector2i(1600, 900)   # room for the HUD (headless windows are 64 x 64)
			sel = main.selection
			bar = main.hud.get("group_bar")
			main.camera_rig.edge_pan_enabled = false   # headless mouse sits in a screen corner
			if bar == null:
				_error = "GameHUD has no group_bar"
				return
			for u in root.get_tree().get_nodes_in_group("units"):
				if u.team != 0 or u.is_in_group("heroes"):
					continue
				if u.has_method("command_gather"):
					_workers.append(u)
				elif u.unit_name == "Flame Guard":
					_guards.append(u)
				elif u.unit_name == "Ember Archer":
					_archers.append(u)
			if _guards.size() != 5 or _archers.size() != 4 or _workers.size() != 3:
				_error = "expected 5 guards, 4 archers, 3 workers; got %d, %d, %d" % [
						_guards.size(), _archers.size(), _workers.size()]
		3:
			_check_set_add_steal()
		5:
			_check_bar()
		6:
			_check_tab_clicks()
		40:
			_check_tab_double_click()
		41:
			# A dead unit leaves its group and the tab updates.
			_guards[4].take_damage(99999.0)
		44:
			# Group 1 was guards 2, 3, 4 + the wizard: now 3 members, most common still FG.
			if sel.get_control_group(1).size() != 3 or not bar.tab_for_group(1).text.contains("3 FG"):
				_error = "dead guard still in group 1 (%d members, tab '%s')" % [
						sel.get_control_group(1).size(), bar.tab_for_group(1).text]
				return
			_check_f2()
			# F3 needs idle workers: stop the three gatherers and let them stand still.
			for w in _workers:
				w.command_stop()
		80:
			_check_f3()
		81:
			_check_keys_and_text()
			_done = _error == ""


func _check_set_add_steal() -> void:
	# Ctrl+1 = the five guards, Ctrl+4 = the four archers.
	sel.select_units(_guards)
	_key(KEY_1, KEY_AMPERSAND, "ctrl")
	sel.select_units(_archers)
	_key(KEY_4, KEY_APOSTROPHE, "ctrl")
	if sel.get_control_group(1).size() != 5 or sel.get_control_group(4).size() != 4:
		_error = "Ctrl+1 / Ctrl+4 gave %d / %d members" % [sel.get_control_group(1).size(), sel.get_control_group(4).size()]
		return
	# Shift+1 adds the wizard to group 1.
	sel.select_units([main.hero])
	_key(KEY_1, KEY_AMPERSAND, "shift")
	if sel.get_control_group(1).size() != 6 or not sel.get_control_group(1).has(main.hero):
		_error = "Shift+1 did not add the wizard (group 1 has %d)" % sel.get_control_group(1).size()
		return
	# Alt+2 steals two guards: they leave group 1, group 2 is exactly them.
	sel.select_units([_guards[0], _guards[1]])
	_key(KEY_2, KEY_2, "alt")
	var g1: Array = sel.get_control_group(1)
	var g2: Array = sel.get_control_group(2)
	if g2.size() != 2 or g1.has(_guards[0]) or g1.has(_guards[1]) or g1.size() != 4:
		_error = "Alt+2 steal: group 1 has %d (guards 0/1 in it: %s), group 2 has %d" % [
				g1.size(), g1.has(_guards[0]) or g1.has(_guards[1]), g2.size()]
		return
	# Alt+2 again with one archer replaces group 2 (steal = set, not add).
	sel.select_units([_archers[3]])
	_key(KEY_2, KEY_2, "alt")
	if sel.get_control_group(2).size() != 1 or sel.get_control_group(4).has(_archers[3]):
		_error = "second Alt+2 did not replace group 2 / take the archer from group 4"
		return
	# Shift+Alt+2 steals two more archers from group 4 and adds them to group 2.
	sel.select_units([_archers[0], _archers[1]])
	_key(KEY_2, KEY_2, "shift+alt")
	if sel.get_control_group(2).size() != 3 or sel.get_control_group(4).size() != 1:
		_error = "Shift+Alt+2: group 2 has %d (want 3), group 4 has %d (want 1)" % [
				sel.get_control_group(2).size(), sel.get_control_group(4).size()]
		return
	# Key 0 is group 10, and a building can be in a group.
	sel.select_building(main.keep)
	_key(KEY_0, KEY_0, "ctrl")
	sel.select_units([])
	_key(KEY_0, KEY_0)
	if sel.selected_building != main.keep:
		_error = "Ctrl+0 then 0 did not reselect the keep (group 10)"
		return
	# Plain 1 selects group 1 again (3 guards + the wizard).
	_key(KEY_1, KEY_AMPERSAND)
	if sel.selected.size() != 4 or not sel.selected.has(main.hero) or sel.selected_building != null:
		_error = "1 selected %d units, expected 4" % sel.selected.size()


func _check_bar() -> void:
	if bar.visible_groups() != [1, 2, 4, 10]:
		_error = "tabs shown for groups %s, expected [1, 2, 4, 10]" % [bar.visible_groups()]
		return
	# Group 1 = 3 Flame Guards + Vessa: count 4, most common = FG.
	var t1: Button = bar.tab_for_group(1)
	if not t1.text.contains("4 FG") or bar.key_labels[0].text != "1":
		_error = "tab 1 shows '%s' / key '%s', expected '4 FG' / '1'" % [t1.text, bar.key_labels[0].text]
		return
	if not bar.tab_for_group(2).text.contains("3 EA"):
		_error = "tab 2 shows '%s', expected '3 EA'" % bar.tab_for_group(2).text
		return
	if bar.key_labels[9].text != "0" or not bar.tab_for_group(10).text.contains("1 KE"):
		_error = "tab 10 shows key '%s' text '%s', expected '0' / '1 KE'" % [bar.key_labels[9].text, bar.tab_for_group(10).text]
		return
	if bar.highlighted_group() != 1:
		_error = "highlighted tab %d, expected 1 (group 1 is selected)" % bar.highlighted_group()
		return
	# Placement: just above the selection panel, same left edge.
	var panel_rect: Rect2 = main.hud.selection_panel.get_global_rect()
	var tab_rect: Rect2 = t1.get_global_rect()
	if absf(tab_rect.position.x - panel_rect.position.x) > 1.5 or tab_rect.end.y > panel_rect.position.y \
			or panel_rect.position.y - tab_rect.end.y > 8.0:
		_error = "tab 1 at %s, selection panel at %s" % [tab_rect, panel_rect]


func _check_tab_clicks() -> void:
	# Left click on tab 2 (real input) selects group 2 and moves the highlight.
	sel.select_units([])
	_click(bar.tab_for_group(2).get_global_rect().get_center())
	if sel.selected.size() != 3 or not sel.selected.has(_archers[0]):
		_error = "clicking tab 2 selected %d units, expected group 2 (3)" % sel.selected.size()
		return
	bar.refresh()
	if bar.highlighted_group() != 2:
		_error = "highlight on %d after clicking tab 2" % bar.highlighted_group()


func _check_tab_double_click() -> void:
	# Double click on tab 4 (two clicks at once): select + centre the camera on the group.
	main.camera_rig.focus_on(Vector3(40, 0, -40))
	var center: Vector2 = bar.tab_for_group(4).get_global_rect().get_center()
	_click(center)
	_click(center, true)
	var a: Vector3 = _archers[2].global_position
	var cam: Vector3 = main.camera_rig.position
	if sel.selected.size() != 1 or Vector2(cam.x, cam.z).distance_to(Vector2(a.x, a.z)) > 0.5:
		_error = "double click on tab 4: %d selected, camera at %s, group at %s" % [sel.selected.size(), cam, a]


func _check_f2() -> void:
	sel.select_units([])
	_key(KEY_F2, KEY_F2)
	var expected := 0
	for u in root.get_tree().get_nodes_in_group("units"):
		if u.team == 0 and u.is_alive() and not u.has_method("command_gather"):
			expected += 1
	if sel.selected.size() != expected or not sel.selected.has(main.hero):
		_error = "F2 selected %d units (wizard in: %s), expected %d with the wizard" % [
				sel.selected.size(), sel.selected.has(main.hero), expected]
		return
	for u in sel.selected:
		if u.has_method("command_gather"):
			_error = "F2 selected a worker"
			return


func _check_f3() -> void:
	var seen: Array = []
	for i in 3:
		_key(KEY_F3, KEY_F3)
		if sel.selected.size() != 1 or not _workers.has(sel.selected[0]):
			_error = "F3 press %d selected %s, expected one idle worker" % [i + 1, sel.selected]
			return
		var w: Node3D = sel.selected[0]
		if seen.has(w):
			_error = "F3 press %d did not cycle to a new idle worker" % (i + 1)
			return
		seen.append(w)
		var cam: Vector3 = main.camera_rig.position
		if Vector2(cam.x, cam.z).distance_to(Vector2(w.global_position.x, w.global_position.z)) > 0.5:
			_error = "F3 did not centre the camera on the worker"
			return
	_key(KEY_F3, KEY_F3)
	if sel.selected.is_empty() or sel.selected[0] != seen[0]:
		_error = "4th F3 did not wrap around to the first idle worker"
		return
	# A worker with a job is not idle.
	var busy: Node = seen[0]
	busy.command_gather(main.crystal_nodes[&"node_home_a"])
	if sel.idle_workers().has(busy):
		_error = "a gathering worker counts as idle"


func _check_keys_and_text() -> void:
	# X = attack-move targeting, A does nothing (reserved for WASD), C = stop.
	sel.select_units(_archers.slice(0, 2))
	_key(KEY_A, KEY_Q)
	if sel.get_pending_order() != &"":
		_error = "physical A still starts an order"
		return
	_key(KEY_X, KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "X did not start attack-move targeting"
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	var card: Node = main.hud.command_card
	card.refresh()
	var keys: Array = []
	for i in 4:
		keys.append(card.key_labels[i].text)
	if keys != ["M", "C", "H", "X"]:
		_error = "command card letters %s, expected M C H X" % [keys]
		return
	var help_found := false
	for node in main.hud.find_children("*", "Label", true, false):
		var t: String = (node as Label).text
		# "F3: idle (Ctrl all)" since the Tab / unit priority help line (2026-09-27).
		if t.contains("X: attack-move") and t.contains("C: stop") and t.contains("Alt steal") \
				and t.contains("F2: army") and t.contains("F3: idle") and t.contains("F9: restart"):
			help_found = true
	if not help_found:
		_error = "help text does not show the new keys"


func _key(physical: Key, printed: Key, mods := "") -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.ctrl_pressed = mods.contains("ctrl")
	ev.shift_pressed = mods.contains("shift")
	ev.alt_pressed = mods.contains("alt")
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _click(pos: Vector2, double := false) -> void:
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	root.push_input(move)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	ev.double_click = double
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	up.double_click = false
	root.push_input(up)
