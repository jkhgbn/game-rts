extends SceneTree
## Tasks 19.C5a / 19.C5b / 19.C5c (docs/design/mission-04.md "Done when"): headless scripted runs of mission 4 with the
## cutscenes off (= the skip path: every end state runs at once).
## Default (seat path): the start state (tier 2 keep, 26 pop, L4 + 3 points, Malrik L5, the isle guard), the pylon
## clearance (>= 6 m from every crossing centre, >= 2 m from the lane edge), the seat blocked while Shadow stands on
## the isle, the Rise by the seat (sec_seat done), the Ward (no damage while a pylon stands), a pylon broken by Shadow
## (L24 + m4_malrik_pylons), phase 2 (walk, Cracked Leg at 70 %), the darkest hour by boss HP (Vey, phase 3), three
## turns of the key (L16-L19), the fall, the victory and the m04 reward (set_flags) in a test save.
## `-- --meter`: the Rise by the Hollow meter (sec_seat failed) and the darkest hour by keep HP.
## `-- --defeat`: Vessa dies (L20, defeat). `-- --keep`: the Fire keep falls (obj_keep failed, defeat).
## Run:  godot --headless --path . -s tests/test_19_c5.gd --fixed-fps 60 --quit-after 30000 [-- --meter]

const TASK_ID := "19_c5"
const SCENE := "res://missions/mission_04.tscn"
const TEST_SAVE := "user://test_19_c5_campaign.json"
const LANE_HALF_WIDTH := 2.6

var h := MissionHarness.new()
var main: Mission04
var mode := "seat"
var _wait := 0
var _hp_before := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--meter"):
		mode = "meter"
	elif args.has("--defeat"):
		mode = "defeat"
	elif args.has("--keep"):
		mode = "keep"
	h.task_id = "%s/%s" % [TASK_ID, mode]
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://test_19_c5_none.json"}}) as Mission04
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	h.steps.add("start state", _start_state, 10)
	match mode:
		"defeat":
			h.protect_hero = false
			h.steps.add("Vessa dies", func() -> bool:
				MissionHarness.kill([main.hero])
				return true, 10)
			h.steps.add("defeat", func() -> bool: return h.ended == 0, 400)
			h.steps.add("L20", func() -> bool:
				return h.check(main.said_ids.has(&"L20"), "L20 said") and h.check(h.saw("obj_vessa", "failed"), "obj_vessa failed"), 10)
			return
		"keep":
			h.steps.add("the keep falls", func() -> bool:
				MissionHarness.kill([main.keep])
				return true, 10)
			h.steps.add("defeat", func() -> bool: return h.ended == 0, 400)
			h.steps.add("obj_keep failed", func() -> bool: return h.check(h.saw("obj_keep", "failed"), "obj_keep failed"), 10)
			return
	if mode == "seat":
		h.steps.add("seat blocked by the isle guard", _seat_blocked, 400)
		h.steps.add("clear the isle, sit", _sit, 10)
		h.steps.add("the Rise (seat)", func() -> bool: return main.phase == 1, 600)
	else:
		h.steps.add("the meter fills", _meter, 10)
		h.steps.add("the Rise (meter)", func() -> bool: return main.phase == 1, 1200)
	h.steps.add("the Rise end state", _rise_state, 10)
	h.steps.add("the Ward holds", _ward, 30)
	h.steps.add("E7 the pylon strike (L9)", func() -> bool:
		_skip_to(main.rise_time + 21.0)
		return main.said_ids.has(&"L9") and not main.strike_units.is_empty(), 300)
	h.steps.add("Shadow breaks P3", _shadow_breaks_p3, 10)
	h.steps.add("L24 + flag", func() -> bool: return main.said_ids.has(&"L24"), 120)
	h.steps.add("the other pylons fall", _break_rest, 10)
	h.steps.add("phase 2", func() -> bool: return main.phase == 2 and main.said_ids.has(&"L11"), 120)
	h.steps.add("the walk starts", _walking, 600)
	if mode == "seat":
		h.steps.add("Cracked Leg at 70 %", _crack, 10)
		h.steps.add("E10", func() -> bool: return main.said_ids.has(&"L12"), 120)
		h.steps.add("darkest hour by boss HP", _boss_to_40, 10)
	else:
		h.steps.add("darkest hour by keep HP", _keep_to_50, 10)
	h.steps.add("phase 3", func() -> bool: return main.phase == 3, 600)
	h.steps.add("the storm end state", _storm_state, 10)
	h.steps.add("three turns of the key", _turn_key, 6000)
	h.steps.add("the Colossus falls", _finish_boss, 10)
	h.steps.add("victory", func() -> bool: return h.ended == 1, 600)
	h.steps.add("lines and save", _lines_and_save, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _skip_to(t: float) -> void:
	MissionHarness.skip_time(main, maxf(0.0, t - main.mission_time()))


func _start_state() -> bool:
	var pop := 0
	for n in root.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.PLAYER and u.unit_type:
			pop += u.unit_type.pop
	var eco := Economy.for_team(Unit.Team.PLAYER)
	h.check(pop == 26, "start pop 26 (got %d)" % pop)
	h.check(eco != null and eco.pop_cap >= 40, "pop cap 40 (got %s)" % (eco.pop_cap if eco else -1))
	h.check(eco != null and eco.crystals == 400, "400 crystals (got %s)" % (eco.crystals if eco else -1))
	h.check(main.keep.tier == 2, "the Fire keep starts as a Stronghold")
	h.check(main.hero.level == 4 and main.hero.spell_points == 3, "Vessa L4 + 3 points (L%d, %d)" % [main.hero.level, main.hero.spell_points])
	h.check(main.shadow_hero.level == 5, "Malrik L5 (L%d)" % main.shadow_hero.level)
	h.check(main.isle_guard.size() == 9, "isle guard 9 (%d)" % main.isle_guard.size())
	h.check(main.taverns.size() == 1, "only the west tavern")
	h.check(main.river != null, "the river is on")
	h.check(main.objective_state("obj_isle") == "active" and main.objective_state("obj_keep") == "active", "phase 0 objectives")
	var inv := ItemDrops.inventory_of(main.hero) as Inventory
	h.check(inv != null and inv.get_type(Inventory.ARTIFACT_SLOT) != null \
			and inv.get_type(Inventory.ARTIFACT_SLOT).id == &"masters_signet", "Signet in artifact slot 1")
	# 19.C5a clearance: >= 6 m from every crossing centre, >= 2 m between the footprint and the lane edge.
	for i in Mission04.PYLON_SPOTS.size():
		var p: Vector3 = Mission04.PYLON_SPOTS[i]
		for c: Dictionary in main.river.crossings():
			var cc: Vector3 = c["center"]
			h.check(Vector2(p.x - cc.x, p.z - cc.z).length() >= 6.0, "P%d %.1f m from %s" % [i + 1,
					Vector2(p.x - cc.x, p.z - cc.z).length(), c["id"]])
		var lane_end: Vector3 = main.PLAYER_START if p.x < 0.0 else main.SHADOW_START
		var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2.ZERO, Vector2(lane_end.x, lane_end.z))
		var gap := Vector2(p.x, p.z).distance_to(q) - LANE_HALF_WIDTH - M04Keystone.PYLON_RADIUS
		h.check(gap >= 2.0, "P%d lane gap %.1f m" % [i + 1, gap])
	return true


