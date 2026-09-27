extends Node3D
## Glade Outrider preview (task 13b.V3). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/nature/glade_outrider/tools/glade_outrider_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13b_v3_*.png (riding, walk, gallop, shot, shoot_gallop, z40, silhouette) then quits.
## Without --shots: 1-5 zoom · W walk · G gallop · A shoot · arrows aim front / left / right / behind · D death ·
## R revive · Y turn 45.

const SCENE := "res://art/units/nature/glade_outrider/glade_outrider.tscn"
const LINEUP: Array[String] = ["res://art/units/nature/sprigling.tscn", "res://art/units/nature/burr_slinger.tscn",
	"res://art/units/nature/bramblehorn.tscn", "res://art/units/mounts/grove_stag/grove_stag.tscn",
	"res://art/units/nature/mossback/mossback.tscn"]
const OUT := "res://docs/art/screens/"
const PREFIX := "13b_v3_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
## Aim directions in the unit's frame (+Z forward, +X right).
const DIRS: Array[Vector3] = [Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)]
const DIR_NAMES: Array[String] = ["front", "left", "right", "behind"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _holder: Node3D
var _model: Node3D
var _target: Node3D
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
	_model = (load(SCENE) as PackedScene).instantiate()
	_model.get_node(^"Stag").set(&"fidget_every", 0.0)
	_holder.add_child(_model)
	_target = Node3D.new()
	add_child(_target)
	_aim_dir(0)
	_set_zoom(9.0, Vector3(0, 1.4, 0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	elif "--debug" in OS.get_cmdline_user_args():
		_debug_shots()


## Close-up check sheet (not part of the deliverables): the rider at rest and frozen at full draw toward each
## direction, from 3 angles (docs/art/screens/13b_v3_debug.png).
func _debug_shots() -> void:
	await _wait(1.0)
	_holder.rotation.y = 0.0
	var r: Node = _model.call(&"rider_model")
	var imgs: Array[Image] = []
	var views: Array[Vector3] = [Vector3(0.3, 4.4, 1.3), Vector3(2.8, 2.4, -0.4), Vector3(-3.0, 2.7, 0.3)]
	for i: int in 5:
		if i > 0:
			_aim_dir(i - 1)
			_model.call(&"play_attack")
			await _until_attack(0.11)
			r.process_mode = Node.PROCESS_MODE_DISABLED
		for v: Vector3 in views:
			_look(v, Vector3(0, 2.1, -0.1))
			await get_tree().process_frame
			await get_tree().process_frame
			imgs.append(_grab())
		r.process_mode = Node.PROCESS_MODE_INHERIT
		await _wait(0.8)
	_sheet(imgs, 3, PREFIX + "debug", 560, 400)
	print("13B_V3 DEBUG DONE")
	get_tree().quit()


func _look(from_local: Vector3, at_local: Vector3) -> void:
	var f := _holder.global_transform * from_local
	var a := _holder.global_transform * at_local
	_cam.look_at_from_position(f, a)


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


## Puts the target 12 m away in direction i of the unit's frame and aims at it.
func _aim_dir(i: int) -> void:
	_target.global_position = _holder.global_transform * (DIRS[i] * 12.0)
	_model.call(&"set_aim_target", _target)


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
		KEY_G: _move(0.0 if _moving == 7.6 else 7.6)
		KEY_A: _model.call(&"play_attack")
		KEY_UP: _aim_dir(0)
		KEY_LEFT: _aim_dir(1)
		KEY_RIGHT: _aim_dir(2)
		KEY_DOWN: _aim_dir(3)
		KEY_D: _model.call(&"play_death")
		KEY_R: _model.call(&"revive")
		KEY_Y: _holder.rotation.y += deg_to_rad(45.0)


func _move(v: float) -> void:
	_moving = v
	_model.call(&"set_moving", v)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _riding_sheet()
	await _cycle_sheet(1.7, 0.95, PREFIX + "walk")
	await _cycle_sheet(7.6, 0.5, PREFIX + "gallop")
	await _shot_sheet()
	await _shoot_gallop_sheet()
	await _z40()
	await _silhouettes()
	print("13B_V3 SHOTS DONE")
	get_tree().quit()


## Riding idle: 3/4 front close-up, the side, 3/4 back, a top-down game view.
func _riding_sheet() -> void:
	var imgs: Array[Image] = []
	for view: Array in [[30.0, 16.0, 4.6], [90.0, 6.0, 5.0], [215.0, 24.0, 4.6], [0.0, 55.0, 7.0]]:
		_holder.rotation.y = deg_to_rad(view[0])
		_set_zoom(view[2], Vector3(0.0, 1.7, 0.0), view[1], 0.0)
		await _wait(0.4)
		imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "riding", 800, 450)


## 5 frames of one gait cycle from the side (speed, cycle seconds), from the left hind footfall.
func _cycle_sheet(speed: float, cycle: float, nm: String) -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_set_zoom(5.4, Vector3(0.0, 1.6, 0.0), 6.0)
	_move(speed)
	await _wait(1.2)
	await _until_phase(0.0)
	for k: int in 5:
		imgs.append(_grab())
		await _wait(cycle / 5.0)
	_move(0.0)
	await _wait(0.8)
	_sheet(imgs, 5, nm, 560, 360)


## One shot standing, close 3/4 view from the front-right: rest, drawing, full draw, loose, reload (quiver), nocked.
func _shot_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = 0.0
	_aim_dir(1)
	_look(Vector3(-3.0, 2.7, 0.3), Vector3(0.0, 2.05, -0.1))
	await _wait(2.5)
	imgs.append(_grab())
	_model.call(&"play_attack")
	for t: float in [0.06, 0.12, 0.2, 0.3, 0.6]:
		await _until_attack(t)
		imgs.append(_grab())
	await _wait(2.5)
	_sheet(imgs, 3, PREFIX + "shot", 640, 400)


## Shooting at the gallop in 4 directions (rows front / left / right / behind): full draw, the loose, the hold; seen
## from the game camera angle (3/4 above), the unit galloping to the camera's right.
func _shoot_gallop_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_move(7.6)
	for i: int in 4:
		_aim_dir(i)
		_set_zoom(4.4, Vector3(0.0, 1.95, 0.0), 40.0, 0.0)
		_model.call(&"play_attack")
		await _wait(0.6)
		_model.call(&"play_attack")
		await _wait(1.0)
		_model.call(&"play_attack")
		for t: float in [0.11, 0.16, 0.7]:
			await _until_attack(t)
			imgs.append(_grab())
		await _wait(0.4)
	_move(0.0)
	_sheet(imgs, 3, PREFIX + "shoot_gallop", 560, 360)
	_aim_dir(0)
	await _wait(2.4)


## The in-game read at 40 m: the Outrider standing, a second galloping, a third galloping and shooting behind, next to
## the Nature line-up (Sprigling, Burr Slinger, Bramblehorn, a riderless Grove Stag, the Mossback).
func _z40() -> void:
	_holder.rotation.y = deg_to_rad(30.0)
	_holder.position = ORIGIN + Vector3(-5.0, 0, 0)
	var extra: Array[Node3D] = []
	var gal := _spawn_extra(SCENE, Vector3(-1.0, 0, 0), 60.0)
	gal.call(&"set_moving", 7.6)
	var sh := _spawn_extra(SCENE, Vector3(3.0, 0, 0), 90.0)
	sh.call(&"set_moving", 7.6)
	var tg := Node3D.new()
	add_child(tg)
	tg.global_position = sh.get_parent().global_transform * Vector3(0, 0, -12)
	sh.call(&"set_aim_target", tg)
	extra.append(gal)
	extra.append(sh)
	for i: int in LINEUP.size():
		if ResourceLoader.exists(LINEUP[i]):
			extra.append(_spawn_extra(LINEUP[i], Vector3(-6.5 + 3.2 * float(i), 0, 4.0), 20.0))
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.5))
	await _wait(1.0)
	sh.call(&"play_attack")
	await _wait(0.1)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.2).save_png(OUT + PREFIX + "z40.png")
	for e: Node3D in extra:
		e.get_parent().queue_free()
	tg.queue_free()
	_holder.position = ORIGIN


