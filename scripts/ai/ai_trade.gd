class_name AITrade
extends RefCounted
## Rule 10 of the bot (docs/design/market-trade.md section 7, task 10.A3): trade. Owned by the Commander, one
## per bot; it only uses public APIs (Market, Caravan, GoldBank, TradeNetwork, HuntersGuild) and sees Magpies and
## enemy units only through its team's fog (no fog node, or fog off: every Magpie counts as seen).
## - 10a / 10b Bazaar: the Commander's build row M1 asks bazaar_due() / bazaar_crystals(): from ai.trade_start
##   with a completed Hall and cost + 100 crystals; "behind" (seen_strength > 1.5 x own_strength for 60 s, from
##   4:00) builds it at once; a lost Bazaar is rebuilt 60 s later with 250 crystals.
## - 10c caravans: caravan_target() (ai.caravan_target, _late once home nodes a + b are empty, +1 while behind);
##   the Commander queues them (its 20 s rule and pop checks).
## - 10d routes, every 30 s: the Bazaar's near route (the default, the other near post while the default is
##   unsafe: a caravan on it robbed / killed / hit far from home in 90 s, or an enemy group >= 150 seen within
##   15 m of its road in 60 s); up to ai.far_route_caravans caravans to the best far post while own_strength >=
##   ai.far_route_ratio x max(seen, 250), not behind, and no Magpie or enemy fighter seen on that road in 90 s.
## - 10e raids on a remote node (TradeNetwork.workers_raided): the Commander's rows S3 / S4 ask raid_tower_due().
## - 10f hunters, 10g wares, 10h (AIChampions, gold revive / hire), 10i exchange: at most one gold purchase per
##   think tick (gold_spend_ok()), in that order.
## - 10j a caravan hit within 35 m of an own building: intruder() hands the attacker to rule 1; farther away the
##   route becomes unsafe instead.
## Magpies never count as the enemy army: they are kept as sightings per road and per spot (10d / 10f) and as
## looters (B6).

const REBUILD_DELAY := 60.0           ## 10a: a destroyed Bazaar is rebuilt this long after it fell...
const REBUILD_CRYSTALS := 250         ## ...with this many crystals.
const BAZAAR_MARGIN := 100            ## 10a: crystals >= cost + this.
const BEHIND_RATIO := 1.5             ## 10b
const BEHIND_TIME := 60.0
const BEHIND_EARLIEST := 240.0
const CARAVAN_CRYSTALS := 125         ## 10c: queue a caravan only with this many crystals...
const CARAVAN_POP_FREE := 2           ## ...and pop_used + pop <= pop_cap - this.
const CARAVAN_MAX := 6
const ROUTE_EVERY := 30.0             ## 10d
const UNSAFE_LOSS := 90.0
const UNSAFE_ENEMY := 60.0
const UNSAFE_STRENGTH := 150.0
const ROAD_RADIUS := 15.0
const FAR_CLEAR := 90.0               ## 10d: no Magpie / enemy on the far road for this long.
const SEEN_FLOOR := 250.0
const TOWER_MARGIN := 50              ## 10e: crystals >= Spire cost + this.
const TOWER_RADIUS := 20.0            ## 10e: no own tower this close to the raided node.
const OUTRIDER_WINDOW := 120.0        ## 10f
const SWEEP_SEEN := 20.0
const SPOT_RADIUS := 15.0
const SWEEP_SOLDIER_RADIUS := 25.0
const WARE_RESERVE := 50              ## 10g: gold kept for Outriders.
const EXCHANGE_STEP := 100            ## 10i
const ESSENCE_GAP := 100              ## 10i: essence instead when the next item is this close.
const DEFEND_RADIUS := 35.0           ## 10j
const HIT_MEMORY := 3.0               ## 10j: a caravan hit this recently still calls the defence.
const HIT_UNSAFE_GAP := 5.0           ## 10j: at most one "hit far away" loss per post per this long.
const HALL_RADIUS := 14.0             ## B7: an own barracks this close to a raided node is its forward hall.
const LOSS_KEEP := 300.0
const SAMPLES_KEPT := 2000
## 20.A2 (ai-2v2.md 7.2 F2): trade blocks a concede only while it can pay for a comeback: a completed Bazaar and
## gold >= COMEBACK_GOLD, or >= COMEBACK_EARNED gold earned by trips in the last COMEBACK_WINDOW s.
const COMEBACK_GOLD := 100
const COMEBACK_EARNED := 60
const COMEBACK_WINDOW := 120.0
const EARN_SAMPLE_EVERY := 5.0        ## earned_since(): one sample of GoldBank.earned(&"trade") per this long...
const EARN_SAMPLE_KEEP := 300.0       ## ...kept this long (plus the last older one).
## F4: at the pop cap with soldier pop under this share of pop_cap, the caravan target drops by CAP_CARAVAN_CUT
## (never under CAP_CARAVAN_MIN; living caravans are never killed).
const CAP_SOLDIER_SHARE := 0.45
const CAP_CARAVAN_CUT := 2
const CAP_CARAVAN_MIN := 2
const CAP_POP_SLACK := 2

