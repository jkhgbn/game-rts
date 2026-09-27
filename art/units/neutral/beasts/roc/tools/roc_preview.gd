extends Node3D
## Roc preview (task 12.V28) from the RTS camera (pitch 55, fov 50) and detail angles. Windowed:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1600x900 res://art/units/neutral/beasts/roc/tools/roc_preview.tscn -- --shots
## writes docs/art/screens/12_v28_*.png then quits (add --only=<name> for one sheet).
## Keys: 1-5 zoom 6 / 12 / 25 / 40 / 55 · A attack · G gale_swoop · S shrieking_dive · U updraft (+ shroud 4 s) · H hit
## · D death · R revive · W glide toggle · T turn toggle · V swap variants.

const SCENE := "res://art/units/neutral/beasts/roc/roc.tscn"
const OUT := "res://docs/art/screens/"
const PREFIX := "12_v28_"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references for the lineup (skipped when missing).
const COMPARE: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/neutral/hollow_stag/hollow_stag.tscn",
	"res://art/units/neutral/bristleback/bristleback.tscn", "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"]
const GUARD := "res://art/units/fire/flame_guard.tscn"

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _moving: bool = false
var _turning: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-3.8, 0, 0), 20.0, 0))
	_row.append(_spawn(Vector3(3.8, 0, 0), -20.0, 1))
	_set_zoom(16.0, Vector3(0.0, 2.0, 0.0))
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		var only := ""
		for a: String in args:
			if a.begins_with("--only="):
				only = a.substr(7)
		_take_shots(only)


func _process(delta: float) -> void:
	if _turning:
		for m: Node3D in _row:
			m.get_parent().rotation.y += deg_to_rad(90.0) * delta


func _spawn(at: Vector3, yaw_deg: float, variant: int, path: String = SCENE) -> Node3D:
	var m: Node3D = load(path).instantiate()
	if variant >= 0 and m.has_method(&"set_variant"):
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
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(500, 500)
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
		KEY_1: _set_zoom(7.0, Vector3(-3.8, 2.4, 0), 15.0)
		KEY_2: _set_zoom(12.0, Vector3(0, 2.0, 0))
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_G: _cast(&"gale_swoop")
		KEY_S: _cast(&"shrieking_dive")
		KEY_U:
			_cast(&"updraft")
			for m in _row:
				m.set_status(&"shroud", true)
			await _wait(4.0)
			for m in _row:
				m.set_status(&"shroud", false)
		KEY_W:
			_moving = not _moving
			for m in _row:
				m.set_moving(5.0 if _moving else 0.0)
		KEY_T:
			_turning = not _turning
		KEY_V:
			for m in _row:
				m.set_variant(1 - int(m.get_variant()))


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


func _cast(id: StringName) -> void:
	for m in _row:
		m.play_cast(id)


# ---------------------------------------------------------------- screenshots

func _take_shots(only: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	var all := only == ""
	if all or only == "zoom":
		for z: float in [12.0, 25.0, 40.0]:
			_set_zoom(z, Vector3(0.0, 0.0, 0.0))
			await _wait(0.5)
			_crop_world(_grab(), ORIGIN + Vector3(0.0, 1.6, 0.0), 16.0 if z < 30.0 else 20.0).save_png(OUT + PREFIX + "z%d.png" % int(z))
		_set_zoom(40.0)
		await _wait(0.3)
		_grab().save_png(OUT + PREFIX + "game_40m.png")
	if all or only == "ab":
		await _ab_sheet(PREFIX + "ab_40m")
	if all or only == "detail":
		await _detail_sheet(PREFIX + "detail_a", 0)
		await _detail_sheet(PREFIX + "detail_b", 1)
	if all or only == "poses":
		await _pose_sheet(PREFIX + "poses_side", 90.0, 8.0)
		await _pose_sheet(PREFIX + "poses_game", 30.0, 55.0)
	if all or only == "sil":
		await _silhouettes(PREFIX + "silhouette")
	if all or only == "lineup":
		await _lineup(PREFIX + "lineup", false)
		await _lineup(PREFIX + "lineup_black", true)
	if all or only == "fight":
		await _fight(PREFIX + "fight")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m in _row:
		m.get_parent().visible = not on


func _force_glide(m: Node3D) -> void:
	m.set(&"_gliding", true)
	m.set(&"_glide_left", 99.0)
	m.set(&"_flap_amp_w", 0.0)


## A / B contact sheet at the game camera: top row colour at 25 m and 40 m, bottom row the same as black silhouettes.
## Each frame: A gliding, B gliding, A hovering (beat), B hovering, side by side 6 m apart.
func _ab_sheet(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(-20.0, 0.0, -30.0)   # world (0, 0, -10): on the map ground
	var ms: Array = []
	var xs: Array[float] = [-10.5, -3.5, 3.5, 10.5]
	var vs: Array[int] = [0, 1, 0, 1]
	var yaws: Array[float] = [-30.0, -30.0, 150.0, 150.0]
	for i: int in 4:
		ms.append(_spawn(c + Vector3(xs[i], 0, 0), yaws[i], vs[i]))
	await _wait(0.5)
	for i: int in 2:
		ms[i].set_moving(5.0)
		_force_glide(ms[i])
	await _wait(1.0)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c)
		await _wait(0.35)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.5, 0), 30.0))
	var old := _black_world(true, [])
	for m in ms:
		_blacken(m.get_parent())
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c)
		await _wait(0.35)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.5, 0), 30.0))
	_black_world(false, old)
	_grid_sheet(imgs, nm, 2, Color(0.8, 0.8, 0.8))
	for m in ms:
		m.get_parent().queue_free()
	_hide_row(false)


