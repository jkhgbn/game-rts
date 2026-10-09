extends SceneTree
## Mission e4m4 timing check (docs/design/mission-e4-04.md "Lead" check: a scripted headless run on normal wakes the
## Elder, raises the Citadel, breaks the West Gate, both wardens, the Winterheart and reaches the spire, `victory=true`
## in 24-30 game-minutes; Ysolde survives I2). Real fights: no hero protection, no kills or time skips by the test;
## cinematics off (fallback end states), the spec lengths of e4m4_arrival 0:15, e4m4_wardens 0:08, e4m4_thaw 0:12 and
## e4m4_enough 0:40 are added to the reported play time.
## The scripted player (human-like): Spriglings to 11, Seed Hollows, the Citadel when it can (it brings a Treant), 2
## Briar Rocs, Thornlings / Burr Slingers / Vinelashers / Oathkeepers; the army clears the Elder's watch and its totems,
## Ysolde wakes the Elder; a guard of 5 at the west expansion; then the Wall: the West Gate (Treants on the gate, the
## rest on its garrison), the West Wallwarden, the Heart Gate, the East Gate and its warden (with Vessa), the
## Winterheart; then Ysolde walks to the Glass Spire behind the army. Torvald and Aldra are focused by the ranged units.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e4m4_sim.gd --fixed-fps 60
## --quit-after 140000

const TASK_ID := "e4m4_sim"
const MISSION := "res://missions/mission_e4_04.tscn"
const CUTSCENE_SECONDS := {&"arrival": 15.0, &"wardens": 8.0, &"thaw": 12.0, &"enough": 40.0}
const RALLY := Vector3(-30.0, 0.0, 28.0)
const WEST_GUARD := Vector3(-56.0, 0.0, 18.0)
const WORKERS := 11
const GUARDS := 5
const HOLLOWS: Array[Vector3] = [Vector3(-60.0, 0.0, 40.0), Vector3(-52.0, 0.0, 64.0), Vector3(-30.0, 0.0, 62.0)]
const HALL2 := Vector3(-24.0, 0.0, 42.0)
## Human pacing (the spec's rhythm: the Elder ~2:00-4:30, the West Gate from 9:00, then the Heart Gate and the East
## Gate with Vessa, the Winterheart as soon as both wardens fall): the army builds up before the first push and
## regroups at home (out of the Wall's reach) under 25 soldiers. Before JS's 2026-10-08 changes this ran short (14:33);
## now the Wall is sturdier (gates / pieces / wardens, a Rime Colossus per garrison) and the Winterheart stays
## frost-bound until 19:00 (MissionE4_04.HEART_OPEN_AT), with fuller home nodes so the wait does not starve the army:
## the army breaks the gates and the wardens, waits at home, then hits the Winterheart when it opens.
const ELDER_AT := 120.0
const WEST_AT := 540.0
const HEART_GATE_AT := 600.0
const EAST_AT := 660.0

