class_name ToolReport
extends ArtLabReport
## The shared tool report (docs/plan/tools-wave.md section 0 "Readable out"; API in tools/common/README.md): the Art Lab
## scorecard format (tools/art_lab/lab_report.gd: PASS / WARN / FAIL / INFO / SKIP + measured value + rule + fix hint,
## score 0-100, "Improve next") written as docs/tools/<tool>/out/<id>/report.md + report.json, plus one row in
## docs/tools/<tool>/history.md. Everything of ArtLabReport works (`add`, `grade`, `count`, `result`, `quality`,
## `improve_next`, `exit_code`, `extras`, `notes`, `shots`); groups are free-form, declared with `add_group`.
##   var rep := ToolReport.start("cine", "check", "watch_keep")
##   rep.add_group("resolve", "Resolve (sets, markers, actors, cues)")
##   rep.add("R1", "resolve", "marker @P3_from", "FAIL", "missing", "every marker exists", "add P3_from to marks.json")
##   rep.finish()            # writes report.md / report.json / history row, prints the summary; then quit(rep.exit_code())

var tool: String = ""
var verb: String = ""
var id: String = ""
var hash_value: String = ""                 # determinism hash of the output (printed in the report and the history row)
var hash_note: String = ""            # e.g. "2 runs identical"
var group_order: Array[String] = []
var group_titles: Dictionary = {}
var group_weights: Dictionary = {}
var out_dir: String = ""
var _t0: int = 0


static func start(tool_name: String, verb_name: String, asset_id: String) -> ToolReport:
	var r := ToolReport.new()
	r.tool = tool_name
	r.verb = verb_name
	r.id = asset_id
	r.asset = asset_id
	r.kind = verb_name
	r.started = Time.get_datetime_string_from_system(false, true)
	r.out_dir = ToolReport.out_dir_of(tool_name, asset_id)
	r.previous_score = ToolReport.read_previous_quality(r.out_dir, verb_name)
	r._t0 = Time.get_ticks_msec()
	return r


## Grades a value against a "bad" and a "good" end (either direction): 0 at bad, 1 at good. (Own copy: the Art Lab
## moved its version to ArtLabScore; this API stays here for every tool.)
static func grade(value: float, bad: float, good: float) -> float:
	if is_equal_approx(bad, good):
		return 1.0 if value >= good else 0.0
	return clampf((value - bad) / (good - bad), 0.0, 1.0)


## PASS / WARN / FAIL of a value against a budget {limit, hard}: over a hard limit = FAIL, over a soft one = WARN.
static func budget_status(value: float, lim: Dictionary) -> String:
	if lim.is_empty():
		return "INFO"
	if value <= float(lim["limit"]):
		return "PASS"
	return "FAIL" if bool(lim["hard"]) else "WARN"


static func out_dir_of(tool_name: String, asset_id: String) -> String:
	return "res://docs/tools/%s/out/%s" % [tool_name, asset_id]


static func history_path(tool_name: String) -> String:
	return "res://docs/tools/%s/history.md" % tool_name


## Declares a group (report section) in display order; `weight` feeds the quality score (default 1).
func add_group(group_id: String, title: String, weight: float = 1.0) -> void:
	if not group_id in group_order:
		group_order.append(group_id)
	group_titles[group_id] = title
	group_weights[group_id] = weight


## Shortcut for a check without a graded score: add(id, group, name, status, value, rule, hint, -1, improve).
func check(check_id: String, group: String, check_name: String, status: String, value: Variant, rule: String,
		hint: String = "", improve: String = "", shot: String = "") -> Dictionary:
	return add(check_id, group, check_name, status, str(value), rule, hint, -1.0, improve, shot)


func quality() -> float:
	var sw := 0.0
	var ss := 0.0
	for c: Dictionary in checks:
		var s: float = c["score"]
		if s < 0.0:
			continue
		var w: float = float(c["weight"]) * float(group_weights.get(c["group"], 1.0))
		sw += w
		ss += w * s
	return 100.0 * ss / sw if sw > 0.0 else 0.0


## FAIL / WARN lines, one per check: `FAIL R3 marker @P3_from: missing -> add P3_from ...`.
func problem_lines() -> Array[String]:
	var out: Array[String] = []
	for st: String in ["FAIL", "WARN"]:
		for c: Dictionary in checks:
			if c["status"] == st:
				var h: String = c["hint"]
				out.append("%s %s %s: %s%s" % [st, c["id"], c["name"], c["value"], (" -> " + h) if h != "" else ""])
	return out


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d.erase("lab_version")
	d["tool"] = tool
	d["verb"] = verb
	d["id"] = id
	d["hash"] = hash_value
	d["hash_note"] = hash_note
	d["seconds"] = snappedf(seconds, 0.1)
	d["groups"] = group_titles
	return d


