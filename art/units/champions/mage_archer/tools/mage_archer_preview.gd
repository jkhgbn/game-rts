extends Node3D
## Mage Archer preview (task 13b.V5) from the RTS camera (pitch 55, fov 50) and close detail angles.
## Keys: 1-5 zoom 5 / 12 / 25 / 40 / 55 · A attack · C cast cycle (her 3 + the 6 Wizard-tree actives) · P call · H hit
## D death · R revive · L level-up · W walk toggle · Y spin · V swap variants.
## Windowed `-- --shots`: docs/art/screens/13b_v5_*.png (views_a, views_b, shot, casts, call, z40, z40_full, silhouette,
## anim, seated) then quits.

const SCENE := "res://art/units/champions/mage_archer/mage_archer.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
const SHADOW := Color(0.42, 0.22, 0.60)
const FIRE := Color(0.85, 0.30, 0.12)
const CASTS: Array[StringName] = [&"sable_shaft", &"grave_mark", &"eclipse_volley", &"arc_bolt", &"slipstep",
	&"starfall", &"gravity_well", &"comet_rain", &"astral_form"]
## [id, sample time] of the cast sheet (key frames)
const CAST_FRAMES: Array = [[&"sable_shaft", 0.54], [&"sable_shaft", 0.62], [&"grave_mark", 0.36], [&"eclipse_volley", 0.50],
	[&"eclipse_volley", 0.70], [&"arc_bolt", 0.19], [&"slipstep", 0.26], [&"starfall", 0.40], [&"gravity_well", 0.30],
	[&"gravity_well", 0.55], [&"comet_rain", 0.66], [&"astral_form", 0.65]]
const SHADOW_UNITS: Array[String] = ["res://art/units/shadow/shade.tscn", "res://art/units/shadow/nightbolt.tscn",
	"res://art/units/shadow/shadow_knight.tscn", "res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/grave_hound.tscn", "res://art/units/shadow/nightbolt.tscn", "res://art/units/shadow/shade.tscn"]
const CHAMPIONS: Array[String] = ["res://art/units/champions/wayfinder/wayfinder.tscn",
	"res://art/units/champions/mender/mender.tscn", "res://art/units/champions/oathwall/oathwall.tscn",
	"res://art/units/champions/coin_cutter/coin_cutter.tscn"]
const MOUNT := "res://art/units/mounts/roan_courser/roan_courser.tscn"

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _cast_i: int = 0
var _walking: bool = false


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-1.2, 0, 0), 0.0, 0))
	_row.append(_spawn(Vector3(1.2, 0, 0), 30.0, 1))
	_set_zoom(12.0)
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()


func _spawn(at: Vector3, yaw_deg: float, variant: int, col: Color = SHADOW) -> Node3D:
	var m: Node3D = load(SCENE).instantiate()
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	m.call(&"set_variant", variant)
	m.call(&"set_team_color", col)
	holder.add_child(m)
	return m


