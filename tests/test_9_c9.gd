extends SceneTree
## Task 9.C9 (the bot hires, revives and places bounties; champions.md 10 "Done when" 9.C9), scenes/skirmish.tscn.
## Part 0 (instant): the champion knobs of easy / normal / hard (code presets and data/ai/*.tres agree),
##   AIChampions.revive_affordable (before / after items), AIMemory.strength_of(champion) = power().
## Parts normal / easy / hard: a Shadow bot (ENEMY) of that difficulty against an idle player. Attacks are off
##   (profile.launch_attacks = false) so the match lasts long enough to see every hire; everything else is the
##   difficulty's own profile. Every frame: no champion is ever in the bot's orders, soldiers, attack group or
##   scout; the roster never exceeds the difficulty's max.
##   normal: hires a Coin-Cutter between 3:00 and 5:00, then an Oathwall later, never more than 2; the
##     Coin-Cutter is killed: the bot revives it as soon as the essence allows and buys no item meanwhile
##     (revive before items); own_strength counts a champion at the rally with its power; a seen enemy
##     champion enters seen_strength with its power.
##   easy: hires one Oathwall, not before 6:00 (by 15:00); only Guard flags.
##   hard: hires Coin-Cutter, Mender, Wayfinder in that order, the first from 2:00; then the bounty phase
##     (essence given, item list emptied): B4 Explore 25 on an unseen enemy hall spot, B2 Hunt 100 on the nearest
##     of 3 seen enemy workers at a far node (never 2 at once), B1 Guard 50 on an intruded building, B3 Hunt 150
##     on Vessa below 40 % near a bot champion. Every flag fits the budget (active stakes + stake <=
##     pct x spare essence, at most max flags); the bot never removes a flag.
## PERF: the champion rule's median decision cost per think tick must stay < 0.1 ms ("PERF OK"; the average is
## printed too, it is noisy while other agents run).
## Run:  godot --headless --path . -s tests/test_9_c9.gd --fixed-fps 60 --quit-after 150000
##   Options after `--`: --only=static|normal|easy|hard (comma list)

const TASK_ID := "9.C9"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const RALLY := Vector3(30.0, 0.0, -30.0)
const H1 := Vector3(27.0, 0.0, -45.0)
const PART_LIMIT := 560.0            ## Game seconds the normal / hard hire parts may last (9:20).
## Easy has no upper bound in champions.md 10 ("1 after 6:00"): its hire needs crystals >= 225 + 150 on ~6
## workers while waiting builds (X1, V2, S2, Bazaar) come first, measured 8:01 to 11:11 at map-polish.
const EASY_LIMIT := 900.0            ## Game seconds the easy part may last (15:00).
const B4_NATURAL := 100.0            ## Bounty phase: seconds B4 gets to fire on its own (explore_unseen 90 + 10).
const B4_WAIT := 200.0               ## Bounty phase: seconds before "no B4" (the spot memory is aged after B4_NATURAL).
const PERF_LIMIT_MS := 0.1

var main: Node
var bot: Node
var part := ""
var _queue: Array[String] = []
var _wait := 0
var _gap := 0
var _t := 0.0
var _frame := 0
var _errors: Array[String] = []
var _notes: Array[String] = []
var _results: Array[String] = []
var _s := {}                         # per-part state
var _order_error := false


func _initialize() -> void:
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	if only.is_empty() or only.has("static"):
		_part0()
	for p in ["normal", "easy", "hard"]:
		if only.is_empty() or only.has(p):
			_queue.append(p)
	_next_part()


# ---------------------------------------------------------------- part 0

