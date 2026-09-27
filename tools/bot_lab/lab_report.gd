extends SceneTree
## Bot Lab report (docs/plan/bot-lab.md): turns the JSON lines of tools/bot_lab/lab_match.gd (results.jsonl) into
## report.md + report.html (self-contained) in the same folder. Run by run_lab.ps1 at the end of a batch, or alone:
##   godot --headless --path <any project> -s tools/bot_lab/lab_report.gd --quit-after 600 -- \
##       --in=C:/runs/x/results.jsonl [--out=C:/runs/x] [--wall=812] [--parallel=4] [--title="Round 0"]
## Targets (docs/design/rush-balance.md 8): kingdom and pair win rate 45-55 %, median length 15:00-20:00, no winner
## at 24:00 <= 10 %, mirrors 40-60 % for the player side. Cells in the target band are green, in the section-8 pass
## band amber, outside red (small N: read the counts).
## Needs no game class: plain dictionaries only.

const KINGDOMS: Array[String] = ["fire", "shadow", "ice", "nature"]
const REASONS: Array[String] = ["kill", "concede", "early-score", "time-score", "stall", "cap", "error"]
const WIN_TARGET := Vector2(45.0, 55.0)
const PAIR_PASS := Vector2(33.0, 67.0)      ## rush-balance.md 8 at N = 12 per pair
const KINGDOM_PASS := Vector2(43.0, 57.0)
const LEN_TARGET := Vector2(900.0, 1200.0)  ## 15:00-20:00
const LEN_PASS := Vector2(810.0, 1290.0)    ## 13:30-21:30 per pair
const MIRROR_PASS := Vector2(40.0, 60.0)
const NO_WINNER_AT := 1440.0                ## 24:00

