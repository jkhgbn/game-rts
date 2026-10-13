extends SceneTree
## Wave Strike M1 (docs/design/wave-strike.md 7.9 rows 1-2): horn timing, income math, buy caps, sell / cancel
## refunds, Coffers, the Stronghold gate, spawn order. M2 (14.6 WS2.C1): the 14.1 card sets (4 kingdoms, slot order,
## tiers), every card buyable at its tier and refused below it, max_copies ("Max 4 copies" on a 5th Kilnwarden),
## start 600 / income 120, caps 36 / 60 / 84 (JS 2026-10-13: x1.5), field cap still 150. Pure systems (no level): WaveDirector + WaveBank + MusterRoster
## + LaneSpawner on a stub level. Prints "PASS ws_director" or "FAIL ws_director: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_director.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ws_director"

var _fails: Array[String] = []


class StubLevel extends Node:
	var spawned: Array = []        # [seat, id]
	var ratios := [1.0, 1.0]
	var positions: Array[Vector3] = []
	func spawn_lane_unit(seat: int, id: StringName, pos: Vector3, _lat: float) -> Variant:
		spawned.append([seat, id])
		positions.append(pos)
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
	# --- M2 rules (14.2 + JS 2026-10-13)
	_check(rules.start_crystals == 600, "start_crystals %d" % rules.start_crystals)
	_check(rules.base_income == 120, "base_income %d" % rules.base_income)
	_check(rules.cap_at(1) == 36 and rules.cap_at(2) == 60 and rules.cap_at(3) == 84,
			"caps %d / %d / %d" % [rules.cap_at(1), rules.cap_at(2), rules.cap_at(3)])
	_check(rules.field_cap == 200, "field_cap %d (200 since WS2.C3)" % rules.field_cap)
	# --- M2 card sets (14.1): slot order, tiers by slot (1-5 T1, 6-8 T2, 9-10 T3)
	var sets := {
		&"fire": ["flame_guard", "scorchling", "ember_archer", "ash_hurler", "blaze_rider", "cinder_arbalest",
				"pyre_adept", "kilnwarden", "sunforge_cataphract"],
		&"ice": ["rimeshield", "rimeling", "shardcaster", "rime_seer", "snowdrift_rider", "hoarlight_magebow",
				"rimecarver", "rimehorn_rider", "shardguard", "frostcrown_juggernaut"],
		&"nature": ["bramblehorn", "thornling", "wildwood_archer", "bloomtender", "stagrunner", "greenheart_oathkeeper",
				"vinelasher", "bramblesage", "briar_roc", "glade_outrider"],
		&"shadow": ["shade", "grave_hound", "nightbolt", "shadow_knight", "gloam_rider", "barrow_knight", "hexweaver",
				"gloom_deacon", "nightblood_reaver", "veilborn_dreadrider"],
	}
	for k: StringName in sets:
		var got: Array[String] = []
		for id in table.cards_of(k):
			got.append(String(id))
		_check(str(got) == str(sets[k]), "%s cards %s" % [k, str(got)])
		for i in got.size():
			var ut := UnitType.find(got[i])
			var want_tier := 1 if i < 5 else (2 if i < 8 else 3)
			_check(ut != null and ut.requires_tier == want_tier, "%s slot %d %s tier %d (want %d)" % [k, i + 1,
					got[i], ut.requires_tier if ut else -1, want_tier])
	for id: StringName in [&"kilnwarden", &"rimecarver", &"bramblesage", &"gloom_deacon"]:
		_check(table.max_copies_of(id) == 4, "max_copies %s = %d" % [id, table.max_copies_of(id)])
	for id: StringName in [&"pyre_adept", &"rime_seer", &"bloomtender", &"hexweaver"]:
		_check(table.max_copies_of(id) == 6, "max_copies %s = %d" % [id, table.max_copies_of(id)])
	for k: StringName in sets:
		for id in table.cards_of(k):
			if UnitType.find(String(id)).requires_tier == 3:
				_check(table.max_copies_of(id) == 3, "max_copies %s = %d" % [id, table.max_copies_of(id)])
	_check(table.max_copies_of(&"flame_guard") == 0, "flame_guard has no copy limit")
	_check(table.pop(&"cinder_arbalest") == 2 and table.pop(&"barrow_knight") == 2, "pop overrides kept")
	# --- prices from the data table
	# balance pass 2026-10-06: 4 kingdoms; price = cost x mode_mult (tools/wave_strike/reprice_cards.gd), mult in band
	for k: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
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
	# per-card supply (balance pass 2): pop_override wins over UnitType.pop, the roster and its cap read it
	t2.pop_override = {&"flame_guard": 3}
	_check(t2.pop(&"flame_guard") == 3, "pop_override %d" % t2.pop(&"flame_guard"))
	_check(t2.pop(&"ember_archer") == UnitType.find("ember_archer").pop, "pop default = UnitType.pop")
	for id in table.pop_override:
		_check(table.pop(id) >= 1 and table.pop(id) <= 4, "data pop_override %s = %d (1-4)" % [id, table.pop(id)])

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
	_check(bank.crystals() == 600, "start %d" % bank.crystals())
	_check_tiers_and_copies(level, rules, table, dir)
	# buy: price spent, joins the next horn
	var fg := &"flame_guard"
	var p_fg := table.price(fg)
	_check(r.buy(fg) == "", "buy flame_guard")
	_check(bank.crystals() == 600 - p_fg, "spent %d" % (600 - bank.crystals()))
	# T2 gate
	_check(r.can_buy(&"cinder_arbalest") == MusterRoster.REASON_TIER, "T2 gate: %s" % r.can_buy(&"cinder_arbalest"))
	# cancel window: 100 % back inside 5 s
	dir.advance(2.0)
	_check(r.sell(fg) == "" and bank.crystals() == 600, "cancel refund -> %d" % bank.crystals())
	_check(r.pop_used() == 0, "cancel frees pop now (%d)" % r.pop_used())
	r.buy(fg)
	r.buy(&"ember_archer")
	dir.advance(10.0)   # t = 12
	var before := bank.crystals()
	r.sell(&"ember_archer")
	_check(bank.crystals() == before + int(roundf(table.price(&"ember_archer") * 0.5)), "late sell refunds 50 %")
	_check(r.pop_used() == table.pop(fg) + table.pop(&"ember_archer"), "sold pop stays locked until the horn (%d)" % r.pop_used())
	# horn 1 at 30: income + spawns (1 flame guard) + pop freed
	before = bank.crystals()
	var horns := [0]
	dir.horn.connect(func(i: int) -> void: horns[0] = i)
	dir.advance(17.9)   # t = 29.9
	_check(horns[0] == 0, "no horn before 30 s")
	dir.advance(0.2)    # t = 30.1
	_check(horns[0] == 1, "horn 1 at 30 s")
	_check(bank.crystals() == before + 120, "horn 1 income 120 (got %d)" % (bank.crystals() - before))
	_check(r.pop_used() == table.pop(fg), "pop freed at the horn (%d)" % r.pop_used())
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
	# supply cap (Keep 36): cheapest card until full
	bank.economy.crystals = 100000
	var n := 0
	while r.buy(fg) == "" and n < 100:
		n += 1
	_check(r.pop_used() == 36, "cap 36 at Keep (pop %d)" % r.pop_used())
	_check(r.can_buy(fg).begins_with("Supply full (36/36)"), "reason: %s" % r.can_buy(fg))
	# Stronghold gate: from horn 6, 250, 45 s, then cap 60 and T2
	_check(r.can_upgrade() == "From horn 6", "stronghold early: %s" % r.can_upgrade())
	while dir.horn_index < 6:
		dir.advance(1.0)
	_check(r.upgrade() == "", "stronghold starts at horn 6")
	dir.advance(44.0)
	_check(r.tier == 1, "not before 45 s")
	dir.advance(1.5)
	_check(r.tier == 2 and r.cap() == 60, "stronghold done: tier %d cap %d" % [r.tier, r.cap()])
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
	# WS2.C1: a big M2 wave (60 units) never spawns past MAX_ROWS rows behind the gate (the Bastion stands 13 m back)
	var pad := LaneSpawner.new()
	pad.setup(0, 0, Vector3(-71, 0, 0), Vector3.RIGHT, level, rules)
	level.add_child(pad)
	var big: Array[StringName] = []
	for i in 60:
		big.append(fg)
	level.positions.clear()
	pad.queue_wave(big)
	pad.tick(60.0)
	var deepest := 0.0
	for p in level.positions:
		deepest = maxf(deepest, -71.0 - p.x)
	_check(level.positions.size() == 60 and deepest <= (LaneSpawner.MAX_ROWS - 1) * LaneSpawner.ROW_GAP + 0.01,
			"big wave rows: %d spawned, deepest %.1f m behind the gate" % [level.positions.size(), deepest])
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


