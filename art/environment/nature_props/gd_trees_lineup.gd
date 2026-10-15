extends SceneTree
## G-D trees lineup (docs/art/gd_trees.md): the tree / bush meshes on the painted ground under the lighting rig, from
## the game camera. Windowed only:
##   & tools\godot_run.ps1 --path . -s res://art/environment/nature_props/gd_trees_lineup.gd --quit-after 6000 `
##       '--' --gfx=high --tag=after [--trees=<absolute folder of the old meshes>] [--only=a,b] [--autumn]
## --autumn: AutumnSwap (art/environment/autumn/autumn_swap.gd) on the shared materials, the ground and the rig first.
## Shots (docs/art/lab/gd_trees/lineup_<tag>_<gfx>_<shot>.png): pines / firs (3 variants each), broadleaf, birch /
## gold, bushes at zoom 12-14, and a mixed grove (the map's pine / broadleaf / fir pick, 70 trees, scale 0.85-1.3)
## at zoom 30 and 14.

const MESH_DIR := "res://art/environment/meshes/"
const OUT := "res://docs/art/lab/gd_trees/"
const TREES: Array[String] = ["tree_pine", "tree_fir", "tree_broadleaf", "tree_birch", "tree_gold"]
const MAP_TREES: Array[String] = ["tree_pine", "tree_broadleaf", "tree_fir"]

var args := {}
var _rig: Node3D
var _src := ""
var _cache := {}


func _initialize() -> void:
	_run.call_deferred()


func _mesh(name: String) -> Mesh:
	if _cache.has(name):
		return _cache[name]
	var m: Mesh = null
	if _src != "" and FileAccess.file_exists(_src.path_join(name + ".res")):
		m = ResourceLoader.load(_src.path_join(name + ".res"), "", ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	else:
		m = load(MESH_DIR + name + ".res") as Mesh
	_cache[name] = m
	return m


static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func _variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 1.2) - 0.6, 0.0, fmod(i * 0.311, 1.2) - 0.6)
		if _variant_at(p) == variant:
			return p
	return pos


func _add(stage: Node3D, name: String, xfs: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh(name)
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	stage.add_child(mmi)


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	_src = String(args.get("trees", ""))
	var tag := String(args.get("tag", "shot"))
	var gfx := String(args.get("gfx", "high"))
	if DisplayServer.get_name() == "headless":
		print("GDT_LINEUP ERROR: needs a window")
		quit(2)
		return
	var size := Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(size)
	root.content_scale_size = size
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	var light: Node3D = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	stage.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm: Material = load("res://art/environment/ground_material.tres")
	if gm is ShaderMaterial:
		gm = (gm as ShaderMaterial).duplicate()
		(gm as ShaderMaterial).set_shader_parameter(&"lane_a", Vector2(500, 500))
		(gm as ShaderMaterial).set_shader_parameter(&"lane_b", Vector2(501, 501))
		for i in 4:
			(gm as ShaderMaterial).set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	ground.material_override = gm
	stage.add_child(ground)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	stage.add_child(_rig)
	# Species rows at z = -6: one group per mesh (x = (k - 2) * 13), its 3 variants side by side.
	for k in TREES.size():
		var xfs: Array[Transform3D] = []
		for i in 3:
			var pos := _find_variant(Vector3((k - 2) * 13.0 + (i - 1) * 4.2, 0.0, -6.0), i)
			xfs.append(Transform3D(Basis(Vector3.UP, 0.3 + i * 1.9), pos))
		_add(stage, TREES[k], xfs)
	# Bushes at z = 4.
	for k in 2:
		var bx: Array[Transform3D] = []
		for i in 4:
			var bp := Vector3(-3.0 + k * 6.0 + (i % 2) * 1.6, 0.0, 3.5 + (i / 2) * 1.5)
			bx.append(Transform3D(Basis(Vector3.UP, i * 1.3).scaled(Vector3.ONE * (0.8 + 0.15 * i)), bp))
		_add(stage, ["decor_bush", "decor_bush_berry"][k], bx)
	# A mixed grove at z = 40 (the map's pick: hash -> pine / broadleaf / fir, scale 0.85-1.3, >= 2.2 m apart).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var per := {}
	var spots: Array[Vector3] = []
	var tries := 0
	while spots.size() < 70 and tries < 4000:
		tries += 1
		var p := Vector3(rng.randf_range(-16.0, 16.0), 0.0, 40.0 + rng.randf_range(-11.0, 11.0))
		var ok := true
		for q in spots:
			if p.distance_to(q) < 2.2:
				ok = false
				break
		if not ok:
			continue
		spots.append(p)
		var h := fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0)
		var name: String = MAP_TREES[int(h * 997.0) % MAP_TREES.size()]
		if not per.has(name):
			per[name] = [] as Array[Transform3D]
		var s := rng.randf_range(0.85, 1.3)
		(per[name] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(s, s, s)), p))
	for name: String in per:
		_add(stage, name, per[name])
	if args.has("autumn"):
		var sw: GDScript = load("res://art/environment/autumn/autumn_swap.gd")
		sw.call(&"swap_shared_materials")
		for i in 2:
			await process_frame
		sw.call(&"apply_ground", stage)
		sw.call(&"apply_lighting", stage)
		tag += "_autumn"
	for i in 8:
		await process_frame
	var shots: Array = [
		["pine_fir", 14.0, Vector3(-19.5, 0, -6.0)],
		["broadleaf", 12.0, Vector3(0, 0, -6.0)],
		["birch_gold", 14.0, Vector3(19.5, 0, -6.0)],
		["bushes", 8.0, Vector3(0, 0, 4.5)],
		["grove30", 30.0, Vector3(0, 0, 40.0)],
		["grove14", 14.0, Vector3(-4.0, 0, 40.0)],
	]
	var only: PackedStringArray = String(args.get("only", "")).split(",", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for s: Array in shots:
		if not only.is_empty() and not only.has(String(s[0])):
			continue
		_rig.set(&"_target_zoom", s[1])
		_rig.set(&"_zoom", s[1])
		_rig.call(&"focus_on", s[2])
		_rig.call(&"_apply_zoom")
		for i in 30:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var path := OUT + "lineup_%s_%s_%s.png" % [tag, gfx, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("GDT_LINEUP %s" % path)
	print("GDT_LINEUP done")
	quit(0)
