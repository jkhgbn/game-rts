class_name ArtLabDiff
extends RefCounted
## Art Lab v3 (docs/plan/art-lab-v3-plan.md task 1.B): before / after of two runs and the `focus=` inner loop.
##
## `compare=prev` (default when the out folder already holds a scorecard; `compare=off` disables it, `compare=<dir>`
## compares with another out folder): the previous scorecard.json and its shots are read BEFORE the run overwrites them
## (`load_previous`), then `compare` adds to the report a per-check score delta, a "What got worse" list (top of
## scorecard.md) and writes `diff_sheet.png` (old / new / changed-pixel mask per shot).
## `focus=<check ids or aliases>` (comma list, e.g. `focus=R3` or `focus=contrast,glow`): the runner only runs the
## passes those checks need (`needs`, `ArtLabRunner.wants`), then `merge_focus` puts the re-measured checks into the
## previous scorecard (the other checks are kept, flagged `kept`).
## Pure functions (focus sets, check deltas, merge, pixel diff) are static and tested headless in tests/test_art_lab.gd.

## Check ids per run pass (docs/plan/art-lab.md section 1 module map). An id that is in none of them makes a focus run
## run every pass (a new check is never silently skipped; the merge still only takes the focused ids).
const PHASE_IDS := {
	"budgets": ["B1", "B1a", "B2", "B3", "B4", "B4t", "B5", "B6", "B6l", "B6p", "B7", "B8", "B11", "B12"],
	"instances": ["B9", "B9m"],
	"hooks": ["A1"],
	"actions": ["B10"],
	"geometry": ["R8", "R8w", "R9", "R10"],
	"read40": ["R1", "R3", "R3t", "R4", "R4k", "R5", "R6", "R7", "A3", "P1", "P3", "P4", "P5", "R5c", "R5w", "R6cb", "R11", "R12", "S1"],
	"anim": ["A2"],
	"refs": ["R2", "R2r", "P2"],
	"frame": ["B13"],
	"always": ["H0", "H1", "H2"],
}
## Passes that need the render shots (the 40 / 55 / 25 m + close-up frames also set the model box).
const RENDER_PHASES: Array[String] = ["read40", "anim", "refs", "frame"]
const ALIASES := {
	"contrast": ["R3", "R3t", "R4", "R4k"],
	"grounds": ["R4", "R4k"],
	"glow": ["R5", "R5c", "P5"],
	"team": ["R6", "R3t", "R6cb"],
	"walk": ["R11", "R5w"],
	"presets": ["R12"],
	"style": ["S1"],
	"silhouette": ["R1", "R2", "P1", "P2"],
	"refs": ["R2", "R2r", "P2"],
	"geometry": ["R8", "R8w", "R9", "R10"],
	"anim": ["A1", "A2", "A3"],
	"polish": ["P1", "P2", "P3", "P4", "P5"],
	"health": ["H1", "H2", "B9", "B9m", "B10"],
	"budgets": ["B1", "B1a", "B2", "B3", "B4", "B4t", "B5", "B6", "B6l", "B6p", "B7", "B8", "B11", "B12", "B9", "B9m",
		"B10", "B13"],
}
## Checks whose score moves between two runs of the unchanged asset (timing, idle / walk phase), with the points (0-100)
## they jitter by (measured on repeated Mirefang / Shade runs 2026-09-27): a score change inside the band is "same"; a
## status drop still counts but is flagged "noisy".
const NOISE_PTS := {"B13": 30.0, "A2": 10.0, "A3": 8.0, "P4": 8.0, "R5w": 20.0, "R11": 5.0, "R5": 5.0, "R5c": 5.0}
## A score change of at least this many points (0-100) counts as better / worse (the render checks jitter ~1 point).
const MIN_DELTA := 2.0
const STATUS_RANK := {"FAIL": 0, "WARN": 1, "PASS": 2, "INFO": 2}
## Shots cropped around the model before the diff (full 1600 x 900 frames: the model stands at the frame centre).
const CROP := {"z40": Vector2i(256, 144), "z55": Vector2i(224, 126), "z25": Vector2i(384, 216)}
const TILE := Vector2i(400, 225)
const SKIP_SHOTS: Array[String] = ["contact_sheet", "contact_focus", "diff_sheet"]
## Per-pixel change: sum of |dR| + |dG| + |dB| (0-765) above this counts as changed (JPEG noise stays under ~25).
const PIXEL_THR := 45


