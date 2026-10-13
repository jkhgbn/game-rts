class_name WaveBot
extends Node
## The Wave Strike bot (docs/design/wave-strike.md 4.13 task WS.A1, M2 14.3 task WS2.A1): one decision pass
## rules.bot_decide_before s before each horn (plus one at the start). It fills its supply toward the MIX weights of its
## kingdom's cards, keeps at least 40 % of its pop melee, holds the 14.3 floors / ceilings (kingdom caster 1 at the
## Stronghold, 2 at the Citadel; support cards <= 10 % of pop; T3 cards 20-30 % of the Citadel cap, bought first),
## swaps cheap T1 copies for a T3 card when the Citadel supply is full, buys Coffers and the next tier on its
## personality's schedule (saving ahead for it). Deterministic (no rng unless rng_seed is set).
## Personalities (M1 / M2: 2 of the 5): "steward" (eco: Coffers first, strong late), "hammer" (aggro: cards first).

const PERSONALITIES := ["steward", "hammer"]
## Card weights per kingdom (14.3): the bot fills its pop toward these shares (cards above its tier are skipped).
const MIX := {
	&"fire": {&"flame_guard": 4.0, &"scorchling": 2.0, &"ember_archer": 3.0, &"ash_hurler": 1.0, &"blaze_rider": 2.0,
			&"cinder_arbalest": 3.0, &"pyre_adept": 1.5, &"kilnwarden": 1.5, &"sunforge_cataphract": 2.0},
	&"ice": {&"rimeshield": 4.0, &"rimeling": 2.0, &"shardcaster": 3.0, &"rime_seer": 1.5, &"snowdrift_rider": 2.0,
			&"hoarlight_magebow": 3.0, &"rimecarver": 1.0, &"rimehorn_rider": 2.0, &"shardguard": 2.0,
			&"frostcrown_juggernaut": 2.0},
	&"nature": {&"bramblehorn": 3.0, &"thornling": 2.0, &"wildwood_archer": 3.0, &"bloomtender": 1.5, &"stagrunner": 2.0,
			&"greenheart_oathkeeper": 3.0, &"vinelasher": 2.0, &"bramblesage": 1.5, &"briar_roc": 2.0,
			&"glade_outrider": 2.0},
	&"shadow": {&"shade": 4.0, &"grave_hound": 2.0, &"nightbolt": 3.0, &"shadow_knight": 2.0, &"gloam_rider": 2.0,
			&"barrow_knight": 3.0, &"hexweaver": 1.5, &"gloom_deacon": 1.5, &"nightblood_reaver": 2.0,
			&"veilborn_dreadrider": 2.0},
}
## The kingdom casters (CasterKit.CASTERS) and the support cards of 14.1.
const CASTER_IDS: Array[StringName] = [&"kilnwarden", &"rimecarver", &"bramblesage", &"gloom_deacon"]
const SUPPORT_IDS: Array[StringName] = [&"pyre_adept", &"rime_seer", &"bloomtender", &"hexweaver"]
## Per personality: reserve kept unspent, Coffer target level, the horn from which it buys Coffers, the horns at which
## it starts the Stronghold / Citadel. WS2.A1: hammer 9 / 17 -> 7 / 16 (a tier takes 45 / 60 s to rise; 7 / 16 is the
## latest start that puts a caster in the horn 9 wave and a T3 card in the horn 18 wave, 14.6).
const STYLE := {
	"steward": {"reserve": 0, "coffers": 6, "coffer_from_horn": 1, "stronghold_horn": 6, "citadel_horn": 14},
	"hammer": {"reserve": 0, "coffers": 2, "coffer_from_horn": 8, "stronghold_horn": 7, "citadel_horn": 16},
}
const MELEE_SHARE := 0.4
const MELEE_RANGE := 3.0
const SUPPORT_MAX_SHARE := 0.10        ## support cards' pop / pop
const T3_MIN_SHARE := 0.20             ## T3 cards' pop / Citadel cap (met too when every T3 card is at max_copies)
const T3_MAX_SHARE := 0.30

