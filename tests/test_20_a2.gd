extends SceneTree
## Task 20.A2 (docs/design/ai-2v2.md 7.2 F1-F5, the bot stall fix, 1v1), scenes/skirmish.tscn, a normal Shadow bot
## (ENEMY) against an idle player. Parts (each on a fresh scene):
##   static   F4 on a stand-alone AITrade: pop-capped with soldier pop < 45 % of the cap -> target max(2, target - 2);
##            AITrade.earned_since / can_fund_comeback.
##   recovery F1: at 0 workers with a Bazaar, 3 caravans and 600 gold the bot exchanges to crystals within 2 ticks
##            (every full 100, nothing kept for wares) and queues a worker (within 2 ticks of the exchange); no caravan
##            is queued and no ware bought while recovering.
##   notrips  F2: 0 workers, 0 soldiers, a Bazaar + 3 idle caravans, 80 gold just earned by a trip: no concede while the
##            trip is < 120 s old; a concede once no trip for 120 s (Bazaar and caravans still standing).
##   hardstop F2: no keep, 0 workers, 0 soldiers, 0 queued, a Bazaar with 300 gold (trade "can pay", the old stall):
##            no concede before 150 s, a "hard stop" concede at 150 s.
##   trickle  F2 hard stop: trade gold keeps buying workers that die before delivering: "hard stop" at 150 s anyway.
##   starve   F5: crystals held under a due champion hire's reserve: exactly one unit per 20 s gets through.
## Speed (2026-10-02): the step-12 map fill (river, capture points, camps, beasts) is switched off in every part: no part
##   reads it, and its creatures / passes made each frame dearer (a CI on a saturated PC killed the run at the 2400 s
##   wall-clock limit in part trickle, about 6x its quiet 230-380 s). Each part prints its wall seconds and frames.
## Run:  godot --headless --path . -s tests/test_20_a2.gd --fixed-fps 60 --quit-after 60000
##   Options after `--`: --only=static,recovery,notrips,hardstop,trickle,starve

const TASK_ID := "20.A2"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const START_AT := 5.0
const PART_LIMIT := {"static": 30.0, "recovery": 60.0, "notrips": 220.0, "hardstop": 240.0, "trickle": 240.0,
		"starve": 420.0}
const STARVE_WINDOW := 100.0
const STARVE_CRYSTALS := 200

var main: Node
var bot: Node
var part := ""
var _queue: Array[String] = []
var _wait := 0
var _gap := 0
var _t := 0.0
var _errors: Array[String] = []
var _s := {}
var _part_usec := 0
var _part_frames := 0


func _initialize() -> void:
	# 20.A3: the Replay Lab's auto recorder off (docs/plan/replay-lab.md: tests turn it off; its session froze the
	# skirmish economy on 2026-09-26 22:00).
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	for p in ["static", "recovery", "notrips", "hardstop", "trickle", "starve"]:
		if only.is_empty() or only.has(p):
			_queue.append(p)
	_next_part()


# ---------------------------------------------------------------- scene handling

func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	part = _queue.pop_front()
	_wait = 0
	_s = {"stage": 0}
	_part_usec = Time.get_ticks_usec()
	_part_frames = 0
	main = load(SCENE).instantiate()
	for f: StringName in [&"river_enabled", &"points_enabled", &"camps_enabled", &"beasts_enabled"]:
		if f in main:
			main.set(f, false)   # no part reads the map fill (speed: see the header)
	bot = _bot_for(ENEMY)
	root.add_child(main)
	current_scene = main
	print("---- part %s" % part)


func _bot_for(team: int) -> Node:
	var b: Node = null
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			b = child
	if b == null:
		b = COMMANDER.new()
		b.team = team
		main.add_child(b)
	b.difficulty = 1
	var p := AIProfile.for_difficulty(1)
	p.launch_attacks = true   # a bot with attacks off never concedes (mission rule)
	b.profile = p
	b.profile_id = &""
	b.debug_log = false
	return b


