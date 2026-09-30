extends SceneTree
## Task 2.S3: the 1v1 map "Crown Hollow" (docs/design/skirmish-1v1.md), scenes/skirmish.tscn.
## Round A: mirrored start (keeps, 3 + 3 gathering workers, 250 crystals, 3 / 20 pop, 8 nodes of 2000 / 2000 / 2500 / 2500 (balance-1),
## mirrored obstacles, 4 neutral wardens), the crown (+100 HP / +50 mana, dropped 3 s after the
## wearer's death at the death spot), Vessa respawns at the keep after 30 s (then 45 s), Malrik
## heals near his keep, a worker on node_fire_mid delivers at an Ember Hall at (-23, 9), a keep
## trains a worker (stat), destroying every Shadow building -> victory.
## Round B: one F10 does nothing (and expires after 3 s); destroying every Fire building -> defeat.
## Round C: F10 twice -> defeat (surrender).
## Run:  godot --headless --path . -s tests/test_2_s3.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "2.S3"
const TIMEOUT_FRAMES := 8500
const SCENE := "res://scenes/skirmish.tscn"
const SETUP := 5

var main: Node
var total := 0
var frame := 0          # frames since the current round's map was ready
var _wait := 0
var round_id := "A"
var _between := 0       # frames left before the next round's scene is created
var _errors: Array[String] = []
var _log: Array[String] = []
var _ended: Array = []  # Events.mission_ended values of the current round

# round A
var _death_frame := -1
var _death_pos := Vector3.ZERO
var _crown_worn := false
var _crown_dropped := false
var _respawned := false
var _second_death := false
var _hall: Node
var _mid_worker: Node
var _last_carried := 0
var _dropoff_ok := false
var _malrik_hp0 := 0.0
var _heal_ok := false
var _won := false
var _destroy_frame := -1


func _initialize() -> void:
	var events := root.get_node_or_null("Events")
	if events:
		events.mission_ended.connect(func(v: bool) -> void: _ended.append(v))
	_load()


func _load() -> void:
	main = load(SCENE).instantiate()
	# This test checks the map rules alone: switch the Shadow bot off (it would build and fight).
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	frame = 0
	_wait = 0
	_ended.clear()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES:
		_errors.append("timed out in round %s (frame %d)" % [round_id, frame])
		return _finish()
	if _between > 0:
		_between -= 1
		if _between == 0:
			_load()
		return false
	if main == null or main.hero == null:
		_wait += 1
		if _wait > 3000:
			_errors.append("round %s: navigation never finished baking" % round_id)
			return _finish()
		return false
	frame += 1
	match round_id:
		"A":
			_round_a()
		"B":
			_round_b()
		"C":
			_round_c()
		_:
			return _finish()
	if not _errors.is_empty():
		return _finish()
	return false


func _next_round(id: String) -> void:
	_log.append("round %s done at frame %d (total %d)" % [round_id, frame, total])
	round_id = id
	if id == "done":
		return
	main.queue_free()
	main = null
	_between = 3


# ---------------------------------------------------------------- round A

