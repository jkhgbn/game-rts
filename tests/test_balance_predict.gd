extends SceneTree
## Balance model (docs/tools/map_gate/balance_model.md): feature extraction, internal score and predictor.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_balance_predict.gd --fixed-fps 60 --quit-after 12000
## 1. A synthetic rot180 map (built here, open ground): every geometric asymmetry ~0 (<= 2 %), score >= 75 (the
##    navmesh features may still differ a little: the bake's triangulation is not mirrored, units really walk it).
## 2. The same map with seat 1's home nodes 4 m farther and its natural hall 8 m farther: flagged (the economy /
##    expansion features favour seat 0, score drops >= 10, top cause names them).
## 3. The fitter recovers a known model from synthetic games (seeded), and predicts their seat rates within 8 points;
##    a perfectly symmetric map is "clearly fair", a strongly skewed one "likely biased".
## 4. When tools/map_lab/balance/model.json exists: its in-sample seat-rate error on the labelled maps stays within
##    tolerance (median <= 12 points) and it ranks the deliberately skewed variants on the right side of 50 %.
## Prints "PASS balance_predict" or "FAIL balance_predict: <reason>".

const TASK_ID := "balance_predict"
const Features := preload("res://tools/map_lab/balance/balance_features.gd")
const Model := preload("res://tools/map_lab/balance/balance_model.gd")
const Fit := preload("res://tools/map_lab/balance/balance_fit.gd")
const GEOMETRIC := ["eco_home_grid", "exp_nat_grid", "exp_third_grid", "def_exposure_grid", "contest_share", "camps_grid", "vision_grid", "slots_grid", "marks_grid"]

var level: Node = null
var phase := 0
var wait := 0
var results := {}
var errors: Array[String] = []


func _initialize() -> void:
	_start(_layout(false))


func _start(lay: MapLayout) -> void:
	level = (load("res://scenes/layout_level.tscn") as PackedScene).instantiate()
	level.set(&"layout", lay)
	_disable(level)
	root.add_child(level)
	wait = 0


static func _disable(n: Node) -> void:
	for c: Node in n.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.contains("/ai/") and &"enabled" in c:
			c.set(&"enabled", false)


func _process(_d: float) -> bool:
	if level == null:
		return false
	_disable(level)
	wait += 1
	if level.get(&"match_started") != true and level.get(&"hero") == null:
		if wait > 5000:
			return _done("level %d never finished its bake" % phase)
		return false
	if wait < 15:
		return false
	var feat := Features.extract(level)
	if not bool(feat["ok"]):
		return _done("extract failed: %s" % feat["error"])
	results[phase] = {"feat": feat, "score": Model.score(feat)}
	level.queue_free()
	level = null
	if phase == 0:
		phase = 1
		_start(_layout(true))
		return false
	_check()
	return _done("")


func _check() -> void:
	var f0: Dictionary = results[0]["feat"]
	var s0: Dictionary = results[0]["score"]
	for id: String in GEOMETRIC:
		var a := float(f0["asym"].get(id, 0.0))
		if absf(a) > 0.02:
			errors.append("symmetric map: %s asymmetry %.3f > 0.02" % [id, a])
	if float(s0["score"]) < 75.0:
		errors.append("symmetric map scores %.0f < 75 (top %s)" % [s0["score"], s0["causes"][0]["id"]])
	var f1: Dictionary = results[1]["feat"]
	var s1: Dictionary = results[1]["score"]
	if float(f1["adv"]["eco_home_grid"]) < 0.15:
		errors.append("skewed map: eco_home_grid seat-0 advantage %.3f < 0.15" % float(f1["adv"]["eco_home_grid"]))
	if float(f1["adv"]["exp_nat_grid"]) < 0.10:
		errors.append("skewed map: exp_nat_grid seat-0 advantage %.3f < 0.10" % float(f1["adv"]["exp_nat_grid"]))
	if float(s0["score"]) - float(s1["score"]) < 10.0:
		errors.append("skewed map scores %.0f, only %.0f below the symmetric one" % [s1["score"], float(s0["score"]) - float(s1["score"])])
	var top: Array[String] = []
	for i in 3:
		top.append(String(s1["causes"][i]["id"]))
	if not (top.has("eco_home_grid") or top.has("exp_nat_grid")):
		errors.append("skewed map: top causes %s do not name the moved nodes / hall" % ", ".join(top))
	var dbg: Array[String] = []
	for c: Dictionary in s0["causes"].slice(0, 4):
		dbg.append("%s %+.3f" % [c["id"], c["a"]])
	print("  symmetric map, largest asymmetries: " + ", ".join(dbg))
	print("  symmetric score %.0f, skewed score %.0f (top %s)" % [s0["score"], s1["score"], ", ".join(top)])
	_check_fitter()
	_check_model()


