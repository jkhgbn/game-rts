extends Node3D
## Torvald polish preview (task A.3) from the RTS camera (pitch 55, fov 50, like scripts/ui/rts_camera.gd).
## Windowed: `-- --shots --tag=after` saves docs/art/screens/polish_torvald_<tag>_*.png and quits.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up, 7 walk toggle, 8 cast (rime_bolt / flash_freeze / rime_aegis),
## 9 revive, wheel = zoom.

const TORVALD := "res://art/units/wizards/torvald.tscn"
const OTHERS: Array[String] = ["res://art/units/wizards/vessa.tscn", "res://art/units/wizards/malrik.tscn",
	"res://art/units/ice/rimeshield.tscn", "res://art/units/ice/rime_hauler.tscn"]
const OTHER_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95),
	Color(0.45, 0.75, 0.95)]
const ICE := Color(0.45, 0.75, 0.95)
const CASTS: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]

var zoom: float = 12.0
var focus: Vector3 = Vector3(0, 1.0, 0)
var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _tag: String = "after"
var _units: Array[Node3D] = []
var _walking: bool = false
var _cast_i: int = 0
var _pitch: float = 55.0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.substr(6)
	_env = WorldEnvironment.new()
	if ResourceLoader.exists("res://art/environment/world_env.tres"):
		_env.environment = load("res://art/environment/world_env.tres")
	else:
		_env.environment = Environment.new()
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	_ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.36, 0.40, 0.26)
	gm.roughness = 1.0
	_ground.material_override = gm
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	_apply()
	if "--anim" in OS.get_cmdline_user_args():
		_anim_shots()
	elif "--shots" in OS.get_cmdline_user_args():
		_shots()
	else:
		_units.append(_spawn(TORVALD, Vector3.ZERO, 0.0, ICE))


func _spawn(path: String, at: Vector3, yaw_deg: float, col: Color) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var u := ps.instantiate() as Node3D
	if u == null or not u.has_method(&"set_team_color"):
		if u:
			u.free()
		return null
	u.position = at
	u.rotation.y = deg_to_rad(yaw_deg)
	add_child(u)
	u.call(&"set_team_color", col)
	return u


func _apply() -> void:
	var p: float = deg_to_rad(_pitch)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 2.0, 4.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 2.0, 4.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		for u: Node3D in _units:
			if not is_instance_valid(u):
				continue
			match k.physical_keycode:
				KEY_1: u.call(&"play_attack")
				KEY_2: u.call(&"play_hit")
				KEY_3: u.call(&"play_death")
				KEY_4: u.call(&"play_level_up")
				KEY_7: u.call(&"set_moving", 0.0 if _walking else 4.2)
				KEY_8: u.call(&"play_cast", CASTS[_cast_i % CASTS.size()])
				KEY_9: u.call(&"revive")
		if k.physical_keycode == KEY_7:
			_walking = not _walking
		if k.physical_keycode == KEY_8:
			_cast_i += 1


# ------------------------------------------------------------------ shots

func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_torvald_%s_%s.png" % [_tag, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _clear() -> void:
	for u: Node3D in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()
	await get_tree().process_frame