var verbose := false
var h := MissionHarness.new()
var main: MissionE4_04
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hollow_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _guard: Array = []
var _wounded := {}
var _i2_hero_hp := 1.0
var killers := {}
var _v_dead := false
var _regroup := false
var _frames := 0
const REGROUP_BELOW := 25
const REGROUP_UNTIL := 38


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 135000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m4_sim_none.json"}}) as MissionE4_04
	h.steps.add("play", _play, 134000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null:
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
	var key := "%s:%s" % [phase, who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


static func _mmss(t: float) -> String:
	if t < 0.0:
		return "-"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _set_phase(p: StringName) -> void:
	if phase != p:
		phase = p
		_phase_log.append("%s@%s" % [p, _mmss(main.mission_time())])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"arrival"] + (CUTSCENE_SECONDS[&"wardens"] if m.has_fired(&"E12") else 0.0) \
				+ (CUTSCENE_SECONDS[&"thaw"] if m.thawed else 0.0) + (CUTSCENE_SECONDS[&"enough"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); elder %s; wardens %d / 2; halls %s; treants %d; hero HP after I2 %d %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.elder_woken, m.wardens_down,
				m.objective_state("sec_halls"), m.treants.size(), int(100.0 * _i2_hero_hp)])
		print("  phases %s; waves %s; spotlight %s" % [", ".join(_phase_log), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Nature losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_frames += 1
	if _frames % 3600 == 0:
		print("    [watch] frame %d time %s hero %s held %s over %s ending %s" % [_frames, _mmss(m.mission_time()), m.hero_alive(), m.world_is_held, m.game_over, m.is_ending()])
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		if not _v_dead:
			_v_dead = true
			print("    hero down at %s: valid %s ending %s game_over %s" % [_mmss(m.mission_time()), is_instance_valid(m.hero), m.is_ending(), m.game_over])
		return false
	if m.has_fired(&"E10"):
		_i2_hero_hp = minf(_i2_hero_hp, m.hero.hp / maxf(1.0, m.hero.max_hp))
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		var gs := []
		for id: StringName in m.gates:
			var g: Variant = m.gates[id]
			gs.append("%s %d" % [id, int((g as Building).hp) if is_instance_valid(g) and (g as Building).is_alive() else 0])
		print("    t=%s %s ysolde %3.0f/%3.0f L%d | army %2d (w%d) T%d | crystals %4d pop %d/%d | gates %s | wardens %d | heart %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_workers().size(), m.keep.tier if m.keep else 0, eco.crystals, eco.pop_used, eco.pop_cap, str(gs), m.wardens_down,
				int(m.winterheart.hp) if is_instance_valid(m.winterheart) and m.winterheart.is_alive() else 0])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
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
				and u.is_commandable() and not u is Helper:
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 1 and not main.is_dormant(u) \
				and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _hold(units: Array, at: Vector3, r: float, facing := Vector3(0.0, 0.0, -1.0)) -> bool:
	if units.is_empty():
		return false
	var ranged: Array = units.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u))
	SimTactics.focus_wizards(ranged, [main.torvald, main.aldra], 14.0, func(w: Unit) -> bool: return not main.is_dormant(w))
	var foes := _enemies_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, facing)
	return false


