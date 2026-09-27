extends Node3D
## Direwolf preview (task 12.V29) from the RTS camera (pitch 55, fov 50) and detail angles. Row: Greymane (A),
## Moonpelt (B), a Grave Hound for scale.
## Keys: 1-5 zoom 6 / 12 / 25 / 40 / 55 Ã‚Â· A attack Ã‚Â· C cast pounce Ã‚Â· F howl Ã‚Â· H hit Ã‚Â· D death Ã‚Â· R revive Ã‚Â· W walk
## (trot) Ã‚Â· G gallop Ã‚Â· V swap the variants Ã‚Â· Y spin the facing.
## Windowed `-- --shots`: docs/art/screens/12_v29_*.png then quit.

const SCENE := "res://art/units/neutral/beasts/direwolf/direwolf.tscn"
const HOUND := "res://art/units/shadow/grave_hound.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
## Scale / look references for the lineup (skipped when missing).
const COMPARE: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/shadow/grave_hound.tscn",
	"res://art/units/neutral/bristleback/bristleback.tscn", "res://art/units/neutral/hollow_stag/hollow_stag.tscn",
	"res://art/units/neutral/beasts/tusker/tusker.tscn", "res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"]
const LAIR := "res://art/environment/lairs/greymane_hollow.tscn"

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _walking: float = 0.0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(SCENE, Vector3(-3.2, 0, 0), 30.0, 0))
	_row.append(_spawn(SCENE, Vector3(0.6, 0, 0), 100.0, 1))
	_row.append(_spawn(HOUND, Vector3(3.8, 0, 0.3), 60.0))
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(path: String, at: Vector3, yaw_deg: float, variant: int = -1) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
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
	sun.light_color = Color(1.00, 0.89, 0.74)
	sun.light_energy = 1.35
	sun.rotation_degrees = Vector3(-52, 40, 0)
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


func _set_zoom(z: float, focus: Vector3 = Vector3(0.3, 0.0, 0.0), pitch_deg: float = 55.0, yaw_deg: float = 0.0) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0.0, sin(pitch) * z, cos(pitch) * z).rotated(Vector3.UP, yaw)
	_cam.position = ORIGIN + focus + off
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _set_zoom(6.0, Vector3(-1.2, 1.1, 0), 20.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_F: _all(&"play_fidget")
		KEY_C:
			for m in _row:
				if m and m.has_method(&"play_cast"):
					m.play_cast(&"pounce")
		KEY_V:
			for m in _row:
				if m and m.has_method(&"set_variant"):
					m.set_variant(1 - int(m.get_variant()))
		KEY_Y:
			for m in _row:
				if m:
					m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W, KEY_G:
			var sp: float = 4.2 if (event as InputEventKey).physical_keycode == KEY_W else 7.0
			_walking = 0.0 if _walking == sp else sp
			for m in _row:
				if m and m.has_method(&"set_moving"):
					m.set_moving(_walking)


func _all(method: StringName) -> void:
	for m in _row:
		if m and m.has_method(method):
			m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(0.3, 0.8, 0.0), 12.0 if z < 30.0 else 15.0).save_png(OUT + "12_v29_z%d.png" % int(z))
	_set_zoom(40.0)
	await _wait(0.3)
	_grab().save_png(OUT + "12_v29_game_40m.png")
	await _ab_sheet("12_v29_ab_sheet")
	await _detail_sheet("12_v29_detail_a", 0)
	await _detail_sheet("12_v29_detail_b", 1)
	await _heads("12_v29_heads")
	await _pose_sheet("12_v29_poses_side", 90.0, 12.0, 0)
	await _pose_sheet("12_v29_poses_game", 30.0, 55.0, 1)
	await _anim_sheet("12_v29_anim")
	await _silhouettes("12_v29_silhouette")
	await _lineup("12_v29_lineup", false)
	await _lineup("12_v29_lineup_black", true)
	await _hollow("12_v29_hollow")
	get_tree().quit()


func _hide_row(on: bool) -> void:
	for m in _row:
		if m:
			m.get_parent().visible = not on