var seat := 0
var personality := "steward"
var roster: MusterRoster
var bank: WaveBank
var director: WaveDirector
var decisions := 0
var log_lines: Array[String] = []
var swaps := 0
var first_caster_horn := -1            ## the horn whose wave first holds a caster card (-1 = never)
var first_t3_horn := -1                ## same for a T3 card

## Labs: a seed > 0 jitters the card weights by +-20 % (seeded, so a batch of equal personalities still varies).
var rng_seed := 0:
	set(v):
		rng_seed = v
		_jitter.clear()
		if v > 0:
			var rng := RandomNumberGenerator.new()
			rng.seed = v
			for k in MIX:
				for id in MIX[k]:
					_jitter[id] = rng.randf_range(0.8, 1.2)

var _decided_for := -1
var _swapped_for := -1
var _jitter := {}


func setup(p_seat: int, p_roster: MusterRoster, p_bank: WaveBank, p_director: WaveDirector, p_personality: String) -> void:
	seat = p_seat
	roster = p_roster
	bank = p_bank
	director = p_director
	personality = p_personality if STYLE.has(p_personality) else "steward"
	add_to_group(&"wave_bots")


func _physics_process(_delta: float) -> void:
	if director == null or not director.running:
		return
	poll()


## Runs the decision pass when the next horn is close enough and not decided yet (tests call it after advancing the clock).
func poll() -> void:
	var next := director.horn_index + 1
	if _decided_for != next and director.time_to_next_horn() <= director.rules.bot_decide_before:
		_decided_for = next
		decide()


## One decision pass (public for tests).
func decide() -> void:
	decisions += 1
	var style: Dictionary = STYLE[personality]
	var horn := director.horn_index + 1
	var reserve := int(style["reserve"])
	# 1) the next tier (Stronghold, then Citadel) on the personality's schedule; save ahead for it, wait when short
	if roster.tier < roster.rules.max_tier and roster.upgrade_left <= 0.0:
		var tier_horn := int(style["stronghold_horn"]) if roster.tier == 1 else int(style["citadel_horn"])
		var price := roster.next_tier_price()
		if horn >= tier_horn:
			if roster.can_upgrade() == "":
				roster.upgrade()
				_log("tier %d" % (roster.tier + 1))
			elif bank.crystals() < price:
				_log("saving for tier %d" % (roster.tier + 1))
				return   # save this horn's money
			else:
				reserve = maxi(reserve, price)   # not open yet (the rules' from-horn): keep the price aside
		else:
			# the horns before: keep the price aside (before the Citadel, the first T3 card's price too)
			var goal := price + (_cheapest_open_t3() if roster.tier == 2 else 0)
			if horn >= tier_horn - ceili(float(goal) / float(maxi(bank.income(), 1))):
				reserve = maxi(reserve, goal)
	reserve = maxi(reserve, _t3_reserve())
	# 2) Coffers (steward: before cards while under its target; hammer: late and only a few)
	if personality == "steward":
		_buy_coffers(style, horn, reserve)
	# 3) cards
	var bought: Dictionary = {}
	var n := 0
	while bank.crystals() > 0 and n <= 60:
		var id := _next_card(reserve)
		if id == &"" or roster.buy(id) != "":
			break
		n += 1
		bought[id] = int(bought.get(id, 0)) + 1
		if first_caster_horn < 0 and CASTER_IDS.has(id):
			first_caster_horn = horn
		if first_t3_horn < 0 and roster.tier_of_card(id) >= 3:
			first_t3_horn = horn
	if not bought.is_empty():
		var parts: Array[String] = []
		for id: StringName in bought:
			parts.append(String(id) if int(bought[id]) == 1 else "%s x%d" % [id, bought[id]])
		_log("buy " + ", ".join(parts))
	# 4) Citadel supply full and the T3 share short: swap cheap T1 copies (bought next pass)
	_try_swap(horn)
	reserve = maxi(reserve, _t3_reserve())
	if personality != "steward":
		_buy_coffers(style, horn, reserve)
	# 5) ranks: the biggest line first (wave-strike.md 4.4: the late game gets stronger, not bigger)
	var guard := 0
	while guard < 20:
		guard += 1
		var best: StringName = &""
		var best_v := -1
		for id in roster.card_ids():
			if roster.can_rank_up(id) == "" and bank.crystals() - roster.rank_up_price(id) >= reserve \
					and roster.count(id) * roster.price_of(id) > best_v:
				best_v = roster.count(id) * roster.price_of(id)
				best = id
		if best == &"":
			break
		roster.rank_up(best)
		_log("rank %s %d" % [best, roster.rank(best)])
	# 6) supply full and rich: Coffers beyond the target
	if roster.pop_used() >= roster.cap() and bank.crystals() - reserve >= 400:
		while bank.crystals() - bank.coffer_price() >= reserve and bank.buy_coffer() == "":
			_log("coffer+ %d" % bank.coffer_level)


