extends Node3D
## Frostrune Rifleman preview (task 13b.V2, built on the Grove Stag preview). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . --resolution 1600x900 art/units/ice/frostrune_rifleman/tools/frostrune_rifleman_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13b_v2_*.png (views, braced, aim, shot, poses, teams, z40, silhouette) then quits
## (`--only=<name>` for one sheet). Without --shots: keys 1-5 zoom 4 / 8 / 25 / 40 / 55 · B brace toggle · A aim 1.2 s ·
## F fire · W walk · H hit · G fidget · D death · R revive · T team colour · Y turn 45.

const SCENE := "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"
const SHARD := "res://art/units/ice/shardcaster.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13b_v2_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const ICE := Color(0.45, 0.75, 0.95)
const TEAMS: Array[Color] = [Color(0.45, 0.75, 0.95), Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.35, 0.70, 0.25)]
const OTHERS: Array[String] = ["res://art/units/ice/rimeshield.tscn", "res://art/units/ice/rime_seer.tscn"]
const WALK_V := 3.6

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _team_i: int = 0
var _brace_on: bool = false
var _walking: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3.ZERO, 30.0))
	_set_zoom(5.5, Vector3(0.0, 1.0, 0.4))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, team: Color = ICE, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	m.set(&"fidget_every", 0.0)
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
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(4.0, Vector3(0.0, 1.0, 0.4))
		KEY_2: _set_zoom(8.0, Vector3(0.0, 0.8, 0.3))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_B:
			_brace_on = not _brace_on
			_all(&"set_braced", [_brace_on])
		KEY_A: _all(&"play_aim", [1.2])
		KEY_F: _all(&"play_attack")
		KEY_W:
			_walking = not _walking
			_all(&"set_moving", [WALK_V if _walking else 0.0])
		KEY_H: _all(&"play_hit")
		KEY_G: _all(&"play_fidget")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_T:
			_team_i = (_team_i + 1) % TEAMS.size()
			_all(&"set_team_color", [TEAMS[_team_i]])
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)


func _all(method: StringName, args: Array = []) -> void:
	for m: Node3D in _row:
		m.callv(method, args)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var only: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	await _wait(1.0)
	for sheet: String in ["views", "braced", "aim", "shot", "poses", "teams", "z40", "silhouette"]:
		if only != "" and only != sheet:
			continue
		match sheet:
			"views": await _views()
			"braced": await _braced()
			"aim": await _aim()
			"shot": await _shot()
			"poses": await _poses()
			"teams": await _teams()
			"z40": await _z40()
			"silhouette": await _silhouette()
		await _wait(0.3)
	print("RIFLEMAN SHOTS DONE")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m: Node3D in _row:
		m.get_parent().visible = not on


## 2 x 3: game camera close (3/4 front), side, 3/4 back, front, the rifle / scope detail, a 25 m crop.
func _views() -> void:
	var a: Node3D = _row[0]
	var imgs: Array[Image] = []
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(3.8, Vector3(0.1, 1.0, 0.5))
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(3.6, Vector3(0.5, 1.0, 0.0), 6.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 215.0)
	_set_zoom(4.6, Vector3(0.0, 1.0, 0.0), 28.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 0.0)
	_set_zoom(4.4, Vector3(0.0, 1.1, 0.0), 8.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 60.0)
	_set_zoom(1.9, Vector3(0.55, 1.05, 0.55), 18.0, 55.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(25.0, Vector3.ZERO)
	await _wait(0.3)
	imgs.append(_crop(_grab(), 25.0))
	_sheet(imgs, 3, PREFIX + "views")


## The 1.0 s kneel (3/4 front): 0, 0.25, 0.5, 0.75, 1.0 s, then braced from the side, braced 3/4 back, standing up
## (0.2 s after set_braced(false)), braced at the game camera.
func _braced() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 40.0)
	_set_zoom(3.9, Vector3(0.1, 0.8, 0.5), 22.0, 12.0)
	await _wait(0.3)
	var imgs: Array[Image] = [_grab()]
	a.call(&"set_braced", true)
	for t: float in [0.25, 0.5, 0.75, 1.0]:
		await _until_call(a, &"brace_amount", t)
		imgs.append(_grab())
	await _wait(0.2)
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(4.2, Vector3(0.3, 0.7, 0.0), 4.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 200.0)
	_set_zoom(4.6, Vector3(0.0, 0.7, 0.0), 26.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(8.0, Vector3(0.0, 0.5, 0.3))
	await _wait(0.3)
	imgs.append(_grab())
	a.call(&"set_braced", false)
	_set_zoom(3.9, Vector3(0.1, 0.8, 0.5), 22.0, 12.0)
	_place(a, Vector3.ZERO, 40.0)
	await _wait(0.2)
	imgs.append(_grab())
	await _wait(0.6)
	_sheet(imgs, 3, PREFIX + "braced")


## Rime Lock aim (play_aim 1.2 s) braced: 0.1, 0.6, 1.1 s at the game camera close, a scope close-up at 1.1 s, a side
## view; then a standing aim.
func _aim() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 35.0)
	a.call(&"set_braced", true)
	await _wait(1.3)
	_set_zoom(4.6, Vector3(0.0, 0.7, 0.4), 30.0, 10.0)
	var imgs: Array[Image] = []
	a.call(&"play_aim", 1.2)
	for t: float in [0.1, 0.6, 1.1]:
		await _wait(t - (0.0 if imgs.is_empty() else [0.1, 0.6, 1.1][imgs.size() - 1]))
		imgs.append(_grab())
	a.call(&"play_aim", 1.2)
	await _wait(1.0)
	_set_zoom(1.6, Vector3(0.35, 0.85, 0.75), 14.0, 60.0)
	await _wait(0.1)
	imgs.append(_grab())
	a.call(&"play_aim", 1.2)
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(4.0, Vector3(0.3, 0.7, 0.0), 4.0)
	await _wait(1.0)
	imgs.append(_grab())
	a.call(&"set_braced", false)
	await _wait(0.6)
	_place(a, Vector3.ZERO, 35.0)
	_set_zoom(5.0, Vector3(0.0, 1.0, 0.4), 26.0, 10.0)
	a.call(&"play_aim", 1.2)
	await _wait(0.9)
	imgs.append(_grab())
	await _wait(0.8)
	_sheet(imgs, 3, PREFIX + "aim")


