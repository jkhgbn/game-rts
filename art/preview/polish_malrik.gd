extends Node3D
## Polish preview for Malrik (task A.2) from the RTS camera (pitch 55, fov 50), on the real painted ground.
## Keys: 1-4 zoom 6 / 12 / 25 / 45 · A attack · C cast 1-3 cycle · H hit · D death · R revive · L level-up · W walk.
## Windowed `-- --shots <tag>` (use --fixed-fps 60): docs/art/screens/polish_malrik_<tag>_*.png then quit.
## `-- --test` (headless ok): hook test + cost numbers, prints POLISH MALRIK OK.

const MALRIK := "res://art/units/wizards/malrik.tscn"
const SHADE := "res://art/units/shadow/shade.tscn"
const VESSA := "res://art/units/wizards/vessa.tscn"
const CASTS: Array[StringName] = [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]

var _cam: Camera3D
var _front: Node3D          # 3/4 front view
var _back: Node3D           # back view
var _extras: Array[Node3D] = []
var _cast_i: int = 0
var _walking: bool = false
var _tag: String = "x"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_setup_world()
	_front = _spawn(MALRIK, Vector3(0, 0, 0), 0.45)
	_back = _spawn(MALRIK, Vector3(2.4, 0, -0.6), PI + 0.5)
	_extras.append(_spawn(SHADE, Vector3(-2.0, 0, 0.4), 0.3))
	_extras.append(_spawn(VESSA, Vector3(-4.2, 0, -0.4), 0.3))
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(12.0)
	var i := args.find("--shots")
	if i >= 0:
		if i + 1 < args.size():
			_tag = args[i + 1]
		_take_shots()
	elif "--test" in args:
		_run_test()


func _spawn(path: String, p: Vector3, yaw: float) -> Node3D:
	var m: Node3D = (load(path) as PackedScene).instantiate()
	m.position = p
	m.rotation.y = yaw
	add_child(m)
	return m


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
	var gm := load("res://art/environment/ground_material.tres") as ShaderMaterial
	if gm:
		gm = gm.duplicate() as ShaderMaterial
		gm.set_shader_parameter(&"lane_a", Vector2(-40, 3.2))
		gm.set_shader_parameter(&"lane_b", Vector2(40, 3.2))
		for s: int in 4:
			gm.set_shader_parameter(StringName("spot_%d" % s), Vector4.ZERO)
		ground.material_override = gm
	else:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.24, 0.27, 0.20)
		ground.material_override = sm
	add_child(ground)


func _set_zoom(z: float, focus: Vector3 = Vector3(0.4, 1.0, 0)) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(6.0, Vector3(0, 1.4, 0))
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(45.0)
		KEY_A: _both(&"play_attack")
		KEY_H: _both(&"play_hit")
		KEY_D: _both(&"play_death")
		KEY_R: _both(&"revive")
		KEY_L: _both(&"play_level_up")
		KEY_W:
			_walking = not _walking
			_front.call(&"set_moving", 3.2 if _walking else 0.0)
			_back.call(&"set_moving", 3.2 if _walking else 0.0)
		KEY_C:
			_front.call(&"play_cast", CASTS[_cast_i])
			_back.call(&"play_cast", CASTS[_cast_i])
			_cast_i = (_cast_i + 1) % 3


func _both(method: StringName) -> void:
	_front.call(method)
	_back.call(method)


# ---------------------------------------------------------------- screenshots

func _frames(n: int) -> void:
	for k: int in n:
		await get_tree().process_frame


func _secs(s: float) -> void:
	await _frames(maxi(1, int(round(s * 60.0))))