func _buy_coffers(style: Dictionary, horn: int, reserve: int) -> void:
	if horn < int(style["coffer_from_horn"]):
		return
	while bank.coffer_level < int(style["coffers"]) and bank.crystals() - bank.coffer_price() >= reserve \
			and bank.buy_coffer() == "":
		_log("coffer %d" % bank.coffer_level)


## The roster's pop by group: total, melee, support, T3, plus the caster copies.
func _pops() -> Dictionary:
	var st := {"total": 0, "melee": 0, "support": 0, "t3": 0, "casters": 0}
	for id: StringName in roster.cards():
		var t := UnitType.find(String(id))
		if t == null:
			continue
		var p := roster.count(id) * roster.pop_of(id)
		st["total"] += p
		if t.attack_range <= MELEE_RANGE:
			st["melee"] += p
		if SUPPORT_IDS.has(id):
			st["support"] += p
		if roster.tier_of_card(id) >= 3:
			st["t3"] += p
		if CASTER_IDS.has(id):
			st["casters"] += roster.count(id)
	return st


## The kingdom's T3 cards still below their max_copies.
func _open_t3() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in roster.card_ids():
		if roster.tier_of_card(id) < 3:
			continue
		var most := roster.table.max_copies_of(id)
		if most <= 0 or roster.count(id) < most:
			out.append(id)
	return out


## The T3 floor: 20 % of the Citadel cap, or every T3 card at its max_copies (Fire's 3 cataphracts).
func _t3_met() -> bool:
	if _open_t3().is_empty():
		return true
	return float(_pops()["t3"]) >= T3_MIN_SHARE * float(roster.rules.cap_at(3))


## Crystals kept for a T3 card: at the Citadel (or while it rises) with the T3 floor unmet; 0 otherwise.
func _t3_reserve() -> int:
	if roster.tier < 3 and not (roster.tier == 2 and roster.upgrade_left > 0.0):
		return 0
	if _t3_met():
		return 0
	return _cheapest_open_t3()


func _cheapest_open_t3() -> int:
	var least := 0
	for id in _open_t3():
		var p := roster.unit_price(id)
		if least == 0 or p < least:
			least = p
	return least


## The kingdom caster card while under the caster floor, else "".
func _floor_caster(st: Dictionary) -> StringName:
	if int(st["casters"]) >= _caster_cap():
		return &""
	for id in roster.card_ids():
		if CASTER_IDS.has(id):
			return id
	return &""


## Caster copies allowed at the roster's tier (14.3: 1 at the Stronghold, 2 at the Citadel, never more).
func _caster_cap() -> int:
	return 0 if roster.tier < 2 else (1 if roster.tier == 2 else 2)


func _weight(id: StringName) -> float:
	var mix: Dictionary = MIX.get(roster.kingdom, {})
	return float(mix.get(id, 1.0)) * float(_jitter.get(id, 1.0))


## The card that brings the roster closest to the mix, "" = none allowed. Order: caster floor, T3 floor, then the mix
## (melee first while under MELEE_SHARE; caster / support / T3 ceilings; never below `reserve` except for the floors).
func _next_card(reserve: int) -> StringName:
	var st := _pops()
	var pop_total := int(st["total"])
	# T3 floor (bought before T1 / T2 while under 20 %)
	if roster.tier >= 3 and not _t3_met():
		var t3 := _best_of(_open_t3(), st, -1)
		if t3 != &"":
			return t3
	# caster floor
	var caster := _floor_caster(st)
	if caster != &"" and roster.can_buy(caster) == "":
		return caster
	var want_melee := pop_total > 0 and float(st["melee"]) / float(pop_total) < MELEE_SHARE
	var allowed: Array[StringName] = []
	for id in roster.card_ids():
		if _allowed(id, st, reserve):
			allowed.append(id)
	if want_melee:
		var melee: Array[StringName] = []
		for id in allowed:
			var t := UnitType.find(String(id))
			if t.attack_range <= MELEE_RANGE:
				melee.append(id)
		if not melee.is_empty():
			return _best_of(melee, st, -1)
	return _best_of(allowed, st, -1)


