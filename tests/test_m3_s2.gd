extends SceneTree
## Tasks M3.S1-S3 (docs/design/mission-03.md "Acceptance checks" 1-8): a headless scripted VICTORY of mission 3 with
## Pell freed: the map (clearings, paths to the hearts / gates / tavern / rally, the thorn ring closed before E10 and
## open after), the tavern at 0:30 with the free first hire (0 crystals + 75 essence), E1-E13 in order, the hearts
## (regen rule, Thrall drain, credit, Ember Stake 400 HP / sight 10), W2 at the 2nd heart, the m3_oldroot end state,
## the muster (75 s), Malrik's carry at 1.6 m/s, his drop (3 s) and Vessa's claim, the m3_plea + m3_memory end
## state (Signet in slot 2, Shadow pulled back, gates open), the Warden tide (2 / 25 s, max 8), both gates, the
## victory and its save (MISSION_REWARDS[&"m03"], companion candidates). `-- --peddler=false` runs the cache branch.
## Run:  godot --headless --path . -s tests/test_m3_s2.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "m3.s2"
const SCENE := "res://missions/mission_03.tscn"
const TEST_SAVE := "user://test_m3_s2_campaign.json"

var h := MissionHarness.new()
var main: Mission03
var pell := true
var _wait := 0
var _t0 := 0.0
var _hp0 := 0.0


