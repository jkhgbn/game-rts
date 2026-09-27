extends Node3D
## Preview of the Dread Paddock (task 13.V26) from the RTS camera (pitch 55, fov 50) on the game's ground material.
## A: gate toward the camera (yaw PI); B: gate +X (the camera sees the local +X flank: the player's own Lair in the
## 1v1); C: gate -X (the enemy's view). A Nightmare Knight waits at A's gate (play_raise), the Mage Archer rises in B's
## circle (play_call). The Shadow buildings (Dusk Keep, Gloom Hall, Gloom Bazaar, Night Spire, hovel) stand in a row
## behind for the 40 m context shot.
## Windowed run:
##   Godot --path . res://art/buildings/lair/shadow/tools/dread_paddock_preview.tscn --quit-after 9000 -- --shots
## Saves docs/art/screens/13_v26_*.png, prints node / draw-call counts, then quits.
## By hand: wheel = zoom, Q / E = turn, 1 rebuild (6 s), 2 training pulse, 3 HP 40 %, 4 HP 20 %, 5 full HP, 6 destroy,
## 7 toggle selected, 8 blue team, 9 raise, R call, 0 new paddocks.

const PADDOCK := "res://art/buildings/lair/shadow/dread_paddock.tscn"
const KNIGHT := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const ARCHER := "res://art/units/champions/mage_archer/mage_archer.tscn"
const ROW: Array = [
	["res://art/buildings/dusk_keep.tscn", Vector3(-15.0, 0, -17.0)],
	["res://art/buildings/shadow_hall.tscn", Vector3(-4.0, 0, -17.0)],
	["res://art/buildings/market/shadow/market_shadow.tscn", Vector3(5.0, 0, -17.0)],
	["res://art/buildings/shadow_tower.tscn", Vector3(11.5, 0, -15.0)],
	["res://art/buildings/hovel.tscn", Vector3(16.0, 0, -16.0)],
]
const OFS := Vector3(-26, 0, 24)   # a grass patch of the ground material (no keep plaza)
const POS_A := Vector3(0, 0, 0)
const POS_B := Vector3(14, 0, 0)
const POS_C := Vector3(26, 0, 0)

var _cam: Camera3D
var _ground: MeshInstance3D
var _env: WorldEnvironment
var _pads: Array[Node3D] = []
var _extras: Array[Node3D] = []
var _knight: Node3D
var _archer: Node3D
var _zoom: float = 22.0
var _focus: Vector3 = Vector3(0, 2.0, 0)
var _pitch: float = 55.0
var _yaw: float = 0.0
var _build_p: float = 1.0
var _selected: bool = false


func _ready() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 150.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres") as Material
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	for r: Array in ROW:
		_add_extra(r[0], r[1], PI)
	_new_paddocks()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _add_extra(path: String, pos: Vector3, yaw: float) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = OFS + pos
	n.rotation.y = yaw
	add_child(n)
	_extras.append(n)
	return n


func _new_paddocks() -> void:
	for b: Node3D in _pads:
		b.queue_free()
	_pads.clear()
	var yaws: Array[float] = [PI, -PI * 0.5, PI * 0.5]
	var poss: Array[Vector3] = [POS_A, POS_B, POS_C]
	for i: int in 3:
		var b := (load(PADDOCK) as PackedScene).instantiate() as Node3D
		b.position = OFS + poss[i]
		b.rotation.y = yaws[i]
		add_child(b)
		_pads.append(b)
	_build_p = 1.0


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_all(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(_pitch)
	var y: float = deg_to_rad(_yaw)
	_cam.position = OFS + _focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * _zoom
	_cam.rotation = Vector3(-p, y, 0.0)


func _all(method: StringName, arg: Variant = null) -> void:
	for b: Node3D in _pads:
		if arg == null:
			b.call(method)
		else:
			b.call(method, arg)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 3.0, 6.0, 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 3.0, 6.0, 60.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_Q:
				_yaw -= 20.0
				_apply()
			KEY_E:
				_yaw += 20.0
				_apply()
			KEY_1:
				_build_p = 0.0
			KEY_2:
				_all(&"play_training_pulse")
			KEY_3:
				_all(&"set_health_ratio", 0.4)
			KEY_4:
				_all(&"set_health_ratio", 0.2)
			KEY_5:
				_all(&"set_health_ratio", 1.0)
			KEY_6:
				_all(&"play_destroyed")
			KEY_7:
				_selected = not _selected
				_all(&"set_selected", _selected)
			KEY_8:
				_all(&"set_team_color", Color(0.20, 0.45, 0.95))
			KEY_9:
				_all(&"play_raise")
			KEY_R:
				_all(&"play_call")
			KEY_0:
				_new_paddocks()


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/13_v26_%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(nm: String, zoom: float, focus: Vector3, settle: float = 1.0, pitch: float = 55.0, yaw: float = 0.0) -> Image:
	_zoom = zoom
	_focus = focus
	_pitch = pitch
	_yaw = yaw
	_apply()
	await _wait(settle)
	return _save(nm)


func _count(n: Node) -> Vector2i:
	var c := Vector2i.ZERO
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		c.x += 1
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).visible:
		c.y += 1
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _count(ch)
	return c


