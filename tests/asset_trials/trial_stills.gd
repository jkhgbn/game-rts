extends SceneTree
## Asset trials that need a renderer (windowed, one run): the real skirmish map (bot off, fog off, HUD hidden) with
##  1. Debug Draw 3D: the nav path from the player keep to the nearest crystal node + the hero's attack / aggro rings.
##  2. Material Maker: the exported rune texture (docs/art/asset_trials/material_maker/pentagram_emission.png) on an
##     additive ground quad under the hero (a spell circle).
##  3. Sky3D vs the current LightingRig (warm): RTS camera and a low cinematic camera, Sky3D at 06:30 / 12:00 / 18:30.
## GPU ms per frame (viewport measured render time, 60-frame average) is printed for every lighting setup.
## Stills: docs/art/asset_trials/<name>.png. Run (window, ~1 min):
##   tools\godot_run.ps1 --path . -s tests/asset_trials/trial_stills.gd --resolution 1280x720 --quit-after 9000

const OUT := "res://docs/art/asset_trials/"
const RUNE_PNG := "res://docs/art/asset_trials/material_maker/pentagram_emission.png"

## Debug Draw 3D drawer: redraws the path + rings each frame, times its own calls.
class Drawer extends Node:
	var path := PackedVector3Array()
	var rings: Array = []
	var label_pos := Vector3.ZERO
	var label := ""
	var us := 0
	var frames := 0

	func _process(_dt: float) -> void:
		var t := Time.get_ticks_usec()
		var _cfg: Object = DebugDraw3D.new_scoped_config().set_thickness(0.12)
		if path.size() >= 2:
			DebugDraw3D.draw_arrow_path(path, Color(0.2, 1.0, 0.4), 0.8)
		for r: Array in rings:
			DebugDraw3D.draw_line_path(r[0], r[1])
		DebugDraw3D.draw_text(label_pos, label, 64, Color.WHITE)
		us += Time.get_ticks_usec() - t
		frames += 1


var main: Node
var rig: Node3D
var hero: Node3D
var cine_cam: Camera3D


func _initialize() -> void:
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	hero = main.get(&"hero")
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	rig = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	cine_cam = Camera3D.new()
	cine_cam.fov = 40.0
	main.add_child(cine_cam)
	var hp := hero.global_position
	print("hero at %s" % hp)

	var only_dd := OS.get_cmdline_user_args().has("only=dd3d")
	if only_dd:
		await _debug_draw()
		print("STILLS DONE")
		quit()
		return
	# ---- current lighting: baseline stills + GPU time
	await _shot("sky_current_rts", false)
	await _shot("sky_current_cine", true)

	# ---- 1. Debug Draw 3D
	await _debug_draw()
	# ---- 2. Material Maker rune on the ground
	await _rune()

	# ---- 3. Sky3D
	for n: Node in main.find_children("*", "", true, false):
		if n.name == "LightingRig" or (n is WorldEnvironment) or (n is DirectionalLight3D and n.get_parent() == main):
			if is_instance_valid(n) and n.get_parent():
				n.get_parent().remove_child(n)
				n.queue_free()
	await process_frame
	var sky := Sky3D.new()
	sky.name = "Sky3D"
	main.add_child(sky)
	sky.game_time_enabled = false
	for h: Array in [[6.5, "dawn"], [12.0, "noon"], [18.5, "dusk"]]:
		sky.current_time = h[0]
		await _shot("sky3d_%s_rts" % h[1], false)
		await _shot("sky3d_%s_cine" % h[1], true)
	print("STILLS DONE")
	quit()


func _frame_rts() -> void:
	cine_cam.current = false
	(rig.get(&"camera") as Camera3D).current = true
	rig.set(&"_target_zoom", 28.0)
	rig.set(&"_zoom", 28.0)
	rig.rotation.y = 0.0
	rig.call(&"focus_on", hero.global_position)


func _frame_cine() -> void:
	var hp := hero.global_position
	cine_cam.global_position = hp + Vector3(5.0, 1.6, 9.0)
	cine_cam.look_at(hp + Vector3(-2.0, 4.0, -8.0))
	cine_cam.current = true


