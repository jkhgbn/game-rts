extends Node3D
## 13b.V1 Cinderlock Musketeer preview (game camera pitch 55, fov 50, the world environment + sun of the game).
## Windowed, frame-exact:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/fire/cinderlock/tools/cinderlock_preview.tscn --fixed-fps 60 -- --shots
## Saves docs/art/screens/13b_v1_*.png and quits. --only=views,volley,reload,lineup,sil,ember,team (comma list).
## By hand (no --shots): 1 volley, 2 reload 4.2 s, 3 hit, 4 death, 5 walk, 6 loaded toggle, 7 level-up + vet 4, R reset.

const SCENE := "res://art/units/fire/cinderlock/cinderlock.tscn"
const FIRE_IDS: Array[String] = ["cinder_hand", "flame_guard", "ember_archer", "blaze_rider", "ash_hurler"]
const FIRE := Color(0.85, 0.30, 0.12)
const CENTER := Vector3(15, 0, 15)
const OUT := "res://docs/art/screens/13b_v1_%s.png"

var zoom: float = 10.0
var focus: Vector3 = CENTER + Vector3(0, 0.9, 0)
var only: PackedStringArray = PackedStringArray()
var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _sun: DirectionalLight3D
var _live: Array[Node3D] = []


func _ready() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.00, 0.93, 0.82)
	_sun.light_energy = 1.3
	_sun.rotation_degrees = Vector3(-50, 35, 0)
	_sun.shadow_enabled = true
	_sun.shadow_normal_bias = 2.0
	add_child(_sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7).split(",")
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()
	else:
		_spawn(SCENE, CENTER, 0.0)


func _want(s: String) -> bool:
	return only.is_empty() or only.has(s)


