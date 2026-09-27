extends Node3D
## Roan Courser preview (task 13.V6, based on the Rimehorn preview of 13.V1a). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . art/units/mounts/roan_courser/tools/roan_courser_preview.tscn --fixed-fps 60 -- --shots
## writes docs/art/screens/13_v6_*.png (views, walk, gallop, charge, poses, compare (vs the Dusk Steed), teams, seat,
## z40, silhouette) then quits. Without --shots: keys 1-5 zoom 6 / 12 / 25 / 40 / 55 · W walk · G gallop · C charge
## · H hit · F fidget (graze) · D death · R revive · T team colour · Y turn 45.
## The "rider" in the seat shots is a preview-only dummy (capsules) parented to seat_node(): the seat convention.

const SCENE := "res://art/units/mounts/roan_courser/roan_courser.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v6_"
const ORIGIN := Vector3(30.0, 0.0, 30.0)
const TEAMS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.45, 0.75, 0.95), Color(0.42, 0.22, 0.60), Color(0.35, 0.70, 0.25)]
const DUSK := "res://art/units/mounts/dusk_steed/dusk_steed.tscn"
const OTHERS: Array[String] = ["res://art/units/mounts/dusk_steed/dusk_steed.tscn", "res://art/units/champions/wayfinder/wayfinder.tscn",
	"res://art/units/champions/oathwall/oathwall.tscn", "res://art/units/mounts/ember_boar/ember_boar.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _team_i: int = 0
var _moving: float = 0.0
var _barded: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(0, 0, 0), 30.0))
	_set_zoom(7.0, Vector3(0, 1.0, 0.3))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, team: Color = TEAMS[0], barded: bool = false, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if m.has_method(&"set_barded"):
		m.call(&"set_barded", barded)
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
		KEY_1: _set_zoom(6.0, Vector3(0.0, 1.0, 0))
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_W: _move(0.0 if _moving == 1.7 else 1.7)
		KEY_G: _move(0.0 if _moving == 6.0 else 6.0)
		KEY_C: _all(&"play_charge")
		KEY_H: _all(&"play_hit")
		KEY_F: _all(&"play_fidget")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_B:
			_barded = not _barded
			for m: Node3D in _row:
				m.call(&"set_barded", _barded)
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
	await _cycle_sheet(1.8, 0.85, PREFIX + "walk")
	await _cycle_sheet(6.0, 0.465, PREFIX + "gallop")
	await _charge_sheet()
	await _poses_sheet()
	await _compare_sheet()
	await _teams_sheet()
	await _seat_sheet()
	await _z40()
	await _silhouettes()
	print("ROAN COURSER SHOTS DONE")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m: Node3D in _row:
		m.get_parent().visible = not on


## 2 x 3: game camera close (3/4 front), side, 3/4 back, a low detail on the head / horn, top view, 25 m crop.
func _views_sheet() -> void:
	var a: Node3D = _row[0]
	var imgs: Array[Image] = []
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(6.5, Vector3(0.0, 1.0, 0.2))
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(5.6, Vector3(0.0, 1.0, 0.0), 8.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 215.0)
	_set_zoom(5.6, Vector3(0.0, 1.0, 0.0), 32.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 150.0)
	_set_zoom(2.4, Vector3(0.55, 1.55, 0.7), 12.0, 20.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 0.0)
	_set_zoom(6.0, Vector3(0.0, 0.6, 0.2), 80.0)
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(25.0, Vector3.ZERO)
	await _wait(0.3)
	imgs.append(_crop(_grab(), 25.0))
	_sheet(imgs, 3, PREFIX + "views")


## 2 x 3 frames of one gait cycle from the side (speed, cycle seconds).
func _cycle_sheet(speed: float, cycle: float, nm: String) -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(5.8, Vector3(0.0, 1.0, 0.0), 6.0)
	a.call(&"set_moving", speed)
	await _wait(1.2)
	# start on the left hind footfall
	await _until_phase(a, 0.0)
	var imgs: Array[Image] = []
	for i: int in 6:
		imgs.append(_grab())
		await _wait(cycle / 6.0)
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	_sheet(imgs, 3, nm)


## Charge while galloping, 3/4 front: t 0 (galloping), 0.06 (horn levelled), 0.10 (strike), 0.2, 0.3 (toss), 0.6.
func _charge_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 60.0)
	_set_zoom(6.0, Vector3(0.0, 1.0, 0.3), 14.0, 20.0)
	a.call(&"set_moving", 6.0)
	await _wait(1.0)
	var imgs: Array[Image] = [_grab()]
	a.call(&"play_charge")
	for t: float in [0.06, 0.10, 0.2, 0.3, 0.6]:
		await _until(a, &"_action_t", t)
		imgs.append(_grab())
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "charge")


