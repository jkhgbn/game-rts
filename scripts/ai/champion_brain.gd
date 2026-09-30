class_name ChampionBrain
extends Node
## A champion's autonomous behaviour (docs/design/champions.md section 8, task 9.C5). A child named "Brain"
## of each Champion (the Champion creates it in _ready from this script's path). Nobody orders champions:
## this brain moves its parent with the normal command_move / command_attack / command_attack_move.
##
## Rules, first that fires wins (8.1):
## R1 fallen / reviving -> nothing (`Fallen` / `Returns in N s`);
## R2 flee under Champion.flee_pct (the archetype's + the class delta, skills-rework.md 3) to the nearest rest
##    spot (own completed keep / barracks, or a tavern door not held by the enemy), Stride on the way, rest until
##    85 % HP or 60 s (`Fleeing`, `Resting`); while resting it may shop at a shop within 20 m;
## R3 Ember Draught under 50 % HP (does not stop the other rules);
## R4 join a fight: it was hit in the last 2 s, or an own unit / building within its engage radius was hit
##    in the last 2 s by a visible enemy, and danger there <= courage x power x 1.5 (`Fighting`). Target: the
##    archetype rule where there is one, else the class's (skills-rework.md 6, `_pick_fight_target`). Stance
##    (11.A1): a back-line champion (`is_back_line()`: Wizard class, or a ranged archetype before its class)
##    keeps today's rules (the Mender keeps 4 m behind its ally, the Wayfinder shoots from its range); a melee
##    class closes in (a melee Mender attacks like the others);
## R5 unpaid: skip R6 (`Unpaid!`);
## R6 bounty flags: utility U = S x G x A x D x R x H (8.2), keep the current flag while valid unless another
##    scores >= 1.5 x, else take the best with U >= ChampionType.bounty_threshold (10);
## R7 shopping detour (purse >= next wish-list price, shop <= 40 m, no flag, once per 60 s);
## R8 personality default (8.3; a melee-class Mender follows 1 m behind the army centre, not 4 m);
## R9 idle wander within 10 m of home.
## 12.A2 map fill (map-fill.md 6; every rule is a no-op when its system is absent): R4 danger counts camp creatures /
## beasts at their strength and remembered camps (ChampionSense); a Claim flag (Explore that `is_claim()`) sends its
## pursuers to stand in the point's capture circle until it is captured; R8 starts with the beast hunting party
## (ChampionSense.party_target: `Hunting big game`); the Wayfinder's map-known patrol loop adds the own bank's
## watchtowers and stands in a not-own one's circle until captured (max 25 s, `Capturing`); the Oathwall's patrol
## adds own-held wells / towers within 35 m of an own building; the Coin-Cutter's Raid clears a T1 camp of its own
## bank (alive, explored) when courage x power x HP >= 1.6 x its strength (after looting Magpies and workers, before
## caches); R8 / R9 walks never cross a remembered living camp's aggro zone (detour) and Wayfinder goals skip them;
## R9 idle hunt (Wayfinder, Coin-Cutter): on its routine (explore / lurk / idle) a game critter visible to the team
## within 15 m -> attack it (`Hunting game`), once per 120 s, dropped beyond 20 m, after 20 s, or when R1-R8 fires.
## R1-R5 run every 0.5 s; R6-R9 are re-planned every 2.0 s, or at the next 0.5 s tick after an event (own
## flags changed, damage taken while not fighting, arrived). Brains are staggered by 0.1 s per champion.
## Knowledge comes only from the team's ChampionSense (fog of war). Intents are the display strings of 8.1
## (`&"Hunting bounty"`, `&"Fleeing"`...) set through `Champion.set_intent(id, target)`.
## Other step-9 classes (Champion, ChampionType, Bounty, ChampionGuild, Tavern) are reached through
## get() / has_method() / groups only.

enum Plan { NONE, FLAG, SHOP, EXPLORE, PATROL, RAID, CACHE, LURK, FOLLOW, HOME, IDLE, CAMP, BEAST, GAME }

const LURK_OFFSET := 14.0   ## Coin-Cutter lurk spot distance from the tavern door (> Tavern.HOLD_RADIUS 12).
enum Order { NONE, MOVE, ATTACK_MOVE, ATTACK }

const FAST_TICK := 0.5
const PLAN_TICK := 2.0
const STAGGER := 0.1
const STAGGER_SLOTS := 5

# R2 flee / rest
const REST_HP := 0.85
const REST_MAX := 60.0
const FLEE_TRAVEL_MAX := 60.0
const FLEE_RETRY := 10.0            ## After a rest that timed out, no new flee for this long.
const REST_BUILDING_RADIUS := 13.0  ## Home rest works within 15 m of a keep / barracks (2 m margin).
const TAVERN_REST_RADIUS := 6.0     ## Tavern rest works within 8 m of the door (2 m margin).
const REST_SHOP_RADIUS := 20.0
# R3 potion
const POTION_HP := 0.5
const POTION_TIME := 8.0            ## A Draught heals over 8 s: no second one meanwhile.
const DRAUGHT_ID := &"ember_draught"
const STRIDE_ID := &"stride"
# R4 fight
const HIT_WINDOW := 2.0
const FIGHT_HOLD := 4.0             ## A fight goes on this long after the last trigger while the target is seen.
const JOIN_DANGER_MULT := 1.5
const DEFAULT_ENGAGE := 10.0
const OATH_HOME_RADIUS := 20.0      ## The Oathwall's big engage radius only counts around own buildings.
const OATH_CHASE := 25.0            ## 8.3: never chases more than 25 m past the last building.
const MENDER_BEHIND := 4.0
const MENDER_MELEE_BEHIND := 1.0    ## 11.A1: a melee-class Mender follows 1 m behind the army centre.
const RANGED_REACH := 3.0           ## An attack range above this shoots (Unit.attack_range doc).
const ARCH_TIER := 1000.0           ## Target score gap of the archetype rule (the class rule scores < 1000).
const CLASS_TIER := 100.0           ## Target score gap inside a class rule (distances are capped below it).
const CLEAVE_RADIUS := 2.5          ## Two-Hand: enemies within 2.5 m of a target count as its crowd.
const CROWD_MAX := 8
# R6 utility
const SWITCH_RATIO := 1.5
const DEFAULT_THRESHOLD := 10.0
const DIST_K := 30.0
const DIST_MULT := 1.2
const RISK_MIN := 0.05
const HEALTH_MIN := 0.3
const LEASH_HOME := 35.0
const LEASH_FACTOR := 0.3
const CUTTER_PREY := 1.3
const MENDER_WIZARD := 1.2
const TOWER_FEAR := 12.0
const TOWER_FEAR_LEVEL := 4
const GUARD_RADIUS := 14.0
const GUARD_POINT_TIME := 8.0
const ESCORT_BEHIND := 4.0
# R7 shopping
const SHOP_DETOUR_MAX := 40.0
const SHOP_DETOUR_GAP := 60.0
const SHOP_BUY_DIST := 10.5         ## Shops sell within 12 m.
const SHOP_TIMEOUT := 40.0
const MAX_BUYS := 8
# R8 defaults
const EXPLORE_RING := 30.0
const EXPLORE_SAMPLES := 12
const EXPLORE_KEEP_DIV := 60.0
const EXPLORE_GOAL_TIME := 30.0
const EXPLORE_REACHED := 4.0
const MAP_LIMIT := 56.0
const PATROL_EVERY := 20.0
const PATROL_HIT_MEMORY := 30.0
const CACHE_TIMEOUT := 40.0
const CACHE_STUCK := 3.0            ## Standing on a cache that did not open: ignore it for a while.
const CACHE_IGNORE := 60.0
const FOLLOW_SAMPLES := 20
const GROUP_RADIUS := 10.0
const MIN_ARMY := 3
const FOLLOW_WIZARD := 5.0
const FOLLOW_ENEMY_RADIUS := 30.0
const IDLE_RADIUS := 10.0
const IDLE_MIN := 8.0
const IDLE_MAX := 12.0
# orders
const ARRIVE := 2.0
const LOOTER_RADIUS := 30.0          ## 10.A3: the Coin-Cutter's Raid takes a visible looting Magpie this close.
const REORDER_DIST := 1.5
const ORDER_NUDGE := 4.0
# 12.A2 map fill (map-fill.md 6)
const TOWER_STAND_MAX := 25.0        ## Wayfinder: stands in a not-own tower's circle at most this long.
const TOWER_WALK_MAX := 60.0         ## ...and walks to it at most this long.
const OATH_POINT_RADIUS := 35.0      ## Oathwall patrol adds own-held wells / towers this close to an own building.
const CLAIM_RADIUS := 7.5            ## A Claim flag's point: the capture point within this of the flag (7 m rule).
const CAMP_START := 1.6              ## Coin-Cutter solos a T1 camp from courage x power x HP >= this x its strength...
const CAMP_KEEP := 0.8               ## ...and keeps at it down to this x.
const CAMP_DETOUR := 2.5             ## Walks pass a camp's aggro zone this far outside it.
const GAME_RADIUS := 15.0            ## R9 idle hunt: a visible game critter this close...
const GAME_DROP := 20.0              ## ...dropped once it is farther than this...
const GAME_GAP := 120.0              ## ...at most one hunt per this many seconds per champion...
const GAME_MAX := 20.0               ## ...and never longer than this.

# Intents (the text of 8.1; the UI colours them).
const I_FALLEN := &"Fallen"
const I_FLEEING := &"Fleeing"
const I_RESTING := &"Resting"
const I_FIGHTING := &"Fighting"
const I_UNPAID := &"Unpaid!"
const I_HUNT := &"Hunting bounty"
const I_SCOUT := &"Scouting bounty"
const I_GUARD := &"Guarding"
const I_ESCORT := &"Escorting"
const I_SHOP := &"Shopping"
const I_EXPLORE := &"Exploring"
const I_PATROL := &"Patrolling"
const I_RAID := &"Raiding"
const I_ARMY := &"With the army"
const I_IDLE := &"Idle"
const I_CAPTURE := &"Capturing"          ## 12.A2: a Wayfinder standing in a tower's circle.
const I_BIG_GAME := &"Hunting big game"  ## 12.A2: the beast hunting party.
const I_GAME := &"Hunting game"          ## 12.A2: the R9 idle hunt of a deer / rabbit.

