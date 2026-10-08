extends SceneTree
## Mission e4m2 timing check (docs/design/mission-e4-02.md "Lead" check: a scripted headless run on normal escorts the 4
## convoys, raises the Citadel and calls Maelis, `victory=true` in 18-22 game-minutes with >= 30 of 40 through). Real
## fights: no hero protection, no kills or time skips by the test; cinematics off (fallback end states), the spec lengths
## of e4m2_lantern 0:15, e4m2_hush 0:08 and e4m2_border 0:30 are added to the reported play time.
## The scripted player (human-like): Spriglings to 11, Seed Hollows, the Citadel when it can, Maelis called, 2 Briar Rocs,
## Thornlings / Burr Slingers / Vinelashers / Oathkeepers; a home guard of 5 at the Grove Hall; the army sweeps the road
## ahead of the first convoy (the Hollow Oak, the brook and its totems, Crowstone), then walks with each convoy a little
## ahead of its lead (spread, ranged behind, Hush focused). Convoys leave on their auto times (no early ring).
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e4m2_sim.gd --fixed-fps 60
## --quit-after 110000

const TASK_ID := "e4m2_sim"
const MISSION := "res://missions/mission_e4_02.tscn"
const CUTSCENE_SECONDS := {&"lantern": 15.0, &"hush": 8.0, &"border": 30.0}
const HOME := Vector3(50.0, 0.0, -26.0)
const RALLY := Vector3(52.0, 0.0, -6.0)
const WORKERS := 11
const GUARDS := 5
const HOLLOWS: Array[Vector3] = [Vector3(74.0, 0.0, -30.0), Vector3(66.0, 0.0, -44.0), Vector3(40.0, 0.0, -40.0)]
const HALL2 := Vector3(46.0, 0.0, -18.0)
const SWEEP: Array[Vector3] = [Vector3(40.0, 0.0, 16.0), Vector3(-4.0, 0.0, -12.0), Vector3(-38.0, 0.0, 16.0)]

var verbose := false
var h := MissionHarness.new()
var main: MissionE4_02
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
var _sweep_i := 0
var _called_at := -1.0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 105000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m2_sim_none.json"}}) as MissionE4_02
	h.steps.add("play", _play, 104000)
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
	var what: String = String(unit.unit_type.id) if unit.unit_type else "?"
	var key := "%s:%s>%s" % [phase, who, what if what == "meadow_folk" else "unit"]
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
		var cine: float = CUTSCENE_SECONDS[&"lantern"] + (CUTSCENE_SECONDS[&"hush"] if m.has_fired(&"E7") else 0.0) \
				+ (CUTSCENE_SECONDS[&"border"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); arrived %d / %d (needed %d), lost %d; Maelis called %s; brook %s; hollow %s" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.arrived, m.folk_total, m.folk_needed,
				m.lost, _mmss(_called_at), m.objective_state("sec_brook"), m.objective_state("sec_hollow")])
		print("  phases %s; waves %s; spotlight %s" % [", ".join(_phase_log), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Nature losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
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
		print("    t=%s %s ysolde %3.0f/%3.0f L%d | army %2d guard %d (w%d) T%d | crystals %4d pop %d/%d | convoy %d road %d arrived %d lost %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _guard.size(),
				_workers().size(), m.keep.tier if m.keep else 0, eco.crystals, eco.pop_used, eco.pop_cap, m.next_convoy,
				m.on_road(), m.arrived, m.lost])
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


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _soldiers():
		if not _guard.has(u):
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
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not main.is_dormant(u) \
				and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _hold(units: Array, at: Vector3, r: float, facing := Vector3(-1.0, 0.0, 0.0)) -> bool:
	if units.is_empty():
		return false
	var ranged: Array = units.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u))
	SimTactics.focus_wizards(ranged, [main.hush], 14.0, func(w: Unit) -> bool: return not main.is_dormant(w))
	var foes := _enemies_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, facing)
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
	var roster := HelperRoster.for_team(0)
	if k.tier >= 3 and roster and roster.can_call() == "" and _called_at < 0.0:
		if roster.call_helper() == "":
			_called_at = m.mission_time()
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
	if k.tier >= 3 and _called_at < 0.0 and eco.crystals < 300:
		return   # Maelis first
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

## The lead walker of the convoy on the road (the one farthest along), else null.
func _convoy_lead() -> Unit:
	var best: Unit = null
	var wp := -1
	for c: Dictionary in main.convoys:
		if c["state"] != &"road":
			continue
		for v: Variant in c["walkers"]:
			if is_instance_valid(v) and (v as Unit).is_alive() and not (v as Unit).has_meta(&"arrived"):
				var u := v as Unit
				var i := int(u.get_meta(&"wp", 0))
				if i > wp:
					wp = i
					best = u
	return best


func _plan() -> void:
	var m := main
	var hero := m.hero
	var t := m.mission_time()
	if not _retreat and hero.hp < hero.max_hp * 0.45:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.85:
		_retreat = false
	# --- the home guard (B1 at 6:00 comes for the Grove Hall).
	_guard = _guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _guard.size() < GUARDS and t > 200.0:
		for u in _soldiers():
			if _guard.size() >= GUARDS:
				break
			if not _guard.has(u) and not SimTactics.is_ranged(u) and u.unit_type.id != &"briar_roc":
				_guard.append(u)
	_hold(_guard, HOME, 24.0, Vector3(0.0, 0.0, -1.0))
	var army: Array = SimTactics.pull_back_wounded(_army(), RALLY, _wounded, 0.5)
	var goal := Vector3.INF
	# --- the sweep ahead of convoy 1: the Hollow Oak, the brook (its totems), Crowstone.
	if _sweep_i < SWEEP.size():
		_set_phase(StringName("sweep%d" % _sweep_i))
		var at: Vector3 = SWEEP[_sweep_i]
		var busy := _hold(army, at, 16.0)
		if _sweep_i == 1:
			var alive := m.totems.filter(func(b: Variant) -> bool: return is_instance_valid(b) and (b as Building).is_alive())
			if not busy and not alive.is_empty():
				for v: Variant in army:
					var u := v as Unit
					if u.attack_target == null:
						u.command_attack(alive[0])
				busy = true
		var c := SimTactics.centroid(army)
		if not busy and c != Vector3.INF and MissionBase._flat(c, at) < 8.0:
			_sweep_i += 1
		goal = at + Vector3(6.0, 0.0, 0.0)
		if _sweep_i >= 1 and t >= 175.0 and m.next_convoy >= 1 and _sweep_i < 2:
			pass
	else:
		var lead := _convoy_lead()
		if lead != null:
			_set_phase(StringName("escort%d" % m.next_convoy))
			var wp := mini(int(lead.get_meta(&"wp", 1)) + 1, MissionE4_02.ROAD.size() - 1)
			var ahead: Vector3 = lead.global_position.lerp(MissionE4_02.ROAD[wp], 0.6)
			if not _hold(army, ahead, 18.0):
				# threats to the convoy itself
				var near := _enemies_near(lead.global_position, 16.0)
				if not near.is_empty():
					_hold(army, near[0].global_position, 10.0)
			goal = lead.global_position + Vector3(0.0, 0.0, 3.0)
		else:
			_set_phase(&"wait")
			var spot: Vector3 = MissionE4_02.ROAD[2] if m.next_convoy < 4 else MissionE4_02.ROAD[6]
			_hold(army, spot, 18.0)
			goal = spot + Vector3(4.0, 0.0, 0.0)
	if _retreat:
		_hero_to(RALLY, 3.0)
	elif goal != Vector3.INF:
		_hero_to(goal, 3.0)
