extends SceneTree
## Bot review 2026-10-12 (docs/handoff/bot-review-2026-10-12.md "A: Commander" + "Verification A + C"), fixes in
## scripts/ai/commander.gd, checked unit-level on scenes/skirmish.tscn (camps only) with the ENEMY Commander frozen
## (enabled = false after its setup; the test sets _now and calls the rule steps itself):
##   A3  _adopt_buildings adopts X1 (the natural hall spot, "pos" INF) and a building shifted off its slot (<= 10 m).
##   A5  "group lost" in Stage.CREEP ends the creep (current_creep cleared) and sets _creep_retry_at.
##   A2  Stage.HUNT: a point not reached in 60 s -> the next explore point; a building not reached -> skipped and not
##       hunted again; a member near the building keeps the hunt.
##   A4  all_in turns off once mining is possible again for 20 s (not before).
##   A6  _reserve_split keeps ai.attack_reserve pop (never a pop >= 3 unit); the sortie uses it.
##   A1  a site no builder may reach for 90 s stops blocking _next_row; X1 is not held without map-fill creeps.
##   A7  the fog-less scout leaves a loop point after SCOUT_LEG_TIME.
##   C1  is_army_unit(u): own soldier true; scout, worker, enemy false.
## Run:  godot --headless --path . -s tests/test_botfix_commander.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "botfix_commander"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1

var main: Node
var bot: Node
var _wait := 0
var _errors: Array[String] = []
var _soldiers: Array[Unit] = []


func _initialize() -> void:
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	main = load(SCENE).instantiate()
	for f: StringName in [&"river_enabled", &"points_enabled", &"beasts_enabled"]:   # camps on: A1 map fill
		if f in main:
			main.set(f, false)
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == ENEMY:
			bot = child
	if bot == null:
		bot = COMMANDER.new()
		bot.team = ENEMY
		main.add_child(bot)
	bot.difficulty = 1
	bot.profile = AIProfile.for_difficulty(1)
	bot.profile_id = &""
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if not main.match_started or not bool(bot.get(&"_ready_done")):
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: the bot never started" % TASK_ID)
			return true
		return false
	bot.enabled = false   # frozen: the test drives it
	_run()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("  error: " + e)
		print("FAIL %s: %s" % [TASK_ID, _errors[0]])
	return true


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["ok  " if ok else "BAD ", what])
	if not ok:
		_errors.append(what)


func _soldier(at: Vector3, type_id: String = "shade", team: int = ENEMY) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	main.add_child(u)
	u.global_position = at
	u.command_stop()
	return u


func _run() -> void:
	var rally: Vector3 = bot.get(&"_rally")
	for i in 3:
		_soldiers.append(_soldier(rally + Vector3(i, 0.0, 0.0)))
	bot.set(&"_now", main.match_time())
	bot.call(&"_scan")
	_a3()
	_a5()
	_a2()
	_a4()
	_a6()
	_a1()
	_a7()
	_c1()


# ---------------------------------------------------------------- A3

var _x1_site: Building = null
var _h1_site: Building = null