## One roc alone, close: front, 3/4 front, side, back from above, underside (3/4 from below), game angle 55 deg.
func _detail_sheet(nm: String, variant: int) -> void:
	_hide_row(true)
	var c := Vector3(-20.0 + 30.0 * float(variant), 0, -20.0)
	var u := _spawn(c, 0.0, variant)
	var h: Node3D = u.get_parent()
	_force_glide(u)
	var frames: Array[Image] = []
	await _wait(0.6)
	for f: Array in [[0.0, 10.0, 7.5], [35.0, 18.0, 8.0], [90.0, 4.0, 8.0], [200.0, 40.0, 8.5], [30.0, -22.0, 8.0],
			[25.0, 55.0, 10.0]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), c + Vector3(0, 2.5, 0), float(f[1]))
		await _wait(0.3)
		frames.append(_center_crop(_grab()))
	_sheet(frames, nm, 3, 540, 440)
	h.queue_free()
	_hide_row(false)


## Key frames side by side: hover, glide, beat down, attack strike, swoop up / dive / impact, shriek, updraft launch,
## death fall / crash.
func _pose_sheet(nm: String, yaw: float, pitch: float) -> void:
	_hide_row(true)
	var rows: Array = [["hover", 0.0, 0], ["glide", 0.0, 0], ["attack", 0.16, 0], ["gale", 0.14, 0], ["gale", 0.4, 0],
		["gale", 0.54, 0], ["shriek", 0.47, 1], ["updraft", 0.3, 0], ["death", 0.5, 1], ["death", 1.1, 0]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	var gap := 4.2 if yaw > 60.0 else 5.0
	var c := Vector3(0, 0, 24.0)
	for i: int in n:
		var u := _spawn(c + Vector3((float(i) - float(n - 1) * 0.5) * gap, 0, 0), yaw, int(rows[i][2]))
		units.append(u)
		t_max = maxf(t_max, float(rows[i][1]))
	if pitch < 30.0:
		_set_zoom(30.0, c + Vector3(0.0, 2.2, 0), pitch)
	else:
		_set_zoom(34.0, c + Vector3(0.0, 1.0, 0), pitch)
	await _wait(0.8)
	units[1].set_moving(5.0)
	_force_glide(units[1])
	var order: Array = range(n)
	order.sort_custom(func(a: int, b: int) -> bool: return float(rows[a][1]) > float(rows[b][1]))
	var elapsed := 0.0
	for i: int in order:
		var start: float = t_max - float(rows[i][1])
		if start > elapsed:
			await _wait(start - elapsed)
			elapsed = start
		match String(rows[i][0]):
			"attack":
				units[i].play_attack()
			"gale":
				units[i].play_cast(&"gale_swoop")
			"shriek":
				units[i].play_cast(&"shrieking_dive")
			"updraft":
				units[i].play_cast(&"updraft")
			"death":
				units[i].play_death()
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_grab().save_png(OUT + nm + ".png")
	await _wait(0.3)
	for m in units:
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


## Unlit black on white (the "black test"): gliding 3/4, hovering front, side, banking; 25 m and 40 m; then the dive.
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	_hide_row(true)
	var sil: Array = []
	var yaws: Array[float] = [20.0, 180.0, 90.0, 60.0]
	var c := Vector3(0, 0, 48.0)
	for i: int in 4:
		var u := _spawn(c + Vector3(-10.5 + 7.0 * float(i), 0, 0), yaws[i], i % 2)
		sil.append(u)
	await _wait(0.4)
	for u in sil:
		_blacken(u.get_parent())
	sil[0].set_moving(5.0)
	_force_glide(sil[0])
	sil[3].set_moving(5.0)
	sil[3].set_turning(120.0)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c)
		sil[3].set_turning(120.0)
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.5, 0), 30.0))
	for u in sil:
		u.play_cast(&"gale_swoop")
	await _wait(0.42)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.5, 0), 30.0))
	_strip(imgs, nm, Color(0.8, 0.8, 0.8))
	await _wait(1.0)
	for m in sil:
		m.get_parent().queue_free()
	_black_world(false, old)
	_hide_row(false)