func _end_part() -> void:
	print("%s: %.1f wall s, %d frames, match %s" % [part, float(Time.get_ticks_usec() - _part_usec) / 1.0e6,
			_part_frames, _clock(_t)])
	if bot:
		print("%s bot log (last lines):" % part)
		var lines: Array = bot.log_lines
		for i in range(maxi(0, lines.size() - 25), lines.size()):
			print("  " + str(lines[i]))
	main.queue_free()
	main = null
	bot = null
	_gap = 3


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_part()
		return false
	if main == null:
		return true
	_part_frames += 1
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_t = main.match_time()
	if not bot.get(&"_ready_done"):
		return false
	match part:
		"static":
			_static_part()
		"recovery":
			_recovery_part()
		"notrips":
			_notrips_part()
		"hardstop":
			_hardstop_part()
		"trickle":
			_trickle_part()
		"starve":
			_starve_part()
	if main != null and _t > float(PART_LIMIT[part]) + (float(_s.get("t0", 0.0))):
		_errors.append("%s: timed out at stage %d (%s)" % [part, int(_s["stage"]), _clock(_t)])
		_end_part()
	return false


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("  error: " + e)
		print("FAIL %s: %s" % [TASK_ID, _errors[0]])
	quit()


# ---------------------------------------------------------------- static (F4, earned_since)

func _static_part() -> void:
	var a := AITrade.new(ENEMY, PLAYER, AIProfile.normal())
	if not a.active():
		_errors.append("static: AITrade not active (no GoldBank?)")
		_end_part()
		return
	var cases := [
		# [home empty, pop_used, pop_cap, soldier_pop, want]
		[false, -1, -1, -1, 4],      # old call
		[false, 39, 40, 10, 2],      # capped, small army: 4 -> max(2, 2)
		[true, 38, 40, 17, 4],       # capped, small army, late: 6 -> 4
		[true, 38, 40, 18, 6],       # 18 = 45 % of 40: army big enough
		[true, 37, 40, 5, 6],        # not capped
		[false, 20, 20, 3, 2],       # capped at 20
	]
	for c: Array in cases:
		var got := a.caravan_target(bool(c[0]), int(c[1]), int(c[2]), int(c[3]))
		if got != int(c[4]):
			_errors.append("static: caravan_target%s = %d (want %d)" % [str(c.slice(0, 4)), got, int(c[4])])
	# earned_since from the bot's own samples (GoldBank.earned(&"trade")).
	var gb := GoldBank.for_team(ENEMY)
	var cu: Array[Unit] = []
	var bu: Array[Building] = []
	a.sense(100.0, null, 0.0, 0.0, cu, bu)
	gb.add(70, &"trade")
	a.sense(110.0, null, 0.0, 0.0, cu, bu)
	a.sense(200.0, null, 0.0, 0.0, cu, bu)
	if a.earned_since(105.0) != 70 or a.earned_since(80.0) != 70 or a.earned_since(150.0) != 0:
		_errors.append("static: earned_since 105 / 80 / 150 = %d / %d / %d (want 70 / 70 / 0)" % [a.earned_since(105.0),
				a.earned_since(80.0), a.earned_since(150.0)])
	if a.can_fund_comeback(200.0):
		_errors.append("static: can_fund_comeback without a Bazaar")
	print("static: F4 caravan targets and earned_since checked")
	_end_part()


# ---------------------------------------------------------------- recovery (F1)

