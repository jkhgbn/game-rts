extends Node3D
## Preview of the Rime Keep from the RTS camera (pitch 55, fov 50 like scripts/ui/rts_camera.gd).
## Keys 1-4: zoom 15 / 25 / 40 / 55. Run with `-- --shots` to save docs/art/screens/ice_keep_z15/z40.png and quit.

const KEEP := preload("res://art/buildings/ice_keep.tscn")

var _cam: Camera3D
var _keep # untyped: the hooks live on the keep's script
var _shots: bool = false


func _ready() -> void:
	var env_path := "res://art/environment/world_env.tres"
	var we := WorldEnvironment.new()
	if ResourceLoader.exists(env_path):
		we.environment = load(env_path)
	else:
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.16, 0.18, 0.22)
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_white = 6.0
		env.glow_enabled = true
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		env.glow_intensity = 0.55
		env.glow_bloom = 0.08
		env.glow_hdr_threshold = 1.1
		env.glow_hdr_scale = 2.0
		for i: int in 7:
			env.set_glow_level(i, i == 2 or i == 4)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.45, 0.52, 0.70)
		env.ambient_light_energy = 0.35
		we.environment = env
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
	_keep = KEEP.instantiate()
	_keep.rotation.y = PI / 2.0 # same as the game: gate faces -x (the enemy side, like the Dusk Keep)
	add_child(_keep)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(40.0)
	_shots = "--shots" in OS.get_cmdline_user_args()
	if _shots:
		_take_shots()


func _set_zoom(z: float) -> void:
	var pitch := deg_to_rad(55.0)
	# At zoom 15 the focus sits 6 m in front of the keep so the keep lands in the upper third.
	var focus := Vector3(0, 0, 3.0 if z < 20.0 else (-4.0 if z < 35.0 else 0.0))
	_cam.position = focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match (event as InputEventKey).keycode:
			KEY_1: _set_zoom(15.0)
			KEY_2: _set_zoom(25.0)
			KEY_3: _set_zoom(40.0)
			KEY_4: _set_zoom(55.0)


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for z: float in [15.0, 40.0]:
		_set_zoom(z)
		await _wait(1.5)
		_save("ice_keep_z%d" % int(z))
		print("shot z", z, " fps ", Engine.get_frames_per_second())
	await _state_sequence()
	get_tree().quit()


## 3.V2 states, one screenshot each at zoom 30, plus a contact sheet ice_keep_states.png.
func _state_sequence() -> void:
	_set_zoom(30.0)
	var sheet: Array[Image] = []
	var labels: Array[String] = []
	_keep.set_construction_progress(0.0)
	await _wait(0.8)
	sheet.append(_save("ice_keep_state_construct00")); labels.append("construct00")
	_keep.set_construction_progress(0.5)
	await _wait(0.8)
	sheet.append(_save("ice_keep_state_construct50")); labels.append("construct50")
	_keep.set_construction_progress(1.0)
	await _wait(0.15)
	_save("ice_keep_state_construct_done_flash")
	await _wait(2.0)
	sheet.append(_save("ice_keep_state_idle")); labels.append("idle")
	_keep.set_selected(true)
	await _wait(0.4)
	_save("ice_keep_state_selected")
	_keep.set_selected(false)
	await _wait(0.4)
	_keep.play_training_pulse()
	await _wait(0.12)
	sheet.append(_save("ice_keep_state_training")); labels.append("training")
	await _wait(0.8)
	_keep.set_health_ratio(0.4)
	await _wait(2.5)
	sheet.append(_save("ice_keep_state_hp40")); labels.append("hp40")
	_keep.set_health_ratio(0.2)
	await _wait(2.0)
	sheet.append(_save("ice_keep_state_hp20")); labels.append("hp20")
	_keep.set_health_ratio(1.0)
	await _wait(3.6)
	_save("ice_keep_state_healed")
	_keep.set_health_ratio(0.2)
	await _wait(1.0)
	_keep.destroyed_finished.connect(func() -> void: print("destroyed_finished emitted at ", _clock))
	_clock = 0.0
	_keep.play_destroyed()
	await _wait(1.2)
	sheet.append(_save("ice_keep_state_destroyed_1s2")); labels.append("destroyed 1.2s")
	await _wait(1.8)
	sheet.append(_save("ice_keep_state_destroyed_3s")); labels.append("destroyed 3s")
	print("draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	# Contact sheet 4 x 2 at half size.
	var w: int = sheet[0].get_width() / 2
	var h: int = sheet[0].get_height() / 2
	var out := Image.create(w * 4, h * 2, false, sheet[0].get_format())
	for i: int in sheet.size():
		var im: Image = sheet[i]
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % 4) * w, (i / 4) * h))
	out.save_png("res://docs/art/screens/ice_keep_states.png")
	print("states sheet: ", labels)


var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> Image:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/%s.png" % nm)
	return img
