extends SceneTree
## Task 10.C2: the Bazaar (market-trade.md 4.1 / 12). Checks: the 4 .tres numbers; the Bazaar is in the
## build menu (buildable_for, key B, last) only while trade is on; BuildGrid.create_building makes a
## Market; placement refusals in order (no Hall -> "Needs a completed Hall" (a Hall site does not count),
## 25 m from the keep -> "Must be within 20 m of your keep", crystals after both, a second one ->
## "Only one Bazaar"); Market.of_team (the contract's for_team; completed only); not a shop / drop-off; set_route works and refuses
## a non-post and a too-short route; the default route is the near post with the highest value;
## route_value formula; a 7th caravan (alive + queued) -> "Caravan limit reached"; a queued caravan is
## trained after 20 s with home_market = the Bazaar; a destroyed Bazaar refunds its queue.
## Other step-10 parts are stubbed here: a Node in group "gold_banks" turns trade on, trading posts are
## plain Node3D in group "trade_posts", the caravan UnitType is built here if data/units/caravan.tres
## is missing.
## Run:  godot --headless --path . -s tests/test_10_c2.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "10.C2"
const TIMEOUT_FRAMES := 3000
const SETUP_FRAME := 5

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _log: Array[String] = []

var grid: BuildGrid
var eco: Economy
var keep: Keep
var market: Market
var caravan_type: UnitType
var _routes_seen: Array = []
var _trained: Array = []
var _queue_frame := -1
var _done := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == SETUP_FRAME:
		_setup()
	elif frame > SETUP_FRAME and _errors.is_empty():
		_tick()
	if not _errors.is_empty() or _done:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (queued at frame %d, trained %d)" % [_queue_frame, _trained.size()])
		return _finish()
	return false


# ---------------------------------------------------------------- setup

func _setup() -> void:
	grid = main.build_grid
	eco = main.economy
	keep = main.keep
	_check_types()
	_check_build_menu()
	if not _errors.is_empty():
		return
	_check_placement()
	if not _errors.is_empty():
		return
	_check_market_api()
	if not _errors.is_empty():
		return
	_check_routes()
	if not _errors.is_empty():
		return
	_check_caravan_limit()


func _check_types() -> void:
	# id: [name, cost, build_time, max_hp, faction]
	var want := {
		"fire_market": ["Ember Bazaar", 175, 1000.0, "fire"],
		"shadow_market": ["Gloom Bazaar", 175, 1000.0, "shadow"],
		"ice_market": ["Frost Bazaar", 175, 1200.0, "ice"],
		"nature_market": ["Grove Bazaar", 155, 900.0, "nature"],
	}
	for id: String in want:
		var t := BuildingType.find(id)
		if t == null:
			_errors.append("missing data/buildings/%s.tres" % id)
			continue
		var w: Array = want[id]
		if t.display_name != w[0] or t.cost != w[1] or t.max_hp != w[2] or String(t.faction) != w[3] \
				or t.build_time != 40.0 or t.footprint != Vector2i(3, 3) or t.height != 4.5 \
				or t.sight_radius != 12.0 or t.kind != &"market" or t.hotkey_label != "B" or t.max_count != 1 \
				or t.requires_kind != &"barracks" or t.max_keep_distance != 20.0 or not t.counts_for_defeat \
				or t.train_ids != Array([&"caravan"], TYPE_STRING_NAME, &"", null) or t.pop_bonus != 0:
			_errors.append("%s numbers" % id)
		var faction := String(t.faction)
		if t.model_path != "res://art/buildings/market/%s/market_%s.tscn" % [faction, faction]:
			_errors.append("%s model_path %s" % [id, t.model_path])
		if not BuildingType.ALL_IDS.has(StringName(id)):
			_errors.append("%s not in ALL_IDS" % id)
		if BuildingType.find(String(t.display_name)) != t:
			_errors.append("find by name %s" % t.display_name)
	if BuildingType.find("nature_market") and BuildingType.find("nature_market").idle_regen_pct != 1.0:
		_errors.append("Grove Bazaar has no Verdant regen")


