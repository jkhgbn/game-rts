extends Node3D
## Grizzlemaw preview (task 12.V30) from the RTS camera (pitch 55, fov 50) and detail angles. A (left) and the Elder
## (B, right) side by side.
## Keys: 1-5 zoom 6 / 12 / 25 / 40 / 55 · A attack · M maul · C rending roar · E enrage toggle · F fidget · H hit
## · D death · R revive · W walk toggle · Y spin the facing.
## Windowed `-- --shots`: docs/art/screens/12_v30_*.png then quit.

const SCENE := "res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references for the lineup (skipped when missing): other big beasts and a soldier for scale.
const COMPARE: Array[String] = ["res://art/units/neutral/hollow_stag/hollow_stag.tscn",
	"res://art/units/neutral/beasts/tusker/tusker.tscn", "res://art/units/nature/bramblehorn.tscn",
	"res://art/units/neutral/bristleback/bristleback.tscn", "res://art/units/fire/flame_guard.tscn"]
const DEN := "res://art/environment/lairs/old_wood_den.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _walking: bool = false
var _rage: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-2.4, 0, 0), 30.0, 0))
	_row.append(_spawn(Vector3(2.6, 0, 0), 30.0, 1))
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, variant: int = 0, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	if path == SCENE:
		m.call(&"set_variant", variant)
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
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


func _set_zoom(z: float, focus: Vector3 = Vector3(0.0, 0.0, 0.0), pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0.0, sin(pitch) * z, cos(pitch) * z).rotated(Vector3.UP, yaw)
	_cam.position = ORIGIN + focus + off
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(7.0, Vector3(0, 1.2, 0), 20.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_F: _all(&"play_fidget")
		KEY_M: _all(&"play_cast", [&"maul"])
		KEY_C: _all(&"play_cast", [&"rending_roar"])
		KEY_E:
			_rage = not _rage
			_all(&"set_enraged", [_rage])
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			_all(&"set_moving", [5.0 if _walking else 0.0])


func _all(method: StringName, args: Array = []) -> void:
	for m in _row:
		if m.has_method(method):
			m.callv(method, args)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(0.0, 1.0, 0.0), 13.0 if z < 30.0 else 16.0).save_png(OUT + "12_v30_z%d.png" % int(z))
	_set_zoom(40.0)
	await _wait(0.3)
	_grab().save_png(OUT + "12_v30_game_40m.png")
	await _ab_sheet("12_v30_ab_40m")
	await _detail_sheet("12_v30_detail_a", 0)
	await _detail_sheet("12_v30_detail_b", 1)
	await _heads("12_v30_heads")
	await _pose_sheet("12_v30_poses_side", 90.0, 12.0, 0)
	await _pose_sheet("12_v30_poses_game", 30.0, 55.0, 1)
	await _anim_sheet("12_v30_anim")
	await _silhouettes("12_v30_silhouette")
	await _lineup("12_v30_lineup", false)
	await _lineup("12_v30_lineup_black", true)
	await _den("12_v30_den")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m in _row:
		m.get_parent().visible = not on


## THE A / B contact sheet: the two variants at 40 m game camera in colour (facing 3 ways), then the same as unlit
## black silhouettes, then both roaring. They must read apart (B: bigger, silver back, white face, chain).
func _ab_sheet(nm: String) -> void:
	_hide_row(true)
	var units: Array = []
	var c := Vector3(0.0, 0.0, 150.0)
	var yaws: Array[float] = [30.0, 150.0, 270.0]
	for i: int in 3:
		for v: int in 2:
			units.append(_spawn(c + Vector3(-6.0 + 6.0 * float(i), 0.0, -2.6 + 5.2 * float(v)), yaws[i], v))
	await _wait(0.6)
	var imgs: Array[Image] = []
	_set_zoom(40.0, c)
	await _wait(0.4)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.0, 0), 22.0))
	for u in units:
		u.play_cast(&"rending_roar")
	await _wait(0.6)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.0, 0), 22.0))
	await _wait(1.6)
	var old := _black_world(true, [])
	for u in units:
		_blacken(u)
	await _wait(0.2)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.0, 0), 22.0))
	_black_world(false, old)
	_strip(imgs, nm, Color.WHITE, true)
	for u in units:
		u.get_parent().queue_free()
	_hide_row(false)


