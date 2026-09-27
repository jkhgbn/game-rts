extends Node3D
## Vessa polish preview (task A.1): the Fire wizard from the RTS camera (pitch 55, fov 50) at 12 / 25 / 45 m.
## Keys: 1-5 zoom 6 / 12 / 25 / 45 / 55 · A attack · C cast cycle (fireball, ember_step, kindle) · H hit · D death
## R revive · L level-up · W walk toggle · Y spin the facing.
## `-- --shots --tag=after`: docs/art/screens/polish_vessa_<tag>_*.png then quit.
## `-- --compare`: stitches polish_vessa_before_X | polish_vessa_after_X into polish_vessa_compare_X.png.
## `-- --stats` (headless ok): instance / vertex / light counts and the per-frame animation cost of 100 Vessas.

const VESSA := "res://art/units/wizards/vessa.tscn"
const VESSA_BEFORE := "res://art/units/wizards/vessa_before.tscn"   # temporary, only while A.1 compares
const GUARD :="res://art/units/fire/flame_guard.tscn"
const CASTS: Array[StringName] = [&"fireball", &"ember_step", &"kindle"]
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)   # plain grass, away from the paved lanes of the ground shader

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []        # untyped: hooks live on the model scripts
var _cast_i: int = 0
var _walking: bool = false
var _tag: String = "after"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--tag="):
			_tag = a.substr(6)
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
	# The line-up: front, 3/4 back, side (walking), and a Flame Guard for scale.
	var vp := VESSA
	if _tag == "before" and ResourceLoader.exists(VESSA_BEFORE):
		vp = VESSA_BEFORE
	_row.append(_spawn(vp, Vector3(-2.4, 0, 0), 0.0))
	_row.append(_spawn(vp, Vector3(-0.4, 0, 0), 200.0))
	_row.append(_spawn(vp, Vector3(1.6, 0, 0), 90.0))
	_row.append(_spawn(GUARD, Vector3(3.4, 0, 0), 0.0))
	_row[2].set_moving(4.6)
	_set_zoom(25.0)
	if "--stats" in args:
		_stats()
	elif "--shots" in args:
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # like Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	m.set(&"_fidget_next", 1.0e9)   # no random idle fidgets in the fixed shots
	if m.has_method(&"set_team_color"):
		m.set_team_color(Color(0.85, 0.30, 0.12))
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


func _set_zoom(z: float, focus: Vector3 = Vector3(0.5, 0.0, 0.0)) -> void:
	var pitch := deg_to_rad(55.0)
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
				m.set_moving(4.6 if _walking else 0.0)
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
	var p := "polish_vessa_%s_" % _tag
	for z: float in [12.0, 25.0, 45.0]:
		_set_zoom(z)
		await _wait(0.6)
		var img := _save(p + "z%d" % int(z))
		# Crop around the line-up, upscaled so the far shots can be judged pixel by pixel.
		_crop(img, z, p + "z%d_crop" % int(z))
	# Close-up (front + 3/4 back).
	_set_zoom(6.0, Vector3(-1.4, 1.2, 0))
	await _wait(0.5)
	_save(p + "close")
	await _anim_sheet(p + "anim")
	await _silhouettes(p + "sil")
	get_tree().quit()


## One frame per state, 2 Vessas (front + side), zoom 9: idle, walk, attack, 3 casts (2 frames each), hit, level-up, death.
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
		m.set_moving(4.6)
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
	var peaks: Array = [[0.18, 0.32], [0.12, 0.30], [0.30, 0.62]]
	for c: int in 3:
		for m in pair:
			m.play_cast(CASTS[c])
		for t: float in peaks[c]:
			await _until(a, &"_action_t", t)
			frames.append(_grab())
		await _wait(1.0)
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
	# Idle fidgets (the new model only; unknown ids play the fireball on the old one).
	for f: StringName in [&"_idle_flame", &"_idle_staff"]:
		await _wait(0.5)
		for m in pair:
			m.play_cast(f)
		await _until(a, &"_action_t", 1.0 if f == &"_idle_flame" else 0.9)
		frames.append(_grab())
	_contact(frames, nm, Rect2i(320, 60, 960, 540))