func _check_build_menu() -> void:
	var menus := {
		&"fire": ["fire_hearth", "fire_barracks", "fire_tower"],
		&"shadow": ["shadow_hovel", "shadow_barracks", "shadow_tower"],
		&"ice": ["ice_lodge", "ice_barracks", "ice_tower", "ice_wall"],
		&"nature": ["nature_hollow", "nature_barracks", "nature_tower"],
	}
	# Trade off (no GoldBank, no TradeNetwork: the mission map): the old menus, unchanged.
	if BuildingType.trade_active():
		_errors.append("trade_active() with no GoldBank / TradeNetwork")
	for f: StringName in menus:
		if _ids(BuildingType.buildable_for(f)) != menus[f]:
			_errors.append("trade off: %s menu %s" % [f, _ids(BuildingType.buildable_for(f))])
	# Trade on: the kingdom's Bazaar comes last, key B.
	# A stand-in bank of no team (-1): Building / Unit look banks up by `team`, none will match it.
	var stub := GDScript.new()
	stub.source_code = "extends Node\nvar team := -1\n"
	stub.reload()
	var bank: Node = stub.new()
	bank.name = "StubGoldBank"
	bank.add_to_group(&"gold_banks")
	main.add_child(bank)
	if not BuildingType.trade_active():
		_errors.append("trade_active() false with a node in gold_banks")
	for f: StringName in menus:
		var want: Array = (menus[f] as Array).duplicate()
		want.append("%s_market" % f)
		var got := BuildingType.buildable_for(f)
		if _ids(got) != want:
			_errors.append("trade on: %s menu %s" % [f, _ids(got)])
		elif got[got.size() - 1].hotkey_label != "B":
			_errors.append("%s Bazaar key %s" % [f, got[got.size() - 1].hotkey_label])
	var probe := BuildGrid.create_building(BuildingType.find("fire_market"))
	if not probe is Market or not probe is TrainingBuilding:
		_errors.append("create_building(fire_market) is not a Market")
	probe.free()


# ---------------------------------------------------------------- placement