func _shot(tag: String, cine: bool) -> void:
	if cine:
		_frame_cine()
	else:
		_frame_rts()
	for i in 40:
		await process_frame
	var gpu := 0.0
	var cpu := 0.0
	for i in 60:
		await process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + tag + ".png"))
	print("STILL %s gpu=%.2f ms cpu_render=%.2f ms draws=%d fps=%d" % [tag, gpu / 60.0, cpu / 60.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Engine.get_frames_per_second()])


func _debug_draw() -> void:
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b.get(&"team") == 0 and b is Node3D:
			keep = b
			break
	var node: Node3D = null
	var best := INF
	for c: Node in get_nodes_in_group(&"crystal_nodes"):
		if keep and c is Node3D:
			var d := (c as Node3D).global_position.distance_to(keep.global_position)
			if d < best:
				best = d
				node = c
	var map_rid: RID = (main as Node3D).get_world_3d().navigation_map
	var path := PackedVector3Array()
	if keep and node:
		path = NavigationServer3D.map_get_path(map_rid, keep.global_position, node.global_position, true)
	print("DD3D nav path keep -> crystal: %d points, %.1f m straight" % [path.size(), best])
	var mgr: Object = Engine.get_singleton("DebugDrawManager") if Engine.has_singleton("DebugDrawManager") else null
	var kids: Array = []
	for k: Node in root.get_children():
		kids.append(String(k.name))
	print("DD3D enabled=%s manager=%s manager_in_tree=%s root children=%s" % [DebugDraw3D.debug_enabled, mgr,
			(mgr as Node).is_inside_tree() if mgr is Node else "n/a", str(kids)])
	var hp := hero.global_position
	var t0 := Time.get_ticks_usec()
	var lifted := PackedVector3Array()
	for p: Vector3 in path:
		lifted.append(p + Vector3.UP * 0.6)
	var rings: Array = []
	for ring: Array in [[float(hero.get(&"attack_range")), Color(1.0, 0.35, 0.1)], [float(hero.get(&"aggro_range")), Color(1.0, 0.9, 0.2)]]:
		var pts := PackedVector3Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(hp + Vector3(cos(a) * ring[0], 0.6, sin(a) * ring[0]))
		rings.append([pts, ring[1]])
	# The normal DD3D usage: a node that redraws every frame (duration 0).
	var drawer := Drawer.new()
	drawer.path = lifted
	drawer.rings = rings
	drawer.label_pos = hp + Vector3.UP * 3.5
	drawer.label = "atk %.0f m / aggro %.0f m" % [hero.get(&"attack_range"), hero.get(&"aggro_range")]
	drawer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(drawer)
	print("DD3D tree paused=%s (skirmish start pick pauses the game), manager process_mode=%s" % [paused,
			(mgr as Node).process_mode if mgr is Node else -1])
	if mgr is Node:
		(mgr as Node).process_mode = Node.PROCESS_MODE_ALWAYS
	print("DD3D setup %.3f ms; ranges atk=%s aggro=%s" % [(Time.get_ticks_usec() - t0) / 1000.0,
			hero.get(&"attack_range"), hero.get(&"aggro_range")])
	await process_frame
	await process_frame
	var stats: Object = DebugDraw3D.get_render_stats()
	var sd := {}
	for pr: Dictionary in stats.get_property_list():
		if pr.usage & PROPERTY_USAGE_EDITOR and pr.type == TYPE_INT:
			sd[pr.name] = stats.get(pr.name)
	print("DD3D stats: %s" % str(sd))
	if keep:
		# frame between the keep and the node so the path is on screen
		_frame_rts()
		rig.call(&"focus_on", (keep.global_position + (node.global_position if node else hp)) * 0.5)
		for i in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "debugdraw_path_keep.png"))
		print("STILL debugdraw_path_keep")
	await _shot("debugdraw_hero_rings", false)
	print("DD3D drawer: %.4f ms per frame avg over %d frames" % [drawer.us / 1000.0 / maxi(1, drawer.frames), drawer.frames])
	drawer.queue_free()
	DebugDraw3D.clear_all()


func _rune() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(RUNE_PNG))
	if img == null:
		print("MM rune png missing")
		return
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.albedo_color = Color(1.0, 0.75, 0.35) * 1.6   # red export tinted toward fire gold
	var q := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7.0, 7.0)
	q.mesh = pm
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main.add_child(q)
	q.global_position = hero.global_position + Vector3.UP * 0.06
	await _shot("mm_rune_circle_rts", false)
	await _shot("mm_rune_circle_cine", true)
	q.queue_free()
