class_name Caravan
extends Unit
## A trade caravan (UnitType.is_caravan; built by Worker.make_unit). docs/design/market-trade.md 4.2-4.3, 5.4.
## The loop: load 2 s at its Bazaar's spawn point -> walk the route (TradeNetwork.route_points: road nodes,
## then the post door) -> trade 2 s at the door (cargo = the route value in gold, locked now) -> walk the
## same waypoints back at loaded speed (modifier `cargo:load`, move_speed -0.4) -> deliver at its Bazaar
## (GoldBank.add(cargo, &"trade"), TradeNetwork.record_delivery) -> loop.
## - Before the posts open (4:00) it waits at the Bazaar.
## - A post held by the enemy: it stops at the last waypoint before the door (near route: 20 m before the door
##   on its leg), waits up to 45 s, then goes home empty.
## - Its Bazaar destroyed: it waits at the keep and delivers to the next completed Bazaar of its team.
## - Move / Stop / Hold / attack orders keep the cargo and leave it idle. It never fights.
## - Dies loaded: drops a LootSack with 50 % of the cargo.
## Step-10 classes of other tasks (TradeNetwork, GoldBank, LootSack, Market, TradeVfx) are reached through
## groups, has_method() and a load guard only.

signal cargo_changed(caravan: Caravan, amount: int)
signal delivered(caravan: Caravan, amount: int)
signal robbed(caravan: Caravan, amount: int, thief: Node3D)

const LOAD_TIME := 2.0
const TRADE_TIME := 2.0
const HELD_WAIT := 45.0             ## Seconds at the hold point before going home empty.
const HELD_NEAR_BACKOFF := 20.0     ## Near route (no waypoint before the door): wait this far before the door.
const LOOT_RATIO := 0.5             ## Share of the cargo dropped as a loot sack on death (rounded down).
const CARGO_MODIFIER := &"cargo:load"
const LOADED_SPEED_DELTA := -0.4    ## 4.0 -> 3.6 m/s while loaded.
const POLL := 0.5                   ## Seconds between checks while waiting (post held, posts closed, no Bazaar).
const WAYPOINT_REACH := 2.5         ## Road nodes: switch to the next one this close.
const DOOR_REACH := 1.5
const HOME_REACH := 1.5
const KEEP_REACH := 2.5
const HOLD_REACH := 2.0
const ARRIVE_SLACK := 1.5           ## The agent finished its path this close to the goal: arrived.
const REPATH_TIME := 1.0            ## Path finished short of the goal: ask again after this long.
const STUCK_ARRIVE := 6.0           ## No progress for 2 s this close to the goal (crowd): arrived.
const SPAWN_MARKET_RANGE := 12.0    ## A new caravan starts its loop when its team's Bazaar is this close.
const ROUTE_MIN := 20.0             ## TradeNetwork "Route too short" (fallback without a network).
const ROUTE_CAP := 140.0

const LOCAL_TEAM := Unit.Team.PLAYER   ## Only this team's lines go to the HUD.
const MSG_SECONDS := 3.0
const LOSS_MSG_INTERVAL := 10.0     ## Robbery / loss lines: at most one per 10 s, summed.
const HELD_MSG_INTERVAL := 30.0

const MSG_NOT_POST := "Not a trading post"
const MSG_NO_BAZAAR := "No Bazaar"
const MSG_TOO_SHORT := "Route too short"
const MSG_HELD := "Held by the enemy"

const LOOT_SACK_PATH := "res://scripts/world/loot_sack.gd"
const MARKET_KIND := &"market"
const MARKETS_GROUP := &"markets"
const CARGO_COLOR := Color(1.0, 0.85, 0.3)

