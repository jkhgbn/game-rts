class_name ArtLabCalibration
extends RefCounted
## Art Lab v3 calibration set (docs/plan/art-lab.md "Calibration", task 1.C): 12 known cases with expected score bands.
## 6 good finished assets + 6 planted-bad variants built IN MEMORY from real assets (calib_plant.gd; the real scenes are
## never edited or saved). The whole set runs as ONE v3 batch (ArtLabBatch.run_all: one Godot process, the stage built
## once) with quick=1 (no references / frame cost: B13 is noise on a busy PC) and log=0. Every scorecard lands in
## docs/art/lab/_calibration/<case>/, the summary in docs/art/lab/_calibration/calibration.md.
## tests/test_art_lab_calibration.gd runs it and FAILS when a rule change moves a case out of its band:
##   quality  [lo, hi]  measured over 2 windowed runs, widened by a margin (MARGIN)
##   result   allowed overall results
##   expect   {check id: allowed statuses}: the check must be there with one of them (the planted problem must show)
##   allow    {check id: allowed statuses}: WARN / FAIL tolerated on that check; any other WARN / FAIL in the scorecard
##            is a NEW alarm and fails the test (a false alarm on a good asset, or a planted case failing on the
##            wrong rule)
## Headless runs judge only the checks that ran (render checks come out SKIP) and no quality band.
## Change a band only with a reason in art-lab.md "Calibration" (the band IS the lab's contract).

const OUT_ROOT := "res://docs/art/lab/_calibration"
const VIRTUAL_DIR := "res://tools/art_lab/calibration/virtual/"
## Quality margin added around the 2-run measured range when the bands were set (points).
const MARGIN := 3.0

const SHADE := "res://art/units/shadow/shade.tscn"
const STEED := "res://art/units/mounts/dusk_steed/dusk_steed.tscn"
const AQUEDUCT := "res://art/environment/landmarks/aqueduct.tscn"
const GUN_VFX := "res://art/vfx/unit_fire_gun_vfx.gd"
const DEER := "res://art/units/neutral/critters/deer.tscn"
const DRAGON := "res://art/units/titans/frost_dragon/frost_dragon.tscn"

