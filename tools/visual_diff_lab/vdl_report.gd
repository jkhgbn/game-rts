extends RefCounted
## Visual Diff Lab outputs (docs/plan/visual-diff-lab.md):
##   golden mode: <golden>/<id>.png (+ <id>.unstable.png when the shot had unstable pixels) and <golden>/golden.json
##   check mode:  <out>/latest/<id>.png (current), <id>_diff.png (heatmap), <id>_compare.png (golden | current | heat),
##                <out>/latest/scorecard.md + scorecard.json, and one row in <out>/history.md + history.jsonl
## `lab` is the running visual_diff_lab.gd SceneTree (captures, notes, tolerance, golden_dir, out_dir, commit, args).

const Diff := preload("res://tools/visual_diff_lab/vdl_diff.gd")


static func _stamp() -> String:
	return Time.get_datetime_string_from_system(false, true)


static func _save_png(img: Image, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := img.save_png(path)
	if err != OK:
		push_error("VISUAL_DIFF_LAB: cannot write %s (%s)" % [path, error_string(err)])
	return err == OK


static func write_goldens(lab: Object, shots: Array) -> void:
	var dir: String = lab.get(&"golden_dir")
	DirAccess.make_dir_recursive_absolute(dir)
	var caps: Dictionary = lab.get(&"captures")
	var meta := {}
	var old_path := dir.path_join("golden.json")
	if FileAccess.file_exists(old_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(old_path))
		if parsed is Dictionary and (parsed as Dictionary).get("shots") is Dictionary:
			meta = (parsed as Dictionary)["shots"]
	for s: Dictionary in shots:
		var id := String(s["id"])
		if not caps.has(id):
			continue
		var c: Dictionary = caps[id]
		_save_png(c["img"], dir.path_join(id + ".png"))
		var up := dir.path_join(id + ".unstable.png")
		if c["unstable"] != null:
			_save_png(c["unstable"], up)
		elif FileAccess.file_exists(up):
			DirAccess.remove_absolute(up)
		meta[id] = {"recorded": _stamp(), "commit": lab.get(&"commit"), "size": [(c["img"] as Image).get_width(),
			(c["img"] as Image).get_height()], "unstable_px": c["unstable_px"], "what": s.get("what", ""),
			"units": c.get("units", "")}
		print("  golden %s written (%d unstable px)" % [id, int(c["unstable_px"])])
	var f := FileAccess.open(old_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"updated": _stamp(), "tolerance": lab.get(&"tolerance"), "shots": meta}, "\t"))
		f.close()
	if not bool((lab.get(&"args") as Dictionary).has("no-history")):
		_append_history(lab, "golden", "GOLDEN", -1, "%d golden(s) recorded: %s" % [shots.size(),
			", ".join(shots.map(func(s: Dictionary) -> String: return String(s["id"])))])
	print("VISUAL_DIFF_LAB GOLDEN %d shot(s) -> %s" % [shots.size(), dir])


