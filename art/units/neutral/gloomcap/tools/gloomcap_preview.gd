extends Node3D
## Gloomcap preview (task 12.V22): the Hollow camp (1 Elder + 3 Sprouts) from the RTS camera (pitch 55, fov 50) and
## detail / pose sheets. Keys: 1-5 zoom 5 / 12 / 25 / 40 / 55 · A attack · C cast spore_burst · F fidget / hop
## · H hit · D death · R revive · W walk toggle.
## Windowed `-- --shots`: docs/art/screens/12_v22_*.png then quit.

const ELDER := "res://art/units/neutral/gloomcap/gloomcap_elder.tscn"
const SPROUT := "res://art/units/neutral/gloomcap/gloomcap_sprout.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references for the lineup (skipped when missing).
const COMPARE: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/neutral/bristleback/bristleback.tscn",
	"res://art/units/nature/bramblehorn.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _camp: Array = []
var _walking: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_camp = _spawn_camp(Vector3.ZERO)
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float) -> Node3D:
	var m: Node3D = load(path).instantiate()
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	return m


## The camp layout of map-fill.md 5.2: the Elder at the spot, the Sprouts in a loose ring r 1.5-2 around it.
func _spawn_camp(at: Vector3) -> Array:
	var out: Array = [_spawn(ELDER, at, 10.0)]
	for s: Array in [[Vector3(-1.6, 0, 0.9), 40.0], [Vector3(1.4, 0, 1.3), -25.0], [Vector3(0.3, 0, -1.8), 170.0]]:
		out.append(_spawn(SPROUT, at + (s[0] as Vector3), float(s[1])))
	return out


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
		KEY_1: _set_zoom(5.0, Vector3(0, 0.8, 0), 25.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_F:
			_all(&"play_fidget")
			_all(&"play_hop")
		KEY_C:
			for m in _camp:
				m.play_cast(&"spore_burst")
		KEY_W:
			_walking = not _walking
			for m in _camp:
				m.set_moving(3.5 if _walking else 0.0)


func _all(method: StringName) -> void:
	for m in _camp:
		if m.has_method(method):
			m.call(method)


func _quiet(m: Node3D) -> void:
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
	if &"hop_every" in m:
		m.set(&"hop_every", 0.0)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.5)
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(0.0, 0.6, 0.0), 9.0 if z < 30.0 else 12.0).save_png(OUT + "12_v22_camp_z%d.png" % int(z))
	# The 40 m frame uncropped (what the player sees at that zoom), with the cast burst mid-cloud on a second shot.
	_set_zoom(40.0)
	await _wait(0.3)
	_grab().save_png(OUT + "12_v22_game_40m.png")
	for m in _camp:
		m.play_cast(&"spore_burst")
	await _wait(0.85)
	_crop_world(_grab(), ORIGIN + Vector3(0.0, 0.6, 0.0), 12.0).save_png(OUT + "12_v22_camp_cast_z40.png")
	await _wait(1.5)
	await _detail_sheet("12_v22_detail_elder", ELDER, 1.0, 5.2)
	await _detail_sheet("12_v22_detail_sprout", SPROUT, 0.38, 2.2)
	await _pose_sheet("12_v22_poses_elder", ELDER, [["rest", 0.0], ["walk", 0.3], ["attack", 0.08], ["attack", 0.15],
		["cast", 0.36], ["cast", 0.6], ["fidget", 0.5], ["death", 0.5]], 2.6, 12.0, 1.0)
	await _pose_sheet("12_v22_poses_sprout", SPROUT, [["rest", 0.0], ["walk", 0.2], ["attack", 0.07], ["attack", 0.13],
		["cast", 0.25], ["cast", 0.4], ["hop", 0.3], ["death", 0.4]], 1.1, 5.0, 0.35)
	await _silhouettes("12_v22_silhouette")
	await _lineup("12_v22_lineup", false)
	await _lineup("12_v22_lineup_black", true)
	get_tree().quit()


func _hide_camp(on: bool) -> void:
	for m in _camp:
		m.get_parent().visible = not on


