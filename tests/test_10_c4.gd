extends SceneTree
## Task 10.C4: ThievesGuild (docs/design/market-trade.md sections 5.1-5.2, "Done when" 10.C4).
## A small scene without a map: a stub level (match clock, base_center), a stub TradeNetwork (delivered signal,
## ambush_spots, worker_spot), two stub Dens, a stub ThiefBand; real CrystalNodes, units and buildings.
## Run:  godot --headless --path . -s tests/test_10_c4.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "10.C4"

const LEVEL_SRC := """
extends Node3D
var clock := 0.0
func match_time() -> float:
	return clock
func base_center(team: int) -> Vector3:
	return Vector3(-29.0, 0.0, 43.0) if team == 0 else Vector3(29.0, 0.0, -43.0)
"""

const NET_SRC := """
extends Node
signal delivered(team: int, caravan: Node, amount: int, post: Node)
var spots := {}    # post instance id -> {team: Array[Vector3]}
var wspots := {}   # node instance id -> Vector3
func _init() -> void:
	add_to_group("trade_network")
func ambush_spots(team: int, post: Node) -> Array:
	return spots.get(post.get_instance_id(), {}).get(team, [])
func worker_spot(node: Node) -> Vector3:
	return wspots.get(node.get_instance_id(), Vector3.INF)
"""

const DEN_SRC := """
extends Node3D
var kind := &"den"
var door := Vector3.ZERO
var bands_out := 0
func _init() -> void:
	add_to_group("guilds")
func door_point() -> Vector3:
	return door
func play_band_out() -> void:
	bands_out += 1
"""

const BAND_SRC := """
extends Node
signal finished(band)
var guild: Node
var thieves: Array = []
var target: Dictionary = {}
var spot := Vector3.ZERO
var state := &"leaving"
func setup(g: Node, t: Array, tg: Dictionary) -> void:
	guild = g
	thieves = t
	target = tg
	spot = tg.get("spot", Vector3.ZERO)
	for u in thieves:
		u.set_physics_process(false)   # no navmesh here: they just stand
func finish() -> void:
	state = &"done"
	finished.emit(self)
"""

## Road spots (market-trade.md 2.4).
const A1 := Vector3(-44, 0, 15)
const A2 := Vector3(-15, 0, 44)
const A3 := Vector3(-48, 0, -22)
const A4 := Vector3(-22, 0, -48)
const W1 := Vector3(-8, 0, 16)
const W2 := Vector3(-50, 0, -30)
const NW_DOOR := Vector3(-51, 0, -45)
const SE_DOOR := Vector3(51, 0, 45)

var errors: Array[String] = []
var _done := false
var level   # the stub level (clock, base_center)
var net     # the stub TradeNetwork
var den_nw
var den_se
var post_hf: Node3D   # Heron Ford
var post_ms: Node3D   # Millstone Cross
var post_sg: Node3D   # Saltgate
var node_home: CrystalNode
var node_mid: CrystalNode
var node_rich: CrystalNode
var band_gd: GDScript
var mtype: UnitType
var guild: ThievesGuild
var sent: Array = []
var finished: Array = []
var msgs: Array[String] = []
var extras: Array[Node] = []   # units / buildings made by a phase, freed by _clear


func _initialize() -> void:
	var ls := GDScript.new()
	ls.source_code = LEVEL_SRC
	ls.reload()
	level = Node3D.new() as Node3D
	level.set_script(ls)
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	await process_frame
	_build_world()
	await _phase_schedule()
	await _phase_weights()
	await _phase_workers()
	await _phase_spots()
	await _phase_retries()
	await _phase_sizes()
	await _phase_veterans()
	_phase_no_purchase()
	_clear()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


