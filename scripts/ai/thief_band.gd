class_name ThiefBand
extends Node
## One band of Magpies (market-trade.md 5.3): the brain that moves 2-4 neutral thieves from a Magpie Den to an
## ambush spot, strikes a loaded caravan or the workers of a remote node, then flees home in smoke.
## ThievesGuild (10.C4) spawns the Magpies at a Den door, creates the band, adds it to the tree and calls
## setup(guild, thieves, target) with one of its targets() entries ({kind, team, post or node, spot, weight}).
##
## States: leaving -> lurking -> striking -> fleeing -> done (a lurk that finds nothing also ends in fleeing,
## without smoke). Thinks every 0.5 s (bands staggered by 0.1 s); movement is command_move / command_attack only
## (never attack-move), so no path is queried per frame. The snatch channel is timed per frame (a float).
## Per-Magpie loot (gold) lives in `thief.get_meta(&"loot", 0)` (max 60 from snatches); a Magpie that dies
## with loot drops a LootSack (load guard: scripts/world/loot_sack.gd); a Magpie home at a Den door leaves the
## map (Unit.leave_map()) and its loot is fenced (gone).
## Strength rules (5.3 "Strike check"): soldiers and wizards as AIMemory, champions power(), trackers 150,
## Magpies 80, workers and caravans 0; a finished tower whose range covers the point 150, a keep 250.

signal finished(band: ThiefBand)
## A strike begins (UI whistle, TradeNetwork / ThievesGuild bookkeeping). `victim`: a caravan or a worker.
signal strike_started(band: ThiefBand, victim: Node3D)
## A Magpie begins the 1.5 s Snatch channel on a caravan.
signal snatch_started(thief: Node3D, caravan: Node3D)
## A Snatch finished: `amount` gold went from the caravan to the thief's loot.
signal snatched(thief: Node3D, caravan: Node3D, amount: int)

const TICK := 0.5                     ## Think interval (s).
const STAGGER := 0.1                  ## Bands are offset by 0.1 s steps so they don't think on the same frame.
const MAGPIE_STRENGTH := 80.0
const TRACKER_STRENGTH := 150.0
const TOWER_STRENGTH := 150.0
const KEEP_STRENGTH := 250.0
const STRIKE_RATIO := 70.0            ## Strike only when the escort strength <= 70 x living Magpies.
const ESCORT_RADIUS := 10.0
const CARAVAN_STRIKE_RADIUS := 12.0   ## A loaded caravan this close to the band triggers a strike.
const WORKER_STRIKE_RADIUS := 14.0    ## Workers this close to the target node can be struck.
const LURK_TIME := 90.0
const CLUSTER_RADIUS := 1.5           ## Lurk slots on a 1.5 m circle: a loose 3 m cluster.
const SNATCH_TIME := 1.5
const SNATCH_BREAK_DAMAGE := 20.0
const SNATCH_REACH := 1.8             ## Gap (m) between the thief's and the caravan's bodies to start a snatch.
const SNATCH_KEEP_REACH := 2.8        ## ... and to finish it (the caravan may roll on a little).
const LOOT_MAX := 60                  ## Gold one Magpie takes from snatches / kills.
const FINISH_TIME := 15.0             ## After the cargo is gone, keep hitting the caravan at most this long.
const STRIKE_MAX_TIME := 30.0         ## Safety: a caravan strike never lasts longer (snatches keep breaking).
const WORKER_STRIKE_TIME := 15.0
const WORKER_KILLS_MAX := 2
const SHROUD_TIME := 2.0
const SACK_RADIUS := 15.0
const SACK_REACH := 2.0
const CHASE_LIMIT := 15.0             ## Fight-back never drags a Magpie farther than this from its spot.
const ATTACK_MEMORY := 3.0            ## Attackers count for this long after their last hit.
const FORCE_RADIUS := 12.0            ## The attackers' team's units this close to the band count as the force.
const DOOR_REACH := 3.0               ## A fleeing Magpie this close to a Den door leaves the map.
## Bot fix D3 (2026-10-12): a flee never lasts longer (cross-map flees on 176 m maps take ~40 s + sack pickups);
## after it every remaining thief leaves the map where it stands (door blocked / unreachable).
const FLEE_MAX_TIME := 90.0
const SACK_RUN_MAX := 10.0            ## D3: a calm-flee sack run longer than this is dropped (sack unreachable).
const ARRIVE_RADIUS := 4.0
const REMOTE_DISTANCE := 30.0         ## Nodes (and workers) within 30 m of their team's keep are home: never raided.
const SPOT_UNIT_RADIUS := 18.0
const SPOT_TOWER_RADIUS := 20.0
const SPOT_KEEP_RADIUS := 25.0
const SPOT_RETRY_TIME := 20.0
const SPOT_RETRIES := 3
const KEEP_CACHE_TIME := 10.0
const LOOT_SACK_PATH := "res://scripts/world/loot_sack.gd"
const DEFAULT_DEN_DOORS: Array[Vector3] = [Vector3(-51.0, 0.0, -45.0), Vector3(51.0, 0.0, 45.0)]
const NEUTRAL := 2   # Unit.Team.NEUTRAL

