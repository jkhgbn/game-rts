extends Node3D
## Ice army preview (tasks 7.V3 / 7.V4) from the RTS camera (pitch 55, fov 50). Units whose scene does not exist
## yet are skipped. Windowed: `-- --shots` saves docs/art/screens/char_ice_a_*.png and quits.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up + veterancy 4, 5 carry toggle, 6 mine, 7 walk toggle, 8 cast,
## 9 revive, wheel = zoom.

const ALL: Array[String] = ["ice/rime_hauler", "ice/rimeshield", "wizards/torvald", "ice/shardcaster",
	"ice/rime_seer", "ice/seer", "ice/rime_colossus", "ice/colossus"]
const ALL_SPEEDS: Array[float] = [4.6, 4.2, 4.2, 4.4, 4.2, 4.2, 3.4, 3.4]
const CASTS: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 0.9, 0)
var _cam: Camera3D
var _row: Array[Node3D] = []
var _ids: Array[String] = []
var _speeds: Array[float] = []
var _walking: bool = false
var _carry: bool = false
var _cast_i: int = 0


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
	# `-- --v3` shows only the 7.V3 units (hauler, rimeshield, Torvald).
	var n_max: int = 3 if "--v3" in OS.get_cmdline_user_args() else ALL.size()
	for i: int in n_max:
		if not ResourceLoader.exists("res://art/units/%s.tscn" % ALL[i]):
			continue
		var u := _spawn(ALL[i], Vector3.ZERO, 0.0)
		if u == null:
			continue
		_row.append(u)
		_ids.append(ALL[i])
		_speeds.append(ALL_SPEEDS[i])
	for i: int in _row.size():
		_row[i].position = Vector3((float(i) - float(_row.size() - 1) * 0.5) * 2.4, 0, 0)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(id: String, at: Vector3, yaw: float) -> Node3D:
	var ps := load("res://art/units/%s.tscn" % id) as PackedScene
	if ps == null:
		return null
	var u := ps.instantiate() as Node3D
	if u == null or not u.has_method(&"set_team_color"):   # scene still being built (script missing)
		if u:
			u.free()
		return null
	u.position = at
	u.rotation.y = yaw
	add_child(u)
	u.call(&"set_team_color", Color(0.45, 0.75, 0.95))
	return u


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _all(method: StringName, args: Array = []) -> void:
	for u: Node3D in _row:
		if is_instance_valid(u) and u.has_method(method):
			u.callv(method, args)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 5.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 5.0, 55.0)
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
					_row[i].call(&"set_moving", _speeds[i] if _walking else 0.0)
			KEY_8:
				_all(&"play_cast", [CASTS[_cast_i % CASTS.size()]])
				_cast_i += 1
			KEY_9: _all(&"revive")


func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/char_ice_a_%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _both(name: String) -> void:
	zoom = 15.0
	_apply()
	await get_tree().process_frame
	await get_tree().process_frame
	_save(name + "_z15")
	zoom = 40.0
	_apply()
	await get_tree().process_frame
	await get_tree().process_frame
	_save(name + "_z40")
	zoom = 15.0
	_apply()


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.0)
	_row[0].call(&"set_carrying", true)
	await _wait(0.5)
	await _both("idle")
	# Close-ups, one per unit, and a side view of the row.
	for i: int in _row.size():
		zoom = 5.0
		focus = _row[i].position + Vector3(0, 1.0, 0)
		_apply()
		await _wait(0.2)
		_save("close_%s" % _ids[i].get_file())
	focus = Vector3(0, 0.9, 0)
	for u: Node3D in _row:
		u.rotation.y = PI * 0.5
	zoom = 12.0
	_apply()
	await _wait(0.2)
	_save("side_z12")
	for u: Node3D in _row:
		u.rotation.y = 0.0
	# Walk mid-stride.
	for i: int in _row.size():
		_row[i].call(&"set_moving", _speeds[i])
	await _wait(0.9)
	await _both("walk")
	for u: Node3D in _row:
		u.call(&"set_moving", 0.0)
	await _wait(0.5)
	# Attack at the strike / release.
	_all(&"play_attack")
	await _wait(0.10)
	await _both("attack")
	await _wait(1.0)
	# Cast (Torvald: flash freeze at the slam; others use the generic cast) and the worker mines.
	_all(&"play_cast", [&"flash_freeze"])
	_row[0].call(&"play_mine")
	await _wait(0.42)
	await _both("cast")
	await _wait(1.2)
	_all(&"play_cast", [&"rime_aegis"])
	await _wait(0.5)
	_save("cast_aegis_z15")
	await _wait(1.0)
	# Death at 0.5 s.
	_all(&"play_death")
	await _wait(0.5)
	await _both("death")
	await _wait(1.0)
	get_tree().quit()
