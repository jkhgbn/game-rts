class_name ThievesGuild
extends Node
## The Thieves' Guild, "the Magpies" (docs/design/market-trade.md section 5, contract section 12). One node per
## match in group "thieves_guild"; find it with `ThievesGuild.instance(tree)` (null when trade is off). It runs
## both Magpie Dens (GuildHouse nodes, group "guilds", kind &"den") and only decides WHEN, WHERE and HOW MANY:
## - Targets (`targets()`): a **road** of team T from 5:00 = a route (team, post) with >= 1 delivered trip of T in
##   the last 120 s, weight = gold T traded on it in the last 180 s + 30; a **remote node** of team T from 8:00 =
##   a crystal node > 30 m from T's keep with >= 2 of T's workers within 14 m, weight = 0.5 x crystals taken
##   from it in the last 180 s + 20. Home nodes are never targets.
## - Schedule: a tick every TICK (75 s) of match time from OPEN_TIME (5:00). A tick sends one band when a
##   target exists and fewer than MAX_ALIVE Magpies are alive; the target is drawn by weight (seeded `rng`).
## - Spot: road = the first valid spot of that route's ambush list (TradeNetwork.ambush_spots, post end first);
##   node = its W spot (TradeNetwork.worker_spot). Valid = no target-team soldier / wizard / champion / tracker
##   within 18 m, no target-team tower within 20 m, no target-team keep within 25 m. None valid: the band waits
##   RETRY_DELAY s "at the Den door" (kept here, not spawned) and retries, MAX_RETRIES times, then goes back in.
## - Size: 2; 3 with 6+ caravans on the map or from 12:00; +1 from 15:00 (max 4); never above MAX_ALIVE alive.
## - Spawn: Magpies (UnitType "magpie", data/units/magpie.tres) walk out of the Den door nearer the spot,
##   team NEUTRAL, group "magpies", meta &"loot" = 0, veteran modifier `den:veteran` (+10 % max HP from 10:00,
##   +20 % from 15:00; living Magpies get it too). Then they are handed to a ThiefBand
##   (res://scripts/ai/thief_band.gd, loaded by path): the band is added as a child of this guild, then
##   `setup(guild, thieves, target)` is called in the same frame. The band does everything else (5.3).
## Purely neutral (Q4): there is no hire / bribe / toll / purchase API on purpose.
## Messages (`message(text, seconds)`): the level connects it to hud.show_message; if nothing is connected the
## guild calls the parent's `hud.show_message` itself.

signal band_sent(band: Node)
signal band_finished(band: Node)
## A line for the HUD message area.
signal message(text: String, seconds: float)

const OPEN_TIME := 300.0            ## 5:00: first band, road targets.
const WORKER_RAID_TIME := 480.0     ## 8:00: remote-node worker targets.
const TICK := 75.0
const MAX_ALIVE := 6

const ROAD_TRIP_WINDOW := 120.0     ## A road is a target with a trip of the team in this window...
const WEIGHT_WINDOW := 180.0        ## ...weighted by the gold traded / crystals mined in this window.
const ROAD_BASE_WEIGHT := 30.0
const NODE_BASE_WEIGHT := 20.0
const NODE_MINED_WEIGHT := 0.5
const REMOTE_DISTANCE := 30.0       ## A node farther than this from the team's keep is remote.
const NODE_WORKER_RADIUS := 14.0
const MIN_NODE_WORKERS := 2
const MINING_SAMPLE := 10.0         ## Own mining samples (only without TradeNetwork.mined_recently).

const BAND_SIZE := 2
const BAND_SIZE_MID := 3
const BAND_SIZE_MAX := 4
const MID_TIME := 720.0             ## 12:00: bands of 3.
const MID_CARAVANS := 6             ## ...or 6+ caravans on the map.
const LATE_TIME := 900.0            ## 15:00: +1.

const SPOT_UNIT_RADIUS := 18.0
const SPOT_TOWER_RADIUS := 20.0
const SPOT_KEEP_RADIUS := 25.0
const RETRY_DELAY := 20.0
const MAX_RETRIES := 3

