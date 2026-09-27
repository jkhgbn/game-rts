extends SceneTree
## Task 5.U1: main menu loads, Start launches the skirmish with HARD set on the bot, Esc toggles
## the pause (not while an order is pending), Restart keeps the difficulty, settings save / load.
## Run: godot --headless --path . -s tests/test_5_u1.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "5.u1"
const TIMEOUT_FRAMES := 3600
const SETTINGS_PATH := "user://settings.cfg"

var menu: Node
var level: Node
var pause: Node
var frame := 0
var step := 0
var _wait := 0
var _backup: PackedByteArray = PackedByteArray()
var _had_backup := false


func _initialize() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		_had_backup = true
		_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	match step:
		0:
			if frame < 3:
				return false
			# 7.U1: Campaign is active now (mission list panel).
			if menu.skirmish_button == null or menu.campaign_button.disabled:
				return _finish("main menu buttons missing or Campaign disabled")
			menu.skirmish_button.pressed.emit()
			if not menu.skirmish_panel.visible:
				return _finish("skirmish setup panel did not open")
			menu.difficulty_buttons[2].pressed.emit()   # Hard
			if menu.get_difficulty() != 2:
				return _finish("Hard not selected")
			# 8.U1: the 4 kingdoms are playable on each side.
			if menu.kingdom_buttons.size() != 4 or menu.kingdom_buttons[2].disabled or menu.kingdom_buttons[3].disabled:
				return _finish("the 4 player kingdom cards should be enabled")
			menu.set_player_kingdom(&"fire")
			menu.set_enemy(&"shadow")
			menu.start_button.pressed.emit()
			level = current_scene
			if level == null or level.name != "Skirmish":
				return _finish("Start did not launch the skirmish")
			if int(level.get_node("ShadowBot").difficulty) != 2:
				return _finish("bot difficulty is not HARD")
			step = 1
		1:
			if level.get("hero") == null:
				_wait += 1
				return _wait > 3000 and _finish("skirmish never spawned the hero")
			var bot: Node = level.get_node("ShadowBot")
			if bot.ai == null or bot.ai.id != &"hard":
				return _finish("bot profile is not hard (%s)" % str(bot.ai.id if bot.ai else null))
			if is_instance_valid(menu):
				return _finish("main menu was not freed")
			pause = load("res://scenes/ui/pause_menu.tscn").instantiate()
			level.add_child(pause)
			step = 2
		2:
			# Esc with a pending order cancels it, never pauses.
			var sel: Node = level.get("selection")
			sel.select_units([level.hero])
			sel.begin_order(&"move")
			if sel.get_pending_order() != &"":
				_press_esc()
				if paused:
					return _finish("Esc paused while an order was pending")
				if sel.get_pending_order() != &"":
					return _finish("Esc did not cancel the pending order")
			_press_esc()
			if not paused or not pause.is_open():
				return _finish("Esc did not pause")
			_press_esc()
			if paused or pause.is_open():
				return _finish("second Esc did not resume")
			_press_esc()
			if not paused:
				return _finish("Esc did not pause again")
			pause.restart()
			step = 3
			_wait = 0
		3:
			_wait += 1
			if _wait < 5:
				return false
			var lv: Node = current_scene
			if lv == null or lv == level or not is_instance_valid(lv):
				return _wait > 600 and _finish("restart did not reload the level")
			if paused:
				return _finish("still paused after restart")
			if int(lv.get_node("ShadowBot").difficulty) != 2:
				return _finish("restart lost the HARD difficulty")
			step = 4
		4:
			GameSettings.master_volume = 0.4
			GameSettings.music_volume = 0.25
			GameSettings.sfx_volume = 0.6
			GameSettings.edge_pan = false
			GameSettings.ui_scale = 1.25
			GameSettings.fullscreen = false
			if GameSettings.save_settings() != OK:
				return _finish("settings save failed")
			GameSettings.reset_defaults()
			GameSettings.load_settings()
			if not is_equal_approx(GameSettings.master_volume, 0.4) or not is_equal_approx(GameSettings.music_volume, 0.25) \
					or not is_equal_approx(GameSettings.sfx_volume, 0.6) or GameSettings.edge_pan != false \
					or not is_equal_approx(GameSettings.ui_scale, 1.25):
				return _finish("settings did not load back")
			GameSettings.apply(self)
			if AudioServer.get_bus_index(&"Music") == -1 or AudioServer.get_bus_index(&"SFX") == -1:
				return _finish("audio buses missing")
			if not is_equal_approx(root.content_scale_factor, 1.25):
				return _finish("UI scale not applied")
			var cam: Node = current_scene.get("camera_rig")
			if cam and cam.edge_pan_enabled:
				return _finish("edge pan not applied")
			GameSettings.reset_defaults()
			GameSettings.apply(self)
			return _finish("")
	return false


func _press_esc() -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ESCAPE
		ev.keycode = KEY_ESCAPE
		ev.pressed = pressed
		root.push_input(ev)


func _finish(reason: String) -> bool:
	paused = false
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_backup)
			f.close()
	elif FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
