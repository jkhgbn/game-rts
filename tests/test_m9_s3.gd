extends SceneTree
## Task M9.S3 (docs/design/mission-02.md "Acceptance checks"): a headless scripted VICTORY of mission 2 with both
## mission 1 flags true (Pell freed, outpost burned): E1-E12 + E11b in order, the lines of that branch exactly once,
## the m2_heartfrost skip end state (cinematics off = the skip path; run twice = same state, L9 once), the orb in
## the free artifact slot, the shore walls (SW / NW / SE sealed, NE open: wall path test), the Sentinels wake NEUTRAL,
## Aldra appears, the Pursuit, then the victory save (MISSION_REWARDS[&"m02"]) into a test save file.
## Run:  godot --headless --path . -s tests/test_m9_s3.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "m9.s3"
const SCENE := "res://missions/mission_02.tscn"
const TEST_SAVE := "user://test_m9_s3_campaign.json"
const BRANCH_LINES: Array[StringName] = [&"L1", &"L2", &"L3", &"L4a", &"L5", &"L6b", &"L7", &"L8", &"L9", &"L10",
		&"L15", &"L16", &"L17", &"L11", &"L12"]

var h := MissionHarness.new()
var main: Node
var _wait := 0


func _initialize() -> void:
	h.task_id = TASK_ID
	main = h.open(self, SCENE, {"difficulty": 1, "set": {
		"flag_override": {"m1_peddler_freed": true, "m1_outpost_burned": true},
		"campaign_save_path": "user://test_m9_none.json"}})
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	h.steps.add("E2 at 2:00", _e2, 10)
	h.steps.add("E2 fired", func() -> bool: return h.saw("obj_dig", "active"), 120)
	h.steps.add("E3 Pell", _e3, 10)
	h.steps.add("E3 fired", func() -> bool: return main.call(&"has_fired", &"E3"), 120)
	h.steps.add("thaw 3 blocks (E4 / E5)", _thaw, 10)
	h.steps.add("E6 at 8:00 (outpost burned)", _e6, 10)
	h.steps.add("E6 fired", func() -> bool: return main.call(&"has_fired", &"E6"), 120)
	h.steps.add("E7 a floe breaks", _e7, 10)
	h.steps.add("E9 near the Heartfrost", _e9, 10)
	h.steps.add("E9 fired", func() -> bool: return main.call(&"has_fired", &"E9"), 120)
	h.steps.add("E10 the Heartfrost melts", _e10, 10)
	h.steps.add("E11 claim the orb", _e11, 10)
	h.steps.add("E11 fired", func() -> bool: return bool(main.get(&"orb_taken")), 60)
	h.steps.add("E11 state", _e11_state, 10)
	h.steps.add("wall path test", _wall_paths, 400)
	h.steps.add("E11b open the SW gap", _e11b, 10)
	h.steps.add("E11b fired", func() -> bool: return main.call(&"has_fired", &"E11b"), 120)
	h.steps.add("E12 home", _e12, 10)
	h.steps.add("victory", func() -> bool: return h.ended == 1, 600)
	h.steps.add("lines and save", _lines_and_save, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _skip_to(t: float) -> void:
	MissionHarness.skip_time(main, maxf(0.0, t - float(main.call(&"mission_time"))))


func _hero() -> Wizard:
	return main.get(&"hero")


func _e2() -> bool:
	h.check(h.dialogue_log.size() >= 2, "L1 L2 at E1")
	_skip_to(120.5)
	return true


func _e3() -> bool:
	MissionHarness.put(_hero(), Mission02.PELL_POS + Vector3(6.0, 0.0, 2.0))
	return true


func _thaw() -> bool:
	h.check(get_nodes_in_group(&"item_pickups").any(func(n: Node) -> bool:
		var t: Variant = n.get(&"type")
		return t is ItemType and (t as ItemType).id == &"frostglass_shard"), "Pell drops a Frostglass Shard")
	for b: MissionBrazier in main.get(&"blocks"):
		b.light()
	h.check(int(main.get(&"thawed")) == 3 and h.saw("sec_emberguard", "done"), "3 blocks thawed, sec_emberguard done")
	var inv := ItemDrops.inventory_of(_hero()) as Inventory
	h.check(inv.find_slot(&"oath_of_embers") >= 0, "Oath of Embers in Vessa's inventory")
	var vets := 0
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.level == 2:
			vets += 1
	h.check(vets >= 9, "9 Emberguard soldiers at veterancy 2 (got %d)" % vets)
	return true


func _e6() -> bool:
	_skip_to(480.5)
	return true


func _e7() -> bool:
	h.check((main.get(&"reinforcements") as Array).is_empty(), "no reinforcements when the outpost burned")
	(main.get(&"lake") as GlasswaterLake).break_floe(5)
	h.check(main.call(&"has_fired", &"E7"), "E7 on the first break")
	return true


func _e9() -> bool:
	MissionHarness.put(_hero(), Vector3(-10.0, 0.0, 10.0))
	return true


func _e10() -> bool:
	var hf: Heartfrost = main.get(&"heartfrost")
	hf.take_damage(1.0e6, _hero())
	h.check(bool(main.get(&"heartfrost_freed")), "E10 end state ran (cinematics off = the skip path)")
	main.call(&"_e10_end_state")   # a second run (skip + finished) changes nothing
	var l9 := h.dialogue_log.filter(func(l: String) -> bool: return l.contains("hundred winters of ice")).size()
	h.check(l9 == 1, "L9 queued once (got %d)" % l9)
	h.check(h.saw("obj_heartfrost", "done") and h.saw("obj_dig", "done") and h.saw("obj_orb", "active"),
			"objectives after E10")
	h.check(h.saw("sec_dig", "done"), "sec_dig done (dig < 50 %)")
	h.check(not bool(main.get(&"dig_active")), "the dig stops")
	return true


func _e11() -> bool:
	MissionHarness.put(_hero(), Vector3(0.5, 0.0, 1.8))
	return true


func _e11_state() -> bool:
	var inv := ItemDrops.inventory_of(_hero()) as Inventory
	h.check(inv.find_slot(&"stillwater_orb") == Inventory.ARTIFACT_SLOT + 1, "the orb in artifact slot 2")
	h.check(inv.find_slot(&"ember_crown") == Inventory.ARTIFACT_SLOT, "the crown stays in slot 1")
	h.check(_hero().has_meta(Unit.STATUS_TIME_MULT_META), "Stillwater passive on Vessa")
	h.check(h.saw("obj_orb", "done") and h.saw("obj_escape", "active"), "obj_orb done, obj_escape active")
	h.check(bool((main.get(&"blizzard") as MissionBlizzard).blowing), "B2 blows")
	h.check(bool((main.get(&"aldra") as MissionRidgeActor).shown), "Aldra on the ridge")
	for s: Unit in main.get(&"sentinels"):
		h.check(not main.call(&"is_dormant", s) and s.team == Unit.Team.NEUTRAL, "Sentinel awake, NEUTRAL")
	var rows: Dictionary = main.get(&"wall_rows")
	h.check(rows.has(&"sw") and rows.has(&"nw") and rows.has(&"se") and not rows.has(&"ne"), "walls at SW NW SE only")
	for g: StringName in rows:
		for row: Array in rows[g]:
			h.check(row.size() >= 5, "gap %s: a row of %d walls" % [g, row.size()])
			for w: Building in row:
				h.check(w.team == Unit.Team.NEUTRAL and not w.building_type.counts_for_defeat, "NEUTRAL wall")
	h.check((main.get(&"waves_fired") as Array).has(&"pursuit"), "the Pursuit")
	h.check((main.get(&"shadow_hero") as Wizard).level == 5, "Malrik L5 at E11")
	# A Sentinel attacks a Shade within its leash.
	var s0: Unit = (main.get(&"sentinels") as Array)[0]
	var shade: Unit = main.call(&"make_unit", "shade")
	main.call(&"_spawn", shade, Unit.Team.ENEMY, s0.global_position + Vector3(3.0, 0.0, 0.0))
	shade.set_meta(&"m9_probe", true)
	_wait = 0
	return true


func _path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var map := (main as Node3D).get_world_3d().navigation_map
	return NavigationServer3D.map_get_path(map, from, to, true)


static func _passes_near(path: PackedVector3Array, p: Vector3, r: float) -> bool:
	for i in range(1, path.size()):
		var c := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(path[i - 1].x, path[i - 1].z),
				Vector2(path[i].x, path[i].z))
		if c.distance_to(Vector2(p.x, p.z)) <= r:
			return true
	return false


