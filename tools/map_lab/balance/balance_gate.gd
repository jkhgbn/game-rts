extends RefCounted
## Balance model in the map gate (docs/tools/map_gate/balance_model.md): decides whether G5 needs the full 40 / 120
## bot games or can PASS by prediction after a small confirmation sample.
##   plan(prediction)                    -> {mode: "confirm" | "full", games, why}
##   confirm(prediction, games, model)   -> {status: "PASS" | "FULL", why}
## Rule: only a "clearly fair" prediction (every difficulty's 90 % interval inside 40-60 %) earns the short path:
## CONFIRM_GAMES games (4 mirrors x 3 difficulties, seats alternated by seed). It PASSes when the sample agrees with the
## prediction: per difficulty and pooled, |observed - predicted| <= 1.96 x sqrt(tau^2 + p(1-p)/n), no script error,
## every game ended. Anything else -> the full G5 (40 games, 120 near the 45-55 % edge), exactly as before.
## No class_name on purpose (preloaded tool script).

const Model := preload("res://tools/map_lab/balance/balance_model.gd")
const CONFIRM_GAMES := 12


static func plan(prediction: Dictionary) -> Dictionary:
	if String(prediction.get("verdict", "")) == "clearly fair":
		return {"mode": "confirm", "games": CONFIRM_GAMES,
			"why": "predicted clearly fair: %d-game confirmation sample instead of 40 / 120" % CONFIRM_GAMES}
	return {"mode": "full", "games": 40, "why": "predicted %s: full G5" % prediction.get("verdict", "?")}


## games: [{diff, team, y, ...}] (balance_fit.gd game_of), plus raw rows for script_errors / end checks (optional).
static func confirm(prediction: Dictionary, games: Array, raw_rows: Array = []) -> Dictionary:
	if String(prediction.get("verdict", "")) != "clearly fair":
		return {"status": "FULL", "why": "prediction is %s" % prediction.get("verdict", "?")}
	for r: Dictionary in raw_rows:
		if int(r.get("script_errors", 0)) > 0:
			return {"status": "FULL", "why": "a confirmation game had script errors"}
		if String(r.get("end_reason", "")) in ["cap", "stall", ""]:
			return {"status": "FULL", "why": "a confirmation game did not end (%s)" % r.get("end_reason", "?")}
	if games.size() < CONFIRM_GAMES:
		return {"status": "FULL", "why": "only %d decided confirmation games (< %d)" % [games.size(), CONFIRM_GAMES]}
	var tau := float(prediction.get("tau", Model.TAU_MIN))
	var why: Array[String] = []
	var ok := true
	var po := 0.0
	var pp := 0.0
	for d: String in Model.DIFFS:
		var dg := games.filter(func(g: Dictionary) -> bool: return String(g["diff"]) == d)
		if dg.is_empty():
			continue
		var p := float(prediction["per"][d]["p"])
		var obs := 0.0
		for g: Dictionary in dg:
			obs += float(g["y"])
		obs /= dg.size()
		po += obs * dg.size()
		pp += p * dg.size()
		var lim := 1.96 * sqrt(tau * tau + p * (1.0 - p) / dg.size())
		why.append("%s %.0f %% observed vs %.0f %% predicted (n %d, limit +-%.0f)" % [d, 100 * obs, 100 * p, dg.size(), 100 * lim])
		if absf(obs - p) > lim:
			ok = false
	po /= games.size()
	pp /= games.size()
	var lim_all := 1.96 * sqrt(tau * tau + pp * (1.0 - pp) / games.size())
	why.append("pooled %.0f %% vs %.0f %% (limit +-%.0f)" % [100 * po, 100 * pp, 100 * lim_all])
	if absf(po - pp) > lim_all:
		ok = false
	return {"status": "PASS" if ok else "FULL", "why": "; ".join(why)}