func _part0() -> void:
	var want := {
		0: {"max": 1, "order": ["oathwall"], "earliest": 360.0, "before": false, "pct": 1.0, "flags": 1, "guard": true,
				"unseen": 120.0},
		1: {"max": 2, "order": ["coin_cutter", "oathwall"], "earliest": 180.0, "before": true, "pct": 0.25, "flags": 2,
				"guard": false, "unseen": 120.0},
		2: {"max": 3, "order": ["coin_cutter", "mender", "wayfinder"], "earliest": 120.0, "before": true, "pct": 0.4,
				"flags": 3, "guard": false, "unseen": 90.0},
	}
	for d in 3:
		var profiles: Array = [AIProfile.for_difficulty(d)]
		for k in ["ice", "nature"]:
			var path := "res://data/ai/%s_%s.tres" % [k, AIProfile.DIFFICULTY_NAMES[d]]
			if ResourceLoader.exists(path):
				profiles.append(load(path))
			else:
				_errors.append("missing %s" % path)
		profiles.append(AIProfile.ice(d))
		profiles.append(AIProfile.nature(d))
		var w: Dictionary = want[d]
		for p: AIProfile in profiles:
			var tag := "%s (%s)" % [p.id, p.resource_path.get_file() if p.resource_path != "" else "code"]
			if p.champion_max != int(w["max"]) or Array(p.champion_order) != w["order"] \
					or not is_equal_approx(p.champion_earliest, float(w["earliest"])) \
					or p.revive_before_items != bool(w["before"]) or not is_equal_approx(p.bounty_budget_pct, float(w["pct"])) \
					or p.bounty_max_flags != int(w["flags"]) or p.bounty_guard_only != bool(w["guard"]) \
					or not is_equal_approx(p.explore_unseen, float(w["unseen"])):
				_errors.append("%s champion knobs: max %d, order %s, earliest %.0f, before %s, pct %.2f, flags %d, guard %s, unseen %.0f" % [
						tag, p.champion_max, str(p.champion_order), p.champion_earliest, str(p.revive_before_items),
						p.bounty_budget_pct, p.bounty_max_flags, str(p.bounty_guard_only), p.explore_unseen])
	if AIProfile.mission_01().champion_max != 0 or (load("res://data/ai/mission_01.tres") as AIProfile).champion_max != 0:
		_errors.append("mission_01 must never hire (champion_max 0)")
	# Revive before / after items.
	if not AIChampions.revive_affordable(90, 90, 150, true) or AIChampions.revive_affordable(89, 90, 0, true):
		_errors.append("revive_affordable before items wrong")
	if AIChampions.revive_affordable(200, 90, 150, false) or not AIChampions.revive_affordable(240, 90, 150, false) \
			or not AIChampions.revive_affordable(90, 90, 0, false):
		_errors.append("revive_affordable after items wrong")
	# A champion's strength = power() (L1 200).
	var ct: Resource = load("res://scripts/units/champion_type.gd").call(&"find", &"coin_cutter")
	if ct == null:
		_errors.append("no ChampionType coin_cutter")
	else:
		var ch: Node = load("res://scripts/units/champion.gd").new()
		ch.call(&"apply_champion_type", ct, 0)
		var s := AIMemory.strength_of(ch)
		if not is_equal_approx(s, float(ch.call(&"power"))) or not is_equal_approx(s, 200.0):
			_errors.append("strength_of(champion L1) = %.1f (want power() = 200)" % s)
		ch.free()
	print("part 0: champion knobs, revive rule and champion strength checked")


# ---------------------------------------------------------------- scene handling

func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	part = _queue.pop_front()
	_wait = 0
	_frame = 0
	_s = {"hires": [], "roster_max": 0}
	main = load(SCENE).instantiate()
	var d := {"easy": 0, "normal": 1, "hard": 2}[part] as int
	bot = _bot_for(ENEMY, d)
	root.add_child(main)
	current_scene = main


func _bot_for(team: int, difficulty: int) -> Node:
	var b: Node = null
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			b = child
	if b == null:
		b = COMMANDER.new()
		b.team = team
		main.add_child(b)
	b.difficulty = difficulty
	var p := AIProfile.for_difficulty(difficulty)
	p.launch_attacks = false
	b.profile = p
	b.profile_id = &""
	b.debug_log = false
	return b


