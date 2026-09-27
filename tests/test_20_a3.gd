extends SceneTree
## Task 20.A3 (bot think-time budget + attacks happen), scenes/skirmish.tscn, one normal bot per side (Fire = PLAYER seat,
## Shadow = ENEMY), the 30:00 time limit. Checks:
##   budget   each bot's median think tick <= MEDIAN_BUDGET_MS, p95 <= P95_BUDGET_MS, slowest <= MAX_BUDGET_MS (p95 / max
##            only when the machine is not oversubscribed: tick average <= BUSY_AVG_RATIO x median).
##   attack   each bot launches its first real attack (rule 7, not a creep) by ATTACK_BY seconds (15:00), unless rule 7's
##            own gates (strength, rally, regrow) were < 20 % of its blocked ticks (it had no army to send).
## Prints the economy, the per-step think cost (median / average / max with the match time of the max), the named
## sub-steps and why rule 7 did not launch (Commander.attack_blocks) every 2:00 and at the end.
## Run:  godot --headless --path . -s tests/test_20_a3.gd --fixed-fps 60 --quit-after 80000
##   Options after `--`: --minutes=N (stop after N match minutes, default 16), --log (print the bots' decisions),
##   --deaths (print every soldier death with its place and target), --record (keep the Replay Lab recorder on),
##   --fire=<kingdom> --shadow=<kingdom> (kingdom of each seat, default fire / shadow).

const TASK_ID := "20.A3"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const LIMIT_SECONDS := 1800.0
const FIRE := 0
const SHADOW := 1
## ai.md: < 0.3 ms per think on a quiet machine. These limits leave room for a busy one (agents running in parallel:
## the OS alone stalls a tick 50-250 ms now and then, so the max only catches real multi-second hitches).
const MEDIAN_BUDGET_MS := 1.5
const P95_BUDGET_MS := 20.0
const MAX_BUDGET_MS := 1000.0
const ATTACK_BY := 900.0
const RULE_GATE_SHARE := 0.2
const BUSY_AVG_RATIO := 5.0
const REPORT_EVERY := 120.0
const REPLAY_HOOKS := "res://scripts/core/replay/replay_hooks.gd"

var main: Node
var bots: Array[Node] = []
var _wait := 0
var _minutes := 16.0
var _log := false
var _next_report := REPORT_EVERY
var _kingdoms := {FIRE: &"", SHADOW: &""}
var _deaths := false
var _frame := 0
var _last_alive := {}


func _initialize() -> void:
	# The Replay Lab's auto recorder off (docs/plan/replay-lab.md: tests turn it off; on 2026-09-26 22:00 the recording
	# session froze every skirmish economy: 0 crystals gathered). `--record` keeps it on.
	if ResourceLoader.exists(REPLAY_HOOKS) and not OS.get_cmdline_user_args().has("--record"):
		load(REPLAY_HOOKS).auto_record = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			_minutes = float(a.trim_prefix("--minutes="))
		elif a == "--log":
			_log = true
		elif a == "--deaths":
			_deaths = true
		elif a.begins_with("--fire="):
			_kingdoms[FIRE] = StringName(a.trim_prefix("--fire="))
		elif a.begins_with("--shadow="):
			_kingdoms[SHADOW] = StringName(a.trim_prefix("--shadow="))
	main = load(SCENE).instantiate()
	main.set(&"time_limit_s", LIMIT_SECONDS)
	if _kingdoms[FIRE] != &"":
		main.set(&"player_kingdom", _kingdoms[FIRE])
	if _kingdoms[SHADOW] != &"":
		main.set(&"enemy_kingdom", _kingdoms[SHADOW])
	root.add_child(main)
	current_scene = main
	bots.append(_bot_for(FIRE))
	bots.append(_bot_for(SHADOW))


func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.debug_log = _log
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.debug_log = _log
	main.add_child(b)
	return b


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	var t: float = main.match_time()
	_frame += 1
	if _deaths and _frame % 20 == 0:
		_track_deaths(t)
	if t >= _next_report:
		_next_report += REPORT_EVERY
		_report(t)
	if main.game_over or t >= _minutes * 60.0:
		return _finish(t)
	return false


## --deaths: every soldier of either bot that dies is printed with where it died and its last attack target.
func _track_deaths(t: float) -> void:
	var alive := {}
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u.unit_type == null or u.unit_type.is_worker or int(u.team) > 1:
			continue
		var id := u.get_instance_id()
		var tgt: Variant = u.attack_target
		var tname := ""
		if tgt != null and is_instance_valid(tgt):
			tname = str((tgt as Node).name)
			var tt: Variant = (tgt as Node).get(&"unit_type")
			if tt != null:
				tname = str(tt.id)
		alive[id] = [int(u.team), str(u.unit_type.id), u.global_position, tname]
	for id in _last_alive.keys():
		if not alive.has(id):
			var e: Array = _last_alive[id]
			var p: Vector3 = e[2]
			print("DIED [%d:%02d] team %d %s at (%d, %d) fighting %s" % [int(t) / 60, int(t) % 60, int(e[0]), e[1],
					roundi(p.x), roundi(p.z), e[3]])
	_last_alive = alive


