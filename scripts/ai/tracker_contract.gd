class_name TrackerContract
extends Node
## A Greywater Lodge contract (docs/design/market-trade.md 6.1 / 6.2, task 10.A2): the brain of the trackers
## a team hired with gold. Trackers are autonomous (never commandable): only this node orders them, with the
## normal command_move / command_attack / command_stop.
##
## Outriders (2 trackers, 180 s): each tracker shadows one own caravan, 4 m behind it (loaded caravans first,
## farthest from home first, then the ones on the longest route; never two trackers on one caravan; re-picked
## every 2 s). It shoots a Magpie within 12 m of any own caravan when the Magpie is inside its 15 m leash
## around its caravan, and anything that hit its caravan (or itself) in the last 3 s. It never goes more than
## 15 m from its caravan (checked every frame while fighting).
## Sweep (3 trackers, 120 s): walk the team's spots in order (W spots of remote nodes with workers, then the
## road spots of the busiest route, then every other spot), attack every Magpie within 15 m, chase a Magpie
## carrying loot up to 30 m from where the fight began; after the last spot the plan is rebuilt and starts over.
## Both: trackers only fight Magpies and units that attacked them or their charge in the last 3 s (they never
## start fights with enemy soldiers). At the end every tracker leaves the map where it stands
## (`Unit.leave_map()`, 10.C6), then `ended(contract)` is emitted and the contract frees itself.
## The contract also ends early when all its trackers are dead or gone.
## Thinks every 0.5 s, contracts staggered by 0.1 s. Other step-10 classes (HuntersGuild, TradeNetwork,
## Caravan, Market, ThiefBand) are reached through groups, get() and has_method() only.

signal ended(contract: TrackerContract)

const OUTRIDERS := &"outriders"
const SWEEP := &"sweep"

const TICK := 0.5
const STAGGER := 0.1
const STAGGER_SLOTS := 5
const HIT_MEMORY := 3.0          ## Attackers of a tracker / its caravan are answered this long.
# Outriders
const REPICK := 2.0
const FOLLOW_BEHIND := 4.0
const GUARD_RADIUS := 12.0       ## A Magpie this close to any own caravan is fair game.
const LEASH := 15.0              ## Never farther than this from its caravan.
const LEASH_GUARD := 0.6         ## The per-frame guard pulls a fighting tracker back this much before the leash.
const ATTACKER_REACH := 20.0     ## Attackers of the caravan are shot up to this far from it (leash + range - 2).
const LEASH_BLOCK := 1.5         ## After a leash pull, that target is not re-engaged (unless in range) this long.
const REORDER_DIST := 1.0
const MOVING_SPEED := 0.3
# Sweep
const SWEEP_RADIUS := 15.0
const LOOT_CHASE := 30.0
const JOIN_RADIUS := 30.0        ## An idle sweeper joins a teammate's fight this close.
const CHASE_BLOCK := 6.0         ## A Magpie let go at the chase limit is not re-engaged this long.
const SPOT_ARRIVE := 3.5
const SPOT_DWELL := 3.0
const SPOT_MERGE := 3.0
const SPOT_TIMEOUT := 60.0       ## A spot nobody can reach is skipped after this long.
const FORMATION: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(-1.8, 0.0, 1.4), Vector3(1.8, 0.0, 1.4),
		Vector3(0.0, 0.0, -2.0)]
const TRADE_SECONDS := 180.0

enum Order { NONE, MOVE, ATTACK, STOP }

@export var enabled := true      ## False: no automatic ticks (tests call think_now()); the clock still runs.
## Perf counters (read only): microseconds spent in automatic ticks by every contract, and the tick count.
static var usec_total := 0
static var ticks := 0
static var _slots := 0

var guild: Node = null           ## The HuntersGuild that sold the contract (may be null in tests).
var team: int = 0
var kind: StringName = &""
var trackers: Array = []         ## Every tracker hired (dead or gone ones stay; check is_instance_valid).
var duration := 0.0

