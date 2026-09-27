extends Node3D
## Caravan preview (task 10.V5). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . art/units/caravan/caravan_preview.tscn -- --shots
## writes docs/art/screens/caravan_*.png (states, teams_z40, poses, silhouette) then quits.
## Without --shots: keys 1-5 zoom 8 / 15 / 25 / 40 / 55 · L toggle loaded · W walk toggle · H hit · D death ·
## R revive · Y turn 45°.

const SCENE := "res://art/units/caravan/caravan.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "caravan_"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)
const SCALE_UNITS: Array = [["res://art/units/fire/flame_guard.tscn", FIRE], ["res://art/units/fire/blaze_rider.tscn", FIRE],
	["res://art/units/neutral/magpie/magpie.tscn", Color(0, 0, 0, 0)]]
const ORIGIN := Vector3(20.0, 0.0, 20.0)

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _walking: bool = false
var _loaded: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-1.4, 0, 0), 30.0, false, FIRE))
	_row.append(_spawn(Vector3(1.4, 0, 0), 30.0, true, FIRE))
	_set_zoom(9.0, Vector3(0.0, 0.8, 0.0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, loaded: bool, col: Color, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if m.has_method(&"set_loaded"):
		m.call(&"set_loaded", loaded)
	holder.add_child(m)
	if col.a > 0.0 and m.has_method(&"set_team_color"):
		m.call(&"set_team_color", col)
	return m


func _setup_world() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(_ground)


func _set_zoom(z: float, focus: Vector3 = Vector3.ZERO, pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	_cam.position = ORIGIN + focus + back * z
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(8.0, Vector3(0.0, 0.8, 0))
		KEY_2: _set_zoom(15.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L:
			_loaded = not _loaded
			for m: Node3D in _row:
				m.call(&"set_loaded", _loaded)
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m: Node3D in _row:
				m.call(&"set_moving", 4.0 if _walking else 0.0)


func _all(method: StringName) -> void:
	for m: Node3D in _row:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	await _states_sheet()
	await _teams_z40()
	await _poses_sheet()
	await _silhouettes()
	get_tree().quit()


## 2 x 3 sheet, empty (left) vs loaded (right), Fire: game camera close, side, 3/4 back (the deck), front,
## then the pair at 25 m and 40 m game zoom (crops, nearest upscale) next to a Flame Guard and a Blaze Rider.
func _states_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	var imgs: Array[Image] = []
	_place(a, Vector3(-1.5, 0, 0), 30.0)
	_place(b, Vector3(1.5, 0, 0), 30.0)
	_set_zoom(9.0, Vector3(0.0, 0.7, 0.0))
	await _wait(0.5)
	imgs.append(_grab())
	_place(a, Vector3(-1.9, 0, 0), 90.0)
	_place(b, Vector3(1.9, 0, 0), 90.0)
	_set_zoom(7.5, Vector3(0.0, 0.9, 0.0), 12.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-1.4, 0, 0), 160.0)
	_place(b, Vector3(1.4, 0, 0), 200.0)
	_set_zoom(7.5, Vector3(0.0, 0.8, 0.0), 42.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-1.3, 0, 0), -20.0)
	_place(b, Vector3(1.3, 0, 0), 20.0)
	_set_zoom(6.5, Vector3(0.0, 0.9, 0.0), 20.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-1.5, 0, 0), 30.0)
	_place(b, Vector3(1.5, 0, 0), 30.0)
	var extra: Array = []
	for i: int in 2:
		if ResourceLoader.exists(SCALE_UNITS[i][0]):
			extra.append(_spawn(Vector3(3.6 + 1.8 * float(i), 0, 0), 0.0, false, SCALE_UNITS[i][1], SCALE_UNITS[i][0]))
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(1.2, 0.0, 0.0))
		await _wait(0.5)
		imgs.append(_crop(_grab(), z, 1.0))
	for m: Node3D in extra:
		m.get_parent().queue_free()
	_sheet(imgs, 2, PREFIX + "states")


