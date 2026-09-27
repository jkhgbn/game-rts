extends SceneTree
## Task 12.V18 screenshots: four Wayshrines on the map's painted ground under the warm LightingRig, seen by the game
## camera (pitch 55, fov 50, distance = zoom), a Flame Guard and a Shadow Knight for scale. Windowed only:
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/buildings/capture/wayshrine/wayshrine_preview.gd
##       --resolution 1600x900 --quit-after 4000 -- [only=<shot>,<shot>]
## Saves docs/art/screens/wayshrine_<shot>.png: asleep, awake, capturing, owned (zoom 12 close-ups), states_z30 (the
## four side by side), blessing (mid-burst), awake_z40 / asleep_z40 (game zoom), silhouette_z40 (black on white).

const SCENE := "res://art/buildings/capture/wayshrine/wayshrine.tscn"
const RIG := "res://art/environment/lighting/lighting_rig.gd"
const GROUND_MAT := "res://art/environment/ground_material.tres"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
## Around the West Wayshrine's spot on the skirmish map ((-22, -6), map-fill.md 4.1): the ground shader is world-space,
## so the stage gets the real ground there (and stays off the Crown Isle paving).
const ORIGIN := Vector3(-30.0, 0.0, -6.0)
const SPACING := 11.0

var _only: PackedStringArray = PackedStringArray()
var _hide: PackedStringArray = PackedStringArray()   # debug: node names of the shrines to keep hidden (hide=Column,Halo)
var _world: Node3D
var _cam: Camera3D
var _shrines: Array[Node3D] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
		if arg.begins_with("hide="):
			_hide = arg.substr(5).split(",")
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	var rig: Node3D = (load(RIG) as GDScript).new() as Node3D
	_world.add_child(rig)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	ground.material_override = load(GROUND_MAT) as Material
	ground.position = ORIGIN
	_world.add_child(ground)
	var scene := load(SCENE) as PackedScene
	# 0 asleep neutral, 1 awake, 2 awake being captured by Fire, 3 asleep owned by Shadow.
	for i: int in 4:
		var s: Node3D = scene.instantiate() as Node3D
		s.position = _spot(i)
		match i:
			1:
				s.call(&"set_state", &"awake")
			2:
				s.call(&"set_state", &"awake")
				s.call(&"set_capture", FIRE, 0.62)
			3:
				s.call(&"set_owner_color", SHADOW)
		_world.add_child(s)
		_shrines.append(s)
	_add_unit("res://art/units/fire/flame_guard.tscn", _spot(1) + Vector3(2.6, 0, 1.4), -0.6)
	_add_unit("res://art/units/fire/flame_guard.tscn", _spot(2) + Vector3(-1.9, 0, 2.2), 0.5)
	_add_unit("res://art/units/fire/ember_archer.tscn", _spot(2) + Vector3(1.4, 0, 2.6), -0.3)
	_add_unit("res://art/units/shadow/shadow_knight.tscn", _spot(3) + Vector3(2.8, 0, 0.8), -1.2)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 400.0
	_world.add_child(_cam)
	_cam.current = true
	_run()


func _spot(i: int) -> Vector3:
	return ORIGIN + Vector3((float(i) - 1.5) * SPACING, 0.0, 0.0)


func _add_unit(path: String, pos: Vector3, yaw: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var u: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	u.position = pos
	u.rotation.y = yaw
	_world.add_child(u)


func _look(focus: Vector3, zoom: float) -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _wanted(shot: String) -> bool:
	return _only.is_empty() or _only.has(shot)


func _shot(shot: String, focus: Vector3, zoom: float, frames: int = 50) -> void:
	if not _wanted(shot):
		return
	_look(focus, zoom)
	for i in frames:
		await process_frame
		for s: Node3D in _shrines:
			for nm: String in _hide:
				var n := s.find_child(nm, true, false) as VisualInstance3D
				if n:
					n.layers = 0   # (the shrine drives `visible` itself)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/wayshrine_%s.png" % shot
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for i in 30:
		await process_frame
	var up := Vector3(0, 0.9, 0)
	await _shot("asleep", _spot(0) + up, 12.0)
	await _shot("awake", _spot(1) + up, 12.0)
	await _shot("capturing", _spot(2) + up, 12.0)
	await _shot("owned", _spot(3) + up, 12.0)
	await _shot("states_z30", ORIGIN + Vector3(0, 0, 1.0), 34.0)
	await _shot("awake_z40", _spot(1), 40.0)
	await _shot("asleep_z40", _spot(0), 40.0)
	if _wanted("blessing"):
		# Fire takes the awake shrine: blessing burst, it falls asleep in Fire's colour.
		_look(_spot(2) + up, 16.0)
		for i in 20:
			await process_frame
		var s: Node3D = _shrines[2]
		s.call(&"set_capture", FIRE, 1.0)
		for i in 10:
			await process_frame
		s.call(&"play_blessing", FIRE)
		s.call(&"set_capture", null, 0.0)
		s.call(&"set_state", &"asleep")
		s.call(&"set_owner_color", FIRE)
		await _shot("blessing", _spot(2) + up, 16.0, 48)
		for i in 120:
			await process_frame
		await _shot("captured_after", _spot(2) + up, 12.0, 10)
	if _wanted("silhouette_z40"):
		await _silhouette()
	print("SHOTS DONE")
	quit()


## Black silhouette on white at zoom 40 (art-keep.md 0.1): the awake shrine's geometry (the light effects hidden), from
## the front and turned 90 degrees, next to a Flame Guard.
func _silhouette() -> void:
	root.remove_child(_world)
	var w := Node3D.new()
	root.add_child(w)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	w.add_child(we)
	for i: int in 2:
		var s: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
		s.position = Vector3(-4.0 + i * 8.0, 0.0, 200.0)
		s.rotation.y = PI * 0.5 * i
		w.add_child(s)
	var u: Node3D = (load("res://art/units/fire/flame_guard.tscn") as PackedScene).instantiate() as Node3D
	u.position = Vector3(0.0, 0.0, 201.0)
	w.add_child(u)
	for i in 3:
		await process_frame
	for g: Node in w.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.name in ["Contact", "Ring", "Burst", "Column", "Motes", "Halo"] or gi is GPUParticles3D:
			gi.visible = false
			gi.set_meta(&"hidden", true)
		else:
			gi.material_override = black
	var cam := Camera3D.new()
	cam.fov = 50.0
	w.add_child(cam)
	var p: float = deg_to_rad(55.0)
	cam.position = Vector3(0.0, 0.8, 200.0) + Vector3(0.0, sin(p) * 40.0, cos(p) * 40.0)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	cam.current = true
	for i in 12:
		await process_frame
		# The shrine script re-shows its effects every frame: keep them hidden.
		for g2: Node in w.find_children("*", "GeometryInstance3D", true, false):
			if g2.has_meta(&"hidden"):
				(g2 as GeometryInstance3D).visible = false
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/wayshrine_silhouette_z40.png"
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)