const VETERAN_MODIFIER := &"den:veteran"
const VETERAN_TIMES: Array[float] = [600.0, 900.0]   ## 10:00, 15:00.
const VETERAN_BONUS: Array[float] = [0.10, 0.20]     ## max_hp_pct at each step.

const MAGPIE_TYPE := "magpie"
const THIEF_BAND_PATH := "res://scripts/ai/thief_band.gd"
const MAGPIE_GROUP := &"magpies"
const LOOT_META := &"loot"
const SPAWN_RING := 1.0             ## Magpies stand on a ring this wide around the door.
const NAV_SNAP := 3.0
const DEFAULT_SEED := 1010

const MSG_ON_ROADS := "The Magpies are on the roads"

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2

## Returns the match time in seconds (the skirmish passes its match_time). Unset: the parent's match_time(),
## else this guild's own age.
var match_time_source: Callable
## Seeded rng for the weighted draw (the skirmish may reseed it).
var rng := RandomNumberGenerator.new()
## Where Magpies are added (default: this guild's parent, the level).
var spawn_parent: Node
## Hooks for tests and tools: the Magpie UnitType (default UnitType.find("magpie")) and the band Script
## (default THIEF_BAND_PATH).
var magpie_type: UnitType
var band_script: Script

var _age := 0.0
var _next_tick := OPEN_TIME
var _pending: Dictionary = {}           # {target, retries, retry_at}: a band waiting for a valid spot
var _bands: Array[Node] = []
var _announced := false
var _veteran_step := -1
var _net: Node = null
var _ledger_connected := false
var _ledger: Array[Dictionary] = []     # {t, team, post, amount}: deliveries, oldest first
var _net_check_left := 0.0
var _samples: Dictionary = {}           # node instance id -> {last: int, hist: Array of [t, taken]}
var _next_sample := 0.0
var _warned: Dictionary = {}


## The match's guild, or null (no trade on this map).
static func instance(tree: SceneTree) -> ThievesGuild:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("thieves_guild"):
		var g := node as ThievesGuild
		if g and not g.is_queued_for_deletion():
			return g
	return null


func _init() -> void:
	add_to_group("thieves_guild")
	rng.seed = DEFAULT_SEED


func _ready() -> void:
	add_to_group("thieves_guild")
	if not match_time_source.is_valid():
		var p := get_parent()
		if p and p.has_method(&"match_time"):
			match_time_source = Callable(p, &"match_time")
	_veteran_step = _veteran_step_at(match_time())
	_connect_network()


## Skirmish save (review W2-7): the one-time "on the roads" line.
func save_world_state() -> Dictionary:
	return {"announced": _announced}


func load_world_state(d: Dictionary) -> void:
	_announced = bool(d.get("announced", _announced))


func _physics_process(delta: float) -> void:
	_age += delta
	var now := match_time()
	if not _ledger_connected:
		_net_check_left -= delta
		if _net_check_left <= 0.0:
			_net_check_left = 1.0
			_connect_network()
	if now >= _next_sample:
		_next_sample = now + MINING_SAMPLE
		_sample_mining(now)
	var step := _veteran_step_at(now)
	if step != _veteran_step:
		_veteran_step = step
		for m in _living_magpies():
			_apply_veteran(m)
	if now < OPEN_TIME:
		return
	if not _pending.is_empty() and now >= float(_pending["retry_at"]):
		_try_pending(now)
	if now >= _next_tick:
		_next_tick += TICK
		if _next_tick <= now:
			_next_tick = now + TICK   # the clock jumped (tests, a paused tree): no burst of ticks
		_tick(now)


# ---------------------------------------------------------------- public

## Seconds of match time (match_time_source, else the parent's match_time(), else this guild's age).
func match_time() -> float:
	return float(match_time_source.call()) if match_time_source.is_valid() else _age


## True from 5:00 of match time.
func is_open() -> bool:
	return match_time() >= OPEN_TIME


