class_name Commander
extends Node
## The skirmish bot (docs/design/ai.md): Malrik plays the Shadow side of the 1v1 like a player.
## One Commander per bot team, a child of the Skirmish level (scenes/skirmish.tscn). It only uses
## what a player has: command_* orders, Economy, Keep / barracks queues and rallies, BuildGrid.check /
## find_spot / place. It never gets free crystals, and it only knows where enemy units and buildings
## are when its team's fog of war shows them VISIBLE (6.A1; no fog or fog off: when one of its units
## (16 m) or buildings (20 m) sees them) (AIMemory). It scouts unexplored ground. It knows the map: nodes,
## its slots, the crown, where the enemy keep stands.
## It thinks on a Timer every profile.decision_interval seconds (never per frame) and runs the 8 rules
## of ai.md in order: 1 defend, 2 retreat, 3 economy, 4 build, 5 train, 6 scout, 7 attack, 8 wizard.
## At most one placement and one training queue per tick.
## Positions below are the Shadow side's (ai.md "Fixed slots"); a Fire bot uses their point mirror.
## Unit kinds follow the barracks card order: slot 0 basic melee, 1 ranged, 2 fast, 3 heavy
## (Shadow: Shade, Nightbolt, Grave Hound, Shadow Knight), so the same code can play Fire.
## Spells (levels.md "The bot", task 3.A1): every tick the Commander spends Malrik's spell points on the
## first learnable entry of ai.spell_order (_learn_spells, also while he is dead).
## ONE CASTING OWNER: Malrik's own 0.5 s loop (ShadowWizard._ai_cast_with_caster -> SpellCaster.suggest_cast,
## the spells.md rules 1-4) casts; the Commander never calls command_cast / auto_cast while that loop runs.
## The Commander's rule 8 matches it: its HEAL threshold (HERO_LOW) is rule 1's 35 %, so Shroud + the walk
## home and the Commander's retreat send him the same way. If the wizard exposes `ai_auto_cast`
## (handoff for gameplay-coder), the Commander switches it off and becomes the only caster (_cast_check):
## same suggest_cast() rules, every 0.5 s, only after an enemy has stayed within 12 m for ai.reaction_delay.
## Items (items.md "The bot", task 4.A1): AIItems (ai_items.gd) buys the difficulty's build list near an own
## shop and uses Draught / Brace / Blink / Stride / Rallying Cry; idle with an affordable next item, Malrik walks
## to his keep. Without the items system (no inventory) nothing changes.
## Kingdoms (7.A1, 8.A1): any kingdom on either team (PLAYER too, for bot vs bot). The profile comes from the bot
## wizard's kingdom (AIProfile.id_for_faction: Ice, Nature, else the Shadow bot), buildings from
## BuildingType.buildable_for(kingdom), soldiers from the barracks card order. Nature (kingdom-nature.md 6): a third
## house row V3 (any kingdom whose house allows 3), an opening of 3 queued workers, retreat at 50 % and the regrow
## rule (the next attack waits for 85 % average HP or 30 s at the rally), a Thornling scout from 1:30, Ysolde's casts
## through her SpellCaster.suggest_cast() (plus Wild Bloom with no enemy near), Wild Bloom before her retreat.
## Summons (UnitType.lifetime > 0, Saplings) are never ordered or counted.
## Vessa (8.A2): SpellCaster.suggest_cast() has no Fire rules, so a Fire bot casts through AICasts.suggest_vessa()
## (_vessa_cast_check: Fireball on clusters / the enemy wizard, Kindle in a fight, Ember Step to escape or engage).
## It learns by ai.spell_order like Malrik (the slots F / Q / E are Fireball / Ember Step / Kindle).
## Champions (9.C9, champions.md 10, rule 9): AIChampions (ai_champions.gd) hires, revives and places bounty
## flags B1-B4. The bot NEVER orders a unit whose is_commandable() is false (its ChampionBrain drives it): _scan
## keeps champions out of _soldiers, so no army, attack group, scout, defence or rally order reaches them. An own
## champion within 20 m of the rally adds its power() to own_strength (and the home strength); a seen enemy
## champion adds its power() to seen_strength (AIMemory.strength_of). A due hire is saved for like a build (its
## price + 150 crystals kept from training, 20 s rule included, 2 pop kept free); a due hire and (normal / hard)
## a fallen champion's revive hold their essence from the wizard's items.
## Trade (10.A3, market-trade.md 7, rule 10): AITrade (ai_trade.gd). Build row M1 (the Bazaar, after S2) and the
## raid Spires S3 / S4 (10e) are rows like the others (their crystals: cost + 100 / cost + 50, a rebuilt Bazaar 250);
## caravans are queued before soldiers (10c, same 20 s rule); routes, hunters, wares (10d-10g) run after the build
## rule, the exchange (10i) after the champion rule (10h: AIChampions pays revives / hires in gold). Caravans and
## hired trackers are never army: _scan keeps them out of _soldiers / _enemies (0 strength), the Commander never
## orders a caravan (AITrade routes them through the Bazaar and command_trade). A Bazaar is never used as a barracks
## (_barracks = completed kind "barracks" only).
## Stall fix (20.A2, ai-2v2.md 7.2 F1-F5): recovery mode at 0 workers (gold -> crystals, workers first, no caravans or
## wares); trade blocks the concede only while it can still pay for a comeback; a 150 s hard stop with no soldier and no
## delivery; fewer caravans at the pop cap with a small army; the 20 s rule is used up on the queue. All-in with nothing
## left to mine: no new workers, gold -> crystals, trade-fed attacks gather min_attack_pop first.
## Map fill (12.A1, map-fill.md 7, rules 11-13): AIMapFill (ai_mapfill.gd) reads the river, capture points, camps and
## epic beasts through their groups; every rule is a no-op while its system is absent (missions, toggles off).
## 11a / 11e: when rule 7 did not launch, the army at the rally minus the reserve creeps a camp or beast
## (Stage.CREEP, logged CREEP; the wizard joins tier 1, beasts, or by ai.malrik_joins); it ends when the target is
## dead (the wizard then picks up drops within 12 m), under 50 % of the launch HP (retreat) or on any rule-1
## intrusion (recall). 12a / 12c: capture squads (AIMapFill.squad_tick, never home units). 12b: an enemy capturing
## an own point near the base is a rule-1 intruder; farther, the rally group attack-moves there (Stage.POINT) when
## the capturers are <= 0.8 x the rally. 12c: an awake enemy-bank shrine is rule 7's first target row (Stage.SHRINE).
## 13a: with a river the scout walks AIMapFill.SCOUT_PATH_RIVER and crosses at a road bridge; 13b (hard): MID goes
## through AIMapFill.attack_waypoint() when the enemy's Crown Bridge is held. Creatures, beasts and game critters
## are NEUTRAL or not Units: never in _enemies, seen_strength or own_strength, never ordered to be attacked here.
## 20.A3 (think time + attacks): _scan shares one per-frame team split of "units" between the Commanders and classifies
## each unit once (_units_by_team, _kind_of); AIItems remembers item prices; find_spot runs at most every 30 s per row.
## Rule 1 never chases an intruder onto the warden isle or into a living camp (_neutral_ground). Rule 7 compares
## own_strength + the joining wizard with seen_strength and grows impatient once the army is gathered
## (_attack_ratio_now: attack_ratio -> attack_ratio_floor over attack_patience, the floor from first_attack_by with no
## attack yet, attack_full_pop launches anyway). Per-step perf: rule_usec / rule_usec_max / step_usec_median().

enum Difficulty { EASY, NORMAL, HARD }
enum Stage { NONE, CAMP, MID, KEEP, HUNT, RETREAT, CREEP, SHRINE, POINT }
enum HeroState { ANCHOR, DEFEND, ATTACK, HEAL, CROWN, WAIT, JOB }
enum UnitKind { SOLDIER, WORKER, CHAMPION, CARAVAN, TRADE, SUMMON, WIZARD, CASTER }   ## 20.A3 scan cache (_kind_of); CASTER: caster-units.md 8.

const KIND_CACHE_MAX := 2000        ## 20.A3: freed units leave the kind cache once it grows past this.
static var _snapshot := {}           # 20.A3: _units_by_team() result of _snapshot_frame
static var _snapshot_frame := -1
static var _snapshot_tree: SceneTree = null
static var _kinds := {}              # 20.A3: unit instance id -> UnitKind

const SIGHT_UNIT := 16.0
const SIGHT_BUILDING := 20.0
const EYE_CELL := 20.0
const FRESH := 3.0                  ## Seconds: a sighting this recent counts as "there now".
const CALM_TIME := 15.0
const CORE_RADIUS := 30.0           ## Intruders this close to the keep spot are always fought.
const MINOR_SHARE := 0.35           ## 20.A3: intruders <= this x the home strength (away from the core) = a minor defence...
const DETACH_RATIO := 2.0           ## ...fought by the nearest home soldiers worth this x the intruders...
const DETACH_MIN := 2               ## ...and at least this many.
const RECALL_RATIO := 1.5
const HIT_MEMORY := 3.0             ## A hit on a building / worker triggers the defence this long.
const WORKER_DANGER := 10.0
const WORKER_CALM := 6.0
const RALLY_RADIUS := 12.0
const RALLY_HOME := 9.0             ## Rally units further than this (and idle) walk back.
const RALLY_SHARE := 0.8
const SEEN_FLOOR := 250.0
const RETREAT_RADIUS := 15.0
const RETREAT_RATIO := 1.5
const RETREAT_TIMEOUT := 60.0
const EXPAND_STRENGTH := 400.0
## balance-1.md 2f: X1 when home a + b < 2 000 (half of the 4 000 they start with) or at 5:00; X2 (the
## forward hall by the rich node) when home a + b < 800 (a fifth) or at 9:00, with >= 150 crystals and no
## attack out. Shares of the starting home total, so older maps with smaller nodes keep the same moment.
const EXPAND_HOME_SHARE := 0.5
const X2_HOME_SHARE := 0.2
const X2_TIME := 540.0
const X2_MIN_CRYSTALS := 150
const X2_SPOT := Vector3(33.0, 0.0, 33.0)   ## Shadow's RICH_HALL_SPOT (skirmish.gd); Fire: the mirror.
## 6.A1 scouting with fog: the fixed loop's unexplored points first, then the nearest unexplored point of
## a 12 m grid; a leg ends when its point is in sight (or after SCOUT_LEG_TIME); SCOUT_LEGS legs, then home.
const SCOUT_GRID := 12.0
const SCOUT_LEGS := 6
const SCOUT_LEG_TIME := 45.0
const SCOUT_CAMP_AVOID := 14.0      ## Grid points this close to a living warden camp are skipped.
const TOWER2_GAP := 120.0
const STARVE_TIME := 20.0
const SLOT_RETRY := 5.0
const SLOT_TRIES := 3
const SLOT_SEARCH_RETRY := 30.0     ## 20.A3: after a find_spot miss (or a spot-free refusal), the next search.
const MID_GATHER := 4
const MID_RADIUS := 10.0
const MID_TIMEOUT := 40.0
const NEAR_CROWN := 40.0
const BASE_CLEAR_RADIUS := 25.0
const BASE_REACHED := 18.0
const POINT_REACHED := 8.0
const FOCUS_RADIUS := 12.0
const FOCUS_SEARCH := 25.0
const FOCUS_UNITS := 3
const RESERVE := 2
const HERO_LOW := 0.35
const HERO_OK := 0.7
const HERO_HEAL_MAX := 60.0
const HERO_HOME := 12.0
const HERO_CROWN_HP := 0.6
const HERO_FOLLOW := 4.0
const HERO_RESPAWN_WAIT := 20.0
const HERO_ANCHOR_SLACK := 6.0
const CROWN_CLEAR := 12.0
const SCOUT_HOME_HP := 0.5
const WAYPOINT_REACH := 4.0
const CONCEDE_CRYSTALS := 100
## 20.A2 (ai-2v2.md 7.2 F2): no soldier and no crystal delivered (0 workers, 0 soldiers, 0 queued included) for this
## long -> concede whatever stands.
const HARD_STOP_TIME := 150.0
const HARD_STOP_ARM := 300.0        ## ...armed from this match time even if the bot never had a soldier.
const HARD_STOP_LOG := 30.0         ## HOPELESS is logged once a stretch lasts this long.
## 20.A2 F1: recovery also with fewer than this many workers and crystals < worker cost + RECOVERY_MARGIN.
const RECOVERY_WORKERS := 3
const RECOVERY_MARGIN := 50
const RECOVERY_DEPTH := 2           ## Workers queued at once at the keep while recovering.
const NODE_WORKERS := 3
const ORDER_REPEAT := 8.0           ## Same order to the same unit is not re-sent sooner than this.
const LOG_KEEP := 400
const CAST_CHECK := 0.5             ## spells.md: Malrik's cast rules are checked every 0.5 s.
const CAST_NEARBY := 12.0           ## spells.md: "P" = enemies within 12 m.
const SPELL_SLOTS := "FQE"
const SHOP_WALK_DIST := 8.0        ## 4.A1: walks this close to the keep to shop (shops reach 12 m).
## 12.A1 map fill (rules 11-13).
const CREEP_RETREAT_HP := 0.5       ## 11b: a creep turns back under this share of its launch HP.
const SORTIE_MIN_UNITS := 2         ## 11a / 12b: a creep or point sortie needs at least this many soldiers...
const SORTIE_MIN_HP := 0.6          ## ...with this average HP share.
const CREEP_TIMEOUT := 120.0        ## A creep still not over after this goes home.
const CREEP_RETRY := 30.0           ## After a creep turned back (retreat / recall), no creep for this long.
const SCOUT_KEEP_LEAD := 40.0       ## 12a: this long before a scout is due, the would-be scout is kept out of squads.
const POINT_TIMEOUT := 60.0         ## 12b
const POINT_ARRIVED := 10.0
const SHRINE_TIMEOUT := 75.0        ## 12c: the shrine row gives up after this.

## Mix targets per barracks slot: AIProfile.mix_* (ai.md rule 5; Ice: kingdom-ice.md 7).
const RANGED_SHARE := 0.5
const MELEE_SHARE := 0.6
const HEAVY_SLOT := 3               ## Only from ai.heavy_crystals and ai.heavy_soldier_pop (8.A1 knobs).

## Shadow side (the Fire side is the point mirror).
const RALLY := Vector3(30.0, 0.0, -30.0)
const ANCHOR := Vector3(36.0, 0.0, -36.0)
const CROWN_SPOT := Vector3.ZERO
const SCOUT_PATH: Array[Vector3] = [Vector3(16.0, 0.0, -6.0), Vector3(6.0, 0.0, 16.0),
		Vector3(-16.0, 0.0, 6.0), Vector3(-27.0, 0.0, 27.0)]
const SLOT_SHIFTS: Array[Vector3] = [Vector3(0.0, 0.0, 4.0), Vector3(4.0, 0.0, 0.0)]
## Build rows in order (ai.md rule 4). "pos" INF = the natural hall spot of the level.
const ROWS: Array[Dictionary] = [
	{"id": &"H1", "kind": &"barracks", "pos": Vector3(27.0, 0.0, -45.0), "builders": 1},
	{"id": &"V1", "kind": &"house", "pos": Vector3(50.0, 0.0, -46.0), "builders": 1},
	{"id": &"S1", "kind": &"tower", "pos": Vector3(37.0, 0.0, -29.0), "builders": 1},
	{"id": &"V2", "kind": &"house", "pos": Vector3(50.0, 0.0, -52.0), "builders": 1},
	## 8.A1: only for a kingdom whose house max_count is 3+ (Nature's 3 Seed Hollows), keep offset (7, -15).
	{"id": &"V3", "kind": &"house", "pos": Vector3(50.0, 0.0, -58.0), "builders": 1, "min_houses": 3},
	{"id": &"X1", "kind": &"barracks", "pos": Vector3.INF, "builders": 2},
	## Pop 200 (2026-09-27): houses +20, max 9 per kingdom -> rows V4-V9 around the back of the base (a blocked slot
	## falls back to the shifts / find_spot as usual). Each needs the previous V row finished and the pop tight.
	{"id": &"V4", "kind": &"house", "pos": Vector3(56.0, 0.0, -46.0), "builders": 1, "min_houses": 4},
	{"id": &"V5", "kind": &"house", "pos": Vector3(56.0, 0.0, -52.0), "builders": 1, "min_houses": 5},
	{"id": &"V6", "kind": &"house", "pos": Vector3(56.0, 0.0, -40.0), "builders": 1, "min_houses": 6},
	{"id": &"V7", "kind": &"house", "pos": Vector3(44.0, 0.0, -54.0), "builders": 1, "min_houses": 7},
	{"id": &"V8", "kind": &"house", "pos": Vector3(56.0, 0.0, -58.0), "builders": 1, "min_houses": 8},
	{"id": &"V9", "kind": &"house", "pos": Vector3(38.0, 0.0, -56.0), "builders": 1, "min_houses": 9},
	{"id": &"S2", "kind": &"tower", "pos": Vector3(25.0, 0.0, -37.0), "builders": 1},
	## 10.A3 (market-trade.md 7): build row 7 = the Bazaar at M1; 10e raid Spires at S3 (natural) / S4 (rich).
	## "slot": the level's market_slot / tower_slot when it has them (else "pos", mirrored as usual).
	{"id": &"M1", "kind": &"market", "pos": Vector3(45.0, 0.0, -27.0), "builders": 1, "slot": &"M1", "trade": true},
	{"id": &"S3", "kind": &"tower", "pos": Vector3(19.0, 0.0, -1.0), "builders": 1, "slot": &"S3", "trade": true},
	{"id": &"S4", "kind": &"tower", "pos": Vector3(37.0, 0.0, 45.0), "builders": 1, "slot": &"S4", "trade": true},
	{"id": &"X2", "kind": &"barracks", "pos": X2_SPOT, "builders": 2},
]
## 7.A1 Ice walls (hard): offsets from the S1 tower, Shadow side (mirrored for the other side).
const WALL_OFFSETS: Array[Vector3] = [Vector3(-2.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0)]
const ADOPT_RADIUS := 4.0           ## A standing own building this close to a slot fills it (missions).
const SCRIPTED := &"scripted"       ## Group / meta of mission units the Commander never controls.