## Every loss on a route: {"time", "post": Node3D or null, "kind": &"robbed" / &"killed" / &"hit"}. Read only.
var losses: Array[Dictionary] = []
## Every remote-node raid on this team: {"time", "node": WeakRef (the CrystalNode)}. Read only.
var raids: Array[Dictionary] = []
## Every route decision: {"time", "post": Node3D, "why": String}. Read only.
var route_log: Array[Dictionary] = []
## Far assignments: {"time", "caravan": WeakRef, "post": Node3D or null, "far": bool}. Read only.
var far_log: Array[Dictionary] = []
## Wares bought: {"id", "time", "price"}. Contracts hired: {"kind", "time"}. Exchanges: {"time", "gold", "to"}.
var wares: Array[Dictionary] = []
var contracts: Array[Dictionary] = []
var exchanges: Array[Dictionary] = []
var caravans_queued := 0              ## Read only (the Commander counts its queues here).
var bazaar_placed: Array[float] = []  ## Read only: match time of each Bazaar placement.
var behind := false                   ## Read only (10b).
var behind_since := -1.0              ## Read only: when the current "behind" stretch began (-1 = not behind).
## 20.A2 F1: set by the Commander every tick. Recovery = 0 workers, or < 3 workers and crystals < worker cost + 50,
## while a keep or a barracks stands: the exchange keeps nothing and goes to crystals only (even after another gold
## purchase this tick), wares / Outriders / Sweep and gold hires pause, the Commander queues no caravan.
var recovering := false
var recovery_workers := 0             ## The Commander's worker count when it set `recovering` (log line).
var recovery_exchanges := 0           ## Read only: exchanges made while recovering.
## Perf: microseconds of the trade decisions (the paid actions excluded, like BuildGrid.place), calls, samples.
var usec_total := 0
var tick_count := 0
var usec_samples := PackedInt32Array()

var _team := 1
var _enemy_team := 0
var _ai: AIProfile
var _now := 0.0
var _fog: FogOfWar = null
var _net_ref: TradeNetwork = null
var _bank_ref: GoldBank = null
var _hunters_ref: HuntersGuild = null
var _net_hooked: TradeNetwork = null
var _had_bazaar := false
var _bazaar_lost_at := -INF
var _cond_since := -1.0               # seen > 1.5 x own since (10b)
var _next_route := -INF
var _far := {}                        # caravan instance id -> WeakRef (caravans sent far by the bot)
var _far_clean := {}                  # far caravan id -> true once seen empty since it was sent (B5)
var _far_post: Node3D = null
var _hooked := {}                     # caravan instance id -> true (damage_taken / died connected)
var _pending_hits: Array = []         # [time, WeakRef caravan, WeakRef attacker, Vector3 pos, Node3D post]
var _near_hits: Array = []            # [time, WeakRef attacker] hits within 35 m of an own building
var _hit_post_at := {}                # post instance id -> time of the last "hit" loss
var _road_thief := {}                 # post instance id -> last time a Magpie was seen within 15 m of its road
var _road_enemy := {}                 # post instance id -> last time an enemy fighter was seen near its road
var _roads := {}                      # post instance id -> PackedVector3Array (Bazaar, then the waypoints)
var _roads_market: Node3D = null
var _spots: Array[Vector3] = []       # own ambush spots (every route) + W spots of own remote nodes
var _spot_thief: Array[float] = []    # parallel to _spots: last Magpie sighting within 15 m
var _spots_at := -INF
var _magpies: Array = []              # visible Magpies this tick: [Unit, Vector3, int loot]
var _bought := false                  # a gold purchase happened this think tick
var _caravan_count := 0               # own living caravans at the last sense()
var _earn_samples: Array = []         # [time, GoldBank.earned(&"trade")], oldest first (earned_since)
var _usec := 0
var _action_usec := 0


func _init(team: int, enemy_team: int, profile: AIProfile) -> void:
	_team = team
	_enemy_team = enemy_team
	_ai = profile


## The profile may change on the Commander's first tick (kingdom profile).
func set_profile(profile: AIProfile) -> void:
	_ai = profile


## True when this bot trades: the profile allows it and the team has a GoldBank (trade on in this match).
func active() -> bool:
	return _ai != null and _ai.trade and bank() != null


func bank() -> GoldBank:
	if _bank_ref == null or not is_instance_valid(_bank_ref) or _bank_ref.is_queued_for_deletion():
		_bank_ref = GoldBank.for_team(_team)
	return _bank_ref


