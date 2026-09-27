extends SceneTree
## Task 10.A3 (bot rule 10, trade; market-trade.md 7 and "Done when" 10.A3), scenes/skirmish.tscn.
## Part static: the trade knobs of easy / normal / hard (code presets, ice() / nature(), data/ai/*.tres agree),
##   mission_01 never trades; AITrade "behind" (10b: seen > 1.5 x own for 60 s from 4:00 -> the Bazaar before
##   trade_start, caravan target +1) on a stand-alone AITrade.
## Parts normal / easy / hard: a Shadow bot (ENEMY) of that difficulty against an idle player (attacks off, like
##   test_9_c9, so the match lasts; at most 10 soldiers so pop stays free for caravans). Every few frames: no
##   caravan in the bot's soldiers / orders / attack group; caravans (alive + queued) never above the target.
##   normal: Bazaar placed at M1 (45, -27) between 5:30 and 7:00; 4 caravans; gold from trade; then (the test acts)
##     a loaded caravan on the default route is robbed -> Outriders at once and the route switches to the other near
##     post; wares bought in the normal order (Axles at 3+ caravans, Charter, Steel, Gambesons); gold above 450 is
##     exchanged; a fallen champion with essence short is revived in gold; a raid on the natural node -> a Spire at
##     S3 (19, -1); the Coin-Cutter's Raid default targets a looting Magpie within 30 m (ChampionBrain); the bot
##     does not concede while it has caravans or a Bazaar, and concedes once both are gone.
##   easy: Bazaar not before 8:00; at most 2 caravans; a robbery hires nothing; only the Masons' Charter is bought,
##     surplus gold above 200 is exchanged.
##   hard: Bazaar from 4:30 (before 6:00); 3 caravans sent far when ahead; B5 Escort on a loaded far caravan; B6
##     Hunt on a looting Magpie near a champion; Sweep for a Magpie on an unguarded spot; B7 Guard on the forward
##     hall + an S3 Spire after a raid; wares in the hard order; a hire paid in gold.
## PERF: the trade rule's median decision cost per think tick < 0.1 ms ("PERF OK").
## Run:  godot --headless --path . -s tests/test_10_a3.gd --fixed-fps 60 --quit-after 200000
##   Options after `--`: --only=static|normal|easy|hard (comma list)

const TASK_ID := "10.A3"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const NEUTRAL := 2
const M1 := Vector3(45.0, 0.0, -27.0)
const S3 := Vector3(19.0, 0.0, -1.0)
const A3M := Vector3(48.0, 0.0, 22.0)
const PERF_LIMIT_MS := 0.1
const PART_LIMIT := {"normal": 1080.0, "easy": 780.0, "hard": 1080.0}   ## game seconds per part at most

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
var _s := {}


func _initialize() -> void:
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	if only.is_empty() or only.has("static"):
		_static_checks()
	for p in ["normal", "easy", "hard"]:
		if only.is_empty() or only.has(p):
			_queue.append(p)
	_next_part()


# ---------------------------------------------------------------- static

func _static_checks() -> void:
	var want := {
		0: {"start": 480.0, "target": 2, "late": 3, "far": 0, "ratio": 0.0, "wares": ["masons_charter"], "axles": 0,
				"outriders": false, "sweep": false, "revive": false, "hire": false, "exchange": 200, "flags": []},
		1: {"start": 330.0, "target": 4, "late": 6, "far": 2, "ratio": 1.5,
				"wares": ["iron_axles", "masons_charter", "tempered_steel", "gambesons"], "axles": 3,
				"outriders": true, "sweep": false, "revive": true, "hire": false, "exchange": 450, "flags": ["B5"]},
		2: {"start": 270.0, "target": 6, "late": 6, "far": 3, "ratio": 1.2,
				"wares": ["tempered_steel", "iron_axles", "gambesons", "masons_charter"], "axles": 0,
				"outriders": true, "sweep": true, "revive": true, "hire": true, "exchange": 600, "flags": ["B5", "B6", "B7"]},
	}
	for d in 3:
		var profiles: Array = [AIProfile.for_difficulty(d), AIProfile.ice(d), AIProfile.nature(d)]
		for k in ["ice", "nature"]:
			var path := "res://data/ai/%s_%s.tres" % [k, AIProfile.DIFFICULTY_NAMES[d]]
			if ResourceLoader.exists(path):
				profiles.append(load(path))
			else:
				_errors.append("missing %s" % path)
		var w: Dictionary = want[d]
		for p: AIProfile in profiles:
			var tag := "%s (%s)" % [p.id, p.resource_path.get_file() if p.resource_path != "" else "code"]
			var bad: Array[String] = []
			if not p.trade:
				bad.append("trade off")
			if not is_equal_approx(p.trade_start, float(w["start"])):
				bad.append("trade_start %.0f" % p.trade_start)
			if p.caravan_target != int(w["target"]) or p.caravan_target_late != int(w["late"]):
				bad.append("caravans %d / %d" % [p.caravan_target, p.caravan_target_late])
			if p.far_route_caravans != int(w["far"]) or not is_equal_approx(p.far_route_ratio, float(w["ratio"])):
				bad.append("far %d ratio %.2f" % [p.far_route_caravans, p.far_route_ratio])
			if Array(p.ware_order) != w["wares"] or p.axles_min_caravans != int(w["axles"]):
				bad.append("wares %s (axles at %d)" % [str(p.ware_order), p.axles_min_caravans])
			if p.hire_outriders != bool(w["outriders"]) or p.hire_sweep != bool(w["sweep"]):
				bad.append("hunters %s / %s" % [str(p.hire_outriders), str(p.hire_sweep)])
			if p.gold_revive != bool(w["revive"]) or p.gold_hire != bool(w["hire"]):
				bad.append("gold revive %s hire %s" % [str(p.gold_revive), str(p.gold_hire)])
			if p.gold_exchange_above != int(w["exchange"]) or Array(p.trade_flags) != w["flags"]:
				bad.append("exchange %d flags %s" % [p.gold_exchange_above, str(p.trade_flags)])
			if not bad.is_empty():
				_errors.append("%s trade knobs: %s" % [tag, ", ".join(bad)])
	if AIProfile.mission_01().trade or (load("res://data/ai/mission_01.tres") as AIProfile).trade:
		_errors.append("mission_01 must never trade")
	print("part static: trade knobs checked")


