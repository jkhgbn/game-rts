extends SceneTree
## G-F per-map horizon (docs/art/gf_horizon.md): tags the Crown Hollow landmark pieces of the 8 baked horizon sector
## meshes in UV.y (HorizonVariant.TAG_*: 1 watchtower, 2 shrine, 3 aqueduct, 4 stone ring, 5 pond, 6 granite crag;
## 0 = ground / canopy), in place, without touching geometry, colours, anchors or the material. horizon.gdshader never
## reads UV.y, so Crown Hollow looks exactly as before; HorizonVariant drops the tagged pieces on the other maps.
## A piece = vertices welded by position and joined by triangles (as HorizonFit.anchors); only small pieces (<= 20 m)
## that are not crowns (UV.x 0.8 / 0.55) are tagged, by their centre's distance to the builder's landmark sites.
## Idempotent. Re-run after horizon_builder.gd re-bakes the ring. Run headless:
##   tools\godot_run.ps1 --headless --path . -s res://art/environment/horizon/horizon_tag_bake.gd --quit-after 6000

const MESH_DIR := "res://art/environment/horizon/meshes/"
const NAMES: Array[String] = ["north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west"]
const PIECE_MAX := 20.0


func _init() -> void:
	var totals: Dictionary = {}
	for nm: String in NAMES:
		var path := MESH_DIR + "horizon_%s.res" % nm
		var mesh := load(path) as ArrayMesh
		if mesh == null or mesh.get_surface_count() == 0:
			push_error("horizon_tag_bake: no mesh %s" % path)
			continue
		var arrays: Array = mesh.surface_get_arrays(0)
		var mat: Material = mesh.surface_get_material(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var roots := _pieces(verts, idx)
		var lo: Dictionary = {}
		var hi: Dictionary = {}
		var fmin: Dictionary = {}
		var fmax: Dictionary = {}
		for i: int in verts.size():
			var r: int = roots[i]
			var p := Vector2(verts[i].x, verts[i].z)
			if lo.has(r):
				lo[r] = (lo[r] as Vector2).min(p)
				hi[r] = (hi[r] as Vector2).max(p)
				fmin[r] = minf(float(fmin[r]), uv[i].x)
				fmax[r] = maxf(float(fmax[r]), uv[i].x)
			else:
				lo[r] = p
				hi[r] = p
				fmin[r] = uv[i].x
				fmax[r] = uv[i].x
		var tag_of: Dictionary = {}
		for r: int in lo:
			var l: Vector2 = lo[r]
			var h: Vector2 = hi[r]
			if maxf(h.x - l.x, h.y - l.y) > PIECE_MAX:
				tag_of[r] = 0
				continue
			# Crowns (domes 0.8, conifers 0.55) are never landmarks; flat rock / ruin pieces are 1.0, pond discs 0.
			var flat := float(fmin[r]) > 0.99
			var disc := float(fmax[r]) < 0.01
			if not flat and not disc:
				tag_of[r] = 0
				continue
			tag_of[r] = HorizonVariant.landmark_tag((l + h) * 0.5, disc)
		var counts: Dictionary = {}
		for i: int in verts.size():
			var t: int = tag_of[roots[i]]
			uv[i] = Vector2(uv[i].x, float(t))
			if t > 0:
				counts[t] = int(counts.get(t, 0)) + 1
				totals[t] = int(totals.get(t, 0)) + 1
		arrays[Mesh.ARRAY_TEX_UV] = uv
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, mat)
		var err := ResourceSaver.save(mesh, path)
		print("%s: %d verts, tagged %s, save %d" % [nm, verts.size(), str(counts), err])
	print("HORIZON TAGS DONE %s" % str(totals))
	quit()


## Union-find root of every vertex: welded by position (1 mm), joined by triangles.
func _pieces(verts: PackedVector3Array, idx: PackedInt32Array) -> PackedInt32Array:
	var n := verts.size()
	var parent := PackedInt32Array()
	parent.resize(n)
	var weld: Dictionary = {}
	for i: int in n:
		var v := verts[i]
		var key := Vector3i(roundi(v.x * 1000.0), roundi(v.y * 1000.0), roundi(v.z * 1000.0))
		var first: int = weld.get(key, -1)
		if first < 0:
			weld[key] = i
			parent[i] = i
		else:
			parent[i] = first
	for t: int in range(0, idx.size() - 2, 3):
		var a := _root(parent, idx[t])
		for k: int in [1, 2]:
			var b := _root(parent, idx[t + k])
			if a != b:
				parent[b] = a
				a = _root(parent, a)
	var out := PackedInt32Array()
	out.resize(n)
	for i: int in n:
		out[i] = _root(parent, i)
	return out


func _root(parent: PackedInt32Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	while parent[i] != r:
		var nx := parent[i]
		parent[i] = r
		i = nx
	return r
