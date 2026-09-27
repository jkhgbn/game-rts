extends Node3D
## Frost Dragon preview (task 13c.V1). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/titans/frost_dragon/frost_dragon_preview.tscn -- --shots
## writes docs/art/screens/13c_v1_*.png (z40 game camera over an Ice army, side by side with the Cinder Dragon at 40 m
## and close, flight states, close-ups, breath, death, black silhouettes of both dragons, scale lineup, kingdom tints)
## then quits. Add --only=<name> to render one sheet.
## Without --shots: keys 1-6 zoom 8 / 15 / 25 / 40 / 55 / close · W fly toggle · T turn toggle · A breath · H hit ·
## D death · R revive · Y turn 45 deg · C next kingdom colour.

const SCENE := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const CINDER := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13c_v1_"
const ICE := Color(0.55, 0.80, 0.95)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const NATURE := Color(0.45, 0.8, 0.35)
const COLOSSUS := "res://art/units/ice/rime_colossus.tscn"
const SHIELD := "res://art/units/ice/rimeshield.tscn"
const CASTER := "res://art/units/ice/shardcaster.tscn"
const SEER := "res://art/units/ice/rime_seer.tscn"
const TORVALD := "res://art/units/wizards/torvald.tscn"
const RIDER := "res://art/units/fire/blaze_rider.tscn"
const SPEED := 5.0

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _sun: DirectionalLight3D
var _dragon: Node3D
var _extra: Array = []
var _flying: bool = false
var _turning: bool = false
var _col_i: int = 0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	_cam.make_current()
	_dragon = _spawn(SCENE, Vector3.ZERO, 30.0, ICE)
	_set_zoom(18.0, Vector3(0.0, 3.5, 0.0), 30.0, 20.0)
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		var only := ""
		for a: String in args:
			if a.begins_with("--only="):
				only = a.substr(7)
		_take_shots(only)


func _process(delta: float) -> void:
	if _turning and is_instance_valid(_dragon):
		_dragon.get_parent().rotation.y += deg_to_rad(110.0) * delta


func _spawn(path: String, at: Vector3, yaw_deg: float, col: Color) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	if col.a > 0.0 and m.has_method(&"set_team_color"):
		m.call(&"set_team_color", col)
	return m


func _setup_world() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.00, 0.93, 0.82)
	_sun.light_energy = 1.3
	_sun.rotation_degrees = Vector3(-50, 35, 0)
	_sun.shadow_enabled = true
	_sun.shadow_normal_bias = 2.0
	_sun.directional_shadow_max_distance = 120.0
	add_child(_sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	_ground.mesh = pm
	# A plain painted-grass stand-in: art/environment/ground.gdshader does not compile at the time of 13c.V1 (another
	# agent's work in progress: "default values to uniform arrays"), and a failed ground renders flat grey.
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.46, 0.72, 0.28)
	grass.roughness = 1.0
	var nt := NoiseTexture2D.new()
	nt.noise = FastNoiseLite.new()
	nt.noise.frequency = 0.02
	nt.seamless = true
	grass.albedo_texture = nt
	grass.uv1_scale = Vector3(6, 6, 6)
	_ground.material_override = grass
	add_child(_ground)


