extends SceneTree
## Task 10.V10 screenshots on the real skirmish map (scenes/skirmish.tscn, bot off, fog off, HUD hidden): the ring road
## of market-trade.md 2.1 painted by the ground shader (road_segs / road_count), waystones from WaystoneRow, the four
## trading posts at their centres turned toward their doors (TradePostModel.yaw_for_door) with their signs. Trees and
## rocks inside the road corridors and the post clearings are hidden (10.C1 removes them in the real map).
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/buildings/trade_post/trade_post_preview.gd
##       --resolution 1600x900 --quit-after 9000 -- [only=<shot>,<shot>]
## Saves docs/art/screens/trade_<shot>.png.

const POST_SCENE := "res://art/buildings/trade_post/trade_post.tscn"
const ROW_PATH := "res://art/environment/meshes/waystone_row.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
## market-trade.md 2.1: ring road nodes (player side; the enemy side is the point mirror).
const HUB := Vector2(-36, 36)
const W_DOOR := Vector2(-49, 1)
const NW1 := Vector2(-48, -44)
const NW2 := Vector2(-44, -48)
const S_DOOR := Vector2(-1, 49)
## [id, centre, door, sign]
const POSTS: Array = [
	[&"heron_ford", Vector3(-53, 0, 1), Vector3(-49, 0, 1)],
	[&"millstone_cross", Vector3(-1, 0, 53), Vector3(-1, 0, 49)],
	[&"lantern_wharf", Vector3(53, 0, -1), Vector3(49, 0, -1)],
	[&"saltgate", Vector3(1, 0, -53), Vector3(1, 0, -49)],
]
const HOUSES: Array[Vector3] = [Vector3(-55, 0, -45), Vector3(55, 0, 45), Vector3(-45, 0, -55), Vector3(45, 0, 55)]

const SHOTS: Array = [
	# [name, zoom, focus, setup]
	["post_heron_z20", 20.0, Vector3(-50.5, 0, 2.0), ""],
	["post_millstone_z20", 20.0, Vector3(-1.0, 0, 50.5), ""],
	["post_lantern_z20", 20.0, Vector3(50.5, 0, -0.5), ""],
	["post_gate_z20", 20.0, Vector3(1.0, 0, -50.5), ""],
	["post_heron_z12", 12.0, Vector3(-51.0, 1.5, 2.0), ""],
	["post_heron_z55", 55.0, Vector3(-44.0, 0, 6.0), ""],
	["post_millstone_z55", 55.0, Vector3(-4.0, 0, 44.0), ""],
	["roads_z40_west", 40.0, Vector3(-43.0, 0, 16.0), ""],
	["roads_z15_close", 15.0, Vector3(-43.5, 0, 17.0), ""],
	["roads_z30_corner", 30.0, Vector3(-44.0, 0, -42.0), ""],
	["roads_z55_south", 55.0, Vector3(-18.0, 0, 38.0), ""],
	["roads_z55_north", 55.0, Vector3(18.0, 0, -38.0), ""],
	["posts_states_z20", 20.0, Vector3(-50.5, 0, 2.0), "states"],
	["roads_before_z40_west", 40.0, Vector3(-43.0, 0, 16.0), "no_roads"],
]

var main: Node
var _only: PackedStringArray = PackedStringArray()
var _ground: ShaderMaterial
var _roads := PackedVector4Array()
var _posts: Array[Node3D] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
	_roads = ring_roads()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


## The 10 ring road segments (market-trade.md 2.1) as vec4 (x0, z0, x1, z1).
static func ring_roads() -> PackedVector4Array:
	var half: Array = [[HUB, W_DOOR], [W_DOOR, NW1], [NW1, NW2], [NW2, -S_DOOR], [HUB, S_DOOR]]
	var out := PackedVector4Array()
	for s: Array in half:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		out.append(Vector4(a.x, a.y, b.x, b.y))
	for s: Array in half:
		var a: Vector2 = -(s[0] as Vector2)
		var b: Vector2 = -(s[1] as Vector2)
		out.append(Vector4(a.x, a.y, b.x, b.y))
	return out


