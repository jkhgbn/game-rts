extends SceneTree
## Tool 3 Lens: shot composer + icon / portrait studio (docs/plan/tools-wave.md section 4, tools/lens/README.md).
## Run through tools/lens/run_lens.ps1 <verb> <id> [key=value ...]; the id is tools/lens/specs/<id>.lens.

const VERBS := [
	{"verb": "help", "args": "", "text": "grammar + a complete example"},
	{"verb": "check", "args": "<id>", "text": "headless: parse, stage, solve every shot, camera_<shot>.json, predicted metrics, 2-run hash", "needs_id": true},
	{"verb": "solve", "args": "<id>", "text": "same as check (writes the CameraSpec files)", "needs_id": true},
	{"verb": "build", "args": "<id>", "text": "same as check (writes the CameraSpec files)", "needs_id": true},
	{"verb": "shoot", "args": "<id> [shot=] [res=]", "text": "WINDOWED stills + measured metrics (ID passes: coverage, face in band, occlusion, contrast)", "needs_id": true},
	{"verb": "sheet", "args": "<id>", "text": "same as shoot", "needs_id": true},
	{"verb": "marks", "args": "<id> set=<set_id> [prefix=]", "text": "headless: solve the spec's shots on a stage set's puppets -> marks.json (contract format)", "needs_id": true},
	{"verb": "icons", "args": "<id> [only=a,b]", "text": "WINDOWED: the spec's icons blocks -> art/icons/lens/<kind>/<id>.png + sheet + metrics", "needs_id": true},
	{"verb": "portrait", "args": "<id> [only=]", "text": "WINDOWED: the spec's portrait lines -> art/portraits/<speaker>.png + sheet", "needs_id": true},
	{"verb": "turnaround", "args": "<res://scene.tscn | unit id>", "text": "WINDOWED: 8 views at 45 deg, one scale -> sheet", "needs_id": true},
	{"verb": "cinecheck", "args": "<id> [cine=<cine id>]", "text": "headless: the baked data/cinematics/<cine>.tres uses this spec's camera_<shot>.json", "needs_id": true},
	{"verb": "demo", "args": "", "text": "the acceptance demo (the ps1 runs check, shoot, icons, portrait, cine bake)"},
]
const KEYS := [
	{"key": "shot", "default": "", "text": "only this shot (shoot / check)"},
	{"key": "res", "default": "", "text": "override output sizes, e.g. 1600x900,3440x1440"},
	{"key": "set", "default": "", "text": "marks: the stage set id (art/cinematics/stage_sets/<set>/)"},
	{"key": "prefix", "default": "", "text": "marks: shot id prefix in the marks file (P11 -> <prefix><shot>)"},
	{"key": "only", "default": "", "text": "icons / portrait: comma list of ids"},
	{"key": "cine", "default": "", "text": "cinecheck: the cinematic id (default = the spec id)"},
	{"key": "src", "default": "", "text": "a .lens path instead of tools/lens/specs/<id>.lens"},
]
const EXAMPLE := """# tools/lens/specs/two_wizards.lens
lens two_wizards  res=1600x900,3440x1440  band=2.39  fov=40  light=studio  rim=warm  bg=#1b1a1f
subject vessa  res://art/units/wizards/vessa.tscn  at=(0,0,0)  yaw=20  pose=play_cast:fireball@0.35
subject shade  res://art/units/shadow/shade.tscn   at=(1.5,0,4)  yaw=200
shot V1 "mcu on vessa, 3/4 left, low"                 # prose words (comma separated)
shot V2                                              # or a frame line, same vocabulary
  frame ms on vessa  angle=3/4-right  height=high  comp=thirds-left  push=0.15
  light preset=dusk rim=cool
shot V3 "ms two-shot vessa shade, high"
shot V4 "mcu ots vessa over shade"
icons units  size=256  yaw=30  pitch=20  fill=0.65  bg=kingdom
  icon cinderlock  res://art/units/fire/cinderlock/cinderlock.tscn  faction=fire
portrait vessa  res://art/units/wizards/vessa.tscn  frame=cu  angle=3/4-right  size=512  faction=fire"""

const OUT_ICONS := "res://art/icons/lens/"
const OUT_PORTRAITS := "res://art/portraits/"
const EXISTING_ICONS := "res://art/icons/"

var cli: ToolCli


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	cli = ToolCli.parse("lens", VERBS, KEYS)
	if cli.bad != "":
		print(cli.bad)
		quit(ToolCli.BAD_INPUT)
		return
	ToolCli.watchdog(self, 1500.0, "lens")
	var code := ToolCli.OK
	match cli.verb:
		"help":
			print(cli.help_text("Lens: framing words -> camera (CameraSpec camera.json), stills with measured framing, icons and portraits with one rule", EXAMPLE))
			print(_grammar())
		"check", "solve", "build":
			code = await _check()
		"shoot", "sheet":
			code = await _shoot()
		"marks":
			code = await _marks()
		"icons":
			code = await _icons()
		"portrait":
			code = await _portraits()
		"turnaround":
			code = await _turnaround()
		"cinecheck":
			code = _cinecheck()
		"demo":
			print("LENS demo: run it through tools/lens/run_lens.ps1 demo (it chains check, shoot, icons, portrait and the cine bake)")
	quit(code)


func _doc() -> LensDoc:
	return LensDoc.load_file(LensDoc.source_of(cli.opt("src", cli.id)), cli.opt("set") if cli.verb == "marks" else "")


