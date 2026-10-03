extends SceneTree
## MT9 (docs/design/map-production.md 2.8 / 4.2): the skirmish menu's map picker (scripts/ui/menus/main_menu.gd).
## - the skirmish setup shows the map column: 1v1 / 2v2 filter, the list (Random first, then the catalog's ready maps of
##   the filter, with their preview icons), the preview, the title / info lines; the default is Crown Hollow (1v1);
## - mouse: a left click on a list item selects that map (preview + info follow);
## - keyboard: with the list focused, Down / Up move the selection (and the map), Enter moves the focus to Start; Enter
##   on the focused 2v2 filter button lists the 4-seat maps only, with the "plays as a 1v1 for now" note;
## - Random: "?" over the preview; Start with Random in the 2v2 filter launches a ready 4-seat map on LayoutLevel
##   (MenuFlow.map_id / map_layout_path remember it) and the restart hook (MenuFlow.restart, F9) reloads the same map;
## - Start saves the choice (GameSettings.map_id; the settings file is restored at the end).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt9_map_picker.gd --fixed-fps 60 --quit-after 12000
## Prints "PASS mt9_map_picker" or "FAIL mt9_map_picker: <reasons>".

const TASK_ID := "mt9_map_picker"
const SETTINGS_PATH := "user://settings.cfg"
const SIM := preload("res://scripts/core/sim_mode.gd")
const TIMEOUT_FRAMES := 10000

var menu: Node
var level: Node
var fails: Array[String] = []
var notes: Array[String] = []
var step := 0
var frame := 0
var _wait := 0
var _backup := PackedByteArray()
var _had_backup := false
var _restarted := false
var _pending_click := Vector2.INF


func _initialize() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		_had_backup = true
		_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	GameSettings.load_settings()
	GameSettings.map_id = &"crown_hollow"   # the default the picker opens on (not saved)
	root.size = Vector2i(1600, 900)
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	frame += 1
	_flush_click()
	if frame > TIMEOUT_FRAMES:
		fails.append("timed out at step %d" % step)
		return _done()
	match step:
		0:
			if frame < 3:
				return false
			menu.show_skirmish_setup()
			step = 1
			_wait = 0
		1:
			_wait += 1
			if _wait < 3:
				return false
			if not _check_layout():
				return _done()
			# mouse: click the Thornwater item
			var i: int = menu.map_list_ids.find(&"thornwater")
			_click_item(i)
			step = 2
			_wait = 0
		2:
			_wait += 1
			if _wait < 3:
				return false
			if menu.get_map() != &"thornwater":
				fails.append("a click on Thornwater selected %s" % menu.get_map())
			_check_shown(&"thornwater", "Thornwater", "120 m")
			# keyboard: focus the list, Up -> Crown Hollow, Up -> Random, Down -> Crown Hollow
			menu.map_list.grab_focus()
			_key(KEY_UP)
			step = 3
			_wait = 0
		3:
			_wait += 1
			if _wait < 2:
				return false
			if menu.get_map() != &"crown_hollow":
				fails.append("Up from Thornwater selected %s" % menu.get_map())
			_key(KEY_UP)
			step = 4
			_wait = 0
		4:
			_wait += 1
			if _wait < 2:
				return false
			if menu.get_map() != MapCatalog.RANDOM_ID:
				fails.append("Up from Crown Hollow selected %s" % menu.get_map())
			if not menu.map_preview_mark.visible or menu.map_preview.texture != null:
				fails.append("Random shows a preview image instead of the '?'")
			_key(KEY_DOWN)
			step = 5
			_wait = 0
		5:
			_wait += 1
			if _wait < 2:
				return false
			if menu.get_map() != &"crown_hollow":
				fails.append("Down from Random selected %s" % menu.get_map())
			_check_shown(&"crown_hollow", "Crown Hollow", "120 m")
			_key(KEY_ENTER)
			step = 6
			_wait = 0
		6:
			_wait += 1
			if _wait < 2:
				return false
			if root.gui_get_focus_owner() != menu.start_button:
				fails.append("Enter on the list did not focus Start (focus: %s)" % root.gui_get_focus_owner())
			# keyboard: focus the 2v2 filter button, Enter (Godot 4.7 headless drops mouse releases on Buttons: no hover;
			# the mouse path is the list click above)
			menu.map_filter_buttons[1].grab_focus()
			_key(KEY_ENTER)
			step = 7
			_wait = 0
		7:
			_wait += 1
			if _wait < 3:
				return false
			if menu.get_map_filter() != MapCatalog.SEATS_2V2:
				fails.append("the 2v2 button did not switch the filter")
			var ids: Array = menu.listed_maps()
			var cat := MapCatalog.load_default()
			if ids.is_empty() or ids[0] != MapCatalog.RANDOM_ID:
				fails.append("2v2 list does not start with Random: %s" % str(ids))
			for k in range(1, ids.size()):
				if int(cat.entry(ids[k]).get("seats", 0)) != 4 or not cat.is_ready(ids[k]):
					fails.append("2v2 list has %s" % ids[k])
			if not ids.has(&"quartermeet"):
				fails.append("Quartermeet is not in the 2v2 list")
			if menu.get_map() != &"quartermeet":
				fails.append("the 2v2 filter selected %s (expected its first map, Quartermeet)" % menu.get_map())
			_check_shown(&"quartermeet", "Quartermeet", "176 m")
			if not MapCatalog.FOUR_SEAT_RUNTIME and (not menu.map_note_label.visible or not menu.map_note_label.text.contains("1v1")):
				fails.append("no 'plays as a 1v1' note on Quartermeet: '%s'" % menu.map_note_label.text)
			# select_map of a 1v1 map switches the filter back; then Random in 2v2 and Start
			menu.select_map(&"thornwater")
			if menu.get_map_filter() != MapCatalog.SEATS_1V1 or menu.get_map() != &"thornwater":
				fails.append("select_map(thornwater) did not switch to the 1v1 filter")
			menu.set_map_filter(MapCatalog.SEATS_2V2)
			menu.select_map(MapCatalog.RANDOM_ID)
			SIM.enabled = true
			level = menu.start_skirmish()
			menu = null
			step = 8
			_wait = 0
		8:
			_wait += 1
			if level == null or not is_instance_valid(level):
				fails.append("Start made no level")
				return _done()
			if not bool(level.get(&"match_started")):
				if _wait > 9000:
					fails.append("the started map never baked")
					return _done()
				return false
			var cat := MapCatalog.load_default()
			if not (level is LayoutLevel) or not cat.is_ready(MenuFlow.map_id) or int(cat.entry(MenuFlow.map_id)["seats"]) != 4:
				fails.append("Random 2v2 started %s (%s)" % [MenuFlow.map_id, level.get_script().resource_path])
			elif String((level as LayoutLevel).map_layout().id) != String(MenuFlow.map_id):
				fails.append("the level plays %s, MenuFlow says %s" % [(level as LayoutLevel).map_layout().id, MenuFlow.map_id])
			if GameSettings.map_id != MapCatalog.RANDOM_ID:
				fails.append("Start did not save the choice (GameSettings.map_id %s)" % GameSettings.map_id)
			notes.append("Random 2v2 -> %s" % MenuFlow.map_id)
			# restart (pause menu / F9): the reloaded LayoutLevel gets the same map back
			MenuFlow.restart(self)
			step = 9
			_wait = 0
		9:
			_wait += 1
			var cur := current_scene
			if cur == null or cur == level or not is_instance_valid(cur):
				if _wait > 600:
					fails.append("restart made no new level")
					return _done()
				return false
			if not bool(cur.get(&"match_started")):
				if _wait > 9000:
					fails.append("the restarted map never baked")
					return _done()
				return false
			if not (cur is LayoutLevel) or String((cur as LayoutLevel).map_layout().id) != String(MenuFlow.map_id):
				fails.append("restart reloaded %s, not %s" % [cur.get(&"layout_path"), MenuFlow.map_id])
			elif String((cur as LayoutLevel).layout_error()) != "":
				fails.append("restarted level: %s" % (cur as LayoutLevel).layout_error())
			return _done()
	return false


