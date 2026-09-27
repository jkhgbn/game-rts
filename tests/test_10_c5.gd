extends SceneTree
## Task 10.C5: HuntersGuild (docs/design/market-trade.md 6.2 / 6.3, "Done when" 10.C5), in a small world with
## stubbed GoldBanks (group "gold_banks"), two stub Lodges (group "guilds", kind &"lodge"), a stub
## TradeNetwork (group "trade_network") and stub caravans (group "caravans").
## - Lodge closed before 5:00; Outriders 120 gold / 2 trackers / 180 s, Sweep 100 / 3 / 120 s.
## - Refusals in order: closed, running, cooldown, no caravans (Outriders), gold.
## - One contract per kind and team, 30 s cooldown after it ends (also when every tracker died).
## - Trackers spawn at the Lodge nearer their first destination, belong to the team, are in "trackers",
##   `is_commandable() == false` (once 10.C6's UnitType.commandable exists).
## - A Magpie kill pays 10 gold (source reward) to the killer's team (tracker kills to the hirer); the summed
##   local line `Greywater Lodge pays 20 gold for 2 Magpies`, at most once per 10 s.
## Run:  godot --headless --path . -s tests/test_10_c5.gd --fixed-fps 60 --quit-after 16000

const TASK_ID := "10.C5"
const P := 0
const E := 1
const N := 2
const NW_DOOR := Vector3(-45.0, 0.0, -51.0)
const SE_DOOR := Vector3(45.0, 0.0, 51.0)

const BANK_SRC := """extends Node
var team := 0
var gold := 0
var by_source := {}
func can_afford(n: int) -> bool:
	return gold >= n
func spend(n: int) -> bool:
	if gold < n:
		return false
	gold -= n
	return true
func add(n: int, source: StringName = &"") -> void:
	gold += n
	by_source[source] = int(by_source.get(source, 0)) + n
func earned(source: StringName = &"") -> int:
	if source == &"":
		var t := 0
		for k in by_source:
			t += int(by_source[k])
		return t
	return int(by_source.get(source, 0))
"""
const LODGE_SRC := """extends Node3D
var kind: StringName = &"lodge"
var door := Vector3.ZERO
var contracts := 0
func door_point() -> Vector3:
	return door
func play_contract() -> void:
	contracts += 1
"""
const NET_SRC := """extends Node
var remote: Array = []
var workers: Array = []
var spot := Vector3(-50.0, 0.0, -30.0)
var post_a: Node3D
var post_b: Node3D
func remote_nodes(team: int) -> Array:
	return remote if team == 0 else []
func workers_at(_team: int, _node: Node) -> Array:
	return workers
func worker_spot(_node: Node) -> Vector3:
	return spot
func posts() -> Array:
	return [post_a, post_b]
func trips(_team: int, post: Node, _seconds: float = 120.0) -> int:
	return 3 if post == post_b else 0
func ambush_spots(_team: int, post: Node) -> Array:
	if post == post_b:
		return [Vector3(2.0, 0.0, 2.0), Vector3(3.0, 0.0, 3.0)]
	return [Vector3(1.0, 0.0, 1.0), Vector3(2.0, 0.0, 2.0)]
"""


## Caravan stand-in (10.C3 builds the real one): the fields HuntersGuild reads.
class StubCaravan extends Unit:
	var cargo := 0
	var home_market: Node3D = null
	var route_post: Node3D = null

	func is_loaded() -> bool:
		return cargo > 0


var world: Node3D
var guild: HuntersGuild
var bank0: Node
var bank1: Node
var lodge_nw: Node3D
var lodge_se: Node3D
var net: Node
var mt := 200.0
var errors: Array[String] = []
var notes: Array[String] = []
var finished := false
var started: Array = []
var ended_log: Array = []
var messages: Array[String] = []
var rewards: Array = []
var frames := 0
var checks := 0


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	bank0 = _node(BANK_SRC, "GoldBank0")
	bank0.set(&"team", P)
	bank0.add_to_group(&"gold_banks")
	world.add_child(bank0)
	bank1 = _node(BANK_SRC, "GoldBank1")
	bank1.set(&"team", E)
	bank1.add_to_group(&"gold_banks")
	world.add_child(bank1)
	lodge_nw = _lodge(NW_DOOR, Vector3(-45.0, 0.0, -55.0), "LodgeNW")
	lodge_se = _lodge(SE_DOOR, Vector3(45.0, 0.0, 55.0), "LodgeSE")
	var den := _node(LODGE_SRC, "DenNW") as Node3D
	den.set(&"kind", &"den")
	den.set(&"door", Vector3(-51.0, 0.0, -45.0))
	den.add_to_group(&"guilds")
	world.add_child(den)
	guild = HuntersGuild.new()
	guild.name = "HuntersGuild"
	guild.local_team = P
	guild.match_time_source = func() -> float: return mt
	world.add_child(guild)
	guild.contract_started.connect(func(t: int, k: StringName, c: Node) -> void: started.append([t, k, c]))
	guild.contract_ended.connect(func(t: int, k: StringName) -> void: ended_log.append([t, k, frames]))
	guild.message.connect(func(text: String, _s: float) -> void: messages.append(text))
	guild.reward_paid.connect(func(t: int, a: int) -> void: rewards.append([t, a]))
	_run()