const WAYFINDER := &"wayfinder"
const OATHWALL := &"oathwall"
const COIN_CUTTER := &"coin_cutter"
const MENDER := &"mender"
# class ids (ChampionClass.IDS)
const SPEAR := &"spear"
const SWORD_SHIELD := &"sword_shield"
const TWO_HAND := &"two_hand"
const WIZARD_CLASS := &"wizard"
## Used when the ChampionType lacks a field (numbers of champions.md 4.1 / 4.2).
const DEFAULTS := {
	WAYFINDER: {"greed": 1.0, "courage": 0.9, "engage_radius": 10.0, "hunt": 0.6, "explore": 2.0,
			"guard": 0.3, "escort": 0.5, "flee_pct": 0.40},
	OATHWALL: {"greed": 0.8, "courage": 1.6, "engage_radius": 20.0, "hunt": 0.7, "explore": 0.2,
			"guard": 2.0, "escort": 1.0, "flee_pct": 0.20},
	COIN_CUTTER: {"greed": 1.5, "courage": 0.8, "engage_radius": 8.0, "hunt": 1.8, "explore": 0.6,
			"guard": 0.3, "escort": 0.3, "flee_pct": 0.35},
	MENDER: {"greed": 0.9, "courage": 0.7, "engage_radius": 9.0, "hunt": 0.4, "explore": 0.3,
			"guard": 0.8, "escort": 2.0, "flee_pct": 0.45},
}
const KIND_NAMES := ["HUNT", "EXPLORE", "GUARD", "ESCORT"]
const AFFINITY_KEYS := ["hunt", "explore", "guard", "escort"]

@export var enabled := true          ## False: no automatic ticks (tests call think_now()).
@export var debug_log := false
@export var idle_hunt_enabled := true   ## 12.A2 R9 idle hunt (Wayfinder, Coin-Cutter); tests may switch it off.

## Perf counters (read only): microseconds spent in automatic ticks by every brain, and the tick count.
static var usec_total := 0
static var ticks := 0
static var _slots := 0

var champion: Unit = null            ## The parent (a Champion). Read only.
var sense: ChampionSense = null      ## The team's knowledge. Read only.
var archetype: StringName = &""      ## wayfinder / oathwall / coin_cutter / mender. Read only.
var plan: Plan = Plan.NONE           ## Read only: what R6-R9 chose.
var current_flag: Variant = null     ## Read only: the bounty it pursues (or null).
var fleeing := false                 ## Read only.
var resting := false                 ## Read only.
var last_detour_at := -INF           ## Read only: sense time of the last shopping detour.
var purchases: Array[String] = []    ## Read only: item ids bought, in order.
var potions_drunk := 0               ## Read only.
var strides_used := 0                ## Read only.
var log_lines: Array[String] = []    ## Read only: the last decisions (debug).

var _now := 0.0
var _fast_left := 0.0
var _plan_left := 0.0
var _replan := true
var _seen_bounty_version := -1
var _seen_looter_version := 0    ## 10.A3: ChampionSense.looter_version at this brain's last plan (Coin-Cutter only).
var _was_dead := false
var _rng := RandomNumberGenerator.new()
# kinds of the Bounty script (resolved once)
var _kinds: Array[int] = [0, 1, 2, 3]
var _kinds_script: Script = null
# R2
var _rest_spot: Dictionary = {}
var _flee_since := 0.0
var _rest_since := 0.0
var _flee_block_until := -INF
var _rest_shopped := false
# R3
var _potion_until := -INF
# R4
var _fight_target: Variant = null
var _fight_last := -INF
var _fight_ally: Variant = null
var _fight_ordered := false          # the current orders come from R4
var _unpaid_now := false             # R5 holds this tick: default intents read `Unpaid!`
# plans
var _plan_node: Variant = null       # shop / building / worker / cache / unit being followed
var _plan_point := Vector3.INF
var _plan_since := 0.0
var _guard_point := Vector3.INF
var _guard_point_at := -INF
var _explore_goal := Vector3.INF
var _explore_since := 0.0
var _explore_is_patrol := false      # the goal is a cache / tavern patrol spot (map known)
var _patrol_spot_index := 0
var _patrol_next_at := -INF
var _idle_next_at := -INF
var _stale_workers := {}             # instance id -> sense time of the sighting already checked
var _ignored_caches := {}            # instance id -> sense time until which it is skipped
var _cache_arrived_at := -INF
var _wish_index := 0                 # fallback wish-list progress (inventories without the helper)
# 12.A2
var _explore_tower: Node3D = null    # the own-bank tower the patrol goal stands at (Wayfinder)
var _tower_since := -INF             # when it started standing in that tower's circle
var _tower_standing := false         # standing in a tower's circle this tick
var _patrol_looping := false         # the Wayfinder is on its map-known patrol loop
var _game_since := -INF
var _game_next_at := -INF            # R9 idle hunt: no new hunt before this sense time
var hunts_started := 0               ## Read only: R9 idle hunts started (tests, debug).
# orders
var _order: Order = Order.NONE
var _order_point := Vector3.INF
var _order_target: Variant = null
var _order_at := -INF
var _arrive_fired := true
# trait cache (per ChampionType instance)
var _traits_type: Object = null
var _traits_cache := {}
# intent cache
var _intent: StringName = &""
var _intent_target: Variant = null


func _ready() -> void:
	champion = get_parent() as Unit
	_rng.randomize()
	var slot := _slots
	_slots += 1
	_fast_left = STAGGER * float(slot % STAGGER_SLOTS)
	_plan_left = 0.0
	if champion and champion.has_signal(&"damage_taken"):
		champion.damage_taken.connect(_on_damage_taken)
	_resolve_archetype()


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_fast_left -= delta
	_plan_left -= delta
	if _fast_left > 0.0:
		return
	_fast_left += FAST_TICK
	if _fast_left < 0.0:
		_fast_left = FAST_TICK
	var t0 := Time.get_ticks_usec()
	_tick()
	usec_total += Time.get_ticks_usec() - t0
	ticks += 1


# ---------------------------------------------------------------- public (UI, tests, debug)

## Runs one 0.5 s tick now; `force_plan` also re-plans R6-R9 (tests, debug).
func think_now(force_plan: bool = true) -> void:
	if force_plan:
		_replan = true
	_tick()


## The flag R6 would pursue now (hysteresis included), or null. No side effect.
func choose_flag() -> Variant:
	if not _ensure_sense():
		return null
	var best: Variant = null
	var best_u := 0.0
	for b: Variant in sense.bounties:
		if not _flag_ok(b):
			continue
		var u := flag_utility(b)
		if u > best_u:
			best_u = u
			best = b
	if _flag_ok(current_flag):
		var cur_u := flag_utility(current_flag)
		if best != null and best != current_flag and best_u >= SWITCH_RATIO * cur_u:
			return best
		return current_flag
	return best if best_u >= threshold() else null


## 8.2 utility of bounty `b` for this champion (0 when it may not go there).
func flag_utility(b: Variant) -> float:
	if not _flag_ok(b) or not _ensure_sense():
		return 0.0
	var node := b as Node3D
	var kind := _kind_index(node)
	if kind < 0:
		return 0.0
	var others := 0
	var pursuers: Variant = node.call(&"active_pursuers") if node.has_method(&"active_pursuers") \
			else node.get(&"pursuers")
	if pursuers is Array:
		for p: Variant in pursuers:
			if p != champion and p != null and is_instance_valid(p):
				others += 1
	var stake := float(node.get(&"stake")) if node.get(&"stake") != null else 0.0
	var s := stake / float(1 + others)
	var g := _trait("greed", 1.0)
	var a := _trait(AFFINITY_KEYS[kind], 1.0)
	var pos := _flag_point(node, kind)
	var target: Variant = node.get(&"target")
	var target_ok: bool = target != null and is_instance_valid(target)
	var home_leash := _trait("home_leash", LEASH_HOME if archetype == OATHWALL else 0.0)
	if home_leash > 0.0 and sense.dist_to_own_building(pos) > home_leash:
		a *= _trait("home_leash_mult", LEASH_FACTOR)
	if kind == 0 and target_ok and (_is_worker(target) or (target as Node).is_in_group(&"champions")):
		a *= _trait("hunt_priority_mult", CUTTER_PREY if archetype == COIN_CUTTER else 1.0)
	if kind == 3 and target_ok and _is_wizard(target):
		a *= _trait("escort_wizard_mult", MENDER_WIZARD if archetype == MENDER else 1.0)
	if _fears_structures() and sense.near_structure(pos, _fear_radius()):
		return 0.0
	var d := _flat(champion.global_position - pos) * DIST_MULT
	var dist_f := DIST_K / (DIST_K + d)
	var hp := _hp_ratio()
	var danger := sense.danger_at(pos, ChampionSense.DANGER_RADIUS, _wizard_mult())
	var cp := _trait("courage", 1.0) * _power() * hp
	var r := 1.0 if danger <= cp else maxf(RISK_MIN, cp / danger)
	var h := maxf(HEALTH_MIN, hp)
	return s * g * a * dist_f * r * h


## The take threshold (ChampionType.bounty_threshold, 10).
func threshold() -> float:
	var t := _type()
	if t and t.get(&"bounty_threshold") != null and float(t.get(&"bounty_threshold")) > 0.0:
		return float(t.get(&"bounty_threshold"))
	return DEFAULT_THRESHOLD


## Flee threshold as a ratio: Champion.flee_pct (it already holds the class delta, skills-rework.md 3: a Sword and
## Shield Oathwall reads 0.15), else ChampionType.flee_pct; 0.35 or 35 both read as 35 %.
func flee_ratio() -> float:
	var v: Variant = champion.get(&"flee_pct") if champion else null
	if v == null:
		var t := _type()
		v = t.get(&"flee_pct") if t else null
	var f := float(v) if v != null else float((DEFAULTS.get(archetype, {}) as Dictionary).get("flee_pct", 0.3))
	return f / 100.0 if f > 1.0 else f


## The champion's class id (&"spear", &"sword_shield", &"two_hand", &"wizard"), &"" before its level-2 draw.
func class_id() -> StringName:
	if champion and champion.has_method(&"class_id"):
		return StringName(champion.call(&"class_id"))
	return &""


