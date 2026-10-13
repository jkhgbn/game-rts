extends SceneTree
## Fix batch F3b (code review 2026-10-12), buildings / economy:
##  R4-1  a soldier saved with Forge upgrades gets them back after a load (modifier + range, the range once);
##  max_hp a script set on a building survives a save / load round trip;
##  R4-3  a queued helper Call stub is rebuilt after a load; a code-built stub nobody rebuilds is refunded;
##  R4-7  TierSystem.set_tier during a keep upgrade cancels it with a full refund (the tier never drops later);
##  C1-5  a branched story film marks its main id seen too (StoryFilms.seen_ids).
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_f3b_buildings.gd --fixed-fps 60 --quit-after 9000
## Prints "PASS f3b_buildings" or "FAIL f3b_buildings: <reasons>".

const TASK_ID := "f3b_buildings"
const TEST_PATH := "user://saves/_test_f3b_buildings.save"
const PLAYER := 0
const FAKE_STUB_ID := &"f3b_fake_stub"
const FAKE_COST := 120
const MAX_HP_OVERRIDE := 4321.0

var errors: Array[String] = []
var level: Node
var step := "start"
var frames := 0
var total := 0
var data: Dictionary = {}
var restorer_done := false
var archer_base_range := 0.0
var crystals_at_save := 0
var had_call_stub := false
var bakes_seen := 0
var depleted_node: Node = null


func _initialize() -> void:
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	total += 1
	frames += 1
	if total > 8000:
		_fail("timed out at step %s" % step)
		return _finish()
	match step:
		"start":
			if level.get(&"hero") != null and bool(level.get(&"match_started")):
				_bots_off()
				_setup()
				_goto("settle")
		"settle":
			if frames >= 4:
				_check_before_save()
				_save()
				_goto("reload")
		"reload":
			_reload_from(data)
			_goto("wait")
		"wait":
			if restorer_done:
				_bots_off()
				_check_after_load()
				_goto("bake_idle")
		"bake_idle":
			var g: BuildGrid = level.get(&"build_grid")
			if not g.is_rebaking() and frames >= 10:
				_deplete_setup()
				_goto("deplete")
			elif frames > 1200:
				_fail("R4-6: the load rebake never finished")
				_goto("deplete")
		"deplete":
			if bakes_seen > 0 or frames > 240:
				if bakes_seen == 0:
					_fail("R4-6: no navmesh rebake after a crystal node was depleted")
				if is_instance_valid(depleted_node) and depleted_node.is_inside_tree():
					_fail("R4-6: the depleted node is still in the tree")
				_tier_setup()
				_goto("tier")
		"tier":
			if frames >= 3:
				_tier_check()
				_film_check()
				_gold_refund_check()
				_seat_switch_setup()
				_goto("seat")
		"seat":
			if frames >= 3:
				_seat_switch_check()
				_goto("seat_free")
		"seat_free":
			if frames >= 2:
				_seat_free_check()
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


func _setup() -> void:
	var keep: Keep = level.get(&"keep")
	# workers stand still: no crystal income between the save and the checks
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == PLAYER and u.has_method("command_gather"):
			u.command_stop()
	# R4-1: Forge levels + a soldier they touch
	var forge := ForgeKit.for_team(PLAYER)
	forge.set_level(&"weapons", 1)
	forge.set_level(&"fire_bowstrings", 1)
	var archer_type := UnitType.find("ember_archer")
	archer_base_range = archer_type.attack_range
	var archer := Worker.make_unit(archer_type)
	archer.team = Unit.Team.PLAYER
	level.add_child(archer)
	archer.global_position = keep.global_position + Vector3(6.0, 0.0, -6.0)
	archer.command_hold()
	# max_hp override (a mission tollgate / door does this)
	keep.max_hp = MAX_HP_OVERRIDE
	keep.hp = 4000.0
	# R4-3: a worker training, then a helper Call stub, then a code-built stub nobody can rebuild
	var eco := Economy.for_team(PLAYER)
	eco.crystals = 1000
	if keep.queue_unit(keep.trainable_types()[0]) != "":
		_fail("could not queue a worker")
	var roster := HelperRoster.for_team(PLAYER)
	var call_stub := roster.call_type() if roster else null
	if call_stub:
		keep.queue.append(call_stub)
		eco.reserve_pop(call_stub.pop)
		had_call_stub = true
	else:
		print("  (no helper for the player kingdom: Call stub part skipped)")
	var fake := UnitType.new()
	fake.id = FAKE_STUB_ID
	fake.cost = FAKE_COST
	fake.pop = 0
	fake.train_time = 30.0
	keep.queue.append(fake)


