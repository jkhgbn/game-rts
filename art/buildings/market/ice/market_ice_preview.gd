extends Node3D
## Task 10.V3 preview: the Frost Bazaar from the RTS camera (pitch 55, fov 50, rts_camera.gd) with the game's lighting
## rig and ground, the Frost Hall beside it for the style / scale reference and a 1.8 m capsule worker at its door.
## Windowed run:
##   Godot --path . res://art/buildings/market/ice/market_ice_preview.tscn -- --shots
## Saves docs/art/screens/frost_bazaar_*.png, prints node / draw-call counts, then quits. Add `--family` for
## frost_bazaar_family.png: every Bazaar that exists, colour row + black silhouette at 40 m.
## By hand: wheel = zoom, 1 rebuild (6 s), 2 delivery, 3 HP 40 %, 4 HP 20 %, 5 full HP, 6 destroy, 7 select,
## 8 red team, 9 turn (gate toward -X / +Z), 0 new model, P training pulse.

const BAZAAR := "res://art/buildings/market/ice/market_ice.tscn"
const HALL := "res://art/buildings/ice_hall.tscn"
const BAZAARS: Array[String] = [
	"res://art/buildings/market/fire/market_fire.tscn",
	"res://art/buildings/market/shadow/market_shadow.tscn",
	"res://art/buildings/market/ice/market_ice.tscn",
	"res://art/buildings/market/nature/market_nature.tscn",
]
const ORIGIN := Vector3(0.0, 0.0, 0.0)
const HALL_X := -9.0

var _cam: Camera3D
var _ground: MeshInstance3D
var _env_node: Node
var _bazaar: Node3D
var _hall: Node3D
var _worker: MeshInstance3D
var _zoom: float = 18.0
var _focus: Vector3 = Vector3(0, 2.0, 0)
var _pitch: float = 55.0
var _yaw: float = PI
var _build_p: float = 1.0
var _selected: bool = false