func _spawn(path: String, at: Vector3, yaw_deg: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	m.call(&"set_team_color", FIRE)
	_live.append(holder)
	return m


func _fire(i: int, at: Vector3, yaw_deg: float) -> Node3D:
	return _spawn("res://art/units/fire/%s.tscn" % FIRE_IDS[i], at, yaw_deg)


func _clear() -> void:
	for h: Node3D in _live:
		h.queue_free()
	_live.clear()


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


## Side / free camera: yaw around the focus (0 = the game view from +Z), pitch in degrees.
func _orbit(f: Vector3, dist: float, yaw_deg: float, pitch_deg: float) -> void:
	var p: float = deg_to_rad(pitch_deg)
	var y: float = deg_to_rad(yaw_deg)
	_cam.position = f + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	_cam.look_at(f, Vector3.UP)


func _look(f: Vector3, z: float) -> void:
	focus = f
	zoom = z
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 1.0, 3.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 1.0, 3.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		for h: Node3D in _live:
			var m: Node3D = h.get_child(0)
			match k.physical_keycode:
				KEY_1: m.call(&"play_attack")
				KEY_2: m.call(&"play_reload", 4.2)
				KEY_3: m.call(&"play_hit")
				KEY_4: m.call(&"play_death")
				KEY_5: m.call(&"set_moving", 0.0 if m.get(&"_speed") > 0.0 else 4.6)
				KEY_6: m.call(&"set_loaded", not m.call(&"is_loaded"))
				KEY_7:
					m.call(&"play_level_up")
					m.call(&"set_veterancy", 4)
		if k.physical_keycode == KEY_R:
			_clear()
			_spawn(SCENE, CENTER, 0.0)


# ---------------------------------------------------------------- capture

func _grab() -> Image:
	return get_viewport().get_texture().get_image()


func _save(name: String, img: Image = null) -> void:
	if img == null:
		img = _grab()
	var path: String = OUT % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, "  draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


## Grid of images (cols x rows, each scaled to cell w x h).
func _sheet(imgs: Array[Image], cols: int, cw: int, ch: int) -> Image:
	var rows: int = ceili(float(imgs.size()) / cols)
	var out := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i].duplicate()
		im.convert(Image.FORMAT_RGBA8)
		im.resize(cw, ch, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	return out


## Crop the centre of the viewport (w x h) around a screen point.
func _crop(img: Image, c: Vector2, w: int, h: int) -> Image:
	var x: int = clampi(int(c.x) - w / 2, 0, img.get_width() - w)
	var y: int = clampi(int(c.y) - h / 2, 0, img.get_height() - h)
	return img.get_region(Rect2i(x, y, w, h))


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _frames(20)
	if _want("views"):
		await _shot_views()
	if _want("volley"):
		await _shot_volley()
	if _want("reload"):
		await _shot_reload()
	if _want("ember"):
		await _shot_ember()
	if _want("lineup"):
		await _shot_lineup()
	if _want("team"):
		await _shot_team()
	if _want("sil"):
		await _shot_silhouette()
	print("CINDERLOCK SHOTS DONE")
	get_tree().quit()


## Close-ups at the game pitch (front, 3/4, side, back) + a low hero angle, and a 2 x 3 sheet.
func _shot_views() -> void:
	var m: Node3D = _spawn(SCENE, CENTER, 0.0)
	var h: Node3D = m.get_parent()
	await _frames(20)
	var imgs: Array[Image] = []
	var names: Array[String] = ["front", "3q", "side", "back", "3q_back"]
	var yaws: Array[float] = [0.0, -45.0, -90.0, 180.0, 135.0]
	for i: int in yaws.size():
		h.rotation.y = deg_to_rad(yaws[i])
		_look(CENTER + Vector3(0, 1.0, 0), 4.2)
		await _frames(3)
		var img := _grab()
		_save("view_" + names[i], img)
		imgs.append(img)
	h.rotation.y = deg_to_rad(-30.0)
	_orbit(CENTER + Vector3(0, 1.05, 0), 3.6, 0.0, 12.0)
	await _frames(3)
	var hero := _grab()
	_save("view_hero", hero)
	imgs.append(hero)
	_save("views", _sheet(imgs, 3, 800, 450))
	_clear()
	await _frames(2)


## Volley timeline, side view (profile, gun toward the right of the frame): 8 frozen copies in a row, then the same
## at the game pitch; and a line of 6 firing together.
func _shot_volley() -> void:
	var frames: Array[int] = [0, 5, 9, 11, 13, 20, 33, 44]   # 0, 0.08, 0.15 (shot), 0.18 (kick), 0.22, 0.33, 0.55, 0.73 s
	var ms: Array[Node3D] = []
	for c: int in frames.size():
		ms.append(_spawn(SCENE, CENTER + Vector3((c - 3.5) * 1.9, 0, 0), 90.0))
	await _frames(15)
	for m: Node3D in ms:
		m.call(&"play_attack")
	var f: int = 0
	for c: int in frames.size():
		while f < frames[c]:
			await get_tree().process_frame
			f += 1
		ms[c].process_mode = Node.PROCESS_MODE_DISABLED
	_orbit(CENTER + Vector3(0, 1.0, 0), 13.5, 0.0, 8.0)
	await _frames(3)
	_save("volley")
	_look(CENTER + Vector3(0, 0.9, 0), 13.0)
	await _frames(3)
	_save("volley_game_cam")
	# Close-up on the shot and the kick frames.
	_orbit(ms[2].global_position + Vector3(0.9, 1.2, 0), 4.2, 0.0, 10.0)
	await _frames(3)
	var a := _grab()
	_orbit(ms[3].global_position + Vector3(0.9, 1.2, 0), 4.2, 0.0, 10.0)
	await _frames(3)
	var b := _grab()
	_save("volley_close", _sheet([a, b] as Array[Image], 2, 800, 450))
	_clear()
	await _frames(2)
	# Line of 6 facing up-screen (away from the camera, toward the enemy), all fire at once.
	var line: Array[Node3D] = []
	for i: int in 6:
		line.append(_spawn(SCENE, CENTER + Vector3((i - 2.5) * 1.3, 0, 0), 180.0))
	_look(CENTER + Vector3(0, 0.8, 0), 14.0)
	await _frames(20)
	_save("volley_line_ready")
	for m: Node3D in line:
		m.call(&"play_attack")
	await _frames(10)
	_save("volley_line_fire")
	_clear()
	await _frames(2)


## Reload (4.2 s): profile row of frozen copies across the loop + a close-up of a ramrod stroke from the game pitch.
func _shot_reload() -> void:
	var frames: Array[int] = [0, 8, 17, 40, 56, 72, 90, 150, 238, 252]   # s x 60
	var ms: Array[Node3D] = []
	for c: int in frames.size():
		ms.append(_spawn(SCENE, CENTER + Vector3((c - 4.5) * 1.9, 0, 0), 60.0))
	await _frames(15)
	for m: Node3D in ms:
		m.call(&"play_reload", 4.2)
	var f: int = 0
	for c: int in frames.size():
		while f < frames[c]:
			await get_tree().process_frame
			f += 1
		ms[c].process_mode = Node.PROCESS_MODE_DISABLED
	_orbit(CENTER + Vector3(0, 1.0, 0), 16.5, 0.0, 10.0)
	await _frames(3)
	_save("reload")
	_look(CENTER + Vector3(0, 0.9, 0), 16.0)
	await _frames(3)
	_save("reload_game_cam")
	_clear()
	await _frames(2)
	var m: Node3D = _spawn(SCENE, CENTER, -20.0)
	await _frames(10)
	m.call(&"play_reload", 4.2)
	var imgs: Array[Image] = []
	_orbit(CENTER + Vector3(0.2, 0.9, 0), 3.6, 25.0, 18.0)
	var f2: int = 0
	for k: int in [12, 30, 44, 58]:   # swing in, rod low, rod high, rod low
		await _frames(k - f2)
		f2 = k
		imgs.append(_grab())
	_save("reload_close", _sheet(imgs, 2, 800, 450))
	_clear()
	await _frames(2)


## Ember: loaded vs empty vs the shot flare, close.
func _shot_ember() -> void:
	var a: Node3D = _spawn(SCENE, CENTER + Vector3(-1.2, 0, 0), -15.0)
	var b: Node3D = _spawn(SCENE, CENTER + Vector3(1.2, 0, 0), -15.0)
	b.call(&"set_loaded", false)
	_look(CENTER + Vector3(0, 1.0, 0), 5.5)
	await _frames(20)
	_save("ember_loaded_vs_empty")
	_clear()
	await _frames(2)


## 40 m lineups: the Cinderlock among the five Fire units (game camera 40 and 20), a mixed army block at 40.
func _shot_lineup() -> void:
	for i: int in FIRE_IDS.size():
		_fire(i, CENTER + Vector3((i - 2.5) * 2.6, 0, 0), 0.0)
	_spawn(SCENE, CENTER + Vector3(2.5 * 2.6, 0, 0), 0.0)
	_look(CENTER + Vector3(0, 0.8, 0), 12.0)
	await _frames(30)
	_save("lineup_z12")
	_look(CENTER + Vector3(0, 0.8, 0), 20.0)
	await _frames(5)
	_save("lineup_z20")
	_look(CENTER + Vector3(0, 0.8, 0), 40.0)
	await _frames(5)
	var img := _grab()
	_save("lineup_z40", img)
	var vp := get_viewport().get_visible_rect().size
	var cr := _crop(img, vp * 0.5, 480, 270)
	cr.resize(1440, 810, Image.INTERPOLATE_NEAREST)
	_save("lineup_z40_zoomed", cr)
	_clear()
	await _frames(2)
	# Mixed army at 40 m: 8 Cinderlocks (front rank), 6 Flame Guards, 5 Ember Archers, 2 Blaze Riders, walking up-screen.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k: int in 8:
		var m := _spawn(SCENE, CENTER + Vector3(-5.0 + k * 1.3 + rng.randf_range(-0.2, 0.2), 0, -1.5), 180.0)
		if k % 2 == 0:
			m.call(&"set_moving", 4.6)
	for k: int in 6:
		_fire(1, CENTER + Vector3(-4.0 + k * 1.6, 0, 0.8), 180.0)
	for k: int in 5:
		_fire(2, CENTER + Vector3(-4.0 + k * 2.0, 0, 3.0), 180.0)
	for k: int in 2:
		_fire(3, CENTER + Vector3(-6.5 + k * 13.0, 0, 1.5), 180.0)
	_look(CENTER + Vector3(0, 0.5, 0.5), 40.0)
	await _frames(40)
	var army := _grab()
	_save("army_z40", army)
	var ac := _crop(army, vp * 0.5, 640, 360)
	ac.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	_save("army_z40_zoomed", ac)
	_look(CENTER + Vector3(0, 0.5, 0.5), 25.0)
	await _frames(5)
	_save("army_z25")
	_clear()
	await _frames(2)


## Mirror match: another kingdom colour recolours only the team cloth (plume, sash, collar, band); veteran 4.
func _shot_team() -> void:
	var a := _spawn(SCENE, CENTER + Vector3(-1.1, 0, 0), -20.0)
	var b := _spawn(SCENE, CENTER + Vector3(1.1, 0, 0), -20.0)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	b.call(&"set_veterancy", 4)
	a.call(&"set_veterancy", 4)
	_look(CENTER + Vector3(0, 1.0, 0), 6.0)
	await _frames(20)
	_save("team_vet4")
	_clear()
	await _frames(2)


## Black silhouettes on white: the Cinderlock (highlighted column) among the Fire units at 40 m and 18 m, 3 facings.
func _shot_silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	_sun.visible = false
	var env0: Environment = _env.environment
	_env.environment = Environment.new()
	var yaws: Array[float] = [0.0, -60.0, 180.0]
	for k: int in yaws.size():
		for i: int in FIRE_IDS.size():
			_fire(i, CENTER + Vector3((i - 2.5) * 2.8, 0, -3.0 + k * 3.0), yaws[k])
		_spawn(SCENE, CENTER + Vector3(2.5 * 2.8, 0, -3.0 + k * 3.0), yaws[k])
	await _frames(5)
	for h: Node3D in _live:
		_blacken(h, black)
	_look(CENTER + Vector3(0, 0.6, 0), 40.0)
	await _frames(20)
	var img := _grab()
	_save("silhouette_z40", img)
	var vp := get_viewport().get_visible_rect().size
	var cr := _crop(img, vp * 0.5, 480, 270)
	cr.resize(1440, 810, Image.INTERPOLATE_NEAREST)
	_save("silhouette_z40_zoomed", cr)
	_look(CENTER + Vector3(0, 0.6, 0), 18.0)
	await _frames(5)
	_save("silhouette_z18")
	_clear()
	# Firing pose silhouettes (shot frame) and reload, beside the archer.
	var ms: Array[Node3D] = []
	for k: int in 3:
		ms.append(_spawn(SCENE, CENTER + Vector3(-3.0 + k * 3.0, 0, 0), [0.0, 180.0, -90.0][k]))
	var ea := _fire(2, CENTER + Vector3(6.0, 0, 0), 0.0)
	var rl := _spawn(SCENE, CENTER + Vector3(-6.0, 0, 0), 0.0)
	await _frames(5)
	for h: Node3D in _live:
		_blacken(h, black)
	for m: Node3D in ms:
		m.call(&"play_attack")
	ea.call(&"play_attack")
	rl.call(&"play_reload", 4.2)
	await _frames(10)
	for h: Node3D in _live:
		(h.get_child(0) as Node).process_mode = Node.PROCESS_MODE_DISABLED
	_look(CENTER + Vector3(0, 0.8, 0), 18.0)
	await _frames(3)
	_save("silhouette_actions_z18")
	_clear()
	_env.environment = env0
	_sun.visible = true
	_ground.material_override = load("res://art/environment/ground_material.tres")
	await _frames(2)


func _blacken(n: Node, mat: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D or c.name == "Shadow":
			(c as Node3D).visible = false
		elif c is GeometryInstance3D:
			(c as GeometryInstance3D).material_override = mat
		_blacken(c, mat)
