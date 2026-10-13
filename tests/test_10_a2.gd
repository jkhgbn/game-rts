extends SceneTree
## Task 10.A2: TrackerContract (docs/design/market-trade.md 6.1 / 6.2, "Done when" 10.A2), in a small world with a
## navmesh. HuntersGuild, TradeNetwork and Caravan are built in parallel: the caravans are StubCaravan (a Unit with
## cargo / home_market / route_post / is_loaded), the network is StubNet (group "trade_network"), no guild.
## - Outriders: caravans picked loaded-farthest-from-home first, then longest route; never two trackers on one;
##   4 m behind a walking caravan; never beyond 15 m of it; shoot Magpies within 12 m of any own caravan (and
##   inside the leash); answer units that hit their caravan or themselves; ignore enemy soldiers that do not.
## - Sweep: spot plan = W spots with workers, busiest route's road spots, then the rest (nearest-neighbour, merged
##   duplicates); walks it in order; attacks Magpies within 15 m; chases a looter up to 30 m, a Magpie without
##   loot only 15 m; ignores enemy soldiers.
## - time_left, end_contract / timeout: trackers leave the map, `ended` once, the node frees itself; all trackers
##   dead -> ended. first_destination. Perf: 4 contracts (10 trackers), 12 caravans, 6 Magpies.
## Run:  godot --headless --path . -s tests/test_10_a2.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "10.A2"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL
const TRACKER_TRES := "res://data/units/greywater_tracker.tres"


## Caravan stand-in (10.C3 builds the real one).
class StubCaravan extends Unit:
	var cargo := 0
	var home_market: Node3D = null
	var route_post: Node3D = null

	func is_loaded() -> bool:
		return cargo > 0

	func _ready() -> void:
		super._ready()
		add_to_group(&"caravans")


## TradeNetwork stand-in (10.C1 builds the real one): only what the Sweep reads.
class StubNet extends Node:
	var nodes: Array = []
	var worker_map := {}
	var wspots := {}
	var posts_list: Array = []
	var spots_map := {}
	var trip_map := {}

	func _init() -> void:
		add_to_group(&"trade_network")

	func remote_nodes(_team: int) -> Array:
		return nodes

	func workers_at(_team: int, node: Variant) -> Array:
		return worker_map.get(node, [])

	func worker_spot(node: Variant) -> Vector3:
		return wspots.get(node, Vector3.INF)

	func posts() -> Array:
		return posts_list

	func ambush_spots(_team: int, post: Variant) -> Array:
		return spots_map.get(post, [])

	func trips(_team: int, post: Variant, _seconds: float = 120.0) -> int:
		return int(trip_map.get(post, 0))

	func route_length(m: Node3D, p: Node3D) -> float:
		return m.global_position.distance_to(p.global_position)


var world: Node3D
var errors: Array[String] = []
var notes: Array[String] = []
var finished := false
var spawned: Array = []
var stages := 0
var ended_count := 0
var tracker_type: Resource = null


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240.0, 1.0, 240.0)
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
	if ResourceLoader.exists(TRACKER_TRES):
		tracker_type = load(TRACKER_TRES)
	else:
		notes.append("no greywater_tracker.tres yet (10.C6): trackers use the stats of 6.1 set by hand")
	var probe := Unit.new()
	if not probe.has_method(&"leave_map"):
		notes.append("Unit.leave_map() missing (10.C6): the contract's fallback frees the trackers")
	probe.free()
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	await _test_outrider_picks()
	await _clear()
	await _test_follow_and_leash()
	await _clear()
	await _test_one_caravan()
	await _clear()
	await _test_outrider_fights()
	await _clear()
	await _test_sweep_plan_and_walk()
	await _clear()
	await _test_sweep_fights()
	await _clear()
	await _test_end()
	await _clear()
	await _test_perf()
	await _clear()
	_eq(stages, 8, "every stage ran to its end")
	for n in notes:
		print("NOTE %s: %s" % [TASK_ID, n])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- Outriders

