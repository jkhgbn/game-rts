extends Node3D
## Preview of the Gloom Bazaar (task 10.V2) from the RTS camera (pitch 55, fov 50) on the game's ground material.
## A: gate toward the camera (yaw PI); B / C: gates turned +X / -X like the 1v1 (Building._gate_yaw). The Gloom Hall,
## a Night Spire and a Gloom Thrall stand beside A for scale; the other Bazaars (if they exist) line up behind.
## Windowed run:
##   Godot --path . res://art/buildings/market/shadow/market_shadow_preview.tscn -- --tag=v1 --shots
## Saves docs/art/screens/market_shadow_<tag>_*.png, prints node / draw-call counts, then quits.
## By hand: wheel = zoom, 1 rebuild (6 s), 2 training pulse, 3 HP 40 %, 4 HP 20 %, 5 full HP, 6 destroy,
## 7 toggle selected, 8 blue team, 9 delivery, 0 new buildings.

const BAZAAR := "res://art/buildings/market/shadow/market_shadow.tscn"
const HALL := "res://art/buildings/shadow_hall.tscn"
const SPIRE := "res://art/buildings/shadow_tower.tscn"
const THRALL := "res://art/units/shadow/gloom_thrall.tscn"
const CARAVAN := "res://art/units/caravan/caravan.tscn"
const OTHERS: Array[String] = ["res://art/buildings/market/fire/market_fire.tscn",
	"res://art/buildings/market/ice/market_ice.tscn", "res://art/buildings/market/nature/market_nature.tscn"]
const OFS := Vector3(-26, 0, 24)   # a grass patch of the ground material (no keep plaza)
const POS_A := Vector3(0, 0, 0)
const POS_B := Vector3(16, 0, 0)
const POS_C := Vector3(28, 0, 0)

var _cam: Camera3D
var _ground: MeshInstance3D
var _env: WorldEnvironment
var _baz: Array[Node3D] = []
var _extras: Array[Node3D] = []
var _others: Array[Node3D] = []
var _tag: String = "v1"
var _zoom: float = 22.0
var _focus: Vector3 = Vector3(0, 2.0, 0)
var _pitch: float = 55.0
var _build_p: float = 1.0
var _selected: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
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
	_add_extra(HALL, Vector3(-11.0, 0, 1.0), PI)
	_add_extra(SPIRE, Vector3(-5.0, 0, -5.5), PI)
	var th: Node3D = _add_extra(THRALL, POS_A + Vector3(-1.2, 0, -4.6), 0.3)
	if th:
		th.scale = Vector3.ONE
	_add_extra(CARAVAN, POS_A + Vector3(-4.0, 0, -5.0), PI * 0.6)
	for i: int in OTHERS.size():
		var o: Node3D = _add_extra(OTHERS[i], Vector3(-10.0 + 10.0 * i, 0, -16.0), PI)
		if o:
			_others.append(o)
	_new_bazaars()
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


