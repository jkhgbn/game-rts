extends Node3D
## Preview of the small buildings (task 5.V2) from the RTS camera (pitch 55, fov 50).
## Front row (z 0): Hearth, Hovel, Ember Spire, Night Spire, idle. Back row (z -10): the same in states
## (Hearth 50 % built, Hovel 20 % HP, Ember Spire selected + shooting, Night Spire 40 % HP + shooting).
## Windowed run `-- --shots` saves docs/art/screens/small_z15.png, small_z40.png, small_states.png,
## small_destroyed.png, then quits. By hand: mouse wheel = zoom, 1 rebuild back row, 2 shots, 3 destroy front row.

const SCENES: Array[PackedScene] = [
	preload("res://art/buildings/hearth.tscn"),
	preload("res://art/buildings/hovel.tscn"),
	preload("res://art/buildings/fire_tower.tscn"),
	preload("res://art/buildings/shadow_tower.tscn"),
]
const XS: Array[float] = [-6.5, -1.3, 2.9, 5.9]

@export var zoom: float = 15.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 1.5, 0)

@onready var _cam: Camera3D = $Camera3D

var _front: Array[Node3D] = []
var _back: Array[Node3D] = []
var _build_p: float = 0.5
var _shot_timer: float = 0.0


func _ready() -> void:
	for i: int in SCENES.size():
		_front.append(_spawn(i, 0.0))
		_back.append(_spawn(i, -10.0))
	_back[0].call(&"set_construction_progress", 0.5)
	_back[1].call(&"set_health_ratio", 0.2)
	_back[2].call(&"set_selected", true)
	_back[3].call(&"set_health_ratio", 0.4)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(i: int, z: float) -> Node3D:
	var b: Node3D = SCENES[i].instantiate() as Node3D
	b.position = Vector3(XS[i], 0.0, z)
	b.rotation.y = PI  # gate (-Z) toward the camera
	add_child(b)
	return b


func _process(delta: float) -> void:
	_shot_timer += delta
	if _shot_timer >= 0.75:
		_shot_timer = 0.0
		_back[2].call(&"play_shot")
		_back[3].call(&"play_shot")


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
				_back[0].call(&"set_construction_progress", 0.0)
			KEY_2:
				for b: Node3D in _front:
					if b.has_method(&"play_shot"):
						b.call(&"play_shot")
			KEY_3:
				for b: Node3D in _front:
					b.call(&"play_destroyed")


func _save(nm: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for shot: Array in [[15.0, Vector3(0, 1.5, -1.5), "small_z15"], [40.0, Vector3(0, 0.0, -6.0), "small_z40"],
			[18.0, Vector3(0, 1.5, -11.5), "small_states"]]:
		zoom = shot[0]
		focus = shot[1]
		_apply()
		await _wait(1.5)
		_save(shot[2])
	# Destroyed (front row) at 1.0 s, then check destroyed_finished.
	var finished: Array[int] = [0]
	for b: Node3D in _front:
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
		b.call(&"play_destroyed")
	zoom = 15.0
	focus = Vector3(0, 1.5, -1.5)
	_apply()
	await _wait(1.0)
	_save("small_destroyed")
	await _wait(1.8)
	print("destroyed_finished emitted: ", finished[0], "/4")
	get_tree().quit()
