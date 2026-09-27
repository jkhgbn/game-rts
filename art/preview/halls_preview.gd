extends Node3D
## Preview of the Ember Hall (left) and the Gloom Hall (right) from the RTS camera (pitch 55, fov 50).
## Windowed runs:
##   `-- --shots`   saves docs/art/screens/hall_fire_z15.png, hall_shadow_z15.png, hall_z40.png, then quits.
##   `-- --states`  saves docs/art/screens/hall_state_*.png + the contact sheet hall_states.png, then quits.
## Keys by hand: 1 construction replay (6 s), 2 training pulse, 3 HP 40 %, 4 HP 20 %, 5 full HP, 6 destroy,
## 7 toggle selected, 8 cycle team colour, 0 new halls. Mouse wheel = zoom.

const SCENES: Array[PackedScene] = [preload("res://art/buildings/fire_hall.tscn"),
	preload("res://art/buildings/shadow_hall.tscn")]
const POSITIONS: Array[Vector3] = [Vector3(-5.0, 0, 0), Vector3(5.0, 0, 0)]
const TEAM_COLORS: Array[Color] = [Color(0.20, 0.45, 0.95), Color(0.30, 0.80, 0.30)]

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 2, 0)

@onready var _cam: Camera3D = $Camera3D

var _halls: Array[Node3D] = []
var _build_p: float = 1.0
var _selected: bool = false
var _team: int = -1


func _ready() -> void:
	_new_halls()
	_apply()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--shots" in args:
		_shots()
	elif "--states" in args:
		_states()


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_all(&"set_construction_progress", _build_p)


func _all(method: StringName, arg: Variant = null) -> void:
	for h: Node3D in _halls:
		if arg == null:
			h.call(method)
		else:
			h.call(method, arg)


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
				_all(&"set_construction_progress", 0.0)
			KEY_2:
				_all(&"play_training_pulse")
			KEY_3:
				_all(&"set_health_ratio", 0.4)
			KEY_4:
				_all(&"set_health_ratio", 0.2)
			KEY_5:
				_all(&"set_health_ratio", 1.0)
			KEY_6:
				_all(&"play_destroyed")
			KEY_7:
				_selected = not _selected
				_all(&"set_selected", _selected)
			KEY_8:
				_team = (_team + 1) % TEAM_COLORS.size()
				_all(&"set_team_color", TEAM_COLORS[_team])
			KEY_0:
				_new_halls()


func _new_halls() -> void:
	for h: Node3D in _halls:
		h.queue_free()
	_halls.clear()
	for i: int in SCENES.size():
		var h := SCENES[i].instantiate() as Node3D
		h.position = POSITIONS[i]
		h.rotation.y = PI  # gate (-Z) toward the camera
		add_child(h)
		_halls.append(h)
	_build_p = 1.0


func _save(name: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for shot: Array in [[15.0, Vector3(-5, 1.5, 1.5), "hall_fire_z15"], [15.0, Vector3(5, 1.5, 1.5), "hall_shadow_z15"],
			[40.0, Vector3(0, 2.0, 0), "hall_z40"]]:
		zoom = shot[0]
		focus = shot[1]
		_apply()
		await _wait(1.5)
		_save(shot[2])
	get_tree().quit()


func _states() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	zoom = 26.0
	focus = Vector3(0, 2.5, 0)
	_apply()
	var sheet: Array[Image] = []
	_all(&"set_construction_progress", 0.0)
	await _wait(0.6)
	_all(&"set_construction_progress", 0.5)
	await _wait(1.0)
	sheet.append(_save("hall_state_construction50"))
	_all(&"set_construction_progress", 1.0)
	await _wait(0.12)
	_save("hall_state_complete_flash")
	await _wait(1.8)
	sheet.append(_save("hall_state_idle"))
	_all(&"set_selected", true)
	_all(&"play_training_pulse")
	await _wait(0.15)
	sheet.append(_save("hall_state_selected_training"))
	_all(&"set_selected", false)
	await _wait(0.5)
	_all(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_save("hall_state_hp40"))
	_all(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_save("hall_state_hp20"))
	var finished: Array[int] = [0]
	for h: Node3D in _halls:
		h.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	_all(&"play_destroyed")
	await _wait(1.2)
	_save("hall_state_destroyed_1s2")
	await _wait(1.9)
	sheet.append(_save("hall_state_destroyed_3s"))
	print("destroyed_finished emitted: ", finished[0], " / 2")
	# Healing check + team colour on fresh halls.
	_new_halls()
	await get_tree().process_frame
	_all(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_all(&"set_health_ratio", 1.0)
	_all(&"set_team_color", TEAM_COLORS[0])
	await _wait(4.0)
	_save("hall_state_healed_blue")
	var out := Image.create(1920, 720, false, Image.FORMAT_RGBA8)
	for i: int in sheet.size():
		var img: Image = sheet[i]
		img.convert(Image.FORMAT_RGBA8)
		img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i((i % 3) * 640, (i / 3) * 360))
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/hall_states.png"))
	print("saved hall_states.png")
	get_tree().quit()