var guild: Node = null
var thieves: Array = []               ## Living Magpies of the band (read only).
var target: Dictionary = {}           ## The ThievesGuild.targets() entry (read only).
var spot: Vector3 = Vector3.INF       ## Current ambush spot (read only).
var state: StringName = &"leaving"    ## &"leaving", &"lurking", &"striking", &"fleeing", &"done" (read only).
var worker_kills: int = 0             ## Workers killed in the worker strike (read only).
## The LootSack script (static spawn(parent, pos, amount)); set from LOOT_SACK_PATH in setup. Tests may inject.
var loot_sack_script: Script = null

## Perf counters over every band (tests / perf runs read them).
static var think_usec_total: int = 0
static var think_count: int = 0
static var _serial: int = 0

var _team := -1
var _kind: StringName = &"road"
var _size := 0
var _clock := 0.0
var _think_left := TICK
var _setup_done := false          # nothing runs before setup() (the guild adds the band, then calls it)
var _started := false
var _state_time := 0.0
var _spots: Array[Vector3] = []   # the route's road spots (post end first), for the one move to the next spot
var _spot_index := -1
var _moved_once := false
var _waiting := false             # no valid spot yet: waiting at the Den door
var _retries := 0
var _travel_limit := 60.0
var _slots: Dictionary = {}       # thief instance id -> Vector3 lurk slot
var _doors: Array[Vector3] = []
var _door := Vector3.INF
var _flee_calm := false           # going home after a quiet lurk (no smoke)
# Fights
var _attackers: Dictionary = {}   # attacker instance id -> {"node": Node3D, "time": float}
var _hit_by: Dictionary = {}      # thief instance id -> {"node": Node3D, "time": float}
var _unit_attackers: Array = []   # living enemy units that hit the band in the last 3 s (from _attack_force)
var _building_attackers := 0
var _fighting := false
var _fight_origin := Vector3.ZERO
var _answering: Dictionary = {}   # thief instance id -> the attacker it answers
# Strike
var _victim: Node3D = null
var _strike_kind: StringName = &""
var _strike_time := 0.0
var _cargo_gone_at := -1.0
var _snatcher: Unit = null
var _snatch_left := 0.0
var _snatch_damage := 0.0
# Sacks
var _sack_runs: Dictionary = {}   # thief instance id -> {"thief": Unit, "sack": Node3D, "start": float}
var _sacks_given_up: Dictionary = {}   # sack instance id -> true: a flee sack run timed out on it (D3)
# Cache
var _keep_cache: Dictionary = {}  # team -> Vector3
var _keep_cache_at := -100.0


func _init() -> void:
	add_to_group(&"thief_bands")
	_think_left = TICK + STAGGER * float(_serial % 5)
	_serial += 1


## `thieves`: the Magpies (Units, team NEUTRAL, usually standing at a Den door); `target`: a
## ThievesGuild.targets() entry. `target.spot` (a Vector3) is used as given; without one the band picks the
## first valid spot of the route (TradeNetwork.ambush_spots) or the node's worker spot itself, waiting at the
## Den door and retrying every 20 s (3 retries, then it goes back in).
func setup(guild_node: Node, thief_list: Array, target_entry: Dictionary) -> void:
	guild = guild_node
	target = target_entry.duplicate()
	_team = int(target.get("team", -1))
	_kind = StringName(target.get("kind", &"road"))
	thieves = []
	for t in thief_list:
		if is_instance_valid(t) and t is Unit and (t as Unit).is_alive():
			_adopt(t as Unit)
	_size = thieves.size()
	if loot_sack_script == null and ResourceLoader.exists(LOOT_SACK_PATH):
		loot_sack_script = load(LOOT_SACK_PATH) as Script
	var s: Variant = target.get("spot")
	if s is Vector3 and (s as Vector3).is_finite():
		spot = s
	state = &"leaving"
	_state_time = 0.0
	_setup_done = true


## 80 per living Magpie.
func strength() -> float:
	return MAGPIE_STRENGTH * float(_alive_count())


## Gold carried by the living Magpies.
func loot_total() -> int:
	var total := 0
	for t in thieves:
		if is_instance_valid(t):
			total += int((t as Node).get_meta(&"loot", 0))
	return total


## The team being robbed.
func target_team() -> int:
	return _team


## Seconds spent in the current state.
func state_time() -> float:
	return _state_time


## The caravan or worker being struck (null outside a strike).
func victim() -> Node3D:
	return _victim if is_instance_valid(_victim) else null


# ---------------------------------------------------------------- shared rules (static)

## Danger value of one unit for the strike check (5.3): 0 for workers, caravans and the dead.
static func unit_strength(node: Node) -> float:
	if not is_instance_valid(node) or not node is Unit:
		return 0.0
	var u := node as Unit
	if not u.is_alive() or _is_caravan(u):
		return 0.0
	if u.is_in_group(&"magpies"):
		return MAGPIE_STRENGTH
	if u.is_in_group(&"trackers"):
		return TRACKER_STRENGTH
	if u.has_method(&"power"):
		return float(u.call(&"power"))
	return AIMemory.strength_of(u)


