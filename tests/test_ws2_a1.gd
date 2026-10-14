extends SceneTree
## WS2.A1 (docs/design/wave-strike.md 14.3 / 14.6): the WaveBot's M2 mix on the pure systems (WaveDirector + WaveBank +
## MusterRoster + LaneSpawner on a stub level; a bounty stand-in of 20 x horn per horn). Per kingdom x personality, 30 horns:
## - a kingdom caster in the horn 9 wave at the latest (hammer; steward too), a T3 card in the horn 18 wave at the latest;
## - casters <= 1 at the Stronghold and <= 2 ever; support pop <= 10 % (+1); T3 pop <= 30 % of the Citadel cap;
##   melee >= 40 % of pop; max_copies never passed; every MIX entry is a card of its kingdom (and vice versa).
## Plus a forced swap: Citadel, supply full of T1, bank rich -> "swap <old> -> <T3>", the T3 card bought next pass.
## WS3.A1 (15.4): style per personality (steward Line, hammer Spearhead), the pad arranged after each pass, front-row
## roles, the swap sells the back-most copy. WS4.A1 (16.3): first upgrade by UPGRADE_BY_HORN in the personality's order,
## max 2 a pass, lines >= 4 copies; forced: Citadel + full supply + rich bank -> exactly the 2 first items of the order.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws2_a1.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ws2_a1"
const KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]
## WS4.A1: every personality has bought its first upgrade by this horn (16.3, stub economy).
const UPGRADE_BY_HORN := 26

var _fails: Array[String] = []


class StubLevel extends Node:
	func spawn_lane_unit(_seat: int, _id: StringName, _pos: Vector3, _lat: float) -> Variant:
		return null
	func bastion_ratio(_team: int) -> float:
		return 1.0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	var table := WaveCardTable.load_default()
	for k in KINGDOMS:
		var mix: Dictionary = WaveBot.MIX[k]
		var ids := table.cards_of(k)
		_check(mix.size() == ids.size(), "%s MIX has %d cards, table %d" % [k, mix.size(), ids.size()])
		for id in ids:
			_check(mix.has(id), "%s MIX misses %s" % [k, id])
	for k in KINGDOMS:
		for p: String in ["hammer", "steward"]:
			_run(k, p)
		_swap(k)
		for p: String in ["hammer", "steward"]:
			_forced_upgrades(k, p)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


## A one-seat stub match: [level, director, bank, roster, bot].
func _match(kingdom: StringName, personality: String) -> Array:
	var rules := WaveStrikeRules.load_default()
	var table := WaveCardTable.load_default()
	var level := StubLevel.new()
	root.add_child(level)
	var eco := Economy.new()
	eco.team = Unit.Team.PLAYER
	level.add_child(eco)
	var dir := WaveDirector.new()
	dir.setup(rules, level)
	level.add_child(dir)
	var bank := WaveBank.new()
	bank.setup(0, Unit.Team.PLAYER, rules, eco)
	level.add_child(bank)
	var r := MusterRoster.new()
	r.setup(0, Unit.Team.PLAYER, kingdom, rules, table, bank, dir)
	level.add_child(r)
	var sp := LaneSpawner.new()
	sp.setup(0, Unit.Team.PLAYER, Vector3.ZERO, Vector3.RIGHT, level, rules)
	level.add_child(sp)
	dir.add_seat(bank, r, sp)
	var bot := WaveBot.new()
	level.add_child(bot)
	bot.setup(0, r, bank, dir, personality)
	return [level, dir, bank, r, bot]


