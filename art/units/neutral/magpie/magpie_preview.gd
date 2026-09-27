extends Node3D
## Magpie preview (task 10.V6). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . art/units/neutral/magpie/magpie_preview.tscn -- --shots
## writes docs/art/screens/magpie_*.png (views, z40, poses, silhouette) then quits.
## Without --shots: keys 1-5 zoom 6 / 12 / 25 / 40 / 55 · A attack · S snatch · F smoke flee (shroud 2 s) · K carry
## toggle · H hit · D death · R revive · W walk toggle · Y turn.

const SCENE := "res://art/units/neutral/magpie/magpie.tscn"
const COIN_CUTTER := "res://art/units/champions/coin_cutter/coin_cutter.tscn"
const CARAVAN := "res://art/units/caravan/caravan.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "magpie_"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ORIGIN := Vector3(20.0, 0.0, 20.0)

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _walking: bool = false
var _carry: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-0.8, 0, 0), 0.0))
	_row.append(_spawn(Vector3(0.8, 0, 0), 0.0, true))
	_set_zoom(6.0, Vector3(0.0, 1.0, 0.0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, carrying: bool = false, path: String = SCENE, col: Color = FIRE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	m.set(&"_idle_left", 1.0e9)
	m.set(&"_fidget_next", 1.0e9)
	if carrying and m.has_method(&"set_carrying"):
		m.call(&"set_carrying", true)
	if m.has_method(&"set_loaded"):
		m.call(&"set_loaded", true)
	if path != SCENE and m.has_method(&"set_team_color"):
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
		KEY_1: _set_zoom(6.0, Vector3(0.0, 1.0, 0))
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_S: _all(&"play_snatch")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_F:
			for m: Node3D in _row:
				m.call(&"set_status", &"shroud", true)
			await _wait(2.0)
			for m: Node3D in _row:
				m.call(&"set_status", &"shroud", false)
		KEY_K:
			_carry = not _carry
			for m: Node3D in _row:
				m.call(&"set_carrying", _carry)
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m: Node3D in _row:
				m.call(&"set_moving", 5.2 if _walking else 0.0)


func _all(method: StringName) -> void:
	for m: Node3D in _row:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	await _views_sheet()
	await _z40()
	await _poses_sheet()
	await _silhouettes()
	get_tree().quit()


## Extra units for scale / comparison: the Coin-Cutter (the other thief-like figure, must read differently) and the
## caravan (loaded) if 10.V5 has landed.
func _others(x0: float, yaw: float = 20.0) -> Array:
	var out: Array = []
	var x := x0
	out.append(_spawn(Vector3(x, 0, 0), yaw, false, COIN_CUTTER, FIRE))
	x += 1.6
	if ResourceLoader.exists("res://art/units/shadow/shade.tscn"):
		out.append(_spawn(Vector3(x, 0, 0), yaw, false, "res://art/units/shadow/shade.tscn", SHADOW))
		x += 1.6
	if ResourceLoader.exists(CARAVAN):
		out.append(_spawn(Vector3(x + 1.0, 0, 0), 60.0, false, CARAVAN, FIRE))
	return out


## 2 x 3 sheet: empty-handed and carrying Magpies from the game camera close, a low front detail camera, 3/4 back,
## side; then at 25 m and 40 m game zoom (crops, nearest upscale) next to a Coin-Cutter, a Shade and a caravan.
func _views_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	var imgs: Array[Image] = []
	_place(a, Vector3(-0.75, 0, 0), 0.0)
	_place(b, Vector3(0.75, 0, 0), 0.0)
	_set_zoom(5.2, Vector3(0.0, 0.9, 0.0))
	await _wait(0.5)
	imgs.append(_grab())
	_set_zoom(3.4, Vector3(0.0, 1.0, 0.0), 10.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 150.0)
	_place(b, Vector3(0.75, 0, 0), 215.0)
	_set_zoom(5.2, Vector3(0.0, 0.9, 0.0), 40.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 90.0)
	_place(b, Vector3(0.75, 0, 0), -90.0)
	_set_zoom(4.4, Vector3(0.0, 0.9, 0.0), 14.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 20.0)
	_place(b, Vector3(0.75, 0, 0), -20.0)
	var extra := _others(2.4)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(2.0, 0.0, 0.0))
		await _wait(0.5)
		imgs.append(_crop(_grab(), z))
	for m: Node3D in extra:
		m.get_parent().queue_free()
	_sheet(imgs, 2, PREFIX + "views")


## The in-game read at 40 m (pitch 55): a lurking Magpie, one walking off with loot, one snatching, one fleeing in
## smoke, next to a Coin-Cutter and a loaded caravan (if present).
func _z40() -> void:
	for m: Node3D in _row:
		m.get_parent().visible = false
	var mags: Array = []
	mags.append(_spawn(Vector3(-4.0, 0, 0), 10.0))
	mags.append(_spawn(Vector3(-2.3, 0, 0.6), 200.0, true))
	mags.append(_spawn(Vector3(-0.6, 0, 0), 40.0))
	mags.append(_spawn(Vector3(1.0, 0, 0.8), 150.0, true))
	var extra := _others(2.8, -20.0)
	await _wait(0.4)
	mags[1].call(&"set_moving", 5.2)
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	mags[3].call(&"set_moving", 5.2)
	mags[3].call(&"set_status", &"shroud", true)
	await _wait(0.6)
	mags[2].call(&"play_snatch")
	await _wait(0.6)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	var c := _crop(img, 40.0)
	c.save_png(OUT + PREFIX + "z40.png")
	for m: Node3D in mags + extra:
		m.get_parent().queue_free()
	for m: Node3D in _row:
		m.get_parent().visible = true


## One frame per state (empty-handed front 3/4 + carrying side): lurk, head snap, sneak walk, walk carrying, scissor
## (wind / strike), snatch (lunge, rummage, yank), smoke flee (dip, spring), flee sprint, hit, death, revived.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	_place(a, Vector3(-0.8, 0, 0), 30.0)
	_place(b, Vector3(0.8, 0, 0), 90.0)
	_set_zoom(4.0, Vector3(0.0, 0.8, 0.0), 30.0)
	var pair: Array = [a, b]
	var frames: Array[Image] = []
	await _wait(0.5)
	frames.append(_grab())
	await _wait(0.9)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 5.2)
	await _wait(0.66)
	frames.append(_grab())
	await _wait(0.12)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 0.0)
	await _wait(0.6)
	for t: float in [0.05, 0.11]:
		for m: Node3D in pair:
			m.call(&"play_attack")
		await _until(a, &"_action_t", t)
		frames.append(_grab())
		await _wait(0.6)
	b.call(&"set_carrying", false)
	for m: Node3D in pair:
		m.call(&"play_snatch")
	for t: float in [0.3, 0.72, 1.22]:
		await _until(a, &"_action_t", t)
		frames.append(_grab())
	await _wait(0.5)
	b.call(&"set_carrying", true)
	await _wait(0.4)
	for m: Node3D in pair:
		m.call(&"set_moving", 5.2)
		m.call(&"set_status", &"shroud", true)
	for t: float in [0.1, 0.3]:
		await _until(a, &"_action_t", t)
		frames.append(_grab())
	await _wait(0.5)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_status", &"shroud", false)
		m.call(&"set_moving", 0.0)
	await _wait(1.2)
	for m: Node3D in pair:
		m.call(&"play_hit")
	await _wait(0.06)
	frames.append(_grab())
	await _wait(0.6)
	for m: Node3D in pair:
		m.call(&"play_death")
	for t: float in [0.3, 0.75]:
		await _until(a, &"_death_t", t)
		frames.append(_grab())
	await _wait(0.5)
	for m: Node3D in pair:
		m.call(&"revive")
	await _wait(0.3)
	frames.append(_grab())
	for i: int in frames.size():
		frames[i] = frames[i].get_region(Rect2i(300, 20, 1000, 860))
	_sheet(frames, 5, PREFIX + "poses")


