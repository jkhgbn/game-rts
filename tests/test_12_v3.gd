extends SceneTree
## Task 12.V3 (Crown Bridges): art/environment/bridges/lane_bridge.tscn.
## Run:  $GODOT --headless --path . -s tests/test_12_v3.gd --fixed-fps 60 --quit-after 600
## Checks: the scene instantiates without errors; draw-only (no collider, no physics body, no Area3D), 0 lights;
## <= 3 materials (and the stone one is the shared nature_mat.tres); mesh data present and indexed; triangle budget;
## the walkable deck is flush (y 0.0-0.03) and covers every point of the moat under the 8 x 6.5 m crossing;
## nothing but paving rises above y 0.03 inside the walkable deck; 4 ember braziers (emission only) at the ends;
## the placement contract (local +Z away from the isle, both crossings point-mirrored).

const TASK_ID := "12.v3"
const SCENE := "res://art/environment/bridges/lane_bridge.tscn"
const STONE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const MOAT_R := 12.75
const WEST := Vector3(-9.02, 0.0, 9.02)
const EAST := Vector3(9.02, 0.0, -9.02)
const MAX_TRIS := 8000

var _fails: Array[String] = []


func _initialize() -> void:
	_run()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - " + f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene missing")
	if not _fails.is_empty():
		return
	var ps: PackedScene = load(SCENE) as PackedScene
	var bridge: Node3D = ps.instantiate() as Node3D
	_check(bridge != null, "root is not a Node3D")
	if bridge == null:
		return
	root.add_child(bridge)
	# Draw-only, no lights.
	var meshes: Array[MeshInstance3D] = []
	for n: Node in bridge.find_children("*", "", true, false):
		_check(not (n is CollisionObject3D or n is CollisionShape3D or n is CollisionPolygon3D),
				"has a collider / body: %s" % n.name)
		_check(not (n is Light3D), "has a light: %s" % n.name)
		_check(not (n is NavigationObstacle3D or n is NavigationRegion3D), "touches navigation: %s" % n.name)
		if n is MeshInstance3D:
			meshes.append(n as MeshInstance3D)
	_check(meshes.size() >= 1, "no MeshInstance3D")
	# Materials, triangles, indexed data.
	var mats: Dictionary = {}
	var tris: int = 0
	var stone_arrays: Array = []
	var ember_arrays: Array = []
	var ember_mat: Material = null
	for mi: MeshInstance3D in meshes:
		var mesh: Mesh = mi.mesh
		_check(mesh != null, "%s has no mesh" % mi.name)
		if mesh == null:
			continue
		for s: int in mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(s)
			if m == null:
				m = mesh.surface_get_material(s)
			if mi.material_override:
				m = mi.material_override
			_check(m != null, "surface %d has no material" % s)
			if m:
				mats[m] = true
			var arr: Array = mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX] if arr.size() > 0 and arr[Mesh.ARRAY_VERTEX] != null \
					else PackedVector3Array()
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr.size() > 0 and arr[Mesh.ARRAY_INDEX] != null \
					else PackedInt32Array()
			_check(v.size() > 0, "surface %d: no vertex data (mesh saved empty?)" % s)
			_check(idx.size() > 0, "surface %d is not indexed" % s)
			tris += int(idx.size() / 3.0)
			var sname: String = (mesh as ArrayMesh).surface_get_name(s) if mesh is ArrayMesh else ""
			if sname == "stone":
				stone_arrays = arr
				_check(m != null and m.resource_path == STONE_MAT, "stone surface must use the shared nature_mat.tres")
			elif sname == "ember":
				ember_arrays = arr
				ember_mat = m
	_check(mats.size() <= 3, "%d materials (max 3)" % mats.size())
	_check(tris > 500 and tris <= MAX_TRIS, "%d triangles (budget %d)" % [tris, MAX_TRIS])
	print("lane bridge: %d mesh instance(s), %d materials, %d triangles" % [meshes.size(), mats.size(), tris])
	if stone_arrays.is_empty():
		_check(false, "no 'stone' surface")
		return
	_check_deck(meshes[0].mesh, stone_arrays)
	_check_braziers(ember_arrays, ember_mat)
	_check_placement(bridge)
	bridge.queue_free()


