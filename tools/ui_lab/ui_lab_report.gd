class_name UILabReport
extends RefCounted
## UI Lab (docs/plan/ui-lab.md): the scorecard. One check per (screen, resolution, check type) with PASS / WARN /
## FAIL / SKIP, the items found, a 0-100 quality score and an "Improve next" list (always >= 3 items). Writes
## scorecard.md, scorecard.json and a row in docs/ui/lab/improvement-log.md.

const VERSION := "2.0"
## Check types, in table order: id -> [title, weight, rule, fix hint].
const TYPES := {
	"overflow": ["Text overflow", 2.0, "text fits its own rect and its frame (tol 2 px)",
		"widen the frame / label, shorten the text, or allow wrapping"],
	"offscreen": ["Off-screen", 2.0, "every text / button fully on screen",
		"anchor it to the screen edge it belongs to, or clamp its position to the viewport"],
	"overlap": ["Overlaps", 1.5, "no two text / button rects overlap (>= 12 % of the smaller, >= 24 px2)",
		"move one of them, or hide the lower-priority one while the other shows"],
	"font": ["Min font size", 1.0, "effective size >= 11 px (FAIL < 9)", "raise the font size (ui-style.md sizes: 12+)"],
	"contrast": ["Contrast", 1.5, "WCAG AA: 4.5 (small) / 3.0 (large >= 24 px); FAIL under 2/3 of that",
		"brighter text, darker / more opaque panel, or a 2-3 px outline"],
	"tooltip": ["Tooltips", 1.0, "abbreviated / icon buttons have a tooltip (in-game: every button)",
		"set tooltip_text (the action, its key and its cost)"],
	"hotkeys": ["Hotkeys", 2.0, "no letter twice on the command card; help keys unique outside a context",
		"give each slot its own key; in the help, qualify context keys (\"Flag: Z raise\")"],
	# v2 (2026-09-27): what v1 saw on the shots but did not measure
	"gaps": ["Bottom-bar gaps", 1.5, "HUD: no empty gap > 25 % of the width between the bottom panels (FAIL > 40 %)",
		"anchor the bottom panels to the screen width (stretch the centre bar or spread the blocks), so ultrawide has no hole"],
	"bleed": ["Bleed-through", 2.0, "modal panels: no outside text drawn over them or visible through them (bg alpha >= 0.95)",
		"make the modal panel opaque, put a dimmer behind it, or hide the HUD text while it is open"],
	"icons": ["Icon contrast", 1.0, "switches / check boxes / icon buttons: 3:1 inside the icon (WCAG 1.4.11), FAIL < 2",
		"give the off state a visible track / outline; icons need a lighter or darker core than their button"],
	"edge": ["Edge margin", 1.0, "big panels are flush with a screen edge or >= 8 px from it",
		"move it clear of the edge (>= 8 px; shrink it at small sizes) or flush it"],
}
const TYPE_ORDER: Array[String] = ["overflow", "offscreen", "overlap", "font", "contrast", "tooltip", "hotkeys", "gaps",
	"bleed", "icons", "edge"]

var started := ""
var seconds := 0.0
var headless := false
var resolutions: Array[String] = []
var screens: Array[String] = []
var checks: Array[Dictionary] = []
var shots: Dictionary = {}        # "screen@res" -> relative path
var actual_sizes: Dictionary = {} # res -> "WxH" really obtained
var notes: Array[String] = []
var previous_score := -1.0


## Adds a check from its items: an item with `fail` true (or `fail_all`) makes it FAIL, others WARN; none = PASS.
## `warn_only` caps it at WARN. Returns the check.
func add_items(screen: String, res: String, type: String, items: Array[Dictionary], fail_all := false,
		warn_only := false) -> Dictionary:
	var nf := 0
	for it: Dictionary in items:
		if fail_all or bool(it.get("fail", false)):
			nf += 1
	var status := "PASS"
	if nf > 0 and not warn_only:
		status = "FAIL"
	elif not items.is_empty():
		status = "WARN"
	var score := 1.0 / (1.0 + 0.3 * float(items.size()) + 0.5 * float(nf))
	if status == "PASS":
		score = 1.0
	var c := {"screen": screen, "res": res, "type": type, "status": status, "count": items.size(), "fails": nf,
		"score": score, "items": _clean(items)}
	checks.append(c)
	return c


func add_skip(screen: String, res: String, type: String, why: String) -> void:
	checks.append({"screen": screen, "res": res, "type": type, "status": "SKIP", "count": 0, "fails": 0,
		"score": -1.0, "items": [], "why": why})


