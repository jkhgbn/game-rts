extends SceneTree
## Task 6.U3: minimap fog, ghosts, hidden enemies (fog-of-war.md, ui-style.md 7.1). Skirmish, bot off.
## Run:  godot --headless --path . -s tests/test_6_u3.gd --fixed-fps 60 --quit-after 3000
## Add  shot=<file.png>  after  --  (and run without --headless) to save a screenshot of the HUD.
## Checks: the minimap fog texture (visible start, black enemy start, NEAREST, rebuilt on `updated`);
## a hidden Shade is not drawn, not clickable, and a right-click on it moves instead of attacking;
## a seen-then-fogged hovel is drawn as a ghost; placement refuses "Unexplored"; F11 updates the minimap.

const TASK_ID := "6.U3"
const TIMEOUT_FRAMES := 2400
const SCENE := "res://scenes/skirmish.tscn"
const SHADE_POS := Vector3(-6.0, 0.0, 16.0)
const HOVEL_POS := Vector3(-24.0, 0.0, -6.0)

var main: Node
var mm: Node
var sel: Node
var frame := 0
var _wait := 0
var _phase := 0
var _phase_frame := 0
var _errors: Array[String] = []
var _shade: Node3D
var _guard: Node3D
var _worker: Node3D
var _hovel: Node3D
var _messages: Array[String] = []
var _shot := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shot="):
			_shot = arg.substr(5)
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	var done := _step()
	if done or frame > TIMEOUT_FRAMES:
		if not done:
			_errors.append("timed out in phase %d" % _phase)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _next(phase: int) -> void:
	_phase = phase
	_phase_frame = frame


func _step() -> bool:
	var t := frame - _phase_frame
	match _phase:
		0:
			if t < 30:
				return false
			mm = main.hud.minimap
			sel = main.selection
			sel.message.connect(func(m: String) -> void: _messages.append(m))
			_expect(int(mm.fog_texture_updates) > 0, "minimap fog texture never built")
			_expect(is_equal_approx(float(mm.fog_alpha_at(main.PLAYER_START)), 0.0), "start not clear on the minimap")
			_expect(float(mm.fog_alpha_at(main.SHADOW_START)) > 0.99, "enemy start not black on the minimap")
			_expect(int(mm.texture_filter) == CanvasItem.TEXTURE_FILTER_NEAREST, "fog texture not NEAREST")
			_expect(int(mm.drawn_enemy_icons) == 0, "enemy icons drawn through the fog (%d)" % int(mm.drawn_enemy_icons))
			_shade = main.make_unit("shade")
			_add(_shade, 1, SHADE_POS)
			_guard = main.make_unit("flame_guard")
			_add(_guard, 0, main.PLAYER_START + Vector3(3.0, 0.0, -3.0))
			_next(1)
		1:
			if t < 20:
				return false
			_expect(not _shade.visible, "Shade should be hidden")
			var before := int(mm.fog_texture_updates)
			main.fog.update_team(0)   # emits updated: same data, no rebuild
			_expect(int(mm.fog_texture_updates) == before, "fog texture rebuilt without a change")
			_expect(int(mm.drawn_enemy_icons) == 0, "hidden Shade drawn on the minimap")
			main.camera_rig.focus_on(SHADE_POS)
			_next(2)
		2:
			if t < 5:
				return false
			var cam: Camera3D = main.camera_rig.camera
			var screen := cam.unproject_position(_shade.global_position + Vector3.UP * 0.8)
			_expect(sel.unit_at(screen) != _shade, "hidden Shade is clickable")
			sel.select_units([_guard])
			_right_click(screen)
			_expect(_guard.get(&"attack_target") == null, "right-click on a hidden enemy ordered an attack")
			# Attack-move into the fog is still accepted.
			sel.begin_order(&"attack_move")
			_expect(sel.confirm_pending_at(SHADE_POS + Vector3(2.0, 0.0, 0.0)), "attack-move into the fog refused")
			_guard.call(&"command_stop")
			# F11: fog off, the minimap clears at once and the Shade becomes a target.
			_press_f11()
			_next(3)
		3:
			if t < 3:
				return false
			_expect(not main.fog.enabled, "F11 did not turn the fog off")
			_expect(is_equal_approx(float(mm.fog_alpha_at(main.SHADOW_START)), 0.0), "fog off: minimap still black")
			var cam: Camera3D = main.camera_rig.camera
			var screen := cam.unproject_position(_shade.global_position + Vector3.UP * 0.8)
			_expect(sel.unit_at(screen) == _shade, "fog off: Shade not clickable")
			_expect(int(mm.drawn_enemy_icons) > 0, "fog off: no enemy icons on the minimap")
			_press_f11()
			_next(4)
		4:
			if t < 20:
				return false
			_expect(main.fog.enabled, "second F11 did not turn the fog on")
			_expect(float(mm.fog_alpha_at(main.SHADOW_START)) > 0.99, "fog back on: minimap not black")
			# A hovel seen once, then left in the fog, is a ghost on the minimap.
			_hovel = main.build_grid.spawn_complete(load("res://data/buildings/shadow_hovel.tres"), HOVEL_POS, 1)
			_guard.global_position = HOVEL_POS + Vector3(0.0, 0.0, 7.0)
			_guard.call(&"command_stop")
			_next(5)
		5:
			if t < 20:
				return false
			_expect(_hovel.visible, "hovel not seen")
			_guard.global_position = main.PLAYER_START + Vector3(4.0, 0.0, -4.0)
			_guard.call(&"command_stop")
			_next(6)
		6:
			if t < 20:
				return false
			_expect(not _hovel.visible, "hovel still visible")
			_expect(int(mm.drawn_ghosts) == 1, "expected 1 ghost on the minimap, got %d" % int(mm.drawn_ghosts))
			_expect(float(mm.fog_alpha_at(HOVEL_POS)) > 0.5 and float(mm.fog_alpha_at(HOVEL_POS)) < 0.6,
					"explored cell not dimmed 0.55 on the minimap")
			_check_placement()
			if _shot == "" or DisplayServer.get_name() == "headless":
				return true
			main.camera_rig.focus_on(main.PLAYER_START + Vector3(10.0, 0.0, -10.0))
			_next(7)
		7:
			if t < 10:
				return false
			var img := root.get_texture().get_image()
			img.save_png(_shot)
			print("screenshot: ", _shot)
			return true
	return false