func _player_archer() -> Unit:
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == PLAYER and u.unit_type and u.unit_type.id == &"ember_archer" and u.is_alive():
			return u
	return null


func _check_before_save() -> void:
	var a := _player_archer()
	if a == null:
		_fail("no archer before the save")
		return
	if not a.has_modifier(ForgeKit.MODIFIER):
		_fail("the archer has no forge modifier before the save")
	if not is_equal_approx(a.attack_range, archer_base_range + 1.0):
		_fail("archer range before the save %.2f (want %.2f)" % [a.attack_range, archer_base_range + 1.0])


func _save() -> void:
	if SaveGame.block_reason(level) != "":
		_fail("save refused: %s" % SaveGame.block_reason(level))
	var why := SaveGame.write_file(TEST_PATH, SaveGame.capture(level))
	if why != "":
		_fail("write_file: %s" % why)
	data = SaveGame.read_file(TEST_PATH)
	if data.has("error"):
		_fail("read_file: %s" % data["error"])
	crystals_at_save = Economy.for_team(PLAYER).crystals


func _reload_from(d: Dictionary) -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = SaveGame.instantiate_level(d)
	if level == null:
		_fail("instantiate_level returned null")
		return
	restorer_done = false
	var r := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		if not ok:
			_fail("the restorer reported a failure"))
	root.add_child(level)
	current_scene = level


func _check_after_load() -> void:
	# R4-1
	var a := _player_archer()
	if a == null:
		_fail("no archer after the load")
	else:
		if not a.has_modifier(ForgeKit.MODIFIER):
			_fail("R4-1: the loaded archer lost its forge modifier")
		if not is_equal_approx(a.attack_range, archer_base_range + 1.0):
			_fail("R4-1: loaded archer range %.2f (want %.2f)" % [a.attack_range, archer_base_range + 1.0])
	# max_hp override
	var keep: Keep = level.get(&"keep")
	if not is_equal_approx(keep.max_hp, MAX_HP_OVERRIDE):
		_fail("max_hp override lost: %.0f (want %.0f)" % [keep.max_hp, MAX_HP_OVERRIDE])
	if absf(keep.hp - 4000.0) > 1.0:
		_fail("keep hp after load %.0f (want 4000)" % keep.hp)
	# R4-3
	var ids: Array[StringName] = []
	for t in keep.queue:
		ids.append(t.id)
	if had_call_stub and not ids.has(HelperRoster.CALL_ID):
		_fail("R4-3: the helper Call stub was dropped on load (queue %s)" % str(ids))
	if ids.has(FAKE_STUB_ID):
		_fail("R4-3: an unknown stub came back as a queue entry")
	var got := Economy.for_team(PLAYER).crystals - crystals_at_save
	if got != FAKE_COST:
		_fail("R4-3: crystals after load %+d vs the save (want +%d refund)" % [got, FAKE_COST])


## R4-6: empties a crystal node; its shrink tween ends with a navmesh rebake (seen as BuildGrid.is_rebaking() or the
## region's bake_finished).
func _deplete_setup() -> void:
	var g: BuildGrid = level.get(&"build_grid")
	var node: CrystalNode = null
	for n in get_nodes_in_group(&"crystal_nodes"):
		if n is CrystalNode and not (n as CrystalNode).is_depleted():
			node = n as CrystalNode
			break
	if node == null or g.nav_region == null:
		_fail("R4-6: no crystal node / nav region to test")
		return
	depleted_node = node
	g.nav_region.bake_finished.connect(func() -> void: bakes_seen += 1)
	_watch_rebake(g)
	node.take(node.crystals_left)


func _watch_rebake(g: BuildGrid) -> void:
	process_frame.connect(func() -> void:
		if step == "deplete" and g and is_instance_valid(g) and g.is_rebaking():
			bakes_seen += 1)


func _tier_setup() -> void:
	var ts := TierSystem.instance()
	if ts == null:
		_fail("no TierSystem in the skirmish")
		return
	ts.time_gates = false
	var keep: Keep = level.get(&"keep")
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var grid: BuildGrid = level.get(&"build_grid")
	grid.spawn_complete(BuildingType.find("fire_barracks"), keep.global_position + dir * 16.0, PLAYER)