## rifle_shot standing (side-ish 3/4): 0.05, 0.10 (the crack), 0.14, 0.30, 0.60; then a braced shot at the crack.
func _shot() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 70.0)
	_set_zoom(4.8, Vector3(0.2, 1.0, 0.3), 12.0, 22.0)
	await _wait(0.4)
	var imgs: Array[Image] = []
	a.call(&"play_attack")
	for t: float in [0.05, 0.10, 0.14, 0.30, 0.60]:
		await _until(a, &"_action_t", t)
		imgs.append(_grab())
	await _wait(0.5)
	a.call(&"set_braced", true)
	await _wait(1.3)
	a.call(&"play_attack")
	await _until(a, &"_action_t", 0.12)
	imgs.append(_grab())
	await _wait(0.6)
	a.call(&"set_braced", false)
	await _wait(0.6)
	_sheet(imgs, 3, PREFIX + "shot")


## Walk (2 frames), hit, fidget peak, level-up, death 0.3 / 0.55 (the shatter), revive.
func _poses() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 45.0)
	_set_zoom(5.2, Vector3(0.0, 0.9, 0.4), 24.0, 12.0)
	var imgs: Array[Image] = []
	a.call(&"set_moving", WALK_V)
	await _wait(0.8)
	imgs.append(_grab())
	await _wait(0.15)
	imgs.append(_grab())
	a.call(&"set_moving", 0.0)
	await _wait(0.6)
	a.call(&"play_hit")
	await _wait(0.05)
	imgs.append(_grab())
	await _wait(0.5)
	a.call(&"play_fidget")
	await _until(a, &"_action_t", 0.8)
	imgs.append(_grab())
	await _wait(1.2)
	a.call(&"play_level_up")
	await _wait(0.12)
	imgs.append(_grab())
	await _wait(0.6)
	a.call(&"play_death")
	await _until(a, &"_death_t", 0.3)
	imgs.append(_grab())
	await _until(a, &"_death_t", 0.56)
	imgs.append(_grab())
	await _wait(1.0)
	a.call(&"revive")
	await _wait(0.4)
	imgs.append(_grab())
	for i: int in imgs.size():
		imgs[i] = imgs[i].get_region(Rect2i(300, 40, 1000, 780))
	_sheet(imgs, 4, PREFIX + "poses")


## The 4 kingdom colours (the team hood / coat / sleeves), standing and braced, then the same at 40 m.
func _teams() -> void:
	_hide_row(true)
	var ms: Array = []
	for i: int in 4:
		ms.append(_spawn(Vector3(-4.5 + 3.0 * float(i), 0, 0), 25.0, TEAMS[i]))
	ms[1].call(&"set_braced", true)
	ms[3].call(&"set_braced", true)
	await _wait(1.2)
	var imgs: Array[Image] = []
	_set_zoom(10.0, Vector3(0.0, 0.8, 0.0), 40.0)
	await _wait(0.3)
	imgs.append(_grab())
	_set_zoom(40.0, Vector3.ZERO)
	await _wait(0.3)
	imgs.append(_crop(_grab(), 40.0, 2.2))
	for m: Node3D in ms:
		m.get_parent().queue_free()
	_hide_row(false)
	_sheet(imgs, 2, PREFIX + "teams")


