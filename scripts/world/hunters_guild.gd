class_name HuntersGuild
extends Node
## The Hunters' Guild (docs/design/market-trade.md sections 6.2-6.3, contract section 12): one node per match
## in group "hunters_guild", created by the skirmish when `trade_enabled`; find it with
## `HuntersGuild.instance(get_tree())` (null when trade is off). It runs both Greywater Lodges.
## - Contracts (bought with gold from the team's GoldBank, group "gold_banks"): Outriders 120 gold, 2 trackers,
##   180 s; Sweep 100 gold, 3 trackers, 120 s. Open from 5:00 of match time, one running contract of each kind
##   per team, COOLDOWN s after it ends. Refusals in order: see `can_hire`.
## - Trackers (`data/units/greywater_tracker.tres`, a code placeholder with the 6.1 numbers until it exists)
##   belong to the hiring team, join group "trackers", walk out of the Lodge whose door is nearer their first
##   destination (`first_destination`) and are handed to a TrackerContract
##   (res://scripts/ai/tracker_contract.gd, load-guarded; a minimal built-in countdown stands in while it is
##   missing). The contract's `ended(contract)` signal ends the contract here; the guild also ends it when the
##   duration is over (+ END_GRACE), when every tracker is gone, or when the contract node was freed.
## - Lodge reward: every Magpie (group "magpies") killed pays REWARD_PER_MAGPIE gold (source &"reward") to the
##   team credited with the killing blow (trackers credit their hiring team: they belong to it). The local
##   team's line `Greywater Lodge pays 20 gold for 2 Magpies` is summed and sent at most once per 10 s.
## Messages for the local team go out through `message(text, seconds)` (the level connects it to
## hud.show_message). Other step-10 parts (GoldBank, TradeNetwork, Caravan, GuildHouse, TrackerContract) are
## reached only through groups, `has_method()` and `get()`.

signal contract_started(team: int, kind: StringName, contract: Node)
signal contract_ended(team: int, kind: StringName)
## Gold paid to `team` for one Magpie kill (the Lodge reward).
signal reward_paid(team: int, amount: int)
## A line for the HUD message area (only what the local team should read).
signal message(text: String, seconds: float)

const OPEN_TIME := 300.0                 ## 5:00 of match time.
## Contract kinds (6.2): price in gold, trackers sent, duration in seconds, display name.
const CONTRACTS := {
	&"outriders": {"cost": 120, "trackers": 2, "duration": 180.0, "name": "Outriders"},
	&"sweep": {"cost": 100, "trackers": 3, "duration": 120.0, "name": "Sweep"},
}
const KINDS: Array[StringName] = [&"outriders", &"sweep"]
const COOLDOWN := 30.0                   ## After a contract ends, before the same kind can be hired again.
const REWARD_PER_MAGPIE := 10            ## Gold per Magpie killed (6.3).
const REWARD_MESSAGE_INTERVAL := 10.0    ## The summed reward line at most once per 10 s.
const REWARD_MESSAGE_GATHER := 1.0       ## Kills this close together share one line.
const END_GRACE := 1.0                   ## The guild ends a contract that outlived its duration by this much.
const SPAWN_SPREAD := 1.2                ## Trackers stand on a small ring around the Lodge door.
const NAV_SNAP := 3.0

const TRACKER_TYPE_ID := "greywater_tracker"
const TRACKER_CONTRACT_PATH := "res://scripts/ai/tracker_contract.gd"
const TRACKER_GROUP := &"trackers"
const MAGPIE_GROUP := &"magpies"
## Lodge doors when the level has no GuildHouse of kind &"lodge" (market-trade.md 2.3).
const DEFAULT_LODGE_DOORS: Array[Vector3] = [Vector3(-45.0, 0.0, -51.0), Vector3(45.0, 0.0, 51.0)]

## can_hire / hire refusals, in the order they are checked (6.2). R_UNKNOWN comes first (bad kind).
const R_UNKNOWN := "Unknown contract"
const R_CLOSED := "The Lodge opens at 5:00"
const R_RUNNING := "Contract already running"
const R_COOLDOWN := "On cooldown"
const R_NO_CARAVANS := "No caravans to escort"
const R_GOLD := "Not enough gold"