## The map's ground (the 120 m plane with the ground shader; not the map dressing's plateau).
func _find_ground() -> ShaderMaterial:
	for mi: Node in main.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		var plane := (mi as MeshInstance3D).mesh as PlaneMesh
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and plane and plane.size.x <= 121.0:
			print("ground: %s road_count=%s" % [mi.get_path(), str(sm.get_shader_parameter(&"road_count"))])
			return sm
	return null


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	# The skirmish (10.C1) paints the roads itself (EnvProps.set_roads); older maps get the spec's ring here.
	_ground = _find_ground()
	if _ground and int(_ground.get_shader_parameter(&"road_count") if _ground.get_shader_parameter(&"road_count") != null else 0) == 0:
		_ground.set_shader_parameter(&"road_segs", _roads)
		_ground.set_shader_parameter(&"road_count", _roads.size())
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_clear_corridors()
	_place_posts()
	var row: Script = load(ROW_PATH) as Script
	var clear := PackedVector3Array([Vector3(HUB.x, 0, HUB.y), Vector3(-HUB.x, 0, -HUB.y)])
	var radii := PackedFloat32Array([14.0, 14.0])
	for p: Array in POSTS:
		clear.append(p[1])
		radii.append(7.0)
	for h: Vector3 in HOUSES:
		clear.append(h)
		radii.append(7.0)
	var stones: MultiMeshInstance3D = row.call(&"build", _roads, 10.0, 2.2, 5.0, clear, radii, 6.0)
	if stones:
		main.add_child(stones)
		print("waystones: %d" % stones.multimesh.instance_count)
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		if not _only.is_empty() and not _only.has(s[0]):
			continue
		var setup: String = s[3]
		if setup == "states":
			_posts[0].call(&"set_open", false)
			_posts[1].call(&"set_held", Color(0.85, 0.30, 0.12))
		if setup == "no_roads" and _ground:
			_ground.set_shader_parameter(&"road_count", 0)
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		var saved_xf: Transform3D = (_posts[1].get_parent() as Node3D).transform
		if setup == "states":
			# Put the closed Heron Ford and a held copy side by side: move Millstone's model next to it for the shot.
			_posts[1].get_parent().position = Vector3(-49.0, 0, 11.0)
			_posts[1].get_parent().rotation.y = PI * 0.5
		for i in 70:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/trade_%s.png" % s[0]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		if setup == "states":
			_posts[0].call(&"set_open", true)
			_posts[1].call(&"set_held", null)
			(_posts[1].get_parent() as Node3D).transform = saved_xf
		if setup == "no_roads" and _ground:
			_ground.set_shader_parameter(&"road_count", _roads.size())
	if _only.has("gpu"):
		await _gpu_cost(rig)
	if _only.is_empty() or _only.has("silhouette"):
		await _silhouette()
	print("SHOTS DONE")
	quit()


func _place_posts() -> void:
	# The skirmish (10.C1) already places TradePosts that show this model: open them and use their models.
	var existing: Array[Node] = get_nodes_in_group(&"trade_posts")
	if not existing.is_empty():
		for p: Array in POSTS:
			for tp: Node in existing:
				if tp.get(&"post_id") == p[0]:
					tp.call(&"set_open", true)
					var art: Node3D = tp.call(&"model") as Node3D
					if art and art.has_method(&"set_sign"):
						_posts.append(art)
		if _posts.size() == POSTS.size():
			print("using the skirmish's TradePosts")
			return
		_posts.clear()
	var scene := load(POST_SCENE) as PackedScene
	for p: Array in POSTS:
		var holder := Node3D.new()   # stands in for TradePost (10.C1)
		holder.name = "Post_%s" % p[0]
		holder.position = p[1]
		holder.rotation.y = TradePostModel.yaw_for_door(p[1], p[2])
		main.add_child(holder)
		var m: Node3D = scene.instantiate() as Node3D
		m.call(&"set_sign", TradePostModel.sign_for_post(p[0]))
		holder.add_child(m)
		_posts.append(m)