func _seat_blocked() -> bool:
	MissionHarness.put(main.hero, Vector3.ZERO)
	return main.seat_blocked


func _sit() -> bool:
	h.check(main.seat_progress == 0.0, "the seat does not fill while blocked")
	MissionHarness.kill(main.isle_guard)
	for n in root.get_tree().get_nodes_in_group("units"):   # anything Shadow that wandered onto the isle
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, Vector3.ZERO) < 12.0:
			MissionHarness.kill([u])
	MissionHarness.put(main.hero, Vector3.ZERO)
	return true


func _meter() -> bool:
	h.check(main.hollow >= 0.0 and main.hollow < 10.0, "the meter starts low (%.1f)" % main.hollow)
	_skip_to(1000.0)
	return true


func _rise_state() -> bool:
	if mode == "seat":
		h.check(h.saw("sec_seat", "done"), "sec_seat done by the seat")
	else:
		h.check(h.saw("sec_seat", "failed"), "sec_seat failed by the meter")
	h.check(h.saw("obj_isle", "done") and h.saw("obj_pylons", "active"), "obj_isle done, obj_pylons active")
	h.check(main.keystone.pylons.size() == 4 and main.keystone.colossus_alive(), "4 pylons + the Colossus")
	h.check(main.keystone.colossus.phase == 1, "Colossus phase 1")
	h.check(MissionBase._flat(main.hero.global_position, Mission04.RISE_VESSA) < 1.0, "Vessa at the West Crown Bridge")
	h.check(main.pillars_left() == 0, "the pillar ring is gone")
	h.check(main.said_ids.has(&"L7") and main.said_ids.has(&"L8"), "L7 L8")
	for u in main.isle_guard:
		h.check(not is_instance_valid(u) or not (u as Unit).is_alive(), "the isle guard is gone")
	return true


func _ward() -> bool:
	var c := main.keystone.colossus
	_hp_before = c.hp
	c.take_damage(5000.0, main.hero)
	return h.check(is_equal_approx(c.hp, _hp_before), "the Ward blocks damage while pylons stand")