## The army on a building: Treants on it always, the rest on the defenders within 10 m of it first.
func _siege(units: Array, b: Building) -> void:
	var at := b.global_position + Vector3(0.0, 0.0, 4.0)
	var foes := _enemies_near(at, 11.0)
	var ranged: Array = units.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u))
	SimTactics.focus_wizards(ranged, [main.torvald, main.aldra], 14.0, func(w: Unit) -> bool: return not main.is_dormant(w))
	for v: Variant in units:
		var u := v as Unit
		var t: Variant = u.attack_target
		if t != null and is_instance_valid(t) and (t as Node).has_method(&"is_alive") and bool((t as Node).call(&"is_alive")):
			continue
		if u.unit_type.id == &"elder_treant" or foes.is_empty():
			u.command_attack(b)
		else:
			u.command_attack_move(foes[0].global_position)


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _tend_sites(workers: Array[Unit]) -> Array:
	var busy: Array = []
	_sites = _sites.filter(func(r: Array) -> bool: return is_instance_valid(r[0]) and (r[0] as Building).is_alive() \
			and not (r[0] as Building).is_constructed())
	for r: Array in _sites:
		var w: Variant = r[1]
		if w == null or not is_instance_valid(w) or not (w as Unit).is_alive():
			if workers.is_empty():
				continue
			w = workers[0]
			r[1] = w
		var wu := w as Unit
		busy.append(wu)
		if not bool(wu.call(&"is_building")) and not wu.has_move_order():
			wu.call(&"command_build", r[0])
	return busy


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for suffix in ["a", "b", "x"]:
		node = m.node_of(0, suffix)
		if node:
			break
	var busy := _tend_sites(workers)
	for w in workers:
		if busy.has(w):
			continue
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			w.call(&"command_gather", node)
	var k := m.keep
	if k == null or not k.is_alive():
		return
	var saving := k.tier < 3 and m.mission_time() >= 300.0 and not k.is_upgrading()
	if k.tier < 3 and m.mission_time() >= 330.0 and k.can_upgrade() == "":
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= (360 if saving else 40):
		if k.queue_unit(UnitType.find("sprigling")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if eco.pop_cap - eco.pop_used < 6 and _hollow_i < HOLLOWS.size() and eco.crystals >= (380 if saving else 90):
		_build("nature_hollow", HOLLOWS[_hollow_i], workers[0])
		_hollow_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"nature_barracks").size()
	if halls < 2 and eco.crystals >= 200 and m.mission_time() > 60.0 and not saving:
		_build("nature_barracks", HALL2, workers[0])
	if saving and eco.crystals < 360:
		return
	if k.tier >= 3 and k.queue.size() < 2 and eco.crystals >= 380:
		var rocs := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"briar_roc").size()
		if rocs < 2:
			k.queue_unit(UnitType.find("briar_roc"))
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"nature_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["thornling", "burr_slinger", "thornling", "vinelasher", "greenheart_oathkeeper", "burr_slinger",
				"bloomtender", "thornling"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("thornling"))
		_train_i += 1
		hall.set_rally_point(RALLY)
	for u in _soldiers():
		var ca := u.get_node_or_null(^"CasterAbility")
		if ca and ca.has_method(&"set_autocast"):
			for sid: StringName in [&"snagroot", &"pollen_haze", &"seed_storm"]:
				if ca.has_method(&"autocast") and not bool(ca.call(&"autocast", sid)):
					ca.call(&"set_autocast", sid, true)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"thornburst", &"wild_bloom", &"call_the_thicket"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _enemies_near(w.global_position, 14.0).is_empty() and w.hp > w.max_hp * 0.8:
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id != &"":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _alive(b: Variant) -> bool:
	return b != null and is_instance_valid(b) and (b as Building).is_alive()


func _awake_warden() -> Unit:
	for id: StringName in main.wallwardens:
		var w: Variant = main.wallwardens[id]
		if w != null and is_instance_valid(w) and (w as Unit).is_alive() and not main.is_dormant(w):
			return w as Unit
	return null