func _end_part() -> void:
	var ca: Variant = bot.get(&"champion_ai")
	if ca != null:
		var avg: float = float(ca.usec_total) / maxf(1.0, float(ca.tick_count)) / 1000.0
		var ms: float = ca.median_ms()
		var line := "%s: champion rule median %.4f ms, avg %.4f ms over %d ticks; bot tick avg %.3f ms (max %.3f ms)" % [
				part, ms, avg, ca.tick_count, bot.tick_usec_average() / 1000.0, bot.tick_usec_max / 1000.0]
		print(line)
		if ms > PERF_LIMIT_MS:
			_errors.append("%s: champion rule median %.3f ms per tick (limit %.2f)" % [part, ms, PERF_LIMIT_MS])
		else:
			print("PERF OK (%s)" % part)
		print("%s bot log (champions / bounties):" % part)
		for l in bot.log_lines:
			if l.contains("CHAMPION") or l.contains("BOUNTY"):
				print("  " + l)
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
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	_t = main.match_time()
	if not bot.get(&"_ready_done"):
		return false
	_common_checks()
	match part:
		"normal":
			_normal_tick()
		"easy":
			_easy_tick()
		"hard":
			_hard_tick()
	return false


## Every frame: roster size, hires, and no champion ever in the bot's hands.
func _common_checks() -> void:
	var g: Node = _guild(ENEMY)
	if g:
		_s["roster_max"] = maxi(int(_s["roster_max"]), int(g.call(&"roster_size")))
	var ca: Variant = bot.get(&"champion_ai")
	if ca != null:
		for h: Dictionary in ca.hires:
			if not (_s["hires"] as Array).has(h):
				(_s["hires"] as Array).append(h)
				print("[%s] %s hire #%d %s (%s) at %d:%02d" % [part, part, (_s["hires"] as Array).size(), h["id"],
						h["name"], int(h["time"]) / 60, int(h["time"]) % 60])
	if _order_error or _frame % 5 != 0:
		return
	var orders: Dictionary = bot.get(&"_orders")
	var group: Array = bot.get(&"_group")
	var soldiers: Array = bot.get(&"_soldiers")
	var scout: Variant = bot.get(&"_scout")
	for node in get_nodes_in_group("champions"):
		if int(node.get(&"team")) != ENEMY:
			continue
		var bad := ""
		if orders.has(node.get_instance_id()):
			bad = "in _orders"
		elif group.has(node):
			bad = "in the attack group"
		elif soldiers.has(node):
			bad = "in _soldiers"
		elif scout != null and is_instance_valid(scout) and scout == node:
			bad = "the scout"
		if bad != "":
			_order_error = true
			_errors.append("%s: bot champion %s %s at %.0f s" % [part, node.name, bad, _t])


func _guild(team: int) -> Node:
	for node in get_nodes_in_group("champion_guilds"):
		if int(node.get(&"team")) == team:
			return node
	return null


func _bank(team: int) -> Node:
	for node in get_nodes_in_group("essence_banks"):
		if int(node.get(&"team")) == team:
			return node
	return null


func _board(team: int) -> Node:
	for node in get_nodes_in_group("bounty_boards"):
		if int(node.get(&"team")) == team:
			return node
	return null


func _set_essence(team: int, amount: int) -> void:
	var bank: Node = _bank(team)
	var have := int(bank.get(&"essence"))
	if have > amount:
		bank.call(&"spend", have - amount)
	elif have < amount:
		bank.call(&"add", amount - have)


func _hire_time(id: StringName) -> float:
	for h: Dictionary in _s["hires"]:
		if StringName(h["id"]) == id:
			return float(h["time"])
	return -1.0


func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


# ---------------------------------------------------------------- normal