# ================================================================ focus

## The focus set {id: true} from a `focus=` value: comma / space separated check ids (case-insensitive: `r3t` = R3t)
## or aliases (`contrast`, `grounds`, `glow`, `team`, `walk`, `presets`, `style`, `silhouette`, `refs`, `geometry`,
## `anim`, `polish`, `health`, `budgets`).
static func focus_set(spec: String) -> Dictionary:
	var out := {}
	for raw: String in spec.replace(" ", ",").replace(";", ",").split(",", false):
		var w := raw.strip_edges()
		if w == "":
			continue
		if ALIASES.has(w.to_lower()):
			for a: String in ALIASES[w.to_lower()]:
				out[a] = true
		else:
			out[norm_id(w)] = true
	return out


## `r3T` -> `R3t`, `b4t` -> `B4t`, `h1` -> `H1` (letters before the number upper case, after it lower case).
static func norm_id(w: String) -> String:
	var s := ""
	var digits := false
	for ch: String in w.strip_edges():
		if ch >= "0" and ch <= "9":
			digits = true
			s += ch
		else:
			s += ch.to_lower() if digits else ch.to_upper()
	return s


## True when a focus run must run `phase` (a PHASE_IDS key, or "shots" / "turns"). Empty focus = everything.
static func needs(focus: Dictionary, phase: String) -> bool:
	if focus.is_empty() or has_unknown(focus):
		return true
	if phase == "turns":
		return false   # the turns sheet feeds no check
	if phase == "shots":
		for p: String in RENDER_PHASES:
			if needs(focus, p):
				return true
		return false
	for id: String in PHASE_IDS.get(phase, []):
		if focus.has(id):
			return true
	return false


## True when the focus names an id no pass is known to produce (then every pass runs).
static func has_unknown(focus: Dictionary) -> bool:
	for id: String in focus:
		var known := false
		for p: String in PHASE_IDS:
			if id in PHASE_IDS[p]:
				known = true
				break
		if not known:
			return true
	return false


## The checks of a focus run merged into the previous run's checks: a focused id takes the new check(s) at the old
## place; every other check is kept from the previous run (flag `kept`). H0 is always the new one; H1 / H2 (errors)
## take the new one when focused or when it is worse (an error seen in the short run is never hidden).
static func merge_focus(prev_checks: Array, new_checks: Array[Dictionary], focus: Dictionary) -> Array[Dictionary]:
	var prev_status := {}
	for pc: Dictionary in prev_checks:
		prev_status[String(pc["id"])] = String(pc["status"])
	var take := {}   # id -> [new checks]
	var order: Array[String] = []
	for c: Dictionary in new_checks:
		var id := String(c["id"])
		var use := focus.has(id) or id == "H0"
		if id in ["H1", "H2"] and not use and prev_status.has(id):
			use = _rank(String(c["status"])) < _rank(String(prev_status[id]))
		if not use:
			continue
		if not take.has(id):
			take[id] = []
			order.append(id)
		(take[id] as Array).append(c)
	var out: Array[Dictionary] = []
	var used := {}
	for pc2: Dictionary in prev_checks:
		var pid := String(pc2["id"])
		if take.has(pid):
			if not used.has(pid):
				used[pid] = true
				for nc: Dictionary in take[pid]:
					out.append(nc)
			continue
		var k := pc2.duplicate()
		k["kept"] = true
		out.append(k)
	for id2: String in order:
		if not used.has(id2):
			for nc2: Dictionary in take[id2]:
				out.append(nc2)
	return out


# ================================================================ previous run

