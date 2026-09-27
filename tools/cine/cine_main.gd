extends SceneTree
## `cine`: the Movie Maker CLI (docs/plan/tools-wave.md section 3; manual: tools/cine/README.md).
## Run through tools/cine/run_cine.ps1 <verb> <id> [key=value ...]; the id is data/cinematics/src/<id>.cine.

const TOOL := "cine"
const VERBS := [
	{"verb": "help", "args": "", "text": "grammar + a complete example"},
	{"verb": "check", "args": "<id>", "text": "headless: parse, resolve, timing, framing, 180-degree rule, subtitles, 2-run hash", "needs_id": true},
	{"verb": "build", "args": "<id>", "text": "check, then bake data/cinematics/<id>.tres (runtime classes) if 0 FAIL", "needs_id": true},
	{"verb": "sheet", "args": "<id>", "text": "headless: timing sheet PNG (shots, lines + CPS, cue ticks, music)", "needs_id": true},
	{"verb": "stills", "args": "<id> [shot=P3] [res=WxH,..]", "text": "WINDOWED: frames a/b/c per shot with band + safe area, contact sheet", "needs_id": true},
	{"verb": "animatic", "args": "<id>", "text": "WINDOWED: stills with grey proxies (capsules, boxes)", "needs_id": true},
	{"verb": "play", "args": "<id>", "text": "WINDOWED: live playback (cine preview player: bars, subtitles, fades, cues)", "needs_id": true},
	{"verb": "record", "args": "<id> [fps=30] [res=1920x804] [dur=]", "text": "WINDOWED Movie Maker: PNG sequence + WAV outside res:// (the ps1 adds --write-movie)", "needs_id": true},
	{"verb": "demo", "args": "", "text": "the acceptance demo (The Watch-Keep): checks, planted bugs = 4 FAIL, sheet, hash x2"},
]
const KEYS := [
	{"key": "shot", "default": "all", "text": "stills / animatic: only this shot id"},
	{"key": "res", "default": "1600x900", "text": "stills: comma list of WxH (3440x1440 = the user's ultrawide)"},
	{"key": "fps", "default": "30", "text": "record frame rate (the ps1 passes it to --fixed-fps)"},
	{"key": "dur", "default": "all", "text": "record / play: stop after this many seconds"},
	{"key": "src", "default": "", "text": "a .cine path instead of data/cinematics/src/<id>.cine"},
	{"key": "animatic", "default": "0", "text": "1 = grey proxies in stills / play / record"},
	{"key": "log", "default": "1", "text": "0 = no history row"},
	{"key": "out", "default": "", "text": "record: output folder (the ps1 sets it; outside res://)"},
	{"key": "expect_fail", "default": "", "text": "check: exit 0 only if exactly this many FAILs (planted-bug files)"},
]
const EXAMPLE := """# data/cinematics/src/two_wizards.cine
cine two_wizards  title="Two Wizards"  letterbox=2.39  seed=3  length=6..12
env night  moon_yaw=200
prop  keep   res://art/buildings/fire_keep.tscn  at=(0, 0, 0)
cast  vessa  res://art/units/wizards/vessa.tscn  at=(0, 0, -7)   yaw=180
cast  shade  res://art/units/shadow/shade.tscn   at=(1, 0, -11)  yaw=0
shot S1 4.0  cam=frame "ms on vessa and shade, high"  push=0.6
  at 0.5  line vessa "Who walks the wall at this hour?"
  at 2.0  anim shade play_attack
shot S2 3.0  cam=frame "mcu on vessa, ots shade left"
  at 0.2  sfx res://assets/audio/sfx/spell_umbral_shroud.wav
  at 2.4  fade alpha=1 time=0.6"""


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var cli := ToolCli.parse(TOOL, VERBS, KEYS)
	if cli.bad != "":
		print(cli.bad)
		quit(ToolCli.BAD_INPUT)
		return
	ToolCli.watchdog(self, 600.0, TOOL)
	var code := ToolCli.OK
	match cli.verb:
		"help":
			print(cli.help_text("the Movie Maker: a .cine text timeline -> checks, baked CinematicScript, stills, timing sheet, recording", EXAMPLE))
			print(GRAMMAR)
		"check", "build":
			code = await _check(cli, cli.id, cli.verb)
		"sheet":
			code = _sheet(cli, cli.id)
		"stills", "animatic":
			code = await _stills(cli, cli.id, cli.verb == "animatic" or cli.opt_bool("animatic"))
		"play", "record":
			code = await _play(cli, cli.id, cli.verb == "record")
		"demo":
			code = await _demo(cli)
	quit(code)