func _run(kingdom: StringName, personality: String) -> void:
	var m := _match(kingdom, personality)
	var dir: WaveDirector = m[1]
	var r: MusterRoster = m[3]
	var bot: WaveBot = m[4]
	var tag := "%s/%s" % [kingdom, personality]
	var cap3 := r.rules.cap_at(3)
	bot.decide()   # the start pass
	var paid := 0
	while dir.horn_index < 30:
		dir.advance(0.5)
		if dir.horn_index != paid:
			# a kill-bounty stand-in (no combat here): 20 x horn per horn (a real 1v1 earns ~3x that, test_ws_match "earned")
			paid = dir.horn_index
			r.bank.add_bounty(20 * paid)
		bot.poll()
		var casters := 0
		for id in WaveBot.CASTER_IDS:
			casters += r.count(id)
		_check(casters <= (0 if r.tier < 2 else (1 if r.tier == 2 else 2)),
				"%s: %d casters at tier %d" % [tag, casters, r.tier])
		for id in r.card_ids():
			var most := r.table.max_copies_of(id)
			_check(most <= 0 or r.count(id) <= most, "%s: %d %s (max %d)" % [tag, r.count(id), id, most])
		_check(r.pop_used() <= r.cap(), "%s: pop %d / %d" % [tag, r.pop_used(), r.cap()])
		_check(r.bank.crystals() >= 0, "%s: crystals %d" % [tag, r.bank.crystals()])
	var total := 0
	var melee := 0
	var support := 0
	var t3 := 0
	for id: StringName in r.cards():
		var pp := r.count(id) * r.pop_of(id)
		total += pp
		if UnitType.find(String(id)).attack_range <= WaveBot.MELEE_RANGE:
			melee += pp
		if WaveBot.SUPPORT_IDS.has(id):
			support += pp
		if r.tier_of_card(id) >= 3:
			t3 += pp
	print("%s: first caster horn %d, first T3 horn %d, swaps %d, tier %d, pop %d / %d (melee %d, support %d, T3 %d), cards %s" % [
			tag, bot.first_caster_horn, bot.first_t3_horn, bot.swaps, r.tier, r.pop_used(), r.cap(), melee, support, t3,
			str(r.cards())])
	_check(bot.first_caster_horn > 0 and bot.first_caster_horn <= 9, "%s: first caster horn %d (want <= 9)" % [tag, bot.first_caster_horn])
	_check(bot.first_t3_horn > 0 and bot.first_t3_horn <= 18, "%s: first T3 horn %d (want <= 18)" % [tag, bot.first_t3_horn])
	_check(r.tier == 3, "%s: tier %d at horn 30" % [tag, r.tier])
	_check(float(melee) >= 0.4 * float(total), "%s: melee %d / %d pop" % [tag, melee, total])
	_check(float(support) <= 0.1 * float(total) + 1.0, "%s: support %d / %d pop" % [tag, support, total])
	_check(float(t3) <= 0.3 * float(cap3), "%s: T3 %d pop > 30 %% of %d" % [tag, t3, cap3])
	_check(float(t3) >= 0.2 * float(cap3) or _all_t3_maxed(r), "%s: T3 floor unmet (%d pop)" % [tag, t3])
	# WS3.A1: formation style per personality, the pad holds every copy, arranged (re-arranging changes nothing)
	var style: StringName = &"spearhead" if personality == "hammer" else &"line"
	_check(bot.formation_style() == style and r.place_style == style, "%s: style %s / %s" % [tag, bot.formation_style(), r.place_style])
	_check(r.pad.copy_count() == r.card_total(), "%s: pad %d copies, roster %d" % [tag, r.pad.copy_count(), r.card_total()])
	var before := r.pad.save_cells()
	r.pad.auto_arrange(style)
	_check(str(before) == str(r.pad.save_cells()), "%s: pad not arranged in %s" % [tag, style])
	# 15.4 zones: Spearhead keeps plain melee off row 0 (riders / heavies form the point); Line puts melee or heavies there
	var front := bot.front_row_roles()
	if personality == "hammer":
		_check(not front.contains("melee"), "%s: spearhead front row %s" % [tag, front])
	else:
		_check(front.contains("melee") or front.contains("heavy"), "%s: line front row %s" % [tag, front])
	# WS4.A1: upgrades by the personality's order, max 2 a pass, card lines >= 4 copies only
	var ups := r.upgrades_bought
	_check(not ups.is_empty() and bot.first_upgrade_horn > 0 and bot.first_upgrade_horn <= UPGRADE_BY_HORN,
			"%s: first upgrade horn %d (want <= %d), %s" % [tag, bot.first_upgrade_horn, UPGRADE_BY_HORN, str(ups)])
	if not ups.is_empty():
		if personality == "steward":
			_check(ups[0] == "armoury:armour:1", "%s: steward's first upgrade %s" % [tag, ups[0]])
			_check(ups.size() < 2 or ups[1] == "armoury:weapons:1", "%s: steward's 2nd upgrade %s" % [tag, ups[1]])
		else:
			_check(ups[0].ends_with(":a") and not ups[0].begins_with("armoury"), "%s: hammer's first upgrade %s" % [tag, ups[0]])
	var per_pass := {}
	for line in bot.log_lines:
		if line.contains(":upgrade "):
			var k := line.get_slice(":", 0)
			per_pass[k] = int(per_pass.get(k, 0)) + 1
			var key := line.get_slice("upgrade ", 1)
			if not key.begins_with("armoury"):
				var cid := StringName(key.get_slice(":", 0))
				_check(int(r.bought_by_card.get(cid, 0)) >= WaveBot.UPGRADE_MIN_COPIES, "%s: upgrade %s on a small line" % [tag, key])
	for k: String in per_pass:
		_check(int(per_pass[k]) <= WaveBot.UPGRADE_MAX_PER_PASS, "%s: %d upgrades in pass %s" % [tag, per_pass[k], k])
	print("%s: style %s, front row [%s], upgrades (first horn %d) %s" % [tag, style, front, bot.first_upgrade_horn, str(ups)])
	(m[0] as Node).free()


