extends RefCounted
## Data Lab (docs/plan/data-lab.md): the scorecard. Same format as the Art Lab (tools/art_lab/lab_report.gd):
## one row per check with PASS / WARN / FAIL / INFO, the measured value, the rule and a fix hint, a 0-100 score,
## an "Improve next" list (always >= 3 items), every finding listed (resource, field, what is wrong, the fix), extra
## tables (the cross-kingdom balance table) and one row per run in docs/data/lab/history.md.
## No class_name on purpose: tools/ scripts are preloaded, so a new lab never needs an editor import.

const VERSION := "1.1"
## Who fixes a finding (CLAUDE.md "Who owns what"): longest path prefix of its `where`. Balance calls (B1 / F6)
## are design decisions: game-designer. Anything else: the lead.
const OWNER_PREFIXES := [["data/units/", "gameplay-coder"], ["data/spells/", "gameplay-coder"],
	["data/champions/", "gameplay-coder"], ["data/champion_classes/", "gameplay-coder"], ["scripts/units/", "gameplay-coder"],
	["scripts/spells/", "gameplay-coder"], ["data/buildings/", "systems-coder"], ["scripts/buildings/", "systems-coder"],
	["scripts/economy/", "systems-coder"], ["scripts/world/", "systems-coder"], ["scripts/campaign/", "systems-coder"],
	["missions/", "systems-coder"], ["data/items/", "items-coder"], ["scripts/items/", "items-coder"],
	["data/ai/", "ai-coder"], ["scripts/ai/", "ai-coder"], ["scripts/ui/", "ui-coder"], ["scenes/ui/", "ui-coder"],
	["docs/design/", "game-designer"]]
const DESIGN_CHECKS: Array[String] = ["B1", "F6"]
const GROUP_WEIGHT := {"load": 2.0, "fields": 1.5, "refs": 1.5, "keys": 1.5, "text": 1.0, "ai": 1.0, "balance": 0.5}
const GROUP_TITLE := {"load": "Load (every resource loads, ids match files)", "fields": "Fields and bounds",
	"refs": "References (files, ids, abilities, items)", "keys": "Hotkeys", "text": "Text (names, tooltips, width, French readiness)",
	"ai": "AI profiles (data/ai + built-in presets)", "balance": "Balance (INFO / WARN only)"}
const GROUP_ORDER: Array[String] = ["load", "fields", "refs", "keys", "text", "ai", "balance"]
const SEVERITY := {"FAIL": 3, "WARN": 2, "INFO": 1, "PASS": 0}

var run_id: String = ""
var started: String = ""
var seconds: float = 0.0
var checks: Array[Dictionary] = []
var findings: Array[Dictionary] = []   # {check, sev, where, what, fix}
var tables: Array[Dictionary] = []     # {title, markdown}
var notes: Array[String] = []
var extras: Array[Dictionary] = []     # fallback "Improve next" ideas {title, text, source}
var previous_score: float = -1.0
var counts_scanned: Dictionary = {}    # kind -> number of resources checked
var extra_files: Dictionary = {}       # file name -> text, written next to the scorecard (ui_strings.csv)


## Adds one check built from its findings. `total` = items looked at (units, keys...), `issues` = [{sev, where,
## what, fix}] (sev FAIL / WARN / INFO). Status = the worst issue; the score is graded by the share of clean items so
## fixing one of five problems moves it. `info_only` = the check never FAILs or WARNs by itself (INFO rows).
func add_check(id: String, group: String, check_name: String, rule: String, total: int, issues: Array,
		hint: String = "", improve: String = "", weight: float = 1.0, value_override: String = "") -> Dictionary:
	var worst := "PASS"
	var bad := {}
	for it: Dictionary in issues:
		var sev: String = it.get("sev", "WARN")
		if int(SEVERITY[sev]) > int(SEVERITY[worst]):
			worst = sev
		if sev == "FAIL" or sev == "WARN":
			bad[String(it.get("where", ""))] = true
		findings.append({"check": id, "sev": sev, "where": it.get("where", ""), "what": it.get("what", ""),
			"fix": it.get("fix", hint), "owner": owner_of(String(it.get("where", "")), id)})
	var status := worst
	if status == "INFO" and total > 0:
		status = "PASS"
	var clean := maxi(0, total - bad.size())
	var value := value_override
	if value == "":
		var nf := _count_sev(issues, "FAIL")
		var nw := _count_sev(issues, "WARN")
		value = "%d / %d clean" % [clean, total]
		if nf + nw > 0:
			value += " (%d FAIL, %d WARN)" % [nf, nw]
		var ni := _count_sev(issues, "INFO")
		if ni > 0:
			value += ", %d info" % ni
	var graded := float(clean) / float(total) if total > 0 else 1.0
	var c := {"id": id, "group": group, "name": check_name, "status": status, "value": value, "rule": rule,
		"hint": hint, "improve": improve, "weight": weight, "total": total}
	c["score"] = _score_of(status, graded)
	checks.append(c)
	return c


