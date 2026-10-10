extends SceneTree
## Mid-match save / load (docs/design/save-load.md):
##  A. skirmish round trip: play ~10 s, change the state (crystals, a queue, a soldier, hero XP / damage, a move order),
##     save to a file, read it back, rebuild the level from it, compare units / economy / buildings / clock;
##  B. mission round trip (MissionSkeleton): objectives, fired events, flags, a script variable, a named-method timer,
##     the hero's spot; a lambda timer blocks the save;
##  C. a save of another version is refused (nothing launched), a missing slot too; the pause menu lists 4 slots;
##  D. Wave Strike round trip (bots on both seats): clock, horn, cards, lane units, crystals.
##  Review 2026-10-10: a saved site is rebuilt as a site (never complete first, #5); a dead wizard keeps its
##  death_guard and its mission died handlers stay quiet (#7); launching a mission save remembers the mission for Retry
##  with its saved difficulty (#6).
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_save_load.gd --fixed-fps 60 --quit-after 30000
## Prints "PASS save_load" or "FAIL save_load: <reasons>".

const TASK_ID := "save_load"
const TEST_PATH := "user://saves/_test_save_load.save"
const POS_TOL := 1.5
const HP_TOL := 0.06

var errors: Array[String] = []
var level: Node
var step := "skirmish_start"
var frames := 0
var total := 0
var data: Dictionary = {}
var expect: Dictionary = {}
var restorer_done := false
var watch_sites := false
var sites_born_complete := 0


func _initialize() -> void:
	print("test_save_load: start")
	node_added.connect(_on_node_added)
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	total += 1
	frames += 1
	if total > 25000:
		_fail("timed out at step %s" % step)
		return _finish()
	match step:
		"skirmish_start":
			if level.get(&"hero") != null and bool(level.get(&"match_started")):
				_bots_off()
				_goto("skirmish_play")
		"skirmish_play":
			if frames >= 600:
				_skirmish_change()
				_goto("skirmish_settle")
		"skirmish_settle":
			if frames >= 3:
				_skirmish_save()
				_goto("skirmish_reload")
		"skirmish_reload":
			watch_sites = true
			sites_born_complete = 0
			_reload_from(data)
			_goto("skirmish_wait")
		"skirmish_wait":
			if restorer_done:
				watch_sites = false
				if sites_born_complete > 0:
					_fail("a saved construction site was rebuilt complete first (%d)" % sites_born_complete)
				_bots_off()
				_skirmish_compare()
				_dead_wizard_check()
				_launch_retry_check()
				_check_pause_menu()
				_version_checks()
				_mission_start()
				_goto("mission_start")
		"mission_start":
			if level.get(&"hero") != null and bool(level.get(&"match_started")):
				_goto("mission_play")
		"mission_play":
			if frames >= 120:
				_mission_change_and_save()
				_goto("mission_reload")
		"mission_reload":
			_reload_from(data)
			_goto("mission_wait")
		"mission_wait":
			if restorer_done:
				_mission_compare()
				_ws_start()
				_goto("ws_play")
		"ws_play":
			var dir: Variant = level.get(&"director")
			if dir != null and int(dir.get(&"horn_index")) >= 1 and (level.call(&"lane_units") as Array).size() >= 2:
				_ws_save()
				_goto("ws_reload")
			elif frames > 6000:
				_fail("Wave Strike: no horn / lane unit after 100 s")
				return _finish()
		"ws_reload":
			_reload_from(data)
			_goto("ws_wait")
		"ws_wait":
			if restorer_done:
				_ws_compare()
				return _finish()
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _fail(msg: String) -> void:
	errors.append(msg)
	print("  x ", msg)


func _finish() -> bool:
	DirAccess.remove_absolute(TEST_PATH)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true


func _bots_off() -> void:
	for n in level.find_children("*", "Commander", true, false):
		n.set(&"enabled", false)


