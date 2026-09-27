extends Node3D
## Game critters preview (task 12.V15): red deer + rabbit from the RTS camera (pitch 55, fov 50) and detail angles.
## Keys: 1-5 zoom 5 / 12 / 25 / 40 / 55 · I idle · W walk · F flee · H hit · D death · R revive · Y spin.
## Windowed `-- --shots`: docs/art/screens/12_v15_*.png, then quits.
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/neutral/critters/tools/critter_preview.tscn
##     --resolution 1600x900 --fixed-fps 60 -- --shots

const DEER := "res://art/units/neutral/critters/deer.tscn"
const RABBIT := "res://art/units/neutral/critters/rabbit.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references (skipped when missing): a soldier, the camp boar and the Hollow Stag the deer must not be
## mistaken for.
const COMPARE: Array[String] = ["res://art/units/fire/flame_guard.tscn",
	"res://art/units/neutral/bristleback/bristleback.tscn",
	"res://art/units/neutral/hollow_stag/hollow_stag.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(DEER, Vector3(-1.6, 0, 0), 30.0))
	_row.append(_spawn(DEER, Vector3(1.0, 0, 0.6), 110.0))
	_row.append(_spawn(RABBIT, Vector3(2.8, 0, 0), 200.0))
	_row.append(_spawn(RABBIT, Vector3(3.6, 0, 0.8), -40.0))
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # stands in for GameCritter: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
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
	var gmat: Material = null
	if ResourceLoader.exists("res://art/environment/ground_material.tres"):
		gmat = load("res://art/environment/ground_material.tres")
	if gmat == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.24, 0.27, 0.20)
		gmat = sm
	_ground.material_override = gmat
	add_child(_ground)


func _set_zoom(z: float, focus: Vector3 = Vector3(1.0, 0.0, 0.0), pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0.0, sin(pitch) * z, cos(pitch) * z).rotated(Vector3.UP, yaw)
	_cam.position = ORIGIN + focus + off
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(5.0, Vector3(0.0, 0.8, 0), 20.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_I: _all(&"play_idle")
		KEY_W:
			for m in _row:
				m.play_move(3.0 if m.scene_file_path == DEER else 2.0)
		KEY_F: _all(&"play_flee")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)


func _all(method: StringName) -> void:
	for m in _row:
		m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_hide_row(true)
	await _wait(0.5)
	await _detail_sheet("12_v15_detail_deer", DEER, 0.9, 3.6, 1)
	await _detail_sheet("12_v15_detail_rabbit", RABBIT, 0.3, 1.5, 2)
	await _pose_sheet("12_v15_poses_deer", DEER, 2.3, 1.0, 11.5)
	await _pose_sheet("12_v15_poses_rabbit", RABBIT, 0.8, 0.3, 4.2)
	await _death_sheet("12_v15_death")
	await _game_view("12_v15_game", false)
	await _game_view("12_v15_game_black", true)
	await _silhouettes("12_v15_silhouette")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m in _row:
		m.get_parent().visible = not on


## One animal alone, close: front 3/4, side, back, 3/4 back (idle look), game angle 55 deg, side grazing.
func _detail_sheet(nm: String, path: String, focus_y: float, dist: float, look: int) -> void:
	var at := Vector3(0, 0, 80.0)
	var u := _spawn(path, at, 0.0)
	u.set_idle_mode(1)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.6)
	var views: Array = [[35.0, 10.0, dist, look], [90.0, 6.0, dist, look], [180.0, 12.0, dist, look],
		[215.0, 22.0, dist, look], [25.0, 55.0, dist * 1.3, look], [90.0, 6.0, dist, 0 if look == 1 else 1]]
	for f: Array in views:
		u.set_idle_mode(int(f[3]))
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), at + Vector3(0, focus_y, 0), float(f[1]))
		await _wait(1.4 if int(f[3]) == 0 else 0.4)
		frames.append(_center_crop(_grab()))
	var w := 520
	var hh := 440
	var out := Image.create(w * 3, hh * 2, false, frames[0].get_format())
	for i: int in frames.size():
		frames[i].resize(w, hh)
		out.blit_rect(frames[i], Rect2i(0, 0, w, hh), Vector2i((i % 3) * w, (i / 3) * hh))
	out.save_png(OUT + nm + ".png")
	h.queue_free()
	await _wait(0.1)