var _left := 0.0
var _now := 0.0
var _tick_left := 0.0
var _repick_left := 0.0
var _ended := false
var _charges := {}               # tracker iid -> caravan (Unit)
var _orders := {}                # tracker iid -> {order, point, target}
var _hits := {}                  # victim iid -> {attacker iid -> [attacker, time]}
var _watched := {}               # victim iid -> [node, callable]
var _headings := {}              # caravan iid -> Vector3 (last walking direction)
var _blocked := {}               # tracker iid -> [target, until]
var _gone := {}                  # tracker iid -> true once it left the map (fading out)
# Sweep
var _spots: Array[Vector3] = []
var _spot_index := 0
var _spot_since := 0.0
var _spot_arrived_at := -1.0
var _loops := 0
var _engage := {}                # tracker iid -> {target, anchor}


func _init() -> void:
	add_to_group(&"tracker_contracts")


func _ready() -> void:
	var slot := _slots
	_slots += 1
	_tick_left = STAGGER * float(slot % STAGGER_SLOTS)


## Called by the HuntersGuild right after spawning the trackers (before or after adding the contract to the
## tree). `trackers` are Units of `team`.
func setup(p_guild: Node, p_team: int, p_kind: StringName, p_trackers: Array, p_duration: float) -> void:
	guild = p_guild
	team = p_team
	kind = p_kind
	duration = p_duration
	_left = p_duration
	trackers = []
	for t: Variant in p_trackers:
		if t == null or not is_instance_valid(t) or not t is Unit or not (t as Unit).is_alive():
			continue
		var u := t as Unit
		trackers.append(u)
		if not u.is_in_group(&"trackers"):
			u.add_to_group(&"trackers")
		u.set_meta(&"contract", self)
		_watch(u)
		if u.has_signal(&"left_map"):   # 10.C6
			u.connect(&"left_map", _on_tracker_left, CONNECT_ONE_SHOT)
	_repick_left = 0.0
	_spots.clear()
	_spot_index = 0


# ---------------------------------------------------------------- public (guild, UI, tests)

func time_left() -> float:
	return maxf(0.0, _left)


func is_ended() -> bool:
	return _ended


## The trackers still alive and on the map.
func living_trackers() -> Array:
	var out: Array = []
	for t: Variant in trackers:
		if _alive(t) and not _gone.has((t as Node).get_instance_id()):
			out.append(t)
	return out


## Sweep: how many times the spot plan was walked to its end and started over.
func loops_done() -> int:
	return _loops


## Outriders: the caravan `tracker` shadows (null for a spare tracker or a Sweep contract).
func charge_of(tracker: Node) -> Node3D:
	if tracker == null or not is_instance_valid(tracker):
		return null
	var c: Variant = _charges.get(tracker.get_instance_id())
	return c as Node3D if _alive(c) else null


## Sweep: the spots of the current loop, in walking order (a copy), and the index of the next one.
func planned_spots() -> Array[Vector3]:
	return _spots.duplicate()


func current_spot_index() -> int:
	return _spot_index


func display_name() -> String:
	return "Outriders" if kind == OUTRIDERS else "Sweep"


## One line for a tracker's inspect panel: what it does now.
func status_text(tracker: Node) -> String:
	if _ended:
		return "Leaving"
	if tracker == null or not is_instance_valid(tracker):
		return ""
	var o: Dictionary = _orders.get(tracker.get_instance_id(), {})
	if int(o.get("order", Order.NONE)) == Order.ATTACK:
		return "Fighting"
	if kind == OUTRIDERS:
		return "Escorting a caravan" if charge_of(tracker) != null else "Waiting for a caravan"
	if _spots.is_empty():
		return "Sweeping"
	return "Sweeping (spot %d / %d)" % [mini(_spot_index + 1, _spots.size()), _spots.size()]


## Ends the contract now: every tracker leaves the map where it stands, `ended` is emitted once, the node frees
## itself. Safe to call twice.
func end_contract() -> void:
	if _ended:
		return
	_ended = true
	set_physics_process(false)
	for t: Variant in trackers:
		if not _alive(t) or _gone.has((t as Node).get_instance_id()):
			continue
		var u := t as Unit
		_gone[u.get_instance_id()] = true
		if u.has_signal(&"left_map") and u.is_connected(&"left_map", _on_tracker_left):
			u.disconnect(&"left_map", _on_tracker_left)
		u.command_stop()
		if u.has_method(&"leave_map"):
			u.call(&"leave_map")
		else:   # 10.C6 not merged yet: remove it quietly (no death, no XP)
			u.remove_from_group(&"units")
			u.queue_free()
	_unwatch_all()
	ended.emit(self)
	if is_inside_tree():
		queue_free()