@export var team: Unit.Team = Unit.Team.ENEMY
@export var difficulty: Difficulty = Difficulty.NORMAL
@export var profile: AIProfile            ## Optional: overrides the preset of `difficulty`.
## 7.A1: &"shadow_default", &"ice_default" or &"mission_01" (AIProfile.for_id at `difficulty`). Empty =
## picked from the bot wizard's kingdom (Ice -> ice_default, else shadow_default) on the first tick.
@export var profile_id: StringName = &""
@export var enabled := true               ## False = the bot does nothing (tests of a passive side).
@export var debug_log := false            ## Prints one line per decision ("[3:31] ATTACK ...").

var ai: AIProfile                         ## Read only: the knobs in use.
var memory := AIMemory.new()              ## Read only.
var own_strength := 0.0                   ## Read only: living soldiers (not workers, wizard, towers) + champions' power within 20 m of the rally.
var seen_strength := 0.0                  ## Read only.
var stage: Stage = Stage.NONE             ## Read only: what the attack group is doing.
var attacks_launched := 0                 ## Read only.
var first_attack_time := -1.0             ## Read only: match time of the first launch.
var all_in := false                       ## Read only: no crystals left to mine or spend: endgame.
var intrusions: Array[float] = []         ## Read only: match time of each defence start.
var log_lines: Array[String] = []         ## Read only: the last decisions.
var tick_count := 0                       ## Read only (perf).
var tick_usec_max := 0                    ## Read only (perf).
var tick_usec_total := 0                  ## Read only (perf).
var tick_max_at := 0.0                    ## Read only (perf): match time of the slowest tick.
var rule_usec := {}                       ## Read only (perf): think step index -> total usec.
var rule_usec_max := {}                   ## Read only (perf, 20.A3): think step index -> slowest single call (usec).
var rule_usec_max_at := {}                ## Read only (perf, 20.A3): think step index -> match time of that call.
var tick_usec_samples: Array[int] = []    ## Read only (perf, 20.A3): every counted tick's usec (median).
var rule_usec_samples := {}               ## Read only (perf, 20.A3): think step index -> Array of usec per tick.
var attack_blocks := {}                   ## Read only (20.A3): why rule 7 did not launch -> think ticks (diagnostics).
var sub_usec := {}                        ## Read only (perf, 20.A3): named sub-step -> total usec.
var sub_usec_max := {}                    ## Read only (perf, 20.A3): named sub-step -> slowest call (usec).
var spells_learned: Array[String] = []    ## Read only: "Q1", "F2"... in the order the bot learned them.
var casts_owned := false                  ## Read only: true = this Commander casts (Malrik's loop is off).
var vessa_casts := {}                     ## Read only (8.A2): Vessa's accepted casts per AICasts rule ("cluster"...).
var items: AIItems                        ## Read only (4.A1): build list progress, purchases, item uses.
var scout_goal := Vector3.INF             ## Read only (6.A1): where the scout is walking (INF = none).
var scout_goals: Array[Vector3] = []      ## Read only (6.A1): every scouting point chosen so far.
var faction: StringName = &""             ## Read only (8.A1): the kingdom this bot plays (set on the first tick).
var workers_queued := 0                   ## Read only (8.A1): workers queued at the keep so far.
var retreat_hp_ratios: Array[float] = []  ## Read only (8.A1): group HP / launch HP at each HP retreat.
var launch_hp_ratios: Array[float] = []   ## Read only (8.A1): the group's average HP share at each launch.
var launch_after_regrow: Array[float] = [] ## Read only (8.A1): seconds waited at the rally before a launch after a retreat.
var champion_ai: AIChampions              ## Read only (9.C9): hires, revives, bounty flags (rule 9).
var trade_ai: AITrade                     ## Read only (10.A3): Bazaar, caravans, routes, gold (rule 10).
var mapfill_ai: AIMapFill                 ## Read only (12.A1): creeps, capture squads, shrines, scout loop (rules 11-13).
var recovering := false                   ## Read only (20.A2 F1): rebuilding workers (see _update_recovery).
var recovery_starts: Array[float] = []    ## Read only (20.A2): match time of each recovery start.
var starve_passes: Array[float] = []      ## Read only (20.A2 F5): match time of each unit queued by the 20 s rule.
var conceded_at := -1.0                   ## Read only (20.A2): match time of the concede (-1 = none).
var concede_reason := ""                  ## Read only (20.A2): "rule", "all-in" or "hard stop".

var _level: Skirmish
var _timer: Timer
var _ready_done := false
var _now := 0.0
var _enemy_team := 0
var _faction: StringName = &""
var _types := {}                          # BuildingType.kind -> BuildingType
var _worker_type: UnitType
var _eco: Economy
var _rally := Vector3.ZERO
var _anchor := Vector3.ZERO
var _node_refs := {}                      # "a" / "b" / "mid" / "rich" -> CrystalNode (may be freed)
var _min_soldier_cost := 70
var _home_start := 0                      # crystals in the home nodes at the start (expansion shares)
var _fog: FogOfWar                        # this tick's fog (null: none or off -> the 16 / 20 m rule)

# this tick's scan (alive only; never kept across ticks)
var _workers: Array[Worker] = []
var _soldiers: Array[Unit] = []
var _enemies: Array[Unit] = []
var _buildings: Array[Building] = []
var _enemy_buildings: Array[Building] = []
var _barracks: Array[TrainingBuilding] = []   # finished, not the keep
var _champions: Array[Unit] = []          # own living champions (never ordered, 9.C9)
var _caravans: Array[Unit] = []           # own living caravans (never army, never ordered here, 10.A3)
var _casters: Array[Unit] = []            # own living caster units (caster-units.md 8: AICasters places them, never the army)
var casters_ai: AICasters                 ## Read only (caster-units.md 8, CU.A1): training, positioning, casting of the casters.
var _champion_home := 0.0                 # their power within 20 m of the rally (in own_strength)
var _wizard: Wizard
var _keep: Keep

# attack group (untyped: members may be freed between ticks)
var _group: Array = []
var _group_ids := {}
var _launch_hp := 0.0
var _stage_since := 0.0
var _hunt_target = null
var _hunt_point := Vector3.INF
var _explore: Array[Vector3] = []
var _hero_joins := false
var _sortie: Dictionary = {}              # 12.A1: the creep / point / shrine target of Stage CREEP / POINT / SHRINE
var _sortie_retreat := false              # the running retreat comes from a creep / point sortie (no regrow wait)
var _launched_tick := false               # rule 7 launched this tick (11a creeps only when it did not)
var _mid_goal := Vector3.ZERO             # Stage.MID's point: the crown, or (13b) a crossing waypoint
var _creep_retry_at := -INF               # 11b: no new creep before this after one turned back

# scout
var _scout = null
var _scout_wp := 0
var _next_scout := 0.0
var _scout_leg_since := 0.0
var _scout_grid: Array[Vector3] = []
var _scout_via := Vector3.INF             # 13a: a road bridge to walk through before the scout's goal

# defence
var _defending := false
var _intrusion_since := -1.0
var _last_intrusion := -INF
var _intruder_pos := Vector3.INF
var _defend_fight := false                # false: outnumbered away from the core, hold the rally
var _minor_defence := false               # 20.A3: a small intrusion away from the core: only _detached fight it
var _detached := {}                       # 20.A3: instance id -> true, the soldiers sent at a minor intrusion
var _hit_by = null
var _hit_time := -INF

# workers
var _worker_hp := {}                      # id -> hp last tick
var _worker_hit := {}                     # id -> time of the last hit
var _fleeing := {}                        # id -> [worker, node to go back to]
var _expansion_moved := false
var _x2_moved := false

# builds
var _rows: Array[Dictionary] = []        # this profile's build rows (ROWS filtered + walls)
var _skipped_rows := {}                   # row id -> true: never built (a wall that would block the path)
var _follow_units: Array = []             # follow_units(): the wizard follows these (mission Final wave)
var _slot_building := {}                  # row id -> Building
var _trigger_time := {}                   # row id -> time it started waiting
var _slot_tries := {}
var _slot_retry_at := {}
var _pending_row := {}
var _pending_cost := 0
var _build_cost := 0                      # crystals of the waiting build row only (_pending_cost may be a hire's)
var _starve_since := -1.0
var _starve_pass := false                 # the last _can_spend() true came from the 20 s rule (F5: armed on queue)
var _hopeless_since := -1.0               # 20.A2 F2 hard stop: no soldier and no worker delivery since
var _last_gathered := -1                  # Economy.gathered_total at the last concede check
var _had_soldier := false                 # the hard stop is armed once a soldier ever lived (or from HARD_STOP_ARM)
var _hopeless_logged := false
var _placed := 0
var _far_node: CrystalNode = null         # 20.A3: _safe_far_node() of the tick at _far_node_at
var _far_node_at := -1.0
var _far_node_home := Vector3.INF
var _cap_max := -1                        # 20.A3: _pop_cap_max() of the tick at _cap_max_at
var _cap_max_at := -1.0
var _queued_this_tick := false
var _place_usec := 0

# orders and signals
var _orders := {}                         # unit id -> [kind, pos, time]
var _connected := {}                      # building id -> true
var _hero_state: HeroState = HeroState.ANCHOR
var _hero_since := 0.0
var _hero_was_dead := false
var _hero_wait_until := -1.0
var _cast_timer: Timer
var _threat_since := -1.0                 # match time an enemy came within CAST_NEARBY (-1 = none)
var _regrow_since := -1.0                 # match time the last retreat got back to the rally (-1 = none pending)
var _gathered_since := -1.0               # 20.A3: match time rule 7's army became gathered (pop + rally share)
var _regrow_logged := false


func _ready() -> void:
	# One bot per team: a second Commander for the same team (e.g. a test's and the level's) leaves.
	for sibling in get_parent().get_children():
		if sibling != self and sibling is Commander and int((sibling as Commander).team) == int(team) \
				and not sibling.is_queued_for_deletion():
			queue_free()
			return
	if profile != null:
		ai = profile
	elif profile_id != &"":
		ai = AIProfile.for_id(profile_id, int(difficulty))
	else:
		ai = AIProfile.for_difficulty(difficulty)   # replaced by the kingdom's profile on the first tick
	_timer = Timer.new()
	_timer.wait_time = ai.decision_interval
	_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_timer.autostart = true
	_timer.timeout.connect(_think)
	add_child(_timer)


## The Commander of `for_team` under `level`, or null.
static func for_team(level: Node, for_team_id: int) -> Commander:
	if level == null:
		return null
	for child in level.get_children():
		var c := child as Commander
		if c and int(c.team) == for_team_id:
			return c
	return null


## True for mission units the Commander must leave alone: group "scripted" or meta "scripted" = true.
static func is_scripted(n: Node) -> bool:
	if n == null:
		return false
	return n.is_in_group(SCRIPTED) or (n.has_meta(SCRIPTED) and bool(n.get_meta(SCRIPTED)))


## Mission hook (mission-01.md Final wave): from now on the bot wizard leaves his anchor and follows the
## living units of `units` (attack-move a few metres behind their centre; the HEAL retreat still applies).
## An empty array sends him back to his anchor.
func follow_units(units: Array) -> void:
	_follow_units = units.duplicate()
	_log("WIZARD follows %d scripted units" % units.size())


func tick_usec_average() -> float:
	return float(tick_usec_total) / maxf(1.0, float(tick_count))


## 20.A3: the median think tick (usec), 0 before the first counted tick.
func tick_usec_median() -> float:
	if tick_usec_samples.is_empty():
		return 0.0
	return _median(tick_usec_samples)


## 20.A3: the median usec of think step `i` (STEP_NAMES order).
func step_usec_median(i: int) -> float:
	return _median(rule_usec_samples.get(i, []))