func to_markdown() -> String:
	var q := quality()
	var s := "# %s %s: %s\n\n" % [tool, verb, id]
	s += "%s - `tools/%s/run_%s.ps1 %s %s`%s\n\n" % [started, tool, tool, verb, id,
		(" - hash `%s`%s" % [hash_value, (" (" + hash_note + ")") if hash_note != "" else ""]) if hash_value != "" else ""]
	var delta := ""
	if previous_score >= 0.0:
		delta = " (previous run %.0f, %+d)" % [previous_score, int(round(q - previous_score))]
	s += "## Result: **%s** - quality **%.0f / 100**%s\n\n" % [result(), q, delta]
	s += "%d FAIL, %d WARN, %d PASS, %d info, %d skipped, %.0f s\n\n" % [count("FAIL"), count("WARN"), count("PASS"),
		count("INFO"), count("SKIP"), seconds]
	s += "## Improve next\n"
	var i := 1
	for it: Dictionary in improve_next():
		s += "%d. **%s** (%s): %s _(from %s)_\n" % [i, it["title"], it["status"], it["text"], it["source"]]
		i += 1
	s += "\n"
	var groups: Array[String] = group_order.duplicate()
	for c0: Dictionary in checks:
		if not String(c0["group"]) in groups:
			groups.append(String(c0["group"]))
	for g: String in groups:
		var rows: Array[Dictionary] = []
		for c: Dictionary in checks:
			if c["group"] == g:
				rows.append(c)
		if rows.is_empty():
			continue
		s += "## %s\n| # | Check | Result | Measured | Rule | Fix hint |\n|---|---|---|---|---|---|\n" % group_titles.get(g, g)
		for c: Dictionary in rows:
			var st: String = c["status"]
			if st == "FAIL" or st == "WARN":
				st = "**%s**" % st
			if float(c["score"]) >= 0.0 and c["status"] != "SKIP":
				st += " %.0f" % (100.0 * float(c["score"]))
			var hint: String = c["hint"] if c["status"] == "FAIL" or c["status"] == "WARN" else ""
			s += "| %s | %s | %s | %s | %s | %s |\n" % [c["id"], _cell(c["name"]), st, _cell(c["value"]), _cell(c["rule"]),
				_cell(hint)]
		s += "\n"
	if not shots.is_empty():
		s += "## Images\n"
		for k: String in shots:
			s += "- %s: [%s](%s)\n" % [k, shots[k], shots[k]]
		s += "\n"
	if not notes.is_empty():
		s += "## Notes\n"
		for n: String in notes:
			s += "- %s\n" % n
	return s


## Writes `report.md` + `report.json` in `dir` (default: docs/tools/<tool>/out/<id>/). A verb other than check / build
## also writes `report_<verb>.md` / `.json` so `sheet` does not overwrite the `check` report.
func write(dir: String = "") -> void:
	var d := dir if dir != "" else out_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var base := "report" if verb in ["check", "build", ""] else "report_" + verb
	var f := FileAccess.open(d.path_join(base + ".md"), FileAccess.WRITE)
	if f:
		f.store_string(to_markdown())
		f.close()
	var j := FileAccess.open(d.path_join(base + ".json"), FileAccess.WRITE)
	if j:
		j.store_string(JSON.stringify(to_dict(), "\t"))
		j.close()


## Appends one row to docs/tools/<tool>/history.md (created with its header the first time).
func append_history(path: String = "") -> void:
	var p := path if path != "" else ToolReport.history_path(tool)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.get_base_dir()))
	var exists := FileAccess.file_exists(p)
	var f := FileAccess.open(p, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if f == null:
		return
	if not exists:
		f.store_string("# %s history\n\nOne row per run (`tools/%s/run_%s.ps1`). Quality 0-100; delta vs the previous run of the same verb.\n\n" % [tool, tool, tool] +
			"| When | Verb | Id | Quality | Result | Hash | Top suggestions | Report |\n|---|---|---|---|---|---|---|---|\n")
	else:
		f.seek_end()
	var q := quality()
	var dl := ""
	if previous_score >= 0.0:
		dl = " (%+d)" % int(round(q - previous_score))
	var tops: Array[String] = []
	for it: Dictionary in improve_next():
		if tops.size() >= 3:
			break
		tops.append(String(it["title"]))
	var base := "report" if verb in ["check", "build", ""] else "report_" + verb
	f.store_string("| %s | %s | %s | %.0f%s | %s (%dF %dW) | %s | %s | %s |\n" % [started, verb, id, q, dl, result(),
		count("FAIL"), count("WARN"), hash_value, _cell("; ".join(tops)), out_dir.path_join(base + ".md").replace("res://", "")])
	f.close()


## Prints the machine-readable tail every tool ends with:
##   `<TOOL> <verb> <id>: <RESULT> quality <q> (<f> FAIL, <w> WARN) hash <h> -> <report path>` + every FAIL / WARN line.
func print_summary() -> void:
	print("%s %s %s: %s quality %.0f (%d FAIL, %d WARN) hash %s -> %s" % [tool.to_upper(), verb, id, result(), quality(),
		count("FAIL"), count("WARN"), hash_value if hash_value != "" else "-", out_dir.replace("res://", "")])
	for l: String in problem_lines():
		print("  " + l)


## write + append_history + print_summary. Returns the exit code (0 PASS / WARN, 1 FAIL).
func finish(log_history: bool = true) -> int:
	seconds = float(Time.get_ticks_msec() - _t0) / 1000.0
	write()
	if log_history:
		append_history()
	print_summary()
	return exit_code()


static func read_previous_quality(dir: String, verb_name: String) -> float:
	var base := "report" if verb_name in ["check", "build", ""] else "report_" + verb_name
	var p := dir.path_join(base + ".json")
	if not FileAccess.file_exists(p):
		return -1.0
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d is Dictionary and (d as Dictionary).has("quality"):
		return float((d as Dictionary)["quality"])
	return -1.0


## The hash stored by the previous run of this verb ("" when none): for "same as last run" determinism checks.
static func read_previous_hash(dir: String, verb_name: String) -> String:
	var base := "report" if verb_name in ["check", "build", ""] else "report_" + verb_name
	var p := dir.path_join(base + ".json")
	if not FileAccess.file_exists(p):
		return ""
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d is Dictionary:
		return String((d as Dictionary).get("hash", ""))
	return ""