func _shadow_breaks_p3() -> bool:
	var shade: Unit = null
	for n in root.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and not (u is Wizard):
			shade = u
			break
	var p3: Unit = main.keystone.pylons[2]
	p3.take_damage(1.0e7, shade)
	return true


func _break_rest() -> bool:
	h.check(main.shadow_pylons == 1 and bool(main.mission_flags().get("m4_malrik_pylons", false)), "m4_malrik_pylons")
	for i in [0, 1, 3]:
		(main.keystone.pylons[i] as Unit).take_damage(1.0e7, main.hero)
	return true


func _walking() -> bool:
	var c := main.keystone.colossus
	return c.phase == 2 and MissionBase._flat(c.global_position, Vector3.ZERO) > 2.0


func _crack() -> bool:
	var c := main.keystone.colossus
	c.take_damage((c.hp - c.max_hp * 0.68) / c.damage_mult() / Unit.armor_multiplier(25.0), main.hero)
	return h.check(c.hp < c.max_hp * 0.7, "boss below 70 %% (%.0f)" % c.hp)


func _boss_to_40() -> bool:
	var c := main.keystone.colossus
	c.cracked_left = 0.0
	c.take_damage((c.hp - c.max_hp * 0.38) / c.damage_mult() / Unit.armor_multiplier(25.0), main.hero)
	return true


func _keep_to_50() -> bool:
	main.keep.take_damage(main.keep.hp - main.keep.max_hp * 0.45, null)
	return true


func _storm_state() -> bool:
	var k := main.keystone
	h.check(k.colossus.phase == 3 and k.colossus.hp <= k.colossus.max_hp * 0.4 + 1.0, "kneeling at <= 40 %")
	h.check(k.vey_alive() and MissionBase._flat(k.vey.global_position, main.hero.global_position) <= 4.0, "Vey beside Vessa")
	h.check(main.said_ids.has(&"L14") and main.said_ids.has(&"L15") and main.said_ids.has(&"L25"), "L14 L15 L25")
	h.check(h.saw("obj_colossus", "done") and h.saw("obj_key", "active"), "obj_key active")
	h.check(main.darkest_by == (&"boss" if mode == "seat" else &"keep"), "darkest hour by %s" % main.darkest_by)
	return true


## Vessa stands by the heart with Vey; each Exposed window the test hits the Colossus hard enough for ~1/3.
func _turn_key() -> bool:
	var k := main.keystone
	var c := k.colossus
	var at := c.global_position + Vector3(-c.radius - 2.0, 0.0, 2.0)
	if MissionBase._flat(main.hero.global_position, at) > 1.5:
		MissionHarness.put(main.hero, at)
	if is_instance_valid(k.vey) and MissionBase._flat(k.vey.global_position, at) > 5.0:
		MissionHarness.put(k.vey, at + Vector3(-2.0, 0.0, 1.0))
	if k.exposures >= 3:
		return true
	return false


func _finish_boss() -> bool:
	var k := main.keystone
	h.check(main.said_ids.has(&"L16") and main.said_ids.has(&"L17") and main.said_ids.has(&"L18") \
			and main.said_ids.has(&"L19"), "L16-L19 on exposures 1-3")
	h.check(k.colossus.exposed or k.exposed_time_left() >= 0.0, "exposed")
	k.colossus.set_exposed(true)
	k.colossus.take_damage(1.0e7, main.hero)
	return true


func _lines_and_save() -> bool:
	h.check(main.heart_stone != null and is_instance_valid(main.heart_stone), "the heart_stone actor")
	h.check(h.saw("obj_key", "done"), "obj_key done")
	for id: StringName in [&"L1", &"L2", &"L3", &"L4", &"L7", &"L8", &"L9", &"L10", &"L11", &"L21"]:
		h.check(main.said_ids.has(id), "line %s said" % id)
	var seen := {}
	for id in main.said_ids:
		h.check(not seen.has(id), "line %s once" % id)
		seen[id] = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var cs := CampaignState.open(TEST_SAVE)
	h.check(cs.on_mission_victory(&"m04", main) == OK, "victory save")
	var loaded := CampaignState.open(TEST_SAVE)
	h.check(loaded.is_completed(&"m04"), "m04 completed")
	h.check(loaded.flag("ep1_complete") and loaded.flag("ep1_shard_to_malrik") and loaded.flag("ep1_vey_returned"),
			"set_flags written")
	h.check(loaded.flag("m4_malrik_pylons"), "m4_malrik_pylons saved")
	h.check(loaded.flag("m4_seat_taken") == (mode == "seat"), "m4_seat_taken = %s" % (mode == "seat"))
	h.check(loaded.unlocked.has(&"e2m1"), "e2m1 unlocked")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return true
