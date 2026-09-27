class_name BeastBrain
extends Node
## The brain of one epic beast (docs/design/map-fill.md 5.5, contract section 13, task 12.A3). EpicBeasts (12.C11)
## creates one per beast and calls setup(beast, lair) with its lair entry ({id, name, kind, center, radius,
## patrol: PackedVector3Array, first_spawn, respawn}; optional `leash`, `nest` (Roc) and `variant`, which
## EpicBeasts passes). It works as a child of EpicBeasts or of the beast: when the beast dies the brain stops,
## and frees itself if it is not the beast's child (EpicBeasts frees it too; both are harmless together).
## It never creates the "CreatureAbilities" node (EpicBeasts adds it first); it switches that node's own
## autocast off (`autocast_enabled = false`: the brain drives every cast, passives keep running) and sets the
## patrol pace through its `set_patrolling(on)` (else the same `beast:patrol` modifier itself).
##
## States (`state`):
## &"patrol": walks the lair's patrol points in order at patrol speed (modifier `beast:patrol`), pausing
##   10-20 s at each; the first combatant within aggro of the beast and inside the leash, or any attacker
##   inside the leash, starts a fight.
## &"fight": attacks `target` at fight speed. Targets are combatants only (PLAYER / ENEMY soldiers, wizards,
##   champions, trackers); workers, caravans, buildings, game critters and neutrals are never picked, but a
##   Unit that hit the beast in the last 3 s is answered while it stands inside the leash (contract: "answer
##   any attacker inside the leash"). The leash is the territory radius + 10 m around the lair centre.
##   Abilities go through the beast's child "CreatureAbilities" (`cast(id, target) -> String`, `ready(id)`),
##   on the triggers of 5.5. The beast walks back when it is beyond the leash or had no valid target for 8 s.
## &"return": walks to the centre at fight speed, ignoring everything; then patrols again.
## &"escape" (Roc only, once per life): at 40 % HP it casts Updraft (target: the nest position, a Vector3) and
##   flies to its nest (lair `nest`, else the centre), ignoring everything; there it fights again.
## Reset heal (patrol and return): after 5 s without damage +3 % max HP / s, full HP after 10 s.
##
## Thinks every 0.5 s, brains staggered by 1/16 s. Candidates come from a cached list of the combatants inside
## the leash, kept by a monitoring-only Area3D child ("LeashArea", a cylinder over the leash, mask = layer 2
## units, no collision layer): entries / exits are signals, so a think never walks the whole "units" group
## (a full walk costs ~3 us per unit in GDScript, ~0.5 ms per think with 170 units), and the candidates are only
## read when a decision needs them (a fight whose target is in reach reads nothing). Movement uses only
## command_move / command_attack / command_stop, issued on changes (never every frame).
## CreatureAbilities (12.C4) and EpicBeasts (12.C11) are reached through get_node_or_null / has_method only.

signal state_changed(brain: BeastBrain, new_state: StringName)

const TICK := 0.5
const STAGGER_SLOTS := 8
const AREA_MARGIN := 1.5                 ## The leash area is this much wider than the leash (unit radii).
const AREA_HEIGHT := 8.0
const UNITS_LAYER := 2                   ## Physics layer 2 = units (CLAUDE.md), as a mask bit value.
const LEASH_EXTRA := 10.0                ## Leash = territory radius + 10 m around the centre (5.5).
const NO_TARGET_RETURN := 8.0            ## Seconds in a fight without a valid target before walking home.
const ATTACKER_MEMORY := 3.0
const ARRIVE := 1.5
const LEG_TIMEOUT := 25.0                ## A patrol leg that takes longer is skipped (blocked point).
const RETURN_TIMEOUT := 30.0
const ESCAPE_ARRIVE := 2.5
const ESCAPE_TIMEOUT := 10.0
const REGEN_DELAY := 5.0
const REGEN_PCT := 0.03                  ## Of max HP per second.
const FULL_HEAL_DELAY := 10.0
const SWITCH_GAIN := 3.0                 ## Switch to an attacker this much closer when the target is out of reach.
const RETRY_AFTER_REFUSAL := 1.0
const RANGED_REACH := 3.0                ## attack_range above this = a ranged unit (Unit.attack_range doc).
const MODIFIER_PATROL := &"beast:patrol"
const ABILITIES_NODE := "CreatureAbilities"
const NEUTRAL := 2                       # Unit.Team.NEUTRAL

