extends "res://art/units/wizards/ysolde.gd"
## Young Ysolde's model (Episode 4 memories): the real Ysolde kit, minus what makes her read as the grown Keeper of the
## Wood: no antler crown and no blossoms on it (a child wears a plain leaf wreath with a few small flowers instead). The
## staff is hidden by child_ysolde.gd. Its own scene path, so the kit's per-type merged-mesh cache never mixes it with
## the adult's.

func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	if pivot != null and pivot.name == &"Head":
		if mat == _mat(&"ysolde_antler"):
			return null
		for key: String in ["ys14_antlers", "ys14_crown_leaf", "ys14_crown_leaf_dark", "ys14_crown_blossoms"]:
			if _meshes.has(key) and mesh == _meshes[key]:
				return null
		if part_name == "HeadGlow":   # the eye bar only (the adult's glow also lights the blossom hearts on the antlers)
			mesh = _bake("child_head_glow", [[box(Vector3(0.20, 0.045, 0.05)), Transform3D(Basis(), Vector3(0, 1.785, 0.243))]])
	return super.add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)


func _build_parts() -> void:
	super._build_parts()
	var head: Node3D = $Root/Chest/Head
	# a few small white-and-pink flowers tucked in the leaf wreath
	var fl: Array = []
	for i: int in 5:
		var a := (-60.0 + 30.0 * float(i)) * DEG
		var p := Vector3(sin(a) * 0.17, 1.965, cos(a) * 0.14 - 0.03)
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -35.0 * DEG)
		fl.append_array(_flower(Transform3D(b.scaled(Vector3.ONE * 0.55), p)))
	super.add_part(head, _bake("child_wreath_blossoms", fl), _mat(&"ysolde_blossom"), Vector3.ZERO)
