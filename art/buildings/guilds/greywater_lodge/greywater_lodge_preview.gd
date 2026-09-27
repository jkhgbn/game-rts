extends Node3D
## Preview of the Greywater Lodge (task 10.V9) from the RTS camera (pitch 55, fov 50) on the real ground material:
## both Lodges at their Crown Hollow spots (market-trade.md 2.3), turned by GreywaterLodgeModel.yaw_for_spot, the
## Magpie Den beside them when its scene exists (to check that the two houses read differently), a Greywater
## Tracker (or Vessa) at the door for scale.
## Windowed run `-- --shots` saves docs/art/screens/greywater_lodge_*.png, then quits.
## By hand: mouse wheel = zoom, 1 / 2 = focus Lodge NW / SE, 3 = both houses, O = open / close, S = select,
## C = play_contract.

const LODGE: PackedScene = preload("res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn")
const DEN_PATH := "res://art/buildings/guilds/magpie_den/magpie_den.tscn"
const TRACKER_PATH := "res://art/units/neutral/tracker/tracker.tscn"
const VESSA_PATH := "res://art/units/wizards/vessa.tscn"
const SPOTS: Array[Vector3] = [Vector3(-45, 0, -55), Vector3(45, 0, 55)]
const DEN_SPOTS: Array[Vector3] = [Vector3(-55, 0, -45), Vector3(55, 0, 45)]

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(-45, 1.5, -55)

@onready var _cam: Camera3D = $Camera3D
@onready var _env: WorldEnvironment = $WorldEnvironment

var _lodges: Array[Node3D] = []
var _dens: Array[Node3D] = []
var _open: bool = true
var _sel: bool = false


func _ready() -> void:
	for p: Vector3 in SPOTS:
		var l: Node3D = LODGE.instantiate() as Node3D
		l.position = p
		l.rotation.y = GreywaterLodgeModel.yaw_for_spot(p)
		add_child(l)
		_lodges.append(l)
	if ResourceLoader.exists(DEN_PATH):
		for p: Vector3 in DEN_SPOTS:
			var d: Node3D = (load(DEN_PATH) as PackedScene).instantiate() as Node3D
			d.position = p
			d.rotation.y = PI * 0.5 if p.x < 0.0 else -PI * 0.5   # door toward the road (+X / -X)
			add_child(d)
			_dens.append(d)
	var unit_path: String = TRACKER_PATH if ResourceLoader.exists(TRACKER_PATH) else VESSA_PATH
	if ResourceLoader.exists(unit_path):
		var u: Node3D = (load(unit_path) as PackedScene).instantiate() as Node3D
		add_child(u)
		u.global_position = _lodges[0].call(&"get_door_point") + Vector3(0.9, 0, -0.6)
		u.rotation.y = 0.4
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


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
			KEY_3:
				focus = Vector3(-50, 1.0, -50)
			KEY_O:
				_open = not _open
				for l: Node3D in _lodges:
					l.call(&"set_open", _open)
			KEY_S:
				_sel = not _sel
				_lodges[0].call(&"set_selected", _sel)
			KEY_C:
				_lodges[0].call(&"play_contract")
		_apply()


func _save(nm: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(nm: String, z: float, f: Vector3, pitch: float = 55.0, wait: float = 1.2) -> void:
	zoom = z
	focus = f
	pitch_degrees = pitch
	_apply()
	await _wait(wait)
	_save(nm)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var a: Vector3 = SPOTS[0]
	await _wait(1.5)
	await _shot("greywater_lodge_z15", 15.0, a + Vector3(0, 1.8, 0.4))
	await _shot("greywater_lodge_z30", 30.0, a + Vector3(0, 1.0, 0))
	await _shot("greywater_lodge_z60", 60.0, a + Vector3(3, 0.0, 3))
	await _shot("greywater_lodge_se_z22", 22.0, SPOTS[1] + Vector3(0, 1.5, 0))
	await _shot("greywater_lodge_se_back", 11.0, SPOTS[1] + Vector3(0, 1.4, 0.2), 35.0)
	await _shot("greywater_lodge_porch", 8.5, a + Vector3(-0.8, 1.6, 1.8), 32.0)
	await _shot("greywater_lodge_platform", 8.0, a + Vector3(2.0, 3.0, 2.0), 38.0)
	await _shot("greywater_lodge_front_low", 14.0, a + Vector3(0, 2.5, 0.5), 22.0)
	await _shot("greywater_lodge_vs_den_z45", 45.0, Vector3(-50, 1.0, -50))
	# Closed (before 5:00), then selected + a contract (horn flag up).
	_lodges[0].call(&"set_open", false)
	await _shot("greywater_lodge_closed_z20", 20.0, a + Vector3(0, 1.5, 0), 55.0, 1.4)
	_lodges[0].call(&"set_open", true)
	_lodges[0].call(&"set_selected", true)
	_lodges[0].call(&"play_contract")
	await _shot("greywater_lodge_contract_z20", 20.0, a + Vector3(0, 1.5, 0), 55.0, 1.6)
	_lodges[0].call(&"set_selected", false)
	await _silhouette()
	get_tree().quit()


## Black silhouette on white of the north-west Lodge at zoom 40 (art-keep.md 0.1 test).
func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	for n: Node in get_children():
		if n is Node3D and n != _cam and n != _lodges[0]:
			(n as Node3D).visible = false
	for g: Node in _lodges[0].find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is GPUParticles3D or gi.name.begins_with("LightPool") or gi.name.ends_with("Decal") \
				or gi.name.ends_with("Halo"):
			gi.visible = false
		else:
			gi.material_override = black
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	await _shot("greywater_lodge_silhouette_z40", 40.0, SPOTS[0] + Vector3(0, 2.0, 0), 55.0, 0.5)
