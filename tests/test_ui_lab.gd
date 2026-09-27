extends SceneTree
## UI Lab self-test (docs/plan/ui-lab.md): every check finds a planted problem and passes a clean layout; the
## scorecard grades, lists "Improve next" and writes its files. Headless, no game scene needed.
## Run:  godot --headless --path . -s tests/test_ui_lab.gd --fixed-fps 60 --quit-after 600
## Prints "PASS ui_lab" or "FAIL ui_lab: <reasons>".

const TASK_ID := "ui_lab"
const SCREEN := Rect2(0, 0, 1600, 900)

var _fails: Array[String] = []
var bad: Control
var good: Control


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fails.append(what)


func _dark_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.09, 1.0)
	sb.set_content_margin_all(8)
	return sb


func _run() -> void:
	root.size = Vector2i(1600, 900)
	# ---- the bad screen: one planted problem per check
	bad = Control.new()
	bad.size = SCREEN.size
	root.add_child(bad)
	var frame := Panel.new()                       # fixed 120 x 40 frame, label placed by hand: overflow
	frame.position = Vector2(20, 20)
	frame.size = Vector2(120, 40)
	bad.add_child(frame)
	var long := Label.new()
	long.text = "This line is much too long for its little frame"
	long.position = Vector2(4, 4)
	frame.add_child(long)
	var cut := Label.new()                         # clipped text: cut
	cut.text = "Clipped words that do not fit"
	cut.clip_text = true
	cut.custom_minimum_size = Vector2(60, 0)
	cut.position = Vector2(20, 100)
	cut.size = Vector2(60, 23)
	bad.add_child(cut)
	var off := Label.new()                         # past the right edge: off-screen
	off.text = "Off the edge"
	off.position = Vector2(1560, 200)
	bad.add_child(off)
	var o1 := Label.new()                          # two labels on the same spot: overlap
	o1.text = "Crystals 500"
	o1.position = Vector2(400, 300)
	bad.add_child(o1)
	var o2 := Label.new()
	o2.text = "Population 12"
	o2.position = Vector2(404, 302)
	bad.add_child(o2)
	var tiny := Label.new()                        # 8 px: font FAIL
	tiny.text = "tiny"
	tiny.add_theme_font_size_override("font_size", 8)
	tiny.position = Vector2(600, 500)
	bad.add_child(tiny)
	var dark := PanelContainer.new()               # grey text on a dark opaque panel: contrast
	dark.add_theme_stylebox_override("panel", _dark_panel_style())
	dark.position = Vector2(800, 500)
	bad.add_child(dark)
	var dim := Label.new()
	dim.text = "Hard to read"
	dim.add_theme_color_override("font_color", Color(0.22, 0.2, 0.22))
	dark.add_child(dim)
	var abbr := Button.new()                       # abbreviation without tooltip
	abbr.text = "Hr"
	abbr.position = Vector2(1000, 600)
	bad.add_child(abbr)
	var badges: Array = []
	for k: String in ["Z", "X", "Z"]:
		var b := Label.new()
		b.text = k
		b.position = Vector2(1200 + 40 * badges.size(), 700)
		bad.add_child(b)
		badges.append(b)

	# ---- the good screen: a panel with a label and a button with a tooltip, all on screen
	good = Control.new()
	good.size = SCREEN.size
	root.add_child(good)
	var gp := PanelContainer.new()
	gp.add_theme_stylebox_override("panel", _dark_panel_style())
	gp.position = Vector2(100, 100)
	good.add_child(gp)
	var box := VBoxContainer.new()
	gp.add_child(box)
	var gl := Label.new()
	gl.text = "Readable title"
	gl.add_theme_font_size_override("font_size", 18)
	gl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	box.add_child(gl)
	var gb := Button.new()
	gb.text = "Start"
	gb.tooltip_text = "Start the match"
	box.add_child(gb)
	for i in 4:
		await process_frame
	bad.visible = true

	var ctl_bad := UILabChecks.visible_controls(bad)
	# Only the bad scope: hide nothing, but checks get the bad list; badges are checked on their own.
	var overflow := UILabChecks.find_overflow(ctl_bad)
	_check(_has(overflow, long, "frame"), "overflow: the long label in the 120 px frame was not found")
	_check(_has(overflow, cut, "cut"), "overflow: the clipped label was not found")
	var offs := UILabChecks.find_offscreen(ctl_bad, SCREEN)
	_check(_has(offs, off), "offscreen: the label past the right edge was not found")
	_check(not _has(offs, o1), "offscreen: an on-screen label was reported")
	var ol := UILabChecks.find_overlaps(ctl_bad)
	var found_pair := false
	for it: Dictionary in ol:
		if (it["node"] == o1 and it["other"] == o2) or (it["node"] == o2 and it["other"] == o1):
			found_pair = true
	_check(found_pair, "overlap: the two stacked labels were not found (%d items)" % ol.size())
	var small := UILabChecks.find_small_fonts(ctl_bad)
	_check(_has(small, tiny) and bool(_item(small, tiny).get("fail", false)), "font: the 8 px label is not a FAIL")
	var con := UILabChecks.find_low_contrast(ctl_bad, null)
	_check(_has(con, dim), "contrast: dark grey on dark panel was not found")
	var tips := UILabChecks.find_missing_tooltips(ctl_bad)
	_check(_has(tips, abbr) and bool(_item(tips, abbr)["short"]), "tooltip: the 'Hr' button was not flagged short")
	var dups := UILabChecks.find_duplicate_badges(badges)
	_check(dups.size() == 1 and String(dups[0]["value"]) == "Z", "hotkeys: expected one duplicate Z badge, got %d" % dups.size())
	var help := "Left click: select    G: gather    C: stop\nG: trade (caravans)    Flag: Z raise · Delete remove\n" \
			+ "Z X C V B: train    B: build\nB, B: Bazaar    Bazaar: Z caravan"
	var hd := UILabChecks.find_duplicate_help_keys(help)
	_check(hd.size() == 1 and String(hd[0]["value"]) == "G", "help: expected only G duplicated, got %s" % str(hd.map(func(d: Dictionary) -> String: return str(d["value"]))))
	# Real help text parses into entries (no crash, some keys).
	_check(UILabChecks.parse_help(GameHUD.help_text("Vessa")).size() >= 15, "help: GameHUD.help_text parsed into too few entries")
	# Contrast maths: black on white = 21.
	_check(absf(UILabChecks.contrast_ratio(Color.BLACK, Color.WHITE) - 21.0) < 0.01, "contrast_ratio(black, white) != 21")
	# Pixel background sampling: a flat image returns its colour.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.4, 0.6))
	var bg := UILabChecks.sample_background(img, Rect2(10, 10, 20, 10))
	_check(bg.is_equal_approx(Color(0.2, 0.4, 0.6)) or bg.to_html() == Color(0.2, 0.4, 0.6).to_html(), "sample_background on a flat image")

	# ---- the good screen passes every check
	var ctl_good := UILabChecks.visible_controls(good)
	_check(UILabChecks.find_overflow(ctl_good).is_empty(), "good: overflow reported")
	_check(UILabChecks.find_offscreen(ctl_good, SCREEN).is_empty(), "good: offscreen reported")
	_check(UILabChecks.find_overlaps(ctl_good).is_empty(), "good: overlap reported %s" % str(UILabChecks.find_overlaps(ctl_good).map(func(d: Dictionary) -> String: return d["text"])))
	_check(UILabChecks.find_small_fonts(ctl_good).is_empty(), "good: small font reported")
	_check(UILabChecks.find_low_contrast(ctl_good, null).is_empty(), "good: low contrast reported %s" % str(UILabChecks.find_low_contrast(ctl_good, null).map(func(d: Dictionary) -> String: return d["detail"])))
	_check(UILabChecks.find_missing_tooltips(ctl_good).is_empty(), "good: missing tooltip reported")
	# Hidden branches are skipped.
	bad.visible = false
	_check(UILabChecks.visible_controls(bad).is_empty(), "hidden scope still returned controls")

	# ---- the scorecard
	var rep := UILabReport.new()
	rep.started = "test"
	rep.resolutions.append("1600x900")
	rep.screens.append("bad")
	rep.screens.append("good")
	rep.add_items("bad", "1600x900", "overflow", overflow, true)
	rep.add_items("bad", "1600x900", "font", small)
	rep.add_items("good", "1600x900", "overflow", [] as Array[Dictionary])
	rep.add_skip("good", "1600x900", "contrast", "test")
	_check(rep.result() == "FAIL", "report: result should be FAIL")
	var q := rep.quality()
	_check(q > 0.0 and q < 100.0, "report: quality %.1f not in (0, 100)" % q)
	_check(rep.improve_next().size() >= 3, "report: Improve next has < 3 items")
	var md := rep.to_markdown()
	_check(md.contains("## Matrix") and md.contains("Improve next") and md.contains("bad @ 1600x900"), "report: markdown misses sections")
	var dir := "user://ui_lab_selftest"
	rep.write(dir, dir.path_join("log.md"))
	_check(FileAccess.file_exists(dir.path_join("scorecard.json")) and FileAccess.file_exists(dir.path_join("log.md")),
			"report: files not written")
	rep.write(dir, dir.path_join("log.md"))
	_check(rep.previous_score >= 0.0, "report: previous score not read back")
	for f in ["scorecard.md", "scorecard.json", "log.md"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))

	bad.free()
	good.free()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(PackedStringArray(_fails))])
	quit(0 if _fails.is_empty() else 1)


func _item(items: Array[Dictionary], n: Node) -> Dictionary:
	for it: Dictionary in items:
		if it["node"] == n:
			return it
	return {}


func _has(items: Array[Dictionary], n: Node, kind := "") -> bool:
	var it := _item(items, n)
	return not it.is_empty() and (kind == "" or String(it.get("kind", "")) == kind)
