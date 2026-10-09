extends SceneTree
## Mission e6m4 timing check (docs/design/mission-e6-04.md acceptance "Timing": a scripted headless run on normal -
## Stronghold, Bramblesages on the isle, break wg_w then wg_n, hold the West Bridge and the NW Steps - ends
## `victory=true` in 20-23 game minutes with the seal above 30 %). The hold needs 16:00 of clear time from 1:00, so no
## rush can win early; tests/test_e6m4_passive_sim.gd checks that doing nothing loses the seal. Real fights,
## cinematics off; e6m4_crack 0:30 + e6m4_first_crack 0:12 + e6m4_down 0:45 are added to the reported play time.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e6m4_sim.gd --fixed-fps 60
## --quit-after 100000

const TASK_ID := "e6m4_sim"
const MISSION := "res://missions/mission_e6_04.tscn"
const CINE_SECONDS := 87.0
const ISLE_HOLD := Vector3(-5.0, 0.0, 5.0)
const RALLY := Vector3(-14.0, 0.0, 14.0)
const HOLLOW_SPOT := Vector3(-52.0, 0.0, 40.0)
const HALL2 := Vector3(-20.0, 0.0, 44.0)
const WORKERS := 12

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE6_04
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _strike: Array = []
var _phase := "build"
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_passive" if passive else "")
	h.protect_hero = false
	h.timeout_frames = 98000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m4_sim_none.json"}}) as MissionE6_04
	h.steps.add("play", _play, 97000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null or unit.is_worker():
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
	var key := "%s@%d" % [who, int(main.mission_time() / 60.0)]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		print("  %s at mission time %s (play time with cutscenes %s); hold %d %%, paused %s; seal min %d %%; counted %d; gates west %d east %d" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(t + CINE_SECONDS),
				int(m.hold * 100.0), MissionE5Base.mmss(m.pause_time), int(m.seal_min * 100.0), m.counted, m.west_broken,
				m.east_broken])
		print("  waves %s; spotlight %s" % [",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  player losses (killer@minute): %s" % str(killers))
		if passive:
			h.check(h.ended == 0, "a passive run won (%s)" % MissionE5Base.mmss(t))
			return true
		h.check(h.ended == 1, "defeat at %s (%s)" % [MissionE5Base.mmss(t), _phase])
		h.check(t + CINE_SECONDS >= 1200.0 and t + CINE_SECONDS <= 1380.0, "play time %s outside 20-23 min" % MissionE5Base.mmss(t + CINE_SECONDS))
		h.check(m.seal_min > 0.3, "the seal fell to %d %%" % int(m.seal_min * 100.0))
		return true
	if passive:
		return false
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s ysolde %3.0f L%d | army %2d strike %d w%d | crystals %4d pop %d/%d T%d | hold %3d%% %s seal %4.0f | ally %d | foes %d" % [
				MissionE5Base.mmss(m.mission_time()), _phase, m.hero.hp, m.hero.level, _soldiers().size(), _strike.size(),
				_workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.keep.tier if m.keep else 0, int(m.hold * 100.0),
				"P" if m.hold_paused else " ", m.seal.hp, m.ally_army().size(), _foes(Vector3.ZERO, 90.0).size()])
	_economy()
	_spells()
	_plan()
	return false


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


func _foes(at: Vector3, r: float) -> Array[Unit]:
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
	var foes := _foes(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, Vector3(1.0, 0.0, -1.0))
	return false


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
			for s in ["a", "b", "mid"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if k.tier < 2 and k.can_upgrade() == "" and not k.is_upgrading() and eco.crystals >= 200:
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("sprigling")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	elif k.tier >= 2 and k.queue.size() < 1 and eco.crystals >= 150:
		var sages := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"bramblesage").size()
		if sages < 2:
			k.queue_unit(UnitType.find("bramblesage"))
			k.set_rally_point(RALLY)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and not _built.has("hall2") and eco.crystals >= 160 and m.mission_time() > 30.0:
		if _build("nature_barracks", HALL2, free_w):
			_built["hall2"] = true
		return
	if free_w and eco.pop_cap - eco.pop_used < 6 and _built.size() < 3 and not _built.has("h%d" % int(eco.pop_cap)) \
			and eco.crystals >= 100:
		if _build("nature_hollow", HOLLOW_SPOT + Vector3(0.0, 0.0, -6.0 * _built.size()), free_w):
			_built["h%d" % int(eco.pop_cap)] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"nature_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["thornling", "wildwood_archer", "thornling", "wildwood_archer", "bloomtender", "vinelasher"]
		hall.queue_unit(UnitType.find(mix[_train_i % mix.size()]))
		_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"call_the_thicket", &"wild_bloom", &"thornburst"]:
			if w.learn_spell(id) == "":
				break
	var foes := _foes(w.global_position, 12.0)
	if foes.is_empty():
		return
	if foes.size() >= 4 and w.command_cast(&"call_the_thicket", foes[0].global_position) == "":
		return
	var hurt := _soldiers().filter(func(u: Unit) -> bool: return u.hp < u.max_hp * 0.6 \
			and MissionBase._flat(u.global_position, w.global_position) < 10.0)
	if hurt.size() >= 3 and w.command_cast(&"wild_bloom", (hurt[0] as Unit).global_position) == "":
		return
	w.command_cast(&"thornburst", foes[0].global_position)


func _plan() -> void:
	var m := main
	var army := _soldiers()
	_strike = _strike.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	var target: WardenGate = null
	for gid: StringName in [&"wg_w", &"wg_n"]:
		if (m.wgates[gid] as WardenGate).is_alive():
			target = m.wgates[gid] as WardenGate
			break
	if target and _strike.is_empty() and army.size() >= 24 and m.hold > 0.15 and m.hold < 0.45:
		for u in army:
			if _strike.size() < army.size() * 0.55 and u.unit_type.id != &"bramblesage":
				_strike.append(u)
	if target == null or _strike.size() < 5:
		_strike.clear()
	var home: Array = army.filter(func(u: Unit) -> bool: return not _strike.has(u))
	if not _strike.is_empty():
		_phase = "strike %s" % target.gate_id
		if not _hold(_strike, target.global_position, 12.0):
			for v: Variant in _strike:
				if (v as Unit).attack_target == null:
					(v as Unit).command_attack(target)
	else:
		_phase = "isle"
	# The isle: clear the Master's circle first.
	var circle := _foes(Vector3.ZERO, 9.0)
	if not circle.is_empty():
		for u in home:
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack(circle[0])
	else:
		_hold(home, ISLE_HOLD, 20.0)
	var spot := ISLE_HOLD + Vector3(-4.0, 0.0, 4.0)
	if m.hero.hp < m.hero.max_hp * 0.35:
		spot = MissionE6_04.KEEP_POS + Vector3(6.0, 0.0, -6.0)
	if MissionBase._flat(m.hero.global_position, spot) > 3.0:
		m.hero.command_move(spot)
