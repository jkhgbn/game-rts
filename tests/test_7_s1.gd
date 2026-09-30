extends SceneTree
## Tasks 7.S1 + 7.S2 (docs/design/kingdom-ice.md section 5, 2.4): the 5 Ice BuildingTypes with the spec
## numbers, Ice workers' build menu (Z X C V), the Ice skirmish (enemy_kingdom = &"ice": Rime Keep,
## 3 workers, Torvald), a Rime Spire hit chills 2 s, the 17th Ice Wall is refused with
## "Wall limit reached", and a side with only walls left loses.
## Run:  godot --headless --path . -s tests/test_7_s1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "7.S1"
const TIMEOUT_FRAMES := 2400
const SCENE := "res://scenes/skirmish.tscn"
const SETUP := 5
const TOWER_POS := Vector3(11.0, 0.0, -21.0)
const SPY_POS := Vector3(15.0, 0.0, -21.0)

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _spy: Unit   # a Flame Guard in the Rime Spire's range
var _tower: Node
var _chilled := false
var _kill_frame := -1


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.set("enemy_kingdom", &"ice")
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == SETUP:
		_check_types()
		_check_start()
		_check_wall_limit()
		_setup_spire()
	elif frame > SETUP and _kill_frame < 0:
		if _spy and _spy.has_status(&"chill"):
			_chilled = true
			var left := _spy.status_time_left(&"chill")
			if left < 1.9 or left > 2.0 + 0.001:
				_errors.append("Rime Spire chill lasts %.2f s, not 2" % left)
			_kill_all_but_walls()
	elif _kill_frame > 0 and frame >= _kill_frame + 60:
		if int(main.winner_team) != Unit.Team.PLAYER:
			_errors.append("Ice has only walls left but did not lose (winner %d)" % int(main.winner_team))
		if Building.for_team(Unit.Team.ENEMY).size() != 16:
			_errors.append("expected the 16 walls alive, got %d buildings" % Building.for_team(Unit.Team.ENEMY).size())
		return _finish()
	if not _errors.is_empty():
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (chilled=%s)" % _chilled)
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


# ---------------------------------------------------------------- data

func _check_types() -> void:
	# id: [cost, build_time, max_hp, footprint, height, pop_bonus, max_count, hotkey]
	var spec := {
		&"ice_keep": [0, 0.0, 3000.0, Vector2i(3, 3), 6.0, 20, 0, ""],
		&"ice_barracks": [150, 54.0, 1560.0, Vector2i(3, 3), 4.0, 0, 0, "X"],
		&"ice_lodge": [80, 30.0, 600.0, Vector2i(2, 2), 3.0, 20, 9, "Z"],   # pop-200 rule (economy.md 2026-09-27): +20, max 9
		&"ice_tower": [130, 42.0, 900.0, Vector2i(1, 1), 5.0, 0, 4, "C"],
		&"ice_wall": [20, 8.0, 500.0, Vector2i(1, 1), 2.5, 0, 16, "V"],
	}
	for id: StringName in spec:
		var t := BuildingType.find(String(id))
		if t == null:
			_errors.append("no BuildingType %s" % id)
			continue
		var s: Array = spec[id]
		var got := [t.cost, t.build_time, t.max_hp, t.footprint, t.height, t.pop_bonus, t.max_count, t.hotkey_label]
		if str(got) != str(s):
			_errors.append("%s is %s, spec %s" % [id, str(got), str(s)])
		if t.faction != &"ice":
			_errors.append("%s faction %s" % [id, t.faction])
		if t.counts_for_defeat != (id != &"ice_wall"):
			_errors.append("%s counts_for_defeat = %s" % [id, t.counts_for_defeat])
	var spire := BuildingType.find("ice_tower")
	if spire and (spire.attack_damage != 12.0 or spire.attack_range != 11.0 or spire.attack_cooldown != 1.5 \
			or spire.sight_radius != 16.0 or spire.on_hit_status != &"chill" or spire.on_hit_duration != 2.0):
		_errors.append("Rime Spire attack / chill numbers differ from the spec")
	var wall := BuildingType.find("ice_wall")
	if wall and wall.sight_radius != 4.0:
		_errors.append("Ice Wall sight %.1f" % wall.sight_radius)
	# Step 10: the Bazaar (kind market) joins every build menu while trade is on; it is not part of this check.
	# docs/design/stables.md: the kingdom's Stables (key N) comes last in skirmish games (Stables16.enabled_here()).
	var stables_on := Stables16.enabled_here()
	var ids: Array[StringName] = []
	for t in BuildingType.buildable_for(&"ice"):
		if t.kind != &"market":
			ids.append(t.id)
	var want_ice: Array[StringName] = [&"ice_lodge", &"ice_barracks", &"ice_tower", &"ice_wall"]
	if stables_on:
		want_ice.append(&"ice_stables")
	if ids != want_ice:
		_errors.append("Ice build menu is %s, want %s" % [str(ids), str(want_ice)])
	var core := func(t: BuildingType) -> bool: return t.kind != &"market" and t.kind != &"stables"
	var fire_n := BuildingType.buildable_for(&"fire").filter(core).size()
	var shadow_n := BuildingType.buildable_for(&"shadow").filter(core).size()
	var fire_st := BuildingType.buildable_for(&"fire").filter(func(t: BuildingType) -> bool: return t.kind == &"stables").size()
	if fire_n != 3 or shadow_n != 3 or fire_st != (1 if stables_on else 0):
		_errors.append("Fire / Shadow build menus changed (%d / %d core, %d stables)" % [fire_n, shadow_n, fire_st])
	# Frost Hall trains the 4 Ice soldiers once their UnitTypes exist (7.G2).
	var hall := BuildingType.find("ice_barracks")
	if hall and UnitType.find("rimeshield") != null and hall.trains.size() != 4:
		_errors.append("Frost Hall trains %d types" % hall.trains.size())