## Side view row: idle look, graze / nibble, sit up (rabbit), walk at 2 phases, run at 2 phases, hit.
func _pose_sheet(nm: String, path: String, spacing: float, focus_y: float, dist: float) -> void:
	var is_deer: bool = path == DEER
	var rows: Array = [["look", 0.0], ["graze", 0.0], ["walk", 0.0], ["walk", 0.25], ["run", 0.05], ["run", 0.55],
		["hit", 0.0]]
	if not is_deer:
		rows = [["still", 0.0], ["graze", 0.0], ["situp", 0.0], ["walk", 0.12], ["walk", 0.45], ["run", 0.15],
			["run", 0.6], ["hit", 0.0]]
	var n := rows.size()
	var z := 30.0
	var units: Array = []
	for i: int in n:
		var u := _spawn(path, Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0, z), 90.0)
		units.append(u)
		match String(rows[i][0]):
			"look": u.set_idle_mode(1)
			"graze": u.set_idle_mode(0)
			"situp": u.set_idle_mode(1)
			"still": u.set_idle_mode(2)
			"walk": u.play_move(3.0 if is_deer else 2.0)
			"run": u.play_move(u.flee_speed)
			"hit": u.set_idle_mode(1 if is_deer else 2)
	_set_zoom(dist * float(n) / 7.0, Vector3(0.0, focus_y, z), 8.0)
	await _wait(1.8)
	for i: int in n:
		if String(rows[i][0]) == "walk" or String(rows[i][0]) == "run":
			units[i].set(&"_phase", float(rows[i][1]))
		if String(rows[i][0]) == "hit":
			units[i].play_hit()
	await _wait(0.1)
	_grab().save_png(OUT + nm + ".png")
	for m in units:
		m.get_parent().queue_free()
	await _wait(0.1)


## Death over time (deer + rabbit, 3/4 view): 0.15 / 0.4 / 0.8 / 1.3 / 3.0 / 4.35 / 4.6 s.
func _death_sheet(nm: String) -> void:
	var z := 50.0
	var d := _spawn(DEER, Vector3(-0.8, 0, z), 60.0)
	var r := _spawn(RABBIT, Vector3(1.6, 0, z + 0.4), 60.0)
	d.set_idle_mode(1)
	r.set_idle_mode(2)
	_set_zoom(6.0, Vector3(0.3, 0.6, z), 30.0, 0.0)
	await _wait(0.8)
	var frames: Array[Image] = [_grab()]
	d.play_death()
	r.play_death()
	for t: float in [0.15, 0.4, 0.8, 1.3, 3.0, 4.35, 4.6]:
		await _until(d, t)
		frames.append(_grab())
	_contact(frames, nm, 4, Rect2i(260, 120, 1080, 610))
	d.get_parent().queue_free()
	r.get_parent().queue_free()
	await _wait(0.1)


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
			continue
		# The critters keep their own shader (its vertex rig poses them) with flat_black on.
		if g is MeshInstance3D and (g as MeshInstance3D).mesh and (g as MeshInstance3D).mesh.get_surface_count() > 0:
			var sm := (g as MeshInstance3D).mesh.surface_get_material(0) as ShaderMaterial
			if sm and sm.shader and sm.shader.resource_path.ends_with("critter_painted.gdshader"):
				var dup := sm.duplicate() as ShaderMaterial
				dup.set_shader_parameter(&"flat_black", true)
				(g as GeometryInstance3D).material_override = dup
				continue
		(g as GeometryInstance3D).material_override = black


