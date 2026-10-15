class_name AIResearch
extends RefCounted
## Bot rule for unit research (docs/design/unit-upgrades.md 12 "Bots", task UR.A1). Commander rule 5 calls
## `try_buy` right after the "+" (`UnitUpgrades.bot_try_buy`); it replaces the old `BowmanUpgrades.bot_try_buy` call
## (the bowman rows live in `UnitResearch` now and follow this same rule).
## Every INTERVAL s, one buy at most: the own unit type with the most living units that meets its count (pop 1 >= 3,
## pop 2+ >= 2, casters >= 2, tier-3 >= 1; hard one less, never below 1), then its next open row in table order that
## the difficulty allows, at an own building that can start it, when crystals >= price + reserve. Never saves.
## Not delaying the other spenders: the crystals of a due Stronghold / Citadel (TIER_LOOKAHEAD s before the bot's
## timeline) and of a due Forge (FORGE_HOLD s) are kept on top of the reserve; those of the Forge's next card line and of a wanted
## "+" only while that spender could pay now (its own price + reserve rule), and then the last free Hall is left to
## the "+" (they share the Hall's research slot). Tier saving and the helper call stop the pass before this rule
## (Commander `_rule_train`); a due champion hire waiting for crystals holds it HIRE_HOLD s at a time.
## Between passes, a pick that waited only for crystals is retried as soon as they are there.

const INTERVAL := 6.0
const TIER_LOOKAHEAD := 30.0
## A due champion hire that waits for crystals stops research for HIRE_HOLD s, then lets it run HIRE_FREE s (repeat):
## in bot-vs-bot runs a hire often waited 8-10 min (soldiers spend first), and research never ran (UR.A1, 2026-10-14).
const HIRE_HOLD := 45.0
const HIRE_FREE := 30.0
## A due Forge building keeps its crystals this long, then only while the Forge step could pay it now.
const FORGE_HOLD := 90.0
## difficulty (Commander.Difficulty: 0 easy, 1 normal, 2 hard) -> crystals kept after the buy.
const RESERVE := {0: 300, 1: 200, 2: 150}
## difficulty -> max rows bought per match (-1 = no cap).
const MAX_ROWS := {0: 2, 1: 6, 2: -1}
## difficulty -> highest row tier allowed (easy: tier-1 rows only).
const MAX_TIER := {0: 1, 1: 3, 2: 3}

var team := 0
var last_bought: StringName = &""   ## Read only: the last row started (tests / logs).
var block := ""                     ## Read only: why the last pass bought nothing (debug).
var bought: Array[StringName] = []  ## Read only: rows this bot started this match.
var passes := 0                     ## Read only: passes run (every INTERVAL s when rule 5 reaches this rule).
var _next := 0.0
var _last_refusal := ""
var _waiting_need := 0  # crystals the last pass's pick waited for (0 = none)
var _forge_since := INF  # match time the Forge building was first seen due (INF = not due)
var _hire_since := INF   # match time the current champion-hire wait started (INF = none)


func _init(for_team: int = 0) -> void:
	team = for_team


## The living units of `type` a type needs before its rows are bought.
static func min_count(type: UnitType, difficulty: int) -> int:
	var n := 3
	if T3Kit.is_t3_unit(type.id):
		n = 1
	elif CasterKit.is_caster(type.id):
		n = 2
	elif type.pop >= 2:
		n = 2
	if difficulty >= 2:
		n -= 1
	return maxi(n, 1)


## True when the difficulty may buy row `id` (easy: tier-1 rows only).
static func row_allowed(id: StringName, difficulty: int) -> bool:
	var r := UnitResearch.row(id)
	return not r.is_empty() and int(r.get("tier", 1)) <= int(MAX_TIER.get(clampi(difficulty, 0, 2), 3))


## Rows of the team done or in progress (counts against the difficulty's cap; survives a load).
func rows_taken() -> int:
	var bank := UnitResearch.for_team(team, false)
	if bank == null:
		return 0
	var n := bank.done.size()
	for id: StringName in UnitResearch.ROWS:
		if bank.is_working(id):
			n += 1
	return n