## Reads the run to compare with / merge into, BEFORE this run writes its files: {"dir", "json" (the previous
## scorecard.json or {}), "images" {shot: prepared Image}}. `compare=off` (or 0 / none) = no images (a focus run still
## merges into the previous scorecard). `compare=<dir>` reads another out folder. {} when there is nothing to read.
static func load_previous(out_dir: String, opts: Dictionary) -> Dictionary:
	var mode := String(opts.get("compare", "prev")).strip_edges()
	var off := mode.to_lower() in ["off", "0", "none", "no", "false"]
	var res := {}
	var own := read_json(out_dir.path_join("scorecard.json"))
	if not own.is_empty():
		res["json"] = own   # what a focus run merges into (always this out folder)
	if off:
		return res
	var dir := out_dir
	if mode.to_lower() != "prev" and mode != "1" and mode != "":
		dir = mode if mode.begins_with("res://") or mode.begins_with("user://") or mode.is_absolute_path() else "res://" + mode
		dir = dir.trim_suffix("/")
	var cj := own if dir == out_dir else read_json(dir.path_join("scorecard.json"))
	if cj.is_empty():
		if dir != out_dir:
			print("ART LAB WARNING: compare=%s has no scorecard.json" % mode)
		return res
	res["dir"] = dir
	res["cmp_json"] = cj
	res["compare"] = true
	var imgs := {}
	var shots: Dictionary = cj.get("shots", {})
	for shot: String in shots:
		if shot in SKIP_SHOTS:
			continue
		var img := _load(dir.path_join(String(shots[shot])))
		if img != null:
			imgs[shot] = prepare(img, shot)
	res["images"] = imgs
	return res


## A scorecard.json as a Dictionary ({} when missing / unreadable).
static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func _load(path: String) -> Image:
	var g := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(g) and not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(g) != OK:
		return null
	return img


# ================================================================ compare

## Per-check deltas between two check lists (score = the 0-1 check score, shown x100). Keys: id + occurrence (a check
## id that appears twice is matched in order). Returns {"rows": every matched check, "worse", "better", "new", "gone",
## "unchanged": count}. Worse = the status dropped (PASS -> WARN -> FAIL) or the score fell >= MIN_DELTA points.
static func compare_checks(old: Array, new: Array) -> Dictionary:
	var old_by := _keyed(old)
	var new_by := _keyed(new)
	var rows: Array[Dictionary] = []
	var worse: Array[Dictionary] = []
	var better: Array[Dictionary] = []
	var added: Array[Dictionary] = []
	var gone: Array[Dictionary] = []
	var same := 0
	for k: String in new_by:
		var n: Dictionary = new_by[k]
		if not old_by.has(k):
			added.append(_row(null, n))
			continue
		var o: Dictionary = old_by[k]
		var r := _row(o, n)
		rows.append(r)
		match String(r["change"]):
			"worse":
				worse.append(r)
			"better":
				better.append(r)
			_:
				same += 1
	for k2: String in old_by:
		if not new_by.has(k2):
			gone.append(_row(old_by[k2], null))
	worse.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["loss"]) > float(b["loss"]))
	better.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["loss"]) < float(b["loss"]))
	return {"rows": rows, "worse": worse, "better": better, "new": added, "gone": gone, "unchanged": same}


static func _keyed(list: Array) -> Dictionary:
	var out := {}
	var seen := {}
	for c: Dictionary in list:
		var id := String(c.get("id", "?"))
		var n := int(seen.get(id, 0))
		seen[id] = n + 1
		out[id if n == 0 else "%s#%d" % [id, n + 1]] = c
	return out


static func _rank(status: String) -> int:
	return int(STATUS_RANK.get(status, -1))


static func _pts(c: Variant) -> float:
	if c == null:
		return -1.0
	var s := float((c as Dictionary).get("score", -1.0))
	return 100.0 * s if s >= 0.0 else -1.0


