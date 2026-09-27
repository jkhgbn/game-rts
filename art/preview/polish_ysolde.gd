extends Node3D
## Ysolde polish preview (task A.14): the Nature wizard from the RTS camera (pitch 55, fov 50) at 12 / 25 / 45 m.
## Keys: 1-5 zoom 6 / 12 / 25 / 45 / 55 · A attack · C cast cycle (thornburst, wild_bloom, call_the_thicket) · H hit
## D death · R revive · L level-up · W walk toggle · Y spin the facing.
## `-- --shots --tag=after`: docs/art/screens/polish_ysolde_<tag>_*.png then quit.
## `-- --compare`: stitches polish_ysolde_before_X | polish_ysolde_after_X into polish_ysolde_compare_X.png.
## `-- --stats` (headless ok): instance / vertex / light counts, hook sweep and the per-frame cost of 100 Ysoldes.

const YSOLDE := "res://art/units/wizards/ysolde.tscn"
const YSOLDE_BEFORE := "res://art/units/wizards/ysolde_before.tscn"   # A.14 snapshot of the 8.V3 model (removed after the compare)
const SCALE_UNITS: Array[String] = ["res://art/units/nature/thornling.tscn", "res://art/units/nature/sprigling.tscn"]
const WIZARDS: Array[String] = ["res://art/units/wizards/vessa.tscn", "res://art/units/wizards/malrik.tscn",
	"res://art/units/wizards/torvald.tscn"]
const WIZARD_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95)]
const NATURE := Color(0.35, 0.70, 0.25)
const CASTS: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
const PEAKS: Array = [[0.20, 0.40], [0.30, 0.70], [0.26, 0.58]]
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)   # plain grass, away from the paved lanes of the ground shader

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []        # untyped: hooks live on the model scripts
var _cast_i: int = 0
var _walking: bool = false
var _tag: String = "after"
var _path: String = YSOLDE


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--tag="):
			_tag = a.substr(6)
	if _tag == "before" and ResourceLoader.exists(YSOLDE_BEFORE):
		_path = YSOLDE_BEFORE
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	if "--compare" in args:
		_compare()
		get_tree().quit()
		return
	# The line-up: front, 3/4 back, side (walking), and two Nature soldiers for scale.
	_row.append(_spawn(_path, Vector3(-2.4, 0, 0), 0.0))
	_row.append(_spawn(_path, Vector3(-0.4, 0, 0), 200.0))
	_row.append(_spawn(_path, Vector3(1.6, 0, 0), 90.0))
	_row.append(_spawn(SCALE_UNITS[0], Vector3(3.3, 0, 0), 0.0))
	_row.append(_spawn(SCALE_UNITS[1], Vector3(4.6, 0, 0), 0.0))
	_row[2].set_moving(4.8)
	_set_zoom(25.0)
	if "--stats" in args:
		_stats()
	elif "--shots" in args:
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float, col: Color = NATURE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	# No random idle fidgets in the fixed shots (Ysolde, Torvald, Vessa name the timer differently).
	m.set(&"_idle_left", 1.0e9)
	m.set(&"_fidget_next", 1.0e9)
	if m.has_method(&"set_team_color"):
		m.set_team_color(col)
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
	var gmat: Material = load("res://art/environment/ground_material.tres") if ResourceLoader.exists("res://art/environment/ground_material.tres") else null
	if gmat == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.24, 0.27, 0.20)
		gmat = sm
	_ground.material_override = gmat
	add_child(_ground)


