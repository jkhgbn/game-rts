class_name TradeNetwork
extends Node
## The trade map of a match (docs/design/market-trade.md 2, 4.3; contract section 12): the ring road, the
## trading posts, route length / value, the trade ledger, post holders, spot danger, remote nodes and mining
## samples. One per match, group "trade_network"; reach it with `TradeNetwork.instance(get_tree())`.
## The skirmish creates it (Skirmish._build_map) and calls setup(); campaign maps may call setup() with
## their own posts and roads (market-trade.md 10).
## - Road graph: named nodes (Vector3, y 0) joined by segments. Nodes whose id starts with "hub" are base hubs:
##   a team's hub is the hub nearest its base (base_positions, else its keep). A post's door is on the road
##   node nearest to TradePost.door_point().
## - Route (4.3): L = straight distance from the Bazaar's centre to the first road node after the team's hub on
##   the shortest ring path hub -> post door, plus the ring length from that node to the door.
##   V = round(10 + min(L, 140)^2 / 136) gold per trip. route_points() are the caravan's waypoints (the Bazaar
##   itself is not included; the post door is last).
## - Time: match time from `match_time_source` (the skirmish passes its match_time), else this node's age.
##   Posts open at OPEN_TIME (4:00, `posts_opened` once), guild houses at GUILD_OPEN_TIME (5:00).
## - One 1 Hz pass over "units" / "buildings" (refresh()): post holders (12 m, emits post_held_changed),
##   fighters and defences per team for strength_near() / spot_valid(), workers within 14 m of each crystal
##   node for workers_at(). Mining samples every 10 s (mined_recently()).
## - Ledger: record_delivery() (caravans, 10.C3); robbed caravans emit caravan_robbed on this node themselves
##   (counted in robbed_total); record_workers_raided() (thief bands); record_loot_pickup() (loot sacks);
##   losses and Magpie kills are counted from Events.unit_died.

signal posts_opened
signal delivered(team: int, caravan: Node, amount: int, post: Node)
signal caravan_robbed(team: int, caravan: Node, amount: int, thief: Node)
signal workers_raided(team: int, node: Node)
signal post_held_changed(post: Node, holder_team: int)
## A loot sack was picked up (team NEUTRAL = a Magpie took it). Emitted by record_loot_pickup (LootSack).
signal loot_picked(team: int, amount: int, sack: Node)
## The guild houses opened (GUILD_OPEN_TIME). Once.
signal guilds_opened

const OPEN_TIME := 240.0                ## 4:00: trading posts open.
const GUILD_OPEN_TIME := 300.0          ## 5:00: Magpie Dens and Greywater Lodges open.
const PASS_INTERVAL := 1.0              ## Holders / strength / workers cache.
const SAMPLE_INTERVAL := 10.0           ## Mining samples.
const HOLD_RADIUS := 12.0
const NEAR_DISTANCE := 60.0             ## A post is near for a team when its door is closer than this to its keep.
const REMOTE_DISTANCE := 30.0           ## A node farther than this from a team's keep is remote for it.
const REMOTE_TIE := 2.0                 ## Contested nodes (equally far from both keeps) are remote for both.
const WORKER_RADIUS := 14.0             ## workers_at(): workers this close to the node.
const WORKER_SPOT_MAX := 20.0           ## worker_spot(): the W spot must be this close to the node.
const VALUE_BASE := 10.0
const VALUE_DIVISOR := 136.0
const LENGTH_CAP := 140.0
const MIN_ROUTE := 20.0
const SPOT_ON_ROAD := 3.0               ## An ambush spot belongs to a road segment this close to it.
const SPOT_UNIT_RADIUS := 18.0          ## spot_valid(): no fighter of the team this close...
const SPOT_TOWER_RADIUS := 20.0         ## ...no tower...
const SPOT_KEEP_RADIUS := 25.0          ## ...no keep.
const STRENGTH_TRACKER := 150.0
const STRENGTH_MAGPIE := 80.0
const STRENGTH_TOWER := 150.0
const STRENGTH_KEEP := 250.0
const LEDGER_SECONDS := 900.0           ## Ledger / sample history kept (totals are kept forever).
const HUB_PREFIX := "hub"