func _a3() -> void:
	var eco := Economy.for_team(ENEMY)
	eco.add(3000)
	var faction: StringName = bot.get(&"faction")
	var type: BuildingType = null
	for t in BuildingType.buildable_for(faction):
		if t.kind == &"barracks":
			type = t
	if type == null:
		_check(false, "A3: no barracks type for %s" % faction)
		return
	var grid: BuildGrid = main.build_grid
	var natural: Vector3 = main.natural_hall_spot(ENEMY)
	var spot := Vector3.INF
	for off: Vector3 in [Vector3(6, 0, 0), Vector3(-6, 0, 0), Vector3(0, 0, 6), Vector3(0, 0, -6), Vector3(5, 0, 5),
			Vector3(-5, 0, -5), Vector3(5, 0, -5), Vector3(-5, 0, 5), Vector3(8, 0, 0), Vector3(0, 0, 8)]:
		var p: Vector3 = grid.snap(natural + off, type.footprint)
		if Vector2(p.x - natural.x, p.z - natural.z).length() <= 9.5 and grid.check(type, p, ENEMY) == "":
			spot = p
			break
	if spot == Vector3.INF:
		spot = natural   # still proves the X1 ("pos" INF) adoption
	_x1_site = grid.place(type, spot, ENEMY, [])
	var h1_spot: Vector3 = bot.call(&"planned_spot", &"H1")
	_h1_site = grid.place(type, h1_spot, ENEMY, []) if grid.check(type, h1_spot, ENEMY) == "" else null
	_check(_x1_site != null, "A3: a barracks site near the natural (%.1f m off the slot)" % Vector2(spot.x - natural.x,
			spot.z - natural.z).length())
	if _x1_site == null:
		return
	var slots: Dictionary = bot.get(&"_slot_building")
	slots.clear()   # a fresh Commander after a quickload
	bot.call(&"_adopt_buildings")
	_check(slots.get(&"X1") == _x1_site, "A3: X1 adopts the Hall standing by the natural hall spot")
	if _h1_site != null:
		_check(slots.get(&"H1") == _h1_site, "A3: H1 keeps its own Hall (closest pairs first)")
	_check(bool(bot.call(&"_row_built", {"id": &"X1", "kind": &"barracks", "pos": Vector3.INF, "builders": 2})),
			"A3: X1 counts as built (no second Hall)")


# ---------------------------------------------------------------- A5

func _a5() -> void:
	var mf: Object = bot.get(&"mapfill_ai")
	if mf == null:
		_check(false, "A5: no mapfill_ai")
		return
	var t := {"kind": &"camp", "name": "Test camp", "pos": Vector3(10, 0, 10), "tier": 1, "strength": 100.0}
	mf.set(&"current_creep", t.duplicate())
	bot.set(&"_now", 500.0)
	bot.set(&"stage", 6)   # Stage.CREEP
	bot.set(&"_sortie", t)
	(bot.get(&"_group") as Array).clear()
	(bot.get(&"_group_ids") as Dictionary).clear()
	bot.call(&"_rule_retreat")
	_check(int(bot.get(&"stage")) == 0, "A5: group lost -> Stage NONE")
	_check((mf.get(&"current_creep") as Dictionary).is_empty(), "A5: current_creep cleared")
	_check(is_equal_approx(float(bot.get(&"_creep_retry_at")), 500.0 + COMMANDER.CREEP_RETRY),
			"A5: _creep_retry_at = now + CREEP_RETRY (%.0f)" % float(bot.get(&"_creep_retry_at")))


# ---------------------------------------------------------------- A2

func _set_group(units: Array) -> void:
	var g: Array = bot.get(&"_group")
	var ids: Dictionary = bot.get(&"_group_ids")
	g.clear()
	ids.clear()
	for u in units:
		g.append(u)
		ids[(u as Unit).get_instance_id()] = true


