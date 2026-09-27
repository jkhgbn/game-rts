extends SceneTree
## Tasks 7.A1 (Ice bot) + M7.A1 (mission_01 bot profile), scenes/skirmish.tscn.
## Part 1 (only if the skirmish has `enemy_kingdom` and the Ice data exists): a hard Ice bot, profile picked
##   from Torvald's kingdom, S1 moved to 1:00 for speed: it gathers, builds a Frost Hall, a Rime Spire and
##   an Ice Wall beside it, and trains Ice soldiers.
## Part 2 (Shadow skirmish, profile_id mission_01, 5 000 crystals, 12 extra Shades at the rally): it never
##   attacks, keeps <= 4 workers, never trains past 8 soldiers, leaves a "scripted" Shade alone (a normal one
##   at the same spot is walked back), never rebuilds its Gloom Hall once destroyed, Malrik stays home, then
##   follows units given to follow_units().
## Run:  godot --headless --path . -s tests/test_7_a1.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "7.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const SHADOW := 1
const ICE_TIMEOUT := 240.0          # game seconds
const MISSION_TIME := 150.0
const LONER_POS := Vector3(44.0, 0.0, -14.0)   # ~20 m from the Shadow rally (30, -30)

var main: Node
var bot: Node
var part := 0                       # 1 ice, 2 mission
var _wait := 0
var _t := 0.0
var _errors: Array[String] = []
var _skipped := ""
var _tweaked := false
var _gap := 0                       # frames left before part 2 starts (part 1's scene is freed first)

# ice
var _ice := {"gathered": false, "hall": false, "spire": false, "wall": false, "soldier": false}

# mission
var _mission_setup := false
var _scripted: Unit
var _loner: Unit
var _max_workers := 0
var _max_soldiers := 0
var _hall_killed_at := -1.0
var _follow_started := false
var _follow_target: Unit
var _malrik_far := false


func _initialize() -> void:
	var probe: Node = load(SCENE).instantiate()
	var has_kingdom := &"enemy_kingdom" in probe
	probe.free()
	var ice_data := BuildingType.find("ice_barracks") != null and UnitType.find("rimeshield") != null
	if has_kingdom and ice_data:
		_start(1)
	else:
		_skipped = "Ice part skipped (enemy_kingdom %s, Ice data %s)" % [str(has_kingdom), str(ice_data)]
		print(_skipped)
		_start(2)


func _start(p: int) -> void:
	part = p
	_wait = 0
	_tweaked = false
	main = load(SCENE).instantiate()
	if p == 1:
		main.set(&"enemy_kingdom", &"ice")
	bot = null
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == SHADOW:
			bot = child
	if bot == null:
		bot = COMMANDER.new()
		bot.team = SHADOW
		main.add_child(bot)
	bot.debug_log = true
	if p == 1:
		bot.difficulty = 2
		bot.profile = null
		bot.profile_id = &""
	else:
		bot.profile = null
		bot.profile_id = &"mission_01"
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if _gap > 0:
		# the part-1 skirmish is freed first: a new one would otherwise reuse its dying map-fill services
		_gap -= 1
		if _gap == 0:
			_start(2)
		return false
	if main == null or not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_t = main.match_time()
	if part == 1:
		return _ice_tick()
	return _mission_tick()


# ---------------------------------------------------------------- part 1: Ice bot

func _ice_tick() -> bool:
	if not _tweaked and bot.get(&"_ready_done"):
		_tweaked = true
		if bot.ai.profile_id != &"ice_default":
			_errors.append("Ice bot picked profile %s, not ice_default" % bot.ai.profile_id)
		if not bot.ai.build_walls:
			_errors.append("hard Ice profile has no walls")
		bot.ai.tower1_time = 60.0
		print("Ice bot profile %s (%s)" % [bot.ai.id, bot.ai.profile_id])
	var eco := Economy.for_team(SHADOW)
	if eco and eco.gathered_total > 0:
		_ice["gathered"] = true
	for node in get_nodes_in_group("buildings"):
		var b := node as Building
		if b == null or int(b.team) != SHADOW or b.building_type == null:
			continue
		if b.building_type.id == &"ice_barracks" and b.is_constructed():
			_ice["hall"] = true
		if b.building_type.id == &"ice_tower":
			_ice["spire"] = true
		if b.building_type.kind == &"wall":
			_ice["wall"] = true
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u and int(u.team) == SHADOW and u.unit_type and u.unit_type.faction == &"ice" \
				and not u.unit_type.is_worker and not u is Wizard:
			_ice["soldier"] = true
	var all_ok := true
	for k in _ice:
		all_ok = all_ok and bool(_ice[k])
	if all_ok or _t > ICE_TIMEOUT or main.game_over:
		print("Ice bot at %.0f s: %s" % [_t, str(_ice)])
		for line in bot.log_lines:
			if line.contains("PLACE") or line.contains("WALL") or line.contains("START"):
				print(line)
		for k in _ice:
			if not bool(_ice[k]):
				_errors.append("Ice bot: no %s by %.0f s" % [k, _t])
		main.queue_free()
		main = null
		_gap = 3
	return false


