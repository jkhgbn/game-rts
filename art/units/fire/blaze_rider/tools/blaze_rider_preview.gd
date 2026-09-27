extends Node3D
## Blaze Rider preview (task 13.V10). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/fire/blaze_rider/tools/blaze_rider_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v10_*.png (after, compare, gallop, charge, attack, teams, z40, silhouette) then quits.
## `-- --before` renders the scene as it is now into 13_v10_before.png (+ 13_v10_before_z40.png); run it once on the
## old scene before replacing it (the compare sheet reads it back).
## Without flags: 1-5 zoom Â· W walk Â· G gallop Â· C charge Â· A attack Â· D death Â· R revive Â· B barding Â· Y turn 45.

const SCENE := "res://art/units/fire/blaze_rider.tscn"
const LINEUP: Array[String] = ["res://art/units/fire/cinder_hand.tscn", "res://art/units/fire/flame_guard.tscn",
	"res://art/units/fire/ember_archer.tscn", "res://art/units/fire/ash_hurler.tscn",
	"res://art/units/fire/cinderlock/cinderlock.tscn", "res://art/units/wizards/vessa.tscn",
	"res://art/units/mounts/ember_boar/ember_boar.tscn"]
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v10_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const GALLOP := 7.5

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _holder: Node3D
var _model: Node3D
var _moving: float = 0.0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_holder = Node3D.new()
	_holder.position = ORIGIN
	_holder.rotation.y = deg_to_rad(30.0)
	add_child(_holder)
	_model = _instance(SCENE)
	_holder.add_child(_model)
	_set_zoom(9.0, Vector3(0, 1.4, 0))
	var args := OS.get_cmdline_user_args()
	if "--before" in args:
		_take_before()
	elif "--shots" in args:
		_take_shots()
	elif "--debug" in args:
		_debug_shots()


## Close-up check sheet (not a deliverable): the rider from 3 sides at rest, then frozen mid-charge and at the attack
## strike (docs/art/screens/13_v10_debug.png).
func _debug_shots() -> void:
	await _wait(1.0)
	_holder.rotation.y = 0.0
	var r: Node = _model.call(&"rider_model")
	var b: Node = _model.call(&"mount_model")
	var imgs: Array[Image] = []
	var views: Array[Vector3] = [Vector3(1.6, 2.6, 2.6), Vector3(3.2, 2.2, -0.2), Vector3(-1.4, 2.8, -2.8)]
	for i: int in 3:
		if i == 1:
			_model.call(&"play_charge")
			await _wait(0.2)
		elif i == 2:
			_model.call(&"play_attack")
			await _wait(0.12)
		if i > 0:
			r.process_mode = Node.PROCESS_MODE_DISABLED
			b.process_mode = Node.PROCESS_MODE_DISABLED
		for v: Vector3 in views:
			_cam.look_at_from_position(_holder.global_transform * v, _holder.global_transform * Vector3(0, 1.8, 0.1))
			await get_tree().process_frame
			await get_tree().process_frame
			imgs.append(_grab())
		r.process_mode = Node.PROCESS_MODE_INHERIT
		b.process_mode = Node.PROCESS_MODE_INHERIT
		await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "debug", 560, 400)
	print("13_V10 DEBUG DONE")
	get_tree().quit()