func _round_a() -> void:
	if frame == SETUP:
		_check_start()
		_start_crown_and_dropoff()
		return
	if frame < SETUP:
		return
	var hero: Unit = main.hero
	var crown: Node = main.crown
	# The crown is worn one frame after Vessa stands on it.
	if not _crown_worn and crown.wearer == hero:
		_crown_worn = true
		# Crown +100 HP / +50 mana on Vessa's 350 / 100, then her STR / INT path percent (auto-picked at 0:00 in
		# headless skirmishes; Fire picks INT: +25 % max mana -> 187.5).
		var want_hp := 450.0 * _hp_mult(hero)
		var want_mana := 150.0 * _mana_mult(hero)
		if not is_equal_approx(hero.max_hp, want_hp) or not is_equal_approx(hero.hp, want_hp) \
				or not is_equal_approx(hero.max_mana, want_mana):
			_errors.append("crown bonus: hp %.0f / %.0f mana max %.1f, want %.0f / %.0f, %.1f (path %s)" % [
					hero.hp, hero.max_hp, hero.max_mana, want_hp, want_hp, want_mana, _path(hero)])
		if not String(main.hud._objective.text).contains("worn by Vessa"):
			_errors.append("objective line: %s" % main.hud._objective.text)
	if frame == SETUP + 10:
		if not _crown_worn:
			_errors.append("Vessa at the crown did not take it (wearer %s)" % crown.wearer)
			return
		_death_pos = hero.global_position
		hero.take_damage(1.0e6, null)
		_death_frame = frame
		if hero.is_alive() or not is_equal_approx(main.respawn_time_left(0), 30.0):
			_errors.append("after death: alive %s, respawn in %.2f (want 30)" % [hero.is_alive(), main.respawn_time_left(0)])
		if not is_equal_approx(hero.max_hp, 350.0 * _hp_mult(hero)) or crown.is_available() or crown.wearer != null:
			_errors.append("death: max_hp %.0f, crown available %s" % [hero.max_hp, crown.is_available()])
	if _death_frame > 0 and not _crown_dropped:
		var t: int = frame - _death_frame
		if crown.is_available():
			_crown_dropped = true
			var d := _flat(crown.global_position, _death_pos)
			_log.append("crown dropped %.2f s after the death, %.2f m from the death spot" % [t / 60.0, d])
			if absf(t / 60.0 - 3.0) > 0.1 or d > 1.5:
				_errors.append("crown drop after %.2f s at %.2f m" % [t / 60.0, d])
			if not String(main.hud._objective.text).contains("unclaimed"):
				_errors.append("objective after the drop: %s" % main.hud._objective.text)
	if _death_frame > 0 and not _respawned:
		var t2: int = frame - _death_frame
		if t2 == 30 * 60 - 20 and hero.is_alive():
			_errors.append("Vessa is back before 30 s")
		if hero.is_alive():
			_respawned = true
			var spot: Vector3 = main.keep.spawn_point()
			_log.append("Vessa back after %.2f s at %s (keep spawn %s), hp %.0f" % [t2 / 60.0, hero.global_position, spot, hero.hp])
			if absf(t2 / 60.0 - 30.0) > 0.1 or _flat(hero.global_position, spot) > 1.5 \
					or not is_equal_approx(hero.hp, 350.0 * _hp_mult(hero)) \
					or not is_equal_approx(hero.max_hp, 350.0 * _hp_mult(hero)):
				_errors.append("respawn after %.2f s, %.2f m from the keep spawn point, hp %.0f / %.0f" % [
						t2 / 60.0, _flat(hero.global_position, spot), hero.hp, hero.max_hp])
			if not main.selection.selected.has(hero):
				_errors.append("the respawned wizard is not selected")
	if _respawned and not _second_death and frame - _death_frame > 30 * 60 + 10:
		_second_death = true
		hero.take_damage(1.0e6, null)
		if not is_equal_approx(main.respawn_time_left(0), 45.0):
			_errors.append("second death: respawn in %.2f, want 45" % main.respawn_time_left(0))
	# Malrik heals 1 % / s near his keep (4 hp / s).
	if frame == SETUP + 60:
		var malrik: Unit = main.shadow_hero
		malrik.hp = 200.0
		_malrik_hp0 = malrik.hp
	if frame == SETUP + 60 + 300:
		var gained: float = main.shadow_hero.hp - _malrik_hp0
		_log.append("Malrik healed %.1f hp in 5 s near his keep" % gained)
		# 1 % of max HP per second: 400 -> 20 in 5 s; with a STR path (+20 % max HP, Shadow's auto-pick) 480 -> 24.
		var want_heal: float = 0.05 * main.shadow_hero.max_hp
		if absf(gained - want_heal) > 1.0:
			_errors.append("home healing: +%.1f in 5 s, want %.1f (1 %% of %.0f max HP per s)" % [gained, want_heal,
					main.shadow_hero.max_hp])
		_heal_ok = true
	_track_dropoff()
	if not _won and _second_death and _dropoff_ok and _heal_ok and _destroy_frame < 0:
		var s: Dictionary = main.stats_of(0)
		if s["trained"] != 1 or s["lost"] < 2 or s["gathered"] <= 0:
			_errors.append("stats before the end: %s" % s)
		for b in Building.for_team(Unit.Team.ENEMY):
			b.take_damage(1.0e9, null)
		_destroy_frame = frame
	if _destroy_frame > 0 and not _won:
		if main.game_over:
			_won = true
			var s2: Dictionary = main.stats_of(0)
			_log.append("victory after %d frames; end screen:\n%s" % [frame - _destroy_frame, main.end_screen_text()])
			if main.winner_team != Unit.Team.PLAYER or _ended != [true] or s2["buildings_destroyed"] != 1:
				_errors.append("win: winner %d, mission_ended %s, stats %s" % [main.winner_team, _ended, s2])
			_next_round("B")
		elif frame - _destroy_frame > 60:
			_errors.append("no victory 1 s after every Shadow building fell")