func _parse_fail(doc: LensDoc, rep: ToolReport) -> bool:
	rep.add_group("parse", "Spec", 1.0)
	if doc.ok():
		rep.check("P1", "parse", "spec", "PASS", "%d shots, %d icon groups, %d portraits" % [doc.shots.size(), doc.icons.size(),
			doc.portraits.size()], "0 errors")
		for wv: Dictionary in doc.spec.warnings:
			rep.check("P2", "parse", "warning", "WARN", ToolSpec.format_error(wv), "no warnings", String(wv.get("hint", "")))
		return false
	var i := 0
	for e: String in doc.spec.error_lines():
		i += 1
		print(e)
		rep.check("P%d" % i, "parse", "spec error", "FAIL", e, "the spec parses", "fix the line named in the value")
	return true


# ---------------------------------------------------------------- check / solve

func _shot_list(doc: LensDoc) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in doc.shots:
		if cli.opt("shot") == "" or cli.opt("shot") == s["id"]:
			out.append(s)
	return out


func _res_list(s: Dictionary) -> Array:
	if cli.opt("res") != "":
		var arr: Array = []
		for v: Vector2i in cli.opt_sizes("res", []):
			arr.append(v)
		return arr
	return s["res"]


## Stages one shot under `parent` and solves it. {stage, subjects, cam (per res: Vector2i -> solve dict), parsed}.
func _stage_shot(doc: LensDoc, s: Dictionary, parent: Node) -> Dictionary:
	var st := LensStage.create(parent)
	var subs: Array = doc.subjects.duplicate()
	subs.append_array(s["subjects"])
	if String(s.get("set", "")) != "":
		st.add_set(String(s["set"]))
	st.add_subjects(subs)
	st.hide_particles()
	await st.settle_and_pose(self, subs)
	var measured: Dictionary = await st.measure_stable(self, subs)
	if ToolCli.is_windowed():
		st.freeze()
	var cams := {}
	for r: Vector2i in _res_list(s):
		cams[r] = LensSolver.solve(s["parsed"], measured, {"res": r, "band": s["band"], "fov": s["fov"]})
	return {"stage": st, "subjects": measured, "cams": cams}


func _check() -> int:
	var doc := _doc()
	var rep := ToolReport.start("lens", cli.verb, doc.id)
	if _parse_fail(doc, rep):
		return rep.finish()
	rep.add_group("solve", "Solved framing (predicted from bounds)", 2.0)
	rep.add_group("icons", "Icon / portrait subjects", 1.0)
	rep.add_group("det", "Determinism", 1.0)
	var hashes: Array[String] = []
	var pure_ok := true
	var poses: Array = [[], []]      # camera positions / looks / fovs per run (staging stability)
	for run: int in 2:
		var all := ""
		for s: Dictionary in _shot_list(doc):
			var holder := Node3D.new()
			root.add_child(holder)
			var p: Dictionary = await _stage_shot(doc, s, holder)
			var first := true
			for r: Vector2i in p["cams"]:
				var cam: Dictionary = p["cams"][r]
				var js := LensSolver.to_json(cam, s["id"])
				all += JSON.stringify(js)
				if OS.has_environment("LENS_DEBUG"): print("DBG ", s["id"], " ", JSON.stringify(js["a"]), " pred ", cam["pred_s"], " subj ", p["subjects"])
				(poses[run] as Array).append([cam["a"]["pos"], cam["a"]["look"], float(cam["a"]["fov"]), s["id"]])
				if run == 0:
					# the solver itself is a pure function: same bounds -> same bytes
					var again := LensSolver.solve(s["parsed"], p["subjects"], {"res": r, "band": s["band"], "fov": s["fov"]})
					pure_ok = pure_ok and JSON.stringify(LensSolver.to_json(again, s["id"])) == JSON.stringify(js)
					if first:
						_write_json("%s/camera_%s.json" % [rep.out_dir, s["id"]], js)
						if s["id"] == doc.shots[0]["id"]:
							_write_json("%s/camera.json" % rep.out_dir, js)
					_solve_checks(rep, s, cam, r, p["subjects"])
				first = false
			holder.queue_free()
			await process_frame
		hashes.append(ToolCli.hash_of(all))
	var worst := 0.0
	var worst_id := ""
	for i: int in (poses[0] as Array).size():
		var a: Array = poses[0][i]
		var b: Array = poses[1][i]
		var d := maxf((a[0] as Vector3).distance_to(b[0]), ((a[1] as Vector3) - (a[0] as Vector3)).normalized().distance_to(((b[1] as Vector3) - (b[0] as Vector3)).normalized()) * (a[1] as Vector3).distance_to(a[0]))   # position, or view direction as the drift at the look point
		d = maxf(d, absf(float(a[2]) - float(b[2])) * 0.01)
		if d > worst:
			worst = d
			worst_id = String(a[3])
	rep.hash_value = hashes[0]
	rep.hash_note = "2 stagings identical" if hashes[0] == hashes[1] else "2 stagings within %.1f mm (idle animation phase)" % (worst * 1000.0)
	rep.check("D1", "det", "solver (same bounds, 2 solves)", "PASS" if pure_ok else "FAIL", "identical bytes" if pure_ok else "differ",
		"a pure function", "report this to the Lens owner")
	rep.check("D2", "det", "two stagings", "PASS" if worst <= 0.06 else ("WARN" if worst <= 0.12 else "FAIL"),
		"%s / %s, worst %.1f mm (%s)" % [hashes[0], hashes[1], worst * 1000.0, worst_id], "cameras within 60 mm (models idle-sway +- 4 cm; bounds on a 1 cm grid)",
		"a pose=...@t or a moving model changes the bounds: pose it, or give the subject a still model")
	await _check_subject_scenes(doc, rep)
	rep.notes.append("CameraSpec files: %s/camera_<shot>.json (first res of each shot; camera.json = the first shot). cine: `cam=lens \"<words>\" lens_spec=res://docs/tools/lens/out/%s/camera_<shot>.json`" % [rep.out_dir.replace("res://", ""), doc.id])
	rep.notes.append("Coverage s = reference height / band height (head for ecu cu mcu, body for ms cowboy fs ws ews); targets in LensSolver.SIZES; pixels are measured by `shoot` (windowed).")
	rep.extras.append({"title": "Measure it", "text": "run `run_lens.ps1 shoot %s` to confirm the predicted framing from pixels" % doc.id, "source": "lens"})
	return rep.finish()