## Frees the running level and builds the saved one in its place (what SaveGame.launch does, minus MenuFlow).
func _reload_from(d: Dictionary) -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = SaveGame.instantiate_level(d)
	if level == null:
		_fail("instantiate_level returned null")
		quit(1)
		return
	restorer_done = false
	var r := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		if not ok:
			_fail("the restorer reported a failure"))
	root.add_child(level)
	current_scene = level


## Review 2026-10-10 #5: a hearth site entering the tree during the load must already be a site.
func _on_node_added(n: Node) -> void:
	if watch_sites and n is Building and (n as Building).building_type 			and (n as Building).building_type.id == &"fire_hearth" and (n as Building).is_constructed():
		sites_born_complete += 1


## A died listener on a mission (it has save_restoring): muted while a load kills a wizard that was dead at the save.
class MutedListener:
	extends RefCounted
	var save_restoring := true
	var calls := 0

	func on_died(_u: Unit) -> void:
		calls += 1


## Review 2026-10-10 #7: restoring a dead wizard keeps the guard the rebuilt start gave it and does not run the
## mission's died handlers.
func _dead_wizard_check() -> void:
	var w := level.call(&"wizard_of", 1) as Wizard if level.has_method(&"wizard_of") else null
	if w == null or not w.is_alive():
		w = level.get(&"hero") as Wizard   # a skirmish respawns it (no enemy wizard on this map setup)
	if w and not w.is_alive():
		w = null
	if w == null:
		_fail("no living wizard for the dead-wizard check")
		return
	var guard := func(_a: Variant) -> bool: return true
	w.death_guard = guard
	var muted := MutedListener.new()
	w.died.connect(muted.on_died)
	w.load_snapshot_late({"alive": false, "wizard": {}}, {}, {})
	if w.is_alive():
		_fail("a wizard saved dead is alive after load_snapshot_late")
	if w.death_guard != guard:
		_fail("load_snapshot_late of a dead wizard wiped its death_guard")
	if muted.calls != 0:
		_fail("a mission died handler ran for a wizard dead at the save")
	if not w.died.is_connected(muted.on_died):
		_fail("the muted died handler was not connected back")
	else:
		w.died.disconnect(muted.on_died)
	w.death_guard = Callable()


## Review 2026-10-10 #6: SaveGame.launch of a mission save sets the menu's mission path and difficulty (Retry). A scene
## that does not exist builds nothing, but the menu state is set before.
func _launch_retry_check() -> void:
	var keep_diff := MenuFlow.difficulty
	var keep_map := MenuFlow.map_id
	var keep_layout := MenuFlow.map_layout_path
	var path := "res://missions/_no_such_mission.tscn"
	var d := {"level": {"mode": "mission", "scene": path, "props": {"mission_difficulty": 2}, "difficulty": 0}}
	if SaveGame.launch(self, d) != null:
		_fail("launch built a level from a missing scene")
	if MenuFlow.difficulty != 2 or MenuFlow._mission_path != path:
		_fail("launch of a mission save: difficulty %d, mission path '%s'" % [MenuFlow.difficulty, MenuFlow._mission_path])
	MenuFlow.remember_mission("")
	MenuFlow.difficulty = keep_diff
	MenuFlow.map_id = keep_map
	MenuFlow.map_layout_path = keep_layout


# ---------------------------------------------------------------- A. skirmish