## 10b on a stand-alone AITrade (needs the scene's GoldBank to be active).
func _behind_checks() -> void:
	var cu: Array[Unit] = []
	var bu: Array[Building] = []
	var a := AITrade.new(ENEMY, PLAYER, AIProfile.normal())
	if not a.active():
		_errors.append("AITrade not active in the skirmish (no GoldBank?)")
		return
	a.sense(230.0, null, 100.0, 400.0, cu, bu)
	a.sense(245.0, null, 100.0, 400.0, cu, bu)
	if a.behind:
		_errors.append("behind before 60 s")
	a.sense(304.0, null, 100.0, 400.0, cu, bu)
	if not a.behind or not a.bazaar_due(304.0, true) or a.bazaar_due(304.0, false):
		_errors.append("behind 10b: behind %s, due %s (hall) / %s (no hall) at 5:04" % [str(a.behind),
				str(a.bazaar_due(304.0, true)), str(a.bazaar_due(304.0, false))])
	if a.caravan_target(false) != 5 or a.caravan_target(true) != 6:
		_errors.append("behind caravan targets %d / %d (want 5 / 6)" % [a.caravan_target(false), a.caravan_target(true)])
	var b := AITrade.new(ENEMY, PLAYER, AIProfile.normal())
	b.sense(304.0, null, 400.0, 400.0, cu, bu)
	if b.behind or b.bazaar_due(320.0, true) or not b.bazaar_due(330.0, true) or b.caravan_target(false) != 4:
		_errors.append("not behind: due at 5:20 %s, at 5:30 %s, target %d" % [str(b.bazaar_due(320.0, true)),
				str(b.bazaar_due(330.0, true)), b.caravan_target(false)])
	if b.bazaar_crystals(175) != 275:
		_errors.append("bazaar_crystals(175) = %d (want 275)" % b.bazaar_crystals(175))
	print("behind checks done")


# ---------------------------------------------------------------- scene handling

func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	part = _queue.pop_front()
	_wait = 0
	_frame = 0
	_s = {"stage": 0, "max_caravans": 0, "behind_at": -INF}
	main = load(SCENE).instantiate()
	var d := {"easy": 0, "normal": 1, "hard": 2}[part] as int
	bot = _bot_for(ENEMY, d)
	root.add_child(main)
	current_scene = main
	print("---- part %s" % part)


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
	p.max_soldiers = 10
	b.profile = p
	b.profile_id = &""
	b.debug_log = false
	return b