func _initialize() -> void:
	pell = not OS.get_cmdline_user_args().has("--peddler=false")
	h.task_id = TASK_ID + ("" if pell else "/cache")
	main = h.open(self, SCENE, {"difficulty": 1, "set": {
		"flag_override": {"m1_peddler_freed": pell},
		"campaign_save_path": "user://test_m3_none.json"}}) as Mission03
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	h.steps.add("map (check 1, 2 before)", _map, 10)
	h.steps.add("E1 lines + branch", _e1, 10)
	h.steps.add("tavern opens at 0:30", func() -> bool:
		_skip_to(30.5)
		return true, 10)
	h.steps.add("E2 fired", func() -> bool: return main.has_fired(&"E2"), 120)
	h.steps.add("first hire is free (check 4)", _hire, 10)
	h.steps.add("E3 fired", func() -> bool: return main.has_fired(&"E3"), 400)
	h.steps.add("heart regen (check 3)", _regen_start, 10)
	h.steps.add("heart regen waits 10 s", _regen_check, 1200)
	h.steps.add("D1 at 3:00", func() -> bool:
		_skip_to(180.5)
		return true, 10)
	h.steps.add("D1 drains RH3", _drain_start, 120)
	h.steps.add("D1 drain rate", _drain_rate, 400)
	h.steps.add("RH1 by Vessa (E6, stake)", _rh1, 10)
	h.steps.add("stake raid in 30 s", _stake_raid, 10)
	h.steps.add("stake raid fired", func() -> bool: return main.waves_fired.has(&"stake_raid"), 200)
	h.steps.add("RH2 by Vessa (E6b, W2)", _rh2, 10)
	h.steps.add("RH3 by Shadow (E10)", _rh3, 10)
	h.steps.add("barrier open: path to (0, 2) (check 2)", _open_path, 600)
	h.steps.add("muster 75 s", _muster, 10)
	h.steps.add("march", func() -> bool: return main.race_phase == &"march", 200)
	h.steps.add("Malrik takes the Signet (E10b)", _malrik_takes, 10)
	h.steps.add("E10b fired", func() -> bool: return main.signet_state == &"malrik", 120)
	h.steps.add("carry speed (check 5)", _carry_start, 10)
	h.steps.add("carry speed measured", _carry_check, 400)
	h.steps.add("Malrik killed: drop after 3 s", _kill_malrik, 10)
	h.steps.add("Signet on the ground", func() -> bool: return main.signet_state == &"ground", 400)
	h.steps.add("Vessa takes it (E11)", _vessa_takes, 10)
	h.steps.add("E11 fired", func() -> bool: return main.race_phase == &"over", 120)
	h.steps.add("E11 state (check 6)", _e11_state, 10)
	h.steps.add("tide spawns, max 8 alive", _tide, 3000)
	h.steps.add("gates (E12, E13)", _gates, 10)
	h.steps.add("victory", func() -> bool: return h.ended == 1, 600)
	h.steps.add("lines and save (check 8)", _lines_and_save, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _skip_to(t: float) -> void:
	MissionHarness.skip_time(main, maxf(0.0, t - main.mission_time()))


func _path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var map := (main as Node3D).get_world_3d().navigation_map
	return NavigationServer3D.map_get_path(map, from, to, true)


func _path_reaches(from: Vector3, to: Vector3, r: float) -> bool:
	var p := _path(from, to)
	return p.size() > 1 and Mission03._flat(p[p.size() - 1], to) <= r


func _map() -> bool:
	# Trees / rocks (StaticBody3D children of the region that are not mission props) stay out of every clearing.
	var clearings := main.map_clearings()
	var bad := 0
	for c in main.nav_region.get_children():
		var b := c as StaticBody3D
		if b == null or b is Building or b is RootHeart or b is WardenGate or b.is_in_group(&"thorn_barrier") \
				or b.name == "Oldroot" or b is Tavern or b is CrystalNode or b is RuinPeddler:
			continue
		if main._in_clearing(b.global_position, clearings) and b.global_position.distance_to(Vector3.ZERO) > 1.0:
			bad += 1
			print("  in a clearing: %s %s %s" % [b.name, b.get_class(), b.global_position])
	h.check(bad == 0, "no tree / rock in a clearing (%d)" % bad)
	var from := Vector3(-40.0, 0.0, 40.0)
	for id: StringName in Mission03.HEARTS:
		h.check(_path_reaches(from, Mission03.HEARTS[id][1] + Vector3(2.5, 0.0, 0.0), 1.5), "path to heart %s" % id)
	for id: StringName in Mission03.GATES:
		var g: WardenGate = main.gates[id]
		h.check(_path_reaches(from, g.front_point(), 1.5), "path to gate %s" % id)
	h.check(_path_reaches(from, main.taverns[0].door_point(), 1.5), "path to the tavern door")
	h.check(_path_reaches(from, Mission03.SHADOW_RALLY, 1.5), "path to the Shadow rally")
	var p := _path(from, Vector3(0.0, 0.0, 2.0))
	h.check(p.size() > 1 and Mission03._flat(p[p.size() - 1], Vector3.ZERO) > 5.0, "no path within 5 m of the tree")
	var lane := _path(from, Vector3(40.0, 0.0, -40.0))
	var through_band := false
	for q in lane:
		var r := Vector2(q.x, q.z).length()
		h.check(r >= 6.5, "the lane path stays out of the ring (r %.1f)" % r)
		if r < 12.0:
			through_band = true
	h.check(lane.size() > 1 and through_band, "the lane path passes between r 7 and r 12")
	h.check(main.thorns.size() == 18, "18 thorn segments")
	h.check(main.taverns.size() == 1 and main.taverns[0].open_time == 30.0, "one tavern, opens 0:30")
	h.check((main.pell != null) == pell and (main.pell_cache != null) != pell, "Pell / cache branch")
	var eco := Economy.for_team(Unit.Team.PLAYER)
	h.check(eco.pop_cap == 40 and eco.crystals == 300, "pop cap 40 (%d), 300 crystals (%d)" % [eco.pop_cap, eco.crystals])
	h.check(main.hero.level == 3 and main.hero.spell_points == 2 and main.hero.spell_rank(&"fireball") == 1,
			"Vessa L3, 2 points, Fireball 1 (L%d, %d, %d)" % [main.hero.level, main.hero.spell_points,
			main.hero.spell_rank(&"fireball")])
	var inv := ItemDrops.inventory_of(main.hero) as Inventory
	h.check(inv.find_slot(&"ember_crown") >= 0 and inv.find_slot(&"stillwater_orb") >= 0, "crown + orb (no-save fallback)")
	h.check(main.shadow_hero.level == 4, "Malrik L4")
	return true


func _e1() -> bool:
	var want := ["L1", "L2", "L3"] + (["L20"] if pell else [])
	h.check(main.said_ids == Array(want).map(func(s: String) -> StringName: return StringName(s)),
			"E1 lines %s" % str(main.said_ids))
	return true


func _hire() -> bool:
	var g := ChampionGuild.for_team(Unit.Team.PLAYER)
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var cost := g.hire_cost(&"wayfinder")
	h.check(int(cost["crystals"]) == 0 and int(cost["essence"]) == 75, "first hire 0 + 75 (%s)" % str(cost))
	var c0 := eco.crystals
	var e0 := bank.essence
	h.check(g.hire(&"wayfinder") == "", "hire the Wayfinder")
	h.check(eco.crystals == c0 and bank.essence == e0 - 75, "paid 0 crystals, 75 essence")
	h.check(int(g.hire_cost(&"oathwall")["crystals"]) > 0, "the 2nd hire costs crystals")
	var bot := ChampionGuild.for_team(Unit.Team.ENEMY)
	h.check(bot == null or bot.roster_size() == 0, "the bot has not hired")
	return true


func _regen_start() -> bool:
	var rh1: RootHeart = main.hearts[&"rh1"]
	rh1.take_damage(100.0, main.hero)
	_hp0 = rh1.hp
	_wait = 0
	return true


func _regen_check() -> bool:
	var rh1: RootHeart = main.hearts[&"rh1"]
	_wait += 1
	if _wait == 540:   # 9 s: no regen yet
		h.check(is_equal_approx(rh1.hp, _hp0), "no regen before 10 s (%.1f)" % rh1.hp)
	if _wait < 720:
		return false
	h.check(rh1.hp > _hp0 + 9.0 and rh1.hp < _hp0 + 30.0, "regen ~9 HP/s after 10 s (%.1f -> %.1f)" % [_hp0, rh1.hp])
	return true


var _thralls: Array = []


func _drain_start() -> bool:
	if main.squads.is_empty():
		return false
	var sq: Dictionary = main.squads[0]
	h.check(sq["heart"] == main.hearts[&"rh3"], "D1 goes to RH3 first")
	_thralls = sq["thralls"]
	h.check(_thralls.size() == 3 and (sq["shades"] as Array).size() == 3, "D1 = 3 Thralls + 3 Shades")
	# Put them at the heart, clear the guardians so the measure is clean.
	MissionHarness.kill(main.guard_groups[&"G3"])
	var p: Vector3 = Mission03.HEARTS[&"rh3"][1]
	for i in _thralls.size():
		var a := float(i) * TAU / 3.0
		MissionHarness.put(_thralls[i], p + Vector3(cos(a), 0.0, sin(a)) * 2.4)
		MissionHarness.immortal(_thralls[i])
	var rh3: RootHeart = main.hearts[&"rh3"]
	rh3.hp = rh3.max_hp
	_hp0 = rh3.hp
	_wait = 0
	return true


func _drain_rate() -> bool:
	_wait += 1
	if _wait < 300:
		return false
	var rh3: RootHeart = main.hearts[&"rh3"]
	var rate := (_hp0 - rh3.hp) / 5.0
	h.check(rate > 11.0 and rate < 12.5, "3 Thralls drain ~12 HP/s = a full heart in 75 s (%.2f)" % rate)
	return true


func _rh1() -> bool:
	var rh1: RootHeart = main.hearts[&"rh1"]
	rh1.take_damage(1.0e6, main.hero)
	h.check(main.has_fired(&"E6") and main.heart_credit[&"rh1"] == Unit.Team.PLAYER, "E6, credit Fire")
	h.check(main.stakes.size() == 1, "an Ember Stake planted")
	var s: Building = main.stakes[0]
	h.check(s.max_hp == 400.0 and s.team == Unit.Team.PLAYER and not s.building_type.counts_for_defeat \
			and FogOfWar.sight_of(s) == 10.0, "stake 400 HP, PLAYER, sight 10 (%.1f)" % FogOfWar.sight_of(s))
	h.check(h.saw("sec_stakes", "active"), "sec_stakes appears")
	h.check(main.said_ids.has(&"L8"), "L8 (Ysolde)")
	return true


func _stake_raid() -> bool:
	MissionHarness.skip_time(main, 31.0)
	return true


func _rh2() -> bool:
	(main.hearts[&"rh2"] as RootHeart).take_damage(1.0e6, main.hero)
	h.check(main.has_fired(&"E6b") and main.waves_fired.has(&"W2"), "E6b: W2 at the 2nd heart")
	return true


func _rh3() -> bool:
	var shade: Unit = null
	for sq: Dictionary in main.squads:
		for u: Variant in sq["shades"]:
			if is_instance_valid(u) and (u as Unit).is_alive():
				shade = u
	(main.hearts[&"rh3"] as RootHeart).take_damage(1.0e6, shade)
	h.check(main.heart_credit[&"rh3"] == Unit.Team.ENEMY, "RH3 credit Shadow (killing blow)")
	h.check(main.has_fired(&"E10") and main.barrier_down, "E10 end state ran (cinematics off = the skip path)")
	h.check(h.saw("obj_hearts", "done") and h.saw("obj_signet", "active") and h.saw("sec_stakes", "done"),
			"objectives after E10")
	h.check(main.race_phase == &"muster" and main.race_army.size() >= 12, "the race army musters (%d)" % main.race_army.size())
	h.check(main.shadow_hero.level == 5, "Malrik L5 for the race")
	main._e10_end_state()   # a second run (skip + finished) changes nothing
	h.check(main.said_ids.count(&"L13") == 1, "L13 once")
	_wait = 0
	return true


func _open_path() -> bool:
	_wait += 1
	if _wait < 120:
		return false
	h.check(_path_reaches(Vector3(-40.0, 0.0, 40.0), Vector3(0.0, 0.0, 2.0), 0.6), "a path reaches (0, 2) after the wither")
	return true


func _muster() -> bool:
	h.check(main.race_phase == &"muster", "still mustering")
	_skip_to(main.muster_ends_at + 0.5)
	return true


func _malrik_takes() -> bool:
	MissionHarness.immortal(main.hero)
	MissionHarness.put(main.hero, Vector3(-30.0, 0.0, 30.0))
	MissionHarness.put(main.shadow_hero, main.tree_grab_point())
	return true


func _carry_start() -> bool:
	h.check(main.said_ids.has(&"L19"), "L19")
	var m := main.shadow_hero
	MissionHarness.put(m, Vector3(8.0, 0.0, -8.0))
	m.command_move(Mission03.DUSK_KEEP_POS)
	_hp0 = m.global_position.distance_to(Mission03.DUSK_KEEP_POS)
	_wait = 0
	return true


func _carry_check() -> bool:
	_wait += 1
	if _wait < 300:
		return false
	var m := main.shadow_hero
	var speed := (_hp0 - m.global_position.distance_to(Mission03.DUSK_KEEP_POS)) / 5.0
	h.check(speed > 1.2 and speed < 1.75, "carry speed ~1.6 m/s (%.2f)" % speed)
	return true


func _kill_malrik() -> bool:
	main.shadow_hero.take_damage(1.0e7, main.hero)
	h.check(main.signet_state == &"dropping", "the Signet drops")
	return true


func _vessa_takes() -> bool:
	h.check(main.said_ids.has(&"L22"), "L22 at the drop")
	MissionHarness.put(main.hero, main.signet_ground + Vector3(0.5, 0.0, 0.5))
	return true


func _e11_state() -> bool:
	var inv := ItemDrops.inventory_of(main.hero) as Inventory
	h.check(inv.find_slot(&"masters_signet") == Inventory.ARTIFACT_SLOT + 1, "the Signet in artifact slot 2")
	h.check(inv.find_slot(&"ember_crown") == Inventory.ARTIFACT_SLOT, "the crown stays in slot 1")
	h.check(h.saw("obj_signet", "done") and h.saw("obj_gates", "active"), "obj_signet done, obj_gates active")
	for id: StringName in main.gates:
		h.check((main.gates[id] as WardenGate).is_open, "gate %s open" % id)
	h.check(main.said_ids.has(&"L15") and main.said_ids.has(&"L16"), "L15 L16")
	var homeward := 0
	for u: Variant in main.race_army:
		if is_instance_valid(u) and (u as Unit).is_alive() and (u as Unit).has_meta(&"m3_home"):
			homeward += 1
	h.check(homeward > 0, "the race army pulls back to the rally (%d)" % homeward)
	_wait = 0
	return true


func _tide() -> bool:
	_wait += 1
	for id: StringName in main.tide_units:
		var alive := (main.tide_units[id] as Array).filter(func(v: Variant) -> bool:
			return is_instance_valid(v) and (v as Unit).is_alive()).size()
		if alive > Mission03.TIDE_MAX_ALIVE:
			h.check(false, "gate %s: %d Wardens alive" % [id, alive])
	if _wait < 60 * 26:
		return false
	var g: WardenGate = main.gates[&"wg1"]
	h.check(g.tides == 2, "2 tides in 26 s (got %d)" % g.tides)
	return true


func _gates() -> bool:
	(main.gates[&"wg1"] as WardenGate).take_damage(1.0e9, main.hero)
	h.check(main.has_fired(&"E12") and main.said_ids.has(&"L17"), "E12, L17")
	(main.gates[&"wg2"] as WardenGate).take_damage(1.0e9, main.hero)
	h.check(main.has_fired(&"E13") and h.saw("obj_gates", "done"), "E13")
	for id: StringName in main.tide_units:
		for v: Variant in main.tide_units[id]:
			h.check(not is_instance_valid(v) or not (v as Unit).is_alive(), "the Wardens crumble")
	return true


func _lines_and_save() -> bool:
	for id: StringName in main.said_ids:
		h.check(main.said_ids.count(id) == 1, "%s said once" % id)
	var cast_text := FileAccess.get_file_as_string("res://data/voice/cast.json")
	for row: Array in Mission03.DIALOGUE:
		var sp: StringName = row[0]
		h.check(cast_text.contains("\"%s\"" % sp), "speaker %s in cast.json" % sp)
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice/lines/m03.json"))
	h.check(json is Dictionary and (json["lines"] as Array).size() == Mission03.DIALOGUE.size(), "m03.json has every line")
	h.check(h.saw("sec_champion", "done"), "sec_champion done")
	var cs := CampaignState.open(TEST_SAVE)
	cs.reset()
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var essence := bank.essence
	h.check(cs.companion_candidates(main).size() == 1, "the hired champion is a companion candidate")
	h.check(cs.on_mission_victory(&"m03", main) == OK, "victory save")
	var loaded := CampaignState.open(TEST_SAVE)
	h.check(loaded.is_completed(&"m03"), "m03 completed")
	h.check(loaded.owned_artifacts().has("masters_signet"), "Signet owned")
	h.check(loaded.flag("m3_hired") and loaded.flag("m3_stakes_held") and not loaded.flag("m3_mossjaw_slain"),
			"m3 flags (hired, stakes held, Mossjaw alive)")
	h.check(loaded.carried_essence() == mini(1500, (essence + 300) / 2), "+300 then 50 %% (%d)" % loaded.carried_essence())
	h.check(CampaignState.film_target(CampaignState.reward_of(&"m03").get("next", &"")) == &"m04", "next = m04 (after the c3_parley film)")
	loaded.reset()
	return true