## 11.A1 stance: true = back line (Champion.is_ranged(): the Wizard class, or a ranged archetype before its
## class); false = a melee fighter that closes in through R4.
func is_back_line() -> bool:
	if champion == null:
		return false
	if champion.has_method(&"is_ranged"):
		return bool(champion.call(&"is_ranged"))
	var t := _type()
	var r: Variant = t.get(&"attack_range") if t else null
	return (float(r) if r != null else champion.attack_range) > RANGED_REACH


## 12.A2 hunting party: true when this champion is free for a beast hunt (R8 / R9: alive, not fleeing, no flag, not
## shopping); `starting` (joining a new hunt) also needs HP >= 70 % and no other fight. ChampionSense asks.
func party_free(starting: bool) -> bool:
	if champion == null or not is_instance_valid(champion) or not champion.is_alive():
		return false
	if fleeing or resting or current_flag != null or plan == Plan.SHOP or plan == Plan.FLAG:
		return false
	if starting:
		if _hp_ratio() < ChampionSense.PARTY_HP:
			return false
		if plan != Plan.BEAST and _fight_target != null and is_instance_valid(_fight_target) \
				and not (_fight_target as Node).is_in_group(&"beasts"):
			return false
	return true


## 12.A2 hunting party: courage x power (not scaled by HP), summed by ChampionSense.
func party_power() -> float:
	if champion == null or not is_instance_valid(champion):
		return 0.0
	return _trait("courage", 1.0) * _power()


## 12.A2: the Oathwall's patrol stops now (own completed buildings + own-held wells / towers within 35 m of one).
func patrol_stops() -> Array:
	var out: Array = []
	if not _ensure_sense():
		return out
	for e: Dictionary in _patrol_entries():
		out.append(e["node"])
	return out


## Where R6-R9 last sent the champion (INF = nowhere), for tests and debug.
func plan_goal() -> Vector3:
	return _order_point if _order != Order.ATTACK else Vector3.INF


## The node of the current plan (shop, building, worker, cache, unit followed) or null.
func plan_node() -> Variant:
	return _plan_node if _plan_node != null and is_instance_valid(_plan_node) else null


## The Wayfinder's next explore point (8.3), INF when every point scores nothing. No side effect.
func explore_goal() -> Vector3:
	if not _ensure_sense():
		return Vector3.INF
	var me := champion.global_position
	var cp := _trait("courage", 1.0) * _power() * _hp_ratio()
	var fear := _fears_structures()
	var fear_r := _fear_radius()
	var home := sense.home_point
	var best := Vector3.INF
	var best_s := -INF
	var a0 := _rng.randf() * TAU / float(EXPLORE_SAMPLES)
	for i in EXPLORE_SAMPLES:
		var a := a0 + TAU * float(i) / float(EXPLORE_SAMPLES)
		var p := Vector3(me.x + cos(a) * EXPLORE_RING, 0.0, me.z + sin(a) * EXPLORE_RING)
		if absf(p.x) > MAP_LIMIT or absf(p.z) > MAP_LIMIT:
			continue
		var st := sense.state_at(p)
		if st == FogOfWar.VISIBLE:
			continue
		if fear and sense.near_structure(p, fear_r):
			continue
		if sense.danger_at(p) > cp:
			continue
		if not sense.camp_zone_at(p).is_empty():
			continue   # 12.A2: never into a camp's aggro
		var score := (2.0 if st == FogOfWar.UNEXPLORED else 1.0) + _flat(p - home) / EXPLORE_KEEP_DIV
		if score > best_s:
			best_s = score
			best = p
	return best


# ---------------------------------------------------------------- the tick

func _tick() -> void:
	if champion == null or not is_instance_valid(champion) or not _ensure_sense():
		return
	_now = sense.now
	_unpaid_now = false
	if archetype == &"":
		_resolve_archetype()
	# R1
	if not champion.is_alive():
		_rule_fallen()
		return
	if _was_dead:
		_was_dead = false
		_reset_orders()
		_replan = true
	var hp := _hp_ratio()
	# R2
	if _rule_flee(hp):
		_drop_game()
		return
	# R3 (never stops the other rules)
	_rule_potion(hp)
	# R4
	if _rule_fight(hp):
		_drop_game()
		return
	# R5
	var unpaid := _is_unpaid()
	_unpaid_now = unpaid
	if unpaid and current_flag != null:
		_drop_flag()
		_replan = true
	# R6-R9 (10.A3: a Coin-Cutter re-plans at once when a looting Magpie comes into view, its Raid default's first
	# choice; at the 2 s plan tick it could already have walked out of sight of it)
	var new_looter := archetype == COIN_CUTTER and sense.looter_version != _seen_looter_version
	if _replan or _plan_left <= 0.0 or sense.bounty_version != _seen_bounty_version or new_looter or _arrived():
		_replan = false
		_plan_left = PLAN_TICK
		_seen_bounty_version = sense.bounty_version
		_seen_looter_version = sense.looter_version
		_choose_plan(unpaid)
	_execute_plan()


func _ensure_sense() -> bool:
	if champion == null or not is_instance_valid(champion):
		return false
	if sense == null or not is_instance_valid(sense) or sense.team != int(champion.team):
		sense = ChampionSense.for_team(int(champion.team))
	return sense != null


func _on_damage_taken(_amount: float, _attacker: Node3D) -> void:
	if _intent != I_FIGHTING:
		_replan = true


# ---------------------------------------------------------------- R1

func _rule_fallen() -> void:
	if not _was_dead:
		_was_dead = true
		_drop_flag()
		fleeing = false
		resting = false
		_fight_target = null
		plan = Plan.NONE
		_plan_node = null
		_reset_orders()
		_log("FALLEN")
	var left := _revive_time_left()
	if left > 0.0:
		_set_intent(StringName("Returns in %d s" % ceili(left)))
	else:
		_set_intent(I_FALLEN)


func _revive_time_left() -> float:
	for g in get_tree().get_nodes_in_group(&"champion_guilds"):
		if g.get(&"team") != null and int(g.get(&"team")) == int(champion.team) \
				and g.has_method(&"revive_time_left"):
			return float(g.call(&"revive_time_left", champion))
	return 0.0


# ---------------------------------------------------------------- R2 flee / rest

func _rule_flee(hp: float) -> bool:
	if not fleeing:
		if hp >= flee_ratio() or _now < _flee_block_until:
			return false
		var spot := _pick_rest_spot()
		if spot.is_empty():
			return false
		fleeing = true
		resting = false
		_rest_shopped = false
		_flee_since = _now
		_rest_spot = spot
		_fight_target = null
		_log("FLEE at %d %% to %s" % [roundi(hp * 100.0), str(spot["center"])])
		_use_stride()
	var done := hp >= REST_HP
	if not done and resting and _now - _rest_since >= REST_MAX:
		done = true
		_flee_block_until = _now + FLEE_RETRY
	if not done and not resting and _now - _flee_since >= FLEE_TRAVEL_MAX:
		done = true
		_flee_block_until = _now + FLEE_RETRY
	if done:
		_log("REST over at %d %%" % roundi(hp * 100.0))
		fleeing = false
		resting = false
		_rest_spot = {}
		_reset_orders()
		_replan = true
		return false
	if not _rest_spot_ok(_rest_spot):
		var again := _pick_rest_spot()
		if again.is_empty():
			fleeing = false
			resting = false
			_replan = true
			return false
		_rest_spot = again
	var me := champion.global_position
	var center: Vector3 = _rest_spot["center"]
	var in_rest := _flat(me - center) <= float(_rest_spot["arrive"])
	if in_rest and not resting:
		resting = true
		_rest_since = _now
		_log("RESTING")
	if resting and not _rest_shopped and _rest_shop_step():
		return true
	if in_rest:
		_set_intent(I_RESTING, _rest_spot["node"])
	else:
		_order_move(_rest_spot["point"], false)   # a plain walk: no fighting on the way
		_set_intent(I_RESTING if resting else I_FLEEING, _rest_spot["node"])
	return true


## The nearest rest spot: an own completed keep / barracks (rest within 15 m) or a tavern door that is
## not held by the enemy (rest within 8 m). {} if none.
func _pick_rest_spot() -> Dictionary:
	var me := champion.global_position
	var best: Dictionary = {}
	var best_d := INF
	for b: Dictionary in sense.own_buildings:
		if (b["kind"] != &"keep" and b["kind"] != &"barracks") or not is_instance_valid(b["node"]):
			continue
		var c: Vector3 = b["pos"]
		var d := _flat(me - c)
		if d < best_d:
			best_d = d
			var dir := _dir_flat(me - c, Vector3(1.0, 0.0, 0.0))
			best = {"node": b["node"], "center": c, "point": c + dir * (float(b["radius"]) + 3.0),
					"arrive": REST_BUILDING_RADIUS, "tavern": false}
	for tv: Dictionary in sense.taverns:
		if bool(tv["held"]):
			continue
		var door: Vector3 = tv["door"]
		var d := _flat(me - door)
		if d < best_d:
			best_d = d
			best = {"node": tv["node"], "center": door, "point": door, "arrive": TAVERN_REST_RADIUS,
					"tavern": true}
	return best


func _rest_spot_ok(spot: Dictionary) -> bool:
	if spot.is_empty():
		return false
	var node: Variant = spot["node"]
	if node == null or not is_instance_valid(node):
		return false
	if (node as Node).has_method(&"is_alive") and not bool((node as Node).call(&"is_alive")):
		return false
	if bool(spot["tavern"]):
		for tv: Dictionary in sense.taverns:
			if tv["node"] == node:
				return not bool(tv["held"])
	return true


## While resting: walk to a shop within 20 m and buy what the purse allows. True while walking there.
func _rest_shop_step() -> bool:
	var price := _next_price()
	if price <= 0 or _purse() < price:
		return false
	var shop := _nearest_shop(REST_SHOP_RADIUS)
	if shop == null:
		_rest_shopped = true
		return false
	if _flat(champion.global_position - shop.global_position) <= SHOP_BUY_DIST:
		_buy_all()
		_rest_shopped = true
		return false
	_order_move(_shop_point(shop), false)
	_set_intent(I_SHOP, shop)
	return true


# ---------------------------------------------------------------- R3 potion