func network() -> TradeNetwork:
	if _net_ref == null or not is_instance_valid(_net_ref) or _net_ref.is_queued_for_deletion():
		var tree := Engine.get_main_loop() as SceneTree
		_net_ref = TradeNetwork.instance(tree) if tree else null
	return _net_ref


func hunters() -> HuntersGuild:
	if _hunters_ref == null or not is_instance_valid(_hunters_ref) or _hunters_ref.is_queued_for_deletion():
		var tree := Engine.get_main_loop() as SceneTree
		_hunters_ref = HuntersGuild.instance(tree) if tree else null
	return _hunters_ref


## The team's completed, living Bazaar, or null.
func market() -> Market:
	return Market.of_team(_team)


## The Bazaar type of a kingdom (`<kingdom>_market`), or null.
static func market_type(kingdom: StringName) -> BuildingType:
	return BuildingType.find("%s_market" % kingdom)


## True for a caravan (TradeNetwork.is_caravan) or a hired tracker: they never count as army (7 "Strength").
static func is_trade_unit(u: Node) -> bool:
	if u == null:
		return false
	return TradeNetwork.is_caravan(u) or u.is_in_group(&"trackers")


## True if `buildings` hold an own Bazaar (a site too).
static func has_market_building(buildings: Array[Building]) -> bool:
	for b in buildings:
		if b.building_type != null and b.building_type.kind == &"market":
			return true
	return false


# ---------------------------------------------------------------- per-tick sense

## Early in each think tick: the lost-Bazaar clock, "behind", caravan hooks, caravan hits, Magpie sightings.
func sense(now: float, fog: FogOfWar, own_strength: float, seen_strength: float, caravans: Array[Unit],
		buildings: Array[Building]) -> void:
	var t0 := Time.get_ticks_usec()
	_now = now
	_fog = fog
	_bought = false
	_action_usec = 0
	_hook_network()
	# 10a: a Bazaar that fell is rebuilt REBUILD_DELAY later.
	var has := has_market_building(buildings)
	if has:
		_had_bazaar = true
	elif _had_bazaar:
		_had_bazaar = false
		_bazaar_lost_at = now
	# 10b behind.
	if now >= BEHIND_EARLIEST and seen_strength > BEHIND_RATIO * own_strength:
		if _cond_since < 0.0:
			_cond_since = now
	else:
		_cond_since = -1.0
	var was := behind
	behind = _cond_since >= 0.0 and now - _cond_since >= BEHIND_TIME
	if behind and not was:
		behind_since = now
	elif not behind:
		behind_since = -1.0
	_caravan_count = caravans.size()
	_sample_earned(now)
	for c in caravans:
		_hook_caravan(c)
		var cid := c.get_instance_id()
		if _far.has(cid) and not _far_clean.has(cid):
			var cargo: Variant = c.get(&"cargo")
			if cargo is int and int(cargo) <= 0:
				_far_clean[cid] = true
	_process_hits(buildings)
	_see_magpies()
	for i in range(losses.size() - 1, -1, -1):
		if now - float(losses[i]["time"]) > LOSS_KEEP:
			losses.remove_at(i)
	_usec = Time.get_ticks_usec() - t0


## 10j: the attacker of an own caravan hit in the last 3 s within 35 m of an own building (still alive), else
## null. Rule 1 treats it as an intruder.
func intruder() -> Node3D:
	for i in range(_near_hits.size() - 1, -1, -1):
		var h: Array = _near_hits[i]
		if _now - float(h[0]) > HIT_MEMORY:
			_near_hits.remove_at(i)
			continue
		var a: Object = (h[1] as WeakRef).get_ref()
		if a != null and is_instance_valid(a) and a.has_method(&"is_alive") and bool(a.call(&"is_alive")):
			return a as Node3D
	return null


