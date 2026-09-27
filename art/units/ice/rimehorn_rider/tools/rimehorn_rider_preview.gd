extends Node3D
## Rimehorn Rider preview (task 13.V8). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/ice/rimehorn_rider/tools/rimehorn_rider_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v8_*.png (views, walk, gallop, swing, swing_gallop, charge, death, teams, z40, silhouette)
## then quits. `-- --debug` = a close-up check sheet (13_v8_debug.png).
## Without arguments: 1-5 zoom · W walk · G gallop · A swing · C charge · D death · R revive · B barding · Y turn 45.

const SCENE := "res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn"
const LINEUP: Array[String] = ["res://art/units/ice/rime_hauler.tscn", "res://art/units/ice/rimeshield.tscn",
	"res://art/units/ice/shardcaster.tscn", "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn",
	"res://art/units/ice/rime_seer.tscn", "res://art/units/ice/rime_colossus.tscn"]
const MAMMOTH := "res://art/units/titans/war_mammoth/war_mammoth.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v8_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const GALLOP := 6.0

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
	_model = _new_model()
	_holder.add_child(_model)
	_set_zoom(9.0, Vector3(0, 1.4, 0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	elif "--debug" in OS.get_cmdline_user_args():
		_debug_shots()


func _new_model() -> Node3D:
	var mdl: Node3D = (load(SCENE) as PackedScene).instantiate()
	mdl.get_node(^"Rimehorn").set(&"fidget_every", 0.0)
	mdl.get_node(^"Rider").set(&"fidget_every", 0.0)
	return mdl


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


func _look(from_local: Vector3, at_local: Vector3) -> void:
	_cam.look_at_from_position(_holder.global_transform * from_local, _holder.global_transform * at_local)


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
		KEY_C: _model.call(&"play_charge")
		KEY_D: _model.call(&"play_death")
		KEY_R: _model.call(&"revive")
		KEY_B: _model.call(&"set_barded", not bool(_model.call(&"is_barded")))
		KEY_Y: _holder.rotation.y += deg_to_rad(45.0)


func _move(v: float) -> void:
	_moving = v
	_model.call(&"set_moving", v)


# ---------------------------------------------------------------- screenshots

func _debug_shots() -> void:
	await _wait(1.0)
	_holder.rotation.y = 0.0
	var imgs: Array[Image] = []
	var views: Array[Vector3] = [Vector3(0.3, 5.0, 3.6), Vector3(4.0, 2.4, 0.4), Vector3(-4.0, 2.6, 0.6),
		Vector3(0.5, 2.6, -4.2)]
	for v: Vector3 in views:
		_look(v, Vector3(0.0, 1.8, -0.1))
		await _wait(0.2)
		imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "debug", 800, 520)
	# the swing frozen at key times, from the right side and from the front-right above
	var r: Node = _model.call(&"rider_model")
	var sw: Array[Image] = []
	for view: Vector3 in [Vector3(4.6, 2.2, 0.3), Vector3(3.0, 4.2, 3.4)]:
		for t: float in [0.0, 0.06, 0.10, 0.125, 0.15, 0.3]:
			if t > 0.0:
				_model.call(&"play_attack")
				await _until_attack(t)
				r.process_mode = Node.PROCESS_MODE_DISABLED
			_look(view, Vector3(0.0, 1.6, 0.3))
			await get_tree().process_frame
			await get_tree().process_frame
			sw.append(_grab())
			r.process_mode = Node.PROCESS_MODE_INHERIT
			await _wait(1.0)
	_sheet(sw, 6, PREFIX + "debug_swing", 480, 400)
	print("13_V8 DEBUG DONE")
	get_tree().quit()


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _views_sheet()
	await _cycle_sheet(1.7, 0.95, PREFIX + "walk")
	await _cycle_sheet(GALLOP, 0.66, PREFIX + "gallop")
	await _swing_sheet()
	await _swing_gallop_sheet()
	await _charge_sheet()
	await _death_sheet()
	await _teams_sheet()
	await _z40()
	await _silhouettes()
	print("13_V8 SHOTS DONE")
	get_tree().quit()


## Riding idle: 3/4 front close-up, the side, 3/4 back, the left (shield) side, a game-angle view, barded.
func _views_sheet() -> void:
	var imgs: Array[Image] = []
	for view: Array in [[30.0, 16.0, 5.4], [90.0, 6.0, 5.6], [215.0, 22.0, 5.4], [-90.0, 8.0, 5.6], [20.0, 55.0, 8.0]]:
		_holder.rotation.y = deg_to_rad(view[0])
		_set_zoom(view[2], Vector3(0.0, 1.6, 0.0), view[1], 0.0)
		await _wait(0.4)
		imgs.append(_grab())
	_model.call(&"set_barded", true)
	_holder.rotation.y = deg_to_rad(40.0)
	_set_zoom(5.6, Vector3(0.0, 1.6, 0.0), 20.0, 0.0)
	await _wait(0.6)
	imgs.append(_grab())
	_model.call(&"set_barded", false)
	_sheet(imgs, 3, PREFIX + "views", 800, 450)


## 5 frames of one gait cycle from the side (speed, cycle seconds), from the left hind footfall.
func _cycle_sheet(speed: float, cycle: float, nm: String) -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_set_zoom(6.0, Vector3(0.0, 1.5, 0.0), 8.0)
	_move(speed)
	await _wait(1.2)
	await _until_phase(0.0)
	for k: int in 5:
		imgs.append(_grab())
		await _wait(cycle / 5.0)
	_move(0.0)
	await _wait(0.8)
	_sheet(imgs, 5, nm, 560, 380)


## The great swing standing, 3/4 front-right close view: rest, wind-up, strike, follow-through, recovery; then the
## same frames from the game camera.
func _swing_sheet() -> void:
	var imgs: Array[Image] = []
	for view: int in 2:
		_holder.rotation.y = deg_to_rad(-40.0 if view == 0 else 0.0)
		if view == 0:
			_set_zoom(5.6, Vector3(0.0, 1.7, 0.0), 10.0, 0.0)
		else:
			_set_zoom(7.5, Vector3(0.0, 1.2, 0.0), 55.0, 0.0)
		await _wait(1.2)
		imgs.append(_grab())
		_model.call(&"play_attack")
		for t: float in [0.08, 0.13, 0.16, 0.4]:
			await _until_attack(t)
			imgs.append(_grab())
		await _wait(1.0)
	_sheet(imgs, 5, PREFIX + "swing", 560, 380)


## Chopping at the gallop, seen from the game camera angle (3/4 above): 4 frames.
func _swing_gallop_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_move(GALLOP)
	_set_zoom(6.0, Vector3(0.0, 1.6, 0.0), 40.0, 0.0)
	await _wait(1.2)
	_model.call(&"play_attack")
	for t: float in [0.05, 0.10, 0.16, 0.3]:
		await _until_attack(t)
		imgs.append(_grab())
	_move(0.0)
	await _wait(1.2)
	_sheet(imgs, 4, PREFIX + "swing_gallop", 560, 380)


## The charge at the gallop from the side and from 3/4 front: before, the impact (0.10), 0.2, 0.45.
func _charge_sheet() -> void:
	var imgs: Array[Image] = []
	for view: int in 2:
		_holder.rotation.y = deg_to_rad(90.0 if view == 0 else 35.0)
		_set_zoom(6.2, Vector3(0.0, 1.5, 0.0), 8.0 if view == 0 else 18.0, 0.0)
		_move(GALLOP)
		await _wait(1.2)
		imgs.append(_grab())
		_model.call(&"play_charge")
		for t: float in [0.10, 0.2, 0.45]:
			await _wait(t - (0.0 if t == 0.10 else (0.10 if t == 0.2 else 0.2)))
			imgs.append(_grab())
		_move(0.0)
		await _wait(1.2)
	_sheet(imgs, 4, PREFIX + "charge", 560, 380)


## Death at the gallop: 0.25, 0.5, 0.6 (shatter), 0.8, 1.2 s; then revive.
func _death_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(60.0)
	_set_zoom(6.5, Vector3(0.0, 1.0, 0.0), 22.0, 0.0)
	_move(GALLOP)
	await _wait(1.0)
	_model.call(&"play_death")
	var last := 0.0
	for t: float in [0.25, 0.5, 0.62, 0.8, 1.2]:
		await _wait(t - last)
		last = t
		imgs.append(_grab())
	_move(0.0)
	_model.call(&"revive")
	await _wait(0.8)
	_sheet(imgs, 5, PREFIX + "death", 560, 380)


## Team colours: Ice (own), Fire red, Shadow violet, Nature green side by side, game-angle close.
func _teams_sheet() -> void:
	var cols: Array[Color] = [Color(0.45, 0.75, 0.95), Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60),
		Color(0.35, 0.70, 0.25)]
	var extra: Array[Node3D] = []
	_holder.visible = false
	for i: int in 4:
		var e := _spawn_extra(SCENE, Vector3(-4.8 + 3.2 * float(i), 0, 0), 30.0)
		e.call(&"set_team_color", cols[i])
		extra.append(e)
	_set_zoom(11.0, Vector3(0.0, 1.2, 0.0), 40.0, 0.0)
	await _wait(0.6)
	var img := _grab()
	img.save_png(OUT + PREFIX + "teams.png")
	for e: Node3D in extra:
		e.get_parent().queue_free()
	_holder.visible = true