## Runs one 0.5 s think now (tests, debug).
func think_now() -> void:
	if not _ended:
		_tick()


## Where the contract will send its trackers first (HuntersGuild picks the Lodge nearer this point):
## Outriders = the first caravan they would escort, Sweep = the first spot. Vector3.INF when unknown.
static func first_destination(tree: SceneTree, p_team: int, p_kind: StringName) -> Vector3:
	if tree == null:
		return Vector3.INF
	if p_kind == OUTRIDERS:
		var ranked := _rank_caravans(tree, _caravans_of(tree, p_team))
		return (ranked[0] as Node3D).global_position if not ranked.is_empty() else Vector3.INF
	var start := _keep_position(tree, p_team)
	var plan := _plan_spots(tree, p_team, start if start.is_finite() else Vector3.ZERO)
	return plan[0] if not plan.is_empty() else Vector3.INF


# ---------------------------------------------------------------- clock

func _physics_process(delta: float) -> void:
	if _ended:
		return
	_now += delta
	_left -= delta
	if _left <= 0.0:
		end_contract()
		return
	if not enabled:
		return
	if kind == OUTRIDERS:
		_leash_guard()
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	if _tick_left < 0.0:
		_tick_left = TICK
	var t0 := Time.get_ticks_usec()
	_tick()
	usec_total += Time.get_ticks_usec() - t0
	ticks += 1


func _tick() -> void:
	var living := living_trackers()
	if living.is_empty():
		end_contract()
		return
	_forget_old_hits()
	if kind == OUTRIDERS:
		_tick_outriders(living)
	else:
		_tick_sweep(living)


# ---------------------------------------------------------------- Outriders

func _tick_outriders(living: Array) -> void:
	var caravans := _caravans_of(get_tree(), team)
	for c: Unit in caravans:
		var v := Vector3(c.velocity.x, 0.0, c.velocity.z)
		if v.length() > MOVING_SPEED:
			_headings[c.get_instance_id()] = v.normalized()
	_repick_left -= TICK
	var lost := false
	for t: Unit in living:
		var c: Variant = _charges.get(t.get_instance_id())
		if c != null and not _alive(c):
			lost = true
	if _repick_left <= 0.0 or lost:
		_repick_left = REPICK
		_repick(living, caravans)
	for t: Unit in living:
		var c := charge_of(t) as Unit
		var target := _outrider_target(t, c, caravans)
		if target != null:
			_order_attack(t, target)
		elif c != null:
			_order_move(t, _behind_point(c, t))
		else:
			_order_stop(t)


## Keeps a tracker's caravan while it is still among the top picks; free picks go to the nearest free tracker.
func _repick(living: Array, caravans: Array) -> void:
	var ranked := _rank_caravans(get_tree(), caravans)
	var chosen := ranked.slice(0, living.size())
	var new_charges := {}
	var taken := {}
	var free: Array = []
	for t: Unit in living:
		var c: Variant = _charges.get(t.get_instance_id())
		if _alive(c) and chosen.has(c) and not taken.has((c as Node).get_instance_id()):
			new_charges[t.get_instance_id()] = c
			taken[(c as Node).get_instance_id()] = true
		else:
			free.append(t)
	for c: Unit in chosen:
		if taken.has(c.get_instance_id()) or free.is_empty():
			continue
		var best: Unit = null
		var best_d := INF
		for t: Unit in free:
			var d := _flat(t.global_position, c.global_position)
			if d < best_d:
				best_d = d
				best = t
		free.erase(best)
		new_charges[best.get_instance_id()] = c
		taken[c.get_instance_id()] = true
		_watch(c)
	_charges = new_charges


## Attackers of its caravan, then its own attackers, then Magpies near any own caravan; the current target is
## kept while it stays valid. Null while the tracker is outside its leash (it walks back first).
func _outrider_target(t: Unit, c: Unit, caravans: Array) -> Node3D:
	var center := c.global_position if c != null else t.global_position
	if c != null and _flat(t.global_position, center) > LEASH:
		return null
	var cur: Variant = (_orders.get(t.get_instance_id(), {}) as Dictionary).get("target")
	var cands: Array = []
	if c != null:
		for a: Unit in _recent_attackers(c):
			if _flat(a.global_position, center) <= ATTACKER_REACH and _engageable(t, a):
				cands.append(a)
	var own_attackers: Array = []
	for a: Unit in _recent_attackers(t):
		if _flat(a.global_position, center) <= ATTACKER_REACH and _engageable(t, a):
			own_attackers.append(a)
	var magpies: Array = []
	for m: Unit in _magpies(t):
		if _flat(m.global_position, center) > LEASH or not _engageable(t, m):
			continue
		for cv: Unit in caravans:
			if _flat(m.global_position, cv.global_position) <= GUARD_RADIUS:
				magpies.append(m)
				break
	for group: Array in [cands, own_attackers, magpies]:
		if _alive(cur) and group.has(cur):
			return cur as Node3D
	for group: Array in [cands, own_attackers, magpies]:
		if not group.is_empty():
			return _nearest(t.global_position, group)
	return null