## THE A / B contact sheet: a Greymane and a Moonpelt side by side, same pose / facing, then a mixed pack running,
## at 12 m (side), 25 m and 40 m game camera: they must read apart at 40 m (grey maned vs white sleek + eye glints).
func _ab_sheet(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(-45.0, 0.0, -40.0)
	var hs: Array = []
	var units: Array = []
	for i: int in 2:
		var u := _spawn(SCENE, c + Vector3(-1.9 + 3.8 * float(i), 0, 0), 70.0, i)
		units.append(u)
		hs.append(u.get_parent())
	await _wait(0.6)
	var imgs: Array[Image] = []
	_set_zoom(10.0, c + Vector3(0.0, 1.0, 0.0), 12.0)
	await _wait(0.4)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.0, 1.0, 0.0), 9.5))
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c)
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.0, 0.8, 0.0), 10.0))
	# A mixed pack galloping at 40 m (4 A, 2 B), then pouncing.
	for h in hs:
		h.queue_free()
	hs.clear()
	units.clear()
	var spots: Array = [[-4.0, 0.0, 0], [-1.5, 1.5, 1], [1.0, -0.8, 0], [3.2, 1.2, 0], [0.0, 3.4, 1], [-3.0, 3.6, 0]]
	for s: Array in spots:
		var u := _spawn(SCENE, c + Vector3(float(s[0]), 0, float(s[1])), 90.0 + float(s[0]) * 6.0, int(s[2]))
		units.append(u)
		hs.append(u.get_parent())
	await _wait(0.5)
	for u in units:
		u.set_moving(7.0)
	_set_zoom(40.0, c + Vector3(0.0, 0.0, 1.5))
	await _wait(0.6)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.0, 0.8, 1.5), 14.0))
	for u in units:
		u.set_moving(0.0)
		u.play_cast(&"pounce")
	await _wait(0.27)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.0, 0.8, 1.5), 14.0))
	await _wait(0.9)
	_set_zoom(55.0, c + Vector3(0.0, 0.0, 1.5))
	await _wait(0.4)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0.0, 0.8, 1.5), 16.0))
	_grid_sheet(imgs, nm, 3)
	for h in hs:
		h.queue_free()
	_hide_row(false)


## One wolf alone, close: front, 3/4 front, side, back, 3/4 back from above, game angle 55 deg.
func _detail_sheet(nm: String, variant: int) -> void:
	_hide_row(true)
	var u := _spawn(SCENE, Vector3(-45.0, 0, -10.0), 0.0, variant)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	for f: Array in [[0.0, 8.0, 6.0], [35.0, 14.0, 6.0], [90.0, 6.0, 6.0], [180.0, 12.0, 6.0], [215.0, 30.0, 6.0],
			[25.0, 55.0, 7.5]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), Vector3(-45.0, 1.05, -10.0), float(f[1]))
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
	_sheet(frames, nm, 3, 480, 440)
	h.queue_free()
	_hide_row(false)


## Head close-ups: A and B at 3/4, jaws open (attack windup) and the B eyes glowing.
func _heads(nm: String) -> void:
	_hide_row(true)
	var frames: Array[Image] = []
	for v: int in 2:
		var u := _spawn(SCENE, Vector3(-45.0, 0, 15.0), 40.0, v)
		var h: Node3D = u.get_parent()
		await _wait(0.4)
		_set_zoom(2.6, Vector3(-44.3, 1.48, 15.85), 12.0, 25.0)
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
		u.play_attack()
		await _until(u, &"_action_t", 0.065)
		frames.append(_center_crop(_grab()))
		await _wait(0.6)
		h.rotation.y = deg_to_rad(95.0)
		_set_zoom(3.2, Vector3(-44.2, 1.4, 15.0), 8.0)
		await _wait(0.25)
		frames.append(_center_crop(_grab()))
		h.queue_free()
		await _wait(0.1)
	_sheet(frames, nm, 3, 480, 440)
	_hide_row(false)


## Key frames side by side: rest, trot, gallop, bite windup / strike / rip, pounce crouch / air / bite, howl, death.
func _pose_sheet(nm: String, yaw: float, pitch: float, variant: int) -> void:
	_hide_row(true)
	var rows: Array = [["rest", 0.0], ["trot", 0.4], ["gallop", 0.4], ["attack", 0.065], ["attack", 0.12],
		["attack", 0.22], ["cast", 0.06], ["cast", 0.26], ["cast", 0.58], ["fidget", 0.9], ["death", 0.45], ["death", 0.9]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	var gap := 3.2 if yaw > 60.0 else 2.6
	for i: int in n:
		var u := _spawn(SCENE, Vector3((float(i) - float(n - 1) * 0.5) * gap, 0, -60.0), yaw, variant)
		units.append(u)
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(26.0 if pitch < 30.0 else 30.0, Vector3(0.0, 1.0, -60.0), pitch)
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
			"trot":
				units[i].set_moving(4.2)
			"gallop":
				units[i].set_moving(7.0)
			"attack":
				units[i].play_attack()
			"fidget":
				units[i].play_fidget()
			"death":
				units[i].play_death()
			_:
				units[i].play_cast(&"pounce")
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_grab().save_png(OUT + nm + ".png")
	await _wait(1.6)
	for m in units:
		m.get_parent().queue_free()
	_hide_row(false)


## One frame per state (A front 3/4 + B side): idle, gallop, hit, bite, pounce in the air, death 0.3 / 0.6 / 0.9, revived.
func _anim_sheet(nm: String) -> void:
	_hide_row(true)
	var a := _spawn(SCENE, Vector3(-2.2, 0, -25.0), 30.0, 0)
	var b := _spawn(SCENE, Vector3(2.4, 0, -25.0), 90.0, 1)
	var pair: Array = [a, b]
	_set_zoom(12.0, Vector3(0.0, 1.0, -25.0), 40.0)
	var frames: Array[Image] = []
	await _wait(0.6)
	frames.append(_grab())
	for m in pair:
		m.set_moving(7.0)
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
	await _wait(0.07)
	frames.append(_grab())
	await _wait(1.0)
	for m in pair:
		m.play_cast(&"pounce")
	await _wait(0.26)
	frames.append(_grab())
	await _wait(1.2)
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
	_contact(frames, nm, 3, Rect2i(240, 60, 1120, 630))
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


## Unlit black on white (the "black test"): A front 3/4, A side, B side, B 3/4 back, A galloping; 25 m and 40 m; then
## all pouncing (in the air).
func _silhouettes(nm: String) -> void:
	var old := _black_world(true, [])
	_hide_row(true)
	var sil: Array = []
	var yaws: Array[float] = [20.0, 90.0, 90.0, 200.0, 70.0]
	var vars: Array[int] = [0, 0, 1, 1, 0]
	for i: int in 5:
		var u := _spawn(SCENE, Vector3(-6.4 + 3.2 * float(i), 0, 48.0), yaws[i], vars[i])
		sil.append(u)
	await _wait(0.4)
	for u in sil:
		_blacken(u)
	sil[4].set_moving(7.0)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 0.9, 48.0)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 48.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 17.0))
	sil[4].set_moving(0.0)
	await _wait(0.2)
	for u in sil:
		u.play_cast(&"pounce")
	await _wait(0.26)
	imgs.append(_crop_world(_grab(), centre, 17.0))
	_strip(imgs, nm, Color(0.8, 0.8, 0.8))
	await _wait(1.0)
	for m in sil:
		m.get_parent().queue_free()
	_black_world(false, old)
	_hide_row(false)


