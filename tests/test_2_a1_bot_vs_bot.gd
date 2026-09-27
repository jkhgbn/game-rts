extends SceneTree
## Task 2.A1 (the bot), bot vs bot: one normal bot per side on scenes/skirmish.tscn (Fire plays the
## mirrored slots). A real win (every building of one side down, or a concede) before 30:00 is a normal PASS.
## Step 16a: the skirmish runs with the 30:00 time limit (`time_limit_s` 1800); a match still going at 30:00 ends
## on score: the test logs the full ScoreKeeper table, "WON ON SCORE team X by N" and prints
## "PASS 2.A1 bot vs bot (on score)" (a stall is still worth data), plus the stall diagnostics (a worker-less side
## kept alive by its caravans / Bazaar...). Prints both bots' attacks, the winner and the think-tick cost.
## rush-balance.md 1 targets a 15-20 min median: balance runs count "on score" results separately.
## Run:  godot --headless --path . -s tests/test_2_a1_bot_vs_bot.gd --fixed-fps 60 --quit-after 116000

const TASK_ID := "2.A1 bot vs bot"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const LIMIT_SECONDS := 1800.0
const TIMEOUT_FRAMES := 110000
const FIRE := 0
const SHADOW := 1

var main: Node
var bots: Array[Node] = []
var frame := 0
var _wait := 0
var _ended_at := -1.0


func _initialize() -> void:
	# 20.A3: the Replay Lab's auto recorder off (docs/plan/replay-lab.md: tests turn it off; its session froze the
	# skirmish economy on 2026-09-26 22:00).
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	main = load(SCENE).instantiate()
	main.set(&"time_limit_s", LIMIT_SECONDS)
	root.add_child(main)
	current_scene = main
	bots.append(_bot_for(FIRE))
	bots.append(_bot_for(SHADOW))


func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.debug_log = true
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.debug_log = true
	main.add_child(b)
	return b


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	var t: float = main.match_time()
	if main.game_over:
		return _finish(t)
	if frame % 3600 == 0:
		for team in [FIRE, SHADOW]:
			var eco: Economy = Economy.for_team(team)
			print("[%d:%02d] team %d: buildings %d, crystals %d, gathered %d, pop %d / %d" % [int(t) / 60,
					int(t) % 60, team, Building.for_team(team).size(), eco.crystals, eco.gathered_total,
					eco.pop_used, eco.pop_cap])
	if frame > TIMEOUT_FRAMES:
		return _finish(t)
	return false


func _finish(t: float) -> bool:
	for b in bots:
		print("bot %d: %d attacks (first %.0f s), ticks %d, avg %.3f ms, max %.3f ms" % [int(b.team),
				b.attacks_launched, b.first_attack_time, b.tick_count, b.tick_usec_average() / 1000.0,
				b.tick_usec_max / 1000.0])
		if b.has_method(&"tick_usec_median"):   # 20.A3
			print("bot %d: think median %.3f ms (max at %.0f s), attack blocks %s" % [int(b.team),
					b.tick_usec_median() / 1000.0, b.tick_max_at, str(b.get(&"attack_blocks"))])
	var winner: int = main.winner_team
	var on_score: bool = main.get(&"ended_on_score") == true
	print("match over: %s at %.0f s, winner team %d%s" % [str(main.game_over), t, winner, " (on score)" if on_score else ""])
	var sk: Node = main.get(&"score_keeper") as Node
	if sk != null and is_instance_valid(sk):
		print(sk.call(&"table_text"))
	if main.game_over and winner >= 0 and not on_score:
		print("PASS %s" % TASK_ID)
		return true
	# Why nobody won: a side with no workers left that still owns caravans or a Bazaar never concedes
	# (Commander._check_concede, 10.A3) and has to be razed building by building.
	for b in bots:
		var tm := int(b.team)
		var markets := 0
		for m in get_nodes_in_group("markets"):
			if int(m.get(&"team")) == tm:
				markets += 1
		print("team %d: buildings %d, workers %d, soldiers %d, caravans %d, bazaar %d, crystals %d, all-in %s" % [tm,
				Building.for_team(tm).size(), (b.get(&"_workers") as Array).size(), (b.get(&"_soldiers") as Array).size(),
				(b.get(&"_caravans") as Array).size(), markets, Economy.for_team(tm).crystals, str(b.get(&"all_in"))])
	if main.game_over and on_score and winner >= 0 and sk != null:
		print("WON ON SCORE team %d by %d" % [winner, int(sk.call(&"margin"))])
		print("PASS %s (on score)" % TASK_ID)
	else:
		print("FAIL %s: no winner in %.0f s" % [TASK_ID, t])
	return true