## A Magpie this team sees now within `radius` of `pos` (10j worker hits), else null.
func magpie_near(pos: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for m: Array in _magpies:
		var d := _flat(m[1], pos)
		if d <= best_d and is_instance_valid(m[0]):
			best_d = d
			best = m[0]
	return best


## True while this team sees at least one Magpie (test helper).
func magpies_seen() -> int:
	return _magpies.size()


# ---------------------------------------------------------------- 10a / 10b / 10c / 10e (asked by the Commander)

## 10a / 10b: the M1 row may trigger now (`hall_done`: an own Hall is completed; the row itself checks that no
## Bazaar stands and orders it after the other rows).
func bazaar_due(now: float, hall_done: bool) -> bool:
	if not active() or not hall_done:
		return false
	if _bazaar_lost_at > -INF:
		return now - _bazaar_lost_at >= REBUILD_DELAY
	return now >= _ai.trade_start or (behind and now >= BEHIND_EARLIEST)


## 10a: crystals the M1 placement waits for (cost + 100; a rebuild: 250).
func bazaar_crystals(cost: int) -> int:
	if _bazaar_lost_at > -INF:
		return maxi(REBUILD_CRYSTALS, cost)
	return cost + BAZAAR_MARGIN


## 10e: crystals a raid Spire waits for.
static func tower_crystals(cost: int) -> int:
	return cost + TOWER_MARGIN


func note_bazaar_placed(now: float) -> void:
	bazaar_placed.append(now)


## 10c: caravans to keep (alive + queued). 20.A2 F4: pass `pop_used`, `pop_cap` and `soldier_pop` (the team's
## soldiers, caravans and workers excluded): when pop_used >= pop_cap - 2 and soldier_pop < 45 % of pop_cap the
## target is max(2, target - 2), so a capped bot keeps pop for the army that must finish the game. Without them
## (-1) the old target.
func caravan_target(home_nodes_empty: bool, pop_used: int = -1, pop_cap: int = -1, soldier_pop: int = -1) -> int:
	if not active():
		return 0
	var n := _ai.caravan_target_late if home_nodes_empty else _ai.caravan_target
	if behind:
		n += 1
	n = mini(n, CARAVAN_MAX)
	if pop_cap > 0 and pop_used >= 0 and soldier_pop >= 0 and pop_used >= pop_cap - CAP_POP_SLACK \
			and float(soldier_pop) < CAP_SOLDIER_SHARE * float(pop_cap):
		n = mini(n, maxi(CAP_CARAVAN_MIN, n - CAP_CARAVAN_CUT))
	return n


## 20.A2 F2: can trade still pay for a comeback? A completed own Bazaar and (gold >= 100, or >= 60 gold earned by
## trips in the last 120 s). Only then do caravans / a Bazaar block the Commander's concede.
func can_fund_comeback(now: float) -> bool:
	var b := bank()
	if not active() or b == null or not b.has_bazaar():
		return false
	if b.gold >= COMEBACK_GOLD:
		return true
	return earned_since(now - COMEBACK_WINDOW) >= COMEBACK_EARNED


## Gold earned by trade trips (GoldBank source &"trade") since match time `t`: GoldBank.earned_since(t) when the
## bank has it, else from this bot's own samples of GoldBank.earned(&"trade") (one every 5 s from its first sense();
## before the first sample: everything since then).
func earned_since(t: float) -> int:
	var b := bank()
	if b == null:
		return 0
	if b.has_method(&"earned_since"):
		return int(b.call(&"earned_since", t))
	var total := b.earned(GoldBank.SOURCE_TRADE)
	var base := -1
	for s: Array in _earn_samples:
		if float(s[0]) <= t:
			base = int(s[1])
		else:
			break
	if base < 0:
		base = int(_earn_samples[0][1]) if not _earn_samples.is_empty() else total
	return maxi(0, total - base)


func _sample_earned(now: float) -> void:
	var b := bank()
	if b == null:
		return
	if not _earn_samples.is_empty() and now - float(_earn_samples[-1][0]) < EARN_SAMPLE_EVERY:
		return
	_earn_samples.append([now, b.earned(GoldBank.SOURCE_TRADE)])
	# Keep one sample older than the window so earned_since(now - window) has its base.
	while _earn_samples.size() > 2 and now - float(_earn_samples[1][0]) > EARN_SAMPLE_KEEP:
		_earn_samples.remove_at(0)


## 10e: a Spire at the raided `node` is due: the node was raided (ever), still has crystals, and no own tower
## (sites too) stands within 20 m of it.
func raid_tower_due(node: Node3D, buildings: Array[Building]) -> bool:
	if not active() or node == null or not is_instance_valid(node):
		return false
	if node is CrystalNode and (node as CrystalNode).is_depleted():
		return false
	var raided := false
	for r: Dictionary in raids:
		if (r["node"] as WeakRef).get_ref() == node:
			raided = true
			break
	if not raided:
		return false
	for b in buildings:
		if b.building_type and b.building_type.kind == &"tower" and _flat(b.global_position, node.global_position) <= TOWER_RADIUS:
			return false
	return true


# ---------------------------------------------------------------- 10d routes, 10f hunters, 10g wares

## Rule 10 purchases and routes for one think tick (after the Commander's build and caravan queue). `soldiers`:
## own soldiers (Sweep: no soldier within 25 m of the spot). Returns log lines.
func tick(now: float, memory: AIMemory, own_strength: float, seen_strength: float, soldiers: Array[Unit]) -> Array[String]:
	var out: Array[String] = []
	if not active():
		return out
	var t0 := Time.get_ticks_usec()
	var m := market()
	if m != null:
		if now >= _next_route:
			_next_route = now + ROUTE_EVERY
			_routes(m, memory, own_strength, seen_strength, out)
		else:
			_prune_far()
	# 20.A2 F1: while recovering, gold goes to crystals for workers: no Outriders / Sweep, no wares.
	if not _bought and not recovering:
		_hunters_rule(soldiers, out)
	if not _bought and not recovering:
		_wares_rule(m, out)
	var spent := _usec + Time.get_ticks_usec() - t0 - _action_usec
	usec_total += spent
	tick_count += 1
	usec_samples.append(spent)
	if usec_samples.size() > SAMPLES_KEPT:
		usec_samples.remove_at(0)
	return out


## 10h (AIChampions): may gold still be spent this tick? note_gold_spent() after a gold revive / hire.
## 20.A2 F1: never while recovering (the gold is exchanged for crystals).
func gold_spend_ok() -> bool:
	return not _bought and not recovering


func note_gold_spent() -> void:
	_bought = true


## 10i, after 10f-10h: gold above ai.gold_exchange_above (and above the next ware's price + 50 while one is
## still wanted) is exchanged in steps of 100: into essence when the next item (`item_price`, 0 = none) is within
## 100 essence of `essence`, else into crystals. 20.A2 F1: while recovering, every full 100 goes to crystals.
## Returns a log line or "".
func exchange_tick(item_price: int, essence: int) -> String:
	if not exchange_ready():
		return ""
	var b := bank()
	var keep := _exchange_keep()
	var steps := (b.gold - keep) / EXCHANGE_STEP
	if steps <= 0:
		return ""
	var to := &"crystals"
	if not recovering and item_price > 0 and essence < item_price and item_price - essence <= ESSENCE_GAP:
		to = &"essence"
	var before := b.gold
	var a0 := Time.get_ticks_usec()
	var reason := b.exchange(steps * EXCHANGE_STEP, to)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		return ""
	_bought = true
	exchanges.append({"time": _now, "gold": steps * EXCHANGE_STEP, "to": to, "recovery": recovering})
	if recovering:
		recovery_exchanges += 1
		return "RECOVERY: %d workers, exchanging %d gold -> crystals (gold %d -> %d)" % [recovery_workers,
				steps * EXCHANGE_STEP, before, b.gold]
	return "TRADE exchange %d gold -> %s (gold %d -> %d, keeps %d)" % [steps * EXCHANGE_STEP, to, before, b.gold, keep]


## 10i: true when this tick may exchange: no gold purchase yet, a Bazaar, and gold above what is kept.
## 20.A2 F1: while recovering, any 100 gold with a Bazaar (another purchase this tick does not stop it).
func exchange_ready() -> bool:
	var b := bank()
	if not active() or b == null:
		return false
	if recovering:
		return b.gold >= EXCHANGE_STEP and b.has_bazaar()
	if _bought or b.gold < _ai.gold_exchange_above + EXCHANGE_STEP:
		return false
	return b.gold - _exchange_keep() >= EXCHANGE_STEP and b.has_bazaar()


## Gold the exchange leaves: ai.gold_exchange_above, and the next ware's price + 50 while one is still wanted.
## 20.A2 F1: 0 while recovering.
func _exchange_keep() -> int:
	if recovering:
		return 0
	var keep := _ai.gold_exchange_above
	var ware := next_ware()
	if ware != &"":
		keep = maxi(keep, GoldBank.ware_price(ware) + WARE_RESERVE)
	return keep


## The next ware of ai.ware_order still to buy whose gate holds (Iron-shod Axles: ai.axles_min_caravans living
## caravans, as of the last sense()), or &"".
func next_ware() -> StringName:
	var b := bank()
	if b == null or _ai == null:
		return &""
	for s in _ai.ware_order:
		var id := StringName(s)
		if not GoldBank.WARES.has(id) or b.owns_ware(id):
			continue
		if id == &"iron_axles" and _ai.axles_min_caravans > 0 and _caravan_count < _ai.axles_min_caravans:
			continue
		return id
	return &""


## The caravans the bot sent far (alive).
func far_caravans() -> Array:
	_prune_far()
	var out: Array = []
	for id in _far:
		var c: Object = (_far[id] as WeakRef).get_ref()
		if c != null:
			out.append(c)
	return out


## The far post the bot trades with (null: none chosen).
func far_post() -> Node3D:
	return _far_post if _far_post != null and is_instance_valid(_far_post) else null


## 10d: is the route to `post` unsafe now (for this team, from its Bazaar)?
func is_unsafe(post: Node3D, memory: AIMemory) -> bool:
	if post == null:
		return false
	for l: Dictionary in losses:
		if l["post"] == post and _now - float(l["time"]) <= UNSAFE_LOSS:
			return true
	return _enemy_on_road(post, memory, UNSAFE_ENEMY, UNSAFE_STRENGTH)


func _routes(m: Market, memory: AIMemory, own_strength: float, seen_strength: float, out: Array[String]) -> void:
	var net := network()
	if net == null:
		return
	_refresh_roads(m, net)
	var near: Array[Node3D] = []
	var far: Array[Node3D] = []
	for p in net.posts():
		var post := p as Node3D
		if post == null or net.route_reason(m, post) == TradeNetwork.MSG_TOO_SHORT:
			continue
		if m.is_far_post(post):
			far.append(post)
		else:
			near.append(post)
	# Near: the default unless unsafe, then the other near post (if that one is safe).
	var def := m.default_route()
	var pick := def
	var why := "default"
	if def != null and is_unsafe(def, memory):
		why = "default unsafe, no safe near post"
		for p in near:
			if p != def and not is_unsafe(p, memory):
				pick = p
				why = "%s unsafe" % post_name(def)
				break
	if pick != null and m.route_post != pick and m.set_route(pick) == "":
		route_log.append({"time": _now, "post": pick, "why": why})
		out.append("TRADE route %s (%d gold / trip): %s" % [post_name(pick), m.route_value_to(pick), why])
	# Far: the best far post while ahead and its road is clear.
	var best: Node3D = null
	var best_v := -1
	for p in far:
		if net.route_reason(m, p) != "":
			continue
		var v := m.route_value_to(p)
		if v > best_v:
			best_v = v
			best = p
	var ratio_ok := _ai.far_route_caravans > 0 and _ai.far_route_ratio > 0.0 \
			and own_strength >= _ai.far_route_ratio * maxf(seen_strength, SEEN_FLOOR)
	var far_ok := best != null and ratio_ok and not behind and not is_unsafe(best, memory) \
			and _now - float(_road_thief.get(best.get_instance_id(), -INF)) > FAR_CLEAR \
			and not _enemy_on_road(best, memory, FAR_CLEAR, 0.001)
	_prune_far()
	if not far_ok:
		if not _far.is_empty():
			var reason := "behind" if behind else ("not strong enough" if not ratio_ok else "far road unsafe")
			for id in _far.keys():
				var c := (_far[id] as WeakRef).get_ref() as Caravan
				if c != null and c.command_trade(m) == "":
					far_log.append({"time": _now, "caravan": weakref(c), "post": null, "far": false})
			_far.clear()
			_far_clean.clear()
			out.append("TRADE far caravans called home: %s" % reason)
		_far_post = null
		return
	_far_post = best
	# Far caravans on another far post move to the best one.
	for id in _far.keys():
		var c := (_far[id] as WeakRef).get_ref() as Caravan
		if c != null and c.route_post != best:
			c.command_trade(best)
	var want := _ai.far_route_caravans - _far.size()
	if want <= 0:
		return
	var pool: Array = []
	for c in m.caravans():
		var cv := c as Caravan
		if cv == null or not cv.is_alive() or _far.has(cv.get_instance_id()):
			continue
		# Empty caravans at home first, then empty ones on the road, then loaded ones (they deliver first).
		var score := 0 if cv.cargo <= 0 and cv.trade_state in [&"loading", &"idle", &"waiting"] else \
				(1 if cv.cargo <= 0 else 2)
		pool.append([score, cv])
	pool.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var sent := 0
	for e: Array in pool:
		if sent >= want:
			break
		var cv := e[1] as Caravan
		if cv.command_trade(best) == "":
			_far[cv.get_instance_id()] = weakref(cv)
			if cv.cargo <= 0:
				_far_clean[cv.get_instance_id()] = true
			far_log.append({"time": _now, "caravan": weakref(cv), "post": best, "far": true})
			sent += 1
	if sent > 0:
		out.append("TRADE %d caravan(s) far to %s (%d gold / trip; str %.0f vs seen %.0f)" % [sent,
				post_name(best), best_v, own_strength, seen_strength])


func _hunters_rule(soldiers: Array[Unit], out: Array[String]) -> void:
	var g := hunters()
	var b := bank()
	if g == null or b == null or not g.is_open():
		return
	# Outriders: a caravan robbed or killed in the last 120 s.
	if _ai.hire_outriders and b.gold >= g.contract_cost(&"outriders"):
		var lost := false
		for l: Dictionary in losses:
			if l["kind"] != &"hit" and _now - float(l["time"]) <= OUTRIDER_WINDOW:
				lost = true
				break
		if lost and g.can_hire(_team, &"outriders") == "":
			_hire(g, &"outriders", "a caravan was lost", out)
			return
	# Sweep (hard): Magpies seen near one of our spots in the last 20 s and no own soldier within 25 m of it.
	if _ai.hire_sweep and b.gold >= g.contract_cost(&"sweep"):
		for i in _spots.size():
			if _now - _spot_thief[i] > SWEEP_SEEN:
				continue
			var guarded := false
			for s in soldiers:
				if _flat(s.global_position, _spots[i]) <= SWEEP_SOLDIER_RADIUS:
					guarded = true
					break
			if not guarded:
				if g.can_hire(_team, &"sweep") == "":
					_hire(g, &"sweep", "Magpies at %s" % _xz(_spots[i]), out)
				return


func _hire(g: HuntersGuild, kind: StringName, why: String, out: Array[String]) -> void:
	var a0 := Time.get_ticks_usec()
	var reason := g.hire(_team, kind)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		return
	_bought = true
	contracts.append({"kind": kind, "time": _now})
	out.append("TRADE hires %s (%d gold): %s" % [kind, g.contract_cost(kind), why])


func _wares_rule(m: Market, out: Array[String]) -> void:
	var b := bank()
	if b == null or m == null:
		return
	var id := next_ware()
	if id == &"":
		return
	var price := GoldBank.ware_price(id)
	if b.gold < price + WARE_RESERVE or b.can_buy_ware(id) != "":
		return
	var a0 := Time.get_ticks_usec()
	var reason := b.buy_ware(id)
	_action_usec += Time.get_ticks_usec() - a0
	if reason != "":
		return
	_bought = true
	wares.append({"id": id, "time": _now, "price": price})
	out.append("TRADE buys %s (%d gold, %d left)" % [GoldBank.ware_name(id), price, b.gold])


# ---------------------------------------------------------------- B5-B7 helpers (AIChampions)

## B5: an own caravan loaded on a far trip (the one farthest from its Bazaar), else null. A caravan sent far
## while carrying a near cargo counts only after it delivered that one (seen empty since it was sent).
func far_loaded_caravan() -> Node3D:
	var m := market()
	var best: Node3D = null
	var best_d := -1.0
	for c in far_caravans():
		var cv := c as Caravan
		if cv == null or not cv.is_alive():
			continue
		if not cv.is_loaded() or not _far_clean.has(cv.get_instance_id()):
			continue
		var d := _flat(cv.global_position, m.global_position) if m else 0.0
		if d > best_d:
			best_d = d
			best = cv
	return best


## B6: a Magpie this team sees now, carrying loot, within `radius` of one of `points` (nearest first), else null.
func looter_near(points: Array[Node3D], radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for m: Array in _magpies:
		if int(m[2]) <= 0 or not is_instance_valid(m[0]):
			continue
		for p in points:
			var d := _flat(p.global_position, m[1])
			if d <= best_d:
				best_d = d
				best = m[0]
	return best


## B7: the own completed forward hall (a barracks within 14 m) of a remote node raided in the last `window` s.
func raided_hall(window: float, buildings: Array[Building]) -> Building:
	for i in range(raids.size() - 1, -1, -1):
		var r: Dictionary = raids[i]
		if _now - float(r["time"]) > window:
			break
		var node := (r["node"] as WeakRef).get_ref() as Node3D
		if node == null:
			continue
		for b in buildings:
			if b.is_constructed() and b.building_type and b.building_type.kind == &"barracks" \
					and _flat(b.global_position, node.global_position) <= HALL_RADIUS:
				return b
	return null


## Median decision cost of the last think ticks, in ms.
func median_ms() -> float:
	if usec_samples.is_empty():
		return 0.0
	var s := usec_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2]) / 1000.0