func _check_placement() -> void:
	var bazaar := BuildingType.find("fire_market")
	var hall_t := BuildingType.find("fire_barracks")
	# The same type without the Bazaar rules, to find spots that pass every other rule.
	var free := bazaar.duplicate() as BuildingType
	free.requires_kind = &""
	free.max_keep_distance = 0.0
	free.max_count = 0
	eco.crystals = 5000
	var k := keep.global_position

	# 1. No Hall.
	var s := _spot(free, k)
	if _flat(s, k) > 20.0:
		_errors.append("nearest free Bazaar spot %.1f m from the keep" % _flat(s, k))
		return
	_expect(bazaar, s, BuildGrid.MSG_NEEDS_HALL)
	if BuildGrid.prerequisite_reason(bazaar, Unit.Team.PLAYER) != BuildGrid.MSG_NEEDS_HALL:
		_errors.append("prerequisite_reason without a Hall")
	eco.crystals = 10
	_expect(bazaar, s, BuildGrid.MSG_NEEDS_HALL)   # the Hall rule speaks before the crystals
	eco.crystals = 5000

	# 2. A Hall under construction does not count.
	var hall_spot := grid.find_spot(hall_t, k + Vector3(0, 0, -12), Unit.Team.PLAYER)
	var site := grid.place(hall_t, hall_spot, Unit.Team.PLAYER, [])
	if site == null:
		_errors.append("Hall site refused: %s" % grid.last_reason)
		return
	s = _spot(free, k)
	_expect(bazaar, s, BuildGrid.MSG_NEEDS_HALL)
	site.cancel_construction()

	# 3. A completed Hall: ok near the keep.
	var hall := grid.spawn_complete(hall_t, hall_spot, Unit.Team.PLAYER)
	grid.request_rebake()
	if hall == null or not hall.is_constructed():
		_errors.append("spawn_complete Hall")
		return
	if BuildGrid.prerequisite_reason(bazaar, Unit.Team.PLAYER) != "":
		_errors.append("prerequisite_reason with a Hall")
	s = _spot(free, k)
	_expect(bazaar, s, "")
	_log.append("Bazaar spot %s, %.1f m from the keep %s" % [s, _flat(s, k), k])
	var m1 := Vector3(-45, 0, 27)
	_log.append("M1 (-45, 27): %.1f m from the keep, check '%s'" % [_flat(m1, k), grid.check(bazaar, m1, Unit.Team.PLAYER)])

	# 4. 25 m from the keep.
	var far := Vector3.INF
	for r in [25.0, 24.0, 26.0, 23.0]:
		for i in 24:
			var a := TAU * i / 24.0
			var p := grid.snap(k + Vector3(cos(a), 0, sin(a)) * float(r), bazaar.footprint)
			if _flat(p, k) > 20.5 and grid.check(free, p, Unit.Team.PLAYER) == "":
				far = p
				break
		if far != Vector3.INF:
			break
	if far == Vector3.INF:
		_errors.append("no free spot 23-26 m from the keep")
		return
	_expect(bazaar, far, BuildGrid.MSG_KEEP_DISTANCE)
	eco.crystals = 10
	_expect(bazaar, far, BuildGrid.MSG_KEEP_DISTANCE)   # before the crystals too
	_expect(bazaar, s, BuildGrid.MSG_NO_CRYSTALS)
	eco.crystals = 5000
	_log.append("far spot %s at %.1f m" % [far, _flat(far, k)])
	# The enemy (its keep far away) is refused at the player's spot by the distance rule, not the Hall.
	if BuildGrid.keep_distance_reason(bazaar, s, Unit.Team.ENEMY) != BuildGrid.MSG_KEEP_DISTANCE:
		_errors.append("enemy keep distance at the player's spot")

	# 5. Place it (175 crystals), then a second one is refused.
	var before := eco.crystals
	var bsite := grid.place(bazaar, s, Unit.Team.PLAYER, [])
	if bsite == null or not bsite is Market or eco.crystals != before - 175:
		_errors.append("Bazaar placement: %s, %d crystals" % [grid.last_reason, before - eco.crystals])
		return
	if Market.of_team(Unit.Team.PLAYER) != null:
		_errors.append("for_team returns a construction site")
	if (bsite as Market).can_queue(_caravan()) != TrainingBuilding.REASON_UNDER_CONSTRUCTION:
		_errors.append("a Bazaar site can train")
	var s2 := _spot(free, k)
	_expect(bazaar, s2, BuildGrid.MSG_MARKET_LIMIT)
	if not BuildGrid.at_limit(bazaar, Unit.Team.PLAYER) or BuildGrid.limit_message(bazaar) != "Only one Bazaar" \
			or BuildGrid.at_limit(bazaar, Unit.Team.ENEMY):
		_errors.append("at_limit / limit_message")
	# Other limits keep their messages.
	if BuildGrid.limit_message(BuildingType.find("fire_hearth")) != BuildGrid.MSG_LIMIT \
			or BuildGrid.limit_message(BuildingType.find("ice_wall")) != BuildGrid.MSG_WALL_LIMIT:
		_errors.append("hearth / wall limit messages changed")
	before = eco.crystals
	bsite.cancel_construction()
	if eco.crystals != before + 131:
		_errors.append("cancel refund %d, want 131" % (eco.crystals - before))
	market = grid.spawn_complete(bazaar, s, Unit.Team.PLAYER) as Market
	grid.request_rebake()


# ---------------------------------------------------------------- Market

func _check_market_api() -> void:
	if market == null or not market.is_constructed():
		_errors.append("spawn_complete Bazaar is not a completed Market")
		return
	if Market.of_team(Unit.Team.PLAYER) != market or Market.of_team(Unit.Team.ENEMY) != null:
		_errors.append("Market.for_team")
	if market.is_shop() or market.is_drop_off() or not market.counts_for_defeat() or market.hp != 1000.0:
		_errors.append("shop %s drop-off %s defeat %s hp %.0f" % [market.is_shop(), market.is_drop_off(),
				market.counts_for_defeat(), market.hp])
	if Building.nearest_drop_off(Unit.Team.PLAYER, market.global_position) == market:
		_errors.append("workers would deliver to the Bazaar")
	var types := market.trainable_types()
	if types.size() != 1 or not Market.is_caravan_type(types[0]):
		_errors.append("Bazaar trains %s" % [types])
	if market.can_queue(UnitType.find("flame_guard")) != TrainingBuilding.REASON_UNKNOWN:
		_errors.append("the Bazaar trains soldiers")


