class_name CineChecks
extends RefCounted
## The `cine check` rules (docs/plan/tools-wave.md section 3). One report row per problem, so a planted bug = one FAIL:
## parse / resolve (every name exists, did-you-mean), timing, framing (named faces inside the 2.39 band at every
## 0.25 s), continuity (180-degree rule and jump cuts at every cut), subtitles (2 x 48 chars, CPS, fits its shot).

const SAMPLE_DT := 0.25
const MAX_CHARS := 48
const MAX_LINES := 2
const CPS_OK := 17.0
const CPS_MAX := 22.0
const AXIS_MIN_SIN := 0.17      # ~10 deg: a camera almost on the line is neutral (allowed)


static func add_groups(rep: ToolReport) -> void:
	rep.add_group("parse", "Parse (grammar, keys, numbers)", 2.0)
	rep.add_group("resolve", "Resolve (set, markers, actors, clips, vfx, audio, lines)", 2.0)
	rep.add_group("timing", "Timing", 1.0)
	rep.add_group("framing", "Framing (faces in the 2.39 band, 16:9 frame)", 2.0)
	rep.add_group("continuity", "Continuity (180-degree rule, jump cuts)", 1.5)
	rep.add_group("subtitles", "Subtitles (2 x 48 chars, CPS, fit)", 1.0)
	rep.add_group("determinism", "Determinism", 1.0)
	rep.add_group("partners", "Partner tools", 0.5)


## Parse + resolve problems (from the reader, the stage and the bake) as report rows.
static func problems(doc: CineDoc, stage: CineStage, bake: CineBake, rep: ToolReport) -> void:
	var n := 1
	for e: Dictionary in doc.spec.errors:
		rep.check("E%d" % n, "parse", "line %d" % int(e["line"]), "FAIL", "%s (token \"%s\")" % [e["message"], e["token"]],
			"the .cine grammar (tools/cine/README.md)", String(e["hint"]) if String(e["hint"]) != "" else "see `run_cine.ps1 help`",
			"fix %s:%d" % [String(e["file"]).get_file(), int(e["line"])])
		n += 1
	var rows: Array[Dictionary] = []
	rows.append_array(stage.problems)
	if bake != null:
		rows.append_array(bake.problems)
	for p: Dictionary in rows:
		var ln: ToolSpecLine = p.get("line")
		var where := (" (line %d)" % ln.line) if ln != null else ""
		rep.check("R%d" % n, String(p.get("group", "resolve")), String(p["name"]) + where, String(p["status"]), p["value"],
			String(p.get("rule", "names resolve")), String(p["hint"]), String(p["hint"]))
		n += 1
	if doc.spec.errors.is_empty() and rows.filter(func(x: Dictionary) -> bool: return x["status"] == "FAIL").is_empty():
		rep.check("R0", "resolve", "every name resolves", "PASS", "%d actors, %d markers, %d shots" % [stage.actors.size(),
			bake.all_markers().size() if bake != null else 0, doc.shots.size()], "sets, markers, actors, clips, vfx, audio exist")


static func partners(bake: CineBake, rep: ToolReport) -> void:
	var names := {"runtime": "tool 1 resources (bake .tres)", "player": "tool 1 CinematicPlayer (play / record)",
		"lens": "tool 3 Lens", "motion": "tool 5 Motion Lab", "vfx": "tool 7 VFX Composer"}
	var i := 1
	for k: String in names:
		var present: bool = bake.partner.get(k, "missing") == "present"
		rep.check("T%d" % i, "partners", names[k], "INFO", "present" if present else "missing (cine degrades: WARN + proxy when used)",
			"optional at bake time")
		i += 1