func _rule_potion(hp: float) -> void:
	if hp >= POTION_HP or _now < _potion_until:
		return
	var inv := _inventory()
	if inv == null or ItemActives.check_by_id(inv, DRAUGHT_ID) != "":
		return
	if ItemActives.drink_potion(inv) == "":
		_potion_until = _now + POTION_TIME
		potions_drunk += 1
		_log("POTION at %d %%" % roundi(hp * 100.0))


func _use_stride() -> void:
	var inv := _inventory()
	if inv == null or ItemActives.check_by_id(inv, STRIDE_ID) != "":
		return
	if ItemActives.use_stride(inv) == "":
		strides_used += 1
		_log("STRIDE")


# ---------------------------------------------------------------- R4 fight

func _rule_fight(hp: float) -> bool:
	var me := champion.global_position
	var cp := _trait("courage", 1.0) * _power() * hp * JOIN_DANGER_MULT
	var trigger := Vector3.INF
	var attackers: Array = []
	var ally: Variant = null
	# a) it was hit in the last 2 s
	if champion.seconds_since_damage() < HIT_WINDOW:
		for e: Dictionary in sense.enemies:
			if e["target"] == champion:
				attackers.append(e)
		if attackers.is_empty():
			var near := sense.nearest_enemy(me, maxf(champion.aggro_range, DEFAULT_ENGAGE))
			if not near.is_empty():
				attackers.append(near)
		if not attackers.is_empty():
			trigger = me
	# b) an own unit / building within the engage radius hit in the last 2 s by a visible enemy
	if trigger == Vector3.INF:
		var best_d := INF
		for h: Dictionary in sense.hits:
			if h["node"] == champion:
				continue
			var p: Vector3 = h["pos"]
			var d := _flat(me - p)
			if d <= _engage_radius_for(h) and d < best_d:
				best_d = d
				trigger = p
				attackers = h["attackers"]
				ally = h["node"]
	if trigger != Vector3.INF and sense.danger_at(trigger, ChampionSense.DANGER_RADIUS, _wizard_mult()) <= cp:
		var target: Variant = _pick_fight_target(attackers, trigger)
		if target != null:
			if target != _fight_target:
				_log("FIGHT %s" % (target as Node).name)
			_fight_target = target
			_fight_last = _now
			_fight_ally = ally
	# the fight goes on while the target is alive, seen and the last trigger is recent
	if _fight_target != null and (not is_instance_valid(_fight_target) or _now - _fight_last > FIGHT_HOLD
			or not (_fight_target as Node).call(&"is_alive") or not sense.knows(_fight_target)
			or (_leashed() and sense.dist_to_own_building((_fight_target as Node3D).global_position) > _chase_leash())):
		_fight_target = null
		_fight_ally = null
	if _fight_target == null:
		if _fight_ordered:
			_fight_ordered = false
			_reset_orders()
			_replan = true
		return false
	_fight_ordered = true
	if archetype == MENDER and is_back_line():
		_mender_keep_distance()
	else:
		_order_attack(_fight_target)
	_set_intent(I_FIGHTING, _fight_target)
	return true


## Engage radius for a hit own thing: the trait (Oathwall 20, only around own buildings, else 10).
func _engage_radius_for(h: Dictionary) -> float:
	var r := _trait("engage_radius", DEFAULT_ENGAGE)
	if _trait("engage_around_buildings", 1.0 if archetype == OATHWALL else 0.0) > 0.0 \
			and r > DEFAULT_ENGAGE and not bool(h["building"]) \
			and sense.dist_to_own_building(h["pos"]) > OATH_HOME_RADIUS:
		r = DEFAULT_ENGAGE
	return r


## skills-rework.md 6 (R4 target preference; lowest score wins). The archetype rule first where there is one:
## Coin-Cutter workers first, then the lowest HP % (its rule decides alone); Oathwall the enemy hitting an own
## building or the wizard (a tier of ARCH_TIER). Inside that, or for the Wayfinder / Mender, the class rule:
## Spear enemy ranged units and casters first; Sword and Shield the enemy attacking an ally (not itself);
## Two-Hand the enemy with the most enemies within 2.5 m; Wizard the enemy attacking the most hurt own unit or
## building (itself included); no class (or no match): the nearest. Candidates: the attackers and the visible
## enemies near the fight (ChampionSense: the team's fog only).
func _pick_fight_target(attackers: Array, at: Vector3) -> Variant:
	var cands: Array[Dictionary] = []
	for e: Variant in attackers:
		cands.append(e)
	var r := _trait("engage_radius", DEFAULT_ENGAGE) + 4.0
	for e: Dictionary in sense.enemies:
		var p: Vector3 = e["pos"]
		if _flat(p - at) <= r and not cands.has(e):
			cands.append(e)
	var me := champion.global_position
	var cls := class_id() if archetype != COIN_CUTTER else &""
	var crowd := PackedVector3Array()
	if cls == TWO_HAND:
		for e: Dictionary in cands:   # the neighbours that count: the visible enemies around this fight
			crowd.append(e["pos"])
	var best: Variant = null
	var best_score := INF
	for e: Dictionary in cands:
		var n: Variant = e["node"]
		if n == null or not is_instance_valid(n) or not (n as Node).call(&"is_alive"):
			continue
		var p: Vector3 = e["pos"]
		if _leashed() and sense.dist_to_own_building(p) > _chase_leash():
			continue
		var d := _flat(me - p)
		var score := d
		match archetype:
			COIN_CUTTER:
				score = (0.0 if bool(e["worker"]) else 10.0) + float(e["hp_ratio"])
			OATHWALL:
				var t: Variant = e["target"]
				var home_hit: bool = t != null and is_instance_valid(t) and (t is Building or _is_wizard(t)) \
						and (t as Node).get(&"team") != null and int((t as Node).get(&"team")) == int(champion.team)
				score = _class_score(e, d, cls, crowd) + (0.0 if home_hit else ARCH_TIER)
			_:
				score = _class_score(e, d, cls, crowd)
		if score < best_score:
			best_score = score
			best = n
	return best


## The class part of the target score (0 .. < ARCH_TIER, lower = better); `d` = distance to the enemy.
func _class_score(e: Dictionary, d: float, cls: StringName, crowd: PackedVector3Array) -> float:
	var dd := minf(d, CLASS_TIER - 1.0)
	match cls:
		SPEAR:
			return (0.0 if _is_ranged_or_caster(e) else CLASS_TIER) + dd
		SWORD_SHIELD:
			var t: Variant = e["target"]
			var on_ally: bool = t != champion and _is_own(t)
			return (0.0 if on_ally else CLASS_TIER) + dd
		TWO_HAND:
			var p: Vector3 = e["pos"]
			var r2 := CLEAVE_RADIUS * CLEAVE_RADIUS
			var n := -1   # the candidate itself is in `crowd`
			for q: Vector3 in crowd:
				if (q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z) <= r2:
					n += 1
			return float(CROWD_MAX - clampi(n, 0, CROWD_MAX)) * CLASS_TIER + dd
		WIZARD_CLASS:
			var t: Variant = e["target"]
			if _is_own(t):
				# the most hurt victim first; distance only breaks exact ties
				return _node_hp_ratio(t) * CLASS_TIER + dd * 0.001
			return 2.0 * CLASS_TIER + dd
	return dd


## An enemy that shoots (reach over 3 m), a support caster or a wizard (ChampionAbilities' "ranged or caster").
func _is_ranged_or_caster(e: Dictionary) -> bool:
	if not bool(e["melee"]) or bool(e["hero"]):
		return true
	var n: Variant = e["node"]
	return n != null and is_instance_valid(n) and ((n as Node).get(&"support_caster") != null or _is_wizard(n))


## A living node of the champion's own team (unit or building).
func _is_own(t: Variant) -> bool:
	if t == null or not is_instance_valid(t) or not t is Node:
		return false
	var team: Variant = (t as Node).get(&"team")
	return team != null and int(team) == int(champion.team)


static func _node_hp_ratio(t: Variant) -> float:
	var hp: Variant = (t as Node).get(&"hp")
	var mx: Variant = (t as Node).get(&"max_hp")
	if hp == null or mx == null:
		return 1.0
	return clampf(float(hp) / maxf(float(mx), 1.0), 0.0, 1.0)


## Mender in a fight: stays 4 m behind the ally, on the side away from the nearest seen enemy.
func _mender_keep_distance() -> void:
	var enemy_pos := (_fight_target as Node3D).global_position
	var anchor: Vector3 = champion.global_position
	if _fight_ally != null and is_instance_valid(_fight_ally):
		anchor = (_fight_ally as Node3D).global_position
	else:
		var best_d := INF
		for u: Variant in sense.own_soldiers + sense.own_champions:
			if u == champion or not is_instance_valid(u):
				continue
			var d := _flat((u as Node3D).global_position - enemy_pos)
			if d < best_d:
				best_d = d
				anchor = (u as Node3D).global_position
	var point := anchor + _dir_flat(anchor - enemy_pos, Vector3(1.0, 0.0, 0.0)) * _trait("keep_behind", MENDER_BEHIND)
	if _flat(champion.global_position - point) > ARRIVE:
		_order_move(point, false)


# ---------------------------------------------------------------- R6-R9 planning

func _choose_plan(unpaid: bool) -> void:
	# R6 bounty
	var flag: Variant = null if unpaid else choose_flag()
	if flag != current_flag:
		if flag == null:
			_drop_flag()
		else:
			_take_flag(flag)
	if current_flag != null:
		_set_plan(Plan.FLAG, current_flag)
		return
	# R7 shopping (a detour in progress goes on)
	if plan == Plan.SHOP and plan_node() != null and _now - _plan_since < SHOP_TIMEOUT:
		return
	var shop := _shop_detour()
	if shop != null:
		last_detour_at = _now
		_set_plan(Plan.SHOP, shop)
		_log("SHOP detour to %s (purse %d)" % [shop.name, _purse()])
		return
	# R8 (12.A2) the beast hunting party comes before the personality default
	var prey := sense.party_target(champion)
	if prey != null:
		if plan != Plan.BEAST or plan_node() != prey:
			_log("PARTY hunts %s" % prey.name)
		_set_plan(Plan.BEAST, prey)
		return
	var game: Variant = plan_node() if plan == Plan.GAME and _game_ok(plan_node()) else null
	# R8 personality default, R9 idle
	match archetype:
		WAYFINDER:
			_set_plan(Plan.EXPLORE, null)
		OATHWALL:
			if sense.own_buildings.is_empty():
				_set_plan(Plan.IDLE, null)
			else:
				_set_plan(Plan.PATROL, plan_node() if plan == Plan.PATROL else null)
		COIN_CUTTER:
			_choose_raid()
		MENDER:
			_choose_follow()
		_:
			_set_plan(Plan.IDLE, null)
	# R9 (12.A2) idle hunt
	_choose_idle_hunt(game)