## 4 m behind the caravan's walking direction; a caravan that never walked keeps the tracker on its side.
func _behind_point(c: Unit, t: Unit) -> Vector3:
	var h: Variant = _headings.get(c.get_instance_id())
	var dir := Vector3.ZERO
	var v := Vector3(c.velocity.x, 0.0, c.velocity.z)
	if v.length() > MOVING_SPEED:
		# aim where the spot will be at the next think, so the tracker does not trail a walking caravan
		return c.global_position + v * TICK - v.normalized() * FOLLOW_BEHIND
	if h != null:
		dir = -(h as Vector3)
	else:
		dir = t.global_position - c.global_position
		dir.y = 0.0
		if dir.length() < 0.1:
			dir = Vector3(0.0, 0.0, 1.0)
		dir = dir.normalized()
	return c.global_position + dir * FOLLOW_BEHIND


## Every frame, cheap: a fighting outrider about to pass its leash is pulled back to its caravan.
func _leash_guard() -> void:
	for id: int in _charges:
		var c: Variant = _charges[id]
		var o: Dictionary = _orders.get(id, {})
		if int(o.get("order", Order.NONE)) != Order.ATTACK or not _alive(c):
			continue
		var t := instance_from_id(id) as Unit
		if t == null or not _alive(t):
			continue
		if _flat(t.global_position, (c as Node3D).global_position) > LEASH - LEASH_GUARD:
			_blocked[id] = [o.get("target"), _now + LEASH_BLOCK]
			_order_move(t, _behind_point(c as Unit, t))


# ---------------------------------------------------------------- Sweep

func _tick_sweep(living: Array) -> void:
	if _spots.is_empty() or _spot_index >= _spots.size():
		_rebuild_spots(living)
	var fighting: Array = []
	var anchors := {}   # target iid -> where that fight began (joiners share it: the 30 m chase stays one chase)
	var idle: Array = []
	for t: Unit in living:
		var target := _sweep_target(t)
		if target != null:
			_order_attack(t, target)
			if not anchors.has(target.get_instance_id()):
				fighting.append(target)
				anchors[target.get_instance_id()] = (_engage[t.get_instance_id()] as Dictionary)["anchor"]
		else:
			idle.append(t)
	var walkers: Array = []
	for t: Unit in idle:
		var join: Node3D = null
		if not fighting.is_empty():
			join = _nearest(t.global_position, fighting)
			if join != null and (_flat(t.global_position, join.global_position) > JOIN_RADIUS or _is_blocked(t, join)):
				join = null
		if join != null:
			_engage[t.get_instance_id()] = {"target": join, "anchor": anchors[join.get_instance_id()]}
			_order_attack(t, join)
		else:
			walkers.append(t)
	if walkers.is_empty():
		return
	if _spots.is_empty():
		for t: Unit in walkers:
			_order_stop(t)
		return
	var spot := _spots[_spot_index]
	var arrived := true
	for i in walkers.size():
		var t := walkers[i] as Unit
		var p := spot + FORMATION[i % FORMATION.size()]
		_order_move(t, p)
		if _flat(t.global_position, p) > SPOT_ARRIVE:
			arrived = false
	if arrived and fighting.is_empty():
		if _spot_arrived_at < 0.0:
			_spot_arrived_at = _now
		if _now - _spot_arrived_at >= SPOT_DWELL:
			_next_spot()
	elif _now - _spot_since > SPOT_TIMEOUT and fighting.is_empty():
		_next_spot()


func _next_spot() -> void:
	_spot_index += 1
	_spot_since = _now
	_spot_arrived_at = -1.0
	# the loop restarts at the next tick with a fresh plan (_spot_index == size)


