extends Node3D
## Preview of the Dragon Roost (task 13.V25) from the RTS camera (pitch 55, fov 50) on the real ground: the player's
## Roost at the T3 slot (-33, 55) turned like Building does (gate toward the map centre: yaw -90) with the Fire keep, an
## Ember Hall, Flame Guards and a Cinder Dragon hovering beside the nest for scale; the enemy's mirror at (33, -55) in
## another team colour (seen from the local -X side); a row of states; a Roost for the raise flare.
## Windowed run `-- --shots` saves docs/art/screens/13_v25_*.png (z40, views, annex, raise, states, silhouette), quits.
## By hand: wheel = zoom, 1 = player Roost, 2 = enemy mirror, 3 = states row, 4 = raise Roost, R = raise, C = crucible
## on / off, F = forge, S = select, P = training pulse, Q / E = orbit the camera.

const ROOST: PackedScene = preload("res://art/buildings/lair/fire/dragon_roost.tscn")
const KEEP_PATH := "res://art/buildings/fire_keep.tscn"
const HALL_PATH := "res://art/buildings/fire_hall.tscn"
const GUARD_PATH := "res://art/units/fire/flame_guard.tscn"
const DRAGON_PATH := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const T3 := Vector3(-33, 0, 55)
const T3_ENEMY := Vector3(33, 0, -55)
const ROW_Z := 20.0
const ROW_X0 := -42.0
const ROW_STEP := 12.0
const RAISE_AT := Vector3(0, 0, -20)
const TILE := Vector2i(800, 450)

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var yaw_degrees: float = 0.0
@export var focus: Vector3 = T3 + Vector3(0, 3.0, 0)

@onready var _cam: Camera3D = $Camera3D
@onready var _env: WorldEnvironment = $WorldEnvironment

var _main: Node3D
var _mirror: Node3D
var _raiser: Node3D
var _row: Array[Node3D] = []
var _sel: bool = false
var _lit: bool = false


func _ready() -> void:
	_build_scene()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


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


func _unit(path: String, pos: Vector3, yaw: float, team: Color) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var u := (load(path) as PackedScene).instantiate() as Node3D
	add_child(u)
	u.position = pos
	u.rotation.y = yaw
	if u.has_method(&"set_team_color"):
		u.call(&"set_team_color", team)
	return u


func _build_scene() -> void:
	_main = _place(ROOST, T3, -PI * 0.5, FIRE)
	_mirror = _place(ROOST, T3_ENEMY, PI * 0.5, SHADOW)
	if ResourceLoader.exists(KEEP_PATH):
		_place(load(KEEP_PATH) as PackedScene, T3 + Vector3(-12, 0, -14), -PI * 0.5, FIRE)
	if ResourceLoader.exists(HALL_PATH):
		_place(load(HALL_PATH) as PackedScene, T3 + Vector3(-1, 0, -11), -PI * 0.5, FIRE)
	for i: int in 3:
		_unit(GUARD_PATH, T3 + Vector3(4.3 + 0.9 * i, 0, -1.2 + 0.7 * i), PI * 0.5, FIRE)
	if ResourceLoader.exists(DRAGON_PATH):
		var d := (load(DRAGON_PATH) as PackedScene).instantiate() as Node3D
		if "fly_height" in d:
			d.set(&"fly_height", 7.0)
		add_child(d)
		d.position = T3 + Vector3(7.5, 0, 4.5)
		d.rotation.y = PI * 0.75
		if d.has_method(&"set_team_color"):
			d.call(&"set_team_color", FIRE)
	_raiser = _place(ROOST, RAISE_AT, -PI * 0.5, FIRE)
	# States row (player orientation): site 0 / 35 / 70 %, idle, 40 %, 20 %, two to destroy.
	var states: Array[float] = [0.0, 0.35, 0.7, 1.0, 1.0, 1.0, 1.0, 1.0]
	for i: int in states.size():
		var m := _place(ROOST, Vector3(ROW_X0 + ROW_STEP * i, 0, ROW_Z), -PI * 0.5, FIRE)
		m.call(&"set_construction_progress", states[i])
		_row.append(m)
	_row[4].call(&"set_health_ratio", 0.4)
	_row[5].call(&"set_health_ratio", 0.2)
	for i: int in [6, 7]:
		_row[i].call(&"set_crucible", true, true)


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
				focus = T3 + Vector3(0, 3, 0)
			KEY_2:
				focus = T3_ENEMY + Vector3(0, 3, 0)
			KEY_3:
				focus = Vector3(ROW_X0 + ROW_STEP * 3.5, 0, ROW_Z)
			KEY_4:
				focus = RAISE_AT + Vector3(0, 3, 0)
			KEY_R:
				_main.call(&"play_raise")
				_raiser.call(&"play_raise")
			KEY_C:
				_lit = not _lit
				_main.call(&"set_crucible", _lit)
				_mirror.call(&"set_crucible", _lit)
			KEY_F:
				_main.call(&"play_forge")
				_mirror.call(&"play_forge")
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


# ---------------------------------------------------------------- shots

func _grab() -> Image:
	return get_viewport().get_texture().get_image()


func _save_img(img: Image, nm: String) -> void:
	var path: String = "res://docs/art/screens/%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " (", img.get_width(), " x ", img.get_height(), ") fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frame(z: float, f: Vector3, pitch: float = 55.0, yaw: float = 0.0) -> void:
	zoom = z
	focus = f
	pitch_degrees = pitch
	yaw_degrees = yaw
	_apply()