## Placement: the ghost reads "Unexplored" and a click there is refused; explored ground is fine.
func _check_placement() -> void:
	_worker = main.make_unit("cinder_hand")
	_add(_worker, 0, main.PLAYER_START + Vector3(2.0, 0.0, 2.0))
	sel.select_units([_worker])
	var hearth: Resource = null
	for bt in load("res://scripts/buildings/building_type.gd").buildable_for(&"fire"):
		if String(bt.id).ends_with("hearth"):
			hearth = bt
	if hearth == null:
		_errors.append("no hearth type")
		return
	var grid: Node = main.build_grid
	var spot := Vector3.INF
	for p in [Vector3(10, 0, -10), Vector3(0, 0, -20), Vector3(20, 0, 0), Vector3(-10, 0, -30),
			Vector3(30, 0, 20), Vector3(14, 0, 30), Vector3(-30, 0, -10), Vector3(6, 0, 6)]:
		var c: Vector3 = grid.snap(p, hearth.footprint)
		if grid.check(hearth, c, 0) == "" and not sel.footprint_explored(hearth, c):
			spot = c
			break
	if spot == Vector3.INF:
		_errors.append("no free unexplored spot found for the placement check")
		return
	_expect(sel.footprint_explored(hearth, main.PLAYER_START), "start not explored for placement")
	sel.begin_placement(hearth)
	var cam: Camera3D = main.camera_rig.camera
	main.camera_rig.focus_on(spot)
	# The camera moves at once with focus_on; use a mouse motion so the ghost follows.
	var ev := InputEventMouseMotion.new()
	ev.position = cam.unproject_position(spot)
	root.push_input(ev)
	sel.refresh_ghost()
	_expect(sel.ghost_reason() == "Unexplored", "ghost reason is '%s', not Unexplored" % sel.ghost_reason())
	var crystals_before: int = main.economy.crystals
	_messages.clear()
	var site: Variant = sel.place_building_at(spot)
	_expect(site == null, "placement accepted on unexplored ground")
	_expect(_messages.has("Unexplored"), "no Unexplored message (%s)" % str(_messages))
	_expect(main.economy.crystals == crystals_before, "crystals spent on a refused placement")
	sel.cancel_targeting()


func _add(u: Node3D, team: int, pos: Vector3) -> void:
	u.set(&"team", team)
	main.add_child(u)
	u.global_position = pos
	u.call(&"command_stop")


func _right_click(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)


func _press_f11() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F11
	ev.keycode = KEY_F11
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)
