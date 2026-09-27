extends SceneTree
## Bakes the Grove Bazaar's meshes (task 10.V4) to art/buildings/market/nature/baked/*.res, so the game loads them
## instead of building them in GDScript the first time a Grove Bazaar appears. Run it WINDOWED (headless may drop
## mesh data when saving) after ANY change to the geometry code of market_nature.gd (or of nature/nature_kit.gd);
## tests/test_10_v4.gd fails on a stale bake:
##   Godot --path . -s art/buildings/market/nature/market_nature_bake.gd --fixed-fps 60 --quit-after 120

const SCENE := "res://art/buildings/market/nature/market_nature.tscn"

var _frame: int = 0
var _model: Node


func _initialize() -> void:
	NatureMarketModel.force_build = true
	NatureMarketModel.clear_cache()
	_model = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_model)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var dir: String = ProjectSettings.globalize_path(NatureMarketModel.BAKED_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var total: int = 0
	var bytes: int = 0
	for key: String in NatureMarketModel.cached_keys():
		var mesh: ArrayMesh = NatureMarketModel.cached_mesh(key)
		var path: String = NatureMarketModel.baked_path(key)
		var err: int = ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
		var verts: int = 0
		for s: int in mesh.get_surface_count():
			verts += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var size: int = FileAccess.open(path, FileAccess.READ).get_length() if err == OK else 0
		print("baked %s surfaces=%d verts=%d bytes=%d err=%d" % [path, mesh.get_surface_count(), verts, size, err])
		total += 1
		bytes += size
	print("market_nature_bake: %d meshes, %d KB" % [total, bytes / 1024])
	_model.queue_free()
	return true
