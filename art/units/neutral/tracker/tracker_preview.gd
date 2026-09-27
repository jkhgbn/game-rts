extends Node3D
## Greywater Tracker preview (task 10.V7) from the RTS camera (pitch 55, fov 50) and a few detail angles.
## Keys: 1-5 zoom 5 / 12 / 25 / 40 / 55 · A attack · C cast · H hit · D death · R revive · L level-up · W walk toggle
## · Y spin the facing.
## Windowed `-- --shots`: docs/art/screens/tracker_*.png then quit. `-- --detail`: only the close-up sheets.

const SCENE := "res://art/units/neutral/tracker/tracker.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)
const COMPARE: Array[String] = ["res://art/units/champions/wayfinder/wayfinder.tscn", "res://art/units/fire/ember_archer.tscn",
	"res://art/units/shadow/nightbolt.tscn"]

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
	_row.append(_spawn(Vector3(-2.2, 0, 0), 0.0, FIRE))
	_row.append(_spawn(Vector3(0.0, 0, 0), 0.0, SHADOW))
	_row.append(_spawn(Vector3(2.2, 0, 0), 200.0, ICE))
	_row.append(_spawn(Vector3(4.4, 0, 0), 90.0, NATURE))
	_set_zoom(12.0)
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		_take_shots()
	elif "--detail" in args:
		_detail_only()


func _detail_only() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _detail_sheet("tracker_detail_a", FIRE)
	await _pose_sheet("tracker_poses_side", 90.0, 14.0)
	await _pose_sheet("tracker_poses_front", 20.0, 40.0)
	get_tree().quit()


func _spawn(at: Vector3, yaw_deg: float, col: Color) -> Node3D:
	var m: Node3D = load(SCENE).instantiate()
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	m.call(&"set_team_color", col)
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
	pm.size = Vector2(200, 200)
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


func _set_zoom(z: float, focus: Vector3 = Vector3(1.1, 0.0, 0.0), pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0.0, sin(pitch) * z, cos(pitch) * z).rotated(Vector3.UP, yaw)
	_cam.position = ORIGIN + focus + off
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(5.0, Vector3(-1.1, 1.2, 0), 25.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L: _all(&"play_level_up")
		KEY_C:
			for m in _row:
				m.play_cast(&"snare_shot")
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m in _row:
				m.set_moving(5.4 if _walking else 0.0)


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(1.1, 1.0, 0.0), 9.5).save_png(OUT + "tracker_z%d.png" % int(z))
	await _detail_sheet("tracker_detail_a", FIRE)
	await _detail_sheet("tracker_detail_b", SHADOW)
	await _pose_sheet("tracker_poses_side", 90.0, 14.0)
	await _pose_sheet("tracker_poses_front", 20.0, 40.0)
	await _anim_sheet("tracker_anim")
	await _silhouettes("tracker_silhouette")
	await _lineup("tracker_lineup", false)
	await _lineup("tracker_lineup_black", true)
	get_tree().quit()


## One unit alone, close (not a game angle): front, 3/4 front, side, back, 3/4 back, game angle 55 deg at 5 m.
func _detail_sheet(nm: String, col: Color) -> void:
	for m in _row:
		m.get_parent().visible = false
	var u := _spawn(Vector3(0, 0, 80.0), 0.0, col)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	for f: Array in [[0.0, 10.0, 4.2], [35.0, 10.0, 4.2], [90.0, 10.0, 4.2], [180.0, 10.0, 4.2], [215.0, 22.0, 4.2],
			[20.0, 55.0, 5.5]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), Vector3(0, 1.2, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_center_crop(_grab(), 0.5, 0.56))
	var w := 400
	var hh := 450
	var out := Image.create(w * 3, hh * 2, false, frames[0].get_format())
	for i: int in frames.size():
		frames[i].resize(w, hh)
		out.blit_rect(frames[i], Rect2i(0, 0, w, hh), Vector2i((i % 3) * w, (i / 3) * hh))
	out.save_png(OUT + nm + ".png")
	h.queue_free()
	for m in _row:
		m.get_parent().visible = true