func _test_outrider_picks() -> void:
	var home := _point(Vector3(0, 0, 0))
	var post_near := _point(Vector3(20, 0, 0))
	var post_far := _point(Vector3(60, 0, 0))
	var c1 := _caravan(P, Vector3(-30, 0, 10), 100, home, post_near)   # loaded, 31.6 m from home
	var c2 := _caravan(P, Vector3(10, 0, 0), 50, home, post_near)      # loaded, 10 m
	var c3 := _caravan(P, Vector3(0, 0, -20), 0, home, post_far)       # empty, route 60
	var c4 := _caravan(P, Vector3(0, 0, 20), 0, home, post_near)       # empty, route 20
	_caravan(E, Vector3(-40, 0, 10), 200, null, null)                  # enemy caravan: never picked
	var t1 := _tracker(P, Vector3(-5, 0, -5))
	var t2 := _tracker(P, Vector3(5, 0, -5))
	await _wait(2)
	_check(TrackerContract.first_destination(self, P, TrackerContract.OUTRIDERS).distance_to(c1.global_position) < 0.1,
			"first_destination(outriders) = the loaded caravan farthest from home")
	var k := _contract(P, TrackerContract.OUTRIDERS, [t1, t2], 60.0)
	await _wait(40)
	var picked := [k.charge_of(t1), k.charge_of(t2)]
	_check(picked.has(c1) and picked.has(c2), "loaded caravans first (got %s)" % _names(picked))
	_check(picked[0] != picked[1], "never both trackers on one caravan")
	_check(absf(k.time_left() - (60.0 - 42.0 / 60.0)) < 0.1, "time_left counts down (%.2f)" % k.time_left())
	_check(t1.is_in_group(&"trackers") and t1.get_meta(&"_contract", null) == k, "trackers joined group + meta")
	# c1 unloads: the empty one on the longest route (c3) replaces it, c2 keeps its tracker.
	var keeper: Node = t1 if k.charge_of(t1) == c2 else t2
	c1.cargo = 0
	await _wait(150)
	picked = [k.charge_of(t1), k.charge_of(t2)]
	_check(picked.has(c2) and picked.has(c3), "then the longest route (got %s)" % _names(picked))
	_check(k.charge_of(keeper) == c2, "a tracker keeps its caravan while it stays a top pick")
	_check(not picked.has(c4), "the short-route caravan is not picked")
	stages += 1


func _test_follow_and_leash() -> void:
	var home := _point(Vector3(-40, 0, 0))
	var c1 := _caravan(P, Vector3(-30, 0, -8), 100, home, null)
	var c2 := _caravan(P, Vector3(-30, 0, 8), 100, home, null)
	for c: Unit in [c1, c2]:
		c.move_speed = 4.0
	var t1 := _tracker(P, Vector3(-38, 0, -3))
	var t2 := _tracker(P, Vector3(-38, 0, 3))
	var k := _contract(P, TrackerContract.OUTRIDERS, [t1, t2], 60.0)
	await _wait(60)
	c1.command_move(Vector3(30, 0, -8))
	c2.command_move(Vector3(30, 0, 8))
	var samples := 0
	var behind := 0
	var dist_sum := 0.0
	var max_d := 0.0
	var caught := {}
	for f in 780:   # 13 s of walking
		await _wait(1)
		for t: Unit in [t1, t2]:
			var c := k.charge_of(t) as Unit
			if c == null:
				continue
			var d := _flat(t.global_position, c.global_position)
			if d < 6.0:
				caught[t] = true
			if not caught.has(t):
				continue
			max_d = maxf(max_d, d)
			var v := Vector3(c.velocity.x, 0, c.velocity.z)
			if f > 120 and v.length() > 1.0:
				samples += 1
				dist_sum += d
				if v.normalized().dot((t.global_position - c.global_position).normalized()) < -0.7:
					behind += 1
	_check(caught.size() == 2, "both trackers reach their caravans")
	_check(k.charge_of(t1) != k.charge_of(t2), "one tracker per caravan")
	_check(samples > 200, "enough walking samples (%d)" % samples)
	if samples > 0:
		var avg := dist_sum / float(samples)
		_check(avg > 3.0 and avg < 5.5, "trackers stay ~4 m from their caravan (avg %.2f)" % avg)
		_check(float(behind) / float(samples) > 0.85, "trackers stay behind the caravan (%d / %d)" % [behind, samples])
	_check(max_d <= 15.0, "never beyond 15 m of the caravan (max %.2f)" % max_d)
	stages += 1