## The wizard's STR / INT path (level-boons.md 14; "" in missions or when the feature is off).
func _path(w: Node) -> StringName:
	var p := StrIntPath.of(w)
	return p.path if p != null else &""


func _hp_mult(w: Node) -> float:
	return 1.0 + float(StrIntPath.STR_STATS["max_hp_pct"]) if _path(w) == StrIntPath.PATH_STR else 1.0


func _mana_mult(w: Node) -> float:
	return 1.0 + float(StrIntPath.INT_STATS["max_mana_pct"]) if _path(w) == StrIntPath.PATH_INT else 1.0


func _check_start() -> void:
	var k: Node = main.keep
	var sk: Node = main.shadow_keep
	if k == null or sk == null or k.building_type.id != &"fire_keep" or sk.building_type.id != &"shadow_keep" \
			or _flat(k.global_position, Vector3(-43, 0, 43)) > 0.01 or _flat(sk.global_position, Vector3(43, 0, -43)) > 0.01 \
			or not k.is_constructed() or not sk.is_constructed() or sk.team != Unit.Team.ENEMY:
		_errors.append("keeps wrong")
	for team in [0, 1]:
		var eco := Economy.for_team(team)
		if eco == null or eco.crystals != 250 or eco.pop_used != 3 or eco.pop_cap != 20:
			_errors.append("team %d economy: %s" % [team, [eco.crystals, eco.pop_used, eco.pop_cap] if eco else "none"])
		var gathering := 0
		for u in get_nodes_in_group("units"):
			if u.team == team and u.has_method("command_gather") and u.is_gathering():
				gathering += 1
		if gathering != 3 or main.workers_of(team).size() != 3:
			_errors.append("team %d: %d gathering workers" % [team, gathering])
		if Building.for_team(team).size() != 1:
			_errors.append("team %d starts with %d buildings" % [team, Building.for_team(team).size()])
	if _flat(main.hero.global_position, Vector3(-36, 0, 36)) > 0.5 \
			or _flat(main.shadow_hero.global_position, Vector3(36, 0, -36)) > 0.5:
		_errors.append("wizards not at their starts")
	var want := {&"node_fire_a": Vector3(-46, 0, 34), &"node_fire_b": Vector3(-34, 0, 46), &"node_fire_mid": Vector3(-16, 0, 6),
			&"node_shadow_a": Vector3(46, 0, -34), &"node_shadow_b": Vector3(34, 0, -46), &"node_shadow_mid": Vector3(16, 0, -6),
			&"node_fire_rich": Vector3(-40, 0, -40), &"node_shadow_rich": Vector3(40, 0, 40)}
	# Balance-1 (2a): 8 nodes, 2 000 / 2 000 / 2 500 (mid) / 2 500 (contested rich) per side.
	var amounts := {&"a": 2000, &"b": 2000, &"mid": 2500, &"rich": 2500}
	if main.crystal_nodes.size() != 8:
		_errors.append("%d crystal nodes" % main.crystal_nodes.size())
	for id in want:
		var n: Node3D = main.crystal_nodes.get(id)
		if n == null or _flat(n.global_position, want[id]) > 0.01 \
				or n.crystals_left != int(amounts[StringName(String(id).get_slice("_", 2))]):
			_errors.append("node %s wrong" % id)
	# Every tree, rock and pillar has a mirror at (-x, -z).
	var obstacles: Array[Vector3] = []
	for child in main.nav_region.get_children():
		if child is StaticBody3D and not child is Building and not child is CrystalNode \
				and child.global_position.length() > 0.01:
			obstacles.append(child.global_position)
	var unmatched := 0
	for p in obstacles:
		var found := false
		for q in obstacles:
			if _flat(p, -q) < 0.01:
				found = true
				break
		if not found:
			unmatched += 1
	_log.append("%d obstacles (trees, rocks, pillars), %d without a mirror" % [obstacles.size(), unmatched])
	if unmatched > 0 or obstacles.size() < 40:
		_errors.append("%d obstacles, %d not mirrored" % [obstacles.size(), unmatched])
	# 4 neutral wardens around the crown, radius 4.
	var wardens := 0
	for u in get_nodes_in_group("units"):
		if u.team == Unit.Team.NEUTRAL and absf(_flat(u.global_position, Vector3.ZERO) - 4.0) < 0.3:
			wardens += 1
	if wardens != 4 or main.wardens.size() != 4:
		_errors.append("%d neutral wardens at the crown" % wardens)
	if main.crown == null or not main.crown.is_available() or _flat(main.crown.global_position, Vector3.ZERO) > 0.01:
		_errors.append("the crown is not at (0, 0)")
	# Helpers.
	if main.base_center(1) != Vector3(43, 0, -43) or main.home_nodes(1).size() != 2 \
			or main.natural_node(1) != main.crystal_nodes[&"node_shadow_mid"] or main.natural_hall_spot(1) != Vector3(23, 0, -9):
		_errors.append("helpers base_center / home_nodes / natural_node / natural_hall_spot")


