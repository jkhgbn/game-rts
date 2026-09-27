extends Node3D
## Wayfinder preview (task 9.V1) from the RTS camera (pitch 55, fov 50) and a few detail angles.
## Keys: 1-5 zoom 5 / 12 / 25 / 40 / 55 · A attack · C cast cycle · H hit · D death · R revive · L level-up
## W walk toggle · Y spin the facing · V swap variants · K next class weapon (none, spear, sword_shield, two_hand, wizard).
## Windowed `-- --shots`: docs/art/screens/champion_wayfinder_*.png (+ champion_wayfinder_silhouette.png) then quit.
## Windowed `-- --classes` (task 11.V2): champion_wayfinder_classes.png (archetype + 4 class weapons: front 3/4, back
## 3/4, the 40 m game camera lit, then the black test at 40 m front / back-walking) and champion_wayfinder_class_poses.png
## (one row per class: Signal Flare grab + throw, Snare Line, Trailblaze, attack strike, the 3 class skills).

const SCENE := "res://art/units/champions/wayfinder/wayfinder.tscn"
const OUT := "res://docs/art/screens/"
const ORIGIN := Vector3(20.0, 0.0, 20.0)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)
const CASTS: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze"]
const SCALE_UNITS: Array[String] = ["res://art/units/fire/ember_archer.tscn", "res://art/units/shadow/nightbolt.tscn"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array = []
var _cast_i: int = 0
var _walking: bool = false
var _cls_i: int = 0

const CLASS_LIST: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const CLASS_SKILLS: Dictionary = {
	&"spear": [[&"lunge", 0.20], [&"hobbling_javelin", 0.34], [&"skewer", 0.32]],
	&"sword_shield": [[&"riposte", 0.6], [&"second_wind", 0.7], [&"shield_throw", 0.30]],
	&"two_hand": [[&"cleave", 0.30], [&"crushing_blow", 0.40], [&"whirlwind", 0.7]],
	&"wizard": [[&"arc_bolt", 0.22], [&"slipstep", 0.36], [&"starfall", 0.6]],
}
const STRIKE_T: Dictionary = {&"spear": 0.12, &"sword_shield": 0.12, &"two_hand": 0.16, &"wizard": 0.14}


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	_row.append(_spawn(Vector3(-2.2, 0, 0), 0.0, 0, FIRE))
	_row.append(_spawn(Vector3(0.0, 0, 0), 0.0, 1, SHADOW))
	_row.append(_spawn(Vector3(2.2, 0, 0), 200.0, 0, ICE))
	_row.append(_spawn(Vector3(4.4, 0, 0), 90.0, 1, NATURE))
	_set_zoom(12.0)
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		_take_shots()
	elif "--detail" in args:
		_detail_only()
	elif "--classes" in args:
		_classes_only()


func _detail_only() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.0)
	await _detail_sheet("champion_wayfinder_detail_a", 0, FIRE)
	await _detail_sheet("champion_wayfinder_detail_b", 1, SHADOW)
	await _pose_sheet("champion_wayfinder_poses_side", 90.0, 14.0)
	await _pose_sheet("champion_wayfinder_poses_front", 20.0, 55.0)
	get_tree().quit()


## One unit alone, close (not a game angle): front, 3/4 front, side, back, 3/4 back, game angle 55 deg at 5 m.
func _detail_sheet(nm: String, variant: int, col: Color) -> void:
	for m in _row:
		m.get_parent().visible = false
	var u := _spawn(Vector3(0, 0, 80.0), 0.0, variant, col)
	var h: Node3D = u.get_parent()
	var frames: Array[Image] = []
	await _wait(0.5)
	for f: Array in [[0.0, 10.0, 4.2], [35.0, 10.0, 4.2], [90.0, 10.0, 4.2], [180.0, 10.0, 4.2], [215.0, 22.0, 4.2],
			[20.0, 55.0, 5.5]]:
		h.rotation.y = deg_to_rad(float(f[0]))
		_set_zoom(float(f[2]), Vector3(0, 1.3, 80.0), float(f[1]))
		await _wait(0.25)
		frames.append(_grab().get_region(Rect2i(400, 0, 800, 900)))
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