func _src(cli: ToolCli, id: String) -> String:
	return CineDoc.source_of(cli.opt("src", id))


## Parse + stage + bake + eval. The stage goes under `parent` (a SubViewport for stills, else the root).
func pipeline(src: String, parent: Node, animatic: bool = false) -> Dictionary:
	var doc := CineDoc.load_file(src)
	var stage := CineStage.new()
	parent.add_child(stage)
	stage.build(doc, animatic)
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	return {"doc": doc, "stage": stage, "bake": bake, "ev": ev}


func _free(p: Dictionary) -> void:
	var st: CineStage = p["stage"]
	if is_instance_valid(st):
		st.queue_free()


func run_checks(p: Dictionary, rep: ToolReport) -> void:
	var doc: CineDoc = p["doc"]
	var bake: CineBake = p["bake"]
	var ev: CineEval = p["ev"]
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, p["stage"], bake, rep)
	if bake.shots.is_empty():
		return
	CineChecks.timing(doc, bake, ev, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.continuity(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	CineChecks.partners(bake, rep)


func hash_of(p: Dictionary) -> String:
	var bake: CineBake = p["bake"]
	var ev: CineEval = p["ev"]
	if bake.shots.is_empty():
		return ""
	return ToolCli.hash_of(JSON.stringify(bake.to_data(), "", true) + "#" + ev.hash_frames(60))


func _check(cli: ToolCli, id: String, verb: String) -> int:
	var src := _src(cli, id)
	var rep := ToolReport.start(TOOL, verb, id)
	var p := pipeline(src, root)
	var doc: CineDoc = p["doc"]
	rep.notes.append("source `%s` (%d lines), %.1f s, %d shots, stage: %s" % [src.replace("res://", ""), doc.line_count(),
		(p["ev"] as CineEval).total, doc.shots.size(), ("set " + doc.set_id) if (p["stage"] as CineStage).set_found else "cine-built (props / cast)"])
	if doc.line_count() > 80:
		rep.notes.append("the .cine has %d lines (demo budget <= 80)" % doc.line_count())
	run_checks(p, rep)
	var timing_rows := rep.checks.filter(func(c: Dictionary) -> bool: return c["group"] == "timing")
	if doc.spec.errors.is_empty() and timing_rows.is_empty():
		rep.check("X1", "parse", "checks ran", "FAIL", "no timing rows", "every check group runs", "a cine script failed: read the Godot errors above")
	if doc.spec.errors.is_empty():
		rep.check("P0", "parse", "grammar", "PASS", "%d lines, 0 errors" % doc.line_count(), "tools/cine/README.md grammar")
	# determinism: a second, fully fresh run (parse + stage + bake + 60 fps frames) must hash the same
	var h1 := hash_of(p)
	_free(p)
	await process_frame
	var p2 := pipeline(src, root)
	var h2 := hash_of(p2)
	rep.hash_value = h1
	var prev := ToolReport.read_previous_hash(rep.out_dir, verb)
	rep.hash_note = "2 runs identical" if h1 == h2 and h1 != "" else "runs differ"
	rep.check("D1", "determinism", "2 fresh runs (bake + 3600 frames at 60 fps)", "PASS" if h1 == h2 and h1 != "" else "FAIL",
		"%s / %s" % [h1, h2], "same spec + seed = same bytes", "remove time / random sources from the stage")
	rep.check("D2", "determinism", "vs previous run", "INFO", "same" if prev == h1 else ("changed (was %s)" % prev if prev != "" else "first run"), "")
	await _runtime_cross_check(p2, rep)
	if verb == "build":
		if rep.count("FAIL") == 0:
			var out := (p2["bake"] as CineBake).save()
			rep.check("B1", "determinism", "bake", "PASS" if out != "" else "FAIL", out.replace("res://", "") if out != "" else "not written",
				"data/cinematics/<id>.tres (CinematicScript)", "check the runtime classes (scripts/cinematics/)")
			if out.ends_with(".json"):
				rep.check("B2", "partners", "runtime classes", "WARN", "tool 1 missing: JSON bake only", "a .tres needs scripts/cinematics/", "rerun build when tool 1 lands")
		else:
			rep.check("B1", "determinism", "bake", "SKIP", "not baked: fix the FAILs first", "")
	_free(p2)
	rep.extras.append({"title": "Look at the pictures", "text": "run `stills` (windowed) and open stills.png: framing numbers do not judge beauty", "source": "cine"})
	rep.extras.append({"title": "Timing sheet", "text": "run `sheet` and read timing.png: line bars show CPS colour", "source": "cine"})
	rep.extras.append({"title": "Two-run hash", "text": "the hash in the history must stay the same while the .cine is unchanged", "source": "cine"})
	var code := rep.finish(cli.opt("log", "1") != "0")
	if cli.has("expect_fail"):
		var want := cli.opt_int("expect_fail", -1)
		print("CINE expect_fail=%d got %d FAIL -> %s" % [want, rep.count("FAIL"), "OK" if want == rep.count("FAIL") else "MISMATCH"])
		return ToolCli.OK if want == rep.count("FAIL") else ToolCli.FAIL
	return code


## Plays the baked script with tool 1's CinematicPlayer (load-guarded), seeks to the middle of every shot and compares
## its debug_state() camera with cine's evaluator: the two must agree, or stills / checks judge another movie.
func _runtime_cross_check(p: Dictionary, rep: ToolReport) -> void:
	var path := "res://scripts/cinematics/cinematic_player.gd"
	var bake: CineBake = p["bake"]
	var ev: CineEval = p["ev"]
	if not ResourceLoader.exists(path) or bake.shots.is_empty() or rep.count("FAIL") > 0:
		rep.check("RT1", "partners", "runtime camera = cine camera", "SKIP", "no player or FAILs", "")
		return
	var res := bake.to_resource()
	var pl_script: Script = load(path)
	if res == null or pl_script == null:
		rep.check("RT1", "partners", "runtime camera = cine camera", "SKIP", "runtime classes missing", "")
		return
	var pl: Node = pl_script.new()
	for k: String in ["use_overlay", "emit_events"]:
		if k in pl:
			pl.set(k, false)
	root.add_child(pl)
	var err: Variant = pl.call(&"play", res, p["stage"])
	if String(err) != "":
		rep.check("RT1", "partners", "runtime camera = cine camera", "WARN", "play() refused: " + String(err), "the runtime plays the bake", "report to tool 1")
		pl.queue_free()
		return
	await process_frame
	var worst := 0.0
	var where := ""
	for i: int in bake.shots.size():
		if int(bake.shots[i]["camera_mode"]) in [4, 5]:
			continue
		var t := ev.starts[i] + float(bake.shots[i]["duration"]) * 0.5
		pl.call(&"seek", t)
		var ds: Dictionary = pl.call(&"debug_state")
		var cam: Dictionary = ds.get("camera", {})
		if not cam.has("pos"):
			continue
		var d := (cam["pos"] as Vector3).distance_to(ev.camera(t)["pos"])
		if d > worst:
			worst = d
			where = "%s at %.2f s" % [bake.shots[i]["id"], t]
	if pl.has_method(&"skip"):
		pl.call(&"skip")
	pl.queue_free()
	await process_frame
	rep.check("RT1", "partners", "runtime camera = cine camera", "PASS" if worst <= 0.05 else "WARN",
		"worst %.3f m%s" % [worst, (" (" + where + ")") if where != "" else ""], "<= 0.05 m at the middle of every shot",
		"the runtime and cine disagree: note it in docs/handoff/for-systems-coder.md")


func _sheet(cli: ToolCli, id: String) -> int:
	var rep := ToolReport.start(TOOL, "sheet", id)
	var p := pipeline(_src(cli, id), root)
	var chk := ToolReport.start(TOOL, "check", id)
	run_checks(p, chk)
	var header: Array = ["%s  %d FAIL  %d WARN  (cine check)" % [chk.result(), chk.count("FAIL"), chk.count("WARN")]]
	for l: String in chk.problem_lines().slice(0, 4):
		header.append(l)
	var img := CineSheets.timing_sheet(p["doc"], p["bake"], p["ev"], header)
	var path := rep.out_dir.path_join("timing.png")
	var err := ToolSheet.save_png(img, path)
	rep.add_group("sheet", "Timing sheet")
	rep.check("SH1", "sheet", "timing.png", "PASS" if err == OK else "FAIL", "%dx%d" % [img.get_width(), img.get_height()], "written", "check the out folder")
	rep.shots["timing"] = "timing.png"
	rep.hash_value = ToolCli.hash_of(img.get_data())
	_free(p)
	return rep.finish(cli.opt("log", "1") != "0")


## Frames a / b / c of every shot (5 %, 50 %, 95 %) with the band + safe area, and one contact sheet.
func _stills(cli: ToolCli, id: String, animatic: bool) -> int:
	var verb := "animatic" if animatic else "stills"
	var rep := ToolReport.start(TOOL, verb, id)
	rep.add_group("stills", "Stills")
	if not ToolCli.is_windowed():
		rep.check("ST0", "stills", "renderer", "FAIL", "headless", "stills need a window", "run `run_cine.ps1 %s %s` (it opens a window)" % [verb, id])
		return rep.finish(false)
	var sizes := cli.opt_sizes("res", [Vector2i(1600, 900)])
	var cap := ToolCapture.create(root, sizes[0])
	var p := pipeline(_src(cli, id), cap.viewport, animatic)
	var chk := ToolReport.start(TOOL, "check", id)
	run_checks(p, chk)
	var ev: CineEval = p["ev"]
	var bake: CineBake = p["bake"]
	var prev := CinePreview.new()
	root.add_child(prev)
	prev.setup(ev, p["stage"], cap.viewport, false)
	cap.camera.current = false
	var only := cli.opt("shot", "")
	var tiles: Array = []
	var folder := rep.out_dir.path_join(verb)
	var n := 0
	for sz: Vector2i in sizes:
		cap.set_size(sz)
		for i: int in bake.shots.size():
			var s: Dictionary = bake.shots[i]
			if only != "" and String(s["id"]) != only:
				continue
			var bad := ""
			for c: Dictionary in chk.checks:
				if String(c["shot"]) == String(s["id"]) and (c["status"] == "FAIL" or c["status"] == "WARN"):
					bad = c["status"] if bad != "FAIL" else bad
			for fk: Array in [["a", 0.05], ["b", 0.5], ["c", 0.95]]:
				var lt := float(fk[1]) * float(s["duration"])
				prev.pose(ev.starts[i] + lt)
				var img: Image = await cap.snap(3)
				if img == null:
					continue
				ToolSheet.band_overlay(img, bake.doc.letterbox)
				var line_txt := ""
				for ln: Dictionary in s["lines"]:
					if lt >= float(ln["at"]) and lt < float(ln["at"]) + maxf(2.5, 0.9 + 0.055 * String(ln["text"]).length()):
						line_txt = "%s: %s" % [ln["speaker"], ln["text"]]
				var fname := "%s_%s_%d.png" % [s["id"], fk[0], sz.x]
				ToolSheet.save_png(img, folder.path_join(fname))
				n += 1
				var cam_names := ["static", "dolly", "crane", "orbit", "rail", "follow"]
				var tile := {"img": img, "label": "%s %s %.1fs %s fov %.0f%s" % [s["id"], fk[0], lt, cam_names[int(s["camera_mode"])],
					float(ev.camera(ev.starts[i] + lt)["fov"]), ("  " + line_txt) if line_txt != "" else ""]}
				if bad != "":
					tile["mark"] = ToolSheet.FAIL_C if bad == "FAIL" else ToolSheet.WARN_C
					tile["color"] = tile["mark"]
				tiles.append(tile)
	var header: Array = ["%s  %d FAIL  %d WARN  (cine check; red / amber frame = that shot has a FAIL / WARN)" % [chk.result(),
		chk.count("FAIL"), chk.count("WARN")], "YELLOW LINES = 2.39 BAND (THE BARS HIDE THE DARK PART), CYAN = SAFE AREA 90 %"]
	for l: String in chk.problem_lines().slice(0, 3):
		header.append(l)
	var sheet := ToolSheet.grid(tiles, 3, 520, header, "%s %s  \"%s\"  %d frames" % [verb.to_upper(), id, bake.doc.title, n])
	var sheet_path := rep.out_dir.path_join(verb + ".png")
	ToolSheet.save_png(sheet, sheet_path)
	rep.shots["contact sheet"] = verb + ".png"
	rep.check("ST1", "stills", "frames", "PASS" if n > 0 else "FAIL", "%d frames in %s/" % [n, verb], "3 per shot per size", "")
	rep.hash_value = ToolCli.hash_of(sheet.get_data())
	prev.queue_free()
	_free(p)
	cap.free_viewport()
	return rep.finish(cli.opt("log", "1") != "0")


## Live playback in the window (play) or under Movie Maker (record: the ps1 starts Godot with --write-movie).
func _play(cli: ToolCli, id: String, record: bool) -> int:
	var rep := ToolReport.start(TOOL, "record" if record else "play", id)
	rep.add_group("play", "Playback")
	if not ToolCli.is_windowed():
		rep.check("P0", "play", "renderer", "FAIL", "headless", "play / record need a window", "run it through run_cine.ps1 (windowed)")
		return rep.finish(false)
	var p := pipeline(_src(cli, id), root, cli.opt_bool("animatic"))
	var ev: CineEval = p["ev"]
	var prev := CinePreview.new()
	root.add_child(prev)
	prev.setup(ev, p["stage"], root, true)
	prev.letterbox = (p["doc"] as CineDoc).letterbox
	var dur := cli.opt_float("dur", 0.0)
	var frames := 0
	var fps := Engine.get_frames_per_second()
	prev.start((p["doc"] as CineDoc).music)
	var limit := ev.total + prev.head + prev.tail + 0.1
	if dur > 0.0:
		limit = minf(limit, dur + prev.head)
	var t0 := Time.get_ticks_msec()
	var worst_ms := 0.0
	var last := Time.get_ticks_usec()
	while prev.playing and prev.t < limit - prev.head:
		await process_frame
		var now := Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, float(now - last) / 1000.0)
		last = now
		frames += 1
	var mpath := Engine.get_write_movie_path()
	rep.check("P1", "play", "frames", "PASS" if frames > 0 else "FAIL", "%d frames, %.1f s cinematic time, wall %.1f s, worst frame %.1f ms" % [frames,
		prev.t + prev.head, float(Time.get_ticks_msec() - t0) / 1000.0, worst_ms], "plays to the end", "")
	if record:
		rep.check("P2", "play", "movie", "PASS" if mpath != "" else "FAIL", mpath if mpath != "" else "not under --write-movie",
			"Movie Maker PNG sequence + WAV outside res://", "use run_cine.ps1 record <id> (it adds --write-movie)")
		rep.notes.append("Movie Maker writes <name>00000000.png ... + <name>.wav; convert to video only with the user's OK (no ffmpeg here)")
	rep.notes.append("player: cine preview (CinePreview)%s" % ("; tool 1 CinematicPlayer present" if ResourceLoader.exists("res://scripts/cinematics/cinematic_player.gd") else ""))
	prev.queue_free()
	_free(p)
	return rep.finish(cli.opt("log", "1") != "0")


## The acceptance demo, headless part: The Watch-Keep check (0 FAIL), the planted-bug file (exactly 4 FAIL), timing
## sheet, 2-run hash. Stills and the 10 s recording are windowed runs started by run_cine.ps1 demo.
func _demo(cli: ToolCli) -> int:
	var ok := true
	var c1 := await _check(ToolCli.parse(TOOL, VERBS, KEYS, PackedStringArray(["build", "watch_keep"])), "watch_keep", "build")
	var r1 := ToolReport.read_previous_quality(ToolReport.out_dir_of(TOOL, "watch_keep"), "build")
	var j1: Variant = JSON.parse_string(FileAccess.get_file_as_string(ToolReport.out_dir_of(TOOL, "watch_keep").path_join("report.json")))
	var fails1 := int((j1 as Dictionary)["counts"]["FAIL"]) if j1 is Dictionary else -1
	var hash_note := String((j1 as Dictionary).get("hash_note", "")) if j1 is Dictionary else ""
	print("DEMO watch_keep: exit %d, %d FAIL, quality %.0f, %s" % [c1, fails1, r1, hash_note])
	ok = ok and c1 == 0 and fails1 == 0 and hash_note == "2 runs identical"
	var c2 := await _check(ToolCli.parse(TOOL, VERBS, KEYS, PackedStringArray(["check", "watch_keep_bugs"])), "watch_keep_bugs", "check")
	var j2: Variant = JSON.parse_string(FileAccess.get_file_as_string(ToolReport.out_dir_of(TOOL, "watch_keep_bugs").path_join("report.json")))
	var fails2 := int((j2 as Dictionary)["counts"]["FAIL"]) if j2 is Dictionary else -1
	print("DEMO watch_keep_bugs: exit %d, %d FAIL (want exactly 4)" % [c2, fails2])
	ok = ok and fails2 == 4
	var c3 := _sheet(ToolCli.parse(TOOL, VERBS, KEYS, PackedStringArray(["sheet", "watch_keep"])), "watch_keep")
	ok = ok and c3 == 0
	print("DEMO %s" % ("PASS (headless part; stills + record run windowed)" if ok else "FAIL"))
	return ToolCli.OK if ok else ToolCli.FAIL


const GRAMMAR := """
Grammar (one line per item; `# ` comments; tools/cine/README.md has the full table):
  cine <id> title="..." letterbox=2.39 skip_lock=0 seed=1 length=45..60 skippable=true
  use set <set_id>          tool 6 set art/cinematics/stage_sets/<set_id>/ (markers, puppets); missing = WARN + boxes
  use lines <path.json>     tool 10 LineTrack {cine_id, lines: {shot: [{at, speaker, text, duration}]}}
  use music <res path>      music bed for the whole cinematic
  env night|dusk|day|none [moon_yaw= moon_pitch= energy= color=#hex]   (only when no set brings its own)
  prop <name> <res://scene.tscn> at=(x,y,z) yaw=<deg> scale=<k>
  cast <tag> <res://model.tscn | capsule> at=(x,y,z) yaw=<deg> [hidden=1] [speaker=<id>]
  mark <name> (x,y,z) [fov=40]                 -> @name
  marks <shot> from=(..) to=(..) look=(..)>(..) fov=40>36   -> @<shot>_from/_to/_look_from/_look_to
  shot <id> <seconds> cam=<mode> [keys]  modes: static dolly crane orbit follow rail frame lens (none = the shot's marks)
     static/dolly/crane: from= to= look=<a>[><b>] fov=<a>[><b>]   (positions: (x,y,z) | @marker | actor | actor+(dx,dy,dz))
     orbit: pivot=<actor|pos> r= h= deg=<a>><b>     follow: actor= offset=(x,y,z)     rail: rail=<Path3D in the set>
     frame "<size> on <actor>[ and <actor>], <angle>, <height>, thirds left|right, ots <actor>" [push=<m>]
        size ecu cu mcu ms mls ws ews; angle front, 3/4 left, 3/4 right, profile left, profile right, back;
        height eye low high top.   lens "<words>" = tool 3 (lens_spec=<camera.json>), else the same framer + WARN
     in=cut|fade_black[:s]|fade_white[:s]|blend[:s]  ease=in|out|in_out|out_in  trans=sine|linear|cubic|...
     roll= shake=0..1 faces=a,b (faces that must stay in the band; look/pivot/frame subjects are added) set=<set_id>
  (indented under a shot)  at <seconds> <action> ...
     line <speaker> "text" [dur=]      move <actor> to=<pos> [speed=2]     teleport <actor> to=<pos> [yaw=]
     face <actor> yaw=<deg> | to=<actor|pos>     anim <actor> <play_hook> [arg=]     clip <actor> <clip_id>
     vfx <id> [at=<pos|actor>] [to=] [scene=res://..]   sfx <res path> [vol=]   music <res path>   shake <0..1>
     fade [color=#000] [alpha=1] [time=0.5]   title "text" [sub=] [time=3]   show <actor>   hide <actor>
     call <method> [args=a,b]   set_shot <set_id>
Clip ids without tool 5: cast attack hit death level_up staff_slam draw_knife slash kneel bow point nod turn_head_left turn_head_right
"""