func _set_plan(p: Plan, node: Variant) -> void:
	if p != plan or node != _plan_node:
		_plan_since = _now
		if p != plan:
			_log("PLAN %s" % Plan.keys()[p])
	plan = p
	_plan_node = node


func _execute_plan() -> void:
	match plan:
		Plan.FLAG:
			if not _flag_ok(current_flag):
				_drop_flag()
				_replan = true
				_set_plan(Plan.IDLE, null)
				_exec_idle()
			else:
				_exec_flag()
			return
		Plan.SHOP:
			_exec_shop()
			return
		Plan.EXPLORE:
			_exec_explore()
		Plan.PATROL:
			_exec_patrol()
		Plan.RAID:
			_exec_raid()
		Plan.CACHE:
			_exec_cache()
		Plan.LURK:
			_exec_lurk()
		Plan.FOLLOW:
			_exec_follow()
		Plan.HOME:
			_exec_home()
		Plan.CAMP:
			_exec_camp()
		Plan.BEAST:
			_exec_beast()
		Plan.GAME:
			_exec_game()
		_:
			_exec_idle()


# ---------------------------------------------------------------- R6 flags

func _flag_ok(b: Variant) -> bool:
	if b == null or not is_instance_valid(b) or not b is Node3D:
		return false
	var n := b as Node3D
	if n.is_queued_for_deletion() or not n.is_inside_tree():
		return false
	var t: Variant = n.get(&"team")
	if t == null or int(t) != int(champion.team):
		return false
	return not n.has_method(&"is_valid") or bool(n.call(&"is_valid"))


func _take_flag(b: Variant) -> void:
	_drop_flag()
	current_flag = b
	if (b as Node).has_method(&"add_pursuer"):
		(b as Node).call(&"add_pursuer", champion)
	_guard_point = Vector3.INF
	_log("TAKE bounty %s (U %.1f)" % [(b as Node).name, flag_utility(b)])


func _drop_flag() -> void:
	if current_flag != null and is_instance_valid(current_flag) and (current_flag as Node).has_method(&"remove_pursuer"):
		(current_flag as Node).call(&"remove_pursuer", champion)
	current_flag = null


## 0 Hunt, 1 Explore, 2 Guard, 3 Escort (the Bounty script's HUNT... constants when it has them); -1.
func _kind_index(b: Node) -> int:
	var k: Variant = b.get(&"kind")
	if k == null:
		return -1
	var s := b.get_script() as Script
	if s != null and s != _kinds_script:
		_kinds_script = s
		_kinds = [0, 1, 2, 3]
		var consts := s.get_script_constant_map()
		for i in KIND_NAMES.size():
			var kname: String = KIND_NAMES[i]
			if consts.has(kname):
				_kinds[i] = int(consts[kname])
			else:
				for v: Variant in consts.values():
					if v is Dictionary and (v as Dictionary).has(kname):
						_kinds[i] = int((v as Dictionary)[kname])
	return _kinds.find(int(k))


## Where the flag is: a Hunt target while it is seen (else the flag's last-seen spot), the guarded
## building / escorted unit, the Explore point.
func _flag_point(b: Node3D, kind: int) -> Vector3:
	var t: Variant = b.get(&"target")
	if kind != 1 and t != null and is_instance_valid(t) and t is Node3D:
		if kind != 0 or sense.knows(t):
			return (t as Node3D).global_position
	return b.global_position


func _exec_flag() -> void:
	var b := current_flag as Node3D
	var kind := _kind_index(b)
	var t: Variant = b.get(&"target")
	var target_ok: bool = t != null and is_instance_valid(t) and t is Node3D \
			and (not (t as Node).has_method(&"is_alive") or bool((t as Node).call(&"is_alive")))
	match kind:
		0:   # Hunt
			if target_ok and sense.knows(t):
				_order_attack(t)
			else:
				_order_move(b.global_position, true)
			_set_intent(I_HUNT, b)
		1:   # Explore (12.A2: a Claim stands in the point's capture circle until it is captured)
			var pt := claim_point(b)
			if pt != null:
				_order_move(_stand_point(pt, _point_stand(pt)), false)
			else:
				_order_move(b.global_position, false)
			_set_intent(I_SCOUT, b)
		2:   # Guard: patrol within 14 m of the building
			var center: Vector3 = (t as Node3D).global_position if target_ok else b.global_position
			var reach := Unit.radius_of(t as Node3D) if target_ok else 2.0
			if _guard_point == Vector3.INF or _now - _guard_point_at >= GUARD_POINT_TIME \
					or _flat(champion.global_position - _guard_point) <= ARRIVE \
					or _flat(_guard_point - center) > GUARD_RADIUS:
				var a := _rng.randf() * TAU
				var r := minf(reach + _rng.randf_range(2.0, 6.0), GUARD_RADIUS - 2.0)
				_guard_point = center + Vector3(cos(a), 0.0, sin(a)) * r
				_guard_point_at = _now
			_order_move(_guard_point, true)
			_set_intent(I_GUARD, b)
		3:   # Escort: 4 m behind the unit
			if target_ok:
				var point := _behind((t as Node3D), ESCORT_BEHIND)
				if _flat(champion.global_position - point) > ARRIVE:
					_order_move(point, true)
			else:
				_order_move(b.global_position, true)
			_set_intent(I_ESCORT, b)


## A point `dist` behind `u`: opposite to its walk, else away from the nearest seen enemy, else on our side.
func _behind(u: Node3D, dist: float) -> Vector3:
	var p := u.global_position
	var vel: Variant = u.get(&"velocity")
	if vel is Vector3 and Vector2((vel as Vector3).x, (vel as Vector3).z).length() > 0.5:
		return p - _dir_flat(vel as Vector3, Vector3.BACK) * dist
	var e := sense.nearest_enemy(p, FOLLOW_ENEMY_RADIUS)
	if not e.is_empty():
		return p + _dir_flat(p - (e["pos"] as Vector3), Vector3.BACK) * dist
	return p + _dir_flat(champion.global_position - p, Vector3.BACK) * dist


# ---------------------------------------------------------------- 12.A2 capture points

## The capture point of a Claim flag (an Explore whose `is_claim()` is true, BountyBoard 12.C5), else null: the flag's
## `claim_point()` / `point` if it has one, its target when that is a capture point, else the point within 7.5 m.
func claim_point(b: Variant) -> Node3D:
	if b == null or not is_instance_valid(b) or not b is Node3D:
		return null
	var flag := b as Node3D
	if not flag.has_method(&"is_claim") or not bool(flag.call(&"is_claim")):
		return null
	for m: StringName in [&"claim_point", &"point"]:
		if flag.has_method(m):
			var v: Variant = flag.call(m)
			if v is Node3D and is_instance_valid(v):
				return v as Node3D
	for prop: StringName in [&"claim_point", &"point", &"target"]:
		var v2: Variant = flag.get(prop)
		if v2 is Node3D and is_instance_valid(v2) and (v2 as Node).has_method(&"is_capture_point"):
			return v2 as Node3D
	var best: Node3D = null
	var best_d := CLAIM_RADIUS
	for p: Dictionary in sense.points:
		var d := _flat((p["pos"] as Vector3) - flag.global_position)
		if d <= best_d:
			best_d = d
			best = p["node"]
	return best


## How far from a point's centre a champion stands to capture it (inside the circle, outside the body).
func _point_stand(pt: Node3D) -> float:
	var e := sense.point_entry(pt)
	if not e.is_empty():
		return float(e["stand"])
	var rad: Variant = pt.get(&"capture_radius")
	return maxf(1.0, (float(rad) if rad != null else 6.0) * 0.55)


## The stand spot `dist` from `pt` on the champion's side.
func _stand_point(pt: Node3D, dist: float) -> Vector3:
	var c := pt.global_position
	return c + _dir_flat(champion.global_position - c, _dir_flat(sense.home_point - c, Vector3.BACK)) * dist


## Wayfinder patrol at a tower: while the goal is a not-own tower and it stands inside the circle, it stays (max 25 s,
## `Capturing`). True while standing. Captured / timed out: the next loop spot.
func _tower_step() -> bool:
	_tower_standing = false
	var t := _explore_tower
	if t == null or not is_instance_valid(t) or not _explore_is_patrol:
		_explore_tower = null
		return false
	var e := sense.point_entry(t)
	if e.is_empty():
		return false
	if int(e["owner"]) == int(champion.team):
		if _tower_since != -INF:
			_log("TOWER %s captured" % t.name)
			_explore_goal = Vector3.INF   # next spot of the loop
		_explore_tower = null
		_tower_since = -INF
		return false
	var d := _flat(champion.global_position - (e["pos"] as Vector3))
	if d > float(e["radius"]) - 0.5:
		return false   # still walking there
	if _tower_since == -INF:
		_tower_since = _now
		_log("TOWER %s: capturing" % t.name)
	if _now - _tower_since >= TOWER_STAND_MAX:
		_log("TOWER %s: gave up after %d s" % [t.name, roundi(TOWER_STAND_MAX)])
		_explore_tower = null
		_explore_goal = Vector3.INF
		_tower_since = -INF
		return false
	_tower_standing = true
	_order_move(_stand_point(t, float(e["stand"])), false)
	_set_intent(I_CAPTURE, t)
	return true