## An INFO row (no score): tables, lists, notes.
func add_info(id: String, group: String, check_name: String, value: String, rule: String = "") -> void:
	checks.append({"id": id, "group": group, "name": check_name, "status": "INFO", "value": value, "rule": rule,
		"hint": "", "improve": "", "weight": 0.0, "total": 0, "score": -1.0})


func add_table(title: String, markdown: String) -> void:
	tables.append({"title": title, "markdown": markdown})


static func owner_of(where: String, check_id: String) -> String:
	if DESIGN_CHECKS.has(check_id):
		return "game-designer"
	var w := where.trim_prefix("res://")
	var best := ""
	var best_len := -1
	for p: Array in OWNER_PREFIXES:
		var pre: String = p[0]
		if w.begins_with(pre) and pre.length() > best_len:
			best = p[1]
			best_len = pre.length()
	return best if best != "" else "lead"


## Findings of one severity grouped by owner, then by (check, fix): one line per fix with every place it applies.
func _fix_list_markdown() -> String:
	var by_owner := {}
	for f: Dictionary in findings:
		if f["sev"] != "FAIL" and f["sev"] != "WARN":
			continue
		var o: String = f.get("owner", "lead")
		if not by_owner.has(o):
			by_owner[o] = {}
		var k := "%s|%s|%s" % [f["sev"], f["check"], f["fix"]]
		if not (by_owner[o] as Dictionary).has(k):
			by_owner[o][k] = []
		(by_owner[o][k] as Array).append(f)
	if by_owner.is_empty():
		return "Nothing to fix.\n"
	var owners := by_owner.keys()
	owners.sort()
	var s := ""
	for o: String in owners:
		var groups: Dictionary = by_owner[o]
		var n := 0
		for k: String in groups:
			n += (groups[k] as Array).size()
		s += "### %s (%d findings; handoff: docs/handoff/for-%s.md)\n" % [o, n, o]
		var keys := groups.keys()
		keys.sort()
		for k: String in keys:
			var list: Array = groups[k]
			var f0: Dictionary = list[0]
			var places: Array[String] = []
			for f: Dictionary in list:
				places.append("`%s` (%s)" % [String(f["where"]).get_file() if String(f["where"]).contains("/") else f["where"],
					_cell(f["what"]).left(90)])
			s += "- **%s %s**: %s -> %s\n" % [f0["sev"], f0["check"], _cell(f0["fix"]), "; ".join(places)]
		s += "\n"
	return s


## INFO findings whose text only differs by a letter / number (e.g. "card_key V is set but no code reads it") are
## one row with every place, so the list stays readable.
func _info_markdown(infos: Array[Dictionary]) -> String:
	var re_letter := RegEx.create_from_string("\\b[A-Z]\\b")
	var re_num := RegEx.create_from_string("-?\\d+(\\.\\d+)?")
	var groups := {}
	var order: Array[String] = []
	for f: Dictionary in infos:
		var shape := re_num.sub(re_letter.sub(String(f["what"]), "?", true), "N", true)
		var k := "%s|%s" % [f["check"], shape]
		if not groups.has(k):
			groups[k] = []
			order.append(k)
		(groups[k] as Array).append(f)
	var s := "| Check | Where | What |\n|---|---|---|\n"
	for k: String in order:
		var list: Array = groups[k]
		if list.size() < 3:
			for f: Dictionary in list:
				s += "| %s | %s | %s |\n" % [f["check"], _cell(f["where"]), _cell(f["what"])]
			continue
		var places: Array[String] = []
		for f: Dictionary in list:
			places.append(String(f["where"]).get_file())
		s += "| %s | %d places: %s | %s (e.g.) |\n" % [list[0]["check"], list.size(), _cell(", ".join(places)),
			_cell(list[0]["what"])]
	return s


static func _count_sev(issues: Array, sev: String) -> int:
	var n := 0
	for it: Dictionary in issues:
		if it.get("sev", "") == sev:
			n += 1
	return n


static func _score_of(status: String, graded: float) -> float:
	var g := clampf(graded, 0.0, 1.0)
	match status:
		"PASS":
			return 1.0
		"WARN":
			return lerpf(0.35, 0.69, g)
		"FAIL":
			return lerpf(0.0, 0.34, g)
	return -1.0