func _plan() -> void:
	var m := main
	var hero := m.hero
	var t := m.mission_time()
	if not _retreat and hero.hp < hero.max_hp * 0.45:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.85:
		_retreat = false
	_guard = _guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _guard.size() < GUARDS and t > 150.0 and not m.thawed:
		for u in _soldiers():
			if _guard.size() >= GUARDS:
				break
			if not _guard.has(u) and not SimTactics.is_ranged(u) and u.unit_type.id != &"elder_treant" and u.unit_type.id != &"briar_roc":
				_guard.append(u)
	if m.thawed:
		_guard.clear()
	_hold(_guard, WEST_GUARD, 20.0)
	var army: Array = SimTactics.pull_back_wounded(_soldiers().filter(func(u: Unit) -> bool: return not _guard.has(u)),
			RALLY, _wounded, 0.5)
	var goal := Vector3.INF
	var warden := _awake_warden()
	# Once the Winterheart is open the income is thinning: regroup only a broken army, and not for long.
	var below := 12 if m.heart_open else REGROUP_BELOW
	var until := 22 if m.heart_open else REGROUP_UNTIL
	if army.size() < below and t > 400.0:
		_regroup = true
	elif army.size() >= until:
		_regroup = false
	if not m.elder_woken and t >= ELDER_AT and t < 420.0:
		_set_phase(&"elder")
		var at := MissionE4_04.ELDER
		var busy := _hold(army, at + Vector3(0.0, 0.0, -6.0), 14.0)
		var totems: Array = m.elder_totems.filter(func(b: Variant) -> bool: return _alive(b))
		if not busy and not totems.is_empty():
			_siege(army, totems[0])
		goal = at if totems.is_empty() and _enemies_near(at, 10.0).is_empty() else at + Vector3(0.0, 0.0, 8.0)
	elif m.thawed:
		_set_phase(&"spire")
		var at := MissionE4_04.GLASS_SPIRE + Vector3(0.0, 0.0, 10.0)
		_hold(army, at, 16.0)
		var c := SimTactics.centroid(army)
		# Once the army is on the spire guard, Ysolde runs for the spire (the goal is to reach it, e4m4_enough stops the
		# fight the moment she is within 8 m), whatever her HP.
		var engaged := c != Vector3.INF and MissionBase._flat(c, at) < 20.0 or army.size() < 6
		if engaged:
			main.hero.command_move(MissionE4_04.GLASS_SPIRE)
			return
		goal = c if c != Vector3.INF else at
	elif warden != null and warden.global_position.z > MissionE4_04.WALL_Z:
		_set_phase(&"warden")
		_hold(army, warden.global_position, 14.0)
		for v: Variant in army:
			var u := v as Unit
			if u.unit_type.id == &"elder_treant" or SimTactics.is_ranged(u):
				if u.attack_target != warden:
					u.command_attack(warden)
		goal = warden.global_position + Vector3(0.0, 0.0, 10.0)
	elif _regroup and not m.thawed:
		_set_phase(&"regroup")
		_hold(army, RALLY, 16.0)
		goal = RALLY + Vector3(0.0, 0.0, 6.0)
	elif m.wardens_down >= 2 and _alive(m.winterheart) and not m.heart_open:
		_set_phase(&"wait_heart")   # both wardens down, the Winterheart frost-bound until 19:00: build up at home
		_hold(army, RALLY, 18.0)
		goal = RALLY
	elif _alive(m.gates.get(&"west")) and t >= WEST_AT and m.wardens_down < 2:
		_set_phase(&"west_gate")
		_siege(army, m.gates[&"west"])
		goal = (MissionE4_04.GATES[&"west"] as Vector3) + Vector3(0.0, 0.0, 10.0)
	elif not _alive(m.gates.get(&"west")) and _alive(m.gates.get(&"heart")) and t >= HEART_GATE_AT and m.wardens_down < 2:
		_set_phase(&"heart_gate")
		_siege(army, m.gates[&"heart"])
		goal = (MissionE4_04.GATES[&"heart"] as Vector3) + Vector3(0.0, 0.0, 10.0)
	elif not _alive(m.gates.get(&"heart")) and m.wardens_down < 2 and _alive(m.gates.get(&"east")) and t >= EAST_AT:
		_set_phase(&"east_gate")
		_siege(army, m.gates[&"east"])
		goal = (MissionE4_04.GATES[&"east"] as Vector3) + Vector3(0.0, 0.0, 10.0)
	elif m.wardens_down < 2 and warden != null and t >= EAST_AT:
		_set_phase(&"warden_north")
		_hold(army, warden.global_position, 14.0)
		goal = warden.global_position + Vector3(0.0, 0.0, 10.0)
	elif m.wardens_down >= 2 and _alive(m.winterheart) and m.heart_open and _alive(m.gates.get(&"west")) \
			and _alive(m.gates.get(&"heart")) and _alive(m.gates.get(&"east")):
		# The Wall regrew every breach while the army waited for 19:00: break the Heart Gate again first.
		_set_phase(&"rebreach")
		_siege(army, m.gates[&"heart"])
		goal = (MissionE4_04.GATES[&"heart"] as Vector3) + Vector3(0.0, 0.0, 12.0)
	elif m.wardens_down >= 2 and _alive(m.winterheart) and m.heart_open:
		_set_phase(&"winterheart")
		_siege(army, m.winterheart)
		goal = MissionE4_04.WINTERHEART + Vector3(0.0, 0.0, 12.0)
	else:
		_set_phase(&"wait")
		_hold(army, RALLY, 18.0)   # out of the Wall's reach (I2 hunts groups within 30 m of it)
		goal = RALLY
	if _retreat:
		_hero_to(RALLY, 3.0)
	elif goal != Vector3.INF:
		_hero_to(goal, 2.0)
