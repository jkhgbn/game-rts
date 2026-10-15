class_name Market
extends TrainingBuilding
## The Bazaar (market-trade.md 4.1, contract in section 12): one per team, within 20 m of the keep, needs a
## completed Hall (BuildGrid.check with BuildingType.requires_kind / max_keep_distance / max_count). It trains
## caravans (queue 5, max CARAVAN_LIMIT per team alive + queued) and holds the route they trade on
## (`route_post`, a TradePost). Not a shop, not a crystal drop-off; counts for defeat.
##
## Step-10 parts that may not exist yet are reached without their class names: the TradeNetwork through
## its group "trade_network" (route length / value / near-far), trading posts through the group
## "trade_posts", caravans through the group "caravans" or their UnitType (`is_caravan` / id &"caravan").
## Without a TradeNetwork the route length is the straight distance to the post door (tests, campaign).
##
## Look (10.C9): the kingdom's Bazaar model (`BuildingType.model_scene`, res://art/buildings/market/<kingdom>/).
## - One of its caravans delivers -> the model's `play_delivery()` (the scale tips, coins glint). Heard on
##   TradeNetwork.delivered (caravan.home_market == self); without a network, on each caravan's own `delivered`.
##   The caravan itself plays the `delivery` / `post_trade` TradeVfx: not repeated here.
## - Its team's GoldBank emits `ware_bought` -> TradeVfx `ware_bought` (gold ring pulse) on this Bazaar.
## The network / bank may appear after the Bazaar: the links are retried once per LINK_INTERVAL.

signal route_changed(market: Market, post: Node3D)

const CARAVAN_LIMIT := 6
const MIN_ROUTE_LENGTH := 20.0       ## market-trade.md 4.3: L < 20 -> "Route too short".
const ROUTE_CAP := 140.0             ## L is capped at 140 for the value.
const NEAR_DISTANCE := 60.0          ## A post is near when its door is < 60 m from the team's keep (2.2).
const REASON_CARAVAN_LIMIT := "Caravan limit reached"
const REASON_NOT_A_POST := "Not a trading post"
const REASON_ROUTE_TOO_SHORT := "Route too short"
const CARAVAN_ID := &"caravan"
const GROUP := &"markets"            ## Every Bazaar (sites too) is in "buildings" and in this group.
const LINK_INTERVAL := 1.0           ## Seconds between tries to find the TradeNetwork / GoldBank signals.
const VFX_WARE_BOUGHT := &"ware_bought"

## The trading post the caravans trade with (a change applies at each caravan's next departure).
## Unset (or freed) = the default: the near post with the highest value from this Bazaar (null if none).
## Assigning goes through set_route (null clears back to the default).
var route_post: Node3D:
	get:
		return _current_route()
	set(value):
		if value == null:
			_clear_route()
		else:
			set_route(value)

var _route_post: Node3D = null
var _route_explicit := false
var _network_link: Node = null       # the TradeNetwork whose `delivered` we listen to
var _bank_link: Node = null          # this team's GoldBank (its `ware_bought`)
var _link_left := 0.0


func _ready() -> void:
	# Building._ready picks the kingdom's Bazaar model (BuildingType.get_model_scene: model_scene, else model_path).
	super()
	add_to_group(GROUP)
	_link_trade_signals()


func _physics_process(delta: float) -> void:
	super(delta)
	_link_left -= delta
	if _link_left <= 0.0:
		_link_left = LINK_INTERVAL
		_link_trade_signals()


# ---------------------------------------------------------------- public

## The completed, living Bazaar of `for_team_id`, or null (sites and ruins don't count).
## This is the contract's "Market.for_team": GDScript refuses that name here because the parent
## Building already has `static func for_team(team) -> Array[Building]` (all the team's buildings), so
## `load(market.gd).call(&"for_team", t)` returns THAT array, never a Bazaar. Use of_team, or the group.
static func of_team(for_team_id: int) -> Market:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GROUP):
		var m := node as Market
		if m and int(m.team) == for_team_id and m.is_alive() and m.is_constructed():
			return m
	return null