func count(status: String) -> int:
	var n := 0
	for c: Dictionary in checks:
		if c["status"] == status:
			n += 1
	return n


func count_findings(sev: String) -> int:
	var n := 0
	for f: Dictionary in findings:
		if f["sev"] == sev:
			n += 1
	return n


func result() -> String:
	if count("FAIL") > 0:
		return "FAIL"
	if count("WARN") > 0:
		return "WARN"
	return "PASS"


func quality() -> float:
	var sw := 0.0
	var ss := 0.0
	for c: Dictionary in checks:
		var s: float = c["score"]
		if s < 0.0:
			continue
		var w: float = float(c["weight"]) * float(GROUP_WEIGHT.get(c["group"], 1.0))
		sw += w
		ss += w * s
	return 100.0 * ss / sw if sw > 0.0 else 0.0


## FAIL checks first, then WARN, then the most weighted headroom; each item names its first finding. Topped up
## with `extras` so there are always >= min_items.
func improve_next(min_items: int = 3, max_items: int = 8) -> Array[Dictionary]:
	var cands: Array[Dictionary] = []
	for c: Dictionary in checks:
		if float(c["score"]) < 0.0 or float(c["score"]) >= 0.999:
			continue
		var w: float = float(c["weight"]) * float(GROUP_WEIGHT.get(c["group"], 1.0))
		var rank: float = w * (1.0 - float(c["score"]))
		if c["status"] == "FAIL":
			rank += 100.0
		elif c["status"] == "WARN":
			rank += 10.0
		var first := _first_finding(String(c["id"]))
		var text: String = String(c["improve"]) if String(c["improve"]) != "" else String(c["hint"])
		if not first.is_empty():
			text = "%s: %s -> %s" % [first["where"], first["what"], first["fix"]] + ("" if text == "" else " (%s)" % text)
		cands.append({"rank": rank, "title": c["name"], "text": text, "source": "%s %s" % [c["id"], c["value"]],
			"status": c["status"]})
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rank"]) > float(b["rank"]))
	var out: Array[Dictionary] = []
	for c2: Dictionary in cands:
		if out.size() >= max_items:
			break
		out.append(c2)
	for e: Dictionary in extras:
		if out.size() >= min_items:
			break
		out.append({"rank": 0.0, "title": e["title"], "text": e["text"], "source": e["source"], "status": "IDEA"})
	return out


func _first_finding(check_id: String) -> Dictionary:
	for sev: String in ["FAIL", "WARN"]:
		for f: Dictionary in findings:
			if f["check"] == check_id and f["sev"] == sev:
				return f
	return {}


func exit_code() -> int:
	return 1 if result() == "FAIL" else 0


# ---------------------------------------------------------------- writers

func to_dict() -> Dictionary:
	return {
		"lab_version": VERSION, "run": run_id, "started": started, "seconds": snappedf(seconds, 0.01),
		"result": result(), "quality": snappedf(quality(), 0.1), "previous_quality": snappedf(previous_score, 0.1),
		"counts": {"PASS": count("PASS"), "WARN": count("WARN"), "FAIL": count("FAIL"), "INFO": count("INFO")},
		"finding_counts": {"FAIL": count_findings("FAIL"), "WARN": count_findings("WARN"), "INFO": count_findings("INFO")},
		"scanned": counts_scanned, "checks": checks, "findings": findings, "improve_next": improve_next(),
		"tables": tables, "notes": notes,
	}


