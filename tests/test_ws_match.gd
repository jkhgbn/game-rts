extends SceneTree
# error_lab: quit-after=130000 (a 30:00 match is 108000 frames; seed 1 ends by bastion at ~29:13 = 105654 frames, ~350 s wall)
## Wave Strike M1 headless match (docs/design/wave-strike.md 7.9 "test_ws_bot" + "test_lane_march"): a 1v1 on Ashwind
## Reach where BOTH seats are WaveBots (the player's seat on autopilot), run as fast as the CPU allows. PASS when the
## match ends (Bastion kill, or the 30:00 rule) inside the limit, no lane unit stalled (LaneMarch.stall_events == 0,
## a stall = 10 s without progress and without a fight), and both sides spawned units. One JSON line "WS_RESULT {...}"
## (the batch runner tools/wave_strike/run_ws_batch.ps1 reads it). Script errors are counted by the runner (stderr).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_match.gd --fixed-fps 60 --quit-after 130000 '--' --seed=1
## Args (after "--"): --seed=N  --p0=hammer|steward  --p1=...  --west=fire|shadow (seat 0's kingdom)  --limit=1800
##   --sim=1 (default 1: no art)  --wizards=1  --out=PATH (the JSON line is also written there)  --perf=1 (frame times)
##   --east=fire|shadow|ice|nature (seat 1; default the other of fire / shadow)  --rule.<field>=N (a WaveStrikeRules knob)
##   --cards=res://....tres (a candidate WaveCardTable instead of data/wave_strike/card_prices.tres)

const TASK_ID := "ws_match"
const SCENE := "res://scenes/wave_strike.tscn"
const SIM_MODE_PATH := "res://scripts/core/sim_mode.gd"
const SIM_STRIP: Array[String] = ["SpellVfx", "CombatVfx", "UnitVfx", "CavalryVfx", "GameAudio", "Horizon"]

var args := {}
var level: Node
var seed_value := 1
var limit := 1800.0
var _frames := 0
var _started := false
var _done := false
var _t0 := 0
var _peak_units := 0
var _peak_by_team := [0, 0]
var _frame_usec := 0
var _perf: Dictionary = {}      ## alive-bucket (50s) -> [frames, usec_sum, usec_max]
var _last_usec := 0
var _out := ""
var _timeline: Array = []      ## one row a minute (see _process)
var _wiz_casts := [0, 0]
var _wiz_deaths := [0, 0]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s if eq < 0 else s.substr(0, eq)] = "1" if eq < 0 else s.substr(eq + 1)
	seed_value = int(args.get("seed", "1"))
	limit = float(args.get("limit", "1800"))
	_out = String(args.get("out", ""))
	seed(seed_value * 7919 + 17)
	if String(args.get("sim", "1")) == "1" and ResourceLoader.exists(SIM_MODE_PATH):
		(load(SIM_MODE_PATH) as Script).set(&"enabled", true)
	if args.has("cards"):
		# a candidate price table (tools/wave_strike/reprice_cards.gd --save=...): WaveCardTable.load_default() returns it
		var cand := load(String(args["cards"]))
		if cand == null:
			push_error("ws_match: no card table at %s" % args["cards"])
		else:
			(load("res://scripts/world/wave_strike/wave_card_table.gd") as Script).set(&"_cached", cand)
			print("WS cards %s" % args["cards"])
	level = (load(SCENE) as PackedScene).instantiate()
	var west := StringName(args.get("west", "fire"))
	level.set(&"player_kingdom", west)
	level.set(&"enemy_kingdom", StringName(args.get("east", "shadow" if west == &"fire" else "fire")))
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", String(args.get("wizards", "1")) == "1")
	var p: Array[String] = [String(args.get("p0", "hammer")), String(args.get("p1", "hammer"))]
	level.set(&"personalities", p)
	var rules: Resource = (load("res://scripts/world/wave_strike/wave_strike_rules.gd") as Script).call(&"load_default")
	rules.set(&"time_limit", limit)
	# Balance Lab-style knobs, in memory: --rule.base_income=120 --rule.bastion_hp_mult=1.8 (int / float fields)
	for k: String in args:
		if k.begins_with("rule."):
			var field := k.substr(5)
			var cur: Variant = rules.get(field)
			if cur == null:
				push_error("ws_match: unknown rule %s" % field)
				continue
			rules.set(field, int(args[k]) if cur is int else float(args[k]))
			print("WS rule %s = %s" % [field, str(rules.get(field))])
	level.set(&"rules", rules)
	if String(args.get("sim", "1")) == "1":
		for c in level.get_children():
			if SIM_STRIP.has(String(c.name)):
				level.remove_child(c)
				c.free()
	root.add_child(level)
	current_scene = level
	_t0 = Time.get_ticks_usec()
	_last_usec = _t0
	print("WS start seed %d west %s personalities %s limit %d" % [seed_value, west, str(p), int(limit)])


