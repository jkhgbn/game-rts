extends SceneTree
## Task UX.1: the Controls setting (GameSettings.control_scheme) on the mission 1 map, through real input events
## (Viewport.push_input, physical keycodes with AZERTY keycodes where they differ).
## - Settings: Classic is the default; both schemes save / load in user://settings.cfg (backed up and restored);
##   the Settings panel's Controls list switches the scheme and its hint follows.
## - Classic: physical A = attack-move targeting (X too), Esc cancels; A + left click on the ground = attack-move,
##   on an enemy = attack it, on an own unit = attack-move to it, on the minimap = attack-move there (camera unchanged);
##   W / A do not walk the wizard; right click moves her; help and command card show A.
## - Hero WASD: A starts nothing (walk left), X = attack-move, W walks the wizard; switching to Classic while W is held
##   stops her; help and command card show X and "W A S D: walk Vessa".
## - RTS camera (WASD) (third entry, saved "rts_wasd"): A starts nothing, X = attack-move, help / card show X and
##   "W A S D / edge: pan"; held D pans the camera right (not the wizard), Shift+D faster; in Classic D does nothing.
## - Labels: with an AZERTY layout simulated (KeyLabels.overrides) the help reads "Q + click", "F / A / E",
##   "Z Q S D: walk"; the card shows Q for attack-move and A for spell 2.
## Run: godot --headless --path . -s tests/test_ux_1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ux.1"
const TIMEOUT_FRAMES := 1200
const SETTINGS_PATH := "user://settings.cfg"

var main: Node
var sel: Node
var card: Node
var frame := 0
var _wait := 0
var _error := ""
var _had_settings := false
var _settings_backup := PackedByteArray()
var _soldiers: Array = []
var _archer: Node3D
var _enemy: Node3D
var _hero_start := Vector3.ZERO
var _move_goal := Vector3.ZERO
var _move_start_dist := 0.0
var _cam_before := Vector3.ZERO


func _initialize() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		_had_settings = true
		_settings_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	root.size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			return _finish("navigation never finished baking")
		return false
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at frame %d" % frame)
	_step(frame)
	if _error != "":
		return _finish(_error)
	if frame == 200:
		return _finish("")
	return false