func _recovery_part() -> void:
	var ta: AITrade = bot.trade_ai
	match int(_s["stage"]):
		0:
			if _t < START_AT:
				return
			_strip(true)
			if not _add_bazaar():
				_end_part()
				return
			for i in 3:
				_add_caravan(i)
			var gb := GoldBank.for_team(ENEMY)
			gb.add(600 - gb.gold, &"loot")
			_s["tick0"] = int(bot.tick_count)
			_s["t0"] = _t
			_s["stage"] = 1
			print("recovery: 0 workers, Bazaar, 3 caravans, 600 gold, 0 crystals at %s" % _clock(_t))
		1:
			var gb := GoldBank.for_team(ENEMY)
			var ticks := int(bot.tick_count) - int(_s["tick0"])
			if not _s.has("ex_tick") and ta.recovery_exchanges > 0:
				_s["ex_tick"] = ticks
				print("recovery: exchanged after %d tick(s): gold %d, crystals %d" % [ticks, gb.gold,
						Economy.for_team(ENEMY).crystals])
				if gb.gold >= 100:
					_errors.append("recovery: %d gold kept after the exchange (want < 100)" % gb.gold)
			if _s.has("ex_tick") and not _s.has("worker_tick") and _keep_workers_queued() > 0:
				_s["worker_tick"] = ticks
				print("recovery: worker queued after %d tick(s)" % ticks)
			if Market.caravan_count(ENEMY) > 3:
				_errors.append("recovery: a caravan was queued while recovering")
			if not gb.owned_wares.is_empty():
				_errors.append("recovery: a ware was bought while recovering")
			if bool(bot.recovering):
				_s["seen_recovering"] = true
			if _s.has("worker_tick") or ticks > 6:
				if not _s.has("seen_recovering"):
					_errors.append("recovery: the bot never went into recovery at 0 workers")
				if not _s.has("ex_tick") or int(_s["ex_tick"]) > 2:
					_errors.append("recovery: no exchange within 2 ticks (%s)" % str(_s.get("ex_tick", "none")))
				if not _s.has("worker_tick") or int(_s["worker_tick"]) > int(_s.get("ex_tick", 0)) + 2:
					_errors.append("recovery: no worker queued within 2 ticks of the exchange (%s)" % str(_s.get("worker_tick", "none")))
				if not _log_has("RECOVERY"):
					_errors.append("recovery: no RECOVERY log line")
				_end_part()


# ---------------------------------------------------------------- no trips for 120 s (F2)

func _notrips_part() -> void:
	match int(_s["stage"]):
		0:
			if _t < START_AT:
				return
			_strip(true)
			if not _add_bazaar():
				_end_part()
				return
			for i in 3:
				_add_caravan(i)
			var gb := GoldBank.for_team(ENEMY)
			gb.add(80 - gb.gold, &"trade")   # one trip's gold (under the 100 exchange step)
			_s["t0"] = _t
			_s["stage"] = 1
			print("notrips: 0 workers, 0 soldiers, Bazaar, 3 idle caravans, 80 gold from a trip at %s" % _clock(_t))
		1:
			_strip(false)
			var since := _t - float(_s["t0"])
			if main.game_over:
				print("notrips: conceded %.1f s after the last trip (%s, caravans %d, Bazaar %s, winner %d)" % [since,
						str(bot.concede_reason), Market.caravan_count(ENEMY), str(GoldBank.for_team(ENEMY).has_bazaar()),
						int(main.winner_team)])
				if since < 118.0:
					_errors.append("notrips: conceded %.1f s after a trip (want >= 120)" % since)
				if since > 132.0:
					_errors.append("notrips: conceded %.1f s after the last trip (want ~120)" % since)
				if str(bot.concede_reason) == "hard stop":
					_errors.append("notrips: the concede came from the hard stop, not the trade rule")
				if int(main.winner_team) != PLAYER:
					_errors.append("notrips: winner %d" % int(main.winner_team))
				_end_part()
			elif since > 140.0:
				_errors.append("notrips: no concede %.0f s after the last trip" % since)
				_end_part()


# ---------------------------------------------------------------- hard stop (F2)