func _normal_tick() -> void:
	var g: Node = _guild(ENEMY)
	var ca: Variant = bot.get(&"champion_ai")
	var cc: Node = g.call(&"champion_of", &"coin_cutter") if g else null
	var stage := int(_s.get("stage", 0))
	match stage:
		0:   # wait for the Coin-Cutter to walk out, 10 s
			if cc != null and cc.call(&"is_alive") and not _s.has("cc_out"):
				_s["cc_out"] = _t
			if _s.has("cc_out") and _t - float(_s["cc_out"]) >= 10.0:
				# Revive before items: essence 1 below the revive cost; an unheld bot could buy a cheaper item.
				var cost := int(g.call(&"revive_cost", cc))
				_set_essence(ENEMY, cost - 1)
				_s["bought_before"] = (bot.items.bought as Array).size() if bot.items else 0
				_s["item_price"] = _item_price()
				cc.call(&"take_damage", 1.0e6, null)
				_s["killed_at"] = _t
				_s["stage"] = 1
				print("[normal] Coin-Cutter killed at %s, essence %d (revive %d, next item %d)" % [_clock(_t), cost - 1,
						cost, _s["item_price"]])
		1:   # the revive
			if cc != null and g.call(&"is_reviving", cc):
				var bought := (bot.items.bought as Array).size() if bot.items else 0
				print("[normal] revive paid at %s (%.1f s after the death), items bought meanwhile %d" % [_clock(_t),
						_t - float(_s["killed_at"]), bought - int(_s["bought_before"])])
				if bought != int(_s["bought_before"]):
					_errors.append("normal: the wizard bought an item while a revive waited (revive before items)")
				if _t - float(_s["killed_at"]) > 6.0:
					_errors.append("normal: revive %.1f s after the essence allowed it" % (_t - float(_s["killed_at"])))
				_s["stage"] = 2
			elif _t - float(_s["killed_at"]) > 30.0:
				_errors.append("normal: no revive 30 s after the death")
				_s["stage"] = 2
		2:   # the champion back: own_strength counts it at the rally
			if cc != null and cc.call(&"is_alive"):
				cc.global_position = RALLY + Vector3(1.5, 0.0, 1.0)
				_s["tick_at"] = int(bot.tick_count)
				_s["stage"] = 3
		3:
			if int(bot.tick_count) > int(_s["tick_at"]):
				var want := _expected_own_strength()
				print("[normal] own_strength %.1f, expected %.1f (soldiers + champions within 20 m of the rally)" % [
						bot.own_strength, want])
				if absf(float(bot.own_strength) - want) > 1.0:
					_errors.append("normal: own_strength %.1f, expected %.1f with the champion at the rally" % [
							bot.own_strength, want])
				_s["stage"] = 4
		4:   # wait for the Oathwall (later), then 20 s
			var ow_t := _hire_time(&"oathwall")
			if ow_t >= 0.0 and _t - ow_t >= 20.0:
				_s["stage"] = 5
		5:   # an enemy (player) champion seen by the bot counts its power in seen_strength
			# Spawned straight at the bot's rally (not hired): by now the bot's own champions may legitimately
			# stand at both tavern doors (Coin-Cutter lurking at one, a fresh hire at the other), and the
			# player's guild then refuses with "Enemies hold both taverns" (champions.md 2 "Held").
			print("[normal] tavern doors at %s:" % _clock(_t))
			_print_doors()
			var ct: Resource = load("res://scripts/units/champion_type.gd").call(&"find", &"wayfinder")
			if ct == null:
				_errors.append("normal: no ChampionType wayfinder for the seen_strength check")
				_s["stage"] = 7
			else:
				var pch: Node3D = ct.call(&"create_champion", 0)
				pch.set(&"team", PLAYER)
				main.add_child(pch)
				pch.global_position = RALLY + Vector3(-3.0, 0.0, 3.0)
				pch.call(&"command_stop")
				_s["p_ch"] = pch
				_s["p_at"] = _t
				_s["stage"] = 6
		6:
			var pch: Node = _s["p_ch"]
			var entry: Dictionary = bot.memory.units.get(pch.get_instance_id(), {}) if is_instance_valid(pch) else {}
			if not entry.is_empty():
				var power := float(pch.call(&"power"))
				print("[normal] seen enemy champion strength %.1f (power %.1f), seen_strength %.1f" % [
						float(entry["strength"]), power, bot.seen_strength])
				if not is_equal_approx(float(entry["strength"]), power) or float(bot.seen_strength) < power - 0.5:
					_errors.append("normal: seen enemy champion strength %.1f, power %.1f, seen_strength %.1f" % [
							float(entry["strength"]), power, bot.seen_strength])
				_s["stage"] = 7
			elif _t - float(_s["p_at"]) > 4.0:
				_errors.append("normal: the enemy champion at the rally never entered the bot's memory")
				_s["stage"] = 7
	if int(_s.get("stage", 0)) < 7 and _t < PART_LIMIT and not main.game_over:
		return
	var cc_t := _hire_time(&"coin_cutter")
	var ow_t := _hire_time(&"oathwall")
	var hires: Array = _s["hires"]
	_results.append("normal: hires %s at %s, roster max %d, flags %d" % [str(hires.map(func(h): return h["id"])),
			str(hires.map(func(h): return _clock(h["time"]))), int(_s["roster_max"]), (ca.flags as Array).size()])
	if hires.is_empty() or StringName(hires[0]["id"]) != &"coin_cutter" or cc_t < 180.0 or cc_t > 300.0:
		_errors.append("normal: first hire %s at %.0f s (want a Coin-Cutter between 3:00 and 5:00)" % [
				hires[0]["id"] if not hires.is_empty() else "none", cc_t])
	if ow_t < 0.0 or ow_t <= cc_t:
		_errors.append("normal: Oathwall hire at %.0f s (want after the Coin-Cutter at %.0f s)" % [ow_t, cc_t])
	if int(_s["roster_max"]) > 2 or hires.size() > 2 or int(ca.max_roster) > 2:
		_errors.append("normal: more than 2 champions (roster max %d, hires %d)" % [int(_s["roster_max"]), hires.size()])
	if int(_s.get("stage", 0)) < 7:
		_errors.append("normal: stopped at stage %d at %.0f s" % [int(_s.get("stage", 0)), _t])
	_check_flags("normal", ca)
	_end_part()


