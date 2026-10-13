extends SceneTree
## Mission e6m2 timing check (docs/design/mission-e6-02.md acceptance "Timing"): open branch = escort the townsfolk,
## send Torvald and a detachment back to the mere at the telegraph, then break both Warden Gates: `victory=true` in
## 16:00-20:00 with >= 12 saved. The rush floor rides on this run: the army goes for the gates as soon as the folk are
## through, and the night must not end before the Final (16:00) is dead. Real fights, cinematics off (fallback end
## states); the spec lengths of e6m2_rider 0:15 and the dawn film 0:30 are added to the reported play time.
## Once both Warden Gates are down every wave (Breach, Lake 2, the Final) comes up through the mere crack: the whole
## army then waits at the lake (2026-10-13; holding the gap fed the detachment to the Breach and Torvald died ~12:35).
## tests/test_e6m2_shut_sim.gd runs the shut branch (the window runs out, a wall defence to 20:00).
## `-- --seed N`, `-- --difficulty N` (0-2, default 1), `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e6m2_sim.gd --fixed-fps 60
## --quit-after 90000

const TASK_ID := "e6m2_sim"
const MISSION := "res://missions/mission_e6_02.tscn"
const CINE_SECONDS := 45.0
const RALLY := Vector3(0.0, 0.0, -22.0)
const ROAD_HOLD := Vector3(0.0, 0.0, 6.0)
const LAKE_HOLD := Vector3(46.0, 0.0, -38.0)
const LODGE := Vector3(-24.0, 0.0, -50.0)
const HALL2 := Vector3(-26.0, 0.0, -36.0)
const WALL_HOLD := Vector3(0.0, 0.0, -14.0)
const GAP_HOLD := Vector3(0.0, 0.0, -5.0)     ## the open Frostgate's gap: the army plugs it once the folk are in
const GAP_HERO := Vector3(0.0, 0.0, -16.0)    ## Torvald casts from behind the wall
const LAKE_ARMY := Vector3(48.0, 0.0, -34.0)   ## between the mere crack (54, -24) and the Heartfrost (44, -46)
const LAKE_HERO := Vector3(40.0, 0.0, -44.0)    ## Torvald behind that line, by the Heartfrost
const WORKERS := 12
const DETACH := 5

var verbose := false
var shut := false           ## test_e6m2_shut_sim: never open, hold the wall
var h := MissionHarness.new()
var main: MissionE6_02
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _detach: Array = []
var _phase := "build"
var _healing := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	var difficulty := 1
	var di := args.find("--difficulty")
	if di >= 0 and di + 1 < args.size():
		difficulty = clampi(int(args[di + 1]), 0, 2)
	h.task_id = TASK_ID + ("_shut" if shut else "")
	h.protect_hero = false
	h.timeout_frames = 88000
	main = h.open(self, MISSION, {"difficulty": difficulty, "set": {"campaign_save_path": "user://test_e6m2_sim_none.json"}}) as MissionE6_02
	h.steps.add("play", _play, 87000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		print("  %s (%s) at mission time %s (play time with cutscenes %s); saved %d / sent %d; gates broken %d; Heartfrost min %d %%; Frostgate %s" % [
				"victory" if h.ended == 1 else "defeat", m.branch, MissionE5Base.mmss(t), MissionE5Base.mmss(t + CINE_SECONDS),
				m.saved, m.folk_sent, m.gates_broken, int(m.heart_min * 100.0),
				"shattered" if m.gate.is_shattered else ("closed" if m.gate.is_closed else "open")])
		print("  waves %s; spotlight %s" % [",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		h.check(h.ended == 1, "defeat at %s (%s)" % [MissionE5Base.mmss(t), _phase])
		if shut:
			h.check(t >= 1199.0, "the shut branch ended before dawn (%s)" % MissionE5Base.mmss(t))
		else:
			h.check(t >= 960.0 and t <= 1200.0, "mission time %s outside 16:00-20:00" % MissionE5Base.mmss(t))
			h.check(m.saved >= 12, "only %d saved" % m.saved)
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s torvald %3.0f/%3.0f L%d | army %2d det %d w%d | crystals %4d pop %d/%d | heart %4.0f gate %4.0f | saved %d" % [
				MissionE5Base.mmss(m.mission_time()), _phase, m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_detach.size(), _workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.heartfrost.hp, m.gate.hp, m.saved])
	_economy()
	_spells()
	_plan()
	return false


# ---------------------------------------------------------------- helpers

func _soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _foes_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hold(units: Array, at: Vector3, r: float) -> bool:
	if units.is_empty():
		return false
	var foes := _foes_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, Vector3(0.0, 0.0, 1.0))
	return false


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
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
		var t: Variant = w.get(&"gather_node")
		if not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			for s in ["a", "b", "rich"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("rime_hauler")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and not _built.has("hall2") and eco.crystals >= 160 and m.mission_time() > 40.0:
		if _build("ice_barracks", HALL2, free_w):
			_built["hall2"] = true
		return
	if free_w and eco.pop_cap - eco.pop_used < 6 and _built.size() < 3 and not _built.has("lodge%d" % int(eco.pop_cap)) \
			and eco.crystals >= 100:
		if _build("ice_lodge", LODGE + Vector3(-5.0 * _built.size(), 0.0, 0.0), free_w):
			_built["lodge%d" % int(eco.pop_cap)] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"ice_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 140:
			continue
		var mix: Array = ["rimeshield", "frostbow", "shardcaster", "rimeshield", "frostbow", "rime_colossus"]
		var want: String = mix[_train_i % mix.size()]
		hall.queue_unit(UnitType.find(want))
		_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"rime_aegis", &"flash_freeze", &"rime_bolt"]:
			if w.learn_spell(id) == "":
				break
	var foes := _foes_near(w.global_position, 12.0)
	if foes.is_empty():
		return
	if foes.size() >= 3 and w.command_cast(&"flash_freeze", foes[0].global_position) == "":
		return
	if w.hp < w.max_hp * 0.6 and w.command_cast(&"rime_aegis", w) == "":
		return
	w.command_cast(&"rime_bolt", foes[0])


