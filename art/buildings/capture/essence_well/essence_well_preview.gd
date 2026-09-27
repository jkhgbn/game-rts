extends SceneTree
## Task 12.V19 screenshots of the Essence well from the RTS camera (pitch 55, fov 50), saved as
## docs/art/screens/essence_well_<shot>.png. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/buildings/capture/essence_well/essence_well_preview.gd
##       --resolution 1600x900 --quit-after 9000 -- [world=plain] [only=<shot>,<shot>]
## Phase A, on the real skirmish map (scenes/skirmish.tscn, bot off, fog off, HUD hidden; `world=plain` or a map that
## fails to load uses a plain ground with the game's lighting rig): Mossmere Well at (-30, -24) and Stonemere Well at
## (30, 24) (map-fill.md 4.1; props within 4.5 m hidden as the point's clearing will be), the wizard beside it for scale:
## neutral at zoom 12 / 20 / 30 / 55, capturing, owned by each kingdom colour, the income pulse.
## Phase B, plain world: the six looks side by side, and the black-on-white silhouette at zoom 40 (art-keep.md 0.1).

const WELL_PATH := "res://art/buildings/capture/essence_well/essence_well.tscn"
const GROUND_MAT := "res://art/environment/ground_material.tres"
const VESSA_PATH := "res://art/units/wizards/vessa.tscn"
const SPOT_W := Vector3(-30, 0, -24)
const SPOT_E := Vector3(30, 0, 24)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.6)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)

var _only: PackedStringArray = PackedStringArray()
var _plain: bool = false
var _world: Node3D
var _main: Node
var _cam: Camera3D
var _wells: Array[Node3D] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
		elif arg == "world=plain":
			_plain = true
	_run()


func _want(nm: String) -> bool:
	return _only.is_empty() or _only.has(nm)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var scene: PackedScene = null if _plain else load("res://scenes/skirmish.tscn") as PackedScene
	if scene:
		_main = scene.instantiate()
		var bot: Node = _main.get_node_or_null(^"ShadowBot")
		if bot:
			bot.set(&"enabled", false)
		root.add_child(_main)
		current_scene = _main
		var wait := 0
		while _main.get(&"hero") == null and wait < 3000:
			await process_frame
			wait += 1
		var fog: Node = _main.get(&"fog")
		if fog and fog.has_method(&"set_enabled"):
			fog.call(&"set_enabled", false)
		var hud: Variant = _main.get(&"hud")
		if hud is CanvasLayer:
			(hud as CanvasLayer).visible = false
		for n: Node in _main.find_children("*", "CanvasLayer", true, false):
			if n.name != "Vignette":
				(n as CanvasLayer).visible = false
		_world = _main as Node3D
		_clear_spots([SPOT_W, SPOT_E], 4.5)
		print("world: skirmish")
	else:
		_world = _plain_world()
		print("world: plain")
	for p: Vector3 in [SPOT_W, SPOT_E]:
		var w: Node3D = (load(WELL_PATH) as PackedScene).instantiate() as Node3D
		w.position = p
		_world.add_child(w)
		_wells.append(w)
	_place_hero(SPOT_W + Vector3(2.9, 0, 2.2))
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	_world.add_child(_cam)
	_cam.current = true
	var w0: Node3D = _wells[0]
	var f: Vector3 = SPOT_W + Vector3(0, 0.9, 0)
	await _shot("neutral_z12", 12.0, f)
	await _shot("neutral_z20", 20.0, f)
	await _shot("neutral_z30", 30.0, SPOT_W + Vector3(0, 0.5, 0))
	await _shot("neutral_z55", 55.0, SPOT_W)
	w0.call(&"set_capture", FIRE, 0.62)
	await _shot("capturing_z20", 20.0, f)
	await _shot("capturing_z55", 55.0, SPOT_W)
	w0.call(&"set_capture", null, 0.0)
	for c: Array in [["fire", FIRE], ["shadow", SHADOW], ["ice", ICE], ["nature", NATURE]]:
		w0.call(&"set_owner_color", c[1])
		await _shot("owned_%s_z20" % c[0], 20.0, f)
	w0.call(&"set_owner_color", FIRE)
	await _shot("owned_fire_z55", 55.0, SPOT_W)
	await _shot("owned_fire_z12", 12.0, f)
	if _want("pulse_z20"):
		await _wait(1.0)
		w0.call(&"play_pulse")
		await _shot("pulse_z20", 20.0, f, 0.33)
		w0.call(&"play_pulse")
		await _shot("pulse_late_z20", 20.0, f, 0.62)
	w0.call(&"set_owner_color", null)
	w0.call(&"set_selected", true)
	await _shot("selected_z20", 20.0, f)
	w0.call(&"set_selected", false)
	# Phase B: plain world.
	if _main:
		root.remove_child(_main)
		_main.queue_free()
		_main = null
		_world = _plain_world()
		_cam = Camera3D.new()
		_cam.fov = 50.0
		_cam.far = 500.0
		_world.add_child(_cam)
		_cam.current = true
	else:
		for w: Node3D in _wells:
			w.visible = false
	var looks: Array = [null, "cap", FIRE, SHADOW, ICE, NATURE]
	var line: Array[Node3D] = []
	for i: int in looks.size():
		var w: Node3D = (load(WELL_PATH) as PackedScene).instantiate() as Node3D
		w.position = SPOT_W + Vector3(-17.5 + i * 7.0, 0, 14.0)
		var look: Variant = looks[i]
		if look is Color:
			w.call(&"set_owner_color", look)
		elif look is String:
			w.call(&"set_capture", NATURE, 0.4)
		_world.add_child(w)
		line.append(w)
	await _shot("lineup_z30", 34.0, SPOT_W + Vector3(0, 0, 14.0), 1.2)
	await _silhouette(line[0])
	print("SHOTS DONE")
	quit()