## Diagnostics: every non-worker unit within the hold radius of each tavern door.
func _print_doors() -> void:
	for t in get_nodes_in_group("taverns"):
		var door: Vector3 = t.call(&"door_point")
		var who: Array[String] = []
		for node in get_nodes_in_group("units"):
			var u := node as Unit
			if u == null or not u.is_alive() or u.is_worker():
				continue
			var d := Vector2(u.global_position.x - door.x, u.global_position.z - door.z).length()
			if d <= 12.0:
				who.append("%s team %d %.1f m%s" % [u.unit_name, int(u.team), d,
						" (%s)" % str(u.get(&"intent")) if u.is_in_group(&"champions") else ""])
		print("  door %s held for player %s: %s" % [str(door), str(t.call(&"is_held_by_enemy_of", PLAYER)), str(who)])


## Bot soldiers' strength (the Commander's _scan rules) + its champions within 20 m of the rally.
func _expected_own_strength() -> float:
	var s := 0.0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != ENEMY or Commander.is_scripted(u):
			continue
		if not u.is_commandable():
			var d := Vector2(u.global_position.x - RALLY.x, u.global_position.z - RALLY.z).length()
			if d <= AIChampions.STRENGTH_RADIUS:
				s += float(u.call(&"power"))
			continue
		if u is Worker or u is Wizard or AICasts.is_summon(u):
			continue
		s += AIMemory.strength_of(u)
	return s


func _item_price() -> int:
	if bot.items == null:
		return 0
	var inv: Object = AIItems.inventory_of(main.wizard_of(ENEMY))
	if inv == null:
		return 0
	var p: Dictionary = bot.items.next_purchase(inv)
	return 0 if p.is_empty() else int(bot.items.price(inv, p["type"]))


# ---------------------------------------------------------------- easy

func _easy_tick() -> void:
	var ca: Variant = bot.get(&"champion_ai")
	var hires: Array = _s["hires"]
	if (hires.is_empty() or _t - float(hires[0]["time"]) < 30.0) and _t < EASY_LIMIT and not main.game_over:
		return
	_results.append("easy: hires %s at %s, roster max %d, flags %s" % [str(hires.map(func(h): return h["id"])),
			str(hires.map(func(h): return _clock(h["time"]))), int(_s["roster_max"]),
			str((ca.flags as Array).map(func(f): return f["rule"]))])
	if hires.is_empty() or StringName(hires[0]["id"]) != &"oathwall" or float(hires[0]["time"]) < 360.0:
		_errors.append("easy: first hire %s at %s (want an Oathwall from 6:00)" % [
				hires[0]["id"] if not hires.is_empty() else "none", _clock(hires[0]["time"]) if not hires.is_empty() else "-"])
	if int(_s["roster_max"]) > 1 or hires.size() > 1:
		_errors.append("easy: more than 1 champion")
	for f: Dictionary in ca.flags:
		if f["rule"] != "B1":
			_errors.append("easy placed a %s flag (Guard flags only)" % f["rule"])
	_check_flags("easy", ca)
	_end_part()