static func _median(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var s := samples.duplicate()
	s.sort()
	return float(s[s.size() / 2])


## 20.A3: adds the time since `since` (Time.get_ticks_usec()) to the named sub-step.
func _sub(key: String, since: int) -> void:
	var u := Time.get_ticks_usec() - since
	sub_usec[key] = int(sub_usec.get(key, 0)) + u
	if u > int(sub_usec_max.get(key, 0)):
		sub_usec_max[key] = u


## 20.A3: the think step names in `rule_usec` index order (perf reports).
const STEP_NAMES: Array[String] = ["scan", "memory", "track_workers", "all_in", "pending", "defend", "retreat",
		"economy", "build", "train", "scout", "attack", "wizard", "concede", "learn", "champions", "items",
		"trade_sense", "trade", "exchange", "mapfill_sense", "mapfill"]


# ---------------------------------------------------------------- the think tick

func _think() -> void:
	if not enabled:
		return
	if _level == null:
		_level = get_parent() as Skirmish
		if _level == null:
			_level = get_tree().current_scene as Skirmish
		if _level == null:
			return
	if not _level.match_started or _level.game_over:
		return
	var t0 := Time.get_ticks_usec()
	_now = _level.match_time()
	_queued_this_tick = false
	_launched_tick = false
	_place_usec = 0
	var first := not _ready_done
	if first:
		_setup()
	var steps: Array[Callable] = [_scan, _update_memory, _track_workers, _check_all_in, _compute_pending, _rule_defend,
			_rule_retreat, _rule_economy, _rule_build, _rule_train, _rule_scout, _rule_attack, _rule_wizard,
			_check_concede, _learn_spells, _rule_champions, _rule_items, _trade_sense, _rule_trade, _trade_exchange,
			_mapfill_sense, _rule_mapfill]
	# 10.A3: the trade steps run at their place in the rule order (indices 17-19 keep rule_usec's old keys).
	# 12.A1: the map-fill sense before rule 1 (12b intruders), rules 11-12 right after rule 7 (20, 21).
	var order: Array[int] = [0, 1, 17, 20, 2, 3, 4, 5, 6, 7, 8, 18, 9, 10, 11, 21, 12, 13, 14, 15, 19, 16]
	for i in order:
		var s0 := Time.get_ticks_usec()
		steps[i].call()
		var su := Time.get_ticks_usec() - s0
		rule_usec[i] = int(rule_usec.get(i, 0)) + su
		if not first:
			if su > int(rule_usec_max.get(i, 0)):
				rule_usec_max[i] = su
				rule_usec_max_at[i] = _now
			if not rule_usec_samples.has(i):
				rule_usec_samples[i] = []
			(rule_usec_samples[i] as Array).append(su)
	# t3-helpers.md 9 (T3 agent): call / revive the helper, its stance, 1-2 T3 units, Saboteurs, the Genie. T3Kit.ENABLED.
	if T3Kit.ENABLED:
		T3Kit.bot_tick(int(team), int(difficulty), _keep if is_instance_valid(_keep) else null, _now)
	# BuildGrid.place (site + navmesh rebake request) costs the same for a player: not counted.
	var dt := Time.get_ticks_usec() - t0 - _place_usec
	if first:
		return   # the first tick loads resources once: not counted
	tick_count += 1
	tick_usec_total += dt
	tick_usec_samples.append(dt)
	if dt > tick_usec_max:
		tick_usec_max = dt
		tick_max_at = _now


func _setup() -> void:
	_ready_done = true
	_enemy_team = Skirmish.enemy_team_of(team)
	_eco = Economy.for_team(team)
	_rally = _side(RALLY)
	_anchor = _side(ANCHOR)
	var k := _level.keep_of(team)
	_faction = _detect_faction(k)
	faction = _faction
	if profile == null and profile_id == &"":
		ai = AIProfile.for_id(AIProfile.id_for_faction(_faction), int(difficulty))
		_timer.wait_time = ai.decision_interval
	for t in BuildingType.buildable_for(_faction):
		_types[t.kind] = t
	trade_ai = AITrade.new(int(team), _enemy_team, ai)
	if trade_ai.active():
		var market := AITrade.market_type(_faction)   # buildable_for lists it only while trade is active
		if market:
			_types[&"market"] = market
	_worker_type = null
	if k and not k.trainable_types().is_empty():
		_worker_type = k.trainable_types()[0]
	else:
		var keep_type := BuildingType.find("%s_keep" % _faction)
		if keep_type:
			for t in keep_type.trains:
				if t and t.is_worker:
					_worker_type = t
					break
	_build_rows()
	_adopt_buildings()
	var barracks: BuildingType = _types.get(&"barracks")
	if barracks:
		_min_soldier_cost = 1 << 30
		for t in barracks.trains:
			if t:
				_min_soldier_cost = mini(_min_soldier_cost, t.cost)
	# Own node refs, kept untyped: Skirmish.node_of() errors once a depleted node is freed.
	for suffix in ["a", "b", "mid", "rich"]:
		_node_refs[suffix] = _level.node_of(int(team), suffix)
	for n in _home_nodes():
		_home_start += n.crystals_left
	var steps_x := int(MapInfo.half_x() / SCOUT_GRID)   # MT1: the running map's size (120 m: 5)
	var steps_z := int(MapInfo.half_z() / SCOUT_GRID)
	for i in range(-steps_x + 1, steps_x):
		for j in range(-steps_z + 1, steps_z):
			_scout_grid.append(Vector3(i * SCOUT_GRID, 0.0, j * SCOUT_GRID))
	_next_scout = ai.first_scout_time if ai.first_scout_time >= 0.0 else ai.scout_interval
	items = AIItems.new(int(team), ai.item_build, ai.potion_stock)
	champion_ai = AIChampions.new(int(team), _enemy_team, ai)
	champion_ai.trade = trade_ai
	mapfill_ai = AIMapFill.new(int(team), _enemy_team, ai)
	mapfill_ai.setup(get_tree(), _level)
	champion_ai.mapfill = mapfill_ai
	if CasterKit.ENABLED and casters_ai == null:
		casters_ai = AICasters.new(self)
		add_child(casters_ai)
	_mid_goal = CROWN_SPOT
	_log("START %s bot (%s), team %d, %s" % [ai.id, ai.profile_id, int(team), _faction])


## The team's kingdom: Skirmish.kingdom_of(team) when it exists, else the bot wizard's (UnitType.faction), else its
## keep's, else Shadow (ENEMY) / Fire.
func _detect_faction(k: Keep) -> StringName:
	if _level.has_method(&"kingdom_of"):   # 8.S2: the skirmish knows each side's (checked) kingdom
		var kd: Variant = _level.call(&"kingdom_of", int(team))
		if kd is StringName and kd != &"":
			return kd
	var w := _level.wizard_of(team)
	if w:
		var f: Variant = w.get(&"faction")   # a wizard script may name its kingdom
		if f is StringName and f != &"" and f != &"neutral":
			return f
		if w.unit_type and w.unit_type.faction != &"" and w.unit_type.faction != &"neutral":
			return w.unit_type.faction
	if k and k.building_type and k.building_type.faction != &"":
		return k.building_type.faction
	return &"shadow" if team == Unit.Team.ENEMY else &"fire"


## The build rows of this profile: ROWS filtered by ai.build_rows, plus the Ice walls after S1 (7.A1).
func _build_rows() -> void:
	_rows.clear()
	for row: Dictionary in ROWS:
		if not ai.build_rows.is_empty() and not ai.build_rows.has(String(row["id"])):
			continue
		if row["id"] == &"X2" and not ai.second_expansion:
			continue
		if row.get("trade", false) and (trade_ai == null or not trade_ai.active() or not _types.has(row["kind"])):
			continue   # 10.A3: no Bazaar / raid Spires without trade (missions, trade off, profile.trade false)
		if row.has("min_houses"):
			var house: BuildingType = _types.get(row["kind"])
			if house == null or house.max_count < int(row["min_houses"]):
				continue   # V3-V9: only while the kingdom's house max_count allows that many
		_rows.append(row)
		if row["id"] == &"S1" and ai.build_walls and _types.has(&"wall"):
			for i in WALL_OFFSETS.size():
				_rows.append({"id": StringName("W%d" % (i + 1)), "kind": &"wall", "pos": WALL_OFFSETS[i],
						"builders": 1, "wall": true})


## Buildings the level placed on a slot (a mission's Gloom Hall, Night Spire, Hovel) count as that slot.
func _adopt_buildings() -> void:
	for node in get_tree().get_nodes_in_group("buildings"):
		var b := node as Building
		if b == null or not b.is_alive() or int(b.team) != int(team) or b is Keep or b.building_type == null:
			continue
		for row: Dictionary in _rows:
			var pos: Vector3 = row["pos"]
			if row.get("wall", false) or pos == Vector3.INF or _slot_building.has(row["id"]):
				continue
			if row["kind"] == b.building_type.kind and _flat(_row_base(row), b.global_position) <= ADOPT_RADIUS:
				_slot_building[row["id"]] = b
				_log("SLOT %s = %s already standing" % [row["id"], b.building_type.display_name])
				break


## One pass over "units" and "buildings".
func _scan() -> void:
	_workers.clear()
	_soldiers.clear()
	_enemies.clear()
	_buildings.clear()
	_barracks.clear()
	_champions.clear()
	_caravans.clear()
	_casters.clear()
	_champion_home = 0.0
	own_strength = 0.0
	_wizard = _level.wizard_of(team)
	_keep = _level.keep_of(team)
	_fog = _find_fog()
	var s0 := Time.get_ticks_usec()
	# 20.A3: the living units split by team once per physics frame for every Commander, and each unit's kind (fixed by
	# its type and spawn groups) classified once: the old loop re-tested every unit of the map with 5-8 calls per tick.
	var by_team := _units_by_team(get_tree())
	for n: Variant in by_team.get(int(team), []):
		if not is_instance_valid(n):
			continue
		var u := n as Unit
		if not u.is_alive() or is_scripted(u):
			continue   # mission units: never ordered, never counted (mission-01.md)
		match _kind_of(u):
			UnitKind.CARAVAN:
				_caravans.append(u)   # 10.A3: caravans (AITrade routes them) are never army: 0 strength, no orders
			UnitKind.CHAMPION:
				# 9.C9: champions (their brain drives them) never join an army, group, defence or order; near
				# the rally their power counts in own_strength (champions.md 10).
				_champions.append(u)
				if _flat(u.global_position, _rally) <= AIChampions.STRENGTH_RADIUS:
					var p := AIMemory.strength_of(u)
					own_strength += p
					_champion_home += p
			UnitKind.WORKER:
				_workers.append(u as Worker)
			UnitKind.SOLDIER:
				_soldiers.append(u)
				own_strength += AIMemory.strength_of(u)
			UnitKind.CASTER:
				# caster-units.md 8.2: casters never join the army's orders (AICasters keeps them 4 m behind it); they
				# count cost x 0.5 (x 1.0 with mana) in the strength.
				_casters.append(u)
				own_strength += AIMemory.strength_of(u)
			# TRADE (hired trackers: their contract drives them), SUMMON (8.A1 Saplings), WIZARD: skipped
	for n: Variant in by_team.get(_enemy_team, []):
		if not is_instance_valid(n):
			continue
		var u := n as Unit
		var k := _kind_of(u)
		if not u.is_alive() or k == UnitKind.CARAVAN or k == UnitKind.TRADE:
			continue   # caravans / trackers: 0 strength in seen_strength, never intruders (10.A3)
		if _fog == null or _fog.is_visible(int(team), u.global_position):
			_enemies.append(u)   # with fog: only the ones a player of this team would see now
	_sub("scan.units", s0)
	_enemy_buildings.clear()
	for node in get_tree().get_nodes_in_group("buildings"):
		var b := node as Building
		if b == null or not b.is_alive():
			continue
		if int(b.team) != int(team):
			if int(b.team) == _enemy_team:
				_enemy_buildings.append(b)
			continue
		_buildings.append(b)
		if b is TrainingBuilding and not b is Keep and b.is_constructed() and b.building_type \
				and b.building_type.kind == &"barracks":
			_barracks.append(b as TrainingBuilding)   # 10.C2: never the Bazaar (it trains caravans)
		var id := b.get_instance_id()
		if not _connected.has(id):
			_connected[id] = true
			b.damaged.connect(_on_building_damaged)
	_prune(_group, _group_ids)
	if _scout != null and (not is_instance_valid(_scout) or not (_scout as Unit).is_alive()):
		_scout = null


## 20.A3: the living "units" grouped by team ({team: Array}), built once per physics frame and shared by every
## Commander (the bots think on the same frame). Units freed later in the frame are skipped by the callers.
static func _units_by_team(tree: SceneTree) -> Dictionary:
	var frame := Engine.get_physics_frames()
	if frame == _snapshot_frame and _snapshot_tree == tree:
		return _snapshot
	_snapshot_frame = frame
	_snapshot_tree = tree
	_snapshot = {}
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		var t := int(u.team)
		if not _snapshot.has(t):
			_snapshot[t] = []
		(_snapshot[t] as Array).append(u)
	if _kinds.size() > KIND_CACHE_MAX:
		for id: int in _kinds.keys():
			if not is_instance_id_valid(id):
				_kinds.erase(id)
	return _snapshot


## 20.A3: what a unit is for the scan, classified once per unit (type and spawn groups never change): trade units
## (caravans, 10.A3; hired trackers) first, then champions (not commandable, 9.C9), workers, summons (8.A1),
## wizards, soldiers.
static func _kind_of(u: Unit) -> UnitKind:
	var id := u.get_instance_id()
	var k: Variant = _kinds.get(id)
	if k != null:
		return k
	var kind := UnitKind.SOLDIER
	if AITrade.is_trade_unit(u):
		kind = UnitKind.CARAVAN if TradeNetwork.is_caravan(u) else UnitKind.TRADE
	elif not u.is_commandable():
		kind = UnitKind.CHAMPION
	elif CasterKit.is_caster_unit(u):
		kind = UnitKind.CASTER
	elif u is Worker:
		kind = UnitKind.WORKER
	elif AICasts.is_summon(u):
		kind = UnitKind.SUMMON
	elif u is Wizard:
		kind = UnitKind.WIZARD
	_kinds[id] = kind
	return kind


## The level's fog of war when it exists and is on (6.A1), else null (the 16 / 20 m rule is used).
func _find_fog() -> FogOfWar:
	if _level == null:
		return null
	var v: Variant = _level.get(&"fog")
	if v == null or not is_instance_valid(v) or not v is FogOfWar:
		return null
	var f := v as FogOfWar
	return f if f.enabled else null


func _building_visible(b: Building) -> bool:
	var p := b.global_position
	if _fog.is_visible(int(team), p):
		return true
	var r := maxf(b.target_radius() - 0.5, 0.0)
	if r <= 0.0:
		return false
	for d: Vector3 in [Vector3(r, 0.0, 0.0), Vector3(-r, 0.0, 0.0), Vector3(0.0, 0.0, r), Vector3(0.0, 0.0, -r)]:
		if _fog.is_visible(int(team), p + d):
			return true
	return false


## True if this team sees `pos` now: its fog cell is VISIBLE (without fog: always, the caller uses radii).
func _can_see(pos: Vector3) -> bool:
	return _fog == null or _fog.is_visible(int(team), pos)


## With fog (6.A1): every enemy in a VISIBLE cell of this team enters memory (_enemies is already
## filtered in _scan); a building when its centre or one of its 4 edge points is visible.
## Without fog: everything within 16 m of a bot unit or 20 m of a bot building (grid of 20 m cells).
func _update_memory() -> void:
	if _fog != null:
		for e in _enemies:
			memory.see_unit(e, _now)
		for b in _enemy_buildings:
			if _building_visible(b):
				memory.see_building(b, _now)
		memory.forget(_now, ai.memory_seconds)
		seen_strength = memory.strength()
		return
	var grid := {}
	for w in _workers:
		_add_eye(grid, w.global_position, SIGHT_UNIT)
	for u in _soldiers:
		_add_eye(grid, u.global_position, SIGHT_UNIT)
	if _wizard and _wizard.is_alive():
		_add_eye(grid, _wizard.global_position, SIGHT_UNIT)
	for b in _buildings:
		_add_eye(grid, b.global_position, SIGHT_BUILDING)
	for e in _enemies:
		if _sees(grid, e.global_position, 0.0):
			memory.see_unit(e, _now)
	for b in _enemy_buildings:
		if _sees(grid, b.global_position, b.target_radius()):
			memory.see_building(b, _now)
	memory.forget(_now, ai.memory_seconds)
	seen_strength = memory.strength()


func _add_eye(grid: Dictionary, p: Vector3, r: float) -> void:
	var key := Vector2i(floori(p.x / EYE_CELL), floori(p.z / EYE_CELL))
	if not grid.has(key):
		grid[key] = []
	(grid[key] as Array).append(Vector3(p.x, p.z, r))


func _sees(grid: Dictionary, p: Vector3, extra: float) -> bool:
	var cx := floori(p.x / EYE_CELL)
	var cz := floori(p.z / EYE_CELL)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var eyes: Variant = grid.get(Vector2i(cx + dx, cz + dz))
			if eyes == null:
				continue
			for eye: Vector3 in eyes:
				var r := eye.z + extra
				if (eye.x - p.x) * (eye.x - p.x) + (eye.y - p.z) * (eye.y - p.z) <= r * r:
					return true
	return false


func _check_all_in() -> void:
	if not all_in and _out_of_crystals():
		all_in = true
		_log("ALL-IN: nothing left to mine or buy (%d crystals, %d workers, %d nodes left)" % [_eco.crystals,
				_workers.size(), get_tree().get_nodes_in_group("crystal_nodes").size()])
	elif all_in and recovering and _trade_funds_comeback() and not _out_of_crystals() and _node_left():
		# 20.A2: trade gold turns into crystals again: rebuild workers instead of throwing them at the enemy.
		all_in = false
		_log("ALL-IN off: trade gold pays for workers again (%d crystals)" % _eco.crystals)


## 20.A2 F2: an own completed Bazaar whose gold can still pay for a comeback (AITrade.can_fund_comeback).
func _trade_funds_comeback() -> bool:
	return trade_ai != null and trade_ai.active() and trade_ai.can_fund_comeback(_now)


## Worker HP drops = "a worker takes damage" (for the defence and the flee rule).
func _track_workers() -> void:
	var seen_ids := {}
	for w in _workers:
		var id := w.get_instance_id()
		seen_ids[id] = true
		var before: float = _worker_hp.get(id, w.hp)
		if w.hp < before - 0.01 and w != _scout and not _group_ids.has(id):   # away from home: no defence
			_worker_hit[id] = _now
			var attacker := _nearest_enemy_fighter(w.global_position, SIGHT_UNIT)
			if attacker:
				_hit_by = attacker
				_hit_time = _now
			elif trade_ai != null and trade_ai.active():
				# 10j: a worker hit by a Magpie within 35 m of an own building is a rule-1 intrusion.
				var thief := trade_ai.magpie_near(w.global_position, SIGHT_UNIT)
				if thief != null and _distance_to_base(w.global_position) <= AITrade.DEFEND_RADIUS:
					_hit_by = thief
					_hit_time = _now
		_worker_hp[id] = w.hp
	if tick_count % 30 == 0:
		for id in _worker_hp.keys():
			if not seen_ids.has(id):
				_worker_hp.erase(id)
				_worker_hit.erase(id)
		for id in _orders.keys():
			if not is_instance_id_valid(id):
				_orders.erase(id)


func _on_building_damaged(_amount: float, attacker: Variant) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	var n := attacker as Node3D
	if n and n.get(&"team") != null and int(n.get(&"team")) == _enemy_team:
		_hit_by = n
		_hit_time = _now


# ---------------------------------------------------------------- rule 1: defend

func _rule_defend() -> void:
	var intruder: Node3D = null
	var best := INF
	var intruder_strength := 0.0
	var wardens := _camp_alive()
	for e in _enemies:
		if e is Worker:
			continue
		var d := _distance_to_base(e.global_position)
		if d <= ai.defend_radius:
			if _neutral_ground(e.global_position, wardens):
				continue   # 20.A3: never chased onto the warden isle or into a living camp (a hit still counts)
			memory.see_unit(e, _now)
			intruder_strength += AIMemory.strength_of(e)
			if d < best:
				best = d
				intruder = e
	if intruder == null and _hit_by != null and _now - _hit_time <= HIT_MEMORY \
			and is_instance_valid(_hit_by) and bool((_hit_by as Object).call(&"is_alive")):
		intruder = _hit_by as Node3D
		intruder_strength = maxf(intruder_strength, AIMemory.strength_of(intruder))

	if intruder != null:
		_last_intrusion = _now
		_intruder_pos = intruder.global_position
		if not _defending:
			if _intrusion_since < 0.0:
				_intrusion_since = _now
				# One extra think exactly when the reaction delay is over (not up to a tick later).
				get_tree().create_timer(ai.reaction_delay, false, true).timeout.connect(_think)
				_log("INTRUDER %s seen, reacting in %.1f s" % [_name_of(intruder), ai.reaction_delay])
			if _now - _intrusion_since >= ai.reaction_delay - 0.05:   # a frame of slack for the extra think
				_defending = true
				intrusions.append(_now)
				_log("DEFEND vs %s at %s, str %.0f vs home %.0f" % [_name_of(intruder),
						_xz(_intruder_pos), intruder_strength, _home_strength()])
	else:
		_intrusion_since = -1.0
		if _defending and _now - _last_intrusion >= CALM_TIME:
			_defending = false
			_intruder_pos = Vector3.INF
			_log("DEFENCE over")
			for id in _fleeing.keys():
				_release_worker(id)

	_defend_fight = false
	if _defending and intruder != null:
		var outnumbered := intruder_strength > RECALL_RATIO * _home_strength()
		var at_point := stage == Stage.POINT and _flat(_intruder_pos, _sortie.get("pos", Vector3.INF)) <= POINT_ARRIVED + 5.0
		if stage == Stage.CREEP or (stage == Stage.POINT and not at_point):
			_start_retreat("recalled home from the %s (intruders %.0f)" % [_sortie_name(), intruder_strength])   # 11b
		elif _group_out() and outnumbered:
			_start_retreat("recalled home (intruders %.0f)" % intruder_strength)
		# Outnumbered away from the core (at the forward hall): hold the rally, don't feed units one
		# by one; in the core base everyone fights.
		var core := _flat(_intruder_pos, _level.base_center(int(team))) <= CORE_RADIUS
		_defend_fight = core or not outnumbered
		# 20.A3: a minor intrusion away from the core (a raiding champion or scout at the forward hall: <= 35 % of the
		# home strength) gets a detachment, the nearest home soldiers worth 2x the intruders (2 at least); the rest
		# holds the rally and rule 7 may still launch. Before, every harass pulled the whole army out for 30-60 s
		# (the Fire bot was "defending" ~48 % of its ticks) and fed it to whatever stood behind the intruder.
		var home_s := _home_strength()
		_minor_defence = _defend_fight and not core and intruder_strength <= MINOR_SHARE * home_s
		_detached = _detachment(intruder_strength) if _minor_defence else {}
		var i := 0
		for u in _soldiers:
			if not _is_home_unit(u):
				continue
			i += 1
			if _defend_fight and (not _minor_defence or _detached.has(u.get_instance_id())):
				_order_attack_move(u, _intruder_pos, 4.0)
			elif u.attack_target == null and _flat(u.global_position, _rally) > RALLY_HOME:
				_order_move(u, _rally_spot(i))
	elif not _defending:
		_minor_defence = false
		_detached = {}
	_protect_workers()


## 20.A3: the home soldiers nearest to the intruder until their strength is DETACH_RATIO x `intruders` (DETACH_MIN at
## least): {instance id: true}.
func _detachment(intruders: float) -> Dictionary:
	var cands: Array[Unit] = []
	for u in _soldiers:
		if _is_home_unit(u):
			cands.append(u)
	cands.sort_custom(func(a: Unit, b: Unit) -> bool:
		return _flat(a.global_position, _intruder_pos) < _flat(b.global_position, _intruder_pos))
	var out := {}
	var s := 0.0
	for u in cands:
		if out.size() >= DETACH_MIN and s >= DETACH_RATIO * intruders:
			break
		out[u.get_instance_id()] = true
		s += AIMemory.strength_of(u)
	return out


## 20.A3: `pos` stands where rule 1 must not send the army: the crown isle while its wardens live (the forward hall's
## 28 m circle reaches it; the wardens killed whole defending armies there), or inside a living neutral camp or beast
## lair (AIMapFill.in_neutral_camp). Such an enemy is left to the neutrals unless it hits a building or a worker.
func _neutral_ground(pos: Vector3, wardens_alive: bool) -> bool:
	if wardens_alive and _flat(pos, CROWN_SPOT) < AIMapFill.ISLE_RADIUS:
		return true
	return mapfill_ai != null and mapfill_ai.in_neutral_camp(pos)


## Strength that defends the base: rally soldiers, finished towers, the wizard when at home, champions
## within 20 m of the rally (9.C9).
func _home_strength() -> float:
	var s := _champion_home
	for u in _soldiers:
		if _is_home_unit(u):
			s += AIMemory.strength_of(u)
	for b in _buildings:
		s += AIMemory.strength_of(b)
	if _wizard and _wizard.is_alive() and _flat(_wizard.global_position, _anchor) < 30.0:
		s += AIMemory.strength_of(_wizard)
	return s


## Workers near an enemy soldier or just hit flee to the drop-off, then go back after 6 calm s.
func _protect_workers() -> void:
	for w in _workers:
		var id := w.get_instance_id()
		if w == _scout or _group_ids.has(id):
			continue
		var danger := _nearest_enemy_fighter(w.global_position, WORKER_DANGER) != null
		var hit := _now - float(_worker_hit.get(id, -INF)) <= ai.decision_interval + 0.01
		if _fleeing.has(id):
			var calm := not danger and _now - float(_worker_hit.get(id, -INF)) >= WORKER_CALM
			if calm:
				_release_worker(id)
			continue
		if danger or hit:
			var back: Variant = w.gather_node if w.is_gathering() else null
			_fleeing[id] = [w, back]
			var drop := Building.nearest_drop_off(int(team), w.global_position)
			var to: Vector3 = drop.call(&"drop_off_point") if drop else _level.base_center(int(team))
			w.command_move(to)


func _release_worker(id: int) -> void:
	var entry: Array = _fleeing.get(id, [])
	_fleeing.erase(id)
	if entry.is_empty() or not is_instance_valid(entry[0]):
		return
	var w := entry[0] as Worker
	if not w.is_alive() or w.is_building():
		return
	var node: CrystalNode = entry[1] if is_instance_valid(entry[1]) else null
	if node == null or node.is_depleted():
		node = _best_node()
	if node:
		w.command_gather(node)


# ---------------------------------------------------------------- rule 2: retreat

func _rule_retreat() -> void:
	if stage == Stage.NONE:
		return
	if _group.is_empty():
		_end_attack("group lost")
		return
	var centre := _group_centre()
	if stage == Stage.RETREAT:
		if _flat(centre, _rally) <= RALLY_RADIUS or _now - _stage_since >= RETREAT_TIMEOUT:
			var from_sortie := _sortie_retreat
			_end_attack("back at the rally")
			if ai.regrow_hp > 0.0 and not from_sortie:
				_regrow_since = _now   # 8.A1: the next attack waits for the regrow (see _regrow_ready)
				_regrow_logged = false
		else:
			for u in _group:
				_order_move(u, _rally)
		return
	var hp := 0.0
	var strength := 0.0
	for u in _group:
		hp += (u as Unit).hp
		strength += AIMemory.strength_of(u)
	var enemy := memory.strength_near(centre, RETREAT_RADIUS, _now, FRESH)
	if all_in:
		return   # nothing to save the army for
	var hp_floor := CREEP_RETREAT_HP if stage == Stage.CREEP or stage == Stage.POINT else ai.retreat_hp   # 11b
	if hp < hp_floor * _launch_hp:
		if _group_out():
			retreat_hp_ratios.append(hp / maxf(_launch_hp, 1.0))
		_start_retreat("HP %.0f of %.0f" % [hp, _launch_hp])
	elif enemy > RETREAT_RATIO * strength:
		_start_retreat("enemy %.0f vs group %.0f" % [enemy, strength])


func _start_retreat(reason: String) -> void:
	if not _group_out():
		return
	_sortie_retreat = stage == Stage.CREEP or stage == Stage.POINT
	if stage == Stage.CREEP and mapfill_ai != null:
		mapfill_ai.note_creep_end(_sortie, false, null)
		_creep_retry_at = _now + CREEP_RETRY
	stage = Stage.RETREAT
	_stage_since = _now
	_log("RETREAT %d units: %s" % [_group.size(), reason])
	for u in _group:
		_order_move(u, _rally)


func _end_attack(reason: String) -> void:
	_log("ATTACK over: %s" % reason)
	_clear_group()


func _clear_group() -> void:
	stage = Stage.NONE
	_group.clear()
	_group_ids.clear()
	_hunt_target = null
	_hunt_point = Vector3.INF
	_sortie = {}
	_sortie_retreat = false
	_mid_goal = CROWN_SPOT


# ---------------------------------------------------------------- rule 3: economy

func _rule_economy() -> void:
	_expansion_workers()
	for w in _workers:
		if _busy(w) or w.is_gathering() or w.is_building():
			continue
		var node := _best_node()
		if node:
			w.command_gather(node)
	if _keep == null or _queued_this_tick or _worker_type == null:
		return
	var queued := 0
	for t in _keep.queue:
		if t.is_worker:
			queued += 1
	var target := ai.worker_target_home
	if _x1_done():
		target = ai.worker_target_expanded
	if _slot_done(&"X2"):
		target = maxi(target, ai.worker_target_x2)
	# 8.A1 opening (Nature): the first `opening_workers` workers may all be queued at once.
	var depth := ai.queue_depth
	if workers_queued < ai.opening_workers:
		depth = maxi(depth, ai.opening_workers)
	if recovering:
		depth = maxi(depth, RECOVERY_DEPTH)   # 20.A2 F1: workers first, two at a time, no build / hire reserve
	if _workers.size() + queued >= target or _keep.queue.size() >= depth:
		return
	if all_in and not _node_left():
		return   # 20.A2: nothing left to mine: a worker would only walk into the all-in attack
	if _keep.can_queue(_worker_type) != "" or not _pop_ok(_worker_type.pop) \
			or not _can_spend(_worker_type.cost, recovering):
		return
	var node := _best_node()
	if node:
		_keep.set_rally_node(node)
	if _keep.queue_unit(_worker_type) == "":
		_note_queued()
		_queued_this_tick = true
		workers_queued += 1
		_log("TRAIN %s (%d workers + %d queued%s)" % [_worker_type.display_name, _workers.size(), queued + 1,
				", recovery" if recovering else ""])


## X1 finished: the 3 newest workers gather the natural node. X1 gone: they go home.
func _expansion_workers() -> void:
	_rich_workers()
	var mid := _own_node("mid")
	if _x1_done():
		if _expansion_moved or mid == null:
			return
		_expansion_moved = true
		var moved := 0
		for i in range(_workers.size() - 1, -1, -1):
			var w := _workers[i]
			if _busy(w) or w.is_building():
				continue
			w.command_gather(mid)
			moved += 1
			if moved >= NODE_WORKERS:
				break
		_log("EXPANSION done: %d workers to the natural node" % moved)
	elif _expansion_moved:
		_expansion_moved = false
		for w in _workers:
			if w.gather_node == mid and mid != null:
				var home := _best_node()
				if home and home != mid:
					w.command_gather(home)


## Our own nodes are gone: the node nearest to `home` with no known enemy building within 25 m and
## no enemy fighter seen near it lately (workers would only die there). Null if none.
func _safe_far_node(home: Vector3) -> CrystalNode:
	# 20.A3: asked by the all-in, recovery and concede checks and once per idle worker (mined-out endgame: every
	# worker idles, 15 x a scan of every node against the memory each tick): computed once per tick.
	if _far_node_at == _now and _far_node_home == home and (_far_node == null or is_instance_valid(_far_node)):
		return _far_node
	_far_node_at = _now
	_far_node_home = home
	_far_node = _safe_far_node_now(home)
	return _far_node


func _safe_far_node_now(home: Vector3) -> CrystalNode:
	var best: CrystalNode = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("crystal_nodes"):
		var n := node as CrystalNode
		if n == null or n.is_depleted():
			continue
		var d := _flat(n.global_position, home)
		if d >= best_d or memory.nearest_building(n.global_position, FOCUS_SEARCH) != null \
				or memory.fighter_near(n.global_position, SIGHT_UNIT, _now, ai.memory_seconds):
			continue
		best_d = d
		best = n
	return best


## Own node "a", "b" or "mid" if it still has crystals, else null.
func _own_node(suffix: String) -> CrystalNode:
	var n: Variant = _node_refs.get(suffix)
	if n == null or not is_instance_valid(n) or (n as CrystalNode).is_depleted():
		return null
	return n as CrystalNode


func _home_nodes() -> Array[CrystalNode]:
	var out: Array[CrystalNode] = []
	for suffix in ["a", "b"]:
		var n := _own_node(suffix)
		if n:
			out.append(n)
	return out


func _x1_done() -> bool:
	return _slot_done(&"X1")


func _slot_done(id: StringName) -> bool:
	var b: Variant = _slot_building.get(id)
	return b != null and is_instance_valid(b) and (b as Building).is_alive() and (b as Building).is_constructed()


## balance-1.md 2f: X2 finished -> the 3 newest free workers gather the rich node (once).
func _rich_workers() -> void:
	var rich := _own_node("rich")
	if _x2_moved or rich == null or not _slot_done(&"X2"):
		return
	_x2_moved = true
	var moved := 0
	for i in range(_workers.size() - 1, -1, -1):
		var w := _workers[i]
		if _busy(w) or w.is_building() or w.gather_node == rich:
			continue
		w.command_gather(rich)
		moved += 1
		if moved >= NODE_WORKERS:
			break
	_log("EXPANSION 2 done: %d workers to the rich node" % moved)


## The own node with fewer than 3 workers nearest to the keep (the natural one only once X1 is
## finished), else the own node with the fewest; with no own node left, the nearest node anywhere.
func _best_node() -> CrystalNode:
	var nodes := _home_nodes()
	var mid := _own_node("mid")
	if mid and _x1_done():
		nodes.append(mid)
	var rich := _own_node("rich")
	if rich and _slot_done(&"X2"):
		nodes.append(rich)
	var home := _level.base_center(int(team))
	if nodes.is_empty():
		if mid:
			return mid
		if rich and _slot_done(&"X2"):
			return rich
		return _safe_far_node(home)
	var counts := {}
	for w in _workers:
		if w.gather_node != null and is_instance_valid(w.gather_node):
			counts[w.gather_node] = int(counts.get(w.gather_node, 0)) + 1
	var best: CrystalNode = null
	var best_d := INF
	for n in nodes:
		if int(counts.get(n, 0)) < NODE_WORKERS:
			var d := _flat(n.global_position, home)
			if d < best_d:
				best_d = d
				best = n
	if best:
		return best
	var fewest := 1 << 30
	for n in nodes:
		if int(counts.get(n, 0)) < fewest:
			fewest = int(counts.get(n, 0))
			best = n
	return best


# ---------------------------------------------------------------- rule 4: build

## The first build row whose trigger holds and whose building is missing (a barracks first when
## none is alive); nothing while a construction site stands (one site at a time).
func _compute_pending() -> void:
	_pending_row = _next_row()
	var type: BuildingType = _types.get(_pending_row.get("kind", &"")) if not _pending_row.is_empty() else null
	_pending_cost = _row_crystals(_pending_row, type) if type else 0
	_build_cost = _pending_cost
	# 9.C9: with no build waiting, a due champion hire keeps its price + 150 crystals from training, under the
	# same 20 s rule as a build (champions.md 10 "no build waiting": a waiting build always comes first).
	var hire_save := 0
	if champion_ai:
		champion_ai.set_profile(ai)
		hire_save = champion_ai.plan(_now)
	# 20.A2 F5: the hire reserve counts in _pending_cost for _can_spend (with a waiting build: on top of it; the
	# build still comes first, AIChampions waits for build cost + price).
	if hire_save > 0:
		_pending_cost += hire_save
	if _pending_row.is_empty() and hire_save <= 0:
		_starve_since = -1.0
	elif _starve_since < 0.0:
		_starve_since = _now


func _next_row() -> Dictionary:
	var have_barracks := false
	for b in _buildings:
		if b.building_type and b.building_type.kind == &"barracks":
			have_barracks = true
	if not have_barracks:   # a barracks has priority over everything, even a site in progress
		for row: Dictionary in _rows:
			if row["kind"] == &"barracks" and not _row_built(row) and _row_trigger(row):
				return row
	for b in _buildings:
		if not b.is_constructed():
			return {}
	for row: Dictionary in _rows:
		if not _row_built(row) and _row_trigger(row):
			return row
	return {}


func _row_built(row: Dictionary) -> bool:
	if _skipped_rows.has(row["id"]):
		return true
	var b: Variant = _slot_building.get(row["id"])
	if b != null and is_instance_valid(b) and (b as Building).is_alive():
		return true
	if not ai.rebuild and _slot_building.has(row["id"]):
		return true   # mission_01: a slot's building that fell stays gone
	var type: BuildingType = _types.get(row["kind"])
	if row.get("wall", false):
		return type == null   # walls: max_count counts every wall, the row only its own
	if type == null:
		return true
	if type.max_count <= 0:
		return false
	var count := 0
	for other in _buildings:
		if other.building_type == type:
			count += 1
	return count >= type.max_count


func _row_trigger(row: Dictionary) -> bool:
	# Pop 200: the house margin grows with the cap (4 up to cap 40, then cap / 10) so a big army keeps producing.
	var pop_tight := _eco.pop_cap < _pop_cap_max() and _eco.pop_used >= _eco.pop_cap - maxi(4, _eco.pop_cap / 10)
	match String(row["id"]):
		"H1":
			return true
		"V1":
			return pop_tight
		"V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9":
			var prev: Variant = _slot_building.get(StringName("V%d" % (String(row["id"]).substr(1).to_int() - 1)))
			return pop_tight and prev != null and is_instance_valid(prev) and (prev as Building).is_constructed()
		"S1":
			return not intrusions.is_empty() or _now >= ai.tower1_time
		"S2":
			if _now >= ai.tower2_time:
				return true
			for t in intrusions:
				if t - intrusions[0] >= TOWER2_GAP:
					return true
			return false
		"X1":
			if _own_node("mid") == null or _group_out():
				return false
			var low := _home_left() < ai.expand_home_below if ai.expand_home_below > 0 \
					else _home_left() < EXPAND_HOME_SHARE * _home_start
			return (low or _now >= ai.expand_time) and (not _camp_alive() or own_strength >= EXPAND_STRENGTH)
		"W1", "W2":
			return _slot_done(&"S1")
		"X2":
			if not ai.second_expansion or _own_node("rich") == null or _group_out() or not _x1_done():
				return false
			return (_home_left() < X2_HOME_SHARE * _home_start or _now >= X2_TIME) \
					and _eco.crystals >= X2_MIN_CRYSTALS
		"M1":
			return trade_ai != null and trade_ai.bazaar_due(_now, _hall_done())
		"S3":
			return trade_ai != null and trade_ai.raid_tower_due(_own_node("mid"), _buildings)
		"S4":
			return trade_ai != null and trade_ai.raid_tower_due(_own_node("rich"), _buildings)
	return false


## 10.A3: crystals a row's placement waits for: the Bazaar cost + 100 (a rebuild 250), a raid Spire cost + 50,
## else the cost.
func _row_crystals(row: Dictionary, type: BuildingType) -> int:
	match row.get("id", &""):
		&"M1":
			return trade_ai.bazaar_crystals(type.cost) if trade_ai else type.cost
		&"S3", &"S4":
			return AITrade.tower_crystals(type.cost)
	return type.cost


## An own Hall (kind barracks) is completed.
func _hall_done() -> bool:
	for b in _buildings:
		if b.building_type and b.building_type.kind == &"barracks" and b.is_constructed():
			return true
	return false


## Where a row's building goes: the level's M1 / S3 / S4 slot when it has one, the natural hall spot for "pos"
## INF, else the Shadow-side "pos" mirrored for this side.
func _row_base(row: Dictionary) -> Vector3:
	var pos: Vector3 = row["pos"]
	if pos == Vector3.INF:
		return _level.natural_hall_spot(int(team))
	var slot: StringName = row.get("slot", &"")
	if slot == &"M1" and _level.has_method(&"market_slot"):
		return _level.call(&"market_slot", int(team))
	if (slot == &"S3" or slot == &"S4") and _level.has_method(&"tower_slot"):
		var p: Vector3 = _level.call(&"tower_slot", int(team), slot)
		if p != Vector3.INF:
			return p
	# Review H4: X2 (the second barracks) is Crown Hollow's rich hall; a LayoutLevel has its own rich_hall slot
	# (identity on Crown Hollow layouts; the plain skirmish keeps the constant).
	if row.get("id", &"") == &"X2" and _level.has_method(&"bot_point"):
		var rh: Vector3 = _level.rich_hall_spot(int(team))
		if rh != Vector3.INF:
			return rh
	return _side(pos)


func _home_left() -> int:
	var n_left := 0
	for n in _home_nodes():
		n_left += n.crystals_left
	return n_left


func _rule_build() -> void:
	_maintain_sites()
	if _pending_row.is_empty():
		return
	var row := _pending_row
	var id: StringName = row["id"]
	if not _trigger_time.has(id):
		_trigger_time[id] = _now
		_log("BUILD %s triggered" % id)
	var delay := 0.0 if _placed == 0 else ai.build_delay
	var type: BuildingType = _types.get(row["kind"])
	if type == null or _now - float(_trigger_time[id]) < delay or _eco.crystals < _row_crystals(row, type):
		return
	if _now < float(_slot_retry_at.get(id, 0.0)):
		return
	var spot := _row_spot(row, type)
	if spot == Vector3.INF:
		_slot_retry_at[id] = maxf(float(_slot_retry_at.get(id, 0.0)), _now + SLOT_RETRY)   # 20.A3: keeps a 30 s search wait
		return
	var builders := _pick_builders(spot, int(row["builders"]))
	if builders.is_empty():
		return
	var p0 := Time.get_ticks_usec()
	var site := _level.build_grid.place(type, spot, int(team), builders)
	_place_usec += Time.get_ticks_usec() - p0
	if site == null:
		_slot_tries[id] = int(_slot_tries.get(id, 0)) + 1
		_slot_retry_at[id] = _now + SLOT_RETRY
		_log("BUILD %s refused at %s: %s" % [id, _xz(spot), _level.build_grid.last_reason])
		if row.get("wall", false):
			_skipped_rows[id] = true
		return
	_slot_building[id] = site
	_trigger_time.erase(id)
	_slot_tries.erase(id)
	_starve_since = -1.0
	_placed += 1
	if row["kind"] == &"market" and trade_ai:
		trade_ai.note_bazaar_placed(_now)
	_log("PLACE %s %s at %s, %d builder(s), crystals left %d" % [id, type.display_name, _xz(site.global_position),
			builders.size(), _eco.crystals])


## The slot if it is free; after 3 refusals (at once for a permanent reason) the shifted slots, then
## the nearest valid spot. INF = try again in 5 s.
func _row_spot(row: Dictionary, type: BuildingType) -> Vector3:
	var id: StringName = row["id"]
	if row.get("wall", false):
		return _wall_spot(row, type)
	var base := _row_base(row)
	var reason := _level.build_grid.check(type, base, int(team))
	if reason == "":
		return base
	var tries := int(_slot_tries.get(id, 0)) + 1
	if reason != BuildGrid.MSG_BLOCKED:
		tries = maxi(tries, SLOT_TRIES)
	_log("BUILD %s slot %s refused (%s), try %d" % [id, _xz(base), reason, tries])
	_slot_tries[id] = tries
	if tries < SLOT_TRIES:
		return Vector3.INF
	if _spot_free_reason(reason, type):
		_slot_retry_at[id] = _now + SLOT_SEARCH_RETRY
		return Vector3.INF   # 20.A3: a limit / missing prerequisite refuses every spot: no ring search
	for shift in SLOT_SHIFTS:
		var p := base + _side_vec(shift)
		if _level.build_grid.check(type, p, int(team)) == "":
			return p
	# 20.A3: find_spot() checks up to 289 spots (each one loops over every unit and crystal node): 0.1-2 s on a busy
	# machine. A miss is searched again only after SLOT_SEARCH_RETRY, not every 5 s.
	var p0 := Time.get_ticks_usec()
	var found := _level.build_grid.find_spot(type, base, int(team), 8)
	_sub("build.find_spot", p0)
	if found != Vector3.INF and _level.build_grid.check(type, found, int(team)) == "":
		return found
	_slot_retry_at[id] = _now + SLOT_SEARCH_RETRY
	return Vector3.INF


## 20.A3: a BuildGrid.check refusal that does not depend on the spot (every other spot answers the same).
func _spot_free_reason(reason: String, type: BuildingType) -> bool:
	return reason == BuildGrid.MSG_UNKNOWN or reason == BuildGrid.limit_message(type) \
			or reason == BuildGrid.prerequisite_reason(type, int(team))


## kingdom-ice.md 7 "Walls": beside the finished S1 tower, only if BuildGrid.check is ok and the keep ->
## rally navmesh path is shorter than ai.wall_path_ratio x the straight line; else the row is skipped for good.
func _wall_spot(row: Dictionary, type: BuildingType) -> Vector3:
	var id: StringName = row["id"]
	var s1: Variant = _slot_building.get(&"S1")
	if s1 == null or not is_instance_valid(s1):
		return Vector3.INF
	var spot := _level.build_grid.snap((s1 as Building).global_position + _side_vec(row["pos"]), type.footprint)
	var reason := _level.build_grid.check(type, spot, int(team))
	var ratio := _rally_path_ratio()
	if reason != "" or ratio >= ai.wall_path_ratio:
		_skipped_rows[id] = true
		_log("WALL %s skipped at %s (%s, path x%.2f)" % [id, _xz(spot), reason if reason != "" else "path", ratio])
		return Vector3.INF
	return spot


## Navmesh path length keep -> rally over the straight line (INF: no keep or no path).
func _rally_path_ratio() -> float:
	if _keep == null or not is_instance_valid(_keep):
		return INF
	var from := _keep.drop_off_point()
	var straight := _flat(from, _rally)
	if straight < 1.0:
		return 1.0
	var map := _level.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, from, _rally, true)
	if path.size() < 2:
		return INF
	var length := 0.0
	for i in range(1, path.size()):
		length += _flat(path[i - 1], path[i])
	return length / straight