## The in-game read at 40 m (pitch 55): the four kingdom colours, loaded (top row) and empty (bottom row), two walking.
func _teams_z40() -> void:
	var cols: Array[Color] = [FIRE, SHADOW, ICE, NATURE]
	var extra: Array = []
	for m: Node3D in _row:
		m.get_parent().visible = false
	for i: int in 8:
		var loaded := i < 4
		var at := Vector3(-6.0 + 4.0 * float(i % 4), 0, -2.6 if loaded else 2.6)
		extra.append(_spawn(at, [20.0, 110.0, -45.0, 200.0][i % 4] + (0.0 if loaded else 35.0), loaded, cols[i % 4]))
	if ResourceLoader.exists(SCALE_UNITS[2][0]):
		extra.append(_spawn(Vector3(9.0, 0, -2.0), 200.0, false, SCALE_UNITS[2][1], SCALE_UNITS[2][0]))
	extra.append(_spawn(Vector3(9.0, 0, 2.0), 0.0, false, SCALE_UNITS[0][1], SCALE_UNITS[0][0]))
	await _wait(0.4)
	extra[1].call(&"set_moving", 3.6)
	extra[6].call(&"set_moving", 4.0)
	_set_zoom(40.0, Vector3(1.0, 0.0, 0.0))
	await _wait(0.8)
	var img := _grab()
	img.save_png(OUT + PREFIX + "teams_z40_full.png")
	_crop(img, 40.0, 2.0).save_png(OUT + PREFIX + "teams_z40.png")
	for m: Node3D in extra:
		m.get_parent().queue_free()
	for m: Node3D in _row:
		m.get_parent().visible = true


## Empty (left) and loaded (right, side-on): idle, walk x2, hit, load bump, death 0.3 / 0.6 / 0.9, revived.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	_place(a, Vector3(-1.6, 0, 0), 35.0)
	_place(b, Vector3(1.6, 0, 0), 90.0)
	_set_zoom(8.0, Vector3(0.0, 0.7, 0.0), 30.0)
	var pair: Array = [a, b]
	var frames: Array[Image] = []
	await _wait(0.5)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 4.0)
	await _wait(0.7)
	frames.append(_grab())
	await _wait(0.16)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 0.0)
	await _wait(0.6)
	for m: Node3D in pair:
		m.call(&"play_hit")
	await _wait(0.07)
	frames.append(_grab())
	await _wait(0.5)
	a.call(&"set_loaded", true)
	await _wait(0.18)
	frames.append(_grab())
	a.call(&"set_loaded", false)
	await _wait(0.6)
	for m: Node3D in pair:
		m.call(&"play_death")
	for t: float in [0.3, 0.6, 0.9]:
		await _until(b, &"_death_t", t)
		frames.append(_grab())
	await _wait(0.5)
	for m: Node3D in pair:
		m.call(&"revive")
	await _wait(0.3)
	frames.append(_grab())
	for i: int in frames.size():
		frames[i] = frames[i].get_region(Rect2i(150, 60, 1300, 780))
	_sheet(frames, 3, PREFIX + "poses")


## Unlit black on white (the 40 m black test): empty and loaded from 4 angles, one walking; at 25 m and 40 m next to
## a Blaze Rider (the other long unit) and a Magpie when it exists.
func _silhouettes() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var old_ground := _ground.material_override
	var old_env := _env.environment
	_ground.material_override = white
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	for m: Node3D in _row:
		m.get_parent().visible = false
	var units: Array = []
	var yaws: Array[float] = [90.0, 30.0, 180.0, 0.0]
	for i: int in 4:
		units.append(_spawn(Vector3(-7.0 + 3.6 * float(i), 0, 0), yaws[i], i % 2 == 1, FIRE))
	units[3].call(&"set_moving", 4.0)
	for i: int in [1, 2]:
		if ResourceLoader.exists(SCALE_UNITS[i][0]):
			units.append(_spawn(Vector3(7.4 + 2.4 * float(i - 1), 0, 0), 90.0 if i == 1 else 20.0, false,
				SCALE_UNITS[i][1], SCALE_UNITS[i][0]))
	await _wait(0.5)
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.6, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 22.0 / (1.66 * z))
		var h: int = int(float(w) * 0.30)
		var c := img.get_region(Rect2i(800 - w / 2, 470 - h / 2 - int(float(h) * 0.14), w, h))
		c.resize(1400, 420, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1400, 420 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1400, 420), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1400, 420), Vector2i(0, 428))
	out.save_png(OUT + PREFIX + "silhouette.png")
	_ground.material_override = old_ground
	_env.environment = old_env
	for m: Node3D in units:
		m.get_parent().queue_free()
	for m: Node3D in _row:
		m.get_parent().visible = true


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw_deg)


## Crop a window of the same world size at every zoom (~15 x 8.4 m x scale), nearest upscale to 800 x 450.
func _crop(img: Image, z: float, scale: float) -> Image:
	var w: int = clampi(int(1600.0 * 12.0 / z * 1.0 * scale), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - h / 2, 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800 * int(scale), 450 * int(scale), Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	if imgs[0].get_width() == 1300:
		w = 650
		h = 390
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


func _until(m: Object, prop: StringName, t: float) -> void:
	var guard := 0
	while float(m.get(prop)) < t and guard < 240:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
