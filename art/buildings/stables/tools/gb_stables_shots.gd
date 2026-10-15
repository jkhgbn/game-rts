extends SceneTree
## Task G-B neutral: before / after shots of the Shadow and Nature Stables (they draw with the shared
## stables_painted.gdshader). Same Crown Hollow scene, one run: the after shot, then every material on the shared
## shader swapped to the pre-G-B copy (stables_painted_legacy.gdshader, tool only) for the before shot.
## Windowed only:
##   tools\godot_run.ps1 --path . -s res://art/buildings/stables/tools/gb_stables_shots.gd --resolution 1920x1080
##       --quit-after 30000 -- --gfx=high
## Saves docs/art/lab/gb_neutral/shots/stables_<kingdom>_<before|after>_q<q>.png.

const OUT_DIR := "res://docs/art/lab/gb_neutral/shots"
const SHARED: Shader = preload("res://art/buildings/stables/stables_painted.gdshader")
const LEGACY: Shader = preload("res://art/buildings/stables/tools/stables_painted_legacy.gdshader")
const KINDS: Array[String] = ["shadow", "nature"]

var main: Node
var _cam: Node3D
var _stables: Dictionary = {}


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
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
	paused = false
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	_cam = main.get(&"camera_rig")
	_cam.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var q: int = GameSettings.effective_graphics_quality()
	GameSettings.apply_graphics(self, q)
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 0:
			keep = b as Node3D
	var grid: Node = main.get(&"build_grid")
	var kp: Vector3 = keep.global_position
	var toward: Vector3 = (Vector3.ZERO - kp)
	toward.y = 0.0
	toward = toward.normalized()
	var side: Vector3 = Vector3.UP.cross(toward).normalized()
	var i := 0
	for k: String in KINDS:
		var ty: BuildingType = load("res://data/buildings/%s_stables.tres" % k) as BuildingType
		var want: Vector3 = kp + side * (-16.0 + 32.0 * i) + toward * 4.0
		var spot: Vector3 = grid.call(&"find_spot", ty, want, 0, 6)
		if spot == Vector3.INF or not spot.is_finite():
			spot = want
		_stables[k] = grid.call(&"spawn_complete", ty, spot, 0)
		i += 1
	for f in 60:
		await process_frame
	for tag: String in ["after", "before"]:
		if tag == "before":
			var n := _swap_to_legacy()
			print("GBS swapped %d material(s) to the legacy shader" % n)
		for k: String in KINDS:
			_cam.call(&"fly_to", (_stables[k] as Node3D).global_position, 0.0, 14.0, 0.0)
			for f in 50:
				await process_frame
			await RenderingServer.frame_post_draw
			var path := "%s/stables_%s_%s_q%d.png" % [OUT_DIR, k, tag, q]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print("saved %s" % path)
	print("GBS DONE")
	quit()


func _swap_to_legacy() -> int:
	var n := 0
	for k: String in KINDS:
		for gi: Node in (_stables[k] as Node).find_children("*", "GeometryInstance3D", true, false):
			var g := gi as GeometryInstance3D
			var mats: Array = [g.material_override]
			if g is MeshInstance3D and (g as MeshInstance3D).mesh:
				var mi := g as MeshInstance3D
				for s: int in mi.mesh.get_surface_count():
					mats.append(mi.get_surface_override_material(s))
					mats.append(mi.mesh.surface_get_material(s))
			for m: Variant in mats:
				var sm := m as ShaderMaterial
				if sm and sm.shader == SHARED:
					sm.shader = LEGACY
					n += 1
	return n