## The map-known patrol loop (Wayfinder): Lost Cache spots + tavern doors + the own bank's watchtowers; the loop starts
## at the nearest spot, then goes round. Spots in danger (> courage x power), in a camp's aggro zone or near a known
## tower before L4 are skipped. Sets `_explore_goal` (INF when none).
func _next_patrol_spot() -> void:
	var spots: Array[Vector3] = []
	var towers: Array = []
	for c: Variant in sense.caches:
		if c != null and is_instance_valid(c):
			spots.append((c as Node3D).global_position)
			towers.append(null)
	for tv: Dictionary in sense.taverns:
		spots.append(tv["door"])
		towers.append(null)
	for p: Dictionary in sense.points:
		if p["kind"] == &"watchtower" and int(p["bank"]) == int(champion.team):
			spots.append(_stand_point(p["node"], float(p["stand"])))
			towers.append(p["node"])
	_explore_goal = Vector3.INF
	_explore_tower = null
	_tower_since = -INF
	if spots.is_empty():
		_patrol_looping = false
		return
	var cp := _trait("courage", 1.0) * _power() * _hp_ratio()
	var fear := _fears_structures()
	var fear_r := _fear_radius()
	var ok: Array[bool] = []
	var any := false
	for s: Vector3 in spots:
		var good := sense.danger_at(s, ChampionSense.DANGER_RADIUS) <= cp and sense.camp_zone_at(s).is_empty() \
				and not (fear and sense.near_structure(s, fear_r))
		ok.append(good)
		any = any or good
	if not any:
		_patrol_looping = false
		return
	var pick := -1
	if not _patrol_looping:
		var best_d := INF
		for i in spots.size():
			var d := _flat(champion.global_position - spots[i])
			if ok[i] and d < best_d:
				best_d = d
				pick = i
	else:
		for k in spots.size():
			var i2 := (_patrol_spot_index + 1 + k) % spots.size()
			if ok[i2]:
				pick = i2
				break
	_patrol_spot_index = pick
	_patrol_looping = true
	_explore_goal = spots[pick]
	_explore_is_patrol = true
	var tw: Variant = towers[pick]
	if tw != null and is_instance_valid(tw) and int(sense.point_entry(tw).get("owner", -1)) != int(champion.team):
		_explore_tower = tw as Node3D


## Own-held wells and towers within 35 m of an own building (the Oathwall's patrol adds them).
func _own_points_near_home() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in sense.points:
		if int(p["owner"]) != int(champion.team) or (p["kind"] != &"watchtower" and p["kind"] != &"well"):
			continue
		if sense.dist_to_own_building(p["pos"]) <= OATH_POINT_RADIUS:
			out.append(p)
	return out


## R8 / R9 walks: the goal, or a detour spot beside the first remembered living camp whose aggro zone the straight
## walk would cross ("never paths into a camp's aggro"). `ignore`: a camp it is going to on purpose.
func _safe_step(goal: Vector3, ignore: Variant = null) -> Vector3:
	if goal == Vector3.INF or not _ensure_sense():
		return goal
	var me := champion.global_position
	var c := sense.camp_blocking(me, goal, ignore)
	if c.is_empty():
		return goal
	var center: Vector3 = c["pos"]
	var seg := Vector3(goal.x - me.x, 0.0, goal.z - me.z)
	var dir := seg.normalized()
	var t := (center - me).dot(dir)
	var closest := me + dir * t
	var off := Vector3(closest.x - center.x, 0.0, closest.z - center.z)
	if off.length() < 0.1:
		off = Vector3(-dir.z, 0.0, dir.x)
	var detour := center + off.normalized() * (ChampionSense.CAMP_ZONE + CAMP_DETOUR)
	detour.y = goal.y
	return detour


# ---------------------------------------------------------------- 12.A2 camps, beasts, game

## Coin-Cutter: the nearest T1 camp on its own bank, remembered alive, explored, with courage x power x HP >= 1.6 x its
## strength (0.8 x to keep the current one), or null.
func _camp_to_clear() -> Node3D:
	var cp := _trait("courage", 1.0) * _power() * _hp_ratio()
	var current: Variant = plan_node() if plan == Plan.CAMP else null
	var me := champion.global_position
	var best: Node3D = null
	var best_d := INF
	for c: Dictionary in sense.camps:
		if int(c["tier"]) != 1 or not bool(c["alive"]) or not bool(c["explored"]):
			continue
		var pos: Vector3 = c["pos"]
		if sense.bank_of(pos) != int(champion.team):
			continue
		var need := (CAMP_KEEP if c["node"] == current else CAMP_START) * float(c["strength"])
		if cp < need:
			continue
		var d := _flat(me - pos)
		if d < best_d:
			best_d = d
			best = c["node"]
	return best


func _exec_camp() -> void:
	var camp := plan_node() as Node3D
	var e := sense.camp_entry(camp)
	if camp == null or e.is_empty() or not bool(e["alive"]):
		_log("CAMP done")
		_set_plan(Plan.NONE, null)
		_replan = true
		return
	var target: Node3D = null
	var best := INF
	if camp.has_method(&"creatures"):
		for u: Variant in camp.call(&"creatures"):
			if u == null or not is_instance_valid(u) or not sense.knows(u):
				continue
			var r := _node_hp_ratio(u)
			if r < best:
				best = r
				target = u as Node3D
	if target != null:
		_order_attack(target)
	else:
		_order_move(e["pos"], true)
	_set_intent(I_RAID, target if target != null else camp)


func _exec_beast() -> void:
	var b := plan_node() as Node3D
	if b == null or not bool(b.call(&"is_alive")) or sense.party_target(champion) != b:
		_log("PARTY over")
		_set_plan(Plan.NONE, null)
		_replan = true
		return
	if sense.knows(b):
		_order_attack(b)
	else:
		var e := sense.beast_entry(b)
		_order_move(e.get("pos", b.global_position), true)
	_set_intent(I_BIG_GAME, b)


## R9 idle hunt: Wayfinder and Coin-Cutter on their routine (explore / lurk / idle / home, not standing at a tower).
func _choose_idle_hunt(current: Variant) -> void:
	if not idle_hunt_enabled or (archetype != WAYFINDER and archetype != COIN_CUTTER):
		return
	if not (plan == Plan.EXPLORE or plan == Plan.LURK or plan == Plan.IDLE or plan == Plan.HOME) or _tower_standing:
		return
	if current != null:
		_set_plan(Plan.GAME, current)   # a hunt in progress goes on
		return
	if _now < _game_next_at:
		return
	var me := champion.global_position
	var best: Node3D = null
	var best_s := INF
	for c: Dictionary in sense.critters:
		var d := _flat(me - (c["pos"] as Vector3))
		if d > GAME_RADIUS:
			continue
		var s := d + (0.0 if c["kind"] == &"deer" else GAME_RADIUS)   # deer first
		if s < best_s:
			best_s = s
			best = c["node"]
	if best == null:
		return
	_game_since = _now
	if not _game_ok(best):
		return
	_game_next_at = _now + GAME_GAP
	hunts_started += 1
	_log("GAME hunt %s" % best.name)
	_set_plan(Plan.GAME, best)


## A hunted critter is still worth it: alive, visible to the team, within 20 m, the hunt younger than 20 s.
func _game_ok(c: Variant) -> bool:
	if c == null or not is_instance_valid(c) or not c is Node3D:
		return false
	var n := c as Node3D
	if n.has_method(&"is_alive") and not bool(n.call(&"is_alive")):
		return false
	if n.has_method(&"is_visible_to") and not bool(n.call(&"is_visible_to", int(champion.team))):
		return false
	return _flat(champion.global_position - n.global_position) <= GAME_DROP and _now - _game_since <= GAME_MAX


func _exec_game() -> void:
	var c: Variant = plan_node()
	if not _game_ok(c):
		_log("GAME over")
		_set_plan(Plan.NONE, null)
		_replan = true
		return
	_order_attack(c)
	_set_intent(I_GAME, c)


func _drop_game() -> void:
	if plan == Plan.GAME:
		_set_plan(Plan.NONE, null)
		_replan = true


# ---------------------------------------------------------------- R7 shopping

## The shop for a detour now, or null: purse >= next wish-list price, a usable shop within 40 m, no
## flag taken, the last detour >= 60 s ago.
func _shop_detour() -> Node3D:
	if current_flag != null or _now - last_detour_at < SHOP_DETOUR_GAP:
		return null
	var price := _next_price()
	if price <= 0 or _purse() < price:
		return null
	return _nearest_shop(SHOP_DETOUR_MAX)


func _exec_shop() -> void:
	var shop := plan_node() as Node3D
	var alive := shop != null and (not shop.has_method(&"is_alive") or bool(shop.call(&"is_alive")))
	if not alive or _now - _plan_since >= SHOP_TIMEOUT:
		_end_shop()
		return
	if _flat(champion.global_position - shop.global_position) <= SHOP_BUY_DIST:
		_buy_all()
		_end_shop()
		return
	_order_move(_shop_point(shop), false)
	_set_intent(I_SHOP, shop)


func _end_shop() -> void:
	_set_plan(Plan.NONE, null)
	_replan = true
	_plan_left = 0.0


## Buys every affordable wish-list entry in order (Inventory.next_wishlist_buy + buy).
func _buy_all() -> void:
	var inv := _inventory()
	if inv == null or not inv.has_method(&"buy"):
		return
	var list := _wishlist()
	for i in MAX_BUYS:
		var t: Variant = null
		if inv.has_method(&"next_wishlist_buy"):
			t = inv.call(&"next_wishlist_buy", list)
		elif _wish_index < list.size():
			t = _item_type(list[_wish_index])
		if t == null or not t is Object:
			break
		var r: Variant = inv.call(&"buy", t)
		if not (r is String and r == ""):
			break
		if not inv.has_method(&"next_wishlist_buy"):
			_wish_index += 1
		var id: Variant = (t as Object).get(&"id")
		purchases.append(str(id))
		_log("BOUGHT %s (purse %d)" % [str(id), _purse()])


func _next_price() -> int:
	var inv := _inventory()
	if inv == null:
		return 0
	var list := _wishlist()
	if inv.has_method(&"next_wishlist_price"):
		return int(inv.call(&"next_wishlist_price", list))
	if _wish_index < list.size():
		var t := _item_type(list[_wish_index])
		if t and t.has_method(&"total_cost"):
			return int(t.call(&"total_cost"))
	return 0


func _nearest_shop(max_dist: float) -> Node3D:
	var me := champion.global_position
	var best: Node3D = null
	var best_d := max_dist
	for s: Variant in sense.shops:
		if s == null or not is_instance_valid(s):
			continue
		var n := s as Node3D
		var d := _flat(me - n.global_position)
		if d <= best_d:
			best_d = d
			best = n
	return best