## Diffs every captured shot against its golden; returns the exit code (1 when a shot FAILs).
static func check_and_report(lab: Object, shots: Array) -> int:
	var gdir: String = lab.get(&"golden_dir")
	var latest: String = (lab.get(&"out_dir") as String).path_join("latest")
	DirAccess.make_dir_recursive_absolute(latest)
	var caps: Dictionary = lab.get(&"captures")
	var tol: int = lab.get(&"tolerance")
	var rows: Array[Dictionary] = []
	for s: Dictionary in shots:
		var id := String(s["id"])
		var row := {"id": id, "what": s.get("what", ""), "result": "FAIL", "score": 0, "why": "", "changed_pct": 0.0,
			"changed_px": 0, "max_delta": 0, "mean_delta": 0.0, "bbox": [], "where": "-", "unstable_px": 0, "ignored_pct": 0.0}
		if not caps.has(id):
			row["why"] = "not captured"
			rows.append(row)
			continue
		var c: Dictionary = caps[id]
		var cur: Image = c["img"]
		row["unstable_px"] = c["unstable_px"]
		_save_png(cur, latest.path_join(id + ".png"))
		var gpath := gdir.path_join(id + ".png")
		if not FileAccess.file_exists(gpath):
			row["result"] = "NEW"
			row["score"] = 0
			row["why"] = "no golden yet: record it with run_visual_diff_lab.ps1 -Golden -Shots %s" % id
			rows.append(row)
			continue
		var golden := Image.load_from_file(gpath)
		var mask: Image = Diff.rect_mask(Vector2i(cur.get_width(), cur.get_height()), s.get("ignore", []))
		var gup := gdir.path_join(id + ".unstable.png")
		if FileAccess.file_exists(gup):
			var gm := Image.load_from_file(gup)
			if gm != null:
				gm.convert(Image.FORMAT_L8)
				mask = Diff.mask_union(mask, gm)
		mask = Diff.mask_union(mask, c["unstable"])
		var res: Dictionary = Diff.diff(golden, cur, tol, mask)
		var v: Dictionary = Diff.verdict(res, float(s.get("pass_pct", Diff.PASS_PCT)))
		row["result"] = v["result"]
		row["score"] = v["score"]
		row["why"] = v["why"]
		if bool(res["ok"]):
			var bb: Rect2i = res["bbox"]
			row["changed_pct"] = snappedf(float(res["changed_pct"]), 0.0001)
			row["changed_px"] = res["changed_px"]
			row["max_delta"] = res["max_delta"]
			row["mean_delta"] = snappedf(float(res["mean_delta"]), 0.1)
			row["bbox"] = [bb.position.x, bb.position.y, bb.size.x, bb.size.y] if bb.has_area() else []
			row["where"] = Diff.region_name(bb, Vector2i(cur.get_width(), cur.get_height()))
			row["ignored_pct"] = snappedf(100.0 * float(res["ignored_px"]) / float(maxi(1, cur.get_width() * cur.get_height())), 0.01)
			var heat := Diff.heatmap(cur, res, mask)
			_save_png(heat, latest.path_join(id + "_diff.png"))
			_save_png(Diff.compare_strip(golden, cur, heat), latest.path_join(id + "_compare.png"))
		rows.append(row)
		print("  %s %s: %.3f %% changed (%d px), bbox %s, %s" % [row["result"], id, float(row["changed_pct"]),
			int(row["changed_px"]), str(row["bbox"]), row["why"]])
	var overall := "PASS"
	var total := 0
	var worst := 100
	for r: Dictionary in rows:
		total += int(r["score"])
		worst = mini(worst, int(r["score"]))
		if r["result"] == "FAIL":
			overall = "FAIL"
		elif (r["result"] == "WARN" or r["result"] == "NEW") and overall == "PASS":
			overall = "WARN"
	var score := int(round(float(total) / float(maxi(1, rows.size()))))
	_write_scorecard(lab, latest, rows, overall, score, worst)
	if not bool((lab.get(&"args") as Dictionary).has("no-history")):
		var bad := rows.filter(func(r: Dictionary) -> bool: return r["result"] != "PASS").map(
			func(r: Dictionary) -> String: return "%s %s %.2f%%" % [r["id"], r["result"], float(r["changed_pct"])])
		_append_history(lab, "check", overall, score, ", ".join(bad) if not bad.is_empty() else "all %d shots unchanged" % rows.size(), rows)
	print("VISUAL_DIFF_LAB %s score %d (worst %d) - %d shots - %s" % [overall, score, worst, rows.size(), latest.path_join("scorecard.md")])
	return 1 if overall == "FAIL" else 0