static func _row(o: Variant, n: Variant) -> Dictionary:
	var ref: Dictionary = n if n != null else o
	var r := {"id": String(ref.get("id", "?")), "name": String(ref.get("name", "")), "group": String(ref.get("group", "")),
		"old_status": String((o as Dictionary).get("status", "")) if o != null else "",
		"new_status": String((n as Dictionary).get("status", "")) if n != null else "",
		"old_score": _pts(o), "new_score": _pts(n),
		"old_value": String((o as Dictionary).get("value", "")) if o != null else "",
		"new_value": String((n as Dictionary).get("value", "")) if n != null else "",
		"delta": 0.0, "loss": 0.0, "change": "same", "noisy": NOISE_PTS.has(String(ref.get("id", "")))}
	if o == null or n == null:
		r["change"] = "new" if o == null else "gone"
		return r
	var os := String(r["old_status"])
	var ns := String(r["new_status"])
	if os == "SKIP" or ns == "SKIP":
		r["change"] = "skipped" if os != ns else "same"
		return r
	var d := 0.0
	if float(r["old_score"]) >= 0.0 and float(r["new_score"]) >= 0.0:
		d = float(r["new_score"]) - float(r["old_score"])
	r["delta"] = d
	var w := float(ref.get("weight", 1.0)) * float(ArtLabScore.GROUP_WEIGHT.get(r["group"], 1.0))
	var step := _rank(ns) - _rank(os)
	# rank: a status drop first (x100), then the weighted score change
	r["loss"] = -float(step) * 100.0 - d * w
	var band := maxf(MIN_DELTA, float(NOISE_PTS.get(String(r["id"]), 0.0)))
	if step < 0 or (step == 0 and d <= -band):
		r["change"] = "worse"
	elif step > 0 or d >= band:
		r["change"] = "better"
	return r


## One line per check change: `R3 Contrast vs ground (meadow): PASS 88 -> WARN 60 (-28)`.
static func row_text(r: Dictionary) -> String:
	var a := String(r["old_status"]) + ((" %.0f" % float(r["old_score"])) if float(r["old_score"]) >= 0.0 else "")
	var b := String(r["new_status"]) + ((" %.0f" % float(r["new_score"])) if float(r["new_score"]) >= 0.0 else "")
	return "%s %s: %s -> %s (%s)%s" % [r["id"], r["name"], a, b, signed(float(r["delta"])),
		" (noisy check: re-run before acting)" if bool(r.get("noisy", false)) else ""]


## A rounded signed number: `+2`, `-28`, `+0` (never `-0`).
static func signed(v: float) -> String:
	return "%+d" % int(round(v))


# ================================================================ pixel diff

## A shot prepared for the diff: full frames cropped around the model (CROP), everything fitted to TILE.
static func prepare(img: Image, shot: String) -> Image:
	var im := ArtLabImage.rgba8(img).duplicate() as Image
	if CROP.has(shot):
		var c: Vector2i = CROP[shot]
		var cw := mini(c.x, im.get_width())
		var ch := mini(c.y, im.get_height())
		im = im.get_region(Rect2i((im.get_width() - cw) / 2, (im.get_height() - ch) / 2, cw, ch))
	var s := minf(1.0, minf(float(TILE.x) / float(im.get_width()), float(TILE.y) / float(im.get_height())))
	if s < 1.0:
		im.resize(maxi(1, int(float(im.get_width()) * s)), maxi(1, int(float(im.get_height()) * s)), Image.INTERPOLATE_BILINEAR)
	return im


## Changed-pixel diff of two prepared images (the old one is resized to the new size when they differ). Returns
## {"frac": changed share 0-1, "changed", "total", "resized": bool, "mask": Image (the new shot dimmed to grey, changed
## pixels magenta, brighter = a bigger change)}.
static func pixel_diff(old: Image, new: Image, thr: int = PIXEL_THR) -> Dictionary:
	var b := ArtLabImage.rgba8(new)
	var a := ArtLabImage.rgba8(old)
	var resized := false
	if a.get_size() != b.get_size():
		a = a.duplicate() as Image
		a.resize(b.get_width(), b.get_height(), Image.INTERPOLATE_BILINEAR)
		resized = true
	var da := a.get_data()
	var db := b.get_data()
	var out := PackedByteArray()
	out.resize(db.size())
	var changed := 0
	var n := b.get_width() * b.get_height()
	for i: int in n:
		var j := i * 4
		var d := absi(int(da[j]) - int(db[j])) + absi(int(da[j + 1]) - int(db[j + 1])) + absi(int(da[j + 2]) - int(db[j + 2]))
		if d > thr:
			changed += 1
			var v := clampi(140 + d / 2, 140, 255)
			out[j] = v
			out[j + 1] = 0
			out[j + 2] = v
		else:
			var g := (int(db[j]) + int(db[j + 1]) + int(db[j + 2])) / 9   # grey at ~1/3 brightness
			out[j] = g
			out[j + 1] = g
			out[j + 2] = g
		out[j + 3] = 255
	var mask := Image.create_from_data(b.get_width(), b.get_height(), false, Image.FORMAT_RGBA8, out)
	return {"frac": float(changed) / float(maxi(n, 1)), "changed": changed, "total": n, "resized": resized, "mask": mask}