# ---------------------------------------------------------------- skirmish start

func _check_start() -> void:
	var k: Node = main.shadow_keep
	if k == null or k.building_type == null or k.building_type.id != &"ice_keep":
		_errors.append("the Ice bot's keep is not a Rime Keep")
	elif not is_equal_approx(k.max_hp, 3000.0):
		_errors.append("Rime Keep has %.0f HP" % k.max_hp)
	var wiz: Node = main.shadow_hero
	if wiz == null or wiz.get(&"kingdom") != &"ice" or not String(wiz.get(&"unit_name")).begins_with("Torvald"):
		_errors.append("the Ice bot's wizard is not Torvald (%s)" % (wiz.get(&"unit_name") if wiz else "none"))
	var workers: Array = main.workers_of(Unit.Team.ENEMY)
	if workers.size() != 3:
		_errors.append("the Ice bot has %d workers" % workers.size())
	elif UnitType.find("rime_hauler") != null:
		for w: Unit in workers:
			if w.unit_type == null or w.unit_type.id != &"rime_hauler":
				_errors.append("an Ice worker is not a Rime Hauler")
				break
	var fire_keep: Node = main.keep
	if fire_keep == null or fire_keep.building_type.id != &"fire_keep":
		_errors.append("the player's keep is not the Fire keep")
	if not String(main.call(&"_objective_text")).contains("every Ice building"):
		_errors.append("objective text does not name Ice")


func _check_wall_limit() -> void:
	var grid: BuildGrid = main.build_grid
	var wall := BuildingType.find("ice_wall")
	Economy.for_team(Unit.Team.ENEMY).add(1000)
	# A free 1 x 1 spot near the Ice base (a tower spot is a wall spot: same footprint).
	var spot := grid.find_spot(BuildingType.find("ice_tower"), main.base_center(Unit.Team.ENEMY) + Vector3(-8, 0, 8),
			Unit.Team.ENEMY)
	if spot == Vector3.INF:
		_errors.append("no free spot for a wall")
		return
	for i in 15:
		grid.spawn_complete(wall, Vector3(-15.0 + i * 2.0, 0.0, 55.0), Unit.Team.ENEMY)
	var r15 := grid.check(wall, spot, Unit.Team.ENEMY)
	if r15 != "":
		_errors.append("16th wall refused: %s" % r15)
	grid.spawn_complete(wall, Vector3(15.0, 0.0, 55.0), Unit.Team.ENEMY)
	var r16 := grid.check(wall, spot, Unit.Team.ENEMY)
	if r16 != "Wall limit reached":
		_errors.append("17th wall: '%s'" % r16)


# ---------------------------------------------------------------- Rime Spire chill + defeat

func _setup_spire() -> void:
	_tower = main.build_grid.spawn_complete(BuildingType.find("ice_tower"), TOWER_POS, Unit.Team.ENEMY)
	_spy = main.make_unit("flame_guard")
	_spy.team = Unit.Team.PLAYER
	main.add_child(_spy)
	_spy.global_position = SPY_POS
	_spy.command_stop()


func _kill_all_but_walls() -> void:
	for b in Building.for_team(Unit.Team.ENEMY):
		if b.building_type.id != &"ice_wall":
			b.take_damage(1.0e7, null)
	_kill_frame = frame