## True from 8:00 (remote-node worker raids).
func worker_raids_open() -> bool:
	return match_time() >= WORKER_RAID_TIME


## Seconds until the next tick (a band leaves only if a target exists then).
func time_until_next_tick() -> float:
	return maxf(0.0, _next_tick - match_time())


## The two Magpie Dens (group "guilds", kind &"den").
func dens() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group("guilds"):
		if is_instance_valid(node) and StringName(str(node.get(&"kind"))) == &"den":
			out.append(node)
	return out


## The bands out on the map right now (not finished).
func bands() -> Array:
	var out: Array = []
	for b in _bands:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			out.append(b)
	return out


## Living Magpies on the map (group "magpies").
func magpies_alive() -> int:
	return _living_magpies().size()


## True while a drawn band waits for a valid spot (it retries every 20 s, 3 times).
func has_waiting_band() -> bool:
	return not _pending.is_empty()


## The size the next band gets now (before the MAX_ALIVE cap): 2; 3 with 6+ caravans on the map or from
## 12:00; +1 from 15:00 (max 4).
func band_size() -> int:
	var t := match_time()
	var n := BAND_SIZE
	if t >= MID_TIME or _caravans_on_map() >= MID_CARAVANS:
		n = BAND_SIZE_MID
	if t >= LATE_TIME:
		n += 1
	return mini(n, BAND_SIZE_MAX)


## The veteran max_hp_pct Magpies get now: 0, 0.10 (10:00) or 0.20 (15:00).
func veteran_bonus() -> float:
	var step := _veteran_step_at(match_time())
	return VETERAN_BONUS[step] if step >= 0 else 0.0


## Every target right now: {kind: &"road" / &"workers", team, post (road) or node (workers), spot, spots,
## weight}. `spot` = the first valid spot (Vector3.INF when none is valid right now), `spots` = every spot of
## that target in order (road: post end first). Empty before 5:00.
func targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var now := match_time()
	if now < OPEN_TIME:
		return out
	_prune_ledger(now)
	# Roads: (team, post) pairs with a trip in the last 120 s, in ledger order.
	var seen := {}
	for e in _ledger:
		if now - float(e["t"]) > ROAD_TRIP_WINDOW:
			continue
		var post: Variant = e["post"]
		if post == null or not is_instance_valid(post):
			continue
		var team := int(e["team"])
		var key := "%d:%d" % [team, (post as Object).get_instance_id()]
		if seen.has(key):
			continue
		seen[key] = true
		var spots := _road_spots(team, post)
		out.append({"kind": &"road", "team": team, "post": post, "spot": _first_valid(team, spots), "spots": spots,
				"weight": float(_gold_on(team, post, now)) + ROAD_BASE_WEIGHT})
	# Remote nodes, from 8:00.
	if now >= WORKER_RAID_TIME:
		for team: int in [PLAYER_TEAM, ENEMY_TEAM]:
			for node in _remote_nodes(team):
				if _workers_near(team, node).size() < MIN_NODE_WORKERS:
					continue
				var spot := _worker_spot(node)
				var spots: Array[Vector3] = []
				if spot != Vector3.INF:
					spots.append(spot)
				out.append({"kind": &"workers", "team": team, "node": node, "spot": _first_valid(team, spots),
						"spots": spots, "weight": NODE_MINED_WEIGHT * float(_mined_recently(node, now)) + NODE_BASE_WEIGHT})
	return out