## Caravans of `for_team_id`: the living ones, plus (include_queued) those in every own Bazaar's queue.
## The CARAVAN_LIMIT counts both.
static func caravan_count(for_team_id: int, include_queued: bool = true) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u and int(u.team) == for_team_id and u.is_alive() and is_caravan_unit(u):
			n += 1
	if include_queued:
		for node in tree.get_nodes_in_group(GROUP):
			var m := node as Market
			if m and int(m.team) == for_team_id and m.is_alive():
				n += m.queued_caravans()
	return n


## True for a caravan unit (group "caravans", or a caravan UnitType).
static func is_caravan_unit(u: Node) -> bool:
	if u == null or not is_instance_valid(u):
		return false
	if u.is_in_group(&"caravans"):
		return true
	var t: Variant = u.get(&"unit_type")
	return t is UnitType and is_caravan_type(t)


static func is_caravan_type(t: UnitType) -> bool:
	return t != null and (t.get(&"is_caravan") == true or t.id == CARAVAN_ID)


## The living caravans that belong to this Bazaar (home_market == self; caravans without a living home
## Bazaar are counted by their team's Bazaar: they deliver to it, market-trade.md 4.2).
func caravans() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or u.team != team or not u.is_alive() or not is_caravan_unit(u):
			continue
		var home: Variant = u.get(&"home_market")
		if home == self:
			out.append(u)
		elif home == null or not is_instance_valid(home) or not (home as Node).is_inside_tree() \
				or ((home as Node).has_method(&"is_alive") and not bool((home as Node).call(&"is_alive"))):
			out.append(u)
	return out


## Caravans waiting in this Bazaar's queue.
func queued_caravans() -> int:
	var n := 0
	for t in queue:
		if is_caravan_type(t):
			n += 1
	return n


## The caravan type (trains = [caravan]); retries the lookup while data/units/caravan.tres is missing.
func trainable_types() -> Array[UnitType]:
	if building_type and building_type.trains.is_empty():
		building_type.resolve_trains()
	return super()


## "" if `type` can be queued, else the reason; adds "Caravan limit reached" (6 alive + queued per team)
## after the building checks and before the queue / crystal / pop checks.
func can_queue(type: UnitType) -> String:
	if _dead or not is_constructed() or type == null or not _trains(type):
		return super(type)
	if is_caravan_type(type) and caravan_count(int(team)) >= CARAVAN_LIMIT:
		return REASON_CARAVAN_LIMIT
	return super(type)


## Sets the route to `post` (a trading post: group "trade_posts"). "" = done, else
## "Not a trading post" or "Route too short" (L < 20 m, market-trade.md 4.3). Emits route_changed.
func set_route(post: Node3D) -> String:
	if post == null or not is_instance_valid(post) or not post.is_in_group(&"trade_posts"):
		return REASON_NOT_A_POST
	if _too_short(post):
		return REASON_ROUTE_TOO_SHORT
	var changed := post != _route_post
	_route_post = post
	_route_explicit = true
	if changed:
		route_changed.emit(self, post)
	return ""


## Gold per trip on the current route (0 without one).
func route_value() -> int:
	var post := route_post
	return route_value_to(post) if post else 0


## Gold per trip from this Bazaar to `post`: TradeNetwork.route_value, else round(10 + min(L, 140)² / 136).
func route_value_to(post: Node3D) -> int:
	if post == null or not is_instance_valid(post):
		return 0
	var net := _network()
	if net and net.has_method(&"route_value"):
		return int(net.call(&"route_value", self, post))
	var l := minf(route_length_to(post), ROUTE_CAP)
	return roundi(10.0 + l * l / 136.0)


## Route length L from this Bazaar to `post` (TradeNetwork.route_length, else the straight flat distance
## from the centre to the post door).
func route_length_to(post: Node3D) -> float:
	if post == null or not is_instance_valid(post):
		return 0.0
	var net := _network()
	if net and net.has_method(&"route_length"):
		return float(net.call(&"route_length", self, post))
	var door := _door_of(post)
	return Vector2(door.x - global_position.x, door.z - global_position.z).length()


## True if `post` is "far" for this Bazaar's team (TradeNetwork.is_far, else door >= 60 m from the keep).
func is_far_post(post: Node3D) -> bool:
	if post == null or not is_instance_valid(post):
		return false
	var net := _network()
	if net and net.has_method(&"is_far"):
		return bool(net.call(&"is_far", int(team), post))
	var door := _door_of(post)
	var keep := Keep.nearest(int(team), door)
	var from := keep.global_position if keep else global_position
	return Vector2(door.x - from.x, door.z - from.z).length() >= NEAR_DISTANCE