func _save(nm: String) -> Image:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/polish_malrik_%s_%s.png" % [_tag, nm])
	return img


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _secs(1.2)
	for z: float in [12.0, 25.0, 45.0]:
		_set_zoom(z)
		await _secs(0.5)
		_save("z%d" % int(z))
	# Close-up (detail check) at 6 m.
	_set_zoom(6.0, Vector3(0.6, 1.5, 0))
	await _secs(0.4)
	_save("close")
	_set_zoom(3.2, Vector3(0.1, 1.9, 0.1))
	await _secs(0.3)
	_save("face")
	_set_zoom(12.0)
	await _secs(0.3)
	var sheet: Array[Image] = []
	# Walk (two phases)
	_front.call(&"set_moving", 3.2)
	_back.call(&"set_moving", 3.2)
	await _secs(0.8)
	sheet.append(_save("walk_a"))
	await _secs(0.28)
	sheet.append(_save("walk_b"))
	_front.call(&"set_moving", 0.0)
	_back.call(&"set_moving", 0.0)
	await _secs(0.8)
	# Attack at the release frame
	_both(&"play_attack")
	await _secs(0.12)
	sheet.append(_save("attack"))
	await _secs(0.8)
	# Casts: two frames each (build-up and peak)
	var peaks: Array = [[0.15, 0.30], [0.25, 0.55], [0.22, 0.50]]
	for c: int in 3:
		_front.call(&"play_cast", CASTS[c])
		_back.call(&"play_cast", CASTS[c])
		var done := 0.0
		for p: float in peaks[c]:
			await _secs(p - done)
			done = p
			sheet.append(_save("cast%d_%d" % [c + 1, int(p * 100.0)]))
		await _secs(1.2)
	_both(&"play_hit")
	await _secs(0.05)
	sheet.append(_save("hit"))
	await _secs(0.6)
	_both(&"play_death")
	var dt := 0.0
	for t: float in [0.3, 0.55, 0.8]:
		await _secs(t - dt)
		dt = t
		sheet.append(_save("death_%d" % int(t * 100.0)))
	await _secs(0.6)
	_both(&"revive")
	await _secs(0.5)
	sheet.append(_save("revived"))
	_contact(sheet, "sheet")
	# Close-up cast frames at 7 m for the body language.
	_set_zoom(7.0, Vector3(0.4, 1.4, 0))
	var close_sheet: Array[Image] = []
	await _secs(0.5)
	close_sheet.append(_save("close_idle"))
	for c: int in 3:
		_front.call(&"play_cast", CASTS[c])
		await _secs(peaks[c][1])
		close_sheet.append(_save("close_cast%d" % (c + 1)))
		await _secs(1.2)
	_front.call(&"play_attack")
	await _secs(0.12)
	close_sheet.append(_save("close_attack"))
	await _secs(0.8)
	_front.call(&"play_death")
	await _secs(0.5)
	close_sheet.append(_save("close_death"))
	await _secs(0.8)
	_front.call(&"revive")
	_contact(close_sheet, "close_sheet")
	# Side view (facing screen right): casts, attack and death read in profile.
	_front.rotation.y = PI * 0.5
	await _secs(0.4)
	var side: Array[Image] = [_save("side_idle")]
	for c: int in 3:
		_front.call(&"play_cast", CASTS[c])
		await _secs(peaks[c][1])
		side.append(_save("side_cast%d" % (c + 1)))
		await _secs(1.2)
	_front.call(&"play_attack")
	await _secs(0.14)
	side.append(_save("side_attack"))
	await _secs(0.8)
	_front.call(&"set_moving", 3.2)
	await _secs(0.9)
	side.append(_save("side_walk"))
	_front.call(&"set_moving", 0.0)
	await _secs(0.6)
	_front.call(&"play_death")
	await _secs(0.35)
	side.append(_save("side_death35"))
	await _secs(0.3)
	side.append(_save("side_death65"))
	await _secs(0.8)
	_front.call(&"revive")
	_front.rotation.y = 0.45
	_contact(side, "side_sheet")
	# Silhouette: black on white at 25 m.
	await _silhouette()
	print("draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " fps ", Engine.get_frames_per_second())
	get_tree().quit()


func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	for n: Node in get_children():
		if n is WorldEnvironment:
			var env := Environment.new()
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color.WHITE
			(n as WorldEnvironment).environment = env
		elif n is DirectionalLight3D:
			(n as DirectionalLight3D).visible = false
		elif n is MeshInstance3D:
			(n as MeshInstance3D).material_override = white
	for m: Node3D in [_front, _back] + _extras:
		for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
			if g.name == "Shadow" or g is GPUParticles3D:
				(g as GeometryInstance3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
		for l: Node in m.find_children("*", "Light3D", true, false):
			(l as Light3D).visible = false
	for z: float in [25.0, 45.0]:
		_set_zoom(z)
		await _secs(0.3)
		_save("silhouette_z%d" % int(z))


func _contact(imgs: Array[Image], nm: String) -> void:
	var cols := 4
	var w: int = imgs[0].get_width() / 2
	var h: int = imgs[0].get_height() / 2
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, imgs[0].get_format())
	for i: int in imgs.size():
		var im: Image = imgs[i].duplicate()
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png("res://docs/art/screens/polish_malrik_%s_%s.png" % [_tag, nm])


# ---------------------------------------------------------------- headless hook test

func _run_test() -> void:
	var ok := true
	await _secs(0.2)
	var m = _front
	var inst := 0
	var verts := 0
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if not (n as GeometryInstance3D).visible:
			continue
		inst += 1
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mesh: Mesh = (n as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				verts += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var parts := 0
	for n: Node in m.find_children("*", "GPUParticles3D", true, false):
		parts += (n as GPUParticles3D).amount
	print("Malrik: geometry instances ", inst, ", vertices ", verts, ", lights ",
		m.find_children("*", "OmniLight3D", true, false).size(), ", particles ", parts)
	m.set_team_color(m.kingdom_color)
	m.set_moving(3.2)
	await _secs(0.6)
	m.play_attack()
	await _secs(0.6)
	for s: StringName in CASTS:
		m.play_cast(s)
		await _secs(1.0)
	m.play_cast(&"unknown_spell")
	await _secs(1.0)
	m.play_hit()
	m.play_level_up()
	ok = ok and m.set_status(&"haste", true) and m.set_status(&"shroud", true) and not m.set_status(&"burn", true)
	m.set_status(&"haste", false)
	m.set_status(&"shroud", false)
	m.set_moving(0.0)
	await _secs(0.5)
	var got := [false]
	m.death_finished.connect(func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.play_death()
	await _secs(1.2)
	if not got[0]:
		push_error("Malrik: death_finished not emitted")
		ok = false
	m.revive()
	await _secs(0.2)
	if absf(m.get_node("Root").position.y) > 0.05 or not m.is_processing():
		push_error("Malrik: revive did not reset")
		ok = false
	# Mirror match colour: must not error.
	var mirror: Node3D = (load(MALRIK) as PackedScene).instantiate()
	mirror.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	add_child(mirror)
	await _secs(0.1)
	var shared: bool = mirror.get_node("Root/Chest/Merged").mesh == _front.get_node("Root/Chest/Merged").mesh
	print("merged mesh shared between instances: ", shared)
	ok = ok and shared
	# Animation cost: 40 Malriks (walking / idle / casting), middle tier headless.
	var bench: Array[Node3D] = []
	for k: int in 40:
		var b: Node3D = (load(MALRIK) as PackedScene).instantiate()
		b.position = Vector3(float(k % 8) * 1.5, 0, 10.0 + float(k / 8) * 1.5)
		add_child(b)
		b.call(&"set_moving", 3.2 if k % 2 == 0 else 0.0)
		bench.append(b)
	await _secs(0.5)
	var acc := 0.0
	var frames := 0
	var t0 := Time.get_ticks_usec()
	while frames < 120:
		if frames % 30 == 0:
			for k: int in range(1, 40, 4):
				bench[k].call(&"play_cast", CASTS[(frames / 30 + k) % 3])
		await get_tree().process_frame
		acc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	print("40 Malriks: avg TIME_PROCESS %.3f ms / frame (whole scene), wall %.2f ms / frame" % [acc / frames * 1000.0,
		(Time.get_ticks_usec() - t0) / 1000.0 / frames])
	# Baseline: the same with 40 Vessas.
	for b: Node3D in bench:
		b.queue_free()
	bench.clear()
	for k: int in 40:
		var b: Node3D = (load(VESSA) as PackedScene).instantiate()
		b.position = Vector3(float(k % 8) * 1.5, 0, 10.0 + float(k / 8) * 1.5)
		add_child(b)
		b.call(&"set_moving", 3.2 if k % 2 == 0 else 0.0)
		bench.append(b)
	await _secs(0.5)
	acc = 0.0
	frames = 0
	t0 = Time.get_ticks_usec()
	while frames < 120:
		await get_tree().process_frame
		acc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	print("40 Vessas (baseline): avg TIME_PROCESS %.3f ms / frame, wall %.2f ms / frame" % [acc / frames * 1000.0,
		(Time.get_ticks_usec() - t0) / 1000.0 / frames])
	print("POLISH MALRIK OK" if ok else "POLISH MALRIK FAILED")
	get_tree().quit()