func _end_part() -> void:
	var ta: Variant = bot.get(&"trade_ai") if bot else null
	if ta != null:
		var ms: float = ta.median_ms()
		var avg: float = float(ta.usec_total) / maxf(1.0, float(ta.tick_count)) / 1000.0
		print("%s: trade rule median %.4f ms, avg %.4f ms over %d ticks; bot tick avg %.3f ms (max %.3f ms)" % [part,
				ms, avg, ta.tick_count, bot.tick_usec_average() / 1000.0, bot.tick_usec_max / 1000.0])
		if ms > PERF_LIMIT_MS:
			_errors.append("%s: trade rule median %.3f ms per tick (limit %.2f)" % [part, ms, PERF_LIMIT_MS])
		else:
			print("PERF OK (%s)" % part)
		var want := {"normal": 4, "easy": 2, "hard": 6}[part] as int
		if int(_s["max_caravans"]) < want:
			_errors.append("%s: at most %d caravans (want %d)" % [part, int(_s["max_caravans"]), want])
		var gb := GoldBank.for_team(ENEMY)
		if gb:
			print("%s: gold earned %d (trade %d), wares %s, contracts %d, exchanges %d, max caravans %d" % [part,
					gb.earned(), gb.earned(&"trade"), str(gb.owned_wares), (ta.contracts as Array).size(),
					(ta.exchanges as Array).size(), int(_s["max_caravans"])])
	if bot:
		print("%s bot log (trade):" % part)
		for l: String in bot.log_lines:
			if l.contains("TRADE") or l.contains("M1") or l.contains("S3") or l.contains("Caravan") \
					or l.contains("gold") or l.contains("B5") or l.contains("B6") or l.contains("B7") \
					or l.contains("CONCEDE"):
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
	if _frame == 1 and part == "normal":
		_behind_checks()
	_common_checks()
	if main.game_over and not _s.has("concede_armed"):
		_errors.append("%s: the match ended at %s (winner %d)" % [part, _clock(_t), int(main.winner_team)])
		_end_part()
		return false
	match part:
		"normal":
			_normal_tick()
		"easy":
			_easy_tick()
		"hard":
			_hard_tick()
	if main != null and _t > float(PART_LIMIT[part]):
		_errors.append("%s: timed out at stage %d (%s)" % [part, int(_s["stage"]), _clock(_t)])
		_end_part()
	return false


## Every few frames: caravans never in the bot's army / orders, never above the target.
func _common_checks() -> void:
	if _frame % 10 != 0:
		return
	var ta: AITrade = bot.trade_ai
	if ta == null:
		return
	if ta.behind:
		_s["behind_at"] = _t
	var count := Market.caravan_count(ENEMY)
	_s["max_caravans"] = maxi(int(_s["max_caravans"]), count)
	var target := ta.caravan_target(_home_empty())
	if count > target and _t - float(_s["behind_at"]) > 30.0 and not _s.has("no_count_check"):
		_errors.append("%s: %d caravans (alive + queued) above the target %d at %s" % [part, count, target, _clock(_t)])
		_s["no_count_check"] = true
	if _s.has("caravan_leak"):
		return
	var orders: Dictionary = bot.get(&"_orders")
	var group: Array = bot.get(&"_group")
	var soldiers: Array = bot.get(&"_soldiers")
	for node in get_nodes_in_group("caravans"):
		if int(node.get(&"team")) != ENEMY:
			continue
		var bad := ""
		if soldiers.has(node):
			bad = "in _soldiers"
		elif group.has(node):
			bad = "in the attack group"
		elif orders.has(node.get_instance_id()):
			bad = "in _orders"
		if bad != "":
			_s["caravan_leak"] = true
			_errors.append("%s: caravan %s %s at %s" % [part, node.name, bad, _clock(_t)])


func _home_empty() -> bool:
	for suffix in ["a", "b"]:
		var n: Variant = main.call(&"node_of", ENEMY, suffix)
		if n != null and is_instance_valid(n) and not (n as CrystalNode).is_depleted():
			return false
	return true


# ---------------------------------------------------------------- helpers

func _ta() -> AITrade:
	return bot.trade_ai


func _gb() -> GoldBank:
	return GoldBank.for_team(ENEMY)


func _set_gold(n: int) -> void:
	var gb := _gb()
	if gb:
		gb.add(n - gb.gold)


func _set_essence(n: int) -> void:
	var bank := EssenceBank.for_team(ENEMY)
	if bank == null:
		return
	if bank.essence > n:
		bank.spend(bank.essence - n)
	elif bank.essence < n:
		bank.add(n - bank.essence)


func _guild() -> Node:
	for node in get_nodes_in_group("champion_guilds"):
		if int(node.get(&"team")) == ENEMY:
			return node
	return null


func _board() -> Node:
	for node in get_nodes_in_group("bounty_boards"):
		if int(node.get(&"team")) == ENEMY:
			return node
	return null


func _clear_flags() -> void:
	var board: Node = _board()
	if board == null:
		return
	for b: Variant in (board.get(&"bounties") as Array).duplicate():
		board.call(&"remove", b)


func _net() -> TradeNetwork:
	return TradeNetwork.instance(self)


func _hunters() -> HuntersGuild:
	return HuntersGuild.instance(self)


func _caravans_alive() -> Array:
	var out: Array = []
	for node in get_nodes_in_group("caravans"):
		if int(node.get(&"team")) == ENEMY and (node as Unit).is_alive():
			out.append(node)
	return out


