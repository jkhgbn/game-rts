extends Node3D
## Frost Wyrm preview (task 13c.V8). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/neutral/beasts/frost_wyrm/tools/frost_wyrm_preview.tscn -- --shots
## writes docs/art/screens/13c_v8_*.png (the z40 game camera over the river, A / B at 40 m airborne and coiled, next to
## the Frost Dragon, airborne close-ups, the coil, the three casts, the breath, the death, black silhouettes beside the
## Frost Dragon) then quits. Add --only=<name> to render one sheet.
## Without --shots: keys 1-6 zoom 8 / 15 / 25 / 40 / 55 / head · W fly toggle · T turn toggle · G grounded toggle ·
## A breath · Q dive · E tail lash · Z blizzard · H hit · D death · R revive · V variant · Y turn 45 deg.

const SCENE := "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn"
const DRAGON := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13c_v8_"
const ICE := Color(0.55, 0.80, 0.95)
const FIRE := Color(0.85, 0.30, 0.12)
const SHIELD := "res://art/units/ice/rimeshield.tscn"
const CASTER := "res://art/units/ice/shardcaster.tscn"
const TORVALD := "res://art/units/wizards/torvald.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const ARCHER := "res://art/units/fire/ember_archer.tscn"
const SPEED := 5.5

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _water: MeshInstance3D
var _sun: DirectionalLight3D
var _wyrm: Node3D
var _extra: Array = []
var _flying: bool = false
var _turning: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	_cam.make_current()
	_wyrm = _spawn(SCENE, Vector3.ZERO, 30.0)
	_set_zoom(22.0, Vector3(0.0, 3.0, -1.0), 30.0, 20.0)
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		var only := ""
		for a: String in args:
			if a.begins_with("--only="):
				only = a.substr(7)
		_take_shots(only)


func _process(delta: float) -> void:
	if _turning and is_instance_valid(_wyrm):
		_wyrm.get_parent().rotation.y += deg_to_rad(60.0) * delta


