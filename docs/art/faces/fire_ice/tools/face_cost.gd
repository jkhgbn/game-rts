extends SceneTree
## Faces pass 2026-09-28: vertex cost of FaceKit face variants (headless). Prints the neutral / far vertex count of a
## face spec with and without the "lean" options (UnitFaces.lean), and of its parts (decals only / + hair / + beard).
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/faces/fire_ice/tools/face_cost.gd --quit-after 600


func _initialize() -> void:
	var base := {"center": Vector3(0, 1.5, 0.05), "radius": 0.12, "head_mesh": CharacterModel.sphere(0.12, 8, 5),
		"preset": &"gentle", "detail": &"low", "ears": &"none"}
	var variants := {
		"decals": {},
		"decals_blush0": {"x": {&"neutral": {"blush": 0.0}}},
		"ears_round": {"ears": &"round"},
		"crop": {"hair_style": &"crop"},
		"moustache": {"beard": &"moustache"},
		"full": {"beard": &"full"},
		"spade": {"beard": &"spade"},
		"fringe3": {"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.5, 0.05), 0.12,
			Color.RED, Color.RED)},
	}
	var i := 0
	for k: String in variants:
		var spec := base.duplicate()
		for kk: String in variants[k]:
			spec[kk] = variants[k][kk]
		var st := FaceKit.style_from(spec)
		var n0 := _vc(FaceKit.face_mesh("cost%d" % i, st, &"neutral"))
		var nf := _vc(FaceKit.face_mesh("cost%d" % i, st, FaceKit.FAR))
		var st2 := UnitFaces.lean(FaceKit.style_from(spec))
		var l0 := _vc(FaceKit.face_mesh("costl%d" % i, st2, &"neutral"))
		var lf := _vc(FaceKit.face_mesh("costl%d" % i, st2, FaceKit.FAR))
		print("FACE COST %-14s neutral %4d far %4d | lean neutral %4d far %4d" % [k, n0, nf, l0, lf])
		i += 1
	quit(0)


static func _vc(m: Mesh) -> int:
	var n := 0
	for s: int in m.get_surface_count():
		n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n