static func timing(doc: CineDoc, bake: CineBake, ev: CineEval, rep: ToolReport) -> void:
	var tot := ev.total
	var r := doc.length_range
	var st := "PASS" if tot >= r.x - 0.001 and tot <= r.y + 0.001 else "FAIL"
	rep.check("TM1", "timing", "total length", st, "%.2f s (%d shots)" % [tot, bake.shots.size()], "%.0f..%.0f s" % [r.x, r.y],
		"lengthen / trim shots", "retime the shots to fit %.0f..%.0f s" % [r.x, r.y])
	var short: Array[String] = []
	for s: Dictionary in bake.shots:
		if float(s["duration"]) < 1.0:
			short.append("%s %.2fs" % [s["id"], float(s["duration"])])
	rep.check("TM2", "timing", "shot lengths", "WARN" if not short.is_empty() else "PASS",
		", ".join(short) if not short.is_empty() else "all >= 1.0 s", ">= 1.0 s (shorter reads as a flash cut)",
		"lengthen the shot", "hold short shots >= 1 s")
	var bad: Array[String] = []
	for i: int in bake.shots.size():
		var s2: Dictionary = bake.shots[i]
		if int(s2["transition_in"]) in [1, 2]:
			var tt := float(s2["transition_time"])
			if tt > float(s2["duration"]) or (i > 0 and tt * 0.5 > float(bake.shots[i - 1]["duration"])):
				bad.append("%s fade %.2fs" % [s2["id"], tt])
	rep.check("TM3", "timing", "fade lengths", "FAIL" if not bad.is_empty() else "PASS",
		", ".join(bad) if not bad.is_empty() else "fit", "a fade fits in its shots", "shorten in=fade_black:<s>")


static func framing(bake: CineBake, ev: CineEval, rep: ToolReport) -> void:
	var band := ToolSheet.band_rect(Vector2i(CineEval.REF_SIZE), 2.39)
	var h := CineEval.REF_SIZE.y
	var top := float(band.position.y) / h
	var bot := float(band.end.y) / h
	var bh := bot - top
	var n := 1
	for i: int in bake.shots.size():
		var s: Dictionary = bake.shots[i]
		var faces: Array = s["faces"]
		if faces.is_empty():
			rep.check("F%d" % n, "framing", "%s faces" % s["id"], "INFO", "no named face", "shots that show a face name it (look / pivot / frame / faces=)",
				"", "", String(s["id"]))
			n += 1
			continue
		if bool(s["fallback_cam"]):
			rep.check("F%d" % n, "framing", "%s faces" % s["id"], "SKIP", "proxy camera (set missing)", "", "", "", String(s["id"]))
			n += 1
			continue
		for tag: String in faces:
			var worst := 0.0      # 0 = centre of the safe area .. 1 = on the band edge .. > 1 outside
			var wt := 0.0
			var wuv := Vector3(0.5, 0.5, 1)
			var shown := 0
			var dur := float(s["duration"])
			var t := 0.0
			while t <= dur + 0.0001:
				var gt := ev.starts[i] + minf(t, dur - 0.001)
				var a := ev.actor(tag, gt)
				if bool(a["visible"]):
					shown += 1
					var c := ev.camera(gt)
					var uv := CineEval.project(c["xform"], c["fov"], ev.head_point(tag, gt))
					var score := 9.0
					if uv.z > 0.0:
						var dv := absf(uv.y - (top + bot) * 0.5) / (bh * 0.5)
						var du := absf(uv.x - 0.5) / 0.5
						score = maxf(dv, du)
					if score > worst:
						worst = score
						wt = t
						wuv = uv
				t += SAMPLE_DT
			if shown == 0:
				rep.check("F%d" % n, "framing", "%s %s" % [s["id"], tag], "INFO", "hidden during the shot", "", "", "", String(s["id"]))
				n += 1
				continue
			var st := "PASS" if worst <= 0.9 else ("WARN" if worst <= 1.0 else "FAIL")
			var where := "behind the camera" if wuv.z <= 0.0 else "u %.2f v %.2f" % [wuv.x, wuv.y]
			var hint := ""
			if st != "PASS":
				if wuv.z <= 0.0:
					hint = "the camera looks away from %s: aim look= at it" % tag
				elif wuv.y < top + bh * 0.5 and absf(wuv.y - (top + bot) * 0.5) / (bh * 0.5) >= absf(wuv.x - 0.5) / 0.5:
					hint = "face too high (above the band): raise look= or lower the camera"
				elif wuv.y >= top + bh * 0.5 and absf(wuv.y - (top + bot) * 0.5) / (bh * 0.5) >= absf(wuv.x - 0.5) / 0.5:
					hint = "face too low (under the band): lower look= or raise the camera"
				else:
					hint = "face at the frame side: turn the camera toward %s or widen fov" % tag
			rep.add("F%d" % n, "framing", "%s face %s" % [s["id"], tag], st, "worst %s at %.2f s" % [where, wt],
				"head inside the 2.39 band safe area (90 %)", hint, ToolReport.grade(worst, 1.3, 0.5),
				"keep %s nearer the band centre in %s" % [tag, s["id"]] if st == "PASS" else hint, String(s["id"]))
			n += 1