## Escort strength of `team` around `pos`: its units within `radius` + its finished towers (150) and keeps
## (250) whose range covers `pos`.
static func escort_strength(tree: SceneTree, team: int, pos: Vector3, radius: float = ESCORT_RADIUS) -> float:
	if tree == null:
		return 0.0
	var total := 0.0
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or int(u.team) != team or not u.is_alive():
			continue
		if _flat(u.global_position, pos) <= radius:
			total += unit_strength(u)
	for node in tree.get_nodes_in_group(&"buildings"):
		var kind := _building_kind(node)
		if kind != &"tower" and kind != &"keep":
			continue
		var b := node as Node3D
		if b == null or int(b.get(&"team")) != team or not _building_ready(b):
			continue
		var bt: BuildingType = b.get(&"building_type")
		var reach := bt.attack_range + 1.0
		if kind == &"keep" and b.has_method(&"target_radius"):
			reach += float(b.call(&"target_radius"))
		if _flat(b.global_position, pos) <= reach:
			total += KEEP_STRENGTH if kind == &"keep" else TOWER_STRENGTH
	return total


## Spot validity (5.2): no `team` soldier, wizard, champion or tracker within 18 m, no `team` tower within
## 20 m, no `team` keep within 25 m.
static func spot_is_valid(tree: SceneTree, team: int, pos: Vector3) -> bool:
	if tree == null:
		return true
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or int(u.team) != team or not u.is_alive() or u.is_worker() or _is_caravan(u):
			continue
		if _flat(u.global_position, pos) <= SPOT_UNIT_RADIUS:
			return false
	for node in tree.get_nodes_in_group(&"buildings"):
		var kind := _building_kind(node)
		if kind != &"tower" and kind != &"keep":
			continue
		var b := node as Node3D
		if b == null or int(b.get(&"team")) != team or not _building_ready(b):
			continue
		var limit := SPOT_KEEP_RADIUS if kind == &"keep" else SPOT_TOWER_RADIUS
		if _flat(b.global_position, pos) <= limit:
			return false
	return true


## Position of `team`'s living keep (Vector3.INF if none).
static func keep_position(tree: SceneTree, team: int) -> Vector3:
	if tree == null:
		return Vector3.INF
	for node in tree.get_nodes_in_group(&"buildings"):
		if _building_kind(node) != &"keep":
			continue
		var b := node as Node3D
		if b and int(b.get(&"team")) == team and (not b.has_method(&"is_alive") or bool(b.call(&"is_alive"))):
			return b.global_position
	return Vector3.INF


static func _building_kind(node: Node) -> StringName:
	if not is_instance_valid(node):
		return &""
	var bt: Variant = node.get(&"building_type")
	if bt is BuildingType:
		return (bt as BuildingType).kind
	return &""


static func _building_ready(b: Node) -> bool:
	if b.has_method(&"is_alive") and not bool(b.call(&"is_alive")):
		return false
	return not b.has_method(&"is_constructed") or bool(b.call(&"is_constructed"))


static func _is_caravan(u: Node) -> bool:
	if u.is_in_group(&"caravans"):
		return true
	var t: Variant = u.get(&"unit_type")
	return t is UnitType and bool((t as UnitType).get(&"is_caravan"))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ---------------------------------------------------------------- frame

func _physics_process(delta: float) -> void:
	if state == &"done" or not _setup_done:
		return
	_clock += delta
	_state_time += delta
	if state == &"striking":
		_strike_time += delta
	if _snatcher != null:
		_snatch_left -= delta
		if _snatch_left <= 0.0:
			_complete_snatch()
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left += TICK
		var t0 := Time.get_ticks_usec()
		_think()
		think_usec_total += Time.get_ticks_usec() - t0
		think_count += 1


func _think() -> void:
	_prune()
	if thieves.is_empty():
		_finish()
		return
	if not _started:
		_begin()
		if state == &"fleeing":
			return
	if state != &"fleeing" and _check_danger():
		return
	match state:
		&"leaving":
			_think_leaving()
		&"lurking":
			_think_lurking()
		&"striking":
			_think_striking()
		&"fleeing":
			_think_fleeing()


func _begin() -> void:
	_started = true
	_doors = _den_doors()
	if _kind == &"road":
		_spots = _route_spots()
	if spot.is_finite():
		_spot_index = _index_of_spot(spot)
		_go_to_spot()
		return
	var s := _choose_spot()
	if s.is_finite():
		spot = s
		_spot_index = _index_of_spot(spot)
		_go_to_spot()
	else:
		_waiting = true
		_retries = 0
		_state_time = 0.0


# ---------------------------------------------------------------- states

func _think_leaving() -> void:
	if _waiting:
		if _state_time < SPOT_RETRY_TIME:
			return
		_state_time = 0.0
		var s := _choose_spot()
		if s.is_finite():
			_waiting = false
			spot = s
			_spot_index = _index_of_spot(spot)
			_go_to_spot()
			return
		_retries += 1
		if _retries >= SPOT_RETRIES:
			_start_flee(false)
		return
	if _fighting:
		return
	_update_sacks()
	if _arrived() or _state_time > _travel_limit:
		state = &"lurking"
		_state_time = 0.0
		for t in thieves:
			if not _sack_runs.has(t.get_instance_id()):
				_move_unit(t, _slot_of(t))


func _think_lurking() -> void:
	if not _fighting:
		var v := _pick_victim()
		if v != null:
			_start_strike(v)
			return
		_update_sacks()
		_keep_cluster()
	if _state_time < LURK_TIME:
		return
	if _kind == &"road" and not _moved_once:
		_moved_once = true
		var next := _next_spot()
		if next.is_finite():
			spot = next
			_spot_index = _index_of_spot(spot)
			_go_to_spot()
			return
	_start_flee(false)