# ================================================================ run hooks (called by ArtLabRunner.run)

## After the checks of a run: merges a focus run into the previous scorecard, compares with the previous run (checks,
## quality, shots) and writes diff_sheet.png (windowed). Fills `ctx.rep.compare` / `ctx.rep.focus`; returns the console
## summary line ("" when there was nothing to compare).
static func finish(ctx: ArtLabRunner, prev: Dictionary) -> String:
	var rep := ctx.rep
	var pj: Dictionary = prev.get("json", {})
	var prev_checks: Array = pj.get("checks", [])
	var new_shots: Dictionary = rep.shots.duplicate()   # the shots this run took (a focus run merges the old ones in)
	if not ctx.focus.is_empty():
		var ids: Array[String] = []
		for k: String in ctx.focus:
			ids.append(k)
		rep.focus = ids
		if prev_checks.is_empty():
			rep.notes.append("focus=%s: no previous scorecard in %s, so this is a partial run (only the focused passes)" % [
				",".join(ids), ctx.out_dir])
		else:
			var measured := rep.checks.size()
			rep.checks = merge_focus(prev_checks, rep.checks, ctx.focus)
			var kept := 0
			for c: Dictionary in rep.checks:
				if bool(c.get("kept", false)):
					kept += 1
			var shots: Dictionary = (pj.get("shots", {}) as Dictionary).duplicate()
			shots.merge(rep.shots, true)
			rep.shots = shots
			rep.focus_note = "focus=%s: %d check(s) re-measured, %d kept from the run of %s" % [",".join(ids),
				rep.checks.size() - kept, kept, pj.get("started", "?")]
			if measured == 0:
				rep.focus_note += " (no focused check was produced)"
	var cj: Dictionary = prev.get("cmp_json", {})
	if cj.is_empty() or not bool(prev.get("compare", false)):
		return ""
	var cmp := compare_checks(cj.get("checks", []), rep.checks)
	cmp["against"] = String(prev.get("dir", "")).replace("res://", "")
	cmp["prev_started"] = String(cj.get("started", ""))
	cmp["prev_quality"] = float(cj.get("quality", -1.0))
	cmp["quality"] = rep.quality()
	cmp["prev_result"] = String(cj.get("result", ""))
	var shot_rows: Array[Dictionary] = []
	var tiles: Array[Dictionary] = []
	var old_imgs: Dictionary = prev.get("images", {})
	for shot: String in new_shots:
		if shot in SKIP_SHOTS or not old_imgs.has(shot):
			continue
		var img := _load(ctx.out_dir.path_join(String(new_shots[shot])))
		if img == null:
			continue
		var nimg := prepare(img, shot)
		var pd := pixel_diff(old_imgs[shot], nimg)
		shot_rows.append({"shot": shot, "changed": snappedf(float(pd["frac"]), 0.0001), "resized": pd["resized"]})
		tiles.append({"img": old_imgs[shot], "label": "%s before" % shot})
		tiles.append({"img": nimg, "label": "%s after" % shot})
		tiles.append({"img": pd["mask"], "label": "%s: %.1f %% changed%s" % [shot, 100.0 * float(pd["frac"]),
			" (size differs)" if bool(pd["resized"]) else ""]})
	cmp["shots"] = shot_rows
	rep.compare = cmp
	if not ctx.headless and not tiles.is_empty():
		var sheet: Image = await render_sheet(ctx, cmp, tiles)
		sheet.save_png(ProjectSettings.globalize_path(ctx.out_dir.path_join("diff_sheet.png")))
		rep.shots["diff_sheet"] = "diff_sheet.png"
		cmp["sheet"] = "diff_sheet.png"
	return summary_line(ctx.asset, cmp)


