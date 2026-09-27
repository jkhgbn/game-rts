class_name ArtLabReport
extends RefCounted
## Art Lab (docs/plan/art-lab.md): the scorecard. Collects checks (PASS / WARN / FAIL / INFO / SKIP + measured value +
## rule + fix hint) and writes scorecard.md / scorecard.json, the contact sheet PNG and a line in
## docs/art/lab/improvement-log.md. The numbers (grades, 0-100 quality, "Improve next" ranking) come from lab_score.gd.

const VERSION := "3.1"
## Kept for callers of the pre-v3 API (tools/common/tool_report.gd extends this class): the weights live in lab_score.gd.
const GROUP_WEIGHT := ArtLabScore.GROUP_WEIGHT
const GROUP_TITLE := {"health": "Health (errors, allocations, hooks)", "budget": "Budgets", "read": "Readability at 40 m",
	"anim": "Animation", "polish": "Polish (scored, never fails)", "decor": "Decor set", "vfx": "VFX family",
	"craft": "Craft: shape and detail at the close-up / 25 m (scored, never fails)"}
const GROUP_ORDER: Array[String] = ["health", "budget", "read", "anim", "decor", "vfx", "craft", "polish"]

var asset: String = ""
var scene: String = ""
var kind: String = ""
var tier: String = ""
var kingdom: String = ""
var ground: String = ""
var headless: bool = false
var checks: Array[Dictionary] = []
var shots: Dictionary = {}          # name -> file name in the out folder
var notes: Array[String] = []
var extras: Array[Dictionary] = []  # fallback improvement ideas {title, text, source}
var budget_row: Dictionary = {}
var previous_score: float = -1.0
var started: String = ""
var seconds: float = 0.0
## v3 before / after (lab_diff.gd `ArtLabDiff.finish`): {prev_quality, quality, worse, better, rows, new, gone,
## unchanged, shots, sheet...} vs the previous run; {} = nothing compared.
var compare: Dictionary = {}
## v3 `focus=`: the re-measured check ids (the other checks are kept from the previous run, flag `kept`).
var focus: Array[String] = []
var focus_note: String = ""


## Adds a check. `score` (0-1, -1 = from the status) grades how far inside / outside the rule it is, so the quality
## score moves when an agent improves something that already passes. `improve` = a concrete next step (shown in
## "Improve next" when the check has headroom).
func add(id: String, group: String, check_name: String, status: String, value: String, rule: String, hint: String = "",
		score: float = -1.0, improve: String = "", shot: String = "", weight: float = 1.0) -> Dictionary:
	var c := {"id": id, "group": group, "name": check_name, "status": status, "value": value, "rule": rule,
		"hint": hint, "graded": score, "improve": improve, "shot": shot, "weight": weight}
	c["score"] = ArtLabScore.score_of(status, score)
	checks.append(c)
	return c


func count(status: String) -> int:
	var n := 0
	for c: Dictionary in checks:
		if c["status"] == status:
			n += 1
	return n


func result() -> String:
	if count("FAIL") > 0:
		return "FAIL"
	if count("WARN") > 0:
		return "WARN"
	return "PASS"


func quality() -> float:
	return ArtLabScore.quality(checks)


## The "Improve next" list (ArtLabScore.improve_next): FAIL / WARN first, then headroom, topped up with `extras`.
func improve_next(min_items: int = 3, max_items: int = 6) -> Array[Dictionary]:
	return ArtLabScore.improve_next(checks, extras, min_items, max_items)

func exit_code() -> int:
	return 1 if result() == "FAIL" else 0


# ---------------------------------------------------------------- writers

func to_dict() -> Dictionary:
	var imp := improve_next()
	var d := {
		"lab_version": VERSION, "asset": asset, "scene": scene, "kind": kind, "tier": tier, "kingdom": kingdom,
		"ground": ground, "headless": headless, "started": started, "seconds": snappedf(seconds, 0.1),
		"result": result(), "quality": snappedf(quality(), 0.1), "previous_quality": snappedf(previous_score, 0.1),
		"counts": {"PASS": count("PASS"), "WARN": count("WARN"), "FAIL": count("FAIL"), "INFO": count("INFO"),
			"SKIP": count("SKIP")},
		"checks": checks, "improve_next": imp, "shots": shots, "budget": budget_row, "notes": notes,
	}
	if not compare.is_empty():
		d["compare"] = compare
	if not focus.is_empty():
		d["focus"] = focus
		d["focus_note"] = focus_note
	return d