const TUSKER := &"tusker"
const ROC := &"roc"
const DIREWOLF := &"direwolf"
const GRIZZLEMAW := &"grizzlemaw"

## Beast unit ids (data/units/*.tres) -> [kind, variant].
const BEAST_IDS := {
	&"ironhide_tusker": [TUSKER, 0], &"old_scarback": [TUSKER, 1],
	&"stormcrest_roc": [ROC, 0], &"duskwing_roc": [ROC, 1],
	&"greymane_direwolf": [DIREWOLF, 0], &"moonpelt_direwolf": [DIREWOLF, 1],
	&"grizzlemaw": [GRIZZLEMAW, 0], &"elder_grizzlemaw": [GRIZZLEMAW, 1],
}
## Aggro of the brain (the .tres has aggro_range 0), patrol and fight speeds of 5.5 (fight = the .tres speed;
## FIGHT_SPEED is only used when the beast has no base move speed).
const AGGRO := {TUSKER: 8.0, ROC: 10.0, DIREWOLF: 9.0, GRIZZLEMAW: 9.0}
const PATROL_SPEED := {TUSKER: 3.5, ROC: 3.5, DIREWOLF: 4.5, GRIZZLEMAW: 3.0}
const FIGHT_SPEED := {TUSKER: 5.5, ROC: 6.5, DIREWOLF: 7.0, GRIZZLEMAW: 5.0}
const DEFAULT_AGGRO := 9.0

# Ability ids (contract section 13) and triggers (5.5).
const GORE_CHARGE := &"gore_charge"
const GALE_SWOOP := &"gale_swoop"
const SHRIEKING_DIVE := &"shrieking_dive"
const UPDRAFT := &"updraft"
const POUNCE := &"pounce"
const MAUL := &"maul"
const RENDING_ROAR := &"rending_roar"
const ENRAGE := &"enrage"
const CHARGE_MIN := 6.0
const CHARGE_MAX := 14.0
const SWOOP_MAX := 12.0
const SWOOP_CROWD := 3.0
const POUNCE_MIN := 5.0
const POUNCE_MAX := 10.0
const MAUL_SLACK := 0.5
const ROAR_RADIUS := 6.0
const ROAR_HP := 0.5
const UPDRAFT_HP := 0.4
const ENRAGE_HP := 0.3
const UPDRAFT_RETRY := 3.0               ## Updraft refused this long (not transiently): the Roc flies home anyway.
## CreatureAbilities refusals that only mean "not now" (Updraft is retried until it works).
const TRANSIENT_REFUSALS: Array[String] = ["Cannot act", "Cannot move", "Busy", "On cooldown"]
## Used only when CreatureAbilities has no ready() / is_ready(): the brain times the cooldowns itself.
const FALLBACK_COOLDOWN := {GORE_CHARGE: 12.0, GALE_SWOOP: 10.0, SHRIEKING_DIVE: 10.0, POUNCE: 9.0,
		MAUL: 9.0, RENDING_ROAR: 30.0, UPDRAFT: INF, ENRAGE: INF}

@export var enabled := true              ## False: no automatic ticks (tests call think_now()).
@export var debug_log := false
@export var pause_min := 10.0            ## Patrol pause range (s) at each point (5.5: 10-20 s).
@export var pause_max := 20.0

## Perf counters over every brain (tests / perf runs read them).
static var think_usec_total: int = 0
static var think_count: int = 0
static var scan_usec_total: int = 0      ## Part of think_usec_total spent reading the cached list.
static var _serial: int = 0

var beast: Unit = null                   ## The beast (read only).
var lair: Dictionary = {}                ## Its lair entry (read only).
var kind: StringName = &""               ## &"tusker", &"roc", &"direwolf", &"grizzlemaw" (read only).
var variant: int = 0                     ## 0 = A, 1 = B (read only).
var state: StringName = &"patrol"        ## &"patrol", &"fight", &"return", &"escape" (read only).
var target: Node3D = null                ## The combatant it fights (read only).
var escaped := false                     ## True once the Roc's Updraft escape happened (read only).
var casts: Dictionary = {}               ## Ability id -> successful casts (read only, tests / debug).
var patrol_visits: int = 0               ## Patrol points reached (read only).
var log_lines: Array[String] = []        ## The last decisions (debug).