func _view(z: float, f: Vector3) -> void:
	zoom = z
	focus = f
	_apply()


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	# 1. Torvald alone: front, three-quarter, back, side (z12) + close-up.
	_units.append(_spawn(TORVALD, Vector3(-3.6, 0, 0), 0.0, ICE))
	_units.append(_spawn(TORVALD, Vector3(-1.2, 0, 0), -40.0, ICE))
	_units.append(_spawn(TORVALD, Vector3(1.2, 0, 0), 90.0, ICE))
	_units.append(_spawn(TORVALD, Vector3(3.6, 0, 0), 180.0, ICE))
	_view(12.0, Vector3(0, 1.0, 0))
	await _wait(1.2)
	await _save("z12")
	_view(5.5, Vector3(-3.6, 1.4, 0))
	await _wait(0.6)
	await _save("close")
	_view(5.5, Vector3(1.2, 1.4, 0))
	await _wait(0.6)
	await _save("close_side")
	# detail check from a low camera (not a game angle): face, beard, crown
	_pitch = 20.0
	_view(3.6, Vector3(-3.6, 1.75, 0))
	await _wait(0.6)
	await _save("detail_front")
	_pitch = 55.0
	await _clear()
	if "--quick" in OS.get_cmdline_user_args():
		_units.append(_spawn(TORVALD, Vector3.ZERO, 0.0, ICE))
		_units.append(_spawn(OTHERS[0], Vector3(-2.4, 0, 0), 0.0, OTHER_COLORS[0]))
		_units.append(_spawn(OTHERS[2], Vector3(2.4, 0, 0), 0.0, OTHER_COLORS[2]))
		_view(25.0, Vector3(0, 1.0, 0))
		await _wait(1.0)
		await _save("z25")
		get_tree().quit()
		return
	# 2. Scale lineup with the other wizards and two Ice soldiers (z25, z45) + silhouette.
	var xs: Array[float] = [-4.8, -2.4, 2.4, 4.8]
	_units.append(_spawn(TORVALD, Vector3.ZERO, 0.0, ICE))
	for i: int in OTHERS.size():
		var u := _spawn(OTHERS[i], Vector3(xs[i], 0, 0), 0.0, OTHER_COLORS[i])
		if u:
			_units.append(u)
	_view(25.0, Vector3(0, 1.0, 0))
	await _wait(1.0)
	await _save("z25")
	_view(45.0, Vector3(0, 1.0, 0))
	await _wait(1.0)
	await _save("z45")
	# the 45 m look with Torvald walking (tier 1 animates every 2nd frame)
	_view(12.0, Vector3(0, 1.0, 0))
	await _wait(0.6)
	await _save("z12_lineup")
	await _silhouette()
	await _clear()
	# 3. Pose sheets (z12, front and side): each unit is started so all reach their key frame together.
	await _pose_sheet("poses_a", [
		["walk", 0.0, 0.40], ["attack", 0.0, 0.12], ["rime_bolt", 0.0, 0.14],
		["flash_freeze", 0.0, 0.20], ["flash_freeze", 0.0, 0.40]], 0.0)
	await _pose_sheet("poses_a_side", [
		["walk", 0.0, 0.40], ["attack", 0.0, 0.12], ["rime_bolt", 0.0, 0.14],
		["flash_freeze", 0.0, 0.20], ["flash_freeze", 0.0, 0.40]], 90.0)
	await _pose_sheet("poses_b", [
		["rime_aegis", 0.0, 0.35], ["rime_aegis", 0.0, 0.80], ["hit", 0.0, 0.06],
		["level_up", 0.0, 0.18], ["death", 0.0, 0.55]], 0.0)
	await _pose_sheet("poses_b_side", [
		["rime_aegis", 0.0, 0.35], ["rime_aegis", 0.0, 0.80], ["hit", 0.0, 0.06],
		["level_up", 0.0, 0.18], ["death", 0.0, 0.55]], 90.0)
	await _pose_sheet("poses_c", [
		["idle_beard", 0.0, 0.95], ["idle_tap", 0.0, 0.47], ["idle_survey", 0.0, 0.6],
		["flash_freeze", 0.0, 0.29], ["rime_aegis", 0.0, 0.12]], 0.0)
	await _pose_sheet("poses_c_side", [
		["idle_beard", 0.0, 0.95], ["idle_tap", 0.0, 0.47], ["idle_survey", 0.0, 0.6],
		["flash_freeze", 0.0, 0.29], ["rime_aegis", 0.0, 0.12]], 90.0)
	# 4. Casts at z25 (how they read in play).
	_units.append(_spawn(TORVALD, Vector3(-2.5, 0, 0), 0.0, ICE))
	_units.append(_spawn(TORVALD, Vector3(0, 0, 0), 0.0, ICE))
	_units.append(_spawn(TORVALD, Vector3(2.5, 0, 0), 0.0, ICE))
	_view(25.0, Vector3(0, 1.0, 0))
	await _wait(1.0)
	_units[0].call(&"play_cast", &"rime_bolt")
	_units[1].call(&"play_cast", &"flash_freeze")
	_units[2].call(&"play_cast", &"rime_aegis")
	await _wait(0.32)
	await _save("casts_z25")
	await _wait(1.5)
	await _clear()
	get_tree().quit()


