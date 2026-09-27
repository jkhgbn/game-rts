extends RefCounted
## World Forge scorecard (the lab scorecard format: PASS / WARN / FAIL / INFO, measured value, rule, fix hint, score
## 0-100, "Improve next"). Writes docs/tools/world_forge/out/<id>/report.md + report.json and one row in
## docs/tools/world_forge/history.md. Swap to tools/common/tool_report.gd once it is frozen (same fields).
## No class_name on purpose (preloaded tool script).

const HISTORY := "res://docs/tools/world_forge/history.md"

var title := ""
var id := ""
var kind := ""          ## "set" / "map" / "export"
var checks: Array[Dictionary] = []
var notes: Array[String] = []
var files: Array[String] = []
var hash := ""
var seconds := 0.0


func add(cid: String, name: String, status: String, value: String, rule: String, hint := "", weight := 1.0) -> void:
	checks.append({"id": cid, "name": name, "status": status, "value": value, "rule": rule, "hint": hint, "weight": weight})


func count(status: String) -> int:
	var n := 0
	for c in checks:
		if c["status"] == status:
			n += 1
	return n


func result() -> String:
	if count("FAIL") > 0:
		return "FAIL"
	if count("WARN") > 0:
		return "WARN"
	return "PASS"


func score() -> float:
	var tot := 0.0
	var got := 0.0
	for c in checks:
		var s := {"PASS": 1.0, "WARN": 0.5, "FAIL": 0.0}.get(c["status"], -1.0) as float
		if s < 0.0:
			continue
		tot += float(c["weight"])
		got += s * float(c["weight"])
	return 100.0 * got / maxf(0.001, tot)


func exit_code() -> int:
	return 1 if result() == "FAIL" else 0


func improve_next() -> Array[String]:
	var out: Array[String] = []
	for st in ["FAIL", "WARN"]:
		for c in checks:
			if c["status"] == st and c["hint"] != "":
				out.append("%s %s: %s" % [c["id"], c["name"], c["hint"]])
	for c in checks:
		if out.size() >= 3:
			break
		if c["status"] == "INFO" and c["hint"] != "":
			out.append("%s %s: %s" % [c["id"], c["name"], c["hint"]])
	var tips: Array[String] = ["Look at the PNGs in this folder: one question per image (plan = placement, stills = framing).",
		"Run `run_world_forge.ps1 sheet <id>` (windowed) for the real stills of every mark."]
	if kind != "set":
		tips = ["Open layout.png (spots by kind, river, roads) and map_lab/heatmap.png (where paths crowd).",
			"Read map_lab/scorecard.md: its WARN rows (engine path noise F2 is not the map's fault) and Improve next."]
	for t in tips:
		if out.size() < 3:
			out.append(t)
	return out


func write(out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var md := "# %s\n\n**Result: %s**, score **%.0f / 100** (%d FAIL, %d WARN, %d PASS). Hash `%s`. %.1f s.\n\n" % [
		title, result(), score(), count("FAIL"), count("WARN"), count("PASS"), hash, seconds]
	md += "| ID | Check | Status | Measured | Rule | Fix hint |\n|---|---|---|---|---|---|\n"
	for c in checks:
		md += "| %s | %s | %s | %s | %s | %s |\n" % [c["id"], c["name"], c["status"], String(c["value"]).replace("|", "/"),
			String(c["rule"]).replace("|", "/"), String(c["hint"]).replace("|", "/")]
	md += "\n## Improve next\n"
	for s in improve_next():
		md += "- %s\n" % s
	if not files.is_empty():
		md += "\n## Files\n"
		for f in files:
			md += "- `%s`\n" % f
	if not notes.is_empty():
		md += "\n## Notes\n"
		for n in notes:
			md += "- %s\n" % n
	var f := FileAccess.open(out_dir.path_join("report.md"), FileAccess.WRITE)
	f.store_string(md)
	f.close()
	var js := {"tool": "world_forge", "title": title, "id": id, "kind": kind, "result": result(), "score": snappedf(score(), 0.1),
		"hash": hash, "seconds": snappedf(seconds, 0.01), "checks": checks, "improve_next": improve_next(), "files": files, "notes": notes}
	var fj := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE)
	fj.store_string(JSON.stringify(js, "\t"))
	fj.close()


func append_history() -> void:
	var path := HISTORY
	var exists := FileAccess.file_exists(path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if not exists:
		f.store_string("# World Forge history\n\n| When | Kind | Id | Result | Score | FAIL / WARN | Hash |\n|---|---|---|---|---|---|---|\n")
	f.seek_end()
	var now := Time.get_datetime_dict_from_system()
	f.store_string("| %04d-%02d-%02d %02d:%02d | %s | %s | %s | %.0f | %d / %d | `%s` |\n" % [now.year, now.month, now.day, now.hour,
		now.minute, kind, id, result(), score(), count("FAIL"), count("WARN"), hash])
	f.close()


## Console lines: "WORLD FORGE: <RESULT> score N ..." then one line per FAIL / WARN.
func print_summary(out_dir: String) -> void:
	print("WORLD FORGE %s %s: %s score %.0f / 100 (%d FAIL, %d WARN, %d PASS) hash %s -> %s" % [kind, id, result(), score(),
		count("FAIL"), count("WARN"), count("PASS"), hash, out_dir.path_join("report.md")])
	for c in checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			print("  %s %s %s: %s  (fix: %s)" % [c["status"], c["id"], c["name"], c["value"], c["hint"]])
