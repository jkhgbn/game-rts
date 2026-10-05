extends SceneTree
## `balance <map>`: the internal balance score (0-100) of a map layout and the predicted G5 bot-fairness result, in
## seconds, no bot games (docs/tools/map_gate/balance_model.md). Loads a LayoutLevel (bots off, sim mode), waits for
## the navmesh bake, extracts the per-seat features (balance_features.gd), scores them and runs the fitted predictor
## (balance_model.gd + model.json).
##   tools\map_lab\balance\run_balance.ps1 <map> [out=<file.json>]
##   tools\world_forge\run_world_forge.ps1 balance <map>
##   & tools/godot_run.ps1 --headless --path . -s res://tools/map_lab/balance/balance.gd --fixed-fps 60 --quit-after 9000 '--' map=thornwater
## map = an id (data/maps/<id>_layout.tres, data/maps/gen/<id>_layout.tres, tools/map_lab/balance/variants/<id>_layout.tres)
## or a res:// path. out = also write the features + score + prediction as JSON (the dataset uses this).
## confirm=<dir> (map gate): judge the confirmation sample in <dir> (Bot Lab results.jsonl, one level of sub folders)
## against the prediction (balance_gate.gd); prints `BALANCE GATE: PASS|FULL <why>`, exit 0 PASS / 1 FULL.
## Last line: `BALANCE <map>: score <N> / 100, seat 0 predicted easy E % / normal N % / hard H %, <verdict>`.
## Exit 0 = clearly fair / uncertain, 1 = likely biased, 2 = bad input / no bake.

const Features := preload("res://tools/map_lab/balance/balance_features.gd")
const Model := preload("res://tools/map_lab/balance/balance_model.gd")
const Gate := preload("res://tools/map_lab/balance/balance_gate.gd")
const Fit := preload("res://tools/map_lab/balance/balance_fit.gd")
const _SIM := preload("res://scripts/core/sim_mode.gd")
const SEARCH := ["res://data/maps/%s_layout.tres", "res://data/maps/gen/%s_layout.tres", "res://tools/map_lab/balance/variants/%s_layout.tres"]

var opts := {}
var level: Node = null
var frame := 0
var ready_frame := -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var path := resolve(String(opts.get("map", "thornwater")))
	var lay: Resource = LayoutLevel.load_layout(path)
	if lay == null:
		print("BALANCE: FAIL no layout for '%s' (tried %s)" % [opts.get("map", ""), path])
		quit(2)
		return
	_SIM.enabled = true
	level = (load("res://scenes/layout_level.tscn") as PackedScene).instantiate()
	level.set(&"layout", lay)
	_disable(level)
	root.add_child(level)


static func resolve(id: String) -> String:
	if id.begins_with("res://") or id.contains(":/") or id.contains(":\\"):
		return id
	for pat: String in SEARCH:
		var p := pat % id
		if ResourceLoader.exists(p):
			return p
	return SEARCH[0] % id


static func _disable(n: Node) -> void:
	for c: Node in n.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.contains("/ai/") and &"enabled" in c:
			c.set(&"enabled", false)


func _process(_d: float) -> bool:
	if level == null:
		return true
	frame += 1
	_disable(level)
	if ready_frame < 0:
		if level.get(&"match_started") == true or level.get(&"hero") != null:
			ready_frame = frame
		elif frame > 7000:
			print("BALANCE: FAIL the level never finished its navmesh bake")
			quit(2)
		return false
	if frame < ready_frame + 10:
		return false
	var feat := Features.extract(level)
	if not bool(feat["ok"]):
		print("BALANCE: FAIL %s" % feat["error"])
		quit(2)
		return true
	var model := Model.load_model(String(opts.get("model", Model.MODEL_PATH)))
	var sc := Model.score(feat)
	var pr := Model.predict(model, feat["adv"])
	var lines := report_lines(String(feat["map"]), feat, sc, pr, model)
	print("\n".join(lines))
	if opts.has("out"):
		var o := {"map": feat["map"], "path": resolve(String(opts.get("map", ""))), "seats": feat["seats"], "asym": feat["asym"],
			"adv": feat["adv"], "abs": feat["abs"], "score": sc["score"], "prediction": pr, "seconds": feat["seconds"]}
		var f := FileAccess.open(String(opts["out"]), FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(o, "\t", false))
			f.close()
	if opts.has("confirm"):
		var gs: Array = Fit.games_in_dir(String(opts["confirm"]))
		var pl := Gate.plan(pr)
		var c := Gate.confirm(pr, gs[0], gs[1])
		print("BALANCE GATE: %s (%s) %s" % [c["status"], pl["why"], c["why"]])
		quit(0 if c["status"] == "PASS" else 1)
		return true
	quit(1 if pr["verdict"] == "likely biased" else 0)
	return true