func _physics_process(_delta: float) -> bool:
	frames += 1
	return false


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	if root.get_node_or_null(^"Events") == null:
		_fail("no Events autoload at runtime")
		return
	if HuntersGuild.instance(self) != guild:
		_check(false, "HuntersGuild.instance(tree) finds the guild")
	_check(guild.lodges().size() == 2, "lodges() lists the 2 Lodges, not the Den (got %d)" % guild.lodges().size())

	# ---- closed before 5:00 (and closed beats every other reason)
	bank0.set(&"gold", 1000)
	_check(not guild.is_open(), "closed at 3:20")
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_CLOSED, "outriders before 5:00")
	_expect(guild.hire(P, &"sweep"), HuntersGuild.R_CLOSED, "sweep before 5:00")
	_check(int(bank0.get(&"gold")) == 1000, "a refused hire spends nothing")
	_expect(guild.can_hire(P, &"nope"), HuntersGuild.R_UNKNOWN, "unknown kind")
	_check(guild.contract_cost(&"outriders") == 120 and guild.contract_cost(&"sweep") == 100, "prices 120 / 100")
	_check(guild.contract_trackers(&"outriders") == 2 and guild.contract_trackers(&"sweep") == 3, "trackers 2 / 3")
	_check(is_equal_approx(guild.contract_duration(&"outriders"), 180.0)
			and is_equal_approx(guild.contract_duration(&"sweep"), 120.0), "durations 180 / 120")
	mt = 299.9
	_expect(guild.can_hire(P, &"sweep"), HuntersGuild.R_CLOSED, "still closed at 4:59.9")
	mt = 300.0
	_check(guild.is_open(), "open at 5:00")

	# ---- no caravans (Outriders only) before gold
	bank0.set(&"gold", 0)
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_NO_CARAVANS, "outriders without caravans")
	_expect(guild.can_hire(P, &"sweep"), HuntersGuild.R_GOLD, "sweep without gold")
	var caravan := _unit(StubCaravan.new(), P, Vector3(40.0, 0.0, 50.0), &"caravans")
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_GOLD, "outriders with a caravan, no gold")
	bank0.set(&"gold", 119)
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_GOLD, "outriders with 119 gold")
	bank0.set(&"gold", 1000)

	# ---- trade network stub: sweep destinations
	net = _node(NET_SRC, "TradeNetwork")
	net.add_to_group(&"trade_network")
	world.add_child(net)
	var node_rich := Node3D.new()
	world.add_child(node_rich)
	node_rich.global_position = Vector3(-40.0, 0.0, -40.0)
	var pa := Node3D.new()
	var pb := Node3D.new()
	world.add_child(pa)
	world.add_child(pb)
	net.set(&"post_a", pa)
	net.set(&"post_b", pb)
	net.set(&"remote", [node_rich])
	var w1 := Node.new()
	var w2 := Node.new()
	world.add_child(w1)
	world.add_child(w2)
	net.set(&"workers", [w1, w2])
	var spots := guild.sweep_spots(P)
	var want: Array[Vector3] = [Vector3(-50.0, 0.0, -30.0), Vector3(2.0, 0.0, 2.0), Vector3(3.0, 0.0, 3.0),
			Vector3(1.0, 0.0, 1.0)]
	_check(spots == want, "sweep_spots: W spot, busiest route, then the others, no duplicates (got %s)" % [spots])

	# ---- escort order: loaded farthest from home first, then the others
	var home := Node3D.new()
	world.add_child(home)
	home.global_position = Vector3(-45.0, 0.0, 27.0)
	var c_near := _unit(StubCaravan.new(), P, Vector3(-45.0, 0.0, 17.0), &"caravans") as StubCaravan
	var c_far := _unit(StubCaravan.new(), P, Vector3(-45.0, 0.0, -13.0), &"caravans") as StubCaravan
	for c: StubCaravan in [c_near, c_far]:
		c.cargo = 50
		c.home_market = home
	var order := guild.escort_order(P)
	_check(order.size() == 3 and order[0] == c_far and order[1] == c_near and order[2] == caravan,
			"escort_order: loaded far, loaded near, then empty")
	c_near.cargo = 0
	c_far.cargo = 0
	c_near.queue_free()
	c_far.queue_free()
	await _wait(2)

	# ---- hire Outriders: the caravan at (40, 50) is nearer the south-east Lodge
	var before_msgs := messages.size()
	_expect(guild.hire(P, &"outriders"), "", "hire outriders")
	_check(int(bank0.get(&"gold")) == 880, "outriders cost 120 (gold %d)" % int(bank0.get(&"gold")))
	var outr := _trackers(P, &"outriders")
	_check(outr.size() == 2, "outriders send 2 trackers (got %d)" % outr.size())
	for t: Node3D in outr:
		_check(_flat(t.global_position).distance_to(SE_DOOR) < 2.5, "outrider spawned at the SE Lodge door (%s)"
				% t.global_position)
		_check(int(t.get(&"team")) == P, "outrider belongs to the hiring team")
		_check_commandable(t)
	_check(int(lodge_se.get(&"contracts")) == 1 and int(lodge_nw.get(&"contracts")) == 0, "play_contract on the SE Lodge")
	_check(started.size() == 1 and int(started[0][0]) == P and StringName(started[0][1]) == &"outriders"
			and started[0][2] is Node, "contract_started(0, outriders, contract)")
	_check(messages.size() == before_msgs + 1 and messages[-1] == "Outriders hired: 2 trackers guard your caravans",
			"outriders message")
	var contract: Node = started[0][2]
	_check(contract.is_in_group(&"tracker_contracts"), "the contract is in group tracker_contracts")
	_check(guild.contract_of(P, &"outriders") == contract, "contract_of")
	# running beats cooldown / caravans / gold
	bank0.set(&"gold", 0)
	caravan.remove_from_group(&"caravans")
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_RUNNING, "second outriders while one runs")
	caravan.add_to_group(&"caravans")
	bank0.set(&"gold", 880)

	# ---- hire Sweep: the first destination is the W spot (-50, -30): north-west Lodge
	_expect(guild.hire(P, &"sweep"), "", "hire sweep")
	var sweep_frame := frames
	_check(int(bank0.get(&"gold")) == 780, "sweep cost 100")
	var sw := _trackers(P, &"sweep")
	_check(sw.size() == 3, "sweep sends 3 trackers (got %d)" % sw.size())
	for t: Node3D in sw:
		_check(_flat(t.global_position).distance_to(NW_DOOR) < 2.5, "sweep tracker spawned at the NW Lodge door (%s)"
				% t.global_position)
		_check(t.is_in_group(&"trackers") and int(t.get(&"team")) == P, "sweep tracker in 'trackers', team 0")
	_check(messages[-1] == "Sweep hired: 3 trackers clear your roads and mines", "sweep message")
	_expect(guild.hire(P, &"sweep"), HuntersGuild.R_RUNNING, "second sweep while one runs")
	_check(absf(guild.contract_time_left(P, &"outriders") - 180.0) < 0.2, "outriders time left ~180 (%.2f)"
			% guild.contract_time_left(P, &"outriders"))
	_check(absf(guild.contract_time_left(P, &"sweep") - 120.0) < 0.2, "sweep time left ~120")
	_check(guild.cooldown_left(P, &"sweep") == 0.0, "no cooldown while running")
	var type: Variant = (sw[0] as Node).get(&"unit_type")
	if type is Object and StringName(str((type as Object).get(&"id"))) == &"greywater_tracker":
		if not ResourceLoader.exists("res://data/units/greywater_tracker.tres"):
			notes.append("data/units/greywater_tracker.tres missing (10.C6): trackers use the code placeholder")
	else:
		_check(false, "trackers are greywater_tracker units")

	# ---- enemy team: Sweep, then its trackers all die -> ended early + cooldown
	bank1.set(&"gold", 500)
	var msgs_before_enemy := messages.size()
	# A contract script without the TrackerContract API -> the built-in stand-in runs the contract.
	var bad := GDScript.new()
	bad.source_code = "extends Node\n"
	bad.reload()
	guild.contract_script = bad
	_expect(guild.hire(E, &"sweep"), "", "enemy hires sweep")
	guild.contract_script = null
	_check(started[-1][2] is HuntersGuild.FallbackContract, "stand-in contract when the script has no setup()")
	if ResourceLoader.exists(HuntersGuild.TRACKER_CONTRACT_PATH):
		_check((started[0][2] as Node).get_script() == load(HuntersGuild.TRACKER_CONTRACT_PATH),
				"the real TrackerContract runs the player's contracts")
	else:
		notes.append("scripts/ai/tracker_contract.gd missing (10.A2): the stand-in contract ran everything")
	var e_sw := _trackers(E, &"sweep")
	_check(e_sw.size() == 3, "enemy sweep sends 3 trackers")
	_check(messages.size() == msgs_before_enemy, "no hire message for the enemy's contract")
	_check(int(bank1.get(&"gold")) == 400, "enemy paid 100")

	# ---- Lodge reward
	var soldier := _unit(Unit.new(), P, Vector3(0.0, 0.0, 20.0))
	var wild := _unit(Unit.new(), N, Vector3(0.0, 0.0, -20.0))
	var m1 := _magpie(Vector3(1.0, 0.0, 20.0))
	var m2 := _magpie(Vector3(-1.0, 0.0, 20.0))
	var m3 := _magpie(Vector3(3.0, 0.0, 3.0))
	var m4 := _magpie(Vector3(0.0, 0.0, -21.0))
	await _wait(2)
	var msgs_before := messages.size()
	m1.take_damage(10000.0, soldier)
	m2.take_damage(10000.0, soldier)
	m3.take_damage(10000.0, e_sw[0])
	m4.take_damage(10000.0, wild)
	await _wait(1)
	_check(int(bank0.call(&"earned", &"reward")) == 20, "2 Magpies killed by team 0 pay 20 reward gold (got %d)"
			% int(bank0.call(&"earned", &"reward")))
	_check(int(bank1.call(&"earned", &"reward")) == 10, "a Magpie killed by a team-1 tracker pays team 1 10 gold")
	_check(rewards.size() == 3, "reward_paid 3 times (a neutral kill pays nobody) (got %d)" % rewards.size())
	_check(guild.magpies_slain(P) == 2 and guild.magpies_slain(E) == 1, "magpies_slain per team")
	_check(guild.rewards_paid(P) == 20, "rewards_paid(0) == 20")
	_check(messages.size() == msgs_before, "the reward line waits to sum the burst")
	await _wait(70)
	var reward_lines := _lines_since(msgs_before, "Greywater Lodge pays")
	_check(reward_lines == ["Greywater Lodge pays 20 gold for 2 Magpies"], "summed reward line (got %s)" % [reward_lines])
	var m5 := _magpie(Vector3(2.0, 0.0, 20.0))
	await _wait(60)
	m5.take_damage(10000.0, soldier)
	await _wait(300)   # 5 s later: still inside the 10 s window
	_check(_lines_since(msgs_before, "Greywater Lodge pays").size() == 1, "at most one reward line per 10 s")
	await _wait(300)
	reward_lines = _lines_since(msgs_before, "Greywater Lodge pays")
	_check(reward_lines.size() == 2 and reward_lines[1] == "Greywater Lodge pays 10 gold for 1 Magpie",
			"second reward line after 10 s (got %s)" % [reward_lines])
	_check(int(bank0.call(&"earned", &"reward")) == 30, "third Magpie paid")

	# ---- enemy sweep trackers all die: the contract ends, cooldown 30 s
	for t: Node in e_sw:
		if is_instance_valid(t) and t.has_method(&"take_damage"):
			t.call(&"take_damage", 10000.0, soldier)
	await _wait(3)
	_check(not guild.is_running(E, &"sweep"), "enemy sweep ends when every tracker died")
	_check(_ended_count(E, &"sweep") == 1, "contract_ended(1, sweep)")
	_check(absf(guild.cooldown_left(E, &"sweep") - 30.0) < 0.2, "cooldown 30 s after the end (%.2f)"
			% guild.cooldown_left(E, &"sweep"))
	_expect(guild.can_hire(E, &"sweep"), HuntersGuild.R_COOLDOWN, "enemy sweep on cooldown")

	# ---- our Sweep ends after 120 s
	while _ended_count(P, &"sweep") == 0 and frames - sweep_frame < 130 * 60:
		await _wait(10)
	var sweep_end := _ended_frame(P, &"sweep")
	var sweep_len := float(sweep_end - sweep_frame) / 60.0
	_check(sweep_end >= 0 and sweep_len >= 119.8 and sweep_len <= 121.3, "sweep lasts 120 s (%.2f s)" % sweep_len)
	_check(not guild.is_running(P, &"sweep") and guild.contract_time_left(P, &"sweep") == 0.0, "sweep stopped")
	bank0.set(&"gold", 0)
	_expect(guild.can_hire(P, &"sweep"), HuntersGuild.R_COOLDOWN, "cooldown beats not enough gold")
	await _wait(150)
	for t: Variant in sw:
		_check(not is_instance_valid(t) or not (t as Node).is_inside_tree() or not (t as Node).is_in_group(&"units"),
				"sweep trackers left the map after the contract")
	bank0.set(&"gold", 1000)
	await _wait(roundi((guild.cooldown_left(P, &"sweep") + 0.1) * 60.0))
	_expect(guild.can_hire(P, &"sweep"), "", "sweep can be hired again after the 30 s cooldown")

	# ---- Outriders end after 180 s; then cooldown, then "No caravans to escort" before gold
	var outr_frame := sweep_frame   # hired in the same frame as the sweep (same _run step)
	while _ended_count(P, &"outriders") == 0 and frames - outr_frame < 190 * 60:
		await _wait(10)
	var outr_len := float(_ended_frame(P, &"outriders") - outr_frame) / 60.0
	_check(outr_len >= 179.8 and outr_len <= 181.3, "outriders last 180 s (%.2f s)" % outr_len)
	caravan.queue_free()
	bank0.set(&"gold", 0)
	await _wait(2)
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_COOLDOWN, "cooldown beats no caravans")
	await _wait(roundi((guild.cooldown_left(P, &"outriders") + 0.1) * 60.0))
	_expect(guild.can_hire(P, &"outriders"), HuntersGuild.R_NO_CARAVANS, "no caravans beats gold")
	_finish()