func _has_contract(kind: StringName, since: float) -> bool:
	for c: Dictionary in _ta().contracts:
		if c["kind"] == kind and float(c["time"]) >= since - 0.01:
			return true
	return false


func _has_flag(rule: String, since: float) -> bool:
	for f: Dictionary in bot.champion_ai.flags:
		if f["rule"] == rule and float(f["time"]) >= since - 0.01:
			return true
	return false


func _living_champion() -> Node3D:
	for node in get_nodes_in_group("champions"):
		if int(node.get(&"team")) == ENEMY and (node as Unit).is_alive():
			return node
	return null


func _spawn_magpie(pos: Vector3, loot: int) -> Unit:
	var type := UnitType.find("magpie")
	if type == null:
		_errors.append("%s: no magpie UnitType" % part)
		return null
	var m := Worker.make_unit(type)
	m.team = NEUTRAL as Unit.Team
	m.add_to_group(&"magpies")
	m.set_meta(&"loot", loot)
	main.add_child(m)
	m.global_position = pos
	m.command_stop()
	return m


## Magpies leave like the guild's do (leave_map: no death, no loot); a plain free would leave dangling targets.
func _remove_magpie(m: Variant) -> void:
	if m != null and is_instance_valid(m) and (m as Unit).is_alive():
		(m as Unit).leave_map()


func _tower_near(p: Vector3, r: float) -> bool:
	for b in Building.for_team(ENEMY):
		if b.building_type and b.building_type.kind == &"tower" and Vector2(b.global_position.x - p.x,
				b.global_position.z - p.z).length() <= r:
			return true
	return false


func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _stage(n: int) -> void:
	_s["stage"] = n
	_s["since"] = _t


func _since() -> float:
	return _t - float(_s.get("since", _t))


## Common timeline: the Bazaar placement window, position, first gold. True once the Bazaar is up with
## `min_caravans` caravans alive and trade gold earned.
func _trade_running(lo: float, hi: float, min_caravans: int) -> bool:
	var ta := _ta()
	if ta == null:
		return false
	if not _s.has("placed") and not ta.bazaar_placed.is_empty():
		var at := float(ta.bazaar_placed[0])
		_s["placed"] = at
		var site: Node3D = null
		for node in get_nodes_in_group("markets"):
			if int(node.get(&"team")) == ENEMY:
				site = node
		var d := Vector2(site.global_position.x - M1.x, site.global_position.z - M1.z).length() if site else INF
		print("[%s] Bazaar placed at %s, %.1f m from M1" % [part, _clock(at), d])
		if at < lo or at > hi:
			_errors.append("%s: Bazaar placed at %s (want %s - %s)" % [part, _clock(at), _clock(lo), _clock(hi)])
		if d > 6.0:
			_errors.append("%s: Bazaar %.1f m from M1" % [part, d])
	if not _s.has("placed") and _t > hi + 1.0:
		_errors.append("%s: no Bazaar by %s" % [part, _clock(hi)])
		_s["placed"] = -1.0
	if not _s.has("gold_at") and _gb() and _gb().earned(&"trade") > 0:
		_s["gold_at"] = _t
		print("[%s] first trade gold at %s" % [part, _clock(_t)])
	if not _s.has("c4") and _caravans_alive().size() >= 4:
		_s["c4"] = _t
		print("[%s] 4 caravans at %s" % [part, _clock(_t)])
	return Market.of_team(ENEMY) != null and _caravans_alive().size() >= min_caravans and _s.has("gold_at")


# ---------------------------------------------------------------- normal

