extends SceneTree
## G-D map props shots and fps (docs/art/gd_props.md). Windowed only. One map per run:
##   & tools\godot_run.ps1 --path . -s res://art/environment/nature_props/gd_props_shots.gd --fixed-fps 60 `
##       --quit-after 40000 '--' --map=crown --gfx=high --tag=after [--fps] [--no-shots] [--only=crown10,crystal10]
## --map=crown (scenes/skirmish.tscn) | thornwater (LayoutLevel + data/maps/thornwater_layout.tres)
## --gfx= low|medium|high|ultra (GameSettings reads it itself), --tag= file name prefix (before / after)
## --fps: after the shots, unfreezes the match and measures frame times (vsync off, Engine.max_fps 0) at a
##        full-map view and at zoom 30 over a forest edge; prints "GDP_FPS view=.. avg=.. low1=.. gpu_ms=..".
## Views: crown30 / crown10 (Ember Crown pedestal), crystal30 / crystal10 (the player's nearest crystal node, one
## half-mined node next to it in crystal10 when there are two), forest30 / forest10 (the densest tree group near the
## player's base), camp10 (nearest monster camp), point10 (nearest capture point), full55.
## Shots go to docs/art/lab/gd_props/<tag>_<map>_<gfx>_<view>.png.
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped.

const OUT := "res://docs/art/lab/gd_props/"
const SKIRMISH := "res://scenes/skirmish.tscn"
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
const THORNWATER := "res://data/maps/thornwater_layout.tres"
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
		print("GDP_SHOTS ERROR: needs a window")
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
			print("GDP_SHOTS ERROR: match never started")
			quit(2)
			return
	for i in 60:
		await process_frame
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(size) - Vector2(2, 2))
	# HUD off; the lighting rig's own layers (vignette / haze) are part of the look and stay.
	var rigs := get_nodes_in_group(&"lighting_rigs")
	for n in main.find_children("*", "CanvasLayer", true, false):
		var in_rig := false
		for r in rigs:
			if r == n or (r as Node).is_ancestor_of(n):
				in_rig = true
		if not in_rig:
			(n as CanvasLayer).visible = false
	# --props-tier=N: the shared prop materials at another tier than the game's (A/B in one build; 0 = pre-G-D look).
	if args.has("props-tier"):
		var pl: Variant = load("res://art/environment/nature_props/props_look.gd")
		(pl as Script).call(&"apply", int(String(args["props-tier"])))
	var keep := _keep_pos(0)
	var crystal := _nearest_in(&"crystal_nodes", keep)
	var forest := _forest_spot(keep)
	var views: Array = [
		["crown30", Vector3.ZERO, 30.0],
		["crown10", Vector3(0.0, 0.0, 1.0), 10.0],
		["crystal30", crystal, 30.0],
		["crystal10", crystal, 10.0],
		["forest30", forest, 30.0],
		["forest10", forest, 10.0],
		["camp10", _nearest_in(&"neutral_camps", keep), 12.0],
		["point10", _nearest_in(&"capture_points", keep), 12.0],
		["full55", Vector3.ZERO, 55.0],
	]
	# Show depletion: the second-nearest node of the player's field at 40 %.
	var second := _second_crystal(crystal)
	if second and second.has_method(&"take"):
		var left := int(second.get(&"crystals_left"))
		second.call(&"take", int(left * 0.6))
	var only: PackedStringArray = String(args.get("only", "")).split(",", false)
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	if not args.has("no-shots"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		for v: Array in views:
			if not only.is_empty() and not only.has(String(v[0])):
				continue
			if v[1] == Vector3.INF:
				continue
			_place(v[1], v[2])
			for i in 24:
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var path := OUT + "%s_%s_%s_%s.png" % [tag, map_id, gfx, v[0]]
			img.save_png(ProjectSettings.globalize_path(path))
			print("GDP_SHOT %s at %s" % [path, str(v[1])])
	if args.has("fps"):
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		Engine.max_fps = 0
		Engine.physics_ticks_per_second = 60
		await _measure("fps_full55", Vector3.ZERO, 55.0)
		await _measure("fps_forest30", forest if forest != Vector3.INF else keep, 30.0)
		await _measure("fps_crown30", Vector3.ZERO, 30.0)
	print("GDP_SHOTS done")
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
	print("GDP_FPS map=%s gfx=%s view=%s avg=%.1f low1=%.1f avg_ms=%.2f gpu_ms=%.2f draws=%d prims=%d" % [map_id, gfx,
		view, 1000.0 / avg_ms, 1000.0 / worst, avg_ms, gpu_ms,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])


func _place(at: Vector3, zoom: float) -> void:
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	# Dev tool only: RTSCamera has no public "set zoom now". Its public fly_to(pos, yaw, zoom, 0) was tried and framed
	# a different spot than focus_on (the shots must match the before set, taken this way), so this writes the
	# camera's own zoom fields like g2a_shots.gd does. Game code never does this.
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


func _nearest_in(group: StringName, to: Vector3) -> Vector3:
	var best := Vector3.INF
	var bd := INF
	for n in get_nodes_in_group(group):
		if not (n is Node3D):
			continue
		var p := (n as Node3D).global_position
		var d := p.distance_to(to)
		if d < bd:
			bd = d
			best = p
	return best


func _second_crystal(first: Vector3) -> Node:
	var best: Node = null
	var bd := INF
	for n in get_nodes_in_group(&"crystal_nodes"):
		var p := (n as Node3D).global_position
		var d := p.distance_to(first)
		if d > 0.5 and d < bd and d < 9.0:
			bd = d
			best = n
	return best


## The tree (EnvProps MultiMesh instance) with the most trees within 8 m, among those 12-40 m from the keep.
func _forest_spot(keep: Vector3) -> Vector3:
	var pts: Array[Vector3] = []
	var env := main.get_node_or_null(^"EnvProps")
	if env == null:
		return Vector3.INF
	for c in env.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi == null or not String(mmi.name).begins_with("Tree"):
			continue
		for i in mmi.multimesh.instance_count:
			pts.append(mmi.multimesh.get_instance_transform(i).origin)
	var best := Vector3.INF
	var bn := -1
	for p in pts:
		var dk := Vector2(p.x - keep.x, p.z - keep.z).length()
		if dk < 12.0 or dk > 40.0:
			continue
		var n := 0
		for q in pts:
			if p.distance_squared_to(q) < 64.0:
				n += 1
		if n > bn:
			bn = n
			best = p
	return best
