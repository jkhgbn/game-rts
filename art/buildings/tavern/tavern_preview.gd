extends Node3D
## Preview of the tavern and the bounty flags (task 9.V6) from the RTS camera (pitch 55, fov 50), on the real
## Crown Hollow ground: both taverns at their spots, turned like tavern.gd does (TavernModel.yaw_for_spot), a Ruin
## Peddler, Vessa at the door for scale, a row of the 4 flag kinds in the 4 kingdom colours.
## Windowed run `-- --shots` saves docs/art/screens/tavern_*.png and bounty_flags_*.png, then quits.
## By hand: mouse wheel = zoom, 1 / 2 = focus tavern A / B, 3 = flags, O = open / close, S = select, P = door pulse,
## R = raise the flags.

const TAVERN: PackedScene = preload("res://art/buildings/tavern/tavern_model.tscn")
const FLAG: PackedScene = preload("res://art/buildings/tavern/bounty_flag.tscn")
const PEDDLER_PATH := "res://art/environment/ruin_peddler.tscn"
const VESSA_PATH := "res://art/units/wizards/vessa.tscn"
const SPOTS: Array[Vector3] = [Vector3(-15, 0, -15), Vector3(15, 0, 15)]
const TEAM_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95),
	Color(0.35, 0.70, 0.25)]
const FLAG_ROW := Vector3(-3.0, 0.0, 6.0)

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(-15, 1.5, -15)

@onready var _cam: Camera3D = $Camera3D
@onready var _env: WorldEnvironment = $WorldEnvironment

var _taverns: Array[Node3D] = []
var _flags: Array[Node3D] = []
var _open: bool = true
var _sel: bool = false


func _ready() -> void:
	for p: Vector3 in SPOTS:
		var holder := Node3D.new()   # stands in for tavern.gd (a turned StaticBody3D)
		holder.position = p
		holder.rotation.y = TavernModel.yaw_for_spot(p)
		add_child(holder)
		var t: Node3D = TAVERN.instantiate() as Node3D
		holder.add_child(t)
		_taverns.append(t)
	if ResourceLoader.exists(PEDDLER_PATH):
		var ped: Node3D = (load(PEDDLER_PATH) as PackedScene).instantiate() as Node3D
		ped.position = Vector3(-22, 0, -22)
		ped.rotation.y = PI * 0.25
		add_child(ped)
	if ResourceLoader.exists(VESSA_PATH):
		var v: Node3D = (load(VESSA_PATH) as PackedScene).instantiate() as Node3D
		add_child(v)
		v.global_position = _taverns[0].call(&"get_door_point") + Vector3(0.8, 0, 0.6)
		v.rotation.y = PI * 0.25
	for i: int in 4:
		var f: Node3D = FLAG.instantiate() as Node3D
		f.position = FLAG_ROW + Vector3(2.0 * i, 0, 0)
		add_child(f)
		f.call(&"set_team_color", TEAM_COLORS[i])
		f.call(&"set_kind", i)
		_flags.append(f)
	# One flag in context by the tavern door (Explore, fire team).
	var ctx: Node3D = FLAG.instantiate() as Node3D
	add_child(ctx)
	ctx.position = Vector3(-9.5, 0, -11.0)
	ctx.call(&"set_team_color", TEAM_COLORS[0])
	ctx.call(&"set_kind", 1)
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
			zoom = clampf(zoom - 3.0, 4.0, 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 4.0, 60.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				focus = SPOTS[0] + Vector3(0, 1.5, 0)
			KEY_2:
				focus = SPOTS[1] + Vector3(0, 1.5, 0)
			KEY_3:
				focus = FLAG_ROW + Vector3(3, 1, 0)
			KEY_O:
				_open = not _open
				for t: Node3D in _taverns:
					t.call(&"set_open", _open)
			KEY_S:
				_sel = not _sel
				_taverns[0].call(&"set_selected", _sel)
				_flags[0].call(&"set_selected", _sel)
			KEY_P:
				_taverns[0].call(&"play_door_pulse")
			KEY_R:
				for f: Node3D in _flags:
					f.call(&"play_raise")
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
	await _wait(1.5)
	await _shot("tavern_z15", 15.0, Vector3(-15, 1.8, -14.5))
	await _shot("tavern_z30", 30.0, Vector3(-14, 1.0, -14))
	await _shot("tavern_z55", 55.0, Vector3(-10, 0.0, -10))
	await _shot("tavern_other_side_z22", 22.0, Vector3(15, 1.5, 15))
	await _shot("tavern_porch", 9.0, Vector3(-12.6, 2.2, -12.4), 38.0)
	await _shot("tavern_front_low", 14.0, Vector3(-14.5, 2.5, -14.0), 22.0)
	# Flags: close detail (below the game's min zoom, to judge the icons) and at game zoom.
	for f: Node3D in _flags:
		f.call(&"set_selected", false)
	await _shot("bounty_flags_close", 6.5, FLAG_ROW + Vector3(3.0, 1.6, 0.0), 22.0, 0.6)
	await _shot("bounty_flags_z20", 20.0, FLAG_ROW + Vector3(3.0, 0.8, 0.0))
	# Closed tavern (before 2:00) and selected + pulse.
	_taverns[0].call(&"set_open", false)
	await _shot("tavern_closed_z20", 20.0, Vector3(-14, 1.5, -14), 55.0, 1.4)
	_taverns[0].call(&"set_open", true)
	_taverns[0].call(&"set_selected", true)
	_taverns[0].call(&"play_door_pulse")
	await _shot("tavern_selected_z20", 20.0, Vector3(-14, 1.5, -14), 55.0, 0.95)
	_taverns[0].call(&"set_selected", false)
	await _silhouette()
	get_tree().quit()


## Black silhouette on white of tavern A at zoom 40 (art-keep.md 0.1 test).
func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for n: Node in get_children():
		if n is GeometryInstance3D or n is GPUParticles3D:
			(n as Node3D).visible = false
		elif n is Node3D and n != _cam and not (n as Node3D).is_ancestor_of(_taverns[0]):
			(n as Node3D).visible = false
	for g: Node in _taverns[0].find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is GPUParticles3D or gi.name.begins_with("Light") or gi.name.ends_with("Decal") or gi.name == "Halo":
			gi.visible = false
		else:
			gi.material_override = black
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	await _shot("tavern_silhouette_z40", 40.0, Vector3(-15, 2.0, -15), 55.0, 0.5)
