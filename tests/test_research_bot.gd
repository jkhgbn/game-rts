extends SceneTree
## UR.A1 (docs/design/unit-upgrades.md 12 "Bots"): the bot researches the unit rows at its training buildings
## (AIResearch, scripts/ai/ai_research.gd, called by Commander rule 5 in place of the bowman call).
## Phase 1 "rules" (a skirmish without bots, AIResearch driven by hand on the Fire side):
## - the count rule (pop 1 needs 3 units, hard one less), the table order (next open row);
## - easy buys only tier-1 rows and at most 2; normal buys a tier-2 row;
## - not delaying: a wanted "+" keeps the last free Hall and its price; a due Forge keeps its cost; a due keep upgrade
##   keeps its cost (TIER_LOOKAHEAD s before the bot timeline);
## Phase 2 "bots" (a fresh skirmish, sim mode, easy Commander vs hard Commander, until 15:00 or game over):
## - hard starts >= 3 rows by 15:00; easy only tier-1 rows, <= 2; the hard Stronghold comes by BOT_START + 180 s.
##   A match that ends before 15:00 with hard under 3 rows is INCONCLUSIVE on the PASS line (no full 15 minutes).
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_research_bot.gd --fixed-fps 60 --quit-after 120000
##   [-- phase=rules|bots] [pair=shadow:fire (team 0 easy : team 1 hard)] [log=0|1] [full] [ur_off (baseline times; the row checks fail)]
## Early stop: the bots phase ends as soon as hard has 3 rows and the clock passed 6:00 (easy's checks can only
## fail through a buy, and its cap is enforced by the rule); `full` runs to 15:00.
# error_lab: quit-after=120000

const TASK_ID := "research_bot"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const SIM_MODE_PATH := "res://scripts/core/sim_mode.gd"
const SIM_STRIP_NAMES: Array[String] = ["SpellVfx", "CombatVfx", "IceVfx", "NatureVfx", "ChampionVfx", "TradeVfx",
		"MapFillVfx", "TitanVfx", "UnitVfx", "GameAudio", "Horizon"]
const PLAYER := 0
const LIMIT := 900.0
const EARLY_AFTER := 360.0
const STRONGHOLD_SLACK := 180.0

var main: Node
var _errors: Array[String] = []
var _checks := 0
var _phase := ""
var _kingdoms: Array[String] = ["shadow", "fire"]
var _log_team := -1
var _full := false
var _sample := -1
var _inconclusive := ""
var _blocked := {}   # diagnostics: half-seconds the hard bot's rule 5 skipped research (a champion hire waits)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		if s == "full":
			_full = true
		if s == "ur_off":   # diagnostics: the same bots without research (compare the Stronghold / Forge times)
			UnitResearch.lab_off = true
		var kv := s.split("=", true, 1)
		if kv.size() < 2:
			continue
		match kv[0]:
			"phase":
				_phase = kv[1]
			"pair":
				var p := kv[1].split(":")
				_kingdoms = [p[0], p[1]]
			"log":
				_log_team = int(kv[1])
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	if _phase == "" or _phase == "rules":
		await _rules()
		if main != null and is_instance_valid(main):
			main.queue_free()
			current_scene = null
			main = null
			await _frames(10)
	if _errors.is_empty() and (_phase == "" or _phase == "bots"):
		await _bots()
	_finish()


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s (%d checks)%s" % [TASK_ID, _checks, "" if _inconclusive == "" else " (INCONCLUSIVE: %s)" % _inconclusive])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 20))])
	quit(0 if _errors.is_empty() else 1)


