extends SceneTree
## Mission 3 windowed screenshot pass (not a CI test): the key moments of a scripted run on normal, saved as PNGs to
## user://shots_m3/ (the base, the Oldroot behind its thorns, the three hearts and their guardians, the tavern, a burst
## heart and its Ember Stake, the m3_oldroot card, the open tree with the Signet, Malrik carrying it, an open gate
## and its tide, the m3_parting card).
## Run (windowed):  godot --path . -s tests/shots_m3.gd --fixed-fps 60 --quit-after 20000

const SCENE := "res://missions/mission_03.tscn"
const OUT := "user://shots_m3"

var h := MissionHarness.new()
var main: Mission03
var _wait := 0


func _initialize() -> void:
	h.task_id = "shots_m3"
	h.timeout_frames = 19000
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://shots_m3_none.json",
			"flag_override": {"m1_peddler_freed": true}}}) as Mission03
	_add_look("base", Mission03.PLAYER_START, 34.0)
	h.steps.add("explore", func() -> bool:
		for id: StringName in main.hearts:
			main.fog.reveal(Unit.Team.PLAYER, (main.hearts[id] as Node3D).global_position, 12.0)
		main.fog.reveal(Unit.Team.PLAYER, Vector3.ZERO, 14.0)
		return true, 5)
	_add_look("oldroot_thorns", Vector3.ZERO, 26.0)
	_add_look("rh1_mossgate", Mission03.HEARTS[&"rh1"][1], 22.0)
	_add_look("rh2_hollowfen", Mission03.HEARTS[&"rh2"][1], 24.0)
	_add_look("rh3_stagwatch_maelis", Mission03.HEARTS[&"rh3"][1], 22.0)
	_add_look("tavern_pell", Vector3(-18.0, 0.0, -12.0), 24.0)
	h.steps.add("burn RH1", func() -> bool:
		MissionHarness.kill(main.guard_groups[&"G1"])
		(main.hearts[&"rh1"] as RootHeart).take_damage(1.0e6, main.hero)
		return true, 5)
	_add_look("rh1_burst_stake", Mission03.HEARTS[&"rh1"][1], 18.0, 40)
	h.steps.add("drain look", func() -> bool:
		MissionHarness.skip_time(main, 181.0 - main.mission_time())
		return true, 5)
	h.steps.add("thralls arrive", func() -> bool:
		if main.squads.is_empty():
			return false
		var p: Vector3 = Mission03.HEARTS[&"rh3"][1]
		var i := 0
		for t: Variant in main.squads[0]["thralls"]:
			MissionHarness.put(t, p + Vector3(cos(i * 2.1), 0.0, sin(i * 2.1)) * 2.4)
			i += 1
		MissionHarness.kill(main.guard_groups[&"G3"])
		return true, 300)
	_add_look("rh3_drained", Mission03.HEARTS[&"rh3"][1], 16.0, 300)
	h.steps.add("hearts down + card on", func() -> bool:
		main.cinematics_enabled = true
		(main.hearts[&"rh2"] as RootHeart).take_damage(1.0e6, main.hero)
		(main.hearts[&"rh3"] as RootHeart).take_damage(1.0e6, main.hero)
		return true, 5)
	h.steps.add("card up", func() -> bool: return _frames(240), 400)
	h.steps.add("shot card", func() -> bool: return _shot("08_m3_oldroot_card"), 5)
	h.steps.add("card ends", func() -> bool: return main.barrier_down and _frames(60), 3000)
	h.steps.add("cards off", func() -> bool:
		main.cinematics_enabled = false
		return true, 5)
	_add_look("oldroot_open_signet", Vector3.ZERO, 20.0, 330)
	h.steps.add("march", func() -> bool:
		MissionHarness.skip_time(main, main.muster_ends_at - main.mission_time() + 0.5)
		MissionHarness.put(main.hero, Vector3(-30.0, 0.0, 30.0))
		return main.race_phase == &"march", 200)
	h.steps.add("malrik grabs", func() -> bool:
		MissionHarness.put(main.shadow_hero, main.tree_grab_point())
		return main.signet_state == &"malrik", 200)
	h.steps.add("malrik walks", func() -> bool: return _frames(300), 400)
	h.steps.add("look malrik", func() -> bool:
		_look(main.shadow_hero.global_position, 16.0)
		return _frames(20), 100)
	h.steps.add("shot malrik", func() -> bool: return _shot("10_malrik_carry"), 5)
	h.steps.add("vessa takes", func() -> bool:
		main.shadow_hero.take_damage(1.0e7, main.hero)
		return main.signet_state == &"ground", 400)
	h.steps.add("vessa takes 2", func() -> bool:
		MissionHarness.put(main.hero, main.signet_ground + Vector3(0.4, 0.0, 0.4))
		return main.race_phase == &"over", 200)
	h.steps.add("tide", func() -> bool: return _frames(400), 600)
	h.steps.add("look gate", func() -> bool:
		_look((main.gates[&"wg2"] as Node3D).global_position, 18.0)
		return _frames(30), 100)
	h.steps.add("shot gate", func() -> bool: return _shot("11_gate_tide"), 5)
	h.steps.add("gates + parting card", func() -> bool:
		main.cinematics_enabled = true
		(main.gates[&"wg1"] as WardenGate).take_damage(1.0e9, main.hero)
		(main.gates[&"wg2"] as WardenGate).take_damage(1.0e9, main.hero)
		return true, 5)
	h.steps.add("parting up", func() -> bool: return _frames(420), 600)
	h.steps.add("shot parting", func() -> bool: return _shot("12_m3_parting_card"), 5)
	h.steps.add("victory", func() -> bool: return h.ended == 1, 4000)


var _shot_n := 0


func _add_look(name_: String, at: Vector3, zoom: float, settle := 40) -> void:
	h.steps.add("look " + name_, func() -> bool:
		_look(at, zoom)
		return _frames(settle), settle + 60)
	h.steps.add("shot " + name_, func() -> bool:
		_shot_n += 1
		return _shot("%02d_%s" % [_shot_n, name_]), 5)


func _process(_d: float) -> bool:
	return h.tick()


func _frames(n: int) -> bool:
	_wait += 1
	if _wait >= n:
		_wait = 0
		return true
	return false


func _look(at: Vector3, zoom: float) -> void:
	main.camera_rig.focus_on(at)
	main.camera_rig.set(&"_target_zoom", zoom)
	main.camera_rig.set(&"_zoom", zoom)


func _shot(name_: String) -> bool:
	var img := get_root().get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name_]
	img.save_png(path)
	print("shot ", ProjectSettings.globalize_path(path))
	return true