# ---------------------------------------------------------------- hard + the bounty phase

func _hard_tick() -> void:
	var ca: Variant = bot.get(&"champion_ai")
	var stage := int(_s.get("stage", 0))
	var board: Node = _board(ENEMY)
	match stage:
		0:   # the three hires
			var alive := 0
			var g: Node = _guild(ENEMY)
			var roster: Array = g.get(&"champions") if g else []
			for ch in roster:
				if is_instance_valid(ch) and ch.call(&"is_alive"):
					alive += 1
			if (_s["hires"] as Array).size() >= 3 and alive >= 3:
				_s["stage"] = 1
			elif _t >= PART_LIMIT:
				_errors.append("hard: only %d hires by %s" % [(_s["hires"] as Array).size(), _clock(_t)])
				_s["stage"] = 99
		1:   # bounty phase setup: essence, no item list, the board cleared
			_s["natural_flags"] = (ca.flags as Array).size()
			if bot.items:
				bot.items.build = PackedStringArray()
			_set_essence(ENEMY, 3000)
			board.connect(&"bounty_ended", func(_b: Variant, reason: StringName) -> void:
				if reason == &"removed":
					_s["removed_seen"] = int(_s.get("removed_seen", 0)) + 1)
			_clear_board(board)
			_s["phase_at"] = _t
			_s["stage"] = 2
			print("[hard] bounty phase at %s (%d flags placed before)" % [_clock(_t), int(_s["natural_flags"])])
		2:   # B4: an enemy hall spot unseen for 90 s -> Explore 25 (it may already have fired in play)
			if _rule_count(ca, "B4") > 0:
				print("[hard] B4 at %s, %.0f s into the bounty phase%s" % [_clock(_t), _t - float(_s["phase_at"]),
						" (spot memory aged by the test)" if _s.has("b4_aged") else ""])
				_s["stage"] = 3
			elif _t - float(_s["phase_at"]) > B4_WAIT:
				_errors.append("hard: no B4 Explore flag %.0f s into the bounty phase (spot memory aged from %.0f s)" % [
						B4_WAIT, B4_NATURAL])
				_s["stage"] = 3
			else:
				_age_b4_spots(ca)
		3:   # B2: 3 enemy workers at the player's natural node, seen through a sight marker
			_set_essence(ENEMY, 3000)
			_clear_board(board)
			var node: Node3D = main.node_of(PLAYER, "mid")
			var at: Vector3 = node.global_position if node else Vector3(-16.0, 0.0, 6.0)
			var workers: Array = []
			for i in 3:
				var w: Unit = main.make_unit("cinder_hand")
				w.team = PLAYER
				main.add_child(w)
				w.global_position = at + Vector3(2.5 * cos(i * 2.1), 0.0, 2.5 * sin(i * 2.1))
				w.command_stop()
				workers.append(w)
			_s["workers"] = workers
			_s["marker"] = SightMarker.spawn(ENEMY, at, 14.0, 0.0, main)
			_s["b2_before"] = _rule_count(ca, "B2")
			_s["b2_at"] = _t
			_s["stage"] = 4
		4:
			if _rule_count(ca, "B2") > int(_s["b2_before"]):
				var f: Dictionary = _last_flag(ca, "B2")
				if not (_s["workers"] as Array).has(f["target"]) or f["kind"] != 0 or f["stake"] != 100:
					_errors.append("hard: B2 flag %s %d on %s (want Hunt 100 on one of the 3 workers)" % [
							f["kind"], f["stake"], str(f["target"])])
				_s["b2_first"] = f["bounty"]
				_s["b2_seen"] = _t
				_s["stage"] = 5
			elif _t - float(_s["b2_at"]) > 6.0:
				_errors.append("hard: no B2 flag with 3 seen workers at a far node")
				_s["stage"] = 6
		5:   # never a second raid flag while the first is active
			var first: Variant = _s["b2_first"]
			if _rule_count(ca, "B2") > int(_s["b2_before"]) + 1 and first != null and is_instance_valid(first) \
					and not first.get(&"ended"):
				_errors.append("hard: a second B2 flag while the first is active (max 1)")
			if _t - float(_s["b2_seen"]) >= 3.0:
				_s["stage"] = 6
		6:   # clean up, then B1 + B3
			for w in _s.get("workers", []):
				if is_instance_valid(w):
					w.queue_free()
			if _s.get("marker") != null and is_instance_valid(_s["marker"]):
				(_s["marker"] as Node).queue_free()
			_set_essence(ENEMY, 3000)
			_clear_board(board)
			var host: Node3D = null
			var g: Node = _guild(ENEMY)
			for ch in g.get(&"champions"):
				if is_instance_valid(ch) and ch.call(&"is_alive"):
					host = ch
					break
			var intruder: Unit = main.make_unit("flame_guard")
			intruder.team = PLAYER
			main.add_child(intruder)
			intruder.global_position = H1 + Vector3(-7.0, 0.0, 0.0)
			intruder.command_stop()
			var vessa: Unit = main.wizard_of(PLAYER)
			if host != null and vessa != null and vessa.is_alive():
				vessa.global_position = host.global_position + Vector3(4.0, 0.0, 0.0)
				vessa.command_stop()
				vessa.take_damage(maxf(0.0, vessa.hp - 0.3 * vessa.max_hp), null)
			else:
				_errors.append("hard: no living bot champion / Vessa for B3")
			_s["b1_before"] = _rule_count(ca, "B1")
			_s["b3_before"] = _rule_count(ca, "B3")
			_s["b13_at"] = _t
			_s["vessa"] = vessa
			_s["stage"] = 7
		7:
			var b1 := _rule_count(ca, "B1") > int(_s["b1_before"])
			var b3 := _rule_count(ca, "B3") > int(_s["b3_before"])
			if (b1 and b3) or _t - float(_s["b13_at"]) > 12.0:
				if not b1:
					_errors.append("hard: no B1 Guard flag on the intruded base")
				else:
					var f: Dictionary = _last_flag(ca, "B1")
					if f["kind"] != 2 or f["stake"] != 50 or not f["target"] is Building \
							or int((f["target"] as Building).team) != ENEMY:
						_errors.append("hard: B1 flag %s %d (want Guard 50 on a bot building)" % [f["kind"], f["stake"]])
				if not b3:
					_errors.append("hard: no B3 Hunt flag on Vessa at 30 % HP near a champion")
				else:
					var f: Dictionary = _last_flag(ca, "B3")
					if f["kind"] != 0 or f["stake"] != 150 or f["target"] != _s["vessa"]:
						_errors.append("hard: B3 flag %s %d on %s (want Hunt 150 on Vessa)" % [f["kind"], f["stake"],
								str(f["target"])])
				_s["stage"] = 99
	if stage != 99:
		return
	var hires: Array = _s["hires"]
	var ids: Array = hires.map(func(h): return String(h["id"]))
	_results.append("hard: hires %s at %s, roster max %d, flags %s" % [str(ids),
			str(hires.map(func(h): return _clock(h["time"]))), int(_s["roster_max"]),
			str((ca.flags as Array).map(func(f): return "%s@%s" % [f["rule"], _clock(f["time"])]))])
	if ids.slice(0, 3) != ["coin_cutter", "mender", "wayfinder"]:
		_errors.append("hard: hire order %s (want coin_cutter, mender, wayfinder)" % str(ids))
	if hires.is_empty() or float(hires[0]["time"]) < 120.0:
		_errors.append("hard: first hire before 2:00")
	if int(_s["roster_max"]) > 3:
		_errors.append("hard: more than 3 champions")
	_check_flags("hard", ca)
	var removed := int(_s.get("removed_seen", 0))
	if removed != int(_s.get("removed_by_test", 0)):
		_errors.append("hard: %d flags removed but the test removed %d (the bot must never remove one)" % [removed,
				int(_s.get("removed_by_test", 0))])
	_end_part()


