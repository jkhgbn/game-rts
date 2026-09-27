extends Node3D
## Oathwall preview (task 9.V2): both variants in the real lighting / painted ground, posed deterministically.
## Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/units/champions/oathwall/tools/oathwall_preview.tscn -- --shots
## writes docs/art/screens/champion_oathwall_preview.png (contact sheet, 4 x 4 tiles of 480 px) and
## docs/art/screens/champion_oathwall_variants.png (A and B, 3/4 front and back, 800 px) and
## docs/art/screens/champion_oathwall_silhouette.png (black on white, 3 tiles), then quits.
## Sheet rows (left to right):
##   1 Garran (A, Fire) 3/4 front · Gerda (B, Shadow team) 3/4 front · A back 3/4 (cape, sash tails) · B profile
##   2 RTS camera (pitch 55, fov 50), centre crops: zoom 15 x2 · zoom 28 x3 · zoom 40 x4 · walk mid-stride
##   3 slam at the strike frame (side) · oath_of_iron peak · shield_bash shove · bulwark_stand planted (3 s in)
##   4 hit flash · level-up flash · death 0.5 s · idle fidget (door lifted)
## Silhouette: RTS zoom 40 crop x5 · RTS zoom 20 crop x2 · front view · side view (A left, B right).
## By hand (no args): 1 attack, 2 hit, 3 death, 4 level-up, 5 oath, 6 bash, 7 bulwark, 8 walk, 9 revive,
## V variant, F fidget, T team colour, wheel zoom.

const SCENE := "res://art/units/champions/oathwall/oathwall.tscn"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 0.95)
const TILE := 480
const OUT := "res://docs/art/screens/"

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 1.0, 0)
var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _a: Node3D
var _b: Node3D
var _sheet: Image
var _walking: bool = false
var _team_i: int = 0


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
	_cam.fov = 50.0
	_cam.far = 400.0
	add_child(_cam)
	_a = _spawn(Vector3(-1.3, 0, 0), 0, FIRE)
	_b = _spawn(Vector3(1.3, 0, 0), 1, SHADOW)
	_rts()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _spawn(at: Vector3, variant: int, team: Color) -> Node3D:
	var holder := Node3D.new()   # stands in for Unit._visual (facing lives here)
	holder.position = at
	add_child(holder)
	var m := (load(SCENE) as PackedScene).instantiate() as Node3D
	m.call(&"set_variant", variant)
	m.call(&"set_team_color", team)
	holder.add_child(m)
	return m


func _rts() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.fov = 50.0
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _look(from: Vector3, at: Vector3, fov: float = 40.0) -> void:
	_cam.fov = fov
	_cam.position = from
	_cam.look_at(at, Vector3.UP)


## 3/4 view of model m from direction `dir` (model-facing space: +Z = its face), `dist` metres.
func _portrait(m: Node3D, dir: Vector3, dist: float, h: float = 1.05) -> void:
	var holder := m.get_parent() as Node3D
	var c := holder.global_position + Vector3(0, h, 0)
	var d := holder.global_basis * dir.normalized()
	_look(c + d * dist, c)


func _place(m: Node3D, at: Vector3, yaw: float) -> void:
	var holder := m.get_parent() as Node3D
	holder.position = at
	holder.rotation.y = yaw


func _reset(m: Node3D) -> void:
	m.set_process(false)
	m.call(&"revive")
	m.call(&"set_moving", 0.0)
	m.call(&"_animate", 0.0)