func _skirmish_change() -> void:
	var eco := Economy.for_team(Unit.Team.PLAYER)
	eco.crystals = 777
	var keep: Keep = level.get(&"keep")
	var worker_type := keep.trainable_types()[0]
	eco.crystals += worker_type.cost
	if keep.queue_unit(worker_type) != "":
		_fail("could not queue a worker")
	var hero: Wizard = level.get(&"hero")
	hero.add_xp(400)
	hero.take_damage(60.0, null)
	hero.command_move(hero.global_position + Vector3(6.0, 0.0, -4.0))
	var soldier := Worker.make_unit(UnitType.find("flame_guard"))
	soldier.team = Unit.Team.PLAYER
	level.add_child(soldier)
	soldier.global_position = keep.global_position + Vector3(6.0, 0.0, -6.0)
	soldier.command_hold()
	soldier.add_xp(Unit.VETERANCY_XP[1])
	soldier.add_modifier(&"mission:test_buff", {"attack_damage": 5.0})
	soldier.take_damage(20.0, null)
	# a finished barracks training a soldier, a hearth under construction, a mined node, a champion
	var grid: BuildGrid = level.get(&"build_grid")
	var rax_type := BuildingType.find("fire_barracks")
	var rax := grid.spawn_complete(rax_type, grid.find_spot(rax_type, keep.global_position + Vector3(10, 0, -10), 0), 0) as TrainingBuilding
	grid.request_rebake()
	var trainee: UnitType = rax.trainable_types()[0]
	eco.crystals += trainee.cost
	if rax.queue_unit(trainee) != "":
		_fail("could not queue in the barracks")
	var site_type := BuildingType.find("fire_hearth")
	eco.crystals += site_type.cost
	var builder: Unit = null
	for n in get_nodes_in_group(&"units"):
		if n is Worker and int((n as Unit).team) == 0:
			builder = n
			break
	var site := grid.place(site_type, grid.find_spot(site_type, keep.global_position + Vector3(-8, 0, -10), 0), 0, [builder])
	if site == null:
		_fail("could not place a hearth site: %s" % grid.last_reason)
	var node: CrystalNode = level.call(&"node_of", 0, "b")
	node.take(55)
	var guild: ChampionGuild = level.call(&"guild_of", 0)
	if guild:
		var ch: Unit = guild.add_companion({"id": String(ChampionGuild.ARCHETYPES[0]), "variant": 0}, keep.global_position + Vector3(4, 0, 4))
		if ch:
			ch.add_xp(250)
		else:
			_fail("could not add a champion")


func _skirmish_save() -> void:
	if SaveGame.block_reason(level) != "":
		_fail("skirmish save refused: %s" % SaveGame.block_reason(level))
	var why := SaveGame.write_file(TEST_PATH, SaveGame.capture(level))
	if why != "":
		_fail("write_file: %s" % why)
	data = SaveGame.read_file(TEST_PATH)
	if data.has("error"):
		_fail("read_file: %s" % data["error"])
	expect = _snapshot()
	print("  saved: %d units, %d buildings, t=%.1f" % [(expect["units"] as Array).size(),
			(expect["buildings"] as Array).size(), float(expect["time"])])


func _snapshot() -> Dictionary:
	var units: Array = []
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and not u.is_queued_for_deletion():
			units.append({"type": String(u.unit_type.id) if u.unit_type else u.get_class(), "team": int(u.team),
					"pos": u.global_position, "hp": u.hp, "level": u.level, "hold": u.is_holding(),
					"mod": u.has_modifier(&"mission:test_buff")})
	var buildings: Array = []
	for n in get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b and b.is_alive() and b.building_type:
			buildings.append({"type": String(b.building_type.id), "team": int(b.team), "hp": b.hp,
					"built": b.is_constructed(),
					"queue": (b.get(&"queue") as Array).size() if &"queue" in b else 0})
	var hero: Wizard = level.get(&"hero")
	var nodes := {}
	for n in get_nodes_in_group(&"crystal_nodes"):
		nodes[String((n as CrystalNode).node_id)] = (n as CrystalNode).crystals_left
	var champs: Array = []
	for n in get_nodes_in_group(&"champions"):
		champs.append([String(n.call(&"type_id")), int(n.get(&"level")), int(n.get(&"xp"))])
	champs.sort()
	return {
		"units": units, "buildings": buildings, "nodes": nodes, "champions": champs,
		"crystals": [Economy.for_team(0).crystals, Economy.for_team(1).crystals],
		"pop": Economy.for_team(0).pop_used,
		"time": float(level.call(&"match_time")),
		"hero_level": hero.level, "hero_xp": hero.xp, "hero_hp": hero.hp, "hero_moving": hero.has_move_order(),
	}


