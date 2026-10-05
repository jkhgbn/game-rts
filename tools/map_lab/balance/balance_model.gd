extends RefCounted
## Balance model, part 2 (docs/tools/map_gate/balance_model.md): the internal balance score of a map's features
## (balance_features.gd) and the predictor of the map gate's G5 bot-fairness result (seat-0 win rate per difficulty),
## fitted on labelled maps (Bot Lab games) by balance_fit.gd into model.json.
## Model (per game g on map m, difficulty d; undecided games skipped):
##   logit P(seat 0 wins) = k_d * z_m + g_d * team_g
##   z_m    = sum_f w_f * adv_mf              (adv = seat-0 advantage of feature f, balance_features.gd)
##   team_g = +1 when the PLAYER bot sat on seat 0, -1 with --swap-sides (the bot-side effect, not the map's)
## Two candidate weightings, the better leave-one-map-out (LOMO) log-loss wins: "prior" (w_f = weight_f / tol_f of the
## score, one scale per difficulty: 3 fitted numbers + 3 team terms) and "ridge" (w_f fitted, L2 on standardised
## features). Prediction interval: the LOMO residual spread beyond binomial noise (tau), +-1.645 tau (90 %).
## No class_name on purpose (preloaded tool script).

const Features := preload("res://tools/map_lab/balance/balance_features.gd")
const MODEL_PATH := "res://tools/map_lab/balance/model.json"
const DIFFS: Array[String] = ["easy", "normal", "hard"]
const ASYM_CAP := 80.0          ## score points the asymmetries can cost at most
const FAIR_LO := 0.45           ## G5 band
const FAIR_HI := 0.55
const CLEAR_LO := 0.40          ## "clearly fair": the whole 90 % interval inside 40-60 % on every difficulty
const CLEAR_HI := 0.60
const TAU_MIN := 0.03           ## the interval never gets narrower than +-1.645 x 3 points
const Z90 := 1.645


# ---------------------------------------------------------------- internal balance score

## {score, asym_lost, sanity_lost, causes: [{id, group, label, a, adv, lost, favours}] (largest first), sanity: [String]}
static func score(feat: Dictionary) -> Dictionary:
	var causes: Array[Dictionary] = []
	var asym_lost := 0.0
	for f: Dictionary in Features.FEATURES:
		var id: String = f["id"]
		var a := float((feat.get("asym", {}) as Dictionary).get(id, 0.0))
		var adv := float((feat.get("adv", {}) as Dictionary).get(id, 0.0))
		var lost := float(f["weight"]) * minf(1.5, absf(a) / float(f["tol"]))
		asym_lost += lost
		causes.append({"id": id, "group": f["group"], "label": f["label"], "a": a, "adv": adv, "lost": lost,
			"favours": "-" if absf(adv) < 1e-4 else ("seat 0 (side 0, south-west)" if adv > 0.0 else "seat 1 (side 1)"),
			"v0": (feat["seats"][0] as Dictionary).get(id, 0.0), "v1": (feat["seats"][1] as Dictionary).get(id, 0.0)})
	causes.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["lost"]) > float(y["lost"]))
	asym_lost = minf(ASYM_CAP, asym_lost)
	var ab: Dictionary = feat.get("abs", {})
	var sanity: Array[String] = []
	var s_lost := 0.0
	if int(ab.get("unreachable", 0)) > 0:
		s_lost += 10.0
		sanity.append("%d seat target(s) unreachable on the navmesh (-10)" % int(ab["unreachable"]))
	var err := float(ab.get("slot_sym_err", 0.0))
	if err > 1.0:
		var l := minf(6.0, err * 2.0)
		s_lost += l
		sanity.append("bot slots / marks off the symmetry by %.1f m on average (-%.0f)" % [err, l])
	var kk := float(ab.get("keep_keep", 0.0))
	if kk < 90.0 or kk > 230.0:
		s_lost += 4.0
		sanity.append("keep-to-keep path %.0f m outside 90-230 m (-4)" % kk)
	var nat := float(ab.get("natural", 0.0))
	if nat < 15.0 or nat > 55.0:
		s_lost += 3.0
		sanity.append("natural hall %.0f m from the keep, outside 15-55 m (-3)" % nat)
	var mw := float(ab.get("route_min_width", INF))
	if mw < 4.0:
		s_lost += 3.0
		sanity.append("main route narrows to %.1f m (< 4 m: armies queue) (-3)" % mw)
	if int(ab.get("neutral_objectives", 0)) < 10:
		s_lost += 2.0
		sanity.append("only %d neutral objectives (-2)" % int(ab.get("neutral_objectives", 0)))
	s_lost = minf(20.0, s_lost)
	return {"score": clampf(100.0 - asym_lost - s_lost, 0.0, 100.0), "asym_lost": asym_lost, "sanity_lost": s_lost,
		"causes": causes, "sanity": sanity}