func _set_zoom(z: float, focus: Vector3 = Vector3(0.8, 0.0, 0.0), pitch_deg: float = 55.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	_cam.position = ORIGIN + focus + Vector3(0.0, sin(pitch) * z, cos(pitch) * z)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _set_zoom(6.0, Vector3(0.5, 1.2, 0))
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(45.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L: _all(&"play_level_up")
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m in _row:
				m.set_moving(4.8 if _walking else 0.0)
		KEY_C:
			for i: int in 3:
				_row[i].play_cast(CASTS[_cast_i])
			_cast_i = (_cast_i + 1) % 3


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	var p := "polish_ysolde_%s_" % _tag
	for z: float in [12.0, 25.0, 45.0]:
		_set_zoom(z)
		await _wait(0.6)
		var img := _save(p + "z%d" % int(z))
		# Crop around the line-up, upscaled so the far shots can be judged pixel by pixel.
		_crop(img, z, p + "z%d_crop" % int(z))
	# Close-ups: the game angle, then a low detail camera (not a game angle) on the face and crown.
	_set_zoom(6.0, Vector3(-1.4, 1.2, 0))
	await _wait(0.5)
	_save(p + "close")
	_set_zoom(3.4, Vector3(-2.4, 1.7, 0), 22.0)
	await _wait(0.4)
	_save(p + "detail")
	var rows: Array = [["attack", 0.12], ["thornburst", 0.20], ["thornburst", 0.42], ["wild_bloom", 0.60],
		["call_the_thicket", 0.30], ["call_the_thicket", 0.66]]
	await _pose_sheet(p + "poses_side", rows, 90.0, 28.0)
	await _pose_sheet(p + "poses_front", rows, 0.0, 55.0)
	await _anim_sheet(p + "anim")
	await _silhouettes(p + "sil")
	await _wizard_lineup(p + "wizards")
	await _cast_shot(p + "casts_z25")
	get_tree().quit()


## One frame per state, 2 Ysoldes (front + side), zoom 6.5: idle, walk, attack, 3 casts (2 frames each), hit,
## level-up, death (4), revived, idle fidgets (2).
func _anim_sheet(nm: String) -> void:
	for i: int in _row.size():
		_row[i].get_parent().visible = i < 2
	var a: Node3D = _row[0]
	var b: Node3D = _row[1]
	b.get_parent().rotation.y = deg_to_rad(90.0)
	b.get_parent().position = ORIGIN + Vector3(1.0, 0, 0)
	a.get_parent().position = ORIGIN + Vector3(-1.0, 0, 0)
	_set_zoom(6.5, Vector3(0.0, 1.2, 0))
	var pair: Array = [a, b]
	var frames: Array[Image] = []
	await _wait(0.5)
	frames.append(_grab())                       # idle
	for m in pair:
		m.set_moving(4.8)
	await _wait(0.7)
	frames.append(_grab())                       # walk
	for m in pair:
		m.set_moving(0.0)
	await _wait(0.5)
	for m in pair:
		m.play_attack()
	await _until(a, &"_action_t", 0.12)
	frames.append(_grab())                       # attack (release)
	await _wait(0.6)
	for c: int in 3:
		for m in pair:
			m.play_cast(CASTS[c])
		for t: float in PEAKS[c]:
			await _until(a, &"_action_t", t)
			frames.append(_grab())
		await _wait(1.2)
	for m in pair:
		m.play_hit()
	await _wait(0.05)
	frames.append(_grab())                       # hit
	await _wait(0.5)
	for m in pair:
		m.play_level_up()
	await _wait(0.15)
	frames.append(_grab())                       # level-up
	await _wait(0.6)
	for m in pair:
		m.play_death()
	for t: float in [0.2, 0.45, 0.7, 0.95]:
		await _until(a, &"_death_t", t)
		frames.append(_grab())
	await _wait(0.4)
	for m in pair:
		m.revive()
	await _wait(0.3)
	frames.append(_grab())                       # revived
	# Idle fidgets (the new model only; unknown ids play the thornburst on the old one).
	for f: Array in [[&"idle_bloom", 1.1], [&"idle_listen", 1.0], [&"idle_twirl", 0.7]]:
		await _wait(0.5)
		for m in pair:
			m.play_cast(f[0])
		await _until(a, &"_action_t", f[1])
		frames.append(_grab())
	_contact(frames, nm, Rect2i(320, 60, 960, 540))
	for i: int in _row.size():
		_row[i].get_parent().visible = true


## Key frames side by side: rows [kind, key_time]; each unit is started so all reach their key frame together.
func _pose_sheet(nm: String, rows: Array, yaw: float, pitch: float) -> void:
	for m in _row:
		m.get_parent().visible = false
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	for i: int in n:
		units.append(_spawn(_path, Vector3((float(i) - float(n - 1) * 0.5) * 2.3, 0, 0.0), yaw))
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(11.0, Vector3(0.0, 1.2, 0.0), pitch)
	await _wait(0.8)
	var order: Array = range(n)
	order.sort_custom(func(a: int, b: int) -> bool: return float(rows[a][1]) > float(rows[b][1]))
	var elapsed := 0.0
	for i: int in order:
		var start: float = t_max - float(rows[i][1])
		if start > elapsed:
			await _wait(start - elapsed)
			elapsed = start
		if rows[i][0] == "attack":
			units[i].play_attack()
		else:
			units[i].play_cast(StringName(rows[i][0]))
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_save(nm)
	await _wait(1.3)
	for m in units:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


## Unlit black on white (the "black test"), 3 facings at 25 and 45 m.
func _silhouettes(nm: String) -> void:
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
	var yaws: Array[float] = [0.0, 200.0, 90.0]
	var saved: Array = []
	for i: int in _row.size():
		var h: Node3D = _row[i].get_parent()
		h.visible = i < 3
		h.position = ORIGIN + Vector3(-2.0 + 2.0 * float(i), 0, 0)
		if i < 3:
			h.rotation.y = deg_to_rad(yaws[i])
			_row[i].set_moving(0.0)
		for g: Node in h.find_children("*", "GeometryInstance3D", true, false):
			saved.append([g, (g as GeometryInstance3D).material_override, (g as Node3D).visible])
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 45.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.4)
		imgs.append(_crop_img(_grab(), z))
	var w := imgs[0].get_width()
	var out := Image.create(w * 2, imgs[0].get_height(), false, imgs[0].get_format())
	out.blit_rect(imgs[0], Rect2i(Vector2i.ZERO, imgs[0].get_size()), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(Vector2i.ZERO, imgs[1].get_size()), Vector2i(w, 0))
	out.save_png(OUT + nm + ".png")
	for s: Array in saved:
		(s[0] as GeometryInstance3D).material_override = s[1]
		(s[0] as Node3D).visible = s[2]
	_ground.material_override = old_ground
	_env.environment = old_env
	for i: int in _row.size():
		_row[i].get_parent().visible = true


## The four wizards side by side (Vessa, Malrik, Torvald, Ysolde) at 25 m and 45 m, cropped.
func _wizard_lineup(nm: String) -> void:
	for m in _row:
		m.get_parent().visible = false
	var extra: Array = []
	for i: int in WIZARDS.size():
		if ResourceLoader.exists(WIZARDS[i]):
			extra.append(_spawn(WIZARDS[i], Vector3(-3.0 + 2.0 * float(i), 0, 30.0), 0.0, WIZARD_COLORS[i]))
	extra.append(_spawn(_path, Vector3(3.0, 0, 30.0), 0.0))
	var imgs: Array[Image] = []
	for z: float in [25.0, 45.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 30.0))
		await _wait(0.6)
		imgs.append(_crop_img(_grab(), z))
	var w := imgs[0].get_width()
	var out := Image.create(w * 2, imgs[0].get_height(), false, imgs[0].get_format())
	out.blit_rect(imgs[0], Rect2i(Vector2i.ZERO, imgs[0].get_size()), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(Vector2i.ZERO, imgs[1].get_size()), Vector2i(w, 0))
	out.save_png(OUT + nm + ".png")
	for m in extra:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