func _tile(z: float, f: Vector3, pitch: float = 55.0, wait: float = 0.6, yaw: float = 0.0) -> Image:
	_frame(z, f, pitch, yaw)
	await _wait(wait)
	var img := _grab()
	img.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
	return img


func _sheet(tiles: Array[Image], cols: int, nm: String) -> void:
	var rows: int = ceili(float(tiles.size()) / cols)
	var out := Image.create(TILE.x * cols, TILE.y * rows, false, tiles[0].get_format())
	for i: int in tiles.size():
		out.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, TILE), Vector2i((i % cols) * TILE.x, (i / cols) * TILE.y))
	_save_img(out, nm)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.5)
	# 1. Game camera, zoom 40, the player's base corner (full resolution).
	_frame(40.0, T3 + Vector3(-3, 0, -5))
	await _wait(1.0)
	_save_img(_grab(), "13_v25_z40")
	# 2. Views: player side close, enemy side close, gate low, back low, perch low (from -X), top.
	var views: Array[Image] = []
	views.append(await _tile(16.0, T3 + Vector3(0, 3.5, 0)))
	views.append(await _tile(16.0, T3_ENEMY + Vector3(0, 3.5, 0)))
	views.append(await _tile(15.0, T3 + Vector3(0, 4.0, 0), 18.0, 0.6, 90.0))
	views.append(await _tile(15.0, T3 + Vector3(0, 4.0, 0), 18.0, 0.6, -90.0))
	views.append(await _tile(14.0, T3 + Vector3(0, 5.0, 0), 12.0, 0.6, 0.0))
	views.append(await _tile(17.0, T3 + Vector3(0, 0.0, 0), 88.0, 0.6))
	_sheet(views, 3, "13_v25_views")
	# 3. Annex: without (player), with (player), with (enemy camera), forging (close).
	var annex: Array[Image] = []
	annex.append(await _tile(17.0, T3 + Vector3(0, 2.5, 0)))
	_main.call(&"set_crucible", true)
	_mirror.call(&"set_crucible", true)
	await _wait(1.6)
	annex.append(await _tile(17.0, T3 + Vector3(0, 2.5, 0)))
	annex.append(await _tile(17.0, T3_ENEMY + Vector3(0, 2.5, 0)))
	# The annex from the enemy camera, close (the mirror's anchor lands at world (-1.85, -1.85) from its centre).
	annex.append(await _tile(10.0, T3_ENEMY + Vector3(-1.85, 1.4, -1.85)))
	annex.append(await _tile(10.0, T3_ENEMY + Vector3(-1.85, 1.4, -1.85), 40.0, 0.4, -35.0))
	# The player's anchor lands at world (+1.85, +1.85).
	_frame(9.0, T3 + Vector3(1.85, 1.6, 1.85), 40.0, 0.0)
	await _wait(0.4)
	_main.call(&"play_forge")
	await _wait(0.5)
	var forge := _grab()
	forge.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
	annex.append(forge)
	_sheet(annex, 3, "13_v25_annex")
	# 4. Raise flare: before, 0.35 s (peak), 0.8 s, 1.6 s.
	var raise: Array[Image] = []
	_frame(20.0, RAISE_AT + Vector3(0, 4.0, 0), 45.0)
	await _wait(0.6)
	var r0 := _grab()
	r0.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
	raise.append(r0)
	_raiser.call(&"play_raise")
	for t: float in [0.4, 0.45, 0.8]:
		await _wait(t)
		var img := _grab()
		img.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
		raise.append(img)
	_sheet(raise, 2, "13_v25_raise")
	# 5. States: site 0 / 35 / 70, idle, 40 %, 20 %, destroyed 1 s, destroyed 3 s (the wreck).
	var states: Array[Image] = []
	for i: int in 6:
		states.append(await _tile(14.0, Vector3(ROW_X0 + ROW_STEP * i, 3.0, ROW_Z), 55.0, 0.5))
	_row[6].call(&"play_destroyed")
	_row[7].call(&"play_destroyed")
	states.append(await _tile(14.0, Vector3(ROW_X0 + ROW_STEP * 6, 3.0, ROW_Z), 55.0, 1.0))
	states.append(await _tile(14.0, Vector3(ROW_X0 + ROW_STEP * 7, 2.0, ROW_Z), 55.0, 2.4))
	_sheet(states, 4, "13_v25_states")
	# 6. Silhouettes at 40 m: colour player / enemy on top, black below.
	var sil: Array[Image] = []
	sil.append(await _tile(40.0, T3 + Vector3(0, 3.0, 0)))
	sil.append(await _tile(40.0, T3_ENEMY + Vector3(0, 3.0, 0)))
	_blacken([_main, _mirror])
	sil.append(await _tile(40.0, T3 + Vector3(0, 3.0, 0), 55.0, 0.5))
	sil.append(await _tile(40.0, T3_ENEMY + Vector3(0, 3.0, 0), 55.0, 0.5))
	_sheet(sil, 2, "13_v25_silhouette")
	get_tree().quit()


## Black silhouettes on white of `models` (art-keep.md 0.1 test): everything else hidden.
func _blacken(models: Array[Node3D]) -> void:
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
			if gi is GPUParticles3D or gi.name.contains("Decal") or gi.name.ends_with("Pool") \
					or gi.name.begins_with("Rubble") or gi.name == "BuildOutline":
				gi.visible = false
			else:
				gi.material_override = black
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
