extends Node3D
## Tusker preview (task 12.V27): Ironhide Tusker (A) and Old Scarback (B) from the RTS camera (pitch 55, fov 50),
## next to the camp Bristleback, plus detail angles, poses, the gore charge and silhouettes.
## Keys: 1-5 zoom 6 / 12 / 25 / 40 / 55 · A attack · C cast gore_charge (a real 10 m dash) · B bristle_hide
## · F fidget · H hit · D death · R revive · W walk toggle · Y spin the facing.
## Windowed `-- --shots`: docs/art/screens/12_v27_*.png then quit.

const SCENE := "res://art/units/neutral/beasts/tusker/tusker.tscn"
const BRISTLEBACK := "res://art/units/neutral/bristleback/bristleback.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references for the lineup (skipped when missing).
const COMPARE: Array[String] = ["res://art/units/neutral/bristleback/bristleback.tscn",
	"res://art/units/neutral/hollow_stag/hollow_stag.tscn", "res://art/units/fire/flame_guard.tscn",
	"res://art/units/neutral/ruin_warden.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _walking: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(SCENE, Vector3(-3.6, 0, 0), 35.0, 0))
	_row.append(_spawn(SCENE, Vector3(1.4, 0, 0), 35.0, 1))
	_row.append(_spawn(BRISTLEBACK, Vector3(5.2, 0, 0.3), 35.0))
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float, variant: int = -1) -> Node3D:
	var m: Node3D = load(path).instantiate()
	if variant >= 0 and m.has_method(&"set_variant"):
		m.call(&"set_variant", variant)
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	for p: StringName in [&"fidget_every", &"dig_every"]:
		if p in m:
			m.set(p, 0.0)
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
	pm.size = Vector2(420, 420)
	_ground.mesh = pm
	var gmat: Material = null
	if ResourceLoader.exists("res://art/environment/ground_material.tres"):
		gmat = load("res://art/environment/ground_material.tres")
	if gmat == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.24, 0.27, 0.20)
		gmat = sm
	_ground.material_override = gmat
	add_child(_ground)


func _set_zoom(z: float, focus: Vector3 = Vector3(0.8, 0.0, 0.0), pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0.0, sin(pitch) * z, cos(pitch) * z).rotated(Vector3.UP, yaw)
	_cam.position = ORIGIN + focus + off
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(6.0, Vector3(-1.0, 1.2, 0), 20.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_F: _all(&"play_fidget")
		KEY_B:
			for m in _row:
				if m.has_method(&"play_bristle"):
					m.play_cast(&"bristle_hide")
		KEY_C:
			for m in _row:
				if m.has_method(&"set_variant"):
					_dash(m, 10.0)
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m in _row:
				if m.has_method(&"set_moving"):
					m.set_moving(5.5 if _walking else 0.0)


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


## Plays gore_charge and drags the holder `dist` m forward at 12 m/s (what CreatureAbilities does to the unit), then
## puts it back after the toss.
func _dash(m: Node3D, dist: float) -> void:
	var h: Node3D = m.get_parent()
	var start := h.position
	var fwd := h.global_transform.basis.z.normalized()
	m.call(&"play_cast", &"gore_charge")
	var moved := 0.0
	while moved < dist:
		await get_tree().process_frame
		var step := 12.0 * get_process_delta_time()
		h.position += fwd * step
		moved += step
	await _wait(1.2)
	h.position = start


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(0.8, 1.0, 0.0), 14.0 if z < 30.0 else 18.0).save_png(OUT + "12_v27_z%d.png" % int(z))
	_set_zoom(40.0)
	await _wait(0.3)
	_grab().save_png(OUT + "12_v27_game_40m.png")
	await _contact_sheet("12_v27_contact")
	await _detail_sheet("12_v27_detail_a", 0)
	await _detail_sheet("12_v27_detail_b", 1)
	await _pose_sheet("12_v27_poses_side", 90.0, 12.0)
	await _pose_sheet("12_v27_poses_game", 30.0, 55.0)
	await _charge_sheet("12_v27_charge")
	await _lineup("12_v27_lineup", false)
	await _lineup("12_v27_lineup_black", true)
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m in _row:
		m.get_parent().visible = not on