func _step(t: int) -> void:
	match t:
		1:
			sel = main.selection
			card = main.hud.command_card
			main.camera_rig.edge_pan_enabled = false   # headless mouse at (0, 0) would pan
			for u in get_nodes_in_group("units"):
				if u.team == 0 and not u.is_in_group("heroes") and not u.has_method("command_gather"):
					if str(u.unit_type.id) == "flame_guard":
						_soldiers.append(u)
					elif _archer == null and str(u.unit_type.id) == "ember_archer":
						_archer = u
			if _soldiers.size() < 3 or _archer == null:
				_error = "need 3 Flame Guards and an archer (found %d)" % _soldiers.size()
				return
			_check_settings()
		2:
			# The panel's GameSettings.apply() reset the headless window and turned edge-pan back on.
			root.size = Vector2i(1600, 900)
			main.camera_rig.edge_pan_enabled = false
		3:
			if root.get_visible_rect().size != Vector2(1600, 900):
				_error = "viewport is %s" % root.get_visible_rect().size
				return
			GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
			_check_classic_keys()
		4:
			# Enemy 14 m from the soldiers (out of their 8 m aggro), not moving by itself.
			_enemy = main.make_unit("shade")
			_enemy.team = 1
			main.add_child(_enemy)
			_enemy.global_position = _center() + Vector3(10.0, 0.0, -10.0)
			_enemy.aggro_range = 0.0
			_enemy.command_stop()
			for u in _soldiers:
				u.command_stop()
			main.camera_rig.focus_on(_center() + Vector3(5.0, 0.0, -5.0))
		8:
			# A + left click on the enemy = attack it.
			sel.select_units(_soldiers)
			_key(KEY_A, KEY_Q)
			_click(_screen(_enemy.global_position + Vector3.UP * 0.8), MOUSE_BUTTON_LEFT)
			if sel.get_pending_order() != &"":
				_error = "A + click on an enemy left the order pending"
				return
			for u in _soldiers:
				if u.attack_target != _enemy:
					_error = "A + click on an enemy: a soldier's target is %s" % u.attack_target
					return
			_enemy.queue_free()
			for u in _soldiers:
				u.command_stop()
		10:
			# A + left click on an own unit (an archer) = attack-move to where it stands, no attack.
			main.camera_rig.focus_on(_archer.global_position)
		12:
			sel.select_units(_soldiers)
			_key(KEY_A, KEY_Q)
			_click(_screen(_archer.global_position + Vector3.UP * 0.8), MOUSE_BUTTON_LEFT)
			for u in _soldiers:
				var goal: Vector3 = u.get("_attack_move_target")
				if not u.is_attack_moving() or u.attack_target != null:
					_error = "A + click on an own unit: soldier attack-moving %s, target %s" % [u.is_attack_moving(),
							u.attack_target]
					return
				if _flat(goal, _archer.global_position) > 4.5:
					_error = "A + click on an own unit: goal %s is %.1f m from the archer" % [goal,
							_flat(goal, _archer.global_position)]
					return
			for u in _soldiers:
				u.command_stop()
		14:
			_check_minimap()
		16:
			# Classic: W and A never walk the wizard.
			for u in _soldiers:
				u.command_stop()
			main.hero.command_stop()
			sel.select_units([main.hero])
			_key_state(KEY_W, KEY_Z, true)
			_key_state(KEY_A, KEY_Q, true)
		30:
			if main.hero.get_move_input() != Vector3.ZERO or sel.wizard_control.is_walking():
				_error = "Classic: W / A walked the wizard (input %s)" % main.hero.get_move_input()
				return
			if sel.get_pending_order() != &"":
				sel.cancel_targeting()   # A with only the wizard selected started attack-move: fine
			_key_state(KEY_W, KEY_Z, false)
			_key_state(KEY_A, KEY_Q, false)
			# Classic: right click on the ground moves her.
			main.camera_rig.focus_on(main.hero.global_position)
		32:
			sel.select_units([main.hero])
			_move_goal = main.hero.global_position + Vector3(5.0, 0.0, -4.0)
			_move_start_dist = _flat(main.hero.global_position, _move_goal)
			_click(_screen(_move_goal), MOUSE_BUTTON_RIGHT)
		100:
			var now := _flat(main.hero.global_position, _move_goal)
			if _move_start_dist - now < 2.0:
				_error = "Classic: right click did not move the wizard (%.1f -> %.1f)" % [_move_start_dist, now]
				return
			main.hero.command_stop()
		102:
			GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
			_check_hero_wasd_keys()
			_hero_start = main.hero.global_position
			_key_state(KEY_W, KEY_Z, true)
		130:
			if main.hero.get_move_input() == Vector3.ZERO or _flat(main.hero.global_position, _hero_start) < 0.5:
				_error = "Hero WASD: W did not walk the wizard (input %s, moved %.2f m)" % [main.hero.get_move_input(),
						_flat(main.hero.global_position, _hero_start)]
				return
			# Switching to Classic while W is held stops her.
			GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
		133:
			if main.hero.get_move_input() != Vector3.ZERO or sel.wizard_control.is_walking():
				_error = "switching to Classic with W held did not release the wizard"
				return
			_key_state(KEY_W, KEY_Z, false)
			main.hero.command_stop()
			_check_labels()
		140:
			# RTS camera (WASD): X = attack-move, A starts nothing, W A S D pan the camera (not the wizard).
			GameSettings.set_control_scheme(GameSettings.CONTROLS_RTS_WASD, false)
			_check_rts_wasd_keys()
			main.camera_rig.focus_on(Vector3.ZERO)
			_cam_before = main.camera_rig.position
			_input_key(KEY_D, true)
		150:
			var d1: float = main.camera_rig.position.x - _cam_before.x
			if d1 < 0.5:
				_error = "RTS WASD: D did not pan the camera right (%.2f m)" % d1
				return
			if main.hero.get_move_input() != Vector3.ZERO or sel.wizard_control.is_walking():
				_error = "RTS WASD: D walked the wizard"
				return
			set_meta(&"d1", d1)
			_cam_before = main.camera_rig.position
			_input_key(KEY_SHIFT, true)
		160:
			var d2: float = main.camera_rig.position.x - _cam_before.x
			if d2 < float(get_meta(&"d1")) * 1.5:
				_error = "RTS WASD: Shift+D is not faster (%.2f vs %.2f m)" % [d2, float(get_meta(&"d1"))]
				return
			_input_key(KEY_SHIFT, false)
			# Classic: D does nothing to the camera.
			GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
			_cam_before = main.camera_rig.position
		170:
			if main.camera_rig.position.distance_to(_cam_before) > 0.01:
				_error = "Classic: D panned the camera"
				return
			_input_key(KEY_D, false)