func _think_striking() -> void:
	if not _victim_alive():
		var next: Node3D = null
		if _strike_kind == &"workers" and worker_kills < WORKER_KILLS_MAX and _strike_time < WORKER_STRIKE_TIME:
			next = _pick_worker(false)
		if next == null:
			_end_strike()
			return
		_set_victim(next)
	if _strike_kind == &"caravan":
		if _cargo_of(_victim) <= 0:
			if _cargo_gone_at < 0.0:
				_cargo_gone_at = _strike_time
			if _strike_time - _cargo_gone_at >= FINISH_TIME:
				_end_strike()
				return
		elif _snatcher == null:
			_try_start_snatch()
		if _strike_time >= STRIKE_MAX_TIME:
			_end_strike()
			return
	elif worker_kills >= WORKER_KILLS_MAX or _strike_time >= WORKER_STRIKE_TIME:
		_end_strike()
		return
	# Everyone not answering an attacker hits the victim.
	for t in thieves:
		var u := t as Unit
		var id := u.get_instance_id()
		if _answering.has(id):
			var a: Variant = _answering[id]
			if is_instance_valid(a) and (a as Unit).is_alive():
				continue
			_answering.erase(id)
		if u.attack_target != _victim:
			u.command_attack(_victim)


func _think_fleeing() -> void:
	if _state_time > FLEE_MAX_TIME:
		# D3: the door is unreachable (blocked, off the navmesh): every remaining thief leaves where it stands.
		for t in thieves.duplicate():
			_leave(t as Unit)
		_finish()
		return
	if _flee_calm:
		# Going home after a quiet lurk: pick up sacks on the way; hit on the way -> smoke and run.
		if _attack_force() > 0.0 or not _unit_attackers.is_empty():
			_start_flee(true)
			return
		_update_sacks()
	for t in thieves.duplicate():
		var u := t as Unit
		if _sack_runs.has(u.get_instance_id()):
			continue
		if _flat(u.global_position, _door) <= DOOR_REACH:
			_leave(u)
		elif _state_time > 1.0 and Vector2(u.velocity.x, u.velocity.z).length() < 0.2 and u.can_move():
			# Stopped short (crowding at the door): walk again to a slightly different point.
			var jitter := Vector3(sin(_clock * 7.1), 0.0, cos(_clock * 5.3)) * 0.8
			u.command_move(_door + jitter)
	if thieves.is_empty():
		_finish()


# ---------------------------------------------------------------- danger and fights

# True when the band fled this tick.
func _check_danger() -> bool:
	var dead := _size - _alive_count()
	if _size > 0 and dead > 0 and dead * 2 >= _size:
		_start_flee(true)   # half the band is dead
		return true
	var force := _attack_force()
	if force <= 0.0 and _unit_attackers.is_empty() and _building_attackers == 0:
		if _fighting:
			_stop_fighting()
		return false
	if force > strength():
		_start_flee(true)
		return true
	if _unit_attackers.is_empty():
		# Only buildings hit us: nothing to answer. Lurking under a tower is pointless: go.
		if state == &"lurking":
			_start_flee(true)
			return true
		return false
	_answer_attackers()
	return false


# Strength of what hit the band in the last 3 s: every unit of the attackers' teams within 12 m of the band,
# plus attackers farther out (archers), plus attacking towers (150) and keeps (250). Fills _unit_attackers.
func _attack_force() -> float:
	_unit_attackers.clear()
	_building_attackers = 0
	if _attackers.is_empty():
		return 0.0
	var teams := {}
	var buildings_force := 0.0
	for id in _attackers.keys():
		var e: Dictionary = _attackers[id]
		var n: Variant = e["node"]
		if _clock - float(e["time"]) > ATTACK_MEMORY or not is_instance_valid(n):
			_attackers.erase(id)
			continue
		if n is Unit:
			if (n as Unit).is_alive():
				_unit_attackers.append(n)
				teams[int((n as Unit).team)] = true
		elif n is Node3D and _building_ready(n):
			_building_attackers += 1
			var kind := _building_kind(n)
			buildings_force += KEEP_STRENGTH if kind == &"keep" else (TOWER_STRENGTH if kind == &"tower" else 0.0)
	if teams.is_empty():
		return buildings_force
	var force := buildings_force
	var counted := {}
	var c := _centroid()
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not teams.has(int(u.team)) or not u.is_alive():
			continue
		if _flat(u.global_position, c) <= FORCE_RADIUS:
			force += unit_strength(u)
			counted[u.get_instance_id()] = true
	for a in _unit_attackers:
		if not counted.has((a as Unit).get_instance_id()):
			force += unit_strength(a)
	return force


func _answer_attackers() -> void:
	if state == &"striking":
		# Magpies hit by someone answer him (the snatcher keeps at the caravan); the others stay on the victim.
		for t in thieves:
			var u := t as Unit
			if u == _snatcher:
				continue
			var a := _own_attacker(u)
			# Workers hitting back during a worker strike are simply the next victims (kills stay counted).
			if a != null and a != _victim and not (_strike_kind == &"workers" and a.is_worker()):
				_answering[u.get_instance_id()] = a
				if u.attack_target != a:
					u.command_attack(a)
		return
	if not _fighting:
		_fighting = true
		_fight_origin = spot if state == &"lurking" else _centroid()
		_sack_runs.clear()
	for t in thieves:
		var u := t as Unit
		var id := u.get_instance_id()
		if _flat(u.global_position, _fight_origin) > CHASE_LIMIT:
			_answering.erase(id)
			_move_unit(u, _slot_of(u) if state == &"lurking" else _fight_origin)
			continue
		var a := _own_attacker(u)
		if a == null:
			a = _nearest_attacker(u.global_position)
		if a == null:
			continue
		_answering[id] = a
		if u.attack_target != a:
			u.command_attack(a)


