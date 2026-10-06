extends RefCounted
## Game Health Dashboard: writes docs/health/latest.md and the self-contained docs/health/latest.html (inline CSS +
## SVG, no external files, light and dark) from a HealthCore.compute() result.

const Core := preload("res://tools/health/health_core.gd")

const STATUS_TEXT := {"good": "Good", "warn": "Watch", "bad": "Poor", "none": "No data"}


static func fmt(s: float) -> String:
	return "no data" if s < 0.0 else "%.1f" % s


static func signed(d: float) -> String:
	return ("+%.1f" % d) if d >= 0.0 else ("%.1f" % d)


static func markdown(res: Dictionary, when: String, commit: String) -> String:
	var md: Array[String] = []
	var tr: Dictionary = res["trend"]
	md.append("# Game Health: %s / 100" % fmt(float(res["score"])))
	md.append("")
	md.append("%s, commit `%s`. Made by `tools\\health\\run_health.ps1` from the labs' latest outputs (nothing re-run). " % [when, commit]
			+ "Coverage %d %% of the weight (areas with no data are left out). Method: docs/design/health-and-playtests.md." % roundi(float(res["coverage"]) * 100.0))
	md.append("")
	if int(tr["runs"]) > 0 and float(tr["prev_mean"]) >= 0.0:
		md.append("**Trend:** %s vs the mean of the last %d runs (%s); previous run %s." % [signed(float(tr["delta"])), int(tr["runs"]),
				fmt(float(tr["prev_mean"])), fmt(float(tr["last"]))])
	else:
		md.append("**Trend:** first run (no history yet).")
	md.append("")
	md.append("## Top 3 problems to fix next")
	md.append("")
	md.append("| # | Problem | Area | Costs (health pts) | Evidence | Owner | Re-check / fix |")
	md.append("|---|---|---|---|---|---|---|")
	var i := 1
	for p in res["top3"]:
		md.append("| %d | %s | %s | %.1f | %s | %s | %s |" % [i, _cell(p["text"]), p["area_title"], float(p["impact"]),
				_cell(p.get("evidence", "")), _cell(p.get("owner", "")), _cell(p.get("fix", ""))])
		i += 1
	if (res["top3"] as Array).is_empty():
		md.append("| - | nothing measurable to fix | | | | | |")
	md.append("")
	md.append("## Areas")
	md.append("")
	md.append("| Area | Weight | Score | Status | vs last runs |")
	md.append("|---|---|---|---|---|")
	for aid in Core.area_ids():
		var a: Dictionary = res["areas"][aid]
		var d: Variant = (tr["areas"] as Dictionary).get(aid, null)
		md.append("| %s | %d | %s | %s | %s |" % [a["title"], int(a["weight"]), fmt(float(a["score"])), STATUS_TEXT[a["status"]],
				signed(float(d)) if d != null else "-"])
	md.append("")
	md.append("## Components (the evidence)")
	md.append("")
	md.append("| Area | Component | Score | Weight | Evidence | Source | Age (days) |")
	md.append("|---|---|---|---|---|---|---|")
	for aid in Core.area_ids():
		for c in res["areas"][aid]["components"]:
			md.append("| %s | %s | %s | %s | %s | `%s` | %s |" % [res["areas"][aid]["title"], _cell(c["label"]), fmt(float(c["score"])),
					c["weight"], _cell(c["evidence"]), c.get("source", ""), "-" if float(c.get("age_days", -1)) < 0.0 else str(c["age_days"])])
	md.append("")
	md.append("## Next problems (after the top 3)")
	md.append("")
	var k := 0
	for p in res["problems"]:
		if (res["top3"] as Array).has(p):
			continue
		k += 1
		if k > 12:
			break
		md.append("- %.2f pts, %s: %s (%s)" % [float(p["impact"]), p["area_title"], p["text"], p.get("owner", "")])
	md.append("")
	md.append("Weights: " + ", ".join(PackedStringArray(Core.AREAS.map(func(a: Array) -> String: return "%s %d" % [a[1], int(a[2])]))) + ".")
	md.append("")
	return "\n".join(md)


static func _cell(v: Variant) -> String:
	return String(str(v)).replace("|", "/").replace("\n", " ")


static func esc(v: Variant) -> String:
	return String(str(v)).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")


