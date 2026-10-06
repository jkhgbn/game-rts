extends RefCounted
## Playtest analyzer (docs/design/health-and-playtests.md, part B): turns one or many Playtest Recorder files
## (user://playtests/*.jsonl, scripts/core/playtest/playtest_recorder.gd) into docs/playtests/<name>.md + heatmap PNGs.
## Pure static functions: tests/test_playtest_recorder.gd calls `report()` directly; tools/playtest/analyze.gd is the
## command-line entry (tools\playtest\analyze.ps1).

const SECTIONS := ["## Summary", "## Pacing", "## Economy vs bot", "## Army composition", "## Heatmaps",
		"## Input (hotkeys vs clicks)", "## Hitches", "## Tuning suggestions", "## Replay"]
const EXPECTED_PATH := "res://tools/playtest/expected.json"
const HEAT_PX := 256
const FLOAT_CRYSTALS := 600
const SLOW_FACTOR := 2.0


## One recording: {path, name, header, samples, events, end, replay, bad_lines}.
static func load_recording(path: String) -> Dictionary:
	var rec := {"path": path, "name": path.get_file().get_basename(), "header": {}, "samples": [], "events": [],
			"end": {}, "replay": {}, "bad_lines": 0}
	if not FileAccess.file_exists(path):
		rec["bad_lines"] = -1
		return rec
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var s := line.strip_edges()
		if s == "":
			continue
		var j := JSON.new()
		if j.parse(s) != OK or not (j.data is Dictionary):
			rec["bad_lines"] = int(rec["bad_lines"]) + 1
			continue
		var d: Dictionary = j.data
		match String(d.get("k", "")):
			"header":
				rec["header"] = d
			"s":
				(rec["samples"] as Array).append(d)
			"ev":
				(rec["events"] as Array).append(d)
			"end":
				rec["end"] = d
			"replay":
				rec["replay"] = d
			_:
				rec["bad_lines"] = int(rec["bad_lines"]) + 1
	return rec