const MSG_CLOSED := "Trading posts open at 4:00"
const MSG_TOO_SHORT := "Route too short"
const MSG_HELD := "Held by the enemy"
const MSG_NOT_POST := "Not a trading post"

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2

## Returns the match time in seconds. Unset: this node's own age.
var match_time_source: Callable
## Team -> Vector3: each team's keep spot (used even after the keep falls). Missing: the team's living Keep.
var base_positions := {}

var _age := 0.0
var _posts: Array = []                  # TradePost nodes
var _nodes := {}                        # StringName -> Vector3 (y 0)
var _adj := {}                          # StringName -> Array of [StringName, float length]
var _segments: Array = []               # [StringName a, StringName b]
var _road_spots: Array[Vector3] = []
var _spot_on_segment: Array[int] = []   # per road spot: index in _segments, -1 = off the road
var _worker_spots: Array[Vector3] = []
var _path_cache := {}                   # "a>b" -> Array[StringName]
var _door_nodes := {}                   # post instance id -> StringName

var _posts_open := false
var _posts_announced := false
var _guilds_open := false
var _guilds_announced := false
var _pass_left := 0.0
var _sample_left := SAMPLE_INTERVAL
var _refreshed := false

var _holders := {}                      # post instance id -> team (-1 = nobody)
var _fighters := {PLAYER_TEAM: [], ENEMY_TEAM: []}    # [Vector3 pos, float strength]
var _defences := {PLAYER_TEAM: [], ENEMY_TEAM: []}    # [Vector3 pos, float reach, float strength, StringName kind]
var _workers_near := {}                 # crystal node instance id -> {team: Array[Unit]}

var _ledger: Array = []                 # [time, team, amount, post instance id]
var _traded_total := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _trips_total := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _robbed_total := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _loot_total := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _caravans_lost := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _workers_lost := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _magpies_slain := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _raids := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _mine_last := {}                    # crystal node instance id -> crystals_left at the last sample
var _mine_log := {}                     # crystal node instance id -> Array of [time, taken]


func _ready() -> void:
	add_to_group("trade_network")
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died") and not events.is_connected(&"unit_died", _on_unit_died):
		events.connect(&"unit_died", _on_unit_died)
	# Caravans emit caravan_robbed on this node themselves (Caravan.steal); count what they report.
	if not caravan_robbed.is_connected(_on_caravan_robbed):
		caravan_robbed.connect(_on_caravan_robbed)


func _exit_tree() -> void:
	var events := get_node_or_null(^"/root/Events")
	if events and events.is_connected(&"unit_died", _on_unit_died):
		events.disconnect(&"unit_died", _on_unit_died)


## The match's network (group "trade_network"), or null (trade off, or a map without one).
static func instance(tree: SceneTree) -> TradeNetwork:
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"trade_network") as TradeNetwork


## `posts`: TradePost nodes. `nodes`: road node id (StringName) -> Vector3; ids starting with "hub" are base
## hubs. `segments`: Array of [id_a, id_b]. `spots`: {&"road": {id: Vector3} (ambush spots on the roads),
## &"worker": {id: Vector3} (spots beside remote crystal nodes)}; Arrays of Vector3 work too.
func setup(posts: Array, nodes: Dictionary, segments: Array, spots: Dictionary) -> void:
	_posts = posts.duplicate()
	_nodes.clear()
	for id in nodes:
		var p: Vector3 = nodes[id]
		_nodes[StringName(id)] = Vector3(p.x, 0.0, p.z)
	_segments.clear()
	_adj.clear()
	for id: StringName in _nodes:
		_adj[id] = []
	for seg in segments:
		var a := StringName(seg[0])
		var b := StringName(seg[1])
		if not _nodes.has(a) or not _nodes.has(b):
			push_warning("TradeNetwork: segment %s-%s names an unknown road node" % [a, b])
			continue
		var length := _flat(_nodes[a], _nodes[b])
		_segments.append([a, b])
		(_adj[a] as Array).append([b, length])
		(_adj[b] as Array).append([a, length])
	_road_spots = _spot_list(spots.get(&"road", spots.get("road", [])))
	_worker_spots = _spot_list(spots.get(&"worker", spots.get("worker", [])))
	_spot_on_segment.clear()
	for p in _road_spots:
		_spot_on_segment.append(_segment_near(p, SPOT_ON_ROAD))
	_path_cache.clear()
	_door_nodes.clear()
	_holders.clear()
	for post in _posts:
		if is_instance_valid(post):
			_holders[post.get_instance_id()] = -1
			if post.has_method(&"set_open"):
				post.call(&"set_open", is_open())
	_posts_open = is_open()


