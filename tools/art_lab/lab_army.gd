class_name ArtLabArmy
extends RefCounted
## Art Lab v3 army sweep + ranked art backlog (docs/plan/art-lab-v3-plan.md task 1.E; manual docs/plan/art-lab.md).
## Entry: tools/art_lab/art_lab.gd `sweep=all` (or `sweep=fire` / `sweep=ice,nature`), wrapper
## `.\tools\art_lab\run_art_lab.ps1 -Sweep all`.
## 1. Every asset of the asked kingdoms (units incl. cavalry, wizard, titan, mount, buildings; `neutral` = neutral units,
##    champions, beasts, critters, mounts, neutral buildings) runs in ONE batch process (lab_batch.gd, stage built once),
##    quick=1 (no per-asset references / frame cost; `full=1` keeps them), scorecards in docs/art/lab/_army/assets/<name>/.
## 2. Army silhouette pass: every mobile model (unit / mount / titan / beast / critter) of the asked kingdoms + the
##    neutral neighbours is rendered ONCE at 40 m (4 turns, black masks + one lit frame in its own team colour); every
##    pair is compared (mean IoU over the turns, mean-colour dE); the closest pairs get a side-by-side tile
##    (lit A | lit B | overlay, same scale) in docs/art/lab/_army/pairs/.
## 3. docs/art/lab/_army/army.md: every asset ranked by quality (worst first) with its top improvement, its fixes.json
##    top recipe (task 1.A, read when present) and its closest look-alike; per-kingdom silhouette sheets + pair tables.
## 4. docs/art/lab/backlog.md (sweep=all, or backlog=1): the ranked art to-do list: every FAIL first, then the largest
##    estimated score gain per estimated minute; one line per item with the command to re-check. Windowed scorecards of
##    assets outside the sweep (decor sets, VFX, landmarks: docs/art/lab/<name>/scorecard.json) are ranked too.
## Options: only=a,b (name filter), buildings=0, full=1, fail_fast=1, log=1 (improvement-log rows, default off),
##   reuse=1 (no asset runs: the last sweep's scorecards + a fresh silhouette pass, ~1-2 min), backlog_only=1 (rewrite
##   backlog.md from the last sweep's scorecards + army.json, headless, seconds),
##   out=<dir> (default docs/art/lab/_army; a partial sweep writes _army/<groups>/), backlog=<path>, pairs=<tiles per
##   kingdom, default 3>, ground= / light= / timing= pass through to every asset.

const GROUPS: Array[String] = ["fire", "ice", "nature", "shadow", "neutral"]
const KINGDOMS: Array[String] = ["fire", "ice", "nature", "shadow"]
const SIL_KINDS: Array[String] = ["unit", "mount", "titan", "beast", "critter"]
const OUT := "res://docs/art/lab/_army"
const BACKLOG := "res://docs/art/lab/backlog.md"
const LAB_DIR := "res://docs/art/lab"
## File-name words that give the kingdom when the folder does not (wizards, titans, mounts, keeps). Neutral folders win.
const KINGDOM_WORDS: Array = [["vessa", "fire"], ["malrik", "shadow"], ["torvald", "ice"], ["ysolde", "nature"],
	["cinder", "fire"], ["ember", "fire"], ["frost", "ice"], ["rime", "ice"], ["mammoth", "ice"], ["dusk", "shadow"],
	["nightmare", "shadow"], ["gloam", "shadow"], ["grove", "nature"], ["treant", "nature"]]
## Estimated minutes of tech-artist work to move one check to a clean PASS (by check id; default 20). Rough, from the
## art agents' reports: a recolour ~10 min, a glow / light tweak ~10-15, a merge ~20, a geometry / silhouette rework 30-45.
const MINUTES := {"B1": 20, "B2": 20, "B3": 15, "B4": 40, "B4t": 40, "B5": 10, "B6": 15, "B6l": 15, "B6p": 10, "B7": 10,
	"B8": 25, "B9": 20, "B9m": 20, "B10": 25, "B11": 20, "B12": 20, "B13": 30, "H0": 20, "H1": 20, "H2": 15, "A1": 20,
	"A2": 15, "A3": 25, "R1": 30, "R2": 45, "R2r": 5, "R3": 10, "R3t": 15, "R4": 15, "R4k": 15, "R5": 15, "R6": 15,
	"R7": 10, "R8": 20, "R8w": 20, "R9": 10, "R10": 20, "P1": 30, "P2": 30, "P3": 15, "P4": 30, "P5": 10, "V2": 20,
	"V3": 20, "V4": 15, "V5": 15, "V6": 20}
const OWNER := "tech-artist"


# ================================================================ asset list

## The kingdom of an art path: a neutral folder (neutral, champions, caravan, capture, guilds, tavern, trade post) wins,
## then a kingdom folder / file prefix, then the KINGDOM_WORDS table; else neutral.
static func kingdom_of(path: String) -> String:
	var p := path.to_lower()
	for nw: String in ["/neutral/", "/champions/", "/caravan/", "/capture/", "/guilds/", "/tavern/", "/trade_post/"]:
		if nw in p:
			return "neutral"
	for k: String in KINGDOMS:
		if "/%s/" % k in p or p.get_file().begins_with(k + "_"):
			return k
	for pair: Array in KINGDOM_WORDS:
		if String(pair[0]) in p.get_file():
			return pair[1]
	return "neutral"


## Every asset of the sweep: [{scene, name, kind, kingdom, group}] for the asked groups (kingdoms + "neutral"), sorted
## by group then name. `buildings=false` leaves out res://art/buildings/.
static func assets(groups: Array[String], buildings: bool = true, only: String = "") -> Array[Dictionary]:
	var paths: Array[String] = ArtLabScenes.list_scenes("res://art/units/", true, true)
	if buildings:
		paths.append_array(ArtLabScenes.list_scenes("res://art/buildings/", true, true))
	var out: Array[Dictionary] = []
	var seen := {}
	for p: String in paths:
		var nm := p.get_file().get_basename()
		var k := kingdom_of(p)
		if not k in groups or seen.has(nm):
			continue
		if only != "":
			var hit := false
			for w: String in only.split(",", false):
				if w.strip_edges() != "" and w.strip_edges() in nm:
					hit = true
			if not hit:
				continue
		seen[nm] = true
		out.append({"scene": p, "name": nm, "kind": ArtLabBatch.guess_kind(p), "kingdom": k, "group": k})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ga := GROUPS.find(String(a["group"]))
		var gb := GROUPS.find(String(b["group"]))
		return ga < gb if ga != gb else String(a["name"]) < String(b["name"]))
	return out