## The in-game read at 40 m: Riflemen standing, braced, walking and aiming next to Shardcasters (and a Rimeshield and
## a Rime Seer), all in Ice colour.
func _z40() -> void:
	_hide_row(true)
	var ms: Array = []
	var riflemen: Array = []
	var specs: Array = [[Vector3(-5.2, 0, 0.3), 20.0, SCENE], [Vector3(-3.0, 0, -0.5), 150.0, SCENE],
		[Vector3(-0.8, 0, 0.6), 60.0, SCENE], [Vector3(1.4, 0, -0.3), -25.0, SCENE],
		[Vector3(3.8, 0, 0.4), 20.0, SHARD], [Vector3(5.8, 0, -0.4), 150.0, SHARD], [Vector3(7.8, 0, 0.5), 60.0, SHARD]]
	for sp: Array in specs:
		var m := _spawn(sp[0], sp[1], ICE, sp[2])
		ms.append(m)
		if sp[2] == SCENE:
			riflemen.append(m)
	var x := 9.8
	for p: String in OTHERS:
		if ResourceLoader.exists(p):
			ms.append(_spawn(Vector3(x, 0, 0), 20.0, ICE, p))
			x += 2.2
	riflemen[2].call(&"set_braced", true)
	riflemen[3].call(&"set_braced", true)
	riflemen[1].call(&"set_moving", WALK_V)
	ms[5].call(&"set_moving", 4.4)
	await _wait(1.3)
	riflemen[3].call(&"play_aim", 1.2)
	_set_zoom(40.0, Vector3(2.0, 0.0, 0.0))
	await _wait(0.9)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.6).save_png(OUT + PREFIX + "z40.png")
	_set_zoom(25.0, Vector3(2.0, 0.0, 0.0))
	await _wait(0.3)
	_crop(_grab(), 25.0, 2.2).save_png(OUT + PREFIX + "z25.png")
	for m: Node3D in ms:
		m.get_parent().queue_free()
	_hide_row(false)


## Unshaded black units on a white ground (the 40 m black test). Returns what to restore.
func _blacken(units: Array) -> Array:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var old := [_ground.material_override, _env.environment]
	_ground.material_override = white
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	return old


func _unblacken(old: Array) -> void:
	_ground.material_override = old[0]
	_env.environment = old[1]


## Black on white at 25 m and 40 m: Rifleman side, 3/4, braced side, braced 3/4, walking; then 2 Shardcasters.
func _silhouette() -> void:
	_hide_row(true)
	var units: Array = []
	var specs: Array = [[90.0, SCENE, false], [30.0, SCENE, false], [90.0, SCENE, true], [30.0, SCENE, true],
		[60.0, SCENE, false], [90.0, SHARD, false], [30.0, SHARD, false]]
	for i: int in specs.size():
		var m := _spawn(Vector3(-9.0 + 3.0 * float(i), 0, 0), specs[i][0], ICE, specs[i][1])
		if specs[i][2]:
			m.call(&"set_braced", true)
		units.append(m)
	units[4].call(&"set_moving", WALK_V)
	await _wait(1.3)
	var old := _blacken(units)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 30.0 / (1.66 * z))
		var h: int = int(float(w) * 0.30)
		var c := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(470 - h / 2, 0, 900 - h), mini(w, 1600), mini(h, 900)))
		c.resize(1600, 480, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1600, 480 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1600, 480), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1600, 480), Vector2i(0, 488))
	out.save_png(OUT + PREFIX + "silhouette.png")
	_unblacken(old)
	for m: Node3D in units:
		m.get_parent().queue_free()
	_hide_row(false)


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw_deg)


## Crop a window of the same world size at every zoom (~9 x 5 m x widen), nearest upscale to 800 x 450.
func _crop(img: Image, z: float, widen: float = 1.0) -> Image:
	var w: int = clampi(int(1600.0 * 13.0 / z * 0.55 * widen), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - h / 2 - int(h * 0.1), 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	if imgs[0].get_width() == 1000:
		w = 500
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


func _until_call(m: Object, method: StringName, t: float) -> void:
	var guard := 0
	while float(m.call(method)) < t - 0.001 and guard < 240:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