## Visible mesh nodes of the Paddock, and the draw calls of the Paddock alone vs the Gloom Hall / Gloom Bazaar alone.
func _report() -> void:
	var c: Vector2i = _count(_pads[0])
	print("NODES dread_paddock mesh=%d multimesh=%d" % [c.x, c.y])
	_ground.visible = false
	var solo: Array = [["dread_paddock", _pads[0], POS_A]]
	for i: int in _extras.size():
		var nm: String = (ROW[i][0] as String).get_file().get_basename()
		if nm in ["shadow_hall", "market_shadow"]:
			solo.append([nm, _extras[i], ROW[i][1]])
	for s: Array in solo:
		var target: Node3D = s[1]
		for n: Node in get_children():
			if n is Node3D and (n in _pads or n in _extras or n == _knight or n == _archer):
				(n as Node3D).visible = n == target
		_zoom = 20.0
		_focus = (s[2] as Vector3) + Vector3(0, 2.0, 0)
		_yaw = 0.0
		_apply()
		await _wait(0.4)
		print("DRAWS %s draw_calls=%d objects=%d prims=%d" % [s[0],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	for n: Node in get_children():
		if n is Node3D and (n in _pads or n in _extras or n == _knight or n == _archer):
			(n as Node3D).visible = true
	_ground.visible = true


func _sheet(imgs: Array[Image], nm: String, cols: int) -> void:
	var w: int = 640
	var h: int = 360
	var rows: int = ceili(float(imgs.size()) / cols)
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i: int in imgs.size():
		var img: Image = imgs[i]
		img.convert(Image.FORMAT_RGBA8)
		img.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13_v26_%s.png" % nm))


## Black silhouettes on white (art-keep.md 0.1 test): the three Paddocks and the Shadow row (for comparison); decals,
## pools, halos and particles left out. One-way (the last shot).
func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	_ground.visible = false
	if _knight:
		_knight.visible = false
	if _archer:
		_archer.visible = false
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	_env.environment = env
	for b: Node3D in _pads:
		b.set_process(false)   # keep the halos hidden (the model re-shows them every frame)
	for b: Node3D in _pads + _extras:
		_blacken(b, black)


func _blacken(n: Node, m: Material) -> void:
	if n is GPUParticles3D:
		(n as GPUParticles3D).visible = false
	elif n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.name.contains("Decal") or g.name.contains("Pool") or g.name.contains("Halo") or g.name.contains("Outline") \
				or g.name.contains("Glow") or g.name.contains("Shadow"):
			g.visible = false
		else:
			g.material_override = m
	for c: Node in n.get_children():
		_blacken(c, m)


func _spawn_actors() -> void:
	# The Nightmare Knight waits in front of A's gate (A's gate faces the camera: world +Z).
	if ResourceLoader.exists(KNIGHT):
		_knight = (load(KNIGHT) as PackedScene).instantiate() as Node3D
		_knight.position = OFS + POS_A + Vector3(0.55, 0, 5.2)
		_knight.rotation.y = PI
		add_child(_knight)
	# The Mage Archer in B's circle.
	if ResourceLoader.exists(ARCHER):
		_archer = (load(ARCHER) as PackedScene).instantiate() as Node3D
		add_child(_archer)
		_archer.global_position = _pads[1].call(&"get_call_point")
		_archer.rotation.y = -PI * 0.5


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(0.6)
	await _report()
	_spawn_actors()
	await _wait(0.3)
	# Close-ups and game zooms of A (gate toward the camera).
	await _shot("a_z10", 10.0, POS_A + Vector3(0.0, 3.0, 0.5), 1.5)
	await _shot("a_z16", 16.0, POS_A + Vector3(0, 2.6, 0))
	await _shot("a_low", 12.0, POS_A + Vector3(0, 3.2, 0.0), 1.0, 25.0)
	await _shot("a_back_z12", 12.0, POS_A + Vector3(0, 2.4, 0), 0.6, 45.0, 180.0)
	# The two game views (flanks): B = the player's own Lair (local +X), C = the enemy's (local -X).
	await _shot("b_player_view_z14", 14.0, POS_B + Vector3(0, 2.2, 0))
	await _shot("c_enemy_view_z14", 14.0, POS_C + Vector3(0, 2.2, 0))
	await _shot("b_yard_close_z8", 8.0, POS_B + Vector3(0, 1.4, 0.6), 0.6)
	await _shot("bc_z30", 30.0, (POS_B + POS_C) * 0.5 + Vector3(0, 1.0, 0))
	await _shot("context_z40", 40.0, Vector3(3.0, 0.0, -8.0))
	# Raise (A, the Knight at the gate) and call (B, the Mage Archer in the circle).
	_pads[0].call(&"play_raise")
	await _wait(0.8)
	var raise_img: Image = _save("raise_0s8_far")
	await _shot("raise_close", 11.0, POS_A + Vector3(0, 2.6, 1.5), 0.05)
	await _wait(2.6)
	_pads[1].call(&"play_call")
	if _archer and _archer.has_method(&"play_call"):
		_archer.call(&"play_call")
	await _shot("call_0s7", 9.0, POS_B + Vector3(0, 1.6, 0.2), 0.7)
	var call_img: Image = await _shot("call_1s5", 9.0, POS_B + Vector3(0, 1.6, 0.2), 0.8)
	await _wait(1.5)
	# States on B (the player's view) at z 18.
	var sheet: Array[Image] = []
	var f := POS_B + Vector3(0, 2.2, 0)
	_all(&"set_construction_progress", 0.0)
	sheet.append(await _shot("state_construct00", 18.0, f, 0.4))
	_all(&"set_construction_progress", 0.35)
	sheet.append(await _shot("state_construct35", 18.0, f, 0.4))
	_all(&"set_construction_progress", 0.75)
	sheet.append(await _shot("state_construct75", 18.0, f, 0.4))
	_all(&"set_construction_progress", 1.0)
	await _wait(0.12)
	_save("state_complete_flash")
	await _wait(1.5)
	_all(&"set_selected", true)
	_all(&"play_training_pulse")
	await _wait(0.12)
	sheet.append(_save("state_selected_pulse"))
	_all(&"set_selected", false)
	await _wait(0.8)
	_all(&"play_raise")
	await _wait(0.6)
	sheet.append(_save("state_raise_0s6"))
	await _wait(2.8)
	sheet.append(raise_img)
	sheet.append(call_img)
	_all(&"set_health_ratio", 0.4)
	sheet.append(await _shot("state_hp40", 18.0, f, 2.5))
	_all(&"set_health_ratio", 0.2)
	sheet.append(await _shot("state_hp20", 18.0, f, 2.0))
	var finished: Array[int] = [0]
	for b: Node3D in _pads:
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	if _archer:
		_archer.visible = false
	_all(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_save("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_save("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_save("state_destroyed_3s3"))
	print("destroyed_finished emitted: ", finished[0], " / ", _pads.size())
	_new_paddocks()
	await get_tree().process_frame
	_all(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_all(&"set_health_ratio", 1.0)
	_all(&"set_team_color", Color(0.20, 0.45, 0.95))
	sheet.append(await _shot("state_healed_blue", 18.0, f, 3.0))
	_sheet(sheet, "states", 3)
	print("saved states sheet")
	_all(&"set_team_color", Color(0.42, 0.22, 0.60))
	await _wait(0.3)
	_silhouette()
	await _shot("silhouette_z40", 40.0, Vector3(3.0, 0.0, -8.0), 0.5)
	await _shot("silhouette_views_z30", 30.0, (POS_A + POS_C) * 0.5, 0.3)
	get_tree().quit()