## THE contact sheet: A | B | Bristleback, in colour (top row) and as black silhouettes on white (bottom row), at
## 12 / 25 / 40 m from the game camera; a third row: the same trio from the side at 25 m (colour, then black) and the
## 40 m silhouette of both beasts walking.
func _contact_sheet(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(0.0, 0.0, 150.0)
	var trio: Array = [_spawn(SCENE, c + Vector3(-3.8, 0, 0), 35.0, 0), _spawn(SCENE, c + Vector3(1.2, 0, 0), 35.0, 1),
		_spawn(BRISTLEBACK, c + Vector3(5.2, 0, 0.3), 35.0)]
	await _wait(0.6)
	var centre := ORIGIN + c + Vector3(0.7, 1.0, 0.0)
	var imgs: Array[Image] = []
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z, c + Vector3(0.7, 0, 0))
		await _wait(0.4)
		imgs.append(_crop_world(_grab(), centre, 15.0))
	_set_zoom(16.0, c + Vector3(0.7, 0.9, 0), 8.0)
	await _wait(0.4)
	var side_col := _crop_world(_grab(), centre, 15.0)
	var old := _black_world(true, [])
	for m in trio:
		_blacken(m.get_parent())
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z, c + Vector3(0.7, 0, 0))
		await _wait(0.4)
		imgs.append(_crop_world(_grab(), centre, 15.0))
	imgs.append(side_col)
	_set_zoom(16.0, c + Vector3(0.7, 0.9, 0), 8.0)
	await _wait(0.4)
	imgs.append(_crop_world(_grab(), centre, 15.0))
	for m in trio:
		if m.has_method(&"set_moving"):
			m.set_moving(5.5)
	_set_zoom(40.0, c + Vector3(0.7, 0, 0))
	await _wait(0.45)
	imgs.append(_crop_world(_grab(), centre, 15.0))
	_black_world(false, old)
	_grid_sheet(imgs, nm, 3, [Color(1, 1, 1), Color(1, 1, 1), Color(1, 1, 1)])
	for m in trio:
		m.get_parent().queue_free()
	_hide_row(false)


## One beast alone, close: front, 3/4 front, side, back, 3/4 back from above, game angle 55 deg.
func _detail_sheet(nm: String, variant: int) -> void:
	_hide_row(true)
	var u := _spawn(SCENE, Vector3(0, 0, 80.0), 0.0, variant)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	var dist := 7.5 * (1.15 if variant == 1 else 1.0)
	for f: Array in [[0.0, 10.0], [35.0, 16.0], [90.0, 6.0], [180.0, 14.0], [215.0, 32.0], [25.0, 55.0]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(dist * (1.2 if float(f[1]) > 50.0 else 1.0), Vector3(0, 1.2, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
	_sheet(frames, nm, 3, 480, 440)
	h.queue_free()
	_hide_row(false)


## Key frames side by side (A): rest, walk, gore windup / strike / toss, charge gallop x2, toss, fidget, death x2.
func _pose_sheet(nm: String, yaw: float, pitch: float) -> void:
	_hide_row(true)
	var rows: Array = [["rest", 0.0], ["walk", 0.4], ["attack", 0.065], ["attack", 0.12], ["attack", 0.26],
		["cast", 0.3], ["cast", 0.45], ["cast", 0.83], ["fidget", 0.7], ["death", 0.45], ["death", 0.85]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	var gap := 4.3 if yaw > 60.0 else 3.4
	for i: int in n:
		var u := _spawn(SCENE, Vector3((float(i) - float(n - 1) * 0.5) * gap, 0, 24.0), yaw, 0)
		units.append(u)
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(30.0 if pitch < 30.0 else 36.0, Vector3(0.0, 1.0, 24.0), pitch)
	await _wait(0.8)
	var order: Array = range(n)
	order.sort_custom(func(a: int, b: int) -> bool: return float(rows[a][1]) > float(rows[b][1]))
	var elapsed := 0.0
	for i: int in order:
		var start: float = t_max - float(rows[i][1])
		if start > elapsed:
			await _wait(start - elapsed)
			elapsed = start
		match String(rows[i][0]):
			"rest":
				pass
			"walk":
				units[i].set_moving(5.5)
			"attack":
				units[i].play_attack()
			"fidget":
				units[i].play_fidget()
			"death":
				units[i].play_death()
			_:
				units[i].play_cast(&"gore_charge")
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_grab().save_png(OUT + nm + ".png")
	await _wait(1.6)
	for m in units:
		m.get_parent().queue_free()
	_hide_row(false)


## A real charge: B and A dashing 10 m at 12 m/s past the camera (dust trail), then the skid and toss; 25 m game camera.
func _charge_sheet(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(0.0, 0.0, 200.0)
	var a := _spawn(SCENE, c + Vector3(-5.5, 0, 1.8), 90.0, 0)
	var b := _spawn(SCENE, c + Vector3(-5.5, 0, -2.4), 90.0, 1)
	await _wait(0.6)
	_set_zoom(22.0, c + Vector3(0, 0, -0.3))
	var imgs: Array[Image] = []
	_dash(a, 10.0)
	_dash(b, 10.0)
	for t: float in [0.3, 0.6, 0.9, 1.02]:
		await _until(a, &"_action_t", t)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.0, -0.3), 17.0))
	_grid_sheet(imgs, nm, 2, [Color.WHITE])
	await _wait(1.5)
	a.get_parent().queue_free()
	b.get_parent().queue_free()
	_hide_row(false)


func _black_world(on: bool, old: Array) -> Array:
	if on:
		var white := StandardMaterial3D.new()
		white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		white.albedo_color = Color.WHITE
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color.WHITE
		var keep: Array = [_ground.material_override, _env.environment]
		_ground.material_override = white
		_env.environment = e
		return keep
	_ground.material_override = old[0]
	_env.environment = old[1]
	return []


func _blacken(under: Node) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	for g: Node in under.find_children("*", "GeometryInstance3D", true, false):
		if g is GPUParticles3D or g.name == "Shadow":
			(g as Node3D).visible = false
		else:
			(g as GeometryInstance3D).material_override = black


## Scale and look: A, B, a Bristleback, a Hollow Stag, a Flame Guard, a Ruin Warden at 25 and 40 m; black = unlit.
func _lineup(nm: String, black: bool) -> void:
	_hide_row(true)
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var xs: Array[float] = [-8.4, -3.6, 0.6, 3.6, 7.2, 9.6]
	var paths: Array[String] = [SCENE, SCENE]
	paths.append_array(COMPARE)
	var yaws: Array[float] = [35.0, 35.0, 40.0, 60.0, 40.0, 40.0]
	for i: int in paths.size():
		if ResourceLoader.exists(paths[i]):
			var u := _spawn(paths[i], Vector3(xs[i], 0, 60.0), yaws[i], i if i < 2 else -1)
			holders.append(u.get_parent())
	await _wait(0.5)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.6, 0.0, 60.0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(0.6, 0.9, 60.0), 22.0))
	_strip(imgs, nm, Color.WHITE)
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	_hide_row(false)