func _a2() -> void:
	var s0 := _soldiers[0]
	_set_group([s0])
	var far1 := Vector3(-40, 0, 40)
	var far2 := Vector3(-30, 0, 30)
	bot.set(&"_now", 600.0)
	bot.set(&"stage", 4)   # Stage.HUNT
	bot.set(&"_stage_since", 600.0)
	bot.set(&"_hunt_target", null)
	bot.set(&"_hunt_point", far1)
	bot.set(&"_hunt_since", 600.0)
	bot.set(&"_hunt_goal_since", 600.0)
	var ex: Array[Vector3] = [far2]
	bot.set(&"_explore", ex)
	var memory: AIMemory = bot.get(&"memory")
	memory.buildings.clear()
	bot.call(&"_drive_attack")
	_check(bot.get(&"_hunt_point") == far1, "A2: the point is kept before HUNT_TIMEOUT")
	bot.set(&"_now", 600.0 + COMMANDER.HUNT_TIMEOUT + 1.0)
	bot.call(&"_drive_attack")
	_check(bot.get(&"_hunt_point") == far2 and int(bot.get(&"stage")) == 4,
			"A2: an unreached point -> the next explore point (%s)" % str(bot.get(&"_hunt_point")))
	# A building nobody reaches: given up, then never picked again while skipped.
	var pkeep: Node3D = main.keep_of(PLAYER)
	if pkeep == null:
		_check(false, "A2: no player keep")
		return
	memory.see_building(pkeep, 600.0)
	bot.call(&"_hunt", pkeep)
	bot.call(&"_drive_attack")
	_check(bot.get(&"_hunt_target") == pkeep, "A2: hunting the player keep")
	# a member near the building keeps the hunt alive
	var t1 := 700.0 + COMMANDER.HUNT_TIMEOUT + 5.0
	bot.set(&"_now", t1)
	bot.set(&"_hunt_since", 700.0)
	var old_pos := s0.global_position
	s0.global_position = pkeep.global_position + Vector3(6, 0, 0)
	_check(not bool(bot.call(&"_hunt_stuck")) and is_equal_approx(float(bot.get(&"_hunt_since")), t1),
			"A2: a member near the building restarts the clock")
	s0.global_position = old_pos
	bot.set(&"_now", t1 + COMMANDER.HUNT_TIMEOUT + 1.0)
	var ex2: Array[Vector3] = [far1]
	bot.set(&"_explore", ex2)
	bot.call(&"_drive_attack")
	var skipped: Dictionary = bot.get(&"_hunt_skipped")
	_check(skipped.has(pkeep.get_instance_id()), "A2: the unreached keep is remembered as skipped")
	_check(bot.get(&"_hunt_target") != pkeep, "A2: the skipped keep is not hunted again")
	_check(memory.nearest_building(pkeep.global_position, INF, &"", &"", skipped) != pkeep,
			"A2: AIMemory.nearest_building honours skip_ids")
	skipped.clear()
	# Test review: progress (the centre >= 3 m closer than its best) and a fight near the group restart the clock.
	bot.set(&"_hunt_target", null)
	bot.set(&"_hunt_point", far1)
	var centre: Vector3 = bot.call(&"_group_centre")
	var d := Vector2(centre.x - far1.x, centre.z - far1.z).length()
	var t2 := 900.0
	bot.set(&"_now", t2)
	bot.set(&"_hunt_goal_since", t2)
	bot.set(&"_hunt_since", t2 - COMMANDER.HUNT_TIMEOUT - 10.0)
	bot.set(&"_hunt_best_d", d + COMMANDER.HUNT_PROGRESS + 1.0)
	_check(not bool(bot.call(&"_hunt_stuck")) and is_equal_approx(float(bot.get(&"_hunt_since")), t2),
			"A2: a group still closing in (far reachable target) keeps the hunt")
	bot.set(&"_hunt_since", t2 - COMMANDER.HUNT_TIMEOUT - 10.0)
	bot.set(&"_hunt_best_d", d)   # no progress...
	var foe := _soldier(centre + Vector3(5, 0, 0), "shade", PLAYER)
	memory.see_unit(foe, t2)      # ...but defenders hold the group short of it
	_check(not bool(bot.call(&"_hunt_stuck")) and is_equal_approx(float(bot.get(&"_hunt_since")), t2),
			"A2: a fight near the group keeps the hunt")
	# Review round 2: foes seen across a river keep fighter_near true forever: the hard cap drops the goal anyway.
	var cap := COMMANDER.HUNT_CAP_MULT * COMMANDER.HUNT_TIMEOUT
	bot.set(&"_now", t2 + cap - 1.0)
	memory.see_unit(foe, t2 + cap - 1.0)
	_check(not bool(bot.call(&"_hunt_stuck")), "A2: fighter near, no progress: kept before the hard cap")
	bot.set(&"_now", t2 + cap + 1.0)
	memory.see_unit(foe, t2 + cap + 1.0)
	_check(bool(memory.fighter_near(centre, COMMANDER.RETREAT_RADIUS, t2 + cap + 1.0, COMMANDER.FRESH))
			and bool(bot.call(&"_hunt_stuck")), "A2: fighter near, no progress: dropped at the hard cap (%.0f s)" % cap)
	bot.set(&"_now", t2)
	bot.set(&"_hunt_goal_since", t2)
	memory.units.clear()
	foe.queue_free()
	bot.set(&"_hunt_since", t2 - COMMANDER.HUNT_TIMEOUT - 10.0)
	_check(bool(bot.call(&"_hunt_stuck")), "A2: no progress, no fight -> stuck")
	bot.call(&"_clear_group")


