extends Node3D
## Preview of the Ember Bazaar (task 10.V1) from the RTS camera (pitch 55, fov 50) on the real ground: the player's
## Bazaar at the M1 slot (-45, 27) turned like Building does (gate toward the map centre: yaw -90), the Fire keep and
## an Ember Hall beside it for scale, Vessa and (if it exists) a caravan at the stall; the enemy's mirror at (45, -27)
## in another team colour; a row of states (site 0 / 35 / 70 %, idle, 40 % HP, 20 % HP, destroyed).
## Windowed run `-- --shots` saves docs/art/screens/bazaar_fire_*.png, then quits.
## `-- --sheet` saves docs/art/screens/bazaars_silhouette.png: every Bazaar that exists (fire, shadow, ice, nature),
## in colour (top) and as a black silhouette (bottom), then quits.
## By hand: wheel = zoom, 1 = player Bazaar, 2 = enemy mirror, 3 = states row, D = delivery, S = select,
## P = training pulse, Q / E = orbit the camera.

const MARKET: PackedScene = preload("res://art/buildings/market/fire/market_fire.tscn")
const KEEP_PATH := "res://art/buildings/fire_keep.tscn"
const HALL_PATH := "res://art/buildings/fire_hall.tscn"
const VESSA_PATH := "res://art/units/wizards/vessa.tscn"
const CARAVAN_PATH := "res://art/units/caravan/caravan.tscn"
const SHEET_PATHS: Array[String] = ["res://art/buildings/market/fire/market_fire.tscn",
	"res://art/buildings/market/shadow/market_shadow.tscn", "res://art/buildings/market/ice/market_ice.tscn",
	"res://art/buildings/market/nature/market_nature.tscn"]
const SHEET_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95),
	Color(0.35, 0.70, 0.25)]
const M1 := Vector3(-45, 0, 27)
const M1_ENEMY := Vector3(45, 0, -27)
const ROW_Z := -6.0
const ROW_X0 := -27.0
const ROW_STEP := 9.0
const SHEET_Z := 44.0

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var yaw_degrees: float = 0.0
@export var focus: Vector3 = M1 + Vector3(0, 2.0, 0)

@onready var _cam: Camera3D = $Camera3D
@onready var _env: WorldEnvironment = $WorldEnvironment

var _main: Node3D
var _mirror: Node3D
var _row: Array[Node3D] = []
var _sheet: Array[Node3D] = []
var _sel: bool = false


func _ready() -> void:
	var sheet_mode: bool = "--sheet" in OS.get_cmdline_user_args()
	if sheet_mode:
		_build_sheet()
	else:
		_build_scene()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()
	elif sheet_mode:
		_sheet_shots()


func _holder(pos: Vector3, yaw: float) -> Node3D:
	var h := Node3D.new()   # stands in for Building (the model is its child, turned by _gate_yaw)
	h.position = pos
	add_child(h)
	var inner := Node3D.new()
	inner.rotation.y = yaw
	h.add_child(inner)
	return inner


func _place(scene: PackedScene, pos: Vector3, yaw: float, team: Color) -> Node3D:
	var m := scene.instantiate() as Node3D
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", team)
	_holder(pos, yaw).add_child(m)
	return m


func _build_scene() -> void:
	_main = _place(MARKET, M1, -PI * 0.5, Color(0.85, 0.30, 0.12))
	_mirror = _place(MARKET, M1_ENEMY, PI * 0.5, Color(0.42, 0.22, 0.60))
	if ResourceLoader.exists(KEEP_PATH):
		_place(load(KEEP_PATH) as PackedScene, Vector3(-43, 0, 43), -PI * 0.5, Color(0.85, 0.30, 0.12))
	if ResourceLoader.exists(HALL_PATH):
		_place(load(HALL_PATH) as PackedScene, Vector3(-35, 0, 33), -PI * 0.5, Color(0.85, 0.30, 0.12))
	if ResourceLoader.exists(VESSA_PATH):
		var v := (load(VESSA_PATH) as PackedScene).instantiate() as Node3D
		add_child(v)
		v.position = M1 + Vector3(4.2, 0, 1.2)
		v.rotation.y = PI * 0.5
	if ResourceLoader.exists(CARAVAN_PATH):
		var c := (load(CARAVAN_PATH) as PackedScene).instantiate() as Node3D
		add_child(c)
		c.position = M1 + Vector3(5.0, 0, -2.5)
		c.rotation.y = PI * 0.5
		if c.has_method(&"set_team_color"):
			c.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		if c.has_method(&"set_loaded"):
			c.call(&"set_loaded", true)
	# States row (player orientation).
	var states: Array[float] = [0.0, 0.35, 0.7, 1.0, 1.0, 1.0, 1.0]
	for i: int in states.size():
		var m := _place(MARKET, Vector3(ROW_X0 + ROW_STEP * i, 0, ROW_Z), -PI * 0.5, Color(0.85, 0.30, 0.12))
		m.call(&"set_construction_progress", states[i])
		_row.append(m)
	_row[4].call(&"set_health_ratio", 0.4)
	_row[5].call(&"set_health_ratio", 0.2)