func _all_t3_maxed(r: MusterRoster) -> bool:
	for id in r.card_ids():
		if r.tier_of_card(id) >= 3 and r.count(id) < r.table.max_copies_of(id):
			return false
	return true


## Citadel, supply full of the cheapest T1 melee card, bank rich: one swap, then the T3 card next pass.
func _swap(kingdom: StringName) -> void:
	var m := _match(kingdom, "hammer")
	var dir: WaveDirector = m[1]
	var bank: WaveBank = m[2]
	var r: MusterRoster = m[3]
	var bot: WaveBot = m[4]
	r.tier = 3
	bank.economy.crystals = 100000
	var cheap: StringName = r.card_ids()[1]   # slot 2: the cheap fast melee card
	while r.buy(cheap) == "":
		pass
	dir.advance(10.0)   # past the cancel window
	bank.economy.crystals = 600
	# WS3.A1: the swap sells the back-most copy (watch the pad's first change after the pass starts)
	var back := r.pad.back_most(cheap)
	var cells_before := r.pad.cells_of(cheap)
	var removed: Array[Vector2i] = []
	var watch := func() -> void:
		if removed.is_empty() and r.pad.cells_of(cheap).size() == cells_before.size() - 1:
			for c in cells_before:
				if not r.pad.cells_of(cheap).has(c):
					removed.append(c)
	r.pad.changed.connect(watch)
	bot.decide()
	r.pad.changed.disconnect(watch)
	_check(removed.size() == 1 and removed[0] == back, "%s swap: sold %s, back-most %s" % [kingdom, str(removed), back])
	var log_text := "\n".join(bot.log_lines)
	_check(bot.swaps == 1 and log_text.contains("swap "), "%s swap: swaps %d, log %s" % [kingdom, bot.swaps, log_text])
	var t3_before := 0
	for id in r.card_ids():
		if r.tier_of_card(id) >= 3:
			t3_before += r.count(id)
	_check(t3_before == 0, "%s swap: T3 bought before the pop is free (%d)" % [kingdom, t3_before])
	r.on_horn()
	bot.decide()
	var t3_after := 0
	for id in r.card_ids():
		if r.tier_of_card(id) >= 3:
			t3_after += r.count(id)
	_check(t3_after >= 1, "%s swap: no T3 card after the horn (log %s)" % [kingdom, "\n".join(bot.log_lines)])
	_check(bot.swaps == 1, "%s swap: %d swaps in one horn" % [kingdom, bot.swaps])
	print("%s swap: %s" % [kingdom, " | ".join(bot.log_lines)])
	(m[0] as Node).free()


## WS4.A1: Citadel, supply full of one 4+ copy line, bank rich -> exactly 2 upgrades in the personality's order.
func _forced_upgrades(kingdom: StringName, personality: String) -> void:
	var m := _match(kingdom, personality)
	var dir: WaveDirector = m[1]
	var bank: WaveBank = m[2]
	var r: MusterRoster = m[3]
	var bot: WaveBot = m[4]
	r.tier = 3
	bank.economy.crystals = 100000
	var line: StringName = r.card_ids()[0]
	while r.buy(line) == "":
		pass
	dir.advance(10.0)
	bank.economy.crystals = 5000
	bot.decide()
	var ups := r.upgrades_bought
	var want: Array = ["armoury:armour:1", "armoury:weapons:1"] if personality == "steward" else ["%s:a" % line, "%s:b" % line]
	_check(str(ups) == str(want), "%s/%s forced upgrades %s (want %s)" % [kingdom, personality, str(ups), str(want)])
	print("%s/%s forced upgrades: %s" % [kingdom, personality, str(ups)])
	(m[0] as Node).free()