func _normal_tick() -> void:
	var ta := _ta()
	match int(_s["stage"]):
		0:
			if _trade_running(330.0, 420.0, 3) and _t >= 300.0:
				_stage(1)
		1:   # rob a loaded caravan on the current route (the default unless the Magpies struck first)
			var m := Market.of_team(ENEMY)
			var def := m.route_post
			_s["default"] = def
			if def != m.default_route():
				if ta.losses.is_empty():
					_errors.append("normal: route %s is not the default %s before any loss" % [
							AITrade.post_name(def), AITrade.post_name(m.default_route())])
				else:
					_notes.append("normal: route already off the default after %d natural losses" % ta.losses.size())
			for c in _caravans_alive():
				var cv := c as Caravan
				if cv.cargo > 0 and cv.route_post == def:
					_set_gold(130)
					_s["rob_at"] = _t
					var got := cv.steal(cv.cargo, null)
					print("[normal] robbed %d gold from a caravan on %s at %s (gold 130)" % [got,
							AITrade.post_name(def), _clock(_t)])
					_stage(2)
					break
			if int(_s["stage"]) == 1 and _since() > 120.0:
				_errors.append("normal: no loaded caravan on the default route for 120 s")
				_stage(2)
				_s["rob_at"] = _t
		2:   # Outriders at once
			if _has_contract(&"outriders", float(_s["rob_at"])):
				print("[normal] Outriders hired %.1f s after the robbery" % _since())
				_stage(3)
			elif _since() > 5.0:
				var why := _hunters().can_hire(ENEMY, &"outriders")
				if (why == HuntersGuild.R_RUNNING or why == HuntersGuild.R_COOLDOWN) and _has_contract(&"outriders", 0.0):
					_notes.append("normal: Outriders already hired after an earlier natural loss (%s)" % why)
				else:
					_errors.append("normal: no Outriders 5 s after a robbery (gold %d, reason '%s')" % [_gb().gold, why])
				_stage(3)
		3:   # the route leaves the robbed post
			var def: Node3D = _s["default"]
			var m := Market.of_team(ENEMY)
			if m.route_post != def:
				print("[normal] route switched to %s %.1f s after the robbery" % [AITrade.post_name(m.route_post),
						_t - float(_s["rob_at"])])
				_stage(4)
			elif _since() > 40.0:
				var other_unsafe := false
				for p in _net().posts():
					if p != def and not m.is_far_post(p) and ta.is_unsafe(p, bot.memory):
						other_unsafe = true
				if other_unsafe:
					_notes.append("normal: route kept on the default (the other near post was unsafe too)")
				else:
					_errors.append("normal: route not switched 40 s after a robbery on the default post")
				_stage(4)
		4:   # wares in order
			if _wares_stage(["iron_axles", "masons_charter", "tempered_steel", "gambesons"]):
				_stage(5)
		5:   # exchange above 450
			if _since() < 0.1:
				_set_gold(700)
				_s["n_ex"] = ta.exchanges.size()
			elif ta.exchanges.size() > int(_s["n_ex"]):
				var e: Dictionary = ta.exchanges[ta.exchanges.size() - 1]
				print("[normal] exchanged %d gold -> %s, gold now %d" % [int(e["gold"]), e["to"], _gb().gold])
				if _gb().gold > 549 or _gb().gold < 450:
					_errors.append("normal: gold %d after the exchange (want 450-549)" % _gb().gold)
				_stage(6)
			elif _since() > 5.0:
				_errors.append("normal: no exchange with 700 gold")
				_stage(6)
		6:   # gold revive
			if _revive_stage():
				_stage(7)
		7:   # raid on the natural node -> S3 Spire
			if _raid_stage(false):
				_stage(8)
		8:   # the Coin-Cutter's Raid default goes for a looting Magpie (no flags up)
			if _looter_stage():
				_stage(9)
		9:
			_concede_stage()


## ChampionBrain (10.A3): a visible Magpie carrying loot within 30 m of the Coin-Cutter becomes its Raid target.
func _looter_stage() -> bool:
	var g: Node = _guild()
	var cc: Node3D = g.call(&"champion_of", &"coin_cutter") if g else null
	if not _s.has("lt_at"):
		if cc == null or not is_instance_valid(cc) or not (cc as Unit).is_alive():
			if _since() > 60.0:
				_notes.append("normal: no living Coin-Cutter for the looter check")
				return true
			return false
		_clear_flags()
		_s["lt_m"] = _spawn_magpie(cc.global_position + Vector3(4.0, 0.0, 4.0), 30)
		_s["lt_at"] = _t
		return false
	var m: Variant = _s["lt_m"]
	var brain: Variant = cc.get(&"brain") if cc != null and is_instance_valid(cc) else null
	var target: Variant = brain.call(&"plan_node") if brain != null else null
	if m == null or not is_instance_valid(m) or not (m as Unit).is_alive():
		_notes.append("normal: the looting Magpie died before the Coin-Cutter's choice could be seen")
		return true
	if target == m or (cc != null and is_instance_valid(cc) and (cc as Unit).attack_target == m):
		print("[normal] Coin-Cutter goes for the looting Magpie %.1f s after it showed (intent %s)" % [
				_t - float(_s["lt_at"]), str(cc.get(&"intent"))])
		_remove_magpie(m)
		return true
	if _t - float(_s["lt_at"]) > 8.0:
		_errors.append("normal: the Coin-Cutter ignored a looting Magpie 8 s (intent %s)" % str(cc.get(&"intent")))
		if m != null and is_instance_valid(m):
			_remove_magpie(m)
		return true
	return false