## Gold being carried back (0 = empty). Setting it updates the loaded look and speed and emits cargo_changed.
var cargo: int = 0: set = _set_cargo
## The Bazaar this caravan belongs to. Market._spawn sets it before add_child, then calls command_trade(self);
## a caravan added next to its team's Bazaar without an order (TrainingBuilding style) finds it and starts the
## loop by itself; after its Bazaar was lost it takes the team's next completed one.
var home_market: Node3D = null
## The post of the current (or next) trip. A post given with command_trade stays this caravan's route;
## otherwise it follows its Bazaar's route_post at every departure.
var route_post: Node3D = null
## &"idle", &"loading", &"to_post", &"trading", &"returning", &"waiting". Read only.
var trade_state: StringName = &"idle"

## Tests may inject a stand-in for scripts/world/loot_sack.gd (a script with `static func spawn(parent, pos, amount)`).
static var loot_sack_script: Script = null

static var _msg_last: Dictionary = {}      # "kind:team" -> game time of the last line
static var _msg_pending: Dictionary = {}   # "kind:team" -> amount summed while throttled
static var _msg_scene := 0                 # instance id of the level the two tables above belong to

var _wait_reason: StringName = &""   # &"closed", &"held", &"no_bazaar", &"no_route" (trade_state &"waiting")
var _own_route := false              # true after command_trade(post): keep that post instead of the Bazaar's
var _trip_post: Node3D = null        # the post of the trip in progress
var _trip_value := 0                 # its value at departure (used if the Bazaar is gone when trading ends)
var _route := PackedVector3Array()   # outbound waypoints, the door last
var _wp_i := -1                      # waypoint being walked to (-1 on the way back = home)
var _leg_start := Vector3.ZERO
var _hold_point := Vector3.ZERO
var _timer := 0.0
var _poll_left := 0.0
var _fresh := true                   # just created: start the loop once the spawn frame is over
var _walking := false                # a trade-loop walk is in progress (_target valid)
var _target := Vector3.INF
var _reach := HOME_REACH
var _repath_left := REPATH_TIME
var _stuck_tries := 0
var _stuck_from := INF
var _cargo_visual: MeshInstance3D


func _ready() -> void:
	super()
	add_to_group("caravans")
	_build_cargo_visual()
	_apply_load_look()
	# The trainer orders the new unit to its rally point right after adding it: start the loop after that.
	_on_spawned.call_deferred()


# ---------------------------------------------------------------- public

## Trade with `target`: a trading post (from now on this caravan's route; a loaded caravan delivers first), or
## the own Bazaar (go home, deliver, then follow the Bazaar's route). Returns "" or the reason:
## "Not a trading post", "No Bazaar", "Route too short".
func command_trade(target: Node3D) -> String:
	if target == null or not is_instance_valid(target):
		return MSG_NOT_POST
	if _is_market_node(target):
		var b := target as Building
		if int(b.team) != int(team):
			return MSG_NOT_POST
		if not b.is_alive() or not b.is_constructed():
			return MSG_NO_BAZAAR
		home_market = target
		_own_route = false
		var r: Variant = target.get(&"route_post")
		route_post = r as Node3D if r is Node3D and is_instance_valid(r) else null
		if is_alive():
			_go_home()
		return ""
	if not _is_post(target):
		return MSG_NOT_POST
	if not _market_ok():
		var m := _find_market(global_position, INF)
		if m == null:
			return MSG_NO_BAZAAR
		home_market = m
	if _route_reason(target) == MSG_TOO_SHORT:
		return MSG_TOO_SHORT
	route_post = target
	_own_route = true
	if not is_alive():
		return ""
	if cargo > 0 or not _is_open():
		_go_home()   # deliver first / wait at the Bazaar for the posts to open
	elif _flat_distance(_home_point()) <= SPAWN_MARKET_RANGE * 0.5:
		_begin_loading()
	else:
		_join_route(target)
	return ""


func is_loaded() -> bool:
	return cargo > 0


## A Magpie takes up to `amount` gold. Returns what was taken (0 when empty or dead); emits `robbed`.
func steal(amount: int, thief: Node3D) -> int:
	if not is_alive() or amount <= 0 or cargo <= 0:
		return 0
	var taken := mini(amount, cargo)
	cargo -= taken
	var who: Node3D = thief if thief != null and is_instance_valid(thief) else null
	robbed.emit(self, taken, who)
	var net := _network()
	if net and net.has_signal(&"caravan_robbed"):
		net.emit_signal(&"caravan_robbed", int(team), self, taken, who)
	if int(team) == LOCAL_TEAM:
		_notify_summed(&"robbed", int(team), taken)
	return taken


