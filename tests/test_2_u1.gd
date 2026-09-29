extends SceneTree
## Test for 2.U1 on the 1v1 map (scenes/skirmish.tscn), with real input events (push_input,
## physical keycodes, AZERTY printed keycodes where they differ):
## - W / D walk Vessa camera-relative (camera rotated), the camera follows her, release = ZERO,
##   works with the keep selected, never while a text field has focus;
## - B opens the build menu (Hearth Z / Hall X / Spire C / Back), Esc closes it; B X + click places an
##   Ember Hall where valid (crystals -150, workers build it); an invalid spot shows the refusal above
##   the ghost and as a message; Shift+click keeps placing;
## - a construction site selected: Cancel card, Delete cancels it (75 % refund);
## - a barracks selected: slots Z X C V + rally, Z queues a Flame Guard; panel shows name and queue;
## - hero column: countdown while Vessa is dead, F1 centres on the keep, un-greyed after respawn, crown line;
## - top bar match timer; the end banner with the stats when the Shadow side loses.
## Run:  godot --headless --path . -s tests/test_2_u1.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "2.u1"
const TIMEOUT_FRAMES := 700
const WARM_UP := 90

var main: Node
var sel: Node
var card: Node
var panel: Node
var eco: Node
var keep: Node
var grid: Node
var frame := 0
var _wait := 0
var _warm := 0
var _error := ""
var _done := false
var _workers: Array = []
var _start := Vector3.ZERO
var _site: Node = null
var _hall: Node = null
var _crystals := 0
var _line_edit: LineEdit
var _end_frame := -1


func _initialize() -> void:
	# UX.1: this test covers the Hero WASD control scheme (W A S D walk, X = attack-move); test_ux_1 covers Classic.
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	# Units only start moving once the navigation map has synced (a second or so after the bake).
	_warm += 1
	if _warm < WARM_UP:
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
			main.camera_rig.edge_pan_enabled = false
			sel = main.selection
			card = main.hud.command_card
			panel = main.hud.selection_panel
			eco = main.economy
			keep = main.keep
			grid = main.build_grid
			for u in root.get_tree().get_nodes_in_group("units"):
				if u.team == 0 and u.has_method("command_build"):
					_workers.append(u)
			if _workers.size() != 3:
				_error = "expected 3 Cinder Hands, found %d" % _workers.size()
				return
			# WASD with the keep selected and the camera turned 45 degrees.
			main.camera_rig.rotation.y = -PI / 4.0
			sel.select_building(keep)
			_start = main.hero.global_position
			_key_event(KEY_W, KEY_Z, true)       # AZERTY prints Z on the physical W key
		40:
			var moved: Vector3 = main.hero.global_position - _start
			var forward := _flat(-main.camera_rig.camera.global_transform.basis.z)
			if moved.length() < 1.5 or _flat(moved).dot(forward) < 0.9:
				_error = "W moved Vessa %s, expected ~2.8 m along the camera forward %s" % [moved, forward]
				return
			var cam: Vector3 = main.camera_rig.position
			var hp: Vector3 = main.hero.global_position
			if Vector2(cam.x - hp.x, cam.z - hp.z).length() > 0.6:
				_error = "the camera did not follow Vessa while W was held (camera %s, Vessa %s)" % [cam, hp]
				return
			if sel.selected_building != keep:
				_error = "walking with W changed the selection"
				return
			_key_event(KEY_W, KEY_Z, false)
		42:
			if main.hero.get_move_input() != Vector3.ZERO:
				_error = "releasing W did not send Vector3.ZERO"
				return
			_start = main.hero.global_position
			_key_event(KEY_D, KEY_D, true)
		62:
			var moved: Vector3 = main.hero.global_position - _start
			var right := _flat(main.camera_rig.camera.global_transform.basis.x)
			if moved.length() < 0.8 or _flat(moved).dot(right) < 0.85:
				_error = "D moved Vessa %s, expected along the camera right %s" % [moved, right]
				return
			_key_event(KEY_D, KEY_D, false)
			# A focused text field swallows W A S D.
			_line_edit = LineEdit.new()
			main.hud.add_child(_line_edit)
			_line_edit.grab_focus()
		64:
			_key_event(KEY_W, KEY_Z, true)
		70:
			if main.hero.get_move_input() != Vector3.ZERO:
				_error = "W walked Vessa while a text field had focus"
				return
			_key_event(KEY_W, KEY_Z, false)
			_line_edit.queue_free()
			_check_help_and_timer()
		72:
			_check_build_menu()
		74:
			_place_hall()
		76:
			_place_invalid()
		78:
			_shift_place()
		80:
			_cancel_site()
			_spawn_hall()
		82:
			_train_at_barracks()
		84:
			_kill_vessa()
		88:
			_check_dead_column()
		90:
			_check_respawned()
		92:
			_check_crown()
		96:
			_end_match()
		_:
			if _end_frame > 0 and frame >= _end_frame:
				_check_end_screen()


