extends SceneTree
## Map picker start paths (fix 2026-10-04): with a clean settings file (GameSettings.use_test_file, the player's saved
## map never leaks in) the skirmish Start launches Crown Hollow on scenes/skirmish.tscn (node "Skirmish"); a player with
## Thornwater chosen gets a LayoutLevel playing Thornwater, F9 (the level's own key) reloads Thornwater, and
## MenuFlow.quit_to_menu returns to the main menu.
## Run: godot --headless --path . -s tests/test_map_start.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "map_start"
const SIM := preload("res://scripts/core/sim_mode.gd")
const BAKE_FRAMES := 9000

var menu: Node
var level: Node
var step := 0
var _wait := 0
var fails: Array[String] = []


func _initialize() -> void:
	GameSettings.use_test_file()
	SIM.enabled = true
	_open_menu()


func _open_menu() -> void:
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	_wait += 1
	match step:
		0:   # default map: Crown Hollow, the Skirmish scene
			if _wait < 3:
				return false
			menu.skirmish_button.pressed.emit()
			if menu.get_map() != MapCatalog.DEFAULT_ID:
				fails.append("a clean settings file opens the picker on %s, not Crown Hollow" % menu.get_map())
			menu.start_button.pressed.emit()
			level = current_scene
			if level == null or level.name != "Skirmish" or level is LayoutLevel:
				fails.append("default Start launched %s, not the Crown Hollow Skirmish" % (level.name if level else "nothing"))
				return _done()
			if MenuFlow.map_id != MapCatalog.DEFAULT_ID or MenuFlow.map_layout_path != "":
				fails.append("MenuFlow remembers %s / %s for Crown Hollow" % [MenuFlow.map_id, MenuFlow.map_layout_path])
			menu = null
			_next(1)
		1:   # back to the menu, choose Thornwater
			if not _started(level, "Crown Hollow"):
				return fails.size() > 0 and _done()
			MenuFlow.quit_to_menu(self)
			_next(2)
		2:
			var cur := current_scene
			if cur == null or cur == level or not is_instance_valid(cur) or not cur.has_method(&"start_skirmish"):
				if _wait > 600:
					fails.append("quit_to_menu did not open the main menu")
					return _done()
				return false
			menu = cur
			if _wait < 3:
				return false
			menu.skirmish_button.pressed.emit()
			menu.select_map(&"thornwater")
			if menu.get_map() != &"thornwater":
				fails.append("Thornwater is not selectable (ready?)")
				return _done()
			menu.start_button.pressed.emit()
			level = current_scene
			menu = null
			if not (level is LayoutLevel):
				fails.append("Thornwater Start launched %s, not a LayoutLevel" % (level.name if level else "nothing"))
				return _done()
			if GameSettings.map_id != &"thornwater":
				fails.append("Start did not keep the choice (GameSettings.map_id %s)" % GameSettings.map_id)
			_next(3)
		3:
			if not _started(level, "Thornwater"):
				return fails.size() > 0 and _done()
			if String((level as LayoutLevel).map_layout().id) != "thornwater" or (level as LayoutLevel).layout_error() != "":
				fails.append("the level plays %s (%s)" % [(level as LayoutLevel).map_layout().id, (level as LayoutLevel).layout_error()])
			var f9 := InputEventKey.new()   # F9 the way a player presses it
			f9.physical_keycode = KEY_F9
			f9.keycode = KEY_F9
			f9.pressed = true
			root.push_input(f9)
			_next(4)
		4:
			var cur := current_scene
			if cur == null or cur == level or not is_instance_valid(cur):
				if _wait > 600:
					fails.append("F9 made no new level")
					return _done()
				return false
			if not (cur is LayoutLevel):
				fails.append("F9 reloaded %s, not a LayoutLevel" % cur.name)
				return _done()
			level = cur
			_next(5)
		5:
			if not _started(level, "the F9 Thornwater"):
				return fails.size() > 0 and _done()
			if String((level as LayoutLevel).map_layout().id) != "thornwater":
				fails.append("F9 reloaded %s, not Thornwater" % (level as LayoutLevel).map_layout().id)
			MenuFlow.quit_to_menu(self)
			_next(6)
		6:
			var cur := current_scene
			if cur == null or cur == level or not is_instance_valid(cur) or not cur.has_method(&"start_skirmish"):
				if _wait > 600:
					fails.append("quit_to_menu from Thornwater did not open the main menu")
				else:
					return false
			return _done()
	return false


func _next(s: int) -> void:
	step = s
	_wait = 0


## True once `lvl` has its hero (the match runs); records a failure after BAKE_FRAMES.
func _started(lvl: Node, what: String) -> bool:
	if lvl == null or not is_instance_valid(lvl):
		fails.append("%s level vanished" % what)
		return false
	if lvl.get("hero") != null and bool(lvl.get(&"match_started")):
		return true
	if _wait > BAKE_FRAMES:
		fails.append("%s never started" % what)
	return false


func _done() -> bool:
	if FileAccess.file_exists(GameSettings.TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.TEST_PATH))
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	return true
