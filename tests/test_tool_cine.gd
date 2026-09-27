extends SceneTree
## Test of tools wave tool 2 `cine` + the shared base tools/common/ (docs/plan/tools-wave.md sections 1 and 3).
## Run: godot --headless --path . -s tests/test_tool_cine.gd --fixed-fps 60 --quit-after 6000
## Prints "PASS tool_cine" or "FAIL tool_cine: <reasons>".

const TASK_ID := "tool_cine"

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fails.append(what)
		print("  x " + what)


func _run() -> void:
	_test_spec()
	_test_cli()
	_test_report()
	_test_sheet()
	_test_doc_errors()
	await _test_pipeline()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _test_spec() -> void:
	var s := ToolSpec.parse_text("""# comment
set forge_x  size=40x30 tint=#ff8800  name="two words"   # trailing comment
place res://a.tscn at=(-8, 0, -10) yaw=30
  child @mark 38>32 14..20 "quoted arg"
scatter kit area=ring((0,0),14..20) poly=[(-20,5),(0,3)]
""", "t.spec")
	_ok(s.ok(), "spec parses")
	_ok(s.lines.size() == 3, "3 top-level lines (got %d)" % s.lines.size())
	var l0: ToolSpecLine = s.lines[0]
	_ok(l0.line == 2 and l0.keyword == "set" and l0.arg(0) == "forge_x", "line numbers / keyword / arg")
	_ok(l0.get_str("tint") == "#ff8800" and l0.get_str("name") == "two words", "hex colour not a comment; quoted value")
	var l1: ToolSpecLine = s.lines[1]
	_ok(ToolSpec.vec_of(l1.get_str("at")) == Vector3(-8, 0, -10), "vector with spaces is one token")
	_ok(l1.children.size() == 1 and l1.children[0].line == 4, "indented child block")
	var c: ToolSpecLine = l1.children[0]
	_ok(ToolSpec.kind_of(c.arg(0)) == "marker" and ToolSpec.kind_of(c.arg(1)) == "fromto" and ToolSpec.kind_of(c.arg(2)) == "range", "token kinds")
	_ok(c.arg(3) == "quoted arg" and c.quoted[3], "quoted positional")
	_ok(ToolSpec.fromto("38>32") == PackedStringArray(["38", "32"]) and ToolSpec.range_of("14..20") == Vector2(14, 20), "fromto / range")
	_ok(ToolSpec.list_of(s.lines[2].get_str("poly")).size() == 2, "list_of top-level commas")
	_ok(ToolSpec.nearest("torvlad", ["torvald", "vessa"]) == "torvald", "did you mean")
	s.check_keys(l0, ["size", "tint"])
	_ok(s.errors.size() == 1 and "did you mean" not in String(s.errors[0]["hint"]) and int(s.errors[0]["line"]) == 2, "unknown key error with line")
	_ok(ToolSpec.format_error(s.errors[0]).begins_with("t.spec:2:"), "error line format")


func _test_cli() -> void:
	var verbs := [{"verb": "help"}, {"verb": "check", "needs_id": true}]
	var keys := [{"key": "seed", "default": "0"}]
	var c := ToolCli.parse("x", verbs, keys, PackedStringArray(["check", "abc", "seed=4"]))
	_ok(c.bad == "" and c.verb == "check" and c.id == "abc" and c.opt_int("seed") == 4, "cli parse")
	var c2 := ToolCli.parse("x", verbs, keys, PackedStringArray(["chek", "abc"]))
	_ok("did you mean \"check\"" in c2.bad, "cli verb did-you-mean")
	var c3 := ToolCli.parse("x", verbs, keys, PackedStringArray(["check", "abc", "sed=1"]))
	_ok("did you mean \"seed\"" in c3.bad, "cli key did-you-mean")
	var c4 := ToolCli.parse("x", verbs, keys, PackedStringArray(["check"]))
	_ok("missing <id>" in c4.bad, "cli missing id")
	_ok(ToolCli.hash_of("a") == ToolCli.hash_of("a") and ToolCli.hash_of("a") != ToolCli.hash_of("b"), "hash")


func _test_report() -> void:
	var r := ToolReport.start("cine_test", "check", "unit")
	r.add_group("g", "Group")
	r.check("A", "g", "one", "PASS", 1, "rule")
	r.check("B", "g", "two", "FAIL", 2, "rule", "fix it")
	_ok(r.result() == "FAIL" and r.exit_code() == 1 and r.count("PASS") == 1, "report result / exit code")
	var md := r.to_markdown()
	_ok("## Group" in md and "fix it" in md and "Improve next" in md, "report markdown")
	var dir := "user://tool_cine_test"
	r.write(dir)
	_ok(FileAccess.file_exists(dir.path_join("report.md")) and FileAccess.file_exists(dir.path_join("report.json")), "report files")
	_ok(is_equal_approx(ToolReport.grade(5.0, 0.0, 10.0), 0.5) and ToolReport.budget_status(3.0, {"limit": 2.0, "hard": true}) == "FAIL", "grade / budget_status")
	_ok(r.problem_lines().size() == 1 and r.problem_lines()[0].begins_with("FAIL B"), "problem lines")


func _test_sheet() -> void:
	_ok(ToolSheet.bar_px(Vector2i(1600, 900)) == 115 and ToolSheet.bar_px(Vector2i(3440, 1440)) == 43 and ToolSheet.bar_px(Vector2i(2560, 1080)) == 32, "bar heights 115 / 43 / 32")
	var img := ToolSheet.new_image(100, 30, Color.BLACK)
	var w := ToolSheet.text(img, 2, 2, "AB", Color.WHITE, 2)
	_ok(w == 24 and img.get_pixel(3, 5).r > 0.9, "bitmap text draws")
	var g := ToolSheet.grid([{"img": img, "label": "x"}, {"img": img, "label": "y"}], 2, 100, ["PASS ok"], "T")
	_ok(g.get_width() == 2 * 108 + 8, "grid width")


