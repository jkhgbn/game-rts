extends SceneTree
## G2a ground / foliage shots and fps (docs/art/g2a_ground.md). Windowed only. One map per run:
##   & tools\godot_run.ps1 --path . -s res://art/environment/grass/g2a_shots.gd --fixed-fps 60 --quit-after 40000 `
##       '--' --map=crown --gfx=high --tag=after [--fps] [--no-shots] [--res=1920x1080]
## --map=crown (scenes/skirmish.tscn) | thornwater (LayoutLevel + data/maps/thornwater_layout.tres)
## --gfx= low|medium|high|ultra (GameSettings reads it itself), --tag= file name prefix (before / after)
## --fps: after the shots, unfreezes the match and measures frame times (vsync off, real time, not --fixed-fps
##        stepping: Engine.max_fps 0) over FPS_FRAMES frames at two views; prints "G2A_FPS view=.. avg=.. low1=..".
## Shots go to docs/art/lab/g2a_ground/<tag>_<map>_<gfx>_<view>.png.
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped.

const OUT := "res://docs/art/lab/g2a_ground/"
const SKIRMISH := "res://scenes/skirmish.tscn"
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
const THORNWATER := "res://data/maps/thornwater_layout.tres"
const GRASS_FIELD := "res://art/environment/grass/ground_detail.gd"
const FPS_WARMUP := 90
const FPS_FRAMES := 900

