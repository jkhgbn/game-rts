extends Node3D
## Oathwall class weapons preview (task 11.V3). Windowed only (the headless renderer draws nothing):
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/champions/oathwall/tools/oathwall_classes_preview.tscn -- --shots
## Writes docs/art/screens/champion_oathwall_classes.png: one row per class (archetype hammer, spear, sword_shield,
## two_hand, wizard), 9 columns of 300 px:
##   front 3/4 · back 3/4 · attack strike · Oath of Iron peak · Shield Bash shove · Bulwark Stand (3 s) · the class
##   moment (archetype: walk; spear: Hobbling Javelin, door planted; sword_shield: Shield Throw, door leaving; two_hand /
##   wizard: Shield Bash swing-off, door over the shoulder) · 40 m game camera (x5 crop) · 40 m black silhouette.
## Without --shots: 1-5 class, A attack, O oath, B bash, U bulwark, T class skill 3, W walk, Y turn.

const SCENE := "res://art/units/champions/oathwall/oathwall.tscn"
const OUT := "res://docs/art/screens/"
const CLASSES: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const STRIKE: Array[float] = [0.12, 0.12, 0.12, 0.16, 0.14]
const TEAM := Color(0.42, 0.22, 0.60)
const TILE := 300
const COLS := 9

var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _m: Node3D
var _sheet: Image
var _walking: bool = false


func _ready() -> void:
	_env = WorldEnvironment.new()
	_env.environment = (load("res://art/environment/world_env.tres") as Environment).duplicate()
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
	pm.size = Vector2(200, 200)
	_ground.mesh = pm
	var spots: Array[Vector4] = []
	var gm: Material = EnvProps.ground_material(Vector3(-40, 0, 10), Vector3(40, 0, 10), spots)
	if gm == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.30, 0.34, 0.22)
		gm = sm
	_ground.material_override = gm
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.far = 400.0
	add_child(_cam)
	_m = _spawn()
	_portrait(Vector3(0.55, 0.30, 1.0), 5.0, 1.1)
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn() -> Node3D:
	var holder := Node3D.new()
	add_child(holder)
	var m := (load(SCENE) as PackedScene).instantiate() as Node3D
	m.set(&"fidget_every", 0.0)
	m.call(&"set_team_color", TEAM)
	holder.add_child(m)
	return m


func _look(from: Vector3, at: Vector3, fov: float = 40.0) -> void:
	_cam.fov = fov
	_cam.position = from
	_cam.look_at(at, Vector3.UP)


func _portrait(dir: Vector3, dist: float, h: float = 1.1) -> void:
	var holder := _m.get_parent() as Node3D
	var c := holder.global_position + Vector3(0, h, 0)
	_look(c + holder.global_basis * dir.normalized() * dist, c)


func _rts(zoom: float) -> void:
	var p: float = deg_to_rad(55.0)
	_cam.fov = 50.0
	_cam.position = Vector3(0.0, sin(p) * zoom, cos(p) * zoom) + Vector3(0, 1.0, 0)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _reset(cls: StringName) -> void:
	_m.call(&"revive")
	_m.set_process(false)
	_m.call(&"set_moving", 0.0)
	_m.call(&"set_weapon_class", cls, false)
	(_m.get_parent() as Node3D).rotation.y = 0.0
	# clear the one-shot dust / sparks left over from the previous tile
	for p: Node in _m.get_node("Fx").get_children():
		if p is GPUParticles3D:
			(p as GPUParticles3D).restart()
			(p as GPUParticles3D).emitting = false
	_m.call(&"_animate", 0.0)