## Scale and look: A and B next to a Flame Guard, a Grave Hound, a Bristleback, the Hollow Stag (and the other beasts
## when they exist), at 25 and 40 m. black: the same row as unlit silhouettes.
func _lineup(nm: String, black: bool) -> void:
	_hide_row(true)
	var old: Array = _black_world(true, []) if black else []
	var holders: Array = []
	var x := -9.0
	var paths: Array[String] = [SCENE, SCENE]
	paths.append_array(COMPARE)
	var width: Array[float] = [3.4, 3.4, 1.6, 2.4, 2.4, 3.6, 4.0, 4.2]
	for i: int in paths.size():
		if not ResourceLoader.exists(paths[i]):
			continue
		var u := _spawn(paths[i], Vector3(x + width[i] * 0.5, 0, 25.0), 55.0 if i < 2 else 40.0, i if i < 2 else -1)
		holders.append(u.get_parent())
		x += width[i]
	await _wait(0.5)
	if black:
		for h in holders:
			_blacken(h)
	var mid := x * 0.5 - 4.5
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(mid, 0.0, 25.0))
		await _wait(0.6)
		imgs.append(_crop_world(_grab(), ORIGIN + Vector3(mid, 0.9, 25.0), x + 11.0))
	_strip(imgs, nm, Color.WHITE)
	for h in holders:
		h.queue_free()
	if black:
		_black_world(false, old)
	_hide_row(false)


## Greymane Hollow in context (the lair scene when it exists): a Greymane pounces into a squad of Flame Guards; a
## Moonpelt beside for the pair read; 25 m, 40 m, then the pounce at 40 m.
func _hollow(nm: String) -> void:
	_hide_row(true)
	var c := Vector3(-40.0, 0.0, -62.0)
	var extra: Array = []
	if ResourceLoader.exists(LAIR):
		var site: Node3D = load(LAIR).instantiate()
		site.position = ORIGIN + c
		add_child(site)
		extra.append(site)
	var w := _spawn(SCENE, c + Vector3(-1.5, 0, -1.0), 35.0, 0)
	extra.append(w.get_parent())
	var w2 := _spawn(SCENE, c + Vector3(-4.2, 0, 1.2), 70.0, 1)
	extra.append(w2.get_parent())
	if ResourceLoader.exists(COMPARE[0]):
		for k: int in 5:
			var a := 0.2 + 0.4 * float(k)
			var g := _spawn(COMPARE[0], c + Vector3(3.5 + cos(a) * 1.6, 0, 2.0 + sin(a) * 1.6), 240.0)
			extra.append(g.get_parent())
	await _wait(0.6)
	var imgs: Array[Image] = []
	for z: float in [25.0, 40.0]:
		_set_zoom(z, c)
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 0.8, 0), 14.0))
	w.play_cast(&"pounce")
	w2.play_attack()
	await _wait(0.26)
	imgs.append(_crop_world(_grab(), ORIGIN + c + Vector3(0, 0.8, 0), 14.0))
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


## Equal images in a grid (cols per row), 8 px gaps.
func _grid_sheet(imgs: Array[Image], nm: String, cols: int) -> void:
	var w := imgs[0].get_width()
	var h := imgs[0].get_height()
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols + 8 * (cols - 1), h * rows + 8 * (rows - 1), false, imgs[0].get_format())
	out.fill(Color.WHITE)
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


## Central crop (keeps the detail frames whatever the window size): a 12:11 box of 80 % of the height.
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