# ---------------------------------------------------------------- A4

func _a4() -> void:
	var eco := Economy.for_team(ENEMY)
	eco.add(1000)
	bot.call(&"_scan")
	_check(not bool(bot.call(&"_out_of_crystals")) and bool(bot.call(&"_node_left")), "A4: setup: crystals and a node")
	bot.set(&"all_in", true)
	bot.set(&"_all_in_ok_since", -1.0)
	bot.set(&"_now", 1000.0)
	bot.call(&"_check_all_in")
	_check(bool(bot.get(&"all_in")), "A4: still all-in at once (hold)")
	bot.set(&"_now", 1000.0 + COMMANDER.ALL_IN_OFF_HOLD - 1.0)
	bot.call(&"_check_all_in")
	_check(bool(bot.get(&"all_in")), "A4: still all-in before the 20 s hold")
	bot.set(&"_now", 1000.0 + COMMANDER.ALL_IN_OFF_HOLD + 0.5)
	bot.call(&"_check_all_in")
	_check(not bool(bot.get(&"all_in")), "A4: all-in off after 20 s of mining possible")


# ---------------------------------------------------------------- A6

func _a6() -> void:
	var home: Array[Unit] = []
	home.append_array(_soldiers)
	var leaving: Array[Unit] = bot.call(&"_reserve_split", home.duplicate(), 1)
	_check(leaving.size() == 2, "A6: reserve 1 pop -> 2 of 3 shades leave (%d)" % leaving.size())
	leaving = bot.call(&"_reserve_split", home.duplicate(), 2)
	_check(leaving.size() == 1, "A6: reserve 2 pop -> 1 of 3 leaves (%d)" % leaving.size())
	leaving = bot.call(&"_reserve_split", home.duplicate(), 0)
	_check(leaving.size() == 3, "A6: reserve 0 -> all leave")
	var src := FileAccess.get_file_as_string("res://scripts/ai/commander.gd")
	var i := src.find("func _launch_sortie")
	var body := src.substr(i, src.find("\nfunc ", i + 10) - i)
	_check(body.contains("_reserve_split(home, maxi(0, ai.attack_reserve))") and not body.contains("RESERVE,"),
			"A6: _launch_sortie uses the shared reserve split")


# ---------------------------------------------------------------- A1