func to_markdown() -> String:
	var q := quality()
	var s := "# Data Lab scorecard: %s\n\n" % run_id
	var scanned: Array[String] = []
	for k: String in counts_scanned:
		scanned.append("%d %s" % [int(counts_scanned[k]), k])
	s += "%s · lab v%s · %.2f s · scanned %s\n\n" % [started, VERSION, seconds, ", ".join(scanned)]
	var delta := ""
	if previous_score >= 0.0:
		delta = " (previous run %.0f, %+d)" % [previous_score, int(round(q - previous_score))]
	s += "## Result: **%s** · score **%.0f / 100**%s\n\n" % [result(), q, delta]
	s += "%d FAIL · %d WARN · %d PASS · %d info checks; findings: %d FAIL, %d WARN, %d info\n\n" % [count("FAIL"),
		count("WARN"), count("PASS"), count("INFO"), count_findings("FAIL"), count_findings("WARN"), count_findings("INFO")]
	s += "## Improve next\n"
	var i := 1
	for it: Dictionary in improve_next():
		s += "%d. **%s** (%s): %s _(from %s)_\n" % [i, it["title"], it["status"], _cell(it["text"]), _cell(it["source"])]
		i += 1
	s += "\n"
	s += "## Fix list by owner (paste into docs/handoff/for-<owner>.md)\n" + _fix_list_markdown() + "\n"
	for g: String in GROUP_ORDER:
		var rows: Array[Dictionary] = []
		for c: Dictionary in checks:
			if c["group"] == g:
				rows.append(c)
		if rows.is_empty():
			continue
		s += "## %s\n| # | Check | Result | Measured | Rule | Fix hint |\n|---|---|---|---|---|---|\n" % GROUP_TITLE.get(g, g)
		for c: Dictionary in rows:
			var st: String = c["status"]
			if st == "FAIL" or st == "WARN":
				st = "**%s**" % st
			if float(c["score"]) >= 0.0:
				st += " %.0f" % (100.0 * float(c["score"]))
			var hint: String = c["hint"] if c["status"] == "FAIL" or c["status"] == "WARN" else ""
			s += "| %s | %s | %s | %s | %s | %s |\n" % [c["id"], c["name"], st, _cell(c["value"]), _cell(c["rule"]),
				_cell(hint)]
		s += "\n"
	s += "## Findings (FAIL and WARN)\n"
	var bad := 0
	for sev: String in ["FAIL", "WARN"]:
		for f: Dictionary in findings:
			if f["sev"] != sev:
				continue
			if bad == 0:
				s += "| Sev | Check | Owner | Where | What | Fix |\n|---|---|---|---|---|---|\n"
			bad += 1
			s += "| %s | %s | %s | %s | %s | %s |\n" % [sev, f["check"], f.get("owner", ""), _cell(f["where"]), _cell(f["what"]),
				_cell(f["fix"])]
	if bad == 0:
		s += "None.\n"
	s += "\n"
	for t: Dictionary in tables:
		s += "## %s\n%s\n\n" % [t["title"], t["markdown"]]
	var infos: Array[Dictionary] = []
	for f: Dictionary in findings:
		if f["sev"] == "INFO":
			infos.append(f)
	if not infos.is_empty():
		s += "## Info findings (%d)\n" % infos.size() + _info_markdown(infos) + "\n"
	if not notes.is_empty():
		s += "## Notes\n"
		for n: String in notes:
			s += "- %s\n" % n
	return s


static func _cell(v: Variant) -> String:
	return str(v).replace("|", "/").replace("\n", " ")


func write(out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var f := FileAccess.open(out_dir.path_join("scorecard.md"), FileAccess.WRITE)
	if f:
		f.store_string(to_markdown())
		f.close()
	var j := FileAccess.open(out_dir.path_join("scorecard.json"), FileAccess.WRITE)
	if j:
		j.store_string(JSON.stringify(to_dict(), "\t"))
		j.close()
	for name: String in extra_files:
		var e := FileAccess.open(out_dir.path_join(name), FileAccess.WRITE)
		if e:
			e.store_string(String(extra_files[name]))
			e.close()


## Appends one row to the history log (created with its header the first time).
func append_history(log_path: String, out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(log_path.get_base_dir()))
	var exists := FileAccess.file_exists(log_path)
	var f := FileAccess.open(log_path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if f == null:
		return
	if not exists:
		f.store_string("# Data Lab history\n\nOne row per run (`tools/data_lab/data_lab.gd`, docs/plan/data-lab.md). " +
			"Score 0-100 (higher is better); the delta is against the previous row.\n\n" +
			"| When | Run | Score | Result | Findings | Top suggestions | Scorecard |\n|---|---|---|---|---|---|---|\n")
	else:
		f.seek_end()
	var q := quality()
	var d := ""
	if previous_score >= 0.0:
		d = " (%+d)" % int(round(q - previous_score))
	var tops: Array[String] = []
	for it: Dictionary in improve_next():
		if tops.size() >= 3:
			break
		tops.append(String(it["title"]))
	f.store_string("| %s | %s | %.0f%s | %s (%dF %dW checks) | %d FAIL, %d WARN | %s | %s |\n" % [started, run_id, q, d,
		result(), count("FAIL"), count("WARN"), count_findings("FAIL"), count_findings("WARN"), "; ".join(tops),
		out_dir.path_join("scorecard.md").replace("res://", "")])
	f.close()


## The score of the last row of the history log (-1 when none).
static func read_previous(log_path: String) -> float:
	if not FileAccess.file_exists(log_path):
		return -1.0
	var lines := FileAccess.get_file_as_string(log_path).split("\n", false)
	for k in range(lines.size() - 1, -1, -1):
		var cols := lines[k].split("|")
		if cols.size() > 4 and cols[3].strip_edges().split(" ")[0].is_valid_float():
			return cols[3].strip_edges().split(" ")[0].to_float()
	return -1.0