# ---------------------------------------------------------------- internals

func _hook_network() -> void:
	var net := network()
	if net == null or net == _net_hooked:
		return
	_net_hooked = net
	net.caravan_robbed.connect(_on_robbed)
	net.workers_raided.connect(_on_raided)


func _on_robbed(team: int, caravan: Node, amount: int, _thief: Node) -> void:
	if team != _team:
		return
	var post: Variant = caravan.get(&"route_post") if caravan != null and is_instance_valid(caravan) else null
	losses.append({"time": _now_time(), "post": post if post is Node3D else null, "kind": &"robbed",
			"amount": amount})


func _on_raided(team: int, node: Node) -> void:
	if team != _team or node == null or not is_instance_valid(node):
		return
	raids.append({"time": _now_time(), "node": weakref(node)})


func _hook_caravan(c: Unit) -> void:
	var id := c.get_instance_id()
	if _hooked.has(id):
		return
	_hooked[id] = true
	c.damage_taken.connect(_on_caravan_damaged.bind(weakref(c)))
	c.died.connect(_on_caravan_died)


func _on_caravan_damaged(amount: float, attacker: Node3D, ref: WeakRef) -> void:
	var c := ref.get_ref() as Node3D
	if c == null or amount <= 0.0:
		return
	var post: Variant = c.get(&"route_post")
	_pending_hits.append([_now_time(), weakref(attacker) if attacker != null else weakref(c), c.global_position,
			post if post is Node3D and is_instance_valid(post) else null, attacker != null])


