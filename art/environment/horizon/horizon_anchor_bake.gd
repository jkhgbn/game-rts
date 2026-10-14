extends SceneTree
## Writes the HorizonFit anchors (UV2) into the 8 baked horizon sector meshes in place, without touching their
## geometry, colours or material (horizon_builder.gd writes them too when it re-bakes the ring). Idempotent.
## Run headless:
##   tools\godot_run.ps1 --headless --path . -s res://art/environment/horizon/horizon_anchor_bake.gd --quit-after 6000

const MESH_DIR := "res://art/environment/horizon/meshes/"
const NAMES: Array[String] = ["north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west"]


func _init() -> void:
	for nm: String in NAMES:
		var path := MESH_DIR + "horizon_%s.res" % nm
		var mesh := load(path) as ArrayMesh
		if mesh == null or mesh.get_surface_count() == 0:
			push_error("horizon_anchor_bake: no mesh %s" % path)
			continue
		var arrays: Array = mesh.surface_get_arrays(0)
		var mat: Material = mesh.surface_get_material(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var anchors := HorizonFit.anchors(verts, idx)
		arrays[Mesh.ARRAY_TEX_UV2] = anchors
		var moved := 0
		for i: int in verts.size():
			if Vector2(verts[i].x, verts[i].z).distance_squared_to(anchors[i]) > 0.0001:
				moved += 1
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, mat)
		var err := ResourceSaver.save(mesh, path)
		print("%s: %d verts, %d anchored on a piece centre, save %d" % [nm, verts.size(), moved, err])
	print("HORIZON ANCHORS DONE")
	quit()