func _stop_fighting() -> void:
	_fighting = false
	_answering.clear()
	for t in thieves:
		var u := t as Unit
		match state:
			&"leaving":
				_move_unit(u, _slot_of(u))
			&"lurking":
				_move_unit(u, _slot_of(u))


# The living unit that last hit `u` (within 3 s), if the band may answer it.
func _own_attacker(u: Unit) -> Unit:
	var e: Variant = _hit_by.get(u.get_instance_id())
	if e == null:
		return null
	var n: Variant = (e as Dictionary)["node"]
	if _clock - float((e as Dictionary)["time"]) > ATTACK_MEMORY or not is_instance_valid(n) or not n is Unit:
		return null
	var a := n as Unit
	return a if _may_answer(a) else null


func _nearest_attacker(from: Vector3) -> Unit:
	var best: Unit = null
	var best_d := INF
	for a in _unit_attackers:
		var au := a as Unit
		if not _may_answer(au):
			continue
		var d := _flat(au.global_position, from)
		if d < best_d:
			best_d = d
			best = au
	return best


# Never answer a worker standing at its home (5.3: home-node workers are never touched).
func _may_answer(a: Unit) -> bool:
	if a == null or not a.is_alive() or int(a.team) == NEUTRAL:
		return false
	return not (a.is_worker() and _is_home_area(a.global_position, int(a.team)))


# ---------------------------------------------------------------- strikes

func _pick_victim() -> Node3D:
	if _kind == &"workers":
		return _pick_worker(true)
	return _pick_caravan()


func _pick_caravan() -> Node3D:
	var c := _centroid()
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"caravans"):
		if not is_instance_valid(node) or not node is Unit:
			continue
		var cv := node as Unit
		if not cv.is_alive() or int(cv.team) != _team or _cargo_of(cv) <= 0:
			continue
		var d := _flat(cv.global_position, c)
		if d <= CARAVAN_STRIKE_RADIUS and d < best_d:
			best_d = d
			best = cv
	if best == null:
		return null
	if escort_strength(get_tree(), _team, best.global_position) > STRIKE_RATIO * float(_alive_count()):
		return null
	return best


# A worker of the target team within 14 m of the target node (never at a home node), carrying crystals first,
# then the nearest. `check_escort`: only for the first victim of a strike.
func _pick_worker(check_escort: bool) -> Node3D:
	var node_pos := _node_pos()
	if not node_pos.is_finite() or _is_home_area(node_pos, _team):
		return null
	var c := _centroid()
	var best: Unit = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or int(u.team) != _team or not u.is_alive() or not u.is_worker():
			continue
		if _flat(u.global_position, node_pos) > WORKER_STRIKE_RADIUS or _is_home_area(u.global_position, _team):
			continue
		var score := _flat(u.global_position, c)
		if int(u.get(&"carried")) > 0:
			score -= 1000.0
		if score < best_score:
			best_score = score
			best = u
	if best == null:
		return null
	if check_escort and escort_strength(get_tree(), _team, best.global_position) > STRIKE_RATIO * float(_alive_count()):
		return null
	return best


func _start_strike(v: Node3D) -> void:
	state = &"striking"
	_state_time = 0.0
	_strike_kind = &"workers" if _kind == &"workers" else &"caravan"
	_strike_time = 0.0
	_cargo_gone_at = -1.0
	_snatcher = null
	_answering.clear()
	_sack_runs.clear()
	_fighting = false
	_set_victim(v)
	strike_started.emit(self, v)
	if _strike_kind == &"workers":
		var net := get_tree().get_first_node_in_group(&"trade_network")
		if net != null and net.has_method(&"record_workers_raided"):
			net.call(&"record_workers_raided", _team, target.get("node"))
		elif net != null and net.has_signal(&"workers_raided"):
			net.emit_signal(&"workers_raided", _team, target.get("node"))


func _set_victim(v: Node3D) -> void:
	_unhook_victim()
	_victim = v
	if v.has_signal(&"died") and not v.is_connected(&"died", _on_victim_died):
		v.connect(&"died", _on_victim_died)
	for t in thieves:
		var u := t as Unit
		if not _answering.has(u.get_instance_id()):
			u.command_attack(v)


func _unhook_victim() -> void:
	if is_instance_valid(_victim) and _victim.is_connected(&"died", _on_victim_died):
		_victim.disconnect(&"died", _on_victim_died)


func _end_strike() -> void:
	_unhook_victim()
	_victim = null
	_snatcher = null
	_start_flee(true)


func _victim_alive() -> bool:
	return is_instance_valid(_victim) and (not _victim.has_method(&"is_alive") or bool(_victim.call(&"is_alive")))


func _on_victim_died(unit: Unit) -> void:
	if _strike_kind != &"workers" or not is_instance_valid(unit) or not unit.is_worker():
		return
	worker_kills += 1
	var carried := int(unit.get(&"carried"))
	if carried > 0:
		var k: Variant = unit.killer
		_give_loot(carried, k if is_instance_valid(k) and thieves.has(k) else null, unit.global_position)


