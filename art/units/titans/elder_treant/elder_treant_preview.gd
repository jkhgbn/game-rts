extends Node3D
## Elder Treant preview (task 13.V18). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/titans/elder_treant/elder_treant_preview.tscn -- --shots
## writes docs/art/screens/13_v18_*.png (close-ups, walk, root morph frames, volley + slam, 40 m game camera with
## Nature units, black silhouette next to the Hollow Stag and the Gloomcap, side lineup, death) then quits.
## Add --only=<name> to render one sheet. Without --shots: keys 1-6 zoom · W walk · V root / uproot · A attack /
## volley · H hit · D death · R revive · G regen · Y turn 45 deg · C next kingdom colour.

const SCENE := "res://art/units/titans/elder_treant/elder_treant.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "13_v18_"
const NATURE := Color(0.35, 0.70, 0.25)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const THORN := "res://art/units/nature/thornling.tscn"
const SLINGER := "res://art/units/nature/burr_slinger.tscn"
const BLOOM := "res://art/units/nature/bloomtender.tscn"
const BRAMBLE := "res://art/units/nature/bramblehorn.tscn"
const SAPLING := "res://art/units/nature/sapling.tscn"
const YSOLDE := "res://art/units/wizards/ysolde.tscn"
const STAG := "res://art/units/neutral/hollow_stag/hollow_stag.tscn"
const GLOOM := "res://art/units/neutral/gloomcap/gloomcap_elder.tscn"

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _sun: DirectionalLight3D
var _tr: Node3D
var _extra: Array = []
var _walking: bool = false
var _col_i: int = 0
var _regen: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	_cam.make_current()
	_tr = _spawn(SCENE, Vector3.ZERO, 20.0, NATURE)
	_set_zoom(14.0, Vector3(0.0, 2.2, 0.0), 25.0, 25.0)
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		var only := ""
		for a: String in args:
			if a.begins_with("--only="):
				only = a.substr(7)
		_take_shots(only)


