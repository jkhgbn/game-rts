extends Node3D
## Task A.9 preview: Fire / Shadow halls, houses and towers from the RTS camera (pitch 55, fov 50, rts_camera.gd),
## on the game's ground material. Row (x): Ember Hall, Hearth, Ember Spire | Night Spire, Hovel, Gloom Hall.
## Windowed run:
##   Godot --path . res://art/preview/halls_preview_polish.tscn -- --tag=after --shots
## Saves docs/art/screens/polish_bld_<tag>_*.png, prints node / draw-call counts, then quits.
## By hand: wheel = zoom, 1 rebuild (6 s), 2 training pulse + tower shots, 3 HP 40 %, 4 HP 20 %, 5 full HP,
## 6 destroy, 7 toggle selected, 8 blue team, 9 turn gates to -X, 0 new buildings.

const SCENES: Array[String] = [
	"res://art/buildings/fire_hall.tscn",
	"res://art/buildings/hearth.tscn",
	"res://art/buildings/fire_tower.tscn",
	"res://art/buildings/shadow_tower.tscn",
	"res://art/buildings/hovel.tscn",
	"res://art/buildings/shadow_hall.tscn",
]
const NAMES: Array[String] = ["ember_hall", "hearth", "ember_spire", "night_spire", "hovel", "gloom_hall"]
const XS: Array[float] = [-12.5, -5.6, -1.7, 1.7, 5.6, 12.5]
const ORIGIN := Vector3(-22.0, 0.0, 12.0)