# ---------------------------------------------------------------- predictor

## The default model when no model.json exists: the prior weighting with neutral scales (honest: unfitted).
static func default_model() -> Dictionary:
	return {"kind": "prior", "w": prior_weights(), "k": {"easy": 0.0, "normal": 0.0, "hard": 0.0},
		"team": {"easy": 0.0, "normal": 0.0, "hard": 0.0}, "tau": 0.12, "fitted": false, "maps": 0, "games": 0}


static func prior_weights() -> Dictionary:
	var w := {}
	for f: Dictionary in Features.FEATURES:
		w[f["id"]] = float(f["weight"]) / float(f["tol"]) / 100.0
	return w


static func load_model(path: String = MODEL_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_model()
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else default_model()


static func z_of(model: Dictionary, adv: Dictionary) -> float:
	var z := 0.0
	var w: Dictionary = model.get("w", {})
	for id: String in w:
		z += float(w[id]) * float(adv.get(id, 0.0))
	return z


static func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-clampf(x, -30.0, 30.0)))


## Predicted seat-0 win rate per difficulty with seats alternated (team term cancels): {d: {p, lo, hi}}, verdict, why.
static func predict(model: Dictionary, adv: Dictionary) -> Dictionary:
	var z := z_of(model, adv)
	var tau := maxf(TAU_MIN, float(model.get("tau", 0.12)))
	var per := {}
	var verdict := "clearly fair"
	var why: Array[String] = []
	var biased := false
	for d: String in DIFFS:
		var k := float((model.get("k", {}) as Dictionary).get(d, 0.0))
		var p := sigmoid(k * z)
		var lo := clampf(p - Z90 * tau, 0.0, 1.0)
		var hi := clampf(p + Z90 * tau, 0.0, 1.0)
		per[d] = {"p": p, "lo": lo, "hi": hi}
		if (p < FAIR_LO or p > FAIR_HI) and (hi < 0.5 or lo > 0.5):
			biased = true
			why.append("%s %.0f %% (90 %% interval %.0f-%.0f %%) is outside 45-55 %% and excludes 50 %%" % [d, 100 * p, 100 * lo, 100 * hi])
		elif lo < CLEAR_LO or hi > CLEAR_HI:
			if verdict == "clearly fair":
				verdict = "uncertain"
			why.append("%s %.0f %% (90 %% interval %.0f-%.0f %%) reaches outside 40-60 %%" % [d, 100 * p, 100 * lo, 100 * hi])
	if biased:
		verdict = "likely biased"
	if not bool(model.get("fitted", false)):
		verdict = "uncertain"
		why.append("no fitted model (tools/map_lab/balance/model.json missing): run balance_fit.gd")
	return {"z": z, "per": per, "verdict": verdict, "why": why, "tau": tau}


# ---------------------------------------------------------------- fitting (balance_fit.gd)

## games: [{map, diff, team (+1 / -1), y (1 = seat 0 won)}]; advs: {map -> {id -> adv}}. Returns a model dict.
## kind "prior": w fixed (prior_weights), fit k_d and team_d. kind "ridge": fit w (standardised, L2 lam) then k_d.
static func fit(games: Array, advs: Dictionary, kind: String, lam: float) -> Dictionary:
	var model := default_model()
	model["kind"] = kind
	model["lam"] = lam
	var ids: Array[String] = []
	for f: Dictionary in Features.FEATURES:
		ids.append(String(f["id"]))
	if kind == "ridge":
		# standardise each feature over the maps in the training set
		var sd := {}
		for id in ids:
			var s := 0.0
			var n := 0
			for m: String in advs:
				s += pow(float((advs[m] as Dictionary).get(id, 0.0)), 2.0)
				n += 1
			sd[id] = maxf(0.005, sqrt(s / maxf(1.0, n)))
		# per-game logistic regression with columns x_f = adv_f / sd_f (no intercept: seat 0 means nothing alone)
		# plus 3 team columns (one per difficulty, light penalty)
		var cols := ids.size() + 3
		var X: Array = []
		var Y: Array[float] = []
		for g: Dictionary in games:
			var adv: Dictionary = advs.get(g["map"], {})
			var row := PackedFloat64Array()
			row.resize(cols)
			for i in ids.size():
				row[i] = float(adv.get(ids[i], 0.0)) / float(sd[ids[i]])
			row[ids.size() + DIFFS.find(String(g["diff"]))] = float(g["team"])
			X.append(row)
			Y.append(float(g["y"]))
		var pen := PackedFloat64Array()
		pen.resize(cols)
		for i in cols:
			pen[i] = lam if i < ids.size() else 0.5
		var beta := _logistic_irls(X, Y, pen)
		var w := {}
		for i in ids.size():
			w[ids[i]] = beta[i] / float(sd[ids[i]])
		model["w"] = w
	# per-difficulty scale k_d and team term (2-column logistic each, light penalty), z from w
	var k := {}
	var team := {}
	for d: String in DIFFS:
		var X2: Array = []
		var Y2: Array[float] = []
		for g: Dictionary in games:
			if String(g["diff"]) != d:
				continue
			var row := PackedFloat64Array([z_of(model, advs.get(g["map"], {})), float(g["team"])])
			X2.append(row)
			Y2.append(float(g["y"]))
		if X2.is_empty():
			k[d] = 0.0
			team[d] = 0.0
			continue
		var b := _logistic_irls(X2, Y2, PackedFloat64Array([0.05 if kind == "prior" else 0.5, 0.5]))
		k[d] = b[0]
		team[d] = b[1]
	model["k"] = k
	model["team"] = team
	model["fitted"] = true
	return model