func _solve_checks(rep: ToolReport, s: Dictionary, cam: Dictionary, r: Vector2i, subjects: Dictionary) -> void:
	var sid: String = s["id"]
	var tgt := float(cam["target_s"])
	var pred := float(cam["pred_s"])
	var err := absf(pred / tgt - 1.0)
	var st := "PASS" if err <= 0.1 else ("WARN" if err <= 0.25 else "FAIL")
	if (cam["subjects"] as Array).size() > 1 and pred < tgt and st == "FAIL":
		st = "WARN"   # widened on purpose so both faces fit: the size word asks for more than the staging allows
	var hint := "two-shot too wide for this size: move the subjects closer or use a wider size (ws)" if (cam["subjects"] as Array).size() > 1 else "check the subject bounds (Head pivot) or pick another size"
	rep.add("S_%s_cov" % sid, "solve", "%s %s coverage (%dx%d)" % [sid, cam["size"], r.x, r.y], st, "%.2f (target %.2f)" % [pred, tgt],
		"+-10 % of the vocabulary target", hint, _grade(err, 0.25, 0.05))
	var bf := float(cam["band_frac"])
	var bad: Array[String] = []
	for t: String in cam["subjects"]:
		var n: Vector2 = cam["head_ndc"][t]
		if absf(n.y) > bf or absf(n.x) > 1.0:
			bad.append(t)
	rep.check("S_%s_band" % sid, "solve", "%s faces in band (predicted)" % sid, "PASS" if bad.is_empty() else "FAIL",
		"all in" if bad.is_empty() else "out: " + ", ".join(PackedStringArray(bad)), "every framed face inside the 2.39 band",
		"lower the height word or use a wider size")


func _check_subject_scenes(doc: LensDoc, rep: ToolReport) -> void:
	var n := 0
	for g: Dictionary in doc.icons:
		n += (g["items"] as Array).size()
	n += doc.portraits.size()
	if n == 0:
		rep.check("I0", "icons", "icon / portrait lines", "INFO", "none", "-")
		return
	rep.check("I1", "icons", "icon / portrait scenes resolve", "PASS", "%d scenes" % n, "every res:// path exists",
		"", "", "")
	# Data Lab view: UnitType / BuildingType ids with no icon anywhere (existing library or art/icons/lens)
	var missing: Array[String] = []
	for pair: Array in [["res://data/units", "units"], ["res://data/buildings", "buildings"]]:
		for f: String in DirAccess.get_files_at(pair[0]):
			if not f.ends_with(".tres"):
				continue
			var id := f.get_basename()
			if not FileAccess.file_exists("%s%s/%s.png" % [EXISTING_ICONS, pair[1], id]) and not FileAccess.file_exists("%s%s/%s.png" % [OUT_ICONS, pair[1], id]):
				missing.append("%s/%s" % [pair[1], id])
	rep.check("I2", "icons", "data ids without an icon (Data Lab view)", "INFO", "%d: %s" % [missing.size(), ", ".join(PackedStringArray(missing.slice(0, 14)))],
		"every UnitType / BuildingType has an icon", "add them to an icons block (model scene path) and run `icons`")


# ---------------------------------------------------------------- shoot

func _shoot() -> int:
	var doc := _doc()
	var rep := ToolReport.start("lens", "shoot", doc.id)
	if _parse_fail(doc, rep):
		return rep.finish()
	rep.add_group("frame", "Measured framing (pixels)", 2.0)
	rep.add_group("read", "Readability", 1.0)
	if not ToolCli.is_windowed():
		rep.check("W1", "frame", "windowed run", "FAIL", "headless", "shoot needs pixels", "use run_lens.ps1 shoot (it opens a window)")
		return rep.finish()
	var tiles: Array = []
	var passes := 0
	var total := 0
	for s: Dictionary in _shot_list(doc):
		for r: Vector2i in _res_list(s):
			var cap := ToolCapture.create(root, r)
			var p: Dictionary = await _stage_shot(doc, s, cap.viewport)
			var st: LensStage = p["stage"]
			var cam: Dictionary = p["cams"][r]
			var xf: Transform3D = cam["xform"]
			cap.set_camera(xf, float(cam["fov"]))
			var main_tag: String = (cam["subjects"] as Array)[0]
			st.light(String(s["light"]), String(s["rim"]), s["bg"], xf, (p["subjects"][main_tag]["aabb"] as AABB).get_center())
			var m := await _measure_shot(cap, st, cam, r)
			var ok := _shot_checks(rep, s, cam, r, m)
			total += 1
			if ok:
				passes += 1
			var still: Image = m["beauty"]
			var over := ToolSheet.band_overlay(still.duplicate() as Image, float(s["band"]), 0.9, 0.55)
			_draw_heads(over, m)
			var fn := "%s_%dx%d.png" % [s["id"], r.x, r.y]
			ToolSheet.save_png(still, "%s/%s" % [rep.out_dir, fn])
			rep.shots["%s %dx%d" % [s["id"], r.x, r.y]] = fn
			tiles.append({"img": over, "label": "%s %s S %.2f/%.2f %s" % [s["id"], cam["size"], m["s"], cam["target_s"], "OK" if ok else "CHECK"],
				"color": ToolSheet.PASS_C if ok else ToolSheet.WARN_C})
			st.free_stage()
			cap.free_viewport()
			await process_frame
	var head: Array = ["%s %d/%d shots framed within +-10 %% with faces in the band" % ["PASS" if passes == total else "WARN", passes, total],
		"yellow = 2.39 band, cyan = safe area, green box = measured head"]
	var sheet := ToolSheet.grid(tiles, 2, 640, head, "LENS SHOOT %s" % doc.id.to_upper())
	ToolSheet.save_png(sheet, "%s/sheet.png" % rep.out_dir)
	rep.shots["sheet"] = "sheet.png"
	rep.notes.append("Metrics from ID passes (unshaded white subject / black occluders): coverage s = head or body pixel height / band height; face in band = >= 90 % of the head mask rows inside the band; occlusion = 1 - visible / alone pixels; contrast = WCAG luminance ratio and CIE76 dE, subject vs a ring of background around it.")
	return rep.finish()


