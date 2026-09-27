extends Node3D
## Task A2.5 preview: the Heartwood (Nature keep) epic pass, from the RTS camera (pitch 55, fov 50, rts_camera.gd),
## next to the three polished keeps. Windowed run:
##   Godot --path . res://art/preview/nature_keep_polish_preview.tscn -- --tag=after --shots
## Saves docs/art/screens/polish_naturekeep_<tag>_*.png (zooms, gate / back views, states sheet, silhouettes, the
## 4-keep lineup) and quits. Without --shots: keys 1-4 zoom, 5 lineup.

const NATURE := "res://art/buildings/nature_keep.tscn"
const LINEUP: Array[String] = ["res://art/buildings/fire_keep.tscn", "res://art/buildings/dusk_keep.tscn",
	"res://art/buildings/ice_keep.tscn", "res://art/buildings/nature_keep.tscn"]
const ORIGIN := Vector3(36.0, 0.0, -36.0) # a keep spot of the 1v1 map (ground.gdshader spot_1)
const LINE_ORIGIN := Vector3(-40.0, 0.0, 40.0)
const LINE_STEP := 17.0

var _cam: Camera3D
var _keep: Node3D # untyped hooks: the keep's script
var _tag: String = "after"
var _prefix: String = ""
var _extras: Array[Node3D] = []
var _lineup: Array[Node3D] = []
var _clock: float = 0.0
var _we: WorldEnvironment


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
	_prefix = "polish_naturekeep_%s_" % _tag
	_we = WorldEnvironment.new()
	_we.environment = load("res://art/environment/world_env.tres")
	add_child(_we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(ground)
	_extras.append(ground)
	# Scale reference: a 1.8 m capsule "worker" beside the keep.
	var cap := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	cap.mesh = cm
	var capm := StandardMaterial3D.new()
	capm.albedo_color = Color(0.8, 0.7, 0.5)
	cap.material_override = capm
	cap.position = ORIGIN + Vector3(-5.2, 0.9, 1.5)
	add_child(cap)
	_extras.append(cap)
	_keep = _spawn(NATURE, ORIGIN)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(40.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(path: String, at: Vector3) -> Node3D:
	var k: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	k.rotation.y = PI / 2.0 # like the game's east keep: gate faces -x
	k.position = at
	add_child(k)
	return k


func _process(delta: float) -> void:
	_clock += delta


func _set_zoom(z: float, focus: Vector3 = Vector3.ZERO, yaw_deg: float = 0.0, origin: Vector3 = ORIGIN) -> void:
	var pitch := deg_to_rad(55.0)
	var yaw := deg_to_rad(yaw_deg)
	var back := Vector3(sin(yaw), 0.0, cos(yaw))
	_cam.position = origin + focus + back * cos(pitch) * z + Vector3(0.0, sin(pitch) * z, 0.0)
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match (event as InputEventKey).keycode:
			KEY_1: _set_zoom(15.0, Vector3(0, 0, 3))
			KEY_2: _set_zoom(25.0, Vector3(0, 0, -2))
			KEY_3: _set_zoom(40.0)
			KEY_4: _set_zoom(55.0)
			KEY_5: _show_lineup()


func _show_lineup() -> void:
	if _lineup.is_empty():
		for i: int in LINEUP.size():
			_lineup.append(_spawn(LINEUP[i], LINE_ORIGIN + Vector3(LINE_STEP * float(i), 0, 0)))
	_set_zoom(50.0, Vector3(LINE_STEP * 1.5, 0, -2.0), 0.0, LINE_ORIGIN)


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.8)
	_set_zoom(15.0, Vector3(0, 0, 3.0))
	await _wait(0.8)
	_save("z15")
	_set_zoom(25.0, Vector3(0, 0, -1.0))
	await _wait(0.6)
	_save("z25")
	_set_zoom(40.0)
	await _wait(0.6)
	_save("z40")
	_set_zoom(50.0)
	await _wait(0.6)
	_save("z50")
	# Gate facing the camera, the other side (the west keep's view), and a 3/4 view from behind.
	_keep.rotation.y = PI
	_set_zoom(22.0, Vector3(0, 0, -1.0))
	await _wait(0.6)
	_save("gate_z22")
	_keep.rotation.y = -PI / 2.0
	_set_zoom(25.0, Vector3(0, 0, -1.0))
	await _wait(0.6)
	_save("west_z25")
	_keep.rotation.y = PI / 2.0
	_set_zoom(25.0, Vector3(0, 0, -1.0), 140.0)
	await _wait(0.6)
	_save("back_z25")
	# Draw calls with / without the keep at zoom 40.
	_set_zoom(40.0)
	await _wait(0.4)
	var dc_with: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_keep.visible = false
	await _wait(0.4)
	var dc_without: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_keep.visible = true
	await _wait(0.2)
	print("A2.5 draw calls keep = ", dc_with - dc_without, " (", dc_with, " - ", dc_without, ") fps ", Engine.get_frames_per_second())
	print("A2.5 particles idle = ", _count_particles(), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	if "--quick" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	await _state_sequence()
	await _lineup_shots()
	await _silhouette()
	get_tree().quit()


func _count_particles() -> int:
	var n: int = 0
	for p: Node in _keep.find_children("*", "GPUParticles3D", true, false):
		var g := p as GPUParticles3D
		if g.emitting and g.is_visible_in_tree():
			n += int(g.amount * g.amount_ratio)
	return n


func _state_sequence() -> void:
	_set_zoom(30.0, Vector3(0, 0, -2.0))
	var sheet: Array[Image] = []
	_keep.call(&"set_construction_progress", 0.0)
	await _wait(0.8)
	sheet.append(_save("construct00"))
	_keep.call(&"set_construction_progress", 0.5)
	await _wait(0.8)
	sheet.append(_save("construct50"))
	_keep.call(&"set_construction_progress", 1.0)
	await _wait(0.15)
	_save("construct_done_flash")
	await _wait(2.0)
	sheet.append(_save("idle"))
	_keep.call(&"set_selected", true)
	await _wait(0.4)
	_save("selected")
	_keep.call(&"set_selected", false)
	await _wait(0.4)
	_keep.call(&"play_training_pulse")
	await _wait(0.12)
	sheet.append(_save("training"))
	await _wait(0.8)
	_keep.call(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_save("hp40"))
	print("A2.5 particles hp40 = ", _count_particles())
	_keep.call(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_save("hp20"))
	var dc20: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	print("A2.5 particles hp20 = ", _count_particles(), " frame draw calls ", dc20)
	_keep.call(&"set_health_ratio", 1.0)
	await _wait(3.0)
	_save("healed")
	_keep.call(&"set_health_ratio", 0.2)
	await _wait(1.0)
	_keep.connect(&"destroyed_finished", func() -> void: print("A2.5 destroyed_finished at ", _clock))
	_clock = 0.0
	_keep.call(&"play_destroyed")
	await _wait(0.5)
	sheet.append(_save("destroyed_0s5"))
	await _wait(0.7)
	sheet.append(_save("destroyed_1s2"))
	await _wait(0.8)
	_save("destroyed_2s")
	await _wait(0.95)
	sheet.append(_save("destroyed_3s"))
	print("A2.5 particles destroyed = ", _count_particles())
	var w: int = sheet[0].get_width() / 2
	var h: int = sheet[0].get_height() / 2
	var out := Image.create(w * 5, h * 2, false, sheet[0].get_format())
	for i: int in sheet.size():
		var im: Image = sheet[i]
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % 5) * w, (i / 5) * h))
	out.save_png("res://docs/art/screens/%sstates.png" % _prefix)