## One line for the panel: "To Saltgate", "Trading", "Returning with 119", "Waiting: Saltgate is held"...
func state_text() -> String:
	match trade_state:
		&"loading":
			return "Loading"
		&"to_post":
			return "To %s" % _post_name(_trip_post)
		&"trading":
			return "Trading"
		&"returning":
			return "Returning with %d" % cargo if cargo > 0 else "Returning"
		&"waiting":
			match _wait_reason:
				&"closed":
					return "Waiting: posts open at 4:00"
				&"held":
					return "Waiting: %s is held" % _post_name(_trip_post)
				&"no_bazaar":
					return "Waiting: no Bazaar"
				&"no_route":
					return "Waiting: no route"
			return "Waiting"
	return "Idle"


## Seconds left in the current timed step (loading, trading, waiting at a held post); 0 otherwise.
func step_time_left() -> float:
	if trade_state == &"loading" or trade_state == &"trading" \
			or (trade_state == &"waiting" and _wait_reason == &"held"):
		return maxf(0.0, _timer)
	return 0.0


# ---------------------------------------------------------------- orders (keep the cargo, stop trading)

func command_move(target: Vector3) -> void:
	_go_idle()
	super(target)


## Caravans never fight: an attack order does nothing.
func command_attack(_target_node) -> void:
	pass


func command_attack_move(target: Vector3) -> void:
	command_move(target)


func command_hold() -> void:
	_go_idle()
	super()


func command_stop() -> void:
	_go_idle()
	super()


func take_damage(amount: float, attacker: Node3D = null) -> void:
	super(amount, attacker)
	if attack_target != null and _auto_target:   # the base unit fights back; a caravan never does
		attack_target = null
		_auto_target = false


func die() -> void:
	if not is_alive():
		return
	var lost := cargo
	_walking = false
	trade_state = &"idle"
	if lost > 0:
		_drop_sack(int(floor(lost * LOOT_RATIO)))
		cargo = 0
	if int(team) == LOCAL_TEAM:
		_notify_summed(&"destroyed", int(team), 1)
	super()


# ---------------------------------------------------------------- save / load (review R4-4)

## The Unit snapshot + the trade loop: home Bazaar (save id), route / trip post (post id), cargo, state.
func save_snapshot(ids: Dictionary) -> Dictionary:
	var d := super(ids)
	var c := {"cargo": cargo, "state": String(trade_state), "own_route": _own_route, "trip_value": _trip_value}
	if home_market != null and is_instance_valid(home_market) and ids.has(home_market):
		c["home"] = ids[home_market]
	if _post_ok(route_post):
		c["route_post"] = String(route_post.get(&"post_id"))
	if _post_ok(_trip_post):
		c["trip_post"] = String(_trip_post.get(&"post_id"))
	d["caravan"] = c
	return d


## After the Unit part (which leaves it idle): its Bazaar, route and cargo come back and the loop goes on: a
## loaded caravan walks home to deliver, an empty one on its way out rejoins its route, any other one goes home.
func load_snapshot_late(d: Dictionary, nodes: Dictionary, crystal_nodes: Dictionary) -> void:
	super(d, nodes, crystal_nodes)
	var c: Dictionary = d.get("caravan", {})
	if c.is_empty() or not is_alive():
		return
	_fresh = false
	var home: Variant = nodes.get(c.get("home", -1))
	if home is Node3D and is_instance_valid(home):
		home_market = home
	route_post = _post_by_id(str(c.get("route_post", "")))
	_trip_post = _post_by_id(str(c.get("trip_post", "")))
	_own_route = bool(c.get("own_route", false))
	_trip_value = int(c.get("trip_value", 0))
	cargo = int(c.get("cargo", 0))
	var state := StringName(str(c.get("state", "idle")))
	if state == &"idle":
		return
	if cargo == 0 and state == &"to_post" and _post_ok(_trip_post) and _market_ok() and _is_open():
		_join_route(_trip_post)
	else:
		_go_home()