var _center := Vector3.ZERO
var _radius := 4.0
var _leash := 4.0 + LEASH_EXTRA
var _nest := Vector3.ZERO
var _aggro := DEFAULT_AGGRO
var _patrol: Array[Vector3] = []
var _patrol_snapped := false
var _patrol_index := 0
var _pause_left := 0.0
var _leg_time := 0.0
var _moving_to := Vector3.INF
var _clock := 0.0
var _think_left := TICK
var _state_time := 0.0
var _no_target_time := 0.0
var _attackers: Dictionary = {}          # attacker instance id -> {"node": Node3D, "time": float}
var _nearby: Array = []                  # combatants inside the leash (this tick)
var _nearby_attackers: Array = []        # recent attackers inside the leash (this tick)
var _near_ready := false
var _atts_ready := false
var _ab: Node = null                     # the beast's CreatureAbilities (cached)
var _last_cast: Dictionary = {}          # id -> clock of the last successful cast
var _retry_at: Dictionary = {}           # id -> clock before which a refused cast is not retried
var _area: Area3D = null
var _members: Dictionary = {}            # instance id -> Unit: combatants inside the leash area (signals)
var _updraft_since := -1.0               # clock when Updraft was first wanted (-1: not yet)
var _enraged := false
var _enrage_refusals := 0
var _patrol_mod_on := false
var _abilities_bound := false
var _setup_done := false
var _dead := false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	add_to_group(&"beast_brains")
	_think_left = TICK * float(_serial % STAGGER_SLOTS + 1) / float(STAGGER_SLOTS)
	_serial += 1


func _ready() -> void:
	if not _setup_done and get_parent() is Unit:
		setup(get_parent() as Unit, {})


## `beast`: the living beast Unit (team NEUTRAL, group "beasts"); `lair`: its EpicBeasts lair entry. Kind and
## variant come from the lair (`kind`, `variant`) or else from the beast's UnitType id.
func setup(p_beast: Unit, p_lair: Dictionary) -> void:
	if beast != null and is_instance_valid(beast) and beast.damage_taken.is_connected(_on_damage_taken):
		beast.damage_taken.disconnect(_on_damage_taken)
		beast.died.disconnect(_on_died)
	beast = p_beast
	lair = p_lair.duplicate()
	if beast == null:
		return
	var info: Array = BEAST_IDS.get(beast.unit_type.id if beast.unit_type != null else &"", [&"", 0])
	kind = StringName(lair.get("kind", info[0]))
	variant = int(lair.get("variant", beast.get_meta(&"beast_variant", info[1])))
	var c: Variant = lair.get("center", lair.get("centre", null))
	if c is Vector3:
		_center = c
	elif beast.is_inside_tree():
		_center = beast.global_position
	else:
		_center = beast.position
	_center.y = 0.0
	_radius = float(lair.get("radius", 4.0))
	_leash = float(lair.get("leash", _radius + LEASH_EXTRA))
	var n: Variant = lair.get("nest", null)
	_nest = n if n is Vector3 else _center
	_aggro = float(lair.get("aggro", AGGRO.get(kind, DEFAULT_AGGRO)))
	_patrol.clear()
	var pts: Variant = lair.get("patrol", [])
	if pts is PackedVector3Array or pts is Array:
		for p: Variant in pts:
			if p is Vector3:
				_patrol.append(p)
	_patrol_snapped = false
	_patrol_index = 0
	_rng.seed = hash(str(lair.get("id", "beast"))) + variant
	_pause_left = 0.0
	beast.damage_taken.connect(_on_damage_taken)
	beast.died.connect(_on_died)
	_build_area()
	_abilities_bound = false
	_bind_abilities()
	_setup_done = true
	_dead = false
	state = &"patrol"
	_state_time = 0.0


## Runs one think now (tests, debug). The leash area learns about units one physics frame after they arrive.
func think_now() -> void:
	_think()


