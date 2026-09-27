extends Node3D
## Champion class weapons preview (task 11.V1). Windowed only (the headless renderer draws nothing):
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/champions/weapons/tools/champion_weapons_preview.tscn -- --shots
## Writes docs/art/screens/:
##   champion_weapons_kit.png            the 7 pieces side by side (spear, quiver, javelin, sword, round shield,
##                                       greatsword, staff), front and side
##   champion_weapons_<champion>.png     5 columns (archetype, spear, sword_shield, two_hand, wizard) x 2 rows (front
##                                       3/4, back 3/4), the kit's GENERIC grips (per-champion grips: 11.V2-11.V5)
##   champion_weapons_poses_<champion>.png  4 attack strikes + the 12 class skill key frames (generic poses)
##   champion_weapons_z40.png            the 16 champion x class combos at the 40 m game camera, 4 kingdom colours
## Until 11.V2-11.V5 tag them, the models still hold their archetype weapons; this preview hides the two that are
## separate nodes (the Wayfinder's Bow, the Mender's Staff) to show the intended read; the Oathwall's hammer and the
## Coin-Cutter's knives are merged in their arms and stay visible here.
## Without --shots: 1-4 champion, 5-9 class (archetype, spear, sword_shield, two_hand, wizard), A attack, C next class
## skill, P pop, Y turn.

const OUT := "res://docs/art/screens/"
const CHAMPIONS: Array[String] = ["wayfinder", "oathwall", "coin_cutter", "mender"]
const CLASSES: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const SKILLS: Array = [[&"spear", &"lunge", 0.22], [&"spear", &"hobbling_javelin", 0.30], [&"spear", &"skewer", 0.32],
	[&"sword_shield", &"riposte", 0.6], [&"sword_shield", &"second_wind", 0.7], [&"sword_shield", &"shield_throw", 0.20],
	[&"two_hand", &"cleave", 0.30], [&"two_hand", &"crushing_blow", 0.40], [&"two_hand", &"whirlwind", 0.7],
	[&"wizard", &"arc_bolt", 0.22], [&"wizard", &"slipstep", 0.36], [&"wizard", &"starfall", 0.6]]
const STRIKE: Array = [[&"spear", 0.12], [&"sword_shield", 0.12], [&"two_hand", 0.16], [&"wizard", 0.14]]
const KINGDOMS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95), Color(0.35, 0.70, 0.25)]
const ORIGIN := Vector3(40.0, 0.0, 40.0)
const HIDE_ARCH: Array[String] = ["Root/Chest/ArmR/Bow", "Root/Chest/ArmR/Staff"]

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _model: Node3D
var _champ: int = 0
var _cls: int = 0
var _skill_i: int = 0


func _ready() -> void:
	_setup_world()
	_cam = Camera3D.new()
	_cam.fov = 40.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	if "--shots" in OS.get_cmdline_user_args():
		_take_shots()
	else:
		_model = _spawn(CHAMPIONS[0], Vector3.ZERO, 30.0, KINGDOMS[0])
		_view(4.6, Vector3(0, 1.05, 0), 12.0, 0.0)


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
	_ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(_ground)


func _spawn(champ: String, at: Vector3, yaw_deg: float, col: Color) -> Node3D:
	var holder := Node3D.new()
	holder.position = ORIGIN + at
	holder.rotation.y = deg_to_rad(yaw_deg)
	add_child(holder)
	var m: Node3D = (load("res://art/units/champions/%s/%s.tscn" % [champ, champ]) as PackedScene).instantiate()
	holder.add_child(m)
	for p: String in ["_idle_left", "_fidget_wait"]:
		if p in m:
			m.set(p, 1.0e9)
	m.call(&"set_team_color", col)
	return m


func _set_class(m: Node3D, cls: StringName, pop: bool = false) -> void:
	m.call(&"set_weapon_class", cls, pop)
	for p: String in HIDE_ARCH:
		var n := m.get_node_or_null(p) as Node3D
		if n:
			n.visible = cls == &""