func _start_crown_and_dropoff() -> void:
	# Vessa steps on the crown (balance-1: sealed until 6:00 of match time; the seal has its own
	# test, test_6_b2, so this one starts past it).
	main.crown.seal_time = 0.0
	main.hero.global_position = Vector3(0, 0, 1.0)
	main.hero.command_stop()
	# The keep trains one worker (end-screen stat).
	var r: String = main.keep.queue_unit(UnitType.find("cinder_hand"))
	if r != "":
		_errors.append("keep refused a worker: %s" % r)
	# An Ember Hall at the spec's spot next to node_fire_mid, and a worker sent to that node.
	var hall_t := BuildingType.find("fire_barracks")
	var spot: Vector3 = main.build_grid.snap(Vector3(-23, 0, 9), hall_t.footprint)
	var reason: String = main.build_grid.check(hall_t, spot, 0)
	if reason != "" or spot != Vector3(-23, 0, 9):
		_errors.append("Ember Hall at (-23, 9): '%s' (snapped %s)" % [reason, spot])
	_hall = main.build_grid.spawn_complete(hall_t, spot, 0)
	main.build_grid.request_rebake()
	if not _hall.is_drop_off() or main.keep.is_drop_off() != true:
		_errors.append("is_drop_off: hall %s keep %s" % [_hall.is_drop_off(), main.keep.is_drop_off()])
	var workers: Array = main.workers_of(0)
	_mid_worker = workers[2]
	_mid_worker.command_gather(main.natural_node(0))


func _track_dropoff() -> void:
	if _dropoff_ok or _mid_worker == null or not is_instance_valid(_mid_worker):
		return
	var c: int = _mid_worker.carried
	if _last_carried > 0 and c == 0:
		var at: Vector3 = _mid_worker.global_position
		var d_hall := _flat(at, _hall.drop_off_point())
		var d_keep := _flat(at, main.keep.drop_off_point())
		_log.append("mid worker delivered at %s: %.2f m from the hall drop-off, %.1f m from the keep's (frame %d)" % [at, d_hall, d_keep, frame])
		if d_hall > 2.5:
			_errors.append("the worker on node_fire_mid delivered %.2f m from the hall, %.1f m from the keep" % [d_hall, d_keep])
		_dropoff_ok = true
	_last_carried = c


# ---------------------------------------------------------------- rounds B and C

func _round_b() -> void:
	if frame == SETUP:
		_press_f10()
		if main.game_over:
			_errors.append("one F10 surrendered")
	if frame == SETUP + 240:   # 4 s later the first press has expired
		_press_f10()
	if frame == SETUP + 250:
		if main.game_over:
			_errors.append("two F10 presses 4 s apart surrendered")
		for b in Building.for_team(Unit.Team.PLAYER):
			b.take_damage(1.0e9, null)
	if frame > SETUP + 250 and main.game_over:
		if main.winner_team != Unit.Team.ENEMY or _ended != [false]:
			_errors.append("defeat: winner %d, mission_ended %s" % [main.winner_team, _ended])
		_log.append("defeat %d frames after the Fire buildings fell" % (frame - SETUP - 250))
		_next_round("C")
	elif frame > SETUP + 320:
		_errors.append("no defeat 1 s after every Fire building fell")


func _round_c() -> void:
	if frame == SETUP:
		_press_f10()
	if frame == SETUP + 60:
		_press_f10()
	if frame == SETUP + 62:
		if not main.game_over or main.winner_team != Unit.Team.ENEMY or _ended != [false]:
			_errors.append("F10 twice: game_over %s winner %d mission_ended %s" % [main.game_over, main.winner_team, _ended])
		_next_round("done")


func _press_f10() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F10
	ev.keycode = KEY_F10
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


# ---------------------------------------------------------------- helpers

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	for line in _log:
		print("  ", line)
	if _errors.is_empty() and round_id == "done":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true
