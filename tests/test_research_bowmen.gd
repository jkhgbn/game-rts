extends SceneTree
## UR.G5 (docs/design/unit-upgrades.md 7-15): BowmanUpgrades is a facade over UnitResearch.
## - chains: the needs refusals come from UnitResearch ("Needs Heavy Draw", "Needs Heartseeker Points"), facade
##   options show them locked;
## - Hunting Party bought through UnitResearch only (no BowmanUpgrades node yet) still brings the twin;
## - no double bonus: Heavy Draw = the row's "research:" modifier only (17 damage, no "bowman:" modifier), re-applying
##   changes nothing;
## - old save: a "bowman_upgrades:<team>" row maps to granted rows + the research in progress, the unit's saved
##   "bowman:" modifier is dropped (17, not 20), and the mapping survives UnitResearch's own row loading after it.
## Run:  godot --headless --path . -s tests/test_research_bowmen.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "research_bowmen"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 3000

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _halls := {}
var _spot := Vector3.ZERO


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.camps_enabled = false
	main.beasts_enabled = false
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 5 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


func _count(id: StringName, team: int) -> int:
	var n := 0
	for u in get_nodes_in_group(&"units"):
		if u is Unit and int(u.team) == team and u.unit_type and u.unit_type.id == id and u.is_alive():
			n += 1
	return n


func _run() -> void:
	var keep: Node3D = main.keep
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var side := dir.cross(Vector3.UP)
	_spot = keep.global_position + dir * 20.0
	main.economy.add(20000)
	main.economy.add_pop_bonus(150)
	var i := 0
	for f: StringName in [&"fire", &"nature"]:
		_halls[f] = main.build_grid.spawn_complete(BuildingType.find("%s_barracks" % f),
				keep.global_position - dir * 2.0 + side * (-10.0 + 12.0 * i), PLAYER) as TrainingBuilding
		i += 1
	_halls[&"enemy_fire"] = main.build_grid.spawn_complete(BuildingType.find("fire_barracks"),
			keep.global_position - dir * 2.0 + side * 16.0, ENEMY) as TrainingBuilding
	await _frames(2)
	await _check_hunting_party_through_research()
	_check_chains()
	await _check_no_double()
	await _check_old_save()
	_done = true


# Hunting Party bought through UnitResearch (the UR.U1 card), no BowmanUpgrades node made before.
func _check_hunting_party_through_research() -> void:
	_check(BowmanUpgrades.for_team(PLAYER, false) == null, "a BowmanUpgrades node exists before any use")
	var ur := UnitResearch.for_team(PLAYER)
	_check(ur != null, "no UnitResearch in the skirmish")
	if ur == null:
		return
	var hall: TrainingBuilding = _halls[&"nature"]
	_check(ur.can_buy(&"wildwood_hunting_party", hall) == "Needs Heartseeker Points",
			"Hunting Party needs: %s" % ur.can_buy(&"wildwood_hunting_party", hall))
	ur.grant(&"wildwood_keen_eye")
	ur.grant(&"wildwood_heartseeker")
	ur.grant(&"wildwood_hunting_party")
	_check(BowmanUpgrades.team_has(PLAYER, &"wildwood_hunting_party"), "facade does not see Hunting Party")
	_check(BowmanKit.crit_numbers(PLAYER) == Vector2(0.20, 2.75), "Heartseeker crit numbers from UnitResearch")
	var quick := UnitType.find("wildwood_archer").duplicate() as UnitType
	quick.train_time = 0.2
	var before := _count(&"wildwood_archer", PLAYER)
	_check(hall.queue_unit(quick) == "", "queue a Wildwood Archer")
	await _frames(30)
	_check(_count(&"wildwood_archer", PLAYER) == before + 2, "Hunting Party through UnitResearch: %d new (want 2)"
			% (_count(&"wildwood_archer", PLAYER) - before))
	before = _count(&"wildwood_archer", PLAYER)
	hall.queue_unit(quick)
	await _frames(30)
	_check(_count(&"wildwood_archer", PLAYER) == before + 2, "Hunting Party second archer: %d new (want 2)"
			% (_count(&"wildwood_archer", PLAYER) - before))