## The sweep groups from `sweep=` ("all", "fire", "ice,nature"); empty when a name is unknown.
static func parse_groups(spec: String) -> Array[String]:
	var out: Array[String] = []
	if spec.strip_edges().to_lower() in ["all", "1", ""]:
		out.assign(GROUPS)
		return out
	for g: String in spec.to_lower().split(",", false):
		var s := g.strip_edges()
		if not s in GROUPS:
			return [] as Array[String]
		if not s in out:
			out.append(s)
	return out


# ================================================================ ranking (pure: the headless test checks these)

## Backlog items of one asset's checks (scorecard check dicts: id, name, status, score, weight, group, value, rule,
## hint, improve): every scored check with headroom and a fix text. gain = quality points if that check reaches a clean
## PASS (0.85 for a FAIL / WARN, 1.0 otherwise; weights from lab_score.gd), minutes from MINUTES, rate = gain / minute.
static func items_of(checks: Array) -> Array[Dictionary]:
	var sw := 0.0
	for c: Dictionary in checks:
		if float(c.get("score", -1.0)) >= 0.0 and String(c.get("status", "")) != "SKIP":
			sw += _w(c)
	var out: Array[Dictionary] = []
	if sw <= 0.0:
		return out
	for c2: Dictionary in checks:
		var s := float(c2.get("score", -1.0))
		var st := String(c2.get("status", ""))
		if s < 0.0 or st == "SKIP":
			continue
		var bad := st == "FAIL" or st == "WARN"
		if not bad and s >= 0.97:
			continue
		var text := String(c2.get("improve", ""))
		if text == "" and bad:
			text = String(c2.get("hint", ""))
		if text == "":
			continue
		var gain := 100.0 * _w(c2) * maxf((0.85 if bad else 1.0) - s, 0.0) / sw
		var id := String(c2.get("id", ""))
		var mins := float(MINUTES.get(id, 20))
		out.append({"id": id, "name": String(c2.get("name", "")), "status": st, "text": text,
			"value": String(c2.get("value", "")), "rule": String(c2.get("rule", "")), "gain": gain, "minutes": mins,
			"rate": gain / mins})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _before(a, b))
	return out


static func _w(c: Dictionary) -> float:
	return float(c.get("weight", 1.0)) * float(ArtLabScore.GROUP_WEIGHT.get(String(c.get("group", "")), 1.0))


## Backlog order: FAIL first, then the best gain per minute (ties: the bigger gain).
static func _before(a: Dictionary, b: Dictionary) -> bool:
	var fa := String(a["status"]) == "FAIL"
	var fb := String(b["status"]) == "FAIL"
	if fa != fb:
		return fa
	if not is_equal_approx(float(a["rate"]), float(b["rate"])):
		return float(a["rate"]) > float(b["rate"])
	return float(a["gain"]) > float(b["gain"])


## The backlog of several assets: per asset every FAIL + its best other item (by rate), each tagged with the asset
## (`assets`: [{name, kind, kingdom, ground, quality, result, checks, source, extra_items}]). Sorted by `_before`.
static func backlog(assets_in: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a: Dictionary in assets_in:
		var its := items_of(a.get("checks", []))
		its.append_array(a.get("extra_items", []) as Array)
		its.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return _before(x, y))
		var took_other := false
		for it: Dictionary in its:
			if String(it["status"]) != "FAIL":
				if took_other:
					continue
				took_other = true
			var row := it.duplicate()
			for k: String in ["name", "kind", "kingdom", "ground", "quality", "result", "source", "out"]:
				row["asset_" + k] = a.get(k, "")
			out.append(row)
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return _before(x, y))
	return out


## The command that re-checks one asset (short names work for models, decor sets and VFX families).
static func recheck_cmd(asset_name: String, kind: String, kingdom: String, ground: String = "") -> String:
	var s := ".\\tools\\art_lab\\run_art_lab.ps1 %s %s %s" % [asset_name, kind, kingdom]
	if ground != "" and ground != "meadow":
		s += " -Extra 'ground=%s'" % ground
	return s


## One backlog line (a Markdown table row).
static func backlog_line(i: int, it: Dictionary) -> String:
	var what := "%s %s" % [it["id"], it["name"]]
	if String(it.get("value", "")) != "":
		what += " (%s)" % _clip(String(it["value"]), 60)
	return "| %d | %s | %s | %s | %s: %s | +%.1f | %d | %.2f | %s | `%s` |" % [i, it["asset_name"], it["asset_kingdom"],
		it["status"], _cell(what), _cell(_clip(String(it["text"]), 260)), float(it["gain"]), int(it["minutes"]),
		float(it["rate"]), OWNER, recheck_cmd(String(it["asset_name"]), String(it["asset_kind"]),
		String(it["asset_kingdom"]), String(it["asset_ground"]))]