## The 12 cases. `plant` = calib_plant.gd mode applied to `scene` (planted-bad), "" = the real asset as it is.
## Bands set 2026-09-27 from two windowed batch runs on the laptop (lab v3 phase 1, 1.C thresholds), min - 3 / max + 3:
##   shade 98.1 / 98.0 (96.1 with the OC3 R5 flake: band 94), dusk_steed 97.7 / 97.1, aqueduct 98.2 / 98.2, fire_gun_vfx 100 / 100 (93.7 in a run where V6
##   flaked, OC2: band 90), deer 98.5 / 98.5, frost_dragon 97.9 / 98.0, green 81.9 / 84.8, glow40 91.9 / 91.8,
##   verts20k 94.3 / 94.3, float 90.5 / 90.6, permat 89.0 / 89.0, team 94.0 / 93.7.
## Open cases (allowed WARNs, docs/plan/art-lab.md "Calibration"): OC1 R5c, OC2 V6 musket_shot, OC3 Shade R5,
## OC4 A2 on critters (headless only).
const CASES: Array[Dictionary] = [
	# ---- good finished assets
	{"id": "shade", "scene": SHADE, "args": ["kind=unit", "kingdom=shadow"], "plant": "",
		"quality": [94.0, 100.0], "result": ["PASS", "WARN"], "expect": {"R3": ["PASS"], "R6": ["PASS"], "B9": ["PASS"], "R9": ["PASS"]},
		"allow": {"R5c": ["WARN"], "R5": ["WARN"]}},   # open cases OC1 (R5c noisy on a dark body: dL +2..+14 over 4 runs), OC3 (the eye glow sits at the bloom level: median 0 / 1 flips)
	{"id": "dusk_steed", "scene": STEED, "args": ["kind=mount", "kingdom=shadow"], "plant": "",
		"quality": [94.0, 100.0], "result": ["PASS", "WARN"], "expect": {"R3": ["PASS"], "R5": ["PASS"], "B4": ["PASS"]},
		"allow": {"R5c": ["WARN"]}},   # open case OC1: R5c ring is mostly bright grass around a dark head (dL -4..+0)
	{"id": "aqueduct", "scene": AQUEDUCT, "args": ["kind=landmark", "kingdom=neutral"], "plant": "",
		"quality": [95.0, 100.0], "result": ["PASS", "WARN"], "expect": {"R3": ["PASS"], "R9": ["PASS"]},
		"allow": {}},
	{"id": "fire_gun_vfx", "scene": GUN_VFX, "args": ["kind=vfx", "kingdom=fire", "ids=musket_shot,musket_breach"], "plant": "",
		"quality": [90.0, 100.0], "result": ["PASS", "WARN"], "expect": {"V2": ["PASS"], "V3": ["PASS"], "V4": ["PASS"]},
		"allow": {"V6": ["WARN"]}},   # open case OC2: V6 musket_shot 149 px in one run (>= 200 in the others)
	{"id": "deer", "scene": DEER, "args": ["kind=critter", "kingdom=neutral"], "plant": "",
		"quality": [95.0, 100.0], "result": ["PASS", "WARN"], "expect": {"R9": ["PASS"], "B4t": ["PASS"], "R3": ["PASS"]},
		"allow": {"A2": ["WARN"]}},   # OC4: headless only, critter death is 4.8 s by design (corpse hold), A2 wants <= 2 s
	{"id": "frost_dragon", "scene": DRAGON, "args": ["kind=titan", "kingdom=ice"], "plant": "",
		"quality": [94.5, 100.0], "result": ["PASS", "WARN"], "expect": {"R3": ["PASS"], "R6": ["PASS"], "B9": ["PASS"]},
		"allow": {}},
	# ---- planted-bad variants (built at run time from the real assets above)
	{"id": "plant_green_shade", "scene": SHADE, "args": ["kind=unit", "kingdom=shadow", "tier=soldier"], "plant": "green",
		"quality": [79.0, 88.0], "result": ["FAIL", "WARN"], "expect": {"R3": ["FAIL"]},
		"allow": {"R6": ["WARN", "FAIL"], "R6cb": ["WARN"], "R3t": ["WARN"], "R4": ["WARN"], "R4k": ["WARN"], "R5c": ["WARN"], "R5w": ["WARN"], "R5": ["WARN"], "A2": ["WARN"]}},   # one green material everywhere: no team cloth, no kit shader (A2 dissolve)
	{"id": "plant_glow40_frost_dragon", "scene": DRAGON, "args": ["kind=titan", "kingdom=ice", "tier=titan"], "plant": "glow40",
		"quality": [88.5, 95.0], "result": ["WARN", "FAIL"], "expect": {"R5": ["WARN"]},
		"allow": {"R5w": ["WARN"], "R5c": ["WARN"]}},
	{"id": "plant_verts20k_shade", "scene": SHADE, "args": ["kind=unit", "kingdom=shadow", "tier=soldier", "fail_fast=1"], "plant": "verts20k",
		"quality": [91.0, 97.5], "result": ["FAIL"], "expect": {"B4": ["FAIL"]},
		"allow": {}},
	{"id": "plant_float_deer", "scene": DEER, "args": ["kind=critter", "kingdom=neutral", "tier=deer"], "plant": "float",
		"quality": [86.5, 93.5], "result": ["FAIL"], "expect": {"R9": ["FAIL"]},
		"allow": {"A2": ["WARN"]}},   # OC4: headless only, critter death is 4.8 s by design (corpse hold), A2 wants <= 2 s
	{"id": "plant_permat_dusk_steed", "scene": STEED, "args": ["kind=mount", "kingdom=shadow", "tier=mount", "fail_fast=1"], "plant": "permat",
		"quality": [86.0, 92.0], "result": ["FAIL"], "expect": {"B9": ["FAIL"]},
		"allow": {}},
	{"id": "plant_team_dusk_steed", "scene": STEED, "args": ["kind=mount", "kingdom=shadow", "tier=mount"], "plant": "team",
		"quality": [90.5, 97.0], "result": ["WARN", "FAIL"], "expect": {"R6": ["WARN", "FAIL"], "R6cb": ["WARN"]},
		"allow": {"R5c": ["WARN"]}},   # OC1
]

static var _virtual: Array[PackedScene] = []   # keeps the in-memory variants alive (the resource cache is weak)


## The virtual scene path of a planted case.
## Where a run writes its scorecards (a headless run must not overwrite the windowed ones).
static func out_root(headless: bool) -> String:
	return OUT_ROOT + ("_headless" if headless else "")


static func virtual_path(c: Dictionary) -> String:
	return VIRTUAL_DIR + String(c["id"]) + ".tscn"


## Builds every planted variant in memory: the real scene instanced (not in the tree), a CalibPlant child added, packed
## into a new PackedScene that takes over a virtual res:// path (ResourceLoader.exists / load find it in the cache).
## Nothing is written to disk. Returns the errors ("" = all built).
static func register_plants(only: PackedStringArray = []) -> String:
	var errs: Array[String] = []
	for c: Dictionary in CASES:
		if String(c["plant"]) == "" or (not only.is_empty() and not String(c["id"]) in only):
			continue
		var vp := virtual_path(c)
		if ResourceLoader.has_cached(vp):
			continue
		var base := load(String(c["scene"])) as PackedScene
		if base == null:
			errs.append("%s: cannot load %s" % [c["id"], c["scene"]])
			continue
		var root := base.instantiate()
		var plant := ArtLabCalibPlant.new()
		plant.name = "CalibPlant"
		plant.mode = StringName(c["plant"])
		root.add_child(plant)
		plant.owner = root
		var ps := PackedScene.new()
		var err := ps.pack(root)
		root.free()
		if err != OK:
			errs.append("%s: pack error %d" % [c["id"], err])
			continue
		ps.take_over_path(vp)
		_virtual.append(ps)
		if not ResourceLoader.exists(vp):
			errs.append("%s: virtual scene not visible to ResourceLoader" % c["id"])
	return "; ".join(errs)