func _spawn(at: Vector3, yaw_deg: float, variant: int, col: Color) -> Node3D:
	var m: Node3D = load(SCENE).instantiate()
	var holder := Node3D.new()      # stands in for Unit._visual: the model never moves its own root
	holder.position = at + ORIGIN
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	m.call(&"set_variant", variant)
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
		KEY_V:
			for m in _row:
				m.set_variant(1 - int(m.variant))
		KEY_Y:
			for m: Node3D in _row:
				m.get_parent().rotation.y += deg_to_rad(45.0)
		KEY_W:
			_walking = not _walking
			for m in _row:
				m.set_moving(5.8 if _walking else 0.0)
		KEY_C:
			for m in _row:
				m.play_cast(CASTS[_cast_i])
			_cast_i = (_cast_i + 1) % 3
		KEY_K:
			_cls_i = (_cls_i + 1) % CLASS_LIST.size()
			for m in _row:
				m.set_weapon_class(CLASS_LIST[_cls_i])


func _all(method: StringName) -> void:
	for m in _row:
		if m.has_method(method):
			m.call(method)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(1.2)
	var p := "champion_wayfinder_"
	for z: float in [12.0, 25.0, 40.0]:
		_set_zoom(z)
		await _wait(0.5)
		_crop_world(_grab(), ORIGIN + Vector3(1.1, 1.0, 0.0), 9.5).save_png(OUT + p + "z%d.png" % int(z))
	await _variants_sheet(p + "variants")
	await _pose_sheet(p + "poses_side", 90.0, 18.0)
	await _pose_sheet(p + "poses_front", 20.0, 55.0)
	await _anim_sheet(p + "anim")
	await _silhouettes("champion_wayfinder_silhouette")
	await _scale_lineup(p + "lineup")
	get_tree().quit()


## Close-ups (low detail camera, not a game angle) of both variants: front, 3/4 front, back; then the game angle.
func _variants_sheet(nm: String) -> void:
	for m in _row:
		m.get_parent().visible = false
	var extra: Array = []
	var yaws: Array[float] = [0.0, 35.0, 160.0]
	for v: int in 2:
		for i: int in 3:
			extra.append(_spawn(Vector3(-3.0 + 1.5 * float(i) + 4.6 * float(v), 0, 12.0), yaws[i], v, FIRE if v == 0 else SHADOW))
	var frames: Array[Image] = []
	await _wait(0.6)
	_set_zoom(6.5, Vector3(-1.5, 1.25, 12.0), 12.0)
	await _wait(0.3)
	frames.append(_grab())
	_set_zoom(6.5, Vector3(3.1, 1.25, 12.0), 12.0)
	await _wait(0.3)
	frames.append(_grab())
	_set_zoom(9.0, Vector3(-1.5, 0.6, 12.0), 55.0)
	await _wait(0.3)
	frames.append(_grab())
	_set_zoom(9.0, Vector3(3.1, 0.6, 12.0), 55.0)
	await _wait(0.3)
	frames.append(_grab())
	_contact(frames, nm, 2)
	for m in extra:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


## Key frames side by side: rest, attack release, flare_arrow, snare_line, trailblaze (loose), trailblaze rally.
func _pose_sheet(nm: String, yaw: float, pitch: float) -> void:
	for m in _row:
		m.get_parent().visible = false
	var rows: Array = [["rest", 0.0], ["attack", 0.15], ["flare_arrow", 0.40], ["snare_line", 0.25], ["trailblaze", 0.33],
		["trailblaze", 0.62]]
	var units: Array = []
	var n := rows.size()
	var t_max := 0.0
	for i: int in n:
		units.append(_spawn(Vector3((float(i) - float(n - 1) * 0.5) * 1.75, 0, 24.0), yaw, i % 2, FIRE))
		t_max = maxf(t_max, float(rows[i][1]))
	_set_zoom(8.0, Vector3(0.0, 1.3, 24.0), pitch)
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
			"attack":
				units[i].play_attack()
			_:
				units[i].play_cast(StringName(rows[i][0]))
	if t_max > elapsed:
		await _wait(t_max - elapsed)
	_save(nm)
	await _wait(1.3)
	for m in units:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true


## One frame per state (front + side pair): idle, walk, hit, level-up, death 0.3 / 0.6 / 0.9, revived.
func _anim_sheet(nm: String) -> void:
	for m in _row:
		m.get_parent().visible = false
	var a := _spawn(Vector3(-1.0, 0, 36.0), 20.0, 0, FIRE)
	var b := _spawn(Vector3(1.0, 0, 36.0), 90.0, 1, SHADOW)
	var pair: Array = [a, b]
	_set_zoom(7.0, Vector3(0.0, 1.2, 36.0), 40.0)
	var frames: Array[Image] = []
	await _wait(0.6)
	frames.append(_grab())
	for m in pair:
		m.set_moving(5.8)
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
		m.play_level_up()
	await _wait(0.12)
	frames.append(_grab())
	await _wait(0.6)
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