static func continuity(bake: CineBake, ev: CineEval, rep: ToolReport) -> void:
	var tags: Array = ev.actor_start.keys()
	tags.sort()
	var n := 1
	for i: int in range(1, bake.shots.size()):
		var s: Dictionary = bake.shots[i]
		var cut_name := "cut %s>%s" % [bake.shots[i - 1]["id"], s["id"]]
		if int(s["transition_in"]) != 0:
			rep.check("C%d" % n, "continuity", cut_name, "INFO", "fade / blend (scene break: the axis may reset)", "180-degree rule applies to cuts")
			n += 1
			continue
		if bool(s["fallback_cam"]) or bool(bake.shots[i - 1]["fallback_cam"]):
			rep.check("C%d" % n, "continuity", cut_name, "SKIP", "proxy camera", "")
			n += 1
			continue
		var t1 := ev.starts[i] - 0.001
		var t2 := ev.starts[i]
		var c1 := ev.camera(t1)
		var c2 := ev.camera(t2)
		var crossed: Array[String] = []
		var kept: Array[String] = []
		for ai: int in tags.size():
			for bi: int in range(ai + 1, tags.size()):
				var ta: String = tags[ai]
				var tb: String = tags[bi]
				if not (_on_screen(ev, ta, t1, c1) and _on_screen(ev, tb, t1, c1) and _on_screen(ev, ta, t2, c2) and _on_screen(ev, tb, t2, c2)):
					continue
				var pa := ev.head_point(ta, t2)
				var pb := ev.head_point(tb, t2)
				var s1 := _side(pa, pb, c1["pos"])
				var s2 := _side(pa, pb, c2["pos"])
				if absf(s1) < AXIS_MIN_SIN or absf(s2) < AXIS_MIN_SIN:
					kept.append("%s-%s (on the axis)" % [ta, tb])
				elif signf(s1) != signf(s2):
					crossed.append("%s-%s" % [ta, tb])
				else:
					kept.append("%s-%s" % [ta, tb])
		if not crossed.is_empty():
			rep.check("C%d" % n, "continuity", cut_name + " axis", "FAIL", "camera crosses the line " + ", ".join(crossed),
				"180-degree rule: both shots on the same side of the line between two on-screen actors",
				"%s and %s film %s from opposite sides: move one camera across (keep the side the other shots use), or cut through a neutral / fade shot" % [bake.shots[i - 1]["id"], s["id"], crossed[0]],
				"keep %s's camera on %s's side of %s" % [s["id"], bake.shots[i - 1]["id"], crossed[0]], String(s["id"]))
		elif not kept.is_empty():
			rep.check("C%d" % n, "continuity", cut_name + " axis", "PASS", "same side: " + ", ".join(kept), "180-degree rule")
		else:
			rep.check("C%d" % n, "continuity", cut_name + " axis", "INFO", "no pair on screen in both shots", "180-degree rule")
		n += 1
		# jump cut
		var d1: Vector3 = c1["look"] - c1["pos"]
		var d2: Vector3 = c2["look"] - c2["pos"]
		var moved := (c1["pos"] as Vector3).distance_to(c2["pos"])
		var ang := rad_to_deg(d1.angle_to(d2))
		var fr := float(c2["fov"]) / maxf(1.0, float(c1["fov"]))
		if moved < 0.1 * d1.length() and ang < 10.0 and absf(fr - 1.0) < 0.1:
			rep.check("C%d" % n, "continuity", cut_name + " jump cut", "WARN", "camera moved %.2f m, turned %.1f deg" % [moved, ang],
				"a cut changes framing by > 10 % (else it reads as a jump)", "change size or angle at %s (e.g. ms -> cu, or 30 deg around)" % s["id"],
				"reframe %s" % s["id"], String(s["id"]))
			n += 1