## A rich roster of `kingdom` on its own seat (WaveBank + Economy on the stub level).
func _rich_roster(level: Node, rules: WaveStrikeRules, table: WaveCardTable, dir: WaveDirector, seat: int,
		kingdom: StringName) -> MusterRoster:
	var eco := Economy.new()
	eco.team = Unit.Team.PLAYER
	level.add_child(eco)
	var bank := WaveBank.new()
	bank.setup(seat, Unit.Team.PLAYER, rules, eco)
	level.add_child(bank)
	bank.economy.crystals = 1000000
	var r := MusterRoster.new()
	r.setup(seat, Unit.Team.PLAYER, kingdom, rules, table, bank, dir)
	level.add_child(r)
	return r


## WS2.C1: every card of every kingdom is refused below its tier ("Requires Stronghold" / "Requires Citadel") and
## buyable at it; a 4th T3 copy is refused "Max 3 copies", a 5th Kilnwarden "Max 4 copies"; the Citadel cap is 84.
func _check_tiers_and_copies(level: Node, rules: WaveStrikeRules, table: WaveCardTable, dir: WaveDirector) -> void:
	var seat := 10
	for k: StringName in [&"fire", &"ice", &"nature", &"shadow"]:
		var r := _rich_roster(level, rules, table, dir, seat, k)
		seat += 1
		for t: int in [1, 2, 3]:
			r.tier = t
			for id in r.card_ids():
				var need := r.tier_of_card(id)
				var why := r.can_buy(id)
				if need > t:
					var want := "Requires Stronghold" if need == 2 else "Requires Citadel"
					_check(why == want, "%s %s at tier %d: '%s' (want '%s')" % [k, id, t, why, want])
				else:
					_check(why == "", "%s %s buyable at tier %d: '%s'" % [k, id, t, why])
		r.tier = 3
		for id in r.card_ids():
			if r.tier_of_card(id) == 3:
				for i in 3:
					_check(r.buy(id) == "", "%s buy T3 %s copy %d" % [k, id, i + 1])
				_check(r.can_buy(id) == "Max 3 copies", "%s 4th %s: '%s'" % [k, id, r.can_buy(id)])
				break
	# the done-when line: a 5th Kilnwarden (Fire, Stronghold)
	var fr := _rich_roster(level, rules, table, dir, seat, &"fire")
	fr.tier = 2
	for i in 4:
		_check(fr.buy(&"kilnwarden") == "", "kilnwarden copy %d" % (i + 1))
	_check(fr.can_buy(&"kilnwarden") == "Max 4 copies", "5th kilnwarden: '%s'" % fr.can_buy(&"kilnwarden"))
	_check(fr.buy(&"kilnwarden") == "Max 4 copies" and fr.count(&"kilnwarden") == 4, "5th kilnwarden refused")
	fr.sell(&"kilnwarden")
	_check(fr.can_buy(&"kilnwarden") == "", "a sell frees the copy: '%s'" % fr.can_buy(&"kilnwarden"))
	fr.tier = 3
	_check(fr.cap() == 84, "Citadel cap %d" % fr.cap())
