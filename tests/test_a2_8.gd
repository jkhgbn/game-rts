extends SceneTree
## Task A2.8 (trees + rocks second pass): every nature prop scene instantiates, has no light and no script,
## uses the ONE shared painted material (+ the shared contact-shadow material), stays inside its triangle budget
## (whole mesh and per shape variant), touches the ground, and the border forest is lighter than before A2.8.
## Run:  godot --headless --path . -s tests/test_a2_8.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "a2.8"
const DIR := "res://art/environment/"
const MESH_DIR := "res://art/environment/meshes/"
const MAT_PATH := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT_PATH := "res://art/environment/nature_props/nature_contact_mat.tres"
## name -> [max triangles in the mesh (all 3 variants), max triangles one instance draws (one variant)]
const PROPS := {
	"tree_pine": [1100, 420], "tree_fir": [1100, 420], "tree_broadleaf": [1300, 500], "tree_birch": [1000, 360],
	"tree_gold": [1100, 450], "rock_boulder": [700, 260], "rock_slab": [700, 280], "rock_shards": [450, 160],
	"rock_spire": [450, 160], "ruin_pillar": [1200, 560],
}
const FAR := ["tree_pine_far", "tree_fir_far", "tree_broadleaf_far", "tree_birch_far", "tree_gold_far"]
const FAR_BUDGET := 130
const CONTACT_BUDGET := 48            ## triangles of the contact-shadow disc(s)
const BORDER_BUDGET := 100000         ## border forest triangles (136 k before A2.8)
## What EnvProps (scripts/world/env_props.gd) loads today.
const ENV_PROPS_MESHES := ["tree_pine", "tree_broadleaf", "tree_fir", "rock_boulder", "rock_slab", "rock_shards",
	"ruin_pillar"]

var _fails: PackedStringArray = []


func _initialize() -> void:
	var mat: Material = load(MAT_PATH) as Material
	var cmat: Material = load(CONTACT_MAT_PATH) as Material
	if mat == null or cmat == null:
		_fail("shared materials missing")
	for name: String in PROPS:
		_check_scene(name, mat, cmat)
	for name2: String in FAR:
		_check_far(name2, mat)
	for name3: String in ENV_PROPS_MESHES:
		if not ResourceLoader.exists(MESH_DIR + name3 + ".res"):
			_fail("EnvProps mesh missing: %s" % name3)
	_check_border()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	quit()


func _fail(msg: String) -> void:
	_fails.append(msg)