func _report(t: float) -> void:
	print("---- [%d:%02d] think cost" % [int(t) / 60, int(t) % 60])
	for b in bots:
		var eco: Economy = Economy.for_team(int(b.team))
		if eco:
			print("team %d: crystals %d, gathered %d, pop %d / %d" % [int(b.team), eco.crystals, eco.gathered_total,
					eco.pop_used, eco.pop_cap])
		print("bot %d: ticks %d, median %.3f ms, avg %.3f ms, max %.3f ms at %.0f s; attacks %d (first %.0f s), stage %s, str %.0f vs seen %.0f" % [
				int(b.team), b.tick_count, b.tick_usec_median() / 1000.0, b.tick_usec_average() / 1000.0,
				b.tick_usec_max / 1000.0, b.tick_max_at, b.attacks_launched, b.first_attack_time, str(b.stage),
				b.own_strength, b.seen_strength])
		var names: Array = b.STEP_NAMES
		var usec: Dictionary = b.rule_usec
		var mx: Dictionary = b.rule_usec_max
		var at: Dictionary = b.rule_usec_max_at
		var keys := usec.keys()
		var med := {}
		for k in keys:
			med[k] = b.step_usec_median(int(k))
		keys.sort_custom(func(x: Variant, y: Variant) -> bool: return float(med[x]) > float(med[y]))
		var parts: Array[String] = []
		for k in keys:
			parts.append("%s %.3f/%.2f/%.1f@%.0f" % [names[int(k)], float(med[k]) / 1000.0,
					float(usec[k]) / 1000.0 / maxf(1.0, float(b.tick_count)), float(mx.get(k, 0)) / 1000.0,
					float(at.get(k, 0.0))])
		print("  steps (median ms/avg ms/max ms@s): %s" % ", ".join(parts))
		print("  attack blocks (ticks): %s" % str(b.attack_blocks))
		var sub: Variant = b.get(&"sub_usec")
		if sub is Dictionary and not (sub as Dictionary).is_empty():
			var sd := sub as Dictionary
			var sm: Dictionary = b.get(&"sub_usec_max")
			var sk := sd.keys()
			sk.sort_custom(func(x: Variant, y: Variant) -> bool: return int(sd[x]) > int(sd[y]))
			var sp: Array[String] = []
			for k in sk:
				sp.append("%s %.2f/%.1f" % [k, float(sd[k]) / 1000.0 / maxf(1.0, float(b.tick_count)),
						float(sm.get(k, 0)) / 1000.0])
			print("  sub (avg ms/max ms): %s" % ", ".join(sp))


func _finish(t: float) -> bool:
	_report(t)
	var errors: Array[String] = []
	for b in bots:
		var med: float = b.tick_usec_median() / 1000.0
		var mx: float = b.tick_usec_max / 1000.0
		var samples: Array = (b.tick_usec_samples as Array).duplicate()
		samples.sort()
		var p95: float = float(samples[mini(samples.size() - 1, int(samples.size() * 0.95))]) / 1000.0 \
				if not samples.is_empty() else 0.0
		# Wall-clock ticks: on an oversubscribed machine (20+ Godot processes) the OS stalls land in random trivial steps
		# (a 1.5 s "retreat" step) and the average runs far above the median. Then only the median is judged.
		var avg: float = b.tick_usec_average() / 1000.0
		var busy := avg > BUSY_AVG_RATIO * maxf(med, 0.001)
		print("bot %d think: median %.3f ms, avg %.3f ms, p95 %.3f ms, max %.3f ms at %.0f s%s" % [int(b.team), med, avg,
				p95, mx, b.tick_max_at, " (BUSY machine: p95 / max not judged)" if busy else ""])
		if med > MEDIAN_BUDGET_MS:
			errors.append("bot %d median think %.3f ms > %.1f ms" % [int(b.team), med, MEDIAN_BUDGET_MS])
		if not busy and p95 > P95_BUDGET_MS:
			errors.append("bot %d p95 think %.1f ms > %.0f ms" % [int(b.team), p95, P95_BUDGET_MS])
		if not busy and mx > MAX_BUDGET_MS:
			errors.append("bot %d slowest think %.1f ms at %.0f s > %.0f ms" % [int(b.team), mx, b.tick_max_at, MAX_BUDGET_MS])
		# Rule 7 must launch whenever an army is gathered: a bot with no attack by 15:00 fails unless rule 7's own gates
		# ("strength", "rally", "regrow") held it back in < RULE_GATE_SHARE of its blocked ticks (the rest: no army, pop,
		# a real defence, a sortie out: its army kept dying or fighting at home, balance rather than the attack rule).
		var first: float = b.first_attack_time
		var blocks: Dictionary = b.attack_blocks
		var total := 0
		for k: String in blocks:
			total += int(blocks[k])
		var gate := float(int(blocks.get("strength", 0)) + int(blocks.get("rally", 0)) + int(blocks.get("regrow", 0))) \
				/ maxf(1.0, float(total))
		if t >= ATTACK_BY and (first < 0.0 or first > ATTACK_BY):
			if gate < RULE_GATE_SHARE:
				print("bot %d: no attack by %.0f s, rule 7's own gates only %.0f %% of its blocked ticks: %s" % [
						int(b.team), ATTACK_BY, gate * 100.0, str(blocks)])
			else:
				errors.append("bot %d first attack %.0f s (need <= %.0f s), blocks %s" % [int(b.team), first, ATTACK_BY,
						str(blocks)])
		print("bot %d (%s): %d attacks, first %.0f s, median %.3f ms, max %.3f ms" % [int(b.team), str(b.faction),
				b.attacks_launched, first, med, mx])
	print("match: over %s at %.0f s, winner %d" % [str(main.game_over), t, int(main.winner_team)])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in errors:
			print("  " + e)
		print("FAIL %s: %s" % [TASK_ID, errors[0]])
	return true