func _check_chains() -> void:
	var bank := BowmanUpgrades.for_team(PLAYER)
	var fire: TrainingBuilding = _halls[&"fire"]
	_check(bank.can_buy(&"scorchbow_pitch_arrows", fire) == "Needs Heavy Draw",
			"Pitch Arrows needs: %s" % bank.can_buy(&"scorchbow_pitch_arrows", fire))
	var opts := BowmanUpgrades.options_for(fire)
	_check(opts.size() == 2 and opts[0]["id"] == &"scorchbow_heavy_draw" and opts[1]["state"] == &"locked",
			"Ember Hall facade options %s" % str(opts.map(func(o: Dictionary) -> String: return "%s:%s" % [o["id"], o["state"]])))
	# The facade table agrees with UnitResearch's bowman rows.
	for id: StringName in BowmanUpgrades.UPGRADES:
		var r := UnitResearch.row(id)
		_check(bool(r.get("bowman", false)) and int(r["price"]) == int(BowmanUpgrades.UPGRADES[id]["crystals"])
				and StringName(r["needs"]) == StringName(BowmanUpgrades.UPGRADES[id]["needs"]), "%s row differs" % id)


func _check_no_double() -> void:
	var bow := _spawn("scorchbow", PLAYER, _spot)
	BowmanUpgrades.for_team(PLAYER).grant(&"scorchbow_heavy_draw")
	await _frames(2)
	_check(is_equal_approx(bow.attack_damage, 17.0), "Heavy Draw living bow %.1f (want 17)" % bow.attack_damage)
	_check(bow.has_modifier(&"research:scorchbow_heavy_draw"), "no research: modifier")
	_check(not bow.has_modifier(&"bowman:scorchbow_heavy_draw"), "a bowman: modifier is still added")
	BowmanUpgrades.apply_to(bow)
	UnitResearch.apply_to(bow)
	_check(is_equal_approx(bow.attack_damage, 17.0), "re-apply doubled: %.1f" % bow.attack_damage)
	var fresh := _spawn("scorchbow", PLAYER, _spot + Vector3(3.0, 0.0, 0.0))
	_check(is_equal_approx(fresh.attack_damage, 17.0), "new bow at spawn %.1f (want 17)" % fresh.attack_damage)
	await _frames(2)
	_check(is_equal_approx(fresh.attack_damage, 17.0), "new bow after UnitResearch's pass %.1f" % fresh.attack_damage)
	bow.queue_free()
	fresh.queue_free()


# An old save (before UR.G5): the bow carries the saved "bowman:" modifier, the facade row has the done ids + work.
func _check_old_save() -> void:
	var bow := _spawn("scorchbow", ENEMY, _spot + Vector3(0.0, 0.0, 30.0))
	bow.add_modifier(&"bowman:scorchbow_heavy_draw", {&"attack_damage": 3.0}, false)
	_check(is_equal_approx(bow.attack_damage, 17.0), "old-save bow before the load %.1f" % bow.attack_damage)
	var hall: TrainingBuilding = _halls[&"enemy_fire"]
	var node := BowmanUpgrades.create_for_save(main, "bowman_upgrades:%d" % ENEMY)
	_check(node is BowmanUpgrades, "create_for_save made no node")
	if not node is BowmanUpgrades:
		return
	var old := {"team": ENEMY, "researched": ["scorchbow_heavy_draw", "wildwood_keen_eye"],
			"work": [{"id": "scorchbow_pitch_arrows", "hall": hall, "left": 9.0}]}
	node.call(&"load_state", old, {})
	# SaveWorld order is not fixed: UnitResearch's own (older, bowman-less) row may load after the facade's.
	var ur := UnitResearch.for_team(ENEMY, false)
	_check(ur != null, "no enemy UnitResearch after the old load")
	if ur == null:
		return
	ur.load_state({"done": [], "work": []}, {})
	await _frames(3)
	_check(UnitResearch.team_has(ENEMY, &"scorchbow_heavy_draw") and UnitResearch.team_has(ENEMY, &"wildwood_keen_eye"),
			"old done ids not granted")
	_check(ur.is_working(&"scorchbow_pitch_arrows") and ur.working_at(hall) == &"scorchbow_pitch_arrows",
			"old work not restored")
	var p := ur.progress(&"scorchbow_pitch_arrows")
	_check(p > 0.7 and p < 0.85, "old work progress %.2f (want ~0.8)" % p)
	_check(is_equal_approx(bow.attack_damage, 17.0), "old-save bow damage %.1f (want 17, not 20)" % bow.attack_damage)
	_check(not bow.has_modifier(&"bowman:scorchbow_heavy_draw"), "old bowman: modifier kept")
	_check(bow.has_modifier(&"research:scorchbow_heavy_draw"), "research: modifier missing after the old load")
	_check((node as BowmanUpgrades).save_state().is_empty(), "the facade still saves state")
	_check(ur.save_state()["done"].has("scorchbow_heavy_draw"), "UnitResearch save misses the mapped row")
	bow.queue_free()