# ---------------------------------------------------------------- time

## Seconds of match time (match_time_source, else this node's age).
func match_time() -> float:
	return float(match_time_source.call()) if match_time_source.is_valid() else _age


## True from OPEN_TIME (4:00) on.
func is_open() -> bool:
	return match_time() >= OPEN_TIME


## Seconds until the posts open (0 once open).
func time_until_open() -> float:
	return maxf(0.0, OPEN_TIME - match_time())


## True from GUILD_OPEN_TIME (5:00) on (the guild houses' doors).
func guilds_open() -> bool:
	return match_time() >= GUILD_OPEN_TIME


## After a load restored the match clock: what already opened is not announced again (review W2-7). The posts
## and guild houses still get set_open on the next tick.
func sync_announcements() -> void:
	_posts_announced = _posts_announced or is_open()
	_guilds_announced = _guilds_announced or guilds_open()


func _physics_process(delta: float) -> void:
	_age += delta
	var open := is_open()
	if open != _posts_open:
		_posts_open = open
		for post in _posts:
			if is_instance_valid(post) and post.has_method(&"set_open"):
				post.call(&"set_open", open)
		if open and not _posts_announced:
			_posts_announced = true
			posts_opened.emit()
	var g_open := guilds_open()
	if g_open != _guilds_open:
		_guilds_open = g_open
		for house in get_tree().get_nodes_in_group(&"guilds"):
			if house.has_method(&"set_open"):
				house.call(&"set_open", g_open)
		if g_open and not _guilds_announced:
			_guilds_announced = true
			guilds_opened.emit()
	_pass_left -= delta
	if _pass_left <= 0.0:
		_pass_left = PASS_INTERVAL
		refresh()
	_sample_left -= delta
	if _sample_left <= 0.0:
		_sample_left = SAMPLE_INTERVAL
		_sample_mining()


# ---------------------------------------------------------------- map queries

## The trading posts (TradePost nodes) of this network.
func posts() -> Array:
	return _posts.filter(func(p: Variant) -> bool: return is_instance_valid(p))


## The post with this id (&"heron_ford"...), or null.
func post_by_id(id: StringName) -> Node3D:
	for p in posts():
		if StringName(p.get(&"post_id")) == id:
			return p
	return null


## The guild houses (group "guilds"; GuildHouse nodes).
func guild_houses() -> Array:
	return get_tree().get_nodes_in_group(&"guilds") if is_inside_tree() else []


## Each road segment as [a, b] (y 0), for the minimap, the ground paint and route lines.
func road_segments() -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	for seg in _segments:
		out.append(PackedVector3Array([_nodes[seg[0]], _nodes[seg[1]]]))
	return out


## Road node positions by id (a copy).
func road_nodes() -> Dictionary:
	return _nodes.duplicate()