func _make_level(with_bots: bool) -> Array:
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", StringName(_kingdoms[0]) if with_bots else &"fire")
	main.set(&"enemy_kingdom", StringName(_kingdoms[1]) if with_bots else &"shadow")
	main.set(&"time_limit_s", 0.0)
	if not with_bots:
		main.set(&"camps_enabled", false)
		main.set(&"beasts_enabled", false)
	var commander_script := load(COMMANDER_PATH) as Script
	var bots: Array = [null, null]
	for child in main.get_children():
		if with_bots and SIM_STRIP_NAMES.has(String(child.name)):
			main.remove_child(child)
			child.free()
		elif child.get_script() == commander_script:
			if with_bots:
				bots[int(child.get(&"team"))] = child
			else:
				main.remove_child(child)
				child.free()
	if with_bots:
		for team in [0, 1]:
			if bots[team] == null:
				var b: Node = commander_script.new()
				b.name = "ResearchBot%d" % team
				b.set(&"team", team)
				main.add_child(b)
				bots[team] = b
			bots[team].set(&"difficulty", 0 if team == 0 else 2)
			bots[team].set(&"debug_log", team == _log_team)
	root.add_child(main)
	current_scene = main
	if with_bots:
		for key: StringName in [&"hud", &"camera_rig", &"selection"]:
			var n: Variant = main.get(key)
			if n is Node and is_instance_valid(n):
				(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
	return bots


func _wait_start() -> bool:
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the skirmish never started")
			return false
	return true


# ---------------------------------------------------------------- phase 1: the rule, by hand

func _rules() -> void:
	print("---- phase rules")
	_make_level(false)
	if not await _wait_start():
		return
	await _frames(5)
	var keep: Node3D = main.call(&"keep_of", PLAYER)
	var grid: BuildGrid = main.get(&"build_grid")
	var eco := Economy.for_team(PLAYER)
	var ts := TierSystem.instance()
	var bank := UnitResearch.for_team(PLAYER)
	_ok(keep != null and grid != null and eco != null and ts != null and bank != null, "level pieces")
	if not _errors.is_empty():
		return
	var hall_type := BuildingType.find("fire_barracks")
	var hall := _spawn(grid, hall_type, keep, 14.0, 0.0)
	_ok(hall != null, "Hall spawned")
	if hall == null:
		return
	await _physics(2)
	eco.crystals = 3000
	var now := 10.0

	# The count rule: 2 Flame Guards = enough for hard only.
	var guards: Array[Unit] = []
	for i in 2:
		guards.append(_unit(&"flame_guard", keep, Vector3(6 + i, 0, 6)))
	await _physics(2)
	var easy := AIResearch.new(PLAYER)
	var normal := AIResearch.new(PLAYER)
	var hard := AIResearch.new(PLAYER)
	_ok(easy.try_buy(0, eco, now, &"fire") == &"", "easy: 2 Flame Guards are not enough (%s)" % easy.block)
	_ok(normal.try_buy(1, eco, now, &"fire") == &"", "normal: 2 Flame Guards are not enough")
	var c0 := eco.crystals
	_ok(hard.try_buy(2, eco, now, &"fire") == &"flame_guard_kindled_mail" and eco.crystals == c0 - 75,
			"hard: 2 Flame Guards -> Kindled Mail, the first row (%s)" % hard.block)
	_ok(hard.try_buy(2, eco, now + 1.0, &"fire") == &"", "one pass every 6 s")
	bank.cancel(&"flame_guard_kindled_mail")

	# Easy: tier-1 rows only, 2 at most.
	ts.set_tier(PLAYER, 2)
	var hall2 := _spawn(grid, hall_type, keep, 14.0, 12.0)   # two Halls: the "+" keeps one, research may use the other
	_ok(hall2 != null, "second Hall spawned")
	guards.append(_unit(&"flame_guard", keep, Vector3(9, 0, 6)))
	await _physics(2)
	bank.grant(&"flame_guard_kindled_mail")
	now += 10.0
	_ok(easy.try_buy(0, eco, now, &"fire") == &"", "easy never buys the tier-2 Backdraft (%s)" % easy.block)
	var normal_pick := normal.try_buy(1, eco, now, &"fire")
	_ok(normal_pick == &"flame_guard_backdraft", "normal buys the tier-2 Backdraft (%s, %s)" % [normal_pick, normal.block])
	bank.cancel(&"flame_guard_backdraft")
	for i in 3:
		_unit(&"ash_hurler", keep, Vector3(4, 0, 9 + i))
	await _physics(2)
	now += 10.0
	_ok(easy.try_buy(0, eco, now, &"fire") == &"ash_hurler_wheeled_mantlet", "easy: 3 Ash Hurlers -> Wheeled Mantlet (%s)" % easy.block)
	for i in 4:
		_unit(&"ember_archer", keep, Vector3(10, 0, 9 + i))
	await _physics(2)
	now += 10.0
	_ok(easy.rows_taken() == 2 and easy.try_buy(0, eco, now, &"fire") == &"" and easy.block == "cap",
			"easy stops at 2 rows (%d, %s)" % [easy.rows_taken(), easy.block])
	bank.cancel(&"ash_hurler_wheeled_mantlet")   # both Halls free again (one stays for the wanted "+")
	_ok(normal.try_buy(1, eco, now, &"fire") == &"ember_archer_quick_nock",
			"normal goes on: the most numerous type first (Ember Archer, %s)" % normal.block)
	bank.cancel(&"ember_archer_quick_nock")

	# "+": the last free Hall stays for it. Hall 2 runs a row; 4 Ember Archers want their "+".
	_ok(bank.buy(&"ash_hurler_wheeled_mantlet", hall2) == "", "Hall 2 busy with a row")
	now += 10.0
	var before := hard.try_buy(2, eco, now, &"fire")
	_ok(before == &"" and not UnitResearch.building_busy(hall),
			"one free Hall and a '+' wanted: research leaves it (%s, %s)" % [before, hard.block])
	_ok(UnitUpgrades.bot_try_buy(PLAYER, [hall, hall2], eco, 2000.0), "the '+' then takes the Hall")
	var plus := UnitUpgrades.for_team(PLAYER)
	for id: StringName in UnitUpgrades.UNITS:
		if plus.is_working(id):
			plus.cancel(id)
	bank.cancel(&"ash_hurler_wheeled_mantlet")
	# "+" price kept: with the "+" wanted and two free Halls, research needs price + reserve + the "+" price.
	var plus_price := UnitUpgrades.price_of(&"ember_archer")
	eco.crystals = 75 + 150 + plus_price - 1
	now += 10.0
	_ok(hard.try_buy(2, eco, now, &"fire") == &"", "the '+' price is kept (%s)" % hard.block)
	eco.crystals = 75 + 150 + plus_price
	now += 10.0
	var with_plus := hard.try_buy(2, eco, now, &"fire")
	_ok(with_plus == &"ember_archer_quick_nock", "with the '+' price on top it buys (%s, %s)" % [with_plus, hard.block])
	bank.cancel(&"ember_archer_quick_nock")
	for id: StringName in [&"flame_guard", &"ember_archer", &"ash_hurler"]:
		plus.grant(id)   # no "+" wanted from here

	# Forge: past the hard Forge time with no Forge, its cost is kept.
	var forge_cost := ForgeKit.forge_type(&"fire").cost
	var forge_now := float(ForgeKit.BOT_BUILD_AT[2])
	eco.crystals = 75 + 150 + forge_cost - 1
	_ok(hard.try_buy(2, eco, forge_now, &"fire") == &"", "a due Forge keeps its cost (%s)" % hard.block)
	eco.crystals = 75 + 150 + forge_cost
	var with_forge := hard.try_buy(2, eco, forge_now + 10.0, &"fire")
	_ok(with_forge == &"ember_archer_quick_nock", "with the Forge cost on top it buys (%s, %s)" % [with_forge, hard.block])
	bank.cancel(&"ember_archer_quick_nock")
	# Short of the Forge's own bar (cost + its reserve): held during FORGE_HOLD, free after it.
	eco.crystals = 75 + 150 + 25
	_ok(hard.try_buy(2, eco, forge_now + 20.0, &"fire") == &"", "within FORGE_HOLD the Forge cost is kept (%s)" % hard.block)
	var after_forge_hold := hard.try_buy(2, eco, forge_now + AIResearch.FORGE_HOLD + 5.0, &"fire")
	_ok(after_forge_hold == &"ember_archer_quick_nock", "after FORGE_HOLD a Forge the bot cannot pay yet no longer holds research (%s, %s)"
			% [after_forge_hold, hard.block])
	bank.cancel(&"ember_archer_quick_nock")

	# Keep upgrade: the Citadel is due (match clock past the hard timeline - lookahead): its cost is kept.
	var cit_at := float((TierSystem.BOT_START[2] as Array)[1]) * ts.pace_time_x
	var clock := ts.match_time_source
	ts.match_time_source = func() -> float: return cit_at
	var st := TierSystem.status(PLAYER)
	var up_cost := int(st.get("crystals", 0))
	_ok(int(st.get("next", 0)) == 3 and up_cost > 0, "Citadel next (%s)" % str(st))
	var hard2 := AIResearch.new(PLAYER)
	eco.crystals = 75 + 150 + up_cost - 1
	_ok(hard2.try_buy(2, eco, 50.0, &"fire") == &"", "a due Citadel keeps its cost (%s)" % hard2.block)
	eco.crystals = 75 + 150 + up_cost
	var with_tier := hard2.try_buy(2, eco, 60.0, &"fire")
	_ok(with_tier == &"ember_archer_quick_nock", "with the Citadel cost on top it buys (%s, %s)" % [with_tier, hard2.block])
	ts.match_time_source = clock

	# A champion hire waiting for crystals holds research HIRE_HOLD s, then lets it run.
	var hard3 := AIResearch.new(PLAYER)
	eco.crystals = 3000
	_ok(hard3.try_buy(2, eco, 100.0, &"fire", true) == &"", "a waiting champion hire holds research (%s)" % hard3.block)
	_ok(hard3.try_buy(2, eco, 120.0, &"fire", true) == &"", "still held 20 s later")
	var after_hold := hard3.try_buy(2, eco, 100.0 + AIResearch.HIRE_HOLD + 1.0, &"fire", true)
	_ok(after_hold != &"", "after %d s of waiting research runs again (%s)" % [int(AIResearch.HIRE_HOLD), hard3.block])


# ---------------------------------------------------------------- phase 2: bots

func _bots() -> void:
	print("---- phase bots %s:%s, team 0 easy, team 1 hard" % [_kingdoms[0], _kingdoms[1]])
	if ResourceLoader.exists(SIM_MODE_PATH):
		(load(SIM_MODE_PATH) as Script).set(&"enabled", true)
	var bots := _make_level(true)
	if not await _wait_start():
		return
	var stronghold := [-1.0, -1.0]
	var forge_at := [-1.0, -1.0]
	var started := [{}, {}]   # team -> row id -> match time
	var linked := [false, false]
	var t := 0.0
	var last_print := -1
	while true:
		await process_frame
		paused = false
		t = float(main.call(&"match_time"))
		for team in [0, 1]:
			if not linked[team]:
				var bank := UnitResearch.for_team(team, false)
				if bank:
					linked[team] = true
					var tm: int = team
					var rows: Dictionary = started[team]
					bank.research_started.connect(func(id: StringName) -> void:
						rows[id] = float(main.call(&"match_time"))
						print("  %s t%d research %s (tier %d)" % [_mmss(float(main.call(&"match_time"))), tm, id,
								int(UnitResearch.row(id).get("tier", 1))]))
			if stronghold[team] < 0.0 and TierSystem.tier_of(team) >= 2:
				stronghold[team] = t
			if forge_at[team] < 0.0:
				for b in Building.for_team(team):
					if b is ForgeBuilding:
						forge_at[team] = t
		if int(t * 2.0) != _sample:
			_sample = int(t * 2.0)
			var ca: Variant = bots[1].get(&"champion_ai")
			if ca != null and bool(ca.call(&"hire_waits_for_crystals", main)):
				_blocked["hire"] = int(_blocked.get("hire", 0)) + 1
		if int(t) / 60 != last_print:
			if not _blocked.is_empty():
				print("    blocked half-seconds so far: %s" % str(_blocked))
			last_print = int(t) / 60
			var ai: AIResearch = bots[1].get(&"research_ai")
			print("  %s hard rows %d (%d passes, block: %s), easy rows %d, hard crystals %d" % [_mmss(t),
					(started[1] as Dictionary).size(), ai.passes if ai else 0, ai.block if ai else "-",
					(started[0] as Dictionary).size(), Economy.for_team(1).crystals])
		if bool(main.get(&"game_over")) or t >= LIMIT:
			break
		if not _full and t >= EARLY_AFTER and (started[1] as Dictionary).size() >= 3:
			print("  EARLY STOP at %s: hard has 3 rows" % _mmss(t))
			break
	print("  ended %s%s; stronghold easy %s hard %s; forge easy %s hard %s" % [_mmss(t),
			" (game over)" if bool(main.get(&"game_over")) else "", _mmss(stronghold[0]), _mmss(stronghold[1]),
			_mmss(forge_at[0]), _mmss(forge_at[1])])
	var hard_rows: Dictionary = started[1]
	var easy_rows: Dictionary = started[0]
	var over := bool(main.get(&"game_over"))
	if over and t < LIMIT and hard_rows.size() < 3:
		# The match ended before 15:00: the bar had no full 15 minutes (not a FAIL, said on the PASS line).
		_inconclusive = "the match ended at %s (winner team %s) with hard at %d rows" % [_mmss(t),
				str(main.get(&"winner_team")), hard_rows.size()]
	else:
		_ok(hard_rows.size() >= 3, "hard started %d rows by %s (want >= 3): %s" % [hard_rows.size(), _mmss(t), str(hard_rows.keys())])
	_ok(easy_rows.size() <= 2, "easy started %d rows (max 2): %s" % [easy_rows.size(), str(easy_rows.keys())])
	for id: StringName in easy_rows:
		_ok(int(UnitResearch.row(id).get("tier", 1)) == 1, "easy bought a tier-%d row %s" % [int(UnitResearch.row(id).get("tier", 1)), id])
	var deadline := float((TierSystem.BOT_START[2] as Array)[0]) + STRONGHOLD_SLACK
	_ok(stronghold[1] >= 0.0 or t < deadline, "hard never reached the Stronghold by %s" % _mmss(deadline))
	_ok(stronghold[1] < 0.0 or stronghold[1] <= deadline, "hard Stronghold late: %s (by %s)" % [_mmss(stronghold[1]), _mmss(deadline)])


# ---------------------------------------------------------------- helpers

func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, fwd: float, side: float) -> Building:
	if type == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * fwd + Vector3(dir.z, 0, -dir.x) * side, PLAYER)
	return grid.spawn_complete(type, spot, PLAYER) if spot != Vector3.INF else null


func _unit(id: StringName, keep: Node3D, off: Vector3, team: int = PLAYER) -> Unit:
	var u: Unit = UnitType.find(String(id)).create_unit()
	u.team = team
	main.add_child(u)
	u.global_position = keep.global_position + off
	return u


static func _mmss(s: float) -> String:
	if s < 0.0:
		return "-"
	return "%d:%02d" % [floori(s / 60.0), int(s) % 60]