## One pass of the rule. Returns the row id started, or &"" (see `block`). `hire_waits` = a due champion hire waits
## for crystals: research is skipped for HIRE_HOLD s of such a wait, then may run for HIRE_FREE s, and so on.
## `kept_extra` = more crystals to keep on top (the Commander: a due first caster's cost).
func try_buy(difficulty: int, eco: Economy, now: float, faction: StringName, hire_waits: bool = false,
		kept_extra: int = 0) -> StringName:
	if eco == null or not UnitResearch.ENABLED or not UnitResearch.enabled_here():
		return &""
	if not hire_waits:
		_hire_since = INF
	elif _hire_since > now:   # a new wait (INF), or a new match in the same process
		_hire_since = now
	if hire_waits and fmod(now - _hire_since, HIRE_HOLD + HIRE_FREE) < HIRE_HOLD:
		block = "a champion hire waits"
		return &""
	if _next - now > INTERVAL * 2.0:   # a new match in the same process: the clock restarted
		_next = 0.0
	# Between passes, a pick that waited only for crystals is retried as soon as they are there (the rule runs before
	# soldier training in rule 5, so the crystals are not gone to the next soldier first). Still one buy per INTERVAL.
	if now < _next and not (_waiting_need > 0 and eco.crystals >= _waiting_need):
		return &""
	_waiting_need = 0
	_next = now + INTERVAL
	passes += 1
	var d := clampi(difficulty, 0, 2)
	var cap := int(MAX_ROWS[d])
	if cap >= 0 and rows_taken() >= cap:
		block = "cap"
		return &""
	var bank := UnitResearch.for_team(team)
	if bank == null:
		return &""
	var counts := _unit_counts()
	if counts.is_empty():
		block = "no units"
		return &""
	var plus_id := _plus_wanted(counts)
	# The "+" only holds the Hall / its price while it could buy now (its own rule: price + BOT_RESERVE); a "+" the
	# bot cannot afford does not freeze research (CI 2026-10-14: a hard Shadow bot sat 4 min on one row).
	if plus_id != &"" and eco.crystals < UnitUpgrades.price_of(plus_id) + UnitUpgrades.BOT_RESERVE:
		plus_id = &""
	var halls_free := _free_halls()
	var types: Array[StringName] = []
	for id: StringName in counts:
		types.append(id)
	types.sort_custom(func(a: StringName, b: StringName) -> bool:
		return int(counts[a]) > int(counts[b]) or (int(counts[a]) == int(counts[b]) and String(a) < String(b)))
	var why: PackedStringArray = []
	for uid in types:
		var ut := UnitType.find(String(uid))
		if ut == null or int(counts[uid]) < min_count(ut, d):
			why.append("%s x%d" % [uid, int(counts[uid])])
			continue
		for id in UnitResearch.rows_for_unit(uid):
			if bank.is_done(id) or bank.is_working(id) or not row_allowed(id, d):
				continue
			var where := _building_for(bank, id, plus_id != &"", halls_free)
			if where == null:
				why.append("%s: %s" % [id, _last_refusal])
				continue
			var need := int(UnitResearch.row(id)["price"]) + int(RESERVE[d]) + maxi(kept_extra, 0) \
					+ _kept_for_others(d, eco, now, faction, plus_id)
			if eco.crystals < need:
				block = "%s waits for %d crystals" % [id, need]
				_waiting_need = need
				return &""   # never saves, never buys a lesser row instead
			if bank.buy(id, where) != "":
				continue
			last_bought = id
			bought.append(id)
			block = ""
			return id
	block = "nothing open (%s)" % ", ".join(why)
	return &""


# own living unit types that have research rows -> count
func _unit_counts() -> Dictionary:
	var out := {}
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or int(u.team) != team or u.unit_type == null or not u.is_alive() or u.unit_type.is_worker:
			continue
		var id := u.unit_type.id
		if not out.has(id):
			if UnitResearch.rows_for_unit(id).is_empty():
				continue
			out[id] = 0
		out[id] = int(out[id]) + 1
	return out


# The unit id whose "+" the bot wants now (UnitUpgrades.bot_try_buy's own pick: >= BOT_MIN_UNITS, not done, not
# running), else &"". Counts come from every own unit with a "+" (also those without research rows).
func _plus_wanted(_counts: Dictionary) -> StringName:
	if not UnitUpgrades.ENABLED or TierSystem.tier_of(team) < UnitUpgrades.TIER_NEEDED:
		return &""
	var plus := UnitUpgrades.for_team(team, false)
	var counts := {}
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.unit_type and u.is_alive() and UnitUpgrades.has_plus(u.unit_type.id) \
				and not UnitUpgrades.team_has(team, u.unit_type.id):
			counts[u.unit_type.id] = int(counts.get(u.unit_type.id, 0)) + 1
	var best: StringName = &""
	for id: StringName in counts:
		if plus != null and plus.is_working(id):
			continue
		if int(counts[id]) >= UnitUpgrades.BOT_MIN_UNITS and (best == &"" or int(counts[id]) > int(counts[best])):
			best = id
	return best