func _ready() -> void:
	var rig_path := "res://art/environment/lighting/lighting_rig.gd"
	if ResourceLoader.exists(rig_path):
		var rig: Node = (load(rig_path) as GDScript).new()
		rig.set(&"preset_id", &"warm")
		add_child(rig)
		_env_node = rig
	else:
		var we := WorldEnvironment.new()
		we.environment = load("res://art/environment/world_env.tres")
		add_child(we)
		_env_node = we
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
	var gm: Material = load("res://art/environment/ground_material.tres") as Material
	if gm == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.25, 0.36, 0.15)
		gm = sm
	_ground.material_override = gm
	add_child(_ground)
	_worker = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	_worker.mesh = cm
	var capm := StandardMaterial3D.new()
	capm.albedo_color = Color(0.8, 0.7, 0.5)
	_worker.material_override = capm
	_worker.position = ORIGIN + Vector3(1.2, 0.9, 4.2)
	add_child(_worker)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_new_models()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_bazaar.call(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(_pitch)
	_cam.position = ORIGIN + _focus + Vector3(0.0, sin(p) * _zoom, cos(p) * _zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _new_models() -> void:
	if _bazaar:
		_bazaar.queue_free()
	if _hall:
		_hall.queue_free()
	_bazaar = (load(BAZAAR) as PackedScene).instantiate() as Node3D
	_bazaar.position = ORIGIN
	_bazaar.rotation.y = _yaw
	add_child(_bazaar)
	_hall = (load(HALL) as PackedScene).instantiate() as Node3D
	_hall.position = ORIGIN + Vector3(HALL_X, 0, 0)
	_hall.rotation.y = PI
	add_child(_hall)
	_build_p = 1.0


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 3.0, 6.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 3.0, 6.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				_build_p = 0.0
			KEY_2:
				_bazaar.call(&"play_delivery")
			KEY_3:
				_bazaar.call(&"set_health_ratio", 0.4)
			KEY_4:
				_bazaar.call(&"set_health_ratio", 0.2)
			KEY_5:
				_bazaar.call(&"set_health_ratio", 1.0)
			KEY_6:
				_bazaar.call(&"play_destroyed")
			KEY_7:
				_selected = not _selected
				_bazaar.call(&"set_selected", _selected)
			KEY_8:
				_bazaar.call(&"set_team_color", Color(0.85, 0.25, 0.25))
			KEY_9:
				_yaw = PI * 0.5 if _yaw == PI else PI
				_new_models()
			KEY_0:
				_new_models()
			KEY_P:
				_bazaar.call(&"play_training_pulse")


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/frost_bazaar_%s.png" % nm
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


## Visible geometry nodes (MeshInstance3D + MultiMeshInstance3D, recursive), lights and emitting particles.
func _count(n: Node) -> Vector4i:
	var c := Vector4i.ZERO
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		c.x += (n as MeshInstance3D).mesh.get_surface_count() if (n as MeshInstance3D).mesh else 0
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).visible:
		c.y += 1
	elif n is Light3D and (n as Light3D).visible:
		c.z += 1
	elif n is GPUParticles3D and (n as GPUParticles3D).emitting:
		c.w += (n as GPUParticles3D).amount
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _count(ch)
	return c


func _report() -> void:
	var c: Vector4i = _count(_bazaar)
	print("NODES frost_bazaar surfaces=%d multimesh=%d lights=%d particles=%d" % [c.x, c.y, c.z, c.w])
	var ch: Vector4i = _count(_hall)
	print("NODES frost_hall surfaces=%d multimesh=%d lights=%d particles=%d" % [ch.x, ch.y, ch.z, ch.w])
	_ground.visible = false
	_worker.visible = false
	for pair: Array in [["empty", null], ["frost_bazaar", _bazaar], ["frost_hall", _hall]]:
		_bazaar.visible = pair[1] == _bazaar
		_hall.visible = pair[1] == _hall
		var target: Node3D = pair[1] if pair[1] != null else _bazaar
		_zoom = 20.0
		_focus = target.position - ORIGIN + Vector3(0, 2.0, 0)
		_apply()
		await _wait(0.3)
		print("DRAWS %s draw_calls=%d objects=%d prims=%d" % [pair[0],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	_bazaar.visible = true
	_hall.visible = true
	_ground.visible = true
	_worker.visible = true


func _sheet(imgs: Array[Image], path: String, cols: int, w: int = 640, h: int = 360) -> void:
	var rows: int = ceili(float(imgs.size()) / cols)
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	for i: int in imgs.size():
		var img: Image = imgs[i]
		img.convert(Image.FORMAT_RGBA8)
		img.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path)


var _black: StandardMaterial3D
var _white_env: Environment


## Black silhouette on a white background (art-keep.md 0.1 test) for every node in `nodes`; the rest hidden.
func _silhouette(on: bool, nodes: Array[Node3D]) -> void:
	if _black == null:
		_black = StandardMaterial3D.new()
		_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_black.albedo_color = Color.BLACK
		_white_env = Environment.new()
		_white_env.background_mode = Environment.BG_COLOR
		_white_env.background_color = Color.WHITE
	_ground.visible = not on
	_worker.visible = not on
	var we := _find_env(_env_node)
	if we:
		if on:
			we.set_meta(&"env_backup", we.environment)
			we.environment = _white_env
		elif we.has_meta(&"env_backup"):
			we.environment = we.get_meta(&"env_backup")
	for n: Node3D in nodes:
		_overlay(n, _black if on else null)


func _find_env(n: Node) -> WorldEnvironment:
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c: Node in n.get_children():
		var w := _find_env(c)
		if w:
			return w
	return null


func _overlay(n: Node, m: Material) -> void:
	if n is GPUParticles3D:
		(n as GPUParticles3D).visible = m == null
	elif n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.name.contains("Decal") or g.name.contains("Outline") or g.name == "Rubble":
			g.visible = m == null
		else:
			g.material_overlay = m
	for c: Node in n.get_children():
		_overlay(c, m)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(0.8)
	await _report()
	await _shot("z12", 12.0, Vector3(0.0, 2.6, 0.0), 1.5)
	await _shot("z18", 18.0, Vector3(-1.5, 2.0, 0.0))
	await _shot("z30", 30.0, Vector3(-4.5, 1.5, 0.0))
	await _shot("z45", 45.0, Vector3(-4.5, 0.0, 0.0))
	await _shot("front_low", 13.0, Vector3(0.0, 2.8, 0.0), 0.6, 25.0)
	await _shot("counter_close", 7.0, Vector3(1.0, 1.8, 0.5), 0.5, 35.0)
	await _shot("scale_close", 8.0, Vector3(-1.95, 6.6, -1.9), 0.5, 30.0)
	# Other sides (the game turns the gate toward the map centre).
	for side: Array in [["side_z18", PI * 0.5], ["other_side_z18", -PI * 0.5], ["back_z18", 0.0]]:
		_yaw = side[1]
		_new_models()
		await _shot(side[0], 18.0, Vector3(0.0, 2.0, 0.0), 1.3)
	_yaw = PI
	_new_models()
	await _wait(0.6)
	# Silhouette at 40 m with the Frost Hall beside it (they must not read the same).
	_silhouette(true, [_bazaar, _hall] as Array[Node3D])
	await _shot("silhouette_z40", 40.0, Vector3(-4.5, 0.0, 0.0), 0.4)
	_silhouette(false, [_bazaar, _hall] as Array[Node3D])
	# Delivery: the scale tips and swings back, the coins glint.
	_zoom = 12.0
	_focus = Vector3(-1.95, 6.2, -1.9)
	_pitch = 35.0
	_apply()
	await _wait(0.6)
	_bazaar.call(&"play_delivery")
	await _wait(0.3)
	var d1: Image = _save("delivery_0s3")
	await _wait(0.45)
	var d2: Image = _save("delivery_0s75")
	await _wait(1.8)
	var d3: Image = _save("delivery_2s5")
	_sheet([d1, d2, d3] as Array[Image], "res://docs/art/screens/frost_bazaar_delivery.png", 3)
	# States at z 20.
	var sheet: Array[Image] = []
	var sf := Vector3(0.0, 2.0, 0.0)
	_bazaar.call(&"set_construction_progress", 0.0)
	sheet.append(await _shot("state_construct00", 20.0, sf, 0.4))
	_bazaar.call(&"set_construction_progress", 0.35)
	sheet.append(await _shot("state_construct35", 20.0, sf, 0.4))
	_bazaar.call(&"set_construction_progress", 0.75)
	sheet.append(await _shot("state_construct75", 20.0, sf, 0.4))
	_bazaar.call(&"set_construction_progress", 1.0)
	await _wait(0.12)
	_save("state_complete_flash")
	await _wait(1.5)
	_bazaar.call(&"set_selected", true)
	_bazaar.call(&"play_training_pulse")
	await _wait(0.12)
	sheet.append(_save("state_selected_pulse"))
	_bazaar.call(&"set_selected", false)
	_bazaar.call(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_save("state_hp40"))
	_bazaar.call(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_save("state_hp20"))
	var finished: Array[int] = [0]
	_bazaar.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	_bazaar.call(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_save("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_save("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_save("state_destroyed_3s3"))
	print("destroyed_finished emitted: ", finished[0])
	_new_models()
	await get_tree().process_frame
	_bazaar.call(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_bazaar.call(&"set_health_ratio", 1.0)
	_bazaar.call(&"set_team_color", Color(0.85, 0.25, 0.25))
	sheet.append(await _shot("state_healed_red", 20.0, sf, 2.5))
	_sheet(sheet, "res://docs/art/screens/frost_bazaar_states.png", 3)
	if "--family" in OS.get_cmdline_user_args():
		await _bazaars_sheet()
	get_tree().quit()


## Contact sheet of every Bazaar that exists (fire / shadow / ice / nature): colour at z 22 on top, black silhouette at
## z 40 below. Missing ones are skipped (other agents build them in parallel).
func _bazaars_sheet() -> void:
	_bazaar.visible = false
	_hall.visible = false
	var colour: Array[Image] = []
	var black: Array[Image] = []
	for path: String in BAZAARS:
		if not ResourceLoader.exists(path):
			print("bazaars sheet: missing ", path)
			continue
		var ps := load(path) as PackedScene
		var b: Node3D = ps.instantiate() as Node3D if ps else null
		if b == null:
			print("bazaars sheet: cannot instance ", path)
			continue
		b.position = ORIGIN + Vector3(0, 0, 40)
		b.rotation.y = PI
		add_child(b)
		_zoom = 22.0
		_focus = Vector3(0, 2.0, 40)
		_pitch = 55.0
		_apply()
		await _wait(1.0)
		colour.append(get_viewport().get_texture().get_image())
		_silhouette(true, [b] as Array[Node3D])
		_zoom = 40.0
		_focus = Vector3(0, 1.5, 40)
		_apply()
		await _wait(0.4)
		black.append(get_viewport().get_texture().get_image())
		_silhouette(false, [b] as Array[Node3D])
		b.queue_free()
		await get_tree().process_frame
	var all: Array[Image] = []
	all.append_array(colour)
	all.append_array(black)
	if colour.size() > 0:
		_sheet(all, "res://docs/art/screens/frost_bazaar_family.png", colour.size(), 480, 360)
	_bazaar.visible = true
	_hall.visible = true