## One bear alone, close: front, 3/4 front, side, back, 3/4 back from above, game angle 55 deg.
func _detail_sheet(nm: String, variant: int) -> void:
	_hide_row(true)
	var u := _spawn(Vector3(0, 0, 80.0), 0.0, variant)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	var k := 1.15 if variant == 1 else 1.0
	for f: Array in [[0.0, 8.0, 7.0], [35.0, 14.0, 7.0], [90.0, 6.0, 7.5], [180.0, 12.0, 7.0], [215.0, 30.0, 7.5],
			[25.0, 55.0, 9.0]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]) * k, Vector3(0, 1.2 * k, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
	_sheet(frames, nm, 3, 480, 440)
	h.queue_free()
	_hide_row(false)


## The two heads close up (3/4 front and side): the white muzzle, chain, bones, torn ear; the enraged red eyes.
func _heads(nm: String) -> void:
	_hide_row(true)
	var frames: Array[Image] = []
	for v: int in 2:
		var u := _spawn(Vector3(0, 0, 90.0), 0.0, v)
		var h: Node3D = u.get_parent()
		await _wait(0.4)
		var k := 1.15 if v == 1 else 1.0
		for f: Array in [[30.0, 12.0, 3.2], [90.0, 6.0, 3.6]]:
			h.rotation.y = deg_to_rad(float(f[0]))
			_set_zoom(float(f[2]) * k, Vector3(0.0, 1.5 * k, 90.0 + 1.2 * k), float(f[1]))
			await _wait(0.25)
			frames.append(_center_crop(_grab()))
		u.set_enraged(true)
		h.rotation.y = deg_to_rad(20.0)
		_set_zoom(3.0 * k, Vector3(0.0, 1.5 * k, 90.0 + 1.3 * k), 10.0)
		await _wait(0.8)
		frames.append(_center_crop(_grab()))
		h.queue_free()
		await _wait(0.1)
	_sheet(frames, nm, 3, 480, 440)
	_hide_row(false)


## Key frames side by side: rest, walk, swipe windup / strike, maul, roar rear / slam, fidget, death.
func _pose_sheet(nm: String, yaw: float, pitch: float, variant: int) -> void:
	_hide_row(true)
	var rows: Array = [["rest", 0.0], ["walk", 0.4], ["attack", 0.08], ["attack", 0.14], ["maul", 0.09],
		["roar", 0.6], ["roar", 1.25], ["fidget", 1.0], ["death", 0.3], ["death", 0.9]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	var gap := 3.7 if yaw > 60.0 else 4.2
	for i: int in n:
		var u := _spawn(Vector3((float(i) - float(n - 1) * 0.5) * gap, 0, 24.0), yaw, variant)
		units.append(u)
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(21.0 if pitch < 30.0 else 36.0, Vector3(0.0, 1.6, 24.0), pitch)
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
				units[i].set_moving(5.0)
			"attack":
				units[i].play_attack()
			"maul":
				units[i].play_cast(&"maul")
			"roar":
				units[i].play_cast(&"rending_roar")
			"fidget":
				units[i].play_fidget()
			"death":
				units[i].play_death()
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_grab().save_png(OUT + nm + ".png")
	await _wait(1.6)
	for m in units:
		m.get_parent().queue_free()
	_hide_row(false)


## One frame per state (A front 3/4 + B side): idle, walk, hit, swipe, maul, roar, slam, enraged, death 0.4 / 0.9.
func _anim_sheet(nm: String) -> void:
	_hide_row(true)
	var a := _spawn(Vector3(-2.6, 0, 36.0), 30.0, 0)
	var b := _spawn(Vector3(2.8, 0, 36.0), 90.0, 1)
	var pair: Array = [a, b]
	_set_zoom(15.0, Vector3(0.0, 1.2, 36.0), 35.0)
	var frames: Array[Image] = []
	await _wait(0.6)
	frames.append(_grab())
	for m in pair:
		m.set_moving(5.0)
	await _wait(0.55)
	frames.append(_grab())
	for m in pair:
		m.set_moving(0.0)
	await _wait(0.5)
	for m in pair:
		m.play_hit()
	await _wait(0.06)
	frames.append(_grab())
	await _wait(0.6)
	for m in pair:
		m.play_attack()
	await _wait(0.13)
	frames.append(_grab())
	await _wait(1.0)
	for m in pair:
		m.play_cast(&"maul")
	await _wait(0.1)
	frames.append(_grab())
	await _wait(1.2)
	for m in pair:
		m.play_cast(&"rending_roar")
	await _wait(0.55)
	frames.append(_grab())
	await _wait(0.72)
	frames.append(_grab())
	await _wait(0.8)
	for m in pair:
		m.set_enraged(true)
	await _wait(0.8)
	frames.append(_grab())
	for m in pair:
		m.play_death()
	for t: float in [0.4, 0.9]:
		await _until(a, &"_death_t", t)
		frames.append(_grab())
	await _wait(0.4)
	_contact(frames, nm, 5, Rect2i(200, 40, 1200, 675))
	for m in pair:
		m.get_parent().queue_free()
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


## Unlit black on white (the "black test"): A and B front 3/4, side, back 3/4, walking; 25 m and 40 m; then roaring.
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	_hide_row(true)
	var sil: Array = []
	var yaws: Array[float] = [20.0, 90.0, 200.0, 60.0]
	for i: int in 4:
		for v: int in 2:
			sil.append(_spawn(Vector3(-6.3 + 4.2 * float(i), 0, 48.0 - 2.5 + 5.0 * float(v)), yaws[i], v))
	await _wait(0.4)
	for u in sil:
		_blacken(u)
	sil[6].set_moving(5.0)
	sil[7].set_moving(5.0)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 1.0, 48.0)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 48.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 19.0))
	for u in sil:
		u.set_moving(0.0)
		u.play_cast(&"rending_roar")
	await _wait(0.6)
	imgs.append(_crop_world(_grab(), centre, 19.0))
	_strip(imgs, nm, Color(0.8, 0.8, 0.8), false)
	await _wait(1.5)
	for m in sil:
		m.get_parent().queue_free()
	_black_world(false, old)
	_hide_row(false)