## The game view: a herd (2 stags, 1 hind), 4 rabbits and the references, 25 m and 40 m (cropped 16 m wide) and the
## full 40 m frame at 1:1 pixels. black: the same as unlit silhouettes.
func _game_view(nm: String, black: bool) -> void:
	var old: Array = _black_world(true, []) if black else []
	var z := 70.0
	var holders: Array = []
	var specs: Array = [[DEER, Vector3(-4.0, 0, z), 20.0, 0], [DEER, Vector3(-2.2, 0, z + 1.5), 150.0, 1],
		[DEER, Vector3(-3.2, 0, z - 1.6), 250.0, 0], [RABBIT, Vector3(0.2, 0, z + 0.5), 30.0, 0],
		[RABBIT, Vector3(1.0, 0, z - 0.8), 120.0, 1], [RABBIT, Vector3(1.6, 0, z + 1.2), 200.0, 2],
		[RABBIT, Vector3(-0.6, 0, z - 1.8), 300.0, -2]]
	for s: Array in specs:
		var m: Node3D = load(s[0]).instantiate()
		if s[0] == DEER and int(s[3]) == 1:
			m.set(&"antlers", false)
		var h := Node3D.new()
		h.position = ORIGIN + (s[1] as Vector3)
		h.rotation.y = deg_to_rad(float(s[2]))
		add_child(h)
		h.add_child(m)
		holders.append(h)
		if int(s[3]) == -2:
			m.play_flee()
		elif s[0] == DEER:
			m.set_idle_mode(int(s[3]) % 2)
		else:
			m.set_idle_mode(int(s[3]))
	var xs: Array[float] = [3.4, 5.4, 8.6]
	for i: int in COMPARE.size():
		if ResourceLoader.exists(COMPARE[i]):
			var u: Node3D = load(COMPARE[i]).instantiate()
			var h := Node3D.new()
			h.position = ORIGIN + Vector3(xs[i], 0, z)
			h.rotation.y = deg_to_rad(40.0)
			add_child(h)
			h.add_child(u)
			holders.append(h)
	await _wait(0.8)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for zz: float in [25.0, 40.0]:
		_set_zoom(zz, Vector3(1.5, 0.0, z))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(1.5, 0.6, z), 16.0))
	var full := _grab()
	var w := imgs[0].get_width()
	var out := Image.create(w * 2 + 8, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color.WHITE)
	out.blit_rect(imgs[0], Rect2i(Vector2i.ZERO, imgs[0].get_size()), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(Vector2i.ZERO, imgs[1].get_size()), Vector2i(w + 8, 0))
	out.save_png(OUT + nm + ".png")
	if not black:
		full.save_png(OUT + "12_v15_z40_full.png")
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	await _wait(0.1)


## Unlit black on white: deer from 4 sides + fleeing, rabbits sitting / sitting up / bolting; 25 m and 40 m.
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	var z := 90.0
	var list: Array = []
	var yaws: Array[float] = [20.0, 90.0, 200.0, 290.0]
	for i: int in 4:
		var u := _spawn(DEER, Vector3(-4.5 + 2.2 * float(i), 0, z), yaws[i])
		u.set_idle_mode(1)
		list.append(u)
	list[3].play_flee()
	for i: int in 4:
		var u := _spawn(RABBIT, Vector3(-3.5 + 1.6 * float(i), 0, z + 3.0), yaws[i])
		u.set_idle_mode(2 if i == 0 else 1)
		list.append(u)
	list[7].play_flee()
	await _wait(0.6)
	for u in list:
		_blacken(u)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(-1.0, 0.5, z + 1.2)
	for zz: float in [25.0, 40.0]:
		_set_zoom(zz, Vector3(-1.0, 0.0, z + 1.2))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 12.0))
	var w := imgs[0].get_width()
	var out := Image.create(w * 2 + 8, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	for i: int in 2:
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")
	for m in list:
		m.get_parent().queue_free()
	_black_world(false, old)


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


func _center_crop(img: Image) -> Image:
	var h: int = int(img.get_height() * 0.8)
	var w: int = mini(int(h * 1.18), img.get_width())
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _contact(imgs: Array[Image], nm: String, cols: int, crop: Rect2i = Rect2i()) -> void:
	if crop.size != Vector2i.ZERO:
		for i: int in imgs.size():
			imgs[i] = imgs[i].get_region(crop)
	var w: int = imgs[0].get_width() / 2
	var h: int = imgs[0].get_height() / 2
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, imgs[0].get_format())
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


func _until(m: Object, t: float) -> void:
	var guard := 0
	while float(m.call(&"death_time")) < t and guard < 600:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
