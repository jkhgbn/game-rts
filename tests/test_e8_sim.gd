extends SceneTree
## Episode 8 timing checks (docs/design/mission-e8-01.md 10, mission-e8-02.md 12, mission-e8-03.md 11): a scripted
## headless run on normal of one Episode 8 mission ends `victory=true` inside the spec's target (cutscenes counted at
## their .cine length). `-- --mission e8m1_fire|e8m1_shadow|e8m1_ice|e8m1_nature|e8m2|e8m3` (the thin wrappers
## tests/test_e8m*_sim.gd set it), `-- --road <k>` (e8m2 / e8m3: the player's kingdom, default fire), `-- --passive`
## (the scripted player does nothing: the mission must not win by itself), `-- --seed N`, `-- --verbose`.
## Real fights, cinematics off. Slow. Run: godot --headless --path . -s tests/test_e8_sim.gd --fixed-fps 60
## --quit-after 150000 -- --mission e8m1_fire

const SCENES := {"e8m1_fire": "res://missions/mission_e8_01_fire.tscn", "e8m1_shadow": "res://missions/mission_e8_01_shadow.tscn",
		"e8m1_ice": "res://missions/mission_e8_01_ice.tscn", "e8m1_nature": "res://missions/mission_e8_01_nature.tscn",
		"e8m2": "res://missions/mission_e8_02.tscn", "e8m3": "res://missions/mission_e8_03.tscn"}
## [min, max] play time in seconds (cutscenes included) and the cutscene seconds added to the mission clock.
const TARGET := {"e8m1_fire": [1080.0, 1320.0, 65.0], "e8m1_shadow": [1080.0, 1320.0, 80.0], "e8m1_ice": [1080.0, 1320.0, 50.0],
		"e8m1_nature": [1080.0, 1320.0, 45.0], "e8m2": [1500.0, 1800.0, 75.0], "e8m3": [1680.0, 2100.0, 60.0]}
const PASSIVE_LIMIT := {"e8m1_fire": 1500.0, "e8m1_shadow": 1500.0, "e8m1_ice": 1500.0, "e8m1_nature": 1500.0,
		"e8m2": 1900.0, "e8m3": 2200.0}
const HALL_MIX := {&"fire": ["flame_guard", "ember_archer", "pyre_adept", "flame_guard", "ember_archer", "blaze_rider"],
		&"shadow": ["shade", "nightbolt", "hexweaver", "shade", "shadow_knight", "nightbolt"],
		&"ice": ["rimeshield", "shardcaster", "frost_mortar", "rimeshield", "shardcaster", "rime_seer"],
		&"nature": ["thornling", "wildwood_archer", "bloomtender", "thornling", "wildwood_archer", "vinelasher"]}

var mission := "e8m1_fire"
var road: StringName = &"fire"
var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE8Base
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _houses := 0
var _phase := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	passive = passive or args.has("--passive")
	var i := args.find("--mission")
	if i >= 0 and i + 1 < args.size():
		mission = args[i + 1]
	i = args.find("--road")
	if i >= 0 and i + 1 < args.size():
		road = StringName(args[i + 1])
	i = args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	if mission.begins_with("e8m1_"):
		road = StringName(mission.substr(5))
	MissionE8Base.forced_road = road
	h.task_id = "%s_sim%s" % [mission, "_passive" if passive else ""]
	h.protect_hero = false
	h.timeout_frames = 148000
	main = h.open(self, SCENES[mission], {"difficulty": 1, "set": {"campaign_save_path": "user://test_e8_sim_none.json"}}) as MissionE8Base
	h.steps.add("play", _play, 147000)


func _process(_delta: float) -> bool:
	return h.tick()


func _report(t: float) -> void:
	var cine := float(TARGET[mission][2])
	print("  %s %s at mission time %s (play time with cutscenes %s); waves %s" % [mission,
			"victory" if h.ended == 1 else ("defeat" if h.ended == 0 else "no end"), MissionE5Base.mmss(t),
			MissionE5Base.mmss(t + cine), ",".join(main.get(&"waves_fired") if main.get(&"waves_fired") != null else [])])
	print("  objectives %s" % str(h.objective_log))
	print("  said %s" % str(main.said))
	print("  state %s" % _state())