## Where to stand to buy: just outside the shop, on our side (well within its 12 m).
func _shop_point(shop: Node3D) -> Vector3:
	var c := shop.global_position
	var reach := Unit.radius_of(shop) if shop.has_method(&"target_radius") else 1.5
	return c + _dir_flat(champion.global_position - c, Vector3(1.0, 0.0, 0.0)) * minf(reach + 2.5, SHOP_BUY_DIST - 2.0)


# ---------------------------------------------------------------- R8 defaults

func _exec_explore() -> void:
	if _tower_step():   # 12.A2: standing in a not-own tower's circle
		return
	var me := champion.global_position
	var fear := _fears_structures()
	var keep_goal := _explore_goal != Vector3.INF and _now - _explore_since < EXPLORE_GOAL_TIME \
			and _flat(me - _explore_goal) > EXPLORE_REACHED \
			and not (fear and sense.near_structure(_explore_goal, _fear_radius()))
	if _explore_tower != null and _explore_goal != Vector3.INF:
		keep_goal = _now - _explore_since < TOWER_WALK_MAX   # a tower goal ends in _tower_step
	if keep_goal and not _explore_is_patrol:   # an explore goal (not a patrol spot) ends once in sight
		keep_goal = sense.state_at(_explore_goal) != FogOfWar.VISIBLE
	if keep_goal and not sense.camp_zone_at(_explore_goal).is_empty():
		keep_goal = false   # 12.A2: a camp was seen there meanwhile
	if not keep_goal:
		_explore_goal = explore_goal()
		_explore_since = _now
		_explore_is_patrol = false
		_explore_tower = null
		if _explore_goal == Vector3.INF:
			# the map is known: patrol the Lost Cache spots, the taverns and the own bank's watchtowers (12.A2)
			_next_patrol_spot()
		else:
			_patrol_looping = false
		if _explore_goal != Vector3.INF:
			_log("EXPLORE (%d, %d)%s" % [roundi(_explore_goal.x), roundi(_explore_goal.z),
					" tower" if _explore_tower != null else ""])
	if _explore_goal != Vector3.INF:
		_order_move(_safe_step(_explore_goal), false)
	_set_intent(I_EXPLORE, _explore_tower)


## Oathwall: every 20 s the next own completed building clockwise around the keep, the one hit most
## recently in the last 30 s first; never more than 25 m from the buildings.
func _exec_patrol() -> void:
	var me := champion.global_position
	var current: Variant = plan_node()
	var entries := _patrol_entries()
	var cur: Dictionary = {}
	for b: Dictionary in entries:
		if b["node"] == current:
			cur = b
			break
	if cur.is_empty() or _now >= _patrol_next_at:
		_patrol_next_at = _now + PATROL_EVERY
		_plan_node = _next_patrol_building(current if not cur.is_empty() else null, entries)
		cur = {}
		for b2: Dictionary in entries:
			if b2["node"] == _plan_node:
				cur = b2
				break
	var bld := plan_node() as Node3D
	if bld == null or cur.is_empty():
		_exec_idle()
		return
	var c := bld.global_position
	var point := c + _dir_flat(me - c, _dir_flat(sense.home_point - c, Vector3(1.0, 0.0, 0.0))) \
			* float(cur["reach"])
	if _chase_leash() > 0.0 and sense.dist_to_own_building(me) > _chase_leash():
		_order_move(_safe_step(point), false)   # too far from home: walk straight back
	else:
		_order_move(_safe_step(point), true)
	_set_intent(I_PATROL, bld)


## The Oathwall's patrol stops: own completed buildings (reach = radius + 2.5 m) and, 12.A2, own-held wells / towers
## within 35 m of an own building (reach = their stand distance, inside the capture circle).
func _patrol_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b: Dictionary in sense.own_buildings:
		out.append({"node": b["node"], "pos": b["pos"], "since_damage": b["since_damage"],
				"reach": float(b["radius"]) + 2.5})
	for p: Dictionary in _own_points_near_home():
		out.append({"node": p["node"], "pos": p["pos"], "since_damage": INF, "reach": p["stand"]})
	return out


func _next_patrol_building(current: Variant, entries: Array[Dictionary]) -> Node3D:
	var hit: Node3D = null
	var hit_age := PATROL_HIT_MEMORY
	for b: Dictionary in entries:
		if not is_instance_valid(b["node"]):
			continue
		if float(b["since_damage"]) < hit_age:
			hit_age = float(b["since_damage"])
			hit = b["node"]
	if hit != null and hit != current:
		return hit
	var home := sense.home_point
	var cur_angle := -INF
	if current != null and is_instance_valid(current):
		var cp := (current as Node3D).global_position
		cur_angle = atan2(cp.z - home.z, cp.x - home.x)
	var next: Node3D = null
	var next_a := INF
	var first: Node3D = null
	var first_a := INF
	for b: Dictionary in entries:
		if not is_instance_valid(b["node"]):
			continue
		var p: Vector3 = b["pos"]
		var a := atan2(p.z - home.z, p.x - home.x)
		if a < first_a:
			first_a = a
			first = b["node"]
		if a > cur_angle + 0.0001 and a < next_a:
			next_a = a
			next = b["node"]
	return next if next != null else first


## Coin-Cutter: a seen enemy worker (last 30 s) with low danger, else the nearest closed Lost Cache, else
## lurk at the tavern door nearer the enemy. 10.A3 (market-trade.md 6.4): a visible Magpie carrying loot within
## 30 m (same danger rule) comes first.
func _choose_raid() -> void:
	var me := champion.global_position
	var cp := _trait("courage", 1.0) * _power() * _hp_ratio()
	var best: Variant = null
	var best_d := LOOTER_RADIUS
	for e: Dictionary in sense.enemies:
		if int(e.get("loot", 0)) <= 0:
			continue
		var lp: Vector3 = e["pos"]
		var ld := _flat(me - lp)
		if ld <= best_d and sense.danger_at(lp, ChampionSense.DANGER_RADIUS, _wizard_mult()) <= cp:
			best_d = ld
			best = e["node"]
	if best != null:
		_set_plan(Plan.RAID, best)
		return
	best_d = INF
	for id: int in sense.workers_seen:
		var w: Dictionary = sense.workers_seen[id]
		if _stale_workers.has(id) and float(_stale_workers[id]) >= float(w["time"]):
			continue
		var node: Object = (w["node"] as WeakRef).get_ref()
		if node == null:
			continue
		var p: Vector3 = w["pos"]
		if sense.danger_at(p, ChampionSense.DANGER_RADIUS, _wizard_mult()) > cp:
			continue
		var d := _flat(me - p)
		if d < best_d:
			best_d = d
			best = node
	if best != null:
		_set_plan(Plan.RAID, best)
		return
	var camp := _camp_to_clear()   # 12.A2: a T1 camp of its own bank, when strong enough
	if camp != null:
		if plan != Plan.CAMP or plan_node() != camp:
			_log("CAMP %s" % camp.name)
		_set_plan(Plan.CAMP, camp)
		return
	var cache := _nearest_cache()
	if cache != null:
		if plan != Plan.CACHE or plan_node() != cache:
			_cache_arrived_at = -INF
		_set_plan(Plan.CACHE, cache)
		return
	_set_plan(Plan.LURK, null)


func _exec_raid() -> void:
	var w := plan_node() as Node3D
	if w == null or not bool(w.call(&"is_alive")):
		_replan = true
		_exec_idle()
		return
	if sense.knows(w):
		_order_attack(w)
	else:
		var id := w.get_instance_id()
		var seen: Dictionary = sense.workers_seen.get(id, {})
		var p: Vector3 = seen.get("pos", w.global_position) if not seen.is_empty() else champion.global_position
		if seen.is_empty() or _flat(champion.global_position - p) <= ARRIVE + 1.0:
			# gone from where we saw it: forget this sighting
			_stale_workers[id] = float(seen.get("time", _now))
			_replan = true
		else:
			_order_move(p, true)
	_set_intent(I_RAID, w)


