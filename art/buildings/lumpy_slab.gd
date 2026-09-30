class_name LumpySlab
extends RefCounted
## A roof slab / thick board with a LUMPY, SAGGING top (in-game grade 2026-09-30, Art Lab C1 "shape richness": a flat
## box roof is the biggest plain plane of a building). Drop-in for a BoxMesh of the same size in BuildingMerge items:
## centred on its origin, top face at +size.y / 2 displaced by a sag (the middle of the length hangs lower) and soft
## lumps (a few smooth bumps, seeded), both fading to 0 at the rim so the four sides and the bottom stay flat and meet
## the rolls / trims of the model. Smooth normals from the height field (the light breaks on the lumps). Same arrays as
## the primitives (vertex, normal, tangent, UV = local xz, index), cached per (size, sub, lump, sag, seed).

static var _cache: Dictionary = {}


## size = the box it replaces; sub = top-grid cells along x / z; lump = bump height (m); sag = middle dip along z (m).
static func mesh(size: Vector3, sub: Vector2i, lump: float, sag: float, seed: int = 0) -> ArrayMesh:
	var key := "%s|%s|%.3f|%.3f|%d" % [size, sub, lump, sag, seed]
	if _cache.has(key):
		return _cache[key]
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var ix := PackedInt32Array()
	var nx := sub.x + 1
	var nz := sub.y + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 7919
	var ph := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var fx := [rng.randf_range(1.6, 2.4), rng.randf_range(2.6, 3.6)]
	var fz := [rng.randf_range(1.2, 1.8), rng.randf_range(2.4, 3.4)]
	var height := func(x: float, z: float) -> float:
		var u := x / hx          # -1..1
		var w := z / hz
		var rim := (1.0 - u * u) * (1.0 - w * w)     # 0 at the rim, 1 in the middle
		var bumps: float = sin(u * fx[0] * PI + ph[0]) * sin(w * fz[0] * PI + ph[1]) * 0.6 \
			+ sin(u * fx[1] * PI + ph[2]) * sin(w * fz[1] * PI + ph[3]) * 0.4
		return rim * (lump * bumps - sag * (1.0 - w * w) * 1.0)
	# top grid
	for j: int in nz:
		for i: int in nx:
			var x := -hx + size.x * float(i) / float(sub.x)
			var z := -hz + size.z * float(j) / float(sub.y)
			v.append(Vector3(x, hy + height.call(x, z), z))
			var e := 0.02
			var dx: float = (height.call(x + e, z) - height.call(x - e, z)) / (2.0 * e)
			var dz: float = (height.call(x, z + e) - height.call(x, z - e)) / (2.0 * e)
			n.append(Vector3(-dx, 1.0, -dz).normalized())
	for j2: int in sub.y:
		for i2: int in sub.x:
			var a := j2 * nx + i2
			ix.append_array(PackedInt32Array([a, a + 1, a + nx, a + 1, a + nx + 1, a + nx]))
	# four flat sides (the rim is at hy all round) and the bottom
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for k: int in 4:
		var p0: Vector3 = corners[k]
		var p1: Vector3 = corners[(k + 1) % 4]
		var out := Vector3((p0 + p1).x, 0.0, (p0 + p1).z).normalized()
		_quad(v, n, ix, p0 + Vector3(0, hy, 0), p1 + Vector3(0, hy, 0), p1 - Vector3(0, hy, 0), p0 - Vector3(0, hy, 0), out)
	_quad(v, n, ix, Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz), Vector3.DOWN)
	var tg := PackedFloat32Array()
	var uv := PackedVector2Array()
	for p: Vector3 in v:
		tg.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
		uv.append(Vector2(p.x, p.z))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TANGENT] = tg
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = ix
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_cache[key] = m
	return m


## A flat quad a-b-c-d with outward normal `out`, wound so its front faces `out` (Godot: clockwise from the front).
static func _quad(v: PackedVector3Array, n: PackedVector3Array, ix: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, out: Vector3) -> void:
	var base := v.size()
	for p: Vector3 in [a, b, c, d]:
		v.append(p)
		n.append(out)
	var front := (b - a).cross(c - a).dot(out) < 0.0
	if front:
		ix.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	else:
		ix.append_array(PackedInt32Array([base, base + 2, base + 1, base, base + 3, base + 2]))
