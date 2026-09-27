extends SceneTree
## Task 10.C3: the caravan loop (docs/design/market-trade.md 4.2-4.3, 5.4, "Done when" 10.C3).
## Run:  godot --headless --path . -s tests/test_10_c3.gd --fixed-fps 60 --quit-after 13000
## A small flat world (no HUD / map scripts). TradeNetwork, TradePost, GoldBank, Market and LootSack are other
## step-10 tasks: stubbed here with runtime scripts reached the same way Caravan reaches them (groups,
## has_method, Caravan.loot_sack_script).
## Scenarios run side by side from t = 0 (posts closed for the first CLOSED_TIME seconds):
##   A  Millstone Cross from a Bazaar at (-45, 27): load 2 s, out at 4.0, trade 2 s, back at 3.6, +28 per trip,
##      ~56 / min +-10 % over 3 min; waits while the posts are closed.
##   B  Saltgate (own route): passes w_door, nw1, nw2, then the door, in that order.
##   C  Lantern Wharf held: waits at se1 (the last waypoint) 45 s, then home empty.
##   E  Heron Ford held (near route): waits 20 m before the door.
##   F  enemy Bazaar destroyed while a loaded caravan returns: it waits at the keep, delivers to the rebuilt one.
##   G  Move / Stop / Hold keep the cargo; command_trade(own Bazaar) goes home and delivers.
##   D  steal(60) from 119 leaves 59, emits robbed; summed robbery line.
##   H  a loaded caravan killed drops a 50 % sack; an empty one drops nothing.
##   Worker.make_unit builds a Caravan for is_caravan types; command_trade refusals.

const TASK_ID := "10.C3"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL
const CLOSED_TIME := 3.0
const RATE_WINDOW := 180.0
const FPS := 60.0
const MARKET_PATH := "res://scripts/buildings/market.gd"

const BAZAAR_P := Vector3(-45.0, 0.0, 27.0)
const BAZAAR_E := Vector3(45.0, 0.0, -27.0)
const BAZAAR_E2 := Vector3(38.0, 0.0, -30.0)
const KEEP_P := Vector3(-43.0, 0.0, 43.0)
const KEEP_E := Vector3(43.0, 0.0, -43.0)
const W_DOOR := Vector3(-49.0, 0.0, 1.0)
const NW1 := Vector3(-48.0, 0.0, -44.0)
const NW2 := Vector3(-44.0, 0.0, -48.0)
const N_DOOR := Vector3(1.0, 0.0, -49.0)
const S_DOOR := Vector3(-1.0, 0.0, 49.0)
const SE2 := Vector3(44.0, 0.0, 48.0)
const SE1 := Vector3(48.0, 0.0, 44.0)
const E_DOOR := Vector3(49.0, 0.0, -1.0)

const WORLD_SRC := "extends Node3D\nvar hud: Node = null\nvar sacks: Array = []\n" \
		+ "func record_sack(pos: Vector3, amount: int) -> void:\n\tsacks.append([pos, amount])\n"
const HUD_SRC := "extends Node\nvar lines: Array = []\nvar frames: Array = []\n" \
		+ "func show_message(text: String, _seconds: float = 2.0) -> void:\n" \
		+ "\tlines.append(text)\n\tframes.append(Engine.get_physics_frames())\n"
const NET_SRC := "extends Node\nsignal caravan_robbed(team: int, caravan: Node, amount: int, thief: Node)\n" \
		+ "var open := false\nvar routes := {}\nvar values := {}\nvar deliveries: Array = []\n" \
		+ "func is_open() -> bool:\n\treturn open\n" \
		+ "func route_points(_market: Node3D, post: Node3D) -> PackedVector3Array:\n" \
		+ "\treturn PackedVector3Array(routes.get(post, []))\n" \
		+ "func route_value(_market: Node3D, post: Node3D) -> int:\n\treturn int(values.get(post, 0))\n" \
		+ "func route_reason(_market: Node3D, post: Node3D) -> String:\n" \
		+ "\tif not open:\n\t\treturn \"Trading posts open at 4:00\"\n" \
		+ "\tif post.get(&\"held\"):\n\t\treturn \"Held by the enemy\"\n\treturn \"\"\n" \
		+ "func record_delivery(team: int, amount: int, post: Node, caravan: Node) -> void:\n" \
		+ "\tdeliveries.append([team, amount, post, caravan])\n"
