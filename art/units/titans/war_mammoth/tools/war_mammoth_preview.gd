extends Node3D
## War Mammoth + howdah preview (tasks 13.V16 / 13.V17). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/titans/war_mammoth/tools/war_mammoth_preview.tscn
##       --resolution 1600x900 --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v16_*.png (views, walk, trample, poses, howdah_shot, teams, lineup, z40, silhouette)
## then quits. Without --shots: keys 1-5 zoom 8 / 14 / 25 / 40 / 55 · W walk · T trample · A gore · S howdah shot
## (target to the right) · U shot at a flyer · H hit · F fidget · D death · R revive · C team colour · Y turn 45.

const SCENE := "res://art/units/titans/war_mammoth/war_mammoth.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v16_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const TEAMS: Array[Color] = [Color(0.45, 0.75, 0.95), Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.35, 0.70, 0.25)]
## Ice army + Ice mount / titan for the lineups (skipped when missing).
const ICE_UNITS: Array[String] = ["res://art/units/ice/rimeshield.tscn", "res://art/units/ice/shardcaster.tscn",
	"res://art/units/ice/rime_seer.tscn", "res://art/units/ice/rime_colossus.tscn", "res://art/units/mounts/rimehorn/rimehorn.tscn",
	"res://art/units/wizards/torvald.tscn"]
## Big neutral beasts it must never be confused with.
const BEASTS: Array[String] = ["res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn",
	"res://art/units/neutral/beasts/tusker/tusker.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _team_i: int = 0
var _moving: float = 0.0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3.ZERO, 30.0))
	_set_zoom(12.0, Vector3(0, 2.0, 0.5))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, team: Color = TEAMS[0], path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if &"fidget_every" in m:
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
		KEY_1: _set_zoom(8.0, Vector3(0.0, 2.0, 0.5))
		KEY_2: _set_zoom(14.0, Vector3(0.0, 1.5, 0.0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W:
			_moving = 0.0 if _moving > 0.0 else 3.4
			_all_call(&"set_moving", [_moving])
		KEY_T: _all_call(&"play_trample", [])
		KEY_A: _all_call(&"play_attack", [])
		KEY_S:
			for m: Node3D in _row:
				m.call(&"play_howdah_shot", m.global_transform * Vector3(12, 1, 2))
		KEY_U:
			for m: Node3D in _row:
				m.call(&"play_howdah_shot", m.global_transform * Vector3(-2, 10, 8))
		KEY_H: _all_call(&"play_hit", [])
		KEY_F: _all_call(&"play_fidget", [])
		KEY_D: _all_call(&"play_death", [])
		KEY_R: _all_call(&"revive", [])
		KEY_C:
			_team_i = (_team_i + 1) % TEAMS.size()
			_all_call(&"set_team_color", [TEAMS[_team_i]])
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)


func _all_call(method: StringName, args: Array) -> void:
	for m: Node3D in _row:
		m.callv(method, args)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	await _views_sheet()
	await _walk_sheet()
	await _trample_sheet()
	await _poses_sheet()
	await _howdah_sheet()
	await _teams_sheet()
	await _lineup()
	await _z40()
	await _silhouettes()
	print("WAR MAMMOTH SHOTS DONE")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m: Node3D in _row:
		m.get_parent().visible = not on


## 2 x 3: game camera close (3/4 front), side, 3/4 back, a low close-up on the head / tusks, top view, 25 m crop.
func _views_sheet() -> void:
	var a: Node3D = _row[0]
	var imgs: Array[Image] = []
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(12.5, Vector3(0.0, 2.0, 0.4))
	await _wait(0.5)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(10.5, Vector3(0.6, 2.2, 0.0), 8.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 215.0)
	_set_zoom(11.0, Vector3(0.0, 2.2, 0.0), 32.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 150.0)
	_set_zoom(5.2, Vector3(1.8, 2.3, 1.9), 10.0, 25.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 0.0)
	_set_zoom(11.5, Vector3(0.0, 1.5, 0.8), 82.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(25.0, Vector3(0.0, 1.0, 0.0))
	await _wait(0.3)
	imgs.append(_crop(_grab(), 25.0, 1.5))
	_sheet(imgs, 3, PREFIX + "views")


## 2 x 3 frames of one walk cycle from the side.
func _walk_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(10.5, Vector3(0.6, 2.2, 0.0), 6.0)
	a.call(&"set_moving", 3.4)
	await _wait(1.2)
	await _until_phase(a, 0.0)
	var imgs: Array[Image] = []
	for i: int in 6:
		imgs.append(_grab())
		await _wait(0.95 / 6.0)
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	_sheet(imgs, 3, PREFIX + "walk")


## Trample while walking, 3/4 front: the first (trumpet) at t 0.1 / 0.2 (stomp) / 0.35, then a plain one (the other
## side) at 0.12 / 0.2 / 0.3.
func _trample_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 35.0)
	_set_zoom(9.5, Vector3(0.6, 2.0, 1.0), 30.0, 20.0)
	a.call(&"set_moving", 3.4)
	await _wait(3.4)
	var imgs: Array[Image] = []
	a.call(&"play_trample")
	for t: float in [0.1, 0.2, 0.35]:
		await _until(a, &"_tr_t", t)
		imgs.append(_grab())
	await _wait(0.8)
	a.call(&"play_trample")
	for t: float in [0.12, 0.2, 0.3]:
		await _until(a, &"_tr_t", t)
		imgs.append(_grab())
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "trample")