## The default route: the near post with the highest value from this Bazaar (null if none is valid).
func default_route() -> Node3D:
	var best: Node3D = null
	var best_value := -1
	for post in _posts():
		if is_far_post(post) or _too_short(post):
			continue
		var v := route_value_to(post)
		if v > best_value:
			best_value = v
			best = post
	return best


## True when the route was set by the player / bot (set_route), false while it is the default.
func has_explicit_route() -> bool:
	return _route_explicit and _route_post != null and is_instance_valid(_route_post)


## The model's delivery flourish (the scale tips toward the gold pan, coins glint). Called when one of this
## Bazaar's caravans delivers; the model ignores it on a site or a wreck (placeholder: nothing).
func play_delivery() -> void:
	_call_model(&"play_delivery")


## Bazaars are not base shops.
func is_shop() -> bool:
	return false


## Workers never deliver crystals to a Bazaar.
func is_drop_off() -> bool:
	return false


# ---------------------------------------------------------------- training

## Like TrainingBuilding, but the caravan gets `home_market` = self (and `route_post` = this Bazaar's route,
## so the UI shows it at once) before it enters the scene, and then
## `command_trade(self)` (go home, deliver, follow the Bazaar's route) instead of a rally walk.
func _spawn(type: UnitType) -> void:
	var eco := _get_economy()
	if eco:
		eco.release_pop(type.pop)   # the living unit counts its own pop from now on
	var unit := Worker.make_unit(type)
	unit.team = team
	if &"home_market" in unit:
		unit.set(&"home_market", self)
	# The UI shows the caravan's route at once (the caravan re-reads the Bazaar's route at each departure).
	if &"route_post" in unit and unit.get(&"route_post") == null:
		unit.set(&"route_post", route_post)
	var parent := get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(unit)
	unit.global_position = spawn_point()
	unit.command_stop()
	if unit.has_method(&"command_trade"):
		unit.call(&"command_trade", self)
	else:
		unit.command_move(rally_point())
	if not _linked(_network_link):
		_watch_caravan(unit)
	_call_model(&"play_training_pulse")
	unit_trained.emit(unit)


# ---------------------------------------------------------------- trade signals (look)

## Connects TradeNetwork.delivered and the team's GoldBank.ware_bought once they exist; without a network,
## each own caravan's `delivered` instead.
func _link_trade_signals() -> void:
	if not is_inside_tree():
		return
	if not _linked(_network_link):
		_network_link = null
		var net := _network()
		if net and net.has_signal(&"delivered"):
			if not net.is_connected(&"delivered", _on_network_delivered):
				net.connect(&"delivered", _on_network_delivered)
			_network_link = net
	if not _linked(_bank_link):
		_bank_link = null
		var bank := _team_bank()
		if bank and bank.has_signal(&"ware_bought"):
			if not bank.is_connected(&"ware_bought", _on_ware_bought):
				bank.connect(&"ware_bought", _on_ware_bought)
			_bank_link = bank
	if not _linked(_network_link):
		for c in caravans():
			_watch_caravan(c)


func _linked(n: Node) -> bool:
	return n != null and is_instance_valid(n) and n.is_inside_tree()


func _watch_caravan(c: Node) -> void:
	if c != null and is_instance_valid(c) and c.has_signal(&"delivered") \
			and not c.is_connected(&"delivered", _on_caravan_delivered):
		c.connect(&"delivered", _on_caravan_delivered)


func _team_bank() -> Node:
	for bank in get_tree().get_nodes_in_group(&"gold_banks"):
		var t: Variant = bank.get(&"team")
		if t != null and int(t) == int(team) and not bank.is_queued_for_deletion():
			return bank
	return null


func _on_network_delivered(_team: int, caravan: Node, _amount: int, _post: Node) -> void:
	_on_delivery(caravan)


## Only without a network (the network's `delivered` covers the same delivery).
func _on_caravan_delivered(caravan: Node, _amount: int) -> void:
	if _linked(_network_link):
		return
	_on_delivery(caravan)