func _wall_paths() -> bool:
	_wait += 1
	if _wait < 180:
		return false
	var probe: Unit = null
	for n in get_nodes_in_group(&"units"):
		if n.has_meta(&"m9_probe"):
			probe = n
	var s0: Unit = (main.get(&"sentinels") as Array)[0]
	h.check(probe == null or not probe.is_alive() or s0.attack_target == probe, "a Sentinel attacks a Shade")
	for to: Vector3 in [Vector3(-40, 0, 40), Vector3(-40, 0, -40), Vector3(40, 0, 40)]:
		var path := _path(Vector3(0, 0, 3.5), to)
		h.check(path.size() > 1, "a path out of the lake to %s" % to)
		for g in Mission02.SEALED_GAPS:
			h.check(not _passes_near(path, Mission02.gap_center(g), 2.5), "path to %s avoids sealed %s" % [to, g])
		h.check(_passes_near(path, Mission02.gap_center(&"ne"), 5.0), "path to %s leaves by NE" % to)
	return true


func _e11b() -> bool:
	var rows: Array = (main.get(&"wall_rows") as Dictionary)[&"sw"]
	MissionHarness.kill([rows[0][rows[0].size() / 2], rows[1][rows[1].size() / 2]])
	return true


func _e12() -> bool:
	var l17 := h.dialogue_log.filter(func(l: String) -> bool: return l.contains("Through my glass")).size()
	h.check(l17 == 1, "L17 once")
	var keep: Node3D = main.get(&"keep")
	MissionHarness.put(_hero(), keep.global_position + Vector3(6.0, 0.0, -4.0))
	return true