## Unlit black on white (the "black test"), 3 facings at 25 and 45 m.
func _silhouettes(nm: String) -> void:
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
	_env.environment = e
	var yaws: Array[float] = [0.0, 200.0, 90.0]
	for i: int in _row.size():
		var h: Node3D = _row[i].get_parent()
		h.visible = i < 3
		h.position = ORIGIN + Vector3(-2.0 + 2.0 * float(i), 0, 0)
		if i < 3:
			h.rotation.y = deg_to_rad(yaws[i])
			_row[i].set_moving(0.0)
		for g: Node in h.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	var imgs: Array[Image] = []
	for z: float in [25.0, 45.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 0.0))
		await _wait(0.4)
		var img := _grab()
		var c := _crop_img(img, z)
		imgs.append(c)
	var w := imgs[0].get_width()
	var out := Image.create(w * 2, imgs[0].get_height(), false, imgs[0].get_format())
	out.blit_rect(imgs[0], Rect2i(Vector2i.ZERO, imgs[0].get_size()), Vector2i.ZERO)
	out.blit_rect(imgs[1], Rect2i(Vector2i.ZERO, imgs[1].get_size()), Vector2i(w, 0))
	out.save_png(OUT + nm + ".png")


func _crop(img: Image, z: float, nm: String) -> void:
	_crop_img(img, z).save_png(OUT + nm + ".png")


## Crop a window that keeps the same world size (~9 x 5 m) at every zoom, resized to 800 x 450.
func _crop_img(img: Image, z: float) -> Image:
	var w: int = clampi(int(1600.0 * 12.0 / z * 0.62), 80, 1600)
	var h: int = int(float(w) * 9.0 / 16.0)
	var cx: int = 800 + int(0.5 * 1600.0 * 12.0 / z * 0.06)
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
	for s: String in ["z12_crop", "z25_crop", "z45_crop", "close", "anim", "sil"]:
		var a := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_vessa_before_%s.png" % s))
		var b := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_vessa_after_%s.png" % s))
		if a == null or b == null or a.is_empty() or b.is_empty():
			print("compare: missing ", s)
			continue
		if s == "close" or s == "anim":
			a.resize(a.get_width() / 2, a.get_height() / 2)
			b.resize(b.get_width() / 2, b.get_height() / 2)
		var gap := 8
		var out := Image.create(a.get_width() + b.get_width() + gap, maxi(a.get_height(), b.get_height()), false, Image.FORMAT_RGBA8)
		out.fill(Color.WHITE)
		a.convert(Image.FORMAT_RGBA8)
		b.convert(Image.FORMAT_RGBA8)
		out.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
		out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(a.get_width() + gap, 0))
		out.save_png(ProjectSettings.globalize_path(OUT + "polish_vessa_compare_%s.png" % s))
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
	print("Vessa: draw instances ", inst, " (not merged ", sep, "), vertices ", verts,
		", lights ", m.find_children("*", "Light3D", true, false).size(),
		", particles ", m.find_children("*", "GPUParticles3D", true, false).size())
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var nv := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			for s: int in (n as MeshInstance3D).mesh.get_surface_count():
				nv += ((n as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  ", m.get_path_to(n), "  verts ", nv)
	# Hook sweep: every hook once, death_finished, revive.
	var ok := true
	for s: StringName in CASTS:
		m.play_cast(s)
		await _wait(1.0)
	m.play_attack()
	await _wait(0.5)
	m.play_hit()
	m.play_level_up()
	await _wait(0.5)
	var got := [false]
	m.death_finished.connect(func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.play_death()
	await _wait(1.3)
	ok = ok and got[0]
	m.revive()
	await _wait(0.2)
	ok = ok and absf(m.get_node("Root").position.y) < 0.05 and m.is_processing()
	# Cost: 100 Vessas (half walking), headless = middle tier.
	var bench: Array[Node3D] = []
	for k: int in 100:
		var b: Node3D = load(VESSA_BEFORE if _tag == "before" else VESSA).instantiate()
		b.position = Vector3(float(k % 10) * 1.5, 0, 12.0 + float(k / 10) * 1.5)
		add_child(b)
		b.call(&"set_moving", 4.6 if k % 2 == 0 else 0.0)
		bench.append(b)
	await _wait(0.5)
	var acc := 0.0
	var frames := 0
	var t0 := Time.get_ticks_usec()
	while frames < 240:
		await get_tree().process_frame
		acc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	print("100 Vessas (%s): avg TIME_PROCESS %.3f ms, wall %.3f ms / frame" % [_tag, acc / frames * 1000.0, (Time.get_ticks_usec() - t0) / 1000.0 / frames])
	print("VESSA STATS OK" if ok else "VESSA STATS FAILED")
	get_tree().quit()