## The top recipe of an asset's fixes.json (task 1.A writes it next to the scorecard; read only when present, any of
## the shapes [..], {fixes: [..]}, {recipes: [..]}; the recipe for `check_id` wins; `computed_only` = the first recipe
## whose values were computed, e.g. a colour search or a vertex plan, not a text hint). "" when there is none.
static func top_recipe(out_dir: String, check_id: String = "", computed_only: bool = false) -> String:
	var p := out_dir.path_join("fixes.json")
	if not FileAccess.file_exists(p):
		return ""
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	var arr: Array = []
	if d is Array:
		arr = d
	elif d is Dictionary:
		for k: String in ["fixes", "recipes", "items"]:
			if (d as Dictionary).get(k) is Array:
				arr = d[k]
				break
	if computed_only:
		var keep: Array = []
		for f0: Variant in arr:
			if f0 is Dictionary and bool((f0 as Dictionary).get("computed", false)):
				keep.append(f0)
		arr = keep
	if arr.is_empty():
		return ""
	var pick: Variant = arr[0]
	if check_id != "":
		for f: Variant in arr:
			if f is Dictionary and String((f as Dictionary).get("check", (f as Dictionary).get("id", ""))) == check_id:
				pick = f
				break
	if pick is Dictionary:
		for k2: String in ["proposal", "recipe", "fix", "text", "summary", "action"]:
			if (pick as Dictionary).has(k2) and String(pick[k2]) != "":
				var cid := String((pick as Dictionary).get("check", (pick as Dictionary).get("id", "")))
				return ("%s: " % cid if cid != "" else "") + String(pick[k2])
		return JSON.stringify(pick)
	return String(pick)


static func _cell(s: String) -> String:
	return s.replace("|", "/").replace("\n", " ").strip_edges()


static func _clip(s: String, n: int) -> String:
	return s if s.length() <= n else s.left(n - 3) + "..."


# ================================================================ silhouettes (windowed)

## Renders every model once at 40 m on the meadow (warm light): 4 black masks (yaw 0 / 90 / 180 / 270) over the
## model's own screen rect (a square box that holds every turn) + the mean Lab colour and a lit crop at yaw 0 in its
## own team colour. Returns name -> {name, group, kind, roi, masks, lab, lit, lit_rect}. Empty headless.
static func silhouettes(ctx: ArtLabRunner, models: Array[Dictionary]) -> Dictionary:
	var out := {}
	ctx.headless = DisplayServer.get_name() == "headless"
	if ctx.headless:
		return out
	await ctx.use_stage(&"warm")
	ctx.gp = ArtLabStage.GROUND_POINTS[&"meadow"]
	ctx.ground_y = ctx.gp.y
	ctx.stage.game_cam(ctx.gp, 40.0)
	for md: Dictionary in models:
		ctx.kingdom = StringName(md["kingdom"])
		var inst := ctx.spawn(String(md["scene"]), ctx.gp, 0.0)
		if inst == null:
			continue
		if inst.has_method(&"set_team_color"):
			inst.call(&"set_team_color", ctx.model_color(inst))
		await ctx.frames(2)
		await ctx.settle(inst)
		ArtLabStage.freeze(inst, true)
		var hold := inst.get_parent() as Node3D
		var b := ArtLabCensus.world_aabb(inst, ctx.ground_y)
		var r := 0.3
		for i: int in 8:
			var e := b.get_endpoint(i) - ctx.gp
			r = maxf(r, Vector2(e.x, e.z).length())
		var box := AABB(Vector3(ctx.gp.x - r, ctx.ground_y, ctx.gp.z - r), Vector3(2.0 * r, maxf(b.end.y - ctx.ground_y, 0.3), 2.0 * r))
		var roi := ctx.stage.roi_of(box, 4)
		var ms: Array = []
		for yaw: float in [0.0, 90.0, 180.0, 270.0]:
			hold.rotation.y = deg_to_rad(yaw)
			ms.append(ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, inst), roi))
		hold.rotation.y = 0.0
		var lit: Image = await ctx.stage.grab()
		var lr := ArtLabImage.clamp_rect(roi, 24, lit.get_width(), lit.get_height())
		out[md["name"]] = {"name": md["name"], "group": md["group"], "kind": md["kind"], "roi": roi, "masks": ms,
			"lab": ArtLabImage.mean_lab(lit, roi, ms[0]), "lit": lit.get_region(lr), "lit_rect": lr}
		ctx.free_model(inst)
		await ctx.frames(1)
	return out


## IoU of two masks that cover different frame rects (`ra`, `rb`): only the overlap of their boxes is scanned.
static func iou_at(a: ArtLabImage.Mask, ra: Rect2i, b: ArtLabImage.Mask, rb: Rect2i) -> float:
	if a.count == 0 or b.count == 0:
		return 0.0
	var ba := Rect2i(ra.position + a.bbox.position, a.bbox.size)
	var bb := Rect2i(rb.position + b.bbox.position, b.bbox.size)
	var ov := ba.intersection(bb)
	if not ov.has_area():
		return 0.0
	var inter := 0
	for y: int in range(ov.position.y, ov.end.y):
		var rowa := (y - ra.position.y) * a.w - ra.position.x
		var rowb := (y - rb.position.y) * b.w - rb.position.x
		for x: int in range(ov.position.x, ov.end.x):
			if a.bits[rowa + x] != 0 and b.bits[rowb + x] != 0:
				inter += 1
	return float(inter) / float(a.count + b.count - inter)


## Every pair of silhouettes: mean IoU over the 4 turns + mean-colour dE. Pairs whose areas differ so much that the IoU
## cannot pass 0.5 (min / max pixel count) are skipped, and so are mount / unit pairs (a grove stag vs the cavalry that
## rides it). Sorted by IoU, highest first.
static func pairs_of(sils: Dictionary) -> Array[Dictionary]:
	var names: Array = sils.keys()
	var out: Array[Dictionary] = []
	for i: int in names.size():
		for j: int in range(i + 1, names.size()):
			var a: Dictionary = sils[names[i]]
			var b: Dictionary = sils[names[j]]
			if (a["kind"] == "mount") != (b["kind"] == "mount") and (a["kind"] == "unit" or b["kind"] == "unit"):
				continue   # a bare mount is never fielded next to units (it is the cavalry's lower half): no mount / unit pairs
			var bound := 0.0
			for y: int in 4:
				var ca := float((a["masks"][y] as ArtLabImage.Mask).count)
				var cb := float((b["masks"][y] as ArtLabImage.Mask).count)
				bound += minf(ca, cb) / maxf(maxf(ca, cb), 1.0)
			if bound / 4.0 < 0.5:
				continue
			var s := 0.0
			for y2: int in 4:
				s += iou_at(a["masks"][y2], a["roi"], b["masks"][y2], b["roi"])
			out.append({"a": a["name"], "b": b["name"], "ga": a["group"], "gb": b["group"], "iou": s / 4.0,
				"de": (a["lab"] as Vector3).distance_to(b["lab"])})
	out.sort_custom(func(x: Dictionary, y3: Dictionary) -> bool: return float(x["iou"]) > float(y3["iou"]))
	return out