func _post_by_id(id: String) -> Node3D:
	if id == "" or not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group(&"trade_posts"):
		if String(n.get(&"post_id")) == id:
			return n as Node3D
	return null


# ---------------------------------------------------------------- the loop

func _physics_process(delta: float) -> void:
	if attack_target != null and not has_status(&"taunted"):
		attack_target = null   # never fights (aggro 0, no damage)
		_auto_target = false
	super(delta)
	if not is_alive() or not can_act() or trade_state == &"idle":
		return
	match trade_state:
		&"loading":
			_timer -= delta
			if _timer <= 0.0:
				_depart()
		&"to_post":
			if not _post_ok(_trip_post):
				_go_home()
				return
			if _wp_i == _route.size() - 1:
				_poll_left -= delta
				if _poll_left <= 0.0:
					_poll_left = POLL
					if _is_held(_trip_post):
						_start_held_wait()
						return
			if _walk_step(delta):
				_on_out_waypoint()
		&"trading":
			_timer -= delta
			if _timer <= 0.0:
				_finish_trade()
		&"returning":
			if _wp_i < 0:
				_poll_left -= delta
				if _poll_left <= 0.0:
					_poll_left = POLL
					if not _market_ok():
						_go_to_keep()
						return
					var home := _home_point()
					if _flat(home, _target) > 1.0:   # a new Bazaar (or it moved): walk there
						_walk_to(home, HOME_REACH)
			if _walk_step(delta):
				_on_back_waypoint()
		&"waiting":
			_wait_process(delta)


func _on_spawned() -> void:
	if not _fresh:
		return
	_fresh = false
	if not is_alive() or trade_state != &"idle":
		return   # the Market (or a test) already gave it a trade order
	if not _market_ok():
		var m := _find_market(global_position, SPAWN_MARKET_RANGE)
		if m == null:
			return   # not trained by a Bazaar: stays idle until ordered
		home_market = m
	_go_home()


## Leaves the Bazaar for the post of this trip (own route, else the Bazaar's route).
func _depart() -> void:
	if not _market_ok():
		_go_to_keep()
		return
	var post := _choose_post()
	if post == null:
		_set_waiting(&"no_route")
		return
	if not _is_open():
		_set_waiting(&"closed")
		return
	if _route_reason(post) == MSG_TOO_SHORT:
		_set_waiting(&"no_route")
		return
	_start_trip(post, 0)


func _start_trip(post: Node3D, first_index: int) -> void:
	_trip_post = post
	route_post = post
	_trip_value = _route_value(post)
	_route = _route_points(post)
	_wp_i = clampi(first_index, 0, _route.size() - 1)
	trade_state = &"to_post"
	_leg_start = global_position
	_poll_left = 0.0
	_head_out()


## Empty caravan ordered to a post from the field: join the route at the waypoint that makes the shortest
## way to the door (no loading).
func _join_route(post: Node3D) -> void:
	var pts := _route_points(post)
	var best := 0
	var best_cost := INF
	var tail := 0.0
	for i in range(pts.size() - 1, -1, -1):
		if i < pts.size() - 1:
			tail += _flat(pts[i], pts[i + 1])
		var cost := _flat_distance(pts[i]) + tail
		if cost < best_cost:
			best_cost = cost
			best = i
	_start_trip(post, best)


func _head_out() -> void:
	var last := _route.size() - 1
	if _wp_i == last and _is_held(_trip_post):
		_start_held_wait()
		return
	_walk_to(_route[_wp_i], DOOR_REACH if _wp_i == last else WAYPOINT_REACH)


func _on_out_waypoint() -> void:
	if _wp_i >= _route.size() - 1:
		_begin_trading()
		return
	_wp_i += 1
	_leg_start = global_position
	_poll_left = 0.0
	_head_out()