## Schema check of one recording: [] = valid, else the problems (used by the test and printed by the analyzer).
static func validate(rec: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	var h: Dictionary = rec["header"]
	for k in ["v", "game", "date", "mode", "sample_every", "retry"]:
		if not h.has(k):
			errs.append("header has no '%s'" % k)
	for s in rec["samples"]:
		for k in ["t", "wk", "army", "tier", "cam", "keys", "clicks"]:
			if not s.has(k):
				errs.append("sample at t=%s has no '%s'" % [s.get("t", "?"), k])
				break
	for e in rec["events"]:
		if not e.has("e") or not e.has("t"):
			errs.append("event without e / t: %s" % JSON.stringify(e).left(80))
	if (rec["end"] as Dictionary).is_empty():
		errs.append("no end line (game crashed or still running)")
	elif not String(rec["end"].get("outcome", "")) in ["win", "loss", "left"]:
		errs.append("end outcome '%s'" % rec["end"].get("outcome", ""))
	if int(rec["bad_lines"]) != 0:
		errs.append("%d unreadable lines" % int(rec["bad_lines"]))
	return errs


static func clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


## A JSON number as text ("250", not "250.0"); "-" when missing.
static func _n(v: Variant) -> String:
	if v == null:
		return "-"
	if (v is float or v is int) and is_equal_approx(float(v), roundf(float(v))):
		return str(int(v))
	return str(v)


static func _p(p: Variant) -> String:
	return "(%.0f, %.0f)" % [float(p[0]), float(p[1])] if p is Array and (p as Array).size() >= 2 else "(?)"


static func events_of(rec: Dictionary, kind: String) -> Array:
	return (rec["events"] as Array).filter(func(e: Dictionary) -> bool: return String(e.get("e", "")) == kind)


## Objective spans: [{id, start, end, state, dur, deaths, hero_deaths, idle, centroid}].
static func objective_spans(rec: Dictionary) -> Array:
	var spans := {}
	var order: Array[String] = []
	for e in events_of(rec, "objective"):
		var id := String(e.get("id", ""))
		var st := String(e.get("state", ""))
		if not spans.has(id):
			spans[id] = {"id": id, "start": 0.0, "end": -1.0, "state": "active"}
			order.append(id)
		if st == "active":
			spans[id]["start"] = float(e["t"])
		elif st in ["done", "failed"]:
			spans[id]["end"] = float(e["t"])
			spans[id]["state"] = st
	var end_t := float(rec["end"].get("t", 0.0))
	var out: Array = []
	for id in order:
		var sp: Dictionary = spans[id]
		var stop := float(sp["end"]) if float(sp["end"]) >= 0.0 else end_t
		sp["dur"] = maxf(stop - float(sp["start"]), 0.0)
		var deaths := 0
		var hero := 0
		var cx := 0.0
		var cz := 0.0
		for e in events_of(rec, "death"):
			var t := float(e["t"])
			if int(e.get("team", -1)) == 0 and t >= float(sp["start"]) and t <= stop:
				deaths += 1
				cx += float(e["p"][0])
				cz += float(e["p"][1])
				if bool(e.get("hero", false)):
					hero += 1
		var idle := 0.0
		for e in events_of(rec, "idle"):
			if float(e["t"]) >= float(sp["start"]) and float(e["t"]) <= stop:
				idle += float(e.get("dur", 0.0))
		sp["deaths"] = deaths
		sp["hero_deaths"] = hero
		sp["idle"] = idle
		sp["centroid"] = [cx / deaths, cz / deaths] if deaths > 0 else []
		if float(sp["end"]) < 0.0:
			sp["state"] = "unfinished"
		out.append(sp)
	return out


## Expected seconds per "<mode>/<objective>": tools/playtest/expected.json, else the median over the loaded
## recordings when the objective was finished in 2+ of them.
static func expected_times(recs: Array) -> Dictionary:
	var out := {}
	if FileAccess.file_exists(EXPECTED_PATH):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED_PATH))
		if j is Dictionary:
			for m in j:
				if j[m] is Dictionary:
					for o in j[m]:
						out["%s/%s" % [m, o]] = float(j[m][o])
	var seen := {}
	for r in recs:
		for sp in objective_spans(r):
			if sp["state"] == "done":
				var key := "%s/%s" % [r["header"].get("mode", ""), sp["id"]]
				if not seen.has(key):
					seen[key] = []
				seen[key].append(float(sp["dur"]))
	for key in seen:
		if not out.has(key) and (seen[key] as Array).size() >= 2:
			var a: Array = seen[key]
			a.sort()
			out[key] = float(a[a.size() / 2])
	return out