func _on_delivery(caravan: Node) -> void:
	if caravan != null and is_instance_valid(caravan) and caravan.get(&"home_market") == self:
		play_delivery()


## A ware of this team was bought: a gold ring pulse on the Bazaar (TradeVfx `ware_bought`).
func _on_ware_bought(_id: StringName) -> void:
	if _dead or not is_constructed() or not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"trade_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", VFX_WARE_BOUGHT, global_position, self)


# ---------------------------------------------------------------- route helpers

func _current_route() -> Node3D:
	if _route_post != null and is_instance_valid(_route_post) and _route_post.is_inside_tree():
		return _route_post
	_route_post = null
	_route_explicit = false
	if not is_inside_tree():
		return null
	var post := default_route()
	if post:
		_route_post = post
		route_changed.emit(self, post)
	return post


func _clear_route() -> void:
	var had := _route_post != null
	_route_post = null
	_route_explicit = false
	if had:
		route_changed.emit(self, null)


func _too_short(post: Node3D) -> bool:
	var net := _network()
	if net and net.has_method(&"route_reason"):
		return String(net.call(&"route_reason", self, post)) == REASON_ROUTE_TOO_SHORT
	return route_length_to(post) < MIN_ROUTE_LENGTH


func _network() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"trade_network")


func _posts() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	var net := _network()
	var list: Array = net.call(&"posts") if net and net.has_method(&"posts") \
			else get_tree().get_nodes_in_group(&"trade_posts")
	for p in list:
		if is_instance_valid(p) and p is Node3D:
			out.append(p)
	return out


func _door_of(post: Node3D) -> Vector3:
	if post.has_method(&"door_point"):
		return post.call(&"door_point")
	return post.global_position


# ---------------------------------------------------------------- look

## No rally flag: a right-click with the Bazaar selected sets the route (market-trade.md 8).
func _update_flag() -> void:
	if _flag:
		_flag.visible = false


## Placeholder until the Bazaar models exist: a platform, a stall under a striped awning in the kingdom
## colour, a tall mast with a balance scale and a crate stack (market-trade.md 9, 10.V1-10.V4).
func _build_shape() -> void:
	var body := _body_size()
	var wood := Color(0.42, 0.3, 0.2)
	var platform := BoxMesh.new()
	platform.size = Vector3(body.x - 0.4, 0.4, body.z - 0.4)
	_add_mesh(platform, building_type.body_color.darkened(0.25) if building_type else wood, 0.2)
	var stall := BoxMesh.new()
	stall.size = Vector3(3.6, 2.0, 2.8)
	var s := _add_mesh(stall, building_type.body_color if building_type else wood, 1.4)
	s.position.x = -0.6
	s.position.z = -0.4
	var awning := PrismMesh.new()
	awning.size = Vector3(4.4, 0.9, 3.6)
	var a := _add_mesh(awning, team_color, 2.85)
	a.position.x = -0.6
	a.position.z = -0.4
	var mast := CylinderMesh.new()
	mast.top_radius = 0.1
	mast.bottom_radius = 0.16
	mast.height = body.y + 1.0
	var m := _add_mesh(mast, wood, (body.y + 1.0) * 0.5)
	m.position = Vector3(2.0, m.position.y, 2.0)
	var beam := BoxMesh.new()
	beam.size = Vector3(1.8, 0.1, 0.1)
	var bm := _add_mesh(beam, Color(0.75, 0.55, 0.25), body.y + 0.8)
	bm.position = Vector3(2.0, bm.position.y, 2.0)
	for side in [-1.0, 1.0]:
		var pan := CylinderMesh.new()
		pan.top_radius = 0.3
		pan.bottom_radius = 0.22
		pan.height = 0.08
		var p := _add_mesh(pan, Color(1.0, 0.8, 0.3), body.y + 0.2)
		p.position = Vector3(2.0 + 0.8 * side, p.position.y, 2.0)
	var crate := BoxMesh.new()
	crate.size = Vector3(0.9, 0.9, 0.9)
	var c1 := _add_mesh(crate, wood.lightened(0.15), 0.85)
	c1.position = Vector3(-2.1, c1.position.y, 2.0)
	var c2 := _add_mesh(crate, wood.lightened(0.05), 1.75)
	c2.position = Vector3(-2.1, c2.position.y, 2.0)
	c2.rotation.y = 0.4