## The four keeps side by side (fire, dusk, ice, nature), gate toward -x like the game's east keep.
func _lineup_shots() -> void:
	_show_lineup()
	await _wait(1.5)
	_save("lineup_z50")
	_set_zoom(34.0, Vector3(LINE_STEP * 2.5, 0, -1.0), 0.0, LINE_ORIGIN)
	await _wait(0.5)
	_save("lineup_pair_z34")
	var dc_all: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	# Draw calls of each lineup keep (hide one at a time, same view).
	_set_zoom(50.0, Vector3(LINE_STEP * 1.5, 0, -2.0), 0.0, LINE_ORIGIN)
	await _wait(0.4)
	dc_all = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var pr_all: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	for i: int in _lineup.size():
		_lineup[i].visible = false
		await _wait(0.3)
		var dc: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		_lineup[i].visible = true
		print("A2.5 lineup ", LINEUP[i].get_file(), " draw calls = ", dc_all - dc, " primitives = ", pr_all - pr)
		await _wait(0.2)


## Unlit black on white, a fresh keep (the old one is destroyed by now).
func _silhouette() -> void:
	for k: Node3D in _lineup:
		k.queue_free()
	_lineup.clear()
	_keep.queue_free()
	await _wait(0.1)
	_keep = _spawn(NATURE, ORIGIN)
	await _wait(0.5)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for n: Node in _keep.find_children("*", "GeometryInstance3D", true, false):
		if n is GPUParticles3D or n.name == "ContactDecal" or n.name == "Outline":
			(n as Node3D).visible = false
			continue
		var gi := n as GeometryInstance3D
		# Cut-out leaf cards keep their shape: only override the plain surfaces.
		gi.material_override = black
	for e: Node3D in _extras:
		e.visible = false
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	_we.environment = env
	_set_zoom(40.0)
	await _wait(0.3)
	_save("silhouette_z40")
	_keep.rotation.y = PI
	_set_zoom(30.0, Vector3.ZERO, 0.0)
	_cam.rotation = Vector3(deg_to_rad(-10.0), 0.0, 0.0)
	_cam.position = ORIGIN + Vector3(0, 7.0, 32.0)
	await _wait(0.3)
	_save("silhouette_side")


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> Image:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/%s%s.png" % [_prefix, nm])
	return img
