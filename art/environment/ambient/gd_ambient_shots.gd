extends SceneTree
## G-D ambient life shots, frame strips and fps (docs/art/gd_ambient.md). Windowed only. One map / mood per run:
##   & tools\godot_run.ps1 --path . -s res://art/environment/ambient/gd_ambient_shots.gd --quit-after 60000 `
##       '--' --map=crown --mood=day --gfx=high --tag=after [--fps] [--no-shots] [--no-ambient] [--fog]
## --map=crown (scenes/skirmish.tscn) | quartermeet | thornwater (LayoutLevel + data/maps/<id>_layout.tres)
## --mood=day | night (EmberfallNight.night() on the rig) | snow (the ice preset on the rig) | autumn (autumn_swap.gd)
## --gfx= low|medium|high|ultra (GameSettings reads it), --tag= file prefix, --no-ambient = the "before" (no node)
## --fps: frame times (vsync off, Engine.max_fps 0) over FPS_FRAMES at the full-map view (zoom 55, centre) and z35;
##        prints "GDA_FPS map=.. gfx=.. view=.. avg=.. low1=.. gpu_ms=..".
## --strip: 4 frames 0.4 s apart at the z35 view (motion), kept in the contact sheet.
## Output: docs/art/lab/gd_ambient/<tag>_<map>_<mood>_<gfx>_<view>.png (the folder has a .gdignore).
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped where they need them.

const OUT := "res://docs/art/lab/gd_ambient/"
const SKIRMISH := "res://scenes/skirmish.tscn"
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
const AMBIENT := "res://art/environment/ambient/ambient_life.gd"
const NIGHT := "res://art/environment/lighting/emberfall_night.gd"
const RIG := "res://art/environment/lighting/lighting_rig.gd"
const FPS_WARMUP := 90
const FPS_FRAMES := 600