func _test_one_caravan() -> void:
	var c := _caravan(P, Vector3(0, 0, 0), 100, _point(Vector3(-20, 0, 0)), null)
	var t1 := _tracker(P, Vector3(-4, 0, 4))
	var t2 := _tracker(P, Vector3(4, 0, 4))
	var k := _contract(P, TrackerContract.OUTRIDERS, [t1, t2], 60.0)
	await _wait(40)
	var n := 0
	for t in [t1, t2]:
		if k.charge_of(t) == c:
			n += 1
	_eq(n, 1, "one caravan, two trackers: only one shadows it")
	_check(k.status_text(t1) != "" and k.display_name() == "Outriders", "status text / name")
	stages += 1


func _test_outrider_fights() -> void:
	var home := _point(Vector3(-50, 0, 0))
	var ca := _caravan(P, Vector3(0, 0, 0), 100, home, null)    # farther from home: first pick
	var cb := _caravan(P, Vector3(-30, 0, 0), 100, home, null)
	var t1 := _tracker(P, Vector3(0, 0, -4))
	var t2 := _tracker(P, Vector3(-30, 0, -4))
	var k := _contract(P, TrackerContract.OUTRIDERS, [t1, t2], 120.0)
	await _wait(40)
	_check(k.charge_of(t1) == ca and k.charge_of(t2) == cb, "nearest free tracker takes each caravan")
	# A Magpie 14 m from both caravans (outside 12) but inside t1's leash: ignored. One 9 m from ca: shot by t1
	# only (t2's caravan is 30 m away).
	var far_m := _magpie(Vector3(14, 0, 0), 5000.0, 0)
	var m := _magpie(Vector3(0, 0, 9), 36.0, 0)
	var max_d := 0.0
	var t1_hit_far := false
	var t2_on_m := false
	var killed_at := -1
	for f in 600:
		await _wait(1)
		max_d = maxf(max_d, _flat(t1.global_position, ca.global_position))
		max_d = maxf(max_d, _flat(t2.global_position, cb.global_position))
		if t1.attack_target == far_m or t2.attack_target == far_m:
			t1_hit_far = true
		if is_instance_valid(m) and t2.attack_target == m:
			t2_on_m = true
		if killed_at < 0 and (not is_instance_valid(m) or not m.is_alive()):
			killed_at = f
			break
	_check(killed_at >= 0, "the Magpie within 12 m of a caravan is shot dead (frame %d)" % killed_at)
	_check(not t1_hit_far, "a Magpie 14 m from every caravan is ignored")
	_check(not t2_on_m, "the other tracker does not leave its caravan's leash for it")
	# The Magpie near cb (another caravan) and inside t1's leash? place one 10 m from cb, 20 m from ca: only t2.
	var m2 := _magpie(Vector3(-30, 0, 10), 5000.0, 0)
	await _wait(60)
	_check(t2.attack_target == m2, "t2 shoots a Magpie near its caravan")
	_check(t1.attack_target != m2, "t1 ignores a Magpie outside its leash")
	_kill(m2)
	_kill(far_m)
	await _wait(40)
	# An idle enemy soldier 5 m from t1 is ignored; once it hits the caravan it is answered.
	var s := _soldier(E, Vector3(5, 0, -4), 2000.0, 4.0, 1.6)
	await _wait(180)
	_check(t1.attack_target != s and t2.attack_target != s, "trackers ignore an enemy soldier that does not attack")
	s.command_attack(ca)
	var answered := false
	for f in 240:
		await _wait(1)
		max_d = maxf(max_d, _flat(t1.global_position, ca.global_position))
		if t1.attack_target == s:
			answered = true
			break
	_check(answered, "t1 answers the soldier that hit its caravan")
	# The attacker of a tracker itself is answered too.
	var s2 := _soldier(E, cb.global_position + Vector3(4, 0, -6), 2000.0, 4.0, 1.6)
	await _wait(10)
	s2.command_attack(t2)
	answered = false
	for f in 240:
		await _wait(1)
		max_d = maxf(max_d, _flat(t2.global_position, cb.global_position))
		if t2.attack_target == s2:
			answered = true
			break
	_check(answered, "t2 answers the soldier that hit it")
	# A ranged attacker 19 m from the caravan: t1 goes for it but never leaves its 15 m leash.
	_kill(s)
	_kill(s2)
	var archer := _soldier(E, Vector3(0, 0, -19), 5000.0, 2.0, 18.0)
	await _wait(10)
	archer.command_attack(ca)
	var engaged := false
	for f in 420:
		await _wait(1)
		max_d = maxf(max_d, _flat(t1.global_position, ca.global_position))
		if t1.attack_target == archer:
			engaged = true
	_check(engaged, "t1 engages a ranged attacker of its caravan")
	_check(max_d <= 15.0, "fighting outriders never go beyond 15 m of their caravan (max %.2f)" % max_d)
	stages += 1