## Tops the gold up for the next ware until every ware of `order` is owned; checks the order. True when done.
func _wares_stage(order: Array) -> bool:
	var ta := _ta()
	var gb := _gb()
	if not _s.has("ware_start"):
		_s["ware_start"] = ta.wares.size()
		_s["ware_topped"] = -INF
	if _caravans_alive().size() < 3 and order.has("iron_axles") and not gb.owns_ware(&"iron_axles"):
		if _since() > 90.0:
			_errors.append("%s: fewer than 3 caravans for the Axles gate" % part)
			return true
		return false
	var all := true
	for id: String in order:
		if not gb.owns_ware(StringName(id)):
			all = false
	if all:
		var bought: Array = []
		for w: Dictionary in ta.wares:
			bought.append(String(w["id"]))
		print("[%s] wares bought in order %s" % [part, str(bought)])
		if bought != order:
			_errors.append("%s: wares bought %s, want %s" % [part, str(bought), str(order)])
		return true
	var next := ta.next_ware()
	if next != &"" and gb.gold < GoldBank.ware_price(next) + 50 and _t - float(_s["ware_topped"]) > 2.0:
		_set_gold(GoldBank.ware_price(next) + 60)
		_s["ware_topped"] = _t
	if _since() > 90.0:
		_errors.append("%s: wares not all bought after 90 s (owned %s)" % [part, str(gb.owned_wares)])
		return true
	return false


## Kills a living champion with the essence short and the gold ready: the bot revives it in gold.
func _revive_stage() -> bool:
	var g: Node = _guild()
	var ca: AIChampions = bot.champion_ai
	if not _s.has("rev_ch"):
		var ch := _living_champion()
		if ch == null:
			if _since() > 60.0:
				_notes.append("%s: no living champion for the gold revive check" % part)
				return true
			return false
		_s["rev_ch"] = ch
		_s["rev_n"] = ca.gold_revives.size()
		var price := int(g.call(&"revive_cost", ch, true))
		_set_essence(0)
		_set_gold(price + 20)
		ch.call(&"take_damage", 1.0e6, null)
		_s["rev_at"] = _t
		print("[%s] %s killed at %s, essence 0, gold %d (revive %d gold)" % [part, ch.name, _clock(_t), price + 20, price])
		return false
	if ca.gold_revives.size() > int(_s["rev_n"]):
		var r: Dictionary = ca.gold_revives[ca.gold_revives.size() - 1]
		print("[%s] revived in gold (%d) %.1f s after the death" % [part, int(r["gold"]), _t - float(_s["rev_at"])])
		return true
	if _t - float(_s["rev_at"]) > 6.0:
		_errors.append("%s: no gold revive 6 s after the death (gold %d)" % [part, _gb().gold])
		return true
	return false


## A raid recorded on the natural node: a Spire at S3 (hard: also B7 Guard 50 on the forward hall).
func _raid_stage(check_b7: bool) -> bool:
	var node: Variant = main.call(&"natural_node", ENEMY)
	if not _s.has("raid_at"):
		if node == null or not is_instance_valid(node) or (node as CrystalNode).is_depleted():
			_notes.append("%s: natural node gone: no raid check" % part)
			return true
		if check_b7:
			_clear_flags()
			_set_essence(3000)
		Economy.for_team(ENEMY).add(500)
		_s["raid_at"] = _t
		_net().record_workers_raided(ENEMY, node)
		print("[%s] raid recorded on the natural node at %s" % [part, _clock(_t)])
		return false
	if check_b7 and not _s.has("b7") and _has_flag("B7", float(_s["raid_at"])):
		_s["b7"] = _t
		print("[%s] B7 Guard on the forward hall %.1f s after the raid" % [part, _t - float(_s["raid_at"])])
	if not _s.has("s3") and _tower_near(S3, 6.0):
		_s["s3"] = _t
		print("[%s] S3 Spire placed %.1f s after the raid" % [part, _t - float(_s["raid_at"])])
	if _s.has("s3") and (_s.has("b7") or not check_b7):
		return true
	if _t - float(_s["raid_at"]) > 150.0:
		if not _s.has("s3"):
			_errors.append("%s: no Spire at S3 150 s after a raid" % part)
		if check_b7 and not _s.has("b7"):
			_errors.append("%s: no B7 Guard flag after a raid" % part)
		return true
	return false


## No concede while caravans / a Bazaar remain; concede once both are gone.
func _concede_stage() -> void:
	var sub := int(_s.get("cs", 0))
	match sub:
		0:
			(bot.ai as AIProfile).launch_attacks = true   # a bot with attacks off never concedes (mission rule)
			_strip_enemy()
			_s["cs"] = 1
			_s["cs_at"] = _t
		1:
			_strip_enemy()
			if main.game_over:
				_errors.append("normal: conceded with caravans and a Bazaar left")
				_stage(99)
				_end_part()
				return
			if _t - float(_s["cs_at"]) > 6.0:
				print("[normal] no concede with %d caravans and a Bazaar (6 s)" % _caravans_alive().size())
				if _caravans_alive().is_empty():
					_notes.append("normal: no caravan alive at the concede check")
				_s["concede_armed"] = true
				for c in _caravans_alive():
					(c as Unit).take_damage(1.0e6, null)
				for node in get_nodes_in_group("markets"):
					if int(node.get(&"team")) == ENEMY:
						(node as Building).take_damage(1.0e7, null)
				_s["cs"] = 2
				_s["cs_at"] = _t
		2:
			_strip_enemy()
			if main.game_over:
				print("[normal] conceded %.1f s after the caravans and the Bazaar fell (winner %d)" % [
						_t - float(_s["cs_at"]), int(main.winner_team)])
				if int(main.winner_team) != PLAYER:
					_errors.append("normal: winner %d after the concede" % int(main.winner_team))
				_stage(99)
				_end_part()
			elif _t - float(_s["cs_at"]) > 6.0:
				_errors.append("normal: no concede 6 s after the caravans and the Bazaar fell")
				_stage(99)
				_end_part()


