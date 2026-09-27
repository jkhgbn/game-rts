extends Node3D
## Gloam Rider preview (task 13.V7). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/shadow/gloam_rider/tools/gloam_rider_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v7_*.png (riding, walk, gallop, lance, charge, z40, silhouette) then quits.
## `-- --debug` writes 13_v7_debug.png (close-ups from 3 angles: rest, gallop, strike, charge).
## Without args: 1-5 zoom · W walk · G gallop · A attack · C charge · D death · R revive · B barding · Y turn 45.

const SCENE := "res://art/units/shadow/gloam_rider/gloam_rider.tscn"
const LINEUP: Array[String] = ["res://art/units/shadow/gloom_thrall.tscn", "res://art/units/shadow/shade.tscn",
	"res://art/units/shadow/nightbolt.tscn", "res://art/units/shadow/grave_hound.tscn",
	"res://art/units/shadow/shadow_knight.tscn", "res://art/units/mounts/dusk_steed/dusk_steed.tscn"]
const KNIGHT := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v7_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const GALLOP := 7.2

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
	_model = (load(SCENE) as PackedScene).instantiate()
	_model.get_node(^"Steed").set(&"fidget_every", 0.0)
	_holder.add_child(_model)
	_set_zoom(9.0, Vector3(0, 1.8, 0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	elif "--debug" in OS.get_cmdline_user_args():
		_debug_shots()


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
	var f := _holder.global_transform * from_local
	var a := _holder.global_transform * at_local
	_cam.look_at_from_position(f, a)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(6.0, Vector3(0, 2.2, 0))
		KEY_2: _set_zoom(9.0, Vector3(0, 1.8, 0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W: _move(0.0 if _moving == 1.8 else 1.8)
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

## Close-up check sheet: rest, galloping, the strike frame, the charge strike; from the front-right, the right side
## and the left side.
func _debug_shots() -> void:
	await _wait(1.0)
	_holder.rotation.y = 0.0
	var imgs: Array[Image] = []
	var views: Array[Vector3] = [Vector3(2.6, 3.0, 3.2), Vector3(4.2, 2.4, 0.2), Vector3(-4.2, 2.6, 0.6)]
	var r: Node = _model.call(&"rider_model")
	var s: Node = _model.call(&"mount_model")
	for i: int in 4:
		match i:
			1:
				_move(GALLOP)
				await _wait(1.2)
			2:
				_move(0.0)
				await _wait(1.0)
				_model.call(&"play_attack")
				await _until_attack(0.125)
			3:
				_move(GALLOP)
				await _wait(1.0)
				_model.call(&"play_charge")
				await _wait(0.12)
		r.process_mode = Node.PROCESS_MODE_DISABLED
		s.process_mode = Node.PROCESS_MODE_DISABLED
		for v: Vector3 in views:
			_look(v, Vector3(0, 1.9, 0.3))
			await get_tree().process_frame
			await get_tree().process_frame
			imgs.append(_grab())
		r.process_mode = Node.PROCESS_MODE_INHERIT
		s.process_mode = Node.PROCESS_MODE_INHERIT
		await _wait(0.9)
	_move(0.0)
	_sheet(imgs, 3, PREFIX + "debug", 560, 400)
	print("13_V7 DEBUG DONE")
	get_tree().quit()


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _riding_sheet()
	await _cycle_sheet(1.8, 0.9, PREFIX + "walk")
	await _cycle_sheet(GALLOP, 0.5, PREFIX + "gallop")
	await _lance_sheet()
	await _charge_sheet()
	await _z40()
	await _silhouettes()
	print("13_V7 SHOTS DONE")
	get_tree().quit()


## Riding idle: 3/4 front close-up, the side, 3/4 back, a top-down game view; then barded.
func _riding_sheet() -> void:
	var imgs: Array[Image] = []
	for view: Array in [[30.0, 14.0, 5.6], [90.0, 6.0, 6.0], [215.0, 22.0, 5.6], [0.0, 55.0, 8.5]]:
		_holder.rotation.y = deg_to_rad(view[0])
		_set_zoom(view[2], Vector3(0.0, 2.0, 0.0), view[1], 0.0)
		await _wait(0.4)
		imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "riding", 800, 450)


## 5 frames of one gait cycle from the side (speed, cycle seconds), from the left hind footfall.
func _cycle_sheet(speed: float, cycle: float, nm: String) -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_set_zoom(6.6, Vector3(0.0, 2.0, 0.0), 6.0)
	_move(speed)
	await _wait(1.2)
	await _until_phase(0.0)
	for k: int in 5:
		imgs.append(_grab())
		await _wait(cycle / 5.0)
	_move(0.0)
	await _wait(0.8)
	_sheet(imgs, 5, nm, 560, 360)


## The lance_charge attack standing (row 1, from the right side) and at the gallop (row 2, 3/4 game angle): couch,
## draw back, the strike frame, hold, recovery.
func _lance_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_set_zoom(6.4, Vector3(0.6, 2.0, 0.0), 8.0)
	await _wait(1.6)
	_model.call(&"play_attack")
	for t: float in [0.04, 0.08, 0.125, 0.25, 0.45]:
		await _until_attack(t)
		imgs.append(_grab())
	await _wait(1.0)
	_move(GALLOP)
	_set_zoom(6.0, Vector3(0.6, 1.9, 0.0), 38.0)
	await _wait(1.4)
	_model.call(&"play_attack")
	for t: float in [0.04, 0.08, 0.125, 0.25, 0.45]:
		await _until_attack(t)
		imgs.append(_grab())
	_move(0.0)
	await _wait(1.0)
	_sheet(imgs, 5, PREFIX + "lance", 520, 360)


## play_charge at the gallop from the side and the game angle: before, strike (0.10), follow-through, recovery.
func _charge_sheet() -> void:
	var imgs: Array[Image] = []
	_holder.rotation.y = deg_to_rad(90.0)
	_move(GALLOP)
	for view: Array in [[8.0, 6.6], [40.0, 6.4]]:
		_set_zoom(view[1], Vector3(0.8, 1.9, 0.0), view[0])
		await _wait(1.2)
		imgs.append(_grab())
		_model.call(&"play_charge")
		for t: float in [0.05, 0.1, 0.3, 0.6]:
			await _until_charge(t)
			imgs.append(_grab())
		await _wait(0.6)
	_move(0.0)
	await _wait(1.0)
	_sheet(imgs, 5, PREFIX + "charge", 520, 360)


## The in-game read at 40 m: the Gloam Rider standing, a second galloping, a third striking, next to the Shadow army
## (Gloom Thrall, Shade, Nightbolt, Grave Hound, Shadow Knight, a riderless Dusk Steed) and the Nightmare Knight.
func _z40() -> void:
	_holder.rotation.y = deg_to_rad(30.0)
	_holder.position = ORIGIN + Vector3(-5.5, 0, -0.5)
	var extra: Array[Node3D] = []
	var gal := _spawn_extra(SCENE, Vector3(-1.5, 0, -0.5), 60.0)
	gal.call(&"set_moving", GALLOP)
	var st := _spawn_extra(SCENE, Vector3(2.5, 0, -0.5), 90.0)
	st.call(&"set_moving", GALLOP)
	extra.append(gal)
	extra.append(st)
	if ResourceLoader.exists(KNIGHT):
		var k := _spawn_extra(KNIGHT, Vector3(7.0, 0, -0.5), 20.0)
		extra.append(k)
	for i: int in LINEUP.size():
		if ResourceLoader.exists(LINEUP[i]):
			extra.append(_spawn_extra(LINEUP[i], Vector3(-7.0 + 3.0 * float(i), 0, 4.0), 20.0))
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.5))
	await _wait(1.2)
	st.call(&"play_charge")
	await _wait(0.1)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.4).save_png(OUT + PREFIX + "z40.png")
	for e: Node3D in extra:
		e.get_parent().queue_free()
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


