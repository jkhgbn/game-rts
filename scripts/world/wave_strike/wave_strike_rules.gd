class_name WaveStrikeRules
extends Resource
## Wave Strike mode numbers (docs/design/wave-strike.md section 6; M1 subset). Data: data/wave_strike/rules_default.tres.
## Labs and tests override fields in memory (duplicate first). Card prices live in WaveCardTable (card_prices.tres).

const DEFAULT_PATH := "res://data/wave_strike/rules_default.tres"

@export_group("Horns")
@export var horn_first := 30.0            ## s, the first horn
@export var horn_interval := 40.0         ## s between horns
@export var last_horns_at := 900.0        ## s: from here the interval is last_horns_interval (balance pass 2026-10-06: 24:00 -> 15:00)
@export var last_horns_interval := 20.0   ## balance pass 2026-10-06: 30 -> 20 s
@export var horn_warning := 5.0           ## s: the HUD countdown turns hot, the bots decide (bot_decide_before)
@export var bot_decide_before := 3.0      ## s before each horn: the bot's decision pass
@export var spawn_stagger := 0.15         ## s between two units of one horn
@export var time_limit := 1800.0          ## s: the higher Bastion HP % wins (0 = off)

@export_group("Economy")
@export var start_crystals := 400
@export var base_income := 100            ## per horn
@export var coffer_step := 15             ## + per Coffer level per horn
@export var coffer_prices: Array[int] = [150, 200, 250, 300, 350, 400, 450, 500]
@export var bounty_pct := 0.12            ## of the killed unit's card price, to the killing team
@export var defender_bounty_mult := 1.5   ## kill in the team's own third of the lane
@export var underdog_enabled := true
@export var underdog_pct_per_step := 0.08 ## + income per full underdog_step of Bastion HP gap
@export var underdog_step := 0.15
@export var underdog_max := 0.24

@export_group("Roster")
@export var supply_cap: Array[int] = [24, 40, 56]   ## 1v1 per tier (Keep, Stronghold, Citadel)
@export var sell_refund := 0.5
@export var cancel_window := 5.0          ## s: a sell this soon after the buy refunds 100 %
@export var stronghold_price := 250
@export var stronghold_time := 45.0
@export var stronghold_from_horn := 6
@export var citadel_price := 450
@export var citadel_time := 60.0
@export var citadel_from_horn := 14
@export var max_tier := 3                 ## M1: Stronghold + Citadel (supply and rank 3; T3 cards come in M2)
## Card ranks (wave-strike.md 4.4): rank 2 "Drilled" (Stronghold) +60 % of the card price per copy, rank 3 "Elite"
## (Citadel) +100 %; a copy bought later pays the line's ranks too.
@export var rank_pct: Array[float] = [0.6, 1.0]
@export var rank_names: Array[String] = ["Recruit", "Drilled", "Elite"]
@export var last_horns_armor_cut := 0.25  ## Bastion armour -25 % from last_horns_at

@export_group("Bastion")
@export var bastion_hp_mult := 2.0        ## x the kingdom's Citadel keep HP (balance pass 2026-10-06: 2.5 -> 2.0)
@export var bastion_armor := 3.0

@export_group("Wizard")
@export var wizard_enabled := true
@export var wizard_horn_xp := 40
@export var wizard_respawn_base := 15.0
@export var wizard_respawn_per_level := 2.0

@export_group("Lane")
@export var lane_lateral := 8.0           ## m: the widest lateral offset of a marching unit from the lane centre line
@export var leash_melee := 12.0           ## m off its lane line: a unit drops its target and walks back
@export var leash_ranged := 6.0


## The default rules (a fresh copy: callers may change it).
static func load_default() -> WaveStrikeRules:
	var r: WaveStrikeRules = null
	if ResourceLoader.exists(DEFAULT_PATH):
		r = load(DEFAULT_PATH) as WaveStrikeRules
	if r == null:
		return WaveStrikeRules.new()
	return r.duplicate(true) as WaveStrikeRules


## Game time of horn `n` (1-based).
func horn_time(n: int) -> float:
	if n <= 0:
		return 0.0
	var t := horn_first
	for i in range(1, n):
		t += last_horns_interval if t >= last_horns_at else horn_interval
	return t


## Supply cap at `tier` (1-3).
func cap_at(tier: int) -> int:
	return supply_cap[clampi(tier, 1, supply_cap.size()) - 1]


## Price of the next Coffer level after `level` (-1 = maxed).
func coffer_price(level: int) -> int:
	return coffer_prices[level] if level >= 0 and level < coffer_prices.size() else -1