## Walkable deck: flush at y 0.0-0.03 over the whole 8 x 6.5 m rectangle where the moat is, nothing taller in it.
func _check_deck(mesh: Mesh, stone: Array) -> void:
	var v: PackedVector3Array = stone[Mesh.ARRAY_VERTEX]
	var max_in := -INF
	var flush := 0
	for p: Vector3 in v:
		# Inside the walkable deck (the parapets start at |x| 3.96; moss cushions hug their foot, so test |x| < 3.5).
		if absf(p.x) < 3.5 and absf(p.z) < 3.2:
			max_in = maxf(max_in, p.y)
			if p.y >= 0.0 and p.y <= 0.03:
				flush += 1
	_check(max_in <= 0.03 + 1e-4, "something rises to y %.3f inside the walkable deck (max 0.03)" % max_in)
	_check(flush > 200, "too few paving vertices at y 0.0-0.03 (%d)" % flush)
	# Every point over the water (r 11-14.5 from the isle centre) under the deck has paving above it.
	var tm: TriangleMesh = mesh.generate_triangle_mesh()
	_check(tm != null, "no triangle mesh")
	if tm == null:
		return
	var missed := 0
	var tested := 0
	var worst := 0.0
	# The deck proper (the moss at the parapets' foot starts past |x| 3.62; units' centres stay within |x| 3.5
	# of the 8 m gap).
	var x := -3.6
	while x <= 3.6:
		var z := -3.2
		while z <= 3.2:
			var r: float = Vector2(x, z + MOAT_R).length()
			if r >= 10.9 and r <= 14.6:
				tested += 1
				var hit: Dictionary = tm.intersect_ray(Vector3(x, 2.0, z), Vector3.DOWN)
				# Paving tops (0.006-0.026) or the mossy joint bed right under them (-0.028).
				var ok: bool = not hit.is_empty() and float((hit["position"] as Vector3).y) >= -0.035 \
						and float((hit["position"] as Vector3).y) <= 0.031
				if not ok:
					missed += 1
					if not hit.is_empty():
						worst = minf(worst, float((hit["position"] as Vector3).y))
			z += 0.13
		x += 0.13
	_check(tested > 500, "deck sampling found no water under the crossing (%d)" % tested)
	_check(missed == 0, "%d of %d points over the moat are not covered by the flush deck (lowest hit y %.2f)" % [
			missed, tested, worst])
	print("deck: %d points over the moat checked, %d uncovered, max y inside the deck %.3f" % [tested, missed, max_in])


## Four ember braziers, one near each post (+-4.62, +-3.1), above y 1.3, emission-only material.
func _check_braziers(ember: Array, mat: Material) -> void:
	_check(not ember.is_empty(), "no 'ember' surface")
	if ember.is_empty():
		return
	_check(mat is ShaderMaterial and float((mat as ShaderMaterial).get_shader_parameter(&"energy")) > 0.5,
			"ember material has no emission energy")
	var v: PackedVector3Array = ember[Mesh.ARRAY_VERTEX]
	var corners: Array = [Vector2(-4.62, -3.1), Vector2(4.62, -3.1), Vector2(-4.62, 3.1), Vector2(4.62, 3.1)]
	for c: Vector2 in corners:
		var n := 0
		for p: Vector3 in v:
			if Vector2(p.x, p.z).distance_to(c) < 0.45 and p.y > 1.3:
				n += 1
		_check(n > 10, "no embers on the brazier at %s" % c)
	for p: Vector3 in v:
		if Vector2(absf(p.x) - 4.62, absf(p.z) - 3.1).length() > 0.5:
			_check(false, "ember vertex away from the braziers at %s" % p)
			break


## Local +Z points away from the isle; both crossings are point mirrors.
func _check_placement(bridge: Node3D) -> void:
	_check(bridge.has_method(&"place_on_moat"), "root script lacks place_on_moat()")
	if not bridge.has_method(&"place_on_moat"):
		return
	_check(is_equal_approx(float(bridge.get(&"MOAT_RADIUS")), MOAT_R), "MOAT_RADIUS is not 12.75")
	bridge.call(&"place_on_moat", WEST, Vector3.ZERO)
	var xw: Transform3D = bridge.transform
	_check(xw.origin.distance_to(WEST) < 0.001, "place_on_moat did not move the bridge to the crossing")
	_check((xw * Vector3(0, 0, -MOAT_R)).distance_to(Vector3.ZERO) < 0.05, "local (0, 0, -12.75) is not the isle centre")
	_check(xw.basis.z.dot(Vector3(-0.7071, 0, 0.7071)) > 0.999, "west bridge +Z does not point away from the isle")
	_check(absf(xw.basis.y.dot(Vector3.UP) - 1.0) < 1e-4, "bridge is not upright")
	bridge.call(&"place_on_moat", EAST, Vector3.ZERO)
	var xe: Transform3D = bridge.transform
	_check(xe.basis.z.dot(-xw.basis.z) > 0.999 and xe.basis.x.dot(-xw.basis.x) > 0.999, "east bridge is not the point mirror")
	# Same basis from the static helper, and for a moat not centred on the origin.
	var scr: Script = bridge.get_script() as Script
	var b: Basis = scr.call(&"basis_for", Vector3(5.0, 0.0, 2.0) + Vector3(0, 0, 12.75), Vector3(5.0, 0.0, 2.0))
	_check(b.z.dot(Vector3(0, 0, 1)) > 0.999, "basis_for ignores isle_center")
	# Foam stones: in the moat's water ring, and point-mirrored between the two bridges.
	var fw: PackedVector4Array = scr.call(&"foam_rocks", WEST, Vector3.ZERO)
	var fe: PackedVector4Array = scr.call(&"foam_rocks", EAST, Vector3.ZERO)
	_check(fw.size() >= 2 and fw.size() == fe.size(), "foam_rocks size")
	for i: int in fw.size():
		var r: float = Vector2(fw[i].x, fw[i].y).length()
		_check(r > 11.0 and r < 14.5, "foam stone %d not in the moat (r %.2f)" % [i, r])
		_check(Vector2(fw[i].x + fe[i].x, fw[i].y + fe[i].y).length() < 0.01, "foam stones are not point-mirrored")