func _begin_trading() -> void:
	_stop_walk()
	trade_state = &"trading"
	_timer = TRADE_TIME
	var door := _door_of(_trip_post)
	_face(door - global_position)


## The trade is done: the cargo is the route value from the caravan's own Bazaar, locked now.
func _finish_trade() -> void:
	var value := _route_value(_trip_post) if _market_ok() and _post_ok(_trip_post) else _trip_value
	cargo = maxi(0, value)
	_play_vfx(&"post_trade", _door_of(_trip_post) if _post_ok(_trip_post) else global_position)
	_start_return(_route.size() - 2)


## Walk back: waypoint `next_index`, then the ones before it, then home (-1 = straight home).
func _start_return(next_index: int) -> void:
	trade_state = &"returning"
	_wp_i = mini(next_index, _route.size() - 1)
	_poll_left = 0.0
	if _wp_i >= 0:
		_walk_to(_route[_wp_i], WAYPOINT_REACH)
	else:
		_go_home()


func _on_back_waypoint() -> void:
	if _wp_i < 0:
		_arrive_home()
		return
	_wp_i -= 1
	if _wp_i >= 0:
		_walk_to(_route[_wp_i], WAYPOINT_REACH)
	else:
		_go_home()


## Walk to the Bazaar's spawn point (to deliver and load). No Bazaar: wait at the keep.
func _go_home() -> void:
	if not _market_ok():
		_go_to_keep()
		return
	trade_state = &"returning"
	_wp_i = -1
	_poll_left = POLL
	var home := _home_point()
	if _flat_distance(home) <= HOME_REACH:
		_arrive_home()
	else:
		_walk_to(home, HOME_REACH)


func _arrive_home() -> void:
	if not _market_ok():
		_go_to_keep()
		return
	if cargo > 0:
		_deliver()
	_begin_loading()


func _begin_loading() -> void:
	if not _market_ok():
		_go_to_keep()
		return
	_stop_walk()
	if not _is_open():
		_set_waiting(&"closed")
		return
	trade_state = &"loading"
	_timer = LOAD_TIME


func _deliver() -> void:
	var amount := cargo
	cargo = 0
	var bank := _gold_bank()
	if bank and bank.has_method(&"add"):
		bank.call(&"add", amount, &"trade")
	var net := _network()
	if net and net.has_method(&"record_delivery"):
		net.call(&"record_delivery", int(team), amount, _trip_post if _post_ok(_trip_post) else null, self)
	delivered.emit(self, amount)
	_play_vfx(&"delivery", _home_point() if _market_ok() else global_position)


# ---------------------------------------------------------------- waiting

func _set_waiting(reason: StringName) -> void:
	_stop_walk()
	trade_state = &"waiting"
	_wait_reason = reason
	_poll_left = POLL


## The post is held by the enemy: back off to the hold point and wait up to 45 s.
func _start_held_wait() -> void:
	var last := _route.size() - 1
	if last >= 1:
		_hold_point = _route[last - 1]
	else:
		var door := _route[last]
		var away := Vector3(_leg_start.x - door.x, 0.0, _leg_start.z - door.z)
		var d := away.length()
		_hold_point = _leg_start if d < 0.01 else door + away / d * minf(HELD_NEAR_BACKOFF, d)
	trade_state = &"waiting"
	_wait_reason = &"held"
	_timer = HELD_WAIT
	_poll_left = POLL
	if _flat_distance(_hold_point) > HOLD_REACH:
		_walk_to(_hold_point, HOLD_REACH)
	else:
		_stop_walk()
	if int(team) == LOCAL_TEAM:
		_notify_held(_post_name(_trip_post))


## No Bazaar: walk to the nearest own keep and wait there for a new one.
func _go_to_keep() -> void:
	_set_waiting(&"no_bazaar")
	_poll_left = 0.0
	var keep := Keep.nearest(int(team), global_position)
	if keep:
		var spot := keep.drop_off_point()
		if _flat_distance(spot) > KEEP_REACH:
			_walk_to(spot, KEEP_REACH)


