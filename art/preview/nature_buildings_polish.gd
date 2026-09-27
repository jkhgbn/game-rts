extends Node3D
## Task A2.6 preview: the Nature buildings (Grove Hall, Seed Hollow, Bramble Spire) from the RTS camera (pitch 55,
## fov 50, rts_camera.gd), with the game's lighting rig and ground, the Heartwood beside them for the style reference.
## Windowed run:
##   Godot --path . res://art/preview/nature_buildings_polish.tscn -- --tag=after --shots
## Saves docs/art/screens/nature_bld_<tag>_*.png, prints build times, node / draw-call counts, then quits.
## By hand: wheel = zoom, 1 rebuild (6 s), 2 training pulse + tower shots, 3 HP 40 %, 4 HP 20 %, 5 full HP,
## 6 destroy, 7 toggle selected, 8 red team, 9 turn gates to -X, 0 new buildings.

const SCENES: Array[String] = [
	"res://art/buildings/nature_hall.tscn",
	"res://art/buildings/nature_hollow.tscn",
	"res://art/buildings/nature_spire.tscn",
]
const NAMES: Array[String] = ["grove_hall", "seed_hollow", "bramble_spire"]
const XS: Array[float] = [-9.0, -2.2, 2.6]
const KEEP_SCENE := "res://art/buildings/nature_keep.tscn"
const KEEP_X := -19.5
const ORIGIN := Vector3(-22.0, 0.0, 12.0)

var _cam: Camera3D
var _ground: MeshInstance3D
var _blds: Array[Node3D] = []
var _extra: Array[Node3D] = []   ## a second spire and hollow (red team) to the right
var _keep: Node3D
var _tag: String = "after"
var _zoom: float = 28.0
var _focus: Vector3 = Vector3(0, 1.5, 0)
var _yaw: float = PI
var _build_p: float = 1.0
var _selected: bool = false
var _shot_clock: float = 0.0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
	var rig_path := "res://art/environment/lighting/lighting_rig.gd"
	if ResourceLoader.exists(rig_path):
		var rig: Node = (load(rig_path) as GDScript).new()
		rig.set(&"preset_id", &"warm")
		add_child(rig)
	else:
		var we := WorldEnvironment.new()
		we.environment = load("res://art/environment/world_env.tres")
		add_child(we)
		var sun := DirectionalLight3D.new()
		sun.light_color = Color(1.00, 0.93, 0.82)
		sun.light_energy = 1.3
		sun.rotation_degrees = Vector3(-50, 35, 0)
		sun.shadow_enabled = true
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
	# Scale reference: a 1.8 m capsule "worker" in front of the hall gate and beside the hollow.
	for p: Vector3 in [Vector3(-7.4, 0.9, 4.8), Vector3(0.2, 0.9, 3.0)]:
		var cap := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.35
		cm.height = 1.8
		cap.mesh = cm
		var capm := StandardMaterial3D.new()
		capm.albedo_color = Color(0.8, 0.7, 0.5)
		cap.material_override = capm
		cap.position = ORIGIN + p
		add_child(cap)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_new_buildings(true)
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_all(&"set_construction_progress", _build_p)
	_shot_clock += delta
	if _shot_clock > 0.8:
		_shot_clock = 0.0
		for b: Node3D in _extra:
			if is_instance_valid(b) and b.has_method(&"play_shot"):
				b.call(&"play_shot")


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = ORIGIN + _focus + Vector3(0.0, sin(p) * _zoom, cos(p) * _zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _every() -> Array[Node3D]:
	var all: Array[Node3D] = []
	all.append_array(_blds)
	all.append_array(_extra)
	return all


func _all(method: StringName, arg: Variant = null) -> void:
	for b: Node3D in _every():
		if not is_instance_valid(b) or not b.has_method(method):
			continue
		if arg == null:
			b.call(method)
		else:
			b.call(method, arg)


func _new_buildings(timed: bool = false) -> void:
	for b: Node3D in _every():
		b.queue_free()
	_blds.clear()
	_extra.clear()
	if _keep:
		_keep.queue_free()
	for i: int in SCENES.size():
		var t0: int = Time.get_ticks_usec()
		var b := (load(SCENES[i]) as PackedScene).instantiate() as Node3D
		b.position = ORIGIN + Vector3(XS[i], 0, 0)
		b.rotation.y = _yaw
		add_child(b)
		if timed:
			print("BUILD %s first instance %.1f ms" % [NAMES[i], (Time.get_ticks_usec() - t0) / 1000.0])
			var t1: int = Time.get_ticks_usec()
			var b2 := (load(SCENES[i]) as PackedScene).instantiate() as Node3D
			add_child(b2)
			print("BUILD %s next instance %.1f ms" % [NAMES[i], (Time.get_ticks_usec() - t1) / 1000.0])
			b2.free()
		_blds.append(b)
	# A red-team hollow and a spire (shooting) on the right, gates toward -X.
	for e: Array in [[SCENES[1], Vector3(7.2, 0, 0.5)], [SCENES[2], Vector3(10.6, 0, -0.5)]]:
		var b := (load(e[0]) as PackedScene).instantiate() as Node3D
		b.position = ORIGIN + (e[1] as Vector3)
		b.rotation.y = PI * 0.5
		b.call(&"set_team_color", Color(0.85, 0.22, 0.18))
		add_child(b)
		_extra.append(b)
	_keep = (load(KEEP_SCENE) as PackedScene).instantiate() as Node3D
	_keep.position = ORIGIN + Vector3(KEEP_X, 0, -1)
	_keep.rotation.y = _yaw
	add_child(_keep)
	_build_p = 1.0


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 3.0, 8.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 3.0, 8.0, 55.0)
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
				_all(&"set_team_color", Color(0.85, 0.25, 0.25))
			KEY_9:
				_yaw = PI * 0.5 if _yaw == PI else PI
				_new_buildings()
			KEY_0:
				_new_buildings()


