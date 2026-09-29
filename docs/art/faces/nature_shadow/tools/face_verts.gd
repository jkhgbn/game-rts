extends SceneTree
## Vertex counts of FaceKit styles (calibration for the Nature / Shadow unit faces).


func _initialize() -> void:
	var base := {"center": Vector3(0, 1.0, 0.0), "radius": 0.25, "preset": &"plain"}
	var cases := {
		"normal_nohair": {},
		"low_nohair": {"detail": &"low"},
		"low_crop": {"detail": &"low", "hair_style": &"crop"},
		"low_fringe_round": {"detail": &"low", "hair_style": &"fringe", "ears": &"round"},
		"low_bob_pointed": {"detail": &"low", "hair_style": &"bob", "ears": &"pointed"},
		"low_long": {"detail": &"low", "hair_style": &"long"},
		"low_nohair_r012": {"detail": &"low", "radius": 0.12},
		"dens5_nohair": {"density": 5.0},
		"low_noblush": {"detail": &"low", "x": {&"neutral": {"blush": 0.0}, &"smile": {"blush": 0.0}, &"fierce": {"blush": 0.0}, &"worried": {"blush": 0.0}, &"shout": {"blush": 0.0}}},
		"low_noblush_nobrow": {"detail": &"low", "brow": {"none": true}, "x": {&"neutral": {"blush": 0.0}}},
		"low_ears_round": {"detail": &"low", "ears": &"round"},
		"low_ears_pointed": {"detail": &"low", "ears": &"pointed"},
	}
	for k: String in cases:
		var spec := base.duplicate()
		var ov: Dictionary = cases[k]
		for kk: String in ov:
			spec[kk] = ov[kk]
		var st := FaceKit.style_from(spec)
		if ov.has("density"):
			st["density"] = ov["density"]
		var line := k + ":"
		for id: StringName in [&"neutral", &"smile", &"fierce", &"shout", &"far"]:
			var m := FaceKit.face_mesh("probe_" + k, st, id)
			var n := 0
			for s: int in m.get_surface_count():
				n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			line += " %s=%d" % [id, n]
		print("FACEVERTS ", line)
	quit(0)