func _build_world() -> void:
	var ns := GDScript.new()
	ns.source_code = NET_SRC
	ns.reload()
	net = Node.new()
	net.set_script(ns)
	net.name = "TradeNetwork"
	level.add_child(net)
	var ds := GDScript.new()
	ds.source_code = DEN_SRC
	ds.reload()
	den_nw = _den(ds, Vector3(-55, 0, -45), NW_DOOR)
	den_se = _den(ds, Vector3(55, 0, 45), SE_DOOR)
	band_gd = GDScript.new()
	band_gd.source_code = BAND_SRC
	band_gd.reload()
	post_hf = _post("HeronFord", Vector3(-53, 0, 1))
	post_ms = _post("MillstoneCross", Vector3(-1, 0, 53))
	post_sg = _post("Saltgate", Vector3(1, 0, -53))
	net.spots[post_hf.get_instance_id()] = {0: [A1]}
	net.spots[post_ms.get_instance_id()] = {0: [A2], 1: [A4, A3, Vector3(15, 0, -44)]}
	net.spots[post_sg.get_instance_id()] = {0: [A4, A3, A1]}
	node_home = _node("node_fire_a", Vector3(-46, 0, 34))
	node_mid = _node("node_fire_mid", Vector3(-16, 0, 6))
	node_rich = _node("node_fire_rich", Vector3(-40, 0, -40))
	net.wspots[node_mid.get_instance_id()] = W1
	net.wspots[node_rich.get_instance_id()] = W2
	mtype = UnitType.find("magpie")
	if mtype == null:   # data/units/magpie.tres comes from 10.C6: same numbers (market-trade.md 5.1)
		mtype = UnitType.new()
		mtype.id = &"magpie"
		mtype.display_name = "Magpie"
		mtype.faction = &"neutral"
		mtype.max_hp = 140.0
		mtype.attack_damage = 9.0
		mtype.attack_range = 1.5
		mtype.move_speed = 5.2
		mtype.aggro_range = 0.0
		mtype.radius = 0.4
		mtype.kill_xp = 25


# ---------------------------------------------------------------- phases

## No band before 5:00; a band at the 5:00 tick for a road with a trip in the last 120 s; the next ticks every
## 75 s only when a target exists; the band leaves from the nearer Den with the right members.
func _phase_schedule() -> void:
	await _at(0.0)
	_new_guild()
	_check(ThievesGuild.instance(self) == guild, "instance(tree) finds the guild")
	_check(guild.dens().size() == 2, "dens() lists the two Dens")
	await _at(200.0)
	_deliver(0, 28, post_ms)
	await _at(250.0)
	await _at(299.0)
	_check(sent.is_empty() and not guild.is_open(), "no band before 5:00")
	_check(guild.targets().is_empty(), "no targets before 5:00")
	await _at(300.0)
	_check(guild.is_open(), "open at 5:00")
	_check(sent.size() == 1, "a band at the 5:00 tick (got %d)" % sent.size())
	if sent.size() == 1:
		var band = sent[0]
		var target: Dictionary = band.target
		_check(target.get("kind") == &"road" and int(target.get("team")) == 0 and target.get("post") == post_ms,
				"band target = the player's Millstone road")
		_check(band.spot.is_equal_approx(A2), "band spot = A2")
		_check(target.get("den") == den_se and den_se.bands_out == 1, "band leaves from the nearer Den (south-east)")
		_check(is_equal_approx(float(target.get("weight")), 58.0), "road weight = 28 gold + 30")
		_check(band.thieves.size() == 2, "band of 2 at 5:00 (got %d)" % band.thieves.size())
		for m: Node in band.thieves:
			var u := m as Unit
			_check(u != null and int(u.team) == Unit.Team.NEUTRAL and u.is_in_group(&"magpies"), "Magpie is NEUTRAL in group magpies")
			_check(u != null and int(u.get_meta(&"loot", -1)) == 0, "Magpie starts with loot 0")
			_check(u != null and _flat(u.global_position, SE_DOOR) <= 1.5, "Magpie spawns at the SE Den door")
			_check(u != null and not u.has_modifier(&"den:veteran") and is_equal_approx(u.max_hp, 140.0), "no veteran HP before 10:00")
		_check(band.get_parent() == guild, "the band is a child of the guild")
	_check(msgs.count("The Magpies are on the roads") == 1, "message the first time a band leaves")
	_check(guild.magpies_alive() == 2, "magpies_alive() == 2")
	await _at(340.0)
	_check(sent.size() == 1, "no band between ticks")
	await _at(375.0)   # tick: the trip at 200 is 175 s old: no target
	_check(sent.size() == 1, "no band at a tick without a target")
	_deliver(0, 15, post_hf)   # t = 375, just after the tick
	await _at(449.0)
	_check(sent.size() == 1, "still one band before the 7:30 tick")
	await _at(450.0)
	_check(sent.size() == 2, "a band at the 7:30 tick (got %d)" % sent.size())
	if sent.size() == 2:
		var band2 = sent[1]
		_check(band2.target.get("post") == post_hf and band2.spot.is_equal_approx(A1), "second band: Heron Ford at A1")
		_check(band2.target.get("den") == den_nw, "Heron Ford band leaves from the north-west Den")
		for m: Node in band2.thieves:
			_check(_flat((m as Node3D).global_position, NW_DOOR) <= 1.5, "Magpie spawns at the NW Den door")
	_check(msgs.count("The Magpies are on the roads") == 1, "the Magpies message only once")
	# A road stays a target only with a trip in the last 120 s.
	level.clock = 375.0 + 119.0
	_check(_count(guild.targets(), &"road") == 1, "road target 119 s after the trip")
	level.clock = 375.0 + 121.0
	_check(_count(guild.targets(), &"road") == 0, "no road target 121 s after the trip")
	# band_finished
	var first = sent[0]
	first.finish()
	_check(finished.has(first) and not guild.bands().has(first), "band_finished and bands() drops it")
	_check(guild.bands().size() == 1, "bands() keeps the other band")


