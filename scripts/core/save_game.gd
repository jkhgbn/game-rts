class_name SaveGame
extends RefCounted
## Mid-match save / load (docs/design/save-load.md): slot files under user://saves/, the "can I save now?" rules, the
## level description a load rebuilds from, and the launch of a saved match. The world itself is SaveWorld's; the
## SaveRestorer node applies it once the rebuilt level's match runs.
##   SaveGame.save_to_slot(level, &"slot_1") -> ""        SaveGame.load_slot(get_tree(), &"quick") -> ""
## Keys (PauseMenu): F12 quicksave, Ctrl+F12 quickload.

const VERSION := 1
const MAGIC := "FWSAVE"
const DIR := "user://saves"
const SLOTS: Array[StringName] = [&"slot_1", &"slot_2", &"slot_3", &"quick"]
const QUICK := &"quick"
const RESTORER_NAME := "SaveRestorer"
const RESTORER_SCRIPT := "res://scripts/core/save_restorer.gd"

# Reasons / messages: logic text, English here, shown through Loc.sink (HUD) or Loc.t (menu).
const REASON_NO_LEVEL := "Nothing to save here"
const REASON_NOT_STARTED := "The match has not started yet"
const REASON_OVER := "The match is over"
const REASON_FILM := "Can't save during a film"
const REASON_FILM_LOAD := "Can't load during a film"
const REASON_LOADING := "Still loading"
const REASON_WRITE := "Could not write the save file"
const REASON_NO_FILE := "No save in this slot"
const REASON_BAD_FILE := "This save file is damaged"
const REASON_VERSION := "This save is from another version of the game"
const REASON_NO_SCENE := "The saved map is missing"
const MSG_SAVED := "Game saved"
const MSG_LOADED := "Game loaded"

## Level properties a load sets again before the rebuilt level enters the tree (only those the level has).
const LEVEL_PROPS: Array[StringName] = [&"player_kingdom", &"enemy_kingdom", &"trade_enabled", &"time_limit_s",
		&"mission_difficulty", &"layout_path", &"personalities", &"autopilot_player", &"wizards_enabled",
		&"tiers_enabled", &"tavern_enabled", &"river_enabled", &"points_enabled", &"camps_enabled", &"beasts_enabled",
		&"fast_pace", &"blitz_pace"]


static func slot_path(slot: StringName) -> String:
	return "%s/%s.save" % [DIR, slot]


# ---------------------------------------------------------------- saving

## "" when `level` can be saved now, else why not (English logic text).
static func block_reason(level: Node) -> String:
	if level == null or not is_instance_valid(level) or not (&"build_grid" in level) or level.get(&"hero") == null:
		return REASON_NO_LEVEL
	if is_loading(level):
		return REASON_LOADING
	if &"match_started" in level and not bool(level.get(&"match_started")):
		return REASON_NOT_STARTED
	if bool(level.get(&"game_over")) or (&"result" in level and not (level.get(&"result") as Dictionary).is_empty()):
		return REASON_OVER
	for p in level.get_tree().get_nodes_in_group(&"cinematic_player"):
		if p.has_method(&"is_playing") and bool(p.call(&"is_playing")):
			return REASON_FILM
	if level is MissionBase:
		return (level as MissionBase).save_block_reason()
	return ""


## The full save Dictionary of `level` (no check: call block_reason first).
static func capture(level: Node) -> Dictionary:
	var info := level_info(level)
	var t := match_time_of(level)
	return {
		"magic": MAGIC,
		"version": VERSION,
		"meta": {"title": String(info["title"]), "mode": String(info["mode"]), "time": t,
				"date": Time.get_datetime_string_from_system(false, true), "unix": Time.get_unix_time_from_system()},
		"level": info,
		"world": SaveWorld.capture(level),
	}


## How to rebuild `level`: scene / script, mode, title, the properties set before the tree, the menu's choices.
static func level_info(level: Node) -> Dictionary:
	var props := {}
	for p in LEVEL_PROPS:
		if p in level:
			var v: Variant = level.get(p)
			if v is Array:
				v = (v as Array).duplicate()
			props[String(p)] = v
	var mode := "main"
	if level is MissionBase:
		mode = "mission"
	elif level is Skirmish:
		mode = "skirmish"
	elif &"director" in level:
		mode = "wave_strike"
	var title := String(level.get(&"mission_title")) if level is MissionBase else ""
	if title == "" and mode == "skirmish":
		var entry := MapCatalog.load_default().entry(MenuFlow.map_id)
		title = String(entry.get("title", "")) if entry is Dictionary else ""
		if title == "":
			title = "Skirmish"
	if title == "":
		title = "Wave Strike" if mode == "wave_strike" else "Mission 1"
	return {
		"scene": level.scene_file_path,
		"script": (level.get_script() as Script).resource_path if level.get_script() else "",
		"mode": mode,
		"title": title,
		"props": props,
		"difficulty": MenuFlow.difficulty,
		"map_id": String(MenuFlow.map_id),
		"layout_path": MenuFlow.map_layout_path,
		"player_kingdom": String(MenuFlow.player_kingdom),
		"enemy_kingdom": String(MenuFlow.enemy_kingdom),
	}