## Unlit black on white: standing, galloping, charging (all from the side); 25 m and 40 m.
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
	_holder.position = ORIGIN + Vector3(-5.0, 0, 0)
	_holder.rotation.y = deg_to_rad(90.0)
	var b := _spawn_extra(SCENE, Vector3(0, 0, 0), 90.0)
	b.call(&"set_moving", GALLOP)
	var c := _spawn_extra(SCENE, Vector3(5.0, 0, 0), 90.0)
	c.call(&"set_moving", GALLOP)
	await _wait(1.0)
	c.call(&"play_charge")
	await _wait(0.12)
	for n: Node in [_holder, b.get_parent(), c.get_parent()]:
		for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	for n: Node in [_model, b, c]:
		for p: Node in [n.call(&"rider_model"), n.call(&"mount_model")]:
			(p as Node).process_mode = Node.PROCESS_MODE_DISABLED
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
		var at: float = float(r.get(&"_action_t"))
		if r.get(&"_action") != &"attack" or at >= t:
			return
		await get_tree().process_frame
		guard += 1


## Waits until the rider's charge clock reaches t (s).
func _until_charge(t: float) -> void:
	var r: Node = _model.call(&"rider_model")
	var guard := 0
	while guard < 120:
		if float(r.get(&"_chg_t")) >= t:
			return
		await get_tree().process_frame
		guard += 1


## Waits until the steed's gait phase wraps past `p` (0-1).
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