# ---------------------------------------------------------------- checks

func _check_settings() -> void:
	GameSettings.reset_defaults()
	if GameSettings.control_scheme != GameSettings.CONTROLS_CLASSIC or GameSettings.hero_wasd():
		_error = "Classic is not the default scheme"
		return
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD)
	GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC
	GameSettings.load_settings()
	if not GameSettings.hero_wasd():
		_error = "Hero WASD was not saved / loaded"
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	if str(cfg.get_value("settings", "control_scheme", "")) != "hero_wasd":
		_error = "settings.cfg control_scheme is '%s'" % cfg.get_value("settings", "control_scheme", "")
		return
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC)
	GameSettings.load_settings()
	if GameSettings.control_scheme != GameSettings.CONTROLS_CLASSIC:
		_error = "Classic was not saved / loaded"
		return
	if GameSettings.control_scheme_from_id("nonsense") != GameSettings.CONTROLS_CLASSIC:
		_error = "an unknown saved scheme is not Classic"
		return
	if GameSettings.attack_move_keys() != [KEY_A, KEY_X] or GameSettings.attack_move_key() != KEY_A:
		_error = "Classic attack-move keys are %s" % [GameSettings.attack_move_keys()]
		return
	# The Settings panel (main menu and pause menu share it): Controls list + hint.
	var panel := SettingsPanel.new()
	root.add_child(panel)
	if panel.controls_option == null or panel.controls_option.item_count != 3 or panel.controls_option.selected != 0:
		_error = "Settings panel Controls list missing or not on Classic"
		return
	if not panel.controls_hint.text.contains("Right click moves your wizard") \
			or not panel.controls_hint.text.contains("A + click: attack-move"):
		_error = "Classic hint is '%s'" % panel.controls_hint.text
		return
	panel.controls_option.select(1)
	panel.controls_option.item_selected.emit(1)
	if not GameSettings.hero_wasd() or not panel.controls_hint.text.contains("W A S D: walk your wizard"):
		_error = "choosing Hero WASD in the panel: scheme %d, hint '%s'" % [GameSettings.control_scheme,
				panel.controls_hint.text]
		return
	panel.close()   # saves
	GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC
	GameSettings.load_settings()
	if not GameSettings.hero_wasd():
		_error = "the panel's Back did not save Hero WASD"
		return
	if GameSettings.attack_move_keys() != [KEY_X] or GameSettings.attack_move_key() != KEY_X:
		_error = "Hero WASD attack-move keys are %s" % [GameSettings.attack_move_keys()]
		return
	panel.open()
	if panel.controls_option.selected != 1:
		_error = "the panel did not show Hero WASD on open"
		return
	# RTS camera (WASD): the third entry; saved as "rts_wasd"; X only for attack-move.
	panel.controls_option.select(2)
	panel.controls_option.item_selected.emit(2)
	if not GameSettings.rts_wasd() or not panel.controls_hint.text.contains("X + click: attack-move") \
			or not panel.controls_hint.text.contains("W A S D / arrows: camera"):
		_error = "choosing RTS camera (WASD) in the panel: scheme %d, hint '%s'" % [GameSettings.control_scheme,
				panel.controls_hint.text]
		return
	panel.close()
	GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC
	GameSettings.load_settings()
	var cfg2 := ConfigFile.new()
	cfg2.load(SETTINGS_PATH)
	if not GameSettings.rts_wasd() or str(cfg2.get_value("settings", "control_scheme", "")) != "rts_wasd":
		_error = "RTS camera (WASD) was not saved / loaded"
		return
	if GameSettings.attack_move_keys() != [KEY_X] or GameSettings.attack_move_key() != KEY_X or GameSettings.hero_wasd():
		_error = "RTS WASD attack-move keys are %s" % [GameSettings.attack_move_keys()]
		return
	panel.open()
	if panel.controls_option.selected != 2:
		_error = "the panel did not show RTS camera (WASD) on open"
		return
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC)
	panel.queue_free()