func _wait_process(delta: float) -> void:
	if _walking and _walk_step(delta):
		_stop_walk()
	if _wait_reason == &"held":
		_timer -= delta
	_poll_left -= delta
	if _poll_left > 0.0:
		return
	_poll_left = POLL
	match _wait_reason:
		&"held":
			if not _post_ok(_trip_post):
				_go_home()
			elif not _is_held(_trip_post):
				trade_state = &"to_post"   # free again: on to the door
				_wp_i = _route.size() - 1
				_leg_start = global_position
				_walk_to(_route[_wp_i], DOOR_REACH)
			elif _timer <= 0.0:
				_start_return(_route.size() - 3 if _route.size() >= 2 else -1)   # home empty
		&"no_bazaar":
			var m := _find_market(global_position, INF)
			if m:
				home_market = m
				_go_home()
		&"closed", &"no_route":
			if not _market_ok():
				_go_to_keep()
			elif _wait_reason == &"closed" and _is_open():
				_begin_loading()
			elif _wait_reason == &"no_route" and _choose_post() != null:
				_begin_loading()


func _go_idle() -> void:
	trade_state = &"idle"
	_wait_reason = &""
	_stop_walk()


# ---------------------------------------------------------------- walking

func _walk_to(pos: Vector3, reach: float) -> void:
	_target = pos
	_reach = reach
	_walking = true
	_repath_left = REPATH_TIME
	_stuck_tries = 0
	_stuck_from = INF
	_last_nav_target = Vector3.INF   # always ask for a fresh path
	super.command_move(pos)          # the base order: the trade loop stays on


func _stop_walk() -> void:
	_walking = false
	_target = Vector3.INF
	super.command_stop()


## True once the current walk has arrived.
func _walk_step(delta: float) -> bool:
	if not _walking:
		return true
	var d := _flat_distance(_target)
	if d <= _reach:
		return true
	if not can_move():
		return false
	# The agent finished its path a little short of the goal (crowd, obstacle): close enough.
	if not _has_move_order and d <= _reach + ARRIVE_SLACK:
		return true
	_repath_left -= delta
	if _repath_left > 0.0:
		return false
	_repath_left = REPATH_TIME
	var progressed := d < _stuck_from - 0.3
	_stuck_from = d
	if progressed:
		_stuck_tries = 0
		return false
	# No progress for a second: jammed by other units at the goal (counts as arrived), else ask again.
	_stuck_tries += 1
	if d <= STUCK_ARRIVE and (_stuck_tries >= 2 or not _has_move_order):
		return true
	_last_nav_target = Vector3.INF
	super.command_move(_target)
	return false


# ---------------------------------------------------------------- helpers

func _market_ok() -> bool:
	var b := home_market as Building
	return b != null and is_instance_valid(b) and b.is_alive() and b.is_constructed()


func _home_point() -> Vector3:
	if home_market == null or not is_instance_valid(home_market):
		return global_position
	if home_market.has_method(&"spawn_point"):
		return home_market.call(&"spawn_point")
	return home_market.global_position


func _choose_post() -> Node3D:
	if _own_route and _post_ok(route_post):
		return route_post
	_own_route = false
	if not _market_ok():
		return null
	var r: Variant = home_market.get(&"route_post")
	if r is Node3D and _post_ok(r):
		return r
	return null


## The nearest completed, living Bazaar of this team within `max_dist` of `near` (null if none).
func _find_market(near: Vector3, max_dist: float) -> Node3D:
	if not is_inside_tree():
		return null
	var best: Node3D = null
	var best_d := max_dist
	for node in get_tree().get_nodes_in_group(&"buildings"):
		if not is_instance_valid(node) or not _is_market_node(node):
			continue
		var b := node as Building
		if int(b.team) != int(team) or not b.is_alive() or not b.is_constructed():
			continue
		var d := _flat(b.global_position, near)
		if d <= best_d:
			best_d = d
			best = b
	return best