func _plain_world() -> Node3D:
	var world := Node3D.new()
	world.name = "PreviewWorld"
	root.add_child(world)
	current_scene = world
	var rig_script: Script = load("res://art/environment/lighting/lighting_rig.gd") as Script
	if rig_script:
		world.add_child(rig_script.new() as Node)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	ground.material_override = load(GROUND_MAT) as Material
	world.add_child(ground)
	return world


func _place_hero(at: Vector3) -> void:
	var hero: Node3D = null
	if _main:
		hero = _main.get(&"hero") as Node3D
	if hero:
		hero.global_position = at
		if hero.has_method(&"command_stop"):
			hero.call(&"command_stop")
		hero.rotation.y = -2.4
	elif ResourceLoader.exists(VESSA_PATH):
		var v: Node3D = (load(VESSA_PATH) as PackedScene).instantiate() as Node3D
		_world.add_child(v)
		v.global_position = at
		v.rotation.y = -2.4


## Preview only: hides the drawn props (MultiMesh instances and single props) within `r` of the spots, like the
## capture point's clearing will.
func _clear_spots(spots: Array, r: float) -> void:
	var hidden := 0
	for n: Node in _main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null:
			continue
		var gx: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = gx * mmi.multimesh.get_instance_transform(i)
			for s: Vector3 in spots:
				if Vector2(xf.origin.x - s.x, xf.origin.z - s.z).length() < r:
					mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
						Vector3(xf.origin.x, -30.0, xf.origin.z)))
					hidden += 1
					break
	for n: Node in _main.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var aabb: AABB = mi.get_aabb()
		if aabb.size.x > 20.0 or aabb.size.z > 20.0:
			continue   # ground, water, cliffs
		var p: Vector3 = mi.global_position
		for s: Vector3 in spots:
			if Vector2(p.x - s.x, p.z - s.z).length() < r:
				mi.visible = false
				hidden += 1
	print("hidden props: %d" % hidden)


func _aim(zoom: float, focus: Vector3, pitch_deg: float = 55.0) -> void:
	var p: float = deg_to_rad(pitch_deg)
	_cam.global_position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.global_rotation = Vector3(-p, 0.0, 0.0)


func _wait(seconds: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(seconds * 1000.0):
		await process_frame


func _shot(nm: String, zoom: float, focus: Vector3, wait: float = 1.3) -> void:
	if not _want(nm):
		return
	_aim(zoom, focus)
	await _wait(wait)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/essence_well_%s.png" % nm
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


## Black silhouette on white of one well at zoom 40 (art-keep.md 0.1 test).
func _silhouette(w: Node3D) -> void:
	if not _want("silhouette_z40"):
		return
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var clear := StandardMaterial3D.new()
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color = Color(1, 1, 1, 0)
	for n: Node in _world.get_children():
		if n != _cam and n != w:
			n.queue_free()
	await process_frame
	for n: Node in w.get_children():
		var gi := n as MeshInstance3D
		if gi == null:
			if n is GeometryInstance3D:
				(n as GeometryInstance3D).visible = false
			continue
		if gi.name == "Body":
			gi.set_surface_override_material(0, black)
			gi.set_surface_override_material(1, clear)   # the contact shadow disc
		elif gi.name == "Essence":
			gi.material_override = black
		else:
			gi.visible = false
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	_world.add_child(we)
	await _shot("silhouette_z40", 40.0, w.global_position + Vector3(0, 1.2, 0), 0.6)