var args := {}
var main: Node = null
var map_id := "crown"
var tag := "shot"
var gfx := "high"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	map_id = String(args.get("map", "crown"))
	tag = String(args.get("tag", "shot"))
	gfx = String(args.get("gfx", "high"))
	if DisplayServer.get_name() == "headless":
		print("G2A_SHOTS ERROR: needs a window")
		quit(2)
		return
	var res := String(args.get("res", "1920x1080")).split("x")
	var size := Vector2i(int(res[0]), int(res[1]))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(size)
	root.content_scale_size = size
	for i in 6:
		await process_frame
	print("G2A_SHOTS window=%s viewport=%s gfx=%s map=%s" % [str(DisplayServer.window_get_size()),
		str(root.get_visible_rect().size), gfx, map_id])
	if map_id == "thornwater":
		main = (load(LAYOUT_SCENE) as PackedScene).instantiate()
		main.set(&"layout_path", THORNWATER)
	else:
		main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			print("G2A_SHOTS ERROR: match never started")
			quit(2)
			return
	if map_id != "crown" and not args.has("no-detail") and ResourceLoader.exists(GRASS_FIELD):
		# Thornwater has no MapDressingArt: add GroundDetail as the main.gd hook (handoff) will.
		(load(GRASS_FIELD) as Script).call(&"ensure", main)
	for i in 30:
		await process_frame
	var gdn: Node = main.get_node_or_null(^"GroundDetail")
	if gdn:
		var w := 0
		while not bool(gdn.call(&"is_baked")) and w < 600:
			await process_frame
			w += 1
		print("G2A_DETAIL baked=%s bake=%s counts=%s quality=%d" % [str(gdn.call(&"is_baked")),
			str(gdn.call(&"bake_stats")), str(gdn.call(&"instance_counts")), int(gdn.get(&"quality"))])
		if args.has("dump-bake"):
			var bi: Array = gdn.call(&"bake_images")
			for k in bi.size():
				var im := (bi[k] as Image).duplicate() as Image
				im.clear_mipmaps()
				im.save_png(ProjectSettings.globalize_path(OUT + "bake_%s_%d.png" % [map_id, k]))
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(size) - Vector2(2, 2))
	var keep := _keep_pos(0)
	var inward := Vector3(-keep.x, 0.0, -keep.z).normalized()
	if not args.has("hud-on"):
		for n in main.find_children("*", "CanvasLayer", true, false):
			(n as CanvasLayer).visible = false
	var views: Array = [
		["z10", keep + inward * 9.0 + Vector3(2.0, 0.0, 0.0), 10.0],
		["z30", keep + inward * 12.0, 30.0],
		["z50", keep + inward * 22.0, 50.0],
	]
	if map_id == "crown":
		views.append(["meadow30", Vector3(-24.0, 0.0, 18.0), 30.0])
		views.append(["meadow10", Vector3(-26.0, 0.0, 20.0), 10.0])
		views.append(["centre45", Vector3(0.0, 0.0, 0.0), 45.0])
	else:
		views.append(["centre45", Vector3(0.0, 0.0, 0.0), 45.0])
	var fog: Variant = main.get(&"fog")
	if not args.has("no-shots"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		for v: Array in views:
			var fog_off := not args.has("fog")
			if fog_off and fog is Node and &"enabled" in fog:
				(fog as Node).set(&"enabled", false)
			_place(v[1], v[2])
			for i in 20:
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var path := OUT + "%s_%s_%s_%s.png" % [tag, map_id, gfx, v[0]]
			img.save_png(ProjectSettings.globalize_path(path))
			print("G2A_SHOT %s" % path)
			if gdn:
				print("  detail pos=%s children=%s" % [str((gdn as Node3D).global_position), str(gdn.get_children().map(func(ch: Node) -> String: return "%s vis=%s" % [ch.name, str((ch as Node3D).visible) if ch is Node3D else "-"]))])
			if fog_off and fog is Node and &"enabled" in fog:
				(fog as Node).set(&"enabled", true)
	if args.has("fps"):
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		if gdn and args.has("gd-q"):
			gdn.call(&"set_quality", int(String(args["gd-q"])))
		if gdn and args.has("gd-far-off"):
			var fr: Node = gdn.get_node_or_null(^"GrassFar")
			if fr:
				fr.queue_free()
		Engine.max_fps = 0
		Engine.physics_ticks_per_second = 60
		await _measure("fps_z30", keep + inward * 12.0, 30.0)
		await _measure("fps_z50", Vector3(0.0, 0.0, 0.0), 50.0)
		await _measure("fps_z10", keep + inward * 9.0, 10.0)
	print("G2A_SHOTS done")
	quit(0)


func _measure(view: String, at: Vector3, zoom: float) -> void:
	_place(at, zoom)
	for i in FPS_WARMUP:
		await process_frame
	var times := PackedFloat64Array()
	var last := Time.get_ticks_usec()
	for i in FPS_FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last) / 1000.0)
		last = now
	var sum := 0.0
	for t in times:
		sum += t
	var avg_ms := sum / float(times.size())
	var sorted := times.duplicate()
	sorted.sort()
	var n1 := maxi(1, int(sorted.size() / 100.0))
	var worst := 0.0
	for i in n1:
		worst += sorted[sorted.size() - 1 - i]
	worst /= float(n1)
	var gpu_ms := 0.0
	for i in 30:
		await process_frame
		gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()) / 30.0
	print("G2A_FPS map=%s gfx=%s view=%s avg=%.1f low1=%.1f avg_ms=%.2f gpu_ms=%.2f draws=%d prims=%d" % [map_id, gfx,
		view, 1000.0 / avg_ms, 1000.0 / worst, avg_ms, gpu_ms,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])


func _place(at: Vector3, zoom: float) -> void:
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	(cam as Node3D).rotation = Vector3.ZERO
	(cam as Node).call(&"focus_on", at)
	(cam as Node).set(&"_zoom", zoom)
	(cam as Node).set(&"_target_zoom", zoom)
	(cam as Node).call(&"_apply_zoom")


func _keep_pos(team: int) -> Vector3:
	for b in get_nodes_in_group(&"buildings"):
		var sc := b.get_script() as Script
		if int(b.get(&"team")) == team and sc != null and sc.resource_path.contains("keep"):
			return (b as Node3D).global_position
	return Vector3.ZERO
