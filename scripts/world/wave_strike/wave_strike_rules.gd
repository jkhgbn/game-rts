class_name WaveStrikeRules
extends Resource
## Wave Strike mode numbers (docs/design/wave-strike.md section 6; M1 subset). Data: data/wave_strike/rules_default.tres.
## Labs and tests override fields in memory (duplicate first). Card prices live in WaveCardTable (card_prices.tres).

const DEFAULT_PATH := "res://data/wave_strike/rules_default.tres"

@export_group("Horns")
@export var horn_first := 30.0            ## s, the first horn
@export var horn_interval := 40.0         ## s between horns
@export var last_horns_at := 840.0        ## s: from here the interval is last_horns_interval (balance passes 2026-10-06: 24:00 -> 15:00 -> 14:00)
@export var last_horns_interval := 20.0   ## balance pass 2026-10-06: 30 -> 20 s
@export var horn_warning := 5.0           ## s: the HUD countdown turns hot, the bots decide (bot_decide_before)
@export var bot_decide_before := 3.0      ## s before each horn: the bot's decision pass
@export var spawn_stagger := 0.15         ## s between two units of one horn
@export var time_limit := 1800.0          ## s: the higher Bastion HP % wins (0 = off)

@export_group("Economy")
@export var start_crystals := 600            ## M2 (wave-strike.md 14.2): 400 -> 600
@export var base_income := 120            ## per horn (M2: 100 -> 120)
@export var coffer_step := 15             ## + per Coffer level per horn
@export var coffer_prices: Array[int] = [150, 200, 250, 300, 350, 400, 450, 500]
@export var bounty_pct := 0.12            ## of the killed unit's card price, to the killing team
@export var defender_bounty_mult := 1.5   ## kill in the team's own third of the lane
@export var underdog_enabled := true
@export var underdog_pct_per_step := 0.08 ## + income per full underdog_step of Bastion HP gap
@export var underdog_step := 0.15
@export var underdog_max := 0.24

@export_group("Roster")
## 1v1 per tier (Keep, Stronghold, Citadel). M2 (JS 2026-10-13, decisions.md): x1.5 = 36 / 60 / 84 (was 24 / 40 / 56).
@export var supply_cap: Array[int] = [36, 60, 84]
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
## Unit upgrades (wave-strike.md 16: card upgrades A / B + the Armoury; WaveUpgradeTable). Labs switch: false = every
## upgrade buy is refused "Upgrades off".
@export var upgrades_enabled := true

@export_group("Bastion")
@export var bastion_hp_mult := 1.6        ## x the Citadel keep HP (balance passes 2026-10-06: 2.5 -> 2.0 -> 1.6)
@export var bastion_armor := 3.0
## Keep HP the Bastion is built from for EVERY kingdom (0 = the kingdom keep's own max_hp: Ice 3 000, Nature 2 250).
@export var bastion_base_hp := 2500.0

@export_group("Wizard")
@export var wizard_enabled := true
@export var wizard_horn_xp := 40
@export var wizard_respawn_base := 15.0
@export var wizard_respawn_per_level := 2.0
## Wave Strike re-rule of wizard burst (balance pass 2, 2026-10-06; 4.4 "re-ruled" spells): kingdom -> flat
## `spell_power` added to that kingdom's wizard as the modifier "ws_rule" (spell damage x (1 + sp / 100), so -40 =
## x0.6). The waves march bunched in a 40 m lane, so area spells (Fireball, Thornburst) hit far more than in skirmish.
@export var wizard_spell_power: Dictionary = {}
## More per-kingdom wizard stats for the mode, kingdom -> {stat: value} (Unit.add_modifier format, e.g.
## {&"shadow": {"max_hp_pct": 0.4}}), merged into the same "ws_rule" modifier.
@export var wizard_stats: Dictionary = {}

@export_group("Field")
## Most living lane units one seat may field (0 = no limit; balance pass 2, the perf valve of 7.8 (7)): a horn's units
## past it stay home (they are not spawned; the card still marches at the next horn).
@export var field_cap := 150             ## data: 200 (WS2.C3) = at most 400 lane units on the field in a 1v1

@export_group("Lane")
@export var lane_lateral := 8.0           ## m: the widest lateral offset of a marching unit from the lane centre line
@export var leash_melee := 12.0           ## m off its lane line: a unit drops its target and walks back
@export var leash_ranged := 6.0
## Mana of a lane caster when it spawns, x its max mana (WS2.C2: at the skirmish 50 the 75-100 mana spells barely fired).
@export var lane_caster_start_mana_pct := 1.0

@export_group("Formation")
## Muster Pad waves (wave-strike.md 15.3, WaveFormation): the wave walks as a block at its slowest copy's speed until
## first contact (false = each unit at its own speed; release effects then fire at first contact).
@export var march_lock := true
@export var march_speed_floor := 4.0      ## m/s: the locked wave never walks slower (a slower copy simply trails)
@export var march_release_after := 45.0   ## s after the march started: the formation breaks anyway
@export var muster_hold_extra := 0.5      ## s the spawned wave stands after its last copy spawned


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