func _spawn(path: String, at: Vector3, yaw_deg: float, col: Color = Color(0, 0, 0, 0)) -> Node3D:
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
	# a plain painted-grass stand-in (as the Frost Dragon preview) and a river strip: the Wyrm lives over the water
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
	_water = MeshInstance3D.new()
	var wm := PlaneMesh.new()
	wm.size = Vector2(300, 6.0)
	_water.mesh = wm
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.16, 0.42, 0.46)
	water.roughness = 0.3
	water.metallic_specular = 0.6
	_water.material_override = water
	_water.position = Vector3(0.0, 0.015, 0.0)
	add_child(_water)


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
		KEY_1: _set_zoom(8.0, Vector3(0.0, 4.5, 2.0), 20.0, 30.0)
		KEY_2: _set_zoom(15.0, Vector3(0.0, 3.0, -1.0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_6: _set_zoom(4.5, Vector3(0.0, 4.6, 4.2), 12.0, 40.0)
		KEY_A: _wyrm.call(&"play_attack")
		KEY_Q: _wyrm.call(&"play_cast", &"glacial_dive")
		KEY_E: _wyrm.call(&"play_cast", &"tail_lash")
		KEY_Z: _wyrm.call(&"play_cast", &"blizzard")
		KEY_H: _wyrm.call(&"play_hit")
		KEY_D: _wyrm.call(&"play_death")
		KEY_R: _wyrm.call(&"revive")
		KEY_V: _wyrm.call(&"set_variant", 1 - int(_wyrm.call(&"get_variant")))
		KEY_G: _wyrm.call(&"set_grounded", not bool(_wyrm.call(&"is_grounded")))
		KEY_Y: _wyrm.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_T: _turning = not _turning
		KEY_W:
			_flying = not _flying
			_wyrm.call(&"set_moving", SPEED if _flying else 0.0)


# ---------------------------------------------------------------- screenshots

func _take_shots(only: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	var sheets: Array[String] = ["z40", "ab40", "duo", "air", "coil", "casts", "breath", "death", "silhouette"]
	for s: String in sheets:
		if only != "" and only != s:
			continue
		match s:
			"z40": await _shot_z40()
			"ab40": await _shot_ab40()
			"duo": await _shot_duo()
			"air": await _shot_air()
			"coil": await _shot_coil()
			"casts": await _shot_casts()
			"breath": await _shot_breath()
			"death": await _shot_death()
			"silhouette": await _shot_silhouette()
	print("FROST WYRM SHOTS DONE")
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


func _reset(at: Vector3 = Vector3.ZERO, yaw: float = 30.0, grounded: bool = false, variant: int = 0) -> void:
	_wyrm.call(&"revive")
	_wyrm.call(&"set_variant", variant)
	_wyrm.call(&"set_moving", 0.0)
	_wyrm.call(&"set_grounded", grounded)
	_wyrm.set(&"_g", 1.0 if grounded else 0.0)
	_place(_wyrm, at, yaw)
	_wyrm.get_parent().visible = true
	_water.visible = true


func _units(list: Array) -> void:
	for u: Array in list:
		if ResourceLoader.exists(u[0]):
			_extra.append(_spawn(u[0], u[1], u[2], u[3]))


## The in-game read: game camera 40 m (pitch 55) over the river strip: the Rimescale Wyrm flying and turning over the
## water, Old Hoarfang coiled on the bank, a small Fire army and an Ice squad on both banks for scale.
func _shot_z40() -> void:
	_reset(Vector3(-4.0, 0, 0.0), 70.0)
	_wyrm.call(&"set_moving", SPEED)
	var b := _spawn(SCENE, Vector3(9.0, 0, 5.0), -120.0)
	_extra.append(b)
	b.call(&"set_variant", 1)
	b.call(&"set_grounded", true)
	b.set(&"_g", 1.0)
	_units([[GUARD, Vector3(2.0, 0, 9.0), 180.0, FIRE], [GUARD, Vector3(3.2, 0, 9.4), 180.0, FIRE],
		[GUARD, Vector3(4.4, 0, 9.0), 180.0, FIRE], [ARCHER, Vector3(1.0, 0, 11.0), 180.0, FIRE],
		[ARCHER, Vector3(2.4, 0, 11.3), 180.0, FIRE], [ARCHER, Vector3(3.8, 0, 11.0), 180.0, FIRE],
		[SHIELD, Vector3(-6.0, 0, -6.5), 0.0, ICE], [SHIELD, Vector3(-4.8, 0, -6.8), 0.0, ICE],
		[CASTER, Vector3(-3.4, 0, -7.5), 0.0, ICE], [TORVALD, Vector3(-5.2, 0, -8.5), 0.0, ICE]])
	_set_zoom(40.0, Vector3(1.0, 0.0, 1.5))
	for k: int in 40:
		_wyrm.get_parent().rotation.y += deg_to_rad(1.2)
		await get_tree().process_frame
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 0.5).save_png(OUT + PREFIX + "z40.png")
	_clear_extra()


## A (Rimescale) and B (Old Hoarfang) side by side at the 40 m game camera: hovering, then both coiled. 2x crops.
func _shot_ab40() -> void:
	var imgs: Array[Image] = []
	for grounded: bool in [false, true]:
		_reset(Vector3(-6.0, 0, 0.0), 20.0, grounded, 0)
		var b := _spawn(SCENE, Vector3(7.0, 0, 0.0), -20.0)
		_extra.append(b)
		b.call(&"set_variant", 1)
		b.call(&"set_grounded", grounded)
		b.set(&"_g", 1.0 if grounded else 0.0)
		_set_zoom(40.0, Vector3(0.5, 0.0, -0.5))
		await _wait(1.0)
		imgs.append(_crop(_grab(), 0.55))
		_clear_extra()
	_sheet(imgs, 2, PREFIX + "ab40", 1200, 675)


## Next to the Frost Dragon: 40 m game camera (both hovering, one wyrm flying, one dragon flying; 2x crop) and 18 m.
func _shot_duo() -> void:
	_reset(Vector3(-6.0, 0, 2.0), 25.0)
	var d1 := _spawn(DRAGON, Vector3(6.0, 0, 2.0), -25.0, ICE)
	var w2 := _spawn(SCENE, Vector3(-6.0, 0, -9.0), 80.0)
	var d2 := _spawn(DRAGON, Vector3(7.0, 0, -9.0), -80.0, ICE)
	_extra.append_array([d1, w2, d2])
	w2.call(&"set_moving", SPEED)
	d2.call(&"set_moving", 5.0)
	_set_zoom(40.0, Vector3(0.0, 0.0, -2.0))
	await _wait(1.5)
	var imgs: Array[Image] = []
	var img := _grab()
	img.save_png(OUT + PREFIX + "duo_z40_full.png")
	imgs.append(_crop(img, 0.6))
	_clear_extra()
	_reset(Vector3(-5.0, 0, 0.0), 35.0)
	var d3 := _spawn(DRAGON, Vector3(6.0, 0, 0.0), 35.0, ICE)
	_extra.append(d3)
	_set_zoom(24.0, Vector3(0.5, 3.4, -1.0), 28.0, 10.0)
	await _wait(1.2)
	imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "duo", 1200, 675)
	_clear_extra()


## Airborne close-ups, 3 x 2: hover 3/4 front, side, from above, flying (3/4 back), the head (frill crest), the tail fluke.
func _shot_air() -> void:
	_reset(Vector3.ZERO, 0.0)
	await _wait(0.6)
	var imgs: Array[Image] = []
	for v: Array in [[17.0, Vector3(0.0, 3.6, -1.5), 22.0, 35.0], [17.0, Vector3(0.0, 3.6, -1.5), 4.0, 90.0],
			[19.0, Vector3(0.0, 3.0, -2.0), 78.0, 0.0]]:
		_set_zoom(v[0], v[1], v[2], v[3])
		await _wait(0.4)
		imgs.append(_grab())
	_wyrm.call(&"set_moving", SPEED)
	await _wait(1.2)
	_set_zoom(16.0, Vector3(0.0, 3.6, -2.0), 30.0, 150.0)
	await _wait(0.3)
	imgs.append(_grab())
	_wyrm.call(&"set_moving", 0.0)
	await _wait(1.2)
	var hp: Vector3 = _wyrm.call(&"get_head_point")
	_set_zoom(4.6, hp + Vector3(0.0, 0.25, 0.6), 14.0, 38.0)
	await _wait(0.3)
	imgs.append(_grab())
	var tp: Vector3 = _wyrm.call(&"get_tail_tip")
	_set_zoom(5.0, tp + Vector3(0.0, 0.2, 0.6), 38.0, 150.0)
	await _wait(0.05)
	imgs.append(_grab())
	_sheet(imgs, 3, PREFIX + "air")


## The coil, 3 x 2: 3/4 view, from above, low side, the head held low, the landing blend at 0.4 s, Old Hoarfang coiled.
func _shot_coil() -> void:
	_reset(Vector3.ZERO, 0.0, true)
	_water.visible = false
	await _wait(0.6)
	var imgs: Array[Image] = []
	for v: Array in [[12.0, Vector3(0.0, 0.8, 0.0), 32.0, 30.0], [13.0, Vector3(0.0, 0.5, 0.0), 80.0, 0.0],
			[11.0, Vector3(0.0, 1.0, 0.0), 6.0, 60.0]]:
		_set_zoom(v[0], v[1], v[2], v[3])
		await _wait(0.4)
		imgs.append(_grab())
	var hp: Vector3 = _wyrm.call(&"get_head_point")
	_set_zoom(4.8, hp + Vector3(0.0, 0.0, 0.6), 10.0, 20.0)
	await _wait(0.3)
	imgs.append(_grab())
	_reset(Vector3.ZERO, 0.0, false)
	await _wait(0.8)
	_wyrm.call(&"set_grounded", true)
	_set_zoom(16.0, Vector3(0.0, 1.8, 0.0), 24.0, 40.0)
	await _until(_wyrm, &"_g", 0.5)
	imgs.append(_grab())
	_reset(Vector3.ZERO, 0.0, true, 1)
	_set_zoom(13.0, Vector3(0.0, 0.9, 0.0), 30.0, -35.0)
	await _wait(0.8)
	imgs.append(_grab())
	_sheet(imgs, 3, PREFIX + "coil")
	_wyrm.call(&"set_variant", 0)


## The three casts, one per row (side 3/4 at ~17 m): Glacial Dive (climb 0.3, plunge 0.75, impact 1.0, coiled 1.45),
## Tail Lash from the coil (windup 0.2, strike 0.35, follow 0.5, recover 0.75), Blizzard (rear 0.4, roar 0.75, 1.05,
## 1.45).
func _shot_casts() -> void:
	var imgs: Array[Image] = []
	_reset(Vector3.ZERO, 0.0)
	_set_zoom(17.0, Vector3(0.0, 1.2, 1.5), 12.0, 70.0)
	await _wait(1.0)
	_wyrm.call(&"play_cast", &"glacial_dive")
	for t: float in [0.3, 0.75, 1.0, 1.45]:
		await _until(_wyrm, &"_action_t", t)
		imgs.append(_grab())
	_reset(Vector3.ZERO, 0.0, true)
	_set_zoom(15.0, Vector3(0.0, 0.8, -0.5), 42.0, 20.0)
	await _wait(0.8)
	_wyrm.call(&"play_cast", &"tail_lash")
	for t: float in [0.2, 0.35, 0.5, 0.75]:
		await _until(_wyrm, &"_action_t", t)
		imgs.append(_grab())
	await _wait(0.6)
	_reset(Vector3.ZERO, 0.0)
	_set_zoom(14.0, Vector3(0.0, 3.0, 1.0), 10.0, 60.0)
	await _wait(1.0)
	_wyrm.call(&"play_cast", &"blizzard")
	for t: float in [0.4, 0.75, 1.05, 1.45]:
		await _until(_wyrm, &"_action_t", t)
		imgs.append(_grab())
	await _wait(0.6)
	_sheet(imgs, 4, PREFIX + "casts")


## The Rime Breath, side and 3/4 front: rear 0.2, strike 0.45, sweep 0.7.
func _shot_breath() -> void:
	_reset(Vector3.ZERO, 0.0)
	var imgs: Array[Image] = []
	for view: int in 2:
		if view == 0:
			_set_zoom(10.0, Vector3(0.0, 4.3, 3.0), 6.0, 90.0)
		else:
			_set_zoom(7.5, Vector3(0.0, 4.4, 4.0), 12.0, 30.0)
		await _wait(1.0)
		_wyrm.call(&"play_attack")
		for t: float in [0.2, 0.45, 0.7]:
			await _until(_wyrm, &"_action_t", t)
			imgs.append(_grab())
		await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "breath")