func _instance(path: String) -> Node3D:
	var m: Node3D = (load(path) as PackedScene).instantiate()
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
	var boar := m.get_node_or_null(^"Boar")
	if boar:
		boar.set(&"fidget_every", 0.0)
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
		KEY_1: _set_zoom(5.0, Vector3(0, 1.9, 0))
		KEY_2: _set_zoom(9.0, Vector3(0, 1.4, 0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W: _move(0.0 if _moving == 1.7 else 1.7)
		KEY_G: _move(0.0 if _moving == GALLOP else GALLOP)
		KEY_A: _model.call(&"play_attack")
		KEY_C:
			if _model.has_method(&"play_charge"):
				_model.call(&"play_charge")
		KEY_D: _model.call(&"play_death")
		KEY_R: _model.call(&"revive")
		KEY_B:
			if _model.has_method(&"set_barded"):
				_model.call(&"set_barded", not bool(_model.call(&"is_barded")))
		KEY_Y: _holder.rotation.y += deg_to_rad(45.0)


func _move(v: float) -> void:
	_moving = v
	_model.call(&"set_moving", v)


# ---------------------------------------------------------------- screenshots

func _take_before() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _views_sheet(PREFIX + "before")
	await _z40(PREFIX + "before_z40", false)
	print("13_V10 BEFORE DONE")
	get_tree().quit()


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _views_sheet(PREFIX + "after")
	_compare()
	await _cycle_sheet()
	await _charge_sheet()
	await _attack_sheet()
	await _teams()
	await _z40(PREFIX + "z40", true)
	await _silhouettes()
	print("13_V10 SHOTS DONE")
	get_tree().quit()


func _views() -> Array:
	# [yaw of the unit, camera pitch, distance, focus height]
	return [[30.0, 16.0, 5.6, 1.6], [90.0, 6.0, 6.0, 1.6], [215.0, 24.0, 5.6, 1.6], [0.0, 55.0, 8.5, 1.2]]


## Riding idle: 3/4 front, side, 3/4 back, the game camera.
func _views_sheet(nm: String) -> void:
	var imgs: Array[Image] = []
	for v: Array in _views():
		_holder.rotation.y = deg_to_rad(v[0])
		_set_zoom(v[2], Vector3(0.0, v[3], 0.0), v[1], 0.0)
		await _wait(0.5)
		imgs.append(_grab())
	_sheet(imgs, 2, nm, 800, 450)


## Old (top, 13_v10_before.png) against new (bottom): the 3/4 front and the side views.
func _compare() -> void:
	var before := Image.load_from_file(ProjectSettings.globalize_path(OUT + PREFIX + "before.png"))
	var after := Image.load_from_file(ProjectSettings.globalize_path(OUT + PREFIX + "after.png"))
	if before == null or after == null:
		return
	var out := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	before.convert(Image.FORMAT_RGBA8)
	after.convert(Image.FORMAT_RGBA8)
	out.blit_rect(before, Rect2i(0, 0, 1600, 450), Vector2i(0, 0))
	out.blit_rect(after, Rect2i(0, 0, 1600, 450), Vector2i(0, 450))
	out.save_png(OUT + PREFIX + "compare.png")


## Walk (top) and gallop (bottom): 5 frames of one cycle each, from the side.
func _cycle_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	for sp: Array in [[1.7, 1.2], [GALLOP, 0.5]]:
		_set_zoom(6.2, Vector3(0.0, 1.7, 0.0), 6.0)
		_move(sp[0])
		await _wait(1.2)
		await _until_phase(0.0)
		for k: int in 5:
			imgs.append(_grab())
			await _wait(float(sp[1]) / 5.0)
	_move(0.0)
	await _wait(0.8)
	_sheet(imgs, 5, PREFIX + "gallop", 560, 380)


## The charge at the gallop (play_charge): before, couch (0.05), impact (0.10), gore (0.25), hold (0.45), recovery
## (0.8); top row from the side, bottom row from the game camera angle.
func _charge_sheet() -> void:
	var imgs: Array[Image] = []
	for row: int in 2:
		_holder.rotation.y = deg_to_rad(90.0 if row == 0 else 60.0)
		if row == 0:
			_set_zoom(6.4, Vector3(0.0, 1.7, 0.0), 8.0)
		else:
			_set_zoom(7.0, Vector3(0.0, 1.4, 0.0), 45.0)
		_move(GALLOP)
		await _wait(1.0)
		imgs.append(_grab())
		_model.call(&"play_charge")
		var f0 := Engine.get_process_frames()
		for t: float in [0.05, 0.10, 0.25, 0.45, 0.8]:
			while float(Engine.get_process_frames() - f0) / 60.0 < t:
				await get_tree().process_frame
			imgs.append(_grab())
		await _wait(0.6)
	_move(0.0)
	await _wait(0.6)
	_sheet(imgs, 6, PREFIX + "charge", 480, 330)


## The melee attack (lance_charge, strike 0.12 s) standing and at the gallop: rest, couch, strike, follow-through.
func _attack_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(70.0)
	for moving: float in [0.0, GALLOP]:
		_set_zoom(6.0, Vector3(0.0, 1.6, 0.0), 12.0)
		_move(moving)
		await _wait(1.2)
		imgs.append(_grab())
		_model.call(&"play_attack")
		var f0 := Engine.get_process_frames()
		for t: float in [0.07, 0.13, 0.3]:
			while float(Engine.get_process_frames() - f0) / 60.0 < t:
				await get_tree().process_frame
			imgs.append(_grab())
		await _wait(0.8)
	_move(0.0)
	await _wait(0.5)
	_sheet(imgs, 4, PREFIX + "attack", 560, 360)


## Team colours: the Fire kingdom colour, Shadow violet, Ice blue; the right one barded.
func _teams() -> void:
	_holder.rotation.y = deg_to_rad(40.0)
	_holder.position = ORIGIN + Vector3(-3.4, 0, 0)
	var b := _spawn_extra(SCENE, Vector3(0, 0, 0), 40.0)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	var c := _spawn_extra(SCENE, Vector3(3.4, 0, 0), 40.0)
	c.call(&"set_team_color", Color(0.45, 0.75, 0.95))
	if c.has_method(&"set_barded"):
		c.call(&"set_barded", true)
	_set_zoom(9.5, Vector3(0.0, 1.3, 0.0), 30.0)
	await _wait(0.8)
	_grab().save_png(OUT + PREFIX + "teams.png")
	b.get_parent().queue_free()
	c.get_parent().queue_free()
	_holder.position = ORIGIN


## The in-game read at 40 m: this rider standing, one galloping, one charging, next to the Fire line-up (Cinder Hand,
## Flame Guard, Ember Archer, Ash Hurler, Cinderlock, Vessa, a riderless Ember Boar).
func _z40(nm: String, extras: bool) -> void:
	_holder.rotation.y = deg_to_rad(30.0)
	_holder.position = ORIGIN + Vector3(-5.0, 0, 0)
	var extra: Array[Node3D] = []
	if extras:
		var gal := _spawn_extra(SCENE, Vector3(-1.0, 0, 0), 60.0)
		gal.call(&"set_moving", GALLOP)
		var ch := _spawn_extra(SCENE, Vector3(3.2, 0, 0), 90.0)
		ch.call(&"set_moving", GALLOP)
		extra.append(gal)
		extra.append(ch)
	for i: int in LINEUP.size():
		if ResourceLoader.exists(LINEUP[i]):
			extra.append(_spawn_extra(LINEUP[i], Vector3(-7.5 + 2.6 * float(i), 0, 4.0), 20.0))
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.5))
	await _wait(1.0)
	if extras:
		extra[1].call(&"play_charge")
		await _wait(0.12)
	var img := _grab()
	img.save_png(OUT + nm + "_full.png")
	_crop(img, 40.0, 2.4).save_png(OUT + nm + ".png")
	for e: Node3D in extra:
		e.get_parent().queue_free()
	_holder.position = ORIGIN


