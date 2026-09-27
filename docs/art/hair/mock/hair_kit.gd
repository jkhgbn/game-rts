extends RefCounted
## Prototype of the kit `hair` builder (hair redesign plan, docs/art/hair-redesign-plan.md section 5).
## A LOCK = a chunky swept strand: a flattened pentagon section swept along a cubic Bezier, swelling a little after the
## root and tapering to a point, optional twist, flat-shaded (painted low-poly look), no transparency. The last part of
## the lock can take a second material (ember / frost / blossom tips). Everything is in MODEL space (feet origin): add
## the mesh with add_part(head, mesh, null, Vector3.ZERO) so the kit merges it into the Head pivot.
## Not wired into CharacterModel yet: the plan's task H0 moves it to art/units/kit/hair_kit.gd.

const SIDES := 5


## One lock. pts = 4 Bezier control points (root first). face = the direction the flat side looks (e.g. away from the
## head centre). width / thick in metres at the widest; rings = sections along the lock (4-6); tip_from = 0-1 where the
## tip material starts (1 = no tip); twist in degrees root -> tip.
static func lock(st_body: SurfaceTool, st_tip: SurfaceTool, pts: Array, face: Vector3, width: float, thick: float,
		rings: int = 4, tip_from: float = 1.0, twist: float = 0.0) -> void:
	var sec: Array = []   # Array of PackedVector3Array (one ring each)
	for i: int in rings:
		var u := float(i) / float(rings)
		var p := _bez(pts, u)
		var t := (_bez(pts, minf(u + 0.02, 1.0)) - _bez(pts, maxf(u - 0.02, 0.0))).normalized()
		var b := t.cross(face).normalized()
		if b.length() < 0.5:
			b = t.cross(Vector3.UP).normalized()
		var n := b.cross(t).normalized()
		var tw := deg_to_rad(twist * u)
		var bb := b * cos(tw) + n * sin(tw)
		var nn := n * cos(tw) - b * sin(tw)
		var s := _profile(u)
		var ring := PackedVector3Array()
		for k: int in SIDES:
			var a := TAU * float(k) / float(SIDES) + PI * 0.5
			ring.append(p + bb * (cos(a) * width * 0.5 * s) + nn * (sin(a) * thick * 0.5 * s))
		sec.append(ring)
	var tip := _bez(pts, 1.0)
	for i: int in rings:
		var u0 := float(i) / float(rings)
		var st := st_tip if u0 >= tip_from and st_tip != null else st_body
		var r0: PackedVector3Array = sec[i]
		if i < rings - 1:
			var r1: PackedVector3Array = sec[i + 1]
			for k: int in SIDES:
				var k1 := (k + 1) % SIDES
				_tri(st, r0[k], r1[k], r1[k1])
				_tri(st, r0[k], r1[k1], r0[k1])
		else:
			for k: int in SIDES:
				_tri(st, r0[k], tip, r0[(k + 1) % SIDES])
	# root cap (hidden under the hat / in the cap, but closes the shape for the silhouette pass)
	var r: PackedVector3Array = sec[0]
	for k: int in range(1, SIDES - 1):
		_tri(st_body, r[0], r[k + 1], r[k])


## Two SurfaceTools ready for lock(); finish() commits them into one ArrayMesh (2 surfaces, materials set).
static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0xFFFFFFFF)   # flat shading
	return st


static func finish(st_body: SurfaceTool, body_mat: Material, st_tip: SurfaceTool, tip_mat: Material) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for pair: Array in [[st_body, body_mat], [st_tip, tip_mat]]:
		var st: SurfaceTool = pair[0]
		if st == null:
			continue
		st.generate_normals()
		st.set_material(pair[1])
		st.commit(mesh)
	return mesh


## Width profile along the lock: swells to 1.0 at u 0.3, tapers to 0.3 at the last ring.
static func _profile(u: float) -> float:
	if u < 0.3:
		return lerpf(0.8, 1.0, u / 0.3)
	return lerpf(1.0, 0.3, pow((u - 0.3) / 0.7, 1.2))


static func _bez(p: Array, u: float) -> Vector3:
	var v := 1.0 - u
	return p[0] * v * v * v + p[1] * 3.0 * v * v * u + p[2] * 3.0 * v * u * u + p[3] * u * u * u


## Godot front faces are clockwise seen from outside; the ring order above winds them that way.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## Vertex count of a lock (flat, unindexed) for the budget.
static func lock_verts(rings: int) -> int:
	return (rings - 1) * SIDES * 6 + SIDES * 3 + (SIDES - 2) * 3