func _check_help_and_timer() -> void:
	var help_ok := false
	for node in main.hud.find_children("*", "Label", true, false):
		var t: String = (node as Label).text
		if t.contains("W A S D: walk Vessa") and t.contains("B: build (workers)") \
				and t.contains("Z X C V B N M ,: train") and t.contains("Delete: cancel a site") \
				and t.contains("F10 x2: surrender"):   # "F10 x2" since the Tab / unit priority help line (2026-09-27)
			help_ok = true
	if not help_ok:
		_error = "help text does not show the wave 2 keys"
		return
	var bar: Node = main.hud.top_bar
	var clock := RegEx.create_from_string("^\\d+:\\d\\d$")
	if not bar.timer_label.visible or clock.search(bar.timer_label.text) == null:
		_error = "top bar timer '%s' (visible %s), level says '%s'" % [bar.timer_label.text,
				bar.timer_label.visible, main.match_time_text()]
		return
	var rect: Rect2 = bar.get_global_rect()
	# 400 wide at x 600; with essence (4.U1a, items.md) 500 wide at x 550.
	var w := 500.0 if bar.get("essence_bank") != null else 400.0
	if bar.get("gold_bank") != null:
		w += 124.0   # step 10 (ui-trade.md 3): gold item, 624 x 40 at (488, 8)
	# 2026-09-27: the pop number is 100 px wide ("200 / 200", pop cap 200), so the bar may be up to 24 px wider than
	# the spec widths; it must stay centred.
	if rect.size.x < w - 1.5 or rect.size.x > w + 24.0 or absf(rect.position.x - (800.0 - rect.size.x * 0.5)) > 1.5:
		_error = "top bar with the timer at %s, expected %d wide at x %d" % [rect, int(w), int(800.0 - w * 0.5)]


func _check_build_menu() -> void:
	sel.select_units(_workers)
	card.refresh()
	if _ids(5) != ["move", "stop", "hold", "gather", "build"] or card.key_labels[4].text != "B":
		_error = "worker card %s, expected move stop hold gather build (B)" % [_ids(5)]
		return
	_key(KEY_B, KEY_B)
	if not sel.build_menu_open:
		_error = "B did not open the build menu"
		return
	if _ids(5) != ["build_fire_hearth", "build_fire_barracks", "build_fire_tower", "back", ""]:
		_error = "build menu shows %s" % [_ids(5)]
		return
	var keys: Array = []
	for i in 4:
		keys.append(card.key_labels[i].text)
	if keys != ["Z", "X", "C", "Esc"]:
		_error = "build menu letters %s, expected Z X C Esc" % [keys]
		return
	var tip: String = card.buttons[1].tooltip_text
	if not tip.begins_with("Ember Hall  [X]\nCost 150 crystals · 45 s · 1300 HP\n"):
		_error = "Ember Hall tooltip '%s'" % tip
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	if sel.build_menu_open or _ids(5)[4] != "build":
		_error = "Esc did not close the build menu (%s)" % [_ids(5)]
		return
	_key(KEY_B, KEY_B)
	_click(Vector2(800, 450), MOUSE_BUTTON_RIGHT)
	if sel.build_menu_open:
		_error = "right click did not close the build menu"
		return
	# B then X (the Hall) starts the placement ghost.
	_key(KEY_B, KEY_B)
	_key(KEY_X, KEY_X)
	if sel.get_pending_order() != &"build" or sel.placing_type == null \
			or sel.placing_type.id != &"fire_barracks":
		_error = "B X did not start placing an Ember Hall (pending %s)" % sel.get_pending_order()
		return
	var spot: Vector3 = grid.find_spot(sel.placing_type, keep.global_position + Vector3(12, 0, -12), 0)
	if spot == Vector3.INF:
		_error = "no free spot for an Ember Hall"
		return
	main.camera_rig.focus_on(spot)
	_start = spot