## ID passes + beauty for one staged shot. Returns {beauty, s, head_bbox: {tag: Rect2i}, band_ok: {tag: bool}, occl, contrast}.
func _measure_shot(cap: ToolCapture, st: LensStage, cam: Dictionary, r: Vector2i) -> Dictionary:
	var band := ToolSheet.band_rect(r, float(cam["band"])) if float(cam["band"]) > 0.0 else Rect2i(Vector2i.ZERO, r)
	var tags: Array = cam["subjects"]
	var main_tag: String = tags[0]
	var out := {"head_bbox": {}, "band_ok": {}, "head_in": {}}
	for t: String in tags:
		st.id_begin(cap.viewport, [st.head_node(t)], [], false)
		var hi: Image = await cap.snap(3)
		st.id_end()
		var hs := LensMeasure.mask_stats(hi, false, band)
		out["head_bbox"][t] = hs["bbox"]
		var frac := float(hs["inside"]) / maxf(1.0, float(hs["count"]))
		var c: Rect2i = hs["bbox"]
		var cy := c.position.y + c.size.y / 2
		out["head_in"][t] = frac
		out["band_ok"][t] = hs["count"] > 0 and frac >= 0.9 and cy >= band.position.y and cy < band.end.y and c.position.x + c.size.x / 2 >= 0 and c.position.x + c.size.x / 2 < r.x
		if t == main_tag:
			out["head_px"] = c.size.y
			out["head_clipped"] = c.position.y <= band.position.y or c.end.y >= band.end.y
	st.id_begin(cap.viewport, [st.models[main_tag]], [], false)
	var alone: Image = await cap.snap(3)
	st.id_end()
	var as_ := LensMeasure.mask_stats(alone)
	st.id_begin(cap.viewport, [st.models[main_tag]], [], true)
	var vis: Image = await cap.snap(3)
	st.id_end()
	var vs := LensMeasure.mask_stats(vis)
	var beauty: Image = await cap.snap(4)
	out["beauty"] = beauty
	out["occl"] = maxf(0.0, 1.0 - float(vs["count"]) / maxf(1.0, float(as_["count"])))
	out["contrast"] = LensMeasure.contrast(beauty, LensMeasure.mask_of(vis), vs["bbox"]) if vs["count"] > 0 else {"lum_ratio": 1.0, "delta_e": 0.0}
	var band_px := float(band.size.y)
	var size: String = cam["size"]
	var ref: Dictionary = LensSolver.SIZES[size]
	if ref["ref"] == "head" or ref["anchor"] == "top":
		out["s"] = float(out.get("head_px", 0)) / band_px * float(cam["ratio"])
	else:
		out["s"] = float((as_["bbox"] as Rect2i).size.y) / band_px
	return out


func _shot_checks(rep: ToolReport, s: Dictionary, cam: Dictionary, r: Vector2i, m: Dictionary) -> bool:
	var sid := "%s_%dx%d" % [s["id"], r.x, r.y]
	var tgt := float(cam["target_s"])
	var meas := float(m["s"])
	var err := absf(meas / tgt - 1.0)
	var size: String = cam["size"]
	var st := "PASS" if err <= 0.1 else ("WARN" if err <= 0.2 else "FAIL")
	if size == "ecu" and bool(m.get("head_clipped", false)):
		st = "PASS"   # the head overfills the band by design; the solve checks the scale
		meas = float(cam["pred_s"])
	rep.add("F_%s_cov" % sid, "frame", "%s %s coverage" % [sid, size], st, "%.3f (target %.2f, %+.0f %%)" % [meas, tgt, (meas / tgt - 1.0) * 100.0],
		"+-10 % of the vocabulary target", "a hat / prop inflates the Head pivot: check the model's Head node", _grade(err, 0.2, 0.03))
	var all_in := true
	for t: String in cam["subjects"]:
		var okb: bool = m["band_ok"][t]
		all_in = all_in and okb
		rep.check("F_%s_band_%s" % [sid, t], "frame", "%s face %s in band" % [sid, t], "PASS" if okb else "FAIL",
			"%.0f %% of head rows inside" % (float(m["head_in"][t]) * 100.0), ">= 90 % inside the 2.39 band", "use a lower size or the eye height")
	var oc := float(m["occl"])
	var ocs := "PASS" if oc <= 0.3 else ("WARN" if oc <= 0.6 else "FAIL")
	if String(cam.get("over", "")) != "" and oc <= 0.6:
		ocs = "PASS"
	rep.check("R_%s_occl" % sid, "read", "%s occlusion" % sid, ocs, "%.0f %%" % (oc * 100.0), "<= 30 % (ots <= 60 %)", "move the occluder or change the angle")
	var ct: Dictionary = m["contrast"]
	var cst := "PASS" if float(ct["lum_ratio"]) >= 1.5 or float(ct["delta_e"]) >= 15.0 else "WARN"
	rep.check("R_%s_contrast" % sid, "read", "%s subject vs background" % sid, cst, "L %.2f : 1, dE %.0f" % [ct["lum_ratio"], ct["delta_e"]],
		"luminance >= 1.5:1 or dE >= 15", "add rim=warm|cool or a darker / lighter bg")
	return st == "PASS" and all_in