## Scale and look: the two rocs next to a Flame Guard, a Hollow Stag, a Bristleback and the Cinder Dragon titan, at 25 and
## 40 m. black: the same row as unlit silhouettes.
func _lineup(nm: String, black: bool) -> void:
	_hide_row(true)
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var c := Vector3(-20.0, 0, -5.0)
	var xs: Array[float] = [-12.0, -5.0, 0.5, 3.6, 7.0, 13.5]
	var paths: Array[String] = [SCENE, SCENE]
	paths.append_array(COMPARE)
	var yaws: Array[float] = [20.0, -20.0, 40.0, 40.0, 40.0, 30.0]
	for i: int in paths.size():
		if ResourceLoader.exists(paths[i]):
			var u := _spawn(c + Vector3(xs[i], 0, 0), yaws[i], i if i < 2 else -1, paths[i])
			holders.append(u.get_parent())
	await _wait(0.6)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c + Vector3(0.5, 0, 0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.5, 1.5, 0), 34.0))
	_strip(imgs, nm, Color.WHITE)
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	_hide_row(false)


## In context: a Stormcrest over a squad of Flame Guards, a Duskwing beside another; 40 m, then both dive.
func _fight(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(-20.0, 0.0, -40.0)
	var extra: Array = []
	var ra := _spawn(c + Vector3(-5.0, 0, 0), 150.0, 0)
	var rb := _spawn(c + Vector3(6.0, 0, 1.0), 200.0, 1)
	extra.append(ra.get_parent())
	extra.append(rb.get_parent())
	if ResourceLoader.exists(GUARD):
		for k: int in 10:
			var p := Vector3(-8.0 + 2.0 * float(k % 5), 0, 4.5 + 1.8 * float(k / 5))
			var g := _spawn(c + p, 180.0 + 10.0 * float(k % 3), -1, GUARD)
			if g.has_method(&"set_team_color"):
				g.call(&"set_team_color", Color(0.85, 0.30, 0.12))
			extra.append(g.get_parent())
	await _wait(0.8)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c + Vector3(0, 0, 2.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.2, 2.0), 26.0))
	ra.play_cast(&"gale_swoop")
	rb.play_cast(&"shrieking_dive")
	await _wait(0.5)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 1.2, 2.0), 26.0))
	_strip(imgs, nm, Color.WHITE)
	for e in extra:
		e.queue_free()
	_hide_row(false)


## Images side by side with an 8 px gap.
func _strip(imgs: Array[Image], nm: String, bg: Color) -> void:
	var w := imgs[0].get_width()
	var out := Image.create(w * imgs.size() + 8 * (imgs.size() - 1), imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(bg)
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")


## Images in a grid (cols per row) with an 8 px gap.
func _grid_sheet(imgs: Array[Image], nm: String, cols: int, bg: Color) -> void:
	var w := imgs[0].get_width()
	var h := imgs[0].get_height()
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols + 8 * (cols - 1), h * rows + 8 * (rows - 1), false, imgs[0].get_format())
	out.fill(bg)
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * (i % cols), (h + 8) * (i / cols)))
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


## Central crop: a 12:11 box of 80 % of the height.
func _center_crop(img: Image) -> Image:
	var h := int(img.get_height() * 0.8)
	var w := mini(int(h * 12.0 / 11.0), img.get_width())
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