func _rebuild_spots(living: Array) -> void:
	var start := Vector3.ZERO
	for t: Unit in living:
		start += t.global_position
	start /= float(maxi(1, living.size()))
	if _spot_index > 0:
		_loops += 1
	_spots = _plan_spots(get_tree(), team, start)
	_spot_index = 0
	_spot_since = _now
	_spot_arrived_at = -1.0


## Keeps the current target while it stays within 15 m of where the fight began (30 m for a Magpie carrying
## loot; attackers while they keep attacking), else its own attackers, else the nearest Magpie within 15 m
## (loot carriers first).
func _sweep_target(t: Unit) -> Node3D:
	var id := t.get_instance_id()
	var attackers := _recent_attackers(t)
	var e: Dictionary = _engage.get(id, {})
	var cur: Variant = e.get("target")
	if _alive(cur):
		var cn := cur as Node3D
		var anchor: Vector3 = e.get("anchor", t.global_position)
		var limit := LOOT_CHASE if _loot(cn) > 0 else SWEEP_RADIUS
		if attackers.has(cn) or (cn.is_in_group(&"magpies") and _flat(cn.global_position, anchor) <= limit):
			return cn
		_blocked[id] = [cn, _now + CHASE_BLOCK]   # out of the chase limit: let it go for a while
	_engage.erase(id)
	var pick: Node3D = null
	if not attackers.is_empty():
		pick = _nearest(t.global_position, attackers)
	else:
		var loot_near: Array = []
		var near: Array = []
		var b: Variant = _blocked.get(id)
		var blocked_target: Variant = b[0] if b != null and _now < float(b[1]) else null
		for m: Unit in _magpies(t):
			if m == blocked_target:
				continue
			if _flat(m.global_position, t.global_position) <= SWEEP_RADIUS:
				near.append(m)
				if _loot(m) > 0:
					loot_near.append(m)
		pick = _nearest(t.global_position, loot_near if not loot_near.is_empty() else near)
	if pick != null:
		_engage[id] = {"target": pick, "anchor": t.global_position}
	return pick