var _cam: Camera3D
var _ground: MeshInstance3D
var _blds: Array[Node3D] = []
var _tag: String = "after"
var _zoom: float = 28.0
var _focus: Vector3 = Vector3(0, 1.5, 0)
var _yaw: float = PI
var _build_p: float = 1.0
var _selected: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
	var we := WorldEnvironment.new()
	we.environment = load("res://art/environment/world_env.tres")
	add_child(we)
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
	# Scale reference: a 1.8 m capsule "worker" in front of each hall gate.
	for x: float in [-11.0, 11.0]:
		var cap := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.35
		cm.height = 1.8
		cap.mesh = cm
		var capm := StandardMaterial3D.new()
		capm.albedo_color = Color(0.8, 0.7, 0.5)
		cap.material_override = capm
		cap.position = ORIGIN + Vector3(x, 0.9, 4.6)
		add_child(cap)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_new_buildings()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_all(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = ORIGIN + _focus + Vector3(0.0, sin(p) * _zoom, cos(p) * _zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _all(method: StringName, arg: Variant = null) -> void:
	for b: Node3D in _blds:
		if not b.has_method(method):
			continue
		if arg == null:
			b.call(method)
		else:
			b.call(method, arg)


func _new_buildings() -> void:
	for b: Node3D in _blds:
		b.queue_free()
	_blds.clear()
	for i: int in SCENES.size():
		var b := (load(SCENES[i]) as PackedScene).instantiate() as Node3D
		b.position = ORIGIN + Vector3(XS[i], 0, 0)
		b.rotation.y = _yaw
		add_child(b)
		_blds.append(b)
	_build_p = 1.0


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 3.0, 10.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 3.0, 10.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				_build_p = 0.0
			KEY_2:
				_all(&"play_training_pulse")
				_all(&"play_shot")
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
				_yaw = PI * 0.5 if _yaw == PI else PI
				_new_buildings()
			KEY_0:
				_new_buildings()


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_bld_%s_%s.png" % [_tag, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		" prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(nm: String, zoom: float, focus: Vector3, settle: float = 1.2) -> Image:
	_zoom = zoom
	_focus = focus
	_apply()
	await _wait(settle)
	return _save(nm)


## Visible geometry nodes per building (MeshInstance3D + MultiMeshInstance3D, recursive).
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


func _report() -> void:
	for i: int in _blds.size():
		var c: Vector2i = _count(_blds[i])
		print("NODES %s mesh=%d multimesh=%d" % [NAMES[i], c.x, c.y])
	# Draw calls of each building alone (others hidden, ground hidden), camera at z 20.
	_ground.visible = false
	for i: int in _blds.size():
		for j: int in _blds.size():
			_blds[j].visible = i == j
		_zoom = 20.0
		_focus = Vector3(XS[i], 1.5, 0)
		_apply()
		await _wait(0.3)
		print("DRAWS %s draw_calls=%d objects=%d" % [NAMES[i],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	for b: Node3D in _blds:
		b.visible = true
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
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/polish_bld_%s_%s.png" % [_tag, nm]))


func _silhouette(on: bool) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_overlay = white if on else null
	for b: Node3D in _blds:
		_overlay(b, black if on else null)


func _overlay(n: Node, m: Material) -> void:
	if n is GPUParticles3D:
		(n as GPUParticles3D).visible = m == null
	elif n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		# Decals / ground quads stay out of the silhouette.
		if g.name.contains("Decal") or g.name.contains("Scorch") or g.name.contains("Outline"):
			g.visible = m == null
		else:
			g.material_overlay = m
	for c: Node in n.get_children():
		_overlay(c, m)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(0.5)
	await _report()
	await _shot("fire_z10", 10.0, Vector3(-11.5, 2.5, 0.5), 1.5)
	await _shot("shadow_z10", 10.0, Vector3(11.5, 2.5, 0.5))
	await _shot("small_z12", 12.0, Vector3(0, 1.8, 0.5))
	await _shot("fire_z16", 16.0, Vector3(-8.0, 2.0, 0.5))
	await _shot("shadow_z16", 16.0, Vector3(8.0, 2.0, 0.5))
	await _shot("row_z28", 28.0, Vector3(0, 1.5, 0))
	await _shot("row_z45", 45.0, Vector3(0, 0, 0))
	_silhouette(true)
	await _shot("silhouette_z40", 40.0, Vector3(0, 0, 0), 0.4)
	_silhouette(false)
	# Gates turned to -X (the game turns gates toward the map centre).
	_yaw = PI * 0.5
	_new_buildings()
	await _shot("side_z20", 20.0, Vector3(-7.0, 1.5, 0), 1.5)
	await _shot("side_shadow_z20", 20.0, Vector3(7.0, 1.5, 0), 0.4)
	_yaw = PI
	_new_buildings()
	await _wait(0.5)
	# States, both halves of the row at z 28.
	var sheet: Array[Image] = []
	_all(&"set_construction_progress", 0.0)
	await _wait(0.3)
	sheet.append(await _shot("state_construct00", 26.0, Vector3(0, 1.5, 0), 0.4))
	_all(&"set_construction_progress", 0.35)
	sheet.append(await _shot("state_construct35", 26.0, Vector3(0, 1.5, 0), 0.4))
	_all(&"set_construction_progress", 0.75)
	sheet.append(await _shot("state_construct75", 26.0, Vector3(0, 1.5, 0), 0.4))
	_all(&"set_construction_progress", 1.0)
	await _wait(0.12)
	_save("state_complete_flash")
	await _wait(1.5)
	_all(&"set_selected", true)
	_all(&"play_training_pulse")
	_all(&"play_shot")
	await _wait(0.12)
	sheet.append(_save("state_selected_pulse"))
	_all(&"set_selected", false)
	_all(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_save("state_hp40"))
	_all(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_save("state_hp20"))
	await _shot("state_hp20_fire_z14", 14.0, Vector3(-8.0, 2.0, 0.5), 0.3)
	await _shot("state_hp20_shadow_z14", 14.0, Vector3(8.0, 2.0, 0.5), 0.3)
	_zoom = 26.0
	_focus = Vector3(0, 1.5, 0)
	_apply()
	var finished: Array[int] = [0]
	for b: Node3D in _blds:
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	_all(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_save("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_save("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_save("state_destroyed_3s3"))
	await _shot("state_wreck_fire_z14", 14.0, Vector3(-8.0, 1.5, 0.5), 0.3)
	await _shot("state_wreck_shadow_z14", 14.0, Vector3(8.0, 1.5, 0.5), 0.3)
	print("destroyed_finished emitted: ", finished[0], " / ", _blds.size())
	# Heal back + team colour on fresh buildings.
	_new_buildings()
	await get_tree().process_frame
	_all(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_all(&"set_health_ratio", 1.0)
	_all(&"set_team_color", Color(0.20, 0.45, 0.95))
	sheet.append(await _shot("state_healed_blue", 26.0, Vector3(0, 1.5, 0), 3.0))
	_sheet(sheet, "states", 3)
	print("saved states sheet")
	get_tree().quit()