static func _on_screen(ev: CineEval, tag: String, t: float, c: Dictionary) -> bool:
	if not bool(ev.actor(tag, t)["visible"]):
		return false
	var uv := CineEval.project(c["xform"], c["fov"], ev.head_point(tag, t))
	return uv.z > 0.0 and uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0


## Signed sine of the camera's angle to the line a->b (top view): + one side, - the other.
static func _side(a: Vector3, b: Vector3, cam: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ac := Vector2(cam.x - a.x, cam.z - a.z)
	if ab.length() < 0.3 or ac.length() < 0.01:
		return 0.0
	return ab.normalized().cross(ac.normalized())


static func wrap_text(text: String, width: int = MAX_CHARS) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for w: String in text.split(" ", false):
		if cur == "":
			cur = w
		elif cur.length() + 1 + w.length() <= width:
			cur += " " + w
		else:
			out.append(cur)
			cur = w
	if cur != "":
		out.append(cur)
	return out


static func subtitles(doc: CineDoc, bake: CineBake, rep: ToolReport) -> void:
	var speakers: Array = []
	for tag: String in doc.cast:
		speakers.append(tag)
		speakers.append(String(doc.cast[tag]["speaker"]))
	speakers.append_array(["narrator", "whisper", "voice"])
	var n := 1
	var total := 0
	for s: Dictionary in bake.shots:
		var lines: Array = (s["lines"] as Array).duplicate()
		lines.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["at"]) < float(y["at"]))
		var dur := float(s["duration"])
		for li: int in lines.size():
			total += 1
			var ln: Dictionary = lines[li]
			var text := String(ln["text"])
			var at := float(ln["at"])
			var eff := float(ln["duration"]) if float(ln["duration"]) > 0.0 else maxf(2.5, 0.9 + 0.055 * text.length())
			var shown := minf(at + eff, dur) - at
			if li + 1 < lines.size():
				shown = minf(shown, float(lines[li + 1]["at"]) - at)
			var cps := float(text.length()) / maxf(0.01, shown)
			var wl := wrap_text(text)
			var st := "PASS"
			var why: Array[String] = []
			var hint := ""
			if text.length() > MAX_CHARS * MAX_LINES or wl.size() > MAX_LINES:
				st = "FAIL"
				why.append("%d chars = %d lines of <= %d" % [text.length(), wl.size(), MAX_CHARS])
				hint = "split it into two lines (two `line` actions) or cut words: <= %d chars" % (MAX_CHARS * MAX_LINES)
			if at >= dur or shown < 1.0:
				st = "FAIL"
				why.append("on screen %.2f s" % maxf(0.0, shown))
				if hint == "":
					hint = "start it earlier or lengthen %s" % s["id"]
			if cps > CPS_MAX:
				st = "FAIL"
				why.append("%.1f chars/s" % cps)
				if hint == "":
					hint = "give it more time (dur=, a longer shot) or fewer words"
			elif cps > CPS_OK and st == "PASS":
				st = "WARN"
				why.append("%.1f chars/s" % cps)
				hint = "aim for <= %.0f chars/s: more time or fewer words" % CPS_OK
			var sp := String(ln["speaker"])
			if not sp in speakers and st == "PASS":
				st = "WARN"
				why.append("speaker \"%s\" not cast" % sp)
				var nn := ToolSpec.nearest(sp, speakers)
				hint = ("did you mean \"%s\"?" % nn) if nn != "" else "cast the speaker or use narrator"
			var val := "%s \"%s\" %.1f cps, %.1f s" % [sp, text.left(40) + (".." if text.length() > 40 else ""), cps, shown]
			if not why.is_empty():
				val = ", ".join(why) + ": " + val
			rep.add("S%d" % n, "subtitles", "%s line %d (src %d)" % [s["id"], li + 1, int(ln["src_line"])], st, val,
				"<= 2 x 48 chars, <= %.0f cps (max %.0f), fits the shot" % [CPS_OK, CPS_MAX], hint,
				ToolReport.grade(cps, CPS_MAX, 12.0), hint if hint != "" else "", String(s["id"]))
			n += 1
	if total == 0:
		rep.check("S0", "subtitles", "lines", "INFO", "no lines", "")