const CSS := """
:root{--page:#f9f9f7;--surface:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--muted:#6f6d68;--grid:#e1e0d9;--axis:#c3c2b7;
--series:#2a78d6;--track:#f0efec;--good:#0ca30c;--warn:#fab219;--bad:#d03b3b;--ring:rgba(11,11,11,.10);--up:#006300;--down:#b42626}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--page:#0d0d0d;--surface:#1a1a19;--ink:#fff;--ink2:#c3c2b7;
--muted:#9a988f;--grid:#2c2c2a;--axis:#383835;--series:#3987e5;--track:#262624;--ring:rgba(255,255,255,.10);--up:#0ca30c;--down:#e66767}}
:root[data-theme="dark"]{--page:#0d0d0d;--surface:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--muted:#9a988f;--grid:#2c2c2a;--axis:#383835;
--series:#3987e5;--track:#262624;--ring:rgba(255,255,255,.10);--up:#0ca30c;--down:#e66767}
*{box-sizing:border-box}body{margin:0;background:var(--page);color:var(--ink);font:15px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:1080px;margin:0 auto;padding:24px 16px 48px}h1{font-size:22px;margin:0 0 4px}h2{font-size:17px;margin:28px 0 10px}
.sub{color:var(--ink2);font-size:13px}.card{background:var(--surface);border:1px solid var(--ring);border-radius:10px;padding:16px}
.hero{display:flex;flex-wrap:wrap;gap:16px;align-items:stretch;margin-top:16px}.hero .card{flex:1 1 220px}
.big{font-size:56px;font-weight:650;line-height:1}.big small{font-size:18px;color:var(--ink2);font-weight:400}
.chip{display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink2)}.dot{width:10px;height:10px;border-radius:50%;display:inline-block}
.good{background:var(--good)}.warn{background:var(--warn)}.bad{background:var(--bad)}.none{background:var(--axis)}
.up{color:var(--up)}.down{color:var(--down)}.flat{color:var(--ink2)}
.bars{display:grid;grid-template-columns:minmax(120px,190px) 1fr 64px 90px 70px;gap:8px 12px;align-items:center}
.track{height:14px;background:var(--track);border-radius:4px;position:relative}.fill{height:14px;background:var(--series);border-radius:0 4px 4px 0}
.num{font-variant-numeric:tabular-nums;text-align:right}.lbl{font-size:14px}.w{color:var(--muted);font-size:12px}
.probs{display:grid;gap:12px}.prob{display:grid;grid-template-columns:36px 1fr;gap:12px}.rank{font-size:24px;font-weight:650;color:var(--ink2)}
.prob p{margin:4px 0;color:var(--ink2);font-size:13px}.prob b{font-size:15px}code{font-size:12px;background:var(--track);padding:1px 4px;border-radius:4px;word-break:break-all}
table{border-collapse:collapse;width:100%;font-size:13px}th,td{text-align:left;padding:6px 8px;border-bottom:1px solid var(--grid);vertical-align:top}
th{color:var(--ink2);font-weight:600}td.n{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
.scroll{overflow-x:auto}svg text{fill:var(--muted);font-size:11px}
@media (max-width:640px){.bars{grid-template-columns:110px 1fr 48px}.bars .hide-s{display:none}.big{font-size:44px}}
"""


static func html(res: Dictionary, history: Array, when: String, commit: String) -> String:
	var h: Array[String] = []
	var tr: Dictionary = res["trend"]
	var score := float(res["score"])
	var st := Core.status_of(score)
	h.append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">")
	h.append("<title>Game Health</title><style>%s</style></head><body><main>" % CSS)
	h.append("<h1>Four Wizards: Game Health</h1><div class=\"sub\">%s, commit <code>%s</code>. From the labs' latest outputs (nothing re-run). Coverage %d %% of the weight.</div>" % [
			esc(when), esc(commit), roundi(float(res["coverage"]) * 100.0)])
	# Hero
	var dtxt := "first run"
	var dcls := "flat"
	if int(tr["runs"]) > 0 and float(tr["prev_mean"]) >= 0.0:
		dtxt = "%s vs the last %d runs (mean %s)" % [signed(float(tr["delta"])), int(tr["runs"]), fmt(float(tr["prev_mean"]))]
		dcls = String(tr["arrow"])
	h.append("<div class=\"hero\"><div class=\"card\"><div class=\"sub\">Health score</div><div class=\"big\">%s<small> / 100</small></div>" % fmt(score))
	h.append("<div class=\"chip\"><span class=\"dot %s\"></span>%s</div> <div class=\"sub %s\">%s</div></div>" % [st, STATUS_TEXT[st], dcls, esc(dtxt)])
	h.append("<div class=\"card\" style=\"flex:2 1 380px\"><div class=\"sub\">Health score, last runs</div>%s</div></div>" % trend_svg(history, score))
	# Top 3
	h.append("<h2>Top 3 problems to fix next</h2><div class=\"probs\">")
	var i := 1
	for p in res["top3"]:
		h.append("<div class=\"card prob\"><div class=\"rank\">%d</div><div><b>%s</b><p>%s, costs %.1f health points. Owner: %s</p><p>Evidence: %s</p><p>Re-check / fix: <code>%s</code></p></div></div>" % [
				i, esc(p["text"]), esc(p["area_title"]), float(p["impact"]), esc(p.get("owner", "")), esc(p.get("evidence", "")), esc(p.get("fix", ""))])
		i += 1
	if (res["top3"] as Array).is_empty():
		h.append("<div class=\"card\">Nothing measurable to fix.</div>")
	h.append("</div>")
	# Areas
	h.append("<h2>Areas</h2><div class=\"card\"><div class=\"bars\">")
	h.append("<div class=\"w\">Area (weight)</div><div class=\"w\">Score 0-100</div><div class=\"w num\">Score</div><div class=\"w hide-s\">Status</div><div class=\"w hide-s num\">vs last</div>")
	for aid in Core.area_ids():
		var a: Dictionary = res["areas"][aid]
		var s := float(a["score"])
		var d: Variant = (tr["areas"] as Dictionary).get(aid, null)
		var dc := "flat" if d == null else Core.arrow(float(d))
		h.append("<div class=\"lbl\">%s <span class=\"w\">(%d)</span></div>" % [esc(a["title"]), int(a["weight"])])
		h.append("<div class=\"track\" title=\"%s: %s\"><div class=\"fill\" style=\"width:%.1f%%\"></div></div>" % [esc(a["title"]), fmt(s), maxf(s, 0.0)])
		h.append("<div class=\"num\">%s</div><div class=\"chip hide-s\"><span class=\"dot %s\"></span>%s</div><div class=\"num hide-s %s\">%s</div>" % [
				fmt(s), a["status"], STATUS_TEXT[a["status"]], dc, "-" if d == null else signed(float(d))])
	h.append("</div></div>")
	# Components
	h.append("<h2>Components (the evidence)</h2><div class=\"card scroll\"><table><tr><th>Area</th><th>Component</th><th>Score</th><th>Weight</th><th>Evidence</th><th>Source</th><th>Age (d)</th></tr>")
	for aid in Core.area_ids():
		for c in res["areas"][aid]["components"]:
			h.append("<tr><td>%s</td><td>%s</td><td class=\"n\">%s</td><td class=\"n\">%s</td><td>%s</td><td><code>%s</code></td><td class=\"n\">%s</td></tr>" % [
					esc(res["areas"][aid]["title"]), esc(c["label"]), fmt(float(c["score"])), c["weight"], esc(c["evidence"]),
					esc(c.get("source", "")), "-" if float(c.get("age_days", -1)) < 0.0 else str(c["age_days"])])
	h.append("</table></div>")
	h.append("<p class=\"sub\">Health = weighted mean of the areas with data (%s). Area = weighted mean of its components. A problem's cost = the health points its component loses, split over that component's problems. Method: docs/design/health-and-playtests.md.</p>" % esc(
			", ".join(PackedStringArray(Core.AREAS.map(func(a: Array) -> String: return "%s %d" % [a[1], int(a[2])])))))
	h.append("</main></body></html>")
	return "\n".join(h)