## The three casts side by side at 25 m, near their key frame (how they read in play).
func _cast_shot(nm: String) -> void:
	for i: int in _row.size():
		var h: Node3D = _row[i].get_parent()
		h.visible = i < 3
		h.rotation.y = deg_to_rad(20.0)
		h.position = ORIGIN + Vector3(-2.2 + 2.2 * float(i), 0, 0)
		_row[i].set_moving(0.0)
	_set_zoom(25.0, Vector3(0.0, 0.0, 0.0))
	await _wait(0.8)
	# Started so all three are near their strongest frame together.
	_row[1].play_cast(CASTS[1])
	await _wait(0.12)
	_row[2].play_cast(CASTS[2])
	await _wait(0.14)
	_row[0].play_cast(CASTS[0])
	await _wait(0.30)
	var img := _grab()
	_crop_img(img, 25.0).save_png(OUT + nm + ".png")
	await _wait(1.2)


func _crop(img: Image, z: float, nm: String) -> void:
	_crop_img(img, z).save_png(OUT + nm + ".png")


## Crop a window that keeps the same world size (~9 x 5 m) at every zoom, resized to 800 x 450.
func _crop_img(img: Image, z: float) -> Image:
	var w: int = clampi(int(1600.0 * 12.0 / z * 0.62), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var cx: int = 800
	var cy: int = 450 - int(h * 0.1)
	var r := Rect2i(clampi(cx - w / 2, 0, 1600 - w), clampi(cy - h / 2, 0, 900 - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST if z > 20.0 else Image.INTERPOLATE_BILINEAR)
	return c


func _contact(imgs: Array[Image], nm: String, crop: Rect2i = Rect2i()) -> void:
	if crop.size != Vector2i.ZERO:
		for i: int in imgs.size():
			imgs[i] = imgs[i].get_region(crop)
			imgs[i].resize(1600, 900)
	var cols := 4
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


func _save(nm: String) -> Image:
	var img := _grab()
	img.save_png(OUT + nm + ".png")
	return img


# ---------------------------------------------------------------- before | after

func _compare() -> void:
	for s: String in ["z12_crop", "z25_crop", "z45_crop", "close", "detail", "anim", "sil", "wizards", "casts_z25"]:
		var a := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_ysolde_before_%s.png" % s))
		var b := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_ysolde_after_%s.png" % s))
		if a == null or b == null or a.is_empty() or b.is_empty():
			print("compare: missing ", s)
			continue
		if s == "close" or s == "anim" or s == "detail":
			a.resize(a.get_width() / 2, a.get_height() / 2)
			b.resize(b.get_width() / 2, b.get_height() / 2)
		var vertical := s == "wizards" or s == "sil"
		var gap := 8
		var out: Image
		a.convert(Image.FORMAT_RGBA8)
		b.convert(Image.FORMAT_RGBA8)
		if vertical:
			out = Image.create(maxi(a.get_width(), b.get_width()), a.get_height() + b.get_height() + gap, false, Image.FORMAT_RGBA8)
			out.fill(Color.WHITE)
			out.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
			out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(0, a.get_height() + gap))
		else:
			out = Image.create(a.get_width() + b.get_width() + gap, maxi(a.get_height(), b.get_height()), false, Image.FORMAT_RGBA8)
			out.fill(Color.WHITE)
			out.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
			out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(a.get_width() + gap, 0))
		out.save_png(ProjectSettings.globalize_path(OUT + "polish_ysolde_compare_%s.png" % s))
		print("compare: wrote ", s)


