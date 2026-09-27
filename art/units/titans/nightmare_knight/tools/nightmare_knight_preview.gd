extends Node3D
## Nightmare Knight preview (task 13.V15). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/titans/nightmare_knight/tools/nightmare_knight_preview.tscn
##       --fixed-fps 60 --quit-after 9000 -- --shots
## writes docs/art/screens/13_v15_*.png (views, detail, gallop, charge, poses, teams, z40, silhouette) then quits.
## Without --shots: keys 1-5 zoom 6 / 12 / 25 / 40 / 55 · W walk · G gallop · C charge · A attack · H hit · F fidget
## · D death · R revive · S smoke toggle · T team colour · Y turn 45.

const SCENE := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v15_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const TEAMS: Array[Color] = [Color(0.42, 0.22, 0.60), Color(0.85, 0.30, 0.12), Color(0.45, 0.75, 0.95), Color(0.35, 0.70, 0.25)]
const SHADOW_UNITS: Array[String] = ["res://art/units/shadow/shadow_knight.tscn", "res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/shade.tscn", "res://art/units/shadow/nightbolt.tscn", "res://art/units/shadow/grave_hound.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _team_i: int = 0
var _moving: float = 0.0
var _smoke: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3.ZERO, 30.0))
	_set_zoom(10.0, Vector3(0, 1.8, 0.3))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, team: Color = TEAMS[0], path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if m.has_method(&"play_fidget"):
		m.set(&"fidget_every", 0.0)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", team)
	holder.add_child(m)
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
	pm.size = Vector2(300, 300)
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
		KEY_1: _set_zoom(6.0, Vector3(0.0, 2.2, 0))
		KEY_2: _set_zoom(12.0, Vector3(0.0, 1.5, 0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W: _move(0.0 if _moving == 2.0 else 2.0)
		KEY_G: _move(0.0 if _moving == 8.0 else 8.0)
		KEY_C: _all(&"play_charge")
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_F: _all(&"play_fidget")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_S:
			_smoke = not _smoke
			for m: Node3D in _row:
				m.call(&"set_gallop_smoke", _smoke)
		KEY_T:
			_team_i = (_team_i + 1) % TEAMS.size()
			for m: Node3D in _row:
				m.call(&"set_team_color", TEAMS[_team_i])
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)


func _move(v: float) -> void:
	_moving = v
	for m: Node3D in _row:
		m.call(&"set_moving", v)


func _all(method: StringName) -> void:
	for m: Node3D in _row:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _views_sheet()
	await _detail_sheet()
	await _gallop_sheet()
	await _charge_sheet()
	await _poses_sheet()
	await _teams_sheet()
	await _z40()
	await _silhouettes()
	print("NIGHTMARE KNIGHT SHOTS DONE")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m: Node3D in _row:
		m.get_parent().visible = not on


## 2 x 3: game camera close (3/4 front), side, 3/4 back, front low, top view, 25 m crop.
func _views_sheet() -> void:
	var a: Node3D = _row[0]
	var imgs: Array[Image] = []
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(7.5, Vector3(0.0, 2.0, 0.3))
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(9.5, Vector3(0.0, 2.3, 0.0), 6.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 215.0)
	_set_zoom(9.5, Vector3(0.0, 2.0, 0.0), 28.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 180.0 + 150.0)
	_set_zoom(8.5, Vector3(0.0, 2.2, 0.0), 10.0, -10.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 0.0)
	_set_zoom(10.0, Vector3(0.0, 1.0, 0.4), 82.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(25.0, Vector3(0.0, 0.5, 0.0))
	await _wait(0.3)
	imgs.append(_crop(_grab(), 25.0))
	_sheet(imgs, 3, PREFIX + "views")


## Close-ups: the knight (helm, crest, pauldrons), the horse head, a burning hoof, the lance head, the shield.
func _detail_sheet() -> void:
	var a: Node3D = _row[0]
	var imgs: Array[Image] = []
	_place(a, Vector3.ZERO, 35.0)
	_set_zoom(3.4, Vector3(0.05, 3.1, -0.1), 14.0, 10.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 120.0)
	_set_zoom(2.6, Vector3(1.3, 2.4, -0.9), 10.0, 15.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 60.0)
	_set_zoom(2.0, Vector3(0.7, 0.3, 0.1), 12.0, 10.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, -60.0)
	_set_zoom(4.2, Vector3(-0.9, 2.5, 0.3), 8.0, -30.0)
	await _wait(0.3)
	imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "detail")


## One gallop stride from the side (6 frames) with the smoke trail running.
func _gallop_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(10.0, Vector3(0.0, 2.2, 0.0), 8.0)
	a.call(&"set_moving", 8.0)
	await _wait(1.2)
	await _until_phase(a, 0.0)
	var imgs: Array[Image] = []
	for i: int in 6:
		imgs.append(_grab())
		await _wait(0.43 / 6.0)
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "gallop")