## W spots of remote nodes with workers, the road spots of the busiest route, then every other spot of the team
## (other routes, remote nodes without workers). Nearest-neighbour order inside each group, duplicates merged.
static func _plan_spots(tree: SceneTree, p_team: int, start: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var net := tree.get_first_node_in_group(&"trade_network")
	if net == null:
		return out
	var w_busy: Array = []
	var w_quiet: Array = []
	if net.has_method(&"remote_nodes") and net.has_method(&"worker_spot"):
		for n: Variant in net.call(&"remote_nodes", p_team):
			if n == null or not is_instance_valid(n):
				continue
			var s: Variant = net.call(&"worker_spot", n)
			if not s is Vector3 or not (s as Vector3).is_finite():
				continue
			var workers: Variant = net.call(&"workers_at", p_team, n) if net.has_method(&"workers_at") else []
			if workers is Array and not (workers as Array).is_empty():
				w_busy.append(s)
			else:
				w_quiet.append(s)
	var busiest_road: Array = []
	var other_roads: Array = []
	if net.has_method(&"posts") and net.has_method(&"ambush_spots"):
		var posts: Array = []
		for p: Variant in net.call(&"posts"):
			if p != null and is_instance_valid(p):
				posts.append(p)
		var busiest: Variant = _busiest_post(tree, net, p_team, posts)
		for p: Variant in posts:
			var spots: Variant = net.call(&"ambush_spots", p_team, p)
			if not spots is Array:
				continue
			if p == busiest:
				busiest_road.append_array(spots as Array)
			else:
				other_roads.append_array(spots as Array)
	var at := start
	for group: Array in [w_busy, busiest_road, other_roads + w_quiet]:
		var left: Array = []
		for s: Variant in group:
			var v := s as Vector3
			var dup := false
			for o: Vector3 in out:
				if _flat(o, v) < SPOT_MERGE:
					dup = true
					break
			for o: Vector3 in left:
				if _flat(o, v) < SPOT_MERGE:
					dup = true
					break
			if not dup:
				left.append(v)
		while not left.is_empty():
			var best := 0
			for i in left.size():
				if _flat(at, left[i]) < _flat(at, left[best]):
					best = i
			at = left[best]
			out.append(at)
			left.remove_at(best)
	return out


## The post with the most trips of the team in the last 180 s; ties (and no trips) go to the own Bazaar's route.
static func _busiest_post(tree: SceneTree, net: Node, p_team: int, posts: Array) -> Variant:
	var market_post: Variant = null
	var market := _market_of(tree, p_team)
	if market != null:
		market_post = market.get(&"route_post")
	var best: Variant = null
	var best_trips := 0
	if net.has_method(&"trips"):
		for p: Variant in posts:
			var n := int(net.call(&"trips", p_team, p, TRADE_SECONDS))
			if n > best_trips or (n == best_trips and n > 0 and p == market_post):
				best_trips = n
				best = p
	if best == null:
		best = market_post if market_post != null and posts.has(market_post) else (posts[0] if not posts.is_empty() else null)
	return best


# ---------------------------------------------------------------- orders

func _order_attack(t: Unit, target: Node3D) -> void:
	var id := t.get_instance_id()
	var o: Dictionary = _orders.get(id, {})
	if int(o.get("order", Order.NONE)) == Order.ATTACK and o.get("target") == target and t.attack_target == target:
		return
	t.command_attack(target)
	_orders[id] = {"order": Order.ATTACK, "point": Vector3.INF, "target": target}


func _order_move(t: Unit, point: Vector3) -> void:
	var id := t.get_instance_id()
	var o: Dictionary = _orders.get(id, {})
	if int(o.get("order", Order.NONE)) == Order.MOVE and (o.get("point", Vector3.INF) as Vector3).distance_to(point) < REORDER_DIST:
		return
	if _flat(t.global_position, point) < REORDER_DIST:
		if int(o.get("order", Order.NONE)) != Order.STOP:
			_order_stop(t)
		return
	t.command_move(point)
	_orders[id] = {"order": Order.MOVE, "point": point, "target": null}


func _order_stop(t: Unit) -> void:
	var id := t.get_instance_id()
	var o: Dictionary = _orders.get(id, {})
	if int(o.get("order", Order.NONE)) == Order.STOP:
		return
	t.command_stop()
	_orders[id] = {"order": Order.STOP, "point": Vector3.INF, "target": null}


func _is_blocked(t: Unit, target: Node3D) -> bool:
	var b: Variant = _blocked.get(t.get_instance_id())
	return b != null and _now < float(b[1]) and b[0] == target


## False for a target the leash guard just pulled this tracker away from (unless it is already in range).
func _engageable(t: Unit, target: Node3D) -> bool:
	var b: Variant = _blocked.get(t.get_instance_id())
	if b == null:
		return true
	if _now >= float(b[1]):
		_blocked.erase(t.get_instance_id())
		return true
	if b[0] != target:
		return true
	return _flat(t.global_position, target.global_position) <= t.attack_range + t.radius + Unit.radius_of(target)


# ---------------------------------------------------------------- hits (the 3 s memory)

func _watch(victim: Unit) -> void:
	var id := victim.get_instance_id()
	if _watched.has(id):
		return
	var cb := _on_hit.bind(id)
	victim.damage_taken.connect(cb)
	_watched[id] = [victim, cb]


func _unwatch_all() -> void:
	for id: int in _watched:
		var pair: Array = _watched[id]
		var n: Variant = pair[0]
		if n != null and is_instance_valid(n) and (n as Object).is_connected(&"damage_taken", pair[1]):
			(n as Object).disconnect(&"damage_taken", pair[1])
	_watched.clear()


func _exit_tree() -> void:
	if _ended:
		_unwatch_all()


func _on_tracker_left(unit: Node) -> void:
	if unit != null and is_instance_valid(unit):
		_gone[unit.get_instance_id()] = true


func _on_hit(_amount: float, attacker: Node3D, victim_id: int) -> void:
	if attacker == null or not is_instance_valid(attacker) or not attacker is Unit:
		return   # buildings (towers) are never chased
	var at: Variant = attacker.get(&"team")
	if at != null and int(at) == team:
		return
	var d: Dictionary = _hits.get(victim_id, {})
	d[attacker.get_instance_id()] = [attacker, _now]
	_hits[victim_id] = d


## Units that hit `victim` in the last 3 s and are still alive.
func _recent_attackers(victim: Node) -> Array:
	var out: Array = []
	var d: Dictionary = _hits.get(victim.get_instance_id(), {})
	for aid: int in d:
		var pair: Array = d[aid]
		if _now - float(pair[1]) <= HIT_MEMORY and _alive(pair[0]):
			out.append(pair[0])
	return out


func _forget_old_hits() -> void:
	for vid: int in _hits.keys():
		var d: Dictionary = _hits[vid]
		for aid: int in d.keys():
			var pair: Array = d[aid]
			if _now - float(pair[1]) > HIT_MEMORY or not _alive(pair[0]):
				d.erase(aid)
		if d.is_empty():
			_hits.erase(vid)


# ---------------------------------------------------------------- lookups

## Living own caravans (group "caravans").
static func _caravans_of(tree: SceneTree, p_team: int) -> Array:
	var out: Array = []
	for n: Node in tree.get_nodes_in_group(&"caravans"):
		if n is Unit and int((n as Unit).team) == p_team and (n as Unit).is_alive():
			out.append(n)
	return out


## Loaded caravans farthest from home first, then the others on the longest route first.
static func _rank_caravans(tree: SceneTree, caravans: Array) -> Array:
	var net := tree.get_first_node_in_group(&"trade_network")
	var loaded: Array = []
	var empty: Array = []
	for c: Unit in caravans:
		var is_loaded := false
		if c.has_method(&"is_loaded"):
			is_loaded = bool(c.call(&"is_loaded"))
		else:
			var cargo: Variant = c.get(&"cargo")
			is_loaded = cargo != null and int(cargo) > 0
		if is_loaded:
			loaded.append([_home_distance(tree, c), c.get_instance_id(), c])
		else:
			empty.append([_route_length(net, c), c.get_instance_id(), c])
	var by_key := func(a: Array, b: Array) -> bool:
		return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1])
	loaded.sort_custom(by_key)
	empty.sort_custom(by_key)
	var out: Array = []
	for e: Array in loaded + empty:
		out.append(e[2])
	return out


