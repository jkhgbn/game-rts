extends SceneTree
## Task 12.V24 screenshots on the real skirmish map (scenes/skirmish.tscn with its river, fords and decor; bot off,
## fog off, HUD hidden, camps_enabled off so the CampManager does not spawn): the 8 camp sites placed with
## CampSite.place_at() on the map-fill.md 5.2 spots, the creature models (art/units/neutral/) staged on the
## NeutralCamp ring (r 1.5 / 2.0, slot 0 toward the map centre; the stag on the spot). Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/camps/camps_preview.gd
##       --resolution 1600x900 --quit-after 12000 -- [only=<shot>,<shot>]
## Saves docs/art/screens/12_v24_<shot>.png. *_cleared shots: set_cleared(true) on every site, creatures hidden.
## *_mirror shots: the enemy-side copy (camera turned 180 deg, as the enemy sees its own camp).

const SITE_SCRIPT := "res://art/environment/camps/camp_site.gd"
const SPOTS: Array = [
	# [id, kind, pos]
	["wallow_s", &"bristleback", Vector3(-14.0, 0.0, 57.0)], ["wallow_n", &"bristleback", Vector3(14.0, 0.0, -57.0)],
	["nest_s", &"mirefang", Vector3(8.5, 0.0, 34.0)], ["nest_n", &"mirefang", Vector3(-8.5, 0.0, -34.0)],
	["hollow_nw", &"gloomcap", Vector3(-55.0, 0.0, -55.0)], ["hollow_se", &"gloomcap", Vector3(55.0, 0.0, 55.0)],
	["stag_w", &"hollow_stag", Vector3(-37.0, 0.0, -10.0)], ["stag_e", &"hollow_stag", Vector3(37.0, 0.0, 10.0)],
]
const CREATURES := {
	&"bristleback": ["res://art/units/neutral/bristleback/bristleback.tscn", "res://art/units/neutral/bristleback/bristleback.tscn"],
	&"mirefang": ["res://art/units/neutral/mirefang/mirefang.tscn", "res://art/units/neutral/mirefang/mirefang.tscn",
		"res://art/units/neutral/mirefang/mirefang.tscn"],
	&"gloomcap": ["res://art/units/neutral/gloomcap/gloomcap_elder.tscn", "res://art/units/neutral/gloomcap/gloomcap_sprout.tscn",
		"res://art/units/neutral/gloomcap/gloomcap_sprout.tscn", "res://art/units/neutral/gloomcap/gloomcap_sprout.tscn"],
	&"hollow_stag": ["res://art/units/neutral/hollow_stag/hollow_stag.tscn"],
}
const RING_RADII: Array[float] = [1.5, 2.0]

const SHOTS: Array = [
	# [name, zoom, focus, yaw deg, cleared]
	["wallow_z40", 40.0, Vector3(-14.0, 0, 57.0), 0.0, false],
	["wallow_z18", 18.0, Vector3(-14.0, 0.3, 57.0), 0.0, false],
	["wallow_cleared_z18", 18.0, Vector3(-14.0, 0.3, 57.0), 0.0, true],
	["wallow_mirror_z40", 40.0, Vector3(14.0, 0, -57.0), 180.0, false],
	["nest_z40", 40.0, Vector3(-8.5, 0, -34.0), 0.0, false],
	["nest_z16", 16.0, Vector3(-8.5, 0.2, -34.0), 0.0, false],
	["nest_cleared_z16", 16.0, Vector3(-8.5, 0.2, -34.0), 0.0, true],
	["nest_mirror_z40", 40.0, Vector3(8.5, 0, 34.0), 180.0, false],
	["hollow_z40", 40.0, Vector3(-55.0, 0, -55.0), 0.0, false],
	["hollow_z18", 18.0, Vector3(-55.0, 0.3, -55.0), 0.0, false],
	["hollow_cleared_z18", 18.0, Vector3(-55.0, 0.3, -55.0), 0.0, true],
	["hollow_mirror_z40", 40.0, Vector3(55.0, 0, 55.0), 180.0, false],
	["stag_z40", 40.0, Vector3(-37.0, 0, -10.0), 0.0, false],
	["stag_z18", 18.0, Vector3(-37.0, 0.3, -10.0), 0.0, false],
	["stag_cleared_z18", 18.0, Vector3(-37.0, 0.3, -10.0), 0.0, true],
	["stag_mirror_z40", 40.0, Vector3(37.0, 0, 10.0), 180.0, false],
]