## Unlit black on white (the "black test"): front, 3/4 back, side, walking, and the bow drawn, at 25 m and 40 m.
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
	for m in _row:
		m.get_parent().visible = false
	var sil: Array = []
	var yaws: Array[float] = [0.0, 200.0, 90.0, 45.0]
	for i: int in 4:
		sil.append(_spawn(Vector3(-2.4 + 1.6 * float(i), 0, 48.0), yaws[i], i % 2, FIRE))
	await _wait(0.4)
	for g: Node in find_children("*", "GeometryInstance3D", true, false):
		if g == _ground:
			continue
		if g is GPUParticles3D or g.name == "Shadow":
			(g as Node3D).visible = false
		else:
			(g as GeometryInstance3D).material_override = black
	sil[3].set_moving(5.8)
	var imgs: Array[Image] = []
	var centre := ORIGIN + Vector3(0.0, 1.1, 48.0)
	for z: float in [25.0, 40.0]:
		_set_zoom(z, Vector3(0.0, 0.0, 48.0))
		await _wait(0.5)
		imgs.append(_crop_world(_grab(), centre, 7.2))
	# the bow drawn (flare_arrow on the first, attack on the third), from 40 m
	sil[3].set_moving(0.0)
	sil[0].play_cast(&"flare_arrow")
	await _wait(0.26)
	sil[2].play_attack()
	await _wait(0.13)
	imgs.append(_crop_world(_grab(), centre, 7.2))
	var w := imgs[0].get_width()
	var out := Image.create(w * 3 + 16, imgs[0].get_height(), false, imgs[0].get_format())
	out.fill(Color(0.8, 0.8, 0.8))
	for i: int in 3:
		out.blit_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i((w + 8) * i, 0))
	out.save_png(OUT + nm + ".png")
	await _wait(1.0)
	for m in sil:
		m.get_parent().queue_free()
	_ground.material_override = old_ground
	_env.environment = old_env
	for m in _row:
		m.get_parent().visible = true


## Scale: the Wayfinder next to an Ember Archer and a Nightbolt (1.6 m ranged soldiers) at 25 and 40 m.
func _scale_lineup(nm: String) -> void:
	for m in _row:
		m.get_parent().visible = false
	var extra: Array = []
	extra.append(_spawn(Vector3(-1.6, 0, 60.0), 0.0, 0, FIRE))
	extra.append(_spawn(Vector3(1.6, 0, 60.0), 30.0, 1, SHADOW))
	for i: int in SCALE_UNITS.size():
		if ResourceLoader.exists(SCALE_UNITS[i]):
			var u: Node3D = load(SCALE_UNITS[i]).instantiate()
			var h := Node3D.new()
			h.position = ORIGIN + Vector3(-4.6 + 9.2 * float(i), 0, 60.0)
			add_child(h)
			h.add_child(u)
			extra.append(u)
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
	for m in extra:
		m.get_parent().queue_free()
	for m in _row:
		m.get_parent().visible = true



# ---------------------------------------------------------------- class weapons (11.V2)

func _classes_only() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for m in _row:
		m.get_parent().visible = false
	await _wait(1.0)
	await _classes_sheet("champion_wayfinder_classes")
	await _class_poses_sheet("champion_wayfinder_class_poses")
	print("WAYFINDER CLASS SHOTS DONE")
	get_tree().quit()


