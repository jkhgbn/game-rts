extends Node3D
## Fire army preview (task 4.V2) from the RTS camera (pitch 55, fov 50).
## Windowed: `-- --shots` saves docs/art/screens/char_fire_*.png and quits.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up + veterancy 4, 5 carry toggle, 6 mine, 7 walk toggle, wheel = zoom.

const IDS: Array[String] = ["cinder_hand", "flame_guard", "ember_archer", "blaze_rider", "ash_hurler"]
const SPEEDS: Array[float] = [4.6, 5.0, 5.2, 7.5, 4.0]

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 0.8, 0)
var _cam: Camera3D
var _row: Array[Node3D] = []
var _group: Array[Node3D] = []
var _walking: bool = false
var _carry: bool = false


func _ready() -> void:
	var env := WorldEnvironment.new()
	if ResourceLoader.exists("res://art/environment/world_env.tres"):
		env.environment = load("res://art/environment/world_env.tres")
	else:
		env.environment = Environment.new()
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.36, 0.40, 0.26)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	for i: int in IDS.size():
		var u := _spawn(IDS[i], Vector3((i - 2) * 2.2, 0, 0), 0.0)
		_row.append(u)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(id: String, at: Vector3, yaw: float) -> Node3D:
	var u := (load("res://art/units/fire/%s.tscn" % id) as PackedScene).instantiate() as Node3D
	u.position = at
	u.rotation.y = yaw
	add_child(u)
	u.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	return u


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _all(method: StringName, args: Array = []) -> void:
	for u: Node3D in _row + _group:
		if is_instance_valid(u) and u.has_method(method):
			u.callv(method, args)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 8.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 8.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1: _all(&"play_attack")
			KEY_2: _all(&"play_hit")
			KEY_3: _all(&"play_death")
			KEY_4:
				_all(&"play_level_up")
				_all(&"set_veterancy", [4])
			KEY_5:
				_carry = not _carry
				_all(&"set_carrying", [_carry])
			KEY_6: _all(&"play_mine")
			KEY_7:
				_walking = not _walking
				for i: int in _row.size():
					_row[i].call(&"set_moving", SPEEDS[i] if _walking else 0.0)


func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" process_ms=", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.0)
	# 1) Row at zoom 15 and 40 (idle; the worker carries, the guard is veteran 4).
	_row[0].call(&"set_carrying", true)
	_row[1].call(&"set_veterancy", 4)
	zoom = 15.0
	focus = Vector3(0, 0.8, 0)
	_apply()
	await _wait(1.0)
	_save("char_fire_z15")
	zoom = 40.0
	_apply()
	await _wait(0.8)
	_save("char_fire_z40")
	if "--close" in OS.get_cmdline_user_args():
		for i: int in _row.size():
			zoom = 5.5
			focus = _row[i].position + Vector3(0, 0.9, 0)
			_apply()
			await _wait(0.3)
			_save("char_fire_close_%s" % IDS[i])
		get_tree().quit()
		return
	focus = Vector3(0, 0.8, 0)
	# 2) Walk cycle mid-stride (zoom 12, rider gallops at base speed).
	zoom = 12.0
	_apply()
	for i: int in _row.size():
		_row[i].call(&"set_moving", SPEEDS[i])
	await _wait(0.9)
	_save("char_fire_walk_z12")
	for u: Node3D in _row:
		u.call(&"set_moving", 0.0)
	await _wait(0.5)
	# 3) Attack frames: guard/rider at the strike (0.10 s), archer/hurler at the release (0.14 s), worker mine.
	for u: Node3D in _row:
		u.call(&"play_attack")
	await _wait(0.13)
	_save("char_fire_attack_z12")
	await _wait(1.0)
	_row[0].call(&"play_mine")
	await _wait(0.33)
	_save("char_fire_mine_z12")
	await _wait(1.5)
	# 4) Death at 0.5 s.
	for u: Node3D in _row:
		u.call(&"play_death")
	await _wait(0.5)
	_save("char_fire_death_z12")
	await _wait(1.0)
	for u: Node3D in _row:
		u.queue_free()
	_row.clear()
	# 5) Group of 20 mixed units, a loose blob, facing a marker at +Z (some walking).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var marker := Vector3(0, 0, 12)
	for i: int in 20:
		var id: String = IDS[[1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 3, 3, 3, 0, 0, 1, 2, 3, 4][i]]
		var at := Vector3(rng.randf_range(-5.0, 5.0), 0, rng.randf_range(-3.5, 3.5))
		var d: Vector3 = marker - at
		var u := _spawn(id, at, atan2(d.x, d.z))
		_group.append(u)
		if i % 3 == 0:
			u.call(&"set_moving", 5.0)
	focus = Vector3(0, 0, 0)
	zoom = 40.0
	_apply()
	await _wait(1.2)
	_save("char_fire_group20_z40")
	zoom = 22.0
	_apply()
	await _wait(0.6)
	_save("char_fire_group20_z22")
	# 6) 200 units for the frame budget (zoom 40): fps + process time.
	for i: int in 180:
		var id2: String = IDS[i % 5]
		var at2 := Vector3(-24.0 + (i % 30) * 1.6, 0, -14.0 + (i / 30) * 1.8)
		var u2 := _spawn(id2, at2, 0.0)
		_group.append(u2)
		if i % 2 == 0:
			u2.call(&"set_moving", 5.0)
		if i % 15 == 14:
			await get_tree().process_frame   # staggered spawn (see the instance-uniform note in the report)
	zoom = 45.0
	_apply()
	await _wait(3.0)
	_save("char_fire_200_z45")
	get_tree().quit()