const MSG_HIRED := {
	&"outriders": "Outriders hired: 2 trackers guard your caravans",
	&"sweep": "Sweep hired: 3 trackers clear your roads and mines",
}
const MSG_REWARD := "Greywater Lodge pays %d gold for %d %s"

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2

## The team whose player reads the messages.
@export var local_team: int = PLAYER_TEAM
## Returns the match time in seconds (the skirmish passes its match_time). Unset: the parent's
## `match_time()` if it has one, else this node's own age.
var match_time_source: Callable
## Where trackers are added (default: this guild's parent, the level).
var spawn_parent: Node
## Hooks for tests and tools: the tracker UnitType (default: data/units/greywater_tracker.tres, else a code
## placeholder) and the contract Script (default: TRACKER_CONTRACT_PATH when it exists and compiles).
var tracker_type: UnitType
var contract_script: Script

var _age := 0.0
var _clock := 0.0                 # seconds this guild has run (durations and cooldowns)
var _running: Dictionary = {}     # "team:kind" -> {team, kind, contract, trackers, ends_at}
var _cooldown_until: Dictionary = {}   # "team:kind" -> _clock value
var _paid: Dictionary = {}        # victim instance id -> true (never pay a Magpie twice)
var _slain: Dictionary = {}       # team -> Magpies killed by that team
var _rewards: Dictionary = {}     # team -> gold paid by the Lodge
var _msg_gold := 0                # the local team's reward line waiting to be sent
var _msg_count := 0
var _msg_at := INF                # _clock value when the waiting line goes out
var _msg_last := -INF             # _clock value of the last reward line

static var _placeholder_type: UnitType


## The match's guild, or null when the level has none (trade off, missions).
static func instance(tree: SceneTree) -> HuntersGuild:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("hunters_guild"):
		var g := node as HuntersGuild
		if g and not g.is_queued_for_deletion():
			return g
	return null


func _init() -> void:
	add_to_group("hunters_guild")


func _ready() -> void:
	add_to_group("hunters_guild")
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died") and not events.is_connected(&"unit_died", _on_unit_died):
		events.connect(&"unit_died", _on_unit_died)


func _physics_process(delta: float) -> void:
	_age += delta
	_clock += delta
	if not _running.is_empty():
		_check_running()
	if _msg_count > 0 and _clock >= _msg_at:
		_flush_reward_message()


# ---------------------------------------------------------------- queries

## Seconds of match time (match_time_source, else the parent's match_time(), else this node's age).
func match_time() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	var level := get_parent()
	if level and level.has_method(&"match_time"):
		return float(level.call(&"match_time"))
	return _age


## True from 5:00 of match time on.
func is_open() -> bool:
	return match_time() >= OPEN_TIME


## Seconds until the Lodges open (0 once open).
func time_until_open() -> float:
	return maxf(0.0, OPEN_TIME - match_time())


## The Greywater Lodges of the level (GuildHouse nodes in group "guilds" with kind &"lodge").
func lodges() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group("guilds"):
		if is_instance_valid(node) and StringName(str(node.get(&"kind"))) == &"lodge":
			out.append(node)
	return out


## Gold price of a contract kind (0 for an unknown kind).
func contract_cost(kind: StringName) -> int:
	var c: Dictionary = CONTRACTS.get(StringName(kind), {})
	return int(c.get("cost", 0))


## Trackers a contract kind sends (0 for an unknown kind).
func contract_trackers(kind: StringName) -> int:
	var c: Dictionary = CONTRACTS.get(StringName(kind), {})
	return int(c.get("trackers", 0))


## Seconds a contract kind lasts (0 for an unknown kind).
func contract_duration(kind: StringName) -> float:
	var c: Dictionary = CONTRACTS.get(StringName(kind), {})
	return float(c.get("duration", 0.0))


## "" if `team` can hire `kind` now, else the first refusal: "Unknown contract", "The Lodge opens at 5:00",
## "Contract already running", "On cooldown", "No caravans to escort" (Outriders only), "Not enough gold".
func can_hire(team: int, kind: StringName) -> String:
	kind = StringName(kind)
	if not CONTRACTS.has(kind):
		return R_UNKNOWN
	if not is_open():
		return R_CLOSED
	if is_running(team, kind):
		return R_RUNNING
	if cooldown_left(team, kind) > 0.0:
		return R_COOLDOWN
	if kind == &"outriders" and _living_caravans(team).is_empty():
		return R_NO_CARAVANS
	var bank := gold_bank(team)
	if bank == null or not bank.has_method(&"can_afford") or not bool(bank.call(&"can_afford", contract_cost(kind))):
		return R_GOLD
	return ""