func _tier_check() -> void:
	var ts := TierSystem.instance()
	if ts == null:
		return
	var keep: Keep = level.get(&"keep")
	var eco := Economy.for_team(PLAYER)
	eco.crystals = 1000
	var r := keep.upgrade()
	if r != "":
		_fail("R4-7: could not start the Stronghold upgrade: %s" % r)
		return
	var paid := 1000 - eco.crystals
	ts.set_tier(PLAYER, 2)
	if keep.is_upgrading():
		_fail("R4-7: set_tier left the upgrade running")
	if eco.crystals != 1000:
		_fail("R4-7: set_tier refund: crystals %d (paid %d, want 1000)" % [eco.crystals, paid])
	if keep.tier != 2:
		_fail("R4-7: tier %d after set_tier(2)" % keep.tier)


func _gold_refund_check() -> void:
	var g := GoldBank.for_team(PLAYER)
	if g == null:
		print("  (no GoldBank: refund check skipped)")
		return
	var before_gold := g.gold
	var before_earned := g.earned()
	g.refund(40)
	if g.gold != before_gold + 40 or g.earned() != before_earned:
		_fail("GoldBank.refund: gold %d (want %d), earned %d (want %d)" % [g.gold, before_gold + 40, g.earned(),
				before_earned])


var seat_unit: Unit
var seat_house: Building
var seat_pops: Array = []


## R4-5: a soldier and a finished house of the player, later switched to the enemy team.
func _seat_switch_setup() -> void:
	var keep: Keep = level.get(&"keep")
	seat_unit = Worker.make_unit(UnitType.find("flame_guard"))
	seat_unit.team = Unit.Team.PLAYER
	level.add_child(seat_unit)
	seat_unit.global_position = keep.global_position + Vector3(-6.0, 0.0, 6.0)
	seat_unit.command_hold()
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var grid: BuildGrid = level.get(&"build_grid")
	seat_house = grid.spawn_complete(BuildingType.find("fire_hearth"), keep.global_position + dir * 9.0 \
			+ Vector3(dir.z, 0.0, -dir.x) * 9.0, PLAYER)


## What switch_seat_side does (MissionBase, F1): team, then Economy.move_unit on the old Economy / refresh_economy.
func _seat_switch_check() -> void:
	var mine := Economy.for_team(PLAYER)
	var theirs := Economy.for_team(Unit.Team.ENEMY)
	if seat_house == null or mine == null or theirs == null:
		_fail("R4-5: setup (house %s)" % str(seat_house))
		return
	var bonus := seat_house.building_type.pop_bonus
	var pop := seat_unit.unit_type.pop
	var m0 := [mine.pop_used, mine.pop_cap]
	var t0 := [theirs.pop_used, theirs.pop_cap]
	seat_unit.team = Unit.Team.ENEMY
	mine.move_unit(seat_unit, theirs)
	seat_house.team = Unit.Team.ENEMY
	seat_house.refresh_economy()
	if mine.pop_used != int(m0[0]) - pop or theirs.pop_used != int(t0[0]) + pop:
		_fail("R4-5: unit pop %d -> %d / %d -> %d (pop %d)" % [m0[0], mine.pop_used, t0[0], theirs.pop_used, pop])
	if mine.pop_cap != mini(int(m0[1]) - bonus, mine.max_pop_cap) \
			or theirs.pop_cap != mini(int(t0[1]) + bonus, theirs.max_pop_cap):
		_fail("R4-5: pop cap %d -> %d / %d -> %d (bonus %d)" % [m0[1], mine.pop_cap, t0[1], theirs.pop_cap, bonus])
	seat_pops = [mine.pop_used, theirs.pop_used, pop]
	seat_unit.queue_free()


## After the switched unit is freed: only the new team's Economy gives its pop back.
func _seat_free_check() -> void:
	if seat_pops.is_empty():
		return
	var mine := Economy.for_team(PLAYER)
	var theirs := Economy.for_team(Unit.Team.ENEMY)
	var pop := int(seat_pops[2])
	if theirs.pop_used != int(seat_pops[1]) - pop or mine.pop_used != int(seat_pops[0]):
		_fail("R4-5: freeing the switched unit: theirs %d (want %d), mine %d (want %d)" % [theirs.pop_used,
				int(seat_pops[1]) - pop, mine.pop_used, int(seat_pops[0])])


func _film_check() -> void:
	var both := StoryFilms.seen_ids(&"c_e6_gate", &"c_e6_gate_shut")
	if not (both.has(&"c_e6_gate") and both.has(&"c_e6_gate_shut")):
		_fail("C1-5: a branched film marks %s" % str(both))
	if StoryFilms.seen_ids(&"c_e6_gate", &"c_e6_gate").size() != 1:
		_fail("C1-5: the main film marks itself twice")