## Batch entries (ArtLabBatch format: scene= first, then the case args, name= the case id).
static func entries(only: PackedStringArray = []) -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	for c: Dictionary in CASES:
		if not only.is_empty() and not String(c["id"]) in only:
			continue
		var e := PackedStringArray(["scene=" + (virtual_path(c) if String(c["plant"]) != "" else String(c["scene"]))])
		for a: String in c["args"]:
			e.append(a)
		e.append("name=" + String(c["id"]))
		out.append(e)
	return out


static func case_of(id: String) -> Dictionary:
	for c: Dictionary in CASES:
		if String(c["id"]) == id:
			return c
	return {}


## The measured scorecard of a case (scorecard.json in <root>/<id>/; headless runs use out_root(true)): {result,
## quality, checks: {id: {status, value, score}}} or {} when missing.
static func measured(id: String, root: String = OUT_ROOT) -> Dictionary:
	var p := root.path_join(id).path_join("scorecard.json")
	if not FileAccess.file_exists(p):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not d is Dictionary:
		return {}
	var checks := {}
	for ch: Variant in (d as Dictionary).get("checks", []):
		if ch is Dictionary:
			var cid := String(ch.get("id", ""))
			# a check id can repeat (e.g. R9 on another pass): keep the worst status
			if checks.has(cid) and _rank(String(checks[cid]["status"])) >= _rank(String(ch.get("status", ""))):
				continue
			checks[cid] = {"status": String(ch.get("status", "")), "value": String(ch.get("value", "")),
				"score": float(ch.get("score", -1.0))}
	return {"result": String(d.get("result", "")), "quality": float(d.get("quality", -1.0)), "checks": checks,
		"seconds": float(d.get("seconds", 0.0)), "headless": bool(d.get("headless", false))}


## True for checks a headless run measures (budgets, health, hooks, geometry): they must be in every scorecard.
static func headless_check(cid: String) -> bool:
	return (cid.begins_with("B") and cid != "B13") or cid.begins_with("H") or cid in ["A1", "A2", "R8", "R9", "R10"]


static func _rank(st: String) -> int:
	return {"FAIL": 3, "WARN": 2, "PASS": 1, "INFO": 0, "SKIP": 0}.get(st, 0)


## Judges one case against its band. Returns the problems ("" list = in band). `headless`: render checks SKIP, so the
## quality band and the overall result are not judged (only the checks that ran).
static func judge(c: Dictionary, mes: Dictionary, headless: bool) -> Array[String]:
	var out: Array[String] = []
	if mes.is_empty():
		out.append("no scorecard")
		return out
	var checks: Dictionary = mes["checks"]
	if not headless:
		var q := float(mes["quality"])
		var band: Array = c["quality"]
		if q < float(band[0]) or q > float(band[1]):
			out.append("quality %.1f outside [%.0f, %.0f]" % [q, float(band[0]), float(band[1])])
		if not String(mes["result"]) in (c["result"] as Array):
			out.append("result %s not in %s" % [mes["result"], c["result"]])
	var expect: Dictionary = c["expect"]
	for cid: String in expect:
		if not checks.has(cid):
			if not headless or headless_check(cid):
				out.append("%s missing" % cid)
			continue
		var st := String(checks[cid]["status"])
		if st == "SKIP" and headless:
			continue
		if not st in (expect[cid] as Array):
			out.append("%s %s (expected %s): %s" % [cid, st, "/".join(expect[cid]), String(checks[cid]["value"]).left(90)])
	var allow: Dictionary = c["allow"]
	for cid2: String in checks:
		var st2 := String(checks[cid2]["status"])
		if st2 != "WARN" and st2 != "FAIL":
			continue
		if expect.has(cid2) or (allow.has(cid2) and st2 in (allow[cid2] as Array)):
			continue
		out.append("new %s %s: %s" % [st2, cid2, String(checks[cid2]["value"]).left(90)])
	return out


## Markdown summary of a calibration run (docs/art/lab/_calibration/calibration.md).
static func summary_md(rows: Array[Dictionary], total_s: float, headless: bool) -> String:
	var md := "# Art Lab calibration run\n\n%s, lab v%s, %s, %d cases in %.0f s. Bands: tools/art_lab/calibration/calibration.gd; manual: docs/plan/art-lab.md \"Calibration\".\n\n" % [
		Time.get_datetime_string_from_system(false, true), ArtLabReport.VERSION, "headless" if headless else "windowed",
		rows.size(), total_s]
	md += "| case | plant | result | quality | band | WARN / FAIL | verdict |\n|---|---|---|---|---|---|---|\n"
	for r: Dictionary in rows:
		md += "| %s | %s | %s | %.1f | %s | %s | %s |\n" % [r["id"], r["plant"] if String(r["plant"]) != "" else "-", r["result"],
			float(r["quality"]), r["band"], r["alarms"], "in band" if (r["problems"] as Array).is_empty() else "OUT: " + "; ".join(r["problems"])]
	return md