var rows: Array[Dictionary] = []
var bad_lines := 0
var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	var in_path := String(args.get("in", ""))
	if in_path == "" or not FileAccess.file_exists(in_path):
		push_error("LAB report: --in=<results.jsonl> missing (%s)" % in_path)
		quit(1)
		return
	var out_dir := String(args.get("out", in_path.get_base_dir()))
	var f := FileAccess.open(in_path, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var v: Variant = JSON.parse_string(line)
		if v is Dictionary:
			rows.append(v)
		else:
			bad_lines += 1
	f.close()
	var md := _markdown()
	var html := _html()
	_write(out_dir.path_join("report.md"), md)
	_write(out_dir.path_join("report.html"), html)
	print("LAB report: %d matches -> %s" % [rows.size(), out_dir.path_join("report.md")])
	quit(0)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("LAB report: can't write %s" % path)
		return
	f.store_string(text)
	f.close()


# ---------------------------------------------------------------- numbers

func _ok(r: Dictionary) -> bool:
	return not r.has("error") and String(r.get("end_reason", "error")) != "error"


func _valid() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in rows:
		if _ok(r):
			out.append(r)
	return out


## Wins of kingdom a vs kingdom b (a != b), both side orders: [wins, games].
func _pair_record(a: String, b: String) -> Vector2i:
	var w := 0
	var n := 0
	for r in _valid():
		var p := String(r["player"])
		var e := String(r["enemy"])
		if not ((p == a and e == b) or (p == b and e == a)):
			continue
		n += 1
		if String(r.get("winner", "none")) == a:
			w += 1
	return Vector2i(w, n)


## Mirror a:a: [player-side wins, games].
func _mirror_record(a: String) -> Vector2i:
	var w := 0
	var n := 0
	for r in _valid():
		if String(r["player"]) == a and String(r["enemy"]) == a:
			n += 1
			if String(r.get("winner_side", "none")) == "player":
				w += 1
	return Vector2i(w, n)


func _kingdom_record(k: String) -> Vector2i:
	var w := 0
	var n := 0
	for r in _valid():
		var p := String(r["player"])
		var e := String(r["enemy"])
		if p == e or (p != k and e != k):
			continue
		n += 1
		if String(r.get("winner", "none")) == k:
			w += 1
	return Vector2i(w, n)


func _lengths(filter: Callable) -> Array[float]:
	var out: Array[float] = []
	for r in _valid():
		if filter.call(r):
			out.append(float(r.get("end_time", 0.0)))
	out.sort()
	return out


static func _quantile(sorted: Array[float], q: float) -> float:
	if sorted.is_empty():
		return -1.0
	var i := clampf(q * float(sorted.size() - 1), 0.0, float(sorted.size() - 1))
	var lo := floori(i)
	var hi := ceili(i)
	return lerpf(sorted[lo], sorted[hi], i - float(lo))


static func _clock(s: float) -> String:
	if s < 0.0:
		return "-"
	var t := int(round(s))
	return "%d:%02d" % [t / 60, t % 60]


static func _pct(w: int, n: int) -> float:
	return 100.0 * float(w) / float(n) if n > 0 else -1.0


## "good" (target band), "pass" (section-8 pass band), "bad", "none" (no data).
static func _band(v: float, target: Vector2, pass_band: Vector2) -> String:
	if v < 0.0:
		return "none"
	if v >= target.x and v <= target.y:
		return "good"
	if v >= pass_band.x and v <= pass_band.y:
		return "pass"
	return "bad"


## ASCII tags (any viewer / console shows them); report.html turns them into cell colours.
static func _mark(band: String) -> String:
	return {"good": " [ok]", "pass": " [near]", "bad": " [OUT]", "none": ""}[band]


func _reason_counts(list: Array[Dictionary]) -> Dictionary:
	var c := {}
	for rs in REASONS:
		c[rs] = 0
	for r in list:
		var rs := String(r.get("end_reason", "error")) if _ok(r) else "error"
		c[rs] = int(c.get(rs, 0)) + 1
	return c


func _avg(list: Array[Dictionary], side_of: Callable, key: String) -> float:
	var total := 0.0
	var n := 0
	for r in list:
		var side := String(side_of.call(r))
		if side == "":
			continue
		var st: Dictionary = (r.get("stats", {}) as Dictionary).get(side, {})
		if st.has(key):
			total += float(st[key])
			n += 1
	return total / float(n) if n > 0 else -1.0


func _configs() -> String:
	var seen := {}
	for r in rows:
		var key := "difficulty %s, style %s, sim %s, tick %d, limit %s, early %s" % [r.get("difficulty", "?"),
				r.get("style", "?"), str(r.get("sim", "?")), int(r.get("tick", 0)), _clock(float(r.get("limit", 0))),
				"on" if r.get("early", false) else "off"]
		seen[key] = int(seen.get(key, 0)) + 1
	var parts: Array[String] = []
	for k: String in seen:
		parts.append("%s (%d)" % [k, seen[k]])
	return "; ".join(parts)


func _commits() -> String:
	var seen := {}
	for r in rows:
		var c := String(r.get("commit", ""))
		seen[c if c != "" else "?"] = true
	return ", ".join(PackedStringArray(seen.keys()))


func _perf() -> Dictionary:
	var real := 0.0
	var game := 0.0
	var cpu := 0.0
	var speeds: Array[float] = []
	for r in _valid():
		real += float(r.get("real_s", 0.0))
		game += float(r.get("end_time", 0.0))
		cpu += float(r.get("cpu_s", 0.0))
		speeds.append(float(r.get("speed", 0.0)))
	speeds.sort()
	var wall := String(args.get("wall", "")).to_float()
	var par := String(args.get("parallel", "")).to_int()
	return {"real": real, "game": game, "cpu": cpu, "speed": _quantile(speeds, 0.5), "wall": wall, "parallel": par,
			"per_hour": 3600.0 * float(_valid().size()) / wall if wall > 0.0 else -1.0,
			"avg_real": real / float(maxi(1, _valid().size()))}


# ---------------------------------------------------------------- markdown

func _markdown() -> String:
	var v := _valid()
	var L: Array[String] = []
	var title := String(args.get("title", "Bot Lab report"))
	L.append("# %s" % title)
	L.append("")
	L.append("%d matches (%d failed%s). Commit: %s. %s." % [rows.size(), rows.size() - v.size(),
			", %d unreadable lines" % bad_lines if bad_lines > 0 else "", _commits(), _configs()])
	L.append("Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), "
			+ "median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % "
			+ "player side. Small N: read the counts.")
	L.append("")
	L.append("## Win % matrix (row kingdom vs column kingdom, both side orders)")
	L.append("Cell: row win % (wins-games). Diagonal: mirror, player-side win %.")
	L.append("")
	L.append("| | " + " | ".join(KINGDOMS.map(func(k: String) -> String: return k.capitalize())) + " |")
	L.append("|---|" + "---|".repeat(KINGDOMS.size()))
	for a in KINGDOMS:
		var cells: Array[String] = []
		for b in KINGDOMS:
			var rec := _mirror_record(a) if a == b else _pair_record(a, b)
			var p := _pct(rec.x, rec.y)
			var band := _band(p, WIN_TARGET, MIRROR_PASS if a == b else PAIR_PASS)
			cells.append("-" if rec.y == 0 else "%d %% (%d-%d)%s" % [roundi(p), rec.x, rec.y, _mark(band)])
		L.append("| **%s** | %s |" % [a.capitalize(), " | ".join(cells)])
	L.append("")
	L.append("## Per kingdom (non-mirror games)")
	L.append("| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |")
	L.append("|---|---|---|---|---|---|---|---|")
	for k in KINGDOMS:
		var rec := _kingdom_record(k)
		var p := _pct(rec.x, rec.y)
		var mine := func(r: Dictionary) -> String:
			if String(r["player"]) == String(r["enemy"]):
				return ""
			return "player" if String(r["player"]) == k else ("enemy" if String(r["enemy"]) == k else "")
		var lens := _lengths(func(r: Dictionary) -> bool: return mine.call(r) != "")
		L.append("| %s | %s%s | %d-%d | %s | %s | %s | %s | %s |" % [k.capitalize(),
				"-" if p < 0.0 else "%d %%" % roundi(p), _mark(_band(p, WIN_TARGET, KINGDOM_PASS)), rec.x, rec.y,
				_clock(_quantile(lens, 0.5)), _num(_avg(v, mine, "peak_army_pop")), _num(_avg(v, mine, "peak_workers")),
				_num(_avg(v, mine, "gathered")), _num(_avg(v, mine, "attacks"))])
	L.append("")
	L.append("## Match length")
	var all_l := _lengths(func(_r: Dictionary) -> bool: return true)
	var med := _quantile(all_l, 0.5)
	L.append("Overall: median **%s**%s, p90 %s, min %s, max %s (n = %d)." % [_clock(med),
			_mark(_band(med, LEN_TARGET, LEN_TARGET)), _clock(_quantile(all_l, 0.9)),
			_clock(all_l[0] if not all_l.is_empty() else -1.0), _clock(all_l[-1] if not all_l.is_empty() else -1.0), all_l.size()])
	L.append("")
	L.append("| Pair (unordered) | Games | Median | p90 | Pair win % |")
	L.append("|---|---|---|---|---|")
	for i in KINGDOMS.size():
		for j in range(i, KINGDOMS.size()):
			var a := KINGDOMS[i]
			var b := KINGDOMS[j]
			var lens := _lengths(func(r: Dictionary) -> bool:
				return (String(r["player"]) == a and String(r["enemy"]) == b) or (String(r["player"]) == b and String(r["enemy"]) == a))
			if lens.is_empty():
				continue
			var m := _quantile(lens, 0.5)
			var rec := _mirror_record(a) if a == b else _pair_record(a, b)
			var wl := "%s %d %%" % [("player side" if a == b else a.capitalize()), roundi(_pct(rec.x, rec.y))]
			L.append("| %s vs %s | %d | %s%s | %s | %s |" % [a.capitalize(), b.capitalize(), lens.size(), _clock(m),
					_mark(_band(m, LEN_TARGET, LEN_PASS)), _clock(_quantile(lens, 0.9)), wl])
	L.append("")
	L.append("## How matches ended")
	var rc := _reason_counts(rows)
	L.append("| Reason | Matches | Share |")
	L.append("|---|---|---|")
	for rs in REASONS:
		if int(rc[rs]) > 0:
			L.append("| %s | %d | %d %% |" % [rs, rc[rs], roundi(_pct(int(rc[rs]), rows.size()))])
	var no_winner := 0
	for r in v:
		var real_end := ["kill", "concede"].has(String(r["end_reason"])) and float(r["end_time"]) <= NO_WINNER_AT
		if not real_end:
			no_winner += 1
	var nw := _pct(no_winner, v.size())
	L.append("")
	L.append("No real winner (kill / concede) by 24:00: **%d %%** (%d of %d)%s. Early-score and time-score ends count here."
			% [roundi(nw), no_winner, v.size(), _mark("good" if nw <= 10.0 else "bad") if nw >= 0.0 else ""])
	var calls := 0
	var agree := 0
	for r in v:
		var ec: Variant = r.get("early_call")
		if ec is Dictionary and not (ec as Dictionary).is_empty() and String(r["end_reason"]) != "early-score":
			calls += 1
			if int(ec.get("winner_team", -9)) == int(r.get("winner_team", -8)):
				agree += 1
	if calls > 0:
		L.append("Early-stop check (matches played past the would-be call): the call picked the final winner in %d of %d."
				% [agree, calls])
	L.append("")
	L.append("## Stalls")
	var flags := {}
	for r in v:
		for fl: Variant in r.get("stall_flags", []):
			flags[String(fl)] = int(flags.get(String(fl), 0)) + 1
	if flags.is_empty():
		L.append("No stall flag raised.")
	else:
		L.append("| Flag | Matches |")
		L.append("|---|---|")
		for fl: String in flags:
			L.append("| %s | %d |" % [fl, flags[fl]])
	L.append("")
	L.append("## Speed")
	var pf := _perf()
	L.append("Median sim speed x%.1f (game seconds per real second, one process). Sum of match real time %s for %s of game time; average %.0f s per match." % [
			float(pf["speed"]), _clock(float(pf["real"])), _clock(float(pf["game"])), float(pf["avg_real"])])
	if float(pf["cpu"]) > 0.0 and float(pf["game"]) > 0.0:
		L.append("CPU time %s in total: %.0f CPU s per 20 game minutes (the cost on a free core)." % [
				_clock(float(pf["cpu"])), float(pf["cpu"]) / float(pf["game"]) * 1200.0])
	if float(pf["wall"]) > 0.0:
		L.append("Batch wall clock %s with %d in parallel: **%.0f matches per hour**." % [_clock(float(pf["wall"])),
				int(pf["parallel"]), float(pf["per_hour"])])
	L.append("")
	L.append("## Matches")
	L.append("| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |")
	L.append("|---|---|---|---|---|---|---|---|---|---|")
	var sorted := rows.duplicate()
	sorted.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return [String(x.get("pair", "")), int(x.get("seed", 0))] < [String(y.get("pair", "")), int(y.get("seed", 0))])
	for r: Dictionary in sorted:
		if not _ok(r):
			L.append("| %s | %s | - | error: %s | - | - | - | - | - | %s |" % [r.get("pair", "?"), str(r.get("seed", "?")),
					String(r.get("error", "no result")), str(r.get("real_s", "-"))])
			continue
		var sc: Dictionary = r.get("score", {})
		var st: Dictionary = r.get("stats", {})
		L.append("| %s | %d | %s | %s | %s | %s-%s | %s-%s | %s-%s | %s | %.0f |" % [r["pair"], int(r["seed"]),
				String(r["winner"]).capitalize(), r["end_reason"], r["end_clock"],
				_num(float(sc.get("player", {}).get("total", -1))), _num(float(sc.get("enemy", {}).get("total", -1))),
				_num(float(st.get("player", {}).get("peak_army_pop", -1))), _num(float(st.get("enemy", {}).get("peak_army_pop", -1))),
				_num(float(st.get("player", {}).get("peak_workers", -1))), _num(float(st.get("enemy", {}).get("peak_workers", -1))),
				", ".join(PackedStringArray(r.get("stall_flags", []))), float(r.get("real_s", 0.0))])
	L.append("")
	return "\n".join(L)