func _check_classic_keys() -> void:
	sel.select_units(_soldiers)
	_key(KEY_A, KEY_Q)   # physical A (AZERTY prints Q there)
	if sel.get_pending_order() != &"attack_move":
		_error = "Classic: A did not start attack-move targeting ('%s')" % sel.get_pending_order()
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	if sel.get_pending_order() != &"":
		_error = "Classic: Esc did not cancel attack-move"
		return
	_key(KEY_X, KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "Classic: X (alias) did not start attack-move targeting"
		return
	sel.cancel_targeting()
	# A + left click on the ground = attack-move there.
	var goal: Vector3 = _center() + Vector3(4.0, 0.0, -6.0)
	main.camera_rig.focus_on(goal)
	_key(KEY_A, KEY_Q)
	_click(_screen(goal), MOUSE_BUTTON_LEFT)
	if sel.get_pending_order() != &"" or not _soldiers[0].is_attack_moving():
		_error = "Classic: A + ground click did not attack-move (pending '%s', at %s, hovered %s)" % [
				sel.get_pending_order(), _screen(goal), root.gui_get_hovered_control()] \
				+ " cam %s rig %s goal %s vp %s" % [main.camera_rig.camera.global_position, main.camera_rig.position, goal,
				root.get_visible_rect().size]
		return
	# Help and command card (the HUD rewrites its help the frame after a scheme change; call it now).
	main.hud.refresh_help()
	var help: String = main.hud.get(&"_help_label").text
	if not help.contains("Attack-move: A + click (X too)") or not help.contains("Right click: move (Vessa too)") \
			or help.contains("walk Vessa") or help.split("\n").size() != 12:   # step 12 (ui-mapfill.md 12): 12 lines
		_error = "Classic help text:\n%s" % help
		return
	if help != GameHUD.help_text("Vessa"):
		_error = "the HUD help is not GameHUD.help_text in Classic"
		return
	card.refresh()
	var s: Dictionary = card.slots[3]
	if str(s.get("key", "")) != "A" or not str(s.get("tooltip", "")).begins_with("Attack-move  [A]\n") \
			or not str(s.get("tooltip", "")).contains("X works too"):
		_error = "Classic card attack-move slot: key '%s', tooltip '%s'" % [s.get("key", ""), s.get("tooltip", "")]
		return
	if not GameHUD.walk_hint("Vessa").begins_with("Right-click"):
		_error = "Classic walk hint is '%s'" % GameHUD.walk_hint("Vessa")


func _check_minimap() -> void:
	var minimap: Control = main.hud.minimap
	var rect: Rect2 = minimap.get_global_rect()
	sel.select_units(_soldiers)
	_cam_before = main.camera_rig.position
	_key(KEY_A, KEY_Q)
	var point := Vector3(-20.0, 0.0, 20.0)
	_click(rect.position + minimap.world_to_map(point), MOUSE_BUTTON_LEFT)
	if sel.get_pending_order() != &"" or not _soldiers[0].is_attack_moving():
		_error = "Classic: A + minimap click did not attack-move (pending '%s')" % sel.get_pending_order()
		return
	var goal: Vector3 = _soldiers[0].get("_attack_move_target")
	if _flat(goal, point) > 4.5:
		_error = "A + minimap click: goal %s is not near %s" % [goal, point]
		return
	if main.camera_rig.position != _cam_before:
		_error = "A + minimap click moved the camera"
		return
	# Right click on the minimap while targeting cancels.
	_key(KEY_A, KEY_Q)
	_click(rect.position + minimap.world_to_map(point), MOUSE_BUTTON_RIGHT)
	if sel.get_pending_order() != &"":
		_error = "right click on the minimap did not cancel A targeting"


func _check_hero_wasd_keys() -> void:
	sel.select_units(_soldiers)
	_key(KEY_A, KEY_Q)
	if sel.get_pending_order() != &"":
		_error = "Hero WASD: A started '%s' (A is walk-left)" % sel.get_pending_order()
		return
	_key(KEY_X, KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "Hero WASD: X did not start attack-move targeting"
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	if sel.get_pending_order() != &"":
		_error = "Hero WASD: Esc did not cancel attack-move"
		return
	main.hud.refresh_help()
	var help: String = main.hud.get(&"_help_label").text
	if not help.contains("W A S D: walk Vessa") or not help.contains("X: attack-move") \
			or not help.contains("B: build (workers)") or help.split("\n").size() != 12:
		_error = "Hero WASD help text:\n%s" % help
		return
	card.refresh()
	var s: Dictionary = card.slots[3]
	if str(s.get("key", "")) != "X" or not str(s.get("tooltip", "")).begins_with("Attack-move  [X]\n") \
			or str(s.get("tooltip", "")).contains("works too"):
		_error = "Hero WASD card attack-move slot: key '%s', tooltip '%s'" % [s.get("key", ""), s.get("tooltip", "")]
		return
	if GameHUD.walk_hint("Vessa") != "Walk Vessa with W A S D":
		_error = "Hero WASD walk hint is '%s'" % GameHUD.walk_hint("Vessa")
		return
	sel.select_units([main.hero])


func _check_rts_wasd_keys() -> void:
	sel.select_units(_soldiers)
	_key(KEY_A, KEY_Q)
	if sel.get_pending_order() != &"":
		_error = "RTS WASD: A started '%s' (A is pan left)" % sel.get_pending_order()
		return
	_key(KEY_X, KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "RTS WASD: X did not start attack-move targeting"
		return
	_key(KEY_ESCAPE, KEY_ESCAPE)
	main.hud.refresh_help()
	var help: String = main.hud.get(&"_help_label").text
	if not help.contains("Attack-move: X + click") or help.contains("(X too)") or help.contains("walk Vessa") \
			or not help.contains("Right click: move (Vessa too)") or not help.contains("W A S D / edge: pan") \
			or help.split("\n").size() != 12:
		_error = "RTS WASD help text:\n%s" % help
		return
	card.refresh()
	var s: Dictionary = card.slots[3]
	if str(s.get("key", "")) != "X" or str(s.get("tooltip", "")).contains("works too"):
		_error = "RTS WASD card attack-move slot: key '%s', tooltip '%s'" % [s.get("key", ""), s.get("tooltip", "")]
		return
	if not GameHUD.walk_hint("Vessa").begins_with("Right-click"):
		_error = "RTS WASD walk hint is '%s'" % GameHUD.walk_hint("Vessa")
		return
	# AZERTY labels: "Z Q S D / edge: pan".
	KeyLabels.overrides = {KEY_A: "Q", KEY_Q: "A", KEY_W: "Z", KEY_Z: "W"}
	help = GameHUD.help_text("Vessa")
	var hint := SettingsPanel.controls_hint_text(GameSettings.CONTROLS_RTS_WASD)
	KeyLabels.overrides = {}
	if not help.contains("Z Q S D / edge: pan") or not hint.contains("Z Q S D / arrows: camera"):
		_error = "AZERTY RTS WASD help / hint:\n%s\n%s" % [help, hint]
		return
	sel.select_units([main.hero])


## Key state through Input (RTSCamera reads Input.is_physical_key_pressed).
func _input_key(physical: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = physical
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _check_labels() -> void:
	if KeyLabels.of(KEY_A) != "A" or KeyLabels.letter("Q") != "Q" or KeyLabels.letter("Del") != "Del":
		_error = "headless labels: A -> '%s', Q -> '%s'" % [KeyLabels.of(KEY_A), KeyLabels.letter("Q")]
		return
	# AZERTY: physical A prints Q, Q prints A, W prints Z, Z prints W.
	KeyLabels.overrides = {KEY_A: "Q", KEY_Q: "A", KEY_W: "Z", KEY_Z: "W"}
	GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC
	var help := GameHUD.help_text("Vessa")
	if not help.contains("Attack-move: Q + click (X too)") or not help.contains("F / A / E: spells") \
			or not help.contains("W X C V B: train") or not help.contains("Ctrl+F/A/E") \
			or not help.contains("Flag: W raise"):
		_error = "AZERTY Classic help:\n%s" % help
		return
	main.hud.refresh_help()
	if main.hud.get(&"_help_label").text != help:
		_error = "the HUD help did not follow the keyboard labels"
		return
	sel.select_units(_soldiers)
	card.refresh()
	var s: Dictionary = card.slots[3]
	if str(s.get("key", "")) != "Q" or not str(s.get("tooltip", "")).begins_with("Attack-move  [Q]\n"):
		_error = "AZERTY card attack-move slot: key '%s', tooltip '%s'" % [s.get("key", ""), s.get("tooltip", "")]
		return
	sel.select_units([main.hero])
	card.refresh()
	var spell2: Dictionary = card.slots[5]
	if str(spell2.get("key", "")) != "A" or str(spell2.get("tooltip", "")).contains("Ctrl+Q"):
		_error = "AZERTY card spell 2: key '%s', tooltip '%s'" % [spell2.get("key", ""), spell2.get("tooltip", "")]
		return
	if not SettingsPanel.controls_hint_text(GameSettings.CONTROLS_CLASSIC).contains("Q + click: attack-move"):
		_error = "AZERTY Classic settings hint: %s" % SettingsPanel.controls_hint_text(GameSettings.CONTROLS_CLASSIC)
		return
	GameSettings.control_scheme = GameSettings.CONTROLS_HERO_WASD
	help = GameHUD.help_text("Vessa")
	if not help.contains("Z Q S D: walk Vessa") or not help.contains("X: attack-move"):
		_error = "AZERTY Hero WASD help:\n%s" % help
		return
	if GameHUD.walk_hint("Vessa") != "Walk Vessa with Z Q S D":
		_error = "AZERTY walk hint is '%s'" % GameHUD.walk_hint("Vessa")
		return
	KeyLabels.overrides = {}
	GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC


# ---------------------------------------------------------------- helpers

func _center() -> Vector3:
	var c := Vector3.ZERO
	for u in _soldiers:
		c += u.global_position
	c /= maxf(1.0, _soldiers.size())
	return Vector3(c.x, 0.0, c.z)


func _screen(world: Vector3) -> Vector2:
	return main.camera_rig.camera.unproject_position(world)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _move(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev)


func _button(pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = pressed
	root.push_input(ev)


func _click(pos: Vector2, button: MouseButton) -> void:
	_move(pos)
	_button(pos, button, true)
	_button(pos, button, false)


func _key_state(physical: Key, keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = keycode
	ev.pressed = pressed
	root.push_input(ev)


func _key(physical: Key, keycode: Key) -> void:
	_key_state(physical, keycode, true)
	_key_state(physical, keycode, false)


func _finish(reason: String) -> bool:
	KeyLabels.overrides = {}
	if _had_settings:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_settings_backup)
			f.close()
	elif FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
