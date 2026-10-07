class_name WaveBot
extends Node
## The M1 Wave Strike bot (docs/design/wave-strike.md 4.13, task WS.A1): one decision pass rules.bot_decide_before s
## before each horn (plus one at the start). It buys from a fixed priority table per kingdom and personality, keeps at
## least 40 % of its pop melee, buys Coffers and the Stronghold on its personality's schedule. Deterministic (no rng).
## Personalities (M1: 2 of the 5): "steward" (eco: Coffers first, strong late), "hammer" (aggro: cards first).

const PERSONALITIES := ["steward", "hammer"]
## Card weights per kingdom: the bot fills its pop toward these shares (cards it cannot use yet are skipped).
const MIX := {
	&"fire": {&"flame_guard": 4.0, &"ember_archer": 3.0, &"blaze_rider": 2.0, &"cinder_arbalest": 3.0},
	# balance pass 2026-10-06: every kingdom = line, archer, rider, T2 (the sets of data/wave_strike/card_prices.tres)
	# balance pass 2: Shadow's archer is nightbolt (was bleakbow) and its T2 card barrow_knight (was hollow_oathsworn)
	&"shadow": {&"shade": 4.0, &"nightbolt": 3.0, &"gloam_rider": 2.0, &"barrow_knight": 3.0},
	&"ice": {&"rimeshield": 4.0, &"shardcaster": 3.0, &"snowdrift_rider": 2.0, &"hoarlight_magebow": 3.0},
	&"nature": {&"bramblehorn": 4.0, &"wildwood_archer": 3.0, &"stagrunner": 2.0, &"greenheart_oathkeeper": 3.0},
}
## Per personality: reserve kept unspent, Coffer target level and how much of the bank a Coffer may take, the horn
## from which it buys the Stronghold.
const STYLE := {
	"steward": {"reserve": 0, "coffers": 6, "coffer_from_horn": 1, "stronghold_horn": 6, "citadel_horn": 14},
	"hammer": {"reserve": 0, "coffers": 2, "coffer_from_horn": 8, "stronghold_horn": 9, "citadel_horn": 17},
}
const MELEE_SHARE := 0.4

var seat := 0
var personality := "steward"
var roster: MusterRoster
var bank: WaveBank
var director: WaveDirector
var decisions := 0
var log_lines: Array[String] = []

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
	var next := director.horn_index + 1
	if _decided_for != next and director.time_to_next_horn() <= director.rules.bot_decide_before:
		_decided_for = next
		decide()


## One decision pass (public for tests).
func decide() -> void:
	decisions += 1
	var style: Dictionary = STYLE[personality]
	var horn := director.horn_index + 1
	# 1) the next tier (Stronghold, then Citadel) on the personality's schedule; save for it when short
	var tier_horn := int(style["stronghold_horn"]) if roster.tier == 1 else int(style["citadel_horn"])
	if roster.tier < roster.rules.max_tier and roster.upgrade_left <= 0.0 and horn >= tier_horn:
		if roster.can_upgrade() == "":
			roster.upgrade()
			_log("tier %d" % (roster.tier + 1))
		elif bank.crystals() < roster.next_tier_price():
			_log("saving for tier %d" % (roster.tier + 1))
			return   # save this horn's money
	# 2) Coffers (steward: before cards while under its target; hammer: late and only a few)
	if personality == "steward":
		_buy_coffers(style, horn)
	# 3) cards
	var bought := 0
	while bank.crystals() > int(style["reserve"]):
		var id := _next_card()
		if id == &"" or roster.buy(id) != "":
			break
		bought += 1
		if bought > 60:
			break
	if personality != "steward":
		_buy_coffers(style, horn)
	# 4) ranks: the biggest line first (wave-strike.md 4.4: the late game gets stronger, not bigger)
	var guard := 0
	while guard < 20:
		guard += 1
		var best: StringName = &""
		var best_v := -1
		for id in roster.card_ids():
			if roster.can_rank_up(id) == "" and roster.count(id) * roster.price_of(id) > best_v:
				best_v = roster.count(id) * roster.price_of(id)
				best = id
		if best == &"":
			break
		roster.rank_up(best)
		_log("rank %s %d" % [best, roster.rank(best)])
	# 5) supply full and rich: Coffers beyond the target
	if roster.pop_used() >= roster.cap() and bank.crystals() >= 400:
		while bank.buy_coffer() == "":
			_log("coffer+ %d" % bank.coffer_level)


func _buy_coffers(style: Dictionary, horn: int) -> void:
	if horn < int(style["coffer_from_horn"]):
		return
	while bank.coffer_level < int(style["coffers"]) and bank.buy_coffer() == "":
		_log("coffer %d" % bank.coffer_level)


## The card that brings the roster closest to the mix (melee first while under MELEE_SHARE), "" = none affordable.
func _next_card() -> StringName:
	var mix: Dictionary = MIX.get(roster.kingdom, {})
	var pop_total := 0
	var pop_melee := 0
	for id in roster.cards():
		var t := UnitType.find(String(id))
		if t:
			pop_total += roster.count(id) * roster.pop_of(id)
			if t.attack_range <= 3.0:
				pop_melee += roster.count(id) * roster.pop_of(id)
	var want_melee := pop_total > 0 and float(pop_melee) / float(pop_total) < MELEE_SHARE
	var best: StringName = &""
	var best_score := INF
	var weight_sum := 0.0
	for id in roster.card_ids():
		if roster.tier_of_card(id) <= roster.tier:
			weight_sum += float(mix.get(id, 1.0)) * float(_jitter.get(id, 1.0))
	for id in roster.card_ids():
		if roster.can_buy(id) != "":
			continue
		var t := UnitType.find(String(id))
		if want_melee and t.attack_range > 3.0:
			continue
		var w := float(mix.get(id, 1.0)) * float(_jitter.get(id, 1.0)) / maxf(weight_sum, 0.001)
		var share := float(roster.count(id) * roster.pop_of(id)) / maxf(float(pop_total), 1.0)
		var score := share - w
		if score < best_score:
			best_score = score
			best = id
	if best == &"" and want_melee:
		# no melee card affordable: any card
		for id in roster.card_ids():
			if roster.can_buy(id) == "":
				return id
	return best


func _log(line: String) -> void:
	log_lines.append("%d:%s" % [director.horn_index, line])