## Synthetic games from a known model: seat-0 log-odds = k_d * z, z = 4 * adv_eco, team effect +0.3.
func _check_fitter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var advs := {}
	var games: Array[Dictionary] = []
	var k := {"easy": 1.0, "normal": 1.5, "hard": 2.0}
	var truth := {}
	for i in 14:
		var m := "syn%d" % i
		var a := (i - 6.5) * 0.04
		var adv := {}
		for f: Dictionary in Features.FEATURES:
			adv[f["id"]] = rng.randf_range(-0.01, 0.01)
		adv["eco_trip_nav"] = a
		advs[m] = adv
		for d: String in Model.DIFFS:
			var zt := 4.0 * a * float(k[d])
			truth[m + d] = Model.sigmoid(zt)
			for g in 160:
				var team := 1.0 if g % 2 == 0 else -1.0
				var p := Model.sigmoid(zt + 0.3 * team)
				games.append({"map": m, "diff": d, "team": team, "y": 1.0 if rng.randf() < p else 0.0})
	var model := Model.fit(games, advs, "ridge", 3.0)
	var worst := 0.0
	for m: String in advs:
		var z := Model.z_of(model, advs[m])
		for d: String in Model.DIFFS:
			worst = maxf(worst, absf(Model.sigmoid(float(model["k"][d]) * z) - float(truth[m + d])))
	if worst > 0.08:
		errors.append("fitter: recovered seat rates off by up to %.1f points (> 8)" % (100.0 * worst))
	if absf(float(model["team"]["normal"]) - 0.3) > 0.15:
		errors.append("fitter: team term %.2f, expected ~0.30" % float(model["team"]["normal"]))
	model["fitted"] = true
	model["tau"] = 0.03
	var fair := Model.predict(model, {})   # every asymmetry 0
	if fair["verdict"] != "clearly fair":
		errors.append("fitter: a symmetric map is '%s', expected clearly fair" % fair["verdict"])
	var skew := Model.predict(model, advs["syn13"])
	if skew["verdict"] != "likely biased":
		errors.append("fitter: a strongly skewed map is '%s', expected likely biased" % skew["verdict"])
	print("  fitter: worst seat-rate error %.1f points, team %.2f" % [100.0 * worst, float(model["team"]["normal"])])


## The real model (when fitted): in-sample error on the labelled maps, and the skewed variants' side of 50 %.
func _check_model() -> void:
	if not FileAccess.file_exists(Model.MODEL_PATH):
		print("  model.json not fitted yet: real-label check skipped")
		return
	var model := Model.load_model()
	var advs := Fit.load_advs()
	var games := Fit.load_games(advs.keys())
	var errs: Array[float] = []
	var per := {}
	for g: Dictionary in games:
		var key := String(g["map"])
		if not per.has(key):
			per[key] = [0.0, 0.0, 0]
		var d := String(g["diff"])
		var p := Model.sigmoid(float(model["k"][d]) * Model.z_of(model, advs.get(key, {})) + float(model["team"][d]) * float(g["team"]))
		per[key][0] += float(g["y"])
		per[key][1] += p
		per[key][2] += 1
	for m: String in per:
		var n := float(per[m][2])
		if n >= 8.0:
			errs.append(absf(per[m][0] - per[m][1]) / n)
	errs.sort()
	var med := errs[errs.size() / 2] if not errs.is_empty() else 0.0
	if med > 0.12:
		errors.append("model.json: median in-sample seat-rate error %.1f points > 12" % (100.0 * med))
	for pair: Array in [["tw_eco0_far", -1], ["tw_eco1_far", 1], ["tw_nat1_far", 1], ["tw_rich0_near", 1]]:
		if advs.has(pair[0]) and String(model.get("kind", "")) != "null":
			var z := Model.z_of(model, advs[pair[0]])
			if signf(z) != float(pair[1]) and absf(z) > 0.0:
				errors.append("model.json: %s predicted on the wrong side of 50 %% (z %.3f)" % [pair[0], z])
	print("  model.json (%s): median in-sample error %.1f points over %d maps" % [model.get("kind", "?"), 100.0 * med, errs.size()])