func _on_caravan_died(unit: Unit) -> void:
	if unit == null:
		return
	_hooked.erase(unit.get_instance_id())
	_far.erase(unit.get_instance_id())
	_far_clean.erase(unit.get_instance_id())
	var post: Variant = unit.get(&"route_post")
	losses.append({"time": _now_time(), "post": post if post is Node3D and is_instance_valid(post) else null,
			"kind": &"killed", "amount": 0})


## Caravan hits since the last tick: within 35 m of an own building -> rule-1 intruder; farther -> the route is
## unsafe (one "hit" loss per post per 5 s).
func _process_hits(buildings: Array[Building]) -> void:
	for h: Array in _pending_hits:
		var pos: Vector3 = h[2]
		var near := false
		for b in buildings:
			if _flat(b.global_position, pos) <= DEFEND_RADIUS:
				near = true
				break
		if near:
			if bool(h[4]):
				_near_hits.append([h[0], h[1]])
			continue
		var post: Node3D = h[3]
		var key := post.get_instance_id() if post != null else 0
		if float(h[0]) - float(_hit_post_at.get(key, -INF)) >= HIT_UNSAFE_GAP:
			_hit_post_at[key] = float(h[0])
			losses.append({"time": float(h[0]), "post": post, "kind": &"hit", "amount": 0})
	_pending_hits.clear()