## Motion strips: one Torvald, several frames of one action cropped and tiled into one image per action.
func _anim_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var u := _spawn(TORVALD, Vector3.ZERO, 90.0, ICE)
	_units.append(u)
	_view(7.5, Vector3(0, 1.2, 0))
	await _wait(1.0)
	# walk, side view: 6 frames over one stride (0.62 s)
	u.call(&"set_moving", 4.2)
	await _wait(0.8)
	await _strip("anim_walk_side", 6, 0.62 / 6.0)
	u.call(&"set_moving", 0.0)
	await _wait(0.6)
	for spec: Array in [["rime_bolt", 90.0, 6, 0.07], ["flash_freeze", 90.0, 7, 0.07], ["rime_aegis", 0.0, 6, 0.12],
			["idle_beard", 20.0, 6, 0.3], ["attack", 90.0, 5, 0.06], ["death", 90.0, 6, 0.16]]:
		u.rotation.y = deg_to_rad(float(spec[1]))
		await _wait(0.3)
		match String(spec[0]):
			"attack": u.call(&"play_attack")
			"death": u.call(&"play_death")
			_: u.call(&"play_cast", StringName(spec[0]))
		await _strip("anim_" + String(spec[0]), int(spec[2]), float(spec[3]))
		await _wait(1.2)
		if spec[0] == "death":
			u.call(&"revive")
	get_tree().quit()


func _strip(name: String, n: int, step: float) -> void:
	var frames: Array[Image] = []
	for i: int in n:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var w := img.get_width()
		var h := img.get_height()
		var cw := int(w * 0.24)
		var ch := int(h * 0.78)
		frames.append(img.get_region(Rect2i(w / 2 - cw / 2, int(h * 0.08), cw, ch)))
		await _wait(step)
	var sheet := Image.create(frames[0].get_width() * n, frames[0].get_height(), false, frames[0].get_format())
	for i: int in n:
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(frames[0].get_width() * i, 0))
	var path: String = "res://docs/art/screens/polish_torvald_%s_%s.png" % [_tag, name]
	sheet.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path)


## rows: [kind, unused, key_time]. kind = walk, attack, hit, death, level_up or a spell id.
func _pose_sheet(name: String, rows: Array, yaw: float) -> void:
	var n := rows.size()
	var t_max: float = 0.0
	for i: int in n:
		var x := (float(i) - float(n - 1) * 0.5) * 2.6
		_units.append(_spawn(TORVALD, Vector3(x, 0, 0), yaw, ICE))
		t_max = maxf(t_max, float(rows[i][2]))
	_view(12.5, Vector3(0, 1.1, 0))
	await _wait(1.0)
	# walkers start first (they need a moment to blend in), then the actions by descending key time.
	for i: int in n:
		if rows[i][0] == "walk":
			_units[i].call(&"set_moving", 4.2)
	await _wait(0.6)
	var order: Array[int] = []
	for i: int in n:
		if rows[i][0] != "walk":
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return float(rows[a][2]) > float(rows[b][2]))
	var elapsed: float = 0.0
	for i: int in order:
		var start: float = t_max - float(rows[i][2])
		if start > elapsed:
			await _wait(start - elapsed)
			elapsed = start
		var u := _units[i]
		match String(rows[i][0]):
			"attack": u.call(&"play_attack")
			"hit": u.call(&"play_hit")
			"death": u.call(&"play_death")
			"level_up": u.call(&"play_level_up")
			_: u.call(&"play_cast", StringName(rows[i][0]))
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	await _save(name)
	await _wait(1.2)
	await _clear()


func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var old_ground := _ground.material_override
	_ground.material_override = white
	var old_env := _env.environment
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	_env.environment = e
	for u: Node3D in _units:
		_blacken(u, black)
	_view(20.0, Vector3(0, 1.0, 0))
	await _wait(0.5)
	await _save("silhouette_z20")
	_env.environment = old_env
	_ground.material_override = old_ground


func _blacken(n: Node, m: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D or c is Light3D:
			(c as Node3D).visible = false
		elif c is GeometryInstance3D:
			if c.name == "Shadow":
				(c as Node3D).visible = false
			else:
				(c as GeometryInstance3D).material_override = m
		_blacken(c, m)
