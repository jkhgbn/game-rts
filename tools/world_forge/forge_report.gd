extends ToolReport
## World Forge scorecard = the shared `ToolReport` (tools/common/tool_report.gd: Art Lab scorecard format, report.md +
## report.json in docs/tools/world_forge/out/<id>/, one row in docs/tools/world_forge/history.md, printed summary).
## `fcheck` files each check under a group from its id prefix; `files` lists what the run wrote (kept in the notes).
## No class_name on purpose (preloaded tool script).

const GROUPS := [["K", "contract", "Set contract", 2.0], ["B", "budget", "Budgets", 1.5], ["S", "scatter", "Scatter", 1.0],
	["M", "marks", "Camera marks", 2.0], ["D", "determinism", "Determinism", 1.0], ["L", "layout", "Layout", 1.5],
	["N", "nav", "Navmesh", 1.0], ["LAB", "lab", "Map Lab", 2.0], ["R", "roundtrip", "Round trip", 1.5], ["E", "export", "Export", 1.0]]

var files: Array[String] = []


## Sets tool / verb / id / out dir like ToolReport.start (verb check / build -> report.md, others report_<verb>.md).
func setup(verb_name: String, asset_id: String) -> void:
	tool = "world_forge"
	verb = verb_name
	id = asset_id
	asset = asset_id
	kind = verb_name
	started = Time.get_datetime_string_from_system(false, true)
	out_dir = ToolReport.out_dir_of(tool, asset_id)
	previous_score = ToolReport.read_previous_quality(out_dir, verb_name)
	for g: Array in GROUPS:
		add_group(g[1], g[2], g[3])


func group_of(cid: String) -> String:
	if cid.begins_with("LAB"):
		return "lab"
	for g: Array in GROUPS:
		if g[0] != "LAB" and cid.begins_with(g[0]):
			return g[1]
	return "other"


## One check: status PASS / WARN / FAIL / INFO, measured value, rule, fix hint, weight.
func fcheck(cid: String, check_name: String, status: String, value: Variant, rule: String, hint := "", weight := 1.0) -> Dictionary:
	return add(cid, group_of(cid), check_name, status, str(value), rule, hint, -1.0, hint if status in ["FAIL", "WARN"] else "", "", weight)


## Writes the report (+ the history row when `log`), prints the summary; returns the exit code.
func done(log := true) -> int:
	if not files.is_empty():
		var shown: Array[String] = []
		for f in files:
			shown.append("`%s`" % f.replace("res://", ""))
		notes.append("Files: " + ", ".join(shown))
	for f in files:
		if f.ends_with(".png") and f.begins_with(out_dir):
			shots[f.get_file().get_basename()] = f.trim_prefix(out_dir + "/")
	return finish(log)