## Death from the air: throe, fall, crash, the glow out, sinking (3/4 view from 18 m).
func _shot_death() -> void:
	_reset(Vector3.ZERO, 20.0)
	_wyrm.call(&"set_moving", SPEED)
	_set_zoom(18.0, Vector3(0.0, 1.8, -1.0), 26.0, 40.0)
	await _wait(1.0)
	var imgs: Array[Image] = []
	_wyrm.call(&"play_death")
	for t: float in [0.2, 0.55, 0.85, 1.0, 1.3, 1.65]:
		await _until(_wyrm, &"_death_t", t)
		imgs.append(_grab())
	await _wait(0.5)
	_wyrm.call(&"revive")
	_sheet(imgs, 3, PREFIX + "death")


## Black on white at 25 m and 40 m game camera: the Frost Wyrm from 3 headings airborne (one flying) + one coiled on
## the top row, the Frost Dragon from the same headings (one flying, one hovering) on the bottom row, a Rimeshield and
## Torvald for scale.
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
	_water.visible = false
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	_sun.shadow_enabled = false
	_wyrm.get_parent().visible = false
	var yaws: Array[float] = [0.0, 90.0, 35.0, 0.0]
	for i: int in 4:
		var w := _spawn(SCENE, Vector3(-20.0 + 13.0 * float(i), 0, -7.0), yaws[i])
		_extra.append(w)
		if i == 3:
			w.call(&"set_grounded", true)
			w.set(&"_g", 1.0)
	for i: int in 4:
		_extra.append(_spawn(DRAGON, Vector3(-20.0 + 13.0 * float(i), 0, 9.0), yaws[i], ICE))
	_units([[SHIELD, Vector3(21.0, 0, 1.5), 90.0, ICE], [TORVALD, Vector3(23.0, 0, 1.5), 0.0, ICE]])
	await _wait(0.5)
	_extra[1].call(&"set_moving", SPEED)
	_extra[5].call(&"set_moving", 5.0)
	for m: Node3D in _extra:
		for g: Node in m.get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 1.0))
		await _wait(0.5)
		imgs.append(_grab())
	_sheet(imgs, 1, PREFIX + "silhouette", 1600, 900)
	_ground.material_override = old_ground
	_env.environment = old_env
	_sun.shadow_enabled = true
	_clear_extra()
	_wyrm.get_parent().visible = true


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
