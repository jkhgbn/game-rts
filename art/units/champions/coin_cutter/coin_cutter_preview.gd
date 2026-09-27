extends Node3D
## Coin-Cutter preview (task 9.V3). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . art/units/champions/coin_cutter/coin_cutter_preview.tscn -- --shots
## writes docs/art/screens/champion_coin_cutter_*.png (variants, z40, poses, silhouette) then quits.
## `-- --classes` (task 11.V4) writes docs/art/screens/champion_coin_cutter_classes.png: one row per weapon (knives,
## spear, sword_shield, two_hand, wizard) x front 3/4, back 3/4, attack strike, Cutpurse, Smoke Pouch, Marked for Coin;
## then the 5 side by side at the 40 m game camera in colour and as a black silhouette (next to a Shade).
## Without --shots: keys 1-5 zoom 6 / 12 / 25 / 40 / 55 · A attack · C cast cycle · H hit · D death · R revive ·
## L level-up · W walk toggle · Y turn · V swap variants.

const SCENE := "res://art/units/champions/coin_cutter/coin_cutter.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "champion_coin_cutter_"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 0.95)
const NATURE := Color(0.35, 0.70, 0.25)
const CASTS: Array[StringName] = [&"cutpurse", &"smoke_pouch", &"marked_for_coin"]
const SCALE_UNITS: Array = [["res://art/units/shadow/shade.tscn", SHADOW], ["res://art/units/fire/flame_guard.tscn", FIRE],
	["res://art/units/wizards/vessa.tscn", FIRE]]
const ORIGIN := Vector3(20.0, 0.0, 20.0)

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _cast_i: int = 0
var _walking: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-0.9, 0, 0), 0.0, 0, FIRE))
	_row.append(_spawn(Vector3(0.9, 0, 0), 0.0, 1, SHADOW))
	_set_zoom(6.0, Vector3(0.0, 1.0, 0.0))
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	elif "--classes" in OS.get_cmdline_user_args():
		_take_class_shots()


func _spawn(at: Vector3, yaw_deg: float, variant: int, col: Color, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	if m.has_method(&"set_variant"):
		m.call(&"set_variant", variant)
	holder.add_child(m)
	m.set(&"_idle_left", 1.0e9)
	m.set(&"_fidget_next", 1.0e9)
	if m.has_method(&"set_team_color"):
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
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L: _all(&"play_level_up")
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_V:
			for m: Node3D in _row:
				m.call(&"set_variant", 1 - int(m.get(&"variant")))
		KEY_W:
			_walking = not _walking
			for m: Node3D in _row:
				m.call(&"set_moving", 5.6 if _walking else 0.0)
		KEY_C:
			for m: Node3D in _row:
				m.call(&"play_cast", CASTS[_cast_i])
			_cast_i = (_cast_i + 1) % CASTS.size()


func _all(method: StringName) -> void:
	for m: Node3D in _row:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	await _variants_sheet()
	await _z40()
	await _poses_sheet()
	await _silhouettes()
	get_tree().quit()


## 2 x 3 sheet: variant A (Fire) and B (Shadow) from the game camera close, a low detail camera front, 3/4 back,
## side; then both at 25 m and 40 m game zoom (crops, nearest upscale) next to a Shade / Flame Guard / Vessa.
func _variants_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	var imgs: Array[Image] = []
	var labels: Array[String] = []
	_place(a, Vector3(-0.75, 0, 0), 0.0)
	_place(b, Vector3(0.75, 0, 0), 0.0)
	_set_zoom(5.2, Vector3(0.0, 0.95, 0.0))
	await _wait(0.5)
	imgs.append(_grab())
	_set_zoom(3.6, Vector3(0.0, 1.05, 0.0), 12.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 150.0)
	_place(b, Vector3(0.75, 0, 0), 215.0)
	_set_zoom(5.2, Vector3(0.0, 0.95, 0.0), 40.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 90.0)
	_place(b, Vector3(0.75, 0, 0), -90.0)
	_set_zoom(4.4, Vector3(0.0, 1.0, 0.0), 18.0)
	await _wait(0.4)
	imgs.append(_grab())
	_place(a, Vector3(-0.75, 0, 0), 20.0)
	_place(b, Vector3(0.75, 0, 0), -20.0)
	var extra: Array = []
	for i: int in SCALE_UNITS.size():
		if ResourceLoader.exists(SCALE_UNITS[i][0]):
			extra.append(_spawn(Vector3(2.3 + 1.5 * float(i), 0, 0), 0.0, 0, SCALE_UNITS[i][1], SCALE_UNITS[i][0]))
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(1.4, 0.0, 0.0))
		await _wait(0.5)
		imgs.append(_crop(_grab(), z))
	for m: Node3D in extra:
		m.get_parent().queue_free()
	_sheet(imgs, 2, PREFIX + "variants")