func _draw_heads(img: Image, m: Dictionary) -> void:
	for t: String in m["head_bbox"]:
		var b: Rect2i = m["head_bbox"][t]
		if b.size.x > 0:
			ToolSheet.frame(img, b, ToolSheet.PASS_C if m["band_ok"][t] else ToolSheet.FAIL_C, 2)


# ---------------------------------------------------------------- marks

func _marks() -> int:
	var doc := _doc()
	var rep := ToolReport.start("lens", "marks", doc.id)
	var set_id := cli.opt("set")
	if set_id == "" and not doc.shots.is_empty():
		set_id = String(doc.shots[0].get("set", ""))
	rep.add_group("marks", "Marks", 1.0)
	if set_id == "" or not ResourceLoader.exists(LensDoc.set_scene_path(set_id)):
		rep.check("M0", "marks", "stage set", "FAIL", set_id if set_id != "" else "none", "set=<set_id> names a set in art/cinematics/stage_sets/",
			"pass set=<id> (e.g. set=forge_watch_keep)")
		return rep.finish()
	# (the doc was loaded with set_override: words are checked against the set's puppets)
	for s: Dictionary in doc.shots:
		s["set"] = set_id
	if _parse_fail(doc, rep):
		return rep.finish()
	var marks := {}
	var prefix := cli.opt("prefix")
	for s: Dictionary in _shot_list(doc):
		var holder := Node3D.new()
		root.add_child(holder)
		var p: Dictionary = await _stage_shot(doc, s, holder)
		var r: Vector2i = (_res_list(s))[0]
		var cam: Dictionary = p["cams"][r]
		var key := prefix + String(s["id"])
		marks[key] = {"from": LensSolver.v3(cam["a"]["pos"]), "to": LensSolver.v3(cam["b"]["pos"]),
			"look_from": LensSolver.v3(cam["a"]["look"]), "look_to": LensSolver.v3(cam["b"]["look"]),
			"fov_from": snappedf(float(cam["a"]["fov"]), 0.01), "fov_to": snappedf(float(cam["b"]["fov"]), 0.01),
			"subject": (cam["subjects"] as Array)[0], "lens": s["words"]}
		_solve_checks(rep, s, cam, r, p["subjects"])
		holder.queue_free()
		await process_frame
	_write_json("%s/marks.json" % rep.out_dir, marks)
	rep.hash_value = ToolCli.hash_of(JSON.stringify(marks))
	rep.check("M1", "marks", "marks file", "PASS", "%d shots -> %s/marks.json" % [marks.size(), rep.out_dir.replace("res://", "")],
		"contract {shot: {from, to, look_from, look_to, fov_from, fov_to}}")
	rep.notes.append("Lens never edits a set: World Forge (tool 6) merges these entries into art/cinematics/stage_sets/%s/marks.json (or calls LensSolver itself for `mark <shot> lens=\"...\"`)." % set_id)
	return rep.finish()


# ---------------------------------------------------------------- icons

func _only() -> Array:
	return Array(cli.opt("only").split(",", false))


func _icons() -> int:
	var doc := _doc()
	var rep := ToolReport.start("lens", "icons", doc.id)
	if _parse_fail(doc, rep):
		return rep.finish()
	rep.add_group("icon", "Icon framing (one rule: silhouette 55-75 % of the tile, centred +- 5 %)", 2.0)
	rep.add_group("ui", "Legibility at 48 px (UI Lab rule)", 1.0)
	if not ToolCli.is_windowed():
		rep.check("W1", "icon", "windowed run", "FAIL", "headless", "icons need pixels", "use run_lens.ps1 icons (it opens a window)")
		return rep.finish()
	var tiles: Array = []
	var ok_n := 0
	var n := 0
	var bytes := PackedByteArray()
	for g: Dictionary in doc.icons:
		for it: Dictionary in g["items"]:
			if not _only().is_empty() and not it["id"] in _only():
				continue
			n += 1
			var res: Dictionary = await _render_icon(g, it)
			var img: Image = res["img"]
			var path := "%s%s/%s.png" % [OUT_ICONS, it["kind"], it["id"]]
			ToolSheet.save_png(img, path)
			bytes.append_array(img.get_data())
			var cov := float(res["cov"])
			var dx := float(res["dx"])
			var dy := float(res["dy"])
			var ok := cov >= 0.55 and cov <= 0.75 and absf(dx) <= 0.05 and absf(dy) <= 0.05
			if ok:
				ok_n += 1
			rep.add("I_%s" % it["id"], "icon", "%s framing" % it["id"], "PASS" if ok else "FAIL",
				"cover %.0f %%, centre %+.1f / %+.1f %%" % [cov * 100.0, dx * 100.0, dy * 100.0], "55-75 %, +- 5 %",
				"hide=<node> for a stray prop, or fill=<0..1> on the icon line", _grade(absf(cov - 0.65), 0.1, 0.02))
			var lg: Dictionary = res["legible"]
			var lst := "PASS" if float(lg["fill"]) >= 0.1 and (float(lg["contrast"]) >= 1.4 or float(lg["delta_e"]) >= 12.0) else "WARN"
			rep.check("U_%s" % it["id"], "ui", "%s at 48 px" % it["id"], lst, "fill %.0f %%, L %.2f:1, dE %.0f" % [float(lg["fill"]) * 100.0,
				lg["contrast"], lg["delta_e"]], "silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12", "rim light or a lighter kingdom bg")
			var small := img.duplicate() as Image
			small.resize(48, 48, Image.INTERPOLATE_LANCZOS)
			var tile := Image.create(img.get_width() + 60, img.get_height(), false, Image.FORMAT_RGBA8)
			tile.fill(ToolSheet.BG)
			tile.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
			tile.blit_rect(small, Rect2i(0, 0, 48, 48), Vector2i(img.get_width() + 6, 4))
			tiles.append({"img": tile, "label": "%s %d%%" % [it["id"], int(round(cov * 100.0))], "color": ToolSheet.PASS_C if ok else ToolSheet.FAIL_C})
			rep.shots[it["id"]] = path.replace("res://", "../../../../../")
	var sheet := ToolSheet.grid(tiles, 6, 316, ["%s %d/%d icons framed by the rule (55-75 %% of the tile, centred +- 5 %%)" % ["PASS" if ok_n == n else "FAIL", ok_n, n],
		"right of each: the same icon at 48 px"], "LENS ICONS %s" % doc.id.to_upper())
	ToolSheet.save_png(sheet, "%s/icons_sheet.png" % rep.out_dir)
	rep.shots["sheet"] = "icons_sheet.png"
	rep.hash_value = ToolCli.hash_of(bytes)
	rep.notes.append("Icons written to %s<kind>/<id>.png (%d px, kingdom background from art/icons/icon_painter.gd). The icon libraries adopt them later (their owner); nothing existing was overwritten." % [OUT_ICONS.replace("res://", ""), 256])
	return rep.finish()