## v3 "Before / after" section (top of scorecard.md): what got worse first, then what got better, the per-check score
## delta table and the changed share of each shot. "" when nothing was compared.
func compare_markdown() -> String:
	if compare.is_empty():
		return ""
	var q0 := float(compare.get("prev_quality", -1.0))
	var q1 := quality()
	var s := "## Before / after (vs the run of %s in `%s`: quality %d -> %d, %s)\n" % [compare.get("prev_started", "?"),
		compare.get("against", ""), ArtLabScore.shown(q0), ArtLabScore.shown(q1), ArtLabScore.delta_text(q0, q1)]
	var worse: Array = compare.get("worse", [])
	s += "### What got worse (%d)\n" % worse.size()
	if worse.is_empty():
		s += "Nothing got worse.\n"
	var i := 1
	for r: Dictionary in worse:
		s += "%d. **%s**. Now: %s. Was: %s\n" % [i, ArtLabDiff.row_text(r), _cell(String(r["new_value"]).left(180)),
			_cell(String(r["old_value"]).left(120))]
		i += 1
	var better: Array = compare.get("better", [])
	if not better.is_empty():
		var bl: Array[String] = []
		for r2: Dictionary in better:
			bl.append(ArtLabDiff.row_text(r2))
		s += "\n### What got better (%d)\n%s\n" % [better.size(), "; ".join(bl)]
	var extra: Array[String] = []
	for r3: Dictionary in compare.get("new", []):
		extra.append("new %s %s (%s)" % [r3["id"], r3["name"], r3["new_status"]])
	for r4: Dictionary in compare.get("gone", []):
		extra.append("gone %s %s (was %s)" % [r4["id"], r4["name"], r4["old_status"]])
	if not extra.is_empty():
		s += "\n" + "; ".join(extra) + "\n"
	var rows: Array[Dictionary] = []
	for r5: Dictionary in compare.get("rows", []):
		if String(r5["change"]) != "same" or absf(float(r5["delta"])) >= 0.5:
			rows.append(r5)
	if not rows.is_empty():
		s += "\n### Score delta per check (%d changed, %d unchanged)\n| # | Check | Before | After | Delta |\n|---|---|---|---|---|\n" % [
			rows.size(), int(compare.get("unchanged", 0))]
		for r6: Dictionary in rows:
			s += "| %s | %s | %s %s | %s %s | %+.1f%s |\n" % [r6["id"], _cell(r6["name"]), r6["old_status"],
				("%.0f" % float(r6["old_score"])) if float(r6["old_score"]) >= 0.0 else "", r6["new_status"],
				("%.0f" % float(r6["new_score"])) if float(r6["new_score"]) >= 0.0 else "", float(r6["delta"]),
				" (noisy)" if bool(r6.get("noisy", false)) else ""]
	var sh: Array = compare.get("shots", [])
	if not sh.is_empty():
		var sl: Array[String] = []
		for r7: Dictionary in sh:
			sl.append("%s %.1f %%" % [r7["shot"], 100.0 * float(r7["changed"])])
		s += "\nChanged pixels per shot: %s%s\n" % [", ".join(sl),
			(" · [diff sheet](%s) (before / after / changed mask)" % compare["sheet"]) if compare.has("sheet") else ""]
	return s + "\n"


func to_markdown() -> String:
	var q := quality()
	var s := "# Art Lab scorecard: %s\n\n" % asset
	s += "Scene `%s` · kind **%s** / tier **%s** · kingdom %s · ground %s · %s · lab v%s%s\n\n" % [scene, kind, tier,
		kingdom, ground, started, VERSION, " · **headless: render checks skipped**" if headless else ""]
	var delta := ""
	if previous_score >= 0.0:
		delta = " (previous run %d, %s)" % [ArtLabScore.shown(previous_score), ArtLabScore.delta_text(previous_score, q)]
	s += "## Result: **%s** · quality **%d / 100** (%.1f)%s\n\n" % [result(), ArtLabScore.shown(q), snappedf(q, 0.1), delta]
	s += "%d FAIL · %d WARN · %d PASS · %d info · %d skipped · %.0f s\n\n" % [count("FAIL"), count("WARN"), count("PASS"),
		count("INFO"), count("SKIP"), seconds]
	if focus_note != "":
		s += "**Focus run**: %s (rows marked _kept_ were not re-measured).\n\n" % focus_note
	s += compare_markdown()
	s += "## Improve next\n"
	var i := 1
	for it: Dictionary in improve_next():
		s += "%d. **%s** (%s): %s _(from %s)_\n" % [i, it["title"], it["status"], it["text"], it["source"]]
		i += 1
	s += "\n"
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
			if float(c["score"]) >= 0.0 and c["status"] != "SKIP":
				st += " %.0f" % (100.0 * float(c["score"]))
			if bool(c.get("kept", false)):
				st += " _kept_"
			var hint: String = c["hint"] if c["status"] == "FAIL" or c["status"] == "WARN" else ""
			s += "| %s | %s | %s | %s | %s | %s |\n" % [c["id"], c["name"], st, _cell(c["value"]), _cell(c["rule"]),
				_cell(hint)]
		s += "\n"
	if not shots.is_empty():
		s += "## Shots\n"
		for k: String in shots:
			s += "- %s: [%s](%s)\n" % [k, shots[k], shots[k]]
		s += "\n"
	if not budget_row.is_empty():
		s += "## Budget used (`tools/art_lab/lab_budgets.gd`, %s)\n`%s`\n\n" % [budget_row.get("src", ""), JSON.stringify(budget_row)]
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


