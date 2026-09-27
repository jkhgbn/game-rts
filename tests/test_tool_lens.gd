extends SceneTree
## Tool 3 Lens (tools/lens/README.md): headless checks of the framing solver, the word parser, the spec reader, the
## CameraSpec contract and the pixel math. Run:
##   tools\godot_run.ps1 --headless --path . -s tests/test_tool_lens.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS tool_lens" or "FAIL tool_lens: <reasons>".

const TASK_ID := "tool_lens"

var fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails.append(what)
		print("  fail: " + what)


func _run() -> void:
	_words()
	_solve_sizes()
	_conventions()
	_contract()
	_doc()
	_measure()
	await _model()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(PackedStringArray(fails))])
	quit()


func _words() -> void:
	var w := LensSolver.parse_words("mcu on vessa, 3/4 left, low, thirds left, dutch 8, push 0.2", ["vessa", "shade"])
	_ok(w["ok"], "prose words parse")
	_ok(w["size"] == "mcu" and w["subjects"] == ["vessa"], "size + subject")
	_ok(is_equal_approx(float(w["angle"]), 45.0) and is_equal_approx(float(w["pitch"]), LensSolver.HEIGHTS["low"]), "angle / height words")
	_ok(w["comp"] == "thirds-left" and is_equal_approx(float(w["dutch"]), 8.0) and is_equal_approx(float(w["push"]), 0.2), "comp / dutch / push")
	var t := LensSolver.parse_words("ms two-shot vessa shade, high", ["vessa", "shade"])
	_ok(t["ok"] and t["two"] and (t["subjects"] as Array).size() == 2, "two-shot")
	var o := LensSolver.parse_words("mcu ots vessa over shade", ["vessa", "shade"])
	_ok(o["ok"] and o["over"] == "vessa" and o["subjects"] == ["shade"], "ots a over b")
	var bad := LensSolver.parse_words("mcu on vesa, 3/4 lef", ["vessa", "shade"])
	_ok(not bad["ok"] and (bad["errors"] as Array).size() == 2, "two teaching errors")
	var txt := JSON.stringify(bad["errors"])
	_ok("did you mean \\\"vessa\\\"" in txt and "did you mean \\\"3/4-left\\\"" in txt, "did-you-mean hints: " + txt.left(200))
	var sz := LensSolver.parse_words("mcuu on vessa", ["vessa"])
	_ok(not sz["ok"] and "mcu" in JSON.stringify(sz["errors"]), "unknown size -> nearest size")


func _subs() -> Dictionary:
	return {"vessa": LensSolver.subject(Vector3(0, 0, 0), 0.0, 1.9), "shade": LensSolver.subject(Vector3(1.4, 0, 0.8), 250.0, 1.8)}


func _solve_sizes() -> void:
	var subs := _subs()
	for size: String in LensSolver.SIZES:
		if size == "ecu":
			continue
		var c := LensSolver.solve_words("%s on vessa, 3/4 right" % size, subs)
		_ok(c["ok"], "solve %s" % size)
		if not c["ok"]:
			continue
		var err := absf(float(c["pred_s"]) / float(c["target_s"]) - 1.0)
		_ok(err < 0.03, "%s predicted coverage %.3f vs %.3f" % [size, c["pred_s"], c["target_s"]])
		var n: Vector2 = c["head_ndc"]["vessa"]
		_ok(absf(n.y) < float(c["band_frac"]) and absf(n.x) < 1.0, "%s face in band" % size)
	# closer sizes put the camera closer
	var d_cu := (LensSolver.solve_words("cu on vessa", subs)["pos"] as Vector3).distance_to(Vector3(0, 1.6, 0))
	var d_ws := (LensSolver.solve_words("ws on vessa", subs)["pos"] as Vector3).distance_to(Vector3(0, 1.6, 0))
	_ok(d_cu < d_ws, "cu closer than ws")
	# two-shot keeps both faces in the band, ots camera behind A
	var two := LensSolver.solve_words("cowboy two-shot vessa shade", subs)
	_ok(absf((two["head_ndc"]["vessa"] as Vector2).x) < 1.0 and absf((two["head_ndc"]["shade"] as Vector2).x) < 1.0, "two-shot both faces in frame")
	var ots := LensSolver.solve_words("mcu ots vessa over shade", subs)
	var ab := (subs["shade"]["pos"] as Vector3) - (subs["vessa"]["pos"] as Vector3)
	_ok(((ots["pos"] as Vector3) - (subs["vessa"]["pos"] as Vector3)).dot(ab) < 0.0, "ots camera behind A")
	# determinism: same input, same bytes
	var a := JSON.stringify(LensSolver.to_json(LensSolver.solve_words("mcu on vessa, 3/4 left, low", subs)))
	var b := JSON.stringify(LensSolver.to_json(LensSolver.solve_words("mcu on vessa, 3/4 left, low", subs)))
	_ok(a == b, "solver deterministic")


