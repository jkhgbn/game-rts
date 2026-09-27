extends SceneTree
## Task 12.V7 (Riverbank biome set): meshes load, shared nature materials, indexed, triangle budgets per variant,
## wind data, willow footprint, the set file's ENTRIES, and headless instantiation (MultiMesh) without errors.
## Run:  godot --headless --path . -s tests/test_12_v7.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "12.v7"
const RB := "res://art/environment/biomes/riverbank/"
const MESHES := "res://art/environment/meshes/"
const SET_PATH := "res://art/environment/biomes/riverbank/riverbank_set.gd"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const KIND_LEAVES := 2
const KIND_STONE := 3
const KIND_BARK := 0

## [path, max triangles per variant (what one instance rasterises), needs wind, variants (3 = masked, 1 = none)]
const BUDGETS := [
	[RB + "rb_reeds.res", 160, true, 3],
	[RB + "rb_cattails.res", 190, true, 3],
	[RB + "rb_lily_pads.res", 120, true, 3],
	[RB + "rb_river_stones.res", 160, false, 3],
	[RB + "rb_driftwood.res", 120, false, 3],
	[MESHES + "tree_willow.res", 620, true, 3],
	[MESHES + "tree_willow_v0.res", 620, true, 1],
	[MESHES + "tree_willow_v1.res", 620, true, 1],
	[MESHES + "tree_willow_v2.res", 620, true, 1],
	[MESHES + "tree_willow_far.res", 160, true, 1],
]

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	for b: Array in BUDGETS:
		_check_mesh(b[0], b[1], b[2], b[3])
	_check_willow_footprint()
	_check_set()
	_stage = Node3D.new()
	root.add_child(_stage)
	for b2: Array in BUDGETS:
		var mesh := load(b2[0]) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 4
		for i in 4:
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, i * 1.3), Vector3(i * 3.1, 0, i * 1.7)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		_stage.add_child(mmi)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - ", f)
		print("FAIL %s: %d check(s) failed" % [TASK_ID, _fails.size()])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check_mesh(path: String, budget: int, needs_wind: bool, variants: int) -> void:
	if not ResourceLoader.exists(path):
		_fail("missing %s" % path)
		return
	var mesh := load(path) as ArrayMesh
	if mesh == null or mesh.get_surface_count() < 1:
		_fail("%s is not an ArrayMesh with surfaces" % path)
		return
	var m0: Material = mesh.surface_get_material(0)
	if m0 == null or m0.resource_path != NATURE_MAT:
		_fail("%s surface 0 does not use the shared nature_mat.tres (%s)" % [path, m0.resource_path if m0 else "null"])
	if mesh.get_surface_count() > 1:
		var m1: Material = mesh.surface_get_material(1)
		if m1 == null or m1.resource_path != CONTACT_MAT:
			_fail("%s surface 1 does not use nature_contact_mat.tres" % path)
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if idx == null or (idx as PackedInt32Array).is_empty():
			_fail("%s surface %d is not indexed" % [path, s])
		elif (idx as PackedInt32Array).size() <= nv:
			_fail("%s surface %d is not welded (%d indices, %d vertices)" % [path, s, (idx as PackedInt32Array).size(), nv])
	var a0: Array = mesh.surface_get_arrays(0)
	var ids: PackedInt32Array = a0[Mesh.ARRAY_INDEX]
	var uv: PackedVector2Array = a0[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = a0[Mesh.ARRAY_TEX_UV2]
	var cols: PackedColorArray = a0[Mesh.ARRAY_COLOR]
	if uv.is_empty() or uv2.is_empty() or cols.is_empty():
		_fail("%s lacks the nature shader data (COLOR, UV, UV2)" % path)
		return
	var per := [0, 0, 0]
	var masked := false
	var max_wind := 0.0
	var leaves := 0
	for t in range(0, ids.size(), 3):
		var m: int = int(uv2[ids[t]].x)
		if m > 0:
			masked = true
		for k in 3:
			if m <= 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	for i in uv.size():
		if int(uv2[i].y) != KIND_STONE:
			max_wind = maxf(max_wind, uv[i].x)
		if int(uv2[i].y) == KIND_LEAVES:
			leaves += 1
	var worst: int = per.max()
	if worst > budget:
		_fail("%s: %d triangles per variant (budget %d): %s" % [path.get_file(), worst, budget, str(per)])
	if variants == 3 and not masked:
		_fail("%s has no variant mask (3 shapes expected)" % path.get_file())
	if variants == 3 and (per[0] == per[1] and per[1] == per[2]):
		_fail("%s: the 3 variants have identical triangle counts (not really different?)" % path.get_file())
	if needs_wind and max_wind <= 0.1:
		_fail("%s: no wind weight in UV.x" % path.get_file())
	if not needs_wind and max_wind > 0.0:
		_fail("%s: rigid prop has a wind weight" % path.get_file())
	if leaves > 0:
		_fail("%s: %d vertices of kind LEAVES (random autumn tint); riverbank foliage uses IVY" % [path.get_file(), leaves])
	print("mesh %-24s tris per variant %s (budget %d), max wind %.2f" % [path.get_file(), str(per), budget, max_wind])


## Trunk foot on the tree collider footprint (r 0.45 s): the trunk's buried base ring (bark below y -0.13; the root
## tips end above y -0.12) lies within 0.55 m of the origin in every variant.
func _check_willow_footprint() -> void:
	var mesh := load(MESHES + "tree_willow.res") as ArrayMesh
	if mesh == null:
		return
	var a: Array = mesh.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var uv2: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var worst := 0.0
	var top := 0.0
	var hem := INF
	for i in v.size():
		if int(uv2[i].y) == KIND_BARK and v[i].y < -0.13:
			worst = maxf(worst, Vector2(v[i].x, v[i].z).length())
		top = maxf(top, v[i].y)
	for i2 in v.size():
		if int(uv2[i2].y) != KIND_BARK and int(uv2[i2].y) != KIND_STONE:
			hem = minf(hem, v[i2].y)
	if worst > 0.55 or worst < 0.2:
		_fail("willow trunk foot reaches %.2f m from its axis (collider r 0.45)" % worst)
	if top < 4.5 or top > 6.0:
		_fail("willow height %.2f m (expected 4.5-6 like the other trees)" % top)
	if hem < 0.3:
		_fail("willow curtain hangs down to %.2f m (keep >= 0.3 m over the ground)" % hem)
	print("willow: trunk foot %.2f m, height %.2f m, curtain hem %.2f m" % [worst, top, hem])


func _check_set() -> void:
	if not ResourceLoader.exists(SET_PATH):
		_fail("missing %s" % SET_PATH)
		return
	var script := load(SET_PATH) as GDScript
	var c: Dictionary = script.get_script_constant_map()
	if c.get("BIOME_ID") != &"riverbank":
		_fail("BIOME_ID is %s" % str(c.get("BIOME_ID")))
	if not (c.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	var entries: Array = c.get("ENTRIES", [])
	if entries.is_empty():
		_fail("ENTRIES is empty")
	var total := 0.0
	var kinds := {}
	for e: Dictionary in entries:
		for key: String in ["mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not e.has(key):
				_fail("entry %s lacks '%s'" % [str(e.get("mesh", "?")), key])
		var mesh_path: String = e.get("mesh", "")
		if not ResourceLoader.exists(mesh_path) or not (load(mesh_path) is Mesh):
			_fail("entry mesh does not load: %s" % mesh_path)
		kinds[mesh_path] = true
		var place: StringName = e.get("place", &"")
		if not place in [&"land", &"bank", &"water", &"under_trees", &"edge"]:
			_fail("entry %s has place %s" % [mesh_path.get_file(), place])
		if place == &"water" and absf(float(e.get("y", 0.0)) - (-0.35)) > 0.001:
			_fail("water entry %s must sit at y -0.35 (the water surface)" % mesh_path.get_file())
		var r: float = e.get("range", 0.0)
		if r < 60.0 or r > 95.0:
			_fail("entry %s range %.0f (spec: 65 / 90)" % [mesh_path.get_file(), r])
		if bool(e.get("shadow", false)) and not mesh_path.ends_with("rb_driftwood.res"):
			_fail("entry %s casts shadows (only logs / big rocks / trees may)" % mesh_path.get_file())
		# Zone areas on Crown Hollow (riverbank_set.gd header): bank ~820, land ~2000, water within `shore` of the
		# edge ~315 m of bank line x shore (max ~650).
		var area := 0.0
		match place:
			&"bank":
				area = 820.0
			&"land":
				area = 2000.0
			&"water":
				area = minf(650.0, 315.0 * float(e.get("shore", 2.5)))
		total += float(e.get("per_100m2", 0.0)) * area / 100.0
	var budget: int = c.get("INSTANCE_BUDGET", 1800)
	if total > budget:
		_fail("expected riverbank instances %.0f > budget %d" % [total, budget])
	if kinds.size() > 5:
		_fail("%d decor mesh kinds (keep the map total <= 24)" % kinds.size())
	var w: Dictionary = c.get("WILLOW", {})
	if not ResourceLoader.exists(String(w.get("mesh", ""))) or not ResourceLoader.exists(String(w.get("far", ""))):
		_fail("WILLOW mesh paths do not exist")
	if absf(float(w.get("collider_radius", 0.0)) - 0.45) > 0.001:
		_fail("WILLOW collider radius must be 0.45 (x s) like the other trees")
	print("set: %d entries, %d mesh kinds, ~%.0f instances expected on Crown Hollow (budget %d)" % [entries.size(),
		kinds.size(), total, budget])