## Road weight = gold T traded on that route in the last 180 s + 30.
func _phase_weights() -> void:
	await _at(1000.0)
	_new_guild()
	level.clock = 1000.0
	_deliver(0, 50, post_hf)
	level.clock = 1100.0
	_deliver(0, 40, post_hf)
	level.clock = 1200.0
	_deliver(0, 30, post_hf)
	_deliver(1, 20, post_ms)
	_deliver(1, 30, post_ms)
	var ts := guild.targets()
	var hf := _find(ts, 0, post_hf)
	var ms := _find(ts, 1, post_ms)
	_check(not hf.is_empty() and is_equal_approx(float(hf["weight"]), 100.0),
			"weight = 40 + 30 (the 1000 s trip is older than 180 s) + 30 (got %s)" % str(hf.get("weight")))
	_check(not ms.is_empty() and is_equal_approx(float(ms["weight"]), 80.0), "enemy road weight 20 + 30 + 30")
	_check(_count(ts, &"road") == 2, "one road target per (team, post)")
	_check(guild.gold_traded(0, post_hf) == 70, "gold_traded over 180 s")


## Worker targets start at 8:00 and need >= 2 of the team's workers within 14 m of a node > 30 m from its keep
## (never a home node); weight = 0.5 x crystals taken in the last 180 s + 20.
func _phase_workers() -> void:
	await _at(440.0)
	_new_guild()
	await _at(441.0)   # the first mining sample (baseline)
	var wt := UnitType.find("cinder_hand")
	for i in 3:
		_unit_of(wt, 0, node_home.global_position + Vector3(2 + i, 0, 0))
	_unit_of(wt, 0, node_mid.global_position + Vector3(3, 0, 0))
	_unit_of(wt, 0, node_mid.global_position + Vector3(0, 0, 13))
	_unit_of(wt, 0, node_rich.global_position + Vector3(2, 0, 0))
	_unit_of(wt, 0, node_rich.global_position + Vector3(15, 0, 0))   # beyond 14 m
	node_mid.take(40)
	await _at(452.0)   # next sample: 40 taken
	_check(_count(guild.targets(), &"workers") == 0, "no worker targets before 8:00")
	await _at(480.0)
	var ts := guild.targets()
	var mid := _find_node(ts, 0, node_mid)
	_check(_count(ts, &"workers") == 1 and not mid.is_empty(), "one worker target at 8:00: the natural node")
	_check(not mid.is_empty() and is_equal_approx(float(mid["weight"]), 40.0),
			"worker weight = 0.5 x 40 + 20 (got %s)" % str(mid.get("weight")))
	_check(not mid.is_empty() and (mid["spot"] as Vector3).is_equal_approx(W1), "worker target spot = W1")
	_check(_find_node(ts, 0, node_home).is_empty(), "never the home node (3 workers there)")
	_check(_find_node(ts, 0, node_rich).is_empty(), "rich node with 1 worker within 14 m: no target")
	var extra := _unit_of(wt, 0, node_rich.global_position + Vector3(0, 0, -3))
	_check(not _find_node(guild.targets(), 0, node_rich).is_empty(), "rich node with 2 workers: a target")
	extra.queue_free()
	await process_frame
	level.clock = 452.0 + 181.0
	mid = _find_node(guild.targets(), 0, node_mid)
	_check(not mid.is_empty() and is_equal_approx(float(mid["weight"]), 20.0), "mined crystals count 180 s only")
	_clear()