## The in-game read at 40 m: the Rider standing, a second galloping, a third chopping, next to the Ice army and the
## War Mammoth.
func _z40() -> void:
	_holder.rotation.y = deg_to_rad(30.0)
	_holder.position = ORIGIN + Vector3(-4.5, 0, -1.0)
	var extra: Array[Node3D] = []
	var gal := _spawn_extra(SCENE, Vector3(-1.0, 0, -1.0), 70.0)
	gal.call(&"set_moving", GALLOP)
	var ch := _spawn_extra(SCENE, Vector3(2.5, 0, -1.0), -20.0)
	extra.append(gal)
	extra.append(ch)
	for i: int in LINEUP.size():
		if ResourceLoader.exists(LINEUP[i]):
			extra.append(_spawn_extra(LINEUP[i], Vector3(-7.0 + 2.4 * float(i), 0, 3.2), 20.0))
	if ResourceLoader.exists(MAMMOTH):
		extra.append(_spawn_extra(MAMMOTH, Vector3(8.5, 0, -0.5), -30.0))
	_set_zoom(40.0, Vector3(0.5, 0.0, 1.0))
	await _wait(1.0)
	ch.call(&"play_attack")
	await _wait(0.16)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.6).save_png(OUT + PREFIX + "z40.png")
	for e: Node3D in extra:
		e.get_parent().queue_free()
	_holder.position = ORIGIN