func _check_routes() -> void:
	var k := keep.global_position
	var m := market.global_position
	var away := Vector2(m.x - k.x, m.z - k.z).normalized()
	var side := Vector2(-away.y, away.x)
	# Posts: two near (door < 60 m from the keep), one far, one too short (< 20 m from the Bazaar).
	var near_a := _post("NearA", k + Vector3(side.x, 0, side.y) * 35.0)
	var near_b := _post("NearB", k + Vector3(-side.x, 0, -side.y) * 52.0)
	var far_post := _post("Far", k + Vector3(away.x, 0, away.y) * 95.0)
	var short := _post("Short", m + Vector3(away.x, 0, away.y) * 9.0)
	market.route_changed.connect(func(mk: Market, p: Node3D) -> void: _routes_seen.append([mk, p]))
	var la := market.route_length_to(near_a)
	var lb := market.route_length_to(near_b)
	var want_default: Node3D = near_a if _value(la) > _value(lb) else near_b
	if market.default_route() != want_default or market.route_post != want_default:
		_errors.append("default route %s, want %s (L %.1f / %.1f)" % [market.route_post, want_default, la, lb])
	if market.has_explicit_route():
		_errors.append("the default route counts as explicit")
	if market.is_far_post(near_a) or market.is_far_post(near_b) or not market.is_far_post(far_post):
		_errors.append("near / far")
	var lf := market.route_length_to(far_post)
	if market.route_value_to(far_post) != _value(lf):
		_errors.append("route_value_to(far) %d, want %d" % [market.route_value_to(far_post), _value(lf)])
	# The spec's table: 49.2 m -> 28, 144.9 m (cap 140) -> 154, 26.3 m -> 15, 122.0 -> 119.
	if _value(49.2) != 28 or _value(144.9) != 154 or _value(26.3) != 15 or _value(122.0) != 119:
		_errors.append("value formula")
	_routes_seen.clear()
	if market.set_route(far_post) != "" or market.route_post != far_post or not market.has_explicit_route() \
			or market.route_value() != _value(lf):
		_errors.append("set_route(far)")
	if _routes_seen.size() != 1 or _routes_seen[0][0] != market or _routes_seen[0][1] != far_post:
		_errors.append("route_changed %s" % [_routes_seen])
	var not_post := Node3D.new()
	main.add_child(not_post)
	not_post.global_position = far_post.global_position
	if market.set_route(not_post) != Market.REASON_NOT_A_POST or market.set_route(null) != Market.REASON_NOT_A_POST:
		_errors.append("set_route(non-post)")
	if market.set_route(short) != Market.REASON_ROUTE_TOO_SHORT:
		_errors.append("set_route(short): '%s' (L %.1f)" % [market.set_route(short), market.route_length_to(short)])
	if market.route_post != far_post:
		_errors.append("a refused route changed the route")
	# A freed post falls back to the default.
	far_post.free()
	if market.route_post != want_default or market.has_explicit_route():
		_errors.append("route after the post was freed: %s" % market.route_post)
	market.route_post = near_a
	if market.route_post != near_a:
		_errors.append("route_post = near_a")
	_log.append("routes: near A %.1f m (%d), near B %.1f m (%d), far %.1f m (%d)" % [la, _value(la), lb, _value(lb),
			lf, _value(lf)])


func _check_caravan_limit() -> void:
	caravan_type = _caravan()
	eco.add_pop_bonus(20)
	eco.crystals = 5000
	# 4 living caravans + 2 queued = 6; a 7th is refused.
	for i in 4:
		var u := Worker.make_unit(caravan_type)
		u.team = Unit.Team.PLAYER
		main.add_child(u)
		u.global_position = market.global_position + Vector3(6 + i, 0, 6)
		u.command_stop()
	if Market.caravan_count(Unit.Team.PLAYER) != 4 or market.caravans().size() != 4:
		_errors.append("caravan_count %d, caravans() %d" % [Market.caravan_count(Unit.Team.PLAYER),
				market.caravans().size()])
	for i in 2:
		var r := market.queue_unit(caravan_type)
		if r != "":
			_errors.append("caravan %d refused: %s" % [5 + i, r])
	if Market.caravan_count(Unit.Team.PLAYER) != 6 or market.queued_caravans() != 2:
		_errors.append("6 caravans counted as %d" % Market.caravan_count(Unit.Team.PLAYER))
	var crystals := eco.crystals
	if market.can_queue(caravan_type) != Market.REASON_CARAVAN_LIMIT \
			or market.queue_unit(caravan_type) != Market.REASON_CARAVAN_LIMIT or eco.crystals != crystals:
		_errors.append("7th caravan: '%s'" % market.can_queue(caravan_type))
	# One queued caravan leaves: room again for exactly one.
	market.cancel(1)
	if market.can_queue(caravan_type) != "" or eco.crystals != crystals + caravan_type.cost:
		_errors.append("after a cancel: '%s'" % market.can_queue(caravan_type))
	# The enemy's count is separate.
	if Market.caravan_count(Unit.Team.ENEMY) != 0:
		_errors.append("enemy caravan count")
	market.unit_trained.connect(func(u: Unit) -> void: _trained.append(u))
	_queue_frame = frame