func _conventions() -> void:
	var subs := {"vessa": LensSolver.subject(Vector3.ZERO, 0.0, 1.9)}
	var l := LensSolver.solve_words("mcu on vessa, 3/4 left, center", subs)
	_ok((l["pos"] as Vector3).x > 0.5 and (l["pos"] as Vector3).z > 0.5, "3/4-left = camera on the subject's left (+X when facing +Z)")
	var lo := LensSolver.solve_words("ms on vessa, low", subs)
	var hi := LensSolver.solve_words("ms on vessa, high", subs)
	_ok((lo["pos"] as Vector3).y < (hi["pos"] as Vector3).y, "low below high")
	var tl := LensSolver.solve_words("ms on vessa, thirds-left", subs)
	_ok(absf((tl["head_ndc"]["vessa"] as Vector2).x + 1.0 / 3.0) < 0.03, "thirds-left puts the head on the left third")
	var p := LensSolver.solve_words("ms on vessa, push 0.3", subs)
	var da := (p["a"]["pos"] as Vector3).distance_to(p["a"]["look"])
	var db := (p["b"]["pos"] as Vector3).distance_to(p["b"]["look"])
	_ok(absf(db / da - 0.7) < 0.01, "push 0.3 = camera b 30 % closer")


func _contract() -> void:
	var c := LensSolver.solve_words("mcu on vessa, 3/4 left", {"vessa": LensSolver.subject(Vector3.ZERO, 0.0)})
	var js := LensSolver.to_json(c, "L1")
	for k: String in ["pos", "look", "fov", "a", "b"]:
		_ok(js.has(k), "CameraSpec key " + k)
	for k2: String in ["pos", "look", "fov"]:
		_ok((js["a"] as Dictionary).has(k2) and (js["b"] as Dictionary).has(k2), "CameraSpec a/b key " + k2)
	var path := "user://lens_test_camera.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(js))
	f.close()
	var back: Variant = LensSolver.from_json(path)
	_ok(back is Dictionary and (back["a"]["pos"] as Vector3).distance_to(c["a"]["pos"]) < 0.001, "camera.json round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _doc() -> void:
	var d := LensDoc.from_text("""subject vessa res://art/units/wizards/vessa.tscn at=(0,0,0) yaw=0
shot A "mcu on vessa, 3/4 left"
shot B
  frame ms on vessa angle=3/4-right height=low comp=thirds-left
""", "t.lens")
	_ok(d.ok(), "valid spec parses: " + "; ".join(d.spec.error_lines()))
	_ok(d.shots.size() == 2 and (d.shots[1]["parsed"] as Dictionary)["comp"] == "thirds-left", "frame line = words")
	var bad := LensDoc.from_text("""subject shade res://art/units/wizards/vesa.tscn
subject vessa res://art/units/wizards/vessa.tscn
shoot A "mcu on vessa"
shot B "mcu on torvlad"
""", "bad.lens")
	var lines := "\n".join(bad.spec.error_lines())
	_ok(bad.spec.errors.size() >= 3, "3 errors in the bad spec: " + lines)
	_ok("bad.lens:1" in lines and "vessa.tscn" in lines, "missing scene names the file / line and a nearby scene")
	_ok("did you mean \"shot\"" in lines, "unknown keyword -> did you mean shot")
	_ok("bad.lens:4" in lines and "unknown subject \"torvlad\"" in lines and "subjects: vessa" in lines, "unknown subject on its line")


func _measure() -> void:
	var img := Image.create(100, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	img.fill_rect(Rect2i(20, 10, 30, 40), Color.WHITE)
	var st := LensMeasure.mask_stats(img, false, Rect2i(0, 20, 100, 20))
	_ok(st["count"] == 1200 and st["bbox"] == Rect2i(20, 10, 30, 40) and st["inside"] == 600, "mask stats")
	var beauty := Image.create(100, 60, false, Image.FORMAT_RGBA8)
	beauty.fill(Color(0.1, 0.1, 0.1))
	beauty.fill_rect(Rect2i(20, 10, 30, 40), Color(0.9, 0.8, 0.7))
	var ct := LensMeasure.contrast(beauty, LensMeasure.mask_of(img), st["bbox"])
	_ok(float(ct["lum_ratio"]) > 5.0 and float(ct["delta_e"]) > 40.0, "contrast of a light subject on dark")
	_ok(is_equal_approx(LensSolver.band_frac(Vector2i(1600, 900)), 1600.0 / 2.39 / 900.0) and LensSolver.band_frac(Vector2i(3440, 1440)) > 0.99, "band fraction")


func _model() -> void:
	var m: Node3D = (load("res://art/units/wizards/vessa.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await create_timer(0.5).timeout
	var s := LensSolver.subject_of(m, 0.0)
	var head: AABB = s["head"]
	var body: AABB = s["aabb"]
	_ok(head.size.y > 0.1 and body.encloses(head.grow(-0.02)), "Head pivot measured inside the body")
	_ok((s["head_pts"] as PackedVector3Array).size() >= 24, "head vertices sampled")
	var c := LensSolver.solve_words("cu on vessa, 3/4 right", {"vessa": s})
	_ok(c["ok"] and absf(float(c["pred_s"]) / float(c["target_s"]) - 1.0) < 0.03, "model cu solves to its target")
	m.queue_free()