func _set_zoom(z: float, focus: Vector3 = Vector3.ZERO, pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	_cam.position = focus + back * z
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(8.0, Vector3(0.0, 4.5, 0.0), 20.0, 30.0)
		KEY_2: _set_zoom(15.0, Vector3(0.0, 3.0, 0.0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_6: _set_zoom(5.0, Vector3(0.0, 5.0, 2.4), 15.0, 40.0)
		KEY_A: _dragon.call(&"play_attack")
		KEY_H: _dragon.call(&"play_hit")
		KEY_D: _dragon.call(&"play_death")
		KEY_R: _dragon.call(&"revive")
		KEY_Y: _dragon.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_T: _turning = not _turning
		KEY_C:
			_col_i = (_col_i + 1) % 4
			_dragon.call(&"set_team_color", [ICE, FIRE, SHADOW, NATURE][_col_i])
		KEY_W:
			_flying = not _flying
			_dragon.call(&"set_moving", SPEED if _flying else 0.0)


# ---------------------------------------------------------------- screenshots

func _take_shots(only: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	var sheets: Array[String] = ["z40", "duo", "flight", "close", "breath", "death", "silhouette", "scale", "teams"]
	for s: String in sheets:
		if only != "" and only != s:
			continue
		match s:
			"z40": await _shot_z40()
			"duo": await _shot_duo()
			"flight": await _shot_flight()
			"close": await _shot_close()
			"breath": await _shot_breath()
			"death": await _shot_death()
			"silhouette": await _shot_silhouette()
			"scale": await _shot_scale()
			"teams": await _shot_teams()
	print("FROST DRAGON SHOTS DONE")
	get_tree().quit()


func _clear_extra() -> void:
	for m: Node3D in _extra:
		if is_instance_valid(m):
			m.get_parent().queue_free()
	_extra.clear()


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = at
	h.rotation.y = deg_to_rad(yaw_deg)


func _reset_dragon(at: Vector3 = Vector3.ZERO, yaw: float = 30.0) -> void:
	_dragon.call(&"revive")
	_dragon.call(&"set_moving", 0.0)
	_place(_dragon, at, yaw)
	_dragon.get_parent().visible = true


## The in-game read: game camera 40 m (pitch 55), the dragon hovering over a small Ice army (Rime Colossus, Torvald,
## Rimeshields, Shardcasters, a Rime Seer), a second dragon flying and banking. Full frame + a 2x crop.
func _shot_z40() -> void:
	_reset_dragon(Vector3(-3.0, 0, 1.0), 20.0)
	var d2 := _spawn(SCENE, Vector3(7.0, 0, -3.0), 110.0, ICE)
	_extra.append(d2)
	d2.call(&"set_moving", SPEED)
	var units: Array = [[COLOSSUS, Vector3(3.0, 0, 5.5), 200.0], [TORVALD, Vector3(0.0, 0, 6.5), 180.0],
		[SHIELD, Vector3(-2.0, 0, 7.0), 180.0], [SHIELD, Vector3(-3.2, 0, 7.2), 180.0],
		[CASTER, Vector3(-5.0, 0, 6.0), 160.0], [CASTER, Vector3(-6.2, 0, 6.3), 160.0], [SEER, Vector3(1.5, 0, 8.0), 180.0]]
	for u: Array in units:
		if ResourceLoader.exists(u[0]):
			_extra.append(_spawn(u[0], u[1], u[2], ICE))
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.5))
	for k: int in 30:
		d2.get_parent().rotation.y += deg_to_rad(2.0)
		await get_tree().process_frame
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 0.5).save_png(OUT + PREFIX + "z40.png")
	_clear_extra()


## Side by side with the Cinder Dragon: at 40 m game camera (one hovering, one flying each; full frame + 2x crop), and
## at 20 m (both hovering, same heading).
func _shot_duo() -> void:
	_reset_dragon(Vector3(-5.0, 0, 2.0), 25.0)
	var c1 := _spawn(CINDER, Vector3(5.0, 0, 2.0), -25.0, FIRE)
	var f2 := _spawn(SCENE, Vector3(-6.0, 0, -7.0), 80.0, ICE)
	var c2 := _spawn(CINDER, Vector3(6.0, 0, -7.0), -80.0, FIRE)
	_extra.append_array([c1, f2, c2])
	f2.call(&"set_moving", SPEED)
	c2.call(&"set_moving", 5.5)
	_set_zoom(40.0, Vector3(0.0, 0.0, -1.0))
	await _wait(1.5)
	var img := _grab()
	img.save_png(OUT + PREFIX + "duo_z40_full.png")
	_crop(img, 0.55).save_png(OUT + PREFIX + "duo_z40.png")
	_clear_extra()
	_reset_dragon(Vector3(-4.5, 0, 0.0), 35.0)
	var c3 := _spawn(CINDER, Vector3(4.5, 0, 0.0), 35.0, FIRE)
	_extra.append(c3)
	var imgs: Array[Image] = []
	_set_zoom(20.0, Vector3(0.0, 3.4, 0.0), 30.0, 10.0)
	await _wait(0.8)
	await _until_phase(0.45)
	imgs.append(_grab())
	_set_zoom(17.0, Vector3(0.0, 4.2, 0.0), 8.0, 90.0)
	_place(_dragon, Vector3(0.0, 0, -4.5), 0.0)
	_place(c3, Vector3(0.0, 0, 4.5), 0.0)
	await _wait(0.5)
	await _until_phase(0.02)
	imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "duo_close")
	_clear_extra()