static func _write_scorecard(lab: Object, latest: String, rows: Array[Dictionary], overall: String, score: int, worst: int) -> void:
	var notes: Array = lab.get(&"notes")
	var md := PackedStringArray()
	md.append("# Visual Diff Lab scorecard")
	md.append("")
	md.append("**%s** - score **%d** / 100 (worst shot %d) - %s - commit `%s` - tolerance %d / 255 per channel - 1600x900" % [
		overall, score, worst, _stamp(), lab.get(&"commit"), lab.get(&"tolerance")])
	md.append("")
	md.append("Thresholds: PASS <= %.2f %% changed pixels (or < %d px), WARN <= %.1f %%, FAIL above. Score = 100 at 0 %%, 0 at %.0f %%. " % [
		Diff.PASS_PCT, Diff.MIN_CHANGED_PX, Diff.WARN_PCT, Diff.SCORE_ZERO_PCT] +
		"Images in this folder: `<shot>.png` (now), `<shot>_diff.png` (heatmap: yellow small / red big change, blue ignored, magenta box), `<shot>_compare.png` (golden | now | heatmap).")
	md.append("")
	md.append("| Shot | Result | Score | Changed | Pixels | Max delta | Change box (x, y, w, h) | Where | Unstable px | Ignored | Why |")
	md.append("|---|---|---|---|---|---|---|---|---|---|---|")
	for r: Dictionary in rows:
		var bb: Array = r["bbox"]
		md.append("| %s | **%s** | %d | %.3f %% | %d | %d | %s | %s | %d | %.2f %% | %s |" % [r["id"], r["result"], int(r["score"]),
			float(r["changed_pct"]), int(r["changed_px"]), int(r["max_delta"]),
			"%d, %d, %d, %d" % [bb[0], bb[1], bb[2], bb[3]] if bb.size() == 4 else "-", r["where"], int(r["unstable_px"]),
			float(r["ignored_pct"]), r["why"]])
	md.append("")
	md.append("## Look at next")
	var any := false
	for r: Dictionary in rows:
		if r["result"] == "PASS":
			continue
		any = true
		if r["result"] == "NEW":
			md.append("- **%s**: %s." % [r["id"], r["why"]])
		else:
			md.append("- **%s** (%s): open `%s_compare.png`. Intended change -> re-record: `tools\\visual_diff_lab\\run_visual_diff_lab.ps1 -Golden -Shots %s`. Accidental -> find the commit that touched the %s of this shot." % [
				r["id"], r["why"], r["id"], r["id"], r["where"]])
	if not any:
		md.append("- Nothing: every shot matches its golden.")
	for r2: Dictionary in rows:
		if int(r2["unstable_px"]) > 2000:
			md.append("- **%s** has %d unstable px (they move between two captures of the frozen frame): an animation still runs while paused; add an ignore rect or freeze it." % [r2["id"], int(r2["unstable_px"])])
	if not notes.is_empty():
		md.append("")
		md.append("## Notes")
		for n: Variant in notes:
			md.append("- %s" % n)
	md.append("")
	var f := FileAccess.open(latest.path_join("scorecard.md"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(md))
		f.close()
	var j := FileAccess.open(latest.path_join("scorecard.json"), FileAccess.WRITE)
	if j:
		j.store_string(JSON.stringify({"when": _stamp(), "commit": lab.get(&"commit"), "result": overall, "score": score,
			"worst": worst, "tolerance": lab.get(&"tolerance"), "shots": rows, "notes": notes}, "\t"))
		j.close()


static func _append_history(lab: Object, mode: String, result: String, score: int, summary: String, rows: Array = []) -> void:
	var out: String = lab.get(&"out_dir")
	DirAccess.make_dir_recursive_absolute(out)
	var md_path := out.path_join("history.md")
	var new_file := not FileAccess.file_exists(md_path)
	var f := FileAccess.open(md_path, FileAccess.READ_WRITE if not new_file else FileAccess.WRITE)
	if f:
		if new_file:
			f.store_string("# Visual Diff Lab history\n\nOne row per lab run (`tools/visual_diff_lab/run_visual_diff_lab.ps1`, " +
				"docs/plan/visual-diff-lab.md). Mode `golden` = the references were (re)recorded; `check` = diff against them.\n\n" +
				"| When | Commit | Mode | Result | Score | Summary |\n|---|---|---|---|---|---|\n")
		else:
			f.seek_end()
		f.store_string("| %s | %s | %s | %s | %s | %s |\n" % [_stamp(), lab.get(&"commit"), mode, result,
			"-" if score < 0 else str(score), summary.replace("|", "/")])
		f.close()
	var jl_path := out.path_join("history.jsonl")
	var jf := FileAccess.open(jl_path, FileAccess.READ_WRITE if FileAccess.file_exists(jl_path) else FileAccess.WRITE)
	if jf:
		jf.seek_end()
		var slim: Array = rows.map(func(r: Dictionary) -> Dictionary: return {"id": r["id"], "result": r["result"],
			"changed_pct": r["changed_pct"], "bbox": r["bbox"]})
		jf.store_string(JSON.stringify({"when": _stamp(), "commit": lab.get(&"commit"), "mode": mode, "result": result,
			"score": score, "shots": slim}) + "\n")
		jf.close()