## Plays the model's timeline to `t` seconds in 1/60 steps (deterministic pose; particles run in real time).
func _advance(m: Node3D, t: float) -> void:
	var n: int = int(round(t * 60.0))
	for i: int in n:
		m.call(&"_animate", 1.0 / 60.0)


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
	for m: Node3D in [_a, _b]:
		_reset(m)
	_sheet = Image.create(TILE * 4, TILE * 4, false, Image.FORMAT_RGB8)
	_sheet.fill(Color(0.08, 0.08, 0.09))
	# Row 1: portraits (the two stand far apart so each fills its own frame).
	_place(_a, Vector3(-3.0, 0, 0), 0.0)
	_place(_b, Vector3(3.0, 0, 0), 0.0)
	_portrait(_a, Vector3(0.55, 0.32, 1.0), 4.4)
	await _tile(0, 0)
	_portrait(_b, Vector3(0.55, 0.32, 1.0), 4.4)
	await _tile(1, 0)
	_portrait(_a, Vector3(-0.6, 0.35, -1.0), 4.4)
	await _tile(2, 0)
	_portrait(_b, Vector3(1.0, 0.12, 0.0), 4.4)
	await _tile(3, 0)
	# Row 2: the RTS camera.
	_place(_a, Vector3(-1.3, 0, 0), 0.25)
	_place(_b, Vector3(1.3, 0, 0), -0.35)
	focus = Vector3(0, 1.0, 0)
	zoom = 15.0
	_rts()
	await _tile(0, 1, 2)
	zoom = 28.0
	_rts()
	await _tile(1, 1, 3)
	zoom = 40.0
	_rts()
	await _tile(2, 1, 4)
	_place(_b, Vector3(3.0, 0, 0), 0.0)
	_place(_a, Vector3(-3.0, 0, 0), 0.0)
	_a.call(&"set_moving", 4.3)
	for i: int in 200:
		_advance(_a, 1.0 / 60.0)
		if float(_a.get(&"_walk_w")) >= 1.0 and absf(sin(TAU * float(_a.get(&"_walk_p")))) > 0.97:
			break
	_portrait(_a, Vector3(1.0, 0.25, 0.55), 4.6)
	await _tile(3, 1)
	_reset(_a)
	# Row 3: attack and the three casts (A).
	_a.call(&"play_attack")
	_advance(_a, 0.13)
	_portrait(_a, Vector3(1.0, 0.18, 0.15), 5.0, 1.0)
	await _tile(0, 2)
	_reset(_a)
	_a.call(&"play_cast", &"oath_of_iron")
	_advance(_a, 0.36)
	_portrait(_a, Vector3(0.6, 0.30, 1.0), 5.2, 1.3)
	await _tile(1, 2)
	_reset(_a)
	_a.call(&"play_cast", &"shield_bash")
	_advance(_a, 0.17)
	_portrait(_a, Vector3(1.0, 0.25, 0.5), 5.0, 1.0)
	await _tile(2, 2)
	_reset(_a)
	_a.call(&"play_cast", &"bulwark_stand")
	_advance(_a, 3.0)
	_portrait(_a, Vector3(0.55, 0.30, 1.0), 4.6, 0.9)
	await _tile(3, 2)
	_reset(_a)
	# Row 4: hit flash, level-up, death, fidget.
	_a.call(&"play_hit")
	_advance(_a, 0.04)
	_portrait(_a, Vector3(0.55, 0.32, 1.0), 4.4)
	await _tile(0, 3)
	_reset(_a)
	_a.call(&"play_level_up")
	_advance(_a, 0.08)
	await _tile(1, 3)
	_reset(_a)
	_a.call(&"play_death")
	_advance(_a, 0.5)
	_portrait(_a, Vector3(1.0, 0.35, 0.6), 4.6, 0.7)
	await _tile(2, 3)
	_reset(_a)
	_a.call(&"play_fidget")
	_advance(_a, 0.36)
	_portrait(_a, Vector3(0.55, 0.32, 1.0), 4.4)
	await _tile(3, 3)
	_reset(_a)
	_sheet.save_png(ProjectSettings.globalize_path(OUT + "champion_oathwall_preview.png"))
	print("saved champion_oathwall_preview.png")
	# Variants close-up: Garran (A, Fire) and Gerda (B, Shadow team), 3/4 front and 3/4 back, 800 px tiles.
	var big := Image.create(1600, 1600, false, Image.FORMAT_RGB8)
	var views: Array = [[_a, Vector3(0.5, 0.25, 1.0)], [_b, Vector3(0.5, 0.25, 1.0)], [_a, Vector3(-0.7, 0.3, -1.0)],
		[_b, Vector3(-0.7, 0.3, -1.0)]]
	for i: int in views.size():
		_portrait(views[i][0] as Node3D, views[i][1] as Vector3, 4.5, 1.0)
		await _frames(3)
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var side: int = img.get_height()
		var sub := img.get_region(Rect2i((img.get_width() - side) / 2, 0, side, side))
		sub.resize(800, 800, Image.INTERPOLATE_LANCZOS)
		sub.convert(big.get_format())
		big.blit_rect(sub, Rect2i(0, 0, 800, 800), Vector2i((i % 2) * 800, (i / 2) * 800))
	big.save_png(ProjectSettings.globalize_path(OUT + "champion_oathwall_variants.png"))
	print("saved champion_oathwall_variants.png")
	# Silhouette strip (black on white).
	_silhouette()
	_sheet = Image.create(TILE * 4, TILE, false, Image.FORMAT_RGB8)
	_place(_a, Vector3(-1.3, 0, 0), 0.25)
	_place(_b, Vector3(1.3, 0, 0), -0.35)
	zoom = 40.0
	_rts()
	await _tile(0, 0, 5)
	zoom = 20.0
	_rts()
	await _tile(1, 0, 2)
	_place(_a, Vector3(-1.4, 0, 0), 0.0)
	_place(_b, Vector3(1.4, 0, 0), 0.0)
	_look(Vector3(0, 1.2, 9.0), Vector3(0, 1.0, 0), 34.0)
	await _tile(2, 0)
	_place(_a, Vector3(-1.4, 0, 0), PI * 0.5)
	_place(_b, Vector3(1.4, 0, 0), PI * 0.5)
	await _tile(3, 0)
	_sheet.save_png(ProjectSettings.globalize_path(OUT + "champion_oathwall_silhouette.png"))
	print("saved champion_oathwall_silhouette.png")
	get_tree().quit()


