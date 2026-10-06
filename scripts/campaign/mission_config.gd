class_name MissionConfig
extends Resource
## The data side of a campaign mission (docs/design/mission-framework.md): every shared knob the mission specs name,
## read once by MissionBase at the right moment. A mission builds one in `_mission_config()` (code) or the scene sets
## `config` to a `.tres` (data). Defaults = "off / untouched", so an empty config changes nothing in a mission.
## Difficulty-dependent values are arrays [easy, normal, hard]; a 1-element array applies to every difficulty and an
## empty array leaves the value alone (see `pick`).

# ---------------------------------------------------------------- identity and end
@export var mission_id: StringName = &""
@export var title := ""
## Easy / normal / hard multipliers of scripted counts (MissionBase.scaled: rounded, min 1 unless 0). [] = no scaling
## (mission 1 sets [0.6, 1.0, 1.4]).
@export var count_mult: Array[float] = []
## Unit types dropped from scripted groups on easy ([] = none; mission 1: [&"shadow_knight"]).
@export var easy_skip_types: Array[StringName] = []
## Defeat when the player has no living keep (`keep_lost_message` on screen). Armed only once the player has had a
## living keep at begin_mission or later: a map without a player keep (hero-only phase) is never lost by this rule.
@export var defeat_on_keep_lost := true
@export var keep_lost_message := "The keep has fallen"
## `instant_loss_on_wizard_death` of the specs: the player's hero (set_player_hero re-points it) dying is a defeat
## after `defeat_delay` seconds.
@export var instant_loss_on_wizard_death := false
@export var defeat_delay := 3.0
@export var victory_banner := "VICTORY"
@export var defeat_banner := "DEFEAT"
## MISSION_REWARDS-shaped entry used when CampaignState.MISSION_REWARDS has none for `mission_id`: "artifact",
## "flags" (flag -> objective id), "bonus_essence", "set_flags", "items" (extra owned artifacts), "unlock", "next",
## "save_items" (false = flags only).
@export var rewards: Dictionary = {}

# ---------------------------------------------------------------- systems switches (read by kits from the scene)
@export var tiers_enabled := false
## TierSystem.max_tier (1-3) and bots_upgrade (missions: false).
@export var max_tier := 3
@export var bots_upgrade := false
## Team (int) -> tier the keeps start at (TierSystem.set_start_tier: no announcement, no timer). {} = all tier 1.
@export var start_tiers: Dictionary = {}
@export var casters_enabled := false
## T3 units at the Citadel keep (T3Kit.enabled_here) and the helper call (T3Kit.helpers_here), separately.
@export var t3_enabled := false
@export var helpers_enabled := false
## Helper already on the field at 0:00, as if called (HelperRoster.grant: no price, pop held).
@export var helper_start_called := false
## Mission call price: any of "crystals", "essence", "time" (0 = free); [easy, normal, hard] arrays allowed per key.
@export var helper_call_price: Dictionary = {}
## Titans (titans-2.md): no titan code exists yet; the values are exposed on the mission node for that kit
## (MissionBase.scene_knob). -1 = the kit's default.
@export var titans_enabled := false
@export var lair_max := -1
@export var titan_max_trained := -1
@export var lair_min_time := -1.0
## The kingdom's Forge (unit upgrades, ForgeKit) in this mission (e2m4 spotlights it; default off in missions).
@export var forge_enabled := false
## The kingdom's Stables (cavalry + the wizard's mount, Stables16) in this mission (e2m3 on; default off in missions).
@export var cavalry_enabled := false

# ---------------------------------------------------------------- seats (2v2 runtime, scripts/core/teams.gd)
## Seat -> side ({PLAYER: 0, ALLY: 0, ENEMY: 1, ENEMY_2: 1}); {} = the 1v1. Copied to the level before `_ready`
## (main.gd configures Teams and one Economy per seat).
@export var seat_sides: Dictionary = {}
## Seat -> the seat its Commander plays against (Skirmish.enemy_team_of); {} = the first seat of the other side.
@export var seat_opponents: Dictionary = {}
## Seat -> kingdom of the extra seats (ALLY / ENEMY_2), e.g. {ALLY: &"nature", ENEMY_2: &"ice"}.
@export var seat_kingdoms: Dictionary = {}

# ---------------------------------------------------------------- start state
## The player's wizard: level and unspent spell points at start (-1 = untouched), spells learned in order, cap
## (0 = none; XP past it is dropped, the bar reads full).
@export var start_level := 1
@export var start_spell_points := -1
@export var start_spells: Array[StringName] = []
@export var level_cap := 0
## Crystals by difficulty for the player / the enemy ([] = untouched; 1 value = every difficulty).
@export var start_crystals: Array[int] = []
@export var enemy_start_crystals: Array[int] = []
## Base essence before the carried essence (-1 = the bank's 150), the +1 / s trickle and kill income.
@export var start_essence := -1
@export var essence_trickle := true
@export var kill_essence := true
## Extra pop cap for the player at start (on top of the keep / houses).
@export var start_pop_bonus := 0
## The top bar (crystals, essence, pop) is hidden.
@export var resources_hidden := false
## No-economy mode: 0 crystals and 0 essence for the player, no trickle, no kill income, resources hidden.
@export var economy_enabled := true
## Artifact slots forced at start: [slot 1 id, slot 2 id], "" = leave that slot alone (e8m1 key relic).
@export var forced_artifacts: Array[String] = []

# ---------------------------------------------------------------- bots
## Commander profile for `bot_team` (AIProfile id, e.g. &"mission_01"). &"" = no Commander (scripted enemy only).
@export var bot_profile_id: StringName = &""
@export var bot_team := 1

# ---------------------------------------------------------------- spotlight (mission-framework.md 7)
## The one unit this mission shows at its best (unit-spotlights.md). {} = none. Keys:
##   "id": UnitType / helper id (or a Dictionary {kingdom: id} resolved from the player's kingdom, Ep8),
##   "card": the English intro line (<= 110 chars, shown through Loc.sink),
##   "trigger": &"start" (begin_mission shows it) / &"unlock" / &"manual" (the mission calls show_spotlight()),
##   "key_hint": e.g. "Ember Hall: V" (optional), "highlight_s": the first unit's gold ring time (default 6.0).
@export var spotlight: Dictionary = {}


## `values[difficulty]` ([easy, normal, hard]); one value = all; `fallback` when empty.
static func pick(values: Array, difficulty: int, fallback: Variant = null) -> Variant:
	if values.is_empty():
		return fallback
	if values.size() == 1:
		return values[0]
	return values[clampi(difficulty, 0, values.size() - 1)]