func _place_hall() -> void:
	var spot := _start
	var screen := _screen(spot)
	_move_mouse(screen)
	_process_selection()
	if sel.ghost_center().distance_to(spot) > 0.01 or sel.ghost_reason() != "":
		_error = "ghost at %s ('%s'), expected a valid spot %s" % [sel.ghost_center(), sel.ghost_reason(), spot]
		return
	_crystals = eco.crystals
	var before: int = main.get_tree().get_nodes_in_group("buildings").size()
	_click(screen, MOUSE_BUTTON_LEFT)
	if eco.crystals != _crystals - 150:
		_error = "placing the Hall: crystals %d -> %d, expected -150" % [_crystals, eco.crystals]
		return
	for b in main.get_tree().get_nodes_in_group("buildings"):
		if b.team == 0 and not b.is_constructed() and b.global_position.distance_to(spot) < 0.01:
			_site = b
	if _site == null or main.get_tree().get_nodes_in_group("buildings").size() != before + 1:
		_error = "no Ember Hall site at %s after the click" % spot
		return
	for w in _workers:
		if w.build_site != _site:
			_error = "a selected worker was not sent to build the site"
			return
	if sel.get_pending_order() != &"" or sel.build_menu_open or sel.placing_type != null:
		_error = "the placement did not end after the click"
		return
	card.refresh()
	if _ids(5)[4] != "build":
		_error = "the normal worker card did not come back after placing (%s)" % [_ids(5)]


func _place_invalid() -> void:
	eco.crystals = 1000
	eco.changed.emit()
	_key(KEY_B, KEY_B)
	_key(KEY_X, KEY_X)
	var node: Node3D = main.crystal_nodes[&"node_fire_a"]
	main.camera_rig.focus_on(node.global_position)
	var screen := _screen(node.global_position)
	_move_mouse(screen)
	_process_selection()
	var reason: String = sel.ghost_reason()
	if reason == "":
		_error = "the ghost on a crystal node is valid"
		return
	var label_ok := false
	for l in sel.find_children("*", "Label", true, false):
		if (l as Label).visible and (l as Label).text == reason:
			label_ok = true
	if not label_ok:
		_error = "the refusal '%s' is not shown above the ghost" % reason
		return
	var before: int = main.get_tree().get_nodes_in_group("buildings").size()
	_click(screen, MOUSE_BUTTON_LEFT)
	if main.get_tree().get_nodes_in_group("buildings").size() != before or eco.crystals != 1000:
		_error = "an Ember Hall was placed on a crystal node"
		return
	if not _hud_shows(reason):
		_error = "the refusal '%s' was not shown as a message" % reason
		return
	if sel.get_pending_order() != &"build":
		_error = "an invalid click ended the placement"
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	if sel.get_pending_order() != &"" or sel.placing_type != null:
		_error = "Esc did not cancel the placement"


func _shift_place() -> void:
	# Hearth (Z) with Shift: the ghost stays up after the site is placed.
	_key(KEY_B, KEY_B)
	_key(KEY_Z, KEY_W)
	if sel.placing_type == null or sel.placing_type.id != &"fire_hearth":
		_error = "B Z did not start placing a Hearth"
		return
	var spot: Vector3 = grid.find_spot(sel.placing_type, keep.global_position + Vector3(0, 0, -14), 0)
	main.camera_rig.focus_on(spot)
	var screen := _screen(spot)
	_move_mouse(screen)
	var before: int = eco.crystals
	_click(screen, MOUSE_BUTTON_LEFT, true)
	if eco.crystals != before - 80:
		_error = "Shift+click did not place a Hearth (crystals %d -> %d)" % [before, eco.crystals]
		return
	if sel.get_pending_order() != &"build":
		_error = "Shift+click ended the placement"
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)