func _skirmish_compare() -> void:
	var got := _snapshot()
	if absf(float(got["time"]) - float(expect["time"])) > 1.0:
		_fail("match time %.1f, saved %.1f" % [got["time"], expect["time"]])
	for t in 2:
		if absi(int(got["crystals"][t]) - int(expect["crystals"][t])) > 20:
			_fail("team %d crystals %d, saved %d" % [t, got["crystals"][t], expect["crystals"][t]])
	if int(got["pop"]) != int(expect["pop"]):
		_fail("player pop %d, saved %d" % [got["pop"], expect["pop"]])
	if int(got["hero_level"]) != int(expect["hero_level"]) or int(got["hero_xp"]) != int(expect["hero_xp"]):
		_fail("hero level/xp %d/%d, saved %d/%d" % [got["hero_level"], got["hero_xp"], expect["hero_level"], expect["hero_xp"]])
	if absf(float(got["hero_hp"]) - float(expect["hero_hp"])) > 5.0:
		_fail("hero hp %.0f, saved %.0f" % [got["hero_hp"], expect["hero_hp"]])
	if not bool(got["hero_moving"]):
		_fail("the hero's move order was not restored")
	# units: same count per (type, team); each saved unit has a twin near its spot with about its HP
	var left: Array = (got["units"] as Array).duplicate()
	for e: Dictionary in expect["units"]:
		var best := -1
		var best_d := INF
		for i in left.size():
			var g: Dictionary = left[i]
			if g["type"] != e["type"] or g["team"] != e["team"]:
				continue
			var d := (g["pos"] as Vector3).distance_to(e["pos"])
			if d < best_d:
				best_d = d
				best = i
		if best < 0:
			_fail("unit %s (team %d) missing after the load" % [e["type"], e["team"]])
			continue
		var g: Dictionary = left[best]
		left.remove_at(best)
		if best_d > POS_TOL:
			_fail("unit %s moved %.1f m" % [e["type"], best_d])
		if absf(float(g["hp"]) - float(e["hp"])) > maxf(3.0, float(e["hp"]) * HP_TOL):
			_fail("unit %s hp %.0f, saved %.0f" % [e["type"], g["hp"], e["hp"]])
		if int(g["level"]) != int(e["level"]) or bool(g["hold"]) != bool(e["hold"]) or bool(g["mod"]) != bool(e["mod"]):
			_fail("unit %s level/hold/modifier differ" % e["type"])
	if not left.is_empty():
		_fail("%d extra units after the load (first %s)" % [left.size(), (left[0] as Dictionary)["type"]])
	for id: String in expect["nodes"]:
		if absi(int((got["nodes"] as Dictionary).get(id, -1)) - int(expect["nodes"][id])) > 25:
			_fail("crystal node %s: %s left, saved %d" % [id, (got["nodes"] as Dictionary).get(id, "gone"), expect["nodes"][id]])
	if str(got["champions"]) != str(expect["champions"]) or (expect["champions"] as Array).is_empty():
		_fail("champions %s, saved %s" % [got["champions"], expect["champions"]])
	var bl: Array = (got["buildings"] as Array).duplicate()
	for e: Dictionary in expect["buildings"]:
		var found := -1
		for i in bl.size():
			if bl[i]["type"] == e["type"] and bl[i]["team"] == e["team"] and bl[i]["queue"] == e["queue"] \
					and bl[i]["built"] == e["built"] \
					and absf(float(bl[i]["hp"]) - float(e["hp"])) <= maxf(5.0, float(e["hp"]) * HP_TOL):
				found = i
				break
		if found < 0:
			_fail("building %s (team %d, queue %d) not restored" % [e["type"], e["team"], e["queue"]])
		else:
			bl.remove_at(found)
	if not bl.is_empty():
		_fail("%d extra buildings after the load" % bl.size())
	print("  skirmish compared: %d units, %d buildings" % [(got["units"] as Array).size(), (got["buildings"] as Array).size()])