func _state() -> String:
	var m := main
	match mission:
		"e8m1_fire":
			return "hunger peak %d storm strikes %d scouts %d" % [int(m.get(&"hunger_peak")), int(m.get(&"storm_strikes")), int(m.get(&"scouts_home"))]
		"e8m1_shadow":
			return "laid %s stone uses %d hush %d" % [str(m.get(&"laid")), int(m.get(&"stone_uses")), int(m.get(&"hush_state"))]
		"e8m1_ice":
			var hd: Unit = m.call(&"_head")
			return "saved %d lost %d wp %d gate %s stop %s head %s" % [int(m.get(&"saved")), int(m.get(&"lost")), int(m.get(&"col_wp")), str(m.get(&"gate_open")),
					str(m.get(&"column_stopped")), str(hd.global_position) if hd else "-"]
		"e8m1_nature":
			return "knots %d hamlets %s saved %d crossed %s" % [int(m.get(&"knots_open")), str(m.get(&"hamlet_state")), int(m.get(&"hamlets_saved")),
					MissionE5Base.mmss(float(m.get(&"crossed_at")))]
		"e8m2":
			var mk := MissionE8Muster.keyhole_of(0)
			var hn: Array = (m as MissionE8Base).host_near(mk, 8.0)
			return "key %.1f near %d %s lit %s muster %s hollow %d help %s" % [float(m.get(&"key_progress")), hn.size(),
					str(hn[0].unit_type.id) + str(hn[0].global_position) if not hn.is_empty() else "", str((m.get(&"lit") as Dictionary).keys()), str(m.get(&"muster")), int(m.get(&"hollow_peak")),
					str(m.get(&"help_kills"))]
		"e8m3":
			return "phase %d king %d turns %d wards %s fed %d" % [int(m.get(&"phase")), int((m.get(&"king") as Unit).hp) if m.get(&"king") else -1,
					int(m.get(&"turns")), str(m.get(&"ward")), int(m.get(&"fed"))]
	return ""


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	var t := m.mission_time()
	if passive and h.ended < 0 and t >= float(PASSIVE_LIMIT[mission]):
		_report(t)
		return true
	if h.ended >= 0:
		_report(t)
		if passive:
			h.check(h.ended != 1, "a passive run won (%s)" % MissionE5Base.mmss(t))
			return true
		var play := t + float(TARGET[mission][2])
		h.check(h.ended == 1, "defeat at %s (%s)" % [MissionE5Base.mmss(t), _phase])
		h.check(play >= float(TARGET[mission][0]) and play <= float(TARGET[mission][1]),
				"play time %s outside %s-%s" % [MissionE5Base.mmss(play), MissionE5Base.mmss(TARGET[mission][0]), MissionE5Base.mmss(TARGET[mission][1])])
		return true
	if passive:
		return false
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(t / 30.0) != _last_print:
		_last_print = int(t / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s hero %3.0f L%d | army %2d | crystals %4d | %s" % [MissionE5Base.mmss(t), _phase, m.hero.hp, m.hero.level,
				_soldiers().size(), eco.crystals if eco else -1, _state()])
	_economy()
	_spells()
	match mission:
		"e8m1_fire":
			_plan_fire()
		"e8m1_shadow":
			_plan_shadow()
		"e8m1_ice":
			_plan_ice()
		"e8m1_nature":
			_plan_nature()
		"e8m2":
			_plan_muster()
		"e8m3":
			_plan_king()
	return false


# ---------------------------------------------------------------- shared