const POST_SRC := "extends Node3D\nvar post_id: StringName = &\"\"\nvar display_name := \"\"\n" \
		+ "var door := Vector3.ZERO\nvar held := false\n" \
		+ "func door_point() -> Vector3:\n\treturn door\n" \
		+ "func is_held_by_enemy_of(_team: int) -> bool:\n\treturn held\n" \
		+ "func is_open() -> bool:\n\treturn true\n"
const BANK_SRC := "extends Node\nvar team := 0\nvar gold := 0\nvar log: Array = []\n" \
		+ "func add(n: int, source: StringName = &\"\") -> void:\n\tgold += n\n\tlog.append([n, source])\n"
const SACK_SRC := "extends RefCounted\n" \
		+ "static func spawn(parent: Node, pos: Vector3, amount: int) -> Node3D:\n" \
		+ "\tparent.call(&\"record_sack\", pos, amount)\n\treturn null\n"
const MARKET_SRC := "extends TrainingBuilding\nvar route_post: Node3D = null\n"
const VFX_SRC := "extends Node3D\nvar calls: Array = []\n" \
		+ "func play(id: StringName, at: Vector3, target: Variant) -> void:\n\tcalls.append([id, at, target])\n"
const CARAVAN_TYPE_SRC := "extends UnitType\n@export var is_caravan := false\n"

var world: Node3D
var hud: Node
var net: Node
var banks := {}
var vfx: Node3D
var market_script: GDScript
var real_market_script: Script = null
var caravan_type: UnitType
var posts := {}      # StringName -> post node
var errors: Array[String] = []
var finished := false
var stages := 0

var ma: Building     # player Bazaar
var mf: Building     # enemy Bazaar (destroyed)
var mf2: Building    # enemy Bazaar (rebuilt)
var keep_e: Keep
var a: Caravan
var b: Caravan
var c: Caravan
var e: Caravan
var f: Caravan
var g: Caravan