func _try_start_snatch() -> void:
	var best: Unit = null
	var best_gap := INF
	for t in thieves:
		var u := t as Unit
		if _loot_of(u) >= LOOT_MAX or not u.can_act():
			continue
		var gap := _gap(u, _victim)
		if gap <= SNATCH_REACH and gap < best_gap:
			best_gap = gap
			best = u
	if best == null:
		return
	_snatcher = best
	_snatch_left = SNATCH_TIME
	_snatch_damage = 0.0
	var m := best.get_model()
	if m != null and m.has_method(&"play_snatch"):
		m.call(&"play_snatch")
	snatch_started.emit(best, _victim)


func _complete_snatch() -> void:
	var u := _snatcher
	_snatcher = null
	if not is_instance_valid(u) or not u.is_alive() or not _victim_alive() or _strike_kind != &"caravan":
		return
	if _gap(u, _victim) > SNATCH_KEEP_REACH:
		return   # the caravan got away: try again next think
	var amount := mini(_cargo_of(_victim), LOOT_MAX - _loot_of(u))
	if amount <= 0 or not _victim.has_method(&"steal"):
		return
	var before := _loot_of(u)
	var got := int(_victim.call(&"steal", amount, u))
	if got <= 0:
		return
	if _loot_of(u) == before:   # the caravan did not credit the thief itself
		_set_loot(u, before + got)
	_vfx(&"snatch", _victim.global_position, u)
	snatched.emit(u, _victim, got)


func _cargo_of(v: Node) -> int:
	if not is_instance_valid(v):
		return 0
	if v.has_method(&"is_loaded") and not bool(v.call(&"is_loaded")):
		return 0
	var c: Variant = v.get(&"cargo")
	return int(c) if c != null else 0


# Gap between the bodies of a thief and its victim.
func _gap(u: Unit, v: Node3D) -> float:
	return _flat(u.global_position, v.global_position) - Unit.radius_of(v) - u.radius


# ---------------------------------------------------------------- fleeing / home

func _start_flee(smoke: bool) -> void:
	state = &"fleeing"
	_state_time = 0.0
	_flee_calm = not smoke
	_fighting = false
	_answering.clear()
	_sack_runs.clear()
	_snatcher = null
	_waiting = false
	if _doors.is_empty():
		_doors = _den_doors()
	_door = _flee_door(_centroid())
	for t in thieves:
		var u := t as Unit
		if smoke:
			u.apply_status(&"shroud", SHROUD_TIME, true)
			_vfx(&"smoke", u.global_position, null)
		u.command_move(_door)


func _leave(u: Unit) -> void:
	thieves.erase(u)
	_release(u)
	u.set_meta(&"loot", 0)   # fenced
	if u.has_method(&"leave_map"):
		u.call(&"leave_map")
	else:
		u.queue_free()


func _finish() -> void:
	if state == &"done":
		return
	state = &"done"
	_unhook_victim()
	_victim = null
	for t in thieves:
		if is_instance_valid(t):
			_release(t as Unit)
	finished.emit(self)
	queue_free()


# D4 (2026-10-12): the Den door nearest by navmesh path (the guild's nearest_den_door), else straight line.
func _flee_door(from: Vector3) -> Vector3:
	if is_instance_valid(guild) and guild.has_method(&"nearest_den_door"):
		var door: Variant = guild.call(&"nearest_den_door", from)
		if door is Vector3 and (door as Vector3).is_finite():
			return door as Vector3
	return _nearest_door(from)