## True when a band of the Magpies may lurk at `spot` against `team`: no soldier / wizard / champion / tracker
## of `team` within 18 m, no tower of `team` within 20 m, no keep of `team` within 25 m.
func is_spot_valid(team: int, spot: Vector3) -> bool:
	if spot == Vector3.INF or not is_inside_tree():
		return false
	var r2 := SPOT_UNIT_RADIUS * SPOT_UNIT_RADIUS
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or int(u.team) != team or not u.is_alive() or u.is_worker() or _is_caravan(u):
			continue
		if _flat_d2(u.global_position, spot) < r2:
			return false
	for node in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var bt: Variant = node.get(&"team")
		if bt == null or int(bt) != team:
			continue
		if node.has_method(&"is_alive") and not bool(node.call(&"is_alive")):
			continue
		var kind := _building_kind(node)
		var d2 := _flat_d2((node as Node3D).global_position, spot)
		if kind == &"keep" and d2 < SPOT_KEEP_RADIUS * SPOT_KEEP_RADIUS:
			return false
		if kind == &"tower" and d2 < SPOT_TOWER_RADIUS * SPOT_TOWER_RADIUS \
				and (not node.has_method(&"is_constructed") or bool(node.call(&"is_constructed"))):
			return false
	return true


## The first valid spot of a `targets()` entry now (Vector3.INF when none), e.g. for a road band moving on.
func valid_spot(target: Dictionary) -> Vector3:
	var spots: Array = target.get("spots", [])
	return _first_valid(int(target.get("team", -1)), spots)