## B4 depends on the bot's own vision: its champions and caravans may keep BOTH enemy hall spots in sight (the
## Coin-Cutter often camps at the idle player's natural hall spot, and the rich one at (-33, -33) is passed on
## the way from the (-15, -15) tavern), and then no Explore flag is due by the rule. Natural first: a spot out of
## sight at the phase start qualifies within explore_unseen (90 s). After B4_NATURAL s without a flag, the test
## ages the rule's spot memory (AIChampions._spot_seen) every 5 s, so the next think tick flags the first spot
## that is out of sight right then; spots still in sight are refreshed by the rule itself.
func _age_b4_spots(ca: Variant) -> void:
	var waited := _t - float(_s["phase_at"])
	if waited < B4_NATURAL or _frame % 300 != 0:
		return
	var seen: Variant = ca.get(&"_spot_seen")
	if not seen is Array or (seen as Array).is_empty():
		_errors.append("hard: AIChampions._spot_seen missing (the B4 check ages the rule's spot memory)")
		_s["stage"] = 3
		return
	var old := _t - float(bot.ai.explore_unseen) - 1.0
	for i in (seen as Array).size():
		seen[i] = minf(float(seen[i]), old)
	_s["b4_aged"] = true


func _clear_board(board: Node) -> void:
	for b in (board.get(&"bounties") as Array).duplicate():
		board.call(&"remove", b)
		_s["removed_by_test"] = int(_s.get("removed_by_test", 0)) + 1


