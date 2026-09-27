extends Node3D
## Preview of the Magpie Den (task 10.V8) from the RTS camera (pitch 55, fov 50) on the real ground material: both
## Dens at their corners (market-trade.md 2.3), turned like the spec's doors (MagpieDenModel.yaw_for_door), Vessa at
## the north-west door for scale, a Magpie / the Greywater Lodge when those scenes exist (other step-10 tasks).
## Windowed run `-- --shots` saves docs/art/screens/magpie_den_*.png, then quits.
## By hand: mouse wheel = zoom, 1 / 2 = focus Den A / B, O = open / close, S = select, B = band out.

const DEN: PackedScene = preload("res://art/buildings/guilds/magpie_den/magpie_den.tscn")
const VESSA_PATH := "res://art/units/wizards/vessa.tscn"
const MAGPIE_PATH := "res://art/units/neutral/magpie/magpie.tscn"
const LODGE_PATH := "res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn"
const SPOTS: Array[Vector3] = [Vector3(-55, 0, -45), Vector3(55, 0, 45)]
const DOORS: Array[Vector3] = [Vector3(-51, 0, -45), Vector3(51, 0, 45)]
const LODGE_SPOTS: Array[Vector3] = [Vector3(-45, 0, -55), Vector3(45, 0, 55)]
const LODGE_DOORS: Array[Vector3] = [Vector3(-45, 0, -51), Vector3(45, 0, 51)]

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var yaw_degrees: float = 0.0
@export var focus: Vector3 = Vector3(-55, 1.5, -45)

@onready var _cam: Camera3D = $Camera3D
@onready var _env: WorldEnvironment = $WorldEnvironment

var _dens: Array[Node3D] = []
var _vessa: Node3D
var _open: bool = true
var _sel: bool = false


func _ready() -> void:
	for i: int in SPOTS.size():
		var d: Node3D = DEN.instantiate() as Node3D
		d.position = SPOTS[i]
		d.rotation.y = MagpieDenModel.yaw_for_door(SPOTS[i], DOORS[i])
		add_child(d)
		_dens.append(d)
	if ResourceLoader.exists(LODGE_PATH):
		for i: int in LODGE_SPOTS.size():
			var l: Node3D = (load(LODGE_PATH) as PackedScene).instantiate() as Node3D
			l.position = LODGE_SPOTS[i]
			l.rotation.y = atan2(LODGE_DOORS[i].x - LODGE_SPOTS[i].x, LODGE_DOORS[i].z - LODGE_SPOTS[i].z)
			add_child(l)
	if ResourceLoader.exists(VESSA_PATH):
		var v: Node3D = (load(VESSA_PATH) as PackedScene).instantiate() as Node3D
		_vessa = v
		add_child(v)
		v.global_position = DOORS[0] + Vector3(0.6, 0, 1.4)
		v.rotation.y = -PI * 0.5
	if ResourceLoader.exists(MAGPIE_PATH):
		for p: Vector3 in [DOORS[0] + Vector3(0.3, 0, -0.8), DOORS[1] + Vector3(-0.4, 0, 0.9)]:
			var m: Node3D = (load(MAGPIE_PATH) as PackedScene).instantiate() as Node3D
			add_child(m)
			m.global_position = p
			m.rotation.y = PI * 0.5 if p.x < 0.0 else -PI * 0.5
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	var back := Vector3(0.0, sin(p), cos(p)).rotated(Vector3.UP, deg_to_rad(yaw_degrees))
	_cam.position = focus + back * zoom
	_cam.rotation = Vector3(-p, deg_to_rad(yaw_degrees), 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 4.0, 70.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 4.0, 70.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				focus = SPOTS[0] + Vector3(0, 1.5, 0)
			KEY_2:
				focus = SPOTS[1] + Vector3(0, 1.5, 0)
			KEY_O:
				_open = not _open
				for d: Node3D in _dens:
					d.call(&"set_open", _open)
			KEY_S:
				_sel = not _sel
				_dens[0].call(&"set_selected", _sel)
			KEY_B:
				_dens[0].call(&"play_band_out")
		_apply()


func _save(nm: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(nm: String, z: float, f: Vector3, pitch: float = 55.0, wait: float = 1.2, yaw: float = 0.0) -> void:
	zoom = z
	focus = f
	pitch_degrees = pitch
	yaw_degrees = yaw
	_apply()
	await _wait(wait)
	_save(nm)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.5)
	var a: Vector3 = SPOTS[0]
	var b: Vector3 = SPOTS[1]
	await _shot("magpie_den_z15", 15.0, a + Vector3(0.3, 2.2, 0.3))
	await _shot("magpie_den_z30", 30.0, a + Vector3(1.0, 1.0, 0.5))
	await _shot("magpie_den_z55", 55.0, a + Vector3(4.0, 0.0, 2.0))
	await _shot("magpie_den_z60_read", 60.0, a + Vector3(6.0, 0.0, 4.0))
	await _shot("magpie_den_se_z22", 22.0, b + Vector3(0.0, 1.8, 0.0))
	await _shot("magpie_den_front_low", 13.0, a + Vector3(2.0, 3.0, 0.0), 24.0, 1.0, 90.0)
	await _shot("magpie_den_back_low", 14.0, a + Vector3(-0.5, 3.2, -0.5), 26.0, 1.0, 215.0)
	await _shot("magpie_den_vane", 6.5, a + Vector3(-0.3, 7.2, -0.8), 18.0, 1.0, 30.0)
	# Closed (before 5:00), selected, and a band leaving (mid swing).
	_dens[0].call(&"set_open", false)
	await _shot("magpie_den_closed_z20", 20.0, a + Vector3(0.5, 1.5, 0.3), 55.0, 1.4)
	_dens[0].call(&"set_open", true)
	_dens[0].call(&"set_selected", true)
	await _shot("magpie_den_selected_z20", 20.0, a + Vector3(0.5, 1.5, 0.3), 55.0, 1.2)
	_dens[0].call(&"set_selected", false)
	await _shot("magpie_den_open_z20", 20.0, a + Vector3(0.5, 1.5, 0.3), 55.0, 0.6)
	if _vessa:
		_vessa.global_position = DOORS[0] + Vector3(1.2, 0, 3.0)
	_dens[0].call(&"play_band_out")
	await _shot("magpie_den_band_out", 11.0, a + Vector3(3.0, 1.2, 0.5), 42.0, 0.3, 60.0)
	await _shot("magpie_den_band_out_late", 11.0, a + Vector3(3.0, 1.2, 0.5), 42.0, 0.45, 60.0)
	await _silhouette()
	get_tree().quit()


## Black silhouette on white of Den A at zoom 40 and 60 (art-keep.md 0.1 test).
func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	for n: Node in get_children():
		if n is GeometryInstance3D or n is GPUParticles3D:
			(n as Node3D).visible = false
		elif n is Node3D and n != _cam and n != _dens[0]:
			(n as Node3D).visible = false
	for g: Node in _dens[0].find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is GPUParticles3D or gi.name.begins_with("Light") or gi.name.ends_with("Decal") or gi.name == "Halo":
			gi.visible = false
		else:
			gi.material_override = black
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	await _shot("magpie_den_silhouette_z40", 40.0, SPOTS[0] + Vector3(0, 2.5, 0), 55.0, 0.5)
	await _shot("magpie_den_silhouette_z60", 60.0, SPOTS[0] + Vector3(0, 2.5, 0), 55.0, 0.5)
	await _shot("magpie_den_silhouette_side", 30.0, SPOTS[0] + Vector3(0, 3.5, 0), 12.0, 0.5, 90.0)