## Standing charge, toss (attack), hit, fidget (frost shake), death 0.3 / 0.6 / 1.0, revive.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	_place(a, Vector3.ZERO, 50.0)
	_set_zoom(6.2, Vector3(0.0, 0.9, 0.2), 22.0, 15.0)
	var imgs: Array[Image] = []
	await _wait(0.3)
	imgs.append(_grab())
	a.call(&"play_charge")
	await _until(a, &"_action_t", 0.10)
	imgs.append(_grab())
	await _wait(0.9)
	a.call(&"play_attack")
	await _until(a, &"_action_t", 0.13)
	imgs.append(_grab())
	await _wait(0.6)
	a.call(&"play_hit")
	await _wait(0.05)
	imgs.append(_grab())
	await _wait(0.4)
	a.call(&"play_fidget")
	await _until(a, &"_action_t", 1.2)
	imgs.append(_grab())
	await _until(a, &"_action_t", 2.7)
	imgs.append(_grab())
	await _wait(0.8)
	a.call(&"play_death")
	for t: float in [0.3, 0.6, 1.0]:
		await _until(a, &"_death_t", t)
		imgs.append(_grab())
	await _wait(0.3)
	a.call(&"revive")
	await _wait(0.4)
	imgs.append(_grab())
	for i: int in imgs.size():
		imgs[i] = imgs[i].get_region(Rect2i(250, 60, 1100, 780))
	_sheet(imgs, 5, PREFIX + "poses")


## The Roan Courser (left) next to the Dusk Steed (right, if it loads): side, 3/4 front, 3/4 back at the game camera,
## both galloping at 12 m, a 25 m crop, then the same pair as black silhouettes (side).
func _compare_sheet() -> void:
	if not ResourceLoader.exists(DUSK):
		return
	_hide_row(true)
	var p := _spawn(Vector3(-1.7, 0, 0), 30.0)
	var d := _spawn(Vector3(1.7, 0, 0), 30.0, TEAMS[2], false, DUSK)
	var imgs: Array[Image] = []
	for view: Array in [[90.0, 6.0, 0.0, 7.6], [30.0, 24.0, 0.0, 7.4], [215.0, 30.0, 0.0, 7.4]]:
		_place(p, Vector3(-1.7, 0, 0), view[0])
		_place(d, Vector3(1.7, 0, 0), view[0])
		_set_zoom(view[3], Vector3(0.0, 1.1, 0.0), view[1], view[2])
		await _wait(0.3)
		imgs.append(_grab())
	_place(p, Vector3(-1.7, 0, 0), 30.0)
	_place(d, Vector3(1.7, 0, 0), 30.0)
	p.call(&"set_moving", 6.0)
	d.call(&"set_moving", 6.0)
	_set_zoom(12.0, Vector3(0.0, 0.5, 0.0))
	await _wait(0.6)
	imgs.append(_grab())
	_set_zoom(25.0, Vector3.ZERO)
	await _wait(0.3)
	imgs.append(_crop(_grab(), 25.0))
	p.call(&"set_moving", 0.0)
	d.call(&"set_moving", 0.0)
	_place(p, Vector3(-1.7, 0, 0), 90.0)
	_place(d, Vector3(1.7, 0, 0), 90.0)
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
	for mm: Node3D in [p, d]:
		for g: Node in mm.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	_set_zoom(7.6, Vector3(0.0, 1.1, 0.0), 6.0)
	await _wait(0.4)
	imgs.append(_grab())
	_ground.material_override = old_ground
	_env.environment = old_env
	p.get_parent().queue_free()
	d.get_parent().queue_free()
	_hide_row(false)
	_sheet(imgs, 3, PREFIX + "compare")

## The 4 team colours side by side (saddle-cloth only): game camera close, then the same at 40 m.
func _teams_sheet() -> void:
	_hide_row(true)
	var ms: Array = []
	for i: int in 4:
		ms.append(_spawn(Vector3(-5.1 + 3.4 * float(i), 0, 0), 25.0, TEAMS[i], i >= 2))
	var imgs: Array[Image] = []
	_set_zoom(12.0, Vector3(0.0, 0.8, 0.0), 42.0)
	await _wait(0.5)
	imgs.append(_grab())
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.4)
	imgs.append(_crop(_grab(), 40.0, 2.4))
	for m: Node3D in ms:
		m.get_parent().queue_free()
	_hide_row(false)
	_sheet(imgs, 2, PREFIX + "teams")