static func verdict(pr: Dictionary) -> String:
	if float(pr["iou"]) > 0.8 and float(pr["de"]) < 15.0:
		return "READS ALIKE"
	if float(pr["iou"]) > 0.8:
		return "same shape family, colour differs"
	return "close" if float(pr["iou"]) > 0.65 else "distinct"


static func _frame_bbox(s: Dictionary) -> Rect2i:
	var m: ArtLabImage.Mask = s["masks"][0]
	var roi: Rect2i = s["roi"]
	return Rect2i(roi.position + m.bbox.position, m.bbox.size)


## `src` (covering frame rect `src_rect`) cut to the frame rect `want` (bg where src has no pixels).
static func _frame_img(src: Image, src_rect: Rect2i, want: Rect2i, bg: Color) -> Image:
	var out := Image.create(maxi(want.size.x, 1), maxi(want.size.y, 1), false, Image.FORMAT_RGBA8)
	out.fill(bg)
	var ov := src_rect.intersection(want)
	if ov.has_area():
		out.blit_rect(ArtLabImage.rgba8(src), Rect2i(ov.position - src_rect.position, ov.size), ov.position - want.position)
	return out


## Side-by-side tile of a pair, same scale: lit A | lit B | overlay (red = A only, blue = B only, dark = both), yaw 0.
static func pair_tile(a: Dictionary, b: Dictionary) -> Image:
	var want := ArtLabImage.clamp_rect(_frame_bbox(a).merge(_frame_bbox(b)), 10, ArtLabStage.W, ArtLabStage.H)
	var bg := Color(0.12, 0.12, 0.12)
	var la := _frame_img(a["lit"], a["lit_rect"], want, bg)
	var lb := _frame_img(b["lit"], b["lit_rect"], want, bg)
	var ov := Image.create(want.size.x, want.size.y, false, Image.FORMAT_RGBA8)
	ov.fill(Color.WHITE)
	var ma: ArtLabImage.Mask = a["masks"][0]
	var mb: ArtLabImage.Mask = b["masks"][0]
	var ra: Rect2i = a["roi"]
	var rb: Rect2i = b["roi"]
	for y: int in want.size.y:
		for x: int in want.size.x:
			var fx := want.position.x + x
			var fy := want.position.y + y
			var pa := ma.at(fx - ra.position.x, fy - ra.position.y)
			var pb := mb.at(fx - rb.position.x, fy - rb.position.y)
			if pa and pb:
				ov.set_pixel(x, y, Color(0.2, 0.08, 0.3))
			elif pa:
				ov.set_pixel(x, y, Color(0.9, 0.25, 0.2))
			elif pb:
				ov.set_pixel(x, y, Color(0.2, 0.45, 0.95))
	return ArtLabImage.grid([la, lb, ov] as Array[Image], 3, 260, 260, bg, true)


## Silhouette sheet of some models, black on white, in the given order: units / mounts / critters to scale (one common
## frame rect); titans and beasts fitted to their own box (they would shrink everything else to a few pixels).
static func sheet(sils: Dictionary, names: Array[String]) -> Image:
	var common := Rect2i()
	for n: String in names:
		if String(sils[n]["kind"]) in ["titan", "beast"]:
			continue
		var fb := _frame_bbox(sils[n])
		common = fb if common.size == Vector2i.ZERO else common.merge(fb)
	common = ArtLabImage.clamp_rect(common, 4, ArtLabStage.W, ArtLabStage.H)
	var tiles: Array[Image] = []
	for n2: String in names:
		var s: Dictionary = sils[n2]
		var want := common
		if String(s["kind"]) in ["titan", "beast"] or common.size == Vector2i.ZERO:
			want = ArtLabImage.clamp_rect(_frame_bbox(s), 4, ArtLabStage.W, ArtLabStage.H)
		tiles.append(_frame_img(ArtLabImage.mask_image(s["masks"][0]), s["roi"], want, Color.WHITE))
	return ArtLabImage.grid(tiles, mini(maxi(tiles.size(), 1), 8), 160, 160, Color.WHITE, true)


# ================================================================ the sweep