## `ART LAB <asset>: vs previous run quality 91 -> 93 (+2); worse: R3 -28, R5 WARN; better: 2; diff_sheet.png`
static func summary_line(asset: String, cmp: Dictionary) -> String:
	var q0 := float(cmp.get("prev_quality", -1.0))
	var q1 := float(cmp.get("quality", 0.0))
	var worse: Array[String] = []
	for r: Dictionary in cmp.get("worse", []):
		worse.append("%s %s%s" % [r["id"], (String(r["new_status"]) + " ") if r["new_status"] != r["old_status"] else "", signed(float(r["delta"]))])
	return "ART LAB %s: vs previous run quality %.0f -> %.0f (%s); worse: %s; better: %d%s" % [asset, q0, q1, signed(roundf(q1) - roundf(q0)),
		", ".join(worse) if not worse.is_empty() else "none", (cmp.get("better", []) as Array).size(),
		("; " + String(cmp["sheet"])) if cmp.has("sheet") else ""]


## The diff contact sheet: a header (quality before -> after, what got worse / better) over rows of
## old | new | changed-pixel mask per shot. 2D SubViewport under the runner (windowed only).
static func render_sheet(ctx: ArtLabRunner, cmp: Dictionary, tiles: Array[Dictionary]) -> Image:
	var cols := 3
	var tw := TILE.x
	var th := TILE.y
	var lab_h := 22
	var worse_n := mini((cmp.get("worse", []) as Array).size(), 3)
	var better_n := mini((cmp.get("better", []) as Array).size(), 4 - worse_n)
	var header := 74 + 19 * (worse_n + better_n)
	var rows := (tiles.size() + cols - 1) / cols
	var size := Vector2i(tw * cols, header + rows * (th + lab_h))
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	ctx.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.1)
	bg.size = Vector2(size)
	vp.add_child(bg)
	var q0 := float(cmp.get("prev_quality", -1.0))
	var q1 := float(cmp.get("quality", 0.0))
	_label(vp, "BEFORE / AFTER  %s  (previous run %s)" % [ctx.asset, cmp.get("prev_started", "?")], Vector2(12, 8), 24,
		Color(0.95, 0.95, 0.95))
	var worse: Array = cmp.get("worse", [])
	var col := Color(1.0, 0.45, 0.4) if not worse.is_empty() or q1 < q0 - 0.5 else Color(0.4, 0.9, 0.45)
	_label(vp, "quality %.0f -> %.0f (%s)   %d worse, %d better, %d unchanged" % [q0, q1, signed(roundf(q1) - roundf(q0)), worse.size(),
		(cmp.get("better", []) as Array).size(), int(cmp.get("unchanged", 0))], Vector2(12, 40), 20, col)
	var y := 70.0
	for r: Dictionary in worse.slice(0, 3):
		_label(vp, ("WORSE " + row_text(r)).left(150), Vector2(12, y), 15, Color(1.0, 0.55, 0.45))
		y += 19.0
	for r2: Dictionary in (cmp.get("better", []) as Array).slice(0, better_n):
		_label(vp, ("better " + row_text(r2)).left(150), Vector2(12, y), 15, Color(0.55, 0.9, 0.6))
		y += 19.0
	for i: int in tiles.size():
		var t: Dictionary = tiles[i]
		var x := float((i % cols) * tw)
		var ty := float(header + (i / cols) * (th + lab_h))
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(ArtLabImage.fit(t["img"], tw - 4, th - 4))
		tr.position = Vector2(x + 2, ty + 2)
		tr.size = Vector2(tw - 4, th - 4)
		vp.add_child(tr)
		_label(vp, String(t["label"]).left(52), Vector2(x + 6, ty + th), 15, Color(0.85, 0.85, 0.85))
	for k: int in 3:
		await ctx.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


static func _label(p: Node, text: String, pos: Vector2, font_size: int, c: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", c)
	p.add_child(l)