func _test_doc_errors() -> void:
	var d := CineDoc.from_text("cine t title=\"T\"\nshto S1 2.0\nshot S1 2.0 cam=dolyl\n  at 0.5 lnie vessa \"hi\"\n", "t.cine")
	var lines := d.spec.error_lines()
	_ok(lines.size() == 3, "3 parse errors (got %d: %s)" % [lines.size(), lines])
	_ok(lines.size() >= 3 and "t.cine:2:" in lines[0] and "\"shot\"" in lines[0], "unknown keyword -> did you mean shot")
	_ok(lines.size() >= 3 and "\"dolly\"" in lines[1], "unknown cam mode -> did you mean dolly")
	_ok(lines.size() >= 3 and "t.cine:4:" in lines[2] and "\"line\"" in lines[2], "unknown action -> did you mean line")


func _pipe(id: String) -> Dictionary:
	var doc := CineDoc.load_file(CineDoc.source_of(id))
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc)
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	var rep := ToolReport.start("cine", "check", id)
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, stage, bake, rep)
	CineChecks.timing(doc, bake, ev, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.continuity(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	var h := ToolCli.hash_of(JSON.stringify(bake.to_data(), "", true) + "#" + ev.hash_frames(60))
	return {"doc": doc, "stage": stage, "bake": bake, "ev": ev, "rep": rep, "hash": h}


func _test_pipeline() -> void:
	var a := _pipe("watch_keep")
	var rep: ToolReport = a["rep"]
	_ok(rep.count("FAIL") == 0, "watch_keep 0 FAIL (got %s)" % [rep.problem_lines()])
	_ok(absf((a["ev"] as CineEval).total - 46.0) < 0.01 and (a["bake"] as CineBake).shots.size() == 8, "8 shots, 46 s")
	_ok((a["doc"] as CineDoc).line_count() <= 80, "demo .cine <= 80 lines")
	var framing := rep.checks.filter(func(c: Dictionary) -> bool: return c["group"] == "framing" and c["status"] == "PASS")
	_ok(framing.size() >= 7, "every named face framed (got %d PASS)" % framing.size())
	(a["stage"] as CineStage).queue_free()
	await process_frame
	var b := _pipe("watch_keep")
	_ok(a["hash"] == b["hash"], "two fresh runs hash-identical")
	var res: Resource = (b["bake"] as CineBake).to_resource()
	if ResourceLoader.exists("res://scripts/cinematics/cinematic_shot.gd"):
		_ok(res != null and (res.get(&"shots") as Array).size() == 8, "bakes a CinematicScript with 8 shots")
		if res != null:
			var s2: Resource = (res.get(&"shots") as Array)[1]
			_ok(String(s2.get(&"id")) == "S2" and (s2.get(&"lines") as Array).size() == 1, "shot fields + lines baked")
	(b["stage"] as CineStage).queue_free()
	var c := _pipe("watch_keep_bugs")
	var rc: ToolReport = c["rep"]
	_ok(rc.count("FAIL") == 4, "planted-bug file = exactly 4 FAIL (got %d: %s)" % [rc.count("FAIL"), rc.problem_lines()])
	var joined := "\n".join(rc.problem_lines())
	_ok("axis" in joined and "chars" in joined and "@S8_frm" in joined and "draw_knfe" in joined, "the 4 FAILs are the 4 planted bugs")
	_ok("did you mean \"draw_knife\"" in joined and "did you mean \"@S8_from\"" in joined, "fix hints teach")
	(c["stage"] as CineStage).queue_free()
	await process_frame
	_test_lens_and_puppet_speaker()
	await process_frame


## U2 (2026-09-27): cam=lens without lens_spec= is solved at bake by tool 3's LensSolver (no framer WARN); a set
## puppet (not cast) is a valid speaker.
func _test_lens_and_puppet_speaker() -> void:
	var doc := CineDoc.from_text("""cine lens_t  length=1..20
cast vessa capsule at=(0, 0, 0) yaw=0
shot L1 3.0 cam=lens "mcu on vessa, 3/4 left"
  at 0.5 line grunt "Hold the gate."
""", "lens_t.cine")
	_ok(doc.spec.error_lines().is_empty(), "lens_t parses: %s" % [doc.spec.error_lines()])
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc)
	var grunt := Node3D.new()
	grunt.name = "grunt"
	stage.add_child(grunt)
	stage.actors["grunt"] = grunt   # stands in for a set's Puppets/grunt
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	var rep := ToolReport.start("cine", "check", "lens_t")
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, stage, bake, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	var joined := "\n".join(rep.problem_lines())
	if ResourceLoader.exists("res://tools/lens/lens_solver.gd"):
		_ok(not "cam=lens" in joined, "cam=lens solved at bake (no framer fallback): %s" % joined)
		var b: Dictionary = bake.shots[0]
		_ok(not bool(b["fallback_cam"]) and (b["from_pos"] as Vector3).distance_to(Vector3(0, 1.5, 0)) > 0.5, "lens camera placed: %s" % b["from_pos"])
		_ok("vessa" in (b["faces"] as Array), "lens subject judged by framing")
	_ok(not "not cast" in joined, "set puppet counts as a speaker: %s" % joined)
	stage.queue_free()
