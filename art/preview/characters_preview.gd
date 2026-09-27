extends Node3D
## Character preview (4.V1): Vessa and Malrik from the RTS camera (pitch 55, fov 50).
## Keys: 1-4 zoom 8 / 15 / 25 / 40 · A attack · C cast 1-3 cycle · H hit · D death · R revive · L level-up · W walk toggle.
## `-- --shots`: docs/art/screens/char_wizards_*.png then quit. `-- --test` (headless ok): hook test, prints CHAR TEST OK.

const SCENES: Array[String] = ["res://art/units/wizards/vessa.tscn", "res://art/units/wizards/malrik.tscn"]
const CASTS: Array = [[&"fireball", &"ember_step", &"kindle"], [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]]

var _cam: Camera3D
var _models: Array = []   # untyped: hooks live on the model scripts
var _cast_i: int = 0
var _walking: bool = false
var _clock: float = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_setup_world()
	for i: int in SCENES.size():
		var m: Node3D = load(SCENES[i]).instantiate()
		m.position = Vector3(-1.4 + 2.8 * i, 0, 0)
		add_child(m)
		_models.append(m)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(15.0)
	if "--test" in args:
		_run_test()
	elif "--shots" in args:
		_take_shots()


func _setup_world() -> void:
	var we := WorldEnvironment.new()
	we.environment = load("res://art/environment/world_env.tres")
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.24, 0.27, 0.20)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)


func _set_zoom(z: float, focus: Vector3 = Vector3(0, 1.0, 0)) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _process(delta: float) -> void:
	_clock += delta


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(8.0)
		KEY_2: _set_zoom(15.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L: _all(&"play_level_up")
		KEY_W:
			_walking = not _walking
			for m in _models:
				m.set_moving(4.5 if _walking else 0.0)
		KEY_C:
			for i: int in _models.size():
				_models[i].play_cast(CASTS[i][_cast_i])
			_cast_i = (_cast_i + 1) % 3


func _all(method: StringName) -> void:
	for m in _models:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.5)
	for z: float in [15.0, 40.0]:
		_set_zoom(z)
		await _wait(0.8)
		_save("char_wizards_z%d" % int(z))
	# Close-up at rest (detail check), then the 3 casts at their peak frame, a walk, a hit and deaths.
	_set_zoom(7.0, Vector3(0, 1.3, 0))
	await _wait(0.6)
	var sheet: Array[Image] = [_save("char_wizards_close")]
	var peaks: Array[float] = [0.24, 0.12, 0.35]
	for c: int in 3:
		for i: int in _models.size():
			_models[i].play_cast(CASTS[i][c])
		await _wait(peaks[c])
		sheet.append(_save("char_wizards_cast%d" % (c + 1)))
		await _wait(1.0)
	_all(&"play_attack")
	await _wait(0.1)
	sheet.append(_save("char_wizards_attack"))
	await _wait(0.6)
	for m in _models:
		m.set_moving(4.5)
	await _wait(0.9)
	sheet.append(_save("char_wizards_walk"))
	for m in _models:
		m.set_moving(0.0)
	await _wait(0.5)
	_all(&"play_hit")
	await _wait(0.05)
	sheet.append(_save("char_wizards_hit"))
	await _wait(0.5)
	_all(&"play_level_up")
	await _wait(0.12)
	sheet.append(_save("char_wizards_levelup"))
	await _wait(0.6)
	_all(&"play_death")
	for t: float in [0.3, 0.3, 0.3]:
		await _wait(t)
		sheet.append(_save("char_wizards_death_%d" % int(round(_death_clock() * 10.0))))
	await _wait(0.5)
	_all(&"revive")
	await _wait(0.5)
	sheet.append(_save("char_wizards_revived"))
	_contact(sheet, "char_wizards_sheet")
	print("draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " fps ", Engine.get_frames_per_second())
	get_tree().quit()


func _death_clock() -> float:
	return _models[0]._death_t


func _contact(imgs: Array[Image], nm: String) -> void:
	var cols := 4
	var w: int = imgs[0].get_width() / 2
	var h: int = imgs[0].get_height() / 2
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, imgs[0].get_format())
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png("res://docs/art/screens/%s.png" % nm)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> Image:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/%s.png" % nm)
	return img


# ---------------------------------------------------------------- headless hook test

func _run_test() -> void:
	var ok := true
	await _wait(0.2)
	for i: int in _models.size():
		var m = _models[i]
		var nm: String = m.name
		var inst := 0
		var meshes := 0
		for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
			inst += 1
			if n is MeshInstance3D or n is MultiMeshInstance3D:
				meshes += 1
		print(nm, ": geometry instances after merge ", inst, " (meshes ", meshes, "), lights ", m.find_children("*", "OmniLight3D", true, false).size())
		m.set_team_color(m.kingdom_color)
		m.set_moving(4.0)
		await _wait(0.3)
		m.play_attack()
		await _wait(0.5)
		for s: StringName in CASTS[i]:
			m.play_cast(s)
			await _wait(0.95)
		m.play_hit()
		m.play_level_up()
		ok = ok and m.set_status(&"haste", true) and not m.set_status(&"burn", true)
		m.set_status(&"haste", false)
		m.set_moving(0.0)
		await _wait(0.5)
		var got := [false]
		m.death_finished.connect(func() -> void: got[0] = true, CONNECT_ONE_SHOT)
		m.play_death()
		await _wait(1.2)
		if not got[0]:
			push_error("%s: death_finished not emitted" % nm)
			ok = false
		m.revive()
		await _wait(0.2)
		if absf(m.get_node("Root").position.y) > 0.05 or not m.is_processing():
			push_error("%s: revive did not reset" % nm)
			ok = false
	# A second instance of each type must reuse the merged meshes.
	var again: Node3D = load(SCENES[0]).instantiate()
	add_child(again)
	await _wait(0.1)
	var shared: bool = again.get_node("Root/Chest/Merged").mesh == _models[0].get_node("Root/Chest/Merged").mesh
	print("merged mesh shared between instances: ", shared)
	ok = ok and shared
	# Animation cost: 100 walking Vessas (middle tier headless), process time per frame.
	var bench: Array[Node3D] = []
	for k: int in 100:
		var b: Node3D = load(SCENES[k % 2]).instantiate()
		b.position = Vector3(float(k % 10) * 1.5, 0, 10.0 + float(k / 10) * 1.5)
		add_child(b)
		b.call(&"set_moving", 4.0 if k % 2 == 0 else 0.0)
		bench.append(b)
	await _wait(0.5)
	var acc := 0.0
	var frames := 0
	var t0 := Time.get_ticks_usec()
	while frames < 120:
		await get_tree().process_frame
		acc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	print("100 models: avg TIME_PROCESS %.3f ms / frame (whole scene), wall %.1f ms" % [acc / frames, (Time.get_ticks_usec() - t0) / 1000.0])
	print("CHAR TEST OK" if ok else "CHAR TEST FAILED")
	get_tree().quit()