## Leash radius around the lair centre (the lair's `leash`, else territory radius + 10 m).
func leash_radius() -> float:
	return _leash


## The lair centre (y = 0).
func center() -> Vector3:
	return _center


## The brain's aggro radius (the beast's own aggro_range is 0).
func aggro_radius() -> float:
	return _aggro


## Seconds spent in the current state.
func state_time() -> float:
	return _state_time


## The combatants the leash area holds now (living ones; read only, a copy).
func combatants_in_leash() -> Array:
	var out: Array = []
	for u: Variant in _members.values():
		if is_instance_valid(u) and (u as Unit).is_alive():
			out.append(u)
	return out


## True for a unit a beast may pick: a living PLAYER / ENEMY Unit that fights (soldiers, wizards, champions,
## trackers). False for workers, caravans, non-combatants, neutrals (creatures, Magpies, beasts), units
## leaving the map, buildings and game critters (not Units).
static func is_combatant(node: Variant) -> bool:
	if node == null or not is_instance_valid(node) or not node is Unit:
		return false
	var u := node as Unit
	if not u.is_alive() or int(u.team) == NEUTRAL or u.is_worker() or u.is_non_combatant():
		return false
	if u.is_in_group(&"caravans") or u.is_in_group(&"beasts") or u.has_left_map():
		return false
	return true


# ---------------------------------------------------------------- frame

func _physics_process(delta: float) -> void:
	if not _setup_done or _dead:
		return
	_clock += delta
	_state_time += delta
	if not enabled:
		return
	_think_left -= delta
	if _think_left > 0.0:
		return
	_think_left += TICK
	if _think_left <= 0.0:
		_think_left = TICK
	var t0 := Time.get_ticks_usec()
	_think()
	think_usec_total += Time.get_ticks_usec() - t0
	think_count += 1


func _think() -> void:
	if _dead:
		return
	if beast == null or not is_instance_valid(beast):
		_dead = true
		set_physics_process(false)
		if not is_queued_for_deletion():
			queue_free()   # the beast was freed without dying (a child brain goes with it anyway)
		return
	if not beast.is_alive():
		return
	if not _patrol_snapped:
		_snap_patrol()
	if not _abilities_bound:
		_bind_abilities()
	_near_ready = false
	_atts_ready = false
	match state:
		&"patrol":
			_think_patrol()
		&"fight":
			_think_fight()
		&"return":
			_think_return()
		&"escape":
			_think_escape()


# ---------------------------------------------------------------- states

func _think_patrol() -> void:
	if _check_updraft():
		return
	if _beast_center_dist() > leash_radius():
		_set_state(&"return")
		_think_return()
		return
	var t := _pick_target()
	if t != null:
		_start_fight(t)
		return
	_regen()
	# A fight-back the Unit picked itself (a worker, a building...) is cancelled while patrolling.
	if beast.attack_target != null and beast.taunt_source() == null:
		beast.command_stop()
		_moving_to = Vector3.INF
	_patrol_mod(true)
	if _patrol.is_empty():
		if _flat(beast.global_position, _center) > ARRIVE:
			_move(_center)
		return
	var goal := _patrol[_patrol_index % _patrol.size()]
	if _pause_left > 0.0:
		_pause_left -= TICK
		if _pause_left <= 0.0:
			_patrol_index = (_patrol_index + 1) % _patrol.size()
			_leg_time = 0.0
			_move(_patrol[_patrol_index])
		return
	_leg_time += TICK
	if _flat(beast.global_position, goal) <= ARRIVE or _leg_time > LEG_TIMEOUT:
		if _leg_time <= LEG_TIMEOUT:
			patrol_visits += 1
		beast.command_stop()
		_moving_to = Vector3.INF
		_pause_left = _rng.randf_range(pause_min, maxf(pause_min, pause_max))
		_log("patrol: at point %d, pause %.1f s" % [_patrol_index, _pause_left])
		return
	_move(goal)