func _spawn(path: String, at: Vector3, yaw_deg: float, col: Color) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var m: Node3D = ps.instantiate()
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
	_ground.material_override = load("res://art/environment/ground_material.tres")
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
		KEY_1: _set_zoom(4.0, Vector3(0.0, 3.2, 0.3), 10.0, 20.0)
		KEY_2: _set_zoom(14.0, Vector3(0.0, 2.2, 0.0), 25.0, 25.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_6: _set_zoom(10.0, Vector3(0.0, 2.0, 0.0), 10.0, 90.0)
		KEY_A: _tr.call(&"play_attack")
		KEY_H: _tr.call(&"play_hit")
		KEY_D: _tr.call(&"play_death")
		KEY_R: _tr.call(&"revive")
		KEY_V: _tr.call(&"set_rooted", not bool(_tr.call(&"is_rooted")) and float(_tr.call(&"root_progress")) < 0.5)
		KEY_G:
			_regen = not _regen
			_tr.call(&"set_regen", _regen)
		KEY_Y: _tr.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_C:
			_col_i = (_col_i + 1) % 4
			_tr.call(&"set_team_color", [NATURE, FIRE, SHADOW, ICE][_col_i])
		KEY_W:
			_walking = not _walking
			_tr.call(&"set_moving", 3.8 if _walking else 0.0)


# ---------------------------------------------------------------- screenshots

func _take_shots(only: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	var sheets: Array[String] = ["close", "walk", "morph", "volley", "z40", "silhouette", "lineup", "death"]
	for s: String in sheets:
		if only != "" and only != s:
			continue
		match s:
			"close": await _shot_close()
			"walk": await _shot_walk()
			"morph": await _shot_morph()
			"volley": await _shot_volley()
			"z40": await _shot_z40()
			"silhouette": await _shot_silhouette()
			"lineup": await _shot_lineup()
			"death": await _shot_death()
	print("ELDER TREANT SHOTS DONE")
	get_tree().quit()


func _clear_extra() -> void:
	for m: Variant in _extra:
		if m != null and is_instance_valid(m):
			(m as Node3D).get_parent().queue_free()
	_extra.clear()


func _place(m: Node3D, at: Vector3, yaw_deg: float) -> void:
	var h: Node3D = m.get_parent()
	h.position = at
	h.rotation.y = deg_to_rad(yaw_deg)


func _reset(at: Vector3 = Vector3.ZERO, yaw: float = 20.0, rooted: bool = false) -> void:
	_tr.call(&"revive")
	_tr.call(&"set_moving", 0.0)
	_tr.call(&"set_regen", false)
	_tr.call(&"set_rooted", rooted, true)
	_place(_tr, at, yaw)
	_tr.get_parent().visible = true


## Close-ups: face 3/4, full front, side, back 3/4 (walking); rooted 3/4 front; rooted from the game angle.
func _shot_close() -> void:
	var imgs: Array[Image] = []
	_reset(Vector3.ZERO, 0.0)
	await _wait(0.5)
	for v: Array in [[3.4, Vector3(0.0, 3.15, 0.4), 8.0, 28.0], [9.5, Vector3(0.0, 2.2, 0.0), 8.0, 0.0],
			[9.5, Vector3(0.0, 2.2, 0.0), 8.0, 90.0], [9.5, Vector3(0.0, 2.2, 0.0), 18.0, 150.0]]:
		_set_zoom(v[0], v[1], v[2], v[3])
		await _wait(0.3)
		imgs.append(_grab())
	_reset(Vector3.ZERO, 0.0, true)
	await _wait(0.5)
	_set_zoom(11.0, Vector3(0.0, 2.4, 0.0), 12.0, 30.0)
	await _wait(0.3)
	imgs.append(_grab())
	_set_zoom(15.0, Vector3(0.0, 2.0, 0.0), 55.0, 0.0)
	await _wait(0.3)
	imgs.append(_grab())
	_sheet(imgs, 3, PREFIX + "close")
	_reset()


## Walk cycle: six frames over one stride, 3/4 side view.
func _shot_walk() -> void:
	_reset(Vector3.ZERO, 90.0)
	_set_zoom(11.0, Vector3(0.0, 2.0, 0.0), 12.0, 20.0)
	_tr.call(&"set_moving", 3.8)
	await _wait(1.0)
	var imgs: Array[Image] = []
	var period := float(_tr.get(&"stride_time"))
	for k: int in 6:
		await _until_walk(float(k) / 6.0)
		imgs.append(_grab())
	_tr.call(&"set_moving", 0.0)
	_sheet(imgs, 3, PREFIX + "walk")
	await _wait(period)


## The root morph: 0, 0.6, 1.2, 1.8, 2.4 s and rooted (3/4 front, 13 m), then the uproot midway and the heal glow.
func _shot_morph() -> void:
	_reset(Vector3.ZERO, 15.0)
	_set_zoom(13.0, Vector3(0.0, 2.2, 0.0), 16.0, 20.0)
	await _wait(0.8)
	var imgs: Array[Image] = []
	_tr.call(&"set_rooted", true)
	var t0 := Time.get_ticks_msec()
	for t: float in [0.0, 0.6, 1.2, 1.8, 2.4, 3.3]:
		while float(Time.get_ticks_msec() - t0) / 1000.0 < t:
			await get_tree().process_frame
		imgs.append(_grab())
	_sheet(imgs, 3, PREFIX + "root_morph")
	# heal glow: rooted (grove) at dusk-ish exposure from close, and the walking regen
	var imgs2: Array[Image] = []
	_set_zoom(7.5, Vector3(0.0, 2.6, 0.0), 10.0, 35.0)
	await _wait(0.6)
	imgs2.append(_grab())
	_tr.call(&"set_rooted", false)
	await _wait(1.5)
	imgs2.append(_grab())
	await _wait(2.0)
	_tr.call(&"set_regen", true)
	_set_zoom(7.5, Vector3(0.0, 2.4, 0.0), 10.0, 35.0)
	await _wait(0.8)
	imgs2.append(_grab())
	_tr.call(&"set_regen", false)
	_sheet(imgs2, 3, PREFIX + "heal_uproot")


## Rooted thorn volley (draw back 0.08, release 0.15, snap 0.3) and the walking slam (raise 0.08, strike 0.18, 0.4).
func _shot_volley() -> void:
	var imgs: Array[Image] = []
	_reset(Vector3.ZERO, 70.0, true)
	_set_zoom(12.0, Vector3(0.0, 2.6, 0.0), 12.0, 10.0)
	await _wait(0.8)
	_tr.call(&"play_volley")
	for t: float in [0.08, 0.15, 0.3]:
		await _until(_tr, &"_action_t", t)
		imgs.append(_grab())
	await _wait(1.2)
	_reset(Vector3.ZERO, 70.0)
	_set_zoom(10.0, Vector3(0.0, 2.2, 0.0), 12.0, 10.0)
	await _wait(0.8)
	_tr.call(&"play_attack")
	for t: float in [0.08, 0.18, 0.4]:
		await _until(_tr, &"_action_t", t)
		imgs.append(_grab())
	await _wait(1.0)
	_sheet(imgs, 3, PREFIX + "volley_slam")


## Game camera 40 m (pitch 55): a walking and a rooted Treant with a Nature army. Full frame + a 2x crop.
func _shot_z40() -> void:
	_reset(Vector3(-3.5, 0, 0.5), 20.0)
	var r2 := _spawn(SCENE, Vector3(4.5, 0, -1.0), -20.0, NATURE)
	_extra.append(r2)
	r2.call(&"set_rooted", true, true)
	var units: Array = [[THORN, Vector3(-1.0, 0, 5.0)], [THORN, Vector3(0.2, 0, 5.2)], [THORN, Vector3(1.4, 0, 5.0)],
		[THORN, Vector3(-0.4, 0, 6.2)], [SLINGER, Vector3(5.0, 0, 3.5)], [SLINGER, Vector3(6.2, 0, 3.7)],
		[BLOOM, Vector3(2.8, 0, 2.4)], [BRAMBLE, Vector3(-6.0, 0, 3.5)], [YSOLDE, Vector3(1.0, 0, 1.2)],
		[SAPLING, Vector3(3.2, 0, 0.8)]]
	for u: Array in units:
		var n := _spawn(u[0], u[1], 180.0 + randf_range(-20, 20), NATURE)
		if n:
			_extra.append(n)
	_tr.call(&"set_moving", 3.8)
	_set_zoom(40.0, Vector3(0.0, 0.0, 1.5))
	await _wait(1.2)
	var img := _grab()
	img.save_png(OUT + PREFIX + "z40_full.png")
	_crop(img, 0.5).save_png(OUT + PREFIX + "z40.png")
	_tr.call(&"set_moving", 0.0)
	_clear_extra()


## Black on white at 25 m and 40 m game camera: walking from 3 headings, rooted, the Hollow Stag and the Gloomcap
## elder (the neutral creatures it must not be confused with).
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
	_tr.get_parent().visible = false
	var yaws: Array[float] = [0.0, 90.0, 150.0, 20.0]
	for i: int in 4:
		var t := _spawn(SCENE, Vector3(-13.0 + 7.0 * float(i), 0, 0), yaws[i], NATURE)
		_extra.append(t)
		if i == 3:
			t.call(&"set_rooted", true, true)
	for u: Array in [[STAG, Vector3(14.0, 0, -0.5), 60.0], [GLOOM, Vector3(18.5, 0, 0.5), 20.0]]:
		var n := _spawn(u[0], u[1], u[2], Color(0, 0, 0, 0))
		if n:
			_extra.append(n)
	await _wait(0.6)
	for m: Variant in _extra:
		if m == null:
			continue
		for g: Node in (m as Node3D).get_parent().find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	var n_black := 0
	for m: Variant in _extra:
		if m != null:
			n_black += (m as Node3D).get_parent().find_children("*", "GeometryInstance3D", true, false).size()
	print("silhouette: %d models, %d geometry nodes" % [_extra.size(), n_black])
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(2.0, 0.0, 0.0))
		await _wait(0.4)
		print("silhouette cam ", _cam.global_position)
		imgs.append(_grab())
	_sheet(imgs, 1, PREFIX + "silhouette", 1600, 900)
	_ground.material_override = old_ground
	_env.environment = old_env
	_sun.shadow_enabled = true
	_clear_extra()
	_tr.get_parent().visible = true


## Side-on lineup on the ground line: walking and rooted Treant next to Ysolde, a Bramblehorn, a Thornling, a
## Burr Slinger, a Bloomtender, a Sapling; then the same from the game angle at 25 m.
func _shot_lineup() -> void:
	_reset(Vector3(-2.5, 0, 0), 90.0)
	var r2 := _spawn(SCENE, Vector3(3.2, 0, 0), 90.0, NATURE)
	_extra.append(r2)
	r2.call(&"set_rooted", true, true)
	var xs := -9.5
	for u: String in [YSOLDE, BRAMBLE, THORN, SLINGER, BLOOM, SAPLING]:
		var n := _spawn(u, Vector3(xs, 0, 1.5), 90.0, NATURE)
		if n:
			_extra.append(n)
		xs += 1.3 if u != BRAMBLE else 1.8
	var imgs: Array[Image] = []
	_set_zoom(17.0, Vector3(-2.0, 2.0, 0.5), 3.0, 0.0)
	await _wait(0.8)
	imgs.append(_grab())
	_set_zoom(25.0, Vector3(-2.0, 0.0, 0.5), 55.0, 0.0)
	await _wait(0.4)
	imgs.append(_grab())
	_sheet(imgs, 2, PREFIX + "lineup")
	_clear_extra()


## Death: groan, topple, crash (glows out), sinking (3/4 side view).
func _shot_death() -> void:
	_reset(Vector3.ZERO, 70.0)
	_set_zoom(13.0, Vector3(0.0, 1.8, 1.0), 20.0, 10.0)
	await _wait(0.8)
	var imgs: Array[Image] = []
	_tr.call(&"play_death")
	for t: float in [0.25, 0.65, 0.95, 1.12, 1.35, 1.65]:
		await _until(_tr, &"_death_t", t)
		imgs.append(_grab())
	await _wait(0.5)
	_tr.call(&"revive")
	_sheet(imgs, 3, PREFIX + "death")


func _until_walk(p: float) -> void:
	var guard := 0
	while guard < 300:
		var wp := float(_tr.get(&"_walk_p"))
		if absf(wrapf(wp - p, -0.5, 0.5)) < 0.03:
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