var args := {}
var main: Node = null
var map_id := "crown"
var mood := "day"
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
	mood = String(args.get("mood", "day"))
	tag = String(args.get("tag", "shot"))
	gfx = String(args.get("gfx", "high"))
	if DisplayServer.get_name() == "headless":
		print("GDA_SHOTS ERROR: needs a window")
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
	if map_id != "crown":
		main = (load(LAYOUT_SCENE) as PackedScene).instantiate()
		main.set(&"layout_path", "res://data/maps/%s_layout.tres" % map_id)
	else:
		main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"nature")
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
			print("GDA_SHOTS ERROR: match never started")
			quit(2)
			return
	print("GDA_SHOTS paused=%s" % str(paused))
	paused = false   # a start-of-match pick (STR / INT) can hold the tree: ambient life runs with the game
	# Moods: the night / snow looks a mission would set.
	if mood == "night":
		var nn := load(NIGHT) as Script
		nn.call(&"apply_to", main, nn.call(&"night"))
	elif mood == "snow":
		for c in main.get_children():
			if c.get_script() == load(RIG):
				c.set(&"preset_id", &"ice")
				c.call(&"apply", (load(RIG) as Script).call(&"load_preset", &"ice"))
	elif mood == "autumn":   # the golden-autumn swap (art/environment/autumn/autumn_swap.gd), as a 2v2 map will
		var sw := load("res://art/environment/autumn/autumn_swap.gd") as Script
		sw.call(&"swap_shared_materials")
		sw.call(&"apply_ground", main)
		sw.call(&"apply_lighting", main)
	# GroundDetail (grass) as the level hook makes it, on layout maps too.
	var gd_path := "res://art/environment/grass/ground_detail.gd"
	if ResourceLoader.exists(gd_path):
		(load(gd_path) as Script).call(&"ensure", main)
	var al: Node = null
	if not args.has("no-ambient"):
		al = (load(AMBIENT) as Script).call(&"ensure", main)
		var w := 0
		while al and int(al.get(&"quality")) < 1 and w < 3000:
			await process_frame
			w += 1
		if al:
			print("GDA_AMBIENT quality=%d build_ms=%.1f trees=%d meadow=%d bank=%d water=%d road=%d heath=%d mood=%s" % [
				int(al.get(&"quality")), float(al.call(&"build_msec")), int(al.call(&"tree_count")),
				int(al.call(&"candidate_count", "meadow")), int(al.call(&"candidate_count", "bank")),
				int(al.call(&"candidate_count", "water")), int(al.call(&"candidate_count", "road")),
				int(al.call(&"candidate_count", "heath")), str(al.call(&"mood"))])
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(size) - Vector2(2, 2))
	if not args.has("hud-on"):
		for n in main.find_children("*", "CanvasLayer", true, false):
			if n.name != "Vignette":
				(n as CanvasLayer).visible = false
	var fog: Variant = main.get(&"fog")
	if not args.has("fog") and fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	var keep := _keep_pos(0)
	var inward := Vector3(-keep.x, 0.0, -keep.z).normalized()
	var views: Array = _views(keep, inward)
	var sheet: Array[Image] = []
	if not args.has("no-shots"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		for v: Array in views:
			_place(v[1], v[2])
			for i in 150:   # let the emitters fill round the new view (refresh + a few particle lives)
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var path := OUT + "%s_%s_%s_%s_%s.png" % [tag, map_id, mood, gfx, v[0]]
			img.save_png(ProjectSettings.globalize_path(path))
			sheet.append(img)
			print("GDA_SHOT %s" % path)
			if al:
				var info := {}
				for id: StringName in al.call(&"emitter_ids"):
					info[id] = al.call(&"emitter_info", id)
				print("  emitters %s flocks=%d" % [str(info), int(al.call(&"flock_count"))])
		if args.has("strip"):
			_place(views[1][1], views[1][2])
			for i in 60:
				await process_frame
			for k in 4:
				for i in 24:
					await process_frame
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				img.save_png(ProjectSettings.globalize_path(OUT + "%s_%s_%s_%s_strip%d.png" % [tag, map_id, mood, gfx, k]))
				sheet.append(img)
		_contact_sheet(sheet, OUT + "%s_%s_%s_%s_sheet.jpg" % [tag, map_id, mood, gfx])
	if args.has("fps"):
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		Engine.max_fps = 0
		await _measure("full55", Vector3.ZERO, 55.0)
		await _measure("z35", keep + inward * 14.0, 35.0)
	print("GDA_SHOTS done")
	quit(0)


func _views(keep: Vector3, inward: Vector3) -> Array:
	var v: Array = [["z35", keep + inward * 14.0, 35.0]]
	if map_id == "crown":
		v.append(["meadow32", Vector3(-26.0, 0.0, 24.0), 32.0])
		v.append(["wood32", Vector3(-40.0, 0.0, -38.0), 32.0])
		v.append(["river30", Vector3(-6.0, 0.0, -30.0), 30.0])
	else:
		v.append(["centre35", Vector3(0.0, 0.0, 0.0), 35.0])
		v.append(["mid32", keep * 0.5, 32.0])
	return v


func _contact_sheet(imgs: Array[Image], path: String) -> void:
	if imgs.is_empty():
		return
	var cols := 2 if imgs.size() <= 4 else 3
	var rows := int(ceil(float(imgs.size()) / float(cols)))
	var tw := 640
	var th := 360
	var sheet := Image.create_empty(tw * cols, th * rows, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.08))
	for i in imgs.size():
		var im := imgs[i].duplicate() as Image
		im.convert(Image.FORMAT_RGB8)
		im.resize(tw, th, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(im, Rect2i(0, 0, tw, th), Vector2i((i % cols) * tw, (i / cols) * th))
	sheet.save_jpg(ProjectSettings.globalize_path(path), 0.85)
	print("GDA_SHEET %s" % path)


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
	print("GDA_FPS map=%s mood=%s gfx=%s ambient=%s view=%s avg=%.1f low1=%.1f avg_ms=%.2f gpu_ms=%.2f draws=%d" % [
		map_id, mood, gfx, "off" if args.has("no-ambient") else "on", view, 1000.0 / avg_ms, 1000.0 / worst, avg_ms,
		gpu_ms, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])


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