## Standing, gore (rear 0.08, strike 0.14, rake 0.3), hit, fidget trumpet, death 0.3 / 0.6 / 1.0, revive.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 55.0)
	_set_zoom(12.0, Vector3(0.0, 1.8, 0.6), 22.0, 15.0)
	var imgs: Array[Image] = []
	await _wait(0.3)
	imgs.append(_grab())
	a.call(&"play_attack")
	for t: float in [0.08, 0.14, 0.3]:
		await _until(a, &"_action_t", t)
		imgs.append(_grab())
	await _wait(0.8)
	a.call(&"play_hit")
	await _wait(0.05)
	imgs.append(_grab())
	await _wait(0.5)
	a.call(&"play_fidget")
	await _until(a, &"_action_t", 1.0)
	imgs.append(_grab())
	await _wait(1.8)
	a.call(&"play_death")
	for t: float in [0.3, 0.6, 1.0]:
		await _until(a, &"_death_t", t)
		imgs.append(_grab())
	await _wait(0.3)
	a.call(&"revive")
	await _wait(0.5)
	imgs.append(_grab())
	for i: int in imgs.size():
		imgs[i] = imgs[i].get_region(Rect2i(250, 60, 1100, 780))
	_sheet(imgs, 5, PREFIX + "poses")


## The howdah archer close up: rest, full draw (0.10), released (0.14), reaching to the quiver (0.5), nocking (0.8),
## turned to a target on the right, aiming up at a flyer, and a red-team howdah.
func _howdah_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 0.0)
	var focus := Vector3(0.0, 4.05, -0.72)
	_set_zoom(4.2, focus, 28.0, 52.0)
	var h: Node3D = a.call(&"get_howdah")
	var imgs: Array[Image] = []
	await _wait(0.4)
	imgs.append(_grab())
	var fwd := a.global_transform * Vector3(0.0, 3.0, 14.0)
	a.call(&"play_howdah_shot", fwd)
	for t: float in [0.10, 0.14, 0.5, 0.8]:
		await _until(h, &"_shot_t", t)
		imgs.append(_grab())
	await _wait(1.8)
	a.call(&"play_howdah_shot", a.global_transform * Vector3(12.0, 1.0, 2.0))
	await _until(h, &"_shot_t", 0.10)
	imgs.append(_grab())
	await _wait(2.0)
	a.call(&"play_howdah_shot", a.global_transform * Vector3(-1.0, 12.0, 7.0))
	await _until(h, &"_shot_t", 0.10)
	imgs.append(_grab())
	await _wait(2.0)
	a.call(&"set_team_color", TEAMS[1])
	_set_zoom(7.5, focus + Vector3(0.0, -0.8, 0.4), 40.0, 30.0)
	await _wait(0.4)
	imgs.append(_grab())
	a.call(&"set_team_color", TEAMS[0])
	_sheet(imgs, 4, PREFIX + "howdah_shot")


## The 4 team colours side by side at the game camera (14 m), then at 40 m.
func _teams_sheet() -> void:
	_hide_row(true)
	var ms: Array = []
	for i: int in 4:
		ms.append(_spawn(Vector3(-9.0 + 6.0 * float(i), 0, 0), 25.0, TEAMS[i]))
	var imgs: Array[Image] = []
	_set_zoom(16.0, Vector3(0.0, 1.5, 0.0), 45.0)
	await _wait(0.5)
	imgs.append(_grab())
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.4)
	imgs.append(_crop(_grab(), 40.0, 3.0))
	for m: Node3D in ms:
		m.get_parent().queue_free()
	_hide_row(false)
	_sheet(imgs, 2, PREFIX + "teams")