func _nearest_cache() -> Node3D:
	var me := champion.global_position
	var best: Node3D = null
	var best_d := INF
	for c: Variant in sense.caches:
		if c == null or not is_instance_valid(c):
			continue
		var n := c as Node3D
		if n.has_method(&"is_available") and not bool(n.call(&"is_available")):
			continue
		if float(_ignored_caches.get(n.get_instance_id(), -INF)) > _now:
			continue
		if sense.state_at(n.global_position) == FogOfWar.UNEXPLORED:
			continue
		var d := _flat(me - n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _exec_cache() -> void:
	var c := plan_node() as Node3D
	if c == null or (c.has_method(&"is_available") and not bool(c.call(&"is_available"))):
		_replan = true
		_exec_idle()
		return
	var d := _flat(champion.global_position - c.global_position)
	if d <= ARRIVE:
		if _cache_arrived_at == -INF:
			_cache_arrived_at = _now
		elif _now - _cache_arrived_at >= CACHE_STUCK:
			_ignored_caches[c.get_instance_id()] = _now + CACHE_IGNORE   # it does not open for us
			_replan = true
	if _now - _plan_since >= CACHE_TIMEOUT:
		_ignored_caches[c.get_instance_id()] = _now + CACHE_IGNORE
		_replan = true
	_order_move(_safe_step(c.global_position), false)
	_set_intent(I_RAID, c)


func _exec_lurk() -> void:
	var best := Vector3.INF
	var best_d := INF
	var best_node: Variant = null
	for tv: Dictionary in sense.taverns:
		var door: Vector3 = tv["door"]
		var d := _flat(door - sense.enemy_home)
		if d < best_d:
			best_d = d
			best = door
			best_node = tv["node"]
	if best == Vector3.INF:
		_exec_idle()
		return
	# Lead (2026-09-26): lurk LURK_OFFSET m from the door toward the enemy home, outside the tavern's 12 m hold
	# radius, so an idle lurker never locks the other side out of hiring.
	var away := sense.enemy_home - best
	away.y = 0.0
	if away.length() > 0.1:
		best += away.normalized() * LURK_OFFSET
	_order_move(_safe_step(best), false)
	_set_intent(I_RAID, best_node)


## Mender: the own soldier with the most own soldiers within 10 m (sampling <= 20) is the group centre;
## fewer than 3 soldiers: the wizard; wizard dead: home.
func _choose_follow() -> void:
	var soldiers := sense.own_soldiers
	var spos := sense.own_soldier_pos   # positions at the last pass (same order)
	if soldiers.size() >= MIN_ARMY and spos.size() == soldiers.size():
		var count := spos.size()
		var step := maxi(1, ceili(float(count) / float(FOLLOW_SAMPLES)))
		var r2 := GROUP_RADIUS * GROUP_RADIUS
		var best: Variant = null
		var best_n := -1
		var i := 0
		while i < count:
			var sv: Variant = soldiers[i]
			var p := spos[i]
			i += step
			if sv == null or not is_instance_valid(sv):
				continue
			var n := 0
			for q: Vector3 in spos:
				if (q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z) <= r2:
					n += 1
			if n > best_n:
				best_n = n
				best = sv
		if best != null:
			_set_plan(Plan.FOLLOW, best)
			return
	if sense.own_wizard != null and is_instance_valid(sense.own_wizard):
		_set_plan(Plan.FOLLOW, sense.own_wizard)
		return
	_set_plan(Plan.HOME, null)


func _exec_follow() -> void:
	var u := plan_node() as Node3D
	if u == null or not bool(u.call(&"is_alive")):
		_replan = true
		_exec_home()
		return
	var dist := follow_distance(u)
	var p := u.global_position
	var e := sense.nearest_enemy(p, FOLLOW_ENEMY_RADIUS)
	var away := _dir_flat(p - (e["pos"] as Vector3), Vector3.BACK) if not e.is_empty() \
			else _dir_flat(sense.home_point - p, _dir_flat(champion.global_position - p, Vector3.BACK))
	var point := p + away * dist
	_plan_point = point
	if _flat(champion.global_position - point) > ARRIVE:
		_order_move(point, not is_back_line())   # a melee Mender walks ready to fight (joins like the others)
	_set_intent(I_ARMY, u)


## R8 Mender: how far behind the followed unit it stands. The wizard: 5 m. The army centre: 4 m for a back-line
## Mender (Wizard class or before its class, traits.keep_behind), 1 m for a melee-class one (skills-rework.md 6).
func follow_distance(u: Node3D) -> float:
	if _is_wizard(u):
		return FOLLOW_WIZARD
	if not is_back_line():
		return _trait("keep_behind_melee", MENDER_MELEE_BEHIND)
	return _trait("keep_behind", MENDER_BEHIND)


func _exec_home() -> void:
	var home := _home_building()
	var c: Vector3 = home.global_position if home else sense.home_point
	var r := Unit.radius_of(home) + 3.0 if home else 3.0
	var point := c + _dir_flat(champion.global_position - c, Vector3(1.0, 0.0, 0.0)) * r
	_order_move(_safe_step(point), false)
	_set_intent(I_RESTING, home)


## R9: a new point within 10 m of home every 8-12 s.
func _exec_idle() -> void:
	var home := _home_building()
	var c: Vector3 = home.global_position if home else sense.home_point
	if _now >= _idle_next_at or _flat(_plan_point - c) > IDLE_RADIUS + 2.0:
		_idle_next_at = _now + _rng.randf_range(IDLE_MIN, IDLE_MAX)
		var a := _rng.randf() * TAU
		var r0 := (Unit.radius_of(home) + 2.0) if home else 2.0
		_plan_point = c + Vector3(cos(a), 0.0, sin(a)) * _rng.randf_range(minf(r0, IDLE_RADIUS), IDLE_RADIUS)
	_order_move(_safe_step(_plan_point), false)
	_set_intent(I_IDLE, home)


## Nearest own keep or barracks (completed), or null.
func _home_building() -> Node3D:
	var me := champion.global_position
	var best: Node3D = null
	var best_d := INF
	for b: Dictionary in sense.own_buildings:
		if (b["kind"] != &"keep" and b["kind"] != &"barracks") or not is_instance_valid(b["node"]):
			continue
		var d := _flat(me - (b["pos"] as Vector3))
		if d < best_d:
			best_d = d
			best = b["node"]
	return best


# ---------------------------------------------------------------- orders

func _order_move(p: Vector3, attack_move: bool) -> void:
	var kind := Order.ATTACK_MOVE if attack_move else Order.MOVE
	var me := champion.global_position
	if _order == kind and _flat(p - _order_point) < REORDER_DIST:
		# the same order: re-send only if it stopped short for a while
		if _flat(me - p) <= ARRIVE or _now - _order_at < ORDER_NUDGE or champion.velocity.length() > 0.3:
			return
	if attack_move:
		champion.command_attack_move(p)
	else:
		champion.command_move(p)
	_order = kind
	_order_point = p
	_order_target = null
	_order_at = _now
	_arrive_fired = false


func _order_attack(t: Variant) -> void:
	if _order == Order.ATTACK and _order_target == t and champion.attack_target == t:
		return
	champion.command_attack(t)
	_order = Order.ATTACK
	_order_target = t
	_order_point = Vector3.INF
	_order_at = _now
	_arrive_fired = true


func _reset_orders() -> void:
	_order = Order.NONE
	_order_point = Vector3.INF
	_order_target = null
	_arrive_fired = true


## True once when the champion reaches the point of its last walk order (re-plan event).
func _arrived() -> bool:
	if _arrive_fired or _order_point == Vector3.INF or plan == Plan.FOLLOW:
		return false
	if _flat(champion.global_position - _order_point) <= ARRIVE:
		_arrive_fired = true
		return true
	return false


func _set_intent(id: StringName, target: Variant = null) -> void:
	if _unpaid_now and id != I_SHOP and id != I_FIGHTING:
		id = I_UNPAID   # R5: whatever R7-R9 do, the bar reads "Unpaid!"
	var tgt: Node3D = null
	if target != null and is_instance_valid(target) and target is Node3D:
		tgt = target as Node3D
	var cur: Variant = champion.get(&"intent")
	var cur_t: Variant = champion.get(&"intent_target")
	if id == _intent and tgt == _intent_target and (cur == null or cur == id) and (cur_t == null or cur_t == tgt):
		return
	_intent = id
	_intent_target = tgt
	if champion.has_method(&"set_intent"):
		champion.call(&"set_intent", id, tgt)
	elif &"intent" in champion:
		champion.set(&"intent", id)


# ---------------------------------------------------------------- champion data

func _type() -> Object:
	var t: Variant = champion.get(&"champion_type") if champion else null
	return t if is_instance_valid(t) and t is Object else null


func _resolve_archetype() -> void:
	if champion == null:
		return
	var t := _type()
	var id: Variant = t.get(&"id") if t else null
	if id == null or str(id) == "":
		id = champion.get(&"champion_id")
	if id != null and str(id) != "":
		archetype = StringName(str(id))


## A personality number: ChampionType.traits / affinity, else the 4.2 defaults (cached per type).
func _trait(key: String, fallback: float) -> float:
	var t := _type()
	if t != _traits_type:
		_traits_type = t
		_traits_cache.clear()
	var cached: Variant = _traits_cache.get(key)
	if cached != null:
		return float(cached)
	var value := float((DEFAULTS.get(archetype, {}) as Dictionary).get(key, fallback))
	if t:
		for dict_name: StringName in [&"traits", &"affinity"]:
			var d: Variant = t.get(dict_name)
			if d is Dictionary:
				if (d as Dictionary).has(key):
					value = float(d[key])
					break
				if (d as Dictionary).has(StringName(key)):
					value = float(d[StringName(key)])
					break
	_traits_cache[key] = value
	return value


func _level() -> int:
	return int(champion.level)


## Champion.power() (150 + 50 x level + 20 x unlocked class skills + items / 5), not yet scaled by HP.
func _power() -> float:
	if champion.has_method(&"power"):
		return float(champion.call(&"power"))
	return 150.0 + 50.0 * float(_level())


func _hp_ratio() -> float:
	return clampf(champion.hp / maxf(champion.max_hp, 1.0), 0.0, 1.0)


## 4.2: the Coin-Cutter counts an enemy wizard above 50 % HP twice in danger (traits.wizard_fear_mult).
func _wizard_mult() -> float:
	return _trait("wizard_fear_mult", 2.0 if archetype == COIN_CUTTER else 1.0)


## 4.2 Wayfinder: never near a known enemy tower / keep before level 4 (traits.fear_structures_until_level).
func _fears_structures() -> bool:
	var until := _trait("fear_structures_until_level", float(TOWER_FEAR_LEVEL) if archetype == WAYFINDER else 0.0)
	return float(_level()) < until


func _fear_radius() -> float:
	return _trait("fear_structure_radius", TOWER_FEAR)


## 8.3 Oathwall: never chases more than 25 m past the last building (traits.chase_leash), while on no flag.
func _chase_leash() -> float:
	return _trait("chase_leash", OATH_CHASE if archetype == OATHWALL else 0.0)


func _leashed() -> bool:
	return current_flag == null and _chase_leash() > 0.0


func _is_unpaid() -> bool:
	var v: Variant = champion.get(&"is_unpaid")
	return v != null and bool(v)


func _purse() -> int:
	var v: Variant = champion.get(&"purse")
	return int(v) if v != null else 0


func _inventory() -> Node:
	var inv: Variant = champion.get(&"inventory")
	if is_instance_valid(inv) and inv is Node:
		return inv as Node
	return champion.get_node_or_null(^"Inventory")


func _wishlist() -> Array:
	var t := _type()
	var w: Variant = t.get(&"wishlist") if t else null
	return (w as Array) if w is Array else []


static func _item_type(raw: Variant) -> Object:
	if raw is Object:
		return raw
	return ItemType.find(StringName(str(raw)))


static func _is_worker(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and (n as Object).has_method(&"is_worker") \
			and bool((n as Object).call(&"is_worker"))


static func _is_wizard(n: Variant) -> bool:
	if n == null or not is_instance_valid(n) or not n is Node:
		return false
	var node := n as Node
	return node is Wizard or node.is_in_group(&"heroes") or node.is_in_group(&"enemy_heroes")


static func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


static func _dir_flat(v: Vector3, fallback: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.01 else fallback


func _log(text: String) -> void:
	if not debug_log:
		return
	var line := "[%.1f] %s %s" % [_now, champion.name if champion else "?", text]
	log_lines.append(line)
	if log_lines.size() > 60:
		log_lines.remove_at(0)
	print(line)
