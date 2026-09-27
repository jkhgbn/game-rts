class_name ArtLabScore
extends RefCounted
## Art Lab (docs/plan/art-lab.md section 4): the quality score and "Improve next". Grades a measured value between a
## bad and a good end, turns every check's status + grade into a 0-1 score, the weighted mean into the 0-100 quality,
## and ranks the checks with headroom into the "Improve next" list (topped up with the kind's ideas, `add_extras`).
## ArtLabReport (lab_report.gd) stores the checks and writes them; it asks this file for the numbers.

const GROUP_WEIGHT := {"budget": 1.0, "health": 1.5, "read": 2.0, "anim": 1.0, "polish": 1.0, "decor": 1.5, "vfx": 1.5}


## A check's 0-1 score from its status and `graded` (0-1 how far inside / outside the rule, -1 = from the status):
## PASS 0.7-1, WARN 0.35-0.69, FAIL 0-0.34, INFO = the grade itself (-1 = not scored).
static func score_of(status: String, graded: float) -> float:
	var g := clampf(graded, 0.0, 1.0)
	match status:
		"PASS":
			return 1.0 if graded < 0.0 else lerpf(0.7, 1.0, g)
		"WARN":
			return 0.5 if graded < 0.0 else lerpf(0.35, 0.69, g)
		"FAIL":
			return 0.0 if graded < 0.0 else lerpf(0.0, 0.34, g)
		"INFO":
			return -1.0 if graded < 0.0 else g
	return -1.0


## Grades a value against a "bad" and a "good" end (either direction): 0 at bad, 1 at good.
static func grade(value: float, bad: float, good: float) -> float:
	if is_equal_approx(bad, good):
		return 1.0 if value >= good else 0.0
	return clampf((value - bad) / (good - bad), 0.0, 1.0)


## PASS / WARN / FAIL of a value against a budget {limit, hard}: over a hard limit = FAIL, over a soft one = WARN.
static func budget_status(value: float, lim: Dictionary) -> String:
	if lim.is_empty():
		return "INFO"
	if value <= float(lim["limit"]):
		return "PASS"
	return "FAIL" if bool(lim["hard"]) else "WARN"


## Quality 0-100: the weighted mean of every scored check (weight x the group weight).
static func quality(checks: Array[Dictionary]) -> float:
	var sw := 0.0
	var ss := 0.0
	for c: Dictionary in checks:
		var s: float = c["score"]
		if s < 0.0:
			continue
		var w: float = float(c["weight"]) * float(GROUP_WEIGHT.get(c["group"], 1.0))
		sw += w
		ss += w * s
	return 100.0 * ss / sw if sw > 0.0 else 0.0


## The "Improve next" list: the checks with the most weighted headroom that carry a suggestion, FAIL / WARN first,
## then polish ideas; topped up with `extras` so there are always at least `min_items`.
static func improve_next(checks: Array[Dictionary], extras: Array[Dictionary], min_items: int = 3, max_items: int = 6) -> Array[Dictionary]:
	var cands: Array[Dictionary] = []
	for c: Dictionary in checks:
		# v3 1.A: a check with a fix recipe (lab_fixes.gd, `fix`) shows the recipe in words instead of its generic idea;
		# the top recipe (`fix_rank` 1) leads the list
		var fix := String(c.get("fix", ""))
		if fix == "" and (String(c["improve"]) == "" or float(c["score"]) < 0.0 or float(c["score"]) >= 0.97):
			continue
		var w: float = float(c["weight"]) * float(GROUP_WEIGHT.get(c["group"], 1.0))
		var rank: float = w * (1.0 - maxf(float(c["score"]), 0.0))
		if c["status"] == "FAIL":
			rank += 100.0
		elif c["status"] == "WARN":
			rank += 10.0
		if int(c.get("fix_rank", 0)) == 1:
			rank += 1000.0
		cands.append({"rank": rank, "title": c["name"], "text": fix if fix != "" else String(c["improve"]),
			"source": "%s %s%s" % [c["id"], c["name"], (", shot " + String(c["shot"])) if String(c["shot"]) != "" else ""],
			"status": c["status"]})
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rank"]) > float(b["rank"]))
	var out: Array[Dictionary] = []
	for c2: Dictionary in cands:
		if out.size() >= max_items:
			break
		out.append(c2)
	for e: Dictionary in extras:
		if out.size() >= min_items:
			break
		out.append({"rank": 0.0, "title": e["title"], "text": e["text"], "source": e["source"], "status": "IDEA"})
	return out


## Kind-specific improvement ideas that top up "Improve next" to 3 items when the checks leave little headroom.
static func add_extras(ctx: ArtLabRunner) -> void:
	var ideas: Array = []
	match ctx.kind:
		&"unit", &"mount", &"titan", &"beast", &"critter":
			ideas = [["Idle / attack beats", "Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m", "anim strip"],
				["Detail density at 25 m", "Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m", "shot z25"],
				["Key-read contrast", "Put the lightest value and the team colour on the top-facing masses (seen from pitch 55), darker values low", "shot z40"],
				["Glow placement", "Keep one glow point high (head / weapon tip) and one lower accent at most", "glow shot"],
				["Ground contact", "Check the blob strength and a darker contact band at the feet so it never looks pasted on", "shot close"]]
		&"building", &"landmark":
			ideas = [["Dominant vertical + asymmetric secondary", "Push the one dominant vertical 10-15 % taller and make the secondary element clearly one-sided", "silhouette"],
				["Tops light, bottoms dark", "Lighten roofs / caps and darken the plinth band (0.72 x at the ground, 1.08 x at the top)", "shot z40"],
				["Magic moves", "Something magical should rotate, bob or pulse (art-keep 0.6)", "anim strip"],
				["Ground contact", "Contact decal + a few rubble / scorch pieces (art-keep 0.5)", "shot close"]]
		&"decor_set":
			ideas = [["Value step under units", "Keep decor one value step darker / less saturated than unit colours", "D8"],
				["Clusters and bare ground", "Group pieces in clumps with bare ground between them so paths and units stay readable", "D9"],
				["Variety", "Use the 3 shape variants and a 15-25 % scale spread so repeats do not show at 25 m", "shot z25"]]
		&"vfx":
			ideas = [["Read in 0.3 s", "A bright core in the first 0.1 s, then a slower fade; the 40 m read comes from the core + a ground ring", "effects sheet"],
				["Team / kingdom colour", "Tint with the owner's glow colour, never a third tint (art-keep 0.6)", "effects sheet"],
				["Cost", "Pool and reuse; no particles beyond 45 m", "V2 / V5"]]
	for i: Array in ideas:
		ctx.rep.extras.append({"title": i[0], "text": i[1], "source": i[2]})
	# v3 1.A: fix recipes for every FAIL / WARN (lab_fixes.gd -> <out>/fixes.json); runs after the last check, before
	# the scorecard is written, so "Improve next" shows the top recipe. `fixes=0` turns it off.
	if String(ctx.opts.get("fixes", "1")) != "0":
		ArtLabFixes.build(ctx)