## The `count` workers nearest to `spot` (not fleeing, not scouting, not already building).
func _pick_builders(spot: Vector3, count: int) -> Array:
	var free: Array = []
	for w in _workers:
		if _busy(w) or w.is_building():
			continue
		free.append(w)
	free.sort_custom(func(a: Worker, b: Worker) -> bool:
		return _flat(a.global_position, spot) < _flat(b.global_position, spot))
	return free.slice(0, count)


## A site nobody builds (its builder died or fled) gets the nearest free worker.
func _maintain_sites() -> void:
	for b in _buildings:
		if b.is_constructed() or b.builder_count() > 0:
			continue
		var coming := false
		for w in _workers:
			if w.build_site == b:
				coming = true
				break
		if coming:
			continue
		var pick := _pick_builders(b.global_position, 1)
		if not pick.is_empty():
			(pick[0] as Worker).command_build(b)


# ---------------------------------------------------------------- rule 5: train

func _rule_train() -> void:
	for b in _barracks:
		if _flat(b.rally_point(), _rally) > 1.0:
			b.set_rally_point(_rally)
	_keep_rally()
	if _queued_this_tick or _barracks.is_empty():
		return
	if casters_ai != null:
		casters_ai.new_pass()   # 20.A3 perf: its unit / keep counts are taken once for the calls below
	# caster-units.md 8.1: the Stronghold's first caster comes before the Citadel (normal / hard): when the crystals
	# allow it, a due first caster is queued ahead of the Citadel upgrade (a starved Fire bot spent its 300 on the
	# Citadel, then on hires and the Stables, and never fielded its caster, 2026-10-02).
	if casters_ai != null and _keep != null and is_instance_valid(_keep) and _keep.tier == 2 \
			and not _keep.is_upgrading() and casters_ai.first_caster_due() and casters_ai.try_train(true):
		_queued_this_tick = true
		return
	# tiers.md 4: Stronghold / Citadel on the difficulty's timeline (true = started, or saving crystals for it).
	if TierSystem.bot_try_upgrade(team, _keep, _eco, int(difficulty)):
		if _keep.is_upgrading():
			_log("KEEP UPGRADE to %s (crystals left %d)" % [TierSystem.tier_name(_keep.tier + 1), _eco.crystals])
		return
	# t3-helpers.md 9: at the Citadel the helper call comes first (true = called now, or saving crystals for it).
	var helper_step := T3Kit.bot_try_helper(team, _keep, _eco, int(difficulty)) if T3Kit.ENABLED else &""
	if helper_step == &"called":
		_log("HELPER CALL (crystals left %d)" % _eco.crystals)
	if helper_step != &"":
		return
	# 9.C9 (champions.md 10): a due champion hire that waits only for crystals comes before the optional spenders
	# ("+" / bowman upgrades, Stables riders and rank-3, casters); training below still keeps its reserve through
	# _can_spend (20 s rule). The tier timeline, the helper call and the Stables' own construction stay first, like a
	# waiting build.
	var hire_first := champion_ai != null and champion_ai.hire_waits_for_crystals(_level)
	# caster-units.md 8.1: the hard bot queues its caster(s) at the keep before any other Hall unit (normal: its first
	# one, saving the crystals for it meanwhile); a due champion hire goes first.
	if casters_ai != null and not hire_first and casters_ai.try_train(true):
		_queued_this_tick = true
		return
	if casters_ai != null and not hire_first and casters_ai.saving_for_caster():
		return
	if not hire_first and UnitUpgrades.bot_try_buy(team, _barracks, _eco, _now):   # tiers.md 5: "+" upgrades
		_log("PLUS UPGRADE (crystals left %d)" % _eco.crystals)
		return
	if not hire_first and BowmanKit.BOWMEN_ENABLED and BowmanUpgrades.bot_try_buy(team, _barracks, _eco, _now):   # bowmen.md 6
		_log("BOWMAN UPGRADE (crystals left %d)" % _eco.crystals)
		return
	# docs/design/stables.md 6: build the Stables, keep 2 riders queued there, rank-3 at the Citadel (switch Stables16).
	if Stables16.ENABLED and Stables16.bot_step(int(team), _faction, _eco, _now, _level.build_grid,
			_workers, _keep, _rally, int(difficulty), hire_first):
		_log("STABLES step (crystals left %d)" % _eco.crystals)
		return
	var best: TrainingBuilding = null
	for b in _barracks:
		if best == null or b.queue.size() < best.queue.size():
			best = b
	if best.queue.size() >= ai.queue_depth:
		return
	if ai.max_soldiers > 0:
		var count := _soldiers.size()
		for tb in _barracks:
			count += tb.queue.size()
		if count >= ai.max_soldiers:
			return
	var type := _pick_soldier(best)
	if type == null or best.can_queue(type) != "" or not _pop_ok(type.pop) or not _can_spend(type.cost):
		return
	if best.queue_unit(type) == "":
		_note_queued()
		_queued_this_tick = true
		_log("TRAIN %s (soldier pop %d, crystals left %d)" % [type.display_name, _soldier_pop(), _eco.crystals])