var t := -1.0            # game time since the posts opened (negative before)
var frames := 0
var open_frame := -1
var deliveries: Array = []   # [name, amount, time, home_market]
var a_states: Array = []     # [time, state]
var a_speed_out: Array[float] = []
var a_speed_back: Array[float] = []
var a_speed_stat_out := -1.0
var a_speed_stat_back := -1.0
var b_passed: Array[String] = []
var c_wait_start := -1.0
var c_wait_pos := Vector3.INF
var c_wait_end := -1.0
var c_after := ""
var c_after_cargo := -1
var e_wait_pos := Vector3.INF
var f_destroyed_at := -1.0
var f_cargo_at_destroy := 0
var f_at_keep := -1.0
var f_keep_text := ""
var f_keep_cargo := -1
var robbed_events: Array = []
var net_robbed_events: Array = []


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	world.set_script(_script(WORLD_SRC))
	root.add_child(world)
	current_scene = world
	hud = Node.new()
	hud.set_script(_script(HUD_SRC))
	world.add_child(hud)
	world.set(&"hud", hud)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(260.0, 1.0, 260.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(240.0, 240.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	_setup_stubs()
	_test_make_unit()
	_test_refusals()
	_setup_scenarios()
	physics_frame.connect(_monitor)
	await _wait(2)
	_check_closed_phase_start()
	await _wait(int((CLOSED_TIME - 2.0 / FPS) * FPS))
	_check_closed_phase_end()
	net.set(&"open", true)
	open_frame = frames
	await _test_steal_and_death()
	await _wait_until(func() -> bool: return t >= RATE_WINDOW + 2.0, int((RATE_WINDOW + 10.0) * FPS))
	_check_rate_and_timings()
	_check_saltgate()
	_check_held()
	_check_bazaar_lost()
	_check_move_stop()
	_check_messages()
	stages += 1
	_eq(stages, 2, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- setup

func _setup_stubs() -> void:
	net = Node.new()
	net.name = "TradeNetworkStub"
	net.set_script(_script(NET_SRC))
	net.add_to_group(&"trade_network")
	world.add_child(net)
	net.connect(&"caravan_robbed", func(team: int, car: Node, amount: int, thief: Node) -> void:
		net_robbed_events.append([team, car, amount, thief]))
	for team in [P, E]:
		var bank := Node.new()
		bank.set_script(_script(BANK_SRC))
		bank.set(&"team", team)
		bank.add_to_group(&"gold_banks")
		world.add_child(bank)
		banks[team] = bank
	vfx = Node3D.new()
	vfx.set_script(_script(VFX_SRC))
	vfx.add_to_group(&"trade_vfx")
	world.add_child(vfx)
	Caravan.loot_sack_script = _script(SACK_SRC)
	market_script = _script(MARKET_SRC)
	if ResourceLoader.exists(MARKET_PATH):   # 10.C2's Market (committed): tested with the real Bazaar
		real_market_script = load(MARKET_PATH) as Script
	# Posts (centre 4 m behind the door), routes and values of market-trade.md 2.2 / 4.3.
	_post(&"millstone_cross", "Millstone Cross", S_DOOR, Vector3(-1.0, 0.0, 53.0), [S_DOOR], 28)
	_post(&"saltgate", "Saltgate", N_DOOR, Vector3(1.0, 0.0, -53.0), [W_DOOR, NW1, NW2, N_DOOR], 119)
	_post(&"lantern_wharf", "Lantern Wharf", E_DOOR, Vector3(53.0, 0.0, -1.0), [S_DOOR, SE2, SE1, E_DOOR], 154)
	_post(&"heron_ford", "Heron Ford", W_DOOR, Vector3(-53.0, 0.0, 1.0), [W_DOOR], 15)
	# The enemy's near post is Saltgate (mirror of Millstone Cross): its own stub so the routes stay apart.
	_post(&"saltgate_e", "Saltgate", N_DOOR, Vector3(1.0, 0.0, -53.0), [N_DOOR], 28)
	posts[&"lantern_wharf"].set(&"held", true)
	posts[&"heron_ford"].set(&"held", true)
	# The caravan type: data/units/caravan.tres numbers (4.2); is_caravan through a subclass if UnitType lacks it.
	caravan_type = UnitType.new()
	if not &"is_caravan" in caravan_type:
		caravan_type = _script(CARAVAN_TYPE_SRC).new() as UnitType
	caravan_type.id = &"caravan"
	caravan_type.display_name = "Caravan"
	caravan_type.cost = 75
	caravan_type.pop = 1
	caravan_type.train_time = 20.0
	caravan_type.max_hp = 220.0
	caravan_type.armor = 10.0
	caravan_type.attack_damage = 0.0
	caravan_type.aggro_range = 0.0
	caravan_type.move_speed = 4.0
	caravan_type.radius = 0.8
	caravan_type.body_height = 1.9
	caravan_type.kill_xp = 20
	caravan_type.set(&"is_caravan", true)


func _post(id: StringName, display: String, door: Vector3, centre: Vector3, route: Array, value: int) -> void:
	var p := Node3D.new()
	p.set_script(_script(POST_SRC))
	p.name = String(id)
	p.set(&"post_id", id)
	p.set(&"display_name", display)
	p.set(&"door", door)
	p.add_to_group(&"trade_posts")
	world.add_child(p)
	p.global_position = centre
	posts[id] = p
	var routes: Dictionary = net.get(&"routes")
	routes[p] = route
	var values: Dictionary = net.get(&"values")
	values[p] = value


func _market(team: int, pos: Vector3, post: Node3D) -> Building:
	var type := BuildingType.new()
	type.id = &"fire_market" if team == P else &"shadow_market"
	type.display_name = "Ember Bazaar" if team == P else "Gloom Bazaar"
	type.faction = &"fire" if team == P else &"shadow"
	type.kind = &"market"
	type.cost = 175
	type.build_time = 40.0
	type.max_hp = 1000.0
	type.footprint = Vector2i(3, 3)
	type.height = 4.5
	type.max_count = 1
	var real := BuildingType.find(String(type.id))   # 10.C2's .tres when it exists
	var m := (real_market_script.new() if real_market_script else market_script.new()) as Building
	m.building_type = real if real and real_market_script else type
	m.team = team as Unit.Team
	world.add_child(m)
	m.global_position = pos
	m.set(&"route_post", post)
	return m


## A caravan as Market._spawn makes it (home_market set before add_child, stop, command_trade(market)), or
## (legacy = true) as TrainingBuilding._spawn does (stop, then walk to the rally point): the caravan finds its
## Bazaar and starts the loop by itself.
func _trained(market: Building, cname: String, legacy: bool = false) -> Caravan:
	var car := Worker.make_unit(caravan_type) as Caravan
	car.name = cname
	car.team = market.team
	if not legacy:
		car.home_market = market
	world.add_child(car)
	car.global_position = market.call(&"spawn_point")
	car.command_stop()
	if legacy:
		car.command_move(market.call(&"rally_point"))
	else:
		_eq(car.command_trade(market), "", "%s: command_trade(own Bazaar) at spawn" % cname)
	car.delivered.connect(func(who: Caravan, amount: int) -> void:
		deliveries.append([String(who.name), amount, t, who.home_market]))
	return car


func _loose(team: int, pos: Vector3, cname: String) -> Caravan:
	var car := Worker.make_unit(caravan_type) as Caravan
	car.name = cname
	car.team = team as Unit.Team
	world.add_child(car)
	car.global_position = pos
	car.command_stop()
	car.delivered.connect(func(who: Caravan, amount: int) -> void:
		deliveries.append([String(who.name), amount, t, who.home_market]))
	return car


func _setup_scenarios() -> void:
	var kp := Keep.new()
	kp.building_type = BuildingType.find("fire_keep")
	kp.team = P as Unit.Team
	world.add_child(kp)
	kp.global_position = KEEP_P
	keep_e = Keep.new()
	keep_e.building_type = BuildingType.find("shadow_keep")
	keep_e.team = E as Unit.Team
	world.add_child(keep_e)
	keep_e.global_position = KEEP_E
	ma = _market(P, BAZAAR_P, posts[&"millstone_cross"])
	mf = _market(E, BAZAAR_E, posts[&"saltgate_e"])
	a = _trained(ma, "A")
	b = _trained(ma, "B")
	_eq(b.command_trade(posts[&"saltgate"]), "", "command_trade(Saltgate) accepted")
	c = _trained(ma, "C")
	_eq(c.command_trade(posts[&"lantern_wharf"]), "", "command_trade(Lantern Wharf) accepted")
	e = _trained(ma, "E")
	_eq(e.command_trade(posts[&"heron_ford"]), "", "command_trade(Heron Ford) accepted")
	f = _trained(mf, "F", true)
	g = _loose(P, Vector3(-28.0, 0.0, 34.0), "G")   # 17 m from the Bazaar: not "just trained"


# ---------------------------------------------------------------- instant checks

func _test_make_unit() -> void:
	var made := Worker.make_unit(caravan_type)
	_check(made is Caravan, "Worker.make_unit builds a Caravan for an is_caravan type")
	_near(made.get_stat(&"move_speed"), 4.0, "caravan base speed")
	made.free()
	var worker_type := UnitType.find("cinder_hand")
	if worker_type:
		var w := Worker.make_unit(worker_type)
		_check(w is Worker and not w is Caravan, "a worker type still makes a Worker")
		w.free()
	var soldier_type := UnitType.find("flame_guard")
	if soldier_type:
		var s := Worker.make_unit(soldier_type)
		_check(not s is Worker and not s is Caravan, "a soldier type still makes a plain Unit")
		s.free()
	var real := UnitType.find("caravan")   # 10.C6's .tres, when it exists
	if real and real.get(&"is_caravan") == true:
		var rc := Worker.make_unit(real)
		_check(rc is Caravan, "data/units/caravan.tres makes a Caravan")
		rc.free()


func _test_refusals() -> void:
	var lone := _loose(N, Vector3(10.0, 0.0, 80.0), "Lone")
	_eq(lone.command_trade(posts[&"millstone_cross"]), "No Bazaar", "no Bazaar: refused")
	_eq(lone.command_trade(null), "Not a trading post", "null target refused")
	_eq(lone.trade_state, &"idle", "a caravan created away from a Bazaar stays idle")
	lone.queue_free()


func _check_closed_phase_start() -> void:
	for car: Caravan in [a, b, c, e, f]:
		_check(car.home_market != null, "%s found its Bazaar at spawn" % car.name)
		_eq(car.trade_state, &"waiting", "%s waits while the posts are closed" % car.name)
		_eq(car.state_text(), "Waiting: posts open at 4:00", "%s state text before 4:00" % car.name)
	_eq(g.trade_state, &"idle", "G (not trained by a Bazaar) is idle")
	_eq(g.home_market, null, "G has no Bazaar yet")
	# G: Move / Stop / Hold keep the cargo and leave it idle.
	g.cargo = 50
	_check(g.is_loaded(), "G loaded")
	_near(g.get_stat(&"move_speed"), 3.6, "loaded speed 3.6")
	g.command_move(Vector3(-27.0, 0.0, 36.0))
	_eq(g.cargo, 50, "Move keeps the cargo")
	_eq(g.trade_state, &"idle", "Move leaves it idle")
	g.command_stop()
	_eq(g.cargo, 50, "Stop keeps the cargo")
	g.command_hold()
	_eq(g.cargo, 50, "Hold keeps the cargo")
	_eq(g.state_text(), "Idle", "idle text")
	_eq(g.command_trade(keep_e), "Not a trading post", "an enemy keep is not a trading post")
	_eq(g.command_trade(mf), "Not a trading post", "the enemy Bazaar is not a trading post")
	_eq(g.command_trade(ma), "", "command_trade(own Bazaar) accepted")
	_eq(g.home_market, ma, "G's Bazaar is the one ordered")
	_eq(g.trade_state, &"returning", "G goes home to deliver")
	_eq(g.state_text(), "Returning with 50", "returning text")


func _check_closed_phase_end() -> void:
	for car: Caravan in [a, b, c, e, f]:
		_eq(car.trade_state, &"waiting", "%s still waits at 0:%02d before the opening" % [car.name, int(CLOSED_TIME)])
		var home: Vector3 = car.home_market.call(&"spawn_point")
		_check(_flat(car.global_position, home) < 3.0, "%s waits at its Bazaar" % car.name)


func _test_steal_and_death() -> void:
	var d := _loose(P, Vector3(-20.0, 0.0, 20.0), "D")
	d.robbed.connect(func(who: Caravan, amount: int, thief: Node3D) -> void:
		robbed_events.append([who, amount, thief]))
	var thief := Node3D.new()
	world.add_child(thief)
	d.cargo = 119
	_eq(d.steal(60, thief), 60, "steal(60) from 119 takes 60")
	_eq(d.cargo, 59, "59 left")
	_check(d.is_loaded(), "still loaded with 59")
	_eq(robbed_events.size(), 1, "robbed emitted once")
	if robbed_events.size() == 1:
		_eq(robbed_events[0][1], 60, "robbed amount 60")
		_eq(robbed_events[0][2], thief, "robbed thief")
	_eq(net_robbed_events.size(), 1, "TradeNetwork.caravan_robbed emitted")
	_eq(d.steal(60, thief), 59, "the second snatch takes the last 59")
	_eq(d.cargo, 0, "empty after two snatches")
	_check(not d.is_loaded(), "not loaded any more")
	_near(d.get_stat(&"move_speed"), 4.0, "empty speed back to 4.0")
	_eq(d.steal(60, thief), 0, "nothing to steal from an empty caravan")
	var lines: Array = hud.get(&"lines")
	_check(lines.has("Your caravan was robbed: -60 gold"), "robbery line (got %s)" % str(lines))
	# Death: a loaded caravan drops 50 % (rounded down), an empty one nothing.
	var h := _loose(P, Vector3(-20.0, 0.0, 10.0), "H")
	h.cargo = 119
	var at := h.global_position
	h.take_damage(1.0e6, null)
	var sacks: Array = world.get(&"sacks")
	_eq(sacks.size(), 1, "a loaded caravan killed drops one sack")
	if sacks.size() == 1:
		_eq(sacks[0][1], 59, "the sack holds 50 % of 119")
		_check(_flat(sacks[0][0], at) < 0.1, "the sack lies where it died")
	var h2 := _loose(P, Vector3(-20.0, 0.0, 5.0), "H2")
	h2.take_damage(1.0e6, null)
	_eq(sacks.size(), 1, "an empty caravan drops no sack")
	_check(lines.has("Your caravan was destroyed"), "loss line")
	# The second robbery (59) within 10 s is summed into one line when the window ends.
	await _wait(int(11.0 * FPS))
	_check(lines.has("Your caravan was robbed: -59 gold"), "summed robbery line after 10 s (got %s)" % str(lines))
	d.queue_free()
	thief.queue_free()
	stages += 1


# ---------------------------------------------------------------- per-frame monitor

func _monitor() -> void:
	frames += 1
	if open_frame < 0:
		return
	t = (frames - open_frame) / FPS
	# A: states, speeds.
	if is_instance_valid(a):
		if a_states.is_empty() or a_states[a_states.size() - 1][1] != a.trade_state:
			a_states.append([t, a.trade_state])
		var speed := Vector2(a.velocity.x, a.velocity.z).length()
		var home: Vector3 = ma.call(&"spawn_point")
		var mid := _flat(a.global_position, home) > 8.0 and _flat(a.global_position, S_DOOR) > 8.0
		if mid and a.trade_state == &"to_post":
			a_speed_out.append(speed)
			a_speed_stat_out = a.get_stat(&"move_speed")
		elif mid and a.trade_state == &"returning":
			a_speed_back.append(speed)
			a_speed_stat_back = a.get_stat(&"move_speed")
	# B: waypoints passed.
	if is_instance_valid(b) and b_passed.size() < 4:
		var names := ["w_door", "nw1", "nw2", "n_door"]
		var pts := [W_DOOR, NW1, NW2, N_DOOR]
		for i in 4:
			if not b_passed.has(names[i]) and _flat(b.global_position, pts[i]) < 3.0:
				b_passed.append(names[i])
	# C: held wait at se1.
	if is_instance_valid(c):
		if c_wait_start < 0.0 and c.state_text() == "Waiting: Lantern Wharf is held" \
				and _flat(c.global_position, SE1) < 3.0:
			c_wait_start = t
			c_wait_pos = c.global_position
		elif c_wait_start >= 0.0 and c_wait_end < 0.0 and c.trade_state != &"waiting":
			c_wait_end = t
			c_after = c.trade_state
			c_after_cargo = c.cargo
	# E: held wait on a near route.
	if is_instance_valid(e) and e_wait_pos == Vector3.INF and e.state_text() == "Waiting: Heron Ford is held" \
			and t > 3.0 and e.velocity.length() < 0.05:
		e_wait_pos = e.global_position
	# F: destroy its Bazaar while it comes back loaded; rebuild once it waits at the keep.
	if is_instance_valid(f):
		if f_destroyed_at < 0.0 and f.trade_state == &"returning" and f.cargo > 0 \
				and _flat(f.global_position, BAZAAR_E) > 20.0:
			f_destroyed_at = t
			f_cargo_at_destroy = f.cargo
			mf.take_damage(1.0e7, null)
		elif f_destroyed_at >= 0.0 and f_at_keep < 0.0 and f.trade_state == &"waiting" \
				and _flat(f.global_position, keep_e.drop_off_point()) < 4.0:
			f_at_keep = t
			f_keep_text = f.state_text()
			f_keep_cargo = f.cargo
		elif f_at_keep >= 0.0 and mf2 == null and t > f_at_keep + 3.0:
			mf2 = _market(E, BAZAAR_E2, posts[&"saltgate_e"])
			mf2.collision_layer = 2   # no navmesh rebake in this flat world: keep the new body out of the way


# ---------------------------------------------------------------- final checks

func _check_rate_and_timings() -> void:
	var total := 0
	var last := 0.0
	var n := 0
	for dv: Array in deliveries:
		if dv[0] != "A":
			continue
		_eq(dv[1], 28, "A delivers 28 per Millstone Cross trip")
		if float(dv[2]) <= RATE_WINDOW:
			total += int(dv[1])
			last = float(dv[2])
			n += 1
	_check(n >= 5, "A made >= 5 trips in 3 min (got %d)" % n)
	var rate := total / maxf(last, 1.0) * 60.0
	print("  A: %d trips in 3 min, %.1f gold / min" % [n, rate])
	_check(absf(rate - 56.0) <= 5.6, "A earns ~56 gold / min +-10 %% (got %.1f over %d trips)" % [rate, n])
	var bank_log: Array = banks[P].get(&"log")
	var trade_ok := true
	for entry: Array in bank_log:
		trade_ok = trade_ok and entry[1] == &"trade"
	_check(not bank_log.is_empty() and trade_ok, "deliveries go to GoldBank.add(n, &\"trade\")")
	var recorded: Array = net.get(&"deliveries")
	var rec_a := 0
	for r: Array in recorded:
		if r[3] == a:
			rec_a += 1
			_eq(r[2], posts[&"millstone_cross"], "record_delivery names the post")
	_check(rec_a >= n, "TradeNetwork.record_delivery for every delivery of A")
	# Loading and trading last 2 s; the loop order.
	var loads: Array[float] = []
	var trades: Array[float] = []
	var order: Array[StringName] = []
	for i in range(a_states.size() - 1):
		var dur: float = a_states[i + 1][0] - a_states[i][0]
		if a_states[i][1] == &"loading":
			loads.append(dur)
		elif a_states[i][1] == &"trading":
			trades.append(dur)
		if order.size() < 5 and a_states[i][1] != &"waiting":
			order.append(a_states[i][1])
	_eq(order, [&"loading", &"to_post", &"trading", &"returning", &"loading"] as Array[StringName],
			"A loops load -> post -> trade -> back -> load")
	for d in loads:
		_check(absf(d - 2.0) < 0.1, "loading lasts 2 s (got %.2f)" % d)
	for d in trades:
		_check(absf(d - 2.0) < 0.1, "trading lasts 2 s (got %.2f)" % d)
	_check(not loads.is_empty() and not trades.is_empty(), "loading and trading were timed")
	_near(a_speed_stat_out, 4.0, "speed stat out")
	_near(a_speed_stat_back, 3.6, "speed stat back (loaded)")
	_check(not a_speed_back.is_empty() and a_speed_back.max() <= 3.65 and _median(a_speed_back) > 3.4,
			"walks back at 3.6 m/s (median %.2f)" % _median(a_speed_back))
	_check(not a_speed_out.is_empty() and _median(a_speed_out) > 3.8 and a_speed_out.max() <= 4.05,
			"walks out at 4.0 m/s (median %.2f)" % _median(a_speed_out))
	var kinds := {}
	for call: Array in vfx.get(&"calls"):
		kinds[call[0]] = true
	_check(kinds.has(&"post_trade") and kinds.has(&"delivery"), "TradeVfx post_trade and delivery played")


func _check_saltgate() -> void:
	_eq(b_passed, ["w_door", "nw1", "nw2", "n_door"] as Array[String], "the Saltgate route passes w_door, nw1, nw2 in order")
	var got_b := false
	for dv: Array in deliveries:
		if dv[0] == "B":
			got_b = true
			_eq(dv[1], 119, "B delivers the Saltgate value 119")
	_check(got_b, "B delivered at least once")


func _check_held() -> void:
	_check(c_wait_start >= 0.0, "C waited at se1 (the last waypoint before the held door)")
	_check(c_wait_end >= 0.0, "C stopped waiting")
	if c_wait_start >= 0.0 and c_wait_end >= 0.0:
		var waited := c_wait_end - c_wait_start
		print("  C waited %.2f s at se1" % waited)
		_check(absf(waited - 45.0) < 1.0, "C waited 45 s (got %.1f)" % waited)
		_eq(c_after, &"returning", "C goes home after the wait")
		_eq(c_after_cargo, 0, "C goes home empty")
	var c_delivered := false
	for dv: Array in deliveries:
		c_delivered = c_delivered or dv[0] == "C"
	_check(not c_delivered, "C never delivered")
	_check(e_wait_pos != Vector3.INF, "E waited on the near route")
	if e_wait_pos != Vector3.INF:
		var dd := _flat(e_wait_pos, W_DOOR)
		print("  E waits %.1f m before the door" % dd)
		_check(absf(dd - 20.0) < 3.0, "E waits ~20 m before the held door (got %.1f)" % dd)


func _check_bazaar_lost() -> void:
	_check(f_destroyed_at >= 0.0, "F's Bazaar was destroyed while it came back loaded")
	_eq(f_cargo_at_destroy, 28, "F carried 28")
	_check(f_at_keep >= 0.0, "F waited at the keep")
	_eq(f_keep_text, "Waiting: no Bazaar", "F's text at the keep")
	_eq(f_keep_cargo, 28, "F keeps its cargo at the keep")
	_check(mf2 != null, "the Bazaar was rebuilt")
	var ok := false
	for dv: Array in deliveries:
		if dv[0] == "F" and dv[3] == mf2:
			ok = true
			_eq(dv[1], 28, "F delivers its 28 to the rebuilt Bazaar")
	_check(ok, "F delivered to the rebuilt Bazaar")
	if not ok and is_instance_valid(f) and mf2 != null:
		print("  F: %s at %s, cargo %d, home %s, mf2 alive %s built %s at %s, rebuilt at t=%.1f, keep at t=%.1f" % [
				f.state_text(), f.global_position, f.cargo, f.home_market, mf2.is_alive(), mf2.is_constructed(),
				mf2.global_position, f_at_keep + 3.0, f_at_keep])
	_check(int(banks[E].get(&"gold")) >= 28, "the enemy bank got the gold")
	if is_instance_valid(f):
		_eq(f.home_market, mf2, "F's home is the rebuilt Bazaar")


func _check_move_stop() -> void:
	var ok := false
	for dv: Array in deliveries:
		if dv[0] == "G" and not ok:
			ok = true
			_eq(dv[1], 50, "G delivered the 50 it kept through Move / Stop / Hold")
	_check(ok, "G delivered after command_trade(own Bazaar)")
	if is_instance_valid(g):
		_check(g.trade_state != &"idle", "G then follows the Bazaar's route")
		_eq(g.route_post, posts[&"millstone_cross"], "G's route is the Bazaar's")


func _check_messages() -> void:
	var lines: Array = hud.get(&"lines")
	var times: Array = hud.get(&"frames")
	var held_at: Array[int] = []
	for i in lines.size():
		if str(lines[i]).ends_with("is held by the enemy: your caravans wait"):
			held_at.append(int(times[i]))
	_check(held_at.size() >= 2, "held-post message shown (and repeated later) (got %d)" % held_at.size())
	# E (Heron Ford) and C (Lantern Wharf) are held ~25 s apart: at most one line per 30 s.
	for i in range(1, held_at.size()):
		_check(held_at[i] - held_at[i - 1] >= int(30.0 * FPS), "held-post message at most once per 30 s")


# ---------------------------------------------------------------- helpers

func _wait(n: int) -> void:
	for i in n:
		await physics_frame


func _wait_until(cond: Callable, max_frames: int) -> void:
	for i in max_frames:
		if cond.call():
			return
		await physics_frame


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _flat(p: Vector3, q: Vector3) -> float:
	return Vector2(p.x - q.x, p.z - q.z).length()


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var s := values.duplicate()
	s.sort()
	return s[s.size() / 2]


func _check(cond: bool, msg: String) -> void:
	if not cond:
		errors.append(msg)
		print("  x %s" % msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	_check(got == want, "%s (got %s, want %s)" % [msg, str(got), str(want)])


func _near(got: float, want: float, msg: String) -> void:
	_check(absf(got - want) < 0.01, "%s (got %.3f, want %.3f)" % [msg, got, want])