# Completed, living Halls of the team with an empty research slot.
func _free_halls() -> int:
	var n := 0
	for b in Building.for_team(team):
		if b.building_type and b.building_type.kind == &"barracks" and b.is_constructed() \
				and not UnitResearch.building_busy(b):
			n += 1
	return n


# The first own building that can start row `id` now ("" or only short of crystals); the last free Hall is left
# to a wanted "+".
func _building_for(bank: UnitResearch, id: StringName, keep_hall: bool, halls_free: int) -> Building:
	_last_refusal = UnitResearch.REASON_BUILDING
	for b in Building.for_team(team):
		var reason := bank.can_buy(id, b)
		if reason != "" and reason != UnitResearch.REASON_NO_CRYSTALS:
			if reason != UnitResearch.REASON_BUILDING:
				_last_refusal = reason
			continue
		if keep_hall and halls_free <= 1 and b.building_type and b.building_type.kind == &"barracks":
			_last_refusal = "Hall kept for the +"
			continue
		return b
	return null


# Crystals kept for the spenders this rule must not delay: a due keep upgrade, a due Forge or its next card line, a
# wanted "+".
func _kept_for_others(d: int, eco: Economy, now: float, faction: StringName, plus_id: StringName) -> int:
	var kept := 0
	var ts := TierSystem.instance()
	if ts != null and ts.bots_upgrade:
		var st := TierSystem.status(team)
		if not st.is_empty() and int(st.get("next", 0)) > 0 and not bool(st.get("upgrading", false)):
			var tier := int(st.get("tier", 1))
			var times: Array = TierSystem.BOT_START.get(d, TierSystem.BOT_START[1])
			if tier - 1 < times.size() and ts.now() >= float(times[tier - 1]) * ts.pace_time_x - TIER_LOOKAHEAD:
				kept += int(st.get("crystals", 0))
	# A due Forge (the building) is kept for its first FORGE_HOLD s (later only while the Forge step could pay it: the
	# step can wait behind the Stables for minutes, CI 2026-10-14); its next card line only while it could pay it.
	var forge := _forge_kept(d, now, faction)
	if forge.y == 1:
		if _forge_since > now:
			_forge_since = now
	else:
		_forge_since = INF
	if (forge.y == 1 and now - _forge_since < FORGE_HOLD) \
			or (forge.x > 0 and eco.crystals >= forge.x + int(ForgeKit.BOT_RESERVE[d])):
		kept += forge.x
	if plus_id != &"":
		kept += UnitUpgrades.price_of(plus_id)
	return kept


# (crystals, 1 = the Forge building itself is due / 0 = its next card line or nothing).
func _forge_kept(d: int, now: float, faction: StringName) -> Vector2i:
	if not ForgeKit.ENABLED or not ForgeKit.enabled_here():
		return Vector2i.ZERO
	var type := ForgeKit.forge_type(faction)
	if type == null:
		return Vector2i.ZERO
	var forge: ForgeBuilding = null
	for b in Building.for_team(team):
		if b is ForgeBuilding:
			forge = b as ForgeBuilding
	if forge == null:
		if now >= float(ForgeKit.BOT_BUILD_AT[d]) - TIER_LOOKAHEAD and not ForgeKit.spot_backing_off(team, now) \
				and BuildGrid.prerequisite_reason(type, team) == "":
			return Vector2i(type.cost, 1)
		return Vector2i.ZERO
	if not forge.is_constructed() or not forge.queue.is_empty():
		return Vector2i.ZERO
	var cheapest := 0
	for line in ForgeKit.card_lines(faction):
		var lv := ForgeKit.level_of(team, line)
		if lv >= mini(ForgeKit.max_level(line), int(ForgeKit.BOT_MAX_LEVEL[d])):
			continue
		if ForgeKit.tier_of(line, lv + 1) > TierSystem.tier_of(team):
			continue
		var p := ForgeKit.price_of(line, lv + 1)
		if cheapest == 0 or p < cheapest:
			cheapest = p
	return Vector2i(cheapest, 0)