func _nearest_door(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for d in _doors:
		var dist := _flat(d, from)
		if dist < best_d:
			best_d = dist
			best = d
	return best if best.is_finite() else from


func _den_doors() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if is_instance_valid(guild) and guild.has_method(&"dens"):
		for d in guild.call(&"dens"):
			if is_instance_valid(d) and d is Node3D:
				out.append(_door_of(d as Node3D))
	if out.is_empty():
		for g in get_tree().get_nodes_in_group(&"guilds"):
			if is_instance_valid(g) and g is Node3D and StringName(str(g.get(&"kind"))) == &"den":
				out.append(_door_of(g as Node3D))
	if out.is_empty():
		out.assign(DEFAULT_DEN_DOORS)
	return out


func _door_of(d: Node3D) -> Vector3:
	if d.has_method(&"door_point"):
		return d.call(&"door_point")
	return d.global_position


# ---------------------------------------------------------------- spots

func _go_to_spot() -> void:
	state = &"leaving"
	_state_time = 0.0
	_fighting = false
	_answering.clear()
	_slots.clear()
	var n := thieves.size()
	var far := 0.0
	for i in n:
		var u := thieves[i] as Unit
		var slot := spot
		if n > 1:
			var a := TAU * float(i) / float(n)
			slot += Vector3(cos(a), 0.0, sin(a)) * CLUSTER_RADIUS
		_slots[u.get_instance_id()] = slot
		far = maxf(far, _flat(u.global_position, slot))
		u.command_move(slot)
	_travel_limit = far / 4.0 + 15.0


func _slot_of(u: Unit) -> Vector3:
	return _slots.get(u.get_instance_id(), spot)


func _arrived() -> bool:
	for t in thieves:
		var u := t as Unit
		if _sack_runs.has(u.get_instance_id()):
			continue
		if _flat(u.global_position, _slot_of(u)) > ARRIVE_RADIUS:
			return false
	return true


# Lurking Magpies that drifted (a fight, a sack) walk back to their slot.
func _keep_cluster() -> void:
	for t in thieves:
		var u := t as Unit
		if _sack_runs.has(u.get_instance_id()) or u.attack_target != null:
			continue
		var slot := _slot_of(u)
		if _flat(u.global_position, slot) > 3.0 and Vector2(u.velocity.x, u.velocity.z).length() < 0.2:
			u.command_move(slot)


func _choose_spot() -> Vector3:
	if _kind == &"workers":
		var ws := _worker_spot()
		return ws if ws.is_finite() and _spot_ok(ws) else Vector3.INF
	if _spots.is_empty():
		_spots = _route_spots()
	for s in _spots:
		if _spot_ok(s):
			return s
	return Vector3.INF


# The guild's rule when it has one (same numbers), else ours.
func _spot_ok(s: Vector3) -> bool:
	if is_instance_valid(guild) and guild.has_method(&"is_spot_valid"):
		return bool(guild.call(&"is_spot_valid", _team, s))
	return spot_is_valid(get_tree(), _team, s)


# The next valid road spot after the current one (toward the base first, then the others).
func _next_spot() -> Vector3:
	if _spots.is_empty():
		_spots = _route_spots()
	var n := _spots.size()
	if n < 2:
		return Vector3.INF
	var start := maxi(_spot_index, 0)
	for k in range(1, n):
		var s := _spots[(start + k) % n]
		if _flat(s, spot) > 1.0 and _spot_ok(s):
			return s
	return Vector3.INF


func _index_of_spot(s: Vector3) -> int:
	for i in _spots.size():
		if _flat(_spots[i], s) <= 1.5:
			return i
	return -1


func _route_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var net := get_tree().get_first_node_in_group(&"trade_network")
	var post: Variant = target.get("post")
	if net != null and net.has_method(&"ambush_spots") and is_instance_valid(post):
		for s in net.call(&"ambush_spots", _team, post):
			if s is Vector3:
				out.append(s)
	if out.is_empty():
		for s in target.get("spots", []):
			if s is Vector3:
				out.append(s)
	return out


func _worker_spot() -> Vector3:
	var node: Variant = target.get("node")
	var net := get_tree().get_first_node_in_group(&"trade_network")
	if net != null and net.has_method(&"worker_spot") and is_instance_valid(node):
		var ws: Variant = net.call(&"worker_spot", node)
		if ws is Vector3:
			return ws
	var s: Variant = target.get("spot")
	return s if s is Vector3 else Vector3.INF


func _node_pos() -> Vector3:
	var node: Variant = target.get("node")
	if is_instance_valid(node) and node is Node3D:
		return (node as Node3D).global_position
	return spot


# Within 30 m of `team`'s keep (keep positions cached 10 s).
func _is_home_area(pos: Vector3, team: int) -> bool:
	if _clock - _keep_cache_at > KEEP_CACHE_TIME:
		_keep_cache.clear()
		_keep_cache_at = _clock
	if not _keep_cache.has(team):
		_keep_cache[team] = keep_position(get_tree(), team)
	var k: Vector3 = _keep_cache[team]
	return k.is_finite() and _flat(pos, k) <= REMOTE_DISTANCE


# ---------------------------------------------------------------- loot and sacks

func _loot_of(u: Node) -> int:
	return int(u.get_meta(&"loot", 0))


func _set_loot(u: Unit, amount: int) -> void:
	u.set_meta(&"loot", maxi(0, amount))
	var m := u.get_model()
	if m != null and m.has_method(&"set_carrying"):
		m.call(&"set_carrying", amount > 0)


# Gives `amount` gold to `first` (if any), then to the others nearest to `at`, up to 60 each.
func _give_loot(amount: int, first: Variant, at: Vector3) -> void:
	var order: Array = []
	if first != null:
		order.append(first)
	var rest := thieves.filter(func(t: Variant) -> bool: return t != first and is_instance_valid(t))
	rest.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, at) < _flat(b.global_position, at))
	order.append_array(rest)
	for t in order:
		if amount <= 0:
			break
		var u := t as Unit
		if not u.is_alive():
			continue
		var take := mini(amount, LOOT_MAX - _loot_of(u))
		if take > 0:
			_set_loot(u, _loot_of(u) + take)
			amount -= take


# Sacks within 15 m (of the spot while lurking, else of the band): the nearest Magpie with room walks over.
func _update_sacks() -> void:
	for id in _sack_runs.keys():
		var run: Dictionary = _sack_runs[id]
		var u: Variant = run["thief"]
		var sack: Variant = run["sack"]
		if not is_instance_valid(u) or not (u as Unit).is_alive():
			_sack_runs.erase(id)
			continue
		if not is_instance_valid(sack) or (sack as Node).is_queued_for_deletion():
			_sack_runs.erase(id)
			_resume(u as Unit)
			continue
		if state == &"fleeing" and _clock - float(run.get("start", _clock)) > SACK_RUN_MAX:
			# D3: the sack can't be reached in time: give it up and go home.
			_sacks_given_up[(sack as Node).get_instance_id()] = true
			_sack_runs.erase(id)
			_resume(u as Unit)
			continue
		if _flat((u as Unit).global_position, (sack as Node3D).global_position) <= SACK_REACH:
			_take_sack(u as Unit, sack as Node3D)
			_sack_runs.erase(id)
			_resume(u as Unit)
	var sacks := get_tree().get_nodes_in_group(&"loot_sacks")
	if sacks.is_empty():
		return
	var center := spot if state == &"lurking" else _centroid()
	for s in sacks:
		if not is_instance_valid(s) or not s is Node3D or (s as Node).is_queued_for_deletion():
			continue
		var sack := s as Node3D
		if int(sack.get(&"amount")) <= 0 or _flat(sack.global_position, center) > SACK_RADIUS or _sack_taken(sack) \
				or (state == &"fleeing" and _sacks_given_up.has(sack.get_instance_id())):
			continue
		var best: Unit = null
		var best_d := INF
		for t in thieves:
			var u := t as Unit
			if _sack_runs.has(u.get_instance_id()) or u.attack_target != null:
				continue
			var d := _flat(u.global_position, sack.global_position)
			if d < best_d:
				best_d = d
				best = u
		if best == null:
			return
		_sack_runs[best.get_instance_id()] = {"thief": best, "sack": sack, "start": _clock}
		best.command_move(sack.global_position)