## Moving the model across the ground so the world-space smoke trail streams: galloping, then the charge frames.
func _charge_sheet() -> void:
	var a: Node3D = _row[0]
	var h: Node3D = a.get_parent()
	_place(a, Vector3(-12, 0, 0), 90.0)
	a.call(&"set_moving", 8.0)
	var imgs: Array[Image] = []
	var t := 0.0
	while t < 1.4:
		await get_tree().process_frame
		var dt := 1.0 / 60.0
		t += dt
		h.position.x += 8.0 * dt
		_set_zoom(8.5, Vector3(h.position.x - ORIGIN.x, 2.0, 0.0), 22.0, 25.0)
	imgs.append(_grab())
	a.call(&"play_charge")
	var marks: Array[float] = [0.06, 0.10, 0.2, 0.35, 0.6]
	var k := 0
	var ct := 0.0
	while k < marks.size():
		await get_tree().process_frame
		var dt := 1.0 / 60.0
		ct += dt
		h.position.x += 8.0 * dt
		_set_zoom(8.5, Vector3(h.position.x - ORIGIN.x, 2.0, 0.0), 22.0, 25.0)
		if ct >= marks[k]:
			imgs.append(_grab())
			k += 1
	a.call(&"set_moving", 0.0)
	_place(a, Vector3.ZERO, 30.0)
	await _wait(1.2)
	_sheet(imgs, 3, PREFIX + "charge")


## Idle, lance strike (0.08 / 0.14 / 0.4), hit, fidget, death 0.4 / 0.9 / 1.3, revive.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 55.0)
	_set_zoom(10.0, Vector3(0.0, 1.8, 0.4), 20.0, 15.0)
	var imgs: Array[Image] = []
	await _wait(0.3)
	imgs.append(_grab())
	a.call(&"play_attack")
	for tt: float in [0.08, 0.14, 0.4]:
		await _until(a, &"_action_t", tt)
		imgs.append(_grab())
	await _wait(0.8)
	a.call(&"play_hit")
	await _wait(0.05)
	imgs.append(_grab())
	await _wait(0.5)
	a.call(&"play_fidget")
	await _until(a, &"_action_t", 0.5)
	imgs.append(_grab())
	await _wait(1.6)
	a.call(&"play_death")
	for tt: float in [0.4, 0.9, 1.3]:
		await _until(a, &"_death_t", tt)
		imgs.append(_grab())
	await _wait(0.6)
	a.call(&"revive")
	await _wait(0.5)
	imgs.append(_grab())
	for i: int in imgs.size():
		imgs[i] = imgs[i].get_region(Rect2i(250, 30, 1100, 800))
	_sheet(imgs, 5, PREFIX + "poses")


