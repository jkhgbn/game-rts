extends Node3D
## Nature army preview (task 8.V3) from the RTS camera (pitch 55, fov 50). Units whose scene does not exist yet are
## skipped. Windowed: `-- --shots` saves docs/art/screens/char_nature_a_*.png and quits (`-- --all` also shows the
## 8.V4 units when they exist). By hand: 1 attack, 2 hit, 3 death, 4 level-up + veterancy 4, 5 carry toggle, 6 mine,
## 7 walk toggle, 8 cast (cycles the 3 spells), 9 revive, 0 sprout 3 new Saplings, wheel = zoom.

const MINE: Array[String] = ["nature/sprigling", "nature/thornling", "wizards/ysolde", "nature/sapling"]
const MINE_SPEEDS: Array[float] = [4.6, 5.4, 4.8, 4.8]
const OTHERS: Array[String] = ["nature/burr_slinger", "nature/slinger", "nature/bloomtender", "nature/bramblehorn"]
const OTHER_SPEEDS: Array[float] = [5.0, 5.0, 4.8, 4.6]
const CASTS: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
const TEAM := Color(0.35, 0.70, 0.25)

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 0.9, 0)
var _cam: Camera3D
var _row: Array[Node3D] = []
var _ids: Array[String] = []
var _speeds: Array[float] = []
var _extra: Array[Node3D] = []
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
	var ids: Array[String] = MINE.duplicate()
	var speeds: Array[float] = MINE_SPEEDS.duplicate()
	if "--all" in OS.get_cmdline_user_args():
		ids.append_array(OTHERS)
		speeds.append_array(OTHER_SPEEDS)
	for i: int in ids.size():
		if not ResourceLoader.exists("res://art/units/%s.tscn" % ids[i]):
			continue
		var u := _spawn(ids[i], Vector3.ZERO, 0.0)
		if u == null:
			continue
		_row.append(u)
		_ids.append(ids[i])
		_speeds.append(speeds[i])
	for i: int in _row.size():
		_row[i].position = Vector3((float(i) - float(_row.size() - 1) * 0.5) * 2.4, 0, 0)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(id: String, at: Vector3, yaw: float, team: Color = TEAM) -> Node3D:
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
	u.call(&"set_team_color", team)
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
			KEY_0: _thicket(Vector3(0, 0, 4.0))


## Call the Thicket look: 3 Saplings sprout on a ring r 1.2 around `at`.
func _thicket(at: Vector3) -> void:
	for i: int in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		var s := _spawn("nature/sapling", at + Vector3(sin(a), 0, cos(a)) * 1.2, a)
		if s:
			_extra.append(s)


func _clear_extra() -> void:
	for n: Node3D in _extra:
		if is_instance_valid(n):
			n.queue_free()
	_extra.clear()


func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/char_nature_a_%s.png" % name
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
	await _wait(1.2)
	await _both("idle")
	# Close-ups, one per unit, and a side view of the row.
	for i: int in _row.size():
		zoom = 5.0 if _ids[i] != "wizards/ysolde" else 6.0
		focus = _row[i].position + Vector3(0, 0.8, 0)
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
	# Worker carrying.
	_row[0].call(&"set_carrying", true)
	# Walk mid-stride.
	for i: int in _row.size():
		_row[i].call(&"set_moving", _speeds[i])
	await _wait(0.9)
	await _both("walk")
	for u: Node3D in _row:
		u.call(&"set_moving", 0.0)
	_row[0].call(&"set_carrying", false)
	await _wait(0.5)
	# Attack at the strike / release.
	_all(&"play_attack")
	await _wait(0.10)
	await _both("attack")
	await _wait(1.0)
	# Casts: thornburst at the slam (the worker mines), wild bloom fully open, call the thicket planted.
	_all(&"play_cast", [&"thornburst"])
	_row[0].call(&"play_mine")
	await _wait(0.40)
	await _both("cast")
	await _wait(1.2)
	_all(&"play_cast", [&"wild_bloom"])
	await _wait(0.5)
	_save("cast_bloom_z15")
	zoom = 6.0
	focus = _row[2].position + Vector3(0, 1.3, 0)
	_apply()
	await get_tree().process_frame
	_save("cast_bloom_close")
	focus = Vector3(0, 0.9, 0)
	_apply()
	await _wait(1.0)
	_all(&"play_cast", [&"call_the_thicket"])
	await _wait(0.55)
	_save("cast_thicket_z15")
	await _wait(1.0)
	# Sapling sprouting: 3 new Saplings on a ring in front (Call the Thicket), at 0.12 s / 0.3 s / grown.
	_thicket(Vector3(0, 0, 3.5))
	focus = Vector3(0, 0.6, 3.5)
	zoom = 9.0
	_apply()
	await _wait(0.12)
	_save("sprout_a_z9")
	await _wait(0.18)
	_save("sprout_b_z9")
	await _wait(0.6)
	_save("sprout_c_z9")
	focus = Vector3(0, 0.9, 1.5)
	await _both("sprout_grown")
	# Team colour check: a red row behind (set_team_color recolours cloth / cape only).
	for i: int in _ids.size():
		var r := _spawn(_ids[i], Vector3(_row[i].position.x, 0, -3.0), 0.0, Color(0.85, 0.30, 0.12))
		if r:
			_extra.append(r)
	focus = Vector3(0, 0.9, -1.0)
	zoom = 15.0
	_apply()
	await _wait(0.6)
	_save("team_z15")
	# Crowd at 40 m: 8 Thornlings, 4 Sprigling, 3 Saplings, Ysolde (silhouette read).
	_clear_extra()
	for u: Node3D in _row:
		u.visible = false
	var c := Vector3(0, 0, 0)
	for i: int in 8:
		var t := _spawn("nature/thornling", c + Vector3(-3.0 + float(i % 4) * 1.2, 0, 2.0 + float(i / 4) * 1.2), 0.0)
		if t:
			_extra.append(t)
	for i: int in 4:
		var s := _spawn("nature/sprigling", c + Vector3(3.0 + float(i % 2) * 1.0, 0, -1.0 + float(i / 2) * 1.0), 2.4)
		if s:
			s.call(&"set_carrying", i % 2 == 0)
			_extra.append(s)
	_thicket(c + Vector3(-2.0, 0, -1.5))
	var y := _spawn("wizards/ysolde", c + Vector3(0.5, 0, 0.2), 0.3)
	if y:
		_extra.append(y)
	focus = Vector3(0, 0.9, 0.5)
	await _wait(1.0)
	await _both("crowd")
	# Death at 0.5 s (the Sapling withers brown and sinks).
	for u: Node3D in _row:
		u.visible = true
	_clear_extra()
	focus = Vector3(0, 0.9, 0)
	_apply()
	await _wait(0.3)
	_all(&"play_death")
	await _wait(0.5)
	await _both("death")
	zoom = 5.0
	focus = _row[_row.size() - 1].position + Vector3(0, 0.5, 0) if _ids[_ids.size() - 1] == "nature/sapling" else focus
	_apply()
	await get_tree().process_frame
	_save("death_close_last")
	await _wait(1.0)
	get_tree().quit()