## Pays the contract from the team's GoldBank, sends its trackers out of the Lodge nearer their first
## destination and hands them to a TrackerContract. "" = ok, else the reason (see can_hire).
func hire(team: int, kind: StringName) -> String:
	kind = StringName(kind)
	var reason := can_hire(team, kind)
	if reason != "":
		return reason
	var bank := gold_bank(team)
	if not bool(bank.call(&"spend", contract_cost(kind))):
		return R_GOLD
	var lodge := _pick_lodge(team, first_destination(team, kind))
	var contract := _start_contract(team, kind, lodge)
	var lodge_node: Node = lodge["node"]
	if lodge_node and is_instance_valid(lodge_node) and lodge_node.has_method(&"play_contract"):
		lodge_node.call(&"play_contract")
	if team == local_team:
		message.emit(String(MSG_HIRED.get(kind, "")), 4.0)
	contract_started.emit(team, kind, contract)
	return ""


## Load (TrackerContract.create_for_save): starts a contract of `kind` for `team` like hire() but quietly: no price
## (the caller handles it), no open / cooldown / caravan checks, no "hired" line, no Lodge animation, no
## contract_started. Fresh trackers walk out of the Lodge nearer the first destination with the full duration (the
## caller may set the time left). Returns the contract node (the running one if there is already one), or null for
## an unknown kind.
func restore_contract(team: int, kind: StringName) -> Node:
	kind = StringName(kind)
	if not CONTRACTS.has(kind):
		return null
	if is_running(team, kind):
		return contract_of(team, kind)
	return _start_contract(team, kind, _pick_lodge(team, first_destination(team, kind)))


## Spawns the trackers at `lodge`'s door, makes the contract and records it as running (hire / restore_contract).
func _start_contract(team: int, kind: StringName, lodge: Dictionary) -> Node:
	var door: Vector3 = lodge["door"]
	var trackers := _spawn_trackers(team, kind, contract_trackers(kind), door)
	var duration := contract_duration(kind)
	var contract := _make_contract(team, kind, trackers, duration)
	for t: Node in trackers:
		t.set_meta(&"_tracker_contract", contract)
	_running[_key(team, kind)] = {"team": team, "kind": kind, "contract": contract, "trackers": trackers,
			"ends_at": _clock + duration}
	return contract


## True while `team` has a running contract of `kind`.
func is_running(team: int, kind: StringName) -> bool:
	return _running.has(_key(team, StringName(kind)))


## The running contract node of `team` / `kind`, or null.
func contract_of(team: int, kind: StringName) -> Node:
	var rec: Dictionary = _running.get(_key(team, StringName(kind)), {})
	var c: Variant = rec.get("contract")
	return c if is_instance_valid(c) and c is Node else null


## Seconds left on the running contract of `team` / `kind` (0 when none runs).
func contract_time_left(team: int, kind: StringName) -> float:
	var rec: Dictionary = _running.get(_key(team, StringName(kind)), {})
	if rec.is_empty():
		return 0.0
	var c: Variant = rec.get("contract")
	if is_instance_valid(c) and c is Node and (c as Node).has_method(&"time_left"):
		return maxf(0.0, float((c as Node).call(&"time_left")))
	return maxf(0.0, float(rec["ends_at"]) - _clock)


## Seconds before `team` may hire `kind` again after its last contract ended (0 = no cooldown).
func cooldown_left(team: int, kind: StringName) -> float:
	return maxf(0.0, float(_cooldown_until.get(_key(team, StringName(kind)), -INF)) - _clock)


## Magpies killed by `team` since the match started (end screen).
func magpies_slain(team: int) -> int:
	return int(_slain.get(team, 0))


## Gold the Lodges paid `team` for Magpies.
func rewards_paid(team: int) -> int:
	return int(_rewards.get(team, 0))


## The team's GoldBank (group "gold_banks"), or null when trade is off.
func gold_bank(team: int) -> Node:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group("gold_banks"):
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node.get(&"team") != null \
				and int(node.get(&"team")) == team:
			return node
	return null