## `sweep=<all | kingdom[,kingdom]>`: the batch, the silhouette pass, army.md and (all) backlog.md. Returns the exit
## code (0 / 1 any FAIL / 2 bad arguments).
static func sweep(tree: SceneTree, opts: Dictionary) -> int:
	var t0 := Time.get_ticks_msec()
	var groups := parse_groups(String(opts.get("sweep", "all")))
	if groups.is_empty():
		print("ART LAB ERROR: sweep=%s: use all or a comma list of %s" % [opts.get("sweep", ""), GROUPS])
		return 2
	var all := groups.size() == GROUPS.size()
	var out := _res(String(opts.get("out", OUT if all else OUT.path_join("_".join(groups)))))
	var out_root := _res(String(opts.get("out_root", OUT.path_join("assets"))))
	var list := assets(groups, String(opts.get("buildings", "1")) != "0", String(opts.get("only", "")))
	if list.is_empty():
		print("ART LAB ERROR: sweep=%s lists no asset" % opts.get("sweep", ""))
		return 2
	if String(opts.get("backlog_only", "0")) == "1":
		return _rebuild_backlog(list, out, out_root, opts)
	var headless := DisplayServer.get_name() == "headless"
	print("ART LAB SWEEP v3 %s: %d assets (%s)%s" % [",".join(groups), list.size(), _group_counts(list),
		" [headless: budgets only]" if headless else ""])
	_prepare_dirs(out, out_root)
	# 1. the batch (one process, one stage per light preset)
	var entries: Array[PackedStringArray] = []
	for a: Dictionary in list:
		entries.append(PackedStringArray(["scene=" + String(a["scene"]), "kind=" + String(a["kind"]),
			"kingdom=" + String(a["kingdom"])]))
	var shared := {"out_root": out_root, "log": String(opts.get("log", "0")), "progress": "1"}
	if String(opts.get("full", "0")) != "1":
		shared["quick"] = "1"
	for k: String in ["ground", "light", "fail_fast", "timing", "vsync"]:
		if opts.has(k):
			shared[k] = opts[k]
	var pool := {}
	var pool_parent := Node.new()
	pool_parent.name = "StagePool"
	tree.root.add_child(pool_parent)
	var res: Dictionary = {}
	if String(opts.get("reuse", "0")) == "1":
		# re-rank / re-render the silhouettes without re-running the assets: rows from the last sweep's scorecards
		var old := _load_rows(list, out_root)
		var secs: Array = []
		var worst := 0
		for r0: Dictionary in old:
			secs.append(r0["seconds"])
			worst = maxi(worst, int(r0["code"]))
		res = {"rows": old, "seconds": secs, "code": worst, "stages": 0}
		print("ART LAB SWEEP reuse=1: %d scorecards from %s (lab times are the last sweep's)" % [old.size(), out_root])
	else:
		res = await ArtLabBatch.run_all(tree.root, entries, shared, pool_parent, pool)
	var t_batch := float(Time.get_ticks_msec() - t0) / 1000.0
	var note := ""
	if String(opts.get("reuse", "0")) == "1":
		t_batch = 0.0
		for sx: Variant in res["seconds"]:
			t_batch += float(sx)
		note = "**reuse=1**: the asset rows are the last sweep's scorecards (batch time = the sum of their lab times, not wall time); the silhouette pass below is fresh (%s).\n\n" % Time.get_datetime_string_from_system(false, true)
		if FileAccess.file_exists(out.path_join("army.md")):
			var last := ""
			for l: String in FileAccess.get_file_as_string(out.path_join("army.md")).split("\n"):
				if l.begins_with("Last full sweep: "):
					last = l.trim_prefix("Last full sweep: ")
					break
				if l.begins_with("Time: ") and last == "":
					last = l.trim_prefix("Time: ")
			if last != "":
				note += "Last full sweep: %s\n\n" % last
	# 2. silhouettes: the asked kingdoms' mobile models + the neutral neighbours
	var t1 := Time.get_ticks_msec()
	var models: Array[Dictionary] = []
	var sil_list := list.duplicate()
	if not "neutral" in groups:
		sil_list.append_array(assets(["neutral"] as Array[String], false))
	for a2: Dictionary in sil_list:
		if String(a2["kind"]) in SIL_KINDS:
			models.append(a2)
	var ctx := ArtLabRunner.new()
	ctx.name = "ArmyPass"
	ctx.stage_parent = pool_parent
	ctx.stage_pool = pool
	tree.root.add_child(ctx)
	var sils: Dictionary = await silhouettes(ctx, models)
	var pairs := pairs_of(sils)
	var t_sil := float(Time.get_ticks_msec() - t1) / 1000.0
	# 3. army.md (+ tiles) and 4. backlog.md
	var rows: Array = res["rows"]
	var groups_of := {}
	for a3: Dictionary in list:
		groups_of[a3["name"]] = a3["group"]
	var md := _army_md(groups, list, rows, sils, pairs, out, int(opts.get("pairs", "3")), t_batch, t_sil,
		float(Time.get_ticks_msec() - t0) / 1000.0, res, note)
	_write(out.path_join("army.md"), md)
	var pj: Array = []
	for pr: Dictionary in pairs:
		if float(pr["iou"]) > 0.6:
			pj.append({"a": pr["a"], "b": pr["b"], "ga": pr["ga"], "gb": pr["gb"], "iou": snappedf(float(pr["iou"]), 0.001),
				"de": snappedf(float(pr["de"]), 0.1)})
	_write(out.path_join("army.json"), JSON.stringify({"date": Time.get_datetime_string_from_system(false, true),
		"groups": groups, "pairs": pj}, "\t"))
	var bl_path := ""
	if all or opts.has("backlog"):
		bl_path = _res(String(opts.get("backlog", "1"))) if String(opts.get("backlog", "1")) != "1" else BACKLOG
		_write(bl_path, _backlog_md(rows, pairs, groups_of, all, out))
	ctx.queue_free()
	pool_parent.queue_free()
	var total := float(Time.get_ticks_msec() - t0) / 1000.0
	var fails := 0
	for r: Dictionary in rows:
		if String(r["result"]) == "FAIL":
			fails += 1
	print("ART LAB SWEEP v3 done: %d assets, %d FAIL, %d pairs read alike, batch %.0f s (%.1f s / asset), silhouettes %.0f s (%d models), total %.0f s -> %s%s" % [
		rows.size(), fails, _alike(pairs).size(), t_batch, t_batch / float(maxi(rows.size(), 1)), t_sil, sils.size(), total,
		out.path_join("army.md"), (", " + bl_path) if bl_path != "" else ""])
	return int(res["code"])