## The in-game read at 40 m (pitch 55): four Coin-Cutters in the four kingdom colours, one walking, one attacking.
func _z40() -> void:
	var cols: Array[Color] = [FIRE, SHADOW, ICE, NATURE]
	var extra: Array = []
	for m: Node3D in _row:
		m.get_parent().visible = false
	for i: int in 4:
		extra.append(_spawn(Vector3(-3.0 + 2.0 * float(i), 0, 0), 25.0 * float(i) - 20.0, i % 2, cols[i]))
	await _wait(0.4)
	extra[1].call(&"set_moving", 5.6)
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.6)
	extra[2].call(&"play_attack")
	await _wait(0.07)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	var c := _crop(img, 40.0)
	c.save_png(OUT + PREFIX + "z40.png")
	for m: Node3D in extra:
		m.get_parent().queue_free()
	for m: Node3D in _row:
		m.get_parent().visible = true


## One frame per state (A front 3/4 + B side): idle, walk, slash2 (wind / strike / backhand), cutpurse (coil,
## lunge), smoke_pouch (reach, overhead, throw), marked_for_coin (flip apex, point), hit, level-up, death, revived.
func _poses_sheet() -> void:
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	_place(a, Vector3(-0.8, 0, 0), 30.0)
	_place(b, Vector3(0.8, 0, 0), 90.0)
	_set_zoom(4.0, Vector3(0.0, 0.9, 0.0), 30.0)
	var pair: Array = [a, b]
	var frames: Array[Image] = []
	await _wait(0.5)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 5.6)
	await _wait(0.72)
	frames.append(_grab())
	for m: Node3D in pair:
		m.call(&"set_moving", 0.0)
	await _wait(0.6)
	for t: float in [0.05, 0.09, 0.17]:
		for m: Node3D in pair:
			m.call(&"play_attack")
		await _until(a, &"_action_t", t)
		frames.append(_grab())
		await _wait(0.6)
	var keys: Array = [[&"cutpurse", 0.12], [&"cutpurse", 0.24], [&"smoke_pouch", 0.13], [&"smoke_pouch", 0.29],
		[&"smoke_pouch", 0.36], [&"marked_for_coin", 0.45], [&"marked_for_coin", 0.84]]
	for k: Array in keys:
		for m: Node3D in pair:
			m.call(&"play_cast", k[0])
		await _until(a, &"_action_t", float(k[1]))
		frames.append(_grab())
		await _wait(1.1)
	for m: Node3D in pair:
		m.call(&"play_hit")
	await _wait(0.06)
	frames.append(_grab())
	await _wait(0.5)
	for m: Node3D in pair:
		m.call(&"play_level_up")
	await _wait(0.16)
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