## Columns: archetype (bow), spear, sword_shield, two_hand, wizard. Rows: front 3/4 and back 3/4 close-ups, then the
## whole line at the 40 m game camera (pitch 55, fov 50, nearest-upscaled so the real pixels show): lit, black test
## facing the camera, black test from behind while walking.
func _classes_sheet(nm: String) -> void:
	var z0 := 60.0
	var xs: Array[float] = [-4.4, -2.2, 0.0, 2.2, 4.4]
	var units: Array = []
	for i: int in 5:
		var u := _spawn(Vector3(xs[i], 0, z0), 0.0, 0, FIRE)
		u.set_weapon_class(CLASS_LIST[i], false)
		units.append(u)
	await _wait(0.6)
	var close: Array[Image] = []
	for yaw: float in [-30.0, 150.0]:
		for i: int in 5:
			for j: int in 5:
				units[j].get_parent().visible = j == i
			units[i].get_parent().rotation.y = deg_to_rad(yaw)
			var c := Vector3(xs[i], 1.35, z0)
			_set_zoom(5.4, c, 10.0)
			await _wait(0.3)
			close.append(_crop_box(_grab(), ORIGIN + c, 2.1, 3.0, 320, 457, false))
	for i: int in 5:
		units[i].get_parent().visible = true
		units[i].get_parent().rotation.y = deg_to_rad(20.0)
	var strips: Array[Image] = []
	var sc := Vector3(0.0, 1.1, z0)
	_cam.fov = 50.0
	_set_zoom(40.0, Vector3(0, 0, z0))
	await _wait(0.4)
	strips.append(_crop_box(_grab(), ORIGIN + sc, 12.0, 3.6, 1600, 480, true))
	# the black test: unlit black models on white
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
	for u: Node3D in units:
		for g: Node in u.find_children("*", "GeometryInstance3D", true, false):
			if g is GPUParticles3D or g.name == "Shadow":
				(g as Node3D).visible = false
			else:
				(g as GeometryInstance3D).material_override = black
	await _wait(0.3)
	strips.append(_crop_box(_grab(), ORIGIN + sc, 12.0, 3.6, 1600, 480, true))
	for u: Node3D in units:
		u.get_parent().rotation.y = deg_to_rad(200.0)
		u.set_moving(5.8)
	await _wait(0.45)
	strips.append(_crop_box(_grab(), ORIGIN + sc, 12.0, 3.6, 1600, 480, true))
	var out := Image.create(1600, 457 * 2 + 480 * 3 + 4 * 6, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.55, 0.55, 0.55))
	for i: int in close.size():
		close[i].convert(Image.FORMAT_RGBA8)
		out.blit_rect(close[i], Rect2i(0, 0, 320, 457), Vector2i((i % 5) * 320, (i / 5) * (457 + 6)))
	for k: int in strips.size():
		strips[k].convert(Image.FORMAT_RGBA8)
		out.blit_rect(strips[k], Rect2i(0, 0, 1600, 480), Vector2i(0, 2 * (457 + 6) + k * (480 + 6)))
	out.save_png(OUT + nm + ".png")
	for u: Node3D in units:
		u.get_parent().queue_free()
	_ground.material_override = old_ground
	_env.environment = old_env
	await _wait(0.3)


## One row per class: Signal Flare (the grab at the lantern, the throw), Snare Line (the coil flung), Trailblaze (the
## weapon raised), the class attack strike, then the 3 class skills (the kit's generic poses) at a key frame.
func _class_poses_sheet(nm: String) -> void:
	var z0 := 85.0
	var tiles: Array[Image] = []
	for r: int in 4:
		var cls: StringName = CLASS_LIST[r + 1]
		var u := _spawn(Vector3(0, 0, z0), -70.0, r % 2, SHADOW)
		u.set_weapon_class(cls, false)
		var c := Vector3(0.0, 1.35, z0)
		_set_zoom(5.6, c, 12.0)
		await _wait(0.5)
		var moments: Array = [[&"flare_arrow", 0.30], [&"flare_arrow", 0.48], [&"snare_line", 0.20], [&"trailblaze", 0.6],
			[&"attack", STRIKE_T[cls]]]
		moments.append_array(CLASS_SKILLS[cls])
		for mo: Array in moments:
			if mo[0] == &"attack":
				u.play_attack()
			else:
				u.play_cast(mo[0])
			await _until(u, &"_action_t", float(mo[1]))
			tiles.append(_crop_box(_grab(), ORIGIN + c, 2.6, 3.2, 250, 308, false))
			u.play_hit()
			u.play_attack()   # ends long holds (riposte, whirlwind)
			await _wait(1.0)
		u.get_parent().queue_free()
		await _wait(0.2)
	var cols := 8
	var out := Image.create(250 * cols, 308 * 4, false, Image.FORMAT_RGBA8)
	for i: int in tiles.size():
		tiles[i].convert(Image.FORMAT_RGBA8)
		out.blit_rect(tiles[i], Rect2i(0, 0, 250, 308), Vector2i((i % cols) * 250, (i / cols) * 308))
	out.save_png(OUT + nm + ".png")


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


## Crop a window that keeps the same world size at every zoom, resized to 800 x 450.
func _crop_img(img: Image, z: float) -> Image:
	var vw := img.get_width()
	var vh := img.get_height()
	var w: int = clampi(int(float(vw) * 12.0 / z * 0.62), 80, vw)
	var h: int = int(float(w) * 9.0 / 16.0)
	var cx: int = vw / 2
	var cy: int = vh / 2 - int(h * 0.1)
	var r := Rect2i(clampi(cx - w / 2, 0, vw - w), clampi(cy - h / 2, 0, vh - h), w, h)
	var c := img.get_region(r)
	c.resize(800, 450, Image.INTERPOLATE_NEAREST if z > 20.0 else Image.INTERPOLATE_BILINEAR)
	return c


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


func _save(nm: String) -> Image:
	var img := _grab()
	img.save_png(OUT + nm + ".png")
	return img
