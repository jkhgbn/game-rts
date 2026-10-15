extends SceneTree
## G-D trees shots and fps (docs/art/gd_trees.md). Windowed only. One map per run:
##   & tools\godot_run.ps1 --path . -s res://art/environment/nature_props/gd_trees_shots.gd --fixed-fps 60 `
##       --quit-after 40000 '--' --map=crown --gfx=high --tag=after [--trees=<folder>] [--fps] [--no-shots] [--only=a,b]
## --map=crown (scenes/skirmish.tscn) | thornwater | quartermeet (LayoutLevel + data/maps/<id>_layout.tres; Quartermeet
##        is an autumn map)
## --trees=<absolute folder>: after the map is built, every MultiMesh / MeshInstance drawing a mesh whose file name
##        exists in that folder draws the copy from the folder instead (the pre-G-D tree / bush meshes kept outside the
##        project): before / after in ONE build, interleaved runs, nothing in the project swapped.
## --fps: frame times (vsync off, Engine.max_fps 0) at the full map (zoom 55) and over the densest forest (zoom 30);
##        prints "GDT_FPS map=.. gfx=.. trees=.. view=.. avg=.. low1=.. gpu_ms=..".
## Views: forest30 / forest10 (the densest tree group in the play area), edge30 / edge10 (the densest group 12-40 m
## from the player keep), full55. Shots go to docs/art/lab/gd_trees/<tag>_<map>_<gfx>_<view>.png.
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped.

const OUT := "res://docs/art/lab/gd_trees/"
const SKIRMISH := "res://scenes/skirmish.tscn"
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
const LAYOUTS := {
	"thornwater": "res://data/maps/thornwater_layout.tres",
	"quartermeet": "res://data/maps/quartermeet_layout.tres",
}
const FPS_WARMUP := 90
const FPS_FRAMES := 900

var args := {}
var main: Node = null
var map_id := "crown"
var tag := "shot"
var gfx := "high"
var trees_src := ""


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
	trees_src = String(args.get("trees", ""))
	if DisplayServer.get_name() == "headless":
		print("GDT_SHOTS ERROR: needs a window")
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
	if LAYOUTS.has(map_id):
		main = (load(LAYOUT_SCENE) as PackedScene).instantiate()
		main.set(&"layout_path", LAYOUTS[map_id])
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
			print("GDT_SHOTS ERROR: match never started")
			quit(2)
			return
	for i in 60:
		await process_frame
	if trees_src != "":
		print("GDT_SWAP %d mesh users -> %s" % [_swap_meshes(main, trees_src), trees_src])
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(size) - Vector2(2, 2))
	var rigs := get_nodes_in_group(&"lighting_rigs")
	for n in main.find_children("*", "CanvasLayer", true, false):
		var in_rig := false
		for r in rigs:
			if r == n or (r as Node).is_ancestor_of(n):
				in_rig = true
		if not in_rig:
			(n as CanvasLayer).visible = false
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	var keep := _keep_pos(0)
	var forest := _forest_spot(keep, 0.0, 1e9)
	var edge := _forest_spot(keep, 12.0, 40.0)
	var views: Array = [
		["forest30", forest, 30.0],
		["forest10", forest, 10.0],
		["edge30", edge, 30.0],
		["edge10", edge, 10.0],
		["full55", Vector3.ZERO, 55.0],
	]
	var only: PackedStringArray = String(args.get("only", "")).split(",", false)
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
			print("GDT_SHOT %s at %s" % [path, str(v[1])])
	if args.has("fps"):
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		Engine.max_fps = 0
		Engine.physics_ticks_per_second = 60
		await _measure("fps_full55", Vector3.ZERO, 55.0)
		await _measure("fps_forest30", forest if forest != Vector3.INF else keep, 30.0)
	print("GDT_SHOTS done")
	quit(0)


## Points every MultiMeshInstance3D / MeshInstance3D under `n` whose mesh file name exists in `folder` at the copy in
## that folder. Returns how many were swapped.
func _swap_meshes(n: Node, folder: String) -> int:
	var count := 0
	var cache := {}
	for c in n.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh:
			mesh = (c as MultiMeshInstance3D).multimesh.mesh
		elif c is MeshInstance3D:
			mesh = (c as MeshInstance3D).mesh
		if mesh == null or mesh.resource_path == "":
			continue
		var file := mesh.resource_path.get_file()
		var src := folder.path_join(file)
		if not FileAccess.file_exists(src):
			continue
		if not cache.has(src):
			cache[src] = ResourceLoader.load(src, "", ResourceLoader.CACHE_MODE_IGNORE)
		var alt := cache[src] as Mesh
		if alt == null:
			continue
		if c is MultiMeshInstance3D:
			(c as MultiMeshInstance3D).multimesh.mesh = alt
		else:
			(c as MeshInstance3D).mesh = alt
		count += 1
	return count


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
	print("GDT_FPS map=%s gfx=%s trees=%s view=%s avg=%.1f low1=%.1f avg_ms=%.2f gpu_ms=%.2f draws=%d prims=%d" % [
		map_id, gfx, "before" if trees_src != "" else "after", view, 1000.0 / avg_ms, 1000.0 / worst, avg_ms, gpu_ms,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])


func _place(at: Vector3, zoom: float) -> void:
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	# Dev tool only (same as gd_props_shots.gd): writes the camera's own zoom fields. Game code never does this.
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


## The tree (EnvProps MultiMesh instance) with the most trees within 8 m, among those `d0`-`d1` m from the keep
## and 8 m inside the map.
func _forest_spot(keep: Vector3, d0: float, d1: float) -> Vector3:
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
	var half := 1e9
	var mi: Variant = load("res://scripts/core/map_info.gd")
	if mi is Script:
		half = float((mi as Script).call(&"half_max")) - 8.0
	for p in pts:
		if absf(p.x) > half or absf(p.z) > half:
			continue
		var dk := Vector2(p.x - keep.x, p.z - keep.z).length()
		if dk < d0 or dk > d1:
			continue
		var n := 0
		for q in pts:
			if p.distance_squared_to(q) < 64.0:
				n += 1
		if n > bn:
			bn = n
			best = p
	return best
