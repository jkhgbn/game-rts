extends SceneTree
## Mission 3 scripted DEFEATS (docs/design/mission-03.md "Win / lose", checks 5): (a) the hearts fall to Shadow, the
## muster ends, Malrik takes the Signet and carries it within 8 m of the Dusk Keep: E15, obj_signet failed, defeat
## 3 s later, no victory save; (b) `-- --vessa`: Vessa falls: E14, L18, obj_vessa failed, defeat.
## Run:  godot --headless --path . -s tests/test_m3_defeat.gd --fixed-fps 60 --quit-after 12000 [-- --vessa]

const SCENE := "res://missions/mission_03.tscn"

var h := MissionHarness.new()
var main: Mission03
var vessa := false
var _wait := 0


func _initialize() -> void:
	vessa = OS.get_cmdline_user_args().has("--vessa")
	h.task_id = "m3.defeat" + ("/vessa" if vessa else "/signet")
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://test_m3_defeat_none.json"}}) as Mission03
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	if vessa:
		h.steps.add("Vessa falls", func() -> bool:
			h.protect_hero = false
			main.hero.take_damage(1.0e7, null)
			return true, 10)
		h.steps.add("defeat", func() -> bool: return h.ended == 0, 600)
		h.steps.add("E14 state", func() -> bool:
			h.check(main.has_fired(&"E14") and main.said_ids.has(&"L18") and h.saw("obj_vessa", "failed"), "E14, L18")
			return true, 10)
		return
	h.steps.add("hearts fall to Shadow", _hearts, 10)
	h.steps.add("muster ends", func() -> bool:
		MissionHarness.skip_time(main, main.muster_ends_at - main.mission_time() + 0.5)
		return true, 10)
	h.steps.add("march", func() -> bool: return main.race_phase == &"march", 200)
	h.steps.add("Malrik takes it", func() -> bool:
		MissionHarness.put(main.hero, Vector3(-40.0, 0.0, 40.0))
		MissionHarness.put(main.shadow_hero, main.tree_grab_point())
		return main.signet_state == &"malrik", 200)
	h.steps.add("Malrik home", func() -> bool:
		MissionHarness.immortal(main.shadow_hero)
		MissionHarness.put(main.shadow_hero, Mission03.DUSK_KEEP_POS + Vector3(-6.5, 0.0, 2.0))
		return main.has_fired(&"E15"), 200)
	h.steps.add("defeat", func() -> bool: return h.ended == 0, 600)
	h.steps.add("E15 state", func() -> bool:
		h.check(h.saw("obj_signet", "failed"), "obj_signet failed")
		h.check(not main.signet_taken_by_vessa, "no Signet for Vessa")
		return true, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _hearts() -> bool:
	var thrall: Unit = main.make_unit("gloom_thrall")
	main._spawn(thrall, Unit.Team.ENEMY, Vector3(40.0, 0.0, -40.0))
	for id: StringName in main.hearts:
		(main.hearts[id] as RootHeart).take_damage(1.0e6, thrall)
	h.check(main.hearts_down == 3 and main.stakes.is_empty(), "3 hearts down by Shadow, no stake")
	h.check(objective_state_never("sec_stakes"), "sec_stakes never offered")
	h.check(main.race_phase == &"muster", "the race musters")
	return true


func objective_state_never(id: String) -> bool:
	for e in h.objective_log:
		if e.begins_with(id + "="):
			return false
	return true
