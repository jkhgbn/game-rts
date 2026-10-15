class_name GrassClump
extends RefCounted
## One grass clump for GroundDetail's MultiMesh rings (grass_blades.gdshader): BLADES tapered blades, each 2
## segments (5 vertices, 3 triangles), fanned round the clump centre and leaning out. Units: x / z in metres, y = 0..1
## (the shader scales it by the blade height). UV.y = 0 root .. 1 tip, UV.x = blade id (1.0 = the tall centre blade,
## the one that can carry a flower head). Built once per run and cached.

const BLADES := 7
const SPREAD := 0.17     ## clump radius (m) of the blade roots
const WIDTH := 0.060     ## blade root width (m)

static var _cache: ArrayMesh = null


static func build() -> ArrayMesh:
	if _cache:
		return _cache
	var rng := RandomNumberGenerator.new()
	rng.seed = 7741
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for b in BLADES:
		var centre := b == BLADES - 1
		var a := TAU * float(b) / float(BLADES - 1) + rng.randf_range(-0.4, 0.4)
		var r := 0.0 if centre else SPREAD * rng.randf_range(0.35, 1.0)
		var root := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var out := Vector3(cos(a), 0.0, sin(a))
		var lean := (0.03 if centre else rng.randf_range(0.07, 0.15))
		var hgt := (1.0 if centre else rng.randf_range(0.62, 0.95))
		var face := rng.randf_range(0.0, TAU)
		var side := Vector3(cos(face), 0.0, sin(face)) * WIDTH * 0.5 * (1.15 if centre else 1.0)
		var n := Vector3(-side.z, 0.0, side.x).normalized()
		var mid := root + out * lean * 0.35 + Vector3(0.0, hgt * 0.55, 0.0)
		var tip := root + out * lean + Vector3(0.0, hgt, 0.0)
		var base_i := verts.size()
		var id := 1.0 if centre else float(b) / float(BLADES) * 0.8
		for p: Array in [[root - side, 0.0], [root + side, 0.0], [mid - side * 0.62, 0.55], [mid + side * 0.62, 0.55],
				[tip, 1.0]]:
			var v: Vector3 = p[0]
			var h: float = p[1]
			verts.append(v)
			norms.append(n)
			uvs.append(Vector2(id, h))
		idx.append_array([base_i, base_i + 2, base_i + 1, base_i + 1, base_i + 2, base_i + 3,
			base_i + 2, base_i + 4, base_i + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cache = mesh
	return mesh