## Next to the Ice army (game camera, 16 m): Rimeshield, Shardcaster, Rime Seer, Rime Colossus, Rimehorn, Torvald.
func _lineup() -> void:
	_hide_row(true)
	var extra: Array = []
	var mm := _spawn(Vector3(-4.5, 0, 0), 20.0)
	extra.append(mm)
	var x := 0.0
	for p: String in ICE_UNITS:
		if ResourceLoader.exists(p):
			extra.append(_spawn(Vector3(x, 0, 0.5), 20.0, TEAMS[0], p))
			x += 1.8 if not (p.ends_with("colossus.tscn") or p.ends_with("rimehorn.tscn")) else 3.0
	await _wait(0.4)
	_set_zoom(16.0, Vector3(1.5, 1.2, 0.0), 55.0)
	await _wait(0.6)
	_grab().save_png(OUT + PREFIX + "lineup.png")
	for m: Node3D in extra:
		m.get_parent().queue_free()
	_hide_row(false)


## The in-game read at 40 m: a standing, a walking and a trampling Mammoth (one red) next to the Ice army and the
## big neutral beasts (Grizzlemaw, Tusker).
func _z40() -> void:
	_hide_row(true)
	var ms: Array = []
	ms.append(_spawn(Vector3(-9.0, 0, 1.0), 20.0))
	ms.append(_spawn(Vector3(-3.0, 0, -1.5), 150.0, TEAMS[1]))
	ms.append(_spawn(Vector3(3.0, 0, 1.0), 70.0))
	var extra: Array = []
	var x := 7.0
	for p: String in ICE_UNITS + BEASTS:
		if ResourceLoader.exists(p):
			extra.append(_spawn(Vector3(x, 0, 0), 20.0, TEAMS[0], p))
			x += 1.8 if not (p.contains("colossus") or p.contains("rimehorn") or p.contains("beasts")) else 3.2
	await _wait(0.3)
	ms[1].call(&"set_moving", 3.4)
	ms[2].call(&"set_moving", 3.4)
	_set_zoom(40.0, Vector3(4.0, 0.0, 0.0))
	await _wait(1.2)
	ms[2].call(&"play_trample")
	await _wait(0.2)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 3.2).save_png(OUT + PREFIX + "z40.png")
	for m: Node3D in ms + extra:
		m.get_parent().queue_free()
	_hide_row(false)


## Unlit black on white (the 40 m black test): the Mammoth side, 3/4 front, walking, 3/4 back, next to the Rimehorn,
## Rime Colossus, Grizzlemaw and Tusker; at 25 m and 40 m.
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
	var yaws: Array[float] = [90.0, 30.0, 60.0, 210.0]
	for i: int in 4:
		units.append(_spawn(Vector3(-16.0 + 6.2 * float(i), 0, 0), yaws[i]))
	units[2].call(&"set_moving", 3.4)
	var x := 8.5
	for p: String in ["res://art/units/mounts/rimehorn/rimehorn.tscn", "res://art/units/ice/rime_colossus.tscn"] + BEASTS:
		if ResourceLoader.exists(p):
			units.append(_spawn(Vector3(x, 0, 0), 60.0, TEAMS[0], p))
			x += 4.2
	await _wait(0.6)
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 46.0 / (1.66 * z))
		var h: int = int(float(w) * 0.30)
		var c := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - mini(w, 1600)), clampi(470 - h / 2, 0, 900 - mini(h, 900)),
			mini(w, 1600), mini(h, 900)))
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


## Crop a window of the same world size at every zoom (x widen), nearest upscale to 800 x 450.
func _crop(img: Image, z: float, widen: float = 1.0) -> Image:
	var iw := img.get_width()
	var ih := img.get_height()
	var w: int = clampi(int(float(iw) * 13.0 / z * 0.55 * widen), 80, iw)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(iw / 2 - w / 2, 0, iw - w), clampi(ih / 2 - h / 2 - int(h * 0.1), 0, ih - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	if imgs[0].get_width() == 1100:
		w = 550
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
	while float(m.get(prop)) < t and guard < 300:
		await get_tree().process_frame
		guard += 1


## Waits until the gait phase wraps past `p` (0-1).
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