## Workers, soldiers, halls (barracks), crystals, gold, queues of the bot: all gone.
func _strip_enemy() -> void:
	var eco := Economy.for_team(ENEMY)
	for b in Building.for_team(ENEMY):
		if b is TrainingBuilding:
			var tb := b as TrainingBuilding
			while not tb.queue.is_empty():
				tb.cancel(tb.queue.size() - 1)
		if b.building_type and b.building_type.kind == &"barracks" and b.is_alive():
			b.take_damage(1.0e7, null)
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != ENEMY or u is Wizard or u.is_in_group(&"champions") \
				or u.is_in_group(&"caravans") or u.is_in_group(&"trackers"):
			continue
		u.take_damage(1.0e6, null)
	if eco.crystals > 0:
		eco.spend(eco.crystals)
	_set_gold(0)


# ---------------------------------------------------------------- easy

func _easy_tick() -> void:
	var ta := _ta()
	match int(_s["stage"]):
		0:
			if _trade_running(480.0, 580.0, 2):
				_stage(1)
		1:   # a robbery hires nothing
			for c in _caravans_alive():
				var cv := c as Caravan
				if cv.cargo > 0:
					_set_gold(300)
					_s["rob_at"] = _t
					cv.steal(cv.cargo, null)
					_stage(2)
					break
			if int(_s["stage"]) == 1 and _since() > 120.0:
				_notes.append("easy: no loaded caravan to rob")
				_stage(3)
		2:
			if not ta.contracts.is_empty():
				_errors.append("easy: hired %s" % str(ta.contracts))
				_stage(3)
			elif _since() > 5.0:
				print("[easy] no contract after a robbery")
				_stage(3)
		3:   # only the Charter
			if _since() < 0.1:
				_set_gold(500)
			elif _gb().owns_ware(&"masons_charter"):
				print("[easy] Masons' Charter bought %.1f s after gold 500" % _since())
				_stage(4)
			elif _since() > 10.0:
				_errors.append("easy: no Masons' Charter with 500 gold (owned %s)" % str(_gb().owned_wares))
				_stage(4)
		4:   # nothing else, surplus above 200 exchanged
			if _since() < 0.1:
				_set_gold(800)
			elif _since() > 8.0:
				if _gb().owned_wares.size() != 1:
					_errors.append("easy: wares %s (only the Charter)" % str(_gb().owned_wares))
				if _gb().gold > 299 or ta.exchanges.is_empty():
					_errors.append("easy: gold %d after the exchange window (exchanges %d)" % [_gb().gold, ta.exchanges.size()])
				else:
					print("[easy] gold %d after the exchanges %s" % [_gb().gold, str(ta.exchanges)])
				_stage(99)
				_end_part()


# ---------------------------------------------------------------- hard