# ---------------------------------------------------------------- C. pause menu, versions

func _check_pause_menu() -> void:
	var pm := level.get_node_or_null(^"PauseMenu")
	if pm == null:
		_fail("no PauseMenu in the level")
		return
	pm.call(&"show_slots", &"load")
	var buttons: Array = pm.get(&"slot_buttons")
	if buttons.size() != 4:
		_fail("the slot list has %d rows, want 4" % buttons.size())
	for b: Button in buttons:
		if b.text == "":
			_fail("an empty slot row label")
	pm.call(&"_close_slots")
	# every SaveGame message is a translation key (listed in PauseMenu.SAVE_TEXTS)
	var listed: Array = (pm.get_script() as Script).get_script_constant_map().get("SAVE_TEXTS", [])
	var consts := (load("res://scripts/core/save_game.gd") as Script).get_script_constant_map()
	for k: String in consts:
		if (k.begins_with("REASON_") or k.begins_with("MSG_")) and not listed.has(String(consts[k])):
			_fail("SaveGame.%s is not in PauseMenu.SAVE_TEXTS" % k)


func _version_checks() -> void:
	var old := data.duplicate()
	old["version"] = SaveGame.VERSION + 100
	SaveGame.write_file(TEST_PATH, old)
	var back := SaveGame.read_file(TEST_PATH)
	if String(back.get("error", "")) != SaveGame.REASON_VERSION:
		_fail("a save of another version was not refused (%s)" % back.get("error", "read ok"))
	var slot_path := SaveGame.slot_path(&"slot_3")
	var had := FileAccess.file_exists(slot_path)
	if not had:
		SaveGame.write_file(slot_path, old)
		var scene_before := current_scene
		var why := SaveGame.load_slot(self, &"slot_3")
		if why != SaveGame.REASON_VERSION or current_scene != scene_before:
			_fail("load_slot of another version: '%s', scene changed %s" % [why, current_scene != scene_before])
		DirAccess.remove_absolute(slot_path)
	if SaveGame.read_file("user://saves/_nothing_here.save").get("error", "") != SaveGame.REASON_NO_FILE:
		_fail("a missing file is not reported")


# ---------------------------------------------------------------- B. mission

func _mission_start() -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = MissionSkeleton.new()
	level.set(&"show_briefing", false)
	level.set(&"save_campaign_on_victory", false)
	level.set(&"cinematics_enabled", false)
	root.add_child(level)
	current_scene = level


func _mission_change_and_save() -> void:
	var m := level as MissionBase
	m.set_mission_flag("test_flag", 3)
	m.fire_once(&"test_event")
	m.set_objective(&"sec_bonus", "active")
	m.set_objective(&"sec_bonus", "done")
	m.set(&"gate_open", false)   # the intro's end state set it true; the load must keep false
	var hero: Wizard = level.get(&"hero")
	hero.global_position = hero.global_position + Vector3(5.0, 0.0, 3.0)
	hero.command_stop()
	m.after(5.0, func() -> void: pass)
	if m.save_block_reason() != MissionBase.SAVE_REASON_SCRIPTED:
		_fail("a lambda timer did not block the save ('%s')" % m.save_block_reason())
	(m.get(&"_timers") as Array).clear()
	m.after(500.0, Callable(m, &"show_spotlight"))   # a named-method timer survives
	if SaveGame.block_reason(level) != "":
		_fail("mission save refused: %s" % SaveGame.block_reason(level))
	data = SaveGame.capture(level)
	expect = {"hero_pos": hero.global_position, "time": m.mission_time()}


