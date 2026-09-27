extends SceneTree
## Visual Diff Lab: headless checks of the image maths (tools/visual_diff_lab/vdl_diff.gd) and the shot list.
## The render itself needs a window: run tools/visual_diff_lab/run_visual_diff_lab.ps1 for that.
## Run:  godot --headless --path . -s tests/test_visual_diff_lab.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "visual_diff_lab"
const Diff := preload("res://tools/visual_diff_lab/vdl_diff.gd")
const Shots := preload("res://tools/visual_diff_lab/vdl_shots.gd")

var _fails: Array[String] = []


func _initialize() -> void:
	_run()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - %s" % f)
		print("FAIL %s: %d check(s)" % [TASK_ID, _fails.size()])
	quit(0 if _fails.is_empty() else 1)


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fails.append(what)


func _img(w: int, h: int, c: Color) -> Image:
	var i := Image.create(w, h, false, Image.FORMAT_RGBA8)
	i.fill(c)
	return i


func _run() -> void:
	var base := _img(200, 100, Color(0.2, 0.4, 0.6))
	# identical
	var r0 := Diff.diff(base, base.duplicate(), 12)
	_check(bool(r0["ok"]) and int(r0["changed_px"]) == 0, "identical images: 0 changed")
	_check(Diff.verdict(r0)["result"] == "PASS" and int(Diff.verdict(r0)["score"]) == 100, "identical: PASS 100")
	# below tolerance (+10/255 on red)
	var faint := _img(200, 100, Color(0.2 + 10.0 / 255.0, 0.4, 0.6))
	_check(int(Diff.diff(base, faint, 12)["changed_px"]) == 0, "delta 10 under tolerance 12 is not a change")
	_check(int(Diff.diff(base, faint, 5)["changed_px"]) == 200 * 100, "delta 10 over tolerance 5 is a change")
	# a 20x10 block changed -> bbox + pct
	var block := base.duplicate() as Image
	block.fill_rect(Rect2i(50, 30, 20, 10), Color(1, 0, 0))
	var r1 := Diff.diff(base, block, 12)
	_check(int(r1["changed_px"]) == 200, "block: 200 px changed (got %d)" % int(r1["changed_px"]))
	_check(r1["bbox"] == Rect2i(50, 30, 20, 10), "block: bbox %s" % str(r1["bbox"]))
	_check(is_equal_approx(float(r1["changed_pct"]), 1.0), "block: 1 %% changed (got %f)" % float(r1["changed_pct"]))
	_check(Diff.verdict(r1)["result"] == "WARN", "exactly 1 %%: WARN (warn limit %.1f)" % Diff.WARN_PCT)
	var block3 := base.duplicate() as Image
	block3.fill_rect(Rect2i(0, 0, 60, 10), Color(1, 0, 0))   # 3 %
	var v3 := Diff.verdict(Diff.diff(base, block3, 12))
	_check(v3["result"] == "FAIL" and int(v3["score"]) == 40, "3 %%: FAIL score 40 (got %s)" % str(v3))
	_check(Diff.region_name(r1["bbox"], Vector2i(200, 100)) == "middle-left", "region name middle-left (got %s)" % Diff.region_name(r1["bbox"], Vector2i(200, 100)))
	# ignore mask hides the block
	var mask := Diff.rect_mask(Vector2i(200, 100), [Rect2i(45, 25, 30, 20)])
	var r2 := Diff.diff(base, block, 12, mask)
	_check(int(r2["changed_px"]) == 0 and int(r2["ignored_px"]) == 600, "masked block: 0 changed, 600 ignored")
	# small change -> WARN; tiny change -> PASS (noise floor)
	var big := _img(1000, 1000, Color(0.5, 0.5, 0.5))
	var warn := big.duplicate() as Image
	warn.fill_rect(Rect2i(0, 0, 50, 50), Color(0, 0, 0))    # 2500 px = 0.25 %
	_check(Diff.verdict(Diff.diff(big, warn, 12))["result"] == "WARN", "0.25 %: WARN")
	var tiny := big.duplicate() as Image
	tiny.fill_rect(Rect2i(0, 0, 4, 4), Color(0, 0, 0))       # 16 px
	_check(Diff.verdict(Diff.diff(big, tiny, 12))["result"] == "PASS", "16 px: PASS (noise floor)")
	# size mismatch
	var r3 := Diff.diff(base, _img(100, 100, Color.BLACK), 12)
	_check(not bool(r3["ok"]) and Diff.verdict(r3)["result"] == "FAIL", "size mismatch: FAIL")
	# unstable mask + union
	var um: Array = Diff.unstable_mask(base, block, 12, 1)
	_check(int(um[1]) == 200, "unstable: 200 px")
	var mimg: Image = um[0]
	_check(mimg.get_pixel(49, 29).r > 0.5 and mimg.get_pixel(10, 10).r < 0.5, "unstable mask grown by 1 px, rest clear")
	var u := Diff.mask_union(mask, mimg)
	_check(u.get_pixel(46, 26).r > 0.5 and u.get_pixel(69, 39).r > 0.5, "mask union keeps both")
	# heatmap + compare strip sizes, bbox outline magenta
	var heat := Diff.heatmap(block, r1)
	_check(heat.get_size() == Vector2i(200, 100), "heatmap size")
	var hp := heat.get_pixel(60, 35)
	_check(hp.r > 0.9 and hp.b < 0.1, "changed pixel painted hot")
	var strip := Diff.compare_strip(base, block, heat, 0.5)
	_check(strip.get_width() == 100 * 3 + 16 and strip.get_height() == 50 + 8, "compare strip size %s" % str(strip.get_size()))
	# change regions (v1.1): two blocks far apart = 2 regions, biggest first; focus sheet = one row per region
	var two := big.duplicate() as Image
	two.fill_rect(Rect2i(20, 20, 30, 30), Color(0, 0, 0))      # 900 px
	two.fill_rect(Rect2i(700, 800, 10, 10), Color(1, 1, 1))    # 100 px
	var r4 := Diff.diff(big, two, 12)
	var regs := Diff.regions(r4)
	_check(regs.size() == 2 and int(regs[0]["px"]) == 900 and regs[0]["rect"] == Rect2i(20, 20, 30, 30) and int(regs[1]["px"]) == 100,
		"regions: 2 blocks, biggest first (got %s)" % str(regs))
	_check(Diff.regions(r0).is_empty(), "regions: none when nothing changed")
	var focus := Diff.focus_sheet(big, two, Diff.heatmap(two, r4), regs)
	_check(focus != null and focus.get_height() > 2 * 64 and focus.get_width() >= 3 * 96, "focus sheet: 2 rows of 3 zoomed crops (got %s)" % (str(focus.get_size()) if focus else "null"))
	_check(Diff.focus_sheet(big, big, null, []) == null, "focus sheet: null without regions")
	# shot list
	var ids := Shots.ids()
	_check(ids.size() >= 9, "at least 9 shots")
	var seen := {}
	var kinds := {}
	for s: Dictionary in Shots.SHOTS:
		_check(not seen.has(s["id"]), "unique shot id %s" % s["id"])
		seen[s["id"]] = true
		kinds[s["kind"]] = int(kinds.get(s["kind"], 0)) + 1
		_check(["menu", "map", "lineup"].has(s["kind"]), "known kind %s" % s["kind"])
		for r: Variant in s.get("ignore", []):
			_check(r is Rect2i, "%s: ignore entries are Rect2i" % s["id"])
	_check(int(kinds.get("map", 0)) == 4 and int(kinds.get("lineup", 0)) == 4 and int(kinds.get("menu", 0)) == 1,
		"4 map cameras, 4 lineups, 1 menu (got %s)" % str(kinds))