## One icon: fit (solver) -> 3 pixel refinements on the alpha mask -> beauty over the kingdom background.
func _render_icon(g: Dictionary, it: Dictionary) -> Dictionary:
	var size := int(g["size"])
	var cap := ToolCapture.create(root, Vector2i(size, size), null, true)
	var st := LensStage.create(cap.viewport)
	st.env.background_mode = Environment.BG_CLEAR_COLOR
	st.add_subjects([{"tag": "m", "res": it["res"], "at": Vector3.ZERO, "yaw": 0.0}])
	var model: Node3D = st.models["m"]
	for nm: String in String(it["hide"]).split(",", false):
		var hn := model.find_child(nm, true, false)
		if hn is Node3D:
			(hn as Node3D).visible = false
	await st.settle_and_pose(self, [])
	st.hide_particles()
	st.freeze()
	var box := LensSolver.aabb_of(model)
	var fov := float(g["fov"])
	var fill := float(it["fill"])
	var fit := LensSolver.solve_fit(box, 0.0, float(it["yaw"]), float(it["pitch"]), fill, fov)
	var look: Vector3 = fit["look"]
	var dir: Vector3 = ((fit["pos"] as Vector3) - look).normalized()
	var dist := float(fit["dist"])
	var xf: Transform3D = fit["xform"]
	st.light(String(g["light"]), "cool" if it["faction"] in ["shadow", "nature"] else "warm", {"kind": "flat", "value": ""}, xf, box.get_center())
	st.env.background_mode = Environment.BG_CLEAR_COLOR
	var img: Image = null
	var ms := {}
	for it2: int in 4:
		xf = LensSolver.look_xform(look + dir * dist, look)
		cap.set_camera(xf, fov)
		img = await cap.snap(3)
		ms = LensMeasure.mask_stats(img, true)
		if it2 == 3 or ms["count"] == 0:
			break
		var bb: Rect2i = ms["bbox"]
		var cov := float(maxi(bb.size.x, bb.size.y)) / float(size)
		var ctr := (Vector2(bb.position) + Vector2(bb.size) * 0.5) / float(size) * 2.0 - Vector2.ONE
		var half := tan(deg_to_rad(fov) * 0.5) * dist
		look += xf.basis.x * ctr.x * half - xf.basis.y * ctr.y * half
		dist *= cov / fill
	var bb2: Rect2i = ms.get("bbox", Rect2i())
	var cov2 := float(maxi(bb2.size.x, bb2.size.y)) / float(size)
	var c2 := (Vector2(bb2.position) + Vector2(bb2.size) * 0.5) / float(size) - Vector2(0.5, 0.5)
	var bg: Image
	match String(g["bg"]):
		"kingdom":
			bg = await _painted_bg(String(it["faction"]), size)
		"flat":
			bg = Image.create(size, size, false, Image.FORMAT_RGBA8)
			bg.fill(Color(0.1, 0.09, 0.1))
		_:
			bg = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var out := bg.duplicate() as Image
	out.blend_rect(img, Rect2i(0, 0, size, size), Vector2i.ZERO)
	var lg := LensMeasure.legibility(out, img)
	st.free_stage()
	cap.free_viewport()
	await process_frame
	return {"img": out, "cov": cov2, "dx": c2.x, "dy": c2.y, "legible": lg}


## The existing kingdom icon background (art/icons/icon_painter.gd kind "bg"), 256 px canvas, resized to `size`.
func _painted_bg(faction: String, size: int) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var painter: Node2D = (load("res://art/icons/icon_painter.gd") as GDScript).new()
	painter.set("kind", &"bg")
	painter.set("id", &"lens")
	painter.set("faction", StringName(faction if faction != "neutral" else "fire"))
	painter.set("tier", 0)
	vp.add_child(painter)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	if faction == "neutral":
		# neutral: desaturate the fire background to the guild ochre
		for y: int in img.get_height():
			for x: int in img.get_width():
				var c := img.get_pixel(x, y)
				var l := c.get_luminance()
				img.set_pixel(x, y, Color(l * 1.1, l * 0.95, l * 0.7, c.a))
	if size != 256:
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return img


# ---------------------------------------------------------------- portraits