## The Den nearer `pos` (from its door, by navmesh path length: map-fill.md 2.4, so a band never walks the
## long way round the river; straight line while the navmesh is not ready), or null without Dens.
func nearest_den(pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for d in dens():
		if not d is Node3D:
			continue
		var dd := path_distance(_door_of(d), pos)
		if dd < best_d:
			best_d = dd
			best = d
	return best


## The door of the Den nearer `pos` (Vector3.INF without Dens): where a fleeing band goes home.
func nearest_den_door(pos: Vector3) -> Vector3:
	var d := nearest_den(pos)
	return _door_of(d) if d else Vector3.INF


## Gold `team` delivered on the route to `post` in the last `seconds` (from TradeNetwork.delivered).
func gold_traded(team: int, post: Node, seconds: float = WEIGHT_WINDOW) -> int:
	var now := match_time()
	var sum := 0
	for e in _ledger:
		if int(e["team"]) == team and e["post"] == post and now - float(e["t"]) <= seconds:
			sum += int(e["amount"])
	return sum


## Records a delivery (connected to TradeNetwork.delivered; callers without a network may call it too).
func note_delivery(team: int, amount: int, post: Node) -> void:
	_ledger.append({"t": match_time(), "team": team, "post": post, "amount": maxi(0, amount)})


# ---------------------------------------------------------------- schedule

func _tick(now: float) -> void:
	if not _pending.is_empty():
		return   # the last band still waits at the door (it can't: 4 x 20 s < 75 s, but be safe)
	if magpies_alive() >= MAX_ALIVE:
		return
	var list := targets()
	if list.is_empty():
		return
	_pending = {"target": _draw(list), "retries": 0, "retry_at": now}
	_try_pending(now)


## Sends the waiting band if its target still has a valid spot; else waits RETRY_DELAY and retries, at most
## MAX_RETRIES times, then the band goes back in.
func _try_pending(now: float) -> void:
	var target := _refresh(_pending["target"])
	if target.is_empty():
		var list := targets()
		if not list.is_empty():
			target = _draw(list)
	var spot: Vector3 = target.get("spot", Vector3.INF) if not target.is_empty() else Vector3.INF
	if spot != Vector3.INF and magpies_alive() < MAX_ALIVE and not dens().is_empty():
		_pending = {}
		_send(target, spot)
		return
	if magpies_alive() >= MAX_ALIVE:
		_pending = {}
		return
	if not target.is_empty():
		_pending["target"] = target
	_pending["retries"] = int(_pending["retries"]) + 1
	if int(_pending["retries"]) > MAX_RETRIES:
		_pending = {}   # the band goes back in
		return
	_pending["retry_at"] = now + RETRY_DELAY


## The current targets() entry for the same kind / team / post or node ({} when it is not a target any more).
func _refresh(old: Dictionary) -> Dictionary:
	for t in targets():
		if t["kind"] == old.get("kind") and int(t["team"]) == int(old.get("team", -1)) \
				and t.get("post") == old.get("post") and t.get("node") == old.get("node"):
			return t
	return {}


func _draw(list: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for t in list:
		total += maxf(0.0, float(t["weight"]))
	if total <= 0.0:
		return list[0]
	var r := rng.randf() * total
	for t in list:
		r -= maxf(0.0, float(t["weight"]))
		if r < 0.0:
			return t
	return list[list.size() - 1]


func _send(target: Dictionary, spot: Vector3) -> void:
	var script := _band_script()
	var type := _magpie_type()
	if script == null or type == null:
		return
	var size := mini(band_size(), MAX_ALIVE - magpies_alive())
	if size < 1:
		return
	var den := nearest_den(spot)
	var door := _door_of(den)
	var parent := spawn_parent if spawn_parent and is_instance_valid(spawn_parent) else get_parent()
	var thieves: Array = []
	for i in size:
		var a := TAU * float(i) / float(size)
		var at := _snap(door + Vector3(cos(a), 0.0, sin(a)) * SPAWN_RING)
		var m := _make_magpie(type)
		if m == null:
			continue
		parent.add_child(m)
		m.global_position = at
		m.command_stop()
		_apply_veteran(m)
		thieves.append(m)
	if thieves.is_empty():
		return
	var t := target.duplicate()
	t["spot"] = spot
	t["den"] = den
	var band := script.new() as Node
	if band == null:
		for m in thieves:
			m.queue_free()
		return
	band.name = "ThiefBand"
	add_child(band, true)
	if band.has_method(&"setup"):
		band.call(&"setup", self, thieves, t)
	_bands.append(band)
	if band.has_signal(&"finished"):
		band.connect(&"finished", _on_band_finished.bind(band), CONNECT_ONE_SHOT)
	band.tree_exiting.connect(_on_band_exiting.bind(band), CONNECT_ONE_SHOT)
	if den and den.has_method(&"play_band_out"):
		den.call(&"play_band_out")
	if not _announced:
		_announced = true
		_say(MSG_ON_ROADS, 4.0)
	band_sent.emit(band)


func _make_magpie(type: UnitType) -> Unit:
	var m := Worker.make_unit(type)
	if m == null:
		return null
	m.team = NEUTRAL_TEAM as Unit.Team
	m.add_to_group(MAGPIE_GROUP)
	m.set_meta(LOOT_META, 0)
	return m


func _on_band_finished(_arg: Variant, band: Node) -> void:
	_finish(band)


func _on_band_exiting(band: Node) -> void:
	_finish(band)


func _finish(band: Node) -> void:
	if not _bands.has(band):
		return
	_bands.erase(band)
	band_finished.emit(band)
	if is_instance_valid(band) and not band.is_queued_for_deletion() and band.is_inside_tree():
		band.queue_free.call_deferred()


# ---------------------------------------------------------------- targets: data

func _connect_network() -> void:
	if _ledger_connected or not is_inside_tree():
		return
	var net := _network()
	if net and net.has_signal(&"delivered"):
		net.connect(&"delivered", _on_delivered)
		_ledger_connected = true


func _network() -> Node:
	if _net != null and is_instance_valid(_net) and not _net.is_queued_for_deletion():
		return _net
	_net = get_tree().get_first_node_in_group(&"trade_network") if is_inside_tree() else null
	return _net


func _on_delivered(team: int, _caravan: Node, amount: int, post: Node) -> void:
	note_delivery(team, amount, post)


func _prune_ledger(now: float) -> void:
	var keep := maxf(ROAD_TRIP_WINDOW, WEIGHT_WINDOW)
	while not _ledger.is_empty() and now - float(_ledger[0]["t"]) > keep:
		_ledger.remove_at(0)


func _gold_on(team: int, post: Variant, now: float) -> int:
	var sum := 0
	for e in _ledger:
		if int(e["team"]) == team and e["post"] == post and now - float(e["t"]) <= WEIGHT_WINDOW:
			sum += int(e["amount"])
	return sum


func _road_spots(team: int, post: Variant) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var net := _network()
	if net and net.has_method(&"ambush_spots"):
		for p: Variant in net.call(&"ambush_spots", team, post):
			if p is Vector3:
				out.append(p)
	return out


func _worker_spot(node: Node) -> Vector3:
	var net := _network()
	if net and net.has_method(&"worker_spot"):
		var p: Variant = net.call(&"worker_spot", node)
		if p is Vector3:
			return p
	return Vector3.INF


## TradeNetwork.remote_nodes(team), else the crystal nodes more than 30 m from the team's keep.
func _remote_nodes(team: int) -> Array:
	var net := _network()
	if net and net.has_method(&"remote_nodes"):
		var out: Array = []
		for n: Variant in net.call(&"remote_nodes", team):
			if n != null and is_instance_valid(n) and n is Node3D:
				out.append(n)
		return out
	var home := _keep_position(team)
	var list: Array = []
	if home == Vector3.INF:
		return list
	for node in get_tree().get_nodes_in_group("crystal_nodes"):
		var cn := node as CrystalNode
		if cn and not cn.is_depleted() and sqrt(_flat_d2(cn.global_position, home)) > REMOTE_DISTANCE:
			list.append(cn)
	return list


## The team's keep: the level's base_center(team) (stays after the keep falls), else its living keep.
func _keep_position(team: int) -> Vector3:
	var level := get_parent()
	if level and level.has_method(&"base_center"):
		var p: Variant = level.call(&"base_center", team)
		if p is Vector3:
			return p
	for node in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(node) or not node is Node3D or node.get(&"team") == null:
			continue
		if int(node.get(&"team")) == team and _building_kind(node) == &"keep" \
				and (not node.has_method(&"is_alive") or bool(node.call(&"is_alive"))):
			return (node as Node3D).global_position
	return Vector3.INF


func _workers_near(team: int, node: Node3D) -> Array:
	var out: Array = []
	var r2 := NODE_WORKER_RADIUS * NODE_WORKER_RADIUS
	var at := node.global_position
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive() and u.is_worker() and _flat_d2(u.global_position, at) <= r2:
			out.append(u)
	return out


## Crystals taken from `node` in the last 180 s: TradeNetwork.mined_recently, else own 10 s samples.
func _mined_recently(node: Node, now: float) -> int:
	var net := _network()
	if net and net.has_method(&"mined_recently"):
		return int(net.call(&"mined_recently", node, WEIGHT_WINDOW))
	var s: Dictionary = _samples.get(node.get_instance_id(), {})
	var sum := 0
	for h: Array in s.get("hist", []):
		if now - float(h[0]) <= WEIGHT_WINDOW:
			sum += int(h[1])
	return sum


func _sample_mining(now: float) -> void:
	if not is_inside_tree():
		return
	var net := _network()
	if net and net.has_method(&"mined_recently"):
		return
	for node in get_tree().get_nodes_in_group("crystal_nodes"):
		var cn := node as CrystalNode
		if cn == null:
			continue
		var id := cn.get_instance_id()
		var s: Dictionary = _samples.get(id, {})
		if s.is_empty():
			_samples[id] = {"last": cn.crystals_left, "hist": []}
			continue
		var taken := int(s["last"]) - cn.crystals_left
		s["last"] = cn.crystals_left
		var hist: Array = s["hist"]
		if taken > 0:
			hist.append([now, taken])
		while not hist.is_empty() and now - float(hist[0][0]) > WEIGHT_WINDOW:
			hist.remove_at(0)


func _first_valid(team: int, spots: Array) -> Vector3:
	for p: Variant in spots:
		if p is Vector3 and is_spot_valid(team, p):
			return p
	return Vector3.INF


# ---------------------------------------------------------------- helpers

func _living_magpies() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(MAGPIE_GROUP):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_in_group(&"units"):
			continue
		if node.has_method(&"is_alive") and not bool(node.call(&"is_alive")):
			continue
		out.append(node)
	return out


func _caravans_on_map() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"caravans"):
		if is_instance_valid(node) and not node.is_queued_for_deletion() \
				and (not node.has_method(&"is_alive") or bool(node.call(&"is_alive"))):
			n += 1
	return n


func _veteran_step_at(t: float) -> int:
	var step := -1
	for i in VETERAN_TIMES.size():
		if t >= VETERAN_TIMES[i]:
			step = i
	return step


func _apply_veteran(m: Node) -> void:
	if not is_instance_valid(m) or not m.has_method(&"add_modifier"):
		return
	var step := _veteran_step_at(match_time())
	if step < 0:
		if m.has_method(&"remove_modifier"):
			m.call(&"remove_modifier", VETERAN_MODIFIER)
		return
	m.call(&"add_modifier", VETERAN_MODIFIER, {"max_hp_pct": VETERAN_BONUS[step]})


func _magpie_type() -> UnitType:
	if magpie_type == null:
		magpie_type = UnitType.find(MAGPIE_TYPE)
	if magpie_type == null:
		_warn_once("type", "ThievesGuild: no data/units/%s.tres yet, no Magpies leave the Dens" % MAGPIE_TYPE)
	return magpie_type


func _band_script() -> Script:
	if band_script == null and ResourceLoader.exists(THIEF_BAND_PATH):
		band_script = load(THIEF_BAND_PATH) as Script
	if band_script == null or not band_script.can_instantiate():
		_warn_once("band", "ThievesGuild: no ThiefBand (%s) yet, no Magpies leave the Dens" % THIEF_BAND_PATH)
		return null
	return band_script


func _warn_once(key: String, text: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		push_warning(text)


func _is_caravan(u: Unit) -> bool:
	if u.is_in_group(&"caravans"):
		return true
	var v: Variant = u.unit_type.get(&"is_caravan") if u.unit_type != null else null
	return v is bool and v


func _building_kind(b: Node) -> StringName:
	if b is Keep:
		return &"keep"
	var bt: Variant = b.get(&"building_type")
	if bt is Object and is_instance_valid(bt):
		return StringName(str((bt as Object).get(&"kind")))
	return &""


func _door_of(house: Node) -> Vector3:
	if house == null or not is_instance_valid(house):
		return Vector3.INF
	if house.has_method(&"door_point"):
		var p: Variant = house.call(&"door_point")
		if p is Vector3:
			return p
	return (house as Node3D).global_position if house is Node3D else Vector3.INF


static func _flat_d2(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return dx * dx + dz * dz


## Walking distance from `from` to `to`: the navmesh path length (plus the straight bits from / to the path's
## ends when a point is off the navmesh); the flat straight distance while there is no baked navmesh.
func path_distance(from: Vector3, to: Vector3) -> float:
	if not from.is_finite() or not to.is_finite():
		return INF
	var straight := sqrt(_flat_d2(from, to))
	if not is_inside_tree() or get_viewport() == null:
		return straight
	var map := get_viewport().find_world_3d().navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return straight
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	if path.size() < 2:
		return straight
	var total := sqrt(_flat_d2(from, path[0])) + sqrt(_flat_d2(path[path.size() - 1], to))
	for i in range(1, path.size()):
		total += sqrt(_flat_d2(path[i - 1], path[i]))
	return total


## `p` moved onto the navmesh when a navmesh point is within NAV_SNAP.
func _snap(p: Vector3) -> Vector3:
	if not is_inside_tree() or get_viewport() == null:
		return p
	var map := get_viewport().find_world_3d().navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	if Vector2(q.x - p.x, q.z - p.z).length() <= NAV_SNAP:
		return Vector3(q.x, p.y, q.z)
	return p


func _say(text: String, seconds: float) -> void:
	if not message.get_connections().is_empty():
		message.emit(text, seconds)
		return
	var level := get_parent()
	var hud: Variant = level.get(&"hud") if level else null
	if hud is Object and is_instance_valid(hud) and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, seconds)