## One model alone, close (not a game angle): front, 3/4 front, side, back, 3/4 back from above, game angle 55 deg.
func _detail_sheet(nm: String, path: String, focus_y: float, dist: float) -> void:
	_hide_camp(true)
	var u := _spawn(path, Vector3(0, 0, 80.0), 0.0)
	_quiet(u)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	for f: Array in [[0.0, 8.0, 1.0], [35.0, 14.0, 1.0], [90.0, 8.0, 1.0], [180.0, 12.0, 1.0], [215.0, 30.0, 1.0],
			[25.0, 55.0, 1.3]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(dist * float(f[2]), Vector3(0, focus_y, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
	var w := 440
	var hh := 440
	var out := Image.create(w * 3, hh * 2, false, frames[0].get_format())
	for i: int in frames.size():
		frames[i].resize(w, hh)
		out.blit_rect(frames[i], Rect2i(0, 0, w, hh), Vector2i((i % 3) * w, (i / 3) * hh))
	out.save_png(OUT + nm + ".png")
	h.queue_free()
	_hide_camp(false)


## Key frames side by side (3/4 front view): each unit starts its action so they all reach their time together.
func _pose_sheet(nm: String, path: String, rows: Array, spacing: float, dist: float, focus_y: float) -> void:
	_hide_camp(true)
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	for i: int in n:
		var u := _spawn(path, Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0, 30.0), 30.0)
		_quiet(u)
		units.append(u)
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(dist, Vector3(0.0, focus_y, 30.0), 22.0)
	await _wait(0.8)
	var order: Array = range(n)
	order.sort_custom(func(a: int, b: int) -> bool: return float(rows[a][1]) > float(rows[b][1]))
	var elapsed := 0.0
	for i: int in order:
		var start: float = t_max - float(rows[i][1])
		if start > elapsed:
			await _wait(start - elapsed)
			elapsed = start
		var u = units[i]
		match String(rows[i][0]):
			"walk":
				u.set_moving(3.5)
			"attack":
				u.play_attack()
			"cast":
				u.play_cast(&"spore_burst")
			"fidget":
				u.play_fidget()
			"hop":
				u.play_hop()
			"death":
				u.play_death()
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	var img := _grab()
	var w := img.get_width()
	var h := img.get_height()
	img.get_region(Rect2i(0, int(h * 0.18), w, int(h * 0.64))).save_png(OUT + nm + ".png")
	await _wait(1.3)
	for m in units:
		m.get_parent().queue_free()
	_hide_camp(false)


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


## Unlit black on white (the "black test") of a camp, at 25 and 40 m, then while casting.
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	_hide_camp(true)
	var sil := _spawn_camp(Vector3(0, 0, 48.0))
	await _wait(0.4)
	for u in sil:
		_quiet(u)
		_blacken(u.get_parent())
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 0.6, 48.0)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 48.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 8.5))
	for u in sil:
		u.play_attack()
	await _wait(0.15)
	imgs.append(_crop_world(_grab(), centre, 8.5))
	var w := imgs[0].get_width()
	var out := Image.create(w * 3 + 16, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	for i: int in 3:
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")
	await _wait(1.0)
	for m in sil:
		m.get_parent().queue_free()
	_black_world(false, old)
	_hide_camp(false)


## Scale and look: an Elder and two Sprouts next to a Flame Guard, a Bristleback and a Bramblehorn at 25 and 40 m.
func _lineup(nm: String, black: bool) -> void:
	_hide_camp(true)
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var e := _spawn(ELDER, Vector3(-4.6, 0, 60.0), 20.0)
	var s1 := _spawn(SPROUT, Vector3(-2.6, 0, 60.0), 30.0)
	var s2 := _spawn(SPROUT, Vector3(-1.6, 0, 60.5), -20.0)
	for u in [e, s1, s2]:
		_quiet(u)
		holders.append(u.get_parent())
	var xs: Array[float] = [0.2, 2.4, 5.2]
	for i: int in COMPARE.size():
		if ResourceLoader.exists(COMPARE[i]):
			var u: Node3D = load(COMPARE[i]).instantiate()
			var h := Node3D.new()
			h.position = ORIGIN + Vector3(xs[i], 0, 60.0)
			h.rotation.y = deg_to_rad(40.0)
			add_child(h)
			h.add_child(u)
			holders.append(h)
	await _wait(0.4)
	if black:
		for h in holders:
			_blacken(h)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.3, 0.0, 60.0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(0.3, 0.9, 60.0), 14.0))
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
	_hide_camp(false)


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


## Central square crop of 60 % of the height.
func _center_crop(img: Image) -> Image:
	var h := int(img.get_height() * 0.9)
	var w := h
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
