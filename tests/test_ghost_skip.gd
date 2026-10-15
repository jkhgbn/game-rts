extends SceneTree
## Building.make_ghost skips any node (and its subtree) with meta no_ghost == true; other meshes are still copied.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ghost_skip.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ghost_skip"

var main: Node
var _wait := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	var err := _run()
	if err == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, err])
	return true


func _run() -> String:
	var building: Building = null
	for n in get_nodes_in_group(&"buildings"):
		if n is Building:
			building = n
			break
	if building == null:
		return "no building on the map"
	var visual: Node3D = building.get(&"_visual") as Node3D
	if visual == null:
		return "building has no visual"
	var mat := StandardMaterial3D.new()
	var base_ghost: Node3D = building.make_ghost(mat)
	var baseline: int = base_ghost.get_child_count()
	base_ghost.free()

	var skip_mesh := BoxMesh.new()
	var kept_mesh := SphereMesh.new()
	var skip_root := Node3D.new()
	skip_root.set_meta(&"no_ghost", true)
	visual.add_child(skip_root)
	var skip_inner := Node3D.new()
	skip_root.add_child(skip_inner)
	var skip_mi := MeshInstance3D.new()
	skip_mi.mesh = skip_mesh
	skip_inner.add_child(skip_mi)
	var kept_mi := MeshInstance3D.new()
	kept_mi.mesh = kept_mesh
	visual.add_child(kept_mi)
	var false_meta := MeshInstance3D.new()
	false_meta.mesh = kept_mesh
	false_meta.set_meta(&"no_ghost", false)
	visual.add_child(false_meta)

	var ghost: Node3D = building.make_ghost(mat)
	var kept := 0
	var skipped_found := false
	for c in ghost.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		if mi.mesh == skip_mesh:
			skipped_found = true
		if mi.mesh == kept_mesh:
			kept += 1
	var count: int = ghost.get_child_count()
	ghost.free()
	if skipped_found:
		return "no_ghost subtree mesh was copied"
	if kept != 2:
		return "expected 2 kept meshes, got %d" % kept
	if count != baseline + 2:
		return "ghost has %d meshes, expected %d" % [count, baseline + 2]
	if baseline == 0:
		return "baseline ghost is empty (other meshes not copied)"
	return ""