func _spawn_other(path: String, at: Vector3, yaw_deg: float, col: Color = SHADOW) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var m: Node3D = (load(path) as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	holder.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", col)
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
	pm.size = Vector2(800, 800)
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
		KEY_1: _set_zoom(5.0, Vector3(0, 1.2, 0), 20.0)
		KEY_2: _set_zoom(12.0)
		KEY_3: _set_zoom(25.0)
		KEY_4: _set_zoom(40.0)
		KEY_5: _set_zoom(55.0)
		KEY_A: _all(&"play_attack")
		KEY_H: _all(&"play_hit")
		KEY_D: _all(&"play_death")
		KEY_R: _all(&"revive")
		KEY_L: _all(&"play_level_up")
		KEY_P: _all(&"play_call")
		KEY_V:
			for m in _row:
				m.set_variant(1 - int(m.variant))
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m in _row:
				m.set_moving(5.2 if _walking else 0.0)
		KEY_C:
			for m in _row:
				m.play_cast(CASTS[_cast_i])
			_cast_i = (_cast_i + 1) % CASTS.size()


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for m in _row:
		m.get_parent().visible = false
	await _wait(1.0)
	await _views_sheet("13b_v5_views_a", 0)
	await _views_sheet("13b_v5_views_b", 1)
	await _shot_sheet("13b_v5_shot")
	await _cast_sheet("13b_v5_casts")
	await _call_sheet("13b_v5_call")
	await _anim_sheet("13b_v5_anim")
	await _seated_sheet("13b_v5_seated")
	await _army_shot("13b_v5_z40")
	await _silhouettes("13b_v5_silhouette")
	print("MAGE ARCHER SHOTS DONE")
	get_tree().quit()


## One variant alone, close: front, 3/4 front, side, back, 3/4 back, then the game angle (55 deg) at 6 m.
func _views_sheet(nm: String, variant: int) -> void:
	var u := _spawn(Vector3(0, 0, 80.0), 0.0, variant)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	for f: Array in [[0.0, 8.0, 5.0], [35.0, 8.0, 5.0], [90.0, 8.0, 5.0], [180.0, 8.0, 5.0], [215.0, 20.0, 5.0],
			[25.0, 55.0, 6.0]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), Vector3(0, 1.15, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_crop_box(_grab(), ORIGIN + Vector3(0, 1.15, 80.0), 2.6, 2.9, 420, 468, false))
	_tiles(frames, nm, 3, 420, 468)
	h.queue_free()
	await _wait(0.1)


## The attack, side view then front 3/4: rest, raising, drawn (the arrow of light), loose, recoil, lowering.
func _shot_sheet(nm: String) -> void:
	var frames: Array[Image] = []
	for view: Array in [[90.0, 10.0], [-35.0, 18.0]]:
		var u := _spawn(Vector3(0, 0, 100.0), float(view[0]), 1 if float(view[0]) == 90.0 else 0)
		await _wait(0.5)
		var c := Vector3(0.0, 1.25, 100.0)
		_set_zoom(5.4, c, float(view[1]))
		for t: float in [0.0, 0.07, 0.135, 0.17, 0.24, 0.42]:
			if t > 0.0:
				u.play_attack()
				await _until(u, &"_action_t", t)
			else:
				await _wait(0.2)
			frames.append(_crop_box(_grab(), ORIGIN + c, 2.9, 2.9, 300, 300, false))
			await _wait(0.8)
		u.get_parent().queue_free()
		await _wait(0.1)
	_tiles(frames, nm, 6, 300, 300)


## Key frames of her 3 abilities and the 6 Wizard-tree actives (3/4 front, then the same from the side).
func _cast_sheet(nm: String) -> void:
	var frames: Array[Image] = []
	for view: Array in [[-30.0, 14.0], [90.0, 8.0]]:
		for i: int in CAST_FRAMES.size():
			var fr: Array = CAST_FRAMES[i]
			var u := _spawn(Vector3(0, 0, 120.0), float(view[0]), i % 2)
			var c := Vector3(0.0, 1.35, 120.0)
			_set_zoom(6.2, c, float(view[1]))
			await _wait(0.35)
			u.play_cast(fr[0])
			await _until(u, &"_action_t", float(fr[1]))
			frames.append(_crop_box(_grab(), ORIGIN + c, 3.3, 3.5, 250, 265, false))
			u.get_parent().queue_free()
			await _wait(0.05)
	_tiles(frames, nm, 6, 250, 265)


## play_call: she rises out of the ground (0.2 .. 1.1), stands, raises the bow with the quiver fanned (1.5), done (2.0).
func _call_sheet(nm: String) -> void:
	var frames: Array[Image] = []
	var u := _spawn(Vector3(0, 0, 140.0), -25.0, 0)
	var c := Vector3(0.0, 1.1, 140.0)
	_set_zoom(6.5, c, 22.0)
	await _wait(0.5)
	u.play_call()
	for t: float in [0.30, 0.60, 0.85, 1.10, 1.35, 1.55, 1.75, 1.98]:
		await _until(u, &"_action_t", t)
		frames.append(_crop_box(_grab(), ORIGIN + c, 3.4, 3.4, 300, 300, false))
	_tiles(frames, nm, 8, 300, 300)
	u.get_parent().queue_free()
	await _wait(0.1)


## States: idle, walk, hit, level-up, death 0.3 / 0.6 / 0.9, revived (A front 3/4 + B side).
func _anim_sheet(nm: String) -> void:
	var a := _spawn(Vector3(-1.0, 0, 160.0), 20.0, 0)
	var b := _spawn(Vector3(1.0, 0, 160.0), 90.0, 1)
	var pair: Array = [a, b]
	_set_zoom(7.5, Vector3(0.0, 1.2, 160.0), 30.0)
	var frames: Array[Image] = []
	await _wait(0.6)
	var c := ORIGIN + Vector3(0.0, 1.1, 160.0)
	frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	for m in pair:
		m.set_moving(5.2)
	await _wait(0.62)
	frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	for m in pair:
		m.set_moving(0.0)
	await _wait(0.5)
	for m in pair:
		m.play_hit()
	await _wait(0.05)
	frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	await _wait(0.5)
	for m in pair:
		m.play_level_up()
	await _wait(0.12)
	frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	await _wait(0.6)
	for m in pair:
		m.play_death()
	for t: float in [0.3, 0.6, 0.9]:
		await _until(a, &"_death_t", t)
		frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	await _wait(0.4)
	for m in pair:
		m.revive()
	await _wait(0.3)
	frames.append(_crop_box(_grab(), c, 5.0, 3.0, 500, 300, false))
	_tiles(frames, nm, 4, 500, 300)
	for m in pair:
		m.get_parent().queue_free()
	await _wait(0.1)


## Seated on a Roan Courser (she buys one at level 7): standing, walking, the attack, from the side and 3/4.
func _seated_sheet(nm: String) -> void:
	if not ResourceLoader.exists(MOUNT):
		return
	var frames: Array[Image] = []
	for view: Array in [[90.0, 10.0], [-35.0, 30.0]]:
		var holder := Node3D.new()
		holder.position = ORIGIN + Vector3(0, 0, 180.0)
		holder.rotation.y = deg_to_rad(float(view[0]))
		add_child(holder)
		var mount: Node3D = (load(MOUNT) as PackedScene).instantiate()
		holder.add_child(mount)
		var u: Node3D = load(SCENE).instantiate()
		holder.add_child(u)
		await _wait(0.2)
		u.call(&"set_seated", true, mount)
		var c := Vector3(0.0, 1.6, 180.0)
		_set_zoom(7.0, c, float(view[1]))
		await _wait(0.5)
		frames.append(_crop_box(_grab(), ORIGIN + c, 4.2, 3.4, 420, 340, false))
		if mount.has_method(&"set_moving"):
			mount.call(&"set_moving", 6.0)
		await _wait(0.5)
		frames.append(_crop_box(_grab(), ORIGIN + c, 4.2, 3.4, 420, 340, false))
		if mount.has_method(&"set_moving"):
			mount.call(&"set_moving", 0.0)
		await _wait(0.5)
		u.play_attack()
		await _until(u, &"_action_t", 0.14)
		frames.append(_crop_box(_grab(), ORIGIN + c, 4.2, 3.4, 420, 340, false))
		holder.queue_free()
		await _wait(0.1)
	_tiles(frames, nm, 3, 420, 340)


## The 40 m game camera: Veyra and Vesper in a Shadow army (Shades, Nightbolts, a Shadow Knight, a Gloom Thrall, a
## Grave Hound) beside the four champions; nearest-upscaled crop (the real pixels) + the full frame.
func _army_shot(nm: String) -> void:
	var z0 := 220.0
	var extra: Array = []
	extra.append(_spawn(Vector3(-0.6, 0, z0), 10.0, 0))
	extra.append(_spawn(Vector3(3.2, 0, z0 + 1.5), -30.0, 1))
	var ma: Node3D = extra[1]
	var xs: Array[float] = [-5.0, -3.2, -1.2, 1.2, 5.2, -4.0, 0.8]
	var zs: Array[float] = [2.0, 1.2, 2.8, 2.6, 2.4, -1.0, -1.6]
	for i: int in SHADOW_UNITS.size():
		var o := _spawn_other(SHADOW_UNITS[i], Vector3(xs[i], 0, z0 + zs[i]), float(i * 25))
		if o:
			extra.append(o)
	for i: int in CHAMPIONS.size():
		var o := _spawn_other(CHAMPIONS[i], Vector3(-4.5 + 3.0 * float(i), 0, z0 - 3.5), 15.0 - 10.0 * float(i))
		if o:
			extra.append(o)
	_set_zoom(40.0, Vector3(0.0, 0.0, z0))
	await _wait(0.8)
	await _wait(0.2)
	ma.play_attack()
	await _until(ma, &"_action_t", 0.14)
	var full := _grab()
	var crop := _crop_box(full, ORIGIN + Vector3(0.0, 0.8, z0), 14.0, 8.0, 1400, 800, true)
	crop.save_png(OUT + nm + ".png")
	var f2 := full.duplicate() as Image
	f2.resize(800, 450, Image.INTERPOLATE_BILINEAR)
	f2.save_png(OUT + nm + "_full.png")
	await _wait(0.5)
	for m in extra:
		m.get_parent().queue_free()
	await _wait(0.1)


## Unlit black on white (the black test) at 25 m and 40 m: front, 3/4 back, side, walking, and drawn (attack).
func _silhouettes(nm: String) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	var z0 := 260.0
	var sil: Array = []
	var yaws: Array[float] = [0.0, 200.0, 90.0, 45.0, -30.0]
	for i: int in 5:
		sil.append(_spawn(Vector3(-3.2 + 1.6 * float(i), 0, z0), yaws[i], i % 2))
	var others: Array = []
	for i: int in 3:
		var o := _spawn_other(SHADOW_UNITS[i], Vector3(-3.2 + 1.6 * float(i), 0, z0 + 3.0), 0.0)
		if o:
			others.append(o)
	var wf := _spawn_other(CHAMPIONS[0], Vector3(2.0, 0, z0 + 3.0), 0.0)
	await _wait(0.4)
	for g: Node in find_children("*", "GeometryInstance3D", true, false):
		if g == _ground:
			continue
		if g is GPUParticles3D or g.name == "Shadow":
			(g as Node3D).visible = false
		else:
			(g as GeometryInstance3D).material_override = black
	sil[3].set_moving(5.2)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 1.1, z0 + 1.2)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, z0 + 1.2))
		await _wait(0.5)
		imgs.append(_crop_box(_grab(), centre, 9.0, 6.0, 600, 400, true))
	sil[3].set_moving(0.0)
	sil[4].play_attack()
	sil[0].play_cast(&"starfall")
	await _until(sil[4], &"_action_t", 0.14)
	imgs.append(_crop_box(_grab(), centre, 9.0, 6.0, 600, 400, true))
	var out := Image.create(600 * 3 + 16, 400, false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	for i: int in 3:
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i(608 * i, 0))
	out.save_png(OUT + nm + ".png")
	await _wait(1.0)
	for m in sil:
		m.get_parent().queue_free()
	for m in others:
		m.get_parent().queue_free()
	if wf:
		wf.get_parent().queue_free()
	_ground.material_override = old_ground
	_env.environment = old_env