func _rule_count(ca: Variant, rule: String) -> int:
	var n := 0
	for f: Dictionary in ca.flags:
		if f["rule"] == rule:
			n += 1
	return n


func _last_flag(ca: Variant, rule: String) -> Dictionary:
	var out := {}
	for f: Dictionary in ca.flags:
		if f["rule"] == rule:
			out = f
	return out


## Every flag the bot placed fit its budget and the flag limit, with the stake of its rule.
func _check_flags(tag: String, ca: Variant) -> void:
	var ai: AIProfile = bot.ai
	var stakes := {"B1": 50, "B2": 100, "B3": 150, "B4": 25, "B5": 50, "B6": 75, "B7": 50}   # B5-B7: step 10
	for f: Dictionary in ca.flags:
		if int(f["active_before"]) + int(f["stake"]) > float(f["budget"]) + 0.01:
			_errors.append("%s: %s flag over budget (%d + %d > %.1f)" % [tag, f["rule"], f["active_before"], f["stake"],
					f["budget"]])
		if int(f["stake"]) != int(stakes[f["rule"]]):
			_errors.append("%s: %s stake %d" % [tag, f["rule"], f["stake"]])
		if not is_equal_approx(float(f["budget"]), ai.bounty_budget_pct * float(f["surplus"])):
			_errors.append("%s: %s budget %.1f is not %.2f x %d" % [tag, f["rule"], f["budget"], ai.bounty_budget_pct,
					f["surplus"]])
		if f["rule"] == "B4":
			var spots: Array[Vector3] = [main.natural_hall_spot(PLAYER), main.rich_hall_spot(PLAYER)]
			var ok := false
			for p in spots:
				if Vector2(p.x - (f["pos"] as Vector3).x, p.z - (f["pos"] as Vector3).z).length() < 1.0:
					ok = true
			if not ok or f["kind"] != 1:
				_errors.append("%s: B4 flag at %s is not an Explore on an enemy hall spot" % [tag, str(f["pos"])])
	var board: Node = _board(ENEMY)
	if board and (board.get(&"bounties") as Array).size() > ai.bounty_max_flags:
		_errors.append("%s: %d flags up (max %d)" % [tag, (board.get(&"bounties") as Array).size(), ai.bounty_max_flags])


# ---------------------------------------------------------------- end

func _finish() -> void:
	for n in _notes:
		print("note: " + n)
	for r in _results:
		print(r)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()