## Concrete tuning suggestions for one recording (strings, most important first).
static func suggestions(rec: Dictionary, expected: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var mode := String(rec["header"].get("mode", ""))
	for sp in objective_spans(rec):
		var key := "%s/%s" % [mode, sp["id"]]
		var where := (" at %s" % _p(sp["centroid"])) if not (sp["centroid"] as Array).is_empty() else ""
		if expected.has(key) and float(expected[key]) > 0.0 and float(sp["dur"]) >= SLOW_FACTOR * float(expected[key]):
			out.append("Objective `%s` took %.1fx the expected time (%s vs %s): %d deaths%s, %d hero deaths, %.0f s idle." % [
					sp["id"], float(sp["dur"]) / float(expected[key]), clock(sp["dur"]), clock(expected[key]), sp["deaths"], where,
					sp["hero_deaths"], sp["idle"]])
		elif not expected.has(key) and int(sp["deaths"]) >= 4:
			out.append("Objective `%s`: %d deaths%s in %s (no expected time yet: add it to tools/playtest/expected.json)." % [
					sp["id"], sp["deaths"], where, clock(sp["dur"])])
		if sp["state"] == "unfinished":
			out.append("Objective `%s` was never finished (%s spent on it, outcome %s)." % [sp["id"], clock(sp["dur"]),
					rec["end"].get("outcome", "?")])
	# Hero deaths clustered within 15 m.
	var hero_p: Array = []
	for e in events_of(rec, "death"):
		if bool(e.get("hero", false)) and int(e.get("team", -1)) == 0:
			hero_p.append(e["p"])
	for i in hero_p.size():
		var near := 0
		for j in hero_p.size():
			if Vector2(hero_p[i][0], hero_p[i][1]).distance_to(Vector2(hero_p[j][0], hero_p[j][1])) <= 15.0:
				near += 1
		if near >= 2:
			out.append("The hero died %d times within 15 m of %s: a danger zone (camp / tower / ambush) to soften or signpost." % [near, _p(hero_p[i])])
			break
	# Idle (waiting).
	var end_t := maxf(float(rec["end"].get("t", 1.0)), 1.0)
	var idle := events_of(rec, "idle")
	var idle_total := 0.0
	var longest := {}
	for e in idle:
		idle_total += float(e.get("dur", 0.0))
		if longest.is_empty() or float(e["dur"]) > float(longest["dur"]):
			longest = e
	if not longest.is_empty() and (idle_total / end_t > 0.15 or float(longest["dur"]) >= 30.0):
		out.append("The player waited %.0f s in total (%.0f %% of the match), longest %.0f s ending at %s: add a next-step cue or shorten that wait." % [
				idle_total, 100.0 * idle_total / end_t, float(longest["dur"]), clock(longest["t"])])
	# Floating crystals.
	var run := 0.0
	var worst := 0.0
	var worst_t := 0.0
	var prev_t := -1.0
	for s in rec["samples"]:
		if int(s.get("cr", 0)) >= FLOAT_CRYSTALS:
			run += float(s["t"]) - prev_t if prev_t >= 0.0 else 0.0
			if run > worst:
				worst = run
				worst_t = float(s["t"])
		else:
			run = 0.0
		prev_t = float(s["t"])
	if worst >= 30.0:
		out.append("Crystals stayed above %d for %.0f s (until %s): the player did not know what to spend on (build / train hint)." % [
				FLOAT_CRYSTALS, worst, clock(worst_t)])
	# Economy vs the bot (minutes 3-10).
	var pi := 0.0
	var bi := 0.0
	for s in rec["samples"]:
		if float(s["t"]) >= 180.0 and float(s["t"]) <= 600.0:
			pi += float(s.get("inc", 0))
			bi += float(s.get("e_inc", 0))
	if bi > 0.0 and pi < 0.75 * bi:
		out.append("Income minutes 3-10 was %.0f %% of the bot's: the player under-built workers (worker count curve in 'Economy vs bot')." % (100.0 * pi / bi))
	# Performance.
	var hitches := events_of(rec, "hitch")
	var ms: Array = rec["end"].get("ms", [])
	if hitches.size() >= 5 or (ms.size() >= 3 and float(ms[2]) > 33.0):
		var top: Dictionary = {}
		for h in hitches:
			if top.is_empty() or float(h["ms"]) > float(top["ms"]):
				top = h
		out.append("%d hitches > 50 ms (p99 frame %s ms)%s: run tools\\perf_lab\\run_perf_lab.ps1 on that scene state." % [
				int(rec["end"].get("hitches", hitches.size())), ms[2] if ms.size() >= 3 else "?",
				(", worst %.0f ms at %s with %d units, camera %s" % [top["ms"], clock(top["t"]), int(top.get("units", 0)), _p(top.get("cam", []))]) if not top.is_empty() else ""])
	# Input.
	var keys := int(rec["end"].get("keys", 0))
	var clicks := int(rec["end"].get("clicks", 0))
	if keys + clicks >= 100 and float(keys) / (keys + clicks) < 0.3:
		out.append("Only %.0f %% of actions were hotkeys: surface the hotkeys on the command card / in a tip." % (100.0 * keys / (keys + clicks)))
	if bool(rec["end"].get("rage_quit", false)):
		out.append("The player left at %s within a minute of a hero death or a lost fight: check the difficulty there." % clock(rec["end"].get("t", 0.0)))
	if int(rec["header"].get("retry", 0)) >= 2:
		out.append("Retry #%d of %s: look at what failed in the earlier runs." % [int(rec["header"]["retry"]), mode])
	return out


## Heatmap PNG of positions (Array of [x, z]) over the map (size [w, d], centred on 0). Returns the Image.
static func heatmap(points: Array, map_size: Array) -> Image:
	var img := Image.create(HEAT_PX, HEAT_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.09, 0.09, 0.1))
	var w := float(map_size[0]) if map_size.size() >= 2 and float(map_size[0]) > 0.0 else 120.0
	var d := float(map_size[1]) if map_size.size() >= 2 and float(map_size[1]) > 0.0 else 120.0
	var grid := Color(0.17, 0.17, 0.18)
	var step := 20.0
	var gx := -w / 2.0
	while gx <= w / 2.0:
		var px := int((gx + w / 2.0) / w * (HEAT_PX - 1))
		for y in HEAT_PX:
			img.set_pixel(px, y, grid)
		gx += step
	var gz := -d / 2.0
	while gz <= d / 2.0:
		var py := int((gz + d / 2.0) / d * (HEAT_PX - 1))
		for x in HEAT_PX:
			img.set_pixel(x, py, grid)
		gz += step
	var heat := PackedFloat32Array()
	heat.resize(HEAT_PX * HEAT_PX)
	var r := 7
	for p in points:
		if not (p is Array) or (p as Array).size() < 2:
			continue
		var cx := int((float(p[0]) + w / 2.0) / w * (HEAT_PX - 1))
		var cy := int((float(p[1]) + d / 2.0) / d * (HEAT_PX - 1))
		for y in range(maxi(cy - r * 3, 0), mini(cy + r * 3 + 1, HEAT_PX)):
			for x in range(maxi(cx - r * 3, 0), mini(cx + r * 3 + 1, HEAT_PX)):
				var dd := float((x - cx) * (x - cx) + (y - cy) * (y - cy))
				heat[y * HEAT_PX + x] += exp(-dd / (2.0 * r * r))
	var mx := 0.0
	for v in heat:
		mx = maxf(mx, v)
	if mx <= 0.0:
		return img
	for y in HEAT_PX:
		for x in HEAT_PX:
			var v := heat[y * HEAT_PX + x] / mx
			if v < 0.03:
				continue
			# Sequential ramp: dark orange -> orange -> pale yellow, alpha with the value.
			var c := Color(0.55, 0.16, 0.05).lerp(Color(0.92, 0.41, 0.2), minf(v * 2.0, 1.0))
			if v > 0.5:
				c = c.lerp(Color(1.0, 0.93, 0.6), (v - 0.5) * 2.0)
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, clampf(0.35 + v, 0.0, 1.0)))
	return img