## Spot validity: 18 m units, 20 m towers, 25 m keep; only the target team counts; first valid spot of the list.
func _phase_spots() -> void:
	await _at(1500.0)
	_new_guild()
	var soldier_t := UnitType.find("flame_guard")
	_check(guild.is_spot_valid(0, A4), "empty spot is valid")
	var s := _unit_of(soldier_t, 0, A4 + Vector3(17, 0, 0))
	_check(not guild.is_spot_valid(0, A4), "player soldier at 17 m blocks")
	_check(guild.is_spot_valid(1, A4), "a player soldier does not block the enemy's spot")
	s.global_position = A4 + Vector3(19, 0, 0)
	_check(guild.is_spot_valid(0, A4), "player soldier at 19 m does not block")
	var e := _unit_of(soldier_t, 1, A4 + Vector3(2, 0, 0))
	var w := _unit_of(UnitType.find("cinder_hand"), 0, A4 + Vector3(0, 0, 3))
	_check(guild.is_spot_valid(0, A4), "enemy soldiers and own workers do not block")
	e.queue_free()
	w.queue_free()
	await process_frame
	var tower := _building("fire_tower", 0, A4 + Vector3(0, 0, 19))
	_check(not guild.is_spot_valid(0, A4), "tower at 19 m blocks")
	tower.global_position = A4 + Vector3(0, 0, 21)
	_check(guild.is_spot_valid(0, A4), "tower at 21 m does not block")
	var keep := _building("fire_keep", 0, A4 + Vector3(-24, 0, 0))
	_check(not guild.is_spot_valid(0, A4), "keep at 24 m blocks")
	keep.global_position = A4 + Vector3(-26, 0, 0)
	_check(guild.is_spot_valid(0, A4), "keep at 26 m does not block")
	# First valid spot of the route list (post end first).
	s.global_position = A4 + Vector3(5, 0, 0)
	_deliver(0, 119, post_sg)
	var sg := _find(guild.targets(), 0, post_sg)
	_check(not sg.is_empty() and (sg["spot"] as Vector3).is_equal_approx(A3), "blocked A4 -> the spot is A3")
	_check(guild.valid_spot(sg).is_equal_approx(A3), "valid_spot() agrees")
	_clear()