# ---------------------------------------------------------------- image helpers

## Crop w_m x h_m metres (screen plane) around the world point `centre`, resized to out_w x out_h.
func _crop_box(img: Image, centre: Vector3, w_m: float, h_m: float, out_w: int, out_h: int, nearest: bool) -> Image:
	var c := _cam.unproject_position(centre)
	var r := _cam.unproject_position(centre + _cam.global_transform.basis.x * 1.0)
	var ppm := maxf(r.x - c.x, 1.0)
	var w: int = clampi(int(w_m * ppm), 8, img.get_width())
	var h: int = clampi(int(h_m * ppm), 8, img.get_height())
	var rect := Rect2i(clampi(int(c.x) - w / 2, 0, img.get_width() - w), clampi(int(c.y) - h / 2, 0, img.get_height() - h), w, h)
	var out := img.get_region(rect)
	out.resize(out_w, out_h, Image.INTERPOLATE_NEAREST if nearest else Image.INTERPOLATE_BILINEAR)
	return out


func _tiles(imgs: Array[Image], nm: String, cols: int, w: int, h: int) -> void:
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.3, 0.3, 0.3))
	for i: int in imgs.size():
		var im := imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


func _until(m: Object, prop: StringName, t: float) -> void:
	var guard := 0
	while float(m.get(prop)) < t and guard < 300:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