static func report_lines(map: String, feat: Dictionary, sc: Dictionary, pr: Dictionary, model: Dictionary) -> Array[String]:
	var L: Array[String] = []
	L.append("== Balance: %s  (features %.1f s, navmesh + Map Lab grid, no bot games)" % [map, float(feat.get("seconds", 0.0))])
	L.append("Internal balance score %.0f / 100  (asymmetries -%.1f, sanity -%.1f)" % [sc["score"], sc["asym_lost"], sc["sanity_lost"]])
	L.append("Top asymmetries (seat 0 = side-0 seat, value seat 0 / seat 1, signed asymmetry, points lost, who it favours):")
	var shown := 0
	for c: Dictionary in sc["causes"]:
		if shown >= 6 or float(c["lost"]) < 0.25:
			break
		L.append("  %-18s %-62s %8.2f / %-8.2f %+6.1f %%  -%4.1f  favours %s" % [c["id"], c["label"], float(c["v0"]), float(c["v1"]),
			100.0 * float(c["a"]), float(c["lost"]), c["favours"]])
		shown += 1
	if shown == 0:
		L.append("  none above 0.25 points: the seats mirror within tolerance")
	for s: String in sc["sanity"]:
		L.append("  sanity: " + s)
	var fit_txt := "model %s, fitted on %d maps / %d games, LOMO error %s" % [model.get("kind", "?"), int(model.get("maps", 0)),
		int(model.get("games", 0)), str(model.get("cv_mae_text", "n/a"))] if bool(model.get("fitted", false)) else "model NOT fitted (defaults)"
	L.append("Predicted G5 seat-0 win rate (seats alternated; %s):" % fit_txt)
	for d: String in Model.DIFFS:
		var q: Dictionary = pr["per"][d]
		L.append("  %-7s %4.0f %%   90 %% interval %3.0f-%3.0f %%" % [d, 100.0 * float(q["p"]), 100.0 * float(q["lo"]), 100.0 * float(q["hi"])])
	L.append("Verdict: %s" % pr["verdict"])
	for w: String in pr["why"]:
		L.append("  - " + w)
	L.append("Recommendation: " + recommendation(sc, pr))
	var per: Dictionary = pr["per"]
	L.append("BALANCE %s: score %.0f / 100, seat 0 predicted easy %.0f %% / normal %.0f %% / hard %.0f %%, %s" % [map, sc["score"],
		100.0 * float(per["easy"]["p"]), 100.0 * float(per["normal"]["p"]), 100.0 * float(per["hard"]["p"]), pr["verdict"]])
	return L


static func recommendation(sc: Dictionary, pr: Dictionary) -> String:
	var top: Array = []
	for c: Dictionary in sc["causes"]:
		if float(c["lost"]) >= 2.0 and top.size() < 3:
			top.append("%s (%s, %+.0f %%)" % [c["label"], c["favours"], 100.0 * float(c["a"])])
	var fix := ("fix first: " + "; ".join(top)) if not top.is_empty() else "no single asymmetry stands out"
	match String(pr["verdict"]):
		"clearly fair":
			return "G5 by prediction: a 12-game confirmation sample is enough (balance_gate.gd). " + fix
		"likely biased":
			return "do not spend 40-120 bot games yet: %s, then run balance again." % fix
	return "run the full G5 (40 games, 120 near the edge). " + fix
