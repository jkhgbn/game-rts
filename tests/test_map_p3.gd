extends SceneTree
## Task MAP.P3 (map polish, the horizon): art/environment/horizon/horizon.tscn is a self-contained, cheap backdrop:
## only MeshInstance3D children (one per compass sector, all 8 present), no lights / colliders / particles, no
## shadow casting, GI off, ONE shared saved material (horizon_mat.tres), a triangle budget, every vertex well outside
## the playable 120 x 120 square, nothing above the camera sight line into the map, and it instances cleanly next to a map.
## Run: $GODOT --headless --path . -s tests/test_map_p3.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "MAP.P3"
const SCENE := "res://art/environment/horizon/horizon.tscn"
const MAT := "res://art/environment/horizon/horizon_mat.tres"
const SHADER := "res://art/environment/horizon/horizon.gdshader"
const PLATEAU := "res://art/environment/meshes/map_plateau.res"
const MAP_HALF := 60.0
const MIN_OUTSIDE := 10.0      ## metres: no vertex closer than this to the playable square
## Every game camera (pitch 55, any zoom / yaw) sits on the line y = tan(55 deg) * d from the map edge it looks at, so
## with the camera turned to look back into the map from outside, anything above y = 1.43 * d would hide the map edge.
const SIGHT_SLOPE := 1.43
const MAX_TRIS := 100000
const SECTORS := 8

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_check()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("FAIL %s: %s" % [TASK_ID, f])
	quit()


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check() -> void:
	for path: String in [SCENE, MAT, SHADER]:
		if not ResourceLoader.exists(path):
			_fail("missing %s" % path)
			return
	var mat: Resource = load(MAT)
	if not (mat is ShaderMaterial) or (mat as ShaderMaterial).shader == null:
		_fail("horizon_mat.tres is not a ShaderMaterial with a shader")
		return
	if (mat as ShaderMaterial).shader.resource_path != SHADER:
		_fail("horizon_mat.tres does not use horizon.gdshader")
	var code: String = (mat as ShaderMaterial).shader.code
	for word: String in ["shader_type spatial", "void light()", "COLOR"]:
		if not code.contains(word):
			_fail("shader lacks '%s'" % word)
	var scene := load(SCENE) as PackedScene
	if scene == null:
		_fail("horizon.tscn does not load")
		return
	var node: Node = scene.instantiate()
	if not (node is Node3D):
		_fail("root is not a Node3D")
		node.free()
		return
	var h := node as Node3D
	# Instances cleanly into a tree next to a map (what the lead's glue does).
	var host := Node3D.new()
	host.name = "Map"
	root.add_child(host)
	host.add_child(h)
	if h.transform != Transform3D.IDENTITY:
		_fail("the horizon root must sit at the origin (it is baked in world space)")
	var meshes: int = 0
	var tris: int = 0
	var min_out: float = INF
	var worst_sight: float = -INF
	var mats: Dictionary = {}
	for n: Node in _all(h):
		if n == h:
			continue
		if not (n is MeshInstance3D):
			_fail("unexpected node %s (%s): only MeshInstance3D allowed" % [n.name, n.get_class()])
			continue
		var mi := n as MeshInstance3D
		meshes += 1
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			_fail("%s casts shadows" % mi.name)
		if mi.gi_mode != GeometryInstance3D.GI_MODE_DISABLED:
			_fail("%s has GI on" % mi.name)
		if mi.material_override != null:
			_fail("%s has a material_override (use the mesh surface material)" % mi.name)
		var mesh := mi.mesh as ArrayMesh
		if mesh == null or mesh.get_surface_count() != 1:
			_fail("%s: expected one ArrayMesh surface" % mi.name)
			continue
		if mesh.resource_path == "":
			_fail("%s: mesh is not saved to a file" % mi.name)
		var sm: Material = mesh.surface_get_material(0)
		if sm == null:
			_fail("%s: no surface material" % mi.name)
		else:
			mats[sm.resource_path] = true
		var arr: Array = mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if arr[Mesh.ARRAY_COLOR] == null:
			_fail("%s: no vertex colours" % mi.name)
		tris += idx.size() / 3
		for p: Vector3 in v:
			var w: Vector3 = mi.transform * p
			var off := Vector2(maxf(absf(w.x) - MAP_HALF, 0.0), maxf(absf(w.z) - MAP_HALF, 0.0))
			var d: float = off.length()
			min_out = minf(min_out, d)
			worst_sight = maxf(worst_sight, w.y - SIGHT_SLOPE * d)
	if meshes != SECTORS:
		_fail("expected %d sector meshes, found %d" % [SECTORS, meshes])
	if mats.size() != 1 or not mats.has(MAT):
		_fail("expected the one shared material %s, found %s" % [MAT, str(mats.keys())])
	if tris > MAX_TRIS:
		_fail("%d triangles > budget %d" % [tris, MAX_TRIS])
	if min_out < MIN_OUTSIDE:
		_fail("a vertex is only %.1f m outside the playable square (min %.1f)" % [min_out, MIN_OUTSIDE])
	_check_plateau_fit(h)
	if worst_sight > 0.0:
		_fail("geometry rises %.1f m above the camera sight line (y = %.2f x distance outside)" % [worst_sight, SIGHT_SLOPE])
	print("horizon: %d meshes, %d tris, 1 material, min %.1f m outside, clearance under the sight line %.1f m" % [
		meshes, tris, min_out, -worst_sight])
	host.queue_free()


## The horizon ground is baked against 12.V5's plateau (art/environment/meshes/map_plateau.res, the open ring with
## the river mouths). Near the cliffs it must stay hidden under the plateau and never lid the south gorge hole: if the
## map edge was rebuilt since, re-run horizon_builder.gd.
func _check_plateau_fit(h: Node3D) -> void:
	var plateau := load(PLATEAU) as ArrayMesh
	if plateau == null:
		_fail("missing %s" % PLATEAU)
		return
	var tm: TriangleMesh = plateau.generate_triangle_mesh()
	if tm == null or not tm.has_method(&"intersect_ray"):
		print("plateau fit: TriangleMesh.intersect_ray unavailable, skipped")
		return
	var over_hole: int = 0
	var poking: int = 0
	var checked: int = 0
	for n: Node in h.get_children():
		var mi := n as MeshInstance3D
		if mi == null or not (mi.mesh is ArrayMesh):
			continue
		var arr: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: Variant = arr[Mesh.ARRAY_TEX_UV]
		if uv == null:
			continue
		var uvs: PackedVector2Array = uv
		for i: int in v.size():
			if uvs[i].x > 0.01:
				continue   # crowns / rocks / ruins, not the ground sheet
			var w: Vector3 = mi.transform * v[i]
			var d: float = Vector2(maxf(absf(w.x) - MAP_HALF, 0.0), maxf(absf(w.z) - MAP_HALF, 0.0)).length()
			if d < 4.0 or d > 24.0:
				continue
			checked += 1
			var hit: Dictionary = tm.call(&"intersect_ray", Vector3(w.x, 100.0, w.z), Vector3.DOWN)
			if hit.is_empty():
				over_hole += 1
			elif w.y > (hit["position"] as Vector3).y + 0.05:
				poking += 1
	print("plateau fit: %d ground vertices checked, %d over a hole, %d above the plateau" % [checked, over_hole, poking])
	if over_hole > 0 or poking > 0:
		_fail("the horizon ground no longer fits the plateau (%d over a hole, %d above it): re-run horizon_builder.gd"
			% [over_hole, poking])


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c: Node in n.get_children():
		out.append_array(_all(c))
	return out
