extends SceneTree
## Mission 4 windowed screenshot pass (not a CI test): the key moments of a scripted run on normal, saved as PNGs to
## user://shots_19_c5/ (the m4_war card, the base, the isle and its guard, the Rise with the pylons and tethers, the
## walk, the darkest hour with Old Vey, an Exposed turn of the key, the heart-stone).
## Run (windowed):  godot --path . -s tests/shots_19_c5.gd --fixed-fps 60 --quit-after 12000

const SCENE := "res://missions/mission_04.tscn"
const OUT := "user://shots_19_c5"

var h := MissionHarness.new()
var main: Mission04
var _n := 0
var _wait := 0


func _initialize() -> void:
	h.task_id = "shots_19_c5"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://shots_19_c5_none.json"}}) as Mission04
	main.cinematics_enabled = true   # the m4_war card plays at the start (PAUSE)
	h.steps.add("card up", func() -> bool: return _frames(90), 200)
	h.steps.add("shot m4_war card", func() -> bool: return _shot("01_m4_war_card"), 5)
	h.steps.add("skip card", func() -> bool:
		CinematicPlayer.instance(self).skip()   # an unfocused window pauses the card
		return true, 5)
	h.steps.add("card ends", func() -> bool: return main.has_fired(&"E1") and not paused \
			and _frames(60), 3000)
	h.steps.add("cards off", func() -> bool:
		main.cinematics_enabled = false
		_look(Vector3(-36.0, 0.0, 36.0), 34.0)
		return true, 5)
	h.steps.add("settle", func() -> bool: return _frames(40), 100)
	h.steps.add("shot base", func() -> bool: return _shot("02_base"), 5)
	h.steps.add("isle", func() -> bool:
		_look(Vector3.ZERO, 26.0)
		MissionHarness.put(main.hero, Vector3(-9.0, 0.0, 9.0))
		return true, 5)
	h.steps.add("settle 2", func() -> bool: return _frames(40), 100)
	h.steps.add("shot isle", func() -> bool: return _shot("03_isle_guard"), 5)
	h.steps.add("clear + sit", func() -> bool:
		MissionHarness.kill(main.isle_guard)
		MissionHarness.put(main.hero, Vector3.ZERO)
		return main.phase == 1, 600)
	h.steps.add("rise settle", func() -> bool:
		_look(Vector3(-4.0, 0.0, 4.0), 46.0)
		return _frames(90), 200)
	h.steps.add("shot rise", func() -> bool: return _shot("04_rise_pylons"), 5)
	h.steps.add("close colossus", func() -> bool:
		_look(Vector3(-2.0, 0.0, 6.0), 22.0)
		return _frames(30), 100)
	h.steps.add("shot colossus", func() -> bool: return _shot("05_colossus_ward"), 5)
	h.steps.add("break pylons", func() -> bool:
		for p in main.keystone.pylons:
			if is_instance_valid(p) and p.is_alive():
				p.take_damage(1.0e7, main.hero)
		return main.phase == 2, 300)
	h.steps.add("walk", func() -> bool:
		MissionHarness.put(main.hero, Vector3(-26.0, 0.0, 26.0))
		return MissionBase._flat(main.keystone.colossus.global_position, Vector3.ZERO) > 9.0, 4000)
	h.steps.add("walk look", func() -> bool:
		_look(main.keystone.colossus.global_position, 30.0)
		return _frames(30), 100)
	h.steps.add("shot walk", func() -> bool: return _shot("06_walk"), 5)
	h.steps.add("darkest", func() -> bool:
		var c := main.keystone.colossus
		c.take_damage((c.hp - c.max_hp * 0.38) / c.damage_mult() / Unit.armor_multiplier(25.0), main.hero)
		return main.phase == 3, 600)
	h.steps.add("key spot", func() -> bool:
		var c := main.keystone.colossus
		MissionHarness.put(main.hero, c.global_position + Vector3(-5.0, 0.0, 2.0))
		_look(c.global_position, 24.0)
		return main.keystone.exposures >= 1, 2000)
	h.steps.add("shot exposed", func() -> bool: return _frames(20) and _shot("07_exposed_vey"), 60)
	h.steps.add("fall", func() -> bool:
		var c := main.keystone.colossus
		if c.is_alive():
			c.set_exposed(true)
			c.take_damage(1.0e7, main.hero)
		return h.ended == 1, 300)
	h.steps.add("stone look", func() -> bool:
		_look(main.heart_stone.global_position, 12.0)
		return _frames(60), 100)
	h.steps.add("shot heart", func() -> bool: return _shot("08_heart_stone"), 5)


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
