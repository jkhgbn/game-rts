extends SceneTree
## Building material syncs upload only on change (docs/reviews/review-art-faces.md M4, L1):
## MatSync.put / shader_default, PaintedVC.sync_glow (0 uploads while the sources rest, 1 after one source changes),
## MeshBake.copy_surface keeps the custom-channel format.
## Run: godot --headless --path . -s tests/test_art_sync_review.gd --quit-after 600

const TASK_ID := "art_sync_review"
const RUNE_GLOW := "res://art/shaders/rune_glow.gdshader"

var _fails: PackedStringArray = []
var _frame := 0


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_run()
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for f: String in _fails:
				print("  " + f)
			print("FAIL %s: %s" % [TASK_ID, _fails[0]])
		return true
	return false


func _run() -> void:
	var sh := load(RUNE_GLOW) as Shader
	# MatSync.put
	var m := ShaderMaterial.new()
	m.shader = sh
	if not MatSync.put(m, &"energy", 2.0):
		_fails.append("put: first set not uploaded")
	if MatSync.put(m, &"energy", 2.0):
		_fails.append("put: same value uploaded again")
	if not MatSync.put(m, &"energy", 2.5):
		_fails.append("put: changed value not uploaded")
	MatSync.put(m, &"glow_color", Color(1, 0.5, 0.2))
	if not MatSync.put(m, &"glow_color", Vector3(1, 0.5, 0.2)):   # another type: no error, uploaded
		_fails.append("put: a value of another type was not uploaded")
	# shader_default cached and equal to the RenderingServer's
	var d1: Variant = MatSync.shader_default(sh, &"energy")
	var d2: Variant = RenderingServer.shader_get_parameter_default(sh.get_rid(), &"energy")
	if d1 != d2 or MatSync.shader_default(sh, &"energy") != d2:
		_fails.append("shader_default %s != %s" % [str(d1), str(d2)])
	# PaintedVC.sync_glow
	var holder := Node3D.new()
	root.add_child(holder)
	var srcs: Array[ShaderMaterial] = []
	for i: int in 3:
		var g := ShaderMaterial.new()
		g.shader = sh
		g.set_shader_parameter(&"energy", 1.0 + i)
		srcs.append(g)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.material = g
		mi.mesh = bm
		mi.position.x = i
		holder.add_child(mi)
	var merged := PaintedVC.convert_glow(holder)
	if merged == null:
		_fails.append("convert_glow merged nothing")
		return
	var n0 := PaintedVC.sync_glow(merged)
	if n0 != 0:
		_fails.append("sync_glow uploaded %d arrays while nothing changed" % n0)
	srcs[1].set_shader_parameter(&"energy", 7.0)
	var n1 := PaintedVC.sync_glow(merged)
	if n1 != 1:
		_fails.append("sync_glow uploaded %d arrays after one energy change (want 1)" % n1)
	var en: PackedFloat32Array = merged.get_shader_parameter(&"energies")
	if en.size() != PaintedVC.GLOW_MAX or absf(en[1] - 7.0) > 0.001 or absf(en[7] - en[2]) > 0.001:
		_fails.append("energies wrong after sync: %s" % str(en))
	# MeshBake.copy_surface keeps CUSTOM0
	var am := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arr[Mesh.ARRAY_CUSTOM0] = PackedFloat32Array([1.0, 2.0, 3.0])
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	var cp := ArrayMesh.new()
	MeshBake.copy_surface(cp, am, 0)
	if MeshBake.custom_flags(cp, 0) != MeshBake.custom_flags(am, 0) or MeshBake.custom_flags(am, 0) == 0:
		_fails.append("copy_surface lost the custom format")
	holder.queue_free()