func _hard_tick() -> void:
	var ta := _ta()
	match int(_s["stage"]):
		0:
			if _trade_running(270.0, 360.0, 4):
				_stage(1)
		1:   # 3 caravans far while ahead
			if ta.far_caravans().size() >= 3:
				print("[hard] %d caravans far to %s at %s (own %.0f vs seen %.0f)" % [ta.far_caravans().size(),
						AITrade.post_name(ta.far_post()), _clock(_t), bot.own_strength, bot.seen_strength])
				for c in ta.far_caravans():
					if not Market.of_team(ENEMY).is_far_post((c as Caravan).route_post):
						_errors.append("hard: a far caravan's route %s is not far" % AITrade.post_name((c as Caravan).route_post))
				_stage(2)
			elif _since() > 240.0:
				_errors.append("hard: %d far caravans after 240 s (own %.0f vs seen %.0f, caravans %d)" % [
						ta.far_caravans().size(), bot.own_strength, bot.seen_strength, _caravans_alive().size()])
				_stage(2)
		2:   # B5 Escort on a loaded far caravan
			if not _s.has("b5_at"):
				if ta.far_loaded_caravan() != null:
					_clear_flags()
					_set_essence(3000)
					_s["b5_at"] = _t
			elif _has_flag("B5", float(_s["b5_at"])):
				print("[hard] B5 Escort on a far caravan %.1f s after it loaded" % (_t - float(_s["b5_at"])))
				_stage(3)
			elif _t - float(_s["b5_at"]) > 10.0:
				_errors.append("hard: no B5 Escort flag on a loaded far caravan")
				_stage(3)
			if int(_s["stage"]) == 2 and _since() > 200.0:
				_errors.append("hard: no loaded far caravan in 200 s")
				_stage(3)
		3:   # B6 Hunt on a looter near a champion
			if not _s.has("b6_at"):
				var ch := _living_champion()
				if ch == null:
					if _since() > 60.0:
						_notes.append("hard: no living champion for B6")
						_stage(4)
					return
				_clear_flags()
				_set_essence(3000)
				_s["b6_m"] = _spawn_magpie(ch.global_position + Vector3(3.0, 0.0, 3.0), 40)
				_s["b6_at"] = _t
			elif _has_flag("B6", float(_s["b6_at"])):
				print("[hard] B6 Hunt on a looting Magpie %.1f s after it showed" % (_t - float(_s["b6_at"])))
				_stage(4)
			elif _t - float(_s["b6_at"]) > 5.0:
				_errors.append("hard: no B6 Hunt flag on a looting Magpie near a champion")
				_stage(4)
		4:   # Sweep for a Magpie lurking on an unguarded spot
			if not _s.has("sw_at"):
				var old: Variant = _s.get("b6_m")
				if old != null and is_instance_valid(old):
					_remove_magpie(old)
				_set_gold(300)   # Sweep 100 even if Outriders (120) come first; below the next ware's 400
				SightMarker.spawn(ENEMY, A3M, 10.0, 20.0, main)
				_s["sw_m"] = _spawn_magpie(A3M, 0)
				_s["sw_at"] = _t
			elif _has_contract(&"sweep", float(_s["sw_at"])):
				print("[hard] Sweep hired %.1f s after a Magpie showed at A3m" % (_t - float(_s["sw_at"])))
				_stage(5)
			elif _t - float(_s["sw_at"]) > 5.0:
				_errors.append("hard: no Sweep for a Magpie at A3m (gold %d, reason '%s', seen %d)" % [_gb().gold,
						_hunters().can_hire(ENEMY, &"sweep"), ta.magpies_seen()])
				_stage(5)
		5:   # raid: B7 + S3
			var m: Variant = _s.get("sw_m")
			if m != null and is_instance_valid(m):
				_remove_magpie(m)
			if _raid_stage(true):
				_stage(6)
		6:   # wares in the hard order
			if _wares_stage(["tempered_steel", "iron_axles", "gambesons", "masons_charter"]):
				_stage(7)
		7:   # a hire paid in gold
			var g: Node = _guild()
			var ca: AIChampions = bot.champion_ai
			if not _s.has("gh_at"):
				var ch := _living_champion()
				if ch == null or g == null:
					if _since() > 60.0:
						_notes.append("hard: no champion to dismiss for the gold hire")
						_stage(99)
						_end_part()
					return
				g.call(&"dismiss", ch)
				_set_essence(3000)
				var cost: Dictionary = g.call(&"hire_cost", &"", true)
				_s["gh_price"] = int(cost["gold"])
				_set_gold(int(cost["gold"]) + 230)   # hunters may take 120 first; stays below the 600 exchange line
				_s["gh_n"] = ca.gold_hires.size()
				_s["gh_at"] = _t
				print("[hard] dismissed %s at %s, gold %d" % [ch.name, _clock(_t), _gb().gold])
			elif ca.gold_hires.size() > int(_s["gh_n"]):
				print("[hard] hire paid in gold %.1f s later: %s" % [_t - float(_s["gh_at"]), str(ca.gold_hires.back())])
				_stage(8)
			elif _gb().gold < int(_s["gh_price"]) + 110:
				_set_gold(int(_s["gh_price"]) + 230)
			elif _t - float(_s["gh_at"]) > 10.0:
				_errors.append("hard: no gold hire 10 s after a dismissal (gold %d, due %s)" % [_gb().gold, ca.hire_due])
				_stage(8)
		8:   # the 6 caravans of hard
			if int(_s["max_caravans"]) >= 6 or _since() > 240.0:
				print("[hard] %d caravans (alive + queued) at most, at %s" % [int(_s["max_caravans"]), _clock(_t)])
				_stage(99)
				_end_part()


# ---------------------------------------------------------------- end

func _finish() -> void:
	for n in _notes:
		print("NOTE: " + n)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("ERROR: " + e)
		print("FAIL %s: %d error(s)" % [TASK_ID, _errors.size()])
	quit(0 if _errors.is_empty() else 1)