## 2 x 3 at 13 m: hover wings up / wings down, forward flap, glide, banking turn, breath.
func _shot_flight() -> void:
	_reset_dragon(Vector3.ZERO, 30.0)
	_set_zoom(13.0, Vector3(0.0, 3.6, 0.0), 45.0, 0.0)
	var imgs: Array[Image] = []
	await _wait(0.6)
	await _until_phase(0.02)
	imgs.append(_grab())
	await _until_phase(0.45)
	imgs.append(_grab())
	_dragon.call(&"set_moving", SPEED)
	await _wait(1.2)
	await _until_phase(0.25)
	imgs.append(_grab())
	var guard := 0
	while float(_dragon.get(&"_flap_amp_w")) > 0.01 and guard < 900:
		await get_tree().process_frame
		guard += 1
	await _wait(0.3)
	imgs.append(_grab())
	_turning = true
	await _wait(1.3)
	imgs.append(_grab())
	_turning = false
	_dragon.call(&"set_moving", 0.0)
	await _wait(1.2)
	_dragon.call(&"play_attack")
	await _wait(0.55)
	imgs.append(_grab())
	await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "flight")


## Close-ups: head 3/4 front, head side, full side, from above-behind, from below (membranes against the sky), top.
func _shot_close() -> void:
	_reset_dragon(Vector3.ZERO, 0.0)
	_dragon.call(&"set_moving", SPEED)
	await _wait(1.0)
	_dragon.set(&"_gliding", true)
	_dragon.set(&"_glide_left", 999.0)
	await _wait(0.8)
	var imgs: Array[Image] = []
	for v: Array in [[3.4, Vector3(0.0, 5.2, 2.4), 12.0, 38.0], [3.4, Vector3(0.0, 5.2, 2.2), 5.0, 90.0],
			[11.0, Vector3(0.0, 4.4, -0.5), 8.0, 90.0], [10.0, Vector3(0.0, 4.4, -0.3), 35.0, 160.0],
			[9.0, Vector3(0.0, 4.6, 0.0), -30.0, 20.0], [11.0, Vector3(0.0, 4.2, -0.4), 80.0, 0.0]]:
		_set_zoom(v[0], v[1], v[2], v[3])
		await _wait(0.25)
		imgs.append(_grab())
	_dragon.set(&"_glide_left", 0.0)
	_dragon.call(&"set_moving", 0.0)
	_sheet(imgs, 3, PREFIX + "close")


## The breath: side view and front 3/4, at 0.2 (rear), 0.45, 0.7 s (jaw open, the throat glow flared).
func _shot_breath() -> void:
	_reset_dragon(Vector3.ZERO, 0.0)
	var imgs: Array[Image] = []
	for view: int in 2:
		if view == 0:
			_set_zoom(9.0, Vector3(0.0, 4.2, 1.2), 8.0, 90.0)
		else:
			_set_zoom(6.0, Vector3(0.0, 4.4, 2.6), 14.0, 35.0)
		await _wait(1.0)
		_dragon.call(&"play_attack")
		for t: float in [0.2, 0.45, 0.7]:
			await _until(_dragon, &"_action_t", t)
			imgs.append(_grab())
		await _wait(1.2)
	_sheet(imgs, 3, PREFIX + "breath")


## Death: throe, spiral fall, crash, glow out, sinking (side 3/4 view from 14 m).
func _shot_death() -> void:
	_reset_dragon(Vector3.ZERO, 20.0)
	_dragon.call(&"set_moving", SPEED)
	_set_zoom(14.0, Vector3(0.0, 2.2, 0.0), 26.0, 30.0)
	await _wait(1.0)
	var imgs: Array[Image] = []
	_dragon.call(&"play_death")
	for t: float in [0.2, 0.55, 0.85, 1.14, 1.35, 1.65]:
		await _until(_dragon, &"_death_t", t)
		imgs.append(_grab())
	await _wait(0.6)
	_dragon.call(&"revive")
	_sheet(imgs, 3, PREFIX + "death")