func _view(dist: float, focus: Vector3, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	_cam.position = ORIGIN + focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.rotation = Vector3(-pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed) or _model == null:
		return
	var k := (event as InputEventKey).keycode
	if k >= KEY_1 and k <= KEY_4:
		_champ = k - KEY_1
		_model.get_parent().queue_free()
		_model = _spawn(CHAMPIONS[_champ], Vector3.ZERO, 30.0, KINGDOMS[0])
		_set_class(_model, CLASSES[_cls])
	elif k >= KEY_5 and k <= KEY_9:
		_cls = k - KEY_5
		_set_class(_model, CLASSES[_cls], true)
	match k:
		KEY_A:
			_model.call(&"play_attack")
		KEY_C:
			var s: Array = SKILLS[_skill_i % SKILLS.size()]
			_skill_i += 1
			_set_class(_model, s[0])
			_model.call(&"play_cast", s[1])
		KEY_P:
			_set_class(_model, &"")
			_set_class(_model, CLASSES[maxi(_cls, 1)], true)
		KEY_Y:
			_model.get_parent().rotation.y += deg_to_rad(45.0)


# ---------------------------------------------------------------- screenshots

func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(0.8)
	await _kit_sheet()
	for c: String in CHAMPIONS:
		await _champion_sheet(c)
	for c: String in CHAMPIONS:
		await _poses_sheet(c)
	await _z40_sheet()
	print("CHAMPION WEAPONS SHOTS DONE")
	get_tree().quit()


## The 7 pieces standing in a row (their piece space, +Y up), front then side.
func _kit_sheet() -> void:
	var kit: GDScript = load("res://art/units/champions/weapons/champion_weapon_kit.gd")
	var pieces: Array[StringName] = [&"spear", &"quiver", &"javelin", &"sword", &"round_shield", &"greatsword", &"staff"]
	var nodes: Array[Node3D] = []
	for i: int in pieces.size():
		var mi := MeshInstance3D.new()
		mi.mesh = kit.call(&"piece_mesh", pieces[i])
		mi.position = ORIGIN + Vector3(-2.4 + 0.8 * float(i), 1.05, 0.0)
		if pieces[i] == &"round_shield":
			mi.position.y = 1.3
		mi.set_instance_shader_parameter(&"ao_height", 2.6)
		add_child(mi)
		nodes.append(mi)
	var imgs: Array[Image] = []
	for yaw: float in [0.0, 90.0]:
		for n: Node3D in nodes:
			n.rotation.y = deg_to_rad(-yaw)
		_view(6.2, Vector3(0, 1.25, 0), 6.0, 0.0)
		await _wait(0.4)
		imgs.append(_grab().get_region(Rect2i(100, 40, 1400, 820)))
	for n: Node3D in nodes:
		n.queue_free()
	_compose(imgs, 1, 1400, 820, "champion_weapons_kit")


## 5 columns (archetype + 4 classes) x 2 rows (front 3/4, back 3/4), one model at a time, cropped.
func _champion_sheet(champ: String) -> void:
	var m := _spawn(champ, Vector3.ZERO, 0.0, KINGDOMS[0])
	await _wait(0.3)
	var front: Array[Image] = []
	var back: Array[Image] = []
	for cls: StringName in CLASSES:
		_set_class(m, cls)
		m.get_parent().rotation.y = deg_to_rad(-30.0)
		_view(4.9, Vector3(0, 1.15, 0), 10.0, 0.0)
		await _wait(0.35)
		front.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
		m.get_parent().rotation.y = deg_to_rad(150.0)
		await _wait(0.25)
		back.append(_grab().get_region(Rect2i(450, 20, 700, 860)))
	m.get_parent().queue_free()
	var all: Array[Image] = []
	all.append_array(front)
	all.append_array(back)
	_compose(all, 5, 350, 430, "champion_weapons_" + champ)


## Strike frames of the 4 attack styles, then the 12 class skills at a key frame (side 3/4 view).
func _poses_sheet(champ: String) -> void:
	var m := _spawn(champ, Vector3.ZERO, 0.0, KINGDOMS[1])
	await _wait(0.3)
	var imgs: Array[Image] = []
	m.get_parent().rotation.y = deg_to_rad(-55.0)
	_view(5.4, Vector3(0, 1.1, 0.3), 14.0, 0.0)
	for s: Array in STRIKE:
		_set_class(m, s[0])
		await _wait(0.2)
		m.call(&"play_attack")
		await _until(m, float(s[1]))
		imgs.append(_grab().get_region(Rect2i(400, 0, 800, 900)))
		await _wait(0.9)
	for s: Array in SKILLS:
		_set_class(m, s[0])
		await _wait(0.2)
		m.call(&"play_cast", s[1])
		await _until(m, float(s[2]))
		imgs.append(_grab().get_region(Rect2i(400, 0, 800, 900)))
		m.call(&"play_hit")   # ends long holds quickly (riposte, whirlwind) by the next action below
		m.call(&"play_attack")
		await _wait(1.0)
	m.get_parent().queue_free()
	_compose(imgs, 8, 300, 338, "champion_weapons_poses_" + champ)


## The 16 champion x class combos at the 40 m game camera (pitch 55), one kingdom colour per row, then nearest-upscaled.
func _z40_sheet() -> void:
	var made: Array[Node3D] = []
	for r: int in CHAMPIONS.size():
		for c: int in 4:
			var m := _spawn(CHAMPIONS[r], Vector3(-4.2 + 2.8 * float(c), 0, -4.2 + 2.8 * float(r)), 20.0, KINGDOMS[r])
			made.append(m)
			_set_class(m, CLASSES[c + 1])
	await _wait(0.5)
	_cam.fov = 50.0
	made[1].call(&"set_moving", 5.0)
	made[6].call(&"play_attack")
	_view(40.0, Vector3(0, 0, 0), 55.0, 0.0)
	await _wait(0.12)
	var img := _grab()
	var w := 560
	var h := 400
	var crop := img.get_region(Rect2i(800 - w / 2, 450 - h / 2, w, h))
	crop.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + "champion_weapons_z40.png")
	_view(14.0, Vector3(0, 0, 0), 55.0, 0.0)
	await _wait(0.3)
	_grab().save_png(OUT + "champion_weapons_z14.png")
	for m: Node3D in made:
		m.get_parent().queue_free()


func _compose(imgs: Array[Image], cols: int, w: int, h: int, nm: String) -> void:
	var rows: int = (imgs.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(OUT + nm + ".png")


func _until(m: Node3D, t: float) -> void:
	var guard := 0
	while float(m.get(&"_action_t")) < t and guard < 300:
		await get_tree().process_frame
		guard += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _grab() -> Image:
	return get_viewport().get_texture().get_image()