func _sack_taken(sack: Node3D) -> bool:
	for id in _sack_runs:
		if (_sack_runs[id] as Dictionary)["sack"] == sack:
			return true
	return false


func _take_sack(u: Unit, sack: Node3D) -> void:
	if not sack.has_method(&"take"):
		return
	var before := _loot_of(u)
	var got := int(sack.call(&"take", u))
	if got > 0 and _loot_of(u) == before:   # the sack did not credit the thief itself
		_set_loot(u, before + got)


# Back to what the band is doing after a sack.
func _resume(u: Unit) -> void:
	if state == &"fleeing":
		u.command_move(_door)
	elif state == &"leaving" or state == &"lurking":
		u.command_move(_slot_of(u))


func _drop_sack(u: Unit, amount: int) -> void:
	if amount < 1 or loot_sack_script == null:
		return
	var parent := u.get_parent()
	if parent == null:
		parent = get_tree().current_scene
	if parent == null or not _script_has(loot_sack_script, &"spawn"):
		return
	loot_sack_script.call(&"spawn", parent, u.global_position, amount)


static func _script_has(script: Script, method: StringName) -> bool:
	for m in script.get_script_method_list():
		if StringName(m.get("name", "")) == method:
			return true
	return false


# ---------------------------------------------------------------- thieves

func _adopt(u: Unit) -> void:
	thieves.append(u)
	if not u.has_meta(&"loot"):
		u.set_meta(&"loot", 0)
	var on_hit := _on_thief_damaged.bind(u)   # the bound callable is what is connected (review L11)
	if not u.damage_taken.is_connected(on_hit):
		u.damage_taken.connect(on_hit)
	if not u.died.is_connected(_on_thief_died):
		u.died.connect(_on_thief_died)
	if u.has_method(&"has_neutral_leash") and bool(u.call(&"has_neutral_leash")):
		push_warning("ThiefBand: %s has a neutral leash (UnitType.neutral_leash should be false)" % u.name)


func _release(u: Unit) -> void:
	if not is_instance_valid(u):
		return
	for c in u.damage_taken.get_connections():
		if (c["callable"] as Callable).get_object() == self:
			u.damage_taken.disconnect(c["callable"])
	if u.died.is_connected(_on_thief_died):
		u.died.disconnect(_on_thief_died)


func _prune() -> void:
	for i in range(thieves.size() - 1, -1, -1):
		var t: Variant = thieves[i]
		if not is_instance_valid(t) or not (t as Unit).is_alive() or (t as Node).is_queued_for_deletion():
			thieves.remove_at(i)


func _alive_count() -> int:
	var n := 0
	for t in thieves:
		if is_instance_valid(t) and (t as Unit).is_alive():
			n += 1
	return n


func _centroid() -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for t in thieves:
		if is_instance_valid(t):
			sum += (t as Node3D).global_position
			n += 1
	return sum / float(n) if n > 0 else spot


func _move_unit(u: Unit, pos: Vector3) -> void:
	if pos.is_finite():
		u.command_move(pos)


func _on_thief_damaged(amount: float, attacker: Node3D, thief: Unit) -> void:
	if thief == _snatcher:
		_snatch_damage += amount
		if _snatch_damage >= SNATCH_BREAK_DAMAGE:
			_snatcher = null   # the snatch is broken; another try on the next think
			if thief.has_method(&"cancel_snatch"):
				thief.call(&"cancel_snatch")   # stop the 1.5 s snatch pose on the model
	if amount <= 0.0 or attacker == null or not is_instance_valid(attacker) or attacker == thief:
		return
	var at: Variant = attacker.get(&"team")
	if at == null or int(at) == NEUTRAL:
		return
	var e := {"node": attacker, "time": _clock}
	_attackers[attacker.get_instance_id()] = e
	if attacker is Unit:
		_hit_by[thief.get_instance_id()] = e


func _on_thief_died(unit: Unit) -> void:
	if unit == _snatcher:
		_snatcher = null
	var loot := _loot_of(unit)
	unit.set_meta(&"loot", 0)
	_drop_sack(unit, loot)


func _vfx(id: StringName, at: Vector3, tgt: Variant) -> void:
	if not is_inside_tree():
		return
	var v := get_tree().get_first_node_in_group(&"trade_vfx")
	if v != null and v.has_method(&"play"):
		v.call(&"play", id, at, tgt)