## Black on white at 25 m and 40 m game camera: the Frost Dragon from 4 headings (one gliding) on the left, the Cinder
## Dragon from the same headings on the right, a Rimeshield and Torvald for scale.
func _shot_silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	_sun.shadow_enabled = false
	_dragon.get_parent().visible = false
	var yaws: Array[float] = [0.0, 90.0, 180.0, 35.0]
	for i: int in 4:
		_extra.append(_spawn(SCENE, Vector3(-16.0 + 8.5 * float(i), 0, -4.0), yaws[i], ICE))
	for i: int in 4:
		_extra.append(_spawn(CINDER, Vector3(-16.0 + 8.5 * float(i), 0, 7.0), yaws[i], FIRE))
	for u: Array in [[SHIELD, Vector3(19.0, 0, 1.5), 90.0], [TORVALD, Vector3(21.0, 0, 1.5), 0.0]]:
		if ResourceLoader.exists(u[0]):
			_extra.append(_spawn(u[0], u[1], u[2], ICE))
	await _wait(0.5)
	_extra[3].call(&"set_moving", SPEED)
	_extra[7].call(&"set_moving", 5.5)
	for m: Node3D in _extra:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(-1.0, 0.0, 1.5))
		await _wait(0.5)
		imgs.append(_grab())
	_sheet(imgs, 1, PREFIX + "silhouette", 1600, 900)
	_ground.material_override = old_ground
	_env.environment = old_env
	_sun.shadow_enabled = true
	_clear_extra()
	_dragon.get_parent().visible = true


## Side-on scale lineup on the ground line: the hovering dragon over a Rime Colossus, Torvald, a Rimeshield.
func _shot_scale() -> void:
	_reset_dragon(Vector3.ZERO, 90.0)
	for u: Array in [[COLOSSUS, Vector3(-1.8, 0, 3.0), 90.0], [TORVALD, Vector3(1.2, 0, 3.0), 90.0],
			[SHIELD, Vector3(2.8, 0, 3.0), 90.0]]:
		if ResourceLoader.exists(u[0]):
			_extra.append(_spawn(u[0], u[1], u[2], ICE))
	var imgs: Array[Image] = []
	_set_zoom(16.0, Vector3(0.0, 3.0, 1.0), 4.0, 0.0)
	await _wait(0.6)
	await _until_phase(0.45)
	imgs.append(_grab())
	_set_zoom(18.0, Vector3(0.0, 2.5, 1.0), 30.0, 30.0)
	await _wait(0.4)
	await _until_phase(0.02)
	imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "scale")
	_clear_extra()


## The four kingdom tints at 40 m (the membranes take the colour), two flying.
func _shot_teams() -> void:
	_dragon.get_parent().visible = false
	var cols: Array[Color] = [ICE, FIRE, SHADOW, NATURE]
	for i: int in 4:
		var d := _spawn(SCENE, Vector3(-13.5 + 9.0 * float(i), 0, 0), [20.0, 150.0, -40.0, 200.0][i], cols[i])
		_extra.append(d)
		if i % 2 == 1:
			d.call(&"set_moving", SPEED)
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.0))
	await _wait(1.0)
	var img := _grab()
	_crop(img, 0.62).save_png(OUT + PREFIX + "teams_z40.png")
	_clear_extra()
	_dragon.get_parent().visible = true


func _until_phase(p: float) -> void:
	var guard := 0
	while guard < 200:
		var fp := float(_dragon.get(&"_flap_p"))
		if absf(fp - p) < 0.03:
			return
		await get_tree().process_frame
		guard += 1


func _until(m: Object, prop: StringName, t: float) -> void:
	var guard := 0
	while float(m.get(prop)) < t and guard < 400:
		await get_tree().process_frame
		guard += 1


func _crop(img: Image, frac: float) -> Image:
	var w: int = int(float(img.get_width()) * frac)
	var h: int = int(float(img.get_height()) * frac)
	var c := img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))
	c.resize(img.get_width(), img.get_height(), Image.INTERPOLATE_BILINEAR)
	return c


func _sheet(imgs: Array[Image], cols: int, nm: String, w: int = 800, h: int = 450) -> void:
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