static func _clean(items: Array[Dictionary]) -> Array:
	var out := []
	for it: Dictionary in items:
		out.append({"text": str(it.get("text", "")), "value": it.get("value", ""), "detail": str(it.get("detail", "")),
			"fail": bool(it.get("fail", false))})
	return out


func count(status: String) -> int:
	var n := 0
	for c: Dictionary in checks:
		if c["status"] == status:
			n += 1
	return n


func result() -> String:
	if count("FAIL") > 0:
		return "FAIL"
	return "WARN" if count("WARN") > 0 else "PASS"


func quality() -> float:
	var sw := 0.0
	var ss := 0.0
	for c: Dictionary in checks:
		if float(c["score"]) < 0.0:
			continue
		var w: float = TYPES[c["type"]][1]
		sw += w
		ss += w * float(c["score"])
	return 100.0 * ss / sw if sw > 0.0 else 0.0


## The worst cells first (FAIL, then WARN, weighted by type and item count), merged per (screen, type) so the same
## problem at 3 resolutions is one line. Topped up with generic polish ideas to at least `min_items`.
func improve_next(min_items := 3, max_items := 6) -> Array[Dictionary]:
	var merged := {}
	for c: Dictionary in checks:
		if c["status"] != "FAIL" and c["status"] != "WARN":
			continue
		var key := "%s/%s" % [c["screen"], c["type"]]
		var rank: float = float(TYPES[c["type"]][1]) * (1.0 - float(c["score"])) + (100.0 if c["status"] == "FAIL" else 10.0)
		if not merged.has(key):
			merged[key] = {"rank": 0.0, "screen": c["screen"], "type": c["type"], "res": [], "status": c["status"],
				"example": ""}
		var m: Dictionary = merged[key]
		m["rank"] = maxf(float(m["rank"]), rank)
		(m["res"] as Array).append(c["res"])
		if c["status"] == "FAIL":
			m["status"] = "FAIL"
		if String(m["example"]) == "" and not (c["items"] as Array).is_empty():
			var it: Dictionary = (c["items"] as Array)[0]
			m["example"] = "%s: %s" % [it["text"], it["detail"]]
	var list: Array = merged.values()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rank"]) > float(b["rank"]))
	var out: Array[Dictionary] = []
	for m: Dictionary in list:
		if out.size() >= max_items:
			break
		var t: Array = TYPES[m["type"]]
		out.append({"status": m["status"], "title": "%s on %s" % [t[0], m["screen"]],
			"text": "%s. e.g. %s (at %s)" % [t[3], m["example"], ", ".join(PackedStringArray(m["res"]))]})
	var ideas := [
		["Tooltips everywhere in game", "every HUD button gets a tooltip with its key and cost, even when its text is clear"],
		["Headroom for French", "French text runs ~20 % longer: keep 20 % spare width in fixed-size frames"],
		["Ultrawide layout", "at 3440x1440 check that HUD blocks stay anchored to their edges and the centre stays clear"],
	]
	for idea: Array in ideas:
		if out.size() >= min_items:
			break
		out.append({"status": "IDEA", "title": idea[0], "text": idea[1]})
	return out


func exit_code() -> int:
	return 1 if result() == "FAIL" else 0


# ---------------------------------------------------------------- writers

func to_dict() -> Dictionary:
	return {"lab_version": VERSION, "started": started, "seconds": snappedf(seconds, 0.1), "headless": headless,
		"result": result(), "quality": snappedf(quality(), 0.1), "previous_quality": snappedf(previous_score, 0.1),
		"counts": {"PASS": count("PASS"), "WARN": count("WARN"), "FAIL": count("FAIL"), "SKIP": count("SKIP")},
		"resolutions": resolutions, "actual_sizes": actual_sizes, "screens": screens, "checks": checks,
		"improve_next": improve_next(), "shots": shots, "notes": notes}


func _cell(screen: String, res: String, type: String) -> Dictionary:
	for c: Dictionary in checks:
		if c["screen"] == screen and c["res"] == res and c["type"] == type:
			return c
	return {}