func _spawn_extra(path: String, at: Vector3, yaw: float) -> Node3D:
	var h := Node3D.new()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw)
	add_child(h)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
	h.add_child(m)
	return m


## Unlit black on white: side (standing), galloping 3/4, galloping + shooting behind; 25 m and 40 m.
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
	_holder.position = ORIGIN + Vector3(-4.6, 0, 0)
	_holder.rotation.y = deg_to_rad(90.0)
	var b := _spawn_extra(SCENE, Vector3(0, 0, 0), 30.0)
	b.call(&"set_moving", 7.6)
	var c := _spawn_extra(SCENE, Vector3(4.6, 0, 0), 90.0)
	c.call(&"set_moving", 7.6)
	var tg := Node3D.new()
	add_child(tg)
	tg.global_position = c.get_parent().global_transform * Vector3(-3, 0, -12)
	c.call(&"set_aim_target", tg)
	c.call(&"play_attack")
	await _wait(0.6)
	c.call(&"play_attack")
	await _wait(0.08)
	for n: Node in [_holder, b.get_parent(), c.get_parent()]:
		for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.3)
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


## Waits until the rider's current shot reaches t (s).
func _until_attack(t: float) -> void:
	var r: Node = _model.call(&"rider_model")
	var guard := 0
	while guard < 120:
		var at: float = float(r.get(&"_action_t"))
		if r.get(&"_action") != &"attack" or at >= t:
			return
		await get_tree().process_frame
		guard += 1


## Waits until the stag's gait phase wraps past `p` (0-1).
func _until_phase(p: float) -> void:
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
