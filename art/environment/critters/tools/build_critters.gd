extends SceneTree
## Bakes the cosmetic critter meshes and materials (task 12.V16):
##   art/environment/critters/meshes/critter_<kind>.res   (critter_meshes.gd)
##   art/environment/critters/materials/critter_<kind>_mat.tres   (ShaderMaterial of critter_<kind>.gdshader)
## Run headless:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://art/environment/critters/tools/build_critters.gd --quit-after 60

const DIR := "res://art/environment/critters/"
const KINDS: Array[StringName] = [&"bird", &"butterfly", &"firefly", &"dragonfly", &"frog", &"splash"]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "meshes"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "materials"))
	var builder: RefCounted = (load(DIR + "critter_meshes.gd") as GDScript).new()
	var ok := true
	for kind: StringName in KINDS:
		var mesh: ArrayMesh = builder.call(&"build", kind)
		var tris: int = builder.call(&"triangle_count", mesh)
		var mesh_path := DIR + "meshes/critter_%s.res" % kind
		var err := ResourceSaver.save(mesh, mesh_path, ResourceSaver.FLAG_COMPRESS)
		ok = ok and err == OK
		var mat := ShaderMaterial.new()
		mat.shader = load(DIR + "critter_%s.gdshader" % kind)
		var mat_path := DIR + "materials/critter_%s_mat.tres" % kind
		if ResourceLoader.exists(mat_path):
			mat = load(mat_path)   # keep tuned uniforms, only refresh the shader link
			mat.shader = load(DIR + "critter_%s.gdshader" % kind)
		err = ResourceSaver.save(mat, mat_path)
		ok = ok and err == OK
		print("%s: %d triangles, %d vertices -> %s" % [kind, tris,
				(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), mesh_path])
	print("BUILD CRITTERS %s" % ("OK" if ok else "FAILED"))
	quit()