## Preview only: hide the drawn trees / rocks / pillars within 2.5 m of a road (+1 m for their crowns) and inside the
## post / house clearings, like 10.C1 will remove them from the map.
func _clear_corridors() -> void:
	var env: Node = main.get(&"env_props")
	if env == null:
		return
	var hidden := 0
	for c: Node in env.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var q := Vector2(xf.origin.x, xf.origin.z)
			var do_hide := false
			for s: Vector4 in _roads:
				var cp: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(s.x, s.y), Vector2(s.z, s.w))
				if q.distance_to(cp) < 3.5:
					do_hide = true
					break
			for p: Array in POSTS:
				var pc: Vector3 = p[1]
				if q.distance_to(Vector2(pc.x, pc.z)) < 6.0:
					do_hide = true
			for h: Vector3 in HOUSES:
				if q.distance_to(Vector2(h.x, h.z)) < 7.0:
					do_hide = true
			if do_hide:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
					Vector3(xf.origin.x, -30.0, xf.origin.z)))
				hidden += 1
	print("hidden props: %d" % hidden)


## GPU time of the whole frame with the roads on / off (same view, the ground fills the screen), `only=gpu`.
func _gpu_cost(rig: Node3D) -> void:
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for view: Array in [[40.0, Vector3(-40.0, 0, 14.0)], [55.0, Vector3(-20.0, 0, 30.0)]]:
		rig.set(&"_target_zoom", view[0])
		rig.set(&"_zoom", view[0])
		rig.call(&"focus_on", view[1])
		var totals := {}
		for pass_i: int in 8:
			# [label, road_count, road_width]: "loop" runs the segment search but never paints.
			for mode: Array in [["roads", _roads.size(), 3.0], ["off", 0, 3.0], ["loop", _roads.size(), 0.0]]:
				_ground.set_shader_parameter(&"road_count", mode[1])
				_ground.set_shader_parameter(&"road_width", mode[2])
				for i in 20:
					await process_frame
				var sum := 0.0
				for i in 90:
					await process_frame
					sum += RenderingServer.viewport_get_measured_render_time_gpu(vp)
				totals[mode[0]] = float(totals.get(mode[0], 0.0)) + sum / 90.0 / 8.0
		print("gpu zoom %d: roads %.3f ms, off %.3f ms, search only %.3f ms" % [int(view[0]), totals["roads"],
				totals["off"], totals["loop"]])
	_ground.set_shader_parameter(&"road_count", _roads.size())
	_ground.set_shader_parameter(&"road_width", 3.0)


## Black silhouette on white of one post at zoom 40 (art-keep.md 0.1 test), in a separate small world.
func _silhouette() -> void:
	root.remove_child(main)   # its environment, vignette and fog must not tint the test
	var world := Node3D.new()
	root.add_child(world)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	world.add_child(we)
	var shots: Array = [[0, 0.0], [1, PI * 0.5], [2, PI], [3, -PI * 0.5]]
	var cams: Array[Camera3D] = []
	for i: int in 4:
		var holder := Node3D.new()
		holder.position = Vector3(-21.0 + i * 14.0, 0, 200.0)
		holder.rotation.y = float(shots[i][1])
		world.add_child(holder)
		var m: Node3D = (load(POST_SCENE) as PackedScene).instantiate() as Node3D
		m.call(&"set_sign", int(shots[i][0]))
		holder.add_child(m)
	for i2 in 3:
		await process_frame
	for g: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is GPUParticles3D or gi.name.begins_with("LightPool") or gi.name.ends_with("Decal") or gi.name == "Halo":
			gi.visible = false
		else:
			gi.material_override = black
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 400.0
	world.add_child(cam)
	var p: float = deg_to_rad(55.0)
	var focus := Vector3(0.0, 2.0, 200.0)
	cam.position = focus + Vector3(0.0, sin(p) * 40.0, cos(p) * 40.0)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	cam.current = true
	cams.append(cam)
	for i3 in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/trade_post_silhouette_z40.png"
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)