func _lines_and_save() -> bool:
	var said: Array = main.get(&"said_ids")
	h.check(said == BRANCH_LINES, "line order %s" % str(said))
	for id: StringName in said:
		var n := said.count(id)
		h.check(n == 1, "%s said once" % id)
	h.check(h.dialogue_log.size() == BRANCH_LINES.size(), "dialogue log %d lines" % h.dialogue_log.size())
	var cast_text := FileAccess.get_file_as_string("res://data/voice/cast.json")
	for row: Array in Mission02.DIALOGUE:
		var sp: StringName = row[0]
		h.check(Speakers.has(sp), "speaker %s in Speakers.TABLE" % sp)
		h.check(cast_text.contains("\"%s\"" % sp), "speaker %s in cast.json" % sp)
	h.check(h.saw("obj_escape", "done") and h.saw("obj_vessa", "done"), "obj_escape / obj_vessa done")
	# The victory save (MISSION_REWARDS[&"m02"]) into a test file.
	var cs := CampaignState.open(TEST_SAVE)
	cs.reset()
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var essence := bank.essence
	h.check(cs.on_mission_victory(&"m02", main) == OK, "victory save")
	var loaded := CampaignState.open(TEST_SAVE)
	h.check(loaded.is_completed(&"m02"), "m02 completed")
	h.check(loaded.owned_artifacts().has("stillwater_orb") and loaded.owned_artifacts().has("ember_crown"), "orb + crown owned")
	h.check(loaded.equipped_artifacts().has("stillwater_orb") and loaded.equipped_artifacts().has("ember_crown"),
			"both equipped %s" % str(loaded.equipped_artifacts()))
	h.check(loaded.flag("m2_emberguard_sworn") and loaded.flag("m2_dig_under_half"), "m2 flags")
	h.check(loaded.carried_essence() == mini(1500, (essence + 300) / 2), "+300 then 50 %% (%d)" % loaded.carried_essence())
	loaded.reset()
	return true