## The 4 kingdom colours side by side at the game camera, then at 40 m.
func _teams_sheet() -> void:
	_hide_row(true)
	var ms: Array = []
	for i: int in 4:
		ms.append(_spawn(Vector3(-6.3 + 4.2 * float(i), 0, 0), 25.0, TEAMS[i]))
	var imgs: Array[Image] = []
	_set_zoom(16.0, Vector3(0.0, 1.5, 0.0), 42.0)
	await _wait(0.5)
	imgs.append(_grab())
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.4)
	imgs.append(_crop(_grab(), 40.0, 2.6))
	for m: Node3D in ms:
		m.get_parent().queue_free()
	_hide_row(false)
	_sheet(imgs, 2, PREFIX + "teams")


## The in-game read at 40 m: a standing, a galloping and a charging Nightmare Knight among the Shadow army (Shadow
## Knight, Gloom Thrall, Shade, Nightbolt, Grave Hound), and one enemy-coloured Knight.
func _z40() -> void:
	_hide_row(true)
	var ms: Array = []
	ms.append(_spawn(Vector3(-4.0, 0, 0.5), 20.0))
	ms.append(_spawn(Vector3(1.0, 0, -1.0), 70.0))
	ms.append(_spawn(Vector3(5.5, 0, 1.2), -30.0, TEAMS[1]))
	var extra: Array = []
	var x := -4.5
	for p: String in SHADOW_UNITS:
		if ResourceLoader.exists(p):
			extra.append(_spawn(Vector3(x, 0, 3.6), 20.0, TEAMS[0], p))
			x += 1.9
	await _wait(0.3)
	ms[1].call(&"set_moving", 8.0)
	ms[2].call(&"set_moving", 8.0)
	_set_zoom(40.0, Vector3(0.5, 0.0, 1.0))
	await _wait(1.0)
	ms[2].call(&"play_charge")
	await _wait(0.1)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.2).save_png(OUT + PREFIX + "z40.png")
	for m: Node3D in ms + extra:
		m.get_parent().queue_free()
	_hide_row(false)


## Unlit black on white (the 40 m black test): side, 3/4 front, 3/4 back, galloping, charging; the Shadow army beside.
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
	_hide_row(true)
	var units: Array = []
	var yaws: Array[float] = [90.0, 30.0, 200.0, 60.0, -40.0]
	for i: int in 5:
		units.append(_spawn(Vector3(-13.0 + 4.6 * float(i), 0, 0), yaws[i]))
	units[3].call(&"set_moving", 8.0)
	var x := 10.5
	for p: String in SHADOW_UNITS:
		units.append(_spawn(Vector3(x, 0, 0), 20.0, TEAMS[0], p))
		x += 1.7
	await _wait(0.6)
	units[4].call(&"play_charge")
	await _wait(0.1)
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(1.0, 0.0, 0.0))
		await _wait(0.2)
		var img := _grab()
		var w: int = int(1600.0 * 38.0 / (1.66 * z))
		var hh: int = int(float(w) * 0.30)
		var c := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - hh / 2 - 20, 0, 900 - hh), mini(w, 1600),
			mini(hh, 900)))
		c.resize(1600, 480, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1600, 480 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1600, 480), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1600, 480), Vector2i(0, 488))
	out.save_png(OUT + PREFIX + "silhouette.png")
	_ground.material_override = old_ground
	_env.environment = old_env
	for m: Node3D in units:
		m.get_parent().queue_free()
	_hide_row(false)


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw_deg)


func _crop(img: Image, z: float, widen: float = 1.0) -> Image:
	var w: int = clampi(int(1600.0 * 13.0 / z * 0.55 * widen * 1.4), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - h / 2 - int(h * 0.1), 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	if imgs[0].get_width() == 1100:
		w = 550
		h = 400
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


func _until_phase(m: Object, p: float) -> void:
	var guard := 0
	var last: float = float(m.call(&"gait_phase"))
	while guard < 240:
		await get_tree().process_frame
		guard += 1
		var now: float = float(m.call(&"gait_phase"))
		if (last < p and now >= p) or (now < last and (p <= now or p > last)):
			return
		last = now


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