# ---------------------------------------------------------------- Sweep

func _sweep_net() -> StubNet:
	var net := StubNet.new()
	world.add_child(net)
	spawned.append(net)
	var n1 := _point(Vector3(12, 0, 12))
	var n2 := _point(Vector3(-34, 0, -34))
	net.nodes = [n1, n2]
	net.worker_map = {n1: [1, 2]}
	net.wspots = {n1: Vector3(10, 0, 10), n2: Vector3(-30, 0, -30)}
	var p1 := _point(Vector3(50, 0, 0))
	var p2 := _point(Vector3(0, 0, 50))
	net.posts_list = [p1, p2]
	net.spots_map = {p1: [Vector3(40, 0, 0), Vector3(30, 0, 0), Vector3(1, 0, 30)], p2: [Vector3(0, 0, 40), Vector3(0, 0, 30)]}
	net.trip_map = {p1: 1, p2: 3}
	return net


func _test_sweep_plan_and_walk() -> void:
	_sweep_net()
	await _wait(2)
	var expect: Array[Vector3] = [Vector3(10, 0, 10), Vector3(0, 0, 30), Vector3(0, 0, 40), Vector3(30, 0, 0),
			Vector3(40, 0, 0), Vector3(-30, 0, -30)]
	_check(TrackerContract.first_destination(self, P, TrackerContract.SWEEP).distance_to(expect[0]) < 0.1,
			"first_destination(sweep) = the W spot with workers")
	var ts: Array = []
	for i in 3:
		ts.append(_tracker(P, Vector3(i - 1.0, 0, 0)))
	var k := _contract(P, TrackerContract.SWEEP, ts, 120.0)
	await _wait(40)
	var plan := k.planned_spots()
	var same := plan.size() == expect.size()
	if same:
		for i in plan.size():
			if plan[i].distance_to(expect[i]) > 0.1:
				same = false
	_check(same, "spot order: W with workers, busiest road, then the rest, duplicates merged (got %s)" % str(plan))
	# Walk: spot 0 reached by all three, then spot 1.
	var reached := {}
	for f in 1500:
		await _wait(1)
		var idx := k.current_spot_index()
		if idx >= plan.size():
			break
		var all_near := true
		for t: Unit in ts:
			if _flat(t.global_position, plan[idx]) > 4.5:
				all_near = false
		if all_near:
			reached[idx] = true
		if reached.has(1):
			break
	_check(reached.has(0) and reached.has(1), "the sweep walks spot 0 then spot 1 (reached %s)" % str(reached.keys()))
	_check(k.status_text(ts[0]).begins_with("Sweeping"), "sweep status text (%s)" % k.status_text(ts[0]))
	stages += 1