func _think_fight() -> void:
	if _check_updraft():
		return
	if _beast_center_dist() > leash_radius() + 1.0:
		_log("fight: beyond the leash")
		_set_state(&"return")
		_think_return()
		return
	var taunter := beast.taunt_source()
	if taunter != null:
		target = taunter   # Unit forces the attack; the brain only follows
	elif not _valid_target(target):
		target = _pick_target()
	else:
		target = _maybe_switch(target)
	if target == null:
		_no_target_time += TICK
		if _no_target_time >= NO_TARGET_RETURN:
			_log("fight: no target for %.0f s" % NO_TARGET_RETURN)
			_set_state(&"return")
			_think_return()
			return
		if beast.attack_target != null and taunter == null and not _busy():
			beast.command_stop()   # nothing valid: stand and look (no chase outside the leash)
		return
	_no_target_time = 0.0
	if beast.can_act():
		_use_abilities()
	if target != null and taunter == null and not _busy() and beast.attack_target != target:
		beast.command_attack(target)


func _think_return() -> void:
	_patrol_mod(false)
	target = null
	_regen()
	if _flat(beast.global_position, _center) <= ARRIVE + 0.5 or _state_time > RETURN_TIMEOUT:
		beast.command_stop()
		_moving_to = Vector3.INF
		_patrol_index = _nearest_patrol_index()
		_leg_time = 0.0
		_pause_left = _rng.randf_range(pause_min, maxf(pause_min, pause_max)) * 0.5
		_set_state(&"patrol")
		return
	_move(_center)


func _think_escape() -> void:
	_patrol_mod(false)
	target = null
	if _flat(beast.global_position, _nest) <= ESCAPE_ARRIVE or _state_time > ESCAPE_TIMEOUT:
		beast.command_stop()
		_moving_to = Vector3.INF
		_log("escape: at the nest")
		_patrol_index = _nearest_patrol_index()
		_pause_left = _rng.randf_range(pause_min, maxf(pause_min, pause_max))
		var t := _pick_target()
		if t != null:
			_start_fight(t)
		else:
			_set_state(&"patrol")
		return
	_move(_nest)


func _start_fight(t: Node3D) -> void:
	target = t
	_no_target_time = 0.0
	_patrol_mod(false)
	_moving_to = Vector3.INF
	_set_state(&"fight")
	_log("fight: %s" % _name_of(t))
	if beast.can_act():
		_use_abilities()
	if target != null and beast.taunt_source() == null and not _busy() and beast.attack_target != target:
		beast.command_attack(target)


func _set_state(s: StringName) -> void:
	if s == state:
		return
	state = s
	_state_time = 0.0
	if s != &"fight":
		_no_target_time = 0.0
	state_changed.emit(self, s)


# ---------------------------------------------------------------- targets

# Candidates are built lazily, at most once per think (a fight with its target in reach and no ability ready
# never walks them): _near() = combatants of the leash area inside the leash, _atts() = recent attackers inside it.
func _near() -> Array:
	if _near_ready:
		return _nearby
	_near_ready = true
	var t0 := Time.get_ticks_usec()
	_nearby.clear()
	var leash := leash_radius()
	var cx := _center.x
	var cz := _center.z
	for id: int in _members.keys():
		var node: Variant = _members[id]
		if not is_instance_valid(node):
			_members.erase(id)
			continue
		var u := node as Unit
		if not u.is_alive():
			_members.erase(id)
			continue
		var p := u.global_position
		var dx := p.x - cx
		var dz := p.z - cz
		var r := leash + u.radius
		if dx * dx + dz * dz <= r * r:
			_nearby.append(u)
	scan_usec_total += Time.get_ticks_usec() - t0
	return _nearby


func _atts() -> Array:
	if _atts_ready:
		return _nearby_attackers
	_atts_ready = true
	_nearby_attackers.clear()
	if _attackers.is_empty():
		return _nearby_attackers
	for id: int in _attackers.keys():
		var entry: Dictionary = _attackers[id]
		var node: Variant = entry["node"]
		if _clock - float(entry["time"]) > ATTACKER_MEMORY or not is_instance_valid(node):
			_attackers.erase(id)
			continue
		if node is Unit and (node as Unit).is_alive() and not (node as Unit).is_in_group(&"caravans") \
				and _inside_leash(node as Unit):
			_nearby_attackers.append(node)
	return _nearby_attackers