# ---------------------------------------------------------------- part 2: mission_01 profile

func _mission_tick() -> bool:
	if not _mission_setup:
		_mission_setup = true
		if bot.ai.profile_id != &"mission_01":
			_errors.append("profile_id mission_01 gave %s" % bot.ai.profile_id)
		Economy.for_team(SHADOW).add(5000)
		for i in 12:
			var s: Unit = main.make_unit("shade")
			s.team = SHADOW
			main.add_child(s)
			s.global_position = Vector3(30.0 + (i % 4) * 1.5, 0.0, -30.0 + (i / 4) * 1.5)
		_scripted = main.make_unit("shade")
		_scripted.team = SHADOW
		_scripted.add_to_group(&"scripted")
		main.add_child(_scripted)
		_scripted.global_position = LONER_POS
		_loner = main.make_unit("shade")
		_loner.team = SHADOW
		main.add_child(_loner)
		_loner.global_position = LONER_POS + Vector3(0.0, 0.0, 3.0)
	if bot.attacks_launched > 0 or bot.stage != 0:
		_errors.append("mission bot attacked at %.0f s" % _t)
		return _finish()
	var workers := 0
	var soldiers := 0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != SHADOW or u is Wizard or u.is_in_group(&"scripted"):
			continue
		if u is Worker:
			workers += 1
		else:
			soldiers += 1
	_max_workers = maxi(_max_workers, workers)
	_max_soldiers = maxi(_max_soldiers, soldiers)
	# Once the Gloom Hall stands, destroy it: it must never come back.
	var hall: Building = null
	for node in get_nodes_in_group("buildings"):
		var b := node as Building
		if b and b.is_alive() and int(b.team) == SHADOW and b.building_type and b.building_type.kind == &"barracks":
			hall = b
	if hall and _hall_killed_at < 0.0 and hall.is_constructed():
		_hall_killed_at = _t
		hall.take_damage(1.0e7, null)
		print("Gloom Hall destroyed at %.0f s" % _t)
	elif hall and _hall_killed_at >= 0.0:
		_errors.append("the mission bot rebuilt its Gloom Hall at %.0f s" % _t)
		return _finish()
	var malrik: Unit = main.wizard_of(SHADOW)
	# Malrik stays home, then follows the units handed to follow_units().
	if not _follow_started and _t >= MISSION_TIME - 40.0:
		_follow_started = true
		_follow_target = main.make_unit("shade")
		_follow_target.team = SHADOW
		_follow_target.add_to_group(&"scripted")
		main.add_child(_follow_target)
		_follow_target.global_position = Vector3(20.0, 0.0, -20.0)
		bot.follow_units([_follow_target])
	if malrik and malrik.is_alive() and not _follow_started \
			and Vector2(malrik.global_position.x - 36.0, malrik.global_position.z + 36.0).length() > 16.0:
		_malrik_far = true
	if _follow_target:
		_follow_target.global_position = Vector3(20.0, 0.0, -20.0)
	if _t >= MISSION_TIME or main.game_over:
		return _finish()
	return false


func _finish() -> bool:
	if part == 2:
		if _max_workers > 4:
			_errors.append("mission bot had %d workers (max 4)" % _max_workers)
		if _max_soldiers > 13:
			_errors.append("mission bot trained past its 8-soldier cap (%d soldiers, 13 given)" % _max_soldiers)
		if _hall_killed_at < 0.0:
			_errors.append("the mission bot never finished its Gloom Hall")
		if is_instance_valid(_scripted) and _scripted.is_alive():
			var moved := Vector2(_scripted.global_position.x - LONER_POS.x, _scripted.global_position.z - LONER_POS.z).length()
			print("scripted Shade moved %.1f m" % moved)
			if moved > 2.0:
				_errors.append("the scripted Shade was moved %.1f m" % moved)
		if is_instance_valid(_loner) and _loner.is_alive():
			var d := Vector2(_loner.global_position.x - 30.0, _loner.global_position.z + 30.0).length()
			print("normal Shade is %.1f m from the rally" % d)
			if d > 12.0:
				_errors.append("the normal Shade was not walked back to the rally (control failed)")
		if _malrik_far:
			_errors.append("Malrik left his anchor before follow_units()")
		var malrik: Unit = main.wizard_of(SHADOW)
		if malrik and malrik.is_alive():
			var d2 := Vector2(malrik.global_position.x - 20.0, malrik.global_position.z + 20.0).length()
			print("Malrik is %.1f m from the followed unit" % d2)
			if d2 > 10.0:
				_errors.append("Malrik did not follow the units (%.1f m away)" % d2)
		print("mission bot: max workers %d, max soldiers %d, attacks %d" % [_max_workers, _max_soldiers,
				bot.attacks_launched])
	if _errors.is_empty():
		print("PASS %s%s" % [TASK_ID, (" (" + _skipped + ")") if _skipped != "" else ""])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