## `backlog_only=1`: rebuilds backlog.md from the last sweep's scorecards (out_root/<name>/scorecard.json) and its
## army.json pairs, no Godot rendering (e.g. after a tech-artist re-ran some assets into the sweep folder, or after a
## ranking change). Works headless.
static func _rebuild_backlog(list: Array[Dictionary], out: String, out_root: String, opts: Dictionary) -> int:
	var rows := _load_rows(list, out_root)
	var groups_of := {}
	var kind_of := {}
	for a: Dictionary in list:
		groups_of[a["name"]] = a["group"]
		kind_of[a["name"]] = a["kind"]
	for a2: Dictionary in assets(["neutral"] as Array[String], false):
		groups_of[a2["name"]] = a2["group"]
		kind_of[a2["name"]] = a2["kind"]
	var pairs: Array[Dictionary] = []
	var aj: Variant = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("army.json"))) if FileAccess.file_exists(out.path_join("army.json")) else null
	if aj is Dictionary:
		for pr: Dictionary in (aj as Dictionary).get("pairs", []):
			pairs.append(pr)
	elif FileAccess.file_exists(out.path_join("army.md")):   # older sweep: the pair tables of army.md
		var seen := {}
		for l: String in FileAccess.get_file_as_string(out.path_join("army.md")).split("\n"):
			var c := l.split("|")
			if c.size() < 6 or not " / " in c[1] or not c[2].strip_edges().is_valid_float():
				continue
			var ab := c[1].strip_edges().split(" / ")
			if seen.has(c[1]) or ((kind_of.get(ab[0], "") == "mount") != (kind_of.get(ab[1], "") == "mount")):
				continue
			seen[c[1]] = true
			pairs.append({"a": ab[0], "b": ab[1], "ga": groups_of.get(ab[0], ""), "gb": groups_of.get(ab[1], ""),
				"iou": c[2].strip_edges().to_float(), "de": c[3].strip_edges().to_float()})
	var bl_path := _res(String(opts.get("backlog", "1"))) if String(opts.get("backlog", "1")) != "1" else BACKLOG
	_write(bl_path, _backlog_md(rows, pairs, groups_of, list.size() >= assets(GROUPS).size(), out))
	print("ART LAB SWEEP backlog rebuilt from %d scorecards, %d pairs -> %s" % [rows.size(), pairs.size(), bl_path])
	return 0 if not rows.is_empty() else 2


## The batch rows of an earlier sweep, read back from out_root/<name>/scorecard.json (same keys as ArtLabBatch.run_all).
static func _load_rows(list: Array[Dictionary], out_root: String) -> Array:
	var rows: Array = []
	for a: Dictionary in list:
		var p := out_root.path_join(String(a["name"])).path_join("scorecard.json")
		if not FileAccess.file_exists(p):
			continue
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
		if not j is Dictionary:
			continue
		var d: Dictionary = j
		rows.append({"asset": d.get("asset", a["name"]), "result": d.get("result", ""), "quality": float(d.get("quality", 0.0)),
			"checks": d.get("checks", []), "improve": d.get("improve_next", []), "kind": d.get("kind", a["kind"]),
			"tier": d.get("tier", ""), "kingdom": d.get("kingdom", a["kingdom"]), "ground": d.get("ground", ""),
			"out": out_root.path_join(String(a["name"])), "scene": d.get("scene", a["scene"]), "seconds": float(d.get("seconds", 0.0)),
			"code": 1 if String(d.get("result", "")) == "FAIL" else 0})
	return rows


static func _group_counts(list: Array[Dictionary]) -> String:
	var c := {}
	for a: Dictionary in list:
		c[a["group"]] = int(c.get(a["group"], 0)) + 1
	var parts: Array[String] = []
	for g: String in GROUPS:
		if c.has(g):
			parts.append("%s %d" % [g, c[g]])
	return ", ".join(parts)


## The sweep folders: out/, out/pairs/ (old tiles removed), assets/ with a .gitignore for the shots (scorecards stay
## in git, ~2-3 MB of jpg / png per asset do not) and a .gdignore on _army (no Godot import of ~100 shots).
static func _prepare_dirs(out: String, out_root: String) -> void:
	for d: String in [out, out.path_join("pairs"), out_root]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var pd := DirAccess.open(out.path_join("pairs"))
	if pd:
		for f: String in pd.get_files():
			if f.ends_with(".png"):
				pd.remove(f)
	if out.begins_with(OUT) and not FileAccess.file_exists(OUT.path_join(".gdignore")):
		_write(OUT.path_join(".gdignore"), "")
	if not FileAccess.file_exists(out_root.path_join(".gitignore")):
		_write(out_root.path_join(".gitignore"), "# Art Lab army sweep: shots stay local, scorecards are kept\n*.jpg\n*.png\n")


## A res:// path from "docs/..." (user:// and res:// kept).
static func _res(p: String) -> String:
	var s := p.strip_edges().trim_suffix("/")
	return s if "://" in s else "res://" + s.trim_prefix("/")


static func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