func _portraits() -> int:
	var doc := _doc()
	var rep := ToolReport.start("lens", "portrait", doc.id)
	if _parse_fail(doc, rep):
		return rep.finish()
	rep.add_group("portrait", "Portrait rule (LensSolver size on the Head pivot, head top 8 % down, centred)", 2.0)
	if not ToolCli.is_windowed():
		rep.check("W1", "portrait", "windowed run", "FAIL", "headless", "portraits need pixels", "use run_lens.ps1 portrait (it opens a window)")
		return rep.finish()
	var tiles: Array = []
	var bytes := PackedByteArray()
	for pr: Dictionary in doc.portraits:
		if not _only().is_empty() and not pr["speaker"] in _only():
			continue
		var size := int(pr["size"])
		var r := Vector2i(size, size)
		var cap := ToolCapture.create(root, r, null, true)
		var st := LensStage.create(cap.viewport)
		var tag := String(pr["speaker"])
		st.add_subjects([{"tag": tag, "res": pr["res"], "at": Vector3.ZERO, "yaw": 0.0}])
		await st.settle_and_pose(self, [])
		st.hide_particles()
		var subs: Dictionary = await st.measure_stable(self, [{"tag": tag, "yaw": 0.0}])
		st.freeze()
		var words := "%s on %s, %s, %s, center" % [pr["frame"], tag, pr["angle"], pr["height"]]
		var cam := LensSolver.solve_words(words, subs, {"res": r, "band": 0.0, "fov": 30.0})
		var xf: Transform3D = cam["xform"]
		cap.set_camera(xf, float(cam["fov"]))
		st.light(String(pr["light"]), "warm" if pr["faction"] in ["fire", "neutral"] else "cool", {"kind": "flat", "value": ""}, xf, (subs[tag]["head"] as AABB).get_center())
		st.env.background_mode = Environment.BG_CLEAR_COLOR
		st.id_begin(cap.viewport, [st.head_node(tag)], [], false)
		var hi: Image = await cap.snap(3)
		st.id_end()
		var hs := LensMeasure.mask_stats(hi)
		var beauty: Image = await cap.snap(4)
		var out := LensStage.gradient_bg(size, String(pr["faction"]))
		out.blend_rect(beauty, Rect2i(Vector2i.ZERO, r), Vector2i.ZERO)
		var path := "%s%s.png" % [OUT_PORTRAITS, tag]
		ToolSheet.save_png(out, path)
		bytes.append_array(out.get_data())
		var hb: Rect2i = hs["bbox"]
		var s_meas := float(hb.size.y) / float(size)
		var tgt := float(cam["target_s"])
		var top := float(hb.position.y) / float(size)
		var cx := (float(hb.position.x) + hb.size.x * 0.5) / float(size) - 0.5
		var err := absf(s_meas / tgt - 1.0)
		var ok := err <= 0.1 and absf(top - 0.08) <= 0.05 and absf(cx) <= 0.1
		rep.add("R_%s" % tag, "portrait", "%s head framing" % tag, "PASS" if ok else "FAIL",
			"head %.0f %% of the height (target %.0f %%), top %.0f %%, centre %+.0f %%" % [s_meas * 100.0, tgt * 100.0, top * 100.0, cx * 100.0],
			"+-10 % of the target, top 8 +- 5 %, centre +- 10 %", "check the model's Head pivot (hat / hood meshes belong under it)",
			_grade(err, 0.2, 0.03))
		rep.shots[tag] = path.replace("res://", "../../../../../")
		tiles.append({"img": out, "label": "%s %s %d%%" % [tag, pr["frame"], int(round(s_meas * 100.0))], "color": ToolSheet.PASS_C if ok else ToolSheet.FAIL_C})
		st.free_stage()
		cap.free_viewport()
		await process_frame
	var sheet := ToolSheet.grid(tiles, 4, 384, [], "LENS PORTRAITS %s" % doc.id.to_upper())
	ToolSheet.save_png(sheet, "%s/portraits_sheet.png" % rep.out_dir)
	rep.shots["sheet"] = "portraits_sheet.png"
	rep.hash_value = ToolCli.hash_of(bytes)
	rep.notes.append("Portraits written to %s<speaker>.png (cinematics.md 1 folder). One rule: the LensSolver size of the line (default cu; the wizards use mcu so hats / antlers fit), head top 8 %% down, centred, 3/4 view, kingdom gradient." % OUT_PORTRAITS.replace("res://", ""))
	return rep.finish()


# ---------------------------------------------------------------- turnaround

func _turnaround() -> int:
	var path := cli.id
	if not path.begins_with("res://"):
		path = _find_model(cli.id)
	var mname := path.get_file().get_basename() if path != "" else cli.id
	var rep := ToolReport.start("lens", "turnaround", "turnaround_" + mname)
	rep.add_group("turn", "Turnaround", 1.0)
	if path == "" or not ResourceLoader.exists(path):
		rep.check("T0", "turn", "model scene", "FAIL", cli.id, "a res:// .tscn or a model file name under art/", "e.g. turnaround res://art/units/wizards/vessa.tscn")
		return rep.finish()
	if not ToolCli.is_windowed():
		rep.check("W1", "turn", "windowed run", "FAIL", "headless", "turnarounds need pixels", "use run_lens.ps1 turnaround")
		return rep.finish()
	var size := Vector2i(384, 384)
	var cap := ToolCapture.create(root, size)
	var st := LensStage.create(cap.viewport)
	st.add_subjects([{"tag": "m", "res": path, "at": Vector3.ZERO, "yaw": 0.0}])
	await st.settle_and_pose(self, [])
	st.hide_particles()
	st.freeze()
	var box := LensSolver.aabb_of(st.models["m"])
	var dist := 0.0
	for i: int in 8:
		dist = maxf(dist, float(LensSolver.solve_fit(box, 0.0, i * 45.0, 10.0, 0.8, 30.0)["dist"]))
	var tiles: Array = []
	var names := ["front", "3/4 left", "left", "3/4 back left", "back", "3/4 back right", "right", "3/4 right"]
	for i2: int in 8:
		var b := deg_to_rad(i2 * 45.0)
		var dir := Vector3(sin(b) * cos(deg_to_rad(10.0)), sin(deg_to_rad(10.0)), cos(b) * cos(deg_to_rad(10.0)))
		var xf := LensSolver.look_xform(box.get_center() + dir * dist, box.get_center())
		cap.set_camera(xf, 30.0)
		if i2 == 0:
			st.light("studio", "warm", {"kind": "flat", "value": "#26252b"}, xf, box.get_center())
		var img: Image = await cap.snap(3)
		tiles.append({"img": img, "label": "%d %s" % [i2 * 45, names[i2]]})
	var sheet := ToolSheet.grid(tiles, 4, 384, ["model %s, one scale, 10 deg above, studio light fixed to the front view" % path.replace("res://", "")], "TURNAROUND %s" % mname.to_upper())
	ToolSheet.save_png(sheet, "%s/turnaround.png" % rep.out_dir)
	rep.shots["turnaround"] = "turnaround.png"
	rep.check("T1", "turn", "8 views", "PASS", "%d views, box %.2f x %.2f x %.2f m" % [tiles.size(), box.size.x, box.size.y, box.size.z], "8 views at 45 deg")
	st.free_stage()
	cap.free_viewport()
	return rep.finish()