## Visible Magpies: this tick's list (looters, magpie_near) and the sightings per road / per spot.
func _see_magpies() -> void:
	_magpies.clear()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"magpies"):
		var u := node as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		var p := u.global_position
		if _fog != null and not _fog.is_visible(_team, p):
			continue
		_magpies.append([u, p, int(u.get_meta(&"loot", 0))])
	if _magpies.is_empty():
		return
	for key in _roads:
		var pts: PackedVector3Array = _roads[key]
		for m: Array in _magpies:
			if _dist_to_polyline(m[1], pts) <= ROAD_RADIUS:
				_road_thief[key] = _now
				break
	for i in _spots.size():
		for m: Array in _magpies:
			if _flat(m[1], _spots[i]) <= SPOT_RADIUS:
				_spot_thief[i] = _now
				break


## Road polylines (Bazaar -> waypoints -> door) for every post, and the own spots (every route's ambush spots +
## the W spots of own remote nodes); rebuilt with each route pass (the Bazaar may have moved: rebuilt).
func _refresh_roads(m: Market, net: TradeNetwork) -> void:
	if m != _roads_market:
		_roads.clear()
		_road_thief.clear()
		_roads_market = m
	for p in net.posts():
		var post := p as Node3D
		if post == null:
			continue
		var key := post.get_instance_id()
		if not _roads.has(key):
			var pts := PackedVector3Array([m.global_position])
			pts.append_array(net.route_points(m, post))
			_roads[key] = pts
	var spots: Array[Vector3] = []
	for p in net.posts():
		for s in net.ambush_spots(_team, p as Node3D):
			if not _has_point(spots, s):
				spots.append(s)
	for n in net.remote_nodes(_team):
		var w := net.worker_spot(n as Node3D)
		if w != Vector3.INF and not _has_point(spots, w):
			spots.append(w)
	var old := {}
	for i in _spots.size():
		old[_spots[i]] = _spot_thief[i]
	_spots = spots
	_spot_thief.clear()
	for s in _spots:
		_spot_thief.append(float(old.get(s, -INF)))