## Buyable now and inside the 14.3 ceilings and the reserve.
func _allowed(id: StringName, st: Dictionary, reserve: int) -> bool:
	if roster.can_buy(id) != "":
		return false
	if bank.crystals() - roster.unit_price(id) < reserve:
		return false
	var p := roster.pop_of(id)
	if CASTER_IDS.has(id) and int(st["casters"]) >= _caster_cap():
		return false
	if SUPPORT_IDS.has(id) and float(int(st["support"]) + p) > SUPPORT_MAX_SHARE * float(int(st["total"]) + p):
		return false
	if roster.tier_of_card(id) >= 3 and float(int(st["t3"]) + p) > T3_MAX_SHARE * float(roster.rules.cap_at(3)):
		return false
	return true


## Among `ids`, the card furthest under its mix share (`max_tier` < 0 = the roster's tier); "" when none is buyable.
func _best_of(ids: Array[StringName], st: Dictionary, max_tier: int) -> StringName:
	var top := roster.tier if max_tier < 0 else max_tier
	var weight_sum := 0.0
	for id in roster.card_ids():
		if roster.tier_of_card(id) <= top:
			weight_sum += _weight(id)
	var best: StringName = &""
	var best_score := INF
	for id in ids:
		if roster.can_buy(id) != "":
			continue
		var share := float(roster.count(id) * roster.pop_of(id)) / maxf(float(st["total"]), 1.0)
		var score := share - _weight(id) / maxf(weight_sum, 0.001)
		if score < best_score:
			best_score = score
			best = id
	return best


## 14.3 swap at the cap: Citadel, supply full, T3 share short, the bank holds the T3 price -> sell the T1 copies with the
## lowest value per pop until the T3 card fits (50 % refund, the pop frees at the next horn; the T3 card is bought by the
## next pass, first in line). One swap per horn. Logged "swap <old> -> <new>". WS2.A1: with the T3 floor met, the same
## swap makes room for the caster floor (the Citadel's 2nd caster would never fit a full supply otherwise).
func _try_swap(horn: int) -> void:
	if roster.tier < 3 or _swapped_for == horn:
		return
	var st := _pops()
	var target: StringName = &""
	if not _t3_met():
		var best_score := INF
		var weight_sum := 0.0
		for id in roster.card_ids():
			weight_sum += _weight(id)
		for id in _open_t3():
			var share := float(roster.count(id) * roster.pop_of(id)) / maxf(float(st["total"]), 1.0)
			var score := share - _weight(id) / maxf(weight_sum, 0.001)
			if score < best_score:
				best_score = score
				target = id
	else:
		target = _floor_caster(st)
	if target == &"":
		return
	var free := roster.cap() - roster.pop_used()
	var need := roster.pop_of(target) - free
	if need <= 0 or bank.crystals() < roster.unit_price(target):
		return
	var sold: Array[String] = []
	while need > 0:
		var worst: StringName = &""
		var worst_v := INF
		for id in roster.card_ids():
			if roster.tier_of_card(id) == 1 and roster.count(id) > 0:
				var v := float(roster.unit_price(id)) / float(maxi(roster.pop_of(id), 1))
				if v < worst_v:
					worst_v = v
					worst = id
		if worst == &"" or roster.sell(worst) != "":
			break
		need -= roster.pop_of(worst)
		sold.append(String(worst))
	if sold.is_empty():
		return
	_swapped_for = horn
	swaps += 1
	_log("swap %s -> %s" % [", ".join(sold), target])


func _log(line: String) -> void:
	log_lines.append("%d:%s" % [director.horn_index, line])