func _spawn_extra(path: String, at: Vector3, yaw: float) -> Node3D:
	var h := Node3D.new()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw)
	add_child(h)
	var mdl: Node3D = _new_model() if path == SCENE else (load(path) as PackedScene).instantiate()
	if &"fidget_every" in mdl:
		mdl.set(&"fidget_every", 0.0)
	h.add_child(mdl)
	return mdl


## Unlit black on white: side standing, galloping 3/4, chopping; 25 m and 40 m.
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
	b.call(&"set_moving", GALLOP)
	var c := _spawn_extra(SCENE, Vector3(4.6, 0, 0), 90.0)
	await _wait(0.5)
	c.call(&"play_attack")
	await _wait(0.16)
	for n: Node in [_holder, b.get_parent(), c.get_parent()]:
		for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	for mdl: Node in [_model, b, c]:
		for sub: Node in [mdl.get_node(^"Rimehorn"), mdl.get_node(^"Rider")]:
			sub.process_mode = Node.PROCESS_MODE_DISABLED
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


## Waits until the rider's current attack reaches t (s).
func _until_attack(t: float) -> void:
	var r: Node = _model.call(&"rider_model")
	var guard := 0
	while guard < 120:
		if r.get(&"_action") != &"attack" or float(r.get(&"_action_t")) >= t:
			return
		await get_tree().process_frame
		guard += 1


## Waits until the rhino's gait phase wraps past `p` (0-1).
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