func _hardstop_part() -> void:
	match int(_s["stage"]):
		0:
			if _t < START_AT or not _arm_hard_stop():
				return
			_strip(true)
			if not _add_bazaar():
				_end_part()
				return
			for i in 3:
				_add_caravan(i)
			var k: Node = main.keep_of(ENEMY)
			if k:
				(k as Building).take_damage(1.0e8, null)
			_s["t0"] = _t
			_s["stage"] = 1
			print("hardstop: no keep, 0 workers, 0 soldiers, Bazaar, 3 caravans, 300 gold kept at %s" % _clock(_t))
		1:
			_strip(false)
			var gb := GoldBank.for_team(ENEMY)
			if gb.gold != 300:
				gb.add(300 - gb.gold, &"loot")
			var since := _t - float(_s["t0"])
			if main.game_over:
				print("hardstop: conceded %.1f s after the start (%s, winner %d)" % [since, str(bot.concede_reason),
						int(main.winner_team)])
				if since < 140.0 or since > 156.0:
					_errors.append("hardstop: conceded after %.1f s (want 150)" % since)
				if str(bot.concede_reason) != "hard stop":
					_errors.append("hardstop: concede reason '%s'" % str(bot.concede_reason))
				_end_part()
			elif since > 165.0:
				_errors.append("hardstop: no concede %.0f s after 0 workers / 0 soldiers / 0 queued" % since)
				_end_part()


# ---------------------------------------------------------------- trickle (hard stop, 20.A2 run 16 stall)

## Keep + Bazaar + 3 caravans, 100 trade gold every 20 s (exchanged, a worker queued), every new worker dies before
## it delivers: queued units never stop the hard-stop clock -> "hard stop" 150 s after the last soldier / delivery.
func _trickle_part() -> void:
	match int(_s["stage"]):
		0:
			if _t < START_AT or not _arm_hard_stop():
				return
			_strip(true)
			if not _add_bazaar():
				_end_part()
				return
			for i in 3:
				_add_caravan(i)
			_s["t0"] = _t
			_s["next_gold"] = _t
			_s["stage"] = 1
			print("trickle: keep, Bazaar, 3 caravans, 100 trade gold every 20 s, every worker killed at %s" % _clock(_t))
		1:
			_strip(false, false)
			if _t >= float(_s["next_gold"]):
				_s["next_gold"] = float(_s["next_gold"]) + 20.0
				GoldBank.for_team(ENEMY).add(100, &"trade")
			if _log_has("(0 workers + 1 queued"):
				_s["queued_seen"] = true
			var since := _t - float(_s["t0"])
			if main.game_over:
				print("trickle: conceded %.1f s after the start (%s, workers queued meanwhile: %s)" % [since,
						str(bot.concede_reason), str(_s.has("queued_seen"))])
				if since < 140.0 or since > 156.0:
					_errors.append("trickle: conceded after %.1f s (want 150)" % since)
				if str(bot.concede_reason) != "hard stop":
					_errors.append("trickle: concede reason '%s'" % str(bot.concede_reason))
				if not _s.has("queued_seen"):
					_errors.append("trickle: the bot never queued a worker with the trade gold")
				_end_part()
			elif since > 165.0:
				_errors.append("trickle: no concede %.0f s after the last soldier / delivery" % since)
				_end_part()


# ---------------------------------------------------------------- 20 s rule (F5)

func _starve_part() -> void:
	var eco := Economy.for_team(ENEMY)
	var ca: AIChampions = bot.champion_ai
	match int(_s["stage"]):
		0:
			if ca == null or ca.hire_due == &"":
				return
			_s["t0"] = _t
			_s["passes0"] = (bot.starve_passes as Array).size()
			_s["trains0"] = _count_trains()
			_s["stage"] = 1
			print("starve: hire %s due at %s, crystals held at %d" % [ca.hire_due, _clock(_t), STARVE_CRYSTALS])
		1:
			if eco.crystals != STARVE_CRYSTALS:
				eco.add(STARVE_CRYSTALS - eco.crystals)
			if ca.hire_due == &"":
				_errors.append("starve: the hire stopped being due at %s" % _clock(_t))
				_end_part()
				return
			var passes: Array = (bot.starve_passes as Array).slice(int(_s["passes0"]))
			# The window starts at the first pass (the 20 s clock starts when the hire / a build began to wait).
			if passes.is_empty():
				if _t - float(_s["t0"]) > 60.0:
					_errors.append("starve: no unit through the reserve in 60 s")
					_end_part()
				return
			if not _s.has("w0"):
				_s["w0"] = float(passes[0])
				_s["trains0"] = _count_trains() - 1
			if _t - float(_s["w0"]) < STARVE_WINDOW:
				return
			var trains := _count_trains() - int(_s["trains0"])
			print("starve: %d unit(s) queued in %.0f s, passes at %s" % [trains, STARVE_WINDOW, str(passes)])
			for i in range(1, passes.size()):
				if float(passes[i]) - float(passes[i - 1]) < 19.5:
					_errors.append("starve: two passes %.1f s apart" % (float(passes[i]) - float(passes[i - 1])))
			if trains != passes.size():
				_errors.append("starve: %d units queued but %d passes (units slipped through the reserve)" % [trains,
						passes.size()])
			if passes.size() < 4 or passes.size() > 6:
				_errors.append("starve: %d passes in %.0f s (want one per 20 s)" % [passes.size(), STARVE_WINDOW])
			_end_part()