## Scale and look: A, B, then the Hollow Stag, the Tusker (12.V27), a Bramblehorn, a Bristleback and a Flame Guard,
## at 25 and 40 m. black: the same row as unlit silhouettes.
func _lineup(nm: String, black: bool) -> void:
	_hide_row(true)
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var xs: Array[float] = [-9.6, -5.2, -0.6, 3.6, 7.2, 10.0, 12.0]
	var paths: Array[String] = [SCENE, SCENE]
	paths.append_array(COMPARE)
	var yaws: Array[float] = [60.0, 60.0, 60.0, 60.0, 60.0, 50.0, 40.0]
	for i: int in paths.size():
		if ResourceLoader.exists(paths[i]):
			var u := _spawn(Vector3(xs[i], 0, 60.0), yaws[i], 1 if i == 1 else 0, paths[i])
			holders.append(u.get_parent())
	await _wait(0.5)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(1.2, 0.0, 60.0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(1.2, 1.0, 60.0), 25.0))
	_strip(imgs, nm, Color.WHITE, false)
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	_hide_row(false)


## In context: the Old Wood Den (12.V32, when it exists), the Elder at its mouth, a squad of Flame Guards closing in;
## 25 m, 40 m, then the Rending Roar at 40 m.
func _den(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(0.0, 0.0, 130.0)
	var extra: Array = []
	if ResourceLoader.exists(DEN):
		var site: Node3D = load(DEN).instantiate()
		site.position = ORIGIN + c
		add_child(site)
		extra.append(site)
	var s := _spawn(c + Vector3(0.0, 0.0, 1.0), 20.0, 1)
	extra.append(s.get_parent())
	var s2 := _spawn(c + Vector3(-7.0, 0.0, 2.0), 60.0, 0)
	extra.append(s2.get_parent())
	if ResourceLoader.exists(GUARD):
		for k: int in 7:
			var a := -0.7 + 0.35 * float(k)
			var g := _spawn(c + Vector3(1.0 + sin(a) * 4.4, 0, 1.0 + cos(a) * 4.4), rad_to_deg(a) + 180.0, 0, GUARD)
			extra.append(g.get_parent())
	await _wait(0.6)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c + Vector3(-2.0, 0, 0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(-2.0, 0.8, 0), 17.0))
	s.play_cast(&"rending_roar")
	s2.play_cast(&"maul")
	await _wait(0.6)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(-2.0, 0.8, 0), 17.0))
	_strip(imgs, nm, Color.WHITE, false)
	for e in extra:
		e.queue_free()
	_hide_row(false)


## Images side by side with an 8 px gap (vertical = stacked).
func _strip(imgs: Array[Image], nm: String, bg: Color, vertical: bool) -> void:
	var w := imgs[0].get_width()
	var h := imgs[0].get_height()
	var n := imgs.size()
	var out := Image.create(w if vertical else w * n + 8 * (n - 1), h * n + 8 * (n - 1) if vertical else h, false,
		imgs[0].get_format())
	out.fill(bg)
	for i: int in n:
		var at := Vector2i(0, (h + 8) * i) if vertical else Vector2i((w + 8) * i, 0)
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), at)
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


func _center_crop(img: Image) -> Image:
	var h := int(img.get_height() * 0.8)
	var w := mini(int(h * 12.0 / 11.0), img.get_width())
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _contact(imgs: Array[Image], nm: String, cols: int, crop: Rect2i = Rect2i()) -> void:
	if crop.size != Vector2i.ZERO:
		for i: int in imgs.size():
			var cr := Rect2i(crop.position, Vector2i(mini(crop.size.x, imgs[i].get_width() - crop.position.x),
				mini(crop.size.y, imgs[i].get_height() - crop.position.y)))
			imgs[i] = imgs[i].get_region(cr)
			imgs[i].resize(1120, 630)
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