func _new_bazaars() -> void:
	for b: Node3D in _baz:
		b.queue_free()
	_baz.clear()
	var yaws: Array[float] = [PI, -PI * 0.5, PI * 0.5]
	var poss: Array[Vector3] = [POS_A, POS_B, POS_C]
	for i: int in 3:
		var b := (load(BAZAAR) as PackedScene).instantiate() as Node3D
		b.position = OFS + poss[i]
		b.rotation.y = yaws[i]
		add_child(b)
		_baz.append(b)
	_build_p = 1.0


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_all(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(_pitch)
	_cam.position = OFS + _focus + Vector3(0.0, sin(p) * _zoom, cos(p) * _zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _all(method: StringName, arg: Variant = null) -> void:
	for b: Node3D in _baz:
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
				_all(&"play_delivery")
			KEY_0:
				_new_bazaars()


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/market_shadow_%s_%s.png" % [_tag, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(nm: String, zoom: float, focus: Vector3, settle: float = 1.0, pitch: float = 55.0) -> Image:
	_zoom = zoom
	_focus = focus
	_pitch = pitch
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


## Visible mesh nodes of the Bazaar, and the draw calls of the Bazaar alone vs the Gloom Hall alone (same camera).
func _report() -> void:
	var c: Vector2i = _count(_baz[0])
	print("NODES gloom_bazaar mesh=%d multimesh=%d" % [c.x, c.y])
	var hall: Node3D = _extras[0] if not _extras.is_empty() else null
	_ground.visible = false
	var solo: Array = [["gloom_bazaar", _baz[0], POS_A], ["gloom_hall", hall, Vector3(-11.0, 0, 1.0)]]
	for s: Array in solo:
		var target: Node3D = s[1]
		if target == null:
			continue
		for n: Node in get_children():
			if n is Node3D and (n in _baz or n in _extras):
				(n as Node3D).visible = n == target
		_zoom = 20.0
		_focus = (s[2] as Vector3) + Vector3(0, 2.0, 0)
		_apply()
		await _wait(0.4)
		print("DRAWS %s draw_calls=%d objects=%d prims=%d" % [s[0],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	for n: Node in get_children():
		if n is Node3D and (n in _baz or n in _extras):
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
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/market_shadow_%s_%s.png" % [_tag, nm]))


## Black silhouettes on white (art-keep.md 0.1 test), the three Bazaars only: decals, pools, halos and particles left
## out. One-way (the last shot): materials are overridden for good.
func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for e: Node3D in _extras:
		e.visible = false
	_ground.visible = false
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	_env.environment = env
	for b: Node3D in _baz:
		_blacken(b, black)


func _blacken(n: Node, m: Material) -> void:
	if n is GPUParticles3D:
		(n as GPUParticles3D).visible = false
	elif n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.name.contains("Decal") or g.name.contains("Pool") or g.name.contains("Halo") or g.name.contains("Outline"):
			g.visible = false
		else:
			g.material_override = m
	for c: Node in n.get_children():
		_blacken(c, m)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(0.6)
	await _report()
	# Close-ups and game zooms of A (gate toward the camera).
	await _shot("a_z10", 10.0, POS_A + Vector3(0.2, 2.6, 0.0), 1.5)
	await _shot("a_z16", 16.0, POS_A + Vector3(0, 2.2, 0))
	await _shot("a_low", 11.0, POS_A + Vector3(0, 2.8, -0.5), 1.0, 28.0)
	await _shot("context_z28", 28.0, Vector3(-4.0, 1.0, -1.0))
	await _shot("context_z45", 45.0, Vector3(4.0, 0.0, -3.0))
	# The 1v1 orientations (gates +X / -X).
	await _shot("b_gate_px_z18", 18.0, POS_B + Vector3(0, 2.0, 0))
	await _shot("c_gate_mx_z18", 18.0, POS_C + Vector3(0, 2.0, 0))
	await _shot("bc_z30", 30.0, (POS_B + POS_C) * 0.5 + Vector3(0, 1.0, 0))
	if not _others.is_empty():
		await _shot("family_z30", 30.0, Vector3(0, 1.0, -12.0))
	# States on A at z 18.
	var sheet: Array[Image] = []
	var f := POS_A + Vector3(0, 2.2, 0)
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
	await _wait(0.6)
	_all(&"play_delivery")
	await _wait(0.28)
	sheet.append(_save("state_delivery_0s3"))
	await _shot("state_delivery_close", 10.0, POS_A + Vector3(-0.6, 4.5, 0.4), 0.05)
	await _wait(3.5)
	_all(&"set_health_ratio", 0.4)
	sheet.append(await _shot("state_hp40", 18.0, f, 2.5))
	_all(&"set_health_ratio", 0.2)
	sheet.append(await _shot("state_hp20", 18.0, f, 2.0))
	var finished: Array[int] = [0]
	for b: Node3D in _baz:
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	_all(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_save("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_save("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_save("state_destroyed_3s3"))
	print("destroyed_finished emitted: ", finished[0], " / ", _baz.size())
	_new_bazaars()
	await get_tree().process_frame
	_all(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_all(&"set_health_ratio", 1.0)
	_all(&"set_team_color", Color(0.20, 0.45, 0.95))
	sheet.append(await _shot("state_healed_blue", 18.0, f, 3.0))
	_sheet(sheet, "states", 3)
	print("saved states sheet")
	_all(&"set_team_color", Color(0.42, 0.22, 0.60))
	_silhouette()
	await _shot("silhouette_z40", 40.0, (POS_A + POS_C) * 0.5, 0.5)
	get_tree().quit()