func _test_sweep_fights() -> void:
	# No network: the trackers hold where they are and only fight.
	var ts: Array = []
	for i in 3:
		ts.append(_tracker(P, Vector3(i * 2.0 - 2.0, 0, 0)))
	var k := _contract(P, TrackerContract.SWEEP, ts, 120.0)
	var soldier := _soldier(E, Vector3(0, 0, 6), 2000.0, 0.0, 1.6)
	await _wait(120)
	var on_soldier := false
	for t: Unit in ts:
		if t.attack_target == soldier:
			on_soldier = true
	_check(not on_soldier, "sweepers ignore an enemy soldier that does not attack")
	_kill(soldier)
	# A looter 10 m away: engaged; moved to 22 m from where the fight began: still chased; 34 m: dropped.
	var looter := _magpie(Vector3(10, 0, 0), 50000.0, 40)
	await _wait(40)
	_check(_any_on(ts, looter), "a Magpie within 15 m is attacked")
	_teleport(looter, Vector3(22, 0, 0))
	await _wait(40)
	_check(_any_on(ts, looter), "a looter 22 m from the fight's start is still chased")
	_teleport(looter, Vector3(34, 0, 0))
	await _wait(40)
	_check(not _any_on(ts, looter), "a looter beyond 30 m is let go")
	_kill(looter)
	await _wait(40)
	# A Magpie without loot: engaged at 10 m, let go at 20 m from the start.
	var ts_center := Vector3.ZERO
	for t: Unit in ts:
		ts_center += t.global_position / 3.0
	var plain := _magpie(ts_center + Vector3(0, 0, 10), 50000.0, 0)
	await _wait(40)
	_check(_any_on(ts, plain), "a Magpie without loot within 15 m is attacked")
	_teleport(plain, ts_center + Vector3(0, 0, 21))
	await _wait(40)
	_check(not _any_on(ts, plain), "a Magpie without loot is not chased past 15 m")
	_kill(plain)
	_check(k.planned_spots().is_empty(), "no network: no spots")
	stages += 1


# ---------------------------------------------------------------- end

func _test_end() -> void:
	var t1 := _tracker(P, Vector3(0, 0, 0))
	var t2 := _tracker(P, Vector3(3, 0, 0))
	var k := _contract(P, TrackerContract.SWEEP, [t1, t2], 2.0)
	ended_count = 0
	k.ended.connect(func(_c: Node) -> void: ended_count += 1)
	await _wait(115)
	_eq(ended_count, 0, "not ended before its duration")
	await _wait(15)
	_eq(ended_count, 1, "ended emitted once at the end of the duration")
	await _wait(3)
	_check(not is_instance_valid(k), "the contract frees itself")
	await _wait(90)
	for t in [t1, t2]:
		var gone: bool = not is_instance_valid(t) or not (t as Node).is_in_group(&"units") \
				or not (t as Node).is_inside_tree() or not (t as Node3D).visible
		_check(gone, "a tracker leaves the map at the contract end")
	# end_contract() by hand, twice: one signal.
	var t3 := _tracker(P, Vector3(0, 0, 5))
	var k2 := _contract(P, TrackerContract.OUTRIDERS, [t3], 60.0)
	ended_count = 0
	k2.ended.connect(func(_c: Node) -> void: ended_count += 1)
	await _wait(5)
	k2.end_contract()
	k2.end_contract()
	_eq(ended_count, 1, "end_contract twice emits ended once")
	# All trackers dead: the contract ends.
	var t4 := _tracker(P, Vector3(0, 0, 8))
	var k3 := _contract(P, TrackerContract.OUTRIDERS, [t4], 60.0)
	ended_count = 0
	k3.ended.connect(func(_c: Node) -> void: ended_count += 1)
	await _wait(5)
	t4.take_damage(10000.0, null)
	await _wait(40)
	_eq(ended_count, 1, "a contract whose trackers all died ends")
	stages += 1


# ---------------------------------------------------------------- perf

func _test_perf() -> void:
	_sweep_net()
	var homes := [_point(Vector3(-40, 0, 40)), _point(Vector3(40, 0, -40))]
	var caravans: Array = []
	for team in [P, E]:
		for i in 6:
			var sg := -1.0 if team == P else 1.0
			var c := _caravan(team, Vector3(sg * (30.0 - 4.0 * i), 0, sg * (20.0 + 3.0 * i)), 50 * (i % 2), homes[team], null)
			c.move_speed = 4.0
			caravans.append(c)
	for i in 6:
		_magpie(Vector3(-20.0 + 8.0 * i, 0, 0), 50000.0, 10 * (i % 2))
	var contracts: Array = []
	for team in [P, E]:
		var sg := -1.0 if team == P else 1.0
		var o: Array = [_tracker(team, Vector3(sg * 35, 0, sg * 25)), _tracker(team, Vector3(sg * 34, 0, sg * 26))]
		contracts.append(_contract(team, TrackerContract.OUTRIDERS, o, 120.0))
		var s: Array = []
		for i in 3:
			s.append(_tracker(team, Vector3(sg * 10 + i, 0, sg * 10)))
		contracts.append(_contract(team, TrackerContract.SWEEP, s, 120.0))
	await _wait(10)
	for c: Unit in caravans:
		c.command_move(-c.global_position)
	var u0 := TrackerContract.usec_total
	var n0 := TrackerContract.ticks
	var frames := 600
	await _wait(frames)
	var usec := TrackerContract.usec_total - u0
	var n := TrackerContract.ticks - n0
	var per_frame := float(usec) / float(frames)
	var per_tick := float(usec) / float(maxi(1, n))
	print("PERF %s: %d ticks, %.1f us per tick, %.1f us per frame (4 contracts, 10 trackers, 12 caravans, 6 Magpies)"
			% [TASK_ID, n, per_tick, per_frame])
	_check(n >= 4 * 2 * 9, "every contract ticks at 2 Hz (%d ticks)" % n)
	_check(per_frame < 60.0, "tracker brains cost < 0.06 ms per frame (%.1f us)" % per_frame)
	stages += 1