func _cancel_site() -> void:
	main.camera_rig.focus_on(_site.global_position)
	_click(_screen(_site.global_position + Vector3.UP * 0.4), MOUSE_BUTTON_LEFT)
	if sel.selected_building != _site:
		_error = "left click on the site did not select it (selected %s)" % sel.selected_building
		return
	card.refresh()
	if _ids(2) != ["cancel", ""] or card.key_labels[0].text != "Del":
		_error = "site card %s, expected Cancel (Del)" % [_ids(2)]
		return
	panel.refresh()
	if panel.current_view() != "keep" or not panel.site_row.visible \
			or not panel.building_info.text.begins_with("Under construction"):
		_error = "site panel: view %s, site row %s, info '%s'" % [panel.current_view(),
				panel.site_row.visible, panel.building_info.text]
		return
	_crystals = eco.crystals
	_key(KEY_DELETE, KEY_DELETE)
	if not _site.cancelled or eco.crystals != _crystals + 112:
		_error = "Delete: cancelled %s, crystals %d -> %d (expected +112)" % [_site.cancelled, _crystals, eco.crystals]
		return


## A finished Ember Hall (its collider is in the physics space from the next frame on).
func _spawn_hall() -> void:
	var type: Resource = load("res://data/buildings/fire_barracks.tres")
	var spot: Vector3 = grid.find_spot(type, keep.global_position + Vector3(-2, 0, -14), 0)
	_hall = grid.spawn_complete(type, spot, 0)


func _train_at_barracks() -> void:
	var spot: Vector3 = _hall.global_position
	main.camera_rig.focus_on(spot)
	_click(_screen(spot + Vector3.UP * 2.0), MOUSE_BUTTON_LEFT)
	if sel.selected_building != _hall:
		_error = "left click on the Ember Hall did not select it"
		return
	card.refresh()
	# Bowmen (docs/design/bowmen.md): each Hall adds its kingdom's bowman as slot 5 (B) when BowmanKit is on.
	var bow: Variant = BowmanKit.hall_bowman(_hall.building_type)
	var want_ids: Array = ["train_flame_guard", "train_ember_archer", "train_blaze_rider", "train_ash_hurler"]
	var want_keys: Array = ["Z", "X", "C", "V"]
	if bow != null:
		want_ids.append("train_%s" % str(bow.get("id")))
		want_keys.append("B")
	# New units 12 (docs/design/new-units-12.md): slots 6-8 (N M ,) when NewUnits12 is on in this game.
	var extra := NewUnits12.hall_units(_hall.building_type)
	for k in extra.size():
		want_ids.append("train_%s" % str(extra[k].id))
		want_keys.append("NM,"[k])
	want_ids.append("rally")
	want_keys.append("")
	if _ids(want_ids.size()) != want_ids:
		_error = "Ember Hall card %s, expected %s" % [_ids(want_ids.size()), want_ids]
		return
	var keys: Array = []
	for i in want_keys.size():
		keys.append(card.key_labels[i].text)
	if keys != want_keys:
		_error = "Ember Hall letters %s, expected %s (rally keyless)" % [keys, want_keys]
		return
	eco.crystals = 500
	eco.changed.emit()
	_key(KEY_Z, KEY_W)                   # AZERTY prints W on the physical Z key
	if _hall.queue.size() != 1 or _hall.queue[0].id != &"flame_guard" or eco.crystals != 410:
		_error = "Z did not queue a Flame Guard (queue %d, crystals %d)" % [_hall.queue.size(), eco.crystals]
		return
	panel.refresh()
	var slot1: Button = panel.queue_buttons[0]
	if panel.keep_name.text != "Ember Hall" or (slot1.icon == null and slot1.text != "Flame Guard") \
			or not panel.rally_label.visible:
		_error = "Ember Hall panel: name '%s', slot 1 '%s'" % [panel.keep_name.text, panel.queue_buttons[0].text]


