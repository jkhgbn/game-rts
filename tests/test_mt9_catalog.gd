extends SceneTree
## MT9 (docs/design/map-production.md 2.8 / 4.2): the MapCatalog (scripts/world/map_catalog.gd, data/maps/catalog.tres).
## - the catalog file loads (not the built-in fallback); ids unique; Crown Hollow is the default, a ready scene map;
## - every entry: title, 2 or 4 seats, a size, a scene or a layout that exists; every layout loads as a MapLayout of
##   that id; ready entries: the layout's size / seat count / biome match the entry, a 512 x 512 preview PNG exists
##   (the World Forge mapsheet render) and preview_texture() gives it, instantiate_level() builds the right level
##   (skirmish.tscn for Crown Hollow, LayoutLevel with layout_path for layouts);
## - every READY entry plays: its level enters the tree (sim mode, bots off), bakes, starts the match with no
##   layout_error, MapInfo has the map's size and both keeps stand on the map;
## - list / filters (2 seats, 4 seats, ready only), pick_random draws only ready maps of the filter, resolve() (Random,
##   unknown, not ready -> Crown Hollow), the 2v2 note while FOUR_SEAT_RUNTIME is false;
## - MenuFlow.instantiate_map remembers map_id / map_layout_path (restarts), GameSettings.map_id round-trips.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt9_catalog.gd --fixed-fps 60 --quit-after 20000
## Prints "PASS mt9_catalog" or "FAIL mt9_catalog: <reasons>".

const TASK_ID := "mt9_catalog"
const SIM := preload("res://scripts/core/sim_mode.gd")
const MapLab := preload("res://tools/map_lab/map_lab.gd")
const SETTINGS_PATH := "user://settings.cfg"

var cat: MapCatalog
var fails: Array[String] = []
var notes: Array[String] = []
var to_play: Array[StringName] = []
var level: Node
var playing: StringName = &""
var _wait := 0
var _backup := PackedByteArray()
var _had_backup := false


func _initialize() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		_had_backup = true
		_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	_static_checks()
	SIM.enabled = true
	for e: Dictionary in cat.list(0, true):
		to_play.append(StringName(e["id"]))
	_next_level()


