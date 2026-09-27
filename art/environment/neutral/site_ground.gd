class_name SiteGround
extends RefCounted
## Task MAP.P2: the painted dirt apron + baked contact shadow that seats a neutral site on the map ground.
## One indexed mesh per shape (cached, shared by every instance of that site) and one shared material
## (site_ground_mat.tres, lit like the ground, alpha blended, no depth write, no shadow casting). One draw node.
##
##   SiteGround.add(parent, node_name, Vector2(hx, hz), corner, reach, door_dir, door_len, seed, strength)
## The buildings name it "ContactDecal" (their node contract) in place of the old unshaded soft blob.
##
## The wall line is a rounded rectangle centred on the parent's origin: half extents (hx, hz) of the straight
## part plus `corner` metres of rounding (hx = hz = 0 gives a circle of radius `corner`). The apron reaches
## `reach` metres out of it (ragged by the shader's noise), with a tongue of trodden earth `door_len` metres
## longer toward `door_dir` (parent space, y ignored; Vector3.ZERO = no tongue).

const MAT: Material = preload("res://art/environment/neutral/site_ground_mat.tres")
const Y := 0.028          # above the ground (0), under the older soft decals (0.03+)
const ARC_STEPS := 7      # samples per rounded corner
const SIDE_STEPS := 6     # samples per straight side
const RINGS: Array[float] = [-0.45, 0.0, 0.22, 0.6, 1.15, 1.0]   # last = outer rim (scaled by reach)

static var _cache: Dictionary = {}


static func add(parent: Node3D, node_name: String, half: Vector2, corner: float, reach: float,
		door_dir: Vector3 = Vector3.ZERO, door_len: float = 0.0, seed_i: int = 0, strength: float = 1.0,
		tint: Color = Color(0.5, 0.5, 0.5)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh(half, corner, reach, door_dir, door_len, seed_i, strength, tint)
	mi.material_override = MAT
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.position = Vector3(0.0, Y, 0.0)
	mi.visibility_range_end = 120.0
	parent.add_child(mi)
	return mi


static func mesh(half: Vector2, corner: float, reach: float, door_dir: Vector3 = Vector3.ZERO,
		door_len: float = 0.0, seed_i: int = 0, strength: float = 1.0, tint: Color = Color(0.5, 0.5, 0.5)) -> ArrayMesh:
	var key := "%s|%.2f|%.2f|%s|%.2f|%d|%.2f|%s" % [half, corner, reach, door_dir, door_len, seed_i, strength, tint]
	if _cache.has(key):
		return _cache[key]
	# Wall line: points + outward normals, counter-clockwise, corners at (+-hx, +-hz).
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	var corners: Array[Vector2] = [Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y)]
	for c: int in 4:
		var a0: float = PI * 0.5 * c
		for s: int in ARC_STEPS:
			var a: float = a0 + PI * 0.5 * float(s) / float(ARC_STEPS - 1)
			var n := Vector2(cos(a), sin(a))
			pts.append(corners[c] + n * corner)
			nrm.append(n)
		# Straight side to the next corner (skipped when it has no length).
		var nxt: Vector2 = corners[(c + 1) % 4]
		var n_side := Vector2(cos(a0 + PI * 0.5), sin(a0 + PI * 0.5))
		var p0: Vector2 = corners[c] + n_side * corner
		var p1: Vector2 = nxt + n_side * corner
		if p0.distance_to(p1) > 0.05:
			for s: int in range(1, SIDE_STEPS):
				pts.append(p0.lerp(p1, float(s) / float(SIDE_STEPS)))
				nrm.append(n_side)
	var door := Vector2(door_dir.x, door_dir.z)
	if door.length() > 0.01:
		door = door.normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7717 + seed_i
	var count := pts.size()
	# Per-sample outer reach: gentle random wobble + the door tongue.
	var outer := PackedFloat32Array()
	outer.resize(count)
	var wob0: float = rng.randf() * TAU
	var wob1: float = rng.randf() * TAU
	for i: int in count:
		var u: float = TAU * float(i) / float(count)
		var r: float = reach * (1.0 + 0.16 * sin(u * 3.0 + wob0) + 0.1 * sin(u * 5.0 + wob1))
		if door_len > 0.0 and door != Vector2.ZERO:
			var d: float = maxf(pts[i].normalized().dot(door), 0.0)
			r += door_len * pow(d, 14.0)
		outer[i] = r
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var norms := PackedVector3Array()
	var col := Color(tint.r, tint.g, tint.b, strength)
	for k: int in RINGS.size():
		for i: int in count:
			var off: float
			if k == RINGS.size() - 1:
				off = outer[i]
			elif RINGS[k] <= 0.0:
				off = RINGS[k]
			else:
				off = minf(RINGS[k], outer[i] * 0.9) if k < 4 else outer[i] * 0.72
			var p: Vector2 = pts[i] + nrm[i] * off
			verts.append(Vector3(p.x, 0.0, p.y))
			uvs.append(Vector2(clampf(off / outer[i], 0.0, 1.0) if off > 0.0 else 0.0, off))
			cols.append(col)
			norms.append(Vector3.UP)
	var idx := PackedInt32Array()
	for k: int in RINGS.size() - 1:
		for i: int in count:
			var j: int = (i + 1) % count
			var a: int = k * count + i
			var b: int = k * count + j
			var c2: int = (k + 1) * count + i
			var d2: int = (k + 1) * count + j
			# Clockwise seen from above (Godot's front face), the ring runs +X -> +Z.
			idx.append_array([a, c2, b, b, c2, d2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cache[key] = m
	return m