func _a1() -> void:
	if _x1_site == null:
		_check(false, "A1: no site from A3")
		return
	bot.set(&"_now", 5000.0)
	bot.call(&"_scan")
	var stalled: Dictionary = bot.get(&"_site_stalled_since")
	stalled.clear()
	_check((bot.call(&"_next_row") as Dictionary).is_empty(), "A1: an unbuilt site blocks the next row")
	# _maintain_sites records a site no builder may walk to (2 workers lost there = unsafe)
	(bot.get(&"_node_losses") as Dictionary)[_x1_site.get_instance_id()] = [4999.0, 4999.5]
	if _h1_site != null:
		(bot.get(&"_node_losses") as Dictionary)[_h1_site.get_instance_id()] = [4999.0, 4999.5]
	bot.call(&"_maintain_sites")
	_check(stalled.has(_x1_site.get_instance_id()), "A1: _maintain_sites notes the unreachable site")
	bot.set(&"_now", 5000.0 + COMMANDER.SITE_STALL_TIME - 1.0)
	_check(not bool(bot.call(&"_site_stalled", _x1_site)), "A1: not stalled before 90 s")
	bot.set(&"_now", 5000.0 + COMMANDER.SITE_STALL_TIME + 1.0)
	_check(bool(bot.call(&"_site_stalled", _x1_site)), "A1: stalled after 90 s")
	for b: Building in bot.get(&"_buildings"):   # the bot's own early H1 site too
		if not b.is_constructed():
			stalled[b.get_instance_id()] = 5000.0
	var row: Dictionary = bot.call(&"_next_row")
	print("     next row with the sites stalled: %s" % str(row.get("id", "none")))
	if row.is_empty():
		for b: Building in bot.get(&"_buildings"):
			print("     own %s constructed=%s stalled=%s" % [b.building_type.id if b.building_type else &"?",
					b.is_constructed(), bot.call(&"_site_stalled", b)])
		for r: Dictionary in bot.get(&"_rows"):
			print("     row %s built=%s trigger=%s" % [r["id"], bot.call(&"_row_built", r), bot.call(&"_row_trigger", r)])
	_check(not row.is_empty(), "A1: stalled sites no longer block _next_row")
	# Test review: a kit site (Forge / Stables, not a row's) holds back only rows that were not already waiting.
	var slots: Dictionary = bot.get(&"_slot_building")
	slots.erase(&"X1")
	stalled.erase(_x1_site.get_instance_id())   # the X1 site now plays an unstalled kit site
	var trig: Dictionary = bot.get(&"_trigger_time")
	trig.clear()
	_check((bot.call(&"_next_row") as Dictionary).is_empty(), "A1: a kit site holds back a row not yet waiting")
	for r: Dictionary in bot.get(&"_rows"):
		trig[r["id"]] = 5000.0
	_check(not (bot.call(&"_next_row") as Dictionary).is_empty(), "A1: a kit site does not starve a waiting row")
	trig.clear()
	slots[&"X1"] = _x1_site
	var mf: Object = bot.get(&"mapfill_ai")
	var on: bool = (bot.ai as AIProfile).map_fill
	(bot.ai as AIProfile).map_fill = false
	_check(bool(bot.call(&"_x1_camp_clear")), "A1: X1 is never held by the camp gate without map-fill creeps")
	(bot.ai as AIProfile).map_fill = on
	stalled.clear()
	(bot.get(&"_node_losses") as Dictionary).clear()
	_a1_mapfill(mf)