func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	_env.environment.glow_enabled = false
	_env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.environment.background_mode = Environment.BG_COLOR
	_env.environment.background_color = Color.WHITE
	_env.environment.fog_enabled = false
	for m: Node3D in [_a, _b]:
		_paint(m, black)


func _paint(n: Node, mat: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			(c as GPUParticles3D).visible = false
		elif c is GeometryInstance3D:
			if c.name == "Shadow":
				(c as GeometryInstance3D).visible = false
			else:
				(c as GeometryInstance3D).material_override = mat
				(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_paint(c, mat)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 2.0, 3.0, 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 2.0, 3.0, 60.0)
		_rts()
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	for m: Node3D in [_a, _b]:
		m.set_process(true)
		match k.physical_keycode:
			KEY_1: m.call(&"play_attack")
			KEY_2: m.call(&"play_hit")
			KEY_3: m.call(&"play_death")
			KEY_4: m.call(&"play_level_up")
			KEY_5: m.call(&"play_cast", &"oath_of_iron")
			KEY_6: m.call(&"play_cast", &"shield_bash")
			KEY_7: m.call(&"play_cast", &"bulwark_stand")
			KEY_8: m.call(&"set_moving", 0.0 if _walking else 4.3)
			KEY_9: m.call(&"revive")
			KEY_V: m.call(&"set_variant", 1 - int(m.call(&"get_variant")))
			KEY_F: m.call(&"play_fidget")
			KEY_T: m.call(&"set_team_color", [FIRE, SHADOW, ICE][(_team_i + 1) % 3])
	if k.physical_keycode == KEY_8:
		_walking = not _walking
	if k.physical_keycode == KEY_T:
		_team_i = (_team_i + 1) % 3