# ---------------------------------------------------------------- helpers

func _check_commandable(t: Node) -> void:
	var probe := UnitType.new()
	var unit_src := (load("res://scripts/units/unit.gd") as Script).source_code
	if &"commandable" in probe and unit_src.contains("commandable"):
		_check(t.has_method(&"is_commandable") and not bool(t.call(&"is_commandable")), "tracker is_commandable() == false")
	elif not notes.has("commandable"):
		notes.append("commandable")
		notes.append("UnitType.commandable / Unit.is_commandable reading it not there yet (10.C6): check skipped")


func _trackers(team: int, kind: StringName) -> Array:
	var out: Array = []
	for n in get_nodes_in_group(&"trackers"):
		if int(n.get(&"team")) == team and n.has_meta(&"tracker_kind") and StringName(n.get_meta(&"tracker_kind")) == kind \
				and not n.has_meta(&"tracker_leaving"):
			out.append(n)
	return out


func _ended_count(team: int, kind: StringName) -> int:
	var n := 0
	for e: Array in ended_log:
		if int(e[0]) == team and StringName(e[1]) == kind:
			n += 1
	return n


func _ended_frame(team: int, kind: StringName) -> int:
	for e: Array in ended_log:
		if int(e[0]) == team and StringName(e[1]) == kind:
			return int(e[2])
	return -1