func _static_checks() -> void:
	if not ResourceLoader.exists(MapCatalog.PATH):
		fails.append("no %s" % MapCatalog.PATH)
	cat = MapCatalog.load_default()
	if (load(MapCatalog.PATH) as MapCatalog) == null:
		fails.append("%s is not a MapCatalog" % MapCatalog.PATH)
	var seen := {}
	for e: Dictionary in cat.maps:
		var id := StringName(e.get("id", ""))
		if id == &"" or seen.has(id):
			fails.append("bad or duplicate id '%s'" % id)
		seen[id] = true
		var seats := int(e.get("seats", 0))
		if seats != 2 and seats != 4:
			fails.append("%s: %d seats" % [id, seats])
		if String(e.get("title", "")) == "" or not (e.get("size") is Vector2):
			fails.append("%s: no title or size" % id)
		var scene := String(e.get("scene", ""))
		var lp := String(e.get("layout", ""))
		if (scene == "") == (lp == ""):
			fails.append("%s: needs exactly one of scene / layout" % id)
		if scene != "" and not ResourceLoader.exists(scene):
			fails.append("%s: scene %s missing" % [id, scene])
		var ready := bool(e.get("ready", false))
		if lp != "":
			var lay := LayoutLevel.load_layout(lp)
			if lay == null:
				fails.append("%s: layout %s does not load" % [id, lp])
			else:
				if String(lay.id) != String(id):
					fails.append("%s: layout id is %s" % [id, lay.id])
				if ready:
					var sz: Vector2 = e["size"]
					if not is_equal_approx(lay.size_x, sz.x) or not is_equal_approx(lay.size_z, sz.y):
						fails.append("%s: catalog size %s, layout %s x %s" % [id, sz, lay.size_x, lay.size_z])
					if lay.seats.size() != seats:
						fails.append("%s: catalog %d seats, layout %d" % [id, seats, lay.seats.size()])
					if lay.biome != "" and lay.biome != String(e.get("biome", "")):
						fails.append("%s: catalog biome %s, layout %s" % [id, e.get("biome"), lay.biome])
		if not ready:
			if String(e.get("note", "")) == "":
				fails.append("%s: not ready but no note says why" % id)
			continue
		var pv := String(e.get("preview", ""))
		if pv == "" or not FileAccess.file_exists(pv):
			fails.append("%s: preview %s missing" % [id, pv])
		else:
			var img := Image.load_from_file(ProjectSettings.globalize_path(pv))
			if img == null or img.get_width() != 512 or img.get_height() != 512:
				fails.append("%s: preview is not 512 x 512" % id)
		if cat.preview_texture(id) == null:
			fails.append("%s: preview_texture() is null" % id)
		var lvl := cat.instantiate_level(id)
		if lvl == null:
			fails.append("%s: instantiate_level() is null" % id)
		else:
			if scene != "" and lvl.scene_file_path != scene:
				fails.append("%s: level scene %s" % [id, lvl.scene_file_path])
			if lp != "" and (not (lvl is LayoutLevel) or String(lvl.get(&"layout_path")) != lp):
				fails.append("%s: level is not a LayoutLevel on %s" % [id, lp])
			lvl.free()
	# default + filters
	var d := cat.entry(MapCatalog.DEFAULT_ID)
	if d.is_empty() or not bool(d.get("ready", false)) or String(d.get("scene", "")) != "res://scenes/skirmish.tscn":
		fails.append("Crown Hollow is not the ready scene-built default")
	var ones := cat.list(MapCatalog.SEATS_1V1, true)
	var twos := cat.list(MapCatalog.SEATS_2V2, true)
	if ones.size() < 2 or twos.is_empty():
		fails.append("expected >= 2 ready 1v1 maps and >= 1 ready 2v2 map, got %d / %d" % [ones.size(), twos.size()])
	for e in ones:
		if int(e["seats"]) != 2 or not bool(e["ready"]):
			fails.append("1v1 list has %s" % e["id"])
	if not cat.has_map(&"thornwater") or not cat.has_map(&"quartermeet"):
		fails.append("Thornwater / Quartermeet missing")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var r1 := cat.pick_random(MapCatalog.SEATS_1V1, rng)
		var r2 := cat.pick_random(MapCatalog.SEATS_2V2, rng)
		var r0 := cat.pick_random(0, rng)
		if not cat.is_ready(r1) or int(cat.entry(r1)["seats"]) != 2:
			fails.append("Random 1v1 drew %s" % r1)
			break
		if not cat.is_ready(r2) or int(cat.entry(r2)["seats"]) != 4:
			fails.append("Random 2v2 drew %s" % r2)
			break
		if not cat.is_ready(r0):
			fails.append("Random drew the not-ready %s" % r0)
			break
	if cat.resolve(&"no_such_map") != MapCatalog.DEFAULT_ID or cat.resolve(&"fourfold_hollow") != MapCatalog.DEFAULT_ID:
		fails.append("resolve() of an unknown / not-ready map is not Crown Hollow")
	if cat.resolve(&"thornwater") != &"thornwater":
		fails.append("resolve(thornwater) changed it")
	if not cat.is_ready(cat.resolve(MapCatalog.RANDOM_ID, MapCatalog.SEATS_1V1, rng)):
		fails.append("resolve(random) is not a ready map")
	var qm := cat.entry(&"quartermeet")
	if MapCatalog.mode_of(qm) != "2v2" or MapCatalog.plays_as(qm) != ("2v2" if MapCatalog.FOUR_SEAT_RUNTIME else "1v1"):
		fails.append("Quartermeet mode %s plays as %s" % [MapCatalog.mode_of(qm), MapCatalog.plays_as(qm)])
	if not MapCatalog.FOUR_SEAT_RUNTIME and MapCatalog.mode_note(qm) == "":
		fails.append("no 'plays as a 1v1' note on a 2v2 map")
	if MapCatalog.mode_note(cat.entry(&"thornwater")) != "":
		fails.append("a 1v1 map has a mode note")
	if MapCatalog.size_text(qm) != "176 m · 4 players":
		fails.append("size text '%s'" % MapCatalog.size_text(qm))
	# MenuFlow + GameSettings
	var lvl2 := MenuFlow.instantiate_map(&"thornwater")
	if MenuFlow.map_id != &"thornwater" or MenuFlow.map_layout_path != "res://data/maps/thornwater_layout.tres" or not (lvl2 is LayoutLevel):
		fails.append("MenuFlow.instantiate_map(thornwater): %s %s" % [MenuFlow.map_id, MenuFlow.map_layout_path])
	lvl2.free()
	var lvl3 := MenuFlow.instantiate_map(&"no_such_map")
	if MenuFlow.map_id != MapCatalog.DEFAULT_ID or MenuFlow.map_layout_path != "" or lvl3.scene_file_path != "res://scenes/skirmish.tscn":
		fails.append("MenuFlow.instantiate_map(unknown) is not Crown Hollow")
	lvl3.free()
	var lvl4 := MenuFlow.instantiate_map(MapCatalog.RANDOM_ID, MapCatalog.SEATS_2V2)
	if not cat.is_ready(MenuFlow.map_id) or int(cat.entry(MenuFlow.map_id)["seats"]) != 4:
		fails.append("MenuFlow Random 2v2 resolved to %s" % MenuFlow.map_id)
	lvl4.free()
	GameSettings.set_map_id(&"thornwater")
	GameSettings.load_settings()
	if GameSettings.map_id != &"thornwater":
		fails.append("GameSettings.map_id did not round-trip (%s)" % GameSettings.map_id)
	GameSettings.reset_defaults()
	if GameSettings.map_id != &"crown_hollow":
		fails.append("GameSettings default map is %s" % GameSettings.map_id)


func _next_level() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		level = null
	if to_play.is_empty():
		_done()
		return
	playing = to_play.pop_front()
	level = cat.instantiate_level(playing)
	MapLab._disable_bots(level)
	root.add_child(level)
	current_scene = level
	_wait = 0


func _process(_delta: float) -> bool:
	if level == null:
		return to_play.is_empty()
	_wait += 1
	MapLab._disable_bots(level)
	if not bool(level.get(&"match_started")):
		if level.has_method(&"layout_error") and String(level.call(&"layout_error")) != "":
			fails.append("%s: layout_error %s" % [playing, level.call(&"layout_error")])
			_next_level()
		elif _wait > 9000:
			fails.append("%s: the level never started" % playing)
			_next_level()
		return false
	var e := cat.entry(playing)
	var sz: Vector2 = e["size"]
	if not is_equal_approx(MapInfo.size_x, sz.x) or not is_equal_approx(MapInfo.size_z, sz.y):
		fails.append("%s: MapInfo %s x %s" % [playing, MapInfo.size_x, MapInfo.size_z])
	for team: int in [0, 1]:
		var k: Variant = level.call(&"keep_of", team)
		if k == null or not MapInfo.contains((k as Node3D).global_position, 2.0):
			fails.append("%s: team %d keep missing or off the map" % [playing, team])
	notes.append("%s plays (%d frames to start)" % [playing, _wait])
	_next_level()
	return false


func _done() -> void:
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_backup)
			f.close()
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