## None valid -> wait 20 s at the Den and retry, 3 retries, then the band goes back in.
func _phase_retries() -> void:
	await _at(2000.0)
	_new_guild()
	var blocker := _unit_of(UnitType.find("flame_guard"), 0, A1 + Vector3(3, 0, 0))
	_deliver(0, 15, post_hf)
	await _at(2000.0)   # the first frame ticks: A1 is blocked
	_check(sent.is_empty() and guild.has_waiting_band(), "blocked spot: the band waits")
	await _at(2019.0)
	await _at(2020.0)   # retry 1 fails
	_check(sent.is_empty() and guild.has_waiting_band(), "retry 1 fails, still waiting")
	blocker.queue_free()
	await process_frame
	await _at(2039.0)
	_check(sent.is_empty(), "no band between retries")
	await _at(2040.0)   # retry 2 works
	_check(sent.size() == 1 and not guild.has_waiting_band(), "retry 2 sends the band once the spot is free")
	_clear()
	await _at(3000.0)
	_new_guild()
	_unit_of(UnitType.find("flame_guard"), 0, A1 + Vector3(3, 0, 0))
	_deliver(0, 15, post_hf)
	await _at(3000.0)
	for t: float in [3020.0, 3040.0]:
		await _at(t)
		_check(guild.has_waiting_band(), "still waiting at %d" % int(t))
	await _at(3059.0)
	_check(guild.has_waiting_band(), "still waiting before the 3rd retry")
	await _at(3060.0)   # 3rd retry fails: back in
	_check(not guild.has_waiting_band() and sent.is_empty(), "after 3 retries the band goes back in (no band)")
	_clear()


## Sizes 2 / 3 (6+ caravans or 12:00) / +1 from 15:00 (max 4); never above 6 alive.
func _phase_sizes() -> void:
	await _at(300.0)
	_new_guild()
	_check(guild.band_size() == 2, "size 2 at 5:00")
	level.clock = 719.0
	_check(guild.band_size() == 2, "size 2 at 11:59")
	level.clock = 720.0
	_check(guild.band_size() == 3, "size 3 at 12:00")
	level.clock = 899.0
	_check(guild.band_size() == 3, "size 3 at 14:59")
	level.clock = 900.0
	_check(guild.band_size() == 4, "size 4 at 15:00")
	level.clock = 5000.0
	_check(guild.band_size() == 4, "size max 4")
	level.clock = 400.0
	var caravans: Array[Node3D] = []
	for i in 6:
		var c := Node3D.new()
		c.add_to_group(&"caravans")
		level.add_child(c)
		extras.append(c)
		caravans.append(c)
	_check(guild.band_size() == 3, "size 3 with 6 caravans on the map")
	caravans[0].queue_free()
	await process_frame
	_check(guild.band_size() == 2, "size 2 with 5 caravans")
	level.clock = 950.0
	_check(guild.band_size() == 4, "size 4 after 15:00 with caravans")
	_clear()
	# Cap: 5 alive -> a band of 1; 6 alive -> no band.
	await _at(1000.0)
	_new_guild()
	for i in 5:
		var m := Unit.new()
		m.team = Unit.Team.NEUTRAL
		m.add_to_group(&"magpies")
		level.add_child(m)
		m.global_position = Vector3(60 + i, 0, 60)
		m.set_physics_process(false)
		extras.append(m)
	_deliver(0, 28, post_ms)
	await _at(1000.0)
	_check(sent.size() == 1 and (sent[0].thieves as Array).size() == 1, "5 alive: the band is capped at 1")
	_check(guild.magpies_alive() == 6, "6 Magpies alive")
	_deliver(0, 28, post_ms)
	await _at(1075.0)
	_check(sent.size() == 1, "6 alive: no band at the tick")
	_clear()


