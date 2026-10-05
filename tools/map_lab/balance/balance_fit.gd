extends SceneTree
## Fits the balance predictor (docs/tools/map_gate/balance_model.md) on every labelled map and validates it
## leave-one-map-out (LOMO). Inputs: tools/map_lab/balance/dataset/<map>.json (features, `run_balance.ps1 features`)
## and Bot Lab results (tools/map_lab/balance/labels/<map>/*.jsonl from run_labels.ps1, plus the map gate's
## docs/tools/map_gate/<map>/bots/*/results.jsonl). Writes tools/map_lab/balance/model.json and validation.md.
##   tools\map_lab\balance\run_balance.ps1 fit [holdout=<map>] [dry=1]
## holdout = leave that map out of the final model too (its prediction is then a true out-of-sample test).
## Candidates: null (team terms only, every map 50 %), prior (score weights, fitted scales), ridge (fitted weights,
## lam 1 / 3 / 10 / 30 / 100). The lowest LOMO log-loss wins.

const Model := preload("res://tools/map_lab/balance/balance_model.gd")
const Features := preload("res://tools/map_lab/balance/balance_features.gd")
const DS := "res://tools/map_lab/balance/dataset/"
const LABELS := "res://tools/map_lab/balance/labels/"
const GATE := "res://docs/tools/map_gate/"
const OUT_MD := "res://tools/map_lab/balance/validation.md"

var opts := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var advs := load_advs()
	var games := load_games(advs.keys())
	var holdout := String(opts.get("holdout", ""))
	var maps: Array[String] = []
	for g: Dictionary in games:
		if not maps.has(String(g["map"])):
			maps.append(String(g["map"]))
	maps.sort()
	print("BALANCE FIT: %d labelled maps, %d decided games (%d maps with features)" % [maps.size(), games.size(), advs.size()])
	if maps.size() < 3:
		print("BALANCE FIT: FAIL too few labelled maps")
		quit(1)
		return
	var cands: Array[Dictionary] = [{"kind": "null", "lam": 0.0}, {"kind": "prior", "lam": 0.0}]
	for lam: float in [1.0, 3.0, 10.0, 30.0, 100.0]:
		cands.append({"kind": "ridge", "lam": lam})
	var best := {}
	var results: Array[Dictionary] = []
	for c: Dictionary in cands:
		var cv := lomo(games, advs, maps, String(c["kind"]), float(c["lam"]))
		cv["kind"] = c["kind"]
		cv["lam"] = c["lam"]
		results.append(cv)
		print("  %-6s lam %5.1f  LOMO log-loss %.4f  cell MAE %.1f pts  (balanced-rate MAE %.1f pts)" % [c["kind"], c["lam"], cv["logloss"],
			100.0 * float(cv["mae"]), 100.0 * float(cv["mae_bal"])])
		if best.is_empty() or float(cv["logloss"]) < float(best["logloss"]) - 1e-9:
			best = cv
	var train := games.filter(func(g: Dictionary) -> bool: return String(g["map"]) != holdout)
	var model := Model.fit(train, advs, String(best["kind"]), float(best["lam"]))
	if String(best["kind"]) == "null":
		model["k"] = {"easy": 0.0, "normal": 0.0, "hard": 0.0}
	model["tau"] = tau_of(best["cells"])
	model["maps"] = maps.size() - (1 if maps.has(holdout) else 0)
	model["games"] = train.size()
	model["holdout"] = holdout
	model["cv_logloss"] = best["logloss"]
	model["cv_mae"] = best["mae"]
	model["cv_mae_text"] = "%.1f pts per map x difficulty" % (100.0 * float(best["mae"]))
	model["null_logloss"] = results[0]["logloss"]
	var md := validation_md(maps, games, advs, results, best, model, holdout)
	if not opts.has("dry"):
		var f := FileAccess.open(Model.MODEL_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(model, "\t", false))
		f.close()
		var m := FileAccess.open(OUT_MD, FileAccess.WRITE)
		m.store_string("\n".join(md) + "\n")
		m.close()
	print("\n".join(md))
	print("BALANCE FIT: model %s lam %.1f, LOMO log-loss %.4f (null %.4f), cell MAE %.1f pts, tau %.3f -> %s" % [best["kind"], best["lam"],
		best["logloss"], results[0]["logloss"], 100.0 * float(best["mae"]), model["tau"], Model.MODEL_PATH])
	quit(0)


static func load_advs() -> Dictionary:
	var out := {}
	var d := DirAccess.open(DS)
	if d == null:
		return out
	for f: String in d.get_files():
		if not f.ends_with(".json"):
			continue
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(DS + f))
		if v is Dictionary and (v as Dictionary).has("seats"):
			out[f.get_basename()] = Features.asym_of(v["seats"])["adv"]   # current dead bands / floors
	return out