## The slot furthest below its target share of soldier pop (the heavy slot only when rich).
func _pick_soldier(b: TrainingBuilding) -> UnitType:
	var types := b.trainable_types()
	if types.is_empty():
		return null
	var mix: PackedFloat32Array = ai.mix_default
	var seen := memory.soldier_mix()
	var total_seen := int(seen["total"])
	if total_seen > 0:
		if float(seen["ranged"]) >= RANGED_SHARE * total_seen:
			mix = ai.mix_vs_ranged
		elif float(seen["melee"]) >= MELEE_SHARE * total_seen:
			mix = ai.mix_vs_melee
	var pops: Array[int] = []
	pops.resize(types.size())
	var total := 0
	for u in _soldiers:
		var i := _slot_of(types, u.unit_type)
		if i >= 0:
			pops[i] += u.unit_type.pop
			total += u.unit_type.pop
	for tb in _barracks:
		for t in tb.queue:
			var i := _slot_of(types, t)
			if i >= 0:
				pops[i] += t.pop
				total += t.pop
	var best := -1
	var best_gap := -INF
	for i in types.size():
		if i == HEAVY_SLOT and (_eco.crystals < maxi(ai.heavy_crystals, types[i].cost) or total < ai.heavy_soldier_pop):
			continue
		# new-units-12.md 5 / tiers-wave.md: a tier-gated unit ("Requires Stronghold", ...) is skipped, never picked
		# then refused (that would stall rule 5 until the tier is reached).
		if b.can_queue(types[i]).begins_with("Requires"):
			continue
		# Slots past the profile mix: the Hall bowman's small share (bowmen.md 6), the new units' (new-units-12.md 5).
		var target: float = mix[i] if i < mix.size() else BowmanKit.bot_share(types[i].id) + NewUnits12.bot_share(types[i].id)
		target += AICasters.mix_bonus(int(team), types[i])   # caster-units.md 8.2: 2+ enemy casters seen -> fast units
		var gap := target - float(pops[i]) / float(maxi(total, 1))
		if gap > best_gap:
			best_gap = gap
			best = i
	return types[best] if best >= 0 else null


static func _slot_of(types: Array[UnitType], t: UnitType) -> int:
	if t == null:
		return -1
	for i in types.size():
		if types[i].id == t.id:
			return i
	return -1


func _soldier_pop() -> int:
	var n := 0
	for u in _soldiers:
		n += u.unit_type.pop if u.unit_type else 1
	return n


## Idle home soldiers far from the rally walk back to their spot there (not while defending).
func _keep_rally() -> void:
	if _defending:
		return
	var i := 0
	for u in _soldiers:
		if not _is_home_unit(u):
			continue
		i += 1
		if u.attack_target != null or _flat(u.global_position, _rally) <= RALLY_HOME:
			continue
		if Vector2(u.velocity.x, u.velocity.z).length() > 0.3:
			continue
		_order_move(u, _rally_spot(i))


## Spot `i` of a small spiral around the rally point (so units don't all stand on one spot).
func _rally_spot(i: int) -> Vector3:
	return _rally + Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * (1.2 * sqrt(float(i)))


## 9.C9: a unit of `pop` still leaves the pop a due champion hire needs (2).
func _pop_ok(pop: int) -> bool:
	var keep_free := champion_ai.pop_reserve() if champion_ai else 0
	return keep_free <= 0 or _eco.pop_used + pop <= _eco.pop_cap - keep_free


## Crystals may go to a unit when what is left still pays the waiting build (and a due champion hire); the 20 s
## rule lets one unit through after a build / hire has waited 20 s for crystals. 20.A2 F5: the pass is spent only
## when the unit is really queued (_note_queued() after queue_unit returned ""), so a refused queue keeps it and
## a second answer in the same 20 s is always no. `ignore_reserve` (recovery workers): only the price counts.
func _can_spend(cost: int, ignore_reserve: bool = false) -> bool:
	_starve_pass = false
	if _eco.crystals < cost:
		return false
	if ignore_reserve or _pending_cost <= 0 or _eco.crystals - cost >= _pending_cost:
		return true
	if _starve_since >= 0.0 and _now - _starve_since >= STARVE_TIME:
		_starve_pass = true
		return true
	return false


## 20.A2 F5: a unit was queued after _can_spend() said yes: a 20 s pass is used up now.
func _note_queued() -> void:
	if not _starve_pass:
		return
	_starve_pass = false
	_starve_since = _now
	starve_passes.append(_now)
	_log("STARVE pass: one unit through the %d-crystal reserve (%d crystals left)" % [_pending_cost, _eco.crystals])


# ---------------------------------------------------------------- rule 6: scout

func _rule_scout() -> void:
	if _scout == null:
		scout_goal = Vector3.INF
	if _scout != null and _fog != null:
		_drive_fog_scout(_scout as Unit)
		return
	var path := _scout_path()
	if _scout != null:
		var s := _scout as Unit
		if s.hp < SCOUT_HOME_HP * s.max_hp and _scout_wp < path.size():
			_scout_wp = path.size()
			_log("SCOUT hurt, coming home")
		var goal := _rally if _scout_wp >= path.size() else _side(path[_scout_wp])
		if _flat(s.global_position, goal) <= WAYPOINT_REACH:
			if _scout_wp >= path.size():
				_scout_done(s)
				return
			_scout_wp += 1
			goal = _rally if _scout_wp >= path.size() else _side(path[_scout_wp])
		scout_goal = goal
		_order_move(s, goal, 1.0)
		return
	if _now < _next_scout or _defending or all_in:
		return
	var pick: Unit = null
	for u in _soldiers:
		if not _is_home_unit(u) or u.attack_target != null:
			continue
		if pick == null or _scout_score(u) < _scout_score(pick):
			pick = u
	if pick == null and _now < ai.scout_worker_before:
		for w in _workers:
			if not w.is_building() and not _busy(w):
				pick = w
	if pick == null:
		return
	var first := _side(path[0])
	if _fog != null:
		first = _next_scout_point(pick.global_position)
		if first == Vector3.INF:
			_next_scout = _now + ai.scout_interval
			return   # the whole map is explored: nothing to scout
	_next_scout = _now + ai.scout_interval
	_scout = pick
	_scout_wp = 0
	_scout_leg_since = _now
	scout_goal = first
	scout_goals.append(first)
	_scout_via = _scout_via_for(pick.global_position, first) if _fog != null else Vector3.INF
	_log("SCOUT %s to %s%s" % [pick.unit_name, _xz(first),
			(" via %s" % _xz(_scout_via)) if _scout_via != Vector3.INF else ""])
	_order_move(pick, _scout_via if _scout_via != Vector3.INF else first, 1.0)


## 13a: the fixed loop (the river loop over Millstone Bridge when the map has a river), Shadow side.
func _scout_path() -> Array[Vector3]:
	if mapfill_ai != null and mapfill_ai.has_river():
		return AIMapFill.SCOUT_PATH_RIVER
	return SCOUT_PATH


## 13a: a road bridge (or cleared ford) to cross first when `goal` is on the other bank; INF otherwise.
func _scout_via_for(from: Vector3, goal: Vector3) -> Vector3:
	if mapfill_ai == null:
		return Vector3.INF
	return mapfill_ai.scout_via(from, goal)


## 6.A1 with fog: a leg ends when its point is in sight (or reached, or after SCOUT_LEG_TIME); then the
## next unexplored point, SCOUT_LEGS legs at most, then home (at once when hurt).
func _drive_fog_scout(s: Unit) -> void:
	var going_home := _scout_wp >= SCOUT_LEGS
	if not going_home and s.hp < SCOUT_HOME_HP * s.max_hp:
		_scout_wp = SCOUT_LEGS
		going_home = true
		_log("SCOUT hurt, coming home")
	if going_home:
		if scout_goal != _rally:
			_scout_via = _scout_via_for(s.global_position, _rally)
		scout_goal = _rally
		if _flat(s.global_position, _rally) <= WAYPOINT_REACH:
			_scout_done(s)
			return
		_scout_move(s, _rally)
		return
	# Points of the fixed loop (drawn around the warden camp) are walked to; grid points only until seen.
	var on_loop := false
	for p0 in _scout_path():
		if _flat(_side(p0), scout_goal) < 0.5:
			on_loop = true
	var leg_over := scout_goal == Vector3.INF or _flat(s.global_position, scout_goal) <= WAYPOINT_REACH \
			or (not on_loop and _fog.is_visible(int(team), scout_goal)) or _now - _scout_leg_since >= SCOUT_LEG_TIME
	if leg_over:
		_scout_wp += 1
		var next := _next_scout_point(s.global_position) if _scout_wp < SCOUT_LEGS else Vector3.INF
		_scout_leg_since = _now
		if next == Vector3.INF:
			_scout_wp = SCOUT_LEGS
			_scout_via = _scout_via_for(s.global_position, _rally)
			scout_goal = _rally
			_scout_move(s, _rally)
			return
		scout_goal = next
		scout_goals.append(next)
		_scout_via = _scout_via_for(s.global_position, next)
		_log("SCOUT next %s%s" % [_xz(next), (" via %s" % _xz(_scout_via)) if _scout_via != Vector3.INF else ""])
	_scout_move(s, scout_goal)


## 13a: walk to `goal`, through _scout_via first while there is one (the leg clock restarts once it is reached).
func _scout_move(s: Unit, goal: Vector3) -> void:
	if _scout_via != Vector3.INF:
		if _flat(s.global_position, _scout_via) <= WAYPOINT_REACH + 1.0:
			_scout_via = Vector3.INF
			_scout_leg_since = _now
		else:
			_order_move(s, _scout_via, 1.0)
			return
	_order_move(s, goal, 1.0)


## The first point of the fixed loop still unexplored for this team, else the unexplored grid point
## nearest to `from`. INF when everything is explored.
func _next_scout_point(from: Vector3) -> Vector3:
	for p0 in _scout_path():
		var p := _side(p0)
		if not _fog.is_explored(int(team), p):
			return p
	var best := Vector3.INF
	var best_d := INF
	var camp := _camp_alive()
	var filter := mapfill_ai != null and mapfill_ai.active()
	for p in _scout_grid:
		if _fog.is_explored(int(team), p) or (camp and _flat(p, CROWN_SPOT) < SCOUT_CAMP_AVOID):
			continue
		if filter and not mapfill_ai.scout_point_ok(p, camp):
			continue   # 13a: water, the guarded isle, camps and beast lairs
		var d := _flat(p, from)
		if d < best_d:
			best_d = d
			best = p
	return best