func _process(_delta: float) -> bool:
	if _done:
		return true
	var now := Time.get_ticks_usec()
	var dt_usec := now - _last_usec
	_last_usec = now
	_frames += 1
	var director: Node = level.get(&"director")
	if director == null:
		if _frames > 3000:
			_finish("FAIL", "the level never started (navmesh / setup)")
			return true
		return false
	if not _started:
		_started = true
		# seeded variety: each bot's card mix is jittered by the seed (equal personalities stay equal on average)
		for b in level.get(&"bots"):
			if b != null and &"rng_seed" in b:
				b.set(&"rng_seed", seed_value * 31 + int(b.get(&"seat")))
		# wizard stats per seat (casts, deaths): the labs check the seats' wizards behave alike
		var ws: Array = level.get(&"wizards")
		for t in ws.size():
			var w: Node = ws[t]
			if w == null:
				continue
			var sc: Variant = w.get(&"spell_caster")
			if sc != null and (sc as Node).has_signal(&"spell_cast"):
				(sc as Node).connect(&"spell_cast", func(_id: StringName) -> void: _wiz_casts[t] += 1)
			w.connect(&"died", func(_u: Node) -> void: _wiz_deaths[t] += 1)
	var alive := 0
	if _frames % 30 == 0:
		var by_team := [0, 0]
		for n in get_nodes_in_group(&"units"):
			if n.has_node(^"LaneMarch") and n.is_alive():
				by_team[int(n.team)] += 1
		alive = by_team[0] + by_team[1]
		# pacing timeline (balance labs): one row a minute = [min, Bastion HP % w / e, alive w / e, front x]
		var tmin := int(float(director.get(&"time")) / 60.0)
		if tmin > _timeline.size() - 1:
			var front := 0.0
			var best := -INF
			for n in get_nodes_in_group(&"units"):
				if n.has_node(^"LaneMarch") and n.is_alive() and int(n.team) == 0 and n.global_position.x > best:
					best = n.global_position.x
			front = best if best > -INF else 0.0
			_timeline.append([tmin, roundi(float(level.call(&"bastion_ratio", 0)) * 100.0),
					roundi(float(level.call(&"bastion_ratio", 1)) * 100.0), by_team[0], by_team[1], roundi(front)])
		_peak_units = maxi(_peak_units, alive)
		for t in 2:
			_peak_by_team[t] = maxi(_peak_by_team[t], by_team[t])
		level.set_meta(&"ws_alive", alive)
	if String(args.get("perf", "0")) == "1" and _frames > 10:
		var bucket := int(level.get_meta(&"ws_alive", 0)) / 50 * 50
		var row: Array = _perf.get(bucket, [0, 0, 0])
		row[0] += 1
		row[1] += dt_usec
		row[2] = maxi(row[2], dt_usec)
		_perf[bucket] = row
	var result: Dictionary = level.get(&"result")
	if not result.is_empty():
		_finish("", "")
		return true
	if float(director.get(&"time")) > limit + 30.0:
		_finish("FAIL", "no result after the time limit")
		return true
	return false


func _finish(verdict: String, why: String) -> void:
	_done = true
	var result: Dictionary = level.get(&"result")
	var stats: Array = level.get(&"stats")
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	var stalls := int(lm.get(&"stall_events"))
	var longest := float(lm.get(&"longest_stall"))
	var reasons: Array[String] = []
	if why != "":
		reasons.append(why)
	if stalls > 0:
		reasons.append("%d lane units stalled (longest %.1f s)" % [stalls, longest])
	if int(stats[0]["spawned"]) == 0 or int(stats[1]["spawned"]) == 0:
		reasons.append("a side never spawned (%d / %d)" % [stats[0]["spawned"], stats[1]["spawned"]])
	if verdict == "":
		verdict = "PASS" if reasons.is_empty() else "FAIL"
	var banks: Array = level.get(&"banks")
	var rosters: Array = level.get(&"rosters")
	var perf_rows := {}
	for b in _perf:
		var r: Array = _perf[b]
		perf_rows[str(b)] = {"frames": r[0], "avg_ms": snappedf(float(r[1]) / maxf(r[0], 1) / 1000.0, 0.01),
			"max_ms": snappedf(float(r[2]) / 1000.0, 0.01)}
	var line := {
		"seed": seed_value, "west": String(level.get(&"player_kingdom")), "east": String(level.get(&"enemy_kingdom")),
		"p0": level.get(&"personalities")[0], "p1": level.get(&"personalities")[1],
		"winner": int(result.get("winner", -2)), "reason": String(result.get("reason", "none")),
		"time": snappedf(float(result.get("time", -1.0)), 0.1), "horns": int(result.get("horns", 0)),
		"ratios": result.get("ratios", []), "stalls": stalls, "longest_stall": snappedf(longest, 0.1),
		"peak_units": _peak_units, "peak_by_team": _peak_by_team, "spawned": [stats[0]["spawned"], stats[1]["spawned"]],
		"value_killed": [stats[0]["value_killed"], stats[1]["value_killed"]],
		"earned": [banks[0].earned_total, banks[1].earned_total], "coffers": [banks[0].coffer_level, banks[1].coffer_level],
		"tiers": [rosters[0].tier, rosters[1].tier], "cards": [rosters[0].cards(), rosters[1].cards()],
		"wall_s": snappedf((Time.get_ticks_usec() - _t0) / 1e6, 0.1), "frames": _frames, "verdict": verdict,
		"perf": perf_rows, "timeline": _timeline, "wizard_casts": _wiz_casts, "wizard_deaths": _wiz_deaths,
	}
	var text := JSON.stringify(line)
	print("WS_RESULT " + text)
	if _out != "":
		var f := FileAccess.open(_out, FileAccess.WRITE)
		if f:
			f.store_line(text)
	if verdict == "PASS":
		print("PASS %s (winner seat %d by %s at %s)" % [TASK_ID, line["winner"], line["reason"], line["time"]])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(reasons)])
	quit(0 if verdict == "PASS" else 1)