## A1 with map fill on (camps): a strong camp on the keep -> natural walk holds X1 (X1_CAMP_WAIT at most) and is the
## first creep target even before X1 stands.
func _a1_mapfill(mf: Object) -> void:
	var camp: Node3D = null
	for n in get_nodes_in_group("neutral_camps"):
		if n is Node3D:
			camp = n
			break
	var mid: Node3D = bot.call(&"_own_node", "mid")
	if camp == null or mid == null or mf == null or not bool(mf.call(&"active")) or not (bot.ai as AIProfile).map_fill:
		_check(false, "A1 map fill: setup (camp %s, natural %s, map fill active %s)" % [camp, mid,
				mf != null and bool(mf.call(&"active"))])
		return
	var block: Dictionary = bot.get(&"_path_block")
	var t0 := 8000.0
	bot.set(&"_now", t0)
	block[mid.get_instance_id()] = [t0, camp]   # the path check's cache: this camp guards the walk
	bot.set(&"_x1_camp_since", -1.0)
	var x1_row := {"id": &"X1", "kind": &"barracks", "pos": Vector3.INF, "builders": 2}
	var strength: float = bot.get(&"own_strength")
	bot.set(&"own_strength", 1.0e6)   # X1's other conditions hold (the crown wardens' EXPAND_STRENGTH rule)
	_check(not bool(bot.call(&"_row_trigger", x1_row)), "A1 map fill: a camp on the natural walk holds the X1 trigger")
	_check(not bool(bot.call(&"_x1_camp_clear")), "A1 map fill: a camp on the natural walk holds X1")
	bot.set(&"_now", t0 + COMMANDER.X1_CAMP_WAIT - 1.0)
	block[mid.get_instance_id()] = [t0 + COMMANDER.X1_CAMP_WAIT - 1.0, camp]
	_check(not bool(bot.call(&"_row_trigger", x1_row)), "A1 map fill: X1 trigger still held at 179 s")
	_check(not bool(bot.call(&"_x1_camp_clear")), "A1 map fill: still held before X1_CAMP_WAIT")
	bot.set(&"_now", t0 + COMMANDER.X1_CAMP_WAIT + 1.0)
	block[mid.get_instance_id()] = [t0 + COMMANDER.X1_CAMP_WAIT + 1.0, camp]
	_check(bool(bot.call(&"_row_trigger", x1_row)), "A1 map fill: X1 triggers at 181 s (no deadlock)")
	_check(bool(bot.call(&"_x1_camp_clear")), "A1 map fill: X1 goes anyway after X1_CAMP_WAIT (no deadlock)")
	bot.set(&"own_strength", strength)
	_check(not bool(bot.call(&"_x1_done")), "A1 map fill: X1 not done (setup)")
	var t: Dictionary = bot.call(&"_blocking_camp_target", 1.0e6)
	_check(t.get("node") == camp, "A1 map fill: _blocking_camp_target picks the natural's camp before X1 (%s)" %
			str(t.get("name", "none")))
	block.erase(mid.get_instance_id())
	bot.set(&"_x1_camp_since", -1.0)


# ---------------------------------------------------------------- A7

func _a7() -> void:
	var s := _soldiers[2]
	bot.call(&"_scan")
	bot.set(&"_fog", null)
	bot.set(&"_now", 7000.0)
	bot.set(&"_scout", s)
	bot.set(&"_scout_wp", 0)
	bot.set(&"_scout_leg_since", 7000.0)
	var path: Array = bot.call(&"_scout_path")
	if path.size() < 2 or s.global_position.distance_to(path[0]) <= COMMANDER.WAYPOINT_REACH:
		_check(false, "A7: setup (scout path %d points)" % path.size())
		return
	bot.call(&"_rule_scout")
	_check(int(bot.get(&"_scout_wp")) == 0, "A7: the leg goes on before SCOUT_LEG_TIME")
	bot.set(&"_now", 7000.0 + COMMANDER.SCOUT_LEG_TIME + 1.0)
	bot.set(&"_fog", null)
	bot.call(&"_rule_scout")
	_check(int(bot.get(&"_scout_wp")) == 1 and is_equal_approx(float(bot.get(&"_scout_leg_since")), 7046.0),
			"A7: fog-less leg over after SCOUT_LEG_TIME (wp %d)" % int(bot.get(&"_scout_wp")))
	bot.set(&"_scout", null)


# ---------------------------------------------------------------- C1

func _c1() -> void:
	bot.call(&"_scan")
	_check(bool(bot.call(&"is_army_unit", _soldiers[0])), "C1: an own soldier is army")
	bot.set(&"_scout", _soldiers[1])
	_check(not bool(bot.call(&"is_army_unit", _soldiers[1])), "C1: the scout is not army")
	bot.set(&"_scout", null)
	var workers: Array = bot.get(&"_workers")
	if not workers.is_empty():
		_check(not bool(bot.call(&"is_army_unit", workers[0])), "C1: a worker is not army")
	var foe := _soldier(Vector3(-50, 0, 50), "shade", PLAYER)
	_check(not bool(bot.call(&"is_army_unit", foe)), "C1: an enemy soldier is not army")
	_check(not bool(bot.call(&"is_army_unit", null)), "C1: null is not army")