func _scout_done(s: Unit) -> void:
	_log("SCOUT home")
	_scout = null
	scout_goal = Vector3.INF
	_scout_via = Vector3.INF
	if s is Worker:
		var n := _best_node()
		if n:
			(s as Worker).command_gather(n)


## Lower = better scout: the fastest soldier type (Grave Hound, Blaze Rider, Thornling), then the cheapest.
func _scout_score(u: Unit) -> float:
	var cost := float(u.unit_type.cost) if u.unit_type else 999.0
	if not ai.scout_fast or u.unit_type == null:
		return cost   # Ice: no fast unit, the cheapest soldier scouts
	return cost - 1000.0 * u.unit_type.move_speed


# ---------------------------------------------------------------- rule 7: attack

func _rule_attack() -> void:
	if stage != Stage.NONE:
		if stage != Stage.RETREAT:
			_drive_attack()
		_block("group out" if stage != Stage.RETREAT else "retreat")
		return
	if not ai.launch_attacks:
		return
	if _defending and not _minor_defence:
		_block("defending")
		return
	var home: Array[Unit] = []
	var near := 0
	for u in _soldiers:
		if _is_home_unit(u) and not _detached.has(u.get_instance_id()):   # 20.A3: a minor defence's detachment stays
			home.append(u)
			if _flat(u.global_position, _rally) <= RALLY_RADIUS:
				near += 1
	var broke := all_in
	if broke:
		# Endgame: nothing left to mine or buy. Everyone goes, workers too (they hit buildings).
		for w in _workers:
			if not _busy(w) and not w.is_building():
				home.append(w)
	if home.is_empty():
		_block("no army")
		return
	var capped := _eco.pop_cap > 0 and _eco.pop_used >= _eco.pop_cap - 2 and not _can_grow()
	# The reserve (the healthiest soldiers) stays home; the rest must make min_attack_pop.
	home.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp > b.hp)
	var reserve := RESERVE
	if (ai.no_reserve_at_cap and capped) or broke:
		reserve = 0
	if home.size() <= reserve:
		_block("no army")
		return
	var pop := 0
	for i in range(reserve, home.size()):
		pop += home[i].unit_type.pop if home[i].unit_type else 1
	# 20.A3: the strength check compares like with like and grows impatient (see _attack_ratio_now / _attack_power).
	var gathered := pop >= ai.min_attack_pop and float(near) >= RALLY_SHARE * home.size()
	if gathered and _gathered_since < 0.0:
		_gathered_since = _now
	elif not gathered:
		_gathered_since = -1.0
	var ratio := _attack_ratio_now()
	var need := ratio * maxf(seen_strength, SEEN_FLOOR)
	var power := _attack_power()
	var full := ai.attack_full_pop > 0 and pop >= ai.attack_full_pop
	var ready := gathered and (power >= need or full)
	if not ready and not (capped and home.size() - reserve >= 2) and not broke:
		if pop < ai.min_attack_pop:
			_block("pop")
		elif float(near) < RALLY_SHARE * home.size():
			_block("rally")
		else:
			_block("strength")
		return
	# 20.A2: all-in while trade gold still buys soldiers: gather min_attack_pop at the rally (or the cap) instead of
	# sending each new unit alone into the enemy towers.
	if broke and not ready and not capped and pop < ai.min_attack_pop and _trade_funds_comeback():
		_block("all-in gather")
		return
	var avg_hp := 0.0
	for i in range(reserve, home.size()):
		avg_hp += home[i].hp / maxf(home[i].max_hp, 1.0)
	avg_hp /= float(home.size() - reserve)
	if not broke and not _regrow_ready(avg_hp):
		_block("regrow")
		return
	var waited := _now - _regrow_since if _regrow_since >= 0.0 else -1.0
	_regrow_since = -1.0
	_group = []
	for i in range(reserve, home.size()):
		_group.append(home[i])
	_group_ids.clear()
	_launch_hp = 0.0
	for u in _group:
		_group_ids[(u as Unit).get_instance_id()] = true
		_launch_hp += (u as Unit).hp
	launch_hp_ratios.append(avg_hp)
	if waited >= 0.0:
		launch_after_regrow.append(waited)
		_log("REGROWN: average HP %.0f %% after %.0f s at the rally" % [avg_hp * 100.0, waited])
	attacks_launched += 1
	_launched_tick = true
	if first_attack_time < 0.0:
		first_attack_time = _now
	_hero_joins = _malrik_joins(broke)
	_explore = _explore_points()
	var why := "ready" if ready else ("pop cap" if capped else "all-in")
	if ready and power < ai.attack_ratio * maxf(seen_strength, SEEN_FLOOR):
		why = "full rally" if power < need else "ratio x%.2f after %.0f s" % [ratio, _now - _gathered_since]
	_gathered_since = -1.0
	# 12c: an awake enemy-bank Wayshrine is the first target row (attack-move there, capture, continue).
	var shrine: Node3D = null
	if mapfill_ai != null and mapfill_ai.active() and not broke:
		shrine = mapfill_ai.attack_shrine(own_strength, seen_strength)
	if shrine != null:
		_sortie = {"kind": &"shrine", "node": shrine, "pos": shrine.global_position, "name": _name_of(shrine)}
		_set_stage(Stage.SHRINE)
	else:
		_pick_attack_row()
	_log("ATTACK #%d %d units (%d pop) str %.0f (power %.0f) vs seen %.0f (%s)%s -> %s" % [attacks_launched,
			_group.size(), pop, own_strength, power, seen_strength, why, " + wizard" if _hero_joins else "",
			Stage.keys()[stage]])
	_drive_attack()


## 20.A3 diagnostics: one think tick where rule 7 did not launch, and why.
func _block(reason: String) -> void:
	attack_blocks[reason] = int(attack_blocks.get(reason, 0)) + 1


## 20.A3: rule 7's ratio now. seen_strength keeps every tower ever seen and the enemy wizard and champions for
## memory_seconds, so a normal bot's army alone could never reach attack_ratio x seen after ~6:00 (the Fire bot made
## 0 attacks in 30 min, both bots turtled until mined out). Once the army is gathered at the rally (pop and 80 %
## there), the ratio falls linearly from ai.attack_ratio to ai.attack_ratio_floor over ai.attack_patience seconds;
## with no attack launched yet by ai.first_attack_by, the floor applies at once.
func _attack_ratio_now() -> float:
	var floor_ratio := minf(ai.attack_ratio_floor, ai.attack_ratio)
	if attacks_launched == 0 and ai.first_attack_by > 0.0 and _now >= ai.first_attack_by:
		return floor_ratio
	if _gathered_since < 0.0 or ai.attack_patience <= 0.0:
		return ai.attack_ratio
	var k := clampf((_now - _gathered_since) / ai.attack_patience, 0.0, 1.0)
	return lerpf(ai.attack_ratio, floor_ratio, k)


## 20.A3: what the attack brings, like seen_strength counts the enemy's wizard: own_strength plus the own wizard when
## he joins this attack (ai.malrik_joins) and is healthy (HP >= 70 %, not healing).
func _attack_power() -> float:
	var w := _wizard
	if w == null or not is_instance_valid(w) or not w.is_alive() or ai.hero_stays_home or is_scripted(w):
		return own_strength
	if _hero_state == HeroState.HEAL or w.hp < HERO_OK * w.max_hp or _now < _hero_wait_until:
		return own_strength
	return own_strength + AIMemory.strength_of(w) if _malrik_joins(false, 1) else own_strength


## Rule 7's wizard join rule (ai.malrik_joins; `broke` = all-in: always). `ahead` = attacks about to be launched
## (20.A3: asked before the launch).
func _malrik_joins(broke: bool = false, ahead: int = 0) -> bool:
	match ai.malrik_joins if not broke else AIProfile.MalrikJoins.EVERY_ATTACK:
		AIProfile.MalrikJoins.EVERY_ATTACK:
			return true
		AIProfile.MalrikJoins.SECOND_ATTACK_OR_STRENGTH:
			return attacks_launched + ahead >= 2 or own_strength >= ai.malrik_join_strength \
					or (_wizard != null and _wizard.level >= ai.malrik_join_level)
	return false


## Rule 7's target rows after the shrine: the crown camp, a seen building near the crown, else the middle.
func _pick_attack_row() -> void:
	if _camp_alive() and own_strength >= ai.camp_strength and _now >= ai.camp_time and _level.crown \
			and not _level.crown.is_worn():
		_set_stage(Stage.CAMP)
	else:
		var b := memory.nearest_building(CROWN_SPOT, NEAR_CROWN)
		if b:
			_hunt(b)
		else:
			_enter_mid()


## Stage.MID toward the crown, or (13b, hard) through the crossing AIMapFill.attack_waypoint() picks when the enemy's
## Crown Bridge is held.
func _enter_mid() -> void:
	_mid_goal = CROWN_SPOT
	if mapfill_ai != null and mapfill_ai.active():
		var wp := mapfill_ai.attack_waypoint(memory, _now)
		if wp != Vector3.INF:
			_mid_goal = wp
			_log("ATTACK reroute: the enemy Crown Bridge is held, going through %s" % _xz(wp))
	_set_stage(Stage.MID)


## 8.A1 regrow rule (kingdom-nature.md 6): after a retreat, the next attack also needs the group's average HP
## >= ai.regrow_hp, or ai.regrow_wait seconds since the group got back to the rally. True = may launch.
func _regrow_ready(avg_hp: float) -> bool:
	if _regrow_since < 0.0 or ai.regrow_hp <= 0.0:
		return true
	if avg_hp >= ai.regrow_hp or _now - _regrow_since >= ai.regrow_wait:
		return true
	if not _regrow_logged:
		_regrow_logged = true
		_log("REGROW: ready to attack, waits (average HP %.0f %% < %.0f %%)" % [avg_hp * 100.0, ai.regrow_hp * 100.0])
	return false


func _drive_attack() -> void:
	var centre := _group_centre()
	match stage:
		Stage.CAMP:
			if not _camp_alive():
				_log("CAMP cleared")
				var b := memory.nearest_building(CROWN_SPOT, NEAR_CROWN)
				if b:
					_hunt(b)
				else:
					_enter_mid()
				return
			_group_attack_move(CROWN_SPOT)
		Stage.MID:
			_group_attack_move(_mid_goal)
			var there := 0
			for u in _group:
				if _flat((u as Unit).global_position, _mid_goal) <= MID_RADIUS:
					there += 1
			if there >= mini(MID_GATHER, _group.size()) or _now - _stage_since >= MID_TIMEOUT:
				_set_stage(Stage.KEEP)
				_log("ATTACK to the enemy keep %s" % _xz(_level.base_center(_enemy_team)))
		Stage.KEEP:
			var base := _level.base_center(_enemy_team)
			_group_attack_move(base)
			_focus_barracks(centre)
			if _flat(centre, base) <= BASE_REACHED and memory.nearest_building(base, BASE_CLEAR_RADIUS) == null:
				_next_hunt(centre)
		Stage.HUNT:
			if _hunt_target != null and (not is_instance_valid(_hunt_target) or not (_hunt_target as Building).is_alive()):
				_hunt_target = null
				_next_hunt(centre)
				return
			if _hunt_target != null:
				_group_attack_move((_hunt_target as Building).global_position)
			elif _hunt_point != Vector3.INF:
				_group_attack_move(_hunt_point)
				if _flat(centre, _hunt_point) <= POINT_REACHED:
					_next_hunt(centre)
					return
			_focus_barracks(centre)
		Stage.SHRINE:
			# 12c: stand in the awake enemy-bank shrine until someone captures it, then the next row.
			if not mapfill_ai.shrine_awake(_sortie.get("node")) or _now - _stage_since >= SHRINE_TIMEOUT:
				_log("SHRINE row over (%s)" % ("taken" if not mapfill_ai.shrine_awake(_sortie.get("node")) else "timeout"))
				_sortie = {}
				_pick_attack_row()
				return
			_group_attack_move(_sortie["pos"])
		Stage.CREEP:
			# 11a / 11e: until the camp or beast is dead (11b: then home, the wizard picks up drops first).
			if not mapfill_ai.target_alive(_sortie):
				_sortie_over(true, "cleared")
				return
			if _now - _stage_since >= CREEP_TIMEOUT:
				_sortie_over(false, "timeout")
				return
			_group_attack_move(mapfill_ai.target_pos(_sortie))
		Stage.POINT:
			# 12b: chase the capturers off an own point, then home.
			var pos: Vector3 = _sortie["pos"]
			_group_attack_move(pos)
			if (_flat(centre, pos) <= POINT_ARRIVED and mapfill_ai.point_safe(_sortie)) \
					or _now - _stage_since >= POINT_TIMEOUT:
				_sortie_over(false, "point safe" if _now - _stage_since < POINT_TIMEOUT else "timeout")


## 11b / 12b: the creep or point sortie is over: everyone walks back to the rally (not a retreat).
func _sortie_over(cleared: bool, reason: String) -> void:
	var t := _sortie
	var what := "CREEP" if stage == Stage.CREEP else "POINT"
	_log("%s over (%s): %s" % [what, reason, _sortie_name()])
	if stage == Stage.CREEP and mapfill_ai != null:
		var joined: Node3D = _wizard if _hero_joins and _wizard != null and _wizard.is_alive() else null
		var line := mapfill_ai.note_creep_end(t, cleared, joined)
		if line != "":
			_log(line)
	var i := 0
	for u in _group:
		i += 1
		_order_move(u as Unit, _rally_spot(i))
	_clear_group()


func _sortie_name() -> String:
	return str(_sortie.get("name", "?"))


func _set_stage(s: Stage) -> void:
	stage = s
	_stage_since = _now


func _hunt(b: Building) -> void:
	_hunt_target = b
	_hunt_point = Vector3.INF
	_set_stage(Stage.HUNT)
	_log("ATTACK target %s at %s" % [b.building_type.display_name if b.building_type else "building",
			_xz(b.global_position)])


## Next target: the nearest seen enemy building, else the next place to look, else go home.
func _next_hunt(from: Vector3) -> void:
	var b := memory.nearest_building(from, INF, &"", &"tower")   # towers last
	if b == null:
		b = memory.nearest_building(from)
	if b:
		_hunt(b)
		return
	while not _explore.is_empty():
		var p: Vector3 = _explore.pop_front()
		if _flat(p, from) > POINT_REACHED:
			_hunt_target = null
			_hunt_point = p
			_set_stage(Stage.HUNT)
			_log("ATTACK searching %s" % _xz(p))
			return
	_start_retreat("nothing left to find")


## Where enemy buildings may stand: their keep, their natural hall, the mirror of our slots.
func _explore_points() -> Array[Vector3]:
	var out: Array[Vector3] = [_level.base_center(_enemy_team), _level.natural_hall_spot(_enemy_team)]
	for row: Dictionary in ROWS:
		var p: Vector3 = row["pos"]
		if p != Vector3.INF and not row.get("trade", false):
			out.append(-_side(p))
	if _fog != null:
		# 6.A1: after the keep, the spots this team never explored first (buildings it can't know of).
		var keep_spot: Vector3 = out.pop_front()
		var unexplored: Array[Vector3] = []
		var explored: Array[Vector3] = []
		for p in out:
			if _fog.is_explored(int(team), p):
				explored.append(p)
			else:
				unexplored.append(p)
		out = [keep_spot]
		out.append_array(unexplored)
		out.append_array(explored)
	return out


## No enemy unit seen near the group: its 3 units nearest to a seen enemy barracks hit it.
func _focus_barracks(centre: Vector3) -> void:
	if memory.fighter_near(centre, FOCUS_RADIUS, _now, FRESH):
		return
	var b := memory.nearest_building(centre, FOCUS_SEARCH, &"barracks")
	if b == null:
		return
	var sorted := _group.duplicate()
	sorted.sort_custom(func(x: Unit, y: Unit) -> bool:
		return _flat(x.global_position, b.global_position) < _flat(y.global_position, b.global_position))
	for i in mini(FOCUS_UNITS, sorted.size()):
		var u := sorted[i] as Unit
		if u.attack_target != b:
			u.command_attack(b)
			_orders[u.get_instance_id()] = [2, b.global_position, _now]


func _group_attack_move(pos: Vector3) -> void:
	for u in _group:
		var unit := u as Unit
		if unit is Worker:
			# Workers never pick fights: they hit the nearest seen building, else walk along.
			var b := memory.nearest_building(unit.global_position, FOCUS_SEARCH)
			if b:
				if unit.attack_target != b:
					unit.command_attack(b)
					_orders[unit.get_instance_id()] = [2, b.global_position, _now]
			else:
				_order_move(unit, pos, 3.0)
			continue
		if unit.attack_target is Building and _orders.get(unit.get_instance_id(), [0])[0] == 2:
			continue   # focusing a barracks
		_order_attack_move(unit, pos, 3.0)


func _group_centre() -> Vector3:
	var c := Vector3.ZERO
	if _group.is_empty():
		return _rally
	for u in _group:
		c += (u as Unit).global_position
	c /= float(_group.size())
	return Vector3(c.x, 0.0, c.z)


func _group_out() -> bool:
	return stage != Stage.NONE and stage != Stage.RETREAT


# ---------------------------------------------------------------- read-only views for AICasters (caster-units.md 8)

## The attack group (units; empty while none is out).
func army_group() -> Array:
	return _group


func rally_point() -> Vector3:
	return _rally


func is_retreating() -> bool:
	return stage == Stage.RETREAT


func group_out() -> bool:
	return _group_out()


func home_keep() -> Keep:
	return _keep if is_instance_valid(_keep) else null


## The enemy units this team sees now (this tick's scan).
func seen_enemies() -> Array[Unit]:
	return _enemies


## Own living soldiers (no workers, champions, caravans, casters).
func own_soldiers() -> Array[Unit]:
	return _soldiers


## Own living casters.
func own_casters() -> Array[Unit]:
	return _casters


## True when `cost` crystals may be spent now without starving a waiting build (rule 4's reserve, 20 s starve rule).
func can_spend_now(cost: int) -> bool:
	return _can_spend(cost)


## True while a build row waits for crystals (rule 4 reserves them).
func build_waiting() -> bool:
	return _pending_cost > 0


## The own wizard while alive, else null.
func own_wizard() -> Wizard:
	return _wizard if is_instance_valid(_wizard) and _wizard.is_alive() else null


## True while rule 1 defends the base.
func defending() -> bool:
	return _defending