## Plays the model's timeline to `t` seconds in 1/60 steps (deterministic pose).
func _advance(t: float) -> void:
	for i: int in int(round(t * 60.0)):
		_m.call(&"_animate", 1.0 / 60.0)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _tile(col: int, row: int, crop_k: int = 1) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var side: int = img.get_height() / crop_k
	var sub := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
	sub.resize(TILE, TILE, Image.INTERPOLATE_NEAREST if crop_k > 1 else Image.INTERPOLATE_LANCZOS)
	sub.convert(_sheet.get_format())
	_sheet.blit_rect(sub, Rect2i(0, 0, TILE, TILE), Vector2i(col * TILE, row * TILE))


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _frames(20)
	_sheet = Image.create(TILE * COLS, TILE * CLASSES.size(), false, Image.FORMAT_RGB8)
	_sheet.fill(Color(0.08, 0.08, 0.09))
	for r: int in CLASSES.size():
		var cls: StringName = CLASSES[r]
		_reset(cls)
		_portrait(Vector3(0.55, 0.30, 1.0), 5.0)
		await _tile(0, r)
		_portrait(Vector3(-0.6, 0.35, -1.0), 5.0)
		await _tile(1, r)
		_m.call(&"play_attack")
		_advance(STRIKE[r] + 0.01)
		_portrait(Vector3(1.0, 0.20, 0.35), 5.4, 1.0)
		await _tile(2, r)
		_reset(cls)
		_m.call(&"play_cast", &"oath_of_iron")
		_advance(0.40)
		_portrait(Vector3(0.6, 0.25, 1.0), 5.6, 1.3)
		await _tile(3, r)
		_reset(cls)
		_m.call(&"play_cast", &"shield_bash")
		_advance(0.23 if r >= 3 else 0.17)
		_portrait(Vector3(1.0, 0.25, 0.5), 5.2, 1.0)
		await _tile(4, r)
		_reset(cls)
		_m.call(&"play_cast", &"bulwark_stand")
		_advance(3.0)
		_portrait(Vector3(0.55, 0.30, 1.0), 5.0, 0.9)
		await _tile(5, r)
		_reset(cls)
		match cls:
			&"":
				_m.call(&"set_moving", 4.3)
				for i: int in 200:
					_advance(1.0 / 60.0)
					if float(_m.get(&"_walk_w")) >= 1.0 and absf(sin(TAU * float(_m.get(&"_walk_p")))) > 0.97:
						break
				_portrait(Vector3(1.0, 0.25, 0.55), 5.0)
			&"spear":
				_m.call(&"play_cast", &"hobbling_javelin")
				_advance(0.30)
				_portrait(Vector3(0.9, 0.30, 0.8), 5.4, 1.1)
			&"sword_shield":
				_m.call(&"play_cast", &"shield_throw")
				_advance(0.32)
				_portrait(Vector3(1.0, 0.45, 0.6), 6.5, 1.2)
			_:
				_m.call(&"play_cast", &"shield_bash")
				_advance(0.07)
				_portrait(Vector3(-0.8, 0.30, -0.6), 5.0, 1.3)
		await _tile(6, r)
		_reset(cls)
		(_m.get_parent() as Node3D).rotation.y = 0.35
		_m.call(&"_animate", 0.0)
		_rts(40.0)
		await _tile(7, r, 5)
	# Silhouettes at 40 m (black on white).
	_silhouette_world()
	for r: int in CLASSES.size():
		_m.get_parent().queue_free()
		_m = _spawn()
		await _frames(2)
		_reset(CLASSES[r])
		(_m.get_parent() as Node3D).rotation.y = 0.35
		_m.call(&"_animate", 0.0)
		_paint(_m)
		_rts(40.0)
		await _tile(8, r, 5)
	_sheet.save_png(ProjectSettings.globalize_path(OUT + "champion_oathwall_classes.png"))
	print("saved champion_oathwall_classes.png")
	get_tree().quit()


func _silhouette_world() -> void:
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	_env.environment.glow_enabled = false
	_env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.environment.background_mode = Environment.BG_COLOR
	_env.environment.background_color = Color.WHITE
	_env.environment.fog_enabled = false


func _paint(n: Node) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	_paint_rec(n, black)


func _paint_rec(n: Node, mat: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			(c as GPUParticles3D).visible = false
		elif c is GeometryInstance3D:
			if c.name == "Shadow":
				(c as GeometryInstance3D).visible = false
			else:
				(c as GeometryInstance3D).material_override = mat
				(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_paint_rec(c, mat)


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	_m.set_process(true)
	match k.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_m.call(&"set_weapon_class", CLASSES[k.physical_keycode - KEY_1])
		KEY_A: _m.call(&"play_attack")
		KEY_O: _m.call(&"play_cast", &"oath_of_iron")
		KEY_B: _m.call(&"play_cast", &"shield_bash")
		KEY_U: _m.call(&"play_cast", &"bulwark_stand")
		KEY_T:
			var ids: Dictionary = {&"spear": &"hobbling_javelin", &"sword_shield": &"shield_throw",
				&"two_hand": &"whirlwind", &"wizard": &"starfall"}
			_m.call(&"play_cast", ids.get(_m.call(&"weapon_class"), &"oath_of_iron"))
		KEY_W:
			_walking = not _walking
			_m.call(&"set_moving", 4.3 if _walking else 0.0)
		KEY_Y:
			(_m.get_parent() as Node3D).rotation.y += deg_to_rad(45.0)