## A Bazaar: group "markets" (Market.GROUP) or a building of kind &"market".
static func _is_market_node(node: Node) -> bool:
	var b := node as Building
	return b != null and (b.is_in_group(MARKETS_GROUP)
			or (b.building_type != null and b.building_type.kind == MARKET_KIND))


static func _is_post(node: Node) -> bool:
	return node != null and is_instance_valid(node) and node.is_in_group(&"trade_posts") \
			and node.has_method(&"door_point")


func _post_ok(post: Node3D) -> bool:
	return post != null and is_instance_valid(post) and post.is_inside_tree()


func _door_of(post: Node3D) -> Vector3:
	if post == null or not is_instance_valid(post):
		return global_position
	if post.has_method(&"door_point"):
		return post.call(&"door_point")
	return post.global_position


static func _post_name(post: Node3D) -> String:
	if post == null or not is_instance_valid(post):
		return "the post"
	var n: Variant = post.get(&"display_name")
	if n != null and str(n) != "":
		return str(n)
	return String(post.name)


func _network() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"trade_network")


func _gold_bank() -> Node:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(&"gold_banks"):
		var t: Variant = node.get(&"team")
		if t != null and int(t) == int(team):
			return node
	return null


func _is_open() -> bool:
	var net := _network()
	if net and net.has_method(&"is_open"):
		return bool(net.call(&"is_open"))
	return true


func _is_held(post: Node3D) -> bool:
	if not _post_ok(post):
		return false
	if post.has_method(&"is_held_by_enemy_of"):
		return bool(post.call(&"is_held_by_enemy_of", int(team)))
	return _route_reason(post) == MSG_HELD


func _route_reason(post: Node3D) -> String:
	var net := _network()
	if net and net.has_method(&"route_reason") and _market_ok():
		return str(net.call(&"route_reason", home_market, post))
	if _market_ok() and _flat(home_market.global_position, _door_of(post)) < ROUTE_MIN:
		return MSG_TOO_SHORT
	return ""


func _route_value(post: Node3D) -> int:
	var net := _network()
	if net and net.has_method(&"route_value") and _market_ok():
		return int(net.call(&"route_value", home_market, post))
	var l := minf(_flat(_home_point(), _door_of(post)), ROUTE_CAP)   # fallback: straight line
	return int(round(10.0 + l * l / 136.0))


## Outbound waypoints ending at the door. Points at the Bazaar itself or inside the post are dropped.
func _route_points(post: Node3D) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var net := _network()
	if net and net.has_method(&"route_points") and _market_ok():
		var raw: Variant = net.call(&"route_points", home_market, post)
		if raw is PackedVector3Array:
			pts = raw
		elif raw is Array:
			for p: Variant in raw:
				if p is Vector3:
					pts.append(p)
	var door := _door_of(post)
	if _market_ok():
		var start := _home_point()
		var centre := home_market.global_position
		while pts.size() > 0 and (_flat(pts[0], start) < 3.0 or _flat(pts[0], centre) < 4.0):
			pts.remove_at(0)
	if _post_ok(post):
		var inside := _flat(door, post.global_position)
		while pts.size() > 0 and _flat(pts[pts.size() - 1], post.global_position) < inside - 0.5:
			pts.remove_at(pts.size() - 1)   # the post centre is behind the door
	if pts.is_empty() or _flat(pts[pts.size() - 1], door) > 1.0:
		pts.append(door)
	return pts


func _drop_sack(amount: int) -> void:
	if amount < 1 or not is_inside_tree():
		return
	var script := loot_sack_script
	if script == null and ResourceLoader.exists(LOOT_SACK_PATH):
		script = load(LOOT_SACK_PATH) as Script
	if script == null:
		return
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	script.call(&"spawn", parent, global_position, amount)


func _play_vfx(id: StringName, at: Vector3) -> void:
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"trade_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, at, self)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ---------------------------------------------------------------- cargo look