func _check_layout() -> bool:
	if menu.map_list == null or menu.map_filter_buttons.size() != 2 or menu.map_preview == null:
		fails.append("no map column in the skirmish setup")
		return false
	if not menu.map_list.is_visible_in_tree():
		fails.append("the map list is not visible")
	var cat := MapCatalog.load_default()
	var ids: Array = menu.listed_maps()
	var want := 1 + cat.list(MapCatalog.SEATS_1V1, true).size()
	if ids.size() != want or menu.map_list.item_count != want:
		fails.append("1v1 list has %d items (%d ids), expected %d" % [menu.map_list.item_count, ids.size(), want])
	if ids.is_empty() or ids[0] != MapCatalog.RANDOM_ID:
		fails.append("the list does not start with Random")
	for k in range(1, ids.size()):
		if menu.map_list.get_item_icon(k) == null:
			fails.append("%s has no preview icon" % ids[k])
	if menu.get_map() != &"crown_hollow" or menu.get_map_filter() != MapCatalog.SEATS_1V1:
		fails.append("default is %s (%d seats), expected Crown Hollow 1v1" % [menu.get_map(), menu.get_map_filter()])
	_check_shown(&"crown_hollow", "Crown Hollow", "120 m")
	# the panel fits the 1600 x 900 window
	var panel: Control = menu.skirmish_panel
	var r := panel.get_global_rect()
	notes.append("skirmish panel %s" % r)
	if r.position.x < 0 or r.end.x > 1600 or r.position.y < 0 or r.end.y > 900:
		fails.append("the skirmish panel %s does not fit 1600 x 900" % r)
	return true


func _check_shown(id: StringName, title: String, size_word: String) -> void:
	if menu.map_title_label.text != title:
		fails.append("%s: title '%s'" % [id, menu.map_title_label.text])
	if not menu.map_info_label.text.contains(size_word):
		fails.append("%s: info '%s' lacks %s" % [id, menu.map_info_label.text, size_word])
	if menu.map_preview.texture == null or menu.map_preview_mark.visible:
		fails.append("%s: no preview image" % id)
	var sel: PackedInt32Array = menu.map_list.get_selected_items()
	if sel.size() != 1 or menu.map_list_ids[sel[0]] != id:
		fails.append("%s: the list selection is %s" % [id, str(sel)])


func _click_item(i: int) -> void:
	if i < 0:
		fails.append("item not listed")
		return
	var list: ItemList = menu.map_list
	var r := list.get_item_rect(i)
	_click_at(list.get_global_transform() * (r.position + r.size * 0.5))


## Mouse motion now, the press + release one frame later (a Button only takes a release it is hovered for).
func _click_at(p: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = p
	move.global_position = p
	root.push_input(move)
	_pending_click = p


func _flush_click() -> void:
	if _pending_click == Vector2.INF:
		return
	var p := _pending_click
	_pending_click = Vector2.INF
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		ev.pressed = pressed
		ev.position = p
		ev.global_position = p
		root.push_input(ev)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		root.push_input(ev)


func _done() -> bool:
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_backup)
			f.close()
		GameSettings.load_settings()
	else:
		GameSettings.reset_defaults()   # no settings file before the test: leave one with the defaults
		GameSettings.save_settings()
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)
	return true