## Triangles of a surface (indexed or not).
static func _tri_count(arr: Array) -> int:
	if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
		return (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


## Triangles per variant k (UV2.x = variant mask: 0 / -1 = every variant, else bit k).
static func _variant_tris(arr: Array, k: int) -> int:
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var n := 0
	var count: int = idx.size() if idx.size() > 0 else uv2.size()
	for t in range(0, count, 3):
		var m := int(uv2[idx[t] if idx.size() > 0 else t].x)
		if m <= 0 or ((m >> k) & 1) == 1:
			n += 1
	return n


## Lowest vertex of variant k (the prop must reach the ground: no floating).
static func _variant_min_y(arr: Array, k: int) -> float:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var lo := INF
	for i in v.size():
		var m := int(uv2[i].x)
		if m <= 0 or ((m >> k) & 1) == 1:
			lo = minf(lo, v[i].y)
	return lo


func _check_scene(name: String, mat: Material, cmat: Material) -> void:
	var path := DIR + name + ".tscn"
	if not ResourceLoader.exists(path):
		_fail("%s: scene missing" % name)
		return
	var inst: Node = (load(path) as PackedScene).instantiate()
	if inst == null or not inst is Node3D:
		_fail("%s: does not instantiate as a Node3D" % name)
		return
	if not inst.find_children("*", "Light3D", true, false).is_empty():
		_fail("%s: has a light" % name)
	for n: Node in [inst] + inst.find_children("*", "", true, false):
		if n.get_script() != null:
			_fail("%s: node %s has a script (props must stay script-free)" % [name, n.name])
	var mi := inst.get_node_or_null(^"Mesh") as MeshInstance3D
	if mi == null or mi.mesh == null:
		_fail("%s: no Mesh child" % name)
		inst.free()
		return
	var mesh: Mesh = mi.mesh
	if mesh.resource_path != MESH_DIR + name + ".res":
		_fail("%s: scene mesh is not %s" % [name, MESH_DIR + name + ".res"])
	if mesh.get_surface_count() != 2:
		_fail("%s: expected 2 surfaces (prop + contact shadow), got %d" % [name, mesh.get_surface_count()])
	elif mesh.surface_get_material(0) != mat or mesh.surface_get_material(1) != cmat:
		_fail("%s: surfaces must use the shared nature / contact materials" % name)
	var arr: Array = mesh.surface_get_arrays(0)
	var total: int = _tri_count(arr)
	var budget: Array = PROPS[name]
	if total > int(budget[0]):
		_fail("%s: %d triangles > %d" % [name, total, budget[0]])
	for k in 3:
		var vt := _variant_tris(arr, k)
		if vt > int(budget[1]):
			_fail("%s: variant %d draws %d triangles > %d" % [name, k, vt, budget[1]])
		if vt < 20:
			_fail("%s: variant %d is empty" % [name, k])
		var lo := _variant_min_y(arr, k)
		if lo > 0.0 or lo < -0.45:
			_fail("%s: variant %d bottom at y %.2f (must sink 0..0.45 m into the ground)" % [name, k, lo])
		# The single-variant mesh (for placement code that picks the variant itself) matches.
		var vpath := MESH_DIR + "%s_v%d.res" % [name, k]
		var vm := load(vpath) as Mesh if ResourceLoader.exists(vpath) else null
		if vm == null:
			_fail("%s: %s missing" % [name, vpath])
		elif _tri_count(vm.surface_get_arrays(0)) != vt:
			_fail("%s: %s triangle count differs from variant %d" % [name, vpath, k])
	if mesh.get_surface_count() > 1:
		var carr: Array = mesh.surface_get_arrays(1)
		if _tri_count(carr) > CONTACT_BUDGET:
			_fail("%s: contact disc over budget" % name)
	print("%-16s %4d tris, per variant %d / %d / %d" % [name, total, _variant_tris(arr, 0), _variant_tris(arr, 1),
			_variant_tris(arr, 2)])
	inst.free()


func _check_far(name: String, mat: Material) -> void:
	var mesh := load(MESH_DIR + name + ".res") as Mesh if ResourceLoader.exists(MESH_DIR + name + ".res") else null
	if mesh == null:
		_fail("%s: missing" % name)
		return
	if mesh.surface_get_material(0) != mat:
		_fail("%s: not on the shared material" % name)
	var arr: Array = mesh.surface_get_arrays(0)
	var tris: int = _tri_count(arr)
	if tris > FAR_BUDGET:
		_fail("%s: %d triangles > %d" % [name, tris, FAR_BUDGET])
	var lo := _variant_min_y(arr, 0)
	if lo > 0.0:
		_fail("%s: floats (bottom y %.2f)" % [name, lo])
	print("%-18s %4d tris" % [name, tris])


## map_dressing.tscn border forest: every set's mesh exists, total triangles under budget.
func _check_border() -> void:
	var ps := load(DIR + "map_dressing.tscn") as PackedScene
	if ps == null:
		_fail("map_dressing.tscn missing")
		return
	var root: Node = ps.instantiate()   # not added to the tree: its _ready (building the MultiMeshes) doesn't run
	var sets: Array = root.get(&"border_sets")
	var total := 0
	var count := 0
	for s: Array in sets:
		var mpath := MESH_DIR + String(s[0]) + ".res"
		if not ResourceLoader.exists(mpath):
			_fail("border set mesh missing: %s" % s[0])
			continue
		var mesh := load(mpath) as Mesh
		var n := int((s[2] as PackedFloat32Array).size() / 12.0)
		var tris := 0
		for si in mesh.get_surface_count():
			tris += _tri_count(mesh.surface_get_arrays(si))
		total += n * tris
		count += n
	root.free()
	print("border forest + crest rocks: %d instances, %d triangles" % [count, total])
	if total > BORDER_BUDGET:
		_fail("border forest %d triangles > %d" % [total, BORDER_BUDGET])