func _count_trains() -> int:
	var n := 0
	for l: String in bot.log_lines:
		if l.contains("] TRAIN "):
			n += 1
	return n


# ---------------------------------------------------------------- helpers

## Kills the bot's workers and soldiers (not the wizard, champions, caravans), cancels its training queues and
## empties its crystals. `first`: also its gold.
func _strip(first: bool, cancel_queues: bool = true) -> void:
	for b in Building.for_team(ENEMY):
		if cancel_queues and b is TrainingBuilding and not b is Market:
			var tb := b as TrainingBuilding
			while not tb.queue.is_empty():
				tb.cancel(tb.queue.size() - 1)
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != ENEMY or u is Wizard or u.is_in_group(&"champions") \
				or u.is_in_group(&"caravans") or u.is_in_group(&"trackers"):
			continue
		u.take_damage(1.0e6, null)
	var eco := Economy.for_team(ENEMY)
	if cancel_queues and eco.crystals > 0:
		eco.spend(eco.crystals)
	if first:
		var gb := GoldBank.for_team(ENEMY)
		if gb and gb.gold > 0:
			gb.spend(gb.gold)


## The hard stop is armed once the bot has had a soldier (or from 5:00): a Shade stands at the base until the bot's
## scan saw it (the strip kills it afterwards). True once armed.
func _arm_hard_stop() -> bool:
	if bool(bot.get(&"_had_soldier")):
		return true
	if not _s.has("arm_soldier"):
		var u: Unit = main.make_unit("shade")
		u.team = ENEMY as Unit.Team
		main.add_child(u)
		u.global_position = main.base_center(ENEMY) + Vector3(-8.0, 0.0, 8.0)
		u.command_stop()
		_s["arm_soldier"] = true
	return false


func _add_bazaar() -> bool:
	var type := BuildingType.find("shadow_market")
	if type == null:
		_errors.append("%s: no shadow_market type" % part)
		return false
	var near: Vector3 = main.call(&"market_slot", ENEMY) if main.has_method(&"market_slot") \
			else Vector3(45.0, 0.0, -27.0)
	# spawn_complete skips the "Needs a completed Hall" check: the slot is free at the start.
	main.build_grid.spawn_complete(type, near, ENEMY)
	if not GoldBank.for_team(ENEMY).has_bazaar():
		_errors.append("%s: the Bazaar is not seen as completed" % part)
		return false
	return true


func _add_caravan(i: int) -> void:
	var u: Unit = main.make_unit("caravan")
	u.team = ENEMY as Unit.Team
	main.add_child(u)
	u.global_position = main.base_center(ENEMY) + Vector3(-6.0 + 2.0 * i, 0.0, 6.0)
	u.command_stop()


func _keep_workers_queued() -> int:
	var k: Keep = main.keep_of(ENEMY)
	if k == null:
		return 0
	var n := 0
	for t in k.queue:
		if t.is_worker:
			n += 1
	return n


func _log_has(text: String) -> bool:
	for l: String in bot.log_lines:
		if l.contains(text):
			return true
	return false


static func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
