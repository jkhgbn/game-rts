extends SceneTree
## Wave Strike M1 (docs/design/wave-strike.md 7.9 rows 1-2): horn timing, income math, buy caps, sell / cancel
## refunds, Coffers, the Stronghold gate, spawn order. Pure systems (no level): WaveDirector + WaveBank + MusterRoster
## + LaneSpawner on a stub level. Prints "PASS ws_director" or "FAIL ws_director: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_director.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ws_director"

var _fails: Array[String] = []


class StubLevel extends Node:
	var spawned: Array = []        # [seat, id]
	var ratios := [1.0, 1.0]
	func spawn_lane_unit(seat: int, id: StringName, _pos: Vector3, _lat: float) -> Variant:
		spawned.append([seat, id])
		return null
	func bastion_ratio(team: int) -> float:
		return ratios[team]


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	var rules := WaveStrikeRules.load_default()
	var table := WaveCardTable.load_default()
	# --- horn timing (the math on the M1 numbers; the data's Last Horns time is checked generically below)
	var hr := rules.duplicate() as WaveStrikeRules
	hr.horn_first = 30.0
	hr.horn_interval = 40.0
	hr.last_horns_at = 1440.0
	hr.last_horns_interval = 30.0
	_check(is_equal_approx(hr.horn_time(1), 30.0), "horn 1 at %.1f" % hr.horn_time(1))
	_check(is_equal_approx(hr.horn_time(2), 70.0), "horn 2 at %.1f" % hr.horn_time(2))
	_check(is_equal_approx(hr.horn_time(36), 30.0 + 35 * 40.0), "horn 36 at %.1f" % hr.horn_time(36))
	# Last Horns: horn 36 at 1430 < 1440, horn 37 at 1470 (still +40 from 1430), 38 at 1500 (+30)
	_check(is_equal_approx(hr.horn_time(37), 1470.0), "horn 37 at %.1f" % hr.horn_time(37))
	_check(is_equal_approx(hr.horn_time(38), 1500.0), "horn 38 at %.1f (Last Horns +30)" % hr.horn_time(38))
	# the data: horns every horn_interval until last_horns_at, then every last_horns_interval
	_check(is_equal_approx(rules.horn_time(1), rules.horn_first), "data horn 1 at %.1f" % rules.horn_time(1))
	var hn := 1
	while rules.horn_time(hn) < rules.last_horns_at:
		hn += 1
	_check(is_equal_approx(rules.horn_time(hn + 2) - rules.horn_time(hn + 1), rules.last_horns_interval),
			"data Last Horns interval %.1f" % (rules.horn_time(hn + 2) - rules.horn_time(hn + 1)))
	# --- prices from the data table
	# balance pass 2026-10-06: 4 kingdoms; price = cost x mode_mult (tools/wave_strike/reprice_cards.gd), mult in band
	for k: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		_check(table.cards_of(k).size() == 4, "%s has %d cards" % [k, table.cards_of(k).size()])
		for id in table.cards_of(k):
			var t := UnitType.find(String(id))
			_check(t != null, "card %s has no UnitType" % id)
			if t:
				var m := float(table.mode_mult.get(id, 1.0))
				_check(m >= 0.7 and m <= 1.4, "mode_mult %s = %.2f (band 0.7-1.4)" % [id, m])
				_check(table.price(id) == int(roundf(t.cost * m / 5.0) * 5.0), "price %s = %d" % [id, table.price(id)])
	var tiers := {}
	for id in table.cards_of(&"fire") + table.cards_of(&"shadow"):
		tiers[UnitType.find(String(id)).requires_tier] = true
	_check(tiers.has(1) and tiers.has(2), "cards mix T1 and T2 (%s)" % str(tiers.keys()))
	# a re-price through the table only
	var t2 := table.duplicate() as WaveCardTable
	t2.mode_mult = {&"flame_guard": 1.12}
	_check(t2.price(&"flame_guard") == int(roundf(UnitType.find("flame_guard").cost * 1.12 / 5.0) * 5.0), "mode_mult re-price")

	# --- systems on a stub level
	var level := StubLevel.new()
	root.add_child(level)
	var eco := Economy.new()
	eco.team = Unit.Team.PLAYER
	level.add_child(eco)
	var eco2 := Economy.new()
	eco2.team = Unit.Team.ENEMY
	level.add_child(eco2)
	var dir := WaveDirector.new()
	dir.setup(rules, level)
	level.add_child(dir)
	var banks: Array[WaveBank] = []
	var rosters: Array[MusterRoster] = []
	for seat in 2:
		var bank := WaveBank.new()
		bank.setup(seat, seat, rules, eco if seat == 0 else eco2)
		level.add_child(bank)
		var r := MusterRoster.new()
		r.setup(seat, seat, &"fire" if seat == 0 else &"shadow", rules, table, bank, dir)
		level.add_child(r)
		var sp := LaneSpawner.new()
		sp.setup(seat, seat, Vector3.ZERO, Vector3.RIGHT, level, rules)
		level.add_child(sp)
		dir.add_seat(bank, r, sp)
		banks.append(bank)
		rosters.append(r)
	var bank := banks[0]
	var r := rosters[0]
	_check(bank.crystals() == 400, "start %d" % bank.crystals())
	# buy: price spent, joins the next horn
	var fg := &"flame_guard"
	var p_fg := table.price(fg)
	_check(r.buy(fg) == "", "buy flame_guard")
	_check(bank.crystals() == 400 - p_fg, "spent %d" % (400 - bank.crystals()))
	# T2 gate
	_check(r.can_buy(&"cinder_arbalest") == MusterRoster.REASON_TIER, "T2 gate: %s" % r.can_buy(&"cinder_arbalest"))
	# cancel window: 100 % back inside 5 s
	dir.advance(2.0)
	_check(r.sell(fg) == "" and bank.crystals() == 400, "cancel refund -> %d" % bank.crystals())
	_check(r.pop_used() == 0, "cancel frees pop now (%d)" % r.pop_used())
	r.buy(fg)
	r.buy(&"ember_archer")
	dir.advance(10.0)   # t = 12
	var before := bank.crystals()
	r.sell(&"ember_archer")
	_check(bank.crystals() == before + int(roundf(table.price(&"ember_archer") * 0.5)), "late sell refunds 50 %")
	_check(r.pop_used() == 2, "sold pop stays locked until the horn (%d)" % r.pop_used())
	# horn 1 at 30: income + spawns (1 flame guard) + pop freed
	before = bank.crystals()
	var horns := [0]
	dir.horn.connect(func(i: int) -> void: horns[0] = i)
	dir.advance(17.9)   # t = 29.9
	_check(horns[0] == 0, "no horn before 30 s")
	dir.advance(0.2)    # t = 30.1
	_check(horns[0] == 1, "horn 1 at 30 s")
	_check(bank.crystals() == before + rules.base_income, "income %d (got %d)" % [rules.base_income, bank.crystals() - before])
	_check(r.pop_used() == 1, "pop freed at the horn (%d)" % r.pop_used())
	dir.advance(1.0)    # stagger 0.15: the unit is out
	_check(level.spawned.size() == 1 and level.spawned[0][1] == fg, "spawns = roster: %s" % str(level.spawned))
	# horn 2 at 70 s
	dir.advance(38.95)  # t = 70.05
	_check(horns[0] == 2, "horn 2 at 70 s (horn %d at t %.2f)" % [horns[0], dir.time])
	# Coffer math
	bank.economy.crystals = 1000
	_check(bank.buy_coffer() == "" and bank.coffer_level == 1 and bank.crystals() == 850, "coffer 1 costs 150")
	_check(bank.income() == rules.base_income + rules.coffer_step, "income with 1 coffer = %d" % bank.income())
	bank.buy_coffer()
	_check(bank.crystals() == 650 and bank.income() == rules.base_income + 2 * rules.coffer_step,
			"coffer 2 costs 200, income %d" % bank.income())
	# underdog tithe: 31 % HP behind = 2 steps = +16 %
	level.ratios = [0.69, 1.0]
	_check(is_equal_approx(dir._underdog(0), 0.16), "underdog 2 steps = %.2f" % dir._underdog(0))
	level.ratios = [0.0, 1.0]
	_check(is_equal_approx(dir._underdog(0), 0.24), "underdog cap = %.2f" % dir._underdog(0))
	_check(dir._underdog(1) == 0.0, "the leader gets no tithe")
	level.ratios = [1.0, 1.0]
	# supply cap (Keep 24): cheapest card until full
	bank.economy.crystals = 100000
	var n := 0
	while r.buy(fg) == "" and n < 100:
		n += 1
	_check(r.pop_used() == 24, "cap 24 at Keep (pop %d)" % r.pop_used())
	_check(r.can_buy(fg).begins_with("Supply full (24/24)"), "reason: %s" % r.can_buy(fg))
	# Stronghold gate: from horn 6, 250, 45 s, then cap 40 and T2
	_check(r.can_upgrade() == "From horn 6", "stronghold early: %s" % r.can_upgrade())
	while dir.horn_index < 6:
		dir.advance(1.0)
	_check(r.upgrade() == "", "stronghold starts at horn 6")
	dir.advance(44.0)
	_check(r.tier == 1, "not before 45 s")
	dir.advance(1.5)
	_check(r.tier == 2 and r.cap() == 40, "stronghold done: tier %d cap %d" % [r.tier, r.cap()])
	_check(r.can_buy(&"cinder_arbalest") == "", "T2 after stronghold: %s" % r.can_buy(&"cinder_arbalest"))
	# ranks: the whole line, 60 % of the price per copy; later copies pay the rank too; Elite needs the Citadel
	var fg_price := table.price(fg)
	var copies := r.count(fg)
	var up := r.rank_up_price(fg)
	_check(up == int(roundf(fg_price * 0.6 * copies / 5.0) * 5.0), "rank-up price %d for %d copies" % [up, copies])
	before = bank.crystals()
	_check(r.rank_up(fg) == "" and r.rank(fg) == 2 and bank.crystals() == before - up, "rank up to Drilled")
	_check(r.unit_price(fg) == int(roundf(fg_price * 1.6 / 5.0) * 5.0), "a Drilled copy costs %d" % r.unit_price(fg))
	_check(r.can_rank_up(fg) == "Requires Citadel", "Elite gate: %s" % r.can_rank_up(fg))
	# spawn order: melee first, then ranged
	r.buy(&"cinder_arbalest")
	var order := r.spawn_list()
	_check(order[order.size() - 1] == &"cinder_arbalest" and order[0] == fg, "spawn order melee -> ranged")
	# the bot buys within its means and the cap
	var bot := WaveBot.new()
	level.add_child(bot)
	bot.setup(1, rosters[1], banks[1], dir, "hammer")
	banks[1].economy.crystals = 400
	bot.decide()
	_check(rosters[1].card_total() > 0 and banks[1].crystals() >= 0, "bot buys (%d cards, %d left)" % [rosters[1].card_total(), banks[1].crystals()])
	_check(rosters[1].pop_used() <= rosters[1].cap(), "bot within cap")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)