## Unlit black on white (the 40 m black test): Magpie front, 3/4 back with the sack, side, walking; at 25 m and 40 m,
## next to a Coin-Cutter, a Shade and a caravan (if present).
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
	var yaws: Array[float] = [0.0, 160.0, 90.0, 30.0]
	for i: int in 4:
		units.append(_spawn(Vector3(-3.6 + 1.6 * float(i), 0, 0), yaws[i], i == 1 or i == 3))
	units[3].call(&"set_moving", 5.2)
	units.append_array(_others(3.0))
	await _wait(0.5)
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(1.2, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 13.0 / (1.66 * z))
		var h: int = int(float(w) * 0.42)
		var c := img.get_region(Rect2i(800 - w / 2, 470 - h / 2, w, h))
		c.resize(1200, 504, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1200, 504 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1200, 504), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1200, 504), Vector2i(0, 512))
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


## Crop a window of the same world size at every zoom (~9 x 5 m), nearest upscale to 800 x 450.
func _crop(img: Image, z: float) -> Image:
	var w: int = clampi(int(1600.0 * 13.0 / z * 0.55), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var r := Rect2i(clampi(800 - w / 2, 0, 1600 - w), clampi(450 - h / 2 - int(h * 0.1), 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String) -> void:
	var w: int = 800
	var h: int = 450
	if imgs[0].get_width() == 1000 and imgs[0].get_height() == 860:
		w = 500
		h = 430
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