## Unlit black on white (the 40 m black test): A front, B 3/4 back, A side, walking B; at 25 m and 40 m, next to a
## Shade and a Flame Guard (same role family) to show the outline differs.
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
		units.append(_spawn(Vector3(-3.3 + 1.6 * float(i), 0, 0), yaws[i], i % 2, FIRE))
	units[3].call(&"set_moving", 5.6)
	for i: int in 2:
		units.append(_spawn(Vector3(3.3 + 1.6 * float(i), 0, 0), 20.0, 0, SCALE_UNITS[i][1], SCALE_UNITS[i][0]))
	await _wait(0.5)
	var saved: Array = []
	for m: Node3D in units:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			saved.append([g, (g as GeometryInstance3D).material_override])
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.8, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var w: int = int(1600.0 * 12.0 / (1.66 * z))
		var h: int = int(float(w) * 0.42)
		var c := img.get_region(Rect2i(800 - w / 2, 470 - h / 2, w, h))
		c.resize(1200, 504, Image.INTERPOLATE_NEAREST)
		imgs.append(c)
	var out := Image.create(1200, 504 * 2 + 8, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	out.blit_rect(imgs[0], Rect2i(0, 0, 1200, 504), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(0, 0, 1200, 504), Vector2i(0, 512))
	out.save_png(OUT + PREFIX + "silhouette.png")
	for s: Array in saved:
		(s[0] as GeometryInstance3D).material_override = s[1]
	_ground.material_override = old_ground
	_env.environment = old_env
	for m: Node3D in units:
		m.get_parent().queue_free()
	for m: Node3D in _row:
		m.get_parent().visible = true


const CLASS_ROWS: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const STRIKE_T: Array[float] = [0.09, 0.12, 0.12, 0.16, 0.14]
const CLASS_CASTS: Array = [[&"cutpurse", 0.21], [&"smoke_pouch", 0.36], [&"marked_for_coin", 0.84]]


func _take_class_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for m: Node3D in _row:
		m.get_parent().visible = false
	await _wait(1.0)
	var cells: Array[Image] = []
	for r: int in CLASS_ROWS.size():
		var m := _spawn(Vector3.ZERO, 0.0, r % 2, FIRE if r % 2 == 0 else SHADOW)
		m.call(&"set_weapon_class", CLASS_ROWS[r], false)
		await _wait(0.3)
		_place(m, Vector3.ZERO, -30.0)
		_set_zoom(4.9, Vector3(0, 1.15, 0), 10.0)
		await _wait(0.3)
		cells.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
		_place(m, Vector3.ZERO, 150.0)
		await _wait(0.3)
		cells.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
		_place(m, Vector3.ZERO, -55.0)
		_set_zoom(5.4, Vector3(0, 1.1, 0.3), 14.0)
		await _wait(0.3)
		m.call(&"play_attack")
		await _until(m, &"_action_t", STRIKE_T[r])
		cells.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
		await _wait(1.0)
		for c: Array in CLASS_CASTS:
			m.call(&"play_cast", c[0])
			await _until(m, &"_action_t", float(c[1]))
			cells.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
			await _wait(1.2)
		m.get_parent().queue_free()
		await _wait(0.1)
	# 40 m bands: the 5 weapons side by side (+ a Shade), colour then black on white.
	var line: Array = []
	for r: int in CLASS_ROWS.size():
		var m := _spawn(Vector3(-4.0 + 1.6 * float(r), 0, 0), 20.0, 0, FIRE)
		m.call(&"set_weapon_class", CLASS_ROWS[r], false)
		line.append(m)
	if ResourceLoader.exists(SCALE_UNITS[0][0]):
		line.append(_spawn(Vector3(4.0, 0, 0), 20.0, 0, SCALE_UNITS[0][1], SCALE_UNITS[0][0]))
	await _wait(0.5)
	_set_zoom(40.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.4)
	var bands: Array[Image] = [_band(_grab())]
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
	var old_env := _env.environment
	_env.environment = e
	for m: Node3D in line:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	await _wait(0.4)
	bands.append(_band(_grab()))
	_env.environment = old_env
	# compose: 5 rows x 6 cells (300 x 369), then the two 1800 x 360 bands
	var cw := 300
	var chh := 369
	var out := Image.create(cw * 6, chh * 5 + 360 * 2 + 8, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in cells.size():
		var im: Image = cells[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(cw, chh, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, cw, chh), Vector2i((i % 6) * cw, (i / 6) * chh))
	for b: int in bands.size():
		out.blit_rect(bands[b], Rect2i(0, 0, 1800, 360), Vector2i(0, chh * 5 + 4 + b * 364))
	out.save_png(OUT + PREFIX + "classes.png")
	print("COIN-CUTTER CLASS SHOTS DONE")
	get_tree().quit()


## The middle of a 40 m frame (~10 x 2 m around the line), nearest-upscaled to 1800 x 360 (5x: true 40 m pixels).
func _band(img: Image) -> Image:
	var w := 360
	var h := 72
	var c := img.get_region(Rect2i(img.get_width() / 2 - w / 2, img.get_height() / 2 - h / 2 - 10, w, h))
	c.convert(Image.FORMAT_RGBA8)
	c.resize(1800, 360, Image.INTERPOLATE_NEAREST)
	return c


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = ORIGIN + at
	h.rotation.y = deg_to_rad(yaw_deg)


## Crop a window of the same world size at every zoom (~8 x 4.5 m), nearest upscale to 800 x 450.
func _crop(img: Image, z: float) -> Image:
	var w: int = clampi(int(1600.0 * 12.0 / z * 0.55), 80, 1600)
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