static func match_time_of(level: Node) -> float:
	if level.has_method(&"match_time"):
		return float(level.call(&"match_time"))
	var dir: Variant = level.get(&"director")
	if dir is Object and is_instance_valid(dir) and &"time" in dir:
		return float(dir.get(&"time"))
	return 0.0


## Writes `data` to `path` (folders created). "" or the reason. The old save is replaced only once the new file is
## fully written (R5-8: a full disk leaves the old save as it was): written to `.tmp`, checked (write error, length),
## the old file moved to `.bak`, the new one renamed in, the `.bak` removed (put back if the rename fails).
static func write_file(path: String, data: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var bak := path + ".bak"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return REASON_WRITE
	f.store_var(data, false)
	f.flush()
	var size := f.get_position()
	var err := f.get_error()
	f.close()
	var check := FileAccess.open(tmp, FileAccess.READ)
	var on_disk := check.get_length() if check else -1
	if check:
		check.close()
	if err != OK or size <= 0 or on_disk != size:
		DirAccess.remove_absolute(tmp)
		return REASON_WRITE
	var had_old := FileAccess.file_exists(path)
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(bak)   # a stale one (an earlier crash) or the last old save: replaced now
	if had_old:
		if DirAccess.rename_absolute(path, bak) != OK:
			DirAccess.remove_absolute(tmp)
			return REASON_WRITE
	if DirAccess.rename_absolute(tmp, path) != OK:
		if had_old:
			DirAccess.rename_absolute(bak, path)
		DirAccess.remove_absolute(tmp)
		return REASON_WRITE
	if had_old:
		DirAccess.remove_absolute(bak)
	return ""


## The save in `path`, or {"error": reason} (missing, damaged, other version). When `path` is missing (a crash between
## write_file's two renames), its `.bak` (the old save) then its `.tmp` (the new one, checked before the renames) are
## read instead.
static func read_file(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		return _read_one(path)
	for alt: String in [path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(alt):
			var d := _read_one(alt)
			if not d.has("error"):
				return d
	return {"error": REASON_NO_FILE}


## True when the slot's file (or a fallback read_file would use) is on disk.
static func save_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") or FileAccess.file_exists(path + ".tmp")


static func _read_one(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"error": REASON_BAD_FILE}
	var v: Variant = f.get_var(false)
	f.close()
	if not v is Dictionary or String((v as Dictionary).get("magic", "")) != MAGIC:
		return {"error": REASON_BAD_FILE}
	var d := v as Dictionary
	if int(d.get("version", -1)) != VERSION:
		return {"error": REASON_VERSION, "meta": d.get("meta", {})}
	if not d.get("level") is Dictionary or not d.get("world") is Dictionary:
		return {"error": REASON_BAD_FILE}
	return d


## Saves `level` into `slot`. "" or the reason (not saved).
static func save_to_slot(level: Node, slot: StringName) -> String:
	var why := block_reason(level)
	if why != "":
		return why
	return write_file(slot_path(slot), capture(level))


## For the slot list: {exists, error, title, time, date}.
static func slot_info(slot: StringName) -> Dictionary:
	var d := read_file(slot_path(slot))
	var meta: Dictionary = d.get("meta", {})
	return {"exists": save_exists(slot_path(slot)), "error": String(d.get("error", "")),
			"title": String(meta.get("title", "")), "time": float(meta.get("time", 0.0)), "date": String(meta.get("date", ""))}


static func clock(seconds: float) -> String:
	var s := maxi(0, int(seconds))
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60] if s >= 3600 else "%d:%02d" % [s / 60, s % 60]


# ---------------------------------------------------------------- loading

## Starts the match saved in `slot` (the current scene is replaced). "" or the reason (nothing changes).
static func load_slot(tree: SceneTree, slot: StringName) -> String:
	if CinematicPlayer.is_any_playing(tree):
		return REASON_FILM_LOAD   # V1-1: the film would keep playing over the loaded match
	var d := read_file(slot_path(slot))
	if d.has("error"):
		return String(d["error"])
	return "" if launch(tree, d) != null else REASON_NO_SCENE


## Rebuilds the saved level through the menu's start path and makes it the current scene. Null if it can't be built.
static func launch(tree: SceneTree, data: Dictionary) -> Node:
	var info: Dictionary = data["level"]
	MenuFlow.difficulty = int(info.get("difficulty", MenuFlow.difficulty))
	MenuFlow.map_id = StringName(str(info.get("map_id", MenuFlow.map_id)))
	MenuFlow.map_layout_path = String(info.get("layout_path", ""))
	if String(info.get("mode", "")) == "skirmish":
		MenuFlow.player_kingdom = StringName(str(info.get("player_kingdom", MenuFlow.player_kingdom)))
		MenuFlow.kingdom = MenuFlow.player_kingdom
		MenuFlow.enemy_kingdom = StringName(str(info.get("enemy_kingdom", MenuFlow.enemy_kingdom)))
	var props: Dictionary = info.get("props", {})
	if String(info.get("mode", "")) == "mission":
		# Retry after the load restarts this mission at the saved difficulty (review 2026-10-10 #6).
		MenuFlow.difficulty = clampi(int(props.get("mission_difficulty", 1)), 0, 2)
		MenuFlow.remember_mission(String(info.get("scene", "")))
	else:
		MenuFlow.remember_mission("")
	if String(info.get("mode", "")) == "wave_strike":
		MenuFlow.ws_kingdom = StringName(str(props.get("player_kingdom", MenuFlow.ws_kingdom)))
		MenuFlow.ws_enemy_resolved = StringName(str(props.get("enemy_kingdom", MenuFlow.ws_enemy_resolved)))
		var pers: Array = props.get("personalities", [])
		if pers.size() >= 2:
			MenuFlow.ws_personality = String(pers[1])
	var level := instantiate_level(data)
	if level == null:
		return null
	_remember_loaded_match(props)   # W1-3 / R5-9: F9 / Restart replays the saved match's settings
	MenuFlow.install_hooks(tree)
	# MenuFlow's node_added hook re-applies the CURRENT settings (trade, time limit) to a skirmish entering the tree;
	# this one-shot hook runs after it and puts the saved values back.
	var reapply := func(node: Node) -> void:
		if node == level:
			_apply_props(level, props)
	tree.node_added.connect(reapply)
	level.tree_entered.connect(func() -> void:
		if tree.node_added.is_connected(reapply):
			tree.node_added.disconnect(reapply), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	var bot := level.get_node_or_null(NodePath(MenuFlow.BOT_NODE))
	if bot != null and MenuFlow.difficulty >= 0:
		bot.set(&"difficulty", MenuFlow.difficulty)
	tree.paused = false
	MenuFlow.set_scene(tree, level)
	return level


## The saved level, not in the tree yet: its scene (or script), the saved properties, briefing / films / dialogue off
## while it rebuilds, and the SaveRestorer child that applies the world once the match runs. Tests add it themselves.
static func instantiate_level(data: Dictionary) -> Node:
	var info: Dictionary = data.get("level", {})
	var level: Node = null
	var scene := String(info.get("scene", ""))
	var script_path := String(info.get("script", ""))
	if scene != "" and ResourceLoader.exists(scene):
		level = (load(scene) as PackedScene).instantiate()
	elif script_path != "" and ResourceLoader.exists(script_path):
		var s := load(script_path) as Script
		if s and s.can_instantiate():
			level = s.new() as Node
	if level == null:
		return null
	_apply_props(level, info.get("props", {}))
	var restorer: Node = (load(RESTORER_SCRIPT) as Script).new()
	restorer.name = RESTORER_NAME
	restorer.set(&"data", data)
	restorer.call(&"prepare", level)
	level.add_child(restorer)
	return level


## MenuFlow.set_loaded_match(props) when the menu has it (ui-coder, F4).
static func _remember_loaded_match(props: Dictionary) -> void:
	var s := MenuFlow as Script
	for m: Dictionary in s.get_script_method_list():
		if StringName(m["name"]) == &"set_loaded_match":
			s.call(&"set_loaded_match", props)
			return


static func _apply_props(level: Node, props: Dictionary) -> void:
	for p: Variant in props:
		var key := StringName(str(p))
		if key in level:
			var v: Variant = props[p]
			if key == &"layout_path" and String(v) == "":
				continue
			if v is Array and level.get(key) is Array:
				(level.get(key) as Array).assign(v)
			else:
				level.set(key, v)


## True while a SaveRestorer is still rebuilding `level`.
static func is_loading(level: Node) -> bool:
	return level != null and is_instance_valid(level) and level.get_node_or_null(NodePath(RESTORER_NAME)) != null