func _mission_compare() -> void:
	var m := level as MissionBase
	if not m is MissionSkeleton:
		_fail("the mission was not rebuilt as MissionSkeleton")
		return
	if m.objective_state("sec_bonus") != "done" or m.objective_state("obj_reach") != "active":
		_fail("objectives: sec_bonus=%s obj_reach=%s" % [m.objective_state("sec_bonus"), m.objective_state("obj_reach")])
	if not m.has_fired(&"test_event"):
		_fail("fired event lost")
	if int(m.mission_flags().get("test_flag", 0)) != 3:
		_fail("mission flag lost")
	if bool(m.get(&"gate_open")):
		_fail("the mission script variable gate_open was not restored")
	var timers: Array = m.get(&"_timers")
	if timers.size() != 1 or (timers[0][1] as Callable).get_method() != &"show_spotlight":
		_fail("the named timer was not restored (%d timers)" % timers.size())
	if absf(m.mission_time() - float(expect["time"])) > 1.0:
		_fail("mission time %.1f, saved %.1f" % [m.mission_time(), expect["time"]])
	var hero: Wizard = level.get(&"hero")
	if hero.global_position.distance_to(expect["hero_pos"]) > POS_TOL:
		_fail("mission hero at %s, saved %s" % [hero.global_position, expect["hero_pos"]])
	if bool(m.get(&"save_restoring")):
		_fail("restoring flag left on")
	print("  mission compared")


# ---------------------------------------------------------------- D. Wave Strike

func _ws_start() -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = load("res://scenes/wave_strike.tscn").instantiate()
	level.set(&"autopilot_player", true)
	root.add_child(level)
	current_scene = level


func _ws_state() -> Dictionary:
	var dir: Object = level.get(&"director")
	var rosters: Array = level.get(&"rosters")
	var lanes := [0, 0]
	for u: Unit in level.call(&"lane_units"):
		lanes[int(u.team)] += 1
	return {"time": float(dir.get(&"time")), "horn": int(dir.get(&"horn_index")),
			"cards": [str((rosters[0] as Object).call(&"cards")), str((rosters[1] as Object).call(&"cards"))],
			"lanes": lanes, "crystals": [Economy.for_team(0).crystals, Economy.for_team(1).crystals]}


func _ws_save() -> void:
	for n in level.find_children("WaveBot*", "", true, false):
		n.process_mode = Node.PROCESS_MODE_DISABLED
	if SaveGame.block_reason(level) != "":
		_fail("Wave Strike save refused: %s" % SaveGame.block_reason(level))
	data = SaveGame.capture(level)
	expect = _ws_state()
	print("  ws saved: horn %d, lanes %s, t=%.1f" % [expect["horn"], expect["lanes"], expect["time"]])


func _ws_compare() -> void:
	for n in level.find_children("WaveBot*", "", true, false):
		n.process_mode = Node.PROCESS_MODE_DISABLED
	var got := _ws_state()
	if absf(float(got["time"]) - float(expect["time"])) > 1.0 or int(got["horn"]) != int(expect["horn"]):
		_fail("Wave Strike clock %.1f / horn %d, saved %.1f / %d" % [got["time"], got["horn"], expect["time"], expect["horn"]])
	if str(got["cards"]) != str(expect["cards"]):
		_fail("Wave Strike cards %s, saved %s" % [got["cards"], expect["cards"]])
	if str(got["lanes"]) != str(expect["lanes"]):
		_fail("Wave Strike lane units %s, saved %s" % [got["lanes"], expect["lanes"]])
	for t in 2:
		if absi(int(got["crystals"][t]) - int(expect["crystals"][t])) > 20:
			_fail("Wave Strike team %d crystals %d, saved %d" % [t, got["crystals"][t], expect["crystals"][t]])
	print("  ws compared")
