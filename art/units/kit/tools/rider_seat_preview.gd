extends Node3D
## Seated rider preview (task 13.V1b): a wizard (Torvald), a champion (Oathwall) and a soldier (Rimeshield) seated on
## the Rimehorn with CharacterModel.set_seated. Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . art/units/kit/tools/rider_seat_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v1b_*.png (riding, walk, gallop, mount, thrown, z40, silhouette) then quits.
## Without --shots: 1-5 zoom Â· W walk Â· G gallop Â· M mount (hop-on) Â· N dismount Â· T thrown Â· S seat / unseat at once
## Â· A attack Â· D death (rider + mount) Â· R revive Â· Y turn 45.

const MOUNT := "res://art/units/mounts/rimehorn/rimehorn.tscn"
const RIDERS: Array[String] = ["res://art/units/wizards/torvald.tscn", "res://art/units/champions/oathwall/oathwall.tscn",
	"res://art/units/ice/rimeshield.tscn"]
const NAMES: Array[String] = ["wizard", "champion", "soldier"]
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v1b_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const ICE := Color(0.45, 0.75, 0.95)

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _pairs: Array = []   # [rider, mount] per rider kind, all at the origin (one shown at a time in the sheets)
var _moving: float = 0.0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	for i: int in RIDERS.size():
		_pairs.append(_spawn_pair(Vector3(-4.5 + 4.5 * float(i), 0, 0), 30.0, RIDERS[i]))
	_set_zoom(12.0, Vector3(0, 1.2, 0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn_pair(at: Vector3, yaw_deg: float, rider_path: String, seated: bool = true) -> Array:
	var holder := Node3D.new()      # like Unit._visual: mount and rider share the unit's transform
	holder.position = ORIGIN + at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	var r: Node3D = load(rider_path).instantiate()
	var m: Node3D = load(MOUNT).instantiate()
	m.set(&"fidget_every", 0.0)
	r.call(&"set_team_color", ICE)
	m.call(&"set_team_color", ICE)
	holder.add_child(r)
	holder.add_child(m)
	if seated:
		r.call(&"set_seated", true, m)
	return [r, m]


func _spawn_foot(at: Vector3, yaw_deg: float, path: String) -> Node3D:
	var holder := Node3D.new()
	holder.position = ORIGIN + at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	var r: Node3D = load(path).instantiate()
	r.call(&"set_team_color", ICE)
	holder.add_child(r)
	return r


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
		KEY_1: _set_zoom(7.0, Vector3(0.0, 1.5, 0))
		KEY_2: _set_zoom(12.0, Vector3(0.0, 1.2, 0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W: _move(0.0 if _moving == 1.7 else 1.7)
		KEY_G: _move(0.0 if _moving == 6.0 else 6.0)
		KEY_M:
			for p: Array in _pairs:
				p[0].call(&"set_seated", true, p[1])
				p[0].call(&"play_mount")
		KEY_N: _riders(&"play_dismount")
		KEY_T: _riders(&"play_thrown")
		KEY_S:
			for p: Array in _pairs:
				p[0].call(&"set_seated", not bool(p[0].call(&"is_seated")), p[1])
		KEY_A: _riders(&"play_attack")
		KEY_D:
			for p: Array in _pairs:
				p[1].call(&"play_death")
				p[0].call(&"play_death")
		KEY_R:
			for p: Array in _pairs:
				p[1].call(&"revive")
				p[0].call(&"revive")
		KEY_Y:
			for p: Array in _pairs:
				p[0].get_parent().rotation.y += deg_to_rad(45.0)


func _move(v: float) -> void:
	_moving = v
	for p: Array in _pairs:
		p[1].call(&"set_moving", v)
		p[0].call(&"set_moving", v)


func _riders(method: StringName) -> void:
	for p: Array in _pairs:
		p[0].call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _riding_sheet()
	await _cycle_sheet(1.7, 0.95, PREFIX + "walk")
	await _cycle_sheet(6.0, 0.497, PREFIX + "gallop")
	await _mount_sheet()
	await _thrown_sheet()
	await _z40()
	await _silhouettes()
	print("13_V1B SHOTS DONE")
	get_tree().quit()


## Shows only pair i, placed at the origin with a yaw.
func _solo(i: int, yaw_deg: float) -> Array:
	for j: int in _pairs.size():
		var h: Node3D = _pairs[j][0].get_parent()
		h.visible = j == i
		h.position = ORIGIN if j == i else ORIGIN + Vector3(0, -50, 0)
		if j == i:
			h.rotation.y = deg_to_rad(yaw_deg)
	return _pairs[i]


func _show_all() -> void:
	for j: int in _pairs.size():
		var h: Node3D = _pairs[j][0].get_parent()
		h.visible = true
		h.position = ORIGIN + Vector3(-4.5 + 4.5 * float(j), 0, 0)
		h.rotation.y = deg_to_rad(30.0)


func _hide_all(on: bool) -> void:
	for p: Array in _pairs:
		(p[0].get_parent() as Node3D).visible = not on


## Riding idle: per rider a 3/4 front close-up, the side, a 3/4 back.
func _riding_sheet() -> void:
	var imgs: Array[Image] = []
	for view: Array in [[30.0, 18.0, 0.0, 4.3], [90.0, 6.0, 0.0, 4.6], [215.0, 26.0, 0.0, 4.3]]:
		for i: int in _pairs.size():
			_solo(i, view[0])
			_set_zoom(view[3], Vector3(0.0, 1.6, 0.0), view[1], view[2])
			await _wait(0.35)
			imgs.append(_grab())
	_sheet(imgs, 3, PREFIX + "riding", 800, 450)


## Per rider (rows) 5 frames of one gait cycle from the side (speed, cycle seconds), starting at the left hind footfall.
func _cycle_sheet(speed: float, cycle: float, nm: String) -> void:
	var imgs: Array[Image] = []
	for i: int in _pairs.size():
		var p := _solo(i, 90.0)
		_set_zoom(4.6, Vector3(0.0, 1.55, 0.0), 6.0)
		p[1].call(&"set_moving", speed)
		p[0].call(&"set_moving", speed)
		await _wait(1.2)
		await _until_phase(p[1], 0.0)
		for k: int in 5:
			imgs.append(_grab())
			await _wait(cycle / 5.0)
		p[1].call(&"set_moving", 0.0)
		p[0].call(&"set_moving", 0.0)
		await _wait(0.8)
	_sheet(imgs, 5, nm, 560, 315)


## Per rider: hop-on from the ground (t 0, 0.1, 0.2, 0.3 = seated), then hop-off (0.1, 0.2, 0.3 = landed), 3/4 front
## from the left flank (the mounting side).
func _mount_sheet() -> void:
	var imgs: Array[Image] = []
	for i: int in _pairs.size():
		var p := _solo(i, 40.0)
		_set_zoom(4.8, Vector3(-0.3, 1.3, 0.0), 14.0, 0.0)
		p[0].call(&"set_seated", false)
		await _wait(0.4)
		p[0].call(&"set_seated", true, p[1])
		p[0].call(&"play_mount")
		imgs.append(_grab())
		for t: float in [0.1, 0.2, 0.3]:
			await _until_rd(p[0], t)
			imgs.append(_grab())
		await _wait(0.5)
		p[0].call(&"play_dismount")
		for t: float in [0.1, 0.2]:
			await _until_rd(p[0], t)
			imgs.append(_grab())
		await _wait(0.15)
		p[1].visible = false   # gameplay removes / puffs the mount when the hop-off lands
		await get_tree().process_frame
		await get_tree().process_frame
		imgs.append(_grab())
		p[1].visible = true
		await _wait(0.3)
		p[0].call(&"set_seated", true, p[1])
	_sheet(imgs, 7, PREFIX + "mount", 480, 300)


## Per rider: thrown off (t 0.05, 0.12, 0.2, 0.28, 0.36, 0.44, landed), 3/4 front.
func _thrown_sheet() -> void:
	var imgs: Array[Image] = []
	for i: int in _pairs.size():
		var p := _solo(i, -40.0)
		_set_zoom(5.4, Vector3(0.4, 1.0, 0.0), 16.0, 0.0)
		await _wait(0.4)
		p[0].call(&"play_thrown")
		p[0].set(&"_rd_side", 1.0)   # thrown toward the camera side
		for t: float in [0.05, 0.12, 0.2, 0.28, 0.36, 0.44]:
			await _until_rd(p[0], t)
			imgs.append(_grab())
		await _wait(0.1)
		imgs.append(_grab())
		await _wait(0.3)
		p[0].call(&"set_seated", true, p[1])
	_sheet(imgs, 7, PREFIX + "thrown", 480, 300)


## The in-game read at 40 m: the three mounted (standing, walking, galloping) next to the same units on foot.
func _z40() -> void:
	_show_all()
	var extra: Array = []
	for i: int in RIDERS.size():
		extra.append(_spawn_foot(Vector3(-3.0 + 1.6 * float(i), 0, 3.2), 20.0, RIDERS[i]))
	_pairs[1][1].call(&"set_moving", 1.7)
	_pairs[2][1].call(&"set_moving", 6.0)
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.0))
	await _wait(1.0)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 1.8).save_png(OUT + PREFIX + "z40.png")
	_pairs[1][1].call(&"set_moving", 0.0)
	_pairs[2][1].call(&"set_moving", 0.0)
	for e: Node3D in extra:
		e.get_parent().queue_free()


## Unlit black on white (the 40 m black test): the three mounted riders side, 3/4 front, galloping; 25 m and 40 m.
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
	var yaws: Array[float] = [90.0, 30.0, 60.0]
	for j: int in _pairs.size():
		var h: Node3D = _pairs[j][0].get_parent()
		h.visible = true
		h.position = ORIGIN + Vector3(-4.6 + 4.6 * float(j), 0, 0)
		h.rotation.y = deg_to_rad(yaws[j])
	_pairs[2][1].call(&"set_moving", 6.0)
	await _wait(0.6)
	for p: Array in _pairs:
		for g: Node in (p[0].get_parent() as Node).find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 22.0 / (1.66 * z))
		var hh: int = int(float(w) * 0.34)
		var c := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - hh / 2, 0, 900 - hh), mini(w, 1600), mini(hh, 900)))
		c.resize(1600, 544, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1600, 544 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1600, 544), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1600, 544), Vector2i(0, 552))
	out.save_png(OUT + PREFIX + "silhouette.png")


## Crop a window of the same world size at every zoom, nearest upscale to 800 x 450.
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
		# centre crop to the cell's aspect, then scale
		var ar: float = float(w) / float(h)
		var cw: int = mini(im.get_width(), int(float(im.get_height()) * ar))
		var chh: int = int(float(cw) / ar)
		im = im.get_region(Rect2i((im.get_width() - cw) / 2, (im.get_height() - chh) / 2, cw, chh))
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


## Waits until the rider's seated transition time reaches t (s).
func _until_rd(m: Object, t: float) -> void:
	var guard := 0
	while float(m.get(&"_rd_t")) < t and StringName(m.call(&"seat_action")) != &"" and guard < 120:
		await get_tree().process_frame
		guard += 1


## Waits until the mount's gait phase wraps past `p` (0-1).
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
