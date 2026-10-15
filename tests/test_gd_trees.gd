extends SceneTree
## G-D trees (docs/art/gd_trees.md): the rebuilt tree / bush meshes keep their contract and their vertex budget.
## - every tree mesh (art/environment/meshes/tree_*.res + _v0.._v2 + _far) exists, uses the shared nature material
##   (+ the contact material), and its vertex count (what one MultiMesh instance runs through the vertex shader:
##   the combined mesh carries all 3 variants) stays <= MAX_VERT_RATIO x the count before G-D trees (BEFORE);
## - the tree scenes stay mesh-only (no physics body, collision shape, light or script): the map's own colliders
##   (radius 0.45 s, height 2) and the navmesh are untouched;
## - the decor bushes (rebuilt by build_nature.gd on the shared nature material, before: env_painted) stay inside the
##   same ratio;
## - nature_painted.gdshader keeps `gd_detail` = 0 by default and the crown sway sits behind it.
## `-- --report` only prints the counts (no verdict), for the before / after table.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gd_trees.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "gd_trees"
const MESH_DIR := "res://art/environment/meshes/"
const DIR := "res://art/environment/"
const MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const SHADER := "res://art/environment/nature_props/nature_painted.gdshader"
const MAX_VERT_RATIO := 2.0
## Welded vertices of surface 0 before G-D trees (2026-10-15, A2.8 meshes).
const BEFORE := {
	"tree_pine": 706, "tree_pine_v0": 270, "tree_pine_v1": 296, "tree_pine_v2": 244,
	"tree_fir": 782, "tree_fir_v0": 290, "tree_fir_v1": 306, "tree_fir_v2": 290,
	"tree_broadleaf": 726, "tree_broadleaf_v0": 294, "tree_broadleaf_v1": 254, "tree_broadleaf_v2": 258,
	"tree_birch": 484, "tree_birch_v0": 170, "tree_birch_v1": 174, "tree_birch_v2": 140,
	"tree_gold": 564, "tree_gold_v0": 254, "tree_gold_v1": 204, "tree_gold_v2": 186,
	"tree_pine_far": 86, "tree_fir_far": 112, "tree_broadleaf_far": 68, "tree_birch_far": 68, "tree_gold_far": 68,
	"decor_bush": 540, "decor_bush_berry": 864,
}
## Bushes are map-wide decor that casts shadows: triangles also <= 2x (before G-D trees), and they must sink into the
## ground (map_dressing_art.gd places them at y 0 with no contact disc).
const BUSH_TRIS_BEFORE := {"decor_bush": 180, "decor_bush_berry": 288}
const BUSH_MAX_Y_BOTTOM := -0.03
const TREES: Array[String] = ["tree_pine", "tree_fir", "tree_broadleaf", "tree_birch", "tree_gold"]
const FAR: Array[String] = ["tree_pine_far", "tree_fir_far", "tree_broadleaf_far", "tree_birch_far", "tree_gold_far"]
const BUSHES: Array[String] = ["decor_bush", "decor_bush_berry"]

var _fails: Array[String] = []
var _report := false


func _initialize() -> void:
	_report = OS.get_cmdline_user_args().has("--report")
	var mat := load(MAT) as Material
	var cmat := load(CONTACT_MAT) as Material
	for name: String in TREES:
		_check_mesh(name, mat, cmat)
		for k in 3:
			_check_mesh("%s_v%d" % [name, k], mat, cmat)
		_check_scene(name)
	for name: String in FAR:
		_check_mesh(name, mat, null)
	for name: String in BUSHES:
		_check_mesh(name, mat, null)
		_check_bush(name)
	var code := (load(SHADER) as Shader).code
	_check(code.contains("uniform float gd_detail = 0.0;"), "nature_painted: gd_detail must default to 0")
	# The crown rustle (vertex work) only runs at Medium+: its comment sits right under the gd_detail branch.
	var at := code.find("(Medium+): crown rustle")
	_check(at > 0 and code.substr(maxi(at - 120, 0), 120).contains("if (gd_detail > 0.5)"),
			"nature_painted: the crown rustle must sit behind `if (gd_detail > 0.5)`")
	if _report:
		print("REPORT done")
	elif _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


static func _counts(mesh: Mesh) -> Vector2i:
	var arr := mesh.surface_get_arrays(0)
	var v := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var t := idx.size() / 3 if idx.size() > 0 else v / 3
	return Vector2i(v, t)


func _check_mesh(name: String, mat: Material, cmat: Material) -> void:
	var path := MESH_DIR + name + ".res"
	if not ResourceLoader.exists(path):
		_check(false, "%s missing" % path)
		return
	var mesh := load(path) as Mesh
	var c := _counts(mesh)
	print("MESH %-22s verts %5d tris %5d" % [name, c.x, c.y])
	if _report:
		return
	_check(mesh.surface_get_material(0) == mat, "%s: surface 0 is not on its shared material" % name)
	if cmat != null:
		_check(mesh.get_surface_count() == 2 and mesh.surface_get_material(1) == cmat,
				"%s: surface 1 must be the shared contact disc" % name)
	if BEFORE.has(name):
		var limit := int(float(BEFORE[name]) * MAX_VERT_RATIO)
		_check(c.x <= limit, "%s: %d vertices > %d (%.1fx the %d before)" % [name, c.x, limit, MAX_VERT_RATIO,
				BEFORE[name]])


func _check_scene(name: String) -> void:
	var ps := load(DIR + name + ".tscn") as PackedScene
	if ps == null:
		_check(false, "%s.tscn missing" % name)
		return
	var inst := ps.instantiate()
	for n: Node in [inst] + inst.find_children("*", "", true, false):
		_check(not (n is CollisionObject3D or n is CollisionShape3D), "%s: has a physics node %s" % [name, n.name])
		_check(not (n is Light3D), "%s: has a light" % name)
		_check(n.get_script() == null, "%s: node %s has a script" % [name, n.name])
	var mi := inst.get_node_or_null(^"Mesh") as MeshInstance3D
	_check(mi != null and mi.mesh != null and mi.mesh.resource_path == MESH_DIR + name + ".res",
			"%s: Mesh child must point at %s.res" % [name, name])
	inst.free()


func _check_bush(name: String) -> void:
	var path := MESH_DIR + name + ".res"
	if not ResourceLoader.exists(path):
		return
	var mesh := load(path) as Mesh
	var c := _counts(mesh)
	var lo := INF
	for p: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
		lo = minf(lo, p.y)
	print("BUSH %-18s tris %4d (cap %d), bottom y %.3f" % [name, c.y, int(BUSH_TRIS_BEFORE[name] * MAX_VERT_RATIO), lo])
	if _report:
		return
	_check(c.y <= int(BUSH_TRIS_BEFORE[name] * MAX_VERT_RATIO), "%s: %d triangles > 2x the %d before" % [name, c.y,
			BUSH_TRIS_BEFORE[name]])
	_check(lo <= BUSH_MAX_Y_BOTTOM, "%s: floats (bottom y %.3f > %.2f)" % [name, lo, BUSH_MAX_Y_BOTTOM])