func _kill_vessa() -> void:
	sel.select_units([])
	main.hero.take_damage(1.0e6)


func _check_dead_column() -> void:
	if not panel.hero_name.disabled or not panel.hero_status.visible \
			or not panel.hero_status.text.begins_with("Vessa returns in "):
		_error = "dead Vessa: name disabled %s, status '%s'" % [panel.hero_name.disabled, panel.hero_status.text]
		return
	var left: int = ceili(main.respawn_time_left(0))
	if panel.hero_status.text != "Vessa returns in %d s" % left:
		_error = "countdown '%s', expected %d s" % [panel.hero_status.text, left]
		return
	main.camera_rig.focus_on(Vector3.ZERO)
	_key(KEY_F1, KEY_F1)
	var cam: Vector3 = main.camera_rig.position
	if Vector2(cam.x - keep.global_position.x, cam.z - keep.global_position.z).length() > 0.5:
		_error = "F1 while Vessa is dead did not centre on the keep (camera %s)" % cam
		return
	if not sel.selected.is_empty():
		_error = "F1 selected something while Vessa is dead"
		return
	main.hero.respawn(main.respawn_point(0))


func _check_respawned() -> void:
	if panel.hero_name.disabled or panel.hero_name.modulate != Color.WHITE or panel.hero_status.visible:
		_error = "the hero column stays greyed after the respawn"
		return
	if not panel.hero_hp_text.text.begins_with("HP  350"):
		_error = "hero HP after the respawn '%s'" % panel.hero_hp_text.text
		return
	var crown: Node3D = main.crown
	crown.set(&"seal_time", 0.0)   # balance-1: sealed until 6:00 (tested in test_6_b2)
	main.hero.global_position = crown.global_position   # she picks the crown up


func _check_crown() -> void:
	if main.crown.wearer != main.hero:
		_error = "Vessa did not pick up the crown"
		return
	if not panel.hero_crown.visible or not panel.hero_crown.text.begins_with("Ember Crown"):
		_error = "the hero column does not show the crown"
		return
	main.hero.global_position = main.respawn_point(0)


func _end_match() -> void:
	for b in main.get_tree().get_nodes_in_group("buildings"):
		if b.team == 1:
			b.take_damage(1.0e7, null)
	_end_frame = frame + 45


func _check_end_screen() -> void:
	var hud: Node = main.hud
	if not hud.is_banner_shown():
		_error = "no end banner when the Shadow side lost"
		return
	var banner_ok := false
	for l in hud.end_panel.find_children("*", "Label", true, false):
		if (l as Label).text == "VICTORY":
			banner_ok = true
	var body: String = hud.end_body.text
	if not banner_ok or not body.begins_with("Match time ") or not body.contains("Units trained ") \
			or not body.contains("Crystals gathered ") or not body.ends_with("F9: play again"):
		_error = "end screen banner %s, body '%s'" % [banner_ok, body]
		return
	_done = true


# ---------------------------------------------------------------- helpers

func _ids(n: int) -> Array:
	var out := []
	var ids: Array = card.slot_ids()
	for i in n:
		out.append(str(ids[i]))
	return out


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z).normalized()


func _screen(world: Vector3) -> Vector2:
	return main.camera_rig.camera.unproject_position(world)


## The ghost follows the last mouse position now (instead of next frame).
func _process_selection() -> void:
	sel.refresh_ghost()


func _hud_shows(text: String) -> bool:
	for node in main.hud.find_children("*", "Label", true, false):
		if (node as Label).text.contains(text):
			return true
	return false


func _key_event(physical: Key, printed: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.pressed = pressed
	root.push_input(ev)


func _key(physical: Key, printed: Key) -> void:
	_key_event(physical, printed, true)
	_key_event(physical, printed, false)


func _move_mouse(pos: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	root.push_input(move)


func _click(pos: Vector2, button: MouseButton, shift := false) -> void:
	_move_mouse(pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.shift_pressed = shift
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)