# ---------------------------------------------------------------- the plan

func _lake_alert() -> bool:
	var m := main
	if not _foes_near(MissionE6_02.HEART_POS, 26.0).is_empty():
		return true
	return m.mission_time() >= m.next_lake_telegraph() - 6.0


func _plan() -> void:
	var m := main
	var t := m.mission_time()
	if m.choice_at >= 0.0 and m.branch == &"":
		if shut:
			pass   # let the fire die
		else:
			m.choose_open()
	var army := _soldiers()
	_detach = _detach.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	var lake := _lake_alert()
	if lake and _detach.size() < DETACH:
		for u in army:
			if not _detach.has(u) and _detach.size() < DETACH and u.unit_type.id != &"rime_colossus":
				_detach.append(u)
	var main_army: Array = army.filter(func(u: Unit) -> bool: return not _detach.has(u))
	if m.hero.hp < m.hero.max_hp * 0.4:
		_healing = true
	elif m.hero.hp > m.hero.max_hp * 0.9:
		_healing = false
	if _healing:
		lake = false   # Torvald walks home to heal; the detachment holds alone
		_hero_to(MissionE6_02.KEEP_POS + Vector3(0.0, 0.0, 6.0), 3.0)
	if lake:
		_hold(_detach, MissionE6_02.HEART_POS + Vector3(4.0, 0.0, 6.0), 22.0)
		_hero_to(MissionE6_02.HEART_POS + Vector3(-4.0, 0.0, 8.0), 3.0)
	else:
		_hold(_detach, LAKE_HOLD, 14.0)
	if _healing:
		if m.gates_broken >= 2:
			_hold(main_army + _detach, LAKE_ARMY, 22.0)
		else:
			_hold(main_army, GAP_HOLD if m.branch == &"open" else WALL_HOLD, 18.0)
		return
	var home := _foes_near(MissionE6_02.KEEP_POS, 24.0)
	if not home.is_empty():
		_phase = "home"
		_hold(main_army, home[0].global_position, 14.0)
		if not lake:
			_hero_to(MissionE6_02.KEEP_POS + Vector3(0.0, 0.0, 8.0), 4.0)
		return
	if m.branch != &"open":
		_phase = "wall"
		_hold(main_army, WALL_HOLD, 14.0)
		if not lake:
			_hero_to(WALL_HOLD + Vector3(0.0, 0.0, -5.0), 3.0)
		return
	if m.folk_sent < 24 or not m.folk.is_empty():
		_phase = "escort"
		_hold(main_army, ROAD_HOLD, 18.0)
		if not lake:
			_hero_to(ROAD_HOLD + Vector3(0.0, 0.0, -6.0), 3.0)
		return
	var target: WardenGate = null
	for id: StringName in [&"wgate_sw", &"wgate_se"]:
		var g := m.wgates[id] as WardenGate
		if g.is_alive():
			target = g
			break
	if target == null and m.gates_broken >= 2:
		# Both Warden Gates are down: the Breach, Lake 2 and the Final can only come up through the mere crack. The whole
		# army waits between the crack and the Heartfrost (a detachment of 5 fed one by one died to the Breach's two
		# Breakers and took Torvald with it); Torvald casts from behind it.
		_phase = "lake"
		_hold(main_army + _detach, LAKE_ARMY, 22.0)
		if not _healing:
			_hero_to(LAKE_HERO, 3.0)
		return
	if target == null or main_army.size() < 14 or t < 600.0:
		# the folk are in: hold the open gate's gap (the Wardens no longer stall on an open gate), Torvald behind the wall
		_phase = "road"
		_hold(main_army, GAP_HOLD, 16.0)
		if not lake:
			_hero_to(GAP_HERO, 3.0)
		return
	_phase = "gate %s" % target.gate_id
	if not _hold(main_army, target.global_position, 14.0):
		for v: Variant in main_army:
			var u := v as Unit
			if u.attack_target == null:
				u.command_attack(target)
	if not lake:
		_hero_to(GAP_HERO, 3.0)   # Torvald keeps the gap behind the wall; the army breaks the gate