func _build_sheet() -> void:
	var n: int = 0
	for i: int in SHEET_PATHS.size():
		if not ResourceLoader.exists(SHEET_PATHS[i]):
			continue
		var scene := load(SHEET_PATHS[i]) as PackedScene
		if scene == null:
			continue
		var m := _place(scene, Vector3(-15.0 + 10.0 * n, 0, SHEET_Z), -PI * 0.5, SHEET_COLORS[i])
		_sheet.append(m)
		n += 1
	print("sheet: %d bazaars" % n)


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	var y: float = deg_to_rad(yaw_degrees)
	_cam.position = focus + Basis(Vector3.UP, y) * Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, y, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 4.0, 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 4.0, 60.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and _main:
		match k.physical_keycode:
			KEY_1:
				focus = M1 + Vector3(0, 2, 0)
			KEY_2:
				focus = M1_ENEMY + Vector3(0, 2, 0)
			KEY_3:
				focus = Vector3(0, 0, ROW_Z)
			KEY_D:
				_main.call(&"play_delivery")
				_mirror.call(&"play_delivery")
			KEY_S:
				_sel = not _sel
				_main.call(&"set_selected", _sel)
			KEY_P:
				_main.call(&"play_training_pulse")
			KEY_Q:
				yaw_degrees -= 15.0
			KEY_E:
				yaw_degrees += 15.0
		_apply()


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frame(z: float, f: Vector3, pitch: float = 55.0, yaw: float = 0.0) -> void:
	zoom = z
	focus = f
	pitch_degrees = pitch
	yaw_degrees = yaw
	_apply()


func _shot(nm: String, z: float, f: Vector3, pitch: float = 55.0, wait: float = 1.0, yaw: float = 0.0) -> Image:
	_frame(z, f, pitch, yaw)
	await _wait(wait)
	return _save(nm)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.5)
	var f := M1 + Vector3(0, 2.0, 0)
	await _shot("bazaar_fire_z15", 15.0, f)
	await _shot("bazaar_fire_z30", 30.0, M1 + Vector3(0, 1.5, 0))
	await _shot("bazaar_fire_z40", 40.0, M1 + Vector3(0, 1.0, 0))
	await _shot("bazaar_fire_z55", 55.0, M1 + Vector3(4, 0.0, 6))
	await _shot("bazaar_fire_enemy_z30", 30.0, M1_ENEMY + Vector3(0, 1.0, 1))
	await _shot("bazaar_fire_gate_low", 13.0, M1 + Vector3(0, 2.6, 0), 24.0, 1.0, 90.0)
	await _shot("bazaar_fire_side_low", 13.0, M1 + Vector3(0, 3.0, 0), 20.0, 1.0, 0.0)
	await _shot("bazaar_fire_back_low", 13.0, M1 + Vector3(0, 3.0, 0), 20.0, 1.0, 180.0)
	# Delivery at the peak of the tip, selected.
	_frame(12.0, M1 + Vector3(0.0, 4.0, 0.5), 30.0, 0.0)
	await _wait(0.8)
	_main.call(&"set_selected", true)
	_main.call(&"play_delivery")
	await _wait(0.22)
	_save("bazaar_fire_delivery")
	await _wait(1.6)
	_main.call(&"set_selected", false)
	# States.
	var names: Array[String] = ["site0", "site35", "site70", "idle", "hp40", "hp20", "destroyed"]
	await _shot("bazaar_fire_states", 50.0, Vector3(0, 0, ROW_Z + 6.0), 55.0, 0.6)
	for i: int in 6:
		await _shot("bazaar_fire_state_" + names[i], 17.0, Vector3(ROW_X0 + ROW_STEP * i, 2.0, ROW_Z), 55.0, 0.5)
	_row[6].call(&"play_destroyed")
	await _shot("bazaar_fire_state_destroyed_1s", 17.0, Vector3(ROW_X0 + ROW_STEP * 6, 2.0, ROW_Z), 55.0, 1.1)
	await _shot("bazaar_fire_state_destroyed_3s", 17.0, Vector3(ROW_X0 + ROW_STEP * 6, 2.0, ROW_Z), 55.0, 2.2)
	await _silhouette([_main], "bazaar_fire_silhouette_z40", 40.0, M1 + Vector3(0, 2.0, 0))
	get_tree().quit()


func _sheet_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.5)
	var mid := Vector3(-15.0 + 5.0 * maxf(_sheet.size() - 1, 0), 2.0, SHEET_Z)
	var colour: Image = await _shot("bazaars_colour_tmp", 36.0, mid, 55.0, 0.8)
	var black: Image = await _silhouette(_sheet, "bazaars_silhouette_tmp", 36.0, mid)
	var w: int = colour.get_width()
	var h: int = colour.get_height()
	var band: int = int(h * 0.62)
	var y0: int = int(h * 0.19)
	var out := Image.create(w, band * 2, false, colour.get_format())
	out.blit_rect(colour, Rect2i(0, y0, w, band), Vector2i(0, 0))
	out.blit_rect(black, Rect2i(0, y0, w, band), Vector2i(0, band))
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/bazaars_silhouette.png"))
	for tmp: String in ["bazaars_colour_tmp", "bazaars_silhouette_tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % tmp))
	print("saved res://docs/art/screens/bazaars_silhouette.png (%d bazaars)" % _sheet.size())
	get_tree().quit()


## Black silhouettes on white of `models` (art-keep.md 0.1 test): everything else hidden.
func _silhouette(models: Array[Node3D], nm: String, z: float, f: Vector3) -> Image:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for n: Node in get_children():
		if n == _cam or n is WorldEnvironment:
			continue
		var keep: bool = false
		for m: Node3D in models:
			if n.is_ancestor_of(m):
				keep = true
		if n is Node3D and not keep:
			(n as Node3D).visible = false
	for m: Node3D in models:
		for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi is GPUParticles3D or gi.name.ends_with("Decal") or gi.name.ends_with("Pool") \
					or gi.name.begins_with("Rubble") or gi.name == "BuildOutline":
				gi.visible = false
			else:
				gi.material_override = black
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	return await _shot(nm, z, f, 55.0, 0.5)