## True if the memory holds enemy fighters seen in the last `window` s within 15 m of the road to `post` whose
## strengths add up to `min_strength` or more.
func _enemy_on_road(post: Node3D, memory: AIMemory, window: float, min_strength: float) -> bool:
	if memory == null or post == null:
		return false
	var pts: Variant = _roads.get(post.get_instance_id())
	if pts == null:
		return false
	var total := 0.0
	for e: Dictionary in memory.units.values():
		if _now - float(e["time"]) > window or float(e["strength"]) <= 0.0:
			continue
		if _dist_to_polyline(e["pos"], pts) <= ROAD_RADIUS:
			total += float(e["strength"])
			if total >= min_strength:
				return true
	return false


func _prune_far() -> void:
	for id in _far.keys():
		var c: Object = (_far[id] as WeakRef).get_ref()
		if c == null or not (c as Unit).is_alive():
			_far.erase(id)
			_far_clean.erase(id)


func _now_time() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	var level := tree.current_scene if tree else null
	if level and level.has_method(&"match_time"):
		return float(level.call(&"match_time"))
	return _now


static func _has_point(list: Array[Vector3], p: Vector3) -> bool:
	for q in list:
		if _flat(q, p) < 0.5:
			return true
	return false


static func _dist_to_polyline(p: Vector3, pts: PackedVector3Array) -> float:
	var best := INF
	for i in range(1, pts.size()):
		var a := Vector2(pts[i - 1].x, pts[i - 1].z)
		var b := Vector2(pts[i].x, pts[i].z)
		var q := Vector2(p.x, p.z)
		var ab := b - a
		var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * t))
	return best


static func post_name(post: Node3D) -> String:
	if post == null:
		return "none"
	var n: Variant = post.get(&"display_name")
	return str(n) if n != null else String(post.name)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _xz(p: Vector3) -> String:
	return "(%d, %d)" % [roundi(p.x), roundi(p.z)]
