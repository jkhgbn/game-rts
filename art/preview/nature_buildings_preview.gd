extends Node3D
## Preview of the Nature buildings (task 8.V2) from the RTS camera (pitch 55, fov 50).
## Front row (z 0), idle: Grove Hall, Seed Hollow, Bramble Spire, a red-team Seed Hollow.
## Back row (z -13), states: Hall 50 % built, Hollow 20 % HP, Spire selected + shooting, Hall 20 % HP (burning).
## Windowed run `-- --shots` saves docs/art/screens/nature_bld_*.png (z15, z40, states, destroyed), then quits.
## By hand: mouse wheel = zoom, 1 rebuild the back row, 2 shots, 3 destroy the front row, 4 red team colour.

const HALL: PackedScene = preload("res://art/buildings/nature_hall.tscn")
const HOLLOW: PackedScene = preload("res://art/buildings/nature_hollow.tscn")
const SPIRE: PackedScene = preload("res://art/buildings/nature_spire.tscn")

@export var zoom: float = 15.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 1.5, 0)

@onready var _cam: Camera3D = $Camera3D

var _front: Array[Node3D] = []
var _back: Array[Node3D] = []
var _build_p: float = 1.0
var _shot_timer: float = 0.0


func _ready() -> void:
	_front.append(_spawn(HALL, Vector3(-8.0, 0, 0)))
	_front.append(_spawn(HOLLOW, Vector3(-1.0, 0, 0)))
	_front.append(_spawn(SPIRE, Vector3(4.0, 0, 0)))
	var red := _spawn(HOLLOW, Vector3(9.5, 0, 0))
	red.call(&"set_team_color", Color(0.85, 0.22, 0.18))
	_front.append(red)
	_back.append(_spawn(HALL, Vector3(-8.0, 0, -13)))
	_back.append(_spawn(HOLLOW, Vector3(-1.0, 0, -13)))
	_back.append(_spawn(SPIRE, Vector3(4.0, 0, -13)))
	_back.append(_spawn(HALL, Vector3(11.0, 0, -13)))
	_back[0].call(&"set_construction_progress", 0.5)
	_back[1].call(&"set_health_ratio", 0.2)
	_back[2].call(&"set_selected", true)
	_back[3].call(&"set_health_ratio", 0.2)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(scene: PackedScene, pos: Vector3) -> Node3D:
	var b: Node3D = scene.instantiate() as Node3D
	b.position = pos
	b.rotation.y = PI  # gate (-Z) toward the camera
	add_child(b)
	return b


func _process(delta: float) -> void:
	_shot_timer += delta
	if _shot_timer >= 0.75:
		_shot_timer = 0.0
		_back[2].call(&"play_shot")
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		for b: Node3D in _back:
			b.call(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 10.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 10.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				_build_p = 0.0
			KEY_2:
				for b: Node3D in _front:
					if b.has_method(&"play_shot"):
						b.call(&"play_shot")
			KEY_3:
				for b: Node3D in _front:
					b.call(&"play_destroyed")
			KEY_4:
				for b: Node3D in _front:
					b.call(&"set_team_color", Color(0.85, 0.22, 0.18))


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for shot: Array in [[15.0, Vector3(-7.5, 2.5, 0.5), "nature_bld_z15_hall"],
			[15.0, Vector3(2.0, 1.2, 0.0), "nature_bld_z15_small"],
			[40.0, Vector3(1.5, 0.0, -6.0), "nature_bld_z40"],
			[24.0, Vector3(1.5, 1.5, -13.0), "nature_bld_states"]]:
		zoom = shot[0]
		focus = shot[1]
		_apply()
		await _wait(1.5)
		_save(shot[2])
	# Burning hall close-up, then the hall construction at 20 %.
	zoom = 15.0
	focus = Vector3(10.0, 2.0, -12.5)
	_apply()
	await _wait(1.0)
	_save("nature_bld_burning")
	_back[0].call(&"set_construction_progress", 0.2)
	_back[1].call(&"set_construction_progress", 0.6)
	zoom = 18.0
	focus = Vector3(-5.0, 1.5, -12.5)
	_apply()
	await _wait(1.0)
	_save("nature_bld_states_close")
	var finished: Array[int] = [0]
	for b: Node3D in _front:
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
		b.call(&"play_destroyed")
	zoom = 22.0
	focus = Vector3(1.0, 1.5, 0.0)
	_apply()
	await _wait(1.3)
	_save("nature_bld_destroyed")
	await _wait(2.2)
	print("destroyed_finished emitted: ", finished[0], "/", _front.size())
	get_tree().quit()