## Every decided game of the maps that have features: {map, diff, team, y, g600 (seat-0 minus seat-1 crystals at 10:00)}.
static func load_games(maps: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: String in maps:
		var files: Array[String] = []
		for root: String in [LABELS + m + "/", GATE + m + "/bots/"]:
			var d := DirAccess.open(root)
			if d == null:
				continue
			for f: String in d.get_files():
				if f.ends_with(".jsonl"):
					files.append(root + f)
			for sub: String in d.get_directories():
				if FileAccess.file_exists(root + sub + "/results.jsonl"):
					files.append(root + sub + "/results.jsonl")
		var seen := {}
		for path: String in files:
			for line: String in FileAccess.get_file_as_string(path).split("\n", false):
				var v: Variant = JSON.parse_string(line)
				if not v is Dictionary:
					continue
				var r: Dictionary = v
				var key := "%s|%s|%s|%s" % [r.get("difficulty", ""), r.get("pair", ""), r.get("seed", ""), r.get("swap_sides", false)]
				if seen.has(key):
					continue   # the same game twice (a copied results file)
				seen[key] = true
				var g := game_of(r)
				if g.is_empty():
					continue
				g["map"] = m
				out.append(g)
	return out


## Every result row under `root` (results.jsonl in it or one level down, *.jsonl in it): [games, raw rows].
static func games_in_dir(root: String) -> Array:
	var games: Array[Dictionary] = []
	var rows: Array[Dictionary] = []
	var files: Array[String] = []
	var d := DirAccess.open(root)
	if d == null:
		return [games, rows]
	for f: String in d.get_files():
		if f.ends_with(".jsonl"):
			files.append(root.path_join(f))
	for sub: String in d.get_directories():
		if FileAccess.file_exists(root.path_join(sub).path_join("results.jsonl")):
			files.append(root.path_join(sub).path_join("results.jsonl"))
	for path: String in files:
		for line: String in FileAccess.get_file_as_string(path).split("\n", false):
			var v: Variant = JSON.parse_string(line)
			if v is Dictionary:
				rows.append(v)
				var g := game_of(v)
				if not g.is_empty():
					games.append(g)
	return [games, rows]


static func game_of(r: Dictionary) -> Dictionary:
	var diff := String(r.get("difficulty", ""))
	if not diff in Model.DIFFS:
		return {}
	var swap := bool(r.get("swap_sides", false))
	var seat := -1
	if r.has("winner_seat") and int(r["winner_seat"]) >= 0:
		seat = int(r["winner_seat"])
	elif String(r.get("winner_side", "")) == "player":
		seat = 1 if swap else 0
	elif String(r.get("winner_side", "")) == "enemy":
		seat = 0 if swap else 1
	if seat < 0:
		return {}
	var g600 := NAN
	var at: Dictionary = (r.get("at", {}) as Dictionary).get("600", {})
	if at.has("player") and at.has("enemy"):
		var gp := float(at["player"].get("gathered", 0))
		var ge := float(at["enemy"].get("gathered", 0))
		g600 = (ge - gp) if swap else (gp - ge)
	return {"diff": diff, "team": -1.0 if swap else 1.0, "y": 1.0 if seat == 0 else 0.0, "g600": g600}


## LOMO: fit without map m, predict m's games. Returns {logloss, mae (game-mix rate vs observed per map x diff),
## mae_bal, cells: [{map, diff, n, obs, pred, pred_bal}]}.
static func lomo(games: Array[Dictionary], advs: Dictionary, maps: Array[String], kind: String, lam: float) -> Dictionary:
	var ll := 0.0
	var n := 0
	var cells: Array[Dictionary] = []
	for m in maps:
		var train := games.filter(func(g: Dictionary) -> bool: return String(g["map"]) != m)
		var test := games.filter(func(g: Dictionary) -> bool: return String(g["map"]) == m)
		var model := Model.fit(train, advs, "prior" if kind == "null" else kind, lam)
		if kind == "null":
			model["k"] = {"easy": 0.0, "normal": 0.0, "hard": 0.0}
		ll += Model.log_loss(model, test, advs) * test.size()
		n += test.size()
		for d: String in Model.DIFFS:
			var tg := test.filter(func(g: Dictionary) -> bool: return String(g["diff"]) == d)
			if tg.is_empty():
				continue
			var obs := 0.0
			var pred := 0.0
			var z := Model.z_of(model, advs.get(m, {}))
			var k := float(model["k"][d])
			for g: Dictionary in tg:
				obs += float(g["y"])
				pred += Model.sigmoid(k * z + float(model["team"][d]) * float(g["team"]))
			cells.append({"map": m, "diff": d, "n": tg.size(), "obs": obs / tg.size(), "pred": pred / tg.size(),
				"pred_bal": Model.sigmoid(k * z)})
	var mae := 0.0
	var mae_bal := 0.0
	var w := 0.0
	for c: Dictionary in cells:
		mae += absf(float(c["obs"]) - float(c["pred"])) * float(c["n"])
		mae_bal += absf(float(c["obs"]) - float(c["pred_bal"])) * float(c["n"])
		w += float(c["n"])
	return {"logloss": ll / maxf(1.0, n), "mae": mae / maxf(1.0, w), "mae_bal": mae_bal / maxf(1.0, w), "cells": cells}


## Spread of the true seat rate around the prediction: LOMO residual variance minus the binomial noise of each cell.
static func tau_of(cells: Array) -> float:
	var s := 0.0
	var w := 0.0
	for c: Dictionary in cells:
		var nn := float(c["n"])
		if nn < 4.0:
			continue
		var p := clampf(float(c["pred"]), 0.05, 0.95)
		s += nn * (pow(float(c["obs"]) - float(c["pred"]), 2.0) - p * (1.0 - p) / nn)
		w += nn
	return maxf(Model.TAU_MIN, sqrt(maxf(0.0, s / maxf(1.0, w))))


static func validation_md(maps: Array[String], games: Array[Dictionary], advs: Dictionary, results: Array[Dictionary],
		best: Dictionary, model: Dictionary, holdout: String) -> Array[String]:
	var L: Array[String] = []
	L.append("# Balance model validation (generated by balance_fit.gd)")
	L.append("")
	L.append("%d maps, %d decided games. Chosen: **%s** (lam %.1f), LOMO log-loss %.4f vs %.4f for the null model (every map 50 %%); tau %.3f.%s" % [
		maps.size(), games.size(), best["kind"], best["lam"], best["logloss"], results[0]["logloss"], model["tau"],
		(" Final model fitted WITHOUT %s." % holdout) if holdout != "" else ""])
	L.append("")
	L.append("| Model | lam | LOMO log-loss | cell MAE (game mix) | cell MAE (seats balanced) |")
	L.append("|---|---|---|---|---|")
	for r: Dictionary in results:
		L.append("| %s | %.1f | %.4f | %.1f pts | %.1f pts |" % [r["kind"], r["lam"], r["logloss"], 100.0 * float(r["mae"]), 100.0 * float(r["mae_bal"])])
	L.append("")
	L.append("Per map, held out (LOMO, chosen model): observed seat-0 win rate / predicted for the same seat mix, games; g600 = mean seat-0 minus seat-1 crystals gathered at 10:00.")
	L.append("")
	L.append("| Map | games | easy obs / pred | normal obs / pred | hard obs / pred | pooled obs / pred | g600 | z |")
	L.append("|---|---|---|---|---|---|---|---|")
	for m in maps:
		var row := "| %s |" % m
		var mg := games.filter(func(g: Dictionary) -> bool: return String(g["map"]) == m)
		row += " %d |" % mg.size()
		var po := 0.0
		var pp := 0.0
		var pn := 0.0
		for d: String in Model.DIFFS:
			var cell := {}
			for c: Dictionary in best["cells"]:
				if String(c["map"]) == m and String(c["diff"]) == d:
					cell = c
			if cell.is_empty():
				row += " - |"
				continue
			row += " %.0f / %.0f %% (%d) |" % [100.0 * float(cell["obs"]), 100.0 * float(cell["pred"]), int(cell["n"])]
			po += float(cell["obs"]) * float(cell["n"])
			pp += float(cell["pred"]) * float(cell["n"])
			pn += float(cell["n"])
		var gs := 0.0
		var gn := 0
		for g: Dictionary in mg:
			if not is_nan(float(g["g600"])):
				gs += float(g["g600"])
				gn += 1
		row += " %.0f / %.0f %% | %+.0f | %+.3f |" % [100.0 * po / maxf(1.0, pn), 100.0 * pp / maxf(1.0, pn), gs / maxf(1.0, gn),
			Model.z_of(model, advs.get(m, {}))]
		L.append(row)
	L.append("")
	L.append("Fitted scales k (seat-0 log-odds per unit of z) and team terms (PLAYER bot on seat 0):")
	for d: String in Model.DIFFS:
		L.append("- %s: k %.2f, team %+.3f" % [d, float(model["k"][d]), float(model["team"][d])])
	var ws: Array = []
	for id: String in model["w"]:
		ws.append([id, float(model["w"][id])])
	ws.sort_custom(func(a: Array, b: Array) -> bool: return absf(a[1]) > absf(b[1]))
	L.append("")
	L.append("Largest weights w (z = sum w x seat-0 advantage):")
	for i in mini(8, ws.size()):
		L.append("- %s %+.3f" % [ws[i][0], ws[i][1]])
	return L