# ---------------------------------------------------------------- stats (headless ok)

func _stats() -> void:
	await _wait(0.3)
	var m: Node3D = _row[0]
	var inst := 0
	var verts := 0
	var sep := 0
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		inst += 1
		if n.name != "Merged" and n.name != "Shadow":
			sep += 1
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mesh := (n as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				verts += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		elif n is MultiMeshInstance3D:
			var mm := (n as MultiMeshInstance3D).multimesh
			var mv := 0
			for s: int in mm.mesh.get_surface_count():
				mv += (mm.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			verts += mv * mm.instance_count
	print("Ysolde (", _path.get_file(), "): draw instances ", inst, " (not merged ", sep, "), vertices ", verts,
		", lights ", m.find_children("*", "Light3D", true, false).size(),
		", particles ", m.find_children("*", "GPUParticles3D", true, false).size())
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var nv := 0
		var surf := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			surf = (n as MeshInstance3D).mesh.get_surface_count()
			for s: int in surf:
				nv += ((n as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  ", m.get_path_to(n), "  ", n.get_class(), "  surfaces ", surf, "  verts ", nv)
	# Hook sweep: every hook once, death_finished, revive.
	var ok := true
	for s: StringName in CASTS:
		m.play_cast(s)
		await _wait(1.2)
	m.play_attack()
	await _wait(0.5)
	m.play_hit()
	m.play_level_up()
	m.set_status(&"haste", true)
	await _wait(0.5)
	m.set_status(&"haste", false)
	m.set_team_color(Color(0.8, 0.2, 0.2))
	m.set_team_color(NATURE)
	var got := [false]
	m.death_finished.connect(func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.play_death()
	await _wait(1.3)
	ok = ok and got[0]
	m.revive()
	await _wait(0.2)
	ok = ok and absf(m.get_node("Root").position.y) < 0.05 and m.is_processing()
	# Cost: 100 Ysoldes (half walking), headless = middle tier.
	var bench: Array[Node3D] = []
	for k: int in 100:
		var b: Node3D = load(_path).instantiate()
		b.position = Vector3(float(k % 10) * 1.5, 0, 12.0 + float(k / 10) * 1.5)
		add_child(b)
		b.call(&"set_moving", 4.8 if k % 2 == 0 else 0.0)
		bench.append(b)
	await _wait(0.5)
	var acc := 0.0
	var frames := 0
	while frames < 120:
		await get_tree().process_frame
		acc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	print("100 Ysoldes: avg TIME_PROCESS %.3f ms / frame" % (acc / frames * 1000.0))
	print("YSOLDE STATS OK" if ok else "YSOLDE STATS FAILED")
	get_tree().quit()