## The caravan waypoints from `market` (not included) to the post door (last): the first road node after the
## team's hub on the shortest ring path, then the ring to the door. Empty if the door can't be reached.
func route_points(market: Node3D, post: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not _valid_node(market) or not _valid_node(post):
		return out
	var path := _team_path(_team_of(market), market.global_position, post)
	if path.is_empty():
		return out
	for i in range(1 if path.size() > 1 else 0, path.size()):
		out.append(_nodes[path[i]])
	var door := _door_point(post)
	if _flat(out[out.size() - 1], door) > 0.5:
		out.append(door)
	return out


## L of market-trade.md 4.3 (metres, not capped). INF if the post can't be reached.
func route_length(market: Node3D, post: Node3D) -> float:
	var pts := route_points(market, post)
	if pts.is_empty():
		return INF
	var length := _flat(market.global_position, pts[0])
	for i in range(1, pts.size()):
		length += _flat(pts[i - 1], pts[i])
	return length


## Gold per trip: round(10 + min(L, 140)^2 / 136); 0 if unreachable.
func route_value(market: Node3D, post: Node3D) -> int:
	return value_for_length(route_length(market, post))


## The value formula of 4.3 for a length L.
static func value_for_length(length: float) -> int:
	if length == INF or is_nan(length):
		return 0
	var l := minf(maxf(length, 0.0), LENGTH_CAP)
	return int(round(VALUE_BASE + l * l / VALUE_DIVISOR))


## "" when the Bazaar can trade with the post now, else "Trading posts open at 4:00", "Route too short" or
## "Held by the enemy" (in that order; "Not a trading post" for anything else).
func route_reason(market: Node3D, post: Node3D) -> String:
	if not _valid_node(post) or not post.is_in_group(&"trade_posts"):
		return MSG_NOT_POST
	if not is_open():
		return MSG_CLOSED
	if _valid_node(market) and route_length(market, post) < MIN_ROUTE:
		return MSG_TOO_SHORT
	if post.has_method(&"is_held_by_enemy_of") and bool(post.call(&"is_held_by_enemy_of", _team_of(market))):
		return MSG_HELD
	return ""


## True when the post's door is NEAR_DISTANCE (60 m) or more from the team's keep.
func is_far(team: int, post: Node3D) -> bool:
	var base := _base_of(team)
	if base == Vector3.INF or not _valid_node(post):
		return false
	return _flat(_door_point(post), base) >= NEAR_DISTANCE


## The road ambush spots on the team's route to `post` (hub -> door), the post end first.
func ambush_spots(team: int, post: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not _valid_node(post):
		return out
	var base := _base_of(team)
	var path := _team_path(team, base if base != Vector3.INF else _door_point(post), post)
	if path.size() < 2:
		return out
	var along := {}   # spot index -> distance along the path from the hub
	var start := 0.0
	for i in range(1, path.size()):
		var a: Vector3 = _nodes[path[i - 1]]
		var b: Vector3 = _nodes[path[i]]
		var seg := _segment_index(path[i - 1], path[i])
		var seg_len := _flat(a, b)
		for k in _road_spots.size():
			if _spot_on_segment[k] != seg or along.has(k):
				continue
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var ap := Vector2(_road_spots[k].x - a.x, _road_spots[k].z - a.z)
			var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			along[k] = start + t * seg_len
		start += seg_len
	var order: Array = along.keys()
	order.sort_custom(func(x: int, y: int) -> bool: return float(along[x]) > float(along[y]))
	for k: int in order:
		out.append(_road_spots[k])
	return out


## The W spot beside a crystal node (the nearest within 20 m), else Vector3.INF.
func worker_spot(node: Node3D) -> Vector3:
	if not _valid_node(node):
		return Vector3.INF
	var best := Vector3.INF
	var best_d := WORKER_SPOT_MAX
	for p in _worker_spots:
		var d := _flat(p, node.global_position)
		if d <= best_d:
			best_d = d
			best = p
	return best


## Crystal nodes (not depleted) more than 30 m from the team's keep and not nearer the other team's keep:
## on Crown Hollow the team's natural and both rich nodes; home nodes never.
func remote_nodes(team: int) -> Array:
	var out := []
	var base := _base_of(team)
	if base == Vector3.INF or not is_inside_tree():
		return out
	var other := _base_of(ENEMY_TEAM if team == PLAYER_TEAM else PLAYER_TEAM)
	for node in get_tree().get_nodes_in_group(&"crystal_nodes"):
		var cn := node as CrystalNode
		if cn == null or cn.is_depleted():
			continue
		var d := _flat(cn.global_position, base)
		if d <= REMOTE_DISTANCE:
			continue
		if other != Vector3.INF and d > _flat(cn.global_position, other) + REMOTE_TIE:
			continue
		out.append(cn)
	return out


## The team's living workers within 14 m of the node (1 Hz cache).
func workers_at(team: int, node: Node3D) -> Array:
	if not _valid_node(node):
		return []
	_ensure_refreshed()
	var by_team: Dictionary = _workers_near.get(node.get_instance_id(), {})
	var list: Array = by_team.get(team, [])
	return list.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())


## Crystals taken from the node in the last `seconds` of match time (10 s samples).
func mined_recently(node: Node3D, seconds := 180.0) -> int:
	if not _valid_node(node):
		return 0
	var log: Array = _mine_log.get(node.get_instance_id(), [])
	var since := match_time() - seconds
	var total := 0
	for e: Array in log:
		if float(e[0]) > since:
			total += int(e[1])
	return total


# ---------------------------------------------------------------- ledger

## A caravan delivered `amount` gold from `post` (the caravan adds the gold to its GoldBank itself).
func record_delivery(team: int, amount: int, post: Node, caravan: Node) -> void:
	if amount <= 0:
		return
	var post_id := post.get_instance_id() if post != null and is_instance_valid(post) else 0
	_ledger.append([match_time(), team, amount, post_id])
	_traded_total[team] = int(_traded_total.get(team, 0)) + amount
	_trips_total[team] = int(_trips_total.get(team, 0)) + 1
	_prune_ledger()
	delivered.emit(team, caravan, amount, post)


## Gold the team delivered in the last `seconds` of match time.
func trade_income(team: int, seconds := 180.0) -> int:
	var since := match_time() - seconds
	var total := 0
	for e: Array in _ledger:
		if int(e[1]) == team and float(e[0]) > since:
			total += int(e[2])
	return total


## Gold the team delivered from `post` in the last `seconds` (the Magpies' road weight).
func route_income(team: int, post: Node, seconds := 180.0) -> int:
	if post == null or not is_instance_valid(post):
		return 0
	var id := post.get_instance_id()
	var since := match_time() - seconds
	var total := 0
	for e: Array in _ledger:
		if int(e[1]) == team and int(e[3]) == id and float(e[0]) > since:
			total += int(e[2])
	return total


## Deliveries of the team from `post` in the last `seconds`.
func trips(team: int, post: Node, seconds := 120.0) -> int:
	if post == null or not is_instance_valid(post):
		return 0
	var id := post.get_instance_id()
	var since := match_time() - seconds
	var n := 0
	for e: Array in _ledger:
		if int(e[1]) == team and int(e[3]) == id and float(e[0]) > since:
			n += 1
	return n


## All gold the team ever delivered by caravan / all its deliveries.
func traded_total(team: int) -> int:
	return int(_traded_total.get(team, 0))


func trips_total(team: int) -> int:
	return int(_trips_total.get(team, 0))


## Gold stolen from the team's caravans so far.
func robbed_total(team: int) -> int:
	return int(_robbed_total.get(team, 0))


## Gold the team picked up from loot sacks so far.
func loot_total(team: int) -> int:
	return int(_loot_total.get(team, 0))


func caravans_lost(team: int) -> int:
	return int(_caravans_lost.get(team, 0))


func workers_lost_to_magpies(team: int) -> int:
	return int(_workers_lost.get(team, 0))


## Magpies whose killing blow came from the team (trackers count for their hiring team).
func magpies_slain(team: int) -> int:
	return int(_magpies_slain.get(team, 0))


## Worker strikes on the team's remote nodes so far.
func raids_on(team: int) -> int:
	return int(_raids.get(team, 0))


## A thief band struck the team's workers at `node` (ThiefBand calls it once per strike).
func record_workers_raided(team: int, node: Node) -> void:
	_raids[team] = int(_raids.get(team, 0)) + 1
	workers_raided.emit(team, node)


## LootSack calls it when a sack is picked up (team NEUTRAL: a Magpie took it).
func record_loot_pickup(team: int, amount: int, sack: Node) -> void:
	if team == PLAYER_TEAM or team == ENEMY_TEAM:
		_loot_total[team] = int(_loot_total.get(team, 0)) + amount
	loot_picked.emit(team, amount, sack)


# ---------------------------------------------------------------- holders, danger (1 Hz cache)

## The team holding the post (-1 = nobody), from the last pass.
func holder_of(post: Node) -> int:
	if post == null or not is_instance_valid(post):
		return -1
	return int(_holders.get(post.get_instance_id(), -1))


## Escort strength of `team` around `pos` (market-trade.md 5.3, ai.md strength): its soldiers, wizard,
## champions (power) and trackers (150) within `radius`, plus its towers (150) and keep (250) whose attack
## range covers `pos`. Workers and caravans count 0. 1 Hz cache.
func strength_near(team: int, pos: Vector3, radius: float) -> float:
	_ensure_refreshed()
	var total := 0.0
	var r2 := radius * radius
	for e: Array in _fighters.get(team, []):
		var p: Vector3 = e[0]
		if (p.x - pos.x) * (p.x - pos.x) + (p.z - pos.z) * (p.z - pos.z) <= r2:
			total += float(e[1])
	for e: Array in _defences.get(team, []):
		if _flat(e[0], pos) <= float(e[1]):
			total += float(e[2])
	return total


## True when a Magpie band may wait at `spot` against `team` (5.2): no fighter of the team (soldier, wizard,
## champion, tracker) within 18 m, no tower of it within 20 m, no keep of it within 25 m. 1 Hz cache.
func spot_valid(team: int, spot: Vector3) -> bool:
	_ensure_refreshed()
	var r2 := SPOT_UNIT_RADIUS * SPOT_UNIT_RADIUS
	for e: Array in _fighters.get(team, []):
		var p: Vector3 = e[0]
		if (p.x - spot.x) * (p.x - spot.x) + (p.z - spot.z) * (p.z - spot.z) <= r2:
			return false
	for e: Array in _defences.get(team, []):
		var limit := SPOT_TOWER_RADIUS if e[3] == &"tower" else SPOT_KEEP_RADIUS
		if _flat(e[0], spot) <= limit:
			return false
	return true


## Strength of one unit for danger sums: 0 for dead units, workers and caravans; trackers 150, Magpies 80;
## else ai.md (AIMemory): soldier cost x veterancy, wizard 170 + 30 x level + items / 5, champion power().
static func unit_strength(u: Unit) -> float:
	if u == null or not u.is_alive():
		return 0.0
	if is_caravan(u):
		return 0.0
	if u.is_in_group(&"trackers"):
		return STRENGTH_TRACKER
	if u.is_in_group(&"magpies"):
		return STRENGTH_MAGPIE
	if u.is_worker():
		return 0.0
	return AIMemory.strength_of(u)


## Caravans: group "caravans" or UnitType.is_caravan (10.C6).
static func is_caravan(u: Node) -> bool:
	if u == null:
		return false
	if u.is_in_group(&"caravans"):
		return true
	var t: Variant = u.get(&"unit_type")
	return t is Resource and bool((t as Resource).get(&"is_caravan"))


## Rebuilds the 1 Hz cache now (holders, fighters, defences, workers per node). Tests may call it.
func refresh() -> void:
	if not is_inside_tree():
		return
	_refreshed = true
	for team in [PLAYER_TEAM, ENEMY_TEAM]:
		(_fighters[team] as Array).clear()
		(_defences[team] as Array).clear()
	_workers_near.clear()
	var nodes: Array[CrystalNode] = []
	for node in get_tree().get_nodes_in_group(&"crystal_nodes"):
		var cn := node as CrystalNode
		if cn and not cn.is_depleted():
			nodes.append(cn)
			_workers_near[cn.get_instance_id()] = {PLAYER_TEAM: [], ENEMY_TEAM: []}
	var w2 := WORKER_RADIUS * WORKER_RADIUS
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		var team := int(u.team)
		if team != PLAYER_TEAM and team != ENEMY_TEAM:
			continue
		var p := u.global_position
		if u.is_worker():
			for cn in nodes:
				var c := cn.global_position
				if (p.x - c.x) * (p.x - c.x) + (p.z - c.z) * (p.z - c.z) <= w2:
					(_workers_near[cn.get_instance_id()][team] as Array).append(u)
			continue
		if is_caravan(u):
			continue
		(_fighters[team] as Array).append([p, unit_strength(u)])
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or not b.is_alive() or not b.is_constructed() or b.building_type == null:
			continue
		var team := int(b.team)
		if team != PLAYER_TEAM and team != ENEMY_TEAM:
			continue
		var kind := b.building_type.kind
		if kind == &"tower":
			(_defences[team] as Array).append([b.global_position, b.building_type.attack_range + b.target_radius(),
					STRENGTH_TOWER, kind])
		elif kind == &"keep":
			(_defences[team] as Array).append([b.global_position, b.building_type.attack_range + b.target_radius(),
					STRENGTH_KEEP, kind])
	_update_holders()


func _ensure_refreshed() -> void:
	if not _refreshed:
		refresh()


func _update_holders() -> void:
	var r2 := HOLD_RADIUS * HOLD_RADIUS
	for post in posts():
		var door := _door_point(post)
		var present := {PLAYER_TEAM: false, ENEMY_TEAM: false}
		for team in [PLAYER_TEAM, ENEMY_TEAM]:
			for e: Array in _fighters[team]:
				var p: Vector3 = e[0]
				if (p.x - door.x) * (p.x - door.x) + (p.z - door.z) * (p.z - door.z) <= r2:
					present[team] = true
					break
		var holder := -1
		if present[PLAYER_TEAM] and not present[ENEMY_TEAM]:
			holder = PLAYER_TEAM
		elif present[ENEMY_TEAM] and not present[PLAYER_TEAM]:
			holder = ENEMY_TEAM
		var id: int = post.get_instance_id()
		if int(_holders.get(id, -1)) == holder:
			continue
		_holders[id] = holder
		if post.has_method(&"set_holder_team"):
			post.call(&"set_holder_team", holder)
		post_held_changed.emit(post, holder)


# ---------------------------------------------------------------- mining samples

func _sample_mining() -> void:
	if not is_inside_tree():
		return
	var now := match_time()
	for node in get_tree().get_nodes_in_group(&"crystal_nodes"):
		var cn := node as CrystalNode
		if cn == null:
			continue
		_sample_node(cn, now)
	_prune_samples(now)


func _sample_node(cn: CrystalNode, now: float) -> void:
	var id := cn.get_instance_id()
	var left := maxi(cn.crystals_left, 0)
	if not _mine_last.has(id):
		_mine_last[id] = left
		if not cn.depleted.is_connected(_on_node_depleted):
			cn.depleted.connect(_on_node_depleted)
		return
	var taken := int(_mine_last[id]) - left
	_mine_last[id] = left
	if taken > 0:
		if not _mine_log.has(id):
			_mine_log[id] = []
		(_mine_log[id] as Array).append([now, taken])


func _on_node_depleted(cn: CrystalNode) -> void:
	if is_instance_valid(cn):
		_sample_node(cn, match_time())


func _prune_samples(now: float) -> void:
	for id in _mine_log:
		var log: Array = _mine_log[id]
		while not log.is_empty() and float(log[0][0]) < now - LEDGER_SECONDS:
			log.pop_front()


func _prune_ledger() -> void:
	var now := match_time()
	while not _ledger.is_empty() and float(_ledger[0][0]) < now - LEDGER_SECONDS:
		_ledger.pop_front()


# ---------------------------------------------------------------- events

## Counts every caravan_robbed (emitted here by the robbed caravan, Caravan.steal).
func _on_caravan_robbed(team: int, _caravan: Node, amount: int, _thief: Node) -> void:
	_robbed_total[team] = int(_robbed_total.get(team, 0)) + amount


func _on_unit_died(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.get(&"team") == null:
		return
	var team := int(unit.get(&"team"))
	var killer: Variant = unit.get(&"killer")
	var killer_node: Node = killer as Node if killer is Node and is_instance_valid(killer) else null
	if unit.is_in_group(&"magpies"):
		if killer_node != null and killer_node.get(&"team") != null:
			var kt := int(killer_node.get(&"team"))
			if kt == PLAYER_TEAM or kt == ENEMY_TEAM:
				_magpies_slain[kt] = int(_magpies_slain.get(kt, 0)) + 1
		return
	if team != PLAYER_TEAM and team != ENEMY_TEAM:
		return
	if is_caravan(unit):
		_caravans_lost[team] = int(_caravans_lost.get(team, 0)) + 1
	elif unit is Unit and (unit as Unit).is_worker() and killer_node != null and killer_node.is_in_group(&"magpies"):
		_workers_lost[team] = int(_workers_lost.get(team, 0)) + 1


# ---------------------------------------------------------------- graph helpers

## Shortest ring path (road node ids) from the team's hub to the post's door node.
func _team_path(team: int, fallback: Vector3, post: Node3D) -> Array:
	var hub := _hub_of(team, fallback)
	var door := _door_node(post)
	if hub == &"" or door == &"":
		return []
	return _shortest_path(hub, door)


## The hub node nearest the team's base (else nearest `fallback`); any node if the map has no hub.
func _hub_of(team: int, fallback: Vector3) -> StringName:
	var from := _base_of(team)
	if from == Vector3.INF:
		from = fallback
	var best := &""
	var best_d := INF
	var any_hub := false
	for id: StringName in _nodes:
		if String(id).begins_with(HUB_PREFIX):
			any_hub = true
			break
	for id: StringName in _nodes:
		if any_hub and not String(id).begins_with(HUB_PREFIX):
			continue
		var d := _flat(_nodes[id], from)
		if d < best_d:
			best_d = d
			best = id
	return best


func _door_node(post: Node3D) -> StringName:
	var key := post.get_instance_id()
	if _door_nodes.has(key):
		return _door_nodes[key]
	var door := _door_point(post)
	var best := &""
	var best_d := INF
	for id: StringName in _nodes:
		var d := _flat(_nodes[id], door)
		if d < best_d:
			best_d = d
			best = id
	_door_nodes[key] = best
	return best


func _shortest_path(from: StringName, to: StringName) -> Array:
	var key := "%s>%s" % [from, to]
	if _path_cache.has(key):
		return _path_cache[key]
	var dist := {from: 0.0}
	var prev := {}
	var open: Array[StringName] = [from]
	var done := {}
	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if float(dist[open[i]]) < float(dist[open[best_i]]):
				best_i = i
		var cur: StringName = open[best_i]
		open.remove_at(best_i)
		if done.has(cur):
			continue
		done[cur] = true
		if cur == to:
			break
		for edge: Array in _adj.get(cur, []):
			var nxt: StringName = edge[0]
			var nd := float(dist[cur]) + float(edge[1])
			if not dist.has(nxt) or nd < float(dist[nxt]) - 0.0001:
				dist[nxt] = nd
				prev[nxt] = cur
				open.append(nxt)
	var path := []
	if not dist.has(to):
		_path_cache[key] = path
		return path
	var step: StringName = to
	path.push_front(step)
	while step != from:
		step = prev[step]
		path.push_front(step)
	_path_cache[key] = path
	return path


func _segment_index(a: StringName, b: StringName) -> int:
	for i in _segments.size():
		var s: Array = _segments[i]
		if (s[0] == a and s[1] == b) or (s[0] == b and s[1] == a):
			return i
	return -1


## The segment nearest to `p` within `max_d`, or -1.
func _segment_near(p: Vector3, max_d: float) -> int:
	var best := -1
	var best_d := max_d
	for i in _segments.size():
		var a: Vector3 = _nodes[_segments[i][0]]
		var b: Vector3 = _nodes[_segments[i][1]]
		var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(a.x, a.z), Vector2(b.x, b.z))
		var d := q.distance_to(Vector2(p.x, p.z))
		if d <= best_d:
			best_d = d
			best = i
	return best


## The team's keep spot (base_positions), else its living Keep; Vector3.INF if neither.
func _base_of(team: int) -> Vector3:
	if base_positions.has(team):
		var p: Vector3 = base_positions[team]
		return Vector3(p.x, 0.0, p.z)
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(&"buildings"):
			var k := node as Keep
			if k and int(k.team) == team and k.is_alive():
				return Vector3(k.global_position.x, 0.0, k.global_position.z)
	return Vector3.INF


func _door_point(post: Node3D) -> Vector3:
	if post.has_method(&"door_point"):
		var d: Vector3 = post.call(&"door_point")
		return Vector3(d.x, 0.0, d.z)
	return Vector3(post.global_position.x, 0.0, post.global_position.z)


func _team_of(node: Node) -> int:
	var t: Variant = node.get(&"team") if node != null else null
	return int(t) if t != null else PLAYER_TEAM


static func _spot_list(v: Variant) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if v is Dictionary:
		for k in v:
			var p: Vector3 = v[k]
			out.append(Vector3(p.x, 0.0, p.z))
	elif v is Array:
		for p in v:
			if p is Vector3:
				out.append(Vector3(p.x, 0.0, p.z))
	return out


static func _valid_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and n is Node3D


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