## Where the first tracker of a `kind` contract heads, Vector3.INF when unknown. Outriders: the caravan the
## first tracker will shadow (escort_order). Sweep: the first of sweep_spots().
func first_destination(team: int, kind: StringName) -> Vector3:
	match StringName(kind):
		&"outriders":
			var order := escort_order(team)
			if not order.is_empty():
				return _flat((order[0] as Node3D).global_position)
		&"sweep":
			var spots := sweep_spots(team)
			if not spots.is_empty():
				return spots[0]
	return Vector3.INF


## The team's living caravans in the order Outriders pick them (6.2): loaded ones farthest from home first,
## then the others on the longest route first.
func escort_order(team: int) -> Array:
	var loaded: Array = []
	var empty: Array = []
	for c: Node3D in _living_caravans(team):
		var is_loaded := false
		if c.has_method(&"is_loaded"):
			is_loaded = bool(c.call(&"is_loaded"))
		elif c.get(&"cargo") != null:
			is_loaded = int(c.get(&"cargo")) > 0
		if is_loaded:
			loaded.append([_distance_from_home(c, team), c])
		else:
			empty.append([_route_length_of(c, team), c])
	var by_first_desc := func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0])
	loaded.sort_custom(by_first_desc)
	empty.sort_custom(by_first_desc)
	var out: Array = []
	for pair: Array in loaded + empty:
		out.append(pair[1])
	return out