static func _alike(pairs: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in pairs:
		if verdict(p) == "READS ALIKE":
			out.append(p)
	return out


## Pairs that matter for a group: kingdom k vs itself / the neutral neighbours; neutral vs neutral.
static func _group_pairs(pairs: Array[Dictionary], g: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in pairs:
		var ga := String(p["ga"])
		var gb := String(p["gb"])
		if g == "neutral":
			if ga == "neutral" and gb == "neutral":
				out.append(p)
		elif (ga == g and (gb == g or gb == "neutral")) or (gb == g and ga == "neutral"):
			out.append(p)
	return out


static func _cross_pairs(pairs: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in pairs:
		if p["ga"] != p["gb"] and p["ga"] != "neutral" and p["gb"] != "neutral":
			out.append(p)
	return out


static func _closest(pairs: Array[Dictionary], nm: String) -> Dictionary:
	for p: Dictionary in pairs:   # sorted by IoU: the first hit is the closest
		if p["a"] == nm or p["b"] == nm:
			return p
	return {}


static func _tile(sils: Dictionary, pr: Dictionary, out: String) -> String:
	var f := "pairs/%s__%s.png" % [pr["a"], pr["b"]]
	if not sils.has(pr["a"]) or not sils.has(pr["b"]):
		return ""
	pair_tile(sils[pr["a"]], sils[pr["b"]]).save_png(ProjectSettings.globalize_path(out.path_join(f)))
	return f


static func _pair_table(prs: Array[Dictionary], sils: Dictionary, out: String, n_rows: int, n_tiles: int) -> String:
	if prs.is_empty():
		return "No pair above IoU 0.5 (every silhouette differs in size or shape).\n\n"
	var s := "| pair | IoU | colour dE | verdict | tile |\n|---|---|---|---|---|\n"
	var i := 0
	for pr: Dictionary in prs.slice(0, n_rows):
		var t := _tile(sils, pr, out) if i < n_tiles else ""
		s += "| %s / %s | %.2f | %.1f | %s | %s |\n" % [pr["a"], pr["b"], float(pr["iou"]), float(pr["de"]), verdict(pr),
			("[tile](%s)" % t) if t != "" else ""]
		i += 1
	s += "\n"
	for pr2: Dictionary in prs.slice(0, n_tiles):
		var f := "pairs/%s__%s.png" % [pr2["a"], pr2["b"]]
		if FileAccess.file_exists(out.path_join(f)):
			s += "![%s vs %s](%s)\n" % [pr2["a"], pr2["b"], f]
	return s + "\n"


static func _army_md(groups: Array[String], list: Array[Dictionary], rows: Array, sils: Dictionary,
		pairs: Array[Dictionary], out: String, n_tiles: int, t_batch: float, t_sil: float, total: float,
		res: Dictionary, note: String = "") -> String:
	var group_of := {}
	for a: Dictionary in list:
		group_of[a["name"]] = a["group"]
	var headless := DisplayServer.get_name() == "headless"
	var s := "# Art Lab army sweep v3: %s\n\n" % ("all kingdoms" if groups.size() == GROUPS.size() else ", ".join(groups))
	s += "%s · lab v%s · %d assets · %s · batch (one Godot process, stage built once), per-asset runs `quick=1` (no references / frame cost: R2 and B13 are judged by the army pass below / the Perf Lab). Re-run: `.\\tools\\art_lab\\run_art_lab.ps1 -Sweep %s`.\n\n" % [
		Time.get_datetime_string_from_system(false, true), ArtLabReport.VERSION, rows.size(),
		"**headless: budgets / health / hooks only**" if headless else "windowed", ",".join(groups) if groups.size() < GROUPS.size() else "all"]
	s += "Time: batch **%.0f s** (%.1f s / asset; first %.1f s), silhouettes %.0f s for %d models, total **%.0f s** (%.1f min). Per-asset scorecards: `docs/art/lab/_army/assets/<name>/` (shots stay local: `.gitignore`). Ranked to-do list: `docs/art/lab/backlog.md` (written by `-Sweep all`).\n\n" % [
		t_batch, t_batch / float(maxi(rows.size(), 1)), float((res["seconds"] as Array)[0]) if not (res["seconds"] as Array).is_empty() else 0.0,
		t_sil, sils.size(), total, total / 60.0]
	s += note
	# per group summary
	s += "## Per kingdom\n\n| group | assets | FAIL | WARN | PASS | mean quality | worst | lab time |\n|---|---|---|---|---|---|---|---|\n"
	for g: String in groups:
		var n := 0
		var cnt := {"FAIL": 0, "WARN": 0, "PASS": 0}
		var qs := 0.0
		var worst := ""
		var wq := 999.0
		var secs := 0.0
		for r: Dictionary in rows:
			if group_of.get(r["asset"], group_of.get(String(r["scene"]).get_file().get_basename(), "")) != g:
				continue
			n += 1
			cnt[r["result"]] = int(cnt.get(r["result"], 0)) + 1
			qs += float(r["quality"])
			secs += float(r["seconds"])
			if float(r["quality"]) < wq:
				wq = float(r["quality"])
				worst = String(r["asset"])
		if n > 0:
			s += "| %s | %d | %d | %d | %d | %.0f | %s %.0f | %.0f s (%.1f min) |\n" % [g, n, cnt["FAIL"], cnt["WARN"], cnt["PASS"],
				qs / float(n), worst, wq, secs, secs / 60.0]
	# ranking
	var sorted_rows := rows.duplicate()
	sorted_rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["quality"]) < float(y["quality"]))
	s += "\n## Ranking (worst first)\n\nTop improvement = the scorecard's \"Improve next\" #1; fix recipe = its `fixes.json` top item (task 1.A, when present); look-alike = the closest silhouette of the army pass (IoU over 4 turns / colour dE).\n\n"
	s += "| # | asset | kingdom | kind / tier | result | quality | FAIL / WARN | top improvement | fix recipe | closest look-alike | scorecard |\n|---|---|---|---|---|---|---|---|---|---|---|\n"
	var i := 1
	for r2: Dictionary in sorted_rows:
		var bad: Array[String] = []
		for c: Dictionary in r2["checks"]:
			if c["status"] == "FAIL" or c["status"] == "WARN":
				bad.append("%s %s" % [c["status"], c["id"]])
		var imp := ""
		var imp_id := ""
		if not (r2["improve"] as Array).is_empty():
			var it: Dictionary = r2["improve"][0]
			imp = "**%s**: %s" % [it["title"], _clip(String(it["text"]), 140)]
			imp_id = String(it["source"]).get_slice(" ", 0)
		var rec := top_recipe(String(r2["out"]), imp_id)
		if rec != "" and imp != "" and rec.substr(rec.find(": ") + 2).left(40) in imp:
			var comp := top_recipe(String(r2["out"]), "", true)
			rec = ("computed %s" % comp) if comp != "" else "(= top improvement)"
		var near := _closest(pairs, String(r2["asset"]))
		var near_s := ""
		if not near.is_empty():
			near_s = "%s %.2f / dE %.0f" % [near["b"] if near["a"] == r2["asset"] else near["a"], float(near["iou"]), float(near["de"])]
		var card := String(r2["out"]).path_join("scorecard.md")
		if card.begins_with(out + "/"):
			card = card.trim_prefix(out + "/")
		elif card.begins_with(OUT + "/") and out.begins_with(OUT + "/"):
			card = "../" + card.trim_prefix(OUT + "/")
		s += "| %d | %s | %s | %s / %s | %s | %.0f | %s | %s | %s | %s | [card](%s) |\n" % [i, r2["asset"],
			group_of.get(r2["asset"], r2["kingdom"]), r2["kind"], r2["tier"], r2["result"], float(r2["quality"]),
			", ".join(bad), _cell(imp), _cell(_clip(rec, 140)), near_s, card]
		i += 1
	# silhouettes
	s += "\n## Army silhouettes (40 m, meadow, own team colour; IoU = mean over yaw 0 / 90 / 180 / 270, reads alike = IoU > 0.8 and colour dE < 15)\n\n"
	if headless or sils.is_empty():
		s += "Skipped (headless: no renderer).\n"
		return s
	s += "Each kingdom is compared with itself and with the neutral neighbours (neutral units, champions, beasts, critters, mounts). Pair tiles: lit A | lit B | overlay (red = A only, blue = B only, dark = both), same scale, yaw 0.\n\n"
	for g2: String in groups:
		var names: Array[String] = []
		for a2: Dictionary in list:
			if a2["group"] == g2 and sils.has(a2["name"]):
				names.append(String(a2["name"]))
		if names.is_empty():
			continue
		var f := "%s_silhouettes.png" % g2
		sheet(sils, names).save_png(ProjectSettings.globalize_path(out.path_join(f)))
		s += "### %s\n\n![%s](%s)\n\nOrder (8 per row; units / mounts to scale, titans / beasts fitted): %s\n\n" % [g2.capitalize(), g2, f, ", ".join(names)]
		s += _pair_table(_group_pairs(pairs, g2), sils, out, 8, n_tiles)
	if groups.size() > 2:
		s += "### Closest pairs across kingdoms (mirror-match risk: team colour is the only difference)\n\n"
		s += _pair_table(_cross_pairs(pairs), sils, out, 8, 4)
	return s


static func _backlog_md(rows: Array, pairs: Array[Dictionary], groups_of: Dictionary, include_old: bool, out: String) -> String:
	var assets_in: Array = []
	var in_sweep := {}
	var alike := _alike(pairs)
	for r: Dictionary in rows:
		in_sweep[r["asset"]] = true
		var extra: Array[Dictionary] = []
		for pr: Dictionary in alike:
			if pr["a"] == r["asset"] or pr["b"] == r["asset"]:
				var other := String(pr["b"] if pr["a"] == r["asset"] else pr["a"])
				extra.append({"id": "R2", "name": "Reads alike (army pass)", "status": "WARN",
					"text": "Reads like %s at 40 m (IoU %.2f, dE %.0f): change the top third of the silhouette (head / crest / weapon) or the main colour mass; see docs/art/lab/_army/pairs/" % [other, float(pr["iou"]), float(pr["de"])],
					"value": "IoU %.2f vs %s" % [float(pr["iou"]), other], "rule": "IoU <= 0.8 or dE >= 15",
					"gain": 5.0, "minutes": float(MINUTES["R2"]), "rate": 5.0 / float(MINUTES["R2"])})
		assets_in.append({"name": r["asset"], "kind": r["kind"], "kingdom": groups_of.get(r["asset"], r["kingdom"]),
			"ground": r["ground"], "quality": r["quality"], "result": r["result"], "checks": r["checks"],
			"source": "sweep", "out": r["out"], "extra_items": extra})
	var older := 0
	if include_old:
		var d := DirAccess.open(LAB_DIR)
		if d:
			for sub: String in d.get_directories():
				if sub.begins_with("_") or in_sweep.has(sub):
					continue
				var p := LAB_DIR.path_join(sub).path_join("scorecard.json")
				if not FileAccess.file_exists(p):
					continue
				var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
				if not j is Dictionary or bool((j as Dictionary).get("headless", true)) or in_sweep.has(String(j.get("asset", sub))):
					continue
				older += 1
				assets_in.append({"name": String(j.get("asset", sub)), "kind": String(j.get("kind", "")),
					"kingdom": String(j.get("kingdom", "neutral")), "ground": String(j.get("ground", "")),
					"quality": float(j.get("quality", 0.0)), "result": String(j.get("result", "")),
					"checks": j.get("checks", []), "source": "scorecard %s" % String(j.get("started", "")).left(10),
					"out": LAB_DIR.path_join(sub)})
	var items := backlog(assets_in)
	var s := "# Art backlog (ranked by the Art Lab)\n\n"
	s += "Generated %s by `.\\tools\\art_lab\\run_art_lab.ps1 -Sweep all` (lab v%s): %d swept assets + %d older windowed scorecards (decor sets, VFX, landmarks... from `docs/art/lab/<name>/`). Army sweep: [army.md](%s).\n\n" % [
		Time.get_datetime_string_from_system(false, true), ArtLabReport.VERSION, rows.size(), older,
		out.trim_prefix(LAB_DIR + "/").path_join("army.md")]
	s += "**Order:** every FAIL first, then the largest estimated score gain per estimated minute. Per asset: every FAIL + its best other item. **gain** = quality points if that check reaches a clean PASS (lab_score.gd weights; sweep scores are `quick=1`, so R2 / B13 come from the army pass / the Perf Lab); **min** = estimated tech-artist minutes for that kind of fix (table at the end); a \"reads alike\" pair from the army pass counts +5. Fix recipes: the asset's `fixes.json` (task 1.A) when present. Owner: %s. Re-check = the single windowed run (writes `docs/art/lab/<name>/`; task 1.B adds `-Extra 'focus=<check ids>'` for a fast inner loop).\n\n" % OWNER
	s += "| # | asset | kingdom | status | item (check, value) | fix | gain | min | pts / min | owner | re-check |\n|---|---|---|---|---|---|---|---|---|---|---|\n"
	var i := 1
	for it: Dictionary in items:
		var rec := top_recipe(String(it.get("asset_out", "")), String(it["id"]), true)   # computed recipes only (values)
		if rec.begins_with(String(it["id"]) + ": ") and not rec.substr(rec.find(": ") + 2).left(40) in String(it["text"]):
			it["text"] = "%s **Recipe:** %s" % [_clip(String(it["text"]), 100), _clip(rec, 150)]
		else:
			it["text"] = _clip(String(it["text"]), 200)
		s += backlog_line(i, it) + "\n"
		i += 1
	s += "\n## Minutes per check (estimates, `tools/art_lab/lab_army.gd` MINUTES)\n\n"
	var keys: Array = MINUTES.keys()
	var parts: Array[String] = []
	for k: String in keys:
		parts.append("%s %d" % [k, int(MINUTES[k])])
	s += ", ".join(parts) + "; anything else 20.\n"
	return s