static func _num(x: float) -> String:
	if x < 0.0:
		return "-"
	if x >= 100.0 or is_equal_approx(x, roundf(x)):
		return str(roundi(x))
	return str(snappedf(x, 0.1))


# ---------------------------------------------------------------- html

## The markdown rendered to a small self-contained HTML page (headings, paragraphs, tables; the [ok] / [near] / [OUT]
## tags become coloured cells).
func _html() -> String:
	var md := _markdown()
	var out: Array[String] = []
	out.append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">")
	out.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
	out.append("<title>%s</title>" % _esc(String(args.get("title", "Bot Lab report"))))
	out.append("<style>")
	out.append(":root{--bg:#f7f5f0;--fg:#1d1b18;--mute:#6b665d;--line:#d9d3c7;--good:#d7efd9;--pass:#f7e7bf;--bad:#f5d0cb;--head:#ece7dc}")
	out.append("@media (prefers-color-scheme: dark){:root{--bg:#171613;--fg:#ebe6dc;--mute:#a39d91;--line:#3a362f;--good:#1f4526;--pass:#4a3d17;--bad:#552520;--head:#24221d}}")
	out.append("body{background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,Segoe UI,sans-serif;margin:0 auto;max-width:1100px;padding:16px}")
	out.append("h1{font-size:22px}h2{font-size:17px;margin-top:28px;border-bottom:1px solid var(--line);padding-bottom:4px}")
	out.append("p{color:var(--fg)}.wrap{overflow-x:auto}table{border-collapse:collapse;margin:8px 0;font-variant-numeric:tabular-nums}")
	out.append("th,td{border:1px solid var(--line);padding:4px 8px;text-align:left;white-space:nowrap}th{background:var(--head)}")
	out.append("td.good{background:var(--good)}td.pass{background:var(--pass)}td.bad{background:var(--bad)}")
	out.append("</style></head><body>")
	var in_table := false
	var header_done := false
	for raw in md.split("\n"):
		var line := String(raw)
		if line.begins_with("|"):
			var cells := line.strip_edges().trim_prefix("|").trim_suffix("|").split("|")
			if not in_table:
				out.append("<div class=\"wrap\"><table>")
				in_table = true
				header_done = false
			if line.begins_with("|---"):
				header_done = true
				continue
			var tag := "td" if header_done else "th"
			var row := "<tr>"
			for c in cells:
				var text := String(c).strip_edges()
				var cls := ""
				if text.contains("[ok]"):
					cls = " class=\"good\""
				elif text.contains("[near]"):
					cls = " class=\"pass\""
				elif text.contains("[OUT]"):
					cls = " class=\"bad\""
				text = text.replace(" [ok]", "").replace(" [near]", "").replace(" [OUT]", "")
				row += "<%s%s>%s</%s>" % [tag, cls, _inline(text), tag]
			out.append(row + "</tr>")
			continue
		if in_table:
			out.append("</table></div>")
			in_table = false
		if line.begins_with("## "):
			out.append("<h2>%s</h2>" % _inline(line.substr(3)))
		elif line.begins_with("# "):
			out.append("<h1>%s</h1>" % _inline(line.substr(2)))
		elif line.strip_edges() != "":
			out.append("<p>%s</p>" % _inline(line))
	if in_table:
		out.append("</table></div>")
	out.append("</body></html>")
	return "\n".join(out)


static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


## Escapes and turns **bold** into <b>.
static func _inline(s: String) -> String:
	var e := _esc(s)
	var parts := e.split("**")
	var out := ""
	for i in parts.size():
		out += ("<b>%s</b>" % parts[i]) if i % 2 == 1 else parts[i]
	return out