func to_markdown() -> String:
	var q := quality()
	var s := "# UI Lab scorecard\n\n%s · lab v%s · %.0f s%s\n\n" % [started, VERSION, seconds,
		" · **headless: no screenshots, contrast from style boxes only**" if headless else ""]
	var delta := ""
	if previous_score >= 0.0:
		delta = " (previous run %.0f, %+d)" % [previous_score, int(round(q - previous_score))]
	s += "## Result: **%s** · quality **%.0f / 100**%s\n\n" % [result(), q, delta]
	s += "%d FAIL · %d WARN · %d PASS · %d skipped\n\n" % [count("FAIL"), count("WARN"), count("PASS"), count("SKIP")]
	if shots.has("contact_sheet"):
		s += "Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](%s)\n\n" \
				% shots["contact_sheet"]
	s += "## Improve next\n"
	var i := 1
	for it: Dictionary in improve_next():
		s += "%d. **%s** (%s): %s\n" % [i, it["title"], it["status"], it["text"]]
		i += 1
	s += "\n## Matrix (status, items found)\n| Screen @ resolution |"
	for t: String in TYPE_ORDER:
		s += " %s |" % TYPES[t][0]
	s += " Shot |\n|---|"
	for t: String in TYPE_ORDER:
		s += "---|"
	s += "---|\n"
	for res: String in resolutions:
		for sc: String in screens:
			var row := "| %s @ %s |" % [sc, res]
			var any := false
			for t: String in TYPE_ORDER:
				var c := _cell(sc, res, t)
				if c.is_empty():
					row += " - |"
					continue
				any = true
				var st: String = c["status"]
				if st == "FAIL" or st == "WARN":
					row += " **%s** %d |" % [st, int(c["count"])]
				else:
					row += " %s |" % st
			var key := "%s@%s" % [sc, res]
			row += " %s |" % ("[jpg](%s)" % shots[key] if shots.has(key) else "-")
			if any:
				s += row + "\n"
	s += "\n## Rules\n| Check | Rule | Fix hint |\n|---|---|---|\n"
	for t: String in TYPE_ORDER:
		s += "| %s | %s | %s |\n" % [TYPES[t][0], TYPES[t][2], TYPES[t][3]]
	s += "\n## Details (FAIL / WARN cells, up to 8 items each)\n"
	for c: Dictionary in checks:
		if c["status"] != "FAIL" and c["status"] != "WARN":
			continue
		s += "\n**%s @ %s · %s: %s (%d)**\n" % [c["screen"], c["res"], TYPES[c["type"]][0], c["status"], int(c["count"])]
		var n := 0
		for it: Dictionary in c["items"]:
			if n >= 8:
				s += "- ... %d more\n" % (int(c["count"]) - 8)
				break
			s += "- %s%s: %s\n" % ["**FAIL** " if bool(it["fail"]) else "", str(it["text"]).replace("|", "/"), it["detail"]]
			n += 1
	var skips := []
	for c: Dictionary in checks:
		if c["status"] == "SKIP":
			skips.append("%s @ %s %s (%s)" % [c["screen"], c["res"], c["type"], c.get("why", "")])
	if not skips.is_empty():
		s += "\n## Skipped\n"
		for k: String in skips:
			s += "- %s\n" % k
	if not actual_sizes.is_empty():
		s += "\n## Window sizes obtained\n"
		for r: String in actual_sizes:
			s += "- %s -> %s\n" % [r, actual_sizes[r]]
	if not notes.is_empty():
		s += "\n## Notes\n"
		for n2: String in notes:
			s += "- %s\n" % n2
	return s


## Writes scorecard.md / scorecard.json into `dir` and appends a row to `log_path`. Reads the previous quality from
## the old scorecard.json first.
func write(dir: String, log_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var json_path := dir.path_join("scorecard.json")
	if FileAccess.file_exists(json_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		if old is Dictionary:
			previous_score = float((old as Dictionary).get("quality", -1.0))
	var f := FileAccess.open(dir.path_join("scorecard.md"), FileAccess.WRITE)
	if f:
		f.store_string(to_markdown())
		f.close()
	f = FileAccess.open(json_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "  "))
		f.close()
	if log_path == "":
		return
	var header := not FileAccess.file_exists(log_path)
	f = FileAccess.open(log_path, FileAccess.READ_WRITE if not header else FileAccess.WRITE)
	if f == null:
		return
	if header:
		f.store_string("# UI Lab improvement log\n\n| When | Result | Quality | FAIL | WARN | PASS | Resolutions | Top item |\n|---|---|---|---|---|---|---|---|\n")
	else:
		f.seek_end()
	var top := improve_next()
	f.store_string("| %s | %s | %.0f | %d | %d | %d | %s | %s |\n" % [started, result(), quality(), count("FAIL"),
		count("WARN"), count("PASS"), ", ".join(PackedStringArray(resolutions)),
		str(top[0]["title"]).replace("|", "/") if not top.is_empty() else ""])
	f.close()