## Images side by side with an 8 px gap.
func _strip(imgs: Array[Image], nm: String, bg: Color) -> void:
	var w := imgs[0].get_width()
	var out := Image.create(w * imgs.size() + 8 * (imgs.size() - 1), imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(bg)
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")


## Images in a grid (cols), 6 px grey gaps.
func _grid_sheet(imgs: Array[Image], nm: String, cols: int, _bg: Array) -> void:
	var w := imgs[0].get_width()
	var h := imgs[0].get_height()
	var rows: int = (imgs.size() + cols - 1) / cols
	var gap := 6
	var out := Image.create(w * cols + gap * (cols - 1), h * rows + gap * (rows - 1), false, imgs[0].get_format())
	out.fill(Color(0.55, 0.55, 0.55))
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((i % cols) * (w + gap),
			(i / cols) * (h + gap)))
	out.save_png(OUT + nm + ".png")


func _sheet(frames: Array[Image], nm: String, cols: int, w: int, hh: int) -> void:
	var rows: int = (frames.size() + cols - 1) / cols
	var out := Image.create(w * cols, hh * rows, false, frames[0].get_format())
	for i: int in frames.size():
		frames[i].resize(w, hh)
		out.blit_rect(frames[i], Rect2i(0, 0, w, hh), Vector2i((i % cols) * w, (i / cols) * hh))
	out.save_png(OUT + nm + ".png")


## Crop a window `width_m` metres wide around the world point `centre` (projected by the current camera), 800 x 450.
func _crop_world(img: Image, centre: Vector3, width_m: float) -> Image:
	var c := _cam.unproject_position(centre)
	var r := _cam.unproject_position(centre + _cam.global_transform.basis.x * width_m * 0.5)
	var w: int = clampi(int((r.x - c.x) * 2.0), 40, img.get_width())
	var h: int = mini(int(float(w) * 9.0 / 16.0), img.get_height())
	var rect := Rect2i(clampi(int(c.x) - w / 2, 0, img.get_width() - w), clampi(int(c.y) - h / 2, 0, img.get_height() - h), w, h)
	var out := img.get_region(rect)
	out.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return out


## Central crop (keeps the detail frames whatever the window size): a 12:11 box of 80 % of the height.
func _center_crop(img: Image) -> Image:
	var h := int(img.get_height() * 0.8)
	var w := mini(int(h * 12.0 / 11.0), img.get_width())
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _until(m: Object, prop: StringName, t: float) -> void:
	var guard := 0
	while float(m.get(prop)) < t and guard < 240:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