## Ridge-penalised logistic regression by Newton / IRLS (no intercept). X rows PackedFloat64Array, pen per column.
static func _logistic_irls(X: Array, Y: Array[float], pen: PackedFloat64Array, iters: int = 40) -> PackedFloat64Array:
	var p := pen.size()
	var beta := PackedFloat64Array()
	beta.resize(p)
	beta.fill(0.0)
	for _it in iters:
		var H: Array = []
		for i in p:
			var r := PackedFloat64Array()
			r.resize(p)
			r.fill(0.0)
			r[i] = pen[i]
			H.append(r)
		var grad := PackedFloat64Array()
		grad.resize(p)
		for i in p:
			grad[i] = -pen[i] * beta[i]
		for n in X.size():
			var x: PackedFloat64Array = X[n]
			var eta := 0.0
			for i in p:
				eta += x[i] * beta[i]
			var mu := sigmoid(eta)
			var wgt := maxf(1e-6, mu * (1.0 - mu))
			for i in p:
				if x[i] == 0.0:
					continue
				grad[i] += (Y[n] - mu) * x[i]
				var hr: PackedFloat64Array = H[i]
				for j in p:
					hr[j] += wgt * x[i] * x[j]
				H[i] = hr
		var step := _solve(H, grad)
		var mx := 0.0
		for i in p:
			beta[i] += step[i]
			mx = maxf(mx, absf(step[i]))
		if mx < 1e-7:
			break
	return beta


## Gaussian elimination with partial pivoting: solves A x = b (A rows PackedFloat64Array).
static func _solve(A: Array, b: PackedFloat64Array) -> PackedFloat64Array:
	var n := b.size()
	var M: Array = []
	for i in n:
		var r: PackedFloat64Array = (A[i] as PackedFloat64Array).duplicate()
		r.append(b[i])
		M.append(r)
	for c in n:
		var piv := c
		for r in range(c + 1, n):
			if absf((M[r] as PackedFloat64Array)[c]) > absf((M[piv] as PackedFloat64Array)[c]):
				piv = r
		var tmp: PackedFloat64Array = M[c]
		M[c] = M[piv]
		M[piv] = tmp
		var pr: PackedFloat64Array = M[c]
		if absf(pr[c]) < 1e-12:
			continue
		for r in range(c + 1, n):
			var rr: PackedFloat64Array = M[r]
			var f := rr[c] / pr[c]
			if f == 0.0:
				continue
			for j in range(c, n + 1):
				rr[j] -= f * pr[j]
			M[r] = rr
	var x := PackedFloat64Array()
	x.resize(n)
	for i in range(n - 1, -1, -1):
		var ri: PackedFloat64Array = M[i]
		var s := ri[n]
		for j in range(i + 1, n):
			s -= ri[j] * x[j]
		x[i] = s / ri[i] if absf(ri[i]) > 1e-12 else 0.0
	return x


## Mean log-loss of a model on games (seats alternated or not: the team term is used as fitted).
static func log_loss(model: Dictionary, games: Array, advs: Dictionary) -> float:
	var s := 0.0
	for g: Dictionary in games:
		var d := String(g["diff"])
		var eta := float((model["k"] as Dictionary).get(d, 0.0)) * z_of(model, advs.get(g["map"], {})) \
				+ float((model["team"] as Dictionary).get(d, 0.0)) * float(g["team"])
		var p := clampf(sigmoid(eta), 1e-4, 1.0 - 1e-4)
		s -= log(p) if float(g["y"]) > 0.5 else log(1.0 - p)
	return s / maxf(1.0, games.size())