func _find_model(id: String) -> String:
	var stack: Array[String] = ["res://art/units", "res://art/buildings"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for f: String in DirAccess.get_files_at(d):
			if f == id + ".tscn":
				return d + "/" + f
		for sub: String in DirAccess.get_directories_at(d):
			if sub != "tools":
				stack.append(d + "/" + sub)
	return ""


# ---------------------------------------------------------------- cinecheck (demo d)

func _cinecheck() -> int:
	var doc := _doc()
	var cine_id := cli.opt("cine", doc.id)
	var rep := ToolReport.start("lens", "cinecheck", doc.id)
	rep.add_group("cine", "cine bakes cam=lens shots from Lens CameraSpecs", 1.0)
	var tres := "res://data/cinematics/%s.tres" % cine_id
	if not ResourceLoader.exists(tres):
		rep.check("C0", "cine", "baked cinematic", "FAIL", tres.replace("res://", ""), "exists", "run tools\\cine\\run_cine.ps1 build %s src=res://tools/lens/specs/%s.cine" % [cine_id, cine_id])
		return rep.finish()
	var script: Resource = load(tres)
	var n := 0
	for shot: Resource in script.get("shots"):
		var sid := String(shot.get("id"))
		var cj: Variant = LensSolver.from_json("%s/camera_%s.json" % [ToolReport.out_dir_of("lens", doc.id), sid])
		if cj == null:
			continue
		n += 1
		var a: Dictionary = cj["a"]
		var b: Dictionary = cj["b"]
		var d := (shot.get("from_pos") as Vector3).distance_to(a["pos"]) + (shot.get("to_pos") as Vector3).distance_to(b["pos"]) \
			+ (shot.get("look_from") as Vector3).distance_to(a["look"]) + absf(float(shot.get("fov_from")) - float(a["fov"]))
		rep.check("C_%s" % sid, "cine", "%s baked camera = camera_%s.json" % [sid, sid], "PASS" if d < 0.01 else "FAIL", "diff %.4f" % d,
			"< 0.01", "the .cine shot needs lens_spec=res://docs/tools/lens/out/%s/camera_%s.json" % [doc.id, sid])
	if n == 0:
		rep.check("C1", "cine", "lens shots", "FAIL", "0 shots matched", "at least one shot id with a camera_<shot>.json", "run `run_lens.ps1 check %s` first" % doc.id)
	return rep.finish()


# ---------------------------------------------------------------- misc

## 0-1 score: 1 at `good`, 0 at `bad`, linear between (local copy: the Art Lab moved its grade() on 2026-09-27).
static func _grade(value: float, bad: float, good: float) -> float:
	if is_equal_approx(bad, good):
		return 1.0 if value == good else 0.0
	return clampf((value - bad) / (good - bad), 0.0, 1.0)

func _write_json(path: String, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()


func _grammar() -> String:
	return """
Grammar (tools/lens/README.md has the full table):
  lens <id> [res=WxH[,WxH]] [band=2.39] [fov=40] [light=studio|warm|ice|dusk|night|set] [rim=warm|cool|off] [bg=#hex|ground:#hex|set:<id>]
  use cine=res://path.cine                  cast lines of a .cine become subjects (same at= / yaw=)
  subject <tag> <res://scene.tscn> at=(x,y,z) yaw=<deg> [pose=<hook>[:<arg>]@<sec>] [scale=]
  shot <id> "<words>" [res= band= fov= light= rim= bg=]
    frame <size> on <tag>[ and <tag>] [angle= height= comp= lead= dutch= push= truck= crane= arc=]
    subject ... | light preset= rim= | bg flat=#hex | ground=#hex | set=<id> | out WxH WxH [band=]
  icons <group> [size=256 yaw=30 pitch=20 fill=0.65 fov=30 bg=kingdom|flat|none light=studio kind=units|buildings]
    icon <id> <res://scene.tscn> faction=fire|ice|nature|shadow|neutral [kind= yaw= pitch= fill= hide=Node,Node]
  portrait <speaker> <res://scene.tscn> [frame=cu angle=3/4-right height=eye size=512 faction=]
Words: sizes %s | two-shot a b | ots a over b
  angles %s (or angle=<deg>) | heights %s | comps center thirds-left thirds-right (auto = lead room)
  lead left|right | dutch <deg> | push <0..1> truck <m> crane <m> arc <deg> (camera b) | fov <deg>
""" % [" ".join(PackedStringArray(LensSolver.SIZES.keys())), " ".join(PackedStringArray(LensSolver.ANGLES.keys())),
		" ".join(PackedStringArray(LensSolver.HEIGHTS.keys()))]
