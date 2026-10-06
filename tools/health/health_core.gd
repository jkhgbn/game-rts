extends RefCounted
## Game Health Dashboard: the score math (docs/design/health-and-playtests.md). Pure functions on plain
## Dictionaries, so tests/test_health.gd can feed synthetic inputs. No file access here (health_inputs.gd reads the
## labs, health_report.gd writes the pages).
##
## A COMPONENT is one measured thing from one lab output:
##   {id, area, label, score (0-100, or -1 = no data), weight (> 0), evidence, source (file), age_days (-1 unknown),
##    problems: [{text, evidence, owner, fix, share (0-1 of this component's gap; default equal split)}]}
## AREA score  = weighted mean of its components that have data (-1 = no data).
## HEALTH score = weighted mean of the areas that have data (AREAS weights; the missing areas' weight is left out
##                and reported as `coverage`).
## A problem's IMPACT = the health points it costs = area_weight / present_weight x component_weight /
##                area_present_component_weight x (100 - component score) x share. Top 3 = highest impact, one per
##                area first (so one weak lab cannot fill the list), then the next highest.

## [id, title, weight]; weights sum to 100.
const AREAS: Array = [
	["stability", "Stability", 20.0],
	["performance", "Performance", 15.0],
	["balance", "Balance", 15.0],
	["maps", "Maps", 10.0],
	["art", "Art", 10.0],
	["ui", "UI/UX", 10.0],
	["data", "Data", 5.0],
	["content", "Content completeness", 15.0],
]
const TREND_RUNS := 5
const GOOD := 85.0
const WARN := 65.0


static func area_ids() -> Array[String]:
	var out: Array[String] = []
	for a in AREAS:
		out.append(String(a[0]))
	return out


static func area_title(id: String) -> String:
	for a in AREAS:
		if String(a[0]) == id:
			return String(a[1])
	return id


static func area_weight(id: String) -> float:
	for a in AREAS:
		if String(a[0]) == id:
			return float(a[2])
	return 0.0


## "good" / "warn" / "bad" / "none".
static func status_of(score: float) -> String:
	if score < 0.0:
		return "none"
	if score >= GOOD:
		return "good"
	if score >= WARN:
		return "warn"
	return "bad"


## A component Dictionary with defaults (the inputs reader and the tests build them with this).
static func component(id: String, area: String, label: String, score: float, weight := 1.0, evidence := "",
		source := "", problems: Array = [], age_days := -1.0) -> Dictionary:
	return {"id": id, "area": area, "label": label, "score": clampf(score, 0.0, 100.0) if score >= 0.0 else -1.0,
			"weight": maxf(weight, 0.0001), "evidence": evidence, "source": source, "problems": problems,
			"age_days": age_days}


static func problem(text: String, evidence := "", owner := "", fix := "", share := -1.0) -> Dictionary:
	return {"text": text, "evidence": evidence, "owner": owner, "fix": fix, "share": share}


## The whole computation. `history` = earlier rows of docs/health/history.jsonl (oldest first).
## Returns {score, coverage, areas: {id: {title, weight, score, status, components}}, problems (all, by impact),
## top3, trend}.
static func compute(components: Array, history: Array = []) -> Dictionary:
	var areas := {}
	for a in AREAS:
		areas[String(a[0])] = {"title": String(a[1]), "weight": float(a[2]), "score": -1.0, "status": "none",
				"components": []}
	for c in components:
		var aid := String(c.get("area", ""))
		if areas.has(aid):
			(areas[aid]["components"] as Array).append(c)
	var present_w := 0.0
	var total := 0.0
	for aid in areas:
		var s := area_score(areas[aid]["components"])
		areas[aid]["score"] = s
		areas[aid]["status"] = status_of(s)
		if s >= 0.0:
			present_w += float(areas[aid]["weight"])
			total += s * float(areas[aid]["weight"])
	var score := total / present_w if present_w > 0.0 else -1.0
	var all_w := 0.0
	for a in AREAS:
		all_w += float(a[2])
	var probs := rank_problems(areas, present_w)
	var res := {"score": snappedf(score, 0.1) if score >= 0.0 else -1.0, "coverage": present_w / all_w,
			"areas": areas, "problems": probs, "top3": top_problems(probs, 3)}
	res["trend"] = trend(res, history)
	return res