## Key frames side by side: rest, walk, attack aim (0.10), release (0.16), re-span (0.55), cast aim (0.28).
func _pose_sheet(nm: String, yaw: float, pitch: float) -> void:
	for m in _row:
		m.get_parent().visible = false
	var rows: Array = [["rest", 0.0], ["walk", 0.4], ["attack", 0.10], ["attack", 0.16], ["attack", 0.55], ["cast", 0.28]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	for i: int in n:
		units.append(_spawn(Vector3((float(i) - float(n - 1) * 0.5) * 1.9, 0, 24.0), yaw, FIRE))
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(8.5, Vector3(0.0, 1.2, 24.0), pitch)
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
				units[i].set_moving(5.4)
			"attack":
				units[i].play_attack()
			_:
				units[i].play_cast(&"snare_shot")
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_grab().save_png(OUT + nm + ".png")
	await _wait(1.3)
	for m in units:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


## One frame per state (front + side pair): idle, walk, hit, aimed, death 0.3 / 0.6 / 0.9, revived.
func _anim_sheet(nm: String) -> void:
	for m in _row:
		m.get_parent().visible = false
	var a := _spawn(Vector3(-1.0, 0, 36.0), 20.0, FIRE)
	var b := _spawn(Vector3(1.0, 0, 36.0), 90.0, SHADOW)
	var pair: Array = [a, b]
	_set_zoom(7.0, Vector3(0.0, 1.2, 36.0), 40.0)
	var frames: Array[Image] = []
	await _wait(0.6)
	frames.append(_grab())
	for m in pair:
		m.set_moving(5.4)
	await _wait(0.66)
	frames.append(_grab())
	for m in pair:
		m.set_moving(0.0)
	await _wait(0.5)
	for m in pair:
		m.play_hit()
	await _wait(0.05)
	frames.append(_grab())
	await _wait(0.5)
	for m in pair:
		m.play_attack()
	await _wait(0.12)
	frames.append(_grab())
	await _wait(1.4)
	for m in pair:
		m.play_death()
	for t: float in [0.3, 0.6, 0.9]:
		await _until(a, &"_death_t", t)
		frames.append(_grab())
	await _wait(0.4)
	for m in pair:
		m.revive()
	await _wait(0.3)
	frames.append(_grab())
	_contact(frames, nm, 4, Rect2i(320, 60, 960, 540))
	for m in pair:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


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


## Unlit black on white (the "black test"): front, 3/4 back, side, walking, then aimed, at 25 m and 40 m.
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	for m in _row:
		m.get_parent().visible = false
	var sil: Array = []
	var yaws: Array[float] = [0.0, 200.0, 90.0, 45.0]
	for i: int in 4:
		sil.append(_spawn(Vector3(-2.4 + 1.6 * float(i), 0, 48.0), yaws[i], FIRE))
	await _wait(0.4)
	for u in sil:
		_blacken(u)
	sil[3].set_moving(5.4)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 1.1, 48.0)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 48.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 7.2))
	sil[3].set_moving(0.0)
	for u in sil:
		u.play_attack()
	await _wait(0.12)
	imgs.append(_crop_world(_grab(), centre, 7.2))
	var w := imgs[0].get_width()
	var out := Image.create(w * 3 + 16, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	for i: int in 3:
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")
	await _wait(1.3)
	for m in sil:
		m.get_parent().queue_free()
	_black_world(false, old)
	for m in _row:
		m.get_parent().visible = true


## The 40 m distinction: tracker (Fire, Shadow) next to the Wayfinder, an Ember Archer and a Nightbolt, at 25 and 40 m.
## black: the same row as unlit silhouettes.
func _lineup(nm: String, black: bool) -> void:
	for m in _row:
		m.get_parent().visible = false
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var xs: Array[float] = [-4.0, -2.0, 0.0, 2.0, 4.0]
	var t1 := _spawn(Vector3(xs[0], 0, 60.0), 20.0, FIRE)
	holders.append(t1.get_parent())
	var t2 := _spawn(Vector3(xs[4], 0, 60.0), 20.0, SHADOW)
	holders.append(t2.get_parent())
	for i: int in COMPARE.size():
		if ResourceLoader.exists(COMPARE[i]):
			var u: Node3D = load(COMPARE[i]).instantiate()
			var h := Node3D.new()
			h.position = ORIGIN + Vector3(xs[i + 1], 0, 60.0)
			h.rotation.y = deg_to_rad(20.0)
			add_child(h)
			h.add_child(u)
			holders.append(h)
	await _wait(0.4)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 60.0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(0.0, 1.0, 60.0), 12.0))
	var w := imgs[0].get_width()
	var out := Image.create(w * 2 + 8, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color.WHITE)
	out.blit_rect(imgs[0], Rect2i(Vector2i.ZERO, imgs[0].get_size()), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(Vector2i.ZERO, imgs[1].get_size()), Vector2i(w + 8, 0))
	out.save_png(OUT + nm + ".png")
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	for m in _row:
		m.get_parent().visible = true


## Crop a window `width_m` metres wide around the world point `centre` (projected by the current camera), 800 x 450.
func _crop_world(img: Image, centre: Vector3, width_m: float) -> Image:
	var c := _cam.unproject_position(centre)
	var r := _cam.unproject_position(centre + _cam.global_transform.basis.x * width_m * 0.5)
	var w: int = clampi(int((r.x - c.x) * 2.0), 40, img.get_width())
	var h: int = int(float(w) * 9.0 / 16.0)
	var rect := Rect2i(clampi(int(c.x) - w / 2, 0, img.get_width() - w), clampi(int(c.y) - h / 2, 0, img.get_height() - h), w, h)
	var out := img.get_region(rect)
	out.resize(800, 450, Image.INTERPOLATE_NEAREST)
	return out


## Central crop: `fw` of the width, `fh` of the height (keeps the 8:9 detail frames whatever the window size).
func _center_crop(img: Image, fw: float, fh: float) -> Image:
	var w := int(img.get_width() * fw)
	var h := int(img.get_height() * fh * 1.6)
	h = mini(h, img.get_height())
	w = mini(int(h * 8.0 / 9.0), img.get_width())
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _contact(imgs: Array[Image], nm: String, cols: int, crop: Rect2i = Rect2i()) -> void:
	if crop.size != Vector2i.ZERO:
		for i: int in imgs.size():
			imgs[i] = imgs[i].get_region(crop)
			imgs[i].resize(1600, 900)
	var w: int = imgs[0].get_width() / 2
	var h: int = imgs[0].get_height() / 2
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, imgs[0].get_format())
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.resize(w, h)
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
