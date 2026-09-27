extends SceneTree
## Bakes the Nature buildings' meshes (task A2.6) to art/buildings/nature/baked/*.res, so the game loads them instead
## of building them in GDScript the first time a Grove Hall, Seed Hollow or Bramble Spire appears. Run it WINDOWED
## (headless may drop mesh data when saving) after ANY change to the geometry code of nature_hall.gd,
## nature_hollow.gd, nature_spire.gd or nature/nature_kit.gd (tests/test_a2_6.gd fails on a stale bake):
##   Godot --path . -s art/buildings/nature/nature_bake.gd --fixed-fps 60 --quit-after 120

const SCENES: Array[String] = ["res://art/buildings/nature_hall.tscn", "res://art/buildings/nature_hollow.tscn",
	"res://art/buildings/nature_spire.tscn"]

var _frame: int = 0
var _models: Array[Node] = []


func _initialize() -> void:
	NatureKit.force_build = true
	NatureKit.clear_cache()
	for s: String in SCENES:
		var m: Node = (load(s) as PackedScene).instantiate()
		root.add_child(m)
		_models.append(m)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var dir: String = ProjectSettings.globalize_path(NatureKit.BAKED_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var total: int = 0
	var bytes: int = 0
	for key: String in NatureKit.cached_keys():
		var mesh: ArrayMesh = NatureKit.cached_mesh(key)
		var path: String = NatureKit.baked_path(key)
		var err: int = ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
		var verts: int = 0
		for s: int in mesh.get_surface_count():
			verts += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var size: int = FileAccess.open(path, FileAccess.READ).get_length() if err == OK else 0
		print("baked %s surfaces=%d verts=%d bytes=%d err=%d" % [path, mesh.get_surface_count(), verts, size, err])
		total += 1
		bytes += size
	print("nature_bake: %d meshes, %d KB" % [total, bytes / 1024])
	for m: Node in _models:
		m.queue_free()
	return true