## den:veteran +10 % max HP from 10:00, +20 % from 15:00, on living and new Magpies.
func _phase_veterans() -> void:
	await _at(590.0)
	_new_guild()
	_deliver(0, 28, post_ms)
	await _at(590.0)
	_check(sent.size() == 1, "a band at 9:50")
	var ms: Array = sent[0].thieves if sent.size() == 1 else []
	_check(not ms.is_empty() and is_equal_approx((ms[0] as Unit).max_hp, 140.0), "140 HP before 10:00")
	await _at(600.0)
	_check(not ms.is_empty() and (ms[0] as Unit).has_modifier(&"den:veteran")
			and is_equal_approx((ms[0] as Unit).max_hp, 154.0), "living Magpie: 154 HP at 10:00")
	_check(is_equal_approx(guild.veteran_bonus(), 0.1), "veteran_bonus 0.1")
	await _at(900.0)
	_check(not ms.is_empty() and is_equal_approx((ms[0] as Unit).max_hp, 168.0), "living Magpie: 168 HP at 15:00")
	_deliver(0, 28, post_ms)
	await _at(990.0)   # next tick after 900 is at 975
	_check(sent.size() == 2, "a band after 15:00")
	if sent.size() == 2:
		var m2: Unit = sent[1].thieves[0]
		_check(is_equal_approx(m2.max_hp, 168.0) and is_equal_approx(m2.hp, 168.0), "new Magpie: 168 HP at 15:00")
		_check((sent[1].thieves as Array).size() == 4, "band of 4 after 15:00")
	_clear()


## Q4: the Magpies are purely neutral, nobody can hire, pay or bribe them.
func _phase_no_purchase() -> void:
	var g := ThievesGuild.new()
	for m: String in ["hire", "can_hire", "hire_cost", "bribe", "pay", "pay_toll", "toll", "buy", "can_buy",
			"purchase", "hire_band", "contract_cost"]:
		_check(not g.has_method(StringName(m)), "no purchase API: %s" % m)
	g.free()


# ---------------------------------------------------------------- helpers

func _new_guild() -> void:
	_clear()
	sent.clear()
	finished.clear()
	guild = ThievesGuild.new()
	guild.name = "ThievesGuild"
	guild.magpie_type = mtype
	guild.band_script = band_gd
	guild.band_sent.connect(func(b: Node) -> void: sent.append(b))
	guild.band_finished.connect(func(b: Node) -> void: finished.append(b))
	guild.message.connect(func(t: String, _s: float) -> void: msgs.append(t))
	level.add_child(guild)


func _clear() -> void:
	if guild and is_instance_valid(guild):
		guild.free()
	guild = null
	for n in root.get_tree().get_nodes_in_group(&"magpies"):
		n.free()
	for n in extras:
		if is_instance_valid(n):
			n.free()
	extras.clear()


func _at(t: float) -> void:
	level.clock = t
	await physics_frame
	await physics_frame


func _deliver(team: int, amount: int, post: Node) -> void:
	net.delivered.emit(team, null, amount, post)


func _den(script: GDScript, pos: Vector3, door: Vector3) -> Node3D:
	var d := Node3D.new()
	d.set_script(script)
	d.set(&"door", door)
	level.add_child(d)
	d.global_position = pos
	return d


func _post(post_name: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = post_name
	level.add_child(p)
	p.global_position = pos
	return p


func _node(id: String, pos: Vector3) -> CrystalNode:
	var n := CrystalNode.new()
	n.node_id = StringName(id)
	n.crystals_left = 2000
	level.add_child(n)
	n.global_position = pos
	return n


func _unit_of(type: UnitType, team: int, pos: Vector3) -> Unit:
	var u := Worker.make_unit(type)
	u.team = team as Unit.Team
	level.add_child(u)
	u.global_position = pos
	u.set_physics_process(false)
	extras.append(u)
	return u


func _building(type_id: String, team: int, pos: Vector3) -> Building:
	var b := Building.new()
	b.building_type = BuildingType.find(type_id)
	b.team = team
	level.add_child(b)
	b.global_position = pos
	extras.append(b)
	return b


func _count(ts: Array[Dictionary], kind: StringName) -> int:
	var n := 0
	for t in ts:
		if t["kind"] == kind:
			n += 1
	return n


func _find(ts: Array[Dictionary], team: int, post: Node) -> Dictionary:
	for t in ts:
		if t["kind"] == &"road" and int(t["team"]) == team and t["post"] == post:
			return t
	return {}


func _find_node(ts: Array[Dictionary], team: int, node: Node) -> Dictionary:
	for t in ts:
		if t["kind"] == &"workers" and int(t["team"]) == team and t["node"] == node:
			return t
	return {}


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)
		print("  check failed: %s" % what)
