class_name WaystoneRow
extends RefCounted
## Waystones along the trade roads (task 10.V10): ONE MultiMeshInstance3D of art/environment/meshes/waystone.res
## (one draw call + its shadow), draw-only (no collider, no navmesh effect). The map code decides where roads run and
## what to keep clear; this only spaces the stones out. Deterministic (same segments = same stones).
##
## Usage (10.C1, after the roads are known; load it by path while other step-10 parts may be missing):
##     var row: Script = load(WAYSTONE_ROW_PATH)   # "res://art/environment/meshes/waystone_row.gd"
##     var mmi: MultiMeshInstance3D = row.call(&"build", roads, 10.0, 2.2, 5.0, clear_points, clear_radii)
##     if mmi: add_child(mmi)
## `roads` = the same PackedVector4Array (x0, z0, x1, z1) as the ground's road_segs.

const MESH_PATH := "res://art/environment/meshes/waystone.res"
const NODE_NAME := "Waystones"


## Transforms of the stones: every ~`spacing` m along each segment (evenly spread, none within `end_clear` of either
## end), `side_offset` m from the centre line (the road is 3 m wide, the tree-free corridor 2.5 m each side), on the
## right-hand side of travel with every third stone on the other side; random yaw / lean / size from the position.
## A stone within clear_radii[i] (or `default_clear` when that array is shorter) of clear_points[i] is skipped.
static func transforms(roads: PackedVector4Array, spacing: float = 10.0, side_offset: float = 2.2,
		end_clear: float = 5.0, clear_points: PackedVector3Array = PackedVector3Array(),
		clear_radii: PackedFloat32Array = PackedFloat32Array(), default_clear: float = 6.0) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var k: int = 0
	for s: Vector4 in roads:
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		var length: float = a.distance_to(b)
		var usable: float = length - end_clear * 2.0
		if usable < 0.5:
			continue
		var dir: Vector2 = (b - a) / length
		var right := Vector2(-dir.y, dir.x)
		var n: int = maxi(1, int(round(usable / spacing)) + 1)
		for i: int in n:
			var t: float = end_clear + (usable * (float(i) / float(n - 1)) if n > 1 else usable * 0.5)
			var side: float = -1.0 if k % 3 == 2 else 1.0
			k += 1
			var p2: Vector2 = a + dir * t + right * side_offset * side
			var p := Vector3(p2.x, 0.0, p2.y)
			if _cleared(p, clear_points, clear_radii, default_clear):
				continue
			var h: float = _hash(p)
			var h2: float = fposmod(h * 17.13 + 0.31, 1.0)
			var h3: float = fposmod(h * 31.7 + 0.77, 1.0)
			# Face the road (local +z toward the centre line) give or take 25 degrees, lean up to ~6 degrees.
			var face := Vector3(-right.x * side, 0.0, -right.y * side)
			var yaw: float = atan2(face.x, face.z) + (h - 0.5) * 0.9
			var sc: float = 0.88 + h2 * 0.3
			var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, (h3 - 0.5) * 0.2) \
				* Basis(Vector3.FORWARD, (h2 - 0.5) * 0.14)
			out.append(Transform3D(basis.scaled(Vector3(sc, sc * (0.92 + h3 * 0.16), sc)), p))
	return out


## The MultiMeshInstance3D ("Waystones") of transforms(...), not added to the tree. Null when the mesh is missing
## or no stone fits.
static func build(roads: PackedVector4Array, spacing: float = 10.0, side_offset: float = 2.2, end_clear: float = 5.0,
		clear_points: PackedVector3Array = PackedVector3Array(),
		clear_radii: PackedFloat32Array = PackedFloat32Array(), default_clear: float = 6.0) -> MultiMeshInstance3D:
	if not ResourceLoader.exists(MESH_PATH):
		return null
	var xfs: Array[Transform3D] = transforms(roads, spacing, side_offset, end_clear, clear_points, clear_radii,
		default_clear)
	if xfs.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = load(MESH_PATH) as Mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = NODE_NAME
	mmi.multimesh = mm
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return mmi


static func _cleared(p: Vector3, pts: PackedVector3Array, radii: PackedFloat32Array, default_r: float) -> bool:
	for i: int in pts.size():
		var r: float = radii[i] if i < radii.size() else default_r
		if Vector2(p.x - pts[i].x, p.z - pts[i].z).length() < r:
			return true
	return false


static func _hash(p: Vector3) -> float:
	return fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0)