func _lines_since(from: int, prefix: String) -> Array[String]:
	var out: Array[String] = []
	for i in range(from, messages.size()):
		if messages[i].begins_with(prefix):
			out.append(messages[i])
	return out


func _magpie(at: Vector3) -> Unit:
	return _unit(Unit.new(), N, at, &"magpies")


func _unit(u: Unit, team: int, at: Vector3, group: StringName = &"") -> Unit:
	u.team = team as Unit.Team
	if group != &"":
		u.add_to_group(group)
	world.add_child(u)
	u.global_position = at
	u.command_stop()
	return u


func _lodge(door: Vector3, at: Vector3, node_name: String) -> Node3D:
	var l := _node(LODGE_SRC, node_name) as Node3D
	l.set(&"door", door)
	l.add_to_group(&"guilds")
	l.position = at   # the world sits at the origin (not in the tree yet during _initialize)
	world.add_child(l)
	return l


func _node(src: String, node_name: String) -> Node:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var n: Node = s.new()
	n.name = node_name
	return n


func _flat(p: Vector3) -> Vector3:
	return Vector3(p.x, 0.0, p.z)


func _wait(n: int) -> void:
	for i in n:
		await physics_frame


func _expect(got: String, want: String, what: String) -> void:
	_check(got == want, "%s: expected '%s', got '%s'" % [what, want, got])


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		errors.append(what)


func _fail(reason: String) -> void:
	errors.append(reason)
	_finish()


func _finish() -> void:
	for n in notes:
		if n != "commandable":
			print("NOTE %s: %s" % [TASK_ID, n])
	print("%s: %d checks, %d frames" % [TASK_ID, checks, frames])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in errors:
			print("  - " + e)
		print("FAIL %s: %d check(s) failed" % [TASK_ID, errors.size()])
	finished = true