## The spots a Sweep walks (6.2): the worker (W) spots of the team's remote nodes that have workers, then the
## ambush spots of its busiest route, then those of the other routes (duplicates dropped). Empty without a
## TradeNetwork.
func sweep_spots(team: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var net := _trade_network()
	if net == null:
		return out
	if net.has_method(&"remote_nodes") and net.has_method(&"worker_spot"):
		for node: Variant in net.call(&"remote_nodes", team):
			if not (is_instance_valid(node) and node is Node):
				continue
			var workers: Array = net.call(&"workers_at", team, node) if net.has_method(&"workers_at") else []
			if workers.is_empty():
				continue
			_append_unique(out, net.call(&"worker_spot", node))
	if net.has_method(&"posts") and net.has_method(&"ambush_spots"):
		var ranked: Array = []
		var i := 0
		for post: Variant in net.call(&"posts"):
			if not (is_instance_valid(post) and post is Node):
				continue
			var trips := int(net.call(&"trips", team, post, 180.0)) if net.has_method(&"trips") else 0
			var far := bool(net.call(&"is_far", team, post)) if net.has_method(&"is_far") else false
			# Busiest first; ties: near posts first, then the posts' own order.
			ranked.append([trips, 0 if far else 1, -i, post])
			i += 1
		ranked.sort_custom(func(a: Array, b: Array) -> bool:
			for k in 3:
				if int(a[k]) != int(b[k]):
					return int(a[k]) > int(b[k])
			return false)
		for r: Array in ranked:
			for spot: Variant in net.call(&"ambush_spots", team, r[3]):
				_append_unique(out, spot)
	return out


## The door the trackers of a `kind` contract of `team` would walk out of right now.
func lodge_door_for(team: int, kind: StringName) -> Vector3:
	return _pick_lodge(team, first_destination(team, kind))["door"]


## The door of the Lodge nearer `pos` by navmesh path length (DEFAULT_LODGE_DOORS without Lodges; Vector3.INF
## for a non-finite `pos`).
func nearest_lodge_door(pos: Vector3) -> Vector3:
	if not pos.is_finite():
		return Vector3.INF
	return _pick_lodge(-1, _flat(pos))["door"]


## Sends trackers away where they stand: `leave_map()` (1 s fade, no death, no XP) when the unit has it, else a
## 1 s shrink and free. TrackerContracts may use it at their end; the built-in stand-in does.
static func fade_out_trackers(trackers: Array) -> void:
	for t: Variant in trackers:
		if not (is_instance_valid(t) and t is Node):
			continue
		var n := t as Node
		if n.is_queued_for_deletion() or n.has_meta(&"tracker_leaving"):
			continue
		if n.has_method(&"is_alive") and not bool(n.call(&"is_alive")):
			continue
		n.set_meta(&"tracker_leaving", true)
		if n.has_method(&"leave_map"):
			n.call(&"leave_map")
			continue
		for g: StringName in [&"units", TRACKER_GROUP]:
			if n.is_in_group(g):
				n.remove_from_group(g)
		if n is CollisionObject3D:
			(n as CollisionObject3D).collision_layer = 0
		n.process_mode = Node.PROCESS_MODE_DISABLED
		var n3 := n as Node3D
		if n3 == null or not n3.is_inside_tree():
			n.queue_free()
			continue
		var tween := n3.get_tree().create_tween()
		tween.tween_property(n3, "scale", Vector3(0.05, 0.05, 0.05), 1.0)
		tween.tween_callback(func() -> void:
			if is_instance_valid(n3):
				n3.queue_free())


# ---------------------------------------------------------------- contracts

func _key(team: int, kind: StringName) -> String:
	return "%d:%s" % [team, kind]


## A TrackerContract (setup before it enters the tree, as a child of this guild), else the built-in stand-in.
func _make_contract(team: int, kind: StringName, trackers: Array, duration: float) -> Node:
	var script := contract_script
	if script == null and ResourceLoader.exists(TRACKER_CONTRACT_PATH):
		script = load(TRACKER_CONTRACT_PATH) as Script
	var contract: Node = null
	if script and script.can_instantiate():
		contract = script.new() as Node
	if contract == null or not contract.has_method(&"setup") or not contract.has_signal(&"ended"):
		if contract:
			contract.free()
		contract = FallbackContract.new()
	contract.name = "TrackerContract_%s_%d" % [kind, team]
	contract.call(&"setup", self, team, kind, trackers, duration)
	add_child(contract)
	contract.connect(&"ended", _on_contract_ended)
	return contract


func _on_contract_ended(contract: Node) -> void:
	for key: String in _running.keys():
		if _running[key]["contract"] == contract:
			_finish(key)
			return


## Ends contracts whose node is gone, whose trackers are all gone, or that outlived their duration.
func _check_running() -> void:
	for key: String in _running.keys():
		if not _running.has(key):
			continue
		var rec: Dictionary = _running[key]
		var c: Variant = rec["contract"]
		var alive := _living(rec["trackers"])
		if not (is_instance_valid(c) and c is Node) or (c as Node).is_queued_for_deletion():
			fade_out_trackers(alive)
			_finish(key)
			continue
		if alive.is_empty() or _clock >= float(rec["ends_at"]) + END_GRACE:
			if (c as Node).has_method(&"end_contract"):
				(c as Node).call(&"end_contract")   # emits ended -> _finish
			if _running.has(key):
				fade_out_trackers(alive)
				_finish(key)


func _finish(key: String) -> void:
	if not _running.has(key):
		return
	var rec: Dictionary = _running[key]
	_running.erase(key)
	var c: Variant = rec["contract"]
	if is_instance_valid(c) and c is Node and (c as Node).is_connected(&"ended", _on_contract_ended):
		(c as Node).disconnect(&"ended", _on_contract_ended)
	_cooldown_until[key] = _clock + COOLDOWN
	contract_ended.emit(int(rec["team"]), StringName(rec["kind"]))


# ---------------------------------------------------------------- trackers

## The Lodge {node, door} whose door is nearest `dest` (the team's keep when `dest` is INF) by navmesh path
## length (map-fill.md 2.4: trackers never walk the long way round the river; straight line while the navmesh is
## not ready). Without lodges in the level: DEFAULT_LODGE_DOORS with node null.
func _pick_lodge(team: int, dest: Vector3) -> Dictionary:
	var candidates: Array = []
	for l: Node in lodges():
		var door := Vector3.INF
		if l.has_method(&"door_point"):
			door = l.call(&"door_point")
		elif l is Node3D:
			door = (l as Node3D).global_position
		candidates.append({"node": l, "door": _flat(door)})
	if candidates.is_empty():
		for d in DEFAULT_LODGE_DOORS:
			candidates.append({"node": null, "door": d})
	if dest == Vector3.INF:
		var k: Keep = Keep.nearest(team, Vector3.ZERO) if is_inside_tree() else null
		dest = _flat(k.global_position) if k else Vector3.ZERO
	var best: Dictionary = candidates[0]
	var best_d := INF
	for c: Dictionary in candidates:
		var d := path_distance(c["door"] as Vector3, dest)
		if d < best_d:
			best_d = d
			best = c
	return best


func _spawn_trackers(team: int, kind: StringName, count: int, door: Vector3) -> Array:
	var out: Array = []
	var type := _tracker_type()
	var parent := spawn_parent if spawn_parent and is_instance_valid(spawn_parent) else get_parent()
	if type == null or parent == null:
		push_warning("HuntersGuild: can't spawn trackers (no type or no parent)")
		return out
	for i in count:
		var unit := type.create_unit()
		if unit == null:
			continue
		unit.set(&"team", team)
		unit.name = "Tracker_%s_%d_%d" % [kind, team, i]
		unit.add_to_group(TRACKER_GROUP)   # before _ready: GoldBank.apply_wares skips trackers
		unit.set_meta(&"hired_by", team)
		unit.set_meta(&"tracker_kind", kind)
		var a := TAU * float(i) / float(maxi(1, count)) + PI * 0.25
		var at := _snap(door + Vector3(cos(a), 0.0, sin(a)) * SPAWN_SPREAD)
		unit.position = at   # the level sits at the origin; set again below in world space
		parent.add_child(unit)
		unit.global_position = at
		unit.command_stop()   # the door is its first "home"; the contract moves it from here
		out.append(unit)
	return out


## The tracker UnitType: the override, else data/units/greywater_tracker.tres, else a code placeholder with
## the numbers of 6.1 (until 10.C6 lands).
func _tracker_type() -> UnitType:
	if tracker_type:
		return tracker_type
	var t := UnitType.find(TRACKER_TYPE_ID)
	if t:
		return t
	if _placeholder_type == null:
		push_warning("HuntersGuild: no data/units/%s.tres yet, using a placeholder tracker" % TRACKER_TYPE_ID)
		var p := UnitType.new()
		p.id = StringName(TRACKER_TYPE_ID)
		p.display_name = "Greywater Tracker"
		p.faction = &"neutral"
		p.pop = 0
		p.cost = 0
		p.kill_xp = 40
		p.train_time = 0.0
		p.max_hp = 240.0
		p.armor = 5.0
		p.attack_damage = 12.0
		p.attack_range = 7.0
		p.attack_cooldown = 1.2
		p.move_speed = 5.4
		p.aggro_range = 0.0
		p.radius = 0.45
		p.body_height = 1.8
		p.on_hit_status = &"rooted"
		p.on_hit_duration = 0.5
		p.body_color = Color(0.40, 0.48, 0.38)
		p.projectile_color = Color(1.0, 0.75, 0.35)
		if &"commandable" in p:
			p.set(&"commandable", false)
		_placeholder_type = p
	return _placeholder_type


# ---------------------------------------------------------------- Lodge reward

func _on_unit_died(victim: Node) -> void:
	if victim == null or not is_instance_valid(victim) or not _is_magpie(victim):
		return
	var id := victim.get_instance_id()
	if _paid.has(id):
		return
	var team := EssenceBank.killer_team_of(victim)
	if team != PLAYER_TEAM and team != ENEMY_TEAM:
		return   # Magpies killed by neutrals (or nobody) pay no one
	_paid[id] = true
	_slain[team] = int(_slain.get(team, 0)) + 1
	var bank := gold_bank(team)
	if bank == null or not bank.has_method(&"add"):
		return
	bank.call(&"add", REWARD_PER_MAGPIE, &"reward")
	_rewards[team] = int(_rewards.get(team, 0)) + REWARD_PER_MAGPIE
	reward_paid.emit(team, REWARD_PER_MAGPIE)
	if team == local_team:
		if _msg_count == 0:
			_msg_at = maxf(_clock + REWARD_MESSAGE_GATHER, _msg_last + REWARD_MESSAGE_INTERVAL)
		_msg_gold += REWARD_PER_MAGPIE
		_msg_count += 1


func _flush_reward_message() -> void:
	message.emit(MSG_REWARD % [_msg_gold, _msg_count, "Magpie" if _msg_count == 1 else "Magpies"], 4.0)
	_msg_last = _clock
	_msg_gold = 0
	_msg_count = 0
	_msg_at = INF


func _is_magpie(unit: Node) -> bool:
	if unit.is_in_group(MAGPIE_GROUP):
		return true
	var type: Variant = unit.get(&"unit_type")
	return is_instance_valid(type) and type is Object and StringName(str((type as Object).get(&"id"))) == &"magpie"


# ---------------------------------------------------------------- helpers

func _living_caravans(team: int) -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group("caravans"):
		if not is_instance_valid(node) or not node is Node3D or node.get(&"team") == null:
			continue
		if int(node.get(&"team")) != team:
			continue
		if node.has_method(&"is_alive") and not bool(node.call(&"is_alive")):
			continue
		out.append(node)
	return out


func _living(nodes: Array) -> Array:
	var out: Array = []
	for n: Variant in nodes:
		if is_instance_valid(n) and n is Node and (n as Node).is_inside_tree() \
				and not (n as Node).has_meta(&"tracker_leaving") \
				and (not (n as Node).has_method(&"is_alive") or bool((n as Node).call(&"is_alive"))):
			out.append(n)
	return out


## Distance of a caravan from its home Bazaar (else the team's keep, else 0).
func _distance_from_home(c: Node3D, team: int) -> float:
	var home: Variant = c.get(&"home_market")
	if is_instance_valid(home) and home is Node3D:
		return _flat(c.global_position).distance_to(_flat((home as Node3D).global_position))
	var k := Keep.nearest(team, c.global_position)
	return _flat(c.global_position).distance_to(_flat(k.global_position)) if k else 0.0


## Length of a caravan's route (TradeNetwork.route_length, else Bazaar -> post door straight), 0 if unknown.
func _route_length_of(c: Node3D, _team: int) -> float:
	var post: Variant = c.get(&"route_post")
	var home: Variant = c.get(&"home_market")
	if not (is_instance_valid(post) and post is Node3D):
		return 0.0
	var net := _trade_network()
	if net and net.has_method(&"route_length") and is_instance_valid(home) and home is Node3D:
		return float(net.call(&"route_length", home, post))
	var from: Vector3 = (home as Node3D).global_position if is_instance_valid(home) and home is Node3D \
			else c.global_position
	var door: Vector3 = (post as Node3D).call(&"door_point") if (post as Node3D).has_method(&"door_point") \
			else (post as Node3D).global_position
	return _flat(from).distance_to(_flat(door))


func _trade_network() -> Node:
	if not is_inside_tree():
		return null
	var n := get_tree().get_first_node_in_group(&"trade_network")
	return n if n and is_instance_valid(n) else null


func _append_unique(list: Array[Vector3], p: Variant) -> void:
	if not p is Vector3 or p == Vector3.INF:
		return
	var q := _flat(p)
	for e in list:
		if e.distance_to(q) < 0.5:
			return
	list.append(q)


func _flat(p: Vector3) -> Vector3:
	return Vector3(p.x, 0.0, p.z)


## Walking distance from `from` to `to`: the navmesh path length (plus the straight bits from / to the path's
## ends when a point is off the navmesh); the flat straight distance while there is no baked navmesh.
func path_distance(from: Vector3, to: Vector3) -> float:
	if not from.is_finite() or not to.is_finite():
		return INF
	var a := _flat(from)
	var b := _flat(to)
	var straight := a.distance_to(b)
	if not is_inside_tree() or get_viewport() == null:
		return straight
	var map := get_viewport().find_world_3d().navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return straight
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	if path.size() < 2:
		return straight
	var total := a.distance_to(_flat(path[0])) + _flat(path[path.size() - 1]).distance_to(b)
	for i in range(1, path.size()):
		total += _flat(path[i - 1]).distance_to(_flat(path[i]))
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


# ---------------------------------------------------------------- stand-in contract

## Used while res://scripts/ai/tracker_contract.gd is missing (or does not compile): a plain countdown with the
## TrackerContract API; the trackers stand at the Lodge and fade out at the end.
class FallbackContract extends Node:
	signal ended(contract: Node)

	var guild: Node
	var team := 0
	var kind: StringName = &""
	var trackers: Array = []
	var duration := 0.0
	var _left := 0.0
	var _done := false

	func _init() -> void:
		add_to_group("tracker_contracts")

	func setup(p_guild: Node, p_team: int, p_kind: StringName, p_trackers: Array, p_duration: float) -> void:
		guild = p_guild
		team = p_team
		kind = p_kind
		trackers = p_trackers
		duration = p_duration
		_left = p_duration

	func time_left() -> float:
		return maxf(0.0, _left)

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_left -= delta
		if _left <= 0.0:
			end_contract()

	func end_contract() -> void:
		if _done:
			return
		_done = true
		_left = 0.0
		HuntersGuild.fade_out_trackers(trackers)
		ended.emit(self)
		queue_free()