# ---------------------------------------------------------------- helpers

func _contract(team: int, kind: StringName, ts: Array, dur: float) -> TrackerContract:
	var k := TrackerContract.new()
	k.setup(null, team, kind, ts, dur)
	world.add_child(k)
	spawned.append(k)
	return k


func _tracker(team: int, pos: Vector3) -> Unit:
	var u := Unit.new()
	if tracker_type != null and tracker_type is UnitType:
		u.apply_type(tracker_type as UnitType)
	else:
		u.unit_name = "Greywater Tracker"
		u.max_hp = 240.0
		u.attack_damage = 12.0
		u.attack_range = 7.0
		u.attack_cooldown = 1.2
		u.move_speed = 5.4
		u.radius = 0.45
		u.body_height = 1.8
	u.aggro_range = 0.0
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _caravan(team: int, pos: Vector3, cargo: int, home: Node3D, post: Node3D) -> StubCaravan:
	var c := StubCaravan.new()
	c.team = team
	c.unit_name = "Caravan"
	c.max_hp = 50000.0
	c.attack_damage = 0.0
	c.aggro_range = 0.0
	c.move_speed = 4.0
	c.radius = 0.8
	c.cargo = cargo
	c.home_market = home
	c.route_post = post
	world.add_child(c)
	c.global_position = pos
	c.command_stop()
	spawned.append(c)
	return c


func _magpie(pos: Vector3, hp: float, loot: int) -> Unit:
	var m := Unit.new()
	m.team = N
	m.unit_name = "Magpie"
	m.max_hp = hp
	m.attack_damage = 0.0
	m.aggro_range = 0.0
	m.move_speed = 5.2
	m.add_to_group(&"magpies")
	m.set_meta(&"loot", loot)
	world.add_child(m)
	m.global_position = pos
	m.command_stop()
	spawned.append(m)
	return m


func _soldier(team: int, pos: Vector3, hp: float, dmg: float, rng: float) -> Unit:
	var s := Unit.new()
	s.team = team
	s.max_hp = hp
	s.attack_damage = dmg
	s.attack_range = rng
	s.aggro_range = 0.0
	world.add_child(s)
	s.global_position = pos
	s.command_stop()
	spawned.append(s)
	return s


func _point(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	world.add_child(n)
	n.global_position = pos
	spawned.append(n)
	return n


func _teleport(u: Unit, pos: Vector3) -> void:
	u.global_position = pos
	u.command_stop()


func _kill(u: Variant) -> void:
	if u != null and is_instance_valid(u) and (u as Unit).is_alive():
		(u as Unit).take_damage(1.0e9, null)


func _any_on(ts: Array, target: Node) -> bool:
	for t: Variant in ts:
		if is_instance_valid(t) and (t as Unit).attack_target == target:
			return true
	return false


func _names(arr: Array) -> String:
	var out: Array[String] = []
	for n: Variant in arr:
		out.append("null" if n == null else "(%.0f, %.0f)" % [(n as Node3D).global_position.x, (n as Node3D).global_position.z])
	return ", ".join(out)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n) and n is TrackerContract:
			(n as TrackerContract).enabled = false
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile:
			n.queue_free()
	await _wait(3)


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	if got != want:
		errors.append("%s (got %s, want %s)" % [what, str(got), str(want)])