func _spawn_extra(path: String, at: Vector3, yaw: float) -> Node3D:
	var h := Node3D.new()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw)
	add_child(h)
	var m := _instance(path)
	h.add_child(m)
	return m


## Unlit black on white: standing (side), galloping 3/4, charging; 25 m and 40 m.
func _silhouettes() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	_holder.position = ORIGIN + Vector3(-4.8, 0, 0)
	_holder.rotation.y = deg_to_rad(90.0)
	var b := _spawn_extra(SCENE, Vector3(0, 0, 0), 30.0)
	b.call(&"set_moving", GALLOP)
	var c := _spawn_extra(SCENE, Vector3(4.8, 0, 0), 90.0)
	c.call(&"set_moving", GALLOP)
	await _wait(0.8)
	c.call(&"play_charge")
	await _wait(0.2)
	for n: Node in [_holder, b.get_parent(), c.get_parent()]:
		for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await get_tree().process_frame
		await get_tree().process_frame
		var img := _grab()
		var w: int = int(1600.0 * 22.0 / (1.66 * z))
		var hh: int = int(float(w) * 0.34)
		var cr := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - hh / 2, 0, 900 - hh), mini(w, 1600),
			mini(hh, 900)))
		cr.resize(1600, 544, Image.INTERPOLATE_NEAREST)
		imgs.append(cr)
	var out := Image.create(1600, 544 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1600, 544), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1600, 544), Vector2i(0, 552))
	out.save_png(OUT + PREFIX + "silhouette.png")


func _crop(img: Image, z: float, widen: float = 1.0) -> Image:
	var w: int = clampi(int(1600.0 * 13.0 / z * 0.55 * widen), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - h / 2 - int(h * 0.1), 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String, w: int, h: int) -> void:
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		var ar: float = float(w) / float(h)
		var cw: int = mini(im.get_width(), int(float(im.get_height()) * ar))
		var chh: int = int(float(cw) / ar)
		im = im.get_region(Rect2i((im.get_width() - cw) / 2, (im.get_height() - chh) / 2, cw, chh))
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


## Waits until the mount's gait phase wraps past `p` (0-1); returns at once for models without a gait.
func _until_phase(p: float) -> void:
	if not _model.has_method(&"gait_phase"):
		return
	var guard := 0
	var last: float = float(_model.call(&"gait_phase"))
	while guard < 240:
		await get_tree().process_frame
		guard += 1
		var now: float = float(_model.call(&"gait_phase"))
		if (last < p and now >= p) or (now < last and (p <= now or p > last)):
			return
		last = now


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