static func _home_distance(tree: SceneTree, c: Unit) -> float:
	var home: Variant = c.get(&"home_market")
	if home != null and is_instance_valid(home) and home is Node3D:
		return _flat(c.global_position, (home as Node3D).global_position)
	var keep := _keep_position(tree, int(c.team))
	return _flat(c.global_position, keep) if keep.is_finite() else 0.0


static func _route_length(net: Node, c: Unit) -> float:
	var post: Variant = c.get(&"route_post")
	var home: Variant = c.get(&"home_market")
	if post == null or not is_instance_valid(post) or not post is Node3D:
		return 0.0
	if home == null or not is_instance_valid(home) or not home is Node3D:
		return _flat(c.global_position, (post as Node3D).global_position)
	if net != null and net.has_method(&"route_length"):
		return float(net.call(&"route_length", home, post))
	return _flat((home as Node3D).global_position, (post as Node3D).global_position)


static func _market_of(tree: SceneTree, p_team: int) -> Node3D:
	for b: Node in tree.get_nodes_in_group(&"buildings"):
		if not b is Node3D or b.get(&"team") == null or int(b.get(&"team")) != p_team:
			continue
		var bt: Variant = b.get(&"building_type")
		if bt is BuildingType and (bt as BuildingType).kind == &"market" \
				and (not b.has_method(&"is_alive") or bool(b.call(&"is_alive"))):
			return b as Node3D
	return null


static func _keep_position(tree: SceneTree, p_team: int) -> Vector3:
	for b: Node in tree.get_nodes_in_group(&"buildings"):
		if b is Keep and int((b as Keep).team) == p_team and (b as Keep).is_alive():
			return (b as Keep).global_position
	return Vector3.INF


## Living Magpies (group "magpies") that are enemies of `t`.
func _magpies(t: Unit) -> Array:
	var out: Array = []
	for m: Node in get_tree().get_nodes_in_group(&"magpies"):
		if m is Unit and (m as Unit).is_alive() and t.is_enemy_of(m as Node3D):
			out.append(m)
	return out


static func _loot(n: Node) -> int:
	return int(n.get_meta(&"loot", 0)) if n != null and is_instance_valid(n) else 0


static func _nearest(from: Vector3, nodes: Array) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for n: Variant in nodes:
		if not _alive(n):
			continue
		var d := _flat(from, (n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	return best


## Untyped on purpose: freed nodes may be passed.
static func _alive(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and n is Node3D and (n as Node).is_inside_tree() \
			and (not (n as Object).has_method(&"is_alive") or bool((n as Object).call(&"is_alive")))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