func _set_cargo(value: int) -> void:
	value = maxi(0, value)
	if value == cargo:
		return
	var was_loaded := cargo > 0
	cargo = value
	if was_loaded != (cargo > 0):
		_apply_load_look()
	cargo_changed.emit(self, cargo)


## Loaded speed (modifier cargo:load), the model's set_loaded, or the placeholder strongbox.
func _apply_load_look() -> void:
	var loaded := cargo > 0
	if loaded and not has_modifier(CARGO_MODIFIER):
		add_modifier(CARGO_MODIFIER, {&"move_speed": LOADED_SPEED_DELTA})
	elif not loaded and has_modifier(CARGO_MODIFIER):
		remove_modifier(CARGO_MODIFIER)
	if _model and _model.has_method(&"set_loaded"):
		_model.call(&"set_loaded", loaded)
	if _cargo_visual:
		_cargo_visual.visible = loaded


## A small gold strongbox on the back of the placeholder (models show their own: set_loaded).
func _build_cargo_visual() -> void:
	if _visual == null or (_model and _model.has_method(&"set_loaded")):
		return
	_cargo_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.32, 0.36)
	_cargo_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CARGO_COLOR
	mat.emission_enabled = true
	mat.emission = CARGO_COLOR
	mat.emission_energy_multiplier = 1.2
	_cargo_visual.material_override = mat
	_cargo_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cargo_visual.position = Vector3(0.0, body_height * 0.8, -radius * 0.8)
	_cargo_visual.visible = false
	_visual.add_child(_cargo_visual)


# ---------------------------------------------------------------- messages (local team only)

static func _now() -> float:
	return float(Engine.get_physics_frames()) / float(maxi(1, Engine.physics_ticks_per_second))


## Robbery / loss lines: the first shows now, the next ones within 10 s are summed into one line.
static func _notify_summed(kind: StringName, team_id: int, amount: int) -> void:
	_sync_msg_scene()
	var key := "%s:%d" % [kind, team_id]
	if _msg_pending.has(key):
		_msg_pending[key] = int(_msg_pending[key]) + amount
		return
	var since := _now() - float(_msg_last.get(key, -1.0e9))
	if since >= LOSS_MSG_INTERVAL:
		_msg_last[key] = _now()
		_show(_loss_text(kind, amount))
		return
	_msg_pending[key] = amount
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.create_timer(LOSS_MSG_INTERVAL - since, true, true).timeout.connect(
				func() -> void: _flush_summed(key, kind))


## The message tables belong to one level: a new level (F9, a new skirmish) starts them empty, so a pending line of
## the old match never shows in the new one (review 2026-10-08 L4).
static func _sync_msg_scene() -> void:
	var id := _scene_id()
	if id != _msg_scene:
		_msg_scene = id
		_msg_last.clear()
		_msg_pending.clear()


static func _scene_id() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene.get_instance_id() if tree and tree.current_scene else 0


static func _flush_summed(key: String, kind: StringName) -> void:
	_sync_msg_scene()   # the level changed since the line was held: the tables are cleared, nothing shows
	if not _msg_pending.has(key):
		return
	var amount := int(_msg_pending[key])
	_msg_pending.erase(key)
	_msg_last[key] = _now()
	_show(_loss_text(kind, amount))


static func _loss_text(kind: StringName, amount: int) -> String:
	if kind == &"robbed":
		return "Your caravan was robbed: -%d gold" % amount
	if amount <= 1:
		return "Your caravan was destroyed"
	return "%d of your caravans were destroyed" % amount


static func _notify_held(post_name: String) -> void:
	_sync_msg_scene()
	var key := "held:%d" % LOCAL_TEAM
	if _now() - float(_msg_last.get(key, -1.0e9)) < HELD_MSG_INTERVAL:
		return
	_msg_last[key] = _now()
	_show("%s is held by the enemy: your caravans wait" % post_name)


static func _show(text: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = tree.current_scene if tree else null
	if scene == null:
		return
	var hud: Variant = scene.get(&"hud")
	if is_instance_valid(hud) and hud is Object and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, MSG_SECONDS)