func _save(nm: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/nature_bld_%s_%s.png" % [_tag, nm]
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


## Visible geometry nodes (MeshInstance3D, MultiMeshInstance3D), surfaces, lights, emitting particles.
func _count(n: Node) -> Array[int]:
	var c: Array[int] = [0, 0, 0, 0, 0]
	if n is MeshInstance3D and (n as MeshInstance3D).visible and (n as MeshInstance3D).mesh:
		c[0] += 1
		c[1] += (n as MeshInstance3D).mesh.get_surface_count()
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).visible:
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		if mm and mm.instance_count > 0 and mm.visible_instance_count != 0:
			c[0] += 1
			c[1] += 1
	elif n is Light3D and (n as Light3D).visible:
		c[2] += 1
	elif n is GPUParticles3D and (n as GPUParticles3D).emitting:
		c[3] += (n as GPUParticles3D).amount
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m: Mesh = (n as MeshInstance3D).mesh
		for s: int in m.get_surface_count():
			c[4] += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		var cc: Array[int] = _count(ch)
		for i: int in 5:
			c[i] += cc[i]
	return c


func _report() -> void:
	for i: int in _blds.size():
		var c: Array[int] = _count(_blds[i])
		print("NODES %s mesh=%d surfaces=%d lights=%d particles=%d verts=%d" % [NAMES[i], c[0], c[1], c[2], c[3], c[4]])
	# Draw calls of each building alone (others hidden, ground hidden), camera at z 20.
	_ground.visible = false
	_keep.visible = false
	for gi: int in _blds.size():
		for b: Node3D in _every():
			b.visible = b == _blds[gi]
		_zoom = 20.0
		_focus = _blds[gi].position - ORIGIN + Vector3(0, 1.5, 0)
		_apply()
		await _wait(0.4)
		print("DRAWS %s draw_calls=%d objects=%d prims=%d" % [NAMES[gi],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	for b: Node3D in _every():
		b.visible = false
	_focus = Vector3(0, 1.5, 30)
	_apply()
	await _wait(0.4)
	print("DRAWS empty draw_calls=%d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	for path: String in ["res://art/buildings/ice_hall.tscn", "res://art/buildings/ice_lodge.tscn",
			"res://art/buildings/ice_spire.tscn"]:
		var ref := (load(path) as PackedScene).instantiate() as Node3D
		ref.position = ORIGIN + Vector3(0, 0, 30)
		add_child(ref)
		_zoom = 20.0
		_focus = Vector3(0, 1.5, 30)
		_apply()
		await _wait(0.4)
		print("DRAWS ref %s draw_calls=%d objects=%d prims=%d" % [path.get_file().get_basename(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		ref.free()
	for b: Node3D in _every():
		b.visible = true
	_keep.visible = true
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
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/nature_bld_%s_%s.png" % [_tag, nm]))


func _silhouette(on: bool) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_overlay = white if on else null
	for b: Node3D in _every():
		_overlay(b, black if on else null)
	_overlay(_keep, black if on else null)


func _overlay(n: Node, m: Material) -> void:
	if n is GPUParticles3D:
		(n as GPUParticles3D).visible = m == null
	elif n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.name.contains("Decal") or g.name.contains("Outline") or g.name.contains("Aura") or g.name.contains("Dressing"):
			g.visible = m == null
		else:
			g.material_overlay = m
	for c: Node in n.get_children():
		_overlay(c, m)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(0.8)
	await _report()
	await _shot("hall_z12", 12.0, Vector3(-9.0, 2.8, 0.5), 1.5)
	await _shot("small_z11", 11.0, Vector3(0.2, 2.0, 0.5))
	await _shot("hall_z18", 18.0, Vector3(-7.0, 2.2, 0.0))
	await _shot("small_z16", 16.0, Vector3(3.5, 1.5, -0.5))
	await _shot("row_z30", 30.0, Vector3(-5.0, 1.5, -1.0))
	await _shot("row_z45", 45.0, Vector3(-5.0, 0, -1.0))
	_silhouette(true)
	await _shot("silhouette_z40", 40.0, Vector3(-5.0, 0, -1.0), 0.4)
	_silhouette(false)
	# Gates turned to -X (the game turns gates toward the map centre): the left side faces the camera.
	_yaw = PI * 0.5
	_new_buildings()
	await _shot("side_z20", 20.0, Vector3(-5.0, 1.5, 0), 1.5)
	_yaw = -PI * 0.5
	_new_buildings()
	await _shot("side_other_z20", 20.0, Vector3(-5.0, 1.5, 0), 1.5)
	_yaw = PI
	_new_buildings()
	await _wait(0.5)
	# States at z 26.
	var sheet: Array[Image] = []
	var sf := Vector3(-3.0, 1.5, -1.0)
	_all(&"set_construction_progress", 0.0)
	await _wait(0.3)
	sheet.append(await _shot("state_construct00", 26.0, sf, 0.4))
	_all(&"set_construction_progress", 0.35)
	sheet.append(await _shot("state_construct35", 26.0, sf, 0.4))
	_all(&"set_construction_progress", 0.75)
	sheet.append(await _shot("state_construct75", 26.0, sf, 0.4))
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
	await _shot("state_hp20_hall_z14", 14.0, Vector3(-8.0, 2.5, 0.5), 0.3)
	await _shot("state_hp20_small_z14", 14.0, Vector3(1.0, 1.5, -0.5), 0.3)
	_zoom = 26.0
	_focus = sf
	_apply()
	var finished: Array[int] = [0]
	for b: Node3D in _every():
		b.connect(&"destroyed_finished", func() -> void: finished[0] += 1)
	_all(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_save("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_save("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_save("state_destroyed_3s3"))
	await _shot("state_wreck_z14", 14.0, Vector3(-6.0, 1.5, 0.5), 0.3)
	print("destroyed_finished emitted: ", finished[0], " / ", _every().size())
	# Heal back + team colour on fresh buildings.
	_new_buildings()
	await get_tree().process_frame
	_all(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_all(&"set_health_ratio", 1.0)
	_all(&"set_team_color", Color(0.85, 0.25, 0.25))
	sheet.append(await _shot("state_healed_red", 26.0, sf, 3.0))
	_sheet(sheet, "states", 3)
	print("saved states sheet")
	get_tree().quit()