## The Seat convention: a preview dummy rider parented to seat_node(): standing, walking, galloping (bob), charge,
## death (the seat rolls with the body; gameplay throws the rider first).
func _seat_sheet() -> void:
	var a: Node3D = _row[0]
	var dummy := _rider_dummy()
	(a.call(&"seat_node") as Node3D).add_child(dummy)
	_place(a, Vector3.ZERO, 90.0)
	_set_zoom(6.4, Vector3(0.0, 1.3, 0.0), 8.0)
	var imgs: Array[Image] = []
	await _wait(0.3)
	imgs.append(_grab())
	a.call(&"set_moving", 6.0)
	await _wait(1.0)
	await _until_phase(a, 0.0)
	imgs.append(_grab())
	await _wait(0.16)
	imgs.append(_grab())
	a.call(&"play_charge")
	await _until(a, &"_action_t", 0.10)
	imgs.append(_grab())
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	_place(a, Vector3.ZERO, 30.0)
	_set_zoom(6.5, Vector3(0.0, 1.2, 0.2))
	await _wait(0.3)
	imgs.append(_grab())
	_place(a, Vector3.ZERO, 215.0)
	_set_zoom(6.5, Vector3(0.0, 1.2, 0.0), 30.0)
	await _wait(0.3)
	imgs.append(_grab())
	dummy.queue_free()
	_sheet(imgs, 3, PREFIX + "seat")


func _rider_dummy() -> Node3D:
	var root := Node3D.new()
	root.name = "RiderDummy"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.72, 0.55)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.2, 0.35, 0.65)
	var parts: Array = [[CapsuleMesh.new(), Vector3(0, 0.36, 0.02), Vector3(0.20, 0.72, 0), cm],
		[SphereMesh.new(), Vector3(0, 0.86, 0.04), Vector3(0.14, 0.28, 0), mat],
		[CapsuleMesh.new(), Vector3(0.26, 0.02, 0.18), Vector3(0.09, 0.62, 0), cm],
		[CapsuleMesh.new(), Vector3(-0.26, 0.02, 0.18), Vector3(0.09, 0.62, 0), cm]]
	for p: Array in parts:
		var mi := MeshInstance3D.new()
		var mesh: PrimitiveMesh = p[0]
		if mesh is CapsuleMesh:
			(mesh as CapsuleMesh).radius = (p[2] as Vector3).x
			(mesh as CapsuleMesh).height = (p[2] as Vector3).y
		else:
			(mesh as SphereMesh).radius = (p[2] as Vector3).x
			(mesh as SphereMesh).height = (p[2] as Vector3).y
		mi.mesh = mesh
		mi.material_override = p[3]
		mi.position = p[1]
		if (p[1] as Vector3).y < 0.1:
			mi.rotation_degrees = Vector3(-60, 0, 20.0 * signf((p[1] as Vector3).x))
		root.add_child(mi)
	return root


## The in-game read at 40 m: a standing, a walking, a galloping and a charging Roan Courser next to the Dusk Steed,
## the Wayfinder, the Oathwall and the Ember Boar.
func _z40() -> void:
	_hide_row(true)
	var ms: Array = []
	ms.append(_spawn(Vector3(-5.0, 0, 0.5), 20.0))
	ms.append(_spawn(Vector3(-2.2, 0, -0.6), 160.0, TEAMS[1]))
	ms.append(_spawn(Vector3(0.6, 0, 0.6), 70.0))
	ms.append(_spawn(Vector3(3.2, 0, -0.4), -30.0, TEAMS[1], true))
	var extra := _others(5.6)
	await _wait(0.3)
	ms[1].call(&"set_moving", 1.7)
	ms[2].call(&"set_moving", 6.0)
	ms[3].call(&"set_moving", 6.0)
	_set_zoom(40.0, Vector3(1.5, 0.0, 0.0))
	await _wait(0.8)
	ms[3].call(&"play_charge")
	await _wait(0.1)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 40.0, 2.0).save_png(OUT + PREFIX + "z40.png")
	for m: Node3D in ms + extra:
		m.get_parent().queue_free()
	_hide_row(false)


func _others(x0: float) -> Array:
	var out: Array = []
	var x := x0
	for p: String in OTHERS:
		if ResourceLoader.exists(p):
			out.append(_spawn(Vector3(x, 0, 0), 20.0, Color(0.45, 0.75, 0.95), false, p))
			x += 1.9
	return out


## Unlit black on white (the 40 m black test): Roan Courser side, 3/4 front, 3/4 back, galloping, 3/4; at 25 m and
## 40 m, next to the other units.
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
		units.append(_spawn(Vector3(-11.0 + 3.9 * float(i), 0, 0), yaws[i], TEAMS[0], i == 4))
	units[3].call(&"set_moving", 6.0)
	units.append_array(_others(9.2))
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
		var w: int = int(1600.0 * 32.0 / (1.66 * z))
		var h: int = int(float(w) * 0.30)
		var c := img.get_region(Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(470 - h / 2, 0, 900 - h), mini(w, 1600), mini(h, 900)))
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
	while float(m.get(prop)) < t and guard < 240:
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