## Line chart of the health score over the history (+ this run), y 0-100, hover = native tooltip per point.
static func trend_svg(history: Array, current: float) -> String:
	var pts: Array = []
	for r in history.slice(maxi(history.size() - 29, 0)):
		pts.append([String(r.get("time", "")), float(r.get("score", -1.0))])
	pts.append(["this run", current])
	var w := 600.0
	var hgt := 170.0
	var l := 34.0
	var r_ := 12.0
	var t := 10.0
	var b := 22.0
	var s: Array[String] = ["<svg viewBox=\"0 0 %d %d\" width=\"100%%\" role=\"img\" aria-label=\"Health score over the last runs\">" % [int(w), int(hgt)]]
	for gy in [0, 25, 50, 75, 100]:
		var y := t + (hgt - t - b) * (1.0 - float(gy) / 100.0)
		s.append("<line x1=\"%.1f\" x2=\"%.1f\" y1=\"%.1f\" y2=\"%.1f\" stroke=\"var(--grid)\" stroke-width=\"1\"/><text x=\"%.1f\" y=\"%.1f\" text-anchor=\"end\">%d</text>" % [
				l, w - r_, y, y, l - 6, y + 4, int(gy)])
	var n := pts.size()
	var poly: Array[String] = []
	var dots: Array[String] = []
	for i in n:
		var v := float(pts[i][1])
		if v < 0.0:
			continue
		var x := l + (w - l - r_) * (0.5 if n == 1 else float(i) / (n - 1))
		var y := t + (hgt - t - b) * (1.0 - v / 100.0)
		poly.append("%.1f,%.1f" % [x, y])
		dots.append("<g><circle cx=\"%.1f\" cy=\"%.1f\" r=\"10\" fill=\"transparent\"/><circle cx=\"%.1f\" cy=\"%.1f\" r=\"4\" fill=\"var(--series)\" stroke=\"var(--surface)\" stroke-width=\"2\"/><title>%s: %.1f</title></g>" % [
				x, y, x, y, esc(pts[i][0]), v])
	if poly.size() > 1:
		s.append("<polyline points=\"%s\" fill=\"none\" stroke=\"var(--series)\" stroke-width=\"2\" stroke-linejoin=\"round\"/>" % " ".join(poly))
	s.append_array(dots)
	s.append("<text x=\"%.1f\" y=\"%.1f\">%s</text><text x=\"%.1f\" y=\"%.1f\" text-anchor=\"end\">this run</text>" % [
			l, hgt - 6, esc(String(pts[0][0]).left(16)) if n > 1 else "", w - r_, hgt - 6])
	s.append("</svg>")
	return "".join(s)
