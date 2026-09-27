extends Node3D
## Preview of the Shadow army + Ruin Warden (task 4.V3) from the RTS camera (pitch 55, fov 50).
## Keys 1-4: zoom 15 / 25 / 40 / 55, A = attack all, D = death all, M = walk toggle.
## Run with `-- --shots` to save docs/art/screens/char_shadow_*.png and quit.

const SCENES: Array[String] = [
	"res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/shade.tscn",
	"res://art/units/shadow/nightbolt.tscn",
	"res://art/units/shadow/grave_hound.tscn",
	"res://art/units/shadow/shadow_knight.tscn",
	"res://art/units/neutral/ruin_warden.tscn",
]
const SPEEDS: Array[float] = [3.2, 4.8, 4.2, 6.0, 3.6, 4.0]
const SHADOW_COLOR := Color(0.42, 0.22, 0.60)
const GROUP_CENTER := Vector3(40, 0, 0)

var _cam: Camera3D
var _row: Array = []
var _group: Array = []
var _walking: bool = false


func _ready() -> void:
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
	pm.size = Vector2(300, 300)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.26, 0.29, 0.21)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	# The row: one of each, 2.6 m apart, facing the camera (+Z).
	for i: int in SCENES.size():
		var m = _spawn(i, Vector3((i - 2.5) * 2.6, 0, 0), 0.0)
		_row.append(m)
	# A mixed group of 20 at GROUP_CENTER, facing a diagonal "enemy" to the lower right.
	var mix: Array[int] = [0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 1, 2, 3, 0]
	for k: int in mix.size():
		var gx := (k % 5) * 1.7 - 3.4 + (0.4 if (k / 5) % 2 == 1 else 0.0)
		var gz := (k / 5) * 1.8 - 2.7
		var m = _spawn(mix[k], GROUP_CENTER + Vector3(gx, 0, gz), atan2(0.6, 1.0))
		_group.append(m)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(25.0, Vector3.ZERO)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(kind: int, pos: Vector3, yaw: float):
	var holder := Node3D.new() # stands in for Unit._visual (facing lives here)
	holder.position = pos
	holder.rotation.y = yaw
	add_child(holder)
	var m = (load(SCENES[kind]) as PackedScene).instantiate()
	if m.has_method(&"set_team_color"):
		m.set_team_color(SHADOW_COLOR)
	holder.add_child(m)
	m.set_meta(&"speed", SPEEDS[kind])
	return m


func _set_zoom(z: float, focus: Vector3) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _all(list: Array, method: StringName, args: Array = []) -> void:
	for m in list:
		if is_instance_valid(m) and m.has_method(method):
			m.callv(method, args)


func _set_walk(list: Array, on: bool) -> void:
	for m in list:
		if m.has_method(&"set_moving"):
			m.set_moving(float(m.get_meta(&"speed")) if on else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match (event as InputEventKey).physical_keycode:
			KEY_1: _set_zoom(15.0, Vector3(0, 0, 2))
			KEY_2: _set_zoom(25.0, Vector3.ZERO)
			KEY_3: _set_zoom(40.0, Vector3(10, 0, 0))
			KEY_4: _set_zoom(55.0, Vector3(15, 0, 0))
			KEY_A: _all(_row, &"play_attack"); _all(_group, &"play_attack")
			KEY_D: _all(_row, &"play_death")
			KEY_M:
				_walking = not _walking
				_set_walk(_row, _walking)
				_set_walk(_group, _walking)


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	# The thrall at the row carries crystals; the group's thralls mine.
	_all([_row[0]], &"set_carrying", [true])
	await _wait(1.0)
	_set_zoom(15.0, Vector3(0, 0, 1.5))
	await _wait(1.2)
	_save("char_shadow_z15")
	_all(_row, &"play_attack")
	await _wait(0.09)
	_save("char_shadow_attack_z15")
	await _wait(1.2)
	_set_walk(_row, true)
	await _wait(0.8)
	_save("char_shadow_walk_z15")
	_set_walk(_row, false)
	await _wait(0.5)
	_set_zoom(40.0, Vector3(0, 0, 0))
	await _wait(1.0)
	_save("char_shadow_z40")
	# The 20-unit mixed group, walking, at 40 m and 15 m.
	_set_walk(_group, true)
	_set_zoom(40.0, GROUP_CENTER)
	await _wait(1.2)
	_save("char_shadow_group20_z40")
	print("group20 fps ", Engine.get_frames_per_second(), " draw calls ",
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" objects ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_set_zoom(18.0, GROUP_CENTER + Vector3(0, 0, 1))
	_all(_group, &"play_attack")
	await _wait(0.1)
	_save("char_shadow_group20_z18")
	_set_walk(_group, false)
	# Deaths at 0.5 s (sink / crumble).
	_set_zoom(15.0, Vector3(0, 0, 1.5))
	await _wait(1.0)
	var done: Array[int] = [0]
	for m in _row:
		if m.has_signal(&"death_finished"):
			m.death_finished.connect(func() -> void: done[0] += 1)
	_all(_row, &"play_death")
	await _wait(0.5)
	_save("char_shadow_death_z15")
	await _wait(1.3)
	print("death_finished emitted by ", done[0], " / ", _row.size())
	get_tree().quit()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/%s.png" % nm)
	print("saved ", nm)