# New target: the nearest recent attacker inside the leash, else the nearest combatant within aggro.
func _pick_target() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var pos := beast.global_position
	for a: Variant in _atts():
		var d := _flat(pos, (a as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = a
	if best != null:
		return best
	for u: Unit in _near():
		if u.is_hidden_from_auto_target():
			continue
		var d := _flat(pos, u.global_position) - u.radius
		if d <= _aggro and d < best_d:
			best_d = d
			best = u
	return best


# Keeps `t` unless it is out of reach and an attacker stands clearly closer.
func _maybe_switch(t: Node3D) -> Node3D:
	if _in_reach(t, 0.0) or _atts().is_empty():
		return t
	var pos := beast.global_position
	var d_t := _flat(pos, t.global_position)
	var best := t
	var best_d := d_t - SWITCH_GAIN
	for a: Variant in _atts():
		var d := _flat(pos, (a as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = a
	if best != t:
		_log("fight: switch to attacker %s" % _name_of(best))
	return best


func _valid_target(t: Variant) -> bool:
	if t == null or not is_instance_valid(t) or not t is Unit:
		return false
	var u := t as Unit
	if not u.is_alive() or u.has_left_map() or not _inside_leash(u):
		return false
	if _members.has(u.get_instance_id()) or is_combatant(u):   # the leash area only keeps combatants
		return true
	return _atts().has(u)   # a non-combatant attacker is answered while it keeps hitting


func _inside_leash(u: Node3D) -> bool:
	return _flat(u.global_position, _center) <= leash_radius() + Unit.radius_of(u)


func _in_reach(t: Node3D, slack: float) -> bool:
	return _flat(beast.global_position, t.global_position) \
			<= beast.attack_range + beast.radius + Unit.radius_of(t) + slack


# ---------------------------------------------------------------- abilities

func _use_abilities() -> void:
	match kind:
		TUSKER:
			if _ready_to(GORE_CHARGE):
				var t := _band_target(CHARGE_MIN, CHARGE_MAX, false)
				if t != null and _cast(GORE_CHARGE, t):
					target = t
		ROC:
			var id := SHRIEKING_DIVE if variant == 1 else GALE_SWOOP
			if _ready_to(id):
				var t := _crowd_target()
				if t != null and _cast(id, t):
					target = t
		DIREWOLF:
			if _ready_to(POUNCE):
				var t := _band_target(POUNCE_MIN, POUNCE_MAX, true)
				if t != null and _cast(POUNCE, t):
					target = t
		GRIZZLEMAW:
			var ratio := _hp_ratio()
			if not _enraged and ratio < ENRAGE_HP and _ready_to(ENRAGE):
				if _cast(ENRAGE, beast):
					_enraged = true
					return
				_enrage_refusals += 1
				if _enrage_refusals >= 3:
					_enraged = true   # CreatureAbilities handles it as a passive: stop asking
			if ratio <= ROAR_HP and _ready_to(RENDING_ROAR) and _count_near(beast.global_position, ROAR_RADIUS) > 0:
				_cast(RENDING_ROAR, target if target != null else beast)
				return
			if target != null and _in_reach(target, MAUL_SLACK) and _ready_to(MAUL):
				_cast(MAUL, target)


# Gore Charge / Pounce: a combatant `lo`-`hi` m away inside the leash. Pounce prefers ranged units; both then
# prefer the current target, then the nearest.
func _band_target(lo: float, hi: float, prefer_ranged: bool) -> Node3D:
	var pos := beast.global_position
	var best: Node3D = null
	var best_score := INF
	for u: Unit in _near():
		if u.is_hidden_from_auto_target() and u != target:
			continue
		var d := _flat(pos, u.global_position)
		if d < lo or d > hi:
			continue
		var score := d
		if u == target:
			score -= 100.0
		if prefer_ranged and u.attack_range > RANGED_REACH:
			score -= 1000.0
		if score < best_score:
			best_score = score
			best = u
	return best


# Gale Swoop / Shrieking Dive: the combatant within 12 m with the most combatants within 3 m of it (ties: the
# current target, then the nearest).
func _crowd_target() -> Node3D:
	var pos := beast.global_position
	var best: Node3D = null
	var best_score := -INF
	var crowd_sq := SWOOP_CROWD * SWOOP_CROWD
	for u: Unit in _near():
		if u.is_hidden_from_auto_target() and u != target:
			continue
		var d := _flat(pos, u.global_position)
		if d > SWOOP_MAX:
			continue
		var count := 0
		var p := u.global_position
		for o: Unit in _nearby:
			if o == u:
				continue
			var dx := o.global_position.x - p.x
			var dz := o.global_position.z - p.z
			if dx * dx + dz * dz <= crowd_sq:
				count += 1
		var score := float(count) * 100.0 - d + (1.0 if u == target else 0.0)
		if score > best_score:
			best_score = score
			best = u
	return best


func _count_near(pos: Vector3, r: float) -> int:
	var n := 0
	for u: Unit in _near():
		if _flat(pos, u.global_position) <= r + u.radius:
			n += 1
	return n


# Updraft (Roc, once per life at 40 % HP): cast it and fly to the nest. If CreatureAbilities refuses for 3 s
# (or is missing), the Roc flies home anyway.
func _check_updraft() -> bool:
	if kind != ROC or escaped or _hp_ratio() > UPDRAFT_HP or not beast.can_act():
		return false
	var ab := _abilities()
	var ok := false
	if ab != null and ab.has_method(&"cast"):
		var reason := str(ab.call(&"cast", UPDRAFT, _nest))
		ok = reason == ""
		if ok:
			casts[UPDRAFT] = int(casts.get(UPDRAFT, 0)) + 1
		elif TRANSIENT_REFUSALS.has(reason):
			return false   # rooted / mid-leap: Updraft comes as soon as it can
		else:
			if _updraft_since < 0.0:
				_updraft_since = _clock
			if _clock - _updraft_since < UPDRAFT_RETRY:
				return false
	escaped = true
	target = null
	_patrol_mod(false)
	_moving_to = Vector3.INF
	_set_state(&"escape")
	_log("escape: Updraft to the nest (%s)" % ("cast" if ok else "no cast"))
	_move(_nest)
	return true


func _abilities() -> Node:
	if _ab != null and is_instance_valid(_ab):
		return _ab
	_ab = beast.get_node_or_null(ABILITIES_NODE) if beast != null and is_instance_valid(beast) else null
	return _ab


# The brain drives every cast: CreatureAbilities' own autocast is switched off (its passives keep running).
func _bind_abilities() -> void:
	var ab := _abilities()
	if ab == null:
		return
	_abilities_bound = true
	if ab.get(&"autocast_enabled") != null:
		ab.set(&"autocast_enabled", false)


func _ready_to(id: StringName) -> bool:
	var ab := _abilities()
	if ab == null or not ab.has_method(&"cast"):
		return false
	if _clock < float(_retry_at.get(id, -INF)):
		return false
	if ab.has_method(&"ready"):
		return bool(ab.call(&"ready", id))
	if ab.has_method(&"is_ready"):
		return bool(ab.call(&"is_ready", id))
	return _clock - float(_last_cast.get(id, -INF)) >= float(FALLBACK_COOLDOWN.get(id, 10.0))


func _cast(id: StringName, cast_target: Variant) -> bool:
	var ab := _abilities()
	if ab == null or not ab.has_method(&"cast"):
		return false
	var reason := str(ab.call(&"cast", id, cast_target))
	if reason != "":
		_retry_at[id] = _clock + RETRY_AFTER_REFUSAL
		_log("cast %s refused: %s" % [id, reason])
		return false
	_last_cast[id] = _clock
	casts[id] = int(casts.get(id, 0)) + 1
	_log("cast %s" % id)
	return true


# CreatureAbilities may report a dash / leap in progress (`is_busy()`): no new orders meanwhile.
func _busy() -> bool:
	var ab := _abilities()
	return ab != null and ab.has_method(&"is_busy") and bool(ab.call(&"is_busy"))


# ---------------------------------------------------------------- helpers

func _regen() -> void:
	if beast.hp >= beast.max_hp:
		return
	var quiet := beast.seconds_since_damage()
	if quiet >= FULL_HEAL_DELAY:
		beast.heal(beast.max_hp)
	elif quiet >= REGEN_DELAY:
		beast.heal(beast.max_hp * REGEN_PCT * TICK)


func _patrol_mod(on: bool) -> void:
	if on == _patrol_mod_on:
		return
	_patrol_mod_on = on
	var ab := _abilities()
	if ab != null and ab.has_method(&"set_patrolling"):
		ab.call(&"set_patrolling", on)   # same modifier id, speeds from its BEASTS table
		return
	if not on:
		beast.remove_modifier(MODIFIER_PATROL)
		return
	var base := beast.get_base_stat(&"move_speed")
	if base <= 0.0:
		base = float(FIGHT_SPEED.get(kind, beast.move_speed))
	var patrol_speed := float(PATROL_SPEED.get(kind, base))
	if base > patrol_speed:
		beast.add_modifier(MODIFIER_PATROL, {"move_speed_pct": patrol_speed / base - 1.0})


# Orders a walk only when the goal changed (or the beast picked a fight by itself meanwhile).
func _move(goal: Vector3) -> void:
	if _busy():
		return
	if _moving_to.is_finite() and _flat(_moving_to, goal) < 0.5 and beast.attack_target == null:
		return
	_moving_to = goal
	beast.command_move(goal)


func _snap_patrol() -> void:
	if not beast.is_inside_tree():
		return
	var world := beast.get_world_3d()
	if world == null:
		return
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return
	_patrol_snapped = true
	for i in _patrol.size():
		var p := NavigationServer3D.map_get_closest_point(map, _patrol[i])
		if p.is_finite() and _flat(p, _patrol[i]) < 6.0:
			_patrol[i] = p
	var c := NavigationServer3D.map_get_closest_point(map, _nest)
	if c.is_finite() and _flat(c, _nest) < 6.0:
		_nest = c


func _nearest_patrol_index() -> int:
	var best := 0
	var best_d := INF
	for i in _patrol.size():
		var d := _flat(beast.global_position, _patrol[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _hp_ratio() -> float:
	return beast.hp / beast.max_hp if beast.max_hp > 0.0 else 1.0


func _beast_center_dist() -> float:
	return _flat(beast.global_position, _center)


func _on_damage_taken(_amount: float, attacker: Node3D) -> void:
	if attacker == null or not is_instance_valid(attacker) or not attacker is Unit:
		return
	if not beast.is_enemy_of(attacker):
		return
	_attackers[attacker.get_instance_id()] = {"node": attacker, "time": _clock}


func _on_died(_unit: Unit) -> void:
	_dead = true
	target = null
	set_physics_process(false)
	if get_parent() != beast and not is_queued_for_deletion():
		queue_free()


# The monitoring-only leash area (a cylinder at the centre, top_level so it never follows its parent).
func _build_area() -> void:
	if _area == null:
		_area = Area3D.new()
		_area.name = "LeashArea"
		_area.top_level = true
		_area.monitorable = false
		_area.collision_layer = 0
		_area.collision_mask = UNITS_LAYER
		var shape := CollisionShape3D.new()
		shape.shape = CylinderShape3D.new()
		_area.add_child(shape)
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
		add_child(_area)
	var cyl := (_area.get_child(0) as CollisionShape3D).shape as CylinderShape3D
	cyl.radius = _leash + AREA_MARGIN
	cyl.height = AREA_HEIGHT
	_area.position = Vector3(_center.x, AREA_HEIGHT * 0.5 - 1.0, _center.z)
	_members.clear()


func _on_body_entered(body: Node3D) -> void:
	if is_combatant(body):
		_members[body.get_instance_id()] = body


func _on_body_exited(body: Node3D) -> void:
	if body != null:
		_members.erase(body.get_instance_id())


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _name_of(n: Variant) -> String:
	if n == null or not is_instance_valid(n):
		return "null"
	var nm: Variant = (n as Node).get(&"unit_name")
	return str(nm) if nm != null else str((n as Node).name)


func _log(line: String) -> void:
	var s := "[%.1f] %s %s" % [_clock, kind, line]
	log_lines.append(s)
	if log_lines.size() > 30:
		log_lines.remove_at(0)
	if debug_log:
		print("BeastBrain ", s)