## True when rule 5 already queued a unit this tick.
func queued_this_tick() -> bool:
	return _queued_this_tick


## A line in the decision log (AICasters).
func note_log(text: String) -> void:
	_log(text)


## True while the pop cap can still rise: below the hard cap with a house row free or a house site up.
func _can_grow() -> bool:
	if _eco.pop_cap >= _pop_cap_max():
		return false
	var house: BuildingType = _types.get(&"house")
	if house == null:
		return false
	var count := 0
	for b in _buildings:
		if b.building_type == house:
			if not b.is_constructed():
				return true
			count += 1
	return house.max_count <= 0 or count < house.max_count


## The highest pop cap this team can reach (200 since 2026-09-27): the Economy's per-team limit when it has one, else
## Economy.MAX_POP_CAP.
func _pop_cap_max() -> int:
	if _cap_max_at == _now and _cap_max >= 0:
		return _cap_max   # 20.A3: asked once per build row per tick: looked up once per tick
	_cap_max_at = _now
	_cap_max = _pop_cap_max_now()
	return _cap_max


func _pop_cap_max_now() -> int:
	for key: StringName in [&"max_pop_cap", &"pop_cap_max", &"pop_limit"]:
		var v: Variant = _eco.get(key)
		if v is int or v is float:
			return int(v)
	for m: StringName in [&"max_pop_cap", &"pop_cap_max", &"pop_limit"]:
		if _eco.has_method(m):
			return int(_eco.call(m))
	return Economy.MAX_POP_CAP


## True when crystals can't buy a soldier and can't be mined any more (no node left on the map, or
## no worker and no keep to train one).
func _out_of_crystals() -> bool:
	if _eco.crystals >= _min_soldier_cost:
		return false
	if not _node_left():
		return true
	# 20.A2: a worker already queued, or trade gold that still comes in (exchanged while recovering), can mine too.
	var can_mine := not _workers.is_empty() \
			or (_keep != null and _worker_type != null and (_eco.crystals >= _worker_type.cost \
			or _queued_count(_keep, true) > 0 or _trade_funds_comeback()))
	return not can_mine


## A node the workers can still mine: an own home / natural node, else a safe far one.
func _node_left() -> bool:
	return not _home_nodes().is_empty() or _own_node("mid") != null \
			or _safe_far_node(_level.base_center(int(team))) != null


## Units in `b`'s training queue (workers only when `workers_only`).
static func _queued_count(b: TrainingBuilding, workers_only: bool = false) -> int:
	if b == null or not is_instance_valid(b):
		return 0
	if not workers_only:
		return b.queue.size()
	var n := 0
	for t in b.queue:
		if t != null and t.is_worker:
			n += 1
	return n


## Workers the economy must not touch: scouting, fleeing or in the all-in group.
func _busy(w: Worker) -> bool:
	var id := w.get_instance_id()
	return w == _scout or _fleeing.has(id) or _group_ids.has(id)


# ---------------------------------------------------------------- rule 8: the wizard

func _rule_wizard() -> void:
	var w := _wizard
	if w == null or not is_instance_valid(w):
		return
	if not w.is_alive():
		_hero_was_dead = true
		_hero_state = HeroState.ANCHOR
		return
	if is_scripted(w):
		return   # a mission drives him itself
	if _hero_was_dead:
		_hero_was_dead = false
		_hero_wait_until = _now + HERO_RESPAWN_WAIT
		_log("WIZARD back, waits at the anchor")
	var ratio := w.hp / maxf(w.max_hp, 1.0)
	var home := _keep.drop_off_point() if _keep else _anchor

	if _hero_state == HeroState.HEAL:
		if ratio >= HERO_OK or _now - _hero_since >= HERO_HEAL_MAX:
			_hero_state = HeroState.ANCHOR
			_log("WIZARD healed (%.0f %%)" % (ratio * 100.0))
		else:
			if _flat(w.global_position, home) > HERO_HOME:
				_order_move(w, home)
			return
	elif ratio < HERO_LOW:
		_hero_state = HeroState.HEAL
		_hero_since = _now
		_log("WIZARD low (%.0f %%), goes home" % (ratio * 100.0))
		if _cast_retreat_spell(w):
			_log("WIZARD casts %s before the retreat" % ai.retreat_spell)
		_order_move(w, home, 1.0)
		_items_move_start()
		return

	if _now < _hero_wait_until:
		_hero_state = HeroState.WAIT
		if w.attack_target == null and _flat(w.global_position, _anchor) > HERO_ANCHOR_SLACK:
			_order_move(w, _anchor)
		return

	if _defending and _defend_fight and _intruder_pos != Vector3.INF \
			and not (_minor_defence and _hero_joins and _group_out()):   # 20.A3: a minor defence doesn't hold him
		_hero_state = HeroState.DEFEND
		if w.attack_target == null:
			_order_attack_move(w, _intruder_pos, 4.0)
		return

	if _drive_follow(w):
		return

	if _hero_state == HeroState.CROWN and _level.crown and _level.crown.wearer == w:
		_log("WIZARD wears the crown")
		_hero_state = HeroState.ANCHOR
	if not ai.hero_stays_home and _crown_ok(w):
		if _hero_state != HeroState.CROWN:
			_log("WIZARD goes for the crown at %s" % _xz(_level.crown.global_position))
		_hero_state = HeroState.CROWN
		_order_move(w, _level.crown.global_position, 1.0)
		return

	# 12.A1: map-fill jobs (easy: points on its path; a shrine with no squad; drops after a creep). They wait while
	# the wizard follows an attack (not a creep / point sortie, which he may leave for a point on his path).
	if mapfill_ai != null and not ai.hero_stays_home and w.attack_target == null:
		var in_attack := _hero_joins and _group_out() and not _group.is_empty() \
				and stage != Stage.CREEP and stage != Stage.POINT
		var job := mapfill_ai.wizard_goal(_now, w, in_attack)
		if job != Vector3.INF:
			if _hero_state != HeroState.JOB:
				_log("WIZARD job: %s %s" % [str(mapfill_ai.wizard_job.get("kind", "")),
						str(mapfill_ai.wizard_job.get("name", ""))])
			_hero_state = HeroState.JOB
			_order_move(w, job, 1.0)
			return

	if _hero_joins and not ai.hero_stays_home and _group_out() and not _group.is_empty():
		if _hero_state != HeroState.ATTACK:
			_items_move_start()
		_hero_state = HeroState.ATTACK
		var centre := _group_centre()
		var goal := CROWN_SPOT
		match stage:
			Stage.MID:
				goal = _mid_goal
			Stage.KEEP:
				goal = _level.base_center(_enemy_team)
			Stage.HUNT:
				goal = _hunt_point
				if _hunt_target != null and is_instance_valid(_hunt_target):
					goal = (_hunt_target as Building).global_position
			Stage.CREEP, Stage.POINT, Stage.SHRINE:
				goal = _sortie.get("pos", CROWN_SPOT)
		var dir := goal - centre
		dir.y = 0.0
		var follow := centre - (dir.normalized() * HERO_FOLLOW if dir.length() > 0.5 else Vector3.ZERO)
		if w.attack_target == null:
			_order_attack_move(w, follow, 3.0)
		return

	_hero_state = HeroState.ANCHOR
	if w.attack_target == null and _shop_walk(w):
		return
	if w.attack_target == null and _flat(w.global_position, _anchor) > HERO_ANCHOR_SLACK:
		_order_move(w, _anchor)


## ai.retreat_spell (Rime Aegis: self; Wild Bloom: an area centred on the wizard). False if not cast.
func _cast_retreat_spell(w: Wizard) -> bool:
	if ai.retreat_spell == &"" or not w.spell_ids().has(ai.retreat_spell):
		return false
	if w.spell_caster and w.spell_caster.has_method(&"can_cast") \
			and str(w.spell_caster.call(&"can_cast", ai.retreat_spell)) != "":
		return false
	if w.command_cast(ai.retreat_spell, null) == "":
		return true
	return w.command_cast(ai.retreat_spell, w.global_position) == ""


## follow_units() (mission Final wave): attack-move HERO_FOLLOW m behind the centre of the living units,
## on their side toward the wizard's anchor. False when nobody is left to follow (back to the anchor).
func _drive_follow(w: Wizard) -> bool:
	if _follow_units.is_empty():
		return false
	var centre := Vector3.ZERO
	var n := 0
	for x: Variant in _follow_units:
		if x != null and is_instance_valid(x) and (x as Unit).is_alive():
			centre += (x as Unit).global_position
			n += 1
	if n == 0:
		_follow_units.clear()
		_log("WIZARD: the followed units are gone, back to the anchor")
		return false
	centre /= float(n)
	_hero_state = HeroState.ATTACK
	var back := _anchor - centre
	back.y = 0.0
	var spot := centre + (back.normalized() * HERO_FOLLOW if back.length() > 0.5 else Vector3.ZERO)
	if w.attack_target == null:
		_order_attack_move(w, spot, 3.0)
	return true


## 4.A1: idle, the army not attacking, the next item affordable and no shop within 12 m: walk to the keep.
func _shop_walk(w: Wizard) -> bool:
	if items == null or _group_out() or _keep == null or not is_instance_valid(_keep):
		return false
	var inv := AIItems.inventory_of(w)
	if inv == null or AIItems.shop_near(w, _buildings) or not items.wants_shop(inv) or not _items_allowed(inv):
		return false
	var k := _keep.global_position
	var away := w.global_position - k
	away.y = 0.0
	var spot := k + (away.normalized() * SHOP_WALK_DIST if away.length() > 0.5 else Vector3.ZERO)
	var last: Array = _orders.get(w.get_instance_id(), [])
	if last.is_empty() or last[0] != 0 or _flat(last[1], spot) > 2.0:
		_log("WIZARD walks to the shop (next item affordable)")
	_order_move(w, spot)
	return true


## 4.A1: item uses every tick (Draught, Brace, Blink, Rallying Cry), then one purchase when near an own shop.
func _rule_items() -> void:
	var w := _wizard
	if items == null or w == null or not is_instance_valid(w) or not w.is_alive():
		return
	var inv := AIItems.inventory_of(w)
	if inv == null:
		return
	var home := _keep.global_position if _keep and is_instance_valid(_keep) else _level.base_center(int(team))
	var enemy_close := _nearest_enemy_fighter(w.global_position, AIItems.BRACE_ENEMY) != null
	var very_close := _nearest_enemy_fighter(w.global_position, AIItems.SHELL_ENEMY) != null
	for line in items.use_tick(w, inv, _now, enemy_close, home, _soldiers, very_close):
		_log(line)
	if AIItems.shop_near(w, _buildings) and _items_allowed(inv):
		var line := items.shop_tick(inv)
		if line != "":
			_log(line)


## 9.C9: champions come before items: the next purchase only when the essence left after it still pays what
## AIChampions holds (a due hire's essence, normal / hard: fallen champions' revives).
func _items_allowed(inv: Object) -> bool:
	var hold := champion_ai.essence_hold() if champion_ai else 0
	if hold <= 0 or items == null:
		return true
	var p := items.next_purchase(inv)
	if p.is_empty():
		return true
	var have := items.essence()
	return have < 0 or have - items.price(inv, p["type"]) >= hold


## 9.C9: the essence of the wizard's next purchase (0: no items system, nothing left to buy).
func _next_item_price() -> int:
	if items == null or _wizard == null or not is_instance_valid(_wizard):
		return 0
	var inv := AIItems.inventory_of(_wizard)
	if inv == null or not inv.has_method(&"buy"):
		return 0
	var p := items.next_purchase(inv)
	return 0 if p.is_empty() else maxi(0, items.price(inv, p["type"]))


## Rule 9 (9.C9, champions.md 10): revive, hire, one bounty flag (AIChampions). Runs before the items rule so a
## revive gets the essence first.
func _rule_champions() -> void:
	if champion_ai == null or champion_ai.guild() == null:
		return   # no taverns on this map (mission 1), or a profile that never hires
	var intruder := _intruder_pos if _defending else Vector3.INF
	for line in champion_ai.tick(_now, _level, memory, _fog, _next_item_price(), _build_cost, _buildings,
			_defending, intruder, _group_out()):
		_log(line)
	_place_usec += champion_ai.last_action_usec()   # 20.A3: a hire / revive spawn costs a player the same


## 10.A3: the trade sense (lost Bazaar, behind, caravan hits, Magpie sightings); a caravan hit within 35 m of
## an own building makes its attacker a rule-1 intruder (10j).
func _trade_sense() -> void:
	_update_recovery()
	if trade_ai == null or not trade_ai.active():
		return
	trade_ai.set_profile(ai)
	trade_ai.sense(_now, _fog, own_strength, seen_strength, _caravans, _buildings)
	var hit := trade_ai.intruder()
	if hit != null:
		_hit_by = hit
		_hit_time = _now


## 20.A2 F1 (ai-2v2.md 7.2): recovery = 0 workers, or fewer than 3 workers and crystals < worker cost + 50, while a
## keep or a barracks stands (a mission bot that never attacks never recovers: its level scripts it). Set on the
## Commander and on AITrade every tick, logged when it starts and ends.
func _update_recovery() -> void:
	var was := recovering
	var stands := (_keep != null and is_instance_valid(_keep) and _keep.is_alive()) or not _barracks.is_empty()
	var worker_cost := _worker_type.cost if _worker_type else 0
	# A worker only helps while a node is left to mine (else all_in: the gold still becomes crystals, for soldiers).
	recovering = ai.launch_attacks and stands and _worker_type != null and (_workers.is_empty() \
			or (_workers.size() < RECOVERY_WORKERS and _eco.crystals < worker_cost + RECOVERY_MARGIN)) \
			and _node_left()
	if trade_ai != null:
		# All-in (nothing left to mine): every 100 gold becomes crystals too (no wares, no hunters): soldiers.
		trade_ai.recovering = recovering or (all_in and ai.launch_attacks)
		trade_ai.recovery_workers = _workers.size()
	if recovering and not was:
		recovery_starts.append(_now)
		var gold := trade_ai.bank().gold if trade_ai != null and trade_ai.active() else 0
		_log("RECOVERY on: %d workers, %d crystals, %d gold" % [_workers.size(), _eco.crystals, gold])
	elif was and not recovering:
		_log("RECOVERY off: %d workers, %d crystals" % [_workers.size(), _eco.crystals])


## Rule 10 (10.A3, market-trade.md 7): one caravan queued (10c), then routes, hunters and wares (10d-10g).
func _rule_trade() -> void:
	if trade_ai == null or not trade_ai.active():
		return
	_queue_caravan()
	for line in trade_ai.tick(_now, memory, own_strength, seen_strength, _soldiers):
		_log(line)


## 10c: caravans (alive + queued) below the target, crystals >= 125, pop_used + 1 <= pop_cap - 2, the Bazaar
## queue empty -> queue one (the build 20 s rule and the champion pop reserve apply, one queue per tick).
func _queue_caravan() -> void:
	if _queued_this_tick or recovering:
		return   # 20.A2 F1: no caravans while rebuilding workers
	var m := trade_ai.market()
	if m == null or not m.queue.is_empty():
		return
	var have := _caravans.size()   # alive (this tick's scan); the Bazaar queue is empty (one Bazaar per team)
	# 20.A2 F4: pop-capped with a small army -> fewer caravans (pop for the soldiers that must finish the game).
	var target := trade_ai.caravan_target(_home_nodes().is_empty(), _eco.pop_used, _eco.pop_cap, _soldier_pop())
	if have >= target:
		return
	var types := m.trainable_types()
	if types.is_empty():
		return
	var t := types[0]
	if _eco.crystals < AITrade.CARAVAN_CRYSTALS or _eco.pop_used + t.pop > _eco.pop_cap - AITrade.CARAVAN_POP_FREE:
		return
	if not _pop_ok(t.pop) or m.can_queue(t) != "" or not _can_spend(t.cost):
		return
	if m.queue_unit(t) == "":
		_note_queued()
		_queued_this_tick = true
		trade_ai.caravans_queued += 1
		_log("TRAIN %s (%d caravans + 1 queued, target %d%s, crystals left %d)" % [t.display_name, have, target,
				", behind" if trade_ai.behind else "", _eco.crystals])


## 10i, after the champion rule (10h): surplus gold -> crystals (essence when the next item is within 100).
func _trade_exchange() -> void:
	if trade_ai == null or not trade_ai.active():
		return
	if not trade_ai.exchange_ready():
		return   # nothing to exchange: skip the item price lookup
	var bank := EssenceBank.for_team(int(team))
	var line := trade_ai.exchange_tick(_next_item_price(), bank.essence if bank else 0)
	if line != "":
		_log(line)


## Stride when the wizard starts an attack or a retreat.
func _items_move_start() -> void:
	if items == null or _wizard == null or not is_instance_valid(_wizard):
		return
	var inv := AIItems.inventory_of(_wizard)
	if inv == null:
		return
	for line in items.on_move_start(_wizard, inv):
		_log(line)


## The camp is dead, the crown lies free, no enemy soldier near it, the wizard is healthy enough.
func _crown_ok(w: Wizard) -> bool:
	var c := _level.crown
	if c == null or not c.is_available() or _camp_alive() or crown_sealed_left() > 0.0:
		return false
	if _hero_state != HeroState.CROWN and w.hp < HERO_CROWN_HP * w.max_hp:
		return false
	return not memory.fighter_near(c.global_position, CROWN_CLEAR, _now, FRESH)


## balance-1.md 2e: seconds until the crown can be picked up (0 = unsealed). Uses the crown's (or the
## level's) crown_unseal_time_left() when it exists, else the crown's SEAL_TIME constant, else no seal.
func crown_sealed_left() -> float:
	if _level == null:
		return 0.0
	var c: Object = _level.crown
	if c != null and is_instance_valid(c) and c.has_method(&"crown_unseal_time_left"):
		return float(c.call(&"crown_unseal_time_left"))
	if _level.has_method(&"crown_unseal_time_left"):
		return float(_level.call(&"crown_unseal_time_left"))
	if c != null and is_instance_valid(c) and c.get_script() != null:
		var consts: Dictionary = (c.get_script() as Script).get_script_constant_map()
		if consts.has("SEAL_TIME"):
			return maxf(0.0, float(consts["SEAL_TIME"]) - _level.match_time())
	return 0.0


func _camp_alive() -> bool:
	for i in _level.wardens.size():
		var u: Variant = _level.wardens[i]   # may be freed: never into a typed variable
		if is_instance_valid(u) and (u as Unit).is_alive():
			return true
	return false