func _soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u.is_in_group(&"helpers"):
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _foes(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not main.is_dormant(u) \
				and StringName(u.get_meta(Unit.TRUCE_META, &"")) != Unit.TRUCE_ALL \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var tt := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(tt, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(tt, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	_sites = _sites.filter(func(r: Array) -> bool: return is_instance_valid(r[0]) and (r[0] as Building).is_alive() \
			and not (r[0] as Building).is_constructed())
	var busy: Array = []
	for r: Array in _sites:
		var wu := r[1] as Unit
		if wu == null or not is_instance_valid(wu) or not wu.is_alive():
			continue
		busy.append(wu)
		if not bool(wu.call(&"is_building")) and not wu.has_move_order():
			wu.call(&"command_build", r[0])
	for w in workers:
		if busy.has(w):
			continue
		var tn: Variant = w.get(&"gather_node")
		if not w.call(&"is_building") and (tn == null or not is_instance_valid(tn) or (tn as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			for s in ["a", "b", "mid"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not is_instance_valid(k) or not k.is_alive() or eco == null:
		return
	if k.tier < 3 and k.can_upgrade() == "" and not k.is_upgrading() and eco.crystals >= 300:
		k.upgrade()
		return
	var roster := HelperRoster.for_team(0)
	if k.tier >= 3 and roster and roster.can_call() == "" and eco.crystals >= 250:
		roster.call_helper()
		return
	var kd: Dictionary = MissionE8Base.BUILD_OF[m.road]
	if workers.size() < 9 and k.queue.size() < 1 and eco.crystals >= 50:
		k.queue_unit(UnitType.find(String(kd["worker"])))
		var node: CrystalNode = m.node_of(0, "a")
		if node:
			k.set_rally_node(node)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and eco.pop_cap - eco.pop_used < 8 and eco.pop_cap < 120 and _sites.is_empty() and eco.crystals >= 100:
		var base := m.base_center(0)
		if _build(String(kd["house"]), base.lerp(Vector3.ZERO, 0.2) + Vector3(5.0 * (_houses % 3), 0.0, -5.0 * (_houses / 3)), free_w):
			_houses += 1
		return
	if k.tier < 3 and m.mission_time() > 280.0 and eco.crystals < 360 and not k.is_upgrading():
		return   # save for the Citadel
	var mix: Array = HALL_MIX[m.road]
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != StringName(String(kd["hall"])) \
				or hall.queue.size() >= 2 or eco.crystals < 120:
			continue
		hall.queue_unit(UnitType.find(String(mix[_train_i % mix.size()])))
		_train_i += 1
		hall.set_rally_point(_home())


func _home() -> Vector3:
	return main.base_center(0).lerp(Vector3.ZERO, 0.3)


func _spells() -> void:
	var w := main.hero as Wizard
	var ids: Array = MissionE8Base.SPELLS_OF[main.road]
	if w.spell_points > 0:
		for id: StringName in [ids[0], ids[1], ids[2], ids[0], ids[0]]:
			if w.learn_spell(id) == "":
				break
	var foes := _foes(w.global_position, 12.0)
	if foes.is_empty():
		return
	if foes.size() >= 4 and w.command_cast(ids[1], foes[0].global_position) == "":
		return
	w.command_cast(ids[0], foes[0])


## Sends `army` at `at`: fight what is within `r`, else gather there.
func _go(army: Array, at: Vector3, r: float) -> bool:
	var foes := _foes(at, r)
	for v: Variant in army:
		var u := v as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, at) > 6.0:
			u.command_attack_move(at)
	return foes.is_empty()


func _hero_to(at: Vector3) -> void:
	var m := main
	if m.hero.hp < m.hero.max_hp * 0.3:
		at = m.base_center(0).lerp(Vector3.ZERO, 0.15)
	if MissionBase._flat(m.hero.global_position, at) > 1.2:
		m.hero.command_move(at)


func _defend_base(army: Array) -> bool:
	var base := main.base_center(0)
	if not _foes(base, 22.0).is_empty():
		_go(army, base, 26.0)
		return true
	return false


func _attack_structure(army: Array, target: Node3D) -> void:
	for v: Variant in army:
		var u := v as Unit
		if u.attack_target == null or not is_instance_valid(u.attack_target):
			if not _foes(u.global_position, 7.0).is_empty():
				u.command_attack(_foes(u.global_position, 7.0)[0])
			else:
				u.command_attack(target)


# ---------------------------------------------------------------- per mission

func _plan_fire() -> void:
	var m := main
	var army := _soldiers()
	if _defend_base(army):
		_phase = "base"
		return
	_phase = "line"
	var def := Vector3(-10.0, 0.0, 18.0)
	var foes := _foes(def, 22.0).filter(func(u: Unit) -> bool: return MissionE8_01Fire.west_bank(u.global_position))
	if not foes.is_empty():
		_go(army, foes[0].global_position, 8.0)
	else:
		_go(army, def, 4.0)
	_hero_to(def + Vector3(-8.0, 0.0, 8.0))


func _plan_shadow() -> void:
	var m := main as MissionE8_01Shadow
	var army := _soldiers()
	if _defend_base(army):
		_phase = "base"
		return
	var target := Vector3.INF
	for id: StringName in [&"bd1", &"bd2", &"bd3"]:
		if not m.laid.has(String(id)):
			target = MissionE8_01Shadow.DOORS[id]
			break
	if target != Vector3.INF:
		_phase = "door"
		var clear := _go(army, target, 12.0)
		_hero_to(target if clear else target + (m.base_center(0) - target).normalized() * 8.0)
		return
	if m.stair and m.stair.is_alive():
		_phase = "stair"
		if m.stair.is_open:
			_attack_structure(army, m.stair)
		else:
			_go(army, MissionE8_01Shadow.STAIR_GATE + Vector3(-10.0, 0.0, 10.0), 14.0)
		_hero_to(MissionE8_01Shadow.STAIR_GATE + Vector3(-14.0, 0.0, 14.0))
		return
	if m.hush_state < 2:
		_phase = "hush"
		_go(army, MissionE8_01Shadow.GARRISON, 18.0)
		_hero_to(MissionE8_01Shadow.STAIR_GATE + Vector3(-6.0, 0.0, 6.0))
		return
	_phase = "exit"
	_go(army, MissionE8_01Shadow.EXIT, 12.0)
	_hero_to(MissionE8_01Shadow.EXIT)


func _plan_ice() -> void:
	var m := main as MissionE8_01Ice
	var army := _soldiers()
	if (m.alive_refugees().is_empty() or not _foes(m.base_center(0), 14.0).is_empty()) and _defend_base(army):
		_phase = "base"
		return
	var t := m.mission_time()
	if not m.gate_open and t >= 150.0 and not m.has_fired(&"E2"):
		_phase = "lever"
		_go(army, MissionE8_01Ice.GATE + Vector3(0.0, 0.0, 6.0), 14.0)
		_hero_to(MissionE8_01Ice.LEVER)
		return
	var head: Unit = m.call(&"_head")
	var at := MissionE8_01Ice.GATE + Vector3(-6.0, 0.0, 4.0)
	var tail: Unit = null
	for v: Variant in m.alive_refugees():
		tail = v as Unit
	if head != null and head.global_position.z > MissionE8_01Ice.GATE.z and not _foes(head.global_position, 24.0).is_empty():
		_phase = "clear"
		_go(army, head.global_position, 24.0)
		_hero_to(head.global_position + Vector3(-4.0, 0.0, -4.0))
		return
	if tail != null and m.gate_open:
		at = tail.global_position   # escort the tail: the hunters come from behind
		_go(army, at, 20.0)
		_hero_to(MissionE8_01Ice.GATE + Vector3(-6.0, 0.0, 6.0) if tail.global_position.z < MissionE8_01Ice.GATE.z else at + Vector3(-4.0, 0.0, 4.0))
		_phase = "column"
		return
	_phase = "column"
	_go(army, at, 20.0)
	_hero_to(at + Vector3(-4.0, 0.0, 4.0))


func _plan_nature() -> void:
	var m := main as MissionE8_01Nature
	var army := _soldiers()
	if _defend_base(army):
		_phase = "base"
		return
	for i in 3:
		if m.hamlet_state[i] == "raid":
			_phase = "hamlet%d" % i
			var hp: Vector3 = MissionE8_01Nature.HAMLETS[i][1]
			_go(army, hp, 16.0)
			_hero_to(hp + Vector3(-6.0, 0.0, 0.0))
			return
	if m.knots_open < 3:
		var k: Vector3 = MissionE8_01Nature.KNOTS[m.knots_open]
		_phase = "knot%d" % m.knots_open
		var spires: Array = m.spires[m.knots_open]
		for b: Variant in spires:
			if is_instance_valid(b) and (b as Building).is_alive():
				_attack_structure(army, b as Building)
				_hero_to(k + Vector3(-8.0, 0.0, 0.0))
				return
		var clear := _go(army, k, 12.0)
		_hero_to(k if clear else k + Vector3(-6.0, 0.0, 0.0))
		return
	_phase = "exit"
	var road_gate: Variant = m.bridge_gates.get(&"road")
	if road_gate != null and is_instance_valid(road_gate) and (road_gate as WardenGate).is_alive() and m.crossed_at < 0.0:
		_attack_structure(army, road_gate as Node3D)
	else:
		_go(army, MissionE8_01Nature.EXIT, 14.0)
	if not _foes(MissionE8_01Nature.BRIDGEHEAD, 18.0).is_empty():
		_go(army, MissionE8_01Nature.BRIDGEHEAD, 18.0)
		_hero_to(Vector3(12.0, 0.0, -2.0))
	else:
		_hero_to(MissionE8_01Nature.EXIT if m.mission_time() >= MissionE8_01Nature.EXIT_FLOOR - 30.0 else MissionE8_01Nature.EXIT + Vector3(-14.0, 0.0, 0.0))


func _plan_muster() -> void:
	var m := main as MissionE8_02
	var army := _soldiers()
	if _defend_base(army):
		_phase = "base"
		return
	var mine := MissionE8Muster.keyhole_of(Unit.Team.PLAYER)
	var t := m.mission_time()
	if not m.lit.has(Unit.Team.PLAYER):
		var pylon: WardenGate = m.pylons[Unit.Team.PLAYER]
		if t < 300.0:
			_phase = "hold"
			_go(army, mine + Vector3(-8.0, 0.0, 8.0), 14.0)
			_hero_to(mine + Vector3(-12.0, 0.0, 12.0))
		elif pylon.is_alive():
			_phase = "pylon"
			_attack_structure(army, pylon)
			_hero_to(mine + Vector3(-8.0, 0.0, 8.0))
		else:
			_phase = "key"
			var clear := _go(army, mine, 10.0)
			_hero_to(mine if clear else mine + Vector3(-6.0, 0.0, 6.0))
		return
	var home: Array = []
	var field: Array[Unit] = []
	for i in army.size():
		(home if i % 3 == 2 else field).append(army[i])
	_go(home, mine + Vector3(-8.0, 0.0, 8.0), 20.0)
	army = field
	var my_gate: WardenGate = m.gates[Unit.Team.PLAYER]
	if my_gate and my_gate.is_alive():
		_phase = "gate"
		_attack_structure(army, my_gate)
		_hero_to(mine + Vector3(-6.0, 0.0, 6.0))
		return
	# help: answer a ping, else the ally next to march
	var target := -1
	for s: int in m.allies():
		if m.ping.has(s) and not m.lit.has(s) and _foes(m.base_center(0), 30.0).is_empty():
			target = s
			break
	if target >= 0 and target != Teams.ALLY:
		target = -1   # the far bank is the allies' own fight: the scripted player helps its own bank (A2) only
	if target < 0:
		_phase = "wait"
		_go(army, mine, 14.0)
		_hero_to(mine + Vector3(-6.0, 0.0, 6.0))
		return
	_phase = "help%s" % MissionE8Muster.SEAT_NAMES[target]
	var at: Vector3 = (m.ping[target][0] as Vector3) if m.ping.has(target) else MissionE8Muster.keyhole_of(target)
	_go(army, at, 22.0)
	_hero_to(at.lerp(MissionE8Muster.keep_pos(target), 0.25))


func _plan_king() -> void:
	var m := main as MissionE8_03
	var army := _soldiers()
	if _defend_base(army):
		_phase = "base"
		return
	var mine := MissionE8Muster.keyhole_of(Unit.Team.PLAYER)
	var t := m.mission_time()
	var hit := (m.phase == 1 and t < m.surge_until) or (m.phase == 3 and t < m.exposed_until) or m.phase == 2
	if m.phase == 2 and m.king:
		_phase = "walk"
		for v: Variant in army:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack(m.king)
		_hero_to(m.king.global_position + (mine - m.king.global_position).normalized() * 20.0)
		return
	if hit and m.king:
		_phase = "strike"
		for v: Variant in army:
			var u := v as Unit
			if u.attack_target != m.king:
				u.command_attack(m.king)
	else:
		_phase = "ward"
		var w := m.call(&"_weakest_ward") as int
		var at := MissionE8Muster.keyhole_of(w) if w == Unit.Team.PLAYER or float(m.ward[w]) < m.ward_max * 0.6 else mine
		_go(army, at, 14.0)
	_hero_to(mine)
