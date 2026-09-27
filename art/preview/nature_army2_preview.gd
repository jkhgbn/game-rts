extends Node3D
## Preview of Burr Slinger, Bloomtender, Bramblehorn (task 8.V4) from the RTS camera (pitch 55, fov 50).
## Keys 1-4: zoom 15 / 25 / 40 / 55, A = attack all, S = Bloomtender support cast, D = death all, M = walk toggle.
## Run windowed with `-- --shots` to save docs/art/screens/char_nature_b_*.png and quit; `-- --check` headless.

const SCENES: Array[String] = [
	"res://art/units/nature/burr_slinger.tscn",
	"res://art/units/nature/bloomtender.tscn",
	"res://art/units/nature/bramblehorn.tscn",
]
const SPEEDS: Array[float] = [5.0, 4.8, 4.6]
const NATURE_COLOR := Color(0.35, 0.70, 0.25)
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
	var xs: Array[float] = [-2.2, 0.0, 2.8]
	for i: int in SCENES.size():
		_row.append(_spawn(i, Vector3(xs[i], 0, 0), 0.0))
	# A mixed group of 15 at GROUP_CENTER (slingers 7, bloomtenders 4, bramblehorns 4), facing lower right.
	var mix: Array[int] = [0, 0, 1, 0, 2, 0, 2, 1, 0, 2, 0, 1, 2, 0, 1]
	for k: int in mix.size():
		var gx := (k % 5) * 2.2 - 4.4 + (0.6 if (k / 5) % 2 == 1 else 0.0)
		var gz := (k / 5) * 2.6 - 2.6
		_group.append(_spawn(mix[k], GROUP_CENTER + Vector3(gx, 0, gz), atan2(0.6, 1.0)))
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_set_zoom(25.0, Vector3.ZERO)
	_report()
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	elif "--check" in OS.get_cmdline_user_args():
		_check()


func _spawn(kind: int, p: Vector3, yaw: float):
	var holder := Node3D.new()   # stands in for Unit._visual (facing lives here)
	holder.position = p
	holder.rotation.y = yaw
	add_child(holder)
	var m = (load(SCENES[kind]) as PackedScene).instantiate()
	if m.has_method(&"set_team_color"):
		m.set_team_color(NATURE_COLOR)
	holder.add_child(m)
	m.set_meta(&"speed", SPEEDS[kind])
	return m


## Budget report: draw instances after the merge, vertices.
func _report() -> void:
	for m in _row:
		var inst: Array[int] = [0, 0]
		_count(m, inst)
		print("%s: draw instances %d, vertices %d, windup %.2f" % [m.name, inst[0], inst[1], m.attack_windup])


func _count(n: Node, acc: Array[int]) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			acc[0] += 1
			var mesh := (c as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				acc[1] += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		elif c is MultiMeshInstance3D or c is GPUParticles3D:
			acc[0] += 1
		_count(c, acc)


func _set_zoom(z: float, focus: Vector3) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _side_view(focus: Vector3, dist: float, h: float = 1.1) -> void:
	_cam.position = focus + Vector3(dist, h, 0.0)
	_cam.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)


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
			KEY_1: _set_zoom(15.0, Vector3(0, 0, 1.5))
			KEY_2: _set_zoom(25.0, Vector3.ZERO)
			KEY_3: _set_zoom(40.0, Vector3(10, 0, 0))
			KEY_4: _set_zoom(55.0, Vector3(15, 0, 0))
			KEY_A: _all(_row, &"play_attack"); _all(_group, &"play_attack")
			KEY_S: _all([_row[1]], &"play_cast", [&"support"])
			KEY_D: _all(_row, &"play_death")
			KEY_M:
				_walking = not _walking
				_set_walk(_row, _walking)
				_set_walk(_group, _walking)


## Headless check: every hook runs without errors, death_finished fires.
func _check() -> void:
	await _wait(0.3)
	_all(_row, &"play_attack")
	await _wait(1.1)
	_all([_row[1]], &"play_cast", [&"support"])
	print("beam origin ", _row[1].get_beam_origin())
	_all(_row, &"play_hit")
	_all(_row, &"set_veterancy", [4])
	_all(_row, &"set_status", [&"haste", true])
	_set_walk(_row, true)
	await _wait(0.8)
	var done: Array[int] = [0]
	for m in _row:
		m.death_finished.connect(func() -> void: done[0] += 1)
	_all(_row, &"play_death")
	await _wait(1.3)
	_all(_row, &"revive")
	await _wait(0.2)
	print("NATURE2 CHECK death_finished ", done[0], " / ", _row.size())
	get_tree().quit()


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.0)
	_set_zoom(15.0, Vector3(0, 0, 1.5))
	await _wait(1.2)
	_save("char_nature_b_z15")
	_all(_row, &"play_attack")
	await _wait(0.09)
	_save("char_nature_b_windup_z15")
	await _wait(0.07)
	_save("char_nature_b_release_z15")
	await _wait(1.2)
	_all([_row[1]], &"play_cast", [&"support"])
	await _wait(0.25)
	_save("char_nature_b_support_z15")
	await _wait(0.8)
	# Side views (camera at +X: +Z = left of the image).
	_solo(0)
	_side_view(_row[0].global_position, 4.5, 0.9)
	await _wait(0.3)
	_save("char_nature_b_side_slinger")
	_solo(1)
	_side_view(_row[1].global_position, 5.0, 1.1)
	await _wait(0.3)
	_save("char_nature_b_side_bloom")
	_all([_row[1]], &"play_cast", [&"support"])
	await _wait(0.25)
	_save("char_nature_b_side_bloom_heal")
	await _wait(0.8)
	_solo(2)
	_side_view(_row[2].global_position, 7.0, 1.3)
	await _wait(0.3)
	_save("char_nature_b_side_rest")
	_all([_row[2]], &"play_attack")
	await _wait(0.05)
	_save("char_nature_b_side_coil")
	await _wait(0.08)
	_save("char_nature_b_side_gore")
	await _wait(1.0)
	_set_walk([_row[2]], true)
	await _wait(0.6)
	_save("char_nature_b_side_charge")
	_set_walk([_row[2]], false)
	_solo(-1)
	await _wait(0.5)
	_set_zoom(15.0, Vector3(0, 0, 1.5))
	_set_walk(_row, true)
	await _wait(0.8)
	_save("char_nature_b_walk_z15")
	_set_walk(_row, false)
	await _wait(0.5)
	_set_zoom(40.0, Vector3(0, 0, 0))
	await _wait(1.0)
	_save("char_nature_b_z40")
	_set_walk(_group, true)
	_set_zoom(40.0, GROUP_CENTER)
	await _wait(1.2)
	_save("char_nature_b_group_z40")
	print("group fps ", Engine.get_frames_per_second(), " draw calls ",
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_set_walk(_group, false)
	_set_zoom(15.0, Vector3(0, 0, 1.5))
	await _wait(1.0)
	_all(_row, &"play_hit")
	await _wait(0.1)
	_save("char_nature_b_hit_z15")
	await _wait(0.8)
	_all(_row, &"play_death")
	await _wait(0.5)
	_save("char_nature_b_death_z15")
	await _wait(1.0)
	get_tree().quit()


## Shows only row unit i (-1 = all).
func _solo(i: int) -> void:
	for k: int in _row.size():
		(_row[k].get_parent() as Node3D).visible = i < 0 or k == i


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://docs/art/screens/%s.png" % nm)
	print("saved ", nm)
