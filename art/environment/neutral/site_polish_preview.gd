extends SceneTree
## Task MAP.P2 screenshots: every existing neutral site on the real Crown Hollow skirmish map
## (scenes/skirmish.tscn) with the game camera (pitch 55, fov 50) at zoom 40 and 55. Bot off, fog off, HUD hidden,
## lost caches forced to appear. Saves docs/art/screens/map_polish2_<tag>_<site>_z<zoom>.png.
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/neutral/site_polish_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 9000 -- tag=after
## `only=<site>,<site>` renders only those sites (tavern, peddler, cache, crown, post, den, lodge, waystone).

const ZOOMS: Array[float] = [40.0, 55.0]

var main: Node
var _tag := "shot"
var _only := ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _first_in(group: StringName, west: bool = true) -> Node3D:
	var best: Node3D = null
	for n: Node in root.get_tree().get_nodes_in_group(group):
		var n3 := n as Node3D
		if n3 == null:
			continue
		if best == null or (n3.global_position.x < best.global_position.x) == west:
			best = n3
	return best


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer and n.name != &"Vignette":
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	for c: Node in root.get_tree().get_nodes_in_group(&"lost_caches"):
		c.set(&"_wait_left", 0.0)
	for i in 10:
		await process_frame
	var sites: Array = []   # [name, Vector3]
	var t := _first_in(&"taverns")
	if t: sites.append(["tavern", t.global_position])
	var p := _first_in(&"peddlers")
	if p: sites.append(["peddler", p.global_position])
	var c := _first_in(&"lost_caches")
	if c: sites.append(["cache", c.global_position])
	var crown: Node3D = main.get(&"crown")
	if crown: sites.append(["crown", crown.global_position])
	var tp := _first_in(&"trade_posts")
	if tp: sites.append(["post", tp.global_position])
	for g: Node in root.get_tree().get_nodes_in_group(&"guilds"):
		var g3 := g as Node3D
		if g3.global_position.x < 0.0:
			sites.append(["den" if String(g3.name).begins_with("Magpie") else "lodge", g3.global_position])
	var ws := _waystone_spot()
	if ws != Vector3.INF:
		sites.append(["waystone", ws])
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in sites:
		if _only != "" and not _only.split(",").has(s[0]):
			continue
		for z: float in ZOOMS:
			rig.set(&"_target_zoom", z)
			rig.set(&"_zoom", z)
			rig.rotation.y = 0.0
			rig.call(&"focus_on", s[1])
			for i in 40:
				await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			var path := "res://docs/art/screens/map_polish2_%s_%s_z%d.png" % [_tag, s[0], int(z)]
			img.save_png(ProjectSettings.globalize_path(path))
			print("saved %s at %s draws=%d" % [path, str(s[1]),
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("SHOTS DONE")
	quit()


## A waystone of the ring-road MultiMesh on the west side (the one nearest (-40, 0, -10)).
func _waystone_spot() -> Vector3:
	var best := Vector3.INF
	for n: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or not String(mmi.multimesh.mesh.resource_path).contains("waystone"):
			continue
		for i in mmi.multimesh.instance_count:
			var pos: Vector3 = mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin
			if best == Vector3.INF or pos.distance_to(Vector3(-40.0, 0.0, -10.0)) < best.distance_to(Vector3(-40.0, 0.0, -10.0)):
				best = pos
	return best