var main: Node
var _only: PackedStringArray = PackedStringArray()
var _sites: Array[Node3D] = []
var _creatures: Array[Node3D] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	main.set(&"camps_enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _wanted(s: String) -> bool:
	return _only.is_empty() or _only.has(s)


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	# Park the player's army far from the camps (the hero spawns at the keep, fine).
	_place_sites()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var cleared_now := false
	for s: Array in SHOTS:
		if not _wanted(s[0]):
			continue
		if bool(s[4]) != cleared_now:
			cleared_now = bool(s[4])
			for site: Node3D in _sites:
				site.call(&"set_cleared", cleared_now, true)
			for c: Node3D in _creatures:
				c.visible = not cleared_now
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = deg_to_rad(float(s[3]))
		rig.call(&"focus_on", s[2])
		for i in 60:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/12_v24_%s.png" % s[0]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s fps=%d draws=%d prims=%d" % [path, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	rig.rotation.y = 0.0
	if _wanted("silhouette"):
		await _silhouette()
	print("SHOTS DONE")
	quit()


func _place_sites() -> void:
	var script: GDScript = load(SITE_SCRIPT) as GDScript
	for sp: Array in SPOTS:
		var kind: StringName = sp[1]
		var pos: Vector3 = sp[2]
		var site: Node3D = (load(script.call(&"scene_path", kind)) as PackedScene).instantiate() as Node3D
		main.add_child(site)
		site.call(&"place_at", pos)
		_sites.append(site)
		var paths: Array = CREATURES[kind]
		var a0: float = atan2(-pos.z, -pos.x)
		for i: int in paths.size():
			var m: Node3D = (load(paths[i]) as PackedScene).instantiate() as Node3D
			main.add_child(m)
			var off := Vector3.ZERO
			if paths.size() > 1:
				var a: float = a0 + TAU * float(i) / float(paths.size())
				var r: float = RING_RADII[i % RING_RADII.size()]
				off = Vector3(cos(a) * r, 0.0, sin(a) * r)
			m.position = pos + off
			m.rotation.y = a0 + 0.9 * i + 0.4
			_creatures.append(m)


## Black silhouettes on white at zoom 40 (art-keep.md 0.1): the four sites side by side, alive, no creatures.
func _silhouette() -> void:
	root.remove_child(main)
	var world := Node3D.new()
	root.add_child(world)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var clear := StandardMaterial3D.new()
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color = Color(1, 1, 1, 0)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	world.add_child(we)
	var script: GDScript = load(SITE_SCRIPT) as GDScript
	var kinds: Array[StringName] = [&"bristleback", &"mirefang", &"gloomcap", &"hollow_stag"]
	for i in kinds.size():
		var site: Node3D = (load(script.call(&"scene_path", kinds[i])) as PackedScene).instantiate() as Node3D
		world.add_child(site)
		site.position = Vector3(-15.0 + 10.0 * i, 0, 200.0)
		for g: Node in site.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			if mi.name == "Ground" or mi.name == "Cleared":
				mi.visible = false
				continue
			for s in mi.mesh.get_surface_count():
				var m: Material = mi.mesh.surface_get_material(s)
				var contact: bool = m != null and m.resource_path.contains("contact")
				mi.set_surface_override_material(s, clear if contact else black)
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 400.0
	world.add_child(cam)
	var p: float = deg_to_rad(55.0)
	var focus := Vector3(0.0, 0.5, 200.0)
	cam.position = focus + Vector3(0.0, sin(p) * 40.0, cos(p) * 40.0)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	cam.current = true
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/12_v24_silhouette_z40.png"
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)