static func area_score(comps: Array) -> float:
	var w := 0.0
	var t := 0.0
	for c in comps:
		var s := float(c.get("score", -1.0))
		if s < 0.0:
			continue
		w += float(c.get("weight", 1.0))
		t += s * float(c.get("weight", 1.0))
	return t / w if w > 0.0 else -1.0


## Every problem of every component with its impact (health points), highest first.
static func rank_problems(areas: Dictionary, present_w: float) -> Array:
	var out: Array = []
	if present_w <= 0.0:
		return out
	for aid in areas:
		var comps: Array = areas[aid]["components"]
		var cw := 0.0
		for c in comps:
			if float(c.get("score", -1.0)) >= 0.0:
				cw += float(c.get("weight", 1.0))
		if cw <= 0.0:
			continue
		for c in comps:
			var s := float(c.get("score", -1.0))
			if s < 0.0:
				continue
			var gap := float(areas[aid]["weight"]) / present_w * float(c.get("weight", 1.0)) / cw * (100.0 - s)
			var ps: Array = c.get("problems", [])
			if ps.is_empty() or gap <= 0.0:
				continue
			for p in ps:
				var share := float(p.get("share", -1.0))
				if share < 0.0:
					share = 1.0 / float(ps.size())
				var row: Dictionary = (p as Dictionary).duplicate()
				row["impact"] = snappedf(gap * share, 0.01)
				row["area"] = String(aid)
				row["area_title"] = String(areas[aid]["title"])
				row["component"] = String(c.get("id", ""))
				row["component_score"] = s
				if String(row.get("owner", "")) == "":
					row["owner"] = String(aid)
				out.append(row)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["impact"]), float(b["impact"])):
			return float(a["impact"]) > float(b["impact"])
		return area_weight(String(a["area"])) > area_weight(String(b["area"])))
	return out


## The `n` problems to fix next: the highest impact per area first, then the next highest overall.
static func top_problems(ranked: Array, n: int) -> Array:
	var out: Array = []
	var used_areas := {}
	for p in ranked:
		if out.size() >= n:
			break
		if used_areas.has(p["area"]) or float(p["impact"]) <= 0.0:
			continue
		used_areas[p["area"]] = true
		out.append(p)
	for p in ranked:
		if out.size() >= n:
			break
		if not out.has(p) and float(p["impact"]) > 0.0:
			out.append(p)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["impact"]) > float(b["impact"]))
	return out


## Versus the last TREND_RUNS rows of the history: {runs, prev_mean, delta, last, arrow, areas: {id: delta}}.
static func trend(res: Dictionary, history: Array) -> Dictionary:
	var rows: Array = history.slice(maxi(history.size() - TREND_RUNS, 0))
	var out := {"runs": rows.size(), "prev_mean": -1.0, "delta": 0.0, "last": -1.0, "arrow": "new", "areas": {},
			"series": []}
	for r in rows:
		(out["series"] as Array).append(float(r.get("score", -1.0)))
	if rows.is_empty() or float(res.get("score", -1.0)) < 0.0:
		return out
	var t := 0.0
	var n := 0
	for r in rows:
		if float(r.get("score", -1.0)) >= 0.0:
			t += float(r["score"])
			n += 1
	if n == 0:
		return out
	out["prev_mean"] = snappedf(t / n, 0.1)
	out["last"] = float(rows[-1].get("score", -1.0))
	out["delta"] = snappedf(float(res["score"]) - t / n, 0.1)
	out["arrow"] = arrow(float(out["delta"]))
	for aid in res["areas"]:
		var cur := float(res["areas"][aid]["score"])
		var at := 0.0
		var an := 0
		for r in rows:
			var v := float((r.get("areas", {}) as Dictionary).get(aid, -1.0))
			if v >= 0.0:
				at += v
				an += 1
		if cur >= 0.0 and an > 0:
			out["areas"][aid] = snappedf(cur - at / an, 0.1)
	return out


static func arrow(delta: float) -> String:
	if delta >= 1.0:
		return "up"
	if delta <= -1.0:
		return "down"
	return "flat"


## The history row of a result (docs/health/history.jsonl).
static func history_row(res: Dictionary, when: String, commit: String) -> Dictionary:
	var areas := {}
	for aid in res["areas"]:
		areas[aid] = snappedf(float(res["areas"][aid]["score"]), 0.1)
	var top: Array = []
	for p in res["top3"]:
		top.append(String(p["text"]).left(120))
	return {"time": when, "commit": commit, "score": res["score"], "coverage": snappedf(float(res["coverage"]), 0.01),
			"areas": areas, "top3": top}