# ---------------------------------------------------------------- every frame

func _tick() -> void:
	if _queue_frame < 0 or _done:
		return
	if _trained.is_empty():
		return
	var secs := (frame - _queue_frame) / 60.0
	var u: Unit = _trained[0]
	_log.append("caravan trained after %.2f s" % secs)
	if absf(secs - caravan_type.train_time) > 0.2:
		_errors.append("caravan trained in %.2f s, want %.0f" % [secs, caravan_type.train_time])
	if not Market.is_caravan_unit(u) or u.team != Unit.Team.PLAYER:
		_errors.append("trained unit is not a player caravan")
	if &"home_market" in u and u.get(&"home_market") != market:
		_errors.append("home_market not set")
	if _flat(u.global_position, market.spawn_point()) > 1.5:
		_errors.append("caravan spawned at %s, spawn point %s" % [u.global_position, market.spawn_point()])
	if not market.caravans().has(u) or Market.caravan_count(Unit.Team.PLAYER) != 5:
		_errors.append("after training: caravans %d, count %d" % [market.caravans().size(),
				Market.caravan_count(Unit.Team.PLAYER)])
	# A destroyed Bazaar: its queue is refunded, for_team is null, the limit frees nothing more.
	market.queue_unit(caravan_type)
	var crystals := eco.crystals
	market.take_damage(99999.0, null)
	if market.is_alive() or Market.of_team(Unit.Team.PLAYER) != null or eco.crystals != crystals + caravan_type.cost \
			or not market.queue.is_empty():
		_errors.append("destroyed Bazaar: alive %s, for_team %s, refund %d" % [market.is_alive(),
				Market.of_team(Unit.Team.PLAYER), eco.crystals - crystals])
	if BuildGrid.at_limit(BuildingType.find("fire_market"), Unit.Team.PLAYER):
		_errors.append("a destroyed Bazaar still counts for the limit")
	_done = true


# ---------------------------------------------------------------- helpers

## data/units/caravan.tres (10.C6) if it exists, else a stub with the numbers of 4.2 put in the Bazaar's list.
func _caravan() -> UnitType:
	if caravan_type:
		return caravan_type
	var t := UnitType.find("caravan")
	if t == null:
		t = UnitType.new()
		t.id = &"caravan"
		t.display_name = "Caravan"
		t.cost = 75
		t.pop = 1
		t.train_time = 20.0
		t.max_hp = 220.0
		t.move_speed = 4.0
		t.attack_damage = 0.0
		t.aggro_range = 0.0
		t.radius = 0.8
		if &"is_caravan" in t:
			t.set(&"is_caravan", true)
		_log.append("caravan.tres missing: stub type")
	for bid in ["fire_market", "shadow_market", "ice_market", "nature_market"]:
		var bt := BuildingType.find(bid)
		bt.resolve_trains()
		if bt.trains.is_empty():
			bt.trains.append(t)
	caravan_type = t
	return t


func _post(post_name: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = post_name
	p.add_to_group(&"trade_posts")
	main.add_child(p)
	p.global_position = Vector3(pos.x, 0, pos.z)
	return p


func _value(length: float) -> int:
	var l := minf(length, 140.0)
	return roundi(10.0 + l * l / 136.0)


func _spot(type: BuildingType, near: Vector3) -> Vector3:
	var p := grid.find_spot(type, near, Unit.Team.PLAYER, 14)
	if p == Vector3.INF:
		_errors.append("no spot for %s near %s" % [type.id, near])
	return p


func _expect(type: BuildingType, pos: Vector3, want: String) -> void:
	var got := grid.check(type, pos, Unit.Team.PLAYER)
	if got != want:
		_errors.append("%s at %s: '%s', want '%s'" % [type.id, pos, got, want])


func _ids(types: Array[BuildingType]) -> Array:
	var out: Array = []
	for t in types:
		out.append(String(t.id))
	return out


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	for line in _log:
		print("  ", line)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true