## Appends one row to the improvement log (created with its header the first time).
func append_log(log_path: String, out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(log_path.get_base_dir()))
	var exists := FileAccess.file_exists(log_path)
	var f := FileAccess.open(log_path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if f == null:
		return
	if not exists:
		f.store_string("# Art Lab improvement log\n\nOne row per lab run (`tools/art_lab/art_lab.gd`, docs/plan/art-lab.md). " +
			"Quality 0-100 (higher is better); the delta is against the previous run in the same out folder.\n\n" +
			"| When | Asset | Kind / tier | Quality | Result | Top suggestions | Scorecard |\n|---|---|---|---|---|---|---|\n")
	else:
		f.seek_end()
	var q := quality()
	var d := ""
	if previous_score >= 0.0:
		d = " (%s)" % ArtLabScore.delta_text(previous_score, q)
	var tops: Array[String] = []
	for it: Dictionary in improve_next():
		if tops.size() >= 3:
			break
		tops.append(String(it["title"]))
	f.store_string("| %s | %s | %s / %s | %d%s | %s (%dF %dW) | %s | %s |\n" % [started, asset, kind, tier, ArtLabScore.shown(q), d,
		result(), count("FAIL"), count("WARN"), "; ".join(tops), out_dir.path_join("scorecard.md").replace("res://", "")])
	f.close()


## Reads the quality of the previous run in `out_dir` (-1 when none).
static func read_previous(out_dir: String) -> float:
	var p := out_dir.path_join("scorecard.json")
	if not FileAccess.file_exists(p):
		return -1.0
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d is Dictionary and (d as Dictionary).has("quality"):
		return float((d as Dictionary)["quality"])
	return -1.0


## The contact sheet: a header (asset, result, quality, the FAIL / WARN lines, the top improvement) over a grid of
## labelled tiles. Rendered by a 2D SubViewport under `parent` (windowed only). tiles = [{img: Image, label: String}].
func contact_sheet(parent: Node, tiles: Array[Dictionary], cols: int = 4) -> Image:
	var tw := 400
	var th := 225
	var lab_h := 22
	var header := 190
	var rows := (tiles.size() + cols - 1) / cols
	var size := Vector2i(tw * cols, header + rows * (th + lab_h))
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.1)
	bg.size = Vector2(size)
	vp.add_child(bg)
	var res := result()
	var col := Color(0.4, 0.9, 0.45) if res == "PASS" else (Color(1.0, 0.8, 0.3) if res == "WARN" else Color(1.0, 0.35, 0.3))
	_label(vp, "ART LAB  %s  (%s / %s, %s)" % [asset, kind, tier, kingdom], Vector2(12, 8), 26, Color(0.95, 0.95, 0.95))
	var q := quality()
	var qd := ""
	if previous_score >= 0.0:
		qd = "  (prev %d, %s)" % [ArtLabScore.shown(previous_score), ArtLabScore.delta_text(previous_score, q)]
	_label(vp, "%s   quality %d / 100%s   %d FAIL  %d WARN  %d PASS" % [res, ArtLabScore.shown(q), qd, count("FAIL"), count("WARN"),
		count("PASS")], Vector2(12, 42), 22, col)
	var lines: Array[String] = []
	if not compare.is_empty() and not (compare.get("worse", []) as Array).is_empty():
		var wl: Array[String] = []
		for r: Dictionary in compare["worse"]:
			wl.append("%s %s" % [r["id"], ArtLabDiff.signed(float(r["delta"]))])
		lines.append("WORSE than the previous run: " + ", ".join(wl))
	for c: Dictionary in checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			lines.append("%s %s %s: %s" % [c["status"], c["id"], c["name"], str(c["value"])])
	var imp := improve_next()
	var y := 76.0
	for l: String in lines.slice(0, 5):
		_label(vp, l.left(150), Vector2(12, y), 15, Color(1.0, 0.55, 0.45) if l.begins_with("FAIL") or l.begins_with("WORSE") else Color(1.0, 0.85, 0.5))
		y += 19.0
	if lines.size() > 5:
		_label(vp, "... +%d more (scorecard.md)" % (lines.size() - 5), Vector2(12, y), 15, Color(0.8, 0.8, 0.8))
		y += 19.0
	if not imp.is_empty() and y < header - 20:
		_label(vp, ("Improve next: " + String(imp[0]["title"]) + ": " + String(imp[0]["text"])).left(190), Vector2(12, y),
			15, Color(0.6, 0.85, 1.0))
	for i: int in tiles.size():
		var t: Dictionary = tiles[i]
		var x := float((i % cols) * tw)
		var ty := float(header + (i / cols) * (th + lab_h))
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(ArtLabImage.fit(t["img"], tw - 4, th - 4))
		tr.position = Vector2(x + 2, ty + 2)
		tr.size = Vector2(tw - 4, th - 4)
		vp.add_child(tr)
		_label(vp, String(t["label"]).left(58), Vector2(x + 6, ty + th), 15, Color(0.85, 0.85, 0.85))
	for k: int in 3:
		await parent.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func _label(p: Node, text: String, pos: Vector2, font_size: int, c: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", c)
	p.add_child(l)