## The full report. `out_dir` absolute (PNGs go next to the .md). Returns {md, files, errors}.
static func report(paths: Array, out_dir: String, name: String) -> Dictionary:
	var recs: Array = []
	var errors: Array[String] = []
	for p in paths:
		var r := load_recording(String(p))
		var v := validate(r)
		for e in v:
			errors.append("%s: %s" % [r["name"], e])
		if not (r["header"] as Dictionary).is_empty():
			recs.append(r)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var expected := expected_times(recs)
	var files: Array[String] = []
	var md: Array[String] = ["# Playtest report: %s" % name, ""]
	md.append("%d recording(s), made by `tools\\playtest\\analyze.ps1` (docs/design/health-and-playtests.md)." % recs.size())
	if not errors.is_empty():
		md.append("")
		md.append("Schema notes: " + "; ".join(errors.slice(0, 8)))
	md.append("")
	md.append("## Summary")
	md.append("")
	md.append("| Recording | Mode | Map | Kingdoms | Retry | Outcome | Length | Paused | Idle | Rage quit |")
	md.append("|---|---|---|---|---|---|---|---|---|---|")
	for r in recs:
		var h: Dictionary = r["header"]
		var e: Dictionary = r["end"]
		md.append("| %s | %s | %s | %s | %d | %s | %s | %.0f s | %.0f s | %s |" % [r["name"], h.get("mode", ""), h.get("map", "") if String(h.get("map", "")) != "" else "crown_hollow",
				" vs ".join(PackedStringArray(h.get("kingdoms", []))), int(h.get("retry", 0)), e.get("outcome", "(no end)"),
				clock(float(e.get("t", 0.0))), float(e.get("paused_s", 0.0)), float(e.get("idle_s", 0.0)), "yes" if bool(e.get("rage_quit", false)) else "no"])
	# Pacing
	md.append("")
	md.append("## Pacing")
	md.append("")
	for r in recs:
		var spans := objective_spans(r)
		md.append("**%s**" % r["name"])
		md.append("")
		if spans.is_empty():
			var marks: Array[String] = []
			for e in events_of(r, "tier"):
				if int(e.get("team", -1)) == 0:
					marks.append("tier %d at %s" % [int(e["tier"]), clock(e["t"])])
			for s in r["samples"]:
				var sup := 0
				for k in s.get("army", {}):
					sup += int(s["army"][k])
				if sup >= 10:
					marks.append("army 10 supply at %s" % clock(s["t"]))
					break
			var first_fight := events_of(r, "death").filter(func(e: Dictionary) -> bool: return int(e.get("team", -1)) <= 1)
			if not first_fight.is_empty():
				marks.append("first death at %s" % clock(first_fight[0]["t"]))
			md.append("No objectives (skirmish). Milestones: " + (", ".join(marks) if not marks.is_empty() else "none") + ".")
		else:
			md.append("| Objective | Start | Time spent | Expected | State | Deaths (hero) | Idle | Where the deaths were |")
			md.append("|---|---|---|---|---|---|---|---|")
			for sp in spans:
				var key := "%s/%s" % [r["header"].get("mode", ""), sp["id"]]
				md.append("| %s | %s | %s | %s | %s | %d (%d) | %.0f s | %s |" % [sp["id"], clock(sp["start"]), clock(sp["dur"]),
						clock(expected[key]) if expected.has(key) else "-", sp["state"], sp["deaths"], sp["hero_deaths"], sp["idle"],
						_p(sp["centroid"]) if not (sp["centroid"] as Array).is_empty() else "-"])
		var mev := events_of(r, "mission_event")
		if not mev.is_empty():
			md.append("")
			md.append("Mission events: " + ", ".join(PackedStringArray(mev.map(func(e: Dictionary) -> String: return "%s %s" % [e["id"], clock(e["t"])]))))
		md.append("")
	# Economy
	md.append("## Economy vs bot")
	md.append("")
	for r in recs:
		md.append("**%s** (one row per minute; inc = crystals gathered per minute)" % r["name"])
		md.append("")
		md.append("| Time | Crystals | Income | Workers | Tier | Bot crystals | Bot income | Bot workers | Bot tier | Army supply | Bot army |")
		md.append("|---|---|---|---|---|---|---|---|---|---|---|")
		var next_min := 0.0
		for s in r["samples"]:
			if float(s["t"]) + 0.01 < next_min:
				continue
			next_min = floorf(float(s["t"]) / 60.0) * 60.0 + 60.0
			var sup := 0
			for k in s.get("army", {}):
				sup += int(s["army"][k])
			md.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %d | %s |" % [clock(s["t"]), _n(s.get("cr")), _n(s.get("inc")),
					_n(s.get("wk")), _n(s.get("tier")), _n(s.get("e_cr")), _n(s.get("e_inc")), _n(s.get("e_wk")), _n(s.get("e_tier")),
					sup, _n(s.get("e_army"))])
		md.append("")
	# Army
	md.append("## Army composition")
	md.append("")
	for r in recs:
		md.append("**%s** (player supply by unit type, one row per minute)" % r["name"])
		md.append("")
		var next_min := 0.0
		var rows: Array[String] = []
		for s in r["samples"]:
			if float(s["t"]) + 0.01 < next_min:
				continue
			next_min = floorf(float(s["t"]) / 60.0) * 60.0 + 60.0
			var parts: Array[String] = []
			var army: Dictionary = s.get("army", {})
			var ks := army.keys()
			ks.sort_custom(func(a: Variant, b: Variant) -> bool: return int(army[a]) > int(army[b]))
			for k in ks:
				parts.append("%s %d" % [k, int(army[k])])
			rows.append("- %s: %s" % [clock(s["t"]), ", ".join(parts) if not parts.is_empty() else "(none)"])
		if rows.is_empty():
			rows.append("- no samples")
		md.append_array(rows)
		md.append("")
	# Heatmaps
	md.append("## Heatmaps")
	md.append("")
	var fights: Array = []
	var deaths: Array = []
	var size: Array = [120.0, 120.0]
	for r in recs:
		var ms: Array = r["header"].get("map_size", [])
		if ms.size() >= 2:
			size = ms
		for e in events_of(r, "death"):
			fights.append(e["p"])
			if int(e.get("team", -1)) == 0:
				deaths.append(e["p"])
	for pair in [["fights", fights, "every death of both sides"], ["deaths", deaths, "the player's own deaths"]]:
		var fn := "%s_%s.png" % [name, pair[0]]
		heatmap(pair[1], size).save_png(out_dir.path_join(fn))
		files.append(out_dir.path_join(fn))
		md.append("![%s](%s) %s: %d points (top-down, x right, z down, map %s x %s m, 20 m grid)." % [pair[0], fn, pair[2],
				(pair[1] as Array).size(), _n(size[0]), _n(size[1])])
		md.append("")
	# Input
	md.append("## Input (hotkeys vs clicks)")
	md.append("")
	md.append("| Recording | Keys | Clicks | Keys / min | Clicks / min | Hotkey share | Orders | Top orders |")
	md.append("|---|---|---|---|---|---|---|---|")
	for r in recs:
		var e: Dictionary = r["end"]
		var mins := maxf(float(e.get("t", 0.0)) / 60.0, 0.01)
		var k := int(e.get("keys", 0))
		var c := int(e.get("clicks", 0))
		var kinds := {}
		for ev in events_of(r, "cmd"):
			kinds[ev["c"]] = int(kinds.get(ev["c"], 0)) + 1
		var ks := kinds.keys()
		ks.sort_custom(func(a: Variant, b: Variant) -> bool: return int(kinds[a]) > int(kinds[b]))
		md.append("| %s | %d | %d | %.1f | %.1f | %s | %d | %s |" % [r["name"], k, c, k / mins, c / mins,
				("%.0f %%" % (100.0 * k / (k + c))) if k + c > 0 else "-", int(e.get("cmds", 0)),
				", ".join(PackedStringArray(ks.slice(0, 5).map(func(x: Variant) -> String: return "%s %d" % [x, kinds[x]])))])
	md.append("")
	# Hitches
	md.append("## Hitches")
	md.append("")
	md.append("| Recording | Time | Frame ms | Units | Camera |")
	md.append("|---|---|---|---|---|")
	var any_h := false
	for r in recs:
		var hs := events_of(r, "hitch")
		hs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ms"]) > float(b["ms"]))
		for h in hs.slice(0, 15):
			any_h = true
			md.append("| %s | %s | %.0f | %d | %s |" % [r["name"], clock(h["t"]), float(h["ms"]), int(h.get("units", 0)), _p(h.get("cam", []))])
		var ms: Array = r["end"].get("ms", [])
		if ms.size() >= 3:
			md.append("| %s | whole match | p50 %s / p95 %s / p99 %s | | %d hitches > 50 ms |" % [r["name"], ms[0], ms[1], ms[2], int(r["end"].get("hitches", 0))])
	if not any_h:
		md.append("| - | no hitch > 50 ms | | | |")
	md.append("")
	# Suggestions
	md.append("## Tuning suggestions")
	md.append("")
	var n_sug := 0
	for r in recs:
		for s in suggestions(r, expected):
			md.append("- **%s**: %s" % [r["name"], s])
			n_sug += 1
	if n_sug == 0:
		md.append("- Nothing stands out in these recordings.")
	md.append("")
	# Replay
	md.append("## Replay")
	md.append("")
	var any_r := false
	for r in recs:
		var file := String(r["replay"].get("file", ""))
		if file == "":
			continue
		any_r = true
		md.append("- **%s**: replay `%s` (seed %s). Verify / watch it with the Replay Lab: `tools\\replay_lab\\run_replay.ps1 -Path \"$env:APPDATA\\Godot\\app_userdata\\%s\\%s\"`" % [
				r["name"], file, r["replay"].get("seed", "?"), ProjectSettings.get_setting("application/config/name", "Four Wizards RTS"),
				file.trim_prefix("user://").replace("/", "\\")])
	if not any_r:
		md.append("- No command recording linked. The Replay Lab records commands when `ReplayHooks.auto_record` is on (dev); the playtest file then names its `.replay`.")
	md.append("")
	return {"md": "\n".join(md), "files": files, "errors": errors, "recordings": recs.size()}