# ---------------------------------------------------------------- spells (3.A1)

## levels.md "The bot": spend every point on the first learnable entry of ai.spell_order ("Q1" = spell 2
## rank 1). An entry is learnable when the spell is exactly one rank below it and can_learn() says "".
## Runs every tick (the tick after level_changed), dead or alive. Also takes over casting when it can.
func _learn_spells() -> void:
	var w := _wizard
	if w == null or not is_instance_valid(w):
		return
	_take_casting(w)
	var ids := w.spell_ids()
	var guard := 0
	while w.spell_points > 0 and guard < 16:
		guard += 1
		var learned := false
		for entry: String in ai.spell_order:
			var slot := SPELL_SLOTS.find(entry.substr(0, 1))
			var rank := entry.substr(1).to_int()
			if slot < 0 or slot >= ids.size() or rank < 1:
				continue
			var id := ids[slot]
			if w.spell_rank(id) != rank - 1 or w.can_learn(id) != "":
				continue
			if w.learn_spell(id) == "":
				spells_learned.append(entry)
				_log("WIZARD learns %s (%s rank %d) at level %d" % [entry, id, rank, w.level])
				learned = true
				break
		if not learned:
			return   # points banked: nothing on the list is learnable yet


## The one-caster rule (see the header): only when the wizard lets its own loop be switched off.
## 7.A1: a wizard without a loop of its own (Torvald) is cast for by the Commander when its SpellCaster
## has suggest_cast() (the kingdom's rules, e.g. kingdom-ice.md 4.3).
func _take_casting(w: Wizard) -> void:
	if casts_owned:
		return
	if "ai_auto_cast" in w:
		w.set(&"ai_auto_cast", false)
	elif w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	casts_owned = true
	_cast_timer = Timer.new()
	_cast_timer.wait_time = CAST_CHECK
	_cast_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_cast_timer.autostart = true
	_cast_timer.timeout.connect(_cast_check)
	add_child(_cast_timer)
	_log("WIZARD casting now driven by the Commander (reaction %.1f s)" % ai.reaction_delay)


## Every 0.5 s while the Commander owns casting: the suggest_cast() rules, at most one cast, after an
## enemy has been within 12 m for ai.reaction_delay. Rule 1 (Shroud) also starts the HEAL retreat.
func _cast_check() -> void:
	var w := _wizard
	if not enabled or _level == null or _level.game_over or w == null or not is_instance_valid(w) \
			or not w.is_alive() or w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		_threat_since = -1.0
		return
	if AICasts.is_vessa(w):
		_vessa_cast_check(w)
		return
	var now := _level.match_time()
	var threat := false
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and w.is_enemy_of(u) and _flat(u.global_position, w.global_position) <= CAST_NEARBY \
				and (_fog == null or int(u.team) != _enemy_team or _fog.is_visible(int(team), u.global_position)):
			threat = true
			break
	if not threat:
		_threat_since = -1.0
		if AICasts.is_nature(w):   # 8.A1: Wild Bloom may still mend the army after a fight (no enemy near)
			var heal: Dictionary = w.spell_caster.call(&"suggest_cast")
			if StringName(str(heal.get("spell_id", ""))) == &"wild_bloom":
				w.command_cast(&"wild_bloom", heal.get("target"))
		return
	if _threat_since < 0.0:
		_threat_since = now
	if now - _threat_since < ai.reaction_delay:
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	if s.is_empty():
		return
	if w.command_cast(StringName(str(s.get("spell_id", ""))), s.get("target")) != "":
		return
	if bool(s.get("retreat", false)) and _hero_state != HeroState.HEAL and not is_scripted(w):
		_hero_state = HeroState.HEAL
		_hero_since = now
		_order_move(w, _keep.drop_off_point() if _keep and is_instance_valid(_keep) else _anchor, 1.0)
		_items_move_start()


## 8.A2: Vessa has no suggest_cast() rules: AICasts.suggest_vessa() instead, every 0.5 s, at most one cast, once a
## visible foe has stayed within AICasts.VESSA_WATCH (her Fireball reach + a blink) for ai.reaction_delay. Ember
## Step clears her order: an escape starts the HEAL retreat home at once, an engage lets rule 8 re-order her.
func _vessa_cast_check(w: Wizard) -> void:
	var now := _level.match_time()
	var foes: Array[Unit] = []
	var allies: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u == w or not u.is_alive() or _flat(u.global_position, w.global_position) > AICasts.VESSA_WATCH:
			continue
		var t := int(u.team)
		if t == int(team):
			if not u is Wizard and not u.is_worker() and not AICasts.is_summon(u):
				allies.append(u)
		elif t == _enemy_team and (_fog == null or _fog.is_visible(int(team), u.global_position)):
			foes.append(u)
	if foes.is_empty():
		_threat_since = -1.0
		return
	if _threat_since < 0.0:
		_threat_since = now
	if now - _threat_since < ai.reaction_delay:
		return
	var home := _keep.drop_off_point() if _keep and is_instance_valid(_keep) else _anchor
	var engage := _hero_state == HeroState.ATTACK or _hero_state == HeroState.DEFEND
	var s := AICasts.suggest_vessa(w, foes, allies, home, engage)
	if s.is_empty():
		return
	var id := StringName(str(s.get("spell_id", "")))
	if w.command_cast(id, s.get("target")) != "":
		return
	var rule := str(s.get("rule", ""))
	vessa_casts[rule] = int(vessa_casts.get(rule, 0)) + 1
	if id == &"fireball":
		return   # every few seconds in a fight: not logged
	_log("WIZARD casts %s (%s)" % [id, rule])
	if id != &"ember_step" or is_scripted(w):
		return
	_orders.erase(w.get_instance_id())   # the blink stopped her: the next order must go out
	if bool(s.get("retreat", false)):
		if _hero_state != HeroState.HEAL:
			_hero_state = HeroState.HEAL
			_hero_since = now
			_items_move_start()
		_order_move(w, home, 1.0)


# ---------------------------------------------------------------- 12.A1: map fill (rules 11-13)

## Before rule 1: AIMapFill's services and point threats; an enemy capturing an own point within 35 m of an own
## building becomes a rule-1 intruder (12b).
func _mapfill_sense() -> void:
	if mapfill_ai == null or not ai.map_fill:
		return
	mapfill_ai.set_profile(ai)
	mapfill_ai.sense(_now, _fog, memory, own_strength, seen_strength, _enemies, _buildings)
	var hit := mapfill_ai.intruder()
	if hit != null:
		_hit_by = hit
		_hit_time = _now


## After rule 7: capture squads (12a / 12c / 11d), then (when rule 7 did not launch) a point sortie (12b) or a creep
## (11a / 11e) with the army at the rally minus the reserve.
func _rule_mapfill() -> void:
	if mapfill_ai == null or not mapfill_ai.active():
		return
	var home: Array[Unit] = []
	var scout: Unit = null   # rule 6 comes first: the soldier it would send next stays out of the squads
	var scout_soon := _scout == null and _now >= _next_scout - SCOUT_KEEP_LEAD
	for u in _soldiers:
		if _is_home_unit(u):
			home.append(u)
			if scout_soon and u.attack_target == null and (scout == null or _scout_score(u) < _scout_score(scout)):
				scout = u
	for line in mapfill_ai.squad_tick(_now, _rally, home, _wizard, _wizard_free(), _defending or all_in, scout):
		_log(line)
	_launch_sortie()


## The wizard may take a map-fill job: alive, not healing / waiting / defending, not in an attack group.
func _wizard_free() -> bool:
	var w := _wizard
	if w == null or not is_instance_valid(w) or not w.is_alive() or ai.hero_stays_home or is_scripted(w):
		return false
	if _hero_state == HeroState.HEAL or _now < _hero_wait_until or (_defending and _defend_fight):
		return false
	return not (_hero_joins and _group_out())


## 11a / 11e / 12b: no group out, no defence, rule 7 did not launch this tick; the rally army (>= 80 % there, minus the
## reserve, >= 2 soldiers at >= 60 % average HP) goes for a threatened far own point, else the nearest creep target.
func _launch_sortie() -> void:
	if stage != Stage.NONE or _defending or not ai.launch_attacks or all_in or _launched_tick:
		return
	var home: Array[Unit] = []
	var near := 0
	var rally_strength := 0.0
	for u in _soldiers:
		if _is_home_unit(u):
			home.append(u)
			if _flat(u.global_position, _rally) <= RALLY_RADIUS:
				near += 1
				rally_strength += AIMemory.strength_of(u)
	if home.size() - RESERVE < SORTIE_MIN_UNITS or float(near) < RALLY_SHARE * home.size():
		return
	home.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp > b.hp)
	var group: Array[Unit] = []
	var avg_hp := 0.0
	for i in range(RESERVE, home.size()):
		group.append(home[i])
		avg_hp += home[i].hp / maxf(home[i].max_hp, 1.0)
	avg_hp /= float(group.size())
	if avg_hp < SORTIE_MIN_HP:
		return
	var threat := mapfill_ai.point_sortie()
	if not threat.is_empty():
		if float(threat["strength"]) <= AIMapFill.POINT_SORTIE_RATIO * rally_strength:
			_start_sortie(Stage.POINT, threat, group, _malrik_joins())
			_log("POINT defence: %d units to %s (capturers %.0f vs rally %.0f)" % [group.size(), _sortie_name(),
					float(threat["strength"]), rally_strength])
			_drive_attack()
			return
	if _now < _creep_retry_at:
		return   # a creep just turned back: let the army heal and grow first
	var group_strength := 0.0
	for u in group:
		group_strength += AIMemory.strength_of(u)
	var t := mapfill_ai.creep_target(_now, own_strength, _rally, group_strength)
	if t.is_empty():
		return
	var joins: bool = t["kind"] == &"beast" or int(t["tier"]) == 1 or _malrik_joins()
	_start_sortie(Stage.CREEP, t, group, joins)
	mapfill_ai.note_creep_start(t, own_strength)
	_log("CREEP %s (%s) %d units str %.0f (army %.0f) vs %.0f (x%.1f)%s" % [_sortie_name(),
			("beast" if t["kind"] == &"beast" else "tier %d" % int(t["tier"])), group.size(), group_strength,
			own_strength, float(t["strength"]), group_strength / maxf(float(t["strength"]), 1.0),
			" + wizard" if joins else ""])
	_drive_attack()


## Stage CREEP / POINT with `group` against `target` (Commander's attack-group machinery: retreat, recall, rally).
func _start_sortie(s: Stage, target: Dictionary, group: Array[Unit], hero: bool) -> void:
	_group = []
	_group_ids.clear()
	_launch_hp = 0.0
	for u in group:
		_group.append(u)
		_group_ids[u.get_instance_id()] = true
		_launch_hp += u.hp
	_sortie = target
	_hero_joins = hero
	_set_stage(s)


# ---------------------------------------------------------------- concede

## skirmish-1v1.md: no barracks, no workers, < 100 crystals, no soldiers. Also "nothing can recover"
## in the endgame: no soldiers, no workers and nothing left to mine or buy.
## 20.A2 (ai-2v2.md 7.2 F2): trade blocks it only while it can pay for a comeback (a completed Bazaar and gold >= 100
## or >= 60 gold earned by trips in the last 120 s, and a node left to mine; caravans alone never do), and a unit in a
## training queue blocks it. Hard stop: no living soldier and no crystal delivered for 150 s (so 0 workers, 0 soldiers,
## 0 queued for 150 s, and also workers bought with trade gold that die before delivering) -> concede whatever stands.
func _check_concede() -> void:
	if not ai.launch_attacks:
		return   # a mission bot (launch_attacks false) never concedes: the mission decides the end
	# Hard stop clock: no living soldier and no crystal delivered by a worker. It also catches the trickle where
	# every worker bought with trade gold dies before its first delivery (queued units never stop the clock).
	var delivered := _eco.gathered_total != _last_gathered
	_last_gathered = _eco.gathered_total
	if not _soldiers.is_empty():
		_had_soldier = true
	# Armed once the bot has had a soldier (or from HARD_STOP_ARM): the opening has none and waits for deliveries.
	var armed := _had_soldier or _now >= HARD_STOP_ARM
	if not armed or not _soldiers.is_empty() or delivered:
		_hopeless_since = -1.0
		_hopeless_logged = false
	elif _hopeless_since < 0.0:
		_hopeless_since = _now
	if _hopeless_since >= 0.0 and not _hopeless_logged and _now - _hopeless_since >= HARD_STOP_LOG:
		_hopeless_logged = true   # logged once per stretch, only when it lasts
		_log("HOPELESS: no soldier, no delivery for %.0f s (%d workers, %d crystals, %d caravans): hard stop in %.0f s" % [
				_now - _hopeless_since, _workers.size(), _eco.crystals, _caravans.size(),
				HARD_STOP_TIME - (_now - _hopeless_since)])
	if _hopeless_since >= 0.0 and _now - _hopeless_since >= HARD_STOP_TIME:
		_concede("hard stop")
		return
	if not _workers.is_empty() or not _soldiers.is_empty():
		return
	var queued := _queued_count(_keep)
	for b in _barracks:
		queued += _queued_count(b)
	if queued > 0:
		return   # a comeback is being paid for
	if _trade_funds_comeback() and _node_left():
		return   # 10.A3 / 20.A2 F2: trade can still pay for a comeback (workers need a node left to mine)
	if not all_in:
		if _eco.crystals >= CONCEDE_CRYSTALS:
			return
		for b in _buildings:
			if b.building_type and b.building_type.kind == &"barracks":
				return
	_concede("all-in" if all_in else "rule")


## 20.A2 F3: the seat gives up. `level.eliminate_seat(seat, line)` when the level has it (2v2, 20.D1), else
## `surrender(team, line)` (1v1: the seat is the team).
func _concede(reason: String) -> void:
	conceded_at = _now
	concede_reason = reason
	var gold := trade_ai.bank().gold if trade_ai != null and trade_ai.active() else 0
	_log("CONCEDE %s (workers %d, soldiers %d, caravans %d, crystals %d, gold %d, all-in %s)" % [reason,
			_workers.size(), _soldiers.size(), _caravans.size(), _eco.crystals, gold, str(all_in)])
	if _level.has_method(&"eliminate_seat"):
		_level.call(&"eliminate_seat", _seat(), _concede_line())
	else:
		_level.surrender(int(team), _concede_line())


## This bot's seat: the team in the 1v1 (the 2v2 seat API of 20.D1 / 20.A1 replaces it).
func _seat() -> int:
	return int(team)


## The bot wizard's parting line when it concedes (Malrik's is the skirmish's own). Original lines.
func _concede_line() -> String:
	match _faction:
		&"shadow":
			return Skirmish.MALRIK_CONCEDES
		&"ice":
			return "Torvald: \"The frost can wait. So can I.\""
		&"nature":
			return "Ysolde: \"Cut the grove down. It always grows back.\""
		&"fire":
			return "Vessa: \"Fine. Keep the ashes. I will light them again.\""
	return ""


# ---------------------------------------------------------------- helpers

func _order_move(u: Unit, pos: Vector3, tolerance: float = 2.0) -> void:
	if not u.is_commandable():
		return   # 9.C9: champions are never ordered (a second guard behind _scan)
	var id := u.get_instance_id()
	var last: Array = _orders.get(id, [])
	if not last.is_empty() and last[0] == 0 and _flat(last[1], pos) <= tolerance and _now - float(last[2]) < ORDER_REPEAT:
		return
	_orders[id] = [0, pos, _now]
	u.command_move(pos)


## Not re-sent while the unit fights (attack-move resumes by itself) or to about the same spot.
func _order_attack_move(u: Unit, pos: Vector3, tolerance: float = 2.0) -> void:
	if not u.is_commandable():
		return
	var id := u.get_instance_id()
	var last: Array = _orders.get(id, [])
	var same: bool = not last.is_empty() and last[0] == 1 and _flat(last[1], pos) <= tolerance
	if same and (u.attack_target != null or _now - float(last[2]) < ORDER_REPEAT):
		return
	_orders[id] = [1, pos, _now]
	u.command_attack_move(pos)


## Soldiers not in the attack group, not scouting and not in a capture squad (12.A1).
func _is_home_unit(u: Unit) -> bool:
	return u != _scout and not _group_ids.has(u.get_instance_id()) \
			and (mapfill_ai == null or not mapfill_ai.is_busy(u))


func _nearest_enemy_fighter(pos: Vector3, radius: float) -> Unit:
	var best: Unit = null
	var best_d := radius
	for e in _enemies:
		if e is Worker:
			continue
		var d := _flat(e.global_position, pos)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _distance_to_base(pos: Vector3) -> float:
	var best := INF
	for b in _buildings:
		best = minf(best, _flat(b.global_position, pos))
	return best


## `p` given for the Shadow side, mirrored for a Fire bot. On a LayoutLevel (map-production.md MT2) the level maps
## these Crown Hollow points onto its own seats (`bot_point`; identity on Crown Hollow itself).
func _side(p: Vector3) -> Vector3:
	if _level != null and _level.has_method(&"bot_point"):
		return _level.call(&"bot_point", int(team), p)
	return p if team == Unit.Team.ENEMY else -p


## A relative offset `v` given for the Shadow side (slot shifts, wall offsets), turned for this side. On a LayoutLevel
## the level's `bot_vector` (the turn of `bot_point` without its translation; review H3).
func _side_vec(v: Vector3) -> Vector3:
	if _level != null and _level.has_method(&"bot_vector"):
		return _level.call(&"bot_vector", int(team), v)
	return v if team == Unit.Team.ENEMY else -v


static func _prune(list: Array, ids: Dictionary) -> void:
	for i in range(list.size() - 1, -1, -1):
		var x: Variant = list[i]
		if x == null or not is_instance_valid(x) or not (x as Unit).is_alive():
			list.remove_at(i)
	ids.clear()
	for x in list:
		ids[(x as Unit).get_instance_id()] = true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _xz(p: Vector3) -> String:
	return "(%d, %d)" % [roundi(p.x), roundi(p.z)]


static func _name_of(n: Node) -> String:
	var u := n as Unit
	return u.unit_name if u else String(n.name)


func _log(text: String) -> void:
	var s := int(_now)
	var line := "[%d:%02d] %s" % [s / 60, s % 60, text]
	log_lines.append(line)
	if log_lines.size() > LOG_KEEP:
		log_lines.remove_at(0)
	if debug_log:
		print("BOT %d %s" % [int(team), line])