func _done(err: String) -> bool:
	if err != "":
		errors.append(err)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	quit(0 if errors.is_empty() else 1)
	return true


## A small rot180 map on open ground (two keeps, home nodes, natural, rich, crown, camps, watchtowers, caches).
## skew: seat 1's home nodes 4 m and its natural hall + node 8 m farther from its keep.
static func _layout(skew: bool) -> MapLayout:
	var lay := MapLayout.new()
	lay.id = &"balance_synthetic_skew" if skew else &"balance_synthetic"
	lay.title = String(lay.id)
	lay.size = 100.0
	lay.size_x = 100.0
	lay.size_z = 100.0
	lay.symmetry = "rot180"
	var rot := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	lay.seats = [{"team": 0, "side": 0, "frame": Transform3D.IDENTITY, "frame_name": "identity", "name": "south-west"},
		{"team": 1, "side": 1, "frame": rot, "frame_name": "rot180", "name": "north-east"}]
	var keep := Vector3(-34.0, 0.0, 34.0)
	var base: Array = [
		["keep", "keep", "", keep, {"footprint": 6.0}],
		["home_a", "node", "", Vector3(-40.0, 0.0, 26.0), {"role": "a", "amount": 2000.0}],
		["home_b", "node", "", Vector3(-26.0, 0.0, 40.0), {"role": "b", "amount": 2000.0}],
		["nat_node", "node", "", Vector3(-10.0, 0.0, 20.0), {"role": "mid", "amount": 2500.0}],
		["nat_hall", "slot", "natural_hall", Vector3(-15.0, 0.0, 24.0), {}],
		["rich_node", "node", "", Vector3(-38.0, 0.0, -20.0), {"role": "rich", "amount": 2500.0}],
		["rich_hall", "slot", "rich_hall", Vector3(-36.0, 0.0, -11.0), {}],
		["camp_w", "camp", "wallow", Vector3(-20.0, 0.0, 0.0), {}],
		["camp_s", "camp", "stag", Vector3(0.0, 0.0, 30.0), {}],
		["tower", "point", "watchtower", Vector3(-28.0, 0.0, 8.0), {}],
		["cache", "cache", "", Vector3(-8.0, 0.0, 40.0), {}],
	]
	var spots: Array[Dictionary] = []
	for b: Array in base:
		var p: Vector3 = b[3]
		spots.append({"id": b[0], "kind": b[1], "sub": b[2], "pos": p, "props": b[4], "team": 0 if b[1] == "keep" else -1,
			"twin_of": b[0], "image": "identity"})
		var q := rot * p
		var tk := rot * keep
		if skew and String(b[0]) in ["home_a", "home_b"]:
			q += (q - tk).normalized() * 4.0
		if skew and String(b[0]) in ["nat_node", "nat_hall"]:
			q += (q - tk).normalized() * 8.0
		spots.append({"id": String(b[0]) + "_twin", "kind": b[1], "sub": b[2], "pos": q, "props": b[4], "team": 1 if b[1] == "keep" else -1,
			"twin_of": b[0], "image": "rot180"})
	spots.append({"id": "crown", "kind": "crown", "sub": "", "pos": Vector3.ZERO, "props": {}, "team": -1, "twin_of": "crown", "image": "identity"})
	lay.spots = spots
	return lay
